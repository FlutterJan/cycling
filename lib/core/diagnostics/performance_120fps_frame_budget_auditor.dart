// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/performance_profiler_overlay.dart';

/// Werdykt audytu budżetu klatki 3D dla docelowych 120 FPS (< 4.5 ms).
enum FrameBudgetVerdict {
  optimal(
    'OPTIMAL 120 FPS',
    '< 3.2 ms — duży zapas mocy dla stałych 120 Hz',
    AppColors.statusSuccess,
    Icons.verified_rounded,
  ),
  withinBudget(
    'ZGODNY (< 4.5 ms)',
    '3.2–4.5 ms — mieści się w budżecie klatki 120 FPS',
    AppColors.accentBlue,
    Icons.check_circle_outline_rounded,
  ),
  warning(
    'PRZEKROCZONO 4.5 ms',
    '4.5–6.5 ms — ryzyko spadków poniżej 120 FPS',
    AppColors.amberWarning,
    Icons.warning_amber_rounded,
  ),
  critical(
    'KRYTYCZNY JANK',
    '≥ 6.5 ms — naruszenie okna VSync 8.33 ms',
    AppColors.crimsonAlert,
    Icons.error_outline_rounded,
  );

  final String label;
  final String description;
  final Color color;
  final IconData icon;

  const FrameBudgetVerdict(
    this.label,
    this.description,
    this.color,
    this.icon,
  );

  bool get passes120FpsBudget =>
      this == FrameBudgetVerdict.optimal ||
      this == FrameBudgetVerdict.withinBudget;
}

/// Etapy potoku renderowania klatki 3D w Pro Peloton Manager.
enum FramePipelineStage {
  sceneProjection(
    'Rzutowanie 3D & Culling',
    'Scene3dMathProjection',
    700,
    AppColors.accentBlue,
  ),
  pelotonInstancing(
    'Instancjonowanie Peletonu',
    'PelotonInstancedRenderer',
    1500,
    AppColors.goldAccent,
  ),
  roadTerrainMesh(
    'Siatka Drogi & Teren',
    'RoadRibbonMeshBuilder',
    900,
    AppColors.statusSuccess,
  ),
  lightingAndShadows(
    'Oświetlenie & Cienie',
    'DynamicShadowPass',
    800,
    AppColors.amberWarning,
  ),
  hudAndPostProcess(
    'HUD & Post-Processing',
    'TelemetryOverlayPass',
    600,
    AppColors.cyanAccent,
  );

  final String label;
  final String subsystem;
  final int targetMicros;
  final Color color;

  const FramePipelineStage(
    this.label,
    this.subsystem,
    this.targetMicros,
    this.color,
  );

  double get targetMs => targetMicros / 1000.0;
}

/// Predefiniowane scenariusze obciążenia sceny 3D do deterministycznego audytu.
enum FrameBudgetPresetScenario {
  sprintFinish176Riders(
    'Finisz Sprinterski (176 kolarzy)',
    'Gęsty peleton, maksymalny LOD0 i pełne cieniowanie na kresce.',
    176,
    68,
    72,
    36,
    1.18,
  ),
  mountainAscentSwitchbacks(
    'Górskie Serpentyny HC',
    'Rozciągnięty peleton, daleki zasięg siatki terenu i mgła.',
    168,
    24,
    58,
    86,
    0.92,
  ),
  rainyCobblesPeloton(
    'Bruk 5★ w Deszczu',
    'Odbicia na mokrym bruku, cząsteczki deszczu i wibracje kamery.',
    172,
    46,
    64,
    62,
    1.04,
  ),
  timeTrialSolo(
    'Jazda Indywidualna na Czas (ITT)',
    'Pojedynczy kolarz + wóz techniczny, minimalne instancjonowanie.',
    8,
    4,
    4,
    0,
    0.42,
  );

  final String label;
  final String description;
  final int totalRiders;
  final int baseLod0;
  final int baseLod1;
  final int baseLod2;
  final double complexityMultiplier;

  const FrameBudgetPresetScenario(
    this.label,
    this.description,
    this.totalRiders,
    this.baseLod0,
    this.baseLod1,
    this.baseLod2,
    this.complexityMultiplier,
  );
}

/// Pojedyncza próbka pomiarowa budżetu klatki 3D.
@immutable
class FrameBudgetSample {
  final int frameIndex;
  final DateTime timestamp;
  final Map<FramePipelineStage, int> stageMicros;
  final int physicsIsolateMicros;
  final int lod0Count;
  final int lod1Count;
  final int lod2Count;
  final int culledCount;

  const FrameBudgetSample({
    required this.frameIndex,
    required this.timestamp,
    required this.stageMicros,
    this.physicsIsolateMicros = 0,
    this.lod0Count = 0,
    this.lod1Count = 0,
    this.lod2Count = 0,
    this.culledCount = 0,
  });

  int get totalRenderMicros {
    var sum = 0;
    for (final value in stageMicros.values) {
      sum += value;
    }
    return sum;
  }

  double get totalRenderMs => totalRenderMicros / 1000.0;

  double get effectiveFps {
    if (totalRenderMicros <= 0) return 120.0;
    final raw = 1000000.0 / totalRenderMicros;
    return raw.clamp(1.0, 240.0);
  }

  bool get isWithin120FpsBudget =>
      totalRenderMicros < Performance120FpsFrameBudgetAuditor.targetBudgetMicros;

  bool get violatesVsync120Hz =>
      totalRenderMs >= Performance120FpsFrameBudgetAuditor.vsync120HzIntervalMs;

  FrameBudgetVerdict get verdict =>
      Performance120FpsFrameBudgetAuditor.evaluateVerdict(totalRenderMs);

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'frameIndex': frameIndex,
      'timestamp': timestamp.toIso8601String(),
      'totalRenderMicros': totalRenderMicros,
      'totalRenderMs': double.parse(totalRenderMs.toStringAsFixed(3)),
      'physicsIsolateMicros': physicsIsolateMicros,
      'lod0Count': lod0Count,
      'lod1Count': lod1Count,
      'lod2Count': lod2Count,
      'culledCount': culledCount,
      'verdict': verdict.name,
      'stagesMicros': stageMicros.map(
        (key, value) => MapEntry<String, int>(key.name, value),
      ),
    };
  }
}

/// Zagregowane statystyki pojedynczego etapu potoku 3D.
@immutable
class StageBudgetBreakdown {
  final FramePipelineStage stage;
  final double avgMicros;
  final double p95Micros;
  final int maxMicros;
  final double sharePercent;

  const StageBudgetBreakdown({
    required this.stage,
    required this.avgMicros,
    required this.p95Micros,
    required this.maxMicros,
    required this.sharePercent,
  });

  double get avgMs => avgMicros / 1000.0;
  double get p95Ms => p95Micros / 1000.0;
  double get maxMs => maxMicros / 1000.0;
  bool get isOverTarget => p95Micros > stage.targetMicros;
}

/// Rekomendacja optymalizacyjna wygenerowana przez audytor.
@immutable
class FrameOptimizationRecommendation {
  final String id;
  final String title;
  final String description;
  final FramePipelineStage targetStage;
  final double estimatedSavingsMs;
  final FrameBudgetVerdict severity;

  const FrameOptimizationRecommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.targetStage,
    required this.estimatedSavingsMs,
    required this.severity,
  });
}

/// Pełny raport audytu budżetu klatki 3D (< 4.5 ms dla 120 FPS).
@immutable
class FrameBudgetAuditReport {
  final DateTime generatedAt;
  final String scenarioLabel;
  final double targetBudgetMs;
  final double vsyncIntervalMs;
  final int totalFramesSampled;
  final double avgFrameMs;
  final double p50FrameMs;
  final double p95FrameMs;
  final double p99FrameMs;
  final double minFrameMs;
  final double maxFrameMs;
  final double estimatedSustainedFps;
  final double withinBudgetRatio;
  final int overBudgetFramesCount;
  final int dropped120FpsFrames;
  final FrameBudgetVerdict overallVerdict;
  final List<StageBudgetBreakdown> stageBreakdowns;
  final List<FrameBudgetSample> samples;
  final List<FrameOptimizationRecommendation> recommendations;

  const FrameBudgetAuditReport({
    required this.generatedAt,
    required this.scenarioLabel,
    required this.targetBudgetMs,
    required this.vsyncIntervalMs,
    required this.totalFramesSampled,
    required this.avgFrameMs,
    required this.p50FrameMs,
    required this.p95FrameMs,
    required this.p99FrameMs,
    required this.minFrameMs,
    required this.maxFrameMs,
    required this.estimatedSustainedFps,
    required this.withinBudgetRatio,
    required this.overBudgetFramesCount,
    required this.dropped120FpsFrames,
    required this.overallVerdict,
    required this.stageBreakdowns,
    required this.samples,
    required this.recommendations,
  });

  bool get passesAudit =>
      p95FrameMs < targetBudgetMs && dropped120FpsFrames == 0;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'generatedAt': generatedAt.toIso8601String(),
      'scenarioLabel': scenarioLabel,
      'targetBudgetMs': targetBudgetMs,
      'vsyncIntervalMs': double.parse(vsyncIntervalMs.toStringAsFixed(3)),
      'totalFramesSampled': totalFramesSampled,
      'avgFrameMs': double.parse(avgFrameMs.toStringAsFixed(3)),
      'p50FrameMs': double.parse(p50FrameMs.toStringAsFixed(3)),
      'p95FrameMs': double.parse(p95FrameMs.toStringAsFixed(3)),
      'p99FrameMs': double.parse(p99FrameMs.toStringAsFixed(3)),
      'minFrameMs': double.parse(minFrameMs.toStringAsFixed(3)),
      'maxFrameMs': double.parse(maxFrameMs.toStringAsFixed(3)),
      'estimatedSustainedFps':
          double.parse(estimatedSustainedFps.toStringAsFixed(1)),
      'withinBudgetRatio':
          double.parse((withinBudgetRatio * 100.0).toStringAsFixed(2)),
      'overBudgetFramesCount': overBudgetFramesCount,
      'dropped120FpsFrames': dropped120FpsFrames,
      'overallVerdict': overallVerdict.name,
      'passesAudit': passesAudit,
      'stageBreakdowns': stageBreakdowns
          .map(
            (b) => <String, dynamic>{
              'stage': b.stage.name,
              'avgMs': double.parse(b.avgMs.toStringAsFixed(3)),
              'p95Ms': double.parse(b.p95Ms.toStringAsFixed(3)),
              'maxMs': double.parse(b.maxMs.toStringAsFixed(3)),
              'targetMs': b.stage.targetMs,
              'sharePercent': double.parse(b.sharePercent.toStringAsFixed(1)),
              'isOverTarget': b.isOverTarget,
            },
          )
          .toList(),
      'recommendations': recommendations
          .map(
            (r) => <String, dynamic>{
              'id': r.id,
              'title': r.title,
              'targetStage': r.targetStage.name,
              'estimatedSavingsMs': r.estimatedSavingsMs,
              'severity': r.severity.name,
            },
          )
          .toList(),
    };
  }
}

/// Audytor budżetu klatki 3D (< 4.5 ms dla stałych 120 FPS).
///
/// Analizuje próbki potoku renderowania 3D (`Scene3dMathProjection`,
/// `PelotonInstancedRenderer`, `RoadRibbonMeshBuilder`, cieniowanie i HUD),
/// oblicza percentyle P50/P95/P99 i generuje rekomendacje optymalizacyjne.
class Performance120FpsFrameBudgetAuditor {
  const Performance120FpsFrameBudgetAuditor();

  /// Twardy limit budżetu renderingu 3D dla stabilnych 120 FPS [ms].
  static const double targetBudgetMs = 4.5;

  /// Twardy limit budżetu renderingu 3D w mikrosekundach [µs].
  static const int targetBudgetMicros = 4500;

  /// Próg optymalnego zapasu mocy [ms].
  static const double optimalBudgetMs = 3.2;

  /// Okno pojedynczego VSync przy 120 Hz [ms].
  static const double vsync120HzIntervalMs = 1000.0 / 120.0;

  /// Ocenia pojedynczy czas renderingu klatki [ms] względem limitu 4.5 ms.
  static FrameBudgetVerdict evaluateVerdict(double frameMs) {
    if (frameMs < optimalBudgetMs) {
      return FrameBudgetVerdict.optimal;
    }
    if (frameMs < targetBudgetMs) {
      return FrameBudgetVerdict.withinBudget;
    }
    if (frameMs < 6.5) {
      return FrameBudgetVerdict.warning;
    }
    return FrameBudgetVerdict.critical;
  }

  /// Tworzy próbkę budżetu klatki 3D na podstawie metryk z [PerformanceTelemetryRegistry].
  FrameBudgetSample sampleFromTelemetryRegistry({
    required EnginePerformanceMetrics metrics,
    int frameIndex = 0,
    DateTime? timestamp,
    bool enableShadows = true,
    bool enablePostProcess = true,
  }) {
    final lod0 = math.max(0, metrics.lod0Count);
    final lod1 = math.max(0, metrics.lod1Count);
    final lod2 = math.max(0, metrics.lod2Count);
    final totalVisible = lod0 + lod1 + lod2;
    final effectiveRiders = totalVisible > 0
        ? totalVisible
        : math.max(1, metrics.simulatedRidersCount);

    final projectionUs = 240 + (effectiveRiders * 2) + (metrics.culledCount ~/ 2);
    final instancingUs = (lod0 * 14) + (lod1 * 6) + (lod2 * 2) + 220;
    final terrainUs = 620 + (effectiveRiders > 100 ? 140 : 40);
    final shadowUs = enableShadows ? (280 + (lod0 * 7) + (lod1 * 2)) : 90;
    final postUs = enablePostProcess ? 430 : 180;

    return FrameBudgetSample(
      frameIndex: frameIndex,
      timestamp: timestamp ?? DateTime.now(),
      stageMicros: <FramePipelineStage, int>{
        FramePipelineStage.sceneProjection: projectionUs,
        FramePipelineStage.pelotonInstancing: instancingUs,
        FramePipelineStage.roadTerrainMesh: terrainUs,
        FramePipelineStage.lightingAndShadows: shadowUs,
        FramePipelineStage.hudAndPostProcess: postUs,
      },
      physicsIsolateMicros: metrics.physicsTickMicroseconds,
      lod0Count: lod0,
      lod1Count: lod1,
      lod2Count: lod2,
      culledCount: metrics.culledCount,
    );
  }

  /// Uruchamia deterministyczny benchmark 3D dla zadanego scenariusza i ustawień LOD.
  FrameBudgetAuditReport runDeterministicBenchmark({
    required FrameBudgetPresetScenario scenario,
    int frameCount = 120,
    int lodBias = 0,
    bool enableShadows = true,
    bool enablePostProcess = true,
    int seed = 556,
  }) {
    final clampedFrames = frameCount.clamp(12, 360);
    final clampedBias = lodBias.clamp(-1, 1);
    final rng = math.Random(seed ^ scenario.index ^ (clampedBias + 2));
    final start = DateTime(2026, 11, 18, 12, 0, 0);

    // lodBias: -1 = agresywniejszy LOD (mniej LOD0), +1 = wyższa jakość (więcej LOD0)
    final lod0 = math.max(
      1,
      (scenario.baseLod0 * (1.0 + clampedBias * 0.28)).round(),
    );
    final lod1 = math.max(
      0,
      (scenario.baseLod1 * (1.0 - clampedBias * 0.10)).round(),
    );
    final lod2 = math.max(0, scenario.totalRiders - lod0 - lod1);
    final culled = math.max(0, 176 - (lod0 + lod1 + lod2));

    final samples = <FrameBudgetSample>[];
    for (var i = 0; i < clampedFrames; i++) {
      // Okresowa mikro-wariancja kamery/klatki + rzadki pik co 45 klatek
      final wave = math.sin(i * 0.21) * 0.06 + (rng.nextDouble() - 0.5) * 0.08;
      final spikeFactor = (i > 0 && i % 47 == 0) ? 1.14 : 1.0;
      final mult = scenario.complexityMultiplier * (1.0 + wave) * spikeFactor;

      final projectionUs = math.max(
        120,
        ((380 + scenario.totalRiders * 1.4) * (0.95 + wave)).round(),
      );
      final instancingUs = math.max(
        180,
        ((240 + lod0 * 14.5 + lod1 * 5.8 + lod2 * 2.1) * mult).round(),
      );
      final terrainUs = math.max(
        220,
        ((640 + (scenario == FrameBudgetPresetScenario.mountainAscentSwitchbacks ? 220 : 80)) *
                (0.96 + wave))
            .round(),
      );
      final shadowUs = enableShadows
          ? math.max(150, ((260 + lod0 * 7.2 + lod1 * 2.0) * mult).round())
          : 75;
      final postUs = enablePostProcess
          ? math.max(
              160,
              ((410 + (scenario == FrameBudgetPresetScenario.rainyCobblesPeloton ? 140 : 0)) *
                      (0.97 + wave))
                  .round(),
            )
          : 155;

      samples.add(
        FrameBudgetSample(
          frameIndex: i + 1,
          timestamp: start.add(Duration(microseconds: i * 8333)),
          stageMicros: <FramePipelineStage, int>{
            FramePipelineStage.sceneProjection: projectionUs,
            FramePipelineStage.pelotonInstancing: instancingUs,
            FramePipelineStage.roadTerrainMesh: terrainUs,
            FramePipelineStage.lightingAndShadows: shadowUs,
            FramePipelineStage.hudAndPostProcess: postUs,
          },
          physicsIsolateMicros: 420 + rng.nextInt(140),
          lod0Count: lod0,
          lod1Count: lod1,
          lod2Count: lod2,
          culledCount: culled,
        ),
      );
    }

    return auditSamples(
      samples: samples,
      scenarioLabel: scenario.label,
    );
  }

  /// Audytuje przekazaną listę próbek klatek 3D pod kątem budżetu < 4.5 ms.
  FrameBudgetAuditReport auditSamples({
    required List<FrameBudgetSample> samples,
    String scenarioLabel = 'Niestandardowa sesja 3D',
  }) {
    if (samples.isEmpty) {
      return FrameBudgetAuditReport(
        generatedAt: DateTime.now(),
        scenarioLabel: scenarioLabel,
        targetBudgetMs: targetBudgetMs,
        vsyncIntervalMs: vsync120HzIntervalMs,
        totalFramesSampled: 0,
        avgFrameMs: 0.0,
        p50FrameMs: 0.0,
        p95FrameMs: 0.0,
        p99FrameMs: 0.0,
        minFrameMs: 0.0,
        maxFrameMs: 0.0,
        estimatedSustainedFps: 120.0,
        withinBudgetRatio: 1.0,
        overBudgetFramesCount: 0,
        dropped120FpsFrames: 0,
        overallVerdict: FrameBudgetVerdict.optimal,
        stageBreakdowns: const <StageBudgetBreakdown>[],
        samples: const <FrameBudgetSample>[],
        recommendations: const <FrameOptimizationRecommendation>[],
      );
    }

    final frameTimesMs = samples.map((s) => s.totalRenderMs).toList()..sort();
    final sumMs = frameTimesMs.fold<double>(0.0, (acc, v) => acc + v);
    final avgMs = sumMs / frameTimesMs.length;
    final p50 = _percentile(frameTimesMs, 0.50);
    final p95 = _percentile(frameTimesMs, 0.95);
    final p99 = _percentile(frameTimesMs, 0.99);
    final minMs = frameTimesMs.first;
    final maxMs = frameTimesMs.last;

    var withinCount = 0;
    var droppedCount = 0;
    for (final sample in samples) {
      if (sample.isWithin120FpsBudget) {
        withinCount++;
      }
      if (sample.violatesVsync120Hz) {
        droppedCount++;
      }
    }

    final totalAvgMicros = avgMs * 1000.0;
    final breakdowns = <StageBudgetBreakdown>[];
    for (final stage in FramePipelineStage.values) {
      final values =
          samples.map((s) => s.stageMicros[stage] ?? 0).toList()..sort();
      final stageSum = values.fold<int>(0, (acc, v) => acc + v);
      final stageAvg = stageSum / values.length;
      final stageP95 = _percentile(
        values.map((e) => e.toDouble()).toList(),
        0.95,
      );
      final stageMax = values.last;
      final share =
          totalAvgMicros > 0 ? (stageAvg / totalAvgMicros) * 100.0 : 0.0;

      breakdowns.add(
        StageBudgetBreakdown(
          stage: stage,
          avgMicros: stageAvg,
          p95Micros: stageP95,
          maxMicros: stageMax,
          sharePercent: share,
        ),
      );
    }

    final overallVerdict = evaluateVerdict(p95);
    final sustainedFps = p95 <= vsync120HzIntervalMs
        ? 120.0
        : (1000.0 / p95).clamp(1.0, 120.0);

    final recommendations = _buildRecommendations(
      p95Ms: p95,
      breakdowns: breakdowns,
      droppedCount: droppedCount,
    );

    return FrameBudgetAuditReport(
      generatedAt: DateTime.now(),
      scenarioLabel: scenarioLabel,
      targetBudgetMs: targetBudgetMs,
      vsyncIntervalMs: vsync120HzIntervalMs,
      totalFramesSampled: samples.length,
      avgFrameMs: avgMs,
      p50FrameMs: p50,
      p95FrameMs: p95,
      p99FrameMs: p99,
      minFrameMs: minMs,
      maxFrameMs: maxMs,
      estimatedSustainedFps: sustainedFps,
      withinBudgetRatio: withinCount / samples.length,
      overBudgetFramesCount: samples.length - withinCount,
      dropped120FpsFrames: droppedCount,
      overallVerdict: overallVerdict,
      stageBreakdowns: breakdowns,
      samples: List<FrameBudgetSample>.unmodifiable(samples),
      recommendations: recommendations,
    );
  }

  static double _percentile(List<double> sorted, double p) {
    if (sorted.isEmpty) return 0.0;
    if (sorted.length == 1) return sorted.first;
    final index = (p * (sorted.length - 1)).clamp(0.0, sorted.length - 1.0);
    final lower = index.floor();
    final upper = index.ceil();
    if (lower == upper) return sorted[lower];
    final fraction = index - lower;
    return sorted[lower] + (sorted[upper] - sorted[lower]) * fraction;
  }

  List<FrameOptimizationRecommendation> _buildRecommendations({
    required double p95Ms,
    required List<StageBudgetBreakdown> breakdowns,
    required int droppedCount,
  }) {
    final recs = <FrameOptimizationRecommendation>[];
    for (final b in breakdowns) {
      if (!b.isOverTarget) continue;
      final excessMs = (b.p95Micros - b.stage.targetMicros) / 1000.0;
      switch (b.stage) {
        case FramePipelineStage.pelotonInstancing:
          recs.add(
            FrameOptimizationRecommendation(
              id: 'opt_lod0_clamp',
              title: 'Obniż próg przejścia LOD0 → LOD1 na 22 m',
              description:
                  'Etap ${b.stage.subsystem} osiąga ${b.p95Ms.toStringAsFixed(2)} ms '
                  '(limit ${b.stage.targetMs.toStringAsFixed(2)} ms). '
                  'Ograniczenie pełnej geometrii kolarzy w LOD0 zredukuje draw calle.',
              targetStage: b.stage,
              estimatedSavingsMs: math.max(0.35, excessMs * 0.85),
              severity: p95Ms >= targetBudgetMs
                  ? FrameBudgetVerdict.warning
                  : FrameBudgetVerdict.withinBudget,
            ),
          );
          break;
        case FramePipelineStage.lightingAndShadows:
          recs.add(
            FrameOptimizationRecommendation(
              id: 'opt_shadow_cascade',
              title: 'Uprość cienie kaskadowe w tłumie peletonu',
              description:
                  'Dynamiczne cienie zużywają ${b.p95Ms.toStringAsFixed(2)} ms. '
                  'Zastąpienie cieni siatkowych cieniem eliptycznym dla LOD1/LOD2 '
                  'odzyska cenny zapas budżetu 120 FPS.',
              targetStage: b.stage,
              estimatedSavingsMs: math.max(0.28, excessMs * 0.8),
              severity: p95Ms >= targetBudgetMs
                  ? FrameBudgetVerdict.warning
                  : FrameBudgetVerdict.withinBudget,
            ),
          );
          break;
        case FramePipelineStage.roadTerrainMesh:
          recs.add(
            FrameOptimizationRecommendation(
              id: 'opt_ribbon_subdiv',
              title: 'Adaptacyjna teselacja wstęgi drogi',
              description:
                  'RoadRibbonMeshBuilder przekracza budżet (${b.p95Ms.toStringAsFixed(2)} ms). '
                  'Zmniejszenie podziału siatki powyżej 120 m od kamery utrzyma stałe 120 Hz.',
              targetStage: b.stage,
              estimatedSavingsMs: math.max(0.20, excessMs * 0.75),
              severity: FrameBudgetVerdict.withinBudget,
            ),
          );
          break;
        case FramePipelineStage.hudAndPostProcess:
          recs.add(
            FrameOptimizationRecommendation(
              id: 'opt_post_fx',
              title: 'Wyłącz ciężki post-processing przy > 120 kolarzach',
              description:
                  'Przebieg HUD/Post-Process wynosi ${b.p95Ms.toStringAsFixed(2)} ms. '
                  'Izolacja warstwy RepaintBoundary dla telemetrii obniży narzut CPU/GPU.',
              targetStage: b.stage,
              estimatedSavingsMs: math.max(0.18, excessMs * 0.7),
              severity: FrameBudgetVerdict.withinBudget,
            ),
          );
          break;
        case FramePipelineStage.sceneProjection:
          recs.add(
            FrameOptimizationRecommendation(
              id: 'opt_frustum_batch',
              title: 'Batching macierzy rzutowania 3D',
              description:
                  'Scene3dMathProjection zajmuje ${b.p95Ms.toStringAsFixed(2)} ms. '
                  'Wstępne odrzucenie bryłą widzenia (Frustum Culling) zmniejszy narzut.',
              targetStage: b.stage,
              estimatedSavingsMs: math.max(0.12, excessMs * 0.65),
              severity: FrameBudgetVerdict.withinBudget,
            ),
          );
          break;
      }
    }

    if (droppedCount > 0 && recs.isEmpty) {
      recs.add(
        FrameOptimizationRecommendation(
          id: 'opt_vsync_headroom',
          title: 'Zabezpiecz margines VSync 120 Hz',
          description:
              'Wykryto $droppedCount klatek przekraczających 8.33 ms. '
              'Aktywuj adaptacyjny profil LOD w PlatformAdaptiveGraphicsProfiler.',
          targetStage: FramePipelineStage.pelotonInstancing,
          estimatedSavingsMs: 0.65,
          severity: FrameBudgetVerdict.critical,
        ),
      );
    }

    return recs;
  }
}

/// Stan kontrolera Riverpod dla audytora budżetu klatki 120 FPS.
@immutable
class Performance120FpsAuditorState {
  final FrameBudgetPresetScenario selectedScenario;
  final int frameCount;
  final int lodBias;
  final bool enableShadows;
  final bool enablePostProcess;
  final bool isLiveMonitoring;
  final FramePipelineStage? selectedStageFilter;
  final FrameBudgetAuditReport? report;
  final String? statusMessage;

  const Performance120FpsAuditorState({
    this.selectedScenario = FrameBudgetPresetScenario.sprintFinish176Riders,
    this.frameCount = 120,
    this.lodBias = 0,
    this.enableShadows = true,
    this.enablePostProcess = true,
    this.isLiveMonitoring = false,
    this.selectedStageFilter,
    this.report,
    this.statusMessage,
  });

  Performance120FpsAuditorState copyWith({
    FrameBudgetPresetScenario? selectedScenario,
    int? frameCount,
    int? lodBias,
    bool? enableShadows,
    bool? enablePostProcess,
    bool? isLiveMonitoring,
    FramePipelineStage? selectedStageFilter,
    bool clearStageFilter = false,
    FrameBudgetAuditReport? report,
    String? statusMessage,
    bool clearStatusMessage = false,
  }) {
    return Performance120FpsAuditorState(
      selectedScenario: selectedScenario ?? this.selectedScenario,
      frameCount: frameCount ?? this.frameCount,
      lodBias: lodBias ?? this.lodBias,
      enableShadows: enableShadows ?? this.enableShadows,
      enablePostProcess: enablePostProcess ?? this.enablePostProcess,
      isLiveMonitoring: isLiveMonitoring ?? this.isLiveMonitoring,
      selectedStageFilter: clearStageFilter
          ? null
          : (selectedStageFilter ?? this.selectedStageFilter),
      report: report ?? this.report,
      statusMessage:
          clearStatusMessage ? null : (statusMessage ?? this.statusMessage),
    );
  }
}

/// Notifier zarządzający cyklem audytu 120 FPS (< 4.5 ms).
class Performance120FpsAuditorNotifier
    extends StateNotifier<Performance120FpsAuditorState> {
  final Performance120FpsFrameBudgetAuditor _auditor;
  Timer? _liveTimer;
  final List<FrameBudgetSample> _liveBuffer = <FrameBudgetSample>[];

  Performance120FpsAuditorNotifier({
    Performance120FpsFrameBudgetAuditor auditor =
        const Performance120FpsFrameBudgetAuditor(),
  })  : _auditor = auditor,
        super(const Performance120FpsAuditorState()) {
    runBenchmark();
  }

  /// Uruchamia deterministyczny benchmark 3D dla aktualnych ustawień.
  void runBenchmark() {
    _stopLiveTimer();
    final report = _auditor.runDeterministicBenchmark(
      scenario: state.selectedScenario,
      frameCount: state.frameCount,
      lodBias: state.lodBias,
      enableShadows: state.enableShadows,
      enablePostProcess: state.enablePostProcess,
    );
    state = state.copyWith(
      isLiveMonitoring: false,
      report: report,
      statusMessage: report.passesAudit
          ? 'Audyt zaliczony: P95 ${report.p95FrameMs.toStringAsFixed(2)} ms (< 4.5 ms).'
          : 'Przekroczono budżet 4.5 ms: P95 ${report.p95FrameMs.toStringAsFixed(2)} ms.',
    );
  }

  void selectScenario(FrameBudgetPresetScenario scenario) {
    state = state.copyWith(selectedScenario: scenario);
    runBenchmark();
  }

  void setLodBias(int bias) {
    state = state.copyWith(lodBias: bias.clamp(-1, 1));
    runBenchmark();
  }

  void toggleShadows(bool enabled) {
    state = state.copyWith(enableShadows: enabled);
    runBenchmark();
  }

  void togglePostProcess(bool enabled) {
    state = state.copyWith(enablePostProcess: enabled);
    runBenchmark();
  }

  void selectStageFilter(FramePipelineStage? stage) {
    if (stage == state.selectedStageFilter) {
      state = state.copyWith(clearStageFilter: true);
    } else {
      state = state.copyWith(selectedStageFilter: stage);
    }
  }

  /// Pobiera pojedynczą próbkę na żywo z [PerformanceTelemetryRegistry].
  void captureFromTelemetryRegistry() {
    final metrics = PerformanceTelemetryRegistry.instance.metrics.value;
    final sample = _auditor.sampleFromTelemetryRegistry(
      metrics: metrics,
      frameIndex: _liveBuffer.length + 1,
      enableShadows: state.enableShadows,
      enablePostProcess: state.enablePostProcess,
    );
    _liveBuffer.add(sample);
    if (_liveBuffer.length > 120) {
      _liveBuffer.removeAt(0);
    }
    final report = _auditor.auditSamples(
      samples: List<FrameBudgetSample>.from(_liveBuffer),
      scenarioLabel: 'Telemetria na żywo (Engine Registry)',
    );
    state = state.copyWith(
      report: report,
      statusMessage:
          'Zarejestrowano próbkę #${sample.frameIndex}: ${sample.totalRenderMs.toStringAsFixed(2)} ms.',
    );
  }

  /// Przełącza ciągły odczyt z rejestru telemetrii co 100 ms.
  void toggleLiveMonitoring() {
    if (state.isLiveMonitoring) {
      _stopLiveTimer();
      state = state.copyWith(
        isLiveMonitoring: false,
        statusMessage: 'Zatrzymano monitorowanie na żywo.',
      );
      return;
    }

    _liveBuffer.clear();
    captureFromTelemetryRegistry();
    _liveTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => captureFromTelemetryRegistry(),
    );
    state = state.copyWith(
      isLiveMonitoring: true,
      statusMessage: 'Aktywny odczyt telemetrii 3D na żywo...',
    );
  }

  String exportReportJson() {
    final report = state.report;
    if (report == null) return '{}';
    return const JsonEncoder.withIndent('  ').convert(report.toJson());
  }

  void _stopLiveTimer() {
    _liveTimer?.cancel();
    _liveTimer = null;
  }

  @override
  void dispose() {
    _stopLiveTimer();
    super.dispose();
  }
}

/// Provider audytora budżetu klatki 120 FPS (< 4.5 ms).
final performance120FpsAuditorProvider = StateNotifierProvider<
    Performance120FpsAuditorNotifier, Performance120FpsAuditorState>(
  (ref) => Performance120FpsAuditorNotifier(),
);

/// Produkcyjny panel diagnostyczny audytu budżetu klatki 3D (< 4.5 ms dla 120 FPS).
class Performance120FpsFrameBudgetAuditorPanel extends ConsumerWidget {
  const Performance120FpsFrameBudgetAuditorPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(performance120FpsAuditorProvider);
    final notifier = ref.read(performance120FpsAuditorProvider.notifier);
    final report = state.report;

    return Container(
      color: AppColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isMobile = width < 680;
          final isTablet = width >= 680 && width < 1150;
          final horizontalPadding = isMobile ? 12.0 : (isTablet ? 20.0 : 28.0);

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _HeaderBanner(
                  state: state,
                  report: report,
                  isMobile: isMobile,
                  onRunBenchmark: notifier.runBenchmark,
                  onToggleLive: notifier.toggleLiveMonitoring,
                  onCopyJson: () async {
                    final jsonStr = notifier.exportReportJson();
                    await Clipboard.setData(ClipboardData(text: jsonStr));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Raport budżetu 120 FPS skopiowany do schowka (JSON).',
                            style: TextStyle(fontFamily: 'Inter'),
                          ),
                          backgroundColor: AppColors.surfaceLight,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
                _ControlsSection(
                  state: state,
                  isMobile: isMobile,
                  onSelectScenario: notifier.selectScenario,
                  onSetLodBias: notifier.setLodBias,
                  onToggleShadows: notifier.toggleShadows,
                  onTogglePostProcess: notifier.togglePostProcess,
                ),
                if (report != null) ...<Widget>[
                  const SizedBox(height: 16),
                  _KpiGrid(
                    report: report,
                    isMobile: isMobile,
                    isTablet: isTablet,
                  ),
                  const SizedBox(height: 16),
                  if (isMobile || isTablet) ...<Widget>[
                    _TimelineChartCard(
                      report: report,
                      selectedStage: state.selectedStageFilter,
                    ),
                    const SizedBox(height: 16),
                    _StageBreakdownCard(
                      report: report,
                      selectedStage: state.selectedStageFilter,
                      onSelectStage: notifier.selectStageFilter,
                    ),
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          flex: 6,
                          child: _TimelineChartCard(
                            report: report,
                            selectedStage: state.selectedStageFilter,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 5,
                          child: _StageBreakdownCard(
                            report: report,
                            selectedStage: state.selectedStageFilter,
                            onSelectStage: notifier.selectStageFilter,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  _RecommendationsCard(recommendations: report.recommendations),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeaderBanner extends StatelessWidget {
  final Performance120FpsAuditorState state;
  final FrameBudgetAuditReport? report;
  final bool isMobile;
  final VoidCallback onRunBenchmark;
  final VoidCallback onToggleLive;
  final VoidCallback onCopyJson;

  const _HeaderBanner({
    required this.state,
    required this.report,
    required this.isMobile,
    required this.onRunBenchmark,
    required this.onToggleLive,
    required this.onCopyJson,
  });

  @override
  Widget build(BuildContext context) {
    final verdict = report?.overallVerdict ?? FrameBudgetVerdict.withinBudget;

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primaryAccent.withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Icon(
                      Icons.speed_rounded,
                      color: AppColors.goldAccent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Audyt Budżetu Klatki 3D — 120 FPS',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Cel: < 4.50 ms na klatkę (okno VSync 8.33 ms @ 120 Hz)',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontFeatures: <FontFeature>[
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: verdict.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: verdict.color.withValues(alpha: 0.45),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(verdict.icon, size: 15, color: verdict.color),
                    const SizedBox(width: 6),
                    Text(
                      verdict.label,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: verdict.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (state.statusMessage != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              state.statusMessage!,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textSecondary,
                fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _InteractiveActionButton(
                label: 'Uruchom audyt 120 FPS',
                icon: Icons.play_arrow_rounded,
                isPrimary: true,
                onPressed: onRunBenchmark,
              ),
              _InteractiveActionButton(
                label: state.isLiveMonitoring
                    ? 'Zatrzymaj Live'
                    : 'Telemetria Live',
                icon: state.isLiveMonitoring
                    ? Icons.stop_circle_outlined
                    : Icons.sensors_rounded,
                isActive: state.isLiveMonitoring,
                onPressed: onToggleLive,
              ),
              _InteractiveActionButton(
                label: 'Kopiuj JSON',
                icon: Icons.data_object_rounded,
                onPressed: report != null ? onCopyJson : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ControlsSection extends StatelessWidget {
  final Performance120FpsAuditorState state;
  final bool isMobile;
  final ValueChanged<FrameBudgetPresetScenario> onSelectScenario;
  final ValueChanged<int> onSetLodBias;
  final ValueChanged<bool> onToggleShadows;
  final ValueChanged<bool> onTogglePostProcess;

  const _ControlsSection({
    required this.state,
    required this.isMobile,
    required this.onSelectScenario,
    required this.onSetLodBias,
    required this.onToggleShadows,
    required this.onTogglePostProcess,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'SCENARIUSZ I PARAMETRY RENDEROWANIA 3D',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: FrameBudgetPresetScenario.values.map((scenario) {
              final selected = scenario == state.selectedScenario;
              return _InteractiveChip(
                label: scenario.label,
                selected: selected,
                onTap: () => onSelectScenario(scenario),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              const Text(
                'Agresywność LOD:',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              _InteractiveChip(
                label: 'Wydajny (-1)',
                selected: state.lodBias == -1,
                onTap: () => onSetLodBias(-1),
              ),
              _InteractiveChip(
                label: 'Zbalansowany (0)',
                selected: state.lodBias == 0,
                onTap: () => onSetLodBias(0),
              ),
              _InteractiveChip(
                label: 'Ultra (+1)',
                selected: state.lodBias == 1,
                onTap: () => onSetLodBias(1),
              ),
              _InteractiveChip(
                label: state.enableShadows ? 'Cienie: WŁ.' : 'Cienie: WYŁ.',
                selected: state.enableShadows,
                onTap: () => onToggleShadows(!state.enableShadows),
              ),
              _InteractiveChip(
                label: state.enablePostProcess
                    ? 'Post-FX: WŁ.'
                    : 'Post-FX: WYŁ.',
                selected: state.enablePostProcess,
                onTap: () => onTogglePostProcess(!state.enablePostProcess),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  final FrameBudgetAuditReport report;
  final bool isMobile;
  final bool isTablet;

  const _KpiGrid({
    required this.report,
    required this.isMobile,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      _KpiCard(
        title: 'ŚREDNI CZAS KLATKI',
        value: '${report.avgFrameMs.toStringAsFixed(2)} ms',
        subtitle: 'P50: ${report.p50FrameMs.toStringAsFixed(2)} ms',
        accent: report.avgFrameMs < 4.5
            ? AppColors.statusSuccess
            : AppColors.amberWarning,
      ),
      _KpiCard(
        title: 'PERCENTYL P95 (LIMIT 4.5)',
        value: '${report.p95FrameMs.toStringAsFixed(2)} ms',
        subtitle: 'P99: ${report.p99FrameMs.toStringAsFixed(2)} ms',
        accent: report.overallVerdict.color,
      ),
      _KpiCard(
        title: 'STABILNY KADRAAŻ',
        value: '${report.estimatedSustainedFps.toStringAsFixed(0)} FPS',
        subtitle: 'Spadki > 8.33 ms: ${report.dropped120FpsFrames}',
        accent: report.dropped120FpsFrames == 0
            ? AppColors.accentBlue
            : AppColors.crimsonAlert,
      ),
      _KpiCard(
        title: 'ZGODNOŚĆ Z BUDŻETEM',
        value: '${(report.withinBudgetRatio * 100).toStringAsFixed(1)}%',
        subtitle:
            '${report.totalFramesSampled - report.overBudgetFramesCount}/${report.totalFramesSampled} klatek < 4.5 ms',
        accent: report.withinBudgetRatio >= 0.95
            ? AppColors.goldAccent
            : AppColors.amberWarning,
      ),
    ];

    if (isMobile) {
      return Column(
        children: cards
            .map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: c,
              ),
            )
            .toList(),
      );
    }

    if (isTablet) {
      return Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: cards[0]),
              const SizedBox(width: 12),
              Expanded(child: cards[1]),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(child: cards[2]),
              const SizedBox(width: 12),
              Expanded(child: cards[3]),
            ],
          ),
        ],
      );
    }

    return Row(
      children: <Widget>[
        Expanded(child: cards[0]),
        const SizedBox(width: 12),
        Expanded(child: cards[1]),
        const SizedBox(width: 12),
        Expanded(child: cards[2]),
        const SizedBox(width: 12),
        Expanded(child: cards[3]),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color accent;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: accent,
              letterSpacing: -0.5,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
              fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineChartCard extends StatelessWidget {
  final FrameBudgetAuditReport report;
  final FramePipelineStage? selectedStage;

  const _TimelineChartCard({
    required this.report,
    required this.selectedStage,
  });

  @override
  Widget build(BuildContext context) {
    final title = selectedStage == null
        ? 'OŚ CZASU KLATEK 3D (LIMIT 4.50 ms)'
        : 'ETAP: ${selectedStage!.label.toUpperCase()}';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Text(
                'Max: ${report.maxFrameMs.toStringAsFixed(2)} ms',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 190,
            width: double.infinity,
            child: CustomPaint(
              painter: FrameBudgetTimelinePainter(
                samples: report.samples,
                selectedStage: selectedStage,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Wrap(
            spacing: 14,
            runSpacing: 6,
            children: <Widget>[
              _LegendDot(
                color: AppColors.statusSuccess,
                label: '< 3.2 ms (Optimum)',
              ),
              _LegendDot(
                color: AppColors.accentBlue,
                label: '3.2–4.5 ms (Budżet)',
              ),
              _LegendDot(
                color: AppColors.amberWarning,
                label: '> 4.5 ms (Ostrzeżenie)',
              ),
              _LegendDot(
                color: AppColors.crimsonAlert,
                label: '≥ 8.33 ms (Drop 120Hz)',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

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
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            color: AppColors.textSecondary,
            fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// Rysuje wykres słupkowy czasów klatek 3D z linią budżetu 4.5 ms i VSync 8.33 ms.
class FrameBudgetTimelinePainter extends CustomPainter {
  final List<FrameBudgetSample> samples;
  final FramePipelineStage? selectedStage;

  const FrameBudgetTimelinePainter({
    required this.samples,
    this.selectedStage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = AppColors.surfaceLight;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(12),
    );
    canvas.drawRRect(rrect, bgPaint);

    if (samples.isEmpty) return;

    const maxScaleMs = 9.0;
    final budgetY = size.height *
        (1.0 -
            (Performance120FpsFrameBudgetAuditor.targetBudgetMs / maxScaleMs)
                .clamp(0.0, 1.0));
    final vsyncY = size.height *
        (1.0 -
            (Performance120FpsFrameBudgetAuditor.vsync120HzIntervalMs /
                    maxScaleMs)
                .clamp(0.0, 1.0));

    final gridPaint = Paint()
      ..color = AppTheme.borderColor
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(0, size.height * 0.5),
      Offset(size.width, size.height * 0.5),
      gridPaint,
    );

    final barWidth = math.max(1.5, (size.width - 16) / samples.length);
    for (var i = 0; i < samples.length; i++) {
      final sample = samples[i];
      final valueMs = selectedStage == null
          ? sample.totalRenderMs
          : (sample.stageMicros[selectedStage!] ?? 0) / 1000.0;
      final normalized = (valueMs / maxScaleMs).clamp(0.02, 1.0);
      final barHeight = normalized * (size.height - 12);
      final x = 8.0 + i * barWidth;
      final y = size.height - barHeight;

      final Color barColor;
      if (selectedStage != null) {
        barColor = selectedStage!.color;
      } else if (valueMs >=
          Performance120FpsFrameBudgetAuditor.vsync120HzIntervalMs) {
        barColor = AppColors.crimsonAlert;
      } else if (valueMs >=
          Performance120FpsFrameBudgetAuditor.targetBudgetMs) {
        barColor = AppColors.amberWarning;
      } else if (valueMs >=
          Performance120FpsFrameBudgetAuditor.optimalBudgetMs) {
        barColor = AppColors.accentBlue;
      } else {
        barColor = AppColors.statusSuccess;
      }

      canvas.drawRect(
        Rect.fromLTWH(x, y, math.max(1.0, barWidth - 0.8), barHeight),
        Paint()..color = barColor,
      );
    }

    if (selectedStage == null) {
      // Linia budżetu 4.5 ms
      final budgetPaint = Paint()
        ..color = AppColors.goldAccent
        ..strokeWidth = 1.5;
      canvas.drawLine(
        Offset(0, budgetY),
        Offset(size.width, budgetY),
        budgetPaint,
      );

      // Linia VSync 8.33 ms
      final vsyncPaint = Paint()
        ..color = AppColors.crimsonAlert.withValues(alpha: 0.75)
        ..strokeWidth = 1.2;
      canvas.drawLine(
        Offset(0, vsyncY),
        Offset(size.width, vsyncY),
        vsyncPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant FrameBudgetTimelinePainter oldDelegate) {
    return oldDelegate.samples != samples ||
        oldDelegate.selectedStage != selectedStage;
  }
}

class _StageBreakdownCard extends StatelessWidget {
  final FrameBudgetAuditReport report;
  final FramePipelineStage? selectedStage;
  final ValueChanged<FramePipelineStage?> onSelectStage;

  const _StageBreakdownCard({
    required this.report,
    required this.selectedStage,
    required this.onSelectStage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'PODZIAŁ BUDŻETU ETAPÓW 3D (KLIKNIJ ABY FILTROWAĆ)',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ...report.stageBreakdowns.map((b) {
            final isSelected = selectedStage == b.stage;
            final ratio = (b.p95Micros / b.stage.targetMicros).clamp(0.0, 1.5);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _StageRowTile(
                breakdown: b,
                ratio: ratio,
                isSelected: isSelected,
                onTap: () => onSelectStage(b.stage),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _StageRowTile extends StatefulWidget {
  final StageBudgetBreakdown breakdown;
  final double ratio;
  final bool isSelected;
  final VoidCallback onTap;

  const _StageRowTile({
    required this.breakdown,
    required this.ratio,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_StageRowTile> createState() => _StageRowTileState();
}

class _StageRowTileState extends State<_StageRowTile> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final b = widget.breakdown;
    final barColor =
        b.isOverTarget ? AppColors.amberWarning : b.stage.color;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: widget.isSelected || _hovered
                ? AppColors.surfaceLight
                : AppColors.surfaceLight.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focused || widget.isSelected
                  ? AppColors.goldAccent
                  : AppTheme.borderColor,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Flexible(
                    child: Text(
                      b.stage.label,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    'P95 ${b.p95Ms.toStringAsFixed(2)} / ${b.stage.targetMs.toStringAsFixed(2)} ms',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: b.isOverTarget
                          ? AppColors.amberWarning
                          : AppColors.textSecondary,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (widget.ratio / 1.5).clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: AppColors.background,
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecommendationsCard extends StatelessWidget {
  final List<FrameOptimizationRecommendation> recommendations;

  const _RecommendationsCard({required this.recommendations});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'REKOMENDACJE OPTYMALIZACJI 120 FPS',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          if (recommendations.isEmpty)
            const Row(
              children: <Widget>[
                Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.statusSuccess,
                  size: 18,
                ),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Wszystkie etapy potoku 3D mieszczą się w budżecie < 4.50 ms. Brak wąskich gardeł.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            )
          else
            ...recommendations.map(
              (rec) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(
                        rec.severity.icon,
                        color: rec.severity.color,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              rec.title,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              rec.description,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '-${rec.estimatedSavingsMs.toStringAsFixed(2)} ms',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.statusSuccess,
                          fontFeatures: <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InteractiveActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final bool isActive;
  final VoidCallback? onPressed;

  const _InteractiveActionButton({
    required this.label,
    required this.icon,
    this.isPrimary = false,
    this.isActive = false,
    this.onPressed,
  });

  @override
  State<_InteractiveActionButton> createState() =>
      _InteractiveActionButtonState();
}

class _InteractiveActionButtonState extends State<_InteractiveActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;
    final Color bg;
    if (disabled) {
      bg = AppColors.surfaceLight.withValues(alpha: 0.4);
    } else if (widget.isPrimary) {
      bg = _pressed
          ? AppColors.primaryAccent.withValues(alpha: 0.8)
          : (_hovered
              ? AppColors.primaryAccent.withValues(alpha: 0.92)
              : AppColors.primaryAccent);
    } else if (widget.isActive) {
      bg = AppColors.goldAccent.withValues(alpha: 0.18);
    } else {
      bg = _hovered ? AppColors.surfaceLight : AppColors.background;
    }

    final borderColor = _focused
        ? AppColors.goldAccent
        : (widget.isActive ? AppColors.goldAccent : AppTheme.borderColor);

    final fg = disabled
        ? AppColors.textSecondary.withValues(alpha: 0.5)
        : (widget.isActive ? AppColors.goldAccent : AppColors.textPrimary);

    return FocusableActionDetector(
      enabled: !disabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(widget.icon, size: 16, color: fg),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
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

class _InteractiveChip extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _InteractiveChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_InteractiveChip> createState() => _InteractiveChipState();
}

class _InteractiveChipState extends State<_InteractiveChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.selected
        ? AppColors.primaryAccent.withValues(alpha: 0.28)
        : (_hovered ? AppColors.surfaceLight : AppColors.background);
    final borderColor = _focused
        ? AppColors.goldAccent
        : (widget.selected ? AppColors.primaryAccent : AppTheme.borderColor);

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
              color: widget.selected
                  ? AppColors.goldAccent
                  : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
