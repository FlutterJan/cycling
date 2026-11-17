// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/career/career_save.dart';
import 'custom_mod_importer_service.dart';
import 'preset_real_names_template_generator.dart';

/// Rozszerzenie pliku paczki modyfikacji Pro Peloton Manager Workshop.
const String kPpmModFileExtension = '.ppmmod';

/// Magiczny nagłówek formatu `.ppmmod`.
const String kPpmModFormatMagic = 'PPMMOD_V1';

/// Prefiks skompresowanego strumienia GZip Base64 w pliku `.ppmmod`.
const String kPpmModGzipPrefix = 'PPMMOD_GZ_V1:';

/// Bieżąca wersja schematu `.ppmmod`.
const int kPpmModSchemaVersion = 1;

/// Maksymalny rozmiar pojedynczego zasobu osadzonego w paczce `.ppmmod` (5 MB).
const int kMaxPpmModSingleAssetBytes = 5 * 1024 * 1024;

/// Maksymalny łączny rozmiar zasobów w paczce `.ppmmod` (25 MB).
const int kMaxPpmModTotalAssetsBytes = 25 * 1024 * 1024;

/// Kategoria zawartości paczki `.ppmmod`.
enum PpmModContentType {
  databaseAndRoster,
  realismNamesPatch,
  liveryAndJerseys,
  stagesAndCalendar,
  totalConversion;

  String toJson() => name;

  static PpmModContentType fromJson(String value) {
    return PpmModContentType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => PpmModContentType.databaseAndRoster,
    );
  }

  String get labelPl {
    switch (this) {
      case PpmModContentType.databaseAndRoster:
        return 'Baza i Składy';
      case PpmModContentType.realismNamesPatch:
        return 'Paczka Realizmu';
      case PpmModContentType.liveryAndJerseys:
        return 'Stroje i Malowania';
      case PpmModContentType.stagesAndCalendar:
        return 'Etapy i Kalendarz';
      case PpmModContentType.totalConversion:
        return 'Total Conversion';
    }
  }
}

/// Poziom istotności problemu wykrytego podczas walidacji paczki `.ppmmod`.
enum PpmModValidationSeverity {
  info,
  warning,
  error;

  String get labelPl {
    switch (this) {
      case PpmModValidationSeverity.info:
        return 'Info';
      case PpmModValidationSeverity.warning:
        return 'Ostrzeżenie';
      case PpmModValidationSeverity.error:
        return 'Błąd';
    }
  }
}

/// Rodzaj zasobu osadzonego lub powiązanego z paczką `.ppmmod`.
enum PpmModAssetKind {
  jerseyTexture,
  teamBadge,
  stagePack,
  localeOverride,
  databaseOverride;

  String toJson() => name;

  static PpmModAssetKind fromJson(String value) {
    return PpmModAssetKind.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => PpmModAssetKind.databaseOverride,
    );
  }
}

/// Tryb kompresji przy eksporcie pliku `.ppmmod`.
enum PpmModExportCompression {
  gzipBase64,
  plainJson;

  String get labelPl {
    switch (this) {
      case PpmModExportCompression.gzipBase64:
        return 'GZip (.ppmmod)';
      case PpmModExportCompression.plainJson:
        return 'JSON (.ppmmod)';
    }
  }
}

/// Manifest paczki modyfikacji `.ppmmod` dla warsztatu społecznościowego.
class PpmModManifest {
  final String modId;
  final String title;
  final String author;
  final String version;
  final String minGameVersion;
  final String description;
  final PpmModContentType contentType;
  final DateTime createdAt;
  final List<String> tags;
  final List<String> dependencies;
  final String? previewImageBase64;
  final String? websiteUrl;

  const PpmModManifest({
    required this.modId,
    required this.title,
    required this.author,
    required this.version,
    this.minGameVersion = '1.0.0',
    required this.description,
    required this.contentType,
    required this.createdAt,
    this.tags = const [],
    this.dependencies = const [],
    this.previewImageBase64,
    this.websiteUrl,
  });

  PpmModManifest copyWith({
    String? modId,
    String? title,
    String? author,
    String? version,
    String? minGameVersion,
    String? description,
    PpmModContentType? contentType,
    DateTime? createdAt,
    List<String>? tags,
    List<String>? dependencies,
    String? previewImageBase64,
    String? websiteUrl,
  }) {
    return PpmModManifest(
      modId: modId ?? this.modId,
      title: title ?? this.title,
      author: author ?? this.author,
      version: version ?? this.version,
      minGameVersion: minGameVersion ?? this.minGameVersion,
      description: description ?? this.description,
      contentType: contentType ?? this.contentType,
      createdAt: createdAt ?? this.createdAt,
      tags: tags != null ? List<String>.unmodifiable(tags) : this.tags,
      dependencies: dependencies != null
          ? List<String>.unmodifiable(dependencies)
          : this.dependencies,
      previewImageBase64: previewImageBase64 ?? this.previewImageBase64,
      websiteUrl: websiteUrl ?? this.websiteUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'modId': modId,
      'title': title,
      'author': author,
      'version': version,
      'minGameVersion': minGameVersion,
      'description': description,
      'contentType': contentType.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'tags': tags,
      'dependencies': dependencies,
      if (previewImageBase64 != null) 'previewImageBase64': previewImageBase64,
      if (websiteUrl != null) 'websiteUrl': websiteUrl,
    };
  }

  factory PpmModManifest.fromJson(Map<String, dynamic> json) {
    return PpmModManifest(
      modId: (json['modId'] as String? ?? '').trim(),
      title: (json['title'] as String? ?? '').trim(),
      author: (json['author'] as String? ?? '').trim(),
      version: (json['version'] as String? ?? '1.0.0').trim(),
      minGameVersion: (json['minGameVersion'] as String? ?? '1.0.0').trim(),
      description: (json['description'] as String? ?? '').trim(),
      contentType: PpmModContentType.fromJson(
        json['contentType'] as String? ?? 'databaseAndRoster',
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.utc(2026)
          : DateTime.utc(2026),
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList() ??
          const [],
      dependencies: (json['dependencies'] as List<dynamic>?)
              ?.map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList() ??
          const [],
      previewImageBase64: json['previewImageBase64'] as String?,
      websiteUrl: json['websiteUrl'] as String?,
    );
  }
}

/// Zasób osadzony w paczce `.ppmmod` (np. tekstura koszulki, paczka etapów, nadpisanie JSON).
class PpmModAssetEntry {
  final String relativePath;
  final PpmModAssetKind assetKind;
  final int byteSize;
  final String fnv1a64Checksum;
  final String? payloadBase64;

  const PpmModAssetEntry({
    required this.relativePath,
    required this.assetKind,
    required this.byteSize,
    required this.fnv1a64Checksum,
    this.payloadBase64,
  });

  PpmModAssetEntry copyWith({
    String? relativePath,
    PpmModAssetKind? assetKind,
    int? byteSize,
    String? fnv1a64Checksum,
    String? payloadBase64,
  }) {
    return PpmModAssetEntry(
      relativePath: relativePath ?? this.relativePath,
      assetKind: assetKind ?? this.assetKind,
      byteSize: byteSize ?? this.byteSize,
      fnv1a64Checksum: fnv1a64Checksum ?? this.fnv1a64Checksum,
      payloadBase64: payloadBase64 ?? this.payloadBase64,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'relativePath': relativePath,
      'assetKind': assetKind.toJson(),
      'byteSize': byteSize,
      'fnv1a64Checksum': fnv1a64Checksum,
      if (payloadBase64 != null) 'payloadBase64': payloadBase64,
    };
  }

  factory PpmModAssetEntry.fromJson(Map<String, dynamic> json) {
    return PpmModAssetEntry(
      relativePath: (json['relativePath'] as String? ?? '').trim(),
      assetKind: PpmModAssetKind.fromJson(
        json['assetKind'] as String? ?? 'databaseOverride',
      ),
      byteSize: (json['byteSize'] as num?)?.toInt() ?? 0,
      fnv1a64Checksum: (json['fnv1a64Checksum'] as String? ?? '').trim(),
      payloadBase64: json['payloadBase64'] as String?,
    );
  }
}

/// Pojedynczy problem lub informacja diagnostyczna z walidacji paczki `.ppmmod`.
class PpmModValidationIssue {
  final String code;
  final String section;
  final String? targetId;
  final String message;
  final PpmModValidationSeverity severity;

  const PpmModValidationIssue({
    required this.code,
    required this.section,
    this.targetId,
    required this.message,
    required this.severity,
  });

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'section': section,
      if (targetId != null) 'targetId': targetId,
      'message': message,
      'severity': severity.name,
    };
  }

  factory PpmModValidationIssue.fromJson(Map<String, dynamic> json) {
    return PpmModValidationIssue(
      code: json['code'] as String? ?? 'UNKNOWN',
      section: json['section'] as String? ?? 'general',
      targetId: json['targetId'] as String?,
      message: json['message'] as String? ?? '',
      severity: PpmModValidationSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => PpmModValidationSeverity.warning,
      ),
    );
  }
}

/// Pełny raport walidacji oraz metryki gotowości warsztatowej paczki `.ppmmod`.
class PpmModValidationReport {
  final bool isValid;
  final int readinessScore;
  final int teamsCount;
  final int ridersCount;
  final int racesCount;
  final int brandsCount;
  final int assetsCount;
  final int estimatedBytes;
  final int duplicateIdsDetected;
  final int invalidColorsDetected;
  final int invalidIsoCodesDetected;
  final List<PpmModValidationIssue> issues;

  const PpmModValidationReport({
    required this.isValid,
    required this.readinessScore,
    required this.teamsCount,
    required this.ridersCount,
    required this.racesCount,
    required this.brandsCount,
    required this.assetsCount,
    required this.estimatedBytes,
    required this.duplicateIdsDetected,
    required this.invalidColorsDetected,
    required this.invalidIsoCodesDetected,
    required this.issues,
  });

  List<PpmModValidationIssue> get errors => issues
      .where((i) => i.severity == PpmModValidationSeverity.error)
      .toList();

  List<PpmModValidationIssue> get warnings => issues
      .where((i) => i.severity == PpmModValidationSeverity.warning)
      .toList();

  List<PpmModValidationIssue> get infos => issues
      .where((i) => i.severity == PpmModValidationSeverity.info)
      .toList();
}

/// Kompletna paczka modyfikacji `.ppmmod` gotowa do walidacji i eksportu.
class PpmModPackage {
  final int schemaVersion;
  final String formatMagic;
  final PpmModManifest manifest;
  final CustomModPackage? customModPackage;
  final CommunityRealismPatchStructure? realismPatch;
  final List<PpmModAssetEntry> assets;
  final String checksumFnv1a64;

  const PpmModPackage({
    this.schemaVersion = kPpmModSchemaVersion,
    this.formatMagic = kPpmModFormatMagic,
    required this.manifest,
    this.customModPackage,
    this.realismPatch,
    this.assets = const [],
    this.checksumFnv1a64 = '',
  });

  /// Tworzy paczkę `.ppmmod` na podstawie obiektu [CustomModPackage].
  factory PpmModPackage.fromCustomModPackage(
    CustomModPackage modPackage, {
    PpmModContentType contentType = PpmModContentType.databaseAndRoster,
    String minGameVersion = '1.0.0',
    List<String> tags = const ['roster', 'community'],
    List<String> dependencies = const [],
    List<PpmModAssetEntry> assets = const [],
  }) {
    return PpmModPackage(
      manifest: PpmModManifest(
        modId: modPackage.metadata.id,
        title: modPackage.metadata.name,
        author: modPackage.metadata.author,
        version: modPackage.metadata.version,
        minGameVersion: minGameVersion,
        description: modPackage.metadata.description,
        contentType: contentType,
        createdAt: modPackage.metadata.createdDate,
        tags: tags,
        dependencies: dependencies,
        websiteUrl: modPackage.metadata.websiteUrl,
      ),
      customModPackage: modPackage,
      assets: assets,
    );
  }

  /// Tworzy paczkę `.ppmmod` na podstawie obiektu [CommunityRealismPatchStructure].
  factory PpmModPackage.fromRealismPatch(
    CommunityRealismPatchStructure patch, {
    String? modId,
    String minGameVersion = '1.0.0',
    List<String> tags = const ['realism', 'names'],
    List<String> dependencies = const [],
    List<PpmModAssetEntry> assets = const [],
  }) {
    final generatedId = (modId != null && modId.trim().isNotEmpty)
        ? modId.trim()
        : patch.metadata.name
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
            .replaceAll(RegExp(r'^_+|_+$'), '');
    return PpmModPackage(
      manifest: PpmModManifest(
        modId: generatedId.isEmpty ? 'realism_patch_pack' : generatedId,
        title: patch.metadata.name,
        author: patch.metadata.author,
        version: patch.metadata.version,
        minGameVersion: minGameVersion,
        description: patch.metadata.description,
        contentType: PpmModContentType.realismNamesPatch,
        createdAt: patch.metadata.createdDate,
        tags: tags,
        dependencies: dependencies,
      ),
      realismPatch: patch,
      assets: assets,
    );
  }

  PpmModPackage copyWith({
    int? schemaVersion,
    String? formatMagic,
    PpmModManifest? manifest,
    CustomModPackage? customModPackage,
    CommunityRealismPatchStructure? realismPatch,
    List<PpmModAssetEntry>? assets,
    String? checksumFnv1a64,
  }) {
    return PpmModPackage(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      formatMagic: formatMagic ?? this.formatMagic,
      manifest: manifest ?? this.manifest,
      customModPackage: customModPackage ?? this.customModPackage,
      realismPatch: realismPatch ?? this.realismPatch,
      assets: assets != null ? List<PpmModAssetEntry>.unmodifiable(assets) : this.assets,
      checksumFnv1a64: checksumFnv1a64 ?? this.checksumFnv1a64,
    );
  }

  /// Zwraca kanoniczny słownik JSON bez pola sumy kontrolnej.
  Map<String, dynamic> toCanonicalPayloadJson() {
    return {
      'schemaVersion': schemaVersion,
      'formatMagic': formatMagic,
      'manifest': manifest.toJson(),
      if (customModPackage != null)
        'customModPackage': customModPackage!.toJson(),
      if (realismPatch != null) 'realismPatch': realismPatch!.toJson(),
      'assets': assets.map((e) => e.toJson()).toList(),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      ...toCanonicalPayloadJson(),
      'checksumFnv1a64': checksumFnv1a64,
    };
  }

  factory PpmModPackage.fromJson(Map<String, dynamic> json) {
    final customModJson = json['customModPackage'];
    final realismJson = json['realismPatch'];
    final assetsJson = json['assets'] as List<dynamic>? ?? const [];

    return PpmModPackage(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? kPpmModSchemaVersion,
      formatMagic: (json['formatMagic'] as String? ?? kPpmModFormatMagic).trim(),
      manifest: PpmModManifest.fromJson(
        json['manifest'] as Map<String, dynamic>? ?? const {},
      ),
      customModPackage: customModJson is Map<String, dynamic>
          ? CustomModPackage.fromJson(customModJson)
          : null,
      realismPatch: realismJson is Map<String, dynamic>
          ? CommunityRealismPatchStructure.fromJson(realismJson)
          : null,
      assets: assetsJson
          .whereType<Map<String, dynamic>>()
          .map(PpmModAssetEntry.fromJson)
          .toList(),
      checksumFnv1a64: (json['checksumFnv1a64'] as String? ?? '').trim(),
    );
  }
}

/// Potwierdzenie eksportu paczki `.ppmmod` na dysk.
class PpmModPackagingReceipt {
  final String filePath;
  final String modId;
  final String title;
  final PpmModExportCompression compression;
  final int rawJsonBytes;
  final int encodedBytes;
  final String checksumFnv1a64;
  final PpmModValidationReport validationReport;
  final DateTime exportedAt;

  const PpmModPackagingReceipt({
    required this.filePath,
    required this.modId,
    required this.title,
    required this.compression,
    required this.rawJsonBytes,
    required this.encodedBytes,
    required this.checksumFnv1a64,
    required this.validationReport,
    required this.exportedAt,
  });

  double get compressionRatio =>
      rawJsonBytes > 0 ? encodedBytes / rawJsonBytes : 1.0;
}

/// Wynik wczytania i weryfikacji paczki `.ppmmod`.
class PpmModImportResult {
  final PpmModPackage package;
  final PpmModValidationReport validationReport;
  final bool checksumVerified;
  final bool wasCompressed;

  const PpmModImportResult({
    required this.package,
    required this.validationReport,
    required this.checksumVerified,
    required this.wasCompressed,
  });
}

/// Walidator i eksporter paczek modyfikacji `.ppmmod` dla Warsztatu Społeczności.
class ModWorkshopValidatorAndPackager {
  const ModWorkshopValidatorAndPackager();

  static final RegExp _modIdRegex = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_\-\.]{2,63}$');
  static final RegExp _semverRegex = RegExp(r'^\d+\.\d+\.\d+(?:[-+][a-zA-Z0-9\.-]+)?$');
  static final RegExp _hexColorRegex = RegExp(r'^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$');
  static final RegExp _countryIsoRegex = RegExp(r'^[A-Z]{3}$');

  /// Oblicza deterministyczną 64-bitową sumę kontrolną FNV-1a w zapisie szesnastkowym.
  static String computeFnv1a64(String input) {
    final BigInt fnvOffsetBasis = BigInt.parse('cbf29ce484222325', radix: 16);
    final BigInt fnvPrime = BigInt.parse('100000001b3', radix: 16);
    final BigInt mask64 = BigInt.parse('ffffffffffffffff', radix: 16);

    var hash = fnvOffsetBasis;
    final bytes = utf8.encode(input);
    for (final b in bytes) {
      hash = (hash ^ BigInt.from(b)) & mask64;
      hash = (hash * fnvPrime) & mask64;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }

  /// Tworzy gotową, poprawną paczkę startową `.ppmmod` do testów lub szybkiego startu.
  PpmModPackage createStarterTemplatePackage({
    String modId = 'ppm_workshop_starter_pack',
    String title = 'Pro Peloton Community Starter Pack',
    String author = 'Peloton Workshop Creator',
  }) {
    final customMod = CustomModPackage(
      metadata: CustomModMetadata(
        id: modId,
        name: title,
        version: '1.0.0',
        author: author,
        description:
            'Przykładowa paczka modyfikacji `.ppmmod` z poprawionymi nazwami drużyn, kolarzy i wyścigów.',
        createdDate: DateTime.utc(2026, 3, 1),
      ),
      teams: const [
        TeamModEntry(
          matchId: 'team_wt_1',
          name: 'Veloce Alpine Pro Cycling',
          countryIso: 'FRA',
          primaryJerseyColorHex: '#181B22',
          secondaryJerseyColorHex: '#D4AF37',
          accentJerseyColorHex: '#8E4A49',
          sponsorCompanyName: 'Veloce Group',
        ),
      ],
      riders: const [
        RiderModEntry(
          matchId: 'rider_1',
          matchTeamId: 'team_wt_1',
          firstName: 'Jan',
          lastName: 'Kowalski',
          nationalityIso: 'POL',
          birthYear: 1998,
          targetOverallRating: 84,
        ),
      ],
      races: const [
        RaceModEntry(
          matchId: 'race_tdf',
          name: 'Grand Tour de France',
          countryIso: 'FRA',
        ),
      ],
      bikeManufacturers: const [
        BikeModEntry(
          matchId: 'brand_1',
          realName: 'Canyon Aero Works',
          countryIso: 'DEU',
          primaryColorHex: '#0F1115',
          weightGramsModifier: -45.0,
          cdaModifier: -0.002,
        ),
      ],
    );

    return PpmModPackage.fromCustomModPackage(
      customMod,
      tags: const ['starter', 'worldtour', 'verified'],
    );
  }

  /// Przeprowadza pełną walidację struktury, zawartości i zasobów paczki `.ppmmod`.
  PpmModValidationReport validatePackage(
    PpmModPackage package, {
    CareerSave? activeSave,
  }) {
    final issues = <PpmModValidationIssue>[];
    var duplicateIdsDetected = 0;
    var invalidColorsDetected = 0;
    var invalidIsoCodesDetected = 0;

    if (package.formatMagic != kPpmModFormatMagic) {
      issues.add(
        PpmModValidationIssue(
          code: 'INVALID_FORMAT_MAGIC',
          section: 'header',
          message:
              'Nieprawidłowy nagłówek formatu "${package.formatMagic}". Oczekiwano "$kPpmModFormatMagic".',
          severity: PpmModValidationSeverity.error,
        ),
      );
    }

    if (package.schemaVersion < 1 || package.schemaVersion > kPpmModSchemaVersion) {
      issues.add(
        PpmModValidationIssue(
          code: 'UNSUPPORTED_SCHEMA_VERSION',
          section: 'header',
          message:
              'Nieobsługiwana wersja schematu v${package.schemaVersion} (maks. v$kPpmModSchemaVersion).',
          severity: PpmModValidationSeverity.error,
        ),
      );
    }

    // Walidacja manifestu
    final m = package.manifest;
    if (m.modId.isEmpty || !_modIdRegex.hasMatch(m.modId)) {
      issues.add(
        PpmModValidationIssue(
          code: 'INVALID_MOD_ID',
          section: 'manifest',
          targetId: m.modId,
          message:
              'Identyfikator modId ("${m.modId}") musi mieć 3–64 znaki alfanumeryczne (plus _ - .).',
          severity: PpmModValidationSeverity.error,
        ),
      );
    }
    if (m.title.trim().length < 3) {
      issues.add(
        const PpmModValidationIssue(
          code: 'EMPTY_MOD_TITLE',
          section: 'manifest',
          message: 'Tytuł paczki musi zawierać co najmniej 3 znaki.',
          severity: PpmModValidationSeverity.error,
        ),
      );
    }
    if (m.author.trim().isEmpty) {
      issues.add(
        const PpmModValidationIssue(
          code: 'EMPTY_MOD_AUTHOR',
          section: 'manifest',
          message: 'Pole autora paczki nie może być puste.',
          severity: PpmModValidationSeverity.error,
        ),
      );
    }
    if (!_semverRegex.hasMatch(m.version)) {
      issues.add(
        PpmModValidationIssue(
          code: 'INVALID_SEMVER',
          section: 'manifest',
          targetId: m.version,
          message: 'Wersja paczki ("${m.version}") nie spełnia standardu SemVer (np. 1.0.0).',
          severity: PpmModValidationSeverity.error,
        ),
      );
    }
    if (!_semverRegex.hasMatch(m.minGameVersion)) {
      issues.add(
        PpmModValidationIssue(
          code: 'INVALID_MIN_GAME_VERSION',
          section: 'manifest',
          targetId: m.minGameVersion,
          message:
              'Minimalna wersja gry ("${m.minGameVersion}") nie spełnia formatu SemVer.',
          severity: PpmModValidationSeverity.warning,
        ),
      );
    }
    if (m.description.trim().length < 12) {
      issues.add(
        const PpmModValidationIssue(
          code: 'SHORT_DESCRIPTION',
          section: 'manifest',
          message: 'Opis paczki jest bardzo krótki (<12 znaków); dodaj opis dla graczy.',
          severity: PpmModValidationSeverity.warning,
        ),
      );
    }
    if (m.tags.isEmpty) {
      issues.add(
        const PpmModValidationIssue(
          code: 'MISSING_TAGS',
          section: 'manifest',
          message: 'Brak tagów warsztatowych — utrudnia filtrowanie paczki.',
          severity: PpmModValidationSeverity.info,
        ),
      );
    }

    final customMod = package.customModPackage;
    final realismPatch = package.realismPatch;

    final hasCustomModEntries = customMod != null &&
        (customMod.teams.isNotEmpty ||
            customMod.riders.isNotEmpty ||
            customMod.races.isNotEmpty ||
            customMod.bikeManufacturers.isNotEmpty);
    final hasRealismEntries = realismPatch != null &&
        (realismPatch.teams.isNotEmpty ||
            realismPatch.riders.isNotEmpty ||
            realismPatch.races.isNotEmpty ||
            realismPatch.brands.isNotEmpty);

    if (!hasCustomModEntries && !hasRealismEntries && package.assets.isEmpty) {
      issues.add(
        const PpmModValidationIssue(
          code: 'EMPTY_MOD_PAYLOAD',
          section: 'payload',
          message:
              'Paczka nie zawiera żadnych drużyn, kolarzy, wyścigów, marek ani zasobów.',
          severity: PpmModValidationSeverity.error,
        ),
      );
    }

    var teamsCount = 0;
    var ridersCount = 0;
    var racesCount = 0;
    var brandsCount = 0;

    // Walidacja CustomModPackage
    if (customMod != null) {
      teamsCount += customMod.teams.length;
      ridersCount += customMod.riders.length;
      racesCount += customMod.races.length;
      brandsCount += customMod.bikeManufacturers.length;

      final seenTeamIds = <String>{};
      for (var i = 0; i < customMod.teams.length; i++) {
        final t = customMod.teams[i];
        final key = (t.matchId ?? t.matchOriginalName ?? t.name).trim();
        if (t.name.trim().isEmpty) {
          issues.add(
            PpmModValidationIssue(
              code: 'TEAM_EMPTY_NAME',
              section: 'teams',
              targetId: key,
              message: 'Drużyna #$i ma pustą nazwę.',
              severity: PpmModValidationSeverity.error,
            ),
          );
        }
        if (t.matchId != null && t.matchId!.trim().isNotEmpty) {
          if (!seenTeamIds.add(t.matchId!.trim())) {
            duplicateIdsDetected++;
            issues.add(
              PpmModValidationIssue(
                code: 'DUPLICATE_TEAM_ID',
                section: 'teams',
                targetId: t.matchId,
                message: 'Zduplikowany matchId drużyny: "${t.matchId}".',
                severity: PpmModValidationSeverity.error,
              ),
            );
          }
        }
        if (!_countryIsoRegex.hasMatch(t.countryIso.trim().toUpperCase())) {
          invalidIsoCodesDetected++;
          issues.add(
            PpmModValidationIssue(
              code: 'INVALID_TEAM_ISO',
              section: 'teams',
              targetId: key,
              message:
                  'Nieprawidłowy kod ISO kraju "${t.countryIso}" dla drużyny "${t.name}" (wymagane 3 wielkie litery).',
              severity: PpmModValidationSeverity.error,
            ),
          );
        }
        for (final colorPair in [
          ('primary', t.primaryJerseyColorHex),
          ('secondary', t.secondaryJerseyColorHex),
          ('accent', t.accentJerseyColorHex),
        ]) {
          if (!_hexColorRegex.hasMatch(colorPair.$2.trim())) {
            invalidColorsDetected++;
            issues.add(
              PpmModValidationIssue(
                code: 'INVALID_TEAM_HEX',
                section: 'teams',
                targetId: key,
                message:
                    'Nieprawidłowy kolor ${colorPair.$1} "${colorPair.$2}" w drużynie "${t.name}".',
                severity: PpmModValidationSeverity.error,
              ),
            );
          }
        }
      }

      final seenRiderIds = <String>{};
      for (var i = 0; i < customMod.riders.length; i++) {
        final r = customMod.riders[i];
        final key = (r.matchId ?? r.fullName).trim();
        if (r.firstName.trim().isEmpty || r.lastName.trim().isEmpty) {
          issues.add(
            PpmModValidationIssue(
              code: 'RIDER_EMPTY_NAME',
              section: 'riders',
              targetId: key,
              message: 'Kolarz #$i ma puste imię lub nazwisko.',
              severity: PpmModValidationSeverity.error,
            ),
          );
        }
        if (r.matchId != null && r.matchId!.trim().isNotEmpty) {
          if (!seenRiderIds.add(r.matchId!.trim())) {
            duplicateIdsDetected++;
            issues.add(
              PpmModValidationIssue(
                code: 'DUPLICATE_RIDER_ID',
                section: 'riders',
                targetId: r.matchId,
                message: 'Zduplikowany matchId kolarza: "${r.matchId}".',
                severity: PpmModValidationSeverity.error,
              ),
            );
          }
        }
        if (!_countryIsoRegex.hasMatch(r.nationalityIso.trim().toUpperCase())) {
          invalidIsoCodesDetected++;
          issues.add(
            PpmModValidationIssue(
              code: 'INVALID_RIDER_ISO',
              section: 'riders',
              targetId: key,
              message:
                  'Nieprawidłowy kod ISO "${r.nationalityIso}" dla kolarza "${r.fullName}".',
              severity: PpmModValidationSeverity.error,
            ),
          );
        }
        if (r.birthYear != null && (r.birthYear! < 1950 || r.birthYear! > 2012)) {
          issues.add(
            PpmModValidationIssue(
              code: 'RIDER_BIRTH_YEAR_OUT_OF_RANGE',
              section: 'riders',
              targetId: key,
              message:
                  'Rok urodzenia ${r.birthYear} dla "${r.fullName}" poza zakresem 1950–2012.',
              severity: PpmModValidationSeverity.warning,
            ),
          );
        }
        if (r.targetOverallRating != null &&
            (r.targetOverallRating! < 40 || r.targetOverallRating! > 99)) {
          issues.add(
            PpmModValidationIssue(
              code: 'RIDER_OVR_OUT_OF_RANGE',
              section: 'riders',
              targetId: key,
              message:
                  'Ocena OVR ${r.targetOverallRating} dla "${r.fullName}" poza zakresem 40–99.',
              severity: PpmModValidationSeverity.error,
            ),
          );
        }
      }

      for (var i = 0; i < customMod.races.length; i++) {
        final race = customMod.races[i];
        if (race.name.trim().isEmpty) {
          issues.add(
            PpmModValidationIssue(
              code: 'RACE_EMPTY_NAME',
              section: 'races',
              targetId: race.matchId,
              message: 'Wyścig #$i ma pustą nazwę.',
              severity: PpmModValidationSeverity.error,
            ),
          );
        }
        if (race.countryIso != null &&
            !_countryIsoRegex.hasMatch(race.countryIso!.trim().toUpperCase())) {
          invalidIsoCodesDetected++;
          issues.add(
            PpmModValidationIssue(
              code: 'INVALID_RACE_ISO',
              section: 'races',
              targetId: race.matchId ?? race.name,
              message:
                  'Nieprawidłowy kod ISO "${race.countryIso}" dla wyścigu "${race.name}".',
              severity: PpmModValidationSeverity.error,
            ),
          );
        }
      }

      for (var i = 0; i < customMod.bikeManufacturers.length; i++) {
        final bike = customMod.bikeManufacturers[i];
        if (bike.realName.trim().isEmpty) {
          issues.add(
            PpmModValidationIssue(
              code: 'BIKE_EMPTY_NAME',
              section: 'brands',
              targetId: bike.matchId,
              message: 'Producent rowerów #$i ma pustą nazwę.',
              severity: PpmModValidationSeverity.error,
            ),
          );
        }
        if (!_countryIsoRegex.hasMatch(bike.countryIso.trim().toUpperCase())) {
          invalidIsoCodesDetected++;
          issues.add(
            PpmModValidationIssue(
              code: 'INVALID_BIKE_ISO',
              section: 'brands',
              targetId: bike.matchId ?? bike.realName,
              message:
                  'Nieprawidłowy kod ISO "${bike.countryIso}" dla marki "${bike.realName}".',
              severity: PpmModValidationSeverity.error,
            ),
          );
        }
        if (bike.primaryColorHex != null &&
            !_hexColorRegex.hasMatch(bike.primaryColorHex!.trim())) {
          invalidColorsDetected++;
          issues.add(
            PpmModValidationIssue(
              code: 'INVALID_BIKE_HEX',
              section: 'brands',
              targetId: bike.matchId ?? bike.realName,
              message:
                  'Nieprawidłowy kolor HEX "${bike.primaryColorHex}" dla marki "${bike.realName}".',
              severity: PpmModValidationSeverity.error,
            ),
          );
        }
      }
    }

    // Walidacja CommunityRealismPatchStructure za pomocą istniejącego ModSchemaValidator
    if (realismPatch != null) {
      teamsCount += realismPatch.teams.length;
      ridersCount += realismPatch.riders.length;
      racesCount += realismPatch.races.length;
      brandsCount += realismPatch.brands.length;

      final schemaReport = ModSchemaValidator.validateJson(
        jsonEncode(realismPatch.toJson()),
        activeSave: activeSave,
      );
      for (final issue in schemaReport.issues) {
        final mappedSeverity = switch (issue.severity) {
          ModSchemaIssueSeverity.error => PpmModValidationSeverity.error,
          ModSchemaIssueSeverity.warning => PpmModValidationSeverity.warning,
        };
        if (issue.field.toLowerCase().contains('hex')) {
          invalidColorsDetected++;
        } else if (issue.field.toLowerCase().contains('iso')) {
          invalidIsoCodesDetected++;
        } else if (issue.message.toLowerCase().contains('duplikat')) {
          duplicateIdsDetected++;
        }
        issues.add(
          PpmModValidationIssue(
            code: 'SCHEMA_${issue.field.toUpperCase()}',
            section: issue.section,
            targetId: issue.entryId,
            message: issue.message,
            severity: mappedSeverity,
          ),
        );
      }
    }

    // Walidacja zasobów osadzonych
    final seenAssetPaths = <String>{};
    var totalAssetBytes = 0;
    for (final asset in package.assets) {
      final path = asset.relativePath;
      if (path.isEmpty ||
          path.startsWith('/') ||
          path.startsWith('\\') ||
          path.contains('..') ||
          path.contains('\\') ||
          path.contains('\x00')) {
        issues.add(
          PpmModValidationIssue(
            code: 'UNSAFE_ASSET_PATH',
            section: 'assets',
            targetId: path,
            message: 'Niedozwolona ścieżka zasobu: "$path".',
            severity: PpmModValidationSeverity.error,
          ),
        );
      } else if (!seenAssetPaths.add(path)) {
        duplicateIdsDetected++;
        issues.add(
          PpmModValidationIssue(
            code: 'DUPLICATE_ASSET_PATH',
            section: 'assets',
            targetId: path,
            message: 'Zduplikowana ścieżka zasobu: "$path".',
            severity: PpmModValidationSeverity.error,
          ),
        );
      }

      if (asset.byteSize <= 0 || asset.byteSize > kMaxPpmModSingleAssetBytes) {
        issues.add(
          PpmModValidationIssue(
            code: 'ASSET_SIZE_INVALID',
            section: 'assets',
            targetId: path,
            message:
                'Rozmiar zasobu "$path" (${asset.byteSize} B) przekracza limit 5 MB lub jest <= 0.',
            severity: PpmModValidationSeverity.error,
          ),
        );
      }
      totalAssetBytes += asset.byteSize;

      if (asset.payloadBase64 != null) {
        try {
          final decodedBytes = base64Decode(asset.payloadBase64!);
          final computed = computeFnv1a64(base64Encode(decodedBytes));
          if (asset.fnv1a64Checksum.isNotEmpty &&
              asset.fnv1a64Checksum != computed) {
            issues.add(
              PpmModValidationIssue(
                code: 'ASSET_CHECKSUM_MISMATCH',
                section: 'assets',
                targetId: path,
                message: 'Niezgodna suma kontrolna FNV-1a64 zasobu "$path".',
                severity: PpmModValidationSeverity.error,
              ),
            );
          }
        } on FormatException {
          issues.add(
            PpmModValidationIssue(
              code: 'ASSET_INVALID_BASE64',
              section: 'assets',
              targetId: path,
              message: 'Uszkodzone kodowanie Base64 w zasobie "$path".',
              severity: PpmModValidationSeverity.error,
            ),
          );
        }
      }
    }

    if (totalAssetBytes > kMaxPpmModTotalAssetsBytes) {
      issues.add(
        PpmModValidationIssue(
          code: 'TOTAL_ASSETS_SIZE_EXCEEDED',
          section: 'assets',
          message:
              'Łączny rozmiar zasobów ($totalAssetBytes B) przekracza limit 25 MB.',
          severity: PpmModValidationSeverity.error,
        ),
      );
    }

    final canonicalJson = jsonEncode(package.toCanonicalPayloadJson());
    final estimatedBytes = utf8.encode(canonicalJson).length + totalAssetBytes;

    final errorCount =
        issues.where((i) => i.severity == PpmModValidationSeverity.error).length;
    final warningCount =
        issues.where((i) => i.severity == PpmModValidationSeverity.warning).length;
    final rawScore = 100 - (errorCount * 22) - (warningCount * 6);
    final readinessScore = rawScore.clamp(0, 100);

    return PpmModValidationReport(
      isValid: errorCount == 0,
      readinessScore: readinessScore,
      teamsCount: teamsCount,
      ridersCount: ridersCount,
      racesCount: racesCount,
      brandsCount: brandsCount,
      assetsCount: package.assets.length,
      estimatedBytes: estimatedBytes,
      duplicateIdsDetected: duplicateIdsDetected,
      invalidColorsDetected: invalidColorsDetected,
      invalidIsoCodesDetected: invalidIsoCodesDetected,
      issues: List<PpmModValidationIssue>.unmodifiable(issues),
    );
  }

  /// Koduje paczkę `.ppmmod` wraz z sumą kontrolną FNV-1a64 do łańcucha tekstowego.
  String encodeToPpmModString(
    PpmModPackage package, {
    PpmModExportCompression compression = PpmModExportCompression.gzipBase64,
  }) {
    final canonicalJson = jsonEncode(package.toCanonicalPayloadJson());
    final checksum = computeFnv1a64(canonicalJson);
    final signedPackage = package.copyWith(checksumFnv1a64: checksum);
    final fullJson = jsonEncode(signedPackage.toJson());

    if (compression == PpmModExportCompression.plainJson) {
      return fullJson;
    }

    final compressed = gzip.encode(utf8.encode(fullJson));
    return '$kPpmModGzipPrefix${base64Encode(compressed)}';
  }

  /// Dekoduje zawartość pliku `.ppmmod` (GZip lub JSON), weryfikuje sumę kontrolną i waliduje zawartość.
  PpmModImportResult decodeFromPpmModString(
    String rawContent, {
    bool verifyChecksum = true,
    CareerSave? activeSave,
  }) {
    final trimmed = rawContent.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Plik .ppmmod jest pusty.');
    }

    var wasCompressed = false;
    String jsonText;
    if (trimmed.startsWith(kPpmModGzipPrefix)) {
      wasCompressed = true;
      final b64Payload = trimmed.substring(kPpmModGzipPrefix.length).trim();
      final compressedBytes = base64Decode(b64Payload);
      final decompressedBytes = gzip.decode(compressedBytes);
      jsonText = utf8.decode(decompressedBytes);
    } else {
      jsonText = trimmed;
    }

    final decoded = jsonDecode(jsonText);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Korzeń pliku .ppmmod musi być obiektem JSON.');
    }

    final package = PpmModPackage.fromJson(decoded);
    final canonicalJson = jsonEncode(package.toCanonicalPayloadJson());
    final expectedChecksum = computeFnv1a64(canonicalJson);
    final checksumVerified = package.checksumFnv1a64.isNotEmpty &&
        package.checksumFnv1a64 == expectedChecksum;

    if (verifyChecksum && !checksumVerified) {
      throw FormatException(
        'Niezgodna suma kontrolna FNV-1a64 paczki .ppmmod '
        '(oczekiwano $expectedChecksum, otrzymano ${package.checksumFnv1a64}).',
      );
    }

    final report = validatePackage(package, activeSave: activeSave);
    return PpmModImportResult(
      package: package,
      validationReport: report,
      checksumVerified: checksumVerified,
      wasCompressed: wasCompressed,
    );
  }

  /// Eksportuje zwalidowaną paczkę `.ppmmod` atomowo na dysk (`.tmp` -> rename).
  Future<PpmModPackagingReceipt> exportToFile(
    PpmModPackage package,
    String outputPath, {
    PpmModExportCompression compression = PpmModExportCompression.gzipBase64,
    bool rejectInvalid = true,
    CareerSave? activeSave,
  }) async {
    final report = validatePackage(package, activeSave: activeSave);
    if (rejectInvalid && !report.isValid) {
      final firstError =
          report.errors.isNotEmpty ? report.errors.first.message : 'Błąd walidacji';
      throw StateError(
        'Eksport .ppmmod zablokowany (${report.errors.length} błędów): $firstError',
      );
    }

    final normalizedPath = outputPath.toLowerCase().endsWith(kPpmModFileExtension)
        ? outputPath
        : '$outputPath$kPpmModFileExtension';

    final canonicalJson = jsonEncode(package.toCanonicalPayloadJson());
    final checksum = computeFnv1a64(canonicalJson);
    final rawJsonBytes = utf8.encode(canonicalJson).length;
    final encoded = encodeToPpmModString(package, compression: compression);
    final encodedBytes = utf8.encode(encoded).length;

    final targetFile = File(normalizedPath);
    await targetFile.parent.create(recursive: true);
    final tmpFile = File('$normalizedPath.tmp');
    await tmpFile.writeAsString(encoded, flush: true);
    if (await targetFile.exists()) {
      await targetFile.delete();
    }
    await tmpFile.rename(normalizedPath);

    return PpmModPackagingReceipt(
      filePath: normalizedPath,
      modId: package.manifest.modId,
      title: package.manifest.title,
      compression: compression,
      rawJsonBytes: rawJsonBytes,
      encodedBytes: encodedBytes,
      checksumFnv1a64: checksum,
      validationReport: report,
      exportedAt: DateTime.now().toUtc(),
    );
  }

  /// Wczytuje i weryfikuje plik `.ppmmod` z dysku.
  Future<PpmModImportResult> importFromFile(
    String filePath, {
    bool verifyChecksum = true,
    CareerSave? activeSave,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('Nie znaleziono pliku .ppmmod', filePath);
    }
    final content = await file.readAsString();
    return decodeFromPpmModString(
      content,
      verifyChecksum: verifyChecksum,
      activeSave: activeSave,
    );
  }
}

/// Stan Riverpod dla panelu walidacji i pakowania paczek `.ppmmod`.
class ModWorkshopPackagerState {
  final PpmModPackage activePackage;
  final PpmModValidationReport? lastReport;
  final PpmModPackagingReceipt? lastReceipt;
  final PpmModExportCompression compression;
  final PpmModValidationSeverity? issueFilter;
  final bool isBusy;
  final String? statusMessage;
  final String? errorMessage;

  const ModWorkshopPackagerState({
    required this.activePackage,
    this.lastReport,
    this.lastReceipt,
    this.compression = PpmModExportCompression.gzipBase64,
    this.issueFilter,
    this.isBusy = false,
    this.statusMessage,
    this.errorMessage,
  });

  ModWorkshopPackagerState copyWith({
    PpmModPackage? activePackage,
    PpmModValidationReport? lastReport,
    PpmModPackagingReceipt? lastReceipt,
    PpmModExportCompression? compression,
    PpmModValidationSeverity? issueFilter,
    bool clearIssueFilter = false,
    bool? isBusy,
    String? statusMessage,
    String? errorMessage,
    bool clearMessages = false,
  }) {
    return ModWorkshopPackagerState(
      activePackage: activePackage ?? this.activePackage,
      lastReport: lastReport ?? this.lastReport,
      lastReceipt: lastReceipt ?? this.lastReceipt,
      compression: compression ?? this.compression,
      issueFilter: clearIssueFilter ? null : (issueFilter ?? this.issueFilter),
      isBusy: isBusy ?? this.isBusy,
      statusMessage:
          clearMessages ? null : (statusMessage ?? this.statusMessage),
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Notifier zarządzający stanem walidacji i eksportu `.ppmmod`.
class ModWorkshopPackagerNotifier
    extends StateNotifier<ModWorkshopPackagerState> {
  final ModWorkshopValidatorAndPackager _packager;

  ModWorkshopPackagerNotifier({
    ModWorkshopValidatorAndPackager packager =
        const ModWorkshopValidatorAndPackager(),
    PpmModPackage? initialPackage,
  })  : _packager = packager,
        super(
          ModWorkshopPackagerState(
            activePackage:
                initialPackage ?? packager.createStarterTemplatePackage(),
          ),
        ) {
    validateActivePackage();
  }

  void setPackage(PpmModPackage package) {
    final report = _packager.validatePackage(package);
    state = state.copyWith(
      activePackage: package,
      lastReport: report,
      clearMessages: true,
    );
  }

  void updateContentType(PpmModContentType contentType) {
    final updated = state.activePackage.copyWith(
      manifest: state.activePackage.manifest.copyWith(contentType: contentType),
    );
    setPackage(updated);
  }

  void setCompression(PpmModExportCompression compression) {
    state = state.copyWith(compression: compression, clearMessages: true);
  }

  void setIssueFilter(PpmModValidationSeverity? filter) {
    if (filter == null) {
      state = state.copyWith(clearIssueFilter: true);
    } else {
      state = state.copyWith(issueFilter: filter);
    }
  }

  void loadStarterTemplate() {
    final starter = _packager.createStarterTemplatePackage();
    final report = _packager.validatePackage(starter);
    state = state.copyWith(
      activePackage: starter,
      lastReport: report,
      statusMessage: 'Załadowano szablon startowy .ppmmod.',
      errorMessage: null,
    );
  }

  PpmModValidationReport validateActivePackage({CareerSave? activeSave}) {
    final report = _packager.validatePackage(
      state.activePackage,
      activeSave: activeSave,
    );
    state = state.copyWith(
      lastReport: report,
      statusMessage: report.isValid
          ? 'Walidacja zakończona sukcesem (${report.readinessScore}/100).'
          : 'Wykryto ${report.errors.length} błędów walidacji.',
      errorMessage: null,
    );
    return report;
  }

  Future<PpmModPackagingReceipt?> exportActivePackage(String outputPath) async {
    state = state.copyWith(isBusy: true, clearMessages: true);
    try {
      final receipt = await _packager.exportToFile(
        state.activePackage,
        outputPath,
        compression: state.compression,
      );
      state = state.copyWith(
        isBusy: false,
        lastReceipt: receipt,
        lastReport: receipt.validationReport,
        statusMessage:
            'Wyeksportowano ${receipt.modId}$kPpmModFileExtension (${receipt.encodedBytes} B).',
      );
      return receipt;
    } catch (e) {
      state = state.copyWith(
        isBusy: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  Future<PpmModImportResult?> importPackageFromFile(String filePath) async {
    state = state.copyWith(isBusy: true, clearMessages: true);
    try {
      final result = await _packager.importFromFile(filePath);
      state = state.copyWith(
        isBusy: false,
        activePackage: result.package,
        lastReport: result.validationReport,
        statusMessage:
            'Wczytano "${result.package.manifest.title}" (FNV-1a64 zweryfikowana).',
      );
      return result;
    } catch (e) {
      state = state.copyWith(
        isBusy: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }
}

/// Provider walidatora i eksportera `.ppmmod`.
final modWorkshopPackagerProvider = StateNotifierProvider<
    ModWorkshopPackagerNotifier, ModWorkshopPackagerState>(
  (ref) => ModWorkshopPackagerNotifier(),
);

/// Responsywny panel UI walidatora i eksportera paczek `.ppmmod`.
class ModWorkshopValidatorAndPackagerPanel extends ConsumerStatefulWidget {
  final bool isReadOnly;
  final VoidCallback? onExportRequested;

  const ModWorkshopValidatorAndPackagerPanel({
    super.key,
    this.isReadOnly = false,
    this.onExportRequested,
  });

  @override
  ConsumerState<ModWorkshopValidatorAndPackagerPanel> createState() =>
      _ModWorkshopValidatorAndPackagerPanelState();
}

class _ModWorkshopValidatorAndPackagerPanelState
    extends ConsumerState<ModWorkshopValidatorAndPackagerPanel> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(modWorkshopPackagerProvider);
    final notifier = ref.read(modWorkshopPackagerProvider.notifier);
    final report = state.lastReport;
    final manifest = state.activePackage.manifest;
    final disabled = widget.isReadOnly || state.isBusy;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;
        final isWide = constraints.maxWidth >= 1000;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 1),
          ),
          padding: EdgeInsets.all(isCompact ? 12 : 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderCard(manifest, report, isCompact),
                const SizedBox(height: 16),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: _buildConfigurationCard(
                          state,
                          notifier,
                          disabled,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 7,
                        child: _buildIssuesCard(state, notifier, report, disabled),
                      ),
                    ],
                  )
                else ...[
                  _buildConfigurationCard(state, notifier, disabled),
                  const SizedBox(height: 16),
                  _buildIssuesCard(state, notifier, report, disabled),
                ],
                if (state.statusMessage != null || state.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  _buildStatusBanner(state),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderCard(
    PpmModManifest manifest,
    PpmModValidationReport? report,
    bool isCompact,
  ) {
    final score = report?.readinessScore ?? 0;
    final isValid = report?.isValid ?? false;
    final scoreColor = isValid
        ? (score >= 85 ? AppColors.statusSuccess : AppColors.goldAccent)
        : AppColors.crimsonAlert;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      padding: EdgeInsets.all(isCompact ? 14 : 18),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      color: AppColors.goldAccent,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Workshop .ppmmod Validator & Packager',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${manifest.title} • v${manifest.version} • ${manifest.author}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildMetricChip('Drużyny', '${report?.teamsCount ?? 0}'),
                    _buildMetricChip('Kolarze', '${report?.ridersCount ?? 0}'),
                    _buildMetricChip('Wyścigi', '${report?.racesCount ?? 0}'),
                    _buildMetricChip('Marki', '${report?.brandsCount ?? 0}'),
                    _buildMetricChip('Zasoby', '${report?.assetsCount ?? 0}'),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scoreColor.withValues(alpha: 0.6)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$score / 100',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: scoreColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isValid ? 'GOTOWA DO EKSPORTU' : 'WYMAGA POPRAWEK',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: scoreColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip(String label, String value) {
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
          fontSize: 12,
          color: AppColors.textPrimary,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  Widget _buildConfigurationCard(
    ModWorkshopPackagerState state,
    ModWorkshopPackagerNotifier notifier,
    bool disabled,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Konfiguracja paczki .ppmmod',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Typ zawartości',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PpmModContentType.values.map((type) {
              final selected = state.activePackage.manifest.contentType == type;
              return _InteractiveWorkshopChip(
                label: type.labelPl,
                selected: selected,
                disabled: disabled,
                onTap: () => notifier.updateContentType(type),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text(
            'Format kompresji',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PpmModExportCompression.values.map((comp) {
              final selected = state.compression == comp;
              return _InteractiveWorkshopChip(
                label: comp.labelPl,
                selected: selected,
                disabled: disabled,
                onTap: () => notifier.setCompression(comp),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InteractiveWorkshopButton(
                label: 'Waliduj Paczkę',
                icon: Icons.verified_outlined,
                isPrimary: false,
                disabled: disabled,
                onPressed: () => notifier.validateActivePackage(),
              ),
              _InteractiveWorkshopButton(
                label: 'Załaduj Szablon',
                icon: Icons.auto_fix_high_outlined,
                isPrimary: false,
                disabled: disabled,
                onPressed: notifier.loadStarterTemplate,
              ),
              _InteractiveWorkshopButton(
                label: 'Eksportuj .ppmmod',
                icon: Icons.archive_outlined,
                isPrimary: true,
                disabled: disabled || !(state.lastReport?.isValid ?? false),
                onPressed: widget.onExportRequested ??
                    () => notifier.validateActivePackage(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIssuesCard(
    ModWorkshopPackagerState state,
    ModWorkshopPackagerNotifier notifier,
    PpmModValidationReport? report,
    bool disabled,
  ) {
    final allIssues = report?.issues ?? const <PpmModValidationIssue>[];
    final filtered = state.issueFilter == null
        ? allIssues
        : allIssues.where((i) => i.severity == state.issueFilter).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      padding: const EdgeInsets.all(16),
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
                'Raport walidacji (${filtered.length})',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _InteractiveWorkshopChip(
                    label: 'Wszystkie',
                    selected: state.issueFilter == null,
                    disabled: disabled,
                    onTap: () => notifier.setIssueFilter(null),
                  ),
                  _InteractiveWorkshopChip(
                    label: 'Błędy (${report?.errors.length ?? 0})',
                    selected: state.issueFilter == PpmModValidationSeverity.error,
                    disabled: disabled,
                    onTap: () =>
                        notifier.setIssueFilter(PpmModValidationSeverity.error),
                  ),
                  _InteractiveWorkshopChip(
                    label: 'Ostrzeżenia (${report?.warnings.length ?? 0})',
                    selected:
                        state.issueFilter == PpmModValidationSeverity.warning,
                    disabled: disabled,
                    onTap: () => notifier
                        .setIssueFilter(PpmModValidationSeverity.warning),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: AppColors.statusSuccess,
                    size: 18,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Brak wykrytych problemów w wybranym filtrze. Paczka spełnia standard .ppmmod.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: filtered.take(12).map((issue) {
                final color = switch (issue.severity) {
                  PpmModValidationSeverity.error => AppColors.crimsonAlert,
                  PpmModValidationSeverity.warning => AppColors.amberWarning,
                  PpmModValidationSeverity.info => AppColors.accentBlue,
                };
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withValues(alpha: 0.45)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          issue.severity == PpmModValidationSeverity.error
                              ? Icons.error_outline
                              : issue.severity == PpmModValidationSeverity.warning
                                  ? Icons.warning_amber_rounded
                                  : Icons.info_outline,
                          color: color,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '[${issue.section.toUpperCase()}] ${issue.code}',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                issue.message,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(ModWorkshopPackagerState state) {
    final isError = state.errorMessage != null;
    final color = isError ? AppColors.crimsonAlert : AppColors.statusSuccess;
    final text = state.errorMessage ?? state.statusMessage ?? '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _InteractiveWorkshopChip extends StatefulWidget {
  final String label;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  const _InteractiveWorkshopChip({
    required this.label,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  @override
  State<_InteractiveWorkshopChip> createState() =>
      _InteractiveWorkshopChipState();
}

class _InteractiveWorkshopChipState extends State<_InteractiveWorkshopChip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.disabled
        ? AppColors.surfaceLight.withValues(alpha: 0.45)
        : widget.selected
            ? AppColors.primaryAccent.withValues(alpha: _pressed ? 0.95 : 0.85)
            : (_hovered
                ? AppColors.surfaceLight
                : AppColors.background);

    final borderColor = widget.disabled
        ? AppColors.cardBorder.withValues(alpha: 0.4)
        : widget.selected
            ? AppColors.goldAccent
            : (_focused ? AppColors.accentBlue : AppColors.cardBorder);

    return FocusableActionDetector(
      enabled: !widget.disabled,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      child: GestureDetector(
        onTapDown: widget.disabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: widget.disabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.disabled ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
              color: widget.disabled
                  ? AppColors.textSecondary.withValues(alpha: 0.5)
                  : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractiveWorkshopButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final bool disabled;
  final VoidCallback onPressed;

  const _InteractiveWorkshopButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.disabled,
    required this.onPressed,
  });

  @override
  State<_InteractiveWorkshopButton> createState() =>
      _InteractiveWorkshopButtonState();
}

class _InteractiveWorkshopButtonState extends State<_InteractiveWorkshopButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final baseBg = widget.isPrimary
        ? AppColors.primaryAccent
        : AppColors.surfaceLight;
    final bgColor = widget.disabled
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : _pressed
            ? baseBg.withValues(alpha: 0.75)
            : (_hovered ? baseBg.withValues(alpha: 0.92) : baseBg);

    final borderColor = widget.disabled
        ? AppColors.cardBorder.withValues(alpha: 0.4)
        : _focused
            ? AppColors.accentBlue
            : (widget.isPrimary ? AppColors.goldAccent : AppColors.cardBorder);

    return FocusableActionDetector(
      enabled: !widget.disabled,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      child: GestureDetector(
        onTapDown: widget.disabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: widget.disabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.disabled ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: widget.disabled
                    ? AppColors.textSecondary.withValues(alpha: 0.5)
                    : (widget.isPrimary
                        ? AppColors.goldAccent
                        : AppColors.textPrimary),
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: widget.disabled
                      ? AppColors.textSecondary.withValues(alpha: 0.5)
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
