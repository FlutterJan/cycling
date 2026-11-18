import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/diagnostics/obsidian_sovereign_662_certification_suite.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';

void main() {
  group('ObsidianSovereign662CertificationSuite', () {
    test('maps task numbers #001-#662 to all 11 packages', () {
      expect(
        ObsidianSovereignPackageId.fromTaskNumber(1),
        ObsidianSovereignPackageId.foundation,
      );
      expect(
        ObsidianSovereignPackageId.fromTaskNumber(162),
        ObsidianSovereignPackageId.foundation,
      );
      expect(
        ObsidianSovereignPackageId.fromTaskNumber(163),
        ObsidianSovereignPackageId.package1,
      );
      expect(
        ObsidianSovereignPackageId.fromTaskNumber(213),
        ObsidianSovereignPackageId.package2,
      );
      expect(
        ObsidianSovereignPackageId.fromTaskNumber(263),
        ObsidianSovereignPackageId.package3,
      );
      expect(
        ObsidianSovereignPackageId.fromTaskNumber(313),
        ObsidianSovereignPackageId.package4,
      );
      expect(
        ObsidianSovereignPackageId.fromTaskNumber(363),
        ObsidianSovereignPackageId.package5,
      );
      expect(
        ObsidianSovereignPackageId.fromTaskNumber(413),
        ObsidianSovereignPackageId.package6,
      );
      expect(
        ObsidianSovereignPackageId.fromTaskNumber(463),
        ObsidianSovereignPackageId.package7A,
      );
      expect(
        ObsidianSovereignPackageId.fromTaskNumber(513),
        ObsidianSovereignPackageId.package7B,
      );
      expect(
        ObsidianSovereignPackageId.fromTaskNumber(563),
        ObsidianSovereignPackageId.package8,
      );
      expect(
        ObsidianSovereignPackageId.fromTaskNumber(613),
        ObsidianSovereignPackageId.package9,
      );
      expect(
        ObsidianSovereignPackageId.fromTaskNumber(662),
        ObsidianSovereignPackageId.package9,
      );
    });

    test('verifies synthetic project and exports JSON & Markdown', () async {
      final tempDir = await Directory.systemTemp.createTemp('os_662_test_');
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
        await Directory('${tempDir.path}/lib/core/services')
            .create(recursive: true);
        await Directory('${tempDir.path}/lib/engine/simulation')
            .create(recursive: true);
        await Directory('${tempDir.path}/lib/models/race')
            .create(recursive: true);
        await Directory('${tempDir.path}/lib/models/career')
            .create(recursive: true);
        await Directory('${tempDir.path}/lib/models/paracycling')
            .create(recursive: true);

        await File('${tempDir.path}/lib/core/router/app_router.dart')
            .writeAsString('''
class AppRoutes {
  static const paracyclingWorldCup = '/career/paracycling';
  static const clubMuseum = '/career/club-museum';
  static const talentCombine = '/career/talent-combine';
  static const goldenEraRetro = '/career/golden-era';
  static const cyclingEsports = '/career/esports';
}
''');
        await File('${tempDir.path}/lib/engine/engine_integration_bridge.dart')
            .writeAsString('class EngineIntegrationBridge {}');
        await File(
          '${tempDir.path}/lib/core/diagnostics/zero_warnings_662_lint_gate.dart',
        ).writeAsString('class ZeroWarnings662LintGate {}');
        await File(
          '${tempDir.path}/lib/core/diagnostics/performance_and_memory_662_profiler.dart',
        ).writeAsString('class PerformanceAndMemory662Profiler {}');
        await File(
          '${tempDir.path}/lib/core/diagnostics/save_compatibility_v9_migrator.dart',
        ).writeAsString('class SaveCompatibilityV9Migrator {}');
        await File(
          '${tempDir.path}/lib/core/diagnostics/platinum_apex_612_certification_suite.dart',
        ).writeAsString('class PlatinumApex612CertificationSuite {}');
        await File(
          '${tempDir.path}/lib/core/l10n/app_localizations_pl_en.dart',
        ).writeAsString('class BilingualCyclingDictionary {}');
        await File(
          '${tempDir.path}/lib/core/config/app_feature_flags_and_presets.dart',
        ).writeAsString('class AppFeatureFlagsAndPresets {}');
        await File(
          '${tempDir.path}/lib/models/race/global_exotic_tours_expansion_model.dart',
        ).writeAsString('class GlobalExoticToursExpansionModel {}');
        await File(
          '${tempDir.path}/lib/models/career/rider_relationship_chemistry_web_model.dart',
        ).writeAsString('class RiderRelationshipChemistryWebModel {}');
        await File(
          '${tempDir.path}/lib/engine/simulation/what_if_tactical_sandbox_simulator.dart',
        ).writeAsString('class WhatIfTacticalSandboxSimulator {}');
        await File(
          '${tempDir.path}/lib/models/paracycling/uci_paracycling_tandem_handbike_model.dart',
        ).writeAsString('class UciParacyclingTandemHandbikeModel {}');
        await File(
          '${tempDir.path}/lib/core/services/adaptive_dynamic_music_score_engine.dart',
        ).writeAsString('class AdaptiveDynamicMusicScoreEngine {}');
        await File('${tempDir.path}/docs/COMPLETE_GAME_MANUAL_662.md')
            .writeAsString('# COMPLETE_GAME_MANUAL_662.md');
        await File(
          '${tempDir.path}/lib/core/diagnostics/full_state_serialization_fuzz_tester.dart',
        ).writeAsString('class FullStateSerializationFuzzTester {}');

        await File('${tempDir.path}/docs/CODE_MAP.md').writeAsString('''
- `lib/core/router/app_router.dart`
- `lib/engine/engine_integration_bridge.dart`
''');

        await File('${tempDir.path}/docs/QUEUE.md').writeAsString('''
- [x] **Zadanie #001** (`lib/core/router/app_router.dart`): Router.
- [x] **Zadanie #662** (`lib/engine/engine_integration_bridge.dart`): Bridge.
''');

        const suite = ObsidianSovereign662CertificationSuite();
        final report = await suite.runCertification(
          projectRoot: tempDir.path,
          runFlutterAnalyze: false,
          runFlutterTest: false,
        );

        expect(report.totalTasksChecked, 2);
        expect(report.passedTasksCount, 2);
        expect(report.codeMapResult.passed, isTrue);
        expect(report.allPillarsPassed, isTrue);
        expect(report.verdict, ObsidianSovereignVerdict.conditionalPass);
        expect(report.toPrettyJson(), contains('OBSIDIAN SOVEREIGN v4.0'));
        expect(
          report.toMarkdownCertificate(),
          contains('# Certyfikat OBSIDIAN SOVEREIGN v4.0'),
        );
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('verifies real repository pillars and queue entries', () async {
      const suite = ObsidianSovereign662CertificationSuite();
      final report = await suite.runCertification(
        runFlutterAnalyze: false,
        runFlutterTest: false,
      );

      expect(report.totalTasksChecked, greaterThanOrEqualTo(580));
      expect(report.codeMapResult.exists, isTrue);
      expect(report.allPillarsPassed, isTrue);
    });
  });

  group('ObsidianSovereign662CertificationPanel responsive UI', () {
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
        tempDir = await Directory.systemTemp.createTemp('os_662_ui_');
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
              body: ObsidianSovereign662CertificationPanel(
                projectRoot: tempDir.path,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('OBSIDIAN SOVEREIGN v4.0 — Pakiet Certyfikacji (#001–#662)'),
        findsOneWidget,
      );

      await tester.tap(find.text('flutter analyze'));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.tap(find.text('flutter analyze'));
      await tester.pump(const Duration(milliseconds: 250));

      final container = ProviderScope.containerOf(
        tester.element(find.byType(ObsidianSovereign662CertificationPanel)),
      );
      await tester.runAsync(
        () => container
            .read(obsidianSovereign662CertificationProvider.notifier)
            .runAudit(projectRoot: tempDir.path),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Podsumowanie Paczek (#001–#662)'), findsOneWidget);
      expect(find.text('Rejestr Zadań (#001–#662)'), findsOneWidget);
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
