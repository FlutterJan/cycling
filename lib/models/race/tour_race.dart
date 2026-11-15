import 'race_stage.dart';

enum RaceCategory {
  grandTour, // Tour de France, Giro d'Italia, Vuelta a España (21 etapów)
  monument, // Mediolan-San Remo, Flandria, Paryż-Roubaix, Liège, Lombardia (1 dzień)
  worldTourStageRace, // Dauphiné, Tour de Suisse, Tirreno-Adriatico, Paris-Nice (7-8 dni)
  worldTourOneDay, // Strade Bianche, Amstel Gold Race, Clasica San Sebastian
  proSeries, // Tour of Britain, Vuelta a Burgos, Kuurne-Bruxelles-Kuurne
  class1; // Wyścigi kategorii 1.1 / 2.1

  String toJson() => name;

  static RaceCategory fromJson(String value) {
    return RaceCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RaceCategory.worldTourStageRace,
    );
  }
}

class RiderClassificationEntry {
  final String riderId;
  final String riderName;
  final String teamId;
  final int totalTimeSeconds; // Łączny czas w sekundach (dla GC i Youth)
  final int points; // Punkty (dla klasyfikacji punktowej i górskiej)
  final int rank; // Miejsce w klasyfikacji
  final int timeBehindLeaderSeconds; // Strata do lidera w sekundach

  const RiderClassificationEntry({
    required this.riderId,
    required this.riderName,
    required this.teamId,
    required this.totalTimeSeconds,
    required this.points,
    required this.rank,
    required this.timeBehindLeaderSeconds,
  });

  RiderClassificationEntry copyWith({
    String? riderId,
    String? riderName,
    String? teamId,
    int? totalTimeSeconds,
    int? points,
    int? rank,
    int? timeBehindLeaderSeconds,
  }) {
    return RiderClassificationEntry(
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      teamId: teamId ?? this.teamId,
      totalTimeSeconds: totalTimeSeconds ?? this.totalTimeSeconds,
      points: points ?? this.points,
      rank: rank ?? this.rank,
      timeBehindLeaderSeconds: timeBehindLeaderSeconds ?? this.timeBehindLeaderSeconds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'riderName': riderName,
      'teamId': teamId,
      'totalTimeSeconds': totalTimeSeconds,
      'points': points,
      'rank': rank,
      'timeBehindLeaderSeconds': timeBehindLeaderSeconds,
    };
  }

  factory RiderClassificationEntry.fromJson(Map<String, dynamic> json) {
    return RiderClassificationEntry(
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      teamId: json['teamId'] as String,
      totalTimeSeconds: (json['totalTimeSeconds'] as num).toInt(),
      points: (json['points'] as num).toInt(),
      rank: (json['rank'] as num).toInt(),
      timeBehindLeaderSeconds: (json['timeBehindLeaderSeconds'] as num).toInt(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RiderClassificationEntry &&
        other.riderId == riderId &&
        other.rank == rank;
  }

  @override
  int get hashCode => Object.hash(riderId, rank);

  @override
  String toString() {
    return '#$rank $riderName (${totalTimeSeconds > 0 ? "${totalTimeSeconds}s" : "$points pts"})';
  }
}

class TeamClassificationEntry {
  final String teamId;
  final String teamName;
  final int totalTimeSeconds;
  final int rank;
  final int timeBehindLeaderSeconds;

  const TeamClassificationEntry({
    required this.teamId,
    required this.teamName,
    required this.totalTimeSeconds,
    required this.rank,
    required this.timeBehindLeaderSeconds,
  });

  TeamClassificationEntry copyWith({
    String? teamId,
    String? teamName,
    int? totalTimeSeconds,
    int? rank,
    int? timeBehindLeaderSeconds,
  }) {
    return TeamClassificationEntry(
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      totalTimeSeconds: totalTimeSeconds ?? this.totalTimeSeconds,
      rank: rank ?? this.rank,
      timeBehindLeaderSeconds: timeBehindLeaderSeconds ?? this.timeBehindLeaderSeconds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'teamId': teamId,
      'teamName': teamName,
      'totalTimeSeconds': totalTimeSeconds,
      'rank': rank,
      'timeBehindLeaderSeconds': timeBehindLeaderSeconds,
    };
  }

  factory TeamClassificationEntry.fromJson(Map<String, dynamic> json) {
    return TeamClassificationEntry(
      teamId: json['teamId'] as String,
      teamName: json['teamName'] as String,
      totalTimeSeconds: (json['totalTimeSeconds'] as num).toInt(),
      rank: (json['rank'] as num).toInt(),
      timeBehindLeaderSeconds: (json['timeBehindLeaderSeconds'] as num).toInt(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TeamClassificationEntry &&
        other.teamId == teamId &&
        other.rank == rank;
  }

  @override
  int get hashCode => Object.hash(teamId, rank);

  @override
  String toString() {
    return '#$rank $teamName (${totalTimeSeconds}s)';
  }
}

class RaceClassifications {
  final List<RiderClassificationEntry> generalClassification; // Klasyfikacja generalna (żółta/różowa/czerwona koszulka)
  final List<RiderClassificationEntry> pointsClassification; // Klasyfikacja punktowa / sprinterska (zielona koszulka)
  final List<RiderClassificationEntry> mountainsClassification; // Klasyfikacja górska (koszulka w grochy / KOM)
  final List<RiderClassificationEntry> youthClassification; // Klasyfikacja młodzieżowa (biała koszulka U23/U25)
  final List<TeamClassificationEntry> teamClassification; // Klasyfikacja drużynowa (łączny czas 3 najlepszych)

  const RaceClassifications({
    required this.generalClassification,
    required this.pointsClassification,
    required this.mountainsClassification,
    required this.youthClassification,
    required this.teamClassification,
  });

  RaceClassifications copyWith({
    List<RiderClassificationEntry>? generalClassification,
    List<RiderClassificationEntry>? pointsClassification,
    List<RiderClassificationEntry>? mountainsClassification,
    List<RiderClassificationEntry>? youthClassification,
    List<TeamClassificationEntry>? teamClassification,
  }) {
    return RaceClassifications(
      generalClassification: generalClassification ?? this.generalClassification,
      pointsClassification: pointsClassification ?? this.pointsClassification,
      mountainsClassification: mountainsClassification ?? this.mountainsClassification,
      youthClassification: youthClassification ?? this.youthClassification,
      teamClassification: teamClassification ?? this.teamClassification,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'generalClassification': generalClassification.map((e) => e.toJson()).toList(),
      'pointsClassification': pointsClassification.map((e) => e.toJson()).toList(),
      'mountainsClassification': mountainsClassification.map((e) => e.toJson()).toList(),
      'youthClassification': youthClassification.map((e) => e.toJson()).toList(),
      'teamClassification': teamClassification.map((e) => e.toJson()).toList(),
    };
  }

  factory RaceClassifications.fromJson(Map<String, dynamic> json) {
    return RaceClassifications(
      generalClassification: (json['generalClassification'] as List<dynamic>?)
              ?.map((e) => RiderClassificationEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      pointsClassification: (json['pointsClassification'] as List<dynamic>?)
              ?.map((e) => RiderClassificationEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      mountainsClassification: (json['mountainsClassification'] as List<dynamic>?)
              ?.map((e) => RiderClassificationEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      youthClassification: (json['youthClassification'] as List<dynamic>?)
              ?.map((e) => RiderClassificationEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      teamClassification: (json['teamClassification'] as List<dynamic>?)
              ?.map((e) => TeamClassificationEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class TourRace {
  final String id;
  final String name;
  final String countryIso;
  final RaceCategory uciCategory;
  final int startMonth; // 1-12
  final int startDay; // 1-31
  final List<RaceStage> stages;
  final int prizePoolEur;
  final List<String> participatingTeamIds;
  final int ridersPerTeam; // Zazwyczaj 7 (tygodniówki) lub 8 (Grand Tour)
  final RaceClassifications classifications;

  const TourRace({
    required this.id,
    required this.name,
    required this.countryIso,
    required this.uciCategory,
    required this.startMonth,
    required this.startDay,
    required this.stages,
    required this.prizePoolEur,
    required this.participatingTeamIds,
    required this.ridersPerTeam,
    required this.classifications,
  });

  /// Czy wyścig jest 1-dniowym klasykiem
  bool get isOneDayRace => stages.length == 1;

  /// Data rozpoczęcia i zakończenia wyścigu
  DateTime get startDate => DateTime(2026, startMonth, startDay);
  DateTime get endDate => startDate.add(Duration(days: stages.isNotEmpty ? stages.length - 1 : 0));
  bool get isCompleted => false;

  /// Czy wyścig jest 3-tygodniowym Grand Tourem
  bool get isGrandTour => uciCategory == RaceCategory.grandTour || stages.length >= 21;

  /// Łączny dystans całego wyścigu w kilometrach
  double get totalRaceDistanceKm {
    double sum = 0.0;
    for (final st in stages) {
      sum += st.totalDistanceKm;
    }
    return sum;
  }

  /// Łączne przewyższenie całego wyścigu w metrach
  double get totalRaceElevationGainM {
    double sum = 0.0;
    for (final st in stages) {
      sum += st.totalElevationGainM;
    }
    return sum;
  }

  /// Identyfikator obecnego lidera klasyfikacji generalnej
  String? get currentLeaderRiderId =>
      classifications.generalClassification.isNotEmpty
          ? classifications.generalClassification.first.riderId
          : null;

  TourRace copyWith({
    String? id,
    String? name,
    String? countryIso,
    RaceCategory? uciCategory,
    int? startMonth,
    int? startDay,
    List<RaceStage>? stages,
    int? prizePoolEur,
    List<String>? participatingTeamIds,
    int? ridersPerTeam,
    RaceClassifications? classifications,
  }) {
    return TourRace(
      id: id ?? this.id,
      name: name ?? this.name,
      countryIso: countryIso ?? this.countryIso,
      uciCategory: uciCategory ?? this.uciCategory,
      startMonth: startMonth ?? this.startMonth,
      startDay: startDay ?? this.startDay,
      stages: stages != null ? List<RaceStage>.unmodifiable(stages) : this.stages,
      prizePoolEur: prizePoolEur ?? this.prizePoolEur,
      participatingTeamIds: participatingTeamIds != null
          ? List<String>.unmodifiable(participatingTeamIds)
          : this.participatingTeamIds,
      ridersPerTeam: ridersPerTeam ?? this.ridersPerTeam,
      classifications: classifications ?? this.classifications,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'countryIso': countryIso,
      'uciCategory': uciCategory.toJson(),
      'startMonth': startMonth,
      'startDay': startDay,
      'stages': stages.map((s) => s.toJson()).toList(),
      'prizePoolEur': prizePoolEur,
      'participatingTeamIds': participatingTeamIds,
      'ridersPerTeam': ridersPerTeam,
      'classifications': classifications.toJson(),
    };
  }

  factory TourRace.fromJson(Map<String, dynamic> json) {
    return TourRace(
      id: json['id'] as String,
      name: json['name'] as String,
      countryIso: json['countryIso'] as String,
      uciCategory: RaceCategory.fromJson(json['uciCategory'] as String),
      startMonth: (json['startMonth'] as num).toInt(),
      startDay: (json['startDay'] as num).toInt(),
      stages: (json['stages'] as List<dynamic>?)
              ?.map((e) => RaceStage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      prizePoolEur: (json['prizePoolEur'] as num).toInt(),
      participatingTeamIds: (json['participatingTeamIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      ridersPerTeam: (json['ridersPerTeam'] as num).toInt(),
      classifications: json['classifications'] != null
          ? RaceClassifications.fromJson(
              json['classifications'] as Map<String, dynamic>,
            )
          : const RaceClassifications(
              generalClassification: [],
              pointsClassification: [],
              mountainsClassification: [],
              youthClassification: [],
              teamClassification: [],
            ),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TourRace && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'TourRace($name, ${uciCategory.name}, ${stages.length} etapów, pula: €$prizePoolEur)';
  }
}

