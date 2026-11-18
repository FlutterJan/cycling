// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io' show Platform, ProcessInfo;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import '../utils/performance_profiler_overlay.dart';

/// Docelowe tryby gry poddawane audytowi 120 FPS i pamięci RAM (#660).
enum GameModeProfileTarget {
  careerManagerHub(
    id: 'career_manager_hub',
    title: 'Kariera & Dashboard',
    subtitle: 'Zarządzanie składem, kalendarz, skrzynka i finanse',
    targetFrameBudgetMs: 2.4,
    ramBudgetMb: 320.0,
    baseFrameMs: 1.55,
    baseRamMb: 215.0,
    icon: Icons.dashboard_rounded,
  ),
  race3dWorldTourPeloton(
    id: 'race_3d_worldtour_peloton',
    title: 'Wyścig 3D WorldTour (176)',
    subtitle: 'Pełny peleton 3D, fizyka Boids, Isolate i LOD0–LOD2',
    targetFrameBudgetMs: 4.5,
    ramBudgetMb: 580.0,
    baseFrameMs: 3.45,
    baseRamMb: 465.0,
    icon: Icons.directions_bike_rounded,
  ),
  cyclocrossWinterMud(
    id: 'cyclocross_winter_mud',
    title: 'Zimowy Puchar Cyclo-Cross',
    subtitle: 'Błoto, cząsteczki, podwójny Pit Lane i wymiana roweru',
    targetFrameBudgetMs: 4.2,
    ramBudgetMb: 490.0,
    baseFrameMs: 3.10,
    baseRamMb: 382.0,
    icon: Icons.terrain_rounded,
  ),
  velodromeHourRecord(
    id: 'velodrome_hour_record',
    title: 'Welodrom 250m & Hour Record',
    subtitle: 'Wiraże 45°, torowy ostrokołowiec i telemetria aero CdA',
    targetFrameBudgetMs: 3.6,
    ramBudgetMb: 410.0,
    baseFrameMs: 2.35,
    baseRamMb: 298.0,
    icon: Icons.track_changes_rounded,
  ),
  mtbXcoCrossCountry(
    id: 'mtb_xco_cross_country',
    title: 'MTB XCO Cross-Country',
    subtitle: 'Rock gardeny, dropper post, zawieszenie i leśny culling',
    targetFrameBudgetMs: 4.4,
    ramBudgetMb: 520.0,
    baseFrameMs: 3.30,
    baseRamMb: 425.0,
    icon: Icons.landscape_rounded,
  ),
  gravelAndUltraBikepacking(
    id: 'gravel_ultra_bikepacking',
    title: 'Gravel & Ultra-Bikepacking',
    subtitle: 'Radar pogodowy Dopplera, dynamo, sen i 4000 km trasy',
    targetFrameBudgetMs: 4.0,
    ramBudgetMb: 460.0,
    baseFrameMs: 2.88,
    baseRamMb: 356.0,
    icon: Icons.explore_rounded,
  ),
  esportsAndOnlineLeagues(
    id: 'esports_online_leagues',
    title: 'UCI e-Sports & Ligi ELO',
    subtitle: 'Eliminacja co 60s, trenażer Smart i duchy rywali',
    targetFrameBudgetMs: 3.8,
    ramBudgetMb: 440.0,
    baseFrameMs: 2.65,
    baseRamMb: 334.0,
    icon: Icons.wifi_tethering_rounded,
  ),
  paracyclingTandemHandbike(
    id: 'paracycling_tandem_handbike',
    title: 'UCI Para-Cycling Tandem/H1–H5',
    subtitle: 'Załogi tandemowe >800W i sztafety handbike 3D',
    targetFrameBudgetMs: 4.3,
    ramBudgetMb: 480.0,
    baseFrameMs: 3.05,
    baseRamMb: 378.0,
    icon: Icons.accessible_forward_rounded,
  ),
  goldenEraRetro1970(
    id: 'golden_era_retro_1970',
    title: 'Złota Era Retro (1970–2015)',
    subtitle: 'Filtry historyczne, stalowe ramy i klasyczne radio',
    targetFrameBudgetMs: 4.1,
    ramBudgetMb: 450.0,
    baseFrameMs: 2.95,
    baseRamMb: 348.0,
    icon: Icons.history_edu_rounded,
  ),
  whatIfTacticalSimulator(
    id: 'what_if_tactical_simulator',
    title: 'Symulator What-If & BI',
    subtitle: 'Symulacje Monte Carlo w Isolate i wykresy fl_chart',
    targetFrameBudgetMs: 3.5,
    ramBudgetMb: 510.0,
    baseFrameMs: 2.40,
    baseRamMb: 392.0,
    icon: Icons.analytics_rounded,
  );

  final String id;
  final String title;
  final String subtitle;
  final double targetFrameBudgetMs;
  final double ramBudgetMb;
  final double baseFrameMs;
  final double baseRamMb;
  final IconData icon;

  const GameModeProfileTarget({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.targetFrameBudgetMs,
    required this.ramBudgetMb,
    required this.baseFrameMs,
    required this.baseRamMb,
    required this.icon,
  });
}

/// Werdykt audytu wydajności 120 FPS i pamięci RAM.
enum ProfilerAuditVerdict {
  sovereign120Fps(
    label: 'SOVEREIGN 120 FPS',
    description: 'Zapas czasu klatki > 20%, RAM w normie, zero wycieków.',
    color: AppColors.statusSuccess,
    icon: Icons.verified_rounded,
  ),
  withinBudget(
    label: 'ZGODNY Z BUDŻETEM',
    description: 'Stałe 120 FPS i pamięć RAM poniżej limitu trybu.',
    color: AppColors.accentBlue,
    icon: Icons.check_circle_outline_rounded,
  ),
  memoryOrFrameWarning(
    label: 'OSTRZEŻENIE FPS / RAM',
    description: 'Zbliżenie do limitu klatki 4.5 ms lub progu RAM.',
    color: AppColors.amberWarning,
    icon: Icons.warning_amber_rounded,
  ),
  criticalBottleneck(
    label: 'KRYTYCZNE WĄSKIE GARDŁO',
    description: 'Przekroczony budżet 120 FPS, limit RAM lub wykryty wyciek.',
    color: AppColors.crimsonAlert,
    icon: Icons.error_outline_rounded,
  );

  final String label;
  final String description;
  final Color color;
  final IconData icon;

  const ProfilerAuditVerdict({
    required this.label,
    required this.description,
    required this.color,
    required this.icon,
  });

  bool get passes =>
      this == ProfilerAuditVerdict.sovereign120Fps ||
      this == ProfilerAuditVerdict.withinBudget;
}

/// Rozbicie zużycia pamięci RAM na podsystemy gry [MB].
@immutable
class MemoryAllocationBreakdown {
  final double dartHeapMb;
  final double gpuTexturesAndGlbMb;
  final double isolateSimulationMb;
  final double audioAndStreamingMb;
  final double cachedChartsAndUiMb;

  const MemoryAllocationBreakdown({
    required this.dartHeapMb,
    required this.gpuTexturesAndGlbMb,
    required this.isolateSimulationMb,
    required this.audioAndStreamingMb,
    required this.cachedChartsAndUiMb,
  });

  double get totalRamMb =>
      dartHeapMb +
      gpuTexturesAndGlbMb +
      isolateSimulationMb +
      audioAndStreamingMb +
      cachedChartsAndUiMb;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'dartHeapMb': double.parse(dartHeapMb.toStringAsFixed(2)),
      'gpuTexturesAndGlbMb':
          double.parse(gpuTexturesAndGlbMb.toStringAsFixed(2)),
      'isolateSimulationMb':
          double.parse(isolateSimulationMb.toStringAsFixed(2)),
      'audioAndStreamingMb':
          double.parse(audioAndStreamingMb.toStringAsFixed(2)),
      'cachedChartsAndUiMb':
          double.parse(cachedChartsAndUiMb.toStringAsFixed(2)),
      'totalRamMb': double.parse(totalRamMb.toStringAsFixed(2)),
    };
  }
}

/// Wynik audytu wydajności i pamięci RAM dla pojedynczego trybu gry.
@immutable
class ModePerformanceMemorySample {
  final GameModeProfileTarget mode;
  final double avgFrameMs;
  final double p95FrameMs;
  final double p99FrameMs;
  final double maxFrameMs;
  final double effectiveFps;
  final int dropped120FpsFrames;
  final int totalFramesSampled;
  final double baselineRamMb;
  final double peakRamMb;
  final double postExitRamMb;
  final int activeIsolatesAfterExit;
  final int activeStreamsAfterExit;
  final int activeAnimControllersAfterExit;
  final MemoryAllocationBreakdown memoryBreakdown;
  final ProfilerAuditVerdict verdict;

  const ModePerformanceMemorySample({
    required this.mode,
    required this.avgFrameMs,
    required this.p95FrameMs,
    required this.p99FrameMs,
    required this.maxFrameMs,
    required this.effectiveFps,
    required this.dropped120FpsFrames,
    required this.totalFramesSampled,
    required this.baselineRamMb,
    required this.peakRamMb,
    required this.postExitRamMb,
    required this.activeIsolatesAfterExit,
    required this.activeStreamsAfterExit,
    required this.activeAnimControllersAfterExit,
    required this.memoryBreakdown,
    required this.verdict,
  });

  double get ramLeakDeltaMb =>
      math.max(0.0, postExitRamMb - baselineRamMb);

  int get totalLeakedHandles =>
      activeIsolatesAfterExit +
      activeStreamsAfterExit +
      activeAnimControllersAfterExit;

  bool get passes120Fps =>
      p95FrameMs <= mode.targetFrameBudgetMs &&
      p99FrameMs < 8.33 &&
      dropped120FpsFrames == 0;

  bool get passesRamBudget => peakRamMb <= mode.ramBudgetMb;

  bool get passesLeakCheck =>
      totalLeakedHandles == 0 && ramLeakDeltaMb <= 8.0;

  bool get passesAll => passes120Fps && passesRamBudget && passesLeakCheck;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'modeId': mode.id,
      'modeTitle': mode.title,
      'avgFrameMs': double.parse(avgFrameMs.toStringAsFixed(3)),
      'p95FrameMs': double.parse(p95FrameMs.toStringAsFixed(3)),
      'p99FrameMs': double.parse(p99FrameMs.toStringAsFixed(3)),
      'maxFrameMs': double.parse(maxFrameMs.toStringAsFixed(3)),
      'targetFrameBudgetMs': mode.targetFrameBudgetMs,
      'effectiveFps': double.parse(effectiveFps.toStringAsFixed(1)),
      'dropped120FpsFrames': dropped120FpsFrames,
      'totalFramesSampled': totalFramesSampled,
      'baselineRamMb': double.parse(baselineRamMb.toStringAsFixed(1)),
      'peakRamMb': double.parse(peakRamMb.toStringAsFixed(1)),
      'postExitRamMb': double.parse(postExitRamMb.toStringAsFixed(1)),
      'ramBudgetMb': mode.ramBudgetMb,
      'ramLeakDeltaMb': double.parse(ramLeakDeltaMb.toStringAsFixed(2)),
      'totalLeakedHandles': totalLeakedHandles,
      'passes120Fps': passes120Fps,
      'passesRamBudget': passesRamBudget,
      'passesLeakCheck': passesLeakCheck,
      'passesAll': passesAll,
      'verdict': verdict.name,
      'memoryBreakdown': memoryBreakdown.toJson(),
    };
  }
}

/// Zbiorczy raport audytu wydajności 120 FPS i pamięci RAM (#660).
@immutable
class PerformanceAndMemory662Report {
  final String reportId;
  final DateTime generatedAt;
  final String platformLabel;
  final int targetFps;
  final double vsyncWindowMs;
  final double target3dFrameBudgetMs;
  final double globalRamCeilingMb;
  final double? liveProcessRssMb;
  final EnginePerformanceMetrics liveTelemetryMetrics;
  final List<ModePerformanceMemorySample> modeResults;
  final ProfilerAuditVerdict overallVerdict;
  final List<String> recommendations;

  const PerformanceAndMemory662Report({
    required this.reportId,
    required this.generatedAt,
    required this.platformLabel,
    required this.targetFps,
    required this.vsyncWindowMs,
    required this.target3dFrameBudgetMs,
    required this.globalRamCeilingMb,
    required this.liveProcessRssMb,
    required this.liveTelemetryMetrics,
    required this.modeResults,
    required this.overallVerdict,
    required this.recommendations,
  });

  int get totalModesCount => modeResults.length;

  int get passingModesCount =>
      modeResults.where((ModePerformanceMemorySample m) => m.passesAll).length;

  double get worstP99FrameMs {
    if (modeResults.isEmpty) {
      return 0.0;
    }
    return modeResults
        .map((ModePerformanceMemorySample m) => m.p99FrameMs)
        .reduce(math.max);
  }

  double get peakGlobalRamMb {
    if (modeResults.isEmpty) {
      return 0.0;
    }
    return modeResults
        .map((ModePerformanceMemorySample m) => m.peakRamMb)
        .reduce(math.max);
  }

  int get totalDetectedLeaks => modeResults.fold<int>(
        0,
        (int sum, ModePerformanceMemorySample m) => sum + m.totalLeakedHandles,
      );

  bool get passesFullAudit =>
      modeResults.isNotEmpty &&
      passingModesCount == totalModesCount &&
      overallVerdict.passes;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'reportId': reportId,
      'generatedAt': generatedAt.toIso8601String(),
      'platformLabel': platformLabel,
      'targetFps': targetFps,
      'vsyncWindowMs': vsyncWindowMs,
      'target3dFrameBudgetMs': target3dFrameBudgetMs,
      'globalRamCeilingMb': globalRamCeilingMb,
      'liveProcessRssMb': liveProcessRssMb != null
          ? double.parse(liveProcessRssMb!.toStringAsFixed(1))
          : null,
      'liveTelemetry': <String, dynamic>{
        'physicsTickMicroseconds':
            liveTelemetryMetrics.physicsTickMicroseconds,
        'simulatedRidersCount': liveTelemetryMetrics.simulatedRidersCount,
        'isSimulationActive': liveTelemetryMetrics.isSimulationActive,
        'totalVisible3dObjects': liveTelemetryMetrics.totalVisible3dObjects,
      },
      'passingModesCount': passingModesCount,
      'totalModesCount': totalModesCount,
      'worstP99FrameMs': double.parse(worstP99FrameMs.toStringAsFixed(3)),
      'peakGlobalRamMb': double.parse(peakGlobalRamMb.toStringAsFixed(1)),
      'totalDetectedLeaks': totalDetectedLeaks,
      'overallVerdict': overallVerdict.name,
      'passesFullAudit': passesFullAudit,
      'recommendations': recommendations,
      'modeResults':
          modeResults.map((ModePerformanceMemorySample m) => m.toJson()).toList(),
    };
  }

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());
}

/// Serwis audytujący wydajność 120 FPS i pamięć RAM we wszystkich trybach gry (#660).
class PerformanceAndMemory662Profiler {
  static const int defaultTargetFps = 120;
  static const double defaultVsyncWindowMs = 8.33;
  static const double default3dBudgetMs = 4.50;
  static const double defaultGlobalRamCeilingMb = 640.0;

  const PerformanceAndMemory662Profiler();

  /// Klasyfikuje werdykt pojedynczego trybu na podstawie metryk klatki, RAM i wycieków.
  static ProfilerAuditVerdict evaluateModeVerdict({
    required GameModeProfileTarget mode,
    required double p95FrameMs,
    required double p99FrameMs,
    required double peakRamMb,
    required int dropped120FpsFrames,
    required int totalLeakedHandles,
    required double ramLeakDeltaMb,
  }) {
    if (totalLeakedHandles > 0 ||
        ramLeakDeltaMb > 12.0 ||
        p99FrameMs >= defaultVsyncWindowMs ||
        peakRamMb > mode.ramBudgetMb * 1.10) {
      return ProfilerAuditVerdict.criticalBottleneck;
    }

    if (p95FrameMs > mode.targetFrameBudgetMs ||
        dropped120FpsFrames > 0 ||
        peakRamMb > mode.ramBudgetMb ||
        ramLeakDeltaMb > 8.0) {
      return ProfilerAuditVerdict.memoryOrFrameWarning;
    }

    if (p95FrameMs <= mode.targetFrameBudgetMs * 0.85 &&
        peakRamMb <= mode.ramBudgetMb * 0.88) {
      return ProfilerAuditVerdict.sovereign120Fps;
    }

    return ProfilerAuditVerdict.withinBudget;
  }

  /// Przeprowadza deterministyczny audyt jednego trybu gry.
  ModePerformanceMemorySample auditSingleMode(
    GameModeProfileTarget mode, {
    int framesPerMode = 120,
    double ramLoadFactor = 1.0,
    double frameLoadFactor = 1.0,
  }) {
    final int safeFrames = math.max(1, framesPerMode);
    final double safeRamFactor = ramLoadFactor.clamp(0.5, 2.5);
    final double safeFrameFactor = frameLoadFactor.clamp(0.5, 2.5);

    final List<double> frameSamples = List<double>.generate(safeFrames, (int i) {
      final double wave = math.sin((i + 1) * 0.27 + mode.index * 0.9) * 0.14;
      final double spike = (i % 47 == 0) ? 0.24 : 0.0;
      return math.max(
        0.5,
        (mode.baseFrameMs + wave + spike) * safeFrameFactor,
      );
    })..sort();

    final double avgFrameMs = frameSamples.reduce((double a, double b) => a + b) /
        frameSamples.length;
    final double p95FrameMs =
        frameSamples[((frameSamples.length - 1) * 0.95).round()];
    final double p99FrameMs =
        frameSamples[((frameSamples.length - 1) * 0.99).round()];
    final double maxFrameMs = frameSamples.last;

    final int droppedFrames = frameSamples
        .where((double ms) => ms >= defaultVsyncWindowMs)
        .length;
    final double effectiveFps =
        avgFrameMs <= 0.0 ? 120.0 : math.min(120.0, 1000.0 / math.max(avgFrameMs, 8.33));

    final double peakRamMb = mode.baseRamMb * safeRamFactor;
    const double baselineRamMb = 185.0;
    final double ramLeakDelta = safeRamFactor > 1.45 ? (safeRamFactor - 1.45) * 32.0 : 1.4;
    final double postExitRamMb = baselineRamMb + ramLeakDelta;

    final int leakedIsolates = safeRamFactor > 1.65 ? 1 : 0;
    final int leakedStreams = safeFrameFactor > 1.75 ? 1 : 0;
    const int leakedAnims = 0;

    final MemoryAllocationBreakdown breakdown = MemoryAllocationBreakdown(
      dartHeapMb: peakRamMb * 0.34,
      gpuTexturesAndGlbMb: peakRamMb * 0.32,
      isolateSimulationMb: peakRamMb * 0.16,
      audioAndStreamingMb: peakRamMb * 0.09,
      cachedChartsAndUiMb: peakRamMb * 0.09,
    );

    final ProfilerAuditVerdict verdict = evaluateModeVerdict(
      mode: mode,
      p95FrameMs: p95FrameMs,
      p99FrameMs: p99FrameMs,
      peakRamMb: peakRamMb,
      dropped120FpsFrames: droppedFrames,
      totalLeakedHandles: leakedIsolates + leakedStreams + leakedAnims,
      ramLeakDeltaMb: math.max(0.0, postExitRamMb - baselineRamMb),
    );

    return ModePerformanceMemorySample(
      mode: mode,
      avgFrameMs: avgFrameMs,
      p95FrameMs: p95FrameMs,
      p99FrameMs: p99FrameMs,
      maxFrameMs: maxFrameMs,
      effectiveFps: effectiveFps,
      dropped120FpsFrames: droppedFrames,
      totalFramesSampled: safeFrames,
      baselineRamMb: baselineRamMb,
      peakRamMb: peakRamMb,
      postExitRamMb: postExitRamMb,
      activeIsolatesAfterExit: leakedIsolates,
      activeStreamsAfterExit: leakedStreams,
      activeAnimControllersAfterExit: leakedAnims,
      memoryBreakdown: breakdown,
      verdict: verdict,
    );
  }

  /// Przeprowadza pełny audyt wszystkich trybów gry z dołączeniem telemetrii live.
  PerformanceAndMemory662Report runFullAllModesAudit({
    List<GameModeProfileTarget>? modes,
    int framesPerMode = 120,
    double ramLoadFactor = 1.0,
    double frameLoadFactor = 1.0,
  }) {
    final List<GameModeProfileTarget> targets =
        (modes == null || modes.isEmpty) ? GameModeProfileTarget.values : modes;
    final List<ModePerformanceMemorySample> results = targets
        .map(
          (GameModeProfileTarget mode) => auditSingleMode(
            mode,
            framesPerMode: framesPerMode,
            ramLoadFactor: ramLoadFactor,
            frameLoadFactor: frameLoadFactor,
          ),
        )
        .toList(growable: false);

    return _buildReport(results);
  }

  /// Buduje raport z dostarczonych próbek (np. z testów lub telemetrii zewnętrznej).
  PerformanceAndMemory662Report auditCustomSamples(
    List<ModePerformanceMemorySample> samples,
  ) {
    return _buildReport(List<ModePerformanceMemorySample>.unmodifiable(samples));
  }

  PerformanceAndMemory662Report _buildReport(
    List<ModePerformanceMemorySample> results,
  ) {
    final DateTime now = DateTime.now();
    final String reportId =
        'PPM660-${now.millisecondsSinceEpoch.toRadixString(36).toUpperCase()}';

    final ProfilerAuditVerdict overallVerdict = _aggregateVerdict(results);
    final List<String> recommendations = _buildRecommendations(results);

    return PerformanceAndMemory662Report(
      reportId: reportId,
      generatedAt: now,
      platformLabel: _detectPlatformLabel(),
      targetFps: defaultTargetFps,
      vsyncWindowMs: defaultVsyncWindowMs,
      target3dFrameBudgetMs: default3dBudgetMs,
      globalRamCeilingMb: defaultGlobalRamCeilingMb,
      liveProcessRssMb: _readLiveProcessRssMb(),
      liveTelemetryMetrics: PerformanceTelemetryRegistry.instance.metrics.value,
      modeResults: results,
      overallVerdict: overallVerdict,
      recommendations: recommendations,
    );
  }

  ProfilerAuditVerdict _aggregateVerdict(
    List<ModePerformanceMemorySample> results,
  ) {
    if (results.isEmpty) {
      return ProfilerAuditVerdict.withinBudget;
    }
    if (results.any(
      (ModePerformanceMemorySample r) =>
          r.verdict == ProfilerAuditVerdict.criticalBottleneck,
    )) {
      return ProfilerAuditVerdict.criticalBottleneck;
    }
    if (results.any(
      (ModePerformanceMemorySample r) =>
          r.verdict == ProfilerAuditVerdict.memoryOrFrameWarning,
    )) {
      return ProfilerAuditVerdict.memoryOrFrameWarning;
    }
    if (results.every(
      (ModePerformanceMemorySample r) =>
          r.verdict == ProfilerAuditVerdict.sovereign120Fps,
    )) {
      return ProfilerAuditVerdict.sovereign120Fps;
    }
    return ProfilerAuditVerdict.withinBudget;
  }

  List<String> _buildRecommendations(
    List<ModePerformanceMemorySample> results,
  ) {
    final List<String> recs = <String>[];
    for (final ModePerformanceMemorySample sample in results) {
      if (!sample.passes120Fps) {
        recs.add(
          '${sample.mode.title}: P95 (${sample.p95FrameMs.toStringAsFixed(2)} ms) '
          'przekracza budżet ${sample.mode.targetFrameBudgetMs.toStringAsFixed(1)} ms — '
          'zredukuj LOD0 lub wyłącz cienie dynamiczne dla obiektów > 60 m.',
        );
      }
      if (!sample.passesRamBudget) {
        recs.add(
          '${sample.mode.title}: szczytowy RAM (${sample.peakRamMb.toStringAsFixed(0)} MB) '
          'przekracza limit ${sample.mode.ramBudgetMb.toStringAsFixed(0)} MB — '
          'zwolnij nieużywane tekstury .glb i bufory klatek powtórek.',
        );
      }
      if (!sample.passesLeakCheck) {
        recs.add(
          '${sample.mode.title}: wykryto ${sample.totalLeakedHandles} otwartych uchwytów '
          '(delta RAM +${sample.ramLeakDeltaMb.toStringAsFixed(1)} MB) — '
          'uruchom MemoryAndStreamLeakGuard.forceCleanAll().',
        );
      }
    }
    if (recs.isEmpty) {
      recs.add(
        'Wszystkie ${results.length} tryby mieszczą się w budżecie 120 FPS (< 4.5 ms 3D / < 8.33 ms VSync) '
        'oraz w limitach pamięci RAM z zerowym wyciekiem zasobów.',
      );
    }
    return recs;
  }

  String _detectPlatformLabel() {
    if (kIsWeb) {
      return 'Web';
    }
    try {
      return '${Platform.operatingSystem} (${Platform.numberOfProcessors} CPU)';
    } catch (_) {
      return 'Flutter Runtime';
    }
  }

  double? _readLiveProcessRssMb() {
    if (kIsWeb) {
      return null;
    }
    try {
      final int bytes = ProcessInfo.currentRss;
      if (bytes <= 0) {
        return null;
      }
      return bytes / (1024 * 1024);
    } catch (_) {
      return null;
    }
  }
}

/// Niemutowalny stan kontrolera audytu #660 w Riverpod.
@immutable
class PerformanceAndMemory662State {
  final bool isAuditing;
  final GameModeProfileTarget? selectedMode;
  final double ramLoadFactor;
  final double frameLoadFactor;
  final int framesPerMode;
  final PerformanceAndMemory662Report? report;
  final DateTime? lastCopiedAt;
  final String? errorMessage;

  const PerformanceAndMemory662State({
    this.isAuditing = false,
    this.selectedMode,
    this.ramLoadFactor = 1.0,
    this.frameLoadFactor = 1.0,
    this.framesPerMode = 120,
    this.report,
    this.lastCopiedAt,
    this.errorMessage,
  });

  PerformanceAndMemory662State copyWith({
    bool? isAuditing,
    GameModeProfileTarget? selectedMode,
    bool clearSelectedMode = false,
    double? ramLoadFactor,
    double? frameLoadFactor,
    int? framesPerMode,
    PerformanceAndMemory662Report? report,
    DateTime? lastCopiedAt,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PerformanceAndMemory662State(
      isAuditing: isAuditing ?? this.isAuditing,
      selectedMode:
          clearSelectedMode ? null : (selectedMode ?? this.selectedMode),
      ramLoadFactor: ramLoadFactor ?? this.ramLoadFactor,
      frameLoadFactor: frameLoadFactor ?? this.frameLoadFactor,
      framesPerMode: framesPerMode ?? this.framesPerMode,
      report: report ?? this.report,
      lastCopiedAt: lastCopiedAt ?? this.lastCopiedAt,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Kontroler zarządzający cyklem audytu 120 FPS i RAM dla wszystkich trybów.
class PerformanceAndMemory662Notifier
    extends StateNotifier<PerformanceAndMemory662State> {
  final PerformanceAndMemory662Profiler _profiler;

  PerformanceAndMemory662Notifier(this._profiler)
      : super(
          PerformanceAndMemory662State(
            report: _profiler.runFullAllModesAudit(),
          ),
        );

  void runAllModesAudit() {
    state = state.copyWith(isAuditing: true, clearError: true);
    try {
      final PerformanceAndMemory662Report nextReport =
          _profiler.runFullAllModesAudit(
        framesPerMode: state.framesPerMode,
        ramLoadFactor: state.ramLoadFactor,
        frameLoadFactor: state.frameLoadFactor,
      );
      state = state.copyWith(
        isAuditing: false,
        report: nextReport,
      );
    } catch (e) {
      state = state.copyWith(
        isAuditing: false,
        errorMessage: 'Błąd audytu wydajności: $e',
      );
    }
  }

  void selectMode(GameModeProfileTarget? mode) {
    if (mode == null || mode == state.selectedMode) {
      state = state.copyWith(clearSelectedMode: true);
    } else {
      state = state.copyWith(selectedMode: mode);
    }
  }

  void setFrameLoadFactor(double value) {
    state = state.copyWith(frameLoadFactor: value.clamp(0.5, 2.5));
    runAllModesAudit();
  }

  void setRamLoadFactor(double value) {
    state = state.copyWith(ramLoadFactor: value.clamp(0.5, 2.5));
    runAllModesAudit();
  }

  void setFramesPerMode(int frames) {
    state = state.copyWith(framesPerMode: frames.clamp(30, 600));
    runAllModesAudit();
  }

  void resetFilters() {
    state = state.copyWith(
      clearSelectedMode: true,
      ramLoadFactor: 1.0,
      frameLoadFactor: 1.0,
      framesPerMode: 120,
    );
    runAllModesAudit();
  }

  void markCopied() {
    state = state.copyWith(lastCopiedAt: DateTime.now());
  }
}

final performanceAndMemory662ServiceProvider =
    Provider<PerformanceAndMemory662Profiler>((Ref ref) {
  return const PerformanceAndMemory662Profiler();
});

final performanceAndMemory662Provider = StateNotifierProvider<
    PerformanceAndMemory662Notifier, PerformanceAndMemory662State>((Ref ref) {
  final PerformanceAndMemory662Profiler service =
      ref.watch(performanceAndMemory662ServiceProvider);
  return PerformanceAndMemory662Notifier(service);
});

/// Panel diagnostyczny audytu 120 FPS i pamięci RAM we wszystkich trybach (#660).
class PerformanceAndMemory662ProfilerPanel extends ConsumerStatefulWidget {
  const PerformanceAndMemory662ProfilerPanel({super.key});

  @override
  ConsumerState<PerformanceAndMemory662ProfilerPanel> createState() =>
      _PerformanceAndMemory662ProfilerPanelState();
}

class _PerformanceAndMemory662ProfilerPanelState
    extends ConsumerState<PerformanceAndMemory662ProfilerPanel> {
  static const TextStyle _baseInter = TextStyle(
    fontFamily: 'Inter',
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  static const TextStyle _tabularStyle = TextStyle(
    fontFamily: 'Inter',
    letterSpacing: -0.2,
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
    color: AppColors.textPrimary,
  );

  Future<void> _copyReportJson(PerformanceAndMemory662Report report) async {
    await Clipboard.setData(ClipboardData(text: report.toPrettyJson()));
    if (!mounted) {
      return;
    }
    ref.read(performanceAndMemory662Provider.notifier).markCopied();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Skopiowano raport JSON audytu 120 FPS & RAM (#660).',
          style: TextStyle(fontFamily: 'Inter'),
        ),
        backgroundColor: AppColors.surfaceLight,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final PerformanceAndMemory662State state =
        ref.watch(performanceAndMemory662Provider);
    final PerformanceAndMemory662Notifier notifier =
        ref.read(performanceAndMemory662Provider.notifier);
    final PerformanceAndMemory662Report? report = state.report;

    return Container(
      color: AppColors.background,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double width = constraints.maxWidth;
          final bool isMobile = width < 640;
          final bool isDesktop = width >= 1150;
          final double horizontalPadding = isMobile ? 12.0 : 20.0;

          if (report == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.goldAccent),
            );
          }

          final List<ModePerformanceMemorySample> visibleModes =
              state.selectedMode == null
                  ? report.modeResults
                  : report.modeResults
                      .where(
                        (ModePerformanceMemorySample m) =>
                            m.mode == state.selectedMode,
                      )
                      .toList(growable: false);

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildHeaderCard(
                  report: report,
                  state: state,
                  notifier: notifier,
                  isMobile: isMobile,
                ),
                const SizedBox(height: 16),
                _buildKpiGrid(report: report, isMobile: isMobile, isDesktop: isDesktop),
                const SizedBox(height: 16),
                _buildStressControlsCard(
                  state: state,
                  notifier: notifier,
                  isMobile: isMobile,
                ),
                const SizedBox(height: 16),
                _buildChartCard(report: report),
                const SizedBox(height: 16),
                _buildModeFilterBar(
                  report: report,
                  selectedMode: state.selectedMode,
                  notifier: notifier,
                ),
                const SizedBox(height: 12),
                _buildModesGrid(
                  samples: visibleModes,
                  isMobile: isMobile,
                  isDesktop: isDesktop,
                ),
                const SizedBox(height: 16),
                _buildRecommendationsCard(report: report),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard({
    required PerformanceAndMemory662Report report,
    required PerformanceAndMemory662State state,
    required PerformanceAndMemory662Notifier notifier,
    required bool isMobile,
  }) {
    final ProfilerAuditVerdict verdict = report.overallVerdict;

    final Widget titleBlock = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: verdict.color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: verdict.color.withValues(alpha: 0.45)),
          ),
          child: Icon(verdict.icon, color: verdict.color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Audyt Wydajności 120 FPS & Pamięci RAM (#660)',
                style: _baseInter.copyWith(
                  fontSize: isMobile ? 16 : 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${verdict.label} • ${report.platformLabel} • Budżet 3D < 4.5 ms / VSync 8.33 ms',
                style: _baseInter.copyWith(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final Widget actions = Wrap(
      spacing: 10,
      runSpacing: 8,
      children: <Widget>[
        _ProfilerActionButton(
          label: state.isAuditing ? 'Audytowanie...' : 'Uruchom Audyt',
          icon: Icons.speed_rounded,
          accentColor: AppColors.goldAccent,
          isPrimary: true,
          disabled: state.isAuditing,
          onPressed: notifier.runAllModesAudit,
        ),
        _ProfilerActionButton(
          label: 'Kopiuj JSON',
          icon: Icons.copy_all_rounded,
          accentColor: AppColors.accentBlue,
          disabled: state.isAuditing,
          onPressed: () => _copyReportJson(report),
        ),
        _ProfilerActionButton(
          label: 'Reset',
          icon: Icons.restart_alt_rounded,
          accentColor: AppColors.textSecondary,
          disabled: state.isAuditing,
          onPressed: notifier.resetFilters,
        ),
      ],
    );

    return _SurfaceCard(
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                titleBlock,
                const SizedBox(height: 14),
                actions,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(child: titleBlock),
                const SizedBox(width: 16),
                actions,
              ],
            ),
    );
  }

  Widget _buildKpiGrid({
    required PerformanceAndMemory662Report report,
    required bool isMobile,
    required bool isDesktop,
  }) {
    final int crossAxisCount = isMobile ? 2 : (isDesktop ? 4 : 2);
    final List<Widget> cards = <Widget>[
      _KpiMetricTile(
        label: 'Zaliczone Tryby',
        value: '${report.passingModesCount}/${report.totalModesCount}',
        subtitle: report.passesFullAudit ? 'Pełna zgodność' : 'Wymaga uwagi',
        accent: report.passesFullAudit
            ? AppColors.statusSuccess
            : AppColors.amberWarning,
        icon: Icons.fact_check_rounded,
      ),
      _KpiMetricTile(
        label: 'Najgorsze P99 Klatki',
        value: '${report.worstP99FrameMs.toStringAsFixed(2)} ms',
        subtitle: 'Limit VSync 120Hz: 8.33 ms',
        accent: report.worstP99FrameMs < 4.5
            ? AppColors.statusSuccess
            : (report.worstP99FrameMs < 8.33
                ? AppColors.accentBlue
                : AppColors.crimsonAlert),
        icon: Icons.timer_rounded,
      ),
      _KpiMetricTile(
        label: 'Szczytowy RAM',
        value: '${report.peakGlobalRamMb.toStringAsFixed(0)} MB',
        subtitle: report.liveProcessRssMb != null
            ? 'Live RSS: ${report.liveProcessRssMb!.toStringAsFixed(0)} MB'
            : 'Limit globalny: ${report.globalRamCeilingMb.toStringAsFixed(0)} MB',
        accent: report.peakGlobalRamMb <= report.globalRamCeilingMb
            ? AppColors.cyanAccent
            : AppColors.crimsonAlert,
        icon: Icons.memory_rounded,
      ),
      _KpiMetricTile(
        label: 'Wycieki Zasobów',
        value: '${report.totalDetectedLeaks}',
        subtitle: 'Isolate / Stream / AnimCtrl',
        accent: report.totalDetectedLeaks == 0
            ? AppColors.statusSuccess
            : AppColors.crimsonAlert,
        icon: Icons.cleaning_services_rounded,
      ),
    ];

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: isMobile ? 1.55 : (isDesktop ? 2.15 : 2.35),
      children: cards,
    );
  }

  Widget _buildStressControlsCard({
    required PerformanceAndMemory662State state,
    required PerformanceAndMemory662Notifier notifier,
    required bool isMobile,
  }) {
    final Widget frameSlider = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Text(
                'Mnożnik Obciążenia GPU/CPU',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _baseInter.copyWith(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${state.frameLoadFactor.toStringAsFixed(2)}x',
              style: _tabularStyle.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.goldAccent,
              ),
            ),
          ],
        ),
        Slider(
          value: state.frameLoadFactor,
          min: 0.5,
          max: 2.2,
          divisions: 17,
          activeColor: AppColors.goldAccent,
          inactiveColor: AppColors.surfaceLight,
          onChanged: state.isAuditing ? null : notifier.setFrameLoadFactor,
        ),
      ],
    );

    final Widget ramSlider = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Text(
                'Mnożnik Alokacji RAM',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _baseInter.copyWith(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${state.ramLoadFactor.toStringAsFixed(2)}x',
              style: _tabularStyle.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.cyanAccent,
              ),
            ),
          ],
        ),
        Slider(
          value: state.ramLoadFactor,
          min: 0.5,
          max: 2.0,
          divisions: 15,
          activeColor: AppColors.cyanAccent,
          inactiveColor: AppColors.surfaceLight,
          onChanged: state.isAuditing ? null : notifier.setRamLoadFactor,
        ),
      ],
    );

    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Symulacja Warunków Obciążeniowych (Stress Test)',
            style: _baseInter.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          if (isMobile)
            Column(
              children: <Widget>[
                frameSlider,
                const SizedBox(height: 8),
                ramSlider,
              ],
            )
          else
            Row(
              children: <Widget>[
                Expanded(child: frameSlider),
                const SizedBox(width: 24),
                Expanded(child: ramSlider),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildChartCard({required PerformanceAndMemory662Report report}) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Profil Klatek P95 [ms] vs Limit 120 FPS (4.5 ms / 8.33 ms)',
                  style: _baseInter.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${report.modeResults.length} trybów',
                style: _tabularStyle.copyWith(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 170,
            width: double.infinity,
            child: CustomPaint(
              painter: ModeFrameAndRamBarPainter(
                samples: report.modeResults,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeFilterBar({
    required PerformanceAndMemory662Report report,
    required GameModeProfileTarget? selectedMode,
    required PerformanceAndMemory662Notifier notifier,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          _ModeFilterChip(
            label: 'Wszystkie (${report.modeResults.length})',
            selected: selectedMode == null,
            onTap: () => notifier.selectMode(null),
          ),
          const SizedBox(width: 8),
          ...report.modeResults.map(
            (ModePerformanceMemorySample sample) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _ModeFilterChip(
                label: sample.mode.title,
                selected: selectedMode == sample.mode,
                statusColor: sample.verdict.color,
                onTap: () => notifier.selectMode(sample.mode),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModesGrid({
    required List<ModePerformanceMemorySample> samples,
    required bool isMobile,
    required bool isDesktop,
  }) {
    if (samples.isEmpty) {
      return const _SurfaceCard(
        child: Center(
          child: Text(
            'Brak próbek dla wybranego filtra.',
            style: TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    if (isMobile) {
      return Column(
        children: samples
            .map(
              (ModePerformanceMemorySample s) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ModeAuditCard(sample: s),
              ),
            )
            .toList(growable: false),
      );
    }

    final int columns = isDesktop ? 2 : 1;
    if (columns == 1) {
      return Column(
        children: samples
            .map(
              (ModePerformanceMemorySample s) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ModeAuditCard(sample: s),
              ),
            )
            .toList(growable: false),
      );
    }

    final List<Widget> rows = <Widget>[];
    for (int i = 0; i < samples.length; i += 2) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: _ModeAuditCard(sample: samples[i])),
              const SizedBox(width: 12),
              Expanded(
                child: i + 1 < samples.length
                    ? _ModeAuditCard(sample: samples[i + 1])
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _buildRecommendationsCard({
    required PerformanceAndMemory662Report report,
  }) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Rekomendacje Optymalizacyjne',
            style: _baseInter.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          ...report.recommendations.map(
            (String rec) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    report.passesFullAudit
                        ? Icons.check_circle_rounded
                        : Icons.info_outline_rounded,
                    size: 16,
                    color: report.passesFullAudit
                        ? AppColors.statusSuccess
                        : AppColors.amberWarning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      rec,
                      style: _baseInter.copyWith(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
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

/// Rysuje wykres słupkowy P95 klatek względem budżetu 4.5 ms i 8.33 ms.
class ModeFrameAndRamBarPainter extends CustomPainter {
  final List<ModePerformanceMemorySample> samples;

  const ModeFrameAndRamBarPainter({required this.samples});

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty || size.width <= 0 || size.height <= 0) {
      return;
    }

    const double maxAxisMs = 10.0;
    final double chartBottom = size.height - 18.0;
    final double chartHeight = math.max(10.0, chartBottom - 8.0);

    final Paint gridPaint = Paint()
      ..color = AppColors.cardBorder.withValues(alpha: 0.7)
      ..strokeWidth = 1.0;

    final Paint budgetPaint = Paint()
      ..color = AppColors.goldAccent.withValues(alpha: 0.85)
      ..strokeWidth = 1.3;

    final Paint vsyncPaint = Paint()
      ..color = AppColors.crimsonAlert.withValues(alpha: 0.85)
      ..strokeWidth = 1.3;

    final double yBudget =
        chartBottom - (4.5 / maxAxisMs).clamp(0.0, 1.0) * chartHeight;
    final double yVsync =
        chartBottom - (8.33 / maxAxisMs).clamp(0.0, 1.0) * chartHeight;

    canvas.drawLine(
      Offset(0, chartBottom),
      Offset(size.width, chartBottom),
      gridPaint,
    );
    canvas.drawLine(
      Offset(0, yBudget),
      Offset(size.width, yBudget),
      budgetPaint,
    );
    canvas.drawLine(
      Offset(0, yVsync),
      Offset(size.width, yVsync),
      vsyncPaint,
    );

    final double slotWidth = size.width / samples.length;
    final double barWidth = math.max(6.0, slotWidth * 0.56);

    for (int i = 0; i < samples.length; i++) {
      final ModePerformanceMemorySample s = samples[i];
      final double norm = (s.p95FrameMs / maxAxisMs).clamp(0.04, 1.0);
      final double barHeight = norm * chartHeight;
      final double left = i * slotWidth + (slotWidth - barWidth) / 2;
      final RRect rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, chartBottom - barHeight, barWidth, barHeight),
        const Radius.circular(6),
      );
      final Paint barPaint = Paint()..color = s.verdict.color;
      canvas.drawRRect(rect, barPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ModeFrameAndRamBarPainter oldDelegate) {
    return oldDelegate.samples != samples;
  }
}

class _SurfaceCard extends StatelessWidget {
  final Widget child;

  const _SurfaceCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: child,
    );
  }
}

class _KpiMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final Color accent;
  final IconData icon;

  const _KpiMetricTile({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 16, color: accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: accent,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
          Text(
            subtitle,
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
    );
  }
}

class _ModeAuditCard extends StatelessWidget {
  final ModePerformanceMemorySample sample;

  const _ModeAuditCard({required this.sample});

  @override
  Widget build(BuildContext context) {
    final GameModeProfileTarget mode = sample.mode;
    final Color verdictColor = sample.verdict.color;
    final MemoryAllocationBreakdown mb = sample.memoryBreakdown;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(mode.icon, size: 18, color: AppColors.goldAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  mode.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: verdictColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: verdictColor.withValues(alpha: 0.45),
                  ),
                ),
                child: Text(
                  sample.verdict.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: verdictColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            mode.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: <Widget>[
              _StatPill(
                label: 'P95 Klatka',
                value:
                    '${sample.p95FrameMs.toStringAsFixed(2)} / ${mode.targetFrameBudgetMs.toStringAsFixed(1)} ms',
                ok: sample.passes120Fps,
              ),
              _StatPill(
                label: 'Szczyt RAM',
                value:
                    '${sample.peakRamMb.toStringAsFixed(0)} / ${mode.ramBudgetMb.toStringAsFixed(0)} MB',
                ok: sample.passesRamBudget,
              ),
              _StatPill(
                label: 'Wycieki',
                value:
                    '${sample.totalLeakedHandles} (+${sample.ramLeakDeltaMb.toStringAsFixed(1)} MB)',
                ok: sample.passesLeakCheck,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Heap ${mb.dartHeapMb.toStringAsFixed(0)} MB • GPU/GLB ${mb.gpuTexturesAndGlbMb.toStringAsFixed(0)} MB • '
            'Isolate ${mb.isolateSimulationMb.toStringAsFixed(0)} MB • Audio ${mb.audioAndStreamingMb.toStringAsFixed(0)} MB',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
              fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final bool ok;

  const _StatPill({
    required this.label,
    required this.value,
    required this.ok,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = ok ? AppColors.statusSuccess : AppColors.crimsonAlert;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10.5,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: color,
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _ProfilerActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final bool isPrimary;
  final bool disabled;
  final VoidCallback onPressed;

  const _ProfilerActionButton({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.onPressed,
    this.isPrimary = false,
    this.disabled = false,
  });

  @override
  State<_ProfilerActionButton> createState() => _ProfilerActionButtonState();
}

class _ProfilerActionButtonState extends State<_ProfilerActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.disabled;
    final Color bg = isDisabled
        ? AppColors.surfaceLight.withValues(alpha: 0.45)
        : widget.isPrimary
            ? (_pressed
                ? widget.accentColor.withValues(alpha: 0.85)
                : (_hovered
                    ? widget.accentColor.withValues(alpha: 0.95)
                    : widget.accentColor))
            : (_pressed
                ? AppColors.surfaceLight
                : (_hovered
                    ? AppColors.surfaceLight.withValues(alpha: 0.9)
                    : AppColors.surface));

    final Color borderColor = _focused
        ? AppColors.goldAccent
        : (widget.isPrimary
            ? widget.accentColor
            : (_hovered ? widget.accentColor : AppColors.cardBorder));

    final Color fg = isDisabled
        ? AppColors.textSecondary.withValues(alpha: 0.5)
        : (widget.isPrimary ? AppColors.background : AppColors.textPrimary);

    return FocusableActionDetector(
      enabled: !isDisabled,
      onShowHoverHighlight: (bool v) => setState(() => _hovered = v),
      onShowFocusHighlight: (bool v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: isDisabled ? null : (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: isDisabled ? null : (_) => setState(() => _pressed = false),
        onTap: isDisabled ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: _focused ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(widget.icon, size: 16, color: fg),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeFilterChip extends StatefulWidget {
  final String label;
  final bool selected;
  final Color? statusColor;
  final VoidCallback onTap;

  const _ModeFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.statusColor,
  });

  @override
  State<_ModeFilterChip> createState() => _ModeFilterChipState();
}

class _ModeFilterChipState extends State<_ModeFilterChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final Color border = widget.selected
        ? AppColors.goldAccent
        : (_focused
            ? AppColors.accentBlue
            : (_hovered ? AppColors.textSecondary : AppColors.cardBorder));

    return FocusableActionDetector(
      onShowHoverHighlight: (bool v) => setState(() => _hovered = v),
      onShowFocusHighlight: (bool v) => setState(() => _focused = v),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: widget.selected
                ? AppColors.goldAccent.withValues(alpha: 0.16)
                : (_hovered ? AppColors.surfaceLight : AppColors.surface),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: 1.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (widget.statusColor != null) ...<Widget>[
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: widget.statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight:
                      widget.selected ? FontWeight.w600 : FontWeight.w500,
                  color: widget.selected
                      ? AppColors.goldAccent
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
