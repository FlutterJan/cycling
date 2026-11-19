import '../../models/career/career_save.dart';
import '../../models/race/tour_race.dart';
import '../../models/rider/rider.dart';
import '../../models/team/cycling_team.dart';

/// Status prawa startu i wniosku o Dziką Kartę (Wildcard) dla wyścigu.
enum WildcardStatus {
  /// Zespół WorldTour ma gwarantowane i obowiązkowe miejsce we wszystkich wyścigach WT
  automaticEntry,

  /// Zespół ProTeam ma prawo złożyć wniosek o dziką kartę do organizatora
  eligibleToApply,

  /// Wniosek został złożony i oczekuje na posiedzenie komitetu organizacyjnego
  pending,

  /// Dzika karta została oficjalnie przyznana przez organizatora (ASO, RCS, Unipublic itp.)
  granted,

  /// Wniosek został odrzucony przez organizatora (brak miejsc, niska pozycja, inne priorytety)
  rejected,

  /// Zespół nie spełnia wymogów (np. Continental dla Grand Touru) lub wyścig zamknięty
  notEligible,

  /// Wniosek lub udział został wycofany przez kierownictwo drużyny
  withdrawn;

  String toJson() => name;

  static WildcardStatus fromJson(String value) {
    return WildcardStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => WildcardStatus.notEligible,
    );
  }

  /// Czytelna etykieta statusu w języku polskim
  String get label {
    switch (this) {
      case WildcardStatus.automaticEntry:
        return 'Gwarantowany start (WorldTour)';
      case WildcardStatus.eligibleToApply:
        return 'Wymaga wniosku o Wildcard';
      case WildcardStatus.pending:
        return 'Wniosek rozpatrywany';
      case WildcardStatus.granted:
        return 'Dzika Karta Przyznana';
      case WildcardStatus.rejected:
        return 'Wniosek Odrzucony';
      case WildcardStatus.notEligible:
        return 'Brak uprawnień startowych';
      case WildcardStatus.withdrawn:
        return 'Wycofany z wyścigu';
    }
  }

  /// Czy zespół ma zagwarantowany start na liście startowej
  bool get hasGuaranteedEntry =>
      this == WildcardStatus.automaticEntry || this == WildcardStatus.granted;

  /// Czy można złożyć wniosek o Dziką Kartę
  bool get canSubmitApplication => this == WildcardStatus.eligibleToApply;
}

/// Identyfikator podmiotu organizującego wyścig
enum RaceOrganizerType {
  aso, // Amaury Sport Organisation (Francja/Belgia: TdF, Roubaix, Liège, Dauphiné)
  rcsSport, // RCS Sport (Włochy: Giro d'Italia, Sanremo, Lombardia, Tirreno, Strade)
  unipublic, // Unipublic (Hiszpania: Vuelta, San Sebastián, Catalunya, Itzulia)
  flandersClassics, // Flanders Classics (Belgia: Ronde van Vlaanderen, Gent-Wevelgem)
  swissCycling, // Swiss Cycling / Chassot (Szwajcaria: Tour de Suisse, Romandie)
  langTeam, // Lang Team (Polska: Tour de Pologne)
  uciGlobal; // UCI i lokalne federacje (Mistrzostwa Świata, Australia, UAE, Kanada)

  String toJson() => name;

  static RaceOrganizerType fromJson(String value) {
    return RaceOrganizerType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RaceOrganizerType.uciGlobal,
    );
  }
}

/// Profil organizatora wyścigu kolarskiego z filozofią przyznawania dzikich kart
class RaceOrganizer {
  final RaceOrganizerType id;
  final String name;
  final String directorName;
  final String headquarters;
  final String countryIso;
  final String philosophy;
  final int wildcardSlotsDefault;
  final String badgeColorHex;

  const RaceOrganizer({
    required this.id,
    required this.name,
    required this.directorName,
    required this.headquarters,
    required this.countryIso,
    required this.philosophy,
    this.wildcardSlotsDefault = 4,
    this.badgeColorHex = '#D4AF37',
  });

  RaceOrganizer copyWith({
    RaceOrganizerType? id,
    String? name,
    String? directorName,
    String? headquarters,
    String? countryIso,
    String? philosophy,
    int? wildcardSlotsDefault,
    String? badgeColorHex,
  }) {
    return RaceOrganizer(
      id: id ?? this.id,
      name: name ?? this.name,
      directorName: directorName ?? this.directorName,
      headquarters: headquarters ?? this.headquarters,
      countryIso: countryIso ?? this.countryIso,
      philosophy: philosophy ?? this.philosophy,
      wildcardSlotsDefault: wildcardSlotsDefault ?? this.wildcardSlotsDefault,
      badgeColorHex: badgeColorHex ?? this.badgeColorHex,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id.toJson(),
      'name': name,
      'directorName': directorName,
      'headquarters': headquarters,
      'countryIso': countryIso,
      'philosophy': philosophy,
      'wildcardSlotsDefault': wildcardSlotsDefault,
      'badgeColorHex': badgeColorHex,
    };
  }

  factory RaceOrganizer.fromJson(Map<String, dynamic> json) {
    return RaceOrganizer(
      id: RaceOrganizerType.fromJson(json['id'] as String),
      name: json['name'] as String,
      directorName: json['directorName'] as String,
      headquarters: json['headquarters'] as String,
      countryIso: json['countryIso'] as String,
      philosophy: json['philosophy'] as String,
      wildcardSlotsDefault: (json['wildcardSlotsDefault'] as num?)?.toInt() ?? 4,
      badgeColorHex: json['badgeColorHex'] as String? ?? '#D4AF37',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RaceOrganizer && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => '$name (Dyr. $directorName, $countryIso)';
}

/// Złożony wniosek o Dziką Kartę (Wildcard) zapamiętywany w historii kariery
class WildcardApplication {
  final String id;
  final String raceId;
  final String raceName;
  final String teamId;
  final String teamName;
  final DateTime applicationDate;
  final WildcardStatus status;
  final double overallScore; // 0 - 100
  final double rankingScore; // Waga 35%
  final double nationalityScore; // Waga 30%
  final double combativityScore; // Waga 20%
  final double rosterStarScore; // Waga 15%
  final String directorQuote;
  final String officialLetter;
  final DateTime? decisionDate;

  const WildcardApplication({
    required this.id,
    required this.raceId,
    required this.raceName,
    required this.teamId,
    required this.teamName,
    required this.applicationDate,
    required this.status,
    required this.overallScore,
    required this.rankingScore,
    required this.nationalityScore,
    required this.combativityScore,
    required this.rosterStarScore,
    required this.directorQuote,
    required this.officialLetter,
    this.decisionDate,
  });

  WildcardApplication copyWith({
    String? id,
    String? raceId,
    String? raceName,
    String? teamId,
    String? teamName,
    DateTime? applicationDate,
    WildcardStatus? status,
    double? overallScore,
    double? rankingScore,
    double? nationalityScore,
    double? combativityScore,
    double? rosterStarScore,
    String? directorQuote,
    String? officialLetter,
    DateTime? decisionDate,
  }) {
    return WildcardApplication(
      id: id ?? this.id,
      raceId: raceId ?? this.raceId,
      raceName: raceName ?? this.raceName,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      applicationDate: applicationDate ?? this.applicationDate,
      status: status ?? this.status,
      overallScore: overallScore ?? this.overallScore,
      rankingScore: rankingScore ?? this.rankingScore,
      nationalityScore: nationalityScore ?? this.nationalityScore,
      combativityScore: combativityScore ?? this.combativityScore,
      rosterStarScore: rosterStarScore ?? this.rosterStarScore,
      directorQuote: directorQuote ?? this.directorQuote,
      officialLetter: officialLetter ?? this.officialLetter,
      decisionDate: decisionDate ?? this.decisionDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'raceId': raceId,
      'raceName': raceName,
      'teamId': teamId,
      'teamName': teamName,
      'applicationDate': applicationDate.toIso8601String(),
      'status': status.toJson(),
      'overallScore': overallScore,
      'rankingScore': rankingScore,
      'nationalityScore': nationalityScore,
      'combativityScore': combativityScore,
      'rosterStarScore': rosterStarScore,
      'directorQuote': directorQuote,
      'officialLetter': officialLetter,
      'decisionDate': decisionDate?.toIso8601String(),
    };
  }

  factory WildcardApplication.fromJson(Map<String, dynamic> json) {
    return WildcardApplication(
      id: json['id'] as String,
      raceId: json['raceId'] as String,
      raceName: json['raceName'] as String,
      teamId: json['teamId'] as String,
      teamName: json['teamName'] as String,
      applicationDate: DateTime.parse(json['applicationDate'] as String),
      status: WildcardStatus.fromJson(json['status'] as String),
      overallScore: (json['overallScore'] as num).toDouble(),
      rankingScore: (json['rankingScore'] as num).toDouble(),
      nationalityScore: (json['nationalityScore'] as num).toDouble(),
      combativityScore: (json['combativityScore'] as num).toDouble(),
      rosterStarScore: (json['rosterStarScore'] as num).toDouble(),
      directorQuote: json['directorQuote'] as String,
      officialLetter: json['officialLetter'] as String,
      decisionDate: json['decisionDate'] != null
          ? DateTime.parse(json['decisionDate'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WildcardApplication && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'WildcardApplication($teamName -> $raceName, $status, score: ${overallScore.toStringAsFixed(1)})';
}

/// Szczegółowy wynik ewaluacji kandydatury zespołu do Dzikiej Karty
class WildcardEvaluation {
  final bool isApproved;
  final double overallScore;
  final double rankingScore; // Waga 35%
  final double nationalityScore; // Waga 30%
  final double combativityScore; // Waga 20%
  final double rosterStarScore; // Waga 15%
  final String directorQuote;
  final String officialLetter;
  final List<String> strengths;
  final List<String> weaknesses;

  const WildcardEvaluation({
    required this.isApproved,
    required this.overallScore,
    required this.rankingScore,
    required this.nationalityScore,
    required this.combativityScore,
    required this.rosterStarScore,
    required this.directorQuote,
    required this.officialLetter,
    required this.strengths,
    required this.weaknesses,
  });

  WildcardEvaluation copyWith({
    bool? isApproved,
    double? overallScore,
    double? rankingScore,
    double? nationalityScore,
    double? combativityScore,
    double? rosterStarScore,
    String? directorQuote,
    String? officialLetter,
    List<String>? strengths,
    List<String>? weaknesses,
  }) {
    return WildcardEvaluation(
      isApproved: isApproved ?? this.isApproved,
      overallScore: overallScore ?? this.overallScore,
      rankingScore: rankingScore ?? this.rankingScore,
      nationalityScore: nationalityScore ?? this.nationalityScore,
      combativityScore: combativityScore ?? this.combativityScore,
      rosterStarScore: rosterStarScore ?? this.rosterStarScore,
      directorQuote: directorQuote ?? this.directorQuote,
      officialLetter: officialLetter ?? this.officialLetter,
      strengths: strengths != null ? List.unmodifiable(strengths) : this.strengths,
      weaknesses:
          weaknesses != null ? List.unmodifiable(weaknesses) : this.weaknesses,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isApproved': isApproved,
      'overallScore': overallScore,
      'rankingScore': rankingScore,
      'nationalityScore': nationalityScore,
      'combativityScore': combativityScore,
      'rosterStarScore': rosterStarScore,
      'directorQuote': directorQuote,
      'officialLetter': officialLetter,
      'strengths': strengths,
      'weaknesses': weaknesses,
    };
  }

  factory WildcardEvaluation.fromJson(Map<String, dynamic> json) {
    return WildcardEvaluation(
      isApproved: json['isApproved'] as bool,
      overallScore: (json['overallScore'] as num).toDouble(),
      rankingScore: (json['rankingScore'] as num).toDouble(),
      nationalityScore: (json['nationalityScore'] as num).toDouble(),
      combativityScore: (json['combativityScore'] as num).toDouble(),
      rosterStarScore: (json['rosterStarScore'] as num).toDouble(),
      directorQuote: json['directorQuote'] as String,
      officialLetter: json['officialLetter'] as String,
      strengths: (json['strengths'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      weaknesses: (json['weaknesses'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }
}

/// Zintegrowany wpis kalendarza wyścigowego dla danej drużyny
class TeamRaceCalendarEntry {
  final TourRace race;
  final RaceOrganizer organizer;
  final WildcardStatus status;
  final WildcardApplication? application;
  final bool isMandatory;
  final bool isRegistered;
  final int estimatedLogisticsCostEur;

  const TeamRaceCalendarEntry({
    required this.race,
    required this.organizer,
    required this.status,
    this.application,
    required this.isMandatory,
    required this.isRegistered,
    required this.estimatedLogisticsCostEur,
  });

  TeamRaceCalendarEntry copyWith({
    TourRace? race,
    RaceOrganizer? organizer,
    WildcardStatus? status,
    WildcardApplication? application,
    bool? isMandatory,
    bool? isRegistered,
    int? estimatedLogisticsCostEur,
  }) {
    return TeamRaceCalendarEntry(
      race: race ?? this.race,
      organizer: organizer ?? this.organizer,
      status: status ?? this.status,
      application: application ?? this.application,
      isMandatory: isMandatory ?? this.isMandatory,
      isRegistered: isRegistered ?? this.isRegistered,
      estimatedLogisticsCostEur:
          estimatedLogisticsCostEur ?? this.estimatedLogisticsCostEur,
    );
  }
}

/// Serwis zarządzający kalendarzem startowym drużyny i zaproszeniami (Wildcards).
///
/// Zasady licencjonowania UCI i komitetów organizacyjnych:
/// - Zespoły WorldTour mają gwarantowane i obowiązkowe zaproszenia na wszystkie 35 wyścigów WT.
/// - Zespoły ProTeam muszą ubiegać się o Dzikie Karty (Wildcards) na Grand Toury i Monumenty.
/// - Zespoły Continental rywalizują głównie w wyścigach krajowych (Class 1 i wybrane ProSeries).
/// - Organizatorzy oceniają wnioski według 4 wag:
///   1. Ranking UCI i punkty zespołu (35%),
///   2. Dopasowanie narodowości sponsora i bazy (30%),
///   3. Waleczność, ucieczki i profil harcowników (20%),
///   4. Gwiazdy w składzie i liderzy (15%).
class RaceCalendarSelectionService {
  RaceCalendarSelectionService._();

  // ===========================================================================
  // BAZA ORGANIZATORÓW WYŚCIGÓW KOLARSKICH
  // ===========================================================================

  static const RaceOrganizer organizerAso = RaceOrganizer(
    id: RaceOrganizerType.aso,
    name: 'Amaury Sport Organisation (A.S.O.)',
    directorName: 'Christian Prudhomme',
    headquarters: 'Issy-les-Moulineaux, Francja',
    countryIso: 'FR',
    philosophy:
        'Faworyzujemy waleczne ekipy z francuskim sponsorem i bezkompromisowych harcowników, którzy gwarantują godziny czasu antenowego w ucieczkach.',
    wildcardSlotsDefault: 4,
    badgeColorHex: '#FFDF00',
  );

  static const RaceOrganizer organizerRcs = RaceOrganizer(
    id: RaceOrganizerType.rcsSport,
    name: 'RCS Sport (La Gazzetta dello Sport)',
    directorName: 'Mauro Vegni',
    headquarters: 'Mediolan, Włochy',
    countryIso: 'IT',
    philosophy:
        'Premiujemy włoskie dziedzictwo kolarskie, agresywne ucieczki w Apeninach, wsparcie krajowych sponsorów oraz kolarzy walczących o błękitną koszulkę górala.',
    wildcardSlotsDefault: 4,
    badgeColorHex: '#E8749D',
  );

  static const RaceOrganizer organizerUnipublic = RaceOrganizer(
    id: RaceOrganizerType.unipublic,
    name: 'Unipublic (A.S.O. Iberia)',
    directorName: 'Javier Guillén',
    headquarters: 'Madryt, Hiszpania',
    countryIso: 'ES',
    philosophy:
        'Szukamy bezkompromisowych górali na mordercze hiszpańskie ścianki (rampas inhumanas) oraz wspieramy iberyjskie zespoły z mocnymi tradycjami.',
    wildcardSlotsDefault: 4,
    badgeColorHex: '#E30613',
  );

  static const RaceOrganizer organizerFlanders = RaceOrganizer(
    id: RaceOrganizerType.flandersClassics,
    name: 'Flanders Classics',
    directorName: 'Tomas Van Den Spiegel',
    headquarters: 'Zaventem, Belgia',
    countryIso: 'BE',
    philosophy:
        'Uwielbiamy twardych wojowników bruku, wiatru i flamandzkich hellingen. Kolarze muszą wytrzymać bezwzględne tempo i kraksy na wiatrakach.',
    wildcardSlotsDefault: 7,
    badgeColorHex: '#FFCC00',
  );

  static const RaceOrganizer organizerSwiss = RaceOrganizer(
    id: RaceOrganizerType.swissCycling,
    name: 'Chassot Concept & Swiss Cycling',
    directorName: 'Richard Chassot',
    headquarters: 'Fryburg, Szwajcaria',
    countryIso: 'CH',
    philosophy:
        'Cenimy precyzję, nienaganne przygotowanie do jazdy na czas i kolarzy potrafiących rywalizować na wysokogórskich alpejskich przełęczach.',
    wildcardSlotsDefault: 4,
    badgeColorHex: '#DC143C',
  );

  static const RaceOrganizer organizerLangTeam = RaceOrganizer(
    id: RaceOrganizerType.langTeam,
    name: 'Lang Team',
    directorName: 'Czesław Lang',
    headquarters: 'Warszawa, Polska',
    countryIso: 'PL',
    philosophy:
        'Promujemy młode talenty, polskich kolarzy, dynamiczne finisze oraz pasję rywalizacji na trasach Małopolski, Podkarpacia i Śląska.',
    wildcardSlotsDefault: 4,
    badgeColorHex: '#E2001A',
  );

  static const RaceOrganizer organizerUci = RaceOrganizer(
    id: RaceOrganizerType.uciGlobal,
    name: 'UCI World Cycling Committee',
    directorName: 'David Lappartient',
    headquarters: 'Aigle, Szwajcaria',
    countryIso: 'CH',
    philosophy:
        'Globalna promocja kolarstwa szosowego na wszystkich kontynentach, równe szanse sportowe i bezwzględne przestrzeganie przepisów rankingowych.',
    wildcardSlotsDefault: 6,
    badgeColorHex: '#0085C7',
  );

  /// Zwraca właściwy podmiot organizacyjny dla danego wyścigu
  static RaceOrganizer getOrganizerForRace(TourRace race) {
    final id = race.id.toLowerCase();
    final country = race.countryIso.toUpperCase();

    // 1. ASO
    if (id.contains('tour_de_france') ||
        id.contains('roubaix') ||
        id.contains('liege') ||
        id.contains('fleche') ||
        id.contains('paris_nice') ||
        id.contains('dauphine')) {
      return organizerAso;
    }

    // 2. RCS Sport
    if (id.contains('giro') ||
        id.contains('primavera') ||
        id.contains('lombardia') ||
        id.contains('strade') ||
        id.contains('tirreno')) {
      return organizerRcs;
    }

    // 3. Unipublic
    if (id.contains('vuelta') ||
        id.contains('san_sebastian') ||
        id.contains('catalunya') ||
        id.contains('itzulia') ||
        id.contains('valencia') ||
        id.contains('mallorca')) {
      return organizerUnipublic;
    }

    // 4. Flanders Classics
    if (id.contains('flanders') ||
        id.contains('gent_wevelgem') ||
        id.contains('e3_flemish') ||
        id.contains('amstel')) {
      return organizerFlanders;
    }

    // 5. Swiss Cycling
    if (id.contains('suisse') || id.contains('romandie')) {
      return organizerSwiss;
    }

    // 6. Lang Team
    if (id.contains('tour_de_pologne') || country == 'PL') {
      return organizerLangTeam;
    }

    // Domyślny organizator UCI / lokalny
    return organizerUci;
  }

  // ===========================================================================
  // STATUS KWALIFIKACJI I PRAWA STARTU
  // ===========================================================================

  /// Ustala status uprawnień zespołu do startu w danym wyścigu
  static WildcardStatus determineWildcardStatus({
    required TourRace race,
    required CyclingTeam team,
    List<WildcardApplication> applications = const [],
  }) {
    // Sprawdzamy czy zespół już znajduje się na liście startowej wyścigu
    final isAlreadyRegistered = race.participatingTeamIds.contains(team.id);

    // Drużyny WorldTour mają automatyczny i obowiązkowy wstęp na wszystkie wyścigi WT
    if (team.division == TeamDivision.worldTour) {
      if (_isWorldTourLevelRace(race.uciCategory)) {
        return WildcardStatus.automaticEntry;
      }
      return isAlreadyRegistered ? WildcardStatus.automaticEntry : WildcardStatus.eligibleToApply;
    }

    // Sprawdzamy, czy zespół złożył wniosek o Dziką Kartę
    final existingApp = applications.firstWhere(
      (app) => app.raceId == race.id && app.teamId == team.id,
      orElse: () => WildcardApplication(
        id: '',
        raceId: '',
        raceName: '',
        teamId: '',
        teamName: '',
        applicationDate: DateTime(2000),
        status: WildcardStatus.notEligible,
        overallScore: 0,
        rankingScore: 0,
        nationalityScore: 0,
        combativityScore: 0,
        rosterStarScore: 0,
        directorQuote: '',
        officialLetter: '',
      ),
    );

    if (existingApp.id.isNotEmpty) {
      return existingApp.status;
    }

    // Jeśli zespół jest już zarejestrowany (np. przydzielono mu kartę na start sezonu)
    if (isAlreadyRegistered) {
      return WildcardStatus.granted;
    }

    // Reguły dla dywizji ProTeam:
    if (team.division == TeamDivision.proTeam) {
      if (race.isGrandTour || race.uciCategory == RaceCategory.monument) {
        return WildcardStatus.eligibleToApply;
      }
      if (race.uciCategory == RaceCategory.worldTourStageRace ||
          race.uciCategory == RaceCategory.worldTourOneDay) {
        return WildcardStatus.eligibleToApply;
      }
      // W ProSeries i Class 1 ProTeamy startują bezpośrednio
      return WildcardStatus.automaticEntry;
    }

    // Reguły dla dywizji Continental:
    if (team.division == TeamDivision.continental) {
      // Grand Toury i Monumenty są całkowicie zablokowane dla Continental
      if (race.isGrandTour || race.uciCategory == RaceCategory.monument) {
        return WildcardStatus.notEligible;
      }
      // W wyścigach WorldTour Continental nie mogą brać udziału wg regulaminu UCI
      if (_isWorldTourLevelRace(race.uciCategory)) {
        return WildcardStatus.notEligible;
      }
      // W wyścigach Class 1 oraz krajowych ProSeries mają prawo ubiegać się lub startować
      if (race.countryIso == team.countryIso) {
        return WildcardStatus.automaticEntry;
      }
      return WildcardStatus.eligibleToApply;
    }

    return WildcardStatus.notEligible;
  }

  static bool _isWorldTourLevelRace(RaceCategory cat) {
    return cat == RaceCategory.grandTour ||
        cat == RaceCategory.monument ||
        cat == RaceCategory.worldTourStageRace ||
        cat == RaceCategory.worldTourOneDay;
  }

  // ===========================================================================
  // EWALUACJA WNIOSKU O DZIKĄ KARTĘ
  // ===========================================================================

  /// Wylicza szczegółową ocenę wniosku zespołu o dziką kartę na podstawie 4 filarów
  static WildcardEvaluation evaluateWildcardApplication({
    required CareerSave save,
    required TourRace race,
    required CyclingTeam team,
  }) {
    final organizer = getOrganizerForRace(race);
    final teamRiders = save.riders.where((r) => team.rosterRiderIds.contains(r.id)).toList();

    // -------------------------------------------------------------------------
    // 1. FILAR: RANKING UCI I PUNKTY W SEZONIE (Waga 35%)
    // -------------------------------------------------------------------------
    final proTeams = save.teams.where((t) => t.division == TeamDivision.proTeam).toList();
    proTeams.sort((a, b) => b.uciPointsSeason.compareTo(a.uciPointsSeason));
    final teamRankInProTeam = proTeams.indexWhere((t) => t.id == team.id);

    double rankingScore;
    if (teamRankInProTeam == 0) {
      rankingScore = 98.0; // Top 1 ProTeam
    } else if (teamRankInProTeam == 1) {
      rankingScore = 93.0; // Top 2 ProTeam (często obligatoryjne zaproszenie)
    } else if (teamRankInProTeam <= 3) {
      rankingScore = 86.0;
    } else if (teamRankInProTeam <= 6) {
      rankingScore = 74.0;
    } else if (teamRankInProTeam <= 10) {
      rankingScore = 58.0;
    } else {
      rankingScore = (35.0 + (team.uciPointsSeason / 1200.0) * 20.0).clamp(25.0, 52.0);
    }

    // -------------------------------------------------------------------------
    // 2. FILAR: DOPASOWANIE NARODOWOŚCI I POWIĄZANIA LOKALNE (Waga 30%)
    // -------------------------------------------------------------------------
    double nationalityScore = 25.0; // Wartość bazowa dla ekipy międzynarodowej
    final isHomeNationTeam = team.countryIso.toUpperCase() == race.countryIso.toUpperCase();
    final isOrganizerNationMatch = team.countryIso.toUpperCase() == organizer.countryIso.toUpperCase();

    if (isHomeNationTeam) {
      nationalityScore += 45.0;
    } else if (isOrganizerNationMatch) {
      nationalityScore += 30.0;
    }

    // Sprawdzamy sponsorów
    for (final sponsor in team.sponsors) {
      if (sponsor.sponsorName.toLowerCase().contains(race.countryIso.toLowerCase()) ||
          sponsor.importanceTier.index >= 1) {
        nationalityScore += 10.0;
        break;
      }
    }

    // Liczba kolarzy z kraju gospodarza wyścigu
    final localRidersCount = teamRiders
        .where((r) => r.nationalityIso.toUpperCase() == race.countryIso.toUpperCase())
        .length;
    nationalityScore += (localRidersCount * 4.0).clamp(0.0, 20.0);
    nationalityScore = nationalityScore.clamp(20.0, 100.0);

    // -------------------------------------------------------------------------
    // 3. FILAR: WALECZNOŚĆ, UCIECZKI I HARCOWNICY (Waga 20%)
    // -------------------------------------------------------------------------
    int breakawaySpecialists = 0;
    int punchers = 0;
    double sumRaceIq = 0.0;
    double sumHandling = 0.0;

    for (final r in teamRiders) {
      if (r.specialization == RiderSpecialization.breakawaySpecialist) {
        breakawaySpecialists++;
      } else if (r.specialization == RiderSpecialization.puncher) {
        punchers++;
      }
      sumRaceIq += r.skills.raceIq;
      sumHandling += r.skills.bikeHandling;
    }

    final avgRaceIq = teamRiders.isNotEmpty ? sumRaceIq / teamRiders.length : 60.0;
    final avgHandling = teamRiders.isNotEmpty ? sumHandling / teamRiders.length : 60.0;

    double combativityScore = 40.0;
    combativityScore += (breakawaySpecialists * 10.0).clamp(0.0, 30.0);
    combativityScore += (punchers * 4.0).clamp(0.0, 15.0);
    combativityScore += ((avgRaceIq - 60.0) * 0.5).clamp(0.0, 10.0);
    combativityScore += ((avgHandling - 60.0) * 0.5).clamp(0.0, 10.0);

    // Menedżer o wysokiej reputacji daje gwarancję widowiska
    combativityScore += (save.managerReputation / 100.0 * 10.0);
    combativityScore = combativityScore.clamp(25.0, 100.0);

    // -------------------------------------------------------------------------
    // 4. FILAR: GWIAZDY W SKŁADZIE I JAKOŚĆ ROSTERU (Waga 15%)
    // -------------------------------------------------------------------------
    int topRiderOvr = 0;
    int worldClassRidersCount = 0;
    int youngTalentsCount = 0;

    for (final r in teamRiders) {
      final ovr = r.overallRating;
      if (ovr > topRiderOvr) topRiderOvr = ovr;
      if (ovr >= 80) worldClassRidersCount++;
      if (r.age <= 23 && r.potential >= 82) youngTalentsCount++;
    }

    double rosterStarScore = 30.0;
    if (topRiderOvr >= 85) {
      rosterStarScore += 45.0;
    } else if (topRiderOvr >= 80) {
      rosterStarScore += 32.0;
    } else if (topRiderOvr >= 75) {
      rosterStarScore += 18.0;
    }

    rosterStarScore += (worldClassRidersCount * 6.0).clamp(0.0, 18.0);
    rosterStarScore += (youngTalentsCount * 3.0).clamp(0.0, 12.0);
    rosterStarScore = rosterStarScore.clamp(20.0, 100.0);

    // -------------------------------------------------------------------------
    // OBLICZENIE ŁĄCZNEJ OCENY KOŃCOWEJ
    // -------------------------------------------------------------------------
    final overallScore = (rankingScore * 0.35) +
        (nationalityScore * 0.30) +
        (combativityScore * 0.20) +
        (rosterStarScore * 0.15);

    // Próg akceptacji: dla Grand Touru (min. 66 pkt), Monumentu (min. 58 pkt), WT (min. 52 pkt)
    final double acceptanceThreshold = race.isGrandTour
        ? 65.0
        : (race.uciCategory == RaceCategory.monument ? 58.0 : 52.0);

    final isApproved = overallScore >= acceptanceThreshold;

    // Generowanie mocnych i słabych stron
    final List<String> strengths = [];
    final List<String> weaknesses = [];

    if (rankingScore >= 80) {
      strengths.add('Czołowa lokata w rankingu punktowym ProTeam (#${teamRankInProTeam + 1})');
    } else if (rankingScore < 50) {
      weaknesses.add('Niska suma punktów UCI w bieżącym sezonie');
    }

    if (nationalityScore >= 70) {
      strengths.add('Silne zakorzenienie w kraju wyścigu (${race.countryIso}) i lokalni sponsorzy');
    } else if (nationalityScore < 40) {
      weaknesses.add('Brak powiązań narodowych z krajem gospodarza wyścigu');
    }

    if (combativityScore >= 75) {
      strengths.add('Profil ofensywny: liczne grono harcowników i specjalistów ucieczek');
    } else if (combativityScore < 45) {
      weaknesses.add('Pasywny styl jazdy z małą liczbą kolarzy zabierających się w odjazdy');
    }

    if (rosterStarScore >= 70) {
      strengths.add('Obecność w składzie rozpoznawalnych gwiazd peletonu (OVR: $topRiderOvr)');
    } else if (rosterStarScore < 45) {
      weaknesses.add('Brak głośnych nazwisk przyciągających uwagę mediów i kibiców');
    }

    // Generowanie autentycznego cytatu dyrektora i listu
    final quote = _generateDirectorQuote(
      organizer: organizer,
      race: race,
      team: team,
      isApproved: isApproved,
      topRiderOvr: topRiderOvr,
    );

    final letter = _generateOfficialLetter(
      organizer: organizer,
      race: race,
      team: team,
      isApproved: isApproved,
      overallScore: overallScore,
      strengths: strengths,
      weaknesses: weaknesses,
    );

    return WildcardEvaluation(
      isApproved: isApproved,
      overallScore: overallScore,
      rankingScore: rankingScore,
      nationalityScore: nationalityScore,
      combativityScore: combativityScore,
      rosterStarScore: rosterStarScore,
      directorQuote: quote,
      officialLetter: letter,
      strengths: strengths,
      weaknesses: weaknesses,
    );
  }

  // ===========================================================================
  // APLIKOWANIE O DZIKĄ KARTĘ PRZEZ GRACZA
  // ===========================================================================

  /// Składa oficjalny wniosek drużyny gracza o Dziką Kartę na dany wyścig
  static CareerSave applyForWildcard({
    required CareerSave save,
    required String raceId,
  }) {
    final race = save.calendar.getRaceById(raceId);
    if (race == null) {
      throw ArgumentError('Nie znaleziono wyścigu o ID: $raceId');
    }

    final team = save.playerTeam;

    // Sprawdzamy czy zespół już ma wniosek
    final hasAlreadyApplied = save.wildcardApplications.any(
      (app) => app.raceId == raceId && app.teamId == team.id,
    );
    if (hasAlreadyApplied) {
      return save; // Już złożono wniosek
    }

    // Dokonujemy pełnej ewaluacji wniosku
    final evaluation = evaluateWildcardApplication(
      save: save,
      race: race,
      team: team,
    );

    final newStatus = evaluation.isApproved ? WildcardStatus.granted : WildcardStatus.rejected;

    final application = WildcardApplication(
      id: 'wc_${race.id}_${team.id}_${save.currentSeasonYear}',
      raceId: race.id,
      raceName: race.name,
      teamId: team.id,
      teamName: team.name,
      applicationDate: save.currentDate,
      status: newStatus,
      overallScore: evaluation.overallScore,
      rankingScore: evaluation.rankingScore,
      nationalityScore: evaluation.nationalityScore,
      combativityScore: evaluation.combativityScore,
      rosterStarScore: evaluation.rosterStarScore,
      directorQuote: evaluation.directorQuote,
      officialLetter: evaluation.officialLetter,
      decisionDate: save.currentDate,
    );

    final updatedApplications = [application, ...save.wildcardApplications];

    // Jeśli wniosek zaakceptowany, dodajemy drużynę do listy uczestników wyścigu
    List<TourRace> updatedRaces = save.calendar.races;
    if (evaluation.isApproved) {
      updatedRaces = save.calendar.races.map((r) {
        if (r.id == race.id) {
          final currentParticipants = List<String>.from(r.participatingTeamIds);
          if (!currentParticipants.contains(team.id)) {
            currentParticipants.add(team.id);
          }
          return r.copyWith(participatingTeamIds: currentParticipants);
        }
        return r;
      }).toList();
    }

    final updatedCalendar = save.calendar.copyWith(races: updatedRaces);

    return save.copyWith(
      wildcardApplications: updatedApplications,
      calendar: updatedCalendar,
      lastSavedAt: DateTime.now(),
    );
  }

  // ===========================================================================
  // REJESTRACJA I WYCOFANIE Z WYŚCIGU
  // ===========================================================================

  /// Rejestruje drużynę w wyścigu (np. dla ProSeries lub wyścigów, gdzie zespół ma automatyczny wstęp)
  static CareerSave registerTeamForRace({
    required CareerSave save,
    required String raceId,
  }) {
    final teamId = save.playerTeamId;
    final updatedRaces = save.calendar.races.map((r) {
      if (r.id == raceId) {
        final currentParticipants = List<String>.from(r.participatingTeamIds);
        if (!currentParticipants.contains(teamId)) {
          currentParticipants.add(teamId);
        }
        return r.copyWith(participatingTeamIds: currentParticipants);
      }
      return r;
    }).toList();

    return save.copyWith(
      calendar: save.calendar.copyWith(races: updatedRaces),
      lastSavedAt: DateTime.now(),
    );
  }

  /// Wycofuje drużynę z wyścigu nieobowiązkowego
  static CareerSave withdrawTeamFromRace({
    required CareerSave save,
    required String raceId,
  }) {
    final race = save.calendar.getRaceById(raceId);
    if (race == null) return save;

    // Zespoły WorldTour nie mogą wycofać się z wyścigów rangi WorldTour
    if (save.playerTeam.division == TeamDivision.worldTour &&
        _isWorldTourLevelRace(race.uciCategory)) {
      throw StateError(
        'Regulamin UCI: Zespoły dywizji WorldTour mają bezwzględny obowiązek startu we wszystkich wyścigach WorldTour!',
      );
    }

    final teamId = save.playerTeamId;
    final updatedRaces = save.calendar.races.map((r) {
      if (r.id == raceId) {
        final currentParticipants = List<String>.from(r.participatingTeamIds)
          ..remove(teamId);
        return r.copyWith(participatingTeamIds: currentParticipants);
      }
      return r;
    }).toList();

    return save.copyWith(
      calendar: save.calendar.copyWith(races: updatedRaces),
      lastSavedAt: DateTime.now(),
    );
  }

  // ===========================================================================
  // SYMULACJA PRZYZNAWANIA DZIKICH KART DLA CAŁEGO PELETONU (AI TEAMS)
  // ===========================================================================

  /// Przeprowadza całościową alokację dzikich kart dla wszystkich Grand Tourów i Monumentów
  /// pomiędzy ubiegającymi się drużynami ProTeam.
  static CareerSave simulateSeasonWildcardAllocation({
    required CareerSave save,
  }) {
    final wtTeams = save.teams.where((t) => t.division == TeamDivision.worldTour).toList();
    final proTeams = save.teams.where((t) => t.division == TeamDivision.proTeam).toList();

    final wtTeamIds = wtTeams.map((t) => t.id).toList();
    List<WildcardApplication> allApplications = List.from(save.wildcardApplications);
    List<TourRace> updatedRaces = [];

    for (final race in save.calendar.races) {
      if (!_isWorldTourLevelRace(race.uciCategory)) {
        updatedRaces.add(race);
        continue;
      }

      final wildcardSlots = race.isGrandTour ? 4 : (race.uciCategory == RaceCategory.monument ? 7 : 5);

      // Start listę rozpoczynamy od 18 ekip WorldTour
      final Set<String> startingTeamIds = Set.from(wtTeamIds);

      // Oceniamy wszystkie ProTeamy
      final List<_ApplicantScore> scores = [];
      for (final proTeam in proTeams) {
        // Sprawdzamy czy drużyna gracza już ma wniosek
        final existingApp = allApplications.firstWhere(
          (a) => a.raceId == race.id && a.teamId == proTeam.id,
          orElse: () => WildcardApplication(
            id: '',
            raceId: '',
            raceName: '',
            teamId: '',
            teamName: '',
            applicationDate: DateTime(2000),
            status: WildcardStatus.pending,
            overallScore: 0,
            rankingScore: 0,
            nationalityScore: 0,
            combativityScore: 0,
            rosterStarScore: 0,
            directorQuote: '',
            officialLetter: '',
          ),
        );

        if (existingApp.id.isNotEmpty && existingApp.status == WildcardStatus.granted) {
          startingTeamIds.add(proTeam.id);
          continue;
        }

        final eval = evaluateWildcardApplication(
          save: save,
          race: race,
          team: proTeam,
        );

        scores.add(_ApplicantScore(
          team: proTeam,
          evaluation: eval,
        ));
      }

      // Sortujemy kandydatów wg punktacji łącznej
      scores.sort((a, b) => b.evaluation.overallScore.compareTo(a.evaluation.overallScore));

      // Przyznajemy dzikie karty najlepszym zespołom do wyczerpania limitu
      int grantedCount = 0;
      for (final applicant in scores) {
        final isApproved = grantedCount < wildcardSlots && applicant.evaluation.isApproved;
        if (isApproved) {
          startingTeamIds.add(applicant.team.id);
          grantedCount++;
        }

        // Zapisujemy wniosek dla drużyny gracza jeśli dotyczy
        if (applicant.team.id == save.playerTeamId) {
          final playerApp = WildcardApplication(
            id: 'wc_${race.id}_${applicant.team.id}_${save.currentSeasonYear}',
            raceId: race.id,
            raceName: race.name,
            teamId: applicant.team.id,
            teamName: applicant.team.name,
            applicationDate: save.currentDate,
            status: isApproved ? WildcardStatus.granted : WildcardStatus.rejected,
            overallScore: applicant.evaluation.overallScore,
            rankingScore: applicant.evaluation.rankingScore,
            nationalityScore: applicant.evaluation.nationalityScore,
            combativityScore: applicant.evaluation.combativityScore,
            rosterStarScore: applicant.evaluation.rosterStarScore,
            directorQuote: applicant.evaluation.directorQuote,
            officialLetter: applicant.evaluation.officialLetter,
            decisionDate: save.currentDate,
          );
          allApplications.removeWhere((a) => a.raceId == race.id && a.teamId == applicant.team.id);
          allApplications.add(playerApp);
        }
      }

      updatedRaces.add(race.copyWith(participatingTeamIds: startingTeamIds.toList()));
    }

    return save.copyWith(
      calendar: save.calendar.copyWith(races: updatedRaces),
      wildcardApplications: allApplications,
      lastSavedAt: DateTime.now(),
    );
  }

  // ===========================================================================
  // PRZEGLĄD KALENDARZA DLA DRUŻYNY
  // ===========================================================================

  /// Buduje pełną listę wyścigów z kalkulacją statusów dzikich kart dla zespołu
  static List<TeamRaceCalendarEntry> getCalendarOverviewForTeam({
    required CareerSave save,
    required String teamId,
  }) {
    final team = save.teams.firstWhere(
      (t) => t.id == teamId,
      orElse: () => save.playerTeam,
    );

    return save.calendar.races.map((race) {
      final organizer = getOrganizerForRace(race);
      final status = determineWildcardStatus(
        race: race,
        team: team,
        applications: save.wildcardApplications,
      );

      final app = save.wildcardApplications.cast<WildcardApplication?>().firstWhere(
            (a) => a?.raceId == race.id && a?.teamId == team.id,
            orElse: () => null,
          );

      final isRegistered = race.participatingTeamIds.contains(team.id);
      final isMandatory =
          team.division == TeamDivision.worldTour && _isWorldTourLevelRace(race.uciCategory);

      // Szacowany koszt logistyczny (hotele, transport, obsługa serwisowa)
      final estimatedLogisticsCostEur = race.stages.length * 3500 + 4000;

      return TeamRaceCalendarEntry(
        race: race,
        organizer: organizer,
        status: status,
        application: app,
        isMandatory: isMandatory,
        isRegistered: isRegistered,
        estimatedLogisticsCostEur: estimatedLogisticsCostEur,
      );
    }).toList();
  }

  // ===========================================================================
  // GENERATORY CYTATÓW I LISTÓW OFICJALNYCH
  // ===========================================================================

  static String _generateDirectorQuote({
    required RaceOrganizer organizer,
    required TourRace race,
    required CyclingTeam team,
    required bool isApproved,
    required int topRiderOvr,
  }) {
    if (isApproved) {
      switch (organizer.id) {
        case RaceOrganizerType.aso:
          return '„Tour de France i klasyki A.S.O. to kwintesencja heroizmu. Postawa ${team.name} i Wasza bezkompromisowa wola walki w ucieczkach gwarantują kibicom spektakl na najwyższym poziomie!” – ${organizer.directorName}';
        case RaceOrganizerType.rcsSport:
          return '„Corsa Rosa z dumą wita ${team.name}! Włoscy tifosi oczekują od Was odważnych szarż na przełęczach i walki o maglia azzurra od pierwszego etapu!” – ${organizer.directorName}';
        case RaceOrganizerType.unipublic:
          return '„La Vuelta to wyścig z pasją, gdzie decydują strome ścianki i gorące serca. Wasz skład idealnie wpisuje się w drapieżny charakter hiszpańskiego peletonu!” – ${organizer.directorName}';
        case RaceOrganizerType.flandersClassics:
          return '„Flandria to świątynia wiatru i bruku. ${team.name} ma charakter z żelaza, by zmierzyć się z Oude Kwaremont i Taaienbergiem. Do zobaczenia na trasie!” – ${organizer.directorName}';
        case RaceOrganizerType.swissCycling:
          return '„Z wielką przyjemnością potwierdzamy zaproszenie dla ${team.name}. Liczymy na znakomite występy na alpejskich czasówkach!” – ${organizer.directorName}';
        case RaceOrganizerType.langTeam:
          return '„Tour de Pologne to kuźnia talentów i wielkie święto sportu. Z radością witamy Waszą ekipę na polskich szosach!” – ${organizer.directorName}';
        case RaceOrganizerType.uciGlobal:
          return '„Komitet organizacyjny z satysfakcją przyznaje dziką kartę dla ${team.name}. Życzymy udanej i bezpiecznej rywalizacji!” – ${organizer.directorName}';
      }
    } else {
      switch (organizer.id) {
        case RaceOrganizerType.aso:
          return '„Liczba zaproszeń na ${race.name} jest ściśle ograniczona. Musieliśmy dokonać bolesnych wyborów na korzyść drużyn wyżej sklasyfikowanych w rankingu UCI.” – ${organizer.directorName}';
        case RaceOrganizerType.rcsSport:
          return '„Tegoroczny limit dzikich kart zmusił nas do faworyzowania ekip o silniejszych korzeniach lokalnych. Drzwi na przyszłość pozostają otwarte.” – ${organizer.directorName}';
        case RaceOrganizerType.unipublic:
          return '„Rywalizacja o 4 dzikie karty na La Vueltę była niezwykle zacięta. Zabrakło Wam zaledwie kilku punktów do wejścia na ostateczną listę startową.” – ${organizer.directorName}';
        case RaceOrganizerType.flandersClassics:
          return '„Na brukach ${race.name} możemy pomieścić ograniczoną liczbę ekip. Zachęcamy do walki o punkty w pozostałych klasykach ProSeries.” – ${organizer.directorName}';
        case RaceOrganizerType.swissCycling:
        case RaceOrganizerType.langTeam:
        case RaceOrganizerType.uciGlobal:
          return '„Komitet organizacyjny z żalem informuje, że wniosek ${team.name} nie został zakwalifikowany do tegorocznej edycji wyścigu.” – ${organizer.directorName}';
      }
    }
  }

  static String _generateOfficialLetter({
    required RaceOrganizer organizer,
    required TourRace race,
    required CyclingTeam team,
    required bool isApproved,
    required double overallScore,
    required List<String> strengths,
    required List<String> weaknesses,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('KOMITET ORGANIZACYJNY: ${organizer.name.toUpperCase()}');
    buffer.writeln('Siedziba: ${organizer.headquarters}');
    buffer.writeln('Dotyczy: Wniosek o Dziką Kartę (Wildcard) na ${race.name}');
    buffer.writeln('Adresat: Dyrekcja Sportowa zespołu ${team.name}');
    buffer.writeln('Ocena punktowa wniosku: ${overallScore.toStringAsFixed(1)} / 100 pkt\n');

    if (isApproved) {
      buffer.writeln('Szanowni Państwo,');
      buffer.writeln(
        'Z ogromną przyjemnością informujemy, że komitet selekcyjny pod przewodnictwem dyrektora ${organizer.directorName} podjął jednogłośną decyzję o PRZYZNANIU Państwa drużynie oficjalnej Dzikiej Karty (Wildcard) na tegoroczną edycję wyścigu ${race.name}.',
      );
      buffer.writeln(
        '\nO decyzji zadecydował wysoki dorobek punktowy, ofensywna charakterystyka składu oraz wola walki w ucieczkach, która gwarantuje widzom telewizyjnym najwyższe emocje sportowe.',
      );
      if (strengths.isNotEmpty) {
        buffer.writeln('\nKluczowe atuty Państwa kandydatury:');
        for (final s in strengths) {
          buffer.writeln(' • $s');
        }
      }
      buffer.writeln(
        '\nProsimy o zgłoszenie ostatecznego składu (${race.ridersPerTeam} kolarzy) najpóźniej na 72 godziny przed startem etapu otwarcia.',
      );
      buffer.writeln('\nZ kolarskim pozdrowieniem,');
      buffer.writeln('${organizer.directorName}\nDyrektor Generalny ${organizer.name}');
    } else {
      buffer.writeln('Szanowni Państwo,');
      buffer.writeln(
        'Uprzejmie informujemy, że po wnikliwej analizie wszystkich zgłoszeń na wyścig ${race.name}, komitet selekcyjny NIE MÓGŁ w bieżącym roku uwzględnić Państwa kandydatury w gronie zaproszonych zespołów.',
      );
      buffer.writeln(
        '\nZe względu na restrykcyjne przepisy bezpieczeństwa UCI oraz ograniczoną pulę dzikich kart, pierwszeństwo otrzymały zespoły legitymujące się wyższym dorobkiem punktowym oraz ściślejszymi powiązaniami z lokalnym rynkiem kolarskim.',
      );
      if (weaknesses.isNotEmpty) {
        buffer.writeln('\nObszary wymagające poprawy na przyszłość:');
        for (final w in weaknesses) {
          buffer.writeln(' • $w');
        }
      }
      buffer.writeln(
        '\nDoceniamy profesjonalizm Państwa projektu i liczymy na Państwa starty w kolejnych sezonach.',
      );
      buffer.writeln('\nZ wyrazami szacunku,');
      buffer.writeln('${organizer.directorName}\nDyrektor Generalny ${organizer.name}');
    }

    return buffer.toString();
  }
}

class _ApplicantScore {
  final CyclingTeam team;
  final WildcardEvaluation evaluation;

  _ApplicantScore({
    required this.team,
    required this.evaluation,
  });
}

