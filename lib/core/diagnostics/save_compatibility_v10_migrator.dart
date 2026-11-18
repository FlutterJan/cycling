// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/broadcast/tv_director_live_production_model.dart';
import '../../models/medical/grand_tour_nightly_hrv_and_physio_model.dart';
import '../../models/race/americas_and_oceania_tours_model.dart';
import '../../models/uci/technical_scrutiny_and_cas_tribunal_model.dart';
import '../../services/career/historical_grand_tour_winners_timeline_db.dart';
import '../../services/database/database_backup_and_integrity_repair.dart';
import '../theme/app_colors.dart';
import 'save_compatibility_v9_migrator.dart';

/// Sekcje danych wprowadzone w Paczce #10 (#663–#712) objęte migracją v10.
enum Package10MigrationSection {
  americasAndOceaniaTours(
    'Ekspansja UCI: Ameryki i Oceania',
    'americasAndOceaniaTours',
    'Ekspansja #663',
    Icons.public_rounded,
  ),
  technicalScrutinyAndCasTribunal(
    'Kontrole Techniczne UCI X-Ray i Trybunał CAS',
    'technicalScrutinyAndCasTribunal',
    'UCI & CAS #666',
    Icons.qr_code_scanner_rounded,
  ),
  grandTourNightlyHrvAndPhysio(
    'Nocne HRV, CK i Fizjoterapia Grand Tour',
    'grandTourNightlyHrvAndPhysio',
    'Fizjologia #669',
    Icons.monitor_heart_rounded,
  ),
  tvDirectorLiveProduction(
    'Tryb Reżysera Transmisji TV (12 Kamer)',
    'tvDirectorLiveProduction',
    'TV Director #672',
    Icons.live_tv_rounded,
  ),
  tripleCrownWinnersTimelineDb(
    'Baza Potrójnej Korony i Zwycięzców GT',
    'tripleCrownWinnersTimelineDb',
    'Potrójna Korona #698',
    Icons.emoji_events_rounded,
  );

  final String labelPl;
  final String jsonKey;
  final String packageTag;
  final IconData icon;

  const Package10MigrationSection(
    this.labelPl,
    this.jsonKey,
    this.packageTag,
    this.icon,
  );
}

/// Wynikowy status migracji zapisu do schematu v10 (Paczka #10).
enum V10MigrationStatus {
  alreadyCompatible('ZGODNY Z V10 (PACZKA #10)', AppColors.statusSuccess),
  migrated('ZMIGROWANY DO V10', AppColors.accentBlue),
  repairedAndMigrated('NAPRAWIONY I ZMIGROWANY DO V10', AppColors.amberWarning),
  failed('BŁĄD MIGRACJI V10', AppColors.crimsonAlert);

  final String labelPl;
  final Color color;

  const V10MigrationStatus(this.labelPl, this.color);

  bool get isSuccess => this != V10MigrationStatus.failed;
}

/// Pojedyncza akcja uzupełnienia, normalizacji lub naprawy pola podczas migracji v10.
@immutable
class V10MigrationFieldAction {
  final String jsonPath;
  final Package10MigrationSection? section;
  final String reason;
  final String appliedValueSummary;
  final bool wasRepaired;

  const V10MigrationFieldAction({
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

/// Podsumowanie stanu pojedynczej sekcji Paczki #10 po przejściu migracji v10.
@immutable
class Package10SectionSummary {
  final Package10MigrationSection section;
  final bool presentBefore;
  final bool validAfter;
  final int recordsCount;
  final int issuesFixedCount;
  final String note;

  const Package10SectionSummary({
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

/// Pełny raport migracji kompatybilności zapisu gry do schematu v10 (Paczka #10).
@immutable
class SaveCompatibilityV10Report {
  final String saveId;
  final int sourceSchemaVersion;
  final int targetSchemaVersion;
  final V10MigrationStatus status;
  final DateTime migratedAtUtc;
  final String checksumBefore;
  final String checksumAfter;
  final List<Package10SectionSummary> sectionSummaries;
  final List<V10MigrationFieldAction> actions;
  final SaveCompatibilityV9Report? v9PreMigrationReport;
  final Map<String, dynamic>? migratedPayload;
  final IntegritySaveEnvelope? migratedEnvelope;
  final AmericasAndOceaniaToursModel? hydratedAmericasOceaniaTours;
  final TechnicalScrutinyAndCasTribunalModel? hydratedTechnicalScrutiny;
  final GrandTourNightlyHrvAndPhysioModel? hydratedGrandTourHrvPhysio;
  final TvDirectorLiveProductionModel? hydratedTvDirectorProduction;
  final HistoricalGrandTourWinnersTimelineDb? hydratedTripleCrownTimelineDb;
  final String summaryMessage;
  final String? errorMessage;

  const SaveCompatibilityV10Report({
    required this.saveId,
    required this.sourceSchemaVersion,
    this.targetSchemaVersion = SaveCompatibilityV10Migrator.targetSchemaVersion,
    required this.status,
    required this.migratedAtUtc,
    required this.checksumBefore,
    required this.checksumAfter,
    this.sectionSummaries = const [],
    this.actions = const [],
    this.v9PreMigrationReport,
    this.migratedPayload,
    this.migratedEnvelope,
    this.hydratedAmericasOceaniaTours,
    this.hydratedTechnicalScrutiny,
    this.hydratedGrandTourHrvPhysio,
    this.hydratedTvDirectorProduction,
    this.hydratedTripleCrownTimelineDb,
    required this.summaryMessage,
    this.errorMessage,
  });

  int get totalFixesCount =>
      actions.length + (v9PreMigrationReport?.totalFixesCount ?? 0);

  int get repairedFixesCount =>
      actions.where((a) => a.wasRepaired).length +
      (v9PreMigrationReport?.repairedFixesCount ?? 0);

  Package10SectionSummary? summaryFor(Package10MigrationSection section) {
    for (final s in sectionSummaries) {
      if (s.section == section) return s;
    }
    return null;
  }
}

/// Automatyczny migrator zapisów gry do schematu v10 dla struktur Paczki #10,
/// zachowujący bezstratną kompatybilność wsteczną z zapisami v1–v9.
class SaveCompatibilityV10Migrator {
  static const int targetSchemaVersion = 10;

  /// Migruje surowy JSON pliku zapisu (`IntegritySaveEnvelope` lub surowy `CareerSave`).
  static SaveCompatibilityV10Report migrateRawJson({
    required String saveId,
    required String rawJson,
    bool initializeOptionalModesIfMissing = false,
  }) {
    final now = DateTime.now().toUtc();
    if (rawJson.trim().isEmpty) {
      return SaveCompatibilityV10Report(
        saveId: saveId,
        sourceSchemaVersion: 0,
        status: V10MigrationStatus.failed,
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
          return SaveCompatibilityV10Report(
            saveId: saveId,
            sourceSchemaVersion: 0,
            status: V10MigrationStatus.failed,
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
      return SaveCompatibilityV10Report(
        saveId: saveId,
        sourceSchemaVersion: 0,
        status: V10MigrationStatus.failed,
        migratedAtUtc: now,
        checksumBefore: '',
        checksumAfter: '',
        summaryMessage: 'Nieoczekiwany błąd podczas parsowania zapisu JSON.',
        errorMessage: e.toString(),
      );
    }
  }

  /// Migruje zdekodowaną mapę payloadu `CareerSave` w pamięci do schematu v10.
  static SaveCompatibilityV10Report migratePayloadMap({
    required String saveId,
    required Map<String, dynamic> payload,
    int sourceSchemaVersion = 9,
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
      return SaveCompatibilityV10Report(
        saveId: saveId,
        sourceSchemaVersion: sourceSchemaVersion,
        status: V10MigrationStatus.failed,
        migratedAtUtc: now,
        checksumBefore: '',
        checksumAfter: '',
        summaryMessage: 'Błąd podczas klonowania lub migracji mapy payloadu.',
        errorMessage: e.toString(),
      );
    }
  }

  static SaveCompatibilityV10Report _migratePayloadInternal({
    required String saveId,
    required int sourceSchemaVersion,
    required String checksumBefore,
    required Map<String, dynamic> workingPayload,
    required List<String> existingHistory,
    required bool hadEnvelope,
    required bool initializeOptionalModesIfMissing,
    required DateTime now,
  }) {
    final actions = <V10MigrationFieldAction>[];
    final summaries = <Package10SectionSummary>[];

    // Krok 0: Jeśli zapis jest starszy niż v9, przepuść go najpierw przez SaveCompatibilityV9Migrator.
    SaveCompatibilityV9Report? v9Report;
    Map<String, dynamic> payload = workingPayload;
    if (sourceSchemaVersion < 9) {
      v9Report = SaveCompatibilityV9Migrator.migratePayloadMap(
        saveId: saveId,
        payload: workingPayload,
        sourceSchemaVersion: sourceSchemaVersion,
        initializeOptionalModesIfMissing: initializeOptionalModesIfMissing,
      );
      if (!v9Report.status.isSuccess || v9Report.migratedPayload == null) {
        return SaveCompatibilityV10Report(
          saveId: saveId,
          sourceSchemaVersion: sourceSchemaVersion,
          status: V10MigrationStatus.failed,
          migratedAtUtc: now,
          checksumBefore: checksumBefore,
          checksumAfter: checksumBefore,
          v9PreMigrationReport: v9Report,
          summaryMessage:
              'Nie powiodła się wstępna migracja v$sourceSchemaVersion -> v9.',
          errorMessage: v9Report.errorMessage ?? 'V9_PRE_MIGRATION_FAILED',
        );
      }
      payload = jsonDecode(jsonEncode(v9Report.migratedPayload!))
          as Map<String, dynamic>;
    }

    final int seasonYear = _extractSeasonYear(payload, now);

    // 1. Ekspansja UCI: Ameryki i Oceania
    final americasRes = _migrateAmericasAndOceaniaTours(
      payload: payload,
      seasonYear: seasonYear,
      actions: actions,
    );
    summaries.add(americasRes.summary);

    // 2. Kontrole Techniczne UCI X-Ray i Trybunał CAS
    final scrutinyRes = _migrateTechnicalScrutinyAndCas(
      payload: payload,
      seasonYear: seasonYear,
      now: now,
      actions: actions,
    );
    summaries.add(scrutinyRes.summary);

    // 3. Nocne HRV, CK i Fizjoterapia Grand Tour (moduł opcjonalny poza GT)
    final hrvRes = _migrateGrandTourNightlyHrvAndPhysio(
      payload: payload,
      seasonYear: seasonYear,
      initializeIfMissing: initializeOptionalModesIfMissing,
      actions: actions,
    );
    summaries.add(hrvRes.summary);

    // 4. Tryb Reżysera Transmisji TV (moduł opcjonalny poza transmisją na żywo)
    final tvRes = _migrateTvDirectorLiveProduction(
      payload: payload,
      initializeIfMissing: initializeOptionalModesIfMissing,
      actions: actions,
    );
    summaries.add(tvRes.summary);

    // 5. Baza Potrójnej Korony i Zwycięzców Wielkich Tourów
    final tripleCrownRes = _migrateTripleCrownTimelineDb(
      payload: payload,
      seasonYear: seasonYear,
      actions: actions,
    );
    summaries.add(tripleCrownRes.summary);

    // Aktualizacja wersji schematu payloadu do v10
    final int? payloadSchema = (payload['schemaVersion'] as num?)?.toInt();
    if (payloadSchema != targetSchemaVersion) {
      payload['schemaVersion'] = targetSchemaVersion;
      actions.add(
        const V10MigrationFieldAction(
          jsonPath: 'schemaVersion',
          reason:
              'Podniesiono wersję schematu zapisu do v$targetSchemaVersion.',
          appliedValueSummary: '$targetSchemaVersion',
        ),
      );
    }

    if (payload['saveId'] == null ||
        payload['saveId'].toString().trim().isEmpty) {
      payload['saveId'] = saveId;
      actions.add(
        V10MigrationFieldAction(
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
        (v9Report?.repairedFixesCount ?? 0) > 0;
    final bool anyChanged = actions.isNotEmpty ||
        sourceSchemaVersion < targetSchemaVersion ||
        !hadEnvelope ||
        v9Report != null;

    final V10MigrationStatus status;
    if (anyRepaired) {
      status = V10MigrationStatus.repairedAndMigrated;
    } else if (anyChanged) {
      status = V10MigrationStatus.migrated;
    } else {
      status = V10MigrationStatus.alreadyCompatible;
    }

    final updatedHistory = List<String>.from(existingHistory);
    if (v9Report != null) {
      updatedHistory.addAll(
        v9Report.migratedEnvelope?.migrationHistory ?? const <String>[],
      );
    }
    if (status != V10MigrationStatus.alreadyCompatible) {
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

    final int totalFixes = actions.length + (v9Report?.totalFixesCount ?? 0);

    final String summaryMessage = switch (status) {
      V10MigrationStatus.alreadyCompatible =>
        'Zapis "$saveId" jest w pełni zgodny ze schematem v10 (Paczka #10).',
      V10MigrationStatus.migrated =>
        'Zmigrowano zapis "$saveId" (v$sourceSchemaVersion → v10) z $totalFixes aktualizacjami pól Paczki #10.',
      V10MigrationStatus.repairedAndMigrated =>
        'Naprawiono i zmigrowano zapis "$saveId" (v$sourceSchemaVersion → v10); łącznie $totalFixes poprawek.',
      V10MigrationStatus.failed => 'Migracja v10 nie powiodła się.',
    };

    return SaveCompatibilityV10Report(
      saveId: saveId,
      sourceSchemaVersion: sourceSchemaVersion,
      status: status,
      migratedAtUtc: now,
      checksumBefore: checksumBefore,
      checksumAfter: checksumAfter,
      sectionSummaries: List<Package10SectionSummary>.unmodifiable(summaries),
      actions: List<V10MigrationFieldAction>.unmodifiable(actions),
      v9PreMigrationReport: v9Report,
      migratedPayload: payload,
      migratedEnvelope: migratedEnvelope,
      hydratedAmericasOceaniaTours: americasRes.model,
      hydratedTechnicalScrutiny: scrutinyRes.model,
      hydratedGrandTourHrvPhysio: hrvRes.model,
      hydratedTvDirectorProduction: tvRes.model,
      hydratedTripleCrownTimelineDb: tripleCrownRes.model,
      summaryMessage: summaryMessage,
    );
  }

  // ---------------------------------------------------------------------------
  // 1. EKSPANSJA UCI: AMERYKI I OCEANIA
  // ---------------------------------------------------------------------------
  static _V10SectionResult<AmericasAndOceaniaToursModel>
      _migrateAmericasAndOceaniaTours({
    required Map<String, dynamic> payload,
    required int seasonYear,
    required List<V10MigrationFieldAction> actions,
  }) {
    const section = Package10MigrationSection.americasAndOceaniaTours;
    final raw = payload[section.jsonKey];
    final bool presentBefore = raw != null;
    int issuesFixed = 0;

    if (raw == null) {
      final model = AmericasAndOceaniaToursModel.standard(
        seasonYear: seasonYear,
      );
      payload[section.jsonKey] = model.toJson();
      actions.add(
        V10MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason:
              'Brak danych ekspansji Ameryki i Oceanii — utworzono ${model.races.length} wyścigów kalendarza UCI.',
          appliedValueSummary:
              'sezon=$seasonYear, wyścigi=${model.races.length}',
        ),
      );
      return _V10SectionResult(
        summary: Package10SectionSummary(
          section: section,
          presentBefore: false,
          validAfter: true,
          recordsCount: model.races.length,
          issuesFixedCount: 1,
          note:
              'Zainicjalizowano ${model.races.length} wyścigów (TDU, Cadel Evans, Colombia, San Juan, Québec, Montréal).',
        ),
        model: model,
      );
    }

    if (raw is! Map<String, dynamic>) {
      final repaired = AmericasAndOceaniaToursModel.standard(
        seasonYear: seasonYear,
      );
      payload[section.jsonKey] = repaired.toJson();
      actions.add(
        V10MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason:
              'Uszkodzony typ obiektu AmericasAndOceaniaToursModel — przywrócono stan domyślny.',
          appliedValueSummary: 'zresetowano ${repaired.races.length} wyścigów Ameryk i Oceanii',
          wasRepaired: true,
        ),
      );
      return _V10SectionResult(
        summary: Package10SectionSummary(
          section: section,
          presentBefore: true,
          validAfter: true,
          recordsCount: repaired.races.length,
          issuesFixedCount: 1,
          note: 'Naprawiono uszkodzoną strukturę wyścigów Ameryk i Oceanii.',
        ),
        model: repaired,
      );
    }

    AmericasAndOceaniaToursModel parsed;
    try {
      parsed = AmericasAndOceaniaToursModel.fromJson(raw);
    } catch (_) {
      parsed = AmericasAndOceaniaToursModel.standard(seasonYear: seasonYear);
      issuesFixed++;
      actions.add(
        V10MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason:
              'Niekompletne rekordy wyścigów Ameryk i Oceanii — odbudowano strukturę.',
          appliedValueSummary: 'sezon=$seasonYear',
          wasRepaired: true,
        ),
      );
    }

    final int validSeasonYear = parsed.seasonYear.clamp(1970, 2150);
    final List<AmericasOceaniaRaceDefinition> validRaces = parsed.races.isEmpty
        ? AmericasAndOceaniaToursModel.standard(seasonYear: validSeasonYear)
            .races
        : parsed.races;
    final double clampedPrestige =
        parsed.americasOceaniaPrestigeScore.clamp(0.0, 100.0);
    final double clampedReach =
        parsed.internationalSponsorReachMultiplier.clamp(1.0, 5.0);

    if (validSeasonYear != parsed.seasonYear ||
        parsed.races.isEmpty ||
        clampedPrestige != parsed.americasOceaniaPrestigeScore ||
        clampedReach != parsed.internationalSponsorReachMultiplier) {
      parsed = parsed.copyWith(
        seasonYear: validSeasonYear,
        races: validRaces,
        americasOceaniaPrestigeScore: clampedPrestige,
        internationalSponsorReachMultiplier: clampedReach,
      );
      issuesFixed++;
      actions.add(
        V10MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason:
              'Skorygowano zakresy prestiżu/mnożnika lub pustą listę wyścigów Ameryk i Oceanii.',
          appliedValueSummary:
              'wyścigi=${validRaces.length}, prestiż=${clampedPrestige.toStringAsFixed(1)}',
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
          V10MigrationFieldAction(
            jsonPath: section.jsonKey,
            section: section,
            reason:
                'Znormalizowano strukturę JSON kalendarza Ameryk i Oceanii.',
            appliedValueSummary:
                'wyścigi=${parsed.races.length}, historia=${parsed.participationHistory.length}',
          ),
        );
      }
    }

    return _V10SectionResult(
      summary: Package10SectionSummary(
        section: section,
        presentBefore: presentBefore,
        validAfter: true,
        recordsCount: parsed.races.length + parsed.participationHistory.length,
        issuesFixedCount: issuesFixed,
        note:
            'Wyścigi: ${parsed.races.length}, starty: ${parsed.participationHistory.length}.',
      ),
      model: parsed,
    );
  }

  // ---------------------------------------------------------------------------
  // 2. KONTROLE TECHNICZNE UCI X-RAY I TRYBUNAŁ CAS
  // ---------------------------------------------------------------------------
  static _V10SectionResult<TechnicalScrutinyAndCasTribunalModel>
      _migrateTechnicalScrutinyAndCas({
    required Map<String, dynamic> payload,
    required int seasonYear,
    required DateTime now,
    required List<V10MigrationFieldAction> actions,
  }) {
    const section = Package10MigrationSection.technicalScrutinyAndCasTribunal;
    final raw = payload[section.jsonKey];
    final bool presentBefore = raw != null;
    int issuesFixed = 0;

    if (raw == null) {
      final model = TechnicalScrutinyAndCasTribunalModel.initial(
        seasonYear: seasonYear,
        nowIso: now.toIso8601String(),
      );
      payload[section.jsonKey] = model.toJson();
      actions.add(
        V10MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason:
              'Brak rejestru kontroli technicznych UCI i spraw CAS — zainicjalizowano stan startowy.',
          appliedValueSummary: 'sezon=$seasonYear, zgodność=100.0%',
        ),
      );
      return _V10SectionResult(
        summary: const Package10SectionSummary(
          section: section,
          presentBefore: false,
          validAfter: true,
          recordsCount: 0,
          issuesFixedCount: 1,
          note: 'Zainicjalizowano rejestr kontroli X-Ray UCI i spraw CAS.',
        ),
        model: model,
      );
    }

    if (raw is! Map<String, dynamic>) {
      final repaired = TechnicalScrutinyAndCasTribunalModel.initial(
        seasonYear: seasonYear,
        nowIso: now.toIso8601String(),
      );
      payload[section.jsonKey] = repaired.toJson();
      actions.add(
        V10MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason:
              'Uszkodzony typ rejestru kontroli technicznych UCI — przywrócono stan początkowy.',
          appliedValueSummary: 'zgodność=100.0%',
          wasRepaired: true,
        ),
      );
      return _V10SectionResult(
        summary: const Package10SectionSummary(
          section: section,
          presentBefore: true,
          validAfter: true,
          recordsCount: 0,
          issuesFixedCount: 1,
          note: 'Naprawiono uszkodzony rejestr kontroli UCI / CAS.',
        ),
        model: repaired,
      );
    }

    TechnicalScrutinyAndCasTribunalModel parsed;
    try {
      parsed = TechnicalScrutinyAndCasTribunalModel.fromJson(raw);
    } catch (_) {
      parsed = TechnicalScrutinyAndCasTribunalModel.initial(
        seasonYear: seasonYear,
        nowIso: now.toIso8601String(),
      );
      issuesFixed++;
      actions.add(
        V10MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason:
              'Uszkodzone wpisy inspekcji UCI lub spraw CAS — odbudowano rejestr.',
          appliedValueSummary: 'sezon=$seasonYear',
          wasRepaired: true,
        ),
      );
    }

    final int validSeasonYear = parsed.seasonYear.clamp(1970, 2150);
    final double clampedCompliance =
        parsed.teamComplianceAuditScore.clamp(0.0, 100.0);
    final double clampedBias =
        parsed.scrutinyTargetProbabilityBias.clamp(0.0, 1.0);
    final double clampedFines =
        parsed.totalFinesPaidChf < 0 ? 0.0 : parsed.totalFinesPaidChf;

    if (validSeasonYear != parsed.seasonYear ||
        clampedCompliance != parsed.teamComplianceAuditScore ||
        clampedBias != parsed.scrutinyTargetProbabilityBias ||
        clampedFines != parsed.totalFinesPaidChf) {
      parsed = parsed.copyWith(
        seasonYear: validSeasonYear,
        teamComplianceAuditScore: clampedCompliance,
        scrutinyTargetProbabilityBias: clampedBias,
        totalFinesPaidChf: clampedFines,
      );
      issuesFixed++;
      actions.add(
        V10MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason:
              'Skorygowano wartości brzegowe wskaźnika zgodności UCI lub grzywien CHF.',
          appliedValueSummary:
              'zgodność=${clampedCompliance.toStringAsFixed(1)}%, grzywny=${clampedFines.toStringAsFixed(0)} CHF',
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
          V10MigrationFieldAction(
            jsonPath: section.jsonKey,
            section: section,
            reason:
                'Znormalizowano strukturę JSON kontroli technicznych UCI i spraw CAS.',
            appliedValueSummary:
                'inspekcje=${parsed.inspectionHistory.length}, sprawyCAS=${parsed.casCases.length}',
          ),
        );
      }
    }

    return _V10SectionResult(
      summary: Package10SectionSummary(
        section: section,
        presentBefore: presentBefore,
        validAfter: true,
        recordsCount: parsed.inspectionHistory.length + parsed.casCases.length,
        issuesFixedCount: issuesFixed,
        note:
            'Inspekcje: ${parsed.inspectionHistory.length}, CAS: ${parsed.casCases.length}.',
      ),
      model: parsed,
    );
  }

  // ---------------------------------------------------------------------------
  // 3. NOCNE HRV, CK I FIZJOTERAPIA GRAND TOUR (OPCJONALNE)
  // ---------------------------------------------------------------------------
  static _V10OptionalSectionResult<GrandTourNightlyHrvAndPhysioModel>
      _migrateGrandTourNightlyHrvAndPhysio({
    required Map<String, dynamic> payload,
    required int seasonYear,
    required bool initializeIfMissing,
    required List<V10MigrationFieldAction> actions,
  }) {
    const section = Package10MigrationSection.grandTourNightlyHrvAndPhysio;
    final raw = payload[section.jsonKey];
    final bool presentBefore = raw != null;
    int issuesFixed = 0;

    if (raw == null) {
      if (!initializeIfMissing) {
        return const _V10OptionalSectionResult(
          summary: Package10SectionSummary(
            section: section,
            presentBefore: false,
            validAfter: true,
            recordsCount: 0,
            issuesFixedCount: 0,
            note:
                'Opcjonalny moduł fizjologii Grand Tour — nieaktywny poza Wielkim Tourem.',
          ),
          model: null,
        );
      }
      final model = GrandTourNightlyHrvAndPhysioModel.initializeSquad(
        tourId: 'gt_default_$seasonYear',
        tourName: 'Tour de France $seasonYear',
        squadBaselines: _defaultGrandTourSquadBaselines(),
      );
      payload[section.jsonKey] = model.toJson();
      actions.add(
        V10MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason:
              'Zainicjalizowano opcjonalny moduł nocnego HRV i fizjoterapii dla 8-osobowego składu GT.',
          appliedValueSummary:
              'kolarze=${model.baselines.length}, etap=${model.currentStageDay}',
        ),
      );
      return _V10OptionalSectionResult(
        summary: Package10SectionSummary(
          section: section,
          presentBefore: false,
          validAfter: true,
          recordsCount: model.baselines.length,
          issuesFixedCount: 1,
          note:
              'Zainicjalizowano bazowe biomarkery HRV/CK dla 8 kolarzy Grand Tour.',
        ),
        model: model,
      );
    }

    if (raw is! Map<String, dynamic>) {
      final repaired = GrandTourNightlyHrvAndPhysioModel.initializeSquad(
        tourId: 'gt_default_$seasonYear',
        tourName: 'Tour de France $seasonYear',
        squadBaselines: _defaultGrandTourSquadBaselines(),
      );
      payload[section.jsonKey] = repaired.toJson();
      actions.add(
        V10MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason:
              'Uszkodzony typ danych GrandTourNightlyHrvAndPhysioModel — odbudowano skład GT.',
          appliedValueSummary: 'kolarze=${repaired.baselines.length}',
          wasRepaired: true,
        ),
      );
      return _V10OptionalSectionResult(
        summary: Package10SectionSummary(
          section: section,
          presentBefore: true,
          validAfter: true,
          recordsCount: repaired.baselines.length,
          issuesFixedCount: 1,
          note: 'Naprawiono uszkodzony moduł biomarkerów Grand Tour.',
        ),
        model: repaired,
      );
    }

    GrandTourNightlyHrvAndPhysioModel parsed;
    try {
      parsed = GrandTourNightlyHrvAndPhysioModel.fromJson(raw);
    } catch (_) {
      parsed = GrandTourNightlyHrvAndPhysioModel.initializeSquad(
        tourId: 'gt_default_$seasonYear',
        tourName: 'Tour de France $seasonYear',
        squadBaselines: _defaultGrandTourSquadBaselines(),
      );
      issuesFixed++;
      actions.add(
        V10MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason:
              'Uszkodzone próbki HRV/CK Grand Tour — przywrócono bazę 8 kolarzy.',
          appliedValueSummary: 'kolarze=${parsed.baselines.length}',
          wasRepaired: true,
        ),
      );
    }

    final int clampedDay = parsed.currentStageDay
        .clamp(1, GrandTourNightlyHrvAndPhysioModel.maxGrandTourDays);
    if (clampedDay != parsed.currentStageDay) {
      parsed = parsed.copyWith(currentStageDay: clampedDay);
      issuesFixed++;
      actions.add(
        V10MigrationFieldAction(
          jsonPath: '${section.jsonKey}.currentStageDay',
          section: section,
          reason: 'Skorygowano numer dnia etapu Grand Tour do zakresu 1–21.',
          appliedValueSummary: 'dzień=$clampedDay',
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
          V10MigrationFieldAction(
            jsonPath: section.jsonKey,
            section: section,
            reason:
                'Znormalizowano strukturę JSON nocnych pomiarów HRV i CK Grand Tour.',
            appliedValueSummary:
                'kolarze=${parsed.baselines.length}, dni=${parsed.historyByDay.length}',
          ),
        );
      }
    }

    return _V10OptionalSectionResult(
      summary: Package10SectionSummary(
        section: section,
        presentBefore: presentBefore,
        validAfter: true,
        recordsCount: parsed.baselines.length + parsed.historyByDay.length,
        issuesFixedCount: issuesFixed,
        note:
            'Kolarze: ${parsed.baselines.length}, raporty poranne: ${parsed.historyByDay.length}.',
      ),
      model: parsed,
    );
  }

  // ---------------------------------------------------------------------------
  // 4. TRYB REŻYSERA TRANSMISJI TV (OPCJONALNE)
  // ---------------------------------------------------------------------------
  static _V10OptionalSectionResult<TvDirectorLiveProductionModel>
      _migrateTvDirectorLiveProduction({
    required Map<String, dynamic> payload,
    required bool initializeIfMissing,
    required List<V10MigrationFieldAction> actions,
  }) {
    const section = Package10MigrationSection.tvDirectorLiveProduction;
    final raw = payload[section.jsonKey];
    final bool presentBefore = raw != null;
    int issuesFixed = 0;

    if (raw == null) {
      if (!initializeIfMissing) {
        return const _V10OptionalSectionResult(
          summary: Package10SectionSummary(
            section: section,
            presentBefore: false,
            validAfter: true,
            recordsCount: 0,
            issuesFixedCount: 0,
            note:
                'Opcjonalny tryb Reżysera Transmisji TV — nieaktywny poza transmisją na żywo.',
          ),
          model: null,
        );
      }
      final model = TvDirectorLiveProductionModel.createDefaultTourDeFranceStage();
      payload[section.jsonKey] = model.toJson();
      actions.add(
        V10MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason:
              'Zainicjalizowano opcjonalny wóz transmisyjny Reżysera TV z 12 kamerami.',
          appliedValueSummary:
              'kamery=${model.cameraFeeds.length}, budżet=${model.productionBudget.allocatedStageBudgetEur.toStringAsFixed(0)} EUR',
        ),
      );
      return _V10OptionalSectionResult(
        summary: Package10SectionSummary(
          section: section,
          presentBefore: false,
          validAfter: true,
          recordsCount: model.cameraFeeds.length,
          issuesFixedCount: 1,
          note:
              'Zainicjalizowano domyślną produkcję World Feed (12 kamer + grafiki TV).',
        ),
        model: model,
      );
    }

    if (raw is! Map<String, dynamic>) {
      final repaired =
          TvDirectorLiveProductionModel.createDefaultTourDeFranceStage();
      payload[section.jsonKey] = repaired.toJson();
      actions.add(
        V10MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason:
              'Uszkodzony typ obiektu TvDirectorLiveProductionModel — przywrócono 12 kamer.',
          appliedValueSummary: 'kamery=${repaired.cameraFeeds.length}',
          wasRepaired: true,
        ),
      );
      return _V10OptionalSectionResult(
        summary: Package10SectionSummary(
          section: section,
          presentBefore: true,
          validAfter: true,
          recordsCount: repaired.cameraFeeds.length,
          issuesFixedCount: 1,
          note: 'Naprawiono uszkodzoną strukturę Reżysera Transmisji TV.',
        ),
        model: repaired,
      );
    }

    TvDirectorLiveProductionModel parsed;
    try {
      parsed = TvDirectorLiveProductionModel.fromJson(raw);
    } catch (_) {
      parsed = TvDirectorLiveProductionModel.createDefaultTourDeFranceStage();
      issuesFixed++;
      actions.add(
        V10MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason:
              'Niekompletne kanały kamer lub metryki transmisji TV — odbudowano produkcję.',
          appliedValueSummary: 'kamery=${parsed.cameraFeeds.length}',
          wasRepaired: true,
        ),
      );
    }

    if (parsed.cameraFeeds.isEmpty) {
      final defaults =
          TvDirectorLiveProductionModel.createDefaultTourDeFranceStage();
      parsed = parsed.copyWith(
        cameraFeeds: defaults.cameraFeeds,
        programCameraId: defaults.programCameraId,
        previewCameraId: defaults.previewCameraId,
        sixMonitorDeckIds: defaults.sixMonitorDeckIds,
      );
      issuesFixed++;
      actions.add(
        V10MigrationFieldAction(
          jsonPath: '${section.jsonKey}.cameraFeeds',
          section: section,
          reason:
              'Pusta lista kamer transmisji TV — uzupełniono zestaw 12 kamer zachowując metryki i budżet.',
          appliedValueSummary: 'kamery=${parsed.cameraFeeds.length}',
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
          V10MigrationFieldAction(
            jsonPath: section.jsonKey,
            section: section,
            reason:
                'Znormalizowano strukturę JSON produkcji Reżysera Transmisji TV.',
            appliedValueSummary:
                'kamery=${parsed.cameraFeeds.length}, grafiki=${parsed.graphicsQueue.length}',
          ),
        );
      }
    }

    return _V10OptionalSectionResult(
      summary: Package10SectionSummary(
        section: section,
        presentBefore: presentBefore,
        validAfter: true,
        recordsCount: parsed.cameraFeeds.length + parsed.graphicsQueue.length,
        issuesFixedCount: issuesFixed,
        note:
            'Kamery: ${parsed.cameraFeeds.length}, kolejka grafik: ${parsed.graphicsQueue.length}.',
      ),
      model: parsed,
    );
  }

  // ---------------------------------------------------------------------------
  // 5. BAZA POTRÓJNEJ KORONY I ZWYCIĘZCÓW WIELKICH TOURÓW
  // ---------------------------------------------------------------------------
  static _V10SectionResult<HistoricalGrandTourWinnersTimelineDb>
      _migrateTripleCrownTimelineDb({
    required Map<String, dynamic> payload,
    required int seasonYear,
    required List<V10MigrationFieldAction> actions,
  }) {
    const section = Package10MigrationSection.tripleCrownWinnersTimelineDb;
    final raw = payload[section.jsonKey];
    final bool presentBefore = raw != null;
    int issuesFixed = 0;

    if (raw == null) {
      final db = HistoricalGrandTourWinnersTimelineDb.withDefaultHistory(
        careerStartYear: seasonYear,
      );
      payload[section.jsonKey] = db.toJson();
      final tripleCount = db.detectTripleCrownWinners().length;
      actions.add(
        V10MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason:
              'Brak bazy zwycięzców Wielkich Tourów i Potrójnej Korony — zainicjalizowano historię bazową.',
          appliedValueSummary:
              'wpisy=${db.allEntries.length}, potrójneKorony=$tripleCount',
        ),
      );
      return _V10SectionResult(
        summary: Package10SectionSummary(
          section: section,
          presentBefore: false,
          validAfter: true,
          recordsCount: db.allEntries.length,
          issuesFixedCount: 1,
          note:
              'Zainicjalizowano bazę (${db.allEntries.length} zwycięstw, $tripleCount Potrójne Korony).',
        ),
        model: db,
      );
    }

    if (raw is! Map<String, dynamic>) {
      final repaired = HistoricalGrandTourWinnersTimelineDb.withDefaultHistory(
        careerStartYear: seasonYear,
      );
      payload[section.jsonKey] = repaired.toJson();
      actions.add(
        V10MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason:
              'Uszkodzony typ bazy Potrójnej Korony — przywrócono historyczną oś czasu.',
          appliedValueSummary: 'wpisy=${repaired.allEntries.length}',
          wasRepaired: true,
        ),
      );
      return _V10SectionResult(
        summary: Package10SectionSummary(
          section: section,
          presentBefore: true,
          validAfter: true,
          recordsCount: repaired.allEntries.length,
          issuesFixedCount: 1,
          note: 'Naprawiono uszkodzoną bazę zwycięzców Potrójnej Korony.',
        ),
        model: repaired,
      );
    }

    HistoricalGrandTourWinnersTimelineDb parsed;
    try {
      parsed = HistoricalGrandTourWinnersTimelineDb.fromJson(raw);
    } catch (_) {
      parsed = HistoricalGrandTourWinnersTimelineDb.withDefaultHistory(
        careerStartYear: seasonYear,
      );
      issuesFixed++;
      actions.add(
        V10MigrationFieldAction(
          jsonPath: section.jsonKey,
          section: section,
          reason:
              'Niekompletne wpisy bazy Potrójnej Korony — odbudowano kronikę historyczną.',
          appliedValueSummary: 'wpisy=${parsed.allEntries.length}',
          wasRepaired: true,
        ),
      );
    }

    if (parsed.allEntries.isEmpty) {
      final seeded = HistoricalGrandTourWinnersTimelineDb.withDefaultHistory(
        careerStartYear: parsed.careerStartYear,
      );
      parsed.recordWinners(seeded.allEntries);
      issuesFixed++;
      actions.add(
        V10MigrationFieldAction(
          jsonPath: '${section.jsonKey}.entries',
          section: section,
          reason:
              'Pusta kronika zwycięzców — przywrócono historyczne legendy Potrójnej Korony (1974, 1987, 2024).',
          appliedValueSummary: 'wpisy=${parsed.allEntries.length}',
          wasRepaired: true,
        ),
      );
    }

    final tripleCount = parsed.detectTripleCrownWinners().length;
    final normalized = parsed.toJson();
    if (jsonEncode(raw) != jsonEncode(normalized)) {
      payload[section.jsonKey] = normalized;
      if (issuesFixed == 0) {
        issuesFixed++;
        actions.add(
          V10MigrationFieldAction(
            jsonPath: section.jsonKey,
            section: section,
            reason:
                'Znormalizowano strukturę JSON bazy Potrójnej Korony i Wielkich Tourów.',
            appliedValueSummary:
                'wpisy=${parsed.allEntries.length}, potrójneKorony=$tripleCount',
          ),
        );
      }
    }

    return _V10SectionResult(
      summary: Package10SectionSummary(
        section: section,
        presentBefore: presentBefore,
        validAfter: true,
        recordsCount: parsed.allEntries.length,
        issuesFixedCount: issuesFixed,
        note:
            'Wpisy: ${parsed.allEntries.length}, Potrójne Korony: $tripleCount.',
      ),
      model: parsed,
    );
  }

  // ---------------------------------------------------------------------------
  // POMOCNICZE METODY EKSTRAKCJI I DOMYŚLNE DANE
  // ---------------------------------------------------------------------------
  static int _extractSeasonYear(Map<String, dynamic> payload, DateTime now) {
    final direct = (payload['seasonYear'] as num?)?.toInt() ??
        (payload['currentYear'] as num?)?.toInt();
    if (direct != null && direct >= 1970 && direct <= 2150) {
      return direct;
    }
    return now.year;
  }

  static List<RiderBaselineBiomarkers> _defaultGrandTourSquadBaselines() {
    return List<RiderBaselineBiomarkers>.generate(
      GrandTourNightlyHrvAndPhysioModel.grandTourSquadSize,
      (index) => RiderBaselineBiomarkers(
        riderId: 'gt_rider_${index + 1}',
        riderName: 'Kolarz GT #${index + 1}',
        baselineHrvRmssdMs: 74.0 + (index % 4) * 3.5,
        baselineRhrBpm: 42 + (index % 3) * 2,
        baselineCkUL: 165.0 + index * 8.0,
        baselineCortisolNmolL: 410.0,
        baselineTestosteroneNmolL: 19.5,
        baselineSleepEfficiencyPct: 89.0,
      ),
    );
  }
}

class _V10SectionResult<T> {
  final Package10SectionSummary summary;
  final T model;

  const _V10SectionResult({required this.summary, required this.model});
}

class _V10OptionalSectionResult<T> {
  final Package10SectionSummary summary;
  final T? model;

  const _V10OptionalSectionResult({required this.summary, required this.model});
}

// =============================================================================
// STAN I NOTIFIER RIVERPOD DLA MIGRATORA V10
// =============================================================================

@immutable
class SaveCompatibilityV10State {
  final bool isRunning;
  final bool initializeOptionalModesIfMissing;
  final Package10MigrationSection? activeFilter;
  final SaveCompatibilityV10Report? lastReport;

  const SaveCompatibilityV10State({
    this.isRunning = false,
    this.initializeOptionalModesIfMissing = false,
    this.activeFilter,
    this.lastReport,
  });

  SaveCompatibilityV10State copyWith({
    bool? isRunning,
    bool? initializeOptionalModesIfMissing,
    Package10MigrationSection? activeFilter,
    bool clearFilter = false,
    SaveCompatibilityV10Report? lastReport,
  }) {
    return SaveCompatibilityV10State(
      isRunning: isRunning ?? this.isRunning,
      initializeOptionalModesIfMissing: initializeOptionalModesIfMissing ??
          this.initializeOptionalModesIfMissing,
      activeFilter: clearFilter ? null : (activeFilter ?? this.activeFilter),
      lastReport: lastReport ?? this.lastReport,
    );
  }
}

class SaveCompatibilityV10Notifier
    extends StateNotifier<SaveCompatibilityV10State> {
  SaveCompatibilityV10Notifier() : super(const SaveCompatibilityV10State());

  void toggleInitializeOptionalModes(bool value) {
    state = state.copyWith(initializeOptionalModesIfMissing: value);
  }

  void setSectionFilter(Package10MigrationSection? section) {
    if (section == null || state.activeFilter == section) {
      state = state.copyWith(clearFilter: true);
    } else {
      state = state.copyWith(activeFilter: section);
    }
  }

  SaveCompatibilityV10Report runMigrationOnRawJson({
    required String saveId,
    required String rawJson,
  }) {
    state = state.copyWith(isRunning: true);
    final report = SaveCompatibilityV10Migrator.migrateRawJson(
      saveId: saveId,
      rawJson: rawJson,
      initializeOptionalModesIfMissing: state.initializeOptionalModesIfMissing,
    );
    state = state.copyWith(isRunning: false, lastReport: report);
    return report;
  }

  SaveCompatibilityV10Report runMigrationOnPayload({
    required String saveId,
    required Map<String, dynamic> payload,
    int sourceSchemaVersion = 9,
  }) {
    state = state.copyWith(isRunning: true);
    final report = SaveCompatibilityV10Migrator.migratePayloadMap(
      saveId: saveId,
      payload: payload,
      sourceSchemaVersion: sourceSchemaVersion,
      initializeOptionalModesIfMissing: state.initializeOptionalModesIfMissing,
    );
    state = state.copyWith(isRunning: false, lastReport: report);
    return report;
  }
}

/// Globalny provider migratora kompatybilności v10 (Paczka #10).
final saveCompatibilityV10Provider = StateNotifierProvider<
    SaveCompatibilityV10Notifier, SaveCompatibilityV10State>(
  (ref) => SaveCompatibilityV10Notifier(),
);

// =============================================================================
// RESPONSYWNY PANEL UI MIGRATORA V10 (LayoutBuilder 390x844 / 1024x768 / 1600x900)
// =============================================================================

/// Responsywny panel diagnostyczny migratora zapisów v10 dla Paczki #10.
class SaveCompatibilityV10MigratorPanel extends ConsumerWidget {
  final String saveId;
  final String? sampleRawJson;
  final Map<String, dynamic>? samplePayload;
  final int sampleSourceSchemaVersion;
  final VoidCallback? onMigrationCompleted;

  const SaveCompatibilityV10MigratorPanel({
    super.key,
    this.saveId = 'active_career_slot',
    this.sampleRawJson,
    this.samplePayload,
    this.sampleSourceSchemaVersion = 9,
    this.onMigrationCompleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(saveCompatibilityV10Provider);
    final notifier = ref.read(saveCompatibilityV10Provider.notifier);

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

  Widget _buildHeader(SaveCompatibilityV10State state, bool isCompact) {
    final statusColor = state.lastReport?.status.color ?? AppColors.goldAccent;
    final statusText =
        state.lastReport?.status.labelPl ?? 'OCZEKUJE NA WERYFIKACJĘ V10';

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
                    'Migrator Zapisów v10 (Paczka #10)',
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
                    'Kompatybilność wsteczna v1–v9 → schemat v10',
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
    required SaveCompatibilityV10State state,
    required SaveCompatibilityV10Notifier notifier,
    required bool isCompact,
  }) {
    final toggleControl = _V10InteractiveToggleChip(
      label: 'Inicjalizuj tryby opcjonalne (Grand Tour HRV / TV Director)',
      value: state.initializeOptionalModesIfMissing,
      enabled: !state.isRunning,
      onChanged: notifier.toggleInitializeOptionalModes,
    );

    final runButton = _V10PrimaryActionButton(
      label: state.isRunning ? 'Migracja w toku...' : 'Uruchom Migrację v10',
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
                  'seasonYear': 2026,
                  'playerTeamId': 'team_polonia_orlen',
                  'playerTeamName': 'Polonia Orlen Pro Cycling',
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
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
              'Uruchom migrator v10, aby bezstratnie zaktualizować zapis do Paczki #10 (Ameryki/Oceania, X-Ray UCI/CAS, Nocne HRV GT, Reżyser TV, Potrójna Korona).',
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

  Widget _buildReportBanner(SaveCompatibilityV10Report report, bool isCompact) {
    final shortChecksum = report.checksumAfter.length >= 12
        ? report.checksumAfter.substring(0, 12)
        : report.checksumAfter;
    final preFixes = report.v9PreMigrationReport?.totalFixesCount ?? 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1),
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
            spacing: isCompact ? 8 : 16,
            runSpacing: 6,
            children: [
              _buildMetricBadge(
                'Schemat',
                'v${report.sourceSchemaVersion} → v${report.targetSchemaVersion}',
                AppColors.accentBlue,
              ),
              _buildMetricBadge(
                'Poprawki v10',
                '${report.actions.length}',
                AppColors.goldAccent,
              ),
              if (preFixes > 0)
                _buildMetricBadge(
                  'Pre-migracja v9',
                  '$preFixes',
                  AppColors.amberWarning,
                ),
              _buildMetricBadge(
                'SHA-256',
                shortChecksum.isEmpty ? 'brak' : shortChecksum,
                AppColors.statusSuccess,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBadge(String label, String value, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder, width: 1),
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
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionsGrid({
    required SaveCompatibilityV10Report report,
    required SaveCompatibilityV10State state,
    required SaveCompatibilityV10Notifier notifier,
    required bool isCompact,
    required bool isWide,
  }) {
    final int columns = isCompact ? 1 : (isWide ? 3 : 2);
    return LayoutBuilder(
      builder: (context, constraints) {
        const double spacing = 10;
        final double cardWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: report.sectionSummaries.map((summary) {
            final isSelected = state.activeFilter == summary.section;
            return SizedBox(
              width: cardWidth,
              child: _V10SectionSummaryCard(
                summary: summary,
                isSelected: isSelected,
                onTap: () => notifier.setSectionFilter(summary.section),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildActionsLog(
    SaveCompatibilityV10Report report,
    Package10MigrationSection? filter,
  ) {
    final filteredActions = filter == null
        ? report.actions
        : report.actions.where((a) => a.section == filter).toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            filter == null
                ? 'Dziennik migracji v10 (${filteredActions.length})'
                : 'Dziennik dla "${filter.labelPl}" (${filteredActions.length})',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          if (filteredActions.isEmpty)
            const Text(
              'Brak wymaganych modyfikacji dla wybranego filtra — zapis był zgodny.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: filteredActions.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 10,
                  color: AppColors.cardBorder,
                ),
                itemBuilder: (context, index) {
                  final action = filteredActions[index];
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        action.wasRepaired
                            ? Icons.build_circle_rounded
                            : Icons.check_circle_outline_rounded,
                        size: 16,
                        color: action.wasRepaired
                            ? AppColors.amberWarning
                            : AppColors.statusSuccess,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${action.jsonPath} • ${action.appliedValueSummary}',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                fontFeatures: [FontFeature.tabularFigures()],
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
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _V10InteractiveToggleChip extends StatefulWidget {
  final String label;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _V10InteractiveToggleChip({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  State<_V10InteractiveToggleChip> createState() =>
      _V10InteractiveToggleChipState();
}

class _V10InteractiveToggleChipState extends State<_V10InteractiveToggleChip> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = !widget.enabled
        ? AppColors.cardBorder.withValues(alpha: 0.4)
        : _focused
            ? AppColors.goldAccent
            : widget.value
                ? AppColors.accentBlue
                : _hovered
                    ? AppColors.textSecondary
                    : AppColors.cardBorder;

    return Focus(
      canRequestFocus: widget.enabled,
      onFocusChange: (focused) => setState(() => _focused = focused),
      child: MouseRegion(
        cursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTapDown: widget.enabled
              ? (_) => setState(() => _pressed = true)
              : null,
          onTapUp: widget.enabled
              ? (_) => setState(() => _pressed = false)
              : null,
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.enabled
              ? () => widget.onChanged(!widget.value)
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            transform: Matrix4.diagonal3Values(
              _pressed ? 0.99 : 1.0,
              _pressed ? 0.99 : 1.0,
              1.0,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: !widget.enabled
                  ? AppColors.background.withValues(alpha: 0.5)
                  : widget.value
                      ? AppColors.accentBlue.withValues(alpha: 0.14)
                      : _hovered
                          ? AppColors.surfaceLight
                          : AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Row(
              children: [
                Icon(
                  widget.value
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  size: 18,
                  color: !widget.enabled
                      ? AppColors.textSecondary.withValues(alpha: 0.4)
                      : widget.value
                          ? AppColors.accentBlue
                          : AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.label,
                    maxLines: 2,
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
      ),
    );
  }
}

class _V10PrimaryActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  const _V10PrimaryActionButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_V10PrimaryActionButton> createState() =>
      _V10PrimaryActionButtonState();
}

class _V10PrimaryActionButtonState extends State<_V10PrimaryActionButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final Color bgColor = !widget.enabled
        ? AppColors.surfaceLight
        : _pressed
            ? AppColors.primaryAccent.withValues(alpha: 0.8)
            : _hovered
                ? AppColors.primaryAccent.withValues(alpha: 0.92)
                : AppColors.primaryAccent;

    return Focus(
      canRequestFocus: widget.enabled,
      onFocusChange: (focused) => setState(() => _focused = focused),
      child: MouseRegion(
        cursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTapDown: widget.enabled
              ? (_) => setState(() => _pressed = true)
              : null,
          onTapUp: widget.enabled
              ? (_) => setState(() => _pressed = false)
              : null,
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.enabled ? widget.onPressed : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            transform: Matrix4.diagonal3Values(
              _pressed ? 0.98 : 1.0,
              _pressed ? 0.98 : 1.0,
              1.0,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _focused
                    ? AppColors.goldAccent
                    : AppColors.cardBorder,
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

class _V10SectionSummaryCard extends StatefulWidget {
  final Package10SectionSummary summary;
  final bool isSelected;
  final VoidCallback onTap;

  const _V10SectionSummaryCard({
    required this.summary,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_V10SectionSummaryCard> createState() =>
      _V10SectionSummaryCardState();
}

class _V10SectionSummaryCardState extends State<_V10SectionSummaryCard> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final Color statusColor = !widget.summary.validAfter
        ? AppColors.crimsonAlert
        : widget.summary.issuesFixedCount > 0
            ? AppColors.amberWarning
            : AppColors.statusSuccess;

    final Color borderColor = _focused
        ? AppColors.goldAccent
        : widget.isSelected
            ? AppColors.accentBlue
            : _hovered
                ? AppColors.textSecondary
                : AppColors.cardBorder;

    return Focus(
      onFocusChange: (focused) => setState(() => _focused = focused),
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
            transform: Matrix4.diagonal3Values(
              _pressed ? 0.99 : 1.0,
              _pressed ? 0.99 : 1.0,
              1.0,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? AppColors.accentBlue.withValues(alpha: 0.1)
                  : _hovered
                      ? AppColors.surfaceLight
                      : AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      widget.summary.section.icon,
                      size: 18,
                      color: statusColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.summary.section.packageTag,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                    Text(
                      '${widget.summary.recordsCount} rek.',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontFeatures: [FontFeature.tabularFigures()],
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  widget.summary.section.labelPl,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
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
      ),
    );
  }
}
