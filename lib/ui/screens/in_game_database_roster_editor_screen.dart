import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../models/equipment/complete_bike.dart';
import '../../models/rider/rider.dart';
import '../../models/rider/rider_appearance.dart';
import '../../models/rider/rider_contract.dart';
import '../../models/rider/rider_health.dart';
import '../../models/rider/rider_physiology.dart';
import '../../models/rider/rider_power_profile.dart';
import '../../models/rider/rider_skills.dart';
import '../../models/team/bike_manufacturer_deal.dart';
import '../../models/team/cycling_team.dart';
import '../../models/team/sponsor_contract.dart';
import '../../services/generators/world_teams_generator.dart';

/// Active mobile/compact view tab in [InGameDatabaseRosterEditorScreen].
enum DatabaseEditorTab {
  teams('Drużyny', Icons.shield_outlined),
  roster('Skład', Icons.groups_outlined),
  inspector('Edytor', Icons.tune_rounded);

  const DatabaseEditorTab(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Which entity is currently focused in the right-hand inspector pane.
enum DatabaseEditorEntityMode {
  rider,
  team,
}

/// Sorting criteria for the roster list.
enum DatabaseEditorSortField {
  overall('OVR'),
  name('Nazwisko'),
  age('Wiek'),
  ftp('FTP'),
  wPerKg('W/kg'),
  salary('Pensja');

  const DatabaseEditorSortField(this.label);
  final String label;
}

/// Sub-tabs inside the rider inspector.
enum RiderEditorSection {
  identity('Profil'),
  physiology('Fizjologia'),
  power('Krzywa Mocy'),
  skills('Umiejętności');

  const RiderEditorSection(this.label);
  final String label;
}

/// One recorded modification in the editor's audit log.
class DatabaseEditorChangeEntry {
  const DatabaseEditorChangeEntry({
    required this.timestamp,
    required this.category,
    required this.description,
  });

  final DateTime timestamp;
  final String category;
  final String description;
}

/// Validation issue detected on the current database draft.
class DatabaseEditorValidationIssue {
  const DatabaseEditorValidationIssue({
    required this.entityId,
    required this.entityName,
    required this.message,
    required this.isError,
  });

  final String entityId;
  final String entityName;
  final String message;
  final bool isError;
}

/// Immutable snapshot used for undo/redo history.
class DatabaseEditorSnapshot {
  const DatabaseEditorSnapshot({
    required this.teams,
    required this.riders,
    required this.selectedTeamId,
    required this.selectedRiderId,
  });

  final List<CyclingTeam> teams;
  final List<Rider> riders;
  final String? selectedTeamId;
  final String? selectedRiderId;
}

/// Pure helper for validating and serializing the in-game database.
class DatabaseEditorCodec {
  const DatabaseEditorCodec._();

  static final RegExp _hexRegex = RegExp(r'^#[0-9A-Fa-f]{6}$');

  static bool isValidHexColor(String hex) => _hexRegex.hasMatch(hex.trim());

  static Color parseHexColor(String hex, {Color fallback = AppColors.primaryAccent}) {
    final normalized = hex.trim().replaceFirst('#', '');
    if (normalized.length != 6) return fallback;
    final parsed = int.tryParse('FF$normalized', radix: 16);
    if (parsed == null) return fallback;
    return Color(parsed);
  }

  static List<DatabaseEditorValidationIssue> validateDatabase({
    required List<CyclingTeam> teams,
    required List<Rider> riders,
  }) {
    final issues = <DatabaseEditorValidationIssue>[];
    for (final team in teams) {
      if (team.name.trim().isEmpty) {
        issues.add(DatabaseEditorValidationIssue(
          entityId: team.id,
          entityName: team.id,
          message: 'Nazwa drużyny nie może być pusta.',
          isError: true,
        ));
      }
      if (!isValidHexColor(team.primaryJerseyColorHex) ||
          !isValidHexColor(team.secondaryJerseyColorHex) ||
          !isValidHexColor(team.accentJerseyColorHex)) {
        issues.add(DatabaseEditorValidationIssue(
          entityId: team.id,
          entityName: team.name.isEmpty ? team.id : team.name,
          message: 'Nieprawidłowy format koloru HEX stroju (#RRGGBB).',
          isError: true,
        ));
      }
      final teamRidersCount = riders.where((r) => r.contract.teamId == team.id).length;
      if (team.division == TeamDivision.worldTour && teamRidersCount < 5) {
        issues.add(DatabaseEditorValidationIssue(
          entityId: team.id,
          entityName: team.name,
          message: 'Drużyna WorldTour ma mniej niż 5 kolarzy ($teamRidersCount).',
          isError: false,
        ));
      }
    }

    for (final rider in riders) {
      if (rider.firstName.trim().isEmpty || rider.lastName.trim().isEmpty) {
        issues.add(DatabaseEditorValidationIssue(
          entityId: rider.id,
          entityName: rider.id,
          message: 'Imię i nazwisko kolarza nie mogą być puste.',
          isError: true,
        ));
      }
      if (rider.physiology.weightKg < 45 || rider.physiology.weightKg > 110) {
        issues.add(DatabaseEditorValidationIssue(
          entityId: rider.id,
          entityName: rider.fullName,
          message: 'Waga (${rider.physiology.weightKg.toStringAsFixed(1)} kg) poza zakresem 45–110 kg.',
          isError: false,
        ));
      }
      if (rider.powerProfile.watts5s < rider.powerProfile.watts1m ||
          rider.powerProfile.watts1m < rider.powerProfile.watts20m) {
        issues.add(DatabaseEditorValidationIssue(
          entityId: rider.id,
          entityName: rider.fullName,
          message: 'Krzywa mocy nie jest monotoniczna (5s >= 1m >= 20m).',
          isError: false,
        ));
      }
    }
    return issues;
  }

  static String exportToJson({
    required List<CyclingTeam> teams,
    required List<Rider> riders,
  }) {
    final payload = {
      'schemaVersion': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'teamsCount': teams.length,
      'ridersCount': riders.length,
      'teams': teams.map((t) => t.toJson()).toList(),
      'riders': riders.map((r) => r.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  static ({List<CyclingTeam> teams, List<Rider> riders}) importFromJson(String rawJson) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Główny obiekt JSON musi być mapą.');
    }
    final rawTeams = decoded['teams'];
    final rawRiders = decoded['riders'];
    if (rawTeams is! List || rawRiders is! List) {
      throw const FormatException('Brak wymaganych tablic "teams" oraz "riders".');
    }
    final teams = rawTeams
        .map((e) => CyclingTeam.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final riders = rawRiders
        .map((e) => Rider.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return (teams: teams, riders: riders);
  }
}

/// Built-in in-game Database & Roster Editor screen.
class InGameDatabaseRosterEditorScreen extends StatefulWidget {
  const InGameDatabaseRosterEditorScreen({
    super.key,
    this.initialTeams,
    this.initialRiders,
    this.onApplyDatabase,
    this.onBack,
  });

  final List<CyclingTeam>? initialTeams;
  final List<Rider>? initialRiders;
  final void Function(List<CyclingTeam> teams, List<Rider> riders)? onApplyDatabase;
  final VoidCallback? onBack;

  @override
  State<InGameDatabaseRosterEditorScreen> createState() =>
      _InGameDatabaseRosterEditorScreenState();
}

class _InGameDatabaseRosterEditorScreenState
    extends State<InGameDatabaseRosterEditorScreen>
    with SingleTickerProviderStateMixin {
  static const String _freeAgentTeamId = 'free_agent';

  late List<CyclingTeam> _teams;
  late List<Rider> _riders;
  String? _selectedTeamId;
  String? _selectedRiderId;

  DatabaseEditorTab _mobileTab = DatabaseEditorTab.teams;
  DatabaseEditorEntityMode _entityMode = DatabaseEditorEntityMode.rider;
  RiderEditorSection _riderSection = RiderEditorSection.identity;

  TeamDivision? _divisionFilter;
  bool _showFreeAgentsOnly = false;
  String _teamSearchQuery = '';
  String _rosterSearchQuery = '';
  RiderSpecialization? _specFilter;
  DatabaseEditorSortField _sortField = DatabaseEditorSortField.overall;
  bool _sortAscending = false;

  final List<DatabaseEditorSnapshot> _undoStack = [];
  final List<DatabaseEditorSnapshot> _redoStack = [];
  final List<DatabaseEditorChangeEntry> _changeLog = [];
  bool _hasUnsavedChanges = false;
  String? _statusBanner;

  late final AnimationController _pulseController;
  final TextEditingController _teamSearchController = TextEditingController();
  final TextEditingController _rosterSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _initializeDatabase();
  }

  void _initializeDatabase() {
    if (widget.initialTeams != null && widget.initialRiders != null) {
      _teams = List<CyclingTeam>.from(widget.initialTeams!);
      _riders = List<Rider>.from(widget.initialRiders!);
    } else {
      final generated = WorldTeamsGenerator.generateWorldTourSystem(seed: 2026);
      _teams = List<CyclingTeam>.from(generated.teams);
      _riders = List<Rider>.from(generated.allRiders);
    }

    if (_teams.isNotEmpty) {
      _selectedTeamId = _teams.first.id;
      final firstRoster = _ridersForTeam(_selectedTeamId!);
      _selectedRiderId = firstRoster.isNotEmpty
          ? firstRoster.first.id
          : (_riders.isNotEmpty ? _riders.first.id : null);
    } else if (_riders.isNotEmpty) {
      _selectedRiderId = _riders.first.id;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _teamSearchController.dispose();
    _rosterSearchController.dispose();
    super.dispose();
  }

  void _pushUndoSnapshot(String category, String description) {
    _undoStack.add(
      DatabaseEditorSnapshot(
        teams: List<CyclingTeam>.from(_teams),
        riders: List<Rider>.from(_riders),
        selectedTeamId: _selectedTeamId,
        selectedRiderId: _selectedRiderId,
      ),
    );
    if (_undoStack.length > 40) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
    _changeLog.insert(
      0,
      DatabaseEditorChangeEntry(
        timestamp: DateTime.now(),
        category: category,
        description: description,
      ),
    );
    if (_changeLog.length > 50) {
      _changeLog.removeLast();
    }
    _hasUnsavedChanges = true;
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(
      DatabaseEditorSnapshot(
        teams: List<CyclingTeam>.from(_teams),
        riders: List<Rider>.from(_riders),
        selectedTeamId: _selectedTeamId,
        selectedRiderId: _selectedRiderId,
      ),
    );
    final prev = _undoStack.removeLast();
    setState(() {
      _teams = List<CyclingTeam>.from(prev.teams);
      _riders = List<Rider>.from(prev.riders);
      _selectedTeamId = prev.selectedTeamId;
      _selectedRiderId = prev.selectedRiderId;
      _statusBanner = 'Cofnięto ostatnią zmianę.';
    });
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(
      DatabaseEditorSnapshot(
        teams: List<CyclingTeam>.from(_teams),
        riders: List<Rider>.from(_riders),
        selectedTeamId: _selectedTeamId,
        selectedRiderId: _selectedRiderId,
      ),
    );
    final next = _redoStack.removeLast();
    setState(() {
      _teams = List<CyclingTeam>.from(next.teams);
      _riders = List<Rider>.from(next.riders);
      _selectedTeamId = next.selectedTeamId;
      _selectedRiderId = next.selectedRiderId;
      _statusBanner = 'Ponowiono zmianę.';
    });
  }

  CyclingTeam? get _selectedTeam {
    if (_selectedTeamId == null) return null;
    for (final t in _teams) {
      if (t.id == _selectedTeamId) return t;
    }
    return null;
  }

  Rider? get _selectedRider {
    if (_selectedRiderId == null) return null;
    for (final r in _riders) {
      if (r.id == _selectedRiderId) return r;
    }
    return null;
  }

  List<CyclingTeam> get _filteredTeams {
    final query = _teamSearchQuery.trim().toLowerCase();
    return _teams.where((team) {
      if (_divisionFilter != null && team.division != _divisionFilter) {
        return false;
      }
      if (query.isEmpty) return true;
      return team.name.toLowerCase().contains(query) ||
          team.countryIso.toLowerCase().contains(query) ||
          team.id.toLowerCase().contains(query);
    }).toList();
  }

  List<Rider> _ridersForTeam(String teamId) {
    return _riders.where((r) => r.contract.teamId == teamId).toList();
  }

  List<Rider> get _filteredRoster {
    Iterable<Rider> base;
    if (_showFreeAgentsOnly) {
      final teamIds = _teams.map((t) => t.id).toSet();
      base = _riders.where(
        (r) => r.contract.teamId == _freeAgentTeamId || !teamIds.contains(r.contract.teamId),
      );
    } else if (_selectedTeamId != null) {
      base = _riders.where((r) => r.contract.teamId == _selectedTeamId);
    } else {
      base = _riders;
    }

    final query = _rosterSearchQuery.trim().toLowerCase();
    final filtered = base.where((r) {
      if (_specFilter != null && r.specialization != _specFilter) {
        return false;
      }
      if (query.isEmpty) return true;
      return r.fullName.toLowerCase().contains(query) ||
          r.nationalityIso.toLowerCase().contains(query);
    }).toList();

    filtered.sort((a, b) {
      int cmp;
      switch (_sortField) {
        case DatabaseEditorSortField.overall:
          cmp = a.overallRating.compareTo(b.overallRating);
        case DatabaseEditorSortField.name:
          cmp = a.lastName.compareTo(b.lastName);
        case DatabaseEditorSortField.age:
          cmp = a.age.compareTo(b.age);
        case DatabaseEditorSortField.ftp:
          cmp = a.physiology.ftpWatts.compareTo(b.physiology.ftpWatts);
        case DatabaseEditorSortField.wPerKg:
          cmp = a.physiology.wattsPerKg.compareTo(b.physiology.wattsPerKg);
        case DatabaseEditorSortField.salary:
          cmp = a.contract.monthlySalaryEur.compareTo(b.contract.monthlySalaryEur);
      }
      return _sortAscending ? cmp : -cmp;
    });

    return filtered;
  }

  void _updateTeam(CyclingTeam updated, String logDescription) {
    final idx = _teams.indexWhere((t) => t.id == updated.id);
    if (idx == -1) return;
    _pushUndoSnapshot('Drużyna', logDescription);
    setState(() {
      _teams[idx] = updated;
      _statusBanner = logDescription;
    });
  }

  void _updateRider(Rider updated, String logDescription) {
    final idx = _riders.indexWhere((r) => r.id == updated.id);
    if (idx == -1) return;
    _pushUndoSnapshot('Kolarz', logDescription);
    setState(() {
      _riders[idx] = updated;
      _statusBanner = logDescription;
    });
  }

  void _transferRiderToTeam(Rider rider, String targetTeamId) {
    if (rider.contract.teamId == targetTeamId) return;
    _pushUndoSnapshot('Transfer', '${rider.fullName} -> $targetTeamId');
    setState(() {
      final oldTeamId = rider.contract.teamId;
      for (int i = 0; i < _teams.length; i++) {
        final team = _teams[i];
        if (team.id == oldTeamId) {
          _teams[i] = team.copyWith(
            rosterRiderIds: team.rosterRiderIds.where((id) => id != rider.id).toList(),
          );
        } else if (team.id == targetTeamId) {
          final nextIds = List<String>.from(team.rosterRiderIds);
          if (!nextIds.contains(rider.id)) nextIds.add(rider.id);
          _teams[i] = team.copyWith(rosterRiderIds: nextIds);
        }
      }
      final rIdx = _riders.indexWhere((r) => r.id == rider.id);
      if (rIdx != -1) {
        _riders[rIdx] = rider.copyWith(
          contract: rider.contract.copyWith(teamId: targetTeamId),
        );
      }
      _statusBanner = 'Przeniesiono ${rider.fullName} do wybranej drużyny.';
    });
  }

  void _createNewTeam() {
    final id = 'custom_team_${DateTime.now().millisecondsSinceEpoch}';
    final baseDeal = _teams.isNotEmpty
        ? _teams.first.bikeDeal
        : const BikeManufacturerDeal(
            manufacturerId: 'aethon_cycles',
            manufacturerName: 'Aethon Cycles',
            prestigeLevel: 4,
            annualCashContributionEur: 1200000,
            freeBikesQuota: 80,
            researchAndDevelopmentLevel: 82,
            suppliedFrameIds: ['aethon_aero_sl', 'aethon_climb_ul'],
            suppliedWheelsetIds: ['aethon_carbon_50'],
            contractYearsLeft: 3,
            minimumUciRankingRequired: 25,
          );
    final baseBikes = _teams.isNotEmpty
        ? _teams.first.inventoryBikes
        : const <CompleteBike>[];
    final baseSponsors = _teams.isNotEmpty
        ? _teams.first.sponsors
        : const <SponsorContract>[];

    final newTeam = CyclingTeam(
      id: id,
      name: 'Nowa Drużyna Pro',
      division: _divisionFilter ?? TeamDivision.proTeam,
      countryIso: 'POL',
      primaryJerseyColorHex: '#8E4A49',
      secondaryJerseyColorHex: '#181B22',
      accentJerseyColorHex: '#D4AF37',
      cashBalanceEur: 3500000,
      monthlyBurnRateEur: 220000,
      uciPointsSeason: 0,
      rosterRiderIds: const [],
      staff: const TeamStaff(
        trainersLevel: 72,
        sportsDirectorsLevel: 74,
        doctorsLevel: 70,
        mechanicsLevel: 75,
        scoutsLevel: 71,
      ),
      bikeDeal: baseDeal,
      sponsors: baseBikes.isEmpty ? baseSponsors : const [],
      inventoryBikes: baseBikes,
    );

    _pushUndoSnapshot('Drużyna', 'Utworzono drużynę ${newTeam.name}');
    setState(() {
      _teams.insert(0, newTeam);
      _selectedTeamId = newTeam.id;
      _showFreeAgentsOnly = false;
      _entityMode = DatabaseEditorEntityMode.team;
      _mobileTab = DatabaseEditorTab.inspector;
      _statusBanner = 'Dodano nową drużynę: ${newTeam.name}';
    });
  }

  void _createNewRider({Rider? cloneFrom}) {
    final teamId = _showFreeAgentsOnly
        ? _freeAgentTeamId
        : (_selectedTeamId ?? (_teams.isNotEmpty ? _teams.first.id : _freeAgentTeamId));
    final id = 'custom_rider_${DateTime.now().millisecondsSinceEpoch}';

    final newRider = cloneFrom != null
        ? cloneFrom.copyWith(
            id: id,
            firstName: cloneFrom.firstName,
            lastName: '${cloneFrom.lastName} II',
            contract: cloneFrom.contract.copyWith(teamId: teamId),
          )
        : Rider(
            id: id,
            firstName: 'Jan',
            lastName: 'Nowak',
            nationalityIso: 'POL',
            birthDate: DateTime(DateTime.now().year - 23, 5, 14),
            potential: 84,
            specialization: RiderSpecialization.puncher,
            physiology: const RiderPhysiology(
              heightCm: 179.0,
              weightKg: 68.5,
              bodyFatPercentage: 7.4,
              ftpWatts: 395,
              wPrimeJoules: 21500,
              vo2Max: 81.0,
              maxHr: 194,
              restingHr: 41,
              lactateThresholdHr: 176,
              recoveryRate: 1.08,
              glycogenCapacityGrams: 620.0,
            ),
            powerProfile: const RiderPowerProfile(
              watts5s: 1320,
              watts15s: 1090,
              watts30s: 880,
              watts1m: 690,
              watts3m: 515,
              watts5m: 470,
              watts20m: 415,
              watts60m: 385,
            ),
            skills: const RiderSkills(
              cobbles: 74,
              descending: 76,
              bikeHandling: 79,
              aeroPositioning: 75,
              draftingEfficiency: 78,
              raceIq: 77,
              rainResistance: 74,
              heatTolerance: 72,
              timeTrialPositioning: 75,
            ),
            appearance: const RiderAppearance(
              faceShapeIndex: 1,
              skinToneHex: '#F1C27D',
              hairStyleIndex: 2,
              hairColorHex: '#3B2F2F',
              facialHairIndex: 0,
              glassesModelId: 'aero_pro',
              glassesLensColorHex: '#38BDF8',
              helmetModelId: 'vent_pro',
              shoeColorHex: '#F3F4F6',
              sockHeightProportion: 0.72,
              bodyBuildType: BodyBuildType.allRounder,
            ),
            contract: RiderContract(
              teamId: teamId,
              role: RiderRole.domestique,
              monthlySalaryEur: 12000,
              signingBonusEur: 15000,
              winBonusEur: 4000,
              releaseClauseEur: 350000,
              contractEndYear: DateTime.now().year + 2,
              morale: 82.0,
              leaderLoyalty: 78.0,
              requiredRacesIds: const [],
            ),
            health: const RiderHealth(
              acuteTrainingLoad: 38.0,
              chronicTrainingLoad: 72.0,
            ),
            careerPointsUci: 145,
          );

    _pushUndoSnapshot(
      'Kolarz',
      cloneFrom != null
          ? 'Zduplikowano kolarza ${cloneFrom.fullName}'
          : 'Utworzono kolarza ${newRider.fullName}',
    );
    setState(() {
      _riders.insert(0, newRider);
      for (int i = 0; i < _teams.length; i++) {
        if (_teams[i].id == teamId) {
          _teams[i] = _teams[i].copyWith(
            rosterRiderIds: [..._teams[i].rosterRiderIds, newRider.id],
          );
          break;
        }
      }
      _selectedRiderId = newRider.id;
      _entityMode = DatabaseEditorEntityMode.rider;
      _mobileTab = DatabaseEditorTab.inspector;
      _statusBanner = 'Dodano kolarza: ${newRider.fullName}';
    });
  }

  Future<void> _confirmDeleteRider(Rider rider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        title: const Text(
          'Usuń kolarza z bazy',
          style: TextStyle(
            fontFamily: 'Inter',
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Czy na pewno chcesz trwale usunąć kolarza ${rider.fullName} z edytowanej bazy danych?',
          style: const TextStyle(
            fontFamily: 'Inter',
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.crimsonAlert,
              foregroundColor: AppColors.textPrimary,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    _pushUndoSnapshot('Kolarz', 'Usunięto kolarza ${rider.fullName}');
    setState(() {
      _riders.removeWhere((r) => r.id == rider.id);
      for (int i = 0; i < _teams.length; i++) {
        if (_teams[i].rosterRiderIds.contains(rider.id)) {
          _teams[i] = _teams[i].copyWith(
            rosterRiderIds: _teams[i].rosterRiderIds
                .where((id) => id != rider.id)
                .toList(),
          );
        }
      }
      final nextRoster = _filteredRoster;
      _selectedRiderId = nextRoster.isNotEmpty ? nextRoster.first.id : null;
      _statusBanner = 'Usunięto ${rider.fullName} z bazy.';
    });
  }

  void _applyDatabase() {
    final issues = DatabaseEditorCodec.validateDatabase(
      teams: _teams,
      riders: _riders,
    );
    final errors = issues.where((i) => i.isError).toList();
    if (errors.isNotEmpty) {
      setState(() {
        _statusBanner =
            'Nie można zapisać: wykryto ${errors.length} błędów krytycznych (np. ${errors.first.message}).';
      });
      return;
    }

    widget.onApplyDatabase?.call(
      List<CyclingTeam>.unmodifiable(_teams),
      List<Rider>.unmodifiable(_riders),
    );
    _pulseController.forward(from: 0.0);
    setState(() {
      _hasUnsavedChanges = false;
      _statusBanner =
          'Zastosowano bazę danych (${_teams.length} drużyn, ${_riders.length} kolarzy).';
    });
  }

  Future<void> _openJsonModal() async {
    final exported = DatabaseEditorCodec.exportToJson(
      teams: _teams,
      riders: _riders,
    );
    final importController = TextEditingController();
    String? modalError;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.cardBorder),
          ),
          title: const Row(
            children: [
              Icon(Icons.data_object_rounded, color: AppColors.goldAccent),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Eksport / Import JSON Bazy Danych',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Eksport obejmuje ${_teams.length} drużyn i ${_riders.length} kolarzy w formacie zgodnym z modami PPM.',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.surfaceLight,
                          foregroundColor: AppColors.goldAccent,
                          side: const BorderSide(color: AppColors.cardBorder),
                        ),
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: exported));
                          if (ctx.mounted) {
                            setModalState(() {
                              modalError = null;
                            });
                          }
                          if (mounted) {
                            setState(() {
                              _statusBanner = 'Skopiowano bazę JSON do schowka.';
                            });
                          }
                        },
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text('Kopiuj JSON do schowka'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Wklej JSON do zaimportowania:',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: importController,
                    maxLines: 7,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.textPrimary,
                      fontSize: 12,
                    ),
                    decoration: InputDecoration(
                      hintText: '{"teams": [...], "riders": [...]}',
                      hintStyle: const TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.cardBorder),
                      ),
                    ),
                  ),
                  if (modalError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      modalError!,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.crimsonAlert,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Zamknij'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryAccent,
                foregroundColor: AppColors.textPrimary,
              ),
              onPressed: () {
                try {
                  final imported = DatabaseEditorCodec.importFromJson(
                    importController.text,
                  );
                  _pushUndoSnapshot(
                    'Import JSON',
                    'Zaimportowano ${imported.teams.length} drużyn i ${imported.riders.length} kolarzy',
                  );
                  setState(() {
                    _teams = imported.teams;
                    _riders = imported.riders;
                    _selectedTeamId = _teams.isNotEmpty ? _teams.first.id : null;
                    final nextRoster = _filteredRoster;
                    _selectedRiderId =
                        nextRoster.isNotEmpty ? nextRoster.first.id : null;
                    _statusBanner =
                        'Zaimportowano ${imported.teams.length} drużyn i ${imported.riders.length} kolarzy.';
                  });
                  Navigator.of(ctx).pop();
                } catch (e) {
                  setModalState(() {
                    modalError = 'Błąd parsowania JSON: $e';
                  });
                }
              },
              icon: const Icon(Icons.file_download_done_rounded, size: 16),
              label: const Text('Importuj i Zastąp'),
            ),
          ],
        ),
      ),
    );
    importController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final issues = DatabaseEditorCodec.validateDatabase(
      teams: _teams,
      riders: _riders,
    );
    final errorCount = issues.where((i) => i.isError).length;
    final warningCount = issues.length - errorCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isDesktop = width >= 1200;
            final isTablet = width >= 720 && width < 1200;

            return Column(
              children: [
                _buildTopToolbar(
                  isCompact: !isDesktop,
                  errorCount: errorCount,
                  warningCount: warningCount,
                ),
                if (_statusBanner != null) _buildStatusStrip(_statusBanner!),
                if (!isDesktop && !isTablet) _buildMobileTabBar(),
                Expanded(
                  child: isDesktop
                      ? _buildDesktopLayout()
                      : isTablet
                          ? _buildTabletLayout()
                          : _buildMobileLayout(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopToolbar({
    required bool isCompact,
    required int errorCount,
    required int warningCount,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 20,
        vertical: 10,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          if (widget.onBack != null || Navigator.of(context).canPop())
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _EditorIconButton(
                icon: Icons.arrow_back_rounded,
                tooltip: 'Powrót',
                onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
              ),
            ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryAccent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primaryAccent.withValues(alpha: 0.6),
              ),
            ),
            child: const Icon(
              Icons.storage_rounded,
              color: AppColors.goldAccent,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Edytor Bazy Danych i Składów',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textPrimary,
                    fontSize: isCompact ? 14 : 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  '${_teams.length} drużyn • ${_riders.length} kolarzy${_hasUnsavedChanges ? ' • Niezapisane zmiany' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          if (!isCompact) ...[
            _ValidationPill(errorCount: errorCount, warningCount: warningCount),
            const SizedBox(width: 8),
          ],
          _EditorIconButton(
            icon: Icons.undo_rounded,
            tooltip: 'Cofnij (${_undoStack.length})',
            compact: isCompact,
            onPressed: _undoStack.isEmpty ? null : _undo,
          ),
          SizedBox(width: isCompact ? 4 : 6),
          _EditorIconButton(
            icon: Icons.redo_rounded,
            tooltip: 'Ponów (${_redoStack.length})',
            compact: isCompact,
            onPressed: _redoStack.isEmpty ? null : _redo,
          ),
          SizedBox(width: isCompact ? 4 : 6),
          _EditorIconButton(
            icon: Icons.data_object_rounded,
            tooltip: 'Eksport / Import JSON',
            compact: isCompact,
            onPressed: _openJsonModal,
          ),
          SizedBox(width: isCompact ? 6 : 8),
          _PrimaryActionButton(
            label: isCompact ? 'Zapisz' : 'Zastosuj Zmiany',
            icon: Icons.check_circle_outline_rounded,
            compact: isCompact,
            onPressed: _applyDatabase,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusStrip(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: AppColors.surfaceLight,
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.accentBlue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: AppColors.textPrimary,
                fontSize: 12,
              ),
            ),
          ),
          InkWell(
            onTap: () => setState(() => _statusBanner = null),
            child: const Icon(Icons.close_rounded, size: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: DatabaseEditorTab.values.map((tab) {
          final selected = _mobileTab == tab;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _SelectableChipButton(
                label: tab.label,
                icon: tab.icon,
                selected: selected,
                onTap: () => setState(() => _mobileTab = tab),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: 300, child: _buildTeamsExplorerCard()),
          const SizedBox(width: 14),
          Expanded(flex: 5, child: _buildRosterCenterCard()),
          const SizedBox(width: 14),
          SizedBox(width: 410, child: _buildInspectorCard()),
        ],
      ),
    );
  }

  Widget _buildTabletLayout() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: Column(
              children: [
                SizedBox(height: 250, child: _buildTeamsExplorerCard()),
                const SizedBox(height: 12),
                Expanded(child: _buildRosterCenterCard()),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(flex: 6, child: _buildInspectorCard()),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        child: switch (_mobileTab) {
          DatabaseEditorTab.teams => _buildTeamsExplorerCard(key: const ValueKey('m_teams')),
          DatabaseEditorTab.roster => _buildRosterCenterCard(key: const ValueKey('m_roster')),
          DatabaseEditorTab.inspector => _buildInspectorCard(key: const ValueKey('m_inspector')),
        },
      ),
    );
  }

  Widget _buildTeamsExplorerCard({Key? key}) {
    final teams = _filteredTeams;
    return _EditorCard(
      key: key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Drużyny w Bazie',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _CompactActionButton(
                  label: '+ Drużyna',
                  onPressed: _createNewTeam,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: TextField(
              controller: _teamSearchController,
              onChanged: (v) => setState(() => _teamSearchQuery = v),
              style: const TextStyle(
                fontFamily: 'Inter',
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
              decoration: InputDecoration(
                hintText: 'Szukaj drużyny lub kraju...',
                hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textSecondary),
                isDense: true,
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
              ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                _FilterPill(
                  label: 'Wszystkie',
                  selected: _divisionFilter == null && !_showFreeAgentsOnly,
                  onTap: () => setState(() {
                    _divisionFilter = null;
                    _showFreeAgentsOnly = false;
                  }),
                ),
                const SizedBox(width: 6),
                _FilterPill(
                  label: 'WorldTour',
                  selected: _divisionFilter == TeamDivision.worldTour && !_showFreeAgentsOnly,
                  onTap: () => setState(() {
                    _divisionFilter = TeamDivision.worldTour;
                    _showFreeAgentsOnly = false;
                  }),
                ),
                const SizedBox(width: 6),
                _FilterPill(
                  label: 'ProTeam',
                  selected: _divisionFilter == TeamDivision.proTeam && !_showFreeAgentsOnly,
                  onTap: () => setState(() {
                    _divisionFilter = TeamDivision.proTeam;
                    _showFreeAgentsOnly = false;
                  }),
                ),
                const SizedBox(width: 6),
                _FilterPill(
                  label: 'Continental',
                  selected: _divisionFilter == TeamDivision.continental && !_showFreeAgentsOnly,
                  onTap: () => setState(() {
                    _divisionFilter = TeamDivision.continental;
                    _showFreeAgentsOnly = false;
                  }),
                ),
                const SizedBox(width: 6),
                _FilterPill(
                  label: 'Wolni Agenci',
                  selected: _showFreeAgentsOnly,
                  onTap: () => setState(() {
                    _showFreeAgentsOnly = true;
                    _mobileTab = DatabaseEditorTab.roster;
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.cardBorder),
          Expanded(
            child: teams.isEmpty
                ? const Center(
                    child: Text(
                      'Brak drużyn spełniających kryteria.',
                      style: TextStyle(fontFamily: 'Inter', color: AppColors.textSecondary),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: teams.length,
                    itemBuilder: (context, index) {
                      final team = teams[index];
                      final isSelected = !_showFreeAgentsOnly && team.id == _selectedTeamId;
                      final rosterCount = _ridersForTeam(team.id).length;
                      final primary = DatabaseEditorCodec.parseHexColor(team.primaryJerseyColorHex);
                      final secondary = DatabaseEditorCodec.parseHexColor(team.secondaryJerseyColorHex);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: _InteractiveListTile(
                          selected: isSelected,
                          onTap: () {
                            setState(() {
                              _showFreeAgentsOnly = false;
                              _selectedTeamId = team.id;
                              _entityMode = DatabaseEditorEntityMode.team;
                              final teamRoster = _ridersForTeam(team.id);
                              if (teamRoster.isNotEmpty) {
                                _selectedRiderId = teamRoster.first.id;
                              }
                              _mobileTab = DatabaseEditorTab.roster;
                            });
                          },
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 34,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [primary, secondary],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      team.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        color: AppColors.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${team.countryIso} • ${team.division.label}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.cardBorder),
                                ),
                                child: Text(
                                  '$rosterCount',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    color: AppColors.goldAccent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    fontFeatures: [FontFeature.tabularFigures()],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRosterCenterCard({Key? key}) {
    final team = _selectedTeam;
    final roster = _filteredRoster;

    return _EditorCard(
      key: key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                if (!_showFreeAgentsOnly && team != null) ...[
                  CustomPaint(
                    size: const Size(34, 34),
                    painter: _MiniJerseyPainter(
                      primary: DatabaseEditorCodec.parseHexColor(team.primaryJerseyColorHex),
                      secondary: DatabaseEditorCodec.parseHexColor(team.secondaryJerseyColorHex),
                      accent: DatabaseEditorCodec.parseHexColor(team.accentJerseyColorHex),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _showFreeAgentsOnly
                            ? 'Wolni Agenci i Nieprzypisani'
                            : (team?.name ?? 'Wybierz drużynę'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _showFreeAgentsOnly
                            ? '${roster.length} zawodników dostępnych do przypisania'
                            : team != null
                                ? '${team.division.label} • Budżet €${(team.cashBalanceEur / 1000000).toStringAsFixed(2)}M • ${roster.length} kolarzy'
                                : 'Brak wybranej drużyny',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_showFreeAgentsOnly && team != null) ...[
                  _CompactActionButton(
                    label: 'Drużyna',
                    onPressed: () {
                      setState(() {
                        _entityMode = DatabaseEditorEntityMode.team;
                        _mobileTab = DatabaseEditorTab.inspector;
                      });
                    },
                  ),
                  const SizedBox(width: 6),
                ],
                _CompactActionButton(
                  label: '+ Kolarz',
                  isAccent: true,
                  onPressed: () => _createNewRider(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 210,
                  child: TextField(
                    controller: _rosterSearchController,
                    onChanged: (v) => setState(() => _rosterSearchQuery = v),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.textPrimary,
                      fontSize: 12,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Filtruj kolarza...',
                      hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      prefixIcon: const Icon(Icons.search_rounded, size: 16, color: AppColors.textSecondary),
                      isDense: true,
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
                    ),
                  ),
                ),
                DropdownButtonHideUnderline(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: DropdownButton<DatabaseEditorSortField>(
                      value: _sortField,
                      dropdownColor: AppColors.surfaceLight,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.textPrimary,
                        fontSize: 12,
                      ),
                      items: DatabaseEditorSortField.values
                          .map((f) => DropdownMenuItem(
                                value: f,
                                child: Text('Sort: ${f.label}'),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _sortField = v);
                      },
                    ),
                  ),
                ),
                _EditorIconButton(
                  icon: _sortAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                  tooltip: _sortAscending ? 'Rosnąco' : 'Malejąco',
                  onPressed: () => setState(() => _sortAscending = !_sortAscending),
                ),
                DropdownButtonHideUnderline(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: DropdownButton<RiderSpecialization?>(
                      value: _specFilter,
                      dropdownColor: AppColors.surfaceLight,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.textPrimary,
                        fontSize: 12,
                      ),
                      items: [
                        const DropdownMenuItem<RiderSpecialization?>(
                          value: null,
                          child: Text('Wszystkie spec.'),
                        ),
                        ...RiderSpecialization.values.map(
                          (s) => DropdownMenuItem<RiderSpecialization?>(
                            value: s,
                            child: Text(s.displayName),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _specFilter = v),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.cardBorder),
          Expanded(
            child: roster.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_off_outlined, size: 36, color: AppColors.textSecondary),
                        const SizedBox(height: 8),
                        const Text(
                          'Brak kolarzy w tym widoku.',
                          style: TextStyle(fontFamily: 'Inter', color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 10),
                        _CompactActionButton(
                          label: '+ Dodaj pierwszego kolarza',
                          isAccent: true,
                          onPressed: () => _createNewRider(),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: roster.length,
                    itemBuilder: (context, index) {
                      final rider = roster[index];
                      final isSelected =
                          _entityMode == DatabaseEditorEntityMode.rider &&
                          rider.id == _selectedRiderId;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: _InteractiveListTile(
                          selected: isSelected,
                          onTap: () {
                            setState(() {
                              _selectedRiderId = rider.id;
                              _entityMode = DatabaseEditorEntityMode.rider;
                              _mobileTab = DatabaseEditorTab.inspector;
                            });
                          },
                          child: Row(
                            children: [
                              _OvrBadge(ovr: rider.overallRating),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      rider.fullName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        color: AppColors.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${rider.nationalityIso} • ${rider.age} lat • ${rider.specialization.displayName}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                        fontFeatures: [FontFeature.tabularFigures()],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${rider.physiology.ftpWatts} W',
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      color: AppColors.accentBlue,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      fontFeatures: [FontFeature.tabularFigures()],
                                    ),
                                  ),
                                  Text(
                                    '${rider.physiology.wattsPerKg.toStringAsFixed(2)} W/kg',
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                      fontFeatures: [FontFeature.tabularFigures()],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInspectorCard({Key? key}) {
    return _EditorCard(
      key: key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Expanded(
                  child: _SelectableChipButton(
                    label: 'Edytor Kolarza',
                    icon: Icons.directions_bike_rounded,
                    selected: _entityMode == DatabaseEditorEntityMode.rider,
                    onTap: () => setState(() => _entityMode = DatabaseEditorEntityMode.rider),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SelectableChipButton(
                    label: 'Edytor Drużyny',
                    icon: Icons.shield_rounded,
                    selected: _entityMode == DatabaseEditorEntityMode.team,
                    onTap: () => setState(() => _entityMode = DatabaseEditorEntityMode.team),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.cardBorder),
          Expanded(
            child: _entityMode == DatabaseEditorEntityMode.team
                ? _buildTeamInspector()
                : _buildRiderInspector(),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamInspector() {
    final team = _selectedTeam;
    if (team == null) {
      return const Center(
        child: Text(
          'Wybierz drużynę z listy, aby edytować jej parametry.',
          style: TextStyle(fontFamily: 'Inter', color: AppColors.textSecondary),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomPaint(
                size: const Size(52, 52),
                painter: _MiniJerseyPainter(
                  primary: DatabaseEditorCodec.parseHexColor(team.primaryJerseyColorHex),
                  secondary: DatabaseEditorCodec.parseHexColor(team.secondaryJerseyColorHex),
                  accent: DatabaseEditorCodec.parseHexColor(team.accentJerseyColorHex),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team.name,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${team.division.label} • ${_ridersForTeam(team.id).length} kolarzy',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InlineTextEditor(
            key: ValueKey('team_name_${team.id}'),
            label: 'Nazwa Drużyny',
            initialValue: team.name,
            onSubmitted: (val) {
              if (val.trim().isNotEmpty) {
                _updateTeam(team.copyWith(name: val.trim()), 'Zmieniono nazwę drużyny na ${val.trim()}');
              }
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _InlineTextEditor(
                  key: ValueKey('team_iso_${team.id}'),
                  label: 'Kod Kraju (ISO)',
                  initialValue: team.countryIso,
                  onSubmitted: (val) {
                    final iso = val.trim().toUpperCase();
                    if (iso.isNotEmpty) {
                      _updateTeam(team.copyWith(countryIso: iso), 'Zmieniono kraj ${team.name} na $iso');
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dywizja UCI',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<TeamDivision>(
                      initialValue: team.division,
                      dropdownColor: AppColors.surfaceLight,
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.cardBorder),
                        ),
                      ),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.textPrimary,
                        fontSize: 12,
                      ),
                      items: TeamDivision.values
                          .map((d) => DropdownMenuItem(value: d, child: Text(d.label)))
                          .toList(),
                      onChanged: (d) {
                        if (d != null) {
                          _updateTeam(team.copyWith(division: d), 'Zmieniono dywizję ${team.name}');
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _IntSliderTile(
            label: 'Budżet Drużyny (€)',
            value: team.cashBalanceEur.clamp(200000, 40000000),
            min: 200000,
            max: 40000000,
            divisions: 199,
            valueLabel: '€${(team.cashBalanceEur / 1000000).toStringAsFixed(2)}M',
            onChanged: (v) => _updateTeam(
              team.copyWith(cashBalanceEur: v),
              'Zmieniono budżet ${team.name}',
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Kolory Stroju Drużyny (HEX)',
            style: TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _InlineTextEditor(
                  key: ValueKey('team_c1_${team.id}_${team.primaryJerseyColorHex}'),
                  label: 'Główny',
                  initialValue: team.primaryJerseyColorHex,
                  onSubmitted: (val) => _updateTeam(
                    team.copyWith(primaryJerseyColorHex: val.trim()),
                    'Zmieniono główny kolor stroju',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InlineTextEditor(
                  key: ValueKey('team_c2_${team.id}_${team.secondaryJerseyColorHex}'),
                  label: 'Drugi',
                  initialValue: team.secondaryJerseyColorHex,
                  onSubmitted: (val) => _updateTeam(
                    team.copyWith(secondaryJerseyColorHex: val.trim()),
                    'Zmieniono drugi kolor stroju',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InlineTextEditor(
                  key: ValueKey('team_c3_${team.id}_${team.accentJerseyColorHex}'),
                  label: 'Akcent',
                  initialValue: team.accentJerseyColorHex,
                  onSubmitted: (val) => _updateTeam(
                    team.copyWith(accentJerseyColorHex: val.trim()),
                    'Zmieniono kolor akcentu stroju',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Poziom Sztabu Technicznego (1–100)',
            style: TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _IntSliderTile(
            label: 'Dyrektorzy Sportowi',
            value: team.staff.sportsDirectorsLevel.clamp(1, 100),
            min: 1,
            max: 100,
            onChanged: (v) => _updateTeam(
              team.copyWith(staff: team.staff.copyWith(sportsDirectorsLevel: v)),
              'Zmieniono poziom DS (${team.name})',
            ),
          ),
          _IntSliderTile(
            label: 'Trenerzy Fizyczni',
            value: team.staff.trainersLevel.clamp(1, 100),
            min: 1,
            max: 100,
            onChanged: (v) => _updateTeam(
              team.copyWith(staff: team.staff.copyWith(trainersLevel: v)),
              'Zmieniono poziom trenerów (${team.name})',
            ),
          ),
          _IntSliderTile(
            label: 'Mechanicy Sprzętowi',
            value: team.staff.mechanicsLevel.clamp(1, 100),
            min: 1,
            max: 100,
            onChanged: (v) => _updateTeam(
              team.copyWith(staff: team.staff.copyWith(mechanicsLevel: v)),
              'Zmieniono poziom mechaników (${team.name})',
            ),
          ),
          _IntSliderTile(
            label: 'Lekarze i Fizjo',
            value: team.staff.doctorsLevel.clamp(1, 100),
            min: 1,
            max: 100,
            onChanged: (v) => _updateTeam(
              team.copyWith(staff: team.staff.copyWith(doctorsLevel: v)),
              'Zmieniono poziom lekarzy (${team.name})',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiderInspector() {
    final rider = _selectedRider;
    if (rider == null) {
      return const Center(
        child: Text(
          'Wybierz kolarza z listy, aby otworzyć edytor.',
          style: TextStyle(fontFamily: 'Inter', color: AppColors.textSecondary),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              _OvrBadge(ovr: rider.overallRating, large: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rider.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${rider.physiology.ftpWatts} W • ${rider.physiology.wattsPerKg.toStringAsFixed(2)} W/kg • POT ${rider.potential}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.goldAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              _EditorIconButton(
                icon: Icons.copy_all_rounded,
                tooltip: 'Duplikuj kolarza',
                onPressed: () => _createNewRider(cloneFrom: rider),
              ),
              const SizedBox(width: 6),
              _EditorIconButton(
                icon: Icons.delete_outline_rounded,
                tooltip: 'Usuń kolarza',
                iconColor: AppColors.crimsonAlert,
                onPressed: () => _confirmDeleteRider(rider),
              ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: RiderEditorSection.values.map((section) {
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _FilterPill(
                  label: section.label,
                  selected: _riderSection == section,
                  onTap: () => setState(() => _riderSection = section),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1, color: AppColors.cardBorder),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: switch (_riderSection) {
              RiderEditorSection.identity => _buildRiderIdentitySection(rider),
              RiderEditorSection.physiology => _buildRiderPhysiologySection(rider),
              RiderEditorSection.power => _buildRiderPowerSection(rider),
              RiderEditorSection.skills => _buildRiderSkillsSection(rider),
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRiderIdentitySection(Rider rider) {
    final teamItems = <DropdownMenuItem<String>>[
      const DropdownMenuItem<String>(
        value: _freeAgentTeamId,
        child: Text('Wolny Agent (Bez klubu)'),
      ),
      ..._teams.map(
        (t) => DropdownMenuItem<String>(
          value: t.id,
          child: Text(t.name, overflow: TextOverflow.ellipsis),
        ),
      ),
    ];
    final currentTeamValue = _teams.any((t) => t.id == rider.contract.teamId)
        ? rider.contract.teamId
        : _freeAgentTeamId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _InlineTextEditor(
                key: ValueKey('r_fn_${rider.id}_${rider.firstName}'),
                label: 'Imię',
                initialValue: rider.firstName,
                onSubmitted: (v) {
                  if (v.trim().isNotEmpty) {
                    _updateRider(
                      rider.copyWith(firstName: v.trim()),
                      'Zmieniono imię kolarza na ${v.trim()}',
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _InlineTextEditor(
                key: ValueKey('r_ln_${rider.id}_${rider.lastName}'),
                label: 'Nazwisko',
                initialValue: rider.lastName,
                onSubmitted: (v) {
                  if (v.trim().isNotEmpty) {
                    _updateRider(
                      rider.copyWith(lastName: v.trim()),
                      'Zmieniono nazwisko kolarza na ${v.trim()}',
                    );
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _InlineTextEditor(
                key: ValueKey('r_nat_${rider.id}_${rider.nationalityIso}'),
                label: 'Narodowość (ISO)',
                initialValue: rider.nationalityIso,
                onSubmitted: (v) {
                  final iso = v.trim().toUpperCase();
                  if (iso.isNotEmpty) {
                    _updateRider(
                      rider.copyWith(nationalityIso: iso),
                      'Zmieniono narodowość ${rider.fullName} na $iso',
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Specjalizacja',
                    style: TextStyle(fontFamily: 'Inter', color: AppColors.textSecondary, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<RiderSpecialization>(
                    initialValue: rider.specialization,
                    isExpanded: true,
                    dropdownColor: AppColors.surfaceLight,
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.cardBorder),
                      ),
                    ),
                    style: const TextStyle(fontFamily: 'Inter', color: AppColors.textPrimary, fontSize: 12),
                    items: RiderSpecialization.values
                        .map((s) => DropdownMenuItem(value: s, child: Text(s.displayName)))
                        .toList(),
                    onChanged: (s) {
                      if (s != null) {
                        _updateRider(
                          rider.copyWith(specialization: s),
                          'Zmieniono specjalizację ${rider.fullName}',
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Przynależność Klubowa (Transfer)',
          style: TextStyle(fontFamily: 'Inter', color: AppColors.textSecondary, fontSize: 11),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: currentTeamValue,
          isExpanded: true,
          dropdownColor: AppColors.surfaceLight,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
          ),
          style: const TextStyle(fontFamily: 'Inter', color: AppColors.textPrimary, fontSize: 12),
          items: teamItems,
          onChanged: (targetId) {
            if (targetId != null) {
              _transferRiderToTeam(rider, targetId);
            }
          },
        ),
        const SizedBox(height: 12),
        const Text(
          'Rola w Zespole',
          style: TextStyle(fontFamily: 'Inter', color: AppColors.textSecondary, fontSize: 11),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<RiderRole>(
          initialValue: rider.contract.role,
          isExpanded: true,
          dropdownColor: AppColors.surfaceLight,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
          ),
          style: const TextStyle(fontFamily: 'Inter', color: AppColors.textPrimary, fontSize: 12),
          items: RiderRole.values
              .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
              .toList(),
          onChanged: (role) {
            if (role != null) {
              _updateRider(
                rider.copyWith(contract: rider.contract.copyWith(role: role)),
                'Zmieniono rolę ${rider.fullName} na ${role.label}',
              );
            }
          },
        ),
        const SizedBox(height: 12),
        _IntSliderTile(
          label: 'Wiek (lata)',
          value: rider.age.clamp(18, 42),
          min: 18,
          max: 42,
          onChanged: (v) => _updateRider(
            rider.copyWith(age: v),
            'Zmieniono wiek ${rider.fullName} na $v lat',
          ),
        ),
        _IntSliderTile(
          label: 'Potencjał Rozwoju',
          value: rider.potential.clamp(40, 99),
          min: 40,
          max: 99,
          onChanged: (v) => _updateRider(
            rider.copyWith(potential: v),
            'Zmieniono potencjał ${rider.fullName} na $v',
          ),
        ),
        _IntSliderTile(
          label: 'Pensja Miesięczna (€)',
          value: rider.contract.monthlySalaryEur.clamp(2000, 350000),
          min: 2000,
          max: 350000,
          divisions: 174,
          valueLabel: '€${rider.contract.monthlySalaryEur}',
          onChanged: (v) => _updateRider(
            rider.copyWith(contract: rider.contract.copyWith(monthlySalaryEur: v)),
            'Zmieniono pensję ${rider.fullName}',
          ),
        ),
      ],
    );
  }

  Widget _buildRiderPhysiologySection(Rider rider) {
    final phys = rider.physiology;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _IntSliderTile(
          label: 'FTP (Moc Progowa)',
          value: phys.ftpWatts.clamp(220, 500),
          min: 220,
          max: 500,
          valueLabel: '${phys.ftpWatts} W',
          onChanged: (v) => _updateRider(
            rider.copyWith(physiology: phys.copyWith(ftpWatts: v)),
            'Zmieniono FTP ${rider.fullName} na $v W',
          ),
        ),
        _DoubleSliderTile(
          label: 'Masa Ciała',
          value: phys.weightKg.clamp(48.0, 95.0),
          min: 48.0,
          max: 95.0,
          valueLabel: '${phys.weightKg.toStringAsFixed(1)} kg',
          onChanged: (v) => _updateRider(
            rider.copyWith(physiology: phys.copyWith(weightKg: v)),
            'Zmieniono wagę ${rider.fullName} na ${v.toStringAsFixed(1)} kg',
          ),
        ),
        _DoubleSliderTile(
          label: 'Wzrost',
          value: phys.heightCm.clamp(158.0, 202.0),
          min: 158.0,
          max: 202.0,
          valueLabel: '${phys.heightCm.toStringAsFixed(0)} cm',
          onChanged: (v) => _updateRider(
            rider.copyWith(physiology: phys.copyWith(heightCm: v)),
            'Zmieniono wzrost ${rider.fullName}',
          ),
        ),
        _DoubleSliderTile(
          label: 'VO₂max',
          value: phys.vo2Max.clamp(60.0, 96.0),
          min: 60.0,
          max: 96.0,
          valueLabel: '${phys.vo2Max.toStringAsFixed(1)} ml/kg',
          onChanged: (v) => _updateRider(
            rider.copyWith(physiology: phys.copyWith(vo2Max: v)),
            'Zmieniono VO₂max ${rider.fullName}',
          ),
        ),
        _IntSliderTile(
          label: 'Rezerwa Beztlenowa W\'',
          value: phys.wPrimeJoules.clamp(10000, 35000),
          min: 10000,
          max: 35000,
          divisions: 50,
          valueLabel: '${(phys.wPrimeJoules / 1000).toStringAsFixed(1)} kJ',
          onChanged: (v) => _updateRider(
            rider.copyWith(physiology: phys.copyWith(wPrimeJoules: v)),
            'Zmieniono W\' ${rider.fullName}',
          ),
        ),
        _DoubleSliderTile(
          label: 'Regeneracja Nocna',
          value: phys.recoveryRate.clamp(0.75, 1.35),
          min: 0.75,
          max: 1.35,
          valueLabel: '${phys.recoveryRate.toStringAsFixed(2)}x',
          onChanged: (v) => _updateRider(
            rider.copyWith(physiology: phys.copyWith(recoveryRate: v)),
            'Zmieniono regenerację ${rider.fullName}',
          ),
        ),
      ],
    );
  }

  Widget _buildRiderPowerSection(Rider rider) {
    final p = rider.powerProfile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 110,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: CustomPaint(
            size: Size.infinite,
            painter: _PowerCurveSparklinePainter(profile: p),
          ),
        ),
        const SizedBox(height: 14),
        _IntSliderTile(
          label: 'Sprint 5s',
          value: p.watts5s.clamp(700, 1900),
          min: 700,
          max: 1900,
          valueLabel: '${p.watts5s} W',
          onChanged: (v) => _updateRider(
            rider.copyWith(powerProfile: p.copyWith(watts5s: v)),
            'Zmieniono moc 5s (${rider.fullName})',
          ),
        ),
        _IntSliderTile(
          label: 'Atak 1m',
          value: p.watts1m.clamp(400, 950),
          min: 400,
          max: 950,
          valueLabel: '${p.watts1m} W',
          onChanged: (v) => _updateRider(
            rider.copyWith(powerProfile: p.copyWith(watts1m: v)),
            'Zmieniono moc 1m (${rider.fullName})',
          ),
        ),
        _IntSliderTile(
          label: 'VO₂ 5m',
          value: p.watts5m.clamp(300, 620),
          min: 300,
          max: 620,
          valueLabel: '${p.watts5m} W',
          onChanged: (v) => _updateRider(
            rider.copyWith(powerProfile: p.copyWith(watts5m: v)),
            'Zmieniono moc 5m (${rider.fullName})',
          ),
        ),
        _IntSliderTile(
          label: 'Próg 20m',
          value: p.watts20m.clamp(250, 520),
          min: 250,
          max: 520,
          valueLabel: '${p.watts20m} W',
          onChanged: (v) => _updateRider(
            rider.copyWith(powerProfile: p.copyWith(watts20m: v)),
            'Zmieniono moc 20m (${rider.fullName})',
          ),
        ),
        _IntSliderTile(
          label: 'Godzina 60m',
          value: p.watts60m.clamp(220, 480),
          min: 220,
          max: 480,
          valueLabel: '${p.watts60m} W',
          onChanged: (v) => _updateRider(
            rider.copyWith(powerProfile: p.copyWith(watts60m: v)),
            'Zmieniono moc 60m (${rider.fullName})',
          ),
        ),
      ],
    );
  }

  Widget _buildRiderSkillsSection(Rider rider) {
    final s = rider.skills;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _IntSliderTile(
          label: 'Bruk (Cobbles)',
          value: s.cobbles.clamp(1, 99),
          min: 1,
          max: 99,
          onChanged: (v) => _updateRider(
            rider.copyWith(skills: s.copyWith(cobbles: v)),
            'Zmieniono bruk (${rider.fullName})',
          ),
        ),
        _IntSliderTile(
          label: 'Zjazdy (Descending)',
          value: s.descending.clamp(1, 99),
          min: 1,
          max: 99,
          onChanged: (v) => _updateRider(
            rider.copyWith(skills: s.copyWith(descending: v)),
            'Zmieniono zjazdy (${rider.fullName})',
          ),
        ),
        _IntSliderTile(
          label: 'Technika (Handling)',
          value: s.bikeHandling.clamp(1, 99),
          min: 1,
          max: 99,
          onChanged: (v) => _updateRider(
            rider.copyWith(skills: s.copyWith(bikeHandling: v)),
            'Zmieniono technikę (${rider.fullName})',
          ),
        ),
        _IntSliderTile(
          label: 'Pozycja Aero',
          value: s.aeroPositioning.clamp(1, 99),
          min: 1,
          max: 99,
          onChanged: (v) => _updateRider(
            rider.copyWith(skills: s.copyWith(aeroPositioning: v)),
            'Zmieniono aero (${rider.fullName})',
          ),
        ),
        _IntSliderTile(
          label: 'Jazda na Kole (Drafting)',
          value: s.draftingEfficiency.clamp(1, 99),
          min: 1,
          max: 99,
          onChanged: (v) => _updateRider(
            rider.copyWith(skills: s.copyWith(draftingEfficiency: v)),
            'Zmieniono drafting (${rider.fullName})',
          ),
        ),
        _IntSliderTile(
          label: 'Taktyka (Race IQ)',
          value: s.raceIq.clamp(1, 99),
          min: 1,
          max: 99,
          onChanged: (v) => _updateRider(
            rider.copyWith(skills: s.copyWith(raceIq: v)),
            'Zmieniono Race IQ (${rider.fullName})',
          ),
        ),
        _IntSliderTile(
          label: 'Jazda na Czas (TT)',
          value: s.timeTrialPositioning.clamp(1, 99),
          min: 1,
          max: 99,
          onChanged: (v) => _updateRider(
            rider.copyWith(skills: s.copyWith(timeTrialPositioning: v)),
            'Zmieniono TT (${rider.fullName})',
          ),
        ),
        _IntSliderTile(
          label: 'Odporność na Deszcz',
          value: s.rainResistance.clamp(1, 99),
          min: 1,
          max: 99,
          onChanged: (v) => _updateRider(
            rider.copyWith(skills: s.copyWith(rainResistance: v)),
            'Zmieniono odporność na deszcz (${rider.fullName})',
          ),
        ),
        _IntSliderTile(
          label: 'Tolerancja Upału',
          value: s.heatTolerance.clamp(1, 99),
          min: 1,
          max: 99,
          onChanged: (v) => _updateRider(
            rider.copyWith(skills: s.copyWith(heatTolerance: v)),
            'Zmieniono tolerancję upału (${rider.fullName})',
          ),
        ),
      ],
    );
  }
}

class _EditorCard extends StatelessWidget {
  const _EditorCard({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _InteractiveListTile extends StatefulWidget {
  const _InteractiveListTile({
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  State<_InteractiveListTile> createState() => _InteractiveListTileState();
}

class _InteractiveListTileState extends State<_InteractiveListTile> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.selected
        ? AppColors.primaryAccent.withValues(alpha: 0.22)
        : _hovered
            ? AppColors.surfaceLight
            : AppColors.background.withValues(alpha: 0.55);
    final borderColor = widget.selected
        ? AppColors.goldAccent
        : _focused
            ? AppColors.accentBlue
            : _hovered
                ? AppColors.cardBorder
                : Colors.transparent;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectableChipButton extends StatefulWidget {
  const _SelectableChipButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_SelectableChipButton> createState() => _SelectableChipButtonState();
}

class _SelectableChipButtonState extends State<_SelectableChipButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: widget.selected
              ? AppColors.primaryAccent
              : _hovered
                  ? AppColors.surfaceLight
                  : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: widget.selected ? AppColors.goldAccent : AppColors.cardBorder,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  size: 15,
                  color: widget.selected ? AppColors.goldAccent : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: widget.selected ? AppColors.textPrimary : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
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

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryAccent.withValues(alpha: 0.35) : AppColors.background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.goldAccent : AppColors.cardBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              color: selected ? AppColors.textPrimary : AppColors.textSecondary,
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _EditorIconButton extends StatelessWidget {
  const _EditorIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.iconColor,
    this.compact = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? iconColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    final size = compact ? 32.0 : 36.0;
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: compact ? 16 : 18,
          color: disabled
              ? AppColors.textSecondary.withValues(alpha: 0.35)
              : (iconColor ?? AppColors.textPrimary),
        ),
        style: IconButton.styleFrom(
          backgroundColor: AppColors.background,
          disabledBackgroundColor: AppColors.background.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: AppColors.cardBorder),
          ),
          padding: EdgeInsets.all(compact ? 6 : 8),
          minimumSize: Size(size, size),
          maximumSize: Size(size, size),
        ),
      ),
    );
  }
}

class _CompactActionButton extends StatelessWidget {
  const _CompactActionButton({
    required this.label,
    required this.onPressed,
    this.isAccent = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isAccent;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: isAccent ? AppColors.primaryAccent : AppColors.surfaceLight,
        foregroundColor: AppColors.textPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        minimumSize: const Size(0, 32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isAccent ? AppColors.goldAccent.withValues(alpha: 0.7) : AppColors.cardBorder,
          ),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.goldAccent,
        foregroundColor: AppColors.background,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 14,
          vertical: compact ? 8 : 10,
        ),
        minimumSize: Size(0, compact ? 32 : 36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: Icon(icon, size: compact ? 14 : 16),
      label: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ValidationPill extends StatelessWidget {
  const _ValidationPill({
    required this.errorCount,
    required this.warningCount,
  });

  final int errorCount;
  final int warningCount;

  @override
  Widget build(BuildContext context) {
    final hasError = errorCount > 0;
    final hasWarning = warningCount > 0;
    final color = hasError
        ? AppColors.crimsonAlert
        : hasWarning
            ? AppColors.amberWarning
            : AppColors.statusSuccess;
    final text = hasError
        ? '$errorCount błędów'
        : hasWarning
            ? '$warningCount ostrzeżeń'
            : 'Baza spójna';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasError
                ? Icons.error_outline_rounded
                : hasWarning
                    ? Icons.warning_amber_rounded
                    : Icons.verified_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Inter',
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _OvrBadge extends StatelessWidget {
  const _OvrBadge({required this.ovr, this.large = false});

  final int ovr;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final color = ovr >= 85
        ? AppColors.goldAccent
        : ovr >= 75
            ? AppColors.accentBlue
            : AppColors.textSecondary;

    return Container(
      width: large ? 42 : 34,
      height: large ? 42 : 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
      child: Text(
        '$ovr',
        style: TextStyle(
          fontFamily: 'Inter',
          color: color,
          fontSize: large ? 15 : 12,
          fontWeight: FontWeight.w800,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _InlineTextEditor extends StatefulWidget {
  const _InlineTextEditor({
    super.key,
    required this.label,
    required this.initialValue,
    required this.onSubmitted,
  });

  final String label;
  final String initialValue;
  final ValueChanged<String> onSubmitted;

  @override
  State<_InlineTextEditor> createState() => _InlineTextEditorState();
}

class _InlineTextEditorState extends State<_InlineTextEditor> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontFamily: 'Inter',
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _controller,
          onSubmitted: widget.onSubmitted,
          onEditingComplete: () => widget.onSubmitted(_controller.text),
          style: const TextStyle(
            fontFamily: 'Inter',
            color: AppColors.textPrimary,
            fontSize: 12,
          ),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: AppColors.background,
            suffixIcon: IconButton(
              icon: const Icon(Icons.check_rounded, size: 15, color: AppColors.goldAccent),
              onPressed: () => widget.onSubmitted(_controller.text),
              tooltip: 'Zastosuj',
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
          ),
        ),
      ],
    );
  }
}

class _IntSliderTile extends StatelessWidget {
  const _IntSliderTile({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
    this.valueLabel,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final int? divisions;
  final String? valueLabel;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
              Text(
                valueLabel ?? '$value',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.goldAccent,
              inactiveTrackColor: AppColors.surfaceLight,
              thumbColor: AppColors.textPrimary,
              overlayColor: AppColors.goldAccent.withValues(alpha: 0.2),
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: value.toDouble().clamp(min.toDouble(), max.toDouble()),
              min: min.toDouble(),
              max: max.toDouble(),
              divisions: divisions ?? (max - min),
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoubleSliderTile extends StatelessWidget {
  const _DoubleSliderTile({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.valueLabel,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String valueLabel;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
              Text(
                valueLabel,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.accentBlue,
              inactiveTrackColor: AppColors.surfaceLight,
              thumbColor: AppColors.textPrimary,
              overlayColor: AppColors.accentBlue.withValues(alpha: 0.2),
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: 100,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniJerseyPainter extends CustomPainter {
  const _MiniJerseyPainter({
    required this.primary,
    required this.secondary,
    required this.accent,
  });

  final Color primary;
  final Color secondary;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bodyPath = Path()
      ..moveTo(w * 0.28, h * 0.12)
      ..lineTo(w * 0.72, h * 0.12)
      ..lineTo(w * 0.94, h * 0.34)
      ..lineTo(w * 0.80, h * 0.48)
      ..lineTo(w * 0.72, h * 0.40)
      ..lineTo(w * 0.72, h * 0.90)
      ..lineTo(w * 0.28, h * 0.90)
      ..lineTo(w * 0.28, h * 0.40)
      ..lineTo(w * 0.20, h * 0.48)
      ..lineTo(w * 0.06, h * 0.34)
      ..close();

    canvas.drawPath(bodyPath, Paint()..color = primary);

    canvas.save();
    canvas.clipPath(bodyPath);
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.56, w, h * 0.36),
      Paint()..color = secondary,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.48, w, h * 0.08),
      Paint()..color = accent,
    );
    canvas.restore();

    canvas.drawPath(
      bodyPath,
      Paint()
        ..color = AppColors.cardBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniJerseyPainter oldDelegate) {
    return oldDelegate.primary != primary ||
        oldDelegate.secondary != secondary ||
        oldDelegate.accent != accent;
  }
}

class _PowerCurveSparklinePainter extends CustomPainter {
  const _PowerCurveSparklinePainter({required this.profile});
  final RiderPowerProfile profile;

  @override
  void paint(Canvas canvas, Size size) {
    final values = [
      profile.watts5s.toDouble(),
      profile.watts15s.toDouble(),
      profile.watts30s.toDouble(),
      profile.watts1m.toDouble(),
      profile.watts3m.toDouble(),
      profile.watts5m.toDouble(),
      profile.watts20m.toDouble(),
      profile.watts60m.toDouble(),
    ];
    final maxW = values.reduce(math.max).clamp(500.0, 2200.0);
    final minW = (values.reduce(math.min) * 0.85).clamp(100.0, maxW - 50.0);

    final points = <Offset>[];
    for (int i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final normY = (values[i] - minW) / (maxW - minW);
      final y = size.height - normY * (size.height - 12) - 6;
      points.add(Offset(x, y));
    }

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }

    final fillPath = Path.from(linePath)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.goldAccent.withValues(alpha: 0.32),
            AppColors.goldAccent.withValues(alpha: 0.02),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      linePath,
      Paint()
        ..color = AppColors.goldAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    for (final pt in points) {
      canvas.drawCircle(pt, 3.2, Paint()..color = AppColors.textPrimary);
      canvas.drawCircle(pt, 2.0, Paint()..color = AppColors.goldAccent);
    }
  }

  @override
  bool shouldRepaint(covariant _PowerCurveSparklinePainter oldDelegate) {
    return oldDelegate.profile != profile;
  }
}
