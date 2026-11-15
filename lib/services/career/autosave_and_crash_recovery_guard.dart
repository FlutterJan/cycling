import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/career/career_save.dart';

/// Powód wyzwolenia automatycznego zapisu stanu kariery.
enum AutosaveTrigger {
  periodic,
  dayAdvanced,
  preStageBriefing,
  postStageResult,
  transferCompleted,
  manualGuard,
  crashRecoveryRestore;

  String toJson() => name;

  static AutosaveTrigger fromJson(String value) {
    return AutosaveTrigger.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => AutosaveTrigger.periodic,
    );
  }
}

/// Wynik weryfikacji integralności i odzyskiwania pliku zapisu po awarii.
enum SaveRecoveryStatus {
  healthy,
  recoveredFromTemp,
  recoveredFromBackup,
  notFound,
  corruptedUnrecoverable;

  bool get isUsable =>
      this == SaveRecoveryStatus.healthy ||
      this == SaveRecoveryStatus.recoveredFromTemp ||
      this == SaveRecoveryStatus.recoveredFromBackup;
}

/// Szczegółowy raport z operacji odczytu lub odzyskiwania zapisu kariery.
class SaveRecoveryResult {
  final SaveRecoveryStatus status;
  final CareerSave? save;
  final String? checksum;
  final String? sourceFilePath;
  final String? diagnosticMessage;

  const SaveRecoveryResult({
    required this.status,
    this.save,
    this.checksum,
    this.sourceFilePath,
    this.diagnosticMessage,
  });

  bool get wasRecovered =>
      status == SaveRecoveryStatus.recoveredFromTemp ||
      status == SaveRecoveryStatus.recoveredFromBackup;
}

/// Wynik atomowego zapisu transakcyjnego.
class TransactionalSaveReceipt {
  final bool success;
  final String targetPath;
  final String checksum;
  final int payloadBytes;
  final DateTime savedAtUtc;
  final AutosaveTrigger trigger;
  final String? errorMessage;

  const TransactionalSaveReceipt({
    required this.success,
    required this.targetPath,
    required this.checksum,
    required this.payloadBytes,
    required this.savedAtUtc,
    required this.trigger,
    this.errorMessage,
  });
}

/// Punkt kontrolny zapisywany automatycznie przed startem każdego etapu.
///
/// Umożliwia natychmiastowe wznowienie kariery dokładnie przed odprawą tego etapu
/// w razie nieprzewidzianego zamknięcia aplikacji lub utraty zasilania w trakcie wyścigu.
class PreStageCheckpoint {
  final String checkpointId;
  final String careerSaveId;
  final String raceId;
  final String raceName;
  final String stageId;
  final int stageNumber;
  final String stageName;
  final List<String> selectedRiderIds;
  final bool isActiveInProgress;
  final DateTime createdAtUtc;
  final CareerSave careerSave;

  const PreStageCheckpoint({
    required this.checkpointId,
    required this.careerSaveId,
    required this.raceId,
    required this.raceName,
    required this.stageId,
    required this.stageNumber,
    required this.stageName,
    required this.selectedRiderIds,
    required this.isActiveInProgress,
    required this.createdAtUtc,
    required this.careerSave,
  });

  PreStageCheckpoint copyWith({
    String? checkpointId,
    String? careerSaveId,
    String? raceId,
    String? raceName,
    String? stageId,
    int? stageNumber,
    String? stageName,
    List<String>? selectedRiderIds,
    bool? isActiveInProgress,
    DateTime? createdAtUtc,
    CareerSave? careerSave,
  }) {
    return PreStageCheckpoint(
      checkpointId: checkpointId ?? this.checkpointId,
      careerSaveId: careerSaveId ?? this.careerSaveId,
      raceId: raceId ?? this.raceId,
      raceName: raceName ?? this.raceName,
      stageId: stageId ?? this.stageId,
      stageNumber: stageNumber ?? this.stageNumber,
      stageName: stageName ?? this.stageName,
      selectedRiderIds: selectedRiderIds != null
          ? List<String>.unmodifiable(selectedRiderIds)
          : this.selectedRiderIds,
      isActiveInProgress: isActiveInProgress ?? this.isActiveInProgress,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      careerSave: careerSave ?? this.careerSave,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'checkpointId': checkpointId,
      'careerSaveId': careerSaveId,
      'raceId': raceId,
      'raceName': raceName,
      'stageId': stageId,
      'stageNumber': stageNumber,
      'stageName': stageName,
      'selectedRiderIds': selectedRiderIds,
      'isActiveInProgress': isActiveInProgress,
      'createdAtUtc': createdAtUtc.toUtc().toIso8601String(),
      'careerSave': careerSave.toJson(),
    };
  }

  factory PreStageCheckpoint.fromJson(Map<String, dynamic> json) {
    return PreStageCheckpoint(
      checkpointId: json['checkpointId'] as String,
      careerSaveId: json['careerSaveId'] as String,
      raceId: json['raceId'] as String,
      raceName: json['raceName'] as String,
      stageId: json['stageId'] as String,
      stageNumber: (json['stageNumber'] as num).toInt(),
      stageName: json['stageName'] as String,
      selectedRiderIds: (json['selectedRiderIds'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(growable: false),
      isActiveInProgress: json['isActiveInProgress'] as bool? ?? true,
      createdAtUtc: DateTime.parse(json['createdAtUtc'] as String).toUtc(),
      careerSave: CareerSave.fromJson(
        json['careerSave'] as Map<String, dynamic>,
      ),
    );
  }
}

/// Wynik inspekcji punktu kontrolnego przed etapem po starcie aplikacji.
class PreStageRecoveryInspection {
  final SaveRecoveryStatus status;
  final PreStageCheckpoint? checkpoint;
  final String? diagnosticMessage;

  const PreStageRecoveryInspection({
    required this.status,
    this.checkpoint,
    this.diagnosticMessage,
  });

  bool get hasRecoverableStage =>
      status.isUsable &&
      checkpoint != null &&
      checkpoint!.isActiveInProgress;
}

/// Koperta transakcyjna zapisu JSON z sumą kontrolną i metadanymi integralności.
class _TransactionalSaveEnvelope {
  static const int currentSchemaVersion = 1;
  static const String algorithmName = 'fnv1a64+crc32';

  final int schemaVersion;
  final String checksumAlgorithm;
  final String checksum;
  final int payloadBytes;
  final String trigger;
  final DateTime savedAtUtc;
  final Map<String, dynamic> payload;

  const _TransactionalSaveEnvelope({
    required this.schemaVersion,
    required this.checksumAlgorithm,
    required this.checksum,
    required this.payloadBytes,
    required this.trigger,
    required this.savedAtUtc,
    required this.payload,
  });

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'checksumAlgorithm': checksumAlgorithm,
      'checksum': checksum,
      'payloadBytes': payloadBytes,
      'trigger': trigger,
      'savedAtUtc': savedAtUtc.toUtc().toIso8601String(),
      'payload': payload,
    };
  }

  static _TransactionalSaveEnvelope? tryParse(String rawContent) {
    if (rawContent.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(rawContent);
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
      return _TransactionalSaveEnvelope(
        schemaVersion: (decoded['schemaVersion'] as num?)?.toInt() ?? 1,
        checksumAlgorithm:
            decoded['checksumAlgorithm'] as String? ?? algorithmName,
        checksum: checksum,
        payloadBytes: payloadBytes.toInt(),
        trigger: decoded['trigger'] as String? ?? AutosaveTrigger.periodic.name,
        savedAtUtc: DateTime.parse(savedAtRaw).toUtc(),
        payload: payload,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Niezawodny strażnik integralności zapisu kariery oraz automatycznych punktów
/// kontrolnych przed startem każdego etapu (`PreStageCheckpoint`).
///
/// Gwarantuje odporność na nagłą utratę zasilania lub zamknięcie okna aplikacji:
/// 1. Każdy zapis trafia najpierw do pliku `.tmp` z natychmiastowym `flush: true`.
/// 2. Po zapisie plik `.tmp` jest ponownie odczytywany z dysku, dekodowany i
///    weryfikowany sumą kontrolną (`FNV-1a 64-bit` + `CRC-32 IEEE`) oraz rozmiarem.
/// 3. Dotychczasowy plik główny jest zabezpieczany w `.bak`, a `.tmp` atomowo
///    zastępuje plik docelowy.
/// 4. Przed odprawą każdego etapu tworzony jest `PreStageCheckpoint`, który po
///    czystym zakończeniu etapu jest oznaczany jako ukończony.
class AutosaveAndCrashRecoveryGuard {
  static const String _defaultFolderName = 'ppm_saves';
  static const String _checkpointSubfolderName = 'checkpoints';
  static const String _preStagePrefix = 'pre_stage_';

  static final List<int> _crc32Table = _buildCrc32Table();

  final Future<Directory> Function()? _directoryResolver;

  /// Tworzy instancję strażnika. W testach jednostkowych można wstrzyknąć
  /// własny [directoryResolver] zamiast katalogu `path_provider`.
  AutosaveAndCrashRecoveryGuard({
    Future<Directory> Function()? directoryResolver,
  }) : _directoryResolver = directoryResolver;

  /// Oblicza deterministyczną sumę kontrolną (`FNV-1a 64-bit` + `CRC-32`)
  /// dla zadanego łańcucha JSON w kodowaniu UTF-8.
  static String computeJsonChecksum(String jsonPayload) {
    final bytes = utf8.encode(jsonPayload);

    // 1. FNV-1a 64-bit
    BigInt fnvHash = BigInt.parse('cbf29ce484222325', radix: 16);
    final BigInt fnvPrime = BigInt.parse('100000001b3', radix: 16);
    final BigInt mask64 = BigInt.parse('ffffffffffffffff', radix: 16);

    // 2. CRC-32 IEEE 802.3
    int crc = 0xFFFFFFFF;

    for (final b in bytes) {
      fnvHash = ((fnvHash ^ BigInt.from(b)) * fnvPrime) & mask64;
      crc = _crc32Table[(crc ^ b) & 0xFF] ^ (crc >>> 8);
    }
    crc = (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;

    final fnvHex = fnvHash.toRadixString(16).padLeft(16, '0');
    final crcHex = crc.toRadixString(16).padLeft(8, '0');
    return '$fnvHex$crcHex';
  }

  static List<int> _buildCrc32Table() {
    const int polynomial = 0xEDB88320;
    return List<int>.generate(256, (int index) {
      int c = index;
      for (int bit = 0; bit < 8; bit++) {
        if ((c & 1) != 0) {
          c = polynomial ^ (c >>> 1);
        } else {
          c = c >>> 1;
        }
      }
      return c & 0xFFFFFFFF;
    }, growable: false);
  }

  /// Zwraca katalog bazowy zapisów gry (tworzy go jeśli nie istnieje).
  Future<Directory> getSavesDirectory() async {
    if (_directoryResolver != null) {
      final dir = await _directoryResolver();
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    }
    final appDocDir = await getApplicationDocumentsDirectory();
    final savesDir = Directory(
      '${appDocDir.path}${Platform.pathSeparator}$_defaultFolderName',
    );
    if (!await savesDir.exists()) {
      await savesDir.create(recursive: true);
    }
    return savesDir;
  }

  /// Zwraca podkatalog dla punktów kontrolnych `PreStageCheckpoint`.
  Future<Directory> getCheckpointsDirectory() async {
    final baseDir = await getSavesDirectory();
    final cpDir = Directory(
      '${baseDir.path}${Platform.pathSeparator}$_checkpointSubfolderName',
    );
    if (!await cpDir.exists()) {
      await cpDir.create(recursive: true);
    }
    return cpDir;
  }

  /// Atomowy zapis transakcyjny stanu kariery:
  /// `.tmp` -> weryfikacja sumy kontrolnej JSON po odczycie -> kopia `.bak` -> zamiana pliku głównego.
  Future<TransactionalSaveReceipt> saveCareerTransactional(
    CareerSave save, {
    String? customFileBaseName,
    bool isAutoSave = false,
    AutosaveTrigger trigger = AutosaveTrigger.periodic,
  }) async {
    final dir = await getSavesDirectory();
    final String baseName = customFileBaseName ??
        (isAutoSave ? 'autosave_${save.id}' : save.id);

    final targetFile = File('${dir.path}${Platform.pathSeparator}$baseName.json');
    final tempFile = File('${dir.path}${Platform.pathSeparator}$baseName.tmp');
    final backupFile = File('${dir.path}${Platform.pathSeparator}$baseName.bak');

    final nowUtc = DateTime.now().toUtc();
    final updatedSave = save.copyWith(lastSavedAt: nowUtc);

    return _writeTransactionalJson<CareerSave>(
      targetFile: targetFile,
      tempFile: tempFile,
      backupFile: backupFile,
      payloadMap: updatedSave.toJson(),
      validateModel: CareerSave.fromJson,
      trigger: trigger,
      savedAtUtc: nowUtc,
    );
  }

  /// Odczytuje stan kariery z pełną weryfikacją sumy kontrolnej i automatycznym
  /// odzyskiwaniem z `.tmp` lub `.bak` w przypadku uszkodzenia pliku głównego.
  Future<SaveRecoveryResult> loadCareerWithRecovery(
    String saveId, {
    String? customFileBaseName,
    bool isAutoSave = false,
  }) async {
    final dir = await getSavesDirectory();
    final String baseName = customFileBaseName ??
        (isAutoSave ? 'autosave_$saveId' : saveId);

    final targetFile = File('${dir.path}${Platform.pathSeparator}$baseName.json');
    final tempFile = File('${dir.path}${Platform.pathSeparator}$baseName.tmp');
    final backupFile = File('${dir.path}${Platform.pathSeparator}$baseName.bak');

    // 1. Próba odczytu i weryfikacji pliku głównego (.json)
    if (await targetFile.exists()) {
      final mainRead = await _readAndVerifyFile<CareerSave>(
        targetFile,
        CareerSave.fromJson,
      );
      if (mainRead != null) {
        await _safeDelete(tempFile);
        return SaveRecoveryResult(
          status: SaveRecoveryStatus.healthy,
          save: mainRead.model,
          checksum: mainRead.checksum,
          sourceFilePath: targetFile.path,
          diagnosticMessage: 'Zapis główny zweryfikowany poprawnie.',
        );
      }
    }

    // 2. Próba odzyskania z kompletnego pliku tymczasowego (.tmp)
    if (await tempFile.exists()) {
      final tempRead = await _readAndVerifyFile<CareerSave>(
        tempFile,
        CareerSave.fromJson,
      );
      if (tempRead != null) {
        await _promoteFileAtomically(tempFile, targetFile);
        return SaveRecoveryResult(
          status: SaveRecoveryStatus.recoveredFromTemp,
          save: tempRead.model,
          checksum: tempRead.checksum,
          sourceFilePath: targetFile.path,
          diagnosticMessage:
              'Wykryto uszkodzony lub brakujący plik główny — odzyskano zweryfikowany zapis z .tmp.',
        );
      }
      await _safeDelete(tempFile);
    }

    // 3. Próba odzyskania z kopii zapasowej (.bak)
    if (await backupFile.exists()) {
      final bakRead = await _readAndVerifyFile<CareerSave>(
        backupFile,
        CareerSave.fromJson,
      );
      if (bakRead != null) {
        await backupFile.copy(targetFile.path);
        return SaveRecoveryResult(
          status: SaveRecoveryStatus.recoveredFromBackup,
          save: bakRead.model,
          checksum: bakRead.checksum,
          sourceFilePath: targetFile.path,
          diagnosticMessage:
              'Odzyskano ostatni spójny zapis kariery z kopii zapasowej .bak.',
        );
      }
    }

    final anyExisted = await targetFile.exists() ||
        await tempFile.exists() ||
        await backupFile.exists();

    return SaveRecoveryResult(
      status: anyExisted
          ? SaveRecoveryStatus.corruptedUnrecoverable
          : SaveRecoveryStatus.notFound,
      diagnosticMessage: anyExisted
          ? 'Wszystkie kopie zapisu ($baseName) są uszkodzone i nie przeszły weryfikacji sumy kontrolnej.'
          : 'Nie znaleziono zapisu $baseName na dysku.',
    );
  }

  /// Tworzy i atomowo zapisuje punkt kontrolny `PreStageCheckpoint` tuż przed
  /// startem/odprawą etapu.
  Future<TransactionalSaveReceipt> createPreStageCheckpoint({
    required CareerSave careerSave,
    required String raceId,
    required String raceName,
    required String stageId,
    required int stageNumber,
    required String stageName,
    List<String> selectedRiderIds = const [],
  }) async {
    final cpDir = await getCheckpointsDirectory();
    final baseName = '$_preStagePrefix${careerSave.id}';
    final targetFile = File('${cpDir.path}${Platform.pathSeparator}$baseName.json');
    final tempFile = File('${cpDir.path}${Platform.pathSeparator}$baseName.tmp');
    final backupFile = File('${cpDir.path}${Platform.pathSeparator}$baseName.bak');

    final nowUtc = DateTime.now().toUtc();
    final checkpoint = PreStageCheckpoint(
      checkpointId: '${careerSave.id}_${raceId}_s$stageNumber',
      careerSaveId: careerSave.id,
      raceId: raceId,
      raceName: raceName,
      stageId: stageId,
      stageNumber: stageNumber,
      stageName: stageName,
      selectedRiderIds: List<String>.unmodifiable(selectedRiderIds),
      isActiveInProgress: true,
      createdAtUtc: nowUtc,
      careerSave: careerSave.copyWith(lastSavedAt: nowUtc),
    );

    return _writeTransactionalJson<PreStageCheckpoint>(
      targetFile: targetFile,
      tempFile: tempFile,
      backupFile: backupFile,
      payloadMap: checkpoint.toJson(),
      validateModel: PreStageCheckpoint.fromJson,
      trigger: AutosaveTrigger.preStageBriefing,
      savedAtUtc: nowUtc,
    );
  }

  /// Oznacza etap jako czysto zakończony, dezaktywując punkt kontrolny
  /// `PreStageCheckpoint`, aby nie wyświetlać fałszywego monitu odzyskiwania.
  Future<bool> markStageCompleted({
    required String careerSaveId,
    String? stageId,
  }) async {
    final inspection = await inspectPreStageCheckpoint(careerSaveId);
    final checkpoint = inspection.checkpoint;
    if (checkpoint == null) return false;
    if (stageId != null && checkpoint.stageId != stageId) {
      return false;
    }

    final cpDir = await getCheckpointsDirectory();
    final baseName = '$_preStagePrefix$careerSaveId';
    final targetFile = File('${cpDir.path}${Platform.pathSeparator}$baseName.json');
    final tempFile = File('${cpDir.path}${Platform.pathSeparator}$baseName.tmp');
    final backupFile = File('${cpDir.path}${Platform.pathSeparator}$baseName.bak');

    final completed = checkpoint.copyWith(isActiveInProgress: false);
    final receipt = await _writeTransactionalJson<PreStageCheckpoint>(
      targetFile: targetFile,
      tempFile: tempFile,
      backupFile: backupFile,
      payloadMap: completed.toJson(),
      validateModel: PreStageCheckpoint.fromJson,
      trigger: AutosaveTrigger.postStageResult,
      savedAtUtc: DateTime.now().toUtc(),
    );
    return receipt.success;
  }

  /// Sprawdza po uruchomieniu aplikacji, czy istnieje aktywny `PreStageCheckpoint`
  /// dla danej kariery (oznaczający nieoczekiwane zamknięcie w trakcie wyścigu).
  Future<PreStageRecoveryInspection> inspectPreStageCheckpoint(
    String careerSaveId,
  ) async {
    final cpDir = await getCheckpointsDirectory();
    final baseName = '$_preStagePrefix$careerSaveId';
    final targetFile = File('${cpDir.path}${Platform.pathSeparator}$baseName.json');
    final tempFile = File('${cpDir.path}${Platform.pathSeparator}$baseName.tmp');
    final backupFile = File('${cpDir.path}${Platform.pathSeparator}$baseName.bak');

    if (await targetFile.exists()) {
      final verified = await _readAndVerifyFile<PreStageCheckpoint>(
        targetFile,
        PreStageCheckpoint.fromJson,
      );
      if (verified != null) {
        await _safeDelete(tempFile);
        return PreStageRecoveryInspection(
          status: SaveRecoveryStatus.healthy,
          checkpoint: verified.model,
          diagnosticMessage: verified.model.isActiveInProgress
              ? 'Wykryto przerwany wyścig — dostępny punkt wznowienia przed odprawą etapu.'
              : 'Ostatni etap zakończony poprawnie.',
        );
      }
    }

    if (await tempFile.exists()) {
      final verified = await _readAndVerifyFile<PreStageCheckpoint>(
        tempFile,
        PreStageCheckpoint.fromJson,
      );
      if (verified != null) {
        await _promoteFileAtomically(tempFile, targetFile);
        return PreStageRecoveryInspection(
          status: SaveRecoveryStatus.recoveredFromTemp,
          checkpoint: verified.model,
          diagnosticMessage:
              'Odzyskano punkt kontrolny przed etapem z pliku tymczasowego .tmp.',
        );
      }
      await _safeDelete(tempFile);
    }

    if (await backupFile.exists()) {
      final verified = await _readAndVerifyFile<PreStageCheckpoint>(
        backupFile,
        PreStageCheckpoint.fromJson,
      );
      if (verified != null) {
        await backupFile.copy(targetFile.path);
        return PreStageRecoveryInspection(
          status: SaveRecoveryStatus.recoveredFromBackup,
          checkpoint: verified.model,
          diagnosticMessage:
              'Odzyskano punkt kontrolny przed etapem z kopii zapasowej .bak.',
        );
      }
    }

    final anyExisted = await targetFile.exists() ||
        await tempFile.exists() ||
        await backupFile.exists();

    return PreStageRecoveryInspection(
      status: anyExisted
          ? SaveRecoveryStatus.corruptedUnrecoverable
          : SaveRecoveryStatus.notFound,
      diagnosticMessage: anyExisted
          ? 'Plik punktu kontrolnego przed etapem jest uszkodzony.'
          : 'Brak aktywnego punktu kontrolnego przed etapem.',
    );
  }

  /// Wyszukuje dowolny przerwany `PreStageCheckpoint` spośród wszystkich karier
  /// (np. bezpośrednio po uruchomieniu gry przed wyborem slotu).
  Future<PreStageCheckpoint?> detectAnyInterruptedStageCheckpoint() async {
    final cpDir = await getCheckpointsDirectory();
    if (!await cpDir.exists()) return null;

    final List<PreStageCheckpoint> activeCheckpoints = [];
    final entities = cpDir.listSync();
    for (final entity in entities) {
      if (entity is File && entity.path.endsWith('.json')) {
        final name = entity.uri.pathSegments.last;
        if (!name.startsWith(_preStagePrefix)) continue;
        final saveId = name
            .substring(_preStagePrefix.length, name.length - '.json'.length);
        final inspection = await inspectPreStageCheckpoint(saveId);
        if (inspection.hasRecoverableStage) {
          activeCheckpoints.add(inspection.checkpoint!);
        }
      }
    }

    if (activeCheckpoints.isEmpty) return null;
    activeCheckpoints.sort(
      (a, b) => b.createdAtUtc.compareTo(a.createdAtUtc),
    );
    return activeCheckpoints.first;
  }

  /// Wznawia karierę z punktu `PreStageCheckpoint`: atomowo przywraca stan
  /// kariery do głównego slotu i zwraca punkt kontrolny gotowy do odprawy etapu.
  Future<PreStageCheckpoint> resumeFromPreStageCheckpoint(
    PreStageCheckpoint checkpoint, {
    bool alsoSyncAutosave = true,
  }) async {
    final mainReceipt = await saveCareerTransactional(
      checkpoint.careerSave,
      isAutoSave: false,
      trigger: AutosaveTrigger.crashRecoveryRestore,
    );
    if (!mainReceipt.success) {
      throw StateError(
        'Nie udało się przywrócić zapisu głównego z PreStageCheckpoint: ${mainReceipt.errorMessage}',
      );
    }
    if (alsoSyncAutosave) {
      await saveCareerTransactional(
        checkpoint.careerSave,
        isAutoSave: true,
        trigger: AutosaveTrigger.crashRecoveryRestore,
      );
    }
    return checkpoint;
  }

  /// Usuwa punkt kontrolny `PreStageCheckpoint` (np. gdy gracz zrezygnuje ze wznowienia).
  Future<void> discardPreStageCheckpoint(String careerSaveId) async {
    final cpDir = await getCheckpointsDirectory();
    final baseName = '$_preStagePrefix$careerSaveId';
    await _safeDelete(
      File('${cpDir.path}${Platform.pathSeparator}$baseName.json'),
    );
    await _safeDelete(
      File('${cpDir.path}${Platform.pathSeparator}$baseName.tmp'),
    );
    await _safeDelete(
      File('${cpDir.path}${Platform.pathSeparator}$baseName.bak'),
    );
  }

  Future<TransactionalSaveReceipt> _writeTransactionalJson<T>({
    required File targetFile,
    required File tempFile,
    required File backupFile,
    required Map<String, dynamic> payloadMap,
    required T Function(Map<String, dynamic>) validateModel,
    required AutosaveTrigger trigger,
    required DateTime savedAtUtc,
  }) async {
    try {
      // 1. Serializacja payloadu i wyliczenie sumy kontrolnej JSON
      final payloadJson = jsonEncode(payloadMap);
      final payloadBytes = utf8.encode(payloadJson).length;
      final checksum = computeJsonChecksum(payloadJson);

      final envelope = _TransactionalSaveEnvelope(
        schemaVersion: _TransactionalSaveEnvelope.currentSchemaVersion,
        checksumAlgorithm: _TransactionalSaveEnvelope.algorithmName,
        checksum: checksum,
        payloadBytes: payloadBytes,
        trigger: trigger.toJson(),
        savedAtUtc: savedAtUtc,
        payload: payloadMap,
      );

      final envelopeJson = jsonEncode(envelope.toJson());

      // 2. Zapis do pliku tymczasowego .tmp z wymuszonym opróżnieniem buforów
      await tempFile.writeAsString(envelopeJson, flush: true);

      // 3. Weryfikacja po odczycie z .tmp (kontrola sumy kontrolnej i struktury)
      final verified = await _readAndVerifyFile<T>(tempFile, validateModel);
      if (verified == null || verified.checksum != checksum) {
        await _safeDelete(tempFile);
        return TransactionalSaveReceipt(
          success: false,
          targetPath: targetFile.path,
          checksum: checksum,
          payloadBytes: payloadBytes,
          savedAtUtc: savedAtUtc,
          trigger: trigger,
          errorMessage:
              'Weryfikacja sumy kontrolnej pliku tymczasowego .tmp nie powiodła się.',
        );
      }

      // 4. Bezpieczna rotacja poprzedniego poprawnego pliku głównego do .bak
      if (await targetFile.exists()) {
        final existingValid = await _readAndVerifyFile<T>(
          targetFile,
          validateModel,
        );
        if (existingValid != null) {
          final bakTemp = File('${backupFile.path}.tmp');
          await targetFile.copy(bakTemp.path);
          await _promoteFileAtomically(bakTemp, backupFile);
        }
      }

      // 5. Atomowa zamiana pliku głównego na zweryfikowany plik .tmp
      await _promoteFileAtomically(tempFile, targetFile);

      return TransactionalSaveReceipt(
        success: true,
        targetPath: targetFile.path,
        checksum: checksum,
        payloadBytes: payloadBytes,
        savedAtUtc: savedAtUtc,
        trigger: trigger,
      );
    } catch (e) {
      await _safeDelete(tempFile);
      return TransactionalSaveReceipt(
        success: false,
        targetPath: targetFile.path,
        checksum: '',
        payloadBytes: 0,
        savedAtUtc: savedAtUtc,
        trigger: trigger,
        errorMessage: e.toString(),
      );
    }
  }

  Future<_VerifiedRead<T>?> _readAndVerifyFile<T>(
    File file,
    T Function(Map<String, dynamic>) parser,
  ) async {
    try {
      if (!await file.exists()) return null;
      final raw = await file.readAsString();
      final envelope = _TransactionalSaveEnvelope.tryParse(raw);
      if (envelope != null) {
        final recomputedPayloadJson = jsonEncode(envelope.payload);
        final recomputedBytes = utf8.encode(recomputedPayloadJson).length;
        final recomputedChecksum = computeJsonChecksum(recomputedPayloadJson);

        if (recomputedBytes != envelope.payloadBytes ||
            recomputedChecksum != envelope.checksum) {
          return null;
        }
        final model = parser(envelope.payload);
        return _VerifiedRead<T>(model: model, checksum: recomputedChecksum);
      }

      // Obsługa starszego formatu surowego JSON (bez koperty transakcyjnej)
      final legacyDecoded = jsonDecode(raw);
      if (legacyDecoded is Map<String, dynamic>) {
        final model = parser(legacyDecoded);
        final checksum = computeJsonChecksum(jsonEncode(legacyDecoded));
        return _VerifiedRead<T>(model: model, checksum: checksum);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _promoteFileAtomically(File sourceTemp, File targetFile) async {
    try {
      await sourceTemp.rename(targetFile.path);
    } catch (_) {
      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      await sourceTemp.rename(targetFile.path);
    }
  }

  Future<void> _safeDelete(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Celowo ignorujemy błędy czyszczenia osieroconych plików tymczasowych
    }
  }
}

class _VerifiedRead<T> {
  final T model;
  final String checksum;

  const _VerifiedRead({
    required this.model,
    required this.checksum,
  });
}

/// Stan strażnika autozapisu udostępniany warstwie UI i kontrolerom gry.
class AutosaveGuardState {
  final bool isSaving;
  final DateTime? lastSavedAtUtc;
  final String? lastChecksum;
  final AutosaveTrigger? lastTrigger;
  final int successfulSaveCount;
  final PreStageCheckpoint? activePreStageCheckpoint;
  final String? lastError;

  const AutosaveGuardState({
    this.isSaving = false,
    this.lastSavedAtUtc,
    this.lastChecksum,
    this.lastTrigger,
    this.successfulSaveCount = 0,
    this.activePreStageCheckpoint,
    this.lastError,
  });

  AutosaveGuardState copyWith({
    bool? isSaving,
    DateTime? lastSavedAtUtc,
    String? lastChecksum,
    AutosaveTrigger? lastTrigger,
    int? successfulSaveCount,
    PreStageCheckpoint? activePreStageCheckpoint,
    bool clearActiveCheckpoint = false,
    String? lastError,
    bool clearError = false,
  }) {
    return AutosaveGuardState(
      isSaving: isSaving ?? this.isSaving,
      lastSavedAtUtc: lastSavedAtUtc ?? this.lastSavedAtUtc,
      lastChecksum: lastChecksum ?? this.lastChecksum,
      lastTrigger: lastTrigger ?? this.lastTrigger,
      successfulSaveCount: successfulSaveCount ?? this.successfulSaveCount,
      activePreStageCheckpoint: clearActiveCheckpoint
          ? null
          : (activePreStageCheckpoint ?? this.activePreStageCheckpoint),
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}

/// Notifier Riverpod zarządzający transakcyjnym autozapisem i odzyskiwaniem po awarii.
class AutosaveGuardNotifier extends StateNotifier<AutosaveGuardState> {
  final AutosaveAndCrashRecoveryGuard _guard;

  AutosaveGuardNotifier(this._guard) : super(const AutosaveGuardState());

  Future<TransactionalSaveReceipt> performAutosave(
    CareerSave save, {
    AutosaveTrigger trigger = AutosaveTrigger.periodic,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);
    final receipt = await _guard.saveCareerTransactional(
      save,
      isAutoSave: true,
      trigger: trigger,
    );
    state = state.copyWith(
      isSaving: false,
      lastSavedAtUtc: receipt.success ? receipt.savedAtUtc : state.lastSavedAtUtc,
      lastChecksum: receipt.success ? receipt.checksum : state.lastChecksum,
      lastTrigger: trigger,
      successfulSaveCount: receipt.success
          ? state.successfulSaveCount + 1
          : state.successfulSaveCount,
      lastError: receipt.success ? null : receipt.errorMessage,
    );
    return receipt;
  }

  Future<TransactionalSaveReceipt> recordPreStageCheckpoint({
    required CareerSave careerSave,
    required String raceId,
    required String raceName,
    required String stageId,
    required int stageNumber,
    required String stageName,
    List<String> selectedRiderIds = const [],
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);
    final receipt = await _guard.createPreStageCheckpoint(
      careerSave: careerSave,
      raceId: raceId,
      raceName: raceName,
      stageId: stageId,
      stageNumber: stageNumber,
      stageName: stageName,
      selectedRiderIds: selectedRiderIds,
    );
    final inspection = await _guard.inspectPreStageCheckpoint(careerSave.id);
    state = state.copyWith(
      isSaving: false,
      lastSavedAtUtc: receipt.success ? receipt.savedAtUtc : state.lastSavedAtUtc,
      lastChecksum: receipt.success ? receipt.checksum : state.lastChecksum,
      lastTrigger: AutosaveTrigger.preStageBriefing,
      successfulSaveCount: receipt.success
          ? state.successfulSaveCount + 1
          : state.successfulSaveCount,
      activePreStageCheckpoint: inspection.checkpoint,
      lastError: receipt.success ? null : receipt.errorMessage,
    );
    return receipt;
  }

  Future<void> completeStageCheckpoint(
    String careerSaveId, {
    String? stageId,
  }) async {
    await _guard.markStageCompleted(
      careerSaveId: careerSaveId,
      stageId: stageId,
    );
    state = state.copyWith(clearActiveCheckpoint: true);
  }
}

final autosaveAndCrashRecoveryGuardProvider =
    Provider<AutosaveAndCrashRecoveryGuard>((ref) {
  return AutosaveAndCrashRecoveryGuard();
});

final autosaveGuardStateProvider =
    StateNotifierProvider<AutosaveGuardNotifier, AutosaveGuardState>((ref) {
  final guard = ref.watch(autosaveAndCrashRecoveryGuardProvider);
  return AutosaveGuardNotifier(guard);
});
