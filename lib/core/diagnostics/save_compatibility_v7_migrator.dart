// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/multiplayer/online_league_and_ghost_challenge_model.dart';
import '../../models/organizer/race_organizer_empire_model.dart';
import '../../models/race/mtb_xco_course_and_suspension_model.dart';
import '../../models/race/uci_commissaire_rulebook_and_var_model.dart';
import '../../models/race/ultra_endurance_bikepacking_race_model.dart';
import '../../models/team/in_house_bike_brand_manufacturing_model.dart';
import '../../services/career/global_satellite_training_centers_service.dart';
import '../../services/career/manager_skill_tree_perks_service.dart';
import '../../services/career/transfer_rumor_mill_and_journalists_service.dart';
import '../../services/database/database_backup_and_integrity_repair.dart';
import '../theme/app_colors.dart';
import 'save_compatibility_v4_migrator.dart';

/// Sekcje danych wprowadzone w Paczkach #6 oraz #7 (7A i 7B) objęte migracją v7.
enum Package6And7MigrationSection {
  multiplayerLeaguesAndElo(
    'Ligi Online, ELO i Wyzwania Duchów',
    'multiplayerLeaguesAndElo',
    'Paczka #6',
    Icons.public_rounded,
  ),
  mtbXcoSetup(
    'Kolarstwo Górskie MTB XCO',
    'mtbXcoSetup',
    'Paczka #6',
    Icons.forest_rounded,
  ),
  inHouseBikeBrand(
    'Własna Marka Rowerowa R&D',
    'inHouseBikeBrand',
    'Paczka #6',
    Icons.precision_manufacturing_rounded,
  ),
  uciCommissaireRulebook(
    'Przepisy Komisarza UCI i VAR',
    'uciCommissaireRulebook',
    'Paczka #7A',
    Icons.gavel_rounded,
  ),
  transferRumorMill(
    'Przecieki Transferowe i Media',
    'transferRumorMill',
    'Paczka #7A',
    Icons.newspaper_rounded,
  ),
  raceOrganizerEmpire(
    'Tryb Organizatora ASO/RCS',
    'raceOrganizerEmpire',
    'Paczka #7B',
    Icons.stadium_rounded,
  ),
  ultraEnduranceBikepacking(
    'Ultra-Endurance Bikepacking 4000 km',
    'ultraEnduranceBikepacking',
    'Paczka #7B',
    Icons.explore_rounded,
  ),
  globalSatelliteAcademies(
    'Globalne Akademie Satelickie',
    'globalSatelliteAcademies',
    'Paczka #7B',
    Icons.school_rounded,
  ),
  managerSkillTreePerks(
    'Drzewko Perków Menedżera',
    'managerSkillTreePerks',
    'Paczka #7B',
    Icons.account_tree_rounded,
  );

  final String labelPl;
  final String jsonKey;
  final String packageTag;
  final IconData icon;

  const Package6And7MigrationSection(
    this.labelPl,
    this.jsonKey,
    this.packageTag,
    this.icon,
  );
}

/// Wynikowy status migracji zapisu do schematu v7 (Paczki #6 i #7).
enum V7MigrationStatus {
  alreadyCompatible('ZGODNY Z V7 (PACZKI #6–#7)', AppColors.statusSuccess),
  migrated('ZMIGROWANY DO V7', AppColors.accentBlue),
  repairedAndMigrated('NAPRAWIONY I ZMIGROWANY DO V7', AppColors.amberWarning),
  failed('BŁĄD MIGRACJI V7', AppColors.crimsonAlert);

  final String labelPl;
  final Color color;

  const V7MigrationStatus(this.labelPl, this.color);

  bool get isSuccess => this != V7MigrationStatus.failed;
}

/// Pojedyncza akcja uzupełnienia, normalizacji lub naprawy pola podczas migracji v7.
@immutable
class V7MigrationFieldAction {
  final String jsonPath;
  final Package6And7MigrationSection? section;
  final String reason;
  final String appliedValueSummary;
  final bool wasRepaired;

  const V7MigrationFieldAction({
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

/// Podsumowanie stanu pojedynczej sekcji Paczki #6 lub #7 po przejściu migracji v7.
@immutable
class Package6And7SectionSummary {
  final Package6And7MigrationSection section;
  final bool presentBefore;
  final bool validAfter;
  final int recordsCount;
  final int issuesFixedCount;
  final String note;

  const Package6And7SectionSummary({
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

/// Pełny raport migracji kompatybilności zapisu gry do schematu v7.
@immutable
class SaveCompatibilityV7Report {
  final String saveId;
  final int sourceSchemaVersion;
  final int targetSchemaVersion;
  final V7MigrationStatus status;
  final DateTime migratedAtUtc;
  final String checksumBefore;
  final String checksumAfter;
  final List<Package6And7SectionSummary> sectionSummaries;
  final List<V7MigrationFieldAction> actions;
  final SaveCompatibilityV4Report? v4PreMigrationReport;
  final Map<String, dynamic>? migratedPayload;
  final IntegritySaveEnvelope? migratedEnvelope;
  final EloRatingProfile? hydratedEloProfile;
  final List<OnlineLeagueModel> hydratedOnlineLeagues;
  final List<GhostChallengeModel> hydratedGhostChallenges;
  final MtbXcoBikeConfiguration? hydratedMtbXcoConfig;
  final InHouseBikeBrandModel? hydratedInHouseBrand;
  final UciCommissaireRulebookAndVarModel? hydratedUciRulebook;
  final TransferRumorMillState? hydratedTransferRumorMill;
  final RaceOrganizerEmpireModel? hydratedOrganizerEmpire;
  final UltraEnduranceBikepackingRaceModel? hydratedUltraBikepackingRace;
  final GlobalSatelliteTrainingCentersState? hydratedSatelliteAcademies;
  final ManagerSkillTreeState? hydratedManagerSkillTree;
  final String summaryMessage;
  final String? errorMessage;

  const SaveCompatibilityV7Report({
    required this.saveId,
    required this.sourceSchemaVersion,
    this.targetSchemaVersion = SaveCompatibilityV7Migrator.targetSchemaVersion,
    required this.status,
    required this.migratedAtUtc,
    required this.checksumBefore,
    required this.checksumAfter,
    this.sectionSummaries = const [],
    this.actions = const [],
    this.v4PreMigrationReport,
    this.migratedPayload,
    this.migratedEnvelope,
    this.hydratedEloProfile,
    this.hydratedOnlineLeagues = const [],
    this.hydratedGhostChallenges = const [],
    this.hydratedMtbXcoConfig,
    this.hydratedInHouseBrand,
    this.hydratedUciRulebook,
    this.hydratedTransferRumorMill,
    this.hydratedOrganizerEmpire,
    this.hydratedUltraBikepackingRace,
    this.hydratedSatelliteAcademies,
    this.hydratedManagerSkillTree,
    required this.summaryMessage,
    this.errorMessage,
  });

  int get totalFixesCount =>
      actions.length + (v4PreMigrationReport?.totalFixesCount ?? 0);

  int get repairedFixesCount =>
      actions.where((a) => a.wasRepaired).length +
      (v4PreMigrationReport?.actions.where((a) => a.wasRepaired).length ?? 0);

  Package6And7SectionSummary? summaryFor(Package6And7MigrationSection section) {
    for (final s in sectionSummaries) {
      if (s.section == section) return s;
    }
    return null;
  }
}

/// Automatyczny migrator zapisów gry do schematu v7 z pełną obsługą struktur
/// Paczek #6 i #7 (7A i 7B), zachowujący wsteczną kompatybilność z zapisami v1–v6.
class SaveCompatibilityV7Migrator {
  static const int targetSchemaVersion = 7;

  /// Migruje surowy JSON pliku zapisu (`IntegritySaveEnvelope` lub surowy `CareerSave`).
  static SaveCompatibilityV7Report migrateRawJson({
    required String saveId,
    required String rawJson,
    bool initializeOptionalModesIfMissing = false,
  }) {
    final now = DateTime.now().toUtc();
    if (rawJson.trim().isEmpty) {
      return SaveCompatibilityV7Report(
        saveId: saveId,
        sourceSchemaVersion: 0,
        status: V7MigrationStatus.failed,
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
          return SaveCompatibilityV7Report(
            saveId: saveId,
            sourceSchemaVersion: 0,
            status: V7MigrationStatus.failed,
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
        initializeOptionalModesIfMissing: initializeOptionalModesIfMissing,
        now: now,
      );
    } catch (e) {
      return SaveCompatibilityV7Report(
        saveId: saveId,
        sourceSchemaVersion: 0,
        status: V7MigrationStatus.failed,
        migratedAtUtc: now,
        checksumBefore: '',
        checksumAfter: '',
        summaryMessage: 'Nieoczekiwany błąd podczas parsowania zapisu JSON.',
        errorMessage: e.toString(),
      );
    }
  }

  /// Migruje zdekodowaną mapę payloadu `CareerSave` w pamięci do schematu v7.
  static SaveCompatibilityV7Report migratePayloadMap({
    required String saveId,
    required Map<String, dynamic> payload,
    int sourceSchemaVersion = 4,
    bool initializeOptionalModesIfMissing = false,
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
        initializeOptionalModesIfMissing: initializeOptionalModesIfMissing,
        now: now,
      );
    } catch (e) {
      return SaveCompatibilityV7Report(
        saveId: saveId,
        sourceSchemaVersion: sourceSchemaVersion,
        status: V7MigrationStatus.failed,
        migratedAtUtc: now,
        checksumBefore: '',
        checksumAfter: '',
        summaryMessage: 'Błąd podczas klonowania lub migracji mapy payloadu.',
        errorMessage: e.toString(),
      );
    }
  }

  static SaveCompatibilityV7Report _migratePayloadInternal({
    required String saveId,
    required int sourceSchemaVersion,
    required String checksumBefore,
    required Map<String, dynamic> workingPayload,
    required List<String> existingHistory,
    required bool hadEnvelope,
    required bool initializeOptionalModesIfMissing,
    required DateTime now,
  }) {
    final actions = <V7MigrationFieldAction>[];
    final summaries = <Package6And7SectionSummary>[];

    // Krok 0: Jeśli zapis jest starszy niż v4, przepuść go najpierw przez SaveCompatibilityV4Migrator.
    SaveCompatibilityV4Report? v4Report;
    Map<String, dynamic> payload = workingPayload;
    if (sourceSchemaVersion < 4) {
      v4Report = SaveCompatibilityV4Migrator.migratePayloadMap(
        saveId: saveId,
        payload: workingPayload,
        sourceSchemaVersion: sourceSchemaVersion,
      );
      if (!v4Report.status.isSuccess || v4Report.migratedPayload == null) {
        return SaveCompatibilityV7Report(
          saveId: saveId,
          sourceSchemaVersion: sourceSchemaVersion,
          status: V7MigrationStatus.failed,
          migratedAtUtc: now,
          checksumBefore: checksumBefore,
          checksumAfter: checksumBefore,
          v4PreMigrationReport: v4Report,
          summaryMessage:
              'Nie powiodła się wstępna migracja v$sourceSchemaVersion -> v4.',
          errorMessage: v4Report.errorMessage ?? 'V4_PRE_MIGRATION_FAILED',
        );
      }
      payload = jsonDecode(jsonEncode(v4Report.migratedPayload!))
          as Map<String, dynamic>;
    }

    final int seasonYear = _extractSeasonYear(payload, now);
    final String teamId = _extractString(payload, const [
          'playerTeamId',
          'teamId',
        ]) ??
        'team_player_wt';
    final String teamName = _extractString(payload, const [
          'playerTeamName',
          'teamName',
        ]) ??
        'Pro Peloton Team';
    final String managerName = _extractString(payload, const [
          'managerName',
        ]) ??
        'Dyrektor Sportowy';

    // 1. Paczka #6 — Ligi Online, ELO i Wyzwania Duchów
    final mpRes = _migrateMultiplayerLeaguesAndElo(
      payload: payload,
      teamId: teamId,
      managerName: managerName,
      actions: actions,
    );
    summaries.add(mpRes.summary);

    // 2. Paczka #6 — Kolarstwo Górskie MTB XCO
    final mtbRes = _migrateMtbXcoSetup(
      payload: payload,
      actions: actions,
    );
    summaries.add(mtbRes.summary);

    // 3. Paczka #6 — Własna Marka Rowerowa R&D
    final brandRes = _migrateInHouseBikeBrand(
      payload: payload,
      teamId: teamId,
      teamName: teamName,
      seasonYear: seasonYear,
      initializeIfMissing: initializeOptionalModesIfMissing,
      actions: actions,
    );
    summaries.add(brandRes.summary);

    // 4. Paczka #7A — Przepisy Komisarza UCI i VAR
    final uciRes = _migrateUciCommissaireRulebook(
      payload: payload,
      seasonYear: seasonYear,
      actions: actions,
    );
    summaries.add(uciRes.summary);

    // 5. Paczka #7A — Przecieki Transferowe i Media
    final rumorRes = _migrateTransferRumorMill(
      payload: payload,
      actions: actions,
    );
    summaries.add(rumorRes.summary);

    // 6. Paczka #7B — Tryb Organizatora ASO/RCS
    final orgRes = _migrateRaceOrganizerEmpire(
      payload: payload,
      seasonYear: seasonYear,
      initializeIfMissing: initializeOptionalModesIfMissing,
      actions: actions,
    );
    summaries.add(orgRes.summary);

    // 7. Paczka #7B — Ultra-Endurance Bikepacking 4000 km
    final ultraRes = _migrateUltraEnduranceBikepacking(
      payload: payload,
      initializeIfMissing: initializeOptionalModesIfMissing,
      actions: actions,
    );
    summaries.add(ultraRes.summary);

    // 8. Paczka #7B — Globalne Akademie Satelickie
    final academyRes = _migrateGlobalSatelliteAcademies(
      payload: payload,
      now: now,
      actions: actions,
    );
    summaries.add(academyRes.summary);

    // 9. Paczka #7B — Drzewko Perków Menedżera
    final skillTreeRes = _migrateManagerSkillTreePerks(
      payload: payload,
      actions: actions,
    );
    summaries.add(skillTreeRes.summary);

    // Aktualizacja wersji schematu i sumy kontrolnej koperty.
    if (payload['schemaVersion'] != targetSchemaVersion) {
      payload['schemaVersion'] = targetSchemaVersion;
    }

    final checksumAfter =
        DatabaseBackupAndIntegrityRepair.computeCanonicalPayloadChecksum(
      payload,
    );
    final canonicalEncoded = jsonEncode(
      DatabaseBackupAndIntegrityRepair.canonicalizeJsonValue(payload),
    );
    final payloadBytes = utf8.encode(canonicalEncoded).length;

    final updatedHistory = List<String>.from(existingHistory);
    if (sourceSchemaVersion < targetSchemaVersion || !hadEnvelope) {
      updatedHistory.add(
        '${now.toIso8601String()}: v$sourceSchemaVersion->v$targetSchemaVersion (Paczki #6-#7)',
      );
    }

    final envelope = IntegritySaveEnvelope(
      schemaVersion: targetSchemaVersion,
      checksumAlgorithm: IntegritySaveEnvelope.checksumAlgorithmName,
      checksum: checksumAfter,
      payloadBytes: payloadBytes,
      savedAtUtc: now,
      migrationHistory: updatedHistory,
      payload: payload,
    );

    final bool anyRepaired = actions.any((a) => a.wasRepaired) ||
        (v4Report?.actions.any((a) => a.wasRepaired) ?? false) ||
        (v4Report?.baseSaveRepairs.isNotEmpty ?? false);
    final bool anyChanged = sourceSchemaVersion < targetSchemaVersion ||
        !hadEnvelope ||
        actions.isNotEmpty ||
        v4Report != null ||
        checksumBefore != checksumAfter;

    final V7MigrationStatus status;
    if (anyRepaired) {
      status = V7MigrationStatus.repairedAndMigrated;
    } else if (anyChanged) {
      status = V7MigrationStatus.migrated;
    } else {
      status = V7MigrationStatus.alreadyCompatible;
    }

    final totalFixes = actions.length + (v4Report?.totalFixesCount ?? 0);
    final summaryMessage = switch (status) {
      V7MigrationStatus.alreadyCompatible =>
        'Zapis jest w 100% zgodny ze schematem v$targetSchemaVersion (Paczki #6 i #7).',
      V7MigrationStatus.migrated =>
        'Zmigrowano zapis v$sourceSchemaVersion → v$targetSchemaVersion '
            '(uzupełniono $totalFixes pól Paczek #6 i #7).',
      V7MigrationStatus.repairedAndMigrated =>
        'Naprawiono i zmigrowano zapis v$sourceSchemaVersion → v$targetSchemaVersion '
            '($totalFixes akcji naprawczych i migracyjnych).',
      V7MigrationStatus.failed => 'Migracja v7 nie powiodła się.',
    };

    return SaveCompatibilityV7Report(
      saveId: saveId,
      sourceSchemaVersion: sourceSchemaVersion,
      targetSchemaVersion: targetSchemaVersion,
      status: status,
      migratedAtUtc: now,
      checksumBefore: checksumBefore,
      checksumAfter: checksumAfter,
      sectionSummaries: summaries,
      actions: actions,
      v4PreMigrationReport: v4Report,
      migratedPayload: payload,
      migratedEnvelope: envelope,
      hydratedEloProfile: mpRes.value.$1,
      hydratedOnlineLeagues: mpRes.value.$2,
      hydratedGhostChallenges: mpRes.value.$3,
      hydratedMtbXcoConfig: mtbRes.value,
      hydratedInHouseBrand: brandRes.value,
      hydratedUciRulebook: uciRes.value,
      hydratedTransferRumorMill: rumorRes.value,
      hydratedOrganizerEmpire: orgRes.value,
      hydratedUltraBikepackingRace: ultraRes.value,
      hydratedSatelliteAcademies: academyRes.value,
      hydratedManagerSkillTree: skillTreeRes.value,
      summaryMessage: summaryMessage,
    );
  }

  // ---------------------------------------------------------------------------
  // Sekcja 1: Paczka #6 — Ligi Online, ELO i Wyzwania Duchów
  // ---------------------------------------------------------------------------
  static _V7SectionResult<
      (
        EloRatingProfile,
        List<OnlineLeagueModel>,
        List<GhostChallengeModel>,
      )> _migrateMultiplayerLeaguesAndElo({
    required Map<String, dynamic> payload,
    required String teamId,
    required String managerName,
    required List<V7MigrationFieldAction> actions,
  }) {
    const section = Package6And7MigrationSection.multiplayerLeaguesAndElo;
    final key = section.jsonKey;

    // Obsługa starszych aliasów kluczy z prototypów Paczki #6.
    final bool hadCanonical = payload[key] is Map<String, dynamic>;
    final bool hadLegacyAlias = !hadCanonical &&
        (payload['eloProfile'] is Map<String, dynamic> ||
            payload['onlineLeagues'] is List ||
            payload['ghostChallenges'] is List);
    final bool presentBefore = hadCanonical || hadLegacyAlias;
    int fixes = 0;

    final Map<String, dynamic> rawMap;
    if (hadCanonical) {
      rawMap = Map<String, dynamic>.from(payload[key] as Map<String, dynamic>);
    } else if (hadLegacyAlias) {
      rawMap = <String, dynamic>{
        if (payload['eloProfile'] is Map<String, dynamic>)
          'eloProfile': payload['eloProfile'],
        if (payload['onlineLeagues'] is List)
          'leagues': payload['onlineLeagues'],
        if (payload['ghostChallenges'] is List)
          'ghostChallenges': payload['ghostChallenges'],
      };
      payload.remove('eloProfile');
      payload.remove('onlineLeagues');
      payload.remove('ghostChallenges');
      actions.add(
        const V7MigrationFieldAction(
          jsonPath: 'multiplayerLeaguesAndElo',
          section: section,
          reason: 'Przeniesiono starsze klucze multiplayer do kontenera v7.',
          appliedValueSummary: 'Scalono eloProfile/onlineLeagues/ghostChallenges',
          wasRepaired: true,
        ),
      );
      fixes++;
    } else {
      rawMap = <String, dynamic>{};
      actions.add(
        const V7MigrationFieldAction(
          jsonPath: 'multiplayerLeaguesAndElo',
          section: section,
          reason: 'Brak sekcji multiplayer z Paczki #6 w starszym zapisie.',
          appliedValueSummary: 'Utworzono domyślny profil ELO (1200) i puste listy',
        ),
      );
      fixes++;
    }

    final rawElo = rawMap['eloProfile'];
    EloRatingProfile eloProfile;
    if (rawElo is Map<String, dynamic>) {
      eloProfile = EloRatingProfile.fromJson(rawElo);
      if (eloProfile.playerId.trim().isEmpty || eloProfile.currentElo < 100) {
        eloProfile = eloProfile.copyWith(
          playerId: eloProfile.playerId.trim().isEmpty
              ? 'player_$teamId'
              : eloProfile.playerId,
          displayName: eloProfile.displayName.trim().isEmpty
              ? managerName
              : eloProfile.displayName,
          currentElo: eloProfile.currentElo < 100
              ? EloCalculator.defaultStartingElo
              : eloProfile.currentElo,
          peakElo: eloProfile.peakElo < EloCalculator.defaultStartingElo
              ? EloCalculator.defaultStartingElo
              : eloProfile.peakElo,
        );
        actions.add(
          const V7MigrationFieldAction(
            jsonPath: 'multiplayerLeaguesAndElo.eloProfile',
            section: section,
            reason: 'Naprawiono nieprawidłowe ID gracza lub zaniżony ranking ELO.',
            appliedValueSummary: 'ELO >= 100, uzupełnione playerId',
            wasRepaired: true,
          ),
        );
        fixes++;
      }
    } else {
      eloProfile = EloRatingProfile(
        playerId: 'player_$teamId',
        displayName: managerName,
        currentElo: EloCalculator.defaultStartingElo,
        peakElo: EloCalculator.defaultStartingElo,
      );
      if (hadCanonical) {
        actions.add(
          const V7MigrationFieldAction(
            jsonPath: 'multiplayerLeaguesAndElo.eloProfile',
            section: section,
            reason: 'Brak obiektu eloProfile w sekcji multiplayer.',
            appliedValueSummary: 'Domyślny profil ELO (1200)',
            wasRepaired: true,
          ),
        );
        fixes++;
      }
    }

    final rawLeagues = rawMap['leagues'] as List<dynamic>? ?? const [];
    final leagues = <OnlineLeagueModel>[];
    for (final entry in rawLeagues) {
      if (entry is Map<String, dynamic>) {
        leagues.add(OnlineLeagueModel.fromJson(entry));
      } else {
        actions.add(
          const V7MigrationFieldAction(
            jsonPath: 'multiplayerLeaguesAndElo.leagues[]',
            section: section,
            reason: 'Usunięto uszkodzony wpis ligi niebędący mapą JSON.',
            appliedValueSummary: 'Pominięto uszkodzony element',
            wasRepaired: true,
          ),
        );
        fixes++;
      }
    }

    final rawGhosts = rawMap['ghostChallenges'] as List<dynamic>? ?? const [];
    final ghosts = <GhostChallengeModel>[];
    for (final entry in rawGhosts) {
      if (entry is Map<String, dynamic>) {
        ghosts.add(GhostChallengeModel.fromJson(entry));
      } else {
        actions.add(
          const V7MigrationFieldAction(
            jsonPath: 'multiplayerLeaguesAndElo.ghostChallenges[]',
            section: section,
            reason: 'Usunięto uszkodzony wpis wyzwania ducha.',
            appliedValueSummary: 'Pominięto uszkodzony element',
            wasRepaired: true,
          ),
        );
        fixes++;
      }
    }

    payload[key] = <String, dynamic>{
      'eloProfile': eloProfile.toJson(),
      'leagues': leagues.map((e) => e.toJson()).toList(growable: false),
      'ghostChallenges': ghosts.map((e) => e.toJson()).toList(growable: false),
    };

    return _V7SectionResult(
      value: (eloProfile, leagues, ghosts),
      summary: Package6And7SectionSummary(
        section: section,
        presentBefore: presentBefore,
        validAfter: true,
        recordsCount: leagues.length + ghosts.length + 1,
        issuesFixedCount: fixes,
        note: 'ELO ${eloProfile.currentElo} • ${leagues.length} lig • ${ghosts.length} wyzwań duchów',
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sekcja 2: Paczka #6 — Kolarstwo Górskie MTB XCO
  // ---------------------------------------------------------------------------
  static _V7SectionResult<MtbXcoBikeConfiguration> _migrateMtbXcoSetup({
    required Map<String, dynamic> payload,
    required List<V7MigrationFieldAction> actions,
  }) {
    const section = Package6And7MigrationSection.mtbXcoSetup;
    final key = section.jsonKey;

    final bool hadCanonical = payload[key] is Map<String, dynamic>;
    final bool hadLegacy = !hadCanonical && payload['mtbSetup'] is Map<String, dynamic>;
    final bool presentBefore = hadCanonical || hadLegacy;
    int fixes = 0;

    MtbXcoBikeConfiguration config;
    if (hadCanonical) {
      config = MtbXcoBikeConfiguration.fromJson(
        payload[key] as Map<String, dynamic>,
      );
    } else if (hadLegacy) {
      config = MtbXcoBikeConfiguration.fromJson(
        payload['mtbSetup'] as Map<String, dynamic>,
      );
      payload.remove('mtbSetup');
      actions.add(
        const V7MigrationFieldAction(
          jsonPath: 'mtbXcoSetup',
          section: section,
          reason: 'Przemianowano starszy klucz mtbSetup na kanoniczny mtbXcoSetup.',
          appliedValueSummary: 'Przeniesiono konfigurację MTB XCO',
          wasRepaired: true,
        ),
      );
      fixes++;
    } else {
      config = const MtbXcoBikeConfiguration(
        bikeId: 'mtb_xco_pro',
        modelName: 'Factory XC 120 Team',
      );
      actions.add(
        const V7MigrationFieldAction(
          jsonPath: 'mtbXcoSetup',
          section: section,
          reason: 'Brak konfiguracji roweru MTB XCO z Paczki #6.',
          appliedValueSummary: 'Factory XC 120 Team (10.2 kg, 34T, 10-52T)',
        ),
      );
      fixes++;
    }

    if (config.totalWeightKg < 7.5 || config.totalWeightKg > 15.0) {
      final clampedWeight = config.totalWeightKg.clamp(7.5, 15.0);
      config = config.copyWith(totalWeightKg: clampedWeight);
      actions.add(
        V7MigrationFieldAction(
          jsonPath: 'mtbXcoSetup.totalWeightKg',
          section: section,
          reason: 'Waga roweru MTB XCO poza zakresem fizycznym [7.5..15.0] kg.',
          appliedValueSummary: '${clampedWeight.toStringAsFixed(1)} kg',
          wasRepaired: true,
        ),
      );
      fixes++;
    }

    if (config.chainringTeeth < 28 || config.chainringTeeth > 40) {
      final clampedTeeth = config.chainringTeeth.clamp(28, 40);
      config = config.copyWith(chainringTeeth: clampedTeeth);
      actions.add(
        V7MigrationFieldAction(
          jsonPath: 'mtbXcoSetup.chainringTeeth',
          section: section,
          reason: 'Liczba zębów tarczy korby MTB poza zakresem [28..40]T.',
          appliedValueSummary: '${clampedTeeth}T',
          wasRepaired: true,
        ),
      );
      fixes++;
    }

    payload[key] = config.toJson();

    return _V7SectionResult(
      value: config,
      summary: Package6And7SectionSummary(
        section: section,
        presentBefore: presentBefore,
        validAfter: true,
        recordsCount: 1,
        issuesFixedCount: fixes,
        note: '${config.modelName} (${config.totalWeightKg.toStringAsFixed(1)} kg)',
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sekcja 3: Paczka #6 — Własna Marka Rowerowa R&D
  // ---------------------------------------------------------------------------
  static _V7SectionResult<InHouseBikeBrandModel?> _migrateInHouseBikeBrand({
    required Map<String, dynamic> payload,
    required String teamId,
    required String teamName,
    required int seasonYear,
    required bool initializeIfMissing,
    required List<V7MigrationFieldAction> actions,
  }) {
    const section = Package6And7MigrationSection.inHouseBikeBrand;
    final key = section.jsonKey;

    final raw = payload[key];
    final bool presentBefore = raw is Map<String, dynamic>;
    int fixes = 0;

    InHouseBikeBrandModel? model;
    if (raw is Map<String, dynamic>) {
      model = InHouseBikeBrandModel.fromJson(raw);
      if (model.brandId.trim().isEmpty || model.brandName.trim().isEmpty) {
        final starter = InHouseBikeBrandModel.createStarter(
          brandId: 'brand_$teamId',
          ownerTeamId: teamId,
          ownerTeamName: teamName,
          brandName: '$teamName Cycles',
          seasonYear: seasonYear,
        );
        model = model.copyWith(
          brandId: model.brandId.trim().isEmpty ? starter.brandId : model.brandId,
          brandName:
              model.brandName.trim().isEmpty ? starter.brandName : model.brandName,
        );
        actions.add(
          const V7MigrationFieldAction(
            jsonPath: 'inHouseBikeBrand.brandId',
            section: section,
            reason: 'Uzupełniono puste identyfikatory własnej marki rowerowej.',
            appliedValueSummary: 'Przypisano ID/nazwę z drużyny gracza',
            wasRepaired: true,
          ),
        );
        fixes++;
      }
      payload[key] = model.toJson();
    } else if (initializeIfMissing) {
      model = InHouseBikeBrandModel.createStarter(
        brandId: 'brand_$teamId',
        ownerTeamId: teamId,
        ownerTeamName: teamName,
        brandName: '$teamName Cycles',
        seasonYear: seasonYear,
      );
      payload[key] = model.toJson();
      actions.add(
        V7MigrationFieldAction(
          jsonPath: key,
          section: section,
          reason: 'Zainicjalizowano fabrykę własnej marki rowerowej (opcja aktywna).',
          appliedValueSummary: model.brandName,
        ),
      );
      fixes++;
    } else {
      payload[key] = null;
    }

    return _V7SectionResult(
      value: model,
      summary: Package6And7SectionSummary(
        section: section,
        presentBefore: presentBefore,
        validAfter: true,
        recordsCount: model == null ? 0 : model.blueprints.length,
        issuesFixedCount: fixes,
        note: model == null
            ? 'Opcjonalny tryb nieaktywny (gotowy do odblokowania w karierze)'
            : '${model.brandName} • ${model.blueprints.length} projektów ram',
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sekcja 4: Paczka #7A — Przepisy Komisarza UCI i VAR
  // ---------------------------------------------------------------------------
  static _V7SectionResult<UciCommissaireRulebookAndVarModel>
      _migrateUciCommissaireRulebook({
    required Map<String, dynamic> payload,
    required int seasonYear,
    required List<V7MigrationFieldAction> actions,
  }) {
    const section = Package6And7MigrationSection.uciCommissaireRulebook;
    final key = section.jsonKey;
    final raw = payload[key];
    final bool presentBefore = raw is Map<String, dynamic>;
    int fixes = 0;

    UciCommissaireRulebookAndVarModel model;
    if (raw is Map<String, dynamic>) {
      model = UciCommissaireRulebookAndVarModel.fromJson(raw);
      if (model.activeRulebook.articles.isEmpty) {
        final fallback = UciCommissaireRulebookAndVarModel.initial(
          seasonYear: seasonYear,
        );
        model = model.copyWith(activeRulebook: fallback.activeRulebook);
        actions.add(
          const V7MigrationFieldAction(
            jsonPath: 'uciCommissaireRulebook.activeRulebook.articles',
            section: section,
            reason: 'Pusta księga przepisów UCI w zapisie.',
            appliedValueSummary: 'Przywrócono bazowe artykuły regulaminu UCI',
            wasRepaired: true,
          ),
        );
        fixes++;
      }
    } else {
      model = UciCommissaireRulebookAndVarModel.initial(seasonYear: seasonYear);
      actions.add(
        V7MigrationFieldAction(
          jsonPath: key,
          section: section,
          reason: 'Brak księgi przepisów Komisarza UCI i VAR (Paczka #7A).',
          appliedValueSummary:
              'UCI Rulebook $seasonYear (${model.activeRulebook.articles.length} art.)',
        ),
      );
      fixes++;
    }

    payload[key] = model.toJson();

    return _V7SectionResult(
      value: model,
      summary: Package6And7SectionSummary(
        section: section,
        presentBefore: presentBefore,
        validAfter: true,
        recordsCount: model.activeRulebook.articles.length,
        issuesFixedCount: fixes,
        note:
            'Sezon ${model.activeRulebook.seasonYear} • Limit ${model.activeRulebook.minBikeWeightKg.toStringAsFixed(1)} kg',
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sekcja 5: Paczka #7A — Przecieki Transferowe i Media
  // ---------------------------------------------------------------------------
  static _V7SectionResult<TransferRumorMillState> _migrateTransferRumorMill({
    required Map<String, dynamic> payload,
    required List<V7MigrationFieldAction> actions,
  }) {
    const section = Package6And7MigrationSection.transferRumorMill;
    final key = section.jsonKey;
    final raw = payload[key];
    final bool presentBefore = raw is Map<String, dynamic>;
    int fixes = 0;

    TransferRumorMillState state;
    if (raw is Map<String, dynamic>) {
      state = TransferRumorMillState.fromJson(raw);
      if (state.journalists.isEmpty) {
        state = state.copyWith(
          journalists:
              TransferRumorMillAndJournalistsService.createDefaultJournalists(),
        );
        actions.add(
          const V7MigrationFieldAction(
            jsonPath: 'transferRumorMill.journalists',
            section: section,
            reason: 'Brak zdefiniowanych dziennikarzy kolarskich.',
            appliedValueSummary: 'Uzupełniono bazową redakcję kolarską',
            wasRepaired: true,
          ),
        );
        fixes++;
      }
    } else {
      state = TransferRumorMillState.initial();
      actions.add(
        V7MigrationFieldAction(
          jsonPath: key,
          section: section,
          reason: 'Brak stanu giełdy plotek transferowych (Paczka #7A).',
          appliedValueSummary:
              '${state.journalists.length} dziennikarzy • wiarygodność ${state.mediaCredibilityScore}%',
        ),
      );
      fixes++;
    }

    payload[key] = state.toJson();

    return _V7SectionResult(
      value: state,
      summary: Package6And7SectionSummary(
        section: section,
        presentBefore: presentBefore,
        validAfter: true,
        recordsCount: state.journalists.length + state.activeRumors.length,
        issuesFixedCount: fixes,
        note:
            '${state.journalists.length} dziennikarzy • ${state.activeRumors.length} aktywnych plotek',
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sekcja 6: Paczka #7B — Tryb Organizatora ASO/RCS
  // ---------------------------------------------------------------------------
  static _V7SectionResult<RaceOrganizerEmpireModel?> _migrateRaceOrganizerEmpire({
    required Map<String, dynamic> payload,
    required int seasonYear,
    required bool initializeIfMissing,
    required List<V7MigrationFieldAction> actions,
  }) {
    const section = Package6And7MigrationSection.raceOrganizerEmpire;
    final key = section.jsonKey;

    final raw = payload[key] ?? payload['organizerEmpire'];
    final bool hadLegacyAlias =
        payload[key] == null && payload['organizerEmpire'] is Map<String, dynamic>;
    final bool presentBefore = raw is Map<String, dynamic>;
    int fixes = 0;

    if (hadLegacyAlias) {
      payload.remove('organizerEmpire');
      actions.add(
        const V7MigrationFieldAction(
          jsonPath: 'raceOrganizerEmpire',
          section: section,
          reason: 'Przemianowano starszy klucz organizerEmpire na raceOrganizerEmpire.',
          appliedValueSummary: 'Ujednolicono strukturę v7',
          wasRepaired: true,
        ),
      );
      fixes++;
    }

    RaceOrganizerEmpireModel? model;
    if (raw is Map<String, dynamic>) {
      model = RaceOrganizerEmpireModel.fromJson(raw);
      payload[key] = model.toJson();
    } else if (initializeIfMissing) {
      model = RaceOrganizerEmpireModel.createStarterAsoPreset(
        seasonYear: seasonYear,
      );
      payload[key] = model.toJson();
      actions.add(
        V7MigrationFieldAction(
          jsonPath: key,
          section: section,
          reason: 'Zainicjalizowano tryb Organizatora Wyścigów ASO/RCS.',
          appliedValueSummary: model.syndicateName,
        ),
      );
      fixes++;
    } else {
      payload[key] = null;
    }

    return _V7SectionResult(
      value: model,
      summary: Package6And7SectionSummary(
        section: section,
        presentBefore: presentBefore,
        validAfter: true,
        recordsCount: model?.managedRaces.length ?? 0,
        issuesFixedCount: fixes,
        note: model == null
            ? 'Opcjonalny tryb Promotora nieaktywny'
            : '${model.syndicateName} • ${model.managedRaces.length} wyścigów',
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sekcja 7: Paczka #7B — Ultra-Endurance Bikepacking 4000 km
  // ---------------------------------------------------------------------------
  static _V7SectionResult<UltraEnduranceBikepackingRaceModel?>
      _migrateUltraEnduranceBikepacking({
    required Map<String, dynamic> payload,
    required bool initializeIfMissing,
    required List<V7MigrationFieldAction> actions,
  }) {
    const section = Package6And7MigrationSection.ultraEnduranceBikepacking;
    final key = section.jsonKey;

    final raw = payload[key];
    final bool presentBefore = raw is Map<String, dynamic>;
    int fixes = 0;

    UltraEnduranceBikepackingRaceModel? model;
    if (raw is Map<String, dynamic>) {
      final rawRace = raw['race'] is Map<String, dynamic>
          ? raw['race'] as Map<String, dynamic>
          : raw;
      model = UltraEnduranceBikepackingRaceModel.fromJson(rawRace);

      UltraBikepackingRiderProgress? progress;
      if (raw['riderProgress'] is Map<String, dynamic>) {
        progress = UltraBikepackingRiderProgress.fromJson(
          raw['riderProgress'] as Map<String, dynamic>,
        );
      }

      payload[key] = <String, dynamic>{
        'race': model.toJson(),
        if (progress != null) 'riderProgress': progress.toJson(),
      };
    } else if (initializeIfMissing) {
      model = UltraEnduranceBikepackingRaceModel.transcontinental4000KmPreset();
      payload[key] = <String, dynamic>{
        'race': model.toJson(),
      };
      actions.add(
        V7MigrationFieldAction(
          jsonPath: key,
          section: section,
          reason: 'Zainicjalizowano preset wyścigu Ultra-Endurance 4000 km.',
          appliedValueSummary: model.name,
        ),
      );
      fixes++;
    } else {
      payload[key] = null;
    }

    return _V7SectionResult(
      value: model,
      summary: Package6And7SectionSummary(
        section: section,
        presentBefore: presentBefore,
        validAfter: true,
        recordsCount: model?.checkpoints.length ?? 0,
        issuesFixedCount: fixes,
        note: model == null
            ? 'Opcjonalny tryb Ultra-Endurance nieaktywny'
            : '${model.name} (${model.totalDistanceKm.toStringAsFixed(0)} km)',
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sekcja 8: Paczka #7B — Globalne Akademie Satelickie
  // ---------------------------------------------------------------------------
  static _V7SectionResult<GlobalSatelliteTrainingCentersState>
      _migrateGlobalSatelliteAcademies({
    required Map<String, dynamic> payload,
    required DateTime now,
    required List<V7MigrationFieldAction> actions,
  }) {
    const section = Package6And7MigrationSection.globalSatelliteAcademies;
    final key = section.jsonKey;

    final raw = payload[key];
    final bool presentBefore = raw is Map<String, dynamic>;
    int fixes = 0;

    GlobalSatelliteTrainingCentersState state;
    if (raw is Map<String, dynamic>) {
      state = GlobalSatelliteTrainingCentersState.fromJson(raw);
      if (state.nodes.length < SatelliteAcademyRegionId.values.length) {
        const service = GlobalSatelliteTrainingCentersService();
        final fallback = service.createInitialNetwork(currentDate: now);
        final merged = Map<SatelliteAcademyRegionId, SatelliteAcademyNode>.from(
          state.nodes,
        );
        for (final region in SatelliteAcademyRegionId.values) {
          merged.putIfAbsent(region, () => fallback[region]!);
        }
        state = state.copyWith(nodes: merged);
        actions.add(
          const V7MigrationFieldAction(
            jsonPath: 'globalSatelliteAcademies.nodes',
            section: section,
            reason: 'Uzupełniono brakujące regiony akademii satelickich.',
            appliedValueSummary: '4 regiony (Sierra Nevada, Kolumbia, Kenijskie Wyżyny, Flandria)',
            wasRepaired: true,
          ),
        );
        fixes++;
      }
    } else {
      const service = GlobalSatelliteTrainingCentersService();
      state = GlobalSatelliteTrainingCentersState(
        nodes: service.createInitialNetwork(currentDate: now),
        selectedRegion: SatelliteAcademyRegionId.sierraNevadaGranada,
        teamBudgetEur: 1850000.0,
        currentDate: now,
        totalInvestedEur: 0.0,
      );
      actions.add(
        V7MigrationFieldAction(
          jsonPath: key,
          section: section,
          reason: 'Brak sieci Globalnych Akademii Satelickich (Paczka #7B).',
          appliedValueSummary: '${state.nodes.length} regionów gotowych do budowy',
        ),
      );
      fixes++;
    }

    payload[key] = state.toJson();

    return _V7SectionResult(
      value: state,
      summary: Package6And7SectionSummary(
        section: section,
        presentBefore: presentBefore,
        validAfter: true,
        recordsCount: state.nodes.length,
        issuesFixedCount: fixes,
        note: '${state.nodes.length} regionów satelickich',
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sekcja 9: Paczka #7B — Drzewko Perków Menedżera
  // ---------------------------------------------------------------------------
  static _V7SectionResult<ManagerSkillTreeState> _migrateManagerSkillTreePerks({
    required Map<String, dynamic> payload,
    required List<V7MigrationFieldAction> actions,
  }) {
    const section = Package6And7MigrationSection.managerSkillTreePerks;
    final key = section.jsonKey;

    final raw = payload[key] ?? payload['skillTree'];
    final bool hadLegacyAlias =
        payload[key] == null && payload['skillTree'] is Map<String, dynamic>;
    final bool presentBefore = raw is Map<String, dynamic>;
    int fixes = 0;

    if (hadLegacyAlias) {
      payload.remove('skillTree');
      actions.add(
        const V7MigrationFieldAction(
          jsonPath: 'managerSkillTreePerks',
          section: section,
          reason: 'Przemianowano klucz skillTree na kanoniczny managerSkillTreePerks.',
          appliedValueSummary: 'Ujednolicono strukturę v7',
          wasRepaired: true,
        ),
      );
      fixes++;
    }

    ManagerSkillTreeState state;
    if (raw is Map<String, dynamic>) {
      state = ManagerSkillTreeState.fromJson(raw);
    } else {
      state = ManagerSkillTreeState.initial();
      actions.add(
        V7MigrationFieldAction(
          jsonPath: key,
          section: section,
          reason: 'Brak drzewka umiejętności i perków menedżera (Paczka #7B).',
          appliedValueSummary:
              'Poziom ${state.managerLevel}, ${state.availableSkillPoints} pkt startowe',
        ),
      );
      fixes++;
    }

    payload[key] = state.toJson();

    return _V7SectionResult(
      value: state,
      summary: Package6And7SectionSummary(
        section: section,
        presentBefore: presentBefore,
        validAfter: true,
        recordsCount: state.unlockedNodeCount,
        issuesFixedCount: fixes,
        note:
            'Poz. ${state.managerLevel} • ${state.unlockedNodeCount} odblokowanych perków',
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Pomocnicze funkcje ekstrakcji pól z payloadu CareerSave
  // ---------------------------------------------------------------------------
  static int _extractSeasonYear(Map<String, dynamic> payload, DateTime now) {
    final directYear = payload['seasonYear'] ?? payload['currentSeasonYear'];
    if (directYear is num && directYear.toInt() >= 2020) {
      return directYear.toInt();
    }
    final rawDate = payload['currentDate'] ?? payload['lastSavedAt'];
    if (rawDate is String) {
      final parsed = DateTime.tryParse(rawDate);
      if (parsed != null && parsed.year >= 2020) {
        return parsed.year;
      }
    }
    return now.year >= 2025 ? now.year : 2026;
  }

  static String? _extractString(
    Map<String, dynamic> payload,
    List<String> candidateKeys,
  ) {
    for (final k in candidateKeys) {
      final val = payload[k];
      if (val is String && val.trim().isNotEmpty) {
        return val.trim();
      }
    }
    return null;
  }
}

class _V7SectionResult<T> {
  final T value;
  final Package6And7SectionSummary summary;

  const _V7SectionResult({
    required this.value,
    required this.summary,
  });
}

// =============================================================================
// STAN RIVERPOD + NOTIFIER
// =============================================================================

@immutable
class SaveCompatibilityV7State {
  final bool isRunning;
  final bool initializeOptionalModesIfMissing;
  final Package6And7MigrationSection? activeFilter;
  final SaveCompatibilityV7Report? lastReport;

  const SaveCompatibilityV7State({
    this.isRunning = false,
    this.initializeOptionalModesIfMissing = false,
    this.activeFilter,
    this.lastReport,
  });

  SaveCompatibilityV7State copyWith({
    bool? isRunning,
    bool? initializeOptionalModesIfMissing,
    Package6And7MigrationSection? activeFilter,
    bool clearFilter = false,
    SaveCompatibilityV7Report? lastReport,
  }) {
    return SaveCompatibilityV7State(
      isRunning: isRunning ?? this.isRunning,
      initializeOptionalModesIfMissing: initializeOptionalModesIfMissing ??
          this.initializeOptionalModesIfMissing,
      activeFilter: clearFilter ? null : (activeFilter ?? this.activeFilter),
      lastReport: lastReport ?? this.lastReport,
    );
  }
}

class SaveCompatibilityV7Notifier extends StateNotifier<SaveCompatibilityV7State> {
  SaveCompatibilityV7Notifier() : super(const SaveCompatibilityV7State());

  void toggleInitializeOptionalModes(bool value) {
    state = state.copyWith(initializeOptionalModesIfMissing: value);
  }

  void setSectionFilter(Package6And7MigrationSection? section) {
    if (section == null || state.activeFilter == section) {
      state = state.copyWith(clearFilter: true);
    } else {
      state = state.copyWith(activeFilter: section);
    }
  }

  SaveCompatibilityV7Report runMigrationOnRawJson({
    required String saveId,
    required String rawJson,
  }) {
    state = state.copyWith(isRunning: true);
    final report = SaveCompatibilityV7Migrator.migrateRawJson(
      saveId: saveId,
      rawJson: rawJson,
      initializeOptionalModesIfMissing: state.initializeOptionalModesIfMissing,
    );
    state = state.copyWith(isRunning: false, lastReport: report);
    return report;
  }

  SaveCompatibilityV7Report runMigrationOnPayload({
    required String saveId,
    required Map<String, dynamic> payload,
    int sourceSchemaVersion = 4,
  }) {
    state = state.copyWith(isRunning: true);
    final report = SaveCompatibilityV7Migrator.migratePayloadMap(
      saveId: saveId,
      payload: payload,
      sourceSchemaVersion: sourceSchemaVersion,
      initializeOptionalModesIfMissing: state.initializeOptionalModesIfMissing,
    );
    state = state.copyWith(isRunning: false, lastReport: report);
    return report;
  }
}

/// Globalny provider migratora kompatybilności v7 (Paczki #6 i #7).
final saveCompatibilityV7Provider = StateNotifierProvider<
    SaveCompatibilityV7Notifier, SaveCompatibilityV7State>(
  (ref) => SaveCompatibilityV7Notifier(),
);

// =============================================================================
// RESPONSYWNY PANEL UI MIGRATORA V7 (LayoutBuilder 390x844 / 1024x768 / 1600x900)
// =============================================================================

/// Responsywny panel diagnostyczny migratora zapisów v7 dla Paczek #6 i #7.
class SaveCompatibilityV7MigratorPanel extends ConsumerWidget {
  final String saveId;
  final String? sampleRawJson;
  final Map<String, dynamic>? samplePayload;
  final int sampleSourceSchemaVersion;
  final VoidCallback? onMigrationCompleted;

  const SaveCompatibilityV7MigratorPanel({
    super.key,
    this.saveId = 'active_career_slot',
    this.sampleRawJson,
    this.samplePayload,
    this.sampleSourceSchemaVersion = 4,
    this.onMigrationCompleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(saveCompatibilityV7Provider);
    final notifier = ref.read(saveCompatibilityV7Provider.notifier);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 640;
        final bool isWide = constraints.maxWidth >= 1024;

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

  Widget _buildHeader(SaveCompatibilityV7State state, bool isCompact) {
    final statusColor = state.lastReport?.status.color ?? AppColors.goldAccent;
    final statusText =
        state.lastReport?.status.labelPl ?? 'OCZEKUJE NA MIGRACJĘ V7';

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
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Migrator Kompatybilności Zapisów v7 (Paczki #6–#7)',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isCompact ? 15 : 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Waliduje i migruje struktury Ligi Online/ELO, MTB XCO, Własnej Marki R&D, Przepisów UCI VAR, Plotek Transferowych, Organizatora ASO/RCS, Ultra-Bikepackingu, Akademii i Perków.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
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
              borderRadius: BorderRadius.circular(999),
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
    required SaveCompatibilityV7State state,
    required SaveCompatibilityV7Notifier notifier,
    required bool isCompact,
  }) {
    final toggleButton = _V7ToggleChip(
      label: 'Inicjalizuj opcjonalne tryby (Marka / ASO / Ultra)',
      selected: state.initializeOptionalModesIfMissing,
      onTap: () => notifier.toggleInitializeOptionalModes(
        !state.initializeOptionalModesIfMissing,
      ),
    );

    final runButton = _V7ActionButton(
      label: state.isRunning
          ? 'Migrowanie do v7...'
          : 'Uruchom migrację v7',
      icon: Icons.play_arrow_rounded,
      enabled: !state.isRunning,
      onPressed: () {
        if (sampleRawJson != null) {
          notifier.runMigrationOnRawJson(
            saveId: saveId,
            rawJson: sampleRawJson!,
          );
        } else {
          notifier.runMigrationOnPayload(
            saveId: saveId,
            payload: samplePayload ??
                <String, dynamic>{
                  'saveId': saveId,
                  'teamName': 'Polonia Pro Cycling',
                  'seasonYear': 2026,
                },
            sourceSchemaVersion: sampleSourceSchemaVersion,
          );
        }
        onMigrationCompleted?.call();
      },
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          toggleButton,
          const SizedBox(height: 10),
          runButton,
        ],
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 10,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        toggleButton,
        runButton,
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppColors.accentBlue,
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Naciśnij „Uruchom migrację v7”, aby sprawdzić i uaktualnić zapis gry do schematu v7 (Paczki #6 i #7).',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportBanner(SaveCompatibilityV7Report report, bool isCompact) {
    final color = report.status.color;
    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                report.status.labelPl,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                'v${report.sourceSchemaVersion} → v${report.targetSchemaVersion}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Akcje: ${report.totalFixesCount} (naprawy: ${report.repairedFixesCount})',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            report.summaryMessage,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionsGrid({
    required SaveCompatibilityV7Report report,
    required SaveCompatibilityV7State state,
    required SaveCompatibilityV7Notifier notifier,
    required bool isCompact,
    required bool isWide,
  }) {
    final int columns = isCompact ? 1 : (isWide ? 3 : 2);
    const double spacing = 10;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: report.sectionSummaries.map((summary) {
            final isSelected = state.activeFilter == summary.section;
            return SizedBox(
              width: itemWidth,
              child: _V7SectionCard(
                summary: summary,
                selected: isSelected,
                onTap: () => notifier.setSectionFilter(summary.section),
              ),
            );
          }).toList(growable: false),
        );
      },
    );
  }

  Widget _buildActionsLog(
    SaveCompatibilityV7Report report,
    Package6And7MigrationSection? filter,
  ) {
    final filtered = filter == null
        ? report.actions
        : report.actions.where((a) => a.section == filter).toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.receipt_long_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  filter == null
                      ? 'Dziennik migracji v7 (${filtered.length})'
                      : 'Dziennik: ${filter.labelPl} (${filtered.length})',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (filtered.isEmpty)
            const Text(
              'Brak wymaganych modyfikacji w wybranym zakresie — wszystkie pola były poprawne.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            )
          else
            ...filtered.take(12).map(
                  (action) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          action.wasRepaired
                              ? Icons.build_circle_rounded
                              : Icons.add_circle_outline_rounded,
                          size: 15,
                          color: action.wasRepaired
                              ? AppColors.amberWarning
                              : AppColors.accentBlue,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${action.jsonPath} — ${action.appliedValueSummary}',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                action.reason,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _V7SectionCard extends StatefulWidget {
  final Package6And7SectionSummary summary;
  final bool selected;
  final VoidCallback onTap;

  const _V7SectionCard({
    required this.summary,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_V7SectionCard> createState() => _V7SectionCardState();
}

class _V7SectionCardState extends State<_V7SectionCard> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.selected
        ? AppColors.goldAccent
        : _focused
            ? AppColors.accentBlue
            : _hovered
                ? AppColors.primaryAccent
                : AppColors.cardBorder;

    final bgColor = _pressed
        ? AppColors.surface
        : (_hovered || widget.selected
            ? AppColors.surfaceLight
            : AppColors.background);

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor: SystemMouseCursors.click,
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
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    widget.summary.section.icon,
                    size: 16,
                    color: widget.selected
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Text(
                      widget.summary.section.packageTag,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.goldAccent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.summary.presentBefore
                          ? 'Zaktualizowano (${widget.summary.issuesFixedCount})'
                          : 'Dodano domyślnie',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontFeatures: [FontFeature.tabularFigures()],
                        color: AppColors.textSecondary,
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
            ],
          ),
        ),
      ),
    );
  }
}

class _V7ToggleChip extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _V7ToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_V7ToggleChip> createState() => _V7ToggleChipState();
}

class _V7ToggleChipState extends State<_V7ToggleChip> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.selected
        ? AppColors.goldAccent
        : _focused
            ? AppColors.accentBlue
            : _hovered
                ? AppColors.primaryAccent
                : AppColors.cardBorder;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: _pressed
                ? AppColors.surface
                : widget.selected
                    ? AppColors.goldAccent.withValues(alpha: 0.14)
                    : (_hovered ? AppColors.surfaceLight : AppColors.background),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.selected
                    ? Icons.check_box_rounded
                    : Icons.check_box_outline_blank_rounded,
                size: 16,
                color: widget.selected
                    ? AppColors.goldAccent
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: widget.selected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
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

class _V7ActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  const _V7ActionButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_V7ActionButton> createState() => _V7ActionButtonState();
}

class _V7ActionButtonState extends State<_V7ActionButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = !widget.enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.5)
        : _pressed
            ? AppColors.primaryAccent.withValues(alpha: 0.8)
            : _hovered
                ? AppColors.primaryAccent.withValues(alpha: 0.92)
                : AppColors.primaryAccent;

    final borderColor = _focused
        ? AppColors.goldAccent
        : (widget.enabled ? AppColors.primaryAccent : AppColors.cardBorder);

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel:
            widget.enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
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
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: widget.enabled
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
