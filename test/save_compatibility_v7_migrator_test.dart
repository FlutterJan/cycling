import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/diagnostics/save_compatibility_v7_migrator.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';

void main() {
  group('SaveCompatibilityV7Migrator', () {
    test('fails gracefully on empty or invalid JSON root', () {
      final emptyReport = SaveCompatibilityV7Migrator.migrateRawJson(
        saveId: 'empty_slot',
        rawJson: '   ',
      );
      expect(emptyReport.status, V7MigrationStatus.failed);
      expect(emptyReport.errorMessage, 'EMPTY_JSON_PAYLOAD');

      final arrayReport = SaveCompatibilityV7Migrator.migrateRawJson(
        saveId: 'array_slot',
        rawJson: '[1, 2, 3]',
      );
      expect(arrayReport.status, V7MigrationStatus.failed);
      expect(arrayReport.errorMessage, 'INVALID_JSON_ROOT');
    });

    test('migrates v4 payload to v7 with default Paczka #6 & #7 sections', () {
      final report = SaveCompatibilityV7Migrator.migratePayloadMap(
        saveId: 'slot_v4_to_v7',
        sourceSchemaVersion: 4,
        payload: {
          'saveId': 'slot_v4_to_v7',
          'teamId': 'team_polonia',
          'teamName': 'Polonia Pro Cycling',
          'managerName': 'Jan Kowalski',
          'seasonYear': 2026,
        },
      );

      expect(report.status, V7MigrationStatus.migrated);
      expect(report.sourceSchemaVersion, 4);
      expect(report.targetSchemaVersion, 7);
      expect(report.migratedEnvelope?.schemaVersion, 7);
      expect(report.sectionSummaries.length, 9);

      expect(report.hydratedEloProfile?.currentElo, 1200);
      expect(report.hydratedEloProfile?.displayName, 'Jan Kowalski');
      expect(report.hydratedMtbXcoConfig?.totalWeightKg, 10.2);
      expect(report.hydratedUciRulebook?.activeRulebook.seasonYear, 2026);
      expect(report.hydratedTransferRumorMill?.journalists, isNotEmpty);
      expect(report.hydratedSatelliteAcademies?.nodes.length, 4);
      expect(report.hydratedManagerSkillTree?.managerLevel, 1);

      // Tryby opcjonalne pozostają null bez flagi initializeOptionalModesIfMissing
      expect(report.hydratedInHouseBrand, isNull);
      expect(report.hydratedOrganizerEmpire, isNull);
      expect(report.hydratedUltraBikepackingRace, isNull);
    });

    test('initializes optional modes when initializeOptionalModesIfMissing is true', () {
      final report = SaveCompatibilityV7Migrator.migratePayloadMap(
        saveId: 'slot_opt_v7',
        sourceSchemaVersion: 5,
        initializeOptionalModesIfMissing: true,
        payload: {
          'saveId': 'slot_opt_v7',
          'teamId': 'team_vista',
          'teamName': 'Vista Cycling',
          'seasonYear': 2027,
        },
      );

      expect(report.status, V7MigrationStatus.migrated);
      expect(report.hydratedInHouseBrand, isNotNull);
      expect(report.hydratedInHouseBrand?.brandName, 'Vista Cycling Cycles');
      expect(report.hydratedOrganizerEmpire, isNotNull);
      expect(report.hydratedOrganizerEmpire?.managedRaces, isNotEmpty);
      expect(report.hydratedUltraBikepackingRace, isNotNull);
      expect(report.hydratedUltraBikepackingRace?.totalDistanceKm, 4000.0);
    });

    test('is idempotent on already-compatible v7 envelope', () {
      final first = SaveCompatibilityV7Migrator.migratePayloadMap(
        saveId: 'slot_idempotent',
        sourceSchemaVersion: 4,
        initializeOptionalModesIfMissing: true,
        payload: {
          'saveId': 'slot_idempotent',
          'teamId': 'team_alpha',
          'teamName': 'Alpha Pro',
          'seasonYear': 2026,
        },
      );

      final rawV7 = jsonEncode(first.migratedEnvelope!.toJson());
      final second = SaveCompatibilityV7Migrator.migrateRawJson(
        saveId: 'slot_idempotent',
        rawJson: rawV7,
      );

      expect(second.status, V7MigrationStatus.alreadyCompatible);
      expect(second.sourceSchemaVersion, 7);
      expect(second.actions, isEmpty);
      expect(second.checksumBefore, second.checksumAfter);
    });

    test('repairs legacy alias keys and out-of-range MTB values', () {
      final report = SaveCompatibilityV7Migrator.migratePayloadMap(
        saveId: 'slot_repair',
        sourceSchemaVersion: 6,
        payload: {
          'saveId': 'slot_repair',
          'teamId': 'team_repair',
          'teamName': 'Repair Team',
          'seasonYear': 2026,
          'eloProfile': {
            'playerId': '',
            'displayName': '',
            'currentElo': 40,
          },
          'mtbSetup': {
            'bikeId': 'custom_mtb',
            'modelName': 'Custom XC',
            'totalWeightKg': 4.2,
            'chainringTeeth': 54,
          },
          'skillTree': {
            'managerLevel': 3,
            'availableSkillPoints': 4,
          },
        },
      );

      expect(report.status, V7MigrationStatus.repairedAndMigrated);
      expect(report.repairedFixesCount, greaterThan(0));
      expect(report.hydratedEloProfile?.currentElo, 1200);
      expect(report.hydratedMtbXcoConfig?.totalWeightKg, 7.5);
      expect(report.hydratedMtbXcoConfig?.chainringTeeth, 40);
      expect(report.hydratedManagerSkillTree?.managerLevel, 3);
      expect(report.migratedPayload?.containsKey('mtbSetup'), isFalse);
      expect(report.migratedPayload?.containsKey('skillTree'), isFalse);
    });

    test('chains v1 raw JSON through v4 migrator to v7', () {
      final rawV1 = jsonEncode({
        'saveId': 'legacy_v1',
        'teamName': 'Legacy Cycling Club',
        'currentDate': '2026-03-10T10:00:00.000Z',
        'seasonYear': 2026,
      });

      final report = SaveCompatibilityV7Migrator.migrateRawJson(
        saveId: 'legacy_v1',
        rawJson: rawV1,
      );

      expect(report.status.isSuccess, isTrue);
      expect(report.sourceSchemaVersion, 1);
      expect(report.targetSchemaVersion, 7);
      expect(report.v4PreMigrationReport, isNotNull);
      expect(report.migratedEnvelope?.schemaVersion, 7);
    });
  });

  group('SaveCompatibilityV7MigratorPanel responsive UI', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders and runs migration cleanly at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                theme: AppTheme.darkTheme,
                home: const Scaffold(
                  body: SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: SaveCompatibilityV7MigratorPanel(
                      saveId: 'ui_test_slot',
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(
            find.text('Migrator Kompatybilności Zapisów v7 (Paczki #6–#7)'),
            findsOneWidget,
          );

          await tester.tap(
            find.text('Inicjalizuj opcjonalne tryby (Marka / ASO / Ultra)'),
          );
          await tester.pump(const Duration(milliseconds: 250));

          await tester.tap(find.text('Uruchom migrację v7'));
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.text('v4 → v7'), findsOneWidget);
          expect(find.text('Tryb Organizatora ASO/RCS'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
