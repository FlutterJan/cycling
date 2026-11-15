import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../engine/peloton/rider_race_state.dart';
import '../../models/race/race_stage.dart';
import '../../state/race_simulation_notifier.dart';
import 'elevation_profile_chart.dart';

/// Typ wydarzenia na osi czasu etapu wyścigu.
enum StageTimelineEventType {
  /// Atak kolarza lub grupy (ikona błyskawicy).
  attack,

  /// Defekt mechaniczny lub przebicie opony (ikona klucza).
  mechanical,

  /// Kraksa w peletonie lub ucieczce (ikona ostrzeżenia).
  crash,

  /// Wyniki premii górskiej KOM / QOM (ikona góry).
  komResult,

  /// Strefa bufetu / zaopatrzenia (ikona bidonu).
  feedZone;

  /// Czytelna etykieta typu wydarzenia po polsku.
  String get label {
    switch (this) {
      case StageTimelineEventType.attack:
        return 'Atak';
      case StageTimelineEventType.mechanical:
        return 'Defekt';
      case StageTimelineEventType.crash:
        return 'Kraksa';
      case StageTimelineEventType.komResult:
        return 'Premia KOM';
      case StageTimelineEventType.feedZone:
        return 'Bufet';
    }
  }

  /// Ikona przypisana do typu wydarzenia.
  IconData get icon {
    switch (this) {
      case StageTimelineEventType.attack:
        return Icons.bolt_rounded;
      case StageTimelineEventType.mechanical:
        return Icons.build_rounded;
      case StageTimelineEventType.crash:
        return Icons.warning_amber_rounded;
      case StageTimelineEventType.komResult:
        return Icons.landscape_rounded;
      case StageTimelineEventType.feedZone:
        return Icons.local_drink_rounded;
    }
  }

  /// Kolor akcentowy z palety [AppColors].
  Color get accentColor {
    switch (this) {
      case StageTimelineEventType.attack:
        return AppColors.goldAccent;
      case StageTimelineEventType.mechanical:
        return AppColors.accentBlue;
      case StageTimelineEventType.crash:
        return AppColors.crimsonAlert;
      case StageTimelineEventType.komResult:
        return AppColors.primaryAccent;
      case StageTimelineEventType.feedZone:
        return AppColors.statusSuccess;
    }
  }
}

/// Pojedyncze wydarzenie na interaktywnej osi czasu etapu.
class StageTimelineEvent {
  final String id;
  final StageTimelineEventType type;

  /// Dokładny kilometr etapu, na którym doszło do wydarzenia [km].
  final double kilometer;

  /// Godzina wyścigu lub czas etapu (np. `14:32` lub `02:48:15`).
  final String raceTimeLabel;

  /// Krótki tytuł wydarzenia.
  final String title;

  /// Pełny opis sytuacji wyświetlany w dymku i panelu analizy.
  final String description;

  /// Opcjonalne nazwisko głównego kolarza powiązanego z wydarzeniem.
  final String? riderName;

  /// Opcjonalna nazwa drużyny.
  final String? teamName;

  /// Wpływ na różnicę czasową w klasyfikacji generalnej (w sekundach).
  final double? gcImpactSeconds;

  /// Czy wydarzenie było momentem rozstrzygającym losy klasyfikacji generalnej.
  final bool isDecisiveGcMoment;

  const StageTimelineEvent({
    required this.id,
    required this.type,
    required this.kilometer,
    required this.raceTimeLabel,
    required this.title,
    required this.description,
    this.riderName,
    this.teamName,
    this.gcImpactSeconds,
    this.isDecisiveGcMoment = false,
  });

  /// Sformatowany tekst dymka z dokładnym kilometrem, godziną i opisem sytuacji.
  String get formattedTooltipText {
    final kmText = 'Km ${kilometer.toStringAsFixed(1)}';
    return '$kmText ($raceTimeLabel): $description';
  }
}

/// Migawka różnic czasowych klasyfikacji generalnej dla konkretnego kilometra etapu.
class StageGcGapSnapshot {
  final double kilometer;
  final String raceTimeLabel;
  final double leaderGapSeconds;
  final String summaryNote;

  const StageGcGapSnapshot({
    required this.kilometer,
    required this.raceTimeLabel,
    required this.leaderGapSeconds,
    required this.summaryNote,
  });
}

/// Interaktywny pasek osi czasu wyścigu umieszczany nad profilem wysokościowym etapu.
///
/// W trybie wyścigu na żywo (`isSummaryMode: false`) prezentuje wyłącznie wydarzenia,
/// które miały miejsce dotychczas (`kilometer <= currentKm`).
/// W trybie podsumowania etapu (`isSummaryMode: true`) umożliwia swobodne przewijanie
/// całej osi czasu i analizę kilometra, w którym rozstrzygnęła się klasyfikacja generalna.
class InteractiveStageTimelineScrubber extends StatefulWidget {
  /// Całkowity dystans etapu w kilometrach.
  final double totalDistanceKm;

  /// Aktualny kilometraż czoła wyścigu (lub domyślna pozycja w trybie podsumowania).
  final double currentKm;

  /// Lista wszystkich zarejestrowanych wydarzeń na etapie.
  final List<StageTimelineEvent> events;

  /// Tryb podsumowania etapu pozwalający na pełną analizę GC.
  final bool isSummaryMode;

  /// Zewnętrznie kontrolowana pozycja wskaźnika osi czasu [km].
  final double? scrubbedKm;

  /// Callback wywoływany przy zmianie analizowanego kilometra na osi czasu.
  final ValueChanged<double>? onScrubKmChanged;

  /// Callback wywoływany po kliknięciu lub aktywacji znacznika wydarzenia.
  final ValueChanged<StageTimelineEvent>? onEventSelected;

  /// Opcjonalne migawki różnic GC na trasie do analizy w trybie podsumowania.
  final List<StageGcGapSnapshot> gcSnapshots;

  /// Czy pasek osi czasu jest aktywny.
  final bool enabled;

  /// Opcjonalny początkowy zestaw filtrowanych typów wydarzeń.
  final Set<StageTimelineEventType>? initialFilterTypes;

  const InteractiveStageTimelineScrubber({
    super.key,
    required this.totalDistanceKm,
    required this.currentKm,
    required this.events,
    this.isSummaryMode = false,
    this.scrubbedKm,
    this.onScrubKmChanged,
    this.onEventSelected,
    this.gcSnapshots = const [],
    this.enabled = true,
    this.initialFilterTypes,
  });

  @override
  State<InteractiveStageTimelineScrubber> createState() =>
      _InteractiveStageTimelineScrubberState();
}

class _InteractiveStageTimelineScrubberState
    extends State<InteractiveStageTimelineScrubber>
    with SingleTickerProviderStateMixin {
  late double _internalScrubKm;
  late Set<StageTimelineEventType> _activeFilters;
  String? _hoveredEventId;
  String? _selectedEventId;
  bool _isTrackHovered = false;
  bool _isTrackFocused = false;
  bool _isDragging = false;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _internalScrubKm = _clampKm(widget.scrubbedKm ?? widget.currentKm);
    _activeFilters = widget.initialFilterTypes != null
        ? Set<StageTimelineEventType>.from(widget.initialFilterTypes!)
        : Set<StageTimelineEventType>.from(StageTimelineEventType.values);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant InteractiveStageTimelineScrubber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.scrubbedKm != null &&
        widget.scrubbedKm != oldWidget.scrubbedKm) {
      _internalScrubKm = _clampKm(widget.scrubbedKm!);
    } else if (!widget.isSummaryMode &&
        !_isDragging &&
        widget.currentKm != oldWidget.currentKm) {
      _internalScrubKm = _clampKm(widget.currentKm);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  double get _safeTotalKm =>
      widget.totalDistanceKm > 0.0 ? widget.totalDistanceKm : 1.0;

  double get _effectiveScrubKm =>
      _clampKm(widget.scrubbedKm ?? _internalScrubKm);

  double _clampKm(double km) {
    final maxKm = widget.isSummaryMode
        ? _safeTotalKm
        : widget.currentKm.clamp(0.0, _safeTotalKm);
    return km.clamp(0.0, math.max(0.0, maxKm));
  }

  List<StageTimelineEvent> get _visibleEvents {
    final maxKm = widget.isSummaryMode ? _safeTotalKm : widget.currentKm;
    final filtered = widget.events.where((event) {
      if (!_activeFilters.contains(event.type)) return false;
      if (!widget.isSummaryMode && event.kilometer > maxKm + 0.001) {
        return false;
      }
      return event.kilometer >= 0.0 && event.kilometer <= _safeTotalKm + 0.001;
    }).toList()
      ..sort((a, b) => a.kilometer.compareTo(b.kilometer));
    return filtered;
  }

  StageTimelineEvent? get _activeOrNearestEvent {
    final events = _visibleEvents;
    if (events.isEmpty) return null;

    if (_selectedEventId != null) {
      for (final e in events) {
        if (e.id == _selectedEventId) return e;
      }
    }

    StageTimelineEvent? nearest;
    double bestDist = double.infinity;
    for (final e in events) {
      final d = (e.kilometer - _effectiveScrubKm).abs();
      if (d < bestDist) {
        bestDist = d;
        nearest = e;
      }
    }
    return bestDist <= math.max(3.5, _safeTotalKm * 0.04) ? nearest : null;
  }

  StageGcGapSnapshot? get _nearestGcSnapshot {
    if (widget.gcSnapshots.isEmpty) return null;
    StageGcGapSnapshot? nearest;
    double bestDist = double.infinity;
    for (final snap in widget.gcSnapshots) {
      final d = (snap.kilometer - _effectiveScrubKm).abs();
      if (d < bestDist) {
        bestDist = d;
        nearest = snap;
      }
    }
    return nearest;
  }

  List<StageTimelineEvent> get _decisiveGcEvents =>
      _visibleEvents.where((e) => e.isDecisiveGcMoment).toList();

  void _updateScrubFromLocalX(double localX, double trackWidth) {
    if (!widget.enabled || trackWidth <= 0.0) return;
    final fraction = (localX / trackWidth).clamp(0.0, 1.0);
    final nextKm = _clampKm(fraction * _safeTotalKm);
    setState(() {
      _internalScrubKm = nextKm;
    });
    widget.onScrubKmChanged?.call(nextKm);
  }

  void _selectEvent(StageTimelineEvent event) {
    if (!widget.enabled) return;
    setState(() {
      _selectedEventId = event.id;
      _internalScrubKm = _clampKm(event.kilometer);
    });
    widget.onScrubKmChanged?.call(_internalScrubKm);
    widget.onEventSelected?.call(event);
  }

  void _toggleFilter(StageTimelineEventType type) {
    if (!widget.enabled) return;
    setState(() {
      if (_activeFilters.contains(type)) {
        if (_activeFilters.length > 1) {
          _activeFilters.remove(type);
        }
      } else {
        _activeFilters.add(type);
      }
    });
  }

  void _jumpToDecisiveGc({required bool forward}) {
    if (!widget.enabled) return;
    final targets =
        _decisiveGcEvents.isNotEmpty ? _decisiveGcEvents : _visibleEvents;
    if (targets.isEmpty) return;

    StageTimelineEvent? chosen;
    if (forward) {
      for (final e in targets) {
        if (e.kilometer > _effectiveScrubKm + 0.05) {
          chosen = e;
          break;
        }
      }
      chosen ??= targets.first;
    } else {
      for (int i = targets.length - 1; i >= 0; i--) {
        if (targets[i].kilometer < _effectiveScrubKm - 0.05) {
          chosen = targets[i];
          break;
        }
      }
      chosen ??= targets.last;
    }
    _selectEvent(chosen);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (!widget.enabled || event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    final stepKm = math.max(1.0, _safeTotalKm * 0.02);
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      final nextKm = _clampKm(_effectiveScrubKm + stepKm);
      setState(() => _internalScrubKm = nextKm);
      widget.onScrubKmChanged?.call(nextKm);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      final nextKm = _clampKm(_effectiveScrubKm - stepKm);
      setState(() => _internalScrubKm = nextKm);
      widget.onScrubKmChanged?.call(nextKm);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.home) {
      setState(() => _internalScrubKm = 0.0);
      widget.onScrubKmChanged?.call(0.0);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.end) {
      final endKm = _clampKm(_safeTotalKm);
      setState(() => _internalScrubKm = endKm);
      widget.onScrubKmChanged?.call(endKm);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 560;
        final visibleEvents = _visibleEvents;
        final activeEvent = _activeOrNearestEvent;
        final gcSnapshot = _nearestGcSnapshot;

        return AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          opacity: widget.enabled ? 1.0 : 0.5,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isTrackFocused
                    ? AppColors.goldAccent
                    : AppTheme.borderColor,
                width: _isTrackFocused ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.32),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 12 : 16,
              vertical: isCompact ? 10 : 12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderRow(isCompact, visibleEvents.length),
                const SizedBox(height: 8),
                _buildFilterChipsRow(isCompact),
                const SizedBox(height: 10),
                _buildTimelineTrack(visibleEvents),
                if (widget.isSummaryMode || activeEvent != null) ...[
                  const SizedBox(height: 10),
                  _buildAnalysisFooter(isCompact, activeEvent, gcSnapshot),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderRow(bool isCompact, int eventCount) {
    final progressRatio = (_effectiveScrubKm / _safeTotalKm).clamp(0.0, 1.0);
    final kmReadout =
        'Km ${_effectiveScrubKm.toStringAsFixed(1)} / ${_safeTotalKm.toStringAsFixed(1)} km';

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: widget.isSummaryMode
            ? AppColors.goldAccent.withValues(alpha: 0.16)
            : AppColors.primaryAccent.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.isSummaryMode
              ? AppColors.goldAccent.withValues(alpha: 0.5)
              : AppColors.primaryAccent.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.isSummaryMode
                ? Icons.analytics_outlined
                : Icons.timeline_rounded,
            size: 14,
            color: widget.isSummaryMode
                ? AppColors.goldAccent
                : AppColors.textPrimary,
          ),
          const SizedBox(width: 6),
          Text(
            widget.isSummaryMode ? 'ANALIZA OSI CZASU GC' : 'OŚ CZASU ETAPU',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: isCompact ? 10 : 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: widget.isSummaryMode
                  ? AppColors.goldAccent
                  : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );

    final kmChip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Text(
        kmReadout,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: isCompact ? 11 : 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );

    if (isCompact) {
      return Wrap(
        spacing: 8,
        runSpacing: 6,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          badge,
          kmChip,
        ],
      );
    }

    return Row(
      children: [
        badge,
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$eventCount wydarzeń • ${(progressRatio * 100).toStringAsFixed(0)}% trasy',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(width: 8),
        kmChip,
      ],
    );
  }

  Widget _buildFilterChipsRow(bool isCompact) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final type in StageTimelineEventType.values)
          _TimelineFilterChip(
            type: type,
            isSelected: _activeFilters.contains(type),
            enabled: widget.enabled,
            compact: isCompact,
            onTap: () => _toggleFilter(type),
          ),
        if (widget.isSummaryMode && _decisiveGcEvents.isNotEmpty) ...[
          const SizedBox(width: 4),
          _GcJumpButton(
            icon: Icons.skip_previous_rounded,
            tooltip: 'Poprzedni kluczowy moment GC',
            enabled: widget.enabled,
            onPressed: () => _jumpToDecisiveGc(forward: false),
          ),
          _GcJumpButton(
            icon: Icons.skip_next_rounded,
            tooltip: 'Następny kluczowy moment GC',
            enabled: widget.enabled,
            onPressed: () => _jumpToDecisiveGc(forward: true),
          ),
        ],
      ],
    );
  }

  Widget _buildTimelineTrack(List<StageTimelineEvent> events) {
    const double trackHeight = 64.0;
    const double markerSize = 28.0;
    const double horizontalPad = 14.0;

    return Focus(
      onFocusChange: (focused) => setState(() => _isTrackFocused = focused),
      onKeyEvent: _handleKeyEvent,
      child: MouseRegion(
        cursor: widget.enabled
            ? (_isDragging
                ? SystemMouseCursors.grabbing
                : SystemMouseCursors.grab)
            : SystemMouseCursors.forbidden,
        onEnter: (_) => setState(() => _isTrackHovered = true),
        onExit: (_) => setState(() => _isTrackHovered = false),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final usableWidth =
                math.max(1.0, constraints.maxWidth - horizontalPad * 2);
            final currentRatio =
                (widget.currentKm / _safeTotalKm).clamp(0.0, 1.0);
            final scrubRatio =
                (_effectiveScrubKm / _safeTotalKm).clamp(0.0, 1.0);
            final activeBarRatio =
                widget.isSummaryMode ? scrubRatio : currentRatio;

            // Rozłożenie nakładających się markerów na dwóch poziomach wysokości.
            final List<double> laneTops =
                _computeStaggeredLanes(events, usableWidth, markerSize);

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: widget.enabled
                  ? (details) => _updateScrubFromLocalX(
                        details.localPosition.dx - horizontalPad,
                        usableWidth,
                      )
                  : null,
              onHorizontalDragStart: widget.enabled
                  ? (details) {
                      setState(() => _isDragging = true);
                      _updateScrubFromLocalX(
                        details.localPosition.dx - horizontalPad,
                        usableWidth,
                      );
                    }
                  : null,
              onHorizontalDragUpdate: widget.enabled
                  ? (details) => _updateScrubFromLocalX(
                        details.localPosition.dx - horizontalPad,
                        usableWidth,
                      )
                  : null,
              onHorizontalDragEnd: widget.enabled
                  ? (_) => setState(() => _isDragging = false)
                  : null,
              onHorizontalDragCancel: widget.enabled
                  ? () => setState(() => _isDragging = false)
                  : null,
              child: Container(
                height: trackHeight,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isTrackHovered && widget.enabled
                        ? AppColors.goldAccent.withValues(alpha: 0.45)
                        : AppTheme.borderColor,
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Podziałka kilometrowa w tle
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: horizontalPad),
                        child: CustomPaint(
                          painter: _TimelineRulerPainter(
                            totalKm: _safeTotalKm,
                            activeRatio: activeBarRatio,
                            scrubRatio: scrubRatio,
                            isSummaryMode: widget.isSummaryMode,
                          ),
                        ),
                      ),
                    ),

                    // Znaczniki wydarzeń na osi czasu
                    for (int i = 0; i < events.length; i++)
                      Positioned(
                        left: horizontalPad +
                            ((events[i].kilometer / _safeTotalKm)
                                    .clamp(0.0, 1.0) *
                                usableWidth) -
                            (markerSize / 2),
                        top: laneTops[i],
                        child: _TimelineEventMarker(
                          event: events[i],
                          size: markerSize,
                          enabled: widget.enabled,
                          isHovered: _hoveredEventId == events[i].id,
                          isSelected: _selectedEventId == events[i].id,
                          pulseAnimation: _pulseController,
                          onHoverChanged: (hovering) {
                            setState(() {
                              _hoveredEventId = hovering ? events[i].id : null;
                            });
                          },
                          onTap: () => _selectEvent(events[i]),
                        ),
                      ),

                    // Suwak analizowanego kilometra (Scrubber Thumb)
                    Positioned(
                      left: horizontalPad + (scrubRatio * usableWidth) - 7,
                      top: 2,
                      bottom: 2,
                      child: IgnorePointer(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          width: 14,
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: AppColors.goldAccent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.background,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.goldAccent
                                          .withValues(alpha: 0.45),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  width: 2,
                                  color: AppColors.goldAccent
                                      .withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<double> _computeStaggeredLanes(
    List<StageTimelineEvent> events,
    double usableWidth,
    double markerSize,
  ) {
    const double topLane = 8.0;
    const double bottomLane = 28.0;
    final List<double> result = List<double>.filled(events.length, topLane);
    double lastTopX = -999.0;
    double lastBottomX = -999.0;

    for (int i = 0; i < events.length; i++) {
      final x = (events[i].kilometer / _safeTotalKm).clamp(0.0, 1.0) *
          usableWidth;
      if ((x - lastTopX).abs() >= markerSize * 0.9) {
        result[i] = topLane;
        lastTopX = x;
      } else if ((x - lastBottomX).abs() >= markerSize * 0.9) {
        result[i] = bottomLane;
        lastBottomX = x;
      } else {
        result[i] = topLane;
        lastTopX = x;
      }
    }
    return result;
  }

  Widget _buildAnalysisFooter(
    bool isCompact,
    StageTimelineEvent? activeEvent,
    StageGcGapSnapshot? gcSnapshot,
  ) {
    final bool hasGcImpact = activeEvent?.isDecisiveGcMoment == true ||
        activeEvent?.gcImpactSeconds != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasGcImpact
              ? AppColors.goldAccent.withValues(alpha: 0.55)
              : AppTheme.borderColor,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            activeEvent?.type.icon ?? Icons.flag_rounded,
            size: 16,
            color: activeEvent?.type.accentColor ?? AppColors.goldAccent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (activeEvent != null) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Km ${activeEvent.kilometer.toStringAsFixed(1)} • ${activeEvent.raceTimeLabel}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.goldAccent,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      if (activeEvent.isDecisiveGcMoment)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.goldAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'ROZSTRZYGNIĘCIE GC',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.goldAccent,
                            ),
                          ),
                        ),
                      if (activeEvent.gcImpactSeconds != null)
                        Text(
                          '${activeEvent.gcImpactSeconds! >= 0 ? '+' : ''}${activeEvent.gcImpactSeconds!.toStringAsFixed(0)}s GC',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: activeEvent.gcImpactSeconds! > 0
                                ? AppColors.crimsonAlert
                                : AppColors.statusSuccess,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    activeEvent.description,
                    maxLines: isCompact ? 3 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ] else ...[
                  Text(
                    gcSnapshot != null
                        ? 'Km ${gcSnapshot.kilometer.toStringAsFixed(1)} (${gcSnapshot.raceTimeLabel}) — ${gcSnapshot.summaryNote}'
                        : 'Przesuń suwak lub kliknij znacznik, aby przeanalizować momenty etapu i różnice GC.',
                    maxLines: isCompact ? 3 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Złożony widget łączący [InteractiveStageTimelineScrubber] bezpośrednio nad
/// wykresem [ElevationProfileChart] ze wspólną synchronizacją kilometrażu.
class StageProfileWithTimelineScrubber extends StatefulWidget {
  final RaceStage stage;
  final List<StageTimelineEvent> events;
  final double currentLeadKm;
  final bool isSummaryMode;
  final bool isLiveRace;
  final List<RiderPositionSnapshot>? riderSnapshots;
  final Map<String, RiderRaceState>? riderStates;
  final List<String> playerRiderIds;
  final String? selectedRiderId;
  final List<StageGcGapSnapshot> gcSnapshots;
  final ValueChanged<String>? onRiderSelected;
  final ValueChanged<StageTimelineEvent>? onEventSelected;
  final double chartHeight;

  const StageProfileWithTimelineScrubber({
    super.key,
    required this.stage,
    required this.events,
    required this.currentLeadKm,
    this.isSummaryMode = false,
    this.isLiveRace = false,
    this.riderSnapshots,
    this.riderStates,
    this.playerRiderIds = const [],
    this.selectedRiderId,
    this.gcSnapshots = const [],
    this.onRiderSelected,
    this.onEventSelected,
    this.chartHeight = 240,
  });

  @override
  State<StageProfileWithTimelineScrubber> createState() =>
      _StageProfileWithTimelineScrubberState();
}

class _StageProfileWithTimelineScrubberState
    extends State<StageProfileWithTimelineScrubber> {
  double? _scrubbedKm;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showChartHeader = constraints.maxWidth >= 560;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InteractiveStageTimelineScrubber(
              totalDistanceKm: widget.stage.totalDistanceKm,
              currentKm: widget.currentLeadKm,
              events: widget.events,
              isSummaryMode: widget.isSummaryMode,
              scrubbedKm: _scrubbedKm,
              gcSnapshots: widget.gcSnapshots,
              onScrubKmChanged: (km) => setState(() => _scrubbedKm = km),
              onEventSelected: widget.onEventSelected,
            ),
            const SizedBox(height: 10),
            ElevationProfileChart(
              stage: widget.stage,
              height: widget.chartHeight,
              showHeader: showChartHeader,
              riderSnapshots: widget.riderSnapshots,
              riderStates: widget.riderStates,
              playerRiderIds: widget.playerRiderIds,
              selectedRiderId: widget.selectedRiderId,
              currentLeadKm: _scrubbedKm ?? widget.currentLeadKm,
              isLiveRace: widget.isLiveRace,
              onRiderSelected: widget.onRiderSelected,
              onKmScrubbed: (km) => setState(() => _scrubbedKm = km),
            ),
          ],
        );
      },
    );
  }
}

class _TimelineEventMarker extends StatelessWidget {
  final StageTimelineEvent event;
  final double size;
  final bool enabled;
  final bool isHovered;
  final bool isSelected;
  final Animation<double> pulseAnimation;
  final ValueChanged<bool> onHoverChanged;
  final VoidCallback onTap;

  const _TimelineEventMarker({
    required this.event,
    required this.size,
    required this.enabled,
    required this.isHovered,
    required this.isSelected,
    required this.pulseAnimation,
    required this.onHoverChanged,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = event.type.accentColor;
    final tooltipText = event.formattedTooltipText;

    return Tooltip(
      message: tooltipText,
      waitDuration: const Duration(milliseconds: 120),
      showDuration: const Duration(seconds: 5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.75), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      textStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      child: MouseRegion(
        cursor:
            enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
        onEnter: (_) => onHoverChanged(true),
        onExit: (_) => onHoverChanged(false),
        child: GestureDetector(
          onTap: enabled ? onTap : null,
          child: AnimatedBuilder(
            animation: pulseAnimation,
            builder: (context, child) {
              final double scale = isHovered || isSelected
                  ? 1.18
                  : (event.isDecisiveGcMoment
                      ? 1.0 + (pulseAnimation.value * 0.08)
                      : 1.0);
              return Transform.scale(
                scale: scale,
                child: child,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: isSelected
                    ? color
                    : (isHovered
                        ? color.withValues(alpha: 0.28)
                        : AppColors.surfaceLight),
                shape: BoxShape.circle,
                border: Border.all(
                  color: event.isDecisiveGcMoment
                      ? AppColors.goldAccent
                      : color,
                  width: isSelected || event.isDecisiveGcMoment ? 2.0 : 1.2,
                ),
                boxShadow: [
                  if (isHovered || isSelected || event.isDecisiveGcMoment)
                    BoxShadow(
                      color: color.withValues(alpha: 0.45),
                      blurRadius: 8,
                    ),
                ],
              ),
              child: Icon(
                event.type.icon,
                size: size * 0.54,
                color: isSelected ? AppColors.background : color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimelineFilterChip extends StatefulWidget {
  final StageTimelineEventType type;
  final bool isSelected;
  final bool enabled;
  final bool compact;
  final VoidCallback onTap;

  const _TimelineFilterChip({
    required this.type,
    required this.isSelected,
    required this.enabled,
    required this.compact,
    required this.onTap,
  });

  @override
  State<_TimelineFilterChip> createState() => _TimelineFilterChipState();
}

class _TimelineFilterChipState extends State<_TimelineFilterChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.type.accentColor;
    return MouseRegion(
      cursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.enabled ? widget.onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 8 : 10,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? color.withValues(alpha: _isHovered ? 0.28 : 0.18)
                : (_isHovered ? AppColors.surfaceLight : AppColors.background),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.isSelected
                  ? color.withValues(alpha: 0.75)
                  : AppTheme.borderColor,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.type.icon,
                size: 13,
                color: widget.isSelected ? color : AppColors.textSecondary,
              ),
              const SizedBox(width: 5),
              Text(
                widget.type.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight:
                      widget.isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: widget.isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GcJumpButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onPressed;

  const _GcJumpButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.goldAccent.withValues(alpha: 0.45),
            ),
          ),
          child: Icon(
            icon,
            size: 15,
            color: enabled ? AppColors.goldAccent : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _TimelineRulerPainter extends CustomPainter {
  final double totalKm;
  final double activeRatio;
  final double scrubRatio;
  final bool isSummaryMode;

  const _TimelineRulerPainter({
    required this.totalKm,
    required this.activeRatio,
    required this.scrubRatio,
    required this.isSummaryMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double barY = size.height - 12.0;

    final trackPaint = Paint()
      ..color = AppTheme.borderColor
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(0, barY),
      Offset(size.width, barY),
      trackPaint,
    );

    final activePaint = Paint()
      ..color = isSummaryMode
          ? AppColors.goldAccent.withValues(alpha: 0.7)
          : AppColors.primaryAccent
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(0, barY),
      Offset(size.width * activeRatio.clamp(0.0, 1.0), barY),
      activePaint,
    );

    // Kreski podziałki co 20% etapu
    final tickPaint = Paint()
      ..color = AppColors.textSecondary.withValues(alpha: 0.35)
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 5; i++) {
      final t = i / 5.0;
      final x = size.width * t;
      canvas.drawLine(
        Offset(x, barY - 4),
        Offset(x, barY + 4),
        tickPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TimelineRulerPainter oldDelegate) {
    return oldDelegate.totalKm != totalKm ||
        oldDelegate.activeRatio != activeRatio ||
        oldDelegate.scrubRatio != scrubRatio ||
        oldDelegate.isSummaryMode != isSummaryMode;
  }
}
