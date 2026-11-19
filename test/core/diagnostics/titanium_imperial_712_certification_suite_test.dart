import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/diagnostics/titanium_imperial_712_certification_suite.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';

void main() {
  group('TitaniumImperial712CertificationSuite', () {
    test('maps task numbers #001-#712 to all 12 packages', () {
      expect(
        TitaniumImperialPackageId.fromTaskNumber(1),
        TitaniumImperialPackageId.foundation,
      );
      expect(
        TitaniumImperialPackageId.fromTaskNumber(162),
        TitaniumImperialPackageId.foundation,
      );
      expect(
        TitaniumImperialPackageId.fromTaskNumber(163),
        TitaniumImperialPackageId.package1,
      );
      expect(
        TitaniumImperialPackageId.fromTaskNumber(213),
        TitaniumImperialPackageId.package2,
      );
      expect(
        TitaniumImperialPackageId.fromTaskNumber(263),
        TitaniumImperialPackageId.package3,
      );
      expect(
        TitaniumImperialPackageId.fromTaskNumber(313),
        TitaniumImperialPackageId.package4,
      );
      expect(
        TitaniumImperialPackageId.fromTaskNumber(363),
        TitaniumImperialPackageId.package5,
      );
      expect(
        TitaniumImperialPackageId.fromTaskNumber(413),
        TitaniumImperialPackageId.package6,
      );
      expect(
        TitaniumImperialPackageId.fromTaskNumber(463),
        TitaniumImperialPackageId.package7A,
      );
      expect(
        TitaniumImperialPackageId.fromTaskNumber(513),
        TitaniumImperialPackageId.package7B,
      );
      expect(
        TitaniumImperialPackageId.fromTaskNumber(563),
        TitaniumImperialPackageId.package8,
      );
      expect(
        TitaniumImperialPackageId.fromTaskNumber(613),
        TitaniumImperialPackageId.package9,
      );
      expect(
        TitaniumImperialPackageId.fromTaskNumber(663),
        TitaniumImperialPackageId.package10,
      );
      expect(
        TitaniumImperialPackageId.fromTaskNumber(712),
        TitaniumImperialPackageId.package10,
      );
    });

    test('classifies test files into unit, physics, simulation, ui, and serialization', () {
      expect(
        TitaniumImperial712CertificationSuite.classifyTestFile(
          'test/americas_oceania_altitude_heat_test.dart',
        ),
        TitaniumImperialTestCategory.physics,
      );
      expect(
        TitaniumImperial712CertificationSuite.classifyTestFile(
          'test/tv_director_mode_and_brake_fade_test.dart',
        ),
        TitaniumImperialTestCategory.physics,
      );
      expect(
        TitaniumImperial712CertificationSuite.classifyTestFile(
          'test/engine/peloton_boids_simulation_test.dart',
        ),
        TitaniumImperialTestCategory.simulation,
      );
      expect(
        TitaniumImperial712CertificationSuite.classifyTestFile(
          'test/ui/dashboard_screen_test.dart',
        ),
        TitaniumImperialTestCategory.ui,
      );
      expect(
        TitaniumImperial712CertificationSuite.classifyTestFile(
          'test/core/diagnostics/save_compatibility_v10_migrator_test.dart',
        ),
        TitaniumImperialTestCategory.serialization,
      );
      expect(
        TitaniumImperial712CertificationSuite.classifyTestFile(
          'test/models/rider_contract_test.dart',
        ),
        TitaniumImperialTestCategory.unit,
      );
    });

    test('verifies synthetic project, 4 platforms, 16 pillars, and exports JSON & Markdown', () async {
      final tempDir = await Directory.systemTemp.createTemp('ti_712_test_');
      try {
        await File('${tempDir.path}/pubspec.yaml').writeAsString('name: test\n');
        await Directory('${tempDir.path}/docs').create(recursive: true);
        await Directory('${tempDir.path}/windows').create(recursive: true);
        await Directory('${tempDir.path}/macos').create(recursive: true);
        await Directory('${tempDir.path}/android').create(recursive: true);
        await Directory('${tempDir.path}/ios').create(recursive: true);
        await Directory('${tempDir.path}/test/ui').create(recursive: true);
        await Directory('${tempDir.path}/lib/core/router').create(recursive: true);
        await Directory('${tempDir.path}/lib/core/diagnostics').create(recursive: true);
        await Directory('${tempDir.path}/lib/core/l10n').create(recursive: true);
        await Directory('${tempDir.path}/lib/core/config').create(recursive: true);
        await Directory('${tempDir.path}/lib/models/race').create(recursive: true);
        await Directory('${tempDir.path}/lib/models/uci').create(recursive: true);
        await Directory('${tempDir.path}/lib/models/medical').create(recursive: true);
        await Directory('${tempDir.path}/lib/models/broadcast').create(recursive: true);

        await File('${tempDir.path}/lib/core/router/app_router.dart')
            .writeAsString('''
class AppRoutes {
  static const tvBroadcastDirector = '/race/tv-director';
  static const grandTourMorningMedical = '/career/grand-tour-medical';
  static const winterWindTunnelCamp = '/career/winter-wind-tunnel-camp';
  static const contractRenewalsWarRoom = '/career/contract-renewals';
  static const clubMuseum = '/career/club-museum';
}
''');
        File('${tempDir.path}/lib/engine/engine_integration_bridge.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync('class EngineIntegrationBridge {}');
        await File('${tempDir.path}/lib/core/diagnostics/zero_warnings_712_lint_gate.dart')
            .writeAsString('class ZeroWarnings712LintGate {}');
        await File('${tempDir.path}/lib/core/diagnostics/performance_and_memory_712_profiler.dart')
            .writeAsString('class PerformanceAndMemory712Profiler {}');
        await File('${tempDir.path}/lib/core/diagnostics/save_compatibility_v10_migrator.dart')
            .writeAsString('class SaveCompatibilityV10Migrator {}');
        await File('${tempDir.path}/lib/core/diagnostics/obsidian_sovereign_662_certification_suite.dart')
            .writeAsString('class ObsidianSovereign662CertificationSuite {}');
        await File('${tempDir.path}/lib/core/l10n/app_localizations_pl_en.dart')
            .writeAsString('class BilingualCyclingDictionary {}');
        await File('${tempDir.path}/lib/core/config/app_feature_flags_and_presets.dart')
            .writeAsString('class AppFeatureFlagsAndPresets {}');
        await File('${tempDir.path}/lib/models/race/americas_and_oceania_tours_model.dart')
            .writeAsString('class AmericasAndOceaniaToursModel {}');
        await File('${tempDir.path}/lib/models/uci/technical_scrutiny_and_cas_tribunal_model.dart')
            .writeAsString('class TechnicalScrutinyAndCasTribunalModel {}');
        await File('${tempDir.path}/lib/models/medical/grand_tour_nightly_hrv_and_physio_model.dart')
            .writeAsString('class GrandTourNightlyHrvAndPhysioModel {}');
        await File('${tempDir.path}/lib/models/broadcast/tv_director_live_production_model.dart')
            .writeAsString('class TvDirectorLiveProductionModel {}');
        await File('${tempDir.path}/lib/core/config/platform_adaptive_graphics_profiler.dart')
            .writeAsString('class PlatformAdaptiveGraphicsProfiler {}');
        await File('${tempDir.path}/lib/core/diagnostics/full_navigation_routes_verifier.dart')
            .writeAsString('class FullNavigationRoutesVerifier {}');
        await File('${tempDir.path}/docs/COMPLETE_GAME_MANUAL_712.md')
            .writeAsString('# Pro Peloton Manager');
        await File('${tempDir.path}/lib/core/diagnostics/full_state_serialization_fuzz_tester.dart')
            .writeAsString('class FullStateSerializationFuzzTester {}');

        await File('${tempDir.path}/test/ui/sample_ui_test.dart')
            .writeAsString('void main() {}');
        await File('${tempDir.path}/test/physics_aero_test.dart')
            .writeAsString('void main() {}');
        await File('${tempDir.path}/test/save_serialization_test.dart')
            .writeAsString('void main() {}');

        await File('${tempDir.path}/docs/CODE_MAP.md').writeAsString('''
- `lib/core/router/app_router.dart`
- `lib/engine/engine_integration_bridge.dart`
''');

        await File('${tempDir.path}/docs/QUEUE.md').writeAsString('''
- [x] **Zadanie #001** (`lib/core/router/app_router.dart`): Router.
- [x] **Zadanie #712** (`lib/engine/engine_integration_bridge.dart`): Bridge.
''');

        const suite = TitaniumImperial712CertificationSuite();
        final report = await suite.runCertification(
          projectRoot: tempDir.path,
          runFlutterAnalyze: false,
          runFlutterTest: false,
        );

        expect(report.totalTasksChecked, 2);
        expect(report.passedTasksCount, 2);
        expect(report.allPillarsPassed, isTrue);
        expect(report.allPlatformsReady, isTrue);
        expect(report.readyPlatformsCount, 4);
        expect(report.totalTestFilesDiscovered, 3);
        expect(report.verdict, TitaniumImperialVerdict.conditionalPass);
        expect(report.toPrettyJson(), contains('TITANIUM IMPERIAL v5.0'));
        expect(report.toMarkdownCertificate(), contains('# Certyfikat TITANIUM IMPERIAL v5.0 (#001–#712)'));
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    testWidgets(
      'TitaniumImperial712CertificationPanel renders without overflow across 390x844, 1024x768, 1600x900',
      (tester) async {
        final viewports = [
          const Size(390, 844),
          const Size(1024, 768),
          const Size(1600, 900),
        ];

        for (final size in viewports) {
          await tester.binding.setSurfaceSize(size);
          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                theme: AppTheme.darkTheme,
                home: const Scaffold(
                  body: TitaniumImperial712CertificationPanel(),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.text('TITANIUM IMPERIAL v5.0'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }

        await tester.binding.setSurfaceSize(null);
      },
    );
  });
}
