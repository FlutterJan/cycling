import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/config/app_feature_flags_and_presets.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/ui/widgets/career_realism_customizer_panel.dart';

void main() {
  Widget buildTestApp({
    required Size viewportSize,
    ValueChanged<GameplayRealismPresetId>? onPresetSelected,
    ValueChanged<GameplayRealismFlags>? onFlagsChanged,
    void Function(GameplayRealismPresetId, GameplayRealismFlags)?
        onConfirmStartCareer,
    VoidCallback? onCancel,
    bool initialExpandedCustomizations = false,
  }) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: MediaQuery(
          data: MediaQueryData(size: viewportSize),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: viewportSize.width,
                height: viewportSize.height,
                child: CareerRealismCustomizerPanel(
                  onPresetSelected: onPresetSelected,
                  onFlagsChanged: onFlagsChanged,
                  onConfirmStartCareer: onConfirmStartCareer,
                  onCancel: onCancel,
                  initialExpandedCustomizations: initialExpandedCustomizations,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('CareerRealismCustomizerPanel', () {
    testWidgets('renders presets, selects Ironman and confirms start', (
      tester,
    ) async {
      GameplayRealismPresetId? selectedPreset;
      GameplayRealismPresetId? confirmedPreset;
      GameplayRealismFlags? confirmedFlags;

      await tester.pumpWidget(
        buildTestApp(
          viewportSize: const Size(1600, 900),
          onPresetSelected: (id) => selectedPreset = id,
          onConfirmStartCareer: (id, flags) {
            confirmedPreset = id;
            confirmedFlags = flags;
          },
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Konfigurator Realizmu Nowej Kariery'), findsOneWidget);
      expect(find.text('Arcade / Swobodny'), findsOneWidget);
      expect(find.text('WorldTour Standard'), findsOneWidget);
      expect(find.text('Pro Simulation'), findsOneWidget);
      expect(find.text('Ironman Hardcore'), findsOneWidget);
      expect(find.text('Złota Era Retro'), findsOneWidget);

      await tester.tap(find.text('Ironman Hardcore'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(selectedPreset, GameplayRealismPresetId.ironmanHardcore);
      expect(find.text('Aktywny tryb: Ironman Hardcore'), findsOneWidget);

      await tester.ensureVisible(
        find.text('Zatwierdź i Rozpocznij Karierę'),
      );
      await tester.tap(find.text('Zatwierdź i Rozpocznij Karierę'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(confirmedPreset, GameplayRealismPresetId.ironmanHardcore);
      expect(
        confirmedFlags?.saveIntegrity,
        SaveIntegrityMode.ironmanSingleSlot,
      );
    });

    testWidgets('expands customizer, toggles flag to custom and resets', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          viewportSize: const Size(1280, 900),
          initialExpandedCustomizations: true,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Wachlarze na wietrze bocznym'), findsOneWidget);

      await tester.ensureVisible(find.text('Wachlarze na wietrze bocznym'));
      await tester.tap(find.text('Wachlarze na wietrze bocznym'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Aktywny tryb: Własna Konfiguracja'), findsOneWidget);
      expect(find.text('Przywróć WorldTour Standard'), findsOneWidget);

      await tester.ensureVisible(find.text('Przywróć WorldTour Standard'));
      await tester.tap(find.text('Przywróć WorldTour Standard'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Aktywny tryb: WorldTour Standard'), findsOneWidget);
    });

    testWidgets('responsive without overflow on 390x844, 1024x768, 1600x900', (
      tester,
    ) async {
      for (final size in const <Size>[
        Size(390, 844),
        Size(1024, 768),
        Size(1600, 900),
      ]) {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(
          buildTestApp(
            viewportSize: size,
            initialExpandedCustomizations: true,
            onCancel: () {},
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
      }
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('shows lock banner and disables confirm when career is locked', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(appFeatureFlagsProvider.notifier).setCareerLock(true);

      var confirmed = false;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: CareerRealismCustomizerPanel(
                onConfirmStartCareer: (_, __) => confirmed = true,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.textContaining('Konfiguracja realizmu jest zablokowana'),
        findsOneWidget,
      );

      await tester.ensureVisible(
        find.text('Zatwierdź i Rozpocznij Karierę'),
      );
      await tester.tap(find.text('Zatwierdź i Rozpocznij Karierę'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(confirmed, isFalse);
    });
  });
}
