// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/career/career_save.dart';
import '../../models/career/pro_cyclist_career_state.dart';
import '../../models/race/velodrome_track_and_hour_record_model.dart';
import '../../models/rider/rider.dart';
import '../../models/team/cycling_team.dart';
import '../../services/career/autosave_and_crash_recovery_guard.dart';
import '../../services/database/database_backup_and_integrity_repair.dart';
import '../../services/generators/rider_procedural_generator.dart';
import '../../ui/screens/cyclocross_winter_series_screen.dart';
import '../../ui/screens/legends_card_album_and_packs_screen.dart';
import '../theme/app_colors.dart';

/// Sekcje danych wprowadzone w Paczce #4 objęte automatyczną migracją zapisu v4.
enum Package4MigrationSection {
  proCyclistCareer(
    'Kariera Be a Pro (ProCyclistCareerState)',
    'proCyclistCareer',
    Icons.person_pin_circle_rounded,
  ),
  hourRecords(
    'Rekordy Godzinne UCI i Welodromy',
    'hourRecords',
    Icons.timer_rounded,
  ),
  cyclocrossCup(
    'Zimowy Puchar Cyclo-Cross',
    'cyclocrossCup',
    Icons.terrain_rounded,
  ),
  legendsCardAlbum(
    'Kolekcja Kart Legend i Paczek',
    'legendsCardAlbum',
    Icons.style_rounded,
  );

  final String labelPl;
  final String jsonKey;
  final IconData icon;

  const Package4MigrationSection(this.labelPl, this.jsonKey, this.icon);
}

/// Wynikowy status migracji zapisu do formatu v4 z pełnym wsparciem Paczki #4.
enum V4MigrationStatus {
  alreadyCompatible('ZGODNY Z V4 (PACZKA #4)', AppColors.statusSuccess),
  migrated('ZMIGROWANY DO V4', AppColors.accentBlue),
  repairedAndMigrated('NAPRAWIONY I ZMIGROWANY DO V4', AppColors.amberWarning),
  failed('BŁĄD MIGRACJI V4', AppColors.crimsonAlert);

  final String labelPl;
  final Color color;

  const V4MigrationStatus(this.labelPl, this.color);

  bool get isSuccess => this != V4MigrationStatus.failed;
}

/// Pojedyncza akcja uzupełnienia, normalizacji lub naprawy pola podczas migracji.
@immutable
class V4MigrationFieldAction {
  final String jsonPath;
  final Package4MigrationSection? section;
  final String reason;
  final String appliedValueSummary;
  final bool wasRepaired;

  const V4MigrationFieldAction({
    required this.jsonPath,
    this.section,
    required this.reason,
    required this.appliedValueSummary,
    this.wasRepaired = false,
  });

  Map<String, dynamic> toJson() => {
        'jsonPath': jsonPath,
        'section': section?.name,
        'reason': reason,
        'appliedValueSummary': appliedValueSummary,
        'wasRepaired': wasRepaired,
      };
}

/// Podsumowanie stanu pojedynczej sekcji Paczki #4 po przejściu migracji.
@immutable
class Package4SectionSummary {
  final Package4MigrationSection section;
  final bool presentBefore;
  final bool validAfter;
  final int recordsCount;
  final int issuesFixedCount;
  final String note;

  const Package4SectionSummary({
    required this.section,
    required this.presentBefore,
    required this.validAfter,
    required this.recordsCount,
    required this.issuesFixedCount,
    required this.note,
  });

  Map<String, dynamic> toJson() => {
        'section': section.name,
        'presentBefore': presentBefore,
        'validAfter': validAfter,
        'recordsCount': recordsCount,
        'issuesFixedCount': issuesFixedCount,
        'note': note,
      };
}

/// Trwały stan Zimowego Pucharu Przełajowego (Cyclo-Cross) zapisywany w pliku kariery.
@immutable
class CyclocrossCupSaveState {
  final int seasonYear;
  final List<String> calendarRaceIds;
  final List<CyclocrossRaceResult> completedResults;
  final int totalCupPoints;
  final int podiumsCount;
  final int appliedRoadBonusPoints;

  const CyclocrossCupSaveState({
    required this.seasonYear,
    required this.calendarRaceIds,
    this.completedResults = const [],
    this.totalCupPoints = 0,
    this.podiumsCount = 0,
    this.appliedRoadBonusPoints = 0,
  });

  /// Tworzy domyślny stan Pucharu CX dla danego roku sezonu.
  factory CyclocrossCupSaveState.initial({int seasonYear = 2026}) {
    return CyclocrossCupSaveState(
      seasonYear: seasonYear,
      calendarRaceIds: CyclocrossWinterCalendarCatalog.build8IconicRaces()
          .map((race) => race.id)
          .toList(growable: false),
      completedResults: const [],
      totalCupPoints: 0,
      podiumsCount: 0,
      appliedRoadBonusPoints: 0,
    );
  }

  /// Serializuje wynik pojedynczego wyścigu CX do mapy JSON.
  static Map<String, dynamic> raceResultToJson(CyclocrossRaceResult result) {
    return {
      'raceId': result.raceId,
      'raceName': result.raceName,
      'riderId': result.riderId,
      'riderName': result.riderName,
      'placement': result.placement,
      'totalTimeSeconds': result.totalTimeSeconds,
      'pitSwapsCount': result.pitSwapsCount,
      'bunnyHopsSucceeded': result.bunnyHopsSucceeded,
      'rimStrikeIncident': result.rimStrikeIncident,
      'pressureBarUsed': result.pressureBarUsed,
      'treadUsed': result.treadUsed.name,
      'careerBonus': {
        'bikeHandlingGain': result.careerBonus.bikeHandlingGain,
        'cobblesGain': result.careerBonus.cobblesGain,
        'watts1mGain': result.careerBonus.watts1mGain,
        'watts5mGain': result.careerBonus.watts5mGain,
        'ctlFitnessDelta': result.careerBonus.ctlFitnessDelta,
        'atlFatigueDelta': result.careerBonus.atlFatigueDelta,
        'uciPointsEarned': result.careerBonus.uciPointsEarned,
      },
    };
  }

  /// Deserializuje wynik wyścigu CX z mapy JSON z bezpiecznymi wartościami domyślnymi.
  static CyclocrossRaceResult raceResultFromJson(Map<String, dynamic> json) {
    final bonusMap = json['careerBonus'] is Map<String, dynamic>
        ? json['careerBonus'] as Map<String, dynamic>
        : const <String, dynamic>{};

    final treadRaw = json['treadUsed'] as String? ?? 'allRounder';
    final tread = CyclocrossTubularTread.values.firstWhere(
      (e) => e.name.toLowerCase() == treadRaw.toLowerCase(),
      orElse: () => CyclocrossTubularTread.allRounder,
    );

    final placement = ((json['placement'] as num?)?.toInt() ?? 10).clamp(1, 150);
    final totalTimeSeconds =
        ((json['totalTimeSeconds'] as num?)?.toInt() ?? 3600).clamp(600, 14400);
    final pressureBarUsed =
        ((json['pressureBarUsed'] as num?)?.toDouble() ?? 1.55)
            .clamp(1.10, 2.50);

    return CyclocrossRaceResult(
      raceId: json['raceId'] as String? ?? 'cx_unknown',
      raceName: json['raceName'] as String? ?? 'Cyclo-Cross Race',
      riderId: json['riderId'] as String? ?? 'rider_unknown',
      riderName: json['riderName'] as String? ?? 'CX Rider',
      placement: placement,
      totalTimeSeconds: totalTimeSeconds,
      pitSwapsCount: ((json['pitSwapsCount'] as num?)?.toInt() ?? 2).clamp(0, 20),
      bunnyHopsSucceeded:
          ((json['bunnyHopsSucceeded'] as num?)?.toInt() ?? 0).clamp(0, 50),
      rimStrikeIncident: json['rimStrikeIncident'] as bool? ?? false,
      pressureBarUsed: pressureBarUsed,
      treadUsed: tread,
      careerBonus: CyclocrossRoadCareerBonus(
        bikeHandlingGain:
            ((bonusMap['bikeHandlingGain'] as num?)?.toInt() ?? 0).clamp(0, 10),
        cobblesGain:
            ((bonusMap['cobblesGain'] as num?)?.toInt() ?? 0).clamp(0, 10),
        watts1mGain:
            ((bonusMap['watts1mGain'] as num?)?.toInt() ?? 0).clamp(0, 80),
        watts5mGain:
            ((bonusMap['watts5mGain'] as num?)?.toInt() ?? 0).clamp(0, 80),
        ctlFitnessDelta:
            ((bonusMap['ctlFitnessDelta'] as num?)?.toDouble() ?? 0.0)
                .clamp(-10.0, 25.0),
        atlFatigueDelta:
            ((bonusMap['atlFatigueDelta'] as num?)?.toDouble() ?? 0.0)
                .clamp(-10.0, 35.0),
        uciPointsEarned:
            ((bonusMap['uciPointsEarned'] as num?)?.toInt() ?? 0).clamp(0, 500),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'seasonYear': seasonYear,
      'calendarRaceIds': calendarRaceIds,
      'completedResults': completedResults.map(raceResultToJson).toList(),
      'totalCupPoints': totalCupPoints,
      'podiumsCount': podiumsCount,
      'appliedRoadBonusPoints': appliedRoadBonusPoints,
    };
  }

  factory CyclocrossCupSaveState.fromJson(Map<String, dynamic> json) {
    final results = (json['completedResults'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(raceResultFromJson)
        .toList(growable: false);

    final calendarIds = (json['calendarRaceIds'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);

    final computedPodiums = results.where((r) => r.isPodium).length;
    final computedUciPoints = results.fold<int>(
      0,
      (sum, r) => sum + r.careerBonus.uciPointsEarned,
    );

    return CyclocrossCupSaveState(
      seasonYear: ((json['seasonYear'] as num?)?.toInt() ?? 2026)
          .clamp(2020, 2100),
      calendarRaceIds: calendarIds.isNotEmpty
          ? calendarIds
          : CyclocrossWinterCalendarCatalog.build8IconicRaces()
              .map((race) => race.id)
              .toList(growable: false),
      completedResults: results,
      totalCupPoints:
          ((json['totalCupPoints'] as num?)?.toInt() ?? computedUciPoints)
              .clamp(0, 100000),
      podiumsCount:
          ((json['podiumsCount'] as num?)?.toInt() ?? computedPodiums)
              .clamp(0, 500),
      appliedRoadBonusPoints:
          ((json['appliedRoadBonusPoints'] as num?)?.toInt() ??
                  computedUciPoints)
              .clamp(0, 100000),
    );
  }
}

/// Pełny raport z migracji i weryfikacji kompatybilności zapisu v4 (Paczka #4).
@immutable
class SaveCompatibilityV4Report {
  final String saveId;
  final int sourceSchemaVersion;
  final int targetSchemaVersion;
  final V4MigrationStatus status;
  final DateTime migratedAtUtc;
  final String checksumBefore;
  final String checksumAfter;
  final List<Package4SectionSummary> sectionSummaries;
  final List<V4MigrationFieldAction> actions;
  final List<RepairedFieldRecord> baseSaveRepairs;
  final List<SchemaMigrationStep> baseSaveMigrations;
  final Map<String, dynamic>? migratedPayload;
  final IntegritySaveEnvelope? migratedEnvelope;
  final ProCyclistCareerState? hydratedProCyclistState;
  final VelodromeTrackAndHourRecordModel? hydratedVelodromeModel;
  final CyclocrossCupSaveState? hydratedCyclocrossCup;
  final LegendsCardAlbumState? hydratedLegendsAlbum;
  final String summaryMessage;
  final String? errorMessage;

  const SaveCompatibilityV4Report({
    required this.saveId,
    required this.sourceSchemaVersion,
    this.targetSchemaVersion = IntegritySaveEnvelope.currentSchemaVersion,
    required this.status,
    required this.migratedAtUtc,
    required this.checksumBefore,
    required this.checksumAfter,
    this.sectionSummaries = const [],
    this.actions = const [],
    this.baseSaveRepairs = const [],
    this.baseSaveMigrations = const [],
    this.migratedPayload,
    this.migratedEnvelope,
    this.hydratedProCyclistState,
    this.hydratedVelodromeModel,
    this.hydratedCyclocrossCup,
    this.hydratedLegendsAlbum,
    required this.summaryMessage,
    this.errorMessage,
  });

  int get totalFixesCount => actions.length + baseSaveRepairs.length;

  Package4SectionSummary? summaryFor(Package4MigrationSection section) {
    for (final s in sectionSummaries) {
      if (s.section == section) return s;
    }
    return null;
  }
}

/// Automatyczny migrator zapisów gry do schematu v4 z pełną obsługą struktur
/// z Paczki #4: `ProCyclistCareerState`, Rekordy Godzinne UCI, Zimowy Puchar
/// Cyclo-Cross oraz Kolekcja Kart Legend i Paczek Mistrzowskich.
class SaveCompatibilityV4Migrator {
  static const int targetSchemaVersion =
      IntegritySaveEnvelope.currentSchemaVersion;

  /// Migruje surową zawartość pliku JSON zapisu (koperta `IntegritySaveEnvelope`
  /// lub starszy surowy obiekt `CareerSave`).
  static SaveCompatibilityV4Report migrateRawJson({
    required String saveId,
    required String rawJson,
    bool initializeProCyclistIfMissing = false,
  }) {
    final now = DateTime.now().toUtc();
    if (rawJson.trim().isEmpty) {
      return SaveCompatibilityV4Report(
        saveId: saveId,
        sourceSchemaVersion: 0,
        status: V4MigrationStatus.failed,
        migratedAtUtc: now,
        checksumBefore: '',
        checksumAfter: '',
        summaryMessage: 'Plik zapisu jest pusty i nie może zostać zmigrowany.',
        errorMessage: 'EMPTY_JSON_PAYLOAD',
      );
    }

    try {
      final envelope = IntegritySaveEnvelope.tryParse(rawJson);
      final int sourceVersion = envelope?.schemaVersion ?? 1;
      final List<String> history = List<String>.from(
        envelope?.migrationHistory ?? const <String>[],
      );

      final Map<String, dynamic> workingPayload;
      if (envelope != null) {
        workingPayload = jsonDecode(jsonEncode(envelope.payload))
            as Map<String, dynamic>;
      } else {
        final decoded = jsonDecode(rawJson);
        if (decoded is! Map<String, dynamic>) {
          return SaveCompatibilityV4Report(
            saveId: saveId,
            sourceSchemaVersion: 0,
            status: V4MigrationStatus.failed,
            migratedAtUtc: now,
            checksumBefore: '',
            checksumAfter: '',
            summaryMessage: 'Korzeń pliku JSON nie jest mapą obiektu zapisu.',
            errorMessage: 'INVALID_JSON_ROOT',
          );
        }
        workingPayload = decoded;
      }

      final checksumBefore = envelope?.checksum ??
          DatabaseBackupAndIntegrityRepair.computeCanonicalPayloadChecksum(
            workingPayload,
          );

      return _migratePayloadInternal(
        saveId: saveId,
        sourceSchemaVersion: sourceVersion,
        checksumBefore: checksumBefore,
        workingPayload: workingPayload,
        existingHistory: history,
        hadEnvelope: envelope != null,
        initializeProCyclistIfMissing: initializeProCyclistIfMissing,
        now: now,
      );
    } catch (e) {
      return SaveCompatibilityV4Report(
        saveId: saveId,
        sourceSchemaVersion: 0,
        status: V4MigrationStatus.failed,
        migratedAtUtc: now,
        checksumBefore: '',
        checksumAfter: '',
        summaryMessage: 'Nieoczekiwany błąd podczas parsowania zapisu JSON.',
        errorMessage: e.toString(),
      );
    }
  }

  /// Migruje zdekodowaną mapę payloadu `CareerSave` w pamięci.
  static SaveCompatibilityV4Report migratePayloadMap({
    required String saveId,
    required Map<String, dynamic> payload,
    int sourceSchemaVersion = 3,
    bool initializeProCyclistIfMissing = false,
  }) {
    final now = DateTime.now().toUtc();
    try {
      final cloned =
          jsonDecode(jsonEncode(payload)) as Map<String, dynamic>;
      final checksumBefore =
          DatabaseBackupAndIntegrityRepair.computeCanonicalPayloadChecksum(
        cloned,
      );
      return _migratePayloadInternal(
        saveId: saveId,
        sourceSchemaVersion: sourceSchemaVersion,
        checksumBefore: checksumBefore,
        workingPayload: cloned,
        existingHistory: const [],
        hadEnvelope: true,
        initializeProCyclistIfMissing: initializeProCyclistIfMissing,
        now: now,
      );
    } catch (e) {
      return SaveCompatibilityV4Report(
        saveId: saveId,
        sourceSchemaVersion: sourceSchemaVersion,
        status: V4MigrationStatus.failed,
        migratedAtUtc: now,
        checksumBefore: '',
        checksumAfter: '',
        summaryMessage: 'Błąd podczas klonowania lub migracji mapy payloadu.',
        errorMessage: e.toString(),
      );
    }
  }

  static SaveCompatibilityV4Report _migratePayloadInternal({
    required String saveId,
    required int sourceSchemaVersion,
    required String checksumBefore,
    required Map<String, dynamic> workingPayload,
    required List<String> existingHistory,
    required bool hadEnvelope,
    required bool initializeProCyclistIfMissing,
    required DateTime now,
  }) {
    final baseRepairs = <RepairedFieldRecord>[];
    final baseMigrations = <SchemaMigrationStep>[];

    // 1. Bazowa migracja CareerSave (v1 -> v4) przez DatabaseBackupAndIntegrityRepair.
    DatabaseBackupAndIntegrityRepair.migrateAndRepairPayloadInPlace(
      payload: workingPayload,
      fromSchemaVersion: sourceSchemaVersion,
      repairedFields: baseRepairs,
      appliedMigrations: baseMigrations,
    );

    // Weryfikujemy poprawność CareerSave po bazowej migracji.
    final CareerSave baseSave = CareerSave.fromJson(workingPayload);
    final int seasonYear = baseSave.currentSeasonYear;
    final DateTime careerDate = baseSave.currentDate;

    final actions = <V4MigrationFieldAction>[];
    final summaries = <Package4SectionSummary>[];

    // 2. Sekcja Paczki #4: ProCyclistCareerState (Be a Pro).
    final proCyclistOutcome = _migrateProCyclistSection(
      payload: workingPayload,
      baseSave: baseSave,
      initializeIfMissing: initializeProCyclistIfMissing,
      actions: actions,
    );
    summaries.add(proCyclistOutcome.summary);

    // 3. Sekcja Paczki #4: Rekordy Godzinne UCI i Welodromy.
    final hourRecordsOutcome = _migrateHourRecordsSection(
      payload: workingPayload,
      actions: actions,
    );
    summaries.add(hourRecordsOutcome.summary);

    // 4. Sekcja Paczki #4: Zimowy Puchar Cyclo-Cross.
    final cyclocrossOutcome = _migrateCyclocrossSection(
      payload: workingPayload,
      seasonYear: seasonYear,
      actions: actions,
    );
    summaries.add(cyclocrossOutcome.summary);

    // 5. Sekcja Paczki #4: Kolekcja Kart Legend i Paczek Mistrzowskich.
    final albumOutcome = _migrateLegendsAlbumSection(
      payload: workingPayload,
      careerDate: careerDate,
      actions: actions,
    );
    summaries.add(albumOutcome.summary);

    // 6. Zapisujemy zaktualizowaną sumę kontrolną i kopertę v4.
    final canonicalJson = jsonEncode(
      DatabaseBackupAndIntegrityRepair.canonicalizeJsonValue(workingPayload),
    );
    final checksumAfter =
        AutosaveAndCrashRecoveryGuard.computeJsonChecksum(canonicalJson);
    final payloadBytes = utf8.encode(canonicalJson).length;

    final bool anyRepairs =
        baseRepairs.isNotEmpty || actions.any((a) => a.wasRepaired);
    final bool anyChanges = !hadEnvelope ||
        sourceSchemaVersion < targetSchemaVersion ||
        baseRepairs.isNotEmpty ||
        actions.isNotEmpty ||
        checksumBefore != checksumAfter;

    final updatedHistory = List<String>.from(existingHistory);
    if (anyChanges) {
      updatedHistory.add(
        'v$sourceSchemaVersion->v$targetSchemaVersion(pack4)@${now.toIso8601String()}',
      );
    }

    final envelope = IntegritySaveEnvelope(
      schemaVersion: targetSchemaVersion,
      checksumAlgorithm: IntegritySaveEnvelope.checksumAlgorithmName,
      checksum: checksumAfter,
      payloadBytes: payloadBytes,
      savedAtUtc: now,
      migrationHistory: updatedHistory,
      payload: workingPayload,
    );

    final V4MigrationStatus status;
    if (!anyChanges) {
      status = V4MigrationStatus.alreadyCompatible;
    } else if (anyRepairs) {
      status = V4MigrationStatus.repairedAndMigrated;
    } else {
      status = V4MigrationStatus.migrated;
    }

    final String summaryMessage = _buildSummaryMessage(
      status: status,
      sourceVersion: sourceSchemaVersion,
      actionsCount: actions.length,
      baseRepairsCount: baseRepairs.length,
    );

    return SaveCompatibilityV4Report(
      saveId: saveId,
      sourceSchemaVersion: sourceSchemaVersion,
      targetSchemaVersion: targetSchemaVersion,
      status: status,
      migratedAtUtc: now,
      checksumBefore: checksumBefore,
      checksumAfter: checksumAfter,
      sectionSummaries: summaries,
      actions: actions,
      baseSaveRepairs: baseRepairs,
      baseSaveMigrations: baseMigrations,
      migratedPayload: workingPayload,
      migratedEnvelope: envelope,
      hydratedProCyclistState: proCyclistOutcome.hydrated,
      hydratedVelodromeModel: hourRecordsOutcome.hydrated,
      hydratedCyclocrossCup: cyclocrossOutcome.hydrated,
      hydratedLegendsAlbum: albumOutcome.hydrated,
      summaryMessage: summaryMessage,
    );
  }

  static _SectionResult<ProCyclistCareerState?> _migrateProCyclistSection({
    required Map<String, dynamic> payload,
    required CareerSave baseSave,
    required bool initializeIfMissing,
    required List<V4MigrationFieldAction> actions,
  }) {
    const key = 'proCyclistCareer';
    final raw = payload[key];
    final bool presentBefore = raw != null;

    if (raw == null && !initializeIfMissing) {
      return const _SectionResult<ProCyclistCareerState?>(
        hydrated: null,
        summary: Package4SectionSummary(
          section: Package4MigrationSection.proCyclistCareer,
          presentBefore: false,
          validAfter: true,
          recordsCount: 0,
          issuesFixedCount: 0,
          note: 'Tryb menedżerski (opcjonalny profil Be a Pro nieaktywny).',
        ),
      );
    }

    int fixedCount = 0;
    final Map<String, dynamic> sectionMap;
    if (raw is Map<String, dynamic>) {
      sectionMap = Map<String, dynamic>.from(raw);
    } else {
      sectionMap = <String, dynamic>{};
      if (raw != null) {
        fixedCount++;
        actions.add(
          const V4MigrationFieldAction(
            jsonPath: r'$.proCyclistCareer',
            section: Package4MigrationSection.proCyclistCareer,
            reason: 'Nieprawidłowy typ obiektu ProCyclistCareerState',
            appliedValueSummary: 'Zainicjalizowano strukturę domyślną',
            wasRepaired: true,
          ),
        );
      }
    }

    final Rider fallbackRider = baseSave.riders.isNotEmpty
        ? baseSave.riders.first
        : _buildFallbackProRider(baseSave.currentSeasonYear);
    final String fallbackTeamId = baseSave.playerTeamId;
    final String fallbackTeamName = baseSave.teams.isNotEmpty
        ? baseSave.playerTeam.name
        : 'Continental U23 Development';

    fixedCount += _ensureString(
      sectionMap,
      'careerId',
      'pro_${baseSave.id}',
      r'$.proCyclistCareer.careerId',
      Package4MigrationSection.proCyclistCareer,
      'Brak identyfikatora kariery Be a Pro',
      actions,
    );
    fixedCount += _ensureString(
      sectionMap,
      'careerName',
      'Kariera ${fallbackRider.fullName}',
      r'$.proCyclistCareer.careerName',
      Package4MigrationSection.proCyclistCareer,
      'Brak nazwy kariery Be a Pro',
      actions,
    );
    if (sectionMap['playerRider'] is! Map<String, dynamic>) {
      sectionMap['playerRider'] = fallbackRider.toJson();
      fixedCount++;
      actions.add(
        V4MigrationFieldAction(
          jsonPath: r'$.proCyclistCareer.playerRider',
          section: Package4MigrationSection.proCyclistCareer,
          reason: 'Brak lub uszkodzony profil kolarza Be a Pro',
          appliedValueSummary: fallbackRider.fullName,
          wasRepaired: presentBefore,
        ),
      );
    }
    fixedCount += _ensureIsoDate(
      sectionMap,
      'currentDate',
      baseSave.currentDate.toIso8601String(),
      r'$.proCyclistCareer.currentDate',
      Package4MigrationSection.proCyclistCareer,
      'Brak bieżącej daty w ProCyclistCareerState',
      actions,
    );
    fixedCount += _ensureIsoDate(
      sectionMap,
      'careerStartDate',
      baseSave.createdAt.toIso8601String(),
      r'$.proCyclistCareer.careerStartDate',
      Package4MigrationSection.proCyclistCareer,
      'Brak daty rozpoczęcia kariery Be a Pro',
      actions,
    );
    fixedCount += _ensureInt(
      sectionMap,
      'seasonYear',
      baseSave.currentSeasonYear,
      r'$.proCyclistCareer.seasonYear',
      Package4MigrationSection.proCyclistCareer,
      'Brak roku sezonu w ProCyclistCareerState',
      actions,
      min: 2020,
      max: 2100,
    );
    fixedCount += _ensureString(
      sectionMap,
      'currentTeamId',
      fallbackTeamId,
      r'$.proCyclistCareer.currentTeamId',
      Package4MigrationSection.proCyclistCareer,
      'Brak ID drużyny w ProCyclistCareerState',
      actions,
    );
    fixedCount += _ensureString(
      sectionMap,
      'currentTeamName',
      fallbackTeamName,
      r'$.proCyclistCareer.currentTeamName',
      Package4MigrationSection.proCyclistCareer,
      'Brak nazwy drużyny w ProCyclistCareerState',
      actions,
    );
    fixedCount += _ensureString(
      sectionMap,
      'currentDivision',
      TeamDivision.continental.toJson(),
      r'$.proCyclistCareer.currentDivision',
      Package4MigrationSection.proCyclistCareer,
      'Brak dywizji drużyny w ProCyclistCareerState',
      actions,
    );
    fixedCount += _ensureString(
      sectionMap,
      'careerTier',
      ProCyclistCareerTier.u23Continental.toJson(),
      r'$.proCyclistCareer.careerTier',
      Package4MigrationSection.proCyclistCareer,
      'Brak rangi kariery Be a Pro',
      actions,
    );
    fixedCount += _ensureDouble(
      sectionMap,
      'dsTrustScore',
      35.0,
      r'$.proCyclistCareer.dsTrustScore',
      Package4MigrationSection.proCyclistCareer,
      'Brak lub przekroczony zakres dsTrustScore',
      actions,
      min: 0.0,
      max: 100.0,
    );
    fixedCount += _ensureInt(
      sectionMap,
      'skillPoints',
      5,
      r'$.proCyclistCareer.skillPoints',
      Package4MigrationSection.proCyclistCareer,
      'Brak punktów umiejętności (SP)',
      actions,
      min: 0,
      max: 9999,
    );
    fixedCount += _ensureInt(
      sectionMap,
      'privateBalanceEur',
      2500,
      r'$.proCyclistCareer.privateBalanceEur',
      Package4MigrationSection.proCyclistCareer,
      'Brak salda prywatnego kolarza',
      actions,
      min: -1000000,
      max: 1000000000,
    );

    final hydrated = ProCyclistCareerState.fromJson(sectionMap);
    payload[key] = hydrated.toJson();

    if (!presentBefore && initializeIfMissing) {
      actions.add(
        V4MigrationFieldAction(
          jsonPath: r'$.proCyclistCareer',
          section: Package4MigrationSection.proCyclistCareer,
          reason: 'Dodano brakujący profil kariery Be a Pro (Paczka #4)',
          appliedValueSummary: hydrated.playerRider.fullName,
        ),
      );
      fixedCount++;
    }

    return _SectionResult<ProCyclistCareerState?>(
      hydrated: hydrated,
      summary: Package4SectionSummary(
        section: Package4MigrationSection.proCyclistCareer,
        presentBefore: presentBefore,
        validAfter: true,
        recordsCount: 1 +
            hydrated.ownedProperties.length +
            hydrated.achievementJournal.length,
        issuesFixedCount: fixedCount,
        note: '${hydrated.playerRider.fullName} (${hydrated.careerTier.label})',
      ),
    );
  }

  static _SectionResult<VelodromeTrackAndHourRecordModel>
      _migrateHourRecordsSection({
    required Map<String, dynamic> payload,
    required List<V4MigrationFieldAction> actions,
  }) {
    const key = 'hourRecords';
    final raw = payload[key];
    int fixedCount = 0;

    final VelodromeTrackAndHourRecordModel defaults =
        VelodromeTrackAndHourRecordModel.standard();

    if (raw == null) {
      payload[key] = defaults.toJson();
      fixedCount++;
      actions.add(
        V4MigrationFieldAction(
          jsonPath: r'$.hourRecords',
          section: Package4MigrationSection.hourRecords,
          reason: 'Brak sekcji Rekordów Godzinnych UCI (Paczka #4)',
          appliedValueSummary:
              '${defaults.hourRecordHistory.length} rekordów, ${defaults.availableVelodromes.length} welodromów',
        ),
      );
      return _SectionResult<VelodromeTrackAndHourRecordModel>(
        hydrated: defaults,
        summary: Package4SectionSummary(
          section: Package4MigrationSection.hourRecords,
          presentBefore: false,
          validAfter: true,
          recordsCount: defaults.hourRecordHistory.length,
          issuesFixedCount: fixedCount,
          note: 'Zainicjalizowano oficjalny katalog welodromów i rekordów UCI.',
        ),
      );
    }

    if (raw is! Map<String, dynamic>) {
      payload[key] = defaults.toJson();
      fixedCount++;
      actions.add(
        const V4MigrationFieldAction(
          jsonPath: r'$.hourRecords',
          section: Package4MigrationSection.hourRecords,
          reason: 'Uszkodzona struktura sekcji Rekordów Godzinnych UCI',
          appliedValueSummary: 'Przywrócono domyślny model welodromu i rekordów',
          wasRepaired: true,
        ),
      );
      return _SectionResult<VelodromeTrackAndHourRecordModel>(
        hydrated: defaults,
        summary: Package4SectionSummary(
          section: Package4MigrationSection.hourRecords,
          presentBefore: true,
          validAfter: true,
          recordsCount: defaults.hourRecordHistory.length,
          issuesFixedCount: fixedCount,
          note: 'Naprawiono uszkodzony format danych rekordów godzinnych.',
        ),
      );
    }

    final parsed = VelodromeTrackAndHourRecordModel.fromJson(raw);

    // Uzupełniamy brakujące domyślne welodromy i historyczne rekordy UCI.
    final velodromes = List<VelodromeFacilitySpec>.from(parsed.availableVelodromes);
    if (velodromes.isEmpty) {
      velodromes.addAll(VelodromeTrackAndHourRecordModel.defaultVelodromes);
      fixedCount++;
      actions.add(
        const V4MigrationFieldAction(
          jsonPath: r'$.hourRecords.availableVelodromes',
          section: Package4MigrationSection.hourRecords,
          reason: 'Pusta lista certyfikowanych welodromów',
          appliedValueSummary: 'Dodano domyślny katalog 5 welodromów 250 m',
          wasRepaired: true,
        ),
      );
    }

    final existingRecordIds = parsed.hourRecordHistory.map((e) => e.id).toSet();
    final mergedRecords = List<UciHourRecordEntry>.from(parsed.hourRecordHistory);
    int addedDefaultRecords = 0;
    for (final defRecord
        in VelodromeTrackAndHourRecordModel.defaultHourRecordHistory) {
      if (!existingRecordIds.contains(defRecord.id)) {
        mergedRecords.add(defRecord);
        addedDefaultRecords++;
      }
    }
    if (addedDefaultRecords > 0) {
      fixedCount++;
      actions.add(
        V4MigrationFieldAction(
          jsonPath: r'$.hourRecords.hourRecordHistory',
          section: Package4MigrationSection.hourRecords,
          reason: 'Uzupełniono brakujące oficjalne rekordy godzinne UCI',
          appliedValueSummary: '+$addedDefaultRecords wpisów historycznych',
        ),
      );
    }

    // Normalizujemy flagę aktualnego rekordu świata w każdej kategorii.
    final normalizedRecords = _normalizeWorldRecordFlags(mergedRecords);

    final fixedModel = parsed.copyWith(
      availableVelodromes: velodromes,
      hourRecordHistory: normalizedRecords,
    );
    payload[key] = fixedModel.toJson();

    return _SectionResult<VelodromeTrackAndHourRecordModel>(
      hydrated: fixedModel,
      summary: Package4SectionSummary(
        section: Package4MigrationSection.hourRecords,
        presentBefore: true,
        validAfter: true,
        recordsCount: fixedModel.hourRecordHistory.length,
        issuesFixedCount: fixedCount,
        note:
            'Aktywny tor: ${fixedModel.activeVelodrome.name} (${fixedModel.hourRecordHistory.length} rekordów)',
      ),
    );
  }

  static List<UciHourRecordEntry> _normalizeWorldRecordFlags(
    List<UciHourRecordEntry> records,
  ) {
    final bestByCategory = <UciHourRecordCategory, double>{};
    for (final entry in records) {
      final prev = bestByCategory[entry.category] ?? -1.0;
      if (entry.distanceKm > prev) {
        bestByCategory[entry.category] = entry.distanceKm;
      }
    }
    return records.map((entry) {
      final isBest = entry.distanceKm == bestByCategory[entry.category];
      if (entry.isCurrentWorldRecord == isBest) return entry;
      return entry.copyWith(isCurrentWorldRecord: isBest);
    }).toList(growable: false);
  }

  static _SectionResult<CyclocrossCupSaveState> _migrateCyclocrossSection({
    required Map<String, dynamic> payload,
    required int seasonYear,
    required List<V4MigrationFieldAction> actions,
  }) {
    const key = 'cyclocrossCup';
    final raw = payload[key];
    int fixedCount = 0;

    if (raw == null) {
      final initial = CyclocrossCupSaveState.initial(seasonYear: seasonYear);
      payload[key] = initial.toJson();
      fixedCount++;
      actions.add(
        V4MigrationFieldAction(
          jsonPath: r'$.cyclocrossCup',
          section: Package4MigrationSection.cyclocrossCup,
          reason: 'Brak sekcji Zimowego Pucharu Cyclo-Cross (Paczka #4)',
          appliedValueSummary:
              '${initial.calendarRaceIds.length} wyścigów sezonu $seasonYear',
        ),
      );
      return _SectionResult<CyclocrossCupSaveState>(
        hydrated: initial,
        summary: Package4SectionSummary(
          section: Package4MigrationSection.cyclocrossCup,
          presentBefore: false,
          validAfter: true,
          recordsCount: initial.calendarRaceIds.length,
          issuesFixedCount: fixedCount,
          note: 'Dodano kalendarz 8 wyścigów Zimowego Pucharu CX.',
        ),
      );
    }

    if (raw is! Map<String, dynamic>) {
      final initial = CyclocrossCupSaveState.initial(seasonYear: seasonYear);
      payload[key] = initial.toJson();
      fixedCount++;
      actions.add(
        const V4MigrationFieldAction(
          jsonPath: r'$.cyclocrossCup',
          section: Package4MigrationSection.cyclocrossCup,
          reason: 'Uszkodzona struktura Pucharu Cyclo-Cross',
          appliedValueSummary: 'Przywrócono domyślny stan pucharu CX',
          wasRepaired: true,
        ),
      );
      return _SectionResult<CyclocrossCupSaveState>(
        hydrated: initial,
        summary: Package4SectionSummary(
          section: Package4MigrationSection.cyclocrossCup,
          presentBefore: true,
          validAfter: true,
          recordsCount: initial.calendarRaceIds.length,
          issuesFixedCount: fixedCount,
          note: 'Naprawiono uszkodzone dane Pucharu Cyclo-Cross.',
        ),
      );
    }

    final working = Map<String, dynamic>.from(raw);
    fixedCount += _ensureInt(
      working,
      'seasonYear',
      seasonYear,
      r'$.cyclocrossCup.seasonYear',
      Package4MigrationSection.cyclocrossCup,
      'Brak roku sezonu w Pucharze Cyclo-Cross',
      actions,
      min: 2020,
      max: 2100,
    );

    final hydrated = CyclocrossCupSaveState.fromJson(working);
    payload[key] = hydrated.toJson();

    return _SectionResult<CyclocrossCupSaveState>(
      hydrated: hydrated,
      summary: Package4SectionSummary(
        section: Package4MigrationSection.cyclocrossCup,
        presentBefore: true,
        validAfter: true,
        recordsCount: hydrated.completedResults.length,
        issuesFixedCount: fixedCount,
        note:
            'Ukończono ${hydrated.completedResults.length}/${hydrated.calendarRaceIds.length} wyścigów CX (${hydrated.totalCupPoints} pkt UCI)',
      ),
    );
  }

  static _SectionResult<LegendsCardAlbumState> _migrateLegendsAlbumSection({
    required Map<String, dynamic> payload,
    required DateTime careerDate,
    required List<V4MigrationFieldAction> actions,
  }) {
    const key = 'legendsCardAlbum';
    final raw = payload[key];
    final bool presentBefore = raw != null;
    int fixedCount = 0;

    final defaultEntries = LegendsAlbumCatalog.buildDefaultEntries();
    final defaultPacks = LegendsAlbumCatalog.buildDefaultPendingPacks();

    if (raw == null) {
      final initial = LegendsCardAlbumState(
        entries: defaultEntries,
        pendingPacks: defaultPacks,
        selectedRiderId:
            defaultEntries.isNotEmpty ? defaultEntries.first.riderId : null,
      );
      payload[key] = _legendsAlbumToJson(initial);
      fixedCount++;
      actions.add(
        V4MigrationFieldAction(
          jsonPath: r'$.legendsCardAlbum',
          section: Package4MigrationSection.legendsCardAlbum,
          reason: 'Brak sekcji Kolekcji Kart Legend (Paczka #4)',
          appliedValueSummary:
              '${initial.totalCards} kart, ${initial.unopenedPacks.length} paczek',
        ),
      );
      return _SectionResult<LegendsCardAlbumState>(
        hydrated: initial,
        summary: Package4SectionSummary(
          section: Package4MigrationSection.legendsCardAlbum,
          presentBefore: false,
          validAfter: true,
          recordsCount: initial.totalCards,
          issuesFixedCount: fixedCount,
          note:
              'Zainicjalizowano album ${initial.totalCards} kart i ${initial.unopenedPacks.length} paczki startowe.',
        ),
      );
    }

    if (raw is! Map<String, dynamic>) {
      final initial = LegendsCardAlbumState(
        entries: defaultEntries,
        pendingPacks: defaultPacks,
        selectedRiderId:
            defaultEntries.isNotEmpty ? defaultEntries.first.riderId : null,
      );
      payload[key] = _legendsAlbumToJson(initial);
      fixedCount++;
      actions.add(
        const V4MigrationFieldAction(
          jsonPath: r'$.legendsCardAlbum',
          section: Package4MigrationSection.legendsCardAlbum,
          reason: 'Uszkodzona struktura Kolekcji Kart Legend',
          appliedValueSummary: 'Przywrócono domyślny album kart',
          wasRepaired: true,
        ),
      );
      return _SectionResult<LegendsCardAlbumState>(
        hydrated: initial,
        summary: Package4SectionSummary(
          section: Package4MigrationSection.legendsCardAlbum,
          presentBefore: true,
          validAfter: true,
          recordsCount: initial.totalCards,
          issuesFixedCount: fixedCount,
          note: 'Naprawiono uszkodzoną strukturę albumu kart.',
        ),
      );
    }

    // Parsujemy istniejące wpisy i paczki, zachowując odblokowane karty.
    final rawEntries = raw['entries'] as List<dynamic>? ?? const [];
    final parsedEntries = <AlbumLegendCardEntry>[];
    for (final item in rawEntries) {
      if (item is Map<String, dynamic>) {
        parsedEntries.add(AlbumLegendCardEntry.fromJson(item));
      } else {
        fixedCount++;
      }
    }

    // Dołączamy brakujące karty z katalogu domyślnego bez nadpisywania postępu gracza.
    final existingIds = parsedEntries.map((e) => e.riderId).toSet();
    int addedCatalogCards = 0;
    for (final defEntry in defaultEntries) {
      if (!existingIds.contains(defEntry.riderId)) {
        parsedEntries.add(defEntry);
        addedCatalogCards++;
      }
    }
    if (addedCatalogCards > 0) {
      fixedCount++;
      actions.add(
        V4MigrationFieldAction(
          jsonPath: r'$.legendsCardAlbum.entries',
          section: Package4MigrationSection.legendsCardAlbum,
          reason: 'Dodano nowe karty legend z katalogu Paczki #4',
          appliedValueSummary: '+$addedCatalogCards kart do kolekcji',
        ),
      );
    }

    final rawPacks = raw['pendingPacks'] as List<dynamic>? ?? const [];
    final parsedPacks = <PendingChampionshipPack>[];
    for (final item in rawPacks) {
      if (item is Map<String, dynamic>) {
        parsedPacks.add(PendingChampionshipPack.fromJson(item));
      } else {
        fixedCount++;
      }
    }
    if (raw['pendingPacks'] == null && parsedPacks.isEmpty) {
      parsedPacks.addAll(defaultPacks);
      fixedCount++;
      actions.add(
        V4MigrationFieldAction(
          jsonPath: r'$.legendsCardAlbum.pendingPacks',
          section: Package4MigrationSection.legendsCardAlbum,
          reason: 'Brak listy paczek mistrzowskich',
          appliedValueSummary: '+${defaultPacks.length} paczek startowych',
        ),
      );
    }

    final groupingRaw = raw['groupingMode'] as String? ?? 'byEra';
    final groupingMode = LegendsAlbumGroupingMode.values.firstWhere(
      (m) => m.name.toLowerCase() == groupingRaw.toLowerCase(),
      orElse: () => LegendsAlbumGroupingMode.byEra,
    );

    final filterRaw = raw['filterMode'] as String? ?? 'all';
    final filterMode = LegendsAlbumFilterMode.values.firstWhere(
      (m) => m.name.toLowerCase() == filterRaw.toLowerCase(),
      orElse: () => LegendsAlbumFilterMode.all,
    );

    final int wtWins =
        ((raw['worldTourWinsCount'] as num?)?.toInt() ?? 0).clamp(0, 10000);
    final String? selectedRiderId = raw['selectedRiderId'] as String?;

    final hydrated = LegendsCardAlbumState(
      entries: parsedEntries,
      pendingPacks: parsedPacks,
      groupingMode: groupingMode,
      filterMode: filterMode,
      searchQuery: raw['searchQuery'] as String? ?? '',
      selectedRiderId: selectedRiderId ??
          (parsedEntries.isNotEmpty ? parsedEntries.first.riderId : null),
      worldTourWinsCount: wtWins,
    );

    payload[key] = _legendsAlbumToJson(hydrated);

    return _SectionResult<LegendsCardAlbumState>(
      hydrated: hydrated,
      summary: Package4SectionSummary(
        section: Package4MigrationSection.legendsCardAlbum,
        presentBefore: presentBefore,
        validAfter: true,
        recordsCount: hydrated.totalCards,
        issuesFixedCount: fixedCount,
        note:
            'Odblokowano ${hydrated.unlockedCards}/${hydrated.totalCards} kart (${hydrated.unopenedPacks.length} nieotwartych paczek)',
      ),
    );
  }

  static Map<String, dynamic> _legendsAlbumToJson(
    LegendsCardAlbumState state,
  ) {
    return {
      'entries': state.entries.map((e) => e.toJson()).toList(),
      'pendingPacks': state.pendingPacks.map((p) => p.toJson()).toList(),
      'groupingMode': state.groupingMode.name,
      'filterMode': state.filterMode.name,
      'searchQuery': state.searchQuery,
      'selectedRiderId': state.selectedRiderId,
      'worldTourWinsCount': state.worldTourWinsCount,
    };
  }

  static Rider _buildFallbackProRider(int seasonYear) {
    return RiderProceduralGenerator.generateRider(
      id: 'pro_rider_migrated_$seasonYear',
      nationalityIso: 'POL',
      age: 20,
      targetOverallRating: 72,
    );
  }

  static int _ensureString(
    Map<String, dynamic> map,
    String key,
    String defaultValue,
    String jsonPath,
    Package4MigrationSection section,
    String reason,
    List<V4MigrationFieldAction> actions,
  ) {
    final val = map[key];
    if (val is String && val.trim().isNotEmpty) return 0;
    map[key] = defaultValue;
    actions.add(
      V4MigrationFieldAction(
        jsonPath: jsonPath,
        section: section,
        reason: reason,
        appliedValueSummary: defaultValue,
        wasRepaired: val != null,
      ),
    );
    return 1;
  }

  static int _ensureIsoDate(
    Map<String, dynamic> map,
    String key,
    String defaultIso,
    String jsonPath,
    Package4MigrationSection section,
    String reason,
    List<V4MigrationFieldAction> actions,
  ) {
    final val = map[key];
    if (val is String && DateTime.tryParse(val) != null) return 0;
    map[key] = defaultIso;
    actions.add(
      V4MigrationFieldAction(
        jsonPath: jsonPath,
        section: section,
        reason: reason,
        appliedValueSummary: defaultIso,
        wasRepaired: val != null,
      ),
    );
    return 1;
  }

  static int _ensureInt(
    Map<String, dynamic> map,
    String key,
    int defaultValue,
    String jsonPath,
    Package4MigrationSection section,
    String reason,
    List<V4MigrationFieldAction> actions, {
    required int min,
    required int max,
  }) {
    final val = map[key];
    if (val is num) {
      final intVal = val.toInt();
      if (intVal >= min && intVal <= max) return 0;
      final clamped = intVal.clamp(min, max);
      map[key] = clamped;
      actions.add(
        V4MigrationFieldAction(
          jsonPath: jsonPath,
          section: section,
          reason: '$reason (poza zakresem $min..$max)',
          appliedValueSummary: '$clamped',
          wasRepaired: true,
        ),
      );
      return 1;
    }
    map[key] = defaultValue;
    actions.add(
      V4MigrationFieldAction(
        jsonPath: jsonPath,
        section: section,
        reason: reason,
        appliedValueSummary: '$defaultValue',
        wasRepaired: val != null,
      ),
    );
    return 1;
  }

  static int _ensureDouble(
    Map<String, dynamic> map,
    String key,
    double defaultValue,
    String jsonPath,
    Package4MigrationSection section,
    String reason,
    List<V4MigrationFieldAction> actions, {
    required double min,
    required double max,
  }) {
    final val = map[key];
    if (val is num) {
      final dVal = val.toDouble();
      if (!dVal.isNaN && !dVal.isInfinite && dVal >= min && dVal <= max) {
        return 0;
      }
      final clamped =
          (dVal.isNaN || dVal.isInfinite) ? defaultValue : dVal.clamp(min, max);
      map[key] = clamped;
      actions.add(
        V4MigrationFieldAction(
          jsonPath: jsonPath,
          section: section,
          reason: '$reason (poza zakresem $min..$max)',
          appliedValueSummary: clamped.toStringAsFixed(1),
          wasRepaired: true,
        ),
      );
      return 1;
    }
    map[key] = defaultValue;
    actions.add(
      V4MigrationFieldAction(
        jsonPath: jsonPath,
        section: section,
        reason: reason,
        appliedValueSummary: defaultValue.toStringAsFixed(1),
        wasRepaired: val != null,
      ),
    );
    return 1;
  }

  static String _buildSummaryMessage({
    required V4MigrationStatus status,
    required int sourceVersion,
    required int actionsCount,
    required int baseRepairsCount,
  }) {
    switch (status) {
      case V4MigrationStatus.alreadyCompatible:
        return 'Zapis jest w pełni zgodny ze schematem v4 i Paczką #4.';
      case V4MigrationStatus.migrated:
        return 'Zmigrowano zapis v$sourceVersion -> v$targetSchemaVersion '
            '(dodano $actionsCount struktur Paczki #4).';
      case V4MigrationStatus.repairedAndMigrated:
        return 'Naprawiono i zmigrowano zapis v$sourceVersion -> v$targetSchemaVersion '
            '($actionsCount akcji Paczki #4, $baseRepairsCount napraw bazowych).';
      case V4MigrationStatus.failed:
        return 'Migracja zapisu v4 nie powiodła się.';
    }
  }
}

class _SectionResult<T> {
  final T hydrated;
  final Package4SectionSummary summary;

  const _SectionResult({
    required this.hydrated,
    required this.summary,
  });
}

/// Stan Riverpod panelu diagnostycznego migratora v4 (Paczka #4).
@immutable
class SaveCompatibilityV4State {
  final bool isRunning;
  final bool initializeProCyclistIfMissing;
  final Package4MigrationSection? activeFilter;
  final SaveCompatibilityV4Report? lastReport;

  const SaveCompatibilityV4State({
    this.isRunning = false,
    this.initializeProCyclistIfMissing = false,
    this.activeFilter,
    this.lastReport,
  });

  SaveCompatibilityV4State copyWith({
    bool? isRunning,
    bool? initializeProCyclistIfMissing,
    Package4MigrationSection? activeFilter,
    bool clearFilter = false,
    SaveCompatibilityV4Report? lastReport,
  }) {
    return SaveCompatibilityV4State(
      isRunning: isRunning ?? this.isRunning,
      initializeProCyclistIfMissing:
          initializeProCyclistIfMissing ?? this.initializeProCyclistIfMissing,
      activeFilter: clearFilter ? null : (activeFilter ?? this.activeFilter),
      lastReport: lastReport ?? this.lastReport,
    );
  }
}

/// Kontroler Riverpod zarządzający uruchamianiem i podglądem migracji v4.
class SaveCompatibilityV4Notifier
    extends StateNotifier<SaveCompatibilityV4State> {
  SaveCompatibilityV4Notifier() : super(const SaveCompatibilityV4State());

  void toggleInitializeProCyclist(bool value) {
    state = state.copyWith(initializeProCyclistIfMissing: value);
  }

  void setSectionFilter(Package4MigrationSection? section) {
    if (section == null || state.activeFilter == section) {
      state = state.copyWith(clearFilter: true);
    } else {
      state = state.copyWith(activeFilter: section);
    }
  }

  /// Uruchamia migrację surowego zapisu JSON i zapisuje raport w stanie.
  SaveCompatibilityV4Report runRawJsonMigration({
    required String saveId,
    required String rawJson,
  }) {
    state = state.copyWith(isRunning: true);
    final report = SaveCompatibilityV4Migrator.migrateRawJson(
      saveId: saveId,
      rawJson: rawJson,
      initializeProCyclistIfMissing: state.initializeProCyclistIfMissing,
    );
    state = state.copyWith(
      isRunning: false,
      lastReport: report,
    );
    return report;
  }

  /// Uruchamia migrację mapy payloadu w pamięci i zapisuje raport w stanie.
  SaveCompatibilityV4Report runPayloadMapMigration({
    required String saveId,
    required Map<String, dynamic> payload,
    int sourceSchemaVersion = 3,
  }) {
    state = state.copyWith(isRunning: true);
    final report = SaveCompatibilityV4Migrator.migratePayloadMap(
      saveId: saveId,
      payload: payload,
      sourceSchemaVersion: sourceSchemaVersion,
      initializeProCyclistIfMissing: state.initializeProCyclistIfMissing,
    );
    state = state.copyWith(
      isRunning: false,
      lastReport: report,
    );
    return report;
  }
}

/// Globalny provider migratora kompatybilności v4 (Paczka #4).
final saveCompatibilityV4Provider = StateNotifierProvider<
    SaveCompatibilityV4Notifier, SaveCompatibilityV4State>(
  (ref) => SaveCompatibilityV4Notifier(),
);

/// Responsywny panel diagnostyczny migratora zapisów v4 (Paczka #4).
class SaveCompatibilityV4MigratorPanel extends ConsumerWidget {
  final String saveId;
  final String? sampleRawJson;
  final Map<String, dynamic>? samplePayload;
  final VoidCallback? onMigrationCompleted;

  const SaveCompatibilityV4MigratorPanel({
    super.key,
    this.saveId = 'active_career_slot',
    this.sampleRawJson,
    this.samplePayload,
    this.onMigrationCompleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(saveCompatibilityV4Provider);
    final notifier = ref.read(saveCompatibilityV4Provider.notifier);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 600;
        final bool isWide = constraints.maxWidth >= 1000;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 1),
          ),
          padding: EdgeInsets.all(isCompact ? 14 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(state, isCompact),
              const SizedBox(height: 14),
              _buildControlsBar(
                state: state,
                notifier: notifier,
                isCompact: isCompact,
              ),
              const SizedBox(height: 16),
              if (state.lastReport == null)
                _buildEmptyState()
              else ...[
                _buildReportBanner(state.lastReport!, isCompact),
                const SizedBox(height: 14),
                _buildSectionsGrid(
                  report: state.lastReport!,
                  state: state,
                  notifier: notifier,
                  isCompact: isCompact,
                  isWide: isWide,
                ),
                const SizedBox(height: 14),
                _buildActionsLog(state.lastReport!, state.activeFilter),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(SaveCompatibilityV4State state, bool isCompact) {
    final statusColor =
        state.lastReport?.status.color ?? AppColors.goldAccent;
    final statusText =
        state.lastReport?.status.labelPl ?? 'OCZEKUJE NA AUDYT V4';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: const Icon(
            Icons.upgrade_rounded,
            color: AppColors.goldAccent,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Migrator Kompatybilności Zapisu v4 (Paczka #4)',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isCompact ? 15 : 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'ProCyclistCareerState • Rekordy Godzinne • Puchar CX • Kolekcja Kart',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isCompact ? 11.5 : 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (!isCompact) ...[
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withValues(alpha: 0.5)),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildControlsBar({
    required SaveCompatibilityV4State state,
    required SaveCompatibilityV4Notifier notifier,
    required bool isCompact,
  }) {
    final bool canRun = !state.isRunning &&
        (sampleRawJson != null || samplePayload != null);

    final toggleChip = _InteractiveToggleChip(
      label: 'Inicjalizuj Be a Pro jeśli brak',
      selected: state.initializeProCyclistIfMissing,
      enabled: !state.isRunning,
      onChanged: notifier.toggleInitializeProCyclist,
    );

    final runButton = _InteractiveActionButton(
      label: state.isRunning ? 'Migrowanie...' : 'Uruchom Migrację v4',
      icon: Icons.play_arrow_rounded,
      enabled: canRun,
      onPressed: () {
        if (sampleRawJson != null) {
          notifier.runRawJsonMigration(
            saveId: saveId,
            rawJson: sampleRawJson!,
          );
        } else if (samplePayload != null) {
          notifier.runPayloadMapMigration(
            saveId: saveId,
            payload: samplePayload!,
          );
        }
        onMigrationCompleted?.call();
      },
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          toggleChip,
          const SizedBox(height: 10),
          runButton,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: toggleChip),
        const SizedBox(width: 12),
        runButton,
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppColors.accentBlue,
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Uruchom migrację v4, aby automatycznie uzupełnić i zweryfikować '
              'struktury Paczki #4 dla wskazanego zapisu kariery.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportBanner(
    SaveCompatibilityV4Report report,
    bool isCompact,
  ) {
    final color = report.status.color;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                report.status.isSuccess
                    ? Icons.verified_rounded
                    : Icons.error_outline_rounded,
                color: color,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  report.summaryMessage,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: isCompact ? 12 : 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (report.checksumAfter.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Schemat: v${report.sourceSchemaVersion} → v${report.targetSchemaVersion}  •  '
              'CRC/FNV: ${report.checksumAfter}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: AppColors.textSecondary,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionsGrid({
    required SaveCompatibilityV4Report report,
    required SaveCompatibilityV4State state,
    required SaveCompatibilityV4Notifier notifier,
    required bool isCompact,
    required bool isWide,
  }) {
    final cards = report.sectionSummaries.map((summary) {
      final bool isSelected = state.activeFilter == summary.section;
      return _SectionSummaryCard(
        summary: summary,
        isSelected: isSelected,
        onTap: () => notifier.setSectionFilter(summary.section),
      );
    }).toList(growable: false);

    if (isCompact) {
      return Column(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            cards[i],
            if (i < cards.length - 1) const SizedBox(height: 8),
          ],
        ],
      );
    }

    final int columns = isWide ? 4 : 2;
    final List<Widget> rows = [];
    for (int i = 0; i < cards.length; i += columns) {
      final slice = cards.skip(i).take(columns).toList(growable: false);
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int j = 0; j < slice.length; j++) ...[
              Expanded(child: slice[j]),
              if (j < slice.length - 1) const SizedBox(width: 10),
            ],
          ],
        ),
      );
      if (i + columns < cards.length) {
        rows.add(const SizedBox(height: 10));
      }
    }
    return Column(children: rows);
  }

  Widget _buildActionsLog(
    SaveCompatibilityV4Report report,
    Package4MigrationSection? filter,
  ) {
    final filtered = filter == null
        ? report.actions
        : report.actions.where((a) => a.section == filter).toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            filter == null
                ? 'Dziennik migracji Paczki #4 (${filtered.length})'
                : 'Filtr: ${filter.labelPl} (${filtered.length})',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          if (filtered.isEmpty)
            const Text(
              'Brak dodatkowych zmian w wybranej sekcji — struktura była kompletna.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            )
          else
            for (final action in filtered.take(8))
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      action.wasRepaired
                          ? Icons.build_circle_outlined
                          : Icons.add_circle_outline_rounded,
                      size: 15,
                      color: action.wasRepaired
                          ? AppColors.amberWarning
                          : AppColors.statusSuccess,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${action.jsonPath} — ${action.reason} (${action.appliedValueSummary})',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _SectionSummaryCard extends StatefulWidget {
  final Package4SectionSummary summary;
  final bool isSelected;
  final VoidCallback onTap;

  const _SectionSummaryCard({
    required this.summary,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SectionSummaryCard> createState() => _SectionSummaryCardState();
}

class _SectionSummaryCardState extends State<_SectionSummaryCard> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isSelected
        ? AppColors.goldAccent
        : _focused
            ? AppColors.accentBlue
            : _hovered
                ? AppColors.primaryAccent
                : AppColors.cardBorder;

    final bgColor = _pressed
        ? AppColors.surface
        : _hovered
            ? AppColors.surfaceLight.withValues(alpha: 0.9)
            : AppColors.surfaceLight;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: widget.isSelected ? 1.5 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    widget.summary.section.icon,
                    size: 16,
                    color: widget.isSelected
                        ? AppColors.goldAccent
                        : AppColors.accentBlue,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.summary.section.labelPl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                widget.summary.note,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Rekordy: ${widget.summary.recordsCount} • Zmiany: ${widget.summary.issuesFixedCount}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.goldAccent,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InteractiveToggleChip extends StatefulWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _InteractiveToggleChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  @override
  State<_InteractiveToggleChip> createState() => _InteractiveToggleChipState();
}

class _InteractiveToggleChipState extends State<_InteractiveToggleChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = !widget.enabled
        ? AppColors.cardBorder.withValues(alpha: 0.4)
        : widget.selected
            ? AppColors.goldAccent
            : _focused
                ? AppColors.accentBlue
                : _hovered
                    ? AppColors.primaryAccent
                    : AppColors.cardBorder;

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: widget.enabled ? () => widget.onChanged(!widget.selected) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight.withValues(
              alpha: widget.enabled ? 1.0 : 0.45,
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.selected
                    ? Icons.check_box_rounded
                    : Icons.check_box_outline_blank_rounded,
                size: 18,
                color: widget.enabled
                    ? (widget.selected
                        ? AppColors.goldAccent
                        : AppColors.textSecondary)
                    : AppColors.textSecondary.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: widget.enabled
                        ? AppColors.textPrimary
                        : AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InteractiveActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  const _InteractiveActionButton({
    required this.label,
    required this.icon,
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
    final Color bg = !widget.enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.5)
        : _pressed
            ? AppColors.primaryAccent.withValues(alpha: 0.85)
            : _hovered
                ? AppColors.primaryAccent
                : AppColors.primaryAccent.withValues(alpha: 0.92);

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown:
            widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp:
            widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _focused
                  ? AppColors.goldAccent
                  : widget.enabled
                      ? AppColors.goldAccent.withValues(alpha: 0.45)
                      : AppColors.cardBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: widget.enabled
                    ? AppColors.textPrimary
                    : AppColors.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: widget.enabled
                      ? AppColors.textPrimary
                      : AppColors.textSecondary.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
