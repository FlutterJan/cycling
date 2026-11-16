import 'dart:collection';
import 'dart:io' show ProcessInfo;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/performance_profiler_overlay.dart';

/// Narożnik ekranu, w którym wyświetlana jest nakładka telemetryczna.
enum TelemetryOverlayCorner {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

/// Niemutowalny zrzut metryk wydajności dla [FpsAndSimulationTelemetryOverlay].
@immutable
class SimulationTelemetrySnapshot {
  /// Aktualna liczba klatek na sekundę (FPS).
  final double fps;

  /// Czas renderowania pojedynczej ramki (Build + Raster) w milisekundach.
  final double frameRenderTimeMs;

  /// Czas wykonania jednego kroku fizyki w wątku `Isolate` w milisekundach.
  final double isolatePhysicsStepMs;

  /// Liczba widocznych wielokątów (trójkątów) 3D w bieżącej klatce.
  final int visiblePolygons3d;

  /// Aktualne zużycie pamięci RAM procesu w megabajtach (MB).
  final double ramUsageMb;

  /// Docelowy limit FPS (np. 60 lub 120) do wyliczania progów kolorystycznych.
  final int targetFps;

  /// Czy pętla symulacji fizyki `Isolate` jest aktualnie aktywna.
  final bool isSimulationActive;

  const SimulationTelemetrySnapshot({
    this.fps = 60.0,
    this.frameRenderTimeMs = 0.0,
    this.isolatePhysicsStepMs = 0.0,
    this.visiblePolygons3d = 0,
    this.ramUsageMb = 0.0,
    this.targetFps = 60,
    this.isSimulationActive = false,
  });

  /// Zwraca bezpieczną, znormalizowaną kopię bez wartości NaN, Infinity ani ujemnych.
  SimulationTelemetrySnapshot sanitized() {
    double cleanDouble(double value, {double max = 1000000.0}) {
      if (value.isNaN || value.isInfinite || value < 0) return 0.0;
      return math.min(value, max);
    }

    return SimulationTelemetrySnapshot(
      fps: cleanDouble(fps, max: 1000.0),
      frameRenderTimeMs: cleanDouble(frameRenderTimeMs, max: 10000.0),
      isolatePhysicsStepMs: cleanDouble(isolatePhysicsStepMs, max: 10000.0),
      visiblePolygons3d: visiblePolygons3d < 0 ? 0 : visiblePolygons3d,
      ramUsageMb: cleanDouble(ramUsageMb, max: 1048576.0),
      targetFps: targetFps <= 0 ? 60 : targetFps,
      isSimulationActive: isSimulationActive,
    );
  }

  SimulationTelemetrySnapshot copyWith({
    double? fps,
    double? frameRenderTimeMs,
    double? isolatePhysicsStepMs,
    int? visiblePolygons3d,
    double? ramUsageMb,
    int? targetFps,
    bool? isSimulationActive,
  }) {
    return SimulationTelemetrySnapshot(
      fps: fps ?? this.fps,
      frameRenderTimeMs: frameRenderTimeMs ?? this.frameRenderTimeMs,
      isolatePhysicsStepMs: isolatePhysicsStepMs ?? this.isolatePhysicsStepMs,
      visiblePolygons3d: visiblePolygons3d ?? this.visiblePolygons3d,
      ramUsageMb: ramUsageMb ?? this.ramUsageMb,
      targetFps: targetFps ?? this.targetFps,
      isSimulationActive: isSimulationActive ?? this.isSimulationActive,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SimulationTelemetrySnapshot &&
        other.fps == fps &&
        other.frameRenderTimeMs == frameRenderTimeMs &&
        other.isolatePhysicsStepMs == isolatePhysicsStepMs &&
        other.visiblePolygons3d == visiblePolygons3d &&
        other.ramUsageMb == ramUsageMb &&
        other.targetFps == targetFps &&
        other.isSimulationActive == isSimulationActive;
  }

  @override
  int get hashCode => Object.hash(
        fps,
        frameRenderTimeMs,
        isolatePhysicsStepMs,
        visiblePolygons3d,
        ramUsageMb,
        targetFps,
        isSimulationActive,
      );
}

/// Opcjonalny licznik wydajności dla gracza i testera w rogu ekranu.
///
/// Prezentuje w czasie rzeczywistym:
/// - aktualny FPS,
/// - czas renderowania ramki (ms),
/// - czas kroku fizyki `Isolate` (ms),
/// - liczbę widocznych wielokątów 3D,
/// - zużycie pamięci RAM (MB).
///
/// Może być użyty jako wrapper (`child: ...`) lub bezpośrednio wewnątrz `Stack`.
class FpsAndSimulationTelemetryOverlay extends StatefulWidget {
  /// Opcjonalna zawartość pod nakładką (jeśli widget działa jako wrapper).
  final Widget? child;

  /// Czy nakładka jest widoczna.
  final bool isVisible;

  /// Początkowy narożnik wyświetlania nakładki.
  final TelemetryOverlayCorner corner;

  /// Opcjonalny zewnętrzny zrzut metryk (np. do testów lub trybu deterministycznego).
  final SimulationTelemetrySnapshot? snapshot;

  /// Opcjonalne źródło strumienia metryk aktualizowane z zewnątrz.
  final ValueListenable<SimulationTelemetrySnapshot>? telemetryListenable;

  /// Czy automatycznie zbierać czasy klatek przez `SchedulerBinding` oraz RAM procesu.
  final bool enableLiveSchedulerTimings;

  /// Czy panel startuje w trybie rozwiniętym (pełne 5 metryk) czy kompaktowym.
  final bool initiallyExpanded;

  /// Czy przyciski sterujące w nakładce są aktywne.
  final bool isInteractive;

  /// Opcjonalny callback wywoływany po kliknięciu przycisku zamknięcia.
  final VoidCallback? onClose;

  /// Opcjonalny callback po zmianie narożnika przez użytkownika.
  final ValueChanged<TelemetryOverlayCorner>? onCornerChanged;

  const FpsAndSimulationTelemetryOverlay({
    super.key,
    this.child,
    this.isVisible = true,
    this.corner = TelemetryOverlayCorner.topRight,
    this.snapshot,
    this.telemetryListenable,
    this.enableLiveSchedulerTimings = true,
    this.initiallyExpanded = true,
    this.isInteractive = true,
    this.onClose,
    this.onCornerChanged,
  });

  @override
  State<FpsAndSimulationTelemetryOverlay> createState() =>
      _FpsAndSimulationTelemetryOverlayState();
}

class _FpsAndSimulationTelemetryOverlayState
    extends State<FpsAndSimulationTelemetryOverlay>
    with SingleTickerProviderStateMixin {
  static const int _historyCapacity = 24;
  static const int _estimatedPolygonsPerLod0 = 850;
  static const int _estimatedPolygonsPerLod1 = 320;
  static const int _estimatedPolygonsPerLod2 = 96;

  final ListQueue<double> _frameHistoryMs = ListQueue<double>();
  final ListQueue<int> _frameTimestampsUs = ListQueue<int>();

  late final AnimationController _visibilityController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  late TelemetryOverlayCorner _activeCorner;
  late bool _isExpanded;
  bool _isPaused = false;
  bool _timingsRegistered = false;
  bool _isCardHovered = false;

  double _measuredFps = 60.0;
  double _measuredFrameMs = 0.0;
  double _measuredRamMb = 0.0;
  double _peakFrameMs = 0.0;
  int _lastRamSampleMs = 0;

  @override
  void initState() {
    super.initState();
    _activeCorner = widget.corner;
    _isExpanded = widget.initiallyExpanded;

    _visibilityController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
      value: widget.isVisible ? 1.0 : 0.0,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _visibilityController,
      curve: Curves.easeOutCubic,
    );
    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.0).animate(
      _fadeAnimation,
    );

    _refreshRamUsage(force: true);
    _syncSeedHistoryFromSnapshot();
    _syncTimingsRegistration();

    widget.telemetryListenable?.addListener(_onExternalTelemetryChanged);
    PerformanceTelemetryRegistry.instance.metrics
        .addListener(_onEngineMetricsChanged);
  }

  @override
  void didUpdateWidget(covariant FpsAndSimulationTelemetryOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.corner != oldWidget.corner) {
      _activeCorner = widget.corner;
    }

    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _refreshRamUsage(force: true);
        _visibilityController.forward();
      } else {
        _visibilityController.reverse();
      }
      _syncTimingsRegistration();
    }

    if (widget.telemetryListenable != oldWidget.telemetryListenable) {
      oldWidget.telemetryListenable?.removeListener(_onExternalTelemetryChanged);
      widget.telemetryListenable?.addListener(_onExternalTelemetryChanged);
    }

    if (widget.snapshot != oldWidget.snapshot) {
      _syncSeedHistoryFromSnapshot();
    }

    if (widget.enableLiveSchedulerTimings !=
        oldWidget.enableLiveSchedulerTimings) {
      _syncTimingsRegistration();
    }
  }

  @override
  void dispose() {
    _setTimingsRegistered(false);
    widget.telemetryListenable?.removeListener(_onExternalTelemetryChanged);
    PerformanceTelemetryRegistry.instance.metrics
        .removeListener(_onEngineMetricsChanged);
    _visibilityController.dispose();
    super.dispose();
  }

  void _syncSeedHistoryFromSnapshot() {
    final snap = widget.snapshot?.sanitized();
    if (snap == null || _isPaused) return;
    _recordFrameHistorySample(snap.frameRenderTimeMs);
  }

  void _onExternalTelemetryChanged() {
    if (!mounted || _isPaused) return;
    final snap = widget.telemetryListenable?.value.sanitized();
    if (snap != null) {
      _recordFrameHistorySample(snap.frameRenderTimeMs);
    }
    setState(() {});
  }

  void _onEngineMetricsChanged() {
    if (!mounted || _isPaused) return;
    setState(() {});
  }

  void _syncTimingsRegistration() {
    final shouldListen = widget.isVisible &&
        widget.enableLiveSchedulerTimings &&
        widget.snapshot == null &&
        widget.telemetryListenable == null &&
        !_isPaused;
    _setTimingsRegistered(shouldListen);
  }

  void _setTimingsRegistered(bool active) {
    if (active && !_timingsRegistered) {
      SchedulerBinding.instance.addTimingsCallback(_onReportTimings);
      _timingsRegistered = true;
    } else if (!active && _timingsRegistered) {
      SchedulerBinding.instance.removeTimingsCallback(_onReportTimings);
      _timingsRegistered = false;
    }
  }

  void _onReportTimings(List<FrameTiming> timings) {
    if (!mounted || _isPaused || timings.isEmpty) return;

    final nowUs = DateTime.now().microsecondsSinceEpoch;
    for (final timing in timings) {
      final buildMs = timing.buildDuration.inMicroseconds / 1000.0;
      final rasterMs = timing.rasterDuration.inMicroseconds / 1000.0;
      final spanMs = timing.totalSpan.inMicroseconds / 1000.0;
      final frameMs = math.max(spanMs, buildMs + rasterMs);
      _measuredFrameMs = frameMs;
      _recordFrameHistorySample(frameMs);
      _frameTimestampsUs.addLast(nowUs);
    }

    final cutoffUs = nowUs - 1000000;
    while (_frameTimestampsUs.isNotEmpty &&
        _frameTimestampsUs.first < cutoffUs) {
      _frameTimestampsUs.removeFirst();
    }

    if (_frameTimestampsUs.length >= 2) {
      final elapsedUs = _frameTimestampsUs.last - _frameTimestampsUs.first;
      if (elapsedUs > 0) {
        final fps = (_frameTimestampsUs.length - 1) * 1000000.0 / elapsedUs;
        _measuredFps = fps.clamp(1.0, 240.0);
      }
    } else if (_measuredFrameMs > 0.1) {
      _measuredFps = (1000.0 / _measuredFrameMs).clamp(1.0, 240.0);
    }

    _refreshRamUsage(force: false);
    setState(() {});
  }

  void _recordFrameHistorySample(double frameMs) {
    if (frameMs.isNaN || frameMs.isInfinite || frameMs < 0) return;
    if (frameMs > _peakFrameMs) {
      _peakFrameMs = frameMs;
    }
    _frameHistoryMs.addLast(frameMs);
    while (_frameHistoryMs.length > _historyCapacity) {
      _frameHistoryMs.removeFirst();
    }
  }

  void _refreshRamUsage({required bool force}) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (!force && nowMs - _lastRamSampleMs < 800) return;
    _lastRamSampleMs = nowMs;

    if (kIsWeb) return;
    try {
      final rssBytes = ProcessInfo.currentRss;
      if (rssBytes > 0) {
        _measuredRamMb = rssBytes / (1024.0 * 1024.0);
      }
    } catch (_) {
      // Platforma bez dostępu do ProcessInfo.currentRss — pozostaw ostatnią wartość.
    }
  }

  SimulationTelemetrySnapshot _resolveSnapshot() {
    if (widget.snapshot != null) {
      return widget.snapshot!.sanitized();
    }
    if (widget.telemetryListenable != null) {
      return widget.telemetryListenable!.value.sanitized();
    }

    final engine = PerformanceTelemetryRegistry.instance.metrics.value;
    final estimatedPolygons = (engine.lod0Count * _estimatedPolygonsPerLod0) +
        (engine.lod1Count * _estimatedPolygonsPerLod1) +
        (engine.lod2Count * _estimatedPolygonsPerLod2);

    return SimulationTelemetrySnapshot(
      fps: _measuredFps,
      frameRenderTimeMs: _measuredFrameMs,
      isolatePhysicsStepMs: engine.physicsTickMicroseconds / 1000.0,
      visiblePolygons3d: estimatedPolygons,
      ramUsageMb: _measuredRamMb,
      targetFps: 60,
      isSimulationActive: engine.isSimulationActive,
    ).sanitized();
  }

  void _togglePaused() {
    if (!widget.isInteractive) return;
    setState(() {
      _isPaused = !_isPaused;
      _syncTimingsRegistration();
    });
  }

  void _toggleExpanded() {
    if (!widget.isInteractive) return;
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  void _cycleCorner() {
    if (!widget.isInteractive) return;
    const order = [
      TelemetryOverlayCorner.topRight,
      TelemetryOverlayCorner.bottomRight,
      TelemetryOverlayCorner.bottomLeft,
      TelemetryOverlayCorner.topLeft,
    ];
    final nextIndex = (order.indexOf(_activeCorner) + 1) % order.length;
    final nextCorner = order[nextIndex];
    setState(() {
      _activeCorner = nextCorner;
    });
    widget.onCornerChanged?.call(nextCorner);
  }

  void _resetPeak() {
    if (!widget.isInteractive || _peakFrameMs <= 0.0) return;
    setState(() {
      _peakFrameMs = 0.0;
      _frameHistoryMs.clear();
    });
  }

  Alignment _cornerAlignment(TelemetryOverlayCorner corner) {
    switch (corner) {
      case TelemetryOverlayCorner.topLeft:
        return Alignment.topLeft;
      case TelemetryOverlayCorner.topRight:
        return Alignment.topRight;
      case TelemetryOverlayCorner.bottomLeft:
        return Alignment.bottomLeft;
      case TelemetryOverlayCorner.bottomRight:
        return Alignment.bottomRight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final overlayContent = LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth =
            constraints.hasBoundedWidth ? constraints.maxWidth : 1600.0;
        final maxHeight =
            constraints.hasBoundedHeight ? constraints.maxHeight : 900.0;

        final isCompactViewport = maxWidth < 600.0;
        final isTabletViewport = maxWidth >= 600.0 && maxWidth < 1200.0;
        final outerMargin = isCompactViewport ? 8.0 : 14.0;
        final desiredWidth = _isExpanded
            ? (isCompactViewport
                ? 248.0
                : (isTabletViewport ? 276.0 : 304.0))
            : (isCompactViewport ? 210.0 : 244.0);
        final cardWidth = math.max(
          140.0,
          math.min(desiredWidth, maxWidth - outerMargin * 2),
        );
        final maxCardHeight = math.max(88.0, maxHeight - outerMargin * 2);

        return AnimatedBuilder(
          animation: _visibilityController,
          builder: (context, child) {
            if (_visibilityController.isDismissed && !widget.isVisible) {
              return const SizedBox.shrink();
            }
            return IgnorePointer(
              ignoring: !widget.isVisible,
              child: Padding(
                padding: EdgeInsets.all(outerMargin),
                child: AnimatedAlign(
                  alignment: _cornerAlignment(_activeCorner),
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      alignment: _cornerAlignment(_activeCorner),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: cardWidth,
                          maxHeight: maxCardHeight,
                        ),
                        child: _buildCard(
                          context: context,
                          cardWidth: cardWidth,
                          isCompactViewport: isCompactViewport,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (widget.child == null) {
      return overlayContent;
    }

    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child!,
        Positioned.fill(child: overlayContent),
      ],
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required double cardWidth,
    required bool isCompactViewport,
  }) {
    final snapshot = _resolveSnapshot();
    final fpsColor = _fpsStatusColor(snapshot.fps, snapshot.targetFps);
    final frameColor =
        _frameTimeColor(snapshot.frameRenderTimeMs, snapshot.targetFps);
    final isolateColor = _isolateTimeColor(snapshot.isolatePhysicsStepMs);
    final polyColor = _polygonCountColor(snapshot.visiblePolygons3d);
    final ramColor = _ramUsageColor(snapshot.ramUsageMb);

    final padding = isCompactViewport ? 10.0 : 12.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isCardHovered = true),
      onExit: (_) => setState(() => _isCardHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: cardWidth,
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isCardHovered
                ? AppColors.goldAccent.withValues(alpha: 0.55)
                : AppColors.cardBorder,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.all(padding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(snapshot: snapshot, fpsColor: fpsColor),
              AnimatedSize(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: _isExpanded
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 10),
                          _buildMetricRow(
                            icon: Icons.speed_rounded,
                            label: 'Aktualny FPS',
                            value: '${snapshot.fps.round()} FPS',
                            accentColor: fpsColor,
                            trailingBadge: 'cel ${snapshot.targetFps}',
                          ),
                          const SizedBox(height: 6),
                          _buildMetricRow(
                            icon: Icons.timer_outlined,
                            label: 'Render ramki',
                            value:
                                '${snapshot.frameRenderTimeMs.toStringAsFixed(1)} ms',
                            accentColor: frameColor,
                            trailingBadge: _peakFrameMs > 0
                                ? 'szczyt ${_peakFrameMs.toStringAsFixed(1)}'
                                : null,
                          ),
                          const SizedBox(height: 6),
                          _buildMetricRow(
                            icon: Icons.memory_rounded,
                            label: 'Fizyka Isolate',
                            value:
                                '${snapshot.isolatePhysicsStepMs.toStringAsFixed(2)} ms',
                            accentColor: isolateColor,
                            trailingBadge: snapshot.isSimulationActive
                                ? 'AKTYWNA'
                                : 'IDLE',
                          ),
                          const SizedBox(height: 6),
                          _buildMetricRow(
                            icon: Icons.change_history_rounded,
                            label: 'Wielokąty 3D',
                            value: _formatPolygons(snapshot.visiblePolygons3d),
                            accentColor: polyColor,
                          ),
                          const SizedBox(height: 6),
                          _buildMetricRow(
                            icon: Icons.sd_storage_outlined,
                            label: 'Pamięć RAM',
                            value: '${snapshot.ramUsageMb.toStringAsFixed(1)} MB',
                            accentColor: ramColor,
                          ),
                          const SizedBox(height: 10),
                          _buildFrameHistoryBar(snapshot.targetFps),
                        ],
                      )
                    : Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: _buildCompactSummary(
                          snapshot: snapshot,
                          fpsColor: fpsColor,
                          isolateColor: isolateColor,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader({
    required SimulationTelemetrySnapshot snapshot,
    required Color fpsColor,
  }) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isPaused ? AppColors.amberWarning : fpsColor,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            _isPaused ? 'TELEMETRIA (PAUZA)' : 'TELEMETRIA 3D',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 4),
        _TelemetryIconButton(
          tooltip: _isPaused ? 'Wznów pomiar' : 'Wstrzymaj pomiar',
          icon: _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
          isActive: _isPaused,
          enabled: widget.isInteractive,
          onPressed: _togglePaused,
        ),
        const SizedBox(width: 4),
        _TelemetryIconButton(
          tooltip: 'Resetuj szczyt ramki',
          icon: Icons.refresh_rounded,
          enabled: widget.isInteractive && _peakFrameMs > 0.0,
          onPressed: _resetPeak,
        ),
        const SizedBox(width: 4),
        _TelemetryIconButton(
          tooltip: 'Zmień narożnik',
          icon: Icons.open_with_rounded,
          enabled: widget.isInteractive,
          onPressed: _cycleCorner,
        ),
        const SizedBox(width: 4),
        _TelemetryIconButton(
          tooltip: _isExpanded ? 'Zwiń panel' : 'Rozwiń panel',
          icon: _isExpanded
              ? Icons.keyboard_arrow_up_rounded
              : Icons.keyboard_arrow_down_rounded,
          enabled: widget.isInteractive,
          onPressed: _toggleExpanded,
        ),
        if (widget.onClose != null) ...[
          const SizedBox(width: 4),
          _TelemetryIconButton(
            tooltip: 'Ukryj licznik',
            icon: Icons.close_rounded,
            enabled: widget.isInteractive,
            onPressed: widget.onClose,
          ),
        ],
      ],
    );
  }

  Widget _buildCompactSummary({
    required SimulationTelemetrySnapshot snapshot,
    required Color fpsColor,
    required Color isolateColor,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '${snapshot.fps.round()} FPS · ${snapshot.frameRenderTimeMs.toStringAsFixed(1)} ms',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: fpsColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'ISO ${snapshot.isolatePhysicsStepMs.toStringAsFixed(1)}ms',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isolateColor,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricRow({
    required IconData icon,
    required String label,
    required String value,
    required Color accentColor,
    String? trailingBadge,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.cardBorder.withValues(alpha: 0.8),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: accentColor),
          const SizedBox(width: 6),
          Expanded(
            flex: 3,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.2,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          if (trailingBadge != null) ...[
            const SizedBox(width: 4),
            Flexible(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.cardBorder, width: 0.8),
                ),
                child: Text(
                  trailingBadge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(width: 6),
          Flexible(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: accentColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrameHistoryBar(int targetFps) {
    final samples = _frameHistoryMs.toList(growable: false);
    final budgetMs = 1000.0 / (targetFps <= 0 ? 60 : targetFps);

    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: CustomPaint(
        painter: _FrameHistorySparklinePainter(
          samplesMs: samples,
          budgetMs: budgetMs,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }

  String _formatPolygons(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000.0).toStringAsFixed(2)}M';
    }
    if (count >= 1000) {
      return '${(count / 1000.0).toStringAsFixed(1)}k';
    }
    return '$count';
  }

  Color _fpsStatusColor(double fps, int targetFps) {
    final effectiveTarget = targetFps <= 0 ? 60 : targetFps;
    if (fps >= effectiveTarget * 0.9) return AppColors.statusSuccess;
    if (fps >= effectiveTarget * 0.55) return AppColors.amberWarning;
    return AppColors.crimsonAlert;
  }

  Color _frameTimeColor(double frameMs, int targetFps) {
    final budgetMs = 1000.0 / (targetFps <= 0 ? 60 : targetFps);
    if (frameMs <= budgetMs) return AppColors.cyanAccent;
    if (frameMs <= budgetMs * 1.5) return AppColors.amberWarning;
    return AppColors.crimsonAlert;
  }

  Color _isolateTimeColor(double isolateMs) {
    if (isolateMs <= 4.0) return AppColors.accentBlue;
    if (isolateMs <= 10.0) return AppColors.amberWarning;
    return AppColors.crimsonAlert;
  }

  Color _polygonCountColor(int polygons) {
    if (polygons <= 120000) return AppColors.textPrimary;
    if (polygons <= 250000) return AppColors.amberWarning;
    return AppColors.crimsonAlert;
  }

  Color _ramUsageColor(double ramMb) {
    if (ramMb <= 1024.0) return AppColors.goldAccent;
    if (ramMb <= 2048.0) return AppColors.amberWarning;
    return AppColors.crimsonAlert;
  }
}

class _TelemetryIconButton extends StatefulWidget {
  final String tooltip;
  final IconData icon;
  final bool enabled;
  final bool isActive;
  final VoidCallback? onPressed;

  const _TelemetryIconButton({
    required this.tooltip,
    required this.icon,
    required this.enabled,
    this.isActive = false,
    this.onPressed,
  });

  @override
  State<_TelemetryIconButton> createState() => _TelemetryIconButtonState();
}

class _TelemetryIconButtonState extends State<_TelemetryIconButton> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isInteractive = widget.enabled && widget.onPressed != null;

    final Color bgColor;
    if (!isInteractive) {
      bgColor = AppColors.surfaceLight.withValues(alpha: 0.35);
    } else if (_isPressed || widget.isActive) {
      bgColor = AppColors.primaryAccent.withValues(alpha: 0.35);
    } else if (_isHovered) {
      bgColor = AppColors.surfaceLight;
    } else {
      bgColor = AppColors.background.withValues(alpha: 0.7);
    }

    final Color borderColor;
    if (!isInteractive) {
      borderColor = AppColors.cardBorder.withValues(alpha: 0.45);
    } else if (_isFocused) {
      borderColor = AppColors.goldAccent;
    } else if (_isPressed || widget.isActive) {
      borderColor = AppColors.primaryAccent;
    } else if (_isHovered) {
      borderColor = AppColors.accentBlue.withValues(alpha: 0.7);
    } else {
      borderColor = AppColors.cardBorder;
    }

    final Color iconColor;
    if (!isInteractive) {
      iconColor = AppColors.textSecondary.withValues(alpha: 0.4);
    } else if (widget.isActive) {
      iconColor = AppColors.goldAccent;
    } else if (_isHovered || _isFocused) {
      iconColor = AppColors.textPrimary;
    } else {
      iconColor = AppColors.textSecondary;
    }

    return Tooltip(
      message: widget.tooltip,
      child: FocusableActionDetector(
        enabled: isInteractive,
        onShowFocusHighlight: (focused) => setState(() => _isFocused = focused),
        onShowHoverHighlight: (hovered) => setState(() => _isHovered = hovered),
        shortcuts: const <ShortcutActivator, Intent>{},
        child: GestureDetector(
          onTapDown: isInteractive
              ? (_) => setState(() => _isPressed = true)
              : null,
          onTapUp: isInteractive
              ? (_) => setState(() => _isPressed = false)
              : null,
          onTapCancel: isInteractive
              ? () => setState(() => _isPressed = false)
              : null,
          onTap: isInteractive ? widget.onPressed : null,
          child: AnimatedScale(
            scale: _isPressed && isInteractive ? 0.92 : 1.0,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: borderColor,
                  width: _isFocused ? 1.5 : 1.0,
                ),
              ),
              child: Icon(
                widget.icon,
                size: 14,
                color: iconColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FrameHistorySparklinePainter extends CustomPainter {
  final List<double> samplesMs;
  final double budgetMs;

  const _FrameHistorySparklinePainter({
    required this.samplesMs,
    required this.budgetMs,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final maxScaleMs = math.max(budgetMs * 2.0, 20.0);
    final budgetY =
        size.height - (budgetMs / maxScaleMs).clamp(0.0, 1.0) * size.height;

    final budgetPaint = Paint()
      ..color = AppColors.goldAccent.withValues(alpha: 0.45)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(0, budgetY),
      Offset(size.width, budgetY),
      budgetPaint,
    );

    if (samplesMs.isEmpty) return;

    const slots = 24;
    const barGap = 2.0;
    final barWidth = math.max(
      1.5,
      (size.width - (slots - 1) * barGap) / slots,
    );

    final startOffset = slots - samplesMs.length;
    for (int i = 0; i < samplesMs.length; i++) {
      final valueMs = samplesMs[i];
      final normalized = (valueMs / maxScaleMs).clamp(0.08, 1.0);
      final barHeight = normalized * size.height;
      final x = (startOffset + i) * (barWidth + barGap);
      final y = size.height - barHeight;

      final Color barColor;
      if (valueMs <= budgetMs) {
        barColor = AppColors.statusSuccess;
      } else if (valueMs <= budgetMs * 1.5) {
        barColor = AppColors.amberWarning;
      } else {
        barColor = AppColors.crimsonAlert;
      }

      final paint = Paint()..color = barColor.withValues(alpha: 0.9);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, barHeight),
          const Radius.circular(1.5),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FrameHistorySparklinePainter oldDelegate) {
    if (oldDelegate.budgetMs != budgetMs ||
        oldDelegate.samplesMs.length != samplesMs.length) {
      return true;
    }
    for (int i = 0; i < samplesMs.length; i++) {
      if (oldDelegate.samplesMs[i] != samplesMs[i]) return true;
    }
    return false;
  }
}
