import 'dart:convert';
import 'dart:io';

import '../../models/career/career_save.dart';
import '../../models/career/season_calendar.dart';
import '../../models/race/tour_race.dart';
import '../../models/rider/rider.dart';
import '../../models/team/cycling_team.dart';
import '../../models/team/sponsor_contract.dart';
import '../generators/fictional_brands_catalog.dart';
import '../generators/uci_calendar_generator.dart';
import '../generators/world_teams_generator.dart';
import 'custom_mod_importer_service.dart';

/// Wpis mapowania pojedynczej drużyny w strukturze Community Realism Patch.
class TeamPatchEntry {
  final String originalId;
  final String originalName;
  final String division;
  final String customName;
  final String customShortName;
  final String customCountryIso;
  final String primaryHex;
  final String secondaryHex;
  final String? accentHex;
  final int jerseyPatternIndex;
  final String? sponsorCompanyName;

  const TeamPatchEntry({
    required this.originalId,
    this.originalName = '',
    this.division = 'worldTour',
    required this.customName,
    required this.customShortName,
    required this.customCountryIso,
    required this.primaryHex,
    required this.secondaryHex,
    this.accentHex,
    required this.jerseyPatternIndex,
    this.sponsorCompanyName,
  });

  TeamPatchEntry copyWith({
    String? originalId,
    String? originalName,
    String? division,
    String? customName,
    String? customShortName,
    String? customCountryIso,
    String? primaryHex,
    String? secondaryHex,
    String? accentHex,
    int? jerseyPatternIndex,
    String? sponsorCompanyName,
  }) {
    return TeamPatchEntry(
      originalId: originalId ?? this.originalId,
      originalName: originalName ?? this.originalName,
      division: division ?? this.division,
      customName: customName ?? this.customName,
      customShortName: customShortName ?? this.customShortName,
      customCountryIso: customCountryIso ?? this.customCountryIso,
      primaryHex: primaryHex ?? this.primaryHex,
      secondaryHex: secondaryHex ?? this.secondaryHex,
      accentHex: accentHex ?? this.accentHex,
      jerseyPatternIndex: jerseyPatternIndex ?? this.jerseyPatternIndex,
      sponsorCompanyName: sponsorCompanyName ?? this.sponsorCompanyName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'originalId': originalId,
      if (originalName.isNotEmpty) 'originalName': originalName,
      if (division.isNotEmpty) 'division': division,
      'customName': customName,
      'customShortName': customShortName,
      'customCountryIso': customCountryIso,
      'primaryHex': primaryHex,
      'secondaryHex': secondaryHex,
      if (accentHex != null) 'accentHex': accentHex,
      'jerseyPatternIndex': jerseyPatternIndex,
      if (sponsorCompanyName != null) 'sponsorCompanyName': sponsorCompanyName,
    };
  }

  factory TeamPatchEntry.fromJson(Map<String, dynamic> json) {
    return TeamPatchEntry(
      originalId: (json['originalId'] as String? ?? '').trim(),
      originalName: (json['originalName'] as String? ?? '').trim(),
      division: (json['division'] as String? ?? 'worldTour').trim(),
      customName: (json['customName'] as String? ?? '').trim(),
      customShortName: (json['customShortName'] as String? ?? '').trim().toUpperCase(),
      customCountryIso: (json['customCountryIso'] as String? ?? '').trim().toUpperCase(),
      primaryHex: (json['primaryHex'] as String? ?? '').trim(),
      secondaryHex: (json['secondaryHex'] as String? ?? '').trim(),
      accentHex: (json['accentHex'] as String?)?.trim(),
      jerseyPatternIndex: (json['jerseyPatternIndex'] as num?)?.toInt() ?? 0,
      sponsorCompanyName: (json['sponsorCompanyName'] as String?)?.trim(),
    );
  }
}

/// Wpis mapowania pojedynczego kolarza w strukturze Community Realism Patch.
class RiderPatchEntry {
  final String originalId;
  final String originalName;
  final String teamId;
  final String role;
  final String specialization;
  final String customName;
  final String customShortName;
  final String customCountryIso;
  final String primaryHex;
  final String secondaryHex;
  final int jerseyPatternIndex;

  const RiderPatchEntry({
    required this.originalId,
    this.originalName = '',
    this.teamId = '',
    this.role = '',
    this.specialization = '',
    required this.customName,
    required this.customShortName,
    required this.customCountryIso,
    required this.primaryHex,
    required this.secondaryHex,
    required this.jerseyPatternIndex,
  });

  RiderPatchEntry copyWith({
    String? originalId,
    String? originalName,
    String? teamId,
    String? role,
    String? specialization,
    String? customName,
    String? customShortName,
    String? customCountryIso,
    String? primaryHex,
    String? secondaryHex,
    int? jerseyPatternIndex,
  }) {
    return RiderPatchEntry(
      originalId: originalId ?? this.originalId,
      originalName: originalName ?? this.originalName,
      teamId: teamId ?? this.teamId,
      role: role ?? this.role,
      specialization: specialization ?? this.specialization,
      customName: customName ?? this.customName,
      customShortName: customShortName ?? this.customShortName,
      customCountryIso: customCountryIso ?? this.customCountryIso,
      primaryHex: primaryHex ?? this.primaryHex,
      secondaryHex: secondaryHex ?? this.secondaryHex,
      jerseyPatternIndex: jerseyPatternIndex ?? this.jerseyPatternIndex,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'originalId': originalId,
      if (originalName.isNotEmpty) 'originalName': originalName,
      if (teamId.isNotEmpty) 'teamId': teamId,
      if (role.isNotEmpty) 'role': role,
      if (specialization.isNotEmpty) 'specialization': specialization,
      'customName': customName,
      'customShortName': customShortName,
      'customCountryIso': customCountryIso,
      'primaryHex': primaryHex,
      'secondaryHex': secondaryHex,
      'jerseyPatternIndex': jerseyPatternIndex,
    };
  }

  factory RiderPatchEntry.fromJson(Map<String, dynamic> json) {
    return RiderPatchEntry(
      originalId: (json['originalId'] as String? ?? '').trim(),
      originalName: (json['originalName'] as String? ?? '').trim(),
      teamId: (json['teamId'] as String? ?? '').trim(),
      role: (json['role'] as String? ?? '').trim(),
      specialization: (json['specialization'] as String? ?? '').trim(),
      customName: (json['customName'] as String? ?? '').trim(),
      customShortName: (json['customShortName'] as String? ?? '').trim(),
      customCountryIso: (json['customCountryIso'] as String? ?? '').trim().toUpperCase(),
      primaryHex: (json['primaryHex'] as String? ?? '').trim(),
      secondaryHex: (json['secondaryHex'] as String? ?? '').trim(),
      jerseyPatternIndex: (json['jerseyPatternIndex'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Wpis mapowania pojedynczego wyścigu w strukturze Community Realism Patch.
class RacePatchEntry {
  final String originalId;
  final String originalName;
  final String uciCategory;
  final String customName;
  final String customShortName;
  final String customCountryIso;
  final String primaryHex;
  final String secondaryHex;
  final int jerseyPatternIndex;

  const RacePatchEntry({
    required this.originalId,
    this.originalName = '',
    this.uciCategory = '',
    required this.customName,
    required this.customShortName,
    required this.customCountryIso,
    required this.primaryHex,
    required this.secondaryHex,
    required this.jerseyPatternIndex,
  });

  RacePatchEntry copyWith({
    String? originalId,
    String? originalName,
    String? uciCategory,
    String? customName,
    String? customShortName,
    String? customCountryIso,
    String? primaryHex,
    String? secondaryHex,
    int? jerseyPatternIndex,
  }) {
    return RacePatchEntry(
      originalId: originalId ?? this.originalId,
      originalName: originalName ?? this.originalName,
      uciCategory: uciCategory ?? this.uciCategory,
      customName: customName ?? this.customName,
      customShortName: customShortName ?? this.customShortName,
      customCountryIso: customCountryIso ?? this.customCountryIso,
      primaryHex: primaryHex ?? this.primaryHex,
      secondaryHex: secondaryHex ?? this.secondaryHex,
      jerseyPatternIndex: jerseyPatternIndex ?? this.jerseyPatternIndex,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'originalId': originalId,
      if (originalName.isNotEmpty) 'originalName': originalName,
      if (uciCategory.isNotEmpty) 'uciCategory': uciCategory,
      'customName': customName,
      'customShortName': customShortName,
      'customCountryIso': customCountryIso,
      'primaryHex': primaryHex,
      'secondaryHex': secondaryHex,
      'jerseyPatternIndex': jerseyPatternIndex,
    };
  }

  factory RacePatchEntry.fromJson(Map<String, dynamic> json) {
    return RacePatchEntry(
      originalId: (json['originalId'] as String? ?? '').trim(),
      originalName: (json['originalName'] as String? ?? '').trim(),
      uciCategory: (json['uciCategory'] as String? ?? '').trim(),
      customName: (json['customName'] as String? ?? '').trim(),
      customShortName: (json['customShortName'] as String? ?? '').trim().toUpperCase(),
      customCountryIso: (json['customCountryIso'] as String? ?? '').trim().toUpperCase(),
      primaryHex: (json['primaryHex'] as String? ?? '').trim(),
      secondaryHex: (json['secondaryHex'] as String? ?? '').trim(),
      jerseyPatternIndex: (json['jerseyPatternIndex'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Wpis mapowania marki sprzętu / producenta rowerów w strukturze Community Realism Patch.
class BrandPatchEntry {
  final String originalId;
  final String originalName;
  final String customName;
  final String customShortName;
  final String customCountryIso;
  final String primaryHex;
  final String secondaryHex;
  final int jerseyPatternIndex;

  const BrandPatchEntry({
    required this.originalId,
    this.originalName = '',
    required this.customName,
    required this.customShortName,
    required this.customCountryIso,
    required this.primaryHex,
    required this.secondaryHex,
    required this.jerseyPatternIndex,
  });

  BrandPatchEntry copyWith({
    String? originalId,
    String? originalName,
    String? customName,
    String? customShortName,
    String? customCountryIso,
    String? primaryHex,
    String? secondaryHex,
    int? jerseyPatternIndex,
  }) {
    return BrandPatchEntry(
      originalId: originalId ?? this.originalId,
      originalName: originalName ?? this.originalName,
      customName: customName ?? this.customName,
      customShortName: customShortName ?? this.customShortName,
      customCountryIso: customCountryIso ?? this.customCountryIso,
      primaryHex: primaryHex ?? this.primaryHex,
      secondaryHex: secondaryHex ?? this.secondaryHex,
      jerseyPatternIndex: jerseyPatternIndex ?? this.jerseyPatternIndex,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'originalId': originalId,
      if (originalName.isNotEmpty) 'originalName': originalName,
      'customName': customName,
      'customShortName': customShortName,
      'customCountryIso': customCountryIso,
      'primaryHex': primaryHex,
      'secondaryHex': secondaryHex,
      'jerseyPatternIndex': jerseyPatternIndex,
    };
  }

  factory BrandPatchEntry.fromJson(Map<String, dynamic> json) {
    return BrandPatchEntry(
      originalId: (json['originalId'] as String? ?? '').trim(),
      originalName: (json['originalName'] as String? ?? '').trim(),
      customName: (json['customName'] as String? ?? '').trim(),
      customShortName: (json['customShortName'] as String? ?? '').trim().toUpperCase(),
      customCountryIso: (json['customCountryIso'] as String? ?? '').trim().toUpperCase(),
      primaryHex: (json['primaryHex'] as String? ?? '').trim(),
      secondaryHex: (json['secondaryHex'] as String? ?? '').trim(),
      jerseyPatternIndex: (json['jerseyPatternIndex'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Kompletna struktura pakietu modyfikacji społecznościowej (`Community Realism Patch Structure`).
class CommunityRealismPatchStructure {
  final String schemaVersion;
  final String structureType;
  final CustomModMetadata metadata;
  final List<TeamPatchEntry> teams;
  final List<RiderPatchEntry> riders;
  final List<RacePatchEntry> races;
  final List<BrandPatchEntry> brands;

  const CommunityRealismPatchStructure({
    this.schemaVersion = PresetRealNamesTemplateGenerator.schemaVersion,
    this.structureType = PresetRealNamesTemplateGenerator.communityPatchStructureName,
    required this.metadata,
    required this.teams,
    required this.riders,
    required this.races,
    required this.brands,
  });

  CommunityRealismPatchStructure copyWith({
    String? schemaVersion,
    String? structureType,
    CustomModMetadata? metadata,
    List<TeamPatchEntry>? teams,
    List<RiderPatchEntry>? riders,
    List<RacePatchEntry>? races,
    List<BrandPatchEntry>? brands,
  }) {
    return CommunityRealismPatchStructure(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      structureType: structureType ?? this.structureType,
      metadata: metadata ?? this.metadata,
      teams: teams != null ? List<TeamPatchEntry>.unmodifiable(teams) : this.teams,
      riders: riders != null ? List<RiderPatchEntry>.unmodifiable(riders) : this.riders,
      races: races != null ? List<RacePatchEntry>.unmodifiable(races) : this.races,
      brands: brands != null ? List<BrandPatchEntry>.unmodifiable(brands) : this.brands,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'structureType': structureType,
      'metadata': metadata.toJson(),
      'teams': teams.map((e) => e.toJson()).toList(),
      'riders': riders.map((e) => e.toJson()).toList(),
      'races': races.map((e) => e.toJson()).toList(),
      'brands': brands.map((e) => e.toJson()).toList(),
    };
  }

  String toPrettyJson() {
    return const JsonEncoder.withIndent('  ').convert(toJson());
  }

  factory CommunityRealismPatchStructure.fromJson(Map<String, dynamic> json) {
    final teamsList = (json['teams'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(TeamPatchEntry.fromJson)
        .toList();
    final ridersList = (json['riders'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(RiderPatchEntry.fromJson)
        .toList();
    final racesList = (json['races'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(RacePatchEntry.fromJson)
        .toList();
    final brandsRaw = json['brands'] ?? json['bikeManufacturers'];
    final brandsList = (brandsRaw as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(BrandPatchEntry.fromJson)
        .toList();

    return CommunityRealismPatchStructure(
      schemaVersion: json['schemaVersion'] as String? ??
          PresetRealNamesTemplateGenerator.schemaVersion,
      structureType: json['structureType'] as String? ??
          PresetRealNamesTemplateGenerator.communityPatchStructureName,
      metadata: CustomModMetadata.fromJson(
        json['metadata'] as Map<String, dynamic>? ?? const {},
      ),
      teams: List<TeamPatchEntry>.unmodifiable(teamsList),
      riders: List<RiderPatchEntry>.unmodifiable(ridersList),
      races: List<RacePatchEntry>.unmodifiable(racesList),
      brands: List<BrandPatchEntry>.unmodifiable(brandsList),
    );
  }

  /// Konwertuje strukturę szablonu do formatu [CustomModPackage] używanego przez importer modów.
  CustomModPackage toCustomModPackage() {
    return CustomModPackage(
      metadata: metadata,
      teams: teams
          .map(
            (t) => TeamModEntry(
              matchId: t.originalId,
              matchOriginalName: t.originalName.isNotEmpty ? t.originalName : null,
              name: t.customName,
              countryIso: t.customCountryIso,
              primaryJerseyColorHex: t.primaryHex,
              secondaryJerseyColorHex: t.secondaryHex,
              accentJerseyColorHex: t.accentHex ?? t.secondaryHex,
              sponsorCompanyName: t.sponsorCompanyName,
            ),
          )
          .toList(),
      riders: riders.map((r) {
        final parts = PresetRealNamesTemplateGenerator.splitFullName(r.customName);
        return RiderModEntry(
          matchId: r.originalId,
          matchOriginalFullName: r.originalName.isNotEmpty ? r.originalName : null,
          matchTeamId: r.teamId.isNotEmpty ? r.teamId : null,
          firstName: parts.$1,
          lastName: parts.$2,
          nationalityIso: r.customCountryIso,
        );
      }).toList(),
      races: races
          .map(
            (rc) => RaceModEntry(
              matchId: rc.originalId,
              name: rc.customName,
              countryIso: rc.customCountryIso,
            ),
          )
          .toList(),
      bikeManufacturers: brands
          .map(
            (b) => BikeModEntry(
              matchId: b.originalId,
              matchName: b.originalName.isNotEmpty ? b.originalName : null,
              realName: b.customName,
              countryIso: b.customCountryIso,
              primaryColorHex: b.primaryHex,
            ),
          )
          .toList(),
    );
  }
}

/// Poziom ważności błędu w walidatorze schematu paczki modyfikacji.
enum ModSchemaIssueSeverity {
  error,
  warning,
}

/// Pojedynczy problem wykryty przez [ModSchemaValidator].
class ModSchemaValidationIssue {
  final ModSchemaIssueSeverity severity;
  final String section;
  final String? entryId;
  final String field;
  final String message;

  const ModSchemaValidationIssue({
    required this.severity,
    required this.section,
    this.entryId,
    required this.field,
    required this.message,
  });

  Map<String, dynamic> toJson() {
    return {
      'severity': severity.name,
      'section': section,
      if (entryId != null) 'entryId': entryId,
      'field': field,
      'message': message,
    };
  }
}

/// Szczegółowy raport walidacji schematu zwracany przez [ModSchemaValidator].
class ModSchemaValidationReport {
  final bool isValid;
  final List<ModSchemaValidationIssue> issues;
  final int totalTeamsInPatch;
  final int totalRidersInPatch;
  final int totalRacesInPatch;
  final int totalBrandsInPatch;
  final int teamsReplacedCount;
  final int ridersReplacedCount;
  final int racesReplacedCount;
  final int brandsReplacedCount;
  final String summary;

  const ModSchemaValidationReport({
    required this.isValid,
    required this.issues,
    required this.totalTeamsInPatch,
    required this.totalRidersInPatch,
    required this.totalRacesInPatch,
    required this.totalBrandsInPatch,
    required this.teamsReplacedCount,
    required this.ridersReplacedCount,
    required this.racesReplacedCount,
    required this.brandsReplacedCount,
    required this.summary,
  });

  List<ModSchemaValidationIssue> get errors =>
      issues.where((i) => i.severity == ModSchemaIssueSeverity.error).toList();

  List<ModSchemaValidationIssue> get warnings =>
      issues.where((i) => i.severity == ModSchemaIssueSeverity.warning).toList();
}

/// Walidator schematu paczki modyfikacji sprawdzający HEX, unikalność ID oraz wymagane klucze.
class ModSchemaValidator {
  ModSchemaValidator._();

  static final RegExp _hexColorRegex = RegExp(r'^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$');
  static final RegExp _countryIsoRegex = RegExp(r'^[A-Z]{3}$');

  static const List<String> requiredTopLevelKeys = [
    'schemaVersion',
    'structureType',
    'metadata',
    'teams',
    'riders',
    'races',
    'brands',
  ];

  static const List<String> requiredEntryKeys = [
    'originalId',
    'customName',
    'customShortName',
    'customCountryIso',
    'primaryHex',
    'secondaryHex',
    'jerseyPatternIndex',
  ];

  /// Sprawdza czy ciąg znaków jest poprawnym kolorem HEX (#RRGGBB lub #AARRGGBB).
  static bool isValidHexColor(String value) => _hexColorRegex.hasMatch(value.trim());

  /// Waliduje surowy plik JSON z paczką modyfikacji przed jej zaaplikowaniem.
  static ModSchemaValidationReport validateJson(
    String jsonString, {
    CareerSave? activeSave,
  }) {
    if (jsonString.trim().isEmpty) {
      return const ModSchemaValidationReport(
        isValid: false,
        issues: [
          ModSchemaValidationIssue(
            severity: ModSchemaIssueSeverity.error,
            section: 'root',
            field: 'json',
            message: 'Zawartość JSON paczki modyfikacji jest pusta.',
          ),
        ],
        totalTeamsInPatch: 0,
        totalRidersInPatch: 0,
        totalRacesInPatch: 0,
        totalBrandsInPatch: 0,
        teamsReplacedCount: 0,
        ridersReplacedCount: 0,
        racesReplacedCount: 0,
        brandsReplacedCount: 0,
        summary: 'Walidacja nieudana: pusty dokument JSON.',
      );
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(jsonString);
    } catch (e) {
      return ModSchemaValidationReport(
        isValid: false,
        issues: [
          ModSchemaValidationIssue(
            severity: ModSchemaIssueSeverity.error,
            section: 'root',
            field: 'syntax',
            message: 'Błąd składniowy JSON: $e',
          ),
        ],
        totalTeamsInPatch: 0,
        totalRidersInPatch: 0,
        totalRacesInPatch: 0,
        totalBrandsInPatch: 0,
        teamsReplacedCount: 0,
        ridersReplacedCount: 0,
        racesReplacedCount: 0,
        brandsReplacedCount: 0,
        summary: 'Walidacja nieudana: niepoprawna składnia JSON.',
      );
    }

    if (decoded is! Map<String, dynamic>) {
      return const ModSchemaValidationReport(
        isValid: false,
        issues: [
          ModSchemaValidationIssue(
            severity: ModSchemaIssueSeverity.error,
            section: 'root',
            field: 'root',
            message: 'Główny element JSON musi być obiektem (Map).',
          ),
        ],
        totalTeamsInPatch: 0,
        totalRidersInPatch: 0,
        totalRacesInPatch: 0,
        totalBrandsInPatch: 0,
        teamsReplacedCount: 0,
        ridersReplacedCount: 0,
        racesReplacedCount: 0,
        brandsReplacedCount: 0,
        summary: 'Walidacja nieudana: nieprawidłowy typ dokumentu głównego.',
      );
    }

    return validateRawMap(decoded, activeSave: activeSave);
  }

  /// Waliduje zdekodowaną mapę JSON pod kątem obecności kluczy, kolorów HEX i unikalności ID.
  static ModSchemaValidationReport validateRawMap(
    Map<String, dynamic> rawMap, {
    CareerSave? activeSave,
  }) {
    final List<ModSchemaValidationIssue> issues = [];

    for (final key in requiredTopLevelKeys) {
      if (!rawMap.containsKey(key) || rawMap[key] == null) {
        issues.add(
          ModSchemaValidationIssue(
            severity: ModSchemaIssueSeverity.error,
            section: 'root',
            field: key,
            message: 'Brak wymaganego klucza głównego "$key".',
          ),
        );
      }
    }

    final metadata = rawMap['metadata'];
    if (metadata != null && metadata is! Map<String, dynamic>) {
      issues.add(
        const ModSchemaValidationIssue(
          severity: ModSchemaIssueSeverity.error,
          section: 'metadata',
          field: 'metadata',
          message: 'Pole "metadata" musi być obiektem JSON.',
        ),
      );
    } else if (metadata is Map<String, dynamic>) {
      for (final metaKey in const ['id', 'name', 'version', 'author']) {
        final value = metadata[metaKey];
        if (value is! String || value.trim().isEmpty) {
          issues.add(
            ModSchemaValidationIssue(
              severity: ModSchemaIssueSeverity.error,
              section: 'metadata',
              field: metaKey,
              message: 'Brak lub puste wymagane pole metadanych "$metaKey".',
            ),
          );
        }
      }
    }

    final teamsRaw = _extractSectionList(rawMap, 'teams', issues);
    final ridersRaw = _extractSectionList(rawMap, 'riders', issues);
    final racesRaw = _extractSectionList(rawMap, 'races', issues);
    final brandsRaw = _extractSectionList(rawMap, 'brands', issues);

    final Set<String> knownTeamIds = activeSave != null
        ? activeSave.teams.map((t) => t.id).toSet()
        : const <String>{};
    final Set<String> knownRiderIds = activeSave != null
        ? activeSave.riders.map((r) => r.id).toSet()
        : const <String>{};
    final Set<String> knownRaceIds = activeSave != null
        ? activeSave.calendar.races.map((r) => r.id).toSet()
        : const <String>{};
    final Set<String> knownBrandIds = activeSave != null
        ? {
            ...FictionalBrandsCatalog.allBrands.map((b) => b.id),
            ...activeSave.teams.map((t) => t.bikeDeal.manufacturerId),
          }
        : FictionalBrandsCatalog.allBrands.map((b) => b.id).toSet();

    final teamsMatched = _validateSectionEntries(
      section: 'teams',
      entries: teamsRaw,
      knownIds: knownTeamIds,
      matchKnownIds: activeSave != null,
      issues: issues,
    );
    final ridersMatched = _validateSectionEntries(
      section: 'riders',
      entries: ridersRaw,
      knownIds: knownRiderIds,
      matchKnownIds: activeSave != null,
      issues: issues,
    );
    final racesMatched = _validateSectionEntries(
      section: 'races',
      entries: racesRaw,
      knownIds: knownRaceIds,
      matchKnownIds: activeSave != null,
      issues: issues,
    );
    final brandsMatched = _validateSectionEntries(
      section: 'brands',
      entries: brandsRaw,
      knownIds: knownBrandIds,
      matchKnownIds: true,
      issues: issues,
    );

    final bool hasErrors = issues.any((i) => i.severity == ModSchemaIssueSeverity.error);
    final String summary = hasErrors
        ? 'Walidacja nieudana (${issues.where((i) => i.severity == ModSchemaIssueSeverity.error).length} błędów). '
            'Wykryto: $ridersMatched kolarzy, $teamsMatched drużyn, $brandsMatched rowerów/marek, $racesMatched wyścigów.'
        : 'Schemat poprawny. Gotowe do podmiany: $ridersMatched kolarzy, $teamsMatched drużyn, '
            '$brandsMatched marek rowerów i $racesMatched wyścigów.';

    return ModSchemaValidationReport(
      isValid: !hasErrors,
      issues: List<ModSchemaValidationIssue>.unmodifiable(issues),
      totalTeamsInPatch: teamsRaw.length,
      totalRidersInPatch: ridersRaw.length,
      totalRacesInPatch: racesRaw.length,
      totalBrandsInPatch: brandsRaw.length,
      teamsReplacedCount: teamsMatched,
      ridersReplacedCount: ridersMatched,
      racesReplacedCount: racesMatched,
      brandsReplacedCount: brandsMatched,
      summary: summary,
    );
  }

  /// Waliduje gotowy obiekt [CommunityRealismPatchStructure].
  static ModSchemaValidationReport validateStructure(
    CommunityRealismPatchStructure patch, {
    CareerSave? activeSave,
  }) {
    return validateRawMap(patch.toJson(), activeSave: activeSave);
  }

  static List<dynamic> _extractSectionList(
    Map<String, dynamic> rawMap,
    String section,
    List<ModSchemaValidationIssue> issues,
  ) {
    final value = rawMap[section];
    if (value == null) return const [];
    if (value is! List<dynamic>) {
      issues.add(
        ModSchemaValidationIssue(
          severity: ModSchemaIssueSeverity.error,
          section: section,
          field: section,
          message: 'Sekcja "$section" musi być tablicą (List).',
        ),
      );
      return const [];
    }
    return value;
  }

  static int _validateSectionEntries({
    required String section,
    required List<dynamic> entries,
    required Set<String> knownIds,
    required bool matchKnownIds,
    required List<ModSchemaValidationIssue> issues,
  }) {
    final Set<String> seenIds = <String>{};
    int matchedCount = 0;

    for (int i = 0; i < entries.length; i++) {
      final rawEntry = entries[i];
      if (rawEntry is! Map<String, dynamic>) {
        issues.add(
          ModSchemaValidationIssue(
            severity: ModSchemaIssueSeverity.error,
            section: section,
            entryId: 'index_$i',
            field: 'entry',
            message: 'Wpis #$i w sekcji "$section" musi być obiektem JSON.',
          ),
        );
        continue;
      }

      final String entryId = (rawEntry['originalId'] as String? ?? '').trim();
      final String issueTarget = entryId.isNotEmpty ? entryId : 'index_$i';

      for (final reqKey in requiredEntryKeys) {
        if (!rawEntry.containsKey(reqKey) || rawEntry[reqKey] == null) {
          issues.add(
            ModSchemaValidationIssue(
              severity: ModSchemaIssueSeverity.error,
              section: section,
              entryId: issueTarget,
              field: reqKey,
              message: 'Brak wymaganego klucza "$reqKey" w sekcji "$section" ($issueTarget).',
            ),
          );
        }
      }

      if (entryId.isEmpty) {
        issues.add(
          ModSchemaValidationIssue(
            severity: ModSchemaIssueSeverity.error,
            section: section,
            entryId: issueTarget,
            field: 'originalId',
            message: 'Pole "originalId" nie może być puste w sekcji "$section" (indeks $i).',
          ),
        );
      } else if (!seenIds.add(entryId)) {
        issues.add(
          ModSchemaValidationIssue(
            severity: ModSchemaIssueSeverity.error,
            section: section,
            entryId: entryId,
            field: 'originalId',
            message: 'Zduplikowane ID "$entryId" w sekcji "$section".',
          ),
        );
      }

      final customName = rawEntry['customName'];
      if (customName is! String || customName.trim().isEmpty) {
        issues.add(
          ModSchemaValidationIssue(
            severity: ModSchemaIssueSeverity.error,
            section: section,
            entryId: issueTarget,
            field: 'customName',
            message: 'Pole "customName" musi być niepustym tekstem ($issueTarget).',
          ),
        );
      }

      final customShortName = rawEntry['customShortName'];
      if (customShortName is! String || customShortName.trim().isEmpty) {
        issues.add(
          ModSchemaValidationIssue(
            severity: ModSchemaIssueSeverity.error,
            section: section,
            entryId: issueTarget,
            field: 'customShortName',
            message: 'Pole "customShortName" musi być niepustym tekstem ($issueTarget).',
          ),
        );
      }

      final countryIso = rawEntry['customCountryIso'];
      if (countryIso is! String || !_countryIsoRegex.hasMatch(countryIso.trim().toUpperCase())) {
        issues.add(
          ModSchemaValidationIssue(
            severity: ModSchemaIssueSeverity.error,
            section: section,
            entryId: issueTarget,
            field: 'customCountryIso',
            message: 'Nieprawidłowy 3-literowy kod kraju ISO "$countryIso" ($issueTarget).',
          ),
        );
      }

      final primaryHex = rawEntry['primaryHex'];
      if (primaryHex is! String || !isValidHexColor(primaryHex)) {
        issues.add(
          ModSchemaValidationIssue(
            severity: ModSchemaIssueSeverity.error,
            section: section,
            entryId: issueTarget,
            field: 'primaryHex',
            message: 'Niepoprawny kolor HEX primaryHex "$primaryHex" ($issueTarget).',
          ),
        );
      }

      final secondaryHex = rawEntry['secondaryHex'];
      if (secondaryHex is! String || !isValidHexColor(secondaryHex)) {
        issues.add(
          ModSchemaValidationIssue(
            severity: ModSchemaIssueSeverity.error,
            section: section,
            entryId: issueTarget,
            field: 'secondaryHex',
            message: 'Niepoprawny kolor HEX secondaryHex "$secondaryHex" ($issueTarget).',
          ),
        );
      }

      final accentHex = rawEntry['accentHex'];
      if (accentHex != null && (accentHex is! String || !isValidHexColor(accentHex))) {
        issues.add(
          ModSchemaValidationIssue(
            severity: ModSchemaIssueSeverity.error,
            section: section,
            entryId: issueTarget,
            field: 'accentHex',
            message: 'Niepoprawny kolor HEX accentHex "$accentHex" ($issueTarget).',
          ),
        );
      }

      final patternIdx = rawEntry['jerseyPatternIndex'];
      if (patternIdx is! int || patternIdx < 0 || patternIdx > 15) {
        issues.add(
          ModSchemaValidationIssue(
            severity: ModSchemaIssueSeverity.error,
            section: section,
            entryId: issueTarget,
            field: 'jerseyPatternIndex',
            message: 'Pole "jerseyPatternIndex" musi być liczbą całkowitą 0–15 ($issueTarget).',
          ),
        );
      }

      if (entryId.isNotEmpty) {
        if (!matchKnownIds || knownIds.contains(entryId)) {
          matchedCount++;
        } else {
          issues.add(
            ModSchemaValidationIssue(
              severity: ModSchemaIssueSeverity.warning,
              section: section,
              entryId: entryId,
              field: 'originalId',
              message: 'ID "$entryId" z sekcji "$section" nie występuje w bieżącej bazie gry.',
            ),
          );
        }
      }
    }

    return matchedCount;
  }
}

/// Raport wynikowy operacji [PresetRealNamesTemplateGenerator.applyLivePatchToActiveCareer].
class LivePatchApplyResult {
  final CareerSave updatedSave;
  final ModSchemaValidationReport validationReport;
  final int ridersReplaced;
  final int teamsReplaced;
  final int racesReplaced;
  final int brandsReplaced;
  final int classificationEntriesUpdated;
  final int historyEntriesUpdated;
  final int contractOffersUpdated;
  final String summary;
  final List<String> logMessages;

  const LivePatchApplyResult({
    required this.updatedSave,
    required this.validationReport,
    required this.ridersReplaced,
    required this.teamsReplaced,
    required this.racesReplaced,
    required this.brandsReplaced,
    required this.classificationEntriesUpdated,
    required this.historyEntriesUpdated,
    required this.contractOffersUpdated,
    required this.summary,
    required this.logMessages,
  });
}

/// Serwis generujący kompletny szablon paczki modów `pro_peloton_real_names_pack_template.json`
/// oraz wbudowany pakiet `Community Realism Patch Structure` i bezpieczny live-patcher kariery.
class PresetRealNamesTemplateGenerator {
  PresetRealNamesTemplateGenerator._();

  static const String templateFileName = 'pro_peloton_real_names_pack_template.json';
  static const String communityPatchStructureName = 'Community Realism Patch Structure';
  static const String schemaVersion = '1.0.0';

  /// Eksportuje wszystkie ID drużyn, kolarzy, wyścigów i marek sprzętu z aktywnej kariery.
  static CommunityRealismPatchStructure buildTemplateFromCareerSave(
    CareerSave save, {
    String packName = 'Pro Peloton Manager - Real Names Pack Template',
    String author = 'Pro Peloton Community',
  }) {
    return _assembleStructure(
      teams: save.teams,
      riders: save.riders,
      races: save.calendar.races,
      packName: packName,
      author: author,
      description:
          'Kompletny szablon mapowania ID drużyn, kolarzy, wyścigów i marek sprzętu z aktywnego zapisu kariery.',
      applyBuiltInRealismDefaults: false,
    );
  }

  /// Eksportuje wszystkie bazowe ID drużyn, kolarzy, wyścigów i marek sprzętu ze świata gry.
  static CommunityRealismPatchStructure buildDefaultWorldTemplate({
    int seasonYear = 2026,
    int seed = 42,
    String packName = 'Pro Peloton Manager - Real Names Pack Template',
    String author = 'Pro Peloton Community',
  }) {
    final world = WorldTeamsGenerator.generateWorldTourSystem(seed: seed);
    final races = UciCalendarGenerator.generateFullSeasonCalendar(
      seasonYear: seasonYear,
      participatingTeamIds: world.teams.map((t) => t.id).toList(),
    );

    return _assembleStructure(
      teams: world.teams,
      riders: world.allRiders,
      races: races,
      packName: packName,
      author: author,
      description:
          'Kompletny szablon eksportujący wszystkie ID drużyn, kolarzy, wyścigów i marek sprzętu.',
      applyBuiltInRealismDefaults: false,
    );
  }

  /// Zwraca wbudowany pakiet `Community Realism Patch Structure` z mapowaniem dla głównych ekip,
  /// kolarzy, wyścigów i marek sprzętu (kompatybilny z generatorem szablonów i live-patchem).
  static CommunityRealismPatchStructure buildCommunityRealismPatchStructure({
    CareerSave? activeSave,
    int seasonYear = 2026,
    int seed = 42,
  }) {
    final List<CyclingTeam> teams;
    final List<Rider> riders;
    final List<TourRace> races;

    if (activeSave != null) {
      teams = activeSave.teams;
      riders = activeSave.riders;
      races = activeSave.calendar.races;
    } else {
      final world = WorldTeamsGenerator.generateWorldTourSystem(seed: seed);
      teams = world.teams;
      riders = world.allRiders;
      races = UciCalendarGenerator.generateFullSeasonCalendar(
        seasonYear: seasonYear,
        participatingTeamIds: world.teams.map((t) => t.id).toList(),
      );
    }

    return _assembleStructure(
      teams: teams,
      riders: riders,
      races: races,
      packName: 'Community Realism Patch (Official 2026 Structure)',
      author: 'Pro Peloton Community',
      description:
          'Wbudowany pakiet Community Realism Patch Structure podmieniający fikcyjne drużyny, kolarzy, wyścigi i marki rowerowe.',
      applyBuiltInRealismDefaults: true,
    );
  }

  /// Generuje sformatowany JSON szablonu gotowy do zapisu lub edycji w edytorze.
  static String generateTemplateJson({
    CareerSave? activeSave,
    bool includeBuiltInRealismDefaults = false,
    int seasonYear = 2026,
  }) {
    final structure = includeBuiltInRealismDefaults
        ? buildCommunityRealismPatchStructure(
            activeSave: activeSave,
            seasonYear: seasonYear,
          )
        : (activeSave != null
            ? buildTemplateFromCareerSave(activeSave)
            : buildDefaultWorldTemplate(seasonYear: seasonYear));

    return structure.toPrettyJson();
  }

  /// Jednym kliknięciem zapisuje na dysku kompletny plik `pro_peloton_real_names_pack_template.json`.
  static Future<File> generateTemplateFileOnDisk({
    CareerSave? activeSave,
    Directory? targetDirectory,
    bool includeBuiltInRealismDefaults = false,
    int seasonYear = 2026,
  }) async {
    final dir = targetDirectory ?? await CustomModImporterService.getModsDirectory();
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final file = File('${dir.path}${Platform.pathSeparator}$templateFileName');
    final jsonContent = generateTemplateJson(
      activeSave: activeSave,
      includeBuiltInRealismDefaults: includeBuiltInRealismDefaults,
      seasonYear: seasonYear,
    );
    return file.writeAsString(jsonContent, flush: true);
  }

  /// Podmienia nazwy drużyn, kolarzy, wyścigów i sprzętu w trakcie trwającej już kariery
  /// bez psucia postępów kalendarza, kontraktów, finansów i wyników w klasyfikacjach.
  static LivePatchApplyResult applyLivePatchToActiveCareer({
    required CareerSave activeSave,
    required CommunityRealismPatchStructure patch,
    bool strictValidation = true,
  }) {
    final report = ModSchemaValidator.validateStructure(patch, activeSave: activeSave);
    if (strictValidation && !report.isValid) {
      final firstMsg = report.errors.isNotEmpty
          ? report.errors.first.message
          : 'Niepoprawny schemat paczki modyfikacji.';
      throw FormatException('Walidacja paczki modyfikacji nie powiodła się: $firstMsg');
    }

    final List<String> logs = [];
    int teamsReplaced = 0;
    int ridersReplaced = 0;
    int racesReplaced = 0;
    int brandsReplaced = 0;
    int classificationEntriesUpdated = 0;
    int historyEntriesUpdated = 0;
    int contractOffersUpdated = 0;

    final Map<String, TeamPatchEntry> teamMap = {
      for (final t in patch.teams) t.originalId: t,
    };
    final Map<String, RiderPatchEntry> riderMap = {
      for (final r in patch.riders) r.originalId: r,
    };
    final Map<String, RacePatchEntry> raceMap = {
      for (final rc in patch.races) rc.originalId: rc,
    };
    final Map<String, BrandPatchEntry> brandMap = {
      for (final b in patch.brands) b.originalId: b,
    };

    // 1. Podmiana drużyn i marek rowerowych z zachowaniem budżetu, kontraktów, sztabu i punktów UCI
    final Map<String, String> updatedTeamNamesById = {};
    final List<CyclingTeam> updatedTeams = activeSave.teams.map((team) {
      CyclingTeam currentTeam = team;
      final teamPatch = teamMap[team.id];
      if (teamPatch != null) {
        teamsReplaced++;
        List<SponsorContract> updatedSponsors = team.sponsors;
        if (teamPatch.sponsorCompanyName != null &&
            teamPatch.sponsorCompanyName!.isNotEmpty &&
            updatedSponsors.isNotEmpty) {
          updatedSponsors = updatedSponsors.map((s) {
            if (s.sponsorTier == SponsorTier.titlePrimary) {
              return s.copyWith(companyName: teamPatch.sponsorCompanyName!);
            }
            return s;
          }).toList();
        }

        currentTeam = currentTeam.copyWith(
          name: teamPatch.customName,
          countryIso: teamPatch.customCountryIso,
          primaryJerseyColorHex: teamPatch.primaryHex,
          secondaryJerseyColorHex: teamPatch.secondaryHex,
          accentJerseyColorHex: teamPatch.accentHex ?? currentTeam.accentJerseyColorHex,
          sponsors: updatedSponsors,
        );
        logs.add('Drużyna [${team.id}]: "${team.name}" -> "${currentTeam.name}"');
      }

      final brandPatch = brandMap[currentTeam.bikeDeal.manufacturerId];
      if (brandPatch != null) {
        brandsReplaced++;
        final updatedDeal = currentTeam.bikeDeal.copyWith(
          manufacturerName: brandPatch.customName,
        );
        final updatedBikes = currentTeam.inventoryBikes.map((bike) {
          final updatedFrame = bike.frame.copyWith(
            name: '${brandPatch.customName} ${bike.frame.category.name.toUpperCase()}',
          );
          return bike.copyWith(
            name: '${brandPatch.customName} Factory Pro',
            frame: updatedFrame,
          );
        }).toList();

        currentTeam = currentTeam.copyWith(
          bikeDeal: updatedDeal,
          inventoryBikes: updatedBikes,
        );
        logs.add(
          'Sprzęt (${currentTeam.name}): "${team.bikeDeal.manufacturerName}" -> "${brandPatch.customName}"',
        );
      }

      updatedTeamNamesById[currentTeam.id] = currentTeam.name;
      return currentTeam;
    }).toList();

    // 2. Podmiana kolarzy z zachowaniem kontraktów, zdrowia, fizjologii, punktów UCI i ID
    final Map<String, String> updatedRiderNamesById = {};
    final List<Rider> updatedRiders = activeSave.riders.map((rider) {
      final riderPatch = riderMap[rider.id];
      if (riderPatch != null) {
        ridersReplaced++;
        final nameParts = splitFullName(riderPatch.customName);
        final patchedRider = rider.copyWith(
          firstName: nameParts.$1,
          lastName: nameParts.$2,
          nationalityIso: riderPatch.customCountryIso,
        );
        updatedRiderNamesById[patchedRider.id] = patchedRider.fullName;
        logs.add('Kolarz [${rider.id}]: "${rider.fullName}" -> "${patchedRider.fullName}"');
        return patchedRider;
      }
      updatedRiderNamesById[rider.id] = rider.fullName;
      return rider;
    }).toList();

    // 3. Podmiana wyścigów oraz odświeżenie nazw w aktywnych klasyfikacjach bez utraty czasów/punktów/miejsc
    final Map<String, String> updatedRaceNamesById = {};
    final List<TourRace> updatedRaces = activeSave.calendar.races.map((race) {
      final racePatch = raceMap[race.id];
      final String nextRaceName = racePatch != null ? racePatch.customName : race.name;
      final String nextCountryIso = racePatch != null ? racePatch.customCountryIso : race.countryIso;

      if (racePatch != null) {
        racesReplaced++;
        logs.add('Wyścig [${race.id}]: "${race.name}" -> "$nextRaceName"');
      }
      updatedRaceNamesById[race.id] = nextRaceName;

      final updatedClassifications = _refreshRaceClassificationsNames(
        classifications: race.classifications,
        riderNamesById: updatedRiderNamesById,
        teamNamesById: updatedTeamNamesById,
        onEntryUpdated: () => classificationEntriesUpdated++,
      );

      return race.copyWith(
        name: nextRaceName,
        countryIso: nextCountryIso,
        classifications: updatedClassifications,
      );
    }).toList();

    // 4. Odświeżenie historii ukończonych wyścigów (zachowując ID zwycięzców, czasy i daty)
    final Map<String, RaceHistoryEntry> updatedHistory = {};
    activeSave.calendar.raceHistory.forEach((key, entry) {
      final newRaceName = updatedRaceNamesById[entry.raceId] ?? entry.raceName;
      final newWinnerRiderName = updatedRiderNamesById[entry.winnerRiderId] ?? entry.winnerRiderName;
      final newWinnerTeamName = updatedTeamNamesById[entry.winnerTeamId] ?? entry.winnerTeamName;

      if (newRaceName != entry.raceName ||
          newWinnerRiderName != entry.winnerRiderName ||
          newWinnerTeamName != entry.winnerTeamName) {
        historyEntriesUpdated++;
      }

      updatedHistory[key] = entry.copyWith(
        raceName: newRaceName,
        winnerRiderName: newWinnerRiderName,
        winnerTeamName: newWinnerTeamName,
      );
    });

    // 5. Odświeżenie nazw w trwających ofertach transferowych (zachowując pensje, długości i statusy)
    final List<CareerContractOffer> updatedOffers = activeSave.contractOffers.map((offer) {
      final newRiderName = updatedRiderNamesById[offer.riderId] ?? offer.riderName;
      final newTeamName = updatedTeamNamesById[offer.offeringTeamId] ?? offer.offeringTeamName;
      if (newRiderName != offer.riderName || newTeamName != offer.offeringTeamName) {
        contractOffersUpdated++;
        return offer.copyWith(
          riderName: newRiderName,
          offeringTeamName: newTeamName,
        );
      }
      return offer;
    }).toList();

    final updatedCalendar = activeSave.calendar.copyWith(
      races: updatedRaces,
      activeRaceId: activeSave.calendar.activeRaceId,
      raceHistory: updatedHistory,
    );

    final updatedSave = activeSave.copyWith(
      teams: updatedTeams,
      riders: updatedRiders,
      calendar: updatedCalendar,
      contractOffers: updatedOffers,
      lastSavedAt: DateTime.now(),
    );

    final summary =
        'Live Patch zastosowany bez naruszenia postępów kariery: '
        '$ridersReplaced kolarzy, $teamsReplaced drużyn, $racesReplaced wyścigów, '
        '$brandsReplaced marek sprzętu (zaktualizowano $classificationEntriesUpdated wpisów klasyfikacji).';

    return LivePatchApplyResult(
      updatedSave: updatedSave,
      validationReport: report,
      ridersReplaced: ridersReplaced,
      teamsReplaced: teamsReplaced,
      racesReplaced: racesReplaced,
      brandsReplaced: brandsReplaced,
      classificationEntriesUpdated: classificationEntriesUpdated,
      historyEntriesUpdated: historyEntriesUpdated,
      contractOffersUpdated: contractOffersUpdated,
      summary: summary,
      logMessages: List<String>.unmodifiable(logs),
    );
  }

  /// Wersja convenience przyjmująca surowy ciąg JSON dla aktywnej kariery.
  static LivePatchApplyResult applyLivePatchJsonToActiveCareer({
    required CareerSave activeSave,
    required String jsonContent,
    bool strictValidation = true,
  }) {
    final report = ModSchemaValidator.validateJson(jsonContent, activeSave: activeSave);
    if (strictValidation && !report.isValid) {
      final firstMsg = report.errors.isNotEmpty
          ? report.errors.first.message
          : 'Niepoprawny plik JSON modyfikacji.';
      throw FormatException('Walidacja JSON nie powiodła się: $firstMsg');
    }

    final decoded = jsonDecode(jsonContent) as Map<String, dynamic>;
    final patch = CommunityRealismPatchStructure.fromJson(decoded);
    return applyLivePatchToActiveCareer(
      activeSave: activeSave,
      patch: patch,
      strictValidation: strictValidation,
    );
  }

  /// Bezpiecznie dzieli pełne imię i nazwisko na `(firstName, lastName)`.
  static (String, String) splitFullName(String fullName) {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return ('Unknown', 'Rider');
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return (parts.first, '');
    return (parts.first, parts.sublist(1).join(' '));
  }

  static RaceClassifications _refreshRaceClassificationsNames({
    required RaceClassifications classifications,
    required Map<String, String> riderNamesById,
    required Map<String, String> teamNamesById,
    required void Function() onEntryUpdated,
  }) {
    List<RiderClassificationEntry> mapRiders(List<RiderClassificationEntry> list) {
      return list.map((e) {
        final nextName = riderNamesById[e.riderId];
        if (nextName != null && nextName != e.riderName) {
          onEntryUpdated();
          return e.copyWith(riderName: nextName);
        }
        return e;
      }).toList();
    }

    final updatedTeamClass = classifications.teamClassification.map((e) {
      final nextName = teamNamesById[e.teamId];
      if (nextName != null && nextName != e.teamName) {
        onEntryUpdated();
        return e.copyWith(teamName: nextName);
      }
      return e;
    }).toList();

    return classifications.copyWith(
      generalClassification: mapRiders(classifications.generalClassification),
      pointsClassification: mapRiders(classifications.pointsClassification),
      mountainsClassification: mapRiders(classifications.mountainsClassification),
      youthClassification: mapRiders(classifications.youthClassification),
      teamClassification: updatedTeamClass,
    );
  }

  static CommunityRealismPatchStructure _assembleStructure({
    required List<CyclingTeam> teams,
    required List<Rider> riders,
    required List<TourRace> races,
    required String packName,
    required String author,
    required String description,
    required bool applyBuiltInRealismDefaults,
  }) {
    final Map<String, CyclingTeam> teamsById = {for (final t in teams) t.id: t};

    final List<TeamPatchEntry> teamEntries = [];
    for (int i = 0; i < teams.length; i++) {
      final team = teams[i];
      final preset = applyBuiltInRealismDefaults ? _realTeamPresets[team.id] : null;
      final customName = preset?.name ?? team.name;
      teamEntries.add(
        TeamPatchEntry(
          originalId: team.id,
          originalName: team.name,
          division: team.division.name,
          customName: customName,
          customShortName: preset?.shortName ?? _deriveShortCode(customName),
          customCountryIso: preset?.countryIso ?? team.countryIso,
          primaryHex: preset?.primaryHex ?? _normalizeHex(team.primaryJerseyColorHex),
          secondaryHex: preset?.secondaryHex ?? _normalizeHex(team.secondaryJerseyColorHex),
          accentHex: preset?.accentHex ?? _normalizeHex(team.accentJerseyColorHex),
          jerseyPatternIndex: preset?.jerseyPatternIndex ?? (i % 8),
          sponsorCompanyName: preset?.sponsorCompanyName,
        ),
      );
    }

    final List<RiderPatchEntry> riderEntries = [];
    for (int i = 0; i < riders.length; i++) {
      final rider = riders[i];
      final team = teamsById[rider.contract.teamId];
      final preset = applyBuiltInRealismDefaults ? _realRiderPresets[rider.id] : null;
      final customName = preset?.fullName ?? rider.fullName;
      riderEntries.add(
        RiderPatchEntry(
          originalId: rider.id,
          originalName: rider.fullName,
          teamId: rider.contract.teamId,
          role: rider.contract.role.name,
          specialization: rider.specialization.name,
          customName: customName,
          customShortName: _deriveRiderShortName(customName),
          customCountryIso: preset?.countryIso ?? rider.nationalityIso,
          primaryHex: _normalizeHex(team?.primaryJerseyColorHex ?? '#181B22'),
          secondaryHex: _normalizeHex(team?.secondaryJerseyColorHex ?? '#F3F4F6'),
          jerseyPatternIndex: i % 8,
        ),
      );
    }

    final List<RacePatchEntry> raceEntries = [];
    for (int i = 0; i < races.length; i++) {
      final race = races[i];
      final preset = applyBuiltInRealismDefaults ? _matchRealRacePreset(race) : null;
      final customName = preset?.name ?? race.name;
      raceEntries.add(
        RacePatchEntry(
          originalId: race.id,
          originalName: race.name,
          uciCategory: race.uciCategory.name,
          customName: customName,
          customShortName: preset?.shortName ?? _deriveShortCode(customName),
          customCountryIso: preset?.countryIso ?? race.countryIso,
          primaryHex: preset?.primaryHex ?? '#D4AF37',
          secondaryHex: preset?.secondaryHex ?? '#181B22',
          jerseyPatternIndex: i % 6,
        ),
      );
    }

    final List<BrandPatchEntry> brandEntries = [];
    final allBrands = FictionalBrandsCatalog.allBrands;
    for (int i = 0; i < allBrands.length; i++) {
      final brand = allBrands[i];
      final preset = applyBuiltInRealismDefaults ? _realBrandPresets[brand.id] : null;
      final customName = preset?.name ?? brand.name;
      brandEntries.add(
        BrandPatchEntry(
          originalId: brand.id,
          originalName: brand.name,
          customName: customName,
          customShortName: preset?.shortName ?? _deriveShortCode(customName),
          customCountryIso: preset?.countryIso ?? brand.countryIso,
          primaryHex: preset?.primaryHex ?? _normalizeHex(brand.primaryColorHex),
          secondaryHex: '#F3F4F6',
          jerseyPatternIndex: i % 4,
        ),
      );
    }

    return CommunityRealismPatchStructure(
      schemaVersion: schemaVersion,
      structureType: communityPatchStructureName,
      metadata: CustomModMetadata(
        id: applyBuiltInRealismDefaults
            ? 'community_realism_patch_2026'
            : 'real_names_template_2026',
        name: packName,
        version: schemaVersion,
        author: author,
        description: description,
        createdDate: DateTime.now(),
      ),
      teams: List<TeamPatchEntry>.unmodifiable(teamEntries),
      riders: List<RiderPatchEntry>.unmodifiable(riderEntries),
      races: List<RacePatchEntry>.unmodifiable(raceEntries),
      brands: List<BrandPatchEntry>.unmodifiable(brandEntries),
    );
  }

  static String _normalizeHex(String hex) {
    final trimmed = hex.trim();
    if (ModSchemaValidator.isValidHexColor(trimmed)) {
      return trimmed.toUpperCase();
    }
    return '#181B22';
  }

  static String _deriveShortCode(String name) {
    final clean = name.replaceAll(RegExp(r'[^A-Za-z0-9 ]'), '').trim();
    if (clean.isEmpty) return 'PPM';
    final words = clean.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length >= 3) {
      return '${words[0][0]}${words[1][0]}${words[2][0]}'.toUpperCase();
    }
    if (words.length == 2 && words[0].length >= 2) {
      return '${words[0].substring(0, 2)}${words[1][0]}'.toUpperCase();
    }
    final single = words.first;
    return single.length >= 3 ? single.substring(0, 3).toUpperCase() : single.toUpperCase().padRight(3, 'X');
  }

  static String _deriveRiderShortName(String fullName) {
    final parts = splitFullName(fullName);
    final firstInitial = parts.$1.isNotEmpty ? parts.$1[0].toUpperCase() : 'R';
    final lastUpper = parts.$2.isNotEmpty ? parts.$2.toUpperCase() : parts.$1.toUpperCase();
    return '$firstInitial. $lastUpper';
  }

  static _RealRacePreset? _matchRealRacePreset(TourRace race) {
    final idLower = race.id.toLowerCase();
    final nameLower = race.name.toLowerCase();
    for (final entry in _realRacePresets.entries) {
      if (idLower.contains(entry.key) || nameLower.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  static const Map<String, _RealTeamPreset> _realTeamPresets = {
    'wt_emirates': _RealTeamPreset(
      name: 'UAE Team Emirates XRG',
      shortName: 'UAD',
      countryIso: 'ARE',
      primaryHex: '#FFFFFF',
      secondaryHex: '#0F1115',
      accentHex: '#EF4444',
      jerseyPatternIndex: 1,
      sponsorCompanyName: 'Emirates Airline',
    ),
    'wt_visma': _RealTeamPreset(
      name: 'Team Visma | Lease a Bike',
      shortName: 'TVL',
      countryIso: 'NLD',
      primaryHex: '#FACC15',
      secondaryHex: '#111827',
      accentHex: '#FFFFFF',
      jerseyPatternIndex: 2,
      sponsorCompanyName: 'Visma Software',
    ),
    'wt_ineos': _RealTeamPreset(
      name: 'INEOS Grenadiers',
      shortName: 'IGD',
      countryIso: 'GBR',
      primaryHex: '#EA580C',
      secondaryHex: '#0F172A',
      accentHex: '#FFFFFF',
      jerseyPatternIndex: 3,
      sponsorCompanyName: 'INEOS Group',
    ),
    'wt_soudal': _RealTeamPreset(
      name: 'Soudal Quick-Step',
      shortName: 'SOQ',
      countryIso: 'BEL',
      primaryHex: '#1D4ED8',
      secondaryHex: '#FFFFFF',
      accentHex: '#DC2626',
      jerseyPatternIndex: 4,
      sponsorCompanyName: 'Soudal',
    ),
    'wt_redbull': _RealTeamPreset(
      name: 'Red Bull - BORA - hansgrohe',
      shortName: 'RBH',
      countryIso: 'DEU',
      primaryHex: '#1E293B',
      secondaryHex: '#E11D48',
      accentHex: '#FACC15',
      jerseyPatternIndex: 5,
      sponsorCompanyName: 'Red Bull GmbH',
    ),
    'wt_alpecin': _RealTeamPreset(
      name: 'Alpecin-Deceuninck',
      shortName: 'ADC',
      countryIso: 'BEL',
      primaryHex: '#1E3A8A',
      secondaryHex: '#EF4444',
      accentHex: '#FFFFFF',
      jerseyPatternIndex: 1,
      sponsorCompanyName: 'Alpecin',
    ),
    'wt_lidl': _RealTeamPreset(
      name: 'Lidl-Trek',
      shortName: 'LTK',
      countryIso: 'USA',
      primaryHex: '#1D4ED8',
      secondaryHex: '#EF4444',
      accentHex: '#FACC15',
      jerseyPatternIndex: 6,
      sponsorCompanyName: 'Lidl Stiftung',
    ),
  };

  static const Map<String, _RealRiderPreset> _realRiderPresets = {
    'wt_emirates_r0': _RealRiderPreset('Tadej Pogačar', 'SVN'),
    'wt_visma_r0': _RealRiderPreset('Jonas Vingegaard', 'DNK'),
    'wt_soudal_r0': _RealRiderPreset('Remco Evenepoel', 'BEL'),
    'wt_alpecin_r0': _RealRiderPreset('Mathieu van der Poel', 'NLD'),
    'wt_redbull_r0': _RealRiderPreset('Primož Roglič', 'SVN'),
    'wt_lidl_r0': _RealRiderPreset('Mads Pedersen', 'DNK'),
    'wt_ineos_r0': _RealRiderPreset('Carlos Rodríguez', 'ESP'),
  };

  static const Map<String, _RealRacePreset> _realRacePresets = {
    'boucle': _RealRacePreset('Tour de France', 'TDF', 'FRA', '#FACC15', '#181B22'),
    'corsa_rosa': _RealRacePreset('Giro d\'Italia', 'GIR', 'ITA', '#EC4899', '#181B22'),
    'vuelta': _RealRacePreset('La Vuelta a España', 'VUE', 'ESP', '#EF4444', '#181B22'),
    'primavera': _RealRacePreset('Milano-Sanremo', 'MSR', 'ITA', '#38BDF8', '#181B22'),
    'vlaanderen': _RealRacePreset('Ronde van Vlaanderen', 'RVV', 'BEL', '#FACC15', '#0F1115'),
    'roubaix': _RealRacePreset('Paris-Roubaix', 'PRX', 'FRA', '#9CA3AF', '#0F1115'),
    'liege': _RealRacePreset('Liège-Bastogne-Liège', 'LBL', 'BEL', '#DC2626', '#181B22'),
    'lombardia': _RealRacePreset('Il Lombardia', 'LOM', 'ITA', '#8E4A49', '#181B22'),
    'strade': _RealRacePreset('Strade Bianche', 'STB', 'ITA', '#F3F4F6', '#8E4A49'),
    'pologne': _RealRacePreset('Tour de Pologne', 'TDP', 'POL', '#EF4444', '#FFFFFF'),
  };

  static const Map<String, _RealBrandPreset> _realBrandPresets = {
    'brand_aurelia': _RealBrandPreset('Colnago', 'COL', 'ITA', '#111827'),
    'brand_nordvind': _RealBrandPreset('Cervélo', 'CRV', 'CAN', '#FACC15'),
    'brand_apex_aero': _RealBrandPreset('Specialized', 'SPC', 'USA', '#EF4444'),
    'brand_velo_corsa': _RealBrandPreset('Pinarello', 'PIN', 'ITA', '#1E3A8A'),
    'brand_kestrel': _RealBrandPreset('Canyon', 'CYN', 'DEU', '#EA580C'),
    'brand_boulder': _RealBrandPreset('Trek', 'TRK', 'USA', '#DC2626'),
    'brand_celeste': _RealBrandPreset('Bianchi', 'BNC', 'ITA', '#2DD4BF'),
    'brand_helvetia': _RealBrandPreset('BMC', 'BMC', 'CHE', '#B91C1C'),
    'brand_flemish': _RealBrandPreset('Ridley', 'RID', 'BEL', '#2563EB'),
    'brand_pyrenees': _RealBrandPreset('Orbea', 'ORB', 'ESP', '#059669'),
  };
}

class _RealTeamPreset {
  final String name;
  final String shortName;
  final String countryIso;
  final String primaryHex;
  final String secondaryHex;
  final String accentHex;
  final int jerseyPatternIndex;
  final String sponsorCompanyName;

  const _RealTeamPreset({
    required this.name,
    required this.shortName,
    required this.countryIso,
    required this.primaryHex,
    required this.secondaryHex,
    required this.accentHex,
    required this.jerseyPatternIndex,
    required this.sponsorCompanyName,
  });
}

class _RealRiderPreset {
  final String fullName;
  final String countryIso;

  const _RealRiderPreset(this.fullName, this.countryIso);
}

class _RealRacePreset {
  final String name;
  final String shortName;
  final String countryIso;
  final String primaryHex;
  final String secondaryHex;

  const _RealRacePreset(
    this.name,
    this.shortName,
    this.countryIso,
    this.primaryHex,
    this.secondaryHex,
  );
}

class _RealBrandPreset {
  final String name;
  final String shortName;
  final String countryIso;
  final String primaryHex;

  const _RealBrandPreset(
    this.name,
    this.shortName,
    this.countryIso,
    this.primaryHex,
  );
}
