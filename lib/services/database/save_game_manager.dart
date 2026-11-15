import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../models/career/career_save.dart';

/// Informacje o pojedynczym slocie zapisu gry (sloty 1-5 oraz dedykowany slot Auto-Save).
class SaveSlotInfo {
  final int slotNumber; // 1-5 dla slotów gracza, 0 dla auto-save
  final String slotKey; // 'slot_1', ..., 'slot_5', 'autosave'
  final bool isOccupied;
  final bool isAutoSave;
  final String? saveId;
  final String? saveName;
  final String? playerManagerName;
  final String? playerTeamId;
  final String? playerTeamName;
  final String? playerTeamDivision;
  final String? playerTeamJerseyPrimaryHex;
  final int? currentSeasonYear;
  final DateTime? currentDate;
  final DateTime? lastSavedAt;
  final CareerDifficulty? difficulty;
  final int? cashBalanceEur;
  final int? uciPointsSeason;
  final int? rosterCount;
  final int? fileSizeBytes;
  final bool hasBackup;

  const SaveSlotInfo({
    required this.slotNumber,
    required this.slotKey,
    required this.isOccupied,
    this.isAutoSave = false,
    this.saveId,
    this.saveName,
    this.playerManagerName,
    this.playerTeamId,
    this.playerTeamName,
    this.playerTeamDivision,
    this.playerTeamJerseyPrimaryHex,
    this.currentSeasonYear,
    this.currentDate,
    this.lastSavedAt,
    this.difficulty,
    this.cashBalanceEur,
    this.uciPointsSeason,
    this.rosterCount,
    this.fileSizeBytes,
    this.hasBackup = false,
  });

  /// Tworzy pusty slot
  factory SaveSlotInfo.empty(int slotNumber) {
    final bool auto = slotNumber == 0;
    return SaveSlotInfo(
      slotNumber: slotNumber,
      slotKey: auto ? 'autosave' : 'slot_$slotNumber',
      isOccupied: false,
      isAutoSave: auto,
      hasBackup: false,
    );
  }

  /// Tworzy obiekt metadanych slotu na podstawie pełnego stanu kariery
  factory SaveSlotInfo.fromSave({
    required int slotNumber,
    required CareerSave save,
    int? fileSizeBytes,
    bool hasBackup = false,
  }) {
    final bool auto = slotNumber == 0;
    final team = save.playerTeam;

    return SaveSlotInfo(
      slotNumber: slotNumber,
      slotKey: auto ? 'autosave' : 'slot_$slotNumber',
      isOccupied: true,
      isAutoSave: auto,
      saveId: save.id,
      saveName: save.saveName,
      playerManagerName: save.playerManagerName,
      playerTeamId: save.playerTeamId,
      playerTeamName: team.name,
      playerTeamDivision: team.division.name.toUpperCase(),
      playerTeamJerseyPrimaryHex: team.primaryJerseyColorHex,
      currentSeasonYear: save.currentSeasonYear,
      currentDate: save.currentDate,
      lastSavedAt: save.lastSavedAt,
      difficulty: save.difficulty,
      cashBalanceEur: team.cashBalanceEur,
      uciPointsSeason: team.uciPointsSeason,
      rosterCount: save.playerRoster.length,
      fileSizeBytes: fileSizeBytes,
      hasBackup: hasBackup,
    );
  }

  String get slotTitle {
    if (isAutoSave) return 'AUTO-SAVE (Ostatni zapis)';
    return 'SLOT $slotNumber';
  }

  String get formattedDate {
    if (currentDate == null) return '-';
    final d = currentDate!;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String get formattedLastSavedAt {
    if (lastSavedAt == null) return '-';
    final d = lastSavedAt!;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String get formattedCashBalance {
    if (cashBalanceEur == null) return '-';
    final double mln = cashBalanceEur! / 1000000.0;
    return '€${mln.toStringAsFixed(2)} mln';
  }

  String get formattedFileSize {
    if (fileSizeBytes == null || fileSizeBytes == 0) return '-';
    if (fileSizeBytes! < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes! < 1024 * 1024) {
      return '${(fileSizeBytes! / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes! / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  SaveSlotInfo copyWith({
    int? slotNumber,
    String? slotKey,
    bool? isOccupied,
    bool? isAutoSave,
    String? saveId,
    String? saveName,
    String? playerManagerName,
    String? playerTeamId,
    String? playerTeamName,
    String? playerTeamDivision,
    String? playerTeamJerseyPrimaryHex,
    int? currentSeasonYear,
    DateTime? currentDate,
    DateTime? lastSavedAt,
    CareerDifficulty? difficulty,
    int? cashBalanceEur,
    int? uciPointsSeason,
    int? rosterCount,
    int? fileSizeBytes,
    bool? hasBackup,
  }) {
    return SaveSlotInfo(
      slotNumber: slotNumber ?? this.slotNumber,
      slotKey: slotKey ?? this.slotKey,
      isOccupied: isOccupied ?? this.isOccupied,
      isAutoSave: isAutoSave ?? this.isAutoSave,
      saveId: saveId ?? this.saveId,
      saveName: saveName ?? this.saveName,
      playerManagerName: playerManagerName ?? this.playerManagerName,
      playerTeamId: playerTeamId ?? this.playerTeamId,
      playerTeamName: playerTeamName ?? this.playerTeamName,
      playerTeamDivision: playerTeamDivision ?? this.playerTeamDivision,
      playerTeamJerseyPrimaryHex: playerTeamJerseyPrimaryHex ?? this.playerTeamJerseyPrimaryHex,
      currentSeasonYear: currentSeasonYear ?? this.currentSeasonYear,
      currentDate: currentDate ?? this.currentDate,
      lastSavedAt: lastSavedAt ?? this.lastSavedAt,
      difficulty: difficulty ?? this.difficulty,
      cashBalanceEur: cashBalanceEur ?? this.cashBalanceEur,
      uciPointsSeason: uciPointsSeason ?? this.uciPointsSeason,
      rosterCount: rosterCount ?? this.rosterCount,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      hasBackup: hasBackup ?? this.hasBackup,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'slotNumber': slotNumber,
      'slotKey': slotKey,
      'isOccupied': isOccupied,
      'isAutoSave': isAutoSave,
      if (saveId != null) 'saveId': saveId,
      if (saveName != null) 'saveName': saveName,
      if (playerManagerName != null) 'playerManagerName': playerManagerName,
      if (playerTeamId != null) 'playerTeamId': playerTeamId,
      if (playerTeamName != null) 'playerTeamName': playerTeamName,
      if (playerTeamDivision != null) 'playerTeamDivision': playerTeamDivision,
      if (playerTeamJerseyPrimaryHex != null) 'playerTeamJerseyPrimaryHex': playerTeamJerseyPrimaryHex,
      if (currentSeasonYear != null) 'currentSeasonYear': currentSeasonYear,
      if (currentDate != null) 'currentDate': currentDate!.toIso8601String(),
      if (lastSavedAt != null) 'lastSavedAt': lastSavedAt!.toIso8601String(),
      if (difficulty != null) 'difficulty': difficulty!.name,
      if (cashBalanceEur != null) 'cashBalanceEur': cashBalanceEur,
      if (uciPointsSeason != null) 'uciPointsSeason': uciPointsSeason,
      if (rosterCount != null) 'rosterCount': rosterCount,
      if (fileSizeBytes != null) 'fileSizeBytes': fileSizeBytes,
      'hasBackup': hasBackup,
    };
  }

  factory SaveSlotInfo.fromJson(Map<String, dynamic> json) {
    return SaveSlotInfo(
      slotNumber: (json['slotNumber'] as num?)?.toInt() ?? 1,
      slotKey: json['slotKey'] as String? ?? 'slot_1',
      isOccupied: json['isOccupied'] as bool? ?? false,
      isAutoSave: json['isAutoSave'] as bool? ?? false,
      saveId: json['saveId'] as String?,
      saveName: json['saveName'] as String?,
      playerManagerName: json['playerManagerName'] as String?,
      playerTeamId: json['playerTeamId'] as String?,
      playerTeamName: json['playerTeamName'] as String?,
      playerTeamDivision: json['playerTeamDivision'] as String?,
      playerTeamJerseyPrimaryHex: json['playerTeamJerseyPrimaryHex'] as String?,
      currentSeasonYear: (json['currentSeasonYear'] as num?)?.toInt(),
      currentDate: json['currentDate'] != null ? DateTime.parse(json['currentDate'] as String) : null,
      lastSavedAt: json['lastSavedAt'] != null ? DateTime.parse(json['lastSavedAt'] as String) : null,
      difficulty: json['difficulty'] != null
          ? CareerDifficulty.fromJson(json['difficulty'] as String)
          : null,
      cashBalanceEur: (json['cashBalanceEur'] as num?)?.toInt(),
      uciPointsSeason: (json['uciPointsSeason'] as num?)?.toInt(),
      rosterCount: (json['rosterCount'] as num?)?.toInt(),
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt(),
      hasBackup: json['hasBackup'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    return 'SaveSlotInfo($slotKey, occupied: $isOccupied, team: $playerTeamName, date: $formattedDate)';
  }
}

/// Przenośny format pliku zapisu (Cross-Platform Save Package),
/// zawierający sumę kontrolną FNV-1a 64-bit, sygnaturę i dane gry.
class PortableSavePackage {
  static const String currentMagicHeader = 'PPM_SAVE_V1';
  static const int currentSchemaVersion = 1;

  final String magicHeader;
  final int schemaVersion;
  final DateTime exportedAt;
  final String sourcePlatform;
  final String checksum;
  final SaveSlotInfo slotMetadata;
  final String payloadJsonString;

  const PortableSavePackage({
    required this.magicHeader,
    required this.schemaVersion,
    required this.exportedAt,
    required this.sourcePlatform,
    required this.checksum,
    required this.slotMetadata,
    required this.payloadJsonString,
  });

  Map<String, dynamic> toJson() {
    return {
      'magicHeader': magicHeader,
      'schemaVersion': schemaVersion,
      'exportedAt': exportedAt.toIso8601String(),
      'sourcePlatform': sourcePlatform,
      'checksum': checksum,
      'slotMetadata': slotMetadata.toJson(),
      'payloadJsonString': payloadJsonString,
    };
  }

  factory PortableSavePackage.fromJson(Map<String, dynamic> json) {
    return PortableSavePackage(
      magicHeader: json['magicHeader'] as String? ?? currentMagicHeader,
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? currentSchemaVersion,
      exportedAt: json['exportedAt'] != null
          ? DateTime.parse(json['exportedAt'] as String)
          : DateTime.now(),
      sourcePlatform: json['sourcePlatform'] as String? ?? 'unknown',
      checksum: json['checksum'] as String? ?? '',
      slotMetadata: SaveSlotInfo.fromJson(json['slotMetadata'] as Map<String, dynamic>? ?? {}),
      payloadJsonString: json['payloadJsonString'] as String? ?? '{}',
    );
  }
}

/// Wynik weryfikacji integralności i poprawności importowanego pliku zapisu.
class SaveValidationResult {
  final bool isValid;
  final String? errorMessage;
  final SaveSlotInfo? slotInfo;
  final CareerSave? decodedSave;

  const SaveValidationResult({
    required this.isValid,
    this.errorMessage,
    this.slotInfo,
    this.decodedSave,
  });
}

/// Kompletny menedżer zapisu i odczytu stanu kariery (Save/Load) w pamięci urządzenia.
///
/// Obsługuje:
/// - 5 niezależnych slotów zapisu (`slot_1.json` - `slot_5.json`),
/// - Dedykowany slot Auto-Save (`autosave.json`) aktualizowany po każdym dniu kalendarzowym,
/// - Atomowy zapis bez ryzyka uszkodzenia danych (`.tmp` -> `.bak` -> `.json`),
/// - Błyskawiczny odczyt listy slotów dzięki lekkim plikom metadanych (`.meta.json`),
/// - Eksport i import plików zapisu umożliwiający przenoszenie kariery między iOS, Android, macOS i Windows.
class SaveGameManager {
  SaveGameManager._();

  static const String _savesFolderName = 'ppm_saves';
  static const int maxUserSlots = 5;
  static const int autoSaveSlotNumber = 0;

  /// Katalog na dysku urządzenia dla plików zapisów
  static Future<Directory> getSavesDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final savesDir = Directory('${appDocDir.path}${Platform.pathSeparator}$_savesFolderName');
    if (!await savesDir.exists()) {
      await savesDir.create(recursive: true);
    }
    return savesDir;
  }

  /// Zwraca listę informacji o wszystkich 5 slotach gracza oraz slocie Auto-Save
  static Future<List<SaveSlotInfo>> getAllSlots({bool includeAutoSave = true}) async {
    final List<SaveSlotInfo> slots = [];

    // Sloty gracza 1 - 5
    for (int i = 1; i <= maxUserSlots; i++) {
      slots.add(await getSlotInfo(i));
    }

    // Slot 0: Auto-Save
    if (includeAutoSave) {
      slots.add(await getAutoSaveInfo());
    }

    return slots;
  }

  /// Pobiera szczegółowe metadane danego slotu (1-5) bez ładowania całego świata kolarzy
  static Future<SaveSlotInfo> getSlotInfo(int slotNumber) async {
    final dir = await getSavesDirectory();
    final String baseName = 'slot_$slotNumber';
    final metaFile = File('${dir.path}${Platform.pathSeparator}$baseName.meta.json');
    final mainFile = File('${dir.path}${Platform.pathSeparator}$baseName.json');
    final backupFile = File('${dir.path}${Platform.pathSeparator}$baseName.bak');

    final bool mainExists = await mainFile.exists();
    final bool backupExists = await backupFile.exists();

    if (!mainExists && !backupExists) {
      return SaveSlotInfo.empty(slotNumber);
    }

    // 1. Próba szybkiego odczytu z pliku .meta.json
    if (await metaFile.exists()) {
      try {
        final content = await metaFile.readAsString();
        final jsonMap = jsonDecode(content) as Map<String, dynamic>;
        final slotInfo = SaveSlotInfo.fromJson(jsonMap);
        final int size = mainExists ? await mainFile.length() : (await backupFile.length());
        return slotInfo.copyWith(
          slotNumber: slotNumber,
          fileSizeBytes: size,
          hasBackup: backupExists,
        );
      } catch (_) {
        // Jeśli plik .meta jest uszkodzony, odtworzymy go poniżej z pliku głównego
      }
    }

    // 2. Odtworzenie metadanych z głównego pliku zapisu .json
    try {
      final targetFile = mainExists ? mainFile : backupFile;
      final content = await targetFile.readAsString();
      final jsonMap = jsonDecode(content) as Map<String, dynamic>;
      final save = CareerSave.fromJson(jsonMap);

      final slotInfo = SaveSlotInfo.fromSave(
        slotNumber: slotNumber,
        save: save,
        fileSizeBytes: await targetFile.length(),
        hasBackup: backupExists,
      );

      // Zapisujemy odtworzony plik .meta.json
      await metaFile.writeAsString(jsonEncode(slotInfo.toJson()), flush: true);
      return slotInfo;
    } catch (_) {
      // Plik uszkodzony
      return SaveSlotInfo(
        slotNumber: slotNumber,
        slotKey: 'slot_$slotNumber',
        isOccupied: true,
        saveName: 'Uszkodzony plik zapisu',
        hasBackup: backupExists,
        fileSizeBytes: mainExists ? await mainFile.length() : 0,
      );
    }
  }

  /// Pobiera informacje o slocie Auto-Save (slot 0)
  static Future<SaveSlotInfo> getAutoSaveInfo() async {
    final dir = await getSavesDirectory();
    final metaFile = File('${dir.path}${Platform.pathSeparator}autosave.meta.json');
    final mainFile = File('${dir.path}${Platform.pathSeparator}autosave.json');
    final backupFile = File('${dir.path}${Platform.pathSeparator}autosave.bak');

    final bool mainExists = await mainFile.exists();
    final bool backupExists = await backupFile.exists();

    if (!mainExists && !backupExists) {
      return SaveSlotInfo.empty(autoSaveSlotNumber);
    }

    if (await metaFile.exists()) {
      try {
        final content = await metaFile.readAsString();
        final jsonMap = jsonDecode(content) as Map<String, dynamic>;
        final slotInfo = SaveSlotInfo.fromJson(jsonMap);
        final int size = mainExists ? await mainFile.length() : (await backupFile.length());
        return slotInfo.copyWith(
          slotNumber: autoSaveSlotNumber,
          isAutoSave: true,
          fileSizeBytes: size,
          hasBackup: backupExists,
        );
      } catch (_) {}
    }

    try {
      final targetFile = mainExists ? mainFile : backupFile;
      final content = await targetFile.readAsString();
      final jsonMap = jsonDecode(content) as Map<String, dynamic>;
      final save = CareerSave.fromJson(jsonMap);

      final slotInfo = SaveSlotInfo.fromSave(
        slotNumber: autoSaveSlotNumber,
        save: save,
        fileSizeBytes: await targetFile.length(),
        hasBackup: backupExists,
      );

      await metaFile.writeAsString(jsonEncode(slotInfo.toJson()), flush: true);
      return slotInfo;
    } catch (_) {
      return SaveSlotInfo(
        slotNumber: autoSaveSlotNumber,
        slotKey: 'autosave',
        isOccupied: true,
        isAutoSave: true,
        saveName: 'Uszkodzony Auto-Save',
        hasBackup: backupExists,
        fileSizeBytes: mainExists ? await mainFile.length() : 0,
      );
    }
  }

  /// Sprawdza, czy istnieje zapis Auto-Save
  static Future<bool> hasAutoSave() async {
    final dir = await getSavesDirectory();
    final mainFile = File('${dir.path}${Platform.pathSeparator}autosave.json');
    return mainFile.exists();
  }

  /// Zapisuje stan gry do wybranego slotu (1-5) w sposób w 100% atomowy
  static Future<SaveSlotInfo> saveToSlot({
    required int slotNumber,
    required CareerSave save,
    String? customSaveName,
  }) async {
    if (slotNumber < 1 || slotNumber > maxUserSlots) {
      throw ArgumentError('Numer slotu musi mieścić się w przedziale 1-$maxUserSlots.');
    }

    final dir = await getSavesDirectory();
    final String baseName = 'slot_$slotNumber';
    final targetFile = File('${dir.path}${Platform.pathSeparator}$baseName.json');
    final tempFile = File('${dir.path}${Platform.pathSeparator}$baseName.tmp');
    final backupFile = File('${dir.path}${Platform.pathSeparator}$baseName.bak');
    final metaFile = File('${dir.path}${Platform.pathSeparator}$baseName.meta.json');

    final updatedSave = save.copyWith(
      saveName: customSaveName ?? save.saveName,
      lastSavedAt: DateTime.now(),
    );

    final jsonString = jsonEncode(updatedSave.toJson());

    // 1. Zapis do pliku tymczasowego
    await tempFile.writeAsString(jsonString, flush: true);

    // 2. Jeśli istnieje poprzedni plik zapisu, tworzymy kopię .bak
    if (await targetFile.exists()) {
      try {
        await targetFile.copy(backupFile.path);
      } catch (_) {}
    }

    // 3. Atomowe zastąpienie pliku docelowego
    if (await targetFile.exists()) {
      await targetFile.delete();
    }
    await tempFile.rename(targetFile.path);

    // 4. Zapisujemy lekki plik metadanych .meta.json
    final slotInfo = SaveSlotInfo.fromSave(
      slotNumber: slotNumber,
      save: updatedSave,
      fileSizeBytes: await targetFile.length(),
      hasBackup: await backupFile.exists(),
    );
    await metaFile.writeAsString(jsonEncode(slotInfo.toJson()), flush: true);

    return slotInfo;
  }

  /// Wykonuje automatyczny zapis kariery (Auto-Save) po zakończonym dniu wyścigowym w kalendarzu
  static Future<SaveSlotInfo> performAutoSave({
    required CareerSave save,
    int? originatingSlotNumber,
  }) async {
    final dir = await getSavesDirectory();
    const String baseName = 'autosave';
    final targetFile = File('${dir.path}${Platform.pathSeparator}$baseName.json');
    final tempFile = File('${dir.path}${Platform.pathSeparator}$baseName.tmp');
    final backupFile = File('${dir.path}${Platform.pathSeparator}$baseName.bak');
    final metaFile = File('${dir.path}${Platform.pathSeparator}$baseName.meta.json');

    final updatedSave = save.copyWith(
      lastSavedAt: DateTime.now(),
    );

    final jsonString = jsonEncode(updatedSave.toJson());

    // 1. Zapis atomowy do pliku tymczasowego
    await tempFile.writeAsString(jsonString, flush: true);

    // 2. Rotacja backupu .bak
    if (await targetFile.exists()) {
      try {
        await targetFile.copy(backupFile.path);
      } catch (_) {}
    }

    // 3. Rename do autosave.json
    if (await targetFile.exists()) {
      await targetFile.delete();
    }
    await tempFile.rename(targetFile.path);

    // 4. Zapis metadanych
    final slotInfo = SaveSlotInfo.fromSave(
      slotNumber: autoSaveSlotNumber,
      save: updatedSave,
      fileSizeBytes: await targetFile.length(),
      hasBackup: await backupFile.exists(),
    );
    await metaFile.writeAsString(jsonEncode(slotInfo.toJson()), flush: true);

    // 5. Opcjonalnie aktualizujemy plik slotu macierzystego, aby gracz nie stracił postępów
    if (originatingSlotNumber != null &&
        originatingSlotNumber >= 1 &&
        originatingSlotNumber <= maxUserSlots) {
      try {
        await saveToSlot(
          slotNumber: originatingSlotNumber,
          save: updatedSave,
        );
      } catch (_) {}
    }

    return slotInfo;
  }

  /// Ładuje pełny stan kariery z wybranego slotu (1-5) z automatyczną naprawą z pliku .bak
  static Future<CareerSave?> loadFromSlot(int slotNumber) async {
    if (slotNumber < 1 || slotNumber > maxUserSlots) {
      throw ArgumentError('Numer slotu musi mieścić się w przedziale 1-$maxUserSlots.');
    }

    final dir = await getSavesDirectory();
    final String baseName = 'slot_$slotNumber';
    final mainFile = File('${dir.path}${Platform.pathSeparator}$baseName.json');
    final backupFile = File('${dir.path}${Platform.pathSeparator}$baseName.bak');

    return _loadSaveFromFiles(mainFile: mainFile, backupFile: backupFile);
  }

  /// Ładuje stan kariery z dedykowanego slotu Auto-Save
  static Future<CareerSave?> loadAutoSave() async {
    final dir = await getSavesDirectory();
    const String baseName = 'autosave';
    final mainFile = File('${dir.path}${Platform.pathSeparator}$baseName.json');
    final backupFile = File('${dir.path}${Platform.pathSeparator}$baseName.bak');

    return _loadSaveFromFiles(mainFile: mainFile, backupFile: backupFile);
  }

  static Future<CareerSave?> _loadSaveFromFiles({
    required File mainFile,
    required File backupFile,
  }) async {
    if (await mainFile.exists()) {
      try {
        final content = await mainFile.readAsString();
        final jsonMap = jsonDecode(content) as Map<String, dynamic>;
        return CareerSave.fromJson(jsonMap);
      } catch (_) {
        // Główny plik uszkodzony – próba odzyskania z kopii .bak
        if (await backupFile.exists()) {
          try {
            final bakContent = await backupFile.readAsString();
            final bakMap = jsonDecode(bakContent) as Map<String, dynamic>;
            return CareerSave.fromJson(bakMap);
          } catch (_) {}
        }
        rethrow;
      }
    } else if (await backupFile.exists()) {
      final bakContent = await backupFile.readAsString();
      final bakMap = jsonDecode(bakContent) as Map<String, dynamic>;
      return CareerSave.fromJson(bakMap);
    }

    return null;
  }

  /// Usuwa dany slot zapisu (plik główny, backup oraz metadane)
  static Future<bool> deleteSlot(int slotNumber) async {
    if (slotNumber < 1 || slotNumber > maxUserSlots) return false;

    final dir = await getSavesDirectory();
    final String baseName = 'slot_$slotNumber';
    final mainFile = File('${dir.path}${Platform.pathSeparator}$baseName.json');
    final backupFile = File('${dir.path}${Platform.pathSeparator}$baseName.bak');
    final metaFile = File('${dir.path}${Platform.pathSeparator}$baseName.meta.json');

    bool deleted = false;
    if (await mainFile.exists()) {
      await mainFile.delete();
      deleted = true;
    }
    if (await backupFile.exists()) {
      await backupFile.delete();
    }
    if (await metaFile.exists()) {
      await metaFile.delete();
    }
    return deleted;
  }

  /// Usuwa plik Auto-Save
  static Future<bool> deleteAutoSave() async {
    final dir = await getSavesDirectory();
    const String baseName = 'autosave';
    final mainFile = File('${dir.path}${Platform.pathSeparator}$baseName.json');
    final backupFile = File('${dir.path}${Platform.pathSeparator}$baseName.bak');
    final metaFile = File('${dir.path}${Platform.pathSeparator}$baseName.meta.json');

    bool deleted = false;
    if (await mainFile.exists()) {
      await mainFile.delete();
      deleted = true;
    }
    if (await backupFile.exists()) {
      await backupFile.delete();
    }
    if (await metaFile.exists()) {
      await metaFile.delete();
    }
    return deleted;
  }

  /// Kopiuje stan zapisu z jednego slotu do drugiego
  static Future<SaveSlotInfo> copySlot({
    required int sourceSlot,
    required int targetSlot,
  }) async {
    final sourceSave = await loadFromSlot(sourceSlot);
    if (sourceSave == null) {
      throw StateError('Slot źródłowy #$sourceSlot jest pusty.');
    }

    final copiedSave = sourceSave.copyWith(
      saveName: '${sourceSave.saveName} (Kopia)',
    );

    return saveToSlot(
      slotNumber: targetSlot,
      save: copiedSave,
    );
  }

  // ===========================================================================
  // EKSPORT I IMPORT PLIKÓW ZAPISU (MOBILE <-> MAC / PC TRANSFER)
  // ===========================================================================

  /// Oblicza 64-bitową sumę kontrolną FNV-1a w czystym Darcie
  static String computeChecksum(String input) {
    final bytes = utf8.encode(input);
    var hash = BigInt.parse('14695981039346656037');
    final prime = BigInt.parse('1099511628211');
    final mask = (BigInt.one << 64) - BigInt.one;

    for (final b in bytes) {
      hash = (hash ^ BigInt.from(b)) * prime;
      hash = hash & mask;
    }

    return hash.toRadixString(16).padLeft(16, '0');
  }

  /// Eksportuje wybrany slot lub bieżący stan gry do przenośnego formatu JSON
  static Future<String> exportSaveAsPortableJson({
    required int slotNumber,
    CareerSave? inMemorySave,
  }) async {
    CareerSave? saveToExport = inMemorySave;
    if (saveToExport == null) {
      if (slotNumber == autoSaveSlotNumber) {
        saveToExport = await loadAutoSave();
      } else {
        saveToExport = await loadFromSlot(slotNumber);
      }
    }

    if (saveToExport == null) {
      throw StateError('Brak danych zapisu do wyeksportowania ze slotu #$slotNumber.');
    }

    final payloadJson = jsonEncode(saveToExport.toJson());
    final checksum = computeChecksum(payloadJson);
    final slotInfo = SaveSlotInfo.fromSave(slotNumber: slotNumber, save: saveToExport);

    final package = PortableSavePackage(
      magicHeader: PortableSavePackage.currentMagicHeader,
      schemaVersion: PortableSavePackage.currentSchemaVersion,
      exportedAt: DateTime.now(),
      sourcePlatform: Platform.operatingSystem,
      checksum: checksum,
      slotMetadata: slotInfo,
      payloadJsonString: payloadJson,
    );

    return const JsonEncoder.withIndent('  ').convert(package.toJson());
  }

  /// Zapisuje wyeksportowany pakiet do pliku o wskazanej ścieżce (np. `.ppm_save` lub `.json`)
  static Future<File> exportSaveToFile({
    required int slotNumber,
    required String targetFilePath,
    CareerSave? inMemorySave,
  }) async {
    final jsonString = await exportSaveAsPortableJson(
      slotNumber: slotNumber,
      inMemorySave: inMemorySave,
    );

    final file = File(targetFilePath);
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }

    return file.writeAsString(jsonString, flush: true);
  }

  /// Waliduje przenośny plik zapisu przed zaimportowaniem
  static SaveValidationResult validatePortableSave(String dataString) {
    try {
      final decoded = jsonDecode(dataString);
      if (decoded is! Map<String, dynamic>) {
        return const SaveValidationResult(
          isValid: false,
          errorMessage: 'Plik nie jest poprawnym obiektem JSON.',
        );
      }

      // Sprawdzamy czy to format PortableSavePackage
      if (decoded.containsKey('magicHeader') &&
          decoded['magicHeader'] == PortableSavePackage.currentMagicHeader) {
        final package = PortableSavePackage.fromJson(decoded);

        // Weryfikacja sumy kontrolnej
        final computedChecksum = computeChecksum(package.payloadJsonString);
        if (computedChecksum != package.checksum) {
          return const SaveValidationResult(
            isValid: false,
            errorMessage: 'Niezgodność sumy kontrolnej – plik zapisu został zmodyfikowany lub uszkodzony.',
          );
        }

        final saveJson = jsonDecode(package.payloadJsonString) as Map<String, dynamic>;
        final save = CareerSave.fromJson(saveJson);

        return SaveValidationResult(
          isValid: true,
          slotInfo: package.slotMetadata,
          decodedSave: save,
        );
      }

      // Format surowego CareerSave (np. edycja ręczna przez społeczność)
      if (decoded.containsKey('calendar') &&
          decoded.containsKey('teams') &&
          decoded.containsKey('riders')) {
        final save = CareerSave.fromJson(decoded);
        final slotInfo = SaveSlotInfo.fromSave(slotNumber: 1, save: save);
        return SaveValidationResult(
          isValid: true,
          slotInfo: slotInfo,
          decodedSave: save,
        );
      }

      return const SaveValidationResult(
        isValid: false,
        errorMessage: 'Nieznana struktura pliku zapisu (brak nagłówka PPM_SAVE_V1 lub pól CareerSave).',
      );
    } catch (e) {
      return SaveValidationResult(
        isValid: false,
        errorMessage: 'Błąd dekodowania pliku zapisu: $e',
      );
    }
  }

  /// Importuje przenośny plik zapisu do wskazanego slotu (1-5)
  static Future<SaveSlotInfo> importPortableSave({
    required String dataString,
    required int targetSlotNumber,
  }) async {
    if (targetSlotNumber < 1 || targetSlotNumber > maxUserSlots) {
      throw ArgumentError('Docelowy slot musi mieścić się w przedziale 1-$maxUserSlots.');
    }

    final validation = validatePortableSave(dataString);
    if (!validation.isValid || validation.decodedSave == null) {
      throw FormatException(validation.errorMessage ?? 'Niepoprawny plik zapisu.');
    }

    return saveToSlot(
      slotNumber: targetSlotNumber,
      save: validation.decodedSave!,
    );
  }

  /// Importuje plik zapisu bezpośrednio z pliku na dysku (iOS, Android, macOS, Windows)
  static Future<SaveSlotInfo> importSaveFromFile({
    required File file,
    required int targetSlotNumber,
  }) async {
    if (!await file.exists()) {
      throw FileSystemException('Wskazany plik nie istnieje.', file.path);
    }

    final content = await file.readAsString();
    return importPortableSave(
      dataString: content,
      targetSlotNumber: targetSlotNumber,
    );
  }
}

