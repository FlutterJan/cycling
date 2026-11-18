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

/// Identyfikator etapu / paczki zadań objętych certyfikacją DIAMOND MASTER v2.0 (#001–#562).
enum DiamondMasterPackageId {
  foundation('Fundament (#001–#162)', 1, 162, Icons.foundation_rounded),
  package1('Paczka #1 (#163–#212)', 163, 212, Icons.view_in_ar_rounded),
  package2('Paczka #2 (#213–#262)', 213, 262, Icons.speed_rounded),
  package3('Paczka #3 (#263–#312)', 263, 312, Icons.verified_rounded),
  package4('Paczka #4 (#313–#362)', 313, 362, Icons.directions_bike_rounded),
  package5('Paczka #5 (#363–#412)', 363, 412, Icons.workspace_premium_rounded),
  package6('Paczka #6 (#413–#462)', 413, 462, Icons.public_rounded),
  package7A('Paczka #7A (#463–#512)', 463, 512, Icons.gavel_rounded),
  package7B('Paczka #7B (#513–#562)', 513, 562, Icons.diamond_rounded);

  final String label;
  final int startTask;
  final int endTask;
  final IconData icon;

  const DiamondMasterPackageId(
    this.label,
    this.startTask,
    this.endTask,
    this.icon,
  );

  int get expectedCount => endTask - startTask + 1;

  static DiamondMasterPackageId fromTaskNumber(int taskNumber) {
    for (final pkg in values) {
      if (taskNumber >= pkg.startTask && taskNumber <= pkg.endTask) {
        return pkg;
      }
    }
    return foundation;
  }
}

/// Poziom ważności wyniku bramki lub zadania certyfikacji DIAMOND MASTER v2.0.
enum DiamondMasterSeverity {
  pass('OK', AppColors.statusSuccess),
  info('Info', AppColors.accentBlue),
  warning('Ostrzeżenie', AppColors.amberWarning),
  error('Błąd', AppColors.crimsonAlert);

  final String label;
  final Color color;

  const DiamondMasterSeverity(this.label, this.color);
}

/// Finalny werdykt certyfikacji DIAMOND MASTER v2.0 (#001–#562).
enum DiamondMasterVerdict {
  certifiedDiamondMaster(
    'DIAMOND MASTER v2.0 CERTIFIED',
    'Wszystkie 562 zadania, mapa kodu, filary architektury i bramki jakości przeszły weryfikację.',
    AppColors.cyanAccent,
    Icons.diamond_rounded,
  ),
  conditionalPass(
    'WARUNKOWY PASS (POMINIĘTE BRAMKI CLI)',
    'Zadania #001–#562 i integralność plików są poprawne, ale bramki CLI nie zostały uruchomione.',
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

  const DiamondMasterVerdict(
    this.title,
    this.description,
    this.color,
    this.icon,
  );
}

/// Pojedynczy problem zgłoszony przez bramkę `flutter analyze`.
@immutable
class DiamondMasterAnalyzeIssue {
  final DiamondMasterSeverity severity;
  final String message;
  final String filePath;
  final int line;
  final int column;
  final String ruleName;

  const DiamondMasterAnalyzeIssue({
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
class DiamondMasterAnalyzeGateResult {
  final bool executed;
  final int exitCode;
  final int errorCount;
  final int warningCount;
  final int infoCount;
  final bool noIssuesFound;
  final List<DiamondMasterAnalyzeIssue> issues;
  final String rawOutput;
  final Duration duration;

  const DiamondMasterAnalyzeGateResult({
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
      infoCount == 0;

  factory DiamondMasterAnalyzeGateResult.skipped() =>
      const DiamondMasterAnalyzeGateResult(
        executed: false,
        exitCode: -1,
        errorCount: 0,
        warningCount: 0,
        infoCount: 0,
        noIssuesFound: false,
        issues: [],
        rawOutput: 'Pominięto (tryb szybki bez CLI).',
        duration: Duration.zero,
      );

  Map<String, dynamic> toJson() => {
        'executed': executed,
        'passed': passed,
        'exitCode': exitCode,
        'errorCount': errorCount,
        'warningCount': warningCount,
        'infoCount': infoCount,
        'noIssuesFound': noIssuesFound,
        'durationMs': duration.inMilliseconds,
        'issues': issues.map((e) => e.toJson()).toList(),
      };
}

/// Wynik bramki testów automatycznych `flutter test`.
@immutable
class DiamondMasterTestSuiteGateResult {
  final bool executed;
  final int exitCode;
  final int totalPassed;
  final int totalFailed;
  final int totalSkipped;
  final String summaryLine;
  final String rawOutput;
  final Duration duration;

  const DiamondMasterTestSuiteGateResult({
    required this.executed,
    required this.exitCode,
    required this.totalPassed,
    required this.totalFailed,
    required this.totalSkipped,
    required this.summaryLine,
    required this.rawOutput,
    required this.duration,
  });

  bool get passed => executed && exitCode == 0 && totalFailed == 0;

  factory DiamondMasterTestSuiteGateResult.skipped() =>
      const DiamondMasterTestSuiteGateResult(
        executed: false,
        exitCode: -1,
        totalPassed: 0,
        totalFailed: 0,
        totalSkipped: 0,
        summaryLine: 'Pominięto (tryb szybki bez CLI).',
        rawOutput: 'Pominięto (tryb szybki bez CLI).',
        duration: Duration.zero,
      );

  Map<String, dynamic> toJson() => {
        'executed': executed,
        'passed': passed,
        'exitCode': exitCode,
        'totalPassed': totalPassed,
        'totalFailed': totalFailed,
        'totalSkipped': totalSkipped,
        'summaryLine': summaryLine,
        'durationMs': duration.inMilliseconds,
      };
}

/// Wynik weryfikacji spójności pliku `docs/CODE_MAP.md`.
@immutable
class DiamondMasterCodeMapGateResult {
  final bool exists;
  final int totalLines;
  final int registeredLibFilesCount;
  final List<String> missingTaskPaths;

  const DiamondMasterCodeMapGateResult({
    required this.exists,
    required this.totalLines,
    required this.registeredLibFilesCount,
    required this.missingTaskPaths,
  });

  bool get passed => exists && missingTaskPaths.isEmpty;

  Map<String, dynamic> toJson() => {
        'exists': exists,
        'passed': passed,
        'totalLines': totalLines,
        'registeredLibFilesCount': registeredLibFilesCount,
        'missingTaskPaths': missingTaskPaths,
      };
}

/// Wynik weryfikacji kluczowego filaru architektury gry.
@immutable
class DiamondMasterPillarCheck {
  final String id;
  final String title;
  final String filePath;
  final bool fileExists;
  final bool symbolsPresent;
  final List<String> missingSymbols;

  const DiamondMasterPillarCheck({
    required this.id,
    required this.title,
    required this.filePath,
    required this.fileExists,
    required this.symbolsPresent,
    required this.missingSymbols,
  });

  bool get passed => fileExists && symbolsPresent;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'filePath': filePath,
        'fileExists': fileExists,
        'symbolsPresent': symbolsPresent,
        'passed': passed,
        'missingSymbols': missingSymbols,
      };
}

/// Szczegółowy wynik weryfikacji pojedynczego zadania z zakresu `#001–#562`.
@immutable
class DiamondMasterTaskVerificationEntry {
  final int taskNumber;
  final DiamondMasterPackageId packageId;
  final String artifactPath;
  final String description;
  final bool completedInQueue;
  final bool artifactExists;
  final bool registeredInCodeMap;
  final bool requiresCodeMapRegistration;
  final int todoMarkersCount;
  final int unimplementedCount;
  final int lineCount;

  const DiamondMasterTaskVerificationEntry({
    required this.taskNumber,
    required this.packageId,
    required this.artifactPath,
    required this.description,
    required this.completedInQueue,
    required this.artifactExists,
    required this.registeredInCodeMap,
    required this.requiresCodeMapRegistration,
    required this.todoMarkersCount,
    required this.unimplementedCount,
    required this.lineCount,
  });

  bool get cleanOfPlaceholders =>
      todoMarkersCount == 0 && unimplementedCount == 0;

  bool get passed =>
      completedInQueue &&
      artifactExists &&
      cleanOfPlaceholders &&
      (!requiresCodeMapRegistration || registeredInCodeMap);

  String get formattedNumber => '#${taskNumber.toString().padLeft(3, '0')}';

  List<String> get failureReasons {
    final reasons = <String>[];
    if (!completedInQueue) {
      reasons.add('Niezaznaczone w QUEUE.md');
    }
    if (!artifactExists) {
      reasons.add('Brak pliku $artifactPath');
    }
    if (todoMarkersCount > 0) {
      reasons.add('Znaleziono TODO/FIXME ($todoMarkersCount)');
    }
    if (unimplementedCount > 0) {
      reasons.add('Znaleziono UnimplementedError ($unimplementedCount)');
    }
    if (requiresCodeMapRegistration && !registeredInCodeMap) {
      reasons.add('Brak wpisu w CODE_MAP.md');
    }
    return reasons;
  }

  Map<String, dynamic> toJson() => {
        'taskNumber': taskNumber,
        'formattedNumber': formattedNumber,
        'packageId': packageId.name,
        'artifactPath': artifactPath,
        'completedInQueue': completedInQueue,
        'artifactExists': artifactExists,
        'registeredInCodeMap': registeredInCodeMap,
        'requiresCodeMapRegistration': requiresCodeMapRegistration,
        'todoMarkersCount': todoMarkersCount,
        'unimplementedCount': unimplementedCount,
        'lineCount': lineCount,
        'passed': passed,
        'failureReasons': failureReasons,
      };
}

/// Zbiorcze podsumowanie dla pojedynczej paczki zadań.
@immutable
class DiamondMasterPackageSummary {
  final DiamondMasterPackageId packageId;
  final int totalTasks;
  final int completedQueueTasks;
  final int existingArtifacts;
  final int passedTasks;

  const DiamondMasterPackageSummary({
    required this.packageId,
    required this.totalTasks,
    required this.completedQueueTasks,
    required this.existingArtifacts,
    required this.passedTasks,
  });

  double get passRate => totalTasks == 0 ? 0.0 : passedTasks / totalTasks;

  bool get allPassed => totalTasks > 0 && passedTasks == totalTasks;

  Map<String, dynamic> toJson() => {
        'packageId': packageId.name,
        'label': packageId.label,
        'expectedCount': packageId.expectedCount,
        'totalTasks': totalTasks,
        'completedQueueTasks': completedQueueTasks,
        'existingArtifacts': existingArtifacts,
        'passedTasks': passedTasks,
        'passRate': double.parse(passRate.toStringAsFixed(4)),
        'allPassed': allPassed,
      };
}

/// Kompletny raport certyfikacji **DIAMOND MASTER v2.0** (#001–#562).
@immutable
class DiamondMaster562Report {
  static const String releaseVersion = 'DIAMOND MASTER v2.0';
  static const int expectedTotalTasks = 562;

  final DateTime generatedAt;
  final String projectRoot;
  final List<DiamondMasterTaskVerificationEntry> taskEntries;
  final List<DiamondMasterPackageSummary> packageSummaries;
  final DiamondMasterCodeMapGateResult codeMapResult;
  final List<DiamondMasterPillarCheck> pillarChecks;
  final DiamondMasterAnalyzeGateResult analyzeResult;
  final DiamondMasterTestSuiteGateResult testSuiteResult;
  final Duration duration;

  const DiamondMaster562Report({
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
      totalTasksChecked > 0 && failedTasksCount == 0;

  bool get allPillarsPassed =>
      pillarChecks.isNotEmpty && passedPillarsCount == pillarChecks.length;

  bool get coreIntegrityPassed =>
      allTasksVerified && codeMapResult.passed && allPillarsPassed;

  bool get isFullyCertified =>
      coreIntegrityPassed &&
      analyzeResult.executed &&
      analyzeResult.passed &&
      testSuiteResult.executed &&
      testSuiteResult.passed;

  DiamondMasterVerdict get verdict {
    if (!coreIntegrityPassed) {
      return DiamondMasterVerdict.blocked;
    }
    if ((analyzeResult.executed && !analyzeResult.passed) ||
        (testSuiteResult.executed && !testSuiteResult.passed)) {
      return DiamondMasterVerdict.blocked;
    }
    if (!analyzeResult.executed || !testSuiteResult.executed) {
      return DiamondMasterVerdict.conditionalPass;
    }
    return DiamondMasterVerdict.certifiedDiamondMaster;
  }

  double get readinessScorePercent {
    var earned = 0.0;
    const maxPoints = 100.0;

    // 55 pkt: zadania #001–#562
    earned += totalTasksChecked == 0
        ? 0.0
        : (passedTasksCount / totalTasksChecked).clamp(0.0, 1.0) * 55.0;
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
      ..writeln('# Certyfikat $releaseVersion (#001–#562)')
      ..writeln()
      ..writeln('- **Werdykt**: ${verdict.title}')
      ..writeln(
        '- **Gotowość wydania**: ${readinessScorePercent.toStringAsFixed(1)}%',
      )
      ..writeln('- **Wygenerowano**: ${generatedAt.toIso8601String()}')
      ..writeln(
        '- **Zadania #001–#562**: $passedTasksCount / $expectedTotalTasks zaliczonych',
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
      ..writeln('## Podsumowanie Paczek (#001–#562)')
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

/// Główny silnik certyfikacji **DIAMOND MASTER v2.0** dla zadań `#001–#562`.
class DiamondMaster562CertificationSuite {
  const DiamondMaster562CertificationSuite();

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
      id: 'router_pack7',
      title: 'AppRouter + Trasy Paczek #1–#7B',
      path: 'lib/core/router/app_router.dart',
      markers: [
        'multiplayerLeagues',
        'mtbXcoWorldCup',
        'bikeBrandFactory',
        'velodromeTrackChampionship',
        'raceOrganizerHq',
        'ultraBikepacking',
        'globalAcademies',
        'managerReputation',
      ],
    ),
    (
      id: 'engine_bridge',
      title: 'Centralny Most Integracyjny Silnika',
      path: 'lib/engine/engine_integration_bridge.dart',
      markers: ['EngineIntegrationBridge'],
    ),
    (
      id: 'lint_gate_561',
      title: 'Bramka Jakości Lint & Zero Warnings (#561)',
      path: 'lib/core/diagnostics/final_lint_and_zero_warnings_gate.dart',
      markers: ['FinalLintAndZeroWarningsGate'],
    ),
    (
      id: 'save_v7_migrator',
      title: 'Migrator Zapisów v7 (Paczki #6–#7)',
      path: 'lib/core/diagnostics/save_compatibility_v7_migrator.dart',
      markers: ['SaveCompatibilityV7Migrator'],
    ),
    (
      id: 'gold_master_412',
      title: 'Pakiet Certyfikacji Gold Master v1.0 (#412)',
      path: 'lib/core/diagnostics/gold_master_412_certification_suite.dart',
      markers: ['GoldMaster412CertificationSuite'],
    ),
    (
      id: 'l10n_pl_en',
      title: 'Dwujęzyczny Słownik Kolarski PL/EN',
      path: 'lib/core/l10n/app_localizations_pl_en.dart',
      markers: ['BilingualCyclingDictionary'],
    ),
    (
      id: 'fuzz_tester',
      title: 'Fuzzer Serializacji Stanu Kariery JSON',
      path: 'lib/core/diagnostics/full_state_serialization_fuzz_tester.dart',
      markers: ['FullStateSerializationFuzzTester'],
    ),
    (
      id: 'nav_verifier',
      title: 'Weryfikator Nawigacji 30+ Tras',
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

  /// Uruchamia pełną certyfikację DIAMOND MASTER v2.0 (#001–#562).
  Future<DiamondMaster562Report> runCertification({
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

    final codeMapResult = DiamondMasterCodeMapGateResult(
      exists: codeMapExists,
      totalLines: codeMapLines,
      registeredLibFilesCount: registeredLibFiles.length,
      missingTaskPaths: missingInCodeMap,
    );

    final packageSummaries = _buildPackageSummaries(taskEntries);
    final pillarChecks = await _verifyPillars(root);

    final analyzeResult = runFlutterAnalyze
        ? await _runFlutterAnalyzeGate(root, timeout: commandTimeout)
        : DiamondMasterAnalyzeGateResult.skipped();

    final testSuiteResult = runFlutterTest
        ? await _runFlutterTestGate(root, timeout: commandTimeout)
        : DiamondMasterTestSuiteGateResult.skipped();

    stopwatch.stop();

    return DiamondMaster562Report(
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

  Future<List<DiamondMasterTaskVerificationEntry>> _verifyQueueTasks({
    required String root,
    required File queueFile,
    required Set<String> registeredLibFiles,
  }) async {
    if (!await queueFile.exists()) {
      return const [];
    }

    final lines = await queueFile.readAsLines();
    final entries = <DiamondMasterTaskVerificationEntry>[];
    final seenTasks = <int>{};

    for (final line in lines) {
      final match = _queueTaskRegex.firstMatch(line);
      if (match == null) continue;

      final mark = match.group(1) ?? ' ';
      final taskNum = int.tryParse(match.group(2) ?? '');
      final rawPathSection = match.group(3) ?? '';
      final description = (match.group(4) ?? '').trim();

      if (taskNum == null ||
          taskNum < 1 ||
          taskNum > DiamondMaster562Report.expectedTotalTasks) {
        continue;
      }
      if (!seenTasks.add(taskNum)) continue;

      final artifactPath = _extractPrimaryPath(rawPathSection);
      final normalizedPath = artifactPath.replaceAll('\\', '/');
      final completedInQueue = mark.toLowerCase() == 'x';

      final isDartLibFile =
          normalizedPath.startsWith('lib/') && normalizedPath.endsWith('.dart');
      final requiresCodeMapRegistration = isDartLibFile;
      final registeredInCodeMap =
          !requiresCodeMapRegistration ||
          registeredLibFiles.contains(normalizedPath);

      var artifactExists = false;
      var todoCount = 0;
      var unimplementedCount = 0;
      var lineCount = 0;

      if (normalizedPath.isNotEmpty) {
        final fullPath = _joinPath(root, normalizedPath);
        final entityType = await FileSystemEntity.type(fullPath);
        if (entityType == FileSystemEntityType.file) {
          artifactExists = true;
          if (normalizedPath.endsWith('.dart')) {
            final content = await File(fullPath).readAsString();
            lineCount = const LineSplitter().convert(content).length;
            if (taskNum != 562) {
              todoCount = _todoMarkerRegex.allMatches(content).length;
              unimplementedCount = _unimplementedRegex.allMatches(content).length;
            }
          }
        } else if (entityType == FileSystemEntityType.directory) {
          artifactExists = true;
        }
      }

      entries.add(
        DiamondMasterTaskVerificationEntry(
          taskNumber: taskNum,
          packageId: DiamondMasterPackageId.fromTaskNumber(taskNum),
          artifactPath: normalizedPath,
          description: description,
          completedInQueue: completedInQueue,
          artifactExists: artifactExists,
          registeredInCodeMap: registeredInCodeMap,
          requiresCodeMapRegistration: requiresCodeMapRegistration,
          todoMarkersCount: todoCount,
          unimplementedCount: unimplementedCount,
          lineCount: lineCount,
        ),
      );
    }

    entries.sort((a, b) => a.taskNumber.compareTo(b.taskNumber));
    return entries;
  }

  List<DiamondMasterPackageSummary> _buildPackageSummaries(
    List<DiamondMasterTaskVerificationEntry> entries,
  ) {
    return DiamondMasterPackageId.values.map((pkg) {
      final pkgEntries = entries.where((e) => e.packageId == pkg).toList();
      return DiamondMasterPackageSummary(
        packageId: pkg,
        totalTasks: pkgEntries.length,
        completedQueueTasks: pkgEntries.where((e) => e.completedInQueue).length,
        existingArtifacts: pkgEntries.where((e) => e.artifactExists).length,
        passedTasks: pkgEntries.where((e) => e.passed).length,
      );
    }).toList();
  }

  Future<List<DiamondMasterPillarCheck>> _verifyPillars(String root) async {
    final checks = <DiamondMasterPillarCheck>[];
    for (final spec in _pillarSpecs) {
      final file = File(_joinPath(root, spec.path));
      final exists = await file.exists();
      final missingSymbols = <String>[];

      if (exists) {
        final content = await file.readAsString();
        for (final marker in spec.markers) {
          if (!content.contains(marker)) {
            missingSymbols.add(marker);
          }
        }
      } else {
        missingSymbols.addAll(spec.markers);
      }

      checks.add(
        DiamondMasterPillarCheck(
          id: spec.id,
          title: spec.title,
          filePath: spec.path,
          fileExists: exists,
          symbolsPresent: exists && missingSymbols.isEmpty,
          missingSymbols: missingSymbols,
        ),
      );
    }
    return checks;
  }

  Future<DiamondMasterAnalyzeGateResult> _runFlutterAnalyzeGate(
    String root, {
    required Duration timeout,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await Process.run(
        Platform.isWindows ? 'flutter.bat' : 'flutter',
        const ['analyze', '--fatal-infos'],
        workingDirectory: root,
        runInShell: Platform.isWindows,
      ).timeout(timeout);
      stopwatch.stop();

      final combined = '${result.stdout}\n${result.stderr}'.trim();
      final lines = const LineSplitter().convert(combined);
      final issues = <DiamondMasterAnalyzeIssue>[];
      var errors = 0;
      var warnings = 0;
      var infos = 0;

      final issueRegex = RegExp(
        r'^\s*(error|warning|info)\s+•\s+(.+?)\s+•\s+([^:]+):(\d+):(\d+)\s+•\s+(\S+)\s*$',
        caseSensitive: false,
      );

      for (final line in lines) {
        final m = issueRegex.firstMatch(line);
        if (m == null) continue;
        final rawSev = (m.group(1) ?? 'info').toLowerCase();
        final DiamondMasterSeverity sev;
        if (rawSev == 'error') {
          sev = DiamondMasterSeverity.error;
          errors++;
        } else if (rawSev == 'warning') {
          sev = DiamondMasterSeverity.warning;
          warnings++;
        } else {
          sev = DiamondMasterSeverity.info;
          infos++;
        }
        issues.add(
          DiamondMasterAnalyzeIssue(
            severity: sev,
            message: m.group(2) ?? '',
            filePath: m.group(3) ?? '',
            line: int.tryParse(m.group(4) ?? '0') ?? 0,
            column: int.tryParse(m.group(5) ?? '0') ?? 0,
            ruleName: m.group(6) ?? '',
          ),
        );
      }

      return DiamondMasterAnalyzeGateResult(
        executed: true,
        exitCode: result.exitCode,
        errorCount: errors,
        warningCount: warnings,
        infoCount: infos,
        noIssuesFound:
            result.exitCode == 0 && combined.contains('No issues found'),
        issues: issues,
        rawOutput: combined,
        duration: stopwatch.elapsed,
      );
    } on TimeoutException {
      stopwatch.stop();
      return DiamondMasterAnalyzeGateResult(
        executed: true,
        exitCode: -2,
        errorCount: 1,
        warningCount: 0,
        infoCount: 0,
        noIssuesFound: false,
        issues: const [],
        rawOutput: 'Przekroczono limit czasu flutter analyze.',
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return DiamondMasterAnalyzeGateResult(
        executed: true,
        exitCode: -1,
        errorCount: 1,
        warningCount: 0,
        infoCount: 0,
        noIssuesFound: false,
        issues: const [],
        rawOutput: 'Błąd uruchamiania flutter analyze: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  Future<DiamondMasterTestSuiteGateResult> _runFlutterTestGate(
    String root, {
    required Duration timeout,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await Process.run(
        Platform.isWindows ? 'flutter.bat' : 'flutter',
        const ['test', '--no-pub', '--timeout', '30s'],
        workingDirectory: root,
        runInShell: Platform.isWindows,
      ).timeout(timeout);
      stopwatch.stop();

      final combined = '${result.stdout}\n${result.stderr}'.trim();
      final lines = const LineSplitter().convert(combined);
      final summaryLine = lines.isNotEmpty ? lines.last : '';

      var passed = 0;
      var failed = 0;
      var skipped = 0;

      final plusMatch = RegExp(r'\+(\d+)').allMatches(combined).lastOrNull;
      if (plusMatch != null) {
        passed = int.tryParse(plusMatch.group(1) ?? '0') ?? 0;
      }
      final minusMatch = RegExp(r'-(\d+)').allMatches(combined).lastOrNull;
      if (minusMatch != null) {
        failed = int.tryParse(minusMatch.group(1) ?? '0') ?? 0;
      }
      final skipMatch = RegExp(r'~(\d+)').allMatches(combined).lastOrNull;
      if (skipMatch != null) {
        skipped = int.tryParse(skipMatch.group(1) ?? '0') ?? 0;
      }

      if (result.exitCode != 0 && failed == 0) {
        failed = 1;
      }

      return DiamondMasterTestSuiteGateResult(
        executed: true,
        exitCode: result.exitCode,
        totalPassed: passed,
        totalFailed: failed,
        totalSkipped: skipped,
        summaryLine: summaryLine,
        rawOutput: combined,
        duration: stopwatch.elapsed,
      );
    } on TimeoutException {
      stopwatch.stop();
      return DiamondMasterTestSuiteGateResult(
        executed: true,
        exitCode: -2,
        totalPassed: 0,
        totalFailed: 1,
        totalSkipped: 0,
        summaryLine: 'Przekroczono limit czasu flutter test.',
        rawOutput: 'Przekroczono limit czasu flutter test.',
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return DiamondMasterTestSuiteGateResult(
        executed: true,
        exitCode: -1,
        totalPassed: 0,
        totalFailed: 1,
        totalSkipped: 0,
        summaryLine: 'Błąd uruchamiania flutter test: $e',
        rawOutput: 'Błąd uruchamiania flutter test: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  static String _extractPrimaryPath(String rawPathSection) {
    final backtickMatch = _backtickPathRegex.firstMatch(rawPathSection);
    if (backtickMatch != null) {
      return (backtickMatch.group(1) ?? '').trim();
    }
    return rawPathSection.trim();
  }

  static String _resolveProjectRoot(String? explicitRoot) {
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

  static String _joinPath(String root, String relative) {
    final sep = Platform.pathSeparator;
    final cleanRoot = root.endsWith(sep) || root.endsWith('/')
        ? root.substring(0, root.length - 1)
        : root;
    final cleanRel =
        relative.startsWith('/') ? relative.substring(1) : relative;
    return '$cleanRoot$sep${cleanRel.replaceAll('/', sep)}';
  }
}

/// Tryb filtrowania zadań w panelu certyfikacji DIAMOND MASTER v2.0.
enum DiamondMasterTaskFilter {
  all('Wszystkie (#001–#562)'),
  failedOnly('Tylko błędy'),
  passedOnly('Zaliczone'),
  package6And7Only('Paczki #6–#7B (#413–#562)');

  final String label;
  const DiamondMasterTaskFilter(this.label);
}

/// Stan kontrolera certyfikacji DIAMOND MASTER v2.0.
@immutable
class DiamondMaster562State {
  final bool isRunning;
  final bool runAnalyzeGate;
  final bool runTestGate;
  final DiamondMasterTaskFilter filter;
  final DiamondMasterPackageId? selectedPackage;
  final String searchQuery;
  final DiamondMaster562Report? report;
  final String? errorMessage;
  final String? exportNotice;

  const DiamondMaster562State({
    this.isRunning = false,
    this.runAnalyzeGate = false,
    this.runTestGate = false,
    this.filter = DiamondMasterTaskFilter.all,
    this.selectedPackage,
    this.searchQuery = '',
    this.report,
    this.errorMessage,
    this.exportNotice,
  });

  DiamondMaster562State copyWith({
    bool? isRunning,
    bool? runAnalyzeGate,
    bool? runTestGate,
    DiamondMasterTaskFilter? filter,
    DiamondMasterPackageId? selectedPackage,
    bool clearSelectedPackage = false,
    String? searchQuery,
    DiamondMaster562Report? report,
    String? errorMessage,
    bool clearError = false,
    String? exportNotice,
    bool clearNotice = false,
  }) {
    return DiamondMaster562State(
      isRunning: isRunning ?? this.isRunning,
      runAnalyzeGate: runAnalyzeGate ?? this.runAnalyzeGate,
      runTestGate: runTestGate ?? this.runTestGate,
      filter: filter ?? this.filter,
      selectedPackage:
          clearSelectedPackage ? null : (selectedPackage ?? this.selectedPackage),
      searchQuery: searchQuery ?? this.searchQuery,
      report: report ?? this.report,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      exportNotice: clearNotice ? null : (exportNotice ?? this.exportNotice),
    );
  }
}

/// Kontroler Riverpod zarządzający uruchomieniem i filtrowaniem certyfikacji #562.
class DiamondMaster562CertificationNotifier
    extends StateNotifier<DiamondMaster562State> {
  final DiamondMaster562CertificationSuite _suite;

  DiamondMaster562CertificationNotifier([
    this._suite = const DiamondMaster562CertificationSuite(),
  ]) : super(const DiamondMaster562State());

  void setRunAnalyzeGate(bool value) {
    state = state.copyWith(runAnalyzeGate: value, clearNotice: true);
  }

  void setRunTestGate(bool value) {
    state = state.copyWith(runTestGate: value, clearNotice: true);
  }

  void setFilter(DiamondMasterTaskFilter filter) {
    state = state.copyWith(filter: filter, clearNotice: true);
  }

  void selectPackage(DiamondMasterPackageId? packageId) {
    if (packageId == state.selectedPackage) {
      state = state.copyWith(clearSelectedPackage: true);
    } else {
      state = state.copyWith(selectedPackage: packageId);
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setExportNotice(String? notice) {
    state = state.copyWith(
      exportNotice: notice,
      clearNotice: notice == null,
    );
  }

  Future<void> runAudit({String? projectRoot}) async {
    if (state.isRunning) return;
    state = state.copyWith(
      isRunning: true,
      clearError: true,
      clearNotice: true,
    );
    try {
      final report = await _suite.runCertification(
        projectRoot: projectRoot,
        runFlutterAnalyze: state.runAnalyzeGate,
        runFlutterTest: state.runTestGate,
      );
      if (!mounted) return;
      state = state.copyWith(
        isRunning: false,
        report: report,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isRunning: false,
        errorMessage: 'Błąd certyfikacji DIAMOND MASTER v2.0: $e',
      );
    }
  }
}

/// Provider Riverpod dla pakietu certyfikacji DIAMOND MASTER v2.0 (#562).
final diamondMaster562CertificationProvider = StateNotifierProvider.autoDispose<
    DiamondMaster562CertificationNotifier, DiamondMaster562State>(
  (ref) => DiamondMaster562CertificationNotifier(),
);

/// Produkcyjny panel UI certyfikacji **DIAMOND MASTER v2.0** (#001–#562).
class DiamondMaster562CertificationPanel extends ConsumerStatefulWidget {
  final String? projectRoot;

  const DiamondMaster562CertificationPanel({
    super.key,
    this.projectRoot,
  });

  @override
  ConsumerState<DiamondMaster562CertificationPanel> createState() =>
      _DiamondMaster562CertificationPanelState();
}

class _DiamondMaster562CertificationPanelState
    extends ConsumerState<DiamondMaster562CertificationPanel> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(diamondMaster562CertificationProvider);
    final notifier = ref.read(diamondMaster562CertificationProvider.notifier);

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
                  _buildEmptyStateCard(
                    notifier: notifier,
                    isRunning: state.isRunning,
                  )
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
                          child: _buildPackageBreakdownCard(
                            state.report!,
                            state.selectedPackage,
                            notifier,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 7,
                          child: _buildGatesAndPillarsCard(state.report!),
                        ),
                      ],
                    )
                  else ...[
                    _buildPackageBreakdownCard(
                      state.report!,
                      state.selectedPackage,
                      notifier,
                    ),
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
    required DiamondMaster562State state,
    required DiamondMaster562CertificationNotifier notifier,
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
                color: AppColors.cyanAccent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.cyanAccent.withValues(alpha: 0.45),
                ),
              ),
              child: const Icon(
                Icons.diamond_rounded,
                color: AppColors.cyanAccent,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'DIAMOND MASTER v2.0 — Pakiet Certyfikacji (#001–#562)',
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
          'Kompleksowa weryfikacja 562 zadań kolejki (#001–#562), spójności docs/CODE_MAP.md, '
          '10 filarów architektury oraz bramek flutter analyze i flutter test.',
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
        _DiamondInteractiveChip(
          label: 'flutter analyze',
          icon: Icons.rule_rounded,
          selected: state.runAnalyzeGate,
          enabled: !state.isRunning,
          onTap: () => notifier.setRunAnalyzeGate(!state.runAnalyzeGate),
        ),
        _DiamondInteractiveChip(
          label: 'flutter test',
          icon: Icons.science_rounded,
          selected: state.runTestGate,
          enabled: !state.isRunning,
          onTap: () => notifier.setRunTestGate(!state.runTestGate),
        ),
        if (state.report != null) ...[
          _DiamondInteractiveButton(
            label: 'Kopiuj JSON',
            icon: Icons.data_object_rounded,
            enabled: !state.isRunning,
            isPrimary: false,
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: state.report!.toPrettyJson()),
              );
              notifier.setExportNotice(
                'Skopiowano raport JSON DIAMOND MASTER v2.0 do schowka.',
              );
            },
          ),
          _DiamondInteractiveButton(
            label: 'Certyfikat MD',
            icon: Icons.description_outlined,
            enabled: !state.isRunning,
            isPrimary: false,
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: state.report!.toMarkdownCertificate()),
              );
              notifier.setExportNotice(
                'Skopiowano certyfikat Markdown do schowka.',
              );
            },
          ),
        ],
        _DiamondInteractiveButton(
          label: state.isRunning ? 'Weryfikacja...' : 'Uruchom Audyt #562',
          icon: state.isRunning
              ? Icons.hourglass_top_rounded
              : Icons.play_arrow_rounded,
          enabled: !state.isRunning,
          isPrimary: true,
          onPressed: () => notifier.runAudit(projectRoot: widget.projectRoot),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          titleBlock,
          const SizedBox(height: 14),
          controlsBlock,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
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

  Widget _buildEmptyStateCard({
    required DiamondMaster562CertificationNotifier notifier,
    required bool isRunning,
  }) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Icon(
            Icons.diamond_outlined,
            size: 48,
            color: AppColors.cyanAccent.withValues(alpha: 0.8),
          ),
          const SizedBox(height: 12),
          const Text(
            'Gotowy do certyfikacji DIAMOND MASTER v2.0',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Uruchom audyt, aby zweryfikować wszystkie 562 zadania kolejki, '
            'kompletność CODE_MAP.md oraz 10 filarów silnika i UI.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          _DiamondInteractiveButton(
            label: isRunning ? 'Trwa certyfikacja...' : 'Rozpocznij Certyfikację',
            icon: Icons.verified_rounded,
            enabled: !isRunning,
            isPrimary: true,
            onPressed: () => notifier.runAudit(projectRoot: widget.projectRoot),
          ),
        ],
      ),
    );
  }

  Widget _buildVerdictAndKpiSection({
    required DiamondMaster562Report report,
    required bool isMobile,
    required bool isTablet,
  }) {
    final verdict = report.verdict;
    final kpis = [
      (
        label: 'Gotowość',
        value: '${report.readinessScorePercent.toStringAsFixed(1)}%',
        color: verdict.color,
      ),
      (
        label: 'Zadania #001–#562',
        value:
            '${report.passedTasksCount}/${DiamondMaster562Report.expectedTotalTasks}',
        color: report.allTasksVerified
            ? AppColors.statusSuccess
            : AppColors.amberWarning,
      ),
      (
        label: 'Pliki w CODE_MAP',
        value: '${report.codeMapResult.registeredLibFilesCount}',
        color: report.codeMapResult.passed
            ? AppColors.accentBlue
            : AppColors.crimsonAlert,
      ),
      (
        label: 'Filary Architektury',
        value: '${report.passedPillarsCount}/${report.pillarChecks.length}',
        color: report.allPillarsPassed
            ? AppColors.statusSuccess
            : AppColors.crimsonAlert,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: verdict.color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(verdict.icon, color: verdict.color, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      verdict.title,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: isMobile ? 15 : 18,
                        fontWeight: FontWeight.w700,
                        color: verdict.color,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      verdict.description,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, kpiConstraints) {
              final columns = isMobile ? 2 : (isTablet ? 2 : 4);
              const spacing = 10.0;
              final itemWidth =
                  (kpiConstraints.maxWidth - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: kpis.map((kpi) {
                  return SizedBox(
                    width: itemWidth,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            kpi.label,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            kpi.value,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: kpi.color,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPackageBreakdownCard(
    DiamondMaster562Report report,
    DiamondMasterPackageId? selectedPackage,
    DiamondMaster562CertificationNotifier notifier,
  ) {
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
            'Podsumowanie Paczek (#001–#562)',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          for (final pkg in report.packageSummaries) ...[
            _PackageRowItem(
              summary: pkg,
              selected: selectedPackage == pkg.packageId,
              onTap: () => notifier.selectPackage(pkg.packageId),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildGatesAndPillarsCard(DiamondMaster562Report report) {
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
            'Filary Architektury i Bramki CLI',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _GateRow(
            title: 'docs/CODE_MAP.md',
            subtitle:
                '${report.codeMapResult.registeredLibFilesCount} zarejestrowanych plików lib/',
            passed: report.codeMapResult.passed,
            executed: report.codeMapResult.exists,
          ),
          const SizedBox(height: 8),
          _GateRow(
            title: 'flutter analyze --fatal-infos',
            subtitle: report.analyzeResult.executed
                ? (report.analyzeResult.passed
                    ? '0 błędów i ostrzeżeń'
                    : 'Błędy: ${report.analyzeResult.errorCount}, Ostrzeżenia: ${report.analyzeResult.warningCount}')
                : 'Pominięto (włącz przełącznik powyżej)',
            passed: report.analyzeResult.passed,
            executed: report.analyzeResult.executed,
          ),
          const SizedBox(height: 8),
          _GateRow(
            title: 'flutter test --no-pub',
            subtitle: report.testSuiteResult.executed
                ? 'Zaliczono: ${report.testSuiteResult.totalPassed}, Błędy: ${report.testSuiteResult.totalFailed}'
                : 'Pominięto (włącz przełącznik powyżej)',
            passed: report.testSuiteResult.passed,
            executed: report.testSuiteResult.executed,
          ),
          const SizedBox(height: 14),
          const Text(
            'Zweryfikowane Filary Systemu',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          for (final pillar in report.pillarChecks) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    pillar.passed
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    size: 16,
                    color: pillar.passed
                        ? AppColors.statusSuccess
                        : AppColors.crimsonAlert,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      pillar.title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTaskAuditCard({
    required DiamondMaster562State state,
    required DiamondMaster562CertificationNotifier notifier,
    required DiamondMaster562Report report,
    required bool isMobile,
  }) {
    final query = state.searchQuery.trim().toLowerCase();
    final filtered = report.taskEntries.where((entry) {
      if (state.selectedPackage != null &&
          entry.packageId != state.selectedPackage) {
        return false;
      }
      switch (state.filter) {
        case DiamondMasterTaskFilter.all:
          break;
        case DiamondMasterTaskFilter.failedOnly:
          if (entry.passed) return false;
        case DiamondMasterTaskFilter.passedOnly:
          if (!entry.passed) return false;
        case DiamondMasterTaskFilter.package6And7Only:
          if (entry.taskNumber < 413) return false;
      }
      if (query.isNotEmpty) {
        return entry.formattedNumber.toLowerCase().contains(query) ||
            entry.artifactPath.toLowerCase().contains(query) ||
            entry.description.toLowerCase().contains(query);
      }
      return true;
    }).toList();

    final visibleTasks = filtered.take(80).toList();

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
                  'Rejestr Zadań (#001–#562)',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${filtered.length} pasujących',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
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
            children: [
              for (final f in DiamondMasterTaskFilter.values)
                _DiamondInteractiveChip(
                  label: f.label,
                  icon: Icons.filter_list_rounded,
                  selected: state.filter == f,
                  enabled: true,
                  onTap: () => notifier.setFilter(f),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: notifier.setSearchQuery,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Szukaj po numerze (#562), ścieżce pliku lub opisie...',
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
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.cyanAccent),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (visibleTasks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Brak zadań spełniających kryteria filtrowania.',
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
              itemCount: visibleTasks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final task = visibleTasks[index];
                final statusColor = task.passed
                    ? AppColors.statusSuccess
                    : AppColors.crimsonAlert;
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: task.passed
                          ? AppTheme.borderColor
                          : AppColors.crimsonAlert.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        task.passed
                            ? Icons.check_circle_rounded
                            : Icons.error_rounded,
                        color: statusColor,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  task.formattedNumber,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: statusColor,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                                Text(
                                  task.artifactPath,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: AppColors.accentBlue,
                                  ),
                                ),
                              ],
                            ),
                            if (task.description.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                task.description,
                                maxLines: isMobile ? 2 : 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                            if (!task.passed) ...[
                              const SizedBox(height: 4),
                              Text(
                                task.failureReasons.join(' • '),
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11.5,
                                  color: AppColors.crimsonAlert,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _PackageRowItem extends StatefulWidget {
  final DiamondMasterPackageSummary summary;
  final bool selected;
  final VoidCallback onTap;

  const _PackageRowItem({
    required this.summary,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_PackageRowItem> createState() => _PackageRowItemState();
}

class _PackageRowItemState extends State<_PackageRowItem> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final pkg = widget.summary;
    final accent = pkg.allPassed ? AppColors.statusSuccess : AppColors.amberWarning;

    return FocusableActionDetector(
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _pressed
                  ? AppColors.surface
                  : (widget.selected || _hovered
                      ? AppColors.surfaceLight
                      : AppColors.background.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _focused || widget.selected
                    ? AppColors.cyanAccent
                    : (_hovered ? accent.withValues(alpha: 0.6) : AppTheme.borderColor),
              ),
            ),
            child: Row(
              children: [
                Icon(pkg.packageId.icon, size: 18, color: accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pkg.packageId.label,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pkg.passRate.clamp(0.0, 1.0),
                          minHeight: 5,
                          backgroundColor: AppColors.surface,
                          valueColor: AlwaysStoppedAnimation<Color>(accent),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${pkg.passedTasks}/${pkg.totalTasks}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: accent,
                    fontFeatures: const [FontFeature.tabularFigures()],
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

class _GateRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool passed;
  final bool executed;

  const _GateRow({
    required this.title,
    required this.subtitle,
    required this.passed,
    required this.executed,
  });

  @override
  Widget build(BuildContext context) {
    final color = !executed
        ? AppColors.amberWarning
        : (passed ? AppColors.statusSuccess : AppColors.crimsonAlert);
    final icon = !executed
        ? Icons.pause_circle_outline_rounded
        : (passed ? Icons.check_circle_rounded : Icons.error_rounded);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
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

class _DiamondInteractiveChip extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _DiamondInteractiveChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_DiamondInteractiveChip> createState() =>
      _DiamondInteractiveChipState();
}

class _DiamondInteractiveChipState extends State<_DiamondInteractiveChip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final activeColor =
        widget.selected ? AppColors.cyanAccent : AppColors.textSecondary;
    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: MouseRegion(
        cursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.enabled ? widget.onTap : null,
          onTapDown: widget.enabled
              ? (_) => setState(() => _pressed = true)
              : null,
          onTapUp: widget.enabled
              ? (_) => setState(() => _pressed = false)
              : null,
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: !widget.enabled
                  ? AppColors.surfaceLight.withValues(alpha: 0.4)
                  : (_pressed
                      ? AppColors.surface
                      : (widget.selected
                          ? AppColors.cyanAccent.withValues(alpha: 0.16)
                          : (_hovered
                              ? AppColors.surfaceLight
                              : AppColors.background))),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _focused
                    ? AppColors.goldAccent
                    : (widget.selected
                        ? AppColors.cyanAccent
                        : AppTheme.borderColor),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 15, color: activeColor),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    widget.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: widget.enabled
                          ? (widget.selected
                              ? AppColors.textPrimary
                              : AppColors.textSecondary)
                          : AppColors.textSecondary.withValues(alpha: 0.5),
                    ),
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

class _DiamondInteractiveButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final bool isPrimary;
  final VoidCallback onPressed;

  const _DiamondInteractiveButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.isPrimary,
    required this.onPressed,
  });

  @override
  State<_DiamondInteractiveButton> createState() =>
      _DiamondInteractiveButtonState();
}

class _DiamondInteractiveButtonState extends State<_DiamondInteractiveButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final baseColor =
        widget.isPrimary ? AppColors.primaryAccent : AppColors.surfaceLight;

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: MouseRegion(
        cursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.enabled ? widget.onPressed : null,
          onTapDown: widget.enabled
              ? (_) => setState(() => _pressed = true)
              : null,
          onTapUp: widget.enabled
              ? (_) => setState(() => _pressed = false)
              : null,
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: !widget.enabled
                  ? baseColor.withValues(alpha: 0.4)
                  : (_pressed
                      ? baseColor.withValues(alpha: 0.75)
                      : (_hovered
                          ? baseColor.withValues(alpha: 0.9)
                          : baseColor)),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _focused
                    ? AppColors.goldAccent
                    : (widget.isPrimary
                        ? AppColors.goldAccent.withValues(alpha: 0.5)
                        : AppTheme.borderColor),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 16,
                  color: widget.enabled
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    widget.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: widget.enabled
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
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
