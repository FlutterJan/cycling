import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/career/career_save.dart';
import 'package:pro_peloton_manager/services/career/autosave_and_crash_recovery_guard.dart';
import 'package:pro_peloton_manager/services/generators/initial_game_seeder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late AutosaveAndCrashRecoveryGuard guard;
  late CareerSave sampleSave;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('ppm_autosave_guard_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => tempDir.path,
    );
    guard = AutosaveAndCrashRecoveryGuard(
      directoryResolver: () async => tempDir,
    );
    final seeded = await InitialGameSeeder.seedNewGame(
      const InitialGameSeedConfig(
        saveName: 'Test Guard Career',
        playerManagerName: 'Jan Testowy',
        playerTeamId: 'wt_01',
        saveToDisk: false,
        seed: 101,
      ),
    );
    sampleSave = seeded.save;
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('AutosaveAndCrashRecoveryGuard', () {
    test('computeJsonChecksum is deterministic and detects 1-byte mutation', () {
      const payload = '{"id":"save_1","managerReputation":75}';
      const mutated = '{"id":"save_1","managerReputation":76}';

      final sumA = AutosaveAndCrashRecoveryGuard.computeJsonChecksum(payload);
      final sumB = AutosaveAndCrashRecoveryGuard.computeJsonChecksum(payload);
      final sumMutated =
          AutosaveAndCrashRecoveryGuard.computeJsonChecksum(mutated);

      expect(sumA, equals(sumB));
      expect(sumA.length, equals(24));
      expect(sumA, isNot(equals(sumMutated)));
    });

    test('saveCareerTransactional writes verified JSON, cleans .tmp, rotates .bak',
        () async {
      final firstReceipt = await guard.saveCareerTransactional(
        sampleSave,
        trigger: AutosaveTrigger.dayAdvanced,
      );

      expect(firstReceipt.success, isTrue);
      expect(firstReceipt.checksum, isNotEmpty);
      expect(firstReceipt.payloadBytes, greaterThan(0));

      final mainFile = File(
        '${tempDir.path}${Platform.pathSeparator}${sampleSave.id}.json',
      );
      final tempFile = File(
        '${tempDir.path}${Platform.pathSeparator}${sampleSave.id}.tmp',
      );
      final bakFile = File(
        '${tempDir.path}${Platform.pathSeparator}${sampleSave.id}.bak',
      );

      expect(await mainFile.exists(), isTrue);
      expect(await tempFile.exists(), isFalse);
      expect(await bakFile.exists(), isFalse);

      // Second save rotates first save into .bak
      final updatedSave = sampleSave.copyWith(managerReputation: 88);
      final secondReceipt = await guard.saveCareerTransactional(
        updatedSave,
        trigger: AutosaveTrigger.periodic,
      );

      expect(secondReceipt.success, isTrue);
      expect(await bakFile.exists(), isTrue);

      final loaded = await guard.loadCareerWithRecovery(sampleSave.id);
      expect(loaded.status, equals(SaveRecoveryStatus.healthy));
      expect(loaded.save?.managerReputation, equals(88));
    });

    test('recovers from .tmp if main .json is truncated/corrupted', () async {
      await guard.saveCareerTransactional(sampleSave);

      final mainFile = File(
        '${tempDir.path}${Platform.pathSeparator}${sampleSave.id}.json',
      );
      final tempFile = File(
        '${tempDir.path}${Platform.pathSeparator}${sampleSave.id}.tmp',
      );

      // Simulate a verified .tmp from a newer save interrupted before rename
      final newerSave = sampleSave.copyWith(managerReputation: 92);
      final payloadJson = jsonEncode(newerSave.toJson());
      final checksum =
          AutosaveAndCrashRecoveryGuard.computeJsonChecksum(payloadJson);
      final envelope = jsonEncode({
        'schemaVersion': 1,
        'checksumAlgorithm': 'fnv1a64+crc32',
        'checksum': checksum,
        'payloadBytes': utf8.encode(payloadJson).length,
        'trigger': AutosaveTrigger.periodic.name,
        'savedAtUtc': DateTime.now().toUtc().toIso8601String(),
        'payload': newerSave.toJson(),
      });
      await tempFile.writeAsString(envelope, flush: true);

      // Corrupt the main .json (e.g. power cut)
      await mainFile.writeAsString('{"schemaVersion":1,"broken":', flush: true);

      final result = await guard.loadCareerWithRecovery(sampleSave.id);
      expect(result.status, equals(SaveRecoveryStatus.recoveredFromTemp));
      expect(result.wasRecovered, isTrue);
      expect(result.save?.managerReputation, equals(92));
    });

    test('recovers from .bak when main .json is corrupted and .tmp is invalid',
        () async {
      await guard.saveCareerTransactional(
        sampleSave.copyWith(managerReputation: 64),
      );
      await guard.saveCareerTransactional(
        sampleSave.copyWith(managerReputation: 79),
      );

      final mainFile = File(
        '${tempDir.path}${Platform.pathSeparator}${sampleSave.id}.json',
      );
      final tempFile = File(
        '${tempDir.path}${Platform.pathSeparator}${sampleSave.id}.tmp',
      );

      await mainFile.writeAsString('CORRUPTED_BY_POWER_LOSS', flush: true);
      await tempFile.writeAsString('PARTIAL_TEMP_WRITE', flush: true);

      final result = await guard.loadCareerWithRecovery(sampleSave.id);
      expect(result.status, equals(SaveRecoveryStatus.recoveredFromBackup));
      expect(result.save?.managerReputation, equals(64));
    });

    test(
        'PreStageCheckpoint enables immediate recovery before stage briefing and clears on stage completion',
        () async {
      final cpReceipt = await guard.createPreStageCheckpoint(
        careerSave: sampleSave,
        raceId: 'tdf_2026',
        raceName: 'Tour de France',
        stageId: 'tdf_s14',
        stageNumber: 14,
        stageName: 'Pau - Pla d\'Adet',
        selectedRiderIds: const ['rider_1', 'rider_2', 'rider_3'],
      );
      expect(cpReceipt.success, isTrue);

      // Simulate unexpected app restart mid-race
      final interrupted = await guard.detectAnyInterruptedStageCheckpoint();
      expect(interrupted, isNotNull);
      expect(interrupted!.raceId, equals('tdf_2026'));
      expect(interrupted.stageNumber, equals(14));
      expect(interrupted.isActiveInProgress, isTrue);
      expect(interrupted.selectedRiderIds, hasLength(3));

      final resumed = await guard.resumeFromPreStageCheckpoint(interrupted);
      expect(resumed.stageId, equals('tdf_s14'));

      final loadedMain = await guard.loadCareerWithRecovery(sampleSave.id);
      expect(loadedMain.status, equals(SaveRecoveryStatus.healthy));

      // Mark stage cleanly completed -> no longer flagged as interrupted
      final marked = await guard.markStageCompleted(
        careerSaveId: sampleSave.id,
        stageId: 'tdf_s14',
      );
      expect(marked, isTrue);

      final afterCompletion = await guard.detectAnyInterruptedStageCheckpoint();
      expect(afterCompletion, isNull);
    });
  });
}
