// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Identyfikator etapu / paczki zadań objętych certyfikacją Master (#001–#312).
enum CertificationPackageId {
  foundation('Fundament (#001–#162)', 1, 162, Icons.foundation_rounded),
  package1('Paczka #1 (#163–#212)', 163, 212, Icons.view_in_ar_rounded),
  package2('Paczka #2 (#213–#262)', 213, 262, Icons.speed_rounded),
  package3('Paczka #3 (#263–#312)', 263, 312, Icons.verified_rounded);

  final String label;
  final int startTask;
  final int endTask;
  final IconData icon;

  const CertificationPackageId(
    this.label,
    this.startTask,
    this.endTask,
    this.icon,
  );

  static CertificationPackageId fromTaskNumber(int taskNumber) {
    for (final pkg in values) {
      if (taskNumber >= pkg.startTask && taskNumber <= pkg.endTask) {
        return pkg;
      }
    }
    return foundation;
  }
}

/// Poziom ważności wyniku certyfikacji.
enum CertificationSeverity {
  pass('OK', AppColors.statusSuccess),
  info('Info', AppColors.accentBlue),
  warning('Ostrzeżenie', AppColors.amberWarning),
  error('Błąd', AppColors.crimsonAlert);

  final String label;
  final Color color;

  const CertificationSeverity(this.label, this.color);
}

/// Pojedynczy problem zgłoszony przez bramkę `flutter analyze`.
@immutable
class CertificationAnalyzeIssue {
  final CertificationSeverity severity;
  final String message;
  final String filePath;
  final int line;
  final int column;
  final String ruleName;

  const CertificationAnalyzeIssue({
    required this.severity,
    required this.message,
    required this.filePath,
    required this.line,
    required this.column,
    required this.ruleName,
  });

  Map<String, dynamic> toJson() => {
        'severity': severity.name,
        'message': message,
        'filePath': filePath,
        'line': line,
        'column': column,
        'ruleName': ruleName,
      };
}

/// Wynik bramki analizy statycznej `flutter analyze`.
@immutable
class FlutterAnalyzeGateResult {
  final bool executed;
  final int exitCode;
  final int errorCount;
  final int warningCount;
  final int infoCount;
  final bool noIssuesFound;
  final List<CertificationAnalyzeIssue> issues;
  final String rawOutput;
  final Duration duration;

  const FlutterAnalyzeGateResult({
    required this.executed,
    required this.exitCode,
    required this.errorCount,
    required this.warningCount,
    required this.infoCount,
    required this.noIssuesFound,
    required this.issues,
    required this.rawOutput,
    required this.duration,
  });

  bool get passed =>
      executed &&
      exitCode == 0 &&
      errorCount == 0 &&
      warningCount == 0 &&
      infoCount == 0 &&
      noIssuesFound;

  factory FlutterAnalyzeGateResult.skipped() =>
      const FlutterAnalyzeGateResult(
        executed: false,
        exitCode: 0,
        errorCount: 0,
        warningCount: 0,
        infoCount: 0,
        noIssuesFound: false,
        issues: [],
        rawOutput: 'Pominięto uruchomienie flutter analyze.',
        duration: Duration.zero,
      );

  Map<String, dynamic> toJson() => {
        'executed': executed,
        'exitCode': exitCode,
        'errorCount': errorCount,
        'warningCount': warningCount,
        'infoCount': infoCount,
        'noIssuesFound': noIssuesFound,
        'passed': passed,
        'durationMs': duration.inMilliseconds,
        'issues': issues.map((e) => e.toJson()).toList(),
      };
}

/// Wynik bramki pełnego pakietu testów `flutter test`.
@immutable
class FlutterTestSuiteGateResult {
  final bool executed;
  final int exitCode;
  final int totalPassed;
  final int totalFailed;
  final int totalSkipped;
  final List<String> failedTestNames;
  final String rawOutput;
  final Duration duration;

  const FlutterTestSuiteGateResult({
    required this.executed,
    required this.exitCode,
    required this.totalPassed,
    required this.totalFailed,
    required this.totalSkipped,
    required this.failedTestNames,
    required this.rawOutput,
    required this.duration,
  });

  bool get passed =>
      executed && exitCode == 0 && totalFailed == 0 && totalPassed > 0;

  factory FlutterTestSuiteGateResult.skipped() =>
      const FlutterTestSuiteGateResult(
        executed: false,
        exitCode: 0,
        totalPassed: 0,
        totalFailed: 0,
        totalSkipped: 0,
        failedTestNames: [],
        rawOutput: 'Pominięto uruchomienie flutter test.',
        duration: Duration.zero,
      );

  Map<String, dynamic> toJson() => {
        'executed': executed,
        'exitCode': exitCode,
        'totalPassed': totalPassed,
        'totalFailed': totalFailed,
        'totalSkipped': totalSkipped,
        'passed': passed,
        'durationMs': duration.inMilliseconds,
        'failedTestNames': failedTestNames,
      };
}

/// Wynik audytu mapy projektu `docs/CODE_MAP.md`.
@immutable
class CodeMapIntegrityGateResult {
  final bool exists;
  final int totalLines;
  final int registeredLibFilesCount;
  final List<String> missingTaskPaths;

  const CodeMapIntegrityGateResult({
    required this.exists,
    required this.totalLines,
    required this.registeredLibFilesCount,
    required this.missingTaskPaths,
  });

  bool get passed => exists && missingTaskPaths.isEmpty;

  Map<String, dynamic> toJson() => {
        'exists': exists,
        'totalLines': totalLines,
        'registeredLibFilesCount': registeredLibFilesCount,
        'missingTaskPaths': missingTaskPaths,
        'passed': passed,
      };
}

/// Wynik weryfikacji pojedynczego zadania z zakresu #001–#312.
@immutable
class QueueTaskVerificationEntry {
  final int taskNumber;
  final CertificationPackageId packageId;
  final bool completedInQueue;
  final String artifactPath;
  final bool artifactExists;
  final int artifactSizeBytes;
  final bool registeredInCodeMap;
  final int todoCount;
  final int unimplementedCount;
  final List<String> issues;

  const QueueTaskVerificationEntry({
    required this.taskNumber,
    required this.packageId,
    required this.completedInQueue,
    required this.artifactPath,
    required this.artifactExists,
    required this.artifactSizeBytes,
    required this.registeredInCodeMap,
    required this.todoCount,
    required this.unimplementedCount,
    required this.issues,
  });

  bool get requiresCodeMapRegistration => artifactPath.startsWith('lib/');

  bool get passed =>
      completedInQueue &&
      artifactExists &&
      artifactSizeBytes > 0 &&
      (!requiresCodeMapRegistration || registeredInCodeMap) &&
      todoCount == 0 &&
      unimplementedCount == 0 &&
      issues.isEmpty;

  CertificationSeverity get severity {
    if (!artifactExists || !completedInQueue || unimplementedCount > 0) {
      return CertificationSeverity.error;
    }
    if ((requiresCodeMapRegistration && !registeredInCodeMap) ||
        todoCount > 0 ||
        issues.isNotEmpty) {
      return CertificationSeverity.warning;
    }
    return CertificationSeverity.pass;
  }

  Map<String, dynamic> toJson() => {
        'taskNumber': taskNumber,
        'packageId': packageId.name,
        'completedInQueue': completedInQueue,
        'artifactPath': artifactPath,
        'artifactExists': artifactExists,
        'artifactSizeBytes': artifactSizeBytes,
        'registeredInCodeMap': registeredInCodeMap,
        'todoCount': todoCount,
        'unimplementedCount': unimplementedCount,
        'issues': issues,
        'passed': passed,
      };
}

/// Zagregowane metryki dla jednej paczki zadań.
@immutable
class PackageSummaryMetric {
  final CertificationPackageId packageId;
  final int totalTasks;
  final int completedInQueue;
  final int existingArtifacts;
  final int passedTasks;

  const PackageSummaryMetric({
    required this.packageId,
    required this.totalTasks,
    required this.completedInQueue,
    required this.existingArtifacts,
    required this.passedTasks,
  });

  double get passRate => totalTasks == 0 ? 0.0 : passedTasks / totalTasks;

  Map<String, dynamic> toJson() => {
        'packageId': packageId.name,
        'label': packageId.label,
        'totalTasks': totalTasks,
        'completedInQueue': completedInQueue,
        'existingArtifacts': existingArtifacts,
        'passedTasks': passedTasks,
        'passRate': passRate,
      };
}

/// Kompletny raport certyfikacji końcowej Master (#001–#312).
@immutable
class MasterCertificationReport {
  final DateTime generatedAt;
  final String projectRoot;
  final int targetTasksCount;
  final List<QueueTaskVerificationEntry> taskEntries;
  final List<PackageSummaryMetric> packageSummaries;
  final CodeMapIntegrityGateResult codeMapResult;
  final FlutterAnalyzeGateResult analyzeResult;
  final FlutterTestSuiteGateResult testSuiteResult;
  final Duration duration;

  const MasterCertificationReport({
    required this.generatedAt,
    required this.projectRoot,
    required this.targetTasksCount,
    required this.taskEntries,
    required this.packageSummaries,
    required this.codeMapResult,
    required this.analyzeResult,
    required this.testSuiteResult,
    required this.duration,
  });

  int get totalTasksChecked => taskEntries.length;
  int get completedQueueTasks =>
      taskEntries.where((e) => e.completedInQueue).length;
  int get existingArtifactsCount =>
      taskEntries.where((e) => e.artifactExists).length;
  int get passedTasksCount => taskEntries.where((e) => e.passed).length;
  int get failedTasksCount => totalTasksChecked - passedTasksCount;

  bool get allTasksVerified =>
      totalTasksChecked == targetTasksCount && failedTasksCount == 0;

  bool get overallCertified =>
      allTasksVerified &&
      codeMapResult.passed &&
      (!analyzeResult.executed || analyzeResult.passed) &&
      (!testSuiteResult.executed || testSuiteResult.passed);

  String toMarkdownSummary() {
    final buf = StringBuffer()
      ..writeln('# Raport Certyfikacji Końcowej Sniper Mode (#001–#312)')
      ..writeln('- **Data**: ${generatedAt.toIso8601String()}')
      ..writeln('- **Katalog projektu**: `$projectRoot`')
      ..writeln(
        '- **Status certyfikacji**: ${overallCertified ? 'CERTYFIKOWANO (100%)' : 'WYMAGA POPRAWEK'}',
      )
      ..writeln(
        '- **Zadania zweryfikowane**: $passedTasksCount / $targetTasksCount',
      )
      ..writeln(
        '- **CODE_MAP.md**: ${codeMapResult.passed ? 'KOMPLETNA' : 'BRAKI (${codeMapResult.missingTaskPaths.length})'}',
      )
      ..writeln(
        '- **flutter analyze**: ${analyzeResult.executed ? (analyzeResult.passed ? 'No issues found!' : '${analyzeResult.errorCount} błędów, ${analyzeResult.warningCount} ostrzeżeń, ${analyzeResult.infoCount} info') : 'POMINIĘTO'}',
      )
      ..writeln(
        '- **flutter test**: ${testSuiteResult.executed ? (testSuiteResult.passed ? 'ZALICZONY (${testSuiteResult.totalPassed} testów)' : 'BŁĘDY (${testSuiteResult.totalFailed} niezaliczonych)') : 'POMINIĘTO'}',
      )
      ..writeln('- **Czas weryfikacji**: ${duration.inMilliseconds} ms')
      ..writeln('\n## Podsumowanie paczek');

    for (final pkg in packageSummaries) {
      buf.writeln(
        '- **${pkg.packageId.label}**: ${pkg.passedTasks}/${pkg.totalTasks} '
        '(${(pkg.passRate * 100).toStringAsFixed(1)}%)',
      );
    }

    final failed = taskEntries.where((e) => !e.passed).toList();
    if (failed.isNotEmpty) {
      buf.writeln('\n## Zadania wymagające uwagi (${failed.length})');
      for (final entry in failed.take(30)) {
        buf.writeln(
          '- **#${entry.taskNumber.toString().padLeft(3, '0')}** '
          '(`${entry.artifactPath}`): ${entry.issues.join(', ')}',
        );
      }
    }

    return buf.toString();
  }

  Map<String, dynamic> toJson() => {
        'generatedAt': generatedAt.toIso8601String(),
        'projectRoot': projectRoot,
        'targetTasksCount': targetTasksCount,
        'totalTasksChecked': totalTasksChecked,
        'completedQueueTasks': completedQueueTasks,
        'existingArtifactsCount': existingArtifactsCount,
        'passedTasksCount': passedTasksCount,
        'failedTasksCount': failedTasksCount,
        'overallCertified': overallCertified,
        'durationMs': duration.inMilliseconds,
        'packageSummaries': packageSummaries.map((e) => e.toJson()).toList(),
        'codeMapResult': codeMapResult.toJson(),
        'analyzeResult': analyzeResult.toJson(),
        'testSuiteResult': testSuiteResult.toJson(),
        'taskEntries': taskEntries.map((e) => e.toJson()).toList(),
      };
}

/// Główny silnik certyfikacji końcowej wszystkich 312 zadań Sniper Mode.
class SniperMasterFinalCertification {
  static const int targetTotalTasks = 312;

  static final RegExp _queueTaskRegex = RegExp(
    r'^-\s+\[([xX ])\]\s+\*\*Zadanie\s+#(\d+)\*\*\s+\(`([^`]+)`\)',
    multiLine: true,
  );

  static final RegExp _todoRegex = RegExp(
    r'//\s*TODO\b',
    caseSensitive: false,
  );

  static final RegExp _unimplementedRegex = RegExp(
    r'throw\s+UnimplementedError\b',
  );

  static final RegExp _analyzeLineRegex = RegExp(
    r'^\s*(error|warning|info)\s+-\s+(.+?)\s+-\s+(.+?):(\d+):(\d+)\s+-\s+(\S+)\s*$',
    multiLine: true,
  );

  static final RegExp _testSummaryPassRegex = RegExp(
    r'\+(\d+)(?:\s+~(\d+))?(?:\s+-(\d+))?:',
  );

  const SniperMasterFinalCertification();

  /// Uruchamia pełną certyfikację zadań #001–#312, analizę statyczną i testy.
  Future<MasterCertificationReport> runCertification({
    String? projectRoot,
    bool runFlutterAnalyze = true,
    bool runFlutterTest = true,
  }) async {
    final stopwatch = Stopwatch()..start();
    final root = _resolveProjectRoot(projectRoot);

    final queueFile = File(_joinPath(root, 'docs/QUEUE.md'));
    final codeMapFile = File(_joinPath(root, 'docs/CODE_MAP.md'));

    final queueContent =
        queueFile.existsSync() ? await queueFile.readAsString() : '';
    final codeMapExists = codeMapFile.existsSync();
    final codeMapContent =
        codeMapExists ? await codeMapFile.readAsString() : '';
    final codeMapLines = codeMapExists ? codeMapContent.split('\n').length : 0;

    final parsedByNumber = <int, ({bool completed, String path})>{};
    for (final match in _queueTaskRegex.allMatches(queueContent)) {
      final mark = match.group(1) ?? ' ';
      final numStr = match.group(2) ?? '0';
      final path = (match.group(3) ?? '').trim();
      final taskNum = int.tryParse(numStr) ?? 0;
      if (taskNum >= 1 && taskNum <= targetTotalTasks) {
        parsedByNumber[taskNum] = (
          completed: mark.toLowerCase() == 'x',
          path: path,
        );
      }
    }

    final entries = <QueueTaskVerificationEntry>[];
    final missingCodeMapPaths = <String>[];

    for (var taskNum = 1; taskNum <= targetTotalTasks; taskNum++) {
      final parsed = parsedByNumber[taskNum];
      final pkgId = CertificationPackageId.fromTaskNumber(taskNum);

      if (parsed == null) {
        entries.add(
          QueueTaskVerificationEntry(
            taskNumber: taskNum,
            packageId: pkgId,
            completedInQueue: false,
            artifactPath: '',
            artifactExists: false,
            artifactSizeBytes: 0,
            registeredInCodeMap: false,
            todoCount: 0,
            unimplementedCount: 0,
            issues: const ['Brak wpisu zadania w docs/QUEUE.md'],
          ),
        );
        continue;
      }

      final issues = <String>[];
      if (!parsed.completed) {
        issues.add('Zadanie nieoznaczone jako [x] w docs/QUEUE.md');
      }

      final fullPath = _joinPath(root, parsed.path);
      final fileEntity = File(fullPath);
      final dirEntity = Directory(fullPath);

      var exists = false;
      var sizeBytes = 0;
      var todoCount = 0;
      var unimplementedCount = 0;

      if (fileEntity.existsSync()) {
        exists = true;
        sizeBytes = fileEntity.lengthSync();
        if (parsed.path.endsWith('.dart')) {
          final content = await fileEntity.readAsString();
          todoCount = _todoRegex.allMatches(content).length;
          unimplementedCount = _unimplementedRegex.allMatches(content).length;
          if (todoCount > 0) {
            issues.add('Wykryto $todoCount markerów TODO');
          }
          if (unimplementedCount > 0) {
            issues.add('Wykryto $unimplementedCount wywołań UnimplementedError');
          }
        }
      } else if (dirEntity.existsSync()) {
        exists = true;
        sizeBytes = 1;
      } else {
        issues.add('Brak pliku docelowego na dysku: ${parsed.path}');
      }

      final requiresCodeMap = parsed.path.startsWith('lib/');
      final registeredInCodeMap =
          !requiresCodeMap || codeMapContent.contains(parsed.path);

      if (requiresCodeMap && !registeredInCodeMap) {
        missingCodeMapPaths.add(parsed.path);
        issues.add('Brak wpisu w docs/CODE_MAP.md');
      }

      entries.add(
        QueueTaskVerificationEntry(
          taskNumber: taskNum,
          packageId: pkgId,
          completedInQueue: parsed.completed,
          artifactPath: parsed.path,
          artifactExists: exists,
          artifactSizeBytes: sizeBytes,
          registeredInCodeMap: registeredInCodeMap,
          todoCount: todoCount,
          unimplementedCount: unimplementedCount,
          issues: issues,
        ),
      );
    }

    final summaries = <PackageSummaryMetric>[];
    for (final pkg in CertificationPackageId.values) {
      final pkgEntries = entries.where((e) => e.packageId == pkg).toList();
      summaries.add(
        PackageSummaryMetric(
          packageId: pkg,
          totalTasks: pkgEntries.length,
          completedInQueue: pkgEntries.where((e) => e.completedInQueue).length,
          existingArtifacts: pkgEntries.where((e) => e.artifactExists).length,
          passedTasks: pkgEntries.where((e) => e.passed).length,
        ),
      );
    }

    final registeredLibFilesCount = RegExp(r'`lib/[^`]+\.dart`')
        .allMatches(codeMapContent)
        .map((m) => m.group(0))
        .toSet()
        .length;

    final codeMapResult = CodeMapIntegrityGateResult(
      exists: codeMapExists,
      totalLines: codeMapLines,
      registeredLibFilesCount: registeredLibFilesCount,
      missingTaskPaths: missingCodeMapPaths,
    );

    final analyzeResult = runFlutterAnalyze
        ? await _executeFlutterAnalyze(root)
        : FlutterAnalyzeGateResult.skipped();

    final testSuiteResult = runFlutterTest
        ? await _executeFlutterTest(root)
        : FlutterTestSuiteGateResult.skipped();

    stopwatch.stop();

    return MasterCertificationReport(
      generatedAt: DateTime.now(),
      projectRoot: root,
      targetTasksCount: targetTotalTasks,
      taskEntries: entries,
      packageSummaries: summaries,
      codeMapResult: codeMapResult,
      analyzeResult: analyzeResult,
      testSuiteResult: testSuiteResult,
      duration: stopwatch.elapsed,
    );
  }

  Future<FlutterAnalyzeGateResult> _executeFlutterAnalyze(
    String projectRoot,
  ) async {
    final sw = Stopwatch()..start();
    try {
      final executable = Platform.isWindows ? 'flutter.bat' : 'flutter';
      final result = await Process.run(
        executable,
        const ['analyze', '--no-pub'],
        workingDirectory: projectRoot,
      );
      sw.stop();

      final combinedOutput =
          '${result.stdout}\n${result.stderr}'.trim();
      final issues = <CertificationAnalyzeIssue>[];
      var errors = 0;
      var warnings = 0;
      var infos = 0;

      for (final m in _analyzeLineRegex.allMatches(combinedOutput)) {
        final sevStr = m.group(1) ?? 'info';
        final severity = switch (sevStr) {
          'error' => CertificationSeverity.error,
          'warning' => CertificationSeverity.warning,
          _ => CertificationSeverity.info,
        };
        if (severity == CertificationSeverity.error) errors++;
        if (severity == CertificationSeverity.warning) warnings++;
        if (severity == CertificationSeverity.info) infos++;

        issues.add(
          CertificationAnalyzeIssue(
            severity: severity,
            message: m.group(2) ?? '',
            filePath: m.group(3) ?? '',
            line: int.tryParse(m.group(4) ?? '0') ?? 0,
            column: int.tryParse(m.group(5) ?? '0') ?? 0,
            ruleName: m.group(6) ?? '',
          ),
        );
      }

      final noIssuesFound = combinedOutput.contains('No issues found!') &&
          result.exitCode == 0 &&
          issues.isEmpty;

      return FlutterAnalyzeGateResult(
        executed: true,
        exitCode: result.exitCode,
        errorCount: errors,
        warningCount: warnings,
        infoCount: infos,
        noIssuesFound: noIssuesFound,
        issues: issues,
        rawOutput: combinedOutput,
        duration: sw.elapsed,
      );
    } catch (e) {
      sw.stop();
      return FlutterAnalyzeGateResult(
        executed: true,
        exitCode: -1,
        errorCount: 1,
        warningCount: 0,
        infoCount: 0,
        noIssuesFound: false,
        issues: [
          CertificationAnalyzeIssue(
            severity: CertificationSeverity.error,
            message: 'Nie udało się uruchomić flutter analyze: $e',
            filePath: 'flutter',
            line: 0,
            column: 0,
            ruleName: 'process_error',
          ),
        ],
        rawOutput: e.toString(),
        duration: sw.elapsed,
      );
    }
  }

  Future<FlutterTestSuiteGateResult> _executeFlutterTest(
    String projectRoot,
  ) async {
    final sw = Stopwatch()..start();
    try {
      final executable = Platform.isWindows ? 'flutter.bat' : 'flutter';
      final result = await Process.run(
        executable,
        const ['test', '--no-pub', '--timeout', '30s'],
        workingDirectory: projectRoot,
      );
      sw.stop();

      final combinedOutput =
          '${result.stdout}\n${result.stderr}'.trim();

      var passed = 0;
      var skipped = 0;
      var failed = 0;
      for (final m in _testSummaryPassRegex.allMatches(combinedOutput)) {
        passed = int.tryParse(m.group(1) ?? '0') ?? passed;
        if (m.group(2) != null) {
          skipped = int.tryParse(m.group(2)!) ?? skipped;
        }
        if (m.group(3) != null) {
          failed = int.tryParse(m.group(3)!) ?? failed;
        }
      }

      final failedNames = <String>[];
      for (final line in combinedOutput.split('\n')) {
        if (line.contains('[E]')) {
          failedNames.add(line.trim());
        }
      }

      return FlutterTestSuiteGateResult(
        executed: true,
        exitCode: result.exitCode,
        totalPassed: passed,
        totalFailed: failed,
        totalSkipped: skipped,
        failedTestNames: failedNames,
        rawOutput: combinedOutput,
        duration: sw.elapsed,
      );
    } catch (e) {
      sw.stop();
      return FlutterTestSuiteGateResult(
        executed: true,
        exitCode: -1,
        totalPassed: 0,
        totalFailed: 1,
        totalSkipped: 0,
        failedTestNames: [e.toString()],
        rawOutput: e.toString(),
        duration: sw.elapsed,
      );
    }
  }

  String _resolveProjectRoot(String? explicitRoot) {
    if (explicitRoot != null && explicitRoot.trim().isNotEmpty) {
      return explicitRoot.trim();
    }
    var dir = Directory.current;
    for (var i = 0; i < 6; i++) {
      final pubspec = File(_joinPath(dir.path, 'pubspec.yaml'));
      final queue = File(_joinPath(dir.path, 'docs/QUEUE.md'));
      if (pubspec.existsSync() && queue.existsSync()) {
        return dir.path;
      }
      if (dir.parent.path == dir.path) break;
      dir = dir.parent;
    }
    return Directory.current.path;
  }

  String _joinPath(String root, String relative) {
    final normalizedRoot = root.replaceAll('\\', '/').replaceAll(RegExp(r'/$'), '');
    final normalizedRel = relative.replaceAll('\\', '/').replaceAll(RegExp(r'^/'), '');
    return '$normalizedRoot/$normalizedRel';
  }
}

/// Stan certyfikacji w Riverpod.
@immutable
class MasterCertificationState {
  final bool isRunning;
  final MasterCertificationReport? report;
  final String? errorMessage;
  final bool runAnalyzeGate;
  final bool runTestGate;
  final CertificationPackageId? selectedPackageFilter;
  final bool onlyFailedFilter;

  const MasterCertificationState({
    this.isRunning = false,
    this.report,
    this.errorMessage,
    this.runAnalyzeGate = true,
    this.runTestGate = false,
    this.selectedPackageFilter,
    this.onlyFailedFilter = false,
  });

  MasterCertificationState copyWith({
    bool? isRunning,
    MasterCertificationReport? report,
    String? errorMessage,
    bool clearError = false,
    bool? runAnalyzeGate,
    bool? runTestGate,
    CertificationPackageId? selectedPackageFilter,
    bool clearPackageFilter = false,
    bool? onlyFailedFilter,
  }) {
    return MasterCertificationState(
      isRunning: isRunning ?? this.isRunning,
      report: report ?? this.report,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      runAnalyzeGate: runAnalyzeGate ?? this.runAnalyzeGate,
      runTestGate: runTestGate ?? this.runTestGate,
      selectedPackageFilter: clearPackageFilter
          ? null
          : (selectedPackageFilter ?? this.selectedPackageFilter),
      onlyFailedFilter: onlyFailedFilter ?? this.onlyFailedFilter,
    );
  }
}

/// Notifier zarządzający procesem certyfikacji końcowej #001–#312.
class SniperMasterCertificationNotifier
    extends StateNotifier<MasterCertificationState> {
  final SniperMasterFinalCertification _runner;

  SniperMasterCertificationNotifier([
    this._runner = const SniperMasterFinalCertification(),
  ]) : super(const MasterCertificationState());

  void setRunAnalyzeGate(bool value) {
    state = state.copyWith(runAnalyzeGate: value);
  }

  void setRunTestGate(bool value) {
    state = state.copyWith(runTestGate: value);
  }

  void setPackageFilter(CertificationPackageId? packageId) {
    if (packageId == null) {
      state = state.copyWith(clearPackageFilter: true);
    } else {
      state = state.copyWith(selectedPackageFilter: packageId);
    }
  }

  void setOnlyFailedFilter(bool value) {
    state = state.copyWith(onlyFailedFilter: value);
  }

  Future<void> runCertification({String? projectRoot}) async {
    if (state.isRunning) return;
    state = state.copyWith(isRunning: true, clearError: true);
    try {
      final report = await _runner.runCertification(
        projectRoot: projectRoot,
        runFlutterAnalyze: state.runAnalyzeGate,
        runFlutterTest: state.runTestGate,
      );
      state = state.copyWith(isRunning: false, report: report);
    } catch (e) {
      state = state.copyWith(
        isRunning: false,
        errorMessage: 'Błąd certyfikacji: $e',
      );
    }
  }
}

/// Provider Riverpod dla certyfikacji końcowej Sniper Mode.
final sniperMasterCertificationProvider = StateNotifierProvider<
    SniperMasterCertificationNotifier, MasterCertificationState>(
  (ref) => SniperMasterCertificationNotifier(),
);

/// Produkcyjny panel UI certyfikacji końcowej Master (#001–#312).
class SniperMasterFinalCertificationPanel extends ConsumerWidget {
  final String? projectRoot;

  const SniperMasterFinalCertificationPanel({
    super.key,
    this.projectRoot,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sniperMasterCertificationProvider);
    final notifier = ref.read(sniperMasterCertificationProvider.notifier);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isCompact = width < 640;
        final isTablet = width >= 640 && width < 1100;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor),
          ),
          padding: EdgeInsets.all(isCompact ? 12 : 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context, state, notifier, isCompact),
                const SizedBox(height: 16),
                _buildControlsBar(context, state, notifier, isCompact),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 14),
                  _buildErrorBanner(state.errorMessage!),
                ],
                if (state.report != null) ...[
                  const SizedBox(height: 16),
                  _buildSummaryMetrics(
                    state.report!,
                    isCompact: isCompact,
                    isTablet: isTablet,
                  ),
                  const SizedBox(height: 16),
                  _buildPackageBreakdown(state.report!, isCompact: isCompact),
                  const SizedBox(height: 16),
                  _buildTaskListSection(state, state.report!, notifier),
                ] else if (!state.isRunning) ...[
                  const SizedBox(height: 20),
                  _buildEmptyPrompt(),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    MasterCertificationState state,
    SniperMasterCertificationNotifier notifier,
    bool isCompact,
  ) {
    final report = state.report;
    final badgeColor = report == null
        ? AppColors.goldAccent
        : (report.overallCertified
            ? AppColors.statusSuccess
            : AppColors.amberWarning);
    final badgeText = report == null
        ? 'GOTOWY DO CERTYFIKACJI'
        : (report.overallCertified
            ? 'CERTYFIKOWANO 312/312'
            : 'WYMAGA WERYFIKACJI');

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.goldAccent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.goldAccent.withValues(alpha: 0.4),
                ),
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: AppColors.goldAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Flexible(
              child: Text(
                'Sniper Master Final Certification (#001–#312)',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Pełna certyfikacja kolejki 312 zadań, spójności CODE_MAP.md, analizy statycznej i testów.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );

    final actionRow = Wrap(
      spacing: 10,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
          ),
          child: Text(
            badgeText,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: badgeColor,
              letterSpacing: 0.3,
            ),
          ),
        ),
        _CertificationActionButton(
          label: state.isRunning ? 'Weryfikacja...' : 'Uruchom Certyfikację',
          icon: state.isRunning
              ? Icons.hourglass_top_rounded
              : Icons.verified_rounded,
          enabled: !state.isRunning,
          accentColor: AppColors.goldAccent,
          onPressed: () => notifier.runCertification(projectRoot: projectRoot),
        ),
        if (report != null)
          _CertificationActionButton(
            label: 'Kopiuj JSON',
            icon: Icons.copy_all_rounded,
            enabled: !state.isRunning,
            accentColor: AppColors.accentBlue,
            onPressed: () {
              Clipboard.setData(
                ClipboardData(text: jsonEncode(report.toJson())),
              );
            },
          ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleBlock,
                const SizedBox(height: 12),
                actionRow,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: titleBlock),
                const SizedBox(width: 16),
                actionRow,
              ],
            ),
    );
  }

  Widget _buildControlsBar(
    BuildContext context,
    MasterCertificationState state,
    SniperMasterCertificationNotifier notifier,
    bool isCompact,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _CertificationToggleChip(
            label: 'flutter analyze',
            value: state.runAnalyzeGate,
            enabled: !state.isRunning,
            onChanged: notifier.setRunAnalyzeGate,
          ),
          _CertificationToggleChip(
            label: 'flutter test',
            value: state.runTestGate,
            enabled: !state.isRunning,
            onChanged: notifier.setRunTestGate,
          ),
          _CertificationToggleChip(
            label: 'Tylko błędy',
            value: state.onlyFailedFilter,
            enabled: !state.isRunning,
            onChanged: notifier.setOnlyFailedFilter,
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

  Widget _buildSummaryMetrics(
    MasterCertificationReport report, {
    required bool isCompact,
    required bool isTablet,
  }) {
    final cards = [
      _MetricTile(
        title: 'Zadania 312/312',
        value: '${report.passedTasksCount} / ${report.targetTasksCount}',
        subtitle: report.allTasksVerified
            ? 'Wszystkie zaliczone'
            : '${report.failedTasksCount} wymaga uwagi',
        color: report.allTasksVerified
            ? AppColors.statusSuccess
            : AppColors.amberWarning,
        icon: Icons.checklist_rounded,
      ),
      _MetricTile(
        title: 'CODE_MAP.md',
        value: report.codeMapResult.passed ? '100%' : 'BRAKI',
        subtitle: '${report.codeMapResult.registeredLibFilesCount} plików lib/',
        color: report.codeMapResult.passed
            ? AppColors.statusSuccess
            : AppColors.crimsonAlert,
        icon: Icons.map_rounded,
      ),
      _MetricTile(
        title: 'flutter analyze',
        value: !report.analyzeResult.executed
            ? 'POMINIĘTO'
            : (report.analyzeResult.passed ? '0 ISSUES' : 'PROBLEMY'),
        subtitle: report.analyzeResult.executed
            ? (report.analyzeResult.noIssuesFound
                ? 'No issues found!'
                : '${report.analyzeResult.errorCount}E / ${report.analyzeResult.warningCount}W')
            : 'Wyłączono bramkę',
        color: !report.analyzeResult.executed
            ? AppColors.textSecondary
            : (report.analyzeResult.passed
                ? AppColors.statusSuccess
                : AppColors.crimsonAlert),
        icon: Icons.rule_rounded,
      ),
      _MetricTile(
        title: 'flutter test',
        value: !report.testSuiteResult.executed
            ? 'POMINIĘTO'
            : (report.testSuiteResult.passed
                ? '${report.testSuiteResult.totalPassed} OK'
                : '${report.testSuiteResult.totalFailed} FAIL'),
        subtitle: report.testSuiteResult.executed
            ? '${report.testSuiteResult.duration.inSeconds}s'
            : 'Wyłączono bramkę',
        color: !report.testSuiteResult.executed
            ? AppColors.textSecondary
            : (report.testSuiteResult.passed
                ? AppColors.statusSuccess
                : AppColors.crimsonAlert),
        icon: Icons.science_rounded,
      ),
    ];

    if (isCompact) {
      return Column(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            cards[i],
            if (i < cards.length - 1) const SizedBox(height: 10),
          ],
        ],
      );
    }

    if (isTablet) {
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

    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i < cards.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }

  Widget _buildPackageBreakdown(
    MasterCertificationReport report, {
    required bool isCompact,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Podsumowanie Paczek (#001–#312)',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final pkg in report.packageSummaries)
                Container(
                  width: isCompact ? double.infinity : 260,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            pkg.packageId.icon,
                            size: 16,
                            color: AppColors.goldAccent,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              pkg.packageId.label,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: pkg.passRate,
                          minHeight: 6,
                          backgroundColor: AppColors.background,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            pkg.passRate >= 1.0
                                ? AppColors.statusSuccess
                                : AppColors.amberWarning,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${pkg.passedTasks} / ${pkg.totalTasks} zadań OK',
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
        ],
      ),
    );
  }

  Widget _buildTaskListSection(
    MasterCertificationState state,
    MasterCertificationReport report,
    SniperMasterCertificationNotifier notifier,
  ) {
    final filtered = report.taskEntries.where((entry) {
      if (state.selectedPackageFilter != null &&
          entry.packageId != state.selectedPackageFilter) {
        return false;
      }
      if (state.onlyFailedFilter && entry.passed) {
        return false;
      }
      return true;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PackageFilterChip(
                label: 'Wszystkie (${report.totalTasksChecked})',
                selected: state.selectedPackageFilter == null,
                onTap: () => notifier.setPackageFilter(null),
              ),
              for (final pkg in CertificationPackageId.values)
                _PackageFilterChip(
                  label: pkg.label,
                  selected: state.selectedPackageFilter == pkg,
                  onTap: () => notifier.setPackageFilter(pkg),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Wyświetlane zadania: ${filtered.length}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 340),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final item = filtered[index];
                final sev = item.severity;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: item.passed
                          ? AppTheme.borderColor
                          : sev.color.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item.passed
                            ? Icons.check_circle_rounded
                            : Icons.warning_amber_rounded,
                        size: 16,
                        color: sev.color,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '#${item.taskNumber.toString().padLeft(3, '0')}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.goldAccent,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.artifactPath.isEmpty
                              ? 'Brak ścieżki'
                              : item.artifactPath,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPrompt() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.verified_user_rounded,
            size: 36,
            color: AppColors.goldAccent,
          ),
          SizedBox(height: 10),
          Text(
            'Kliknij „Uruchom Certyfikację”, aby zweryfikować 312 zadań, CODE_MAP.md oraz bramki flutter analyze i flutter test.',
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
}

class _MetricTile extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;

  const _MetricTile({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _CertificationActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final Color accentColor;
  final VoidCallback onPressed;

  const _CertificationActionButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.accentColor,
    required this.onPressed,
  });

  @override
  State<_CertificationActionButton> createState() =>
      _CertificationActionButtonState();
}

class _CertificationActionButtonState
    extends State<_CertificationActionButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bg = !widget.enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : (_pressed
            ? widget.accentColor.withValues(alpha: 0.30)
            : (_hovered
                ? widget.accentColor.withValues(alpha: 0.22)
                : widget.accentColor.withValues(alpha: 0.14)));

    final borderColor = _focused
        ? AppColors.goldAccent
        : (widget.enabled
            ? widget.accentColor.withValues(alpha: _hovered ? 0.85 : 0.5)
            : AppTheme.borderColor);

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: widget.enabled
                    ? widget.accentColor
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: widget.enabled
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CertificationToggleChip extends StatefulWidget {
  final String label;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _CertificationToggleChip({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  State<_CertificationToggleChip> createState() =>
      _CertificationToggleChipState();
}

class _CertificationToggleChipState extends State<_CertificationToggleChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.value
        ? AppColors.statusSuccess.withValues(alpha: _hovered ? 0.22 : 0.14)
        : (_hovered ? AppColors.surfaceLight : AppColors.background);

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTap: widget.enabled ? () => widget.onChanged(!widget.value) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _focused
                  ? AppColors.goldAccent
                  : (widget.value
                      ? AppColors.statusSuccess.withValues(alpha: 0.5)
                      : AppTheme.borderColor),
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
                    ? (widget.value
                        ? AppColors.statusSuccess
                        : AppColors.textSecondary)
                    : AppColors.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: widget.enabled
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PackageFilterChip extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PackageFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_PackageFilterChip> createState() => _PackageFilterChipState();
}

class _PackageFilterChipState extends State<_PackageFilterChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.selected
        ? AppColors.goldAccent.withValues(alpha: 0.18)
        : (_hovered ? AppColors.surfaceLight : AppColors.background);

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _focused
                  ? AppColors.goldAccent
                  : (widget.selected
                      ? AppColors.goldAccent.withValues(alpha: 0.6)
                      : AppTheme.borderColor),
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
              color: widget.selected
                  ? AppColors.goldAccent
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
