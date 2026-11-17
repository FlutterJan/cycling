import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_colors.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/core/theme/colorblind_accessibility_palettes.dart';

void main() {
  group('ColorblindAccessibilityPalettes', () {
    test('defines exactly 4 colorblind palettes plus standard baseline', () {
      expect(ColorblindAccessibilityPalettes.colorblindModes.length, 4);
      expect(
        ColorblindAccessibilityPalettes.colorblindModes,
        containsAll([
          ColorblindPaletteMode.protanopia,
          ColorblindPaletteMode.deuteranopia,
          ColorblindPaletteMode.tritanopia,
          ColorblindPaletteMode.achromatopsia,
        ]),
      );

      for (final mode in ColorblindPaletteMode.values) {
        final palette = ColorblindAccessibilityPalettes.forMode(mode);
        expect(palette.mode, mode);
        expect(palette.powerZones.length, 7);
        expect(
          palette.semanticRoles.length,
          AccessibilitySemanticRole.values.length,
        );
        expect(
          palette.pelotonGroups.length,
          PelotonVisualGroupRole.values.length,
        );
      }
    });

    test('each palette dual-codes power zones Z1-Z7 with 7 unique shapes', () {
      for (final mode in ColorblindPaletteMode.values) {
        final palette = ColorblindAccessibilityPalettes.forMode(mode);
        final shapes = <AccessibilityShapeType>{};
        final colors = <Color>{};

        for (int z = 1; z <= 7; z++) {
          final token = palette.powerZone(z);
          shapes.add(token.shape);
          colors.add(token.color);
          expect(token.shortCode, 'Z$z');
          if (mode.isColorblindMode) {
            expect(
              token.contrastRatioAgainst(AppColors.background),
              greaterThanOrEqualTo(3.0),
              reason: 'Zone $z in $mode should have >= 3.0 contrast vs dark bg',
            );
          }
        }

        expect(shapes.length, 7);
        expect(colors.length, 7);
      }
    });

    test('simulateColor converts to grayscale under achromatopsia', () {
      const sample = Color(0xFF38BDF8);
      final simulated = ColorblindAccessibilityPalettes.simulateColor(
        sample,
        ColorblindPaletteMode.achromatopsia,
      );
      expect((simulated.r - simulated.g).abs(), lessThan(0.001));
      expect((simulated.g - simulated.b).abs(), lessThan(0.001));

      expect(
        ColorblindAccessibilityPalettes.simulateColor(
          sample,
          ColorblindPaletteMode.standard,
        ),
        sample,
      );
    });

    test('ColorblindPaletteMode.fromId falls back to standard', () {
      expect(
        ColorblindPaletteMode.fromId('deuteranopia'),
        ColorblindPaletteMode.deuteranopia,
      );
      expect(
        ColorblindPaletteMode.fromId('unknown_mode'),
        ColorblindPaletteMode.standard,
      );
      expect(
        ColorblindPaletteMode.fromId(null),
        ColorblindPaletteMode.standard,
      );
    });
  });

  group('ColorblindAccessibilityNotifier', () {
    test('updates mode, toggles, and resets cleanly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(colorblindAccessibilityProvider).mode,
        ColorblindPaletteMode.standard,
      );

      final notifier =
          container.read(colorblindAccessibilityProvider.notifier);
      notifier.setMode(ColorblindPaletteMode.deuteranopia);
      notifier.setPatternOverlay(false);
      notifier.setHighContrastBorders(true);
      notifier.setSimulateInPreview(true);

      final updated = container.read(colorblindAccessibilityProvider);
      expect(updated.mode, ColorblindPaletteMode.deuteranopia);
      expect(updated.enableShapeDualCoding, isTrue);
      expect(updated.enablePatternOverlay, isFalse);
      expect(updated.highContrastBorders, isTrue);
      expect(updated.simulateInPreview, isTrue);
      expect(
        container.read(activeColorblindPaletteProvider).mode,
        ColorblindPaletteMode.deuteranopia,
      );

      notifier.resetToDefault();
      expect(
        container.read(colorblindAccessibilityProvider),
        const ColorblindAccessibilityState(),
      );
    });
  });

  group('ColorblindAccessibilitySettingsPanel Widget', () {
    Future<void> pumpPanelAtSize(
      WidgetTester tester,
      Size size,
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
              body: SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: ColorblindAccessibilitySettingsPanel(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renders without overflow at 390x844 mobile', (tester) async {
      await pumpPanelAtSize(tester, const Size(390, 844));
      expect(find.text('Dostępność Wizualna (Daltonizm)'), findsOneWidget);
      expect(find.text('Z4'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow at 1024x768 tablet', (tester) async {
      await pumpPanelAtSize(tester, const Size(1024, 768));
      expect(find.text('Deuteranopia (Brak zieleni)'), findsOneWidget);
      expect(find.text('Z4 Próg FTP'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow at 1600x900 desktop and switches mode',
        (tester) async {
      await pumpPanelAtSize(tester, const Size(1600, 900));

      await tester.tap(find.text('Protanopia (Brak czerwieni)'));
      await tester.pump(const Duration(milliseconds: 300));

      final element =
          tester.element(find.byType(ColorblindAccessibilitySettingsPanel));
      final container = ProviderScope.containerOf(element);
      expect(
        container.read(colorblindAccessibilityProvider).mode,
        ColorblindPaletteMode.protanopia,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
