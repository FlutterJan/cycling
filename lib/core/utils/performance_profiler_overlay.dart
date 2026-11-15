import 'dart:collection';
import 'dart:io' show Platform, ProcessInfo;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/game_settings_notifier.dart';
import '../theme/app_colors.dart';

/// Zestaw metryk wydajnościowych silnika symulacji kolarskiej i renderera 3D.
@immutable
class EnginePerformanceMetrics {
  /// Czas przeliczenia 1 ticku fizyki w wątku Isolate [µs].
  final int physicsTickMicroseconds;

  /// Liczba kolarzy symulowanych w ostatnim ticku (domyślnie 176 w peletonie).
  final int simulatedRidersCount;

  /// Czy symulacja wyścigu w Isolate jest aktualnie aktywna.
  final bool isSimulationActive;

  /// Liczba aktywnych obiektów 3D w kamerze na poziomie szczegółowości LOD 0 (<30 m).
  final int lod0Count;

  /// Liczba aktywnych obiektów 3D w kamerze na poziomie szczegółowości LOD 1 (30–100 m).
  final int lod1Count;

  /// Liczba aktywnych obiektów 3D w kamerze na poziomie szczegółowości LOD 2 (>100 m).
  final int lod2Count;

  /// Liczba obiektów odrzuconych przez Frustum Culling kamery.
  final int culledCount;

  const EnginePerformanceMetrics({
    this.physicsTickMicroseconds = 0,
    this.simulatedRidersCount = 0,
    this.isSimulationActive = false,
    this.lod0Count = 0,
    this.lod1Count = 0,
    this.lod2Count = 0,
    this.culledCount = 0,
  });

  int get totalVisible3dObjects => lod0Count + lod1Count + lod2Count;

  EnginePerformanceMetrics copyWith({
    int? physicsTickMicroseconds,
    int? simulatedRidersCount,
    bool? isSimulationActive,
    int? lod0Count,
    int? lod1Count,
    int? lod2Count,
    int? culledCount,
  }) {
    return EnginePerformanceMetrics(
      physicsTickMicroseconds:
          physicsTickMicroseconds ?? this.physicsTickMicroseconds,
      simulatedRidersCount: simulatedRidersCount ?? this.simulatedRidersCount,
      isSimulationActive: isSimulationActive ?? this.isSimulationActive,
      lod0Count: lod0Count ?? this.lod0Count,
      lod1Count: lod1Count ?? this.lod1Count,
      lod2Count: lod2Count ?? this.lod2Count,
      culledCount: culledCount ?? this.culledCount,
    );
  }
}

/// Globalny rejestr telemetrii wydajnościowej łączący wątek Isolate fizyki
/// oraz renderer 3D z nakładką diagnostyczną [PerformanceProfilerOverlay].
class PerformanceTelemetryRegistry {
  PerformanceTelemetryRegistry._();

  static final PerformanceTelemetryRegistry instance =
      PerformanceTelemetryRegistry._();

  final ValueNotifier<EnginePerformanceMetrics> metrics =
      ValueNotifier<EnginePerformanceMetrics>(const EnginePerformanceMetrics());

  /// Aktualizuje czas przeliczenia ticku fizyki w wątku Isolate [µs].
  void updatePhysicsTick({
    required int microseconds,
    required int riderCount,
    bool isActive = true,
  }) {
    metrics.value = metrics.value.copyWith(
      physicsTickMicroseconds: microseconds < 0 ? 0 : microseconds,
      simulatedRidersCount: riderCount < 0 ? 0 : riderCount,
      isSimulationActive: isActive,
    );
  }

  /// Oznacza zakończenie lub zatrzymanie pętli symulacji.
  void clearSimulationActivity() {
    metrics.value = metrics.value.copyWith(
      isSimulationActive: false,
    );
  }

  /// Aktualizuje statystyki aktywnych obiektów 3D w kamerze (LOD0 / LOD1 / LOD2).
  void updateLodStats({
    required int lod0,
    required int lod1,
    required int lod2,
    int culled = 0,
  }) {
    metrics.value = metrics.value.copyWith(
      lod0Count: lod0 < 0 ? 0 : lod0,
      lod1Count: lod1 < 0 ? 0 : lod1,
      lod2Count: lod2 < 0 ? 0 : lod2,
      culledCount: culled < 0 ? 0 : culled,
    );
  }

  /// Resetuje wszystkie liczniki telemetrii silnika.
  void reset() {
    metrics.value = const EnginePerformanceMetrics();
  }
}

/// Próbka czasu pojedynczej klatki renderera Flutter.
@immutable
class FrameTimingSample {
  final double buildMs;
  final double rasterMs;
  final double totalMs;

  const FrameTimingSample({
    required this.buildMs,
    required this.rasterMs,
    required this.totalMs,
  });
}

/// Profesjonalna nakładka diagnostyczna wyświetlana w prawym górnym rogu ekranu.
///
/// Włączana skrótem klawiszowym `F3` (Windows/macOS/Linux) lub przełącznikiem
/// `showFpsCounter` w ustawieniach aplikacji. Mierzy w czasie rzeczywistym:
/// - FPS, czas budowania UI (`Build ms`) i czas rasteryzacji GPU (`Raster ms`)
///   przez `SchedulerBinding.instance.addTimingsCallback`,
/// - wykres słupkowy ostatnich 60 klatek z progami budżetu 8.33 ms (120 Hz)
///   oraz 16.67 ms (60 Hz),
/// - czas ticku fizyki 176 kolarzy w `Isolate` (µs), liczbę obiektów 3D w kamerze
///   (LOD0 / LOD1 / LOD2) oraz zużycie pamięci RAM procesu.
class PerformanceProfilerOverlay extends ConsumerStatefulWidget {
  final Widget child;

  /// Opcjonalny tryb testowy wymuszający widoczność niezależnie od ustawień.
  final bool? forceVisible;

  const PerformanceProfilerOverlay({
    super.key,
    required this.child,
    this.forceVisible,
  });

  @override
  ConsumerState<PerformanceProfilerOverlay> createState() =>
      _PerformanceProfilerOverlayState();
}

class _PerformanceProfilerOverlayState
    extends ConsumerState<PerformanceProfilerOverlay>
    with SingleTickerProviderStateMixin {
  static const int _maxSamples = 60;
  static const double _budget120HzMs = 8.33;
  static const double _budget60HzMs = 16.67;

  final ListQueue<FrameTimingSample> _samples = ListQueue<FrameTimingSample>();
  final ListQueue<int> _frameTimestampsUs = ListQueue<int>();

  double _currentFps = 60.0;
  double _lastBuildMs = 0.0;
  double _lastRasterMs = 0.0;
  double _peakTotalMs = 0.0;
  double _processRssMb = 0.0;
  int _lastRssCheckMs = 0;

  bool _isPaused = false;
  bool _isCollapsed = false;
  bool _timingsRegistered = false;
  bool _hardwareKeyRegistered = false;

  late final AnimationController _visibilityAnimController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _visibilityAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..addStatusListener((status) {
        if (status == AnimationStatus.dismissed && mounted) {
          setState(() {});
        }
      });
    _fadeAnimation = CurvedAnimation(
      parent: _visibilityAnimController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.06, -0.04),
      end: Offset.zero,
    ).animate(_fadeAnimation);

    _refreshProcessMemory(force: true);
    _registerGlobalF3Handler();

    final initialVisible =
        widget.forceVisible ?? ref.read(gameSettingsProvider).showFpsCounter;
    if (initialVisible) {
      _visibilityAnimController.value = 1.0;
      _setTimingsActive(true);
    }
  }

  @override
  void didUpdateWidget(covariant PerformanceProfilerOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.forceVisible != oldWidget.forceVisible &&
        widget.forceVisible != null) {
      _syncVisibility(widget.forceVisible!);
    }
  }

  void _registerGlobalF3Handler() {
    if (_hardwareKeyRegistered) return;
    if (_supportsDesktopF3Shortcut) {
      HardwareKeyboard.instance.addHandler(_handleHardwareKey);
      _hardwareKeyRegistered = true;
    }
  }

  bool get _supportsDesktopF3Shortcut {
    if (kIsWeb) return false;
    try {
      return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
    } catch (_) {
      return false;
    }
  }

  bool _handleHardwareKey(KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.f3 &&
        !HardwareKeyboard.instance.isAltPressed &&
        !HardwareKeyboard.instance.isControlPressed &&
        !HardwareKeyboard.instance.isMetaPressed) {
      _toggleOverlayVisibility();
      return true;
    }
    return false;
  }

  void _toggleOverlayVisibility() {
    if (!mounted) return;
    final current = ref.read(gameSettingsProvider).showFpsCounter;
    ref.read(gameSettingsProvider.notifier).setShowFpsCounter(!current);
  }

  void _syncVisibility(bool visible) {
    if (visible) {
      _refreshProcessMemory(force: true);
      _setTimingsActive(true);
      _visibilityAnimController.forward();
    } else {
      _setTimingsActive(false);
      _visibilityAnimController.reverse();
    }
  }

  void _setTimingsActive(bool active) {
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
      final totalSpanMs = timing.totalSpan.inMicroseconds / 1000.0;
      final effectiveTotalMs = math.max(totalSpanMs, buildMs + rasterMs);

      _lastBuildMs = buildMs;
      _lastRasterMs = rasterMs;
      if (effectiveTotalMs > _peakTotalMs) {
        _peakTotalMs = effectiveTotalMs;
      }

      _samples.addLast(
        FrameTimingSample(
          buildMs: buildMs,
          rasterMs: rasterMs,
          totalMs: effectiveTotalMs,
        ),
      );
      while (_samples.length > _maxSamples) {
        _samples.removeFirst();
      }

      _frameTimestampsUs.addLast(nowUs);
    }

    // Okno kroczące 1.0 s dla stabilnego odczytu rzeczywistych klatek na sekundę
    final cutoffUs = nowUs - 1000000;
    while (_frameTimestampsUs.isNotEmpty &&
        _frameTimestampsUs.first < cutoffUs) {
      _frameTimestampsUs.removeFirst();
    }

    if (_frameTimestampsUs.length >= 2) {
      final spanUs = _frameTimestampsUs.last - _frameTimestampsUs.first;
      if (spanUs > 0) {
        final measuredFps =
            ((_frameTimestampsUs.length - 1) * 1000000.0) / spanUs;
        _currentFps = measuredFps.clamp(1.0, 240.0);
      }
    } else if (_samples.isNotEmpty && _samples.last.totalMs > 0) {
      _currentFps = (1000.0 / _samples.last.totalMs).clamp(1.0, 240.0);
    }

    _refreshProcessMemory();

    if (mounted) {
      setState(() {});
    }
  }

  void _refreshProcessMemory({bool force = false}) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (!force && nowMs - _lastRssCheckMs < 500) return;
    _lastRssCheckMs = nowMs;

    if (kIsWeb) {
      _processRssMb = 0.0;
      return;
    }

    try {
      _processRssMb = ProcessInfo.currentRss / (1024.0 * 1024.0);
    } catch (_) {
      _processRssMb = 0.0;
    }
  }

  void _resetStats() {
    setState(() {
      _samples.clear();
      _frameTimestampsUs.clear();
      _peakTotalMs = 0.0;
      _lastBuildMs = 0.0;
      _lastRasterMs = 0.0;
    });
  }

  Color _fpsColor(double fps) {
    if (fps >= 60.0) return AppColors.statusSuccess;
    if (fps >= 30.0) return AppColors.amberWarning;
    return AppColors.crimsonAlert;
  }

  @override
  void dispose() {
    _setTimingsActive(false);
    if (_hardwareKeyRegistered) {
      HardwareKeyboard.instance.removeHandler(_handleHardwareKey);
      _hardwareKeyRegistered = false;
    }
    _visibilityAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsVisible = ref.watch(
      gameSettingsProvider.select((s) => s.showFpsCounter),
    );
    final isVisible = widget.forceVisible ?? settingsVisible;

    ref.listen<bool>(
      gameSettingsProvider.select((s) => s.showFpsCounter),
      (previous, next) {
        if (widget.forceVisible == null && previous != next) {
          _syncVisibility(next);
        }
      },
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (isVisible || _visibilityAnimController.isAnimating)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !isVisible,
              child: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 600;
                    final panelWidth = _isCollapsed
                        ? (isCompact ? 168.0 : 188.0)
                        : (isCompact
                            ? math.min(276.0, constraints.maxWidth - 20.0)
                            : 328.0);
                    final edgeInset = isCompact ? 10.0 : 16.0;

                    return Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: edgeInset,
                          right: edgeInset,
                        ),
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: Material(
                              color: Colors.transparent,
                              child: Container(
                                width: panelWidth,
                                constraints: BoxConstraints(
                                  maxHeight: math.max(
                                    120.0,
                                    constraints.maxHeight - edgeInset * 2,
                                  ),
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.surface.withValues(alpha: 0.94),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFF2A2F3D),
                                    width: 1.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.45),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: AnimatedSize(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOutCubic,
                                  alignment: Alignment.topRight,
                                  child: SingleChildScrollView(
                                    padding: EdgeInsets.all(isCompact ? 10 : 12),
                                    child: _buildPanelContent(isCompact),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPanelContent(bool isCompact) {
    final fpsInt = _currentFps.round();
    final fpsColor = _fpsColor(_currentFps);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeaderRow(fpsInt, fpsColor, isCompact),
        if (!_isCollapsed) ...[
          const SizedBox(height: 10),
          _buildTimingMetricsRow(isCompact),
          const SizedBox(height: 10),
          _buildFrameGraphSection(isCompact),
          const SizedBox(height: 10),
          _buildEngineTelemetrySection(isCompact),
        ],
      ],
    );
  }

  Widget _buildHeaderRow(int fpsInt, Color fpsColor, bool isCompact) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _isPaused ? AppColors.textSecondary : fpsColor,
            shape: BoxShape.circle,
            boxShadow: _isPaused
                ? null
                : [
                    BoxShadow(
                      color: fpsColor.withValues(alpha: 0.55),
                      blurRadius: 6,
                    ),
                  ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  '$fpsInt FPS',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: isCompact ? 15 : 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: fpsColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              if (!_isCollapsed) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF2A2F3D)),
                  ),
                  child: const Text(
                    'F3',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 6),
        if (!_isCollapsed) ...[
          _ProfilerIconButton(
            icon: _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            tooltip: _isPaused ? 'Wznów próbkowanie' : 'Wstrzymaj próbkowanie',
            isActive: _isPaused,
            onPressed: () => setState(() => _isPaused = !_isPaused),
          ),
          const SizedBox(width: 4),
          _ProfilerIconButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Resetuj szczyty',
            enabled: _samples.isNotEmpty || _peakTotalMs > 0,
            onPressed: _resetStats,
          ),
          const SizedBox(width: 4),
        ],
        _ProfilerIconButton(
          icon: _isCollapsed
              ? Icons.unfold_more_rounded
              : Icons.unfold_less_rounded,
          tooltip: _isCollapsed ? 'Rozwiń profiler' : 'Zwiń do pigułki FPS',
          onPressed: () => setState(() => _isCollapsed = !_isCollapsed),
        ),
        if (widget.forceVisible == null) ...[
          const SizedBox(width: 4),
          _ProfilerIconButton(
            icon: Icons.close_rounded,
            tooltip: 'Zamknij profiler (F3)',
            onPressed: _toggleOverlayVisibility,
          ),
        ],
      ],
    );
  }

  Widget _buildTimingMetricsRow(bool isCompact) {
    return Row(
      children: [
        Expanded(
          child: _MetricTile(
            label: 'BUILD',
            value: '${_lastBuildMs.toStringAsFixed(2)} ms',
            accent: AppColors.accentBlue,
            isCompact: isCompact,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _MetricTile(
            label: 'RASTER',
            value: '${_lastRasterMs.toStringAsFixed(2)} ms',
            accent: AppColors.goldAccent,
            isCompact: isCompact,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _MetricTile(
            label: 'PEAK',
            value: '${_peakTotalMs.toStringAsFixed(1)} ms',
            accent: _peakTotalMs > _budget60HzMs
                ? AppColors.crimsonAlert
                : AppColors.textPrimary,
            isCompact: isCompact,
          ),
        ),
      ],
    );
  }

  Widget _buildFrameGraphSection(bool isCompact) {
    final samplesList = _samples.toList(growable: false);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'FRAME TIME GRAPH (60 KLATEK)',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              _LegendDot(
                color: AppColors.accentBlue,
                label: 'UI',
              ),
              SizedBox(width: 8),
              _LegendDot(
                color: AppColors.goldAccent,
                label: 'GPU',
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: isCompact ? 64 : 76,
            child: CustomPaint(
              painter: _FrameTimeGraphPainter(
                samples: samplesList,
                maxSamples: _maxSamples,
                budget120HzMs: _budget120HzMs,
                budget60HzMs: _budget60HzMs,
              ),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  '120 Hz: ${_budget120HzMs.toStringAsFixed(2)} ms',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.2,
                    color: AppColors.cyanAccent,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '60 Hz: ${_budget60HzMs.toStringAsFixed(2)} ms',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.2,
                    color: AppColors.amberWarning,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEngineTelemetrySection(bool isCompact) {
    return ValueListenableBuilder<EnginePerformanceMetrics>(
      valueListenable: PerformanceTelemetryRegistry.instance.metrics,
      builder: (context, engine, _) {
        final ridersLabel = engine.simulatedRidersCount > 0
            ? engine.simulatedRidersCount
            : 176;
        final tickText = engine.isSimulationActive ||
                engine.physicsTickMicroseconds > 0
            ? '${engine.physicsTickMicroseconds} µs'
            : 'Standby';
        final tickColor = engine.physicsTickMicroseconds > 8000
            ? AppColors.amberWarning
            : AppColors.statusSuccess;

        final ramText = _processRssMb > 0
            ? '${_processRssMb.toStringAsFixed(1)} MB'
            : 'N/A';

        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2A2F3D)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'TELEMETRIA SILNIKA & 3D',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              _TelemetryRow(
                label: 'Isolate ($ridersLabel kolarzy)',
                value: tickText,
                valueColor: engine.isSimulationActive ||
                        engine.physicsTickMicroseconds > 0
                    ? tickColor
                    : AppColors.textSecondary,
              ),
              const SizedBox(height: 4),
              _TelemetryRow(
                label: 'Obiekty 3D (LOD0/1/2)',
                value:
                    '${engine.lod0Count} / ${engine.lod1Count} / ${engine.lod2Count}',
                valueColor: AppColors.textPrimary,
              ),
              const SizedBox(height: 4),
              _TelemetryRow(
                label: 'Pamięć RAM procesu',
                value: ramText,
                valueColor: AppColors.cyanAccent,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  final bool isCompact;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.accent,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 8,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: isCompact ? 11 : 12,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: accent,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _TelemetryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _TelemetryRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
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
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: valueColor,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ProfilerIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool enabled;
  final bool isActive;

  const _ProfilerIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.enabled = true,
    this.isActive = false,
  });

  @override
  State<_ProfilerIconButton> createState() => _ProfilerIconButtonState();
}

class _ProfilerIconButtonState extends State<_ProfilerIconButton> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool interactive = widget.enabled && widget.onPressed != null;

    Color background = AppColors.surfaceLight;
    if (!interactive) {
      background = AppColors.surfaceLight.withValues(alpha: 0.4);
    } else if (_isPressed) {
      background = AppColors.primaryAccent.withValues(alpha: 0.35);
    } else if (widget.isActive) {
      background = AppColors.primaryAccent.withValues(alpha: 0.25);
    } else if (_isHovered) {
      background = const Color(0xFF2B3140);
    }

    final Color borderColor = _isFocused
        ? AppColors.goldAccent
        : (widget.isActive
            ? AppColors.primaryAccent
            : const Color(0xFF2A2F3D));

    final Color iconColor = !interactive
        ? AppColors.textSecondary.withValues(alpha: 0.38)
        : (widget.isActive
            ? AppColors.goldAccent
            : (_isHovered ? AppColors.textPrimary : AppColors.textSecondary));

    return Tooltip(
      message: widget.tooltip,
      child: FocusableActionDetector(
        enabled: interactive,
        mouseCursor:
            interactive ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onShowHoverHighlight: (hovered) => setState(() => _isHovered = hovered),
        onShowFocusHighlight: (focused) => setState(() => _isFocused = focused),
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              if (interactive) widget.onPressed?.call();
              return null;
            },
          ),
        },
        child: GestureDetector(
          onTapDown:
              interactive ? (_) => setState(() => _isPressed = true) : null,
          onTapUp:
              interactive ? (_) => setState(() => _isPressed = false) : null,
          onTapCancel:
              interactive ? () => setState(() => _isPressed = false) : null,
          onTap: interactive ? widget.onPressed : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Icon(
              widget.icon,
              size: 14,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _FrameTimeGraphPainter extends CustomPainter {
  final List<FrameTimingSample> samples;
  final int maxSamples;
  final double budget120HzMs;
  final double budget60HzMs;

  const _FrameTimeGraphPainter({
    required this.samples,
    required this.maxSamples,
    required this.budget120HzMs,
    required this.budget60HzMs,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    const double maxAxisMs = 24.0;
    final double barSlotWidth = size.width / maxSamples;
    final double barWidth = math.max(1.5, barSlotWidth - 1.2);

    // Siatka tła
    final gridPaint = Paint()
      ..color = const Color(0xFF2A2F3D).withValues(alpha: 0.45)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(0, size.height * 0.5),
      Offset(size.width, size.height * 0.5),
      gridPaint,
    );

    // Słupki ostatnich 60 klatek (wyrównane do prawej krawędzi)
    final int offsetSlots = maxSamples - samples.length;
    final buildPaint = Paint()..style = PaintingStyle.fill;
    final rasterPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < samples.length; i++) {
      final sample = samples[i];
      final double x = (offsetSlots + i) * barSlotWidth;

      final double clampedBuild = sample.buildMs.clamp(0.0, maxAxisMs);
      final double clampedRaster =
          sample.rasterMs.clamp(0.0, maxAxisMs - clampedBuild);

      final double buildHeight = (clampedBuild / maxAxisMs) * size.height;
      final double rasterHeight = (clampedRaster / maxAxisMs) * size.height;

      final bool isOverBudget = sample.totalMs > budget60HzMs;
      buildPaint.color =
          isOverBudget ? AppColors.crimsonAlert : AppColors.accentBlue;
      rasterPaint.color = isOverBudget
          ? AppColors.crimsonAlert.withValues(alpha: 0.72)
          : AppColors.goldAccent;

      if (buildHeight > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              x,
              size.height - buildHeight,
              barWidth,
              buildHeight,
            ),
            const Radius.circular(1),
          ),
          buildPaint,
        );
      }

      if (rasterHeight > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              x,
              size.height - buildHeight - rasterHeight,
              barWidth,
              rasterHeight,
            ),
            const Radius.circular(1),
          ),
          rasterPaint,
        );
      }
    }

    // Linie budżetu klatki: 8.33 ms (120 Hz) i 16.67 ms (60 Hz)
    _drawDashedHorizontalLine(
      canvas: canvas,
      size: size,
      y: size.height - (budget120HzMs / maxAxisMs) * size.height,
      color: AppColors.cyanAccent.withValues(alpha: 0.85),
    );
    _drawDashedHorizontalLine(
      canvas: canvas,
      size: size,
      y: size.height - (budget60HzMs / maxAxisMs) * size.height,
      color: AppColors.amberWarning.withValues(alpha: 0.85),
    );
  }

  void _drawDashedHorizontalLine({
    required Canvas canvas,
    required Size size,
    required double y,
    required Color color,
  }) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    const double dashWidth = 4.0;
    const double dashSpace = 3.0;
    double x = 0.0;
    while (x < size.width) {
      final double endX = math.min(x + dashWidth, size.width);
      canvas.drawLine(Offset(x, y), Offset(endX, y), paint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _FrameTimeGraphPainter oldDelegate) {
    return oldDelegate.samples != samples ||
        oldDelegate.maxSamples != maxSamples ||
        oldDelegate.budget120HzMs != budget120HzMs ||
        oldDelegate.budget60HzMs != budget60HzMs;
  }
}
