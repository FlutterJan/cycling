import 'dart:math' as math;
import 'dart:ui' show FontFeature, FrameTiming;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/settings/game_settings.dart';
import '../../state/game_settings_notifier.dart';
import '../theme/app_colors.dart';

/// Wykryta platforma sprzętowa dla profilera graficznego.
enum AdaptiveGraphicsPlatform {
  windows('Windows Desktop', true, false),
  macOS('macOS Desktop', true, false),
  iOS('iOS Mobile', false, true),
  android('Android Mobile', false, true),
  linux('Linux Desktop', true, false),
  web('Web Browser', false, false),
  other('Inna Platforma', false, false);

  final String displayName;
  final bool isDesktop;
  final bool isMobile;

  const AdaptiveGraphicsPlatform(
    this.displayName,
    this.isDesktop,
    this.isMobile,
  );

  static AdaptiveGraphicsPlatform fromTargetPlatform(
    TargetPlatform platform, {
    bool isWeb = false,
  }) {
    if (isWeb) return AdaptiveGraphicsPlatform.web;
    switch (platform) {
      case TargetPlatform.windows:
        return AdaptiveGraphicsPlatform.windows;
      case TargetPlatform.macOS:
        return AdaptiveGraphicsPlatform.macOS;
      case TargetPlatform.iOS:
        return AdaptiveGraphicsPlatform.iOS;
      case TargetPlatform.android:
        return AdaptiveGraphicsPlatform.android;
      case TargetPlatform.linux:
        return AdaptiveGraphicsPlatform.linux;
      case TargetPlatform.fuchsia:
        return AdaptiveGraphicsPlatform.other;
    }
  }

  static AdaptiveGraphicsPlatform fromJson(String value) {
    return AdaptiveGraphicsPlatform.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => AdaptiveGraphicsPlatform.other,
    );
  }
}

/// Docelowy preset profilera adaptacyjnego z mapowaniem na [GraphicsPreset].
enum AdaptiveGraphicsProfilePreset {
  ultra120FpsDesktop(
    id: 'ultra_120_fps_desktop',
    label: 'Ultra 120 FPS Desktop',
    shortLabel: 'Ultra 120 FPS',
    description:
        'Maksymalna płynność 120 FPS, miękkie cienie Gaussa, gęste tłumy Alpe d\'Huez i pełne cząsteczki 3D.',
    targetFps: 120,
    gamePreset: GraphicsPreset.ultraMacPc,
    badgeColor: AppColors.goldAccent,
  ),
  high60FpsTablet(
    id: 'high_60_fps_tablet',
    label: 'High 60 FPS Tablet',
    shortLabel: 'High 60 FPS',
    description:
        'Stabilne 60 FPS, wysokie cienie dynamiczne, pełna gęstość kibiców i wysoki poziom detali LOD.',
    targetFps: 60,
    gamePreset: GraphicsPreset.highQuality,
    badgeColor: AppColors.accentBlue,
  ),
  balancedMobileBatterySaver(
    id: 'balanced_mobile_battery_saver',
    label: 'Balanced Mobile Battery Saver',
    shortLabel: 'Balanced Eco',
    description:
        'Zoptymalizowany pobór energii i niska temperatura GPU przy zachowaniu czytelnej symulacji peletonu.',
    targetFps: 30,
    gamePreset: GraphicsPreset.batterySaver,
    badgeColor: AppColors.statusSuccess,
  );

  final String id;
  final String label;
  final String shortLabel;
  final String description;
  final int targetFps;
  final GraphicsPreset gamePreset;
  final Color badgeColor;

  const AdaptiveGraphicsProfilePreset({
    required this.id,
    required this.label,
    required this.shortLabel,
    required this.description,
    required this.targetFps,
    required this.gamePreset,
    required this.badgeColor,
  });

  static AdaptiveGraphicsProfilePreset fromJson(String value) {
    return AdaptiveGraphicsProfilePreset.values.firstWhere(
      (e) =>
          e.name.toLowerCase() == value.toLowerCase() ||
          e.id.toLowerCase() == value.toLowerCase() ||
          e.label.toLowerCase() == value.toLowerCase(),
      orElse: () => AdaptiveGraphicsProfilePreset.high60FpsTablet,
    );
  }
}

/// Pojedyncza próbka czasu renderowania klatki podczas okna pomiarowego (1..30).
@immutable
class FrameTimingSample {
  final int frameIndex;
  final double buildDurationMs;
  final double rasterDurationMs;
  final double totalDurationMs;

  const FrameTimingSample({
    required this.frameIndex,
    required this.buildDurationMs,
    required this.rasterDurationMs,
    required this.totalDurationMs,
  });

  factory FrameTimingSample.fromFrameTiming(
    int frameIndex,
    FrameTiming timing,
  ) {
    final buildMs = timing.buildDuration.inMicroseconds / 1000.0;
    final rasterMs = timing.rasterDuration.inMicroseconds / 1000.0;
    final totalMs = timing.totalSpan.inMicroseconds / 1000.0;
    return FrameTimingSample(
      frameIndex: frameIndex,
      buildDurationMs: buildMs.clamp(0.0, 250.0),
      rasterDurationMs: rasterMs.clamp(0.0, 250.0),
      totalDurationMs: math.max(totalMs, buildMs + rasterMs).clamp(0.0, 250.0),
    );
  }

  factory FrameTimingSample.fromDuration(int frameIndex, Duration duration) {
    final totalMs = (duration.inMicroseconds / 1000.0).clamp(0.0, 250.0);
    return FrameTimingSample(
      frameIndex: frameIndex,
      buildDurationMs: totalMs * 0.45,
      rasterDurationMs: totalMs * 0.55,
      totalDurationMs: totalMs,
    );
  }

  Map<String, dynamic> toJson() => {
        'frameIndex': frameIndex,
        'buildDurationMs': buildDurationMs,
        'rasterDurationMs': rasterDurationMs,
        'totalDurationMs': totalDurationMs,
      };

  factory FrameTimingSample.fromJson(Map<String, dynamic> json) {
    return FrameTimingSample(
      frameIndex: (json['frameIndex'] as num?)?.toInt() ?? 1,
      buildDurationMs: (json['buildDurationMs'] as num?)?.toDouble() ?? 0.0,
      rasterDurationMs: (json['rasterDurationMs'] as num?)?.toDouble() ?? 0.0,
      totalDurationMs: (json['totalDurationMs'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Zbiorcze statystyki wydajności z pomiaru pierwszych 30 klatek.
@immutable
class GraphicsProfilerTelemetrySummary {
  final int collectedFrames;
  final int targetSampleCount;
  final double averageFrameTimeMs;
  final double p95FrameTimeMs;
  final double maxFrameTimeMs;
  final double estimatedFps;
  final int droppedFramesCount;
  final bool isProfilingComplete;

  const GraphicsProfilerTelemetrySummary({
    required this.collectedFrames,
    required this.targetSampleCount,
    required this.averageFrameTimeMs,
    required this.p95FrameTimeMs,
    required this.maxFrameTimeMs,
    required this.estimatedFps,
    required this.droppedFramesCount,
    required this.isProfilingComplete,
  });

  factory GraphicsProfilerTelemetrySummary.empty({
    int targetSampleCount = PlatformAdaptiveGraphicsProfiler.defaultSampleCount,
  }) {
    return GraphicsProfilerTelemetrySummary(
      collectedFrames: 0,
      targetSampleCount: targetSampleCount,
      averageFrameTimeMs: 0.0,
      p95FrameTimeMs: 0.0,
      maxFrameTimeMs: 0.0,
      estimatedFps: 0.0,
      droppedFramesCount: 0,
      isProfilingComplete: false,
    );
  }

  factory GraphicsProfilerTelemetrySummary.fromSamples(
    List<FrameTimingSample> samples, {
    int targetSampleCount = PlatformAdaptiveGraphicsProfiler.defaultSampleCount,
  }) {
    if (samples.isEmpty) {
      return GraphicsProfilerTelemetrySummary.empty(
        targetSampleCount: targetSampleCount,
      );
    }

    final durations = samples
        .map((s) => s.totalDurationMs)
        .where((ms) => ms.isFinite && ms >= 0.0)
        .toList()
      ..sort();

    if (durations.isEmpty) {
      return GraphicsProfilerTelemetrySummary.empty(
        targetSampleCount: targetSampleCount,
      );
    }

    final sum = durations.fold<double>(0.0, (acc, v) => acc + v);
    final avg = sum / durations.length;
    final p95Index = ((durations.length - 1) * 0.95).round().clamp(
          0,
          durations.length - 1,
        );
    final p95 = durations[p95Index];
    final maxMs = durations.last;
    final dropped = durations.where((ms) => ms > 16.67).length;
    final fps = avg > 0.1 ? (1000.0 / avg).clamp(1.0, 240.0) : 240.0;

    return GraphicsProfilerTelemetrySummary(
      collectedFrames: samples.length,
      targetSampleCount: targetSampleCount,
      averageFrameTimeMs: avg,
      p95FrameTimeMs: p95,
      maxFrameTimeMs: maxMs,
      estimatedFps: fps,
      droppedFramesCount: dropped,
      isProfilingComplete: samples.length >= targetSampleCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'collectedFrames': collectedFrames,
        'targetSampleCount': targetSampleCount,
        'averageFrameTimeMs': averageFrameTimeMs,
        'p95FrameTimeMs': p95FrameTimeMs,
        'maxFrameTimeMs': maxFrameTimeMs,
        'estimatedFps': estimatedFps,
        'droppedFramesCount': droppedFramesCount,
        'isProfilingComplete': isProfilingComplete,
      };

  factory GraphicsProfilerTelemetrySummary.fromJson(Map<String, dynamic> json) {
    return GraphicsProfilerTelemetrySummary(
      collectedFrames: (json['collectedFrames'] as num?)?.toInt() ?? 0,
      targetSampleCount: (json['targetSampleCount'] as num?)?.toInt() ??
          PlatformAdaptiveGraphicsProfiler.defaultSampleCount,
      averageFrameTimeMs:
          (json['averageFrameTimeMs'] as num?)?.toDouble() ?? 0.0,
      p95FrameTimeMs: (json['p95FrameTimeMs'] as num?)?.toDouble() ?? 0.0,
      maxFrameTimeMs: (json['maxFrameTimeMs'] as num?)?.toDouble() ?? 0.0,
      estimatedFps: (json['estimatedFps'] as num?)?.toDouble() ?? 0.0,
      droppedFramesCount: (json['droppedFramesCount'] as num?)?.toInt() ?? 0,
      isProfilingComplete: json['isProfilingComplete'] as bool? ?? false,
    );
  }
}

/// Pełny stan profilera graficznego dostępny dla UI oraz warstwy ustawień.
@immutable
class PlatformAdaptiveGraphicsState {
  final AdaptiveGraphicsPlatform platform;
  final bool isTabletFormFactor;
  final bool isAutoProfilingEnabled;
  final bool isProfilingActive;
  final AdaptiveGraphicsProfilePreset recommendedPreset;
  final AdaptiveGraphicsProfilePreset activePreset;
  final AdaptiveGraphicsProfilePreset? manualOverridePreset;
  final List<FrameTimingSample> samples;
  final GraphicsProfilerTelemetrySummary telemetry;
  final String decisionReason;
  final DateTime lastUpdatedAt;

  const PlatformAdaptiveGraphicsState({
    required this.platform,
    required this.isTabletFormFactor,
    required this.isAutoProfilingEnabled,
    required this.isProfilingActive,
    required this.recommendedPreset,
    required this.activePreset,
    required this.manualOverridePreset,
    required this.samples,
    required this.telemetry,
    required this.decisionReason,
    required this.lastUpdatedAt,
  });

  bool get isManualOverrideActive => manualOverridePreset != null;

  PlatformAdaptiveGraphicsState copyWith({
    AdaptiveGraphicsPlatform? platform,
    bool? isTabletFormFactor,
    bool? isAutoProfilingEnabled,
    bool? isProfilingActive,
    AdaptiveGraphicsProfilePreset? recommendedPreset,
    AdaptiveGraphicsProfilePreset? activePreset,
    AdaptiveGraphicsProfilePreset? manualOverridePreset,
    bool clearManualOverride = false,
    List<FrameTimingSample>? samples,
    GraphicsProfilerTelemetrySummary? telemetry,
    String? decisionReason,
    DateTime? lastUpdatedAt,
  }) {
    return PlatformAdaptiveGraphicsState(
      platform: platform ?? this.platform,
      isTabletFormFactor: isTabletFormFactor ?? this.isTabletFormFactor,
      isAutoProfilingEnabled:
          isAutoProfilingEnabled ?? this.isAutoProfilingEnabled,
      isProfilingActive: isProfilingActive ?? this.isProfilingActive,
      recommendedPreset: recommendedPreset ?? this.recommendedPreset,
      activePreset: activePreset ?? this.activePreset,
      manualOverridePreset: clearManualOverride
          ? null
          : (manualOverridePreset ?? this.manualOverridePreset),
      samples: samples ?? this.samples,
      telemetry: telemetry ?? this.telemetry,
      decisionReason: decisionReason ?? this.decisionReason,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'platform': platform.name,
        'isTabletFormFactor': isTabletFormFactor,
        'isAutoProfilingEnabled': isAutoProfilingEnabled,
        'isProfilingActive': isProfilingActive,
        'recommendedPreset': recommendedPreset.name,
        'activePreset': activePreset.name,
        'manualOverridePreset': manualOverridePreset?.name,
        'samples': samples.map((s) => s.toJson()).toList(),
        'telemetry': telemetry.toJson(),
        'decisionReason': decisionReason,
        'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
      };

  factory PlatformAdaptiveGraphicsState.fromJson(Map<String, dynamic> json) {
    final rawSamples = json['samples'] as List<dynamic>? ?? const [];
    final parsedSamples = rawSamples
        .whereType<Map<String, dynamic>>()
        .map(FrameTimingSample.fromJson)
        .toList();
    final manualRaw = json['manualOverridePreset'] as String?;

    return PlatformAdaptiveGraphicsState(
      platform: AdaptiveGraphicsPlatform.fromJson(
        json['platform'] as String? ?? 'other',
      ),
      isTabletFormFactor: json['isTabletFormFactor'] as bool? ?? false,
      isAutoProfilingEnabled: json['isAutoProfilingEnabled'] as bool? ?? true,
      isProfilingActive: json['isProfilingActive'] as bool? ?? false,
      recommendedPreset: AdaptiveGraphicsProfilePreset.fromJson(
        json['recommendedPreset'] as String? ?? 'high60FpsTablet',
      ),
      activePreset: AdaptiveGraphicsProfilePreset.fromJson(
        json['activePreset'] as String? ?? 'high60FpsTablet',
      ),
      manualOverridePreset: manualRaw != null
          ? AdaptiveGraphicsProfilePreset.fromJson(manualRaw)
          : null,
      samples: parsedSamples,
      telemetry: json['telemetry'] is Map<String, dynamic>
          ? GraphicsProfilerTelemetrySummary.fromJson(
              json['telemetry'] as Map<String, dynamic>,
            )
          : GraphicsProfilerTelemetrySummary.fromSamples(parsedSamples),
      decisionReason: json['decisionReason'] as String? ??
          'Zainicjalizowano na podstawie profilu platformy.',
      lastUpdatedAt: DateTime.tryParse(
            json['lastUpdatedAt'] as String? ?? '',
          ) ??
          DateTime.now(),
    );
  }
}

/// Wynik ewaluacji presetu na podstawie platformy i telemetrii klatek.
@immutable
class AdaptivePresetEvaluationResult {
  final AdaptiveGraphicsProfilePreset preset;
  final String reason;

  const AdaptivePresetEvaluationResult({
    required this.preset,
    required this.reason,
  });
}

/// Automatyczny profiler graficzny wykrywający platformę (Windows, macOS, iOS, Android)
/// oraz mierzący czas renderowania pierwszych 30 klatek w celu doboru presetu graficznego.
class PlatformAdaptiveGraphicsProfiler {
  static const int defaultSampleCount = 30;
  static const double tabletShortestSideThresholdDp = 600.0;

  final int targetSampleCount;
  final List<FrameTimingSample> _samples = <FrameTimingSample>[];
  TimingsCallback? _activeTimingsCallback;
  bool _isAttachedToScheduler = false;

  PlatformAdaptiveGraphicsProfiler({
    this.targetSampleCount = defaultSampleCount,
  }) : assert(targetSampleCount > 0, 'targetSampleCount musi być > 0');

  List<FrameTimingSample> get samples => List.unmodifiable(_samples);
  bool get isProfilingComplete => _samples.length >= targetSampleCount;
  bool get isAttachedToScheduler => _isAttachedToScheduler;

  /// Wykrywa bieżącą platformę systemu operacyjnego.
  static AdaptiveGraphicsPlatform detectPlatform({
    TargetPlatform? overridePlatform,
    bool? overrideIsWeb,
  }) {
    final isWeb = overrideIsWeb ?? kIsWeb;
    final target = overridePlatform ?? defaultTargetPlatform;
    return AdaptiveGraphicsPlatform.fromTargetPlatform(
      target,
      isWeb: isWeb,
    );
  }

  /// Wykrywa czy urządzenie mobilne/hybrydowe ma rozmiar ekranu klasy tablet (>= 600 dp).
  static bool detectTabletFormFactor({
    required AdaptiveGraphicsPlatform platform,
    double? shortestSideDp,
  }) {
    if (platform.isDesktop) return false;
    if (shortestSideDp != null && shortestSideDp > 0) {
      return shortestSideDp >= tabletShortestSideThresholdDp;
    }
    try {
      final views = SchedulerBinding.instance.platformDispatcher.views;
      if (views.isEmpty) return false;
      final view = views.first;
      final dpr = view.devicePixelRatio > 0 ? view.devicePixelRatio : 1.0;
      final logicalSize = view.physicalSize / dpr;
      return logicalSize.shortestSide >= tabletShortestSideThresholdDp;
    } catch (_) {
      return false;
    }
  }

  /// Domyślny preset startowy przed zakończeniem pomiaru 30 klatek.
  static AdaptiveGraphicsProfilePreset baselinePresetForPlatform(
    AdaptiveGraphicsPlatform platform, {
    bool isTabletFormFactor = false,
  }) {
    if (platform.isDesktop) {
      return AdaptiveGraphicsProfilePreset.ultra120FpsDesktop;
    }
    if (isTabletFormFactor || platform == AdaptiveGraphicsPlatform.web) {
      return AdaptiveGraphicsProfilePreset.high60FpsTablet;
    }
    return AdaptiveGraphicsProfilePreset.balancedMobileBatterySaver;
  }

  /// Wylicza rekomendowany preset na podstawie platformy i czasów pierwszych 30 klatek.
  static AdaptivePresetEvaluationResult evaluatePreset({
    required AdaptiveGraphicsPlatform platform,
    required GraphicsProfilerTelemetrySummary telemetry,
    bool isTabletFormFactor = false,
  }) {
    if (!telemetry.isProfilingComplete || telemetry.collectedFrames == 0) {
      final baseline = baselinePresetForPlatform(
        platform,
        isTabletFormFactor: isTabletFormFactor,
      );
      return AdaptivePresetEvaluationResult(
        preset: baseline,
        reason:
            'Profilowanie w toku (${telemetry.collectedFrames}/${telemetry.targetSampleCount} klatek) — zastosowano profil bazowy dla ${platform.displayName}.',
      );
    }

    final avg = telemetry.averageFrameTimeMs;
    final p95 = telemetry.p95FrameTimeMs;
    final dropped = telemetry.droppedFramesCount;

    if (platform.isDesktop) {
      if (avg <= 10.5 && p95 <= 14.0 && dropped <= 1) {
        return AdaptivePresetEvaluationResult(
          preset: AdaptiveGraphicsProfilePreset.ultra120FpsDesktop,
          reason:
              '${platform.displayName}: średnio ${avg.toStringAsFixed(1)} ms/klatkę (p95: ${p95.toStringAsFixed(1)} ms) — pełne wsparcie 120 FPS.',
        );
      }
      if (avg <= 18.0 && p95 <= 24.0) {
        return AdaptivePresetEvaluationResult(
          preset: AdaptiveGraphicsProfilePreset.high60FpsTablet,
          reason:
              '${platform.displayName}: średnio ${avg.toStringAsFixed(1)} ms/klatkę — dobrano stabilny profil High 60 FPS.',
        );
      }
      return AdaptivePresetEvaluationResult(
        preset: AdaptiveGraphicsProfilePreset.balancedMobileBatterySaver,
        reason:
            '${platform.displayName}: wykryto wysokie obciążenie GPU (${avg.toStringAsFixed(1)} ms/klatkę) — obniżono detale dla płynności.',
      );
    }

    if (platform.isMobile) {
      if (isTabletFormFactor && avg <= 14.5 && p95 <= 18.5 && dropped <= 3) {
        return AdaptivePresetEvaluationResult(
          preset: AdaptiveGraphicsProfilePreset.high60FpsTablet,
          reason:
              '${platform.displayName} (Tablet): średnio ${avg.toStringAsFixed(1)} ms/klatkę — aktywowano High 60 FPS Tablet.',
        );
      }
      if (!isTabletFormFactor && avg <= 11.0 && p95 <= 14.5 && dropped <= 2) {
        return AdaptivePresetEvaluationResult(
          preset: AdaptiveGraphicsProfilePreset.high60FpsTablet,
          reason:
              '${platform.displayName}: flagowa wydajność (${avg.toStringAsFixed(1)} ms/klatkę) pozwala na profil High 60 FPS.',
        );
      }
      return AdaptivePresetEvaluationResult(
        preset: AdaptiveGraphicsProfilePreset.balancedMobileBatterySaver,
        reason:
            '${platform.displayName}: średnio ${avg.toStringAsFixed(1)} ms/klatkę ($dropped opóźnionych klatek) — dobrano Balanced Mobile Battery Saver.',
      );
    }

    if (avg <= 13.5 && p95 <= 17.5) {
      return AdaptivePresetEvaluationResult(
        preset: AdaptiveGraphicsProfilePreset.high60FpsTablet,
        reason:
            '${platform.displayName}: stabilne ${avg.toStringAsFixed(1)} ms/klatkę — dobrano High 60 FPS.',
      );
    }
    return AdaptivePresetEvaluationResult(
      preset: AdaptiveGraphicsProfilePreset.balancedMobileBatterySaver,
      reason:
          '${platform.displayName}: ${avg.toStringAsFixed(1)} ms/klatkę — dobrano oszczędny profil Balanced.',
    );
  }

  /// Dodaje pojedynczy czas trwania klatki (przydatne w testach i symulacji).
  GraphicsProfilerTelemetrySummary recordFrameDuration(Duration duration) {
    if (_samples.length < targetSampleCount) {
      _samples.add(
        FrameTimingSample.fromDuration(_samples.length + 1, duration),
      );
    }
    return buildTelemetry();
  }

  /// Dodaje surowy obiekt [FrameTiming] z silnika Fluttera.
  GraphicsProfilerTelemetrySummary recordFrameTiming(FrameTiming timing) {
    if (_samples.length < targetSampleCount) {
      _samples.add(
        FrameTimingSample.fromFrameTiming(_samples.length + 1, timing),
      );
    }
    return buildTelemetry();
  }

  /// Rejestruje serię czasów klatek (np. z [SchedulerBinding.addTimingsCallback]).
  GraphicsProfilerTelemetrySummary recordFrameTimings(
    List<FrameTiming> timings,
  ) {
    for (final timing in timings) {
      if (_samples.length >= targetSampleCount) break;
      recordFrameTiming(timing);
    }
    return buildTelemetry();
  }

  /// Czyści zebrane próbki przed ponownym pomiarem.
  void resetSamples() {
    _samples.clear();
  }

  GraphicsProfilerTelemetrySummary buildTelemetry() {
    return GraphicsProfilerTelemetrySummary.fromSamples(
      _samples,
      targetSampleCount: targetSampleCount,
    );
  }

  /// Podłącza nasłuch pierwszych 30 klatek w [SchedulerBinding].
  void startSchedulerCapture({
    required void Function(GraphicsProfilerTelemetrySummary summary) onProgress,
    void Function(GraphicsProfilerTelemetrySummary summary)? onComplete,
  }) {
    stopSchedulerCapture();
    resetSamples();

    _activeTimingsCallback = (List<FrameTiming> timings) {
      if (_samples.length >= targetSampleCount) {
        stopSchedulerCapture();
        return;
      }
      final summary = recordFrameTimings(timings);
      onProgress(summary);
      if (summary.isProfilingComplete) {
        stopSchedulerCapture();
        onComplete?.call(summary);
      }
    };

    SchedulerBinding.instance.addTimingsCallback(_activeTimingsCallback!);
    _isAttachedToScheduler = true;
  }

  /// Odłącza aktywny nasłuch [TimingsCallback], aby uniknąć wycieków pamięci.
  void stopSchedulerCapture() {
    final cb = _activeTimingsCallback;
    if (cb != null && _isAttachedToScheduler) {
      try {
        SchedulerBinding.instance.removeTimingsCallback(cb);
      } catch (_) {
        // Bezpieczne pominięcie, gdy binding nie jest już aktywny.
      }
    }
    _activeTimingsCallback = null;
    _isAttachedToScheduler = false;
  }

  void dispose() {
    stopSchedulerCapture();
  }
}

/// Provider kontrolera profilera graficznego zsynchronizowanego z [gameSettingsProvider].
final platformAdaptiveGraphicsProfilerProvider = StateNotifierProvider<
    PlatformAdaptiveGraphicsProfilerNotifier, PlatformAdaptiveGraphicsState>(
  (ref) {
    final settingsNotifier = ref.read(gameSettingsProvider.notifier);
    return PlatformAdaptiveGraphicsProfilerNotifier(
      onApplyGamePreset: settingsNotifier.applyPreset,
    );
  },
);

/// Notifier Riverpod zarządzający cyklem życia pomiaru 30 klatek oraz ręcznym nadpisaniem w ustawieniach.
class PlatformAdaptiveGraphicsProfilerNotifier
    extends StateNotifier<PlatformAdaptiveGraphicsState> {
  final PlatformAdaptiveGraphicsProfiler _profiler;
  final void Function(GraphicsPreset preset)? _onApplyGamePreset;

  PlatformAdaptiveGraphicsProfilerNotifier({
    PlatformAdaptiveGraphicsProfiler? profiler,
    AdaptiveGraphicsPlatform? platformOverride,
    bool? isTabletOverride,
    void Function(GraphicsPreset preset)? onApplyGamePreset,
  })  : _profiler = profiler ?? PlatformAdaptiveGraphicsProfiler(),
        _onApplyGamePreset = onApplyGamePreset,
        super(
          _buildInitialState(
            platformOverride: platformOverride,
            isTabletOverride: isTabletOverride,
            targetSampleCount: (profiler ?? PlatformAdaptiveGraphicsProfiler())
                .targetSampleCount,
          ),
        );

  static PlatformAdaptiveGraphicsState _buildInitialState({
    AdaptiveGraphicsPlatform? platformOverride,
    bool? isTabletOverride,
    required int targetSampleCount,
  }) {
    final platform =
        platformOverride ?? PlatformAdaptiveGraphicsProfiler.detectPlatform();
    final isTablet = isTabletOverride ??
        PlatformAdaptiveGraphicsProfiler.detectTabletFormFactor(
          platform: platform,
        );
    final baseline = PlatformAdaptiveGraphicsProfiler.baselinePresetForPlatform(
      platform,
      isTabletFormFactor: isTablet,
    );

    return PlatformAdaptiveGraphicsState(
      platform: platform,
      isTabletFormFactor: isTablet,
      isAutoProfilingEnabled: true,
      isProfilingActive: false,
      recommendedPreset: baseline,
      activePreset: baseline,
      manualOverridePreset: null,
      samples: const <FrameTimingSample>[],
      telemetry: GraphicsProfilerTelemetrySummary.empty(
        targetSampleCount: targetSampleCount,
      ),
      decisionReason:
          'Oczekuje na pomiar pierwszych $targetSampleCount klatek (${platform.displayName}).',
      lastUpdatedAt: DateTime.now(),
    );
  }

  /// Uruchamia automatyczny pomiar pierwszych 30 klatek przez [SchedulerBinding].
  void startAutoProfiling() {
    if (!state.isAutoProfilingEnabled) return;
    _profiler.startSchedulerCapture(
      onProgress: _handleTelemetryProgress,
      onComplete: _handleTelemetryComplete,
    );
    state = state.copyWith(
      isProfilingActive: true,
      samples: const <FrameTimingSample>[],
      telemetry: GraphicsProfilerTelemetrySummary.empty(
        targetSampleCount: _profiler.targetSampleCount,
      ),
      decisionReason:
          'Trwa pomiar pierwszych ${_profiler.targetSampleCount} klatek na ${state.platform.displayName}...',
      lastUpdatedAt: DateTime.now(),
    );
  }

  /// Rejestruje serię czasów klatek ręcznie (np. w testach lub symulacji).
  void ingestFrameDurations(List<Duration> durations) {
    _profiler.resetSamples();
    var telemetry = _profiler.buildTelemetry();
    for (final duration in durations) {
      telemetry = _profiler.recordFrameDuration(duration);
    }
    _handleTelemetryProgress(telemetry);
    if (telemetry.isProfilingComplete) {
      _handleTelemetryComplete(telemetry);
    }
  }

  void _handleTelemetryProgress(GraphicsProfilerTelemetrySummary telemetry) {
    if (!mounted) return;
    state = state.copyWith(
      samples: _profiler.samples,
      telemetry: telemetry,
      isProfilingActive: !telemetry.isProfilingComplete,
      lastUpdatedAt: DateTime.now(),
    );
  }

  void _handleTelemetryComplete(GraphicsProfilerTelemetrySummary telemetry) {
    if (!mounted) return;
    final eval = PlatformAdaptiveGraphicsProfiler.evaluatePreset(
      platform: state.platform,
      telemetry: telemetry,
      isTabletFormFactor: state.isTabletFormFactor,
    );

    final effectivePreset = state.manualOverridePreset ?? eval.preset;
    state = state.copyWith(
      isProfilingActive: false,
      recommendedPreset: eval.preset,
      activePreset: effectivePreset,
      samples: _profiler.samples,
      telemetry: telemetry,
      decisionReason: state.isManualOverrideActive
          ? 'Ręczny wybór użytkownika (${effectivePreset.label}). Zalecenie profilera: ${eval.preset.label}.'
          : eval.reason,
      lastUpdatedAt: DateTime.now(),
    );

    if (!state.isManualOverrideActive) {
      _onApplyGamePreset?.call(effectivePreset.gamePreset);
    }
  }

  /// Ręcznie zmienia preset w ustawieniach, blokując nadpisywanie przez auto-profiler.
  void setManualPresetOverride(AdaptiveGraphicsProfilePreset preset) {
    state = state.copyWith(
      manualOverridePreset: preset,
      activePreset: preset,
      isAutoProfilingEnabled: false,
      isProfilingActive: false,
      decisionReason:
          'Ustawiono ręcznie w opcjach gry: ${preset.label} (Auto-Profiler wstrzymany).',
      lastUpdatedAt: DateTime.now(),
    );
    _profiler.stopSchedulerCapture();
    _onApplyGamePreset?.call(preset.gamePreset);
  }

  /// Przywraca tryb automatyczny i aplikuje rekomendację profilera.
  void enableAutoProfiling({bool restartBenchmark = true}) {
    final nextActive = state.recommendedPreset;
    state = state.copyWith(
      clearManualOverride: true,
      isAutoProfilingEnabled: true,
      activePreset: nextActive,
      decisionReason:
          'Przywrócono automatyczny dobór presetu (${nextActive.label}).',
      lastUpdatedAt: DateTime.now(),
    );
    _onApplyGamePreset?.call(nextActive.gamePreset);
    if (restartBenchmark) {
      startAutoProfiling();
    }
  }

  /// Symuluje zmianę platformy/rozmiaru w narzędziach diagnostycznych lub testach.
  void setPlatformContext({
    required AdaptiveGraphicsPlatform platform,
    bool isTabletFormFactor = false,
  }) {
    final eval = PlatformAdaptiveGraphicsProfiler.evaluatePreset(
      platform: platform,
      telemetry: state.telemetry,
      isTabletFormFactor: isTabletFormFactor,
    );
    final effective = state.manualOverridePreset ?? eval.preset;
    state = state.copyWith(
      platform: platform,
      isTabletFormFactor: isTabletFormFactor,
      recommendedPreset: eval.preset,
      activePreset: effective,
      decisionReason: eval.reason,
      lastUpdatedAt: DateTime.now(),
    );
  }

  @override
  void dispose() {
    _profiler.dispose();
    super.dispose();
  }
}

/// Produkcyjny panel ustawień profilera graficznego (paleta AppColors, Inter, LayoutBuilder 390/1024/1600).
class PlatformAdaptiveGraphicsProfilerPanel extends StatelessWidget {
  final PlatformAdaptiveGraphicsState state;
  final ValueChanged<AdaptiveGraphicsProfilePreset>? onSelectPreset;
  final VoidCallback? onEnableAutoProfiling;
  final VoidCallback? onRerunBenchmark;
  final bool isEnabled;

  const PlatformAdaptiveGraphicsProfilerPanel({
    super.key,
    required this.state,
    this.onSelectPreset,
    this.onEnableAutoProfiling,
    this.onRerunBenchmark,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final isCompact = width < 640;
        final isWide = width >= 1100;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.all(isCompact ? 14 : 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF2A2F3D),
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(isCompact),
              const SizedBox(height: 16),
              _buildTelemetrySection(isCompact, isWide),
              const SizedBox(height: 16),
              _buildDecisionBanner(),
              const SizedBox(height: 16),
              _buildPresetSelector(isCompact, isWide),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isCompact) {
    final platformBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            state.platform.isDesktop
                ? Icons.desktop_windows_rounded
                : (state.isTabletFormFactor
                    ? Icons.tablet_mac_rounded
                    : Icons.smartphone_rounded),
            size: 15,
            color: AppColors.goldAccent,
          ),
          const SizedBox(width: 6),
          Text(
            state.isTabletFormFactor
                ? '${state.platform.displayName} (Tablet)'
                : state.platform.displayName,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );

    final controls = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _InteractiveActionChip(
          label: state.isAutoProfilingEnabled ? 'Auto-Dobór: WŁ' : 'Tryb Ręczny',
          icon: state.isAutoProfilingEnabled
              ? Icons.auto_awesome_rounded
              : Icons.tune_rounded,
          isActive: state.isAutoProfilingEnabled,
          isEnabled: isEnabled,
          accentColor: AppColors.statusSuccess,
          onTap: onEnableAutoProfiling,
        ),
        _InteractiveActionChip(
          label: state.isProfilingActive
              ? 'Pomiar ${state.telemetry.collectedFrames}/${state.telemetry.targetSampleCount}'
              : 'Pomiar 30 klatek',
          icon: Icons.speed_rounded,
          isActive: state.isProfilingActive,
          isEnabled: isEnabled && !state.isProfilingActive,
          accentColor: AppColors.accentBlue,
          onTap: onRerunBenchmark,
        ),
      ],
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Adaptacyjny Profiler Graficzny',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Analiza pierwszych 30 klatek i dobór profilu GPU',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 10),
          platformBadge,
          const SizedBox(height: 10),
          controls,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Flexible(
                    child: Text(
                      'Adaptacyjny Profiler Graficzny',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  platformBadge,
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Wykrywanie platformy i pomiar czasu renderowania pierwszych 30 klatek',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        controls,
      ],
    );
  }

  Widget _buildTelemetrySection(bool isCompact, bool isWide) {
    final t = state.telemetry;
    final metrics = [
      _MetricTile(
        label: 'ŚR. KLATKA',
        value: t.collectedFrames == 0
            ? '-- ms'
            : '${t.averageFrameTimeMs.toStringAsFixed(1)} ms',
        accent: t.averageFrameTimeMs <= 10.5
            ? AppColors.statusSuccess
            : (t.averageFrameTimeMs <= 16.7
                ? AppColors.accentBlue
                : AppColors.amberWarning),
      ),
      _MetricTile(
        label: 'P95 KLATKA',
        value: t.collectedFrames == 0
            ? '-- ms'
            : '${t.p95FrameTimeMs.toStringAsFixed(1)} ms',
        accent: AppColors.textPrimary,
      ),
      _MetricTile(
        label: 'SZAC. FPS',
        value: t.collectedFrames == 0
            ? '--'
            : '${t.estimatedFps.round()} FPS',
        accent: AppColors.goldAccent,
      ),
      _MetricTile(
        label: 'PRÓBKI',
        value: '${t.collectedFrames}/${t.targetSampleCount}',
        accent: t.isProfilingComplete
            ? AppColors.statusSuccess
            : AppColors.cyanAccent,
      ),
    ];

    final chart = Container(
      height: isCompact ? 76 : 92,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: CustomPaint(
        painter: _FrameTimingBarsPainter(
          samples: state.samples,
          targetCount: t.targetSampleCount,
        ),
        child: const SizedBox.expand(),
      ),
    );

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 5,
            child: Row(
              children: metrics
                  .map(
                    (m) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: m,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(flex: 4, child: chart),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView.count(
          crossAxisCount: isCompact ? 2 : 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: isCompact ? 2.5 : 2.2,
          children: metrics,
        ),
        const SizedBox(height: 10),
        chart,
      ],
    );
  }

  Widget _buildDecisionBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: state.isManualOverrideActive
              ? AppColors.primaryAccent
              : AppColors.cardBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            state.isManualOverrideActive
                ? Icons.lock_outline_rounded
                : Icons.verified_rounded,
            size: 16,
            color: state.isManualOverrideActive
                ? AppColors.amberWarning
                : AppColors.statusSuccess,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              state.decisionReason,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetSelector(bool isCompact, bool isWide) {
    const presets = AdaptiveGraphicsProfilePreset.values;
    if (isCompact) {
      return Column(
        children: presets
            .map(
              (preset) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _PresetOptionCard(
                  preset: preset,
                  isSelected: state.activePreset == preset,
                  isRecommended: state.recommendedPreset == preset,
                  isEnabled: isEnabled,
                  onTap: onSelectPreset != null
                      ? () => onSelectPreset!(preset)
                      : null,
                ),
              ),
            )
            .toList(),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: presets
            .map(
              (preset) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: preset == presets.last ? 0 : (isWide ? 12 : 8),
                  ),
                  child: _PresetOptionCard(
                    preset: preset,
                    isSelected: state.activePreset == preset,
                    isRecommended: state.recommendedPreset == preset,
                    isEnabled: isEnabled,
                    onTap: onSelectPreset != null
                        ? () => onSelectPreset!(preset)
                        : null,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: accent,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractiveActionChip extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final bool isEnabled;
  final Color accentColor;
  final VoidCallback? onTap;

  const _InteractiveActionChip({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.isEnabled,
    required this.accentColor,
    this.onTap,
  });

  @override
  State<_InteractiveActionChip> createState() => _InteractiveActionChipState();
}

class _InteractiveActionChipState extends State<_InteractiveActionChip> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final canTap = widget.isEnabled && widget.onTap != null;
    final borderColor = _isFocused
        ? AppColors.goldAccent
        : (widget.isActive
            ? widget.accentColor
            : (_isHovered ? AppColors.textSecondary : AppColors.cardBorder));

    return FocusableActionDetector(
      enabled: canTap,
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      child: GestureDetector(
        onTapDown: canTap ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: canTap ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: canTap ? () => setState(() => _isPressed = false) : null,
        onTap: canTap ? widget.onTap : null,
        child: MouseRegion(
          cursor: canTap ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: widget.isEnabled ? (_isPressed ? 0.82 : 1.0) : 0.45,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: widget.isActive
                    ? widget.accentColor.withValues(alpha: 0.16)
                    : (_isHovered
                        ? AppColors.surfaceLight
                        : AppColors.background),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.icon,
                    size: 14,
                    color: widget.isActive
                        ? widget.accentColor
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: widget.isActive
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PresetOptionCard extends StatefulWidget {
  final AdaptiveGraphicsProfilePreset preset;
  final bool isSelected;
  final bool isRecommended;
  final bool isEnabled;
  final VoidCallback? onTap;

  const _PresetOptionCard({
    required this.preset,
    required this.isSelected,
    required this.isRecommended,
    required this.isEnabled,
    this.onTap,
  });

  @override
  State<_PresetOptionCard> createState() => _PresetOptionCardState();
}

class _PresetOptionCardState extends State<_PresetOptionCard> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final canTap = widget.isEnabled && widget.onTap != null;
    final borderColor = _isFocused
        ? AppColors.goldAccent
        : (widget.isSelected
            ? AppColors.goldAccent
            : (_isHovered ? AppColors.primaryAccent : const Color(0xFF2A2F3D)));

    return FocusableActionDetector(
      enabled: canTap,
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      child: GestureDetector(
        onTapDown: canTap ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: canTap ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: canTap ? () => setState(() => _isPressed = false) : null,
        onTap: canTap ? widget.onTap : null,
        child: MouseRegion(
          cursor: canTap ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            opacity: widget.isEnabled ? (_isPressed ? 0.85 : 1.0) : 0.45,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? AppColors.surfaceLight
                    : (_isHovered
                        ? const Color(0xFF1D212B)
                        : AppColors.background),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: borderColor,
                  width: widget.isSelected ? 1.5 : 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: widget.preset.badgeColor.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${widget.preset.targetFps} FPS',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: widget.preset.badgeColor,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (widget.isRecommended)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.statusSuccess.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'AUTO',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.statusSuccess,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.preset.label,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.preset.description,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.35,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FrameTimingBarsPainter extends CustomPainter {
  final List<FrameTimingSample> samples;
  final int targetCount;

  const _FrameTimingBarsPainter({
    required this.samples,
    required this.targetCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    const maxScaleMs = 33.33;
    final y60Fps = size.height * (1.0 - (16.67 / maxScaleMs));
    final y120Fps = size.height * (1.0 - (8.33 / maxScaleMs));

    final guide60 = Paint()
      ..color = AppColors.amberWarning.withValues(alpha: 0.35)
      ..strokeWidth = 1.0;
    final guide120 = Paint()
      ..color = AppColors.statusSuccess.withValues(alpha: 0.35)
      ..strokeWidth = 1.0;

    canvas.drawLine(Offset(0, y60Fps), Offset(size.width, y60Fps), guide60);
    canvas.drawLine(Offset(0, y120Fps), Offset(size.width, y120Fps), guide120);

    final count = math.max(targetCount, 1);
    final slotWidth = size.width / count;
    final barWidth = math.max(2.0, slotWidth * 0.68);

    for (var i = 0; i < count; i++) {
      final left = i * slotWidth + (slotWidth - barWidth) / 2;
      if (i >= samples.length) {
        final emptyPaint = Paint()
          ..color = AppColors.cardBorder.withValues(alpha: 0.35);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(left, size.height - 3, barWidth, 3),
            const Radius.circular(2),
          ),
          emptyPaint,
        );
        continue;
      }

      final ms = samples[i].totalDurationMs;
      final normalized = (ms / maxScaleMs).clamp(0.06, 1.0);
      final barHeight = size.height * normalized;
      final barColor = ms <= 8.5
          ? AppColors.statusSuccess
          : (ms <= 16.67 ? AppColors.accentBlue : AppColors.crimsonAlert);

      final barPaint = Paint()..color = barColor;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, size.height - barHeight, barWidth, barHeight),
          const Radius.circular(2),
        ),
        barPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FrameTimingBarsPainter oldDelegate) {
    return oldDelegate.samples.length != samples.length ||
        oldDelegate.targetCount != targetCount;
  }
}
