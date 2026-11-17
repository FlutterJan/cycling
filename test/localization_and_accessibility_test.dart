import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/l10n/app_localizations_pl_en.dart';
import 'package:pro_peloton_manager/core/theme/app_colors.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/core/theme/colorblind_accessibility_palettes.dart';

double _wcagContrast(Color a, Color b) {
  final l1 = a.computeLuminance();
  final l2 = b.computeLuminance();
  final lighter = math.max(l1, l2);
  final darker = math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('PL/EN Localization & Cycling Jargon Dictionaries', () {
    test('BilingualCyclingDictionary passes completeness and uniqueness audit',
        () {
      final report = BilingualCyclingDictionary.auditCompleteness();
      expect(report.isComplete, isTrue);
      expect(report.emptyOrInvalidKeys, isEmpty);
      expect(report.duplicateKeys, isEmpty);
      expect(report.totalUiKeys, greaterThan(0));
      expect(report.totalJargonEntries, greaterThan(0));

      for (final domain in AppL10nDomain.values) {
        expect(domain.label(AppLanguage.pl).trim(), isNotEmpty);
        expect(domain.label(AppLanguage.en).trim(), isNotEmpty);
      }
    });

    test('BilingualCyclingDictionary translates, formats params, and pluralizes',
        () {
      expect(
        BilingualCyclingDictionary.translate('hud_power_watts', AppLanguage.pl),
        'Moc (W)',
      );
      expect(
        BilingualCyclingDictionary.translate('hud_power_watts', AppLanguage.en),
        'Power (W)',
      );

      // Fallback to AppLocalizationsPlEn with parameter interpolation
      expect(
        BilingualCyclingDictionary.translate(
          'settings_header_career_subtitle',
          AppLanguage.pl,
          params: {'saveName': 'Alpecin', 'seasonYear': 2026},
        ),
        'Kariera: Alpecin • Sezon 2026',
      );
      expect(
        BilingualCyclingDictionary.translate(
          'settings_header_career_subtitle',
          AppLanguage.en,
          params: {'saveName': 'Alpecin', 'seasonYear': 2026},
        ),
        'Career: Alpecin • Season 2026',
      );

      // Unknown key returns key itself
      expect(
        BilingualCyclingDictionary.translate(
          'non_existent_key_xyz',
          AppLanguage.en,
        ),
        'non_existent_key_xyz',
      );

      // Polish & English pluralization rules
      expect(
        BilingualCyclingDictionary.pluralize(
          AppLanguage.pl,
          1,
          plOne: 'etap',
          plFew: 'etapy',
          plMany: 'etapów',
          enOne: 'stage',
          enMany: 'stages',
        ),
        '1 etap',
      );
      expect(
        BilingualCyclingDictionary.pluralize(
          AppLanguage.pl,
          3,
          plOne: 'etap',
          plFew: 'etapy',
          plMany: 'etapów',
          enOne: 'stage',
          enMany: 'stages',
        ),
        '3 etapy',
      );
      expect(
        BilingualCyclingDictionary.pluralize(
          AppLanguage.pl,
          12,
          plOne: 'etap',
          plFew: 'etapy',
          plMany: 'etapów',
          enOne: 'stage',
          enMany: 'stages',
        ),
        '12 etapów',
      );
      expect(
        BilingualCyclingDictionary.pluralize(
          AppLanguage.pl,
          24,
          plOne: 'etap',
          plFew: 'etapy',
          plMany: 'etapów',
          enOne: 'stage',
          enMany: 'stages',
        ),
        '24 etapy',
      );
      expect(
        BilingualCyclingDictionary.pluralize(
          AppLanguage.en,
          1,
          plOne: 'etap',
          plFew: 'etapy',
          plMany: 'etapów',
          enOne: 'stage',
          enMany: 'stages',
        ),
        '1 stage',
      );
      expect(
        BilingualCyclingDictionary.pluralize(
          AppLanguage.en,
          5,
          plOne: 'etap',
          plFew: 'etapy',
          plMany: 'etapów',
          enOne: 'stage',
          enMany: 'stages',
        ),
        '5 stages',
      );
    });

    test('BilingualCyclingDictionary searchJargon filters by query and domain',
        () {
      final allEntries = BilingualCyclingDictionary.searchJargon('');
      expect(allEntries.length, BilingualCyclingDictionary.jargonEntries.length);

      final domainEntries = BilingualCyclingDictionary.entriesForDomain(
        AppL10nDomain.pelotonTactics,
      );
      expect(domainEntries, isNotEmpty);
      expect(
        domainEntries.every((e) => e.domain == AppL10nDomain.pelotonTactics),
        isTrue,
      );

      final filtered = BilingualCyclingDictionary.searchJargon(
        domainEntries.first.en,
        domain: AppL10nDomain.pelotonTactics,
      );
      expect(filtered, isNotEmpty);
      expect(filtered.any((e) => e.key == domainEntries.first.key), isTrue);
    });

    test('AppLocalizationsPlEn covers all keys in PL & EN and glossary', () {
      const pl = AppLocalizationsPlEn.pl;
      const en = AppLocalizationsPlEn.en;

      expect(pl.isPolish, isTrue);
      expect(pl.isEnglish, isFalse);
      expect(en.isEnglish, isTrue);
      expect(en.isPolish, isFalse);
      expect(pl.dictionarySize, greaterThan(0));
      expect(pl.dictionarySize, en.dictionarySize);

      for (final key in pl.availableKeys) {
        final plVal = pl.t(key);
        final enVal = en.t(key);
        expect(plVal.trim(), isNotEmpty, reason: 'Empty PL for $key');
        expect(enVal.trim(), isNotEmpty, reason: 'Empty EN for $key');
      }

      // Cycling jargon getters differ appropriately where expected
      expect(pl.echelons, isNotEmpty);
      expect(en.echelons, isNotEmpty);
      expect(pl.bonking, isNotEmpty);
      expect(en.bonking, isNotEmpty);
      expect(pl.stickyBottle, isNotEmpty);
      expect(en.stickyBottle, isNotEmpty);
      expect(pl.yellowJersey, isNotEmpty);
      expect(en.yellowJersey, isNotEmpty);

      // Cycling glossary entries are complete
      expect(AppLocalizationsPlEn.cyclingGlossary, isNotEmpty);
      for (final entry in AppLocalizationsPlEn.cyclingGlossary) {
        expect(entry.key.trim(), isNotEmpty);
        expect(entry.term(AppLanguage.pl).trim(), isNotEmpty);
        expect(entry.term(AppLanguage.en).trim(), isNotEmpty);
        expect(entry.description(AppLanguage.pl).trim(), isNotEmpty);
        expect(entry.description(AppLanguage.en).trim(), isNotEmpty);
      }

      final searchRes = pl.searchGlossary('echelon');
      expect(searchRes, isNotEmpty);

      // AppLanguage JSON serialization round-trip
      expect(AppLanguage.fromJson('pl'), AppLanguage.pl);
      expect(AppLanguage.fromJson('EN'), AppLanguage.en);
      expect(AppLanguage.fromJson('unknown'), AppLanguage.pl);
    });

    test('AppL10nDelegate supports pl/en and loads synchronously', () async {
      const delegate = AppL10nDelegate();
      expect(delegate.isSupported(const Locale('pl')), isTrue);
      expect(delegate.isSupported(const Locale('en')), isTrue);
      expect(delegate.isSupported(const Locale('fr')), isFalse);
      expect(delegate.shouldReload(delegate), isFalse);

      final loadedPl = await delegate.load(const Locale('pl'));
      final loadedEn = await delegate.load(const Locale('en'));
      expect(loadedPl.language, AppLanguage.pl);
      expect(loadedEn.language, AppLanguage.en);
    });

    testWidgets('AppLocalizationsScope provides context.l10n and updates',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: AppLocalizationsScope(
            localizations: AppLocalizationsPlEn.pl,
            child: Builder(
              builder: (context) => Text(context.l10n.t('language_label')),
            ),
          ),
        ),
      );
      expect(find.text('Język gry'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: AppLocalizationsScope(
            localizations: AppLocalizationsPlEn.en,
            child: Builder(
              builder: (context) => Text(context.l10n.t('language_label')),
            ),
          ),
        ),
      );
      expect(find.text('Game Language'), findsOneWidget);
    });

    for (final viewport in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
          'CyclingJargonDictionaryPanel renders cleanly at ${viewport.width.toInt()}x${viewport.height.toInt()}',
          (tester) async {
        tester.view.physicalSize = viewport;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        AppLanguage? switchedTo;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: SingleChildScrollView(
                child: CyclingJargonDictionaryPanel(
                  initialLanguage: AppLanguage.pl,
                  onLanguageChanged: (lang) => switchedTo = lang,
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull);
        expect(find.byType(CyclingJargonDictionaryPanel), findsOneWidget);

        // Switch language to EN
        final enButton = find.text('EN');
        expect(enButton, findsWidgets);
        await tester.tap(enButton.first);
        await tester.pump(const Duration(milliseconds: 300));
        expect(switchedTo, AppLanguage.en);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Colorblind Accessibility Palettes & Contrast Verification', () {
    test('AppColors typography and telemetry accents meet WCAG contrast on dark surfaces',
        () {
      const surfaces = [
        AppColors.background,
        AppColors.surface,
        AppColors.surfaceLight,
      ];

      // Primary text must meet WCAG AAA (>= 7.0) on all core dark surfaces
      for (final bg in surfaces) {
        expect(
          _wcagContrast(AppColors.textPrimary, bg),
          greaterThanOrEqualTo(7.0),
          reason: 'textPrimary contrast against $bg',
        );
      }

      // Secondary text must meet WCAG AA (>= 4.5) on background & surface
      for (final bg in [AppColors.background, AppColors.surface]) {
        expect(
          _wcagContrast(AppColors.textSecondary, bg),
          greaterThanOrEqualTo(4.5),
          reason: 'textSecondary contrast against $bg',
        );
      }

      // Key telemetry & status accents meet >= 3.0 UI contrast on background
      for (final accent in const [
        AppColors.goldAccent,
        AppColors.accentBlue,
        AppColors.cyanAccent,
        AppColors.statusSuccess,
        AppColors.amberWarning,
        AppColors.crimsonAlert,
      ]) {
        expect(
          _wcagContrast(accent, AppColors.background),
          greaterThanOrEqualTo(3.0),
          reason: 'Accent $accent contrast against background',
        );
      }
    });

    test('All 5 ColorblindPaletteMode palettes have complete tokens and valid contrast',
        () {
      for (final mode in ColorblindPaletteMode.values) {
        expect(ColorblindPaletteMode.fromId(mode.id), mode);
        expect(mode.labelPl.trim(), isNotEmpty);
        expect(mode.labelEn.trim(), isNotEmpty);
        expect(mode.descriptionPl.trim(), isNotEmpty);
        expect(mode.descriptionEn.trim(), isNotEmpty);

        final palette = ColorblindAccessibilityPalettes.forMode(mode);
        expect(palette.mode, mode);

        // All 7 Coggan power zones present with distinct colors & non-empty labels
        final zoneColors = <Color>{};
        for (var z = 1; z <= 7; z++) {
          final token = palette.powerZone(z);
          expect(token.labelPl.trim(), isNotEmpty);
          expect(token.labelEn.trim(), isNotEmpty);
          zoneColors.add(token.color);
          expect(
            token.contrastRatioAgainst(AppColors.background),
            greaterThanOrEqualTo(3.0),
            reason: '${mode.id} Z$z contrast against background',
          );
        }
        expect(zoneColors.length, 7,
            reason: '${mode.id} power zones should have 7 distinct colors');

        // All semantic roles present with localized labels
        for (final role in AccessibilitySemanticRole.values) {
          final token = palette.semantic(role);
          expect(token.labelPl.trim(), isNotEmpty);
          expect(token.labelEn.trim(), isNotEmpty);
          // Non-accent semantic tokens must have >= 3.0 contrast on background
          if (role != AccessibilitySemanticRole.accent) {
            expect(
              token.contrastRatioAgainst(AppColors.background),
              greaterThanOrEqualTo(3.0),
              reason: '${mode.id} semantic $role contrast against background',
            );
          }
        }

        // All peloton visual group roles present with >= 3.0 contrast on background
        for (final group in PelotonVisualGroupRole.values) {
          final token = palette.pelotonGroup(group);
          expect(token.labelPl.trim(), isNotEmpty);
          expect(token.labelEn.trim(), isNotEmpty);
          expect(
            token.contrastRatioAgainst(AppColors.background),
            greaterThanOrEqualTo(3.0),
            reason: '${mode.id} peloton group $group contrast against background',
          );
        }
      }
    });

    test('Colorblind simulation transforms colors properly and preserves alpha',
        () {
      const sample = Color(0xCCEF4444);
      expect(
        ColorblindAccessibilityPalettes.simulateColor(
          sample,
          ColorblindPaletteMode.standard,
        ),
        sample,
      );

      final achrom = ColorblindAccessibilityPalettes.simulateColor(
        sample,
        ColorblindPaletteMode.achromatopsia,
      );
      expect(achrom.a, closeTo(sample.a, 0.001));
      expect(achrom.r, closeTo(achrom.g, 0.001));
      expect(achrom.g, closeTo(achrom.b, 0.001));

      for (final mode in ColorblindAccessibilityPalettes.colorblindModes) {
        final simulated = ColorblindAccessibilityPalettes.simulateColor(
          sample,
          mode,
        );
        expect(simulated.a, closeTo(sample.a, 0.001));
      }
    });

    test('ColorblindAccessibilityNotifier & Riverpod providers update state cleanly',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(colorblindAccessibilityProvider).mode,
        ColorblindPaletteMode.standard,
      );
      expect(
        container.read(activeColorblindPaletteProvider).mode,
        ColorblindPaletteMode.standard,
      );

      final notifier =
          container.read(colorblindAccessibilityProvider.notifier);
      notifier.setMode(ColorblindPaletteMode.deuteranopia);
      notifier.setShapeDualCoding(false);
      notifier.setPatternOverlay(false);
      notifier.setHighContrastBorders(true);
      notifier.setSimulateInPreview(true);

      final updated = container.read(colorblindAccessibilityProvider);
      expect(updated.mode, ColorblindPaletteMode.deuteranopia);
      expect(updated.enableShapeDualCoding, isFalse);
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

    for (final viewport in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
          'ColorblindAccessibilitySettingsPanel renders cleanly at ${viewport.width.toInt()}x${viewport.height.toInt()}',
          (tester) async {
        tester.view.physicalSize = viewport;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              home: const Scaffold(
                body: SingleChildScrollView(
                  child: ColorblindAccessibilitySettingsPanel(),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull);
        expect(find.byType(ColorblindAccessibilitySettingsPanel),
            findsOneWidget);
      });
    }
  });
}
