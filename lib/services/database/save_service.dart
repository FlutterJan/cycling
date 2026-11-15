import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../models/career/career_save.dart';
import '../../models/rider/rider.dart';
import '../../models/team/cycling_team.dart';
import '../generators/initial_game_seeder.dart';

/// Podsumowanie pliku zapisu (metadane do szybkiego wyświetlania na liście slotów bez ładowania całego świata).
class CareerSaveMetadata {
  final String saveId;
  final String saveName;
  final String playerManagerName;
  final String playerTeamId;
  final String playerTeamName;
  final int currentSeasonYear;
  final DateTime currentDate;
  final DateTime lastSavedAt;
  final CareerDifficulty difficulty;
  final int fileSizeBytes;

  const CareerSaveMetadata({
    required this.saveId,
    required this.saveName,
    required this.playerManagerName,
    required this.playerTeamId,
    required this.playerTeamName,
    required this.currentSeasonYear,
    required this.currentDate,
    required this.lastSavedAt,
    required this.difficulty,
    required this.fileSizeBytes,
  });

  Map<String, dynamic> toJson() {
    return {
      'saveId': saveId,
      'saveName': saveName,
      'playerManagerName': playerManagerName,
      'playerTeamId': playerTeamId,
      'playerTeamName': playerTeamName,
      'currentSeasonYear': currentSeasonYear,
      'currentDate': currentDate.toIso8601String(),
      'lastSavedAt': lastSavedAt.toIso8601String(),
      'difficulty': difficulty.toJson(),
      'fileSizeBytes': fileSizeBytes,
    };
  }

  factory CareerSaveMetadata.fromJson(Map<String, dynamic> json) {
    return CareerSaveMetadata(
      saveId: json['saveId'] as String,
      saveName: json['saveName'] as String,
      playerManagerName: json['playerManagerName'] as String,
      playerTeamId: json['playerTeamId'] as String,
      playerTeamName: json['playerTeamName'] as String,
      currentSeasonYear: (json['currentSeasonYear'] as num).toInt(),
      currentDate: DateTime.parse(json['currentDate'] as String),
      lastSavedAt: DateTime.parse(json['lastSavedAt'] as String),
      difficulty: CareerDifficulty.fromJson(json['difficulty'] as String),
      fileSizeBytes: (json['fileSizeBytes'] as num).toInt(),
    );
  }
}

/// Serwis zarządzający trwałym zapisem i odczytem stanu kariery (Local JSON Storage + rotacja backupów .bak).
class SaveService {
  SaveService._();

  static const String _savesFolderName = 'ppm_saves';
  static const String _autoSaveSlotPrefix = 'autosave_';

  /// Katalog na dysku, w którym przechowywane są pliki zapisów
  static Future<Directory> getSavesDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final savesDir = Directory('${appDocDir.path}${Platform.pathSeparator}$_savesFolderName');
    if (!await savesDir.exists()) {
      await savesDir.create(recursive: true);
    }
    return savesDir;
  }

  /// Pobiera listę wszystkich dostępnych slotów zapisu gry
  static Future<List<CareerSaveMetadata>> listSavedGames() async {
    final dir = await getSavesDirectory();
    final entities = dir.listSync();
    final List<CareerSaveMetadata> savesList = [];

    for (final entity in entities) {
      if (entity is File && entity.path.endsWith('.json') && !entity.path.endsWith('.bak')) {
        try {
          final content = await entity.readAsString();
          final jsonMap = jsonDecode(content) as Map<String, dynamic>;

          // Odczytujemy metadane
          final String saveId = jsonMap['id'] as String;
          final String saveName = jsonMap['saveName'] as String;
          final String managerName = jsonMap['playerManagerName'] as String;
          final String teamId = jsonMap['playerTeamId'] as String;
          final int seasonYear = (jsonMap['currentSeasonYear'] as num).toInt();
          final DateTime curDate = DateTime.parse(jsonMap['currentDate'] as String);
          final DateTime savedAt = DateTime.parse(jsonMap['lastSavedAt'] as String);
          final CareerDifficulty diff = CareerDifficulty.fromJson(jsonMap['difficulty'] as String);

          // Szukamy nazwy drużyny gracza w zapisanej liście zespołów
          String teamName = teamId;
          final teamsList = jsonMap['teams'] as List<dynamic>?;
          if (teamsList != null) {
            for (final t in teamsList) {
              if (t is Map<String, dynamic> && t['id'] == teamId) {
                teamName = t['name'] as String? ?? teamId;
                break;
              }
            }
          }

          savesList.add(
            CareerSaveMetadata(
              saveId: saveId,
              saveName: saveName,
              playerManagerName: managerName,
              playerTeamId: teamId,
              playerTeamName: teamName,
              currentSeasonYear: seasonYear,
              currentDate: curDate,
              lastSavedAt: savedAt,
              difficulty: diff,
              fileSizeBytes: entity.lengthSync(),
            ),
          );
        } catch (_) {
          // Uszkodzony plik ignorujemy lub omijamy
        }
      }
    }

    // Sortujemy malejąco według daty ostatniego zapisu (najświeższe na górze)
    savesList.sort((a, b) => b.lastSavedAt.compareTo(a.lastSavedAt));
    return savesList;
  }

  /// Ładuje pełny stan kariery z pliku o zadanym identyfikatorze
  static Future<CareerSave?> loadCareerSave(String saveId) async {
    final dir = await getSavesDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}$saveId.json');
    final backupFile = File('${dir.path}${Platform.pathSeparator}$saveId.bak');

    if (await file.exists()) {
      try {
        final content = await file.readAsString();
        final jsonMap = jsonDecode(content) as Map<String, dynamic>;
        return CareerSave.fromJson(jsonMap);
      } catch (e) {
        // Główny plik uszkodzony – próba odzyskania z backupu .bak
        if (await backupFile.exists()) {
          final bakContent = await backupFile.readAsString();
          final bakJson = jsonDecode(bakContent) as Map<String, dynamic>;
          return CareerSave.fromJson(bakJson);
        }
        rethrow;
      }
    } else if (await backupFile.exists()) {
      final bakContent = await backupFile.readAsString();
      final bakJson = jsonDecode(bakContent) as Map<String, dynamic>;
      return CareerSave.fromJson(bakJson);
    }

    return null;
  }

  /// Zapisuje stan kariery na dysku w sposób atomowy (tworzy .tmp, rotuje do .bak, renames to .json).
  static Future<void> saveCareer(
    CareerSave save, {
    bool isAutoSave = false,
  }) async {
    final dir = await getSavesDirectory();
    final saveId = isAutoSave ? '$_autoSaveSlotPrefix${save.id}' : save.id;

    final targetFile = File('${dir.path}${Platform.pathSeparator}$saveId.json');
    final tempFile = File('${dir.path}${Platform.pathSeparator}$saveId.tmp');
    final backupFile = File('${dir.path}${Platform.pathSeparator}$saveId.bak');

    final updatedSave = save.copyWith(lastSavedAt: DateTime.now());
    final jsonString = jsonEncode(updatedSave.toJson());

    // 1. Zapis do pliku tymczasowego
    await tempFile.writeAsString(jsonString, flush: true);

    // 2. Jeśli istnieje poprzedni plik zapisu, tworzymy kopię zapasową .bak
    if (await targetFile.exists()) {
      try {
        await targetFile.copy(backupFile.path);
      } catch (_) {
        // Ignorujemy niepowodzenie backupu
      }
    }

    // 3. Atomowa podmiana pliku docelowego
    if (await targetFile.exists()) {
      await targetFile.delete();
    }
    await tempFile.rename(targetFile.path);
  }

  /// Usuwa dany plik zapisu oraz powiązany z nim plik kopii zapasowej
  static Future<bool> deleteCareerSave(String saveId) async {
    final dir = await getSavesDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}$saveId.json');
    final backupFile = File('${dir.path}${Platform.pathSeparator}$saveId.bak');

    bool deleted = false;
    if (await file.exists()) {
      await file.delete();
      deleted = true;
    }
    if (await backupFile.exists()) {
      await backupFile.delete();
    }
    return deleted;
  }

  /// Tworzy kompletnie nową karierę z wygenerowanym peletonem, kalendarzem UCI i kolarzami.
  /// Obsługuje zarówno prowadzenie istniejącej ekipy, jak i autorskiego zespołu (Custom Team).
  static Future<CareerSave> createNewCareer({
    required String saveName,
    required String playerManagerName,
    required String playerTeamId,
    CareerDifficulty difficulty = CareerDifficulty.normal,
    int seasonYear = 2026,
    int seed = 42,
    CyclingTeam? customTeam,
    List<Rider>? customRoster,
  }) async {
    final result = await InitialGameSeeder.seedNewGame(
      InitialGameSeedConfig(
        saveName: saveName,
        playerManagerName: playerManagerName,
        playerTeamId: playerTeamId,
        difficulty: difficulty,
        seasonYear: seasonYear,
        seed: seed,
        customTeam: customTeam,
        customRoster: customRoster,
        saveToDisk: false,
      ),
    );

    // Zapisujemy na dysku w głównym pliku zapisu SaveService
    await saveCareer(result.save);

    return result.save;
  }
}

