import 'dart:math' as math;
import '../../core/utils/formatters.dart';
import '../../models/race/tour_race.dart';

/// Typ osiągnięcia kolarskiego do ewidencji trofeów (Palmarès).
enum PalmaresAchievementType {
  /// Triumf w klasyfikacji generalnej Grand Touru (Tour de France, Giro, Vuelta)
  grandTourGeneralClassification,

  /// Wygrana etapowa w Grand Tourze
  grandTourStage,

  /// Zwycięstwo w jednym z 5 Monumentów kolarstwa (MSR, RVV, PR, LBL, Lombardia)
  monumentClassic,

  /// Wygrana w tygodniowym wyścigu etapowym WorldTour (np. Dauphiné, Paryż-Nicea, Tour de Suisse)
  worldTourStageRaceGc,

  /// Triumf w prestiżowym klasyku WorldTour (np. Strade Bianche, Amstel Gold Race, San Sebastian)
  worldTourOneDay,

  /// Mistrzostwo Świata ze startu wspólnego (Tęczowa koszulka / Rainbow Jersey)
  worldChampionshipRoad,

  /// Mistrzostwo Świata w jeździe indywidualnej na czas (ITT)
  worldChampionshipTimeTrial,

  /// Złoty medal Igrzysk Olimpijskich
  olympicGold,

  /// Mistrzostwo Kraju (ze startu wspólnego lub ITT)
  nationalChampionship,

  /// Klasyfikacja punktowa Grand Touru (Zielona / Cyklamenowa koszulka)
  pointsJerseyWinner,

  /// Klasyfikacja górska Grand Touru (Koszulka w grochy / Niebieska koszulka KOM)
  komJerseyWinner,

  /// Klasyfikacja młodzieżowa Grand Touru (Biała koszulka U25)
  youthJerseyWinner,

  /// Triumf w wyścigu kategorii ProSeries lub 1.1 / 2.1
  proSeriesOrOtherWin;

  String toJson() => name;

  static PalmaresAchievementType fromJson(String value) {
    return PalmaresAchievementType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => PalmaresAchievementType.proSeriesOrOtherWin,
    );
  }

  String get displayName {
    switch (this) {
      case PalmaresAchievementType.grandTourGeneralClassification:
        return 'Klasyfikacja Generalna Grand Touru';
      case PalmaresAchievementType.grandTourStage:
        return 'Etap Grand Touru';
      case PalmaresAchievementType.monumentClassic:
        return 'Monument Kolarstwa';
      case PalmaresAchievementType.worldTourStageRaceGc:
        return 'Wyścig Etapowy WorldTour';
      case PalmaresAchievementType.worldTourOneDay:
        return 'Klasyk WorldTour';
      case PalmaresAchievementType.worldChampionshipRoad:
        return 'Mistrzostwo Świata (Wyścig ze startu wspólnego)';
      case PalmaresAchievementType.worldChampionshipTimeTrial:
        return 'Mistrzostwo Świata (Jazda indywidualna na czas)';
      case PalmaresAchievementType.olympicGold:
        return 'Złoty Medal Olimpijski';
      case PalmaresAchievementType.nationalChampionship:
        return 'Mistrzostwo Kraju';
      case PalmaresAchievementType.pointsJerseyWinner:
        return 'Klasyfikacja Punktowa Grand Touru';
      case PalmaresAchievementType.komJerseyWinner:
        return 'Klasyfikacja Górska Grand Touru (KOM)';
      case PalmaresAchievementType.youthJerseyWinner:
        return 'Klasyfikacja Młodzieżowa Grand Touru (Biała koszulka)';
      case PalmaresAchievementType.proSeriesOrOtherWin:
        return 'Zwycięstwo ProSeries / Klasa 1';
    }
  }

  /// Wartość punktowa osiągnięcia w Rankingu Wszech Czasów (All-Time GOAT Index)
  int get allTimePointsWeight {
    switch (this) {
      case PalmaresAchievementType.grandTourGeneralClassification:
        return 1000;
      case PalmaresAchievementType.monumentClassic:
        return 450;
      case PalmaresAchievementType.worldChampionshipRoad:
        return 500;
      case PalmaresAchievementType.worldChampionshipTimeTrial:
        return 350;
      case PalmaresAchievementType.olympicGold:
        return 400;
      case PalmaresAchievementType.worldTourStageRaceGc:
        return 200;
      case PalmaresAchievementType.grandTourStage:
        return 100;
      case PalmaresAchievementType.pointsJerseyWinner:
      case PalmaresAchievementType.komJerseyWinner:
        return 150;
      case PalmaresAchievementType.worldTourOneDay:
        return 120;
      case PalmaresAchievementType.youthJerseyWinner:
        return 80;
      case PalmaresAchievementType.nationalChampionship:
        return 60;
      case PalmaresAchievementType.proSeriesOrOtherWin:
        return 40;
    }
  }
}

/// Pojedynczy historyczny wpis sukcesu w gablocie trofeów (Palmarès Entry).
class PalmaresEntry {
  final String id;
  final String riderId;
  final String riderName;
  final String teamId;
  final String teamName;
  final int seasonYear;
  final DateTime date;
  final String raceId;
  final String raceName;
  final RaceCategory raceCategory;
  final PalmaresAchievementType achievementType;
  final String details;
  final String? jerseyWorn; // np. "Maillot Jaune", "Maglia Rosa", "Maillot à Pois"

  const PalmaresEntry({
    required this.id,
    required this.riderId,
    required this.riderName,
    required this.teamId,
    required this.teamName,
    required this.seasonYear,
    required this.date,
    required this.raceId,
    required this.raceName,
    required this.raceCategory,
    required this.achievementType,
    required this.details,
    this.jerseyWorn,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'riderId': riderId,
        'riderName': riderName,
        'teamId': teamId,
        'teamName': teamName,
        'seasonYear': seasonYear,
        'date': date.toIso8601String(),
        'raceId': raceId,
        'raceName': raceName,
        'raceCategory': raceCategory.toJson(),
        'achievementType': achievementType.toJson(),
        'details': details,
        'jerseyWorn': jerseyWorn,
      };

  factory PalmaresEntry.fromJson(Map<String, dynamic> json) {
    return PalmaresEntry(
      id: json['id'] as String,
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      teamId: json['teamId'] as String,
      teamName: json['teamName'] as String,
      seasonYear: (json['seasonYear'] as num).toInt(),
      date: DateTime.parse(json['date'] as String),
      raceId: json['raceId'] as String,
      raceName: json['raceName'] as String,
      raceCategory: RaceCategory.fromJson(json['raceCategory'] as String),
      achievementType:
          PalmaresAchievementType.fromJson(json['achievementType'] as String),
      details: json['details'] as String,
      jerseyWorn: json['jerseyWorn'] as String?,
    );
  }
}

/// Osobista gablota sukcesów każdego kolarza (Rider Palmarès).
class RiderPalmares {
  final String riderId;
  final String riderName;
  final String nationalityIso;
  final int grandTourOverallWins;
  final int tourDeFranceGcWins;
  final int giroDItaliaGcWins;
  final int vueltaAEspanaGcWins;
  final int grandTourStageWins;
  final int tourDeFranceStageWins;
  final int giroStageWins;
  final int vueltaStageWins;
  final int monumentWins;
  final int milanoSanRemoWins;
  final int rondeVanVlaanderenWins;
  final int parisRoubaixWins;
  final int liegeBastogneLiegeWins;
  final int ilLombardiaWins;
  final int worldChampionshipRoadWins;
  final int worldChampionshipTimeTrialWins;
  final int daysInYellowJersey; // Dni w żółtej koszulce TdF (Maillot Jaune)
  final int daysInPinkJersey; // Dni w różowej koszulce Giro (Maglia Rosa)
  final int daysInRedJersey; // Dni w czerwonej koszulce Vuelta (La Roja)
  final int pointsClassificationsWon;
  final int komClassificationsWon;
  final int youthClassificationsWon;
  final int otherWorldTourWins;
  final int totalCareerVictories;
  final List<PalmaresEntry> entries;

  const RiderPalmares({
    required this.riderId,
    required this.riderName,
    required this.nationalityIso,
    this.grandTourOverallWins = 0,
    this.tourDeFranceGcWins = 0,
    this.giroDItaliaGcWins = 0,
    this.vueltaAEspanaGcWins = 0,
    this.grandTourStageWins = 0,
    this.tourDeFranceStageWins = 0,
    this.giroStageWins = 0,
    this.vueltaStageWins = 0,
    this.monumentWins = 0,
    this.milanoSanRemoWins = 0,
    this.rondeVanVlaanderenWins = 0,
    this.parisRoubaixWins = 0,
    this.liegeBastogneLiegeWins = 0,
    this.ilLombardiaWins = 0,
    this.worldChampionshipRoadWins = 0,
    this.worldChampionshipTimeTrialWins = 0,
    this.daysInYellowJersey = 0,
    this.daysInPinkJersey = 0,
    this.daysInRedJersey = 0,
    this.pointsClassificationsWon = 0,
    this.komClassificationsWon = 0,
    this.youthClassificationsWon = 0,
    this.otherWorldTourWins = 0,
    this.totalCareerVictories = 0,
    this.entries = const [],
  });

  /// Czy kolarz wygrał etapy we wszystkich trzech Grand Tourach (Giro, Tour, Vuelta)
  bool get hasGrandTourStageTrifecta =>
      tourDeFranceStageWins > 0 &&
      giroStageWins > 0 &&
      vueltaStageWins > 0;

  /// Czy kolarz wygrał klasyfikację generalną wszystkich trzech Grand Tourów (Triple Crown GC)
  bool get hasGrandTourGcCareerGrandSlam =>
      tourDeFranceGcWins > 0 &&
      giroDItaliaGcWins > 0 &&
      vueltaAEspanaGcWins > 0;

  /// Liczba różnych Monumentów wygranych przez kolarza (od 0 do 5)
  int get distinctMonumentsWonCount {
    int count = 0;
    if (milanoSanRemoWins > 0) count++;
    if (rondeVanVlaanderenWins > 0) count++;
    if (parisRoubaixWins > 0) count++;
    if (liegeBastogneLiegeWins > 0) count++;
    if (ilLombardiaWins > 0) count++;
    return count;
  }

  /// Czy kolarz wygrał wszystkie 5 Monumentów kolarstwa (Monument Grand Slam)
  bool get hasMonumentsGrandSlam => distinctMonumentsWonCount == 5;

  /// Łączna suma dni spędzonych w koszulce lidera Grand Tourów
  int get totalDaysInGrandTourLeaderJerseys =>
      daysInYellowJersey + daysInPinkJersey + daysInRedJersey;

  /// Łączna punktacja w Rankingu Wszech Czasów (GOAT Points)
  int get calculateAllTimeGoatPoints {
    int score = 0;
    score += tourDeFranceGcWins * 1000;
    score += giroDItaliaGcWins * 750;
    score += vueltaAEspanaGcWins * 750;
    score += monumentWins * 450;
    score += worldChampionshipRoadWins * 500;
    score += worldChampionshipTimeTrialWins * 350;
    score += grandTourStageWins * 100;
    score += otherWorldTourWins * 120;
    score += daysInYellowJersey * 30;
    score += (daysInPinkJersey + daysInRedJersey) * 20;
    score += (pointsClassificationsWon + komClassificationsWon) * 150;
    score += youthClassificationsWon * 80;

    // Bonus za unikalne historyczne kamienie milowe
    if (hasGrandTourGcCareerGrandSlam) score += 1500;
    if (hasGrandTourStageTrifecta) score += 300;
    if (hasMonumentsGrandSlam) score += 2000;

    return score;
  }

  RiderPalmares copyWith({
    String? riderId,
    String? riderName,
    String? nationalityIso,
    int? grandTourOverallWins,
    int? tourDeFranceGcWins,
    int? giroDItaliaGcWins,
    int? vueltaAEspanaGcWins,
    int? grandTourStageWins,
    int? tourDeFranceStageWins,
    int? giroStageWins,
    int? vueltaStageWins,
    int? monumentWins,
    int? milanoSanRemoWins,
    int? rondeVanVlaanderenWins,
    int? parisRoubaixWins,
    int? liegeBastogneLiegeWins,
    int? ilLombardiaWins,
    int? worldChampionshipRoadWins,
    int? worldChampionshipTimeTrialWins,
    int? daysInYellowJersey,
    int? daysInPinkJersey,
    int? daysInRedJersey,
    int? pointsClassificationsWon,
    int? komClassificationsWon,
    int? youthClassificationsWon,
    int? otherWorldTourWins,
    int? totalCareerVictories,
    List<PalmaresEntry>? entries,
  }) {
    return RiderPalmares(
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      nationalityIso: nationalityIso ?? this.nationalityIso,
      grandTourOverallWins: grandTourOverallWins ?? this.grandTourOverallWins,
      tourDeFranceGcWins: tourDeFranceGcWins ?? this.tourDeFranceGcWins,
      giroDItaliaGcWins: giroDItaliaGcWins ?? this.giroDItaliaGcWins,
      vueltaAEspanaGcWins: vueltaAEspanaGcWins ?? this.vueltaAEspanaGcWins,
      grandTourStageWins: grandTourStageWins ?? this.grandTourStageWins,
      tourDeFranceStageWins:
          tourDeFranceStageWins ?? this.tourDeFranceStageWins,
      giroStageWins: giroStageWins ?? this.giroStageWins,
      vueltaStageWins: vueltaStageWins ?? this.vueltaStageWins,
      monumentWins: monumentWins ?? this.monumentWins,
      milanoSanRemoWins: milanoSanRemoWins ?? this.milanoSanRemoWins,
      rondeVanVlaanderenWins:
          rondeVanVlaanderenWins ?? this.rondeVanVlaanderenWins,
      parisRoubaixWins: parisRoubaixWins ?? this.parisRoubaixWins,
      liegeBastogneLiegeWins:
          liegeBastogneLiegeWins ?? this.liegeBastogneLiegeWins,
      ilLombardiaWins: ilLombardiaWins ?? this.ilLombardiaWins,
      worldChampionshipRoadWins:
          worldChampionshipRoadWins ?? this.worldChampionshipRoadWins,
      worldChampionshipTimeTrialWins:
          worldChampionshipTimeTrialWins ?? this.worldChampionshipTimeTrialWins,
      daysInYellowJersey: daysInYellowJersey ?? this.daysInYellowJersey,
      daysInPinkJersey: daysInPinkJersey ?? this.daysInPinkJersey,
      daysInRedJersey: daysInRedJersey ?? this.daysInRedJersey,
      pointsClassificationsWon:
          pointsClassificationsWon ?? this.pointsClassificationsWon,
      komClassificationsWon:
          komClassificationsWon ?? this.komClassificationsWon,
      youthClassificationsWon:
          youthClassificationsWon ?? this.youthClassificationsWon,
      otherWorldTourWins: otherWorldTourWins ?? this.otherWorldTourWins,
      totalCareerVictories: totalCareerVictories ?? this.totalCareerVictories,
      entries: entries ?? this.entries,
    );
  }

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'riderName': riderName,
        'nationalityIso': nationalityIso,
        'grandTourOverallWins': grandTourOverallWins,
        'tourDeFranceGcWins': tourDeFranceGcWins,
        'giroDItaliaGcWins': giroDItaliaGcWins,
        'vueltaAEspanaGcWins': vueltaAEspanaGcWins,
        'grandTourStageWins': grandTourStageWins,
        'tourDeFranceStageWins': tourDeFranceStageWins,
        'giroStageWins': giroStageWins,
        'vueltaStageWins': vueltaStageWins,
        'monumentWins': monumentWins,
        'milanoSanRemoWins': milanoSanRemoWins,
        'rondeVanVlaanderenWins': rondeVanVlaanderenWins,
        'parisRoubaixWins': parisRoubaixWins,
        'liegeBastogneLiegeWins': liegeBastogneLiegeWins,
        'ilLombardiaWins': ilLombardiaWins,
        'worldChampionshipRoadWins': worldChampionshipRoadWins,
        'worldChampionshipTimeTrialWins': worldChampionshipTimeTrialWins,
        'daysInYellowJersey': daysInYellowJersey,
        'daysInPinkJersey': daysInPinkJersey,
        'daysInRedJersey': daysInRedJersey,
        'pointsClassificationsWon': pointsClassificationsWon,
        'komClassificationsWon': komClassificationsWon,
        'youthClassificationsWon': youthClassificationsWon,
        'otherWorldTourWins': otherWorldTourWins,
        'totalCareerVictories': totalCareerVictories,
        'entries': entries.map((e) => e.toJson()).toList(),
      };

  factory RiderPalmares.fromJson(Map<String, dynamic> json) {
    return RiderPalmares(
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      nationalityIso: json['nationalityIso'] as String,
      grandTourOverallWins: (json['grandTourOverallWins'] as num?)?.toInt() ?? 0,
      tourDeFranceGcWins: (json['tourDeFranceGcWins'] as num?)?.toInt() ?? 0,
      giroDItaliaGcWins: (json['giroDItaliaGcWins'] as num?)?.toInt() ?? 0,
      vueltaAEspanaGcWins: (json['vueltaAEspanaGcWins'] as num?)?.toInt() ?? 0,
      grandTourStageWins: (json['grandTourStageWins'] as num?)?.toInt() ?? 0,
      tourDeFranceStageWins:
          (json['tourDeFranceStageWins'] as num?)?.toInt() ?? 0,
      giroStageWins: (json['giroStageWins'] as num?)?.toInt() ?? 0,
      vueltaStageWins: (json['vueltaStageWins'] as num?)?.toInt() ?? 0,
      monumentWins: (json['monumentWins'] as num?)?.toInt() ?? 0,
      milanoSanRemoWins: (json['milanoSanRemoWins'] as num?)?.toInt() ?? 0,
      rondeVanVlaanderenWins:
          (json['rondeVanVlaanderenWins'] as num?)?.toInt() ?? 0,
      parisRoubaixWins: (json['parisRoubaixWins'] as num?)?.toInt() ?? 0,
      liegeBastogneLiegeWins:
          (json['liegeBastogneLiegeWins'] as num?)?.toInt() ?? 0,
      ilLombardiaWins: (json['ilLombardiaWins'] as num?)?.toInt() ?? 0,
      worldChampionshipRoadWins:
          (json['worldChampionshipRoadWins'] as num?)?.toInt() ?? 0,
      worldChampionshipTimeTrialWins:
          (json['worldChampionshipTimeTrialWins'] as num?)?.toInt() ?? 0,
      daysInYellowJersey: (json['daysInYellowJersey'] as num?)?.toInt() ?? 0,
      daysInPinkJersey: (json['daysInPinkJersey'] as num?)?.toInt() ?? 0,
      daysInRedJersey: (json['daysInRedJersey'] as num?)?.toInt() ?? 0,
      pointsClassificationsWon:
          (json['pointsClassificationsWon'] as num?)?.toInt() ?? 0,
      komClassificationsWon:
          (json['komClassificationsWon'] as num?)?.toInt() ?? 0,
      youthClassificationsWon:
          (json['youthClassificationsWon'] as num?)?.toInt() ?? 0,
      otherWorldTourWins: (json['otherWorldTourWins'] as num?)?.toInt() ?? 0,
      totalCareerVictories:
          (json['totalCareerVictories'] as num?)?.toInt() ?? 0,
      entries: (json['entries'] as List<dynamic>?)
              ?.map((e) => PalmaresEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Próba wjazdu lub historyczny czas na podjeździe.
class ClimbAttemptEntry {
  final String riderId;
  final String riderName;
  final String teamName;
  final int timeSeconds;
  final int seasonYear;
  final String raceName;
  final double vamMetersPerHour;
  final double estimatedWattsPerKg;

  const ClimbAttemptEntry({
    required this.riderId,
    required this.riderName,
    required this.teamName,
    required this.timeSeconds,
    required this.seasonYear,
    required this.raceName,
    required this.vamMetersPerHour,
    required this.estimatedWattsPerKg,
  });

  String get formattedTime =>
      Formatters.formatRaceTime(timeSeconds, showHoursAlways: false);

  String get formattedVam => '${vamMetersPerHour.round()} VAM (m/h)';

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'riderName': riderName,
        'teamName': teamName,
        'timeSeconds': timeSeconds,
        'seasonYear': seasonYear,
        'raceName': raceName,
        'vamMetersPerHour': vamMetersPerHour,
        'estimatedWattsPerKg': estimatedWattsPerKg,
      };

  factory ClimbAttemptEntry.fromJson(Map<String, dynamic> json) {
    return ClimbAttemptEntry(
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      teamName: json['teamName'] as String,
      timeSeconds: (json['timeSeconds'] as num).toInt(),
      seasonYear: (json['seasonYear'] as num).toInt(),
      raceName: json['raceName'] as String,
      vamMetersPerHour: (json['vamMetersPerHour'] as num).toDouble(),
      estimatedWattsPerKg: (json['estimatedWattsPerKg'] as num).toDouble(),
    );
  }
}

/// Rekord czasowy i klasyfikacja KOM na słynnym podjeździe kolarskim (KOM Time Record).
class ClimbKomRecord {
  final String climbId;
  final String climbName;
  final String mountainRange;
  final String countryIso;
  final double lengthKm;
  final double averageGradientPct;
  final double elevationGainM;
  final int recordTimeSeconds;
  final String recordHolderRiderId;
  final String recordHolderRiderName;
  final String recordHolderTeamName;
  final int achievedInSeasonYear;
  final String achievedInRaceName;
  final double vamMetersPerHour; // Velocità Ascensionale Media (m/h)
  final double estimatedWattsPerKg; // Szacowana moc na podjeździe (W/kg)
  final List<ClimbAttemptEntry> topAttempts;

  const ClimbKomRecord({
    required this.climbId,
    required this.climbName,
    required this.mountainRange,
    required this.countryIso,
    required this.lengthKm,
    required this.averageGradientPct,
    required this.elevationGainM,
    required this.recordTimeSeconds,
    required this.recordHolderRiderId,
    required this.recordHolderRiderName,
    required this.recordHolderTeamName,
    required this.achievedInSeasonYear,
    required this.achievedInRaceName,
    required this.vamMetersPerHour,
    required this.estimatedWattsPerKg,
    this.topAttempts = const [],
  });

  String get formattedRecordTime =>
      Formatters.formatRaceTime(recordTimeSeconds, showHoursAlways: false);

  String get formattedVam => '${vamMetersPerHour.round()} VAM (m/h)';

  ClimbKomRecord copyWith({
    String? climbId,
    String? climbName,
    String? mountainRange,
    String? countryIso,
    double? lengthKm,
    double? averageGradientPct,
    double? elevationGainM,
    int? recordTimeSeconds,
    String? recordHolderRiderId,
    String? recordHolderRiderName,
    String? recordHolderTeamName,
    int? achievedInSeasonYear,
    String? achievedInRaceName,
    double? vamMetersPerHour,
    double? estimatedWattsPerKg,
    List<ClimbAttemptEntry>? topAttempts,
  }) {
    return ClimbKomRecord(
      climbId: climbId ?? this.climbId,
      climbName: climbName ?? this.climbName,
      mountainRange: mountainRange ?? this.mountainRange,
      countryIso: countryIso ?? this.countryIso,
      lengthKm: lengthKm ?? this.lengthKm,
      averageGradientPct: averageGradientPct ?? this.averageGradientPct,
      elevationGainM: elevationGainM ?? this.elevationGainM,
      recordTimeSeconds: recordTimeSeconds ?? this.recordTimeSeconds,
      recordHolderRiderId: recordHolderRiderId ?? this.recordHolderRiderId,
      recordHolderRiderName:
          recordHolderRiderName ?? this.recordHolderRiderName,
      recordHolderTeamName: recordHolderTeamName ?? this.recordHolderTeamName,
      achievedInSeasonYear: achievedInSeasonYear ?? this.achievedInSeasonYear,
      achievedInRaceName: achievedInRaceName ?? this.achievedInRaceName,
      vamMetersPerHour: vamMetersPerHour ?? this.vamMetersPerHour,
      estimatedWattsPerKg: estimatedWattsPerKg ?? this.estimatedWattsPerKg,
      topAttempts: topAttempts ?? this.topAttempts,
    );
  }

  Map<String, dynamic> toJson() => {
        'climbId': climbId,
        'climbName': climbName,
        'mountainRange': mountainRange,
        'countryIso': countryIso,
        'lengthKm': lengthKm,
        'averageGradientPct': averageGradientPct,
        'elevationGainM': elevationGainM,
        'recordTimeSeconds': recordTimeSeconds,
        'recordHolderRiderId': recordHolderRiderId,
        'recordHolderRiderName': recordHolderRiderName,
        'recordHolderTeamName': recordHolderTeamName,
        'achievedInSeasonYear': achievedInSeasonYear,
        'achievedInRaceName': achievedInRaceName,
        'vamMetersPerHour': vamMetersPerHour,
        'estimatedWattsPerKg': estimatedWattsPerKg,
        'topAttempts': topAttempts.map((a) => a.toJson()).toList(),
      };

  factory ClimbKomRecord.fromJson(Map<String, dynamic> json) {
    return ClimbKomRecord(
      climbId: json['climbId'] as String,
      climbName: json['climbName'] as String,
      mountainRange: json['mountainRange'] as String,
      countryIso: json['countryIso'] as String,
      lengthKm: (json['lengthKm'] as num).toDouble(),
      averageGradientPct: (json['averageGradientPct'] as num).toDouble(),
      elevationGainM: (json['elevationGainM'] as num).toDouble(),
      recordTimeSeconds: (json['recordTimeSeconds'] as num).toInt(),
      recordHolderRiderId: json['recordHolderRiderId'] as String,
      recordHolderRiderName: json['recordHolderRiderName'] as String,
      recordHolderTeamName: json['recordHolderTeamName'] as String,
      achievedInSeasonYear: (json['achievedInSeasonYear'] as num).toInt(),
      achievedInRaceName: json['achievedInRaceName'] as String,
      vamMetersPerHour: (json['vamMetersPerHour'] as num).toDouble(),
      estimatedWattsPerKg: (json['estimatedWattsPerKg'] as num).toDouble(),
      topAttempts: (json['topAttempts'] as List<dynamic>?)
              ?.map((e) => ClimbAttemptEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Archiwum wyścigu w danym sezonie (Race Season Archive Record).
class RaceSeasonArchiveRecord {
  final int seasonYear;
  final String raceId;
  final String raceName;
  final RaceCategory raceCategory;
  final String winnerRiderId;
  final String winnerRiderName;
  final String winnerTeamId;
  final String winnerTeamName;
  final int winningMarginSeconds;
  final List<String> podiumRiderNames;
  final Map<int, String> stageWinners; // Numer etapu -> Nazwisko zwycięzcy
  final Map<String, String> jerseyWinners; // Typ koszulki -> Nazwisko
  final String notes;

  const RaceSeasonArchiveRecord({
    required this.seasonYear,
    required this.raceId,
    required this.raceName,
    required this.raceCategory,
    required this.winnerRiderId,
    required this.winnerRiderName,
    required this.winnerTeamId,
    required this.winnerTeamName,
    required this.winningMarginSeconds,
    this.podiumRiderNames = const [],
    this.stageWinners = const {},
    this.jerseyWinners = const {},
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
        'seasonYear': seasonYear,
        'raceId': raceId,
        'raceName': raceName,
        'raceCategory': raceCategory.toJson(),
        'winnerRiderId': winnerRiderId,
        'winnerRiderName': winnerRiderName,
        'winnerTeamId': winnerTeamId,
        'winnerTeamName': winnerTeamName,
        'winningMarginSeconds': winningMarginSeconds,
        'podiumRiderNames': podiumRiderNames,
        'stageWinners':
            stageWinners.map((k, v) => MapEntry(k.toString(), v)),
        'jerseyWinners': jerseyWinners,
        'notes': notes,
      };

  factory RaceSeasonArchiveRecord.fromJson(Map<String, dynamic> json) {
    final stagesRaw = json['stageWinners'] as Map<String, dynamic>? ?? {};
    final stagesMap = stagesRaw.map(
      (k, v) => MapEntry(int.parse(k), v as String),
    );

    return RaceSeasonArchiveRecord(
      seasonYear: (json['seasonYear'] as num).toInt(),
      raceId: json['raceId'] as String,
      raceName: json['raceName'] as String,
      raceCategory: RaceCategory.fromJson(json['raceCategory'] as String),
      winnerRiderId: json['winnerRiderId'] as String,
      winnerRiderName: json['winnerRiderName'] as String,
      winnerTeamId: json['winnerTeamId'] as String,
      winnerTeamName: json['winnerTeamName'] as String,
      winningMarginSeconds: (json['winningMarginSeconds'] as num).toInt(),
      podiumRiderNames: (json['podiumRiderNames'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      stageWinners: stagesMap,
      jerseyWinners: Map<String, String>.from(
          json['jerseyWinners'] as Map? ?? {}),
      notes: json['notes'] as String? ?? '',
    );
  }
}

/// Wpis w Rankingu Wszech Czasów (Hall of Fame / All-Time Greats).
class AllTimeRankingEntry {
  final int rank;
  final String riderId;
  final String riderName;
  final String nationalityIso;
  final bool isActive;
  final int allTimePoints;
  final int grandTourGcWins;
  final int monumentWins;
  final int grandTourStageWins;
  final int daysInYellowJersey;
  final int worldTitles;
  final String trophySummary;

  const AllTimeRankingEntry({
    required this.rank,
    required this.riderId,
    required this.riderName,
    required this.nationalityIso,
    required this.isActive,
    required this.allTimePoints,
    required this.grandTourGcWins,
    required this.monumentWins,
    required this.grandTourStageWins,
    required this.daysInYellowJersey,
    required this.worldTitles,
    required this.trophySummary,
  });

  Map<String, dynamic> toJson() => {
        'rank': rank,
        'riderId': riderId,
        'riderName': riderName,
        'nationalityIso': nationalityIso,
        'isActive': isActive,
        'allTimePoints': allTimePoints,
        'grandTourGcWins': grandTourGcWins,
        'monumentWins': monumentWins,
        'grandTourStageWins': grandTourStageWins,
        'daysInYellowJersey': daysInYellowJersey,
        'worldTitles': worldTitles,
        'trophySummary': trophySummary,
      };

  factory AllTimeRankingEntry.fromJson(Map<String, dynamic> json) {
    return AllTimeRankingEntry(
      rank: (json['rank'] as num).toInt(),
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      nationalityIso: json['nationalityIso'] as String,
      isActive: json['isActive'] as bool,
      allTimePoints: (json['allTimePoints'] as num).toInt(),
      grandTourGcWins: (json['grandTourGcWins'] as num).toInt(),
      monumentWins: (json['monumentWins'] as num).toInt(),
      grandTourStageWins: (json['grandTourStageWins'] as num).toInt(),
      daysInYellowJersey: (json['daysInYellowJersey'] as num).toInt(),
      worldTitles: (json['worldTitles'] as num).toInt(),
      trophySummary: json['trophySummary'] as String,
    );
  }
}

/// Rezultat próby bicia rekordu na podjeździe (KOM Attempt Result).
class ClimbAttemptResult {
  final bool isNewKomRecord;
  final ClimbKomRecord updatedRecord;
  final int? previousRecordTimeSeconds;
  final int timeDeltaSeconds;
  final double currentVam;
  final double estimatedWattsPerKg;
  final String celebrationMessage;

  const ClimbAttemptResult({
    required this.isNewKomRecord,
    required this.updatedRecord,
    this.previousRecordTimeSeconds,
    required this.timeDeltaSeconds,
    required this.currentVam,
    required this.estimatedWattsPerKg,
    required this.celebrationMessage,
  });
}

/// Serwis Archiwum Historii Kolarstwa, Rekordów Podjazdów i Gabloty Trofeów (Palmarès).
class HistoricalRecordsAndPalmaresService {
  final Map<String, RiderPalmares> _riderPalmaresMap = {};
  final Map<String, ClimbKomRecord> _climbRecordsMap = {};
  final List<RaceSeasonArchiveRecord> _seasonArchives = [];

  HistoricalRecordsAndPalmaresService({
    Map<String, RiderPalmares>? riderPalmares,
    Map<String, ClimbKomRecord>? climbRecords,
    List<RaceSeasonArchiveRecord>? seasonArchives,
  }) {
    if (climbRecords != null && climbRecords.isNotEmpty) {
      _climbRecordsMap.addAll(climbRecords);
    } else {
      _initDefaultClimbRecords();
    }

    if (riderPalmares != null) {
      _riderPalmaresMap.addAll(riderPalmares);
    } else {
      _initDefaultRiderPalmares();
    }

    if (seasonArchives != null) {
      _seasonArchives.addAll(seasonArchives);
    }
  }

  /// 1. Rejestruje zakończenie wyścigu, zapisuje archiwum i aktualizuje Palmarès kolarzy.
  void registerRaceCompletion({
    required TourRace race,
    required int seasonYear,
    required String winningRiderId,
    required String winningRiderName,
    required String winningTeamId,
    required String winningTeamName,
    required int winningMarginSeconds,
    List<String> podiumRiderNames = const [],
    Map<int, ({String riderId, String riderName, String teamId, String teamName})> stageWinners = const {},
    Map<String, ({String riderId, String riderName})> jerseyWinners = const {},
    Map<String, int> daysInLeaderJersey = const {},
    String notes = '',
  }) {
    // 1. Zapis do archiwum wyścigów sezonu
    final stageWinnersNames = <int, String>{};
    stageWinners.forEach((stgNum, data) {
      stageWinnersNames[stgNum] = data.riderName;
    });

    final jerseyWinnersNames = <String, String>{};
    jerseyWinners.forEach((jersey, data) {
      jerseyWinnersNames[jersey] = data.riderName;
    });

    final archiveEntry = RaceSeasonArchiveRecord(
      seasonYear: seasonYear,
      raceId: race.id,
      raceName: race.name,
      raceCategory: race.uciCategory,
      winnerRiderId: winningRiderId,
      winnerRiderName: winningRiderName,
      winnerTeamId: winningTeamId,
      winnerTeamName: winningTeamName,
      winningMarginSeconds: winningMarginSeconds,
      podiumRiderNames: podiumRiderNames,
      stageWinners: stageWinnersNames,
      jerseyWinners: jerseyWinnersNames,
      notes: notes,
    );
    _seasonArchives.add(archiveEntry);

    // 2. Aktualizacja Palmarès zwycięzcy klasyfikacji generalnej / wyścigu
    final gcRiderPalmares = _getOrCreateRiderPalmares(
      riderId: winningRiderId,
      riderName: winningRiderName,
    );

    final bool isTdF = race.id.toLowerCase().contains('tour') &&
        (race.isGrandTour || race.name.toLowerCase().contains('france') || race.name.toLowerCase().contains('boucle'));
    final bool isGiro = race.id.toLowerCase().contains('giro') || race.name.toLowerCase().contains('italia') || race.name.toLowerCase().contains('corsa rosa');
    final bool isVuelta = race.id.toLowerCase().contains('vuelta') || race.name.toLowerCase().contains('españa');
    final bool isMonument = race.uciCategory == RaceCategory.monument;

    final nameLower = race.name.toLowerCase();
    final bool isMSR = nameLower.contains('sanremo') || nameLower.contains('primavera');
    final bool isRVV = nameLower.contains('flanders') || nameLower.contains('vlaanderen');
    final bool isPR = nameLower.contains('roubaix') || nameLower.contains('hell of the north');
    final bool isLBL = nameLower.contains('liège') || nameLower.contains('liege') || nameLower.contains('doyenne');
    final bool isLombardia = nameLower.contains('lombardia') || nameLower.contains('falling leaves');

    PalmaresAchievementType achievementType;
    String detailsText;

    if (race.isGrandTour) {
      achievementType = PalmaresAchievementType.grandTourGeneralClassification;
      detailsText = 'Triumf w klasyfikacji generalnej (${Formatters.formatRaceTime(winningMarginSeconds, showHoursAlways: false)} przewagi)';
    } else if (isMonument) {
      achievementType = PalmaresAchievementType.monumentClassic;
      detailsText = 'Triumf w Monumencie kolarstwa';
    } else if (race.isOneDayRace) {
      achievementType = PalmaresAchievementType.worldTourOneDay;
      detailsText = 'Zwycięstwo w prestiżowym wyścigu klasycznym';
    } else {
      achievementType = PalmaresAchievementType.worldTourStageRaceGc;
      detailsText = 'Zwycięstwo w klasyfikacji generalnej';
    }

    final gcEntry = PalmaresEntry(
      id: 'pal_${winningRiderId}_${race.id}_$seasonYear',
      riderId: winningRiderId,
      riderName: winningRiderName,
      teamId: winningTeamId,
      teamName: winningTeamName,
      seasonYear: seasonYear,
      date: DateTime(seasonYear, race.startMonth, race.startDay),
      raceId: race.id,
      raceName: race.name,
      raceCategory: race.uciCategory,
      achievementType: achievementType,
      details: detailsText,
      jerseyWorn: isTdF ? 'Maillot Jaune' : (isGiro ? 'Maglia Rosa' : (isVuelta ? 'La Roja' : null)),
    );

    int daysInYellow = daysInLeaderJersey[winningRiderId] ?? 0;
    int daysInPink = (isGiro && daysInLeaderJersey.containsKey(winningRiderId)) ? daysInLeaderJersey[winningRiderId]! : 0;
    int daysInRed = (isVuelta && daysInLeaderJersey.containsKey(winningRiderId)) ? daysInLeaderJersey[winningRiderId]! : 0;

    final updatedGcPalmares = gcRiderPalmares.copyWith(
      grandTourOverallWins: race.isGrandTour
          ? gcRiderPalmares.grandTourOverallWins + 1
          : gcRiderPalmares.grandTourOverallWins,
      tourDeFranceGcWins: isTdF
          ? gcRiderPalmares.tourDeFranceGcWins + 1
          : gcRiderPalmares.tourDeFranceGcWins,
      giroDItaliaGcWins: isGiro
          ? gcRiderPalmares.giroDItaliaGcWins + 1
          : gcRiderPalmares.giroDItaliaGcWins,
      vueltaAEspanaGcWins: isVuelta
          ? gcRiderPalmares.vueltaAEspanaGcWins + 1
          : gcRiderPalmares.vueltaAEspanaGcWins,
      monumentWins: isMonument
          ? gcRiderPalmares.monumentWins + 1
          : gcRiderPalmares.monumentWins,
      milanoSanRemoWins: isMSR
          ? gcRiderPalmares.milanoSanRemoWins + 1
          : gcRiderPalmares.milanoSanRemoWins,
      rondeVanVlaanderenWins: isRVV
          ? gcRiderPalmares.rondeVanVlaanderenWins + 1
          : gcRiderPalmares.rondeVanVlaanderenWins,
      parisRoubaixWins: isPR
          ? gcRiderPalmares.parisRoubaixWins + 1
          : gcRiderPalmares.parisRoubaixWins,
      liegeBastogneLiegeWins: isLBL
          ? gcRiderPalmares.liegeBastogneLiegeWins + 1
          : gcRiderPalmares.liegeBastogneLiegeWins,
      ilLombardiaWins: isLombardia
          ? gcRiderPalmares.ilLombardiaWins + 1
          : gcRiderPalmares.ilLombardiaWins,
      daysInYellowJersey: isTdF
          ? gcRiderPalmares.daysInYellowJersey + daysInYellow
          : gcRiderPalmares.daysInYellowJersey,
      daysInPinkJersey: gcRiderPalmares.daysInPinkJersey + daysInPink,
      daysInRedJersey: gcRiderPalmares.daysInRedJersey + daysInRed,
      otherWorldTourWins: (!race.isGrandTour && !isMonument)
          ? gcRiderPalmares.otherWorldTourWins + 1
          : gcRiderPalmares.otherWorldTourWins,
      totalCareerVictories: gcRiderPalmares.totalCareerVictories + 1,
      entries: [...gcRiderPalmares.entries, gcEntry],
    );
    _riderPalmaresMap[winningRiderId] = updatedGcPalmares;

    // 3. Aktualizacja zwycięstw etapowych
    stageWinners.forEach((stageNum, sData) {
      final sRiderPalmares = _getOrCreateRiderPalmares(
        riderId: sData.riderId,
        riderName: sData.riderName,
      );

      final stageEntry = PalmaresEntry(
        id: 'pal_st_${sData.riderId}_${race.id}_${stageNum}_$seasonYear',
        riderId: sData.riderId,
        riderName: sData.riderName,
        teamId: sData.teamId,
        teamName: sData.teamName,
        seasonYear: seasonYear,
        date: DateTime(seasonYear, race.startMonth, race.startDay + stageNum),
        raceId: race.id,
        raceName: race.name,
        raceCategory: race.uciCategory,
        achievementType: race.isGrandTour
            ? PalmaresAchievementType.grandTourStage
            : PalmaresAchievementType.proSeriesOrOtherWin,
        details: 'Wygrana na etapie $stageNum',
      );

      final updatedStagePalmares = sRiderPalmares.copyWith(
        grandTourStageWins: race.isGrandTour
            ? sRiderPalmares.grandTourStageWins + 1
            : sRiderPalmares.grandTourStageWins,
        tourDeFranceStageWins: (race.isGrandTour && isTdF)
            ? sRiderPalmares.tourDeFranceStageWins + 1
            : sRiderPalmares.tourDeFranceStageWins,
        giroStageWins: (race.isGrandTour && isGiro)
            ? sRiderPalmares.giroStageWins + 1
            : sRiderPalmares.giroStageWins,
        vueltaStageWins: (race.isGrandTour && isVuelta)
            ? sRiderPalmares.vueltaStageWins + 1
            : sRiderPalmares.vueltaStageWins,
        totalCareerVictories: sRiderPalmares.totalCareerVictories + 1,
        entries: [...sRiderPalmares.entries, stageEntry],
      );
      _riderPalmaresMap[sData.riderId] = updatedStagePalmares;
    });

    // 4. Aktualizacja zdobywców koszulek pobocznych
    jerseyWinners.forEach((jerseyType, jData) {
      if (jData.riderId == winningRiderId && jerseyType.toLowerCase().contains('gc')) {
        return; // Już obsłużone powyżej
      }

      final jPalmares = _getOrCreateRiderPalmares(
        riderId: jData.riderId,
        riderName: jData.riderName,
      );

      final jTypeLower = jerseyType.toLowerCase();
      PalmaresAchievementType ach;
      String desc;

      if (jTypeLower.contains('point') ||
          jTypeLower.contains('sprinter') ||
          jTypeLower.contains('vert') ||
          jTypeLower.contains('green') ||
          jTypeLower.contains('ciclamino') ||
          jTypeLower.contains('zielon')) {
        ach = PalmaresAchievementType.pointsJerseyWinner;
        desc = 'Triumf w klasyfikacji punktowej (Maillot Vert / Maglia Ciclamino)';
      } else if (jTypeLower.contains('kom') ||
          jTypeLower.contains('mountain') ||
          jTypeLower.contains('pois') ||
          jTypeLower.contains('groch') ||
          jTypeLower.contains('azzurra') ||
          jTypeLower.contains('niebiesk') ||
          jTypeLower.contains('górsk')) {
        ach = PalmaresAchievementType.komJerseyWinner;
        desc = 'Triumf w klasyfikacji górskiej (Król Gór / Maillot à Pois)';
      } else {
        ach = PalmaresAchievementType.youthJerseyWinner;
        desc = 'Triumf w klasyfikacji młodzieżowej (Biała koszulka)';
      }

      final jEntry = PalmaresEntry(
        id: 'pal_j_${jData.riderId}_${race.id}_${jerseyType}_$seasonYear',
        riderId: jData.riderId,
        riderName: jData.riderName,
        teamId: winningTeamId,
        teamName: winningTeamName,
        seasonYear: seasonYear,
        date: DateTime(seasonYear, race.startMonth, race.startDay),
        raceId: race.id,
        raceName: race.name,
        raceCategory: race.uciCategory,
        achievementType: ach,
        details: desc,
        jerseyWorn: jerseyType,
      );

      final updatedJPalmares = jPalmares.copyWith(
        pointsClassificationsWon: ach == PalmaresAchievementType.pointsJerseyWinner
            ? jPalmares.pointsClassificationsWon + 1
            : jPalmares.pointsClassificationsWon,
        komClassificationsWon: ach == PalmaresAchievementType.komJerseyWinner
            ? jPalmares.komClassificationsWon + 1
            : jPalmares.komClassificationsWon,
        youthClassificationsWon: ach == PalmaresAchievementType.youthJerseyWinner
            ? jPalmares.youthClassificationsWon + 1
            : jPalmares.youthClassificationsWon,
        entries: [...jPalmares.entries, jEntry],
      );
      _riderPalmaresMap[jData.riderId] = updatedJPalmares;
    });
  }

  /// 2. Rejestruje próbę na słynnym podjeździe, weryfikuje pobicie rekordu KOM i wylicza VAM (m/h).
  ClimbAttemptResult recordClimbAttempt({
    required String climbId,
    required String riderId,
    required String riderName,
    required String teamName,
    required int timeSeconds,
    required int seasonYear,
    required String raceName,
    double? riderWeightKg,
  }) {
    final climb = _climbRecordsMap[climbId];
    if (climb == null) {
      throw ArgumentError('Nieznany podjazd o identyfikatorze: $climbId');
    }

    // Wyliczenie VAM (Velocità Ascensionale Media / Prędkość pionowa wznoszenia w metrach na godzinę)
    // VAM = (przewyższenie [m] / czas [s]) * 3600
    final double calculatedVam =
        (climb.elevationGainM / math.max(1, timeSeconds)) * 3600.0;

    // Estymacja mocy względnej W/kg według formuły empirycznej Ferrariego dla kolarstwa zawodowego:
    // W/kg ≈ VAM / (100 * (2 + nachylenie% * 0.1))
    final double estimatedWkg =
        calculatedVam / (100.0 * (2.0 + (climb.averageGradientPct * 0.10)));

    final attempt = ClimbAttemptEntry(
      riderId: riderId,
      riderName: riderName,
      teamName: teamName,
      timeSeconds: timeSeconds,
      seasonYear: seasonYear,
      raceName: raceName,
      vamMetersPerHour: double.parse(calculatedVam.toStringAsFixed(1)),
      estimatedWattsPerKg: double.parse(estimatedWkg.toStringAsFixed(2)),
    );

    final bool isNewRecord = timeSeconds < climb.recordTimeSeconds;
    final int previousTime = climb.recordTimeSeconds;
    final int delta = previousTime - timeSeconds;

    var updatedAttempts = List<ClimbAttemptEntry>.from(climb.topAttempts);
    updatedAttempts.add(attempt);
    updatedAttempts.sort((a, b) => a.timeSeconds.compareTo(b.timeSeconds));
    if (updatedAttempts.length > 10) {
      updatedAttempts = updatedAttempts.take(10).toList();
    }

    ClimbKomRecord updatedClimb;
    String celebration;

    if (isNewRecord) {
      updatedClimb = climb.copyWith(
        recordTimeSeconds: timeSeconds,
        recordHolderRiderId: riderId,
        recordHolderRiderName: riderName,
        recordHolderTeamName: teamName,
        achievedInSeasonYear: seasonYear,
        achievedInRaceName: raceName,
        vamMetersPerHour: double.parse(calculatedVam.toStringAsFixed(1)),
        estimatedWattsPerKg: double.parse(estimatedWkg.toStringAsFixed(2)),
        topAttempts: updatedAttempts,
      );
      celebration =
          'NOWY REKORD WSZECH CZASÓW! $riderName pobił historyczny rekord na ${climb.climbName} z kosmicznym czasem ${Formatters.formatRaceTime(timeSeconds, showHoursAlways: false)} (poprawa o $delta s, ${calculatedVam.round()} VAM, ~${estimatedWkg.toStringAsFixed(2)} W/kg)!';
    } else {
      updatedClimb = climb.copyWith(topAttempts: updatedAttempts);
      celebration =
          '$riderName pokonał ${climb.climbName} w czasie ${Formatters.formatRaceTime(timeSeconds, showHoursAlways: false)} (${calculatedVam.round()} VAM), tracąc ${timeSeconds - previousTime} s do rekordu ${climb.recordHolderRiderName}.';
    }

    _climbRecordsMap[climbId] = updatedClimb;

    return ClimbAttemptResult(
      isNewKomRecord: isNewRecord,
      updatedRecord: updatedClimb,
      previousRecordTimeSeconds: previousTime,
      timeDeltaSeconds: delta,
      currentVam: double.parse(calculatedVam.toStringAsFixed(1)),
      estimatedWattsPerKg: double.parse(estimatedWkg.toStringAsFixed(2)),
      celebrationMessage: celebration,
    );
  }

  /// 3. Zwraca profil sukcesów i gablotę trofeów danego kolarza.
  RiderPalmares? getRiderPalmares(String riderId) => _riderPalmaresMap[riderId];

  /// 4. Zwraca archiwum wszystkich wyścigów w danym sezonie.
  List<RaceSeasonArchiveRecord> getSeasonWinners(int seasonYear) {
    return _seasonArchives.where((r) => r.seasonYear == seasonYear).toList();
  }

  /// 5. Zwraca listę wszystkich słynnych podjazdów i ich rekordów KOM.
  List<ClimbKomRecord> getClimbRecords() => _climbRecordsMap.values.toList();

  /// 6. Zwraca konkretny rekord podjazdu po ID.
  ClimbKomRecord? getClimbRecordById(String climbId) => _climbRecordsMap[climbId];

  /// 7. Generuje oficjalny Ranking Wszech Czasów (All-Time Hall of Fame) łączący legendy z aktywnymi kolarzami.
  List<AllTimeRankingEntry> getAllTimeHallOfFame() {
    final entries = <AllTimeRankingEntry>[];

    // Aktywni kolarze w grze
    for (final p in _riderPalmaresMap.values) {
      if (p.calculateAllTimeGoatPoints > 0) {
        entries.add(
          AllTimeRankingEntry(
            rank: 0,
            riderId: p.riderId,
            riderName: p.riderName,
            nationalityIso: p.nationalityIso,
            isActive: true,
            allTimePoints: p.calculateAllTimeGoatPoints,
            grandTourGcWins: p.grandTourOverallWins,
            monumentWins: p.monumentWins,
            grandTourStageWins: p.grandTourStageWins,
            daysInYellowJersey: p.daysInYellowJersey,
            worldTitles: p.worldChampionshipRoadWins + p.worldChampionshipTimeTrialWins,
            trophySummary: _buildTrophySummary(p),
          ),
        );
      }
    }

    // Sortowanie według punktów wszech czasów malejąco
    entries.sort((a, b) => b.allTimePoints.compareTo(a.allTimePoints));

    // Nadanie oficjalnej pozycji rankingowej 1..N
    return entries.asMap().entries.map((entry) {
      final index = entry.key + 1;
      final val = entry.value;
      return AllTimeRankingEntry(
        rank: index,
        riderId: val.riderId,
        riderName: val.riderName,
        nationalityIso: val.nationalityIso,
        isActive: val.isActive,
        allTimePoints: val.allTimePoints,
        grandTourGcWins: val.grandTourGcWins,
        monumentWins: val.monumentWins,
        grandTourStageWins: val.grandTourStageWins,
        daysInYellowJersey: val.daysInYellowJersey,
        worldTitles: val.worldTitles,
        trophySummary: val.trophySummary,
      );
    }).toList();
  }

  /// 8. Zwraca kolarzy z ekskluzywnego klubu zwycięzców etapów we wszystkich 3 Grand Tourach (Giro, Tour, Vuelta).
  List<RiderPalmares> getGrandTourStageTrifectaClub() {
    return _riderPalmaresMap.values
        .where((r) => r.hasGrandTourStageTrifecta)
        .toList()
      ..sort((a, b) => b.grandTourStageWins.compareTo(a.grandTourStageWins));
  }

  /// 9. Zwraca kolarzy z największą liczbą wygranych w Monumentach kolarstwa.
  List<RiderPalmares> getMonumentKings() {
    return _riderPalmaresMap.values
        .where((r) => r.monumentWins > 0)
        .toList()
      ..sort((a, b) => b.monumentWins.compareTo(a.monumentWins));
  }

  // --- METODY POMOCNICZE I INICJALIZACJA HISTORII ---

  RiderPalmares _getOrCreateRiderPalmares({
    required String riderId,
    required String riderName,
    String nationalityIso = 'FRA',
  }) {
    return _riderPalmaresMap.putIfAbsent(
      riderId,
      () => RiderPalmares(
        riderId: riderId,
        riderName: riderName,
        nationalityIso: nationalityIso,
      ),
    );
  }

  String _buildTrophySummary(RiderPalmares p) {
    final parts = <String>[];
    if (p.tourDeFranceGcWins > 0) parts.add('${p.tourDeFranceGcWins}x TdF');
    if (p.giroDItaliaGcWins > 0) parts.add('${p.giroDItaliaGcWins}x Giro');
    if (p.vueltaAEspanaGcWins > 0) parts.add('${p.vueltaAEspanaGcWins}x Vuelta');
    if (p.monumentWins > 0) parts.add('${p.monumentWins}x Monumenty');
    if (p.grandTourStageWins > 0) parts.add('${p.grandTourStageWins} et. GT');
    if (p.daysInYellowJersey > 0) parts.add('${p.daysInYellowJersey} dni żółta');
    if (p.worldChampionshipRoadWins > 0) parts.add('${p.worldChampionshipRoadWins}x MŚ');
    if (parts.isEmpty) return 'Brak tytułów najwyższej rangi';
    return parts.join(', ');
  }

  /// Inicjalizuje bazę słynnych podjazdów kolarskich z ich historycznymi rekordami.
  void _initDefaultClimbRecords() {
    _climbRecordsMap['climb_alpe_dhuez'] = const ClimbKomRecord(
      climbId: 'climb_alpe_dhuez',
      climbName: 'Alpe d\'Huez (21 Virages)',
      mountainRange: 'Alpy Francuskie',
      countryIso: 'FRA',
      lengthKm: 13.8,
      averageGradientPct: 8.1,
      elevationGainM: 1118,
      recordTimeSeconds: 2210, // 36:50 Marco Pantani (1995)
      recordHolderRiderId: 'pantani_legend',
      recordHolderRiderName: 'Marco Pantani',
      recordHolderTeamName: 'Mercatone Uno',
      achievedInSeasonYear: 1995,
      achievedInRaceName: 'Tour de France 1995 - Etap 10',
      vamMetersPerHour: 1821.3,
      estimatedWattsPerKg: 6.48,
    );

    _climbRecordsMap['climb_mont_ventoux'] = const ClimbKomRecord(
      climbId: 'climb_mont_ventoux',
      climbName: 'Mont Ventoux (od Bédoin)',
      mountainRange: 'Prowansja (Olbrzym Prowansji)',
      countryIso: 'FRA',
      lengthKm: 21.4,
      averageGradientPct: 7.5,
      elevationGainM: 1600,
      recordTimeSeconds: 3351, // 55:51 Iban Mayo (2004)
      recordHolderRiderId: 'mayo_legend',
      recordHolderRiderName: 'Iban Mayo',
      recordHolderTeamName: 'Euskaltel-Euskadi',
      achievedInSeasonYear: 2004,
      achievedInRaceName: 'Critérium du Dauphiné Libéré 2004',
      vamMetersPerHour: 1718.9,
      estimatedWattsPerKg: 6.25,
    );

    _climbRecordsMap['climb_plateau_de_beille'] = const ClimbKomRecord(
      climbId: 'climb_plateau_de_beille',
      climbName: 'Plateau de Beille',
      mountainRange: 'Pireneje',
      countryIso: 'FRA',
      lengthKm: 15.8,
      averageGradientPct: 7.9,
      elevationGainM: 1250,
      recordTimeSeconds: 2390, // 39:50 Tadej Pogačar (2024)
      recordHolderRiderId: 'pogacar_legend',
      recordHolderRiderName: 'Tadej Pogačar',
      recordHolderTeamName: 'UAE Team Emirates',
      achievedInSeasonYear: 2024,
      achievedInRaceName: 'Tour de France 2024 - Etap 15',
      vamMetersPerHour: 1882.8,
      estimatedWattsPerKg: 6.85,
    );

    _climbRecordsMap['climb_stelvio'] = const ClimbKomRecord(
      climbId: 'climb_stelvio',
      climbName: 'Passo dello Stelvio (Cima Coppi)',
      mountainRange: 'Alpy Retyckie (Dolomity)',
      countryIso: 'ITA',
      lengthKm: 24.5,
      averageGradientPct: 7.4,
      elevationGainM: 1808,
      recordTimeSeconds: 3960, // 1h 06m 00s
      recordHolderRiderId: 'hindley_legend',
      recordHolderRiderName: 'Jai Hindley',
      recordHolderTeamName: 'Team Sunweb',
      achievedInSeasonYear: 2020,
      achievedInRaceName: 'Giro d\'Italia 2020 - Etap 18',
      vamMetersPerHour: 1643.6,
      estimatedWattsPerKg: 5.95,
    );

    _climbRecordsMap['climb_angliru'] = const ClimbKomRecord(
      climbId: 'climb_angliru',
      climbName: 'Alto de l\'Angliru (Cueña les Cabres 23.5%)',
      mountainRange: 'Asturia (Kordyliera Kantabryjska)',
      countryIso: 'ESP',
      lengthKm: 12.5,
      averageGradientPct: 10.1,
      elevationGainM: 1266,
      recordTimeSeconds: 2555, // 42:35 Roberto Heras (2000)
      recordHolderRiderId: 'heras_legend',
      recordHolderRiderName: 'Roberto Heras',
      recordHolderTeamName: 'Kelme-Costa Blanca',
      achievedInSeasonYear: 2000,
      achievedInRaceName: 'Vuelta a España 2000 - Etap 16',
      vamMetersPerHour: 1783.8,
      estimatedWattsPerKg: 5.98,
    );

    _climbRecordsMap['climb_mortirolo'] = const ClimbKomRecord(
      climbId: 'climb_mortirolo',
      climbName: 'Passo del Mortirolo (od Mazzo)',
      mountainRange: 'Alpy Lombardzkie',
      countryIso: 'ITA',
      lengthKm: 12.4,
      averageGradientPct: 10.5,
      elevationGainM: 1300,
      recordTimeSeconds: 2562, // 42:42 Marco Pantani (1994)
      recordHolderRiderId: 'pantani_legend',
      recordHolderRiderName: 'Marco Pantani',
      recordHolderTeamName: 'Carrera Jeans',
      achievedInSeasonYear: 1994,
      achievedInRaceName: 'Giro d\'Italia 1994 - Etap 15',
      vamMetersPerHour: 1826.7,
      estimatedWattsPerKg: 6.00,
    );

    _climbRecordsMap['climb_poggio'] = const ClimbKomRecord(
      climbId: 'climb_poggio',
      climbName: 'Poggio di Sanremo',
      mountainRange: 'Riwiera Liguryjska',
      countryIso: 'ITA',
      lengthKm: 3.7,
      averageGradientPct: 3.7,
      elevationGainM: 137,
      recordTimeSeconds: 335, // 5:35 Mathieu van der Poel (2023)
      recordHolderRiderId: 'mvdp_legend',
      recordHolderRiderName: 'Mathieu van der Poel',
      recordHolderTeamName: 'Alpecin-Deceuninck',
      achievedInSeasonYear: 2023,
      achievedInRaceName: 'Milano-Sanremo 2023',
      vamMetersPerHour: 1472.2,
      estimatedWattsPerKg: 8.20,
    );

    _climbRecordsMap['climb_mur_de_huy'] = const ClimbKomRecord(
      climbId: 'climb_mur_de_huy',
      climbName: 'Mur de Huy (Chemin des Chapelles)',
      mountainRange: 'Ardeny Walońskie',
      countryIso: 'BEL',
      lengthKm: 1.3,
      averageGradientPct: 9.6,
      elevationGainM: 128,
      recordTimeSeconds: 148, // 2:28 Tadej Pogačar (2023)
      recordHolderRiderId: 'pogacar_legend',
      recordHolderRiderName: 'Tadej Pogačar',
      recordHolderTeamName: 'UAE Team Emirates',
      achievedInSeasonYear: 2023,
      achievedInRaceName: 'La Flèche Wallonne 2023',
      vamMetersPerHour: 3113.5,
      estimatedWattsPerKg: 9.40,
    );
  }

  /// Inicjalizuje panteon legend i aktywnych tytanów kolarstwa.
  void _initDefaultRiderPalmares() {
    // 1. Eddy Merckx (Król kolarstwa)
    _riderPalmaresMap['legend_merckx'] = const RiderPalmares(
      riderId: 'legend_merckx',
      riderName: 'Eddy Merckx',
      nationalityIso: 'BEL',
      grandTourOverallWins: 11,
      tourDeFranceGcWins: 5,
      giroDItaliaGcWins: 5,
      vueltaAEspanaGcWins: 1,
      grandTourStageWins: 65,
      tourDeFranceStageWins: 34,
      giroStageWins: 25,
      vueltaStageWins: 6,
      monumentWins: 19,
      milanoSanRemoWins: 7,
      rondeVanVlaanderenWins: 2,
      parisRoubaixWins: 3,
      liegeBastogneLiegeWins: 5,
      ilLombardiaWins: 2,
      worldChampionshipRoadWins: 3,
      daysInYellowJersey: 111,
      daysInPinkJersey: 78,
      daysInRedJersey: 9,
      pointsClassificationsWon: 6,
      komClassificationsWon: 3,
      totalCareerVictories: 286,
    );

    // 2. Bernard Hinault (Borsuk)
    _riderPalmaresMap['legend_hinault'] = const RiderPalmares(
      riderId: 'legend_hinault',
      riderName: 'Bernard Hinault',
      nationalityIso: 'FRA',
      grandTourOverallWins: 10,
      tourDeFranceGcWins: 5,
      giroDItaliaGcWins: 3,
      vueltaAEspanaGcWins: 2,
      grandTourStageWins: 41,
      tourDeFranceStageWins: 28,
      giroStageWins: 6,
      vueltaStageWins: 7,
      monumentWins: 5,
      liegeBastogneLiegeWins: 2,
      parisRoubaixWins: 1,
      ilLombardiaWins: 2,
      worldChampionshipRoadWins: 1,
      daysInYellowJersey: 75,
      daysInPinkJersey: 31,
      daysInRedJersey: 16,
      pointsClassificationsWon: 1,
      komClassificationsWon: 1,
      totalCareerVictories: 147,
    );

    // 3. Tadej Pogačar (Aktywny fenomen)
    _riderPalmaresMap['pogacar_legend'] = const RiderPalmares(
      riderId: 'pogacar_legend',
      riderName: 'Tadej Pogačar',
      nationalityIso: 'SLO',
      grandTourOverallWins: 4,
      tourDeFranceGcWins: 3,
      giroDItaliaGcWins: 1,
      grandTourStageWins: 26,
      tourDeFranceStageWins: 17,
      giroStageWins: 6,
      vueltaStageWins: 3,
      monumentWins: 7,
      rondeVanVlaanderenWins: 1,
      liegeBastogneLiegeWins: 2,
      ilLombardiaWins: 4,
      worldChampionshipRoadWins: 1,
      daysInYellowJersey: 35,
      daysInPinkJersey: 20,
      pointsClassificationsWon: 1,
      komClassificationsWon: 2,
      youthClassificationsWon: 4,
      otherWorldTourWins: 15,
      totalCareerVictories: 88,
    );

    // 4. Mark Cavendish (Rekordzista etapów GT)
    _riderPalmaresMap['cavendish_legend'] = const RiderPalmares(
      riderId: 'cavendish_legend',
      riderName: 'Mark Cavendish',
      nationalityIso: 'GBR',
      grandTourStageWins: 55,
      tourDeFranceStageWins: 35, // Rekord wszech czasów Tour de France
      giroStageWins: 17,
      vueltaStageWins: 3,
      monumentWins: 1,
      milanoSanRemoWins: 1,
      worldChampionshipRoadWins: 1,
      daysInYellowJersey: 1,
      daysInPinkJersey: 4,
      pointsClassificationsWon: 4,
      totalCareerVictories: 165,
    );

    // 5. Marco Pantani (Pirata)
    _riderPalmaresMap['pantani_legend'] = const RiderPalmares(
      riderId: 'pantani_legend',
      riderName: 'Marco Pantani',
      nationalityIso: 'ITA',
      grandTourOverallWins: 2,
      tourDeFranceGcWins: 1,
      giroDItaliaGcWins: 1,
      grandTourStageWins: 16,
      tourDeFranceStageWins: 8,
      giroStageWins: 8,
      daysInYellowJersey: 7,
      daysInPinkJersey: 14,
      komClassificationsWon: 1,
      youthClassificationsWon: 2,
      totalCareerVictories: 46,
    );
  }

  // --- SERIALIZACJA I DESERIALIZACJA CAŁEGO SERWISU ---

  Map<String, dynamic> toJson() => {
        'riderPalmares':
            _riderPalmaresMap.map((k, v) => MapEntry(k, v.toJson())),
        'climbRecords':
            _climbRecordsMap.map((k, v) => MapEntry(k, v.toJson())),
        'seasonArchives': _seasonArchives.map((a) => a.toJson()).toList(),
      };

  factory HistoricalRecordsAndPalmaresService.fromJson(
      Map<String, dynamic> json) {
    final palmaresMap = <String, RiderPalmares>{};
    final rawPalmares = json['riderPalmares'] as Map<String, dynamic>? ?? {};
    rawPalmares.forEach((k, v) {
      palmaresMap[k] = RiderPalmares.fromJson(v as Map<String, dynamic>);
    });

    final climbsMap = <String, ClimbKomRecord>{};
    final rawClimbs = json['climbRecords'] as Map<String, dynamic>? ?? {};
    rawClimbs.forEach((k, v) {
      climbsMap[k] = ClimbKomRecord.fromJson(v as Map<String, dynamic>);
    });

    final archivesList = <RaceSeasonArchiveRecord>[];
    final rawArchives = json['seasonArchives'] as List<dynamic>? ?? [];
    for (final item in rawArchives) {
      archivesList
          .add(RaceSeasonArchiveRecord.fromJson(item as Map<String, dynamic>));
    }

    return HistoricalRecordsAndPalmaresService(
      riderPalmares: palmaresMap,
      climbRecords: climbsMap,
      seasonArchives: archivesList,
    );
  }
}
