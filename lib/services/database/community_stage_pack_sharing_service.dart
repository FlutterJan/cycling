// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/career/season_calendar.dart';
import '../../models/race/race_stage.dart';
import '../../models/race/tour_race.dart';
import '../../state/career_controller.dart';

/// Rozszerzenie pliku paczki tras społecznościowych Pro Peloton Manager.
const String kPpmStageFileExtension = '.ppmstage';

/// Nagłówek formatu pliku `.ppmstage`.
const String kPpmStageFormatMagic = 'PPMSTAGE_V1';

/// Prefiks skompresowanego strumienia GZip Base64 w pliku `.ppmstage`.
const String kPpmStageGzipPrefix = 'PPMSTAGE_GZ_V1:';

/// Bieżąca wersja schematu `.ppmstage`.
const int kPpmStageSchemaVersion = 1;

/// Rodzaj wyścigu zawartego w paczce `.ppmstage`.
enum CommunityStagePackKind {
  oneDayRace,
  stageRace,
  grandTour21;

  String toJson() => name;

  static CommunityStagePackKind fromJson(String value) {
    return CommunityStagePackKind.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CommunityStagePackKind.oneDayRace,
    );
  }

  String get labelPl {
    switch (this) {
      case CommunityStagePackKind.oneDayRace:
        return 'Wyścig jednodniowy';
      case CommunityStagePackKind.stageRace:
        return 'Wyścig etapowy';
      case CommunityStagePackKind.grandTour21:
        return 'Grand Tour (21 etapów)';
    }
  }
}

/// Ważność komunikatu walidacji paczki `.ppmstage`.
enum StagePackIssueSeverity {
  info,
  warning,
  error,
}

/// Pojedynczy problem wykryty podczas walidacji pliku `.ppmstage`.
class CommunityStagePackIssue {
  final String code;
  final String path;
  final String message;
  final StagePackIssueSeverity severity;

  const CommunityStagePackIssue({
    required this.code,
    required this.path,
    required this.message,
    required this.severity,
  });

  Map<String, dynamic> toJson() => {
        'code': code,
        'path': path,
        'message': message,
        'severity': severity.name,
      };

  factory CommunityStagePackIssue.fromJson(Map<String, dynamic> json) {
    return CommunityStagePackIssue(
      code: json['code'] as String? ?? 'UNKNOWN',
      path: json['path'] as String? ?? '',
      message: json['message'] as String? ?? '',
      severity: StagePackIssueSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => StagePackIssueSeverity.warning,
      ),
    );
  }
}

/// Podsumowanie telemetryczne i wynik walidacji paczki `.ppmstage`.
class CommunityStagePackValidationReport {
  final bool isValid;
  final int stageCount;
  final int segmentCount;
  final double totalDistanceKm;
  final double totalElevationGainM;
  final int cobbleSegmentCount;
  final int komClimbCount;
  final int timeTrialStageCount;
  final List<CommunityStagePackIssue> issues;

  const CommunityStagePackValidationReport({
    required this.isValid,
    required this.stageCount,
    required this.segmentCount,
    required this.totalDistanceKm,
    required this.totalElevationGainM,
    required this.cobbleSegmentCount,
    required this.komClimbCount,
    required this.timeTrialStageCount,
    required this.issues,
  });

  List<CommunityStagePackIssue> get errors =>
      issues.where((i) => i.severity == StagePackIssueSeverity.error).toList();

  List<CommunityStagePackIssue> get warnings =>
      issues.where((i) => i.severity == StagePackIssueSeverity.warning).toList();
}

/// Metadane paczki trasy stworzonej w Kreatorze Etapów.
class CommunityStagePackMetadata {
  final String packId;
  final String title;
  final String author;
  final String description;
  final String version;
  final DateTime createdAt;
  final CommunityStagePackKind packKind;
  final List<String> tags;

  const CommunityStagePackMetadata({
    required this.packId,
    required this.title,
    required this.author,
    required this.description,
    required this.version,
    required this.createdAt,
    required this.packKind,
    this.tags = const [],
  });

  CommunityStagePackMetadata copyWith({
    String? packId,
    String? title,
    String? author,
    String? description,
    String? version,
    DateTime? createdAt,
    CommunityStagePackKind? packKind,
    List<String>? tags,
  }) {
    return CommunityStagePackMetadata(
      packId: packId ?? this.packId,
      title: title ?? this.title,
      author: author ?? this.author,
      description: description ?? this.description,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      packKind: packKind ?? this.packKind,
      tags: tags != null ? List<String>.unmodifiable(tags) : this.tags,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'packId': packId,
      'title': title,
      'author': author,
      'description': description,
      'version': version,
      'createdAt': createdAt.toIso8601String(),
      'packKind': packKind.toJson(),
      'tags': tags,
    };
  }

  factory CommunityStagePackMetadata.fromJson(Map<String, dynamic> json) {
    return CommunityStagePackMetadata(
      packId: json['packId'] as String? ?? 'pack_unknown',
      title: json['title'] as String? ?? 'Custom Stage Pack',
      author: json['author'] as String? ?? 'Community Creator',
      description: json['description'] as String? ?? '',
      version: json['version'] as String? ?? '1.0.0',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      packKind: CommunityStagePackKind.fromJson(
        json['packKind'] as String? ?? 'oneDayRace',
      ),
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}

/// Kompletny model paczki `.ppmstage` zawierający metadane oraz definicję wyścigu `TourRace`.
class CommunityStagePack {
  final String formatMagic;
  final int schemaVersion;
  final CommunityStagePackMetadata metadata;
  final TourRace race;
  final String checksumFnv1a64;

  const CommunityStagePack({
    this.formatMagic = kPpmStageFormatMagic,
    this.schemaVersion = kPpmStageSchemaVersion,
    required this.metadata,
    required this.race,
    required this.checksumFnv1a64,
  });

  CommunityStagePack copyWith({
    String? formatMagic,
    int? schemaVersion,
    CommunityStagePackMetadata? metadata,
    TourRace? race,
    String? checksumFnv1a64,
  }) {
    return CommunityStagePack(
      formatMagic: formatMagic ?? this.formatMagic,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      metadata: metadata ?? this.metadata,
      race: race ?? this.race,
      checksumFnv1a64: checksumFnv1a64 ?? this.checksumFnv1a64,
    );
  }

  Map<String, dynamic> toPayloadMap() {
    return {
      'schemaVersion': schemaVersion,
      'metadata': metadata.toJson(),
      'race': race.toJson(),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'formatMagic': formatMagic,
      'schemaVersion': schemaVersion,
      'checksumFnv1a64': checksumFnv1a64,
      'metadata': metadata.toJson(),
      'race': race.toJson(),
    };
  }
}

/// Wynik parsowania i weryfikacji pliku `.ppmstage`.
class CommunityStagePackParseResult {
  final bool success;
  final CommunityStagePack? pack;
  final CommunityStagePackValidationReport? validation;
  final bool checksumVerified;
  final bool wasCompressed;
  final String? errorMessage;

  const CommunityStagePackParseResult({
    required this.success,
    this.pack,
    this.validation,
    required this.checksumVerified,
    required this.wasCompressed,
    this.errorMessage,
  });
}

/// Potwierdzenie zapisu pliku `.ppmstage` na dysku.
class StagePackFileReceipt {
  final String filePath;
  final int bytesWritten;
  final bool compressed;
  final String checksumFnv1a64;
  final CommunityStagePackValidationReport validation;

  const StagePackFileReceipt({
    required this.filePath,
    required this.bytesWritten,
    required this.compressed,
    required this.checksumFnv1a64,
    required this.validation,
  });
}

/// Skrócona informacja o pliku `.ppmstage` znalezionym w katalogu.
class StagePackFileSummary {
  final String filePath;
  final String fileName;
  final int fileSizeBytes;
  final String title;
  final String author;
  final CommunityStagePackKind packKind;
  final int stageCount;
  final double totalDistanceKm;
  final bool isValid;

  const StagePackFileSummary({
    required this.filePath,
    required this.fileName,
    required this.fileSizeBytes,
    required this.title,
    required this.author,
    required this.packKind,
    required this.stageCount,
    required this.totalDistanceKm,
    required this.isValid,
  });
}

/// Wynik wstawienia zaimportowanego wyścigu do kalendarza kariery `SeasonCalendar`.
class SeasonCalendarImportResult {
  final SeasonCalendar updatedCalendar;
  final TourRace insertedRace;
  final bool replacedExisting;
  final int insertedIndex;

  const SeasonCalendarImportResult({
    required this.updatedCalendar,
    required this.insertedRace,
    required this.replacedExisting,
    required this.insertedIndex,
  });
}

/// Wynik pełnego importu pliku `.ppmstage` do aktywnej kariery.
class CareerCalendarImportOutcome {
  final bool success;
  final TourRace? importedRace;
  final CommunityStagePack? pack;
  final String message;

  const CareerCalendarImportOutcome({
    required this.success,
    this.importedRace,
    this.pack,
    required this.message,
  });
}

/// Serwis eksportu i importu własnych tras stworzonych w Kreatorze Etapów
/// jako pojedyncze pliki `.ppmstage` oraz bezpośredniego wczytywania do kalendarza kariery.
class CommunityStagePackSharingService {
  const CommunityStagePackSharingService();

  /// Wylicza deterministyczną 64-bitową sumę kontrolną FNV-1a (hex 16 znaków).
  static String computeFnv1a64Hex(String input) {
    final BigInt fnvOffsetBasis = BigInt.parse('cbf29ce484222325', radix: 16);
    final BigInt fnvPrime = BigInt.parse('100000001b3', radix: 16);
    final BigInt mask64 = BigInt.parse('ffffffffffffffff', radix: 16);

    BigInt hash = fnvOffsetBasis;
    final bytes = utf8.encode(input);
    for (final b in bytes) {
      hash = (hash ^ BigInt.from(b)) & mask64;
      hash = (hash * fnvPrime) & mask64;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }

  /// Tworzy paczkę `.ppmstage` z istniejącego obiektu `TourRace` (1-dniowy lub 21-etapowy Tour).
  CommunityStagePack createPackFromTourRace({
    required TourRace race,
    String author = 'Manager Community',
    String description = '',
    String version = '1.0.0',
    List<String> tags = const [],
    DateTime? createdAt,
  }) {
    final kind = _inferPackKind(race);
    final sanitizedId = _sanitizeSlug(race.id.isNotEmpty ? race.id : race.name);
    final packId = 'ppm_${sanitizedId}_${race.stages.length}s';

    final metadata = CommunityStagePackMetadata(
      packId: packId,
      title: race.name.trim().isEmpty ? 'Custom Race' : race.name.trim(),
      author: author.trim().isEmpty ? 'Manager Community' : author.trim(),
      description: description.trim().isNotEmpty
          ? description.trim()
          : '${kind.labelPl} • ${race.stages.length} etap(ów) • '
              '${race.totalRaceDistanceKm.toStringAsFixed(1)} km',
      version: version.trim().isEmpty ? '1.0.0' : version.trim(),
      createdAt: createdAt ?? DateTime.now().toUtc(),
      packKind: kind,
      tags: tags.isNotEmpty
          ? tags
          : <String>[
              kind.name,
              race.countryIso.toUpperCase(),
              race.uciCategory.name,
            ],
    );

    final draft = CommunityStagePack(
      formatMagic: kPpmStageFormatMagic,
      schemaVersion: kPpmStageSchemaVersion,
      metadata: metadata,
      race: race,
      checksumFnv1a64: '',
    );
    final checksum = computeFnv1a64Hex(jsonEncode(draft.toPayloadMap()));
    return draft.copyWith(checksumFnv1a64: checksum);
  }

  /// Tworzy paczkę `.ppmstage` dla pojedynczego wyścigu jednodniowego na bazie `RaceStage`.
  CommunityStagePack createOneDayPackFromStage({
    required RaceStage stage,
    required String raceName,
    String countryIso = 'POL',
    RaceCategory uciCategory = RaceCategory.worldTourOneDay,
    int startMonth = 4,
    int startDay = 15,
    int prizePoolEur = 85000,
    String author = 'Manager Community',
    String description = '',
    List<String> tags = const [],
  }) {
    final normalizedStage = stage.copyWith(stageNumber: 1);
    final raceId =
        'custom_1d_${_sanitizeSlug(raceName)}_${startMonth}_$startDay';
    final tourRace = TourRace(
      id: raceId,
      name: raceName.trim().isEmpty ? normalizedStage.name : raceName.trim(),
      countryIso: countryIso.trim().isEmpty ? 'POL' : countryIso.toUpperCase(),
      uciCategory: uciCategory,
      startMonth: startMonth.clamp(1, 12),
      startDay: startDay.clamp(1, 31),
      stages: [normalizedStage],
      prizePoolEur: prizePoolEur < 0 ? 0 : prizePoolEur,
      participatingTeamIds: const [],
      ridersPerTeam: 7,
      classifications: const RaceClassifications(
        generalClassification: [],
        pointsClassification: [],
        mountainsClassification: [],
        youthClassification: [],
        teamClassification: [],
      ),
    );
    return createPackFromTourRace(
      race: tourRace,
      author: author,
      description: description,
      tags: tags,
    );
  }

  /// Waliduje strukturę, etapy i segmenty paczki `.ppmstage`.
  CommunityStagePackValidationReport validatePack(CommunityStagePack pack) {
    final issues = <CommunityStagePackIssue>[];

    if (pack.formatMagic != kPpmStageFormatMagic) {
      issues.add(
        CommunityStagePackIssue(
          code: 'INVALID_MAGIC',
          path: 'formatMagic',
          message: 'Nieprawidłowy nagłówek formatu: ${pack.formatMagic}.',
          severity: StagePackIssueSeverity.error,
        ),
      );
    }

    if (pack.schemaVersion > kPpmStageSchemaVersion || pack.schemaVersion < 1) {
      issues.add(
        CommunityStagePackIssue(
          code: 'UNSUPPORTED_SCHEMA',
          path: 'schemaVersion',
          message: 'Nieobsługiwana wersja schematu: v${pack.schemaVersion}.',
          severity: StagePackIssueSeverity.error,
        ),
      );
    }

    final race = pack.race;
    if (race.name.trim().isEmpty) {
      issues.add(
        const CommunityStagePackIssue(
          code: 'EMPTY_RACE_NAME',
          path: 'race.name',
          message: 'Nazwa wyścigu nie może być pusta.',
          severity: StagePackIssueSeverity.error,
        ),
      );
    }

    if (race.startMonth < 1 || race.startMonth > 12) {
      issues.add(
        CommunityStagePackIssue(
          code: 'INVALID_START_MONTH',
          path: 'race.startMonth',
          message: 'Miesiąc startu (${race.startMonth}) musi mieścić się w 1–12.',
          severity: StagePackIssueSeverity.error,
        ),
      );
    }

    if (race.startDay < 1 || race.startDay > 31) {
      issues.add(
        CommunityStagePackIssue(
          code: 'INVALID_START_DAY',
          path: 'race.startDay',
          message: 'Dzień startu (${race.startDay}) musi mieścić się w 1–31.',
          severity: StagePackIssueSeverity.error,
        ),
      );
    }

    if (race.stages.isEmpty) {
      issues.add(
        const CommunityStagePackIssue(
          code: 'NO_STAGES',
          path: 'race.stages',
          message: 'Wyścig musi zawierać przynajmniej 1 etap.',
          severity: StagePackIssueSeverity.error,
        ),
      );
    }

    if (pack.metadata.packKind == CommunityStagePackKind.grandTour21 &&
        race.stages.length != 21) {
      issues.add(
        CommunityStagePackIssue(
          code: 'GRAND_TOUR_STAGE_COUNT',
          path: 'race.stages.length',
          message:
              'Paczka oznaczona jako Grand Tour 21 ma ${race.stages.length} etapów.',
          severity: StagePackIssueSeverity.warning,
        ),
      );
    }

    int segmentCount = 0;
    double totalDist = 0.0;
    double totalGain = 0.0;
    int cobbleCount = 0;
    int komCount = 0;
    int ttCount = 0;

    for (int sIdx = 0; sIdx < race.stages.length; sIdx++) {
      final stage = race.stages[sIdx];
      if (stage.isTimeTrial) {
        ttCount++;
      }
      if (stage.segments.isEmpty) {
        issues.add(
          CommunityStagePackIssue(
            code: 'EMPTY_STAGE_SEGMENTS',
            path: 'race.stages[$sIdx].segments',
            message: 'Etap #${stage.stageNumber} (${stage.name}) nie ma segmentów.',
            severity: StagePackIssueSeverity.error,
          ),
        );
        continue;
      }

      double expectedKm = 0.0;
      for (int segIdx = 0; segIdx < stage.segments.length; segIdx++) {
        final seg = stage.segments[segIdx];
        segmentCount++;
        if (seg.lengthKm <= 0.0) {
          issues.add(
            CommunityStagePackIssue(
              code: 'NON_POSITIVE_SEGMENT_LENGTH',
              path: 'race.stages[$sIdx].segments[$segIdx].lengthKm',
              message:
                  'Segment $segIdx etapu #${stage.stageNumber} ma długość <= 0 km.',
              severity: StagePackIssueSeverity.error,
            ),
          );
        }
        if ((seg.startKm - expectedKm).abs() > 0.25) {
          issues.add(
            CommunityStagePackIssue(
              code: 'DISCONTINUOUS_START_KM',
              path: 'race.stages[$sIdx].segments[$segIdx].startKm',
              message:
                  'Nieciągłość kilometrażu na etapie #${stage.stageNumber} (oczekiwano ~${expectedKm.toStringAsFixed(1)} km, jest ${seg.startKm.toStringAsFixed(1)} km).',
              severity: StagePackIssueSeverity.warning,
            ),
          );
        }
        expectedKm = seg.startKm + seg.lengthKm;
        totalDist += seg.lengthKm;
        totalGain += seg.elevationGainM;
        if (seg.isCobblestone) cobbleCount++;
        if (seg.isKom) komCount++;
      }
    }

    final hasErrors =
        issues.any((i) => i.severity == StagePackIssueSeverity.error);

    return CommunityStagePackValidationReport(
      isValid: !hasErrors,
      stageCount: race.stages.length,
      segmentCount: segmentCount,
      totalDistanceKm: totalDist,
      totalElevationGainM: totalGain,
      cobbleSegmentCount: cobbleCount,
      komClimbCount: komCount,
      timeTrialStageCount: ttCount,
      issues: List<CommunityStagePackIssue>.unmodifiable(issues),
    );
  }

  /// Serializuje paczkę `CommunityStagePack` do zawartości pliku `.ppmstage`.
  String serializePackToPpmStage(
    CommunityStagePack pack, {
    bool compressGzip = false,
    bool pretty = true,
  }) {
    final payloadChecksum = computeFnv1a64Hex(jsonEncode(pack.toPayloadMap()));
    final normalized = pack.copyWith(checksumFnv1a64: payloadChecksum);
    final jsonString = pretty
        ? const JsonEncoder.withIndent('  ').convert(normalized.toJson())
        : jsonEncode(normalized.toJson());

    if (!compressGzip) {
      return jsonString;
    }

    final compressed = gzip.encode(utf8.encode(jsonString));
    return '$kPpmStageGzipPrefix${base64Encode(compressed)}';
  }

  /// Parsuje i weryfikuje zawartość tekstową pliku `.ppmstage` (JSON lub GZip Base64).
  CommunityStagePackParseResult parsePpmStageContent(String rawContent) {
    final trimmed = rawContent.trim();
    if (trimmed.isEmpty) {
      return const CommunityStagePackParseResult(
        success: false,
        checksumVerified: false,
        wasCompressed: false,
        errorMessage: 'Plik .ppmstage jest pusty.',
      );
    }

    bool wasCompressed = false;
    String jsonText = trimmed;

    try {
      if (trimmed.startsWith(kPpmStageGzipPrefix)) {
        wasCompressed = true;
        final b64 = trimmed.substring(kPpmStageGzipPrefix.length).trim();
        final decodedBytes = gzip.decode(base64Decode(b64));
        jsonText = utf8.decode(decodedBytes);
      }

      final dynamic decoded = jsonDecode(jsonText);
      if (decoded is! Map<String, dynamic>) {
        return CommunityStagePackParseResult(
          success: false,
          checksumVerified: false,
          wasCompressed: wasCompressed,
          errorMessage: 'Nieprawidłowy format JSON w pliku .ppmstage.',
        );
      }

      final magic = decoded['formatMagic'] as String? ?? '';
      if (magic != kPpmStageFormatMagic) {
        return CommunityStagePackParseResult(
          success: false,
          checksumVerified: false,
          wasCompressed: wasCompressed,
          errorMessage:
              'Nieznany nagłówek paczki ($magic). Oczekiwano $kPpmStageFormatMagic.',
        );
      }

      final schemaVersion = (decoded['schemaVersion'] as num?)?.toInt() ?? 0;
      final storedChecksum = decoded['checksumFnv1a64'] as String? ?? '';
      final metadataJson = decoded['metadata'] as Map<String, dynamic>?;
      final raceJson = decoded['race'] as Map<String, dynamic>?;

      if (metadataJson == null || raceJson == null) {
        return CommunityStagePackParseResult(
          success: false,
          checksumVerified: false,
          wasCompressed: wasCompressed,
          errorMessage: 'Brak sekcji metadata lub race w pliku .ppmstage.',
        );
      }

      final metadata = CommunityStagePackMetadata.fromJson(metadataJson);
      final race = TourRace.fromJson(raceJson);

      final pack = CommunityStagePack(
        formatMagic: magic,
        schemaVersion: schemaVersion,
        metadata: metadata,
        race: race,
        checksumFnv1a64: storedChecksum,
      );

      final expectedChecksum =
          computeFnv1a64Hex(jsonEncode(pack.toPayloadMap()));
      final checksumOk = storedChecksum.isNotEmpty &&
          storedChecksum.toLowerCase() == expectedChecksum.toLowerCase();

      final validation = validatePack(pack);
      if (!checksumOk) {
        return CommunityStagePackParseResult(
          success: false,
          pack: pack,
          validation: validation,
          checksumVerified: false,
          wasCompressed: wasCompressed,
          errorMessage:
              'Niezgodność sumy kontrolnej FNV-1a64 (plik uszkodzony lub zmodyfikowany).',
        );
      }

      return CommunityStagePackParseResult(
        success: validation.isValid,
        pack: pack,
        validation: validation,
        checksumVerified: true,
        wasCompressed: wasCompressed,
        errorMessage: validation.isValid
            ? null
            : validation.errors.map((e) => e.message).join(' '),
      );
    } on FormatException catch (e) {
      return CommunityStagePackParseResult(
        success: false,
        checksumVerified: false,
        wasCompressed: wasCompressed,
        errorMessage: 'Błąd dekodowania pliku .ppmstage: ${e.message}',
      );
    } catch (e) {
      return CommunityStagePackParseResult(
        success: false,
        checksumVerified: false,
        wasCompressed: wasCompressed,
        errorMessage: 'Nieoczekiwany błąd odczytu .ppmstage: $e',
      );
    }
  }

  /// Zapisuje paczkę `.ppmstage` atomowo na dysk (z rozszerzeniem `.ppmstage`).
  Future<StagePackFileReceipt> exportToFile(
    CommunityStagePack pack,
    String filePath, {
    bool compressGzip = false,
  }) async {
    final validation = validatePack(pack);
    if (!validation.isValid) {
      throw ArgumentError(
        'Nie można wyeksportować nieprawidłowej paczki: '
        '${validation.errors.map((e) => e.message).join('; ')}',
      );
    }

    final targetPath = ensurePpmStageExtension(filePath);
    final content = serializePackToPpmStage(
      pack,
      compressGzip: compressGzip,
      pretty: !compressGzip,
    );
    final bytes = utf8.encode(content);

    final targetFile = File(targetPath);
    await targetFile.parent.create(recursive: true);

    final tmpFile = File('$targetPath.tmp');
    await tmpFile.writeAsBytes(bytes, flush: true);
    if (await targetFile.exists()) {
      await targetFile.delete();
    }
    await tmpFile.rename(targetPath);

    final checksum = computeFnv1a64Hex(jsonEncode(pack.toPayloadMap()));
    return StagePackFileReceipt(
      filePath: targetPath,
      bytesWritten: bytes.length,
      compressed: compressGzip,
      checksumFnv1a64: checksum,
      validation: validation,
    );
  }

  /// Odczytuje i waliduje plik `.ppmstage` z dysku.
  Future<CommunityStagePackParseResult> importFromFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return CommunityStagePackParseResult(
        success: false,
        checksumVerified: false,
        wasCompressed: false,
        errorMessage: 'Nie znaleziono pliku: $filePath',
      );
    }
    final content = await file.readAsString();
    return parsePpmStageContent(content);
  }

  /// Skanuje katalog i zwraca listę znalezionych paczek `.ppmstage`.
  Future<List<StagePackFileSummary>> listAvailablePacksInDirectory(
    String directoryPath,
  ) async {
    final dir = Directory(directoryPath);
    if (!await dir.exists()) return const [];

    final summaries = <StagePackFileSummary>[];
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is! File) continue;
      if (!entity.path.toLowerCase().endsWith(kPpmStageFileExtension)) continue;

      final stat = await entity.stat();
      final result = await importFromFile(entity.path);
      final fileName =
          entity.uri.pathSegments.isNotEmpty ? entity.uri.pathSegments.last : entity.path;

      if (result.pack != null) {
        final p = result.pack!;
        summaries.add(
          StagePackFileSummary(
            filePath: entity.path,
            fileName: fileName,
            fileSizeBytes: stat.size,
            title: p.metadata.title,
            author: p.metadata.author,
            packKind: p.metadata.packKind,
            stageCount: p.race.stages.length,
            totalDistanceKm: p.race.totalRaceDistanceKm,
            isValid: result.success,
          ),
        );
      } else {
        summaries.add(
          StagePackFileSummary(
            filePath: entity.path,
            fileName: fileName,
            fileSizeBytes: stat.size,
            title: fileName,
            author: 'Nieznany',
            packKind: CommunityStagePackKind.oneDayRace,
            stageCount: 0,
            totalDistanceKm: 0.0,
            isValid: false,
          ),
        );
      }
    }

    summaries.sort((a, b) => a.title.compareTo(b.title));
    return summaries;
  }

  /// Wstawia zaimportowany wyścig `TourRace` bezpośrednio do `SeasonCalendar`
  /// z automatycznym rozwiązaniem kolizji ID oraz chronologicznym sortowaniem.
  SeasonCalendarImportResult importIntoSeasonCalendar(
    SeasonCalendar calendar,
    TourRace importedRace, {
    bool regenerateUniqueIdOnCollision = true,
    bool replaceExistingWithSameId = false,
    bool sortChronologically = true,
  }) {
    final updatedList = List<TourRace>.from(calendar.races);
    final existingIdx = updatedList.indexWhere((r) => r.id == importedRace.id);
    bool replaced = false;
    TourRace raceToInsert = importedRace;

    if (existingIdx >= 0) {
      if (replaceExistingWithSameId) {
        updatedList[existingIdx] = importedRace;
        replaced = true;
      } else if (regenerateUniqueIdOnCollision) {
        int suffix = 2;
        String candidateId = '${importedRace.id}_$suffix';
        while (updatedList.any((r) => r.id == candidateId)) {
          suffix++;
          candidateId = '${importedRace.id}_$suffix';
        }
        raceToInsert = importedRace.copyWith(id: candidateId);
        updatedList.add(raceToInsert);
      } else {
        updatedList.add(raceToInsert);
      }
    } else {
      updatedList.add(raceToInsert);
    }

    if (sortChronologically) {
      updatedList.sort((a, b) {
        final m = a.startMonth.compareTo(b.startMonth);
        if (m != 0) return m;
        return a.startDay.compareTo(b.startDay);
      });
    }

    final insertedIdx = updatedList.indexWhere((r) => r.id == raceToInsert.id);
    final updatedCalendar = calendar.copyWith(races: updatedList);

    return SeasonCalendarImportResult(
      updatedCalendar: updatedCalendar,
      insertedRace: raceToInsert,
      replacedExisting: replaced,
      insertedIndex: insertedIdx,
    );
  }

  /// Parsuje zawartość `.ppmstage` i zapisuje wyścig bezpośrednio do kalendarza aktywnej kariery.
  Future<CareerCalendarImportOutcome> importPpmStageToCareerCalendar(
    CareerController controller,
    String rawContent, {
    SeasonCalendar? existingCalendar,
  }) async {
    final parseResult = parsePpmStageContent(rawContent);
    if (!parseResult.success || parseResult.pack == null) {
      return CareerCalendarImportOutcome(
        success: false,
        pack: parseResult.pack,
        message: parseResult.errorMessage ?? 'Błąd wczytywania pliku .ppmstage.',
      );
    }

    final raceToAdd = existingCalendar != null
        ? importIntoSeasonCalendar(existingCalendar, parseResult.pack!.race)
            .insertedRace
        : parseResult.pack!.race;

    final added = await controller.addCustomRaceToCalendar(raceToAdd);
    if (!added) {
      return CareerCalendarImportOutcome(
        success: false,
        pack: parseResult.pack,
        message: 'Brak aktywnego zapisu kariery lub błąd zapisu kalendarza.',
      );
    }

    return CareerCalendarImportOutcome(
      success: true,
      importedRace: raceToAdd,
      pack: parseResult.pack,
      message:
          'Wczytano „${raceToAdd.name}” (${raceToAdd.stages.length} etapów) do kalendarza.',
    );
  }

  /// Zapewnia, że ścieżka docelowa kończy się na `.ppmstage`.
  static String ensurePpmStageExtension(String path) {
    final trimmed = path.trim();
    if (trimmed.toLowerCase().endsWith(kPpmStageFileExtension)) {
      return trimmed;
    }
    return '$trimmed$kPpmStageFileExtension';
  }

  static CommunityStagePackKind _inferPackKind(TourRace race) {
    if (race.stages.length >= 21 ||
        race.uciCategory == RaceCategory.grandTour) {
      return CommunityStagePackKind.grandTour21;
    }
    if (race.stages.length > 1) {
      return CommunityStagePackKind.stageRace;
    }
    return CommunityStagePackKind.oneDayRace;
  }

  static String _sanitizeSlug(String raw) {
    final lower = raw.toLowerCase().trim();
    final replaced = lower.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    final stripped = replaced.replaceAll(RegExp(r'^_+|_+$'), '');
    return stripped.isEmpty ? 'custom_stage' : stripped;
  }
}

/// Stan UI dla panelu eksportu i importu paczek `.ppmstage`.
class CommunityStagePackSharingState {
  final CommunityStagePack? activePack;
  final CommunityStagePackValidationReport? validation;
  final String? serializedPreview;
  final bool compressGzip;
  final bool isBusy;
  final String? statusMessage;
  final bool isErrorStatus;

  const CommunityStagePackSharingState({
    this.activePack,
    this.validation,
    this.serializedPreview,
    this.compressGzip = false,
    this.isBusy = false,
    this.statusMessage,
    this.isErrorStatus = false,
  });

  CommunityStagePackSharingState copyWith({
    CommunityStagePack? activePack,
    CommunityStagePackValidationReport? validation,
    String? serializedPreview,
    bool? compressGzip,
    bool? isBusy,
    String? statusMessage,
    bool? isErrorStatus,
    bool clearStatus = false,
  }) {
    return CommunityStagePackSharingState(
      activePack: activePack ?? this.activePack,
      validation: validation ?? this.validation,
      serializedPreview: serializedPreview ?? this.serializedPreview,
      compressGzip: compressGzip ?? this.compressGzip,
      isBusy: isBusy ?? this.isBusy,
      statusMessage: clearStatus ? null : (statusMessage ?? this.statusMessage),
      isErrorStatus: isErrorStatus ?? this.isErrorStatus,
    );
  }
}

/// Kontroler Riverpod zarządzający eksportem i importem `.ppmstage`.
class CommunityStagePackSharingNotifier
    extends StateNotifier<CommunityStagePackSharingState> {
  final CommunityStagePackSharingService _service;

  CommunityStagePackSharingNotifier({
    CommunityStagePackSharingService service =
        const CommunityStagePackSharingService(),
  })  : _service = service,
        super(const CommunityStagePackSharingState());

  void toggleCompression(bool compress) {
    final pack = state.activePack;
    final preview = pack != null
        ? _service.serializePackToPpmStage(
            pack,
            compressGzip: compress,
            pretty: !compress,
          )
        : state.serializedPreview;
    state = state.copyWith(
      compressGzip: compress,
      serializedPreview: preview,
      clearStatus: true,
    );
  }

  void loadRaceForExport(
    TourRace race, {
    String author = 'Manager Community',
    String description = '',
  }) {
    final pack = _service.createPackFromTourRace(
      race: race,
      author: author,
      description: description,
    );
    final validation = _service.validatePack(pack);
    final preview = _service.serializePackToPpmStage(
      pack,
      compressGzip: state.compressGzip,
      pretty: !state.compressGzip,
    );
    state = state.copyWith(
      activePack: pack,
      validation: validation,
      serializedPreview: preview,
      statusMessage:
          'Przygotowano paczkę ${pack.metadata.title} (${validation.stageCount} etapów).',
      isErrorStatus: !validation.isValid,
    );
  }

  bool importFromRawText(String rawContent) {
    final result = _service.parsePpmStageContent(rawContent);
    if (!result.success || result.pack == null) {
      state = state.copyWith(
        validation: result.validation,
        statusMessage: result.errorMessage ?? 'Błąd parsowania .ppmstage.',
        isErrorStatus: true,
      );
      return false;
    }

    state = state.copyWith(
      activePack: result.pack,
      validation: result.validation,
      serializedPreview: rawContent.trim(),
      statusMessage:
          'Zweryfikowano paczkę „${result.pack!.metadata.title}” (FNV-1a64 OK).',
      isErrorStatus: false,
    );
    return true;
  }

  Future<StagePackFileReceipt?> exportActivePackToFile(String filePath) async {
    final pack = state.activePack;
    if (pack == null) return null;

    state = state.copyWith(isBusy: true, clearStatus: true);
    try {
      final receipt = await _service.exportToFile(
        pack,
        filePath,
        compressGzip: state.compressGzip,
      );
      state = state.copyWith(
        isBusy: false,
        statusMessage:
            'Zapisano ${receipt.filePath} (${receipt.bytesWritten} B).',
        isErrorStatus: false,
      );
      return receipt;
    } catch (e) {
      state = state.copyWith(
        isBusy: false,
        statusMessage: 'Błąd zapisu .ppmstage: $e',
        isErrorStatus: true,
      );
      return null;
    }
  }
}

/// Globalny provider Riverpod dla serwisu paczek `.ppmstage`.
final communityStagePackSharingProvider = StateNotifierProvider<
    CommunityStagePackSharingNotifier, CommunityStagePackSharingState>((ref) {
  return CommunityStagePackSharingNotifier();
});

/// Responsywny panel UI (390x844 / 1024x768 / 1600x900) do eksportu i importu
/// własnych tras `.ppmstage` oraz dodawania ich do kalendarza kariery.
class CommunityStagePackSharingPanel extends StatefulWidget {
  final TourRace? sourceRace;
  final SeasonCalendar? calendar;
  final ValueChanged<TourRace>? onImportToCalendar;
  final ValueChanged<String>? onExportPpmStageText;
  final CommunityStagePackSharingService service;

  const CommunityStagePackSharingPanel({
    super.key,
    this.sourceRace,
    this.calendar,
    this.onImportToCalendar,
    this.onExportPpmStageText,
    this.service = const CommunityStagePackSharingService(),
  });

  @override
  State<CommunityStagePackSharingPanel> createState() =>
      _CommunityStagePackSharingPanelState();
}

class _CommunityStagePackSharingPanelState
    extends State<CommunityStagePackSharingPanel> {
  late final TextEditingController _authorCtrl;
  late final TextEditingController _importPayloadCtrl;
  CommunityStagePack? _currentPack;
  CommunityStagePackValidationReport? _validation;
  bool _compressGzip = false;
  String? _feedbackText;
  bool _feedbackError = false;

  @override
  void initState() {
    super.initState();
    _authorCtrl = TextEditingController(text: 'Manager Community');
    _importPayloadCtrl = TextEditingController();
    if (widget.sourceRace != null) {
      _buildPackFromSource(widget.sourceRace!);
    }
  }

  @override
  void didUpdateWidget(covariant CommunityStagePackSharingPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sourceRace != null && widget.sourceRace != oldWidget.sourceRace) {
      _buildPackFromSource(widget.sourceRace!);
    }
  }

  @override
  void dispose() {
    _authorCtrl.dispose();
    _importPayloadCtrl.dispose();
    super.dispose();
  }

  void _buildPackFromSource(TourRace race) {
    final pack = widget.service.createPackFromTourRace(
      race: race,
      author: _authorCtrl.text,
    );
    final report = widget.service.validatePack(pack);
    final serialized = widget.service.serializePackToPpmStage(
      pack,
      compressGzip: _compressGzip,
      pretty: !_compressGzip,
    );
    setState(() {
      _currentPack = pack;
      _validation = report;
      _importPayloadCtrl.text = serialized;
      _feedbackText =
          'Wygenerowano paczkę .ppmstage (${report.stageCount} etapów).';
      _feedbackError = !report.isValid;
    });
  }

  void _handleExport() {
    if (widget.sourceRace != null) {
      _buildPackFromSource(widget.sourceRace!);
    }
    final pack = _currentPack;
    if (pack == null) {
      setState(() {
        _feedbackText = 'Brak wyścigu źródłowego do eksportu.';
        _feedbackError = true;
      });
      return;
    }
    final serialized = widget.service.serializePackToPpmStage(
      pack,
      compressGzip: _compressGzip,
      pretty: !_compressGzip,
    );
    setState(() {
      _importPayloadCtrl.text = serialized;
      _feedbackText =
          'Gotowe do udostępnienia (${serialized.length} znaków, FNV-1a64).';
      _feedbackError = false;
    });
    widget.onExportPpmStageText?.call(serialized);
  }

  void _handleImport() {
    final raw = _importPayloadCtrl.text;
    final parsed = widget.service.parsePpmStageContent(raw);
    if (!parsed.success || parsed.pack == null) {
      setState(() {
        _validation = parsed.validation;
        _feedbackText =
            parsed.errorMessage ?? 'Niepoprawny plik .ppmstage.';
        _feedbackError = true;
      });
      return;
    }

    final race = parsed.pack!.race;
    TourRace finalRace = race;
    if (widget.calendar != null) {
      final result = widget.service.importIntoSeasonCalendar(
        widget.calendar!,
        race,
      );
      finalRace = result.insertedRace;
    }

    setState(() {
      _currentPack = parsed.pack;
      _validation = parsed.validation;
      _feedbackText =
          'Wczytano „${finalRace.name}” (${finalRace.stages.length} etapów) do kalendarza.';
      _feedbackError = false;
    });
    widget.onImportToCalendar?.call(finalRace);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 560;
          final isWide = constraints.maxWidth >= 960;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(isCompact),
                const SizedBox(height: 12),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: _buildMetadataAndStatsCard()),
                      const SizedBox(width: 16),
                      Expanded(flex: 7, child: _buildPayloadAndActionsCard()),
                    ],
                  )
                else ...[
                  _buildMetadataAndStatsCard(),
                  const SizedBox(height: 12),
                  _buildPayloadAndActionsCard(),
                ],
                if (_feedbackText != null) ...[
                  const SizedBox(height: 12),
                  _buildStatusBanner(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isCompact) {
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.goldAccent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.goldAccent.withValues(alpha: 0.45),
        ),
      ),
      child: const Text(
        '.PPMSTAGE',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: AppColors.goldAccent,
        ),
      ),
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.share_location_outlined,
                  color: AppColors.goldAccent, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Udostępnianie Tras (.ppmstage)',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              badge,
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Eksport i import wyścigów 1-dniowych oraz 21-etapowych Tourów.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        const Icon(Icons.share_location_outlined,
            color: AppColors.goldAccent, size: 22),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Community Stage Pack Sharing (.ppmstage)',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Zapisuj własne wyścigi 1-dniowe lub 21-etapowe Toury i wczytuj je do kalendarza kariery.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        badge,
      ],
    );
  }

  Widget _buildMetadataAndStatsCard() {
    final v = _validation;
    final p = _currentPack;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Metadane i Telemetria Paczki',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _authorCtrl,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              labelText: 'Autor trasy',
              labelStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              filled: true,
              fillColor: AppColors.background,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.goldAccent),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatPill(
                label: 'Typ',
                value: p?.metadata.packKind.labelPl ?? 'Brak danych',
              ),
              _StatPill(
                label: 'Etapy',
                value: '${v?.stageCount ?? 0}',
              ),
              _StatPill(
                label: 'Dystans',
                value: '${(v?.totalDistanceKm ?? 0).toStringAsFixed(1)} km',
              ),
              _StatPill(
                label: 'Przewyższenie',
                value: '+${(v?.totalElevationGainM ?? 0).round()} m',
              ),
              _StatPill(
                label: 'Bruk / KOM',
                value: '${v?.cobbleSegmentCount ?? 0} / ${v?.komClimbCount ?? 0}',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kompresja GZip (.ppmstage)',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Mniejszy rozmiar pliku dla 21-etapowych Grand Tourów',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch.adaptive(
                activeTrackColor: AppColors.goldAccent,
                value: _compressGzip,
                onChanged: (val) {
                  setState(() => _compressGzip = val);
                  if (_currentPack != null) {
                    final serialized = widget.service.serializePackToPpmStage(
                      _currentPack!,
                      compressGzip: val,
                      pretty: !val,
                    );
                    _importPayloadCtrl.text = serialized;
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPayloadAndActionsCard() {
    final canExport = widget.sourceRace != null || _currentPack != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Zawartość pliku .ppmstage (Eksport / Import)',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _importPayloadCtrl,
            maxLines: 6,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Wklej zawartość pliku .ppmstage lub wygeneruj z Kreatora...',
              hintStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.goldAccent),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ActionInteractiveButton(
                label: 'Eksportuj .ppmstage',
                icon: Icons.upload_file_outlined,
                enabled: canExport,
                isPrimary: false,
                onPressed: _handleExport,
              ),
              _ActionInteractiveButton(
                label: 'Wczytaj do Kalendarza',
                icon: Icons.calendar_month_outlined,
                enabled: true,
                isPrimary: true,
                onPressed: _handleImport,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    final color =
        _feedbackError ? AppColors.crimsonAlert : AppColors.statusSuccess;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(
            _feedbackError
                ? Icons.error_outline
                : Icons.check_circle_outline,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _feedbackText!,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;

  const _StatPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionInteractiveButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final bool isPrimary;
  final VoidCallback onPressed;

  const _ActionInteractiveButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.isPrimary,
    required this.onPressed,
  });

  @override
  State<_ActionInteractiveButton> createState() =>
      _ActionInteractiveButtonState();
}

class _ActionInteractiveButtonState extends State<_ActionInteractiveButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final baseBg = widget.isPrimary
        ? AppColors.primaryAccent
        : AppColors.background;
    final effectiveBg = !widget.enabled
        ? AppColors.surface
        : _pressed
            ? baseBg.withValues(alpha: 0.78)
            : _hovered
                ? (widget.isPrimary
                    ? AppColors.primaryAccent.withValues(alpha: 0.9)
                    : AppColors.surfaceLight)
                : baseBg;

    final borderColor = !widget.enabled
        ? AppColors.cardBorder.withValues(alpha: 0.5)
        : _focused
            ? AppColors.goldAccent
            : widget.isPrimary
                ? AppColors.goldAccent.withValues(alpha: 0.55)
                : AppColors.cardBorder;

    final textColor = !widget.enabled
        ? AppColors.textSecondary.withValues(alpha: 0.5)
        : AppColors.textPrimary;

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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: effectiveBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: _focused ? 1.5 : 1.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 16, color: textColor),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
