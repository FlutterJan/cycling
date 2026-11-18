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
enum ZeroWarnings612Severity {
  error('Błąd', AppColors.crimsonAlert, Icons.error_rounded),
  warning('Ostrzeżenie', AppColors.amberWarning, Icons.warning_amber_rounded),
  info('Info', AppColors.accentBlue, Icons.info_outline_rounded);

  final String label;
  final Color color;
  final IconData icon;

  const ZeroWarnings612Severity(this.label, this.color, this.icon);

  static ZeroWarnings612Severity fromToken(String token) {
    switch (token.trim().toLowerCase()) {
      case 'error':
        return ZeroWarnings612Severity.error;
      case 'warning':
        return ZeroWarnings612Severity.warning;
      case 'info':
      default:
        return ZeroWarnings612Severity.info;
    }
  }
}

/// Zakres ścieżek objętych bramką jakości #611 dla etapu Platinum Apex (#001–#612).
enum ZeroWarnings612Scope {
  entireWorkspace('Cały projekt (#001–#612)', <String>[]),
  libDirectory('Kod produkcyjny (lib/)', <String>['lib']),
  testDirectory('Testy automatyczne (test/)', <String>['test']),
  package8AndDiagnostics(
    'Paczka #8 & Diagnostyka',
    <String>[
      'lib/core/diagnostics',
      'lib/models/retro',
      'lib/models/esports',
      'lib/models/career',
    ],
  ),
  diagnosticsOnly('Tylko diagnostyka', <String>['lib/core/diagnostics']);

  final String label;
  final List<String> paths;

  const ZeroWarnings612Scope(this.label, this.paths);
}

/// Werdykt końcowy bramki jakości `flutter analyze --fatal-infos`.
enum ZeroWarnings612Verdict {
  idle(
    'OCZEKUJE NA WERYFIKACJĘ',
    'Uruchom bramkę jakości #611, aby potwierdzić zero błędów, ostrzeżeń i info.',
    AppColors.textSecondary,
    Icons.hourglass_empty_rounded,
  ),
  analyzing(
    'ANALIZA STATYCZNA W TOKU...',
    'Trwa wykonywanie flutter analyze --fatal-infos dla zakresu Platinum Apex.',
    AppColors.accentBlue,
    Icons.sync_rounded,
  ),
  passed(
    'BRAMKA #611 ZALICZONA (0 PROBLEMÓW)',
    'Kod spełnia rygor flutter analyze --fatal-infos bez błędów, ostrzeżeń ani info.',
    AppColors.statusSuccess,
    Icons.verified_rounded,
  ),
  blocked(
    'BRAMKA #611 ZABLOKOWANA',
    'Wykryto problemy lintera lub niezerowy kod wyjścia wymagający naprawy.',
    AppColors.crimsonAlert,
    Icons.gpp_bad_rounded,
  );

  final String title;
  final String description;
  final Color color;
  final IconData icon;

  const ZeroWarnings612Verdict(
    this.title,
    this.description,
    this.color,
    this.icon,
  );
}

/// Kategoria dodatkowej kontroli higieny produkcyjnej kodu.
enum ZeroWarnings612HygieneKind {
  todoOrFixme('Znacznik TODO/FIXME', AppColors.crimsonAlert),
  rawPrintCall('Wywołanie print()', AppColors.amberWarning),
  ignoreForFileDirective('Dyrektywa ignore_for_file', AppColors.accentBlue),
  emptyCatchBlock('Pusty blok catch', AppColors.amberWarning);

  final String label;
  final Color color;

  const ZeroWarnings612HygieneKind(this.label, this.color);
}

/// Pojedynczy problem wykryty przez `flutter analyze`.
@immutable
class ZeroWarnings612Issue {
  final ZeroWarnings612Severity severity;
  final String message;
  final String filePath;
  final int line;
  final int column;
  final String ruleName;
  final String rawLine;

  const ZeroWarnings612Issue({
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
class ZeroWarnings612HygieneIssue {
  final String filePath;
  final int line;
  final ZeroWarnings612HygieneKind kind;
  final String snippet;

  const ZeroWarnings612HygieneIssue({
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
class ZeroWarnings612RuleSummary {
  final String ruleName;
  final int count;
  final ZeroWarnings612Severity highestSeverity;
  final String sampleFile;

  const ZeroWarnings612RuleSummary({
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
class ZeroWarnings612OptionsAudit {
  final String? includeLine;
  final List<String> excludedPatterns;
  final bool hasStrictCasts;
  final bool hasStrictInference;
  final bool hasStrictRawTypes;
  final int customRulesCount;

  const ZeroWarnings612OptionsAudit({
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

/// Wynik wykonania procesu CLI `flutter analyze`.
@immutable
class ZeroWarnings612ProcessOutput {
  final int exitCode;
  final String stdout;
  final String stderr;
  final int durationMs;
  final String command;

  const ZeroWarnings612ProcessOutput({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    required this.durationMs,
    required this.command,
  });
}

/// Sygnatura funkcji uruchamiającej proces CLI (wstrzykiwalna w testach).
typedef ZeroWarnings612ProcessExecutor = Future<ZeroWarnings612ProcessOutput>
    Function(
  List<String> arguments,
  String workingDirectory,
);

/// Pełny raport bramki jakości #611 (`flutter analyze --fatal-infos`).
@immutable
class ZeroWarnings612LintReport {
  final DateTime executedAt;
  final ZeroWarnings612Scope scope;
  final List<String> targetPaths;
  final bool fatalInfosEnabled;
  final bool fatalWarningsEnabled;
  final int exitCode;
  final int durationMs;
  final String command;
  final List<ZeroWarnings612Issue> issues;
  final List<ZeroWarnings612HygieneIssue> hygieneIssues;
  final int scannedFilesCount;
  final ZeroWarnings612OptionsAudit optionsAudit;
  final String rawStderr;

  const ZeroWarnings612LintReport({
    required this.executedAt,
    required this.scope,
    required this.targetPaths,
    required this.fatalInfosEnabled,
    required this.fatalWarningsEnabled,
    required this.exitCode,
    required this.durationMs,
    required this.command,
    required this.issues,
    this.hygieneIssues = const <ZeroWarnings612HygieneIssue>[],
    this.scannedFilesCount = 0,
    this.optionsAudit = const ZeroWarnings612OptionsAudit(),
    this.rawStderr = '',
  });

  int get errorCount =>
      issues.where((i) => i.severity == ZeroWarnings612Severity.error).length;

  int get warningCount =>
      issues.where((i) => i.severity == ZeroWarnings612Severity.warning).length;

  int get infoCount =>
      issues.where((i) => i.severity == ZeroWarnings612Severity.info).length;

  int get totalIssuesCount => issues.length;

  int get filesWithIssuesCount =>
      issues.map((i) => i.normalizedPath).toSet().length;

  bool get isZeroWarningsPassed => exitCode == 0 && issues.isEmpty;

  ZeroWarnings612Verdict get verdict => isZeroWarningsPassed
      ? ZeroWarnings612Verdict.passed
      : ZeroWarnings612Verdict.blocked;

  /// Zestawienie reguł lintera posortowane malejąco po liczbie wystąpień.
  List<ZeroWarnings612RuleSummary> get ruleSummaries {
    final grouped = <String, List<ZeroWarnings612Issue>>{};
    for (final issue in issues) {
      grouped
          .putIfAbsent(issue.ruleName, () => <ZeroWarnings612Issue>[])
          .add(issue);
    }

    final summaries = grouped.entries.map((entry) {
      var highest = ZeroWarnings612Severity.info;
      for (final item in entry.value) {
        if (item.severity == ZeroWarnings612Severity.error) {
          highest = ZeroWarnings612Severity.error;
          break;
        }
        if (item.severity == ZeroWarnings612Severity.warning) {
          highest = ZeroWarnings612Severity.warning;
        }
      }
      return ZeroWarnings612RuleSummary(
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
        'taskId': 611,
        'milestone': 'Platinum Apex #001–#612',
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
        },
        'optionsAudit': optionsAudit.toJson(),
        'ruleSummaries': ruleSummaries.map((r) => r.toJson()).toList(),
        'issues': issues.map((i) => i.toJson()).toList(),
        'hygieneIssues': hygieneIssues.map((h) => h.toJson()).toList(),
      };

  String toMarkdownReport() {
    final buffer = StringBuffer()
      ..writeln('# Bramka Jakości #611 (`flutter analyze --fatal-infos`)')
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

/// Serwis wykonawczy bramki jakości `flutter analyze --fatal-infos` dla etapu #612.
class ZeroWarnings612LintGate {
  final String projectRootPath;
  final ZeroWarnings612ProcessExecutor _processExecutor;

  ZeroWarnings612LintGate({
    String? projectRootPath,
    ZeroWarnings612ProcessExecutor? processExecutor,
  })  : projectRootPath = projectRootPath ?? Directory.current.path,
        _processExecutor = processExecutor ?? _defaultProcessExecutor;

  static Future<ZeroWarnings612ProcessOutput> _defaultProcessExecutor(
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
    return ZeroWarnings612ProcessOutput(
      exitCode: result.exitCode,
      stdout: result.stdout?.toString() ?? '',
      stderr: result.stderr?.toString() ?? '',
      durationMs: stopwatch.elapsedMilliseconds,
      command: 'flutter ${arguments.join(' ')}',
    );
  }

  /// Parsuje wyjście tekstowe `flutter analyze` (format z `-` oraz `•`).
  static List<ZeroWarnings612Issue> parseFlutterAnalyzeOutput(String output) {
    final issues = <ZeroWarnings612Issue>[];
    final lines = const LineSplitter().convert(output);
    final issuePattern = RegExp(
      r'^\s*(error|warning|info)\s+[-•]\s+(.+?)\s+[-•]\s+(.+?):(\d+):(\d+)\s+[-•]\s+([a-zA-Z0-9_]+)\s*$',
    );

    for (final raw in lines) {
      final match = issuePattern.firstMatch(raw);
      if (match == null) continue;

      final severity = ZeroWarnings612Severity.fromToken(match.group(1) ?? '');
      final message = (match.group(2) ?? '').trim();
      final filePath = (match.group(3) ?? '').trim().replaceAll('\\', '/');
      final line = int.tryParse(match.group(4) ?? '0') ?? 0;
      final column = int.tryParse(match.group(5) ?? '0') ?? 0;
      final ruleName = (match.group(6) ?? 'unknown_rule').trim();

      issues.add(
        ZeroWarnings612Issue(
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

  /// Parsuje `analysis_options.yaml` w celu weryfikacji aktywnych zasad analizatora.
  static ZeroWarnings612OptionsAudit parseAnalysisOptions(String yamlContent) {
    final lines = const LineSplitter().convert(yamlContent);
    String? includeLine;
    final excluded = <String>[];
    var strictCasts = false;
    var strictInference = false;
    var strictRawTypes = false;
    var inExcludeBlock = false;
    var inRulesBlock = false;
    var customRulesCount = 0;

    for (final raw in lines) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) {
        continue;
      }

      if (trimmed.startsWith('include:')) {
        includeLine = trimmed.substring('include:'.length).trim();
        inExcludeBlock = false;
        inRulesBlock = false;
        continue;
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

      if (trimmed.startsWith('strict-casts:')) {
        strictCasts = trimmed.endsWith('true');
      } else if (trimmed.startsWith('strict-inference:')) {
        strictInference = trimmed.endsWith('true');
      } else if (trimmed.startsWith('strict-raw-types:')) {
        strictRawTypes = trimmed.endsWith('true');
      }

      if (inExcludeBlock) {
        if (trimmed.startsWith('- ')) {
          excluded.add(trimmed.substring(2).trim());
        } else if (!raw.startsWith(' ') && !raw.startsWith('\t')) {
          inExcludeBlock = false;
        }
      }

      if (inRulesBlock) {
        if (trimmed.startsWith('- ') || trimmed.contains(': true')) {
          customRulesCount++;
        } else if (!raw.startsWith(' ') && !raw.startsWith('\t')) {
          inRulesBlock = false;
        }
      }
    }

    return ZeroWarnings612OptionsAudit(
      includeLine: includeLine,
      excludedPatterns: excluded,
      hasStrictCasts: strictCasts,
      hasStrictInference: strictInference,
      hasStrictRawTypes: strictRawTypes,
      customRulesCount: customRulesCount,
    );
  }

  /// Skanuje pojedynczy plik `.dart` pod kątem higieny produkcyjnej.
  static List<ZeroWarnings612HygieneIssue> scanSourceHygiene(
    String filePath,
    String content,
  ) {
    final findings = <ZeroWarnings612HygieneIssue>[];
    final lines = const LineSplitter().convert(content);
    final todoRegex = RegExp(r'//\s*(TODO|FIXME)\b', caseSensitive: false);
    final rawPrintRegex = RegExp(r'(^|[^\w.])print\s*\(');
    final ignoreForFileRegex = RegExp(r'//\s*ignore_for_file:');
    final emptyCatchRegex = RegExp(r'catch\s*\([^)]*\)\s*\{\s*\}');

    for (var i = 0; i < lines.length; i++) {
      final lineNumber = i + 1;
      final line = lines[i];
      final trimmed = line.trim();

      if (todoRegex.hasMatch(line)) {
        findings.add(
          ZeroWarnings612HygieneIssue(
            filePath: filePath,
            line: lineNumber,
            kind: ZeroWarnings612HygieneKind.todoOrFixme,
            snippet: trimmed,
          ),
        );
      }

      if (!trimmed.startsWith('//') && rawPrintRegex.hasMatch(line)) {
        findings.add(
          ZeroWarnings612HygieneIssue(
            filePath: filePath,
            line: lineNumber,
            kind: ZeroWarnings612HygieneKind.rawPrintCall,
            snippet: trimmed,
          ),
        );
      }

      if (ignoreForFileRegex.hasMatch(line)) {
        findings.add(
          ZeroWarnings612HygieneIssue(
            filePath: filePath,
            line: lineNumber,
            kind: ZeroWarnings612HygieneKind.ignoreForFileDirective,
            snippet: trimmed,
          ),
        );
      }

      if (!trimmed.startsWith('//') && emptyCatchRegex.hasMatch(line)) {
        findings.add(
          ZeroWarnings612HygieneIssue(
            filePath: filePath,
            line: lineNumber,
            kind: ZeroWarnings612HygieneKind.emptyCatchBlock,
            snippet: trimmed,
          ),
        );
      }
    }

    return findings;
  }

  /// Uruchamia bramkę jakości `flutter analyze --fatal-infos`.
  Future<ZeroWarnings612LintReport> runGate({
    ZeroWarnings612Scope scope = ZeroWarnings612Scope.entireWorkspace,
    List<String>? customPaths,
    bool fatalInfos = true,
    bool fatalWarnings = true,
    bool includeHygieneScan = true,
  }) async {
    final targetPaths = customPaths != null && customPaths.isNotEmpty
        ? List<String>.from(customPaths)
        : scope.paths;

    final args = <String>[
      'analyze',
      if (fatalInfos) '--fatal-infos',
      if (fatalWarnings) '--fatal-warnings',
      ...targetPaths,
    ];

    final optionsAudit = _readAnalysisOptionsAudit();
    final execResult = await _processExecutor(args, projectRootPath);
    final combinedOutput = '${execResult.stdout}\n${execResult.stderr}';
    final parsedIssues = parseFlutterAnalyzeOutput(combinedOutput);

    final hygieneResults = includeHygieneScan
        ? await _scanDirectoryHygiene(targetPaths)
        : const _Hygiene612ScanAggregate(issues: [], filesCount: 0);

    return ZeroWarnings612LintReport(
      executedAt: DateTime.now(),
      scope: scope,
      targetPaths: targetPaths,
      fatalInfosEnabled: fatalInfos,
      fatalWarningsEnabled: fatalWarnings,
      exitCode: execResult.exitCode,
      durationMs: execResult.durationMs,
      command: execResult.command,
      issues: parsedIssues,
      hygieneIssues: hygieneResults.issues,
      scannedFilesCount: hygieneResults.filesCount,
      optionsAudit: optionsAudit,
      rawStderr: execResult.stderr.trim(),
    );
  }

  ZeroWarnings612OptionsAudit _readAnalysisOptionsAudit() {
    final file = File(
      '$projectRootPath${Platform.pathSeparator}analysis_options.yaml',
    );
    if (!file.existsSync()) {
      return const ZeroWarnings612OptionsAudit();
    }
    try {
      final content = file.readAsStringSync();
      return parseAnalysisOptions(content);
    } on IOException {
      return const ZeroWarnings612OptionsAudit();
    }
  }

  Future<_Hygiene612ScanAggregate> _scanDirectoryHygiene(
    List<String> targetPaths,
  ) async {
    final dirsToScan = targetPaths.isEmpty ? <String>['lib'] : targetPaths;
    final findings = <ZeroWarnings612HygieneIssue>[];
    var filesCount = 0;

    for (final relativeTarget in dirsToScan) {
      final normalized = relativeTarget.replaceAll('/', Platform.pathSeparator);
      final targetPath = '$projectRootPath${Platform.pathSeparator}$normalized';
      final entityType = FileSystemEntity.typeSync(targetPath);

      if (entityType == FileSystemEntityType.file &&
          targetPath.endsWith('.dart')) {
        filesCount++;
        final content = await File(targetPath).readAsString();
        findings.addAll(scanSourceHygiene(relativeTarget, content));
      } else if (entityType == FileSystemEntityType.directory) {
        final dir = Directory(targetPath);
        await for (final entity
            in dir.list(recursive: true, followLinks: false)) {
          if (entity is File && entity.path.endsWith('.dart')) {
            filesCount++;
            final rel = entity.path
                .replaceFirst(projectRootPath, '')
                .replaceFirst(RegExp(r'^[/\\]+'), '')
                .replaceAll('\\', '/');
            final content = await entity.readAsString();
            findings.addAll(scanSourceHygiene(rel, content));
          }
        }
      }
    }

    return _Hygiene612ScanAggregate(issues: findings, filesCount: filesCount);
  }
}

class _Hygiene612ScanAggregate {
  final List<ZeroWarnings612HygieneIssue> issues;
  final int filesCount;

  const _Hygiene612ScanAggregate({
    required this.issues,
    required this.filesCount,
  });
}

/// Stan kontrolera Riverpod dla bramki jakości #611.
@immutable
class ZeroWarnings612State {
  final bool isRunning;
  final ZeroWarnings612Scope scope;
  final bool fatalInfos;
  final bool fatalWarnings;
  final bool includeHygieneScan;
  final ZeroWarnings612Severity? severityFilter;
  final String? selectedRule;
  final String searchQuery;
  final ZeroWarnings612LintReport? report;
  final String? errorMessage;
  final String? lastActionFeedback;

  const ZeroWarnings612State({
    this.isRunning = false,
    this.scope = ZeroWarnings612Scope.entireWorkspace,
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

  ZeroWarnings612Verdict get currentVerdict {
    if (isRunning) return ZeroWarnings612Verdict.analyzing;
    if (report == null) return ZeroWarnings612Verdict.idle;
    return report!.verdict;
  }

  List<ZeroWarnings612Issue> get filteredIssues {
    final currentReport = report;
    if (currentReport == null) return const <ZeroWarnings612Issue>[];

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

  ZeroWarnings612State copyWith({
    bool? isRunning,
    ZeroWarnings612Scope? scope,
    bool? fatalInfos,
    bool? fatalWarnings,
    bool? includeHygieneScan,
    ZeroWarnings612Severity? severityFilter,
    bool clearSeverityFilter = false,
    String? selectedRule,
    bool clearSelectedRule = false,
    String? searchQuery,
    ZeroWarnings612LintReport? report,
    bool clearReport = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? lastActionFeedback,
    bool clearFeedback = false,
  }) {
    return ZeroWarnings612State(
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

/// Kontroler stanu bramki jakości #611.
class ZeroWarnings612Notifier extends StateNotifier<ZeroWarnings612State> {
  final ZeroWarnings612LintGate _gate;

  ZeroWarnings612Notifier(this._gate) : super(const ZeroWarnings612State());

  void setScope(ZeroWarnings612Scope scope) {
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

  void setSeverityFilter(ZeroWarnings612Severity? severity) {
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
            ? 'Bramka #611 zaliczona: 0 problemów (${report.durationMs} ms).'
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
    state = ZeroWarnings612State(
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

/// Provider serwisu bramki jakości #611.
final zeroWarnings612ServiceProvider = Provider<ZeroWarnings612LintGate>(
  (ref) => ZeroWarnings612LintGate(),
);

/// Provider stanu bramki jakości #611.
final zeroWarnings612GateProvider =
    StateNotifierProvider<ZeroWarnings612Notifier, ZeroWarnings612State>(
  (ref) => ZeroWarnings612Notifier(ref.watch(zeroWarnings612ServiceProvider)),
);

/// Produkcyjny panel UI bramki jakości `flutter analyze --fatal-infos` (#611).
class ZeroWarnings612LintGatePanel extends ConsumerStatefulWidget {
  final bool isReadOnly;

  const ZeroWarnings612LintGatePanel({
    super.key,
    this.isReadOnly = false,
  });

  @override
  ConsumerState<ZeroWarnings612LintGatePanel> createState() =>
      _ZeroWarnings612LintGatePanelState();
}

class _ZeroWarnings612LintGatePanelState
    extends ConsumerState<ZeroWarnings612LintGatePanel> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _copyToClipboard(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ref.read(zeroWarnings612GateProvider.notifier).notifyCopied(label);
  }

  @override
  Widget build(BuildContext context) {
    final gateState = ref.watch(zeroWarnings612GateProvider);
    final notifier = ref.read(zeroWarnings612GateProvider.notifier);

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
                _buildControlsCard(gateState, notifier, isMobile),
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
    ZeroWarnings612State gateState,
    ZeroWarnings612Notifier notifier,
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
                      'BRAMKA JAKOŚCI #611 — PLATINUM APEX',
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
    ZeroWarnings612State gateState,
    ZeroWarnings612Notifier notifier,
    bool isMobile,
  ) {
    final disabled = widget.isReadOnly || gateState.isRunning;

    return _GateSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Zakres analizy statycznej',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ZeroWarnings612Scope.values.map((scope) {
              return _InteractiveFilterChip(
                label: scope.label,
                selected: gateState.scope == scope,
                enabled: !disabled,
                accentColor: AppColors.primaryAccent,
                onTap: () => notifier.setScope(scope),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InteractiveFilterChip(
                label: gateState.fatalInfos
                    ? '✓ --fatal-infos'
                    : '--fatal-infos',
                selected: gateState.fatalInfos,
                enabled: !disabled,
                accentColor: AppColors.accentBlue,
                onTap: () => notifier.setFatalInfos(!gateState.fatalInfos),
              ),
              _InteractiveFilterChip(
                label: gateState.fatalWarnings
                    ? '✓ --fatal-warnings'
                    : '--fatal-warnings',
                selected: gateState.fatalWarnings,
                enabled: !disabled,
                accentColor: AppColors.amberWarning,
                onTap: () =>
                    notifier.setFatalWarnings(!gateState.fatalWarnings),
              ),
              _InteractiveFilterChip(
                label: gateState.includeHygieneScan
                    ? '✓ Skan higieny (TODO/print)'
                    : 'Skan higieny (TODO/print)',
                selected: gateState.includeHygieneScan,
                enabled: !disabled,
                accentColor: AppColors.statusSuccess,
                onTap: () => notifier
                    .setIncludeHygieneScan(!gateState.includeHygieneScan),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(
    ZeroWarnings612LintReport report, {
    required bool isMobile,
    required bool isTablet,
  }) {
    final metrics = [
      _MetricTileData(
        label: 'Błędy (Error)',
        value: '${report.errorCount}',
        color: report.errorCount == 0
            ? AppColors.statusSuccess
            : AppColors.crimsonAlert,
      ),
      _MetricTileData(
        label: 'Ostrzeżenia',
        value: '${report.warningCount}',
        color: report.warningCount == 0
            ? AppColors.statusSuccess
            : AppColors.amberWarning,
      ),
      _MetricTileData(
        label: 'Info',
        value: '${report.infoCount}',
        color: report.infoCount == 0
            ? AppColors.statusSuccess
            : AppColors.accentBlue,
      ),
      _MetricTileData(
        label: 'Czas / Pliki',
        value: '${report.durationMs} ms · ${report.scannedFilesCount}',
        color: AppColors.goldAccent,
      ),
    ];

    final columns = isMobile ? 2 : (isTablet ? 2 : 4);
    const spacing = 12.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: metrics.map((metric) {
            return SizedBox(
              width: itemWidth,
              child: _GateSurfaceCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metric.label,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      metric.value,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: metric.color,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildOptionsAuditCard(ZeroWarnings612OptionsAudit audit) {
    return _GateSurfaceCard(
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text(
            'analysis_options.yaml:',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          _StatusPill(
            label: audit.includeLine ?? 'Brak include',
            color: AppColors.accentBlue,
          ),
          _StatusPill(
            label: 'strict-casts: ${audit.hasStrictCasts ? "ON" : "OFF"}',
            color: audit.hasStrictCasts
                ? AppColors.statusSuccess
                : AppColors.textSecondary,
          ),
          _StatusPill(
            label:
                'strict-inference: ${audit.hasStrictInference ? "ON" : "OFF"}',
            color: audit.hasStrictInference
                ? AppColors.statusSuccess
                : AppColors.textSecondary,
          ),
          _StatusPill(
            label: 'Reguły własne: ${audit.customRulesCount}',
            color: AppColors.goldAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildRuleBreakdownCard(
    ZeroWarnings612State gateState,
    ZeroWarnings612Notifier notifier,
  ) {
    final summaries = gateState.report?.ruleSummaries ?? const [];

    return _GateSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reguły lintera',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          if (summaries.isEmpty)
            const Text(
              'Brak naruszeń reguł lintera.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.statusSuccess,
              ),
            )
          else
            Column(
              children: summaries.map((rule) {
                final selected = gateState.selectedRule == rule.ruleName;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _InteractiveFilterChip(
                    label: '${rule.ruleName} (${rule.count})',
                    selected: selected,
                    enabled: true,
                    accentColor: rule.highestSeverity.color,
                    fullWidth: true,
                    onTap: () => notifier.setSelectedRule(rule.ruleName),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildIssuesListCard(
    ZeroWarnings612State gateState,
    ZeroWarnings612Notifier notifier,
  ) {
    final filtered = gateState.filteredIssues;

    return _GateSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Problemy (${filtered.length})',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InteractiveFilterChip(
                label: 'Wszystkie',
                selected: gateState.severityFilter == null,
                enabled: true,
                accentColor: AppColors.textPrimary,
                onTap: () => notifier.setSeverityFilter(null),
              ),
              ...ZeroWarnings612Severity.values.map((sev) {
                return _InteractiveFilterChip(
                  label: sev.label,
                  selected: gateState.severityFilter == sev,
                  enabled: true,
                  accentColor: sev.color,
                  onTap: () => notifier.setSeverityFilter(sev),
                );
              }),
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
                fontSize: 13,
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
                'Zero problemów dla wybranych filtrów.',
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
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: issue.severity.color.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            issue.severity.icon,
                            size: 16,
                            color: issue.severity.color,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              issue.ruleName,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: issue.severity.color,
                              ),
                            ),
                          ),
                          Text(
                            'L${issue.line}:${issue.column}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        issue.normalizedPath,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        issue.message,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: AppColors.textPrimary,
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

  Widget _buildHygieneCard(List<ZeroWarnings612HygieneIssue> findings) {
    return _GateSurfaceCard(
      borderColor: AppColors.amberWarning.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Uwagi higieny statycznej (${findings.length})',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.amberWarning,
            ),
          ),
          const SizedBox(height: 10),
          ...findings.take(25).map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '[${item.kind.label}] ${item.normalizedPath}:${item.line} — ${item.snippet}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildEmptyPromptCard() {
    return const _GateSurfaceCard(
      child: Row(
        children: [
          Icon(
            Icons.shield_outlined,
            color: AppColors.goldAccent,
            size: 22,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Kliknij „Uruchom --fatal-infos”, aby zweryfikować czystość całego projektu przed finalną certyfikacją Platinum Apex (#612).',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
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
          Icon(icon, color: color, size: 18),
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
}

class _MetricTileData {
  final String label;
  final String value;
  final Color color;

  const _MetricTileData({
    required this.label,
    required this.value,
    required this.color,
  });
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({
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

class _GateSurfaceCard extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  final EdgeInsetsGeometry padding;

  const _GateSurfaceCard({
    required this.child,
    this.borderColor,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
    required this.onTap,
    this.outlined = false,
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
    final effectiveEnabled = widget.enabled;
    final bgColor = !effectiveEnabled
        ? AppColors.surfaceLight.withValues(alpha: 0.45)
        : widget.outlined
            ? (_pressed
                ? widget.accentColor.withValues(alpha: 0.22)
                : _hovered
                    ? widget.accentColor.withValues(alpha: 0.14)
                    : AppColors.surfaceLight)
            : (_pressed
                ? widget.accentColor.withValues(alpha: 0.85)
                : _hovered
                    ? widget.accentColor.withValues(alpha: 0.92)
                    : widget.accentColor);

    final borderColor = !effectiveEnabled
        ? AppColors.cardBorder.withValues(alpha: 0.45)
        : _focused
            ? AppColors.goldAccent
            : widget.outlined
                ? widget.accentColor.withValues(alpha: _hovered ? 0.85 : 0.45)
                : widget.accentColor;

    final fgColor = !effectiveEnabled
        ? AppColors.textSecondary.withValues(alpha: 0.5)
        : AppColors.textPrimary;

    return FocusableActionDetector(
      enabled: effectiveEnabled,
      onShowFocusHighlight: (focused) => setState(() => _focused = focused),
      onShowHoverHighlight: (hovered) => setState(() => _hovered = hovered),
      mouseCursor: effectiveEnabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTapDown: effectiveEnabled
            ? (_) => setState(() => _pressed = true)
            : null,
        onTapUp: effectiveEnabled
            ? (_) => setState(() => _pressed = false)
            : null,
        onTapCancel:
            effectiveEnabled ? () => setState(() => _pressed = false) : null,
        onTap: effectiveEnabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: _focused ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 17, color: fgColor),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
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

class _InteractiveFilterChip extends StatefulWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final Color accentColor;
  final bool fullWidth;
  final VoidCallback onTap;

  const _InteractiveFilterChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.accentColor,
    required this.onTap,
    this.fullWidth = false,
  });

  @override
  State<_InteractiveFilterChip> createState() => _InteractiveFilterChipState();
}

class _InteractiveFilterChipState extends State<_InteractiveFilterChip> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = !widget.enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : widget.selected
            ? widget.accentColor.withValues(alpha: _pressed ? 0.3 : 0.22)
            : _hovered
                ? AppColors.surfaceLight
                : AppColors.background;

    final borderColor = !widget.enabled
        ? AppColors.cardBorder.withValues(alpha: 0.4)
        : _focused
            ? AppColors.goldAccent
            : widget.selected
                ? widget.accentColor
                : (_hovered
                    ? AppColors.textSecondary.withValues(alpha: 0.5)
                    : AppColors.cardBorder);

    final textColor = !widget.enabled
        ? AppColors.textSecondary.withValues(alpha: 0.5)
        : widget.selected
            ? AppColors.textPrimary
            : AppColors.textSecondary;

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowFocusHighlight: (focused) => setState(() => _focused = focused),
      onShowHoverHighlight: (hovered) => setState(() => _hovered = hovered),
      mouseCursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTapDown:
            widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp:
            widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel:
            widget.enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: widget.fullWidth ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: borderColor,
              width: _focused ? 1.5 : 1.0,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
