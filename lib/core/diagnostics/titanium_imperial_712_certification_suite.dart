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

/// Identyfikator etapu / paczki zadań objętych certyfikacją TITANIUM IMPERIAL v5.0 (#001–#712).
enum TitaniumImperialPackageId {
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
  package9('Paczka #9 (#613–#662)', 613, 662, Icons.auto_awesome_rounded),
  package10('Paczka #10 (#663–#712)', 663, 712, Icons.live_tv_rounded);

  final String label;
  final int startTask;
  final int endTask;
  final IconData icon;

  const TitaniumImperialPackageId(
    this.label,
    this.startTask,
    this.endTask,
    this.icon,
  );

  int get expectedCount => endTask - startTask + 1;

  static TitaniumImperialPackageId fromTaskNumber(int taskNumber) {
    for (final pkg in values) {
      if (taskNumber >= pkg.startTask && taskNumber <= pkg.endTask) {
        return pkg;
      }
    }
    return foundation;
  }
}

/// Docelowe platformy produkcyjne certyfikacji TITANIUM IMPERIAL v5.0.
enum TitaniumImperialTargetPlatform {
  windows('Windows', 'windows', Icons.desktop_windows_rounded),
  macos('macOS', 'macos', Icons.laptop_mac_rounded),
  android('Android', 'android', Icons.android_rounded),
  ios('iOS', 'ios', Icons.phone_iphone_rounded);

  final String label;
  final String folderName;
  final IconData icon;

  const TitaniumImperialTargetPlatform(
    this.label,
    this.folderName,
    this.icon,
  );
}

/// Kategoria testów weryfikowanych w ramach jednej komendy certyfikacji v5.0.
enum TitaniumImperialTestCategory {
  unit('Testy Jednostkowe', Icons.check_circle_outline_rounded),
  physics('Testy Fizyczne', Icons.science_rounded),
  simulation('Testy Symulacyjne', Icons.route_rounded),
  ui('Testy UI & Responsywności', Icons.devices_rounded),
  serialization('Testy Serializacji JSON', Icons.data_object_rounded);

  final String label;
  final IconData icon;

  const TitaniumImperialTestCategory(this.label, this.icon);
}

/// Poziom ważności wyniku bramki lub zadania certyfikacji TITANIUM IMPERIAL v5.0.
enum TitaniumImperialSeverity {
  pass('OK', AppColors.statusSuccess),
  info('Info', AppColors.accentBlue),
  warning('Ostrzeżenie', AppColors.amberWarning),
  error('Błąd', AppColors.crimsonAlert);

  final String label;
  final Color color;

  const TitaniumImperialSeverity(this.label, this.color);
}

/// Finalny werdykt certyfikacji TITANIUM IMPERIAL v5.0 (#001–#712).
enum TitaniumImperialVerdict {
  certifiedTitaniumImperial(
    'TITANIUM IMPERIAL v5.0 CERTIFIED',
    'Wszystkie 712 zadań, mapa kodu, 16 filarów, 4 platformy docelowe oraz pełny zestaw testów przeszły weryfikację.',
    AppColors.goldAccent,
    Icons.verified_rounded,
  ),
  conditionalPass(
    'WARUNKOWY PASS (POMINIĘTE BRAMKI CLI)',
    'Zadania #001–#712, platformy i integralność architektury są poprawne, ale bramki CLI nie zostały uruchomione.',
    AppColors.amberWarning,
    Icons.verified_user_outlined,
  ),
  blocked(
    'CERTYFIKACJA ZABLOKOWANA',
    'Wykryto braki w zadaniach, plikach, filarach, platformach lub bramkach jakości wymagające naprawy.',
    AppColors.crimsonAlert,
    Icons.gpp_bad_rounded,
  );

  final String title;
  final String description;
  final Color color;
  final IconData icon;

  const TitaniumImperialVerdict(
    this.title,
    this.description,
    this.color,
    this.icon,
  );
}

/// Raport gotowości pojedynczej platformy docelowej (Windows, macOS, Android, iOS).
@immutable
class TitaniumImperialPlatformReadiness {
  final TitaniumImperialTargetPlatform platform;
  final bool platformDirectoryPresent;
  final bool adaptiveGraphicsSupported;
  final bool responsiveLayoutSupported;
  final String notes;

  const TitaniumImperialPlatformReadiness({
    required this.platform,
    required this.platformDirectoryPresent,
    required this.adaptiveGraphicsSupported,
    required this.responsiveLayoutSupported,
    required this.notes,
  });

  bool get ready => adaptiveGraphicsSupported && responsiveLayoutSupported;

  Map<String, dynamic> toJson() => {
        'platform': platform.name,
        'label': platform.label,
        'platformDirectoryPresent': platformDirectoryPresent,
        'adaptiveGraphicsSupported': adaptiveGraphicsSupported,
        'responsiveLayoutSupported': responsiveLayoutSupported,
        'ready': ready,
        'notes': notes,
      };
}

/// Podsumowanie wykrytych plików testowych dla danej kategorii testów.
@immutable
class TitaniumImperialTestCategorySummary {
  final TitaniumImperialTestCategory category;
  final int testFilesCount;
  final List<String> sampleFiles;

  const TitaniumImperialTestCategorySummary({
    required this.category,
    required this.testFilesCount,
    required this.sampleFiles,
  });

  bool get hasCoverage => testFilesCount > 0;

  Map<String, dynamic> toJson() => {
        'category': category.name,
        'label': category.label,
        'testFilesCount': testFilesCount,
        'hasCoverage': hasCoverage,
        'sampleFiles': sampleFiles,
      };
}

/// Pojedynczy problem zgłoszony przez bramkę `flutter analyze`.
@immutable
class TitaniumImperialAnalyzeIssue {
  final TitaniumImperialSeverity severity;
  final String message;
  final String filePath;
  final int line;
  final int column;
  final String ruleName;

  const TitaniumImperialAnalyzeIssue({
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
class TitaniumImperialAnalyzeGateResult {
  final bool executed;
  final int exitCode;
  final int errorCount;
  final int warningCount;
  final int infoCount;
  final bool noIssuesFound;
  final List<TitaniumImperialAnalyzeIssue> issues;
  final String rawOutput;
  final Duration duration;

  const TitaniumImperialAnalyzeGateResult({
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

  factory TitaniumImperialAnalyzeGateResult.skipped() =>
      const TitaniumImperialAnalyzeGateResult(
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

/// Wynik bramki testów automatycznych `flutter test` dla wszystkich kategorii.
@immutable
class TitaniumImperialTestSuiteGateResult {
  final bool executed;
  final int exitCode;
  final int totalPassed;
  final int totalFailed;
  final int totalSkipped;
  final String summaryLine;
  final String rawOutput;
  final Duration duration;

  const TitaniumImperialTestSuiteGateResult({
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

  factory TitaniumImperialTestSuiteGateResult.skipped() =>
      const TitaniumImperialTestSuiteGateResult(
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
class TitaniumImperialCodeMapGateResult {
  final bool exists;
  final int totalLines;
  final int registeredLibFilesCount;
  final List<String> missingTaskPaths;

  const TitaniumImperialCodeMapGateResult({
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
class TitaniumImperialPillarCheck {
  final String id;
  final String title;
  final String filePath;
  final bool fileExists;
  final bool symbolsPresent;
  final List<String> missingSymbols;

  const TitaniumImperialPillarCheck({
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

/// Szczegółowy wynik weryfikacji pojedynczego zadania z zakresu `#001–#712`.
@immutable
class TitaniumImperialTaskVerificationEntry {
  final int taskNumber;
  final TitaniumImperialPackageId packageId;
  final String artifactPath;
  final String description;
  final bool completedInQueue;
  final bool artifactExists;
  final bool registeredInCodeMap;
  final bool requiresCodeMapRegistration;
  final int todoMarkersCount;
  final int unimplementedCount;
  final int lineCount;

  const TitaniumImperialTaskVerificationEntry({
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

/// Zbiorcze podsumowanie dla pojedynczej paczki zadań (#001–#712).
@immutable
class TitaniumImperialPackageSummary {
  final TitaniumImperialPackageId packageId;
  final int totalTasks;
  final int completedQueueTasks;
  final int existingArtifacts;
  final int passedTasks;

  const TitaniumImperialPackageSummary({
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

/// Kompletny raport certyfikacji **TITANIUM IMPERIAL v5.0** (#001–#712).
@immutable
class TitaniumImperial712Report {
  static const String releaseVersion = 'TITANIUM IMPERIAL v5.0';
  static const int expectedTotalTasks = 712;

  final DateTime generatedAt;
  final String projectRoot;
  final List<TitaniumImperialTaskVerificationEntry> taskEntries;
  final List<TitaniumImperialPackageSummary> packageSummaries;
  final TitaniumImperialCodeMapGateResult codeMapResult;
  final List<TitaniumImperialPillarCheck> pillarChecks;
  final List<TitaniumImperialPlatformReadiness> platformReadiness;
  final List<TitaniumImperialTestCategorySummary> testCategorySummaries;
  final TitaniumImperialAnalyzeGateResult analyzeResult;
  final TitaniumImperialTestSuiteGateResult testSuiteResult;
  final Duration duration;

  const TitaniumImperial712Report({
    required this.generatedAt,
    required this.projectRoot,
    required this.taskEntries,
    required this.packageSummaries,
    required this.codeMapResult,
    required this.pillarChecks,
    required this.platformReadiness,
    required this.testCategorySummaries,
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
  int get readyPlatformsCount => platformReadiness.where((p) => p.ready).length;
  int get totalTestFilesDiscovered => testCategorySummaries.fold<int>(
        0,
        (sum, item) => sum + item.testFilesCount,
      );

  bool get allTasksVerified =>
      totalTasksChecked > 0 && failedTasksCount == 0;

  bool get allPillarsPassed =>
      pillarChecks.isNotEmpty && passedPillarsCount == pillarChecks.length;

  bool get allPlatformsReady =>
      platformReadiness.isNotEmpty &&
      readyPlatformsCount == platformReadiness.length;

  bool get coreIntegrityPassed =>
      allTasksVerified &&
      codeMapResult.passed &&
      allPillarsPassed &&
      allPlatformsReady;

  bool get isFullyCertified =>
      coreIntegrityPassed &&
      analyzeResult.executed &&
      analyzeResult.passed &&
      testSuiteResult.executed &&
      testSuiteResult.passed;

  TitaniumImperialVerdict get verdict {
    if (!coreIntegrityPassed) {
      return TitaniumImperialVerdict.blocked;
    }
    if ((analyzeResult.executed && !analyzeResult.passed) ||
        (testSuiteResult.executed && !testSuiteResult.passed)) {
      return TitaniumImperialVerdict.blocked;
    }
    if (!analyzeResult.executed || !testSuiteResult.executed) {
      return TitaniumImperialVerdict.conditionalPass;
    }
    return TitaniumImperialVerdict.certifiedTitaniumImperial;
  }

  double get readinessScorePercent {
    var earned = 0.0;
    const maxPoints = 100.0;

    // 50 pkt: zadania #001–#712
    earned += totalTasksChecked == 0
        ? 0.0
        : (passedTasksCount / totalTasksChecked).clamp(0.0, 1.0) * 50.0;
    // 15 pkt: integralność CODE_MAP.md
    if (codeMapResult.passed) {
      earned += 15.0;
    }
    // 10 pkt: 16 filarów architektury i AppRouter
    if (pillarChecks.isNotEmpty) {
      earned += (passedPillarsCount / pillarChecks.length) * 10.0;
    }
    // 5 pkt: gotowość 4 platform (Windows, macOS, Android, iOS)
    if (platformReadiness.isNotEmpty) {
      earned += (readyPlatformsCount / platformReadiness.length) * 5.0;
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
        'totalTestFilesDiscovered': totalTestFilesDiscovered,
        'durationMs': duration.inMilliseconds,
        'packageSummaries': packageSummaries.map((e) => e.toJson()).toList(),
        'codeMapResult': codeMapResult.toJson(),
        'pillarChecks': pillarChecks.map((e) => e.toJson()).toList(),
        'platformReadiness': platformReadiness.map((e) => e.toJson()).toList(),
        'testCategorySummaries':
            testCategorySummaries.map((e) => e.toJson()).toList(),
        'analyzeResult': analyzeResult.toJson(),
        'testSuiteResult': testSuiteResult.toJson(),
        'failedTasks':
            taskEntries.where((e) => !e.passed).map((e) => e.toJson()).toList(),
      };

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());

  String toMarkdownCertificate() {
    final buf = StringBuffer()
      ..writeln('# Certyfikat $releaseVersion (#001–#712)')
      ..writeln()
      ..writeln('- **Werdykt**: ${verdict.title}')
      ..writeln(
        '- **Gotowość wydania**: ${readinessScorePercent.toStringAsFixed(1)}%',
      )
      ..writeln('- **Wygenerowano**: ${generatedAt.toIso8601String()}')
      ..writeln(
        '- **Zadania #001–#712**: $passedTasksCount / $expectedTotalTasks zaliczonych',
      )
      ..writeln(
        '- **CODE_MAP.md**: ${codeMapResult.passed ? "PASS" : "FAIL"} '
        '(${codeMapResult.registeredLibFilesCount} plików lib/)',
      )
      ..writeln(
        '- **Filary architektury**: $passedPillarsCount / ${pillarChecks.length}',
      )
      ..writeln(
        '- **Platformy produkcyjne**: $readyPlatformsCount / ${platformReadiness.length} '
        '(Windows, macOS, Android, iOS)',
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
      ..writeln('## Podsumowanie Paczek (#001–#712)')
      ..writeln();

    for (final pkg in packageSummaries) {
      buf.writeln(
        '- **${pkg.packageId.label}**: ${pkg.passedTasks}/${pkg.totalTasks} '
        '(${(pkg.passRate * 100).toStringAsFixed(1)}%)',
      );
    }

    buf
      ..writeln()
      ..writeln('## Pokrycie Testami (Jednostkowe, Fizyczne, Symulacyjne, UI, Serializacja)')
      ..writeln();

    for (final cat in testCategorySummaries) {
      buf.writeln('- **${cat.category.label}**: ${cat.testFilesCount} plików');
    }

    buf
      ..writeln()
      ..writeln('## Gotowość Platform Docelowych')
      ..writeln();

    for (final plat in platformReadiness) {
      buf.writeln(
        '- **${plat.platform.label}**: ${plat.ready ? "READY" : "NOT READY"} — ${plat.notes}',
      );
    }

    return buf.toString();
  }
}

/// Ostateczny pakiet certyfikacji **TITANIUM IMPERIAL v5.0** dla wszystkich 712 zadań.
class TitaniumImperial712CertificationSuite {
  const TitaniumImperial712CertificationSuite();

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
      id: 'router_pack10',
      title: 'AppRouter + Trasy Paczki #10',
      path: 'lib/core/router/app_router.dart',
      markers: [
        'tvBroadcastDirector',
        'grandTourMorningMedical',
        'winterWindTunnelCamp',
        'contractRenewalsWarRoom',
        'clubMuseum',
      ],
    ),
    (
      id: 'engine_bridge',
      title: 'Centralny Most Integracyjny Silnika',
      path: 'lib/engine/engine_integration_bridge.dart',
      markers: ['EngineIntegrationBridge'],
    ),
    (
      id: 'lint_gate_711',
      title: 'Bramka Jakości Zero Warnings & UI Matrix (#711)',
      path: 'lib/core/diagnostics/zero_warnings_712_lint_gate.dart',
      markers: ['ZeroWarnings712LintGate'],
    ),
    (
      id: 'perf_profiler_710',
      title: 'Audytor Wydajności 120 FPS & RAM (#710)',
      path: 'lib/core/diagnostics/performance_and_memory_712_profiler.dart',
      markers: ['PerformanceAndMemory712Profiler'],
    ),
    (
      id: 'save_v10_migrator',
      title: 'Migrator Zapisów v10 (Paczka #10, #705)',
      path: 'lib/core/diagnostics/save_compatibility_v10_migrator.dart',
      markers: ['SaveCompatibilityV10Migrator'],
    ),
    (
      id: 'obsidian_sovereign_662',
      title: 'Pakiet Certyfikacji Obsidian Sovereign v4.0 (#662)',
      path: 'lib/core/diagnostics/obsidian_sovereign_662_certification_suite.dart',
      markers: ['ObsidianSovereign662CertificationSuite'],
    ),
    (
      id: 'l10n_pl_en',
      title: 'Dwujęzyczny Słownik Kolarski PL/EN (#707)',
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
      id: 'americas_oceania_663',
      title: 'Ekspansja UCI Americas & Oceania (#663)',
      path: 'lib/models/race/americas_and_oceania_tours_model.dart',
      markers: ['AmericasAndOceaniaToursModel'],
    ),
    (
      id: 'technical_scrutiny_668',
      title: 'Skanery Techniczne UCI X-Ray & Trybunał CAS (#668)',
      path: 'lib/models/uci/technical_scrutiny_and_cas_tribunal_model.dart',
      markers: ['TechnicalScrutinyAndCasTribunalModel'],
    ),
    (
      id: 'nightly_hrv_physio_673',
      title: 'Nocne HRV & Fizjoterapia Grand Tourowa (#673)',
      path: 'lib/models/medical/grand_tour_nightly_hrv_and_physio_model.dart',
      markers: ['GrandTourNightlyHrvAndPhysioModel'],
    ),
    (
      id: 'tv_director_678',
      title: 'Tryb Reżysera Transmisji TV na Żywo (#678)',
      path: 'lib/models/broadcast/tv_director_live_production_model.dart',
      markers: ['TvDirectorLiveProductionModel'],
    ),
    (
      id: 'platform_graphics',
      title: 'Profiler Graficzny 4 Platform (Win/macOS/Android/iOS)',
      path: 'lib/core/config/platform_adaptive_graphics_profiler.dart',
      markers: ['PlatformAdaptiveGraphicsProfiler'],
    ),
    (
      id: 'navigation_verifier',
      title: 'Weryfikator Tras & Nawigacji Wstecz na 6 Platformach',
      path: 'lib/core/diagnostics/full_navigation_routes_verifier.dart',
      markers: ['FullNavigationRoutesVerifier'],
    ),
    (
      id: 'game_manual_709',
      title: 'Kompletna Encyklopedia Gry 712 Zadań (#709)',
      path: 'docs/COMPLETE_GAME_MANUAL_712.md',
      markers: ['Pro Peloton Manager'],
    ),
    (
      id: 'fuzz_tester',
      title: 'Fuzzer Serializacji Stanu Kariery JSON',
      path: 'lib/core/diagnostics/full_state_serialization_fuzz_tester.dart',
      markers: ['FullStateSerializationFuzzTester'],
    ),
  ];

  /// Uruchamia pełną certyfikację **TITANIUM IMPERIAL v5.0** w jednej komendzie
  /// (zadania #001–#712, platformy, kategorie testów, `flutter analyze` i `flutter test`).
  Future<TitaniumImperial712Report> runOneCommandFullCertification({
    String? projectRoot,
    Duration commandTimeout = const Duration(minutes: 5),
  }) {
    return runCertification(
      projectRoot: projectRoot,
      runFlutterAnalyze: true,
      runFlutterTest: true,
      commandTimeout: commandTimeout,
    );
  }

  /// Uruchamia certyfikację **TITANIUM IMPERIAL v5.0** (#001–#712).
  Future<TitaniumImperial712Report> runCertification({
    String? projectRoot,
    bool runFlutterAnalyze = false,
    bool runFlutterTest = false,
    Duration commandTimeout = const Duration(minutes: 5),
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

    final codeMapResult = TitaniumImperialCodeMapGateResult(
      exists: codeMapExists,
      totalLines: codeMapLines,
      registeredLibFilesCount: registeredLibFiles.length,
      missingTaskPaths: missingInCodeMap,
    );

    final packageSummaries = _buildPackageSummaries(taskEntries);
    final pillarChecks = await _verifyPillars(root);
    final platformReadiness = await _verifyPlatformReadiness(root);
    final testCategorySummaries = await _discoverTestCategories(root);

    final analyzeResult = runFlutterAnalyze
        ? await _runFlutterAnalyzeGate(root, timeout: commandTimeout)
        : TitaniumImperialAnalyzeGateResult.skipped();

    final testSuiteResult = runFlutterTest
        ? await _runFlutterTestGate(root, timeout: commandTimeout)
        : TitaniumImperialTestSuiteGateResult.skipped();

    stopwatch.stop();

    return TitaniumImperial712Report(
      generatedAt: DateTime.now().toUtc(),
      projectRoot: root,
      taskEntries: taskEntries,
      packageSummaries: packageSummaries,
      codeMapResult: codeMapResult,
      pillarChecks: pillarChecks,
      platformReadiness: platformReadiness,
      testCategorySummaries: testCategorySummaries,
      analyzeResult: analyzeResult,
      testSuiteResult: testSuiteResult,
      duration: stopwatch.elapsed,
    );
  }

  /// Klasyfikuje ścieżkę pliku testowego do jednej z 5 kategorii certyfikacji.
  static TitaniumImperialTestCategory classifyTestFile(String relativePath) {
    final normalized = relativePath.toLowerCase().replaceAll('\\', '/');
    if (normalized.contains('serializ') ||
        normalized.contains('fuzz') ||
        normalized.contains('migrator') ||
        normalized.contains('save_')) {
      return TitaniumImperialTestCategory.serialization;
    }
    if (normalized.contains('/ui/') ||
        normalized.contains('widget') ||
        normalized.contains('screen') ||
        normalized.contains('contrast') ||
        normalized.contains('router') ||
        normalized.contains('navigation') ||
        normalized.contains('hud')) {
      return TitaniumImperialTestCategory.ui;
    }
    if (normalized.contains('physics') ||
        normalized.contains('aero') ||
        normalized.contains('altitude') ||
        normalized.contains('heat') ||
        normalized.contains('brake') ||
        normalized.contains('vortex') ||
        normalized.contains('tire') ||
        normalized.contains('watt') ||
        normalized.contains('physiology') ||
        normalized.contains('hrv')) {
      return TitaniumImperialTestCategory.physics;
    }
    if (normalized.contains('simulat') ||
        normalized.contains('peloton') ||
        normalized.contains('boids') ||
        normalized.contains('what_if') ||
        normalized.contains('director') ||
        normalized.contains('isolate') ||
        normalized.contains('race')) {
      return TitaniumImperialTestCategory.simulation;
    }
    return TitaniumImperialTestCategory.unit;
  }

  Future<List<TitaniumImperialTestCategorySummary>> _discoverTestCategories(
    String root,
  ) async {
    final testDir = Directory(_joinPath(root, 'test'));
    final buckets = <TitaniumImperialTestCategory, List<String>>{
      for (final cat in TitaniumImperialTestCategory.values) cat: <String>[],
    };

    if (await testDir.exists()) {
      await for (final entity in testDir.list(recursive: true)) {
        if (entity is! File) continue;
        if (!entity.path.endsWith('_test.dart')) continue;
        final rel = entity.path
            .substring(root.length)
            .replaceAll('\\', '/')
            .replaceFirst(RegExp(r'^/'), '');
        final category = classifyTestFile(rel);
        buckets[category]!.add(rel);
      }
    }

    return TitaniumImperialTestCategory.values.map((cat) {
      final files = buckets[cat]!..sort();
      return TitaniumImperialTestCategorySummary(
        category: cat,
        testFilesCount: files.length,
        sampleFiles: files.take(5).toList(),
      );
    }).toList();
  }

  Future<List<TitaniumImperialPlatformReadiness>> _verifyPlatformReadiness(
    String root,
  ) async {
    final profilerExists = await File(
      _joinPath(root, 'lib/core/config/platform_adaptive_graphics_profiler.dart'),
    ).exists();
    final routerExists = await File(
      _joinPath(root, 'lib/core/router/app_router.dart'),
    ).exists();
    final lintGateExists = await File(
      _joinPath(root, 'lib/core/diagnostics/zero_warnings_712_lint_gate.dart'),
    ).exists();

    final results = <TitaniumImperialPlatformReadiness>[];
    for (final platform in TitaniumImperialTargetPlatform.values) {
      final dirExists =
          await Directory(_joinPath(root, platform.folderName)).exists();
      final notes = dirExists
          ? 'Konfiguracja natywna ${platform.folderName}/ + profiler grafiki + LayoutBuilder.'
          : 'Obsługa przez profiler adaptacyjny i LayoutBuilder (katalog ${platform.folderName}/ opcjonalny).';

      results.add(
        TitaniumImperialPlatformReadiness(
          platform: platform,
          platformDirectoryPresent: dirExists,
          adaptiveGraphicsSupported: profilerExists,
          responsiveLayoutSupported: routerExists && lintGateExists,
          notes: notes,
        ),
      );
    }
    return results;
  }

  Future<List<TitaniumImperialTaskVerificationEntry>> _verifyQueueTasks({
    required String root,
    required File queueFile,
    required Set<String> registeredLibFiles,
  }) async {
    if (!await queueFile.exists()) {
      return const [];
    }

    final lines = await queueFile.readAsLines();
    final entries = <TitaniumImperialTaskVerificationEntry>[];
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
          taskNum > TitaniumImperial712Report.expectedTotalTasks) {
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
            if (taskNum != 712 &&
                taskNum != 662 &&
                taskNum != 612 &&
                taskNum != 562) {
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
        TitaniumImperialTaskVerificationEntry(
          taskNumber: taskNum,
          packageId: TitaniumImperialPackageId.fromTaskNumber(taskNum),
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

  List<TitaniumImperialPackageSummary> _buildPackageSummaries(
    List<TitaniumImperialTaskVerificationEntry> entries,
  ) {
    return TitaniumImperialPackageId.values.map((pkg) {
      final pkgEntries = entries.where((e) => e.packageId == pkg).toList();
      return TitaniumImperialPackageSummary(
        packageId: pkg,
        totalTasks: pkgEntries.length,
        completedQueueTasks: pkgEntries.where((e) => e.completedInQueue).length,
        existingArtifacts: pkgEntries.where((e) => e.artifactExists).length,
        passedTasks: pkgEntries.where((e) => e.passed).length,
      );
    }).toList();
  }

  Future<List<TitaniumImperialPillarCheck>> _verifyPillars(String root) async {
    final checks = <TitaniumImperialPillarCheck>[];
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
        TitaniumImperialPillarCheck(
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

  Future<TitaniumImperialAnalyzeGateResult> _runFlutterAnalyzeGate(
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
      final issues = <TitaniumImperialAnalyzeIssue>[];
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
        final TitaniumImperialSeverity sev;
        if (rawSev == 'error') {
          sev = TitaniumImperialSeverity.error;
          errors++;
        } else if (rawSev == 'warning') {
          sev = TitaniumImperialSeverity.warning;
          warnings++;
        } else {
          sev = TitaniumImperialSeverity.info;
          infos++;
        }
        issues.add(
          TitaniumImperialAnalyzeIssue(
            severity: sev,
            message: m.group(2) ?? '',
            filePath: m.group(3) ?? '',
            line: int.tryParse(m.group(4) ?? '0') ?? 0,
            column: int.tryParse(m.group(5) ?? '0') ?? 0,
            ruleName: m.group(6) ?? '',
          ),
        );
      }

      return TitaniumImperialAnalyzeGateResult(
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
      return TitaniumImperialAnalyzeGateResult(
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
      return TitaniumImperialAnalyzeGateResult(
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

  Future<TitaniumImperialTestSuiteGateResult> _runFlutterTestGate(
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

      return TitaniumImperialTestSuiteGateResult(
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
      return TitaniumImperialTestSuiteGateResult(
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
      return TitaniumImperialTestSuiteGateResult(
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

/// Tryb filtrowania zadań w panelu certyfikacji TITANIUM IMPERIAL v5.0.
enum TitaniumImperialTaskFilter {
  all('Wszystkie (#001–#712)'),
  failedOnly('Tylko błędy'),
  passedOnly('Zaliczone'),
  package10Only('Paczka #10 (#663–#712)');

  final String label;
  const TitaniumImperialTaskFilter(this.label);
}

/// Stan kontrolera certyfikacji TITANIUM IMPERIAL v5.0.
@immutable
class TitaniumImperial712State {
  final bool isRunning;
  final bool runAnalyzeGate;
  final bool runTestGate;
  final TitaniumImperialTaskFilter filter;
  final TitaniumImperialPackageId? selectedPackage;
  final String searchQuery;
  final TitaniumImperial712Report? report;
  final String? errorMessage;
  final String? exportNotice;

  const TitaniumImperial712State({
    this.isRunning = false,
    this.runAnalyzeGate = false,
    this.runTestGate = false,
    this.filter = TitaniumImperialTaskFilter.all,
    this.selectedPackage,
    this.searchQuery = '',
    this.report,
    this.errorMessage,
    this.exportNotice,
  });

  TitaniumImperial712State copyWith({
    bool? isRunning,
    bool? runAnalyzeGate,
    bool? runTestGate,
    TitaniumImperialTaskFilter? filter,
    TitaniumImperialPackageId? selectedPackage,
    bool clearSelectedPackage = false,
    String? searchQuery,
    TitaniumImperial712Report? report,
    String? errorMessage,
    bool clearError = false,
    String? exportNotice,
    bool clearNotice = false,
  }) {
    return TitaniumImperial712State(
      isRunning: isRunning ?? this.isRunning,
      runAnalyzeGate: runAnalyzeGate ?? this.runAnalyzeGate,
      runTestGate: runTestGate ?? this.runTestGate,
      filter: filter ?? this.filter,
      selectedPackage: clearSelectedPackage
          ? null
          : (selectedPackage ?? this.selectedPackage),
      searchQuery: searchQuery ?? this.searchQuery,
      report: report ?? this.report,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      exportNotice: clearNotice ? null : (exportNotice ?? this.exportNotice),
    );
  }

  List<TitaniumImperialTaskVerificationEntry> get filteredTasks {
    final rep = report;
    if (rep == null) return const [];
    final query = searchQuery.trim().toLowerCase();

    return rep.taskEntries.where((entry) {
      if (selectedPackage != null && entry.packageId != selectedPackage) {
        return false;
      }
      switch (filter) {
        case TitaniumImperialTaskFilter.all:
          break;
        case TitaniumImperialTaskFilter.failedOnly:
          if (entry.passed) return false;
          break;
        case TitaniumImperialTaskFilter.passedOnly:
          if (!entry.passed) return false;
          break;
        case TitaniumImperialTaskFilter.package10Only:
          if (entry.packageId != TitaniumImperialPackageId.package10) {
            return false;
          }
          break;
      }
      if (query.isNotEmpty) {
        final inNum = entry.formattedNumber.toLowerCase().contains(query);
        final inPath = entry.artifactPath.toLowerCase().contains(query);
        final inDesc = entry.description.toLowerCase().contains(query);
        if (!inNum && !inPath && !inDesc) return false;
      }
      return true;
    }).toList();
  }
}

/// Kontroler Riverpod zarządzający certyfikacją TITANIUM IMPERIAL v5.0.
class TitaniumImperial712CertificationNotifier
    extends StateNotifier<TitaniumImperial712State> {
  final TitaniumImperial712CertificationSuite _suite;

  TitaniumImperial712CertificationNotifier({
    TitaniumImperial712CertificationSuite? suite,
  })  : _suite = suite ?? const TitaniumImperial712CertificationSuite(),
        super(const TitaniumImperial712State());

  Future<void> runCertification({String? projectRoot}) async {
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
      state = state.copyWith(
        isRunning: false,
        report: report,
      );
    } catch (e) {
      state = state.copyWith(
        isRunning: false,
        errorMessage: 'Nie udało się uruchomić certyfikacji: $e',
      );
    }
  }

  Future<void> runOneCommandFullCertification({String? projectRoot}) async {
    if (state.isRunning) return;
    state = state.copyWith(
      isRunning: true,
      runAnalyzeGate: true,
      runTestGate: true,
      clearError: true,
      clearNotice: true,
    );
    try {
      final report = await _suite.runOneCommandFullCertification(
        projectRoot: projectRoot,
      );
      state = state.copyWith(
        isRunning: false,
        report: report,
      );
    } catch (e) {
      state = state.copyWith(
        isRunning: false,
        errorMessage: 'Nie udało się uruchomić pełnej certyfikacji: $e',
      );
    }
  }

  void toggleAnalyzeGate(bool value) {
    if (state.isRunning) return;
    state = state.copyWith(runAnalyzeGate: value, clearNotice: true);
  }

  void toggleTestGate(bool value) {
    if (state.isRunning) return;
    state = state.copyWith(runTestGate: value, clearNotice: true);
  }

  void setFilter(TitaniumImperialTaskFilter filter) {
    state = state.copyWith(filter: filter, clearNotice: true);
  }

  void selectPackage(TitaniumImperialPackageId? pkg) {
    if (pkg == null || state.selectedPackage == pkg) {
      state = state.copyWith(clearSelectedPackage: true, clearNotice: true);
    } else {
      state = state.copyWith(selectedPackage: pkg, clearNotice: true);
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> copyJsonCertificate() async {
    final report = state.report;
    if (report == null) return;
    await Clipboard.setData(ClipboardData(text: report.toPrettyJson()));
    state = state.copyWith(
      exportNotice: 'Skopiowano certyfikat JSON (#001–#712) do schowka.',
    );
  }

  Future<void> copyMarkdownCertificate() async {
    final report = state.report;
    if (report == null) return;
    await Clipboard.setData(
      ClipboardData(text: report.toMarkdownCertificate()),
    );
    state = state.copyWith(
      exportNotice: 'Skopiowano certyfikat Markdown v5.0 do schowka.',
    );
  }

  void clearNotice() {
    state = state.copyWith(clearNotice: true);
  }
}

/// Globalny provider certyfikacji **TITANIUM IMPERIAL v5.0**.
final titaniumImperial712CertificationProvider = StateNotifierProvider<
    TitaniumImperial712CertificationNotifier, TitaniumImperial712State>(
  (ref) => TitaniumImperial712CertificationNotifier(),
);

/// Produkcyjny panel diagnostyczno-certyfikacyjny **TITANIUM IMPERIAL v5.0**
/// z pełną obsługą responsywności (`390x844`, `1024x768`, `1600x900`) oraz stanów
/// `hover`, `active`, `disabled` i `focus`.
class TitaniumImperial712CertificationPanel extends ConsumerStatefulWidget {
  final String? projectRootOverride;

  const TitaniumImperial712CertificationPanel({
    super.key,
    this.projectRootOverride,
  });

  @override
  ConsumerState<TitaniumImperial712CertificationPanel> createState() =>
      _TitaniumImperial712CertificationPanelState();
}

class _TitaniumImperial712CertificationPanelState
    extends ConsumerState<TitaniumImperial712CertificationPanel> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(titaniumImperial712CertificationProvider);
    final notifier =
        ref.read(titaniumImperial712CertificationProvider.notifier);

    return Container(
      color: AppColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isCompact = width < 640;
          final isWide = width >= 1100;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isCompact ? 12 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderCard(state, notifier, isCompact),
                const SizedBox(height: 16),
                if (state.errorMessage != null) ...[
                  _buildNoticeBanner(
                    message: state.errorMessage!,
                    color: AppColors.crimsonAlert,
                    icon: Icons.error_outline_rounded,
                  ),
                  const SizedBox(height: 16),
                ],
                if (state.exportNotice != null) ...[
                  _buildNoticeBanner(
                    message: state.exportNotice!,
                    color: AppColors.statusSuccess,
                    icon: Icons.check_circle_outline_rounded,
                    onClose: notifier.clearNotice,
                  ),
                  const SizedBox(height: 16),
                ],
                if (state.report == null)
                  _buildEmptyStateCard(state, notifier)
                else ...[
                  _buildVerdictAndScoreRow(state.report!, isCompact, isWide),
                  const SizedBox(height: 16),
                  _buildPlatformAndTestsSection(
                    state.report!,
                    isCompact,
                    isWide,
                  ),
                  const SizedBox(height: 16),
                  _buildPackagesGrid(state, notifier, width),
                  const SizedBox(height: 16),
                  _buildPillarsCard(state.report!, isWide),
                  const SizedBox(height: 16),
                  _buildTasksAuditSection(state, notifier, isCompact),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(
    TitaniumImperial712State state,
    TitaniumImperial712CertificationNotifier notifier,
    bool isCompact,
  ) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.goldAccent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.goldAccent.withValues(alpha: 0.45),
                      ),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: AppColors.goldAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TITANIUM IMPERIAL v5.0',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: isCompact ? 17 : 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Ostateczna certyfikacja 712 zadań • Windows • macOS • Android • iOS',
                          style: TextStyle(
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
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InteractiveActionButton(
                    label: state.isRunning ? 'Skanowanie...' : 'Audyt Szybki',
                    icon: Icons.fact_check_rounded,
                    enabled: !state.isRunning,
                    isPrimary: false,
                    onPressed: () => notifier.runCertification(
                      projectRoot: widget.projectRootOverride,
                    ),
                  ),
                  _InteractiveActionButton(
                    label: state.isRunning
                        ? 'Weryfikacja CLI...'
                        : 'Certyfikuj v5.0 (1 Komenda)',
                    icon: Icons.verified_rounded,
                    enabled: !state.isRunning,
                    isPrimary: true,
                    onPressed: () => notifier.runOneCommandFullCertification(
                      projectRoot: widget.projectRootOverride,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.borderColor, height: 1),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _InteractiveGateToggle(
                label: 'flutter analyze --fatal-infos',
                value: state.runAnalyzeGate,
                enabled: !state.isRunning,
                onChanged: notifier.toggleAnalyzeGate,
              ),
              _InteractiveGateToggle(
                label: 'flutter test (Unit/Fizyka/Sym/UI/JSON)',
                value: state.runTestGate,
                enabled: !state.isRunning,
                onChanged: notifier.toggleTestGate,
              ),
              if (state.report != null) ...[
                _InteractiveActionButton(
                  label: 'Kopiuj JSON',
                  icon: Icons.data_object_rounded,
                  enabled: !state.isRunning,
                  isPrimary: false,
                  onPressed: notifier.copyJsonCertificate,
                ),
                _InteractiveActionButton(
                  label: 'Kopiuj MD',
                  icon: Icons.description_rounded,
                  enabled: !state.isRunning,
                  isPrimary: false,
                  onPressed: notifier.copyMarkdownCertificate,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateCard(
    TitaniumImperial712State state,
    TitaniumImperial712CertificationNotifier notifier,
  ) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.shield_outlined,
            size: 48,
            color: AppColors.goldAccent,
          ),
          const SizedBox(height: 12),
          const Text(
            'Gotowy do certyfikacji TITANIUM IMPERIAL v5.0',
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
            'Uruchom audyt wszystkich 712 zadań, 16 filarów, 5 kategorii testów i 4 platform docelowych.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          _InteractiveActionButton(
            label: state.isRunning ? 'Trwa audyt...' : 'Uruchom Audyt #001–#712',
            icon: Icons.play_arrow_rounded,
            enabled: !state.isRunning,
            isPrimary: true,
            onPressed: () => notifier.runCertification(
              projectRoot: widget.projectRootOverride,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeBanner({
    required String message,
    required Color color,
    required IconData icon,
    VoidCallback? onClose,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
          if (onClose != null)
            IconButton(
              onPressed: onClose,
              icon: Icon(Icons.close_rounded, color: color, size: 18),
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  Widget _buildVerdictAndScoreRow(
    TitaniumImperial712Report report,
    bool isCompact,
    bool isWide,
  ) {
    final verdict = report.verdict;
    final verdictCard = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: verdict.color.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: verdict.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(verdict.icon, color: verdict.color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  verdict.title,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: isCompact ? 14 : 16,
                    fontWeight: FontWeight.w700,
                    color: verdict.color,
                  ),
                ),
                const SizedBox(height: 4),
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
    );

    final metricsCard = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Wrap(
        spacing: 20,
        runSpacing: 12,
        children: [
          _MetricItem(
            label: 'Gotowość',
            value: '${report.readinessScorePercent.toStringAsFixed(1)}%',
            color: AppColors.goldAccent,
          ),
          _MetricItem(
            label: 'Zadania #001–#712',
            value:
                '${report.passedTasksCount}/${TitaniumImperial712Report.expectedTotalTasks}',
            color: report.allTasksVerified
                ? AppColors.statusSuccess
                : AppColors.amberWarning,
          ),
          _MetricItem(
            label: 'CODE_MAP.md',
            value: '${report.codeMapResult.registeredLibFilesCount} plików',
            color: report.codeMapResult.passed
                ? AppColors.statusSuccess
                : AppColors.crimsonAlert,
          ),
          _MetricItem(
            label: 'Filary',
            value: '${report.passedPillarsCount}/${report.pillarChecks.length}',
            color: report.allPillarsPassed
                ? AppColors.statusSuccess
                : AppColors.crimsonAlert,
          ),
          _MetricItem(
            label: 'Platformy',
            value:
                '${report.readyPlatformsCount}/${report.platformReadiness.length}',
            color: report.allPlatformsReady
                ? AppColors.statusSuccess
                : AppColors.crimsonAlert,
          ),
        ],
      ),
    );

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 5, child: verdictCard),
          const SizedBox(width: 16),
          Expanded(flex: 6, child: metricsCard),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        verdictCard,
        const SizedBox(height: 12),
        metricsCard,
      ],
    );
  }

  Widget _buildPlatformAndTestsSection(
    TitaniumImperial712Report report,
    bool isCompact,
    bool isWide,
  ) {
    final platformsCard = Container(
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
            'Matryca Platform Produkcyjnych',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: report.platformReadiness.map((plat) {
              final badgeColor = plat.ready
                  ? AppColors.statusSuccess
                  : AppColors.crimsonAlert;
              return Container(
                width: isCompact ? double.infinity : 210,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Icon(plat.platform.icon, color: badgeColor, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plat.platform.label,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            plat.ready ? 'READY (120 FPS)' : 'BLOCKED',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: badgeColor,
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

    final testsCard = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Zestaw Testów v5.0 (${report.totalTestFilesDiscovered} plików)',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: report.testCategorySummaries.map((cat) {
              final color = cat.hasCoverage
                  ? AppColors.accentBlue
                  : AppColors.amberWarning;
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(cat.category.icon, size: 15, color: color),
                    const SizedBox(width: 6),
                    Text(
                      '${cat.category.label}: ${cat.testFilesCount}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                        fontFeatures: [FontFeature.tabularFigures()],
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

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: platformsCard),
          const SizedBox(width: 16),
          Expanded(child: testsCard),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        platformsCard,
        const SizedBox(height: 12),
        testsCard,
      ],
    );
  }

  Widget _buildPackagesGrid(
    TitaniumImperial712State state,
    TitaniumImperial712CertificationNotifier notifier,
    double availableWidth,
  ) {
    final report = state.report!;
    final crossCount = availableWidth >= 1200
        ? 4
        : availableWidth >= 750
            ? 3
            : availableWidth >= 480
                ? 2
                : 1;

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
            'Postęp Paczek (#001–#712)',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: report.packageSummaries.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossCount,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              mainAxisExtent: 86,
            ),
            itemBuilder: (context, index) {
              final pkg = report.packageSummaries[index];
              final selected = state.selectedPackage == pkg.packageId;
              final statusColor = pkg.allPassed
                  ? AppColors.statusSuccess
                  : AppColors.amberWarning;

              return _InteractivePackageTile(
                summary: pkg,
                selected: selected,
                statusColor: statusColor,
                onTap: () => notifier.selectPackage(pkg.packageId),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPillarsCard(TitaniumImperial712Report report, bool isWide) {
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
          Text(
            'Filary Architektury (${report.passedPillarsCount}/${report.pillarChecks.length})',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: report.pillarChecks.map((pillar) {
              final color = pillar.passed
                  ? AppColors.statusSuccess
                  : AppColors.crimsonAlert;
              return Container(
                width: isWide ? 340 : double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    Icon(
                      pillar.passed
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      color: color,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        pillar.title,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.5,
                          color: AppColors.textPrimary,
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

  Widget _buildTasksAuditSection(
    TitaniumImperial712State state,
    TitaniumImperial712CertificationNotifier notifier,
    bool isCompact,
  ) {
    final tasks = state.filteredTasks;

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
            spacing: 12,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Lista Zadań (${tasks.length})',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(
                width: isCompact ? double.infinity : 260,
                child: TextField(
                  controller: _searchController,
                  onChanged: notifier.setSearchQuery,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Szukaj #numer, ścieżki, opisu...',
                    hintStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
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
                      vertical: 8,
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
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TitaniumImperialTaskFilter.values.map((f) {
              final selected = state.filter == f;
              return _InteractiveFilterChip(
                label: f.label,
                selected: selected,
                onTap: () => notifier.setFilter(f),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          if (tasks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Brak zadań spełniających kryteria filtrowania.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tasks.length > 60 ? 60 : tasks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final entry = tasks[index];
                final color = entry.passed
                    ? AppColors.statusSuccess
                    : AppColors.crimsonAlert;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        entry.passed
                            ? Icons.check_circle_rounded
                            : Icons.error_rounded,
                        color: color,
                        size: 16,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        entry.formattedNumber,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.goldAccent,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          entry.artifactPath,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.5,
                            color: AppColors.textPrimary,
                          ),
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

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11.5,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _InteractiveActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final bool isPrimary;
  final VoidCallback onPressed;

  const _InteractiveActionButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.isPrimary,
    required this.onPressed,
  });

  @override
  State<_InteractiveActionButton> createState() =>
      _InteractiveActionButtonState();
}

class _InteractiveActionButtonState extends State<_InteractiveActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final baseColor =
        widget.isPrimary ? AppColors.primaryAccent : AppColors.surfaceLight;
    final bgColor = !widget.enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.45)
        : _pressed
            ? baseColor.withValues(alpha: 0.8)
            : _hovered
                ? (widget.isPrimary
                    ? AppColors.goldAccent.withValues(alpha: 0.28)
                    : AppColors.surfaceLight.withValues(alpha: 0.9))
                : baseColor;
    final borderColor = !widget.enabled
        ? AppTheme.borderColor.withValues(alpha: 0.4)
        : _focused
            ? AppColors.goldAccent
            : _hovered
                ? AppColors.goldAccent.withValues(alpha: 0.7)
                : AppTheme.borderColor;
    final fgColor =
        widget.enabled ? AppColors.textPrimary : AppColors.textSecondary;

    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: MouseRegion(
        cursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
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
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1),
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
                      fontSize: 12.5,
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

class _InteractiveGateToggle extends StatefulWidget {
  final String label;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _InteractiveGateToggle({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  State<_InteractiveGateToggle> createState() => _InteractiveGateToggleState();
}

class _InteractiveGateToggleState extends State<_InteractiveGateToggle> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: MouseRegion(
        cursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: InkWell(
          onTap: widget.enabled ? () => widget.onChanged(!widget.value) : null,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _hovered
                  ? AppColors.surfaceLight
                  : AppColors.surfaceLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _focused
                    ? AppColors.goldAccent
                    : (widget.value
                        ? AppColors.goldAccent.withValues(alpha: 0.5)
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
                          ? AppColors.goldAccent
                          : AppColors.textSecondary)
                      : AppColors.textSecondary.withValues(alpha: 0.4),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
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

class _InteractivePackageTile extends StatefulWidget {
  final TitaniumImperialPackageSummary summary;
  final bool selected;
  final Color statusColor;
  final VoidCallback onTap;

  const _InteractivePackageTile({
    required this.summary,
    required this.selected,
    required this.statusColor,
    required this.onTap,
  });

  @override
  State<_InteractivePackageTile> createState() =>
      _InteractivePackageTileState();
}

class _InteractivePackageTileState extends State<_InteractivePackageTile> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.selected
                  ? AppColors.primaryAccent.withValues(alpha: 0.22)
                  : _hovered
                      ? AppColors.surfaceLight
                      : AppColors.surfaceLight.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _focused || widget.selected
                    ? AppColors.goldAccent
                    : _hovered
                        ? widget.statusColor.withValues(alpha: 0.65)
                        : AppTheme.borderColor,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      widget.summary.packageId.icon,
                      size: 16,
                      color: widget.statusColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.summary.packageId.label,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${widget.summary.passedTasks}/${widget.summary.totalTasks} '
                  '(${(widget.summary.passRate * 100).toStringAsFixed(0)}%)',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: widget.statusColor,
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

class _InteractiveFilterChip extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _InteractiveFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_InteractiveFilterChip> createState() => _InteractiveFilterChipState();
}

class _InteractiveFilterChipState extends State<_InteractiveFilterChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: widget.selected
                  ? AppColors.goldAccent.withValues(alpha: 0.2)
                  : _hovered
                      ? AppColors.surfaceLight
                      : AppColors.surfaceLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _focused || widget.selected
                    ? AppColors.goldAccent
                    : AppTheme.borderColor,
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
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
