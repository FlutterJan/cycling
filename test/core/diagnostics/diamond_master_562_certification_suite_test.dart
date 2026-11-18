import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/diagnostics/diamond_master_562_certification_suite.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';

void main() {
  group('DiamondMaster562CertificationSuite', () {
    test('maps task numbers #001-#562 to all 9 packages', () {
      expect(
        DiamondMasterPackageId.fromTaskNumber(1),
        DiamondMasterPackageId.foundation,
      );
      expect(
        DiamondMasterPackageId.fromTaskNumber(162),
        DiamondMasterPackageId.foundation,
      );
      expect(
        DiamondMasterPackageId.fromTaskNumber(163),
        DiamondMasterPackageId.package1,
      );
      expect(
        DiamondMasterPackageId.fromTaskNumber(213),
        DiamondMasterPackageId.package2,
      );
      expect(
        DiamondMasterPackageId.fromTaskNumber(263),
        DiamondMasterPackageId.package3,
      );
      expect(
        DiamondMasterPackageId.fromTaskNumber(313),
        DiamondMasterPackageId.package4,
      );
      expect(
        DiamondMasterPackageId.fromTaskNumber(363),
        DiamondMasterPackageId.package5,
      );
      expect(
        DiamondMasterPackageId.fromTaskNumber(413),
        DiamondMasterPackageId.package6,
      );
      expect(
        DiamondMasterPackageId.fromTaskNumber(463),
        DiamondMasterPackageId.package7A,
      );
      expect(
        DiamondMasterPackageId.fromTaskNumber(513),
        DiamondMasterPackageId.package7B,
      );
      expect(
        DiamondMasterPackageId.fromTaskNumber(562),
        DiamondMasterPackageId.package7B,
      );
    });

    test('verifies synthetic project and exports JSON & Markdown', () async {
      final tempDir = await Directory.systemTemp.createTemp('dm_562_test_');
      try {
        await File('${tempDir.path}/pubspec.yaml').writeAsString('name: test\n');
        await Directory('${tempDir.path}/docs').create(recursive: true);
        await Directory('${tempDir.path}/lib/core/router')
            .create(recursive: true);
        await Directory('${tempDir.path}/lib/core/diagnostics')
            .create(recursive: true);
        await Directory('${tempDir.path}/lib/core/l10n')
            .create(recursive: true);
        await Directory('${tempDir.path}/lib/engine').create(recursive: true);

        await File('${tempDir.path}/lib/core/router/app_router.dart')
            .writeAsString('''
class AppRoutes {
  static const multiplayerLeagues = 'multiplayerLeagues';
  static const mtbXcoWorldCup = 'mtbXcoWorldCup';
  static const bikeBrandFactory = 'bikeBrandFactory';
  static const velodromeTrackChampionship = 'velodromeTrackChampionship';
  static const raceOrganizerHq = 'raceOrganizerHq';
  static const ultraBikepacking = 'ultraBikepacking';
  static const globalAcademies = 'globalAcademies';
  static const managerReputation = 'managerReputation';
}
''');
        await File('${tempDir.path}/lib/engine/engine_integration_bridge.dart')
            .writeAsString('class EngineIntegrationBridge {}');
        await File(
          '${tempDir.path}/lib/core/diagnostics/final_lint_and_zero_warnings_gate.dart',
        ).writeAsString('class FinalLintAndZeroWarningsGate {}');
        await File(
          '${tempDir.path}/lib/core/diagnostics/save_compatibility_v7_migrator.dart',
        ).writeAsString('class SaveCompatibilityV7Migrator {}');
        await File(
          '${tempDir.path}/lib/core/diagnostics/gold_master_412_certification_suite.dart',
        ).writeAsString('class GoldMaster412CertificationSuite {}');
        await File(
          '${tempDir.path}/lib/core/l10n/app_localizations_pl_en.dart',
        ).writeAsString('class BilingualCyclingDictionary {}');
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
- [x] **Zadanie #561** (`lib/engine/engine_integration_bridge.dart`): Bridge.
''');

        const suite = DiamondMaster562CertificationSuite();
        final report = await suite.runCertification(
          projectRoot: tempDir.path,
          runFlutterAnalyze: false,
          runFlutterTest: false,
        );

        expect(report.totalTasksChecked, 2);
        expect(report.passedTasksCount, 2);
        expect(report.codeMapResult.passed, isTrue);
        expect(report.allPillarsPassed, isTrue);
        expect(report.verdict, DiamondMasterVerdict.conditionalPass);
        expect(report.toPrettyJson(), contains('DIAMOND MASTER v2.0'));
        expect(
          report.toMarkdownCertificate(),
          contains('# Certyfikat DIAMOND MASTER v2.0'),
        );
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('verifies real repository pillars and queue entries', () async {
      const suite = DiamondMaster562CertificationSuite();
      final report = await suite.runCertification(
        runFlutterAnalyze: false,
        runFlutterTest: false,
      );

      expect(report.totalTasksChecked, 482);
      expect(report.codeMapResult.exists, isTrue);
      expect(report.allPillarsPassed, isTrue);
    });
  });

  group('DiamondMaster562CertificationPanel responsive UI', () {
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
        tempDir = await Directory.systemTemp.createTemp('dm_562_ui_');
        await File('${tempDir.path}/pubspec.yaml')
            .writeAsString('name: ui_test\n');
        await Directory('${tempDir.path}/docs').create(recursive: true);
        await Directory('${tempDir.path}/lib').create(recursive: true);
        await File('${tempDir.path}/lib/app.dart')
            .writeAsString('void main() {}');
        await File('${tempDir.path}/docs/CODE_MAP.md')
            .writeAsString('- `lib/app.dart`');
        await File('${tempDir.path}/docs/QUEUE.md').writeAsString(
          '- [x] **Zadanie #001** (`lib/app.dart`): App entry.\n',
        );
      });

      addTearDown(() async {
        await tester.runAsync(() async {
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        });
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: DiamondMaster562CertificationPanel(
                projectRoot: tempDir.path,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('DIAMOND MASTER v2.0 — Pakiet Certyfikacji (#001–#562)'),
        findsOneWidget,
      );

      await tester.tap(find.text('flutter analyze'));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.tap(find.text('flutter analyze'));
      await tester.pump(const Duration(milliseconds: 250));

      final container = ProviderScope.containerOf(
        tester.element(find.byType(DiamondMaster562CertificationPanel)),
      );
      await tester.runAsync(
        () => container
            .read(diamondMaster562CertificationProvider.notifier)
            .runAudit(projectRoot: tempDir.path),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Podsumowanie Paczek (#001–#562)'), findsOneWidget);
      expect(find.text('Rejestr Zadań (#001–#562)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }

    testWidgets('renders cleanly at 390x844 (mobile)', (tester) async {
      await pumpPanelAtSize(tester, const Size(390, 844));
    });

    testWidgets('renders cleanly at 1024x768 (tablet)', (tester) async {
      await pumpPanelAtSize(tester, const Size(1024, 768));
    });

    testWidgets('renders cleanly at 1600x900 (desktop)', (tester) async {
      await pumpPanelAtSize(tester, const Size(1600, 900));
    });
  });
}
