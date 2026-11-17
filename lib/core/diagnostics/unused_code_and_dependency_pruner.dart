// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Kategoria problemu wykrytego przez pruner martwego kodu i dokumentacji.
enum PrunerIssueCategory {
  unusedImport('Nieużywane importy', Icons.link_off_rounded),
  unusedDependency('Nieużywane zależności', Icons.inventory_2_outlined),
  deadCode('Osierocone pliki', Icons.cleaning_services_rounded),
  missingDocstring('Brak dokumentacji klas', Icons.menu_book_rounded),
  placeholderOrTodo('Znaczniki TODO / FIXME', Icons.flag_outlined);

  /// Czytelna nazwa kategorii w interfejsie użytkownika.
  final String label;

  /// Ikona reprezentująca kategorię.
  final IconData icon;

  const PrunerIssueCategory(this.label, this.icon);
}

/// Poziom ważności wykrytego problemu jakościowego.
enum PrunerSeverity {
  critical('Krytyczny', AppColors.crimsonAlert),
  warning('Ostrzeżenie', AppColors.amberWarning),
  info('Informacja', AppColors.accentBlue);

  /// Czytelna etykieta ważności.
  final String label;

  /// Kolor przypisany do poziomu ważności.
  final Color color;

  const PrunerSeverity(this.label, this.color);
}

/// Filtr listy plików w panelu diagnostycznym prunera.
enum PrunerFilter {
  all('Wszystkie'),
  unusedImports('Importy'),
  missingDocs('Dokumentacja'),
  deadFiles('Osierocone'),
  todos('TODO / FIXME'),
  clean('Czyste');

  /// Etykieta wyświetlana na przycisku filtra.
  final String label;

  const PrunerFilter(this.label);
}

/// Wykryty nieużywany lub zduplikowany import w pliku `.dart`.
@immutable
class UnusedImportFinding {
  /// Względna ścieżka do pliku `.dart`.
  final String filePath;

  /// URI importu (np. `package:...` lub ścieżka względna).
  final String importUri;

  /// Numer linii (1-indeksowany) z dyrektywą `import`.
  final int lineNumber;

  /// Surowa treść linii z dyrektywą `import`.
  final String rawStatement;

  /// Opcjonalny alias `as <prefix>`.
  final String? prefixName;

  /// Uzasadnienie uznania importu za nieużywany.
  final String reason;

  /// Tworzy wpis o wykrytym nieużywanym imporcie.
  const UnusedImportFinding({
    required this.filePath,
    required this.importUri,
    required this.lineNumber,
    required this.rawStatement,
    required this.reason,
    this.prefixName,
  });

  /// Serializuje znalezisko do mapy JSON.
  Map<String, dynamic> toJson() => {
        'filePath': filePath,
        'importUri': importUri,
        'lineNumber': lineNumber,
        'rawStatement': rawStatement,
        'prefixName': prefixName,
        'reason': reason,
      };
}

/// Wykryta deklaracja klasy, enuma, mixina lub rozszerzenia bez komentarza `///`.
@immutable
class MissingClassDocFinding {
  /// Względna ścieżka do pliku `.dart`.
  final String filePath;

  /// Nazwa deklaracji (klasy, enuma, mixina lub rozszerzenia).
  final String symbolName;

  /// Rodzaj deklaracji (`class`, `enum`, `mixin`, `extension`).
  final String declarationKind;

  /// Numer linii (1-indeksowany), w której zaczyna się deklaracja.
  final int lineNumber;

  /// Tworzy wpis o brakującej dokumentacji klasy lub typu.
  const MissingClassDocFinding({
    required this.filePath,
    required this.symbolName,
    required this.declarationKind,
    required this.lineNumber,
  });

  /// Serializuje znalezisko do mapy JSON.
  Map<String, dynamic> toJson() => {
        'filePath': filePath,
        'symbolName': symbolName,
        'declarationKind': declarationKind,
        'lineNumber': lineNumber,
      };
}

/// Wykryta zależność z `pubspec.yaml`, która nie jest importowana w kodzie.
@immutable
class UnusedPubspecDependency {
  /// Nazwa pakietu z `pubspec.yaml`.
  final String packageName;

  /// Wersja lub ograniczenie zadeklarowane w `pubspec.yaml`.
  final String versionConstraint;

  /// Czy pakiet pochodzi z sekcji `dev_dependencies`.
  final bool isDevDependency;

  /// Uzasadnienie oznaczenia jako nieużywana zależność.
  final String reason;

  /// Tworzy wpis o nieużywanej zależności w `pubspec.yaml`.
  const UnusedPubspecDependency({
    required this.packageName,
    required this.versionConstraint,
    required this.isDevDependency,
    required this.reason,
  });

  /// Serializuje znalezisko do mapy JSON.
  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'versionConstraint': versionConstraint,
        'isDevDependency': isDevDependency,
        'reason': reason,
      };
}

/// Wykryty znacznik `TODO`, `FIXME` lub `XXX` w komentarzu źródłowym.
@immutable
class TodoPlaceholderFinding {
  /// Względna ścieżka do pliku `.dart`.
  final String filePath;

  /// Numer linii (1-indeksowany).
  final int lineNumber;

  /// Typ znacznika (`TODO`, `FIXME`, `XXX`).
  final String marker;

  /// Skrócony fragment linii z komentarzem.
  final String snippet;

  /// Tworzy wpis o wykrytym znaczniku TODO/FIXME.
  const TodoPlaceholderFinding({
    required this.filePath,
    required this.lineNumber,
    required this.marker,
    required this.snippet,
  });

  /// Serializuje znalezisko do mapy JSON.
  Map<String, dynamic> toJson() => {
        'filePath': filePath,
        'lineNumber': lineNumber,
        'marker': marker,
        'snippet': snippet,
      };
}

/// Wynik audytu czystości i dokumentacji pojedynczego pliku `.dart`.
@immutable
class PrunedFileAudit {
  /// Względna ścieżka do pliku `.dart` w projekcie.
  final String filePath;

  /// Całkowita liczba linii w pliku.
  final int lineCount;

  /// Lista nazw publicznych klas/enumów/mixinów zadeklarowanych w pliku.
  final List<String> declaredPublicTypes;

  /// Liczba publicznych typów posiadających dokumentację `///`.
  final int documentedTypesCount;

  /// Lista wykrytych nieużywanych importów.
  final List<UnusedImportFinding> unusedImports;

  /// Lista typów pozbawionych komentarza dokumentującego `///`.
  final List<MissingClassDocFinding> missingDocs;

  /// Lista wykrytych znaczników `TODO`/`FIXME`/`XXX`.
  final List<TodoPlaceholderFinding> todoFindings;

  /// Czy plik jest importowany przez inne pliki w `lib/` lub `test/`.
  final bool hasIncomingReferences;

  /// Czy plik jest punktem wejścia (np. `main.dart`, `app_router.dart`).
  final bool isEntryPoint;

  /// Tworzy raport audytu pojedynczego pliku `.dart`.
  const PrunedFileAudit({
    required this.filePath,
    required this.lineCount,
    required this.declaredPublicTypes,
    required this.documentedTypesCount,
    required this.unusedImports,
    required this.missingDocs,
    required this.todoFindings,
    required this.hasIncomingReferences,
    required this.isEntryPoint,
  });

  /// Pokrycie dokumentacją typów publicznych w przedziale `0.0`–`1.0`.
  double get documentationCoverage {
    if (declaredPublicTypes.isEmpty) {
      return 1.0;
    }
    return (documentedTypesCount / declaredPublicTypes.length).clamp(0.0, 1.0);
  }

  /// Czy plik nie ma żadnych referencji przychodzących i nie jest punktem wejścia.
  bool get isPotentiallyOrphaned => !isEntryPoint && !hasIncomingReferences;

  /// Czy plik spełnia wszystkie kryteria czystości (zero nieużywanych importów, brak braków doc i TODO).
  bool get isClean =>
      unusedImports.isEmpty &&
      missingDocs.isEmpty &&
      todoFindings.isEmpty &&
      !isPotentiallyOrphaned;

  /// Serializuje wynik pliku do mapy JSON.
  Map<String, dynamic> toJson() => {
        'filePath': filePath,
        'lineCount': lineCount,
        'declaredPublicTypes': declaredPublicTypes,
        'documentedTypesCount': documentedTypesCount,
        'documentationCoverage': documentationCoverage,
        'hasIncomingReferences': hasIncomingReferences,
        'isEntryPoint': isEntryPoint,
        'isPotentiallyOrphaned': isPotentiallyOrphaned,
        'isClean': isClean,
        'unusedImports': unusedImports.map((e) => e.toJson()).toList(),
        'missingDocs': missingDocs.map((e) => e.toJson()).toList(),
        'todoFindings': todoFindings.map((e) => e.toJson()).toList(),
      };
}

/// Wynik operacji usuwania nieużywanych importów (podgląd lub zapis na dysku).
@immutable
class PruneActionResult {
  /// Ścieżki zmodyfikowanych (lub zakwalifikowanych w trybie dry-run) plików.
  final List<String> modifiedFiles;

  /// Łączna liczba usuniętych (lub zakwalifikowanych) dyrektyw `import`.
  final int removedImportsCount;

  /// Czy operacja została wykonana w trybie symulacji bez zapisu na dysk.
  final bool dryRun;

  /// Lista komunikatów błędów, jeśli zapis któregokolwiek pliku nie powiódł się.
  final List<String> errors;

  /// Krótkie podsumowanie wykonanej operacji.
  final String summary;

  /// Tworzy wynik operacji czyszczenia nieużywanych importów.
  const PruneActionResult({
    required this.modifiedFiles,
    required this.removedImportsCount,
    required this.dryRun,
    required this.errors,
    required this.summary,
  });

  /// Serializuje wynik operacji do mapy JSON.
  Map<String, dynamic> toJson() => {
        'modifiedFiles': modifiedFiles,
        'removedImportsCount': removedImportsCount,
        'dryRun': dryRun,
        'errors': errors,
        'summary': summary,
      };
}

/// Zbiorczy raport analizy martwego kodu, zależności i dokumentacji klas.
@immutable
class UnusedCodeAndDependencyReport {
  /// Ścieżka katalogu głównego projektu poddanego analizie.
  final String projectRoot;

  /// Znacznik czasu wygenerowania raportu (UTC).
  final DateTime generatedAt;

  /// Liczba przeskanowanych plików `.dart` w `lib/`.
  final int totalFilesScanned;

  /// Łączna liczba publicznych klas, enumów, mixinów i rozszerzeń.
  final int totalPublicTypesFound;

  /// Liczba typów publicznych z kompletną dokumentacją `///`.
  final int documentedTypesCount;

  /// Łączna liczba wykrytych nieużywanych importów.
  final int unusedImportsCount;

  /// Liczba plików bez referencji przychodzących (poza punktami wejścia).
  final int orphanedFilesCount;

  /// Liczba nieużywanych zależności wykrytych w `pubspec.yaml`.
  final int unusedDependenciesCount;

  /// Łączna liczba znaczników `TODO` / `FIXME` / `XXX`.
  final int todoCount;

  /// Ogólny wskaźnik jakości dokumentacji w przedziale `0.0`–`1.0`.
  final double overallDocCoverage;

  /// Zbiorczy wskaźnik kondycji kodu (`0`–`100`).
  final int healthScore;

  /// Szczegółowe audyty poszczególnych plików `.dart`.
  final List<PrunedFileAudit> fileAudits;

  /// Lista nieużywanych zależności z `pubspec.yaml`.
  final List<UnusedPubspecDependency> unusedDependencies;

  /// Tworzy zbiorczy raport prunera kodu i dokumentacji.
  const UnusedCodeAndDependencyReport({
    required this.projectRoot,
    required this.generatedAt,
    required this.totalFilesScanned,
    required this.totalPublicTypesFound,
    required this.documentedTypesCount,
    required this.unusedImportsCount,
    required this.orphanedFilesCount,
    required this.unusedDependenciesCount,
    required this.todoCount,
    required this.overallDocCoverage,
    required this.healthScore,
    required this.fileAudits,
    required this.unusedDependencies,
  });

  /// Tworzy pusty raport początkowy dla braku danych.
  factory UnusedCodeAndDependencyReport.empty({String projectRoot = '.'}) {
    return UnusedCodeAndDependencyReport(
      projectRoot: projectRoot,
      generatedAt: DateTime.now().toUtc(),
      totalFilesScanned: 0,
      totalPublicTypesFound: 0,
      documentedTypesCount: 0,
      unusedImportsCount: 0,
      orphanedFilesCount: 0,
      unusedDependenciesCount: 0,
      todoCount: 0,
      overallDocCoverage: 1.0,
      healthScore: 100,
      fileAudits: const [],
      unusedDependencies: const [],
    );
  }

  /// Lista plików posortowana wg liczby problemów (malejąco).
  List<PrunedFileAudit> get filesWithIssues =>
      fileAudits.where((f) => !f.isClean).toList(growable: false);

  /// Serializuje pełny raport do formatu JSON.
  Map<String, dynamic> toJson() => {
        'projectRoot': projectRoot,
        'generatedAt': generatedAt.toIso8601String(),
        'totalFilesScanned': totalFilesScanned,
        'totalPublicTypesFound': totalPublicTypesFound,
        'documentedTypesCount': documentedTypesCount,
        'unusedImportsCount': unusedImportsCount,
        'orphanedFilesCount': orphanedFilesCount,
        'unusedDependenciesCount': unusedDependenciesCount,
        'todoCount': todoCount,
        'overallDocCoverage': overallDocCoverage,
        'healthScore': healthScore,
        'unusedDependencies': unusedDependencies.map((e) => e.toJson()).toList(),
        'fileAudits': fileAudits.map((e) => e.toJson()).toList(),
      };

  /// Formatuje raport jako czytelny dokument Markdown do eksportu lub przeglądu.
  String toMarkdownReport() {
    final buffer = StringBuffer()
      ..writeln('# Raport Prunera Kodu i Dokumentacji Klas')
      ..writeln()
      ..writeln('- **Katalog projektu**: `$projectRoot`')
      ..writeln('- **Wygenerowano (UTC)**: `${generatedAt.toIso8601String()}`')
      ..writeln('- **Przeskanowane pliki**: `$totalFilesScanned`')
      ..writeln(
        '- **Dokumentacja klas**: `$documentedTypesCount / $totalPublicTypesFound` '
        '(${(overallDocCoverage * 100).toStringAsFixed(1)}%)',
      )
      ..writeln('- **Nieużywane importy**: `$unusedImportsCount`')
      ..writeln('- **Nieużywane zależności pubspec**: `$unusedDependenciesCount`')
      ..writeln('- **Pliki osierocone**: `$orphanedFilesCount`')
      ..writeln('- **Znaczniki TODO/FIXME**: `$todoCount`')
      ..writeln('- **Wynik kondycji (Health Score)**: `$healthScore / 100`')
      ..writeln();

    if (unusedDependencies.isNotEmpty) {
      buffer.writeln('## Nieużywane zależności (`pubspec.yaml`)');
      for (final dep in unusedDependencies) {
        final scope = dep.isDevDependency ? 'dev' : 'prod';
        buffer.writeln(
          '- `${dep.packageName}` ($scope, `${dep.versionConstraint}`): ${dep.reason}',
        );
      }
      buffer.writeln();
    }

    final issueFiles = filesWithIssues;
    if (issueFiles.isNotEmpty) {
      buffer.writeln('## Pliki wymagające uwagi (${issueFiles.length})');
      for (final file in issueFiles.take(40)) {
        buffer.writeln(
          '- `${file.filePath}` — importy: ${file.unusedImports.length}, '
          'braki doc: ${file.missingDocs.length}, TODO: ${file.todoFindings.length}'
          '${file.isPotentiallyOrphaned ? ', osierocony' : ''}',
        );
      }
    }

    return buffer.toString().trimRight();
  }
}

/// Wewnętrzna reprezentacja sparsowanego importu w pliku `.dart`.
class _ParsedImport {
  final String uri;
  final int lineNumber;
  final String rawStatement;
  final String? prefixName;
  final List<String> showSymbols;

  const _ParsedImport({
    required this.uri,
    required this.lineNumber,
    required this.rawStatement,
    required this.prefixName,
    required this.showSymbols,
  });
}

/// Wewnętrzna reprezentacja zadeklarowanego typu publicznego w pliku `.dart`.
class _DeclaredTypeInfo {
  final String name;
  final String kind;
  final int lineNumber;
  final bool hasDocComment;

  const _DeclaredTypeInfo({
    required this.name,
    required this.kind,
    required this.lineNumber,
    required this.hasDocComment,
  });
}

/// Silnik analizy martwego kodu, nieużywanych importów, zależności `pubspec.yaml`
/// oraz weryfikacji dokumentacji klas `///` w projekcie Flutter/Dart.
class UnusedCodeAndDependencyPruner {
  /// Domyślne ścieżki traktowane jako punkty wejścia (nie wymagają importu przychodzącego).
  static const Set<String> defaultEntryPoints = {
    'lib/main.dart',
    'lib/core/router/app_router.dart',
  };

  /// Pakiety systemowe lub narzędziowe, które nie muszą występować w `import 'package:...'`.
  static const Set<String> ignoredPubspecPackages = {
    'flutter',
    'flutter_test',
    'flutter_localizations',
    'flutter_lints',
    'cupertino_icons',
    'build_runner',
    'isar_generator',
  };

  /// Domyślna ścieżka główna projektu.
  final String defaultProjectRoot;

  /// Dodatkowe ścieżki punktów wejścia.
  final Set<String> entryPointPaths;

  /// Tworzy instancję prunera kodu i dokumentacji.
  const UnusedCodeAndDependencyPruner({
    this.defaultProjectRoot = '.',
    this.entryPointPaths = defaultEntryPoints,
  });

  static final RegExp _importRegex = RegExp(
    r'''^\s*import\s+['"]([^'"]+)['"]([^;]*);''',
  );
  static final RegExp _asPrefixRegex = RegExp(r'\bas\s+([A-Za-z_]\w*)');
  static final RegExp _showClauseRegex = RegExp(r'\bshow\s+([A-Za-z0-9_,\s]+)');
  static final RegExp _typeDeclarationRegex = RegExp(
    r'^\s*(?:(?:abstract|base|final|interface|sealed|mixin)\s+)*(class|enum|mixin|extension)\s+([A-Za-z_]\w*)',
  );
  static final RegExp _todoRegex = RegExp(
    r'//\s*(TODO|FIXME|XXX)\b[:\s-]*(.*)$',
    caseSensitive: false,
  );
  static final RegExp _packageImportRegex = RegExp(
    r'''package:([A-Za-z0-9_]+)/''',
  );

  /// Skanuje wskazany katalog projektu (lub [defaultProjectRoot]) i zwraca raport.
  Future<UnusedCodeAndDependencyReport> scanProject({String? projectRoot}) async {
    final root = _normalizePath(projectRoot ?? defaultProjectRoot);
    final rootDir = Directory(root);
    if (!await rootDir.exists()) {
      return UnusedCodeAndDependencyReport.empty(projectRoot: root);
    }

    final packageName = await _readPackageName(root);
    final libFiles = await _collectDartFiles(Directory('$root/lib'));
    final testFiles = await _collectDartFiles(Directory('$root/test'));

    final fileContents = <String, String>{};
    final relativeLibPaths = <String>[];

    for (final file in libFiles) {
      final rel = _toRelativePath(root, file.path);
      relativeLibPaths.add(rel);
      fileContents[rel] = await file.readAsString();
    }
    relativeLibPaths.sort();

    final testContents = <String, String>{};
    for (final file in testFiles) {
      final rel = _toRelativePath(root, file.path);
      testContents[rel] = await file.readAsString();
    }

    // Zbieramy typy zadeklarowane w każdym pliku, aby dokładnie weryfikować lokalne importy.
    final declaredTypesByFile = <String, List<_DeclaredTypeInfo>>{};
    for (final relPath in relativeLibPaths) {
      declaredTypesByFile[relPath] = _extractDeclaredTypes(
        fileContents[relPath] ?? '',
      );
    }

    // Budujemy graf referencji przychodzących oraz zbiór używanych pakietów z pubspec.
    final incomingRefs = <String, Set<String>>{
      for (final path in relativeLibPaths) path: <String>{},
    };
    final usedPackages = <String>{};

    void indexReferences(String sourcePath, String content) {
      final imports = _parseImports(content);
      for (final imp in imports) {
        final pkgMatch = _packageImportRegex.firstMatch(imp.uri);
        if (pkgMatch != null) {
          final pkg = pkgMatch.group(1)!;
          usedPackages.add(pkg);
          if (packageName != null && pkg == packageName) {
            final targetRel = 'lib/${imp.uri.substring('package:$packageName/'.length)}';
            incomingRefs[targetRel]?.add(sourcePath);
          }
        } else if (!imp.uri.startsWith('dart:')) {
          final resolved = _resolveRelativeImport(sourcePath, imp.uri);
          incomingRefs[resolved]?.add(sourcePath);
        }
      }
    }

    for (final entry in fileContents.entries) {
      indexReferences(entry.key, entry.value);
    }
    for (final entry in testContents.entries) {
      indexReferences(entry.key, entry.value);
    }

    final fileAudits = <PrunedFileAudit>[];
    var totalPublicTypes = 0;
    var documentedTypes = 0;
    var unusedImportsTotal = 0;
    var orphanedTotal = 0;
    var todoTotal = 0;

    for (final relPath in relativeLibPaths) {
      final content = fileContents[relPath] ?? '';
      final lines = const LineSplitter().convert(content);
      final types = declaredTypesByFile[relPath] ?? const [];

      final publicTypes = types.where((t) => !t.name.startsWith('_')).toList();
      final docCount = publicTypes.where((t) => t.hasDocComment).length;
      final missingDocs = publicTypes
          .where((t) => !t.hasDocComment)
          .map(
            (t) => MissingClassDocFinding(
              filePath: relPath,
              symbolName: t.name,
              declarationKind: t.kind,
              lineNumber: t.lineNumber,
            ),
          )
          .toList(growable: false);

      final unusedImports = _detectUnusedImports(
        filePath: relPath,
        content: content,
        packageName: packageName,
        declaredTypesByFile: declaredTypesByFile,
      );

      final todos = _detectTodoFindings(relPath, lines);
      final isEntry = entryPointPaths.contains(relPath) ||
          relPath.endsWith('_test.dart');
      final hasIncoming = (incomingRefs[relPath]?.isNotEmpty ?? false);

      final audit = PrunedFileAudit(
        filePath: relPath,
        lineCount: lines.length,
        declaredPublicTypes: publicTypes.map((t) => t.name).toList(growable: false),
        documentedTypesCount: docCount,
        unusedImports: unusedImports,
        missingDocs: missingDocs,
        todoFindings: todos,
        hasIncomingReferences: hasIncoming,
        isEntryPoint: isEntry,
      );

      fileAudits.add(audit);
      totalPublicTypes += publicTypes.length;
      documentedTypes += docCount;
      unusedImportsTotal += unusedImports.length;
      if (audit.isPotentiallyOrphaned) {
        orphanedTotal++;
      }
      todoTotal += todos.length;
    }

    final unusedDeps = await _findUnusedPubspecDependencies(root, usedPackages);
    final docCoverage =
        totalPublicTypes == 0 ? 1.0 : (documentedTypes / totalPublicTypes).clamp(0.0, 1.0);

    final healthScore = _computeHealthScore(
      totalFiles: relativeLibPaths.length,
      docCoverage: docCoverage,
      unusedImportsCount: unusedImportsTotal,
      unusedDepsCount: unusedDeps.length,
      todoCount: todoTotal,
      orphanedCount: orphanedTotal,
    );

    return UnusedCodeAndDependencyReport(
      projectRoot: root,
      generatedAt: DateTime.now().toUtc(),
      totalFilesScanned: relativeLibPaths.length,
      totalPublicTypesFound: totalPublicTypes,
      documentedTypesCount: documentedTypes,
      unusedImportsCount: unusedImportsTotal,
      orphanedFilesCount: orphanedTotal,
      unusedDependenciesCount: unusedDeps.length,
      todoCount: todoTotal,
      overallDocCoverage: docCoverage,
      healthScore: healthScore,
      fileAudits: fileAudits,
      unusedDependencies: unusedDeps,
    );
  }

  /// Usuwa wykryte nieużywane importy z plików (lub zwraca podgląd przy [dryRun] = true).
  Future<PruneActionResult> pruneUnusedImports({
    required UnusedCodeAndDependencyReport report,
    String? projectRoot,
    bool dryRun = true,
  }) async {
    final root = _normalizePath(projectRoot ?? report.projectRoot);
    final modifiedFiles = <String>[];
    final errors = <String>[];
    var removedCount = 0;

    for (final audit in report.fileAudits) {
      if (audit.unusedImports.isEmpty) {
        continue;
      }

      final linesToRemove = audit.unusedImports.map((e) => e.lineNumber).toSet();
      removedCount += linesToRemove.length;
      modifiedFiles.add(audit.filePath);

      if (dryRun) {
        continue;
      }

      try {
        final file = File('$root/${audit.filePath}');
        if (!await file.exists()) {
          errors.add('Nie znaleziono pliku: ${audit.filePath}');
          continue;
        }
        final raw = await file.readAsString();
        final hadTrailingNewline = raw.endsWith('\n');
        final lines = const LineSplitter().convert(raw);
        final filtered = <String>[];
        for (var i = 0; i < lines.length; i++) {
          final lineNumber = i + 1;
          if (!linesToRemove.contains(lineNumber)) {
            filtered.add(lines[i]);
          }
        }
        final updated = filtered.join('\n') + (hadTrailingNewline ? '\n' : '');
        await file.writeAsString(updated);
      } catch (e) {
        errors.add('Błąd zapisu ${audit.filePath}: $e');
      }
    }

    final summary = dryRun
        ? 'Podgląd czyszczenia: $removedCount importów w ${modifiedFiles.length} plikach.'
        : 'Usunięto $removedCount nieużywanych importów z ${modifiedFiles.length} plików.';

    return PruneActionResult(
      modifiedFiles: modifiedFiles,
      removedImportsCount: removedCount,
      dryRun: dryRun,
      errors: errors,
      summary: summary,
    );
  }

  /// Generuje gotowy szablon dokumentacji `///` dla klasy lub typu pozbawionego opisu.
  String generateDocstringStub(MissingClassDocFinding finding) {
    final kindLabel = switch (finding.declarationKind) {
      'enum' => 'Wyliczenie',
      'mixin' => 'Mixin',
      'extension' => 'Rozszerzenie',
      _ => 'Klasa',
    };
    return '/// $kindLabel `${finding.symbolName}` odpowiedzialna za logikę modułu.';
  }

  Future<String?> _readPackageName(String root) async {
    final pubspec = File('$root/pubspec.yaml');
    if (!await pubspec.exists()) {
      return null;
    }
    final content = await pubspec.readAsString();
    final match = RegExp(r'^name:\s*([A-Za-z0-9_]+)', multiLine: true).firstMatch(content);
    return match?.group(1);
  }

  Future<List<File>> _collectDartFiles(Directory dir) async {
    if (!await dir.exists()) {
      return const [];
    }
    final files = <File>[];
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        files.add(entity);
      }
    }
    return files;
  }

  List<_ParsedImport> _parseImports(String content) {
    final lines = const LineSplitter().convert(content);
    final imports = <_ParsedImport>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final match = _importRegex.firstMatch(line);
      if (match == null) {
        continue;
      }
      final uri = match.group(1) ?? '';
      final tail = match.group(2) ?? '';
      final prefixMatch = _asPrefixRegex.firstMatch(tail);
      final showMatch = _showClauseRegex.firstMatch(tail);

      final showSymbols = <String>[];
      if (showMatch != null) {
        final rawList = showMatch.group(1) ?? '';
        for (final part in rawList.split(',')) {
          final clean = part.trim();
          if (clean.isNotEmpty) {
            showSymbols.add(clean);
          }
        }
      }

      imports.add(
        _ParsedImport(
          uri: uri,
          lineNumber: i + 1,
          rawStatement: line.trim(),
          prefixName: prefixMatch?.group(1),
          showSymbols: showSymbols,
        ),
      );
    }
    return imports;
  }

  List<_DeclaredTypeInfo> _extractDeclaredTypes(String content) {
    final lines = const LineSplitter().convert(content);
    final result = <_DeclaredTypeInfo>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final match = _typeDeclarationRegex.firstMatch(line);
      if (match == null) {
        continue;
      }
      final kind = match.group(1) ?? 'class';
      final name = match.group(2) ?? '';
      if (name.isEmpty) {
        continue;
      }

      final hasDoc = _hasPrecedingDocComment(lines, i);
      result.add(
        _DeclaredTypeInfo(
          name: name,
          kind: kind,
          lineNumber: i + 1,
          hasDocComment: hasDoc,
        ),
      );
    }

    return result;
  }

  bool _hasPrecedingDocComment(List<String> lines, int declarationIndex) {
    var idx = declarationIndex - 1;
    while (idx >= 0) {
      final trimmed = lines[idx].trim();
      if (trimmed.isEmpty) {
        idx--;
        continue;
      }
      // Pomijamy adnotacje (np. @immutable), szukając dokumentacji powyżej nich.
      if (trimmed.startsWith('@')) {
        idx--;
        continue;
      }
      if (trimmed.startsWith('///') || trimmed.endsWith('*/')) {
        return true;
      }
      return false;
    }
    return false;
  }

  List<UnusedImportFinding> _detectUnusedImports({
    required String filePath,
    required String content,
    required String? packageName,
    required Map<String, List<_DeclaredTypeInfo>> declaredTypesByFile,
  }) {
    final imports = _parseImports(content);
    if (imports.isEmpty) {
      return const [];
    }

    final bodyWithoutImports = _stripImportLinesAndComments(content);
    final findings = <UnusedImportFinding>[];
    final seenUris = <String>{};

    for (final imp in imports) {
      final dedupKey = '${imp.uri}|${imp.prefixName ?? ''}';
      if (!seenUris.add(dedupKey)) {
        findings.add(
          UnusedImportFinding(
            filePath: filePath,
            importUri: imp.uri,
            lineNumber: imp.lineNumber,
            rawStatement: imp.rawStatement,
            prefixName: imp.prefixName,
            reason: 'Zduplikowany import tego samego URI.',
          ),
        );
        continue;
      }

      // 1. Import z aliasem `as prefix` — sprawdzamy użycie `prefix.`.
      if (imp.prefixName != null) {
        final prefixPattern = RegExp('\\b${RegExp.escape(imp.prefixName!)}\\.');
        if (!prefixPattern.hasMatch(bodyWithoutImports)) {
          findings.add(
            UnusedImportFinding(
              filePath: filePath,
              importUri: imp.uri,
              lineNumber: imp.lineNumber,
              rawStatement: imp.rawStatement,
              prefixName: imp.prefixName,
              reason: 'Alias `${imp.prefixName}` nie jest używany w treści pliku.',
            ),
          );
        }
        continue;
      }

      // 2. Import z klauzulą `show` — sprawdzamy czy choć jeden wskazany symbol występuje w pliku.
      if (imp.showSymbols.isNotEmpty) {
        final anyUsed = imp.showSymbols.any(
          (sym) => RegExp('\\b${RegExp.escape(sym)}\\b').hasMatch(bodyWithoutImports),
        );
        if (!anyUsed) {
          findings.add(
            UnusedImportFinding(
              filePath: filePath,
              importUri: imp.uri,
              lineNumber: imp.lineNumber,
              rawStatement: imp.rawStatement,
              reason: 'Żaden z symboli `show ${imp.showSymbols.join(', ')}` nie jest używany.',
            ),
          );
        }
        continue;
      }

      // 3. Lokalny import wewnątrz projektu — możemy zweryfikować zadeklarowane w nim typy publiczne.
      String? targetRelPath;
      if (packageName != null && imp.uri.startsWith('package:$packageName/')) {
        targetRelPath = 'lib/${imp.uri.substring('package:$packageName/'.length)}';
      } else if (!imp.uri.startsWith('package:') && !imp.uri.startsWith('dart:')) {
        targetRelPath = _resolveRelativeImport(filePath, imp.uri);
      }

      if (targetRelPath != null && declaredTypesByFile.containsKey(targetRelPath)) {
        final targetTypes = declaredTypesByFile[targetRelPath]!
            .where((t) => !t.name.startsWith('_'))
            .map((t) => t.name)
            .toList();
        if (targetTypes.isNotEmpty) {
          final anyTypeUsed = targetTypes.any(
            (name) => RegExp('\\b${RegExp.escape(name)}\\b').hasMatch(bodyWithoutImports),
          );
          if (!anyTypeUsed) {
            findings.add(
              UnusedImportFinding(
                filePath: filePath,
                importUri: imp.uri,
                lineNumber: imp.lineNumber,
                rawStatement: imp.rawStatement,
                reason: 'Żaden publiczny typ z `$targetRelPath` nie jest używany w pliku.',
              ),
            );
          }
        }
      }
    }

    return findings;
  }

  List<TodoPlaceholderFinding> _detectTodoFindings(
    String filePath,
    List<String> lines,
  ) {
    final findings = <TodoPlaceholderFinding>[];
    for (var i = 0; i < lines.length; i++) {
      final match = _todoRegex.firstMatch(lines[i]);
      if (match != null) {
        final marker = (match.group(1) ?? 'TODO').toUpperCase();
        final snippet = lines[i].trim();
        findings.add(
          TodoPlaceholderFinding(
            filePath: filePath,
            lineNumber: i + 1,
            marker: marker,
            snippet: snippet.length > 100 ? '${snippet.substring(0, 97)}...' : snippet,
          ),
        );
      }
    }
    return findings;
  }

  Future<List<UnusedPubspecDependency>> _findUnusedPubspecDependencies(
    String root,
    Set<String> usedPackages,
  ) async {
    final pubspecFile = File('$root/pubspec.yaml');
    if (!await pubspecFile.exists()) {
      return const [];
    }

    final lines = const LineSplitter().convert(await pubspecFile.readAsString());
    final unused = <UnusedPubspecDependency>[];
    String? currentSection;

    for (final rawLine in lines) {
      final trimmed = rawLine.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) {
        continue;
      }

      if (!rawLine.startsWith(' ') && !rawLine.startsWith('\t')) {
        if (trimmed.startsWith('dependencies:')) {
          currentSection = 'dependencies';
        } else if (trimmed.startsWith('dev_dependencies:')) {
          currentSection = 'dev_dependencies';
        } else {
          currentSection = null;
        }
        continue;
      }

      if (currentSection == null) {
        continue;
      }

      // Interesują nas wyłącznie klucze na poziomie 2 spacji (bezpośrednie zależności).
      final depMatch = RegExp(r'^  ([a-z0-9_]+):\s*(.*)$').firstMatch(rawLine);
      if (depMatch == null) {
        continue;
      }

      final pkgName = depMatch.group(1)!;
      final version = depMatch.group(2)?.trim() ?? '';
      if (ignoredPubspecPackages.contains(pkgName)) {
        continue;
      }

      if (!usedPackages.contains(pkgName)) {
        unused.add(
          UnusedPubspecDependency(
            packageName: pkgName,
            versionConstraint: version.isEmpty ? 'nested/sdk' : version,
            isDevDependency: currentSection == 'dev_dependencies',
            reason: 'Brak dyrektywy `import \'package:$pkgName/...\'` w katalogach `lib/` oraz `test/`.',
          ),
        );
      }
    }

    return unused;
  }

  String _stripImportLinesAndComments(String content) {
    final lines = const LineSplitter().convert(content);
    final buffer = StringBuffer();
    for (final line in lines) {
      if (_importRegex.hasMatch(line)) {
        continue;
      }
      final trimmed = line.trimLeft();
      if (trimmed.startsWith('//')) {
        continue;
      }
      buffer.writeln(line);
    }
    return buffer.toString();
  }

  int _computeHealthScore({
    required int totalFiles,
    required double docCoverage,
    required int unusedImportsCount,
    required int unusedDepsCount,
    required int todoCount,
    required int orphanedCount,
  }) {
    if (totalFiles == 0) {
      return 100;
    }
    var score = 100.0;
    score -= (1.0 - docCoverage) * 35.0;
    score -= (unusedImportsCount * 2.5).clamp(0.0, 25.0);
    score -= (unusedDepsCount * 4.0).clamp(0.0, 16.0);
    score -= (todoCount * 3.0).clamp(0.0, 15.0);
    score -= (orphanedCount * 1.0).clamp(0.0, 9.0);
    return score.round().clamp(0, 100);
  }

  String _normalizePath(String path) => path.replaceAll('\\', '/').replaceAll(RegExp(r'/+$'), '');

  String _toRelativePath(String root, String fullPath) {
    final normFull = _normalizePath(fullPath);
    if (normFull.startsWith('$root/')) {
      return normFull.substring(root.length + 1);
    }
    return normFull;
  }

  String _resolveRelativeImport(String fromFilePath, String importUri) {
    final segments = fromFilePath.split('/')..removeLast();
    for (final part in importUri.split('/')) {
      if (part == '.' || part.isEmpty) {
        continue;
      }
      if (part == '..') {
        if (segments.isNotEmpty) {
          segments.removeLast();
        }
      } else {
        segments.add(part);
      }
    }
    return segments.join('/');
  }
}

/// Stan kontrolera Riverpod obsługującego skanowanie i czyszczenie martwego kodu.
@immutable
class UnusedCodePrunerState {
  /// Czy aktualnie trwa skanowanie projektu.
  final bool isScanning;

  /// Czy aktualnie trwa operacja usuwania importów.
  final bool isPruning;

  /// Ostatni wygenerowany raport analizy.
  final UnusedCodeAndDependencyReport report;

  /// Wynik ostatniej operacji podglądu lub czyszczenia importów.
  final PruneActionResult? lastPruneResult;

  /// Aktywny filtr listy plików.
  final PrunerFilter selectedFilter;

  /// Fraza wyszukiwania w ścieżkach plików i nazwach typów.
  final String searchQuery;

  /// Ścieżka wybranego pliku do podglądu szczegółów.
  final String? selectedFilePath;

  /// Komunikat błędu, jeśli ostatnia operacja zakończyła się niepowodzeniem.
  final String? errorMessage;

  /// Tworzy stan panelu prunera kodu i dokumentacji.
  const UnusedCodePrunerState({
    required this.isScanning,
    required this.isPruning,
    required this.report,
    required this.lastPruneResult,
    required this.selectedFilter,
    required this.searchQuery,
    required this.selectedFilePath,
    required this.errorMessage,
  });

  /// Stan początkowy z pustym raportem.
  factory UnusedCodePrunerState.initial() => UnusedCodePrunerState(
        isScanning: false,
        isPruning: false,
        report: UnusedCodeAndDependencyReport.empty(),
        lastPruneResult: null,
        selectedFilter: PrunerFilter.all,
        searchQuery: '',
        selectedFilePath: null,
        errorMessage: null,
      );

  /// Zwraca przefiltrowaną listę audytów plików zgodnie z [selectedFilter] i [searchQuery].
  List<PrunedFileAudit> get filteredAudits {
    final query = searchQuery.trim().toLowerCase();
    return report.fileAudits.where((audit) {
      final matchesFilter = switch (selectedFilter) {
        PrunerFilter.all => true,
        PrunerFilter.unusedImports => audit.unusedImports.isNotEmpty,
        PrunerFilter.missingDocs => audit.missingDocs.isNotEmpty,
        PrunerFilter.deadFiles => audit.isPotentiallyOrphaned,
        PrunerFilter.todos => audit.todoFindings.isNotEmpty,
        PrunerFilter.clean => audit.isClean,
      };
      if (!matchesFilter) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }
      return audit.filePath.toLowerCase().contains(query) ||
          audit.declaredPublicTypes.any((t) => t.toLowerCase().contains(query));
    }).toList(growable: false);
  }

  /// Zwraca aktualnie wybrany audyt pliku lub pierwszy element przefiltrowanej listy.
  PrunedFileAudit? get selectedAudit {
    final list = filteredAudits;
    if (list.isEmpty) {
      return null;
    }
    if (selectedFilePath != null) {
      for (final item in list) {
        if (item.filePath == selectedFilePath) {
          return item;
        }
      }
    }
    return list.first;
  }

  /// Tworzy kopię stanu ze zmienionymi polami.
  UnusedCodePrunerState copyWith({
    bool? isScanning,
    bool? isPruning,
    UnusedCodeAndDependencyReport? report,
    PruneActionResult? lastPruneResult,
    bool clearPruneResult = false,
    PrunerFilter? selectedFilter,
    String? searchQuery,
    String? selectedFilePath,
    bool clearSelectedFile = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return UnusedCodePrunerState(
      isScanning: isScanning ?? this.isScanning,
      isPruning: isPruning ?? this.isPruning,
      report: report ?? this.report,
      lastPruneResult:
          clearPruneResult ? null : (lastPruneResult ?? this.lastPruneResult),
      selectedFilter: selectedFilter ?? this.selectedFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedFilePath:
          clearSelectedFile ? null : (selectedFilePath ?? this.selectedFilePath),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Kontroler `StateNotifier` zarządzający cyklem skanowania i czyszczenia martwego kodu.
class UnusedCodePrunerNotifier extends StateNotifier<UnusedCodePrunerState> {
  final UnusedCodeAndDependencyPruner _pruner;

  /// Tworzy kontroler z opcjonalną własną instancją [UnusedCodeAndDependencyPruner].
  UnusedCodePrunerNotifier({
    UnusedCodeAndDependencyPruner pruner = const UnusedCodeAndDependencyPruner(),
  })  : _pruner = pruner,
        super(UnusedCodePrunerState.initial());

  /// Uruchamia pełne skanowanie projektu pod kątem martwego kodu i dokumentacji.
  Future<void> scan({String? projectRoot}) async {
    if (state.isScanning) {
      return;
    }
    state = state.copyWith(isScanning: true, clearError: true, clearPruneResult: true);
    try {
      final report = await _pruner.scanProject(projectRoot: projectRoot);
      state = state.copyWith(
        isScanning: false,
        report: report,
        selectedFilePath:
            report.fileAudits.isNotEmpty ? report.fileAudits.first.filePath : null,
      );
    } catch (e) {
      state = state.copyWith(
        isScanning: false,
        errorMessage: 'Błąd podczas skanowania projektu: $e',
      );
    }
  }

  /// Usuwa wykryte nieużywane importy (w trybie podglądu gdy [dryRun] == true).
  Future<void> pruneUnusedImports({bool dryRun = true}) async {
    if (state.isPruning || state.report.totalFilesScanned == 0) {
      return;
    }
    state = state.copyWith(isPruning: true, clearError: true);
    try {
      final result = await _pruner.pruneUnusedImports(
        report: state.report,
        dryRun: dryRun,
      );
      state = state.copyWith(
        isPruning: false,
        lastPruneResult: result,
      );
      if (!dryRun && result.removedImportsCount > 0) {
        await scan(projectRoot: state.report.projectRoot);
      }
    } catch (e) {
      state = state.copyWith(
        isPruning: false,
        errorMessage: 'Błąd podczas czyszczenia importów: $e',
      );
    }
  }

  /// Zmienia aktywny filtr listy plików.
  void setFilter(PrunerFilter filter) {
    state = state.copyWith(selectedFilter: filter);
  }

  /// Aktualizuje frazę wyszukiwania.
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Wybiera plik do inspekcji szczegółowej.
  void selectFile(String? filePath) {
    state = state.copyWith(selectedFilePath: filePath);
  }

  /// Generuje szablon komentarza `///` dla wskazanej klasy bez dokumentacji.
  String buildDocStub(MissingClassDocFinding finding) {
    return _pruner.generateDocstringStub(finding);
  }

  /// Czyści komunikat ostatniego błędu.
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Globalny provider Riverpod dla panelu czyszczenia martwego kodu i weryfikacji dokumentacji.
final unusedCodePrunerProvider =
    StateNotifierProvider<UnusedCodePrunerNotifier, UnusedCodePrunerState>(
  (ref) => UnusedCodePrunerNotifier(),
);

/// Produkcyjny panel diagnostyczny UI do czyszczenia martwego kodu, nieużywanych
/// zależności `pubspec.yaml` oraz weryfikacji dokumentacji klas w całym projekcie.
class UnusedCodeAndDependencyPrunerPanel extends ConsumerStatefulWidget {
  /// Opcjonalna ścieżka katalogu projektu do skanowania.
  final String? projectRoot;

  /// Czy automatycznie uruchomić pierwsze skanowanie po zamontowaniu widgetu.
  final bool autoScanOnInit;

  /// Tworzy responsywny panel prunera kodu i dokumentacji.
  const UnusedCodeAndDependencyPrunerPanel({
    super.key,
    this.projectRoot,
    this.autoScanOnInit = false,
  });

  @override
  ConsumerState<UnusedCodeAndDependencyPrunerPanel> createState() =>
      _UnusedCodeAndDependencyPrunerPanelState();
}

class _UnusedCodeAndDependencyPrunerPanelState
    extends ConsumerState<UnusedCodeAndDependencyPrunerPanel> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.autoScanOnInit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(unusedCodePrunerProvider.notifier).scan(
                projectRoot: widget.projectRoot,
              );
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _copyMarkdownReport(UnusedCodeAndDependencyReport report) async {
    await Clipboard.setData(ClipboardData(text: report.toMarkdownReport()));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Raport Markdown skopiowany do schowka.',
          style: TextStyle(fontFamily: 'Inter', color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.surfaceLight,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(unusedCodePrunerProvider);
    final notifier = ref.read(unusedCodePrunerProvider.notifier);

    return Container(
      color: AppColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isMobile = width < 640;
          final isDesktop = width >= 1150;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 12 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderCard(state, notifier, isMobile),
                const SizedBox(height: 16),
                _buildKpiGrid(state.report, width),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  _buildBanner(
                    message: state.errorMessage!,
                    color: AppColors.crimsonAlert,
                    icon: Icons.error_outline_rounded,
                    onDismiss: notifier.clearError,
                  ),
                ],
                if (state.lastPruneResult != null) ...[
                  const SizedBox(height: 12),
                  _buildBanner(
                    message: state.lastPruneResult!.summary,
                    color: state.lastPruneResult!.errors.isEmpty
                        ? AppColors.statusSuccess
                        : AppColors.amberWarning,
                    icon: Icons.cleaning_services_rounded,
                  ),
                ],
                const SizedBox(height: 16),
                _buildFilterAndSearchBar(state, notifier, isMobile),
                const SizedBox(height: 16),
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: _buildFileAuditList(state, notifier, maxHeight: 520),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 7,
                        child: _buildDetailAndDependenciesColumn(state, notifier),
                      ),
                    ],
                  )
                else ...[
                  _buildFileAuditList(state, notifier, maxHeight: 320),
                  const SizedBox(height: 16),
                  _buildDetailAndDependenciesColumn(state, notifier),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(
    UnusedCodePrunerState state,
    UnusedCodePrunerNotifier notifier,
    bool isMobile,
  ) {
    final actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _PrunerActionButton(
          label: state.isScanning ? 'Skanowanie...' : 'Skanuj projekt',
          icon: Icons.radar_rounded,
          isPrimary: true,
          isDisabled: state.isScanning || state.isPruning,
          onPressed: () => notifier.scan(projectRoot: widget.projectRoot),
        ),
        _PrunerActionButton(
          label: 'Podgląd czyszczenia',
          icon: Icons.preview_rounded,
          isDisabled: state.isScanning ||
              state.isPruning ||
              state.report.unusedImportsCount == 0,
          onPressed: () => notifier.pruneUnusedImports(dryRun: true),
        ),
        _PrunerActionButton(
          label: 'Wyczyść importy',
          icon: Icons.auto_fix_high_rounded,
          accentColor: AppColors.goldAccent,
          isDisabled: state.isScanning ||
              state.isPruning ||
              state.report.unusedImportsCount == 0,
          onPressed: () => notifier.pruneUnusedImports(dryRun: false),
        ),
        _PrunerActionButton(
          label: 'Eksport MD',
          icon: Icons.copy_all_rounded,
          isDisabled: state.report.totalFilesScanned == 0,
          onPressed: () => _copyMarkdownReport(state.report),
        ),
      ],
    );

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryAccent, width: 1.0),
                ),
                child: const Icon(
                  Icons.cleaning_services_rounded,
                  color: AppColors.goldAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pruner Martwego Kodu i Dokumentacji Klas',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Audyt importów, zależności pubspec.yaml, plików osieroconych oraz pokrycia `///`.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppColors.textSecondary.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          actions,
        ],
      ),
    );
  }

  Widget _buildKpiGrid(UnusedCodeAndDependencyReport report, double width) {
    final crossAxisCount = width < 640 ? 2 : 4;
    final cards = [
      _KpiMetricData(
        title: 'Kondycja Kodu',
        value: '${report.healthScore}/100',
        subtitle: '${report.totalFilesScanned} plików .dart',
        accent: report.healthScore >= 85
            ? AppColors.statusSuccess
            : report.healthScore >= 60
                ? AppColors.amberWarning
                : AppColors.crimsonAlert,
        icon: Icons.verified_rounded,
      ),
      _KpiMetricData(
        title: 'Dokumentacja Klas',
        value: '${(report.overallDocCoverage * 100).toStringAsFixed(1)}%',
        subtitle: '${report.documentedTypesCount}/${report.totalPublicTypesFound} typów',
        accent: AppColors.goldAccent,
        icon: Icons.menu_book_rounded,
      ),
      _KpiMetricData(
        title: 'Martwe Importy',
        value: '${report.unusedImportsCount}',
        subtitle: '${report.unusedDependenciesCount} nieuż. paczek pubspec',
        accent: report.unusedImportsCount == 0
            ? AppColors.statusSuccess
            : AppColors.amberWarning,
        icon: Icons.link_off_rounded,
      ),
      _KpiMetricData(
        title: 'Osierocone / TODO',
        value: '${report.orphanedFilesCount} / ${report.todoCount}',
        subtitle: 'Pliki bez ref. / znaczniki',
        accent: report.todoCount == 0
            ? AppColors.accentBlue
            : AppColors.crimsonAlert,
        icon: Icons.flag_outlined,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 106,
      ),
      itemBuilder: (context, index) => _buildKpiCard(cards[index]),
    );
  }

  Widget _buildKpiCard(_KpiMetricData data) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(data.icon, size: 16, color: data.accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          Text(
            data.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: data.accent,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            data.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
              fontFeatures: [FontFeature.tabularFigures()],
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
    VoidCallback? onDismiss,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1.0),
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
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close_rounded, size: 16),
              color: AppColors.textSecondary,
              tooltip: 'Zamknij',
            ),
        ],
      ),
    );
  }

  Widget _buildFilterAndSearchBar(
    UnusedCodePrunerState state,
    UnusedCodePrunerNotifier notifier,
    bool isMobile,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            onChanged: notifier.setSearchQuery,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Filtruj pliki lub nazwy klas...',
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
              suffixIcon: state.searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        notifier.setSearchQuery('');
                      },
                      icon: const Icon(Icons.clear_rounded, size: 16),
                      color: AppColors.textSecondary,
                    )
                  : null,
              filled: true,
              fillColor: AppColors.surfaceLight,
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
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: PrunerFilter.values.map((filter) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _PrunerFilterChip(
                    label: filter.label,
                    selected: state.selectedFilter == filter,
                    onTap: () => notifier.setFilter(filter),
                  ),
                );
              }).toList(growable: false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileAuditList(
    UnusedCodePrunerState state,
    UnusedCodePrunerNotifier notifier, {
    required double maxHeight,
  }) {
    final items = state.filteredAudits;
    final selectedPath = state.selectedAudit?.filePath;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Audytowane pliki',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${items.length} wyników',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderColor),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Brak plików spełniających wybrane kryteria. Uruchom skanowanie projektu.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(10),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final audit = items[index];
                  final isSelected = audit.filePath == selectedPath;
                  return _PrunerFileListTile(
                    audit: audit,
                    selected: isSelected,
                    onTap: () => notifier.selectFile(audit.filePath),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailAndDependenciesColumn(
    UnusedCodePrunerState state,
    UnusedCodePrunerNotifier notifier,
  ) {
    final selected = state.selectedAudit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor, width: 1.0),
          ),
          child: selected == null
              ? const Text(
                  'Wybierz plik z listy, aby zobaczyć szczegóły importów i dokumentacji klas.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                )
              : _buildSelectedAuditDetails(selected, notifier),
        ),
        const SizedBox(height: 16),
        _buildUnusedDependenciesCard(state.report.unusedDependencies),
      ],
    );
  }

  Widget _buildSelectedAuditDetails(
    PrunedFileAudit audit,
    UnusedCodePrunerNotifier notifier,
  ) {
    final docPct = (audit.documentationCoverage * 100).toStringAsFixed(0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                audit.filePath,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: audit.isClean
                    ? AppColors.statusSuccess.withValues(alpha: 0.16)
                    : AppColors.amberWarning.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: audit.isClean
                      ? AppColors.statusSuccess
                      : AppColors.amberWarning,
                ),
              ),
              child: Text(
                audit.isClean ? 'CZYSTY' : 'DO PRZEGLĄDU',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: audit.isClean
                      ? AppColors.statusSuccess
                      : AppColors.amberWarning,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            Text(
              'Linie: ${audit.lineCount}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            Text(
              'Dokumentacja: $docPct% (${audit.documentedTypesCount}/${audit.declaredPublicTypes.length})',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.goldAccent,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            Text(
              audit.isPotentiallyOrphaned
                  ? 'Brak referencji przychodzących'
                  : 'Referencje: aktywne',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: audit.isPotentiallyOrphaned
                    ? AppColors.crimsonAlert
                    : AppColors.statusSuccess,
              ),
            ),
          ],
        ),
        if (audit.unusedImports.isNotEmpty) ...[
          const SizedBox(height: 14),
          const Text(
            'Nieużywane importy',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.amberWarning,
            ),
          ),
          const SizedBox(height: 6),
          ...audit.unusedImports.map(
            (imp) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'L${imp.lineNumber}: ${imp.rawStatement}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    imp.reason,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (audit.missingDocs.isNotEmpty) ...[
          const SizedBox(height: 14),
          const Text(
            'Klasy bez dokumentacji `///`',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.accentBlue,
            ),
          ),
          const SizedBox(height: 6),
          ...audit.missingDocs.map(
            (doc) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'L${doc.lineNumber} • ${doc.declarationKind} ${doc.symbolName}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notifier.buildDocStub(doc),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.goldAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (audit.todoFindings.isNotEmpty) ...[
          const SizedBox(height: 14),
          const Text(
            'Znaczniki TODO / FIXME',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.crimsonAlert,
            ),
          ),
          const SizedBox(height: 6),
          ...audit.todoFindings.map(
            (todo) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'L${todo.lineNumber} [${todo.marker}]: ${todo.snippet}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildUnusedDependenciesCard(List<UnusedPubspecDependency> deps) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Zależności pubspec.yaml bez importów',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${deps.length}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: deps.isEmpty ? AppColors.statusSuccess : AppColors.amberWarning,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (deps.isEmpty)
            const Text(
              'Wszystkie zadeklarowane zależności są aktywnie importowane w kodzie.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            )
          else
            ...deps.map(
              (dep) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 16,
                      color: dep.isDevDependency
                          ? AppColors.accentBlue
                          : AppColors.amberWarning,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${dep.packageName} (${dep.versionConstraint})',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            dep.reason,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _KpiMetricData {
  final String title;
  final String value;
  final String subtitle;
  final Color accent;
  final IconData icon;

  const _KpiMetricData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accent,
    required this.icon,
  });
}

class _PrunerActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool isDisabled;
  final Color? accentColor;

  const _PrunerActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isPrimary = false,
    this.isDisabled = false,
    this.accentColor,
  });

  @override
  State<_PrunerActionButton> createState() => _PrunerActionButtonState();
}

class _PrunerActionButtonState extends State<_PrunerActionButton> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final baseAccent = widget.accentColor ?? AppColors.primaryAccent;
    final bgColor = widget.isDisabled
        ? AppColors.surfaceLight.withValues(alpha: 0.45)
        : widget.isPrimary
            ? (_isPressed
                ? baseAccent.withValues(alpha: 0.8)
                : _isHovered
                    ? baseAccent.withValues(alpha: 0.92)
                    : baseAccent)
            : (_isPressed
                ? AppColors.surfaceLight.withValues(alpha: 0.9)
                : _isHovered
                    ? AppColors.surfaceLight
                    : AppColors.background);

    final borderColor = widget.isDisabled
        ? AppTheme.borderColor.withValues(alpha: 0.4)
        : _isFocused
            ? AppColors.goldAccent
            : _isHovered
                ? baseAccent
                : AppTheme.borderColor;

    final fgColor = widget.isDisabled
        ? AppColors.textSecondary.withValues(alpha: 0.5)
        : widget.isPrimary
            ? AppColors.textPrimary
            : (widget.accentColor ?? AppColors.textPrimary);

    return FocusableActionDetector(
      enabled: !widget.isDisabled,
      onShowFocusHighlight: (focused) => setState(() => _isFocused = focused),
      onShowHoverHighlight: (hovered) => setState(() => _isHovered = hovered),
      child: MouseRegion(
        cursor: widget.isDisabled
            ? SystemMouseCursors.forbidden
            : SystemMouseCursors.click,
        child: GestureDetector(
          onTapDown: widget.isDisabled
              ? null
              : (_) => setState(() => _isPressed = true),
          onTapUp: widget.isDisabled
              ? null
              : (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.isDisabled ? null : widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor,
                width: _isFocused ? 1.5 : 1.0,
              ),
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
      ),
    );
  }
}

class _PrunerFilterChip extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PrunerFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_PrunerFilterChip> createState() => _PrunerFilterChipState();
}

class _PrunerFilterChipState extends State<_PrunerFilterChip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.selected
        ? AppColors.primaryAccent.withValues(alpha: _pressed ? 0.35 : 0.25)
        : _pressed
            ? AppColors.surfaceLight.withValues(alpha: 0.85)
            : _hovered
                ? AppColors.surfaceLight
                : AppColors.background;

    final borderColor = widget.selected
        ? AppColors.goldAccent
        : _focused
            ? AppColors.accentBlue
            : _hovered
                ? AppColors.textSecondary
                : AppTheme.borderColor;

    return FocusableActionDetector(
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
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

class _PrunerFileListTile extends StatefulWidget {
  final PrunedFileAudit audit;
  final bool selected;
  final VoidCallback onTap;

  const _PrunerFileListTile({
    required this.audit,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_PrunerFileListTile> createState() => _PrunerFileListTileState();
}

class _PrunerFileListTileState extends State<_PrunerFileListTile> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.selected
        ? AppColors.primaryAccent.withValues(alpha: 0.18)
        : _pressed
            ? AppColors.surfaceLight.withValues(alpha: 0.9)
            : _hovered
                ? AppColors.surfaceLight
                : AppColors.background;

    final borderColor = widget.selected
        ? AppColors.goldAccent
        : _focused
            ? AppColors.accentBlue
            : AppTheme.borderColor;

    final statusColor = widget.audit.isClean
        ? AppColors.statusSuccess
        : widget.audit.todoFindings.isNotEmpty
            ? AppColors.crimsonAlert
            : AppColors.amberWarning;

    return FocusableActionDetector(
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.audit.filePath,
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
                        'Importy: ${widget.audit.unusedImports.length} • '
                        'Braki doc: ${widget.audit.missingDocs.length} • '
                        'TODO: ${widget.audit.todoFindings.length}',
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
          ),
        ),
      ),
    );
  }
}
