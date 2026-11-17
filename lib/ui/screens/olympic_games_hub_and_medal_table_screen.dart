import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/rider/rider.dart';
import '../../models/rider/rider_appearance.dart';
import '../../models/rider/rider_contract.dart';
import '../../models/rider/rider_health.dart';
import '../../models/rider/rider_physiology.dart';
import '../../models/rider/rider_power_profile.dart';
import '../../models/rider/rider_skills.dart';
import '../../services/career/olympic_games_quadrennial_cycle_service.dart';

/// Zakładka nawigacyjna w centrum Igrzysk Olimpijskich (szczególnie dla układów mobilnych/tabletowych).
enum OlympicHubTab {
  overviewAndCourse('Przegląd & Trasa', Icons.public_rounded),
  medalTable('Tabela Medalowa', Icons.emoji_events_rounded),
  nationalRosters('Składy Narodowe', Icons.groups_rounded),
  goldChampions('Złoci Mistrzowie', Icons.workspace_premium_rounded);

  final String labelPl;
  final IconData icon;

  const OlympicHubTab(this.labelPl, this.icon);
}

/// Kolumna sortowania tabeli medalowej państw.
enum OlympicMedalTableSortColumn {
  olympicRank('Klasyfikacja (Z-S-B)'),
  totalMedals('Łącznie medali'),
  countryName('Państwo'),
  uciQuota('Kwota RR');

  final String labelPl;
  const OlympicMedalTableSortColumn(this.labelPl);
}

/// Wiersz tabeli medalowej państw dla kolarstwa szosowego na Igrzyskach Olimpijskich.
class OlympicCountryMedalRow {
  final String countryIso;
  final String countryNamePl;
  final String flagCode;
  final int goldCount;
  final int silverCount;
  final int bronzeCount;
  final int roadRaceQuota;
  final int ittQuota;
  final int nationUciRank;
  final bool isPlayerNation;
  final List<String> notableMedalists;

  const OlympicCountryMedalRow({
    required this.countryIso,
    required this.countryNamePl,
    required this.flagCode,
    required this.goldCount,
    required this.silverCount,
    required this.bronzeCount,
    required this.roadRaceQuota,
    required this.ittQuota,
    required this.nationUciRank,
    this.isPlayerNation = false,
    this.notableMedalists = const [],
  });

  int get totalMedals => goldCount + silverCount + bronzeCount;

  int get olympicRankScore =>
      goldCount * 10000 + silverCount * 100 + bronzeCount;

  OlympicCountryMedalRow copyWith({
    int? goldCount,
    int? silverCount,
    int? bronzeCount,
    bool? isPlayerNation,
    List<String>? notableMedalists,
  }) {
    return OlympicCountryMedalRow(
      countryIso: countryIso,
      countryNamePl: countryNamePl,
      flagCode: flagCode,
      goldCount: goldCount ?? this.goldCount,
      silverCount: silverCount ?? this.silverCount,
      bronzeCount: bronzeCount ?? this.bronzeCount,
      roadRaceQuota: roadRaceQuota,
      ittQuota: ittQuota,
      nationUciRank: nationUciRank,
      isPlayerNation: isPlayerNation ?? this.isPlayerNation,
      notableMedalists: notableMedalists ?? this.notableMedalists,
    );
  }
}

/// Kalkulator i agregator tabeli medalowej państw na podstawie raportów symulacji olimpijskich.
class OlympicMedalTableAggregator {
  const OlympicMedalTableAggregator._();

  static const Map<String, ({String namePl, int uciRank})> _nationCatalog = {
    'BEL': (namePl: 'Belgia', uciRank: 1),
    'SLO': (namePl: 'Słowenia', uciRank: 2),
    'FRA': (namePl: 'Francja', uciRank: 3),
    'NED': (namePl: 'Holandia', uciRank: 4),
    'DEN': (namePl: 'Dania', uciRank: 5),
    'ITA': (namePl: 'Włochy', uciRank: 6),
    'GBR': (namePl: 'Wielka Brytania', uciRank: 7),
    'ESP': (namePl: 'Hiszpania', uciRank: 8),
    'AUS': (namePl: 'Australia', uciRank: 9),
    'USA': (namePl: 'Stany Zjednoczone', uciRank: 10),
    'POL': (namePl: 'Polska', uciRank: 11),
    'COL': (namePl: 'Kolumbia', uciRank: 12),
    'SUI': (namePl: 'Szwajcaria', uciRank: 13),
    'GER': (namePl: 'Niemcy', uciRank: 14),
    'NOR': (namePl: 'Norwegia', uciRank: 15),
  };

  /// Buduje tabelę medalową z bazowych wyników edycji oraz ewentualnych raportów symulacji.
  static List<OlympicCountryMedalRow> buildMedalTable({
    required int olympicYear,
    required List<OlympicRaceSimulationReport> reports,
    required String playerNationalityIso,
    required OlympicGamesQuadrennialCycleService service,
  }) {
    final playerIso = playerNationalityIso.toUpperCase();
    final Map<String, OlympicCountryMedalRow> rows = {};

    for (final entry in _nationCatalog.entries) {
      final quota = service.computeNationalQuota(
        nationalityIso: entry.key,
        nationUciRank: entry.value.uciRank,
      );
      rows[entry.key] = OlympicCountryMedalRow(
        countryIso: entry.key,
        countryNamePl: entry.value.namePl,
        flagCode: entry.key,
        goldCount: 0,
        silverCount: 0,
        bronzeCount: 0,
        roadRaceQuota: quota.roadRaceQuota,
        ittQuota: quota.ittQuota,
        nationUciRank: entry.value.uciRank,
        isPlayerNation: entry.key == playerIso,
        notableMedalists: const [],
      );
    }

    final yearReports =
        reports.where((r) => r.edition.year == olympicYear).toList();

    if (yearReports.isEmpty) {
      _seedBaselineEditionMedals(rows, olympicYear);
    } else {
      for (final report in yearReports) {
        for (final standing in report.standings) {
          final medal = standing.medal;
          if (medal == null) continue;
          final iso = standing.nationalityIso.toUpperCase();
          final existing = rows[iso] ??
              OlympicCountryMedalRow(
                countryIso: iso,
                countryNamePl: iso,
                flagCode: iso,
                goldCount: 0,
                silverCount: 0,
                bronzeCount: 0,
                roadRaceQuota: 2,
                ittQuota: 1,
                nationUciRank: 20,
                isPlayerNation: iso == playerIso,
              );
          final medalLabel =
              '${standing.riderName} (${report.discipline == OlympicDiscipline.roadRace ? 'RR' : 'ITT'} · ${medal.polishLabel})';
          rows[iso] = existing.copyWith(
            goldCount: existing.goldCount +
                (medal == OlympicMedalTier.gold ? 1 : 0),
            silverCount: existing.silverCount +
                (medal == OlympicMedalTier.silver ? 1 : 0),
            bronzeCount: existing.bronzeCount +
                (medal == OlympicMedalTier.bronze ? 1 : 0),
            notableMedalists: [...existing.notableMedalists, medalLabel],
          );
        }
      }
    }

    return sortRows(
      rows.values.toList(),
      sortColumn: OlympicMedalTableSortColumn.olympicRank,
      ascending: false,
    );
  }

  static void _seedBaselineEditionMedals(
    Map<String, OlympicCountryMedalRow> rows,
    int olympicYear,
  ) {
    if (olympicYear == 2024) {
      _addMedal(rows, 'BEL', OlympicMedalTier.gold, 'R. Evenepoel (RR · Złoty Medal)');
      _addMedal(rows, 'BEL', OlympicMedalTier.gold, 'R. Evenepoel (ITT · Złoty Medal)');
      _addMedal(rows, 'BEL', OlympicMedalTier.bronze, 'W. van Aert (ITT · Brązowy Medal)');
      _addMedal(rows, 'FRA', OlympicMedalTier.silver, 'V. Madouas (RR · Srebrny Medal)');
      _addMedal(rows, 'FRA', OlympicMedalTier.bronze, 'C. Laporte (RR · Brązowy Medal)');
      _addMedal(rows, 'ITA', OlympicMedalTier.silver, 'F. Ganna (ITT · Srebrny Medal)');
    } else if (olympicYear == 2028) {
      _addMedal(rows, 'SLO', OlympicMedalTier.gold, 'T. Pogačar (RR · Złoty Medal)');
      _addMedal(rows, 'BEL', OlympicMedalTier.gold, 'R. Evenepoel (ITT · Złoty Medal)');
      _addMedal(rows, 'BEL', OlympicMedalTier.silver, 'R. Evenepoel (RR · Srebrny Medal)');
      _addMedal(rows, 'GBR', OlympicMedalTier.silver, 'J. Tarling (ITT · Srebrny Medal)');
      _addMedal(rows, 'POL', OlympicMedalTier.bronze, 'M. Kwiatkowski (RR · Brązowy Medal)');
      _addMedal(rows, 'ITA', OlympicMedalTier.bronze, 'F. Ganna (ITT · Brązowy Medal)');
    } else {
      _addMedal(rows, 'FRA', OlympicMedalTier.gold, 'L. Martinez (RR · Złoty Medal)');
      _addMedal(rows, 'GBR', OlympicMedalTier.gold, 'J. Tarling (ITT · Złoty Medal)');
      _addMedal(rows, 'AUS', OlympicMedalTier.silver, 'L. Plapp (ITT · Srebrny Medal)');
      _addMedal(rows, 'DEN', OlympicMedalTier.silver, 'M. Skjelmose (RR · Srebrny Medal)');
      _addMedal(rows, 'NED', OlympicMedalTier.bronze, 'M. van der Poel (RR · Brązowy Medal)');
      _addMedal(rows, 'USA', OlympicMedalTier.bronze, 'B. McNulty (ITT · Brązowy Medal)');
    }
  }

  static void _addMedal(
    Map<String, OlympicCountryMedalRow> rows,
    String iso,
    OlympicMedalTier medal,
    String note,
  ) {
    final current = rows[iso];
    if (current == null) return;
    rows[iso] = current.copyWith(
      goldCount: current.goldCount + (medal == OlympicMedalTier.gold ? 1 : 0),
      silverCount:
          current.silverCount + (medal == OlympicMedalTier.silver ? 1 : 0),
      bronzeCount:
          current.bronzeCount + (medal == OlympicMedalTier.bronze ? 1 : 0),
      notableMedalists: [...current.notableMedalists, note],
    );
  }

  /// Sortuje i filtruje wiersze tabeli medalowej.
  static List<OlympicCountryMedalRow> sortRows(
    List<OlympicCountryMedalRow> input, {
    required OlympicMedalTableSortColumn sortColumn,
    required bool ascending,
    String searchQuery = '',
    bool onlyWithMedals = false,
  }) {
    final query = searchQuery.trim().toLowerCase();
    final filtered = input.where((row) {
      if (onlyWithMedals && row.totalMedals == 0) return false;
      if (query.isNotEmpty) {
        return row.countryNamePl.toLowerCase().contains(query) ||
            row.countryIso.toLowerCase().contains(query);
      }
      return true;
    }).toList();

    filtered.sort((a, b) {
      int cmp;
      switch (sortColumn) {
        case OlympicMedalTableSortColumn.olympicRank:
          cmp = a.olympicRankScore.compareTo(b.olympicRankScore);
          if (cmp == 0) {
            cmp = a.roadRaceQuota.compareTo(b.roadRaceQuota);
          }
          break;
        case OlympicMedalTableSortColumn.totalMedals:
          cmp = a.totalMedals.compareTo(b.totalMedals);
          if (cmp == 0) {
            cmp = a.goldCount.compareTo(b.goldCount);
          }
          break;
        case OlympicMedalTableSortColumn.countryName:
          cmp = a.countryNamePl.compareTo(b.countryNamePl);
          break;
        case OlympicMedalTableSortColumn.uciQuota:
          cmp = a.roadRaceQuota.compareTo(b.roadRaceQuota);
          if (cmp == 0) {
            cmp = b.nationUciRank.compareTo(a.nationUciRank);
          }
          break;
      }
      return ascending ? cmp : -cmp;
    });

    return filtered;
  }
}

/// Generator przykładowej puli kolarzy światowych dla symulacji olimpijskiej w trybie standalone.
class OlympicHubWorldRosterCatalog {
  const OlympicHubWorldRosterCatalog._();

  static List<Rider> buildSampleWorldRiders() {
    const specs = [
      ('bel_1', 'Remco', 'Evenepoel', 'BEL', 435, 62.0, 96, 88, 92, 4100),
      ('bel_2', 'Wout', 'van Aert', 'BEL', 425, 78.0, 90, 92, 91, 3200),
      ('bel_3', 'Jasper', 'Philipsen', 'BEL', 385, 75.0, 78, 86, 84, 2400),
      ('bel_4', 'Tiesj', 'Benoot', 'BEL', 375, 71.0, 82, 85, 88, 1750),
      ('slo_1', 'Tadej', 'Pogačar', 'SLO', 440, 66.0, 94, 95, 95, 4800),
      ('slo_2', 'Primož', 'Roglič', 'SLO', 415, 65.0, 92, 88, 90, 2900),
      ('slo_3', 'Matej', 'Mohorič', 'SLO', 390, 72.0, 83, 86, 92, 1850),
      ('slo_4', 'Jan', 'Tratnik', 'SLO', 380, 68.0, 84, 80, 87, 1100),
      ('fra_1', 'Valentin', 'Madouas', 'FRA', 385, 70.0, 79, 87, 86, 2100),
      ('fra_2', 'Christophe', 'Laporte', 'FRA', 400, 77.0, 82, 85, 88, 2300),
      ('fra_3', 'Julian', 'Alaphilippe', 'FRA', 380, 62.0, 80, 90, 89, 1750),
      ('fra_4', 'Kévin', 'Vauquelin', 'FRA', 392, 69.0, 86, 84, 83, 1400),
      ('ned_1', 'Mathieu', 'van der Poel', 'NED', 430, 75.0, 85, 96, 93, 3900),
      ('ned_2', 'Dylan', 'van Baarle', 'NED', 395, 76.0, 84, 82, 89, 1500),
      ('ned_3', 'Olav', 'Kooij', 'NED', 370, 72.0, 74, 80, 82, 1900),
      ('ned_4', 'Thymen', 'Arensman', 'NED', 398, 68.0, 87, 79, 82, 1300),
      ('den_1', 'Jonas', 'Vingegaard', 'DEN', 418, 60.0, 93, 86, 91, 4100),
      ('den_2', 'Mads', 'Pedersen', 'DEN', 420, 78.0, 85, 90, 89, 3100),
      ('den_3', 'Mattias', 'Skjelmose', 'DEN', 395, 66.0, 86, 88, 86, 2200),
      ('den_4', 'Mikkel', 'Bjerg', 'DEN', 402, 74.0, 89, 77, 83, 980),
      ('ita_1', 'Filippo', 'Ganna', 'ITA', 465, 83.0, 98, 82, 87, 2600),
      ('ita_2', 'Jonathan', 'Milan', 'ITA', 430, 84.0, 84, 82, 82, 2400),
      ('ita_3', 'Alberto', 'Bettiol', 'ITA', 388, 70.0, 81, 86, 87, 1450),
      ('gbr_1', 'Joshua', 'Tarling', 'GBR', 452, 79.0, 96, 79, 83, 1900),
      ('gbr_2', 'Tom', 'Pidcock', 'GBR', 378, 58.0, 80, 90, 88, 2450),
      ('gbr_3', 'Ethan', 'Hayter', 'GBR', 400, 71.0, 88, 84, 82, 1250),
      ('pol_1', 'Michał', 'Kwiatkowski', 'POL', 385, 68.0, 87, 84, 92, 1650),
      ('pol_2', 'Rafał', 'Majka', 'POL', 368, 60.0, 78, 82, 89, 1200),
      ('pol_3', 'Stanisław', 'Aniołkowski', 'POL', 355, 73.0, 72, 78, 80, 850),
      ('aus_1', 'Luke', 'Plapp', 'AUS', 415, 72.0, 90, 83, 84, 1500),
      ('aus_2', 'Michael', 'Matthews', 'AUS', 392, 74.0, 81, 87, 88, 2200),
      ('usa_1', 'Brandon', 'McNulty', 'USA', 410, 68.0, 91, 83, 85, 1950),
      ('usa_2', 'Matteo', 'Jorgenson', 'USA', 412, 72.0, 89, 87, 89, 2550),
    ];

    return specs.map((s) {
      final wPerKg = s.$5 / s.$6;
      return Rider(
        id: s.$1,
        firstName: s.$2,
        lastName: s.$3,
        nationalityIso: s.$4,
        birthDate: DateTime(1998, 5, 14),
        potential: 92,
        specialization: RiderSpecialization.puncher,
        careerPointsUci: s.$10,
        physiology: RiderPhysiology(
          heightCm: 178.0,
          weightKg: s.$6,
          bodyFatPercentage: 6.8,
          ftpWatts: s.$5,
          wPrimeJoules: 23500,
          vo2Max: 84.5,
          maxHr: 194,
          restingHr: 38,
          lactateThresholdHr: 176,
          recoveryRate: 1.12,
          glycogenCapacityGrams: 540.0,
        ),
        powerProfile: RiderPowerProfile(
          watts5s: (s.$5 * 3.1).round(),
          watts15s: (s.$5 * 2.4).round(),
          watts30s: (s.$5 * 2.05).round(),
          watts1m: (s.$5 * 1.75).round(),
          watts3m: (s.$5 * 1.38).round(),
          watts5m: (s.$5 * 1.25).round(),
          watts20m: (s.$5 * 1.06).round(),
          watts60m: s.$5,
        ),
        skills: RiderSkills(
          cobbles: 80,
          descending: 84,
          bikeHandling: 86,
          aeroPositioning: s.$7 - 2,
          draftingEfficiency: (80 + wPerKg).round().clamp(75, 95),
          raceIq: s.$9,
          rainResistance: 82,
          heatTolerance: 82,
          timeTrialPositioning: s.$7,
        ),
        health: const RiderHealth(
          acuteTrainingLoad: 82.0,
          chronicTrainingLoad: 96.0,
        ),
        contract: RiderContract(
          teamId: 'nat_${s.$4.toLowerCase()}',
          role: RiderRole.teamLeader,
          monthlySalaryEur: 100000,
          signingBonusEur: 50000,
          winBonusEur: 25000,
          releaseClauseEur: 2500000,
          contractEndYear: 2029,
          morale: 88.0,
          leaderLoyalty: 85.0,
          requiredRacesIds: const [],
        ),
        appearance: const RiderAppearance(
          faceShapeIndex: 1,
          skinToneHex: '#E8BE9E',
          hairStyleIndex: 1,
          hairColorHex: '#3B2F2F',
          facialHairIndex: 0,
          glassesModelId: 'aero_pro',
          glassesLensColorHex: '#00E5FF',
          helmetModelId: 'aero_helmet',
          shoeColorHex: '#F3F4F6',
          sockHeightProportion: 0.75,
          bodyBuildType: BodyBuildType.allRounder,
        ),
      );
    }).toList();
  }
}

/// Główny ekran Centrum Igrzysk Olimpijskich i Tabeli Medalowej Państw.
///
/// Integruje 4-letni cykl olimpijski (`OlympicGamesQuadrennialCycleService`),
/// zasady braku radia wyścigowego (No Race Radio), małe reprezentacje narodowe
/// (max 4 RR / max 2 ITT), Złoty Kask i Złotą Ramę Mistrzów Olimpijskich
/// oraz sortowalną/filtrowalną tabelę medalową państw.
class OlympicGamesHubAndMedalTableScreen extends StatefulWidget {
  final OlympicGamesQuadrennialCycleState? initialState;
  final List<OlympicRaceSimulationReport>? initialReports;
  final String playerNationalityIso;
  final bool isReadOnly;
  final ValueChanged<OlympicHostEdition>? onLaunchRace3d;
  final VoidCallback? onBack;

  const OlympicGamesHubAndMedalTableScreen({
    super.key,
    this.initialState,
    this.initialReports,
    this.playerNationalityIso = 'POL',
    this.isReadOnly = false,
    this.onLaunchRace3d,
    this.onBack,
  });

  @override
  State<OlympicGamesHubAndMedalTableScreen> createState() =>
      _OlympicGamesHubAndMedalTableScreenState();
}

class _OlympicGamesHubAndMedalTableScreenState
    extends State<OlympicGamesHubAndMedalTableScreen> {
  static const List<int> _availableOlympicYears = [2024, 2028, 2032, 2036];

  late OlympicGamesQuadrennialCycleService _service;
  late OlympicGamesQuadrennialCycleState _cycleState;
  late List<OlympicRaceSimulationReport> _reports;
  late List<Rider> _worldRiders;

  OlympicHubTab _activeTab = OlympicHubTab.medalTable;
  OlympicMedalTableSortColumn _sortColumn =
      OlympicMedalTableSortColumn.olympicRank;
  bool _sortAscending = false;
  bool _onlyWithMedals = false;
  String _searchQuery = '';
  String _selectedRosterNationIso = 'POL';
  String? _expandedCountryIso;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _reports = List<OlympicRaceSimulationReport>.from(
      widget.initialReports ?? const [],
    );
    _service = OlympicGamesQuadrennialCycleService(
      initialGoldGear: widget.initialState?.activeChampions,
      initialHistory: _reports,
    );
    _worldRiders = OlympicHubWorldRosterCatalog.buildSampleWorldRiders();
    _selectedRosterNationIso = widget.playerNationalityIso.toUpperCase();

    if (widget.initialState != null) {
      _cycleState = widget.initialState!;
    } else {
      const initialYear = 2028;
      _cycleState = OlympicGamesQuadrennialCycleState(
        currentYear: initialYear,
        selectedDiscipline: OlympicDiscipline.roadRace,
        activeEdition: _service.getEditionForYear(initialYear),
        noRadioRules: _service.getNoRaceRadioRules(OlympicDiscipline.roadRace),
        activeChampions: _service.goldGearRegistry
            .where((g) => g.isActiveInYear(initialYear))
            .toList(),
        latestReport: _reports.isNotEmpty ? _reports.last : null,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectYear(int year) {
    if (widget.isReadOnly) return;
    setState(() {
      _cycleState = _cycleState.copyWith(
        currentYear: year,
        activeEdition: _service.getEditionForYear(year),
        activeChampions: _service.goldGearRegistry
            .where((g) => g.isActiveInYear(year))
            .toList(),
      );
    });
  }

  void _selectDiscipline(OlympicDiscipline discipline) {
    if (widget.isReadOnly) return;
    setState(() {
      _cycleState = _cycleState.copyWith(
        selectedDiscipline: discipline,
        noRadioRules: _service.getNoRaceRadioRules(discipline),
      );
    });
  }

  void _runOlympicRaceSimulation() {
    if (widget.isReadOnly || _cycleState.isSimulating) return;
    final nationRanks = {
      for (final entry in {
        'BEL': 1,
        'SLO': 2,
        'FRA': 3,
        'NED': 4,
        'DEN': 5,
        'ITA': 6,
        'GBR': 7,
        'ESP': 8,
        'AUS': 9,
        'USA': 10,
        'POL': 11,
      }.entries)
        entry.key: entry.value,
    };

    final report = _service.simulateOlympicRace(
      olympicYear: _cycleState.currentYear,
      discipline: _cycleState.selectedDiscipline,
      worldRiders: _worldRiders,
      nationUciRanks: nationRanks,
      seed: _cycleState.currentYear * 31 + _cycleState.selectedDiscipline.index,
    );

    setState(() {
      _reports.add(report);
      _cycleState = _cycleState.copyWith(
        latestReport: report,
        activeChampions: _service.goldGearRegistry
            .where((g) => g.isActiveInYear(_cycleState.currentYear))
            .toList(),
      );
    });
  }

  void _onToggleSort(OlympicMedalTableSortColumn column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = column == OlympicMedalTableSortColumn.countryName;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final allMedalRows = OlympicMedalTableAggregator.buildMedalTable(
      olympicYear: _cycleState.currentYear,
      reports: _reports,
      playerNationalityIso: widget.playerNationalityIso,
      service: _service,
    );

    final filteredMedalRows = OlympicMedalTableAggregator.sortRows(
      allMedalRows,
      sortColumn: _sortColumn,
      ascending: _sortAscending,
      searchQuery: _searchQuery,
      onlyWithMedals: _onlyWithMedals,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isMobile = width < 680;
            final isDesktop = width >= 1180;

            return Column(
              children: [
                _buildTopHeader(isMobile),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isMobile ? 12 : 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildYearAndDisciplineBar(isMobile),
                        const SizedBox(height: 16),
                        if (isDesktop)
                          _buildDesktopBentoLayout(
                            allMedalRows: allMedalRows,
                            filteredMedalRows: filteredMedalRows,
                          )
                        else
                          _buildTabbedLayout(
                            isMobile: isMobile,
                            allMedalRows: allMedalRows,
                            filteredMedalRows: filteredMedalRows,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopHeader(bool isMobile) {
    final edition = _cycleState.activeEdition;
    final phase = _service.evaluateCyclePhase(
      DateTime(_cycleState.currentYear, 8, 1),
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: isMobile ? 10 : 14,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          if (widget.onBack != null || Navigator.of(context).canPop()) ...[
            _OlympicIconButton(
              icon: Icons.arrow_back_rounded,
              tooltip: 'Wróć',
              isDisabled: false,
              onTap: widget.onBack ?? () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: 12),
          ],
          Container(
            width: isMobile ? 36 : 42,
            height: isMobile ? 36 : 42,
            decoration: BoxDecoration(
              color: AppColors.goldAccent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.goldAccent.withValues(alpha: 0.5),
              ),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
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
                  'IGRZYSKA OLIMPIJSKIE • ${edition.hostCity.toUpperCase()} ${edition.year}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: isMobile ? 14 : 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${phase.polishLabel} • Brak Radia Wyścigowego • Małe Reprezentacje (4 RR / 2 ITT)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (!isMobile) ...[
            const SizedBox(width: 12),
            _buildSimulateActionButton(isCompact: false),
          ],
        ],
      ),
    );
  }

  Widget _buildYearAndDisciplineBar(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'EDYCJA 4-LETNIA:',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              ..._availableOlympicYears.map((year) {
                final ed = _service.getEditionForYear(year);
                final selected = _cycleState.currentYear == year;
                return _OlympicSelectableChip(
                  label: '$year ${ed.hostCity}',
                  isSelected: selected,
                  isDisabled: widget.isReadOnly,
                  accentColor: AppColors.goldAccent,
                  onTap: () => _selectYear(year),
                );
              }),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.cardBorder, height: 1),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: OlympicDiscipline.values.map((disc) {
                  final selected = _cycleState.selectedDiscipline == disc;
                  return _OlympicSelectableChip(
                    label:
                        '${disc.polishLabel} (max ${disc.maxNationalQuota})',
                    isSelected: selected,
                    isDisabled: widget.isReadOnly,
                    accentColor: AppColors.primaryAccent,
                    onTap: () => _selectDiscipline(disc),
                  );
                }).toList(),
              ),
              if (isMobile)
                SizedBox(
                  width: double.infinity,
                  child: _buildSimulateActionButton(isCompact: true),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimulateActionButton({required bool isCompact}) {
    final enabled = !widget.isReadOnly && !_cycleState.isSimulating;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _OlympicPrimaryButton(
          label: _cycleState.isSimulating
              ? 'Symulacja...'
              : 'Symuluj Wyścig Olimpijski',
          icon: Icons.play_arrow_rounded,
          isDisabled: !enabled,
          isPrimary: true,
          onTap: _runOlympicRaceSimulation,
        ),
        if (widget.onLaunchRace3d != null)
          _OlympicPrimaryButton(
            label: isCompact ? 'Widok 3D' : 'Startuj w 3D',
            icon: Icons.videocam_rounded,
            isDisabled: widget.isReadOnly,
            isPrimary: false,
            onTap: () => widget.onLaunchRace3d?.call(_cycleState.activeEdition),
          ),
      ],
    );
  }

  Widget _buildDesktopBentoLayout({
    required List<OlympicCountryMedalRow> allMedalRows,
    required List<OlympicCountryMedalRow> filteredMedalRows,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 7,
              child: _buildMedalTableCard(
                filteredMedalRows: filteredMedalRows,
                isMobile: false,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  _buildCourseAndNoRadioCard(isMobile: false),
                  const SizedBox(height: 16),
                  _buildGoldChampionsCard(isMobile: false),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildNationalRostersCard(isMobile: false),
        if (_cycleState.latestReport != null) ...[
          const SizedBox(height: 16),
          _buildLatestSimulationPodiumCard(_cycleState.latestReport!, false),
        ],
      ],
    );
  }

  Widget _buildTabbedLayout({
    required bool isMobile,
    required List<OlympicCountryMedalRow> allMedalRows,
    required List<OlympicCountryMedalRow> filteredMedalRows,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: OlympicHubTab.values.map((tab) {
              final selected = _activeTab == tab;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _OlympicSelectableChip(
                  label: tab.labelPl,
                  icon: tab.icon,
                  isSelected: selected,
                  isDisabled: false,
                  accentColor: AppColors.goldAccent,
                  onTap: () => setState(() => _activeTab = tab),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeOutCubic,
          child: switch (_activeTab) {
            OlympicHubTab.medalTable => KeyedSubtree(
                key: const ValueKey('tab_medal_table'),
                child: _buildMedalTableCard(
                  filteredMedalRows: filteredMedalRows,
                  isMobile: isMobile,
                ),
              ),
            OlympicHubTab.overviewAndCourse => KeyedSubtree(
                key: const ValueKey('tab_overview'),
                child: Column(
                  children: [
                    _buildCourseAndNoRadioCard(isMobile: isMobile),
                    if (_cycleState.latestReport != null) ...[
                      const SizedBox(height: 14),
                      _buildLatestSimulationPodiumCard(
                        _cycleState.latestReport!,
                        isMobile,
                      ),
                    ],
                  ],
                ),
              ),
            OlympicHubTab.nationalRosters => KeyedSubtree(
                key: const ValueKey('tab_rosters'),
                child: _buildNationalRostersCard(isMobile: isMobile),
              ),
            OlympicHubTab.goldChampions => KeyedSubtree(
                key: const ValueKey('tab_champions'),
                child: _buildGoldChampionsCard(isMobile: isMobile),
              ),
          },
        ),
      ],
    );
  }

  Widget _buildMedalTableCard({
    required List<OlympicCountryMedalRow> filteredMedalRows,
    required bool isMobile,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.leaderboard_rounded,
                    color: AppColors.goldAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'TABELA MEDALOWA PAŃSTW (${_cycleState.currentYear})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ],
              ),
              _OlympicSelectableChip(
                label: 'Tylko z medalami',
                isSelected: _onlyWithMedals,
                isDisabled: false,
                accentColor: AppColors.accentBlue,
                onTap: () =>
                    setState(() => _onlyWithMedals = !_onlyWithMedals),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Szukaj kraju lub kodu ISO (np. POL, Belgia)...',
              hintStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.surfaceLight,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.goldAccent),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildMedalTableHeaderRow(isMobile),
          const SizedBox(height: 6),
          if (filteredMedalRows.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    color: AppColors.textSecondary,
                    size: 28,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Brak państw spełniających kryteria filtra.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else
            ...filteredMedalRows.asMap().entries.map((entry) {
              final idx = entry.key;
              final row = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _buildMedalCountryRow(
                  rank: idx + 1,
                  row: row,
                  isMobile: isMobile,
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildMedalTableHeaderRow(bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 28,
            child: Text(
              '#',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: _SortHeaderCell(
              label: 'Państwo',
              isActive: _sortColumn == OlympicMedalTableSortColumn.countryName,
              ascending: _sortAscending,
              onTap: () =>
                  _onToggleSort(OlympicMedalTableSortColumn.countryName),
            ),
          ),
          _SortHeaderMedalDot(
            color: AppColors.goldAccent,
            label: 'Z',
            onTap: () =>
                _onToggleSort(OlympicMedalTableSortColumn.olympicRank),
          ),
          _SortHeaderMedalDot(
            color: const Color(0xFFD1D5DB),
            label: 'S',
            onTap: () =>
                _onToggleSort(OlympicMedalTableSortColumn.olympicRank),
          ),
          _SortHeaderMedalDot(
            color: const Color(0xFFCD7F32),
            label: 'B',
            onTap: () =>
                _onToggleSort(OlympicMedalTableSortColumn.olympicRank),
          ),
          SizedBox(
            width: isMobile ? 44 : 56,
            child: _SortHeaderCell(
              label: 'Suma',
              alignRight: true,
              isActive: _sortColumn == OlympicMedalTableSortColumn.totalMedals,
              ascending: _sortAscending,
              onTap: () =>
                  _onToggleSort(OlympicMedalTableSortColumn.totalMedals),
            ),
          ),
          if (!isMobile)
            SizedBox(
              width: 68,
              child: _SortHeaderCell(
                label: 'Kwota',
                alignRight: true,
                isActive: _sortColumn == OlympicMedalTableSortColumn.uciQuota,
                ascending: _sortAscending,
                onTap: () =>
                    _onToggleSort(OlympicMedalTableSortColumn.uciQuota),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMedalCountryRow({
    required int rank,
    required OlympicCountryMedalRow row,
    required bool isMobile,
  }) {
    final isExpanded = _expandedCountryIso == row.countryIso;

    return _InteractiveCardRow(
      isHighlighted: row.isPlayerNation || isExpanded,
      highlightColor:
          row.isPlayerNation ? AppColors.goldAccent : AppColors.accentBlue,
      onTap: () {
        setState(() {
          _expandedCountryIso = isExpanded ? null : row.countryIso;
          _selectedRosterNationIso = row.countryIso;
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  '$rank',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: rank <= 3
                        ? AppColors.goldAccent
                        : AppColors.textSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: row.isPlayerNation
                            ? AppColors.goldAccent.withValues(alpha: 0.2)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: row.isPlayerNation
                              ? AppColors.goldAccent
                              : AppColors.cardBorder,
                        ),
                      ),
                      child: Text(
                        row.countryIso,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: row.isPlayerNation
                              ? AppColors.goldAccent
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        row.countryNamePl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: row.isPlayerNation
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _MedalCountCell(
                count: row.goldCount,
                color: AppColors.goldAccent,
              ),
              _MedalCountCell(
                count: row.silverCount,
                color: const Color(0xFFD1D5DB),
              ),
              _MedalCountCell(
                count: row.bronzeCount,
                color: const Color(0xFFCD7F32),
              ),
              SizedBox(
                width: isMobile ? 44 : 56,
                child: Text(
                  '${row.totalMedals}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              if (!isMobile)
                SizedBox(
                  width: 68,
                  child: Text(
                    '${row.roadRaceQuota}RR/${row.ittQuota}TT',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
            ],
          ),
          if (isExpanded) ...[
            const SizedBox(height: 10),
            const Divider(color: AppColors.cardBorder, height: 1),
            const SizedBox(height: 8),
            Text(
              'Ranking UCI: #${row.nationUciRank} • Kwoty: max ${row.roadRaceQuota} (RR) / max ${row.ittQuota} (ITT)',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: AppColors.accentBlue,
              ),
            ),
            const SizedBox(height: 4),
            if (row.notableMedalists.isEmpty)
              const Text(
                'Brak zdobytych medali w tej edycji Igrzysk.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              )
            else
              ...row.notableMedalists.map(
                (medalist) => Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '• $medalist',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildCourseAndNoRadioCard({required bool isMobile}) {
    final edition = _cycleState.activeEdition;
    final rules = _cycleState.noRadioRules;

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.route_rounded, color: AppColors.accentBlue, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'TRASA OLIMPIJSKA & ZASADA NO RACE RADIO',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  edition.roadRaceCircuitName,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.goldAccent,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    _TelemetryPill(
                      label: 'Dystans RR',
                      value: '${edition.roadRaceDistanceKm.toStringAsFixed(1)} km',
                    ),
                    _TelemetryPill(
                      label: 'Przewyższenie',
                      value: '${edition.roadRaceElevationGainM} m',
                    ),
                    _TelemetryPill(
                      label: 'ITT',
                      value: '${edition.ittDistanceKm.toStringAsFixed(1)} km',
                    ),
                    _TelemetryPill(
                      label: 'Profil',
                      value: edition.roadRaceTerrain.polishLabel,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.amberWarning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.amberWarning.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.portable_wifi_off_rounded,
                      color: AppColors.amberWarning,
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'ZAKAZ RADIA WYŚCIGOWEGO (NO RACE RADIO)',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.amberWarning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Brak łączności głosowej z dyrektorem sportowym. Tablica motocyklowa opóźniona o ${rules.motoChalkboardDelaySeconds} s, kontakt wzrokowy w promieniu ${rules.visualContactRadiusMeters.toStringAsFixed(0)} m, chaos odjazdów x${rules.breakawayChaosMultiplier.toStringAsFixed(2)}.',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoldChampionsCard({required bool isMobile}) {
    final champions = _cycleState.activeChampions;

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                color: AppColors.goldAccent,
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ZŁOTY KASK & ZŁOTA RAMA (4-LETNI CYKL)',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (champions.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Text(
                'Brak aktywnych mistrzów w tym cyklu. Przeprowadź symulację wyścigu olimpijskiego, aby przyznać Złoty Kask i Złotą Ramę na kolejne 4 sezony.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            )
          else
            ...champions.map((gear) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.goldAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.goldAccent.withValues(alpha: 0.45),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.goldAccent.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.goldAccent),
                      ),
                      child: const Icon(
                        Icons.verified_rounded,
                        color: AppColors.goldAccent,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${gear.riderName} (${gear.nationalityIso})',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${gear.discipline.polishLabel} • ${gear.olympicYearWon}–${gear.validUntilYear} • Morale +${gear.moraleBonus}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: AppColors.goldAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildNationalRostersCard({required bool isMobile}) {
    const nationCodes = [
      'POL',
      'BEL',
      'SLO',
      'FRA',
      'NED',
      'DEN',
      'ITA',
      'GBR',
      'AUS',
      'USA',
    ];
    const nationRanks = {
      'BEL': 1,
      'SLO': 2,
      'FRA': 3,
      'NED': 4,
      'DEN': 5,
      'ITA': 6,
      'GBR': 7,
      'AUS': 9,
      'USA': 10,
      'POL': 11,
    };

    final roster = _service.buildNationalTeamRoster(
      olympicYear: _cycleState.currentYear,
      nationalityIso: _selectedRosterNationIso,
      discipline: _cycleState.selectedDiscipline,
      worldRiders: _worldRiders,
      nationUciRank: nationRanks[_selectedRosterNationIso] ?? 15,
    );

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.groups_rounded,
                    color: AppColors.statusSuccess,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'MAŁE REPREZENTACJE NARODOWE',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                'Limit: ${roster.squadSize}/${roster.maxAllowedQuota} miejsc',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.statusSuccess,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: nationCodes.map((iso) {
              return _OlympicSelectableChip(
                label: iso,
                isSelected: _selectedRosterNationIso == iso,
                isDisabled: false,
                accentColor: AppColors.statusSuccess,
                onTap: () => setState(() => _selectedRosterNationIso = iso),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          if (roster.selectedRiderNames.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Text(
                'Brak powołanych kolarzy dla tej reprezentacji.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(roster.selectedRiderNames.length, (i) {
                final riderId = roster.selectedRiderIds[i];
                final riderName = roster.selectedRiderNames[i];
                final isCaptain = riderId == roster.roadCaptainRiderId;

                return Container(
                  width: isMobile ? double.infinity : 230,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCaptain
                          ? AppColors.goldAccent
                          : AppColors.cardBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isCaptain ? Icons.star_rounded : Icons.pedal_bike_rounded,
                        size: 18,
                        color: isCaptain
                            ? AppColors.goldAccent
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              riderName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              isCaptain
                                  ? 'Kapitan Szosowy (bez radia)'
                                  : 'Reprezentant $_selectedRosterNationIso',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                color: isCaptain
                                    ? AppColors.goldAccent
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }

  Widget _buildLatestSimulationPodiumCard(
    OlympicRaceSimulationReport report,
    bool isMobile,
  ) {
    final topEntries = report.standings.take(8).toList();
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.goldAccent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'WYNIKI SYMULACJI: ${report.edition.hostCity.toUpperCase()} ${report.edition.year} • ${report.discipline.polishLabel.toUpperCase()}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.goldAccent,
            ),
          ),
          const SizedBox(height: 10),
          ...topEntries.map((entry) {
            final gapText = entry.rank == 1
                ? _formatDuration(entry.finishTime)
                : '+${_formatDuration(entry.gapToWinner)}';
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: entry.medal != null
                      ? AppColors.goldAccent.withValues(alpha: 0.4)
                      : AppColors.cardBorder,
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 26,
                    child: Text(
                      '${entry.rank}.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: entry.medal != null
                            ? AppColors.goldAccent
                            : AppColors.textSecondary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${entry.riderName} (${entry.nationalityIso})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '${entry.averageSpeedKmh.toStringAsFixed(1)} km/h',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    gapText,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final mins = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) return '${hours}h $mins:$secs';
    return '$mins:$secs';
  }
}

class _OlympicSelectableChip extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final bool isDisabled;
  final Color accentColor;
  final VoidCallback onTap;

  const _OlympicSelectableChip({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.isDisabled,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_OlympicSelectableChip> createState() => _OlympicSelectableChipState();
}

class _OlympicSelectableChipState extends State<_OlympicSelectableChip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = !widget.isDisabled;
    final bgColor = !enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.5)
        : widget.isSelected
            ? widget.accentColor.withValues(alpha: 0.22)
            : _pressed
                ? AppColors.surfaceLight
                : _hovered
                    ? AppColors.surfaceLight.withValues(alpha: 0.9)
                    : AppColors.background;

    final borderColor = !enabled
        ? AppColors.cardBorder.withValues(alpha: 0.5)
        : _focused
            ? AppColors.goldAccent
            : widget.isSelected
                ? widget.accentColor
                : _hovered
                    ? widget.accentColor.withValues(alpha: 0.6)
                    : AppColors.cardBorder;

    return FocusableActionDetector(
      enabled: enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: borderColor,
              width: _focused ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 15,
                  color: !enabled
                      ? AppColors.textSecondary
                      : widget.isSelected
                          ? widget.accentColor
                          : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight:
                        widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: !enabled
                        ? AppColors.textSecondary.withValues(alpha: 0.6)
                        : widget.isSelected
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

class _OlympicPrimaryButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isDisabled;
  final bool isPrimary;
  final VoidCallback onTap;

  const _OlympicPrimaryButton({
    required this.label,
    required this.icon,
    required this.isDisabled,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  State<_OlympicPrimaryButton> createState() => _OlympicPrimaryButtonState();
}

class _OlympicPrimaryButtonState extends State<_OlympicPrimaryButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = !widget.isDisabled;
    final baseColor =
        widget.isPrimary ? AppColors.primaryAccent : AppColors.surfaceLight;

    final bgColor = !enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.5)
        : _pressed
            ? AppColors.goldAccent.withValues(alpha: 0.85)
            : _hovered
                ? (widget.isPrimary
                    ? AppColors.goldAccent
                    : AppColors.surfaceLight)
                : baseColor;

    final borderColor = !enabled
        ? AppColors.cardBorder
        : _focused || _hovered
            ? AppColors.goldAccent
            : (widget.isPrimary ? AppColors.primaryAccent : AppColors.cardBorder);

    final fgColor = !enabled
        ? AppColors.textSecondary
        : (_hovered && widget.isPrimary)
            ? AppColors.background
            : AppColors.textPrimary;

    return FocusableActionDetector(
      enabled: enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: _focused ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 17, color: fgColor),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: fgColor,
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

class _OlympicIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool isDisabled;
  final VoidCallback onTap;

  const _OlympicIconButton({
    required this.icon,
    required this.tooltip,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  State<_OlympicIconButton> createState() => _OlympicIconButtonState();
}

class _OlympicIconButtonState extends State<_OlympicIconButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: FocusableActionDetector(
        enabled: !widget.isDisabled,
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        child: GestureDetector(
          onTap: widget.isDisabled ? null : widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _hovered ? AppColors.surfaceLight : AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _focused ? AppColors.goldAccent : AppColors.cardBorder,
                width: _focused ? 2 : 1,
              ),
            ),
            child: Icon(
              widget.icon,
              size: 18,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractiveCardRow extends StatefulWidget {
  final Widget child;
  final bool isHighlighted;
  final Color highlightColor;
  final VoidCallback onTap;

  const _InteractiveCardRow({
    required this.child,
    required this.isHighlighted,
    required this.highlightColor,
    required this.onTap,
  });

  @override
  State<_InteractiveCardRow> createState() => _InteractiveCardRowState();
}

class _InteractiveCardRowState extends State<_InteractiveCardRow> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isHighlighted
                ? widget.highlightColor.withValues(alpha: 0.08)
                : _hovered
                    ? AppColors.surfaceLight
                    : AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focused
                  ? AppColors.goldAccent
                  : widget.isHighlighted
                      ? widget.highlightColor
                      : _hovered
                          ? AppColors.textSecondary.withValues(alpha: 0.4)
                          : AppColors.cardBorder,
              width: _focused ? 2 : 1,
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class _SortHeaderCell extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool ascending;
  final bool alignRight;
  final VoidCallback onTap;

  const _SortHeaderCell({
    required this.label,
    required this.isActive,
    required this.ascending,
    this.alignRight = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment:
            alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isActive ? AppColors.goldAccent : AppColors.textSecondary,
              ),
            ),
          ),
          if (isActive) ...[
            const SizedBox(width: 2),
            Icon(
              ascending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              size: 12,
              color: AppColors.goldAccent,
            ),
          ],
        ],
      ),
    );
  }
}

class _SortHeaderMedalDot extends StatelessWidget {
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _SortHeaderMedalDot({
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 34,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 3),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedalCountCell extends StatelessWidget {
  final int count;
  final Color color;

  const _MedalCountCell({
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: count > 0 ? FontWeight.w800 : FontWeight.w500,
          color: count > 0 ? color : AppColors.textSecondary,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _TelemetryPill extends StatelessWidget {
  final String label;
  final String value;

  const _TelemetryPill({
    required this.label,
    required this.value,
  });

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
          const SizedBox(height: 1),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
