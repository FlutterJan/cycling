// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/diagnostics/code_map_auto_synchronizer.dart';

void main() {
  group('CodeMapAutoSynchronizer - Unit Tests', () {
    late Directory tempRoot;

    setUp(() async {
      tempRoot = await Directory.systemTemp.createTemp('code_map_sync_test_');
      await Directory('${tempRoot.path}/lib/core/diagnostics').create(recursive: true);
      await Directory('${tempRoot.path}/lib/models/rider').create(recursive: true);
      await Directory('${tempRoot.path}/docs').create(recursive: true);
      await Directory('${tempRoot.path}/test').create(recursive: true);
    });

    tearDown(() async {
      if (await tempRoot.exists()) {
        await tempRoot.delete(recursive: true);
      }
    });

    test('detects unregistered files, stale entries and unused imports accurately', () async {
      await File('${tempRoot.path}/lib/models/rider/rider.dart').writeAsString('''
/// Model kolarza.
class Rider {
  final String name;
  const Rider(this.name);
}
''');

      await File('${tempRoot.path}/lib/core/diagnostics/sample_tool.dart').writeAsString('''
import 'dart:math';
import 'dart:async' as async_lib;
import 'package:pro_peloton_manager/models/rider/rider.dart';

/// Przykładowe narzędzie diagnostyczne.
class SampleTool {
  int compute(int x) => max(x, 10);
}
''');

      await File('${tempRoot.path}/docs/CODE_MAP.md').writeAsString('''
# Mapa Projektu

### `lib/` & `lib/core/`
- `lib/core/diagnostics/deleted_old_file.dart` — Nieistniejący plik.

### `lib/models/`
- `lib/models/rider/rider.dart` — Model kolarza (`Rider`).
''');

      final CodeMapAutoSynchronizer sync = CodeMapAutoSynchronizer(
        projectRootPath: tempRoot.path,
      );
      final CodeMapSyncReport report = await sync.runAudit();

      expect(report.codeMapExists, isTrue);
      expect(report.totalDartFiles, 2);
      expect(report.registeredFilesCount, 1);
      expect(report.unregisteredFilesCount, 1);
      expect(report.staleEntriesCount, 1);
      expect(report.staleEntries.first.filePath, 'lib/core/diagnostics/deleted_old_file.dart');

      final FileRegistrationStatus sampleStatus = report.files.firstWhere(
        (f) => f.filePath == 'lib/core/diagnostics/sample_tool.dart',
      );
      expect(sampleStatus.registeredInCodeMap, isFalse);
      // `dart:math` IS used (max), while `dart:async as async_lib` and `rider.dart` are unused.
      expect(sampleStatus.unusedImports.length, 2);
      expect(
        sampleStatus.unusedImports.map((e) => e.importUri),
        containsAll(['dart:async', 'package:pro_peloton_manager/models/rider/rider.dart']),
      );
      expect(sampleStatus.suggestedCodeMapLine, contains('SampleTool'));
    });

    test('synchronizeCodeMap dryRun previews without modifying disk and apply writes changes',
        () async {
      await File('${tempRoot.path}/lib/core/diagnostics/new_diag.dart').writeAsString('''
/// Nowy moduł diagnostyczny.
class NewDiag {
  void run() {}
}
''');

      final File codeMapFile = File('${tempRoot.path}/docs/CODE_MAP.md');
      await codeMapFile.writeAsString('''
# Mapa Projektu

### `lib/` & `lib/core/`
- `lib/core/diagnostics/ghost.dart` — Stary wpis.
''');

      final CodeMapAutoSynchronizer sync = CodeMapAutoSynchronizer(
        projectRootPath: tempRoot.path,
      );

      final CodeMapSynchronizeResult preview = await sync.synchronizeCodeMap(
        dryRun: true,
        removeStale: true,
      );
      expect(preview.applied, isFalse);
      expect(preview.addedEntriesCount, 1);
      expect(preview.removedStaleCount, 1);
      expect(preview.updatedCodeMapContent, contains('lib/core/diagnostics/new_diag.dart'));
      expect(preview.updatedCodeMapContent, isNot(contains('ghost.dart')));

      // Disk should remain untouched after dryRun.
      expect(await codeMapFile.readAsString(), contains('ghost.dart'));

      final CodeMapSynchronizeResult applied = await sync.synchronizeCodeMap(
        dryRun: false,
        removeStale: true,
      );
      expect(applied.applied, isTrue);
      final String afterWrite = await codeMapFile.readAsString();
      expect(afterWrite, contains('lib/core/diagnostics/new_diag.dart'));
      expect(afterWrite, isNot(contains('ghost.dart')));
    });

    test('analyzeUnusedImports handles show clauses, dart:core and exports', () {
      final CodeMapAutoSynchronizer sync = CodeMapAutoSynchronizer();
      const String source = '''
import 'dart:core';
import 'dart:convert' show jsonEncode, utf8;
import 'dart:math' show min, max;
export 'dart:async';

class Demo {
  int calc(int a, int b) => min(a, b);
}
''';
      final List<UnusedImportIssue> issues = sync.analyzeUnusedImports(source);
      expect(issues.length, 2);
      expect(issues.map((e) => e.importUri), containsAll(['dart:core', 'dart:convert']));
    });

    test('runs audit against real workspace repository', () async {
      final CodeMapAutoSynchronizer sync = CodeMapAutoSynchronizer();
      final CodeMapSyncReport report = await sync.runAudit();
      expect(report.codeMapExists, isTrue);
      expect(report.totalDartFiles, greaterThan(10));
      expect(report.toMarkdownSummary(), contains('Raport CodeMapAutoSynchronizer'));
    });
  });

  group('CodeMapAutoSynchronizerPanel - Responsive UI Tests', () {
    final CodeMapSyncReport sampleReport = CodeMapSyncReport(
      generatedAt: DateTime(2026, 11, 16, 20, 0),
      projectRootPath: 'C:/repo',
      codeMapExists: true,
      totalDartFiles: 3,
      registeredFilesCount: 2,
      unregisteredFilesCount: 1,
      staleEntriesCount: 0,
      filesWithUnusedImportsCount: 1,
      totalUnusedImportsCount: 1,
      orphanedFilesCount: 0,
      scanDuration: const Duration(milliseconds: 42),
      staleEntries: const [],
      files: const [
        FileRegistrationStatus(
          filePath: 'lib/core/diagnostics/code_map_auto_synchronizer.dart',
          layer: ArchitectureLayer.core,
          lineCount: 420,
          sizeBytes: 14500,
          declaredSymbols: ['CodeMapAutoSynchronizer', 'CodeMapAutoSynchronizerPanel'],
          registeredInCodeMap: true,
          registeredSymbolsInCodeMap: ['CodeMapAutoSynchronizer'],
          missingSymbolsInCodeMap: ['CodeMapAutoSynchronizerPanel'],
          hasIncomingReferences: true,
          unusedImports: [],
          suggestedCodeMapLine:
              '- `lib/core/diagnostics/code_map_auto_synchronizer.dart` — Synchronizer.',
        ),
        FileRegistrationStatus(
          filePath: 'lib/services/career/sample_unregistered_service.dart',
          layer: ArchitectureLayer.services,
          lineCount: 120,
          sizeBytes: 3800,
          declaredSymbols: ['SampleUnregisteredService'],
          registeredInCodeMap: false,
          registeredSymbolsInCodeMap: [],
          missingSymbolsInCodeMap: ['SampleUnregisteredService'],
          hasIncomingReferences: true,
          unusedImports: [
            UnusedImportIssue(
              filePath: 'lib/services/career/sample_unregistered_service.dart',
              importUri: 'dart:math',
              lineNumber: 3,
              rawStatement: "import 'dart:math';",
              reason: 'Brak użycia symboli z `dart:math` w ciele pliku.',
            ),
          ],
          suggestedCodeMapLine:
              '- `lib/services/career/sample_unregistered_service.dart` — Sample (`SampleUnregisteredService`).',
        ),
      ],
    );

    Future<void> pumpAtSize(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CodeMapAutoSynchronizerPanel(initialReport: sampleReport),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renders cleanly at 390x844 mobile without overflow', (tester) async {
      await pumpAtSize(tester, const Size(390, 844));
      expect(tester.takeException(), isNull);
      expect(find.text('Code Map Auto Synchronizer'), findsOneWidget);
    });

    testWidgets('renders cleanly at 1024x768 tablet without overflow', (tester) async {
      await pumpAtSize(tester, const Size(1024, 768));
      expect(tester.takeException(), isNull);
      expect(find.text('Pliki w architekturze lib/'), findsOneWidget);
    });

    testWidgets('renders cleanly at 1600x900 desktop and supports filtering', (tester) async {
      await pumpAtSize(tester, const Size(1600, 900));
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const Key('filter_chip_unregistered')));
      await tester.pump(const Duration(milliseconds: 250));
      expect(
        find.text('lib/services/career/sample_unregistered_service.dart'),
        findsWidgets,
      );
    });
  });
}
