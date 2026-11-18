import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/diagnostics/save_compatibility_v10_migrator.dart';
import 'package:pro_peloton_manager/models/broadcast/tv_director_live_production_model.dart';
import 'package:pro_peloton_manager/models/medical/grand_tour_nightly_hrv_and_physio_model.dart';
import 'package:pro_peloton_manager/models/race/americas_and_oceania_tours_model.dart';
import 'package:pro_peloton_manager/models/uci/technical_scrutiny_and_cas_tribunal_model.dart';
import 'package:pro_peloton_manager/services/career/historical_grand_tour_winners_timeline_db.dart';

void main() {
  group('SaveCompatibilityV10Migrator', () {
    test('migrates v9 payload to v10 with required Package 10 defaults', () {
      final report = SaveCompatibilityV10Migrator.migratePayloadMap(
        saveId: 'slot_v9_to_v10',
        sourceSchemaVersion: 9,
        payload: <String, dynamic>{
          'saveId': 'slot_v9_to_v10',
          'seasonYear': 2027,
          'schemaVersion': 9,
        },
      );

      expect(report.status, V10MigrationStatus.migrated);
      expect(report.targetSchemaVersion, 10);
      expect(report.migratedPayload?['schemaVersion'], 10);
      expect(report.hydratedAmericasOceaniaTours, isNotNull);
      expect(report.hydratedAmericasOceaniaTours!.races.length, 6);
      expect(report.hydratedTechnicalScrutiny, isNotNull);
      expect(report.hydratedTripleCrownTimelineDb, isNotNull);
      expect(
        report.hydratedTripleCrownTimelineDb!
            .detectTripleCrownWinners()
            .length,
        greaterThanOrEqualTo(3),
      );
      // Optional modes remain null when initializeOptionalModesIfMissing is false
      expect(report.hydratedGrandTourHrvPhysio, isNull);
      expect(report.hydratedTvDirectorProduction, isNull);
    });

    test('chains v1 legacy raw JSON through v9 to v10 and initializes optional modes', () {
      final legacyJson = jsonEncode(<String, dynamic>{
        'saveId': 'legacy_v1_slot',
        'seasonYear': 2026,
        'playerTeamId': 'team_polonia',
        'playerTeamName': 'Polonia Pro Cycling',
      });

      final report = SaveCompatibilityV10Migrator.migrateRawJson(
        saveId: 'legacy_v1_slot',
        rawJson: legacyJson,
        initializeOptionalModesIfMissing: true,
      );

      expect(report.status.isSuccess, isTrue);
      expect(report.v9PreMigrationReport, isNotNull);
      expect(report.v9PreMigrationReport!.status.isSuccess, isTrue);
      expect(report.hydratedAmericasOceaniaTours, isNotNull);
      expect(report.hydratedTechnicalScrutiny, isNotNull);
      expect(report.hydratedGrandTourHrvPhysio, isNotNull);
      expect(
        report.hydratedGrandTourHrvPhysio!.baselines.length,
        GrandTourNightlyHrvAndPhysioModel.grandTourSquadSize,
      );
      expect(report.hydratedTvDirectorProduction, isNotNull);
      expect(report.hydratedTvDirectorProduction!.cameraFeeds.length, 12);
      expect(report.hydratedTripleCrownTimelineDb, isNotNull);
    });

    test('preserves all 5 Package 10 models losslessly and is idempotent', () {
      final americas = AmericasAndOceaniaToursModel.standard(seasonYear: 2028)
          .copyWith(americasOceaniaPrestigeScore: 77.5);
      final scrutiny = TechnicalScrutinyAndCasTribunalModel.initial(
        seasonYear: 2028,
      ).copyWith(
        teamComplianceAuditScore: 91.5,
        totalFinesPaidChf: 1500.0,
      );
      final hrv = GrandTourNightlyHrvAndPhysioModel.initializeSquad(
        tourId: 'giro_2028',
        tourName: 'Giro d\'Italia 2028',
        squadBaselines: const [
          RiderBaselineBiomarkers(
            riderId: 'r1',
            riderName: 'Jan Kowalski',
            baselineHrvRmssdMs: 82.0,
            baselineRhrBpm: 39,
            baselineCkUL: 140.0,
            baselineCortisolNmolL: 390.0,
            baselineTestosteroneNmolL: 21.0,
            baselineSleepEfficiencyPct: 92.0,
          ),
        ],
      ).copyWith(currentStageDay: 14);
      final tv = TvDirectorLiveProductionModel.createDefaultTourDeFranceStage(
        productionId: 'giro_stage_14',
        allocatedBudgetEur: 310000.0,
      );
      final timeline = HistoricalGrandTourWinnersTimelineDb.withDefaultHistory(
        careerStartYear: 2028,
      );

      final initialReport = SaveCompatibilityV10Migrator.migratePayloadMap(
        saveId: 'v10_full_slot',
        sourceSchemaVersion: 10,
        payload: <String, dynamic>{
          'saveId': 'v10_full_slot',
          'schemaVersion': 10,
          'seasonYear': 2028,
          Package10MigrationSection.americasAndOceaniaTours.jsonKey:
              americas.toJson(),
          Package10MigrationSection.technicalScrutinyAndCasTribunal.jsonKey:
              scrutiny.toJson(),
          Package10MigrationSection.grandTourNightlyHrvAndPhysio.jsonKey:
              hrv.toJson(),
          Package10MigrationSection.tvDirectorLiveProduction.jsonKey:
              tv.toJson(),
          Package10MigrationSection.tripleCrownWinnersTimelineDb.jsonKey:
              timeline.toJson(),
        },
      );

      expect(initialReport.status, V10MigrationStatus.alreadyCompatible);
      expect(
        initialReport
            .hydratedAmericasOceaniaTours!.americasOceaniaPrestigeScore,
        77.5,
      );
      expect(
        initialReport.hydratedTechnicalScrutiny!.totalFinesPaidChf,
        1500.0,
      );
      expect(initialReport.hydratedGrandTourHrvPhysio!.currentStageDay, 14);
      expect(
        initialReport.hydratedTvDirectorProduction!.productionId,
        'giro_stage_14',
      );
      expect(
        initialReport.hydratedTripleCrownTimelineDb!.careerStartYear,
        2028,
      );

      final roundTripJson = jsonEncode(initialReport.migratedEnvelope!.toJson());
      final secondReport = SaveCompatibilityV10Migrator.migrateRawJson(
        saveId: 'v10_full_slot',
        rawJson: roundTripJson,
      );
      expect(secondReport.status, V10MigrationStatus.alreadyCompatible);
      expect(secondReport.actions, isEmpty);
    });

    test('repairs corrupted Package 10 sections cleanly', () {
      final report = SaveCompatibilityV10Migrator.migratePayloadMap(
        saveId: 'corrupt_v10_slot',
        sourceSchemaVersion: 9,
        payload: <String, dynamic>{
          'saveId': 'corrupt_v10_slot',
          'seasonYear': 2026,
          Package10MigrationSection.americasAndOceaniaTours.jsonKey: 'invalid',
          Package10MigrationSection.technicalScrutinyAndCasTribunal.jsonKey: 42,
          Package10MigrationSection.grandTourNightlyHrvAndPhysio.jsonKey:
              <String, dynamic>{'currentStageDay': 99},
          Package10MigrationSection.tvDirectorLiveProduction.jsonKey: true,
          Package10MigrationSection.tripleCrownWinnersTimelineDb.jsonKey:
              <String, dynamic>{'careerStartYear': 2026, 'entries': []},
        },
      );

      expect(report.status, V10MigrationStatus.repairedAndMigrated);
      expect(report.repairedFixesCount, greaterThanOrEqualTo(5));
      expect(report.hydratedAmericasOceaniaTours!.races.length, 6);
      expect(report.hydratedGrandTourHrvPhysio!.currentStageDay, 1);
      expect(report.hydratedTvDirectorProduction!.cameraFeeds.length, 12);
      expect(
        report.hydratedTripleCrownTimelineDb!.allEntries.isNotEmpty,
        isTrue,
      );

      final outOfRangeHrv = GrandTourNightlyHrvAndPhysioModel.initializeSquad(
        tourId: 'tdf_2026',
        tourName: 'Tour de France 2026',
        squadBaselines: const [],
      ).toJson();
      outOfRangeHrv['currentStageDay'] = 99;
      final clampedReport = SaveCompatibilityV10Migrator.migratePayloadMap(
        saveId: 'clamped_hrv_slot',
        sourceSchemaVersion: 10,
        payload: <String, dynamic>{
          'saveId': 'clamped_hrv_slot',
          'schemaVersion': 10,
          'seasonYear': 2026,
          Package10MigrationSection.grandTourNightlyHrvAndPhysio.jsonKey:
              outOfRangeHrv,
        },
      );
      expect(clampedReport.status, V10MigrationStatus.repairedAndMigrated);
      expect(clampedReport.hydratedGrandTourHrvPhysio!.currentStageDay, 21);
    });
  });

  group('SaveCompatibilityV10MigratorPanel responsive UI', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders and runs migration without overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            const ProviderScope(
              child: MaterialApp(
                home: Scaffold(
                  body: SingleChildScrollView(
                    child: SaveCompatibilityV10MigratorPanel(
                      saveId: 'ui_test_slot',
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 250));

          expect(find.text('Migrator Zapisów v10 (Paczka #10)'), findsOneWidget);

          await tester.tap(find.text('Uruchom Migrację v10'));
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.text('ZMIGROWANY DO V10'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
