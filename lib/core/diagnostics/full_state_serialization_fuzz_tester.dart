// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/career/career_save.dart';
import '../../models/career/pro_cyclist_career_state.dart';
import '../../models/rider/rider_contract.dart';
import '../../models/settings/game_settings.dart';
import '../../services/generators/initial_game_seeder.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Strategia mutacji używana przez fuzzer serializacji JSON stanu kariery.
enum FuzzMutationStrategy {
  cleanRoundTrip(
    'Round-Trip 1:1',
    'Pełny cykl toJson -> jsonEncode -> jsonDecode -> fromJson -> toJson z głębokim porównaniem.',
    Icons.sync_alt_rounded,
    AppColors.statusSuccess,
  ),
  missingOptionalFields(
    'Brakujące Pola Opcjonalne',
    'Usuwa losowe opcjonalne sekcje i sprawdza domyślne wartości fallback w fromJson.',
    Icons.layers_clear_rounded,
    AppColors.accentBlue,
  ),
  boundaryValues(
    'Wartości Graniczne & Unicode',
    'Wstrzykuje wartości ekstremalne (0, duże liczby, polskie znaki, emoji, puste listy).',
    Icons.straighten_rounded,
    AppColors.goldAccent,
  ),
  corruptedAndUnknownFields(
    'Nieznane Klucze & Enum Fallback',
    'Dodaje nieznane pola przyszłych wersji, nulle oraz błędne/wielkie litery w enumach.',
    Icons.bug_report_rounded,
    AppColors.amberWarning,
  ),
  typeCoercion(
    'Konwersja Typów num (int/double)',
    'Konwertuje liczby całkowite na zmiennoprzecinkowe (100 -> 100.0) jak w parserach JSON.',
    Icons.swap_horiz_rounded,
    AppColors.cyanAccent,
  ),
  malformedJsonRecovery(
    'Odporność na Uszkodzony JSON',
    'Testuje bezpieczne parsowanie uciętego, niepoprawnego składniowo lub niezgodnego typu JSON.',
    Icons.shield_rounded,
    AppColors.crimsonAlert,
  );

  final String labelPl;
  final String descriptionPl;
  final IconData icon;
  final Color accentColor;

  const FuzzMutationStrategy(
    this.labelPl,
    this.descriptionPl,
    this.icon,
    this.accentColor,
  );
}

/// Wynik pojedynczego przypadku testowego fuzzera.
enum FuzzCaseOutcome {
  passed('ZALICZONY', AppColors.statusSuccess),
  handledGracefully('OBSŁUŻONO BEZPIECZNIE', AppColors.accentBlue),
  diffDetected('WYKRYTO RÓŻNICĘ JSON', AppColors.amberWarning),
  crashed('WYJĄTEK KRYTYCZNY', AppColors.crimsonAlert);

  final String labelPl;
  final Color color;

  const FuzzCaseOutcome(this.labelPl, this.color);

  bool get isHealthy =>
      this == FuzzCaseOutcome.passed ||
      this == FuzzCaseOutcome.handledGracefully;
}

/// Filtr wyników w panelu UI fuzzera.
enum FuzzOutcomeFilter {
  all('Wszystkie'),
  issuesOnly('Tylko Problemy'),
  passedOnly('Zaliczone'),
  gracefulOnly('Obsłużone Błędy');

  final String labelPl;

  const FuzzOutcomeFilter(this.labelPl);
}

/// Rodzaj rozbieżności wykrytej podczas głębokiego porównania dwóch drzew JSON.
enum FuzzDiffKind {
  missingKey('Brakujący klucz'),
  unexpectedKey('Nadmiarowy klucz'),
  typeMismatch(' niezgodność typu'),
  valueMismatch('Niezgodność wartości'),
  listLengthMismatch('Różna długość listy');

  final String labelPl;

  const FuzzDiffKind(this.labelPl);
}

/// Pojedyncza rozbieżność strukturalna między oczekiwanym a zdeserializowanym JSON-em.
@immutable
class FuzzJsonDiff {
  final String path;
  final FuzzDiffKind kind;
  final String expectedSummary;
  final String actualSummary;

  const FuzzJsonDiff({
    required this.path,
    required this.kind,
    required this.expectedSummary,
    required this.actualSummary,
  });

  Map<String, dynamic> toJson() => {
        'path': path,
        'kind': kind.name,
        'expectedSummary': expectedSummary,
        'actualSummary': actualSummary,
      };

  @override
  String toString() =>
      '$path [${kind.labelPl}]: oczekiwano=$expectedSummary, otrzymano=$actualSummary';
}

/// Wynik pojedynczej iteracji fuzzera.
@immutable
class FuzzIterationResult {
  final int iterationIndex;
  final int seed;
  final FuzzMutationStrategy strategy;
  final String targetSection;
  final FuzzCaseOutcome outcome;
  final int durationMs;
  final int checkedPathsCount;
  final List<FuzzJsonDiff> diffs;
  final String? errorMessage;

  const FuzzIterationResult({
    required this.iterationIndex,
    required this.seed,
    required this.strategy,
    required this.targetSection,
    required this.outcome,
    required this.durationMs,
    required this.checkedPathsCount,
    this.diffs = const [],
    this.errorMessage,
  });

  Map<String, dynamic> toJson() => {
        'iterationIndex': iterationIndex,
        'seed': seed,
        'strategy': strategy.name,
        'targetSection': targetSection,
        'outcome': outcome.name,
        'durationMs': durationMs,
        'checkedPathsCount': checkedPathsCount,
        'diffs': diffs.map((d) => d.toJson()).toList(),
        'errorMessage': errorMessage,
      };
}

/// Konfiguracja kampanii fuzzowania serializacji stanu kariery.
@immutable
class FuzzCampaignConfig {
  final int baseSeed;
  final int iterations;
  final Set<FuzzMutationStrategy> enabledStrategies;
  final bool includeSubModels;
  final int maxDiffsPerCase;

  const FuzzCampaignConfig({
    this.baseSeed = 20260409,
    this.iterations = 18,
    this.enabledStrategies = const {
      FuzzMutationStrategy.cleanRoundTrip,
      FuzzMutationStrategy.missingOptionalFields,
      FuzzMutationStrategy.boundaryValues,
      FuzzMutationStrategy.corruptedAndUnknownFields,
      FuzzMutationStrategy.typeCoercion,
      FuzzMutationStrategy.malformedJsonRecovery,
    },
    this.includeSubModels = true,
    this.maxDiffsPerCase = 15,
  });

  FuzzCampaignConfig copyWith({
    int? baseSeed,
    int? iterations,
    Set<FuzzMutationStrategy>? enabledStrategies,
    bool? includeSubModels,
    int? maxDiffsPerCase,
  }) {
    return FuzzCampaignConfig(
      baseSeed: baseSeed ?? this.baseSeed,
      iterations: iterations ?? this.iterations,
      enabledStrategies: enabledStrategies ?? this.enabledStrategies,
      includeSubModels: includeSubModels ?? this.includeSubModels,
      maxDiffsPerCase: maxDiffsPerCase ?? this.maxDiffsPerCase,
    );
  }
}

/// Zbiorczy raport z kampanii fuzzowania serializacji JSON.
@immutable
class FuzzCampaignReport {
  final FuzzCampaignConfig config;
  final int totalIterations;
  final int passedCount;
  final int gracefulErrorCount;
  final int diffCount;
  final int crashCount;
  final int totalPathsChecked;
  final int uniqueKeysCovered;
  final int durationMs;
  final List<FuzzIterationResult> results;
  final DateTime generatedAt;

  const FuzzCampaignReport({
    required this.config,
    required this.totalIterations,
    required this.passedCount,
    required this.gracefulErrorCount,
    required this.diffCount,
    required this.crashCount,
    required this.totalPathsChecked,
    required this.uniqueKeysCovered,
    required this.durationMs,
    required this.results,
    required this.generatedAt,
  });

  bool get isSuccess => diffCount == 0 && crashCount == 0 && totalIterations > 0;

  double get passRate => totalIterations == 0
      ? 0.0
      : (passedCount + gracefulErrorCount) / totalIterations;

  String get summaryText {
    final status = isSuccess ? 'PASS (ZERO REGRESJI)' : 'FAIL (WYKRYTO BŁĘDY)';
    final buffer = StringBuffer()
      ..writeln('=== FULL STATE SERIALIZATION FUZZ REPORT [$status] ===')
      ..writeln(
        'Seed: ${config.baseSeed} | Iteracje: $totalIterations | Czas: ${durationMs}ms',
      )
      ..writeln(
        'Zaliczone: $passedCount | Obsłużone bezpiecznie: $gracefulErrorCount | Różnice JSON: $diffCount | Wyjątki: $crashCount',
      )
      ..writeln(
        'Sprawdzone ścieżki JSON: $totalPathsChecked | Pokryte unikalne klucze: $uniqueKeysCovered',
      );

    final issues = results.where((r) => !r.outcome.isHealthy).toList();
    if (issues.isNotEmpty) {
      buffer.writeln('\nWykryte problemy:');
      for (final issue in issues.take(10)) {
        buffer.writeln(
          '  - #${issue.iterationIndex} [${issue.strategy.labelPl}] (${issue.targetSection}): '
          '${issue.errorMessage ?? issue.diffs.firstOrNull?.toString() ?? issue.outcome.labelPl}',
        );
      }
    }
    return buffer.toString();
  }

  Map<String, dynamic> toJson() => {
        'isSuccess': isSuccess,
        'baseSeed': config.baseSeed,
        'totalIterations': totalIterations,
        'passedCount': passedCount,
        'gracefulErrorCount': gracefulErrorCount,
        'diffCount': diffCount,
        'crashCount': crashCount,
        'totalPathsChecked': totalPathsChecked,
        'uniqueKeysCovered': uniqueKeysCovered,
        'durationMs': durationMs,
        'generatedAt': generatedAt.toIso8601String(),
        'results': results.map((r) => r.toJson()).toList(),
      };
}

/// Wynik bezpiecznego parsowania surowego łańcucha JSON do [CareerSave].
@immutable
class SafeCareerParseResult {
  final CareerSave? save;
  final bool isSuccess;
  final String? errorMessage;

  const SafeCareerParseResult._({
    required this.save,
    required this.isSuccess,
    required this.errorMessage,
  });

  factory SafeCareerParseResult.success(CareerSave save) =>
      SafeCareerParseResult._(
        save: save,
        isSuccess: true,
        errorMessage: null,
      );

  factory SafeCareerParseResult.failure(String message) =>
      SafeCareerParseResult._(
        save: null,
        isSuccess: false,
        errorMessage: message,
      );
}

/// Deterministyczny fuzzer serializacji pełnego stanu kariery JSON (`CareerSave` + submodele).
class FullStateSerializationFuzzTester {
  FullStateSerializationFuzzTester._();

  static const List<String> _optionalCareerKeys = [
    'scoutedRiderIds',
    'contractOffers',
    'financeLedger',
    'managerReputation',
    'serviceCourseLevel',
    'windTunnelLevel',
    'medicalCenterLevel',
    'trophiesWon',
    'franchiseLeaders',
    'dedicatedSquads',
    'wildcardApplications',
    'scoutingProspects',
    'youthAcademy',
  ];

  static const List<String> _unicodeSamples = [
    'Żółć ęśłąźń Ćma Świat',
    'Équipe Côte d’Azur — Alpe d’Huez 🏔️🚴‍♂️',
    'Åre / Øresund / Straße 100%',
    'Team "Apex" \\ escaped / json\t\nline',
    '',
  ];

  /// Bezpiecznie parsuje surowy JSON kariery bez rzucania nieobsłużonych wyjątków.
  static SafeCareerParseResult tryParseCareerSaveSafe(String rawJson) {
    try {
      if (rawJson.trim().isEmpty) {
        return SafeCareerParseResult.failure('Pusty łańcuch JSON.');
      }
      final dynamic decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, dynamic>) {
        return SafeCareerParseResult.failure(
          'Oczekiwano obiektu JSON (Map), otrzymano ${decoded.runtimeType}.',
        );
      }
      final save = CareerSave.fromJson(decoded);
      return SafeCareerParseResult.success(save);
    } on FormatException catch (e) {
      return SafeCareerParseResult.failure('FormatException: ${e.message}');
    } on TypeError catch (e) {
      return SafeCareerParseResult.failure('TypeError: $e');
    } catch (e) {
      return SafeCareerParseResult.failure('Wyjątek deserializacji: $e');
    }
  }

  /// Uruchamia pełną kampanię fuzzowania serializacji stanu kariery.
  static Future<FuzzCampaignReport> runFuzzCampaign({
    FuzzCampaignConfig config = const FuzzCampaignConfig(),
    CareerSave? baseSave,
    void Function(double progress, String stageLabel)? onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();
    final effectiveStrategies = config.enabledStrategies.isEmpty
        ? FuzzMutationStrategy.values.toList()
        : config.enabledStrategies.toList();

    final CareerSave seedSave = baseSave ??
        (await InitialGameSeeder.seedNewGame(
          InitialGameSeedConfig(
            playerTeamId: 'wt_poland_project',
            seed: config.baseSeed,
            saveToDisk: false,
            additionalFreeAgentsCount: 8,
            scoutingProspectsCount: 6,
          ),
        ))
            .save;

    final enrichedSave = _enrichCareerSaveForFuzzing(seedSave, config.baseSeed);
    final results = <FuzzIterationResult>[];
    final coveredKeys = <String>{};
    int totalPathsChecked = 0;

    final int totalIterations = math.max(1, config.iterations);
    for (int i = 0; i < totalIterations; i++) {
      final strategy = effectiveStrategies[i % effectiveStrategies.length];
      final iterSeed = config.baseSeed + (i * 7919);
      onProgress?.call(
        (i + 1) / totalIterations,
        'Iteracja ${i + 1}/$totalIterations: ${strategy.labelPl}',
      );

      final result = _executeSingleIteration(
        iterationIndex: i + 1,
        seed: iterSeed,
        strategy: strategy,
        baseSave: enrichedSave,
        includeSubModels: config.includeSubModels,
        maxDiffs: config.maxDiffsPerCase,
        coveredKeys: coveredKeys,
      );
      totalPathsChecked += result.checkedPathsCount;
      results.add(result);
    }

    stopwatch.stop();
    int passedCount = 0;
    int gracefulErrorCount = 0;
    int diffCount = 0;
    int crashCount = 0;

    for (final r in results) {
      switch (r.outcome) {
        case FuzzCaseOutcome.passed:
          passedCount++;
          break;
        case FuzzCaseOutcome.handledGracefully:
          gracefulErrorCount++;
          break;
        case FuzzCaseOutcome.diffDetected:
          diffCount++;
          break;
        case FuzzCaseOutcome.crashed:
          crashCount++;
          break;
      }
    }

    return FuzzCampaignReport(
      config: config,
      totalIterations: totalIterations,
      passedCount: passedCount,
      gracefulErrorCount: gracefulErrorCount,
      diffCount: diffCount,
      crashCount: crashCount,
      totalPathsChecked: totalPathsChecked,
      uniqueKeysCovered: coveredKeys.length,
      durationMs: stopwatch.elapsedMilliseconds,
      results: List<FuzzIterationResult>.unmodifiable(results),
      generatedAt: DateTime.now(),
    );
  }

  /// Wzbogaca wygenerowany zapis o wpisy kontraktowe, finansowe i trofea,
  /// aby fuzzer przetestował wszystkie gałęzie drzewa `CareerSave`.
  static CareerSave _enrichCareerSaveForFuzzing(CareerSave save, int seed) {
    final now = save.currentDate;
    final sampleRider = save.riders.isNotEmpty ? save.riders.first : null;
    final sampleTeam = save.playerTeam;

    final offers = save.contractOffers.isNotEmpty
        ? save.contractOffers
        : [
            CareerContractOffer(
              offerId: 'fuzz_offer_$seed',
              riderId: sampleRider?.id ?? 'rider_fuzz_1',
              riderName: sampleRider?.fullName ?? 'Jan Kolarz',
              offeringTeamId: sampleTeam.id,
              offeringTeamName: sampleTeam.name,
              annualSalaryEur: 425000,
              contractDurationYears: 3,
              winBonusEur: 18500,
              proposedRole: RiderRole.teamLeader,
              status: ContractOfferStatus.pending,
              offeredDate: now,
              rejectionReason: null,
            ),
          ];

    final ledger = save.financeLedger.isNotEmpty
        ? save.financeLedger
        : [
            CareerFinanceLedgerEntry(
              id: 'fuzz_fin_$seed',
              date: now,
              category: FinanceCategory.sponsorPayout,
              amountEur: 1250000,
              description: 'Rata sponsorska WorldTour (Fuzz)',
            ),
          ];

    return save.copyWith(
      contractOffers: offers,
      financeLedger: ledger,
      trophiesWon: save.trophiesWon.isNotEmpty
          ? save.trophiesWon
          : const ['Tour de Pologne 2025', 'Mistrzostwo Polski ITT'],
    );
  }

  static FuzzIterationResult _executeSingleIteration({
    required int iterationIndex,
    required int seed,
    required FuzzMutationStrategy strategy,
    required CareerSave baseSave,
    required bool includeSubModels,
    required int maxDiffs,
    required Set<String> coveredKeys,
  }) {
    final sw = Stopwatch()..start();
    final rng = math.Random(seed);

    try {
      switch (strategy) {
        case FuzzMutationStrategy.cleanRoundTrip:
          return _runCleanRoundTrip(
            iterationIndex: iterationIndex,
            seed: seed,
            baseSave: baseSave,
            includeSubModels: includeSubModels,
            maxDiffs: maxDiffs,
            coveredKeys: coveredKeys,
            sw: sw,
          );
        case FuzzMutationStrategy.missingOptionalFields:
          return _runMissingOptionalFields(
            iterationIndex: iterationIndex,
            seed: seed,
            rng: rng,
            baseSave: baseSave,
            maxDiffs: maxDiffs,
            coveredKeys: coveredKeys,
            sw: sw,
          );
        case FuzzMutationStrategy.boundaryValues:
          return _runBoundaryValues(
            iterationIndex: iterationIndex,
            seed: seed,
            rng: rng,
            baseSave: baseSave,
            maxDiffs: maxDiffs,
            coveredKeys: coveredKeys,
            sw: sw,
          );
        case FuzzMutationStrategy.corruptedAndUnknownFields:
          return _runCorruptedAndUnknownFields(
            iterationIndex: iterationIndex,
            seed: seed,
            rng: rng,
            baseSave: baseSave,
            maxDiffs: maxDiffs,
            coveredKeys: coveredKeys,
            sw: sw,
          );
        case FuzzMutationStrategy.typeCoercion:
          return _runTypeCoercion(
            iterationIndex: iterationIndex,
            seed: seed,
            rng: rng,
            baseSave: baseSave,
            maxDiffs: maxDiffs,
            coveredKeys: coveredKeys,
            sw: sw,
          );
        case FuzzMutationStrategy.malformedJsonRecovery:
          return _runMalformedJsonRecovery(
            iterationIndex: iterationIndex,
            seed: seed,
            rng: rng,
            baseSave: baseSave,
            sw: sw,
          );
      }
    } catch (e) {
      sw.stop();
      return FuzzIterationResult(
        iterationIndex: iterationIndex,
        seed: seed,
        strategy: strategy,
        targetSection: 'CareerSave',
        outcome: FuzzCaseOutcome.crashed,
        durationMs: sw.elapsedMilliseconds,
        checkedPathsCount: 0,
        errorMessage: e.toString(),
      );
    }
  }

  static FuzzIterationResult _runCleanRoundTrip({
    required int iterationIndex,
    required int seed,
    required CareerSave baseSave,
    required bool includeSubModels,
    required int maxDiffs,
    required Set<String> coveredKeys,
    required Stopwatch sw,
  }) {
    final json1 = baseSave.toJson();
    final encoded1 = jsonEncode(json1);
    final decoded1 = jsonDecode(encoded1) as Map<String, dynamic>;
    final restored1 = CareerSave.fromJson(decoded1);
    final json2 = restored1.toJson();
    final encoded2 = jsonEncode(json2);
    final decoded2 = jsonDecode(encoded2) as Map<String, dynamic>;

    final diffs = <FuzzJsonDiff>[];
    final checked = compareJsonTrees(
      decoded1,
      decoded2,
      path: r'$',
      diffs: diffs,
      maxDiffs: maxDiffs,
      coveredKeys: coveredKeys,
    );

    int subModelPaths = 0;
    if (includeSubModels) {
      subModelPaths += _fuzzSupplementaryModels(
        seed: seed,
        baseSave: baseSave,
        diffs: diffs,
        maxDiffs: maxDiffs,
        coveredKeys: coveredKeys,
      );
    }

    sw.stop();
    return FuzzIterationResult(
      iterationIndex: iterationIndex,
      seed: seed,
      strategy: FuzzMutationStrategy.cleanRoundTrip,
      targetSection: includeSubModels
          ? 'CareerSave + ProCyclist + Settings'
          : 'CareerSave',
      outcome:
          diffs.isEmpty ? FuzzCaseOutcome.passed : FuzzCaseOutcome.diffDetected,
      durationMs: sw.elapsedMilliseconds,
      checkedPathsCount: checked + subModelPaths,
      diffs: diffs,
    );
  }

  static int _fuzzSupplementaryModels({
    required int seed,
    required CareerSave baseSave,
    required List<FuzzJsonDiff> diffs,
    required int maxDiffs,
    required Set<String> coveredKeys,
  }) {
    int totalPaths = 0;

    // 1. GameSettings round-trip
    const settings = GameSettings();
    final s1 = jsonDecode(jsonEncode(settings.toJson())) as Map<String, dynamic>;
    final sRestored = GameSettings.fromJson(s1);
    final s2 =
        jsonDecode(jsonEncode(sRestored.toJson())) as Map<String, dynamic>;
    totalPaths += compareJsonTrees(
      s1,
      s2,
      path: r'$.GameSettings',
      diffs: diffs,
      maxDiffs: maxDiffs,
      coveredKeys: coveredKeys,
    );

    // 2. ProCyclistCareerState round-trip (Paczka #4 Be a Pro)
    if (baseSave.riders.isNotEmpty) {
      final proState = ProCyclistCareerState.createNew(
        careerId: 'pro_fuzz_$seed',
        careerName: 'Kariera Pro Fuzzer',
        playerRider: baseSave.riders.first,
        startDate: baseSave.currentDate,
      );
      final p1 =
          jsonDecode(jsonEncode(proState.toJson())) as Map<String, dynamic>;
      final pRestored = ProCyclistCareerState.fromJson(p1);
      final p2 =
          jsonDecode(jsonEncode(pRestored.toJson())) as Map<String, dynamic>;
      totalPaths += compareJsonTrees(
        p1,
        p2,
        path: r'$.ProCyclistCareerState',
        diffs: diffs,
        maxDiffs: maxDiffs,
        coveredKeys: coveredKeys,
      );
    }

    return totalPaths;
  }

  static FuzzIterationResult _runMissingOptionalFields({
    required int iterationIndex,
    required int seed,
    required math.Random rng,
    required CareerSave baseSave,
    required int maxDiffs,
    required Set<String> coveredKeys,
    required Stopwatch sw,
  }) {
    final rawMap =
        jsonDecode(jsonEncode(baseSave.toJson())) as Map<String, dynamic>;

    final dropCount = 2 + rng.nextInt(5);
    final shuffledKeys = List<String>.from(_optionalCareerKeys)..shuffle(rng);
    final droppedKeys = shuffledKeys.take(dropCount).toList();
    for (final k in droppedKeys) {
      rawMap.remove(k);
    }

    // Usuwamy również opcjonalne pola w pierwszym kontrakcie jeśli istnieje
    final offers = rawMap['contractOffers'] as List<dynamic>?;
    if (offers != null && offers.isNotEmpty) {
      final firstOffer = offers.first as Map<String, dynamic>;
      firstOffer.remove('proposedRole');
      firstOffer.remove('rejectionReason');
    }

    final restored = CareerSave.fromJson(rawMap);
    final reSerialized1 =
        jsonDecode(jsonEncode(restored.toJson())) as Map<String, dynamic>;
    final restoredAgain = CareerSave.fromJson(reSerialized1);
    final reSerialized2 =
        jsonDecode(jsonEncode(restoredAgain.toJson())) as Map<String, dynamic>;

    final diffs = <FuzzJsonDiff>[];
    final checked = compareJsonTrees(
      reSerialized1,
      reSerialized2,
      path: r'$',
      diffs: diffs,
      maxDiffs: maxDiffs,
      coveredKeys: coveredKeys,
    );

    sw.stop();
    return FuzzIterationResult(
      iterationIndex: iterationIndex,
      seed: seed,
      strategy: FuzzMutationStrategy.missingOptionalFields,
      targetSection: 'Usunięto: ${droppedKeys.join(", ")}',
      outcome:
          diffs.isEmpty ? FuzzCaseOutcome.passed : FuzzCaseOutcome.diffDetected,
      durationMs: sw.elapsedMilliseconds,
      checkedPathsCount: checked,
      diffs: diffs,
    );
  }

  static FuzzIterationResult _runBoundaryValues({
    required int iterationIndex,
    required int seed,
    required math.Random rng,
    required CareerSave baseSave,
    required int maxDiffs,
    required Set<String> coveredKeys,
    required Stopwatch sw,
  }) {
    final unicodeName = _unicodeSamples[rng.nextInt(_unicodeSamples.length)];
    final mutatedSave = baseSave.copyWith(
      saveName: unicodeName.isEmpty ? 'Fuzz_Empty_Fallback' : unicodeName,
      playerManagerName: 'Menedżer #$seed 🚴',
      managerReputation: rng.nextBool() ? 0 : 100,
      serviceCourseLevel: rng.nextBool() ? 1 : 5,
      windTunnelLevel: rng.nextBool() ? 1 : 5,
      medicalCenterLevel: rng.nextBool() ? 1 : 5,
      currentSeasonYear: rng.nextBool() ? 1990 : 2099,
      trophiesWon: rng.nextBool()
          ? const []
          : [unicodeName, 'Wielki Tour — 100% / 1e-6'],
    );

    final json1 =
        jsonDecode(jsonEncode(mutatedSave.toJson())) as Map<String, dynamic>;
    final restored = CareerSave.fromJson(json1);
    final json2 =
        jsonDecode(jsonEncode(restored.toJson())) as Map<String, dynamic>;

    final diffs = <FuzzJsonDiff>[];
    final checked = compareJsonTrees(
      json1,
      json2,
      path: r'$',
      diffs: diffs,
      maxDiffs: maxDiffs,
      coveredKeys: coveredKeys,
    );

    sw.stop();
    return FuzzIterationResult(
      iterationIndex: iterationIndex,
      seed: seed,
      strategy: FuzzMutationStrategy.boundaryValues,
      targetSection: 'Granice & Unicode (${mutatedSave.currentSeasonYear})',
      outcome:
          diffs.isEmpty ? FuzzCaseOutcome.passed : FuzzCaseOutcome.diffDetected,
      durationMs: sw.elapsedMilliseconds,
      checkedPathsCount: checked,
      diffs: diffs,
    );
  }

  static FuzzIterationResult _runCorruptedAndUnknownFields({
    required int iterationIndex,
    required int seed,
    required math.Random rng,
    required CareerSave baseSave,
    required int maxDiffs,
    required Set<String> coveredKeys,
    required Stopwatch sw,
  }) {
    final rawMap =
        jsonDecode(jsonEncode(baseSave.toJson())) as Map<String, dynamic>;

    // Wstrzykujemy nieznane pola z przyszłej wersji schematu
    rawMap['__fuzz_future_schema_v99'] = {
      'nestedFlag': true,
      'values': [1, 2.5, null, 'legacy'],
    };
    rawMap['difficulty'] =
        rng.nextBool() ? 'HARD' : 'UNKNOWN_DIFFICULTY_FALLBACK';

    final offers = rawMap['contractOffers'] as List<dynamic>?;
    if (offers != null && offers.isNotEmpty) {
      final firstOffer = offers.first as Map<String, dynamic>;
      firstOffer['status'] = 'NON_EXISTENT_STATUS';
      firstOffer['__extraOfferMeta'] = 42;
    }

    final restored = CareerSave.fromJson(rawMap);
    final json1 =
        jsonDecode(jsonEncode(restored.toJson())) as Map<String, dynamic>;
    final restored2 = CareerSave.fromJson(json1);
    final json2 =
        jsonDecode(jsonEncode(restored2.toJson())) as Map<String, dynamic>;

    final diffs = <FuzzJsonDiff>[];
    final checked = compareJsonTrees(
      json1,
      json2,
      path: r'$',
      diffs: diffs,
      maxDiffs: maxDiffs,
      coveredKeys: coveredKeys,
    );

    sw.stop();
    return FuzzIterationResult(
      iterationIndex: iterationIndex,
      seed: seed,
      strategy: FuzzMutationStrategy.corruptedAndUnknownFields,
      targetSection: 'Unknown Keys & Enum Fallback',
      outcome:
          diffs.isEmpty ? FuzzCaseOutcome.passed : FuzzCaseOutcome.diffDetected,
      durationMs: sw.elapsedMilliseconds,
      checkedPathsCount: checked,
      diffs: diffs,
    );
  }

  static FuzzIterationResult _runTypeCoercion({
    required int iterationIndex,
    required int seed,
    required math.Random rng,
    required CareerSave baseSave,
    required int maxDiffs,
    required Set<String> coveredKeys,
    required Stopwatch sw,
  }) {
    final rawMap =
        jsonDecode(jsonEncode(baseSave.toJson())) as Map<String, dynamic>;

    // Zamieniamy wybrane int na double (symulacja JS/JSON number coercion)
    rawMap['currentSeasonYear'] =
        (rawMap['currentSeasonYear'] as num).toDouble();
    rawMap['managerReputation'] =
        (rawMap['managerReputation'] as num).toDouble();
    rawMap['serviceCourseLevel'] =
        (rawMap['serviceCourseLevel'] as num).toDouble();

    final squads = rawMap['dedicatedSquads'] as List<dynamic>?;
    if (squads != null && squads.isNotEmpty) {
      final firstSquad = squads.first as Map<String, dynamic>;
      firstSquad['chemistryScore'] = rng.nextBool() ? 85 : 85.0;
    }

    final restored = CareerSave.fromJson(rawMap);
    final json1 =
        jsonDecode(jsonEncode(restored.toJson())) as Map<String, dynamic>;
    final restored2 = CareerSave.fromJson(json1);
    final json2 =
        jsonDecode(jsonEncode(restored2.toJson())) as Map<String, dynamic>;

    final diffs = <FuzzJsonDiff>[];
    final checked = compareJsonTrees(
      json1,
      json2,
      path: r'$',
      diffs: diffs,
      maxDiffs: maxDiffs,
      coveredKeys: coveredKeys,
    );

    sw.stop();
    return FuzzIterationResult(
      iterationIndex: iterationIndex,
      seed: seed,
      strategy: FuzzMutationStrategy.typeCoercion,
      targetSection: 'Numeric int <-> double Coercion',
      outcome:
          diffs.isEmpty ? FuzzCaseOutcome.passed : FuzzCaseOutcome.diffDetected,
      durationMs: sw.elapsedMilliseconds,
      checkedPathsCount: checked,
      diffs: diffs,
    );
  }

  static FuzzIterationResult _runMalformedJsonRecovery({
    required int iterationIndex,
    required int seed,
    required math.Random rng,
    required CareerSave baseSave,
    required Stopwatch sw,
  }) {
    final fullJson = jsonEncode(baseSave.toJson());
    final int mode = rng.nextInt(5);
    late final String payload;
    late final String label;

    switch (mode) {
      case 0:
        final cutAt = math.min(fullJson.length ~/ 2, 240);
        payload = fullJson.substring(0, cutAt);
        label = 'Ucięty JSON ($cutAt znaków)';
        break;
      case 1:
        payload = '';
        label = 'Pusty string';
        break;
      case 2:
        payload = '[1, 2, 3, "not_an_object"]';
        label = 'Tablica zamiast obiektu';
        break;
      case 3:
        payload = '{"id": 12345, "saveName": null}';
        label = 'Niepoprawne typy pól wymaganych';
        break;
      default:
        payload = '{broken_json: : : [true';
        label = 'Błąd składni JSON';
        break;
    }

    final parseResult = tryParseCareerSaveSafe(payload);
    sw.stop();

    if (!parseResult.isSuccess && parseResult.errorMessage != null) {
      return FuzzIterationResult(
        iterationIndex: iterationIndex,
        seed: seed,
        strategy: FuzzMutationStrategy.malformedJsonRecovery,
        targetSection: label,
        outcome: FuzzCaseOutcome.handledGracefully,
        durationMs: sw.elapsedMilliseconds,
        checkedPathsCount: 1,
        errorMessage: parseResult.errorMessage,
      );
    }

    return FuzzIterationResult(
      iterationIndex: iterationIndex,
      seed: seed,
      strategy: FuzzMutationStrategy.malformedJsonRecovery,
      targetSection: label,
      outcome: FuzzCaseOutcome.diffDetected,
      durationMs: sw.elapsedMilliseconds,
      checkedPathsCount: 1,
      errorMessage: 'Uszkodzony JSON niespodziewanie przeszedł walidację.',
    );
  }

  /// Rekurencyjnie porównuje dwa zdekodowane drzewa JSON (Map/List/prymitywy)
  /// z tolerancją numeryczną dla liczb zmiennoprzecinkowych.
  static int compareJsonTrees(
    dynamic expected,
    dynamic actual, {
    required String path,
    required List<FuzzJsonDiff> diffs,
    int maxDiffs = 20,
    Set<String>? coveredKeys,
  }) {
    int checkedCount = 1;

    if (expected is Map && actual is Map) {
      for (final key in expected.keys) {
        final keyStr = key.toString();
        coveredKeys?.add(keyStr);
        final childPath = '$path.$keyStr';
        if (!actual.containsKey(key)) {
          if (diffs.length < maxDiffs) {
            diffs.add(
              FuzzJsonDiff(
                path: childPath,
                kind: FuzzDiffKind.missingKey,
                expectedSummary: _summarizeValue(expected[key]),
                actualSummary: '<brak>',
              ),
            );
          }
          continue;
        }
        checkedCount += compareJsonTrees(
          expected[key],
          actual[key],
          path: childPath,
          diffs: diffs,
          maxDiffs: maxDiffs,
          coveredKeys: coveredKeys,
        );
      }

      for (final key in actual.keys) {
        if (!expected.containsKey(key) && diffs.length < maxDiffs) {
          diffs.add(
            FuzzJsonDiff(
              path: '$path.${key.toString()}',
              kind: FuzzDiffKind.unexpectedKey,
              expectedSummary: '<brak>',
              actualSummary: _summarizeValue(actual[key]),
            ),
          );
        }
      }
      return checkedCount;
    }

    if (expected is List && actual is List) {
      if (expected.length != actual.length) {
        if (diffs.length < maxDiffs) {
          diffs.add(
            FuzzJsonDiff(
              path: path,
              kind: FuzzDiffKind.listLengthMismatch,
              expectedSummary: 'len=${expected.length}',
              actualSummary: 'len=${actual.length}',
            ),
          );
        }
        return checkedCount;
      }

      for (int i = 0; i < expected.length; i++) {
        checkedCount += compareJsonTrees(
          expected[i],
          actual[i],
          path: '$path[$i]',
          diffs: diffs,
          maxDiffs: maxDiffs,
          coveredKeys: coveredKeys,
        );
      }
      return checkedCount;
    }

    if (expected is num && actual is num) {
      final double diff = (expected.toDouble() - actual.toDouble()).abs();
      if (diff > 1e-6 || expected.isNaN || actual.isNaN) {
        if (diffs.length < maxDiffs) {
          diffs.add(
            FuzzJsonDiff(
              path: path,
              kind: FuzzDiffKind.valueMismatch,
              expectedSummary: expected.toString(),
              actualSummary: actual.toString(),
            ),
          );
        }
      }
      return checkedCount;
    }

    if (expected != actual) {
      if (diffs.length < maxDiffs) {
        diffs.add(
          FuzzJsonDiff(
            path: path,
            kind: expected.runtimeType != actual.runtimeType
                ? FuzzDiffKind.typeMismatch
                : FuzzDiffKind.valueMismatch,
            expectedSummary: _summarizeValue(expected),
            actualSummary: _summarizeValue(actual),
          ),
        );
      }
    }

    return checkedCount;
  }

  static String _summarizeValue(dynamic value) {
    if (value == null) return 'null';
    if (value is String) {
      return value.length > 40 ? '"${value.substring(0, 37)}..."' : '"$value"';
    }
    if (value is List) return 'List(${value.length})';
    if (value is Map) return 'Map(${value.length})';
    return value.toString();
  }
}

/// Stan kontrolera Riverpod dla panelu fuzzera serializacji.
@immutable
class FullStateSerializationFuzzState {
  final bool isRunning;
  final double progress;
  final String statusMessage;
  final FuzzCampaignConfig config;
  final FuzzCampaignReport? report;
  final FuzzOutcomeFilter outcomeFilter;
  final FuzzMutationStrategy? strategyFilter;
  final String? lastError;

  const FullStateSerializationFuzzState({
    this.isRunning = false,
    this.progress = 0.0,
    this.statusMessage = 'Gotowy do uruchomienia kampanii fuzzingu JSON.',
    this.config = const FuzzCampaignConfig(),
    this.report,
    this.outcomeFilter = FuzzOutcomeFilter.all,
    this.strategyFilter,
    this.lastError,
  });

  FullStateSerializationFuzzState copyWith({
    bool? isRunning,
    double? progress,
    String? statusMessage,
    FuzzCampaignConfig? config,
    FuzzCampaignReport? report,
    bool clearReport = false,
    FuzzOutcomeFilter? outcomeFilter,
    FuzzMutationStrategy? strategyFilter,
    bool clearStrategyFilter = false,
    String? lastError,
    bool clearError = false,
  }) {
    return FullStateSerializationFuzzState(
      isRunning: isRunning ?? this.isRunning,
      progress: progress ?? this.progress,
      statusMessage: statusMessage ?? this.statusMessage,
      config: config ?? this.config,
      report: clearReport ? null : (report ?? this.report),
      outcomeFilter: outcomeFilter ?? this.outcomeFilter,
      strategyFilter:
          clearStrategyFilter ? null : (strategyFilter ?? this.strategyFilter),
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }

  List<FuzzIterationResult> get filteredResults {
    final currentReport = report;
    if (currentReport == null) return const [];
    return currentReport.results.where((item) {
      if (strategyFilter != null && item.strategy != strategyFilter) {
        return false;
      }
      switch (outcomeFilter) {
        case FuzzOutcomeFilter.all:
          return true;
        case FuzzOutcomeFilter.issuesOnly:
          return !item.outcome.isHealthy;
        case FuzzOutcomeFilter.passedOnly:
          return item.outcome == FuzzCaseOutcome.passed;
        case FuzzOutcomeFilter.gracefulOnly:
          return item.outcome == FuzzCaseOutcome.handledGracefully;
      }
    }).toList();
  }
}

/// Notifier zarządzający kampaniami fuzzowania serializacji stanu kariery.
class FullStateSerializationFuzzNotifier
    extends StateNotifier<FullStateSerializationFuzzState> {
  FullStateSerializationFuzzNotifier()
      : super(const FullStateSerializationFuzzState());

  Future<void> runFuzzCampaign({CareerSave? customSave}) async {
    if (state.isRunning) return;
    state = state.copyWith(
      isRunning: true,
      progress: 0.0,
      statusMessage: 'Inicjalizacja świata gry i przygotowanie mutacji...',
      clearError: true,
    );

    try {
      final report = await FullStateSerializationFuzzTester.runFuzzCampaign(
        config: state.config,
        baseSave: customSave,
        onProgress: (progress, label) {
          if (!mounted) return;
          state = state.copyWith(
            progress: progress,
            statusMessage: label,
          );
        },
      );
      if (!mounted) return;
      state = state.copyWith(
        isRunning: false,
        progress: 1.0,
        report: report,
        statusMessage: report.isSuccess
            ? 'Zakończono pomyślnie: ${report.totalIterations} iteracji bez regresji.'
            : 'Wykryto ${report.diffCount + report.crashCount} problemów serializacji.',
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isRunning: false,
        lastError: e.toString(),
        statusMessage: 'Błąd kampanii fuzzingu: $e',
      );
    }
  }

  void setIterations(int iterations) {
    final clamped = iterations.clamp(6, 120);
    state = state.copyWith(
      config: state.config.copyWith(iterations: clamped),
    );
  }

  void setBaseSeed(int seed) {
    state = state.copyWith(
      config: state.config.copyWith(baseSeed: seed),
    );
  }

  void toggleStrategy(FuzzMutationStrategy strategy) {
    final next = Set<FuzzMutationStrategy>.from(state.config.enabledStrategies);
    if (next.contains(strategy)) {
      if (next.length > 1) {
        next.remove(strategy);
      }
    } else {
      next.add(strategy);
    }
    state = state.copyWith(
      config: state.config.copyWith(enabledStrategies: next),
    );
  }

  void setOutcomeFilter(FuzzOutcomeFilter filter) {
    state = state.copyWith(outcomeFilter: filter);
  }

  void setStrategyFilter(FuzzMutationStrategy? strategy) {
    if (strategy == null || strategy == state.strategyFilter) {
      state = state.copyWith(clearStrategyFilter: true);
    } else {
      state = state.copyWith(strategyFilter: strategy);
    }
  }

  void reset() {
    state = const FullStateSerializationFuzzState();
  }
}

/// Globalny provider Riverpod dla fuzzera serializacji stanu kariery.
final fullStateSerializationFuzzProvider = StateNotifierProvider<
    FullStateSerializationFuzzNotifier, FullStateSerializationFuzzState>(
  (ref) => FullStateSerializationFuzzNotifier(),
);

/// Produkcyjny panel diagnostyczny fuzzera serializacji stanu kariery JSON.
/// Responsywny dla 390x844 (mobile), 1024x768 (tablet) i 1600x900 (desktop).
class FullStateSerializationFuzzTesterPanel extends ConsumerStatefulWidget {
  final CareerSave? activeCareerSave;

  const FullStateSerializationFuzzTesterPanel({
    super.key,
    this.activeCareerSave,
  });

  @override
  ConsumerState<FullStateSerializationFuzzTesterPanel> createState() =>
      _FullStateSerializationFuzzTesterPanelState();
}

class _FullStateSerializationFuzzTesterPanelState
    extends ConsumerState<FullStateSerializationFuzzTesterPanel> {
  static const TextStyle _baseInter = TextStyle(
    fontFamily: 'Inter',
    letterSpacing: -0.2,
  );

  static const TextStyle _tabularInter = TextStyle(
    fontFamily: 'Inter',
    letterSpacing: -0.2,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  bool _copiedFeedback = false;

  Future<void> _copyReportToClipboard(FuzzCampaignReport report) async {
    await Clipboard.setData(
      ClipboardData(text: jsonEncode(report.toJson())),
    );
    if (!mounted) return;
    setState(() => _copiedFeedback = true);
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _copiedFeedback = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final fuzzState = ref.watch(fullStateSerializationFuzzProvider);
    final notifier = ref.read(fullStateSerializationFuzzProvider.notifier);

    return Container(
      color: AppColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final bool isCompact = width < 700;
          final bool isDesktopWide = width >= 1200;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isCompact ? 12 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderCard(fuzzState, notifier, isCompact),
                const SizedBox(height: 16),
                if (fuzzState.report != null) ...[
                  _buildKpiGrid(fuzzState.report!, isCompact, isDesktopWide),
                  const SizedBox(height: 16),
                ],
                if (isDesktopWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: _buildConfigAndStrategiesCard(
                          fuzzState,
                          notifier,
                          isCompact,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 7,
                        child: _buildResultsLogCard(fuzzState, notifier),
                      ),
                    ],
                  )
                else ...[
                  _buildConfigAndStrategiesCard(
                    fuzzState,
                    notifier,
                    isCompact,
                  ),
                  const SizedBox(height: 16),
                  _buildResultsLogCard(fuzzState, notifier),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(
    FullStateSerializationFuzzState fuzzState,
    FullStateSerializationFuzzNotifier notifier,
    bool isCompact,
  ) {
    final report = fuzzState.report;
    final Color statusColor = fuzzState.isRunning
        ? AppColors.accentBlue
        : report == null
            ? AppColors.goldAccent
            : report.isSuccess
                ? AppColors.statusSuccess
                : AppColors.crimsonAlert;

    return Container(
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Icon(
                      Icons.data_object_rounded,
                      color: statusColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fuzzer Serializacji Stanu Kariery JSON',
                          style: _baseInter.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: isCompact ? 16 : 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          fuzzState.statusMessage,
                          style: _baseInter.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (report != null)
                    _InteractiveFuzzActionButton(
                      label: _copiedFeedback ? 'Skopiowano JSON' : 'Kopiuj Raport',
                      icon: _copiedFeedback
                          ? Icons.check_rounded
                          : Icons.copy_all_rounded,
                      accentColor: AppColors.goldAccent,
                      isEnabled: !fuzzState.isRunning,
                      onPressed: () => _copyReportToClipboard(report),
                    ),
                  _InteractiveFuzzActionButton(
                    label: fuzzState.isRunning
                        ? 'Fuzzowanie...'
                        : 'Uruchom Fuzzing',
                    icon: fuzzState.isRunning
                        ? Icons.hourglass_top_rounded
                        : Icons.play_arrow_rounded,
                    accentColor: AppColors.primaryAccent,
                    isPrimary: true,
                    isEnabled: !fuzzState.isRunning,
                    onPressed: () => notifier.runFuzzCampaign(
                      customSave: widget.activeCareerSave,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (fuzzState.isRunning || fuzzState.progress > 0) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: fuzzState.progress.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: AppColors.surfaceLight,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildKpiGrid(
    FuzzCampaignReport report,
    bool isCompact,
    bool isDesktopWide,
  ) {
    final cards = [
      _FuzzKpiCard(
        label: 'ITERACJE / PASS RATE',
        value: '${report.totalIterations} (${(report.passRate * 100).toStringAsFixed(0)}%)',
        accentColor:
            report.isSuccess ? AppColors.statusSuccess : AppColors.crimsonAlert,
        icon: Icons.verified_rounded,
      ),
      _FuzzKpiCard(
        label: 'SPRAWDZONE ŚCIEŻKI',
        value: '${report.totalPathsChecked}',
        accentColor: AppColors.accentBlue,
        icon: Icons.account_tree_rounded,
      ),
      _FuzzKpiCard(
        label: 'POKRYTE KLUCZE JSON',
        value: '${report.uniqueKeysCovered}',
        accentColor: AppColors.goldAccent,
        icon: Icons.vpn_key_rounded,
      ),
      _FuzzKpiCard(
        label: 'RÓŻNICE / WYJĄTKI',
        value: '${report.diffCount} / ${report.crashCount}',
        accentColor: (report.diffCount + report.crashCount) == 0
            ? AppColors.statusSuccess
            : AppColors.crimsonAlert,
        icon: Icons.warning_amber_rounded,
      ),
    ];

    if (isDesktopWide) {
      return Row(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            Expanded(child: cards[i]),
            if (i < cards.length - 1) const SizedBox(width: 12),
          ],
        ],
      );
    }

    return GridView.count(
      crossAxisCount: isCompact ? 2 : 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: isCompact ? 1.85 : 2.1,
      children: cards,
    );
  }

  Widget _buildConfigAndStrategiesCard(
    FullStateSerializationFuzzState fuzzState,
    FullStateSerializationFuzzNotifier notifier,
    bool isCompact,
  ) {
    final config = fuzzState.config;
    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Konfiguracja & Strategie Mutacji',
            style: _baseInter.copyWith(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Liczba iteracji: ${config.iterations}',
                      style: _tabularInter.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: AppColors.primaryAccent,
                        inactiveTrackColor: AppColors.surfaceLight,
                        thumbColor: AppColors.goldAccent,
                        overlayColor:
                            AppColors.goldAccent.withValues(alpha: 0.2),
                      ),
                      child: Slider(
                        value: config.iterations.toDouble(),
                        min: 6,
                        max: 60,
                        divisions: 9,
                        onChanged: fuzzState.isRunning
                            ? null
                            : (v) => notifier.setIterations(v.round()),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _InteractiveFuzzActionButton(
                label: 'Seed #${config.baseSeed}',
                icon: Icons.casino_rounded,
                accentColor: AppColors.accentBlue,
                isEnabled: !fuzzState.isRunning,
                onPressed: () =>
                    notifier.setBaseSeed(config.baseSeed + 101),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: FuzzMutationStrategy.values.map((strategy) {
              final enabled = config.enabledStrategies.contains(strategy);
              return _InteractiveStrategyChip(
                strategy: strategy,
                isSelected: enabled,
                isDisabled: fuzzState.isRunning,
                onTap: () => notifier.toggleStrategy(strategy),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsLogCard(
    FullStateSerializationFuzzState fuzzState,
    FullStateSerializationFuzzNotifier notifier,
  ) {
    final results = fuzzState.filteredResults;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Dziennik Iteracji Fuzzera (${results.length})',
                style: _tabularInter.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: FuzzOutcomeFilter.values.map((filter) {
                  return _InteractiveFilterPill(
                    label: filter.labelPl,
                    isSelected: fuzzState.outcomeFilter == filter,
                    onTap: () => notifier.setOutcomeFilter(filter),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (fuzzState.report == null)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Center(
                child: Text(
                  'Kliknij „Uruchom Fuzzing”, aby przetestować serializację pełnego stanu kariery JSON.',
                  textAlign: TextAlign.center,
                  style: _baseInter.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else if (results.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Center(
                child: Text(
                  'Brak iteracji spełniających wybrane kryteria filtra.',
                  style: _baseInter.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: results.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) =>
                  _buildIterationRow(results[index]),
            ),
        ],
      ),
    );
  }

  Widget _buildIterationRow(FuzzIterationResult item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.outcome.color.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.strategy.icon,
                    size: 16,
                    color: item.strategy.accentColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '#${item.iterationIndex} • ${item.strategy.labelPl}',
                    style: _tabularInter.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: item.outcome.color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: item.outcome.color.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  item.outcome.labelPl,
                  style: _baseInter.copyWith(
                    color: item.outcome.color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Sekcja: ${item.targetSection} • Ścieżki: ${item.checkedPathsCount} • ${item.durationMs}ms • Seed: ${item.seed}',
            style: _tabularInter.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          if (item.errorMessage != null) ...[
            const SizedBox(height: 6),
            Text(
              item.errorMessage!,
              style: _baseInter.copyWith(
                color: item.outcome == FuzzCaseOutcome.handledGracefully
                    ? AppColors.accentBlue
                    : AppColors.crimsonAlert,
                fontSize: 12,
              ),
            ),
          ],
          if (item.diffs.isNotEmpty) ...[
            const SizedBox(height: 6),
            for (final diff in item.diffs.take(3))
              Text(
                '• $diff',
                style: _baseInter.copyWith(
                  color: AppColors.amberWarning,
                  fontSize: 11.5,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _FuzzKpiCard extends StatelessWidget {
  final String label;
  final String value;
  final Color accentColor;
  final IconData icon;

  const _FuzzKpiCard({
    required this.label,
    required this.value,
    required this.accentColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: accentColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    letterSpacing: -0.2,
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              letterSpacing: -0.2,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: accentColor,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractiveFuzzActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final bool isPrimary;
  final bool isEnabled;
  final VoidCallback onPressed;

  const _InteractiveFuzzActionButton({
    required this.label,
    required this.icon,
    required this.accentColor,
    this.isPrimary = false,
    this.isEnabled = true,
    required this.onPressed,
  });

  @override
  State<_InteractiveFuzzActionButton> createState() =>
      _InteractiveFuzzActionButtonState();
}

class _InteractiveFuzzActionButtonState
    extends State<_InteractiveFuzzActionButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.isEnabled;
    final Color bg = !enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.45)
        : widget.isPrimary
            ? (_pressed
                ? widget.accentColor.withValues(alpha: 0.78)
                : _hovered
                    ? widget.accentColor.withValues(alpha: 0.92)
                    : widget.accentColor)
            : (_pressed
                ? widget.accentColor.withValues(alpha: 0.24)
                : _hovered
                    ? widget.accentColor.withValues(alpha: 0.16)
                    : AppColors.surfaceLight);

    final Color border = !enabled
        ? AppColors.cardBorder.withValues(alpha: 0.5)
        : _focused
            ? AppColors.goldAccent
            : widget.isPrimary
                ? widget.accentColor
                : (_hovered ? widget.accentColor : AppTheme.borderColor);

    final Color fg = !enabled
        ? AppColors.textSecondary.withValues(alpha: 0.5)
        : widget.isPrimary
            ? AppColors.textPrimary
            : widget.accentColor;

    return FocusableActionDetector(
      enabled: enabled,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      mouseCursor:
          enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: _focused ? 1.5 : 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 16, color: fg),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  letterSpacing: -0.2,
                  color: fg,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InteractiveStrategyChip extends StatefulWidget {
  final FuzzMutationStrategy strategy;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  const _InteractiveStrategyChip({
    required this.strategy,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  State<_InteractiveStrategyChip> createState() =>
      _InteractiveStrategyChipState();
}

class _InteractiveStrategyChipState extends State<_InteractiveStrategyChip> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.strategy.accentColor;
    final enabled = !widget.isDisabled;
    final Color bg = !enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : widget.isSelected
            ? (_pressed
                ? accent.withValues(alpha: 0.28)
                : _hovered
                    ? accent.withValues(alpha: 0.22)
                    : accent.withValues(alpha: 0.14))
            : (_hovered ? AppColors.surfaceLight : AppColors.background);

    final Color border = _focused
        ? AppColors.goldAccent
        : widget.isSelected
            ? accent.withValues(alpha: 0.7)
            : (_hovered ? AppColors.textSecondary : AppTheme.borderColor);

    return FocusableActionDetector(
      enabled: enabled,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      mouseCursor:
          enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border, width: _focused ? 1.5 : 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.strategy.icon,
                size: 14,
                color: widget.isSelected ? accent : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  widget.strategy.labelPl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    letterSpacing: -0.2,
                    color: widget.isSelected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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

class _InteractiveFilterPill extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _InteractiveFilterPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_InteractiveFilterPill> createState() => _InteractiveFilterPillState();
}

class _InteractiveFilterPillState extends State<_InteractiveFilterPill> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isSelected
        ? AppColors.primaryAccent
        : (_hovered ? AppColors.surfaceLight : AppColors.background);
    final border = _focused
        ? AppColors.goldAccent
        : (widget.isSelected ? AppColors.primaryAccent : AppTheme.borderColor);

    return FocusableActionDetector(
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      mouseCursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border, width: 1),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              letterSpacing: -0.2,
              color: widget.isSelected
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
