// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engine/rendering3d/glb_asset_loader_service.dart';
import '../theme/app_colors.dart';

/// Zakres siatek `.glb` ładowanych podczas rozgrzewania pamięci podręcznej.
enum GlbWarmupScope {
  /// Wyłącznie siatki rowerów, ram i kół (najszybszy start).
  bikesOnly(
    label: 'Rowery (.glb)',
    description: 'Ramy szosowe/TT i koła karbonowe',
  ),

  /// Siatki rowerów + kluczowe modele wyścigu (kolarze, droga, bramy, pojazdy).
  essentialBikesAndRace(
    label: 'Wyścig (Essential)',
    description: 'Rowery + 12 kluczowych modeli 3D peletonu',
  ),

  /// Pełny katalog wszystkich 34 modeli `.glb`.
  fullCatalog(
    label: 'Pełny Katalog (34)',
    description: 'Wszystkie modele 3D w pamięci RAM',
  );

  final String label;
  final String description;

  const GlbWarmupScope({
    required this.label,
    required this.description,
  });
}

/// Aktualny etap rozgrzewania pamięci podręcznej przed pierwszą klatką wyścigu.
enum PreloadWarmupPhase {
  idle('Oczekiwanie na rozgrzewkę'),
  shaders('Kompilacja shaderów Canvas'),
  glbMeshes('Ładowanie siatek .glb rowerów'),
  fontsAndText('Rozgrzewanie glifów czcionki Inter'),
  completed('Gotowe (Zero Jank)'),
  failed('Ukończono z ostrzeżeniami');

  final String label;

  const PreloadWarmupPhase(this.label);
}

/// Status pojedynczego kroku rozgrzewania.
enum WarmupStepStatus {
  pending,
  running,
  succeeded,
  recoveredWithFallback,
}

/// Wynik pojedynczego kroku rozgrzewania (shadery, siatki `.glb` lub czcionki).
class WarmupStepResult {
  final String id;
  final String title;
  final PreloadWarmupPhase phase;
  final WarmupStepStatus status;
  final int elapsedMs;
  final int itemsProcessed;
  final String detail;

  const WarmupStepResult({
    required this.id,
    required this.title,
    required this.phase,
    required this.status,
    required this.elapsedMs,
    required this.itemsProcessed,
    required this.detail,
  });
}

/// Wynik kompilacji shaderów Canvas na GPU/CPU.
class ShaderWarmupOutcome {
  final int compiledPipelinesCount;
  final int elapsedMs;
  final String detail;

  const ShaderWarmupOutcome({
    required this.compiledPipelinesCount,
    required this.elapsedMs,
    required this.detail,
  });
}

/// Wynik rozgrzewania glifów i metryk czcionki `Inter`.
class FontWarmupOutcome {
  final int glyphBatchesWarmed;
  final int elapsedMs;
  final String detail;

  const FontWarmupOutcome({
    required this.glyphBatchesWarmed,
    required this.elapsedMs,
    required this.detail,
  });
}

/// Pełny raport z procesu rozgrzewania pamięci podręcznej przed wyścigiem.
class PreloadWarmupReport {
  final DateTime startedAt;
  final DateTime completedAt;
  final GlbWarmupScope scope;
  final int totalDurationMs;
  final int shaderCompileDurationMs;
  final int glbLoadDurationMs;
  final int fontWarmupDurationMs;
  final int shadersCompiledCount;
  final int glbModelsLoadedCount;
  final int glbFallbackCount;
  final int totalVerticesWarmed;
  final int totalTrianglesWarmed;
  final int fontGlyphBatchesWarmed;
  final List<WarmupStepResult> steps;
  final bool jankFreeReady;

  const PreloadWarmupReport({
    required this.startedAt,
    required this.completedAt,
    required this.scope,
    required this.totalDurationMs,
    required this.shaderCompileDurationMs,
    required this.glbLoadDurationMs,
    required this.fontWarmupDurationMs,
    required this.shadersCompiledCount,
    required this.glbModelsLoadedCount,
    required this.glbFallbackCount,
    required this.totalVerticesWarmed,
    required this.totalTrianglesWarmed,
    required this.fontGlyphBatchesWarmed,
    required this.steps,
    required this.jankFreeReady,
  });

  String get summaryText =>
      'Shadery: $shadersCompiledCount (${shaderCompileDurationMs}ms) • '
      'GLB: $glbModelsLoadedCount (${glbLoadDurationMs}ms, '
      '$totalTrianglesWarmed trójkątów) • '
      'Czcionki: $fontGlyphBatchesWarmed partii (${fontWarmupDurationMs}ms)';
}

/// Niemutowalny stan rozgrzewania dla warstwy UI i ekranu ładowania.
class PreloadWarmupState {
  final PreloadWarmupPhase phase;
  final GlbWarmupScope selectedScope;
  final double progress;
  final String currentTaskLabel;
  final bool isRunning;
  final bool isWarmedUp;
  final PreloadWarmupReport? lastReport;
  final String? errorMessage;

  const PreloadWarmupState({
    this.phase = PreloadWarmupPhase.idle,
    this.selectedScope = GlbWarmupScope.essentialBikesAndRace,
    this.progress = 0.0,
    this.currentTaskLabel = 'Gotowy do wstępnej kompilacji zasobów wyścigu',
    this.isRunning = false,
    this.isWarmedUp = false,
    this.lastReport,
    this.errorMessage,
  });

  PreloadWarmupState copyWith({
    PreloadWarmupPhase? phase,
    GlbWarmupScope? selectedScope,
    double? progress,
    String? currentTaskLabel,
    bool? isRunning,
    bool? isWarmedUp,
    PreloadWarmupReport? lastReport,
    bool clearReport = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PreloadWarmupState(
      phase: phase ?? this.phase,
      selectedScope: selectedScope ?? this.selectedScope,
      progress: progress ?? this.progress,
      currentTaskLabel: currentTaskLabel ?? this.currentTaskLabel,
      isRunning: isRunning ?? this.isRunning,
      isWarmedUp: isWarmedUp ?? this.isWarmedUp,
      lastReport: clearReport ? null : (lastReport ?? this.lastReport),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

typedef ShaderWarmupExecutor = Future<ShaderWarmupOutcome> Function();
typedef FontWarmupExecutor = Future<FontWarmupOutcome> Function();

/// Serwis rozgrzewający pamięć podręczną podczas ekranu ładowania wyścigu.
///
/// Eliminuje przycięcia pierwszej klatki (Shader Compilation Jank) poprzez:
/// 1. Wstępną kompilację potoków shaderów Canvas (gradienty, rozmycia `MaskFilter`,
///    `saveLayer` z `BlendMode`, ścieżki wektorowe i zaokrąglone prostokąty HUD).
/// 2. Asynchroniczne załadowanie i sparsowanie siatek `.glb` rowerów i kluczowych
///    modeli 3D wyścigu do pamięci RAM w [GlbAssetLoaderService].
/// 3. Wstępną rasteryzację glifów czcionki `Inter` (w tym `tabularFigures`)
///    na niewidocznym buforze `Canvas`.
class AssetBundlePreloadWarmer {
  static AssetBundlePreloadWarmer? _singleton;

  /// Globalna instancja singletonu serwisu.
  static AssetBundlePreloadWarmer get instance =>
      _singleton ??= AssetBundlePreloadWarmer();

  final GlbAssetLoaderService _glbLoader;
  final ShaderWarmupExecutor? _customShaderExecutor;
  final FontWarmupExecutor? _customFontExecutor;

  PreloadWarmupReport? _cachedReport;
  Future<PreloadWarmupReport>? _inFlightWarmup;

  AssetBundlePreloadWarmer({
    GlbAssetLoaderService? glbLoader,
    ShaderWarmupExecutor? shaderExecutor,
    FontWarmupExecutor? fontExecutor,
  })  : _glbLoader = glbLoader ?? GlbAssetLoaderService.instance,
        _customShaderExecutor = shaderExecutor,
        _customFontExecutor = fontExecutor;

  /// Zwraca ostatni wygenerowany raport rozgrzewania, jeśli istnieje.
  PreloadWarmupReport? get cachedReport => _cachedReport;

  /// Informuje, czy zasoby zostały już rozgrzane.
  bool get isWarmedUp => _cachedReport != null;

  /// Resetuje stan rozgrzewki (np. po zmianie profilu graficznego).
  void reset() {
    _cachedReport = null;
  }

  /// Uruchamia pełną sekwencję rozgrzewania pamięci podręcznej.
  ///
  /// Jeśli proces już trwa, zwraca trwający [Future] zamiast dublować pracę.
  /// Jeśli pamięć jest już rozgrzana dla tego samego [scope] i [force] == false,
  /// natychmiast zwraca wynik z bufora.
  Future<PreloadWarmupReport> warmUp({
    GlbWarmupScope scope = GlbWarmupScope.essentialBikesAndRace,
    bool force = false,
    void Function(PreloadWarmupState state)? onProgress,
  }) async {
    if (!force && _cachedReport != null && _cachedReport!.scope == scope) {
      final cached = _cachedReport!;
      onProgress?.call(
        PreloadWarmupState(
          phase: PreloadWarmupPhase.completed,
          selectedScope: scope,
          progress: 1.0,
          currentTaskLabel: 'Pamięć podręczna już rozgrzana',
          isRunning: false,
          isWarmedUp: true,
          lastReport: cached,
        ),
      );
      return cached;
    }

    if (_inFlightWarmup != null) {
      return _inFlightWarmup!;
    }

    final future = _executeWarmupSequence(
      scope: scope,
      onProgress: onProgress,
    );
    _inFlightWarmup = future;
    try {
      final report = await future;
      _cachedReport = report;
      return report;
    } finally {
      _inFlightWarmup = null;
    }
  }

  Future<PreloadWarmupReport> _executeWarmupSequence({
    required GlbWarmupScope scope,
    void Function(PreloadWarmupState state)? onProgress,
  }) async {
    final startedAt = DateTime.now();
    final totalWatch = Stopwatch()..start();
    final steps = <WarmupStepResult>[];

    void emitProgress({
      required PreloadWarmupPhase phase,
      required double progress,
      required String label,
    }) {
      onProgress?.call(
        PreloadWarmupState(
          phase: phase,
          selectedScope: scope,
          progress: progress.clamp(0.0, 1.0),
          currentTaskLabel: label,
          isRunning: true,
          isWarmedUp: false,
          lastReport: _cachedReport,
        ),
      );
    }

    // -------------------------------------------------------------------------
    // ETAP 1: Wstępna kompilacja shaderów Canvas (Skia / Impeller)
    // -------------------------------------------------------------------------
    emitProgress(
      phase: PreloadWarmupPhase.shaders,
      progress: 0.10,
      label: 'Kompilacja potoków shaderów Canvas 3D i HUD...',
    );

    final shaderOutcome = _customShaderExecutor != null
        ? await _customShaderExecutor()
        : await _warmUpCanvasShaders();

    steps.add(
      WarmupStepResult(
        id: 'canvas_shaders',
        title: 'Kompilacja shaderów Canvas',
        phase: PreloadWarmupPhase.shaders,
        status: shaderOutcome.compiledPipelinesCount > 0
            ? WarmupStepStatus.succeeded
            : WarmupStepStatus.recoveredWithFallback,
        elapsedMs: shaderOutcome.elapsedMs,
        itemsProcessed: shaderOutcome.compiledPipelinesCount,
        detail: shaderOutcome.detail,
      ),
    );

    // -------------------------------------------------------------------------
    // ETAP 2: Ładowanie i parsowanie siatek .glb rowerów i wyścigu
    // -------------------------------------------------------------------------
    emitProgress(
      phase: PreloadWarmupPhase.glbMeshes,
      progress: 0.42,
      label: 'Ładowanie siatek .glb rowerów i sceny 3D...',
    );

    final glbWatch = Stopwatch()..start();
    final targetAssetIds = _resolveTargetAssetIds(scope);
    final loadedModels = <GlbModelGeometry>[];

    const int batchSize = 4;
    for (int i = 0; i < targetAssetIds.length; i += batchSize) {
      final end = math.min(i + batchSize, targetAssetIds.length);
      final chunk = targetAssetIds.sublist(i, end);
      final chunkModels = await Future.wait(
        chunk.map((id) => _glbLoader.loadModel(id)),
      );
      loadedModels.addAll(chunkModels);

      final fraction = 0.42 + (0.38 * (end / math.max(1, targetAssetIds.length)));
      emitProgress(
        phase: PreloadWarmupPhase.glbMeshes,
        progress: fraction,
        label: 'Załadowano $end / ${targetAssetIds.length} siatek .glb',
      );
    }
    glbWatch.stop();

    final fallbackCount =
        loadedModels.where((m) => m.isProceduralFallback).length;
    final totalVertices =
        loadedModels.fold<int>(0, (sum, m) => sum + m.totalVertices);
    final totalTriangles =
        loadedModels.fold<int>(0, (sum, m) => sum + m.totalTriangles);

    steps.add(
      WarmupStepResult(
        id: 'glb_meshes',
        title: 'Siatki .glb rowerów i wyścigu',
        phase: PreloadWarmupPhase.glbMeshes,
        status: fallbackCount == 0
            ? WarmupStepStatus.succeeded
            : WarmupStepStatus.recoveredWithFallback,
        elapsedMs: glbWatch.elapsedMilliseconds,
        itemsProcessed: loadedModels.length,
        detail: fallbackCount == 0
            ? 'Załadowano ${loadedModels.length} modeli ($totalTriangles trójkątów)'
            : 'Załadowano ${loadedModels.length} modeli ($fallbackCount proceduralnych fallbacków)',
      ),
    );

    // -------------------------------------------------------------------------
    // ETAP 3: Wstępne rozgrzanie glifów czcionki Inter
    // -------------------------------------------------------------------------
    emitProgress(
      phase: PreloadWarmupPhase.fontsAndText,
      progress: 0.85,
      label: 'Rasteryzacja glifów czcionki Inter i cyfr telemetrycznych...',
    );

    final fontOutcome = _customFontExecutor != null
        ? await _customFontExecutor()
        : await _warmUpInterFonts();

    steps.add(
      WarmupStepResult(
        id: 'inter_fonts',
        title: 'Czcionka Inter i glify telemetryczne',
        phase: PreloadWarmupPhase.fontsAndText,
        status: fontOutcome.glyphBatchesWarmed > 0
            ? WarmupStepStatus.succeeded
            : WarmupStepStatus.recoveredWithFallback,
        elapsedMs: fontOutcome.elapsedMs,
        itemsProcessed: fontOutcome.glyphBatchesWarmed,
        detail: fontOutcome.detail,
      ),
    );

    totalWatch.stop();
    final completedAt = DateTime.now();

    final report = PreloadWarmupReport(
      startedAt: startedAt,
      completedAt: completedAt,
      scope: scope,
      totalDurationMs: totalWatch.elapsedMilliseconds,
      shaderCompileDurationMs: shaderOutcome.elapsedMs,
      glbLoadDurationMs: glbWatch.elapsedMilliseconds,
      fontWarmupDurationMs: fontOutcome.elapsedMs,
      shadersCompiledCount: shaderOutcome.compiledPipelinesCount,
      glbModelsLoadedCount: loadedModels.length,
      glbFallbackCount: fallbackCount,
      totalVerticesWarmed: totalVertices,
      totalTrianglesWarmed: totalTriangles,
      fontGlyphBatchesWarmed: fontOutcome.glyphBatchesWarmed,
      steps: List.unmodifiable(steps),
      jankFreeReady: shaderOutcome.compiledPipelinesCount > 0 &&
          loadedModels.isNotEmpty &&
          fontOutcome.glyphBatchesWarmed > 0,
    );

    onProgress?.call(
      PreloadWarmupState(
        phase: PreloadWarmupPhase.completed,
        selectedScope: scope,
        progress: 1.0,
        currentTaskLabel: 'Pamięć podręczna gotowa (${report.totalDurationMs} ms)',
        isRunning: false,
        isWarmedUp: true,
        lastReport: report,
      ),
    );

    return report;
  }

  List<String> _resolveTargetAssetIds(GlbWarmupScope scope) {
    switch (scope) {
      case GlbWarmupScope.bikesOnly:
        return GlbAssetCatalog.allAssets
            .where((a) => a.category == GlbAssetCategory.bike)
            .map((a) => a.id)
            .toList(growable: false);
      case GlbWarmupScope.essentialBikesAndRace:
        final bikeIds = GlbAssetCatalog.allAssets
            .where((a) => a.category == GlbAssetCategory.bike)
            .map((a) => a.id);
        const essentialRaceIds = <String>[
          'cyclist_road',
          'helmet_aero',
          'tree_pine',
          'tree_deciduous',
          'arch_finish',
          'barrier_finish',
          'road_asphalt',
          'vehicle_team_car',
          'vehicle_moto_tv',
        ];
        return <String>{...bikeIds, ...essentialRaceIds}.toList(growable: false);
      case GlbWarmupScope.fullCatalog:
        return GlbAssetCatalog.allAssets
            .map((a) => a.id)
            .toList(growable: false);
    }
  }

  /// Kompiluje kluczowe potoki shaderów Canvas na buforze offscreen 128x128 px.
  Future<ShaderWarmupOutcome> _warmUpCanvasShaders() async {
    final watch = Stopwatch()..start();
    const int size = 128;
    int compiledCount = 0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
    );

    // 1. Gradient nieba i nawierzchni asfaltowej (LinearGradient)
    final skyPaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        const Offset(0, 128),
        const [
          Color(0xFF0F1115),
          Color(0xFF1E293B),
          Color(0xFF334155),
        ],
        const [0.0, 0.55, 1.0],
      );
    canvas.drawRect(const Rect.fromLTWH(0, 0, 128, 128), skyPaint);
    compiledCount++;

    // 2. Radialny gradient słońca / refleksów kół (RadialGradient)
    final sunPaint = Paint()
      ..shader = ui.Gradient.radial(
        const Offset(64, 48),
        42,
        const [
          Color(0xFFD4AF37),
          Color(0x66D4AF37),
          Color(0x00D4AF37),
        ],
        const [0.0, 0.45, 1.0],
      );
    canvas.drawCircle(const Offset(64, 48), 42, sunPaint);
    compiledCount++;

    // 3. Miękkie cienie planarne i rozmycie Gaussa (MaskFilter.blur)
    final shadowPaint = Paint()
      ..color = const Color(0x99000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
    canvas.drawOval(const Rect.fromLTWH(24, 72, 80, 22), shadowPaint);
    compiledCount++;

    // 4. Ścieżki wektorowe wstęgi drogi i rzutowanych trójkątów 3D
    final roadPath = Path()
      ..moveTo(46, 20)
      ..lineTo(82, 20)
      ..lineTo(120, 124)
      ..lineTo(8, 124)
      ..close();
    final roadPaint = Paint()
      ..color = const Color(0xFF222630)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawPath(roadPath, roadPaint);

    final strokePaint = Paint()
      ..color = AppColors.goldAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    canvas.drawPath(roadPath, strokePaint);
    compiledCount++;

    // 5. Warstwa mieszania alpha/add (saveLayer + BlendMode) dla flar i potu
    canvas.saveLayer(
      const Rect.fromLTWH(0, 0, 128, 128),
      Paint()..blendMode = BlendMode.srcOver,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(16, 16, 96, 40),
        const Radius.circular(16),
      ),
      Paint()
        ..color = AppColors.primaryAccent.withValues(alpha: 0.75)
        ..blendMode = BlendMode.plus,
    );
    canvas.restore();
    compiledCount++;

    // 6. Rysowanie wierzchołków (drawVertices) wykorzystywane w rzutowaniu siatek
    final vertices = ui.Vertices(
      ui.VertexMode.triangles,
      const [
        Offset(32, 96),
        Offset(64, 32),
        Offset(96, 96),
      ],
      colors: const [
        Color(0xFF8E4A49),
        Color(0xFFD4AF37),
        Color(0xFF38BDF8),
      ],
    );
    canvas.drawVertices(vertices, BlendMode.modulate, Paint());
    compiledCount++;

    final picture = recorder.endRecording();
    ui.Image? rasterized;
    try {
      rasterized = await picture.toImage(size, size);
      // Krótki oddech pętli zdarzeń, aby animacja ekranu ładowania nie gubiła klatek.
      await Future<void>.delayed(Duration.zero);
    } finally {
      rasterized?.dispose();
      picture.dispose();
    }

    watch.stop();
    return ShaderWarmupOutcome(
      compiledPipelinesCount: compiledCount,
      elapsedMs: watch.elapsedMilliseconds,
      detail: 'Skompilowano $compiledCount potoków shaderów Canvas (128x128 offscreen)',
    );
  }

  /// Wstępnie rozgrzewa atlas glifów czcionki `Inter` dla wag i cyfr telemetrycznych.
  Future<FontWarmupOutcome> _warmUpInterFonts() async {
    final watch = Stopwatch()..start();
    const int size = 128;
    const weights = <FontWeight>[
      FontWeight.w400,
      FontWeight.w500,
      FontWeight.w600,
      FontWeight.w700,
    ];
    const fontSizes = <double>[11, 13, 16, 22];
    const sampleGlyphs =
        '0123456789.:+-/%°km/hWBPMLT12ZąćęłńóśźżĄĆĘŁŃÓŚŹŻ€';

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
    );

    int batches = 0;
    for (final weight in weights) {
      for (final fontSize in fontSizes) {
        final painter = TextPainter(
          text: TextSpan(
            text: sampleGlyphs,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: fontSize,
              fontWeight: weight,
              color: AppColors.textPrimary,
              fontFeatures: const [ui.FontFeature.tabularFigures()],
            ),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 2,
        )..layout(maxWidth: size.toDouble());

        painter.paint(canvas, Offset.zero);
        painter.dispose();
        batches++;
      }
    }

    final picture = recorder.endRecording();
    ui.Image? rasterized;
    try {
      rasterized = await picture.toImage(size, size);
      await Future<void>.delayed(Duration.zero);
    } finally {
      rasterized?.dispose();
      picture.dispose();
    }

    watch.stop();
    return FontWarmupOutcome(
      glyphBatchesWarmed: batches,
      elapsedMs: watch.elapsedMilliseconds,
      detail: 'Rozgrzano $batches wariantów czcionki Inter (tabularFigures)',
    );
  }
}

/// Kontroler stanu Riverpod dla [AssetBundlePreloadWarmer].
class AssetBundlePreloadWarmerNotifier
    extends StateNotifier<PreloadWarmupState> {
  final AssetBundlePreloadWarmer _warmer;

  AssetBundlePreloadWarmerNotifier(this._warmer)
      : super(const PreloadWarmupState());

  void selectScope(GlbWarmupScope scope) {
    if (state.isRunning) return;
    state = state.copyWith(selectedScope: scope, clearError: true);
  }

  Future<PreloadWarmupReport> startWarmup({bool force = false}) async {
    if (state.isRunning) {
      return _warmer.warmUp(scope: state.selectedScope);
    }

    state = state.copyWith(
      phase: PreloadWarmupPhase.shaders,
      progress: 0.05,
      currentTaskLabel: 'Inicjalizacja rozgrzewki zasobów...',
      isRunning: true,
      clearError: true,
    );

    try {
      final report = await _warmer.warmUp(
        scope: state.selectedScope,
        force: force,
        onProgress: (nextState) {
          if (mounted) {
            state = nextState;
          }
        },
      );
      if (mounted) {
        state = state.copyWith(
          phase: PreloadWarmupPhase.completed,
          progress: 1.0,
          isRunning: false,
          isWarmedUp: true,
          lastReport: report,
          currentTaskLabel:
              'Gotowe do wyścigu (${report.totalDurationMs} ms)',
        );
      }
      return report;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          phase: PreloadWarmupPhase.failed,
          isRunning: false,
          errorMessage: 'Błąd rozgrzewki: $e',
          currentTaskLabel: 'Wystąpił błąd podczas rozgrzewania zasobów',
        );
      }
      rethrow;
    }
  }

  void reset() {
    if (state.isRunning) return;
    _warmer.reset();
    state = PreloadWarmupState(selectedScope: state.selectedScope);
  }
}

/// Globalny provider Riverpoda udostępniający [AssetBundlePreloadWarmer].
final assetBundlePreloadWarmerProvider =
    Provider<AssetBundlePreloadWarmer>((ref) {
  return AssetBundlePreloadWarmer.instance;
});

/// Provider stanu rozgrzewki zasobów podczas ekranu ładowania.
final preloadWarmupStateProvider = StateNotifierProvider<
    AssetBundlePreloadWarmerNotifier, PreloadWarmupState>((ref) {
  final warmer = ref.watch(assetBundlePreloadWarmerProvider);
  return AssetBundlePreloadWarmerNotifier(warmer);
});

/// Produkcyjny panel diagnostyczno-ładowania rozgrzewki pamięci podręcznej.
///
/// Dostosowuje układ responsywnie do `390x844`, `1024x768` i `1600x900`
/// oraz obsługuje pełne stany interakcji (`hover`, `active`, `disabled`, `focus`).
class AssetBundlePreloadWarmerPanel extends ConsumerWidget {
  final VoidCallback? onReadyToStartRace;

  const AssetBundlePreloadWarmerPanel({
    super.key,
    this.onReadyToStartRace,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final warmupState = ref.watch(preloadWarmupStateProvider);
    final notifier = ref.read(preloadWarmupStateProvider.notifier);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final isCompact = width < 640;
        final isWide = width >= 1100;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2A2F3D), width: 1.0),
          ),
          padding: EdgeInsets.all(isCompact ? 14 : 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(warmupState, isCompact),
                const SizedBox(height: 16),
                _buildProgressBanner(warmupState),
                const SizedBox(height: 16),
                _buildScopeSelector(warmupState, notifier, isCompact),
                const SizedBox(height: 16),
                if (isWide && warmupState.lastReport != null)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildStepsList(warmupState),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: _buildMetricsSummary(warmupState.lastReport!),
                      ),
                    ],
                  )
                else ...[
                  _buildStepsList(warmupState),
                  if (warmupState.lastReport != null) ...[
                    const SizedBox(height: 16),
                    _buildMetricsSummary(warmupState.lastReport!),
                  ],
                ],
                const SizedBox(height: 16),
                _buildActionButtons(warmupState, notifier, isCompact),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(PreloadWarmupState state, bool isCompact) {
    final badgeColor = state.isWarmedUp
        ? AppColors.statusSuccess
        : state.isRunning
            ? AppColors.goldAccent
            : AppColors.accentBlue;

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2A2F3D)),
              ),
              child: Icon(
                state.isWarmedUp
                    ? Icons.bolt_rounded
                    : Icons.layers_rounded,
                color: badgeColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Asset Bundle Preload Warmer',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: isCompact ? 15 : 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Shadery Canvas • Siatki .glb rowerów • Glify Inter',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: badgeColor.withValues(alpha: 0.45)),
          ),
          child: Text(
            state.phase.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBanner(PreloadWarmupState state) {
    final pct = (state.progress * 100).round();
    final barColor = state.phase == PreloadWarmupPhase.failed
        ? AppColors.crimsonAlert
        : state.isWarmedUp
            ? AppColors.statusSuccess
            : AppColors.goldAccent;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  state.errorMessage ?? state.currentTaskLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: state.errorMessage != null
                        ? AppColors.crimsonAlert
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$pct%',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: barColor,
                  fontFeatures: const [ui.FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 8,
              color: AppColors.surfaceLight,
              alignment: Alignment.centerLeft,
              child: AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                widthFactor: state.progress.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScopeSelector(
    PreloadWarmupState state,
    AssetBundlePreloadWarmerNotifier notifier,
    bool isCompact,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Zakres wstępnego ładowania',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: GlbWarmupScope.values.map((scope) {
              return _WarmerScopeChip(
                label: scope.label,
                selected: state.selectedScope == scope,
                disabled: state.isRunning,
                onTap: () => notifier.selectScope(scope),
              );
            }).toList(growable: false),
          ),
        ],
      ),
    );
  }

  Widget _buildStepsList(PreloadWarmupState state) {
    final steps = state.lastReport?.steps ??
        const [
          WarmupStepResult(
            id: 'canvas_shaders',
            title: 'Kompilacja shaderów Canvas',
            phase: PreloadWarmupPhase.shaders,
            status: WarmupStepStatus.pending,
            elapsedMs: 0,
            itemsProcessed: 0,
            detail: 'Gradienty, rozmycia MaskFilter, saveLayer, drawVertices',
          ),
          WarmupStepResult(
            id: 'glb_meshes',
            title: 'Siatki .glb rowerów i wyścigu',
            phase: PreloadWarmupPhase.glbMeshes,
            status: WarmupStepStatus.pending,
            elapsedMs: 0,
            itemsProcessed: 0,
            detail: 'Ramy aero/climbing/TT, koła i modele sceny 3D',
          ),
          WarmupStepResult(
            id: 'inter_fonts',
            title: 'Czcionka Inter i glify telemetryczne',
            phase: PreloadWarmupPhase.fontsAndText,
            status: WarmupStepStatus.pending,
            elapsedMs: 0,
            itemsProcessed: 0,
            detail: 'Rasteryzacja cyfr tabularFigures przed startem etapu',
          ),
        ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Etapy eliminacji Shader Compilation Jank',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ...steps.map((step) => _buildStepRow(step)),
        ],
      ),
    );
  }

  Widget _buildStepRow(WarmupStepResult step) {
    final Color statusColor;
    final IconData statusIcon;
    switch (step.status) {
      case WarmupStepStatus.pending:
        statusColor = AppColors.textSecondary;
        statusIcon = Icons.radio_button_unchecked_rounded;
      case WarmupStepStatus.running:
        statusColor = AppColors.goldAccent;
        statusIcon = Icons.autorenew_rounded;
      case WarmupStepStatus.succeeded:
        statusColor = AppColors.statusSuccess;
        statusIcon = Icons.check_circle_rounded;
      case WarmupStepStatus.recoveredWithFallback:
        statusColor = AppColors.amberWarning;
        statusIcon = Icons.shield_rounded;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(statusIcon, size: 17, color: statusColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  step.detail,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (step.elapsedMs > 0 || step.itemsProcessed > 0)
            Text(
              '${step.elapsedMs} ms',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: statusColor,
                fontFeatures: const [ui.FontFeature.tabularFigures()],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetricsSummary(PreloadWarmupReport report) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Telemetria pamięci podręcznej',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetricBadge(
                label: 'Czas całkowity',
                value: '${report.totalDurationMs} ms',
                accent: AppColors.goldAccent,
              ),
              _MetricBadge(
                label: 'Potoki shaderów',
                value: '${report.shadersCompiledCount}',
                accent: AppColors.accentBlue,
              ),
              _MetricBadge(
                label: 'Modele .glb',
                value: '${report.glbModelsLoadedCount}',
                accent: AppColors.statusSuccess,
              ),
              _MetricBadge(
                label: 'Trójkąty 3D',
                value: '${report.totalTrianglesWarmed}',
                accent: AppColors.cyanAccent,
              ),
              _MetricBadge(
                label: 'Warianty Inter',
                value: '${report.fontGlyphBatchesWarmed}',
                accent: AppColors.textPrimary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    PreloadWarmupState state,
    AssetBundlePreloadWarmerNotifier notifier,
    bool isCompact,
  ) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.end,
      children: [
        _WarmerActionButton(
          label: 'Resetuj',
          icon: Icons.refresh_rounded,
          isPrimary: false,
          disabled: state.isRunning || !state.isWarmedUp,
          onPressed: notifier.reset,
        ),
        _WarmerActionButton(
          label: state.isWarmedUp
              ? 'Rozgrzej ponownie'
              : 'Rozgrzej Cache (Warmup)',
          icon: Icons.flash_on_rounded,
          isPrimary: true,
          disabled: state.isRunning,
          onPressed: () => notifier.startWarmup(force: true),
        ),
        if (onReadyToStartRace != null)
          _WarmerActionButton(
            label: 'Przejdź do wyścigu',
            icon: Icons.play_arrow_rounded,
            isPrimary: true,
            disabled: state.isRunning || !state.isWarmedUp,
            onPressed: onReadyToStartRace!,
          ),
      ],
    );
  }
}

class _MetricBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _MetricBadge({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: accent,
              fontFeatures: const [ui.FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _WarmerScopeChip extends StatefulWidget {
  final String label;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  const _WarmerScopeChip({
    required this.label,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  @override
  State<_WarmerScopeChip> createState() => _WarmerScopeChipState();
}

class _WarmerScopeChipState extends State<_WarmerScopeChip> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.disabled
        ? AppColors.surfaceLight.withValues(alpha: 0.45)
        : widget.selected
            ? AppColors.primaryAccent.withValues(alpha: _pressed ? 0.95 : 0.85)
            : _pressed
                ? AppColors.surfaceLight
                : _hovered
                    ? const Color(0xFF2B303D)
                    : AppColors.surfaceLight;

    final borderColor = _focused
        ? AppColors.goldAccent
        : widget.selected
            ? AppColors.goldAccent.withValues(alpha: 0.8)
            : const Color(0xFF2A2F3D);

    return FocusableActionDetector(
      enabled: !widget.disabled,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      mouseCursor: widget.disabled
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (!widget.disabled) widget.onTap();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown: widget.disabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: widget.disabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.disabled ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: borderColor,
              width: _focused ? 1.5 : 1.0,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
              color: widget.disabled
                  ? AppColors.textSecondary.withValues(alpha: 0.5)
                  : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _WarmerActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final bool disabled;
  final VoidCallback onPressed;

  const _WarmerActionButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.disabled,
    required this.onPressed,
  });

  @override
  State<_WarmerActionButton> createState() => _WarmerActionButtonState();
}

class _WarmerActionButtonState extends State<_WarmerActionButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final Color baseColor = widget.isPrimary
        ? AppColors.primaryAccent
        : AppColors.surfaceLight;

    final Color bgColor = widget.disabled
        ? baseColor.withValues(alpha: 0.35)
        : _pressed
            ? baseColor.withValues(alpha: 0.8)
            : _hovered
                ? Color.lerp(baseColor, AppColors.goldAccent, 0.14)!
                : baseColor;

    final Color borderColor = _focused
        ? AppColors.goldAccent
        : widget.isPrimary
            ? AppColors.goldAccent.withValues(alpha: widget.disabled ? 0.25 : 0.6)
            : const Color(0xFF2A2F3D);

    final Color textColor = widget.disabled
        ? AppColors.textSecondary.withValues(alpha: 0.55)
        : AppColors.textPrimary;

    return FocusableActionDetector(
      enabled: !widget.disabled,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      mouseCursor: widget.disabled
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (!widget.disabled) widget.onPressed();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown: widget.disabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: widget.disabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.disabled ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: _focused ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 16, color: textColor),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
