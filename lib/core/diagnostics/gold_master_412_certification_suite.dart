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

/// Identyfikator etapu / paczki zadań objętych certyfikacją GOLD MASTER v1.0 (#001–#412).
enum GoldMasterPackageId {
  foundation('Fundament (#001–#162)', 1, 162, Icons.foundation_rounded),
  package1('Paczka #1 (#163–#212)', 163, 212, Icons.view_in_ar_rounded),
  package2('Paczka #2 (#213–#262)', 213, 262, Icons.speed_rounded),
  package3('Paczka #3 (#263–#312)', 263, 312, Icons.verified_rounded),
  package4('Paczka #4 (#313–#362)', 313, 362, Icons.directions_bike_rounded),
  package5('Paczka #5 (#363–#412)', 363, 412, Icons.workspace_premium_rounded);

  final String label;
  final int startTask;
  final int endTask;
  final IconData icon;

  const GoldMasterPackageId(
    this.label,
    this.startTask,
    this.endTask,
    this.icon,
  );

  int get expectedCount => endTask - startTask + 1;

  static GoldMasterPackageId fromTaskNumber(int taskNumber) {
    for (final pkg in values) {
      if (taskNumber >= pkg.startTask && taskNumber <= pkg.endTask) {
        return pkg;
      }
    }
    return foundation;
  }
}

/// Poziom ważności wyniku bramki lub zadania certyfikacji.
enum GoldMasterSeverity {
  pass('OK', AppColors.statusSuccess),
  info('Info', AppColors.accentBlue),
  warning('Ostrzeżenie', AppColors.amberWarning),
  error('Błąd', AppColors.crimsonAlert);

  final String label;
  final Color color;

  const GoldMasterSeverity(this.label, this.color);
}

/// Finalny werdykt certyfikacji GOLD MASTER v1.0 (#001–#412).
enum GoldMasterVerdict {
  certifiedGoldMaster(
    'GOLD MASTER v1.0 CERTIFIED',
    'Wszystkie 412 zadań, mapa kodu, trasy nawigacji i bramki jakości przeszły weryfikację.',
    AppColors.goldAccent,
    Icons.workspace_premium_rounded,
  ),
  conditionalPass(
    'WARUNKOWY PASS (POMINIĘTE BRAMKI CLI)',
    'Zadania #001–#412 i integralność plików są poprawne, ale bramki CLI nie zostały uruchomione.',
    AppColors.amberWarning,
    Icons.verified_user_outlined,
  ),
  blocked(
    'CERTYFIKACJA ZABLOKOWANA',
    'Wykryto braki w zadaniach, plikach lub bramkach jakości wymagające naprawy.',
    AppColors.crimsonAlert,
    Icons.gpp_bad_rounded,
  );

  final String title;
  final String description;
  final Color color;
  final IconData icon;

  const GoldMasterVerdict(
    this.title,
    this.description,
    this.color,
    this.icon,
  );
}

/// Pojedynczy problem zgłoszony przez bramkę `flutter analyze`.
@immutable
class GoldMasterAnalyzeIssue {
  final GoldMasterSeverity severity;
  final String message;
  final String filePath;
  final int line;
  final int column;
  final String ruleName;

  const GoldMasterAnalyzeIssue({
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
class GoldMasterAnalyzeGateResult {
  final bool executed;
  final int exitCode;
  final int errorCount;
  final int warningCount;
  final int infoCount;
  final bool noIssuesFound;
  final List<GoldMasterAnalyzeIssue> issues;
  final String rawOutput;
  final Duration duration;

  const GoldMasterAnalyzeGateResult({
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

  factory GoldMasterAnalyzeGateResult.skipped() =>
      const GoldMasterAnalyzeGateResult(
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
class GoldMasterTestSuiteGateResult {
  final bool executed;
  final int exitCode;
  final int totalPassed;
  final int totalFailed;
  final int totalSkipped;
  final List<String> failedTestNames;
  final String rawOutput;
  final Duration duration;

  const GoldMasterTestSuiteGateResult({
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

  factory GoldMasterTestSuiteGateResult.skipped() =>
      const GoldMasterTestSuiteGateResult(
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
class GoldMasterCodeMapGateResult {
  final bool exists;
  final int totalLines;
  final int registeredLibFilesCount;
  final List<String> missingTaskPaths;

  const GoldMasterCodeMapGateResult({
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

/// Wynik weryfikacji kluczowych filarów architektury i tras nawigacji Gold Master.
@immutable
class GoldMasterPillarCheck {
  final String id;
  final String title;
  final String targetPath;
  final bool passed;
  final String details;

  const GoldMasterPillarCheck({
    required this.id,
    required this.title,
    required this.targetPath,
    required this.passed,
    required this.details,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'targetPath': targetPath,
        'passed': passed,
        'details': details,
      };
}

/// Wynik weryfikacji pojedynczego zadania z zakresu #001–#412.
@immutable
class GoldMasterTaskVerificationEntry {
  final int taskNumber;
  final GoldMasterPackageId packageId;
  final bool completedInQueue;
  final String title;
  final String artifactPath;
  final bool artifactExists;
  final int artifactSizeBytes;
  final bool registeredInCodeMap;
  final int todoCount;
  final int unimplementedCount;
  final List<String> issues;

  const GoldMasterTaskVerificationEntry({
    required this.taskNumber,
    required this.packageId,
    required this.completedInQueue,
    required this.title,
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

  GoldMasterSeverity get severity {
    if (!artifactExists || !completedInQueue || unimplementedCount > 0) {
      return GoldMasterSeverity.error;
    }
    if ((requiresCodeMapRegistration && !registeredInCodeMap) ||
        todoCount > 0 ||
        issues.isNotEmpty) {
      return GoldMasterSeverity.warning;
    }
    return GoldMasterSeverity.pass;
  }

  Map<String, dynamic> toJson() => {
        'taskNumber': taskNumber,
        'packageId': packageId.name,
        'completedInQueue': completedInQueue,
        'title': title,
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

/// Zagregowane metryki dla jednej paczki zadań (#001–#412).
@immutable
class GoldMasterPackageSummary {
  final GoldMasterPackageId packageId;
  final int totalTasks;
  final int completedInQueue;
  final int existingArtifacts;
  final int passedTasks;

  const GoldMasterPackageSummary({
    required this.packageId,
    required this.totalTasks,
    required this.completedInQueue,
    required this.existingArtifacts,
    required this.passedTasks,
  });

  double get passRate => totalTasks == 0 ? 0.0 : passedTasks / totalTasks;

  bool get isComplete =>
      totalTasks == packageId.expectedCount && passedTasks == totalTasks;

  Map<String, dynamic> toJson() => {
        'packageId': packageId.name,
        'label': packageId.label,
        'totalTasks': totalTasks,
        'completedInQueue': completedInQueue,
        'existingArtifacts': existingArtifacts,
        'passedTasks': passedTasks,
        'passRate': passRate,
        'isComplete': isComplete,
      };
}

/// Kompletny raport certyfikacji GOLD MASTER v1.0 (#001–#412).
@immutable
class GoldMaster412Report {
  static const String releaseVersion = 'GOLD MASTER v1.0';
  static const int expectedTotalTasks = 412;

  final DateTime generatedAt;
  final String projectRoot;
  final List<GoldMasterTaskVerificationEntry> taskEntries;
  final List<GoldMasterPackageSummary> packageSummaries;
  final GoldMasterCodeMapGateResult codeMapResult;
  final List<GoldMasterPillarCheck> pillarChecks;
  final GoldMasterAnalyzeGateResult analyzeResult;
  final GoldMasterTestSuiteGateResult testSuiteResult;
  final Duration duration;

  const GoldMaster412Report({
    required this.generatedAt,
    required this.projectRoot,
    required this.taskEntries,
    required this.packageSummaries,
    required this.codeMapResult,
    required this.pillarChecks,
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
  int get passedPillarsCount => pillarChecks.where((p) => p.passed).length;

  bool get allTasksVerified =>
      totalTasksChecked == expectedTotalTasks && failedTasksCount == 0;

  bool get allPillarsPassed =>
      pillarChecks.isNotEmpty && passedPillarsCount == pillarChecks.length;

  bool get coreIntegrityPassed =>
      allTasksVerified && codeMapResult.passed && allPillarsPassed;

  bool get isFullyCertified =>
      coreIntegrityPassed &&
      (!analyzeResult.executed || analyzeResult.passed) &&
      (!testSuiteResult.executed || testSuiteResult.passed) &&
      analyzeResult.executed &&
      testSuiteResult.executed;

  GoldMasterVerdict get verdict {
    if (!coreIntegrityPassed) {
      return GoldMasterVerdict.blocked;
    }
    if ((analyzeResult.executed && !analyzeResult.passed) ||
        (testSuiteResult.executed && !testSuiteResult.passed)) {
      return GoldMasterVerdict.blocked;
    }
    if (!analyzeResult.executed || !testSuiteResult.executed) {
      return GoldMasterVerdict.conditionalPass;
    }
    return GoldMasterVerdict.certifiedGoldMaster;
  }

  double get readinessScorePercent {
    var earned = 0.0;
    const maxPoints = 100.0;

    // 55 pkt: zadania #001–#412
    earned += totalTasksChecked == 0
        ? 0.0
        : (passedTasksCount / expectedTotalTasks).clamp(0.0, 1.0) * 55.0;
    // 15 pkt: integralność CODE_MAP.md
    if (codeMapResult.passed) {
      earned += 15.0;
    }
    // 10 pkt: filary architektury i AppRouter
    if (pillarChecks.isNotEmpty) {
      earned += (passedPillarsCount / pillarChecks.length) * 10.0;
    }
    // 10 pkt: flutter analyze
    if (analyzeResult.passed) {
      earned += 10.0;
    } else if (!analyzeResult.executed) {
      earned += 0.0;
    }
    // 10 pkt: flutter test
    if (testSuiteResult.passed) {
      earned += 10.0;
    }
    return (earned / maxPoints * 100.0).clamp(0.0, 100.0);
  }

  Map<String, dynamic> toJson() => {
        'releaseVersion': releaseVersion,
        'generatedAt': generatedAt.toIso8601String(),
        'projectRoot': projectRoot,
        'verdict': verdict.name,
        'readinessScorePercent':
            double.parse(readinessScorePercent.toStringAsFixed(2)),
        'expectedTotalTasks': expectedTotalTasks,
        'totalTasksChecked': totalTasksChecked,
        'completedQueueTasks': completedQueueTasks,
        'existingArtifactsCount': existingArtifactsCount,
        'passedTasksCount': passedTasksCount,
        'failedTasksCount': failedTasksCount,
        'allTasksVerified': allTasksVerified,
        'isFullyCertified': isFullyCertified,
        'durationMs': duration.inMilliseconds,
        'packageSummaries': packageSummaries.map((e) => e.toJson()).toList(),
        'codeMapResult': codeMapResult.toJson(),
        'pillarChecks': pillarChecks.map((e) => e.toJson()).toList(),
        'analyzeResult': analyzeResult.toJson(),
        'testSuiteResult': testSuiteResult.toJson(),
        'failedTasks':
            taskEntries.where((e) => !e.passed).map((e) => e.toJson()).toList(),
      };

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());

  String toMarkdownCertificate() {
    final buf = StringBuffer()
      ..writeln('# Certyfikat $releaseVersion (#001–#412)')
      ..writeln()
      ..writeln('- **Werdykt**: ${verdict.title}')
      ..writeln(
        '- **Gotowość wydania**: ${readinessScorePercent.toStringAsFixed(1)}%',
      )
      ..writeln('- **Wygenerowano**: ${generatedAt.toIso8601String()}')
      ..writeln(
        '- **Zadania #001–#412**: $passedTasksCount / $expectedTotalTasks zaliczonych',
      )
      ..writeln(
        '- **CODE_MAP.md**: ${codeMapResult.passed ? "PASS" : "FAIL"} '
        '(${codeMapResult.registeredLibFilesCount} plików lib/)',
      )
      ..writeln(
        '- **Filary architektury**: $passedPillarsCount / ${pillarChecks.length}',
      )
      ..writeln(
        '- **flutter analyze**: '
        '${analyzeResult.executed ? (analyzeResult.passed ? "PASS (0 issues)" : "FAIL") : "SKIPPED"}',
      )
      ..writeln(
        '- **flutter test**: '
        '${testSuiteResult.executed ? (testSuiteResult.passed ? "PASS (${testSuiteResult.totalPassed} passed)" : "FAIL (${testSuiteResult.totalFailed} failed)") : "SKIPPED"}',
      )
      ..writeln()
      ..writeln('## Podsumowanie Paczek')
      ..writeln();

    for (final pkg in packageSummaries) {
      buf.writeln(
        '- **${pkg.packageId.label}**: ${pkg.passedTasks}/${pkg.totalTasks} '
        '(${(pkg.passRate * 100).toStringAsFixed(1)}%)',
      );
    }
    return buf.toString();
  }
}

/// Główny silnik certyfikacji **GOLD MASTER v1.0** dla zadań `#001–#412`.
class GoldMaster412CertificationSuite {
  const GoldMaster412CertificationSuite();

  static final RegExp _queueTaskRegex = RegExp(
    r'^\s*-\s*\[(x|X| )\]\s*\*\*Zadanie\s*#(\d{3})\*\*\s*\(([^)]+)\)\s*:\s*(.*)$',
  );
  static final RegExp _backtickPathRegex = RegExp(r'`([^`]+)`');
  static final RegExp _todoMarkerRegex = RegExp(
    r'//\s*TODO\b|//\s*FIXME\b',
    caseSensitive: false,
  );
  static final RegExp _unimplementedRegex = RegExp(r'\bUnimplementedError\b');
  static final RegExp _codeMapLibRegex = RegExp(r'`(lib/[^`]+\.dart)`');

  static const List<({String id, String title, String path, List<String> markers})>
      _pillarSpecs = [
    (
      id: 'router_pack5',
      title: 'AppRouter + Trasy Paczki #1–#5',
      path: 'lib/core/router/app_router.dart',
      markers: [
        'gravelWorldSeries',
        'olympicGames',
        'databaseEditor',
        'achievements',
        'preStagePaddock',
        'companionCar',
      ],
    ),
    (
      id: 'engine_bridge',
      title: 'Centralny Most Integracyjny Silnika',
      path: 'lib/engine/engine_integration_bridge.dart',
      markers: ['EngineIntegrationBridge'],
    ),
    (
      id: 'fuzz_tester',
      title: 'Fuzzer Serializacji Stanu Kariery JSON',
      path: 'lib/core/diagnostics/full_state_serialization_fuzz_tester.dart',
      markers: ['FullStateSerializationFuzzTester'],
    ),
    (
      id: 'nav_verifier',
      title: 'Weryfikator Nawigacji 30 Tras',
      path: 'lib/core/diagnostics/full_navigation_routes_verifier.dart',
      markers: ['FullNavigationRoutesVerifier'],
    ),
    (
      id: 'ui_auditor',
      title: 'Audytor Kontrastu WCAG i Typografii Inter',
      path: 'lib/core/diagnostics/ui_golden_contrast_and_font_auditor.dart',
      markers: ['UiGoldenContrastAndFontAuditor'],
    ),
    (
      id: 'leak_guard',
      title: 'Strażnik Pamięci Isolate i Strumieni',
      path: 'lib/core/diagnostics/memory_and_stream_leak_guard.dart',
      markers: ['MemoryAndStreamLeakGuard'],
    ),
  ];

  /// Uruchamia pełną certyfikację GOLD MASTER v1.0 (#001–#412).
  Future<GoldMaster412Report> runCertification({
    String? projectRoot,
    bool runFlutterAnalyze = false,
    bool runFlutterTest = false,
    Duration commandTimeout = const Duration(minutes: 4),
  }) async {
    final stopwatch = Stopwatch()..start();
    final root = _resolveProjectRoot(projectRoot);

    final queueFile = File(_joinPath(root, 'docs/QUEUE.md'));
    final codeMapFile = File(_joinPath(root, 'docs/CODE_MAP.md'));

    final registeredLibFiles = <String>{};
    var codeMapLines = 0;
    final codeMapExists = await codeMapFile.exists();
    if (codeMapExists) {
      final content = await codeMapFile.readAsString();
      codeMapLines = const LineSplitter().convert(content).length;
      for (final match in _codeMapLibRegex.allMatches(content)) {
        final path = match.group(1);
        if (path != null && path.isNotEmpty) {
          registeredLibFiles.add(path);
        }
      }
    }

    final taskEntries = await _verifyQueueTasks(
      root: root,
      queueFile: queueFile,
      registeredLibFiles: registeredLibFiles,
    );

    final missingInCodeMap = <String>[];
    for (final entry in taskEntries) {
      if (entry.requiresCodeMapRegistration &&
          entry.artifactExists &&
          !entry.registeredInCodeMap &&
          !missingInCodeMap.contains(entry.artifactPath)) {
        missingInCodeMap.add(entry.artifactPath);
      }
    }

    final codeMapResult = GoldMasterCodeMapGateResult(
      exists: codeMapExists,
      totalLines: codeMapLines,
      registeredLibFilesCount: registeredLibFiles.length,
      missingTaskPaths: missingInCodeMap,
    );

    final packageSummaries = _buildPackageSummaries(taskEntries);
    final pillarChecks = await _verifyPillars(root);

    final analyzeResult = runFlutterAnalyze
        ? await _runFlutterAnalyzeGate(root, timeout: commandTimeout)
        : GoldMasterAnalyzeGateResult.skipped();

    final testSuiteResult = runFlutterTest
        ? await _runFlutterTestGate(root, timeout: commandTimeout)
        : GoldMasterTestSuiteGateResult.skipped();

    stopwatch.stop();

    return GoldMaster412Report(
      generatedAt: DateTime.now().toUtc(),
      projectRoot: root,
      taskEntries: taskEntries,
      packageSummaries: packageSummaries,
      codeMapResult: codeMapResult,
      pillarChecks: pillarChecks,
      analyzeResult: analyzeResult,
      testSuiteResult: testSuiteResult,
      duration: stopwatch.elapsed,
    );
  }

  Future<List<GoldMasterTaskVerificationEntry>> _verifyQueueTasks({
    required String root,
    required File queueFile,
    required Set<String> registeredLibFiles,
  }) async {
    if (!await queueFile.exists()) {
      return const [];
    }

    final lines = await queueFile.readAsLines();
    final entries = <GoldMasterTaskVerificationEntry>[];
    final seenTasks = <int>{};

    for (final line in lines) {
      final match = _queueTaskRegex.firstMatch(line);
      if (match == null) continue;

      final statusChar = match.group(1) ?? ' ';
      final numberRaw = match.group(2) ?? '0';
      final pathSection = match.group(3) ?? '';
      final titleRaw = (match.group(4) ?? '').trim();

      final taskNumber = int.tryParse(numberRaw) ?? 0;
      if (taskNumber < 1 || taskNumber > GoldMaster412Report.expectedTotalTasks) {
        continue;
      }
      if (!seenTasks.add(taskNumber)) {
        continue;
      }

      final completed = statusChar.toLowerCase() == 'x';
      final pathMatch = _backtickPathRegex.firstMatch(pathSection);
      final artifactPath =
          (pathMatch?.group(1) ?? pathSection.replaceAll('`', '')).trim();

      final issues = <String>[];
      if (!completed) {
        issues.add('Zadanie nieoznaczone jako [x] w docs/QUEUE.md');
      }
      if (artifactPath.isEmpty) {
        issues.add('Brak ścieżki artefaktu w docs/QUEUE.md');
      }

      var exists = false;
      var sizeBytes = 0;
      var todoCount = 0;
      var unimplementedCount = 0;

      if (artifactPath.isNotEmpty) {
        final fullPath = _joinPath(root, artifactPath);
        final file = File(fullPath);
        if (await file.exists()) {
          exists = true;
          final stat = await file.stat();
          sizeBytes = stat.size;
          if (sizeBytes == 0) {
            issues.add('Plik docelowy jest pusty (0 B)');
          }
          if (artifactPath.endsWith('.dart')) {
            final content = await file.readAsString();
            // Pomijamy własną definicję wzorca regex w pliku audytora.
            final isCertificationFile = artifactPath ==
                    'lib/core/diagnostics/gold_master_412_certification_suite.dart' ||
                artifactPath ==
                    'lib/core/diagnostics/sniper_master_final_certification.dart';
            if (!isCertificationFile) {
              todoCount = _todoMarkerRegex.allMatches(content).length;
              unimplementedCount = _unimplementedRegex.allMatches(content).length;
              if (todoCount > 0) {
                issues.add('Wykryto $todoCount niedozwolonych markerów TODO/FIXME');
              }
              if (unimplementedCount > 0) {
                issues.add('Wykryto $unimplementedCount wystąpień UnimplementedError');
              }
            }
          }
        } else {
          issues.add('Brak pliku na dysku: $artifactPath');
        }
      }

      final requiresCodeMap = artifactPath.startsWith('lib/');
      final registeredInCodeMap =
          !requiresCodeMap || registeredLibFiles.contains(artifactPath);
      if (requiresCodeMap && exists && !registeredInCodeMap) {
        issues.add('Plik nie jest zarejestrowany w docs/CODE_MAP.md');
      }

      entries.add(
        GoldMasterTaskVerificationEntry(
          taskNumber: taskNumber,
          packageId: GoldMasterPackageId.fromTaskNumber(taskNumber),
          completedInQueue: completed,
          title: titleRaw,
          artifactPath: artifactPath,
          artifactExists: exists,
          artifactSizeBytes: sizeBytes,
          registeredInCodeMap: registeredInCodeMap,
          todoCount: todoCount,
          unimplementedCount: unimplementedCount,
          issues: issues,
        ),
      );
    }

    entries.sort((a, b) => a.taskNumber.compareTo(b.taskNumber));
    return entries;
  }

  List<GoldMasterPackageSummary> _buildPackageSummaries(
    List<GoldMasterTaskVerificationEntry> entries,
  ) {
    return GoldMasterPackageId.values.map((pkg) {
      final subset = entries.where((e) => e.packageId == pkg).toList();
      return GoldMasterPackageSummary(
        packageId: pkg,
        totalTasks: subset.length,
        completedInQueue: subset.where((e) => e.completedInQueue).length,
        existingArtifacts: subset.where((e) => e.artifactExists).length,
        passedTasks: subset.where((e) => e.passed).length,
      );
    }).toList();
  }

  Future<List<GoldMasterPillarCheck>> _verifyPillars(String root) async {
    final results = <GoldMasterPillarCheck>[];
    for (final spec in _pillarSpecs) {
      final file = File(_joinPath(root, spec.path));
      if (!await file.exists()) {
        results.add(
          GoldMasterPillarCheck(
            id: spec.id,
            title: spec.title,
            targetPath: spec.path,
            passed: false,
            details: 'Brak wymaganego pliku ${spec.path}',
          ),
        );
        continue;
      }

      final content = await file.readAsString();
      final missingMarkers =
          spec.markers.where((m) => !content.contains(m)).toList();
      if (missingMarkers.isNotEmpty) {
        results.add(
          GoldMasterPillarCheck(
            id: spec.id,
            title: spec.title,
            targetPath: spec.path,
            passed: false,
            details: 'Brak symboli: ${missingMarkers.join(', ')}',
          ),
        );
      } else {
        results.add(
          GoldMasterPillarCheck(
            id: spec.id,
            title: spec.title,
            targetPath: spec.path,
            passed: true,
            details: 'Zweryfikowano ${spec.markers.length} kluczowych symboli.',
          ),
        );
      }
    }
    return results;
  }

  Future<GoldMasterAnalyzeGateResult> _runFlutterAnalyzeGate(
    String root, {
    required Duration timeout,
  }) async {
    final sw = Stopwatch()..start();
    try {
      final result = await Process.run(
        Platform.isWindows ? 'flutter.bat' : 'flutter',
        const ['analyze', '--no-pub'],
        workingDirectory: root,
      ).timeout(timeout);
      sw.stop();

      final combined = '${result.stdout}\n${result.stderr}';
      final lines = const LineSplitter().convert(combined);
      final issues = <GoldMasterAnalyzeIssue>[];
      var errors = 0;
      var warnings = 0;
      var infos = 0;

      final issueRegex = RegExp(
        r'^\s*(error|warning|info)\s*•\s*(.+?)\s*•\s*(.+?):(\d+):(\d+)\s*•\s*(\S+)\s*$',
        caseSensitive: false,
      );

      for (final line in lines) {
        final m = issueRegex.firstMatch(line);
        if (m == null) continue;
        final kind = (m.group(1) ?? 'info').toLowerCase();
        final severity = switch (kind) {
          'error' => GoldMasterSeverity.error,
          'warning' => GoldMasterSeverity.warning,
          _ => GoldMasterSeverity.info,
        };
        if (severity == GoldMasterSeverity.error) errors++;
        if (severity == GoldMasterSeverity.warning) warnings++;
        if (severity == GoldMasterSeverity.info) infos++;

        issues.add(
          GoldMasterAnalyzeIssue(
            severity: severity,
            message: m.group(2) ?? '',
            filePath: m.group(3) ?? '',
            line: int.tryParse(m.group(4) ?? '0') ?? 0,
            column: int.tryParse(m.group(5) ?? '0') ?? 0,
            ruleName: m.group(6) ?? '',
          ),
        );
      }

      final noIssues = combined.contains('No issues found!');
      return GoldMasterAnalyzeGateResult(
        executed: true,
        exitCode: result.exitCode,
        errorCount: errors,
        warningCount: warnings,
        infoCount: infos,
        noIssuesFound: noIssues,
        issues: issues,
        rawOutput: combined.trim(),
        duration: sw.elapsed,
      );
    } catch (e) {
      sw.stop();
      return GoldMasterAnalyzeGateResult(
        executed: true,
        exitCode: -1,
        errorCount: 1,
        warningCount: 0,
        infoCount: 0,
        noIssuesFound: false,
        issues: [
          GoldMasterAnalyzeIssue(
            severity: GoldMasterSeverity.error,
            message: 'Wyjątek uruchamiania flutter analyze: $e',
            filePath: 'flutter analyze',
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

  Future<GoldMasterTestSuiteGateResult> _runFlutterTestGate(
    String root, {
    required Duration timeout,
  }) async {
    final sw = Stopwatch()..start();
    try {
      final result = await Process.run(
        Platform.isWindows ? 'flutter.bat' : 'flutter',
        const ['test', '--timeout', '30s'],
        workingDirectory: root,
      ).timeout(timeout);
      sw.stop();

      final combined = '${result.stdout}\n${result.stderr}';
      final summaryRegex = RegExp(
        r'\+(\d+)(?:\s+~(\d+))?(?:\s+-(\d+))?\s*:',
      );
      var passed = 0;
      var skipped = 0;
      var failed = 0;
      for (final match in summaryRegex.allMatches(combined)) {
        passed = int.tryParse(match.group(1) ?? '0') ?? passed;
        skipped = int.tryParse(match.group(2) ?? '0') ?? skipped;
        failed = int.tryParse(match.group(3) ?? '0') ?? failed;
      }

      final failedNames = <String>[];
      for (final line in const LineSplitter().convert(combined)) {
        if (line.contains('[E]')) {
          failedNames.add(line.trim());
        }
      }

      return GoldMasterTestSuiteGateResult(
        executed: true,
        exitCode: result.exitCode,
        totalPassed: passed,
        totalFailed: failed,
        totalSkipped: skipped,
        failedTestNames: failedNames,
        rawOutput: combined.trim(),
        duration: sw.elapsed,
      );
    } catch (e) {
      sw.stop();
      return GoldMasterTestSuiteGateResult(
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
    final normalizedRoot =
        root.replaceAll('\\', '/').replaceAll(RegExp(r'/$'), '');
    final normalizedRel =
        relative.replaceAll('\\', '/').replaceAll(RegExp(r'^/'), '');
    return '$normalizedRoot/$normalizedRel';
  }
}

/// Stan certyfikacji GOLD MASTER v1.0 w Riverpod.
@immutable
class GoldMaster412State {
  final bool isRunning;
  final GoldMaster412Report? report;
  final String? errorMessage;
  final String? exportNotice;
  final bool runAnalyzeGate;
  final bool runTestGate;
  final GoldMasterPackageId? selectedPackageFilter;
  final bool onlyFailedFilter;
  final String searchQuery;

  const GoldMaster412State({
    this.isRunning = false,
    this.report,
    this.errorMessage,
    this.exportNotice,
    this.runAnalyzeGate = false,
    this.runTestGate = false,
    this.selectedPackageFilter,
    this.onlyFailedFilter = false,
    this.searchQuery = '',
  });

  GoldMaster412State copyWith({
    bool? isRunning,
    GoldMaster412Report? report,
    String? errorMessage,
    bool clearError = false,
    String? exportNotice,
    bool clearExportNotice = false,
    bool? runAnalyzeGate,
    bool? runTestGate,
    GoldMasterPackageId? selectedPackageFilter,
    bool clearPackageFilter = false,
    bool? onlyFailedFilter,
    String? searchQuery,
  }) {
    return GoldMaster412State(
      isRunning: isRunning ?? this.isRunning,
      report: report ?? this.report,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      exportNotice:
          clearExportNotice ? null : (exportNotice ?? this.exportNotice),
      runAnalyzeGate: runAnalyzeGate ?? this.runAnalyzeGate,
      runTestGate: runTestGate ?? this.runTestGate,
      selectedPackageFilter: clearPackageFilter
          ? null
          : (selectedPackageFilter ?? this.selectedPackageFilter),
      onlyFailedFilter: onlyFailedFilter ?? this.onlyFailedFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// Notifier zarządzający procesem certyfikacji GOLD MASTER v1.0 (#001–#412).
class GoldMaster412CertificationNotifier
    extends StateNotifier<GoldMaster412State> {
  final GoldMaster412CertificationSuite _suite;

  GoldMaster412CertificationNotifier([
    this._suite = const GoldMaster412CertificationSuite(),
  ]) : super(const GoldMaster412State());

  void setRunAnalyzeGate(bool value) {
    state = state.copyWith(runAnalyzeGate: value, clearExportNotice: true);
  }

  void setRunTestGate(bool value) {
    state = state.copyWith(runTestGate: value, clearExportNotice: true);
  }

  void setPackageFilter(GoldMasterPackageId? packageId) {
    if (packageId == null) {
      state = state.copyWith(clearPackageFilter: true);
    } else {
      state = state.copyWith(selectedPackageFilter: packageId);
    }
  }

  void setOnlyFailedFilter(bool value) {
    state = state.copyWith(onlyFailedFilter: value);
  }

  void setSearchQuery(String value) {
    state = state.copyWith(searchQuery: value);
  }

  Future<void> runCertification({String? projectRoot}) async {
    if (state.isRunning) return;
    state = state.copyWith(
      isRunning: true,
      clearError: true,
      clearExportNotice: true,
    );
    try {
      final report = await _suite.runCertification(
        projectRoot: projectRoot,
        runFlutterAnalyze: state.runAnalyzeGate,
        runFlutterTest: state.runTestGate,
      );
      state = state.copyWith(isRunning: false, report: report);
    } catch (e) {
      state = state.copyWith(
        isRunning: false,
        errorMessage: 'Błąd certyfikacji GOLD MASTER v1.0: $e',
      );
    }
  }

  Future<void> copyJsonReportToClipboard() async {
    final report = state.report;
    if (report == null) return;
    await Clipboard.setData(ClipboardData(text: report.toPrettyJson()));
    state = state.copyWith(
      exportNotice: 'Skopiowano raport JSON GOLD MASTER v1.0 do schowka.',
    );
  }

  Future<void> copyMarkdownCertificateToClipboard() async {
    final report = state.report;
    if (report == null) return;
    await Clipboard.setData(
      ClipboardData(text: report.toMarkdownCertificate()),
    );
    state = state.copyWith(
      exportNotice: 'Skopiowano certyfikat Markdown GOLD MASTER v1.0.',
    );
  }
}

/// Provider Riverpod dla pakietu certyfikacji GOLD MASTER v1.0 (#001–#412).
final goldMaster412CertificationProvider = StateNotifierProvider<
    GoldMaster412CertificationNotifier, GoldMaster412State>(
  (ref) => GoldMaster412CertificationNotifier(),
);

/// Produkcyjny panel UI certyfikacji GOLD MASTER v1.0 (#001–#412).
///
/// Obsługuje układy responsywne `390x844`, `1024x768` i `1600x900` przez
/// `LayoutBuilder`, pełne stany `hover`/`active`/`disabled`/`focus`, paletę
/// `AppColors` oraz typografię `Inter` z `tabularFigures`.
class GoldMaster412CertificationPanel extends ConsumerStatefulWidget {
  final String? projectRoot;

  const GoldMaster412CertificationPanel({
    super.key,
    this.projectRoot,
  });

  @override
  ConsumerState<GoldMaster412CertificationPanel> createState() =>
      _GoldMaster412CertificationPanelState();
}

class _GoldMaster412CertificationPanelState
    extends ConsumerState<GoldMaster412CertificationPanel> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(goldMaster412CertificationProvider);
    final notifier = ref.read(goldMaster412CertificationProvider.notifier);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMobile = width < 640;
        final isTablet = width >= 640 && width < 1180;
        final horizontalPadding = isMobile ? 12.0 : 20.0;

        return Container(
          color: AppColors.background,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderCard(
                  context: context,
                  state: state,
                  notifier: notifier,
                  isMobile: isMobile,
                ),
                const SizedBox(height: 16),
                if (state.errorMessage != null) ...[
                  _buildBanner(
                    icon: Icons.error_outline_rounded,
                    color: AppColors.crimsonAlert,
                    message: state.errorMessage!,
                  ),
                  const SizedBox(height: 16),
                ],
                if (state.exportNotice != null) ...[
                  _buildBanner(
                    icon: Icons.check_circle_outline_rounded,
                    color: AppColors.statusSuccess,
                    message: state.exportNotice!,
                  ),
                  const SizedBox(height: 16),
                ],
                if (state.report == null)
                  _buildEmptyStateCard(notifier: notifier, isRunning: state.isRunning)
                else ...[
                  _buildVerdictAndKpiSection(
                    report: state.report!,
                    isMobile: isMobile,
                    isTablet: isTablet,
                  ),
                  const SizedBox(height: 16),
                  if (!isMobile && !isTablet)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: _buildPackageBreakdownCard(state.report!),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 7,
                          child: _buildGatesAndPillarsCard(state.report!),
                        ),
                      ],
                    )
                  else ...[
                    _buildPackageBreakdownCard(state.report!),
                    const SizedBox(height: 16),
                    _buildGatesAndPillarsCard(state.report!),
                  ],
                  const SizedBox(height: 16),
                  _buildTaskAuditCard(
                    state: state,
                    notifier: notifier,
                    report: state.report!,
                    isMobile: isMobile,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderCard({
    required BuildContext context,
    required GoldMaster412State state,
    required GoldMaster412CertificationNotifier notifier,
    required bool isMobile,
  }) {
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.goldAccent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.goldAccent.withValues(alpha: 0.45),
                ),
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: AppColors.goldAccent,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'GOLD MASTER v1.0 — Pakiet Certyfikacji (#001–#412)',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isMobile ? 16 : 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Kompleksowa weryfikacja 412 zadań kolejki, spójności docs/CODE_MAP.md, '
          'kluczowych filarów silnika oraz bramek flutter analyze i flutter test.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );

    final controlsBlock = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _GoldMasterToggleChip(
          label: 'flutter analyze',
          icon: Icons.rule_rounded,
          selected: state.runAnalyzeGate,
          enabled: !state.isRunning,
          onToggle: () => notifier.setRunAnalyzeGate(!state.runAnalyzeGate),
        ),
        _GoldMasterToggleChip(
          label: 'flutter test',
          icon: Icons.science_rounded,
          selected: state.runTestGate,
          enabled: !state.isRunning,
          onToggle: () => notifier.setRunTestGate(!state.runTestGate),
        ),
        _GoldMasterActionButton(
          label: state.isRunning ? 'Certyfikacja...' : 'Uruchom Certyfikację',
          icon: state.isRunning ? Icons.hourglass_top_rounded : Icons.play_arrow_rounded,
          accentColor: AppColors.goldAccent,
          foregroundColor: Colors.black,
          enabled: !state.isRunning,
          onPressed: () =>
              notifier.runCertification(projectRoot: widget.projectRoot),
        ),
        if (state.report != null) ...[
          _GoldMasterActionButton(
            label: 'JSON',
            icon: Icons.data_object_rounded,
            accentColor: AppColors.surfaceLight,
            foregroundColor: AppColors.textPrimary,
            enabled: !state.isRunning,
            onPressed: notifier.copyJsonReportToClipboard,
          ),
          _GoldMasterActionButton(
            label: 'Certyfikat MD',
            icon: Icons.description_outlined,
            accentColor: AppColors.primaryAccent,
            foregroundColor: AppColors.textPrimary,
            enabled: !state.isRunning,
            onPressed: notifier.copyMarkdownCertificateToClipboard,
          ),
        ],
      ],
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                titleBlock,
                const SizedBox(height: 14),
                controlsBlock,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: titleBlock),
                const SizedBox(width: 20),
                Flexible(child: controlsBlock),
              ],
            ),
    );
  }

  Widget _buildBanner({
    required IconData icon,
    required Color color,
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
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

  Widget _buildEmptyStateCard({
    required GoldMaster412CertificationNotifier notifier,
    required bool isRunning,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.verified_outlined,
            size: 44,
            color: AppColors.goldAccent,
          ),
          const SizedBox(height: 12),
          const Text(
            'Gotowy do certyfikacji wydania GOLD MASTER v1.0',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Uruchom audyt, aby zweryfikować zadania #001–#412, rejestrację plików '
            'w CODE_MAP.md oraz stan filarów architektury.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          _GoldMasterActionButton(
            label: isRunning ? 'Weryfikacja w toku...' : 'Rozpocznij Audyt #001–#412',
            icon: Icons.rocket_launch_rounded,
            accentColor: AppColors.goldAccent,
            foregroundColor: Colors.black,
            enabled: !isRunning,
            onPressed: () =>
                notifier.runCertification(projectRoot: widget.projectRoot),
          ),
        ],
      ),
    );
  }

  Widget _buildVerdictAndKpiSection({
    required GoldMaster412Report report,
    required bool isMobile,
    required bool isTablet,
  }) {
    final verdict = report.verdict;
    final columns = isMobile ? 2 : (isTablet ? 3 : 4);

    final kpis = [
      (
        label: 'Zadania #001–#412',
        value: '${report.passedTasksCount}/${GoldMaster412Report.expectedTotalTasks}',
        sub: '${report.failedTasksCount} błędów',
        color: report.allTasksVerified
            ? AppColors.statusSuccess
            : AppColors.crimsonAlert,
      ),
      (
        label: 'Gotowość Wydania',
        value: '${report.readinessScorePercent.toStringAsFixed(1)}%',
        sub: verdict.title,
        color: verdict.color,
      ),
      (
        label: 'CODE_MAP.md',
        value: '${report.codeMapResult.registeredLibFilesCount} plików',
        sub: report.codeMapResult.passed
            ? '100% spójności'
            : '${report.codeMapResult.missingTaskPaths.length} braków',
        color: report.codeMapResult.passed
            ? AppColors.statusSuccess
            : AppColors.amberWarning,
      ),
      (
        label: 'Czas Audytu',
        value: '${report.duration.inMilliseconds} ms',
        sub: 'Filary ${report.passedPillarsCount}/${report.pillarChecks.length}',
        color: AppColors.accentBlue,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: verdict.color.withValues(alpha: 0.6)),
          ),
          child: Row(
            children: [
              Icon(verdict.icon, color: verdict.color, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      verdict.title,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: verdict.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      verdict.description,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, inner) {
            const spacing = 12.0;
            final cardWidth =
                (inner.maxWidth - spacing * (columns - 1)) / columns;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: kpis
                  .map(
                    (kpi) => SizedBox(
                      width: cardWidth,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              kpi.label,
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
                              kpi.value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: kpi.color,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              kpi.sub,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPackageBreakdownCard(GoldMaster412Report report) {
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
            'Rozkład Paczek (#001–#412)',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          for (final pkg in report.packageSummaries) ...[
            _PackageProgressRow(summary: pkg),
            if (pkg != report.packageSummaries.last) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _buildGatesAndPillarsCard(GoldMaster412Report report) {
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
            'Bramki Jakości & Filary GOLD MASTER',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _GateStatusRow(
            title: 'flutter analyze (--no-pub)',
            statusText: !report.analyzeResult.executed
                ? 'Pominięto'
                : (report.analyzeResult.passed
                    ? 'PASS (0 issues)'
                    : 'FAIL (${report.analyzeResult.errorCount}E / ${report.analyzeResult.warningCount}W)'),
            color: !report.analyzeResult.executed
                ? AppColors.amberWarning
                : (report.analyzeResult.passed
                    ? AppColors.statusSuccess
                    : AppColors.crimsonAlert),
          ),
          const SizedBox(height: 8),
          _GateStatusRow(
            title: 'flutter test (--timeout 30s)',
            statusText: !report.testSuiteResult.executed
                ? 'Pominięto'
                : (report.testSuiteResult.passed
                    ? 'PASS (${report.testSuiteResult.totalPassed} testów)'
                    : 'FAIL (${report.testSuiteResult.totalFailed} błędów)'),
            color: !report.testSuiteResult.executed
                ? AppColors.amberWarning
                : (report.testSuiteResult.passed
                    ? AppColors.statusSuccess
                    : AppColors.crimsonAlert),
          ),
          const Divider(color: AppTheme.borderColor, height: 22),
          for (final pillar in report.pillarChecks) ...[
            _GateStatusRow(
              title: pillar.title,
              subtitle: pillar.details,
              statusText: pillar.passed ? 'OK' : 'BRAK',
              color: pillar.passed
                  ? AppColors.statusSuccess
                  : AppColors.crimsonAlert,
            ),
            if (pillar != report.pillarChecks.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildTaskAuditCard({
    required GoldMaster412State state,
    required GoldMaster412CertificationNotifier notifier,
    required GoldMaster412Report report,
    required bool isMobile,
  }) {
    final query = state.searchQuery.trim().toLowerCase();
    final filtered = report.taskEntries.where((entry) {
      if (state.selectedPackageFilter != null &&
          entry.packageId != state.selectedPackageFilter) {
        return false;
      }
      if (state.onlyFailedFilter && entry.passed) {
        return false;
      }
      if (query.isNotEmpty) {
        final haystack =
            '#${entry.taskNumber.toString().padLeft(3, '0')} ${entry.title} ${entry.artifactPath}'
                .toLowerCase();
        if (!haystack.contains(query)) return false;
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Rejestr Weryfikacji Zadań',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${filtered.length} / ${report.totalTasksChecked}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: isMobile ? double.infinity : 260,
                child: TextField(
                  controller: _searchController,
                  onChanged: notifier.setSearchQuery,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Szukaj #412, nazwy lub ścieżki...',
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
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.borderColor),
                    ),
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
              ),
              _GoldMasterFilterChip(
                label: 'Wszystkie',
                selected: state.selectedPackageFilter == null,
                onTap: () => notifier.setPackageFilter(null),
              ),
              for (final pkg in GoldMasterPackageId.values)
                _GoldMasterFilterChip(
                  label: pkg.label.split(' ').first,
                  selected: state.selectedPackageFilter == pkg,
                  onTap: () => notifier.setPackageFilter(pkg),
                ),
              _GoldMasterFilterChip(
                label: 'Tylko błędy',
                selected: state.onlyFailedFilter,
                onTap: () =>
                    notifier.setOnlyFailedFilter(!state.onlyFailedFilter),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Brak zadań spełniających wybrane kryteria filtrowania.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length > 60 ? 60 : filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) =>
                  _TaskVerificationRow(entry: filtered[index]),
            ),
        ],
      ),
    );
  }
}

class _PackageProgressRow extends StatelessWidget {
  final GoldMasterPackageSummary summary;

  const _PackageProgressRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    final pct = (summary.passRate * 100).clamp(0.0, 100.0);
    final barColor = summary.isComplete
        ? AppColors.statusSuccess
        : (pct >= 80 ? AppColors.amberWarning : AppColors.crimsonAlert);

    return Container(
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
              Icon(summary.packageId.icon, size: 16, color: barColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  summary.packageId.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${summary.passedTasks}/${summary.totalTasks}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: barColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: summary.passRate.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.background,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _GateStatusRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String statusText;
  final Color color;

  const _GateStatusRow({
    required this.title,
    this.subtitle,
    required this.statusText,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.45)),
          ),
          child: Text(
            statusText,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

class _TaskVerificationRow extends StatelessWidget {
  final GoldMasterTaskVerificationEntry entry;

  const _TaskVerificationRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final severity = entry.severity;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: entry.passed
              ? AppTheme.borderColor
              : severity.color.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: severity.color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '#${entry.taskNumber.toString().padLeft(3, '0')}',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: severity.color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.artifactPath.isEmpty
                      ? 'Brak ścieżki'
                      : entry.artifactPath,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (entry.issues.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      entry.issues.join(' • '),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        color: severity.color,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            entry.passed ? 'PASS' : severity.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: severity.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoldMasterActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final Color foregroundColor;
  final bool enabled;
  final VoidCallback onPressed;

  const _GoldMasterActionButton({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.foregroundColor,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_GoldMasterActionButton> createState() =>
      _GoldMasterActionButtonState();
}

class _GoldMasterActionButtonState extends State<_GoldMasterActionButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = !widget.enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.5)
        : _pressed
            ? widget.accentColor.withValues(alpha: 0.8)
            : _hovered
                ? widget.accentColor.withValues(alpha: 0.92)
                : widget.accentColor;

    final fgColor =
        widget.enabled ? widget.foregroundColor : AppColors.textSecondary;

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor:
          widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (widget.enabled) widget.onPressed();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled
            ? (_) {
                setState(() => _pressed = false);
                widget.onPressed();
              }
            : null,
        onTapCancel:
            widget.enabled ? () => setState(() => _pressed = false) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focused
                  ? AppColors.cyanAccent
                  : AppTheme.borderColor,
              width: _focused ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 17, color: fgColor),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: fgColor,
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

class _GoldMasterToggleChip extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onToggle;

  const _GoldMasterToggleChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onToggle,
  });

  @override
  State<_GoldMasterToggleChip> createState() => _GoldMasterToggleChipState();
}

class _GoldMasterToggleChipState extends State<_GoldMasterToggleChip> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.selected
        ? AppColors.primaryAccent.withValues(alpha: _pressed ? 0.4 : 0.28)
        : (_hovered ? AppColors.surfaceLight : AppColors.background);

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor:
          widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (widget.enabled) widget.onToggle();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled
            ? (_) {
                setState(() => _pressed = false);
                widget.onToggle();
              }
            : null,
        onTapCancel:
            widget.enabled ? () => setState(() => _pressed = false) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: widget.enabled
                ? activeColor
                : AppColors.surfaceLight.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focused
                  ? AppColors.cyanAccent
                  : (widget.selected
                      ? AppColors.goldAccent
                      : AppTheme.borderColor),
              width: _focused ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 15,
                color: widget.selected
                    ? AppColors.goldAccent
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: widget.selected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
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

class _GoldMasterFilterChip extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GoldMasterFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_GoldMasterFilterChip> createState() => _GoldMasterFilterChipState();
}

class _GoldMasterFilterChipState extends State<_GoldMasterFilterChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor: SystemMouseCursors.click,
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: widget.selected
                ? AppColors.goldAccent.withValues(alpha: 0.2)
                : (_hovered ? AppColors.surfaceLight : AppColors.background),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _focused
                  ? AppColors.cyanAccent
                  : (widget.selected
                      ? AppColors.goldAccent
                      : AppTheme.borderColor),
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
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
