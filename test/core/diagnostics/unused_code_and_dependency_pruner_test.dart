import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/diagnostics/unused_code_and_dependency_pruner.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';

void main() {
  group('UnusedCodeAndDependencyPruner', () {
    test('detects unused imports, missing class docs, TODOs, orphaned files and unused deps', () async {
      final tempDir = await Directory.systemTemp.createTemp('pruner_test_');
      try {
        await File('${tempDir.path}/pubspec.yaml').writeAsString('''
name: sample_app
dependencies:
  flutter:
    sdk: flutter
  used_pkg: ^1.0.0
  unused_pkg: ^2.0.0
dev_dependencies:
  flutter_test:
    sdk: flutter
''');

        await Directory('${tempDir.path}/lib/models').create(recursive: true);
        await Directory('${tempDir.path}/lib/utils').create(recursive: true);

        await File('${tempDir.path}/lib/models/used_model.dart').writeAsString('''
/// Udokumentowany model.
class UsedModel {
  final int id;
  const UsedModel(this.id);
}
''');

        await File('${tempDir.path}/lib/models/orphan_model.dart').writeAsString('''
class UndocumentedOrphan {
  const UndocumentedOrphan();
}
''');

        await File('${tempDir.path}/lib/main.dart').writeAsString('''
import 'package:used_pkg/used_pkg.dart';
import 'package:unused_alias/lib.dart' as unused_alias;
import 'package:show_pkg/show_pkg.dart' show UnusedSymbol;
import 'models/used_model.dart';
import 'models/used_model.dart';

/// Główna aplikacja.
class MainApp {
  const MainApp();
}

void main() {
  // TO DO: clean format
  // TODO: remove temporary log
  const UsedModel(1);
}
''');

        const pruner = UnusedCodeAndDependencyPruner();
        final report = await pruner.scanProject(projectRoot: tempDir.path);

        expect(report.totalFilesScanned, 3);
        expect(report.totalPublicTypesFound, 3);
        expect(report.documentedTypesCount, 2);
        expect(report.unusedImportsCount, 3);
        expect(report.orphanedFilesCount, 1);
        expect(report.unusedDependenciesCount, 1);
        expect(report.unusedDependencies.first.packageName, 'unused_pkg');
        expect(report.todoCount, 1);
        expect(report.toMarkdownReport(), contains('Raport Prunera Kodu'));
        expect(report.toJson()['unusedImportsCount'], 3);

        final dryRun = await pruner.pruneUnusedImports(
          report: report,
          projectRoot: tempDir.path,
          dryRun: true,
        );
        expect(dryRun.dryRun, isTrue);
        expect(dryRun.removedImportsCount, 3);

        final applied = await pruner.pruneUnusedImports(
          report: report,
          projectRoot: tempDir.path,
          dryRun: false,
        );
        expect(applied.dryRun, isFalse);
        expect(applied.errors, isEmpty);
        expect(applied.removedImportsCount, 3);

        final rescan = await pruner.scanProject(projectRoot: tempDir.path);
        expect(rescan.unusedImportsCount, 0);
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    test('generates Polish docstring stubs by declaration kind', () {
      const pruner = UnusedCodeAndDependencyPruner();
      const enumFinding = MissingClassDocFinding(
        filePath: 'lib/a.dart',
        symbolName: 'RaceMode',
        declarationKind: 'enum',
        lineNumber: 10,
      );
      expect(
        pruner.generateDocstringStub(enumFinding),
        contains('Wyliczenie `RaceMode`'),
      );
    });
  });

  group('UnusedCodeAndDependencyPrunerPanel responsive UI', () {
    Future<void> pumpPanelAtSize(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(
              body: UnusedCodeAndDependencyPrunerPanel(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renders without overflow at 390x844 (mobile)', (tester) async {
      await pumpPanelAtSize(tester, const Size(390, 844));
      expect(
        find.text('Pruner Martwego Kodu i Dokumentacji Klas'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow at 1024x768 (tablet)', (tester) async {
      await pumpPanelAtSize(tester, const Size(1024, 768));
      expect(find.text('Kondycja Kodu'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow at 1600x900 (desktop)', (tester) async {
      await pumpPanelAtSize(tester, const Size(1600, 900));
      expect(find.text('Audytowane pliki'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
