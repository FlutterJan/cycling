import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/career/career_save.dart';
import '../career/autosave_and_crash_recovery_guard.dart';

/// Aktualny status integralności pliku zapisu JSON na dysku.
enum SaveIntegrityStatus {
  valid,
  legacyNeedsMigration,
  repairedAndMigrated,
  restoredFromBackup,
  checksumMismatch,
  corruptedJson,
  notFound;

  bool get isHealthy =>
      this == SaveIntegrityStatus.valid ||
      this == SaveIntegrityStatus.repairedAndMigrated ||
      this == SaveIntegrityStatus.restoredFromBackup;

  String get labelPl {
    switch (this) {
      case SaveIntegrityStatus.valid:
        return 'ZWERYFIKOWANY (OK)';
      case SaveIntegrityStatus.legacyNeedsMigration:
        return 'WYMAGA MIGRACJI SCHEMATU';
      case SaveIntegrityStatus.repairedAndMigrated:
        return 'NAPRAWIONY I ZMIGROWANY';
      case SaveIntegrityStatus.restoredFromBackup:
        return 'ODZYSKANY Z KOPII .BAK';
      case SaveIntegrityStatus.checksumMismatch:
        return 'BŁĄD SUMY KONTROLNEJ';
      case SaveIntegrityStatus.corruptedJson:
        return 'USZKODZONY JSON';
      case SaveIntegrityStatus.notFound:
        return 'BRAK PLIKU';
    }
  }
}

/// Poziom ważności wykrytego problemu integralności.
enum IntegrityIssueSeverity {
  info,
  warning,
  critical,
}

/// Pojedynczy problem wykryty podczas audytu integralności zapisu.
class IntegrityIssue {
  final String code;
  final String jsonPath;
  final String message;
  final IntegrityIssueSeverity severity;

  const IntegrityIssue({
    required this.code,
    required this.jsonPath,
    required this.message,
    required this.severity,
  });
}

/// Rekord automatycznie uzupełnionego lub naprawionego pola podczas migracji.
class RepairedFieldRecord {
  final String jsonPath;
  final String reason;
  final String appliedValueSummary;

  const RepairedFieldRecord({
    required this.jsonPath,
    required this.reason,
    required this.appliedValueSummary,
  });
}

/// Pojedynczy krok migracji schematu pomiędzy wersjami paczek zadań.
class SchemaMigrationStep {
  final int fromVersion;
  final int toVersion;
  final String description;
  final int fieldsAddedCount;

  const SchemaMigrationStep({
    required this.fromVersion,
    required this.toVersion,
    required this.description,
    required this.fieldsAddedCount,
  });
}

/// Raport z weryfikacji, naprawy i migracji pojedynczego zapisu gry.
class SaveIntegrityAuditReport {
  final String saveId;
  final SaveIntegrityStatus status;
  final int detectedSchemaVersion;
  final int targetSchemaVersion;
  final String? expectedChecksum;
  final String? actualChecksum;
  final int payloadBytes;
  final bool hasBackupFile;
  final DateTime auditedAtUtc;
  final List<IntegrityIssue> issues;
  final List<RepairedFieldRecord> repairedFields;
  final List<SchemaMigrationStep> appliedMigrations;
  final CareerSave? careerSave;
  final String summaryMessage;

  const SaveIntegrityAuditReport({
    required this.saveId,
    required this.status,
    required this.detectedSchemaVersion,
    required this.targetSchemaVersion,
    required this.expectedChecksum,
    required this.actualChecksum,
    required this.payloadBytes,
    required this.hasBackupFile,
    required this.auditedAtUtc,
    this.issues = const [],
    this.repairedFields = const [],
    this.appliedMigrations = const [],
    this.careerSave,
    required this.summaryMessage,
  });

  bool get checksumMatches =>
      expectedChecksum != null &&
      actualChecksum != null &&
      expectedChecksum == actualChecksum;
}

/// Potwierdzenie wykonania atomowego zapisu z kopią `.bak` i sumą kontrolną.
class BackupAndWriteReceipt {
  final bool success;
  final String saveId;
  final String targetPath;
  final String? backupPath;
  final bool backupCreated;
  final String checksum;
  final int schemaVersion;
  final int payloadBytes;
  final DateTime writtenAtUtc;
  final String? errorMessage;

  const BackupAndWriteReceipt({
    required this.success,
    required this.saveId,
    required this.targetPath,
    this.backupPath,
    required this.backupCreated,
    required this.checksum,
    required this.schemaVersion,
    required this.payloadBytes,
    required this.writtenAtUtc,
    this.errorMessage,
  });
}

/// Koperta integralności zapisu JSON przechowująca sumę kontrolną i historię migracji.
class IntegritySaveEnvelope {
  static const int currentSchemaVersion = 4;
  static const String checksumAlgorithmName = 'fnv1a64+crc32';

  final int schemaVersion;
  final String checksumAlgorithm;
  final String checksum;
  final int payloadBytes;
  final DateTime savedAtUtc;
  final List<String> migrationHistory;
  final Map<String, dynamic> payload;

  const IntegritySaveEnvelope({
    required this.schemaVersion,
    required this.checksumAlgorithm,
    required this.checksum,
    required this.payloadBytes,
    required this.savedAtUtc,
    this.migrationHistory = const [],
    required this.payload,
  });

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'checksumAlgorithm': checksumAlgorithm,
      'checksum': checksum,
      'payloadBytes': payloadBytes,
      'savedAtUtc': savedAtUtc.toUtc().toIso8601String(),
      'migrationHistory': migrationHistory,
      'payload': payload,
    };
  }

  static IntegritySaveEnvelope? tryParse(String rawJson) {
    if (rawJson.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, dynamic>) return null;
      final checksum = decoded['checksum'];
      final payload = decoded['payload'];
      final payloadBytes = decoded['payloadBytes'];
      final savedAtRaw = decoded['savedAtUtc'];
      if (checksum is! String ||
          payload is! Map<String, dynamic> ||
          payloadBytes is! num ||
          savedAtRaw is! String) {
        return null;
      }
      final parsedDate = DateTime.tryParse(savedAtRaw)?.toUtc();
      if (parsedDate == null) return null;

      return IntegritySaveEnvelope(
        schemaVersion: (decoded['schemaVersion'] as num?)?.toInt() ?? 1,
        checksumAlgorithm:
            decoded['checksumAlgorithm'] as String? ?? checksumAlgorithmName,
        checksum: checksum,
        payloadBytes: payloadBytes.toInt(),
        savedAtUtc: parsedDate,
        migrationHistory: (decoded['migrationHistory'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(growable: false),
        payload: payload,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Automatyczny system weryfikacji sumy kontrolnej, rotacji kopii zapasowych `.bak`,
/// naprawy uszkodzeń oraz bezbłędnej migracji pól zapisów gry pomiędzy paczkami zadań.
class DatabaseBackupAndIntegrityRepair {
  static const String _defaultSavesFolder = 'ppm_saves';
  static const int currentSchemaVersion = IntegritySaveEnvelope.currentSchemaVersion;

  final Future<Directory> Function()? _directoryResolver;

  DatabaseBackupAndIntegrityRepair({
    Future<Directory> Function()? directoryResolver,
  }) : _directoryResolver = directoryResolver;

  /// Zwraca katalog zapisów (domyślnie `Documents/ppm_saves` lub wstrzyknięty w testach).
  Future<Directory> resolveSavesDirectory() async {
    if (_directoryResolver != null) {
      final dir = await _directoryResolver();
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    }
    final appDocDir = await getApplicationDocumentsDirectory();
    final savesDir = Directory(
      '${appDocDir.path}${Platform.pathSeparator}$_defaultSavesFolder',
    );
    if (!await savesDir.exists()) {
      await savesDir.create(recursive: true);
    }
    return savesDir;
  }

  /// Kanonizuje strukturę JSON (rekurencyjnie sortuje klucze map), dzięki czemu
  /// suma kontrolna jest w 100% deterministyczna niezależnie od kolejności kluczy.
  static dynamic canonicalizeJsonValue(dynamic value) {
    if (value is Map<String, dynamic>) {
      final sortedKeys = value.keys.toList()..sort();
      final result = <String, dynamic>{};
      for (final key in sortedKeys) {
        result[key] = canonicalizeJsonValue(value[key]);
      }
      return result;
    }
    if (value is Map) {
      final sortedKeys = value.keys.map((e) => e.toString()).toList()..sort();
      final result = <String, dynamic>{};
      for (final key in sortedKeys) {
        result[key] = canonicalizeJsonValue(value[key]);
      }
      return result;
    }
    if (value is List) {
      return value.map(canonicalizeJsonValue).toList(growable: false);
    }
    return value;
  }

  /// Oblicza deterministyczną sumę kontrolną (`FNV-1a 64-bit` + `CRC-32 IEEE`)
  /// dla kanonicznej postaci mapy JSON.
  static String computeCanonicalPayloadChecksum(Map<String, dynamic> payload) {
    final canonical = canonicalizeJsonValue(payload);
    final encoded = jsonEncode(canonical);
    return AutosaveAndCrashRecoveryGuard.computeJsonChecksum(encoded);
  }

  /// Weryfikuje surowy łańcuch JSON z dysku (koperta integralności lub starszy format surowy).
  SaveIntegrityAuditReport verifyRawJsonContent({
    required String saveId,
    required String rawContent,
    bool hasBackupFile = false,
  }) {
    final now = DateTime.now().toUtc();
    if (rawContent.trim().isEmpty) {
      return SaveIntegrityAuditReport(
        saveId: saveId,
        status: SaveIntegrityStatus.corruptedJson,
        detectedSchemaVersion: 0,
        targetSchemaVersion: currentSchemaVersion,
        expectedChecksum: null,
        actualChecksum: null,
        payloadBytes: 0,
        hasBackupFile: hasBackupFile,
        auditedAtUtc: now,
        issues: const [
          IntegrityIssue(
            code: 'EMPTY_FILE',
            jsonPath: r'$',
            message: 'Plik zapisu jest pusty.',
            severity: IntegrityIssueSeverity.critical,
          ),
        ],
        summaryMessage: 'Plik zapisu jest pusty i nie może zostać zdekodowany.',
      );
    }

    final envelope = IntegritySaveEnvelope.tryParse(rawContent);
    if (envelope != null) {
      final canonicalEncoded = jsonEncode(canonicalizeJsonValue(envelope.payload));
      final actualChecksum =
          AutosaveAndCrashRecoveryGuard.computeJsonChecksum(canonicalEncoded);
      final legacyChecksum =
          AutosaveAndCrashRecoveryGuard.computeJsonChecksum(
            jsonEncode(envelope.payload),
          );
      final matches = envelope.checksum == actualChecksum ||
          envelope.checksum == legacyChecksum;

      if (!matches) {
        return SaveIntegrityAuditReport(
          saveId: saveId,
          status: SaveIntegrityStatus.checksumMismatch,
          detectedSchemaVersion: envelope.schemaVersion,
          targetSchemaVersion: currentSchemaVersion,
          expectedChecksum: envelope.checksum,
          actualChecksum: actualChecksum,
          payloadBytes: utf8.encode(canonicalEncoded).length,
          hasBackupFile: hasBackupFile,
          auditedAtUtc: now,
          issues: [
            IntegrityIssue(
              code: 'CHECKSUM_MISMATCH',
              jsonPath: r'$.checksum',
              message:
                  'Niezgodność sumy kontrolnej: oczekiwano ${envelope.checksum}, obliczono $actualChecksum.',
              severity: IntegrityIssueSeverity.critical,
            ),
          ],
          summaryMessage:
              'Wykryto naruszenie integralności sumy kontrolnej pliku JSON.',
        );
      }

      final dryRunRepairs = <RepairedFieldRecord>[];
      final dryRunMigrations = <SchemaMigrationStep>[];
      final clonedPayload =
          jsonDecode(jsonEncode(envelope.payload)) as Map<String, dynamic>;
      migrateAndRepairPayloadInPlace(
        payload: clonedPayload,
        fromSchemaVersion: envelope.schemaVersion,
        repairedFields: dryRunRepairs,
        appliedMigrations: dryRunMigrations,
      );

      if (envelope.schemaVersion < currentSchemaVersion ||
          dryRunRepairs.isNotEmpty) {
        return SaveIntegrityAuditReport(
          saveId: saveId,
          status: SaveIntegrityStatus.legacyNeedsMigration,
          detectedSchemaVersion: envelope.schemaVersion,
          targetSchemaVersion: currentSchemaVersion,
          expectedChecksum: envelope.checksum,
          actualChecksum: actualChecksum,
          payloadBytes: utf8.encode(canonicalEncoded).length,
          hasBackupFile: hasBackupFile,
          auditedAtUtc: now,
          repairedFields: dryRunRepairs,
          appliedMigrations: dryRunMigrations,
          summaryMessage:
              'Suma kontrolna poprawna, lecz zapis wymaga migracji v${envelope.schemaVersion} -> v$currentSchemaVersion (${dryRunRepairs.length} pól).',
        );
      }

      return SaveIntegrityAuditReport(
        saveId: saveId,
        status: SaveIntegrityStatus.valid,
        detectedSchemaVersion: envelope.schemaVersion,
        targetSchemaVersion: currentSchemaVersion,
        expectedChecksum: envelope.checksum,
        actualChecksum: actualChecksum,
        payloadBytes: utf8.encode(canonicalEncoded).length,
        hasBackupFile: hasBackupFile,
        auditedAtUtc: now,
        summaryMessage:
            'Zapis zweryfikowany pomyślnie (schemat v${envelope.schemaVersion}, suma kontrolna zgodna).',
      );
    }

    // Próba odczytu jako starszy (legacy) surowy obiekt CareerSave JSON bez koperty.
    try {
      final decoded = jsonDecode(rawContent);
      if (decoded is! Map<String, dynamic>) {
        return SaveIntegrityAuditReport(
          saveId: saveId,
          status: SaveIntegrityStatus.corruptedJson,
          detectedSchemaVersion: 0,
          targetSchemaVersion: currentSchemaVersion,
          expectedChecksum: null,
          actualChecksum: null,
          payloadBytes: utf8.encode(rawContent).length,
          hasBackupFile: hasBackupFile,
          auditedAtUtc: now,
          issues: const [
            IntegrityIssue(
              code: 'INVALID_ROOT_TYPE',
              jsonPath: r'$',
              message: 'Korzeń pliku JSON nie jest obiektem mapy.',
              severity: IntegrityIssueSeverity.critical,
            ),
          ],
          summaryMessage: 'Nieprawidłowa struktura główna JSON.',
        );
      }

      final dryRunRepairs = <RepairedFieldRecord>[];
      final dryRunMigrations = <SchemaMigrationStep>[];
      final cloned = jsonDecode(jsonEncode(decoded)) as Map<String, dynamic>;
      migrateAndRepairPayloadInPlace(
        payload: cloned,
        fromSchemaVersion: 1,
        repairedFields: dryRunRepairs,
        appliedMigrations: dryRunMigrations,
      );

      final actualChecksum = computeCanonicalPayloadChecksum(decoded);
      return SaveIntegrityAuditReport(
        saveId: saveId,
        status: SaveIntegrityStatus.legacyNeedsMigration,
        detectedSchemaVersion: 1,
        targetSchemaVersion: currentSchemaVersion,
        expectedChecksum: null,
        actualChecksum: actualChecksum,
        payloadBytes: utf8.encode(rawContent).length,
        hasBackupFile: hasBackupFile,
        auditedAtUtc: now,
        issues: const [
          IntegrityIssue(
            code: 'LEGACY_UNENVELOPED_SAVE',
            jsonPath: r'$',
            message:
                'Starszy format zapisu bez koperty sumy kontrolnej (wymaga migracji).',
            severity: IntegrityIssueSeverity.warning,
          ),
        ],
        repairedFields: dryRunRepairs,
        appliedMigrations: dryRunMigrations,
        summaryMessage:
            'Wykryto starszy zapis bez sumy kontrolnej. Gotowy do bezpiecznej migracji do v$currentSchemaVersion.',
      );
    } catch (e) {
      return SaveIntegrityAuditReport(
        saveId: saveId,
        status: SaveIntegrityStatus.corruptedJson,
        detectedSchemaVersion: 0,
        targetSchemaVersion: currentSchemaVersion,
        expectedChecksum: null,
        actualChecksum: null,
        payloadBytes: utf8.encode(rawContent).length,
        hasBackupFile: hasBackupFile,
        auditedAtUtc: now,
        issues: [
          IntegrityIssue(
            code: 'JSON_DECODE_ERROR',
            jsonPath: r'$',
            message: 'Błąd składni JSON: $e',
            severity: IntegrityIssueSeverity.critical,
          ),
        ],
        summaryMessage: 'Plik JSON jest uszkodzony składniowo.',
      );
    }
  }

  /// Automatycznie tworzy kopię zapasową `.bak` przed każdym zapisem, oblicza
  /// sumę kontrolną i zapisuje plik atomowo przez `.tmp` z weryfikacją po zapisie.
  Future<BackupAndWriteReceipt> writeCareerSaveWithBackup({
    required CareerSave save,
    String? customSaveId,
    List<String> migrationHistory = const [],
  }) async {
    final saveId = customSaveId ?? save.id;
    final payload = save.toJson();
    return writePayloadWithBackup(
      saveId: saveId,
      payload: payload,
      schemaVersion: currentSchemaVersion,
      migrationHistory: migrationHistory,
    );
  }

  /// Atomowy zapis surowej mapy JSON (owiniętej w kopertę sumy kontrolnej)
  /// z obowiązkową rotacją dotychczasowego pliku do `.bak` przed nadpisaniem.
  Future<BackupAndWriteReceipt> writePayloadWithBackup({
    required String saveId,
    required Map<String, dynamic> payload,
    int schemaVersion = currentSchemaVersion,
    List<String> migrationHistory = const [],
  }) async {
    final dir = await resolveSavesDirectory();
    final targetFile = File('${dir.path}${Platform.pathSeparator}$saveId.json');
    final tempFile = File('${dir.path}${Platform.pathSeparator}$saveId.tmp');
    final backupFile = File('${dir.path}${Platform.pathSeparator}$saveId.bak');
    final backupTempFile =
        File('${dir.path}${Platform.pathSeparator}$saveId.bak.tmp');

    final nowUtc = DateTime.now().toUtc();
    final canonicalPayload =
        canonicalizeJsonValue(payload) as Map<String, dynamic>;
    final canonicalPayloadJson = jsonEncode(canonicalPayload);
    final payloadBytes = utf8.encode(canonicalPayloadJson).length;
    final checksum =
        AutosaveAndCrashRecoveryGuard.computeJsonChecksum(canonicalPayloadJson);

    final envelope = IntegritySaveEnvelope(
      schemaVersion: schemaVersion,
      checksumAlgorithm: IntegritySaveEnvelope.checksumAlgorithmName,
      checksum: checksum,
      payloadBytes: payloadBytes,
      savedAtUtc: nowUtc,
      migrationHistory: migrationHistory,
      payload: canonicalPayload,
    );
    final envelopeJson = jsonEncode(envelope.toJson());

    try {
      // 1. Zapis nowego stanu do pliku tymczasowego .tmp z natychmiastowym flush
      await tempFile.writeAsString(envelopeJson, flush: true);

      // 2. Weryfikacja zapisanego pliku .tmp z dysku przed jakąkolwiek podmianą
      final writtenCheck = await tempFile.readAsString();
      final verifiedEnvelope = IntegritySaveEnvelope.tryParse(writtenCheck);
      if (verifiedEnvelope == null || verifiedEnvelope.checksum != checksum) {
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
        return BackupAndWriteReceipt(
          success: false,
          saveId: saveId,
          targetPath: targetFile.path,
          backupPath: backupFile.path,
          backupCreated: false,
          checksum: checksum,
          schemaVersion: schemaVersion,
          payloadBytes: payloadBytes,
          writtenAtUtc: nowUtc,
          errorMessage:
              'Weryfikacja sumy kontrolnej pliku .tmp po zapisie nie powiodła się.',
        );
      }

      // 3. Automatyczna kopia zapasowa .bak przed każdym nadpisaniem istniejącego zapisu
      bool backupCreated = false;
      if (await targetFile.exists()) {
        final existingContent = await targetFile.readAsString();
        await backupTempFile.writeAsString(existingContent, flush: true);
        if (await backupFile.exists()) {
          await backupFile.delete();
        }
        await backupTempFile.rename(backupFile.path);
        backupCreated = true;
      }

      // 4. Atomowa podmiana pliku docelowego .json
      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      await tempFile.rename(targetFile.path);

      return BackupAndWriteReceipt(
        success: true,
        saveId: saveId,
        targetPath: targetFile.path,
        backupPath: backupCreated ? backupFile.path : null,
        backupCreated: backupCreated,
        checksum: checksum,
        schemaVersion: schemaVersion,
        payloadBytes: payloadBytes,
        writtenAtUtc: nowUtc,
      );
    } catch (e) {
      return BackupAndWriteReceipt(
        success: false,
        saveId: saveId,
        targetPath: targetFile.path,
        backupPath: backupFile.path,
        backupCreated: false,
        checksum: checksum,
        schemaVersion: schemaVersion,
        payloadBytes: payloadBytes,
        writtenAtUtc: nowUtc,
        errorMessage: 'Błąd atomowego zapisu z kopią .bak: $e',
      );
    }
  }

  /// Wczytuje, weryfikuje sumę kontrolną, a w razie potrzeby odzyskuje z `.bak`
  /// i automatycznie migruje oraz uzupełnia brakujące pola z nowszych paczek zadań.
  Future<SaveIntegrityAuditReport> verifyAndRepairSave(
    String saveId, {
    bool persistRepairedSave = true,
  }) async {
    final dir = await resolveSavesDirectory();
    final targetFile = File('${dir.path}${Platform.pathSeparator}$saveId.json');
    final backupFile = File('${dir.path}${Platform.pathSeparator}$saveId.bak');
    final hasBackup = await backupFile.exists();
    final now = DateTime.now().toUtc();

    if (!await targetFile.exists() && !hasBackup) {
      return SaveIntegrityAuditReport(
        saveId: saveId,
        status: SaveIntegrityStatus.notFound,
        detectedSchemaVersion: 0,
        targetSchemaVersion: currentSchemaVersion,
        expectedChecksum: null,
        actualChecksum: null,
        payloadBytes: 0,
        hasBackupFile: false,
        auditedAtUtc: now,
        summaryMessage: 'Nie znaleziono pliku zapisu ani kopii zapasowej .bak.',
      );
    }

    String? sourceRaw;
    bool recoveredFromBackup = false;
    final List<IntegrityIssue> collectedIssues = [];

    if (await targetFile.exists()) {
      sourceRaw = await targetFile.readAsString();
      final primaryCheck = verifyRawJsonContent(
        saveId: saveId,
        rawContent: sourceRaw,
        hasBackupFile: hasBackup,
      );

      if (primaryCheck.status == SaveIntegrityStatus.checksumMismatch ||
          primaryCheck.status == SaveIntegrityStatus.corruptedJson) {
        collectedIssues.addAll(primaryCheck.issues);
        if (hasBackup) {
          final bakRaw = await backupFile.readAsString();
          final bakCheck = verifyRawJsonContent(
            saveId: saveId,
            rawContent: bakRaw,
            hasBackupFile: true,
          );
          if (bakCheck.status != SaveIntegrityStatus.checksumMismatch &&
              bakCheck.status != SaveIntegrityStatus.corruptedJson) {
            sourceRaw = bakRaw;
            recoveredFromBackup = true;
            collectedIssues.add(
              const IntegrityIssue(
                code: 'FALLBACK_TO_BACKUP',
                jsonPath: r'$',
                message:
                    'Plik główny był uszkodzony — automatycznie odzyskano stan z kopii .bak.',
                severity: IntegrityIssueSeverity.warning,
              ),
            );
          } else {
            return primaryCheck;
          }
        } else {
          return primaryCheck;
        }
      }
    } else if (hasBackup) {
      sourceRaw = await backupFile.readAsString();
      recoveredFromBackup = true;
      collectedIssues.add(
        const IntegrityIssue(
          code: 'RESTORED_MISSING_PRIMARY_FROM_BAK',
          jsonPath: r'$',
          message:
              'Brak pliku głównego .json — przywrócono stan z kopii zapasowej .bak.',
          severity: IntegrityIssueSeverity.warning,
        ),
      );
    }

    if (sourceRaw == null) {
      return SaveIntegrityAuditReport(
        saveId: saveId,
        status: SaveIntegrityStatus.corruptedJson,
        detectedSchemaVersion: 0,
        targetSchemaVersion: currentSchemaVersion,
        expectedChecksum: null,
        actualChecksum: null,
        payloadBytes: 0,
        hasBackupFile: hasBackup,
        auditedAtUtc: now,
        summaryMessage: 'Nie udało się odczytać danych zapisu.',
      );
    }

    final envelope = IntegritySaveEnvelope.tryParse(sourceRaw);
    int detectedVersion = envelope?.schemaVersion ?? 1;
    final List<String> migrationHistory =
        List<String>.from(envelope?.migrationHistory ?? const <String>[]);
    final Map<String, dynamic> workingPayload = envelope != null
        ? (jsonDecode(jsonEncode(envelope.payload)) as Map<String, dynamic>)
        : (jsonDecode(sourceRaw) as Map<String, dynamic>);

    final List<RepairedFieldRecord> repairedFields = [];
    final List<SchemaMigrationStep> appliedMigrations = [];

    migrateAndRepairPayloadInPlace(
      payload: workingPayload,
      fromSchemaVersion: detectedVersion,
      repairedFields: repairedFields,
      appliedMigrations: appliedMigrations,
    );

    final CareerSave hydratedSave = CareerSave.fromJson(workingPayload);
    final newChecksum = computeCanonicalPayloadChecksum(workingPayload);
    final payloadBytes = utf8.encode(jsonEncode(workingPayload)).length;

    final bool didModify = recoveredFromBackup ||
        detectedVersion < currentSchemaVersion ||
        repairedFields.isNotEmpty ||
        envelope == null;

    if (persistRepairedSave && didModify) {
      for (final step in appliedMigrations) {
        migrationHistory.add(
          'v${step.fromVersion}->v${step.toVersion}@${now.toIso8601String()}',
        );
      }
      await writePayloadWithBackup(
        saveId: saveId,
        payload: workingPayload,
        schemaVersion: currentSchemaVersion,
        migrationHistory: migrationHistory,
      );
    }

    final SaveIntegrityStatus finalStatus;
    if (recoveredFromBackup) {
      finalStatus = SaveIntegrityStatus.restoredFromBackup;
    } else if (didModify) {
      finalStatus = SaveIntegrityStatus.repairedAndMigrated;
    } else {
      finalStatus = SaveIntegrityStatus.valid;
    }

    return SaveIntegrityAuditReport(
      saveId: saveId,
      status: finalStatus,
      detectedSchemaVersion: detectedVersion,
      targetSchemaVersion: currentSchemaVersion,
      expectedChecksum: envelope?.checksum ?? newChecksum,
      actualChecksum: newChecksum,
      payloadBytes: payloadBytes,
      hasBackupFile: hasBackup || (persistRepairedSave && didModify),
      auditedAtUtc: now,
      issues: collectedIssues,
      repairedFields: repairedFields,
      appliedMigrations: appliedMigrations,
      careerSave: hydratedSave,
      summaryMessage: _buildAuditSummary(
        status: finalStatus,
        detectedVersion: detectedVersion,
        repairedCount: repairedFields.length,
        recoveredFromBackup: recoveredFromBackup,
      ),
    );
  }

  /// Audytuje wszystkie pliki `.json` w katalogu zapisów (bez modyfikacji plików).
  Future<List<SaveIntegrityAuditReport>> auditAllSavesInDirectory() async {
    final dir = await resolveSavesDirectory();
    if (!await dir.exists()) return const [];

    final entities = dir.listSync();
    final List<SaveIntegrityAuditReport> reports = [];
    final Set<String> seenSaveIds = {};

    for (final entity in entities) {
      if (entity is File && entity.path.endsWith('.json')) {
        final fileName =
            entity.uri.pathSegments.isNotEmpty ? entity.uri.pathSegments.last : '';
        final saveId = fileName.replaceAll('.json', '');
        if (saveId.isEmpty || seenSaveIds.contains(saveId)) continue;
        seenSaveIds.add(saveId);

        final raw = await entity.readAsString();
        final bakFile = File('${dir.path}${Platform.pathSeparator}$saveId.bak');
        reports.add(
          verifyRawJsonContent(
            saveId: saveId,
            rawContent: raw,
            hasBackupFile: await bakFile.exists(),
          ),
        );
      }
    }

    reports.sort((a, b) => a.saveId.compareTo(b.saveId));
    return reports;
  }

  /// Migruje i bezbłędnie uzupełnia brakujące pola ze wszystkich paczek zadań
  /// (infrastruktura klubu, liderzy franczyzowi, akademia U23, profil mleczanowy,
  /// stan zdrowia/formy, kontuzje, dzikie karty i spójność zakresów liczbowych).
  static void migrateAndRepairPayloadInPlace({
    required Map<String, dynamic> payload,
    required int fromSchemaVersion,
    required List<RepairedFieldRecord> repairedFields,
    required List<SchemaMigrationStep> appliedMigrations,
  }) {
    final nowIso = DateTime.now().toUtc().toIso8601String();

    // --- KROK 1 (v1 -> v2): Podstawowe metadane i infrastruktura klubu ---
    int v2Added = 0;
    v2Added += _ensureStringField(
      payload,
      'id',
      'save_repaired_${DateTime.now().millisecondsSinceEpoch}',
      r'$.id',
      'Brak identyfikatora zapisu',
      repairedFields,
    );
    v2Added += _ensureStringField(
      payload,
      'saveName',
      'Kariera Odzyskana',
      r'$.saveName',
      'Brak nazwy zapisu',
      repairedFields,
    );
    v2Added += _ensureIsoDateField(
      payload,
      'createdAt',
      nowIso,
      r'$.createdAt',
      'Brak lub błędny format daty utworzenia',
      repairedFields,
    );
    v2Added += _ensureIsoDateField(
      payload,
      'lastSavedAt',
      nowIso,
      r'$.lastSavedAt',
      'Brak lub błędny format daty ostatniego zapisu',
      repairedFields,
    );
    v2Added += _ensureIsoDateField(
      payload,
      'currentDate',
      '2026-01-15T08:00:00.000Z',
      r'$.currentDate',
      'Brak lub błędny format bieżącej daty kalendarza',
      repairedFields,
    );
    v2Added += _ensureStringField(
      payload,
      'difficulty',
      'normal',
      r'$.difficulty',
      'Brak poziomu trudności',
      repairedFields,
    );
    v2Added += _ensureStringField(
      payload,
      'playerManagerName',
      'Dyrektor Sportowy',
      r'$.playerManagerName',
      'Brak nazwy menedżera',
      repairedFields,
    );
    v2Added += _ensureIntField(
      payload,
      'currentSeasonYear',
      2026,
      r'$.currentSeasonYear',
      'Brak roku sezonu',
      repairedFields,
      min: 2020,
      max: 2100,
    );
    v2Added += _ensureIntField(
      payload,
      'managerReputation',
      50,
      r'$.managerReputation',
      'Brak lub przekroczona reputacja menedżera (1–100)',
      repairedFields,
      min: 1,
      max: 100,
    );
    v2Added += _ensureIntField(
      payload,
      'serviceCourseLevel',
      1,
      r'$.serviceCourseLevel',
      'Brak poziomu zaplecza Service Course (1–5)',
      repairedFields,
      min: 1,
      max: 5,
    );
    v2Added += _ensureIntField(
      payload,
      'windTunnelLevel',
      1,
      r'$.windTunnelLevel',
      'Brak poziomu tunelu aerodynamicznego (1–5)',
      repairedFields,
      min: 1,
      max: 5,
    );
    v2Added += _ensureIntField(
      payload,
      'medicalCenterLevel',
      1,
      r'$.medicalCenterLevel',
      'Brak poziomu centrum medycznego (1–5)',
      repairedFields,
      min: 1,
      max: 5,
    );

    if (fromSchemaVersion < 2 || v2Added > 0) {
      appliedMigrations.add(
        SchemaMigrationStep(
          fromVersion: fromSchemaVersion < 2 ? 1 : currentSchemaVersion,
          toVersion: 2,
          description: 'Uzupełnienie metadanych kariery i poziomów infrastruktury klubu.',
          fieldsAddedCount: v2Added,
        ),
      );
    }

    // --- KROK 2 (v2 -> v3): Rozszerzone kolekcje kariery, akademia U23, dzikie karty ---
    int v3Added = 0;
    v3Added += _ensureListField(
      payload,
      'scoutedRiderIds',
      r'$.scoutedRiderIds',
      'Brak listy obserwowanych kolarzy',
      repairedFields,
    );
    v3Added += _ensureListField(
      payload,
      'contractOffers',
      r'$.contractOffers',
      'Brak listy ofert kontraktowych',
      repairedFields,
    );
    v3Added += _ensureListField(
      payload,
      'financeLedger',
      r'$.financeLedger',
      'Brak księgi finansowej',
      repairedFields,
    );
    v3Added += _ensureListField(
      payload,
      'trophiesWon',
      r'$.trophiesWon',
      'Brak listy trofeów',
      repairedFields,
    );
    v3Added += _ensureListField(
      payload,
      'franchiseLeaders',
      r'$.franchiseLeaders',
      'Brak listy liderów franczyzowych',
      repairedFields,
    );
    v3Added += _ensureListField(
      payload,
      'dedicatedSquads',
      r'$.dedicatedSquads',
      'Brak listy dedykowanych pociągów',
      repairedFields,
    );
    v3Added += _ensureListField(
      payload,
      'wildcardApplications',
      r'$.wildcardApplications',
      'Brak wniosków o dzikie karty',
      repairedFields,
    );
    v3Added += _ensureListField(
      payload,
      'scoutingProspects',
      r'$.scoutingProspects',
      'Brak puli młodych talentów skautingowych',
      repairedFields,
    );
    v3Added += _ensureListField(
      payload,
      'teams',
      r'$.teams',
      'Brak listy drużyn',
      repairedFields,
    );
    v3Added += _ensureListField(
      payload,
      'riders',
      r'$.riders',
      'Brak listy kolarzy',
      repairedFields,
    );

    if (payload['youthAcademy'] is! Map<String, dynamic>) {
      payload['youthAcademy'] = <String, dynamic>{
        'academyLevel': 1,
        'annualBudgetEur': 150000,
        'u23Roster': const <dynamic>[],
        'graduatedRiderIds': const <dynamic>[],
      };
      v3Added++;
      repairedFields.add(
        const RepairedFieldRecord(
          jsonPath: r'$.youthAcademy',
          reason: 'Brak obiektu Akademii Młodzieżowej U23',
          appliedValueSummary: 'YouthAcademy(level=1)',
        ),
      );
    }

    if (payload['calendar'] is! Map<String, dynamic>) {
      final int year = (payload['currentSeasonYear'] as num?)?.toInt() ?? 2026;
      payload['calendar'] = <String, dynamic>{
        'seasonYear': year,
        'races': const <dynamic>[],
      };
      v3Added++;
      repairedFields.add(
        RepairedFieldRecord(
          jsonPath: r'$.calendar',
          reason: 'Brak obiektu kalendarza sezonu',
          appliedValueSummary: 'SeasonCalendar($year)',
        ),
      );
    }

    if (fromSchemaVersion < 3 || v3Added > 0) {
      appliedMigrations.add(
        SchemaMigrationStep(
          fromVersion: fromSchemaVersion < 3 ? 2 : currentSchemaVersion,
          toVersion: 3,
          description:
              'Migracja kolekcji skautingu, akademii U23, dzikich kart oraz franczyz.',
          fieldsAddedCount: v3Added,
        ),
      );
    }

    // --- KROK 3 (v3 -> v4): Głęboka migracja modeli drużyn i kolarzy (Lactate/Lab, Health, Skills) ---
    int v4Added = 0;
    final teams = payload['teams'];
    if (teams is List) {
      for (int i = 0; i < teams.length; i++) {
        final t = teams[i];
        if (t is Map<String, dynamic>) {
          v4Added += _repairTeamMap(t, i, repairedFields);
        }
      }
      if (payload['playerTeamId'] is! String ||
          (payload['playerTeamId'] as String).trim().isEmpty) {
        final fallbackTeamId = teams.isNotEmpty && teams.first is Map
            ? ((teams.first as Map)['id']?.toString() ?? 'team_player_default')
            : 'team_player_default';
        payload['playerTeamId'] = fallbackTeamId;
        v4Added++;
        repairedFields.add(
          RepairedFieldRecord(
            jsonPath: r'$.playerTeamId',
            reason: 'Brak identyfikatora drużyny gracza',
            appliedValueSummary: fallbackTeamId,
          ),
        );
      }
    }

    final riders = payload['riders'];
    if (riders is List) {
      for (int i = 0; i < riders.length; i++) {
        final r = riders[i];
        if (r is Map<String, dynamic>) {
          v4Added += _repairRiderMap(r, i, repairedFields);
        }
      }
    }

    if (fromSchemaVersion < 4 || v4Added > 0) {
      appliedMigrations.add(
        SchemaMigrationStep(
          fromVersion: fromSchemaVersion < 4 ? 3 : currentSchemaVersion,
          toVersion: 4,
          description:
              'Głębokie uzupełnienie pól drużyn i kolarzy (profil mleczanowy, zdrowie, umiejętności).',
          fieldsAddedCount: v4Added,
        ),
      );
    }
  }

  static int _repairTeamMap(
    Map<String, dynamic> team,
    int index,
    List<RepairedFieldRecord> repairedFields,
  ) {
    int count = 0;
    final prefix = r'$.teams[' '$index]';
    count += _ensureStringField(
      team,
      'id',
      'team_repaired_$index',
      '$prefix.id',
      'Brak ID drużyny',
      repairedFields,
    );
    count += _ensureStringField(
      team,
      'name',
      'Drużyna Odzyskana #$index',
      '$prefix.name',
      'Brak nazwy drużyny',
      repairedFields,
    );
    count += _ensureStringField(
      team,
      'division',
      'worldTour',
      '$prefix.division',
      'Brak dywizji drużyny',
      repairedFields,
    );
    count += _ensureStringField(
      team,
      'countryIso',
      team['countryCode']?.toString() ?? 'PL',
      '$prefix.countryIso',
      'Brak kodu kraju ISO drużyny',
      repairedFields,
    );
    count += _ensureStringField(
      team,
      'primaryJerseyColorHex',
      '#8E4A49',
      '$prefix.primaryJerseyColorHex',
      'Brak koloru podstawowego koszulki',
      repairedFields,
    );
    count += _ensureStringField(
      team,
      'secondaryJerseyColorHex',
      '#D4AF37',
      '$prefix.secondaryJerseyColorHex',
      'Brak koloru drugorzędnego koszulki',
      repairedFields,
    );
    count += _ensureStringField(
      team,
      'accentJerseyColorHex',
      '#F3F4F6',
      '$prefix.accentJerseyColorHex',
      'Brak koloru akcentowego koszulki',
      repairedFields,
    );
    count += _ensureIntField(
      team,
      'cashBalanceEur',
      2000000,
      '$prefix.cashBalanceEur',
      'Brak salda gotówkowego drużyny',
      repairedFields,
    );
    count += _ensureIntField(
      team,
      'monthlyBurnRateEur',
      180000,
      '$prefix.monthlyBurnRateEur',
      'Brak miesięcznego kosztu utrzymania drużyny',
      repairedFields,
      min: 0,
    );
    count += _ensureListField(
      team,
      'rosterRiderIds',
      '$prefix.rosterRiderIds',
      'Brak listy ID kolarzy drużyny',
      repairedFields,
    );
    count += _ensureIntField(
      team,
      'uciPointsSeason',
      0,
      '$prefix.uciPointsSeason',
      'Brak punktów UCI w sezonie',
      repairedFields,
      min: 0,
    );
    count += _ensureIntField(
      team,
      'uciPointsThreeYearCycle',
      0,
      '$prefix.uciPointsThreeYearCycle',
      'Brak punktów 3-letniego cyklu UCI',
      repairedFields,
      min: 0,
    );
    if (team['staff'] is! Map<String, dynamic>) {
      team['staff'] = <String, dynamic>{
        'trainersLevel': 3,
        'sportsDirectorsLevel': 3,
        'doctorsLevel': 3,
        'mechanicsLevel': 3,
        'scoutsLevel': 3,
      };
      count++;
      repairedFields.add(
        RepairedFieldRecord(
          jsonPath: '$prefix.staff',
          reason: 'Brak obiektu sztabu drużyny',
          appliedValueSummary: 'TeamStaff(level=3)',
        ),
      );
    }
    if (team['bikeDeal'] is! Map<String, dynamic>) {
      team['bikeDeal'] = <String, dynamic>{
        'manufacturerId': 'brand_default',
        'manufacturerName': 'Velox Carbon',
        'prestigeLevel': 3,
        'annualCashContributionEur': 350000,
        'freeBikesQuota': 60,
        'researchAndDevelopmentLevel': 75,
        'suppliedFrameIds': const <dynamic>[],
        'suppliedWheelsetIds': const <dynamic>[],
        'contractYearsLeft': 2,
        'minimumUciRankingRequired': 18,
      };
      count++;
      repairedFields.add(
        RepairedFieldRecord(
          jsonPath: '$prefix.bikeDeal',
          reason: 'Brak kontraktu sprzętowego producenta rowerów',
          appliedValueSummary: 'BikeManufacturerDeal(Velox Carbon)',
        ),
      );
    }
    return count;
  }

  static int _repairRiderMap(
    Map<String, dynamic> rider,
    int index,
    List<RepairedFieldRecord> repairedFields,
  ) {
    int count = 0;
    final prefix = r'$.riders[' '$index]';

    final physiology = rider['physiology'];
    int ftp = 380;
    if (physiology is Map<String, dynamic>) {
      ftp = (physiology['ftpWatts'] as num?)?.toInt() ?? 380;
      count += _ensureIntField(
        physiology,
        'ftpWatts',
        380,
        '$prefix.physiology.ftpWatts',
        'Brak wartości FTP kolarza',
        repairedFields,
        min: 180,
        max: 550,
      );
    }

    if (rider['lactateAndLabProfile'] is! Map<String, dynamic>) {
      rider['lactateAndLabProfile'] = <String, dynamic>{
        'lt1Watts': (ftp * 0.78).round(),
        'lt2Watts': ftp,
        'vlaMax': 0.42,
        'vo2Max': 78.0,
      };
      count++;
      repairedFields.add(
        RepairedFieldRecord(
          jsonPath: '$prefix.lactateAndLabProfile',
          reason: 'Brak profilu mleczanowego LT1/LT2/VLaMax (dodany w nowszej paczce)',
          appliedValueSummary: 'LT1=${(ftp * 0.78).round()}W, LT2=${ftp}W',
        ),
      );
    }

    final health = rider['health'];
    if (health is Map<String, dynamic>) {
      count += _ensureIntField(
        health,
        'morale',
        75,
        '$prefix.health.morale',
        'Brak morale kolarza',
        repairedFields,
        min: 0,
        max: 100,
      );
    }

    return count;
  }

  static int _ensureStringField(
    Map<String, dynamic> map,
    String key,
    String defaultValue,
    String jsonPath,
    String reason,
    List<RepairedFieldRecord> repairedFields,
  ) {
    final current = map[key];
    if (current is! String || current.trim().isEmpty) {
      map[key] = defaultValue;
      repairedFields.add(
        RepairedFieldRecord(
          jsonPath: jsonPath,
          reason: reason,
          appliedValueSummary: defaultValue,
        ),
      );
      return 1;
    }
    return 0;
  }

  static int _ensureIsoDateField(
    Map<String, dynamic> map,
    String key,
    String defaultIso,
    String jsonPath,
    String reason,
    List<RepairedFieldRecord> repairedFields,
  ) {
    final current = map[key];
    if (current is! String || DateTime.tryParse(current) == null) {
      map[key] = defaultIso;
      repairedFields.add(
        RepairedFieldRecord(
          jsonPath: jsonPath,
          reason: reason,
          appliedValueSummary: defaultIso,
        ),
      );
      return 1;
    }
    return 0;
  }

  static int _ensureIntField(
    Map<String, dynamic> map,
    String key,
    int defaultValue,
    String jsonPath,
    String reason,
    List<RepairedFieldRecord> repairedFields, {
    int? min,
    int? max,
  }) {
    final current = map[key];
    if (current is! num) {
      map[key] = defaultValue;
      repairedFields.add(
        RepairedFieldRecord(
          jsonPath: jsonPath,
          reason: reason,
          appliedValueSummary: '$defaultValue',
        ),
      );
      return 1;
    }
    int val = current.toInt();
    if (min != null && val < min) {
      map[key] = min;
      repairedFields.add(
        RepairedFieldRecord(
          jsonPath: jsonPath,
          reason: '$reason (poniżej minimum $min)',
          appliedValueSummary: '$min',
        ),
      );
      return 1;
    }
    if (max != null && val > max) {
      map[key] = max;
      repairedFields.add(
        RepairedFieldRecord(
          jsonPath: jsonPath,
          reason: '$reason (powyżej maksimum $max)',
          appliedValueSummary: '$max',
        ),
      );
      return 1;
    }
    return 0;
  }

  static int _ensureListField(
    Map<String, dynamic> map,
    String key,
    String jsonPath,
    String reason,
    List<RepairedFieldRecord> repairedFields,
  ) {
    if (map[key] is! List) {
      map[key] = <dynamic>[];
      repairedFields.add(
        RepairedFieldRecord(
          jsonPath: jsonPath,
          reason: reason,
          appliedValueSummary: '[]',
        ),
      );
      return 1;
    }
    return 0;
  }

  static String _buildAuditSummary({
    required SaveIntegrityStatus status,
    required int detectedVersion,
    required int repairedCount,
    required bool recoveredFromBackup,
  }) {
    if (recoveredFromBackup) {
      return 'Odzyskano z kopii .bak i zmigrowano do schematu v$currentSchemaVersion ($repairedCount uzupełnionych pól).';
    }
    switch (status) {
      case SaveIntegrityStatus.valid:
        return 'Plik zapisu jest w 100% spójny (schemat v$detectedVersion).';
      case SaveIntegrityStatus.repairedAndMigrated:
        return 'Zmigrowano z v$detectedVersion do v$currentSchemaVersion i uzupełniono $repairedCount pól.';
      case SaveIntegrityStatus.legacyNeedsMigration:
        return 'Wymaga migracji v$detectedVersion -> v$currentSchemaVersion.';
      case SaveIntegrityStatus.restoredFromBackup:
        return 'Przywrócono z kopii zapasowej .bak.';
      case SaveIntegrityStatus.checksumMismatch:
        return 'Błąd sumy kontrolnej JSON.';
      case SaveIntegrityStatus.corruptedJson:
        return 'Uszkodzony plik JSON.';
      case SaveIntegrityStatus.notFound:
        return 'Nie znaleziono pliku zapisu.';
    }
  }
}

/// Stan kontrolera diagnostyki i naprawy bazy zapisów w Riverpod.
class DatabaseIntegrityRepairState {
  final bool isBusy;
  final List<SaveIntegrityAuditReport> reports;
  final SaveIntegrityAuditReport? selectedReport;
  final String? lastActionMessage;

  const DatabaseIntegrityRepairState({
    this.isBusy = false,
    this.reports = const [],
    this.selectedReport,
    this.lastActionMessage,
  });

  DatabaseIntegrityRepairState copyWith({
    bool? isBusy,
    List<SaveIntegrityAuditReport>? reports,
    SaveIntegrityAuditReport? selectedReport,
    String? lastActionMessage,
  }) {
    return DatabaseIntegrityRepairState(
      isBusy: isBusy ?? this.isBusy,
      reports: reports ?? this.reports,
      selectedReport: selectedReport ?? this.selectedReport,
      lastActionMessage: lastActionMessage ?? this.lastActionMessage,
    );
  }
}

/// Notifier zarządzający audytem, tworzeniem kopii `.bak` oraz naprawą zapisów.
class DatabaseIntegrityRepairNotifier
    extends StateNotifier<DatabaseIntegrityRepairState> {
  final DatabaseBackupAndIntegrityRepair _service;

  DatabaseIntegrityRepairNotifier({
    DatabaseBackupAndIntegrityRepair? service,
  })  : _service = service ?? DatabaseBackupAndIntegrityRepair(),
        super(const DatabaseIntegrityRepairState());

  Future<void> scanAllSaves() async {
    state = state.copyWith(isBusy: true);
    try {
      final reports = await _service.auditAllSavesInDirectory();
      state = state.copyWith(
        isBusy: false,
        reports: reports,
        selectedReport: reports.isNotEmpty ? reports.first : null,
        lastActionMessage:
            'Przeskanowano ${reports.length} plików zapisu na dysku.',
      );
    } catch (e) {
      state = state.copyWith(
        isBusy: false,
        lastActionMessage: 'Błąd skanowania zapisów: $e',
      );
    }
  }

  Future<void> repairAndMigrateSave(String saveId) async {
    state = state.copyWith(isBusy: true);
    try {
      final report = await _service.verifyAndRepairSave(
        saveId,
        persistRepairedSave: true,
      );
      final updatedList = state.reports
          .map((r) => r.saveId == saveId ? report : r)
          .toList(growable: false);
      state = state.copyWith(
        isBusy: false,
        reports: updatedList.isEmpty ? [report] : updatedList,
        selectedReport: report,
        lastActionMessage: report.summaryMessage,
      );
    } catch (e) {
      state = state.copyWith(
        isBusy: false,
        lastActionMessage: 'Błąd naprawy zapisu $saveId: $e',
      );
    }
  }

  void selectReport(SaveIntegrityAuditReport report) {
    state = state.copyWith(selectedReport: report);
  }
}

final databaseIntegrityRepairProvider = StateNotifierProvider<
    DatabaseIntegrityRepairNotifier, DatabaseIntegrityRepairState>(
  (ref) => DatabaseIntegrityRepairNotifier(),
);

/// Responsywny panel diagnostyki integralności, kopii `.bak` i migracji schematu zapisów.
class DatabaseBackupAndIntegrityRepairPanel extends ConsumerWidget {
  const DatabaseBackupAndIntegrityRepairPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(databaseIntegrityRepairProvider);
    final notifier = ref.read(databaseIntegrityRepairProvider.notifier);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 720;
        final bool isWide = constraints.maxWidth >= 1200;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2A2F3D), width: 1.0),
          ),
          padding: EdgeInsets.all(isCompact ? 14 : 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, state, notifier, isCompact),
                const SizedBox(height: 16),
                if (state.lastActionMessage != null) ...[
                  _buildStatusBanner(state.lastActionMessage!),
                  const SizedBox(height: 14),
                ],
                if (state.reports.isEmpty)
                  _buildEmptyState(notifier, state.isBusy)
                else if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: _buildReportsList(state, notifier),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 6,
                        child: _buildSelectedDetails(state, notifier),
                      ),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildReportsList(state, notifier),
                      const SizedBox(height: 16),
                      _buildSelectedDetails(state, notifier),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    DatabaseIntegrityRepairState state,
    DatabaseIntegrityRepairNotifier notifier,
    bool isCompact,
  ) {
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.verified_user_outlined,
              color: AppColors.goldAccent,
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Integralność Zapisów, Kopie .BAK i Migracje',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isCompact ? 15 : 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Weryfikacja sumy kontrolnej FNV-1a+CRC32, rotacja .bak oraz automatyczne uzupełnianie pól schematu v4.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );

    final scanButton = _InteractiveActionButton(
      label: state.isBusy ? 'Skanowanie...' : 'Skanuj Zapisy',
      icon: Icons.radar_rounded,
      accentColor: AppColors.accentBlue,
      enabled: !state.isBusy,
      onPressed: notifier.scanAllSaves,
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleBlock,
          const SizedBox(height: 12),
          scanButton,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: titleBlock),
        const SizedBox(width: 16),
        scanButton,
      ],
    );
  }

  Widget _buildStatusBanner(String message) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppColors.accentBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    DatabaseIntegrityRepairNotifier notifier,
    bool isBusy,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.storage_rounded,
            size: 36,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 10),
          const Text(
            'Brak wczytanych raportów integralności',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Uruchom skanowanie, aby zweryfikować sumy kontrolne JSON oraz kopie zapasowe .bak.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          _InteractiveActionButton(
            label: 'Rozpocznij Audyt',
            icon: Icons.play_arrow_rounded,
            accentColor: AppColors.goldAccent,
            enabled: !isBusy,
            onPressed: notifier.scanAllSaves,
          ),
        ],
      ),
    );
  }

  Widget _buildReportsList(
    DatabaseIntegrityRepairState state,
    DatabaseIntegrityRepairNotifier notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final report in state.reports) ...[
          _SaveReportTile(
            report: report,
            isSelected: state.selectedReport?.saveId == report.saveId,
            onTap: () => notifier.selectReport(report),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildSelectedDetails(
    DatabaseIntegrityRepairState state,
    DatabaseIntegrityRepairNotifier notifier,
  ) {
    final report = state.selectedReport;
    if (report == null) return const SizedBox.shrink();

    final statusColor = _statusColor(report.status);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  report.saveId,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.45)),
                ),
                child: Text(
                  report.status.labelPl,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            report.summaryMessage,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _TelemetryChip(
                label: 'Schemat',
                value:
                    'v${report.detectedSchemaVersion} / v${report.targetSchemaVersion}',
              ),
              _TelemetryChip(
                label: 'Rozmiar',
                value: '${report.payloadBytes} B',
              ),
              _TelemetryChip(
                label: 'Kopia .bak',
                value: report.hasBackupFile ? 'AKTYWNA' : 'BRAK',
              ),
            ],
          ),
          const SizedBox(height: 14),
          _InteractiveActionButton(
            label: 'Napraw, Zmigruj i Zapisz z .BAK',
            icon: Icons.build_circle_outlined,
            accentColor: AppColors.primaryAccent,
            enabled: !state.isBusy,
            onPressed: () => notifier.repairAndMigrateSave(report.saveId),
          ),
        ],
      ),
    );
  }

  static Color _statusColor(SaveIntegrityStatus status) {
    switch (status) {
      case SaveIntegrityStatus.valid:
      case SaveIntegrityStatus.repairedAndMigrated:
      case SaveIntegrityStatus.restoredFromBackup:
        return AppColors.statusSuccess;
      case SaveIntegrityStatus.legacyNeedsMigration:
        return AppColors.amberWarning;
      case SaveIntegrityStatus.checksumMismatch:
      case SaveIntegrityStatus.corruptedJson:
      case SaveIntegrityStatus.notFound:
        return AppColors.crimsonAlert;
    }
  }
}

class _SaveReportTile extends StatefulWidget {
  final SaveIntegrityAuditReport report;
  final bool isSelected;
  final VoidCallback onTap;

  const _SaveReportTile({
    required this.report,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SaveReportTile> createState() => _SaveReportTileState();
}

class _SaveReportTileState extends State<_SaveReportTile> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isSelected
        ? AppColors.goldAccent
        : (_focused || _hovered)
            ? AppColors.accentBlue
            : const Color(0xFF2A2F3D);

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.99 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _hovered ? const Color(0xFF262B37) : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: Row(
              children: [
                Icon(
                  widget.report.status.isHealthy
                      ? Icons.check_circle_outline
                      : Icons.warning_amber_rounded,
                  color: DatabaseBackupAndIntegrityRepairPanel._statusColor(
                    widget.report.status,
                  ),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.report.saveId,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'v${widget.report.detectedSchemaVersion}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    fontFeatures: [FontFeature.tabularFigures()],
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TelemetryChip extends StatelessWidget {
  final String label;
  final String value;

  const _TelemetryChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              fontFeatures: [FontFeature.tabularFigures()],
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractiveActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final bool enabled;
  final VoidCallback onPressed;

  const _InteractiveActionButton({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_InteractiveActionButton> createState() =>
      _InteractiveActionButtonState();
}

class _InteractiveActionButtonState extends State<_InteractiveActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = !widget.enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.45)
        : _pressed
            ? widget.accentColor.withValues(alpha: 0.35)
            : _hovered
                ? widget.accentColor.withValues(alpha: 0.25)
                : widget.accentColor.withValues(alpha: 0.16);

    final borderColor = !widget.enabled
        ? const Color(0xFF2A2F3D)
        : _focused
            ? AppColors.goldAccent
            : widget.accentColor.withValues(alpha: _hovered ? 0.9 : 0.6);

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.enabled ? widget.onPressed : null,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 16,
                  color: widget.enabled
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: widget.enabled
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
