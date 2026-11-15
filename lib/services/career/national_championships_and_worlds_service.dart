// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import '../../models/rider/rider.dart';

/// Dyscyplina mistrzostw kolarskich (start wspólny vs jazda na czas).
enum ChampionshipDiscipline {
  /// Wyścig ze startu wspólnego (Road Race - wyścig klasyczny / runda mistrzowska)
  roadRace('Wyścig ze startu wspólnego', 'Road Race', IconsCode.pedalBike),

  /// Indywidualna jazda na czas (Individual Time Trial - ITT)
  individualTimeTrial('Jazda indywidualna na czas', 'Individual Time Trial (ITT)', IconsCode.timer);

  final String polishLabel;
  final String englishLabel;
  final String iconName;

  const ChampionshipDiscipline(this.polishLabel, this.englishLabel, this.iconName);

  String toJson() => name;

  static ChampionshipDiscipline fromJson(String value) {
    return ChampionshipDiscipline.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ChampionshipDiscipline.roadRace,
    );
  }
}

/// Pomocnicze stałe identyfikatorów ikon bez zależności od Flutter UI.
class IconsCode {
  static const String pedalBike = 'pedal_bike';
  static const String timer = 'timer';
  static const String flag = 'flag';
  static const String trophy = 'emoji_events';
}

/// Poziom mistrzostw (Krajowe w czerwcu vs Światowe we wrześniu).
enum ChampionshipLevel {
  /// Mistrzostwa Krajowe (koniec czerwca, przed Tour de France)
  national('Mistrzostwa Krajowe', 'National Championships', 6),

  /// Mistrzostwa Świata UCI (koniec września, po Vuelcie)
  world('Mistrzostwa Świata UCI', 'UCI World Championships', 9);

  final String polishTitle;
  final String englishTitle;
  final int calendarMonth;

  const ChampionshipLevel(this.polishTitle, this.englishTitle, this.calendarMonth);

  String toJson() => name;

  static ChampionshipLevel fromJson(String value) {
    return ChampionshipLevel.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ChampionshipLevel.national,
    );
  }
}

/// Status koszulki specjalnej przysługującej kolarzowi w peletonie.
enum SpecialJerseyDesignation {
  /// Tęczowa koszulka aktualnego Mistrza Świata UCI (Rainbow Jersey)
  rainbowJersey,

  /// Koszulka aktualnego Mistrza Kraju (National Champion Jersey)
  nationalChampionJersey,

  /// Paski byłego mistrza świata na mankietach rękawków i kołnierzyku (Rainbow Sleeve Bands)
  formerWorldChampionRainbowBands,

  /// Standardowy strój ekipy zawodowej (Trade Team Jersey)
  standardTeamJersey;

  String toJson() => name;

  static SpecialJerseyDesignation fromJson(String value) {
    return SpecialJerseyDesignation.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SpecialJerseyDesignation.standardTeamJersey,
    );
  }
}

/// Tytuł mistrzowski zdobyty przez kolarza w danym sezonie.
class ChampionshipTitle {
  final int year;
  final ChampionshipLevel level;
  final ChampionshipDiscipline discipline;
  final String countryIso; // 'WORLD' dla MŚ lub kod kraju (np. 'POL', 'FRA')
  final String winnerRiderId;
  final String winnerRiderName;
  final String winningTradeTeamName;
  final DateTime dateAwarded;
  final int uciPointsAwarded;

  const ChampionshipTitle({
    required this.year,
    required this.level,
    required this.discipline,
    required this.countryIso,
    required this.winnerRiderId,
    required this.winnerRiderName,
    required this.winningTradeTeamName,
    required this.dateAwarded,
    required this.uciPointsAwarded,
  });

  Map<String, dynamic> toJson() => {
    'year': year,
    'level': level.toJson(),
    'discipline': discipline.toJson(),
    'countryIso': countryIso,
    'winnerRiderId': winnerRiderId,
    'winnerRiderName': winnerRiderName,
    'winningTradeTeamName': winningTradeTeamName,
    'dateAwarded': dateAwarded.toIso8601String(),
    'uciPointsAwarded': uciPointsAwarded,
  };

  factory ChampionshipTitle.fromJson(Map<String, dynamic> json) => ChampionshipTitle(
    year: (json['year'] as num).toInt(),
    level: ChampionshipLevel.fromJson(json['level'] as String),
    discipline: ChampionshipDiscipline.fromJson(json['discipline'] as String),
    countryIso: json['countryIso'] as String,
    winnerRiderId: json['winnerRiderId'] as String,
    winnerRiderName: json['winnerRiderName'] as String,
    winningTradeTeamName: json['winningTradeTeamName'] as String? ?? 'Team',
    dateAwarded: DateTime.parse(json['dateAwarded'] as String),
    uciPointsAwarded: (json['uciPointsAwarded'] as num).toInt(),
  );
}

/// Wynik kolarza na mecie wyścigu mistrzowskiego.
class ChampionshipPodiumResult {
  final int rank;
  final String riderId;
  final String riderName;
  final String nationalityIso;
  final String tradeTeamName;
  final Duration finishTime;
  final Duration timeGapToWinner;
  final int uciPoints;

  const ChampionshipPodiumResult({
    required this.rank,
    required this.riderId,
    required this.riderName,
    required this.nationalityIso,
    required this.tradeTeamName,
    required this.finishTime,
    required this.timeGapToWinner,
    required this.uciPoints,
  });

  bool get isGold => rank == 1;
  bool get isSilver => rank == 2;
  bool get isBronze => rank == 3;

  Map<String, dynamic> toJson() => {
    'rank': rank,
    'riderId': riderId,
    'riderName': riderName,
    'nationalityIso': nationalityIso,
    'tradeTeamName': tradeTeamName,
    'finishTimeMs': finishTime.inMilliseconds,
    'timeGapMs': timeGapToWinner.inMilliseconds,
    'uciPoints': uciPoints,
  };

  factory ChampionshipPodiumResult.fromJson(Map<String, dynamic> json) =>
      ChampionshipPodiumResult(
        rank: (json['rank'] as num).toInt(),
        riderId: json['riderId'] as String,
        riderName: json['riderName'] as String,
        nationalityIso: json['nationalityIso'] as String,
        tradeTeamName: json['tradeTeamName'] as String? ?? 'Trade Team',
        finishTime: Duration(milliseconds: (json['finishTimeMs'] as num).toInt()),
        timeGapToWinner: Duration(milliseconds: (json['timeGapMs'] as num).toInt()),
        uciPoints: (json['uciPoints'] as num).toInt(),
      );
}

/// Pełny rezultat wyścigu mistrzowskiego (krajowego lub mistrzostw świata).
class ChampionshipRaceResult {
  final String raceId;
  final int year;
  final ChampionshipLevel level;
  final ChampionshipDiscipline discipline;
  final String countryIso;
  final String raceName;
  final String hostCity;
  final double distanceKm;
  final List<ChampionshipPodiumResult> results;

  const ChampionshipRaceResult({
    required this.raceId,
    required this.year,
    required this.level,
    required this.discipline,
    required this.countryIso,
    required this.raceName,
    required this.hostCity,
    required this.distanceKm,
    required this.results,
  });

  ChampionshipPodiumResult get winner => results.first;

  Map<String, dynamic> toJson() => {
    'raceId': raceId,
    'year': year,
    'level': level.toJson(),
    'discipline': discipline.toJson(),
    'countryIso': countryIso,
    'raceName': raceName,
    'hostCity': hostCity,
    'distanceKm': distanceKm,
    'results': results.map((r) => r.toJson()).toList(),
  };

  factory ChampionshipRaceResult.fromJson(Map<String, dynamic> json) =>
      ChampionshipRaceResult(
        raceId: json['raceId'] as String,
        year: (json['year'] as num).toInt(),
        level: ChampionshipLevel.fromJson(json['level'] as String),
        discipline: ChampionshipDiscipline.fromJson(json['discipline'] as String),
        countryIso: json['countryIso'] as String,
        raceName: json['raceName'] as String,
        hostCity: json['hostCity'] as String,
        distanceKm: (json['distanceKm'] as num).toDouble(),
        results: (json['results'] as List<dynamic>)
            .map((e) => ChampionshipPodiumResult.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Skład reprezentacji narodowej na Mistrzostwa Świata.
class NationalTeamSelection {
  final String countryIso;
  final String countryName;
  final List<Rider> selectedRiders;
  final String teamLeaderRiderId;
  final int teamQuota;

  const NationalTeamSelection({
    required this.countryIso,
    required this.countryName,
    required this.selectedRiders,
    required this.teamLeaderRiderId,
    required this.teamQuota,
  });

  Rider get leader => selectedRiders.firstWhere(
        (r) => r.id == teamLeaderRiderId,
        orElse: () => selectedRiders.first,
      );
}

/// Rejestr aktualnie panujących mistrzów świata i krajowych oraz archiwum historyczne.
class ReigningChampionsRegistry {
  /// Aktualni mistrzowie kraju ze startu wspólnego (kod kraju -> Tytuł)
  final Map<String, ChampionshipTitle> nationalRoadChampions;

  /// Aktualni mistrzowie kraju w ITT (kod kraju -> Tytuł)
  final Map<String, ChampionshipTitle> nationalIttChampions;

  /// Aktualny Mistrz Świata ze startu wspólnego (Rainbow Jersey)
  ChampionshipTitle? reigningWorldRoadChampion;

  /// Aktualny Mistrz Świata w ITT (Rainbow ITT Suit)
  ChampionshipTitle? reigningWorldIttChampion;

  /// Lista kolarzy, którzy w przeszłości zdobyli mistrzostwo świata i mają dożywotnie paski na mankietach
  final List<String> lifetimeWorldChampionRiderIds;

  /// Pełne archiwum historyczne tytułów sezon po sezonie
  final List<ChampionshipTitle> historicalTitlesArchive;

  ReigningChampionsRegistry({
    Map<String, ChampionshipTitle>? nationalRoadChampions,
    Map<String, ChampionshipTitle>? nationalIttChampions,
    this.reigningWorldRoadChampion,
    this.reigningWorldIttChampion,
    List<String>? lifetimeWorldChampionRiderIds,
    List<ChampionshipTitle>? historicalTitlesArchive,
  })  : nationalRoadChampions = nationalRoadChampions ?? {},
        nationalIttChampions = nationalIttChampions ?? {},
        lifetimeWorldChampionRiderIds = lifetimeWorldChampionRiderIds ?? [],
        historicalTitlesArchive = historicalTitlesArchive ?? [];

  /// Rejestruje nowego mistrza kraju
  void registerNationalChampion(ChampionshipTitle title) {
    if (title.discipline == ChampionshipDiscipline.roadRace) {
      nationalRoadChampions[title.countryIso.toUpperCase()] = title;
    } else {
      nationalIttChampions[title.countryIso.toUpperCase()] = title;
    }
    historicalTitlesArchive.add(title);
  }

  /// Rejestruje nowego mistrza świata
  void registerWorldChampion(ChampionshipTitle title) {
    if (title.discipline == ChampionshipDiscipline.roadRace) {
      reigningWorldRoadChampion = title;
    } else {
      reigningWorldIttChampion = title;
    }
    if (!lifetimeWorldChampionRiderIds.contains(title.winnerRiderId)) {
      lifetimeWorldChampionRiderIds.add(title.winnerRiderId);
    }
    historicalTitlesArchive.add(title);
  }

  /// Sprawdza, czy kolarz jest aktualnym Mistrzem Świata
  bool isReigningWorldChampion(String riderId, {bool isTimeTrial = false}) {
    final champ = isTimeTrial ? reigningWorldIttChampion : reigningWorldRoadChampion;
    return champ != null && champ.winnerRiderId == riderId;
  }

  /// Sprawdza, czy kolarz jest aktualnym Mistrzem swojego Kraju
  bool isReigningNationalChampion(String riderId, String countryIso, {bool isTimeTrial = false}) {
    final map = isTimeTrial ? nationalIttChampions : nationalRoadChampions;
    final champ = map[countryIso.toUpperCase()];
    return champ != null && champ.winnerRiderId == riderId;
  }

  /// Sprawdza, czy kolarz był w przeszłości Mistrzem Świata i ma prawo do tęczowych pasków na mankietach
  bool isFormerWorldChampion(String riderId) {
    return lifetimeWorldChampionRiderIds.contains(riderId);
  }

  Map<String, dynamic> toJson() => {
    'nationalRoadChampions': nationalRoadChampions.map((k, v) => MapEntry(k, v.toJson())),
    'nationalIttChampions': nationalIttChampions.map((k, v) => MapEntry(k, v.toJson())),
    'reigningWorldRoadChampion': reigningWorldRoadChampion?.toJson(),
    'reigningWorldIttChampion': reigningWorldIttChampion?.toJson(),
    'lifetimeWorldChampionRiderIds': lifetimeWorldChampionRiderIds,
    'historicalTitlesArchive': historicalTitlesArchive.map((t) => t.toJson()).toList(),
  };

  factory ReigningChampionsRegistry.fromJson(Map<String, dynamic> json) {
    final registry = ReigningChampionsRegistry(
      lifetimeWorldChampionRiderIds: (json['lifetimeWorldChampionRiderIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      historicalTitlesArchive: (json['historicalTitlesArchive'] as List<dynamic>?)
              ?.map((e) => ChampionshipTitle.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

    if (json['nationalRoadChampions'] != null) {
      final map = json['nationalRoadChampions'] as Map<String, dynamic>;
      map.forEach((k, v) {
        registry.nationalRoadChampions[k] =
            ChampionshipTitle.fromJson(v as Map<String, dynamic>);
      });
    }

    if (json['nationalIttChampions'] != null) {
      final map = json['nationalIttChampions'] as Map<String, dynamic>;
      map.forEach((k, v) {
        registry.nationalIttChampions[k] =
            ChampionshipTitle.fromJson(v as Map<String, dynamic>);
      });
    }

    if (json['reigningWorldRoadChampion'] != null) {
      registry.reigningWorldRoadChampion =
          ChampionshipTitle.fromJson(json['reigningWorldRoadChampion'] as Map<String, dynamic>);
    }

    if (json['reigningWorldIttChampion'] != null) {
      registry.reigningWorldIttChampion =
          ChampionshipTitle.fromJson(json['reigningWorldIttChampion'] as Map<String, dynamic>);
    }

    return registry;
  }
}

/// Serwis zarządzający logiką Mistrzostw Krajowych i Mistrzostw Świata UCI.
class NationalChampionshipsAndWorldsService {
  final ReigningChampionsRegistry registry;

  NationalChampionshipsAndWorldsService({ReigningChampionsRegistry? registry})
      : registry = registry ?? ReigningChampionsRegistry();

  // ===========================================================================
  // 1. POWOŁANIA DO REPREZENTACJI NARODOWYCH NA MISTRZOSTWA ŚWIATA (UCI WORLDS)
  // ===========================================================================

  /// Ustala limity miejsc (kwoty startowe) dla nacji na MŚ w oparciu o siłę kolarską.
  static int getNationQuota(String countryIso) {
    final c = countryIso.toUpperCase();
    switch (c) {
      case 'BEL':
      case 'FRA':
      case 'ITA':
      case 'ESP':
      case 'SLO':
      case 'DEN':
      case 'GBR':
      case 'NED':
        return 8; // Tier 1: Potęgi kolarskie (8 kolarzy)
      case 'AUS':
      case 'USA':
      case 'COL':
      case 'GER':
      case 'SUI':
      case 'NOR':
      case 'POL':
        return 6; // Tier 2: Silne reprezentacje (6 kolarzy)
      case 'POR':
      case 'ERI':
      case 'ECU':
      case 'KAZ':
      case 'AUT':
      case 'CZE':
      case 'CAN':
      case 'IRL':
        return 4; // Tier 3: Średnie nacje (4 kolarzy)
      default:
        return 2; // Tier 4: Pozostałe kraje (1-2 kolarzy)
    }
  }

  /// Zwraca pełną nazwę kraju w języku polskim dla danego kodu ISO.
  static String getCountryName(String countryIso) {
    final c = countryIso.toUpperCase();
    switch (c) {
      case 'POL':
        return 'Polska';
      case 'FRA':
        return 'Francja';
      case 'ITA':
        return 'Włochy';
      case 'BEL':
        return 'Belgia';
      case 'ESP':
        return 'Hiszpania';
      case 'SLO':
        return 'Słowenia';
      case 'DEN':
        return 'Dania';
      case 'GBR':
        return 'Wielka Brytania';
      case 'NED':
        return 'Holandia';
      case 'COL':
        return 'Kolumbia';
      case 'GER':
        return 'Niemcy';
      case 'AUS':
        return 'Australia';
      case 'USA':
        return 'Stany Zjednoczone';
      case 'SUI':
        return 'Szwajcaria';
      case 'NOR':
        return 'Norwegia';
      case 'POR':
        return 'Portugalia';
      case 'ERI':
        return 'Erytrea';
      case 'ECU':
        return 'Ekwador';
      default:
        return c;
    }
  }

  /// Powołuje reprezentacje narodowe ze wszystkich dostępnych kolarzy na świecie.
  List<NationalTeamSelection> draftNationalTeamsForWorldChampionships({
    required List<Rider> worldPool,
    ChampionshipDiscipline discipline = ChampionshipDiscipline.roadRace,
  }) {
    // 1. Grupowanie kolarzy według narodowości
    final Map<String, List<Rider>> byNation = {};
    for (final rider in worldPool) {
      final iso = rider.nationalityIso.toUpperCase();
      byNation.putIfAbsent(iso, () => []).add(rider);
    }

    final List<NationalTeamSelection> selections = [];

    byNation.forEach((countryIso, candidates) {
      final int quota = discipline == ChampionshipDiscipline.individualTimeTrial
          ? math.min(candidates.length, 2) // W jeździe na czas max 2 kolarzy na kraj
          : math.min(candidates.length, getNationQuota(countryIso));

      if (quota <= 0) return;

      // Sortowanie kandydatów pod kątem dyscypliny
      final sortedCandidates = List<Rider>.from(candidates);
      if (discipline == ChampionshipDiscipline.individualTimeTrial) {
        // Ocena jazdy na czas (FTP + timeTrialPositioning)
        sortedCandidates.sort((a, b) {
          final scoreA = a.powerProfile.watts20m + (a.skills.timeTrialPositioning * 3);
          final scoreB = b.powerProfile.watts20m + (b.skills.timeTrialPositioning * 3);
          return scoreB.compareTo(scoreA);
        });
      } else {
        // Ocena wyścigu ze startu wspólnego (punch, sprint, ftp, raceIq)
        sortedCandidates.sort((a, b) {
          final scoreA = a.powerProfile.watts20m +
              (a.skills.punch * 2) +
              (a.powerProfile.watts5s * 0.25) +
              (a.skills.raceIq * 2);
          final scoreB = b.powerProfile.watts20m +
              (b.skills.punch * 2) +
              (b.powerProfile.watts5s * 0.25) +
              (b.skills.raceIq * 2);
          return scoreB.compareTo(scoreA);
        });
      }

      final teamRiders = sortedCandidates.take(quota).toList();
      final leaderId = teamRiders.first.id;

      selections.add(NationalTeamSelection(
        countryIso: countryIso,
        countryName: getCountryName(countryIso),
        selectedRiders: teamRiders,
        teamLeaderRiderId: leaderId,
        teamQuota: quota,
      ));
    });

    // Sortowanie reprezentacji według siły lidera
    selections.sort((a, b) => b.leader.powerProfile.watts20m
        .compareTo(a.leader.powerProfile.watts20m));

    return selections;
  }

  // ===========================================================================
  // 2. SYMULACJA MISTRZOSTW KRAJOWYCH (NATIONAL CHAMPIONSHIPS - CZERWIEC)
  // ===========================================================================

  /// Symuluje Mistrzostwa Krajowe (ze startu wspólnego oraz ITT) dla wybranych nacji.
  List<ChampionshipRaceResult> simulateAllNationalChampionships({
    required int year,
    required List<Rider> worldPool,
    List<String>? targetCountries,
    int? randomSeed,
  }) {
    final math.Random random = math.Random(randomSeed ?? (year * 101));
    final List<ChampionshipRaceResult> championshipResults = [];

    // Pogrupowanie kolarzy
    final Map<String, List<Rider>> byNation = {};
    for (final rider in worldPool) {
      final iso = rider.nationalityIso.toUpperCase();
      if (targetCountries == null || targetCountries.contains(iso)) {
        byNation.putIfAbsent(iso, () => []).add(rider);
      }
    }

    byNation.forEach((countryIso, nationRiders) {
      if (nationRiders.isEmpty) return;

      // 1. Wyścig ze startu wspólnego (Road Race)
      final roadResult = _simulateSingleChampionship(
        year: year,
        level: ChampionshipLevel.national,
        discipline: ChampionshipDiscipline.roadRace,
        countryIso: countryIso,
        participants: nationRiders,
        distanceKm: 228.0,
        hostCity: _getNationalChampionshipHostCity(countryIso),
        random: random,
      );
      championshipResults.add(roadResult);

      // Rejestracja mistrza kraju RR
      final roadChamp = roadResult.winner;
      registry.registerNationalChampion(ChampionshipTitle(
        year: year,
        level: ChampionshipLevel.national,
        discipline: ChampionshipDiscipline.roadRace,
        countryIso: countryIso,
        winnerRiderId: roadChamp.riderId,
        winnerRiderName: roadChamp.riderName,
        winningTradeTeamName: roadChamp.tradeTeamName,
        dateAwarded: DateTime(year, 6, 28),
        uciPointsAwarded: 100,
      ));

      // 2. Jazda na czas (ITT)
      final ittResult = _simulateSingleChampionship(
        year: year,
        level: ChampionshipLevel.national,
        discipline: ChampionshipDiscipline.individualTimeTrial,
        countryIso: countryIso,
        participants: nationRiders,
        distanceKm: 38.0,
        hostCity: _getNationalChampionshipHostCity(countryIso),
        random: random,
      );
      championshipResults.add(ittResult);

      // Rejestracja mistrza kraju ITT
      final ittChamp = ittResult.winner;
      registry.registerNationalChampion(ChampionshipTitle(
        year: year,
        level: ChampionshipLevel.national,
        discipline: ChampionshipDiscipline.individualTimeTrial,
        countryIso: countryIso,
        winnerRiderId: ittChamp.riderId,
        winnerRiderName: ittChamp.riderName,
        winningTradeTeamName: ittChamp.tradeTeamName,
        dateAwarded: DateTime(year, 6, 25),
        uciPointsAwarded: 70,
      ));
    });

    return championshipResults;
  }

  // ===========================================================================
  // 3. SYMULACJA MISTRZOSTW ŚWIATA (UCI WORLDS - WRZESIEŃ)
  // ===========================================================================

  /// Symuluje wyścig Mistrzostw Świata UCI w reprezentacjach narodowych.
  ChampionshipRaceResult simulateWorldChampionships({
    required int year,
    required List<Rider> worldPool,
    ChampionshipDiscipline discipline = ChampionshipDiscipline.roadRace,
    String? hostCity,
    int? randomSeed,
  }) {
    final math.Random random = math.Random(randomSeed ?? (year * 313 + discipline.index));
    final String actualHostCity = hostCity ?? _getWorldChampionshipHostCity(year);

    // 1. Powołania reprezentacji narodowych
    final List<NationalTeamSelection> teams = draftNationalTeamsForWorldChampionships(
      worldPool: worldPool,
      discipline: discipline,
    );

    // 2. Złożenie listy wszystkich powołanych kolarzy
    final List<Rider> participants = [];
    for (final t in teams) {
      participants.addAll(t.selectedRiders);
    }

    final double distanceKm = discipline == ChampionshipDiscipline.roadRace ? 268.0 : 44.0;
    final String raceName = discipline == ChampionshipDiscipline.roadRace
        ? 'UCI Road World Championships • $actualHostCity $year'
        : 'UCI Time Trial World Championships • $actualHostCity $year';

    // 3. Symulacja rywalizacji
    final result = _simulateSingleChampionship(
      year: year,
      level: ChampionshipLevel.world,
      discipline: discipline,
      countryIso: 'WORLD',
      raceNameOverride: raceName,
      participants: participants,
      distanceKm: distanceKm,
      hostCity: actualHostCity,
      random: random,
    );

    // 4. Koronacja i rejestracja Tęczowej Koszulki
    final goldMedalist = result.winner;
    registry.registerWorldChampion(ChampionshipTitle(
      year: year,
      level: ChampionshipLevel.world,
      discipline: discipline,
      countryIso: 'WORLD',
      winnerRiderId: goldMedalist.riderId,
      winnerRiderName: goldMedalist.riderName,
      winningTradeTeamName: goldMedalist.tradeTeamName,
      dateAwarded: DateTime(year, 9, discipline == ChampionshipDiscipline.individualTimeTrial ? 23 : 27),
      uciPointsAwarded: discipline == ChampionshipDiscipline.roadRace ? 900 : 600,
    ));

    return result;
  }

  // ===========================================================================
  // 4. SILNIK SYMULACJI BIEGÓW MISTRZOWSKICH
  // ===========================================================================

  ChampionshipRaceResult _simulateSingleChampionship({
    required int year,
    required ChampionshipLevel level,
    required ChampionshipDiscipline discipline,
    required String countryIso,
    String? raceNameOverride,
    required List<Rider> participants,
    required double distanceKm,
    required String hostCity,
    required math.Random random,
  }) {
    final bool isITT = discipline == ChampionshipDiscipline.individualTimeTrial;
    final List<_RiderPerformanceScore> scoredParticipants = [];

    for (final rider in participants) {
      double performanceScore = 0.0;

      if (isITT) {
        // Waga ITT: FTP 60%, Aero 25%, RaceIQ 15%
        final double ftpWkg = rider.physiology.weightKg > 0
            ? rider.powerProfile.watts20m / rider.physiology.weightKg
            : 4.5;
        performanceScore = (ftpWkg * 15.0) +
            (rider.skills.timeTrialPositioning * 0.40) +
            (rider.skills.raceIq * 0.20) +
            (random.nextDouble() * 8.0 - 4.0); // Losowość formy dnia
      } else {
        // Waga wyścigu ze startu wspólnego: Punch 30%, FTP 35%, Sprint 20%, RaceIQ 15%
        final double ftp = rider.powerProfile.watts20m.toDouble();
        final double punch = rider.skills.punch.toDouble();
        final double sprint = (rider.powerProfile.watts5s / 18.0).clamp(30.0, 95.0);
        final double raceIq = rider.skills.raceIq.toDouble();

        performanceScore = (ftp * 0.16) +
            (punch * 0.45) +
            (sprint * 0.35) +
            (raceIq * 0.30) +
            (random.nextDouble() * 12.0 - 6.0);
      }

      scoredParticipants.add(_RiderPerformanceScore(rider, performanceScore));
    }

    // Sortowanie od najwyższego wyniku
    scoredParticipants.sort((a, b) => b.score.compareTo(a.score));

    // Generowanie podium i czasów
    final List<ChampionshipPodiumResult> podium = [];
    final double baseSpeedKmh = isITT ? 49.5 : 43.2;
    final double winnerTimeHours = distanceKm / baseSpeedKmh;
    final Duration winnerDuration = Duration(milliseconds: (winnerTimeHours * 3600 * 1000).round());

    for (int i = 0; i < scoredParticipants.length; i++) {
      final entry = scoredParticipants[i];
      final rank = i + 1;

      // Wyliczanie straty czasowej
      Duration gap = Duration.zero;
      if (rank > 1) {
        final double gapSec = isITT
            ? (i * 2.8) + (random.nextDouble() * 4.0)
            : (i <= 4 ? (i * 0.2) : (i * 1.5 + (random.nextDouble() * 15.0)));
        gap = Duration(milliseconds: (gapSec * 1000).round());
      }

      final finishTime = winnerDuration + gap;

      // Punkty UCI
      int uciPts = 0;
      if (level == ChampionshipLevel.world) {
        if (rank == 1) {
          uciPts = isITT ? 600 : 900;
        } else if (rank == 2) {
          uciPts = isITT ? 400 : 600;
        } else if (rank == 3) {
          uciPts = isITT ? 300 : 450;
        } else if (rank <= 10) {
          uciPts = (100 - (rank * 8)).clamp(10, 200);
        }
      } else {
        if (rank == 1) {
          uciPts = isITT ? 70 : 100;
        } else if (rank == 2) {
          uciPts = isITT ? 40 : 60;
        } else if (rank == 3) {
          uciPts = isITT ? 25 : 40;
        } else if (rank <= 5) {
          uciPts = 10;
        }
      }

      podium.add(ChampionshipPodiumResult(
        rank: rank,
        riderId: entry.rider.id,
        riderName: entry.rider.fullName,
        nationalityIso: entry.rider.nationalityIso.toUpperCase(),
        tradeTeamName: 'Pro Peloton Team',
        finishTime: finishTime,
        timeGapToWinner: gap,
        uciPoints: uciPts,
      ));
    }

    final String raceName = raceNameOverride ??
        'Mistrzostwa ${getCountryName(countryIso)} • ${discipline.polishLabel} $year';

    return ChampionshipRaceResult(
      raceId: 'champ_${level.name}_${discipline.name}_${countryIso.toLowerCase()}_$year',
      year: year,
      level: level,
      discipline: discipline,
      countryIso: countryIso,
      raceName: raceName,
      hostCity: hostCity,
      distanceKm: distanceKm,
      results: podium,
    );
  }

  // ===========================================================================
  // 5. KLASYFIKACJA STROJÓW I KOSZULEK MISTRZOWSKICH
  // ===========================================================================

  /// Określa, jaki strój ma założyć kolarz na dany wyścig według hierarchii UCI.
  SpecialJerseyDesignation getRiderJerseyDesignation({
    required String riderId,
    required String nationalityIso,
    bool isTimeTrial = false,
  }) {
    // 1. Tęczowa koszulka aktualnego Mistrza Świata (Najwyższy prestiż w kolarstwie)
    if (registry.isReigningWorldChampion(riderId, isTimeTrial: isTimeTrial)) {
      return SpecialJerseyDesignation.rainbowJersey;
    }

    // 2. Koszulka aktualnego Mistrza Kraju
    if (registry.isReigningNationalChampion(riderId, nationalityIso, isTimeTrial: isTimeTrial)) {
      return SpecialJerseyDesignation.nationalChampionJersey;
    }

    // 3. Paski byłego mistrza świata na rękawkach (dożywotnio)
    if (registry.isFormerWorldChampion(riderId)) {
      return SpecialJerseyDesignation.formerWorldChampionRainbowBands;
    }

    // 4. Standardowy strój ekipy
    return SpecialJerseyDesignation.standardTeamJersey;
  }

  /// Zwraca czytelny opis koszulki dla danego kolarza.
  String getJerseyDescription(SpecialJerseyDesignation designation, String countryIso) {
    switch (designation) {
      case SpecialJerseyDesignation.rainbowJersey:
        return 'Tęczowa Koszulka Mistrza Świata UCI (Rainbow Jersey • Maillot Arc-en-Ciel)';
      case SpecialJerseyDesignation.nationalChampionJersey:
        final theme = getNationalJerseyColorTheme(countryIso);
        return 'Koszulka Mistrza Kraju (${theme['description']})';
      case SpecialJerseyDesignation.formerWorldChampionRainbowBands:
        return 'Tęczowe paski mistrza świata na mankietach rękawków i kołnierzyku';
      case SpecialJerseyDesignation.standardTeamJersey:
        return 'Standardowy strój drużynowy';
    }
  }

  /// Zwraca paletę barwną i wzór koszulki Mistrza Kraju dla danej nacji.
  static Map<String, String> getNationalJerseyColorTheme(String countryIso) {
    final c = countryIso.toUpperCase();
    switch (c) {
      case 'POL':
        return {
          'country': 'Polska',
          'primaryHex': '#FFFFFF',
          'secondaryHex': '#DC2626',
          'accentHex': '#FFFFFF',
          'description': 'Biało-czerwona z orłem na piersi',
          'pattern': 'nationalChampion',
        };
      case 'FRA':
        return {
          'country': 'Francja',
          'primaryHex': '#002395',
          'secondaryHex': '#FFFFFF',
          'accentHex': '#ED2939',
          'description': 'Tricolore Bleu-Blanc-Rouge',
          'pattern': 'chestStripe',
        };
      case 'ITA':
        return {
          'country': 'Włochy',
          'primaryHex': '#009246',
          'secondaryHex': '#FFFFFF',
          'accentHex': '#CE2B37',
          'description': 'Tricolore Zielono-Biało-Czerwona',
          'pattern': 'chestStripe',
        };
      case 'BEL':
        return {
          'country': 'Belgia',
          'primaryHex': '#4FA8E0', // Belgijski błękit
          'secondaryHex': '#000000',
          'accentHex': '#FFD100',
          'description': 'Błękitna koszulka z czarno-żółto-czerwonym pasem',
          'pattern': 'chestStripe',
        };
      case 'ESP':
        return {
          'country': 'Hiszpania',
          'primaryHex': '#AA151B',
          'secondaryHex': '#F1BF00',
          'accentHex': '#AA151B',
          'description': 'Rojigualda (Czerwono-Żółto-Czerwona)',
          'pattern': 'verticalStripes',
        };
      case 'DEN':
        return {
          'country': 'Dania',
          'primaryHex': '#C60C30',
          'secondaryHex': '#FFFFFF',
          'accentHex': '#C60C30',
          'description': 'Czerwona z białym krzyżem Dannebrog',
          'pattern': 'chestStripe',
        };
      case 'SLO':
        return {
          'country': 'Słowenia',
          'primaryHex': '#FFFFFF',
          'secondaryHex': '#0055A5',
          'accentHex': '#EE1C25',
          'description': 'Biało-błękitno-zielona z motywem góry Triglav',
          'pattern': 'chevron',
        };
      case 'GBR':
        return {
          'country': 'Wielka Brytania',
          'primaryHex': '#FFFFFF',
          'secondaryHex': '#012169',
          'accentHex': '#C8102E',
          'description': 'Biała z pasami Union Jack',
          'pattern': 'chestStripe',
        };
      case 'NED':
        return {
          'country': 'Holandia',
          'primaryHex': '#FF4F00',
          'secondaryHex': '#FFFFFF',
          'accentHex': '#21468B',
          'description': 'Pomarańczowa (Oranje) z flagą Królestwa Niderlandów',
          'pattern': 'solid',
        };
      case 'COL':
        return {
          'country': 'Kolumbia',
          'primaryHex': '#FCD116',
          'secondaryHex': '#003893',
          'accentHex': '#CE1126',
          'description': 'Żółto-Błękitno-Czerwona (Tricolor Nacional)',
          'pattern': 'chestStripe',
        };
      case 'GER':
        return {
          'country': 'Niemcy',
          'primaryHex': '#FFFFFF',
          'secondaryHex': '#000000',
          'accentHex': '#DD0000',
          'description': 'Biała z pasem czarno-czerwono-złotym',
          'pattern': 'chestStripe',
        };
      case 'AUS':
        return {
          'country': 'Australia',
          'primaryHex': '#00843D',
          'secondaryHex': '#FFCD00',
          'accentHex': '#FFFFFF',
          'description': 'Zielono-Złota (Green and Gold Boxing Kangaroo)',
          'pattern': 'contrastSleeves',
        };
      case 'USA':
        return {
          'country': 'Stany Zjednoczone',
          'primaryHex': '#00205B',
          'secondaryHex': '#BA0C2F',
          'accentHex': '#FFFFFF',
          'description': 'Stars and Stripes (Gwiazdy i Pasy)',
          'pattern': 'verticalStripes',
        };
      default:
        return {
          'country': countryIso,
          'primaryHex': '#FFFFFF',
          'secondaryHex': '#3B82F6',
          'accentHex': '#EF4444',
          'description': 'Barwy narodowe $countryIso',
          'pattern': 'chestStripe',
        };
    }
  }

  // ===========================================================================
  // MIASTA GOSPODARZE
  // ===========================================================================

  static String _getNationalChampionshipHostCity(String countryIso) {
    switch (countryIso.toUpperCase()) {
      case 'POL':
        return 'Płock / Ostróda';
      case 'FRA':
        return 'Saint-Amand-Montrond';
      case 'ITA':
        return 'Comano Terme';
      case 'BEL':
        return 'Zottegem';
      case 'ESP':
        return 'San Lorenzo de El Escorial';
      case 'SLO':
        return 'Radovljica';
      case 'DEN':
        return 'Aalborg';
      case 'GBR':
        return 'Saltburn-by-the-Sea';
      case 'NED':
        return 'Arnhem';
      default:
        return 'Stolica Kraju';
    }
  }

  static String _getWorldChampionshipHostCity(int year) {
    switch (year) {
      case 2026:
        return 'Montreal (Kanada)';
      case 2027:
        return 'Haute-Savoie (Francja)';
      case 2028:
        return 'Abu Dhabi (ZEA)';
      default:
        return 'Zurych (Szwajcaria)';
    }
  }
}

class _RiderPerformanceScore {
  final Rider rider;
  final double score;

  const _RiderPerformanceScore(this.rider, this.score);
}
