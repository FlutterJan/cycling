// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';

/// Poziom ważności problemu zgłoszonego przez `flutter analyze`.
enum LintIssueSeverity {
  error('Błąd', AppColors.crimsonAlert, Icons.error_rounded),
  warning('Ostrzeżenie', AppColors.amberWarning, Icons.warning_amber_rounded),
  info('Info', AppColors.accentBlue, Icons.info_outline_rounded);

  final String label;
  final Color color;
  final IconData icon;

  const LintIssueSeverity(this.label, this.color, this.icon);

  static LintIssueSeverity fromToken(String token) {
    switch (token.trim().toLowerCase()) {
      case 'error':
        return LintIssueSeverity.error;
      case 'warning':
        return LintIssueSeverity.warning;
      case 'info':
      default:
        return LintIssueSeverity.info;
    }
  }
}

/// Zakres ścieżek objętych bramką `flutter analyze --fatal-infos`.
enum LintGateScope {
  entireProject('Cały projekt', <String>[]),
  libOnly('Tylko lib/', <String>['lib']),
  testOnly('Tylko test/', <String>['test']),
  coreDiagnostics('Diagnostyka', <String>['lib/core/diagnostics']);

  final String label;
  final List<String> paths;

  const LintGateScope(this.label, this.paths);
}

/// Werdykt końcowy bramki jakości `flutter analyze --fatal-infos`.
enum LintGateVerdict {
  notRun(
    'OCZEKUJE NA URUCHOMIENIE',
    'Uruchom bramkę jakości, aby zweryfikować zero błędów, ostrzeżeń i info.',
    AppColors.textSecondary,
    Icons.hourglass_empty_rounded,
  ),
  running(
    'ANALIZA W TOKU...',
    'Trwa skanowanie statyczne drzewa Dart/Flutter z flagą --fatal-infos.',
    AppColors.accentBlue,
    Icons.sync_rounded,
  ),
  passed(
    'BRAMKA ZALICZONA (0 PROBLEMÓW)',
    'Kod spełnia rygor flutter analyze --fatal-infos bez błędów, ostrzeżeń ani info.',
    AppColors.statusSuccess,
    Icons.verified_rounded,
  ),
  failedWithIssues(
    'BRAMKA ZABLOKOWANA',
    'Wykryto problemy lintera lub niezerowy kod wyjścia wymagający naprawy.',
    AppColors.crimsonAlert,
    Icons.gpp_bad_rounded,
  );

  final String title;
  final String description;
  final Color color;
  final IconData icon;

  const LintGateVerdict(
    this.title,
    this.description,
    this.color,
    this.icon,
  );
}

/// Kategoria dodatkowej higieny statycznej kodu źródłowego.
enum StaticHygieneCategory {
  todoMarker('Znacznik TODO/FIXME', AppColors.crimsonAlert),
  rawPrint('Wywołanie print()', AppColors.amberWarning),
  ignoreForFile('Dyrektywa ignore_for_file', AppColors.accentBlue),
  emptyCatch('Pusty blok catch', AppColors.amberWarning);

  final String label;
  final Color color;

  const StaticHygieneCategory(this.label, this.color);
}

/// Pojedynczy problem wykryty przez `flutter analyze`.
@immutable
class LintAnalyzeIssue {
  final LintIssueSeverity severity;
  final String message;
  final String filePath;
  final int line;
  final int column;
  final String ruleName;
  final String rawLine;

  const LintAnalyzeIssue({
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

  LintAnalyzeIssue copyWith({
    LintIssueSeverity? severity,
    String? message,
    String? filePath,
    int? line,
    int? column,
    String? ruleName,
    String? rawLine,
  }) {
    return LintAnalyzeIssue(
      severity: severity ?? this.severity,
      message: message ?? this.message,
      filePath: filePath ?? this.filePath,
      line: line ?? this.line,
      column: column ?? this.column,
      ruleName: ruleName ?? this.ruleName,
      rawLine: rawLine ?? this.rawLine,
    );
  }

  Map<String, dynamic> toJson() => {
        'severity': severity.name,
        'message': message,
        'filePath': normalizedPath,
        'line': line,
        'column': column,
        'ruleName': ruleName,
      };

  factory LintAnalyzeIssue.fromJson(Map<String, dynamic> json) {
    return LintAnalyzeIssue(
      severity: LintIssueSeverity.fromToken(
        json['severity']?.toString() ?? 'info',
      ),
      message: json['message']?.toString() ?? '',
      filePath: json['filePath']?.toString() ?? '',
      line: (json['line'] as num?)?.toInt() ?? 0,
      column: (json['column'] as num?)?.toInt() ?? 0,
      ruleName: json['ruleName']?.toString() ?? 'unknown_rule',
      rawLine: json['rawLine']?.toString() ?? '',
    );
  }
}

/// Znalezisko dodatkowej kontroli higieny kodu.
@immutable
class StaticHygieneFinding {
  final String filePath;
  final int line;
  final StaticHygieneCategory category;
  final String snippet;

  const StaticHygieneFinding({
    required this.filePath,
    required this.line,
    required this.category,
    required this.snippet,
  });

  String get normalizedPath => filePath.replaceAll('\\', '/');

  Map<String, dynamic> toJson() => {
        'filePath': normalizedPath,
        'line': line,
        'category': category.name,
        'snippet': snippet,
      };
}

/// Zbiorcze podsumowanie reguły lintera w raporcie.
@immutable
class LintRuleBreakdown {
  final String ruleName;
  final int count;
  final LintIssueSeverity highestSeverity;
  final String sampleFile;

  const LintRuleBreakdown({
    required this.ruleName,
    required this.count,
    required this.highestSeverity,
    required this.sampleFile,
  });

  Map<String, dynamic> toJson() => {
        'ruleName': ruleName,
        'count': count,
        'highestSeverity': highestSeverity.name,
        'sampleFile': sampleFile,
      };
}

/// Podsumowanie konfiguracji pliku `analysis_options.yaml`.
@immutable
class AnalysisOptionsSummary {
  final String? includeLine;
  final List<String> excludedPatterns;
  final bool hasStrictCasts;
  final bool hasStrictInference;
  final bool hasStrictRawTypes;
  final int customRulesCount;

  const AnalysisOptionsSummary({
    this.includeLine,
    this.excludedPatterns = const <String>[],
    this.hasStrictCasts = false,
    this.hasStrictInference = false,
    this.hasStrictRawTypes = false,
    this.customRulesCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'includeLine': includeLine,
        'excludedPatterns': excludedPatterns,
        'hasStrictCasts': hasStrictCasts,
        'hasStrictInference': hasStrictInference,
        'hasStrictRawTypes': hasStrictRawTypes,
        'customRulesCount': customRulesCount,
      };
}

/// Wynik wywołania procesu CLI `flutter analyze`.
@immutable
class LintCommandExecutionResult {
  final int exitCode;
  final String stdout;
  final String stderr;
  final int durationMs;
  final String command;

  const LintCommandExecutionResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    required this.durationMs,
    required this.command,
  });
}

/// Sygnatura funkcji uruchamiającej proces CLI (wstrzykiwalna w testach).
typedef LintProcessRunner = Future<LintCommandExecutionResult> Function(
  List<String> arguments,
  String workingDirectory,
);

/// Pełny raport bramki jakości `flutter analyze --fatal-infos`.
@immutable
class FinalLintGateReport {
  final DateTime executedAt;
  final LintGateScope scope;
  final List<String> targetPaths;
  final bool fatalInfosEnabled;
  final bool fatalWarningsEnabled;
  final int exitCode;
  final int durationMs;
  final String command;
  final List<LintAnalyzeIssue> issues;
  final List<StaticHygieneFinding> hygieneFindings;
  final int scannedFilesCount;
  final AnalysisOptionsSummary analysisOptionsSummary;
  final String rawStderr;

  const FinalLintGateReport({
    required this.executedAt,
    required this.scope,
    required this.targetPaths,
    required this.fatalInfosEnabled,
    required this.fatalWarningsEnabled,
    required this.exitCode,
    required this.durationMs,
    required this.command,
    required this.issues,
    this.hygieneFindings = const <StaticHygieneFinding>[],
    this.scannedFilesCount = 0,
    this.analysisOptionsSummary = const AnalysisOptionsSummary(),
    this.rawStderr = '',
  });

  int get errorCount =>
      issues.where((i) => i.severity == LintIssueSeverity.error).length;

  int get warningCount =>
      issues.where((i) => i.severity == LintIssueSeverity.warning).length;

  int get infoCount =>
      issues.where((i) => i.severity == LintIssueSeverity.info).length;

  int get totalIssuesCount => issues.length;

  int get filesWithIssuesCount =>
      issues.map((i) => i.normalizedPath).toSet().length;

  bool get isZeroWarningsPassed => exitCode == 0 && issues.isEmpty;

  LintGateVerdict get verdict => isZeroWarningsPassed
      ? LintGateVerdict.passed
      : LintGateVerdict.failedWithIssues;

  /// Zestawienie najczęstszych reguł posortowane malejąco po liczbie wystąpień.
  List<LintRuleBreakdown> get ruleBreakdown {
    final grouped = <String, List<LintAnalyzeIssue>>{};
    for (final issue in issues) {
      grouped.putIfAbsent(issue.ruleName, () => <LintAnalyzeIssue>[]).add(issue);
    }

    final list = grouped.entries.map((entry) {
      var highest = LintIssueSeverity.info;
      for (final item in entry.value) {
        if (item.severity == LintIssueSeverity.error) {
          highest = LintIssueSeverity.error;
          break;
        }
        if (item.severity == LintIssueSeverity.warning) {
          highest = LintIssueSeverity.warning;
        }
      }
      return LintRuleBreakdown(
        ruleName: entry.key,
        count: entry.value.length,
        highestSeverity: highest,
        sampleFile: entry.value.first.normalizedPath,
      );
    }).toList();

    list.sort((a, b) {
      final countCmp = b.count.compareTo(a.count);
      if (countCmp != 0) return countCmp;
      return a.ruleName.compareTo(b.ruleName);
    });
    return list;
  }

  Map<String, dynamic> toJson() => {
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
        'summary': {
          'errors': errorCount,
          'warnings': warningCount,
          'infos': infoCount,
          'totalIssues': totalIssuesCount,
          'filesWithIssues': filesWithIssuesCount,
          'scannedFilesCount': scannedFilesCount,
          'hygieneFindings': hygieneFindings.length,
        },
        'analysisOptions': analysisOptionsSummary.toJson(),
        'ruleBreakdown': ruleBreakdown.map((r) => r.toJson()).toList(),
        'issues': issues.map((i) => i.toJson()).toList(),
        'hygieneFindings': hygieneFindings.map((h) => h.toJson()).toList(),
      };

  String toMarkdownSummary() {
    final buffer = StringBuffer()
      ..writeln('# Raport Bramki Jakości (`flutter analyze --fatal-infos`)')
      ..writeln()
      ..writeln('- **Werdykt:** ${verdict.title}')
      ..writeln('- **Komenda:** `$command`')
      ..writeln('- **Kod wyjścia:** `$exitCode` (${durationMs}ms)')
      ..writeln(
        '- **Problemy:** $totalIssuesCount (Błędy: $errorCount, Ostrzeżenia: $warningCount, Info: $infoCount)',
      )
      ..writeln('- **Pliki z problemami:** $filesWithIssuesCount')
      ..writeln('- **Higiena statyczna:** ${hygieneFindings.length} uwag');

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

/// Serwis wykonawczy bramki jakości `flutter analyze --fatal-infos`.
class FinalLintAndZeroWarningsGate {
  final String projectRootPath;
  final LintProcessRunner _processRunner;

  FinalLintAndZeroWarningsGate({
    String? projectRootPath,
    LintProcessRunner? processRunner,
  })  : projectRootPath = projectRootPath ?? Directory.current.path,
        _processRunner = processRunner ?? _defaultProcessRunner;

  static Future<LintCommandExecutionResult> _defaultProcessRunner(
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
    return LintCommandExecutionResult(
      exitCode: result.exitCode,
      stdout: result.stdout?.toString() ?? '',
      stderr: result.stderr?.toString() ?? '',
      durationMs: stopwatch.elapsedMilliseconds,
      command: 'flutter ${arguments.join(' ')}',
    );
  }

  /// Parsuje wyjście tekstowe `flutter analyze` (format z `-` oraz `•`).
  static List<LintAnalyzeIssue> parseFlutterAnalyzeOutput(String output) {
    final issues = <LintAnalyzeIssue>[];
    final lines = const LineSplitter().convert(output);
    final issuePattern = RegExp(
      r'^\s*(error|warning|info)\s+[-•]\s+(.+?)\s+[-•]\s+(.+?):(\d+):(\d+)\s+[-•]\s+([a-zA-Z0-9_]+)\s*$',
    );

    for (final raw in lines) {
      final match = issuePattern.firstMatch(raw);
      if (match == null) continue;

      final severity = LintIssueSeverity.fromToken(match.group(1) ?? 'info');
      final message = (match.group(2) ?? '').trim();
      final filePath = (match.group(3) ?? '').trim().replaceAll('\\', '/');
      final line = int.tryParse(match.group(4) ?? '0') ?? 0;
      final column = int.tryParse(match.group(5) ?? '0') ?? 0;
      final ruleName = (match.group(6) ?? 'unknown_rule').trim();

      issues.add(
        LintAnalyzeIssue(
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

  /// Parsuje `analysis_options.yaml` w celu weryfikacji aktywnej konfiguracji lintera.
  static AnalysisOptionsSummary parseAnalysisOptions(String yamlContent) {
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

    return AnalysisOptionsSummary(
      includeLine: includeLine,
      excludedPatterns: excluded,
      hasStrictCasts: strictCasts,
      hasStrictInference: strictInference,
      hasStrictRawTypes: strictRawTypes,
      customRulesCount: customRulesCount,
    );
  }

  /// Skanuje pojedynczy plik `.dart` pod kątem higieny produkcyjnej.
  static List<StaticHygieneFinding> scanSourceHygiene(
    String filePath,
    String content,
  ) {
    final findings = <StaticHygieneFinding>[];
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
          StaticHygieneFinding(
            filePath: filePath,
            line: lineNumber,
            category: StaticHygieneCategory.todoMarker,
            snippet: trimmed,
          ),
        );
      }

      if (!trimmed.startsWith('//') && rawPrintRegex.hasMatch(line)) {
        findings.add(
          StaticHygieneFinding(
            filePath: filePath,
            line: lineNumber,
            category: StaticHygieneCategory.rawPrint,
            snippet: trimmed,
          ),
        );
      }

      if (ignoreForFileRegex.hasMatch(line)) {
        findings.add(
          StaticHygieneFinding(
            filePath: filePath,
            line: lineNumber,
            category: StaticHygieneCategory.ignoreForFile,
            snippet: trimmed,
          ),
        );
      }

      if (!trimmed.startsWith('//') && emptyCatchRegex.hasMatch(line)) {
        findings.add(
          StaticHygieneFinding(
            filePath: filePath,
            line: lineNumber,
            category: StaticHygieneCategory.emptyCatch,
            snippet: trimmed,
          ),
        );
      }
    }

    return findings;
  }

  /// Uruchamia pełną bramkę jakości `flutter analyze --fatal-infos`.
  Future<FinalLintGateReport> runGate({
    LintGateScope scope = LintGateScope.entireProject,
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

    final analysisOptions = _readAnalysisOptionsSummary();
    final execResult = await _processRunner(args, projectRootPath);
    final combinedOutput = '${execResult.stdout}\n${execResult.stderr}';
    final parsedIssues = parseFlutterAnalyzeOutput(combinedOutput);

    final hygieneResults = includeHygieneScan
        ? await _scanDirectoryHygiene(targetPaths)
        : const _HygieneScanAggregate(findings: [], filesCount: 0);

    return FinalLintGateReport(
      executedAt: DateTime.now(),
      scope: scope,
      targetPaths: targetPaths,
      fatalInfosEnabled: fatalInfos,
      fatalWarningsEnabled: fatalWarnings,
      exitCode: execResult.exitCode,
      durationMs: execResult.durationMs,
      command: execResult.command,
      issues: parsedIssues,
      hygieneFindings: hygieneResults.findings,
      scannedFilesCount: hygieneResults.filesCount,
      analysisOptionsSummary: analysisOptions,
      rawStderr: execResult.stderr.trim(),
    );
  }

  AnalysisOptionsSummary _readAnalysisOptionsSummary() {
    final file = File('$projectRootPath${Platform.pathSeparator}analysis_options.yaml');
    if (!file.existsSync()) {
      return const AnalysisOptionsSummary();
    }
    try {
      final content = file.readAsStringSync();
      return parseAnalysisOptions(content);
    } on IOException {
      return const AnalysisOptionsSummary();
    }
  }

  Future<_HygieneScanAggregate> _scanDirectoryHygiene(
    List<String> targetPaths,
  ) async {
    final dirsToScan = targetPaths.isEmpty ? <String>['lib'] : targetPaths;
    final findings = <StaticHygieneFinding>[];
    var filesCount = 0;

    for (final relativeTarget in dirsToScan) {
      final normalized = relativeTarget.replaceAll('/', Platform.pathSeparator);
      final targetPath = '$projectRootPath${Platform.pathSeparator}$normalized';
      final entityType = FileSystemEntity.typeSync(targetPath);

      if (entityType == FileSystemEntityType.file && targetPath.endsWith('.dart')) {
        filesCount++;
        final content = await File(targetPath).readAsString();
        findings.addAll(scanSourceHygiene(relativeTarget, content));
      } else if (entityType == FileSystemEntityType.directory) {
        final dir = Directory(targetPath);
        await for (final entity in dir.list(recursive: true, followLinks: false)) {
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

    return _HygieneScanAggregate(findings: findings, filesCount: filesCount);
  }
}

class _HygieneScanAggregate {
  final List<StaticHygieneFinding> findings;
  final int filesCount;

  const _HygieneScanAggregate({
    required this.findings,
    required this.filesCount,
  });
}

/// Stan kontrolera Riverpod dla bramki jakości `flutter analyze --fatal-infos`.
@immutable
class FinalLintGateState {
  final bool isRunning;
  final LintGateScope scope;
  final bool fatalInfos;
  final bool fatalWarnings;
  final bool includeHygieneScan;
  final LintIssueSeverity? severityFilter;
  final String? selectedRule;
  final String searchQuery;
  final FinalLintGateReport? report;
  final String? errorMessage;
  final String? lastActionFeedback;

  const FinalLintGateState({
    this.isRunning = false,
    this.scope = LintGateScope.entireProject,
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

  LintGateVerdict get currentVerdict {
    if (isRunning) return LintGateVerdict.running;
    if (report == null) return LintGateVerdict.notRun;
    return report!.verdict;
  }

  List<LintAnalyzeIssue> get filteredIssues {
    final currentReport = report;
    if (currentReport == null) return const <LintAnalyzeIssue>[];

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

  FinalLintGateState copyWith({
    bool? isRunning,
    LintGateScope? scope,
    bool? fatalInfos,
    bool? fatalWarnings,
    bool? includeHygieneScan,
    LintIssueSeverity? severityFilter,
    bool clearSeverityFilter = false,
    String? selectedRule,
    bool clearSelectedRule = false,
    String? searchQuery,
    FinalLintGateReport? report,
    bool clearReport = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? lastActionFeedback,
    bool clearFeedback = false,
  }) {
    return FinalLintGateState(
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

/// Notifier zarządzający uruchomieniem i filtrowaniem wyników bramki lintera.
class FinalLintAndZeroWarningsGateNotifier
    extends StateNotifier<FinalLintGateState> {
  final FinalLintAndZeroWarningsGate _gate;

  FinalLintAndZeroWarningsGateNotifier(this._gate)
      : super(const FinalLintGateState());

  Future<void> runGate() async {
    if (state.isRunning) return;
    state = state.copyWith(
      isRunning: true,
      clearErrorMessage: true,
      clearFeedback: true,
    );

    try {
      final result = await _gate.runGate(
        scope: state.scope,
        fatalInfos: state.fatalInfos,
        fatalWarnings: state.fatalWarnings,
        includeHygieneScan: state.includeHygieneScan,
      );
      state = state.copyWith(
        isRunning: false,
        report: result,
        lastActionFeedback: result.isZeroWarningsPassed
            ? 'Bramka zaliczona: 0 błędów, 0 ostrzeżeń, 0 info.'
            : 'Wykryto ${result.totalIssuesCount} problemów lintera.',
      );
    } catch (e) {
      state = state.copyWith(
        isRunning: false,
        errorMessage: 'Nie udało się uruchomić bramki lintera: $e',
      );
    }
  }

  void setScope(LintGateScope scope) {
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

  void setSeverityFilter(LintIssueSeverity? severity) {
    if (severity == null || severity == state.severityFilter) {
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

  void loadReport(FinalLintGateReport report) {
    state = state.copyWith(
      isRunning: false,
      report: report,
      clearErrorMessage: true,
      clearSeverityFilter: true,
      clearSelectedRule: true,
    );
  }

  void reset() {
    state = const FinalLintGateState();
  }
}

final finalLintGateServiceProvider = Provider<FinalLintAndZeroWarningsGate>(
  (ref) => FinalLintAndZeroWarningsGate(),
);

final finalLintGateProvider = StateNotifierProvider<
    FinalLintAndZeroWarningsGateNotifier, FinalLintGateState>(
  (ref) => FinalLintAndZeroWarningsGateNotifier(
    ref.watch(finalLintGateServiceProvider),
  ),
);

/// Produkcyjny panel diagnostyczny bramki jakości `flutter analyze --fatal-infos`.
class FinalLintAndZeroWarningsGatePanel extends ConsumerStatefulWidget {
  final bool isReadOnly;
  final ValueChanged<FinalLintGateReport>? onExportReport;

  const FinalLintAndZeroWarningsGatePanel({
    super.key,
    this.isReadOnly = false,
    this.onExportReport,
  });

  @override
  ConsumerState<FinalLintAndZeroWarningsGatePanel> createState() =>
      _FinalLintAndZeroWarningsGatePanelState();
}

class _FinalLintAndZeroWarningsGatePanelState
    extends ConsumerState<FinalLintAndZeroWarningsGatePanel> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _copyReportToClipboard(
    FinalLintGateReport report, {
    required bool asJson,
  }) async {
    final text = asJson
        ? const JsonEncoder.withIndent('  ').convert(report.toJson())
        : report.toMarkdownSummary();
    await Clipboard.setData(ClipboardData(text: text));
    widget.onExportReport?.call(report);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceLight,
        content: Text(
          asJson
              ? 'Skopiowano raport JSON bramki lintera.'
              : 'Skopiowano raport Markdown bramki lintera.',
          style: const TextStyle(
            fontFamily: 'Inter',
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(finalLintGateProvider);
    final notifier = ref.read(finalLintGateProvider.notifier);

    return Container(
      color: AppColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 680;
          final isDesktop = constraints.maxWidth >= 1180;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 12 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderCard(state, notifier, isMobile),
                const SizedBox(height: 16),
                _buildControlsCard(state, notifier, isMobile),
                const SizedBox(height: 16),
                if (state.errorMessage != null) ...[
                  _buildErrorBanner(state.errorMessage!),
                  const SizedBox(height: 16),
                ],
                _buildKpiRow(state, isMobile),
                const SizedBox(height: 16),
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 4,
                        child: _buildRuleBreakdownCard(state, notifier),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 7,
                        child: _buildIssuesCard(state, notifier, isMobile),
                      ),
                    ],
                  )
                else ...[
                  _buildRuleBreakdownCard(state, notifier),
                  const SizedBox(height: 16),
                  _buildIssuesCard(state, notifier, isMobile),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(
    FinalLintGateState state,
    FinalLintAndZeroWarningsGateNotifier notifier,
    bool isMobile,
  ) {
    final verdict = state.currentVerdict;
    final report = state.report;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.all(isMobile ? 14 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: report != null
              ? verdict.color.withValues(alpha: 0.45)
              : AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: verdict.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: verdict.color.withValues(alpha: 0.4),
                  ),
                ),
                child: Icon(verdict.icon, color: verdict.color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'BRAMKA JAKOŚCI #561 · FLUTTER ANALYZE',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: AppColors.goldAccent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      verdict.title,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: isMobile ? 16 : 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: verdict.color,
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
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _LintActionButton(
                label: state.isRunning
                    ? 'Analizowanie...'
                    : 'Uruchom --fatal-infos',
                icon: state.isRunning
                    ? Icons.hourglass_top_rounded
                    : Icons.play_arrow_rounded,
                accentColor: AppColors.primaryAccent,
                isPrimary: true,
                disabled: widget.isReadOnly || state.isRunning,
                onTap: notifier.runGate,
              ),
              _LintActionButton(
                label: 'Kopiuj JSON',
                icon: Icons.data_object_rounded,
                accentColor: AppColors.accentBlue,
                disabled: report == null,
                onTap: report == null
                    ? null
                    : () => _copyReportToClipboard(report, asJson: true),
              ),
              _LintActionButton(
                label: 'Kopiuj Markdown',
                icon: Icons.description_outlined,
                accentColor: AppColors.goldAccent,
                disabled: report == null,
                onTap: report == null
                    ? null
                    : () => _copyReportToClipboard(report, asJson: false),
              ),
              _LintActionButton(
                label: 'Resetuj',
                icon: Icons.refresh_rounded,
                accentColor: AppColors.textSecondary,
                disabled: widget.isReadOnly || state.isRunning || report == null,
                onTap: notifier.reset,
              ),
            ],
          ),
          if (state.lastActionFeedback != null) ...[
            const SizedBox(height: 12),
            Text(
              state.lastActionFeedback!,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildControlsCard(
    FinalLintGateState state,
    FinalLintAndZeroWarningsGateNotifier notifier,
    bool isMobile,
  ) {
    final disabled = widget.isReadOnly || state.isRunning;

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Zakres i parametry analizy',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: LintGateScope.values.map((scope) {
              return _LintSelectableChip(
                label: scope.label,
                selected: state.scope == scope,
                disabled: disabled,
                accentColor: AppColors.goldAccent,
                onTap: () => notifier.setScope(scope),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _LintTogglePill(
                label: '--fatal-infos',
                value: state.fatalInfos,
                disabled: disabled,
                onChanged: notifier.setFatalInfos,
              ),
              _LintTogglePill(
                label: '--fatal-warnings',
                value: state.fatalWarnings,
                disabled: disabled,
                onChanged: notifier.setFatalWarnings,
              ),
              _LintTogglePill(
                label: 'Skan higieny (TODO/print)',
                value: state.includeHygieneScan,
                disabled: disabled,
                onChanged: notifier.setIncludeHygieneScan,
              ),
            ],
          ),
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
        border: Border.all(color: AppColors.crimsonAlert.withValues(alpha: 0.5)),
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

  Widget _buildKpiRow(FinalLintGateState state, bool isMobile) {
    final report = state.report;
    final items = [
      _KpiSpec(
        title: 'Błędy (Error)',
        value: report != null ? '${report.errorCount}' : '—',
        color: AppColors.crimsonAlert,
      ),
      _KpiSpec(
        title: 'Ostrzeżenia',
        value: report != null ? '${report.warningCount}' : '—',
        color: AppColors.amberWarning,
      ),
      _KpiSpec(
        title: 'Info',
        value: report != null ? '${report.infoCount}' : '—',
        color: AppColors.accentBlue,
      ),
      _KpiSpec(
        title: 'Pliki z problemami',
        value: report != null ? '${report.filesWithIssuesCount}' : '—',
        color: AppColors.goldAccent,
      ),
      _KpiSpec(
        title: 'Czas / Exit',
        value: report != null
            ? '${report.durationMs}ms · #${report.exitCode}'
            : '—',
        color: report?.isZeroWarningsPassed == true
            ? AppColors.statusSuccess
            : AppColors.textSecondary,
      ),
    ];

    if (isMobile) {
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: items
            .map(
              (item) => SizedBox(
                width: 170,
                child: _buildKpiCard(item),
              ),
            )
            .toList(),
      );
    }

    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Expanded(child: _buildKpiCard(items[i])),
          if (i < items.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }

  Widget _buildKpiCard(_KpiSpec spec) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            spec.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            spec.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: spec.color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleBreakdownCard(
    FinalLintGateState state,
    FinalLintAndZeroWarningsGateNotifier notifier,
  ) {
    final report = state.report;
    final breakdown = report?.ruleBreakdown ?? const <LintRuleBreakdown>[];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Reguły lintera',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (state.selectedRule != null)
                _LintSelectableChip(
                  label: 'Wyczyść filtr',
                  selected: false,
                  disabled: false,
                  accentColor: AppColors.goldAccent,
                  onTap: () => notifier.setSelectedRule(null),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (report == null)
            const Text(
              'Brak danych. Uruchom analizę, aby zobaczyć rozkład reguł.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            )
          else if (breakdown.isEmpty)
            const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.statusSuccess, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Zero naruszeń reguł lintera.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppColors.statusSuccess,
                    ),
                  ),
                ),
              ],
            )
          else
            Column(
              children: breakdown.map((rule) {
                final isSelected = state.selectedRule == rule.ruleName;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _LintRuleRow(
                    rule: rule,
                    selected: isSelected,
                    onTap: () => notifier.setSelectedRule(rule.ruleName),
                  ),
                );
              }).toList(),
            ),
          if (report != null && report.hygieneFindings.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.cardBorder),
            const SizedBox(height: 8),
            Text(
              'Higiena kodu: ${report.hygieneFindings.length} uwag (${report.scannedFilesCount} plików)',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.amberWarning,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIssuesCard(
    FinalLintGateState state,
    FinalLintAndZeroWarningsGateNotifier notifier,
    bool isMobile,
  ) {
    final report = state.report;
    final filtered = state.filteredIssues;

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Lista wykrytych problemów',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${filtered.length}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.goldAccent,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _LintSelectableChip(
                label: 'Wszystkie',
                selected: state.severityFilter == null,
                disabled: false,
                accentColor: AppColors.goldAccent,
                onTap: () => notifier.setSeverityFilter(null),
              ),
              ...LintIssueSeverity.values.map((sev) {
                return _LintSelectableChip(
                  label: sev.label,
                  selected: state.severityFilter == sev,
                  disabled: false,
                  accentColor: sev.color,
                  onTap: () => notifier.setSeverityFilter(sev),
                );
              }),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            onChanged: notifier.setSearchQuery,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Szukaj po pliku, regule lub treści...',
              hintStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.textSecondary,
                size: 18,
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
                borderSide: const BorderSide(color: AppColors.goldAccent),
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (report == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Kliknij „Uruchom --fatal-infos”, aby przeprowadzić audyt.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Brak problemów pasujących do aktywnych filtrów.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.statusSuccess,
                  ),
                ),
              ),
            )
          else
            Column(
              children: filtered.take(100).map((issue) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _LintIssueTile(issue: issue),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _KpiSpec {
  final String title;
  final String value;
  final Color color;

  const _KpiSpec({
    required this.title,
    required this.value,
    required this.color,
  });
}

class _LintActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final bool isPrimary;
  final bool disabled;
  final VoidCallback? onTap;

  const _LintActionButton({
    required this.label,
    required this.icon,
    required this.accentColor,
    this.isPrimary = false,
    this.disabled = false,
    this.onTap,
  });

  @override
  State<_LintActionButton> createState() => _LintActionButtonState();
}

class _LintActionButtonState extends State<_LintActionButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.disabled || widget.onTap == null;
    final bgColor = isDisabled
        ? AppColors.surfaceLight.withValues(alpha: 0.5)
        : widget.isPrimary
            ? (_pressed
                ? widget.accentColor.withValues(alpha: 0.8)
                : _hovered
                    ? widget.accentColor.withValues(alpha: 0.92)
                    : widget.accentColor)
            : (_pressed
                ? AppColors.surfaceLight
                : _hovered
                    ? AppColors.surfaceLight.withValues(alpha: 0.9)
                    : AppColors.background);

    final borderColor = isDisabled
        ? AppColors.cardBorder.withValues(alpha: 0.5)
        : _focused
            ? AppColors.goldAccent
            : _hovered
                ? widget.accentColor
                : AppColors.cardBorder;

    final fgColor = isDisabled
        ? AppColors.textSecondary.withValues(alpha: 0.55)
        : AppColors.textPrimary;

    return FocusableActionDetector(
      enabled: !isDisabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: isDisabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: isDisabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: isDisabled ? null : () => setState(() => _pressed = false),
        onTap: isDisabled ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
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

class _LintSelectableChip extends StatefulWidget {
  final String label;
  final bool selected;
  final bool disabled;
  final Color accentColor;
  final VoidCallback onTap;

  const _LintSelectableChip({
    required this.label,
    required this.selected,
    required this.disabled,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_LintSelectableChip> createState() => _LintSelectableChipState();
}

class _LintSelectableChipState extends State<_LintSelectableChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.selected
        ? widget.accentColor.withValues(alpha: 0.18)
        : _hovered
            ? AppColors.surfaceLight
            : AppColors.background;
    final borderColor = _focused
        ? AppColors.goldAccent
        : widget.selected
            ? widget.accentColor
            : _hovered
                ? AppColors.textSecondary.withValues(alpha: 0.5)
                : AppColors.cardBorder;

    return FocusableActionDetector(
      enabled: !widget.disabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTap: widget.disabled ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
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
              color: widget.disabled
                  ? AppColors.textSecondary.withValues(alpha: 0.5)
                  : widget.selected
                      ? widget.accentColor
                      : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _LintTogglePill extends StatelessWidget {
  final String label;
  final bool value;
  final bool disabled;
  final ValueChanged<bool> onChanged;

  const _LintTogglePill({
    required this.label,
    required this.value,
    required this.disabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _LintSelectableChip(
      label: '${value ? "✓" : "○"} $label',
      selected: value,
      disabled: disabled,
      accentColor: AppColors.statusSuccess,
      onTap: () => onChanged(!value),
    );
  }
}

class _LintRuleRow extends StatefulWidget {
  final LintRuleBreakdown rule;
  final bool selected;
  final VoidCallback onTap;

  const _LintRuleRow({
    required this.rule,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_LintRuleRow> createState() => _LintRuleRowState();
}

class _LintRuleRowState extends State<_LintRuleRow> {
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: widget.selected
                ? widget.rule.highestSeverity.color.withValues(alpha: 0.14)
                : _hovered
                    ? AppColors.surfaceLight
                    : AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.selected
                  ? widget.rule.highestSeverity.color
                  : AppColors.cardBorder,
            ),
          ),
          child: Row(
            children: [
              Icon(
                widget.rule.highestSeverity.icon,
                size: 16,
                color: widget.rule.highestSeverity.color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.rule.ruleName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${widget.rule.count}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: widget.rule.highestSeverity.color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LintIssueTile extends StatelessWidget {
  final LintAnalyzeIssue issue;

  const _LintIssueTile({required this.issue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(issue.severity.icon, size: 15, color: issue.severity.color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  issue.ruleName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
          const SizedBox(height: 6),
          Text(
            issue.message,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            issue.normalizedPath,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
