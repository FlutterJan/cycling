// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pro_peloton_manager/core/diagnostics/save_compatibility_v9_migrator.dart';
import 'package:pro_peloton_manager/core/theme/app_colors.dart';

void main() {
  group('SaveCompatibilityV9Migrator', () {
    test('zwraca błąd dla pustego lub nieprawidłowego JSON-a', () {
      final emptyReport = SaveCompatibilityV9Migrator.migrateRawJson(
        saveId: 'slot_empty_v9',
        rawJson: '   ',
      );
      expect(emptyReport.status, V9MigrationStatus.failed);
      expect(emptyReport.errorMessage, 'EMPTY_JSON_PAYLOAD');

      final arrayReport = SaveCompatibilityV9Migrator.migrateRawJson(
        saveId: 'slot_array_v9',
        rawJson: '[1, 2, 3]',
      );
      expect(arrayReport.status, V9MigrationStatus.failed);
      expect(arrayReport.errorMessage, 'INVALID_JSON_ROOT');
    });

    test('migruje zapis v4 przez łańcuch v8 -> v9 z zachowaniem trybów opcjonalnych jako null', () {
      final legacyPayload = <String, dynamic>{
        'saveId': 'career_v4_orlen',
        'teamId': 'team_polonia_orlen',
        'teamName': 'Polonia Orlen Pro',
        'managerName': 'Adam Nowak',
        'seasonYear': 2027,
      };

      final report = SaveCompatibilityV9Migrator.migratePayloadMap(
        saveId: 'career_v4_orlen',
        payload: legacyPayload,
        sourceSchemaVersion: 4,
        initializeOptionalModesIfMissing: false,
      );

      expect(report.status.isSuccess, isTrue);
      expect(report.targetSchemaVersion, 9);
      expect(report.v8PreMigrationReport, isNotNull);
      expect(report.v8PreMigrationReport!.status.isSuccess, isTrue);
      expect(report.migratedPayload!['schemaVersion'], 9);
      expect(report.migratedEnvelope, isNotNull);
      expect(report.migratedEnvelope!.schemaVersion, 9);
      expect(report.checksumAfter, isNotEmpty);

      // Tryby opcjonalne pozostają null
      expect(report.hydratedParacyclingWorld, isNull);
      expect(report.hydratedCombineEdition, isNull);

      // Struktury bazowe Paczki #9 są zainicjalizowane i zhydratowane
      expect(report.hydratedExoticTours, isNotNull);
      expect(report.hydratedExoticTours!.tours.length, 4);
      expect(report.hydratedSponsorMarket, isNotNull);
      expect(report.hydratedSponsorMarket!.availableOffers, isNotEmpty);
      expect(report.hydratedChemistryWeb, isNotNull);
      expect(report.hydratedEquipmentDecals, isNotNull);
      expect(report.hydratedAiDsStyles, isNotNull);
      expect(report.hydratedAiDsStyles!.aiProfiles, isNotEmpty);
      expect(report.hydratedAnalyticsConfig, isNotNull);
      expect(report.sectionSummaries.length, Package9MigrationSection.values.length);
    });

    test('inicjalizuje opcjonalne tryby Paczki #9 gdy initializeOptionalModesIfMissing = true i zachowuje idempotencję', () {
      final report = SaveCompatibilityV9Migrator.migratePayloadMap(
        saveId: 'career_full_p9',
        payload: <String, dynamic>{
          'saveId': 'career_full_p9',
          'teamId': 'team_polonia_orlen',
          'teamName': 'Polonia Orlen Pro',
          'seasonYear': 2028,
        },
        sourceSchemaVersion: 8,
        initializeOptionalModesIfMissing: true,
      );

      expect(report.status, V9MigrationStatus.migrated);
      expect(report.v8PreMigrationReport, isNull);
      expect(report.hydratedParacyclingWorld, isNotNull);
      expect(report.hydratedParacyclingWorld!.athletes, isNotEmpty);
      expect(report.hydratedCombineEdition, isNotNull);
      expect(report.hydratedCombineEdition!.candidates, isNotEmpty);

      // Idempotencja po ponownej migracji wygenerowanej koperty
      final rawEnvelopeJson = jsonEncode(report.migratedEnvelope!.toJson());
      final secondPass = SaveCompatibilityV9Migrator.migrateRawJson(
        saveId: 'career_full_p9',
        rawJson: rawEnvelopeJson,
      );
      expect(secondPass.status, V9MigrationStatus.alreadyCompatible);
      expect(secondPass.totalFixesCount, 0);
    });

    test('naprawia uszkodzone i przekraczające zakres pola Paczki #9', () {
      final corruptedPayload = <String, dynamic>{
        'saveId': 'career_corrupt_v9',
        'teamId': 'team_test',
        'teamName': 'Test Team',
        'seasonYear': 2026,
        'globalExoticToursExpansion': <String, dynamic>{
          'seasonYear': 2026,
          'globalExpansionReputation': 185.0,
          'nonEuropeanFanBase': -500,
        },
        'globalSponsorMarket': 'invalid_string_instead_of_map',
        'riderRelationshipChemistry': <String, dynamic>{
          'teamId': '',
          'seasonYear': 2026,
        },
        'teamBondingAndMediation': 12345,
        'uciParacyclingWorld': 'broken_para',
        'equipmentCustomDecalsAndSerials': <String, dynamic>{
          'frames': const <Map<String, dynamic>>[],
          'nextSequenceCounter': 0,
          'availableBudgetEur': -25000.0,
        },
        'aiDirectorSportifStyles': 'broken_ai_ds',
        'trainingMicrocycles': <String, dynamic>{
          'microcycles': ['not_a_map'],
        },
        'youthTalentCombine': <String, dynamic>{
          'activeEdition': 'broken_edition',
          'history': 'broken_history',
        },
        'deepCareerAnalyticsBi': <String, dynamic>{
          'exportConfig': 'broken_config',
          'seasonSnapshots': ['bad_snapshot'],
        },
      };

      final report = SaveCompatibilityV9Migrator.migratePayloadMap(
        saveId: 'career_corrupt_v9',
        payload: corruptedPayload,
        sourceSchemaVersion: 8,
      );

      expect(report.status, V9MigrationStatus.repairedAndMigrated);
      expect(report.repairedFixesCount, greaterThan(0));
      expect(report.hydratedExoticTours!.globalExpansionReputation, 100.0);
      expect(report.hydratedExoticTours!.nonEuropeanFanBase, 0);
      expect(report.hydratedSponsorMarket, isNotNull);
      expect(report.hydratedChemistryWeb!.teamId, 'team_test');
      expect(report.hydratedEquipmentDecals!.nextSequenceCounter, 1);
      expect(report.hydratedEquipmentDecals!.availableBudgetEur, 0.0);
      expect(report.hydratedParacyclingWorld, isNotNull);
      expect(report.hydratedCombineEdition, isNull);
    });

    testWidgets('SaveCompatibilityV9MigratorPanel działa responsywnie dla 390x844, 1024x768 i 1600x900', (tester) async {
      for (final size in const [
        Size(390, 844),
        Size(1024, 768),
        Size(1600, 900),
      ]) {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                backgroundColor: AppColors.background,
                body: SingleChildScrollView(
                  padding: EdgeInsets.all(12),
                  child: SaveCompatibilityV9MigratorPanel(
                    saveId: 'ui_test_slot_v9',
                    sampleSourceSchemaVersion: 8,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Migrator Zapisów v9 (Paczka #9)'), findsOneWidget);
        expect(find.text('Uruchom Migrację v9'), findsOneWidget);

        await tester.tap(find.text('Uruchom Migrację v9'));
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          find.textContaining('Zmigrowano zapis "ui_test_slot_v9"'),
          findsOneWidget,
        );
        expect(
          find.text('Globalna Ekspansja UCI (Afryka/Azja/Bliski Wschód)'),
          findsOneWidget,
        );
      }
      await tester.binding.setSurfaceSize(null);
    });
  });
}
