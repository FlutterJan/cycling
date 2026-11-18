import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pro_peloton_manager/core/theme/app_colors.dart';
import 'package:pro_peloton_manager/models/broadcast/tv_director_live_production_model.dart';

/// Kontroler stanu reżyserki transmisji telewizyjnej na żywo.
///
/// Zarządza przełączaniem kamer (`CUT` / `DISSOLVE`), kolejką grafik
/// ekranowych, dynamiczną intensywnością ataków na trasie oraz licznikiem
/// oglądalności i emocji w czasie rzeczywistym.
class TvBroadcastDirectorNotifier
    extends StateNotifier<TvDirectorLiveProductionModel> {
  TvBroadcastDirectorNotifier({
    TvDirectorLiveProductionModel? initialState,
  }) : super(
          initialState ??
              TvDirectorLiveProductionModel.createDefaultTourDeFranceStage(),
        );

  final math.Random _random = math.Random(42);
  int _attackEventTickCounter = 0;

  /// Przełącza wybraną kamerę na szynę podglądu `PREVIEW`.
  void cuePreview(String cameraId) {
    state = state.cuePreviewCamera(cameraId);
  }

  /// Wykonuje przejście `PREVIEW` -> `PROGRAM OUT` wybraną metodą (`CUT` / `DISSOLVE`).
  void takePreview({
    required BroadcastTransitionType transition,
  }) {
    state = state.takePreviewToProgram(transition: transition);
  }

  /// Natychmiastowo przełącza wskazaną kamerę na `PROGRAM OUT`.
  void cutDirectlyToCamera(
    String cameraId, {
    BroadcastTransitionType transition = BroadcastTransitionType.cut,
  }) {
    state = state.switchProgramCamera(cameraId, transition: transition);
  }

  /// Przełącza lub wyłącza emisję na żywo (`ON AIR`).
  void toggleLiveOnAir() {
    state = state.copyWith(isLiveOnAir: !state.isLiveOnAir);
  }

  /// Przypisuje kamerę do jednego z 6 dolnych monitorów podglądu.
  void assignMonitorSlot(int slotIndex, String cameraId) {
    state = state.assignMonitorDeckSlot(slotIndex, cameraId);
  }

  /// Wyzwala natychmiast na antenę wybraną grafikę ekranową (np. porównanie W/kg,
  /// profil podjazdu 3D lub powtórkę w zwolnionym tempie).
  void triggerQuickGraphic(TvGraphicOverlayType type) {
    final active = state.activeOnAirGraphic;
    if (active != null && active.type == type) {
      state = state.dismissActiveGraphic();
      return;
    }

    final existingQueued = state.pendingGraphicsQueue.where((g) => g.type == type);
    if (existingQueued.isNotEmpty) {
      state = state.triggerGraphicOnAir(existingQueued.first.id);
      return;
    }

    final item = _buildGraphicPreset(type, state.currentRaceSecond);
    final withItem = state.enqueueGraphic(item);
    state = withItem.triggerGraphicOnAir(item.id);
  }

  /// Zdejmuje aktualnie wyświetlaną grafikę z anteny.
  void dismissActiveGraphic() {
    state = state.dismissActiveGraphic();
  }

  /// Wywołuje kontrolowany atak na jednej z kamer (ucieczka / pościg / peleton),
  /// podnosząc jej `actionHeatScore`, aby reżyser mógł go złapać w kadrze.
  void triggerSimulatedRaceAttack({String? preferredCameraId}) {
    final candidates = state.cameraFeeds
        .where((c) => c.isAvailableForCut && c.cameraId != state.programCameraId)
        .toList();
    if (candidates.isEmpty) return;

    final target = preferredCameraId != null
        ? candidates.firstWhere(
            (c) => c.cameraId == preferredCameraId,
            orElse: () => candidates.first,
          )
        : candidates[_random.nextInt(candidates.length)];

    final updatedFeeds = state.cameraFeeds.map((cam) {
      if (cam.cameraId == target.cameraId) {
        return cam.copyWith(
          actionHeatScore: 92.0,
          targetGroupLabel: '${cam.targetGroupLabel} • ATAK!',
        );
      }
      return cam;
    }).toList();

    state = state.copyWith(cameraFeeds: updatedFeeds);
  }

  /// Wykonuje jedną sekundę symulacji transmisji na żywo i aktualizuje
  /// wskaźniki oglądalności oraz aktywność kamer na trasie.
  void stepLiveSecond() {
    if (!state.isLiveOnAir) return;

    _attackEventTickCounter++;
    final updatedFeeds = state.cameraFeeds.map((cam) {
      final kmDelta = cam.type == BroadcastCameraType.finishLineOverhead ||
              cam.type == BroadcastCameraType.fixedClimbCornerCam
          ? 0.0
          : 0.012;
      final drift = (_random.nextDouble() - 0.48) * 6.0;
      var nextHeat = (cam.actionHeatScore + drift).clamp(18.0, 96.0);

      // Co 9 sekund na losowej kamerze (ucieczka, peleton lub pościg) wybucha atak.
      if (_attackEventTickCounter % 9 == 0 &&
          cam.cameraId != state.programCameraId &&
          (cam.type == BroadcastCameraType.motoCamFront ||
              cam.type == BroadcastCameraType.motoCamPeloton ||
              cam.type == BroadcastCameraType.motoCamChase) &&
          _random.nextDouble() > 0.45) {
        nextHeat = 86.0 + _random.nextDouble() * 12.0;
      }

      return cam.copyWith(
        currentKilometer: math.min(
          state.stageKilometersTotal,
          cam.currentKilometer + kmDelta,
        ),
        actionHeatScore: nextHeat,
      );
    }).toList();

    final hottest = updatedFeeds.reduce(
      (a, b) => a.actionHeatScore >= b.actionHeatScore ? a : b,
    );

    final withUpdatedFeeds = state.copyWith(cameraFeeds: updatedFeeds);
    state = withUpdatedFeeds.tickSecond(
      deltaSeconds: 1,
      stageActionIntensity: hottest.actionHeatScore,
    );
  }

  BroadcastGraphicOverlayItem _buildGraphicPreset(
    TvGraphicOverlayType type,
    int raceSec,
  ) {
    switch (type) {
      case TvGraphicOverlayType.riderWkgComparison:
        return BroadcastGraphicOverlayItem(
          id: 'gfx_wkg_$raceSec',
          type: type,
          title: 'POJEDYNEK LIDERÓW GC — W/KG',
          subtitle: 'Vingegaard 6.48 W/kg vs Pogačar 6.54 W/kg • 11.8%',
          primaryRiderId: 'rider_gc_1',
          secondaryRiderId: 'rider_gc_2',
          payloadData: const {
            'leftName': 'J. VINGEGAARD',
            'leftTeam': 'TVL',
            'leftWkg': 6.48,
            'leftWatts': 415,
            'leftHr': 176,
            'rightName': 'T. POGAČAR',
            'rightTeam': 'UAD',
            'rightWkg': 6.54,
            'rightWatts': 425,
            'rightHr': 181,
            'slopePercent': 11.8,
          },
          durationSeconds: type.defaultDurationSeconds,
          remainingOnAirSeconds: type.defaultDurationSeconds,
          status: TvGraphicQueueStatus.queued,
          priority: 5,
          productionCostEur: type.defaultProductionCostEur,
          dramaBoost: type.defaultDramaBoost,
          queuedAtRaceSec: raceSec,
        );
      case TvGraphicOverlayType.climb3dProfile:
        return BroadcastGraphicOverlayItem(
          id: 'gfx_climb3d_$raceSec',
          type: type,
          title: 'COL DE LA LOZE — PROFIL PODJAZDU 3D',
          subtitle: 'Pozostało 6.4 km do szczytu • Śr. 9.2% (Max 24%)',
          payloadData: const {
            'climbName': 'Col de la Loze (HC)',
            'altitudeM': 2304,
            'remainingKm': 6.4,
            'avgSlope': 9.2,
            'maxSlope': 24.0,
          },
          durationSeconds: type.defaultDurationSeconds,
          remainingOnAirSeconds: type.defaultDurationSeconds,
          status: TvGraphicQueueStatus.queued,
          priority: 4,
          productionCostEur: type.defaultProductionCostEur,
          dramaBoost: type.defaultDramaBoost,
          queuedAtRaceSec: raceSec,
        );
      case TvGraphicOverlayType.slowMotionReplay:
        return BroadcastGraphicOverlayItem(
          id: 'gfx_slomo_$raceSec',
          type: type,
          title: 'POWTÓRKA SLOW-MOTION 0.25x',
          subtitle: 'Kluczowe przyspieszenie na serpentynie #14 (1140 W)',
          durationSeconds: type.defaultDurationSeconds,
          remainingOnAirSeconds: type.defaultDurationSeconds,
          status: TvGraphicQueueStatus.queued,
          priority: 5,
          productionCostEur: type.defaultProductionCostEur,
          dramaBoost: type.defaultDramaBoost,
          queuedAtRaceSec: raceSec,
        );
      case TvGraphicOverlayType.virtualGapAndTimeSplit:
      case TvGraphicOverlayType.liveHeartRateAndPowerHud:
      case TvGraphicOverlayType.pelotonSpeedAndWindVector:
      case TvGraphicOverlayType.intermediateSprintStandings:
      case TvGraphicOverlayType.komMountainPointsBanner:
      case TvGraphicOverlayType.teamRadioSubtitles:
      case TvGraphicOverlayType.stageSponsorLowerThird:
        return BroadcastGraphicOverlayItem(
          id: 'gfx_${type.name}_$raceSec',
          type: type,
          title: type.displayNamePl.toUpperCase(),
          subtitle: 'Sygnał na żywo • ${state.programCamera.targetGroupLabel}',
          durationSeconds: type.defaultDurationSeconds,
          remainingOnAirSeconds: type.defaultDurationSeconds,
          status: TvGraphicQueueStatus.queued,
          priority: 3,
          productionCostEur: type.defaultProductionCostEur,
          dramaBoost: type.defaultDramaBoost,
          queuedAtRaceSec: raceSec,
        );
    }
  }
}

/// Provider stanu Reżyserki Telewizyjnej na Żywo.
final tvBroadcastDirectorProvider = StateNotifierProvider.autoDispose<
    TvBroadcastDirectorNotifier, TvDirectorLiveProductionModel>(
  (ref) => TvBroadcastDirectorNotifier(),
);

/// Główny ekran **Reżyserki Telewizyjnej (`TvBroadcastDirectorControlRoomScreen`)**.
///
/// Oferuje:
/// - centralny podgląd głównego obrazu na żywo (`PROGRAM OUT`) z nakładkami grafik TV,
/// - dolny rząd 6 mniejszych monitorów podglądu na żywo z różnych miejsc wyścigu,
/// - przyciski natychmiastowego przełączania kamer (`CUT` / `DISSOLVE`),
/// - wyzwalacze grafik ekranowych (porównanie W/kg dwóch liderów, profil podjazdu 3D, powtórka slow-mo),
/// - licznik oglądalności i emocji rosnący w czasie rzeczywistym przy łapaniu ataków.
class TvBroadcastDirectorControlRoomScreen extends ConsumerStatefulWidget {
  const TvBroadcastDirectorControlRoomScreen({
    super.key,
    this.isReadOnly = false,
    this.enableLiveTicker = true,
    this.onBack,
  });

  /// Tryb tylko do odczytu (blokuje przełączanie kamer i wyzwalanie grafik).
  final bool isReadOnly;

  /// Czy uruchamiać automatyczny 1-sekundowy timer transmisji na żywo.
  final bool enableLiveTicker;

  /// Opcjonalna akcja powrotu z ekranu reżyserki.
  final VoidCallback? onBack;

  @override
  ConsumerState<TvBroadcastDirectorControlRoomScreen> createState() =>
      _TvBroadcastDirectorControlRoomScreenState();
}

class _TvBroadcastDirectorControlRoomScreenState
    extends ConsumerState<TvBroadcastDirectorControlRoomScreen>
    with TickerProviderStateMixin {
  Timer? _liveTickerTimer;
  late final AnimationController _pulseController;
  late final AnimationController _feedMotionController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..repeat(reverse: true);

    _feedMotionController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    if (widget.enableLiveTicker) {
      _liveTickerTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) {
          if (!mounted) return;
          ref.read(tvBroadcastDirectorProvider.notifier).stepLiveSecond();
        },
      );
    }
  }

  @override
  void dispose() {
    _liveTickerTimer?.cancel();
    _pulseController.dispose();
    _feedMotionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = ref.watch(tvBroadcastDirectorProvider);
    final notifier = ref.read(tvBroadcastDirectorProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isDesktop = width >= 1200;
            final isTablet = width >= 720 && width < 1200;

            return Column(
              children: [
                _BroadcastTopHeaderBar(
                  model: model,
                  pulseAnimation: _pulseController,
                  isCompact: !isDesktop && !isTablet,
                  isReadOnly: widget.isReadOnly,
                  onBack: widget.onBack ?? () => Navigator.of(context).maybePop(),
                  onToggleLive: widget.isReadOnly ? null : notifier.toggleLiveOnAir,
                  onSimulateAttack: widget.isReadOnly
                      ? null
                      : () => notifier.triggerSimulatedRaceAttack(),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isDesktop ? 16 : 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (isDesktop)
                          _buildDesktopMainWorkspace(model, notifier)
                        else if (isTablet)
                          _buildTabletMainWorkspace(model, notifier)
                        else
                          _buildMobileMainWorkspace(model, notifier),
                        const SizedBox(height: 14),
                        _SixMonitorMultiviewerDeck(
                          model: model,
                          motionAnimation: _feedMotionController,
                          pulseAnimation: _pulseController,
                          isDesktop: isDesktop,
                          isTablet: isTablet,
                          isReadOnly: widget.isReadOnly,
                          onCuePreview: (id) => notifier.cuePreview(id),
                          onQuickCut: (id) => notifier.cutDirectlyToCamera(
                            id,
                            transition: BroadcastTransitionType.cut,
                          ),
                          onAssignSlot: (slotIndex, cameraId) =>
                              notifier.assignMonitorSlot(slotIndex, cameraId),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDesktopMainWorkspace(
    TvDirectorLiveProductionModel model,
    TvBroadcastDirectorNotifier notifier,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 7,
          child: _ProgramOutViewportCard(
            model: model,
            motionAnimation: _feedMotionController,
            pulseAnimation: _pulseController,
            isReadOnly: widget.isReadOnly,
            onDismissGraphic: notifier.dismissActiveGraphic,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          flex: 5,
          child: Column(
            children: [
              _PreviewAndSwitcherConsoleCard(
                model: model,
                motionAnimation: _feedMotionController,
                isReadOnly: widget.isReadOnly,
                onCut: () => notifier.takePreview(
                  transition: BroadcastTransitionType.cut,
                ),
                onDissolve: () => notifier.takePreview(
                  transition: BroadcastTransitionType.dissolve,
                ),
                onAutoHotCam: () => notifier.cutDirectlyToCamera(
                  model.hottestCameraFeed.cameraId,
                  transition: BroadcastTransitionType.cut,
                ),
              ),
              const SizedBox(height: 14),
              _GraphicsAndViewershipControlCard(
                model: model,
                isReadOnly: widget.isReadOnly,
                onTriggerGraphic: notifier.triggerQuickGraphic,
                onDismissGraphic: notifier.dismissActiveGraphic,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabletMainWorkspace(
    TvDirectorLiveProductionModel model,
    TvBroadcastDirectorNotifier notifier,
  ) {
    return Column(
      children: [
        _ProgramOutViewportCard(
          model: model,
          motionAnimation: _feedMotionController,
          pulseAnimation: _pulseController,
          isReadOnly: widget.isReadOnly,
          onDismissGraphic: notifier.dismissActiveGraphic,
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _PreviewAndSwitcherConsoleCard(
                model: model,
                motionAnimation: _feedMotionController,
                isReadOnly: widget.isReadOnly,
                onCut: () => notifier.takePreview(
                  transition: BroadcastTransitionType.cut,
                ),
                onDissolve: () => notifier.takePreview(
                  transition: BroadcastTransitionType.dissolve,
                ),
                onAutoHotCam: () => notifier.cutDirectlyToCamera(
                  model.hottestCameraFeed.cameraId,
                  transition: BroadcastTransitionType.cut,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _GraphicsAndViewershipControlCard(
                model: model,
                isReadOnly: widget.isReadOnly,
                onTriggerGraphic: notifier.triggerQuickGraphic,
                onDismissGraphic: notifier.dismissActiveGraphic,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileMainWorkspace(
    TvDirectorLiveProductionModel model,
    TvBroadcastDirectorNotifier notifier,
  ) {
    return Column(
      children: [
        _ProgramOutViewportCard(
          model: model,
          motionAnimation: _feedMotionController,
          pulseAnimation: _pulseController,
          isReadOnly: widget.isReadOnly,
          onDismissGraphic: notifier.dismissActiveGraphic,
        ),
        const SizedBox(height: 12),
        _PreviewAndSwitcherConsoleCard(
          model: model,
          motionAnimation: _feedMotionController,
          isReadOnly: widget.isReadOnly,
          onCut: () => notifier.takePreview(
            transition: BroadcastTransitionType.cut,
          ),
          onDissolve: () => notifier.takePreview(
            transition: BroadcastTransitionType.dissolve,
          ),
          onAutoHotCam: () => notifier.cutDirectlyToCamera(
            model.hottestCameraFeed.cameraId,
            transition: BroadcastTransitionType.cut,
          ),
        ),
        const SizedBox(height: 12),
        _GraphicsAndViewershipControlCard(
          model: model,
          isReadOnly: widget.isReadOnly,
          onTriggerGraphic: notifier.triggerQuickGraphic,
          onDismissGraphic: notifier.dismissActiveGraphic,
        ),
      ],
    );
  }
}

/// Górny pasek reżyserki z zegarem wyścigu, statusem `ON AIR` i licznikiem oglądalności.
class _BroadcastTopHeaderBar extends StatelessWidget {
  const _BroadcastTopHeaderBar({
    required this.model,
    required this.pulseAnimation,
    required this.isCompact,
    required this.isReadOnly,
    required this.onBack,
    required this.onToggleLive,
    required this.onSimulateAttack,
  });

  final TvDirectorLiveProductionModel model;
  final Animation<double> pulseAnimation;
  final bool isCompact;
  final bool isReadOnly;
  final VoidCallback onBack;
  final VoidCallback? onToggleLive;
  final VoidCallback? onSimulateAttack;

  @override
  Widget build(BuildContext context) {
    final metrics = model.viewershipMetrics;
    final budget = model.productionBudget;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 16,
        vertical: 10,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.cardBorder, width: 1.0),
        ),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DirectorIconButton(
                icon: Icons.arrow_back_rounded,
                tooltip: 'Powrót',
                onPressed: onBack,
              ),
              const SizedBox(width: 10),
              _OnAirLiveBadge(
                isLive: model.isLiveOnAir,
                pulseAnimation: pulseAnimation,
                onTap: onToggleLive,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'REŻYSERKA TV — ${model.raceName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      model.stageTitle,
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
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _TelemetryMetricChip(
                icon: Icons.visibility_rounded,
                label: 'OGLĄDALNOŚĆ',
                value: '${metrics.viewershipMillions.toStringAsFixed(2)}M',
                accentColor: AppColors.cyanAccent,
                subValue:
                    '${metrics.audienceEngagementTrend >= 0 ? '+' : ''}${metrics.audienceEngagementTrend.toStringAsFixed(1)}/m',
              ),
              _TelemetryMetricChip(
                icon: Icons.local_fire_department_rounded,
                label: 'EMOCJE',
                value: '${metrics.dramaRating.toStringAsFixed(0)}/100',
                accentColor: metrics.dramaRating >= 75
                    ? AppColors.crimsonAlert
                    : AppColors.goldAccent,
                subValue: metrics.dramaTier.displayNamePl,
              ),
              _TelemetryMetricChip(
                icon: Icons.bolt_rounded,
                label: 'ZŁAPANE ATAKI',
                value: '${model.capturedPeakMomentsCount}',
                accentColor: AppColors.statusSuccess,
              ),
              if (!isCompact)
                _TelemetryMetricChip(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'BUDŻET OB',
                  value: '${(budget.remainingBudgetEur / 1000).toStringAsFixed(1)}k €',
                  accentColor: budget.isOverBudget
                      ? AppColors.crimsonAlert
                      : AppColors.accentBlue,
                ),
              _TelemetryMetricChip(
                icon: Icons.schedule_rounded,
                label: 'CZAS',
                value: _formatRaceClock(model.currentRaceSecond),
                accentColor: AppColors.textPrimary,
              ),
              _DirectorActionButton(
                label: 'SYMULUJ ATAK',
                icon: Icons.flash_on_rounded,
                backgroundColor: AppColors.amberWarning.withValues(alpha: 0.16),
                borderColor: AppColors.amberWarning,
                textColor: AppColors.amberWarning,
                isDisabled: isReadOnly || onSimulateAttack == null,
                onPressed: onSimulateAttack,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatRaceClock(int totalSeconds) {
    final hrs = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final mins = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$hrs:$mins:$secs';
  }
}

/// Główny centralny monitor `PROGRAM OUT` pokazujący bieżącą kamerę i grafiki TV.
class _ProgramOutViewportCard extends StatelessWidget {
  const _ProgramOutViewportCard({
    required this.model,
    required this.motionAnimation,
    required this.pulseAnimation,
    required this.isReadOnly,
    required this.onDismissGraphic,
  });

  final TvDirectorLiveProductionModel model;
  final Animation<double> motionAnimation;
  final Animation<double> pulseAnimation;
  final bool isReadOnly;
  final VoidCallback onDismissGraphic;

  @override
  Widget build(BuildContext context) {
    final cam = model.programCamera;
    final activeGraphic = model.activeOnAirGraphic;
    final transitionDuration = Duration(
      milliseconds: model.lastTransitionDurationMs,
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: model.isLiveOnAir
              ? AppColors.crimsonAlert.withValues(alpha: 0.85)
              : AppColors.cardBorder,
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: const BoxDecoration(
              color: AppColors.surfaceLight,
              border: Border(
                bottom: BorderSide(color: AppColors.cardBorder, width: 1.0),
              ),
            ),
            child: Wrap(
              spacing: 10,
              runSpacing: 6,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.crimsonAlert,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'PROGRAM OUT',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    Text(
                      '${cam.label} • ${cam.type.displayNamePl}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SignalPill(
                      label: 'KM ${cam.currentKilometer.toStringAsFixed(1)}',
                      color: AppColors.goldAccent,
                    ),
                    const SizedBox(width: 6),
                    _SignalPill(
                      label: 'RF ${cam.signalStrengthPercent.toStringAsFixed(0)}%',
                      color: cam.signalStrengthPercent >= 80
                          ? AppColors.statusSuccess
                          : AppColors.amberWarning,
                    ),
                    const SizedBox(width: 6),
                    _SignalPill(
                      label: 'AKCJA ${cam.actionHeatScore.toStringAsFixed(0)}',
                      color: cam.actionHeatScore >= 75
                          ? AppColors.crimsonAlert
                          : AppColors.accentBlue,
                    ),
                  ],
                ),
              ],
            ),
          ),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedSwitcher(
                  duration: transitionDuration,
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeOutCubic,
                  child: AnimatedBuilder(
                    key: ValueKey<String>(cam.cameraId),
                    animation: motionAnimation,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _BroadcastLiveCameraCanvasPainter(
                          camera: cam,
                          progress: motionAnimation.value,
                          isProgramOut: true,
                        ),
                        child: const SizedBox.expand(),
                      );
                    },
                  ),
                ),
                // Górny lewy watermark transmisji światowej
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.cardBorder,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: pulseAnimation,
                          builder: (context, _) {
                            return Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.crimsonAlert.withValues(
                                  alpha: 0.45 + 0.55 * pulseAnimation.value,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${cam.targetGroupLabel} • FOV ${cam.fovDegrees.toStringAsFixed(0)}°',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Pasek aktywnej grafiki telewizyjnej na antenie
                if (activeGraphic != null)
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: _OnAirTvGraphicOverlayWidget(
                      graphic: activeGraphic,
                      isReadOnly: isReadOnly,
                      onDismiss: onDismissGraphic,
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

/// Konsola szyny `PREVIEW` oraz przycisków przełączania `CUT` i `DISSOLVE`.
class _PreviewAndSwitcherConsoleCard extends StatelessWidget {
  const _PreviewAndSwitcherConsoleCard({
    required this.model,
    required this.motionAnimation,
    required this.isReadOnly,
    required this.onCut,
    required this.onDissolve,
    required this.onAutoHotCam,
  });

  final TvDirectorLiveProductionModel model;
  final Animation<double> motionAnimation;
  final bool isReadOnly;
  final VoidCallback onCut;
  final VoidCallback onDissolve;
  final VoidCallback onAutoHotCam;

  @override
  Widget build(BuildContext context) {
    final preview = model.previewCamera;
    final hottest = model.hottestCameraFeed;
    final isHotCameraWaiting =
        hottest.cameraId != model.programCameraId && hottest.actionHeatScore >= 75;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.statusSuccess.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.statusSuccess),
                    ),
                    child: const Text(
                      'PREVIEW BUS',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.statusSuccess,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    preview.label,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                'CIĘCIA: ${model.totalCameraCuts}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 106,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AnimatedBuilder(
                    animation: motionAnimation,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _BroadcastLiveCameraCanvasPainter(
                          camera: preview,
                          progress: motionAnimation.value,
                          isProgramOut: false,
                        ),
                      );
                    },
                  ),
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${preview.targetGroupLabel} • KM ${preview.currentKilometer.toStringAsFixed(1)}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DirectorActionButton(
                  label: 'CUT (0ms)',
                  icon: Icons.content_cut_rounded,
                  backgroundColor: AppColors.primaryAccent,
                  borderColor: AppColors.crimsonAlert,
                  textColor: Colors.white,
                  isDisabled: isReadOnly,
                  onPressed: onCut,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DirectorActionButton(
                  label: 'DISSOLVE (320ms)',
                  icon: Icons.blur_linear_rounded,
                  backgroundColor: AppColors.surfaceLight,
                  borderColor: AppColors.goldAccent,
                  textColor: AppColors.goldAccent,
                  isDisabled: isReadOnly,
                  onPressed: onDissolve,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _DirectorActionButton(
            label: isHotCameraWaiting
                ? 'ŁAP ATAK NA ŻYWO → ${hottest.label} (${hottest.actionHeatScore.toStringAsFixed(0)})'
                : 'AUTO-ŚLEDZENIE NAJGORĘTSZEJ KAMERY (${hottest.label})',
            icon: Icons.track_changes_rounded,
            backgroundColor: isHotCameraWaiting
                ? AppColors.crimsonAlert.withValues(alpha: 0.18)
                : AppColors.surfaceLight,
            borderColor: isHotCameraWaiting
                ? AppColors.crimsonAlert
                : AppColors.cardBorder,
            textColor: isHotCameraWaiting
                ? AppColors.crimsonAlert
                : AppColors.textSecondary,
            isDisabled: isReadOnly || hottest.cameraId == model.programCameraId,
            onPressed: onAutoHotCam,
          ),
        ],
      ),
    );
  }
}

/// Panel wyzwalaczy grafik ekranowych oraz podsumowania jakości reżyserii.
class _GraphicsAndViewershipControlCard extends StatelessWidget {
  const _GraphicsAndViewershipControlCard({
    required this.model,
    required this.isReadOnly,
    required this.onTriggerGraphic,
    required this.onDismissGraphic,
  });

  final TvDirectorLiveProductionModel model;
  final bool isReadOnly;
  final ValueChanged<TvGraphicOverlayType> onTriggerGraphic;
  final VoidCallback onDismissGraphic;

  @override
  Widget build(BuildContext context) {
    final activeType = model.activeOnAirGraphic?.type;
    final budget = model.productionBudget;
    final metrics = model.viewershipMetrics;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'WYZWALACZE GRAFIK EKRANOWYCH',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              if (model.activeOnAirGraphic != null)
                TextButton.icon(
                  onPressed: isReadOnly ? null : onDismissGraphic,
                  icon: const Icon(Icons.close_rounded, size: 15),
                  label: Text(
                    'ZDEJMIJ (${model.activeOnAirGraphic!.remainingOnAirSeconds}s)',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.crimsonAlert,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _GraphicTriggerTile(
            title: 'Porównanie W/kg Liderów',
            subtitle: 'Bezpośredni pojedynek mocy i tętna na podjeździe',
            icon: Icons.compare_arrows_rounded,
            type: TvGraphicOverlayType.riderWkgComparison,
            isActive: activeType == TvGraphicOverlayType.riderWkgComparison,
            canAfford: budget.canAfford(
              TvGraphicOverlayType.riderWkgComparison.defaultProductionCostEur,
            ),
            isReadOnly: isReadOnly,
            onTap: () =>
                onTriggerGraphic(TvGraphicOverlayType.riderWkgComparison),
          ),
          const SizedBox(height: 8),
          _GraphicTriggerTile(
            title: 'Profil Podjazdu 3D',
            subtitle: 'Izometryczna mapa nachylenia i dystans do szczytu',
            icon: Icons.terrain_rounded,
            type: TvGraphicOverlayType.climb3dProfile,
            isActive: activeType == TvGraphicOverlayType.climb3dProfile,
            canAfford: budget.canAfford(
              TvGraphicOverlayType.climb3dProfile.defaultProductionCostEur,
            ),
            isReadOnly: isReadOnly,
            onTap: () => onTriggerGraphic(TvGraphicOverlayType.climb3dProfile),
          ),
          const SizedBox(height: 8),
          _GraphicTriggerTile(
            title: 'Powtórka Slow-Motion 0.25x',
            subtitle: 'Zwolnione tempo decydującego ataku lub sprintu',
            icon: Icons.slow_motion_video_rounded,
            type: TvGraphicOverlayType.slowMotionReplay,
            isActive: activeType == TvGraphicOverlayType.slowMotionReplay,
            canAfford: budget.canAfford(
              TvGraphicOverlayType.slowMotionReplay.defaultProductionCostEur,
            ),
            isReadOnly: isReadOnly,
            onTap: () => onTriggerGraphic(TvGraphicOverlayType.slowMotionReplay),
          ),
          const SizedBox(height: 8),
          _GraphicTriggerTile(
            title: 'Różnica Czasu & Wirtualny Lider',
            subtitle: 'Strata peletonu i klasyfikacja generalna na żywo',
            icon: Icons.timer_rounded,
            type: TvGraphicOverlayType.virtualGapAndTimeSplit,
            isActive: activeType == TvGraphicOverlayType.virtualGapAndTimeSplit,
            canAfford: budget.canAfford(
              TvGraphicOverlayType
                  .virtualGapAndTimeSplit.defaultProductionCostEur,
            ),
            isReadOnly: isReadOnly,
            onTap: () =>
                onTriggerGraphic(TvGraphicOverlayType.virtualGapAndTimeSplit),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  'OCENA REŻYSERII: ${metrics.directorSkillScore.toStringAsFixed(1)}/100',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.goldAccent,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  'REKORD: ${metrics.peakViewershipMillions.toStringAsFixed(2)}M',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.cyanAccent,
                    fontFeatures: [FontFeature.tabularFigures()],
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

/// Dolny rząd 6 mniejszych monitorów podglądu na żywo z różnych miejsc wyścigu.
class _SixMonitorMultiviewerDeck extends StatelessWidget {
  const _SixMonitorMultiviewerDeck({
    required this.model,
    required this.motionAnimation,
    required this.pulseAnimation,
    required this.isDesktop,
    required this.isTablet,
    required this.isReadOnly,
    required this.onCuePreview,
    required this.onQuickCut,
    required this.onAssignSlot,
  });

  final TvDirectorLiveProductionModel model;
  final Animation<double> motionAnimation;
  final Animation<double> pulseAnimation;
  final bool isDesktop;
  final bool isTablet;
  final bool isReadOnly;
  final ValueChanged<String> onCuePreview;
  final ValueChanged<String> onQuickCut;
  final void Function(int slotIndex, String cameraId) onAssignSlot;

  @override
  Widget build(BuildContext context) {
    final feeds = model.sixMonitorDeckFeeds;
    final crossAxisCount = isDesktop ? 6 : (isTablet ? 3 : 2);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'MULTIVIEWER — 6 MONITORÓW PODGLĄDU NA ŻYWO',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.4,
                ),
              ),
              Text(
                'Kliknij: PREVIEW • Przycisk CUT: NA ANTENĘ',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textSecondary.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: feeds.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: isDesktop ? 1.15 : 1.22,
            ),
            itemBuilder: (context, index) {
              final feed = feeds[index];
              final isProgram = feed.cameraId == model.programCameraId;
              final isPreview = feed.cameraId == model.previewCameraId;

              return _LiveMonitorTile(
                slotIndex: index,
                feed: feed,
                allCameras: model.cameraFeeds,
                isProgram: isProgram,
                isPreview: isPreview,
                motionAnimation: motionAnimation,
                pulseAnimation: pulseAnimation,
                isReadOnly: isReadOnly,
                onTapCue: () => onCuePreview(feed.cameraId),
                onQuickCut: () => onQuickCut(feed.cameraId),
                onSwapCamera: (newId) => onAssignSlot(index, newId),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LiveMonitorTile extends StatefulWidget {
  const _LiveMonitorTile({
    required this.slotIndex,
    required this.feed,
    required this.allCameras,
    required this.isProgram,
    required this.isPreview,
    required this.motionAnimation,
    required this.pulseAnimation,
    required this.isReadOnly,
    required this.onTapCue,
    required this.onQuickCut,
    required this.onSwapCamera,
  });

  final int slotIndex;
  final BroadcastCameraFeed feed;
  final List<BroadcastCameraFeed> allCameras;
  final bool isProgram;
  final bool isPreview;
  final Animation<double> motionAnimation;
  final Animation<double> pulseAnimation;
  final bool isReadOnly;
  final VoidCallback onTapCue;
  final VoidCallback onQuickCut;
  final ValueChanged<String> onSwapCamera;

  @override
  State<_LiveMonitorTile> createState() => _LiveMonitorTileState();
}

class _LiveMonitorTileState extends State<_LiveMonitorTile> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final isHot = widget.feed.actionHeatScore >= 75.0;
    final borderColor = widget.isProgram
        ? AppColors.crimsonAlert
        : widget.isPreview
            ? AppColors.statusSuccess
            : (_isHovered || _isFocused)
                ? AppColors.goldAccent
                : AppColors.cardBorder;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      child: Material(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: widget.isReadOnly ? null : widget.onTapCue,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor,
                width: widget.isProgram || widget.isPreview ? 2.0 : 1.0,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AnimatedBuilder(
                        animation: widget.motionAnimation,
                        builder: (context, _) {
                          return CustomPaint(
                            painter: _BroadcastLiveCameraCanvasPainter(
                              camera: widget.feed,
                              progress: widget.motionAnimation.value,
                              isProgramOut: widget.isProgram,
                            ),
                          );
                        },
                      ),
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: widget.isProgram
                                ? AppColors.crimsonAlert
                                : widget.isPreview
                                    ? AppColors.statusSuccess
                                    : AppColors.background.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.isProgram
                                ? 'PGM'
                                : widget.isPreview
                                    ? 'PVW'
                                    : 'MON ${widget.slotIndex + 1}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      if (isHot)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: AnimatedBuilder(
                            animation: widget.pulseAnimation,
                            builder: (context, _) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.amberWarning.withValues(
                                    alpha: 0.7 + 0.3 * widget.pulseAnimation.value,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'ATAK!',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.feed.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              widget.feed.targetGroupLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!widget.isReadOnly) ...[
                        PopupMenuButton<String>(
                          tooltip: 'Zmień kamerę na monitorze',
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.cameraswitch_rounded,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          color: AppColors.surface,
                          onSelected: widget.onSwapCamera,
                          itemBuilder: (context) {
                            return widget.allCameras
                                .map(
                                  (c) => PopupMenuItem<String>(
                                    value: c.cameraId,
                                    child: Text(
                                      '${c.label} (${c.targetGroupLabel})',
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                )
                                .toList();
                          },
                        ),
                        const SizedBox(width: 2),
                        InkWell(
                          onTap: widget.isProgram ? null : widget.onQuickCut,
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: widget.isProgram
                                  ? AppColors.cardBorder
                                  : AppColors.primaryAccent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'CUT',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: widget.isProgram
                                    ? AppColors.textSecondary
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
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

/// Nakładka wywołanej grafiki telewizyjnej wyświetlana na żywo wewnątrz `PROGRAM OUT`.
class _OnAirTvGraphicOverlayWidget extends StatelessWidget {
  const _OnAirTvGraphicOverlayWidget({
    required this.graphic,
    required this.isReadOnly,
    required this.onDismiss,
  });

  final BroadcastGraphicOverlayItem graphic;
  final bool isReadOnly;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    switch (graphic.type) {
      case TvGraphicOverlayType.riderWkgComparison:
        return _buildWkgComparisonCard();
      case TvGraphicOverlayType.climb3dProfile:
        return _buildClimb3dProfileCard();
      case TvGraphicOverlayType.slowMotionReplay:
        return _buildSlowMotionBanner();
      default:
        return _buildGenericLowerThird();
    }
  }

  Widget _buildWkgComparisonCard() {
    final p = graphic.payloadData;
    final leftName = p['leftName']?.toString() ?? 'LIDER GC #1';
    final rightName = p['rightName']?.toString() ?? 'RYWAL GC #2';
    final leftWkg = (p['leftWkg'] as num?)?.toDouble() ?? 6.48;
    final rightWkg = (p['rightWkg'] as num?)?.toDouble() ?? 6.54;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.goldAccent, width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  leftName,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.goldAccent,
                  ),
                ),
                Text(
                  '${leftWkg.toStringAsFixed(2)} W/kg',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryAccent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'VS • ${graphic.remainingOnAirSeconds}s',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  rightName,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.cyanAccent,
                  ),
                ),
                Text(
                  '${rightWkg.toStringAsFixed(2)} W/kg',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClimb3dProfileCard() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentBlue, width: 1.5),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            height: 44,
            child: CustomPaint(painter: _Climb3dMiniProfilePainter()),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  graphic.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accentBlue,
                  ),
                ),
                Text(
                  graphic.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${graphic.remainingOnAirSeconds}s',
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

  Widget _buildSlowMotionBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.amberWarning, width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.slow_motion_video_rounded,
            color: AppColors.amberWarning,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  graphic.title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.amberWarning,
                  ),
                ),
                Text(
                  graphic.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (!isReadOnly)
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close_rounded, size: 18),
              color: AppColors.textSecondary,
              tooltip: 'Zakończ powtórkę',
            ),
        ],
      ),
    );
  }

  Widget _buildGenericLowerThird() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.goldAccent, width: 1.2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  graphic.title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.goldAccent,
                  ),
                ),
                Text(
                  graphic.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${graphic.remainingOnAirSeconds}s',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Rysuje dynamiczny, stylizowany obraz z wybranej kamery wyścigu kolarskiego.
class _BroadcastLiveCameraCanvasPainter extends CustomPainter {
  _BroadcastLiveCameraCanvasPainter({
    required this.camera,
    required this.progress,
    required this.isProgramOut,
  });

  final BroadcastCameraFeed camera;
  final double progress;
  final bool isProgramOut;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: camera.type.isAerial
            ? const [Color(0xFF101827), Color(0xFF1A2436)]
            : camera.type == BroadcastCameraType.teamCarInterior
                ? const [Color(0xFF14171F), Color(0xFF20242F)]
                : const [Color(0xFF121620), Color(0xFF1B202C)],
      ).createShader(rect);
    canvas.drawRect(rect, skyPaint);

    // Subtelna siatka horyzontu / gór
    final ridgePath = Path()
      ..moveTo(0, size.height * 0.42)
      ..lineTo(size.width * 0.22, size.height * 0.26)
      ..lineTo(size.width * 0.48, size.height * 0.38)
      ..lineTo(size.width * 0.74, size.height * 0.22)
      ..lineTo(size.width, size.height * 0.36)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      ridgePath,
      Paint()..color = const Color(0xFF1F2736).withValues(alpha: 0.7),
    );

    // Droga / serpentyna dostosowana do typu kamery
    final roadPaint = Paint()
      ..color = const Color(0xFF2A3140)
      ..style = PaintingStyle.stroke
      ..strokeWidth = camera.type.isAerial ? size.height * 0.14 : size.height * 0.26
      ..strokeCap = StrokeCap.round;

    final roadPath = Path();
    if (camera.type.isAerial) {
      roadPath.moveTo(0, size.height * 0.78);
      roadPath.cubicTo(
        size.width * 0.3,
        size.height * 0.55,
        size.width * 0.65,
        size.height * 0.85,
        size.width,
        size.height * 0.48,
      );
    } else {
      roadPath.moveTo(size.width * 0.08, size.height);
      roadPath.quadraticBezierTo(
        size.width * 0.48,
        size.height * 0.58,
        size.width * 0.65,
        size.height * 0.42,
      );
    }
    canvas.drawPath(roadPath, roadPaint);

    // Linia osi jezdni (animowana)
    final centerLinePaint = Paint()
      ..color = AppColors.goldAccent.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(roadPath, centerLinePaint);

    // Punkty kolarzy poruszające się po trasie
    final riderCount = camera.type == BroadcastCameraType.motoCamPeloton
        ? 10
        : camera.type == BroadcastCameraType.teamCarInterior
            ? 2
            : 4;
    for (var i = 0; i < riderCount; i++) {
      final t = ((progress + i * 0.09) % 1.0);
      final x = size.width * (0.2 + t * 0.62);
      final y = size.height *
          (0.68 - math.sin(t * math.pi) * 0.16 + (i % 3 - 1) * 0.03);
      final color = i == 0
          ? AppColors.goldAccent
          : (i == 1 ? AppColors.cyanAccent : AppColors.crimsonAlert);
      canvas.drawCircle(
        Offset(x, y),
        isProgramOut ? 5.2 : 3.4,
        Paint()..color = color,
      );
    }

    // Celownik stabilizatora kamery
    if (camera.hasStabilizerLocked) {
      final reticlePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(size.width * 0.5, size.height * 0.52),
          width: size.width * 0.24,
          height: size.height * 0.28,
        ),
        reticlePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BroadcastLiveCameraCanvasPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.camera.cameraId != camera.cameraId ||
        oldDelegate.isProgramOut != isProgramOut;
  }
}

class _Climb3dMiniProfilePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final profile = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width * 0.2, size.height * 0.72)
      ..lineTo(size.width * 0.45, size.height * 0.58)
      ..lineTo(size.width * 0.7, size.height * 0.28)
      ..lineTo(size.width, size.height * 0.12)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(
      profile,
      Paint()
        ..shader = LinearGradient(
          colors: [
            AppColors.accentBlue.withValues(alpha: 0.7),
            AppColors.crimsonAlert.withValues(alpha: 0.85),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.28),
      4,
      Paint()..color = AppColors.goldAccent,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GraphicTriggerTile extends StatefulWidget {
  const _GraphicTriggerTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.type,
    required this.isActive,
    required this.canAfford,
    required this.isReadOnly,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final TvGraphicOverlayType type;
  final bool isActive;
  final bool canAfford;
  final bool isReadOnly;
  final VoidCallback onTap;

  @override
  State<_GraphicTriggerTile> createState() => _GraphicTriggerTileState();
}

class _GraphicTriggerTileState extends State<_GraphicTriggerTile> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.isReadOnly || !widget.canAfford;
    final borderColor = widget.isActive
        ? AppColors.goldAccent
        : (_isHovered || _isFocused) && !disabled
            ? AppColors.accentBlue
            : AppColors.cardBorder;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      child: Material(
        color: widget.isActive
            ? AppColors.goldAccent.withValues(alpha: 0.14)
            : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: disabled ? null : widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: Row(
              children: [
                Icon(
                  widget.icon,
                  size: 18,
                  color: disabled
                      ? AppColors.textSecondary
                      : (widget.isActive
                          ? AppColors.goldAccent
                          : AppColors.accentBlue),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: disabled
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        widget.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: widget.isActive
                        ? AppColors.goldAccent
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Text(
                    widget.isActive
                        ? 'ON AIR'
                        : '${widget.type.defaultProductionCostEur.toStringAsFixed(0)} €',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: widget.isActive
                          ? Colors.black
                          : AppColors.textSecondary,
                      fontFeatures: const [FontFeature.tabularFigures()],
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

class _OnAirLiveBadge extends StatelessWidget {
  const _OnAirLiveBadge({
    required this.isLive,
    required this.pulseAnimation,
    required this.onTap,
  });

  final bool isLive;
  final Animation<double> pulseAnimation;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isLive
              ? AppColors.crimsonAlert.withValues(alpha: 0.16)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isLive ? AppColors.crimsonAlert : AppColors.cardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: pulseAnimation,
              builder: (context, _) {
                return Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isLive
                        ? AppColors.crimsonAlert.withValues(
                            alpha: 0.45 + 0.55 * pulseAnimation.value,
                          )
                        : AppColors.textSecondary,
                  ),
                );
              },
            ),
            const SizedBox(width: 6),
            Text(
              isLive ? 'ON AIR' : 'PAUZA',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isLive ? AppColors.crimsonAlert : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TelemetryMetricChip extends StatelessWidget {
  const _TelemetryMetricChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
    this.subValue,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;
  final String? subValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accentColor),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: accentColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (subValue != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      subValue!,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        color: AppColors.textSecondary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SignalPill extends StatelessWidget {
  const _SignalPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _DirectorIconButton extends StatefulWidget {
  const _DirectorIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  State<_DirectorIconButton> createState() => _DirectorIconButtonState();
}

class _DirectorIconButtonState extends State<_DirectorIconButton> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      child: Tooltip(
        message: widget.tooltip,
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isHovered
                  ? AppColors.surfaceLight
                  : AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isFocused ? AppColors.goldAccent : AppColors.cardBorder,
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

class _DirectorActionButton extends StatefulWidget {
  const _DirectorActionButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.isDisabled,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final bool isDisabled;
  final VoidCallback? onPressed;

  @override
  State<_DirectorActionButton> createState() => _DirectorActionButtonState();
}

class _DirectorActionButtonState extends State<_DirectorActionButton> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.isDisabled || widget.onPressed == null;
    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      child: Material(
        color: disabled
            ? AppColors.surfaceLight.withValues(alpha: 0.5)
            : widget.backgroundColor,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: disabled ? null : widget.onPressed,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: disabled
                    ? AppColors.cardBorder
                    : (_isHovered || _isFocused
                        ? AppColors.goldAccent
                        : widget.borderColor),
                width: _isHovered || _isFocused ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 16,
                  color: disabled ? AppColors.textSecondary : widget.textColor,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color:
                          disabled ? AppColors.textSecondary : widget.textColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
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
