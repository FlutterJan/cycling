import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/services/database/database_backup_and_integrity_repair.dart';

Map<String, dynamic> _buildMinimalLegacySavePayload({
  String id = 'career_legacy_1',
  String saveName = 'Legacy Tour',
}) {
  return <String, dynamic>{
    'id': id,
    'saveName': saveName,
    'createdAt': '2026-01-01T10:00:00.000Z',
    'lastSavedAt': '2026-01-10T10:00:00.000Z',
    'difficulty': 'normal',
    'playerManagerName': 'Jan Kowalski',
    'playerTeamId': 'team_pl_1',
    'currentDate': '2026-02-01T08:00:00.000Z',
    'currentSeasonYear': 2026,
    'calendar': <String, dynamic>{
      'seasonYear': 2026,
      'races': const <dynamic>[],
    },
    'teams': <dynamic>[
      <String, dynamic>{
        'id': 'team_pl_1',
        'name': 'Polska Ekipa Pro',
        'shortName': 'POL',
        'countryCode': 'PL',
        'division': 'worldTour',
        'cashBalanceEur': 3500000,
      },
    ],
    'riders': const <dynamic>[],
  };
}

void main() {
  late Directory tempDir;
  late DatabaseBackupAndIntegrityRepair service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('ppm_db_repair_test_');
    service = DatabaseBackupAndIntegrityRepair(
      directoryResolver: () async => tempDir,
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('DatabaseBackupAndIntegrityRepair', () {
    test('wykrywa poprawny zapis, błąd sumy kontrolnej i uszkodzony JSON', () {
      final payload = _buildMinimalLegacySavePayload();
      final legacyReport = service.verifyRawJsonContent(
        saveId: 'legacy_1',
        rawContent: jsonEncode(payload),
      );
      expect(legacyReport.status, SaveIntegrityStatus.legacyNeedsMigration);
      expect(legacyReport.repairedFields, isNotEmpty);

      final emptyReport = service.verifyRawJsonContent(
        saveId: 'empty_1',
        rawContent: '   ',
      );
      expect(emptyReport.status, SaveIntegrityStatus.corruptedJson);

      final brokenReport = service.verifyRawJsonContent(
        saveId: 'broken_1',
        rawContent: '{bad json',
      );
      expect(brokenReport.status, SaveIntegrityStatus.corruptedJson);
    });

    test('tworzy kopię zapasową .bak przed każdym nadpisaniem i weryfikuje sumę', () async {
      final payload1 = _buildMinimalLegacySavePayload(saveName: 'Stan 1');
      final receipt1 = await service.writePayloadWithBackup(
        saveId: 'slot_1',
        payload: payload1,
      );
      expect(receipt1.success, isTrue);
      expect(receipt1.backupCreated, isFalse);

      final bakFile = File('${tempDir.path}${Platform.pathSeparator}slot_1.bak');
      expect(await bakFile.exists(), isFalse);

      final payload2 = _buildMinimalLegacySavePayload(saveName: 'Stan 2');
      final receipt2 = await service.writePayloadWithBackup(
        saveId: 'slot_1',
        payload: payload2,
      );
      expect(receipt2.success, isTrue);
      expect(receipt2.backupCreated, isTrue);
      expect(await bakFile.exists(), isTrue);

      final bakContent = await bakFile.readAsString();
      final bakEnvelope = IntegritySaveEnvelope.tryParse(bakContent);
      expect(bakEnvelope, isNotNull);
      expect(bakEnvelope!.payload['saveName'], 'Stan 1');
    });

    test('odzyskuje zapis z .bak gdy główny plik .json ma naruszoną sumę kontrolną', () async {
      final payload1 = _buildMinimalLegacySavePayload(saveName: 'Bezpieczny Stan');
      await service.writePayloadWithBackup(
        saveId: 'slot_2',
        payload: payload1,
      );
      final payload2 = _buildMinimalLegacySavePayload(saveName: 'Nowszy Stan');
      await service.writePayloadWithBackup(
        saveId: 'slot_2',
        payload: payload2,
      );

      final mainFile = File('${tempDir.path}${Platform.pathSeparator}slot_2.json');
      final tampered = (await mainFile.readAsString())
          .replaceFirst('Nowszy Stan', 'Zmanipulowany Stan');
      await mainFile.writeAsString(tampered, flush: true);

      final report = await service.verifyAndRepairSave('slot_2');
      expect(report.status, SaveIntegrityStatus.restoredFromBackup);
      expect(report.careerSave, isNotNull);
      expect(report.careerSave!.saveName, 'Bezpieczny Stan');
    });

    test('migruje stary zapis v1 do v4 i uzupełnia brakujące pola z nowych paczek', () async {
      final legacyPayload = _buildMinimalLegacySavePayload();
      final mainFile = File('${tempDir.path}${Platform.pathSeparator}slot_legacy.json');
      await mainFile.writeAsString(jsonEncode(legacyPayload), flush: true);

      final report = await service.verifyAndRepairSave('slot_legacy');
      expect(report.status, SaveIntegrityStatus.repairedAndMigrated);
      expect(report.detectedSchemaVersion, 1);
      expect(report.targetSchemaVersion, DatabaseBackupAndIntegrityRepair.currentSchemaVersion);
      expect(report.careerSave, isNotNull);
      expect(report.careerSave!.managerReputation, 50);
      expect(report.careerSave!.serviceCourseLevel, 1);
      expect(report.careerSave!.windTunnelLevel, 1);
      expect(report.careerSave!.medicalCenterLevel, 1);
      expect(report.repairedFields.any((f) => f.jsonPath == r'$.youthAcademy'), isTrue);

      final secondPass = await service.verifyAndRepairSave('slot_legacy');
      expect(secondPass.status, SaveIntegrityStatus.valid);
    });
  });

  group('DatabaseBackupAndIntegrityRepairPanel UI', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renderuje panel responsywnie bez przepełnień przy ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          await tester.binding.setSurfaceSize(size);
          addTearDown(() => tester.binding.setSurfaceSize(null));

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                databaseIntegrityRepairProvider.overrideWith(
                  (ref) => DatabaseIntegrityRepairNotifier(service: service),
                ),
              ],
              child: const MaterialApp(
                home: Scaffold(
                  body: Padding(
                    padding: EdgeInsets.all(12),
                    child: DatabaseBackupAndIntegrityRepairPanel(),
                  ),
                ),
              ),
            ),
          );

          await tester.pump(const Duration(milliseconds: 300));
          expect(find.byType(DatabaseBackupAndIntegrityRepairPanel), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
