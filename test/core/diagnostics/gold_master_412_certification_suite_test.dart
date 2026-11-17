import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/diagnostics/gold_master_412_certification_suite.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';

void main() {
  group('GoldMaster412CertificationSuite', () {
    test('maps task numbers #001-#412 to all 6 packages', () {
      expect(
        GoldMasterPackageId.fromTaskNumber(1),
        GoldMasterPackageId.foundation,
      );
      expect(
        GoldMasterPackageId.fromTaskNumber(162),
        GoldMasterPackageId.foundation,
      );
      expect(
        GoldMasterPackageId.fromTaskNumber(163),
        GoldMasterPackageId.package1,
      );
      expect(
        GoldMasterPackageId.fromTaskNumber(213),
        GoldMasterPackageId.package2,
      );
      expect(
        GoldMasterPackageId.fromTaskNumber(263),
        GoldMasterPackageId.package3,
      );
      expect(
        GoldMasterPackageId.fromTaskNumber(313),
        GoldMasterPackageId.package4,
      );
      expect(
        GoldMasterPackageId.fromTaskNumber(363),
        GoldMasterPackageId.package5,
      );
      expect(
        GoldMasterPackageId.fromTaskNumber(412),
        GoldMasterPackageId.package5,
      );
    });

    test('verifies synthetic project and exports JSON & Markdown', () async {
      final tempDir = await Directory.systemTemp.createTemp('gm_412_test_');
      try {
        await File('${tempDir.path}/pubspec.yaml').writeAsString('name: test\n');
        await Directory('${tempDir.path}/docs').create(recursive: true);
        await Directory('${tempDir.path}/lib/core/router')
            .create(recursive: true);
        await Directory('${tempDir.path}/lib/core/diagnostics')
            .create(recursive: true);
        await Directory('${tempDir.path}/lib/engine').create(recursive: true);

        await File('${tempDir.path}/lib/core/router/app_router.dart')
            .writeAsString('''
class AppRoutes {
  static const gravelWorldSeries = '/gravel';
  static const olympicGames = '/olympics';
  static const databaseEditor = '/db';
  static const achievements = '/achievements';
  static const preStagePaddock = '/paddock';
  static const companionCar = '/team-car';
}
''');
        await File('${tempDir.path}/lib/engine/engine_integration_bridge.dart')
            .writeAsString('class EngineIntegrationBridge {}');
        await File(
          '${tempDir.path}/lib/core/diagnostics/full_state_serialization_fuzz_tester.dart',
        ).writeAsString('class FullStateSerializationFuzzTester {}');
        await File(
          '${tempDir.path}/lib/core/diagnostics/full_navigation_routes_verifier.dart',
        ).writeAsString('class FullNavigationRoutesVerifier {}');
        await File(
          '${tempDir.path}/lib/core/diagnostics/ui_golden_contrast_and_font_auditor.dart',
        ).writeAsString('class UiGoldenContrastAndFontAuditor {}');
        await File(
          '${tempDir.path}/lib/core/diagnostics/memory_and_stream_leak_guard.dart',
        ).writeAsString('class MemoryAndStreamLeakGuard {}');

        await File('${tempDir.path}/docs/CODE_MAP.md').writeAsString('''
- `lib/core/router/app_router.dart`
- `lib/engine/engine_integration_bridge.dart`
''');

        await File('${tempDir.path}/docs/QUEUE.md').writeAsString('''
- [x] **Zadanie #001** (`lib/core/router/app_router.dart`): Router.
- [x] **Zadanie #363** (`lib/engine/engine_integration_bridge.dart`): Bridge.
''');

        const suite = GoldMaster412CertificationSuite();
        final report = await suite.runCertification(
          projectRoot: tempDir.path,
          runFlutterAnalyze: false,
          runFlutterTest: false,
        );

        expect(report.totalTasksChecked, 2);
        expect(report.passedTasksCount, 2);
        expect(report.codeMapResult.passed, isTrue);
        expect(report.allPillarsPassed, isTrue);
        expect(report.verdict, GoldMasterVerdict.blocked);
        expect(report.toPrettyJson(), contains('GOLD MASTER v1.0'));
        expect(
          report.toMarkdownCertificate(),
          contains('# Certyfikat GOLD MASTER v1.0'),
        );
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('verifies real repository pillars and queue entries', () async {
      const suite = GoldMaster412CertificationSuite();
      final report = await suite.runCertification(
        runFlutterAnalyze: false,
        runFlutterTest: false,
      );

      expect(report.totalTasksChecked, GoldMaster412Report.expectedTotalTasks);
      expect(report.codeMapResult.exists, isTrue);
      expect(report.allPillarsPassed, isTrue);
    });
  });

  group('GoldMaster412CertificationPanel responsive UI', () {
    Future<void> pumpPanelAtSize(
      WidgetTester tester,
      Size size,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      late Directory tempDir;
      await tester.runAsync(() async {
        tempDir = await Directory.systemTemp.createTemp('gm_412_ui_');
        await File('${tempDir.path}/pubspec.yaml')
            .writeAsString('name: ui_test\n');
        await Directory('${tempDir.path}/docs').create(recursive: true);
        await Directory('${tempDir.path}/lib').create(recursive: true);
        await File('${tempDir.path}/lib/app.dart')
            .writeAsString('void main() {}');
        await File('${tempDir.path}/docs/CODE_MAP.md')
            .writeAsString('- `lib/app.dart`');
        await File('${tempDir.path}/docs/QUEUE.md').writeAsString(
          '- [x] **Zadanie #001** (`lib/app.dart`): App init.\n',
        );
      });
      addTearDown(() async {
        await tester.runAsync(() async {
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        });
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: GoldMaster412CertificationPanel(projectRoot: tempDir.path),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(
        find.text('GOLD MASTER v1.0 — Pakiet Certyfikacji (#001–#412)'),
        findsOneWidget,
      );

      await tester.runAsync(() async {
        await container
            .read(goldMaster412CertificationProvider.notifier)
            .runCertification(projectRoot: tempDir.path);
      });
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.text('Rozkład Paczek (#001–#412)'), findsOneWidget);
      expect(find.text('Rejestr Weryfikacji Zadań'), findsOneWidget);
    }

    testWidgets('renders cleanly on mobile 390x844', (tester) async {
      await pumpPanelAtSize(tester, const Size(390, 844));
    });

    testWidgets('renders cleanly on tablet 1024x768', (tester) async {
      await pumpPanelAtSize(tester, const Size(1024, 768));
    });

    testWidgets('renders cleanly on desktop 1600x900', (tester) async {
      await pumpPanelAtSize(tester, const Size(1600, 900));
    });
  });
}
