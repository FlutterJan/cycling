// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/diagnostics/sniper_package_2_audit_runner.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';

void main() {
  group('SniperPackage2AuditRunner', () {
    test('manifest zawiera dokładnie 50 unikalnych zadań #213–#262', () {
      const manifest = SniperPackage2AuditRunner.package2Manifest;
      expect(manifest.length, 50);
      final numbers = manifest.map((e) => e.taskNumber).toSet();
      expect(numbers.length, 50);
      expect(numbers.first, 213);
      expect(numbers.last, 262);
    });

    test('parsuje poprawnie wyjście flutter analyze', () {
      const sample = '''
Analyzing pro_peloton_manager...
  info • Prefer const with constant constructors • lib/foo.dart:12:5 • prefer_const_constructors
  warning • Unused import • lib/bar.dart:3:8 • unused_import
  error • Undefined name 'x' • lib/baz.dart:45:10 • undefined_identifier
''';
      final issues = SniperPackage2AuditRunner.parseFlutterAnalyzeOutput(sample);
      expect(issues.length, 3);
      expect(issues[0].severity, Package2AuditSeverity.info);
      expect(issues[1].severity, Package2AuditSeverity.warning);
      expect(issues[2].severity, Package2AuditSeverity.error);
      expect(issues[2].line, 45);
      expect(issues[2].ruleName, 'undefined_identifier');
    });

    test('weryfikuje integrację Paczki #2 z grą oraz kompletność docs/CODE_MAP.md', () async {
      const runner = SniperPackage2AuditRunner();
      final report = await runner.runFullAudit(runFlutterAnalyze: false);

      expect(report.totalTasks, 50);
      expect(
        report.codeMapResult.missingFilePaths,
        isEmpty,
        reason: 'Brakujące ścieżki w CODE_MAP.md: ${report.codeMapResult.missingFilePaths}',
      );
      expect(
        report.codeMapResult.missingSymbolsByFile,
        isEmpty,
        reason: 'Brakujące symbole w CODE_MAP.md: ${report.codeMapResult.missingSymbolsByFile}',
      );
      expect(
        report.integrationResult.missingCoreBridges,
        isEmpty,
        reason: 'Brakujące mosty integracji: ${report.integrationResult.missingCoreBridges}',
      );
      expect(
        report.integrationResult.brokenRelativeImportsByFile,
        isEmpty,
        reason: 'Uszkodzone importy względne: ${report.integrationResult.brokenRelativeImportsByFile}',
      );
      expect(
        report.taskResults.where((r) => !r.fileExists).toList(),
        isEmpty,
      );
      expect(
        report.taskResults.where((r) => r.missingSymbols.isNotEmpty).toList(),
        isEmpty,
      );
      expect(
        report.taskResults.where((r) => !r.passed).toList(),
        isEmpty,
        reason: report.toMarkdownSummary(),
      );
      expect(report.overallPassed, isTrue);
    });
  });

  group('SniperPackage2AuditPanel responsywność', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renderuje bez RenderFlex overflow w ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() => tester.view.resetPhysicalSize());

          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                theme: AppTheme.darkTheme,
                home: const Scaffold(
                  body: SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: SniperPackage2AuditPanel(),
                  ),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.byType(SniperPackage2AuditPanel), findsOneWidget);
          expect(find.text('Uruchom Audyt'), findsOneWidget);

          await tester.tap(find.text('Uruchom Audyt'));
          await tester.pump(const Duration(milliseconds: 300));
        },
      );
    }
  });
}
