// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pro_peloton_manager/core/diagnostics/save_compatibility_v8_migrator.dart';
import 'package:pro_peloton_manager/core/theme/app_colors.dart';

void main() {
  group('SaveCompatibilityV8Migrator', () {
    test('zwraca błąd dla pustego lub nieprawidłowego JSON-a', () {
      final emptyReport = SaveCompatibilityV8Migrator.migrateRawJson(
        saveId: 'slot_empty',
        rawJson: '   ',
      );
      expect(emptyReport.status, V8MigrationStatus.failed);
      expect(emptyReport.errorMessage, 'EMPTY_JSON_PAYLOAD');

      final arrayReport = SaveCompatibilityV8Migrator.migrateRawJson(
        saveId: 'slot_array',
        rawJson: '[1, 2, 3]',
      );
      expect(arrayReport.status, V8MigrationStatus.failed);
      expect(arrayReport.errorMessage, 'INVALID_JSON_ROOT');
    });

    test('migruje zapis v4 przez łańcuch v7 -> v8 z zachowaniem trybów opcjonalnych jako null', () {
      final legacyPayload = <String, dynamic>{
        'saveId': 'career_v4_polonia',
        'teamId': 'team_polonia_wt',
        'teamName': 'Polonia Pro Cycling',
        'managerName': 'Jan Kowalski',
        'seasonYear': 2027,
      };

      final report = SaveCompatibilityV8Migrator.migratePayloadMap(
        saveId: 'career_v4_polonia',
        payload: legacyPayload,
        sourceSchemaVersion: 4,
        initializeOptionalModesIfMissing: false,
      );

      expect(report.status.isSuccess, isTrue);
      expect(report.targetSchemaVersion, 8);
      expect(report.v7PreMigrationReport, isNotNull);
      expect(report.v7PreMigrationReport!.status.isSuccess, isTrue);
      expect(report.migratedPayload!['schemaVersion'], 8);
      expect(report.migratedEnvelope, isNotNull);
      expect(report.migratedEnvelope!.schemaVersion, 8);
      expect(report.checksumAfter, isNotEmpty);

      // Tryby opcjonalne pozostają null
      expect(report.hydratedRetroSeason, isNull);
      expect(report.hydratedEsportsWorld, isNull);
      expect(report.hydratedNationalCampaign, isNull);
      expect(report.hydratedTransferDeadlineDay, isNull);

      // Struktury bazowe Paczki #8 są zainicjalizowane i zhydratowane
      expect(report.hydratedEsgFleet, isNotNull);
      expect(report.hydratedEsgFleet!.vehicles, isNotEmpty);
      expect(report.hydratedFanClubMembership, isNotNull);
      expect(report.hydratedHallOfFameArchive, isNotNull);
      expect(report.hydratedFeatureFlags, isNotNull);
      expect(report.sectionSummaries.length, Package8MigrationSection.values.length);
    });

    test('inicjalizuje opcjonalne tryby Paczki #8 gdy initializeOptionalModesIfMissing = true', () {
      final report = SaveCompatibilityV8Migrator.migratePayloadMap(
        saveId: 'career_full_p8',
        payload: <String, dynamic>{
          'saveId': 'career_full_p8',
          'teamId': 'team_ccc',
          'teamName': 'CCC Heritage',
          'seasonYear': 2028,
        },
        sourceSchemaVersion: 7,
        initializeOptionalModesIfMissing: true,
      );

      expect(report.status, V8MigrationStatus.migrated);
      expect(report.v7PreMigrationReport, isNull);
      expect(report.hydratedRetroSeason, isNotNull);
      expect(report.hydratedRetroSeason!.seasonYear, 1976);
      expect(report.hydratedEsportsWorld, isNotNull);
      expect(report.hydratedEsportsWorld!.riders, isNotEmpty);
      expect(report.hydratedNationalCampaign, isNotNull);
      expect(report.hydratedNationalCampaign!.seasonYear, 2028);
      expect(report.hydratedTransferDeadlineDay, isNotNull);
      expect(report.hydratedTransferDeadlineDay!.remainingWindowMinutes, 720);

      // Idempotencja po ponownej migracji wygenerowanej koperty
      final rawEnvelopeJson = jsonEncode(report.migratedEnvelope!.toJson());
      final secondPass = SaveCompatibilityV8Migrator.migrateRawJson(
        saveId: 'career_full_p8',
        rawJson: rawEnvelopeJson,
      );
      expect(secondPass.status, V8MigrationStatus.alreadyCompatible);
      expect(secondPass.totalFixesCount, 0);
    });

    test('naprawia uszkodzone i przekraczające zakres pola Paczki #8', () {
      final corruptedPayload = <String, dynamic>{
        'saveId': 'career_corrupt',
        'teamId': 'team_test',
        'teamName': 'Test Team',
        'seasonYear': 2026,
        'goldenEraRetroSeason': <String, dynamic>{
          'seasonYear': 1976,
          'activeWetnessFactor': 2.5,
          'historicalAuthenticityScore': 150.0,
        },
        'uciCyclingEsports': <String, dynamic>{
          'uciDualRecordingMaxDeltaPercent': 50.0,
          'prizePoolEur': -1000.0,
        },
        'teamEsgSustainability': <String, dynamic>{
          'teamId': 'team_test',
          'seasonYear': 2026,
          'annualCo2BudgetTons': -50.0,
          'carbonCreditPricePerTonEur': 0.0,
        },
        'riderPersonalLifeEvents': 'invalid_string_instead_of_map',
        'nationalFederationCampaign': <String, dynamic>{
          'seasonYear': 2026,
          'federationTrust': 140.0,
          'mediaPressure': -20.0,
        },
        'transferDeadlineDay': <String, dynamic>{
          'config': <String, dynamic>{},
          'remainingWindowMinutes': -30,
          'simulationSpeedMultiplier': 99,
        },
        'teamMerchandiseAndFanClub': 12345,
        'riderNicknamesRegistry': <String, dynamic>{
          'records': ['not_a_map'],
        },
        'hallOfFameAndDynasty': <String, dynamic>{
          'entries': 'bad',
          'activeGenerationNumber': 0,
        },
        'gameplayRealismConfig': 'broken',
      };

      final report = SaveCompatibilityV8Migrator.migratePayloadMap(
        saveId: 'career_corrupt',
        payload: corruptedPayload,
        sourceSchemaVersion: 7,
      );

      expect(report.status, V8MigrationStatus.repairedAndMigrated);
      expect(report.repairedFixesCount, greaterThanOrEqualTo(6));
      expect(report.hydratedRetroSeason!.activeWetnessFactor, 1.0);
      expect(report.hydratedRetroSeason!.historicalAuthenticityScore, 100.0);
      expect(report.hydratedEsportsWorld!.uciDualRecordingMaxDeltaPercent, 10.0);
      expect(report.hydratedEsportsWorld!.prizePoolEur, 0.0);
      expect(report.hydratedEsgFleet!.annualCo2BudgetTons, 120.0);
      expect(report.hydratedNationalCampaign!.federationTrust, 100.0);
      expect(report.hydratedNationalCampaign!.mediaPressure, 0.0);
      expect(report.hydratedTransferDeadlineDay!.remainingWindowMinutes, 0);
      expect(report.hydratedTransferDeadlineDay!.simulationSpeedMultiplier, inInclusiveRange(1, 10));
      expect(report.hydratedFeatureFlags, isNotNull);
    });
  });

  group('SaveCompatibilityV8MigratorPanel UI', () {
    Future<void> pumpPanelAtSize(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              backgroundColor: AppColors.background,
              body: SingleChildScrollView(
                padding: EdgeInsets.all(12),
                child: SaveCompatibilityV8MigratorPanel(
                  saveId: 'ui_test_slot',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renderuje się poprawnie bez overflow w 390x844, 1024x768 i 1600x900', (tester) async {
      for (final size in const [
        Size(390, 844),
        Size(1024, 768),
        Size(1600, 900),
      ]) {
        await pumpPanelAtSize(tester, size);
        expect(find.textContaining('Migrator Kompatybilności Zapisów v8'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('uruchamia migrację v8 po kliknięciu przycisku i filtruje sekcje', (tester) async {
      await pumpPanelAtSize(tester, const Size(1280, 800));

      await tester.tap(find.textContaining('Inicjalizuj opcjonalne tryby'));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Uruchom migrację v8'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('ZMIGROWANY DO V8'), findsOneWidget);
      expect(find.text('Ekonomia ESG i Zielona Flota'), findsOneWidget);

      await tester.tap(find.text('Ekonomia ESG i Zielona Flota'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Dziennik: Ekonomia ESG i Zielona Flota'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
