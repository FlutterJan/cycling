import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../engine/peloton/drafting_grid_system.dart';
import '../../engine/peloton/rider_race_state.dart';
import '../../engine/rendering3d/on_bike_computer_hud_widget.dart';
import '../../engine/simulation/stage_simulation_loop.dart';
import '../../models/race/race_stage.dart';
import '../../models/rider/rider_appearance.dart';
import '../../state/race_simulation_notifier.dart';
import '../widgets/group_gaps_chalkboard_widget.dart';
import '../widgets/rider_avatar_painter.dart';
import '../widgets/rider_effort_slider_control.dart';
import '../widgets/tactical_minimap_2d_widget.dart';
import '../widgets/team_tactical_presets_bar.dart';
import 'race_3d_viewport_widget.dart';

/// Profesjonalny interfejs nakładkowy (HUD) łączący oficjalną oprawę telewizyjną
/// Tour de France (styl ASO Broadcast Graphics) oraz interfejs Zwift / MyWhoosh.
class RaceHudOverlay extends ConsumerStatefulWidget {
  /// Opcjonalne tło trójwymiarowe. Domyślnie osadza [Race3DViewportWidget].
  final Widget? background;
  final VoidCallback? onBack;
  final ValueChanged<String>? onRiderSelected;
  final ValueChanged<TacticalOrder>? onOrderIssued;

  const RaceHudOverlay({
    super.key,
    this.background,
    this.onBack,
    this.onRiderSelected,
    this.onOrderIssued,
  });

  @override
  ConsumerState<RaceHudOverlay> createState() => _RaceHudOverlayState();
}

enum _BottomConsoleTab {
  ordersAndEffort('Rozkazy & Wysiłek', Icons.tune_rounded),
  teamPresets('Taktyka Drużyny', Icons.groups_rounded);

  final String label;
  final IconData icon;
  const _BottomConsoleTab(this.label, this.icon);
}

class _RaceHudOverlayState extends ConsumerState<RaceHudOverlay>
    with SingleTickerProviderStateMixin {
  static const BikeDrivetrainSimulator _drivetrainSimulator =
      BikeDrivetrainSimulator();

  bool _isRosterCollapsed = false;
  bool _isRightCornerCollapsed = false;
  bool _isBottomConsoleExpanded = true;
  bool _isRiderOrdersDrawerOpen = true;
  bool _isChalkboardExpanded = false;
  bool _isAeroVisionMode = false;
  bool _autoResponsiveApplied = false;

  int _targetPullWatts = 420;
  _BottomConsoleTab _activeConsoleTab = _BottomConsoleTab.ordersAndEffort;
  final Map<String, double> _riderEffortOverrides = {};
  final Map<String, RiderAeroPosition> _riderAeroOverrides = {};

  late final AnimationController _flammePulseController;

  @override
  void initState() {
    super.initState();
    _flammePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _flammePulseController.dispose();
    super.dispose();
  }

  void _applyInitialResponsiveDefaults(double width) {
    if (_autoResponsiveApplied) return;
    _autoResponsiveApplied = true;
    if (width < 720) {
      _isRosterCollapsed = true;
      _isRightCornerCollapsed = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final simState = ref.watch(raceSimulationProvider);
    final simController = ref.read(raceSimulationProvider.notifier);

    final activeStage =
        simState.simulationState?.stage ?? _generateFallbackStage();
    final playerRiders = simState.playerRidersPositions.isNotEmpty
        ? simState.playerRidersPositions
        : _generateFallbackPlayerSnapshots();

    final allRidersSorted = _sortedRaceStandings(
      simState.riderPositions.isNotEmpty
          ? simState.riderPositions
          : playerRiders,
    );
    final Map<String, int> rankByRiderId = {
      for (int i = 0; i < allRidersSorted.length; i++)
        allRidersSorted[i].riderId: i + 1,
    };

    final selectedRiderId = simState.selectedRiderId ??
        (playerRiders.isNotEmpty ? playerRiders.first.riderId : null);

    final selectedSnapshot = playerRiders.firstWhere(
      (r) => r.riderId == selectedRiderId,
      orElse: () => playerRiders.first,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          _applyInitialResponsiveDefaults(constraints.maxWidth);
          final bool isMobile = constraints.maxWidth < 720;
          final bool isTablet =
              constraints.maxWidth >= 720 && constraints.maxWidth < 1200;

          final double topBarHeight = isMobile ? 104.0 : 76.0;
          final double leftPanelWidth =
              _isRosterCollapsed ? 60.0 : (isMobile ? 256.0 : (isTablet ? 264.0 : 292.0));
          final double rightCornerWidth =
              _isRightCornerCollapsed ? 170.0 : (isMobile ? 276.0 : (isTablet ? 300.0 : 340.0));

          final double bottomConsoleLeft =
              isMobile ? 10.0 : (leftPanelWidth + 22.0);
          final double bottomConsoleRight =
              isMobile ? 10.0 : (rightCornerWidth + 22.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              // 0. Tło 3D (Zwift / MyWhoosh 3D Viewport)
              Positioned.fill(
                child: widget.background ??
                    Race3DViewportWidget(
                      selectedRiderId: selectedRiderId,
                      showCameraControls: false,
                      showBroadcastHud: false,
                      showOnBikeComputer: false,
                      initialAeroVision: _isAeroVisionMode,
                      onRiderSelected: (id) {
                        simController.selectRider(id);
                        widget.onRiderSelected?.call(id);
                      },
                    ),
              ),

              // 1. Górny Pasek Telewizyjny (ASO Broadcast Top Bar)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildBroadcastTopBar(
                        stage: activeStage,
                        simState: simState,
                        simController: simController,
                        isMobile: isMobile,
                        isTablet: isTablet,
                      ),
                      // Rozwijana tablica motocyklisty (GroupGapsChalkboardWidget)
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, anim) => SizeTransition(
                          sizeFactor: anim,
                          alignment: Alignment.topCenter,
                          child: FadeTransition(opacity: anim, child: child),
                        ),
                        child: _isChalkboardExpanded
                            ? Padding(
                                key: const ValueKey('chalkboard_open'),
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 10 : 14,
                                  vertical: 4,
                                ),
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: isMobile ? 370 : 620,
                                    ),
                                    child: GroupGapsChalkboardWidget(
                                      isCollapsible: false,
                                      onGroupSelected: (group) {
                                        if (group.hasPlayerRider) {
                                          final match = playerRiders.firstWhere(
                                            (r) => r.groupType == group.type,
                                            orElse: () => playerRiders.first,
                                          );
                                          simController
                                              .selectRider(match.riderId);
                                          widget.onRiderSelected
                                              ?.call(match.riderId);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(
                                key: ValueKey('chalkboard_closed'),
                              ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Lewy Panel Kolarzy Drużyny (8 kompaktowych, szklanych kart)
              Positioned(
                top: topBarHeight + 8,
                bottom: isMobile ? 190 : 16,
                left: isMobile ? 8 : 12,
                child: SafeArea(
                  child: _buildLeftTeamRosterPanel(
                    playerRiders: playerRiders,
                    rankByRiderId: rankByRiderId,
                    selectedRiderId: selectedRiderId,
                    simController: simController,
                    panelWidth: leftPanelWidth,
                  ),
                ),
              ),

              // 3. Prawy Dolny Róg (OnBikeComputer + TacticalMinimap2D + Aero Vision Mode)
              Positioned(
                right: isMobile ? 8 : 12,
                bottom: isMobile ? (_isBottomConsoleExpanded ? 184 : 62) : 12,
                child: SafeArea(
                  top: false,
                  child: _buildRightBottomCornerDock(
                    stage: activeStage,
                    selectedSnapshot: selectedSnapshot,
                    simController: simController,
                    width: rightCornerWidth,
                    isMobile: isMobile,
                  ),
                ),
              ),

              // 4. Dolna Konsola Taktyczna (RiderEffortSliderControl + TeamTacticalPresetsBar + Rozkazy)
              Positioned(
                bottom: isMobile ? 8 : 12,
                left: bottomConsoleLeft,
                right: bottomConsoleRight,
                child: SafeArea(
                  top: false,
                  child: _buildBottomTacticalConsole(
                    selectedSnapshot: selectedSnapshot,
                    playerRiders: playerRiders,
                    simController: simController,
                    isMobile: isMobile,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ===========================================================================
  // 1. GÓRNY PASEK TELEWIZYJNY (ASO BROADCAST TOP BAR)
  // ===========================================================================

  Widget _buildBroadcastTopBar({
    required RaceStage stage,
    required ActiveRaceSimulationState simState,
    required RaceSimulationNotifier simController,
    required bool isMobile,
    required bool isTablet,
  }) {
    final double distRemainingKm = simState.distanceRemainingKm > 0
        ? simState.distanceRemainingKm
        : (stage.totalDistanceKm > 0 ? stage.totalDistanceKm * 0.14 : 24.6);
    final double totalDistKm =
        stage.totalDistanceKm > 0 ? stage.totalDistanceKm : 160.0;
    final double progressFraction =
        ((totalDistKm - distRemainingKm) / totalDistKm).clamp(0.0, 1.0);

    final currentSeg = (simState.simulationState != null &&
            simState.simulationState!.currentSegmentIndex <
                stage.segments.length)
        ? stage.segments[simState.simulationState!.currentSegmentIndex]
        : null;

    final double gradient = currentSeg?.gradientPercent ?? 5.4;
    final double windSpeed =
        stage.windSpeedKmh > 0 ? stage.windSpeedKmh : 18.0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 12, vertical: 6),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 10 : 14,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.65),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: isMobile ? 350 : (isTablet ? 960 : 1480),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Sekcja lewa: Powrót + Logo wyścigu + Nazwa etapu
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.onBack != null) ...[
                    _InteractiveHudButton(
                      onTap: widget.onBack!,
                      tooltip: 'Opuść symulację etapu',
                      padding: const EdgeInsets.all(6),
                      borderRadius: 10,
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textSecondary,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  _buildRaceBroadcastLogo(stage),
                ],
              ),
              const SizedBox(width: 12),

              // Kilometr do mety (Złote <10km, Flamme Rouge <=1.0km)
              _buildDistanceToFinishBadge(
                distRemainingKm: distRemainingKm,
                progressFraction: progressFraction,
              ),
              const SizedBox(width: 10),

              // Przycisk / pigułka Tablicy Motocyklisty (GroupGapsChalkboardWidget)
              _buildChalkboardTogglePill(simState),
              const SizedBox(width: 10),

              // Wskaźnik wiatru i nachylenia podjazdu
              _buildWindAndGradientCluster(
                windSpeedKmh: windSpeed,
                gradientPercent: gradient,
              ),
              const SizedBox(width: 12),

              // Kontrolki prędkości symulacji: Pause, 1x, 2x, 4x, 8x, Skocz do Akcji
              _buildSimulationSpeedControls(simState, simController),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRaceBroadcastLogo(RaceStage stage) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.goldAccent.withValues(alpha: 0.45),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Emblem TdF / ASO style
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.goldAccent, Color(0xFFA67C00)],
              ),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Center(
              child: Icon(
                Icons.emoji_events_rounded,
                color: Colors.black,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.crimsonAlert,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'ASO WORLD FEED • LIVE',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.goldAccent,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 1),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 190),
                child: Text(
                  'ETAP ${stage.stageNumber} • ${stage.name}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceToFinishBadge({
    required double distRemainingKm,
    required double progressFraction,
  }) {
    final bool isFlammeRouge = distRemainingKm <= 1.0;
    final bool isFinalTenKm = !isFlammeRouge && distRemainingKm < 10.0;

    return AnimatedBuilder(
      animation: _flammePulseController,
      builder: (context, child) {
        final double pulse = _flammePulseController.value;
        final Color borderColor = isFlammeRouge
            ? AppColors.crimsonAlert.withValues(alpha: 0.65 + 0.35 * pulse)
            : (isFinalTenKm
                ? AppColors.goldAccent
                : AppTheme.borderColor);
        final Color bgColor = isFlammeRouge
            ? AppColors.crimsonAlert.withValues(alpha: 0.18 + 0.10 * pulse)
            : (isFinalTenKm
                ? AppColors.goldAccent.withValues(alpha: 0.16)
                : AppColors.surfaceLight);
        final Color kmColor = isFlammeRouge
            ? AppColors.crimsonAlert
            : (isFinalTenKm ? AppColors.goldAccent : AppColors.textPrimary);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: borderColor,
              width: isFlammeRouge || isFinalTenKm ? 1.5 : 1.0,
            ),
            boxShadow: isFlammeRouge
                ? [
                    BoxShadow(
                      color: AppColors.crimsonAlert
                          .withValues(alpha: 0.30 + 0.20 * pulse),
                      blurRadius: 12,
                    ),
                  ]
                : (isFinalTenKm
                    ? [
                        BoxShadow(
                          color: AppColors.goldAccent.withValues(alpha: 0.25),
                          blurRadius: 10,
                        ),
                      ]
                    : null),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isFlammeRouge
                        ? Icons.local_fire_department_rounded
                        : Icons.flag_rounded,
                    color: isFlammeRouge
                        ? AppColors.crimsonAlert
                        : AppColors.goldAccent,
                    size: 15,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isFlammeRouge
                        ? 'FLAMME ROUGE • ${(distRemainingKm * 1000).round()} m'
                        : '${distRemainingKm.toStringAsFixed(1)} km',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: kmColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (!isFlammeRouge) ...[
                    const SizedBox(width: 4),
                    Text(
                      'DO METY',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: isFinalTenKm
                            ? AppColors.goldAccent
                            : AppColors.textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 148,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progressFraction,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isFlammeRouge
                          ? AppColors.crimsonAlert
                          : AppColors.goldAccent,
                    ),
                    minHeight: 4,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChalkboardTogglePill(ActiveRaceSimulationState simState) {
    final double gapSec = simState.breakawayGapSeconds;
    final int gapMin = (gapSec / 60.0).floor();
    final int gapRem = (gapSec % 60.0).round();
    final String gapLabel =
        gapSec > 0 ? '+${gapMin}m ${gapRem.toString().padLeft(2, '0')}s' : '0m 00s';

    return _InteractiveHudButton(
      onTap: () => setState(() => _isChalkboardExpanded = !_isChalkboardExpanded),
      isActive: _isChalkboardExpanded,
      activeColor: AppColors.goldAccent,
      tooltip: 'Rozwiń tablicę motocyklisty (Ardoisier)',
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      borderRadius: 10,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.dashboard_customize_rounded,
            color: AppColors.goldAccent,
            size: 14,
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'ARDOISIER • RÓŻNICE',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textSecondary,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'UCIECZKA ',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.amberWarning,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    gapLabel,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.goldAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _isChalkboardExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: AppColors.textSecondary,
                    size: 14,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWindAndGradientCluster({
    required double windSpeedKmh,
    required double gradientPercent,
  }) {
    Color gradColor = AppColors.statusSuccess;
    if (gradientPercent >= 8.0) {
      gradColor = AppColors.crimsonAlert;
    } else if (gradientPercent >= 5.0) {
      gradColor = AppColors.amberWarning;
    } else if (gradientPercent < -2.0) {
      gradColor = AppColors.cyanAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Wiatr
          Transform.rotate(
            angle: 1.15,
            child: const Icon(
              Icons.navigation_rounded,
              color: AppColors.cyanAccent,
              size: 15,
            ),
          ),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${windSpeedKmh.round()} km/h',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const Text(
                'WIATR BOCZNY',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textSecondary,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Container(
            width: 1,
            height: 22,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: AppTheme.borderColor,
          ),
          // Nachylenie podjazdu
          Icon(Icons.trending_up_rounded, color: gradColor, size: 15),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${gradientPercent >= 0 ? "+" : ""}${gradientPercent.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: gradColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const Text(
                'NACHYLENIE',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textSecondary,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimulationSpeedControls(
    ActiveRaceSimulationState simState,
    RaceSimulationNotifier simController,
  ) {
    final currentSpeed = simState.timeSpeed;
    final bool isPaused = simState.isPaused;

    const speeds = [
      (SimulationTimeSpeed.x1, '1x'),
      (SimulationTimeSpeed.x2, '2x'),
      (SimulationTimeSpeed.x4, '4x'),
      (SimulationTimeSpeed.x8, '8x'),
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _InteractiveHudButton(
          onTap: () => simController.togglePause(),
          isActive: isPaused,
          activeColor: AppColors.statusSuccess,
          tooltip: isPaused ? 'Wznów symulację' : 'Pauza',
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          borderRadius: 8,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                color: isPaused ? AppColors.statusSuccess : AppColors.goldAccent,
                size: 16,
              ),
              const SizedBox(width: 3),
              Text(
                isPaused ? 'WZNÓW' : 'PAUZA',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: isPaused ? AppColors.statusSuccess : AppColors.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        ...speeds.map((item) {
          final isSelected = currentSpeed == item.$1 && !isPaused;
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: _InteractiveHudButton(
              onTap: () {
                if (isPaused) simController.resume();
                simController.setSimulationSpeed(item.$1);
              },
              isActive: isSelected,
              activeColor: AppColors.goldAccent,
              fillWhenActive: true,
              tooltip: 'Prędkość ${item.$2}',
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              borderRadius: 8,
              child: Text(
                item.$2,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: isSelected ? Colors.black : AppColors.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          );
        }),
        const SizedBox(width: 4),
        _InteractiveHudButton(
          onTap: () => simController.simulateToNextKeyMoment(),
          isActive: true,
          activeColor: AppColors.goldAccent,
          fillWhenActive: true,
          tooltip: 'Przewiń do kolejnego kluczowego momentu wyścigu',
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          borderRadius: 8,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt_rounded, color: Colors.black, size: 14),
              SizedBox(width: 4),
              Text(
                'SKOCZ DO AKCJI',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 2. LEWY PANEL KOLARZY DRUŻYNY (8 KOMPAKTOWYCH SZKLANYCH KART)
  // ===========================================================================

  Widget _buildLeftTeamRosterPanel({
    required List<RiderPositionSnapshot> playerRiders,
    required Map<String, int> rankByRiderId,
    required String? selectedRiderId,
    required RaceSimulationNotifier simController,
    required double panelWidth,
  }) {
    final ridersToDisplay = playerRiders.take(8).toList();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      width: panelWidth,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 18,
            offset: const Offset(4, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (!_isRosterCollapsed)
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.groups_2_rounded,
                        color: AppColors.goldAccent,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'DRUŻYNA (${ridersToDisplay.length})',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: AppColors.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              _InteractiveHudButton(
                onTap: () =>
                    setState(() => _isRosterCollapsed = !_isRosterCollapsed),
                tooltip: _isRosterCollapsed
                    ? 'Rozwiń karty kolarzy'
                    : 'Zwiń panel kolarzy',
                padding: const EdgeInsets.all(4),
                borderRadius: 8,
                child: Icon(
                  _isRosterCollapsed
                      ? Icons.chevron_right_rounded
                      : Icons.chevron_left_rounded,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Divider(color: AppTheme.borderColor, height: 1),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.separated(
              itemCount: ridersToDisplay.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (ctx, idx) {
                final rider = ridersToDisplay[idx];
                final bool isSelected = rider.riderId == selectedRiderId;
                final int rank = rankByRiderId[rider.riderId] ?? (idx + 1);

                return _isRosterCollapsed
                    ? _buildCollapsedRiderTile(
                        rider: rider,
                        rank: rank,
                        isSelected: isSelected,
                        simController: simController,
                      )
                    : _buildGlassRiderCard(
                        rider: rider,
                        rank: rank,
                        isSelected: isSelected,
                        simController: simController,
                      );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsedRiderTile({
    required RiderPositionSnapshot rider,
    required int rank,
    required bool isSelected,
    required RaceSimulationNotifier simController,
  }) {
    final int powerZone = _calculatePowerZone(rider.wattsPerKg);
    final Color zoneColor = AppColors.getPowerZoneColor(powerZone);

    return _InteractiveHudButton(
      onTap: () {
        simController.selectRider(rider.riderId);
        widget.onRiderSelected?.call(rider.riderId);
        setState(() => _isRiderOrdersDrawerOpen = true);
      },
      isActive: isSelected,
      activeColor: AppColors.goldAccent,
      tooltip: '#${rider.bibNumber} ${rider.riderName} ($rank.)',
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      borderRadius: 10,
      child: Column(
        children: [
          Text(
            '$rank.',
            style: TextStyle(
              fontFamily: 'Inter',
              color: isSelected ? AppColors.goldAccent : AppColors.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: zoneColor.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: zoneColor.withValues(alpha: 0.7)),
            ),
            child: Text(
              'Z$powerZone',
              style: TextStyle(
                fontFamily: 'Inter',
                color: zoneColor,
                fontSize: 8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${rider.powerWatts}W',
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textPrimary,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassRiderCard({
    required RiderPositionSnapshot rider,
    required int rank,
    required bool isSelected,
    required RaceSimulationNotifier simController,
  }) {
    final int powerZone = _calculatePowerZone(rider.wattsPerKg);
    final Color zoneColor = AppColors.getPowerZoneColor(powerZone);
    final String gearStr = _drivetrainSimulator
        .calculateGear(
          speedKmh: rider.speedKmh,
          cadenceRpm: rider.cadenceRpm,
          gradientPercent: rider.currentGradientPercent,
        )
        .displayString;

    final double glycogenFraction =
        (rider.glycogenPercentage / 100.0).clamp(0.0, 1.0);
    final double wPrimeFraction =
        (rider.wPrimePercentage / 100.0).clamp(0.0, 1.0);

    return _InteractiveHudButton(
      onTap: () {
        simController.selectRider(rider.riderId);
        widget.onRiderSelected?.call(rider.riderId);
        setState(() {
          _isRiderOrdersDrawerOpen = true;
          _isBottomConsoleExpanded = true;
        });
      },
      isActive: isSelected,
      activeColor: AppColors.goldAccent,
      padding: const EdgeInsets.all(8),
      borderRadius: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wiersz 1: Portret, Pozycja, Numer startowy, Nazwisko, Przełożenie
          Row(
            children: [
              RiderAvatarWidget(
                appearance: _buildDeterministicAppearance(rider),
                primaryJerseyColorHex: rider.teamJerseyHexColor,
                size: 30,
                borderWidth: 1.5,
                borderColor: isSelected ? AppColors.goldAccent : zoneColor,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.goldAccent.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$rank.',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              color: AppColors.goldAccent,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '#${rider.bibNumber}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: AppColors.textSecondary,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            rider.riderName,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: isSelected
                                  ? AppColors.goldAccent
                                  : AppColors.textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.settings_rounded,
                          color: AppColors.textSecondary,
                          size: 10,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          gearStr,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: AppColors.textSecondary,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.favorite_rounded,
                          color: AppColors.crimsonAlert,
                          size: 10,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${rider.heartRateBpm} bpm',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: AppColors.textPrimary,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.videocam_rounded,
                  color: AppColors.goldAccent,
                  size: 14,
                ),
            ],
          ),
          const SizedBox(height: 6),

          // Wiersz 2: Strefa mocy Z1-Z7 z kolorowym tłem (W oraz W/kg) + Prędkość
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: zoneColor.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: zoneColor.withValues(alpha: 0.55)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: zoneColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Z$powerZone',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.black,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${rider.powerWatts} W',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: zoneColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                Text(
                  '${rider.wattsPerKg.toStringAsFixed(1)} W/kg',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),

          // Wiersz 3: Dwa precyzyjne paski energii (żółty glikogen + czerwony W')
          _buildEnergyBar(
            label: 'GLIK',
            fraction: glycogenFraction,
            percentText: '${rider.glycogenPercentage.round()}%',
            barColor: glycogenFraction < 0.2
                ? AppColors.crimsonAlert
                : AppColors.amberWarning,
          ),
          const SizedBox(height: 3),
          _buildEnergyBar(
            label: "W'",
            fraction: wPrimeFraction,
            percentText: '${rider.wPrimePercentage.round()}%',
            barColor: AppColors.crimsonAlert,
          ),
          const SizedBox(height: 5),

          // Wiersz 4: Bidony, Żele oraz Ikona Aktywnego Rozkazu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _InteractiveHudButton(
                    onTap: () => simController.giveBidonToRider(rider.riderId),
                    isDisabled: rider.bidonsLeft <= 0,
                    tooltip: rider.bidonsLeft > 0
                        ? 'Podaj bidon (${rider.bidonsLeft})'
                        : 'Brak bidonów',
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    borderRadius: 5,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_drink_rounded,
                          color: rider.bidonsLeft > 0
                              ? AppColors.cyanAccent
                              : AppColors.textSecondary,
                          size: 11,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${rider.bidonsLeft}',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: rider.bidonsLeft > 0
                                ? AppColors.cyanAccent
                                : AppColors.textSecondary,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  _InteractiveHudButton(
                    onTap: () => simController.feedGelToRider(rider.riderId),
                    isDisabled: rider.gelsLeft <= 0,
                    tooltip: rider.gelsLeft > 0
                        ? 'Podaj żel energetyczny (${rider.gelsLeft})'
                        : 'Brak żeli',
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    borderRadius: 5,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bolt_rounded,
                          color: rider.gelsLeft > 0
                              ? AppColors.amberWarning
                              : AppColors.textSecondary,
                          size: 11,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${rider.gelsLeft}',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: rider.gelsLeft > 0
                                ? AppColors.amberWarning
                                : AppColors.textSecondary,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _iconForOrder(rider.activeTacticalOrder),
                      color: AppColors.goldAccent,
                      size: 10,
                    ),
                    const SizedBox(width: 3),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 74),
                      child: Text(
                        rider.activeTacticalOrder.label,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.textSecondary,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnergyBar({
    required String label,
    required double fraction,
    required String percentText,
    required Color barColor,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 26,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textSecondary,
              fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: fraction,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 4,
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 26,
          child: Text(
            percentText,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'Inter',
              color: barColor,
              fontSize: 8,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 3. PRAWY DOLNY RÓG (ON-BIKE COMPUTER + MINIMAPA + AERO VISION MODE)
  // ===========================================================================

  Widget _buildRightBottomCornerDock({
    required RaceStage stage,
    required RiderPositionSnapshot selectedSnapshot,
    required RaceSimulationNotifier simController,
    required double width,
    required bool isMobile,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      width: width,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 18,
            offset: const Offset(-2, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Nagłówek prawego doku + Przełącznik Aero Vision Mode + Zwijanie
          Row(
            children: [
              Expanded(
                child: _InteractiveHudButton(
                  onTap: () =>
                      setState(() => _isAeroVisionMode = !_isAeroVisionMode),
                  isActive: _isAeroVisionMode,
                  activeColor: AppColors.cyanAccent,
                  tooltip: 'Przełącz wizualizację tunelu aero 3D (Aero Vision)',
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  borderRadius: 10,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.air_rounded,
                        color: _isAeroVisionMode
                            ? AppColors.cyanAccent
                            : AppColors.textSecondary,
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          'Aero Vision Mode',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: _isAeroVisionMode
                                ? AppColors.cyanAccent
                                : AppColors.textPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _InteractiveHudButton(
                onTap: () => setState(
                  () => _isRightCornerCollapsed = !_isRightCornerCollapsed,
                ),
                tooltip: _isRightCornerCollapsed
                    ? 'Rozwiń minimapę i licznik'
                    : 'Zwiń prawy panel',
                padding: const EdgeInsets.all(6),
                borderRadius: 8,
                child: Icon(
                  _isRightCornerCollapsed
                      ? Icons.open_in_full_rounded
                      : Icons.close_fullscreen_rounded,
                  color: AppColors.textSecondary,
                  size: 15,
                ),
              ),
            ],
          ),

          if (!_isRightCornerCollapsed) ...[
            const SizedBox(height: 8),
            // Minimapa 2D/3D
            TacticalMinimap2dWidget(
              isCompact: true,
              width: width - 16,
              height: isMobile ? 120 : 148,
              onRiderSelected: (riderId) {
                simController.selectRider(riderId);
                widget.onRiderSelected?.call(riderId);
              },
            ),
            const SizedBox(height: 8),
            // Interaktywny komputer rowerowy (Garmin / Wahoo)
            Align(
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: OnBikeComputerHudWidget(
                  riderSnapshot: selectedSnapshot,
                  stage: stage,
                  segments: stage.segments,
                  initialLayoutMode: isMobile
                      ? BikeComputerLayoutMode.compact
                      : BikeComputerLayoutMode.standard,
                  scale: isMobile ? 0.78 : 0.88,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. DOLNA KONSOLA TAKTYCZNA (EFFORT SLIDER + TEAM PRESETS + ROZKAZY)
  // ===========================================================================

  Widget _buildBottomTacticalConsole({
    required RiderPositionSnapshot selectedSnapshot,
    required List<RiderPositionSnapshot> playerRiders,
    required RaceSimulationNotifier simController,
    required bool isMobile,
  }) {
    final double currentEffort =
        _riderEffortOverrides[selectedSnapshot.riderId] ?? 90.0;
    final RiderAeroPosition currentAero =
        _riderAeroOverrides[selectedSnapshot.riderId] ??
            RiderAeroPosition.standard;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 10 : 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.65),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Pasek nagłówka konsoli z wybranym kolarzem, zakładkami i zwijaniem
          Row(
            children: [
              const Icon(
                Icons.sports_rounded,
                color: AppColors.goldAccent,
                size: 14,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '#${selectedSnapshot.bibNumber} ${selectedSnapshot.riderName.toUpperCase()}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.goldAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ..._BottomConsoleTab.values.map((tab) {
                final bool active = _activeConsoleTab == tab;
                return Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: _InteractiveHudButton(
                    onTap: () => setState(() {
                      _activeConsoleTab = tab;
                      _isBottomConsoleExpanded = true;
                    }),
                    isActive: active,
                    activeColor: AppColors.goldAccent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    borderRadius: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tab.icon,
                          size: 12,
                          color: active
                              ? AppColors.goldAccent
                              : AppColors.textSecondary,
                        ),
                        if (!isMobile) ...[
                          const SizedBox(width: 4),
                          Text(
                            tab == _BottomConsoleTab.ordersAndEffort
                                ? 'Rozkazy'
                                : 'Taktyka Drużyny',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              fontWeight:
                                  active ? FontWeight.w900 : FontWeight.w700,
                              color: active
                                  ? AppColors.goldAccent
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(width: 6),
              _InteractiveHudButton(
                onTap: () => setState(
                  () => _isBottomConsoleExpanded = !_isBottomConsoleExpanded,
                ),
                tooltip: _isBottomConsoleExpanded
                    ? 'Zwiń konsolę taktyczną'
                    : 'Rozwiń konsolę taktyczną',
                padding: const EdgeInsets.all(4),
                borderRadius: 8,
                child: Icon(
                  _isBottomConsoleExpanded
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.keyboard_arrow_up_rounded,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
              ),
            ],
          ),

          // Animowana zawartość konsoli (wejściowa/wyjściowa)
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            child: _isBottomConsoleExpanded
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.08),
                            end: Offset.zero,
                          ).animate(anim),
                          child: child,
                        ),
                      ),
                      child: _activeConsoleTab ==
                              _BottomConsoleTab.ordersAndEffort
                          ? Column(
                              key: const ValueKey('tab_orders_effort'),
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (_isRiderOrdersDrawerOpen) ...[
                                  _buildQuickRiderOrdersRow(
                                    selectedSnapshot: selectedSnapshot,
                                    simController: simController,
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                LayoutBuilder(
                                  builder: (ctx, box) {
                                    final double targetW =
                                        math.max(box.maxWidth, 500.0);
                                    return FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.topCenter,
                                      child: SizedBox(
                                        width: targetW,
                                        child: RiderEffortSliderControl(
                                          key: ValueKey(
                                            selectedSnapshot.riderId,
                                          ),
                                          initialEffortPercent: currentEffort,
                                          initialAeroPosition: currentAero,
                                          riderName:
                                              selectedSnapshot.riderName,
                                          isCompact: true,
                                          onEffortChanged: (val) {
                                            setState(() {
                                              _riderEffortOverrides[
                                                      selectedSnapshot
                                                          .riderId] =
                                                  val;
                                            });
                                          },
                                          onPositionChanged: (pos) {
                                            setState(() {
                                              _riderAeroOverrides[
                                                      selectedSnapshot
                                                          .riderId] =
                                                  pos;
                                            });
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            )
                          : LayoutBuilder(
                              key: const ValueKey('tab_team_presets'),
                              builder: (ctx, box) {
                                final double targetW =
                                    math.max(box.maxWidth, 500.0);
                                return FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.topCenter,
                                  child: SizedBox(
                                    width: targetW,
                                    child: TeamTacticalPresetsBar(
                                      isCompact: true,
                                      onPlanExecuted: (plan) {
                                        for (final assignment
                                            in plan.assignments) {
                                          simController.setRiderTacticalOrder(
                                            assignment.riderId,
                                            assignment.order,
                                          );
                                        }
                                      },
                                      onResetTactics: () {
                                        simController.orderTeamTactics(
                                          order: TacticalOrder.holdPosition,
                                          riderIds: playerRiders
                                              .map((r) => r.riderId)
                                              .toList(),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickRiderOrdersRow({
    required RiderPositionSnapshot selectedSnapshot,
    required RaceSimulationNotifier simController,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildTacticalActionButton(
            icon: Icons.directions_bike_rounded,
            label: 'Utrzymuj Koło',
            color: AppColors.accentBlue,
            isSelected: selectedSnapshot.activeTacticalOrder ==
                    TacticalOrder.holdPosition ||
                selectedSnapshot.activeTacticalOrder ==
                    TacticalOrder.followWheels,
            onTap: () {
              simController.orderRiderHoldPosition(selectedSnapshot.riderId);
              widget.onOrderIssued?.call(TacticalOrder.holdPosition);
            },
          ),
          const SizedBox(width: 6),
          _buildTacticalActionButton(
            icon: Icons.fast_forward_rounded,
            label: 'Daj Zmianę ($_targetPullWatts W)',
            color: AppColors.statusSuccess,
            isSelected:
                selectedSnapshot.activeTacticalOrder == TacticalOrder.pullGroup,
            onTap: () =>
                _showPullWattsModal(selectedSnapshot.riderId, simController),
          ),
          const SizedBox(width: 6),
          _buildTacticalActionButton(
            icon: Icons.shield_rounded,
            label: 'Chroń Lidera',
            color: const Color(0xFF818CF8),
            isSelected: selectedSnapshot.activeTacticalOrder ==
                TacticalOrder.protectLeader,
            onTap: () {
              simController.orderRiderProtectLeader(selectedSnapshot.riderId);
              widget.onOrderIssued?.call(TacticalOrder.protectLeader);
            },
          ),
          const SizedBox(width: 6),
          _buildAttackActionButton(
            riderId: selectedSnapshot.riderId,
            simController: simController,
          ),
          const SizedBox(width: 6),
          _buildTacticalActionButton(
            icon: Icons.bolt_rounded,
            label: 'Zjedz Żel',
            color: AppColors.amberWarning,
            isSelected: false,
            isDisabled: selectedSnapshot.gelsLeft <= 0,
            onTap: () => simController.feedGelToRider(selectedSnapshot.riderId),
          ),
          const SizedBox(width: 6),
          _buildTacticalActionButton(
            icon: Icons.local_drink_rounded,
            label: 'Po Bidony',
            color: AppColors.cyanAccent,
            isSelected: selectedSnapshot.activeTacticalOrder ==
                TacticalOrder.fetchBidonsFromCar,
            onTap: () {
              simController.sendDomestiqueForBidons(selectedSnapshot.riderId);
              widget.onOrderIssued?.call(TacticalOrder.fetchBidonsFromCar);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTacticalActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
    bool isDisabled = false,
  }) {
    return _InteractiveHudButton(
      onTap: onTap,
      isActive: isSelected,
      isDisabled: isDisabled,
      activeColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      borderRadius: 8,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isDisabled
                ? AppColors.textSecondary.withValues(alpha: 0.4)
                : (isSelected ? color : AppColors.textSecondary),
            size: 14,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              color: isDisabled
                  ? AppColors.textSecondary.withValues(alpha: 0.4)
                  : (isSelected ? color : AppColors.textPrimary),
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttackActionButton({
    required String riderId,
    required RaceSimulationNotifier simController,
  }) {
    return _InteractiveHudButton(
      onTap: () {
        simController.orderRiderAttack(riderId);
        widget.onOrderIssued?.call(TacticalOrder.attack);
      },
      isActive: true,
      activeColor: AppColors.crimsonAlert,
      fillWhenActive: true,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      borderRadius: 8,
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, color: Colors.white, size: 14),
          SizedBox(width: 4),
          Text(
            'ZAATAKUJ!',
            style: TextStyle(
              fontFamily: 'Inter',
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showPullWattsModal(
    String riderId,
    RaceSimulationNotifier simController,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.speed_rounded,
                        color: AppColors.statusSuccess,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'DAJ ZMIANĘ NA CZELE PELETONU',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildWattPresetChip('Tempo Z3 (350W)', 350, setModalState),
                      _buildWattPresetChip('Próg FTP (420W)', 420, setModalState),
                      _buildWattPresetChip('Full Gas (500W)', 500, setModalState),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Moc zadana:',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '$_targetPullWatts W',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.statusSuccess,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _targetPullWatts.toDouble(),
                    min: 280,
                    max: 600,
                    divisions: 32,
                    activeColor: AppColors.statusSuccess,
                    onChanged: (val) =>
                        setModalState(() => _targetPullWatts = val.round()),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() {});
                        simController.orderRiderPullGroup(riderId);
                        widget.onOrderIssued?.call(TacticalOrder.pullGroup);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.statusSuccess,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'WYJDŹ NA PROWADZENIE',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWattPresetChip(
    String label,
    int watts,
    StateSetter setModalState,
  ) {
    final bool isSelected = _targetPullWatts == watts;
    return _InteractiveHudButton(
      onTap: () => setModalState(() => _targetPullWatts = watts),
      isActive: isSelected,
      activeColor: AppColors.statusSuccess,
      fillWhenActive: true,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      borderRadius: 8,
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          color: isSelected ? Colors.black : AppColors.textPrimary,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ===========================================================================
  // POMOCNICZE METODY TELEMETRII I FALLBACK DEMO (8 KOLARZY)
  // ===========================================================================

  List<RiderPositionSnapshot> _sortedRaceStandings(
    List<RiderPositionSnapshot> riders,
  ) {
    final copy = List<RiderPositionSnapshot>.from(riders);
    copy.sort(
      (a, b) => b.distanceCoveredMeters.compareTo(a.distanceCoveredMeters),
    );
    return copy;
  }

  int _calculatePowerZone(double wattsPerKg) {
    if (wattsPerKg < 3.0) return 1;
    if (wattsPerKg < 4.0) return 2;
    if (wattsPerKg < 4.9) return 3;
    if (wattsPerKg < 5.7) return 4;
    if (wattsPerKg < 6.5) return 5;
    if (wattsPerKg < 7.8) return 6;
    return 7;
  }

  IconData _iconForOrder(TacticalOrder order) {
    switch (order) {
      case TacticalOrder.holdPosition:
        return Icons.directions_bike_rounded;
      case TacticalOrder.pullGroup:
        return Icons.fast_forward_rounded;
      case TacticalOrder.protectLeader:
        return Icons.shield_rounded;
      case TacticalOrder.attack:
        return Icons.bolt_rounded;
      case TacticalOrder.followWheels:
        return Icons.link_rounded;
      case TacticalOrder.fetchBidonsFromCar:
        return Icons.local_drink_rounded;
      case TacticalOrder.saveEnergy:
        return Icons.battery_saver_rounded;
    }
  }

  RiderAppearance _buildDeterministicAppearance(RiderPositionSnapshot rider) {
    const skins = ['#F5D0B5', '#E8B896', '#D49A73', '#F1C7A8'];
    const hairs = ['#2C1E16', '#5A3825', '#C29B59', '#1A1A1A'];
    const lenses = ['#00E5FF', '#D4AF37', '#EF4444', '#10B981'];
    final int idx = rider.bibNumber.abs();
    return RiderAppearance(
      faceShapeIndex: idx % 3,
      skinToneHex: skins[idx % skins.length],
      hairStyleIndex: idx % 4,
      hairColorHex: hairs[idx % hairs.length],
      facialHairIndex: idx % 2,
      glassesModelId: 'aero_${idx % 3}',
      glassesLensColorHex: lenses[idx % lenses.length],
      helmetModelId: 'pro_aero',
      shoeColorHex: '#FFFFFF',
      sockHeightProportion: 0.7,
      bodyBuildType: BodyBuildType.values[idx % BodyBuildType.values.length],
    );
  }

  RaceStage _generateFallbackStage() {
    return const RaceStage(
      id: 'hud_sample_stage',
      stageNumber: 14,
      name: "Bourg d'Oisans > Alpe d'Huez",
      stageType: StageType.summitFinish,
      segments: [],
      baseTemperatureCelsius: 21.0,
      weatherCondition: WeatherCondition.sunny,
      windSpeedKmh: 16.0,
    );
  }

  List<RiderPositionSnapshot> _generateFallbackPlayerSnapshots() {
    const specs = [
      (1, 'Tadej Pogacar', 445, 6.7, 94, 178, 84.0, 74.0, 2, 2, TacticalOrder.attack, GroupType.breakaway, 135420.0),
      (2, 'Adam Yates', 410, 6.2, 90, 174, 72.0, 68.0, 2, 2, TacticalOrder.protectLeader, GroupType.breakaway, 135412.0),
      (3, 'Joao Almeida', 398, 5.9, 88, 171, 78.0, 70.0, 1, 2, TacticalOrder.pullGroup, GroupType.breakaway, 135405.0),
      (4, 'Rafal Majka', 385, 5.8, 87, 169, 65.0, 62.0, 1, 1, TacticalOrder.protectLeader, GroupType.peloton, 135350.0),
      (5, 'Marc Soler', 370, 5.2, 85, 166, 75.0, 66.0, 2, 1, TacticalOrder.holdPosition, GroupType.peloton, 135330.0),
      (6, 'Tim Wellens', 340, 4.7, 84, 158, 82.0, 78.0, 1, 2, TacticalOrder.fetchBidonsFromCar, GroupType.peloton, 135300.0),
      (7, 'Nils Politt', 330, 4.1, 83, 152, 88.0, 81.0, 2, 2, TacticalOrder.saveEnergy, GroupType.peloton, 135260.0),
      (8, 'Pavel Sivakov', 310, 4.3, 81, 148, 90.0, 84.0, 0, 1, TacticalOrder.followWheels, GroupType.grupetto, 134900.0),
    ];

    return specs.map((s) {
      return RiderPositionSnapshot(
        riderId: 'rider_demo_${s.$1}',
        riderName: s.$2,
        bibNumber: s.$1,
        teamId: 'team_uae',
        teamName: 'UAE Team Emirates',
        teamJerseyHexColor: '#D4AF37',
        isPlayerRider: true,
        distanceCoveredMeters: s.$13,
        kilometerMark: s.$13 / 1000.0,
        elevationMeters: 1840.0,
        currentGradientPercent: 8.2,
        currentSegmentIndex: 4,
        speedMs: 6.4,
        speedKmh: 23.0,
        powerWatts: s.$3,
        wattsPerKg: s.$4,
        cadenceRpm: s.$5,
        heartRateBpm: s.$6,
        wPrimePercentage: s.$7,
        wPrimeJoules: s.$7 * 240.0,
        glycogenPercentage: s.$8,
        glycogenGrams: s.$8 * 6.5,
        hydrationPercent: 84.0,
        bidonsLeft: s.$9,
        gelsLeft: s.$10,
        activeTacticalOrder: s.$11,
        groupIndex: s.$12 == GroupType.breakaway ? 0 : 1,
        groupType: s.$12,
        timeGapToLeaderSeconds: s.$1 == 1 ? 0.0 : (s.$1 * 2.5),
        lateralPositionRoad: 0.0,
        lateralOffsetRoadMeters: 0.2,
        isDrafting: s.$1 > 1,
        draftingSavingsPercent: s.$1 > 1 ? 0.28 : 0.0,
        isPulling: s.$11 == TacticalOrder.pullGroup,
      );
    }).toList();
  }
}

/// Reużywalny przycisk HUD z pełnymi stanami: hover, active, disabled i focus.
class _InteractiveHudButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final String? tooltip;
  final bool isActive;
  final bool isDisabled;
  final bool fillWhenActive;
  final Color activeColor;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const _InteractiveHudButton({
    required this.child,
    required this.onTap,
    this.tooltip,
    this.isActive = false,
    this.isDisabled = false,
    this.fillWhenActive = false,
    this.activeColor = AppColors.goldAccent,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    this.borderRadius = 10,
  });

  @override
  State<_InteractiveHudButton> createState() => _InteractiveHudButtonState();
}

class _InteractiveHudButtonState extends State<_InteractiveHudButton> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = !widget.isDisabled;
    final Color bgColor = widget.isDisabled
        ? AppColors.surface.withValues(alpha: 0.4)
        : (widget.isActive && widget.fillWhenActive
            ? widget.activeColor
            : (widget.isActive
                ? widget.activeColor.withValues(alpha: 0.18)
                : (_isHovered || _isPressed
                    ? AppColors.surfaceLight
                    : AppColors.surface.withValues(alpha: 0.85))));

    final Color borderColor = widget.isDisabled
        ? AppTheme.borderColor.withValues(alpha: 0.4)
        : (widget.isActive
            ? widget.activeColor
            : (_isFocused
                ? AppColors.cyanAccent
                : (_isHovered
                    ? widget.activeColor.withValues(alpha: 0.65)
                    : AppTheme.borderColor)));

    Widget button = FocusableActionDetector(
      enabled: enabled,
      onShowFocusHighlight: (focused) => setState(() => _isFocused = focused),
      onShowHoverHighlight: (hovered) => setState(() => _isHovered = hovered),
      mouseCursor:
          enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _isPressed = false) : null,
        onTap: enabled ? widget.onTap : null,
        child: AnimatedScale(
          scale: _isPressed && enabled ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: widget.padding,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: borderColor,
                width: widget.isActive || _isFocused ? 1.5 : 1.0,
              ),
            ),
            child: widget.child,
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      button = Tooltip(message: widget.tooltip!, child: button);
    }
    return button;
  }
}
