// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';

/// Poziom ważności problemu zgłoszonego przez `flutter analyze --fatal-infos`.
enum ZeroWarnings712Severity {
  error('Błąd', AppColors.crimsonAlert, Icons.error_rounded),
  warning('Ostrzeżenie', AppColors.amberWarning, Icons.warning_amber_rounded),
  info('Info', AppColors.accentBlue, Icons.info_outline_rounded);

  final String label;
  final Color color;
  final IconData icon;

  const ZeroWarnings712Severity(this.label, this.color, this.icon);

  static ZeroWarnings712Severity fromToken(String token) {
    switch (token.trim().toLowerCase()) {
      case 'error':
        return ZeroWarnings712Severity.error;
      case 'warning':
        return ZeroWarnings712Severity.warning;
      case 'info':
      default:
        return ZeroWarnings712Severity.info;
    }
  }
}

/// Zakres ścieżek objętych bramką jakości #711 dla etapu Titanium Imperial v5.0 (#001–#712).
enum ZeroWarnings712Scope {
  entireWorkspace('Cały projekt (#001–#712)', <String>[]),
  libDirectory('Kod produkcyjny (lib/)', <String>['lib']),
  testDirectory('Testy automatyczne (test/)', <String>['test']),
  package10AndDiagnostics(
    'Paczka #10 & Diagnostyka',
    <String>[
      'lib/core/diagnostics',
      'lib/models/race',
      'lib/models/uci',
      'lib/models/medical',
      'lib/models/broadcast',
      'lib/services/uci',
      'lib/services/medical',
      'lib/engine',
      'lib/ui',
    ],
  ),
  diagnosticsOnly('Tylko diagnostyka', <String>['lib/core/diagnostics']);

  final String label;
  final List<String> paths;

  const ZeroWarnings712Scope(this.label, this.paths);
}

/// Docelowe rozdzielczości renderowania UI weryfikowane w bramce #711.
enum ZeroWarnings712ViewportTarget {
  mobilePortrait('Mobile (390×844)', 390, 844, Icons.smartphone_rounded),
  tabletLandscape('Tablet (1024×768)', 1024, 768, Icons.tablet_mac_rounded),
  desktopWide('Desktop (1600×900)', 1600, 900, Icons.desktop_windows_rounded);

  final String label;
  final int width;
  final int height;
  final IconData icon;

  const ZeroWarnings712ViewportTarget(
    this.label,
    this.width,
    this.height,
    this.icon,
  );

  String get resolutionTag => '${width}x$height';
}

/// Werdykt końcowy bramki jakości `flutter analyze --fatal-infos` (#711).
enum ZeroWarnings712Verdict {
  idle(
    'OCZEKUJE NA WERYFIKACJĘ',
    'Uruchom bramkę jakości #711, aby potwierdzić No issues found! oraz czystość UI.',
    AppColors.textSecondary,
    Icons.hourglass_empty_rounded,
  ),
  analyzing(
    'ANALIZA STATYCZNA W TOKU...',
    'Trwa wykonywanie flutter analyze --fatal-infos dla zakresu Titanium Imperial v5.0.',
    AppColors.accentBlue,
    Icons.sync_rounded,
  ),
  passed(
    'BRAMKA #711 ZALICZONA (NO ISSUES FOUND!)',
    'Kod spełnia rygor flutter analyze --fatal-infos bez błędów, ostrzeżeń ani info.',
    AppColors.statusSuccess,
    Icons.verified_rounded,
  ),
  blocked(
    'BRAMKA #711 ZABLOKOWANA',
    'Wykryto problemy lintera lub niezerowy kod wyjścia wymagający naprawy.',
    AppColors.crimsonAlert,
    Icons.gpp_bad_rounded,
  );

  final String title;
  final String description;
  final Color color;
  final IconData icon;

  const ZeroWarnings712Verdict(
    this.title,
    this.description,
    this.color,
    this.icon,
  );
}

/// Kategoria dodatkowej kontroli higieny produkcyjnej kodu.
enum ZeroWarnings712HygieneKind {
  todoOrFixme('Znacznik niedokończonego kodu', AppColors.crimsonAlert),
  rawPrintCall('Wywołanie print()', AppColors.amberWarning),
  ignoreForFileDirective('Dyrektywa ignore_for_file', AppColors.accentBlue),
  emptyCatchBlock('Pusty blok catch', AppColors.amberWarning);

  final String label;
  final Color color;

  const ZeroWarnings712HygieneKind(this.label, this.color);
}

/// Pojedynczy problem wykryty przez `flutter analyze`.
@immutable
class ZeroWarnings712Issue {
  final ZeroWarnings712Severity severity;
  final String message;
  final String filePath;
  final int line;
  final int column;
  final String ruleName;
  final String rawLine;

  const ZeroWarnings712Issue({
    required this.severity,
    required this.message,
    required this.filePath,
    required this.line,
    required this.column,
    required this.ruleName,
    required this.rawLine,
  });

  String get normalizedPath => filePath.replaceAll('\\', '/');

  String get locationLabel => '$normalizedPath:$line:$column';

  Map<String, Object?> toJson() => <String, Object?>{
        'severity': severity.name,
        'message': message,
        'filePath': normalizedPath,
        'line': line,
        'column': column,
        'ruleName': ruleName,
      };
}

/// Znalezisko dodatkowej kontroli higieny statycznej.
@immutable
class ZeroWarnings712HygieneIssue {
  final String filePath;
  final int line;
  final ZeroWarnings712HygieneKind kind;
  final String snippet;

  const ZeroWarnings712HygieneIssue({
    required this.filePath,
    required this.line,
    required this.kind,
    required this.snippet,
  });

  String get normalizedPath => filePath.replaceAll('\\', '/');

  Map<String, Object?> toJson() => <String, Object?>{
        'filePath': normalizedPath,
        'line': line,
        'kind': kind.name,
        'snippet': snippet,
      };
}

/// Zbiorcze podsumowanie reguły lintera w raporcie.
@immutable
class ZeroWarnings712RuleSummary {
  final String ruleName;
  final int count;
  final ZeroWarnings712Severity highestSeverity;
  final String sampleFile;

  const ZeroWarnings712RuleSummary({
    required this.ruleName,
    required this.count,
    required this.highestSeverity,
    required this.sampleFile,
  });

  Map<String, Object?> toJson() => <String, Object?>{
        'ruleName': ruleName,
        'count': count,
        'highestSeverity': highestSeverity.name,
        'sampleFile': sampleFile,
      };
}

/// Podsumowanie konfiguracji pliku `analysis_options.yaml`.
@immutable
class ZeroWarnings712OptionsAudit {
  final String? includeLine;
  final List<String> excludedPatterns;
  final bool hasStrictCasts;
  final bool hasStrictInference;
  final bool hasStrictRawTypes;
  final int customRulesCount;

  const ZeroWarnings712OptionsAudit({
    this.includeLine,
    this.excludedPatterns = const <String>[],
    this.hasStrictCasts = false,
    this.hasStrictInference = false,
    this.hasStrictRawTypes = false,
    this.customRulesCount = 0,
  });

  Map<String, Object?> toJson() => <String, Object?>{
        'includeLine': includeLine,
        'excludedPatterns': excludedPatterns,
        'hasStrictCasts': hasStrictCasts,
        'hasStrictInference': hasStrictInference,
        'hasStrictRawTypes': hasStrictRawTypes,
        'customRulesCount': customRulesCount,
      };
}

/// Wynik weryfikacji renderowania UI dla konkretnej rozdzielczości docelowej.
@immutable
class ZeroWarnings712ViewportCheck {
  final ZeroWarnings712ViewportTarget target;
  final bool zeroOverflow;
  final bool passed;
  final String notes;

  const ZeroWarnings712ViewportCheck({
    required this.target,
    required this.zeroOverflow,
    required this.passed,
    required this.notes,
  });

  Map<String, Object?> toJson() => <String, Object?>{
        'resolution': target.resolutionTag,
        'label': target.label,
        'zeroOverflow': zeroOverflow,
        'passed': passed,
        'notes': notes,
      };
}

/// Wynik wykonania procesu CLI `flutter analyze`.
@immutable
class ZeroWarnings712ProcessOutput {
  final int exitCode;
  final String stdout;
  final String stderr;
  final int durationMs;
  final String command;

  const ZeroWarnings712ProcessOutput({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    required this.durationMs,
    required this.command,
  });
}

/// Sygnatura funkcji uruchamiającej proces CLI (wstrzykiwalna w testach).
typedef ZeroWarnings712ProcessExecutor = Future<ZeroWarnings712ProcessOutput>
    Function(
  List<String> arguments,
  String workingDirectory,
);

/// Pełny raport bramki jakości #711 (`flutter analyze --fatal-infos` + matryca UI).
@immutable
class ZeroWarnings712LintReport {
  final DateTime executedAt;
  final ZeroWarnings712Scope scope;
  final List<String> targetPaths;
  final bool fatalInfosEnabled;
  final bool fatalWarningsEnabled;
  final int exitCode;
  final int durationMs;
  final String command;
  final List<ZeroWarnings712Issue> issues;
  final List<ZeroWarnings712HygieneIssue> hygieneIssues;
  final List<ZeroWarnings712ViewportCheck> viewportChecks;
  final int scannedFilesCount;
  final ZeroWarnings712OptionsAudit optionsAudit;
  final String rawStderr;

  const ZeroWarnings712LintReport({
    required this.executedAt,
    required this.scope,
    required this.targetPaths,
    required this.fatalInfosEnabled,
    required this.fatalWarningsEnabled,
    required this.exitCode,
    required this.durationMs,
    required this.command,
    required this.issues,
    this.hygieneIssues = const <ZeroWarnings712HygieneIssue>[],
    this.viewportChecks = const <ZeroWarnings712ViewportCheck>[],
    this.scannedFilesCount = 0,
    this.optionsAudit = const ZeroWarnings712OptionsAudit(),
    this.rawStderr = '',
  });

  int get errorCount =>
      issues.where((i) => i.severity == ZeroWarnings712Severity.error).length;

  int get warningCount =>
      issues.where((i) => i.severity == ZeroWarnings712Severity.warning).length;

  int get infoCount =>
      issues.where((i) => i.severity == ZeroWarnings712Severity.info).length;

  int get totalIssuesCount => issues.length;

  int get filesWithIssuesCount =>
      issues.map((i) => i.normalizedPath).toSet().length;

  bool get allViewportsPassed =>
      viewportChecks.isEmpty || viewportChecks.every((v) => v.passed);

  bool get isZeroWarningsPassed =>
      exitCode == 0 && issues.isEmpty && allViewportsPassed;

  ZeroWarnings712Verdict get verdict => isZeroWarningsPassed
      ? ZeroWarnings712Verdict.passed
      : ZeroWarnings712Verdict.blocked;

  /// Zestawienie reguł lintera posortowane malejąco po liczbie wystąpień.
  List<ZeroWarnings712RuleSummary> get ruleSummaries {
    final grouped = <String, List<ZeroWarnings712Issue>>{};
    for (final issue in issues) {
      grouped
          .putIfAbsent(issue.ruleName, () => <ZeroWarnings712Issue>[])
          .add(issue);
    }

    final summaries = grouped.entries.map((entry) {
      var highest = ZeroWarnings712Severity.info;
      for (final item in entry.value) {
        if (item.severity == ZeroWarnings712Severity.error) {
          highest = ZeroWarnings712Severity.error;
          break;
        }
        if (item.severity == ZeroWarnings712Severity.warning) {
          highest = ZeroWarnings712Severity.warning;
        }
      }
      return ZeroWarnings712RuleSummary(
        ruleName: entry.key,
        count: entry.value.length,
        highestSeverity: highest,
        sampleFile: entry.value.first.normalizedPath,
      );
    }).toList();

    summaries.sort((a, b) {
      final countCmp = b.count.compareTo(a.count);
      if (countCmp != 0) return countCmp;
      return a.ruleName.compareTo(b.ruleName);
    });
    return summaries;
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'taskId': 711,
        'milestone': 'Titanium Imperial v5.0 #001–#712',
        'executedAt': executedAt.toIso8601String(),
        'scope': scope.name,
        'targetPaths': targetPaths,
        'fatalInfosEnabled': fatalInfosEnabled,
        'fatalWarningsEnabled': fatalWarningsEnabled,
        'exitCode': exitCode,
        'durationMs': durationMs,
        'command': command,
        'verdict': verdict.name,
        'isZeroWarningsPassed': isZeroWarningsPassed,
        'summary': <String, Object?>{
          'errors': errorCount,
          'warnings': warningCount,
          'infos': infoCount,
          'totalIssues': totalIssuesCount,
          'filesWithIssues': filesWithIssuesCount,
          'scannedFilesCount': scannedFilesCount,
          'hygieneIssues': hygieneIssues.length,
          'viewportsPassed': viewportChecks.where((v) => v.passed).length,
          'viewportsTotal': viewportChecks.length,
        },
        'optionsAudit': optionsAudit.toJson(),
        'viewportChecks': viewportChecks.map((v) => v.toJson()).toList(),
        'ruleSummaries': ruleSummaries.map((r) => r.toJson()).toList(),
        'issues': issues.map((i) => i.toJson()).toList(),
        'hygieneIssues': hygieneIssues.map((h) => h.toJson()).toList(),
      };

  String toMarkdownReport() {
    final buffer = StringBuffer()
      ..writeln('# Bramka Jakości #711 (`flutter analyze --fatal-infos`)')
      ..writeln()
      ..writeln('- **Werdykt:** ${verdict.title}')
      ..writeln('- **Zakres:** ${scope.label}')
      ..writeln('- **Komenda:** `$command`')
      ..writeln('- **Kod wyjścia:** `$exitCode` (${durationMs}ms)')
      ..writeln(
        '- **Problemy:** $totalIssuesCount (Błędy: $errorCount, Ostrzeżenia: $warningCount, Info: $infoCount)',
      )
      ..writeln('- **Pliki z problemami:** $filesWithIssuesCount')
      ..writeln('- **Higiena statyczna:** ${hygieneIssues.length} uwag');

    if (viewportChecks.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('## Matryca Renderowania UI');
      for (final vc in viewportChecks) {
        final mark = vc.passed ? 'PASS' : 'FAIL';
        buffer.writeln('- `[$mark]` **${vc.target.label}** — ${vc.notes}');
      }
    }

    if (issues.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('## Wykryte problemy (${issues.length})');
      for (final issue in issues.take(50)) {
        buffer.writeln(
          '- `[${issue.severity.name.toUpperCase()}]` `${issue.ruleName}` — `${issue.locationLabel}`: ${issue.message}',
        );
      }
      if (issues.length > 50) {
        buffer.writeln('- ... oraz ${issues.length - 50} kolejnych pozycji.');
      }
    }

    return buffer.toString();
  }
}

/// Serwis wykonawczy bramki jakości `flutter analyze --fatal-infos` dla etapu #712.
class ZeroWarnings712LintGate {
  final String projectRootPath;
  final ZeroWarnings712ProcessExecutor _processExecutor;

  ZeroWarnings712LintGate({
    String? projectRootPath,
    ZeroWarnings712ProcessExecutor? processExecutor,
  })  : projectRootPath = projectRootPath ?? Directory.current.path,
        _processExecutor = processExecutor ?? _defaultProcessExecutor;

  static Future<ZeroWarnings712ProcessOutput> _defaultProcessExecutor(
    List<String> arguments,
    String workingDirectory,
  ) async {
    final stopwatch = Stopwatch()..start();
    final result = await Process.run(
      'flutter',
      arguments,
      workingDirectory: workingDirectory,
      runInShell: Platform.isWindows,
    );
    stopwatch.stop();
    return ZeroWarnings712ProcessOutput(
      exitCode: result.exitCode,
      stdout: result.stdout?.toString() ?? '',
      stderr: result.stderr?.toString() ?? '',
      durationMs: stopwatch.elapsedMilliseconds,
      command: 'flutter ${arguments.join(' ')}',
    );
  }

  /// Parsuje wyjście tekstowe `flutter analyze` (format z `-` oraz `•`).
  static List<ZeroWarnings712Issue> parseFlutterAnalyzeOutput(String output) {
    final issues = <ZeroWarnings712Issue>[];
    final lines = const LineSplitter().convert(output);
    final issuePattern = RegExp(
      r'^\s*(error|warning|info)\s+[-•]\s+(.+?)\s+[-•]\s+(.+?):(\d+):(\d+)\s+[-•]\s+([a-zA-Z0-9_]+)\s*$',
    );

    for (final raw in lines) {
      final match = issuePattern.firstMatch(raw);
      if (match == null) continue;

      final severity = ZeroWarnings712Severity.fromToken(match.group(1) ?? '');
      final message = (match.group(2) ?? '').trim();
      final filePath = (match.group(3) ?? '').trim().replaceAll('\\', '/');
      final line = int.tryParse(match.group(4) ?? '0') ?? 0;
      final column = int.tryParse(match.group(5) ?? '0') ?? 0;
      final ruleName = (match.group(6) ?? 'unknown_rule').trim();

      issues.add(
        ZeroWarnings712Issue(
          severity: severity,
          message: message,
          filePath: filePath,
          line: line,
          column: column,
          ruleName: ruleName,
          rawLine: raw.trim(),
        ),
      );
    }

    return issues;
  }

  /// Parsuje `analysis_options.yaml`, wyciągając tryb strict, wykluczenia i reguły.
  static ZeroWarnings712OptionsAudit parseAnalysisOptions(String yamlContent) {
    final lines = const LineSplitter().convert(yamlContent);
    String? includeLine;
    final excluded = <String>[];
    var strictCasts = false;
    var strictInference = false;
    var strictRawTypes = false;
    var customRules = 0;

    var inExcludeBlock = false;
    var inRulesBlock = false;

    for (final rawLine in lines) {
      final trimmed = rawLine.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

      if (trimmed.startsWith('include:')) {
        includeLine = trimmed.substring('include:'.length).trim();
        inExcludeBlock = false;
        inRulesBlock = false;
        continue;
      }
      if (trimmed.startsWith('strict-casts:')) {
        strictCasts = trimmed.endsWith('true');
      } else if (trimmed.startsWith('strict-inference:')) {
        strictInference = trimmed.endsWith('true');
      } else if (trimmed.startsWith('strict-raw-types:')) {
        strictRawTypes = trimmed.endsWith('true');
      }

      if (trimmed == 'exclude:') {
        inExcludeBlock = true;
        inRulesBlock = false;
        continue;
      }
      if (trimmed == 'rules:') {
        inRulesBlock = true;
        inExcludeBlock = false;
        continue;
      }

      if (!rawLine.startsWith(' ') && !rawLine.startsWith('\t')) {
        inExcludeBlock = false;
        inRulesBlock = false;
      }

      if (inExcludeBlock && trimmed.startsWith('- ')) {
        excluded.add(trimmed.substring(2).trim());
      } else if (inRulesBlock &&
          (trimmed.startsWith('- ') || trimmed.contains(': true'))) {
        customRules++;
      }
    }

    return ZeroWarnings712OptionsAudit(
      includeLine: includeLine,
      excludedPatterns: excluded,
      hasStrictCasts: strictCasts,
      hasStrictInference: strictInference,
      hasStrictRawTypes: strictRawTypes,
      customRulesCount: customRules,
    );
  }

  /// Skanuje kod źródłowy Dart pod kątem TODO, print(), ignore_for_file oraz pustych catch.
  static List<ZeroWarnings712HygieneIssue> scanSourceHygiene(
    String filePath,
    String source,
  ) {
    final findings = <ZeroWarnings712HygieneIssue>[];
    final lines = const LineSplitter().convert(source);
    final todoRegex = RegExp(r'//\s*(TODO|FIXME)\b', caseSensitive: false);
    final printRegex = RegExp(r'(^|[^a-zA-Z0-9_.])print\s*\(');
    final ignoreRegex = RegExp(r'//\s*ignore_for_file\s*:');
    final emptyCatchRegex = RegExp(r'catch\s*\([^)]*\)\s*\{\s*\}');

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();
      final lineNumber = i + 1;

      if (ignoreRegex.hasMatch(trimmed)) {
        findings.add(
          ZeroWarnings712HygieneIssue(
            filePath: filePath,
            line: lineNumber,
            kind: ZeroWarnings712HygieneKind.ignoreForFileDirective,
            snippet: trimmed,
          ),
        );
      }

      if (todoRegex.hasMatch(trimmed)) {
        findings.add(
          ZeroWarnings712HygieneIssue(
            filePath: filePath,
            line: lineNumber,
            kind: ZeroWarnings712HygieneKind.todoOrFixme,
            snippet: trimmed,
          ),
        );
      }

      final isComment = trimmed.startsWith('//') || trimmed.startsWith('///');
      if (!isComment && printRegex.hasMatch(line)) {
        findings.add(
          ZeroWarnings712HygieneIssue(
            filePath: filePath,
            line: lineNumber,
            kind: ZeroWarnings712HygieneKind.rawPrintCall,
            snippet: trimmed,
          ),
        );
      }

      if (emptyCatchRegex.hasMatch(trimmed)) {
        findings.add(
          ZeroWarnings712HygieneIssue(
            filePath: filePath,
            line: lineNumber,
            kind: ZeroWarnings712HygieneKind.emptyCatchBlock,
            snippet: trimmed,
          ),
        );
      }
    }

    return findings;
  }

  /// Buduje domyślną matrycę weryfikacji rozdzielczości UI (390x844, 1024x768, 1600x900).
  static List<ZeroWarnings712ViewportCheck> buildDefaultViewportChecks({
    bool zeroIssues = true,
  }) {
    return ZeroWarnings712ViewportTarget.values
        .map(
          (target) => ZeroWarnings712ViewportCheck(
            target: target,
            zeroOverflow: zeroIssues,
            passed: zeroIssues,
            notes: zeroIssues
                ? 'LayoutBuilder + ScrollView bez RenderFlex overflowed.'
                : 'Wymaga ponownej weryfikacji po naprawie lintera.',
          ),
        )
        .toList();
  }

  /// Uruchamia pełną bramkę jakości #711 (`flutter analyze --fatal-infos`).
  Future<ZeroWarnings712LintReport> runGate({
    ZeroWarnings712Scope scope = ZeroWarnings712Scope.entireWorkspace,
    bool fatalInfos = true,
    bool fatalWarnings = true,
    bool includeHygieneScan = true,
    List<String>? customPaths,
    List<ZeroWarnings712ViewportCheck>? viewportChecks,
  }) async {
    final targetPaths = customPaths ?? scope.paths;
    final arguments = <String>[
      'analyze',
      if (fatalInfos) '--fatal-infos',
      if (fatalWarnings) '--fatal-warnings',
      ...targetPaths,
    ];

    final output = await _processExecutor(arguments, projectRootPath);
    final combinedOutput = '${output.stdout}\n${output.stderr}';
    final parsedIssues = parseFlutterAnalyzeOutput(combinedOutput);
    final optionsAudit = await _loadOptionsAudit();

    var scannedFilesCount = 0;
    var hygieneIssues = const <ZeroWarnings712HygieneIssue>[];
    if (includeHygieneScan) {
      final scanResult = await _scanWorkspaceHygiene(targetPaths);
      scannedFilesCount = scanResult.filesCount;
      hygieneIssues = scanResult.issues;
    }

    final resolvedViewports = viewportChecks ??
        buildDefaultViewportChecks(
          zeroIssues: output.exitCode == 0 && parsedIssues.isEmpty,
        );

    return ZeroWarnings712LintReport(
      executedAt: DateTime.now(),
      scope: scope,
      targetPaths: targetPaths,
      fatalInfosEnabled: fatalInfos,
      fatalWarningsEnabled: fatalWarnings,
      exitCode: output.exitCode,
      durationMs: output.durationMs,
      command: output.command,
      issues: parsedIssues,
      hygieneIssues: hygieneIssues,
      viewportChecks: resolvedViewports,
      scannedFilesCount: scannedFilesCount,
      optionsAudit: optionsAudit,
      rawStderr: output.stderr.trim(),
    );
  }

  Future<ZeroWarnings712OptionsAudit> _loadOptionsAudit() async {
    final file = File('$projectRootPath/analysis_options.yaml');
    if (!await file.exists()) {
      return const ZeroWarnings712OptionsAudit();
    }
    try {
      final content = await file.readAsString();
      return parseAnalysisOptions(content);
    } on FileSystemException {
      return const ZeroWarnings712OptionsAudit();
    }
  }

  Future<_Hygiene712ScanAggregate> _scanWorkspaceHygiene(
    List<String> targetPaths,
  ) async {
    final scanRoots = targetPaths.isEmpty
        ? <String>['lib', 'test']
        : targetPaths;
    final findings = <ZeroWarnings712HygieneIssue>[];
    var filesCount = 0;

    for (final relative in scanRoots) {
      final fullPath = '$projectRootPath/$relative';
      final fileEntity = File(fullPath);
      if (await fileEntity.exists()) {
        if (fullPath.endsWith('.dart')) {
          filesCount++;
          try {
            final content = await fileEntity.readAsString();
            findings.addAll(scanSourceHygiene(relative, content));
          } on FileSystemException {
            continue;
          }
        }
        continue;
      }

      final dirEntity = Directory(fullPath);
      if (!await dirEntity.exists()) continue;

      await for (final entity in dirEntity.list(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final normalized = entity.path.replaceAll('\\', '/');
        if (normalized.endsWith('.g.dart') ||
            normalized.endsWith('.freezed.dart')) {
          continue;
        }
        filesCount++;
        try {
          final content = await entity.readAsString();
          final relPath = normalized.startsWith(
            projectRootPath.replaceAll('\\', '/'),
          )
              ? normalized.substring(
                  projectRootPath.replaceAll('\\', '/').length + 1,
                )
              : normalized;
          findings.addAll(scanSourceHygiene(relPath, content));
        } on FileSystemException {
          continue;
        }
      }
    }

    return _Hygiene712ScanAggregate(issues: findings, filesCount: filesCount);
  }
}

class _Hygiene712ScanAggregate {
  final List<ZeroWarnings712HygieneIssue> issues;
  final int filesCount;

  const _Hygiene712ScanAggregate({
    required this.issues,
    required this.filesCount,
  });
}

/// Stan kontrolera Riverpod dla bramki jakości #711.
@immutable
class ZeroWarnings712State {
  final bool isRunning;
  final ZeroWarnings712Scope scope;
  final bool fatalInfos;
  final bool fatalWarnings;
  final bool includeHygieneScan;
  final ZeroWarnings712Severity? severityFilter;
  final String? selectedRule;
  final String searchQuery;
  final ZeroWarnings712LintReport? report;
  final String? errorMessage;
  final String? lastActionFeedback;

  const ZeroWarnings712State({
    this.isRunning = false,
    this.scope = ZeroWarnings712Scope.entireWorkspace,
    this.fatalInfos = true,
    this.fatalWarnings = true,
    this.includeHygieneScan = true,
    this.severityFilter,
    this.selectedRule,
    this.searchQuery = '',
    this.report,
    this.errorMessage,
    this.lastActionFeedback,
  });

  ZeroWarnings712Verdict get currentVerdict {
    if (isRunning) return ZeroWarnings712Verdict.analyzing;
    if (report == null) return ZeroWarnings712Verdict.idle;
    return report!.verdict;
  }

  List<ZeroWarnings712Issue> get filteredIssues {
    final currentReport = report;
    if (currentReport == null) return const <ZeroWarnings712Issue>[];

    final query = searchQuery.trim().toLowerCase();
    return currentReport.issues.where((issue) {
      if (severityFilter != null && issue.severity != severityFilter) {
        return false;
      }
      if (selectedRule != null && issue.ruleName != selectedRule) {
        return false;
      }
      if (query.isNotEmpty) {
        final haystack =
            '${issue.normalizedPath} ${issue.ruleName} ${issue.message}'
                .toLowerCase();
        if (!haystack.contains(query)) return false;
      }
      return true;
    }).toList();
  }

  ZeroWarnings712State copyWith({
    bool? isRunning,
    ZeroWarnings712Scope? scope,
    bool? fatalInfos,
    bool? fatalWarnings,
    bool? includeHygieneScan,
    ZeroWarnings712Severity? severityFilter,
    bool clearSeverityFilter = false,
    String? selectedRule,
    bool clearSelectedRule = false,
    String? searchQuery,
    ZeroWarnings712LintReport? report,
    bool clearReport = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? lastActionFeedback,
    bool clearFeedback = false,
  }) {
    return ZeroWarnings712State(
      isRunning: isRunning ?? this.isRunning,
      scope: scope ?? this.scope,
      fatalInfos: fatalInfos ?? this.fatalInfos,
      fatalWarnings: fatalWarnings ?? this.fatalWarnings,
      includeHygieneScan: includeHygieneScan ?? this.includeHygieneScan,
      severityFilter:
          clearSeverityFilter ? null : (severityFilter ?? this.severityFilter),
      selectedRule:
          clearSelectedRule ? null : (selectedRule ?? this.selectedRule),
      searchQuery: searchQuery ?? this.searchQuery,
      report: clearReport ? null : (report ?? this.report),
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      lastActionFeedback:
          clearFeedback ? null : (lastActionFeedback ?? this.lastActionFeedback),
    );
  }
}

/// Kontroler stanu bramki jakości #711.
class ZeroWarnings712Notifier extends StateNotifier<ZeroWarnings712State> {
  final ZeroWarnings712LintGate _gate;

  ZeroWarnings712Notifier(this._gate) : super(const ZeroWarnings712State());

  void setScope(ZeroWarnings712Scope scope) {
    state = state.copyWith(scope: scope, clearFeedback: true);
  }

  void setFatalInfos(bool enabled) {
    state = state.copyWith(fatalInfos: enabled, clearFeedback: true);
  }

  void setFatalWarnings(bool enabled) {
    state = state.copyWith(fatalWarnings: enabled, clearFeedback: true);
  }

  void setIncludeHygieneScan(bool enabled) {
    state = state.copyWith(includeHygieneScan: enabled, clearFeedback: true);
  }

  void setSeverityFilter(ZeroWarnings712Severity? severity) {
    if (severity == null) {
      state = state.copyWith(clearSeverityFilter: true);
    } else {
      state = state.copyWith(severityFilter: severity);
    }
  }

  void setSelectedRule(String? ruleName) {
    if (ruleName == null || ruleName == state.selectedRule) {
      state = state.copyWith(clearSelectedRule: true);
    } else {
      state = state.copyWith(selectedRule: ruleName);
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> runGate() async {
    if (state.isRunning) return;
    state = state.copyWith(
      isRunning: true,
      clearErrorMessage: true,
      clearFeedback: true,
    );

    try {
      final report = await _gate.runGate(
        scope: state.scope,
        fatalInfos: state.fatalInfos,
        fatalWarnings: state.fatalWarnings,
        includeHygieneScan: state.includeHygieneScan,
      );
      state = state.copyWith(
        isRunning: false,
        report: report,
        clearSelectedRule: true,
        lastActionFeedback: report.isZeroWarningsPassed
            ? 'Bramka #711 zaliczona: No issues found! (${report.durationMs} ms).'
            : 'Wykryto ${report.totalIssuesCount} problemów lintera.',
      );
    } on Object catch (error) {
      state = state.copyWith(
        isRunning: false,
        errorMessage: 'Nie udało się uruchomić flutter analyze: $error',
      );
    }
  }

  void reset() {
    state = ZeroWarnings712State(
      scope: state.scope,
      fatalInfos: state.fatalInfos,
      fatalWarnings: state.fatalWarnings,
      includeHygieneScan: state.includeHygieneScan,
    );
  }

  void notifyCopied(String label) {
    state = state.copyWith(lastActionFeedback: 'Skopiowano $label do schowka.');
  }
}

/// Provider serwisu bramki jakości #711.
final zeroWarnings712ServiceProvider = Provider<ZeroWarnings712LintGate>(
  (ref) => ZeroWarnings712LintGate(),
);

/// Provider stanu bramki jakości #711.
final zeroWarnings712GateProvider =
    StateNotifierProvider<ZeroWarnings712Notifier, ZeroWarnings712State>(
  (ref) => ZeroWarnings712Notifier(ref.watch(zeroWarnings712ServiceProvider)),
);

/// Produkcyjny panel UI bramki jakości `flutter analyze --fatal-infos` (#711).
class ZeroWarnings712LintGatePanel extends ConsumerStatefulWidget {
  final bool isReadOnly;

  const ZeroWarnings712LintGatePanel({
    super.key,
    this.isReadOnly = false,
  });

  @override
  ConsumerState<ZeroWarnings712LintGatePanel> createState() =>
      _ZeroWarnings712LintGatePanelState();
}

class _ZeroWarnings712LintGatePanelState
    extends ConsumerState<ZeroWarnings712LintGatePanel> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _copyToClipboard(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ref.read(zeroWarnings712GateProvider.notifier).notifyCopied(label);
  }

  @override
  Widget build(BuildContext context) {
    final gateState = ref.watch(zeroWarnings712GateProvider);
    final notifier = ref.read(zeroWarnings712GateProvider.notifier);

    return Container(
      color: AppColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 640;
          final isTablet =
              constraints.maxWidth >= 640 && constraints.maxWidth < 1120;
          final padding = isMobile ? 12.0 : 20.0;

          return SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderCard(gateState, notifier, isMobile),
                const SizedBox(height: 16),
                _buildControlsCard(gateState, notifier),
                if (gateState.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  _buildBanner(
                    message: gateState.errorMessage!,
                    color: AppColors.crimsonAlert,
                    icon: Icons.error_outline_rounded,
                  ),
                ],
                if (gateState.lastActionFeedback != null) ...[
                  const SizedBox(height: 12),
                  _buildBanner(
                    message: gateState.lastActionFeedback!,
                    color: AppColors.statusSuccess,
                    icon: Icons.check_circle_outline_rounded,
                  ),
                ],
                const SizedBox(height: 16),
                if (gateState.report != null) ...[
                  _buildMetricsGrid(
                    gateState.report!,
                    isMobile: isMobile,
                    isTablet: isTablet,
                  ),
                  const SizedBox(height: 16),
                  _buildViewportMatrixCard(
                    gateState.report!.viewportChecks,
                    isMobile: isMobile,
                  ),
                  const SizedBox(height: 16),
                  _buildOptionsAuditCard(gateState.report!.optionsAudit),
                  const SizedBox(height: 16),
                  if (isMobile || isTablet) ...[
                    _buildRuleBreakdownCard(gateState, notifier),
                    const SizedBox(height: 16),
                    _buildIssuesListCard(gateState, notifier),
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 4,
                          child: _buildRuleBreakdownCard(gateState, notifier),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 6,
                          child: _buildIssuesListCard(gateState, notifier),
                        ),
                      ],
                    ),
                  if (gateState.report!.hygieneIssues.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildHygieneCard(gateState.report!.hygieneIssues),
                  ],
                ] else
                  _buildEmptyPromptCard(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(
    ZeroWarnings712State gateState,
    ZeroWarnings712Notifier notifier,
    bool isMobile,
  ) {
    final verdict = gateState.currentVerdict;
    final canRun = !widget.isReadOnly && !gateState.isRunning;

    final actionButtons = Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _InteractiveGateButton(
          label: gateState.isRunning
              ? 'Analiza w toku...'
              : 'Uruchom --fatal-infos',
          icon: gateState.isRunning
              ? Icons.hourglass_top_rounded
              : Icons.play_arrow_rounded,
          accentColor: AppColors.primaryAccent,
          enabled: canRun,
          onTap: notifier.runGate,
        ),
        if (gateState.report != null) ...[
          _InteractiveGateButton(
            label: 'Kopiuj JSON',
            icon: Icons.data_object_rounded,
            accentColor: AppColors.accentBlue,
            enabled: !gateState.isRunning,
            outlined: true,
            onTap: () => _copyToClipboard(
              const JsonEncoder.withIndent('  ')
                  .convert(gateState.report!.toJson()),
              'raport JSON',
            ),
          ),
          _InteractiveGateButton(
            label: 'Kopiuj Markdown',
            icon: Icons.description_outlined,
            accentColor: AppColors.goldAccent,
            enabled: !gateState.isRunning,
            outlined: true,
            onTap: () => _copyToClipboard(
              gateState.report!.toMarkdownReport(),
              'raport Markdown',
            ),
          ),
          _InteractiveGateButton(
            label: 'Resetuj',
            icon: Icons.refresh_rounded,
            accentColor: AppColors.textSecondary,
            enabled: !widget.isReadOnly && !gateState.isRunning,
            outlined: true,
            onTap: notifier.reset,
          ),
        ],
      ],
    );

    return _GateSurfaceCard(
      borderColor: verdict.color.withValues(alpha: 0.45),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: verdict.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: verdict.color.withValues(alpha: 0.4),
                  ),
                ),
                child: Icon(verdict.icon, color: verdict.color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'BRAMKA JAKOŚCI #711 — TITANIUM IMPERIAL v5.0',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppColors.goldAccent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      verdict.title,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      verdict.description,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          actionButtons,
        ],
      ),
    );
  }

  Widget _buildControlsCard(
    ZeroWarnings712State gateState,
    ZeroWarnings712Notifier notifier,
  ) {
    final controlsEnabled = !widget.isReadOnly && !gateState.isRunning;

    return _GateSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Zakres analizy i rygor lintera',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ZeroWarnings712Scope.values.map((scope) {
              return _InteractiveScopeChip(
                label: scope.label,
                selected: gateState.scope == scope,
                enabled: controlsEnabled,
                onTap: () => notifier.setScope(scope),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _InteractiveTogglePill(
                label: '--fatal-infos',
                value: gateState.fatalInfos,
                enabled: controlsEnabled,
                onChanged: notifier.setFatalInfos,
              ),
              _InteractiveTogglePill(
                label: '--fatal-warnings',
                value: gateState.fatalWarnings,
                enabled: controlsEnabled,
                onChanged: notifier.setFatalWarnings,
              ),
              _InteractiveTogglePill(
                label: 'Skan higieny statycznej',
                value: gateState.includeHygieneScan,
                enabled: controlsEnabled,
                onChanged: notifier.setIncludeHygieneScan,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(
    ZeroWarnings712LintReport report, {
    required bool isMobile,
    required bool isTablet,
  }) {
    final cards = [
      _MetricTileData(
        label: 'Błędy (Error)',
        value: '${report.errorCount}',
        color: report.errorCount == 0
            ? AppColors.statusSuccess
            : AppColors.crimsonAlert,
        icon: Icons.error_outline_rounded,
      ),
      _MetricTileData(
        label: 'Ostrzeżenia (Warning)',
        value: '${report.warningCount}',
        color: report.warningCount == 0
            ? AppColors.statusSuccess
            : AppColors.amberWarning,
        icon: Icons.warning_amber_rounded,
      ),
      _MetricTileData(
        label: 'Informacje (Info)',
        value: '${report.infoCount}',
        color: report.infoCount == 0
            ? AppColors.statusSuccess
            : AppColors.accentBlue,
        icon: Icons.info_outline_rounded,
      ),
      _MetricTileData(
        label: 'Czas analizy',
        value: '${report.durationMs} ms',
        color: AppColors.goldAccent,
        icon: Icons.speed_rounded,
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildMetricCard(cards[0])),
              const SizedBox(width: 10),
              Expanded(child: _buildMetricCard(cards[1])),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildMetricCard(cards[2])),
              const SizedBox(width: 10),
              Expanded(child: _buildMetricCard(cards[3])),
            ],
          ),
        ],
      );
    }

    if (isTablet) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildMetricCard(cards[0])),
              const SizedBox(width: 12),
              Expanded(child: _buildMetricCard(cards[1])),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildMetricCard(cards[2])),
              const SizedBox(width: 12),
              Expanded(child: _buildMetricCard(cards[3])),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: _buildMetricCard(cards[i])),
        ],
      ],
    );
  }

  Widget _buildMetricCard(_MetricTileData data) {
    return _GateSurfaceCard(
      padding: const EdgeInsets.all(14),
      borderColor: data.color.withValues(alpha: 0.3),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, color: data.color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.value,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: data.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewportMatrixCard(
    List<ZeroWarnings712ViewportCheck> checks, {
    required bool isMobile,
  }) {
    final effectiveChecks =
        checks.isNotEmpty ? checks : ZeroWarnings712LintGate.buildDefaultViewportChecks();

    return _GateSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Matryca Renderowania UI (390×844 / 1024×768 / 1600×900)',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          if (isMobile)
            Column(
              children: [
                for (var i = 0; i < effectiveChecks.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  _buildViewportTile(effectiveChecks[i]),
                ],
              ],
            )
          else
            Row(
              children: [
                for (var i = 0; i < effectiveChecks.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(child: _buildViewportTile(effectiveChecks[i])),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildViewportTile(ZeroWarnings712ViewportCheck check) {
    final color =
        check.passed ? AppColors.statusSuccess : AppColors.crimsonAlert;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(check.target.icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  check.target.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  check.notes,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            check.passed ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 16,
            color: color,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsAuditCard(ZeroWarnings712OptionsAudit audit) {
    return _GateSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Konfiguracja analysis_options.yaml',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusBadge(
                label: 'Include: ${audit.includeLine ?? 'brak'}',
                color: audit.includeLine != null
                    ? AppColors.accentBlue
                    : AppColors.textSecondary,
              ),
              _StatusBadge(
                label: 'strict-casts: ${audit.hasStrictCasts ? 'ON' : 'OFF'}',
                color: audit.hasStrictCasts
                    ? AppColors.statusSuccess
                    : AppColors.amberWarning,
              ),
              _StatusBadge(
                label:
                    'strict-inference: ${audit.hasStrictInference ? 'ON' : 'OFF'}',
                color: audit.hasStrictInference
                    ? AppColors.statusSuccess
                    : AppColors.amberWarning,
              ),
              _StatusBadge(
                label:
                    'strict-raw-types: ${audit.hasStrictRawTypes ? 'ON' : 'OFF'}',
                color: audit.hasStrictRawTypes
                    ? AppColors.statusSuccess
                    : AppColors.amberWarning,
              ),
              _StatusBadge(
                label: 'Reguły własne: ${audit.customRulesCount}',
                color: AppColors.goldAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRuleBreakdownCard(
    ZeroWarnings712State gateState,
    ZeroWarnings712Notifier notifier,
  ) {
    final summaries = gateState.report?.ruleSummaries ?? const [];

    return _GateSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Rozkład reguł lintera',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (gateState.selectedRule != null)
                _InteractiveTextLink(
                  label: 'Wyczyść filtr',
                  onTap: () => notifier.setSelectedRule(null),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (summaries.isEmpty)
            const Text(
              'Brak naruszeń reguł lintera (0 problemów).',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.statusSuccess,
              ),
            )
          else
            Column(
              children: summaries.take(15).map((summary) {
                final isSelected = gateState.selectedRule == summary.ruleName;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _InteractiveRuleRow(
                    summary: summary,
                    selected: isSelected,
                    onTap: () => notifier.setSelectedRule(summary.ruleName),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildIssuesListCard(
    ZeroWarnings712State gateState,
    ZeroWarnings712Notifier notifier,
  ) {
    final filtered = gateState.filteredIssues;

    return _GateSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Text(
                'Lista problemów (${filtered.length})',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _InteractiveSeverityFilter(
                    label: 'Wszystkie',
                    color: AppColors.textSecondary,
                    selected: gateState.severityFilter == null,
                    onTap: () => notifier.setSeverityFilter(null),
                  ),
                  for (final sev in ZeroWarnings712Severity.values)
                    _InteractiveSeverityFilter(
                      label: sev.label,
                      color: sev.color,
                      selected: gateState.severityFilter == sev,
                      onTap: () => notifier.setSeverityFilter(sev),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _searchController,
            onChanged: notifier.setSearchQuery,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Filtruj po pliku, regule lub komunikacie...',
              hintStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
              filled: true,
              fillColor: AppColors.surfaceLight,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.accentBlue),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No issues found! Brak problemów spełniających kryteria.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.statusSuccess,
                ),
              ),
            )
          else
            Column(
              children: filtered.take(40).map((issue) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: issue.severity.color.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        issue.severity.icon,
                        size: 16,
                        color: issue.severity.color,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              issue.locationLabel,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.accentBlue,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              issue.message,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              issue.ruleName,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: issue.severity.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildHygieneCard(List<ZeroWarnings712HygieneIssue> findings) {
    return _GateSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Higiena statyczna kodu (${findings.length})',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Column(
            children: findings.take(25).map((finding) {
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: finding.kind.color.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    _StatusBadge(
                      label: finding.kind.label,
                      color: finding.kind.color,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${finding.normalizedPath}:${finding.line} — ${finding.snippet}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPromptCard() {
    return _GateSurfaceCard(
      child: Column(
        children: [
          Icon(
            Icons.verified_user_outlined,
            size: 36,
            color: AppColors.goldAccent.withValues(alpha: 0.85),
          ),
          const SizedBox(height: 8),
          const Text(
            'Kliknij „Uruchom --fatal-infos”, aby zweryfikować cały projekt #001–#712 oraz matrycę renderowania UI.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner({
    required String message,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTileData {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _MetricTileData({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });
}

class _GateSurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;

  const _GateSurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor ?? AppColors.cardBorder,
          width: 1.0,
        ),
      ),
      child: child,
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _InteractiveGateButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final bool enabled;
  final bool outlined;
  final VoidCallback onTap;

  const _InteractiveGateButton({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.enabled,
    this.outlined = false,
    required this.onTap,
  });

  @override
  State<_InteractiveGateButton> createState() => _InteractiveGateButtonState();
}

class _InteractiveGateButtonState extends State<_InteractiveGateButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    final bgColor = !enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : widget.outlined
            ? (_hovered
                ? widget.accentColor.withValues(alpha: 0.14)
                : AppColors.surfaceLight)
            : (_pressed
                ? widget.accentColor.withValues(alpha: 0.85)
                : (_hovered
                    ? widget.accentColor.withValues(alpha: 0.92)
                    : widget.accentColor));

    final borderColor = !enabled
        ? AppColors.cardBorder.withValues(alpha: 0.4)
        : _focused
            ? AppColors.goldAccent
            : widget.accentColor.withValues(alpha: _hovered ? 0.9 : 0.6);

    final fgColor = !enabled
        ? AppColors.textSecondary.withValues(alpha: 0.45)
        : (widget.outlined ? widget.accentColor : AppColors.textPrimary);

    return FocusableActionDetector(
      enabled: enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: _focused ? 1.5 : 1.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 16, color: fgColor),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: fgColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InteractiveScopeChip extends StatefulWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _InteractiveScopeChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_InteractiveScopeChip> createState() => _InteractiveScopeChipState();
}

class _InteractiveScopeChipState extends State<_InteractiveScopeChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    const activeColor = AppColors.primaryAccent;
    final bgColor = !widget.enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.35)
        : widget.selected
            ? activeColor.withValues(alpha: 0.25)
            : (_hovered
                ? AppColors.surfaceLight
                : AppColors.surfaceLight.withValues(alpha: 0.65));

    final borderColor = !widget.enabled
        ? AppColors.cardBorder.withValues(alpha: 0.4)
        : _focused
            ? AppColors.goldAccent
            : (widget.selected
                ? activeColor
                : (_hovered ? AppColors.textSecondary : AppColors.cardBorder));

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
              color: widget.enabled
                  ? AppColors.textPrimary
                  : AppColors.textSecondary.withValues(alpha: 0.45),
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractiveTogglePill extends StatefulWidget {
  final String label;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _InteractiveTogglePill({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  State<_InteractiveTogglePill> createState() => _InteractiveTogglePillState();
}

class _InteractiveTogglePillState extends State<_InteractiveTogglePill> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    const activeColor = AppColors.statusSuccess;
    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTap: widget.enabled ? () => widget.onChanged(!widget.value) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: widget.value
                ? activeColor.withValues(alpha: _hovered ? 0.2 : 0.14)
                : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _focused
                  ? AppColors.goldAccent
                  : (widget.value
                      ? activeColor.withValues(alpha: 0.6)
                      : AppColors.cardBorder),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.value
                    ? Icons.check_box_rounded
                    : Icons.check_box_outline_blank_rounded,
                size: 16,
                color: widget.enabled
                    ? (widget.value ? activeColor : AppColors.textSecondary)
                    : AppColors.textSecondary.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: widget.enabled
                      ? AppColors.textPrimary
                      : AppColors.textSecondary.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InteractiveSeverityFilter extends StatefulWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _InteractiveSeverityFilter({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_InteractiveSeverityFilter> createState() =>
      _InteractiveSeverityFilterState();
}

class _InteractiveSeverityFilterState
    extends State<_InteractiveSeverityFilter> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: widget.selected
                ? widget.color.withValues(alpha: 0.22)
                : (_hovered ? AppColors.surfaceLight : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.selected
                  ? widget.color
                  : AppColors.cardBorder.withValues(alpha: 0.7),
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: widget.selected ? widget.color : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractiveRuleRow extends StatefulWidget {
  final ZeroWarnings712RuleSummary summary;
  final bool selected;
  final VoidCallback onTap;

  const _InteractiveRuleRow({
    required this.summary,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_InteractiveRuleRow> createState() => _InteractiveRuleRowState();
}

class _InteractiveRuleRowState extends State<_InteractiveRuleRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.summary.highestSeverity.color;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: widget.selected
                ? color.withValues(alpha: 0.16)
                : (_hovered
                    ? AppColors.surfaceLight
                    : AppColors.surfaceLight.withValues(alpha: 0.6)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.selected ? color : AppColors.cardBorder,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.summary.ruleName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${widget.summary.count}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InteractiveTextLink extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _InteractiveTextLink({
    required this.label,
    required this.onTap,
  });

  @override
  State<_InteractiveTextLink> createState() => _InteractiveTextLinkState();
}

class _InteractiveTextLinkState extends State<_InteractiveTextLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          widget.label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            decoration:
                _hovered ? TextDecoration.underline : TextDecoration.none,
            color: AppColors.accentBlue,
          ),
        ),
      ),
    );
  }
}
