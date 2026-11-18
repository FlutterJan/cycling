import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/diagnostics/platinum_apex_612_certification_suite.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';

void main() {
  group('PlatinumApex612CertificationSuite', () {
    test('maps task numbers #001-#612 to all 10 packages', () {
      expect(
        PlatinumApexPackageId.fromTaskNumber(1),
        PlatinumApexPackageId.foundation,
      );
      expect(
        PlatinumApexPackageId.fromTaskNumber(162),
        PlatinumApexPackageId.foundation,
      );
      expect(
        PlatinumApexPackageId.fromTaskNumber(163),
        PlatinumApexPackageId.package1,
      );
      expect(
        PlatinumApexPackageId.fromTaskNumber(213),
        PlatinumApexPackageId.package2,
      );
      expect(
        PlatinumApexPackageId.fromTaskNumber(263),
        PlatinumApexPackageId.package3,
      );
      expect(
        PlatinumApexPackageId.fromTaskNumber(313),
        PlatinumApexPackageId.package4,
      );
      expect(
        PlatinumApexPackageId.fromTaskNumber(363),
        PlatinumApexPackageId.package5,
      );
      expect(
        PlatinumApexPackageId.fromTaskNumber(413),
        PlatinumApexPackageId.package6,
      );
      expect(
        PlatinumApexPackageId.fromTaskNumber(463),
        PlatinumApexPackageId.package7A,
      );
      expect(
        PlatinumApexPackageId.fromTaskNumber(513),
        PlatinumApexPackageId.package7B,
      );
      expect(
        PlatinumApexPackageId.fromTaskNumber(563),
        PlatinumApexPackageId.package8,
      );
      expect(
        PlatinumApexPackageId.fromTaskNumber(612),
        PlatinumApexPackageId.package8,
      );
    });

    test('verifies synthetic project and exports JSON & Markdown', () async {
      final tempDir = await Directory.systemTemp.createTemp('pa_612_test_');
      try {
        await File('${tempDir.path}/pubspec.yaml').writeAsString('name: test\n');
        await Directory('${tempDir.path}/docs').create(recursive: true);
        await Directory('${tempDir.path}/lib/core/router')
            .create(recursive: true);
        await Directory('${tempDir.path}/lib/core/diagnostics')
            .create(recursive: true);
        await Directory('${tempDir.path}/lib/core/l10n')
            .create(recursive: true);
        await Directory('${tempDir.path}/lib/core/config')
            .create(recursive: true);
        await Directory('${tempDir.path}/lib/engine').create(recursive: true);
        await Directory('${tempDir.path}/lib/services/database')
            .create(recursive: true);
        await Directory('${tempDir.path}/lib/models/retro')
            .create(recursive: true);
        await Directory('${tempDir.path}/lib/models/esports')
            .create(recursive: true);

        await File('${tempDir.path}/lib/core/router/app_router.dart')
            .writeAsString('''
class AppRoutes {
  static const goldenEraRetro = '/career/golden-era';
  static const cyclingEsports = '/career/esports';
  static const esgGreenFleet = '/career/esg-fleet';
  static const nationalTeamHq = '/career/national-team';
  static const grandTourRouteReveal = '/career/grand-tour-reveal';
  static const hallOfFame = '/career/hall-of-fame';
}
''');
        await File('${tempDir.path}/lib/engine/engine_integration_bridge.dart')
            .writeAsString('class EngineIntegrationBridge {}');
        await File(
          '${tempDir.path}/lib/core/diagnostics/zero_warnings_612_lint_gate.dart',
        ).writeAsString('class ZeroWarnings612LintGate {}');
        await File(
          '${tempDir.path}/lib/core/diagnostics/save_compatibility_v8_migrator.dart',
        ).writeAsString('class SaveCompatibilityV8Migrator {}');
        await File(
          '${tempDir.path}/lib/core/diagnostics/diamond_master_562_certification_suite.dart',
        ).writeAsString('class DiamondMaster562CertificationSuite {}');
        await File(
          '${tempDir.path}/lib/core/l10n/app_localizations_pl_en.dart',
        ).writeAsString('class BilingualCyclingDictionary {}');
        await File(
          '${tempDir.path}/lib/core/config/app_feature_flags_and_presets.dart',
        ).writeAsString('class AppFeatureFlagsAndPresets {}');
        await File(
          '${tempDir.path}/lib/services/database/cloud_cross_save_json_sync_adapter.dart',
        ).writeAsString("const String kCrossSavePacketMagic = 'PPM_CROSS_SAVE_GZ_V1';");
        await File(
          '${tempDir.path}/lib/models/retro/golden_era_retro_season_model.dart',
        ).writeAsString('class GoldenEraRetroSeasonModel {}');
        await File(
          '${tempDir.path}/lib/models/esports/uci_cycling_esports_world_model.dart',
        ).writeAsString('class UciCyclingEsportsWorldModel {}');
        await File('${tempDir.path}/docs/COMPLETE_GAME_MANUAL_612.md')
            .writeAsString('# COMPLETE_GAME_MANUAL_612.md');
        await File(
          '${tempDir.path}/lib/core/diagnostics/full_state_serialization_fuzz_tester.dart',
        ).writeAsString('class FullStateSerializationFuzzTester {}');

        await File('${tempDir.path}/docs/CODE_MAP.md').writeAsString('''
- `lib/core/router/app_router.dart`
- `lib/engine/engine_integration_bridge.dart`
''');

        await File('${tempDir.path}/docs/QUEUE.md').writeAsString('''
- [x] **Zadanie #001** (`lib/core/router/app_router.dart`): Router.
- [x] **Zadanie #611** (`lib/engine/engine_integration_bridge.dart`): Bridge.
''');

        const suite = PlatinumApex612CertificationSuite();
        final report = await suite.runCertification(
          projectRoot: tempDir.path,
          runFlutterAnalyze: false,
          runFlutterTest: false,
        );

        expect(report.totalTasksChecked, 2);
        expect(report.passedTasksCount, 2);
        expect(report.codeMapResult.passed, isTrue);
        expect(report.allPillarsPassed, isTrue);
        expect(report.verdict, PlatinumApexVerdict.conditionalPass);
        expect(report.toPrettyJson(), contains('PLATINUM APEX v3.0'));
        expect(
          report.toMarkdownCertificate(),
          contains('# Certyfikat PLATINUM APEX v3.0'),
        );
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('verifies real repository pillars and queue entries', () async {
      const suite = PlatinumApex612CertificationSuite();
      final report = await suite.runCertification(
        runFlutterAnalyze: false,
        runFlutterTest: false,
      );

      expect(report.totalTasksChecked, greaterThanOrEqualTo(530));
      expect(report.codeMapResult.exists, isTrue);
      expect(report.allPillarsPassed, isTrue);
    });
  });

  group('PlatinumApex612CertificationPanel responsive UI', () {
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
        tempDir = await Directory.systemTemp.createTemp('pa_612_ui_');
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
              body: PlatinumApex612CertificationPanel(
                projectRoot: tempDir.path,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('PLATINUM APEX v3.0 — Pakiet Certyfikacji (#001–#612)'),
        findsOneWidget,
      );

      await tester.tap(find.text('flutter analyze'));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.tap(find.text('flutter analyze'));
      await tester.pump(const Duration(milliseconds: 250));

      final container = ProviderScope.containerOf(
        tester.element(find.byType(PlatinumApex612CertificationPanel)),
      );
      await tester.runAsync(
        () => container
            .read(platinumApex612CertificationProvider.notifier)
            .runAudit(projectRoot: tempDir.path),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Podsumowanie Paczek (#001–#612)'), findsOneWidget);
      expect(find.text('Rejestr Zadań (#001–#612)'), findsOneWidget);
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
