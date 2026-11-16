// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/rider/rider.dart';
import '../../models/rider/rider_appearance.dart';
import '../../models/rider/rider_contract.dart';
import '../../models/rider/rider_health.dart';
import '../../models/rider/rider_physiology.dart';
import '../../models/rider/rider_power_profile.dart';
import '../../models/rider/rider_skills.dart';
import 'development_team_u23_service.dart';

/// Typ profilu wyścigu młodzieżowego U23 wpływający na wagę parametrów fizjologicznych.
enum YouthU23RaceProfile {
  grandTourMountains,
  cobblesMonument,
  ardennesPuncher,
  mixedStageRace;

  String toJson() => name;

  static YouthU23RaceProfile fromJson(String value) {
    return YouthU23RaceProfile.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => YouthU23RaceProfile.mixedStageRace,
    );
  }

  String get label {
    switch (this) {
      case YouthU23RaceProfile.grandTourMountains:
        return 'Wielkie Góry & GC';
      case YouthU23RaceProfile.cobblesMonument:
        return 'Bruk & Wiatr';
      case YouthU23RaceProfile.ardennesPuncher:
        return 'Pagórki & Ścianki';
      case YouthU23RaceProfile.mixedStageRace:
        return 'Etapówka Wszechstronna';
    }
  }
}

/// Poziom gotowości juniora/U23 do podpisania pierwszego kontraktu zawodowego.
enum ProContractReadinessTier {
  worldTourReady,
  proTeamReady,
  needsAnotherU23Year,
  unprovenProspect;

  String toJson() => name;

  static ProContractReadinessTier fromJson(String value) {
    return ProContractReadinessTier.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ProContractReadinessTier.unprovenProspect,
    );
  }

  String get label {
    switch (this) {
      case ProContractReadinessTier.worldTourReady:
        return 'Gotowy na WorldTour';
      case ProContractReadinessTier.proTeamReady:
        return 'Gotowy na ProTeam / Stagiaire';
      case ProContractReadinessTier.needsAnotherU23Year:
        return 'Wymaga kolejnego roku w U23';
      case ProContractReadinessTier.unprovenProspect:
        return 'Brak danych wyścigowych';
    }
  }
}

/// Definicja prestiżowego wyścigu w kalendarzu U23.
class YouthU23RaceDefinition {
  final String id;
  final String name;
  final String countryIso;
  final YouthRaceCategory category;
  final YouthU23RaceProfile profile;
  final int month;
  final int stageCount;
  final double totalDistanceKm;
  final int elevationGainMeters;
  final String signatureSectorOrClimb;
  final double mountainDifficulty;
  final double cobblesDifficulty;
  final double ittWeight;
  final int uciWinPoints;
  final int prizePoolEur;
  final String description;

  const YouthU23RaceDefinition({
    required this.id,
    required this.name,
    required this.countryIso,
    required this.category,
    required this.profile,
    required this.month,
    required this.stageCount,
    required this.totalDistanceKm,
    required this.elevationGainMeters,
    required this.signatureSectorOrClimb,
    required this.mountainDifficulty,
    required this.cobblesDifficulty,
    required this.ittWeight,
    required this.uciWinPoints,
    required this.prizePoolEur,
    required this.description,
  });

  bool get isMultiStage => stageCount > 1;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'countryIso': countryIso,
        'category': category.toJson(),
        'profile': profile.toJson(),
        'month': month,
        'stageCount': stageCount,
        'totalDistanceKm': totalDistanceKm,
        'elevationGainMeters': elevationGainMeters,
        'signatureSectorOrClimb': signatureSectorOrClimb,
        'mountainDifficulty': mountainDifficulty,
        'cobblesDifficulty': cobblesDifficulty,
        'ittWeight': ittWeight,
        'uciWinPoints': uciWinPoints,
        'prizePoolEur': prizePoolEur,
        'description': description,
      };

  factory YouthU23RaceDefinition.fromJson(Map<String, dynamic> json) {
    return YouthU23RaceDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      countryIso: json['countryIso'] as String,
      category: YouthRaceCategory.fromJson(json['category'] as String),
      profile: YouthU23RaceProfile.fromJson(json['profile'] as String),
      month: (json['month'] as num).toInt(),
      stageCount: (json['stageCount'] as num).toInt(),
      totalDistanceKm: (json['totalDistanceKm'] as num).toDouble(),
      elevationGainMeters: (json['elevationGainMeters'] as num).toInt(),
      signatureSectorOrClimb: json['signatureSectorOrClimb'] as String,
      mountainDifficulty: (json['mountainDifficulty'] as num).toDouble(),
      cobblesDifficulty: (json['cobblesDifficulty'] as num).toDouble(),
      ittWeight: (json['ittWeight'] as num).toDouble(),
      uciWinPoints: (json['uciWinPoints'] as num).toInt(),
      prizePoolEur: (json['prizePoolEur'] as num).toInt(),
      description: json['description'] as String,
    );
  }
}

/// Szczegółowa telemetria W/kg oraz VAM zarejestrowana podczas wyścigu U23.
class JuniorU23TelemetryStats {
  final double peak5sWattsPerKg;
  final int peak5sWatts;
  final double peak1mWattsPerKg;
  final double peak5mWattsPerKg;
  final double peak20mWattsPerKg;
  final double ftpWattsPerKg;
  final int normalizedPowerWatts;
  final int vamMetersPerHour;
  final double weightKg;

  const JuniorU23TelemetryStats({
    required this.peak5sWattsPerKg,
    required this.peak5sWatts,
    required this.peak1mWattsPerKg,
    required this.peak5mWattsPerKg,
    required this.peak20mWattsPerKg,
    required this.ftpWattsPerKg,
    required this.normalizedPowerWatts,
    required this.vamMetersPerHour,
    required this.weightKg,
  });

  Map<String, dynamic> toJson() => {
        'peak5sWattsPerKg': peak5sWattsPerKg,
        'peak5sWatts': peak5sWatts,
        'peak1mWattsPerKg': peak1mWattsPerKg,
        'peak5mWattsPerKg': peak5mWattsPerKg,
        'peak20mWattsPerKg': peak20mWattsPerKg,
        'ftpWattsPerKg': ftpWattsPerKg,
        'normalizedPowerWatts': normalizedPowerWatts,
        'vamMetersPerHour': vamMetersPerHour,
        'weightKg': weightKg,
      };

  factory JuniorU23TelemetryStats.fromJson(Map<String, dynamic> json) {
    return JuniorU23TelemetryStats(
      peak5sWattsPerKg: (json['peak5sWattsPerKg'] as num).toDouble(),
      peak5sWatts: (json['peak5sWatts'] as num).toInt(),
      peak1mWattsPerKg: (json['peak1mWattsPerKg'] as num).toDouble(),
      peak5mWattsPerKg: (json['peak5mWattsPerKg'] as num).toDouble(),
      peak20mWattsPerKg: (json['peak20mWattsPerKg'] as num).toDouble(),
      ftpWattsPerKg: (json['ftpWattsPerKg'] as num).toDouble(),
      normalizedPowerWatts: (json['normalizedPowerWatts'] as num).toInt(),
      vamMetersPerHour: (json['vamMetersPerHour'] as num).toInt(),
      weightKg: (json['weightKg'] as num).toDouble(),
    );
  }
}

/// Wynik pojedynczego etapu wyścigu wieloetapowego U23.
class YouthU23StageResultEntry {
  final int stageNumber;
  final String stageTitle;
  final String terrainTag;
  final int position;
  final int timeGapSeconds;
  final double stage20mWattsPerKg;
  final int stageVamMetersPerHour;
  final bool hadIncident;

  const YouthU23StageResultEntry({
    required this.stageNumber,
    required this.stageTitle,
    required this.terrainTag,
    required this.position,
    required this.timeGapSeconds,
    required this.stage20mWattsPerKg,
    required this.stageVamMetersPerHour,
    this.hadIncident = false,
  });

  Map<String, dynamic> toJson() => {
        'stageNumber': stageNumber,
        'stageTitle': stageTitle,
        'terrainTag': terrainTag,
        'position': position,
        'timeGapSeconds': timeGapSeconds,
        'stage20mWattsPerKg': stage20mWattsPerKg,
        'stageVamMetersPerHour': stageVamMetersPerHour,
        'hadIncident': hadIncident,
      };

  factory YouthU23StageResultEntry.fromJson(Map<String, dynamic> json) {
    return YouthU23StageResultEntry(
      stageNumber: (json['stageNumber'] as num).toInt(),
      stageTitle: json['stageTitle'] as String,
      terrainTag: json['terrainTag'] as String,
      position: (json['position'] as num).toInt(),
      timeGapSeconds: (json['timeGapSeconds'] as num).toInt(),
      stage20mWattsPerKg: (json['stage20mWattsPerKg'] as num).toDouble(),
      stageVamMetersPerHour: (json['stageVamMetersPerHour'] as num).toInt(),
      hadIncident: json['hadIncident'] as bool? ?? false,
    );
  }
}

/// Pełny wynik pojedynczego kolarza U23 w symulowanym wyścigu.
class YouthU23RiderRaceEntry {
  final String riderId;
  final String riderName;
  final String nationalityIso;
  final int age;
  final RiderSpecialization specialization;
  final bool isPlayerDevoRider;
  final int gcPosition;
  final int timeGapSeconds;
  final int stageWins;
  final int podiums;
  final int uciPointsEarned;
  final int komRank;
  final int pointsRank;
  final bool hadCrashOrMechanical;
  final JuniorU23TelemetryStats telemetry;
  final List<YouthU23StageResultEntry> stageBreakdown;

  const YouthU23RiderRaceEntry({
    required this.riderId,
    required this.riderName,
    required this.nationalityIso,
    required this.age,
    required this.specialization,
    required this.isPlayerDevoRider,
    required this.gcPosition,
    required this.timeGapSeconds,
    required this.stageWins,
    required this.podiums,
    required this.uciPointsEarned,
    required this.komRank,
    required this.pointsRank,
    required this.hadCrashOrMechanical,
    required this.telemetry,
    this.stageBreakdown = const [],
  });

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'riderName': riderName,
        'nationalityIso': nationalityIso,
        'age': age,
        'specialization': specialization.toJson(),
        'isPlayerDevoRider': isPlayerDevoRider,
        'gcPosition': gcPosition,
        'timeGapSeconds': timeGapSeconds,
        'stageWins': stageWins,
        'podiums': podiums,
        'uciPointsEarned': uciPointsEarned,
        'komRank': komRank,
        'pointsRank': pointsRank,
        'hadCrashOrMechanical': hadCrashOrMechanical,
        'telemetry': telemetry.toJson(),
        'stageBreakdown': stageBreakdown.map((e) => e.toJson()).toList(),
      };

  factory YouthU23RiderRaceEntry.fromJson(Map<String, dynamic> json) {
    return YouthU23RiderRaceEntry(
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      nationalityIso: json['nationalityIso'] as String,
      age: (json['age'] as num).toInt(),
      specialization:
          RiderSpecialization.fromJson(json['specialization'] as String),
      isPlayerDevoRider: json['isPlayerDevoRider'] as bool? ?? false,
      gcPosition: (json['gcPosition'] as num).toInt(),
      timeGapSeconds: (json['timeGapSeconds'] as num).toInt(),
      stageWins: (json['stageWins'] as num).toInt(),
      podiums: (json['podiums'] as num).toInt(),
      uciPointsEarned: (json['uciPointsEarned'] as num).toInt(),
      komRank: (json['komRank'] as num).toInt(),
      pointsRank: (json['pointsRank'] as num).toInt(),
      hadCrashOrMechanical: json['hadCrashOrMechanical'] as bool? ?? false,
      telemetry: JuniorU23TelemetryStats.fromJson(
          json['telemetry'] as Map<String, dynamic>),
      stageBreakdown: (json['stageBreakdown'] as List<dynamic>?)
              ?.map((e) => YouthU23StageResultEntry.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

/// Raport z rozegranego wyścigu młodzieżowego U23.
class YouthU23RaceSimulationReport {
  final YouthU23RaceDefinition race;
  final int seasonYear;
  final DateTime simulatedAt;
  final List<YouthU23RiderRaceEntry> standings;
  final String headlineSummary;
  final String decisiveMomentNote;

  const YouthU23RaceSimulationReport({
    required this.race,
    required this.seasonYear,
    required this.simulatedAt,
    required this.standings,
    required this.headlineSummary,
    required this.decisiveMomentNote,
  });

  YouthU23RiderRaceEntry? get winner =>
      standings.isNotEmpty ? standings.first : null;

  List<YouthU23RiderRaceEntry> get playerDevoResults =>
      standings.where((e) => e.isPlayerDevoRider).toList();

  Map<String, dynamic> toJson() => {
        'race': race.toJson(),
        'seasonYear': seasonYear,
        'simulatedAt': simulatedAt.toIso8601String(),
        'standings': standings.map((e) => e.toJson()).toList(),
        'headlineSummary': headlineSummary,
        'decisiveMomentNote': decisiveMomentNote,
      };

  factory YouthU23RaceSimulationReport.fromJson(Map<String, dynamic> json) {
    return YouthU23RaceSimulationReport(
      race: YouthU23RaceDefinition.fromJson(
          json['race'] as Map<String, dynamic>),
      seasonYear: (json['seasonYear'] as num).toInt(),
      simulatedAt: DateTime.parse(json['simulatedAt'] as String),
      standings: (json['standings'] as List<dynamic>)
          .map((e) =>
              YouthU23RiderRaceEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      headlineSummary: json['headlineSummary'] as String,
      decisiveMomentNote: json['decisiveMomentNote'] as String,
    );
  }
}

/// Skautingowy raport gotowości juniora do pierwszego kontraktu zawodowego.
class JuniorProContractScoutingDossier {
  final String riderId;
  final String riderName;
  final String nationalityIso;
  final int age;
  final RiderSpecialization specialization;
  final int racesTracked;
  final int totalStageWins;
  final int totalPodiums;
  final int bestGcPosition;
  final int totalUciYouthPoints;
  final double best20mWattsPerKg;
  final double average20mWattsPerKg;
  final double peak5mWattsPerKg;
  final double peak1mWattsPerKg;
  final double peak5sWattsPerKg;
  final int peak5sWatts;
  final int peakVamMetersPerHour;
  final double scoutingReadinessScore;
  final ProContractReadinessTier readinessTier;
  final int recommendedSalaryEur;
  final int recommendedContractYears;
  final String scoutingVerdict;

  const JuniorProContractScoutingDossier({
    required this.riderId,
    required this.riderName,
    required this.nationalityIso,
    required this.age,
    required this.specialization,
    required this.racesTracked,
    required this.totalStageWins,
    required this.totalPodiums,
    required this.bestGcPosition,
    required this.totalUciYouthPoints,
    required this.best20mWattsPerKg,
    required this.average20mWattsPerKg,
    required this.peak5mWattsPerKg,
    required this.peak1mWattsPerKg,
    required this.peak5sWattsPerKg,
    required this.peak5sWatts,
    required this.peakVamMetersPerHour,
    required this.scoutingReadinessScore,
    required this.readinessTier,
    required this.recommendedSalaryEur,
    required this.recommendedContractYears,
    required this.scoutingVerdict,
  });

  bool get isReadyForProContract =>
      readinessTier == ProContractReadinessTier.worldTourReady ||
      readinessTier == ProContractReadinessTier.proTeamReady;
}

/// Symulator wyścigów młodzieżowych U23 (`Tour de l'Avenir`, `Giro Next Gen`,
/// `Paris-Roubaix Espoirs` i inne wyścigi Pucharu Narodów U23) z pełnym
/// śledzeniem wyników oraz telemetrii W/kg przed podpisaniem pierwszego kontraktu pro.
class YouthRaceCalendarU23Simulator {
  final int? seed;

  const YouthRaceCalendarU23Simulator({this.seed});

  /// Oficjalny kalendarz najważniejszych wyścigów U23 w sezonie.
  static const List<YouthU23RaceDefinition> officialCalendar = [
    YouthU23RaceDefinition(
      id: 'u23_paris_roubaix_espoirs',
      name: 'Paris-Roubaix Espoirs',
      countryIso: 'FRA',
      category: YouthRaceCategory.u23MonumentClassic,
      profile: YouthU23RaceProfile.cobblesMonument,
      month: 4,
      stageCount: 1,
      totalDistanceKm: 163.5,
      elevationGainMeters: 920,
      signatureSectorOrClimb: 'Carrefour de l\'Arbre (5★ bruk)',
      mountainDifficulty: 1.0,
      cobblesDifficulty: 5.0,
      ittWeight: 0.05,
      uciWinPoints: 120,
      prizePoolEur: 18000,
      description:
          'Piekło Północy w wersji U23: 17 sektorów bruku, walka o pozycję przed Arenbergiem i finisz na welodromie w Roubaix.',
    ),
    YouthU23RaceDefinition(
      id: 'u23_liege_bastogne_liege',
      name: 'Liège-Bastogne-Liège U23',
      countryIso: 'BEL',
      category: YouthRaceCategory.u23MonumentClassic,
      profile: YouthU23RaceProfile.ardennesPuncher,
      month: 4,
      stageCount: 1,
      totalDistanceKm: 174.0,
      elevationGainMeters: 2950,
      signatureSectorOrClimb: 'Côte de la Redoute (1.6 km, 9.4%)',
      mountainDifficulty: 3.3,
      cobblesDifficulty: 1.2,
      ittWeight: 0.0,
      uciWinPoints: 110,
      prizePoolEur: 16500,
      description:
          'Klasyk ardeński dla najlepszych puncherów U23 z decydującymi atakami na La Redoute i Roche-aux-Faucons.',
    ),
    YouthU23RaceDefinition(
      id: 'u23_ronde_de_lisard',
      name: 'Ronde de l\'Isard',
      countryIso: 'FRA',
      category: YouthRaceCategory.continentalStageRace,
      profile: YouthU23RaceProfile.grandTourMountains,
      month: 5,
      stageCount: 5,
      totalDistanceKm: 645.0,
      elevationGainMeters: 12400,
      signatureSectorOrClimb: 'Plateau de Beille (15.8 km, 7.9%)',
      mountainDifficulty: 4.5,
      cobblesDifficulty: 1.0,
      ittWeight: 0.08,
      uciWinPoints: 130,
      prizePoolEur: 22000,
      description:
          'Pirenejski test dla młodych górali U23. Weryfikuje wytrzymałość powyżej 1800 m n.p.m. na wielkich przełęczach.',
    ),
    YouthU23RaceDefinition(
      id: 'u23_course_de_la_paix',
      name: 'Course de la Paix U23',
      countryIso: 'CZE',
      category: YouthRaceCategory.u23NationsCup,
      profile: YouthU23RaceProfile.mixedStageRace,
      month: 6,
      stageCount: 4,
      totalDistanceKm: 528.0,
      elevationGainMeters: 7850,
      signatureSectorOrClimb: 'Dlouhé Stráně (11.2 km, 6.8%)',
      mountainDifficulty: 3.7,
      cobblesDifficulty: 1.1,
      ittWeight: 0.18,
      uciWinPoints: 145,
      prizePoolEur: 24000,
      description:
          'Wyścig Pucharu Narodów w Jesionikach: prolog, pagórkowate etapy i finał na Dlouhé Stráně.',
    ),
    YouthU23RaceDefinition(
      id: 'u23_giro_next_gen',
      name: 'Giro Next Gen (Baby Giro)',
      countryIso: 'ITA',
      category: YouthRaceCategory.u23GrandTour,
      profile: YouthU23RaceProfile.grandTourMountains,
      month: 6,
      stageCount: 8,
      totalDistanceKm: 1035.0,
      elevationGainMeters: 16800,
      signatureSectorOrClimb: 'Passo dello Stelvio (24.3 km, 7.4%)',
      mountainDifficulty: 4.9,
      cobblesDifficulty: 1.3,
      ittWeight: 0.16,
      uciWinPoints: 200,
      prizePoolEur: 45000,
      description:
          'Najważniejszy młodzieżowy Wielki Tour na świecie. Osiem dni ścigania w Dolomitach i Alpach dla przyszłych zwycięzców Grand Tourów.',
    ),
    YouthU23RaceDefinition(
      id: 'u23_tour_de_lavenir',
      name: 'Tour de l\'Avenir',
      countryIso: 'FRA',
      category: YouthRaceCategory.u23NationsCup,
      profile: YouthU23RaceProfile.grandTourMountains,
      month: 8,
      stageCount: 8,
      totalDistanceKm: 1080.0,
      elevationGainMeters: 18400,
      signatureSectorOrClimb: 'Col de la Loze (21.5 km, 7.8%)',
      mountainDifficulty: 5.0,
      cobblesDifficulty: 1.0,
      ittWeight: 0.20,
      uciWinPoints: 240,
      prizePoolEur: 55000,
      description:
          'Młodzieżowy Tour de France w formule reprezentacji narodowych. Zwycięzca niemal zawsze trafia bezpośrednio do elity WorldTour.',
    ),
  ];

  /// Zwraca pełny kalendarz U23 posortowany chronologicznie po miesiącu.
  List<YouthU23RaceDefinition> getCalendar({YouthU23RaceProfile? profileFilter}) {
    final items = profileFilter == null
        ? List<YouthU23RaceDefinition>.from(officialCalendar)
        : officialCalendar.where((r) => r.profile == profileFilter).toList();
    items.sort((a, b) => a.month.compareTo(b.month));
    return items;
  }

  /// Symuluje wskazany wyścig U23 dla przekazanej grupy kolarzy gracza oraz
  /// międzynarodowej stawki rywali U23, rejestrując dokładne wyniki i W/kg.
  YouthU23RaceSimulationReport simulateRace({
    required YouthU23RaceDefinition race,
    required List<Rider> playerDevoRiders,
    List<Rider> externalRivals = const [],
    int seasonYear = 2026,
    int minimumFieldSize = 32,
    DateTime? simulationDate,
  }) {
    final rng = seed != null ? math.Random(seed! + race.id.hashCode) : math.Random();
    final eligiblePlayer = playerDevoRiders.where((r) => r.age <= 23).toList();
    final playerIds = eligiblePlayer.map((r) => r.id).toSet();

    final combinedField = <Rider>[
      ...eligiblePlayer,
      ...externalRivals.where((r) => !playerIds.contains(r.id)),
    ];

    if (combinedField.length < minimumFieldSize) {
      final needed = minimumFieldSize - combinedField.length;
      combinedField.addAll(
        generateInternationalU23Field(
          count: needed,
          seasonYear: seasonYear,
          rng: rng,
          raceIdSeed: race.id,
        ),
      );
    }

    final stageCount = math.max(1, race.stageCount);
    final stageProfiles = _buildStageProfiles(race);

    // Akumulatory wieloetapowe dla każdego kolarza
    final totalTimeSeconds = <String, int>{
      for (final r in combinedField) r.id: 0,
    };
    final stageWinsMap = <String, int>{
      for (final r in combinedField) r.id: 0,
    };
    final podiumsMap = <String, int>{
      for (final r in combinedField) r.id: 0,
    };
    final crashMap = <String, bool>{
      for (final r in combinedField) r.id: false,
    };
    final stageEntriesMap = <String, List<YouthU23StageResultEntry>>{
      for (final r in combinedField) r.id: <YouthU23StageResultEntry>[],
    };
    final peak20mList = <String, List<double>>{
      for (final r in combinedField) r.id: <double>[],
    };
    final peak5mList = <String, List<double>>{
      for (final r in combinedField) r.id: <double>[],
    };
    final peak1mList = <String, List<double>>{
      for (final r in combinedField) r.id: <double>[],
    };
    final peak5sList = <String, List<double>>{
      for (final r in combinedField) r.id: <double>[],
    };
    final vamList = <String, List<int>>{
      for (final r in combinedField) r.id: <int>[],
    };

    for (int s = 0; s < stageCount; s++) {
      final stageMeta = stageProfiles[s];
      final stageScores = <_RiderStageEval>[];

      for (final rider in combinedField) {
        final eval = _evaluateRiderOnStage(
          rider: rider,
          race: race,
          stageMeta: stageMeta,
          rng: rng,
          accumulatedFatiguePenalty: s * 0.012,
        );
        stageScores.add(eval);
      }

      // Sortuj od najwyższego wyniku wydajnościowego na etapie
      stageScores.sort((a, b) => b.performanceScore.compareTo(a.performanceScore));
      final bestScore = stageScores.first.performanceScore;

      for (int rank = 0; rank < stageScores.length; rank++) {
        final eval = stageScores[rank];
        final pos = rank + 1;
        final scoreDiff = (bestScore - eval.performanceScore).clamp(0.0, 200.0);

        // Realistyczne straty czasowe: większe w górach/ITT/bruku, mniejsze na płaskim
        final gapScale = stageMeta.terrainTag == 'Góry HC'
            ? 14.5
            : stageMeta.terrainTag == 'Bruk 5★'
                ? 11.5
                : stageMeta.terrainTag == 'ITT'
                    ? 6.2
                    : 3.4;
        int gapSec = rank == 0 ? 0 : (scoreDiff * gapScale).round();
        if (stageMeta.terrainTag == 'Płaski / Sprint' && rank > 0 && gapSec < 25) {
          gapSec = 0; // Dojazd w głównej grupie
        }
        if (eval.hadIncident) {
          gapSec += 42 + rng.nextInt(115);
          crashMap[eval.rider.id] = true;
        }

        totalTimeSeconds[eval.rider.id] =
            (totalTimeSeconds[eval.rider.id] ?? 0) + gapSec;

        if (pos == 1) {
          stageWinsMap[eval.rider.id] = (stageWinsMap[eval.rider.id] ?? 0) + 1;
        }
        if (pos <= 3) {
          podiumsMap[eval.rider.id] = (podiumsMap[eval.rider.id] ?? 0) + 1;
        }

        peak20mList[eval.rider.id]!.add(eval.stage20mWkg);
        peak5mList[eval.rider.id]!.add(eval.stage5mWkg);
        peak1mList[eval.rider.id]!.add(eval.stage1mWkg);
        peak5sList[eval.rider.id]!.add(eval.stage5sWkg);
        vamList[eval.rider.id]!.add(eval.stageVam);

        stageEntriesMap[eval.rider.id]!.add(
          YouthU23StageResultEntry(
            stageNumber: s + 1,
            stageTitle: stageMeta.title,
            terrainTag: stageMeta.terrainTag,
            position: pos,
            timeGapSeconds: gapSec,
            stage20mWattsPerKg: double.parse(eval.stage20mWkg.toStringAsFixed(2)),
            stageVamMetersPerHour: eval.stageVam,
            hadIncident: eval.hadIncident,
          ),
        );
      }
    }

    // Sortowanie klasyfikacji generalnej (GC)
    final gcOrder = List<Rider>.from(combinedField);
    gcOrder.sort((a, b) {
      final tA = totalTimeSeconds[a.id] ?? 0;
      final tB = totalTimeSeconds[b.id] ?? 0;
      if (tA != tB) return tA.compareTo(tB);
      final wA = stageWinsMap[a.id] ?? 0;
      final wB = stageWinsMap[b.id] ?? 0;
      return wB.compareTo(wA);
    });

    final leaderTime = totalTimeSeconds[gcOrder.first.id] ?? 0;

    // Ranking KOM (wg najwyższego VAM) & Punktowy (wg miejsc na etapach)
    final komSorted = List<Rider>.from(combinedField)
      ..sort((a, b) {
        final vamA = _maxInt(vamList[a.id]!);
        final vamB = _maxInt(vamList[b.id]!);
        return vamB.compareTo(vamA);
      });
    final pointsSorted = List<Rider>.from(combinedField)
      ..sort((a, b) {
        final winsB = stageWinsMap[b.id] ?? 0;
        final winsA = stageWinsMap[a.id] ?? 0;
        if (winsB != winsA) return winsB.compareTo(winsA);
        final podB = podiumsMap[b.id] ?? 0;
        final podA = podiumsMap[a.id] ?? 0;
        return podB.compareTo(podA);
      });

    final standings = <YouthU23RiderRaceEntry>[];
    for (int i = 0; i < gcOrder.length; i++) {
      final r = gcOrder[i];
      final gcPos = i + 1;
      final weight = r.physiology.weightKg > 0 ? r.physiology.weightKg : 68.0;
      final p20 = _maxDouble(peak20mList[r.id]!);
      final p5m = _maxDouble(peak5mList[r.id]!);
      final p1m = _maxDouble(peak1mList[r.id]!);
      final p5s = _maxDouble(peak5sList[r.id]!);
      final peakVam = _maxInt(vamList[r.id]!);
      final uciPts = _calculateUciPointsForPosition(gcPos, race.uciWinPoints);

      final telemetry = JuniorU23TelemetryStats(
        peak5sWattsPerKg: double.parse(p5s.toStringAsFixed(2)),
        peak5sWatts: (p5s * weight).round(),
        peak1mWattsPerKg: double.parse(p1m.toStringAsFixed(2)),
        peak5mWattsPerKg: double.parse(p5m.toStringAsFixed(2)),
        peak20mWattsPerKg: double.parse(p20.toStringAsFixed(2)),
        ftpWattsPerKg: double.parse(r.physiology.wattsPerKg.toStringAsFixed(2)),
        normalizedPowerWatts: (r.physiology.ftpWatts *
                (0.92 + (gcPos <= 5 ? 0.06 : 0.0)))
            .round(),
        vamMetersPerHour: peakVam,
        weightKg: double.parse(weight.toStringAsFixed(1)),
      );

      standings.add(
        YouthU23RiderRaceEntry(
          riderId: r.id,
          riderName: r.fullName,
          nationalityIso: r.nationalityIso,
          age: r.age,
          specialization: r.specialization,
          isPlayerDevoRider: playerIds.contains(r.id),
          gcPosition: gcPos,
          timeGapSeconds: (totalTimeSeconds[r.id] ?? 0) - leaderTime,
          stageWins: stageWinsMap[r.id] ?? 0,
          podiums: podiumsMap[r.id] ?? 0,
          uciPointsEarned: uciPts,
          komRank: komSorted.indexOf(r) + 1,
          pointsRank: pointsSorted.indexOf(r) + 1,
          hadCrashOrMechanical: crashMap[r.id] ?? false,
          telemetry: telemetry,
          stageBreakdown: stageEntriesMap[r.id] ?? const [],
        ),
      );
    }

    final winnerEntry = standings.first;
    final headlineSummary =
        '${winnerEntry.riderName} (${winnerEntry.nationalityIso}) wygrywa ${race.name} '
        'z mocą ${winnerEntry.telemetry.peak20mWattsPerKg.toStringAsFixed(2)} W/kg (20 min).';
    final decisiveMomentNote =
        'Kluczowa selekcja nastąpiła na ${race.signatureSectorOrClimb}, gdzie czołówka '
        'generowała ${winnerEntry.telemetry.vamMetersPerHour} m/h VAM.';

    return YouthU23RaceSimulationReport(
      race: race,
      seasonYear: seasonYear,
      simulatedAt: simulationDate ?? DateTime(seasonYear, race.month, 18),
      standings: standings,
      headlineSummary: headlineSummary,
      decisiveMomentNote: decisiveMomentNote,
    );
  }

  /// Tworzy skautingową teczkę kandydata do pierwszego kontraktu zawodowego na podstawie
  /// jego zebranych wyników i zarejestrowanych statystyk W/kg ze wszystkich wyścigów U23.
  JuniorProContractScoutingDossier buildProContractScoutingDossier({
    required Rider rider,
    required List<YouthU23RaceSimulationReport> seasonReports,
  }) {
    final entries = <YouthU23RiderRaceEntry>[];
    for (final report in seasonReports) {
      for (final entry in report.standings) {
        if (entry.riderId == rider.id) {
          entries.add(entry);
        }
      }
    }

    final weight = rider.physiology.weightKg > 0 ? rider.physiology.weightKg : 68.0;
    if (entries.isEmpty) {
      final base20m = rider.powerProfile.watts20m / weight;
      final base5m = rider.powerProfile.watts5m / weight;
      final base1m = rider.powerProfile.watts1m / weight;
      final base5s = rider.powerProfile.watts5s / weight;
      return JuniorProContractScoutingDossier(
        riderId: rider.id,
        riderName: rider.fullName,
        nationalityIso: rider.nationalityIso,
        age: rider.age,
        specialization: rider.specialization,
        racesTracked: 0,
        totalStageWins: 0,
        totalPodiums: 0,
        bestGcPosition: 0,
        totalUciYouthPoints: 0,
        best20mWattsPerKg: double.parse(base20m.toStringAsFixed(2)),
        average20mWattsPerKg: double.parse(base20m.toStringAsFixed(2)),
        peak5mWattsPerKg: double.parse(base5m.toStringAsFixed(2)),
        peak1mWattsPerKg: double.parse(base1m.toStringAsFixed(2)),
        peak5sWattsPerKg: double.parse(base5s.toStringAsFixed(2)),
        peak5sWatts: rider.powerProfile.watts5s,
        peakVamMetersPerHour: 0,
        scoutingReadinessScore: 25.0,
        readinessTier: ProContractReadinessTier.unprovenProspect,
        recommendedSalaryEur: 45000,
        recommendedContractYears: 2,
        scoutingVerdict:
            'Brak startów w wyścigach U23. Zasymuluj Tour de l\'Avenir, Giro Next Gen lub Paris-Roubaix Espoirs przed ofertą.',
      );
    }

    int wins = 0;
    int podiums = 0;
    int bestGc = 999;
    int totalUci = 0;
    double best20m = 0.0;
    double sum20m = 0.0;
    double peak5m = 0.0;
    double peak1m = 0.0;
    double peak5s = 0.0;
    int peak5sW = 0;
    int peakVam = 0;

    for (final e in entries) {
      wins += e.stageWins;
      podiums += e.podiums;
      if (e.gcPosition < bestGc) bestGc = e.gcPosition;
      totalUci += e.uciPointsEarned;
      if (e.telemetry.peak20mWattsPerKg > best20m) {
        best20m = e.telemetry.peak20mWattsPerKg;
      }
      sum20m += e.telemetry.peak20mWattsPerKg;
      if (e.telemetry.peak5mWattsPerKg > peak5m) {
        peak5m = e.telemetry.peak5mWattsPerKg;
      }
      if (e.telemetry.peak1mWattsPerKg > peak1m) {
        peak1m = e.telemetry.peak1mWattsPerKg;
      }
      if (e.telemetry.peak5sWattsPerKg > peak5s) {
        peak5s = e.telemetry.peak5sWattsPerKg;
      }
      if (e.telemetry.peak5sWatts > peak5sW) {
        peak5sW = e.telemetry.peak5sWatts;
      }
      if (e.telemetry.vamMetersPerHour > peakVam) {
        peakVam = e.telemetry.vamMetersPerHour;
      }
    }

    final avg20m = sum20m / entries.length;

    // Ocena gotowości 0-100: kombinacja W/kg (20m), wyników GC, punktów UCI oraz potencjału
    final wkgScore = ((best20m - 5.0) / 1.45 * 45.0).clamp(0.0, 48.0);
    final gcScore = (bestGc <= 1 ? 24.0 : bestGc <= 5 ? 18.0 : bestGc <= 10 ? 12.0 : 4.0);
    final uciScore = (totalUci / 180.0 * 18.0).clamp(0.0, 18.0);
    final potBonus = ((rider.potential - 70) / 30.0 * 10.0).clamp(0.0, 10.0);
    final readiness = (wkgScore + gcScore + uciScore + potBonus).clamp(0.0, 100.0);

    final ProContractReadinessTier tier;
    final int salary;
    final int years;
    final String verdict;

    if (readiness >= 74.0 || (best20m >= 6.05 && bestGc <= 5)) {
      tier = ProContractReadinessTier.worldTourReady;
      salary = (110000 + (readiness - 70) * 4500).round();
      years = 3;
      verdict =
          'Fenomenalne ${best20m.toStringAsFixed(2)} W/kg (20 min) i Top $bestGc GC w U23. '
          'Natychmiastowy kandydat do 3-letniego kontraktu WorldTour.';
    } else if (readiness >= 52.0 || bestGc <= 12 || wins > 0) {
      tier = ProContractReadinessTier.proTeamReady;
      salary = (60000 + (readiness - 45) * 1800).round();
      years = 2;
      verdict =
          'Solidna baza (${best20m.toStringAsFixed(2)} W/kg, $peakVam m/h VAM). '
          'Gotowy na status Stagiaire lub pierwszy kontrakt ProTeam.';
    } else {
      tier = ProContractReadinessTier.needsAnotherU23Year;
      salary = 38000;
      years = 1;
      verdict =
          'Obiecujący talent, ale ${best20m.toStringAsFixed(2)} W/kg jeszcze nie gwarantuje utrzymania tempa WT. '
          'Zalecany kolejny sezon w U23.';
    }

    return JuniorProContractScoutingDossier(
      riderId: rider.id,
      riderName: rider.fullName,
      nationalityIso: rider.nationalityIso,
      age: rider.age,
      specialization: rider.specialization,
      racesTracked: entries.length,
      totalStageWins: wins,
      totalPodiums: podiums,
      bestGcPosition: bestGc,
      totalUciYouthPoints: totalUci,
      best20mWattsPerKg: double.parse(best20m.toStringAsFixed(2)),
      average20mWattsPerKg: double.parse(avg20m.toStringAsFixed(2)),
      peak5mWattsPerKg: double.parse(peak5m.toStringAsFixed(2)),
      peak1mWattsPerKg: double.parse(peak1m.toStringAsFixed(2)),
      peak5sWattsPerKg: double.parse(peak5s.toStringAsFixed(2)),
      peak5sWatts: peak5sW,
      peakVamMetersPerHour: peakVam,
      scoutingReadinessScore: double.parse(readiness.toStringAsFixed(1)),
      readinessTier: tier,
      recommendedSalaryEur: salary,
      recommendedContractYears: years,
      scoutingVerdict: verdict,
    );
  }

  /// Generuje międzynarodową stawkę juniorów U23 (19–22 lata) do rywalizacji w kalendarzu.
  List<Rider> generateInternationalU23Field({
    int count = 28,
    int seasonYear = 2026,
    math.Random? rng,
    String raceIdSeed = 'u23',
  }) {
    final random = rng ?? math.Random(seed ?? 231);
    const firstNames = [
      'Léo',
      'Matteo',
      'Kacper',
      'Thibaut',
      'Jonas',
      'Pablo',
      'Bram',
      'Noah',
      'Szymon',
      'Lorenzo',
      'Emil',
      'Hugo',
      'Axel',
      'Mikołaj',
    ];
    const lastNames = [
      'Bisiaux',
      'Pellizzari',
      'Krawczyk',
      'Vermeersch',
      'Vingegaard-Jr',
      'Torres',
      'Vandenberghe',
      'De Vries',
      'Wiśniewski',
      'Rondel',
      'Nordhagen',
      'Chabrol',
      'Söderqvist',
      'Zieliński',
    ];
    const nations = [
      'FRA',
      'ITA',
      'POL',
      'BEL',
      'DEN',
      'ESP',
      'NED',
      'NOR',
      'GBR',
      'SLO',
      'COL',
      'GER',
    ];

    const specs = RiderSpecialization.values;
    final generated = <Rider>[];

    for (int i = 0; i < count; i++) {
      final spec = specs[i % specs.length];
      final age = 19 + (i % 4); // 19..22 lata
      final isClimber = spec == RiderSpecialization.gcClimber ||
          spec == RiderSpecialization.pureClimber;
      final isSprinter = spec == RiderSpecialization.pureSprinter ||
          spec == RiderSpecialization.versatileSprinter;
      final isCobbler = spec == RiderSpecialization.classicCobbles;

      final weight = isClimber
          ? 57.5 + random.nextDouble() * 6.5
          : isSprinter
              ? 73.0 + random.nextDouble() * 7.5
              : 64.0 + random.nextDouble() * 7.0;

      // Realistyczne W/kg elity U23 (5.3 - 6.35 W/kg na 20 min)
      final baseWkg = isClimber
          ? 5.65 + random.nextDouble() * 0.68
          : isCobbler
              ? 5.30 + random.nextDouble() * 0.55
              : 5.25 + random.nextDouble() * 0.60;

      final ftp = (weight * baseWkg * 0.94).round();
      final w20m = (weight * baseWkg).round();
      final w5m = (w20m * (1.16 + random.nextDouble() * 0.08)).round();
      final w3m = (w5m * 1.09).round();
      final w1m = (w5m * (1.35 + (isCobbler ? 0.12 : 0.0))).round();
      final w30s = (w1m * 1.24).round();
      final w15s = (w30s * 1.18).round();
      final w5s = isSprinter
          ? 1380 + random.nextInt(320)
          : 980 + random.nextInt(280);

      final potential = 72 + random.nextInt(25);
      final birthYear = seasonYear - age;

      generated.add(
        Rider(
          id: 'u23_${raceIdSeed}_$i',
          firstName: firstNames[(i * 3 + random.nextInt(5)) % firstNames.length],
          lastName: lastNames[(i * 5 + random.nextInt(7)) % lastNames.length],
          nationalityIso: nations[i % nations.length],
          birthDate: DateTime(birthYear, 1 + (i % 12), 10),
          potential: potential,
          specialization: spec,
          physiology: RiderPhysiology(
            heightCm: isClimber ? 174.0 : 181.0,
            weightKg: double.parse(weight.toStringAsFixed(1)),
            bodyFatPercentage: 7.8 + random.nextDouble() * 2.4,
            ftpWatts: ftp,
            wPrimeJoules: 19000 + random.nextInt(7000),
            vo2Max: 74.0 + random.nextDouble() * 11.0,
            maxHr: 196,
            restingHr: 39,
            lactateThresholdHr: 176,
            recoveryRate: 0.72 + random.nextDouble() * 0.22,
            glycogenCapacityGrams: 560.0,
            form: 76.0 + random.nextDouble() * 16.0,
            fatigue: 15.0 + random.nextDouble() * 15.0,
          ),
          powerProfile: RiderPowerProfile(
            watts5s: w5s,
            watts15s: w15s,
            watts30s: w30s,
            watts1m: w1m,
            watts3m: w3m,
            watts5m: w5m,
            watts20m: w20m,
            watts60m: ftp,
          ),
          skills: RiderSkills(
            cobbles: isCobbler ? 78 + random.nextInt(16) : 50 + random.nextInt(22),
            descending: 64 + random.nextInt(25),
            bikeHandling: 65 + random.nextInt(24),
            aeroPositioning: 62 + random.nextInt(24),
            draftingEfficiency: 65 + random.nextInt(22),
            raceIq: 62 + random.nextInt(25),
            rainResistance: 58 + random.nextInt(28),
            heatTolerance: 60 + random.nextInt(25),
            timeTrialPositioning: 58 + random.nextInt(28),
          ),
          appearance: RiderAppearance(
            faceShapeIndex: i % 5,
            skinToneHex: '#E8C3A0',
            hairStyleIndex: i % 6,
            hairColorHex: '#3B2F2F',
            facialHairIndex: 0,
            glassesModelId: 'aero_pro',
            glassesLensColorHex: '#D4AF37',
            helmetModelId: 'aero_carbon',
            shoeColorHex: '#FFFFFF',
            sockHeightProportion: 0.75,
            bodyBuildType: isClimber
                ? BodyBuildType.climberLean
                : isSprinter
                    ? BodyBuildType.sprinterMuscular
                    : BodyBuildType.allRounder,
          ),
          contract: RiderContract(
            teamId: 'u23_national_pool',
            role: RiderRole.neoPro,
            monthlySalaryEur: 1500,
            signingBonusEur: 0,
            winBonusEur: 500,
            releaseClauseEur: 50000,
            contractEndYear: seasonYear,
            morale: 78.0,
            leaderLoyalty: 65.0,
            requiredRacesIds: const [],
          ),
          health: const RiderHealth(
            acuteTrainingLoad: 25.0,
            chronicTrainingLoad: 78.0,
          ),
          careerPointsUci: random.nextInt(85),
        ),
      );
    }

    return generated;
  }

  List<_U23StageMeta> _buildStageProfiles(YouthU23RaceDefinition race) {
    if (race.stageCount == 1) {
      final tag = race.profile == YouthU23RaceProfile.cobblesMonument
          ? 'Bruk 5★'
          : 'Pagórki / Klasyk';
      return [_U23StageMeta(title: race.name, terrainTag: tag)];
    }

    final stages = <_U23StageMeta>[];
    for (int i = 1; i <= race.stageCount; i++) {
      if (i == 1 && race.ittWeight >= 0.15) {
        stages.add(_U23StageMeta(title: 'Etap $i (Prolog ITT)', terrainTag: 'ITT'));
      } else if (i == race.stageCount ||
          (race.mountainDifficulty >= 4.4 && i >= race.stageCount - 2)) {
        stages.add(
          _U23StageMeta(
            title: 'Etap $i (${race.signatureSectorOrClimb})',
            terrainTag: 'Góry HC',
          ),
        );
      } else if (i % 3 == 0) {
        stages.add(
          _U23StageMeta(title: 'Etap $i (Pagórki)', terrainTag: 'Pagórki'),
        );
      } else {
        stages.add(
          _U23StageMeta(title: 'Etap $i (Płaski)', terrainTag: 'Płaski / Sprint'),
        );
      }
    }
    return stages;
  }

  _RiderStageEval _evaluateRiderOnStage({
    required Rider rider,
    required YouthU23RaceDefinition race,
    required _U23StageMeta stageMeta,
    required math.Random rng,
    required double accumulatedFatiguePenalty,
  }) {
    final weight = rider.physiology.weightKg > 0 ? rider.physiology.weightKg : 68.0;
    final wkg20m = rider.powerProfile.watts20m / weight;
    final wkg5m = rider.powerProfile.watts5m / weight;
    final wkg1m = rider.powerProfile.watts1m / weight;
    final wkg5s = rider.powerProfile.watts5s / weight;
    final ftpW = rider.physiology.ftpWatts.toDouble();

    final dayFormFactor =
        0.96 + (rider.physiology.form / 100.0) * 0.06 + (rng.nextDouble() - 0.5) * 0.05;
    final fatigueMod =
        1.0 - (accumulatedFatiguePenalty * (1.2 - rider.physiology.recoveryRate * 0.5)).clamp(0.0, 0.08);
    final effortScale = (dayFormFactor * fatigueMod).clamp(0.88, 1.07);

    double score;
    switch (stageMeta.terrainTag) {
      case 'Góry HC':
        score = wkg20m * 18.5 +
            wkg5m * 6.0 +
            (rider.physiology.vo2Max * 0.35) +
            (rider.skills.descending * 0.14);
        break;
      case 'Bruk 5★':
        score = (ftpW / 38.0) * 3.8 +
            wkg1m * 4.2 +
            wkg5s * 1.1 +
            (rider.skills.cobbles * 0.72) +
            (rider.skills.bikeHandling * 0.35) +
            (rider.skills.rainResistance * 0.22);
        break;
      case 'ITT':
        score = (ftpW / 12.0) * 1.8 +
            wkg20m * 9.0 +
            (rider.skills.timeTrialPositioning * 0.45) +
            (rider.skills.aeroPositioning * 0.35);
        break;
      case 'Pagórki':
      case 'Pagórki / Klasyk':
        score = wkg5m * 9.5 +
            wkg1m * 5.2 +
            wkg20m * 7.0 +
            (rider.skills.raceIq * 0.28) +
            (rider.skills.descending * 0.18);
        break;
      default: // Płaski / Sprint
        score = wkg5s * 4.0 +
            (rider.powerProfile.watts5s / 90.0) +
            (rider.skills.draftingEfficiency * 0.30) +
            (rider.skills.bikeHandling * 0.25) +
            wkg20m * 4.0;
        break;
    }

    // Potencjał i szczęście dnia
    score += (rider.potential - 70) * 0.12;
    score *= effortScale;

    final crashChance = stageMeta.terrainTag == 'Bruk 5★'
        ? 0.085 - (rider.skills.bikeHandling / 2500.0)
        : 0.025;
    final hadIncident = rng.nextDouble() < crashChance.clamp(0.01, 0.12);
    if (hadIncident) {
      score *= 0.90;
    }

    final recorded20m = wkg20m * effortScale;
    final recorded5m = wkg5m * effortScale;
    final recorded1m = wkg1m * effortScale;
    final recorded5s = wkg5s * effortScale;

    // VAM ~ (W/kg * 270..295) na stromych podjazdach górskich
    final baseVamFactor = stageMeta.terrainTag == 'Góry HC'
        ? 286.0
        : stageMeta.terrainTag.contains('Pagórki')
            ? 248.0
            : 195.0;
    final stageVam = (recorded20m * baseVamFactor).round().clamp(950, 1980);

    return _RiderStageEval(
      rider: rider,
      performanceScore: score,
      stage20mWkg: recorded20m,
      stage5mWkg: recorded5m,
      stage1mWkg: recorded1m,
      stage5sWkg: recorded5s,
      stageVam: stageVam,
      hadIncident: hadIncident,
    );
  }

  int _calculateUciPointsForPosition(int position, int winPoints) {
    if (position == 1) return winPoints;
    if (position == 2) return (winPoints * 0.72).round();
    if (position == 3) return (winPoints * 0.54).round();
    if (position <= 5) return (winPoints * 0.38).round();
    if (position <= 10) return (winPoints * 0.22).round();
    if (position <= 20) return (winPoints * 0.10).round();
    return 0;
  }

  double _maxDouble(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce(math.max);
  }

  int _maxInt(List<int> values) {
    if (values.isEmpty) return 0;
    return values.reduce(math.max);
  }
}

class _U23StageMeta {
  final String title;
  final String terrainTag;

  const _U23StageMeta({required this.title, required this.terrainTag});
}

class _RiderStageEval {
  final Rider rider;
  final double performanceScore;
  final double stage20mWkg;
  final double stage5mWkg;
  final double stage1mWkg;
  final double stage5sWkg;
  final int stageVam;
  final bool hadIncident;

  const _RiderStageEval({
    required this.rider,
    required this.performanceScore,
    required this.stage20mWkg,
    required this.stage5mWkg,
    required this.stage1mWkg,
    required this.stage5sWkg,
    required this.stageVam,
    required this.hadIncident,
  });
}

/// Produkcyjny, responsywny panel UI kalendarza wyścigów U23 (`Tour de l'Avenir`,
/// `Giro Next Gen`, `Paris-Roubaix Espoirs`), wyników etapowych oraz telemetrii W/kg
/// juniorów przed podpisaniem pierwszego kontraktu zawodowego.
class YouthRaceCalendarU23Panel extends StatefulWidget {
  final List<Rider> devoRiders;
  final YouthRaceCalendarU23Simulator simulator;
  final int seasonYear;
  final Set<String> signedProRiderIds;
  final void Function(JuniorProContractScoutingDossier dossier)? onSignProContract;
  final void Function(YouthU23RaceSimulationReport report)? onRaceSimulated;

  const YouthRaceCalendarU23Panel({
    super.key,
    required this.devoRiders,
    this.simulator = const YouthRaceCalendarU23Simulator(),
    this.seasonYear = 2026,
    this.signedProRiderIds = const {},
    this.onSignProContract,
    this.onRaceSimulated,
  });

  @override
  State<YouthRaceCalendarU23Panel> createState() =>
      _YouthRaceCalendarU23PanelState();
}

class _YouthRaceCalendarU23PanelState extends State<YouthRaceCalendarU23Panel> {
  late String _selectedRaceId;
  YouthU23RaceProfile? _profileFilter;
  String? _selectedRiderId;
  bool _onlyPlayerDevo = false;
  final Map<String, YouthU23RaceSimulationReport> _reportsByRaceId = {};

  @override
  void initState() {
    super.initState();
    _selectedRaceId = YouthRaceCalendarU23Simulator.officialCalendar.first.id;
  }

  List<YouthU23RaceDefinition> get _filteredRaces =>
      widget.simulator.getCalendar(profileFilter: _profileFilter);

  YouthU23RaceDefinition get _activeRace {
    final races = _filteredRaces;
    if (races.isEmpty) {
      return YouthRaceCalendarU23Simulator.officialCalendar.first;
    }
    return races.firstWhere(
      (r) => r.id == _selectedRaceId,
      orElse: () => races.first,
    );
  }

  void _simulateSelectedRace() {
    final race = _activeRace;
    final report = widget.simulator.simulateRace(
      race: race,
      playerDevoRiders: widget.devoRiders,
      seasonYear: widget.seasonYear,
    );
    setState(() {
      _reportsByRaceId[race.id] = report;
      if (report.standings.isNotEmpty) {
        final playerFirst = report.playerDevoResults.isNotEmpty
            ? report.playerDevoResults.first
            : report.standings.first;
        _selectedRiderId = playerFirst.riderId;
      }
    });
    widget.onRaceSimulated?.call(report);
  }

  void _simulateFullSeason() {
    final calendar = widget.simulator.getCalendar();
    setState(() {
      for (final race in calendar) {
        if (!_reportsByRaceId.containsKey(race.id)) {
          final report = widget.simulator.simulateRace(
            race: race,
            playerDevoRiders: widget.devoRiders,
            seasonYear: widget.seasonYear,
          );
          _reportsByRaceId[race.id] = report;
          widget.onRaceSimulated?.call(report);
        }
      }
      final currentReport = _reportsByRaceId[_activeRace.id];
      if (currentReport != null && _selectedRiderId == null) {
        _selectedRiderId = currentReport.playerDevoResults.isNotEmpty
            ? currentReport.playerDevoResults.first.riderId
            : currentReport.standings.first.riderId;
      }
    });
  }

  Rider? _resolveRiderById(String riderId) {
    for (final r in widget.devoRiders) {
      if (r.id == riderId) return r;
    }
    final report = _reportsByRaceId[_activeRace.id];
    if (report == null) return null;
    for (final entry in report.standings) {
      if (entry.riderId == riderId) {
        return Rider(
          id: entry.riderId,
          firstName: entry.riderName.split(' ').first,
          lastName: entry.riderName.contains(' ')
              ? entry.riderName.substring(entry.riderName.indexOf(' ') + 1)
              : '',
          nationalityIso: entry.nationalityIso,
          birthDate: DateTime(widget.seasonYear - entry.age, 5, 1),
          potential: 84,
          specialization: entry.specialization,
          physiology: RiderPhysiology(
            heightCm: 178,
            weightKg: entry.telemetry.weightKg,
            bodyFatPercentage: 8.2,
            ftpWatts: (entry.telemetry.ftpWattsPerKg * entry.telemetry.weightKg).round(),
            wPrimeJoules: 21000,
            vo2Max: 80.0,
            maxHr: 196,
            restingHr: 39,
            lactateThresholdHr: 176,
            recoveryRate: 0.85,
            glycogenCapacityGrams: 560,
          ),
          powerProfile: RiderPowerProfile(
            watts5s: entry.telemetry.peak5sWatts,
            watts15s: (entry.telemetry.peak5sWatts * 0.85).round(),
            watts30s: (entry.telemetry.peak1mWattsPerKg * entry.telemetry.weightKg * 1.18).round(),
            watts1m: (entry.telemetry.peak1mWattsPerKg * entry.telemetry.weightKg).round(),
            watts3m: (entry.telemetry.peak5mWattsPerKg * entry.telemetry.weightKg * 1.07).round(),
            watts5m: (entry.telemetry.peak5mWattsPerKg * entry.telemetry.weightKg).round(),
            watts20m: (entry.telemetry.peak20mWattsPerKg * entry.telemetry.weightKg).round(),
            watts60m: (entry.telemetry.ftpWattsPerKg * entry.telemetry.weightKg).round(),
          ),
          skills: const RiderSkills(
            cobbles: 70,
            descending: 72,
            bikeHandling: 74,
            aeroPositioning: 70,
            draftingEfficiency: 72,
            raceIq: 72,
            rainResistance: 68,
            heatTolerance: 70,
            timeTrialPositioning: 68,
          ),
          appearance: const RiderAppearance(
            faceShapeIndex: 0,
            skinToneHex: '#E8C3A0',
            hairStyleIndex: 1,
            hairColorHex: '#3B2F2F',
            facialHairIndex: 0,
            glassesModelId: 'aero_pro',
            glassesLensColorHex: '#D4AF37',
            helmetModelId: 'aero_carbon',
            shoeColorHex: '#FFFFFF',
            sockHeightProportion: 0.75,
            bodyBuildType: BodyBuildType.allRounder,
          ),
          contract: RiderContract(
            teamId: 'u23_pool',
            role: RiderRole.neoPro,
            monthlySalaryEur: 1800,
            signingBonusEur: 0,
            winBonusEur: 600,
            releaseClauseEur: 60000,
            contractEndYear: widget.seasonYear,
            morale: 80.0,
            leaderLoyalty: 70.0,
            requiredRacesIds: const [],
          ),
          health: const RiderHealth(
            acuteTrainingLoad: 20.0,
            chronicTrainingLoad: 80.0,
          ),
          careerPointsUci: entry.uciPointsEarned,
        );
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 760;
          final isDesktopWide = constraints.maxWidth >= 1320;
          final activeReport = _reportsByRaceId[_activeRace.id];

          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 12 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderBar(isMobile),
                const SizedBox(height: 16),
                _buildProfileFilterRow(),
                const SizedBox(height: 16),
                _buildRaceCalendarSelector(isMobile),
                const SizedBox(height: 16),
                if (isMobile) ...[
                  _buildStandingsCard(activeReport, isMobile: true),
                  const SizedBox(height: 16),
                  _buildScoutingTelemetryCard(activeReport, isMobile: true),
                ] else if (isDesktopWide) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: _buildStandingsCard(activeReport, isMobile: false),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 5,
                        child: _buildScoutingTelemetryCard(activeReport,
                            isMobile: false),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: _buildStandingsCard(activeReport, isMobile: false),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 5,
                        child: _buildScoutingTelemetryCard(activeReport,
                            isMobile: false),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderBar(bool isMobile) {
    final simulatedCount = _reportsByRaceId.length;
    final totalCount = YouthRaceCalendarU23Simulator.officialCalendar.length;
    final allSimulated = simulatedCount >= totalCount;

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.emoji_events_outlined,
                    color: AppColors.goldAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Kalendarz Wyścigów U23 & Skauting W/kg',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: isMobile ? 16 : 19,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Tour de l\'Avenir • Giro Next Gen • Paris-Roubaix Espoirs ($simulatedCount/$totalCount rozegranych)',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _U23InteractiveActionButton(
                label: _reportsByRaceId.containsKey(_activeRace.id)
                    ? 'Symuluj ponownie'
                    : 'Symuluj wyścig',
                icon: Icons.play_arrow_rounded,
                isPrimary: true,
                onPressed: _simulateSelectedRace,
              ),
              _U23InteractiveActionButton(
                label: allSimulated ? 'Sezon ukończony' : 'Symuluj cały sezon',
                icon: Icons.fast_forward_rounded,
                isPrimary: false,
                enabled: !allSimulated,
                onPressed: allSimulated ? null : _simulateFullSeason,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileFilterRow() {
    const filters = <YouthU23RaceProfile?>[
      null,
      YouthU23RaceProfile.grandTourMountains,
      YouthU23RaceProfile.cobblesMonument,
      YouthU23RaceProfile.ardennesPuncher,
      YouthU23RaceProfile.mixedStageRace,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = _profileFilter == filter;
          final label = filter == null ? 'Wszystkie wyścigi' : filter.label;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _U23FilterChip(
              label: label,
              selected: isSelected,
              onTap: () {
                setState(() {
                  _profileFilter = filter;
                  final races = _filteredRaces;
                  if (races.isNotEmpty &&
                      !races.any((r) => r.id == _selectedRaceId)) {
                    _selectedRaceId = races.first.id;
                  }
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRaceCalendarSelector(bool isMobile) {
    final races = _filteredRaces;
    return SizedBox(
      height: isMobile ? 132 : 124,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: races.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final race = races[index];
          final isSelected = race.id == _activeRace.id;
          final report = _reportsByRaceId[race.id];

          return _U23RaceSelectorCard(
            race: race,
            isSelected: isSelected,
            report: report,
            width: isMobile ? 250 : 272,
            onTap: () {
              setState(() {
                _selectedRaceId = race.id;
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildStandingsCard(
    YouthU23RaceSimulationReport? report, {
    required bool isMobile,
  }) {
    final filteredStandings = report == null
        ? const <YouthU23RiderRaceEntry>[]
        : (_onlyPlayerDevo
            ? report.playerDevoResults
            : report.standings);

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _activeRace.name,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_activeRace.stageCount} et. • ${_activeRace.totalDistanceKm.round()} km • ${_activeRace.signatureSectorOrClimb}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              _U23FilterChip(
                label: 'Tylko Devo (${widget.devoRiders.length})',
                selected: _onlyPlayerDevo,
                onTap: () => setState(() => _onlyPlayerDevo = !_onlyPlayerDevo),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (report == null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.analytics_outlined,
                    color: AppColors.accentBlue,
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _activeRace.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _U23InteractiveActionButton(
                    label: 'Rozpocznij symulację ${_activeRace.name}',
                    icon: Icons.play_circle_outline_rounded,
                    isPrimary: true,
                    onPressed: _simulateSelectedRace,
                  ),
                ],
              ),
            )
          else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Text(
                report.headlineSummary,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.goldAccent,
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (filteredStandings.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'Brak kolarzy Devo w tym filtrze. Wyłącz filtr lub dodaj juniorów U23.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: math.min(filteredStandings.length, 15),
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final entry = filteredStandings[index];
                  final isSelected = entry.riderId == _selectedRiderId;
                  return _U23RiderStandingRow(
                    entry: entry,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        _selectedRiderId = entry.riderId;
                      });
                    },
                  );
                },
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildScoutingTelemetryCard(
    YouthU23RaceSimulationReport? report, {
    required bool isMobile,
  }) {
    YouthU23RiderRaceEntry? selectedEntry;
    if (report != null && report.standings.isNotEmpty) {
      selectedEntry = report.standings.firstWhere(
        (e) => e.riderId == _selectedRiderId,
        orElse: () => report.standings.first,
      );
    }

    final rider = selectedEntry != null
        ? _resolveRiderById(selectedEntry.riderId)
        : (widget.devoRiders.isNotEmpty ? widget.devoRiders.first : null);

    final dossier = rider != null
        ? widget.simulator.buildProContractScoutingDossier(
            rider: rider,
            seasonReports: _reportsByRaceId.values.toList(),
          )
        : null;

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: dossier == null
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Text(
                  'Wybierz lub zasymuluj wyścig U23, aby przeanalizować W/kg kolarza.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dossier.riderName,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${dossier.nationalityIso} • ${dossier.age} lat • ${dossier.specialization.displayName}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _ReadinessBadge(tier: dossier.readinessTier),
                  ],
                ),
                const SizedBox(height: 14),
                _buildWkgTelemetryGrid(dossier),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ocena Skauta przed Kontraktem Zawodowym',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.goldAccent,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        dossier.scoutingVerdict,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Rekomendacja: ${dossier.recommendedContractYears} lata • €${dossier.recommendedSalaryEur} / rok • Gotowość ${dossier.scoutingReadinessScore.toStringAsFixed(0)}/100',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFeatures: [FontFeature.tabularFigures()],
                          color: AppColors.accentBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selectedEntry != null &&
                    selectedEntry.stageBreakdown.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'Przebieg Etapów (W/kg 20 min & VAM)',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...selectedEntry.stageBreakdown.take(5).map(
                        (st) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.borderColor),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 28,
                                  child: Text(
                                    '#${st.position}',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                      color: st.position <= 3
                                          ? AppColors.goldAccent
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    st.stageTitle,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${st.stage20mWattsPerKg.toStringAsFixed(2)} W/kg',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    fontFeatures: [
                                      FontFeature.tabularFigures(),
                                    ],
                                    color: AppColors.cyanAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                ],
                const SizedBox(height: 14),
                _buildSignContractButton(dossier),
              ],
            ),
    );
  }

  Widget _buildWkgTelemetryGrid(JuniorProContractScoutingDossier dossier) {
    final metrics = [
      (
        '20 min W/kg',
        dossier.best20mWattsPerKg.toStringAsFixed(2),
        AppColors.goldAccent,
      ),
      (
        '5 min W/kg',
        dossier.peak5mWattsPerKg.toStringAsFixed(2),
        AppColors.accentBlue,
      ),
      (
        '1 min W/kg',
        dossier.peak1mWattsPerKg.toStringAsFixed(2),
        AppColors.cyanAccent,
      ),
      (
        'Sprint 5s',
        '${dossier.peak5sWatts} W',
        AppColors.statusSuccess,
      ),
      (
        'Szczyt VAM',
        '${dossier.peakVamMetersPerHour} m/h',
        AppColors.amberWarning,
      ),
      (
        'Pkt UCI U23',
        '${dossier.totalUciYouthPoints}',
        AppColors.textPrimary,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.75,
      ),
      itemBuilder: (context, index) {
        final m = metrics[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                m.$1,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  m.$2,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: m.$3,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSignContractButton(JuniorProContractScoutingDossier dossier) {
    final alreadySigned = widget.signedProRiderIds.contains(dossier.riderId);
    final canSign = !alreadySigned &&
        dossier.racesTracked > 0 &&
        widget.onSignProContract != null;

    return _U23InteractiveActionButton(
      label: alreadySigned
          ? 'Kontrakt zawodowy podpisany'
          : dossier.racesTracked == 0
              ? 'Zasymuluj wyścig przed kontraktem'
              : 'Podpisz pierwszy kontrakt Pro (€${dossier.recommendedSalaryEur}/rok)',
      icon: alreadySigned ? Icons.verified_rounded : Icons.edit_document,
      isPrimary: true,
      enabled: canSign,
      onPressed: canSign ? () => widget.onSignProContract!(dossier) : null,
    );
  }
}

class _ReadinessBadge extends StatelessWidget {
  final ProContractReadinessTier tier;

  const _ReadinessBadge({required this.tier});

  @override
  Widget build(BuildContext context) {
    final Color color;
    switch (tier) {
      case ProContractReadinessTier.worldTourReady:
        color = AppColors.goldAccent;
        break;
      case ProContractReadinessTier.proTeamReady:
        color = AppColors.statusSuccess;
        break;
      case ProContractReadinessTier.needsAnotherU23Year:
        color = AppColors.amberWarning;
        break;
      case ProContractReadinessTier.unprovenProspect:
        color = AppColors.textSecondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        tier.label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _U23RaceSelectorCard extends StatefulWidget {
  final YouthU23RaceDefinition race;
  final bool isSelected;
  final YouthU23RaceSimulationReport? report;
  final double width;
  final VoidCallback onTap;

  const _U23RaceSelectorCard({
    required this.race,
    required this.isSelected,
    required this.report,
    required this.width,
    required this.onTap,
  });

  @override
  State<_U23RaceSelectorCard> createState() => _U23RaceSelectorCardState();
}

class _U23RaceSelectorCardState extends State<_U23RaceSelectorCard> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isSelected
        ? AppColors.goldAccent
        : _focused
            ? AppColors.accentBlue
            : _hovered
                ? AppColors.primaryAccent
                : AppTheme.borderColor;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.985 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: widget.width,
            padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.surfaceLight
                : _hovered
                    ? AppColors.surfaceLight.withValues(alpha: 0.65)
                    : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: widget.isSelected ? 1.5 : 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.race.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    widget.report != null
                        ? Icons.check_circle_rounded
                        : Icons.schedule_rounded,
                    size: 16,
                    color: widget.report != null
                        ? AppColors.statusSuccess
                        : AppColors.textSecondary,
                  ),
                ],
              ),
              Text(
                '${widget.race.countryIso} • Miesiąc ${widget.race.month} • ${widget.race.profile.label}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                widget.report != null
                    ? 'Zwycięzca: ${widget.report!.winner?.riderName ?? '-'}'
                    : '${widget.race.stageCount} et. • ${widget.race.totalDistanceKm.round()} km',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: widget.report != null
                      ? AppColors.goldAccent
                      : AppColors.accentBlue,
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

class _U23RiderStandingRow extends StatefulWidget {
  final YouthU23RiderRaceEntry entry;
  final bool isSelected;
  final VoidCallback onTap;

  const _U23RiderStandingRow({
    required this.entry,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_U23RiderStandingRow> createState() => _U23RiderStandingRowState();
}

class _U23RiderStandingRowState extends State<_U23RiderStandingRow> {
  bool _hovered = false;
  bool _focused = false;

  String _formatGap(int seconds) {
    if (seconds <= 0) return '0:00';
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return '+$min:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.primaryAccent.withValues(alpha: 0.22)
                : _hovered
                    ? AppColors.surfaceLight
                    : AppColors.surfaceLight.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected
                  ? AppColors.goldAccent
                  : _focused
                      ? AppColors.accentBlue
                      : AppTheme.borderColor,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  '${e.gcPosition}.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: e.gcPosition == 1
                        ? AppColors.goldAccent
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            e.riderName,
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
                        if (e.isPlayerDevoRider) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryAccent.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'DEVO',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.goldAccent,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '${e.nationalityIso} • ${e.age}l • ${e.specialization.displayName}',
                      maxLines: 1,
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
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${e.telemetry.peak20mWattsPerKg.toStringAsFixed(2)} W/kg',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFeatures: [FontFeature.tabularFigures()],
                      color: AppColors.cyanAccent,
                    ),
                  ),
                  Text(
                    _formatGap(e.timeGapSeconds),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontFeatures: [FontFeature.tabularFigures()],
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _U23FilterChip extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _U23FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_U23FilterChip> createState() => _U23FilterChipState();
}

class _U23FilterChipState extends State<_U23FilterChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: widget.selected
                ? AppColors.primaryAccent
                : _hovered
                    ? AppColors.surfaceLight
                    : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.selected
                  ? AppColors.goldAccent
                  : _focused
                      ? AppColors.accentBlue
                      : AppTheme.borderColor,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
              color: widget.selected
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _U23InteractiveActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final bool enabled;
  final VoidCallback? onPressed;

  const _U23InteractiveActionButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    this.enabled = true,
    required this.onPressed,
  });

  @override
  State<_U23InteractiveActionButton> createState() =>
      _U23InteractiveActionButtonState();
}

class _U23InteractiveActionButtonState
    extends State<_U23InteractiveActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.enabled && widget.onPressed != null;
    final bgColor = !isEnabled
        ? AppColors.surfaceLight.withValues(alpha: 0.45)
        : widget.isPrimary
            ? (_hovered
                ? AppColors.primaryAccent.withValues(alpha: 0.9)
                : AppColors.primaryAccent)
            : (_hovered ? AppColors.surfaceLight : AppColors.surface);

    final borderColor = !isEnabled
        ? AppTheme.borderColor.withValues(alpha: 0.5)
        : _focused
            ? AppColors.accentBlue
            : widget.isPrimary
                ? AppColors.goldAccent.withValues(alpha: 0.7)
                : AppTheme.borderColor;

    return FocusableActionDetector(
      enabled: isEnabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: isEnabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: isEnabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: isEnabled ? () => setState(() => _pressed = false) : null,
        onTap: isEnabled ? widget.onPressed : null,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: isEnabled
                    ? AppColors.goldAccent
                    : AppColors.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isEnabled
                        ? AppColors.textPrimary
                        : AppColors.textSecondary.withValues(alpha: 0.6),
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
