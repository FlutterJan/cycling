// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Poziom zgodności kontrastu według standardu W3C WCAG 2.1.
enum WcagContrastLevel {
  aaa('AAA', '≥ 7.0:1 (tekst zwykły) / ≥ 4.5:1 (duży)', AppColors.statusSuccess),
  aa('AA', '≥ 4.5:1 (tekst zwykły) / ≥ 3.0:1 (duży/UI)', AppColors.accentBlue),
  aaLargeOnly('AA Large', '≥ 3.0:1 (tylko duży tekst / komponenty UI)', AppColors.amberWarning),
  fail('FAIL', '< 3.0:1 — niewystarczający kontrast', AppColors.crimsonAlert);

  final String badge;
  final String description;
  final Color color;

  const WcagContrastLevel(this.badge, this.description, this.color);

  bool get passesAaNormal => this == WcagContrastLevel.aaa || this == WcagContrastLevel.aa;
  bool get passesAaLarge => this != WcagContrastLevel.fail;
}

/// Kategoria wykrytego problemu w audycie stylu UI i typografii.
enum UiAuditIssueCategory {
  contrastViolation('Kontrast WCAG AA', Icons.contrast_rounded, AppColors.crimsonAlert),
  missingTabularFigures('Brak tabularFigures()', Icons.looks_one_rounded, AppColors.amberWarning),
  nonInterFontFamily('Czcionka != Inter', Icons.font_download_off_rounded, AppColors.amberWarning),
  rawColorLiteral('Surowy literał Color(0x...)', Icons.palette_outlined, AppColors.accentBlue);

  final String label;
  final IconData icon;
  final Color accentColor;

  const UiAuditIssueCategory(this.label, this.icon, this.accentColor);
}

/// Filtr widoku listy wyników w panelu audytora.
enum UiGoldenAuditFilter {
  all('Wszystkie'),
  failingOnly('Niezgodne'),
  contrastOnly('Kontrast WCAG'),
  typographyOnly('Typografia & Tabular');

  final String label;

  const UiGoldenAuditFilter(this.label);
}

/// Specyfikacja pary kolorów poddawanej audytowi kontrastu WCAG 2.1.
@immutable
class ColorPairAuditSpec {
  final String id;
  final String label;
  final String foregroundToken;
  final String backgroundToken;
  final Color foreground;
  final Color background;
  final bool isLargeText;
  final bool isUiComponent;

  const ColorPairAuditSpec({
    required this.id,
    required this.label,
    required this.foregroundToken,
    required this.backgroundToken,
    required this.foreground,
    required this.background,
    this.isLargeText = false,
    this.isUiComponent = false,
  });
}

/// Wynik audytu kontrastu dla pojedynczej pary kolorów.
@immutable
class ContrastAuditEntry {
  final ColorPairAuditSpec spec;
  final double contrastRatio;
  final double foregroundLuminance;
  final double backgroundLuminance;
  final WcagContrastLevel level;
  final bool passesRequiredAa;
  final double requiredRatio;
  final Color? suggestedForeground;

  const ContrastAuditEntry({
    required this.spec,
    required this.contrastRatio,
    required this.foregroundLuminance,
    required this.backgroundLuminance,
    required this.level,
    required this.passesRequiredAa,
    required this.requiredRatio,
    this.suggestedForeground,
  });

  Map<String, dynamic> toJson() => {
        'id': spec.id,
        'label': spec.label,
        'foregroundToken': spec.foregroundToken,
        'backgroundToken': spec.backgroundToken,
        'foregroundHex': UiGoldenContrastAndFontAuditor.colorToHex(spec.foreground),
        'backgroundHex': UiGoldenContrastAndFontAuditor.colorToHex(spec.background),
        'contrastRatio': double.parse(contrastRatio.toStringAsFixed(2)),
        'requiredRatio': requiredRatio,
        'level': level.badge,
        'passesRequiredAa': passesRequiredAa,
        'suggestedForegroundHex': suggestedForeground != null
            ? UiGoldenContrastAndFontAuditor.colorToHex(suggestedForeground!)
            : null,
      };
}

/// Wynik audytu pojedynczego obiektu `TextStyle`.
@immutable
class TextStyleAuditResult {
  final String contextLabel;
  final bool hasInterFont;
  final bool hasTabularFigures;
  final bool isNumericTelemetry;
  final bool passes;
  final List<String> findings;

  const TextStyleAuditResult({
    required this.contextLabel,
    required this.hasInterFont,
    required this.hasTabularFigures,
    required this.isNumericTelemetry,
    required this.passes,
    required this.findings,
  });
}

/// Pojedynczy problem wykryty w kodzie źródłowym UI (`lib/`).
@immutable
class SourceStyleAuditFinding {
  final String filePath;
  final int lineNumber;
  final UiAuditIssueCategory category;
  final String message;
  final String lineSnippet;
  final String recommendation;

  const SourceStyleAuditFinding({
    required this.filePath,
    required this.lineNumber,
    required this.category,
    required this.message,
    required this.lineSnippet,
    required this.recommendation,
  });

  Map<String, dynamic> toJson() => {
        'filePath': filePath,
        'lineNumber': lineNumber,
        'category': category.name,
        'message': message,
        'lineSnippet': lineSnippet,
        'recommendation': recommendation,
      };
}

/// Podsumowanie skanowania plików UI pod kątem `FontFeature.tabularFigures()` i spójności motywu.
@immutable
class FontAndThemeFileAuditSummary {
  final String filePath;
  final int textStyleCount;
  final int tabularFiguresCount;
  final int numericTelemetryStyleCount;
  final int missingTabularCount;
  final int nonInterFontCount;
  final int rawColorLiteralCount;
  final List<SourceStyleAuditFinding> findings;

  const FontAndThemeFileAuditSummary({
    required this.filePath,
    required this.textStyleCount,
    required this.tabularFiguresCount,
    required this.numericTelemetryStyleCount,
    required this.missingTabularCount,
    required this.nonInterFontCount,
    required this.rawColorLiteralCount,
    required this.findings,
  });

  bool get isCompliant =>
      missingTabularCount == 0 && nonInterFontCount == 0 && rawColorLiteralCount == 0;
}

/// Pełny raport audytu kontrastu WCAG AA, `FontFeature.tabularFigures()` i palety `AppColors`.
@immutable
class UiGoldenContrastAuditReport {
  final DateTime generatedAt;
  final List<ContrastAuditEntry> contrastEntries;
  final List<FontAndThemeFileAuditSummary> fileSummaries;
  final int scannedFilesCount;
  final int totalTextStyles;
  final int totalTabularFiguresUsages;
  final int totalNumericTelemetryStyles;
  final int missingTabularFiguresCount;
  final int nonInterFontCount;
  final int rawColorLiteralCount;
  final double goldenComplianceScore;

  const UiGoldenContrastAuditReport({
    required this.generatedAt,
    required this.contrastEntries,
    required this.fileSummaries,
    required this.scannedFilesCount,
    required this.totalTextStyles,
    required this.totalTabularFiguresUsages,
    required this.totalNumericTelemetryStyles,
    required this.missingTabularFiguresCount,
    required this.nonInterFontCount,
    required this.rawColorLiteralCount,
    required this.goldenComplianceScore,
  });

  int get passingContrastCount =>
      contrastEntries.where((e) => e.passesRequiredAa).length;

  int get failingContrastCount =>
      contrastEntries.where((e) => !e.passesRequiredAa).length;

  double get contrastPassRate => contrastEntries.isEmpty
      ? 100.0
      : (passingContrastCount / contrastEntries.length) * 100.0;

  double get tabularCoveragePercent {
    if (totalNumericTelemetryStyles <= 0) {
      return 100.0;
    }
    final covered = (totalNumericTelemetryStyles - missingTabularFiguresCount)
        .clamp(0, totalNumericTelemetryStyles);
    return (covered / totalNumericTelemetryStyles) * 100.0;
  }

  List<SourceStyleAuditFinding> get allSourceFindings =>
      fileSummaries.expand((s) => s.findings).toList(growable: false);

  String toJsonPretty() {
    final payload = {
      'generatedAt': generatedAt.toIso8601String(),
      'goldenComplianceScore': double.parse(goldenComplianceScore.toStringAsFixed(1)),
      'contrast': {
        'totalPairs': contrastEntries.length,
        'passingAaPairs': passingContrastCount,
        'failingAaPairs': failingContrastCount,
        'passRatePercent': double.parse(contrastPassRate.toStringAsFixed(1)),
        'entries': contrastEntries.map((e) => e.toJson()).toList(),
      },
      'typographyAndTheme': {
        'scannedFilesCount': scannedFilesCount,
        'totalTextStyles': totalTextStyles,
        'totalTabularFiguresUsages': totalTabularFiguresUsages,
        'totalNumericTelemetryStyles': totalNumericTelemetryStyles,
        'missingTabularFiguresCount': missingTabularFiguresCount,
        'tabularCoveragePercent': double.parse(tabularCoveragePercent.toStringAsFixed(1)),
        'nonInterFontCount': nonInterFontCount,
        'rawColorLiteralCount': rawColorLiteralCount,
        'findings': allSourceFindings.map((f) => f.toJson()).toList(),
      },
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }
}

/// Główny silnik audytu kontrastu WCAG 2.1 AA/AAA oraz użycia `FontFeature.tabularFigures()`
/// i spójności palety `AppColors` + czcionki `Inter`.
class UiGoldenContrastAndFontAuditor {
  const UiGoldenContrastAndFontAuditor();

  static const double wcagAaNormalThreshold = 4.5;
  static const double wcagAaLargeThreshold = 3.0;
  static const double wcagAaaNormalThreshold = 7.0;
  static const double wcagAaaLargeThreshold = 4.5;

  static final RegExp _textStyleRegex = RegExp(r'\bTextStyle\s*\(');
  static final RegExp _tabularFiguresRegex = RegExp(
    r"FontFeature\.tabularFigures\s*\(\s*\)|FontFeature\s*\(\s*['\x22]tnum['\x22]",
  );
  static final RegExp _fontFamilyRegex = RegExp(
    r"fontFamily\s*:\s*['\x22]([^'\x22]+)['\x22]",
  );
  static final RegExp _rawColorRegex = RegExp(r'\bColor\s*\(\s*0x[0-9A-Fa-f]{8}\s*\)');
  static final RegExp _numericTelemetryHintRegex = RegExp(
    r'(\bwatts?\b|\bftp\b|\bbpm\b|\bkm/h\b|\bvam\b|\bcda\b|\bkcal\b|\bscore\b|\btimer\b|\bcountdown\b|\bgap\b|\bpercent\b|\bratio\b|\btoStringAsFixed\b|\bformatTime\b|\bformatCurrency\b|\btabular\b|:\s*\$|\b\d+\.\d+)',
    caseSensitive: false,
  );

  /// Oblicza luminancję względną koloru (0.0 = czerń, 1.0 = biel) wg W3C WCAG 2.1.
  static double relativeLuminance(Color color) {
    final r = _linearizeChannel(color.r);
    final g = _linearizeChannel(color.g);
    final b = _linearizeChannel(color.b);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  static double _linearizeChannel(double channel) {
    if (channel <= 0.04045) {
      return channel / 12.92;
    }
    return math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
  }

  /// Składa półprzezroczysty kolor pierwszego planu nad nieprzezroczystym tłem.
  static Color compositeOver(Color foreground, Color background) {
    if (foreground.a >= 0.999) {
      return foreground;
    }
    return Color.alphaBlend(foreground, background);
  }

  /// Oblicza współczynnik kontrastu WCAG (1.0 .. 21.0) między dwoma kolorami.
  static double contrastRatio(Color foreground, Color background) {
    final effectiveFg = compositeOver(foreground, background);
    final l1 = relativeLuminance(effectiveFg);
    final l2 = relativeLuminance(background);
    final lighter = math.max(l1, l2);
    final darker = math.min(l1, l2);
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Klasyfikuje współczynnik kontrastu na poziom WCAG.
  static WcagContrastLevel classifyContrast(
    double ratio, {
    bool isLargeText = false,
    bool isUiComponent = false,
  }) {
    if (isLargeText) {
      if (ratio >= wcagAaaLargeThreshold) return WcagContrastLevel.aaa;
      if (ratio >= wcagAaLargeThreshold) return WcagContrastLevel.aa;
      return WcagContrastLevel.fail;
    }
    if (isUiComponent) {
      if (ratio >= wcagAaLargeThreshold) return WcagContrastLevel.aa;
      return WcagContrastLevel.fail;
    }
    if (ratio >= wcagAaaNormalThreshold) return WcagContrastLevel.aaa;
    if (ratio >= wcagAaNormalThreshold) return WcagContrastLevel.aa;
    if (ratio >= wcagAaLargeThreshold) return WcagContrastLevel.aaLargeOnly;
    return WcagContrastLevel.fail;
  }

  /// Wyznacza sugerowany kolor pierwszego planu spełniający wymagany próg WCAG AA
  /// poprzez stopniowe rozjaśnianie lub przyciemnianie względem tła.
  static Color? suggestAccessibleForeground(
    Color foreground,
    Color background, {
    double targetRatio = wcagAaNormalThreshold,
  }) {
    if (contrastRatio(foreground, background) >= targetRatio) {
      return null;
    }
    final bgLum = relativeLuminance(background);
    final targetColor = bgLum < 0.5 ? Colors.white : Colors.black;
    for (int step = 1; step <= 20; step++) {
      final t = step / 20.0;
      final candidate = Color.lerp(foreground, targetColor, t)!;
      if (contrastRatio(candidate, background) >= targetRatio) {
        return candidate;
      }
    }
    return targetColor;
  }

  /// Formatuje kolor do zapisu szesnastkowego `#RRGGBB` lub `#AARRGGBB`.
  static String colorToHex(Color color) {
    final argb = color.toARGB32();
    final a = (argb >> 24) & 0xFF;
    final rgb = (argb & 0x00FFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();
    if (a == 0xFF) {
      return '#$rgb';
    }
    final alphaHex = a.toRadixString(16).padLeft(2, '0').toUpperCase();
    return '#$alphaHex$rgb';
  }

  /// Zwraca zestaw kluczowych par kolorów z palety `AppColors` do automatycznego audytu.
  static List<ColorPairAuditSpec> defaultAppColorAuditSpecs() {
    return const [
      ColorPairAuditSpec(
        id: 'text_primary_on_bg',
        label: 'Tekst główny na tle aplikacji',
        foregroundToken: 'AppColors.textPrimary',
        backgroundToken: 'AppColors.background',
        foreground: AppColors.textPrimary,
        background: AppColors.background,
      ),
      ColorPairAuditSpec(
        id: 'text_primary_on_surface',
        label: 'Tekst główny na karcie',
        foregroundToken: 'AppColors.textPrimary',
        backgroundToken: 'AppColors.surface',
        foreground: AppColors.textPrimary,
        background: AppColors.surface,
      ),
      ColorPairAuditSpec(
        id: 'text_primary_on_surface_light',
        label: 'Tekst główny na karcie podniesionej',
        foregroundToken: 'AppColors.textPrimary',
        backgroundToken: 'AppColors.surfaceLight',
        foreground: AppColors.textPrimary,
        background: AppColors.surfaceLight,
      ),
      ColorPairAuditSpec(
        id: 'text_secondary_on_bg',
        label: 'Tekst pomocniczy na tle aplikacji',
        foregroundToken: 'AppColors.textSecondary',
        backgroundToken: 'AppColors.background',
        foreground: AppColors.textSecondary,
        background: AppColors.background,
      ),
      ColorPairAuditSpec(
        id: 'text_secondary_on_surface',
        label: 'Tekst pomocniczy na karcie',
        foregroundToken: 'AppColors.textSecondary',
        backgroundToken: 'AppColors.surface',
        foreground: AppColors.textSecondary,
        background: AppColors.surface,
      ),
      ColorPairAuditSpec(
        id: 'text_secondary_on_surface_light',
        label: 'Tekst pomocniczy na karcie podniesionej',
        foregroundToken: 'AppColors.textSecondary',
        backgroundToken: 'AppColors.surfaceLight',
        foreground: AppColors.textSecondary,
        background: AppColors.surfaceLight,
      ),
      ColorPairAuditSpec(
        id: 'gold_on_bg',
        label: 'Złoto mistrzowskie na tle aplikacji',
        foregroundToken: 'AppColors.goldAccent',
        backgroundToken: 'AppColors.background',
        foreground: AppColors.goldAccent,
        background: AppColors.background,
      ),
      ColorPairAuditSpec(
        id: 'gold_on_surface',
        label: 'Złoto mistrzowskie na karcie',
        foregroundToken: 'AppColors.goldAccent',
        backgroundToken: 'AppColors.surface',
        foreground: AppColors.goldAccent,
        background: AppColors.surface,
      ),
      ColorPairAuditSpec(
        id: 'white_on_primary_accent',
        label: 'Biały tekst na przycisku Burgund',
        foregroundToken: 'Colors.white',
        backgroundToken: 'AppColors.primaryAccent',
        foreground: Colors.white,
        background: AppColors.primaryAccent,
      ),
      ColorPairAuditSpec(
        id: 'black_on_gold_accent',
        label: 'Ciemny tekst na przycisku Złoto',
        foregroundToken: 'AppColors.background',
        backgroundToken: 'AppColors.goldAccent',
        foreground: AppColors.background,
        background: AppColors.goldAccent,
      ),
      ColorPairAuditSpec(
        id: 'accent_blue_on_surface',
        label: 'Akcent telemetryczny Blue na karcie',
        foregroundToken: 'AppColors.accentBlue',
        backgroundToken: 'AppColors.surface',
        foreground: AppColors.accentBlue,
        background: AppColors.surface,
      ),
      ColorPairAuditSpec(
        id: 'cyan_on_surface',
        label: 'Akcent telemetryczny Cyan na karcie',
        foregroundToken: 'AppColors.cyanAccent',
        backgroundToken: 'AppColors.surface',
        foreground: AppColors.cyanAccent,
        background: AppColors.surface,
      ),
      ColorPairAuditSpec(
        id: 'success_on_surface',
        label: 'Status Sukces na karcie',
        foregroundToken: 'AppColors.statusSuccess',
        backgroundToken: 'AppColors.surface',
        foreground: AppColors.statusSuccess,
        background: AppColors.surface,
      ),
      ColorPairAuditSpec(
        id: 'warning_on_surface',
        label: 'Status Ostrzeżenie na karcie',
        foregroundToken: 'AppColors.amberWarning',
        backgroundToken: 'AppColors.surface',
        foreground: AppColors.amberWarning,
        background: AppColors.surface,
      ),
      ColorPairAuditSpec(
        id: 'crimson_on_surface',
        label: 'Status Krytyczny na karcie',
        foregroundToken: 'AppColors.crimsonAlert',
        backgroundToken: 'AppColors.surface',
        foreground: AppColors.crimsonAlert,
        background: AppColors.surface,
      ),
      ColorPairAuditSpec(
        id: 'border_on_surface_ui',
        label: 'Obramowanie kart (komponent UI ≥ 3:1 lub dekoracyjne)',
        foregroundToken: 'AppTheme.borderColor',
        backgroundToken: 'AppColors.surface',
        foreground: AppTheme.borderColor,
        background: AppColors.surface,
        isUiComponent: true,
      ),
    ];
  }

  /// Audytuje pojedynczą parę kolorów względem wymagań WCAG AA.
  ContrastAuditEntry auditColorPair(ColorPairAuditSpec spec) {
    final effectiveFg = compositeOver(spec.foreground, spec.background);
    final fgLum = relativeLuminance(effectiveFg);
    final bgLum = relativeLuminance(spec.background);
    final ratio = contrastRatio(effectiveFg, spec.background);
    final requiredRatio = (spec.isLargeText || spec.isUiComponent)
        ? wcagAaLargeThreshold
        : wcagAaNormalThreshold;
    final level = classifyContrast(
      ratio,
      isLargeText: spec.isLargeText,
      isUiComponent: spec.isUiComponent,
    );
    final passes = ratio >= requiredRatio;
    final suggested = passes
        ? null
        : suggestAccessibleForeground(
            spec.foreground,
            spec.background,
            targetRatio: requiredRatio,
          );

    return ContrastAuditEntry(
      spec: spec,
      contrastRatio: ratio,
      foregroundLuminance: fgLum,
      backgroundLuminance: bgLum,
      level: level,
      passesRequiredAa: passes,
      requiredRatio: requiredRatio,
      suggestedForeground: suggested,
    );
  }

  /// Audytuje `TextStyle` w runtime pod kątem czcionki `Inter` i `FontFeature.tabularFigures()`.
  TextStyleAuditResult auditTextStyle(
    TextStyle style, {
    required String contextLabel,
    bool isNumericTelemetry = false,
  }) {
    final findings = <String>[];
    final family = style.fontFamily;
    final hasInter = family == null || family == 'Inter';
    if (!hasInter) {
      findings.add("Użyto fontFamily='$family' zamiast 'Inter'.");
    }

    final hasTabular = style.fontFeatures?.any((f) => f.feature == 'tnum') ?? false;
    if (isNumericTelemetry && !hasTabular) {
      findings.add(
        'Styl telemetryczny/liczbowy nie zawiera FontFeature.tabularFigures().',
      );
    }

    return TextStyleAuditResult(
      contextLabel: contextLabel,
      hasInterFont: hasInter,
      hasTabularFigures: hasTabular,
      isNumericTelemetry: isNumericTelemetry,
      passes: findings.isEmpty,
      findings: List.unmodifiable(findings),
    );
  }

  /// Analizuje pojedynczy plik źródłowy `.dart` pod kątem `FontFeature.tabularFigures()`,
  /// czcionki `Inter` oraz użycia `AppColors` zamiast surowych literałów `Color(0x...)`.
  FontAndThemeFileAuditSummary auditSourceCode({
    required String filePath,
    required String sourceCode,
  }) {
    final normalizedPath = filePath.replaceAll('\\', '/');
    final lines = const LineSplitter().convert(sourceCode);
    final findings = <SourceStyleAuditFinding>[];

    int textStyleCount = 0;
    int tabularFiguresCount = 0;
    int numericTelemetryStyleCount = 0;
    int missingTabularCount = 0;
    int nonInterFontCount = 0;
    int rawColorLiteralCount = 0;

    final isThemeDefinitionFile = normalizedPath.startsWith('lib/core/theme/');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();
      if (trimmed.startsWith('//') || trimmed.startsWith('///')) {
        continue;
      }

      if (_tabularFiguresRegex.hasMatch(line)) {
        tabularFiguresCount++;
      }

      final fontMatch = _fontFamilyRegex.firstMatch(line);
      if (fontMatch != null) {
        final fontName = fontMatch.group(1) ?? '';
        if (fontName != 'Inter') {
          nonInterFontCount++;
          findings.add(
            SourceStyleAuditFinding(
              filePath: normalizedPath,
              lineNumber: i + 1,
              category: UiAuditIssueCategory.nonInterFontFamily,
              message: "Wykryto niestandardową czcionkę '$fontName' zamiast 'Inter'.",
              lineSnippet: trimmed,
              recommendation: "Ustaw fontFamily: 'Inter'.",
            ),
          );
        }
      }

      if (!isThemeDefinitionFile && _rawColorRegex.hasMatch(line)) {
        rawColorLiteralCount++;
        findings.add(
          SourceStyleAuditFinding(
            filePath: normalizedPath,
            lineNumber: i + 1,
            category: UiAuditIssueCategory.rawColorLiteral,
            message: 'Użyto surowego literału Color(0x...) poza katalogiem theme/.',
            lineSnippet: trimmed,
            recommendation: 'Zastąp stałą z klasy AppColors lub AppTheme.borderColor.',
          ),
        );
      }

      if (_textStyleRegex.hasMatch(line)) {
        textStyleCount++;
        final blockEnd = math.min(lines.length, i + 10);
        final contextStart = math.max(0, i - 3);
        final block = lines.sublist(i, blockEnd).join('\n');
        final surrounding = lines.sublist(contextStart, blockEnd).join('\n');

        final hasTabularInBlock = _tabularFiguresRegex.hasMatch(block);
        final looksLikeTelemetry = _numericTelemetryHintRegex.hasMatch(surrounding);

        if (looksLikeTelemetry) {
          numericTelemetryStyleCount++;
          if (!hasTabularInBlock) {
            missingTabularCount++;
            findings.add(
              SourceStyleAuditFinding(
                filePath: normalizedPath,
                lineNumber: i + 1,
                category: UiAuditIssueCategory.missingTabularFigures,
                message:
                    'TextStyle w kontekście liczbowym/telemetrycznym bez FontFeature.tabularFigures().',
                lineSnippet: trimmed,
                recommendation:
                    'Dodaj fontFeatures: [FontFeature.tabularFigures()] do TextStyle.',
              ),
            );
          }
        }
      }
    }

    return FontAndThemeFileAuditSummary(
      filePath: normalizedPath,
      textStyleCount: textStyleCount,
      tabularFiguresCount: tabularFiguresCount,
      numericTelemetryStyleCount: numericTelemetryStyleCount,
      missingTabularCount: missingTabularCount,
      nonInterFontCount: nonInterFontCount,
      rawColorLiteralCount: rawColorLiteralCount,
      findings: List.unmodifiable(findings),
    );
  }

  /// Uruchamia pełny audyt kontrastu WCAG AA oraz statyczny audyt plików UI.
  ///
  /// Jeśli podano [sourceSamples], analizuje je bezpośrednio (idealne do szybkich testów);
  /// w przeciwnym razie skanuje pliki `.dart` w `lib/ui/` oraz `lib/core/diagnostics/`.
  Future<UiGoldenContrastAuditReport> runFullAudit({
    List<ColorPairAuditSpec>? customColorSpecs,
    Map<String, String>? sourceSamples,
    Directory? projectRoot,
  }) async {
    final specs = customColorSpecs ?? defaultAppColorAuditSpecs();
    final contrastEntries = specs.map(auditColorPair).toList(growable: false);

    final fileSummaries = <FontAndThemeFileAuditSummary>[];
    if (sourceSamples != null) {
      for (final entry in sourceSamples.entries) {
        fileSummaries.add(
          auditSourceCode(filePath: entry.key, sourceCode: entry.value),
        );
      }
    } else {
      final root = projectRoot ?? Directory.current;
      final targetDirs = [
        Directory('${root.path}${Platform.pathSeparator}lib${Platform.pathSeparator}ui'),
        Directory('${root.path}${Platform.pathSeparator}lib${Platform.pathSeparator}core${Platform.pathSeparator}diagnostics'),
      ];
      for (final dir in targetDirs) {
        if (!dir.existsSync()) continue;
        final entities = dir.listSync(recursive: true, followLinks: false);
        for (final entity in entities) {
          if (entity is File && entity.path.endsWith('.dart')) {
            final relative = entity.path
                .replaceFirst(root.path, '')
                .replaceAll('\\', '/')
                .replaceFirst(RegExp(r'^/'), '');
            final content = await entity.readAsString();
            fileSummaries.add(
              auditSourceCode(filePath: relative, sourceCode: content),
            );
          }
        }
      }
    }

    int totalTextStyles = 0;
    int totalTabular = 0;
    int totalNumeric = 0;
    int missingTabular = 0;
    int nonInter = 0;
    int rawColors = 0;

    for (final summary in fileSummaries) {
      totalTextStyles += summary.textStyleCount;
      totalTabular += summary.tabularFiguresCount;
      totalNumeric += summary.numericTelemetryStyleCount;
      missingTabular += summary.missingTabularCount;
      nonInter += summary.nonInterFontCount;
      rawColors += summary.rawColorLiteralCount;
    }

    final contrastScore = contrastEntries.isEmpty
        ? 100.0
        : (contrastEntries.where((e) => e.passesRequiredAa).length /
                contrastEntries.length) *
            100.0;
    final tabularScore = totalNumeric == 0
        ? 100.0
        : ((totalNumeric - missingTabular).clamp(0, totalNumeric) / totalNumeric) *
            100.0;
    final fontPenalty = math.min(20.0, nonInter * 4.0);
    final rawColorPenalty = math.min(15.0, rawColors * 0.5);
    final goldenScore =
        ((contrastScore * 0.55) + (tabularScore * 0.45) - fontPenalty - rawColorPenalty)
            .clamp(0.0, 100.0);

    return UiGoldenContrastAuditReport(
      generatedAt: DateTime.now(),
      contrastEntries: List.unmodifiable(contrastEntries),
      fileSummaries: List.unmodifiable(fileSummaries),
      scannedFilesCount: fileSummaries.length,
      totalTextStyles: totalTextStyles,
      totalTabularFiguresUsages: totalTabular,
      totalNumericTelemetryStyles: totalNumeric,
      missingTabularFiguresCount: missingTabular,
      nonInterFontCount: nonInter,
      rawColorLiteralCount: rawColors,
      goldenComplianceScore: goldenScore,
    );
  }
}

/// Stan Riverpod dla panelu audytora kontrastu i typografii.
@immutable
class UiGoldenContrastAuditorState {
  final bool isLoading;
  final UiGoldenContrastAuditReport? report;
  final UiGoldenAuditFilter activeFilter;
  final String searchQuery;
  final ColorPairAuditSpec sandboxSpec;
  final String? errorMessage;

  const UiGoldenContrastAuditorState({
    this.isLoading = false,
    this.report,
    this.activeFilter = UiGoldenAuditFilter.all,
    this.searchQuery = '',
    this.sandboxSpec = const ColorPairAuditSpec(
      id: 'sandbox_custom',
      label: 'Symulator pary kolorów',
      foregroundToken: 'AppColors.textPrimary',
      backgroundToken: 'AppColors.surface',
      foreground: AppColors.textPrimary,
      background: AppColors.surface,
    ),
    this.errorMessage,
  });

  UiGoldenContrastAuditorState copyWith({
    bool? isLoading,
    UiGoldenContrastAuditReport? report,
    UiGoldenAuditFilter? activeFilter,
    String? searchQuery,
    ColorPairAuditSpec? sandboxSpec,
    String? errorMessage,
    bool clearError = false,
  }) {
    return UiGoldenContrastAuditorState(
      isLoading: isLoading ?? this.isLoading,
      report: report ?? this.report,
      activeFilter: activeFilter ?? this.activeFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      sandboxSpec: sandboxSpec ?? this.sandboxSpec,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Kontroler stanu audytora WCAG AA i `FontFeature.tabularFigures()`.
class UiGoldenContrastAuditorNotifier
    extends StateNotifier<UiGoldenContrastAuditorState> {
  final UiGoldenContrastAndFontAuditor _auditor;

  UiGoldenContrastAuditorNotifier({
    UiGoldenContrastAndFontAuditor auditor = const UiGoldenContrastAndFontAuditor(),
  })  : _auditor = auditor,
        super(const UiGoldenContrastAuditorState());

  Future<void> runAudit({Map<String, String>? sourceSamples}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final report = await _auditor.runFullAudit(sourceSamples: sourceSamples);
      if (!mounted) return;
      state = state.copyWith(isLoading: false, report: report);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Błąd audytu UI: $e',
      );
    }
  }

  void setFilter(UiGoldenAuditFilter filter) {
    state = state.copyWith(activeFilter: filter);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void updateSandboxColors({
    String? foregroundToken,
    Color? foreground,
    String? backgroundToken,
    Color? background,
    bool? isLargeText,
  }) {
    final current = state.sandboxSpec;
    state = state.copyWith(
      sandboxSpec: ColorPairAuditSpec(
        id: current.id,
        label: current.label,
        foregroundToken: foregroundToken ?? current.foregroundToken,
        backgroundToken: backgroundToken ?? current.backgroundToken,
        foreground: foreground ?? current.foreground,
        background: background ?? current.background,
        isLargeText: isLargeText ?? current.isLargeText,
      ),
    );
  }
}

final uiGoldenContrastAuditorProvider = StateNotifierProvider<
    UiGoldenContrastAuditorNotifier, UiGoldenContrastAuditorState>(
  (ref) => UiGoldenContrastAuditorNotifier(),
);

/// Nazwany token koloru z palety `AppColors` do wyboru w symulatorze kontrastu.
@immutable
class _NamedAppColorToken {
  final String token;
  final Color color;

  const _NamedAppColorToken(this.token, this.color);
}

const List<_NamedAppColorToken> _kAppColorTokens = [
  _NamedAppColorToken('AppColors.background', AppColors.background),
  _NamedAppColorToken('AppColors.surface', AppColors.surface),
  _NamedAppColorToken('AppColors.surfaceLight', AppColors.surfaceLight),
  _NamedAppColorToken('AppColors.primaryAccent', AppColors.primaryAccent),
  _NamedAppColorToken('AppColors.goldAccent', AppColors.goldAccent),
  _NamedAppColorToken('AppColors.accentBlue', AppColors.accentBlue),
  _NamedAppColorToken('AppColors.cyanAccent', AppColors.cyanAccent),
  _NamedAppColorToken('AppColors.statusSuccess', AppColors.statusSuccess),
  _NamedAppColorToken('AppColors.amberWarning', AppColors.amberWarning),
  _NamedAppColorToken('AppColors.crimsonAlert', AppColors.crimsonAlert),
  _NamedAppColorToken('AppColors.textPrimary', AppColors.textPrimary),
  _NamedAppColorToken('AppColors.textSecondary', AppColors.textSecondary),
];

/// Produkcyjny panel diagnostyczny audytora kontrastu WCAG AA i `FontFeature.tabularFigures()`.
class UiGoldenContrastAndFontAuditorPanel extends ConsumerStatefulWidget {
  final Map<String, String>? initialSourceSamples;
  final bool autoRunOnInit;

  const UiGoldenContrastAndFontAuditorPanel({
    super.key,
    this.initialSourceSamples,
    this.autoRunOnInit = true,
  });

  @override
  ConsumerState<UiGoldenContrastAndFontAuditorPanel> createState() =>
      _UiGoldenContrastAndFontAuditorPanelState();
}

class _UiGoldenContrastAndFontAuditorPanelState
    extends ConsumerState<UiGoldenContrastAndFontAuditorPanel> {
  static const UiGoldenContrastAndFontAuditor _auditor =
      UiGoldenContrastAndFontAuditor();

  late final TextEditingController _searchController;
  bool _copiedJsonFeedback = false;
  Timer? _copyResetTimer;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    if (widget.autoRunOnInit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(uiGoldenContrastAuditorProvider.notifier)
            .runAudit(sourceSamples: widget.initialSourceSamples);
      });
    }
  }

  @override
  void dispose() {
    _copyResetTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _copyReportJson(UiGoldenContrastAuditReport report) async {
    await Clipboard.setData(ClipboardData(text: report.toJsonPretty()));
    if (!mounted) return;
    setState(() => _copiedJsonFeedback = true);
    _copyResetTimer?.cancel();
    _copyResetTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _copiedJsonFeedback = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(uiGoldenContrastAuditorProvider);
    final notifier = ref.read(uiGoldenContrastAuditorProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 680;
          final isDesktop = constraints.maxWidth >= 1120;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isCompact ? 12 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(state, notifier, isCompact),
                const SizedBox(height: 16),
                if (state.errorMessage != null) ...[
                  _buildErrorBanner(state.errorMessage!),
                  const SizedBox(height: 16),
                ],
                if (state.report != null) ...[
                  _buildKpiGrid(state.report!, isCompact, isDesktop),
                  const SizedBox(height: 16),
                ],
                _buildSandboxCard(state, notifier, isCompact),
                const SizedBox(height: 16),
                _buildFilterAndSearchBar(state, notifier, isCompact),
                const SizedBox(height: 16),
                if (state.isLoading && state.report == null)
                  _buildLoadingCard()
                else if (state.report != null)
                  _buildAuditSections(state, state.report!, isDesktop),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(
    UiGoldenContrastAuditorState state,
    UiGoldenContrastAuditorNotifier notifier,
    bool isCompact,
  ) {
    final titleBlock = Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.goldAccent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.goldAccent.withValues(alpha: 0.4),
              width: 1.0,
            ),
          ),
          child: const Icon(
            Icons.contrast_rounded,
            color: AppColors.goldAccent,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Audytor Kontrastu WCAG AA & Tabular Figures',
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
                'Weryfikacja luminancji W3C WCAG 2.1, FontFeature.tabularFigures() oraz palety AppColors',
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
    );

    final actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _InteractiveActionButton(
          label: state.isLoading ? 'Skanowanie...' : 'Uruchom audyt',
          icon: Icons.play_arrow_rounded,
          isPrimary: true,
          isDisabled: state.isLoading,
          onPressed: () =>
              notifier.runAudit(sourceSamples: widget.initialSourceSamples),
        ),
        _InteractiveActionButton(
          label: _copiedJsonFeedback ? 'Skopiowano JSON' : 'Eksportuj JSON',
          icon: _copiedJsonFeedback ? Icons.check_rounded : Icons.copy_rounded,
          isPrimary: false,
          isDisabled: state.report == null,
          onPressed: state.report != null
              ? () => _copyReportJson(state.report!)
              : null,
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                titleBlock,
                const SizedBox(height: 12),
                actions,
              ],
            )
          : Row(
              children: [
                Expanded(child: titleBlock),
                const SizedBox(width: 16),
                actions,
              ],
            ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.crimsonAlert.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.crimsonAlert, width: 1.0),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.crimsonAlert),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(
    UiGoldenContrastAuditReport report,
    bool isCompact,
    bool isDesktop,
  ) {
    final cards = [
      _KpiMetricCard(
        title: 'Zgodność WCAG AA',
        value: '${report.contrastPassRate.toStringAsFixed(1)}%',
        subtitle:
            '${report.passingContrastCount}/${report.contrastEntries.length} par kolorów',
        accent: report.failingContrastCount == 0
            ? AppColors.statusSuccess
            : AppColors.amberWarning,
        icon: Icons.verified_rounded,
      ),
      _KpiMetricCard(
        title: 'Pokrycie tabularFigures()',
        value: '${report.tabularCoveragePercent.toStringAsFixed(1)}%',
        subtitle: '${report.totalTabularFiguresUsages} użyć w kodzie UI',
        accent: report.missingTabularFiguresCount == 0
            ? AppColors.statusSuccess
            : AppColors.amberWarning,
        icon: Icons.looks_one_rounded,
      ),
      _KpiMetricCard(
        title: 'Golden UI Score',
        value: '${report.goldenComplianceScore.toStringAsFixed(1)}/100',
        subtitle: 'Przeskanowano ${report.scannedFilesCount} plików',
        accent: AppColors.goldAccent,
        icon: Icons.auto_awesome_rounded,
      ),
      _KpiMetricCard(
        title: 'Odstępstwa stylu',
        value:
            '${report.failingContrastCount + report.missingTabularFiguresCount + report.nonInterFontCount}',
        subtitle: '${report.rawColorLiteralCount} surowych literałów Color',
        accent: (report.failingContrastCount + report.missingTabularFiguresCount) == 0
            ? AppColors.accentBlue
            : AppColors.crimsonAlert,
        icon: Icons.rule_rounded,
      ),
    ];

    if (isDesktop) {
      return Row(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            Expanded(child: cards[i]),
            if (i < cards.length - 1) const SizedBox(width: 12),
          ],
        ],
      );
    }

    if (isCompact) {
      return Column(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            cards[i],
            if (i < cards.length - 1) const SizedBox(height: 10),
          ],
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 12),
            Expanded(child: cards[1]),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: cards[2]),
            const SizedBox(width: 12),
            Expanded(child: cards[3]),
          ],
        ),
      ],
    );
  }

  Widget _buildSandboxCard(
    UiGoldenContrastAuditorState state,
    UiGoldenContrastAuditorNotifier notifier,
    bool isCompact,
  ) {
    final entry = _auditor.auditColorPair(state.sandboxSpec);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded, color: AppColors.accentBlue, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Interaktywny Symulator Kontrastu & Tabular Figures',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _WcagBadge(level: entry.level),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: state.sandboxSpec.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor, width: 1.0),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Text(
                  '412 W  •  64.8 km/h  •  +01:24.50',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: state.sandboxSpec.isLargeText ? 20 : 15,
                    fontWeight: FontWeight.w700,
                    color: state.sandboxSpec.foreground,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  'Kontrast: ${entry.contrastRatio.toStringAsFixed(2)} : 1',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: state.sandboxSpec.foreground,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildTokenDropdown(
                label: 'Tekst / Pierwszy plan',
                selectedToken: state.sandboxSpec.foregroundToken,
                onChanged: (token) {
                  notifier.updateSandboxColors(
                    foregroundToken: token.token,
                    foreground: token.color,
                  );
                },
              ),
              _buildTokenDropdown(
                label: 'Tło',
                selectedToken: state.sandboxSpec.backgroundToken,
                onChanged: (token) {
                  notifier.updateSandboxColors(
                    backgroundToken: token.token,
                    background: token.color,
                  );
                },
              ),
              _InteractiveFilterChip(
                label: state.sandboxSpec.isLargeText
                    ? 'Duży tekst (≥ 3.0:1)'
                    : 'Zwykły tekst (≥ 4.5:1)',
                isSelected: state.sandboxSpec.isLargeText,
                onTap: () => notifier.updateSandboxColors(
                  isLargeText: !state.sandboxSpec.isLargeText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTokenDropdown({
    required String label,
    required String selectedToken,
    required ValueChanged<_NamedAppColorToken> onChanged,
  }) {
    final current = _kAppColorTokens.firstWhere(
      (t) => t.token == selectedToken,
      orElse: () => _kAppColorTokens.first,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 4,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 230),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<_NamedAppColorToken>(
                value: current,
                dropdownColor: AppColors.surfaceLight,
                isDense: true,
                isExpanded: true,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                items: _kAppColorTokens.map((t) {
                  return DropdownMenuItem<_NamedAppColorToken>(
                    value: t,
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: t.color,
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(color: AppTheme.borderColor),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            t.token,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) onChanged(value);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterAndSearchBar(
    UiGoldenContrastAuditorState state,
    UiGoldenContrastAuditorNotifier notifier,
    bool isCompact,
  ) {
    final filterChips = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: UiGoldenAuditFilter.values.map((filter) {
        return _InteractiveFilterChip(
          label: filter.label,
          isSelected: state.activeFilter == filter,
          onTap: () => notifier.setFilter(filter),
        );
      }).toList(),
    );

    final searchField = SizedBox(
      width: isCompact ? double.infinity : 280,
      child: TextField(
        controller: _searchController,
        onChanged: notifier.setSearchQuery,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Filtruj token, plik lub regułę...',
          hintStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 18,
            color: AppColors.textSecondary,
          ),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.goldAccent),
          ),
        ),
      ),
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          filterChips,
          const SizedBox(height: 10),
          searchField,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: filterChips),
        const SizedBox(width: 12),
        searchField,
      ],
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.goldAccent,
            ),
          ),
          SizedBox(width: 12),
          Text(
            'Analizowanie kontrastu WCAG AA i plików UI...',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditSections(
    UiGoldenContrastAuditorState state,
    UiGoldenContrastAuditReport report,
    bool isDesktop,
  ) {
    final query = state.searchQuery.trim().toLowerCase();

    final showContrast = state.activeFilter == UiGoldenAuditFilter.all ||
        state.activeFilter == UiGoldenAuditFilter.failingOnly ||
        state.activeFilter == UiGoldenAuditFilter.contrastOnly;
    final showTypography = state.activeFilter == UiGoldenAuditFilter.all ||
        state.activeFilter == UiGoldenAuditFilter.failingOnly ||
        state.activeFilter == UiGoldenAuditFilter.typographyOnly;

    final filteredContrast = report.contrastEntries.where((e) {
      if (state.activeFilter == UiGoldenAuditFilter.failingOnly &&
          e.passesRequiredAa) {
        return false;
      }
      if (query.isEmpty) return true;
      return e.spec.label.toLowerCase().contains(query) ||
          e.spec.foregroundToken.toLowerCase().contains(query) ||
          e.spec.backgroundToken.toLowerCase().contains(query);
    }).toList();

    final filteredFindings = report.allSourceFindings.where((f) {
      if (state.activeFilter == UiGoldenAuditFilter.failingOnly &&
          f.category == UiAuditIssueCategory.rawColorLiteral) {
        return false;
      }
      if (query.isEmpty) return true;
      return f.filePath.toLowerCase().contains(query) ||
          f.message.toLowerCase().contains(query);
    }).toList();

    final contrastWidget = showContrast
        ? _buildContrastMatrixCard(filteredContrast)
        : const SizedBox.shrink();
    final typographyWidget = showTypography
        ? _buildTypographyFindingsCard(filteredFindings, report)
        : const SizedBox.shrink();

    if (isDesktop && showContrast && showTypography) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 5, child: contrastWidget),
          const SizedBox(width: 16),
          Expanded(flex: 5, child: typographyWidget),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showContrast) contrastWidget,
        if (showContrast && showTypography) const SizedBox(height: 16),
        if (showTypography) typographyWidget,
      ],
    );
  }

  Widget _buildContrastMatrixCard(List<ContrastAuditEntry> entries) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.palette_rounded, color: AppColors.goldAccent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Macierz Kontrastu WCAG 2.1 (${entries.length})',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Brak par kolorów spełniających wybrane kryteria.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            for (int i = 0; i < entries.length; i++) ...[
              _ContrastEntryRow(entry: entries[i]),
              if (i < entries.length - 1) const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }

  Widget _buildTypographyFindingsCard(
    List<SourceStyleAuditFinding> findings,
    UiGoldenContrastAuditReport report,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.text_fields_rounded, color: AppColors.accentBlue, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Audyt FontFeature.tabularFigures() & Inter (${findings.length})',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Style tekstowe: ${report.totalTextStyles} • Telemetryczne: ${report.totalNumericTelemetryStyles} • tabularFigures: ${report.totalTabularFiguresUsages}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 12),
          if (findings.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.statusSuccess.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.statusSuccess.withValues(alpha: 0.35),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: AppColors.statusSuccess, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Brak odstępstw typograficznych w zeskanowanych plikach.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            for (int i = 0; i < findings.length; i++) ...[
              _SourceFindingRow(finding: findings[i]),
              if (i < findings.length - 1) const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

class _KpiMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color accent;
  final IconData icon;

  const _KpiMetricCard({
    required this.title,
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
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: accent,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontFeatures: [FontFeature.tabularFigures()],
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

class _ContrastEntryRow extends StatelessWidget {
  final ContrastAuditEntry entry;

  const _ContrastEntryRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: entry.passesRequiredAa
              ? AppTheme.borderColor
              : AppColors.crimsonAlert.withValues(alpha: 0.5),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: entry.spec.background,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Text(
                  'Aa',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: entry.spec.foreground,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.spec.label,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${entry.spec.foregroundToken} na ${entry.spec.backgroundToken}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${entry.contrastRatio.toStringAsFixed(2)}:1',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: entry.level.color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 8),
              _WcagBadge(level: entry.level),
            ],
          ),
          if (entry.suggestedForeground != null) ...[
            const SizedBox(height: 8),
            Text(
              'Sugerowana korekta dla ≥ ${entry.requiredRatio.toStringAsFixed(1)}:1: ${UiGoldenContrastAndFontAuditor.colorToHex(entry.suggestedForeground!)}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: AppColors.amberWarning,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SourceFindingRow extends StatelessWidget {
  final SourceStyleAuditFinding finding;

  const _SourceFindingRow({required this.finding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                finding.category.icon,
                color: finding.category.accentColor,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${finding.filePath}:${finding.lineNumber}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: finding.category.accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  finding.category.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: finding.category.accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            finding.message,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            finding.recommendation,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.accentBlue,
            ),
          ),
        ],
      ),
    );
  }
}

class _WcagBadge extends StatelessWidget {
  final WcagContrastLevel level;

  const _WcagBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: level.color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: level.color.withValues(alpha: 0.45),
          width: 1.0,
        ),
      ),
      child: Text(
        level.badge,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: level.color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _InteractiveActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final bool isDisabled;
  final VoidCallback? onPressed;

  const _InteractiveActionButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.isDisabled,
    this.onPressed,
  });

  @override
  State<_InteractiveActionButton> createState() =>
      _InteractiveActionButtonState();
}

class _InteractiveActionButtonState extends State<_InteractiveActionButton> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = !widget.isDisabled && widget.onPressed != null;
    final Color baseBg = widget.isPrimary
        ? AppColors.primaryAccent
        : AppColors.surfaceLight;
    final Color bgColor;
    if (!enabled) {
      bgColor = AppColors.surfaceLight.withValues(alpha: 0.45);
    } else if (_isPressed) {
      bgColor = widget.isPrimary
          ? AppColors.goldAccent.withValues(alpha: 0.85)
          : AppColors.surfaceLight.withValues(alpha: 0.9);
    } else if (_isHovered) {
      bgColor = widget.isPrimary
          ? AppColors.primaryAccent.withValues(alpha: 0.85)
          : AppColors.surfaceLight;
    } else {
      bgColor = baseBg;
    }

    final borderColor = _isFocused
        ? AppColors.goldAccent
        : (_isHovered && enabled
            ? AppColors.goldAccent.withValues(alpha: 0.55)
            : AppTheme.borderColor);

    final fgColor = !enabled
        ? AppColors.textSecondary.withValues(alpha: 0.5)
        : (_isPressed && widget.isPrimary
            ? AppColors.background
            : AppColors.textPrimary);

    return FocusableActionDetector(
      enabled: enabled,
      onShowFocusHighlight: (focused) => setState(() => _isFocused = focused),
      onShowHoverHighlight: (hovered) => setState(() => _isHovered = hovered),
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _isPressed = false) : null,
          onTapCancel: enabled ? () => setState(() => _isPressed = false) : null,
          onTap: enabled ? widget.onPressed : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 16, color: fgColor),
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: fgColor,
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

class _InteractiveFilterChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _InteractiveFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_InteractiveFilterChip> createState() => _InteractiveFilterChipState();
}

class _InteractiveFilterChipState extends State<_InteractiveFilterChip> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isSelected
        ? AppColors.goldAccent.withValues(alpha: _isPressed ? 0.28 : 0.18)
        : (_isHovered ? AppColors.surfaceLight : AppColors.surface);
    final borderColor = _isFocused || widget.isSelected
        ? AppColors.goldAccent
        : (_isHovered ? AppColors.textSecondary : AppTheme.borderColor);
    final textColor =
        widget.isSelected ? AppColors.goldAccent : AppColors.textSecondary;

    return FocusableActionDetector(
      onShowFocusHighlight: (focused) => setState(() => _isFocused = focused),
      onShowHoverHighlight: (hovered) => setState(() => _isHovered = hovered),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
