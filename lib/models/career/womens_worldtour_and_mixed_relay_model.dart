import 'dart:math' as math;

import 'season_calendar.dart';

/// Dywizja drużyny w kobiecym kolarstwie szosowym UCI.
enum WomensDivision {
  womensWorldTour,
  womensProTeam,
  womensContinental;

  String toJson() => name;

  String get label {
    switch (this) {
      case WomensDivision.womensWorldTour:
        return "UCI Women's WorldTeam";
      case WomensDivision.womensProTeam:
        return "UCI Women's ProTeam";
      case WomensDivision.womensContinental:
        return "UCI Women's Continental";
    }
  }

  /// Minimalna wymagana liczba zawodniczek w kadrze wg regulaminu UCI.
  int get minRosterSize {
    switch (this) {
      case WomensDivision.womensWorldTour:
        return 15;
      case WomensDivision.womensProTeam:
        return 10;
      case WomensDivision.womensContinental:
        return 8;
    }
  }

  /// Maksymalna liczba zawodniczek w kadrze.
  int get maxRosterSize {
    switch (this) {
      case WomensDivision.womensWorldTour:
        return 22;
      case WomensDivision.womensProTeam:
        return 20;
      case WomensDivision.womensContinental:
        return 16;
    }
  }

  static WomensDivision fromJson(String value) {
    return WomensDivision.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => WomensDivision.womensWorldTour,
    );
  }
}

/// Kategoria wyścigu w kalendarzu UCI Women's WorldTour i niższych serii.
enum WomensRaceTier {
  wwtGrandTour,
  wwtMonument,
  wwtStageRace,
  wwtOneDay,
  proSeriesWomen,
  class1Women;

  String toJson() => name;

  String get label {
    switch (this) {
      case WomensRaceTier.wwtGrandTour:
        return 'WWT Grand Tour';
      case WomensRaceTier.wwtMonument:
        return 'WWT Monument';
      case WomensRaceTier.wwtStageRace:
        return 'WWT Stage Race';
      case WomensRaceTier.wwtOneDay:
        return 'WWT One-Day Classic';
      case WomensRaceTier.proSeriesWomen:
        return 'UCI ProSeries Women';
      case WomensRaceTier.class1Women:
        return 'UCI Class 1 Women';
    }
  }

  /// Punkty UCI dla zwyciężczyni klasyfikacji generalnej / wyścigu.
  int get winnerUciPoints {
    switch (this) {
      case WomensRaceTier.wwtGrandTour:
        return 800;
      case WomensRaceTier.wwtMonument:
        return 500;
      case WomensRaceTier.wwtStageRace:
        return 400;
      case WomensRaceTier.wwtOneDay:
        return 400;
      case WomensRaceTier.proSeriesWomen:
        return 200;
      case WomensRaceTier.class1Women:
        return 125;
    }
  }

  static WomensRaceTier fromJson(String value) {
    return WomensRaceTier.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => WomensRaceTier.wwtOneDay,
    );
  }
}

/// Typ klasyfikacji w wyścigach etapowych Women's WorldTour.
enum WomensClassificationType {
  general,
  points,
  mountains,
  youth,
  team;

  String toJson() => name;

  String get label {
    switch (this) {
      case WomensClassificationType.general:
        return 'Klasyfikacja Generalna (GC)';
      case WomensClassificationType.points:
        return 'Klasyfikacja Punktowa';
      case WomensClassificationType.mountains:
        return 'Klasyfikacja Górska (QOM)';
      case WomensClassificationType.youth:
        return 'Klasyfikacja Młodzieżowa (U23)';
      case WomensClassificationType.team:
        return 'Klasyfikacja Drużynowa';
    }
  }

  static WomensClassificationType fromJson(String value) {
    return WomensClassificationType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => WomensClassificationType.general,
    );
  }
}

/// Profil fizjologiczny i wydolnościowy zawodniczki Women's WorldTour.
class WomensPhysiologyProfile {
  final double weightKg;
  final double heightCm;
  final double ftpWatts;
  final double vo2Max;
  final double wPrimeJoules;
  final double watts5s;
  final double watts1m;
  final double watts5m;
  final double watts20m;
  final double recoveryRate; // 0.70 - 1.30
  final double aerodynamicsCda;

  const WomensPhysiologyProfile({
    required this.weightKg,
    required this.heightCm,
    required this.ftpWatts,
    required this.vo2Max,
    required this.wPrimeJoules,
    required this.watts5s,
    required this.watts1m,
    required this.watts5m,
    required this.watts20m,
    required this.recoveryRate,
    required this.aerodynamicsCda,
  });

  /// Stosunek mocy progowej FTP do masy ciała (W/kg).
  double get wPerKg => weightKg > 0.0 ? ftpWatts / weightKg : 0.0;

  /// Stosunek mocy 20-minutowej do masy ciała (W/kg).
  double get wPerKg20m => weightKg > 0.0 ? watts20m / weightKg : 0.0;

  /// Ocena ogólna (40-99) skalibrowana pod kobiecy peleton WorldTour.
  /// Światowa czołówka kobiet: 20m ~ 5.6-5.9 W/kg, 5m ~ 6.6-6.9 W/kg, sprint ~ 1150 W.
  int get overallRating {
    final safeWeight = weightKg > 0.0 ? weightKg : 58.0;
    final ratio20m = watts20m / safeWeight;
    final ratio5m = watts5m / safeWeight;
    final ratio1m = watts1m / safeWeight;

    final scoreClimb = ((ratio20m - 3.2) / (5.8 - 3.2) * 55.0 + 44.0).clamp(40.0, 99.0);
    final scoreVo2 = ((ratio5m - 4.0) / (6.8 - 4.0) * 55.0 + 44.0).clamp(40.0, 99.0);
    final scorePunch = ((ratio1m - 5.5) / (10.2 - 5.5) * 55.0 + 44.0).clamp(40.0, 99.0);
    final scoreSprint = ((watts5s - 650.0) / (1220.0 - 650.0) * 55.0 + 44.0).clamp(40.0, 99.0);

    final weighted = (scoreClimb * 0.35) +
        (scoreVo2 * 0.25) +
        (scorePunch * 0.20) +
        (scoreSprint * 0.20);
    return weighted.round().clamp(40, 99);
  }

  WomensPhysiologyProfile copyWith({
    double? weightKg,
    double? heightCm,
    double? ftpWatts,
    double? vo2Max,
    double? wPrimeJoules,
    double? watts5s,
    double? watts1m,
    double? watts5m,
    double? watts20m,
    double? recoveryRate,
    double? aerodynamicsCda,
  }) {
    return WomensPhysiologyProfile(
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      ftpWatts: ftpWatts ?? this.ftpWatts,
      vo2Max: vo2Max ?? this.vo2Max,
      wPrimeJoules: wPrimeJoules ?? this.wPrimeJoules,
      watts5s: watts5s ?? this.watts5s,
      watts1m: watts1m ?? this.watts1m,
      watts5m: watts5m ?? this.watts5m,
      watts20m: watts20m ?? this.watts20m,
      recoveryRate: recoveryRate ?? this.recoveryRate,
      aerodynamicsCda: aerodynamicsCda ?? this.aerodynamicsCda,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weightKg': weightKg,
      'heightCm': heightCm,
      'ftpWatts': ftpWatts,
      'vo2Max': vo2Max,
      'wPrimeJoules': wPrimeJoules,
      'watts5s': watts5s,
      'watts1m': watts1m,
      'watts5m': watts5m,
      'watts20m': watts20m,
      'recoveryRate': recoveryRate,
      'aerodynamicsCda': aerodynamicsCda,
    };
  }

  factory WomensPhysiologyProfile.fromJson(Map<String, dynamic> json) {
    return WomensPhysiologyProfile(
      weightKg: (json['weightKg'] as num).toDouble(),
      heightCm: (json['heightCm'] as num).toDouble(),
      ftpWatts: (json['ftpWatts'] as num).toDouble(),
      vo2Max: (json['vo2Max'] as num).toDouble(),
      wPrimeJoules: (json['wPrimeJoules'] as num).toDouble(),
      watts5s: (json['watts5s'] as num).toDouble(),
      watts1m: (json['watts1m'] as num).toDouble(),
      watts5m: (json['watts5m'] as num).toDouble(),
      watts20m: (json['watts20m'] as num).toDouble(),
      recoveryRate: (json['recoveryRate'] as num?)?.toDouble() ?? 1.0,
      aerodynamicsCda: (json['aerodynamicsCda'] as num?)?.toDouble() ?? 0.215,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WomensPhysiologyProfile &&
        other.weightKg == weightKg &&
        other.ftpWatts == ftpWatts &&
        other.vo2Max == vo2Max &&
        other.watts5s == watts5s;
  }

  @override
  int get hashCode => Object.hash(weightKg, ftpWatts, vo2Max, watts5s);
}

/// Profil drużyny kobiecej w UCI Women's WorldTour lub ProTeam.
class WomensTeamProfile {
  final String teamId;
  final String name;
  final String shortCode;
  final String countryIso;
  final WomensDivision division;
  final String primaryColorHex;
  final String secondaryColorHex;
  final int annualBudgetEur;
  final int uciPoints;
  final int seasonWins;
  final String? linkedMensTeamId;
  final List<String> rosterRiderIds;
  final int staffLevel; // 1-100
  final int equipmentTier; // 1-5

  const WomensTeamProfile({
    required this.teamId,
    required this.name,
    required this.shortCode,
    required this.countryIso,
    required this.division,
    required this.primaryColorHex,
    required this.secondaryColorHex,
    required this.annualBudgetEur,
    required this.uciPoints,
    this.seasonWins = 0,
    this.linkedMensTeamId,
    required this.rosterRiderIds,
    this.staffLevel = 75,
    this.equipmentTier = 4,
  });

  int get rosterSize => rosterRiderIds.length;

  /// Czy drużyna ma obowiązkowy start we wszystkich wyścigach WWT.
  bool get hasMandatoryWwtEntry => division == WomensDivision.womensWorldTour;

  /// Czy skład spełnia regulaminowy limit liczby zawodniczek dla dywizji.
  bool get isRosterCompliant =>
      rosterSize >= division.minRosterSize &&
      rosterSize <= division.maxRosterSize;

  WomensTeamProfile copyWith({
    String? teamId,
    String? name,
    String? shortCode,
    String? countryIso,
    WomensDivision? division,
    String? primaryColorHex,
    String? secondaryColorHex,
    int? annualBudgetEur,
    int? uciPoints,
    int? seasonWins,
    String? linkedMensTeamId,
    List<String>? rosterRiderIds,
    int? staffLevel,
    int? equipmentTier,
  }) {
    return WomensTeamProfile(
      teamId: teamId ?? this.teamId,
      name: name ?? this.name,
      shortCode: shortCode ?? this.shortCode,
      countryIso: countryIso ?? this.countryIso,
      division: division ?? this.division,
      primaryColorHex: primaryColorHex ?? this.primaryColorHex,
      secondaryColorHex: secondaryColorHex ?? this.secondaryColorHex,
      annualBudgetEur: annualBudgetEur ?? this.annualBudgetEur,
      uciPoints: uciPoints ?? this.uciPoints,
      seasonWins: seasonWins ?? this.seasonWins,
      linkedMensTeamId: linkedMensTeamId ?? this.linkedMensTeamId,
      rosterRiderIds: rosterRiderIds ?? this.rosterRiderIds,
      staffLevel: staffLevel ?? this.staffLevel,
      equipmentTier: equipmentTier ?? this.equipmentTier,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'teamId': teamId,
      'name': name,
      'shortCode': shortCode,
      'countryIso': countryIso,
      'division': division.toJson(),
      'primaryColorHex': primaryColorHex,
      'secondaryColorHex': secondaryColorHex,
      'annualBudgetEur': annualBudgetEur,
      'uciPoints': uciPoints,
      'seasonWins': seasonWins,
      'linkedMensTeamId': linkedMensTeamId,
      'rosterRiderIds': rosterRiderIds,
      'staffLevel': staffLevel,
      'equipmentTier': equipmentTier,
    };
  }

  factory WomensTeamProfile.fromJson(Map<String, dynamic> json) {
    return WomensTeamProfile(
      teamId: json['teamId'] as String,
      name: json['name'] as String,
      shortCode: json['shortCode'] as String,
      countryIso: json['countryIso'] as String,
      division: WomensDivision.fromJson(json['division'] as String),
      primaryColorHex: json['primaryColorHex'] as String,
      secondaryColorHex: json['secondaryColorHex'] as String,
      annualBudgetEur: (json['annualBudgetEur'] as num).toInt(),
      uciPoints: (json['uciPoints'] as num).toInt(),
      seasonWins: (json['seasonWins'] as num?)?.toInt() ?? 0,
      linkedMensTeamId: json['linkedMensTeamId'] as String?,
      rosterRiderIds: (json['rosterRiderIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      staffLevel: (json['staffLevel'] as num?)?.toInt() ?? 75,
      equipmentTier: (json['equipmentTier'] as num?)?.toInt() ?? 4,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WomensTeamProfile && other.teamId == teamId;
  }

  @override
  int get hashCode => teamId.hashCode;
}

/// Pojedyncze wydarzenie wyścigowe w kalendarzu UCI Women's WorldTour.
class WomensRaceEvent {
  final String raceId;
  final String name;
  final String countryIso;
  final WomensRaceTier tier;
  final DateTime startDate;
  final int stageCount;
  final double totalDistanceKm;
  final int elevationGainM;
  final int prizePoolEur;
  final int maxRidersPerTeam;
  final RaceCompletionStatus status;
  final String? winnerRiderId;
  final String? winnerRiderName;
  final String? winnerTeamId;

  const WomensRaceEvent({
    required this.raceId,
    required this.name,
    required this.countryIso,
    required this.tier,
    required this.startDate,
    required this.stageCount,
    required this.totalDistanceKm,
    required this.elevationGainM,
    required this.prizePoolEur,
    this.maxRidersPerTeam = 6,
    this.status = RaceCompletionStatus.upcoming,
    this.winnerRiderId,
    this.winnerRiderName,
    this.winnerTeamId,
  });

  bool get isStageRace => stageCount > 1;

  WomensRaceEvent copyWith({
    String? raceId,
    String? name,
    String? countryIso,
    WomensRaceTier? tier,
    DateTime? startDate,
    int? stageCount,
    double? totalDistanceKm,
    int? elevationGainM,
    int? prizePoolEur,
    int? maxRidersPerTeam,
    RaceCompletionStatus? status,
    String? winnerRiderId,
    String? winnerRiderName,
    String? winnerTeamId,
  }) {
    return WomensRaceEvent(
      raceId: raceId ?? this.raceId,
      name: name ?? this.name,
      countryIso: countryIso ?? this.countryIso,
      tier: tier ?? this.tier,
      startDate: startDate ?? this.startDate,
      stageCount: stageCount ?? this.stageCount,
      totalDistanceKm: totalDistanceKm ?? this.totalDistanceKm,
      elevationGainM: elevationGainM ?? this.elevationGainM,
      prizePoolEur: prizePoolEur ?? this.prizePoolEur,
      maxRidersPerTeam: maxRidersPerTeam ?? this.maxRidersPerTeam,
      status: status ?? this.status,
      winnerRiderId: winnerRiderId ?? this.winnerRiderId,
      winnerRiderName: winnerRiderName ?? this.winnerRiderName,
      winnerTeamId: winnerTeamId ?? this.winnerTeamId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'raceId': raceId,
      'name': name,
      'countryIso': countryIso,
      'tier': tier.toJson(),
      'startDate': startDate.toIso8601String(),
      'stageCount': stageCount,
      'totalDistanceKm': totalDistanceKm,
      'elevationGainM': elevationGainM,
      'prizePoolEur': prizePoolEur,
      'maxRidersPerTeam': maxRidersPerTeam,
      'status': status.toJson(),
      'winnerRiderId': winnerRiderId,
      'winnerRiderName': winnerRiderName,
      'winnerTeamId': winnerTeamId,
    };
  }

  factory WomensRaceEvent.fromJson(Map<String, dynamic> json) {
    return WomensRaceEvent(
      raceId: json['raceId'] as String,
      name: json['name'] as String,
      countryIso: json['countryIso'] as String,
      tier: WomensRaceTier.fromJson(json['tier'] as String),
      startDate: DateTime.parse(json['startDate'] as String),
      stageCount: (json['stageCount'] as num).toInt(),
      totalDistanceKm: (json['totalDistanceKm'] as num).toDouble(),
      elevationGainM: (json['elevationGainM'] as num).toInt(),
      prizePoolEur: (json['prizePoolEur'] as num).toInt(),
      maxRidersPerTeam: (json['maxRidersPerTeam'] as num?)?.toInt() ?? 6,
      status: RaceCompletionStatus.fromJson(
        (json['status'] as String?) ?? 'upcoming',
      ),
      winnerRiderId: json['winnerRiderId'] as String?,
      winnerRiderName: json['winnerRiderName'] as String?,
      winnerTeamId: json['winnerTeamId'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WomensRaceEvent && other.raceId == raceId;
  }

  @override
  int get hashCode => raceId.hashCode;
}

/// Oferta transferowa na rynku zawodniczek Women's WorldTour.
class WomensTransferListing {
  final String riderId;
  final String riderName;
  final String nationalityIso;
  final String? currentTeamId;
  final int overallRating;
  final int annualSalaryDemandEur;
  final int buyoutFeeEur;
  final int contractYearsDesired;

  const WomensTransferListing({
    required this.riderId,
    required this.riderName,
    required this.nationalityIso,
    this.currentTeamId,
    required this.overallRating,
    required this.annualSalaryDemandEur,
    required this.buyoutFeeEur,
    this.contractYearsDesired = 2,
  });

  bool get isFreeAgent => currentTeamId == null;

  WomensTransferListing copyWith({
    String? riderId,
    String? riderName,
    String? nationalityIso,
    String? currentTeamId,
    int? overallRating,
    int? annualSalaryDemandEur,
    int? buyoutFeeEur,
    int? contractYearsDesired,
  }) {
    return WomensTransferListing(
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      nationalityIso: nationalityIso ?? this.nationalityIso,
      currentTeamId: currentTeamId ?? this.currentTeamId,
      overallRating: overallRating ?? this.overallRating,
      annualSalaryDemandEur:
          annualSalaryDemandEur ?? this.annualSalaryDemandEur,
      buyoutFeeEur: buyoutFeeEur ?? this.buyoutFeeEur,
      contractYearsDesired: contractYearsDesired ?? this.contractYearsDesired,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'riderName': riderName,
      'nationalityIso': nationalityIso,
      'currentTeamId': currentTeamId,
      'overallRating': overallRating,
      'annualSalaryDemandEur': annualSalaryDemandEur,
      'buyoutFeeEur': buyoutFeeEur,
      'contractYearsDesired': contractYearsDesired,
    };
  }

  factory WomensTransferListing.fromJson(Map<String, dynamic> json) {
    return WomensTransferListing(
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      nationalityIso: json['nationalityIso'] as String,
      currentTeamId: json['currentTeamId'] as String?,
      overallRating: (json['overallRating'] as num).toInt(),
      annualSalaryDemandEur: (json['annualSalaryDemandEur'] as num).toInt(),
      buyoutFeeEur: (json['buyoutFeeEur'] as num).toInt(),
      contractYearsDesired:
          (json['contractYearsDesired'] as num?)?.toInt() ?? 2,
    );
  }
}

/// Pełny stan sezonu UCI Women's WorldTour w zapisie kariery.
class WomensWorldTourSeasonState {
  final int seasonYear;
  final List<WomensTeamProfile> teams;
  final List<WomensRaceEvent> calendarEvents;
  final Map<String, int> individualUciStandings; // riderId -> points
  final Map<String, int> youthUciStandings; // riderId -> points
  final List<WomensTransferListing> transferMarket;

  const WomensWorldTourSeasonState({
    required this.seasonYear,
    required this.teams,
    required this.calendarEvents,
    this.individualUciStandings = const {},
    this.youthUciStandings = const {},
    this.transferMarket = const [],
  });

  /// Ranking drużyn posortowany malejąco po punktach UCI, a następnie wygranych.
  List<WomensTeamProfile> get teamsSortedByUciPoints {
    final sorted = List<WomensTeamProfile>.from(teams);
    sorted.sort((a, b) {
      final ptsCmp = b.uciPoints.compareTo(a.uciPoints);
      if (ptsCmp != 0) return ptsCmp;
      return b.seasonWins.compareTo(a.seasonWins);
    });
    return sorted;
  }

  /// Nadchodzące wyścigi posortowane chronologicznie.
  List<WomensRaceEvent> upcomingEvents({DateTime? fromDate}) {
    final filtered = calendarEvents.where((event) {
      if (event.status != RaceCompletionStatus.upcoming) return false;
      if (fromDate != null && event.startDate.isBefore(fromDate)) return false;
      return true;
    }).toList();
    filtered.sort((a, b) => a.startDate.compareTo(b.startDate));
    return filtered;
  }

  /// Rejestruje wynik zakończonego wyścigu WWT i aktualizuje punkty UCI.
  WomensWorldTourSeasonState recordRaceCompletion({
    required String raceId,
    required String winnerRiderId,
    required String winnerRiderName,
    required String winnerTeamId,
    bool isYouthEligible = false,
  }) {
    WomensRaceEvent? targetEvent;
    final updatedEvents = calendarEvents.map((event) {
      if (event.raceId == raceId) {
        targetEvent = event.copyWith(
          status: RaceCompletionStatus.completed,
          winnerRiderId: winnerRiderId,
          winnerRiderName: winnerRiderName,
          winnerTeamId: winnerTeamId,
        );
        return targetEvent!;
      }
      return event;
    }).toList();

    if (targetEvent == null) {
      return this;
    }

    final pointsAwarded = targetEvent!.tier.winnerUciPoints;
    final updatedRiderPts = Map<String, int>.from(individualUciStandings);
    updatedRiderPts[winnerRiderId] =
        (updatedRiderPts[winnerRiderId] ?? 0) + pointsAwarded;

    final updatedYouthPts = Map<String, int>.from(youthUciStandings);
    if (isYouthEligible) {
      updatedYouthPts[winnerRiderId] =
          (updatedYouthPts[winnerRiderId] ?? 0) + pointsAwarded;
    }

    final updatedTeams = teams.map((team) {
      if (team.teamId == winnerTeamId) {
        return team.copyWith(
          uciPoints: team.uciPoints + pointsAwarded,
          seasonWins: team.seasonWins + 1,
        );
      }
      return team;
    }).toList();

    return copyWith(
      teams: updatedTeams,
      calendarEvents: updatedEvents,
      individualUciStandings: updatedRiderPts,
      youthUciStandings: updatedYouthPts,
    );
  }

  WomensWorldTourSeasonState copyWith({
    int? seasonYear,
    List<WomensTeamProfile>? teams,
    List<WomensRaceEvent>? calendarEvents,
    Map<String, int>? individualUciStandings,
    Map<String, int>? youthUciStandings,
    List<WomensTransferListing>? transferMarket,
  }) {
    return WomensWorldTourSeasonState(
      seasonYear: seasonYear ?? this.seasonYear,
      teams: teams ?? this.teams,
      calendarEvents: calendarEvents ?? this.calendarEvents,
      individualUciStandings:
          individualUciStandings ?? this.individualUciStandings,
      youthUciStandings: youthUciStandings ?? this.youthUciStandings,
      transferMarket: transferMarket ?? this.transferMarket,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'seasonYear': seasonYear,
      'teams': teams.map((t) => t.toJson()).toList(),
      'calendarEvents': calendarEvents.map((e) => e.toJson()).toList(),
      'individualUciStandings': individualUciStandings,
      'youthUciStandings': youthUciStandings,
      'transferMarket': transferMarket.map((l) => l.toJson()).toList(),
    };
  }

  factory WomensWorldTourSeasonState.fromJson(Map<String, dynamic> json) {
    return WomensWorldTourSeasonState(
      seasonYear: (json['seasonYear'] as num).toInt(),
      teams: (json['teams'] as List<dynamic>)
          .map((e) => WomensTeamProfile.fromJson(e as Map<String, dynamic>))
          .toList(),
      calendarEvents: (json['calendarEvents'] as List<dynamic>)
          .map((e) => WomensRaceEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      individualUciStandings:
          (json['individualUciStandings'] as Map<String, dynamic>? ?? {})
              .map((k, v) => MapEntry(k, (v as num).toInt())),
      youthUciStandings:
          (json['youthUciStandings'] as Map<String, dynamic>? ?? {})
              .map((k, v) => MapEntry(k, (v as num).toInt())),
      transferMarket: (json['transferMarket'] as List<dynamic>? ?? [])
          .map(
            (e) => WomensTransferListing.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

// ============================================================================
// DRUŻYNOWA SZTAFETA MIESZANA (UCI MIXED RELAY TTT)
// ============================================================================

/// Zmiana w Drużynowej Sztafecie Mieszanej (3 mężczyzn + 3 kobiety).
enum MixedRelayLegType {
  mensTrio,
  womensTrio;

  String toJson() => name;

  String get label {
    switch (this) {
      case MixedRelayLegType.mensTrio:
        return 'Zmiana 1: Trójka Męska';
      case MixedRelayLegType.womensTrio:
        return 'Zmiana 2: Trójka Kobieca';
    }
  }

  static MixedRelayLegType fromJson(String value) {
    return MixedRelayLegType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => MixedRelayLegType.mensTrio,
    );
  }
}

/// Faza wyścigu drużyny w Sztafecie Mieszanej TTT.
enum MixedRelayPhase {
  preStart,
  mensLegActive,
  handoverApproaching,
  handoverWindowOpen,
  womensLegActive,
  finished,
  disqualified;

  String toJson() => name;

  String get label {
    switch (this) {
      case MixedRelayPhase.preStart:
        return 'Oczekiwanie na rampie';
      case MixedRelayPhase.mensLegActive:
        return 'Jazda trójki męskiej';
      case MixedRelayPhase.handoverApproaching:
        return 'Strefa przekazania zmiany';
      case MixedRelayPhase.handoverWindowOpen:
        return 'Bramka otwarta — start kobiet!';
      case MixedRelayPhase.womensLegActive:
        return 'Jazda trójki kobiecej';
      case MixedRelayPhase.finished:
        return 'Na mecie';
      case MixedRelayPhase.disqualified:
        return 'Dyskwalifikacja (DSQ)';
    }
  }

  static MixedRelayPhase fromJson(String value) {
    return MixedRelayPhase.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => MixedRelayPhase.preStart,
    );
  }
}

/// Zawodnik lub zawodniczka w składzie trójki Sztafety Mieszanej TTT.
class MixedRelayRiderSlot {
  final String riderId;
  final String fullName;
  final String nationalityIso;
  final bool isFemale;
  final double ftpWatts;
  final double weightKg;
  final double aerodynamicsCda;
  final int timeTrialSkill; // 1-100
  final double distanceMeters;
  final double currentSpeedKmh;
  final double currentPowerWatts;
  final double wPrimeRemainingPct; // 0.0 - 1.0
  final bool isPulling;
  final bool isDropped;
  final bool finishedLeg;
  final double? legFinishTimeSeconds;

  const MixedRelayRiderSlot({
    required this.riderId,
    required this.fullName,
    required this.nationalityIso,
    required this.isFemale,
    required this.ftpWatts,
    required this.weightKg,
    required this.aerodynamicsCda,
    required this.timeTrialSkill,
    this.distanceMeters = 0.0,
    this.currentSpeedKmh = 0.0,
    this.currentPowerWatts = 0.0,
    this.wPrimeRemainingPct = 1.0,
    this.isPulling = false,
    this.isDropped = false,
    this.finishedLeg = false,
    this.legFinishTimeSeconds,
  });

  double get wPerKg => weightKg > 0.0 ? ftpWatts / weightKg : 0.0;

  MixedRelayRiderSlot copyWith({
    String? riderId,
    String? fullName,
    String? nationalityIso,
    bool? isFemale,
    double? ftpWatts,
    double? weightKg,
    double? aerodynamicsCda,
    int? timeTrialSkill,
    double? distanceMeters,
    double? currentSpeedKmh,
    double? currentPowerWatts,
    double? wPrimeRemainingPct,
    bool? isPulling,
    bool? isDropped,
    bool? finishedLeg,
    double? legFinishTimeSeconds,
  }) {
    return MixedRelayRiderSlot(
      riderId: riderId ?? this.riderId,
      fullName: fullName ?? this.fullName,
      nationalityIso: nationalityIso ?? this.nationalityIso,
      isFemale: isFemale ?? this.isFemale,
      ftpWatts: ftpWatts ?? this.ftpWatts,
      weightKg: weightKg ?? this.weightKg,
      aerodynamicsCda: aerodynamicsCda ?? this.aerodynamicsCda,
      timeTrialSkill: timeTrialSkill ?? this.timeTrialSkill,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      currentSpeedKmh: currentSpeedKmh ?? this.currentSpeedKmh,
      currentPowerWatts: currentPowerWatts ?? this.currentPowerWatts,
      wPrimeRemainingPct: wPrimeRemainingPct ?? this.wPrimeRemainingPct,
      isPulling: isPulling ?? this.isPulling,
      isDropped: isDropped ?? this.isDropped,
      finishedLeg: finishedLeg ?? this.finishedLeg,
      legFinishTimeSeconds: legFinishTimeSeconds ?? this.legFinishTimeSeconds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'fullName': fullName,
      'nationalityIso': nationalityIso,
      'isFemale': isFemale,
      'ftpWatts': ftpWatts,
      'weightKg': weightKg,
      'aerodynamicsCda': aerodynamicsCda,
      'timeTrialSkill': timeTrialSkill,
      'distanceMeters': distanceMeters,
      'currentSpeedKmh': currentSpeedKmh,
      'currentPowerWatts': currentPowerWatts,
      'wPrimeRemainingPct': wPrimeRemainingPct,
      'isPulling': isPulling,
      'isDropped': isDropped,
      'finishedLeg': finishedLeg,
      'legFinishTimeSeconds': legFinishTimeSeconds,
    };
  }

  factory MixedRelayRiderSlot.fromJson(Map<String, dynamic> json) {
    return MixedRelayRiderSlot(
      riderId: json['riderId'] as String,
      fullName: json['fullName'] as String,
      nationalityIso: json['nationalityIso'] as String,
      isFemale: json['isFemale'] as bool,
      ftpWatts: (json['ftpWatts'] as num).toDouble(),
      weightKg: (json['weightKg'] as num).toDouble(),
      aerodynamicsCda: (json['aerodynamicsCda'] as num).toDouble(),
      timeTrialSkill: (json['timeTrialSkill'] as num).toInt(),
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble() ?? 0.0,
      currentSpeedKmh: (json['currentSpeedKmh'] as num?)?.toDouble() ?? 0.0,
      currentPowerWatts: (json['currentPowerWatts'] as num?)?.toDouble() ?? 0.0,
      wPrimeRemainingPct:
          (json['wPrimeRemainingPct'] as num?)?.toDouble() ?? 1.0,
      isPulling: json['isPulling'] as bool? ?? false,
      isDropped: json['isDropped'] as bool? ?? false,
      finishedLeg: json['finishedLeg'] as bool? ?? false,
      legFinishTimeSeconds:
          (json['legFinishTimeSeconds'] as num?)?.toDouble(),
    );
  }
}

/// Zdarzenie przekazania zmiany na strefie startowej między trójką męską a kobiecą.
/// Czas zmiany liczy się w momencie przecięcia linii przez 2. zawodnika trójki męskiej.
class MixedRelayHandoverEvent {
  final String teamId;
  final String mensSecondRiderId;
  final String mensSecondRiderName;
  final double handoverElapsedSeconds;
  final double gateReactionDelaySeconds;
  final double falseStartPenaltySeconds;
  final double handoverDistanceMeters;

  const MixedRelayHandoverEvent({
    required this.teamId,
    required this.mensSecondRiderId,
    required this.mensSecondRiderName,
    required this.handoverElapsedSeconds,
    required this.gateReactionDelaySeconds,
    this.falseStartPenaltySeconds = 0.0,
    required this.handoverDistanceMeters,
  });

  /// Ocena jakości przekazania zmiany w skali 0-100%.
  double get handoverQualityScore {
    if (falseStartPenaltySeconds > 0.0) {
      return 15.0;
    }
    // Idealna reakcja <= 0.15s daje 100%, powyżej 1.5s spada do 30%.
    final normalized =
        1.0 - ((gateReactionDelaySeconds - 0.15).clamp(0.0, 1.35) / 1.35);
    return (30.0 + normalized * 70.0).clamp(0.0, 100.0);
  }

  String get qualityRatingLabel {
    if (falseStartPenaltySeconds > 0.0) return 'Falstart (+kara)';
    if (gateReactionDelaySeconds <= 0.25) return 'Perfekcyjna zmiana';
    if (gateReactionDelaySeconds <= 0.60) return 'Dobra zmiana';
    return 'Spóźniona reakcja';
  }

  Map<String, dynamic> toJson() {
    return {
      'teamId': teamId,
      'mensSecondRiderId': mensSecondRiderId,
      'mensSecondRiderName': mensSecondRiderName,
      'handoverElapsedSeconds': handoverElapsedSeconds,
      'gateReactionDelaySeconds': gateReactionDelaySeconds,
      'falseStartPenaltySeconds': falseStartPenaltySeconds,
      'handoverDistanceMeters': handoverDistanceMeters,
    };
  }

  factory MixedRelayHandoverEvent.fromJson(Map<String, dynamic> json) {
    return MixedRelayHandoverEvent(
      teamId: json['teamId'] as String,
      mensSecondRiderId: json['mensSecondRiderId'] as String,
      mensSecondRiderName: json['mensSecondRiderName'] as String,
      handoverElapsedSeconds:
          (json['handoverElapsedSeconds'] as num).toDouble(),
      gateReactionDelaySeconds:
          (json['gateReactionDelaySeconds'] as num).toDouble(),
      falseStartPenaltySeconds:
          (json['falseStartPenaltySeconds'] as num?)?.toDouble() ?? 0.0,
      handoverDistanceMeters:
          (json['handoverDistanceMeters'] as num).toDouble(),
    );
  }
}

/// Zgłoszenie i stan bieżący drużyny narodowej/klubowej w Sztafecie Mieszanej TTT.
class MixedRelayTeamEntry {
  final String teamId;
  final String nationOrClubName;
  final String countryIso;
  final String primaryColorHex;
  final List<MixedRelayRiderSlot> mensTrio;
  final List<MixedRelayRiderSlot> womensTrio;
  final MixedRelayPhase phase;
  final double totalElapsedSeconds;
  final double penaltySeconds;
  final double? mensLegSplitSeconds;
  final MixedRelayHandoverEvent? handoverEvent;
  final List<double> intermediateSplitsSeconds;

  const MixedRelayTeamEntry({
    required this.teamId,
    required this.nationOrClubName,
    required this.countryIso,
    required this.primaryColorHex,
    required this.mensTrio,
    required this.womensTrio,
    this.phase = MixedRelayPhase.preStart,
    this.totalElapsedSeconds = 0.0,
    this.penaltySeconds = 0.0,
    this.mensLegSplitSeconds,
    this.handoverEvent,
    this.intermediateSplitsSeconds = const [],
  });

  /// Regulaminowa weryfikacja składu (dokładnie 3 mężczyzn i 3 kobiety).
  bool get isLineupValid =>
      mensTrio.length == 3 &&
      womensTrio.length == 3 &&
      mensTrio.every((r) => !r.isFemale) &&
      womensTrio.every((r) => r.isFemale);

  double get effectiveTotalTimeSeconds => totalElapsedSeconds + penaltySeconds;

  int get mensActiveCount => mensTrio.where((r) => !r.isDropped).length;

  int get womensActiveCount => womensTrio.where((r) => !r.isDropped).length;

  /// Dystans 2. zawodnika w trójce męskiej (wyznacza moment otwarcia bramki).
  double get mensSecondRiderDistanceMeters =>
      computeSecondRiderDistance(mensTrio);

  /// Dystans 2. zawodniczki w trójce kobiecej (wyznacza czas na mecie).
  double get womensSecondRiderDistanceMeters =>
      computeSecondRiderDistance(womensTrio);

  /// Czy drużyna ma jeszcze co najmniej 2 zawodników zdolnych do ukończenia aktywnej zmiany.
  bool get canCompleteActiveLeg {
    if (phase == MixedRelayPhase.womensLegActive ||
        phase == MixedRelayPhase.handoverWindowOpen) {
      return womensActiveCount >= 2;
    }
    return mensActiveCount >= 2;
  }

  /// Oblicza dystans 2. zawodnika w danej trójce (sortowanie malejące).
  static double computeSecondRiderDistance(List<MixedRelayRiderSlot> trio) {
    if (trio.isEmpty) return 0.0;
    if (trio.length == 1) return trio.first.distanceMeters;
    final distances = trio.map((r) => r.distanceMeters).toList()
      ..sort((a, b) => b.compareTo(a));
    return distances[1];
  }

  MixedRelayTeamEntry copyWith({
    String? teamId,
    String? nationOrClubName,
    String? countryIso,
    String? primaryColorHex,
    List<MixedRelayRiderSlot>? mensTrio,
    List<MixedRelayRiderSlot>? womensTrio,
    MixedRelayPhase? phase,
    double? totalElapsedSeconds,
    double? penaltySeconds,
    double? mensLegSplitSeconds,
    MixedRelayHandoverEvent? handoverEvent,
    List<double>? intermediateSplitsSeconds,
  }) {
    return MixedRelayTeamEntry(
      teamId: teamId ?? this.teamId,
      nationOrClubName: nationOrClubName ?? this.nationOrClubName,
      countryIso: countryIso ?? this.countryIso,
      primaryColorHex: primaryColorHex ?? this.primaryColorHex,
      mensTrio: mensTrio ?? this.mensTrio,
      womensTrio: womensTrio ?? this.womensTrio,
      phase: phase ?? this.phase,
      totalElapsedSeconds: totalElapsedSeconds ?? this.totalElapsedSeconds,
      penaltySeconds: penaltySeconds ?? this.penaltySeconds,
      mensLegSplitSeconds: mensLegSplitSeconds ?? this.mensLegSplitSeconds,
      handoverEvent: handoverEvent ?? this.handoverEvent,
      intermediateSplitsSeconds:
          intermediateSplitsSeconds ?? this.intermediateSplitsSeconds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'teamId': teamId,
      'nationOrClubName': nationOrClubName,
      'countryIso': countryIso,
      'primaryColorHex': primaryColorHex,
      'mensTrio': mensTrio.map((r) => r.toJson()).toList(),
      'womensTrio': womensTrio.map((r) => r.toJson()).toList(),
      'phase': phase.toJson(),
      'totalElapsedSeconds': totalElapsedSeconds,
      'penaltySeconds': penaltySeconds,
      'mensLegSplitSeconds': mensLegSplitSeconds,
      'handoverEvent': handoverEvent?.toJson(),
      'intermediateSplitsSeconds': intermediateSplitsSeconds,
    };
  }

  factory MixedRelayTeamEntry.fromJson(Map<String, dynamic> json) {
    return MixedRelayTeamEntry(
      teamId: json['teamId'] as String,
      nationOrClubName: json['nationOrClubName'] as String,
      countryIso: json['countryIso'] as String,
      primaryColorHex: json['primaryColorHex'] as String,
      mensTrio: (json['mensTrio'] as List<dynamic>)
          .map((e) => MixedRelayRiderSlot.fromJson(e as Map<String, dynamic>))
          .toList(),
      womensTrio: (json['womensTrio'] as List<dynamic>)
          .map((e) => MixedRelayRiderSlot.fromJson(e as Map<String, dynamic>))
          .toList(),
      phase: MixedRelayPhase.fromJson(
        (json['phase'] as String?) ?? 'preStart',
      ),
      totalElapsedSeconds:
          (json['totalElapsedSeconds'] as num?)?.toDouble() ?? 0.0,
      penaltySeconds: (json['penaltySeconds'] as num?)?.toDouble() ?? 0.0,
      mensLegSplitSeconds: (json['mensLegSplitSeconds'] as num?)?.toDouble(),
      handoverEvent: json['handoverEvent'] != null
          ? MixedRelayHandoverEvent.fromJson(
              json['handoverEvent'] as Map<String, dynamic>,
            )
          : null,
      intermediateSplitsSeconds:
          (json['intermediateSplitsSeconds'] as List<dynamic>? ?? [])
              .map((e) => (e as num).toDouble())
              .toList(),
    );
  }
}

/// Specyfikacja trasy Drużynowej Sztafety Mieszanej UCI (Mixed Relay TTT).
class MixedRelayCourseSpec {
  final String eventId;
  final String eventName;
  final String locationCity;
  final String countryIso;
  final double totalDistanceMeters;
  final double handoverDistanceMeters;
  final double handoverApproachZoneMeters;
  final int elevationGainM;
  final double windSpeedKmh;
  final double temperatureCelsius;
  final List<double> intermediateSplitMeters;

  const MixedRelayCourseSpec({
    required this.eventId,
    required this.eventName,
    required this.locationCity,
    required this.countryIso,
    required this.totalDistanceMeters,
    required this.handoverDistanceMeters,
    this.handoverApproachZoneMeters = 500.0,
    required this.elevationGainM,
    this.windSpeedKmh = 12.0,
    this.temperatureCelsius = 20.0,
    this.intermediateSplitMeters = const [],
  });

  double get mensLegDistanceMeters => handoverDistanceMeters;

  double get womensLegDistanceMeters =>
      math.max(0.0, totalDistanceMeters - handoverDistanceMeters);

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'eventName': eventName,
      'locationCity': locationCity,
      'countryIso': countryIso,
      'totalDistanceMeters': totalDistanceMeters,
      'handoverDistanceMeters': handoverDistanceMeters,
      'handoverApproachZoneMeters': handoverApproachZoneMeters,
      'elevationGainM': elevationGainM,
      'windSpeedKmh': windSpeedKmh,
      'temperatureCelsius': temperatureCelsius,
      'intermediateSplitMeters': intermediateSplitMeters,
    };
  }

  factory MixedRelayCourseSpec.fromJson(Map<String, dynamic> json) {
    return MixedRelayCourseSpec(
      eventId: json['eventId'] as String,
      eventName: json['eventName'] as String,
      locationCity: json['locationCity'] as String,
      countryIso: json['countryIso'] as String,
      totalDistanceMeters: (json['totalDistanceMeters'] as num).toDouble(),
      handoverDistanceMeters:
          (json['handoverDistanceMeters'] as num).toDouble(),
      handoverApproachZoneMeters:
          (json['handoverApproachZoneMeters'] as num?)?.toDouble() ?? 500.0,
      elevationGainM: (json['elevationGainM'] as num).toInt(),
      windSpeedKmh: (json['windSpeedKmh'] as num?)?.toDouble() ?? 12.0,
      temperatureCelsius:
          (json['temperatureCelsius'] as num?)?.toDouble() ?? 20.0,
      intermediateSplitMeters:
          (json['intermediateSplitMeters'] as List<dynamic>? ?? [])
              .map((e) => (e as num).toDouble())
              .toList(),
    );
  }
}

/// Pełny stan wyścigu Drużynowej Sztafety Mieszanej (Mixed Relay TTT).
class MixedRelayRaceState {
  final MixedRelayCourseSpec course;
  final List<MixedRelayTeamEntry> teams;
  final double raceClockSeconds;
  final bool isWorldChampionship;

  const MixedRelayRaceState({
    required this.course,
    required this.teams,
    this.raceClockSeconds = 0.0,
    this.isWorldChampionship = true,
  });

  /// Postęp (0.0 - 1.0) 2. zawodnika trójki męskiej do strefy przekazania zmiany.
  double handoverProgressPct(MixedRelayTeamEntry team) {
    if (course.handoverDistanceMeters <= 0.0) return 0.0;
    return (team.mensSecondRiderDistanceMeters / course.handoverDistanceMeters)
        .clamp(0.0, 1.0);
  }

  /// Całkowity postęp (0.0 - 1.0) drużyny na trasie Sztafety Mieszanej.
  double totalCourseProgressPct(MixedRelayTeamEntry team) {
    if (course.totalDistanceMeters <= 0.0) return 0.0;
    final covered = team.phase == MixedRelayPhase.womensLegActive ||
            team.phase == MixedRelayPhase.finished
        ? course.handoverDistanceMeters + team.womensSecondRiderDistanceMeters
        : team.mensSecondRiderDistanceMeters;
    return (covered / course.totalDistanceMeters).clamp(0.0, 1.0);
  }

  /// Klasyfikacja drużynowa na żywo: najpierw drużyny na mecie wg czasu,
  /// następnie drużyny na trasie wg pokonanego dystansu, na końcu DSQ.
  List<MixedRelayTeamEntry> get leaderboardSorted {
    final sorted = List<MixedRelayTeamEntry>.from(teams);
    sorted.sort((a, b) {
      if (a.phase == MixedRelayPhase.disqualified &&
          b.phase != MixedRelayPhase.disqualified) {
        return 1;
      }
      if (b.phase == MixedRelayPhase.disqualified &&
          a.phase != MixedRelayPhase.disqualified) {
        return -1;
      }
      final aFin = a.phase == MixedRelayPhase.finished;
      final bFin = b.phase == MixedRelayPhase.finished;
      if (aFin && bFin) {
        return a.effectiveTotalTimeSeconds
            .compareTo(b.effectiveTotalTimeSeconds);
      }
      if (aFin) return -1;
      if (bFin) return 1;
      return totalCourseProgressPct(b).compareTo(totalCourseProgressPct(a));
    });
    return sorted;
  }

  /// Ocenia zdarzenie przekazania zmiany między 2. mężczyzną a bramką startową kobiet.
  static MixedRelayHandoverEvent evaluateHandover({
    required String teamId,
    required MixedRelayRiderSlot secondMaleRider,
    required double handoverElapsedSeconds,
    required double reactionDelaySeconds,
    required double handoverDistanceMeters,
    bool isFalseStart = false,
  }) {
    final clampedDelay = reactionDelaySeconds.clamp(0.0, 10.0);
    final penalty = isFalseStart ? 15.0 : 0.0;
    return MixedRelayHandoverEvent(
      teamId: teamId,
      mensSecondRiderId: secondMaleRider.riderId,
      mensSecondRiderName: secondMaleRider.fullName,
      handoverElapsedSeconds: handoverElapsedSeconds,
      gateReactionDelaySeconds: clampedDelay,
      falseStartPenaltySeconds: penalty,
      handoverDistanceMeters: handoverDistanceMeters,
    );
  }

  MixedRelayRaceState copyWith({
    MixedRelayCourseSpec? course,
    List<MixedRelayTeamEntry>? teams,
    double? raceClockSeconds,
    bool? isWorldChampionship,
  }) {
    return MixedRelayRaceState(
      course: course ?? this.course,
      teams: teams ?? this.teams,
      raceClockSeconds: raceClockSeconds ?? this.raceClockSeconds,
      isWorldChampionship: isWorldChampionship ?? this.isWorldChampionship,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'course': course.toJson(),
      'teams': teams.map((t) => t.toJson()).toList(),
      'raceClockSeconds': raceClockSeconds,
      'isWorldChampionship': isWorldChampionship,
    };
  }

  factory MixedRelayRaceState.fromJson(Map<String, dynamic> json) {
    return MixedRelayRaceState(
      course: MixedRelayCourseSpec.fromJson(
        json['course'] as Map<String, dynamic>,
      ),
      teams: (json['teams'] as List<dynamic>)
          .map((e) => MixedRelayTeamEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      raceClockSeconds: (json['raceClockSeconds'] as num?)?.toDouble() ?? 0.0,
      isWorldChampionship: json['isWorldChampionship'] as bool? ?? true,
    );
  }
}
