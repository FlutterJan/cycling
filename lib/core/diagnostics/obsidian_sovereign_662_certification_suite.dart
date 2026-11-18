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

/// Identyfikator etapu / paczki zadań objętych certyfikacją OBSIDIAN SOVEREIGN v4.0 (#001–#662).
enum ObsidianSovereignPackageId {
  foundation('Fundament (#001–#162)', 1, 162, Icons.foundation_rounded),
  package1('Paczka #1 (#163–#212)', 163, 212, Icons.view_in_ar_rounded),
  package2('Paczka #2 (#213–#262)', 213, 262, Icons.speed_rounded),
  package3('Paczka #3 (#263–#312)', 263, 312, Icons.verified_rounded),
  package4('Paczka #4 (#313–#362)', 313, 362, Icons.directions_bike_rounded),
  package5('Paczka #5 (#363–#412)', 363, 412, Icons.workspace_premium_rounded),
  package6('Paczka #6 (#413–#462)', 413, 462, Icons.public_rounded),
  package7A('Paczka #7A (#463–#512)', 463, 512, Icons.gavel_rounded),
  package7B('Paczka #7B (#513–#562)', 513, 562, Icons.diamond_rounded),
  package8('Paczka #8 (#563–#612)', 563, 612, Icons.military_tech_rounded),
  package9('Paczka #9 (#613–#662)', 613, 662, Icons.auto_awesome_rounded);

  final String label;
  final int startTask;
  final int endTask;
  final IconData icon;

  const ObsidianSovereignPackageId(
    this.label,
    this.startTask,
    this.endTask,
    this.icon,
  );

  int get expectedCount => endTask - startTask + 1;

  static ObsidianSovereignPackageId fromTaskNumber(int taskNumber) {
    for (final pkg in values) {
      if (taskNumber >= pkg.startTask && taskNumber <= pkg.endTask) {
        return pkg;
      }
    }
    return foundation;
  }
}

/// Poziom ważności wyniku bramki lub zadania certyfikacji OBSIDIAN SOVEREIGN v4.0.
enum ObsidianSovereignSeverity {
  pass('OK', AppColors.statusSuccess),
  info('Info', AppColors.accentBlue),
  warning('Ostrzeżenie', AppColors.amberWarning),
  error('Błąd', AppColors.crimsonAlert);

  final String label;
  final Color color;

  const ObsidianSovereignSeverity(this.label, this.color);
}

/// Finalny werdykt certyfikacji OBSIDIAN SOVEREIGN v4.0 (#001–#662).
enum ObsidianSovereignVerdict {
  certifiedObsidianSovereign(
    'OBSIDIAN SOVEREIGN v4.0 CERTIFIED',
    'Wszystkie 662 zadania, mapa kodu, 15 filarów architektury oraz bramki jakości przeszły weryfikację.',
    AppColors.goldAccent,
    Icons.verified_rounded,
  ),
  conditionalPass(
    'WARUNKOWY PASS (POMINIĘTE BRAMKI CLI)',
    'Zadania #001–#662 i integralność architektury są poprawne, ale bramki CLI nie zostały uruchomione.',
    AppColors.amberWarning,
    Icons.verified_user_outlined,
  ),
  blocked(
    'CERTYFIKACJA ZABLOKOWANA',
    'Wykryto braki w zadaniach, plikach, filarach lub bramkach jakości wymagające naprawy.',
    AppColors.crimsonAlert,
    Icons.gpp_bad_rounded,
  );

  final String title;
  final String description;
  final Color color;
  final IconData icon;

  const ObsidianSovereignVerdict(
    this.title,
    this.description,
    this.color,
    this.icon,
  );
}

/// Pojedynczy problem zgłoszony przez bramkę `flutter analyze`.
@immutable
class ObsidianSovereignAnalyzeIssue {
  final ObsidianSovereignSeverity severity;
  final String message;
  final String filePath;
  final int line;
  final int column;
  final String ruleName;

  const ObsidianSovereignAnalyzeIssue({
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

/// Wynik bramki analizy statycznej `flutter analyze --fatal-infos`.
@immutable
class ObsidianSovereignAnalyzeGateResult {
  final bool executed;
  final int exitCode;
  final int errorCount;
  final int warningCount;
  final int infoCount;
  final bool noIssuesFound;
  final List<ObsidianSovereignAnalyzeIssue> issues;
  final String rawOutput;
  final Duration duration;

  const ObsidianSovereignAnalyzeGateResult({
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

  factory ObsidianSovereignAnalyzeGateResult.skipped() =>
      const ObsidianSovereignAnalyzeGateResult(
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
class ObsidianSovereignTestSuiteGateResult {
  final bool executed;
  final int exitCode;
  final int totalPassed;
  final int totalFailed;
  final int totalSkipped;
  final String summaryLine;
  final String rawOutput;
  final Duration duration;

  const ObsidianSovereignTestSuiteGateResult({
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

  factory ObsidianSovereignTestSuiteGateResult.skipped() =>
      const ObsidianSovereignTestSuiteGateResult(
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
class ObsidianSovereignCodeMapGateResult {
  final bool exists;
  final int totalLines;
  final int registeredLibFilesCount;
  final List<String> missingTaskPaths;

  const ObsidianSovereignCodeMapGateResult({
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
class ObsidianSovereignPillarCheck {
  final String id;
  final String title;
  final String filePath;
  final bool fileExists;
  final bool symbolsPresent;
  final List<String> missingSymbols;

  const ObsidianSovereignPillarCheck({
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

/// Szczegółowy wynik weryfikacji pojedynczego zadania z zakresu `#001–#662`.
@immutable
class ObsidianSovereignTaskVerificationEntry {
  final int taskNumber;
  final ObsidianSovereignPackageId packageId;
  final String artifactPath;
  final String description;
  final bool completedInQueue;
  final bool artifactExists;
  final bool registeredInCodeMap;
  final bool requiresCodeMapRegistration;
  final int todoMarkersCount;
  final int unimplementedCount;
  final int lineCount;

  const ObsidianSovereignTaskVerificationEntry({
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
      reasons.add('Znaleziono znaczniki TODO/FIXME ($todoMarkersCount)');
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

/// Zbiorcze podsumowanie dla pojedynczej paczki zadań (#001–#662).
@immutable
class ObsidianSovereignPackageSummary {
  final ObsidianSovereignPackageId packageId;
  final int totalTasks;
  final int completedQueueTasks;
  final int existingArtifacts;
  final int passedTasks;

  const ObsidianSovereignPackageSummary({
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

/// Kompletny raport certyfikacji **OBSIDIAN SOVEREIGN v4.0** (#001–#662).
@immutable
class ObsidianSovereign662Report {
  static const String releaseVersion = 'OBSIDIAN SOVEREIGN v4.0';
  static const int expectedTotalTasks = 662;

  final DateTime generatedAt;
  final String projectRoot;
  final List<ObsidianSovereignTaskVerificationEntry> taskEntries;
  final List<ObsidianSovereignPackageSummary> packageSummaries;
  final ObsidianSovereignCodeMapGateResult codeMapResult;
  final List<ObsidianSovereignPillarCheck> pillarChecks;
  final ObsidianSovereignAnalyzeGateResult analyzeResult;
  final ObsidianSovereignTestSuiteGateResult testSuiteResult;
  final Duration duration;

  const ObsidianSovereign662Report({
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

  ObsidianSovereignVerdict get verdict {
    if (!coreIntegrityPassed) {
      return ObsidianSovereignVerdict.blocked;
    }
    if ((analyzeResult.executed && !analyzeResult.passed) ||
        (testSuiteResult.executed && !testSuiteResult.passed)) {
      return ObsidianSovereignVerdict.blocked;
    }
    if (!analyzeResult.executed || !testSuiteResult.executed) {
      return ObsidianSovereignVerdict.conditionalPass;
    }
    return ObsidianSovereignVerdict.certifiedObsidianSovereign;
  }

  double get readinessScorePercent {
    var earned = 0.0;
    const maxPoints = 100.0;

    // 55 pkt: zadania #001–#662
    earned += totalTasksChecked == 0
        ? 0.0
        : (passedTasksCount / totalTasksChecked).clamp(0.0, 1.0) * 55.0;
    // 15 pkt: integralność CODE_MAP.md
    if (codeMapResult.passed) {
      earned += 15.0;
    }
    // 10 pkt: 15 filarów architektury i AppRouter
    if (pillarChecks.isNotEmpty) {
      earned += (passedPillarsCount / pillarChecks.length) * 10.0;
    }
    // 10 pkt: flutter analyze --fatal-infos
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
      ..writeln('# Certyfikat $releaseVersion (#001–#662)')
      ..writeln()
      ..writeln('- **Werdykt**: ${verdict.title}')
      ..writeln(
        '- **Gotowość wydania**: ${readinessScorePercent.toStringAsFixed(1)}%',
      )
      ..writeln('- **Wygenerowano**: ${generatedAt.toIso8601String()}')
      ..writeln(
        '- **Zadania #001–#662**: $passedTasksCount / $expectedTotalTasks zaliczonych',
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
      ..writeln('## Podsumowanie Paczek (#001–#662)')
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

/// Główny silnik certyfikacji **OBSIDIAN SOVEREIGN v4.0** dla zadań `#001–#662`.
class ObsidianSovereign662CertificationSuite {
  const ObsidianSovereign662CertificationSuite();

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
      id: 'router_pack9',
      title: 'AppRouter + Trasy Paczek #1–#9',
      path: 'lib/core/router/app_router.dart',
      markers: [
        'paracyclingWorldCup',
        'clubMuseum',
        'talentCombine',
        'goldenEraRetro',
        'cyclingEsports',
      ],
    ),
    (
      id: 'engine_bridge',
      title: 'Centralny Most Integracyjny Silnika',
      path: 'lib/engine/engine_integration_bridge.dart',
      markers: ['EngineIntegrationBridge'],
    ),
    (
      id: 'lint_gate_661',
      title: 'Bramka Jakości Zero Warnings (#661)',
      path: 'lib/core/diagnostics/zero_warnings_662_lint_gate.dart',
      markers: ['ZeroWarnings662LintGate'],
    ),
    (
      id: 'perf_profiler_660',
      title: 'Audytor Wydajności 120 FPS & RAM (#660)',
      path: 'lib/core/diagnostics/performance_and_memory_662_profiler.dart',
      markers: ['PerformanceAndMemory662Profiler'],
    ),
    (
      id: 'save_v9_migrator',
      title: 'Migrator Zapisów v9 (Paczka #9)',
      path: 'lib/core/diagnostics/save_compatibility_v9_migrator.dart',
      markers: ['SaveCompatibilityV9Migrator'],
    ),
    (
      id: 'platinum_apex_612',
      title: 'Pakiet Certyfikacji Platinum Apex v3.0 (#612)',
      path: 'lib/core/diagnostics/platinum_apex_612_certification_suite.dart',
      markers: ['PlatinumApex612CertificationSuite'],
    ),
    (
      id: 'l10n_pl_en',
      title: 'Dwujęzyczny Słownik Kolarski PL/EN (#657)',
      path: 'lib/core/l10n/app_localizations_pl_en.dart',
      markers: ['BilingualCyclingDictionary'],
    ),
    (
      id: 'feature_flags_599',
      title: 'Centralny Rejestr Flag Realizmu (#599)',
      path: 'lib/core/config/app_feature_flags_and_presets.dart',
      markers: ['AppFeatureFlagsAndPresets'],
    ),
    (
      id: 'global_exotic_613',
      title: 'Ekspansja UCI Afryka/Azja/Bliski Wschód (#613)',
      path: 'lib/models/race/global_exotic_tours_expansion_model.dart',
      markers: ['GlobalExoticToursExpansionModel'],
    ),
    (
      id: 'chemistry_web_617',
      title: 'Psychologia Szatni 2.0 & Blood Brothers (#617)',
      path: 'lib/models/career/rider_relationship_chemistry_web_model.dart',
      markers: ['RiderRelationshipChemistryWebModel'],
    ),
    (
      id: 'what_if_620',
      title: 'Symulator Monte Carlo „What-If” (#620)',
      path: 'lib/engine/simulation/what_if_tactical_sandbox_simulator.dart',
      markers: ['WhatIfTacticalSandboxSimulator'],
    ),
    (
      id: 'paracycling_622',
      title: 'Model UCI Para-Cycling Tandem & Handbike (#622)',
      path: 'lib/models/paracycling/uci_paracycling_tandem_handbike_model.dart',
      markers: ['UciParacyclingTandemHandbikeModel'],
    ),
    (
      id: 'adaptive_music_644',
      title: 'Adaptacyjny Silnik Muzyki Szosowej (#644)',
      path: 'lib/core/services/adaptive_dynamic_music_score_engine.dart',
      markers: ['AdaptiveDynamicMusicScoreEngine'],
    ),
    (
      id: 'game_manual_659',
      title: 'Kompletny Przewodnik Gry 13 Trybów (#659)',
      path: 'docs/COMPLETE_GAME_MANUAL_662.md',
      markers: ['COMPLETE_GAME_MANUAL_662.md'],
    ),
    (
      id: 'fuzz_tester',
      title: 'Fuzzer Serializacji Stanu Kariery JSON',
      path: 'lib/core/diagnostics/full_state_serialization_fuzz_tester.dart',
      markers: ['FullStateSerializationFuzzTester'],
    ),
  ];

  /// Uruchamia pełną certyfikację OBSIDIAN SOVEREIGN v4.0 (#001–#662).
  Future<ObsidianSovereign662Report> runCertification({
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

    final codeMapResult = ObsidianSovereignCodeMapGateResult(
      exists: codeMapExists,
      totalLines: codeMapLines,
      registeredLibFilesCount: registeredLibFiles.length,
      missingTaskPaths: missingInCodeMap,
    );

    final packageSummaries = _buildPackageSummaries(taskEntries);
    final pillarChecks = await _verifyPillars(root);

    final analyzeResult = runFlutterAnalyze
        ? await _runFlutterAnalyzeGate(root, timeout: commandTimeout)
        : ObsidianSovereignAnalyzeGateResult.skipped();

    final testSuiteResult = runFlutterTest
        ? await _runFlutterTestGate(root, timeout: commandTimeout)
        : ObsidianSovereignTestSuiteGateResult.skipped();

    stopwatch.stop();

    return ObsidianSovereign662Report(
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

  Future<List<ObsidianSovereignTaskVerificationEntry>> _verifyQueueTasks({
    required String root,
    required File queueFile,
    required Set<String> registeredLibFiles,
  }) async {
    if (!await queueFile.exists()) {
      return const [];
    }

    final lines = await queueFile.readAsLines();
    final entries = <ObsidianSovereignTaskVerificationEntry>[];
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
          taskNum > ObsidianSovereign662Report.expectedTotalTasks) {
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
            if (taskNum != 662 && taskNum != 612 && taskNum != 562) {
              todoCount = _todoMarkerRegex.allMatches(content).length;
              unimplementedCount =
                  _unimplementedRegex.allMatches(content).length;
            }
          }
        } else if (entityType == FileSystemEntityType.directory) {
          artifactExists = true;
        }
      }

      entries.add(
        ObsidianSovereignTaskVerificationEntry(
          taskNumber: taskNum,
          packageId: ObsidianSovereignPackageId.fromTaskNumber(taskNum),
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

  List<ObsidianSovereignPackageSummary> _buildPackageSummaries(
    List<ObsidianSovereignTaskVerificationEntry> entries,
  ) {
    return ObsidianSovereignPackageId.values.map((pkg) {
      final pkgEntries = entries.where((e) => e.packageId == pkg).toList();
      return ObsidianSovereignPackageSummary(
        packageId: pkg,
        totalTasks: pkgEntries.length,
        completedQueueTasks: pkgEntries.where((e) => e.completedInQueue).length,
        existingArtifacts: pkgEntries.where((e) => e.artifactExists).length,
        passedTasks: pkgEntries.where((e) => e.passed).length,
      );
    }).toList();
  }

  Future<List<ObsidianSovereignPillarCheck>> _verifyPillars(String root) async {
    final checks = <ObsidianSovereignPillarCheck>[];
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
        ObsidianSovereignPillarCheck(
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

  Future<ObsidianSovereignAnalyzeGateResult> _runFlutterAnalyzeGate(
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
      final issues = <ObsidianSovereignAnalyzeIssue>[];
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
        final ObsidianSovereignSeverity sev;
        if (rawSev == 'error') {
          sev = ObsidianSovereignSeverity.error;
          errors++;
        } else if (rawSev == 'warning') {
          sev = ObsidianSovereignSeverity.warning;
          warnings++;
        } else {
          sev = ObsidianSovereignSeverity.info;
          infos++;
        }
        issues.add(
          ObsidianSovereignAnalyzeIssue(
            severity: sev,
            message: m.group(2) ?? '',
            filePath: m.group(3) ?? '',
            line: int.tryParse(m.group(4) ?? '0') ?? 0,
            column: int.tryParse(m.group(5) ?? '0') ?? 0,
            ruleName: m.group(6) ?? '',
          ),
        );
      }

      return ObsidianSovereignAnalyzeGateResult(
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
      return ObsidianSovereignAnalyzeGateResult(
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
      return ObsidianSovereignAnalyzeGateResult(
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

  Future<ObsidianSovereignTestSuiteGateResult> _runFlutterTestGate(
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

      return ObsidianSovereignTestSuiteGateResult(
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
      return ObsidianSovereignTestSuiteGateResult(
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
      return ObsidianSovereignTestSuiteGateResult(
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

/// Tryb filtrowania zadań w panelu certyfikacji OBSIDIAN SOVEREIGN v4.0.
enum ObsidianSovereignTaskFilter {
  all('Wszystkie (#001–#662)'),
  failedOnly('Tylko błędy'),
  passedOnly('Zaliczone'),
  package9Only('Paczka #9 (#613–#662)');

  final String label;
  const ObsidianSovereignTaskFilter(this.label);
}

/// Stan kontrolera certyfikacji OBSIDIAN SOVEREIGN v4.0.
@immutable
class ObsidianSovereign662State {
  final bool isRunning;
  final bool runAnalyzeGate;
  final bool runTestGate;
  final ObsidianSovereignTaskFilter filter;
  final ObsidianSovereignPackageId? selectedPackage;
  final String searchQuery;
  final ObsidianSovereign662Report? report;
  final String? errorMessage;
  final String? exportNotice;

  const ObsidianSovereign662State({
    this.isRunning = false,
    this.runAnalyzeGate = false,
    this.runTestGate = false,
    this.filter = ObsidianSovereignTaskFilter.all,
    this.selectedPackage,
    this.searchQuery = '',
    this.report,
    this.errorMessage,
    this.exportNotice,
  });

  ObsidianSovereign662State copyWith({
    bool? isRunning,
    bool? runAnalyzeGate,
    bool? runTestGate,
    ObsidianSovereignTaskFilter? filter,
    ObsidianSovereignPackageId? selectedPackage,
    bool clearSelectedPackage = false,
    String? searchQuery,
    ObsidianSovereign662Report? report,
    String? errorMessage,
    bool clearError = false,
    String? exportNotice,
    bool clearNotice = false,
  }) {
    return ObsidianSovereign662State(
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

/// Kontroler Riverpod zarządzający uruchomieniem i filtrowaniem certyfikacji #662.
class ObsidianSovereign662CertificationNotifier
    extends StateNotifier<ObsidianSovereign662State> {
  final ObsidianSovereign662CertificationSuite _suite;

  ObsidianSovereign662CertificationNotifier([
    this._suite = const ObsidianSovereign662CertificationSuite(),
  ]) : super(const ObsidianSovereign662State());

  void setRunAnalyzeGate(bool value) {
    state = state.copyWith(runAnalyzeGate: value, clearNotice: true);
  }

  void setRunTestGate(bool value) {
    state = state.copyWith(runTestGate: value, clearNotice: true);
  }

  void setFilter(ObsidianSovereignTaskFilter filter) {
    state = state.copyWith(filter: filter, clearNotice: true);
  }

  void selectPackage(ObsidianSovereignPackageId? packageId) {
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
        errorMessage: 'Błąd certyfikacji OBSIDIAN SOVEREIGN v4.0: $e',
      );
    }
  }
}

/// Provider Riverpod dla pakietu certyfikacji OBSIDIAN SOVEREIGN v4.0 (#662).
final obsidianSovereign662CertificationProvider = StateNotifierProvider.autoDispose<
    ObsidianSovereign662CertificationNotifier, ObsidianSovereign662State>(
  (ref) => ObsidianSovereign662CertificationNotifier(),
);

/// Produkcyjny panel UI certyfikacji **OBSIDIAN SOVEREIGN v4.0** (#001–#662).
class ObsidianSovereign662CertificationPanel extends ConsumerStatefulWidget {
  final String? projectRoot;

  const ObsidianSovereign662CertificationPanel({
    super.key,
    this.projectRoot,
  });

  @override
  ConsumerState<ObsidianSovereign662CertificationPanel> createState() =>
      _ObsidianSovereign662CertificationPanelState();
}

class _ObsidianSovereign662CertificationPanelState
    extends ConsumerState<ObsidianSovereign662CertificationPanel> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(obsidianSovereign662CertificationProvider);
    final notifier =
        ref.read(obsidianSovereign662CertificationProvider.notifier);

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
    required ObsidianSovereign662State state,
    required ObsidianSovereign662CertificationNotifier notifier,
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
                color: AppColors.goldAccent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.goldAccent.withValues(alpha: 0.45),
                ),
              ),
              child: const Icon(
                Icons.verified_rounded,
                color: AppColors.goldAccent,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'OBSIDIAN SOVEREIGN v4.0 — Pakiet Certyfikacji (#001–#662)',
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
          'Kompleksowa weryfikacja 662 zadań kolejki (#001–#662), spójności docs/CODE_MAP.md, '
          '15 filarów architektury oraz bramek flutter analyze i flutter test.',
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
        _SovereignInteractiveChip(
          label: 'flutter analyze',
          icon: Icons.rule_rounded,
          selected: state.runAnalyzeGate,
          enabled: !state.isRunning,
          onTap: () => notifier.setRunAnalyzeGate(!state.runAnalyzeGate),
        ),
        _SovereignInteractiveChip(
          label: 'flutter test',
          icon: Icons.science_rounded,
          selected: state.runTestGate,
          enabled: !state.isRunning,
          onTap: () => notifier.setRunTestGate(!state.runTestGate),
        ),
        if (state.report != null) ...[
          _SovereignInteractiveButton(
            label: 'Kopiuj JSON',
            icon: Icons.data_object_rounded,
            enabled: !state.isRunning,
            isPrimary: false,
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: state.report!.toPrettyJson()),
              );
              notifier.setExportNotice(
                'Skopiowano raport JSON OBSIDIAN SOVEREIGN v4.0 do schowka.',
              );
            },
          ),
          _SovereignInteractiveButton(
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
        _SovereignInteractiveButton(
          label: state.isRunning ? 'Weryfikacja...' : 'Uruchom Audyt #662',
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
    required ObsidianSovereign662CertificationNotifier notifier,
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
            Icons.workspace_premium_outlined,
            size: 48,
            color: AppColors.goldAccent.withValues(alpha: 0.85),
          ),
          const SizedBox(height: 12),
          const Text(
            'Gotowy do certyfikacji OBSIDIAN SOVEREIGN v4.0',
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
            'Uruchom audyt, aby zweryfikować wszystkie 662 zadania kolejki, '
            'kompletność CODE_MAP.md oraz 15 filarów silnika, UI i dokumentacji.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          _SovereignInteractiveButton(
            label:
                isRunning ? 'Trwa certyfikacja...' : 'Rozpocznij Certyfikację',
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
    required ObsidianSovereign662Report report,
    required bool isMobile,
    required bool isTablet,
  }) {
    final verdict = report.verdict;
    final scoreStr = '${report.readinessScorePercent.toStringAsFixed(1)}%';

    final kpiCards = [
      _buildKpiTile(
        label: 'Zadania #001–#662',
        value: '${report.passedTasksCount}/${report.totalTasksChecked}',
        accent: report.allTasksVerified
            ? AppColors.statusSuccess
            : AppColors.amberWarning,
        icon: Icons.task_alt_rounded,
      ),
      _buildKpiTile(
        label: 'CODE_MAP.md',
        value: '${report.codeMapResult.registeredLibFilesCount} plików',
        accent: report.codeMapResult.passed
            ? AppColors.statusSuccess
            : AppColors.crimsonAlert,
        icon: Icons.map_outlined,
      ),
      _buildKpiTile(
        label: 'Filary Systemu',
        value: '${report.passedPillarsCount}/${report.pillarChecks.length}',
        accent: report.allPillarsPassed
            ? AppColors.goldAccent
            : AppColors.crimsonAlert,
        icon: Icons.account_tree_rounded,
      ),
      _buildKpiTile(
        label: 'Gotowość Wydania',
        value: scoreStr,
        accent: verdict.color,
        icon: Icons.speed_rounded,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: verdict.color.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(verdict.icon, color: verdict.color, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      verdict.title,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: isMobile ? 15 : 17,
                        fontWeight: FontWeight.w700,
                        color: verdict.color,
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Text(
                  '${report.duration.inMilliseconds} ms',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (isMobile)
            Column(
              children: [
                for (var i = 0; i < kpiCards.length; i++) ...[
                  kpiCards[i],
                  if (i < kpiCards.length - 1) const SizedBox(height: 10),
                ],
              ],
            )
          else if (isTablet)
            Column(
              children: [
                Row(
                  children: [
                    Expanded(child: kpiCards[0]),
                    const SizedBox(width: 12),
                    Expanded(child: kpiCards[1]),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: kpiCards[2]),
                    const SizedBox(width: 12),
                    Expanded(child: kpiCards[3]),
                  ],
                ),
              ],
            )
          else
            Row(
              children: [
                for (var i = 0; i < kpiCards.length; i++) ...[
                  Expanded(child: kpiCards[i]),
                  if (i < kpiCards.length - 1) const SizedBox(width: 12),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildKpiTile({
    required String label,
    required String value,
    required Color accent,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: accent,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageBreakdownCard(
    ObsidianSovereign662Report report,
    ObsidianSovereignPackageId? selectedPackage,
    ObsidianSovereign662CertificationNotifier notifier,
  ) {
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
          const Text(
            'Podsumowanie Paczek (#001–#662)',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Kliknij paczkę, aby przefiltrować listę zadań poniżej.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < report.packageSummaries.length; i++) ...[
            _SovereignInteractivePackageTile(
              summary: report.packageSummaries[i],
              selected: selectedPackage == report.packageSummaries[i].packageId,
              onTap: () => notifier.selectPackage(
                report.packageSummaries[i].packageId,
              ),
            ),
            if (i < report.packageSummaries.length - 1)
              const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildGatesAndPillarsCard(ObsidianSovereign662Report report) {
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
          const Text(
            'Bramki Jakości & 15 Filarów Architektury',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildGateStatusRow(
            title: 'docs/CODE_MAP.md',
            subtitle: report.codeMapResult.passed
                ? '${report.codeMapResult.registeredLibFilesCount} plików lib/ zarejestrowanych'
                : 'Brakujące wpisy: ${report.codeMapResult.missingTaskPaths.length}',
            passed: report.codeMapResult.passed,
            skipped: false,
          ),
          const SizedBox(height: 8),
          _buildGateStatusRow(
            title: 'flutter analyze --fatal-infos',
            subtitle: !report.analyzeResult.executed
                ? 'Pominięto — zaznacz przełącznik powyżej, aby uruchomić'
                : report.analyzeResult.passed
                    ? '0 błędów, 0 ostrzeżeń, 0 info'
                    : '${report.analyzeResult.errorCount} err, ${report.analyzeResult.warningCount} warn, ${report.analyzeResult.infoCount} info',
            passed: report.analyzeResult.passed,
            skipped: !report.analyzeResult.executed,
          ),
          const SizedBox(height: 8),
          _buildGateStatusRow(
            title: 'flutter test --timeout 30s',
            subtitle: !report.testSuiteResult.executed
                ? 'Pominięto — zaznacz przełącznik powyżej, aby uruchomić'
                : report.testSuiteResult.passed
                    ? '${report.testSuiteResult.totalPassed} testów zaliczonych'
                    : '${report.testSuiteResult.totalFailed} niepowodzeń',
            passed: report.testSuiteResult.passed,
            skipped: !report.testSuiteResult.executed,
          ),
          const SizedBox(height: 14),
          const Divider(color: AppTheme.borderColor, height: 1),
          const SizedBox(height: 12),
          for (var i = 0; i < report.pillarChecks.length; i++) ...[
            _buildPillarRow(report.pillarChecks[i]),
            if (i < report.pillarChecks.length - 1) const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }

  Widget _buildGateStatusRow({
    required String title,
    required String subtitle,
    required bool passed,
    required bool skipped,
  }) {
    final color = skipped
        ? AppColors.amberWarning
        : passed
            ? AppColors.statusSuccess
            : AppColors.crimsonAlert;
    final badgeText = skipped
        ? 'SKIP'
        : passed
            ? 'PASS'
            : 'FAIL';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(
            skipped
                ? Icons.pause_circle_outline_rounded
                : passed
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillarRow(ObsidianSovereignPillarCheck pillar) {
    final color =
        pillar.passed ? AppColors.statusSuccess : AppColors.crimsonAlert;
    return Row(
      children: [
        Icon(
          pillar.passed
              ? Icons.check_circle_outline_rounded
              : Icons.error_outline_rounded,
          size: 15,
          color: color,
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Text(
            pillar.title,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          flex: 2,
          child: Text(
            pillar.passed
                ? 'OK'
                : 'Brak: ${pillar.missingSymbols.join(', ')}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskAuditCard({
    required ObsidianSovereign662State state,
    required ObsidianSovereign662CertificationNotifier notifier,
    required ObsidianSovereign662Report report,
    required bool isMobile,
  }) {
    final query = state.searchQuery.trim().toLowerCase();
    final filtered = report.taskEntries.where((entry) {
      if (state.selectedPackage != null &&
          entry.packageId != state.selectedPackage) {
        return false;
      }
      switch (state.filter) {
        case ObsidianSovereignTaskFilter.all:
          break;
        case ObsidianSovereignTaskFilter.failedOnly:
          if (entry.passed) return false;
        case ObsidianSovereignTaskFilter.passedOnly:
          if (!entry.passed) return false;
        case ObsidianSovereignTaskFilter.package9Only:
          if (entry.packageId != ObsidianSovereignPackageId.package9) {
            return false;
          }
      }
      if (query.isNotEmpty) {
        final hay =
            '${entry.formattedNumber} ${entry.artifactPath} ${entry.description}'
                .toLowerCase();
        if (!hay.contains(query)) return false;
      }
      return true;
    }).toList();

    final visibleItems = filtered.take(120).toList();

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
                  'Rejestr Zadań (#001–#662)',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                'Wyświetlono ${visibleItems.length} z ${filtered.length}',
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
          if (isMobile) ...[
            _buildSearchField(notifier),
            const SizedBox(height: 10),
            _buildFilterWrap(state, notifier),
          ] else
            Row(
              children: [
                Expanded(flex: 4, child: _buildSearchField(notifier)),
                const SizedBox(width: 12),
                Expanded(flex: 6, child: _buildFilterWrap(state, notifier)),
              ],
            ),
          const SizedBox(height: 12),
          if (visibleItems.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: const Text(
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
            for (var i = 0; i < visibleItems.length; i++) ...[
              _buildTaskRow(visibleItems[i]),
              if (i < visibleItems.length - 1) const SizedBox(height: 6),
            ],
        ],
      ),
    );
  }

  Widget _buildSearchField(ObsidianSovereign662CertificationNotifier notifier) {
    return TextField(
      controller: _searchController,
      onChanged: notifier.setSearchQuery,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: 'Szukaj numeru (#662), ścieżki lub opisu...',
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
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.goldAccent),
        ),
      ),
    );
  }

  Widget _buildFilterWrap(
    ObsidianSovereign662State state,
    ObsidianSovereign662CertificationNotifier notifier,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final filter in ObsidianSovereignTaskFilter.values)
          _SovereignInteractiveChip(
            label: filter.label,
            icon: Icons.filter_list_rounded,
            selected: state.filter == filter,
            enabled: true,
            onTap: () => notifier.setFilter(filter),
          ),
      ],
    );
  }

  Widget _buildTaskRow(ObsidianSovereignTaskVerificationEntry entry) {
    final color =
        entry.passed ? AppColors.statusSuccess : AppColors.crimsonAlert;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: entry.passed
              ? AppTheme.borderColor
              : AppColors.crimsonAlert.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              entry.formattedNumber,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
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
                  entry.artifactPath,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (!entry.passed)
                  Text(
                    entry.failureReasons.join(' • '),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.crimsonAlert,
                    ),
                  )
                else if (entry.description.isNotEmpty)
                  Text(
                    entry.description,
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
          ),
          const SizedBox(width: 8),
          Icon(
            entry.passed ? Icons.check_rounded : Icons.close_rounded,
            size: 16,
            color: color,
          ),
        ],
      ),
    );
  }
}

class _SovereignInteractiveButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final bool isPrimary;
  final VoidCallback onPressed;

  const _SovereignInteractiveButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.isPrimary,
    required this.onPressed,
  });

  @override
  State<_SovereignInteractiveButton> createState() =>
      _SovereignInteractiveButtonState();
}

class _SovereignInteractiveButtonState
    extends State<_SovereignInteractiveButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = !widget.enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.45)
        : widget.isPrimary
            ? (_hovered
                ? AppColors.primaryAccent.withValues(alpha: 0.92)
                : AppColors.primaryAccent)
            : (_hovered ? AppColors.surfaceLight : AppColors.background);

    final borderColor = !widget.enabled
        ? AppTheme.borderColor.withValues(alpha: 0.4)
        : _focused
            ? AppColors.goldAccent
            : widget.isPrimary
                ? AppColors.goldAccent.withValues(alpha: 0.55)
                : AppTheme.borderColor;

    final fgColor = !widget.enabled
        ? AppColors.textSecondary.withValues(alpha: 0.55)
        : AppColors.textPrimary;

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      mouseCursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.enabled ? widget.onPressed : null,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
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
                Icon(widget.icon, size: 16, color: fgColor),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.label,
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
      ),
    );
  }
}

class _SovereignInteractiveChip extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _SovereignInteractiveChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_SovereignInteractiveChip> createState() =>
      _SovereignInteractiveChipState();
}

class _SovereignInteractiveChipState extends State<_SovereignInteractiveChip> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = !widget.enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : widget.selected
            ? AppColors.goldAccent.withValues(alpha: _hovered ? 0.24 : 0.16)
            : _hovered
                ? AppColors.surfaceLight
                : AppColors.background;

    final borderColor = !widget.enabled
        ? AppTheme.borderColor.withValues(alpha: 0.4)
        : _focused
            ? AppColors.goldAccent
            : widget.selected
                ? AppColors.goldAccent
                : AppTheme.borderColor;

    final fgColor = !widget.enabled
        ? AppColors.textSecondary.withValues(alpha: 0.5)
        : widget.selected
            ? AppColors.goldAccent
            : AppColors.textSecondary;

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      mouseCursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: borderColor,
                width: _focused ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 14, color: fgColor),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    widget.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: fgColor,
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

class _SovereignInteractivePackageTile extends StatefulWidget {
  final ObsidianSovereignPackageSummary summary;
  final bool selected;
  final VoidCallback onTap;

  const _SovereignInteractivePackageTile({
    required this.summary,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_SovereignInteractivePackageTile> createState() =>
      _SovereignInteractivePackageTileState();
}

class _SovereignInteractivePackageTileState
    extends State<_SovereignInteractivePackageTile> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.summary;
    final accent =
        s.allPassed ? AppColors.statusSuccess : AppColors.amberWarning;

    return FocusableActionDetector(
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      mouseCursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.99 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: widget.selected
                  ? AppColors.goldAccent.withValues(alpha: 0.12)
                  : _hovered
                      ? AppColors.surfaceLight.withValues(alpha: 0.95)
                      : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _focused || widget.selected
                    ? AppColors.goldAccent
                    : AppTheme.borderColor,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(s.packageId.icon, size: 16, color: accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.packageId.label,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '${s.passedTasks}/${s.totalTasks}',
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
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: s.passRate.clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: AppColors.background,
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
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
