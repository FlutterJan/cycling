import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pro_peloton_manager/core/diagnostics/ui_golden_contrast_and_font_auditor.dart';
import 'package:pro_peloton_manager/core/theme/app_colors.dart';

void main() {
  const auditor = UiGoldenContrastAndFontAuditor();

  group('WCAG 2.1 Contrast & Luminance Math', () {
    test('black on white yields maximum 21:1 contrast ratio', () {
      final ratio = UiGoldenContrastAndFontAuditor.contrastRatio(
        Colors.black,
        Colors.white,
      );
      expect(ratio, closeTo(21.0, 0.01));
    });

    test('identical colors yield 1:1 contrast ratio', () {
      final ratio = UiGoldenContrastAndFontAuditor.contrastRatio(
        AppColors.surface,
        AppColors.surface,
      );
      expect(ratio, closeTo(1.0, 0.001));
    });

    test('alpha compositing blends semi-transparent foreground over background', () {
      final ratio = UiGoldenContrastAndFontAuditor.contrastRatio(
        Colors.white.withValues(alpha: 0.5),
        Colors.black,
      );
      expect(ratio, greaterThan(4.5));
      expect(ratio, lessThan(10.0));
    });

    test('AppColors primary and secondary text pass WCAG AA on surface and background', () {
      final specs = UiGoldenContrastAndFontAuditor.defaultAppColorAuditSpecs();
      final textPairs = specs.where(
        (s) =>
            s.foregroundToken == 'AppColors.textPrimary' ||
            s.foregroundToken == 'AppColors.textSecondary',
      );
      expect(textPairs.length, greaterThanOrEqualTo(4));
      for (final spec in textPairs) {
        final result = auditor.auditColorPair(spec);
        expect(
          result.passesRequiredAa,
          isTrue,
          reason: '${spec.label} should pass WCAG AA (ratio=${result.contrastRatio})',
        );
      }
    });

    test('failing pair provides accessible suggested foreground color', () {
      const lowContrastSpec = ColorPairAuditSpec(
        id: 'low_contrast_test',
        label: 'Low contrast test',
        foregroundToken: 'DarkGray',
        backgroundToken: 'AppColors.background',
        foreground: Color(0xFF22252A),
        background: AppColors.background,
      );
      final result = auditor.auditColorPair(lowContrastSpec);
      expect(result.passesRequiredAa, isFalse);
      expect(result.level, WcagContrastLevel.fail);
      expect(result.suggestedForeground, isNotNull);
      final fixedRatio = UiGoldenContrastAndFontAuditor.contrastRatio(
        result.suggestedForeground!,
        AppColors.background,
      );
      expect(fixedRatio, greaterThanOrEqualTo(4.5));
    });
  });

  group('TextStyle & Static Source Auditing', () {
    test('auditTextStyle flags missing tabularFigures on numeric telemetry', () {
      const badStyle = TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        color: AppColors.textPrimary,
      );
      final badResult = auditor.auditTextStyle(
        badStyle,
        contextLabel: 'PowerWattBadge',
        isNumericTelemetry: true,
      );
      expect(badResult.passes, isFalse);
      expect(badResult.hasTabularFigures, isFalse);

      const goodStyle = TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        color: AppColors.textPrimary,
        fontFeatures: [FontFeature.tabularFigures()],
      );
      final goodResult = auditor.auditTextStyle(
        goodStyle,
        contextLabel: 'PowerWattBadge',
        isNumericTelemetry: true,
      );
      expect(goodResult.passes, isTrue);
      expect(goodResult.hasTabularFigures, isTrue);
    });

    test('auditSourceCode detects missing tabularFigures, non-Inter font and raw Color', () {
      const sampleCode = '''
import 'package:flutter/material.dart';
class SampleTelemetryWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    final watts = 415.2;
    return Text(
      '\${watts.toStringAsFixed(1)} W',
      style: const TextStyle(
        fontFamily: 'Roboto',
        color: Color(0xFF123456),
        fontSize: 16,
      ),
    );
  }
}
''';
      final summary = auditor.auditSourceCode(
        filePath: 'lib/ui/widgets/sample_telemetry_widget.dart',
        sourceCode: sampleCode,
      );
      expect(summary.missingTabularCount, 1);
      expect(summary.nonInterFontCount, 1);
      expect(summary.rawColorLiteralCount, 1);
      expect(summary.isCompliant, isFalse);
    });

    test('runFullAudit computes golden compliance score and JSON report', () async {
      final report = await auditor.runFullAudit(
        sourceSamples: {
          'lib/ui/widgets/clean_hud.dart': '''
Text(
  '390 W',
  style: const TextStyle(
    fontFamily: 'Inter',
    fontFeatures: [FontFeature.tabularFigures()],
  ),
);
''',
        },
      );
      expect(report.scannedFilesCount, 1);
      expect(report.missingTabularFiguresCount, 0);
      expect(report.totalTabularFiguresUsages, 1);
      expect(report.goldenComplianceScore, greaterThan(80.0));
      expect(report.toJsonPretty(), contains('goldenComplianceScore'));
    });
  });

  group('UiGoldenContrastAndFontAuditorPanel Responsive Widget Tests', () {
    Future<void> pumpAtSize(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: UiGoldenContrastAndFontAuditorPanel(
                initialSourceSamples: {
                  'lib/ui/widgets/test_hud.dart': '''
Text(
  '420 W',
  style: const TextStyle(
    fontFamily: 'Inter',
    fontFeatures: [FontFeature.tabularFigures()],
  ),
);
''',
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(
        find.text('Audytor Kontrastu WCAG AA & Tabular Figures'),
        findsOneWidget,
      );
    }

    testWidgets('renders cleanly at 390x844 (mobile)', (tester) async {
      await pumpAtSize(tester, const Size(390, 844));
    });

    testWidgets('renders cleanly at 1024x768 (tablet)', (tester) async {
      await pumpAtSize(tester, const Size(1024, 768));
    });

    testWidgets('renders cleanly at 1600x900 (desktop)', (tester) async {
      await pumpAtSize(tester, const Size(1600, 900));
    });
  });
}
