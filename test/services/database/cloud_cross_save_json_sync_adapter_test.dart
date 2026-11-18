import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/services/database/cloud_cross_save_json_sync_adapter.dart';

void main() {
  group('CloudCrossSaveJsonSyncAdapter — GZIP & Transfer PC <-> Mac <-> Mobile', () {
    late CloudCrossSaveJsonSyncAdapter adapter;
    late CrossSaveDeviceProfile pcDevice;
    late CrossSaveDeviceProfile macDevice;
    late CrossSaveDeviceProfile mobileDevice;

    setUp(() {
      adapter = CloudCrossSaveJsonSyncAdapter();
      pcDevice = CrossSaveDeviceProfile(
        deviceId: 'pc_win_01',
        deviceName: 'PC Windows Gaming',
        platform: CrossSaveDevicePlatform.pcWindows,
        appVersion: '0.1.0+1',
        lastSeenAt: DateTime.utc(2026, 11, 18, 12, 0),
        isCurrentDevice: true,
      );
      macDevice = CrossSaveDeviceProfile(
        deviceId: 'mac_m3_01',
        deviceName: 'MacBook Pro M3',
        platform: CrossSaveDevicePlatform.macOs,
        appVersion: '0.1.0+1',
        lastSeenAt: DateTime.utc(2026, 11, 18, 13, 0),
      );
      mobileDevice = CrossSaveDeviceProfile(
        deviceId: 'ios_16_01',
        deviceName: 'iPhone 16 Pro',
        platform: CrossSaveDevicePlatform.mobileIos,
        appVersion: '0.1.0+1',
        lastSeenAt: DateTime.utc(2026, 11, 18, 14, 0),
      );
    });

    Map<String, dynamic> buildRealisticSaveJson() {
      return {
        'id': 'save_wt_2027',
        'saveName': 'Polski Projekt WorldTour — Alpy',
        'playerManagerName': 'Jan Kowalski',
        'playerTeamId': 'team_pl_01',
        'currentSeasonYear': 2027,
        'currentDate': '2027-07-14T10:30:00.000Z',
        'teams': [
          {'id': 'team_pl_01', 'name': 'Orzeł Cycling Team'},
          {'id': 'team_fr_02', 'name': 'Équipe Alpes'},
        ],
        'notes': 'Etap królewski\r\nAlpe d\'Huez — pełny atak na 6 km przed metą.',
        'telemetry': List.generate(
          60,
          (i) => {'km': i + 1, 'watts': 380 + (i % 15), 'hr': 168 + (i % 8)},
        ),
      };
    }

    test('kompresuje GZIP i odtwarza JSON 1:1 z oszczędnością transferu', () {
      final raw = buildRealisticSaveJson();
      final packet = adapter.compressRawJson(
        jsonMap: raw,
        sourceDevice: pcDevice,
        compressionLevel: 9,
      );

      expect(packet.magicHeader, kCrossSavePacketMagic);
      expect(packet.metadata.sourcePlatform, CrossSaveDevicePlatform.pcWindows);
      expect(packet.metadata.teamName, 'Orzeł Cycling Team');
      expect(packet.metadata.compressedBytes, lessThan(packet.metadata.uncompressedBytes));
      expect(packet.metadata.bandwidthSavedPercent, greaterThan(40.0));
      expect(packet.metadata.fnv1a64Checksum.length, 16);
      expect(packet.metadata.crc32Checksum.length, 8);

      final restored = adapter.decompressToJson(packet);
      expect(restored['id'], 'save_wt_2027');
      expect(restored['saveName'], 'Polski Projekt WorldTour — Alpy');
      expect(
        restored['notes'],
        'Etap królewski\nAlpe d\'Huez — pełny atak na 6 km przed metą.',
      );
      expect((restored['telemetry'] as List).length, 60);
    });

    test('wykrywa uszkodzenie sumy kontrolnej FNV-1a64 po manipulacji metadanymi', () {
      final packet = adapter.compressRawJson(
        jsonMap: buildRealisticSaveJson(),
        sourceDevice: macDevice,
      );
      final tamperedMeta = CrossSaveEnvelopeMetadata(
        saveId: packet.metadata.saveId,
        saveName: packet.metadata.saveName,
        managerName: packet.metadata.managerName,
        teamName: packet.metadata.teamName,
        seasonYear: packet.metadata.seasonYear,
        inGameDateIso: packet.metadata.inGameDateIso,
        schemaVersion: packet.metadata.schemaVersion,
        sourcePlatform: packet.metadata.sourcePlatform,
        sourceDeviceId: packet.metadata.sourceDeviceId,
        sourceDeviceName: packet.metadata.sourceDeviceName,
        createdAtUtc: packet.metadata.createdAtUtc,
        uncompressedBytes: packet.metadata.uncompressedBytes,
        compressedBytes: packet.metadata.compressedBytes,
        fnv1a64Checksum: '0000000000000000',
        crc32Checksum: packet.metadata.crc32Checksum,
      );
      final tamperedPacket = CrossSaveCompressedPacket(
        metadata: tamperedMeta,
        gzipPayloadBase64: packet.gzipPayloadBase64,
      );

      expect(
        () => adapter.decompressToJson(tamperedPacket),
        throwsA(isA<CrossSaveIntegrityException>()),
      );
    });

    test('koduje i dekoduje przenośny token PPMCS1 między PC a Mobile', () {
      final packet = adapter.compressRawJson(
        jsonMap: buildRealisticSaveJson(),
        sourceDevice: pcDevice,
      );
      final token = adapter.encodePortableToken(packet);
      expect(token.startsWith(kCrossSaveTokenPrefix), isTrue);

      final decodedPacket = adapter.decodePortableToken(token);
      final restored = adapter.decompressToJson(decodedPacket);
      expect(restored['playerManagerName'], 'Jan Kowalski');
      expect(decodedPacket.metadata.sourceDeviceId, pcDevice.deviceId);
    });

    test('eksportuje i importuje plik .ppmsave.gz na dysku', () async {
      final tempDir = await Directory.systemTemp.createTemp('ppm_cross_save_');
      try {
        final packet = adapter.compressRawJson(
          jsonMap: buildRealisticSaveJson(),
          sourceDevice: mobileDevice,
        );
        final file = await adapter.exportToCompressedFile(
          packet: packet,
          targetDirectory: tempDir,
        );
        expect(await file.exists(), isTrue);
        expect(file.path.endsWith(kCrossSaveFileExtension), isTrue);

        final imported = await adapter.importFromCompressedFile(file);
        final json = adapter.decompressToJson(imported);
        expect(json['currentSeasonYear'], 2027);
        expect(imported.metadata.sourcePlatform, CrossSaveDevicePlatform.mobileIos);
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('wykrywa konflikt między PC a Mac i rozwiązuje go zgodnie ze strategią', () async {
      final pcSave = buildRealisticSaveJson();
      final uploadPc = await adapter.uploadSaveJson(
        slotKey: 'slot_1',
        saveJson: pcSave,
        sourceDevice: pcDevice,
      );
      expect(uploadPc.success, isTrue);

      final macSave = Map<String, dynamic>.from(pcSave)
        ..['currentSeasonYear'] = 2028;

      final conflictReceipt = await adapter.uploadSaveJson(
        slotKey: 'slot_1',
        saveJson: macSave,
        sourceDevice: macDevice,
        conflictStrategy: CrossSaveConflictResolutionStrategy.manualReview,
      );
      expect(conflictReceipt.success, isFalse);
      expect(conflictReceipt.conflict, isNotNull);
      expect(conflictReceipt.conflict!.remoteDevice.platform, CrossSaveDevicePlatform.pcWindows);

      final overwriteReceipt = await adapter.uploadSaveJson(
        slotKey: 'slot_1',
        saveJson: macSave,
        sourceDevice: macDevice,
        conflictStrategy: CrossSaveConflictResolutionStrategy.preferLocalDevice,
      );
      expect(overwriteReceipt.success, isTrue);

      final downloaded = await adapter.downloadSaveJson(slotKey: 'slot_1');
      expect(downloaded.receipt.success, isTrue);
      expect(downloaded.json?['currentSeasonYear'], 2028);
    });

    test('CloudCrossSaveSyncNotifier obsługuje upload, token i zmianę platformy', () async {
      final notifier = CloudCrossSaveSyncNotifier();
      notifier.switchLocalDevicePlatform(CrossSaveDevicePlatform.macOs);
      expect(notifier.state.currentDevice.platform, CrossSaveDevicePlatform.macOs);

      final receipt = await notifier.syncUploadSaveJson(
        slotKey: 'slot_mac',
        saveJson: buildRealisticSaveJson(),
      );
      expect(receipt.success, isTrue);
      expect(notifier.state.status, CrossSaveSyncStatus.synced);
      expect(notifier.state.cloudSlots.length, 1);

      final token = notifier.generatePortableTokenForSlot('slot_mac');
      expect(token, isNotNull);

      final imported = await notifier.importPortableToken(
        token: token!,
        targetSlotKey: 'slot_mobile_import',
      );
      expect(imported, isNotNull);
      expect(notifier.state.cloudSlots.length, 2);
    });
  });

  group('CloudCrossSaveJsonSyncPanel — Responsywność UI', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renderuje panel bez przepełnień przy ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
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
                  body: CloudCrossSaveJsonSyncPanel(),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.text('CROSS-SAVE JSON & GZIP SYNC'), findsOneWidget);
          expect(find.text('Wyślij bieżący zapis'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
