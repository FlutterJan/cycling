import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/config/app_feature_flags_and_presets.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';

void main() {
  group('AppFeatureFlagsAndPresets', () {
    test('detects all predefined presets and custom fallback', () {
      for (final preset in AppFeatureFlagsAndPresets.presets) {
        final detected = AppFeatureFlagsAndPresets.detectMatchingPreset(
          preset.flags,
        );
        expect(detected, preset.id);
      }

      final modified = GameplayRealismFlags.balancedDefault().copyWith(
        crashFrequencyMultiplier: 1.9,
      );
      expect(
        AppFeatureFlagsAndPresets.detectMatchingPreset(modified),
        GameplayRealismPresetId.custom,
      );
    });

    test('JSON round-trip preserves flags and state', () {
      final originalState = AppFeatureFlagsState(
        activePresetId: GameplayRealismPresetId.proSimulation,
        flags: AppFeatureFlagsAndPresets.presetById(
          GameplayRealismPresetId.proSimulation,
        ).flags,
        isLockedInActiveCareer: true,
        lastUpdatedAt: DateTime.utc(2026, 7, 1, 12, 0),
      );

      final json = originalState.toJson();
      final restored = AppFeatureFlagsState.fromJson(json);

      expect(restored.activePresetId, originalState.activePresetId);
      expect(restored.flags, originalState.flags);
      expect(restored.isLockedInActiveCareer, isTrue);
      expect(restored.lastUpdatedAt, originalState.lastUpdatedAt);
    });

    test('notifier updates flags, detects custom and respects career lock', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(appFeatureFlagsProvider.notifier);
      expect(
        container.read(appFeatureFlagsProvider).activePresetId,
        GameplayRealismPresetId.balancedWorldTour,
      );

      expect(notifier.applyPreset(GameplayRealismPresetId.ironmanHardcore), isTrue);
      expect(
        container.read(appFeatureFlagsProvider).activePresetId,
        GameplayRealismPresetId.ironmanHardcore,
      );
      expect(
        container.read(activeRealismScoreProvider),
        greaterThanOrEqualTo(80),
      );

      expect(
        notifier.toggleBooleanFlag('enableCrosswindEchelons', false),
        isTrue,
      );
      expect(
        container.read(appFeatureFlagsProvider).activePresetId,
        GameplayRealismPresetId.custom,
      );

      notifier.setCareerLock(true);
      expect(notifier.applyPreset(GameplayRealismPresetId.arcade), isFalse);
      expect(
        container.read(appFeatureFlagsProvider).activePresetId,
        GameplayRealismPresetId.custom,
      );
    });

    test('diffFromPreset and validateFlags report accurate diagnostics', () {
      final arcade = AppFeatureFlagsAndPresets.presetById(
        GameplayRealismPresetId.arcade,
      ).flags;
      final diffs = AppFeatureFlagsAndPresets.diffFromPreset(
        arcade,
        GameplayRealismPresetId.balancedWorldTour,
      );
      expect(diffs, isNotEmpty);

      final inconsistent = GameplayRealismFlags.balancedDefault().copyWith(
        telemetryVisibility: TelemetryVisibilityMode.blindClassic,
        enableTeamBusWarmupAndConvoy: true,
      );
      final validation = AppFeatureFlagsAndPresets.validateFlags(inconsistent);
      expect(validation.isValid, isFalse);
      expect(validation.warnings, isNotEmpty);
    });
  });

  group('AppFeatureFlagsAndPresetsPanel responsive layout', () {
    for (final size in const <Size>[
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets('renders cleanly without overflow at ${size.width}x${size.height}', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              home: const Scaffold(
                body: Padding(
                  padding: EdgeInsets.all(12),
                  child: AppFeatureFlagsAndPresetsPanel(),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Rejestr Realizmu Rozgrywki'), findsOneWidget);
        expect(find.text('Ironman Hardcore'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
