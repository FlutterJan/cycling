// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/career/team_esg_sustainability_and_green_fleet_model.dart';
import '../../models/esports/uci_cycling_esports_world_model.dart';
import '../../models/retro/golden_era_retro_season_model.dart';
import '../../services/career/dynamic_rider_nickname_generator.dart';
import '../../services/career/end_of_career_hall_of_fame_retirement_mode.dart';
import '../../services/career/national_federation_team_manager_mode.dart';
import '../../services/career/rider_personal_life_and_family_events.dart';
import '../../services/career/team_merchandise_and_fan_club_revenue.dart';
import '../../services/career/transfer_deadline_day_live_event.dart';
import '../../services/database/database_backup_and_integrity_repair.dart';
import '../config/app_feature_flags_and_presets.dart';
import '../theme/app_colors.dart';
import 'save_compatibility_v7_migrator.dart';

/// Sekcje danych wprowadzone w Paczce #8 (#563–#612) objęte migracją v8.
enum Package8MigrationSection {
  goldenEraRetroSeason(
    'Złota Era Kolarstwa (1970–2015)',
    'goldenEraRetroSeason',
    'Retro #563',
    Icons.history_edu_rounded,
  ),
  uciCyclingEsports(
    'UCI Cycling Esports & Talent ID',
    'uciCyclingEsports',
    'e-Sports #567',
    Icons.sensors_rounded,
  ),
  teamEsgSustainability(
    'Ekonomia ESG i Zielona Flota',
    'teamEsgSustainability',
    'ESG #571',
    Icons.eco_rounded,
  ),
  riderPersonalLifeEvents(
    'Życie Osobiste i Urlopy Kolarzy',
    'riderPersonalLifeEvents',
    'Kariera #577',
    Icons.family_restroom_rounded,
  ),
  nationalFederationCampaign(
    'Selekcjoner Reprezentacji Narodowej',
    'nationalFederationCampaign',
    'Kadra #580',
    Icons.flag_rounded,
  ),
  transferDeadlineDay(
    'Transfer Deadline Day Live',
    'transferDeadlineDay',
    'Rynek #583',
    Icons.timer_rounded,
  ),
  teamMerchandiseAndFanClub(
    'Sklep Klubowy i Strefy Kibica',
    'teamMerchandiseAndFanClub',
    'Finanse #587',
    Icons.storefront_rounded,
  ),
  riderNicknamesRegistry(
    'Rejestr Przydomków Kolarskich',
    'riderNicknamesRegistry',
    'Media #591',
    Icons.badge_rounded,
  ),
  hallOfFameAndDynasty(
    'Księga Legendy i Dynastia NG+',
    'hallOfFameAndDynasty',
    'Dynastia #597',
    Icons.workspace_premium_rounded,
  ),
  gameplayRealismConfig(
    'Flagi Realizmu i Presety Rozgrywki',
    'gameplayRealismConfig',
    'Konfig #599',
    Icons.tune_rounded,
  );

  final String labelPl;
  final String jsonKey;
  final String packageTag;
  final IconData icon;

  const Package8MigrationSection(
    this.labelPl,
    this.jsonKey,
    this.packageTag,
    this.icon,
  );
}

/// Wynikowy status migracji zapisu do schematu v8 (Paczka #8).
enum V8MigrationStatus {
  alreadyCompatible('ZGODNY Z V8 (PACZKA #8)', AppColors.statusSuccess),
  migrated('ZMIGROWANY DO V8', AppColors.accentBlue),
  repairedAndMigrated('NAPRAWIONY I ZMIGROWANY DO V8', AppColors.amberWarning),
  failed('BŁĄD MIGRACJI V8', AppColors.crimsonAlert);

  final String labelPl;
  final Color color;

  const V8MigrationStatus(this.labelPl, this.color);

  bool get isSuccess => this != V8MigrationStatus.failed;
}

/// Pojedyncza akcja uzupełnienia, normalizacji lub naprawy pola podczas migracji v8.
@immutable
class V8MigrationFieldAction {
  final String jsonPath;
  final Package8MigrationSection? section;
  final String reason;
  final String appliedValueSummary;
  final bool wasRepaired;

  const V8MigrationFieldAction({
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

/// Podsumowanie stanu pojedynczej sekcji Paczki #8 po przejściu migracji v8.
@immutable
class Package8SectionSummary {
  final Package8MigrationSection section;
  final bool presentBefore;
  final bool validAfter;
  final int recordsCount;
  final int issuesFixedCount;
  final String note;

  const Package8SectionSummary({
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

/// Pełny raport migracji kompatybilności zapisu gry do schematu v8 (Paczka #8).
@immutable
class SaveCompatibilityV8Report {
  final String saveId;
  final int sourceSchemaVersion;
  final int targetSchemaVersion;
  final V8MigrationStatus status;
  final DateTime migratedAtUtc;
  final String checksumBefore;
  final String checksumAfter;
  final List<Package8SectionSummary> sectionSummaries;
  final List<V8MigrationFieldAction> actions;
  final SaveCompatibilityV7Report? v7PreMigrationReport;
  final Map<String, dynamic>? migratedPayload;
  final IntegritySaveEnvelope? migratedEnvelope;
  final GoldenEraRetroSeasonModel? hydratedRetroSeason;
  final UciCyclingEsportsWorldModel? hydratedEsportsWorld;
  final TeamEsgSustainabilityAndGreenFleetModel? hydratedEsgFleet;
  final List<RiderFamilyProfile> hydratedFamilyProfiles;
  final List<PersonalLifeEventRecord> hydratedPersonalLifeEvents;
  final NationalChampionshipCampaignState? hydratedNationalCampaign;
  final TransferDeadlineDayState? hydratedTransferDeadlineDay;
  final List<MerchandiseProductSpec> hydratedMerchProducts;
  final FanClubMembershipSnapshot? hydratedFanClubMembership;
  final List<FanZoneActivation> hydratedFanZones;
  final List<RiderNicknameRecord> hydratedNicknames;
  final HallOfFameArchive? hydratedHallOfFameArchive;
  final AppFeatureFlagsState? hydratedFeatureFlags;
  final String summaryMessage;
  final String? errorMessage;

  const SaveCompatibilityV8Report({
    required this.saveId,
    required this.sourceSchemaVersion,
    this.targetSchemaVersion = SaveCompatibilityV8Migrator.targetSchemaVersion,
    required this.status,
    required this.migratedAtUtc,
    required this.checksumBefore,
    required this.checksumAfter,
    this.sectionSummaries = const [],
    this.actions = const [],
    this.v7PreMigrationReport,
    this.migratedPayload,
    this.migratedEnvelope,
    this.hydratedRetroSeason,
    this.hydratedEsportsWorld,
    this.hydratedEsgFleet,
    this.hydratedFamilyProfiles = const [],
    this.hydratedPersonalLifeEvents = const [],
    this.hydratedNationalCampaign,
    this.hydratedTransferDeadlineDay,
    this.hydratedMerchProducts = const [],
    this.hydratedFanClubMembership,
    this.hydratedFanZones = const [],
    this.hydratedNicknames = const [],
    this.hydratedHallOfFameArchive,
    this.hydratedFeatureFlags,
    required this.summaryMessage,
    this.errorMessage,
  });

  int get totalFixesCount =>
      actions.length + (v7PreMigrationReport?.totalFixesCount ?? 0);

  int get repairedFixesCount =>
      actions.where((a) => a.wasRepaired).length +
      (v7PreMigrationReport?.repairedFixesCount ?? 0);

  Package8SectionSummary? summaryFor(Package8MigrationSection section) {
    for (final s in sectionSummaries) {
      if (s.section == section) return s;
    }
    return null;
  }
}

/// Automatyczny migrator zapisów gry do schematu v8 dla struktur Paczki #8,
/// zachowujący pełną kompatybilność wsteczną z zapisami v1–v7.
class SaveCompatibilityV8Migrator {
  static const int targetSchemaVersion = 8;

  /// Migruje surowy JSON pliku zapisu (`IntegritySaveEnvelope` lub surowy `CareerSave`).
  static SaveCompatibilityV8Report migrateRawJson({
    required String saveId,
    required String rawJson,
    bool initializeOptionalModesIfMissing = false,
  }) {
    final now = DateTime.now().toUtc();
    if (rawJson.trim().isEmpty) {
      return SaveCompatibilityV8Report(
        saveId: saveId,
        sourceSchemaVersion: 0,
        status: V8MigrationStatus.failed,
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
          return SaveCompatibilityV8Report(
            saveId: saveId,
            sourceSchemaVersion: 0,
            status: V8MigrationStatus.failed,
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
      return SaveCompatibilityV8Report(
        saveId: saveId,
        sourceSchemaVersion: 0,
        status: V8MigrationStatus.failed,
        migratedAtUtc: now,
        checksumBefore: '',
        checksumAfter: '',
        summaryMessage: 'Nieoczekiwany błąd podczas parsowania zapisu JSON.',
        errorMessage: e.toString(),
      );
    }
  }

  /// Migruje zdekodowaną mapę payloadu `CareerSave` w pamięci do schematu v8.
  static SaveCompatibilityV8Report migratePayloadMap({
    required String saveId,
    required Map<String, dynamic> payload,
    int sourceSchemaVersion = 7,
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
      return SaveCompatibilityV8Report(
        saveId: saveId,
        sourceSchemaVersion: sourceSchemaVersion,
        status: V8MigrationStatus.failed,
        migratedAtUtc: now,
        checksumBefore: '',
        checksumAfter: '',
        summaryMessage: 'Błąd podczas klonowania lub migracji mapy payloadu.',
        errorMessage: e.toString(),
      );
    }
  }

  static SaveCompatibilityV8Report _migratePayloadInternal({
    required String saveId,
    required int sourceSchemaVersion,
    required String checksumBefore,
    required Map<String, dynamic> workingPayload,
    required List<String> existingHistory,
    required bool hadEnvelope,
    required bool initializeOptionalModesIfMissing,
    required DateTime now,
  }) {
    final actions = <V8MigrationFieldAction>[];
    final summaries = <Package8SectionSummary>[];

    // Krok 0: Jeśli zapis jest starszy niż v7, przepuść go najpierw przez SaveCompatibilityV7Migrator.
    SaveCompatibilityV7Report? v7Report;
    Map<String, dynamic> payload = workingPayload;
    if (sourceSchemaVersion < 7) {
      v7Report = SaveCompatibilityV7Migrator.migratePayloadMap(
        saveId: saveId,
        payload: workingPayload,
        sourceSchemaVersion: sourceSchemaVersion,
        initializeOptionalModesIfMissing: initializeOptionalModesIfMissing,
      );
      if (!v7Report.status.isSuccess || v7Report.migratedPayload == null) {
        return SaveCompatibilityV8Report(
          saveId: saveId,
          sourceSchemaVersion: sourceSchemaVersion,
          status: V8MigrationStatus.failed,
          migratedAtUtc: now,
          checksumBefore: checksumBefore,
          checksumAfter: checksumBefore,
          v7PreMigrationReport: v7Report,
          summaryMessage:
              'Nie powiodła się wstępna migracja v$sourceSchemaVersion -> v7.',
          errorMessage: v7Report.errorMessage ?? 'V7_PRE_MIGRATION_FAILED',
        );
      }
      payload = jsonDecode(jsonEncode(v7Report.migratedPayload!))
          as Map<String, dynamic>;
    }

    final int seasonYear = _extractSeasonYear(payload, now);
    final String teamId =
        _extractString(payload, const ['playerTeamId', 'teamId']) ??
            'team_player_wt';
    final String teamName =
        _extractString(payload, const ['playerTeamName', 'teamName']) ??
            'Pro Peloton Team';

    // 1. Złota Era Kolarstwa (1970–2015)
    final retroRes = _migrateGoldenEraRetroSeason(
      payload: payload,
      teamName: teamName,
      initializeIfMissing: initializeOptionalModesIfMissing,
      actions: actions,
    );
    summaries.add(retroRes.summary);

    // 2. UCI Cycling Esports & Talent ID
    final esportsRes = _migrateUciCyclingEsports(
      payload: payload,
      initializeIfMissing: initializeOptionalModesIfMissing,
      actions: actions,
    );
    summaries.add(esportsRes.summary);

    // 3. Ekonomia ESG i Zielona Flota Zespołu
    final esgRes = _migrateTeamEsgSustainability(
      payload: payload,
      teamId: teamId,
      seasonYear: seasonYear,
      actions: actions,
    );
    summaries.add(esgRes.summary);

    // 4. Życie Osobiste i Urlopy Ojcowskie Kolarzy
    final lifeRes = _migrateRiderPersonalLifeEvents(
      payload: payload,
      actions: actions,
    );
    summaries.add(lifeRes.summary);

    // 5. Selekcjoner Reprezentacji Narodowej
    final natRes = _migrateNationalFederationCampaign(
      payload: payload,
      seasonYear: seasonYear,
      initializeIfMissing: initializeOptionalModesIfMissing,
      actions: actions,
    );
    summaries.add(natRes.summary);

    // 6. Transfer Deadline Day Live
    final tddRes = _migrateTransferDeadlineDay(
      payload: payload,
      seasonYear: seasonYear,
      teamName: teamName,
      initializeIfMissing: initializeOptionalModesIfMissing,
      actions: actions,
    );
    summaries.add(tddRes.summary);

    // 7. Sklep Klubowy i Strefy Kibica
    final merchRes = _migrateTeamMerchandiseAndFanClub(
      payload: payload,
      teamId: teamId,
      actions: actions,
    );
    summaries.add(merchRes.summary);

    // 8. Rejestr Przydomków Kolarskich
    final nickRes = _migrateRiderNicknamesRegistry(
      payload: payload,
      seasonYear: seasonYear,
      actions: actions,
    );
    summaries.add(nickRes.summary);

    // 9. Księga Legendy i Dynastia NG+
    final hofRes = _migrateHallOfFameAndDynasty(
      payload: payload,
      actions: actions,
    );
    summaries.add(hofRes.summary);

    // 10. Flagi Realizmu i Presety Rozgrywki
    final flagsRes = _migrateGameplayRealismConfig(
      payload: payload,
      actions: actions,
    );
    summaries.add(flagsRes.summary);

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
        '${now.toIso8601String()}: v$sourceSchemaVersion->v$targetSchemaVersion (Paczka #8)',
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
        (v7Report?.repairedFixesCount ?? 0) > 0;
    final bool anyChanged = sourceSchemaVersion < targetSchemaVersion ||
        !hadEnvelope ||
        actions.isNotEmpty ||
        v7Report != null ||
        checksumBefore != checksumAfter;

    final V8MigrationStatus status;
    if (anyRepaired) {
      status = V8MigrationStatus.repairedAndMigrated;
    } else if (anyChanged) {
      status = V8MigrationStatus.migrated;
    } else {
      status = V8MigrationStatus.alreadyCompatible;
    }

    final totalFixes = actions.length + (v7Report?.totalFixesCount ?? 0);
    final summaryMessage = switch (status) {
      V8MigrationStatus.alreadyCompatible =>
        'Zapis jest w 100% zgodny ze schematem v$targetSchemaVersion (Paczka #8).',
      V8MigrationStatus.migrated =>
        'Zmigrowano zapis v$sourceSchemaVersion → v$targetSchemaVersion '
            '(uzupełniono $totalFixes pól Paczki #8).',
      V8MigrationStatus.repairedAndMigrated =>
        'Naprawiono i zmigrowano zapis v$sourceSchemaVersion → v$targetSchemaVersion '
            '($totalFixes akcji naprawczych i migracyjnych).',
      V8MigrationStatus.failed => 'Migracja v8 nie powiodła się.',
    };

    return SaveCompatibilityV8Report(
      saveId: saveId,
      sourceSchemaVersion: sourceSchemaVersion,
      targetSchemaVersion: targetSchemaVersion,
      status: status,
      migratedAtUtc: now,
      checksumBefore: checksumBefore,
      checksumAfter: checksumAfter,
      sectionSummaries: summaries,
      actions: actions,
      v7PreMigrationReport: v7Report,
      migratedPayload: payload,
      migratedEnvelope: envelope,
      hydratedRetroSeason: retroRes.model,
      hydratedEsportsWorld: esportsRes.model,
      hydratedEsgFleet: esgRes.model,
      hydratedFamilyProfiles: lifeRes.profiles,
      hydratedPersonalLifeEvents: lifeRes.events,
      hydratedNationalCampaign: natRes.model,
      hydratedTransferDeadlineDay: tddRes.model,
      hydratedMerchProducts: merchRes.products,
      hydratedFanClubMembership: merchRes.membership,
      hydratedFanZones: merchRes.fanZones,
      hydratedNicknames: nickRes.records,
      hydratedHallOfFameArchive: hofRes.archive,
      hydratedFeatureFlags: flagsRes.model,
      summaryMessage: summaryMessage,
    );
  }

  // ---------------------------------------------------------------------------
  // 1. ZŁOTA ERA KOLARSTWA (1970–2015)
  // ---------------------------------------------------------------------------
  static _SectionResult<GoldenEraRetroSeasonModel?>
      _migrateGoldenEraRetroSeason({
    required Map<String, dynamic> payload,
    required String teamName,
    required bool initializeIfMissing,
    required List<V8MigrationFieldAction> actions,
  }) {
    const section = Package8MigrationSection.goldenEraRetroSeason;
    final raw = payload[section.jsonKey];
    final bool presentBefore = raw != null;
    int issuesFixed = 0;

    if (raw == null) {
      if (!initializeIfMissing) {
        payload[section.jsonKey] = null;
        return const _SectionResult(
          summary: Package8SectionSummary(
            section: section,
            presentBefore: false,
            validAfter: true,
            recordsCount: 0,
            issuesFixedCount: 0,
            note: 'Tryb opcjonalny nieaktywny (null) — gotowy do uruchomienia.',
          ),
          model: null,
        );
      }
      final created = GoldenEraRetroSeasonModel.columbusSl1976Classic(
        teamName: teamName,
      );
      payload[section.jsonKey] = created.toJson();
      actions.add(
        V8MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason: 'Zainicjalizowano opcjonalną kampanię Golden Era 1976.',
          appliedValueSummary: created.campaignTitle,
        ),
      );
      return _SectionResult(
        summary: Package8SectionSummary(
          section: section,
          presentBefore: false,
          validAfter: true,
          recordsCount: created.calendarEvents.length,
          issuesFixedCount: 1,
          note: 'Utworzono domyślną kampanię ${created.seasonYear} (Columbus SL).',
        ),
        model: created,
      );
    }

    if (raw is! Map<String, dynamic>) {
      final fallback = GoldenEraRetroSeasonModel.columbusSl1976Classic(
        teamName: teamName,
      );
      payload[section.jsonKey] = fallback.toJson();
      actions.add(
        V8MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason: 'Nieprawidłowy typ danych trybu Golden Era (oczekiwano mapy).',
          appliedValueSummary: fallback.campaignTitle,
          wasRepaired: true,
        ),
      );
      return _SectionResult(
        summary: Package8SectionSummary(
          section: section,
          presentBefore: true,
          validAfter: true,
          recordsCount: fallback.calendarEvents.length,
          issuesFixedCount: 1,
          note: 'Naprawiono uszkodzoną strukturę kampanii retro.',
        ),
        model: fallback,
      );
    }

    GoldenEraRetroSeasonModel parsed;
    try {
      parsed = GoldenEraRetroSeasonModel.fromJson(raw);
    } catch (_) {
      final fallback = GoldenEraRetroSeasonModel.columbusSl1976Classic(
        teamName: teamName,
      );
      payload[section.jsonKey] = fallback.toJson();
      actions.add(
        V8MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason: 'Uszkodzone pola wewnętrzne Golden Era — odbudowano domyślną kampanię.',
          appliedValueSummary: fallback.campaignTitle,
          wasRepaired: true,
        ),
      );
      return _SectionResult(
        summary: Package8SectionSummary(
          section: section,
          presentBefore: true,
          validAfter: true,
          recordsCount: fallback.calendarEvents.length,
          issuesFixedCount: 1,
          note: 'Naprawiono uszkodzone pola kampanii retro.',
        ),
        model: fallback,
      );
    }
    final double safeWetness = parsed.activeWetnessFactor.clamp(0.0, 1.0);
    final double safeAuth = parsed.historicalAuthenticityScore.clamp(0.0, 100.0);
    if (safeWetness != parsed.activeWetnessFactor ||
        safeAuth != parsed.historicalAuthenticityScore) {
      parsed = parsed.copyWith(
        activeWetnessFactor: safeWetness,
        historicalAuthenticityScore: safeAuth,
      );
      issuesFixed++;
      actions.add(
        V8MigrationFieldAction(
          jsonPath: '${section.jsonKey}.activeWetnessFactor',
          section: section,
          reason: 'Znormalizowano wskaźnik nasiąknięcia/autentyczności retro.',
          appliedValueSummary:
              'wet=${safeWetness.toStringAsFixed(2)}, auth=${safeAuth.toStringAsFixed(1)}%',
          wasRepaired: true,
        ),
      );
    }

    final normalized = parsed.toJson();
    if (jsonEncode(raw) != jsonEncode(normalized)) {
      payload[section.jsonKey] = normalized;
      if (issuesFixed == 0) {
        issuesFixed++;
        actions.add(
          V8MigrationFieldAction(
            jsonPath: section.jsonKey,
            section: section,
            reason: 'Uzupełniono brakujące pola schematu Golden Era v8.',
            appliedValueSummary:
                'rok=${parsed.seasonYear}, wyścigi=${parsed.calendarEvents.length}',
          ),
        );
      }
    }

    return _SectionResult(
      summary: Package8SectionSummary(
        section: section,
        presentBefore: presentBefore,
        validAfter: true,
        recordsCount: parsed.calendarEvents.length,
        issuesFixedCount: issuesFixed,
        note: 'Kampania ${parsed.seasonYear} (${parsed.teamName}).',
      ),
      model: parsed,
    );
  }

  // ---------------------------------------------------------------------------
  // 2. UCI CYCLING ESPORTS & VIRTUAL TALENT ID
  // ---------------------------------------------------------------------------
  static _SectionResult<UciCyclingEsportsWorldModel?> _migrateUciCyclingEsports({
    required Map<String, dynamic> payload,
    required bool initializeIfMissing,
    required List<V8MigrationFieldAction> actions,
  }) {
    const section = Package8MigrationSection.uciCyclingEsports;
    final raw = payload[section.jsonKey];
    final bool presentBefore = raw != null;
    int issuesFixed = 0;

    if (raw == null) {
      if (!initializeIfMissing) {
        payload[section.jsonKey] = null;
        return const _SectionResult(
          summary: Package8SectionSummary(
            section: section,
            presentBefore: false,
            validAfter: true,
            recordsCount: 0,
            issuesFixedCount: 0,
            note: 'Tryb opcjonalny e-Sports nieaktywny (null).',
          ),
          model: null,
        );
      }
      final created =
          UciCyclingEsportsWorldModel.uciWorldChampionshipElimination();
      payload[section.jsonKey] = created.toJson();
      actions.add(
        V8MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason: 'Zainicjalizowano opcjonalne Mistrzostwa UCI Cycling Esports.',
          appliedValueSummary:
              '${created.riders.length} kolarzy, ${created.talentIdPool.length} talentów',
        ),
      );
      return _SectionResult(
        summary: Package8SectionSummary(
          section: section,
          presentBefore: false,
          validAfter: true,
          recordsCount: created.riders.length + created.talentIdPool.length,
          issuesFixedCount: 1,
          note: 'Utworzono domyślne zawody e-Sports (Elimination 60s).',
        ),
        model: created,
      );
    }

    if (raw is! Map<String, dynamic>) {
      final fallback =
          UciCyclingEsportsWorldModel.uciWorldChampionshipElimination();
      payload[section.jsonKey] = fallback.toJson();
      actions.add(
        V8MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason: 'Uszkodzona struktura UCI Cycling Esports — przywrócono domyślną.',
          appliedValueSummary: fallback.eventName,
          wasRepaired: true,
        ),
      );
      return _SectionResult(
        summary: Package8SectionSummary(
          section: section,
          presentBefore: true,
          validAfter: true,
          recordsCount: fallback.riders.length,
          issuesFixedCount: 1,
          note: 'Naprawiono uszkodzoną strukturę e-Sports.',
        ),
        model: fallback,
      );
    }

    UciCyclingEsportsWorldModel parsed;
    try {
      parsed = UciCyclingEsportsWorldModel.fromJson(raw);
    } catch (_) {
      final fallback =
          UciCyclingEsportsWorldModel.uciWorldChampionshipElimination();
      payload[section.jsonKey] = fallback.toJson();
      actions.add(
        V8MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason: 'Uszkodzone pola wewnętrzne e-Sports — odbudowano domyślne zawody.',
          appliedValueSummary: fallback.eventName,
          wasRepaired: true,
        ),
      );
      return _SectionResult(
        summary: Package8SectionSummary(
          section: section,
          presentBefore: true,
          validAfter: true,
          recordsCount: fallback.riders.length,
          issuesFixedCount: 1,
          note: 'Naprawiono uszkodzone pola e-Sports.',
        ),
        model: fallback,
      );
    }
    final double safeDelta =
        parsed.uciDualRecordingMaxDeltaPercent.clamp(0.5, 10.0);
    final double safePrize = parsed.prizePoolEur < 0 ? 0.0 : parsed.prizePoolEur;
    if (safeDelta != parsed.uciDualRecordingMaxDeltaPercent ||
        safePrize != parsed.prizePoolEur) {
      parsed = parsed.copyWith(
        uciDualRecordingMaxDeltaPercent: safeDelta,
        prizePoolEur: safePrize,
      );
      issuesFixed++;
      actions.add(
        V8MigrationFieldAction(
          jsonPath: '${section.jsonKey}.uciDualRecordingMaxDeltaPercent',
          section: section,
          reason: 'Skorygowano limity Dual-Recording lub puli nagród e-Sports.',
          appliedValueSummary:
              'delta=${safeDelta.toStringAsFixed(1)}%, pula=${safePrize.toStringAsFixed(0)} EUR',
          wasRepaired: true,
        ),
      );
    }

    final normalized = parsed.toJson();
    if (jsonEncode(raw) != jsonEncode(normalized)) {
      payload[section.jsonKey] = normalized;
      if (issuesFixed == 0) {
        issuesFixed++;
        actions.add(
          V8MigrationFieldAction(
            jsonPath: section.jsonKey,
            section: section,
            reason: 'Znormalizowano strukturę UCI Cycling Esports v8.',
            appliedValueSummary:
                'kolarze=${parsed.riders.length}, talenty=${parsed.talentIdPool.length}',
          ),
        );
      }
    }

    return _SectionResult(
      summary: Package8SectionSummary(
        section: section,
        presentBefore: presentBefore,
        validAfter: true,
        recordsCount: parsed.riders.length + parsed.talentIdPool.length,
        issuesFixedCount: issuesFixed,
        note: 'Format ${parsed.raceFormat.name} (${parsed.riders.length} kolarzy).',
      ),
      model: parsed,
    );
  }

  // ---------------------------------------------------------------------------
  // 3. EKONOMIA ESG I ZIELONA FLOTA ZESPOŁU
  // ---------------------------------------------------------------------------
  static _SectionResult<TeamEsgSustainabilityAndGreenFleetModel>
      _migrateTeamEsgSustainability({
    required Map<String, dynamic> payload,
    required String teamId,
    required int seasonYear,
    required List<V8MigrationFieldAction> actions,
  }) {
    const section = Package8MigrationSection.teamEsgSustainability;
    final raw = payload[section.jsonKey];
    final bool presentBefore = raw != null;
    int issuesFixed = 0;

    if (raw == null) {
      final starter = TeamEsgSustainabilityAndGreenFleetModel.createStarterWorldTour(
        teamId: teamId,
        seasonYear: seasonYear,
      );
      payload[section.jsonKey] = starter.toJson();
      actions.add(
        V8MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason: 'Brak sekcji ESG i Zielonej Floty — utworzono flotę startową.',
          appliedValueSummary:
              '${starter.vehicles.length} pojazdów, budżet CO2=${starter.annualCo2BudgetTons}t',
        ),
      );
      return _SectionResult(
        summary: Package8SectionSummary(
          section: section,
          presentBefore: false,
          validAfter: true,
          recordsCount: starter.vehicles.length + starter.ledger.length,
          issuesFixedCount: 1,
          note: 'Zainicjalizowano flotę startową ESG (${starter.vehicles.length} pojazdy).',
        ),
        model: starter,
      );
    }

    if (raw is! Map<String, dynamic>) {
      final starter = TeamEsgSustainabilityAndGreenFleetModel.createStarterWorldTour(
        teamId: teamId,
        seasonYear: seasonYear,
      );
      payload[section.jsonKey] = starter.toJson();
      actions.add(
        V8MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason: 'Nieprawidłowy format sekcji ESG — odbudowano domyślny model.',
          appliedValueSummary: '${starter.vehicles.length} pojazdów',
          wasRepaired: true,
        ),
      );
      return _SectionResult(
        summary: Package8SectionSummary(
          section: section,
          presentBefore: true,
          validAfter: true,
          recordsCount: starter.vehicles.length,
          issuesFixedCount: 1,
          note: 'Naprawiono uszkodzony obiekt ESG.',
        ),
        model: starter,
      );
    }

    TeamEsgSustainabilityAndGreenFleetModel parsed;
    try {
      parsed = TeamEsgSustainabilityAndGreenFleetModel.fromJson(raw);
    } catch (_) {
      final starter = TeamEsgSustainabilityAndGreenFleetModel.createStarterWorldTour(
        teamId: teamId,
        seasonYear: seasonYear,
      );
      payload[section.jsonKey] = starter.toJson();
      actions.add(
        V8MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason: 'Uszkodzone pola wewnętrzne ESG — odbudowano flotę startową.',
          appliedValueSummary: '${starter.vehicles.length} pojazdów',
          wasRepaired: true,
        ),
      );
      return _SectionResult(
        summary: Package8SectionSummary(
          section: section,
          presentBefore: true,
          validAfter: true,
          recordsCount: starter.vehicles.length,
          issuesFixedCount: 1,
          note: 'Naprawiono uszkodzone pola ESG.',
        ),
        model: starter,
      );
    }
    if (parsed.annualCo2BudgetTons <= 0 || parsed.carbonCreditPricePerTonEur <= 0) {
      parsed = TeamEsgSustainabilityAndGreenFleetModel(
        teamId: parsed.teamId,
        seasonYear: parsed.seasonYear,
        vehicles: parsed.vehicles,
        infrastructureTier: parsed.infrastructureTier,
        ledger: parsed.ledger,
        greenSponsors: parsed.greenSponsors,
        annualCo2BudgetTons:
            parsed.annualCo2BudgetTons <= 0 ? 120.0 : parsed.annualCo2BudgetTons,
        carbonCreditPricePerTonEur: parsed.carbonCreditPricePerTonEur <= 0
            ? 85.0
            : parsed.carbonCreditPricePerTonEur,
        railOverFlightPolicyEnabled: parsed.railOverFlightPolicyEnabled,
        recycledKitEnabled: parsed.recycledKitEnabled,
        ecoBottleProgramEnabled: parsed.ecoBottleProgramEnabled,
        cashBalanceEur: parsed.cashBalanceEur,
      );
      issuesFixed++;
      actions.add(
        V8MigrationFieldAction(
          jsonPath: '${section.jsonKey}.annualCo2BudgetTons',
          section: section,
          reason: 'Naprawiono niedodatni budżet CO2 lub cenę kredytu węglowego.',
          appliedValueSummary:
              '${parsed.annualCo2BudgetTons}t @ ${parsed.carbonCreditPricePerTonEur} EUR/t',
          wasRepaired: true,
        ),
      );
    }

    final normalized = parsed.toJson();
    if (jsonEncode(raw) != jsonEncode(normalized)) {
      payload[section.jsonKey] = normalized;
      if (issuesFixed == 0) {
        issuesFixed++;
        actions.add(
          V8MigrationFieldAction(
            jsonPath: section.jsonKey,
            section: section,
            reason: 'Znormalizowano strukturę ESG i Zielonej Floty do v8.',
            appliedValueSummary:
                'pojazdy=${parsed.vehicles.length}, wpisy=${parsed.ledger.length}',
          ),
        );
      }
    }

    return _SectionResult(
      summary: Package8SectionSummary(
        section: section,
        presentBefore: presentBefore,
        validAfter: true,
        recordsCount: parsed.vehicles.length + parsed.ledger.length,
        issuesFixedCount: issuesFixed,
        note: 'Flota: ${parsed.vehicles.length} szt., wpisy CO2: ${parsed.ledger.length}.',
      ),
      model: parsed,
    );
  }

  // ---------------------------------------------------------------------------
  // 4. ŻYCIE OSOBISTE I URLOPY OJCOWSKIE KOLARZY
  // ---------------------------------------------------------------------------
  static _PersonalLifeResult _migrateRiderPersonalLifeEvents({
    required Map<String, dynamic> payload,
    required List<V8MigrationFieldAction> actions,
  }) {
    const section = Package8MigrationSection.riderPersonalLifeEvents;
    final raw = payload[section.jsonKey];
    final bool presentBefore = raw != null;
    int issuesFixed = 0;

    if (raw == null) {
      payload[section.jsonKey] = <String, dynamic>{
        'profiles': const <Map<String, dynamic>>[],
        'events': const <Map<String, dynamic>>[],
        'totalPaternityLeavesGranted': 0,
      };
      actions.add(
        V8MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason: 'Brak rejestru życia osobistego kolarzy — utworzono pusty rejestr.',
          appliedValueSummary: '0 profili, 0 zdarzeń',
        ),
      );
      return const _PersonalLifeResult(
        summary: Package8SectionSummary(
          section: section,
          presentBefore: false,
          validAfter: true,
          recordsCount: 0,
          issuesFixedCount: 1,
          note: 'Utworzono pusty rejestr wydarzeń rodzinnych.',
        ),
        profiles: [],
        events: [],
      );
    }

    if (raw is! Map<String, dynamic>) {
      payload[section.jsonKey] = <String, dynamic>{
        'profiles': const <Map<String, dynamic>>[],
        'events': const <Map<String, dynamic>>[],
        'totalPaternityLeavesGranted': 0,
      };
      actions.add(
        V8MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason: 'Nieprawidłowy format rejestru życia osobistego.',
          appliedValueSummary: 'zresetowano do pustego rejestru',
          wasRepaired: true,
        ),
      );
      return const _PersonalLifeResult(
        summary: Package8SectionSummary(
          section: section,
          presentBefore: true,
          validAfter: true,
          recordsCount: 0,
          issuesFixedCount: 1,
          note: 'Naprawiono uszkodzony rejestr życia osobistego.',
        ),
        profiles: [],
        events: [],
      );
    }

    final rawProfiles = raw['profiles'];
    final profiles = <RiderFamilyProfile>[];
    if (rawProfiles is List) {
      for (final item in rawProfiles) {
        if (item is Map<String, dynamic>) {
          profiles.add(RiderFamilyProfile.fromJson(item));
        } else {
          issuesFixed++;
        }
      }
    } else if (rawProfiles != null) {
      issuesFixed++;
    }

    final rawEvents = raw['events'];
    final events = <PersonalLifeEventRecord>[];
    if (rawEvents is List) {
      for (final item in rawEvents) {
        if (item is Map<String, dynamic>) {
          events.add(PersonalLifeEventRecord.fromJson(item));
        } else {
          issuesFixed++;
        }
      }
    } else if (rawEvents != null) {
      issuesFixed++;
    }

    final int leavesCount =
        ((raw['totalPaternityLeavesGranted'] as num?)?.toInt() ?? 0)
            .clamp(0, 9999);
    final normalized = <String, dynamic>{
      'profiles': profiles.map((p) => p.toJson()).toList(),
      'events': events.map((e) => e.toJson()).toList(),
      'totalPaternityLeavesGranted': leavesCount,
    };

    if (jsonEncode(raw) != jsonEncode(normalized)) {
      payload[section.jsonKey] = normalized;
      if (issuesFixed == 0) {
        issuesFixed++;
        actions.add(
          V8MigrationFieldAction(
            jsonPath: section.jsonKey,
            section: section,
            reason: 'Znormalizowano rejestr życia osobistego kolarzy.',
            appliedValueSummary:
                '${profiles.length} profili, ${events.length} zdarzeń',
          ),
        );
      } else {
        actions.add(
          V8MigrationFieldAction(
            jsonPath: section.jsonKey,
            section: section,
            reason: 'Odfiltrowano uszkodzone wpisy życia osobistego.',
            appliedValueSummary:
                '${profiles.length} profili, ${events.length} zdarzeń',
            wasRepaired: true,
          ),
        );
      }
    }

    return _PersonalLifeResult(
      summary: Package8SectionSummary(
        section: section,
        presentBefore: presentBefore,
        validAfter: true,
        recordsCount: profiles.length + events.length,
        issuesFixedCount: issuesFixed,
        note: 'Profile: ${profiles.length}, zdarzenia: ${events.length}.',
      ),
      profiles: profiles,
      events: events,
    );
  }

  // ---------------------------------------------------------------------------
  // 5. SELEKCJONER REPREZENTACJI NARODOWEJ
  // ---------------------------------------------------------------------------
  static _SectionResult<NationalChampionshipCampaignState?>
      _migrateNationalFederationCampaign({
    required Map<String, dynamic> payload,
    required int seasonYear,
    required bool initializeIfMissing,
    required List<V8MigrationFieldAction> actions,
  }) {
    const section = Package8MigrationSection.nationalFederationCampaign;
    final raw = payload[section.jsonKey];
    final bool presentBefore = raw != null;
    int issuesFixed = 0;

    if (raw == null) {
      if (!initializeIfMissing) {
        payload[section.jsonKey] = null;
        return const _SectionResult(
          summary: Package8SectionSummary(
            section: section,
            presentBefore: false,
            validAfter: true,
            recordsCount: 0,
            issuesFixedCount: 0,
            note: 'Kampania selekcjonera narodowego nieaktywna (null).',
          ),
          model: null,
        );
      }
      final created =
          NationalFederationTeamManagerService.createDefaultPolandCampaign()
              .copyWith(seasonYear: seasonYear);
      payload[section.jsonKey] = created.toJson();
      actions.add(
        V8MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason: 'Zainicjalizowano kampanię Selekcjonera Reprezentacji (POL).',
          appliedValueSummary:
              '${created.candidatePool.length} kandydatów, limit=${created.activeMaxStarters}',
        ),
      );
      return _SectionResult(
        summary: Package8SectionSummary(
          section: section,
          presentBefore: false,
          validAfter: true,
          recordsCount: created.candidatePool.length,
          issuesFixedCount: 1,
          note: 'Utworzono domyślną kadrę narodową (${created.quota.nationCode}).',
        ),
        model: created,
      );
    }

    if (raw is! Map<String, dynamic>) {
      final fallback =
          NationalFederationTeamManagerService.createDefaultPolandCampaign()
              .copyWith(seasonYear: seasonYear);
      payload[section.jsonKey] = fallback.toJson();
      actions.add(
        V8MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason: 'Uszkodzona struktura kampanii reprezentacji narodowej.',
          appliedValueSummary: fallback.quota.nationCode,
          wasRepaired: true,
        ),
      );
      return _SectionResult(
        summary: Package8SectionSummary(
          section: section,
          presentBefore: true,
          validAfter: true,
          recordsCount: fallback.candidatePool.length,
          issuesFixedCount: 1,
          note: 'Naprawiono strukturę kampanii reprezentacji.',
        ),
        model: fallback,
      );
    }

    NationalChampionshipCampaignState parsed;
    try {
      parsed = NationalChampionshipCampaignState.fromJson(raw);
    } catch (_) {
      final fallback =
          NationalFederationTeamManagerService.createDefaultPolandCampaign()
              .copyWith(seasonYear: seasonYear);
      payload[section.jsonKey] = fallback.toJson();
      actions.add(
        V8MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason: 'Uszkodzone pola wewnętrzne reprezentacji — odbudowano kadrę.',
          appliedValueSummary: fallback.quota.nationCode,
          wasRepaired: true,
        ),
      );
      return _SectionResult(
        summary: Package8SectionSummary(
          section: section,
          presentBefore: true,
          validAfter: true,
          recordsCount: fallback.candidatePool.length,
          issuesFixedCount: 1,
          note: 'Naprawiono uszkodzone pola kampanii reprezentacji.',
        ),
        model: fallback,
      );
    }
    final double safeTrust = parsed.federationTrust.clamp(0.0, 100.0);
    final double safePressure = parsed.mediaPressure.clamp(0.0, 100.0);
    if (safeTrust != parsed.federationTrust ||
        safePressure != parsed.mediaPressure) {
      parsed = parsed.copyWith(
        federationTrust: safeTrust,
        mediaPressure: safePressure,
      );
      issuesFixed++;
      actions.add(
        V8MigrationFieldAction(
          jsonPath: '${section.jsonKey}.federationTrust',
          section: section,
          reason: 'Skorygowano zakres zaufania federacji / presji mediów (0–100).',
          appliedValueSummary:
              'trust=${safeTrust.toStringAsFixed(0)}, pressure=${safePressure.toStringAsFixed(0)}',
          wasRepaired: true,
        ),
      );
    }

    final normalized = parsed.toJson();
    if (jsonEncode(raw) != jsonEncode(normalized)) {
      payload[section.jsonKey] = normalized;
      if (issuesFixed == 0) {
        issuesFixed++;
        actions.add(
          V8MigrationFieldAction(
            jsonPath: section.jsonKey,
            section: section,
            reason: 'Znormalizowano pola kampanii reprezentacji narodowej.',
            appliedValueSummary:
                '${parsed.quota.nationCode}, powołani=${parsed.selectedSquad.length}',
          ),
        );
      }
    }

    return _SectionResult(
      summary: Package8SectionSummary(
        section: section,
        presentBefore: presentBefore,
        validAfter: true,
        recordsCount: parsed.candidatePool.length + parsed.selectedSquad.length,
        issuesFixedCount: issuesFixed,
        note: 'Kadra ${parsed.quota.nationCode} (${parsed.selectedSquad.length}/${parsed.activeMaxStarters} powołanych).',
      ),
      model: parsed,
    );
  }

  // ---------------------------------------------------------------------------
  // 6. TRANSFER DEADLINE DAY LIVE
  // ---------------------------------------------------------------------------
  static _SectionResult<TransferDeadlineDayState?> _migrateTransferDeadlineDay({
    required Map<String, dynamic> payload,
    required int seasonYear,
    required String teamName,
    required bool initializeIfMissing,
    required List<V8MigrationFieldAction> actions,
  }) {
    const section = Package8MigrationSection.transferDeadlineDay;
    final raw = payload[section.jsonKey];
    final bool presentBefore = raw != null;
    int issuesFixed = 0;

    if (raw == null) {
      if (!initializeIfMissing) {
        payload[section.jsonKey] = null;
        return const _SectionResult(
          summary: Package8SectionSummary(
            section: section,
            presentBefore: false,
            validAfter: true,
            recordsCount: 0,
            issuesFixedCount: 0,
            note: 'Okno Transfer Deadline Day poza sezonem (null).',
          ),
          model: null,
        );
      }
      final created = TransferDeadlineDayState(
        config: TransferDeadlineDayConfig(
          seasonYear: seasonYear,
          teamName: teamName,
          totalDurationMinutes: 720,
          availableWageBudgetEur: 1200000,
          availableTransferBudgetEur: 850000,
          openRosterSlots: 3,
        ),
        remainingWindowMinutes: 720,
        isLiveTicking: false,
        simulationSpeedMultiplier: 1,
        remainingWageBudgetEur: 1200000,
        remainingTransferBudgetEur: 850000,
        remainingRosterSlots: 3,
        offers: const [],
        completedDeals: const [],
        tickerFeed: const [],
      );
      payload[section.jsonKey] = created.toJson();
      actions.add(
        V8MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason: 'Zainicjalizowano stan Transfer Deadline Day dla sezonu $seasonYear.',
          appliedValueSummary: '720 min, 3 wolne miejsca',
        ),
      );
      return _SectionResult(
        summary: const Package8SectionSummary(
          section: section,
          presentBefore: false,
          validAfter: true,
          recordsCount: 0,
          issuesFixedCount: 1,
          note: 'Utworzono gotowe okno Transfer Deadline Day.',
        ),
        model: created,
      );
    }

    if (raw is! Map<String, dynamic>) {
      payload[section.jsonKey] = null;
      actions.add(
        V8MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason: 'Uszkodzona struktura Transfer Deadline Day — zresetowano do null.',
          appliedValueSummary: 'null',
          wasRepaired: true,
        ),
      );
      return const _SectionResult(
        summary: Package8SectionSummary(
          section: section,
          presentBefore: true,
          validAfter: true,
          recordsCount: 0,
          issuesFixedCount: 1,
          note: 'Wyczyszczono uszkodzone dane okna transferowego.',
        ),
        model: null,
      );
    }

    TransferDeadlineDayState parsed;
    try {
      parsed = TransferDeadlineDayState.fromJson(raw);
    } catch (_) {
      final fallback = TransferDeadlineDayState(
        config: TransferDeadlineDayConfig(
          seasonYear: seasonYear,
          teamName: teamName,
        ),
        remainingWindowMinutes: 0,
        isLiveTicking: false,
        simulationSpeedMultiplier: 1,
        remainingWageBudgetEur: 1200000,
        remainingTransferBudgetEur: 850000,
        remainingRosterSlots: 3,
        offers: const [],
        completedDeals: const [],
        tickerFeed: const [],
      );
      payload[section.jsonKey] = fallback.toJson();
      actions.add(
        V8MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason: 'Uszkodzone pola wewnętrzne Deadline Day — odbudowano stan bezpieczny.',
          appliedValueSummary: '0 min (zamknięte)',
          wasRepaired: true,
        ),
      );
      return _SectionResult(
        summary: const Package8SectionSummary(
          section: section,
          presentBefore: true,
          validAfter: true,
          recordsCount: 0,
          issuesFixedCount: 1,
          note: 'Naprawiono uszkodzone pola okna transferowego.',
        ),
        model: fallback,
      );
    }
    final int safeMinutes = parsed.remainingWindowMinutes < 0
        ? 0
        : parsed.remainingWindowMinutes;
    final int safeSpeed = parsed.simulationSpeedMultiplier.clamp(1, 10);
    if (safeMinutes != parsed.remainingWindowMinutes ||
        safeSpeed != parsed.simulationSpeedMultiplier) {
      parsed = parsed.copyWith(
        remainingWindowMinutes: safeMinutes,
        simulationSpeedMultiplier: safeSpeed,
      );
      issuesFixed++;
      actions.add(
        V8MigrationFieldAction(
          jsonPath: '${section.jsonKey}.remainingWindowMinutes',
          section: section,
          reason: 'Skorygowano ujemny czas lub mnożnik prędkości Deadline Day.',
          appliedValueSummary: '${safeMinutes}m @ ${safeSpeed}x',
          wasRepaired: true,
        ),
      );
    }

    final normalized = parsed.toJson();
    if (jsonEncode(raw) != jsonEncode(normalized)) {
      payload[section.jsonKey] = normalized;
      if (issuesFixed == 0) {
        issuesFixed++;
        actions.add(
          V8MigrationFieldAction(
            jsonPath: section.jsonKey,
            section: section,
            reason: 'Znormalizowano strukturę Transfer Deadline Day.',
            appliedValueSummary:
                'oferty=${parsed.offers.length}, umowy=${parsed.completedDeals.length}',
          ),
        );
      }
    }

    return _SectionResult(
      summary: Package8SectionSummary(
        section: section,
        presentBefore: presentBefore,
        validAfter: true,
        recordsCount: parsed.offers.length + parsed.completedDeals.length,
        issuesFixedCount: issuesFixed,
        note: 'Oferty: ${parsed.offers.length}, finalizacje: ${parsed.completedDeals.length}.',
      ),
      model: parsed,
    );
  }

  // ---------------------------------------------------------------------------
  // 7. SKLEP KLUBOWY I STREFY KIBICA
  // ---------------------------------------------------------------------------
  static _MerchandiseResult _migrateTeamMerchandiseAndFanClub({
    required Map<String, dynamic> payload,
    required String teamId,
    required List<V8MigrationFieldAction> actions,
  }) {
    const section = Package8MigrationSection.teamMerchandiseAndFanClub;
    final raw = payload[section.jsonKey];
    final bool presentBefore = raw != null;
    int issuesFixed = 0;

    const defaultMembership = FanClubMembershipSnapshot(
      totalFanBase: 12500,
      paidClubMembers: 1850,
      annualMembershipFeeEur: 49.0,
      fanEngagementIndex: 68.0,
      regionalSupporters: {'PL': 8200, 'BE': 2400, 'FR': 1900},
    );

    if (raw == null) {
      payload[section.jsonKey] = <String, dynamic>{
        'products': const <Map<String, dynamic>>[],
        'membership': defaultMembership.toJson(),
        'fanZones': const <Map<String, dynamic>>[],
        'starJerseyDemands': const <Map<String, dynamic>>[],
        'totalMerchandiseRevenueEur': 0.0,
      };
      actions.add(
        V8MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason: 'Brak danych sklepu klubowego i Fan Club — utworzono profil startowy.',
          appliedValueSummary:
              '${defaultMembership.totalFanBase} kibiców, ${defaultMembership.paidClubMembers} członków',
        ),
      );
      return const _MerchandiseResult(
        summary: Package8SectionSummary(
          section: section,
          presentBefore: false,
          validAfter: true,
          recordsCount: 1,
          issuesFixedCount: 1,
          note: 'Utworzono bazową społeczność kibiców i sklep klubowy.',
        ),
        products: [],
        membership: defaultMembership,
        fanZones: [],
      );
    }

    if (raw is! Map<String, dynamic>) {
      payload[section.jsonKey] = <String, dynamic>{
        'products': const <Map<String, dynamic>>[],
        'membership': defaultMembership.toJson(),
        'fanZones': const <Map<String, dynamic>>[],
        'starJerseyDemands': const <Map<String, dynamic>>[],
        'totalMerchandiseRevenueEur': 0.0,
      };
      actions.add(
        V8MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason: 'Uszkodzona struktura sklepu klubowego — przywrócono profil domyślny.',
          appliedValueSummary: 'zresetowano dane sklepu',
          wasRepaired: true,
        ),
      );
      return const _MerchandiseResult(
        summary: Package8SectionSummary(
          section: section,
          presentBefore: true,
          validAfter: true,
          recordsCount: 1,
          issuesFixedCount: 1,
          note: 'Naprawiono uszkodzony moduł sklepu i Fan Club.',
        ),
        products: [],
        membership: defaultMembership,
        fanZones: [],
      );
    }

    final products = <MerchandiseProductSpec>[];
    final rawProducts = raw['products'];
    if (rawProducts is List) {
      for (final item in rawProducts) {
        if (item is Map<String, dynamic>) {
          products.add(MerchandiseProductSpec.fromJson(item));
        } else {
          issuesFixed++;
        }
      }
    }

    final membership = raw['membership'] is Map<String, dynamic>
        ? FanClubMembershipSnapshot.fromJson(
            raw['membership'] as Map<String, dynamic>,
          )
        : defaultMembership;
    if (raw['membership'] is! Map<String, dynamic>) {
      issuesFixed++;
    }

    final fanZones = <FanZoneActivation>[];
    final rawZones = raw['fanZones'];
    if (rawZones is List) {
      for (final item in rawZones) {
        if (item is Map<String, dynamic>) {
          fanZones.add(FanZoneActivation.fromJson(item));
        } else {
          issuesFixed++;
        }
      }
    }

    final demands = <StarRiderJerseyDemand>[];
    final rawDemands = raw['starJerseyDemands'];
    if (rawDemands is List) {
      for (final item in rawDemands) {
        if (item is Map<String, dynamic>) {
          demands.add(StarRiderJerseyDemand.fromJson(item));
        } else {
          issuesFixed++;
        }
      }
    }

    final double revenue =
        ((raw['totalMerchandiseRevenueEur'] as num?)?.toDouble() ?? 0.0)
            .clamp(0.0, double.infinity);

    final normalized = <String, dynamic>{
      'products': products.map((p) => p.toJson()).toList(),
      'membership': membership.toJson(),
      'fanZones': fanZones.map((z) => z.toJson()).toList(),
      'starJerseyDemands': demands.map((d) => d.toJson()).toList(),
      'totalMerchandiseRevenueEur': revenue,
    };

    if (jsonEncode(raw) != jsonEncode(normalized)) {
      payload[section.jsonKey] = normalized;
      if (issuesFixed == 0) {
        issuesFixed++;
      }
      actions.add(
        V8MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason: 'Znormalizowano dane sklepu klubowego i stref kibica.',
          appliedValueSummary:
              'produkty=${products.length}, fanZones=${fanZones.length}',
        ),
      );
    }

    return _MerchandiseResult(
      summary: Package8SectionSummary(
        section: section,
        presentBefore: presentBefore,
        validAfter: true,
        recordsCount: products.length + fanZones.length + demands.length,
        issuesFixedCount: issuesFixed,
        note: 'Kibice: ${membership.totalFanBase}, produkty: ${products.length}.',
      ),
      products: products,
      membership: membership,
      fanZones: fanZones,
    );
  }

  // ---------------------------------------------------------------------------
  // 8. REJESTR PRZYDOMKÓW KOLARSKICH
  // ---------------------------------------------------------------------------
  static _NicknamesResult _migrateRiderNicknamesRegistry({
    required Map<String, dynamic> payload,
    required int seasonYear,
    required List<V8MigrationFieldAction> actions,
  }) {
    const section = Package8MigrationSection.riderNicknamesRegistry;
    final raw = payload[section.jsonKey];
    final bool presentBefore = raw != null;
    int issuesFixed = 0;

    if (raw == null) {
      payload[section.jsonKey] = <String, dynamic>{
        'records': const <Map<String, dynamic>>[],
        'lastGeneratedSeasonYear': seasonYear,
      };
      actions.add(
        V8MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason: 'Brak rejestru przydomków kolarskich — utworzono pusty rejestr.',
          appliedValueSummary: 'sezon=$seasonYear, 0 przydomków',
        ),
      );
      return const _NicknamesResult(
        summary: Package8SectionSummary(
          section: section,
          presentBefore: false,
          validAfter: true,
          recordsCount: 0,
          issuesFixedCount: 1,
          note: 'Utworzono pusty rejestr przydomków medialnych.',
        ),
        records: [],
      );
    }

    if (raw is! Map<String, dynamic>) {
      payload[section.jsonKey] = <String, dynamic>{
        'records': const <Map<String, dynamic>>[],
        'lastGeneratedSeasonYear': seasonYear,
      };
      actions.add(
        V8MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason: 'Uszkodzony rejestr przydomków — zresetowano strukturę.',
          appliedValueSummary: '0 przydomków',
          wasRepaired: true,
        ),
      );
      return const _NicknamesResult(
        summary: Package8SectionSummary(
          section: section,
          presentBefore: true,
          validAfter: true,
          recordsCount: 0,
          issuesFixedCount: 1,
          note: 'Naprawiono uszkodzony rejestr przydomków.',
        ),
        records: [],
      );
    }

    final records = <RiderNicknameRecord>[];
    final rawList = raw['records'];
    if (rawList is List) {
      for (final item in rawList) {
        if (item is Map<String, dynamic>) {
          records.add(RiderNicknameRecord.fromJson(item));
        } else {
          issuesFixed++;
        }
      }
    } else if (rawList != null) {
      issuesFixed++;
    }

    final int lastYear =
        (raw['lastGeneratedSeasonYear'] as num?)?.toInt() ?? seasonYear;
    final normalized = <String, dynamic>{
      'records': records.map((r) => r.toJson()).toList(),
      'lastGeneratedSeasonYear': lastYear,
    };

    if (jsonEncode(raw) != jsonEncode(normalized)) {
      payload[section.jsonKey] = normalized;
      if (issuesFixed == 0) {
        issuesFixed++;
      }
      actions.add(
        V8MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason: 'Znormalizowano rejestr przydomków kolarskich.',
          appliedValueSummary: '${records.length} przydomków',
        ),
      );
    }

    return _NicknamesResult(
      summary: Package8SectionSummary(
        section: section,
        presentBefore: presentBefore,
        validAfter: true,
        recordsCount: records.length,
        issuesFixedCount: issuesFixed,
        note: 'Aktywne przydomki: ${records.length}.',
      ),
      records: records,
    );
  }

  // ---------------------------------------------------------------------------
  // 9. KSIĘGA LEGENDY I DYNASTIA NG+
  // ---------------------------------------------------------------------------
  static _HallOfFameResult _migrateHallOfFameAndDynasty({
    required Map<String, dynamic> payload,
    required List<V8MigrationFieldAction> actions,
  }) {
    const section = Package8MigrationSection.hallOfFameAndDynasty;
    final raw = payload[section.jsonKey];
    final bool presentBefore = raw != null;
    int issuesFixed = 0;

    if (raw == null) {
      payload[section.jsonKey] = <String, dynamic>{
        'entries': const <Map<String, dynamic>>[],
        'activeGenerationNumber': 1,
        'dynastyPrestigeBonus': 0.0,
      };
      actions.add(
        V8MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason: 'Brak Księgi Legendy i Dynastii NG+ — zainicjalizowano generację #1.',
          appliedValueSummary: 'generacja #1, 0 wpisów',
        ),
      );
      return const _HallOfFameResult(
        summary: Package8SectionSummary(
          section: section,
          presentBefore: false,
          validAfter: true,
          recordsCount: 0,
          issuesFixedCount: 1,
          note: 'Zainicjalizowano Księgę Legendy (Generacja #1).',
        ),
        archive: HallOfFameArchive(),
      );
    }

    if (raw is! Map<String, dynamic>) {
      payload[section.jsonKey] = <String, dynamic>{
        'entries': const <Map<String, dynamic>>[],
        'activeGenerationNumber': 1,
        'dynastyPrestigeBonus': 0.0,
      };
      actions.add(
        V8MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason: 'Uszkodzona Księga Legendy — zresetowano do pustego archiwum.',
          appliedValueSummary: 'generacja #1',
          wasRepaired: true,
        ),
      );
      return const _HallOfFameResult(
        summary: Package8SectionSummary(
          section: section,
          presentBefore: true,
          validAfter: true,
          recordsCount: 0,
          issuesFixedCount: 1,
          note: 'Naprawiono uszkodzone archiwum Księgi Legendy.',
        ),
        archive: HallOfFameArchive(),
      );
    }

    final entries = <HallOfFameInductionEntry>[];
    final rawEntries = raw['entries'];
    if (rawEntries is List) {
      for (final item in rawEntries) {
        if (item is Map<String, dynamic>) {
          entries.add(HallOfFameInductionEntry.fromJson(item));
        } else {
          issuesFixed++;
        }
      }
    } else if (rawEntries != null) {
      issuesFixed++;
    }

    final archive = HallOfFameArchive(entries: entries);
    final int gen =
        ((raw['activeGenerationNumber'] as num?)?.toInt() ?? 1).clamp(1, 999);
    final double bonus =
        ((raw['dynastyPrestigeBonus'] as num?)?.toDouble() ?? 0.0)
            .clamp(0.0, 100.0);

    final normalized = <String, dynamic>{
      'entries': archive.entries.map((e) => e.toJson()).toList(),
      'activeGenerationNumber': gen,
      'dynastyPrestigeBonus': bonus,
    };

    if (jsonEncode(raw) != jsonEncode(normalized)) {
      payload[section.jsonKey] = normalized;
      if (issuesFixed == 0) {
        issuesFixed++;
      }
      actions.add(
        V8MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason: 'Znormalizowano archiwum Księgi Legendy i Dynastii NG+.',
          appliedValueSummary: 'wpisy=${entries.length}, gen=#$gen',
        ),
      );
    }

    return _HallOfFameResult(
      summary: Package8SectionSummary(
        section: section,
        presentBefore: presentBefore,
        validAfter: true,
        recordsCount: entries.length,
        issuesFixedCount: issuesFixed,
        note: 'Generacja #$gen, wpisy Hall of Fame: ${entries.length}.',
      ),
      archive: archive,
    );
  }

  // ---------------------------------------------------------------------------
  // 10. FLAGI REALIZMU I PRESETY ROZGRYWKI
  // ---------------------------------------------------------------------------
  static _SectionResult<AppFeatureFlagsState> _migrateGameplayRealismConfig({
    required Map<String, dynamic> payload,
    required List<V8MigrationFieldAction> actions,
  }) {
    const section = Package8MigrationSection.gameplayRealismConfig;
    final raw = payload[section.jsonKey];
    final bool presentBefore = raw != null;
    int issuesFixed = 0;

    if (raw == null) {
      final initial = AppFeatureFlagsState.initial();
      payload[section.jsonKey] = initial.toJson();
      actions.add(
        V8MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason: 'Brak konfiguracji realizmu — zastosowano domyślny preset.',
          appliedValueSummary: initial.activePresetId.name,
        ),
      );
      return _SectionResult(
        summary: Package8SectionSummary(
          section: section,
          presentBefore: false,
          validAfter: true,
          recordsCount: 1,
          issuesFixedCount: 1,
          note: 'Zastosowano domyślny preset realizmu (${initial.activePresetId.name}).',
        ),
        model: initial,
      );
    }

    if (raw is! Map<String, dynamic>) {
      final fallback = AppFeatureFlagsState.initial();
      payload[section.jsonKey] = fallback.toJson();
      actions.add(
        V8MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason: 'Uszkodzona konfiguracja flag realizmu — przywrócono preset domyślny.',
          appliedValueSummary: fallback.activePresetId.name,
          wasRepaired: true,
        ),
      );
      return _SectionResult(
        summary: const Package8SectionSummary(
          section: section,
          presentBefore: true,
          validAfter: true,
          recordsCount: 1,
          issuesFixedCount: 1,
          note: 'Naprawiono uszkodzone flagi realizmu.',
        ),
        model: fallback,
      );
    }

    final parsed = AppFeatureFlagsState.fromJson(raw);
    final normalized = parsed.toJson();
    if (jsonEncode(raw) != jsonEncode(normalized)) {
      payload[section.jsonKey] = normalized;
      issuesFixed++;
      actions.add(
        V8MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason: 'Uzupełniono brakujące flagi realizmu schematu v8.',
          appliedValueSummary: parsed.activePresetId.name,
        ),
      );
    }

    return _SectionResult(
      summary: Package8SectionSummary(
        section: section,
        presentBefore: presentBefore,
        validAfter: true,
        recordsCount: 1,
        issuesFixedCount: issuesFixed,
        note: 'Preset: ${parsed.activePresetId.name}.',
      ),
      model: parsed,
    );
  }

  // ---------------------------------------------------------------------------
  // POMOCNIKI
  // ---------------------------------------------------------------------------
  static int _extractSeasonYear(Map<String, dynamic> payload, DateTime now) {
    final direct = payload['seasonYear'] ?? payload['currentYear'];
    if (direct is num) return direct.toInt().clamp(1970, 2100);
    return now.year;
  }

  static String? _extractString(
    Map<String, dynamic> payload,
    List<String> keys,
  ) {
    for (final k in keys) {
      final val = payload[k];
      if (val is String && val.trim().isNotEmpty) {
        return val.trim();
      }
    }
    return null;
  }
}

class _SectionResult<T> {
  final Package8SectionSummary summary;
  final T model;

  const _SectionResult({required this.summary, required this.model});
}

class _PersonalLifeResult {
  final Package8SectionSummary summary;
  final List<RiderFamilyProfile> profiles;
  final List<PersonalLifeEventRecord> events;

  const _PersonalLifeResult({
    required this.summary,
    required this.profiles,
    required this.events,
  });
}

class _MerchandiseResult {
  final Package8SectionSummary summary;
  final List<MerchandiseProductSpec> products;
  final FanClubMembershipSnapshot membership;
  final List<FanZoneActivation> fanZones;

  const _MerchandiseResult({
    required this.summary,
    required this.products,
    required this.membership,
    required this.fanZones,
  });
}

class _NicknamesResult {
  final Package8SectionSummary summary;
  final List<RiderNicknameRecord> records;

  const _NicknamesResult({required this.summary, required this.records});
}

class _HallOfFameResult {
  final Package8SectionSummary summary;
  final HallOfFameArchive archive;

  const _HallOfFameResult({required this.summary, required this.archive});
}

// =============================================================================
// STAN I NOTIFIER RIVERPOD DLA MIGRATORA V8
// =============================================================================

@immutable
class SaveCompatibilityV8State {
  final bool isRunning;
  final bool initializeOptionalModesIfMissing;
  final Package8MigrationSection? activeFilter;
  final SaveCompatibilityV8Report? lastReport;

  const SaveCompatibilityV8State({
    this.isRunning = false,
    this.initializeOptionalModesIfMissing = false,
    this.activeFilter,
    this.lastReport,
  });

  SaveCompatibilityV8State copyWith({
    bool? isRunning,
    bool? initializeOptionalModesIfMissing,
    Package8MigrationSection? activeFilter,
    bool clearFilter = false,
    SaveCompatibilityV8Report? lastReport,
  }) {
    return SaveCompatibilityV8State(
      isRunning: isRunning ?? this.isRunning,
      initializeOptionalModesIfMissing: initializeOptionalModesIfMissing ??
          this.initializeOptionalModesIfMissing,
      activeFilter: clearFilter ? null : (activeFilter ?? this.activeFilter),
      lastReport: lastReport ?? this.lastReport,
    );
  }
}

class SaveCompatibilityV8Notifier
    extends StateNotifier<SaveCompatibilityV8State> {
  SaveCompatibilityV8Notifier() : super(const SaveCompatibilityV8State());

  void toggleInitializeOptionalModes(bool value) {
    state = state.copyWith(initializeOptionalModesIfMissing: value);
  }

  void setSectionFilter(Package8MigrationSection? section) {
    if (section == null || state.activeFilter == section) {
      state = state.copyWith(clearFilter: true);
    } else {
      state = state.copyWith(activeFilter: section);
    }
  }

  SaveCompatibilityV8Report runMigrationOnRawJson({
    required String saveId,
    required String rawJson,
  }) {
    state = state.copyWith(isRunning: true);
    final report = SaveCompatibilityV8Migrator.migrateRawJson(
      saveId: saveId,
      rawJson: rawJson,
      initializeOptionalModesIfMissing: state.initializeOptionalModesIfMissing,
    );
    state = state.copyWith(isRunning: false, lastReport: report);
    return report;
  }

  SaveCompatibilityV8Report runMigrationOnPayload({
    required String saveId,
    required Map<String, dynamic> payload,
    int sourceSchemaVersion = 7,
  }) {
    state = state.copyWith(isRunning: true);
    final report = SaveCompatibilityV8Migrator.migratePayloadMap(
      saveId: saveId,
      payload: payload,
      sourceSchemaVersion: sourceSchemaVersion,
      initializeOptionalModesIfMissing: state.initializeOptionalModesIfMissing,
    );
    state = state.copyWith(isRunning: false, lastReport: report);
    return report;
  }
}

/// Globalny provider migratora kompatybilności v8 (Paczka #8).
final saveCompatibilityV8Provider = StateNotifierProvider<
    SaveCompatibilityV8Notifier, SaveCompatibilityV8State>(
  (ref) => SaveCompatibilityV8Notifier(),
);

// =============================================================================
// RESPONSYWNY PANEL UI MIGRATORA V8 (LayoutBuilder 390x844 / 1024x768 / 1600x900)
// =============================================================================

/// Responsywny panel diagnostyczny migratora zapisów v8 dla Paczki #8.
class SaveCompatibilityV8MigratorPanel extends ConsumerWidget {
  final String saveId;
  final String? sampleRawJson;
  final Map<String, dynamic>? samplePayload;
  final int sampleSourceSchemaVersion;
  final VoidCallback? onMigrationCompleted;

  const SaveCompatibilityV8MigratorPanel({
    super.key,
    this.saveId = 'active_career_slot',
    this.sampleRawJson,
    this.samplePayload,
    this.sampleSourceSchemaVersion = 7,
    this.onMigrationCompleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(saveCompatibilityV8Provider);
    final notifier = ref.read(saveCompatibilityV8Provider.notifier);

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

  Widget _buildHeader(SaveCompatibilityV8State state, bool isCompact) {
    final statusColor = state.lastReport?.status.color ?? AppColors.goldAccent;
    final statusText =
        state.lastReport?.status.labelPl ?? 'OCZEKUJE NA MIGRACJĘ V8';

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
            Icons.auto_fix_high_rounded,
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
                'Migrator Kompatybilności Zapisów v8 (Paczka #8)',
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
                'Waliduje i migruje struktury Złotej Ery 1970–2015, UCI e-Sports, Zielonej Floty ESG, Życia Osobistego, Reprezentacji Narodowej, Deadline Day, Sklepu Klubowego, Przydomków, Księgi Legendy i Flag Realizmu.',
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
    required SaveCompatibilityV8State state,
    required SaveCompatibilityV8Notifier notifier,
    required bool isCompact,
  }) {
    final toggleButton = _V8ToggleChip(
      label: 'Inicjalizuj opcjonalne tryby (Retro / e-Sports / Kadra / TDD)',
      selected: state.initializeOptionalModesIfMissing,
      onTap: () => notifier.toggleInitializeOptionalModes(
        !state.initializeOptionalModesIfMissing,
      ),
    );

    final runButton = _V8ActionButton(
      label: state.isRunning ? 'Migrowanie do v8...' : 'Uruchom migrację v8',
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

    return Row(
      children: [
        Expanded(child: toggleButton),
        const SizedBox(width: 12),
        runButton,
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.accentBlue, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Naciśnij „Uruchom migrację v8”, aby zweryfikować i uzupełnić struktury Paczki #8 (z automatycznym łańcuchem v1–v7 → v8).',
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

  Widget _buildReportBanner(SaveCompatibilityV8Report report, bool isCompact) {
    final color = report.status.color;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
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
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _metricPill('Schemat', 'v${report.sourceSchemaVersion} → v${report.targetSchemaVersion}'),
              _metricPill('Akcje łącznie', '${report.totalFixesCount}'),
              _metricPill('Naprawy', '${report.repairedFixesCount}'),
              if (!isCompact && report.checksumAfter.isNotEmpty)
                _metricPill(
                  'SHA-256',
                  report.checksumAfter.length > 12
                      ? '${report.checksumAfter.substring(0, 12)}…'
                      : report.checksumAfter,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          fontFeatures: [FontFeature.tabularFigures()],
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildSectionsGrid({
    required SaveCompatibilityV8Report report,
    required SaveCompatibilityV8State state,
    required SaveCompatibilityV8Notifier notifier,
    required bool isCompact,
    required bool isWide,
  }) {
    final int columns = isCompact ? 1 : (isWide ? 2 : 2);
    if (columns == 1) {
      return Column(
        children: [
          for (final summary in report.sectionSummaries) ...[
            _V8SectionFilterCard(
              summary: summary,
              selected: state.activeFilter == summary.section,
              onTap: () => notifier.setSectionFilter(summary.section),
            ),
            const SizedBox(height: 8),
          ],
        ],
      );
    }

    final rows = <Widget>[];
    for (int i = 0; i < report.sectionSummaries.length; i += 2) {
      final first = report.sectionSummaries[i];
      final second = i + 1 < report.sectionSummaries.length
          ? report.sectionSummaries[i + 1]
          : null;
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _V8SectionFilterCard(
                summary: first,
                selected: state.activeFilter == first.section,
                onTap: () => notifier.setSectionFilter(first.section),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: second != null
                  ? _V8SectionFilterCard(
                      summary: second,
                      selected: state.activeFilter == second.section,
                      onTap: () => notifier.setSectionFilter(second.section),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );
      if (i + 2 < report.sectionSummaries.length) {
        rows.add(const SizedBox(height: 10));
      }
    }
    return Column(children: rows);
  }

  Widget _buildActionsLog(
    SaveCompatibilityV8Report report,
    Package8MigrationSection? filter,
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
                color: AppColors.textSecondary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                filter == null
                    ? 'Dziennik migracji v8 (${filtered.length})'
                    : 'Dziennik: ${filter.labelPl} (${filtered.length})',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (filtered.isEmpty)
            const Text(
              'Brak wymaganych zmian dla wybranego filtra.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            )
          else
            for (final action in filtered.take(12))
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      action.wasRepaired
                          ? Icons.build_circle_rounded
                          : Icons.add_circle_outline_rounded,
                      size: 14,
                      color: action.wasRepaired
                          ? AppColors.amberWarning
                          : AppColors.accentBlue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '[${action.jsonPath}] ${action.reason} → ${action.appliedValueSummary}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
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

class _V8ToggleChip extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _V8ToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_V8ToggleChip> createState() => _V8ToggleChipState();
}

class _V8ToggleChipState extends State<_V8ToggleChip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = _focused
        ? AppColors.goldAccent
        : widget.selected
            ? AppColors.accentBlue
            : (_hovered ? AppColors.textSecondary : AppColors.cardBorder);
    final bgColor = _pressed
        ? AppColors.surfaceLight
        : widget.selected
            ? AppColors.accentBlue.withValues(alpha: 0.14)
            : (_hovered ? AppColors.surfaceLight : AppColors.background);

    return FocusableActionDetector(
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
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
                  size: 18,
                  color: widget.selected
                      ? AppColors.accentBlue
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.label,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
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

class _V8ActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  const _V8ActionButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_V8ActionButton> createState() => _V8ActionButtonState();
}

class _V8ActionButtonState extends State<_V8ActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = !widget.enabled
        ? AppColors.surfaceLight
        : _pressed
            ? AppColors.primaryAccent.withValues(alpha: 0.78)
            : _hovered
                ? AppColors.primaryAccent.withValues(alpha: 0.92)
                : AppColors.primaryAccent;

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: MouseRegion(
        cursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.enabled ? widget.onPressed : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _focused ? AppColors.goldAccent : AppColors.cardBorder,
                width: _focused ? 1.5 : 1,
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
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
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
      ),
    );
  }
}

class _V8SectionFilterCard extends StatefulWidget {
  final Package8SectionSummary summary;
  final bool selected;
  final VoidCallback onTap;

  const _V8SectionFilterCard({
    required this.summary,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_V8SectionFilterCard> createState() => _V8SectionFilterCardState();
}

class _V8SectionFilterCardState extends State<_V8SectionFilterCard> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.summary;
    final statusColor = !s.validAfter
        ? AppColors.crimsonAlert
        : s.issuesFixedCount > 0
            ? AppColors.amberWarning
            : AppColors.statusSuccess;

    return FocusableActionDetector(
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
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
              color: _pressed
                  ? AppColors.surfaceLight
                  : widget.selected
                      ? AppColors.surfaceLight
                      : (_hovered
                          ? AppColors.surfaceLight.withValues(alpha: 0.7)
                          : AppColors.background),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _focused
                    ? AppColors.goldAccent
                    : widget.selected
                        ? AppColors.goldAccent
                        : AppColors.cardBorder,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(s.section.icon, size: 16, color: AppColors.goldAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.section.labelPl,
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
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  s.note,
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
      ),
    );
  }
}
