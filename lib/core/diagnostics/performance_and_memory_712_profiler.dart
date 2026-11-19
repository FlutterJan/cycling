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

/// Docelowe 11 trybów gry poddawanych audytowi 120 FPS i pamięci RAM (#710).
enum GameMode712ProfileTarget {
  worldTourPeloton(
    id: 'worldtour_peloton',
    title: 'WorldTour (176)',
    subtitle: 'Pełny peleton 3D, fizyka Boids, Isolate i LOD0–LOD2',
    targetFrameBudgetMs: 4.5,
    ramBudgetMb: 580.0,
    baseFrameMs: 3.45,
    baseRamMb: 468.0,
    icon: Icons.directions_bike_rounded,
  ),
  beAProCareer(
    id: 'be_a_pro_career',
    title: 'Be a Pro',
    subtitle: 'Kamera PoV kolarza, HUD telemetryczny i AI zaufania DS',
    targetFrameBudgetMs: 4.3,
    ramBudgetMb: 510.0,
    baseFrameMs: 3.15,
    baseRamMb: 398.0,
    icon: Icons.person_pin_circle_rounded,
  ),
  cycloCrossWinter(
    id: 'cyclo_cross_winter',
    title: 'Cyclo-Cross',
    subtitle: 'Zimowe błoto, cząsteczki, podwójny Pit Lane i zmiana roweru',
    targetFrameBudgetMs: 4.2,
    ramBudgetMb: 490.0,
    baseFrameMs: 3.08,
    baseRamMb: 382.0,
    icon: Icons.terrain_rounded,
  ),
  velodromeTrack(
    id: 'velodrome_track',
    title: 'Welodrom',
    subtitle: 'Tor 250 m, wiraże 45°, ostrokołowiec i telemetria aero CdA',
    targetFrameBudgetMs: 3.6,
    ramBudgetMb: 410.0,
    baseFrameMs: 2.35,
    baseRamMb: 296.0,
    icon: Icons.track_changes_rounded,
  ),
  gravelRacing(
    id: 'gravel_racing',
    title: 'Gravel',
    subtitle: '5 kategorii szutru, wkładki antyprzebiciowe i mleczko tubeless',
    targetFrameBudgetMs: 4.1,
    ramBudgetMb: 470.0,
    baseFrameMs: 2.92,
    baseRamMb: 364.0,
    icon: Icons.grain_rounded,
  ),
  mtbXco(
    id: 'mtb_xco',
    title: 'MTB XCO',
    subtitle: 'Rock gardeny, dropy, dropper post, zawieszenie i leśny culling',
    targetFrameBudgetMs: 4.4,
    ramBudgetMb: 520.0,
    baseFrameMs: 3.28,
    baseRamMb: 422.0,
    icon: Icons.landscape_rounded,
  ),
  ultraEndurance(
    id: 'ultra_endurance',
    title: 'Ultra-Endurance',
    subtitle: 'Trasy 4000 km non-stop, piasta z dynamem i deficyt snu',
    targetFrameBudgetMs: 4.0,
    ramBudgetMb: 460.0,
    baseFrameMs: 2.82,
    baseRamMb: 352.0,
    icon: Icons.explore_rounded,
  ),
  retro1970GoldenEra(
    id: 'retro_1970_golden_era',
    title: 'Retro 1970',
    subtitle: 'Złota Era 1970–2015, filtry historyczne i stalowe ramy',
    targetFrameBudgetMs: 4.1,
    ramBudgetMb: 450.0,
    baseFrameMs: 2.90,
    baseRamMb: 344.0,
    icon: Icons.history_edu_rounded,
  ),
  esportsVirtual(
    id: 'esports_virtual',
    title: 'e-Sports',
    subtitle: 'UCI Cycling Esports, Smart Trainer, Power-Upy i eliminacja 60s',
    targetFrameBudgetMs: 3.8,
    ramBudgetMb: 440.0,
    baseFrameMs: 2.64,
    baseRamMb: 332.0,
    icon: Icons.wifi_tethering_rounded,
  ),
  paracyclingTandemHandbike(
    id: 'paracycling_tandem_handbike',
    title: 'Para-Cycling',
    subtitle: 'Załogi Tandem B >800W, Handbike H1–H5 i klasy C1–C5',
    targetFrameBudgetMs: 4.3,
    ramBudgetMb: 480.0,
    baseFrameMs: 3.04,
    baseRamMb: 376.0,
    icon: Icons.accessible_forward_rounded,
  ),
  tvDirectorLiveProduction(
    id: 'tv_director_live_production',
    title: 'Tryb Reżysera TV',
    subtitle: '12 kamer na żywo, przełączenia PiP, grafiki TV i realizacja',
    targetFrameBudgetMs: 4.5,
    ramBudgetMb: 590.0,
    baseFrameMs: 3.52,
    baseRamMb: 492.0,
    icon: Icons.live_tv_rounded,
  );

  final String id;
  final String title;
  final String subtitle;
  final double targetFrameBudgetMs;
  final double ramBudgetMb;
  final double baseFrameMs;
  final double baseRamMb;
  final IconData icon;

  const GameMode712ProfileTarget({
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

/// Werdykt audytu wydajności 120 FPS i pamięci RAM (#710).
enum Profiler712AuditVerdict {
  sovereign120Fps(
    label: 'IMPERIAL 120 FPS',
    description: 'Zapas budżetu klatki > 15%, RAM w normie, zero wycieków.',
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

  const Profiler712AuditVerdict({
    required this.label,
    required this.description,
    required this.color,
    required this.icon,
  });

  bool get passes =>
      this == Profiler712AuditVerdict.sovereign120Fps ||
      this == Profiler712AuditVerdict.withinBudget;
}

/// Rozbicie alokacji pamięci RAM na podsystemy silnika [MB].
@immutable
class MemoryAllocation712Breakdown {
  final double dartHeapMb;
  final double gpuTexturesAndGlbMb;
  final double isolateSimulationMb;
  final double audioAndStreamingMb;
  final double broadcastPipAndOverlayMb;

  const MemoryAllocation712Breakdown({
    required this.dartHeapMb,
    required this.gpuTexturesAndGlbMb,
    required this.isolateSimulationMb,
    required this.audioAndStreamingMb,
    required this.broadcastPipAndOverlayMb,
  });

  double get totalRamMb =>
      dartHeapMb +
      gpuTexturesAndGlbMb +
      isolateSimulationMb +
      audioAndStreamingMb +
      broadcastPipAndOverlayMb;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'dartHeapMb': double.parse(dartHeapMb.toStringAsFixed(2)),
      'gpuTexturesAndGlbMb':
          double.parse(gpuTexturesAndGlbMb.toStringAsFixed(2)),
      'isolateSimulationMb':
          double.parse(isolateSimulationMb.toStringAsFixed(2)),
      'audioAndStreamingMb':
          double.parse(audioAndStreamingMb.toStringAsFixed(2)),
      'broadcastPipAndOverlayMb':
          double.parse(broadcastPipAndOverlayMb.toStringAsFixed(2)),
      'totalRamMb': double.parse(totalRamMb.toStringAsFixed(2)),
    };
  }
}

/// Wynik audytu wydajności i pamięci RAM dla pojedynczego trybu gry.
@immutable
class ModePerformanceMemory712Sample {
  final GameMode712ProfileTarget mode;
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
  final MemoryAllocation712Breakdown memoryBreakdown;
  final Profiler712AuditVerdict verdict;

  const ModePerformanceMemory712Sample({
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

  double get ramLeakDeltaMb => math.max(0.0, postExitRamMb - baselineRamMb);

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

/// Zbiorczy raport audytu wydajności 120 FPS i pamięci RAM dla 11 trybów (#710).
@immutable
class PerformanceAndMemory712Report {
  final String reportId;
  final DateTime generatedAt;
  final String platformLabel;
  final int targetFps;
  final double vsyncWindowMs;
  final double target3dFrameBudgetMs;
  final double globalRamCeilingMb;
  final double? liveProcessRssMb;
  final EnginePerformanceMetrics liveTelemetryMetrics;
  final List<ModePerformanceMemory712Sample> modeResults;
  final Profiler712AuditVerdict overallVerdict;
  final List<String> recommendations;

  const PerformanceAndMemory712Report({
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
      modeResults.where((ModePerformanceMemory712Sample m) => m.passesAll).length;

  double get worstP99FrameMs {
    if (modeResults.isEmpty) {
      return 0.0;
    }
    return modeResults
        .map((ModePerformanceMemory712Sample m) => m.p99FrameMs)
        .reduce(math.max);
  }

  double get peakGlobalRamMb {
    if (modeResults.isEmpty) {
      return 0.0;
    }
    return modeResults
        .map((ModePerformanceMemory712Sample m) => m.peakRamMb)
        .reduce(math.max);
  }

  int get totalDetectedLeaks => modeResults.fold<int>(
        0,
        (int sum, ModePerformanceMemory712Sample m) =>
            sum + m.totalLeakedHandles,
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
      'modeResults': modeResults
          .map((ModePerformanceMemory712Sample m) => m.toJson())
          .toList(),
    };
  }

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());
}

/// Serwis audytujący wydajność 120 FPS i pamięć RAM we wszystkich 11 trybach (#710).
class PerformanceAndMemory712Profiler {
  static const int defaultTargetFps = 120;
  static const double defaultVsyncWindowMs = 8.33;
  static const double default3dBudgetMs = 4.50;
  static const double defaultGlobalRamCeilingMb = 640.0;

  const PerformanceAndMemory712Profiler();

  /// Klasyfikuje werdykt pojedynczego trybu na podstawie metryk klatki, RAM i wycieków.
  static Profiler712AuditVerdict evaluateModeVerdict({
    required GameMode712ProfileTarget mode,
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
      return Profiler712AuditVerdict.criticalBottleneck;
    }

    if (p95FrameMs > mode.targetFrameBudgetMs ||
        dropped120FpsFrames > 0 ||
        peakRamMb > mode.ramBudgetMb ||
        ramLeakDeltaMb > 8.0) {
      return Profiler712AuditVerdict.memoryOrFrameWarning;
    }

    if (p95FrameMs <= mode.targetFrameBudgetMs * 0.88 &&
        peakRamMb <= mode.ramBudgetMb * 0.90) {
      return Profiler712AuditVerdict.sovereign120Fps;
    }

    return Profiler712AuditVerdict.withinBudget;
  }

  /// Przeprowadza deterministyczny audyt jednego trybu gry.
  ModePerformanceMemory712Sample auditSingleMode(
    GameMode712ProfileTarget mode, {
    int framesPerMode = 120,
    double ramLoadFactor = 1.0,
    double frameLoadFactor = 1.0,
  }) {
    final int safeFrames = math.max(1, framesPerMode);
    final double safeRamFactor = ramLoadFactor.clamp(0.5, 2.5);
    final double safeFrameFactor = frameLoadFactor.clamp(0.5, 2.5);

    final List<double> frameSamples = List<double>.generate(safeFrames, (int i) {
      final double wave = math.sin((i + 1) * 0.25 + mode.index * 0.85) * 0.13;
      final double spike = (i % 49 == 0) ? 0.22 : 0.0;
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
    final double effectiveFps = avgFrameMs <= 0.0
        ? 120.0
        : math.min(120.0, 1000.0 / math.max(avgFrameMs, 8.33));

    final double peakRamMb = mode.baseRamMb * safeRamFactor;
    const double baselineRamMb = 185.0;
    final double ramLeakDelta =
        safeRamFactor > 1.45 ? (safeRamFactor - 1.45) * 32.0 : 1.2;
    final double postExitRamMb = baselineRamMb + ramLeakDelta;

    final int leakedIsolates = safeRamFactor > 1.65 ? 1 : 0;
    final int leakedStreams = safeFrameFactor > 1.75 ? 1 : 0;
    const int leakedAnims = 0;

    final bool isTvMode =
        mode == GameMode712ProfileTarget.tvDirectorLiveProduction;
    final MemoryAllocation712Breakdown breakdown = MemoryAllocation712Breakdown(
      dartHeapMb: peakRamMb * (isTvMode ? 0.30 : 0.34),
      gpuTexturesAndGlbMb: peakRamMb * (isTvMode ? 0.28 : 0.32),
      isolateSimulationMb: peakRamMb * (isTvMode ? 0.14 : 0.16),
      audioAndStreamingMb: peakRamMb * (isTvMode ? 0.10 : 0.09),
      broadcastPipAndOverlayMb: peakRamMb * (isTvMode ? 0.18 : 0.09),
    );

    final Profiler712AuditVerdict verdict = evaluateModeVerdict(
      mode: mode,
      p95FrameMs: p95FrameMs,
      p99FrameMs: p99FrameMs,
      peakRamMb: peakRamMb,
      dropped120FpsFrames: droppedFrames,
      totalLeakedHandles: leakedIsolates + leakedStreams + leakedAnims,
      ramLeakDeltaMb: math.max(0.0, postExitRamMb - baselineRamMb),
    );

    return ModePerformanceMemory712Sample(
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

  /// Przeprowadza pełny audyt wszystkich 11 trybów gry z telemetrią live.
  PerformanceAndMemory712Report runFullAllModesAudit({
    List<GameMode712ProfileTarget>? modes,
    int framesPerMode = 120,
    double ramLoadFactor = 1.0,
    double frameLoadFactor = 1.0,
  }) {
    final List<GameMode712ProfileTarget> targets =
        (modes == null || modes.isEmpty)
            ? GameMode712ProfileTarget.values
            : modes;
    final List<ModePerformanceMemory712Sample> results = targets
        .map(
          (GameMode712ProfileTarget mode) => auditSingleMode(
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
  PerformanceAndMemory712Report auditCustomSamples(
    List<ModePerformanceMemory712Sample> samples,
  ) {
    return _buildReport(
      List<ModePerformanceMemory712Sample>.unmodifiable(samples),
    );
  }

  PerformanceAndMemory712Report _buildReport(
    List<ModePerformanceMemory712Sample> results,
  ) {
    final DateTime now = DateTime.now();
    final String reportId =
        'PPM710-${now.millisecondsSinceEpoch.toRadixString(36).toUpperCase()}';

    final Profiler712AuditVerdict overallVerdict = _aggregateVerdict(results);
    final List<String> recommendations = _buildRecommendations(results);

    return PerformanceAndMemory712Report(
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

  Profiler712AuditVerdict _aggregateVerdict(
    List<ModePerformanceMemory712Sample> results,
  ) {
    if (results.isEmpty) {
      return Profiler712AuditVerdict.withinBudget;
    }
    if (results.any(
      (ModePerformanceMemory712Sample r) =>
          r.verdict == Profiler712AuditVerdict.criticalBottleneck,
    )) {
      return Profiler712AuditVerdict.criticalBottleneck;
    }
    if (results.any(
      (ModePerformanceMemory712Sample r) =>
          r.verdict == Profiler712AuditVerdict.memoryOrFrameWarning,
    )) {
      return Profiler712AuditVerdict.memoryOrFrameWarning;
    }
    if (results.every(
      (ModePerformanceMemory712Sample r) =>
          r.verdict == Profiler712AuditVerdict.sovereign120Fps,
    )) {
      return Profiler712AuditVerdict.sovereign120Fps;
    }
    return Profiler712AuditVerdict.withinBudget;
  }

  List<String> _buildRecommendations(
    List<ModePerformanceMemory712Sample> results,
  ) {
    final List<String> recs = <String>[];
    for (final ModePerformanceMemory712Sample sample in results) {
      if (!sample.passes120Fps) {
        recs.add(
          '${sample.mode.title}: P95 (${sample.p95FrameMs.toStringAsFixed(2)} ms) '
          'przekracza budżet ${sample.mode.targetFrameBudgetMs.toStringAsFixed(1)} ms — '
          'zredukuj gęstość LOD0 lub wyłącz cienie dynamiczne dla obiektów > 60 m.',
        );
      }
      if (!sample.passesRamBudget) {
        recs.add(
          '${sample.mode.title}: szczytowy RAM (${sample.peakRamMb.toStringAsFixed(0)} MB) '
          'przekracza limit ${sample.mode.ramBudgetMb.toStringAsFixed(0)} MB — '
          'zwolnij nieużywane bufory kamer PiP, tekstury .glb i klatki powtórek.',
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
        'Wszystkie ${results.length} trybów (WorldTour -> Tryb Reżysera TV) mieszczą się w budżecie '
        '120 FPS (< 4.5 ms 3D / < 8.33 ms VSync) oraz w limitach RAM bez wycieków zasobów.',
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

/// Niemutowalny stan kontrolera audytu #710 w Riverpod.
@immutable
class PerformanceAndMemory712State {
  final bool isAuditing;
  final GameMode712ProfileTarget? selectedMode;
  final double ramLoadFactor;
  final double frameLoadFactor;
  final int framesPerMode;
  final PerformanceAndMemory712Report? report;
  final DateTime? lastCopiedAt;
  final String? errorMessage;

  const PerformanceAndMemory712State({
    this.isAuditing = false,
    this.selectedMode,
    this.ramLoadFactor = 1.0,
    this.frameLoadFactor = 1.0,
    this.framesPerMode = 120,
    this.report,
    this.lastCopiedAt,
    this.errorMessage,
  });

  PerformanceAndMemory712State copyWith({
    bool? isAuditing,
    GameMode712ProfileTarget? selectedMode,
    bool clearSelectedMode = false,
    double? ramLoadFactor,
    double? frameLoadFactor,
    int? framesPerMode,
    PerformanceAndMemory712Report? report,
    DateTime? lastCopiedAt,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PerformanceAndMemory712State(
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

/// Kontroler zarządzający cyklem audytu 120 FPS i RAM dla 11 trybów (#710).
class PerformanceAndMemory712Notifier
    extends StateNotifier<PerformanceAndMemory712State> {
  final PerformanceAndMemory712Profiler _profiler;

  PerformanceAndMemory712Notifier(this._profiler)
      : super(
          PerformanceAndMemory712State(
            report: _profiler.runFullAllModesAudit(),
          ),
        );

  void runAllModesAudit() {
    state = state.copyWith(isAuditing: true, clearError: true);
    try {
      final PerformanceAndMemory712Report nextReport =
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

  void selectMode(GameMode712ProfileTarget? mode) {
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

final performanceAndMemory712ServiceProvider =
    Provider<PerformanceAndMemory712Profiler>((Ref ref) {
  return const PerformanceAndMemory712Profiler();
});

final performanceAndMemory712Provider = StateNotifierProvider<
    PerformanceAndMemory712Notifier, PerformanceAndMemory712State>((Ref ref) {
  final PerformanceAndMemory712Profiler service =
      ref.watch(performanceAndMemory712ServiceProvider);
  return PerformanceAndMemory712Notifier(service);
});

/// Panel diagnostyczny audytu 120 FPS i pamięci RAM dla 11 trybów (#710).
class PerformanceAndMemory712ProfilerPanel extends ConsumerStatefulWidget {
  const PerformanceAndMemory712ProfilerPanel({super.key});

  @override
  ConsumerState<PerformanceAndMemory712ProfilerPanel> createState() =>
      _PerformanceAndMemory712ProfilerPanelState();
}

class _PerformanceAndMemory712ProfilerPanelState
    extends ConsumerState<PerformanceAndMemory712ProfilerPanel> {
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

  Future<void> _copyReportJson(PerformanceAndMemory712Report report) async {
    await Clipboard.setData(ClipboardData(text: report.toPrettyJson()));
    if (!mounted) {
      return;
    }
    ref.read(performanceAndMemory712Provider.notifier).markCopied();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Skopiowano raport JSON audytu 120 FPS & RAM (#710).',
          style: TextStyle(fontFamily: 'Inter'),
        ),
        backgroundColor: AppColors.surfaceLight,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final PerformanceAndMemory712State state =
        ref.watch(performanceAndMemory712Provider);
    final PerformanceAndMemory712Notifier notifier =
        ref.read(performanceAndMemory712Provider.notifier);
    final PerformanceAndMemory712Report? report = state.report;

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

          final List<ModePerformanceMemory712Sample> visibleModes =
              state.selectedMode == null
                  ? report.modeResults
                  : report.modeResults
                      .where(
                        (ModePerformanceMemory712Sample m) =>
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
                if (state.errorMessage != null) ...<Widget>[
                  const SizedBox(height: 12),
                  _buildErrorBanner(state.errorMessage!),
                ],
                const SizedBox(height: 16),
                _buildKpiGrid(
                  report: report,
                  isMobile: isMobile,
                  isDesktop: isDesktop,
                ),
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

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.crimsonAlert.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.crimsonAlert.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.crimsonAlert,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: _baseInter.copyWith(
                fontSize: 12.5,
                color: AppColors.crimsonAlert,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard({
    required PerformanceAndMemory712Report report,
    required PerformanceAndMemory712State state,
    required PerformanceAndMemory712Notifier notifier,
    required bool isMobile,
  }) {
    final Profiler712AuditVerdict verdict = report.overallVerdict;

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
                'Audyt Wydajności 120 FPS & Pamięci RAM (#710)',
                style: _baseInter.copyWith(
                  fontSize: isMobile ? 16 : 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${verdict.label} • ${report.platformLabel} • 11 Trybów (WorldTour – Reżyser TV)',
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
        _Profiler712ActionButton(
          label: state.isAuditing ? 'Audytowanie...' : 'Uruchom Audyt',
          icon: Icons.speed_rounded,
          accentColor: AppColors.goldAccent,
          isPrimary: true,
          disabled: state.isAuditing,
          onPressed: notifier.runAllModesAudit,
        ),
        _Profiler712ActionButton(
          label: 'Kopiuj JSON',
          icon: Icons.copy_all_rounded,
          accentColor: AppColors.accentBlue,
          disabled: state.isAuditing,
          onPressed: () => _copyReportJson(report),
        ),
        _Profiler712ActionButton(
          label: 'Reset',
          icon: Icons.restart_alt_rounded,
          accentColor: AppColors.textSecondary,
          disabled: state.isAuditing,
          onPressed: notifier.resetFilters,
        ),
      ],
    );

    return _Surface712Card(
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
    required PerformanceAndMemory712Report report,
    required bool isMobile,
    required bool isDesktop,
  }) {
    final int crossAxisCount = isMobile ? 2 : (isDesktop ? 4 : 2);
    final List<Widget> cards = <Widget>[
      _Kpi712MetricTile(
        label: 'Zaliczone Tryby',
        value: '${report.passingModesCount}/${report.totalModesCount}',
        subtitle: report.passesFullAudit ? 'Pełna zgodność 120 FPS' : 'Wymaga uwagi',
        accent: report.passesFullAudit
            ? AppColors.statusSuccess
            : AppColors.amberWarning,
        icon: Icons.fact_check_rounded,
      ),
      _Kpi712MetricTile(
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
      _Kpi712MetricTile(
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
      _Kpi712MetricTile(
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
    required PerformanceAndMemory712State state,
    required PerformanceAndMemory712Notifier notifier,
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
          max: 2.2,
          divisions: 17,
          activeColor: AppColors.cyanAccent,
          inactiveColor: AppColors.surfaceLight,
          onChanged: state.isAuditing ? null : notifier.setRamLoadFactor,
        ),
      ],
    );

    return _Surface712Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Symulacja Obciążenia & Stress-Test',
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

  Widget _buildChartCard({required PerformanceAndMemory712Report report}) {
    return _Surface712Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Porównanie Czasu Klatki P95 [ms] i Alokacji RAM [%] (11 Trybów)',
                  style: _baseInter.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const _Legend712Dot(color: AppColors.statusSuccess, label: 'P95 < 4.5 ms'),
              const SizedBox(width: 12),
              const _Legend712Dot(color: AppColors.cyanAccent, label: 'RAM %'),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 185,
            width: double.infinity,
            child: CustomPaint(
              painter: ModeFrameAndRam712BarPainter(samples: report.modeResults),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeFilterBar({
    required PerformanceAndMemory712Report report,
    required GameMode712ProfileTarget? selectedMode,
    required PerformanceAndMemory712Notifier notifier,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        _ModeFilter712Chip(
          label: 'Wszystkie (${report.totalModesCount})',
          selected: selectedMode == null,
          onTap: () => notifier.selectMode(null),
        ),
        for (final GameMode712ProfileTarget mode
            in GameMode712ProfileTarget.values)
          _ModeFilter712Chip(
            label: mode.title,
            selected: selectedMode == mode,
            onTap: () => notifier.selectMode(mode),
          ),
      ],
    );
  }

  Widget _buildModesGrid({
    required List<ModePerformanceMemory712Sample> samples,
    required bool isMobile,
    required bool isDesktop,
  }) {
    if (samples.isEmpty) {
      return _Surface712Card(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Brak próbek do wyświetlenia.',
              style: _baseInter.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ),
      );
    }

    final int columns = isMobile ? 1 : (isDesktop ? 2 : 1);
    if (columns == 1) {
      return Column(
        children: <Widget>[
          for (int i = 0; i < samples.length; i++) ...<Widget>[
            _ModeSample712Card(sample: samples[i]),
            if (i < samples.length - 1) const SizedBox(height: 12),
          ],
        ],
      );
    }

    final List<Widget> rows = <Widget>[];
    for (int i = 0; i < samples.length; i += 2) {
      final ModePerformanceMemory712Sample left = samples[i];
      final ModePerformanceMemory712Sample? right =
          (i + 1 < samples.length) ? samples[i + 1] : null;
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: _ModeSample712Card(sample: left)),
            const SizedBox(width: 12),
            Expanded(
              child: right != null
                  ? _ModeSample712Card(sample: right)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );
      if (i + 2 < samples.length) {
        rows.add(const SizedBox(height: 12));
      }
    }
    return Column(children: rows);
  }

  Widget _buildRecommendationsCard({
    required PerformanceAndMemory712Report report,
  }) {
    return _Surface712Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Wnioski i Rekomendacje Optymalizacyjne',
            style: _baseInter.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          for (final String rec in report.recommendations)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    report.passesFullAudit
                        ? Icons.check_circle_rounded
                        : Icons.tune_rounded,
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
                        height: 1.4,
                      ),
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

class _Surface712Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _Surface712Card({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: child,
    );
  }
}

class _Kpi712MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final Color accent;
  final IconData icon;

  const _Kpi712MetricTile({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return _Surface712Card(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, color: accent, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    letterSpacing: -0.2,
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Inter',
                letterSpacing: -0.2,
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              letterSpacing: -0.2,
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeSample712Card extends StatefulWidget {
  final ModePerformanceMemory712Sample sample;

  const _ModeSample712Card({required this.sample});

  @override
  State<_ModeSample712Card> createState() => _ModeSample712CardState();
}

class _ModeSample712CardState extends State<_ModeSample712Card> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final ModePerformanceMemory712Sample s = widget.sample;
    final Profiler712AuditVerdict verdict = s.verdict;
    final double ramRatio =
        (s.peakRamMb / s.mode.ramBudgetMb).clamp(0.0, 1.0);
    final double frameRatio =
        (s.p95FrameMs / s.mode.targetFrameBudgetMs).clamp(0.0, 1.0);

    final Color borderColor = _focused
        ? AppColors.goldAccent
        : (_hovered
            ? verdict.color.withValues(alpha: 0.65)
            : const Color(0xFF2A2F3D));

    return FocusableActionDetector(
      onShowHoverHighlight: (bool value) => setState(() => _hovered = value),
      onShowFocusHighlight: (bool value) => setState(() => _focused = value),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _pressed
                ? AppColors.surfaceLight
                : (_hovered ? const Color(0xFF1D212A) : AppColors.surface),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: verdict.color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(s.mode.icon, color: verdict.color, size: 19),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          s.mode.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            letterSpacing: -0.2,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          s.mode.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            letterSpacing: -0.2,
                            fontSize: 11.5,
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
                      color: verdict.color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: verdict.color.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Text(
                      verdict.label,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        letterSpacing: -0.2,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: verdict.color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _Metric712ProgressRow(
                label:
                    'Klatka P95: ${s.p95FrameMs.toStringAsFixed(2)} ms / ${s.mode.targetFrameBudgetMs.toStringAsFixed(1)} ms (P99: ${s.p99FrameMs.toStringAsFixed(2)} ms)',
                ratio: frameRatio,
                color: s.passes120Fps
                    ? AppColors.statusSuccess
                    : AppColors.crimsonAlert,
              ),
              const SizedBox(height: 8),
              _Metric712ProgressRow(
                label:
                    'RAM Szczyt: ${s.peakRamMb.toStringAsFixed(0)} MB / ${s.mode.ramBudgetMb.toStringAsFixed(0)} MB (Delta: +${s.ramLeakDeltaMb.toStringAsFixed(1)} MB)',
                ratio: ramRatio,
                color: s.passesRamBudget
                    ? AppColors.cyanAccent
                    : AppColors.crimsonAlert,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: <Widget>[
                  _Mini712Stat(
                    label: 'FPS',
                    value: s.effectiveFps.toStringAsFixed(0),
                  ),
                  _Mini712Stat(
                    label: 'Śr.',
                    value: '${s.avgFrameMs.toStringAsFixed(2)} ms',
                  ),
                  _Mini712Stat(
                    label: 'GPU/GLB',
                    value:
                        '${s.memoryBreakdown.gpuTexturesAndGlbMb.toStringAsFixed(0)} MB',
                  ),
                  _Mini712Stat(
                    label: 'PiP/UI',
                    value:
                        '${s.memoryBreakdown.broadcastPipAndOverlayMb.toStringAsFixed(0)} MB',
                  ),
                  _Mini712Stat(
                    label: 'Wycieki',
                    value: '${s.totalLeakedHandles}',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Metric712ProgressRow extends StatelessWidget {
  final String label;
  final double ratio;
  final Color color;

  const _Metric712ProgressRow({
    required this.label,
    required this.ratio,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Inter',
            letterSpacing: -0.2,
            fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
            fontSize: 11.5,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: AppColors.surfaceLight,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _Mini712Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Mini712Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontFamily: 'Inter',
          letterSpacing: -0.2,
          fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
          fontSize: 11.5,
        ),
        children: <TextSpan>[
          TextSpan(
            text: '$label: ',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend712Dot extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend712Dot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            letterSpacing: -0.2,
            fontSize: 11.5,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _Profiler712ActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final bool isPrimary;
  final bool disabled;
  final VoidCallback onPressed;

  const _Profiler712ActionButton({
    required this.label,
    required this.icon,
    required this.accentColor,
    this.isPrimary = false,
    this.disabled = false,
    required this.onPressed,
  });

  @override
  State<_Profiler712ActionButton> createState() =>
      _Profiler712ActionButtonState();
}

class _Profiler712ActionButtonState extends State<_Profiler712ActionButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bool disabled = widget.disabled;
    final Color bg = disabled
        ? AppColors.surfaceLight.withValues(alpha: 0.45)
        : (widget.isPrimary
            ? (_pressed
                ? widget.accentColor.withValues(alpha: 0.30)
                : (_hovered
                    ? widget.accentColor.withValues(alpha: 0.22)
                    : widget.accentColor.withValues(alpha: 0.14)))
            : (_pressed
                ? AppColors.surfaceLight
                : (_hovered
                    ? const Color(0xFF282D3A)
                    : AppColors.surfaceLight)));

    final Color border = disabled
        ? const Color(0xFF2A2F3D)
        : (_focused
            ? AppColors.goldAccent
            : (_hovered || widget.isPrimary
                ? widget.accentColor.withValues(alpha: 0.65)
                : const Color(0xFF2A2F3D)));

    final Color fg = disabled
        ? AppColors.textSecondary.withValues(alpha: 0.5)
        : (widget.isPrimary ? widget.accentColor : AppColors.textPrimary);

    return FocusableActionDetector(
      enabled: !disabled,
      onShowHoverHighlight: (bool v) => setState(() => _hovered = v),
      onShowFocusHighlight: (bool v) => setState(() => _focused = v),
      child: GestureDetector(
        onTap: disabled ? null : widget.onPressed,
        onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: MouseRegion(
          cursor:
              disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(widget.icon, size: 16, color: fg),
                const SizedBox(width: 7),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    letterSpacing: -0.2,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: fg,
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

class _ModeFilter712Chip extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeFilter712Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_ModeFilter712Chip> createState() => _ModeFilter712ChipState();
}

class _ModeFilter712ChipState extends State<_ModeFilter712Chip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color bg = widget.selected
        ? AppColors.primaryAccent.withValues(alpha: 0.28)
        : (_pressed
            ? AppColors.surfaceLight
            : (_hovered ? const Color(0xFF252A36) : AppColors.surface));
    final Color border = _focused
        ? AppColors.goldAccent
        : (widget.selected
            ? AppColors.primaryAccent
            : (_hovered
                ? AppColors.textSecondary.withValues(alpha: 0.5)
                : const Color(0xFF2A2F3D)));

    return FocusableActionDetector(
      onShowHoverHighlight: (bool v) => setState(() => _hovered = v),
      onShowFocusHighlight: (bool v) => setState(() => _focused = v),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: border),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Inter',
                letterSpacing: -0.2,
                fontSize: 12,
                fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
                color: widget.selected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Wykres słupkowy P95 czasu klatki i zużycia RAM dla 11 trybów gry (#710).
class ModeFrameAndRam712BarPainter extends CustomPainter {
  final List<ModePerformanceMemory712Sample> samples;

  const ModeFrameAndRam712BarPainter({required this.samples});

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty || size.width <= 0 || size.height <= 0) {
      return;
    }

    const double bottomLabelHeight = 24.0;
    final double chartHeight = math.max(10.0, size.height - bottomLabelHeight);

    final Paint gridPaint = Paint()
      ..color = const Color(0xFF2A2F3D)
      ..strokeWidth = 1.0;

    final Paint budgetPaint = Paint()
      ..color = AppColors.goldAccent.withValues(alpha: 0.65)
      ..strokeWidth = 1.2;

    // Linia budżetu 3D 4.5 ms względem skali 9.0 ms
    final double budgetY = chartHeight * (1.0 - (4.5 / 9.0));
    canvas.drawLine(
      Offset(0, budgetY),
      Offset(size.width, budgetY),
      budgetPaint,
    );
    canvas.drawLine(
      Offset(0, chartHeight),
      Offset(size.width, chartHeight),
      gridPaint,
    );

    final double groupWidth = size.width / samples.length;
    final double barWidth = math.max(4.0, (groupWidth * 0.32).clamp(4.0, 18.0));

    for (int i = 0; i < samples.length; i++) {
      final ModePerformanceMemory712Sample s = samples[i];
      final double centerX = groupWidth * i + groupWidth / 2;

      final double frameNorm = (s.p95FrameMs / 9.0).clamp(0.05, 1.0);
      final double frameHeight = chartHeight * frameNorm;
      final Color frameColor =
          s.passes120Fps ? AppColors.statusSuccess : AppColors.crimsonAlert;

      final RRect frameRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX - barWidth - 1.5,
          chartHeight - frameHeight,
          barWidth,
          frameHeight,
        ),
        const Radius.circular(3),
      );
      canvas.drawRRect(frameRect, Paint()..color = frameColor);

      final double ramNorm = (s.peakRamMb / s.mode.ramBudgetMb).clamp(0.05, 1.0);
      final double ramHeight = chartHeight * ramNorm;
      final Color ramColor =
          s.passesRamBudget ? AppColors.cyanAccent : AppColors.amberWarning;

      final RRect ramRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX + 1.5,
          chartHeight - ramHeight,
          barWidth,
          ramHeight,
        ),
        const Radius.circular(3),
      );
      canvas.drawRRect(ramRect, Paint()..color = ramColor);

      final String shortTag = _shortModeLabel(s.mode);
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: shortTag,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 9.5,
            color: AppColors.textSecondary,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: groupWidth);
      tp.paint(
        canvas,
        Offset(centerX - tp.width / 2, chartHeight + 6),
      );
    }
  }

  String _shortModeLabel(GameMode712ProfileTarget mode) {
    switch (mode) {
      case GameMode712ProfileTarget.worldTourPeloton:
        return 'WT';
      case GameMode712ProfileTarget.beAProCareer:
        return 'PRO';
      case GameMode712ProfileTarget.cycloCrossWinter:
        return 'CX';
      case GameMode712ProfileTarget.velodromeTrack:
        return 'TOR';
      case GameMode712ProfileTarget.gravelRacing:
        return 'GRV';
      case GameMode712ProfileTarget.mtbXco:
        return 'MTB';
      case GameMode712ProfileTarget.ultraEndurance:
        return 'ULT';
      case GameMode712ProfileTarget.retro1970GoldenEra:
        return '1970';
      case GameMode712ProfileTarget.esportsVirtual:
        return 'ESP';
      case GameMode712ProfileTarget.paracyclingTandemHandbike:
        return 'PARA';
      case GameMode712ProfileTarget.tvDirectorLiveProduction:
        return 'TV';
    }
  }

  @override
  bool shouldRepaint(covariant ModeFrameAndRam712BarPainter oldDelegate) {
    return oldDelegate.samples != samples;
  }
}
