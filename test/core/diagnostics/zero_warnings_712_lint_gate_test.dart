import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/diagnostics/zero_warnings_712_lint_gate.dart';

void main() {
  group('ZeroWarnings712LintGate unit tests', () {
    test('parseFlutterAnalyzeOutput parses dash and bullet formats', () {
      const sample = '''
Analyzing pro_peloton_manager...

warning - The value of the local variable 'x' isn't used. Try removing the variable - lib\\engine\\peloton\\foo.dart:42:9 - unused_local_variable
  info • Prefer const with constant constructors • lib/ui/screens/bar.dart:10:5 • prefer_const_constructors
error - Undefined name 'z'. - lib/core/baz.dart:7:3 - undefined_identifier
''';
      final issues = ZeroWarnings712LintGate.parseFlutterAnalyzeOutput(sample);
      expect(issues, hasLength(3));
      expect(issues[0].severity, ZeroWarnings712Severity.warning);
      expect(issues[0].normalizedPath, 'lib/engine/peloton/foo.dart');
      expect(issues[0].line, 42);
      expect(issues[0].column, 9);
      expect(issues[0].ruleName, 'unused_local_variable');

      expect(issues[1].severity, ZeroWarnings712Severity.info);
      expect(issues[1].normalizedPath, 'lib/ui/screens/bar.dart');
      expect(issues[1].ruleName, 'prefer_const_constructors');

      expect(issues[2].severity, ZeroWarnings712Severity.error);
      expect(issues[2].ruleName, 'undefined_identifier');
    });

    test('parseAnalysisOptions extracts include, exclude, and strict flags', () {
      const yaml = '''
include: package:flutter_lints/flutter.yaml

analyzer:
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
  exclude:
    - build/**
    - android/**

linter:
  rules:
    - avoid_print
    - prefer_const_constructors
''';
      final summary = ZeroWarnings712LintGate.parseAnalysisOptions(yaml);
      expect(summary.includeLine, 'package:flutter_lints/flutter.yaml');
      expect(summary.hasStrictCasts, isTrue);
      expect(summary.hasStrictInference, isTrue);
      expect(summary.hasStrictRawTypes, isTrue);
      expect(summary.excludedPatterns, ['build/**', 'android/**']);
      expect(summary.customRulesCount, 2);
    });

    test('scanSourceHygiene detects TODO, raw print, ignore_for_file, empty catch', () {
      const source = '''
// ignore_for_file: unused_local_variable
void demo() {
  // TODO: remove this
  print('debug');
  try {
    throw Exception('x');
  } catch (e) {}
}
''';
      final findings = ZeroWarnings712LintGate.scanSourceHygiene(
        'lib/sample.dart',
        source,
      );
      expect(findings.map((f) => f.kind), [
        ZeroWarnings712HygieneKind.ignoreForFileDirective,
        ZeroWarnings712HygieneKind.todoOrFixme,
        ZeroWarnings712HygieneKind.rawPrintCall,
        ZeroWarnings712HygieneKind.emptyCatchBlock,
      ]);
    });

    test('runGate passes with 0 issues and builds JSON & Markdown reports', () async {
      final gate = ZeroWarnings712LintGate(
        projectRootPath: '.',
        processExecutor: (args, wd) async {
          expect(args, contains('--fatal-infos'));
          expect(args, contains('--fatal-warnings'));
          return ZeroWarnings712ProcessOutput(
            exitCode: 0,
            stdout: 'No issues found! (ran in 1.2s)',
            stderr: '',
            durationMs: 1200,
            command: 'flutter ${args.join(' ')}',
          );
        },
      );

      final report = await gate.runGate(
        scope: ZeroWarnings712Scope.diagnosticsOnly,
        includeHygieneScan: false,
      );

      expect(report.isZeroWarningsPassed, isTrue);
      expect(report.verdict, ZeroWarnings712Verdict.passed);
      expect(report.totalIssuesCount, 0);
      expect(report.viewportChecks, hasLength(3));
      expect(report.allViewportsPassed, isTrue);
      expect(report.toJson()['taskId'], 711);
      expect(report.toJson()['isZeroWarningsPassed'], isTrue);
      expect(report.toMarkdownReport(), contains('NO ISSUES FOUND!'));
    });

    test('runGate fails when issues are present and aggregates ruleSummaries', () async {
      final gate = ZeroWarnings712LintGate(
        projectRootPath: '.',
        processExecutor: (args, wd) async => const ZeroWarnings712ProcessOutput(
          exitCode: 1,
          stdout: '''
warning - Unused var 'a' - lib/a.dart:1:1 - unused_local_variable
warning - Unused var 'b' - lib/b.dart:2:2 - unused_local_variable
info - Prefer const - lib/c.dart:3:3 - prefer_const_constructors
''',
          stderr: '',
          durationMs: 800,
          command: 'flutter analyze --fatal-infos',
        ),
      );

      final report = await gate.runGate(includeHygieneScan: false);
      expect(report.isZeroWarningsPassed, isFalse);
      expect(report.verdict, ZeroWarnings712Verdict.blocked);
      expect(report.warningCount, 2);
      expect(report.infoCount, 1);
      expect(report.filesWithIssuesCount, 3);
      expect(report.ruleSummaries.first.ruleName, 'unused_local_variable');
      expect(report.ruleSummaries.first.count, 2);
    });

    test('notifier filters issues by severity, rule, and search query', () async {
      final gate = ZeroWarnings712LintGate(
        projectRootPath: '.',
        processExecutor: (args, wd) async => const ZeroWarnings712ProcessOutput(
          exitCode: 1,
          stdout: '''
error - Bad type - lib/a.dart:1:1 - invalid_assignment
warning - Unused var - lib/b.dart:2:2 - unused_local_variable
''',
          stderr: '',
          durationMs: 250,
          command: 'flutter analyze --fatal-infos',
        ),
      );

      final notifier = ZeroWarnings712Notifier(gate);
      await notifier.runGate();

      expect(notifier.state.filteredIssues, hasLength(2));

      notifier.setSeverityFilter(ZeroWarnings712Severity.error);
      expect(notifier.state.filteredIssues, hasLength(1));
      expect(notifier.state.filteredIssues.first.ruleName, 'invalid_assignment');

      notifier.setSeverityFilter(null);
      notifier.setSelectedRule('unused_local_variable');
      expect(notifier.state.filteredIssues, hasLength(1));

      notifier.setSelectedRule(null);
      notifier.setSearchQuery('lib/a.dart');
      expect(notifier.state.filteredIssues, hasLength(1));

      notifier.reset();
      expect(notifier.state.report, isNull);
      expect(notifier.state.currentVerdict, ZeroWarnings712Verdict.idle);
    });
  });

  group('ZeroWarnings712LintGatePanel responsive UI tests', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders cleanly without overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          var executed = false;
          final fakeGate = ZeroWarnings712LintGate(
            projectRootPath: 'nonexistent_test_root',
            processExecutor: (args, wd) async {
              executed = true;
              return const ZeroWarnings712ProcessOutput(
                exitCode: 0,
                stdout: 'No issues found! (ran in 0.9s)',
                stderr: '',
                durationMs: 900,
                command: 'flutter analyze --fatal-infos',
              );
            },
          );

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                zeroWarnings712ServiceProvider.overrideWithValue(fakeGate),
              ],
              child: const MaterialApp(
                home: Scaffold(
                  body: ZeroWarnings712LintGatePanel(),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.text('BRAMKA JAKOŚCI #711 — TITANIUM IMPERIAL v5.0'), findsOneWidget);
          expect(find.text('Uruchom --fatal-infos'), findsOneWidget);

          await tester.tap(find.text('Skan higieny statycznej'));
          await tester.pump(const Duration(milliseconds: 250));
          await tester.tap(find.text('Uruchom --fatal-infos'));
          await tester.pump();
          await tester.runAsync(() async {
            await Future<void>.delayed(const Duration(milliseconds: 50));
          });
          await tester.pump();
          await tester.runAsync(() async {
            await Future<void>.delayed(const Duration(milliseconds: 50));
          });
          await tester.pump(const Duration(milliseconds: 300));

          expect(executed, isTrue);
          expect(find.text('BRAMKA #711 ZALICZONA (NO ISSUES FOUND!)'), findsOneWidget);
          expect(find.text('Mobile (390×844)'), findsOneWidget);
          expect(find.text('Tablet (1024×768)'), findsOneWidget);
          expect(find.text('Desktop (1600×900)'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('respects isReadOnly disabled state', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ZeroWarnings712LintGatePanel(isReadOnly: true),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Uruchom --fatal-infos'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('OCZEKUJE NA WERYFIKACJĘ'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
