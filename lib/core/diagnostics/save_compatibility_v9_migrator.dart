// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/career/rider_relationship_chemistry_web_model.dart';
import '../../models/paracycling/uci_paracycling_tandem_handbike_model.dart';
import '../../models/race/global_exotic_tours_expansion_model.dart';
import '../../services/career/ai_director_sportif_tactical_styles_engine.dart';
import '../../services/career/custom_training_microcycle_builder_service.dart';
import '../../services/career/equipment_wind_tunnel_custom_decals_and_serials.dart';
import '../../services/career/global_sponsor_market_expansion_service.dart';
import '../../services/career/team_bonding_retreat_and_conflict_mediation.dart';
import '../../services/career/youth_talent_summer_combine_camp.dart';
import '../../services/database/career_statistics_deep_analytics_exporter.dart';
import '../../services/database/database_backup_and_integrity_repair.dart';
import '../theme/app_colors.dart';
import 'save_compatibility_v8_migrator.dart';

/// Sekcje danych wprowadzone w Paczce #9 (#613–#662) objęte migracją v9.
enum Package9MigrationSection {
  globalExoticToursExpansion(
    'Globalna Ekspansja UCI (Afryka/Azja/Bliski Wschód)',
    'globalExoticToursExpansion',
    'Ekspansja #613',
    Icons.public_rounded,
  ),
  globalSponsorMarket(
    'Sponsorzy Rynków Wschodzących',
    'globalSponsorMarket',
    'Sponsorzy #616',
    Icons.handshake_rounded,
  ),
  riderRelationshipChemistry(
    'Psychologia Szatni 2.0 i Blood Brothers',
    'riderRelationshipChemistry',
    'Szatnia #617',
    Icons.hub_rounded,
  ),
  teamBondingAndMediation(
    'Integracje Drużynowe i Mediacje',
    'teamBondingAndMediation',
    'Mediacje #619',
    Icons.diversity_3_rounded,
  ),
  uciParacyclingWorld(
    'UCI Para-Cycling (Tandemy B i Handbike H1–H5)',
    'uciParacyclingWorld',
    'Para-Cycling #622',
    Icons.accessible_forward_rounded,
  ),
  equipmentCustomDecalsAndSerials(
    'Numery Seryjne Ram i Muzeum Klubowe',
    'equipmentCustomDecalsAndSerials',
    'Sprzęt #629',
    Icons.qr_code_2_rounded,
  ),
  aiDirectorSportifStyles(
    'Style Taktyczne 52 Dyrektorów Sportowych AI',
    'aiDirectorSportifStyles',
    'Taktyka AI #632',
    Icons.psychology_rounded,
  ),
  trainingMicrocycles(
    'Tygodniowe Mikrocykle Treningowe (TSS/TSB)',
    'trainingMicrocycles',
    'Trening #638',
    Icons.calendar_view_week_rounded,
  ),
  youthTalentCombine(
    'Global Young Talent Combine (Obóz Juniorów)',
    'youthTalentCombine',
    'Combine #642',
    Icons.school_rounded,
  ),
  deepCareerAnalyticsBi(
    'Analityka BI Kariery i Eksport CSV/JSON',
    'deepCareerAnalyticsBi',
    'BI #646',
    Icons.analytics_rounded,
  );

  final String labelPl;
  final String jsonKey;
  final String packageTag;
  final IconData icon;

  const Package9MigrationSection(
    this.labelPl,
    this.jsonKey,
    this.packageTag,
    this.icon,
  );
}

/// Wynikowy status migracji zapisu do schematu v9 (Paczka #9).
enum V9MigrationStatus {
  alreadyCompatible('ZGODNY Z V9 (PACZKA #9)', AppColors.statusSuccess),
  migrated('ZMIGROWANY DO V9', AppColors.accentBlue),
  repairedAndMigrated('NAPRAWIONY I ZMIGROWANY DO V9', AppColors.amberWarning),
  failed('BŁĄD MIGRACJI V9', AppColors.crimsonAlert);

  final String labelPl;
  final Color color;

  const V9MigrationStatus(this.labelPl, this.color);

  bool get isSuccess => this != V9MigrationStatus.failed;
}

/// Pojedyncza akcja uzupełnienia, normalizacji lub naprawy pola podczas migracji v9.
@immutable
class V9MigrationFieldAction {
  final String jsonPath;
  final Package9MigrationSection? section;
  final String reason;
  final String appliedValueSummary;
  final bool wasRepaired;

  const V9MigrationFieldAction({
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

/// Podsumowanie stanu pojedynczej sekcji Paczki #9 po przejściu migracji v9.
@immutable
class Package9SectionSummary {
  final Package9MigrationSection section;
  final bool presentBefore;
  final bool validAfter;
  final int recordsCount;
  final int issuesFixedCount;
  final String note;

  const Package9SectionSummary({
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

/// Pełny raport migracji kompatybilności zapisu gry do schematu v9 (Paczka #9).
@immutable
class SaveCompatibilityV9Report {
  final String saveId;
  final int sourceSchemaVersion;
  final int targetSchemaVersion;
  final V9MigrationStatus status;
  final DateTime migratedAtUtc;
  final String checksumBefore;
  final String checksumAfter;
  final List<Package9SectionSummary> sectionSummaries;
  final List<V9MigrationFieldAction> actions;
  final SaveCompatibilityV8Report? v8PreMigrationReport;
  final Map<String, dynamic>? migratedPayload;
  final IntegritySaveEnvelope? migratedEnvelope;
  final GlobalExoticToursExpansionModel? hydratedExoticTours;
  final GlobalSponsorMarketState? hydratedSponsorMarket;
  final RiderRelationshipChemistryWebModel? hydratedChemistryWeb;
  final List<TeamBondingHistoryEntry> hydratedBondingHistory;
  final UciParacyclingTandemHandbikeModel? hydratedParacyclingWorld;
  final EquipmentWindTunnelDecalsState? hydratedEquipmentDecals;
  final AiDirectorSportifTacticalStylesState? hydratedAiDsStyles;
  final List<WeeklyTrainingMicrocycle> hydratedTrainingMicrocycles;
  final CombineCampEdition? hydratedCombineEdition;
  final List<CombineCampHistoryEntry> hydratedCombineHistory;
  final CareerAnalyticsExportConfig? hydratedAnalyticsConfig;
  final List<SeasonAnalyticsSnapshot> hydratedAnalyticsSnapshots;
  final String summaryMessage;
  final String? errorMessage;

  const SaveCompatibilityV9Report({
    required this.saveId,
    required this.sourceSchemaVersion,
    this.targetSchemaVersion = SaveCompatibilityV9Migrator.targetSchemaVersion,
    required this.status,
    required this.migratedAtUtc,
    required this.checksumBefore,
    required this.checksumAfter,
    this.sectionSummaries = const [],
    this.actions = const [],
    this.v8PreMigrationReport,
    this.migratedPayload,
    this.migratedEnvelope,
    this.hydratedExoticTours,
    this.hydratedSponsorMarket,
    this.hydratedChemistryWeb,
    this.hydratedBondingHistory = const [],
    this.hydratedParacyclingWorld,
    this.hydratedEquipmentDecals,
    this.hydratedAiDsStyles,
    this.hydratedTrainingMicrocycles = const [],
    this.hydratedCombineEdition,
    this.hydratedCombineHistory = const [],
    this.hydratedAnalyticsConfig,
    this.hydratedAnalyticsSnapshots = const [],
    required this.summaryMessage,
    this.errorMessage,
  });

  int get totalFixesCount =>
      actions.length + (v8PreMigrationReport?.totalFixesCount ?? 0);

  int get repairedFixesCount =>
      actions.where((a) => a.wasRepaired).length +
      (v8PreMigrationReport?.repairedFixesCount ?? 0);

  Package9SectionSummary? summaryFor(Package9MigrationSection section) {
    for (final s in sectionSummaries) {
      if (s.section == section) return s;
    }
    return null;
  }
}

/// Automatyczny migrator zapisów gry do schematu v9 dla struktur Paczki #9,
/// zachowujący pełną kompatybilność wsteczną z zapisami v1–v8.
class SaveCompatibilityV9Migrator {
  static const int targetSchemaVersion = 9;

  /// Migruje surowy JSON pliku zapisu (`IntegritySaveEnvelope` lub surowy `CareerSave`).
  static SaveCompatibilityV9Report migrateRawJson({
    required String saveId,
    required String rawJson,
    bool initializeOptionalModesIfMissing = false,
  }) {
    final now = DateTime.now().toUtc();
    if (rawJson.trim().isEmpty) {
      return SaveCompatibilityV9Report(
        saveId: saveId,
        sourceSchemaVersion: 0,
        status: V9MigrationStatus.failed,
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
          return SaveCompatibilityV9Report(
            saveId: saveId,
            sourceSchemaVersion: 0,
            status: V9MigrationStatus.failed,
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
      return SaveCompatibilityV9Report(
        saveId: saveId,
        sourceSchemaVersion: 0,
        status: V9MigrationStatus.failed,
        migratedAtUtc: now,
        checksumBefore: '',
        checksumAfter: '',
        summaryMessage: 'Nieoczekiwany błąd podczas parsowania zapisu JSON.',
        errorMessage: e.toString(),
      );
    }
  }

  /// Migruje zdekodowaną mapę payloadu `CareerSave` w pamięci do schematu v9.
  static SaveCompatibilityV9Report migratePayloadMap({
    required String saveId,
    required Map<String, dynamic> payload,
    int sourceSchemaVersion = 8,
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
      return SaveCompatibilityV9Report(
        saveId: saveId,
        sourceSchemaVersion: sourceSchemaVersion,
        status: V9MigrationStatus.failed,
        migratedAtUtc: now,
        checksumBefore: '',
        checksumAfter: '',
        summaryMessage: 'Błąd podczas klonowania lub migracji mapy payloadu.',
        errorMessage: e.toString(),
      );
    }
  }

  static SaveCompatibilityV9Report _migratePayloadInternal({
    required String saveId,
    required int sourceSchemaVersion,
    required String checksumBefore,
    required Map<String, dynamic> workingPayload,
    required List<String> existingHistory,
    required bool hadEnvelope,
    required bool initializeOptionalModesIfMissing,
    required DateTime now,
  }) {
    final actions = <V9MigrationFieldAction>[];
    final summaries = <Package9SectionSummary>[];

    // Krok 0: Jeśli zapis jest starszy niż v8, przepuść go najpierw przez SaveCompatibilityV8Migrator.
    SaveCompatibilityV8Report? v8Report;
    Map<String, dynamic> payload = workingPayload;
    if (sourceSchemaVersion < 8) {
      v8Report = SaveCompatibilityV8Migrator.migratePayloadMap(
        saveId: saveId,
        payload: workingPayload,
        sourceSchemaVersion: sourceSchemaVersion,
        initializeOptionalModesIfMissing: initializeOptionalModesIfMissing,
      );
      if (!v8Report.status.isSuccess || v8Report.migratedPayload == null) {
        return SaveCompatibilityV9Report(
          saveId: saveId,
          sourceSchemaVersion: sourceSchemaVersion,
          status: V9MigrationStatus.failed,
          migratedAtUtc: now,
          checksumBefore: checksumBefore,
          checksumAfter: checksumBefore,
          v8PreMigrationReport: v8Report,
          summaryMessage:
              'Nie powiodła się wstępna migracja v$sourceSchemaVersion -> v8.',
          errorMessage: v8Report.errorMessage ?? 'V8_PRE_MIGRATION_FAILED',
        );
      }
      payload = jsonDecode(jsonEncode(v8Report.migratedPayload!))
          as Map<String, dynamic>;
    }

    final int seasonYear = _extractSeasonYear(payload, now);
    final String teamId =
        _extractString(payload, const ['playerTeamId', 'teamId']) ??
            'team_polonia_orlen';
    final String teamName =
        _extractString(payload, const ['playerTeamName', 'teamName']) ??
            'Pro Peloton Team';

    // 1. Globalna Ekspansja UCI (Afryka, Azja, Bliski Wschód)
    final exoticRes = _migrateGlobalExoticToursExpansion(
      payload: payload,
      seasonYear: seasonYear,
      actions: actions,
    );
    summaries.add(exoticRes.summary);

    // 2. Sponsorzy Rynków Wschodzących
    final sponsorRes = _migrateGlobalSponsorMarket(
      payload: payload,
      actions: actions,
    );
    summaries.add(sponsorRes.summary);

    // 3. Psychologia Szatni 2.0 i Blood Brothers
    final chemistryRes = _migrateRiderRelationshipChemistry(
      payload: payload,
      teamId: teamId,
      seasonYear: seasonYear,
      actions: actions,
    );
    summaries.add(chemistryRes.summary);

    // 4. Integracje Drużynowe i Mediacje
    final bondingRes = _migrateTeamBondingAndMediation(
      payload: payload,
      actions: actions,
    );
    summaries.add(bondingRes.summary);

    // 5. UCI Para-Cycling (tryb opcjonalny)
    final paraRes = _migrateUciParacyclingWorld(
      payload: payload,
      seasonYear: seasonYear,
      teamName: teamName,
      initializeIfMissing: initializeOptionalModesIfMissing,
      actions: actions,
    );
    summaries.add(paraRes.summary);

    // 6. Numery Seryjne Ram i Muzeum Klubowe
    final decalsRes = _migrateEquipmentCustomDecalsAndSerials(
      payload: payload,
      actions: actions,
    );
    summaries.add(decalsRes.summary);

    // 7. Style Taktyczne 52 Dyrektorów Sportowych AI
    final aiDsRes = _migrateAiDirectorSportifStyles(
      payload: payload,
      teamId: teamId,
      actions: actions,
    );
    summaries.add(aiDsRes.summary);

    // 8. Tygodniowe Mikrocykle Treningowe (TSS/TSB)
    final microcycleRes = _migrateTrainingMicrocycles(
      payload: payload,
      actions: actions,
    );
    summaries.add(microcycleRes.summary);

    // 9. Global Young Talent Combine (Obóz Juniorów)
    final combineRes = _migrateYouthTalentCombine(
      payload: payload,
      seasonYear: seasonYear,
      initializeIfMissing: initializeOptionalModesIfMissing,
      actions: actions,
    );
    summaries.add(combineRes.summary);

    // 10. Analityka BI Kariery i Eksport CSV/JSON
    final analyticsRes = _migrateDeepCareerAnalyticsBi(
      payload: payload,
      actions: actions,
    );
    summaries.add(analyticsRes.summary);

    // Aktualizacja wersji schematu payloadu do v9
    final int? payloadSchema = (payload['schemaVersion'] as num?)?.toInt();
    if (payloadSchema != targetSchemaVersion) {
      payload['schemaVersion'] = targetSchemaVersion;
      actions.add(
        const V9MigrationFieldAction(
          jsonPath: 'schemaVersion',
          reason: 'Podniesiono wersję schematu zapisu do v$targetSchemaVersion.',
          appliedValueSummary: '$targetSchemaVersion',
        ),
      );
    }

    if (payload['saveId'] == null || payload['saveId'].toString().trim().isEmpty) {
      payload['saveId'] = saveId;
      actions.add(
        V9MigrationFieldAction(
          jsonPath: 'saveId',
          reason: 'Uzupełniono brakujący identyfikator zapisu saveId.',
          appliedValueSummary: saveId,
        ),
      );
    }

    final checksumAfter =
        DatabaseBackupAndIntegrityRepair.computeCanonicalPayloadChecksum(
      payload,
    );
    final canonicalEncoded = jsonEncode(
      DatabaseBackupAndIntegrityRepair.canonicalizeJsonValue(payload),
    );
    final payloadBytes = utf8.encode(canonicalEncoded).length;

    final bool anyRepaired = actions.any((a) => a.wasRepaired) ||
        (v8Report?.repairedFixesCount ?? 0) > 0;
    final bool anyChanged = actions.isNotEmpty ||
        sourceSchemaVersion < targetSchemaVersion ||
        !hadEnvelope ||
        v8Report != null;

    final V9MigrationStatus status;
    if (anyRepaired) {
      status = V9MigrationStatus.repairedAndMigrated;
    } else if (anyChanged) {
      status = V9MigrationStatus.migrated;
    } else {
      status = V9MigrationStatus.alreadyCompatible;
    }

    final updatedHistory = List<String>.from(existingHistory);
    if (v8Report != null) {
      updatedHistory.addAll(
        v8Report.migratedEnvelope?.migrationHistory ?? const <String>[],
      );
    }
    if (status != V9MigrationStatus.alreadyCompatible) {
      updatedHistory.add(
        'v$sourceSchemaVersion->v$targetSchemaVersion (${now.toIso8601String()})',
      );
    }

    final migratedEnvelope = IntegritySaveEnvelope(
      schemaVersion: targetSchemaVersion,
      checksumAlgorithm: IntegritySaveEnvelope.checksumAlgorithmName,
      checksum: checksumAfter,
      payloadBytes: payloadBytes,
      savedAtUtc: now,
      migrationHistory: updatedHistory,
      payload: payload,
    );

    final int totalFixes =
        actions.length + (v8Report?.totalFixesCount ?? 0);

    final String summaryMessage = switch (status) {
      V9MigrationStatus.alreadyCompatible =>
        'Zapis "$saveId" jest w pełni zgodny ze schematem v9 (Paczka #9).',
      V9MigrationStatus.migrated =>
        'Zmigrowano zapis "$saveId" (v$sourceSchemaVersion → v9) z $totalFixes aktualizacjami pól Paczki #9.',
      V9MigrationStatus.repairedAndMigrated =>
        'Naprawiono i zmigrowano zapis "$saveId" (v$sourceSchemaVersion → v9); łącznie $totalFixes poprawek.',
      V9MigrationStatus.failed => 'Migracja v9 nie powiodła się.',
    };

    return SaveCompatibilityV9Report(
      saveId: saveId,
      sourceSchemaVersion: sourceSchemaVersion,
      status: status,
      migratedAtUtc: now,
      checksumBefore: checksumBefore,
      checksumAfter: checksumAfter,
      sectionSummaries: List<Package9SectionSummary>.unmodifiable(summaries),
      actions: List<V9MigrationFieldAction>.unmodifiable(actions),
      v8PreMigrationReport: v8Report,
      migratedPayload: payload,
      migratedEnvelope: migratedEnvelope,
      hydratedExoticTours: exoticRes.model,
      hydratedSponsorMarket: sponsorRes.model,
      hydratedChemistryWeb: chemistryRes.model,
      hydratedBondingHistory: bondingRes.entries,
      hydratedParacyclingWorld: paraRes.model,
      hydratedEquipmentDecals: decalsRes.model,
      hydratedAiDsStyles: aiDsRes.model,
      hydratedTrainingMicrocycles: microcycleRes.microcycles,
      hydratedCombineEdition: combineRes.edition,
      hydratedCombineHistory: combineRes.history,
      hydratedAnalyticsConfig: analyticsRes.config,
      hydratedAnalyticsSnapshots: analyticsRes.snapshots,
      summaryMessage: summaryMessage,
    );
  }

  // ---------------------------------------------------------------------------
  // 1. GLOBALNA EKSPANSJA UCI (AFRYKA, AZJA, BLISKI WSCHÓD)
  // ---------------------------------------------------------------------------
  static _SectionResult<GlobalExoticToursExpansionModel>
      _migrateGlobalExoticToursExpansion({
    required Map<String, dynamic> payload,
    required int seasonYear,
    required List<V9MigrationFieldAction> actions,
  }) {
    const section = Package9MigrationSection.globalExoticToursExpansion;
    final raw = payload[section.jsonKey];
    final bool presentBefore = raw != null;
    int issuesFixed = 0;

    if (raw == null) {
      final model = GlobalExoticToursExpansionModel.initial(
        seasonYear: seasonYear,
      );
      payload[section.jsonKey] = model.toJson();
      actions.add(
        V9MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason:
              'Brak danych ekspansji pozaeuropejskiej UCI — utworzono 4 flagowe wyścigi.',
          appliedValueSummary:
              'sezon=$seasonYear, wyścigi=${model.tours.length}',
        ),
      );
      return _SectionResult(
        summary: Package9SectionSummary(
          section: section,
          presentBefore: false,
          validAfter: true,
          recordsCount: model.tours.length,
          issuesFixedCount: 1,
          note: 'Zainicjalizowano 4 wyścigi (Rwanda, Langkawi, Oman, AlUla).',
        ),
        model: model,
      );
    }

    if (raw is! Map<String, dynamic>) {
      final repaired = GlobalExoticToursExpansionModel.initial(
        seasonYear: seasonYear,
      );
      payload[section.jsonKey] = repaired.toJson();
      actions.add(
        V9MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason:
              'Uszkodzony typ obiektu globalnej ekspansji UCI — przywrócono stan domyślny.',
          appliedValueSummary: 'zresetowano 4 wyścigi egzotyczne',
          wasRepaired: true,
        ),
      );
      return _SectionResult(
        summary: Package9SectionSummary(
          section: section,
          presentBefore: true,
          validAfter: true,
          recordsCount: repaired.tours.length,
          issuesFixedCount: 1,
          note: 'Naprawiono uszkodzoną strukturę wyścigów pozaeuropejskich.',
        ),
        model: repaired,
      );
    }

    GlobalExoticToursExpansionModel parsed;
    try {
      parsed = GlobalExoticToursExpansionModel.fromJson(raw);
    } catch (_) {
      parsed = GlobalExoticToursExpansionModel.initial(seasonYear: seasonYear);
      issuesFixed++;
      actions.add(
        V9MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason:
              'Niekompletne rekordy wyścigów pozaeuropejskich — odbudowano strukturę.',
          appliedValueSummary: 'sezon=$seasonYear',
          wasRepaired: true,
        ),
      );
    }

    final double clampedRep =
        parsed.globalExpansionReputation.clamp(0.0, 100.0);
    final int clampedFans = parsed.nonEuropeanFanBase < 0
        ? 0
        : parsed.nonEuropeanFanBase;
    if (clampedRep != parsed.globalExpansionReputation ||
        clampedFans != parsed.nonEuropeanFanBase) {
      parsed = parsed.copyWith(
        globalExpansionReputation: clampedRep,
        nonEuropeanFanBase: clampedFans,
      );
      issuesFixed++;
      actions.add(
        V9MigrationFieldAction(
          jsonPath: '${section.jsonKey}.globalExpansionReputation',
          section: section,
          reason: 'Skorygowano reputację ekspansji lub liczbę kibiców poza Europą.',
          appliedValueSummary:
              'rep=${clampedRep.toStringAsFixed(1)}, kibice=$clampedFans',
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
          V9MigrationFieldAction(
            jsonPath: section.jsonKey,
            section: section,
            reason: 'Znormalizowano pola ekspansji pozaeuropejskiej UCI.',
            appliedValueSummary: 'wyścigi=${parsed.tours.length}',
          ),
        );
      }
    }

    return _SectionResult(
      summary: Package9SectionSummary(
        section: section,
        presentBefore: presentBefore,
        validAfter: true,
        recordsCount: parsed.tours.length + parsed.participationHistory.length,
        issuesFixedCount: issuesFixed,
        note:
            'Wyścigi: ${parsed.tours.length}, starty: ${parsed.participationHistory.length}.',
      ),
      model: parsed,
    );
  }

  // ---------------------------------------------------------------------------
  // 2. SPONSORZY RYNKÓW WSCHODZĄCYCH
  // ---------------------------------------------------------------------------
  static _SectionResult<GlobalSponsorMarketState> _migrateGlobalSponsorMarket({
    required Map<String, dynamic> payload,
    required List<V9MigrationFieldAction> actions,
  }) {
    const section = Package9MigrationSection.globalSponsorMarket;
    final raw = payload[section.jsonKey];
    final bool presentBefore = raw != null;
    int issuesFixed = 0;

    if (raw == null) {
      final initial = GlobalSponsorMarketState.initial();
      payload[section.jsonKey] = initial.toJson();
      actions.add(
        V9MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason:
              'Brak danych rynku sponsorów wschodzących — utworzono oferty Azja/Afryka/Bliski Wschód.',
          appliedValueSummary:
              'oferty=${initial.availableOffers.length}, misje=${initial.activationMissions.length}',
        ),
      );
      return _SectionResult(
        summary: Package9SectionSummary(
          section: section,
          presentBefore: false,
          validAfter: true,
          recordsCount: initial.availableOffers.length,
          issuesFixedCount: 1,
          note:
              'Zainicjalizowano ${initial.availableOffers.length} ofert z rynków wschodzących.',
        ),
        model: initial,
      );
    }

    if (raw is! Map<String, dynamic>) {
      final repaired = GlobalSponsorMarketState.initial();
      payload[section.jsonKey] = repaired.toJson();
      actions.add(
        V9MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason:
              'Uszkodzona struktura rynku sponsorów wschodzących — przywrócono stan domyślny.',
          appliedValueSummary: 'zresetowano oferty rynkowe',
          wasRepaired: true,
        ),
      );
      return _SectionResult(
        summary: Package9SectionSummary(
          section: section,
          presentBefore: true,
          validAfter: true,
          recordsCount: repaired.availableOffers.length,
          issuesFixedCount: 1,
          note: 'Naprawiono uszkodzony moduł sponsorów wschodzących.',
        ),
        model: repaired,
      );
    }

    GlobalSponsorMarketState parsed;
    try {
      parsed = GlobalSponsorMarketState.fromJson(raw);
    } catch (_) {
      parsed = GlobalSponsorMarketState.initial();
      issuesFixed++;
      actions.add(
        V9MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason:
              'Niekompletne lub nieprawidłowe pola sponsorów wschodzących — odbudowano.',
          appliedValueSummary: 'oferty=${parsed.availableOffers.length}',
          wasRepaired: true,
        ),
      );
    }

    final double clampedPrestige = parsed.teamPrestige.clamp(0.0, 100.0);
    final int clampedBudget = parsed.teamAvailableBudgetEur < 0
        ? 0
        : parsed.teamAvailableBudgetEur;
    final int clampedDay = parsed.currentSeasonDay < 1
        ? 1
        : parsed.currentSeasonDay;

    if (clampedPrestige != parsed.teamPrestige ||
        clampedBudget != parsed.teamAvailableBudgetEur ||
        clampedDay != parsed.currentSeasonDay) {
      parsed = parsed.copyWith(
        teamPrestige: clampedPrestige,
        teamAvailableBudgetEur: clampedBudget,
        currentSeasonDay: clampedDay,
      );
      issuesFixed++;
      actions.add(
        V9MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason: 'Skorygowano ujemny budżet lub zakres prestiżu w rynku sponsorów.',
          appliedValueSummary:
              'prestiż=${clampedPrestige.toStringAsFixed(1)}, dzień=$clampedDay',
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
          V9MigrationFieldAction(
            jsonPath: section.jsonKey,
            section: section,
            reason: 'Znormalizowano strukturę JSON rynku sponsorów wschodzących.',
            appliedValueSummary:
                'kontrakty=${parsed.activeContracts.length}, oferty=${parsed.availableOffers.length}',
          ),
        );
      }
    }

    return _SectionResult(
      summary: Package9SectionSummary(
        section: section,
        presentBefore: presentBefore,
        validAfter: true,
        recordsCount:
            parsed.availableOffers.length + parsed.activeContracts.length,
        issuesFixedCount: issuesFixed,
        note:
            'Aktywne umowy: ${parsed.activeContracts.length}, oferty: ${parsed.availableOffers.length}.',
      ),
      model: parsed,
    );
  }

  // ---------------------------------------------------------------------------
  // 3. PSYCHOLOGIA SZATNI 2.0 I PAKTY BLOOD BROTHERS
  // ---------------------------------------------------------------------------
  static _SectionResult<RiderRelationshipChemistryWebModel>
      _migrateRiderRelationshipChemistry({
    required Map<String, dynamic> payload,
    required String teamId,
    required int seasonYear,
    required List<V9MigrationFieldAction> actions,
  }) {
    const section = Package9MigrationSection.riderRelationshipChemistry;
    final raw = payload[section.jsonKey];
    final bool presentBefore = raw != null;
    int issuesFixed = 0;

    if (raw == null) {
      final empty = RiderRelationshipChemistryWebModel.empty(
        teamId: teamId,
        seasonYear: seasonYear,
      );
      payload[section.jsonKey] = empty.toJson();
      actions.add(
        V9MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason:
              'Brak grafu relacji szatni 2.0 — utworzono pustą sieć zespołu.',
          appliedValueSummary: 'teamId=$teamId, sezon=$seasonYear',
        ),
      );
      return _SectionResult(
        summary: const Package9SectionSummary(
          section: section,
          presentBefore: false,
          validAfter: true,
          recordsCount: 0,
          issuesFixedCount: 1,
          note: 'Zainicjalizowano pustą sieć relacji szatni.',
        ),
        model: empty,
      );
    }

    if (raw is! Map<String, dynamic>) {
      final repaired = RiderRelationshipChemistryWebModel.empty(
        teamId: teamId,
        seasonYear: seasonYear,
      );
      payload[section.jsonKey] = repaired.toJson();
      actions.add(
        V9MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason:
              'Uszkodzony typ danych Psychologii Szatni 2.0 — przywrócono pustą sieć.',
          appliedValueSummary: 'zresetowano graf relacji',
          wasRepaired: true,
        ),
      );
      return _SectionResult(
        summary: const Package9SectionSummary(
          section: section,
          presentBefore: true,
          validAfter: true,
          recordsCount: 0,
          issuesFixedCount: 1,
          note: 'Naprawiono uszkodzony graf relacji drużynowych.',
        ),
        model: repaired,
      );
    }

    RiderRelationshipChemistryWebModel parsed;
    try {
      parsed = RiderRelationshipChemistryWebModel.fromJson(raw);
    } catch (_) {
      parsed = RiderRelationshipChemistryWebModel.empty(
        teamId: teamId,
        seasonYear: seasonYear,
      );
      issuesFixed++;
      actions.add(
        V9MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason: 'Błąd parsowania grafu relacji — odbudowano strukturę.',
          appliedValueSummary: 'teamId=$teamId',
          wasRepaired: true,
        ),
      );
    }

    if (parsed.teamId.trim().isEmpty) {
      parsed = RiderRelationshipChemistryWebModel(
        teamId: teamId,
        seasonYear: parsed.seasonYear,
        profiles: parsed.profiles,
        edges: parsed.edges,
        bloodBrothersPacts: parsed.bloodBrothersPacts,
        recentEvents: parsed.recentEvents,
      );
      issuesFixed++;
      actions.add(
        V9MigrationFieldAction(
          jsonPath: '${section.jsonKey}.teamId',
          section: section,
          reason: 'Uzupełniono brakujące teamId w grafie relacji szatni.',
          appliedValueSummary: teamId,
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
          V9MigrationFieldAction(
            jsonPath: section.jsonKey,
            section: section,
            reason: 'Znormalizowano krawędzie relacji i pakty Blood Brothers.',
            appliedValueSummary:
                'profile=${parsed.profiles.length}, krawędzie=${parsed.edges.length}',
          ),
        );
      }
    }

    return _SectionResult(
      summary: Package9SectionSummary(
        section: section,
        presentBefore: presentBefore,
        validAfter: true,
        recordsCount:
            parsed.profiles.length + parsed.bloodBrothersPacts.length,
        issuesFixedCount: issuesFixed,
        note:
            'Kolarze: ${parsed.profiles.length}, relacje: ${parsed.edges.length}, pakty: ${parsed.bloodBrothersPacts.length}.',
      ),
      model: parsed,
    );
  }

  // ---------------------------------------------------------------------------
  // 4. INTEGRACJE DRUŻYNOWE I MEDIACJE
  // ---------------------------------------------------------------------------
  static _BondingResult _migrateTeamBondingAndMediation({
    required Map<String, dynamic> payload,
    required List<V9MigrationFieldAction> actions,
  }) {
    const section = Package9MigrationSection.teamBondingAndMediation;
    final raw = payload[section.jsonKey];
    final bool presentBefore = raw != null;
    int issuesFixed = 0;

    if (raw == null) {
      payload[section.jsonKey] = <String, dynamic>{
        'history': const <Map<String, dynamic>>[],
        'completedRetreatsCount': 0,
        'resolvedMediationsCount': 0,
      };
      actions.add(
        V9MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason:
              'Brak historii integracji i mediacji — utworzono pusty dziennik.',
          appliedValueSummary: 'wpisy=0',
        ),
      );
      return const _BondingResult(
        summary: Package9SectionSummary(
          section: section,
          presentBefore: false,
          validAfter: true,
          recordsCount: 0,
          issuesFixedCount: 1,
          note: 'Utworzono dziennik wyjazdów integracyjnych i mediacji.',
        ),
        entries: [],
      );
    }

    if (raw is! Map<String, dynamic>) {
      payload[section.jsonKey] = <String, dynamic>{
        'history': const <Map<String, dynamic>>[],
        'completedRetreatsCount': 0,
        'resolvedMediationsCount': 0,
      };
      actions.add(
        V9MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason: 'Uszkodzona struktura integracji i mediacji — zresetowano.',
          appliedValueSummary: 'wpisy=0',
          wasRepaired: true,
        ),
      );
      return const _BondingResult(
        summary: Package9SectionSummary(
          section: section,
          presentBefore: true,
          validAfter: true,
          recordsCount: 0,
          issuesFixedCount: 1,
          note: 'Naprawiono uszkodzony dziennik integracji.',
        ),
        entries: [],
      );
    }

    final entries = <TeamBondingHistoryEntry>[];
    final rawHistory = raw['history'];
    if (rawHistory is List) {
      for (final item in rawHistory) {
        if (item is Map<String, dynamic>) {
          entries.add(TeamBondingHistoryEntry.fromJson(item));
        } else {
          issuesFixed++;
        }
      }
    } else if (rawHistory != null) {
      issuesFixed++;
    }

    final int retreatsCount =
        ((raw['completedRetreatsCount'] as num?)?.toInt() ?? 0)
            .clamp(0, 100000);
    final int mediationsCount =
        ((raw['resolvedMediationsCount'] as num?)?.toInt() ?? 0)
            .clamp(0, 100000);

    final normalized = <String, dynamic>{
      'history': entries.map((e) => e.toJson()).toList(),
      'completedRetreatsCount': retreatsCount,
      'resolvedMediationsCount': mediationsCount,
    };

    if (jsonEncode(raw) != jsonEncode(normalized)) {
      payload[section.jsonKey] = normalized;
      if (issuesFixed == 0) {
        issuesFixed++;
      }
      actions.add(
        V9MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason: 'Znormalizowano wpisy integracji drużynowych i mediacji.',
          appliedValueSummary:
              'wpisy=${entries.length}, mediacje=$mediationsCount',
          wasRepaired: issuesFixed > 0 && rawHistory is! List,
        ),
      );
    }

    return _BondingResult(
      summary: Package9SectionSummary(
        section: section,
        presentBefore: presentBefore,
        validAfter: true,
        recordsCount: entries.length,
        issuesFixedCount: issuesFixed,
        note:
            'Wpisy: ${entries.length}, wyjazdy: $retreatsCount, mediacje: $mediationsCount.',
      ),
      entries: entries,
    );
  }

  // ---------------------------------------------------------------------------
  // 5. UCI PARA-CYCLING (TANDEMY B, HANDBIKE H1-H5, C1-C5) - OPCJONALNY
  // ---------------------------------------------------------------------------
  static _OptionalSectionResult<UciParacyclingTandemHandbikeModel>
      _migrateUciParacyclingWorld({
    required Map<String, dynamic> payload,
    required int seasonYear,
    required String teamName,
    required bool initializeIfMissing,
    required List<V9MigrationFieldAction> actions,
  }) {
    const section = Package9MigrationSection.uciParacyclingWorld;
    final raw = payload[section.jsonKey];
    final bool presentBefore = raw != null;

    if (raw == null) {
      if (!initializeIfMissing) {
        return const _OptionalSectionResult(
          summary: Package9SectionSummary(
            section: section,
            presentBefore: false,
            validAfter: true,
            recordsCount: 0,
            issuesFixedCount: 0,
            note: 'Tryb opcjonalny nieaktywny — zachowano null.',
          ),
          model: null,
        );
      }
      final model = UciParacyclingTandemHandbikeModel.createDefaultWorldCupSeason(
        seasonYear: seasonYear,
        teamName: teamName,
      );
      payload[section.jsonKey] = model.toJson();
      actions.add(
        V9MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason:
              'Zainicjalizowano opcjonalny Puchar Świata UCI Para-Cycling.',
          appliedValueSummary:
              'zawodnicy=${model.athletes.length}, zawody=${model.events.length}',
        ),
      );
      return _OptionalSectionResult(
        summary: Package9SectionSummary(
          section: section,
          presentBefore: false,
          validAfter: true,
          recordsCount: model.athletes.length + model.events.length,
          issuesFixedCount: 1,
          note:
              'Utworzono sezon Para-Cycling (${model.athletes.length} zawodników).',
        ),
        model: model,
      );
    }

    if (raw is! Map<String, dynamic>) {
      final repaired =
          UciParacyclingTandemHandbikeModel.createDefaultWorldCupSeason(
        seasonYear: seasonYear,
        teamName: teamName,
      );
      payload[section.jsonKey] = repaired.toJson();
      actions.add(
        V9MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason:
              'Uszkodzony obiekt UCI Para-Cycling — przywrócono domyślny sezon.',
          appliedValueSummary: 'sezon=$seasonYear',
          wasRepaired: true,
        ),
      );
      return _OptionalSectionResult(
        summary: Package9SectionSummary(
          section: section,
          presentBefore: true,
          validAfter: true,
          recordsCount: repaired.athletes.length,
          issuesFixedCount: 1,
          note: 'Naprawiono uszkodzone dane UCI Para-Cycling.',
        ),
        model: repaired,
      );
    }

    int issuesFixed = 0;
    UciParacyclingTandemHandbikeModel parsed;
    try {
      parsed = UciParacyclingTandemHandbikeModel.fromJson(raw);
    } catch (_) {
      parsed = UciParacyclingTandemHandbikeModel.createDefaultWorldCupSeason(
        seasonYear: seasonYear,
        teamName: teamName,
      );
      issuesFixed++;
      actions.add(
        V9MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason: 'Niekompletny zapis UCI Para-Cycling — odbudowano sezon.',
          appliedValueSummary: 'sezon=$seasonYear',
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
          V9MigrationFieldAction(
            jsonPath: section.jsonKey,
            section: section,
            reason: 'Znormalizowano dane klas B, H1–H5 i C1–C5 Para-Cycling.',
            appliedValueSummary: 'zawodnicy=${parsed.athletes.length}',
          ),
        );
      }
    }

    return _OptionalSectionResult(
      summary: Package9SectionSummary(
        section: section,
        presentBefore: presentBefore,
        validAfter: true,
        recordsCount: parsed.athletes.length + parsed.events.length,
        issuesFixedCount: issuesFixed,
        note:
            'Zawodnicy: ${parsed.athletes.length}, wyścigi: ${parsed.events.length}.',
      ),
      model: parsed,
    );
  }

  // ---------------------------------------------------------------------------
  // 6. NUMERY SERYJNE RAM I MUZEUM KLUBOWE
  // ---------------------------------------------------------------------------
  static _SectionResult<EquipmentWindTunnelDecalsState>
      _migrateEquipmentCustomDecalsAndSerials({
    required Map<String, dynamic> payload,
    required List<V9MigrationFieldAction> actions,
  }) {
    const section = Package9MigrationSection.equipmentCustomDecalsAndSerials;
    final raw = payload[section.jsonKey];
    final bool presentBefore = raw != null;
    int issuesFixed = 0;

    EquipmentWindTunnelDecalsState defaultState() {
      return const EquipmentWindTunnelDecalsState(
        frames: [],
        nextSequenceCounter: 1,
        availableBudgetEur: 450000.0,
      );
    }

    if (raw == null) {
      final initial = defaultState();
      payload[section.jsonKey] = initial.toJson();
      actions.add(
        V9MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason:
              'Brak rejestru numerów seryjnych ram — utworzono pusty rejestr muzeum.',
          appliedValueSummary: 'ramy=0, budżet=450000 EUR',
        ),
      );
      return _SectionResult(
        summary: const Package9SectionSummary(
          section: section,
          presentBefore: false,
          validAfter: true,
          recordsCount: 0,
          issuesFixedCount: 1,
          note: 'Zainicjalizowano rejestr numerów seryjnych i kalkomanii.',
        ),
        model: initial,
      );
    }

    if (raw is! Map<String, dynamic>) {
      final repaired = defaultState();
      payload[section.jsonKey] = repaired.toJson();
      actions.add(
        V9MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason: 'Uszkodzony rejestr numerów seryjnych ram — przywrócono pusty.',
          appliedValueSummary: 'ramy=0',
          wasRepaired: true,
        ),
      );
      return _SectionResult(
        summary: const Package9SectionSummary(
          section: section,
          presentBefore: true,
          validAfter: true,
          recordsCount: 0,
          issuesFixedCount: 1,
          note: 'Naprawiono uszkodzony rejestr ram seryjnych.',
        ),
        model: repaired,
      );
    }

    EquipmentWindTunnelDecalsState parsed =
        EquipmentWindTunnelDecalsState.fromJson(raw);

    final int safeCounter = parsed.nextSequenceCounter < parsed.frames.length + 1
        ? parsed.frames.length + 1
        : parsed.nextSequenceCounter;
    final double safeBudget =
        parsed.availableBudgetEur < 0 ? 0.0 : parsed.availableBudgetEur;

    if (safeCounter != parsed.nextSequenceCounter ||
        safeBudget != parsed.availableBudgetEur) {
      parsed = parsed.copyWith(
        nextSequenceCounter: safeCounter,
        availableBudgetEur: safeBudget,
      );
      issuesFixed++;
      actions.add(
        V9MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason:
              'Skorygowano licznik numerów seryjnych lub ujemny budżet kalkomanii.',
          appliedValueSummary: 'nextSeq=$safeCounter',
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
          V9MigrationFieldAction(
            jsonPath: section.jsonKey,
            section: section,
            reason: 'Znormalizowano rejestr numerów seryjnych ram.',
            appliedValueSummary: 'ramy=${parsed.frames.length}',
          ),
        );
      }
    }

    return _SectionResult(
      summary: Package9SectionSummary(
        section: section,
        presentBefore: presentBefore,
        validAfter: true,
        recordsCount: parsed.frames.length,
        issuesFixedCount: issuesFixed,
        note: 'Zarejestrowane ramy: ${parsed.frames.length}.',
      ),
      model: parsed,
    );
  }

  // ---------------------------------------------------------------------------
  // 7. STYLE TAKTYCZNE 52 DYREKTORÓW SPORTOWYCH AI
  // ---------------------------------------------------------------------------
  static _SectionResult<AiDirectorSportifTacticalStylesState>
      _migrateAiDirectorSportifStyles({
    required Map<String, dynamic> payload,
    required String teamId,
    required List<V9MigrationFieldAction> actions,
  }) {
    const section = Package9MigrationSection.aiDirectorSportifStyles;
    final raw = payload[section.jsonKey];
    final bool presentBefore = raw != null;
    int issuesFixed = 0;

    if (raw == null) {
      final initial = AiDirectorSportifTacticalStylesState.initial(
        playerTeamId: teamId,
      );
      payload[section.jsonKey] = initial.toJson();
      actions.add(
        V9MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason:
              'Brak konfiguracji stylów 52 dyrektorów sportowych AI — utworzono profil bazowy.',
          appliedValueSummary: 'playerTeamId=$teamId',
        ),
      );
      return _SectionResult(
        summary: Package9SectionSummary(
          section: section,
          presentBefore: false,
          validAfter: true,
          recordsCount: initial.aiProfiles.length,
          issuesFixedCount: 1,
          note: 'Aktywowano ${initial.aiProfiles.length} profili taktycznych DS AI.',
        ),
        model: initial,
      );
    }

    if (raw is! Map<String, dynamic>) {
      final repaired = AiDirectorSportifTacticalStylesState.initial(
        playerTeamId: teamId,
      );
      payload[section.jsonKey] = repaired.toJson();
      actions.add(
        V9MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason:
              'Uszkodzona konfiguracja stylów taktycznych DS AI — przywrócono stan domyślny.',
          appliedValueSummary: 'playerTeamId=$teamId',
          wasRepaired: true,
        ),
      );
      return _SectionResult(
        summary: Package9SectionSummary(
          section: section,
          presentBefore: true,
          validAfter: true,
          recordsCount: repaired.aiProfiles.length,
          issuesFixedCount: 1,
          note: 'Naprawiono uszkodzone style taktyczne DS AI.',
        ),
        model: repaired,
      );
    }

    AiDirectorSportifTacticalStylesState parsed;
    try {
      parsed = AiDirectorSportifTacticalStylesState.fromJson(raw);
    } catch (_) {
      parsed = AiDirectorSportifTacticalStylesState.initial(
        playerTeamId: teamId,
      );
      issuesFixed++;
      actions.add(
        V9MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason: 'Błąd parsowania stylów DS AI — przywrócono profil domyślny.',
          appliedValueSummary: 'playerTeamId=$teamId',
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
          V9MigrationFieldAction(
            jsonPath: section.jsonKey,
            section: section,
            reason: 'Znormalizowano nadpisania stylów taktycznych DS AI.',
            appliedValueSummary:
                'nadpisania=${parsed.customOverrides.length}',
          ),
        );
      }
    }

    return _SectionResult(
      summary: Package9SectionSummary(
        section: section,
        presentBefore: presentBefore,
        validAfter: true,
        recordsCount: parsed.aiProfiles.length,
        issuesFixedCount: issuesFixed,
        note:
            'Profile AI: ${parsed.aiProfiles.length}, nadpisania: ${parsed.customOverrides.length}.',
      ),
      model: parsed,
    );
  }

  // ---------------------------------------------------------------------------
  // 8. TYGODNIOWE MIKROCYKLE TRENINGOWE (TSS/TSB)
  // ---------------------------------------------------------------------------
  static _MicrocyclesResult _migrateTrainingMicrocycles({
    required Map<String, dynamic> payload,
    required List<V9MigrationFieldAction> actions,
  }) {
    const section = Package9MigrationSection.trainingMicrocycles;
    final raw = payload[section.jsonKey];
    final bool presentBefore = raw != null;
    int issuesFixed = 0;

    if (raw == null) {
      payload[section.jsonKey] = <String, dynamic>{
        'microcycles': const <Map<String, dynamic>>[],
        'activeMicrocycleId': null,
      };
      actions.add(
        V9MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason:
              'Brak zapisanych mikrocykli treningowych — utworzono pusty rejestr planera.',
          appliedValueSummary: 'mikrocykle=0',
        ),
      );
      return const _MicrocyclesResult(
        summary: Package9SectionSummary(
          section: section,
          presentBefore: false,
          validAfter: true,
          recordsCount: 0,
          issuesFixedCount: 1,
          note: 'Zainicjalizowano rejestr mikrocykli treningowych.',
        ),
        microcycles: [],
      );
    }

    if (raw is! Map<String, dynamic>) {
      payload[section.jsonKey] = <String, dynamic>{
        'microcycles': const <Map<String, dynamic>>[],
        'activeMicrocycleId': null,
      };
      actions.add(
        V9MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason: 'Uszkodzona struktura mikrocykli treningowych — zresetowano.',
          appliedValueSummary: 'mikrocykle=0',
          wasRepaired: true,
        ),
      );
      return const _MicrocyclesResult(
        summary: Package9SectionSummary(
          section: section,
          presentBefore: true,
          validAfter: true,
          recordsCount: 0,
          issuesFixedCount: 1,
          note: 'Naprawiono uszkodzony planer mikrocykli treningowych.',
        ),
        microcycles: [],
      );
    }

    final microcycles = <WeeklyTrainingMicrocycle>[];
    final rawList = raw['microcycles'];
    if (rawList is List) {
      for (final item in rawList) {
        if (item is Map<String, dynamic>) {
          try {
            microcycles.add(WeeklyTrainingMicrocycle.fromJson(item));
          } catch (_) {
            issuesFixed++;
          }
        } else {
          issuesFixed++;
        }
      }
    } else if (rawList != null) {
      issuesFixed++;
    }

    final String? activeId = raw['activeMicrocycleId'] is String
        ? raw['activeMicrocycleId'] as String
        : null;

    final normalized = <String, dynamic>{
      'microcycles': microcycles.map((m) => m.toJson()).toList(),
      'activeMicrocycleId': activeId,
    };

    if (jsonEncode(raw) != jsonEncode(normalized)) {
      payload[section.jsonKey] = normalized;
      if (issuesFixed == 0) {
        issuesFixed++;
      }
      actions.add(
        V9MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason: 'Znormalizowano listę tygodniowych mikrocykli treningowych.',
          appliedValueSummary: 'mikrocykle=${microcycles.length}',
          wasRepaired: rawList is! List && rawList != null,
        ),
      );
    }

    return _MicrocyclesResult(
      summary: Package9SectionSummary(
        section: section,
        presentBefore: presentBefore,
        validAfter: true,
        recordsCount: microcycles.length,
        issuesFixedCount: issuesFixed,
        note: 'Zapisane mikrocykle: ${microcycles.length}.',
      ),
      microcycles: microcycles,
    );
  }

  // ---------------------------------------------------------------------------
  // 9. GLOBAL YOUNG TALENT COMBINE (OBÓZ JUNIORÓW)
  // ---------------------------------------------------------------------------
  static _CombineResult _migrateYouthTalentCombine({
    required Map<String, dynamic> payload,
    required int seasonYear,
    required bool initializeIfMissing,
    required List<V9MigrationFieldAction> actions,
  }) {
    const section = Package9MigrationSection.youthTalentCombine;
    final raw = payload[section.jsonKey];
    final bool presentBefore = raw != null;
    int issuesFixed = 0;

    if (raw == null) {
      final CombineCampEdition? edition = initializeIfMissing
          ? const YouthTalentSummerCombineCampService().launchAnnualCombine(
              seasonYear: seasonYear,
              location: CombineCampLocation.aigleUciWcc,
            )
          : null;
      payload[section.jsonKey] = <String, dynamic>{
        'activeEdition': edition?.toJson(),
        'history': const <Map<String, dynamic>>[],
      };
      actions.add(
        V9MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason: initializeIfMissing
              ? 'Utworzono edycję obozu Global Young Talent Combine.'
              : 'Utworzono strukturę archiwum obozu talentów Combine.',
          appliedValueSummary: edition == null
              ? 'edycja=null, historia=0'
              : 'kandydaci=${edition.candidates.length}',
        ),
      );
      return _CombineResult(
        summary: Package9SectionSummary(
          section: section,
          presentBefore: false,
          validAfter: true,
          recordsCount: edition?.candidates.length ?? 0,
          issuesFixedCount: 1,
          note: edition == null
              ? 'Przygotowano archiwum obozu Combine.'
              : 'Wygenerowano obóz Combine (${edition.candidates.length} talentów).',
        ),
        edition: edition,
        history: const [],
      );
    }

    if (raw is! Map<String, dynamic>) {
      payload[section.jsonKey] = <String, dynamic>{
        'activeEdition': null,
        'history': const <Map<String, dynamic>>[],
      };
      actions.add(
        V9MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason: 'Uszkodzona struktura Global Young Talent Combine — zresetowano.',
          appliedValueSummary: 'edycja=null, historia=0',
          wasRepaired: true,
        ),
      );
      return const _CombineResult(
        summary: Package9SectionSummary(
          section: section,
          presentBefore: true,
          validAfter: true,
          recordsCount: 0,
          issuesFixedCount: 1,
          note: 'Naprawiono uszkodzone dane obozu Combine.',
        ),
        edition: null,
        history: [],
      );
    }

    CombineCampEdition? edition;
    final rawEdition = raw['activeEdition'];
    if (rawEdition is Map<String, dynamic>) {
      try {
        edition = CombineCampEdition.fromJson(rawEdition);
      } catch (_) {
        issuesFixed++;
      }
    } else if (rawEdition != null) {
      issuesFixed++;
    }

    final history = <CombineCampHistoryEntry>[];
    final rawHistory = raw['history'];
    if (rawHistory is List) {
      for (final item in rawHistory) {
        if (item is Map<String, dynamic>) {
          history.add(CombineCampHistoryEntry.fromJson(item));
        } else {
          issuesFixed++;
        }
      }
    } else if (rawHistory != null) {
      issuesFixed++;
    }

    final normalized = <String, dynamic>{
      'activeEdition': edition?.toJson(),
      'history': history.map((h) => h.toJson()).toList(),
    };

    if (jsonEncode(raw) != jsonEncode(normalized)) {
      payload[section.jsonKey] = normalized;
      if (issuesFixed == 0) {
        issuesFixed++;
      }
      actions.add(
        V9MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason: 'Znormalizowano dane obozu Global Young Talent Combine.',
          appliedValueSummary:
              'kandydaci=${edition?.candidates.length ?? 0}, historia=${history.length}',
          wasRepaired: rawEdition != null && edition == null,
        ),
      );
    }

    return _CombineResult(
      summary: Package9SectionSummary(
        section: section,
        presentBefore: presentBefore,
        validAfter: true,
        recordsCount: (edition?.candidates.length ?? 0) + history.length,
        issuesFixedCount: issuesFixed,
        note:
            'Kandydaci: ${edition?.candidates.length ?? 0}, edycje archiwalne: ${history.length}.',
      ),
      edition: edition,
      history: history,
    );
  }

  // ---------------------------------------------------------------------------
  // 10. ANALITYKA BI KARIERY I EKSPORT CSV/JSON
  // ---------------------------------------------------------------------------
  static _AnalyticsResult _migrateDeepCareerAnalyticsBi({
    required Map<String, dynamic> payload,
    required List<V9MigrationFieldAction> actions,
  }) {
    const section = Package9MigrationSection.deepCareerAnalyticsBi;
    final raw = payload[section.jsonKey];
    final bool presentBefore = raw != null;
    int issuesFixed = 0;

    const defaultConfig = CareerAnalyticsExportConfig();

    if (raw == null) {
      payload[section.jsonKey] = <String, dynamic>{
        'exportConfig': defaultConfig.toJson(),
        'seasonSnapshots': const <Map<String, dynamic>>[],
      };
      actions.add(
        V9MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason:
              'Brak konfiguracji analityki BI kariery — utworzono domyślne ustawienia eksportu.',
          appliedValueSummary: 'format=csvAndJsonBundle, migawki=0',
        ),
      );
      return const _AnalyticsResult(
        summary: Package9SectionSummary(
          section: section,
          presentBefore: false,
          validAfter: true,
          recordsCount: 0,
          issuesFixedCount: 1,
          note: 'Zainicjalizowano konfigurację BI i historię sezonów.',
        ),
        config: defaultConfig,
        snapshots: [],
      );
    }

    if (raw is! Map<String, dynamic>) {
      payload[section.jsonKey] = <String, dynamic>{
        'exportConfig': defaultConfig.toJson(),
        'seasonSnapshots': const <Map<String, dynamic>>[],
      };
      actions.add(
        V9MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason: 'Uszkodzona struktura analityki BI — przywrócono domyślną.',
          appliedValueSummary: 'format=csvAndJsonBundle',
          wasRepaired: true,
        ),
      );
      return const _AnalyticsResult(
        summary: Package9SectionSummary(
          section: section,
          presentBefore: true,
          validAfter: true,
          recordsCount: 0,
          issuesFixedCount: 1,
          note: 'Naprawiono uszkodzoną sekcję analityki BI.',
        ),
        config: defaultConfig,
        snapshots: [],
      );
    }

    CareerAnalyticsExportConfig config = defaultConfig;
    final rawConfig = raw['exportConfig'];
    if (rawConfig is Map<String, dynamic>) {
      config = CareerAnalyticsExportConfig.fromJson(rawConfig);
    } else {
      issuesFixed++;
    }

    final snapshots = <SeasonAnalyticsSnapshot>[];
    final rawSnapshots = raw['seasonSnapshots'];
    if (rawSnapshots is List) {
      for (final item in rawSnapshots) {
        if (item is Map<String, dynamic>) {
          try {
            snapshots.add(SeasonAnalyticsSnapshot.fromJson(item));
          } catch (_) {
            issuesFixed++;
          }
        } else {
          issuesFixed++;
        }
      }
    } else if (rawSnapshots != null) {
      issuesFixed++;
    }

    final normalized = <String, dynamic>{
      'exportConfig': config.toJson(),
      'seasonSnapshots': snapshots.map((s) => s.toJson()).toList(),
    };

    if (jsonEncode(raw) != jsonEncode(normalized)) {
      payload[section.jsonKey] = normalized;
      if (issuesFixed == 0) {
        issuesFixed++;
      }
      actions.add(
        V9MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason: 'Znormalizowano konfigurację BI oraz migawki sezonów.',
          appliedValueSummary: 'migawki=${snapshots.length}',
          wasRepaired: rawConfig is! Map<String, dynamic>,
        ),
      );
    }

    return _AnalyticsResult(
      summary: Package9SectionSummary(
        section: section,
        presentBefore: presentBefore,
        validAfter: true,
        recordsCount: snapshots.length,
        issuesFixedCount: issuesFixed,
        note: 'Migawki sezonowe BI: ${snapshots.length}.',
      ),
      config: config,
      snapshots: snapshots,
    );
  }

  // ---------------------------------------------------------------------------
  // POMOCNICZE METODY EKSTRAKCJI
  // ---------------------------------------------------------------------------
  static int _extractSeasonYear(Map<String, dynamic> payload, DateTime now) {
    final direct = (payload['seasonYear'] as num?)?.toInt() ??
        (payload['currentYear'] as num?)?.toInt();
    if (direct != null && direct >= 1970 && direct <= 2150) {
      return direct;
    }
    return now.year;
  }

  static String? _extractString(
    Map<String, dynamic> payload,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = payload[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }
}

class _SectionResult<T> {
  final Package9SectionSummary summary;
  final T model;

  const _SectionResult({required this.summary, required this.model});
}

class _OptionalSectionResult<T> {
  final Package9SectionSummary summary;
  final T? model;

  const _OptionalSectionResult({required this.summary, required this.model});
}

class _BondingResult {
  final Package9SectionSummary summary;
  final List<TeamBondingHistoryEntry> entries;

  const _BondingResult({required this.summary, required this.entries});
}

class _MicrocyclesResult {
  final Package9SectionSummary summary;
  final List<WeeklyTrainingMicrocycle> microcycles;

  const _MicrocyclesResult({
    required this.summary,
    required this.microcycles,
  });
}

class _CombineResult {
  final Package9SectionSummary summary;
  final CombineCampEdition? edition;
  final List<CombineCampHistoryEntry> history;

  const _CombineResult({
    required this.summary,
    required this.edition,
    required this.history,
  });
}

class _AnalyticsResult {
  final Package9SectionSummary summary;
  final CareerAnalyticsExportConfig config;
  final List<SeasonAnalyticsSnapshot> snapshots;

  const _AnalyticsResult({
    required this.summary,
    required this.config,
    required this.snapshots,
  });
}

// =============================================================================
// STAN I NOTIFIER RIVERPOD DLA MIGRATORA V9
// =============================================================================

@immutable
class SaveCompatibilityV9State {
  final bool isRunning;
  final bool initializeOptionalModesIfMissing;
  final Package9MigrationSection? activeFilter;
  final SaveCompatibilityV9Report? lastReport;

  const SaveCompatibilityV9State({
    this.isRunning = false,
    this.initializeOptionalModesIfMissing = false,
    this.activeFilter,
    this.lastReport,
  });

  SaveCompatibilityV9State copyWith({
    bool? isRunning,
    bool? initializeOptionalModesIfMissing,
    Package9MigrationSection? activeFilter,
    bool clearFilter = false,
    SaveCompatibilityV9Report? lastReport,
  }) {
    return SaveCompatibilityV9State(
      isRunning: isRunning ?? this.isRunning,
      initializeOptionalModesIfMissing: initializeOptionalModesIfMissing ??
          this.initializeOptionalModesIfMissing,
      activeFilter: clearFilter ? null : (activeFilter ?? this.activeFilter),
      lastReport: lastReport ?? this.lastReport,
    );
  }
}

class SaveCompatibilityV9Notifier
    extends StateNotifier<SaveCompatibilityV9State> {
  SaveCompatibilityV9Notifier() : super(const SaveCompatibilityV9State());

  void toggleInitializeOptionalModes(bool value) {
    state = state.copyWith(initializeOptionalModesIfMissing: value);
  }

  void setSectionFilter(Package9MigrationSection? section) {
    if (section == null || state.activeFilter == section) {
      state = state.copyWith(clearFilter: true);
    } else {
      state = state.copyWith(activeFilter: section);
    }
  }

  SaveCompatibilityV9Report runMigrationOnRawJson({
    required String saveId,
    required String rawJson,
  }) {
    state = state.copyWith(isRunning: true);
    final report = SaveCompatibilityV9Migrator.migrateRawJson(
      saveId: saveId,
      rawJson: rawJson,
      initializeOptionalModesIfMissing: state.initializeOptionalModesIfMissing,
    );
    state = state.copyWith(isRunning: false, lastReport: report);
    return report;
  }

  SaveCompatibilityV9Report runMigrationOnPayload({
    required String saveId,
    required Map<String, dynamic> payload,
    int sourceSchemaVersion = 8,
  }) {
    state = state.copyWith(isRunning: true);
    final report = SaveCompatibilityV9Migrator.migratePayloadMap(
      saveId: saveId,
      payload: payload,
      sourceSchemaVersion: sourceSchemaVersion,
      initializeOptionalModesIfMissing: state.initializeOptionalModesIfMissing,
    );
    state = state.copyWith(isRunning: false, lastReport: report);
    return report;
  }
}

/// Globalny provider migratora kompatybilności v9 (Paczka #9).
final saveCompatibilityV9Provider = StateNotifierProvider<
    SaveCompatibilityV9Notifier, SaveCompatibilityV9State>(
  (ref) => SaveCompatibilityV9Notifier(),
);

// =============================================================================
// RESPONSYWNY PANEL UI MIGRATORA V9 (LayoutBuilder 390x844 / 1024x768 / 1600x900)
// =============================================================================

/// Responsywny panel diagnostyczny migratora zapisów v9 dla Paczki #9.
class SaveCompatibilityV9MigratorPanel extends ConsumerWidget {
  final String saveId;
  final String? sampleRawJson;
  final Map<String, dynamic>? samplePayload;
  final int sampleSourceSchemaVersion;
  final VoidCallback? onMigrationCompleted;

  const SaveCompatibilityV9MigratorPanel({
    super.key,
    this.saveId = 'active_career_slot',
    this.sampleRawJson,
    this.samplePayload,
    this.sampleSourceSchemaVersion = 8,
    this.onMigrationCompleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(saveCompatibilityV9Provider);
    final notifier = ref.read(saveCompatibilityV9Provider.notifier);

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

  Widget _buildHeader(SaveCompatibilityV9State state, bool isCompact) {
    final statusColor = state.lastReport?.status.color ?? AppColors.goldAccent;
    final statusText =
        state.lastReport?.status.labelPl ?? 'OCZEKUJE NA WERYFIKACJĘ V9';

    return Wrap(
      spacing: 12,
      runSpacing: 10,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder, width: 1),
              ),
              child: const Icon(
                Icons.upgrade_rounded,
                color: AppColors.goldAccent,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Migrator Zapisów v9 (Paczka #9)',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: isCompact ? 15 : 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Kompatybilność wsteczna v1–v8 → schemat v9',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: statusColor.withValues(alpha: 0.45),
              width: 1,
            ),
          ),
          child: Text(
            statusText,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: statusColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlsBar({
    required SaveCompatibilityV9State state,
    required SaveCompatibilityV9Notifier notifier,
    required bool isCompact,
  }) {
    final toggleControl = _V9InteractiveToggleChip(
      label: 'Inicjalizuj tryby opcjonalne (Para-Cycling / Combine)',
      value: state.initializeOptionalModesIfMissing,
      enabled: !state.isRunning,
      onChanged: notifier.toggleInitializeOptionalModes,
    );

    final runButton = _V9PrimaryActionButton(
      label: state.isRunning ? 'Migracja w toku...' : 'Uruchom Migrację v9',
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
                  'teamId': 'team_polonia_orlen',
                  'teamName': 'Polonia Orlen Pro',
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
          toggleControl,
          const SizedBox(height: 10),
          runButton,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: toggleControl),
        const SizedBox(width: 12),
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
        border: Border.all(color: AppColors.cardBorder, width: 1),
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
              'Uruchom migrator, aby zweryfikować i uzupełnić struktury Paczki #9 '
              '(Ekspansja UCI, Sponsorzy Wschodzący, Psychologia Szatni 2.0, '
              'Para-Cycling, Style DS AI, Mikrocykle, Talent Combine i BI).',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportBanner(SaveCompatibilityV9Report report, bool isCompact) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: report.status.color.withValues(alpha: 0.45),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            report.summaryMessage,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _metaPill(
                'Schemat',
                'v${report.sourceSchemaVersion} → v${report.targetSchemaVersion}',
              ),
              _metaPill('Poprawki', '${report.totalFixesCount}'),
              _metaPill('Naprawy', '${report.repairedFixesCount}'),
              _metaPill(
                'Suma kontrolna',
                report.checksumAfter.isEmpty
                    ? 'brak'
                    : '${report.checksumAfter.substring(0, report.checksumAfter.length.clamp(0, 12))}…',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metaPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontFeatures: [FontFeature.tabularFigures()],
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildSectionsGrid({
    required SaveCompatibilityV9Report report,
    required SaveCompatibilityV9State state,
    required SaveCompatibilityV9Notifier notifier,
    required bool isCompact,
    required bool isWide,
  }) {
    final int columns = isCompact ? 1 : (isWide ? 2 : 2);
    final summaries = report.sectionSummaries;

    if (columns == 1) {
      return Column(
        children: [
          for (final s in summaries) ...[
            _V9SectionSummaryCard(
              summary: s,
              selected: state.activeFilter == s.section,
              onTap: () => notifier.setSectionFilter(s.section),
            ),
            const SizedBox(height: 8),
          ],
        ],
      );
    }

    final rows = <Widget>[];
    for (var i = 0; i < summaries.length; i += 2) {
      final left = summaries[i];
      final right = i + 1 < summaries.length ? summaries[i + 1] : null;
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _V9SectionSummaryCard(
                  summary: left,
                  selected: state.activeFilter == left.section,
                  onTap: () => notifier.setSectionFilter(left.section),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: right == null
                    ? const SizedBox.shrink()
                    : _V9SectionSummaryCard(
                        summary: right,
                        selected: state.activeFilter == right.section,
                        onTap: () => notifier.setSectionFilter(right.section),
                      ),
              ),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _buildActionsLog(
    SaveCompatibilityV9Report report,
    Package9MigrationSection? filter,
  ) {
    final filtered = filter == null
        ? report.actions
        : report.actions.where((a) => a.section == filter).toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            filter == null
                ? 'Dziennik migracji v9 (${filtered.length})'
                : 'Dziennik sekcji: ${filter.labelPl} (${filtered.length})',
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
              'Brak wymaganych modyfikacji dla wybranego filtra.',
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
                          : Icons.check_circle_outline_rounded,
                      size: 15,
                      color: action.wasRepaired
                          ? AppColors.amberWarning
                          : AppColors.statusSuccess,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '[${action.jsonPath}] ${action.reason} (${action.appliedValueSummary})',
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

class _V9InteractiveToggleChip extends StatefulWidget {
  final String label;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _V9InteractiveToggleChip({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  State<_V9InteractiveToggleChip> createState() =>
      _V9InteractiveToggleChipState();
}

class _V9InteractiveToggleChipState extends State<_V9InteractiveToggleChip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.enabled ? () => widget.onChanged(!widget.value) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: !widget.enabled
                ? AppColors.background.withValues(alpha: 0.5)
                : _pressed
                    ? AppColors.surfaceLight
                    : (_hovered
                        ? AppColors.surfaceLight.withValues(alpha: 0.8)
                        : AppColors.background),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focused
                  ? AppColors.goldAccent
                  : widget.value
                      ? AppColors.goldAccent.withValues(alpha: 0.6)
                      : AppColors.cardBorder,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.value
                    ? Icons.check_box_rounded
                    : Icons.check_box_outline_blank_rounded,
                size: 18,
                color: widget.value
                    ? AppColors.goldAccent
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: widget.enabled
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

class _V9PrimaryActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  const _V9PrimaryActionButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_V9PrimaryActionButton> createState() => _V9PrimaryActionButtonState();
}

class _V9PrimaryActionButtonState extends State<_V9PrimaryActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bg = !widget.enabled
        ? AppColors.surfaceLight
        : _pressed
            ? AppColors.primaryAccent.withValues(alpha: 0.82)
            : _hovered
                ? AppColors.primaryAccent.withValues(alpha: 0.92)
                : AppColors.primaryAccent;

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
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
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focused ? AppColors.goldAccent : AppColors.cardBorder,
              width: 1,
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

class _V9SectionSummaryCard extends StatefulWidget {
  final Package9SectionSummary summary;
  final bool selected;
  final VoidCallback onTap;

  const _V9SectionSummaryCard({
    required this.summary,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_V9SectionSummaryCard> createState() => _V9SectionSummaryCardState();
}

class _V9SectionSummaryCardState extends State<_V9SectionSummaryCard> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.summary;
    final Color statusColor = !s.validAfter
        ? AppColors.crimsonAlert
        : (s.issuesFixedCount > 0
            ? AppColors.accentBlue
            : AppColors.statusSuccess);

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
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
