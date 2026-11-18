import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/diagnostics/zero_warnings_612_lint_gate.dart';

void main() {
  group('ZeroWarnings612LintGate unit tests', () {
    test('parseFlutterAnalyzeOutput parses dash and bullet formats', () {
      const sample = '''
Analyzing pro_peloton_manager...

warning - The value of the local variable 'x' isn't used. Try removing the variable - lib\\engine\\peloton\\foo.dart:42:9 - unused_local_variable
  info • Prefer const with constant constructors • lib/ui/screens/bar.dart:10:5 • prefer_const_constructors
error - Undefined name 'z'. - lib/core/baz.dart:7:3 - undefined_identifier
''';
      final issues = ZeroWarnings612LintGate.parseFlutterAnalyzeOutput(sample);
      expect(issues, hasLength(3));
      expect(issues[0].severity, ZeroWarnings612Severity.warning);
      expect(issues[0].normalizedPath, 'lib/engine/peloton/foo.dart');
      expect(issues[0].line, 42);
      expect(issues[0].column, 9);
      expect(issues[0].ruleName, 'unused_local_variable');

      expect(issues[1].severity, ZeroWarnings612Severity.info);
      expect(issues[1].normalizedPath, 'lib/ui/screens/bar.dart');
      expect(issues[1].ruleName, 'prefer_const_constructors');

      expect(issues[2].severity, ZeroWarnings612Severity.error);
      expect(issues[2].ruleName, 'undefined_identifier');
    });

    test('parseAnalysisOptions extracts include, exclude, and strict flags', () {
      const yaml = '''
include: package:flutter_lints/flutter.yaml

analyzer:
  language:
    strict-casts: true
    strict-inference: true
  exclude:
    - build/**
    - android/**

linter:
  rules:
    - avoid_print
    - prefer_const_constructors
''';
      final audit = ZeroWarnings612LintGate.parseAnalysisOptions(yaml);
      expect(audit.includeLine, 'package:flutter_lints/flutter.yaml');
      expect(audit.hasStrictCasts, isTrue);
      expect(audit.hasStrictInference, isTrue);
      expect(audit.hasStrictRawTypes, isFalse);
      expect(audit.excludedPatterns, ['build/**', 'android/**']);
      expect(audit.customRulesCount, 2);
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
      final findings = ZeroWarnings612LintGate.scanSourceHygiene(
        'lib/sample.dart',
        source,
      );
      expect(findings.map((f) => f.kind), [
        ZeroWarnings612HygieneKind.ignoreForFileDirective,
        ZeroWarnings612HygieneKind.todoOrFixme,
        ZeroWarnings612HygieneKind.rawPrintCall,
        ZeroWarnings612HygieneKind.emptyCatchBlock,
      ]);
    });

    test('runGate passes with 0 issues and builds JSON & Markdown reports', () async {
      final gate = ZeroWarnings612LintGate(
        projectRootPath: '.',
        processExecutor: (args, wd) async {
          expect(args, contains('--fatal-infos'));
          expect(args, contains('--fatal-warnings'));
          return ZeroWarnings612ProcessOutput(
            exitCode: 0,
            stdout: 'No issues found! (ran in 1.1s)',
            stderr: '',
            durationMs: 1100,
            command: 'flutter ${args.join(' ')}',
          );
        },
      );

      final report = await gate.runGate(
        scope: ZeroWarnings612Scope.diagnosticsOnly,
        includeHygieneScan: false,
      );

      expect(report.isZeroWarningsPassed, isTrue);
      expect(report.verdict, ZeroWarnings612Verdict.passed);
      expect(report.totalIssuesCount, 0);
      expect(report.toJson()['taskId'], 611);
      expect(report.toJson()['isZeroWarningsPassed'], isTrue);
      expect(report.toMarkdownReport(), contains('BRAMKA #611 ZALICZONA'));
    });

    test('runGate fails when issues are present and aggregates ruleSummaries', () async {
      final gate = ZeroWarnings612LintGate(
        projectRootPath: '.',
        processExecutor: (args, wd) async => ZeroWarnings612ProcessOutput(
          exitCode: 1,
          stdout: '''
warning - Unused var 'a' - lib/a.dart:1:1 - unused_local_variable
warning - Unused var 'b' - lib/b.dart:2:2 - unused_local_variable
info - Prefer const - lib/c.dart:3:3 - prefer_const_constructors
''',
          stderr: '',
          durationMs: 750,
          command: 'flutter ${args.join(' ')}',
        ),
      );

      final report = await gate.runGate(includeHygieneScan: false);
      expect(report.isZeroWarningsPassed, isFalse);
      expect(report.verdict, ZeroWarnings612Verdict.blocked);
      expect(report.warningCount, 2);
      expect(report.infoCount, 1);
      expect(report.filesWithIssuesCount, 3);
      expect(report.ruleSummaries.first.ruleName, 'unused_local_variable');
      expect(report.ruleSummaries.first.count, 2);
    });

    test('notifier filters issues by severity, rule, and search query', () async {
      final gate = ZeroWarnings612LintGate(
        projectRootPath: '.',
        processExecutor: (args, wd) async => const ZeroWarnings612ProcessOutput(
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

      final notifier = ZeroWarnings612Notifier(gate);
      await notifier.runGate();
      expect(notifier.state.filteredIssues, hasLength(2));

      notifier.setSeverityFilter(ZeroWarnings612Severity.error);
      expect(notifier.state.filteredIssues, hasLength(1));
      expect(notifier.state.filteredIssues.first.ruleName, 'invalid_assignment');

      notifier.setSeverityFilter(null);
      notifier.setSelectedRule('unused_local_variable');
      expect(notifier.state.filteredIssues, hasLength(1));

      notifier.setSelectedRule(null);
      notifier.setSearchQuery('lib/b.dart');
      expect(notifier.state.filteredIssues, hasLength(1));
      expect(
        notifier.state.filteredIssues.first.ruleName,
        'unused_local_variable',
      );

      notifier.reset();
      expect(notifier.state.report, isNull);
    });
  });

  group('ZeroWarnings612LintGatePanel responsive widget tests', () {
    Widget buildTestApp({
      required Size size,
      required ZeroWarnings612LintGate gate,
      bool isReadOnly = false,
    }) {
      return ProviderScope(
        overrides: [
          zeroWarnings612ServiceProvider.overrideWithValue(gate),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: size),
            child: Scaffold(
              body: SizedBox(
                width: size.width,
                height: size.height,
                child: ZeroWarnings612LintGatePanel(isReadOnly: isReadOnly),
              ),
            ),
          ),
        ),
      );
    }

    for (final resolution in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders cleanly without overflow at ${resolution.width.toInt()}x${resolution.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = resolution;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final gate = ZeroWarnings612LintGate(
            projectRootPath: '.',
            processExecutor: (args, wd) async =>
                const ZeroWarnings612ProcessOutput(
              exitCode: 0,
              stdout: 'No issues found!',
              stderr: '',
              durationMs: 120,
              command: 'flutter analyze --fatal-infos --fatal-warnings',
            ),
          );

          await tester.pumpWidget(buildTestApp(size: resolution, gate: gate));
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.text('Uruchom --fatal-infos'), findsOneWidget);
          expect(tester.takeException(), isNull);

          await tester.tap(find.text('✓ Skan higieny (TODO/print)'));
          await tester.pump(const Duration(milliseconds: 100));

          await tester.tap(find.text('Uruchom --fatal-infos'));
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(
            find.text('BRAMKA #611 ZALICZONA (0 PROBLEMÓW)'),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('isReadOnly disables run button', (tester) async {
      const size = Size(1024, 768);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var called = false;
      final gate = ZeroWarnings612LintGate(
        projectRootPath: '.',
        processExecutor: (args, wd) async {
          called = true;
          return const ZeroWarnings612ProcessOutput(
            exitCode: 0,
            stdout: '',
            stderr: '',
            durationMs: 50,
            command: 'flutter analyze --fatal-infos',
          );
        },
      );

      await tester.pumpWidget(
        buildTestApp(size: size, gate: gate, isReadOnly: true),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Uruchom --fatal-infos'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(called, isFalse);
    });
  });
}
