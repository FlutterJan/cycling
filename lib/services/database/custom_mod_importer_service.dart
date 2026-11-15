import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../models/career/career_save.dart';
import '../../models/rider/rider.dart';
import '../../models/rider/rider_contract.dart';
import '../../models/team/cycling_team.dart';
import '../../models/team/sponsor_contract.dart';

/// Metadane modyfikacji świata gry (np. paczka z autentycznymi nazwiskami kolarzy i wyścigów).
class CustomModMetadata {
  final String id;
  final String name;
  final String version;
  final String author;
  final String description;
  final DateTime createdDate;
  final String? websiteUrl;

  const CustomModMetadata({
    required this.id,
    required this.name,
    required this.version,
    required this.author,
    required this.description,
    required this.createdDate,
    this.websiteUrl,
  });

  CustomModMetadata copyWith({
    String? id,
    String? name,
    String? version,
    String? author,
    String? description,
    DateTime? createdDate,
    String? websiteUrl,
  }) {
    return CustomModMetadata(
      id: id ?? this.id,
      name: name ?? this.name,
      version: version ?? this.version,
      author: author ?? this.author,
      description: description ?? this.description,
      createdDate: createdDate ?? this.createdDate,
      websiteUrl: websiteUrl ?? this.websiteUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'version': version,
      'author': author,
      'description': description,
      'createdDate': createdDate.toIso8601String(),
      if (websiteUrl != null) 'websiteUrl': websiteUrl,
    };
  }

  factory CustomModMetadata.fromJson(Map<String, dynamic> json) {
    return CustomModMetadata(
      id: json['id'] as String? ?? 'custom_mod_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? 'Community Real Name Pack',
      version: json['version'] as String? ?? '1.0.0',
      author: json['author'] as String? ?? 'Pro Peloton Community',
      description: json['description'] as String? ?? 'Zastępuje fikcyjne dane autentycznymi kolarzami i zespołami.',
      createdDate: json['createdDate'] != null
          ? DateTime.parse(json['createdDate'] as String)
          : DateTime.now(),
      websiteUrl: json['websiteUrl'] as String?,
    );
  }

  @override
  String toString() => 'CustomModMetadata($name v$version by $author)';
}

/// Wpis modyfikacji pojedynczego kolarza w bazie.
class RiderModEntry {
  final String? matchId;
  final String? matchOriginalFullName;
  final String? matchTeamId;
  final RiderRole? matchRole;
  final RiderSpecialization? matchSpecialization;
  final String firstName;
  final String lastName;
  final String nationalityIso;
  final int? birthYear;
  final int? targetOverallRating;

  const RiderModEntry({
    this.matchId,
    this.matchOriginalFullName,
    this.matchTeamId,
    this.matchRole,
    this.matchSpecialization,
    required this.firstName,
    required this.lastName,
    required this.nationalityIso,
    this.birthYear,
    this.targetOverallRating,
  });

  String get fullName => '$firstName $lastName';

  RiderModEntry copyWith({
    String? matchId,
    String? matchOriginalFullName,
    String? matchTeamId,
    RiderRole? matchRole,
    RiderSpecialization? matchSpecialization,
    String? firstName,
    String? lastName,
    String? nationalityIso,
    int? birthYear,
    int? targetOverallRating,
  }) {
    return RiderModEntry(
      matchId: matchId ?? this.matchId,
      matchOriginalFullName: matchOriginalFullName ?? this.matchOriginalFullName,
      matchTeamId: matchTeamId ?? this.matchTeamId,
      matchRole: matchRole ?? this.matchRole,
      matchSpecialization: matchSpecialization ?? this.matchSpecialization,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      nationalityIso: nationalityIso ?? this.nationalityIso,
      birthYear: birthYear ?? this.birthYear,
      targetOverallRating: targetOverallRating ?? this.targetOverallRating,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (matchId != null) 'matchId': matchId,
      if (matchOriginalFullName != null) 'matchOriginalFullName': matchOriginalFullName,
      if (matchTeamId != null) 'matchTeamId': matchTeamId,
      if (matchRole != null) 'matchRole': matchRole!.name,
      if (matchSpecialization != null) 'matchSpecialization': matchSpecialization!.name,
      'firstName': firstName,
      'lastName': lastName,
      'nationalityIso': nationalityIso,
      if (birthYear != null) 'birthYear': birthYear,
      if (targetOverallRating != null) 'targetOverallRating': targetOverallRating,
    };
  }

  factory RiderModEntry.fromJson(Map<String, dynamic> json) {
    return RiderModEntry(
      matchId: json['matchId'] as String?,
      matchOriginalFullName: json['matchOriginalFullName'] as String?,
      matchTeamId: json['matchTeamId'] as String?,
      matchRole: json['matchRole'] != null
          ? RiderRole.fromJson(json['matchRole'] as String)
          : null,
      matchSpecialization: json['matchSpecialization'] != null
          ? RiderSpecialization.fromJson(json['matchSpecialization'] as String)
          : null,
      firstName: json['firstName'] as String? ?? 'Unknown',
      lastName: json['lastName'] as String? ?? 'Rider',
      nationalityIso: (json['nationalityIso'] as String? ?? 'FRA').toUpperCase(),
      birthYear: json['birthYear'] != null ? (json['birthYear'] as num).toInt() : null,
      targetOverallRating: json['targetOverallRating'] != null
          ? (json['targetOverallRating'] as num).toInt()
          : null,
    );
  }
}

/// Wpis modyfikacji pojedynczej drużyny (nazwa, barwy koszulek, oficjalny sponsor).
class TeamModEntry {
  final String? matchId;
  final String? matchOriginalName;
  final String name;
  final String countryIso;
  final String primaryJerseyColorHex;
  final String secondaryJerseyColorHex;
  final String accentJerseyColorHex;
  final String? sponsorCompanyName;
  final String? brandId;

  const TeamModEntry({
    this.matchId,
    this.matchOriginalName,
    required this.name,
    required this.countryIso,
    required this.primaryJerseyColorHex,
    required this.secondaryJerseyColorHex,
    required this.accentJerseyColorHex,
    this.sponsorCompanyName,
    this.brandId,
  });

  TeamModEntry copyWith({
    String? matchId,
    String? matchOriginalName,
    String? name,
    String? countryIso,
    String? primaryJerseyColorHex,
    String? secondaryJerseyColorHex,
    String? accentJerseyColorHex,
    String? sponsorCompanyName,
    String? brandId,
  }) {
    return TeamModEntry(
      matchId: matchId ?? this.matchId,
      matchOriginalName: matchOriginalName ?? this.matchOriginalName,
      name: name ?? this.name,
      countryIso: countryIso ?? this.countryIso,
      primaryJerseyColorHex: primaryJerseyColorHex ?? this.primaryJerseyColorHex,
      secondaryJerseyColorHex: secondaryJerseyColorHex ?? this.secondaryJerseyColorHex,
      accentJerseyColorHex: accentJerseyColorHex ?? this.accentJerseyColorHex,
      sponsorCompanyName: sponsorCompanyName ?? this.sponsorCompanyName,
      brandId: brandId ?? this.brandId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (matchId != null) 'matchId': matchId,
      if (matchOriginalName != null) 'matchOriginalName': matchOriginalName,
      'name': name,
      'countryIso': countryIso,
      'primaryJerseyColorHex': primaryJerseyColorHex,
      'secondaryJerseyColorHex': secondaryJerseyColorHex,
      'accentJerseyColorHex': accentJerseyColorHex,
      if (sponsorCompanyName != null) 'sponsorCompanyName': sponsorCompanyName,
      if (brandId != null) 'brandId': brandId,
    };
  }

  factory TeamModEntry.fromJson(Map<String, dynamic> json) {
    return TeamModEntry(
      matchId: json['matchId'] as String?,
      matchOriginalName: json['matchOriginalName'] as String?,
      name: json['name'] as String? ?? 'Official Team',
      countryIso: (json['countryIso'] as String? ?? 'FRA').toUpperCase(),
      primaryJerseyColorHex: json['primaryJerseyColorHex'] as String? ?? '#000000',
      secondaryJerseyColorHex: json['secondaryJerseyColorHex'] as String? ?? '#FFFFFF',
      accentJerseyColorHex: json['accentJerseyColorHex'] as String? ?? '#FF0000',
      sponsorCompanyName: json['sponsorCompanyName'] as String?,
      brandId: json['brandId'] as String?,
    );
  }
}

/// Wpis modyfikacji wyścigu w kalendarzu.
class RaceModEntry {
  final String? matchId;
  final String? matchKeyword;
  final String name;
  final String? countryIso;

  const RaceModEntry({
    this.matchId,
    this.matchKeyword,
    required this.name,
    this.countryIso,
  });

  RaceModEntry copyWith({
    String? matchId,
    String? matchKeyword,
    String? name,
    String? countryIso,
  }) {
    return RaceModEntry(
      matchId: matchId ?? this.matchId,
      matchKeyword: matchKeyword ?? this.matchKeyword,
      name: name ?? this.name,
      countryIso: countryIso ?? this.countryIso,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (matchId != null) 'matchId': matchId,
      if (matchKeyword != null) 'matchKeyword': matchKeyword,
      'name': name,
      if (countryIso != null) 'countryIso': countryIso,
    };
  }

  factory RaceModEntry.fromJson(Map<String, dynamic> json) {
    return RaceModEntry(
      matchId: json['matchId'] as String?,
      matchKeyword: json['matchKeyword'] as String?,
      name: json['name'] as String? ?? 'Official Tour Race',
      countryIso: json['countryIso'] != null
          ? (json['countryIso'] as String).toUpperCase()
          : null,
    );
  }
}

/// Wpis modyfikacji producenta rowerów i osprzętu.
class BikeModEntry {
  final String? matchId;
  final String? matchName;
  final String realName;
  final String countryIso;
  final String? primaryColorHex;
  final double? weightGramsModifier;
  final double? cdaModifier;

  const BikeModEntry({
    this.matchId,
    this.matchName,
    required this.realName,
    required this.countryIso,
    this.primaryColorHex,
    this.weightGramsModifier,
    this.cdaModifier,
  });

  BikeModEntry copyWith({
    String? matchId,
    String? matchName,
    String? realName,
    String? countryIso,
    String? primaryColorHex,
    double? weightGramsModifier,
    double? cdaModifier,
  }) {
    return BikeModEntry(
      matchId: matchId ?? this.matchId,
      matchName: matchName ?? this.matchName,
      realName: realName ?? this.realName,
      countryIso: countryIso ?? this.countryIso,
      primaryColorHex: primaryColorHex ?? this.primaryColorHex,
      weightGramsModifier: weightGramsModifier ?? this.weightGramsModifier,
      cdaModifier: cdaModifier ?? this.cdaModifier,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (matchId != null) 'matchId': matchId,
      if (matchName != null) 'matchName': matchName,
      'realName': realName,
      'countryIso': countryIso,
      if (primaryColorHex != null) 'primaryColorHex': primaryColorHex,
      if (weightGramsModifier != null) 'weightGramsModifier': weightGramsModifier,
      if (cdaModifier != null) 'cdaModifier': cdaModifier,
    };
  }

  factory BikeModEntry.fromJson(Map<String, dynamic> json) {
    return BikeModEntry(
      matchId: json['matchId'] as String?,
      matchName: json['matchName'] as String?,
      realName: json['realName'] as String? ?? 'Official Bike Brand',
      countryIso: (json['countryIso'] as String? ?? 'ITA').toUpperCase(),
      primaryColorHex: json['primaryColorHex'] as String?,
      weightGramsModifier: json['weightGramsModifier'] != null
          ? (json['weightGramsModifier'] as num).toDouble()
          : null,
      cdaModifier: json['cdaModifier'] != null
          ? (json['cdaModifier'] as num).toDouble()
          : null,
    );
  }
}

/// Pełny pakiet modyfikacji społecznościowej (Real Name Pack).
class CustomModPackage {
  final CustomModMetadata metadata;
  final List<TeamModEntry> teams;
  final List<RiderModEntry> riders;
  final List<RaceModEntry> races;
  final List<BikeModEntry> bikeManufacturers;

  const CustomModPackage({
    required this.metadata,
    this.teams = const [],
    this.riders = const [],
    this.races = const [],
    this.bikeManufacturers = const [],
  });

  CustomModPackage copyWith({
    CustomModMetadata? metadata,
    List<TeamModEntry>? teams,
    List<RiderModEntry>? riders,
    List<RaceModEntry>? races,
    List<BikeModEntry>? bikeManufacturers,
  }) {
    return CustomModPackage(
      metadata: metadata ?? this.metadata,
      teams: teams ?? this.teams,
      riders: riders ?? this.riders,
      races: races ?? this.races,
      bikeManufacturers: bikeManufacturers ?? this.bikeManufacturers,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'metadata': metadata.toJson(),
      'teams': teams.map((e) => e.toJson()).toList(),
      'riders': riders.map((e) => e.toJson()).toList(),
      'races': races.map((e) => e.toJson()).toList(),
      'bikeManufacturers': bikeManufacturers.map((e) => e.toJson()).toList(),
    };
  }

  factory CustomModPackage.fromJson(Map<String, dynamic> json) {
    final metaJson = json['metadata'] as Map<String, dynamic>? ?? {};
    final teamsJson = json['teams'] as List<dynamic>? ?? [];
    final ridersJson = json['riders'] as List<dynamic>? ?? [];
    final racesJson = json['races'] as List<dynamic>? ?? [];
    final bikesJson = json['bikeManufacturers'] as List<dynamic>? ?? [];

    return CustomModPackage(
      metadata: CustomModMetadata.fromJson(metaJson),
      teams: teamsJson
          .map((e) => TeamModEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      riders: ridersJson
          .map((e) => RiderModEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      races: racesJson
          .map((e) => RaceModEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      bikeManufacturers: bikesJson
          .map((e) => BikeModEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  String toString() {
    return 'CustomModPackage(${metadata.name}, riders: ${riders.length}, teams: ${teams.length}, races: ${races.length}, bikes: ${bikeManufacturers.length})';
  }
}

/// Stopień istotności wykrytego problemu podczas walidacji pliku modu.
enum ModValidationSeverity {
  error,
  warning,
  info,
}

/// Szczegółowy wpis problemu walidacji.
class ModValidationIssue {
  final ModValidationSeverity severity;
  final String category;
  final String message;
  final String? targetIdentifier;

  const ModValidationIssue({
    required this.severity,
    required this.category,
    required this.message,
    this.targetIdentifier,
  });

  Map<String, dynamic> toJson() {
    return {
      'severity': severity.name,
      'category': category,
      'message': message,
      if (targetIdentifier != null) 'targetIdentifier': targetIdentifier,
    };
  }
}

/// Wynik walidacji składniowej i logicznej pliku modyfikacji.
class ModValidationResult {
  final bool isValid;
  final List<ModValidationIssue> issues;
  final int totalTeamsInMod;
  final int totalRidersInMod;
  final int totalRacesInMod;
  final int totalBikesInMod;

  const ModValidationResult({
    required this.isValid,
    required this.issues,
    required this.totalTeamsInMod,
    required this.totalRidersInMod,
    required this.totalRacesInMod,
    required this.totalBikesInMod,
  });

  List<ModValidationIssue> get errors =>
      issues.where((i) => i.severity == ModValidationSeverity.error).toList();

  List<ModValidationIssue> get warnings =>
      issues.where((i) => i.severity == ModValidationSeverity.warning).toList();

  List<ModValidationIssue> get infos =>
      issues.where((i) => i.severity == ModValidationSeverity.info).toList();
}

/// Raport z zaaplikowania modyfikacji na aktywnym stanie gry.
class ModApplyResult {
  final CareerSave updatedSave;
  final int ridersRenamed;
  final int teamsUpdated;
  final int racesRenamed;
  final int bikesUpdated;
  final String summary;
  final List<String> logMessages;

  const ModApplyResult({
    required this.updatedSave,
    required this.ridersRenamed,
    required this.teamsUpdated,
    required this.racesRenamed,
    required this.bikesUpdated,
    required this.summary,
    required this.logMessages,
  });
}

/// Główny serwis zarządzający importem, walidacją, podmianą nazw i trwałością modyfikacji Real Name Pack.
class CustomModImporterService {
  CustomModImporterService._();

  static const String _modsFolderName = 'ppm_mods';
  static const String defaultModFileName = 'default_real_name_pack.json';

  static final RegExp _hexColorRegex = RegExp(r'^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$');

  /// Katalog na dysku dla plików modyfikacji
  static Future<Directory> getModsDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final modsDir = Directory('${appDocDir.path}${Platform.pathSeparator}$_modsFolderName');
    if (!await modsDir.exists()) {
      await modsDir.create(recursive: true);
    }
    return modsDir;
  }

  /// Sprawdza, czy użytkownik ma zapisany domyślny preset Real Name Pack
  static Future<bool> hasDefaultModPreset() async {
    final dir = await getModsDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}$defaultModFileName');
    return file.exists();
  }

  /// Wczytuje domyślny mod preset do użycia przy starcie nowej kariery
  static Future<CustomModPackage?> loadDefaultModPreset() async {
    final dir = await getModsDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}$defaultModFileName');
    if (!await file.exists()) return null;

    try {
      final content = await file.readAsString();
      final jsonMap = jsonDecode(content) as Map<String, dynamic>;
      return CustomModPackage.fromJson(jsonMap);
    } catch (_) {
      return null;
    }
  }

  /// Zapisuje paczkę modu jako domyślny preset przy tworzeniu nowych karier
  static Future<bool> saveModAsDefaultPreset(CustomModPackage package) async {
    try {
      final dir = await getModsDirectory();
      final file = File('${dir.path}${Platform.pathSeparator}$defaultModFileName');
      final jsonString = const JsonEncoder.withIndent('  ').convert(package.toJson());
      await file.writeAsString(jsonString, flush: true);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Usuwa domyślny preset modu
  static Future<bool> deleteDefaultModPreset() async {
    final dir = await getModsDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}$defaultModFileName');
    if (await file.exists()) {
      await file.delete();
      return true;
    }
    return false;
  }

  /// Waliduje strukturę pliku JSON pod kątem poprawności danych, schematu i formatów kolorów HEX.
  static ModValidationResult validateModJson(String jsonString) {
    final List<ModValidationIssue> issues = [];

    dynamic decoded;
    try {
      decoded = jsonDecode(jsonString);
    } catch (e) {
      issues.add(
        ModValidationIssue(
          severity: ModValidationSeverity.error,
          category: 'syntax',
          message: 'Błąd składniowy JSON: $e',
        ),
      );
      return ModValidationResult(
        isValid: false,
        issues: issues,
        totalTeamsInMod: 0,
        totalRidersInMod: 0,
        totalRacesInMod: 0,
        totalBikesInMod: 0,
      );
    }

    if (decoded is! Map<String, dynamic>) {
      issues.add(
        const ModValidationIssue(
          severity: ModValidationSeverity.error,
          category: 'root',
          message: 'Główny element pliku modyfikacji musi być obiektem JSON (Map<String, dynamic>).',
        ),
      );
      return ModValidationResult(
        isValid: false,
        issues: issues,
        totalTeamsInMod: 0,
        totalRidersInMod: 0,
        totalRacesInMod: 0,
        totalBikesInMod: 0,
      );
    }

    final root = decoded;

    // 1. Walidacja metadanych
    final meta = root['metadata'];
    if (meta == null || meta is! Map<String, dynamic>) {
      issues.add(
        const ModValidationIssue(
          severity: ModValidationSeverity.warning,
          category: 'metadata',
          message: 'Brak sekcji "metadata" – wygenerowano wartości domyślne.',
        ),
      );
    } else {
      final name = meta['name'] as String?;
      if (name == null || name.trim().isEmpty) {
        issues.add(
          const ModValidationIssue(
            severity: ModValidationSeverity.warning,
            category: 'metadata',
            message: 'Nazwa modyfikacji jest pusta.',
          ),
        );
      }
    }

    // 2. Walidacja sekcji drużyn
    int teamsCount = 0;
    final teams = root['teams'];
    if (teams != null) {
      if (teams is! List) {
        issues.add(
          const ModValidationIssue(
            severity: ModValidationSeverity.error,
            category: 'teams',
            message: 'Pole "teams" musi być listą obiektów.',
          ),
        );
      } else {
        teamsCount = teams.length;
        for (int i = 0; i < teams.length; i++) {
          final t = teams[i];
          if (t is! Map<String, dynamic>) {
            issues.add(
              ModValidationIssue(
                severity: ModValidationSeverity.error,
                category: 'teams',
                message: 'Wpis drużyny #$i nie jest poprawnym obiektem JSON.',
              ),
            );
            continue;
          }

          final name = t['name'] as String?;
          if (name == null || name.trim().isEmpty) {
            issues.add(
              ModValidationIssue(
                severity: ModValidationSeverity.error,
                category: 'teams',
                message: 'Drużyna #$i nie posiada nazwy.',
              ),
            );
          }

          final matchId = t['matchId'] as String?;
          final matchOriginalName = t['matchOriginalName'] as String?;
          if ((matchId == null || matchId.isEmpty) &&
              (matchOriginalName == null || matchOriginalName.isEmpty)) {
            issues.add(
              ModValidationIssue(
                severity: ModValidationSeverity.warning,
                category: 'teams',
                message: 'Drużyna "${name ?? '#$i'}" nie posiada matchId ani matchOriginalName (może nie zostać dopasowana).',
              ),
            );
          }

          // Sprawdzanie kolorów HEX
          for (final colorKey in [
            'primaryJerseyColorHex',
            'secondaryJerseyColorHex',
            'accentJerseyColorHex'
          ]) {
            final col = t[colorKey] as String?;
            if (col != null && !_hexColorRegex.hasMatch(col)) {
              issues.add(
                ModValidationIssue(
                  severity: ModValidationSeverity.warning,
                  category: 'color',
                  message: 'Drużyna "${name ?? '#$i'}" ma niepoprawny format koloru $colorKey: "$col" (oczekiwano #RRGGBB).',
                ),
              );
            }
          }
        }
      }
    }

    // 3. Walidacja sekcji kolarzy
    int ridersCount = 0;
    final riders = root['riders'];
    if (riders != null) {
      if (riders is! List) {
        issues.add(
          const ModValidationIssue(
            severity: ModValidationSeverity.error,
            category: 'riders',
            message: 'Pole "riders" musi być listą obiektów.',
          ),
        );
      } else {
        ridersCount = riders.length;
        for (int i = 0; i < riders.length; i++) {
          final r = riders[i];
          if (r is! Map<String, dynamic>) {
            issues.add(
              ModValidationIssue(
                severity: ModValidationSeverity.error,
                category: 'riders',
                message: 'Wpis kolarza #$i nie jest poprawnym obiektem JSON.',
              ),
            );
            continue;
          }

          final firstName = r['firstName'] as String?;
          final lastName = r['lastName'] as String?;
          if ((firstName == null || firstName.trim().isEmpty) ||
              (lastName == null || lastName.trim().isEmpty)) {
            issues.add(
              ModValidationIssue(
                severity: ModValidationSeverity.error,
                category: 'riders',
                message: 'Kolarz #$i nie posiada imienia lub nazwiska.',
              ),
            );
          }

          final nat = r['nationalityIso'] as String?;
          if (nat == null || nat.length < 2 || nat.length > 3) {
            issues.add(
              ModValidationIssue(
                severity: ModValidationSeverity.warning,
                category: 'riders',
                message: 'Kolarz "${firstName ?? ''} ${lastName ?? '#$i'}" posiada nietypowy kod narodowości: "$nat".',
              ),
            );
          }
        }
      }
    }

    // 4. Walidacja sekcji wyścigów
    int racesCount = 0;
    final races = root['races'];
    if (races != null) {
      if (races is! List) {
        issues.add(
          const ModValidationIssue(
            severity: ModValidationSeverity.error,
            category: 'races',
            message: 'Pole "races" musi być listą obiektów.',
          ),
        );
      } else {
        racesCount = races.length;
        for (int i = 0; i < races.length; i++) {
          final rc = races[i];
          if (rc is! Map<String, dynamic>) {
            issues.add(
              ModValidationIssue(
                severity: ModValidationSeverity.error,
                category: 'races',
                message: 'Wpis wyścigu #$i nie jest obiektem JSON.',
              ),
            );
            continue;
          }

          final name = rc['name'] as String?;
          if (name == null || name.trim().isEmpty) {
            issues.add(
              ModValidationIssue(
                severity: ModValidationSeverity.error,
                category: 'races',
                message: 'Wyścig #$i nie posiada nazwy.',
              ),
            );
          }
        }
      }
    }

    // 5. Walidacja sekcji producentów rowerów
    int bikesCount = 0;
    final bikes = root['bikeManufacturers'];
    if (bikes != null) {
      if (bikes is! List) {
        issues.add(
          const ModValidationIssue(
            severity: ModValidationSeverity.error,
            category: 'bikes',
            message: 'Pole "bikeManufacturers" musi być listą obiektów.',
          ),
        );
      } else {
        bikesCount = bikes.length;
        for (int i = 0; i < bikes.length; i++) {
          final b = bikes[i];
          if (b is! Map<String, dynamic>) {
            issues.add(
              ModValidationIssue(
                severity: ModValidationSeverity.error,
                category: 'bikes',
                message: 'Wpis marki rowerowej #$i nie jest obiektem JSON.',
              ),
            );
            continue;
          }

          final realName = b['realName'] as String?;
          if (realName == null || realName.trim().isEmpty) {
            issues.add(
              ModValidationIssue(
                severity: ModValidationSeverity.error,
                category: 'bikes',
                message: 'Marka rowerowa #$i nie posiada nazwy "realName".',
              ),
            );
          }
        }
      }
    }

    if (teamsCount == 0 && ridersCount == 0 && racesCount == 0 && bikesCount == 0) {
      issues.add(
        const ModValidationIssue(
          severity: ModValidationSeverity.error,
          category: 'empty',
          message: 'Paczka modyfikacji nie zawiera żadnych wpisów kolarzy, drużyn, wyścigów ani rowerów.',
        ),
      );
    }

    final hasErrors = issues.any((i) => i.severity == ModValidationSeverity.error);

    return ModValidationResult(
      isValid: !hasErrors,
      issues: issues,
      totalTeamsInMod: teamsCount,
      totalRidersInMod: ridersCount,
      totalRacesInMod: racesCount,
      totalBikesInMod: bikesCount,
    );
  }

  /// Przetwarza bajty pliku (wykrywa czy to czysty JSON czy archiwum ZIP) i parsuje do paczki modu.
  static Future<CustomModPackage> importModFromBytes(List<int> bytes) async {
    // Sprawdzamy czy to format ZIP (magiczny nagłówek PK\x03\x04 = 0x50 0x4B 0x03 0x04)
    if (bytes.length > 4 &&
        bytes[0] == 0x50 &&
        bytes[1] == 0x4B &&
        bytes[2] == 0x03 &&
        bytes[3] == 0x04) {
      final jsonString = _extractJsonFromZip(bytes);
      if (jsonString != null) {
        final map = jsonDecode(jsonString) as Map<String, dynamic>;
        return CustomModPackage.fromJson(map);
      }
      throw const FormatException('Archiwum ZIP nie zawiera pliku .json z modyfikacją.');
    }

    // Standardowy UTF-8 JSON
    final jsonString = utf8.decode(bytes);
    final map = jsonDecode(jsonString) as Map<String, dynamic>;
    return CustomModPackage.fromJson(map);
  }

  /// Prosty, bezbiblioteczny ekstraktor pierwszego pliku .json z archiwum ZIP w czystym Darcie.
  static String? _extractJsonFromZip(List<int> bytes) {
    int offset = 0;
    while (offset + 30 <= bytes.length) {
      // Szukamy sygnatury nagłówka pliku lokalnego: 0x04034b50 (PK\x03\x04)
      if (bytes[offset] != 0x50 ||
          bytes[offset + 1] != 0x4B ||
          bytes[offset + 2] != 0x03 ||
          bytes[offset + 3] != 0x04) {
        break;
      }

      final compressionMethod = bytes[offset + 8] | (bytes[offset + 9] << 8);
      final compressedSize = bytes[offset + 18] |
          (bytes[offset + 19] << 8) |
          (bytes[offset + 20] << 16) |
          (bytes[offset + 21] << 24);
      final fileNameLength = bytes[offset + 26] | (bytes[offset + 27] << 8);
      final extraFieldLength = bytes[offset + 28] | (bytes[offset + 29] << 8);

      final fileNameStart = offset + 30;
      final fileNameEnd = fileNameStart + fileNameLength;
      if (fileNameEnd > bytes.length) break;

      final fileName = utf8.decode(bytes.sublist(fileNameStart, fileNameEnd));
      final dataStart = fileNameEnd + extraFieldLength;
      final dataEnd = dataStart + compressedSize;

      if (dataEnd <= bytes.length && fileName.toLowerCase().endsWith('.json')) {
        final compressedData = bytes.sublist(dataStart, dataEnd);
        if (compressionMethod == 0) {
          // Stored (brak kompresji)
          return utf8.decode(compressedData);
        } else if (compressionMethod == 8) {
          // Deflate
          try {
            final decompressed = ZLibDecoder(raw: true).convert(compressedData);
            return utf8.decode(decompressed);
          } catch (_) {
            // Spróbuj zlib bez flagi raw
            try {
              final decompressed = zlib.decoder.convert(compressedData);
              return utf8.decode(decompressed);
            } catch (_) {}
          }
        }
      }

      offset = dataEnd;
    }
    return null;
  }

  /// Aplikuje paczkę modyfikacji na istniejącym zapisie kariery, podmieniając nazwy, narodowości i kolory.
  static ModApplyResult applyModPackage({
    required CareerSave save,
    required CustomModPackage package,
  }) {
    final List<String> logs = [];
    int teamsUpdatedCount = 0;
    int ridersRenamedCount = 0;
    int racesRenamedCount = 0;
    int bikesUpdatedCount = 0;

    // 1. Podmiana drużyn (nazwy, barwy koszulek, oficjalny sponsor)
    final Map<String, TeamModEntry> teamByMatchId = {};
    final Map<String, TeamModEntry> teamByOriginalName = {};

    for (final t in package.teams) {
      if (t.matchId != null) teamByMatchId[t.matchId!] = t;
      if (t.matchOriginalName != null) {
        teamByOriginalName[t.matchOriginalName!.toLowerCase()] = t;
      }
    }

    final updatedTeams = save.teams.map((team) {
      TeamModEntry? entry = teamByMatchId[team.id];
      entry ??= teamByOriginalName[team.name.toLowerCase()];

      if (entry != null) {
        teamsUpdatedCount++;
        logs.add('Drużyna: "${team.name}" -> "${entry.name}" [${entry.countryIso}]');

        // Aktualizujemy sponsorów, jeśli podano oficjalnego sponsora
        List<SponsorContract> updatedSponsors = team.sponsors;
        if (entry.sponsorCompanyName != null && updatedSponsors.isNotEmpty) {
          updatedSponsors = updatedSponsors.map((s) {
            if (s.sponsorTier == SponsorTier.titlePrimary) {
              return s.copyWith(companyName: entry!.sponsorCompanyName!);
            }
            return s;
          }).toList();
        }

        return team.copyWith(
          name: entry.name,
          countryIso: entry.countryIso,
          primaryJerseyColorHex: entry.primaryJerseyColorHex,
          secondaryJerseyColorHex: entry.secondaryJerseyColorHex,
          accentJerseyColorHex: entry.accentJerseyColorHex,
          sponsors: updatedSponsors,
        );
      }
      return team;
    }).toList();

    // 2. Podmiana kolarzy (prawdziwe nazwiska, narodowości)
    final Map<String, RiderModEntry> riderByMatchId = {};
    final Map<String, RiderModEntry> riderByOriginalName = {};
    final List<RiderModEntry> roleBasedRiders = [];

    for (final r in package.riders) {
      if (r.matchId != null) riderByMatchId[r.matchId!] = r;
      if (r.matchOriginalFullName != null) {
        riderByOriginalName[r.matchOriginalFullName!.toLowerCase()] = r;
      }
      if (r.matchTeamId != null) {
        roleBasedRiders.add(r);
      }
    }

    final Set<String> matchedRiderIds = {};

    final updatedRiders = save.riders.map((rider) {
      // Dopasowanie 1: bezpośrednie matchId
      RiderModEntry? entry = riderByMatchId[rider.id];

      // Dopasowanie 2: oryginalne nazwisko wygenerowane
      entry ??= riderByOriginalName[rider.fullName.toLowerCase()];

      // Dopasowanie 3: matchTeamId + matchRole / matchSpecialization
      if (entry == null) {
        for (final cand in roleBasedRiders) {
          if (!matchedRiderIds.contains(cand.fullName) &&
              cand.matchTeamId == rider.contract.teamId) {
            final bool roleMatches = cand.matchRole == null || cand.matchRole == rider.contract.role;
            final bool specMatches = cand.matchSpecialization == null ||
                cand.matchSpecialization == rider.specialization;

            if (roleMatches && specMatches) {
              entry = cand;
              matchedRiderIds.add(cand.fullName);
              break;
            }
          }
        }
      }

      if (entry != null) {
        ridersRenamedCount++;
        logs.add('Kolarz: "${rider.fullName}" -> "${entry.fullName}" [${entry.nationalityIso}]');

        return rider.copyWith(
          firstName: entry.firstName,
          lastName: entry.lastName,
          nationalityIso: entry.nationalityIso,
        );
      }
      return rider;
    }).toList();

    // 3. Podmiana wyścigów w kalendarzu sezonu
    final Map<String, RaceModEntry> raceByMatchId = {};
    final List<RaceModEntry> keywordRaces = [];

    for (final rc in package.races) {
      if (rc.matchId != null) raceByMatchId[rc.matchId!] = rc;
      if (rc.matchKeyword != null) keywordRaces.add(rc);
    }

    final updatedRaces = save.calendar.races.map((race) {
      RaceModEntry? entry = raceByMatchId[race.id];

      if (entry == null) {
        for (final kw in keywordRaces) {
          final keyword = kw.matchKeyword!.toLowerCase();
          if (race.id.toLowerCase().contains(keyword) ||
              race.name.toLowerCase().contains(keyword)) {
            entry = kw;
            break;
          }
        }
      }

      if (entry != null) {
        racesRenamedCount++;
        logs.add('Wyścig: "${race.name}" -> "${entry.name}"');
        return race.copyWith(
          name: entry.name,
          countryIso: entry.countryIso ?? race.countryIso,
        );
      }
      return race;
    }).toList();

    // 4. Podmiana marek rowerowych (Colnago, Cervélo, Specialized, Pinarello itp.)
    final Map<String, BikeModEntry> bikesByMatchId = {};
    final Map<String, BikeModEntry> bikesByMatchName = {};

    for (final b in package.bikeManufacturers) {
      if (b.matchId != null) bikesByMatchId[b.matchId!] = b;
      if (b.matchName != null) bikesByMatchName[b.matchName!.toLowerCase()] = b;
    }

    final List<CyclingTeam> finalTeams = updatedTeams.map((team) {
      final deal = team.bikeDeal;
      BikeModEntry? entry = bikesByMatchId[deal.manufacturerId];
      entry ??= bikesByMatchName[deal.manufacturerName.toLowerCase()];

      if (entry != null) {
        bikesUpdatedCount++;
        logs.add('Sprzęt (${team.name}): "${deal.manufacturerName}" -> "${entry.realName}"');

        final updatedDeal = deal.copyWith(
          manufacturerName: entry.realName,
        );

        final updatedBikes = team.inventoryBikes.map((bike) {
          final updatedFrame = bike.frame.copyWith(
            name: '${entry!.realName} ${bike.frame.category.name.toUpperCase()}',
          );
          return bike.copyWith(
            name: '${entry.realName} Factory Pro',
            frame: updatedFrame,
          );
        }).toList();

        return team.copyWith(
          bikeDeal: updatedDeal,
          inventoryBikes: updatedBikes,
        );
      }
      return team;
    }).toList();

    // 5. Aktualizacja ofert transferowych (jeśli kolarz został przemianowany)
    final Map<String, String> riderNameMap = {
      for (final r in updatedRiders) r.id: r.fullName,
    };

    final updatedOffers = save.contractOffers.map((o) {
      final realRiderName = riderNameMap[o.riderId];
      if (realRiderName != null && realRiderName != o.riderName) {
        return o.copyWith(riderName: realRiderName);
      }
      return o;
    }).toList();

    // 6. Składanie zaktualizowanego zapisu gry
    final updatedCalendar = save.calendar.copyWith(races: updatedRaces);

    final finalSave = save.copyWith(
      teams: finalTeams,
      riders: updatedRiders,
      calendar: updatedCalendar,
      contractOffers: updatedOffers,
      lastSavedAt: DateTime.now(),
    );

    final summary =
        'Zastosowano modyfikację "${package.metadata.name}" (v${package.metadata.version}): '
        'zaktualizowano $ridersRenamedCount kolarzy, $teamsUpdatedCount drużyn, '
        '$racesRenamedCount wyścigów oraz $bikesUpdatedCount marek rowerowych.';

    return ModApplyResult(
      updatedSave: finalSave,
      ridersRenamed: ridersRenamedCount,
      teamsUpdated: teamsUpdatedCount,
      racesRenamed: racesRenamedCount,
      bikesUpdated: bikesUpdatedCount,
      summary: summary,
      logMessages: logs,
    );
  }

  /// Eksportuje aktualny świat gry gracza do formatu JSON, pozwalając na dzielenie się modami z innymi.
  static String exportCurrentSaveAsModJson(CareerSave save) {
    final metadata = CustomModMetadata(
      id: 'export_${DateTime.now().millisecondsSinceEpoch}',
      name: '${save.saveName} - World Export',
      version: '1.0.0',
      author: save.playerManagerName,
      description: 'Eksport bazy danych kolarzy i zespołów z zapisu kariery.',
      createdDate: DateTime.now(),
    );

    final teams = save.teams.map((t) {
      return TeamModEntry(
        matchId: t.id,
        matchOriginalName: t.name,
        name: t.name,
        countryIso: t.countryIso,
        primaryJerseyColorHex: t.primaryJerseyColorHex,
        secondaryJerseyColorHex: t.secondaryJerseyColorHex,
        accentJerseyColorHex: t.accentJerseyColorHex,
        sponsorCompanyName: t.sponsors.isNotEmpty ? t.sponsors.first.companyName : null,
        brandId: t.bikeDeal.manufacturerId,
      );
    }).toList();

    final riders = save.riders.map((r) {
      return RiderModEntry(
        matchId: r.id,
        matchOriginalFullName: r.fullName,
        matchTeamId: r.contract.teamId,
        matchRole: r.contract.role,
        matchSpecialization: r.specialization,
        firstName: r.firstName,
        lastName: r.lastName,
        nationalityIso: r.nationalityIso,
        targetOverallRating: r.overallRating,
      );
    }).toList();

    final races = save.calendar.races.map((rc) {
      return RaceModEntry(
        matchId: rc.id,
        name: rc.name,
        countryIso: rc.countryIso,
      );
    }).toList();

    final bikes = save.teams.map((t) {
      return BikeModEntry(
        matchId: t.bikeDeal.manufacturerId,
        matchName: t.bikeDeal.manufacturerName,
        realName: t.bikeDeal.manufacturerName,
        countryIso: t.countryIso,
      );
    }).toSet().toList(); // Unikalne marki

    final package = CustomModPackage(
      metadata: metadata,
      teams: teams,
      riders: riders,
      races: races,
      bikeManufacturers: bikes,
    );

    return const JsonEncoder.withIndent('  ').convert(package.toJson());
  }

  /// Tworzy kompletny, autentyczny pakiet 2026 WorldTour Real Name Pack
  /// (Tadej Pogačar, Jonas Vingegaard, Remco Evenepoel, Mathieu van der Poel,
  /// UAE Team Emirates, Visma-Lease a Bike, Tour de France, Colnago, Cervélo itd.).
  static String generateSampleRealNamePackJson() {
    final samplePackage = CustomModPackage(
      metadata: CustomModMetadata(
        id: 'ppm_official_real_name_pack_2026',
        name: 'Official 2026 WorldTour Real Name & Colors Pack',
        version: '2026.1.0',
        author: 'Pro Peloton Community & Deep Cycling Data',
        description:
            'Kompletny zestaw prawdziwych nazwisk kolarzy, oficjalnych barw koszulek drużyn WorldTour/ProTeam, '
            'autentycznych nazw wyścigów (Grand Toury, Monumenty) oraz realnych marek rowerowych (Colnago, Cervélo, Specialized, Pinarello).',
        createdDate: DateTime(2026, 1, 1),
        websiteUrl: 'https://github.com/pro-peloton-manager/mods',
      ),
      teams: const [
        // 1. UAE Team Emirates (Colnago)
        TeamModEntry(
          matchId: 'team_veloce_santander',
          matchOriginalName: 'Veloce-Santander Corsa',
          name: 'UAE Team Emirates',
          countryIso: 'UAE',
          primaryJerseyColorHex: '#FFFFFF',
          secondaryJerseyColorHex: '#111111',
          accentJerseyColorHex: '#D32F2F',
          sponsorCompanyName: 'Emirates Airlines',
          brandId: 'brand_veloce',
        ),
        // 2. Team Visma | Lease a Bike (Cervélo)
        TeamModEntry(
          matchId: 'team_ventus_ned',
          matchOriginalName: 'Ventus-Jumbo Wind Power',
          name: 'Team Visma | Lease a Bike',
          countryIso: 'NED',
          primaryJerseyColorHex: '#FBC02D',
          secondaryJerseyColorHex: '#212121',
          accentJerseyColorHex: '#FFD600',
          sponsorCompanyName: 'Visma Software International',
          brandId: 'brand_ventus',
        ),
        // 3. Soudal Quick-Step (Specialized)
        TeamModEntry(
          matchId: 'team_flanders_vektor',
          matchOriginalName: 'Flanders-AeroVektor Lotto',
          name: 'Soudal Quick-Step',
          countryIso: 'BEL',
          primaryJerseyColorHex: '#0288D1',
          secondaryJerseyColorHex: '#1565C0',
          accentJerseyColorHex: '#FFFFFF',
          sponsorCompanyName: 'Soudal Fixall Group',
          brandId: 'brand_vektor',
        ),
        // 4. INEOS Grenadiers (Pinarello)
        TeamModEntry(
          matchId: 'team_aethel_ineos',
          matchOriginalName: 'Aethel Royal Grenadiers',
          name: 'INEOS Grenadiers',
          countryIso: 'GBR',
          primaryJerseyColorHex: '#002B49',
          secondaryJerseyColorHex: '#C62828',
          accentJerseyColorHex: '#E53935',
          sponsorCompanyName: 'INEOS Chemicals Group',
          brandId: 'brand_aethel',
        ),
        // 5. Alpecin-Deceuninck (Canyon)
        TeamModEntry(
          matchId: 'team_oranje_ned',
          matchOriginalName: 'Oranje-Heineken Classic Velo',
          name: 'Alpecin-Deceuninck',
          countryIso: 'BEL',
          primaryJerseyColorHex: '#002B49',
          secondaryJerseyColorHex: '#1E3A8A',
          accentJerseyColorHex: '#C5A059',
          sponsorCompanyName: 'Alpecin Caffeine Shampoo',
          brandId: 'brand_ventus',
        ),
        // 6. Red Bull - BORA - hansgrohe (Specialized)
        TeamModEntry(
          matchId: 'team_alpina_aut',
          matchOriginalName: 'Alpina-RedBull Energy Velo',
          name: 'Red Bull - BORA - hansgrohe',
          countryIso: 'GER',
          primaryJerseyColorHex: '#0D47A1',
          secondaryJerseyColorHex: '#D50000',
          accentJerseyColorHex: '#FFD600',
          sponsorCompanyName: 'Red Bull Energy Global',
          brandId: 'brand_kronos',
        ),
        // 7. Lidl-Trek (Trek)
        TeamModEntry(
          matchId: 'team_zenith_usa',
          matchOriginalName: 'Zenith-Apex Silicon Valley',
          name: 'Lidl-Trek',
          countryIso: 'USA',
          primaryJerseyColorHex: '#0D47A1',
          secondaryJerseyColorHex: '#C62828',
          accentJerseyColorHex: '#FFD600',
          sponsorCompanyName: 'Lidl Supermarkets International',
          brandId: 'brand_zenith',
        ),
        // 8. Movistar Team (Canyon)
        TeamModEntry(
          matchId: 'team_silvan_esp',
          matchOriginalName: 'Silvan-Euskadi Iberia',
          name: 'Movistar Team',
          countryIso: 'ESP',
          primaryJerseyColorHex: '#005A9C',
          secondaryJerseyColorHex: '#00B0FF',
          accentJerseyColorHex: '#FFFFFF',
          sponsorCompanyName: 'Telefónica Movistar',
          brandId: 'brand_silvan',
        ),
        // 9. Team Jayco AlUla (Giant)
        TeamModEntry(
          matchId: 'team_apex_aus',
          matchOriginalName: 'Apex-Qantas Pacific Velocity',
          name: 'Team Jayco AlUla',
          countryIso: 'AUS',
          primaryJerseyColorHex: '#0288D1',
          secondaryJerseyColorHex: '#FFFFFF',
          accentJerseyColorHex: '#FFD600',
          sponsorCompanyName: 'Jayco Recreational Vehicles',
          brandId: 'brand_apex',
        ),
        // 10. Decathlon AG2R La Mondiale (Van Rysel)
        TeamModEntry(
          matchId: 'team_gripmax_fra',
          matchOriginalName: 'GripMax-Michelin Velosport',
          name: 'Decathlon AG2R La Mondiale',
          countryIso: 'FRA',
          primaryJerseyColorHex: '#00B0FF',
          secondaryJerseyColorHex: '#2E7D32',
          accentJerseyColorHex: '#FFFFFF',
          sponsorCompanyName: 'Decathlon Sports France',
          brandId: 'brand_gripmax',
        ),
        // 11. Groupama-FDJ (Wilier)
        TeamModEntry(
          matchId: 'team_azur_fra',
          matchOriginalName: 'Azur-TotalEnergies France',
          name: 'Groupama-FDJ',
          countryIso: 'FRA',
          primaryJerseyColorHex: '#0D47A1',
          secondaryJerseyColorHex: '#D32F2F',
          accentJerseyColorHex: '#FFFFFF',
          sponsorCompanyName: 'Groupama Assurances',
          brandId: 'brand_gripmax',
        ),
        // 12. Bahrain Victorious (Merida)
        TeamModEntry(
          matchId: 'team_corsa_armani',
          matchOriginalName: 'Corsa d\'Oro-Armani Squadra',
          name: 'Bahrain Victorious',
          countryIso: 'BRN',
          primaryJerseyColorHex: '#D32F2F',
          secondaryJerseyColorHex: '#00838F',
          accentJerseyColorHex: '#F4D03F',
          sponsorCompanyName: 'Kingdom of Bahrain',
          brandId: 'brand_corsa_doro',
        ),
        // 13. Team dsm-firmenich PostNL (Scott)
        TeamModEntry(
          matchId: 'team_boreas_den',
          matchOriginalName: 'Boreas-Maersk Nordic Line',
          name: 'Team dsm-firmenich PostNL',
          countryIso: 'NED',
          primaryJerseyColorHex: '#00B0FF',
          secondaryJerseyColorHex: '#FF6D00',
          accentJerseyColorHex: '#212121',
          sponsorCompanyName: 'DSM-Firmenich Nutrition',
          brandId: 'brand_boreas',
        ),
        // 14. EF Education-EasyPost (Cannondale)
        TeamModEntry(
          matchId: 'team_sovereign_ger',
          matchOriginalName: 'Sovereign-Lufthansa Team',
          name: 'EF Education-EasyPost',
          countryIso: 'USA',
          primaryJerseyColorHex: '#FF4081',
          secondaryJerseyColorHex: '#00E676',
          accentJerseyColorHex: '#212121',
          sponsorCompanyName: 'EF Language Schools',
          brandId: 'brand_sovereign',
        ),
        // 15. Astana Qazaqstan Team (Wilier)
        TeamModEntry(
          matchId: 'team_kuraudo_jpn',
          matchOriginalName: 'Kuraudo-Toyota Racing Team',
          name: 'Astana Qazaqstan Team',
          countryIso: 'KAZ',
          primaryJerseyColorHex: '#00ACC1',
          secondaryJerseyColorHex: '#FFD600',
          accentJerseyColorHex: '#FFFFFF',
          sponsorCompanyName: 'Samruk-Kazyna Sovereign Fund',
          brandId: 'brand_kuraudo',
        ),
        // 16. Uno-X Mobility (Dare)
        TeamModEntry(
          matchId: 'team_nordic_nor',
          matchOriginalName: 'Nordic-Equinor Arctic Squad',
          name: 'Uno-X Mobility',
          countryIso: 'NOR',
          primaryJerseyColorHex: '#D32F2F',
          secondaryJerseyColorHex: '#FFD600',
          accentJerseyColorHex: '#212121',
          sponsorCompanyName: 'Uno-X Mobility Norway',
          brandId: 'brand_nordic',
        ),
        // 17. Tudor Pro Cycling Team (BMC)
        TeamModEntry(
          matchId: 'team_kronos_swiss',
          matchOriginalName: 'Kronos Precision Velo',
          name: 'Tudor Pro Cycling Team',
          countryIso: 'SUI',
          primaryJerseyColorHex: '#D32F2F',
          secondaryJerseyColorHex: '#111111',
          accentJerseyColorHex: '#FFFFFF',
          sponsorCompanyName: 'Tudor Watch SA',
          brandId: 'brand_kronos',
        ),
        // 18. Polonia-Orlen Racing Team (Factor)
        TeamModEntry(
          matchId: 'team_polonia_orlen',
          matchOriginalName: 'Polonia-Orlen Racing Team',
          name: 'Polonia-Orlen Pro Cycling',
          countryIso: 'POL',
          primaryJerseyColorHex: '#D32F2F',
          secondaryJerseyColorHex: '#FFFFFF',
          accentJerseyColorHex: '#111111',
          sponsorCompanyName: 'ORLEN Petrochemical Global',
          brandId: 'brand_aethel',
        ),
      ],
      riders: const [
        // Tadej Pogačar (UAE Team Emirates)
        RiderModEntry(
          matchTeamId: 'team_veloce_santander',
          matchRole: RiderRole.teamLeader,
          matchSpecialization: RiderSpecialization.gcClimber,
          firstName: 'Tadej',
          lastName: 'Pogačar',
          nationalityIso: 'SLO',
          birthYear: 1998,
          targetOverallRating: 94,
        ),
        // Jonas Vingegaard (Team Visma)
        RiderModEntry(
          matchTeamId: 'team_ventus_ned',
          matchRole: RiderRole.teamLeader,
          matchSpecialization: RiderSpecialization.gcClimber,
          firstName: 'Jonas',
          lastName: 'Vingegaard',
          nationalityIso: 'DEN',
          birthYear: 1996,
          targetOverallRating: 93,
        ),
        // Remco Evenepoel (Soudal Quick-Step)
        RiderModEntry(
          matchTeamId: 'team_flanders_vektor',
          matchRole: RiderRole.teamLeader,
          matchSpecialization: RiderSpecialization.gcClimber,
          firstName: 'Remco',
          lastName: 'Evenepoel',
          nationalityIso: 'BEL',
          birthYear: 2000,
          targetOverallRating: 92,
        ),
        // Mathieu van der Poel (Alpecin-Deceuninck)
        RiderModEntry(
          matchTeamId: 'team_oranje_ned',
          matchRole: RiderRole.teamLeader,
          matchSpecialization: RiderSpecialization.classicCobbles,
          firstName: 'Mathieu',
          lastName: 'van der Poel',
          nationalityIso: 'NED',
          birthYear: 1995,
          targetOverallRating: 93,
        ),
        // Wout van Aert (Team Visma)
        RiderModEntry(
          matchTeamId: 'team_ventus_ned',
          matchRole: RiderRole.teamLeader,
          matchSpecialization: RiderSpecialization.classicCobbles,
          firstName: 'Wout',
          lastName: 'van Aert',
          nationalityIso: 'BEL',
          birthYear: 1994,
          targetOverallRating: 92,
        ),
        // Primož Roglič (Red Bull - BORA)
        RiderModEntry(
          matchTeamId: 'team_alpina_aut',
          matchRole: RiderRole.teamLeader,
          matchSpecialization: RiderSpecialization.gcClimber,
          firstName: 'Primož',
          lastName: 'Roglič',
          nationalityIso: 'SLO',
          birthYear: 1989,
          targetOverallRating: 91,
        ),
        // Mads Pedersen (Lidl-Trek)
        RiderModEntry(
          matchTeamId: 'team_zenith_usa',
          matchRole: RiderRole.teamLeader,
          matchSpecialization: RiderSpecialization.classicCobbles,
          firstName: 'Mads',
          lastName: 'Pedersen',
          nationalityIso: 'DEN',
          birthYear: 1995,
          targetOverallRating: 90,
        ),
        // Filippo Ganna (INEOS)
        RiderModEntry(
          matchTeamId: 'team_aethel_ineos',
          matchRole: RiderRole.teamLeader,
          matchSpecialization: RiderSpecialization.classicCobbles,
          firstName: 'Filippo',
          lastName: 'Ganna',
          nationalityIso: 'ITA',
          birthYear: 1996,
          targetOverallRating: 89,
        ),
        // Carlos Rodríguez (INEOS GC Leader)
        RiderModEntry(
          matchTeamId: 'team_aethel_ineos',
          matchRole: RiderRole.teamLeader,
          matchSpecialization: RiderSpecialization.gcClimber,
          firstName: 'Carlos',
          lastName: 'Rodríguez',
          nationalityIso: 'ESP',
          birthYear: 2001,
          targetOverallRating: 88,
        ),
        // Juan Ayuso (UAE Team Emirates)
        RiderModEntry(
          matchTeamId: 'team_veloce_santander',
          matchRole: RiderRole.coLeader,
          matchSpecialization: RiderSpecialization.pureClimber,
          firstName: 'Juan',
          lastName: 'Ayuso',
          nationalityIso: 'ESP',
          birthYear: 2002,
          targetOverallRating: 89,
        ),
        // Jasper Philipsen (Alpecin pure sprinter)
        RiderModEntry(
          matchTeamId: 'team_oranje_ned',
          matchRole: RiderRole.sprinter,
          matchSpecialization: RiderSpecialization.pureSprinter,
          firstName: 'Jasper',
          lastName: 'Philipsen',
          nationalityIso: 'BEL',
          birthYear: 1998,
          targetOverallRating: 91,
        ),
        // Jonathan Milan (Lidl-Trek pure sprinter)
        RiderModEntry(
          matchTeamId: 'team_zenith_usa',
          matchRole: RiderRole.sprinter,
          matchSpecialization: RiderSpecialization.pureSprinter,
          firstName: 'Jonathan',
          lastName: 'Milan',
          nationalityIso: 'ITA',
          birthYear: 2000,
          targetOverallRating: 89,
        ),
        // Tim Merlier (Soudal Quick-Step sprinter)
        RiderModEntry(
          matchTeamId: 'team_flanders_vektor',
          matchRole: RiderRole.sprinter,
          matchSpecialization: RiderSpecialization.pureSprinter,
          firstName: 'Tim',
          lastName: 'Merlier',
          nationalityIso: 'BEL',
          birthYear: 1992,
          targetOverallRating: 90,
        ),
        // Enric Mas (Movistar GC)
        RiderModEntry(
          matchTeamId: 'team_silvan_esp',
          matchRole: RiderRole.teamLeader,
          matchSpecialization: RiderSpecialization.gcClimber,
          firstName: 'Enric',
          lastName: 'Mas',
          nationalityIso: 'ESP',
          birthYear: 1995,
          targetOverallRating: 87,
        ),
        // Michał Kwiatkowski (INEOS)
        RiderModEntry(
          matchTeamId: 'team_aethel_ineos',
          matchRole: RiderRole.domestique,
          matchSpecialization: RiderSpecialization.domestiqueEngine,
          firstName: 'Michał',
          lastName: 'Kwiatkowski',
          nationalityIso: 'POL',
          birthYear: 1990,
          targetOverallRating: 85,
        ),
        // Rafał Majka (UAE Team Emirates)
        RiderModEntry(
          matchTeamId: 'team_veloce_santander',
          matchRole: RiderRole.domestique,
          matchSpecialization: RiderSpecialization.domestiqueEngine,
          firstName: 'Rafał',
          lastName: 'Majka',
          nationalityIso: 'POL',
          birthYear: 1989,
          targetOverallRating: 84,
        ),
        // Stanisław Aniołkowski (Polonia Orlen)
        RiderModEntry(
          matchTeamId: 'team_polonia_orlen',
          matchRole: RiderRole.sprinter,
          matchSpecialization: RiderSpecialization.pureSprinter,
          firstName: 'Stanisław',
          lastName: 'Aniołkowski',
          nationalityIso: 'POL',
          birthYear: 1997,
          targetOverallRating: 81,
        ),
      ],
      races: const [
        // Grand Toury
        RaceModEntry(
          matchKeyword: 'tour_de_france',
          name: 'Tour de France',
          countryIso: 'FRA',
        ),
        RaceModEntry(
          matchKeyword: 'giro_corsa_rosa',
          name: 'Giro d\'Italia',
          countryIso: 'ITA',
        ),
        RaceModEntry(
          matchKeyword: 'vuelta_espana',
          name: 'La Vuelta Ciclista a España',
          countryIso: 'ESP',
        ),
        // 5 Monumentów Kolarstwa
        RaceModEntry(
          matchKeyword: 'primavera_monument',
          name: 'Milano - Sanremo (La Primavera)',
          countryIso: 'ITA',
        ),
        RaceModEntry(
          matchKeyword: 'flanders_monument',
          name: 'Ronde van Vlaanderen',
          countryIso: 'BEL',
        ),
        RaceModEntry(
          matchKeyword: 'roubaix_monument',
          name: 'Paris - Roubaix (L\'Enfer du Nord)',
          countryIso: 'FRA',
        ),
        RaceModEntry(
          matchKeyword: 'liege_monument',
          name: 'Liège - Bastogne - Liège (La Doyenne)',
          countryIso: 'BEL',
        ),
        RaceModEntry(
          matchKeyword: 'lombardia_monument',
          name: 'Il Lombardia (Giro delle Foglie Morte)',
          countryIso: 'ITA',
        ),
        // Wiosenne i Tygodniowe Klasyki WorldTour
        RaceModEntry(
          matchKeyword: 'strade',
          name: 'Strade Bianche',
          countryIso: 'ITA',
        ),
        RaceModEntry(
          matchKeyword: 'paris_nice',
          name: 'Paris - Nice (Course au Soleil)',
          countryIso: 'FRA',
        ),
        RaceModEntry(
          matchKeyword: 'tirreno',
          name: 'Tirreno - Adriatico (Corsa dei Due Mari)',
          countryIso: 'ITA',
        ),
        RaceModEntry(
          matchKeyword: 'e3_flemish',
          name: 'E3 Saxo Classic',
          countryIso: 'BEL',
        ),
        RaceModEntry(
          matchKeyword: 'gent_wevelgem',
          name: 'Gent - Wevelgem in Flanders Fields',
          countryIso: 'BEL',
        ),
        RaceModEntry(
          matchKeyword: 'amstel',
          name: 'Amstel Gold Race',
          countryIso: 'NED',
        ),
        RaceModEntry(
          matchKeyword: 'fleche',
          name: 'La Flèche Wallonne',
          countryIso: 'BEL',
        ),
        RaceModEntry(
          matchKeyword: 'catalunya',
          name: 'Volta Ciclista a Catalunya',
          countryIso: 'ESP',
        ),
        RaceModEntry(
          matchKeyword: 'itzulia',
          name: 'Itzulia Basque Country',
          countryIso: 'ESP',
        ),
        RaceModEntry(
          matchKeyword: 'romandie',
          name: 'Tour de Romandie',
          countryIso: 'SUI',
        ),
        RaceModEntry(
          matchKeyword: 'dauphine',
          name: 'Critérium du Dauphiné',
          countryIso: 'FRA',
        ),
        RaceModEntry(
          matchKeyword: 'suisse',
          name: 'Tour de Suisse',
          countryIso: 'SUI',
        ),
        RaceModEntry(
          matchKeyword: 'san_sebastian',
          name: 'Clásica de San Sebastián',
          countryIso: 'ESP',
        ),
        RaceModEntry(
          matchKeyword: 'tour_de_pologne',
          name: 'Tour de Pologne UCI WorldTour',
          countryIso: 'POL',
        ),
        RaceModEntry(
          matchKeyword: 'bretagne',
          name: 'Bretagne Classic - Ouest-France',
          countryIso: 'FRA',
        ),
        RaceModEntry(
          matchKeyword: 'benelux',
          name: 'Renewi Tour',
          countryIso: 'BEL',
        ),
        RaceModEntry(
          matchKeyword: 'quebec',
          name: 'Grand Prix Cycliste de Québec',
          countryIso: 'CAN',
        ),
        RaceModEntry(
          matchKeyword: 'montreal',
          name: 'Grand Prix Cycliste de Montréal',
          countryIso: 'CAN',
        ),
        RaceModEntry(
          matchKeyword: 'southern_tour',
          name: 'Santos Tour Down Under',
          countryIso: 'AUS',
        ),
        RaceModEntry(
          matchKeyword: 'emirates',
          name: 'UAE Tour',
          countryIso: 'UAE',
        ),
        RaceModEntry(
          matchKeyword: 'mallorca',
          name: 'Challenge Mallorca',
          countryIso: 'ESP',
        ),
        RaceModEntry(
          matchKeyword: 'valencia',
          name: 'Volta a la Comunitat Valenciana',
          countryIso: 'ESP',
        ),
        RaceModEntry(
          matchKeyword: 'world_rr',
          name: 'UCI Road World Championships',
          countryIso: 'RWA',
        ),
        RaceModEntry(
          matchKeyword: 'world_itt',
          name: 'UCI Individual Time Trial World Championships',
          countryIso: 'RWA',
        ),
        RaceModEntry(
          matchKeyword: 'national_champs',
          name: 'Mistrzostwa Krajowe (National Championships)',
          countryIso: 'UCI',
        ),
      ],
      bikeManufacturers: const [
        BikeModEntry(
          matchId: 'brand_veloce',
          matchName: 'Veloce Corsa',
          realName: 'Colnago',
          countryIso: 'ITA',
          primaryColorHex: '#000000',
        ),
        BikeModEntry(
          matchId: 'brand_ventus',
          matchName: 'Ventus Dutch Velocity',
          realName: 'Cervélo',
          countryIso: 'CAN',
          primaryColorHex: '#FBC02D',
        ),
        BikeModEntry(
          matchId: 'brand_vektor',
          matchName: 'AeroVektor Flanders',
          realName: 'Specialized S-Works',
          countryIso: 'USA',
          primaryColorHex: '#D32F2F',
        ),
        BikeModEntry(
          matchId: 'brand_aethel',
          matchName: 'Aethel Bicycles',
          realName: 'Pinarello Dogma',
          countryIso: 'ITA',
          primaryColorHex: '#002B49',
        ),
        BikeModEntry(
          matchId: 'brand_sovereign',
          matchName: 'Sovereign German Precision',
          realName: 'Canyon Bicycles',
          countryIso: 'GER',
          primaryColorHex: '#1B5E20',
        ),
        BikeModEntry(
          matchId: 'brand_kronos',
          matchName: 'Kronos Racing Bikes',
          realName: 'BMC Switzerland',
          countryIso: 'SUI',
          primaryColorHex: '#D32F2F',
        ),
        BikeModEntry(
          matchId: 'brand_zenith',
          matchName: 'Zenith AeroTech',
          realName: 'Trek Bicycles',
          countryIso: 'USA',
          primaryColorHex: '#0D47A1',
        ),
        BikeModEntry(
          matchId: 'brand_corsa_doro',
          matchName: 'Corsa d\'Oro Milano',
          realName: 'Bianchi Reparto Corse',
          countryIso: 'ITA',
          primaryColorHex: '#00B0FF',
        ),
        BikeModEntry(
          matchId: 'brand_apex',
          matchName: 'Apex Pacific Dynamics',
          realName: 'Giant Bicycles',
          countryIso: 'TWN',
          primaryColorHex: '#0288D1',
        ),
        BikeModEntry(
          matchId: 'brand_boreas',
          matchName: 'Boreas Nordic Framecraft',
          realName: 'Scott Sports',
          countryIso: 'SUI',
          primaryColorHex: '#FF6D00',
        ),
        BikeModEntry(
          matchId: 'brand_silvan',
          matchName: 'Silvan Cycles Iberia',
          realName: 'Orbea Bicycles',
          countryIso: 'ESP',
          primaryColorHex: '#005A9C',
        ),
        BikeModEntry(
          matchId: 'brand_gripmax',
          matchName: 'GripMax France',
          realName: 'Van Rysel / Look',
          countryIso: 'FRA',
          primaryColorHex: '#00B0FF',
        ),
        BikeModEntry(
          matchId: 'brand_kuraudo',
          matchName: 'Kuraudo Works',
          realName: 'Wilier Triestina',
          countryIso: 'ITA',
          primaryColorHex: '#00ACC1',
        ),
      ],
    );

    return const JsonEncoder.withIndent('  ').convert(samplePackage.toJson());
  }
}
extension on CustomModMetadata {
  static const DateTime _defaultDate = _ConstDateTime(2026, 1, 1);
}

class _ConstDateTime implements DateTime {
  final int _year;
  final int _month;
  final int _day;

  const _ConstDateTime(this._year, this._month, this._day);

  @override
  int get year => _year;
  @override
  int get month => _month;
  @override
  int get day => _day;
  @override
  int get hour => 0;
  @override
  int get minute => 0;
  @override
  int get second => 0;
  @override
  int get millisecond => 0;
  @override
  int get microsecond => 0;
  @override
  int get weekday => 4;
  @override
  bool get isUtc => true;

  @override
  DateTime add(Duration duration) => DateTime(_year, _month, _day).add(duration);
  @override
  DateTime subtract(Duration duration) => DateTime(_year, _month, _day).subtract(duration);
  @override
  Duration difference(DateTime other) => DateTime(_year, _month, _day).difference(other);
  @override
  int compareTo(DateTime other) => DateTime(_year, _month, _day).compareTo(other);
  @override
  bool isAfter(DateTime other) => DateTime(_year, _month, _day).isAfter(other);
  @override
  bool isBefore(DateTime other) => DateTime(_year, _month, _day).isBefore(other);
  @override
  bool isAtSameMomentAs(DateTime other) => DateTime(_year, _month, _day).isAtSameMomentAs(other);
  @override
  DateTime toLocal() => this;
  @override
  DateTime toUtc() => this;
  @override
  String toIso8601String() => '2026-01-01T00:00:00.000Z';
  @override
  int get millisecondsSinceEpoch => 1767225600000;
  @override
  int get microsecondsSinceEpoch => 1767225600000000;
  @override
  String get timeZoneName => 'UTC';
  @override
  Duration get timeZoneOffset => Duration.zero;
}
