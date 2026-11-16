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

/// Warstwa architektury aplikacji, do której należy plik `.dart`.
enum ArchitectureLayer {
  core('Core & Diagnostyka', '### `lib/` & `lib/core/`', Icons.memory_rounded),
  models('Modele Domenowe', '### `lib/models/`', Icons.schema_rounded),
  engine('Silnik & Fizyka 3D', '### `lib/engine/`', Icons.precision_manufacturing_rounded),
  services('Serwisy & Baza', '### `lib/services/`', Icons.miscellaneous_services_rounded),
  state('Zarządzanie Stanem', '### `lib/state/`', Icons.hub_rounded),
  uiScreens('Ekrany UI', '### `lib/ui/screens/`', Icons.desktop_windows_rounded),
  uiWidgets('Widgety UI', '### `lib/ui/widgets/`', Icons.widgets_rounded),
  other('Pozostałe', '### `lib/` & `lib/core/`', Icons.folder_open_rounded);

  final String label;
  final String codeMapSectionHeader;
  final IconData icon;

  const ArchitectureLayer(this.label, this.codeMapSectionHeader, this.icon);

  static ArchitectureLayer fromPath(String normalizedPath) {
    if (normalizedPath == 'lib/main.dart' || normalizedPath.startsWith('lib/core/')) {
      return ArchitectureLayer.core;
    }
    if (normalizedPath.startsWith('lib/models/')) {
      return ArchitectureLayer.models;
    }
    if (normalizedPath.startsWith('lib/engine/')) {
      return ArchitectureLayer.engine;
    }
    if (normalizedPath.startsWith('lib/services/')) {
      return ArchitectureLayer.services;
    }
    if (normalizedPath.startsWith('lib/state/')) {
      return ArchitectureLayer.state;
    }
    if (normalizedPath.startsWith('lib/ui/screens/')) {
      return ArchitectureLayer.uiScreens;
    }
    if (normalizedPath.startsWith('lib/ui/widgets/')) {
      return ArchitectureLayer.uiWidgets;
    }
    return ArchitectureLayer.other;
  }
}

/// Filtr listy plików w panelu diagnostycznym.
enum CodeMapSyncFilter {
  all('Wszystkie'),
  unregistered('Brak w CODE_MAP'),
  unusedImports('Nieużywane importy'),
  orphaned('Bez referencji'),
  healthy('Zgodne');

  final String label;

  const CodeMapSyncFilter(this.label);
}

/// Wykryty nieużywany import w pliku `.dart`.
@immutable
class UnusedImportIssue {
  final String filePath;
  final String importUri;
  final int lineNumber;
  final String rawStatement;
  final String reason;
  final bool isPrefixed;
  final String? prefixName;

  const UnusedImportIssue({
    required this.filePath,
    required this.importUri,
    required this.lineNumber,
    required this.rawStatement,
    required this.reason,
    this.isPrefixed = false,
    this.prefixName,
  });

  Map<String, dynamic> toJson() => {
        'filePath': filePath,
        'importUri': importUri,
        'lineNumber': lineNumber,
        'rawStatement': rawStatement,
        'reason': reason,
        'isPrefixed': isPrefixed,
        'prefixName': prefixName,
      };
}

/// Wpis w `docs/CODE_MAP.md`, którego plik docelowy nie istnieje już na dysku.
@immutable
class StaleCodeMapEntry {
  final String filePath;
  final int lineNumber;
  final String rawLine;

  const StaleCodeMapEntry({
    required this.filePath,
    required this.lineNumber,
    required this.rawLine,
  });

  Map<String, dynamic> toJson() => {
        'filePath': filePath,
        'lineNumber': lineNumber,
        'rawLine': rawLine,
      };
}

/// Status rejestracji i czystości pojedynczego pliku `.dart` w katalogu `lib/`.
@immutable
class FileRegistrationStatus {
  final String filePath;
  final ArchitectureLayer layer;
  final int lineCount;
  final int sizeBytes;
  final List<String> declaredSymbols;
  final bool registeredInCodeMap;
  final List<String> registeredSymbolsInCodeMap;
  final List<String> missingSymbolsInCodeMap;
  final bool hasIncomingReferences;
  final List<UnusedImportIssue> unusedImports;
  final String suggestedCodeMapLine;

  const FileRegistrationStatus({
    required this.filePath,
    required this.layer,
    required this.lineCount,
    required this.sizeBytes,
    required this.declaredSymbols,
    required this.registeredInCodeMap,
    required this.registeredSymbolsInCodeMap,
    required this.missingSymbolsInCodeMap,
    required this.hasIncomingReferences,
    required this.unusedImports,
    required this.suggestedCodeMapLine,
  });

  bool get isHealthy => registeredInCodeMap && unusedImports.isEmpty;

  bool get isOrphaned => !hasIncomingReferences && filePath != 'lib/main.dart';

  Map<String, dynamic> toJson() => {
        'filePath': filePath,
        'layer': layer.name,
        'lineCount': lineCount,
        'sizeBytes': sizeBytes,
        'declaredSymbols': declaredSymbols,
        'registeredInCodeMap': registeredInCodeMap,
        'registeredSymbolsInCodeMap': registeredSymbolsInCodeMap,
        'missingSymbolsInCodeMap': missingSymbolsInCodeMap,
        'hasIncomingReferences': hasIncomingReferences,
        'unusedImports': unusedImports.map((e) => e.toJson()).toList(),
        'suggestedCodeMapLine': suggestedCodeMapLine,
        'isHealthy': isHealthy,
      };
}

/// Pełny raport synchronizacji architektury i czystości importów w `lib/`.
@immutable
class CodeMapSyncReport {
  final DateTime generatedAt;
  final String projectRootPath;
  final bool codeMapExists;
  final int totalDartFiles;
  final int registeredFilesCount;
  final int unregisteredFilesCount;
  final int staleEntriesCount;
  final int filesWithUnusedImportsCount;
  final int totalUnusedImportsCount;
  final int orphanedFilesCount;
  final Duration scanDuration;
  final List<FileRegistrationStatus> files;
  final List<StaleCodeMapEntry> staleEntries;

  const CodeMapSyncReport({
    required this.generatedAt,
    required this.projectRootPath,
    required this.codeMapExists,
    required this.totalDartFiles,
    required this.registeredFilesCount,
    required this.unregisteredFilesCount,
    required this.staleEntriesCount,
    required this.filesWithUnusedImportsCount,
    required this.totalUnusedImportsCount,
    required this.orphanedFilesCount,
    required this.scanDuration,
    required this.files,
    required this.staleEntries,
  });

  bool get allPassed =>
      codeMapExists &&
      unregisteredFilesCount == 0 &&
      staleEntriesCount == 0 &&
      totalUnusedImportsCount == 0;

  double get complianceScore {
    if (totalDartFiles == 0) return 100.0;
    final int healthyCount = files.where((f) => f.isHealthy).length;
    final double raw = (healthyCount / totalDartFiles) * 100.0;
    final double stalePenalty = staleEntriesCount * 1.5;
    return (raw - stalePenalty).clamp(0.0, 100.0);
  }

  Map<String, int> get countByLayer {
    final Map<ArchitectureLayer, int> map = {};
    for (final FileRegistrationStatus file in files) {
      map[file.layer] = (map[file.layer] ?? 0) + 1;
    }
    return map.map((key, value) => MapEntry(key.name, value));
  }

  Map<String, dynamic> toJson() => {
        'generatedAt': generatedAt.toIso8601String(),
        'projectRootPath': projectRootPath,
        'codeMapExists': codeMapExists,
        'totalDartFiles': totalDartFiles,
        'registeredFilesCount': registeredFilesCount,
        'unregisteredFilesCount': unregisteredFilesCount,
        'staleEntriesCount': staleEntriesCount,
        'filesWithUnusedImportsCount': filesWithUnusedImportsCount,
        'totalUnusedImportsCount': totalUnusedImportsCount,
        'orphanedFilesCount': orphanedFilesCount,
        'complianceScore': double.parse(complianceScore.toStringAsFixed(2)),
        'allPassed': allPassed,
        'scanDurationMs': scanDuration.inMilliseconds,
        'staleEntries': staleEntries.map((e) => e.toJson()).toList(),
        'files': files.map((e) => e.toJson()).toList(),
      };

  String toMarkdownSummary() {
    final StringBuffer buffer = StringBuffer()
      ..writeln('# Raport CodeMapAutoSynchronizer')
      ..writeln('- Pliki `.dart` w `lib/`: **$totalDartFiles**')
      ..writeln('- Zarejestrowane w `docs/CODE_MAP.md`: **$registeredFilesCount**')
      ..writeln('- Brakujące w `docs/CODE_MAP.md`: **$unregisteredFilesCount**')
      ..writeln('- Nieaktualne wpisy (stale): **$staleEntriesCount**')
      ..writeln('- Nieużywane importy: **$totalUnusedImportsCount** (w $filesWithUnusedImportsCount plikach)')
      ..writeln('- Zgodność architektury: **${complianceScore.toStringAsFixed(1)}%**');

    final List<FileRegistrationStatus> missing =
        files.where((f) => !f.registeredInCodeMap).toList();
    if (missing.isNotEmpty) {
      buffer.writeln('\n## Brakujące wpisy w `docs/CODE_MAP.md`');
      for (final FileRegistrationStatus item in missing) {
        buffer.writeln(item.suggestedCodeMapLine);
      }
    }

    final List<FileRegistrationStatus> withUnused =
        files.where((f) => f.unusedImports.isNotEmpty).toList();
    if (withUnused.isNotEmpty) {
      buffer.writeln('\n## Nieużywane importy');
      for (final FileRegistrationStatus item in withUnused) {
        for (final UnusedImportIssue issue in item.unusedImports) {
          buffer.writeln(
            '- `${issue.filePath}:${issue.lineNumber}` -> `${issue.importUri}` (${issue.reason})',
          );
        }
      }
    }
    return buffer.toString().trim();
  }
}

/// Wynik automatycznej synchronizacji pliku `docs/CODE_MAP.md`.
@immutable
class CodeMapSynchronizeResult {
  final bool applied;
  final int addedEntriesCount;
  final int removedStaleCount;
  final List<String> addedFilePaths;
  final List<String> removedFilePaths;
  final String updatedCodeMapContent;

  const CodeMapSynchronizeResult({
    required this.applied,
    required this.addedEntriesCount,
    required this.removedStaleCount,
    required this.addedFilePaths,
    required this.removedFilePaths,
    required this.updatedCodeMapContent,
  });
}

@immutable
class _ParsedImportDirective {
  final String uri;
  final int lineNumber;
  final String rawStatement;
  final String? prefix;
  final List<String> showIdentifiers;
  final List<String> hideIdentifiers;
  final bool isDeferred;

  const _ParsedImportDirective({
    required this.uri,
    required this.lineNumber,
    required this.rawStatement,
    required this.prefix,
    required this.showIdentifiers,
    required this.hideIdentifiers,
    required this.isDeferred,
  });
}

@immutable
class _ParsedCodeMapEntry {
  final String filePath;
  final int lineNumber;
  final String rawLine;

  const _ParsedCodeMapEntry({
    required this.filePath,
    required this.lineNumber,
    required this.rawLine,
  });
}

/// Narzędzie diagnostyczne weryfikujące rejestrację wszystkich plików `.dart` z `lib/`
/// w architekturze aplikacji (`docs/CODE_MAP.md`) oraz wykrywające nieużywane importy.
class CodeMapAutoSynchronizer {
  final String projectRootPath;
  final String packageName;

  CodeMapAutoSynchronizer({
    String? projectRootPath,
    this.packageName = 'pro_peloton_manager',
  }) : projectRootPath = projectRootPath ?? Directory.current.path;

  static const Map<String, Set<String>> _dartStdLibSymbols = {
    'dart:async': {
      'Future',
      'FutureOr',
      'Stream',
      'StreamController',
      'StreamSubscription',
      'StreamTransformer',
      'Completer',
      'Timer',
      'Zone',
      'scheduleMicrotask',
      'unawaited',
      'runZonedGuarded',
    },
    'dart:convert': {
      'json',
      'jsonEncode',
      'jsonDecode',
      'utf8',
      'latin1',
      'ascii',
      'base64',
      'base64Encode',
      'base64Decode',
      'base64Url',
      'JsonEncoder',
      'JsonDecoder',
      'LineSplitter',
      'Codec',
      'Converter',
    },
    'dart:io': {
      'File',
      'Directory',
      'FileSystemEntity',
      'FileMode',
      'Process',
      'ProcessResult',
      'Platform',
      'Socket',
      'ServerSocket',
      'HttpClient',
      'HttpServer',
      'HttpStatus',
      'stdout',
      'stderr',
      'stdin',
      'exit',
      'exitCode',
      'pid',
      'BytesBuilder',
      'IOSink',
      'OSError',
      'FileSystemException',
    },
    'dart:math': {
      'Random',
      'Point',
      'Rectangle',
      'min',
      'max',
      'sqrt',
      'pow',
      'sin',
      'cos',
      'tan',
      'asin',
      'acos',
      'atan',
      'atan2',
      'exp',
      'log',
      'pi',
      'e',
      'ln2',
      'ln10',
    },
    'dart:typed_data': {
      'Uint8List',
      'Int8List',
      'Uint16List',
      'Int16List',
      'Uint32List',
      'Int32List',
      'Uint64List',
      'Int64List',
      'Float32List',
      'Float64List',
      'ByteData',
      'ByteBuffer',
      'Endian',
      'TypedData',
    },
    'dart:collection': {
      'Queue',
      'ListQueue',
      'HashMap',
      'HashSet',
      'LinkedHashMap',
      'LinkedHashSet',
      'SplayTreeMap',
      'SplayTreeSet',
      'UnmodifiableListView',
      'UnmodifiableMapView',
      'MapBase',
      'ListBase',
    },
    'dart:isolate': {
      'Isolate',
      'SendPort',
      'ReceivePort',
      'Capability',
      'TransferableTypedData',
    },
    'dart:ui': {
      'Color',
      'Offset',
      'Size',
      'Rect',
      'RRect',
      'Path',
      'Canvas',
      'Paint',
      'PaintingStyle',
      'StrokeCap',
      'StrokeJoin',
      'ImageFilter',
      'MaskFilter',
      'BlurStyle',
      'FontFeature',
      'TextDirection',
      'TextAlign',
      'BlendMode',
      'Gradient',
      'Shader',
      'Vertices',
      'PictureRecorder',
      'Image',
      'lerpDouble',
    },
  };

  /// Uruchamia pełny audyt wszystkich plików `.dart` w `lib/`.
  Future<CodeMapSyncReport> runAudit({
    bool includeUnusedImportCheck = true,
    bool includeCrossReferenceCheck = true,
  }) async {
    final Stopwatch stopwatch = Stopwatch()..start();

    final Directory libDir = Directory(_joinPath(projectRootPath, 'lib'));
    final File codeMapFile = File(_joinPath(projectRootPath, 'docs/CODE_MAP.md'));
    final bool codeMapExists = await codeMapFile.exists();
    final String codeMapContent = codeMapExists ? await codeMapFile.readAsString() : '';
    final Map<String, _ParsedCodeMapEntry> parsedCodeMapEntries =
        _parseCodeMapEntries(codeMapContent);

    final List<File> libDartFiles = [];
    if (await libDir.exists()) {
      await for (final FileSystemEntity entity in libDir.list(recursive: true, followLinks: false)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          final String normalized = _normalizeRelativePath(entity.path);
          if (!_isGeneratedDartFile(normalized)) {
            libDartFiles.add(entity);
          }
        }
      }
    }

    libDartFiles.sort(
      (a, b) => _normalizeRelativePath(a.path).compareTo(_normalizeRelativePath(b.path)),
    );

    final Map<String, String> sourceByPath = {};
    final Map<String, List<String>> declaredSymbolsByPath = {};
    final Map<String, int> sizeByPath = {};

    for (final File file in libDartFiles) {
      final String normalized = _normalizeRelativePath(file.path);
      final String source = await file.readAsString();
      sourceByPath[normalized] = source;
      sizeByPath[normalized] = await file.length();
      declaredSymbolsByPath[normalized] = extractPublicSymbols(source);
    }

    final Set<String> referencedProjectFiles = <String>{};
    if (includeCrossReferenceCheck) {
      final List<String> allDartSourcesForRefs = [...sourceByPath.keys];
      for (final String callerPath in allDartSourcesForRefs) {
        final String source = sourceByPath[callerPath] ?? '';
        for (final String uri in _extractImportAndExportUris(source)) {
          final String? resolved = _resolveProjectUri(callerPath, uri);
          if (resolved != null) {
            referencedProjectFiles.add(resolved);
          }
        }
      }

      final Directory testDir = Directory(_joinPath(projectRootPath, 'test'));
      if (await testDir.exists()) {
        await for (final FileSystemEntity entity in testDir.list(recursive: true, followLinks: false)) {
          if (entity is File && entity.path.endsWith('.dart')) {
            final String testPath = _normalizeRelativePath(entity.path);
            final String testSource = await entity.readAsString();
            for (final String uri in _extractImportAndExportUris(testSource)) {
              final String? resolved = _resolveProjectUri(testPath, uri);
              if (resolved != null) {
                referencedProjectFiles.add(resolved);
              }
            }
          }
        }
      }
    }

    final List<FileRegistrationStatus> statuses = [];
    for (final File file in libDartFiles) {
      final String normalized = _normalizeRelativePath(file.path);
      final String source = sourceByPath[normalized] ?? '';
      final List<String> declaredSymbols = declaredSymbolsByPath[normalized] ?? const [];
      final _ParsedCodeMapEntry? codeMapEntry = parsedCodeMapEntries[normalized];
      final bool isRegistered = codeMapEntry != null;

      final List<String> registeredSymbols = [];
      final List<String> missingSymbols = [];
      if (isRegistered) {
        for (final String symbol in declaredSymbols) {
          if (codeMapEntry.rawLine.contains(symbol)) {
            registeredSymbols.add(symbol);
          } else {
            missingSymbols.add(symbol);
          }
        }
      } else {
        missingSymbols.addAll(declaredSymbols);
      }

      final List<UnusedImportIssue> unusedImports = includeUnusedImportCheck
          ? analyzeUnusedImports(
              source,
              filePath: normalized,
              projectSymbolsByPath: declaredSymbolsByPath,
            )
          : const [];

      final ArchitectureLayer layer = ArchitectureLayer.fromPath(normalized);
      final String suggestedLine = buildSuggestedCodeMapLine(
        filePath: normalized,
        declaredSymbols: declaredSymbols,
        source: source,
      );

      statuses.add(
        FileRegistrationStatus(
          filePath: normalized,
          layer: layer,
          lineCount: '\n'.allMatches(source).length + (source.isEmpty ? 0 : 1),
          sizeBytes: sizeByPath[normalized] ?? 0,
          declaredSymbols: declaredSymbols,
          registeredInCodeMap: isRegistered,
          registeredSymbolsInCodeMap: registeredSymbols,
          missingSymbolsInCodeMap: missingSymbols,
          hasIncomingReferences:
              !includeCrossReferenceCheck || referencedProjectFiles.contains(normalized),
          unusedImports: unusedImports,
          suggestedCodeMapLine: suggestedLine,
        ),
      );
    }

    final Set<String> diskPaths = sourceByPath.keys.toSet();
    final List<StaleCodeMapEntry> staleEntries = [];
    for (final _ParsedCodeMapEntry entry in parsedCodeMapEntries.values) {
      if (!diskPaths.contains(entry.filePath)) {
        staleEntries.add(
          StaleCodeMapEntry(
            filePath: entry.filePath,
            lineNumber: entry.lineNumber,
            rawLine: entry.rawLine,
          ),
        );
      }
    }

    final int registeredCount = statuses.where((s) => s.registeredInCodeMap).length;
    final int unregisteredCount = statuses.length - registeredCount;
    final int filesWithUnused = statuses.where((s) => s.unusedImports.isNotEmpty).length;
    final int totalUnused = statuses.fold<int>(0, (acc, s) => acc + s.unusedImports.length);
    final int orphanedCount = statuses.where((s) => s.isOrphaned).length;

    stopwatch.stop();

    return CodeMapSyncReport(
      generatedAt: DateTime.now(),
      projectRootPath: projectRootPath,
      codeMapExists: codeMapExists,
      totalDartFiles: statuses.length,
      registeredFilesCount: registeredCount,
      unregisteredFilesCount: unregisteredCount,
      staleEntriesCount: staleEntries.length,
      filesWithUnusedImportsCount: filesWithUnused,
      totalUnusedImportsCount: totalUnused,
      orphanedFilesCount: orphanedCount,
      scanDuration: stopwatch.elapsed,
      files: statuses,
      staleEntries: staleEntries,
    );
  }

  /// Synchronizuje plik `docs/CODE_MAP.md` o brakujące wpisy (i opcjonalnie usuwa nieaktualne).
  /// Domyślnie `dryRun = true` zwraca podgląd bez modyfikacji dysku.
  Future<CodeMapSynchronizeResult> synchronizeCodeMap({
    bool dryRun = true,
    bool removeStale = false,
  }) async {
    final CodeMapSyncReport report = await runAudit(
      includeUnusedImportCheck: false,
      includeCrossReferenceCheck: false,
    );
    final File codeMapFile = File(_joinPath(projectRootPath, 'docs/CODE_MAP.md'));
    final String originalContent =
        await codeMapFile.exists() ? await codeMapFile.readAsString() : '';

    final List<String> lines = const LineSplitter().convert(originalContent);
    final Set<String> stalePaths =
        removeStale ? report.staleEntries.map((e) => e.filePath).toSet() : <String>{};
    final List<String> removedPaths = [];

    final List<String> workingLines = [];
    for (final String line in lines) {
      final String? pathInLine = _extractCodeMapPathFromLine(line);
      if (pathInLine != null && stalePaths.contains(pathInLine)) {
        removedPaths.add(pathInLine);
        continue;
      }
      workingLines.add(line);
    }

    final List<FileRegistrationStatus> missingFiles =
        report.files.where((f) => !f.registeredInCodeMap).toList();
    final List<String> addedPaths = [];

    for (final FileRegistrationStatus missing in missingFiles) {
      final String header = missing.layer.codeMapSectionHeader;
      final int headerIdx = workingLines.indexWhere((l) => l.trim() == header);
      if (headerIdx != -1) {
        int insertIdx = headerIdx + 1;
        while (insertIdx < workingLines.length) {
          final String current = workingLines[insertIdx].trim();
          if (current.startsWith('### ') || current.startsWith('## ')) {
            break;
          }
          if (current.isEmpty) {
            break;
          }
          insertIdx++;
        }
        workingLines.insert(insertIdx, missing.suggestedCodeMapLine);
      } else {
        workingLines.add(missing.suggestedCodeMapLine);
      }
      addedPaths.add(missing.filePath);
    }

    final String updatedContent = '${workingLines.join('\n')}\n';
    if (!dryRun && (addedPaths.isNotEmpty || removedPaths.isNotEmpty)) {
      await codeMapFile.writeAsString(updatedContent);
    }

    return CodeMapSynchronizeResult(
      applied: !dryRun,
      addedEntriesCount: addedPaths.length,
      removedStaleCount: removedPaths.length,
      addedFilePaths: addedPaths,
      removedFilePaths: removedPaths,
      updatedCodeMapContent: updatedContent,
    );
  }

  /// Analizuje pojedynczy plik źródłowy Dart pod kątem nieużywanych importów.
  List<UnusedImportIssue> analyzeUnusedImports(
    String source, {
    String filePath = 'unknown.dart',
    Map<String, List<String>>? projectSymbolsByPath,
  }) {
    final List<_ParsedImportDirective> imports = _parseImportDirectives(source);
    if (imports.isEmpty) return const [];

    final String codeWithoutDirectives = _stripImportsAndStringsAndComments(source);
    final Set<String> usedIdentifiers = _extractIdentifiers(codeWithoutDirectives);
    final Set<String> exportedUris = _extractExportUris(source);

    final List<UnusedImportIssue> issues = [];

    for (final _ParsedImportDirective directive in imports) {
      if (exportedUris.contains(directive.uri)) {
        continue;
      }

      // 1. Import z prefiksem (`as prefix`)
      if (directive.prefix != null && directive.prefix!.isNotEmpty) {
        final String prefix = directive.prefix!;
        if (!usedIdentifiers.contains(prefix)) {
          issues.add(
            UnusedImportIssue(
              filePath: filePath,
              importUri: directive.uri,
              lineNumber: directive.lineNumber,
              rawStatement: directive.rawStatement,
              reason: 'Prefiks `$prefix` nie jest nigdzie użyty w kodzie.',
              isPrefixed: true,
              prefixName: prefix,
            ),
          );
        }
        continue;
      }

      // 2. Import z klauzulą `show`
      if (directive.showIdentifiers.isNotEmpty) {
        final bool anyShownUsed =
            directive.showIdentifiers.any((id) => usedIdentifiers.contains(id));
        if (!anyShownUsed) {
          issues.add(
            UnusedImportIssue(
              filePath: filePath,
              importUri: directive.uri,
              lineNumber: directive.lineNumber,
              rawStatement: directive.rawStatement,
              reason:
                  'Żaden z symboli `show ${directive.showIdentifiers.join(', ')}` nie jest użyty.',
            ),
          );
        }
        continue;
      }

      // 3. Zbędny jawny import `dart:core`
      if (directive.uri == 'dart:core') {
        issues.add(
          UnusedImportIssue(
            filePath: filePath,
            importUri: directive.uri,
            lineNumber: directive.lineNumber,
            rawStatement: directive.rawStatement,
            reason: 'Pakiet `dart:core` jest importowany automatycznie przez język Dart.',
          ),
        );
        continue;
      }

      // 4. Import standardowej biblioteki `dart:*` ze znanym zestawem symboli
      final Set<String>? knownStdSymbols = _dartStdLibSymbols[directive.uri];
      if (knownStdSymbols != null) {
        final bool anyUsed = knownStdSymbols.any(usedIdentifiers.contains);
        if (!anyUsed) {
          issues.add(
            UnusedImportIssue(
              filePath: filePath,
              importUri: directive.uri,
              lineNumber: directive.lineNumber,
              rawStatement: directive.rawStatement,
              reason: 'Brak użycia symboli z `${directive.uri}` w ciele pliku.',
            ),
          );
        }
        continue;
      }

      // 5. Lokalny import w obrębie projektu (`../` lub `package:<packageName>/...`)
      if (projectSymbolsByPath != null) {
        final String? resolvedTarget = _resolveProjectUri(filePath, directive.uri);
        if (resolvedTarget != null) {
          final List<String>? targetSymbols = projectSymbolsByPath[resolvedTarget];
          if (targetSymbols != null && targetSymbols.isNotEmpty) {
            final bool anySymbolUsed = targetSymbols.any(usedIdentifiers.contains);
            if (!anySymbolUsed) {
              issues.add(
                UnusedImportIssue(
                  filePath: filePath,
                  importUri: directive.uri,
                  lineNumber: directive.lineNumber,
                  rawStatement: directive.rawStatement,
                  reason:
                      'Żaden z publicznych symboli pliku `$resolvedTarget` nie jest użyty.',
                ),
              );
            }
          }
        }
      }
    }

    return issues;
  }

  /// Wyciąga listę publicznych deklaracji najwyższego poziomu (klasy, enumy, mixiny, providery).
  List<String> extractPublicSymbols(String source) {
    final String cleaned = _stripStringsAndComments(source);
    final Set<String> symbols = <String>{};

    final RegExp typeDeclRegex = RegExp(
      r'^\s*(?:abstract\s+|base\s+|final\s+|interface\s+|sealed\s+|mixin\s+)*'
      r'(?:class|enum|mixin|typedef)\s+([A-Z][A-Za-z0-9_]*)',
      multiLine: true,
    );
    for (final RegExpMatch match in typeDeclRegex.allMatches(cleaned)) {
      final String? name = match.group(1);
      if (name != null && !name.startsWith('_')) {
        symbols.add(name);
      }
    }

    final RegExp extensionRegex = RegExp(
      r'^\s*extension\s+([A-Z][A-Za-z0-9_]*)\s+on\b',
      multiLine: true,
    );
    for (final RegExpMatch match in extensionRegex.allMatches(cleaned)) {
      final String? name = match.group(1);
      if (name != null && !name.startsWith('_')) {
        symbols.add(name);
      }
    }

    final RegExp providerRegex = RegExp(
      r'^\s*(?:final|const)\s+([a-z][A-Za-z0-9_]*Provider)\s*=',
      multiLine: true,
    );
    for (final RegExpMatch match in providerRegex.allMatches(cleaned)) {
      final String? name = match.group(1);
      if (name != null && !name.startsWith('_')) {
        symbols.add(name);
      }
    }

    return symbols.toList();
  }

  /// Generuje jednoliniowy wpis gotowy do dopisania w `docs/CODE_MAP.md`.
  String buildSuggestedCodeMapLine({
    required String filePath,
    required List<String> declaredSymbols,
    required String source,
  }) {
    final String summary = _extractDocCommentSummary(source) ?? _inferSummaryFromPath(filePath);
    final String symbolsTag = declaredSymbols.isEmpty
        ? ''
        : ' (`${declaredSymbols.take(6).join('`, `')}`)';
    return '- `$filePath` — $summary$symbolsTag.';
  }

  Map<String, _ParsedCodeMapEntry> _parseCodeMapEntries(String content) {
    final Map<String, _ParsedCodeMapEntry> entries = {};
    if (content.isEmpty) return entries;

    final List<String> lines = const LineSplitter().convert(content);
    for (int i = 0; i < lines.length; i++) {
      final String line = lines[i];
      final String? path = _extractCodeMapPathFromLine(line);
      if (path != null) {
        entries[path] = _ParsedCodeMapEntry(
          filePath: path,
          lineNumber: i + 1,
          rawLine: line,
        );
      }
    }
    return entries;
  }

  String? _extractCodeMapPathFromLine(String line) {
    final RegExp matchExpr = RegExp(r'`(lib/[A-Za-z0-9_/\-\.]+\.dart)`');
    final RegExpMatch? match = matchExpr.firstMatch(line);
    return match?.group(1);
  }

  List<_ParsedImportDirective> _parseImportDirectives(String source) {
    final List<_ParsedImportDirective> result = [];
    final String withoutBlockComments = source.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');
    final List<String> lines = const LineSplitter().convert(withoutBlockComments);

    final StringBuffer currentStmt = StringBuffer();
    int startLine = 0;
    bool collecting = false;

    for (int i = 0; i < lines.length; i++) {
      final String trimmed = lines[i].trim();
      if (!collecting) {
        if (trimmed.startsWith('//')) continue;
        if (trimmed.startsWith('import ')) {
          collecting = true;
          startLine = i + 1;
          currentStmt.clear();
          currentStmt.write(trimmed);
          if (trimmed.contains(';')) {
            final _ParsedImportDirective? parsed =
                _parseSingleImportStatement(currentStmt.toString(), startLine);
            if (parsed != null) result.add(parsed);
            collecting = false;
          }
        }
      } else {
        currentStmt.write(' ');
        currentStmt.write(trimmed);
        if (trimmed.contains(';')) {
          final _ParsedImportDirective? parsed =
              _parseSingleImportStatement(currentStmt.toString(), startLine);
          if (parsed != null) result.add(parsed);
          collecting = false;
        }
      }
    }

    return result;
  }

  _ParsedImportDirective? _parseSingleImportStatement(String stmt, int lineNumber) {
    final RegExp uriRegex = RegExp(r'''import\s+['"]([^'"]+)['"]([^;]*);''');
    final RegExpMatch? match = uriRegex.firstMatch(stmt);
    if (match == null) return null;

    final String uri = match.group(1) ?? '';
    final String tail = match.group(2) ?? '';
    final bool isDeferred = RegExp(r'\bdeferred\b').hasMatch(tail);
    final RegExpMatch? asMatch = RegExp(r'\bas\s+([A-Za-z_][A-Za-z0-9_]*)').firstMatch(tail);
    final String? prefix = asMatch?.group(1);

    final List<String> showIds = [];
    final RegExpMatch? showMatch =
        RegExp(r'\bshow\s+([A-Za-z0-9_,\s]+?)(?=\bhide\b|$)').firstMatch(tail);
    if (showMatch != null) {
      final String rawList = showMatch.group(1) ?? '';
      for (final String part in rawList.split(',')) {
        final String clean = part.trim();
        if (clean.isNotEmpty) showIds.add(clean);
      }
    }

    final List<String> hideIds = [];
    final RegExpMatch? hideMatch =
        RegExp(r'\bhide\s+([A-Za-z0-9_,\s]+?)(?=\bshow\b|$)').firstMatch(tail);
    if (hideMatch != null) {
      final String rawList = hideMatch.group(1) ?? '';
      for (final String part in rawList.split(',')) {
        final String clean = part.trim();
        if (clean.isNotEmpty) hideIds.add(clean);
      }
    }

    return _ParsedImportDirective(
      uri: uri,
      lineNumber: lineNumber,
      rawStatement: stmt,
      prefix: prefix,
      showIdentifiers: showIds,
      hideIdentifiers: hideIds,
      isDeferred: isDeferred,
    );
  }

  List<String> _extractImportAndExportUris(String source) {
    final List<String> uris = [];
    final RegExp regex = RegExp(r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''', multiLine: true);
    for (final RegExpMatch m in regex.allMatches(source)) {
      final String? uri = m.group(1);
      if (uri != null) uris.add(uri);
    }
    return uris;
  }

  Set<String> _extractExportUris(String source) {
    final Set<String> uris = {};
    final RegExp regex = RegExp(r'''^\s*export\s+['"]([^'"]+)['"]''', multiLine: true);
    for (final RegExpMatch m in regex.allMatches(source)) {
      final String? uri = m.group(1);
      if (uri != null) uris.add(uri);
    }
    return uris;
  }

  String? _resolveProjectUri(String callerPath, String uri) {
    if (uri.startsWith('dart:')) return null;
    if (uri.startsWith('package:')) {
      final String pkgPrefix = 'package:$packageName/';
      if (uri.startsWith(pkgPrefix)) {
        return 'lib/${uri.substring(pkgPrefix.length)}';
      }
      return null;
    }

    final List<String> callerParts = callerPath.split('/')..removeLast();
    final List<String> uriParts = uri.split('/');
    for (final String segment in uriParts) {
      if (segment.isEmpty || segment == '.') continue;
      if (segment == '..') {
        if (callerParts.isNotEmpty) callerParts.removeLast();
      } else {
        callerParts.add(segment);
      }
    }
    final String resolved = callerParts.join('/');
    return resolved.startsWith('lib/') ? resolved : null;
  }

  String _stripImportsAndStringsAndComments(String source) {
    final String withoutImports = source.replaceAll(
      RegExp(r'''^\s*(?:import|part\s+of|part|library)\b[^;]*;''', multiLine: true),
      '',
    );
    return _stripStringsAndComments(withoutImports);
  }

  String _stripStringsAndComments(String source) {
    String cleaned = source.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'//[^\n]*'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r"r?'''[\s\S]*?'''"), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'r?"""[\s\S]*?"""'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r"r?'(?:\\.|[^'\\])*'"), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'r?"(?:\\.|[^"\\])*"'), ' ');
    return cleaned;
  }

  Set<String> _extractIdentifiers(String code) {
    final Set<String> identifiers = <String>{};
    final RegExp regex = RegExp(r'\b([A-Za-z_][A-Za-z0-9_]*)\b');
    for (final RegExpMatch match in regex.allMatches(code)) {
      final String? token = match.group(1);
      if (token != null) {
        identifiers.add(token);
      }
    }
    return identifiers;
  }

  String? _extractDocCommentSummary(String source) {
    final RegExp docRegex = RegExp(r'^///\s+([^\n]+)', multiLine: true);
    final RegExpMatch? match = docRegex.firstMatch(source);
    if (match == null) return null;
    final String text = (match.group(1) ?? '').trim();
    if (text.isEmpty || text.startsWith('Copyright')) return null;
    return text.endsWith('.') ? text.substring(0, text.length - 1) : text;
  }

  String _inferSummaryFromPath(String filePath) {
    final String fileName = filePath.split('/').last.replaceAll('.dart', '');
    final String readable = fileName
        .split('_')
        .where((e) => e.isNotEmpty)
        .map((e) => '${e[0].toUpperCase()}${e.substring(1)}')
        .join(' ');
    return 'Moduł $readable';
  }

  bool _isGeneratedDartFile(String normalizedPath) {
    return normalizedPath.endsWith('.g.dart') ||
        normalizedPath.endsWith('.freezed.dart') ||
        normalizedPath.endsWith('.mocks.dart');
  }

  String _normalizeRelativePath(String absoluteOrRelative) {
    final String rootNorm = projectRootPath.replaceAll('\\', '/').replaceAll(RegExp(r'/+$'), '');
    String norm = absoluteOrRelative.replaceAll('\\', '/');
    if (norm.startsWith('$rootNorm/')) {
      norm = norm.substring(rootNorm.length + 1);
    }
    return norm;
  }

  String _joinPath(String root, String relative) {
    final String cleanRoot = root.replaceAll('\\', '/').replaceAll(RegExp(r'/+$'), '');
    final String cleanRel = relative.replaceAll('\\', '/').replaceAll(RegExp(r'^/+'), '');
    return '$cleanRoot/$cleanRel';
  }
}

/// Stan kontrolera Riverpod dla `CodeMapAutoSynchronizer`.
@immutable
class CodeMapSyncState {
  final bool isScanning;
  final CodeMapSyncReport? report;
  final CodeMapSyncFilter selectedFilter;
  final ArchitectureLayer? selectedLayer;
  final String searchQuery;
  final String? selectedFilePath;
  final String? errorMessage;
  final CodeMapSynchronizeResult? lastSyncPreview;

  const CodeMapSyncState({
    this.isScanning = false,
    this.report,
    this.selectedFilter = CodeMapSyncFilter.all,
    this.selectedLayer,
    this.searchQuery = '',
    this.selectedFilePath,
    this.errorMessage,
    this.lastSyncPreview,
  });

  CodeMapSyncState copyWith({
    bool? isScanning,
    CodeMapSyncReport? report,
    CodeMapSyncFilter? selectedFilter,
    ArchitectureLayer? selectedLayer,
    bool clearSelectedLayer = false,
    String? searchQuery,
    String? selectedFilePath,
    bool clearSelectedFile = false,
    String? errorMessage,
    bool clearError = false,
    CodeMapSynchronizeResult? lastSyncPreview,
  }) {
    return CodeMapSyncState(
      isScanning: isScanning ?? this.isScanning,
      report: report ?? this.report,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      selectedLayer: clearSelectedLayer ? null : (selectedLayer ?? this.selectedLayer),
      searchQuery: searchQuery ?? this.searchQuery,
      selectedFilePath: clearSelectedFile ? null : (selectedFilePath ?? this.selectedFilePath),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastSyncPreview: lastSyncPreview ?? this.lastSyncPreview,
    );
  }

  List<FileRegistrationStatus> get filteredFiles {
    final CodeMapSyncReport? r = report;
    if (r == null) return const [];
    final String q = searchQuery.trim().toLowerCase();

    return r.files.where((file) {
      if (selectedLayer != null && file.layer != selectedLayer) {
        return false;
      }
      switch (selectedFilter) {
        case CodeMapSyncFilter.all:
          break;
        case CodeMapSyncFilter.unregistered:
          if (file.registeredInCodeMap) return false;
          break;
        case CodeMapSyncFilter.unusedImports:
          if (file.unusedImports.isEmpty) return false;
          break;
        case CodeMapSyncFilter.orphaned:
          if (!file.isOrphaned) return false;
          break;
        case CodeMapSyncFilter.healthy:
          if (!file.isHealthy) return false;
          break;
      }
      if (q.isNotEmpty) {
        final bool pathMatch = file.filePath.toLowerCase().contains(q);
        final bool symbolMatch =
            file.declaredSymbols.any((s) => s.toLowerCase().contains(q));
        if (!pathMatch && !symbolMatch) return false;
      }
      return true;
    }).toList();
  }
}

/// Notifier zarządzający stanem skanowania i synchronizacji `docs/CODE_MAP.md`.
class CodeMapAutoSynchronizerNotifier extends StateNotifier<CodeMapSyncState> {
  final CodeMapAutoSynchronizer _synchronizer;

  CodeMapAutoSynchronizerNotifier({CodeMapAutoSynchronizer? synchronizer})
      : _synchronizer = synchronizer ?? CodeMapAutoSynchronizer(),
        super(const CodeMapSyncState());

  Future<void> runAudit() async {
    if (state.isScanning) return;
    state = state.copyWith(isScanning: true, clearError: true);
    try {
      final CodeMapSyncReport report = await _synchronizer.runAudit();
      final String? firstSelected = report.files.isNotEmpty ? report.files.first.filePath : null;
      state = state.copyWith(
        isScanning: false,
        report: report,
        selectedFilePath: state.selectedFilePath ?? firstSelected,
      );
    } catch (e) {
      state = state.copyWith(
        isScanning: false,
        errorMessage: 'Błąd audytu CODE_MAP: $e',
      );
    }
  }

  Future<void> previewSynchronize({bool removeStale = false}) async {
    try {
      final CodeMapSynchronizeResult result = await _synchronizer.synchronizeCodeMap(
        dryRun: true,
        removeStale: removeStale,
      );
      state = state.copyWith(lastSyncPreview: result, clearError: true);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Nie udało się przygotować podglądu: $e');
    }
  }

  void setFilter(CodeMapSyncFilter filter) {
    state = state.copyWith(selectedFilter: filter);
  }

  void setLayerFilter(ArchitectureLayer? layer) {
    if (layer == null) {
      state = state.copyWith(clearSelectedLayer: true);
    } else {
      state = state.copyWith(selectedLayer: layer);
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void selectFile(String filePath) {
    state = state.copyWith(selectedFilePath: filePath);
  }
}

final codeMapAutoSynchronizerProvider =
    StateNotifierProvider<CodeMapAutoSynchronizerNotifier, CodeMapSyncState>(
  (ref) => CodeMapAutoSynchronizerNotifier(),
);

/// Responsywny panel UI narzędzia `CodeMapAutoSynchronizer` zgodny z paletą `AppColors` i czcionką `Inter`.
class CodeMapAutoSynchronizerPanel extends StatefulWidget {
  final CodeMapSyncReport? initialReport;
  final VoidCallback? onRunAudit;
  final VoidCallback? onPreviewSync;

  const CodeMapAutoSynchronizerPanel({
    super.key,
    this.initialReport,
    this.onRunAudit,
    this.onPreviewSync,
  });

  @override
  State<CodeMapAutoSynchronizerPanel> createState() =>
      _CodeMapAutoSynchronizerPanelState();
}

class _CodeMapAutoSynchronizerPanelState extends State<CodeMapAutoSynchronizerPanel> {
  late final TextEditingController _searchController;
  CodeMapSyncReport? _report;
  CodeMapSyncFilter _selectedFilter = CodeMapSyncFilter.all;
  ArchitectureLayer? _selectedLayer;
  String _searchQuery = '';
  String? _selectedFilePath;
  bool _isScanning = false;
  bool _copiedFeedback = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _report = widget.initialReport;
    if (_report != null && _report!.files.isNotEmpty) {
      _selectedFilePath = _report!.files.first.filePath;
    }
  }

  @override
  void didUpdateWidget(covariant CodeMapAutoSynchronizerPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialReport != oldWidget.initialReport && widget.initialReport != null) {
      _report = widget.initialReport;
      if (_selectedFilePath == null && _report!.files.isNotEmpty) {
        _selectedFilePath = _report!.files.first.filePath;
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleRunAudit() async {
    if (_isScanning) return;
    if (widget.onRunAudit != null) {
      widget.onRunAudit!();
      return;
    }
    setState(() => _isScanning = true);
    try {
      final CodeMapSyncReport report = await CodeMapAutoSynchronizer().runAudit();
      if (!mounted) return;
      setState(() {
        _report = report;
        _isScanning = false;
        _selectedFilePath = report.files.isNotEmpty ? report.files.first.filePath : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isScanning = false);
    }
  }

  List<FileRegistrationStatus> _filteredFiles() {
    final CodeMapSyncReport? report = _report;
    if (report == null) return const [];
    final String q = _searchQuery.trim().toLowerCase();
    return report.files.where((file) {
      if (_selectedLayer != null && file.layer != _selectedLayer) {
        return false;
      }
      switch (_selectedFilter) {
        case CodeMapSyncFilter.all:
          break;
        case CodeMapSyncFilter.unregistered:
          if (file.registeredInCodeMap) return false;
          break;
        case CodeMapSyncFilter.unusedImports:
          if (file.unusedImports.isEmpty) return false;
          break;
        case CodeMapSyncFilter.orphaned:
          if (!file.isOrphaned) return false;
          break;
        case CodeMapSyncFilter.healthy:
          if (!file.isHealthy) return false;
          break;
      }
      if (q.isNotEmpty) {
        final bool matchPath = file.filePath.toLowerCase().contains(q);
        final bool matchSym = file.declaredSymbols.any((s) => s.toLowerCase().contains(q));
        if (!matchPath && !matchSym) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          final bool isMobile = width < 720;
          final bool isDesktop = width >= 1120;

          final List<FileRegistrationStatus> filtered = _filteredFiles();
          FileRegistrationStatus? selectedFile;
          if (filtered.isNotEmpty) {
            selectedFile = filtered.firstWhere(
              (f) => f.filePath == _selectedFilePath,
              orElse: () => filtered.first,
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 14 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(isMobile),
                const SizedBox(height: 16),
                _buildKpiGrid(isMobile: isMobile, isDesktop: isDesktop),
                const SizedBox(height: 16),
                _buildFilterToolbar(isMobile),
                const SizedBox(height: 16),
                if (_report == null)
                  _buildEmptyState()
                else if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: _buildFileListCard(filtered, isMobile: false),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 5,
                        child: _buildInspectorCard(selectedFile),
                      ),
                    ],
                  )
                else ...[
                  _buildFileListCard(filtered, isMobile: isMobile),
                  const SizedBox(height: 16),
                  _buildInspectorCard(selectedFile),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    final CodeMapSyncReport? report = _report;
    final bool passed = report?.allPassed ?? false;
    final Color badgeColor = report == null
        ? AppColors.accentBlue
        : (passed ? AppColors.statusSuccess : AppColors.amberWarning);

    final Widget titleBlock = Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primaryAccent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.5)),
          ),
          child: const Icon(
            Icons.account_tree_rounded,
            color: AppColors.goldAccent,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Code Map Auto Synchronizer',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
                report == null
                    ? 'Audyt rejestracji plików lib/ w CODE_MAP.md i czystości importów'
                    : 'Zgodność: ${report.complianceScore.toStringAsFixed(1)}% • Czas skanu: ${report.scanDuration.inMilliseconds} ms',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
    );

    final Widget actionsBlock = Wrap(
      spacing: 10,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
          ),
          child: Text(
            report == null
                ? 'GOTOWY'
                : (passed ? '100% SYNCHRONIZACJA' : 'WYMAGA UWAGI'),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: badgeColor,
              letterSpacing: 0.4,
            ),
          ),
        ),
        _SynchronizerActionButton(
          label: _isScanning ? 'Skanowanie...' : 'Skanuj lib/',
          icon: Icons.refresh_rounded,
          isPrimary: true,
          isDisabled: _isScanning,
          onPressed: _handleRunAudit,
        ),
        if (widget.onPreviewSync != null)
          _SynchronizerActionButton(
            label: 'Podgląd CODE_MAP',
            icon: Icons.sync_rounded,
            isPrimary: false,
            isDisabled: _isScanning,
            onPressed: widget.onPreviewSync!,
          ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleBlock,
                const SizedBox(height: 12),
                actionsBlock,
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: titleBlock),
                const SizedBox(width: 12),
                actionsBlock,
              ],
            ),
    );
  }

  Widget _buildKpiGrid({required bool isMobile, required bool isDesktop}) {
    final CodeMapSyncReport? report = _report;
    final List<_KpiTileData> tiles = [
      _KpiTileData(
        title: 'Pliki Dart w lib/',
        value: report == null ? '—' : '${report.totalDartFiles}',
        subtitle: report == null
            ? 'Brak pomiaru'
            : '${report.registeredFilesCount} zarejestrowanych',
        accent: AppColors.accentBlue,
        icon: Icons.description_rounded,
      ),
      _KpiTileData(
        title: 'Brak w CODE_MAP',
        value: report == null ? '—' : '${report.unregisteredFilesCount}',
        subtitle: report == null
            ? 'Oczekuje na audyt'
            : (report.unregisteredFilesCount == 0
                ? 'Wszystkie pliki wpisane'
                : 'Wymaga dopisania'),
        accent: report != null && report.unregisteredFilesCount > 0
            ? AppColors.amberWarning
            : AppColors.statusSuccess,
        icon: Icons.playlist_add_check_rounded,
      ),
      _KpiTileData(
        title: 'Nieużywane importy',
        value: report == null ? '—' : '${report.totalUnusedImportsCount}',
        subtitle: report == null
            ? 'Oczekuje na audyt'
            : 'W ${report.filesWithUnusedImportsCount} plikach',
        accent: report != null && report.totalUnusedImportsCount > 0
            ? AppColors.crimsonAlert
            : AppColors.statusSuccess,
        icon: Icons.cleaning_services_rounded,
      ),
      _KpiTileData(
        title: 'Nieaktualne / Sieroty',
        value: report == null
            ? '—'
            : '${report.staleEntriesCount}/${report.orphanedFilesCount}',
        subtitle: 'Wpisy stale / brak ref.',
        accent: report != null && report.staleEntriesCount > 0
            ? AppColors.amberWarning
            : AppColors.goldAccent,
        icon: Icons.link_off_rounded,
      ),
    ];

    final int columns = isDesktop ? 4 : (isMobile ? 1 : 2);
    if (columns == 1) {
      return Column(
        children: [
          for (int i = 0; i < tiles.length; i++) ...[
            _KpiMetricCard(data: tiles[i]),
            if (i < tiles.length - 1) const SizedBox(height: 10),
          ],
        ],
      );
    }

    if (columns == 2) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _KpiMetricCard(data: tiles[0])),
              const SizedBox(width: 12),
              Expanded(child: _KpiMetricCard(data: tiles[1])),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _KpiMetricCard(data: tiles[2])),
              const SizedBox(width: 12),
              Expanded(child: _KpiMetricCard(data: tiles[3])),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        for (int i = 0; i < tiles.length; i++) ...[
          Expanded(child: _KpiMetricCard(data: tiles[i])),
          if (i < tiles.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }

  Widget _buildFilterToolbar(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final CodeMapSyncFilter filter in CodeMapSyncFilter.values)
                _FilterChipButton(
                  key: Key('filter_chip_${filter.name}'),
                  label: filter.label,
                  isSelected: _selectedFilter == filter,
                  onTap: () => setState(() => _selectedFilter = filter),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (isMobile) ...[
            _buildSearchField(),
            const SizedBox(height: 10),
            _buildLayerDropdown(),
          ] else
            Row(
              children: [
                Expanded(flex: 3, child: _buildSearchField()),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: _buildLayerDropdown()),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _searchQuery = value),
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: 'Szukaj ścieżki pliku lub symbolu...',
        hintStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
        prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textSecondary),
        suffixIcon: _searchQuery.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.textSecondary),
              ),
        filled: true,
        fillColor: AppColors.surfaceLight,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
          borderSide: const BorderSide(color: AppColors.goldAccent, width: 1.2),
        ),
      ),
    );
  }

  Widget _buildLayerDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ArchitectureLayer?>(
          value: _selectedLayer,
          isExpanded: true,
          dropdownColor: AppColors.surfaceLight,
          iconEnabledColor: AppColors.textSecondary,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: AppColors.textPrimary,
          ),
          items: [
            const DropdownMenuItem<ArchitectureLayer?>(
              value: null,
              child: Text('Wszystkie warstwy'),
            ),
            for (final ArchitectureLayer layer in ArchitectureLayer.values)
              DropdownMenuItem<ArchitectureLayer?>(
                value: layer,
                child: Text(layer.label),
              ),
          ],
          onChanged: (value) => setState(() => _selectedLayer = value),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Column(
        children: [
          const Icon(Icons.radar_rounded, size: 40, color: AppColors.goldAccent),
          const SizedBox(height: 12),
          const Text(
            'Brak załadowanego raportu synchronizacji',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Kliknij „Skanuj lib/”, aby zweryfikować wpisy w docs/CODE_MAP.md oraz wykryć nieużywane importy.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          _SynchronizerActionButton(
            label: 'Uruchom skanowanie',
            icon: Icons.play_arrow_rounded,
            isPrimary: true,
            isDisabled: _isScanning,
            onPressed: _handleRunAudit,
          ),
        ],
      ),
    );
  }

  Widget _buildFileListCard(List<FileRegistrationStatus> files, {required bool isMobile}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Pliki w architekturze lib/',
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
                '${files.length} pozycji',
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
          if (files.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Brak plików spełniających wybrane kryteria filtrowania.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: isMobile ? 320 : 440),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: files.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final FileRegistrationStatus item = files[index];
                  final bool isSelected = item.filePath == _selectedFilePath ||
                      (_selectedFilePath == null && index == 0);
                  return _FileRowTile(
                    file: item,
                    isSelected: isSelected,
                    onTap: () => setState(() => _selectedFilePath = item.filePath),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInspectorCard(FileRegistrationStatus? file) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: file == null
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Wybierz plik z listy, aby zobaczyć szczegóły rejestracji i importów.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(file.layer.icon, size: 18, color: AppColors.goldAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        file.filePath,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
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
                    _StatusPill(
                      label: file.registeredInCodeMap ? 'W CODE_MAP.md' : 'Brak w CODE_MAP.md',
                      color: file.registeredInCodeMap
                          ? AppColors.statusSuccess
                          : AppColors.amberWarning,
                    ),
                    _StatusPill(
                      label: file.unusedImports.isEmpty
                          ? 'Importy czyste'
                          : '${file.unusedImports.length} nieużywanych importów',
                      color: file.unusedImports.isEmpty
                          ? AppColors.statusSuccess
                          : AppColors.crimsonAlert,
                    ),
                    _StatusPill(
                      label: '${file.lineCount} linii',
                      color: AppColors.accentBlue,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Sugerowany wpis 1-linijkowy CODE_MAP.md',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: SelectableText(
                    file.suggestedCodeMapLine,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: _SynchronizerActionButton(
                    label: _copiedFeedback ? 'Skopiowano!' : 'Kopiuj wpis',
                    icon: _copiedFeedback ? Icons.check_rounded : Icons.copy_rounded,
                    isPrimary: false,
                    isDisabled: false,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: file.suggestedCodeMapLine));
                      setState(() => _copiedFeedback = true);
                    },
                  ),
                ),
                if (file.unusedImports.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'Wykryte nieużywane importy',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.crimsonAlert,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final UnusedImportIssue issue in file.unusedImports)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.crimsonAlert.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.crimsonAlert.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Linia ${issue.lineNumber}: ${issue.importUri}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            issue.reason,
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
              ],
            ),
    );
  }
}

@immutable
class _KpiTileData {
  final String title;
  final String value;
  final String subtitle;
  final Color accent;
  final IconData icon;

  const _KpiTileData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accent,
    required this.icon,
  });
}

class _KpiMetricCard extends StatelessWidget {
  final _KpiTileData data;

  const _KpiMetricCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: data.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, color: data.accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.value,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
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

class _SynchronizerActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final bool isDisabled;
  final VoidCallback onPressed;

  const _SynchronizerActionButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.isDisabled,
    required this.onPressed,
  });

  @override
  State<_SynchronizerActionButton> createState() => _SynchronizerActionButtonState();
}

class _SynchronizerActionButtonState extends State<_SynchronizerActionButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final Color baseBg = widget.isPrimary ? AppColors.primaryAccent : AppColors.surfaceLight;
    final Color bg = widget.isDisabled
        ? AppColors.surfaceLight.withValues(alpha: 0.5)
        : (_pressed
            ? baseBg.withValues(alpha: 0.85)
            : (_hovered ? baseBg.withValues(alpha: 0.92) : baseBg));
    final Color borderColor = _focused
        ? AppColors.goldAccent
        : (widget.isPrimary ? AppColors.goldAccent.withValues(alpha: 0.6) : AppTheme.borderColor);

    return FocusableActionDetector(
      enabled: !widget.isDisabled,
      onShowFocusHighlight: (focused) => setState(() => _focused = focused),
      onShowHoverHighlight: (hovered) => setState(() => _hovered = hovered),
      child: GestureDetector(
        onTapDown: widget.isDisabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: widget.isDisabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: widget.isDisabled ? null : () => setState(() => _pressed = false),
        onTap: widget.isDisabled ? null : widget.onPressed,
        child: MouseRegion(
          cursor: widget.isDisabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: _focused ? 1.5 : 1.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 16,
                  color: widget.isDisabled ? AppColors.textSecondary : AppColors.textPrimary,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: widget.isDisabled ? AppColors.textSecondary : AppColors.textPrimary,
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

class _FilterChipButton extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChipButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_FilterChipButton> createState() => _FilterChipButtonState();
}

class _FilterChipButtonState extends State<_FilterChipButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final Color bg = widget.isSelected
        ? AppColors.primaryAccent.withValues(alpha: 0.25)
        : (_hovered ? AppColors.surfaceLight : AppColors.background);
    final Color border = _focused || widget.isSelected
        ? AppColors.goldAccent
        : AppTheme.borderColor;

    return FocusableActionDetector(
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      child: GestureDetector(
        onTap: widget.onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: border),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                color: widget.isSelected ? AppColors.goldAccent : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FileRowTile extends StatefulWidget {
  final FileRegistrationStatus file;
  final bool isSelected;
  final VoidCallback onTap;

  const _FileRowTile({
    required this.file,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_FileRowTile> createState() => _FileRowTileState();
}

class _FileRowTileState extends State<_FileRowTile> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final Color statusColor = widget.file.isHealthy
        ? AppColors.statusSuccess
        : (widget.file.unusedImports.isNotEmpty
            ? AppColors.crimsonAlert
            : AppColors.amberWarning);

    return FocusableActionDetector(
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      child: GestureDetector(
        onTap: widget.onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? AppColors.surfaceLight
                  : (_hovered ? AppColors.surfaceLight.withValues(alpha: 0.55) : AppColors.background),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _focused || widget.isSelected ? AppColors.goldAccent : AppTheme.borderColor,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.file.filePath,
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
                        '${widget.file.layer.label} • ${widget.file.declaredSymbols.length} symboli',
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
                _StatusPill(
                  label: widget.file.isHealthy
                      ? 'OK'
                      : (!widget.file.registeredInCodeMap ? 'BRAK' : 'IMPORT'),
                  color: statusColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
