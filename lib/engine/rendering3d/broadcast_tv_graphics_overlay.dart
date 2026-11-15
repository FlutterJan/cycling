// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/theme/app_colors.dart';
import '../../models/race/stage_segment.dart';
import '../../models/rider/rider_appearance.dart';
import '../../services/career/national_championships_and_worlds_service.dart';
import '../../ui/widgets/rider_avatar_painter.dart';

// =============================================================================
// 1. MODELE DANYCH GRAFIK TELEWIZYJNYCH (EUROSPORT / TOUR DE FRANCE)
// =============================================================================

/// Rodzaj punktu pomiaru czasu wyświetlanego w grafice Live Split Timer.
enum BroadcastSplitCheckpointType {
  komSummit('PREMIA GÓRSKA', Icons.terrain_rounded),
  intermediateSprint('LOTNY FINISZ', Icons.bolt_rounded),
  ittCheckpoint('POMIAR CZASU ITT', Icons.timer_rounded);

  final String label;
  final IconData icon;

  const BroadcastSplitCheckpointType(this.label, this.icon);
}

/// Dane do belki dolnej prezentacji kolarza (Lower-Third Rider Spotlight).
@immutable
class BroadcastRiderSpotlightData {
  final String riderId;
  final String riderName;
  final String teamName;
  final String teamShortCode;
  final String nationalityIso;
  final RiderAppearance? appearance;
  final String primaryJerseyHex;
  final String secondaryJerseyHex;
  final String accentJerseyHex;
  final SpecialJerseyDesignation specialJersey;
  final int gcPosition;
  final double gcGapSeconds;
  final double currentPowerWatts;
  final double riderWeightKg;
  final int heartRateBpm;
  final int maxHeartRateBpm;
  final double speedKmh;
  final int? cadenceRpm;
  final bool isAttacking;
  final bool isRaceLeader;
  final String? statusTag;

  const BroadcastRiderSpotlightData({
    required this.riderId,
    required this.riderName,
    required this.teamName,
    required this.teamShortCode,
    required this.nationalityIso,
    this.appearance,
    this.primaryJerseyHex = '#1E3A8A',
    this.secondaryJerseyHex = '#3B82F6',
    this.accentJerseyHex = '#D4AF37',
    this.specialJersey = SpecialJerseyDesignation.standardTeamJersey,
    required this.gcPosition,
    this.gcGapSeconds = 0.0,
    required this.currentPowerWatts,
    this.riderWeightKg = 68.0,
    required this.heartRateBpm,
    this.maxHeartRateBpm = 195,
    required this.speedKmh,
    this.cadenceRpm,
    this.isAttacking = false,
    this.isRaceLeader = false,
    this.statusTag,
  });

  double get wattsPerKg {
    if (riderWeightKg <= 0.0) return 0.0;
    return currentPowerWatts / riderWeightKg;
  }

  String get resolvedStatusTag {
    if (statusTag != null && statusTag!.trim().isNotEmpty) {
      return statusTag!.trim().toUpperCase();
    }
    if (isAttacking) return 'ATAK';
    if (isRaceLeader || gcPosition == 1) return 'LIDER GC';
    return 'PELETON';
  }
}

/// Dane do grafiki profilu podjazdu (Climb Telemetry Banner).
@immutable
class BroadcastClimbTelemetryData {
  final String climbName;
  final SegmentClassification category;
  final double totalLengthKm;
  final double remainingKm;
  final double averageGradientPercent;
  final double currentGradientPercent;
  final double summitElevationM;
  final double currentElevationM;
  final double estimatedClimbTimeSeconds;
  final double leaderGroupVamMetersPerHour;
  final List<double> elevationProfileSamples;

  const BroadcastClimbTelemetryData({
    required this.climbName,
    required this.category,
    required this.totalLengthKm,
    required this.remainingKm,
    required this.averageGradientPercent,
    required this.currentGradientPercent,
    required this.summitElevationM,
    required this.currentElevationM,
    required this.estimatedClimbTimeSeconds,
    required this.leaderGroupVamMetersPerHour,
    this.elevationProfileSamples = const <double>[],
  });

  double get progressFraction {
    if (totalLengthKm <= 0.0) return 0.0;
    return ((totalLengthKm - remainingKm) / totalLengthKm).clamp(0.0, 1.0);
  }
}

/// Pojedynczy wiersz tabeli Top 5 na punkcie pomiaru czasu.
@immutable
class BroadcastSplitEntry {
  final int rank;
  final String riderName;
  final String teamShortCode;
  final String nationalityIso;
  final double gapSeconds;
  final double elapsedSeconds;

  const BroadcastSplitEntry({
    required this.rank,
    required this.riderName,
    required this.teamShortCode,
    required this.nationalityIso,
    required this.gapSeconds,
    required this.elapsedSeconds,
  });
}

/// Dane do stopera punktów pomiaru czasu (Live Split Timer).
@immutable
class BroadcastLiveSplitData {
  final String checkpointName;
  final BroadcastSplitCheckpointType checkpointType;
  final double baseElapsedSeconds;
  final bool isTimerRunning;
  final List<BroadcastSplitEntry> topEntries;
  final String? referenceRiderName;

  const BroadcastLiveSplitData({
    required this.checkpointName,
    required this.checkpointType,
    required this.baseElapsedSeconds,
    this.isTimerRunning = true,
    required this.topEntries,
    this.referenceRiderName,
  });
}

// =============================================================================
// 2. GŁÓWNY WIDŻET NAKŁADKI TELEWIZYJNEJ (BroadcastTvGraphicsOverlay)
// =============================================================================

/// Autentyczna oprawa telewizyjna w stylu Eurosport / Tour de France
/// wyświetlana dynamicznie nad widokiem wyścigu 3D.
///
/// Zawiera 3 moduły:
/// 1. **Lower-Third Rider Spotlight** — dolna belka prezentacji kolarza ze złotym paskiem `#D4AF37`.
/// 2. **Climb Telemetry Banner** — grafika profilu podjazdu (Cat 4 – HC) z VAM i przewidywanym czasem.
/// 3. **Live Split Timer** — stoper do setnych sekundy z tabelą Top 5 i różnicami czasowymi.
class BroadcastTvGraphicsOverlay extends StatefulWidget {
  final BroadcastRiderSpotlightData? riderSpotlight;
  final BroadcastClimbTelemetryData? climbTelemetry;
  final BroadcastLiveSplitData? liveSplit;

  final bool showRiderSpotlight;
  final bool showClimbBanner;
  final bool showLiveSplit;
  final bool isInteractiveControlsVisible;

  final VoidCallback? onDismissSpotlight;
  final VoidCallback? onDismissClimbBanner;
  final VoidCallback? onDismissLiveSplit;
  final ValueChanged<String>? onRiderSpotlightTap;
  final VoidCallback? onToggleSplitTimer;

  const BroadcastTvGraphicsOverlay({
    super.key,
    this.riderSpotlight,
    this.climbTelemetry,
    this.liveSplit,
    this.showRiderSpotlight = true,
    this.showClimbBanner = true,
    this.showLiveSplit = true,
    this.isInteractiveControlsVisible = true,
    this.onDismissSpotlight,
    this.onDismissClimbBanner,
    this.onDismissLiveSplit,
    this.onRiderSpotlightTap,
    this.onToggleSplitTimer,
  });

  /// Formatuje czas stopera z dokładnością do setnych części sekundy:
  /// `MM:SS.cc` lub `HH:MM:SS.cc` dla czasów >= 1h.
  static String formatHundredthsTimer(double totalSeconds) {
    if (totalSeconds.isNaN || totalSeconds.isInfinite || totalSeconds < 0.0) {
      return '00:00.00';
    }
    final int totalCentiseconds = (totalSeconds * 100.0).round();
    final int centiseconds = totalCentiseconds % 100;
    final int allSeconds = totalCentiseconds ~/ 100;
    final int hours = allSeconds ~/ 3600;
    final int minutes = (allSeconds % 3600) ~/ 60;
    final int seconds = allSeconds % 60;

    final String mm = minutes.toString().padLeft(2, '0');
    final String ss = seconds.toString().padLeft(2, '0');
    final String cc = centiseconds.toString().padLeft(2, '0');

    if (hours > 0) {
      final String hh = hours.toString().padLeft(2, '0');
      return '$hh:$mm:$ss.$cc';
    }
    return '$mm:$ss.$cc';
  }

  /// Formatuje różnicę czasową dla tabeli Live Split:
  /// np. `-12` -> `-0'12"`, `+28` -> `+0'28"`, `0` -> `0'00"`.
  static String formatSplitGap(double gapSeconds) {
    if (gapSeconds.isNaN || gapSeconds.isInfinite) return "0'00\"";
    final int rounded = gapSeconds.round();
    if (rounded == 0) return "0'00\"";

    final String sign = rounded < 0 ? '-' : '+';
    final int absSec = rounded.abs();
    final int hours = absSec ~/ 3600;
    final int minutes = (absSec % 3600) ~/ 60;
    final int seconds = absSec % 60;

    if (hours > 0) {
      return '$sign${hours}h ${minutes.toString().padLeft(2, '0')}\'${seconds.toString().padLeft(2, '0')}"';
    }
    return '$sign$minutes\'${seconds.toString().padLeft(2, '0')}"';
  }

  @override
  State<BroadcastTvGraphicsOverlay> createState() =>
      _BroadcastTvGraphicsOverlayState();
}

class _BroadcastTvGraphicsOverlayState
    extends State<BroadcastTvGraphicsOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _spotlightController;
  late final Animation<Offset> _spotlightSlide;
  late final Animation<double> _spotlightFade;

  late final AnimationController _climbController;
  late final Animation<double> _climbFade;
  late final Animation<Offset> _climbSlide;

  late final AnimationController _splitController;
  late final Animation<double> _splitFade;
  late final Animation<Offset> _splitSlide;

  late final Ticker _splitTicker;
  double _tickElapsedSeconds = 0.0;
  bool _localTimerPaused = false;
  bool _isClimbExpanded = true;

  bool get _hasVisibleSpotlight =>
      widget.showRiderSpotlight && widget.riderSpotlight != null;

  bool get _hasVisibleClimb =>
      widget.showClimbBanner && widget.climbTelemetry != null;

  bool get _hasVisibleSplit =>
      widget.showLiveSplit && widget.liveSplit != null;

  @override
  void initState() {
    super.initState();

    _spotlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _spotlightSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _spotlightController,
      curve: Curves.easeOutCubic,
    ));
    _spotlightFade = CurvedAnimation(
      parent: _spotlightController,
      curve: Curves.easeOutCubic,
    );

    _climbController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _climbSlide = Tween<Offset>(
      begin: const Offset(-0.18, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _climbController,
      curve: Curves.easeOutCubic,
    ));
    _climbFade = CurvedAnimation(
      parent: _climbController,
      curve: Curves.easeOutCubic,
    );

    _splitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _splitSlide = Tween<Offset>(
      begin: const Offset(0.18, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _splitController,
      curve: Curves.easeOutCubic,
    ));
    _splitFade = CurvedAnimation(
      parent: _splitController,
      curve: Curves.easeOutCubic,
    );

    _splitTicker = createTicker((Duration elapsed) {
      if (!mounted) return;
      final bool shouldRun = _hasVisibleSplit &&
          (widget.liveSplit?.isTimerRunning ?? false) &&
          !_localTimerPaused;
      if (!shouldRun) return;
      setState(() {
        _tickElapsedSeconds = elapsed.inMilliseconds / 1000.0;
      });
    });

    _syncAnimations(initial: true);
    _syncTicker();
  }

  @override
  void didUpdateWidget(covariant BroadcastTvGraphicsOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.liveSplit?.checkpointName != widget.liveSplit?.checkpointName ||
        oldWidget.liveSplit?.baseElapsedSeconds !=
            widget.liveSplit?.baseElapsedSeconds) {
      _tickElapsedSeconds = 0.0;
      _localTimerPaused = false;
      if (_splitTicker.isActive) {
        _splitTicker.stop();
      }
    }

    _syncAnimations(initial: false);
    _syncTicker();
  }

  void _syncAnimations({required bool initial}) {
    if (_hasVisibleSpotlight) {
      if (initial) {
        _spotlightController.value = 1.0;
      } else {
        _spotlightController.forward();
      }
    } else {
      _spotlightController.reverse();
    }

    if (_hasVisibleClimb) {
      if (initial) {
        _climbController.value = 1.0;
      } else {
        _climbController.forward();
      }
    } else {
      _climbController.reverse();
    }

    if (_hasVisibleSplit) {
      if (initial) {
        _splitController.value = 1.0;
      } else {
        _splitController.forward();
      }
    } else {
      _splitController.reverse();
    }
  }

  void _syncTicker() {
    final bool shouldRun = _hasVisibleSplit &&
        (widget.liveSplit?.isTimerRunning ?? false) &&
        !_localTimerPaused;

    if (shouldRun && !_splitTicker.isActive) {
      _splitTicker.start();
    } else if (!shouldRun && _splitTicker.isActive) {
      _splitTicker.stop();
    }
  }

  @override
  void dispose() {
    _splitTicker.dispose();
    _spotlightController.dispose();
    _climbController.dispose();
    _splitController.dispose();
    super.dispose();
  }

  void _handleToggleTimer() {
    if (widget.onToggleSplitTimer != null) {
      widget.onToggleSplitTimer!();
    } else {
      setState(() {
        _localTimerPaused = !_localTimerPaused;
      });
      _syncTicker();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        final double height = constraints.maxHeight;
        final bool isMobile = width < 640;
        final bool isTablet = width >= 640 && width < 1180;
        final double edgePadding = isMobile ? 12.0 : 20.0;

        if (isMobile) {
          return _buildMobileLayout(
            width: width,
            height: height,
            edgePadding: edgePadding,
          );
        }

        return _buildDesktopTabletLayout(
          width: width,
          height: height,
          isTablet: isTablet,
          edgePadding: edgePadding,
        );
      },
    );
  }

  Widget _buildMobileLayout({
    required double width,
    required double height,
    required double edgePadding,
  }) {
    final double cardMaxWidth = math.max(240.0, width - edgePadding * 2);

    return Stack(
      fit: StackFit.expand,
      children: [
        if (_hasVisibleClimb || _hasVisibleSplit)
          Positioned(
            top: edgePadding,
            left: edgePadding,
            right: edgePadding,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: math.max(120.0, height * 0.56),
              ),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_hasVisibleClimb)
                      FadeTransition(
                        opacity: _climbFade,
                        child: SlideTransition(
                          position: _climbSlide,
                          child: _ClimbTelemetryBannerCard(
                            data: widget.climbTelemetry!,
                            maxWidth: cardMaxWidth,
                            isCompact: true,
                            isExpanded: _isClimbExpanded,
                            showControls: widget.isInteractiveControlsVisible,
                            onToggleExpand: () {
                              setState(() {
                                _isClimbExpanded = !_isClimbExpanded;
                              });
                            },
                            onDismiss: widget.onDismissClimbBanner,
                          ),
                        ),
                      ),
                    if (_hasVisibleClimb && _hasVisibleSplit)
                      const SizedBox(height: 8.0),
                    if (_hasVisibleSplit)
                      FadeTransition(
                        opacity: _splitFade,
                        child: SlideTransition(
                          position: _splitSlide,
                          child: _LiveSplitTimerCard(
                            data: widget.liveSplit!,
                            tickOffsetSeconds: _tickElapsedSeconds,
                            isLocallyPaused: _localTimerPaused,
                            maxWidth: cardMaxWidth,
                            isCompact: true,
                            showControls: widget.isInteractiveControlsVisible,
                            onToggleTimer: _handleToggleTimer,
                            onDismiss: widget.onDismissLiveSplit,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        if (_hasVisibleSpotlight)
          Positioned(
            left: edgePadding,
            right: edgePadding,
            bottom: edgePadding,
            child: FadeTransition(
              opacity: _spotlightFade,
              child: SlideTransition(
                position: _spotlightSlide,
                child: _LowerThirdRiderSpotlightCard(
                  data: widget.riderSpotlight!,
                  maxWidth: cardMaxWidth,
                  isCompact: true,
                  showControls: widget.isInteractiveControlsVisible,
                  onTap: widget.onRiderSpotlightTap != null
                      ? () => widget
                          .onRiderSpotlightTap!(widget.riderSpotlight!.riderId)
                      : null,
                  onDismiss: widget.onDismissSpotlight,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDesktopTabletLayout({
    required double width,
    required double height,
    required bool isTablet,
    required double edgePadding,
  }) {
    final double climbWidth = isTablet ? 340.0 : 390.0;
    final double splitWidth = isTablet ? 310.0 : 350.0;
    final double spotlightMaxWidth =
        isTablet ? math.min(720.0, width - edgePadding * 2) : 820.0;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (_hasVisibleClimb)
          Positioned(
            top: edgePadding,
            left: edgePadding,
            child: FadeTransition(
              opacity: _climbFade,
              child: SlideTransition(
                position: _climbSlide,
                child: _ClimbTelemetryBannerCard(
                  data: widget.climbTelemetry!,
                  maxWidth: climbWidth,
                  isCompact: isTablet,
                  isExpanded: _isClimbExpanded,
                  showControls: widget.isInteractiveControlsVisible,
                  onToggleExpand: () {
                    setState(() {
                      _isClimbExpanded = !_isClimbExpanded;
                    });
                  },
                  onDismiss: widget.onDismissClimbBanner,
                ),
              ),
            ),
          ),
        if (_hasVisibleSplit)
          Positioned(
            top: edgePadding,
            right: edgePadding,
            child: FadeTransition(
              opacity: _splitFade,
              child: SlideTransition(
                position: _splitSlide,
                child: _LiveSplitTimerCard(
                  data: widget.liveSplit!,
                  tickOffsetSeconds: _tickElapsedSeconds,
                  isLocallyPaused: _localTimerPaused,
                  maxWidth: splitWidth,
                  isCompact: isTablet,
                  showControls: widget.isInteractiveControlsVisible,
                  onToggleTimer: _handleToggleTimer,
                  onDismiss: widget.onDismissLiveSplit,
                ),
              ),
            ),
          ),
        if (_hasVisibleSpotlight)
          Positioned(
            left: edgePadding,
            right: edgePadding,
            bottom: edgePadding,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FadeTransition(
                opacity: _spotlightFade,
                child: SlideTransition(
                  position: _spotlightSlide,
                  child: _LowerThirdRiderSpotlightCard(
                    data: widget.riderSpotlight!,
                    maxWidth: spotlightMaxWidth,
                    isCompact: false,
                    showControls: widget.isInteractiveControlsVisible,
                    onTap: widget.onRiderSpotlightTap != null
                        ? () => widget.onRiderSpotlightTap!(
                            widget.riderSpotlight!.riderId)
                        : null,
                    onDismiss: widget.onDismissSpotlight,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// =============================================================================
// 3. BELKA DOLNA PREZENTACJI KOLARZA (LOWER-THIRD RIDER SPOTLIGHT)
// =============================================================================

class _LowerThirdRiderSpotlightCard extends StatefulWidget {
  final BroadcastRiderSpotlightData data;
  final double maxWidth;
  final bool isCompact;
  final bool showControls;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const _LowerThirdRiderSpotlightCard({
    required this.data,
    required this.maxWidth,
    required this.isCompact,
    required this.showControls,
    this.onTap,
    this.onDismiss,
  });

  @override
  State<_LowerThirdRiderSpotlightCard> createState() =>
      _LowerThirdRiderSpotlightCardState();
}

class _LowerThirdRiderSpotlightCardState
    extends State<_LowerThirdRiderSpotlightCard> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  RiderAppearance _resolveAppearance() {
    if (widget.data.appearance != null) {
      return widget.data.appearance!;
    }
    final int seed = widget.data.riderId.hashCode.abs();
    return RiderAppearance(
      faceShapeIndex: seed % 4,
      skinToneHex: const ['#F3C6A5', '#E2AA84', '#C6865C', '#F7D7C4'][seed % 4],
      hairStyleIndex: (seed ~/ 3) % 5,
      hairColorHex: const ['#2B1D12', '#5C3A21', '#B8860B', '#111827'][seed % 4],
      facialHairIndex: seed % 3,
      glassesModelId: 'aero_pro',
      glassesLensColorHex: widget.data.accentJerseyHex,
      helmetModelId: 'tt_vented',
      shoeColorHex: '#FFFFFF',
      sockHeightProportion: 0.45,
      bodyBuildType: BodyBuildType.allRounder,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isInteractive = widget.onTap != null;
    final Color borderColor = _isFocused
        ? AppColors.goldAccent
        : (_isHovered && isInteractive
            ? AppColors.goldAccent.withValues(alpha: 0.75)
            : AppColors.cardBorder);

    final double avatarSize = widget.isCompact ? 46.0 : 58.0;
    final double wkg = widget.data.wattsPerKg;
    final Color powerColor = wkg >= 6.2
        ? AppColors.goldAccent
        : (wkg >= 5.0 ? AppColors.cyanAccent : AppColors.textPrimary);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: widget.maxWidth),
      child: FocusableActionDetector(
        enabled: isInteractive,
        onShowHoverHighlight: (bool hovered) {
          if (mounted) setState(() => _isHovered = hovered);
        },
        onShowFocusHighlight: (bool focused) {
          if (mounted) setState(() => _isFocused = focused);
        },
        child: GestureDetector(
          onTap: widget.onTap,
          onTapDown: isInteractive ? (_) => setState(() => _isPressed = true) : null,
          onTapUp: isInteractive ? (_) => setState(() => _isPressed = false) : null,
          onTapCancel:
              isInteractive ? () => setState(() => _isPressed = false) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            transform: Matrix4.identity()
              ..scaleByDouble(_isPressed ? 0.992 : 1.0, _isPressed ? 0.992 : 1.0, 1.0, 1.0),
            decoration: BoxDecoration(
              color: (_isHovered && isInteractive
                      ? AppColors.surfaceLight
                      : AppColors.surface)
                  .withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: borderColor, width: _isFocused ? 1.5 : 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  blurRadius: 20.0,
                  offset: const Offset(0, 8),
                ),
                if (widget.data.isAttacking || widget.data.isRaceLeader)
                  BoxShadow(
                    color: AppColors.goldAccent.withValues(alpha: 0.16),
                    blurRadius: 16.0,
                    spreadRadius: 1.0,
                  ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15.0),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Złoty pasek transmisji #D4AF37
                    Container(
                      width: widget.isCompact ? 5.0 : 6.0,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.goldAccent,
                            Color(0xFFF3D56B),
                            AppColors.goldAccent,
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: widget.isCompact ? 10.0 : 14.0,
                          vertical: widget.isCompact ? 9.0 : 11.0,
                        ),
                        child: widget.isCompact
                            ? _buildCompactBody(avatarSize, powerColor)
                            : _buildWideBody(avatarSize, powerColor),
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

  Widget _buildWideBody(double avatarSize, Color powerColor) {
    return Row(
      children: [
        RiderAvatarWidget(
          appearance: _resolveAppearance(),
          primaryJerseyColorHex: widget.data.primaryJerseyHex,
          secondaryJerseyColorHex: widget.data.secondaryJerseyHex,
          accentJerseyColorHex: widget.data.accentJerseyHex,
          specialJersey: widget.data.specialJersey,
          nationalityIso: widget.data.nationalityIso,
          size: avatarSize,
          borderColor: AppColors.goldAccent,
          borderWidth: 1.5,
        ),
        const SizedBox(width: 12.0),
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _StatusPill(
                    label: widget.data.resolvedStatusTag,
                    color: widget.data.isAttacking
                        ? AppColors.amberWarning
                        : AppColors.goldAccent,
                  ),
                  const SizedBox(width: 8.0),
                  _GcPositionBadge(
                    position: widget.data.gcPosition,
                    gapSeconds: widget.data.gcGapSeconds,
                  ),
                ],
              ),
              const SizedBox(height: 5.0),
              Row(
                children: [
                  _CountryFlagBadge(isoCode: widget.data.nationalityIso),
                  const SizedBox(width: 8.0),
                  Flexible(
                    child: Text(
                      widget.data.riderName.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15.0,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2.0),
              Text(
                '${widget.data.teamShortCode.toUpperCase()}  •  ${widget.data.teamName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 1.0,
          height: 44.0,
          margin: const EdgeInsets.symmetric(horizontal: 12.0),
          color: AppColors.cardBorder,
        ),
        _TelemetryStatBlock(
          label: 'MOC',
          value: '${widget.data.currentPowerWatts.round()} W',
          subValue: '${widget.data.wattsPerKg.toStringAsFixed(2)} W/kg',
          valueColor: powerColor,
          icon: Icons.bolt_rounded,
        ),
        const SizedBox(width: 14.0),
        _TelemetryStatBlock(
          label: 'TĘTNO',
          value: '${widget.data.heartRateBpm}',
          subValue: 'BPM',
          valueColor: widget.data.heartRateBpm >=
                  (widget.data.maxHeartRateBpm * 0.90).round()
              ? AppColors.crimsonAlert
              : AppColors.textPrimary,
          icon: Icons.favorite_rounded,
          iconColor: AppColors.crimsonAlert,
        ),
        const SizedBox(width: 14.0),
        _TelemetryStatBlock(
          label: 'PRĘDKOŚĆ',
          value: widget.data.speedKmh.toStringAsFixed(1),
          subValue: 'km/h',
          valueColor: AppColors.accentBlue,
          icon: Icons.speed_rounded,
        ),
        if (widget.showControls && widget.onDismiss != null) ...[
          const SizedBox(width: 8.0),
          _TvIconActionButton(
            icon: Icons.close_rounded,
            tooltip: 'Ukryj prezentację kolarza',
            onPressed: widget.onDismiss,
          ),
        ],
      ],
    );
  }

  Widget _buildCompactBody(double avatarSize, Color powerColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            RiderAvatarWidget(
              appearance: _resolveAppearance(),
              primaryJerseyColorHex: widget.data.primaryJerseyHex,
              secondaryJerseyColorHex: widget.data.secondaryJerseyHex,
              accentJerseyColorHex: widget.data.accentJerseyHex,
              specialJersey: widget.data.specialJersey,
              nationalityIso: widget.data.nationalityIso,
              size: avatarSize,
              borderColor: AppColors.goldAccent,
              borderWidth: 1.5,
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _StatusPill(
                        label: widget.data.resolvedStatusTag,
                        color: widget.data.isAttacking
                            ? AppColors.amberWarning
                            : AppColors.goldAccent,
                      ),
                      const SizedBox(width: 6.0),
                      Flexible(
                        child: _GcPositionBadge(
                          position: widget.data.gcPosition,
                          gapSeconds: widget.data.gcGapSeconds,
                          compact: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4.0),
                  Row(
                    children: [
                      _CountryFlagBadge(isoCode: widget.data.nationalityIso),
                      const SizedBox(width: 6.0),
                      Flexible(
                        child: Text(
                          widget.data.riderName.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    widget.data.teamName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.showControls && widget.onDismiss != null)
              _TvIconActionButton(
                icon: Icons.close_rounded,
                tooltip: 'Ukryj prezentację kolarza',
                onPressed: widget.onDismiss,
              ),
          ],
        ),
        const SizedBox(height: 8.0),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 7.0),
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: _CompactStatChip(
                  label: 'MOC',
                  value:
                      '${widget.data.currentPowerWatts.round()} W (${widget.data.wattsPerKg.toStringAsFixed(1)})',
                  color: powerColor,
                ),
              ),
              const SizedBox(width: 6.0),
              Expanded(
                flex: 3,
                child: _CompactStatChip(
                  label: 'HR',
                  value: '${widget.data.heartRateBpm} bpm',
                  color: AppColors.crimsonAlert,
                ),
              ),
              const SizedBox(width: 6.0),
              Expanded(
                flex: 3,
                child: _CompactStatChip(
                  label: 'PRĘDK.',
                  value: '${widget.data.speedKmh.toStringAsFixed(1)} km/h',
                  color: AppColors.accentBlue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// 4. GRAFIKA PROFILU PODJAZDU (CLIMB TELEMETRY BANNER)
// =============================================================================

class _ClimbTelemetryBannerCard extends StatelessWidget {
  final BroadcastClimbTelemetryData data;
  final double maxWidth;
  final bool isCompact;
  final bool isExpanded;
  final bool showControls;
  final VoidCallback onToggleExpand;
  final VoidCallback? onDismiss;

  const _ClimbTelemetryBannerCard({
    required this.data,
    required this.maxWidth,
    required this.isCompact,
    required this.isExpanded,
    required this.showControls,
    required this.onToggleExpand,
    this.onDismiss,
  });

  ({String tag, Color color}) _categoryStyle(SegmentClassification category) {
    switch (category) {
      case SegmentClassification.horsCategorie:
        return (tag: 'HC', color: AppColors.crimsonAlert);
      case SegmentClassification.cat1:
        return (tag: 'CAT 1', color: const Color(0xFFF97316));
      case SegmentClassification.cat2:
        return (tag: 'CAT 2', color: AppColors.amberWarning);
      case SegmentClassification.cat3:
        return (tag: 'CAT 3', color: AppColors.accentBlue);
      case SegmentClassification.cat4:
        return (tag: 'CAT 4', color: AppColors.statusSuccess);
      case SegmentClassification.intermediateSprint:
        return (tag: 'SPRINT', color: AppColors.statusSuccess);
      case SegmentClassification.finishLine:
        return (tag: 'META', color: AppColors.goldAccent);
      case SegmentClassification.none:
        return (tag: 'PODJAZD', color: AppColors.textSecondary);
    }
  }

  String _formatClimbEta(double seconds) {
    if (seconds.isNaN || seconds.isInfinite || seconds <= 0.0) return "0'00\"";
    final int total = seconds.round();
    final int hours = total ~/ 3600;
    final int minutes = (total % 3600) ~/ 60;
    final int secs = total % 60;
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}\'${secs.toString().padLeft(2, '0')}"';
    }
    return '$minutes\'${secs.toString().padLeft(2, '0')}"';
  }

  @override
  Widget build(BuildContext context) {
    final cat = _categoryStyle(data.category);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: AppColors.cardBorder, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.48),
              blurRadius: 16.0,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pasek kategorii na górze
              Container(height: 3.0, color: cat.color),
              Padding(
                padding: EdgeInsets.all(isCompact ? 10.0 : 12.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 3.0,
                          ),
                          decoration: BoxDecoration(
                            color: cat.color.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(6.0),
                            border: Border.all(
                              color: cat.color.withValues(alpha: 0.7),
                            ),
                          ),
                          child: Text(
                            cat.tag,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: cat.color,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data.climbName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Szczyt ${data.summitElevationM.round()} m n.p.m.  •  Pozostało ${data.remainingKm.toStringAsFixed(1)} km',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11.0,
                                  color: AppColors.textSecondary,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (showControls) ...[
                          _TvIconActionButton(
                            icon: isExpanded
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            tooltip: isExpanded
                                ? 'Zwiń profil podjazdu'
                                : 'Rozwiń profil podjazdu',
                            onPressed: onToggleExpand,
                          ),
                          if (onDismiss != null) ...[
                            const SizedBox(width: 4.0),
                            _TvIconActionButton(
                              icon: Icons.close_rounded,
                              tooltip: 'Zamknij profil podjazdu',
                              onPressed: onDismiss,
                            ),
                          ],
                        ],
                      ],
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                      child: isExpanded
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 10.0),
                                SizedBox(
                                  height: 36.0,
                                  width: double.infinity,
                                  child: CustomPaint(
                                    painter: _ClimbMiniProfilePainter(
                                      samples: data.elevationProfileSamples,
                                      progress: data.progressFraction,
                                      accentColor: cat.color,
                                      averageGradient:
                                          data.averageGradientPercent,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10.0),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _ClimbMetricCell(
                                        label: 'DŁUGOŚĆ',
                                        value:
                                            '${data.totalLengthKm.toStringAsFixed(1)} km',
                                      ),
                                    ),
                                    Expanded(
                                      child: _ClimbMetricCell(
                                        label: 'ŚR. NACHYL.',
                                        value:
                                            '${data.averageGradientPercent.toStringAsFixed(1)}%',
                                        highlightColor:
                                            data.averageGradientPercent >= 8.0
                                                ? AppColors.crimsonAlert
                                                : AppColors.amberWarning,
                                      ),
                                    ),
                                    Expanded(
                                      child: _ClimbMetricCell(
                                        label: 'SZAC. CZAS',
                                        value: _formatClimbEta(
                                            data.estimatedClimbTimeSeconds),
                                      ),
                                    ),
                                    Expanded(
                                      child: _ClimbMetricCell(
                                        label: 'VAM LIDERÓW',
                                        value:
                                            '${data.leaderGroupVamMetersPerHour.round()} m/h',
                                        highlightColor: AppColors.goldAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
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

class _ClimbMiniProfilePainter extends CustomPainter {
  final List<double> samples;
  final double progress;
  final Color accentColor;
  final double averageGradient;

  const _ClimbMiniProfilePainter({
    required this.samples,
    required this.progress,
    required this.accentColor,
    required this.averageGradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final List<double> pts = samples.length >= 2
        ? samples
        : const <double>[0.08, 0.22, 0.36, 0.54, 0.72, 0.88, 1.0];

    double minVal = pts.first;
    double maxVal = pts.first;
    for (final v in pts) {
      if (v < minVal) minVal = v;
      if (v > maxVal) maxVal = v;
    }
    final double range = math.max(1e-3, maxVal - minVal);

    final Path fillPath = Path()..moveTo(0.0, size.height);
    final Path linePath = Path();

    final List<Offset> mapped = [];
    for (int i = 0; i < pts.length; i++) {
      final double x = (i / (pts.length - 1)) * size.width;
      final double norm = (pts[i] - minVal) / range;
      final double y = size.height - (norm * (size.height - 8.0) + 4.0);
      mapped.add(Offset(x, y));
      fillPath.lineTo(x, y);
      if (i == 0) {
        linePath.moveTo(x, y);
      } else {
        linePath.lineTo(x, y);
      }
    }
    fillPath
      ..lineTo(size.width, size.height)
      ..close();

    final Paint fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          accentColor.withValues(alpha: 0.38),
          accentColor.withValues(alpha: 0.04),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    final Paint linePaint = Paint()
      ..color = accentColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, linePaint);

    // Pozycja grupy liderów na profilu podjazdu
    final double clampedProgress = progress.clamp(0.0, 1.0);
    final double markerX = clampedProgress * size.width;
    final double exactIdx = clampedProgress * (mapped.length - 1);
    final int lowIdx = exactIdx.floor().clamp(0, mapped.length - 1);
    final int highIdx = exactIdx.ceil().clamp(0, mapped.length - 1);
    final double t = exactIdx - lowIdx;
    final double markerY =
        mapped[lowIdx].dy + (mapped[highIdx].dy - mapped[lowIdx].dy) * t;

    canvas.drawLine(
      Offset(markerX, markerY),
      Offset(markerX, size.height),
      Paint()
        ..color = AppColors.goldAccent.withValues(alpha: 0.55)
        ..strokeWidth = 1.2,
    );
    canvas.drawCircle(
      Offset(markerX, markerY),
      4.5,
      Paint()..color = AppColors.goldAccent,
    );
    canvas.drawCircle(
      Offset(markerX, markerY),
      2.0,
      Paint()..color = AppColors.background,
    );
  }

  @override
  bool shouldRepaint(covariant _ClimbMiniProfilePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.samples != samples ||
        oldDelegate.averageGradient != averageGradient;
  }
}

// =============================================================================
// 5. STOPER PUNKTÓW POMIARU CZASU (LIVE SPLIT TIMER)
// =============================================================================

class _LiveSplitTimerCard extends StatelessWidget {
  final BroadcastLiveSplitData data;
  final double tickOffsetSeconds;
  final bool isLocallyPaused;
  final double maxWidth;
  final bool isCompact;
  final bool showControls;
  final VoidCallback onToggleTimer;
  final VoidCallback? onDismiss;

  const _LiveSplitTimerCard({
    required this.data,
    required this.tickOffsetSeconds,
    required this.isLocallyPaused,
    required this.maxWidth,
    required this.isCompact,
    required this.showControls,
    required this.onToggleTimer,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final bool isRunning = data.isTimerRunning && !isLocallyPaused;
    final double liveSeconds = data.baseElapsedSeconds + tickOffsetSeconds;
    final List<BroadcastSplitEntry> topFive = data.topEntries.take(5).toList();

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: AppColors.cardBorder, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.48),
              blurRadius: 16.0,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pasek Live Split w stylu Eurosport
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 10.0 : 12.0,
                  vertical: 8.0,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight.withValues(alpha: 0.9),
                  border: const Border(
                    bottom: BorderSide(color: AppColors.cardBorder),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      data.checkpointType.icon,
                      size: 14.0,
                      color: AppColors.goldAccent,
                    ),
                    const SizedBox(width: 6.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.checkpointType.label,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: AppColors.goldAccent,
                            ),
                          ),
                          Text(
                            data.checkpointName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (showControls) ...[
                      _TvIconActionButton(
                        icon: isRunning
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        tooltip: isRunning ? 'Wstrzymaj stoper' : 'Wznów stoper',
                        onPressed: onToggleTimer,
                      ),
                      if (onDismiss != null) ...[
                        const SizedBox(width: 4.0),
                        _TvIconActionButton(
                          icon: Icons.close_rounded,
                          tooltip: 'Zamknij pomiar czasu',
                          onPressed: onDismiss,
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              // Tykający stoper do setnych części sekundy
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 10.0 : 12.0,
                  vertical: 8.0,
                ),
                color: AppColors.background.withValues(alpha: 0.65),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 7.0,
                          height: 7.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isRunning
                                ? AppColors.crimsonAlert
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 6.0),
                        Text(
                          isRunning ? 'LIVE SPLIT' : 'WSTRZYMANO',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10.0,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: isRunning
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      BroadcastTvGraphicsOverlay.formatHundredthsTimer(
                          liveSeconds),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20.0,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: AppColors.goldAccent,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              // Tabela Top 5
              if (topFive.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text(
                    'Oczekiwanie na pierwszych kolarzy na punkcie pomiaru...',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 6.0,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < topFive.length; i++)
                        _SplitLeaderboardRow(
                          entry: topFive[i],
                          isLast: i == topFive.length - 1,
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

class _SplitLeaderboardRow extends StatelessWidget {
  final BroadcastSplitEntry entry;
  final bool isLast;

  const _SplitLeaderboardRow({
    required this.entry,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final bool isFaster = entry.gapSeconds < -0.49;
    final bool isSlower = entry.gapSeconds > 0.49;
    final Color gapColor = isFaster
        ? AppColors.statusSuccess
        : (isSlower ? AppColors.crimsonAlert : AppColors.goldAccent);
    final String gapText =
        BroadcastTvGraphicsOverlay.formatSplitGap(entry.gapSeconds);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 4.0),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: AppColors.cardBorder.withValues(alpha: 0.65),
                ),
              ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20.0,
            child: Text(
              '${entry.rank}',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: entry.rank == 1
                    ? AppColors.goldAccent
                    : AppColors.textSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          _CountryFlagBadge(isoCode: entry.nationalityIso, compact: true),
          const SizedBox(width: 6.0),
          Expanded(
            child: Text(
              entry.riderName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.0,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 6.0),
          Text(
            entry.teamShortCode.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10.0,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8.0),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
            decoration: BoxDecoration(
              color: gapColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(5.0),
            ),
            child: Text(
              gapText,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: gapColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 6. WSPÓLNE KOMPONENTY POMOCNICZE (FLAGI, PRZYCISKI HOVER/FOCUS, METRYKI)
// =============================================================================

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(5.0),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: color,
        ),
      ),
    );
  }
}

class _GcPositionBadge extends StatelessWidget {
  final int position;
  final double gapSeconds;
  final bool compact;

  const _GcPositionBadge({
    required this.position,
    required this.gapSeconds,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLeader = position == 1;
    final String gapLabel = isLeader || gapSeconds.abs() < 0.5
        ? ''
        : ' (${BroadcastTvGraphicsOverlay.formatSplitGap(gapSeconds)})';

    return Text(
      compact ? 'GC #$position' : 'GC #$position$gapLabel',
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 11.0,
        fontWeight: FontWeight.w700,
        color: isLeader ? AppColors.goldAccent : AppColors.textSecondary,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

class _TelemetryStatBlock extends StatelessWidget {
  final String label;
  final String value;
  final String subValue;
  final Color valueColor;
  final IconData icon;
  final Color? iconColor;

  const _TelemetryStatBlock({
    required this.label,
    required this.value,
    required this.subValue,
    required this.valueColor,
    required this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11.0, color: iconColor ?? AppColors.textSecondary),
            const SizedBox(width: 4.0),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2.0),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16.0,
            fontWeight: FontWeight.w800,
            color: valueColor,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text(
          subValue,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _CompactStatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _CompactStatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 9.0,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _ClimbMetricCell extends StatelessWidget {
  final String label;
  final String value;
  final Color? highlightColor;

  const _ClimbMetricCell({
    required this.label,
    required this.value,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 9.0,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2.0),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: highlightColor ?? AppColors.textPrimary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// Przycisk akcji nakładki TV z pełnymi stanami hover / focus / active / disabled.
class _TvIconActionButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _TvIconActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  State<_TvIconActionButton> createState() => _TvIconActionButtonState();
}

class _TvIconActionButtonState extends State<_TvIconActionButton> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onPressed == null;
    final Color bgColor = isDisabled
        ? AppColors.surface.withValues(alpha: 0.4)
        : (_isPressed
            ? AppColors.primaryAccent.withValues(alpha: 0.45)
            : (_isHovered
                ? AppColors.surfaceLight
                : AppColors.background.withValues(alpha: 0.6)));
    final Color borderColor = _isFocused
        ? AppColors.goldAccent
        : (_isHovered && !isDisabled
            ? AppColors.goldAccent.withValues(alpha: 0.6)
            : AppColors.cardBorder);

    return Tooltip(
      message: widget.tooltip,
      child: FocusableActionDetector(
        enabled: !isDisabled,
        onShowHoverHighlight: (bool v) => setState(() => _isHovered = v),
        onShowFocusHighlight: (bool v) => setState(() => _isFocused = v),
        child: GestureDetector(
          onTap: widget.onPressed,
          onTapDown:
              isDisabled ? null : (_) => setState(() => _isPressed = true),
          onTapUp:
              isDisabled ? null : (_) => setState(() => _isPressed = false),
          onTapCancel:
              isDisabled ? null : () => setState(() => _isPressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            width: 26.0,
            height: 26.0,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: borderColor),
            ),
            child: Icon(
              widget.icon,
              size: 15.0,
              color: isDisabled
                  ? AppColors.textSecondary.withValues(alpha: 0.4)
                  : (_isHovered
                      ? AppColors.textPrimary
                      : AppColors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}

/// Wektorowa mini-flaga kraju + kod ISO (działa deterministycznie bez brakujących glifów emoji).
class _CountryFlagBadge extends StatelessWidget {
  final String isoCode;
  final bool compact;

  const _CountryFlagBadge({
    required this.isoCode,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final String upper = isoCode.trim().toUpperCase();
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 4.0 : 5.0,
        vertical: compact ? 2.0 : 2.5,
      ),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: compact ? 13.0 : 16.0,
            height: compact ? 9.0 : 11.0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2.0),
              child: CustomPaint(painter: _MiniFlagPainter(isoCode: upper)),
            ),
          ),
          if (!compact) ...[
            const SizedBox(width: 4.0),
            Text(
              upper,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniFlagPainter extends CustomPainter {
  final String isoCode;

  const _MiniFlagPainter({required this.isoCode});

  @override
  void paint(Canvas canvas, Size size) {
    final List<Color> stripes;
    bool vertical = false;

    switch (isoCode) {
      case 'POL':
        stripes = const [Colors.white, Color(0xFFDC143C)];
      case 'FRA':
        vertical = true;
        stripes = const [Color(0xFF0055A4), Colors.white, Color(0xFFEF4135)];
      case 'BEL':
        vertical = true;
        stripes = const [Colors.black, Color(0xFFFDDA24), Color(0xFFEF3340)];
      case 'ITA':
        vertical = true;
        stripes = const [Color(0xFF009246), Colors.white, Color(0xFFCE2B37)];
      case 'SLO':
        stripes = const [Colors.white, Color(0xFF005DA4), Color(0xFFED1C24)];
      case 'NED':
        stripes = const [Color(0xFFAE1C28), Colors.white, Color(0xFF21468B)];
      case 'ESP':
        stripes = const [
          Color(0xFFAA151B),
          Color(0xFFF1BF00),
          Color(0xFFAA151B)
        ];
      case 'GER':
        stripes = const [Colors.black, Color(0xFFDD0000), Color(0xFFFFCE00)];
      case 'COL':
        stripes = const [
          Color(0xFFFCD116),
          Color(0xFF003893),
          Color(0xFFCE1126)
        ];
      case 'DEN':
        stripes = const [Color(0xFFC60C30), Colors.white, Color(0xFFC60C30)];
      case 'GBR':
        stripes = const [Color(0xFF012169), Colors.white, Color(0xFFC8102E)];
      case 'USA':
        stripes = const [Color(0xFFB22234), Colors.white, Color(0xFF3C3B6E)];
      default:
        final int h = isoCode.hashCode.abs();
        stripes = [
          Color.fromARGB(255, 40 + (h % 180), 80 + ((h >> 3) % 140), 190),
          Colors.white,
          Color.fromARGB(255, 190, 50 + ((h >> 5) % 140), 60),
        ];
    }

    for (int i = 0; i < stripes.length; i++) {
      final Paint paint = Paint()..color = stripes[i];
      if (vertical) {
        final double w = size.width / stripes.length;
        canvas.drawRect(Rect.fromLTWH(i * w, 0, w + 0.5, size.height), paint);
      } else {
        final double h = size.height / stripes.length;
        canvas.drawRect(Rect.fromLTWH(0, i * h, size.width, h + 0.5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MiniFlagPainter oldDelegate) {
    return oldDelegate.isoCode != isoCode;
  }
}
