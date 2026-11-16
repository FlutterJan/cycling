import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/diagnostics/asset_bundle_preload_warmer.dart';
import 'package:pro_peloton_manager/engine/rendering3d/glb_asset_loader_service.dart';

void main() {
  group('AssetBundlePreloadWarmer', () {
    late GlbAssetLoaderService glbLoader;
    late AssetBundlePreloadWarmer warmer;

    setUp(() {
      glbLoader = GlbAssetLoaderService();
      warmer = AssetBundlePreloadWarmer(glbLoader: glbLoader);
    });

    test('warmUp bikesOnly preloads bike .glb meshes, shaders and Inter fonts',
        () async {
      final progressEvents = <PreloadWarmupState>[];
      final report = await warmer.warmUp(
        scope: GlbWarmupScope.bikesOnly,
        onProgress: progressEvents.add,
      );

      expect(report.jankFreeReady, isTrue);
      expect(report.shadersCompiledCount, greaterThanOrEqualTo(6));
      expect(report.glbModelsLoadedCount, greaterThanOrEqualTo(8));
      expect(report.fontGlyphBatchesWarmed, equals(16));
      expect(report.totalTrianglesWarmed, greaterThan(0));
      expect(report.steps.length, equals(3));

      expect(glbLoader.isModelCached('frame_aero'), isTrue);
      expect(glbLoader.isModelCached('frame_climbing'), isTrue);
      expect(glbLoader.isModelCached('frame_tt'), isTrue);
      expect(glbLoader.isModelCached('wheel_50mm'), isTrue);

      expect(progressEvents, isNotEmpty);
      expect(progressEvents.last.isWarmedUp, isTrue);
      expect(progressEvents.last.progress, equals(1.0));
    });

    test('warmUp is idempotent when force is false and resets cleanly',
        () async {
      final first = await warmer.warmUp(scope: GlbWarmupScope.bikesOnly);
      final second = await warmer.warmUp(scope: GlbWarmupScope.bikesOnly);

      expect(identical(first, second), isTrue);
      expect(warmer.isWarmedUp, isTrue);

      warmer.reset();
      expect(warmer.isWarmedUp, isFalse);
      expect(warmer.cachedReport, isNull);

      final third = await warmer.warmUp(scope: GlbWarmupScope.bikesOnly);
      expect(identical(first, third), isFalse);
    });

    test('concurrent warmUp calls share the same in-flight Future', () async {
      int shaderCalls = 0;
      final customWarmer = AssetBundlePreloadWarmer(
        glbLoader: glbLoader,
        shaderExecutor: () async {
          shaderCalls++;
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return const ShaderWarmupOutcome(
            compiledPipelinesCount: 6,
            elapsedMs: 20,
            detail: 'Test shader compile',
          );
        },
        fontExecutor: () async => const FontWarmupOutcome(
          glyphBatchesWarmed: 16,
          elapsedMs: 5,
          detail: 'Test font warmup',
        ),
      );

      final results = await Future.wait([
        customWarmer.warmUp(scope: GlbWarmupScope.bikesOnly),
        customWarmer.warmUp(scope: GlbWarmupScope.bikesOnly),
      ]);

      expect(shaderCalls, equals(1));
      expect(identical(results[0], results[1]), isTrue);
    });

    test('essentialBikesAndRace loads bike frames and core race assets',
        () async {
      final report = await warmer.warmUp(
        scope: GlbWarmupScope.essentialBikesAndRace,
      );

      expect(report.jankFreeReady, isTrue);
      expect(glbLoader.isModelCached('frame_aero'), isTrue);
      expect(glbLoader.isModelCached('cyclist_road'), isTrue);
      expect(glbLoader.isModelCached('road_asphalt'), isTrue);
      expect(glbLoader.isModelCached('arch_finish'), isTrue);
    });
  });

  group('AssetBundlePreloadWarmerNotifier & Panel UI', () {
    test('notifier transitions from idle to completed and resets', () async {
      final glbLoader = GlbAssetLoaderService();
      final warmer = AssetBundlePreloadWarmer(
        glbLoader: glbLoader,
        shaderExecutor: () async => const ShaderWarmupOutcome(
          compiledPipelinesCount: 6,
          elapsedMs: 4,
          detail: 'Shaders OK',
        ),
        fontExecutor: () async => const FontWarmupOutcome(
          glyphBatchesWarmed: 16,
          elapsedMs: 3,
          detail: 'Fonts OK',
        ),
      );

      final notifier = AssetBundlePreloadWarmerNotifier(warmer);
      expect(notifier.state.phase, equals(PreloadWarmupPhase.idle));

      notifier.selectScope(GlbWarmupScope.bikesOnly);
      expect(notifier.state.selectedScope, equals(GlbWarmupScope.bikesOnly));

      await notifier.startWarmup();
      expect(notifier.state.isWarmedUp, isTrue);
      expect(notifier.state.phase, equals(PreloadWarmupPhase.completed));
      expect(notifier.state.lastReport, isNotNull);

      notifier.reset();
      expect(notifier.state.isWarmedUp, isFalse);
      expect(notifier.state.phase, equals(PreloadWarmupPhase.idle));
    });

    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
          'AssetBundlePreloadWarmerPanel renders cleanly without overflow at ${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final glbLoader = GlbAssetLoaderService();
        final warmer = AssetBundlePreloadWarmer(
          glbLoader: glbLoader,
          shaderExecutor: () async => const ShaderWarmupOutcome(
            compiledPipelinesCount: 6,
            elapsedMs: 4,
            detail: 'Shaders OK',
          ),
          fontExecutor: () async => const FontWarmupOutcome(
            glyphBatchesWarmed: 16,
            elapsedMs: 3,
            detail: 'Fonts OK',
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              assetBundlePreloadWarmerProvider.overrideWithValue(warmer),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: size.width,
                    height: size.height,
                    child: AssetBundlePreloadWarmerPanel(
                      onReadyToStartRace: () {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Asset Bundle Preload Warmer'), findsOneWidget);
        expect(find.text('Rozgrzej Cache (Warmup)'), findsOneWidget);

        await tester.ensureVisible(find.text('Rozgrzej Cache (Warmup)'));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(find.text('Rozgrzej Cache (Warmup)'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Gotowe (Zero Jank)'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
