import 'dart:math' as math;
import '../../core/constants/physics_constants.dart';
import '../../core/utils/formatters.dart';
import '../../models/race/race_stage.dart';
import '../../models/race/stage_segment.dart';
import '../../models/rider/rider.dart';
import '../../models/team/cycling_team.dart';
import '../physics/aero_calculator.dart';
import '../physics/speed_solver.dart';
import '../physics/w_prime_balance_engine.dart';

/// Typ próby czasowej (jazda na czas).
enum TimeTrialType {
  /// Jazda indywidualna na czas (Individual Time Trial - ITT)
  itt,

  /// Jazda drużynowa na czas (Team Time Trial - TTT)
  ttt;

  String get label {
    switch (this) {
      case TimeTrialType.itt:
        return 'Jazda Indywidualna na Czas (ITT)';
      case TimeTrialType.ttt:
        return 'Jazda Drużynowa na Czas (TTT)';
    }
  }

  bool get isTeam => this == TimeTrialType.ttt;

  String toJson() => name;

  static TimeTrialType fromJson(String value) {
    return TimeTrialType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TimeTrialType.itt,
    );
  }
}

/// Strategia rozłożenia sił na trasie czasówki (Pacing Strategy).
enum PacingStrategy {
  /// Oszczędna / Rezerwa (90-94% FTP):
  /// Bezpieczna jazda poniżej progu tlenowego, minimalne zużycie W',
  /// zapobiega odcięciu sił na trudnych finałach lub silnym wietrze.
  conservative,

  /// Równomierne tempo (100-103% FTP):
  /// Fizjologicznie najbardziej efektywny styl jazdy na czas (even pacing).
  /// Kontrolowany wydatek energii tlenowej i beztlenowej.
  balanced,

  /// Negatywny split (95% FTP w pierwszej połowie, 108% FTP w drugiej połowie):
  /// Taktyka mistrzów świata – oszczędność na początku i potężny finisz.
  negativeSplit,

  /// Agresywna (108-112% FTP):
  /// Wysokie tempo powyżej progu, walka o etap kosztem głębokiego drenażu W'.
  aggressive,

  /// Pełen ogień / All-Out (120-125% FTP):
  /// Maksymalna moc od rampy startowej. Ryzyko odcięcia beztlenowego ("bomba")
  /// i katastrofalnego załamania tempa przed metą.
  allOut,

  /// Własna moc zadana przez gracza w watach [W].
  custom;

  String get label {
    switch (this) {
      case PacingStrategy.conservative:
        return 'Oszczędna (92% FTP)';
      case PacingStrategy.balanced:
        return 'Równomierne tempo (101% FTP)';
      case PacingStrategy.negativeSplit:
        return 'Negatywny Split (95% ➔ 108% FTP)';
      case PacingStrategy.aggressive:
        return 'Agresywna (110% FTP)';
      case PacingStrategy.allOut:
        return 'Pełen ogień / All-Out (122% FTP)';
      case PacingStrategy.custom:
        return 'Własna moc (W)';
    }
  }

  String get shortLabel {
    switch (this) {
      case PacingStrategy.conservative:
        return 'Oszczędna';
      case PacingStrategy.balanced:
        return 'Równomierna';
      case PacingStrategy.negativeSplit:
        return 'Negatywny split';
      case PacingStrategy.aggressive:
        return 'Agresywna';
      case PacingStrategy.allOut:
        return 'All-Out 💥';
      case PacingStrategy.custom:
        return 'Własna moc';
    }
  }

  String get description {
    switch (this) {
      case PacingStrategy.conservative:
        return 'Jazda z rezerwą poniżej FTP. Brak ryzyka odcięcia beztlenowego.';
      case PacingStrategy.balanced:
        return 'Optymalne, stabilne tempo na granicy progu mleczanowego.';
      case PacingStrategy.negativeSplit:
        return 'Spokojniejszy początek, maksymalne przyspieszenie w drugiej części trasy.';
      case PacingStrategy.aggressive:
        return 'Mocne tempo powyżej FTP, eksploatuje rezerwy beztlenowe W\'.';
      case PacingStrategy.allOut:
        return 'Maksymalny atak od rampy. Jeśli W\' spadnie do 0, nastąpi drastyczne załamanie!';
      case PacingStrategy.custom:
        return 'Ściśle określona moc w watach ustawiona przez dyrektora sportowego.';
    }
  }

  /// Wylicza docelowy współczynnik mocy względem FTP w zależności od postępu trasy.
  double getTargetFtpRatio({required double progressFraction}) {
    final double safeProgress = progressFraction.clamp(0.0, 1.0);
    switch (this) {
      case PacingStrategy.conservative:
        return 0.92;
      case PacingStrategy.balanced:
        return 1.01;
      case PacingStrategy.negativeSplit:
        if (safeProgress < 0.50) {
          // Pierwsza połowa: 95% FTP
          return 0.95;
        } else {
          // Druga połowa: progresywnie od 104% do 110% FTP
          final double secondHalfProgress = (safeProgress - 0.50) * 2.0;
          return 1.04 + (0.06 * secondHalfProgress);
        }
      case PacingStrategy.aggressive:
        return 1.10;
      case PacingStrategy.allOut:
        return 1.22;
      case PacingStrategy.custom:
        return 1.00;
    }
  }

  String toJson() => name;

  static PacingStrategy fromJson(String value) {
    return PacingStrategy.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => PacingStrategy.balanced,
    );
  }
}

/// Długość zmiany w pociągu jazdy drużynowej na czas (TTT).
enum TttTurnDuration {
  /// Krótkie zmiany (15 sekund):
  /// Bardzo wysokie tempo, mniejszy drenaż W' na zmianie, dynamiczna praca.
  short15s,

  /// Standardowe zmiany (20 sekund):
  /// Klasyczna rotacja WorldTour, optymalny bilans prędkości i regeneracji.
  standard20s,

  /// Długie zmiany (30 sekund):
  /// Dla drużyn z dominującymi potężnymi motorami czasowymi (rouleurs).
  /// Może zajechać lżejszych górali.
  long30s;

  int get seconds {
    switch (this) {
      case TttTurnDuration.short15s:
        return 15;
      case TttTurnDuration.standard20s:
        return 20;
      case TttTurnDuration.long30s:
        return 30;
    }
  }

  String get label {
    switch (this) {
      case TttTurnDuration.short15s:
        return 'Krótkie (15 sek)';
      case TttTurnDuration.standard20s:
        return 'Standardowe (20 sek)';
      case TttTurnDuration.long30s:
        return 'Długie (30 sek)';
    }
  }

  String toJson() => name;

  static TttTurnDuration fromJson(String value) {
    return TttTurnDuration.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TttTurnDuration.standard20s,
    );
  }
}

/// Punkt pomiaru czasu na trasie czasówki (Intermediate Split / Finish).
class TimeTrialCheckpoint {
  final int index;
  final String name;
  final double distanceKm;
  final double elevationM;
  final bool isFinish;

  const TimeTrialCheckpoint({
    required this.index,
    required this.name,
    required this.distanceKm,
    required this.elevationM,
    this.isFinish = false,
  });

  Map<String, dynamic> toJson() => {
        'index': index,
        'name': name,
        'distanceKm': distanceKm,
        'elevationM': elevationM,
        'isFinish': isFinish,
      };

  factory TimeTrialCheckpoint.fromJson(Map<String, dynamic> json) {
    return TimeTrialCheckpoint(
      index: (json['index'] as num).toInt(),
      name: json['name'] as String,
      distanceKm: (json['distanceKm'] as num).toDouble(),
      elevationM: (json['elevationM'] as num).toDouble(),
      isFinish: json['isFinish'] as bool? ?? false,
    );
  }

  @override
  String toString() => '$name [${distanceKm.toStringAsFixed(1)} km]';
}

/// Zapis osiągniętego wyniku na danym punkcie pomiaru czasu (Split).
class TimeTrialSplitRecord {
  final int checkpointIndex;
  final String checkpointName;
  final double distanceKm;

  /// Czas netto kolarza / drużyny od startu do tego punktu [s]
  final double splitElapsedTimeSeconds;

  /// Pozycja na tym punkcie pomiaru czasu (1, 2, 3...)
  final int splitRank;

  /// Różnica czasowa do lidera na tym punkcie [s]
  final double gapToBestSplitSeconds;

  /// Średnia moc kolarza do tego punktu [W]
  final double averageWattsSoFar;

  /// Średnia prędkość do tego punktu [km/h]
  final double averageSpeedKmhSoFar;

  /// Pozostały zapas pracy beztlenowej W' [J]
  final double remainingWPrimeJoules;

  /// Procentowy poziom baterii beztlenowej W' (0-100%)
  final double wPrimePercentage;

  /// Czy kolarz na tym punkcie doznał odcięcia beztlenowego
  final bool isExhausted;

  const TimeTrialSplitRecord({
    required this.checkpointIndex,
    required this.checkpointName,
    required this.distanceKm,
    required this.splitElapsedTimeSeconds,
    required this.splitRank,
    required this.gapToBestSplitSeconds,
    required this.averageWattsSoFar,
    required this.averageSpeedKmhSoFar,
    required this.remainingWPrimeJoules,
    required this.wPrimePercentage,
    required this.isExhausted,
  });

  String get formattedTime => Formatters.formatRaceTime(
        splitElapsedTimeSeconds,
        showHoursAlways: false,
      );

  String get formattedGap => splitRank == 1
      ? 'Najlepszy czas'
      : Formatters.formatTimeGap(gapToBestSplitSeconds);

  Map<String, dynamic> toJson() => {
        'checkpointIndex': checkpointIndex,
        'checkpointName': checkpointName,
        'distanceKm': distanceKm,
        'splitElapsedTimeSeconds': splitElapsedTimeSeconds,
        'splitRank': splitRank,
        'gapToBestSplitSeconds': gapToBestSplitSeconds,
        'averageWattsSoFar': averageWattsSoFar,
        'averageSpeedKmhSoFar': averageSpeedKmhSoFar,
        'remainingWPrimeJoules': remainingWPrimeJoules,
        'wPrimePercentage': wPrimePercentage,
        'isExhausted': isExhausted,
      };

  factory TimeTrialSplitRecord.fromJson(Map<String, dynamic> json) {
    return TimeTrialSplitRecord(
      checkpointIndex: (json['checkpointIndex'] as num).toInt(),
      checkpointName: json['checkpointName'] as String,
      distanceKm: (json['distanceKm'] as num).toDouble(),
      splitElapsedTimeSeconds:
          (json['splitElapsedTimeSeconds'] as num).toDouble(),
      splitRank: (json['splitRank'] as num).toInt(),
      gapToBestSplitSeconds: (json['gapToBestSplitSeconds'] as num).toDouble(),
      averageWattsSoFar: (json['averageWattsSoFar'] as num).toDouble(),
      averageSpeedKmhSoFar: (json['averageSpeedKmhSoFar'] as num).toDouble(),
      remainingWPrimeJoules:
          (json['remainingWPrimeJoules'] as num).toDouble(),
      wPrimePercentage: (json['wPrimePercentage'] as num).toDouble(),
      isExhausted: json['isExhausted'] as bool? ?? false,
    );
  }
}

/// Stan symulacji pojedynczego kolarza w próbie czasowej (krok po kroku).
class IttRiderSimulationState {
  final Rider rider;
  final String teamId;
  final String teamName;

  /// Opóźnienie startu z rampy startowej w sekundach [s]
  final double startDelaySeconds;

  bool hasStarted;
  bool hasFinished;

  /// Przebyty dystans na trasie w metrach [m]
  double distanceTraveledMeters;

  double get distanceTraveledKm => distanceTraveledMeters / 1000.0;

  /// Czas jazdy netto od zjechania z rampy startowej [s]
  double elapsedRideSeconds;

  /// Aktualna prędkość kolarza w metrach na sekundę [m/s]
  double currentSpeedMs;

  double get currentSpeedKmh => currentSpeedMs * 3.6;

  /// Aktualnie generowana moc mechaniczna [W]
  double currentWatts;

  /// Łączna praca wykonana przez kolarza [J]
  double totalWorkJoules;

  /// Stan naładowania baterii beztlenowej (W' Balance wg Skiby)
  WPrimeState wPrimeState;

  /// Pozostały glikogen w mięśniach i wątrobie [g]
  double glycogenGrams;

  /// Strategia rozłożenia sił
  PacingStrategy pacingStrategy;

  /// Własna zadana moc w watach [W] (gdy wybrano [PacingStrategy.custom])
  int? customWatts;

  /// Zarejestrowane punkty pomiaru czasu kolarza
  final List<TimeTrialSplitRecord> splits;

  /// Czy kolarz złapał "odcięcie beztlenowe" (W' spadło do 0, załamanie tempa)
  bool isBlownUp;

  /// Kilometr trasy, na którym doszło do odcięcia beztlenowego
  double? blowUpKm;

  /// Maksymalna osiągnięta prędkość [km/h]
  double maxSpeedKmh;

  /// Oficjalny czas netto po przekroczeniu mety [s]
  double? finalFinishTimeSeconds;

  IttRiderSimulationState({
    required this.rider,
    required this.teamId,
    required this.teamName,
    required this.startDelaySeconds,
    this.hasStarted = false,
    this.hasFinished = false,
    this.distanceTraveledMeters = 0.0,
    this.elapsedRideSeconds = 0.0,
    this.currentSpeedMs = 0.0,
    this.currentWatts = 0.0,
    this.totalWorkJoules = 0.0,
    required this.wPrimeState,
    required this.glycogenGrams,
    this.pacingStrategy = PacingStrategy.balanced,
    this.customWatts,
    List<TimeTrialSplitRecord>? splits,
    this.isBlownUp = false,
    this.blowUpKm,
    this.maxSpeedKmh = 0.0,
    this.finalFinishTimeSeconds,
  }) : splits = splits ?? [];

  double get averageWatts =>
      elapsedRideSeconds > 0 ? totalWorkJoules / elapsedRideSeconds : 0.0;

  double get averageSpeedKmh => elapsedRideSeconds > 0
      ? (distanceTraveledKm / (elapsedRideSeconds / 3600.0))
      : 0.0;
}

/// Stan kolarza w pociągu jazdy drużynowej na czas (TTT).
class TttRiderInTrainState {
  final IttRiderSimulationState riderState;

  /// Czy kolarz nie wytrzymał tempa i odpadł z pociągu
  bool isDropped;

  /// Kilometr trasy, na którym kolarz odpadł z pociągu
  double? droppedAtKm;

  /// Aktualny współczynnik redukcji oporu powietrza (0.0 na czele, ~0.40 za kołem)
  double currentDraftingReduction;

  TttRiderInTrainState({
    required this.riderState,
    this.isDropped = false,
    this.droppedAtKm,
    this.currentDraftingReduction = 0.0,
  });

  String get riderName => riderState.rider.fullName;
  String get riderId => riderState.rider.id;
}

/// Stan symulacji drużyny w jeździe drużynowej na czas (TTT).
class TttTeamSimulationState {
  final CyclingTeam team;
  final double startDelaySeconds;
  bool hasStarted;
  bool hasFinished;

  /// Dystans pociągu drużyny w metrach [m]
  double distanceTraveledMeters;

  double get distanceTraveledKm => distanceTraveledMeters / 1000.0;

  /// Czas jazdy netto czoła pociągu drużyny [s]
  double teamElapsedSeconds;

  /// Konfiguracja długości zmian
  TttTurnDuration turnDuration;

  /// Skład pociągu drużyny (6-8 kolarzy)
  final List<TttRiderInTrainState> trainRiders;

  /// Indeks aktualnie dającego zmianę na czele wśród kolarzy aktywnych
  int currentPullerIndex;

  /// Czas trwania aktualnej zmiany w sekundach [s]
  double currentTurnElapsedSeconds;

  /// Punkty pomiaru czasu drużyny
  final List<TimeTrialSplitRecord> teamSplits;

  /// Liczba kolarzy, którzy fizycznie dotarli do mety
  int finishersCount;

  /// Oficjalny czas drużyny na mecie (wg regulaminu UCI: czas 4. kolarza!)
  double? officialFourthRiderFinishTimeSeconds;

  /// Maksymalna prędkość pociągu [km/h]
  double maxSpeedKmh;

  TttTeamSimulationState({
    required this.team,
    required this.startDelaySeconds,
    this.hasStarted = false,
    this.hasFinished = false,
    this.distanceTraveledMeters = 0.0,
    this.teamElapsedSeconds = 0.0,
    this.turnDuration = TttTurnDuration.standard20s,
    required this.trainRiders,
    this.currentPullerIndex = 0,
    this.currentTurnElapsedSeconds = 0.0,
    List<TimeTrialSplitRecord>? teamSplits,
    this.finishersCount = 0,
    this.officialFourthRiderFinishTimeSeconds,
    this.maxSpeedKmh = 0.0,
  }) : teamSplits = teamSplits ?? [];

  List<TttRiderInTrainState> get activeRiders =>
      trainRiders.where((r) => !r.isDropped).toList();

  List<TttRiderInTrainState> get droppedRiders =>
      trainRiders.where((r) => r.isDropped).toList();

  TttRiderInTrainState? get currentPuller {
    final active = activeRiders;
    if (active.isEmpty) return null;
    return active[currentPullerIndex % active.length];
  }
}

/// Oficjalny wynik pojedynczego kolarza w jeździe indywidualnej na czas (ITT).
class IttRiderResult {
  final String riderId;
  final String riderName;
  final String teamId;
  final String teamName;
  final int rank;
  final double finishTimeSeconds;
  final double gapToWinnerSeconds;
  final double averageWatts;
  final double averageSpeedKmh;
  final double maxSpeedKmh;
  final double remainingWPrimePercentage;
  final bool isBlownUp;
  final double? blowUpKm;
  final List<TimeTrialSplitRecord> splits;
  final PacingStrategy pacingStrategy;

  const IttRiderResult({
    required this.riderId,
    required this.riderName,
    required this.teamId,
    required this.teamName,
    required this.rank,
    required this.finishTimeSeconds,
    required this.gapToWinnerSeconds,
    required this.averageWatts,
    required this.averageSpeedKmh,
    required this.maxSpeedKmh,
    required this.remainingWPrimePercentage,
    required this.isBlownUp,
    this.blowUpKm,
    required this.splits,
    required this.pacingStrategy,
  });

  String get formattedTime => Formatters.formatRaceTime(
        finishTimeSeconds,
        showHoursAlways: false,
      );

  String get formattedGap =>
      rank == 1 ? 'Zwycięzca' : Formatters.formatTimeGap(gapToWinnerSeconds);

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'riderName': riderName,
        'teamId': teamId,
        'teamName': teamName,
        'rank': rank,
        'finishTimeSeconds': finishTimeSeconds,
        'gapToWinnerSeconds': gapToWinnerSeconds,
        'averageWatts': averageWatts,
        'averageSpeedKmh': averageSpeedKmh,
        'maxSpeedKmh': maxSpeedKmh,
        'remainingWPrimePercentage': remainingWPrimePercentage,
        'isBlownUp': isBlownUp,
        'blowUpKm': blowUpKm,
        'splits': splits.map((s) => s.toJson()).toList(),
        'pacingStrategy': pacingStrategy.toJson(),
      };
}

/// Oficjalny wynik drużyny w jeździe drużynowej na czas (TTT).
class TttTeamResult {
  final String teamId;
  final String teamName;
  final int rank;

  /// Oficjalny czas drużyny na mecie (czas 4. kolarza!)
  final double officialTimeSeconds;

  final double gapToWinnerSeconds;
  final double averageSpeedKmh;
  final int activeFinishersCount;
  final int droppedCount;
  final Map<String, double> individualFinishTimesSeconds;
  final List<String> droppedRiderNames;
  final List<TimeTrialSplitRecord> splits;
  final TttTurnDuration turnDuration;

  const TttTeamResult({
    required this.teamId,
    required this.teamName,
    required this.rank,
    required this.officialTimeSeconds,
    required this.gapToWinnerSeconds,
    required this.averageSpeedKmh,
    required this.activeFinishersCount,
    required this.droppedCount,
    required this.individualFinishTimesSeconds,
    required this.droppedRiderNames,
    required this.splits,
    required this.turnDuration,
  });

  String get formattedTime => Formatters.formatRaceTime(
        officialTimeSeconds,
        showHoursAlways: false,
      );

  String get formattedGap =>
      rank == 1 ? 'Zwycięzca' : Formatters.formatTimeGap(gapToWinnerSeconds);

  Map<String, dynamic> toJson() => {
        'teamId': teamId,
        'teamName': teamName,
        'rank': rank,
        'officialTimeSeconds': officialTimeSeconds,
        'gapToWinnerSeconds': gapToWinnerSeconds,
        'averageSpeedKmh': averageSpeedKmh,
        'activeFinishersCount': activeFinishersCount,
        'droppedCount': droppedCount,
        'individualFinishTimesSeconds': individualFinishTimesSeconds,
        'droppedRiderNames': droppedRiderNames,
        'splits': splits.map((s) => s.toJson()).toList(),
        'turnDuration': turnDuration.toJson(),
      };
}

/// Pełny raport z rozegranego etapu jazdy na czas (ITT lub TTT).
class TimeTrialStageResult {
  final String stageId;
  final String stageName;
  final TimeTrialType type;
  final double totalDistanceKm;
  final List<TimeTrialCheckpoint> checkpoints;
  final List<IttRiderResult> riderResults;
  final List<TttTeamResult> teamResults;
  final List<String> commentaryLog;

  const TimeTrialStageResult({
    required this.stageId,
    required this.stageName,
    required this.type,
    required this.totalDistanceKm,
    required this.checkpoints,
    required this.riderResults,
    required this.teamResults,
    required this.commentaryLog,
  });

  Map<String, dynamic> toJson() => {
        'stageId': stageId,
        'stageName': stageName,
        'type': type.toJson(),
        'totalDistanceKm': totalDistanceKm,
        'checkpoints': checkpoints.map((c) => c.toJson()).toList(),
        'riderResults': riderResults.map((r) => r.toJson()).toList(),
        'teamResults': teamResults.map((t) => t.toJson()).toList(),
        'commentaryLog': commentaryLog,
      };
}

/// Sesja symulacji ITT z możliwością wykonywania kroków czasowych (tick) w UI.
class IttSimulationSession {
  final RaceStage stage;
  final List<TimeTrialCheckpoint> checkpoints;
  final List<IttRiderSimulationState> riderStates;
  final Map<String, CyclingTeam> teamsMap;
  final List<String> commentaryLog;
  double globalElapsedSeconds;
  bool isCompleted;

  IttSimulationSession({
    required this.stage,
    required this.checkpoints,
    required this.riderStates,
    required this.teamsMap,
    this.commentaryLog = const [],
    this.globalElapsedSeconds = 0.0,
    this.isCompleted = false,
  });

  /// Zwraca listę kolarzy aktualnie znajdujących się na trasie
  List<IttRiderSimulationState> get activeRidersOnCourse =>
      riderStates.where((r) => r.hasStarted && !r.hasFinished).toList();

  /// Zwraca listę kolarzy, którzy ukończyli czasówkę
  List<IttRiderSimulationState> get finishedRiders =>
      riderStates.where((r) => r.hasFinished).toList();
}

/// Sesja symulacji TTT z możliwością wykonywania kroków czasowych (tick) w UI.
class TttSimulationSession {
  final RaceStage stage;
  final List<TimeTrialCheckpoint> checkpoints;
  final List<TttTeamSimulationState> teamStates;
  final List<String> commentaryLog;
  double globalElapsedSeconds;
  bool isCompleted;

  TttSimulationSession({
    required this.stage,
    required this.checkpoints,
    required this.teamStates,
    this.commentaryLog = const [],
    this.globalElapsedSeconds = 0.0,
    this.isCompleted = false,
  });

  List<TttTeamSimulationState> get activeTeamsOnCourse =>
      teamStates.where((t) => t.hasStarted && !t.hasFinished).toList();

  List<TttTeamSimulationState> get finishedTeams =>
      teamStates.where((t) => t.hasFinished).toList();
}

/// Dedykowany silnik symulacji jazdy indywidualnej (ITT) i drużynowej na czas (TTT).
///
/// Implementuje:
/// - Starty w interwałach czasowych (falowe wypuszczanie kolarzy / drużyn)
/// - Bezwzględny zakaz draftingu w ITT (brak redukcji oporu aerodynamicznego)
/// - Pacing Strategy: zarządzanie energią i W' Balance na punktach pomiaru czasu
/// - Ryzyko odcięcia beztlenowego ("bomba") przy zbyt agresywnym początku
/// - Formację pociągu na lemondkach w TTT z rotacją zmian (15-30s) i draftem za kołem
/// - Odpadanie wyczerpanych kolarzy z pociągu drużynowego
/// - Oficjalną regułę UCI liczenia czasu drużyny wg **4. kolarza na mecie**!
class TimeTrialSimulationEngine {
  TimeTrialSimulationEngine._();

  /// Domyślna masa roweru czasowego z bidonami i osprzętem aero [kg]
  static const double ttBikeMassKg = 8.4;

  /// Współczynnik oporu toczenia dla wzorcowego gładkiego asfaltu na czasówce
  static const double baseTtCrr = 0.0033;

  /// Domyślna redukcja oporu aero w pociągu czasowym dla kolarzy za kołem (50% w szyku TTT)
  static const double tttDraftingReductionFollower = 0.50;

  // ===========================================================================
  // 1. GENEROWANIE I EKSTRAKCJA PUNKTÓW POMIARU CZASU (CHECKPOINTS)
  // ===========================================================================

  /// Wyodrębnia lub generuje realistyczne punkty pomiaru czasu dla etapu czasówki.
  static List<TimeTrialCheckpoint> extractOrGenerateCheckpoints(RaceStage stage) {
    final double totalKm = stage.totalDistanceKm;
    final List<TimeTrialCheckpoint> checkpoints = [];

    // Sprawdź czy segmenty mają zdefiniowane punkty pomiarowe
    final sprintSegments = stage.segments
        .where((s) => s.sprintOrKomClassification == SegmentClassification.intermediateSprint)
        .toList();

    if (sprintSegments.isNotEmpty) {
      int idx = 1;
      for (final seg in sprintSegments) {
        final double dist = seg.startKm + (seg.lengthKm * 0.5);
        if (dist > 1.5 && dist < totalKm - 1.5) {
          checkpoints.add(
            TimeTrialCheckpoint(
              index: idx,
              name: 'Pomiar Czasu $idx (${dist.toStringAsFixed(1)} km)',
              distanceKm: dist,
              elevationM: seg.startElevationM,
            ),
          );
          idx++;
        }
      }
    }

    // Jeśli etap nie miał predefiniowanych punktów, wygeneruj je wg standardu UCI
    if (checkpoints.isEmpty) {
      if (totalKm <= 12.0) {
        // Prolog / krótka czasówka: 1 punkt pomiaru w połowie
        final double p1 = totalKm * 0.50;
        checkpoints.add(
          TimeTrialCheckpoint(
            index: 1,
            name: 'Pomiar Czasu 1 (${p1.toStringAsFixed(1)} km)',
            distanceKm: p1,
            elevationM: _getElevationAtKm(stage, p1),
          ),
        );
      } else if (totalKm <= 26.0) {
        // Średnia czasówka: 2 punkty pomiaru czasu (~35% i ~70%)
        final double p1 = totalKm * 0.35;
        final double p2 = totalKm * 0.70;
        checkpoints.add(
          TimeTrialCheckpoint(
            index: 1,
            name: 'Pomiar Czasu 1 (${p1.toStringAsFixed(1)} km)',
            distanceKm: p1,
            elevationM: _getElevationAtKm(stage, p1),
          ),
        );
        checkpoints.add(
          TimeTrialCheckpoint(
            index: 2,
            name: 'Pomiar Czasu 2 (${p2.toStringAsFixed(1)} km)',
            distanceKm: p2,
            elevationM: _getElevationAtKm(stage, p2),
          ),
        );
      } else {
        // Długa czasówka (>26 km): 3 punkty pomiaru czasu (~25%, ~52%, ~78%)
        final double p1 = totalKm * 0.25;
        final double p2 = totalKm * 0.52;
        final double p3 = totalKm * 0.78;
        checkpoints.add(
          TimeTrialCheckpoint(
            index: 1,
            name: 'Pomiar Czasu 1 (${p1.toStringAsFixed(1)} km)',
            distanceKm: p1,
            elevationM: _getElevationAtKm(stage, p1),
          ),
        );
        checkpoints.add(
          TimeTrialCheckpoint(
            index: 2,
            name: 'Pomiar Czasu 2 (${p2.toStringAsFixed(1)} km)',
            distanceKm: p2,
            elevationM: _getElevationAtKm(stage, p2),
          ),
        );
        checkpoints.add(
          TimeTrialCheckpoint(
            index: 3,
            name: 'Pomiar Czasu 3 (${p3.toStringAsFixed(1)} km)',
            distanceKm: p3,
            elevationM: _getElevationAtKm(stage, p3),
          ),
        );
      }
    }

    // Zawsze dodaj oficjalną linię mety jako finałowy punkt pomiaru
    checkpoints.add(
      TimeTrialCheckpoint(
        index: checkpoints.length + 1,
        name: 'Meta (${totalKm.toStringAsFixed(1)} km)',
        distanceKm: totalKm,
        elevationM: stage.segments.isNotEmpty
            ? stage.segments.last.endElevationM
            : 100.0,
        isFinish: true,
      ),
    );

    return checkpoints;
  }

  static double _getElevationAtKm(RaceStage stage, double targetKm) {
    if (stage.segments.isEmpty) return 100.0;
    for (final seg in stage.segments) {
      if (targetKm >= seg.startKm && targetKm <= seg.startKm + seg.lengthKm) {
        final double frac = (seg.lengthKm > 0)
            ? (targetKm - seg.startKm) / seg.lengthKm
            : 0.0;
        return seg.startElevationM +
            (seg.endElevationM - seg.startElevationM) * frac;
      }
    }
    return stage.segments.last.endElevationM;
  }

  // ===========================================================================
  // 2. FIZYKA AERODYNAMICZNA I ZARZĄDZANIE MOCĄ (PACING STRATEGY)
  // ===========================================================================

  /// Oblicza efektywne CdA kolarza w pozycji czasowej (na lemondce).
  ///
  /// W ITT drafting wynosi bezwzględnie 0.0.
  /// W TTT kolarz na czele ma 0.0, a kolarze za nim mają ~0.40 redukcji.
  static double calculateRiderEffectiveCdA(
    Rider rider, {
    double draftingReduction = 0.0,
    double yawAngleRadians = 0.0,
  }) {
    final double bsa = rider.physiology.bodySurfaceAreaM2;
    final double frontalArea =
        bsa > 0.0 ? bsa * 0.268 : AeroCalculator.referenceFrontalAreaM2;

    // Umiejętności czasowe kolarza modyfikują jakość pozycji na lemondce
    final double aeroSkillMod = rider.skills.cdaModifier;
    final double ttSkillMod = 1.0 -
        ((rider.skills.timeTrialPositioning - 50) / 100.0) * 0.12;

    // Rower czasowy z dyskiem i profilem TT daje bonus aero (-0.018 m²)
    final double baseCda = AeroCalculator.calculateEffectiveCdA(
      riderFrontalAreaM2: frontalArea,
      position: RiderPosition.timeTrial,
      bikeCdaModifier: -0.018,
      draftingReduction: draftingReduction,
      yawAngleRadians: yawAngleRadians,
    );

    final double effectiveCda = baseCda * aeroSkillMod * ttSkillMod;
    return effectiveCda.clamp(0.165, 0.310);
  }

  /// Oblicza docelową moc kolarza w watach na podstawie wybranej strategii tempa (Pacing Strategy),
  /// zoptymalizowaną pod profil wysokościowy (dodatkowa moc pod górę, oszczędność na zjazdach).
  static double calculateTargetWatts(
    Rider rider,
    PacingStrategy strategy, {
    int? customWatts,
    double progressFraction = 0.0,
    double gradientPercent = 0.0,
  }) {
    final double ftp = rider.physiology.ftpWatts > 0
        ? rider.physiology.ftpWatts.toDouble()
        : 380.0;

    double basePower;
    if (strategy == PacingStrategy.custom && customWatts != null && customWatts > 0) {
      basePower = customWatts.toDouble();
    } else {
      final double ftpRatio = strategy.getTargetFtpRatio(progressFraction: progressFraction);
      basePower = ftp * ftpRatio;
    }

    // Teoremat optymalnego rozłożenia sił w kolarstwie (Optimal Pacing):
    // Zwiększenie mocy na wolnych odcinkach pod górę daje znacznie większy zysk czasowy
    // niż przepalanie watów na szybkich zjazdach przy dominującym oporze aero.
    double gradientMultiplier = 1.0;
    if (gradientPercent > 1.5) {
      // Podjazd: +4% do +15% mocy w zależności od stromości
      final double steepBonus = (gradientPercent / 100.0) * 1.5;
      gradientMultiplier = 1.0 + math.min(0.16, steepBonus);
    } else if (gradientPercent < -2.0) {
      // Zjazd: odpuszczenie mocy o 10% do 25%, aerodynamika wykonuje pracę
      final double easeRatio = (gradientPercent.abs() / 100.0) * 1.2;
      gradientMultiplier = math.max(0.70, 1.0 - easeRatio);
    }

    return basePower * gradientMultiplier;
  }

  /// Wyznacza współczynnik oporów toczenia dla danego segmentu.
  static double calculateSegmentCrr(StageSegment segment) {
    switch (segment.surfaceType) {
      case SegmentSurfaceType.smoothAsphalt:
        return 0.0031;
      case SegmentSurfaceType.concrete:
        return 0.0042;
      case SegmentSurfaceType.roughAsphalt:
        return 0.0058;
      case SegmentSurfaceType.cobblestonesSector1:
      case SegmentSurfaceType.cobblestonesSector2:
      case SegmentSurfaceType.cobblestonesSector3:
      case SegmentSurfaceType.cobblestonesSector4:
      case SegmentSurfaceType.cobblestonesSector5:
        return 0.0110;
      case SegmentSurfaceType.gravelStrade:
        return 0.0080;
    }
  }

  // ===========================================================================
  // 3. SYMULACJA JAZDY INDYWIDUALNEJ NA CZAS (ITT) - TRYB PEŁNY (BATCH)
  // ===========================================================================

  /// Przeprowadza pełną symulację etapu jazdy indywidualnej na czas (ITT).
  ///
  /// Kolarze startują pojedynczo w odstępach czasowych ([startIntervalSeconds]),
  /// drafting jest całkowicie zablokowany, a zużycie W' determinuje ewentualne
  /// odcięcie beztlenowe ("bomba").
  static TimeTrialStageResult simulateIttStage({
    required RaceStage stage,
    required List<Rider> riders,
    required Map<String, CyclingTeam> teamsMap,
    Map<String, PacingStrategy>? customPacing,
    Map<String, int>? customWatts,
    double startIntervalSeconds = 60.0,
    double lateContendersStartIntervalSeconds = 120.0,
  }) {
    final checkpoints = extractOrGenerateCheckpoints(stage);
    final List<String> commentary = [];

    // 1. Ustalenie kolejności startowej (odwrotna kolejność do GC lub według OVR)
    // Słabsi zawodnicy startują na początku, najlepsi czasowcy i liderzy GC na końcu
    final sortedRiders = List<Rider>.from(riders)
      ..sort((a, b) => a.overallRating.compareTo(b.overallRating));

    final totalRiders = sortedRiders.length;
    final List<IttRiderSimulationState> riderStates = [];

    double currentStartDelay = 0.0;
    for (int i = 0; i < totalRiders; i++) {
      final rider = sortedRiders[i];
      final team = teamsMap[rider.contract.teamId] ??
          teamsMap.values.firstWhere(
            (t) => t.rosterRiderIds.contains(rider.id),
            orElse: () => teamsMap.values.first,
          );

      // Ostatnich 15 faworytów startuje w odstępach 2-minutowych (standard UCI)
      final bool isLateContender = (totalRiders - i) <= 15;
      final double interval = isLateContender
          ? lateContendersStartIntervalSeconds
          : startIntervalSeconds;

      final strategy = customPacing?[rider.id] ?? PacingStrategy.balanced;
      final customW = customWatts?[rider.id];

      riderStates.add(
        IttRiderSimulationState(
          rider: rider,
          teamId: team.id,
          teamName: team.name,
          startDelaySeconds: currentStartDelay,
          wPrimeState: WPrimeState.initial(rider.physiology),
          glycogenGrams: rider.physiology.glycogenCapacityGrams > 0
              ? rider.physiology.glycogenCapacityGrams
              : 450.0,
          pacingStrategy: strategy,
          customWatts: customW,
        ),
      );

      currentStartDelay += interval;
    }

    commentary.add(
      'Rozpoczyna się ${stage.name} (ITT) na dystansie ${stage.totalDistanceKm.toStringAsFixed(1)} km! '
      'Wystartuje ${sortedRiders.length} kolarzy. Drafting jest ściśle zakazany.',
    );

    // 2. Przeprowadzenie symulacji fizycznej dla każdego kolarza
    // Każdy kolarz jedzie niezależnie w kanale czasowym bez draftingu
    for (final state in riderStates) {
      _simulateSingleRiderItt(
        state: state,
        stage: stage,
        checkpoints: checkpoints,
        commentary: commentary,
      );
    }

    // 3. Przeliczenie rankingów i strat na punktach pomiaru czasu (Splits)
    for (int c = 0; c < checkpoints.length; c++) {
      _recalculateSplitLeaderboard(riderStates, c);
    }

    // 4. Posortowanie wyników końcowych na mecie
    final List<IttRiderSimulationState> finishedStates =
        riderStates.where((s) => s.hasFinished).toList()
          ..sort((a, b) => (a.finalFinishTimeSeconds ?? double.infinity)
              .compareTo(b.finalFinishTimeSeconds ?? double.infinity));

    final double winnerTime = finishedStates.isNotEmpty
        ? (finishedStates.first.finalFinishTimeSeconds ?? 0.0)
        : 0.0;

    final List<IttRiderResult> officialResults = [];
    for (int rank = 1; rank <= finishedStates.length; rank++) {
      final s = finishedStates[rank - 1];
      final double finishTime = s.finalFinishTimeSeconds ?? 0.0;
      final double gap = finishTime - winnerTime;

      officialResults.add(
        IttRiderResult(
          riderId: s.rider.id,
          riderName: s.rider.fullName,
          teamId: s.teamId,
          teamName: s.teamName,
          rank: rank,
          finishTimeSeconds: finishTime,
          gapToWinnerSeconds: math.max(0.0, gap),
          averageWatts: s.averageWatts,
          averageSpeedKmh: s.averageSpeedKmh,
          maxSpeedKmh: s.maxSpeedKmh,
          remainingWPrimePercentage: s.wPrimeState.wPrimePercentage,
          isBlownUp: s.isBlownUp,
          blowUpKm: s.blowUpKm,
          splits: List<TimeTrialSplitRecord>.from(s.splits),
          pacingStrategy: s.pacingStrategy,
        ),
      );
    }

    if (officialResults.isNotEmpty) {
      final winner = officialResults.first;
      commentary.add(
        '🏆 Zwycięzcą ${stage.name} zostaje ${winner.riderName} (${winner.teamName}) '
        'z fenomenalnym czasem ${winner.formattedTime} (śr. ${winner.averageSpeedKmh.toStringAsFixed(1)} km/h)!',
      );
    }

    return TimeTrialStageResult(
      stageId: stage.id,
      stageName: stage.name,
      type: TimeTrialType.itt,
      totalDistanceKm: stage.totalDistanceKm,
      checkpoints: checkpoints,
      riderResults: officialResults,
      teamResults: const [],
      commentaryLog: commentary,
    );
  }

  /// Symuluje przejazd pojedynczego kolarza w ITT od rampy do mety.
  static void _simulateSingleRiderItt({
    required IttRiderSimulationState state,
    required RaceStage stage,
    required List<TimeTrialCheckpoint> checkpoints,
    required List<String> commentary,
  }) {
    state.hasStarted = true;
    final double totalMeters = stage.totalDistanceKm * 1000.0;
    const double dt = 2.0; // Stabilny 2-sekundowy krok całkowania dynamiki

    double currentSpeedMs = 5.0; // Prędkość po zjechaniu ze stromej rampy startowej
    int nextCheckpointIdx = 0;

    while (state.distanceTraveledMeters < totalMeters) {
      final double currentKm = state.distanceTraveledKm;
      final double progress = (state.distanceTraveledMeters / totalMeters).clamp(0.0, 1.0);

      // Znajdź bieżący segment profilu trasy
      final StageSegment currentSegment = _findSegmentAtKm(stage, currentKm);
      final double slopeGradient = currentSegment.gradientPercent / 100.0;
      final double crr = calculateSegmentCrr(currentSegment);

      // Kąt wiatru i aerodynamika
      final double relativeWindAngle = AeroCalculator.calculateRelativeWindAngle(
        windDirectionDegrees: currentSegment.windDirectionDegrees,
        roadBearingDegrees: currentSegment.roadBearingDegrees,
      );
      final double airDensity = AeroCalculator.calculateAirDensity(
        altitudeMeters: currentSegment.startElevationM,
        temperatureCelsius: stage.baseTemperatureCelsius,
      );

      // CdA na lemondce (drafting = 0.0 w ITT!)
      final double effectiveCdA = calculateRiderEffectiveCdA(
        state.rider,
        draftingReduction: 0.0,
        yawAngleRadians: relativeWindAngle * (math.pi / 180.0),
      );

      // Wyznacz planowaną moc wg strategii tempa
      final double targetWatts = calculateTargetWatts(
        state.rider,
        state.pacingStrategy,
        customWatts: state.customWatts,
        progressFraction: progress,
        gradientPercent: currentSegment.gradientPercent,
      );

      // Aktualizacja baterii beztlenowej W' Balance wg Skiby
      final WPrimeUpdateResult wUpdate = WPrimeBalanceEngine.update(
        state: state.wPrimeState,
        targetPowerWatts: targetWatts,
        physiology: state.rider.physiology,
        timeStepSeconds: dt,
      );

      state.wPrimeState = wUpdate.newState;
      double actualWatts = wUpdate.actualPowerWatts;

      // Wykrycie odcięcia beztlenowego ("bomba")
      if (wUpdate.wasPowerCapped || wUpdate.newState.isExhausted) {
        if (!state.isBlownUp) {
          state.isBlownUp = true;
          state.blowUpKm = currentKm;
          commentary.add(
            '⚠️ KRYZYS! ${state.rider.fullName} zapłacił za zbyt mocne tempo – '
            'całkowite odcięcie beztlenowe (bomba) na ${currentKm.toStringAsFixed(1)}. km!',
          );
        }
        // Przy odcięciu moc spada do 75-80% FTP
        final double capPower = state.rider.physiology.ftpWatts * 0.78;
        actualWatts = math.min(actualWatts, capPower);
      }

      state.currentWatts = actualWatts;
      state.totalWorkJoules += actualWatts * dt;

      // Rozwiązanie równania ruchu (SpeedSolver)
      final double totalMassKg = state.rider.physiology.weightKg + ttBikeMassKg;
      final speedResult = SpeedSolver.solveNextSecond(
        inputWatts: actualWatts,
        currentSpeedMs: currentSpeedMs,
        totalMassKg: totalMassKg,
        gradientFraction: slopeGradient,
        effectiveCdA: effectiveCdA,
        airDensityKgM3: airDensity,
        effectiveCrr: crr,
        windSpeedMs: stage.windSpeedKmh / 3.6,
        relativeWindAngleDegrees: relativeWindAngle,
        descendingSkill: state.rider.skills.descending,
        technicalDifficulty: currentSegment.technicalDifficulty,
        timeStepSeconds: dt,
      );

      currentSpeedMs = math.max(2.5, speedResult.newSpeedMs);
      state.currentSpeedMs = currentSpeedMs;
      state.maxSpeedKmh = math.max(state.maxSpeedKmh, currentSpeedMs * 3.6);

      state.distanceTraveledMeters += currentSpeedMs * dt;
      state.elapsedRideSeconds += dt;

      // Sprawdzenie przekroczenia punktów pomiaru czasu (Checkpoints)
      while (nextCheckpointIdx < checkpoints.length &&
          state.distanceTraveledKm >= checkpoints[nextCheckpointIdx].distanceKm) {
        final cp = checkpoints[nextCheckpointIdx];
        state.splits.add(
          TimeTrialSplitRecord(
            checkpointIndex: cp.index,
            checkpointName: cp.name,
            distanceKm: cp.distanceKm,
            splitElapsedTimeSeconds: state.elapsedRideSeconds,
            splitRank: 0, // Zostanie wyliczone w podsumowaniu
            gapToBestSplitSeconds: 0.0,
            averageWattsSoFar: state.averageWatts,
            averageSpeedKmhSoFar: state.averageSpeedKmh,
            remainingWPrimeJoules: state.wPrimeState.currentWPrimeJoules,
            wPrimePercentage: state.wPrimeState.wPrimePercentage,
            isExhausted: state.wPrimeState.isExhausted || state.isBlownUp,
          ),
        );
        nextCheckpointIdx++;
      }
    }

    state.hasFinished = true;
    state.finalFinishTimeSeconds = state.elapsedRideSeconds;
  }

  // ===========================================================================
  // 4. SYMULACJA JAZDY DRUŻYNOWEJ NA CZAS (TTT) - TRYB PEŁNY (BATCH)
  // ===========================================================================

  /// Przeprowadza pełną symulację etapu jazdy drużynowej na czas (TTT).
  ///
  /// Kolarze jednej drużyny (6-8 zawodników) jadą w zwartej formacji czasowej
  /// na lemondkach, dając zmiany po 15-30 sekund. Kolarz na czele przyjmuje
  /// 100% oporu powietrza, a kolarze za nim korzystają z tunelu aerodynamicznego (40% draft).
  ///
  /// Zgodnie z oficjalnym regulaminem UCI, czas drużyny liczony jest dla **4. zawodnika na mecie**!
  static TimeTrialStageResult simulateTttStage({
    required RaceStage stage,
    required List<CyclingTeam> teams,
    required Map<String, List<Rider>> teamRosters,
    Map<String, TttTurnDuration>? teamTurnDurations,
    double teamStartIntervalSeconds = 180.0,
  }) {
    final checkpoints = extractOrGenerateCheckpoints(stage);
    final List<String> commentary = [];

    final List<TttTeamSimulationState> teamStates = [];
    double currentTeamStartDelay = 0.0;

    for (final team in teams) {
      final roster = teamRosters[team.id] ?? [];
      if (roster.length < 4) continue; // Drużyna musi mieć co najmniej 4 kolarzy do TTT

      final turnDur = teamTurnDurations?[team.id] ?? TttTurnDuration.standard20s;

      final trainRiders = roster.map((rider) {
        return TttRiderInTrainState(
          riderState: IttRiderSimulationState(
            rider: rider,
            teamId: team.id,
            teamName: team.name,
            startDelaySeconds: currentTeamStartDelay,
            wPrimeState: WPrimeState.initial(rider.physiology),
            glycogenGrams: rider.physiology.glycogenCapacityGrams > 0
                ? rider.physiology.glycogenCapacityGrams
                : 450.0,
            pacingStrategy: PacingStrategy.balanced,
          ),
          currentDraftingReduction: tttDraftingReductionFollower,
        );
      }).toList();

      teamStates.add(
        TttTeamSimulationState(
          team: team,
          startDelaySeconds: currentTeamStartDelay,
          turnDuration: turnDur,
          trainRiders: trainRiders,
        ),
      );

      currentTeamStartDelay += teamStartIntervalSeconds;
    }

    commentary.add(
      'Rozpoczyna się ${stage.name} (TTT) na dystansie ${stage.totalDistanceKm.toStringAsFixed(1)} km! '
      'Wystartuje ${teamStates.length} drużyn. Czas liczony jest na 4. kolarzu na linii mety!',
    );

    // Symulacja każdej drużyny
    for (final teamState in teamStates) {
      _simulateSingleTeamTtt(
        teamState: teamState,
        stage: stage,
        checkpoints: checkpoints,
        commentary: commentary,
      );
    }

    // Przeliczenie rankingów na punktach pomiaru czasu drużynowego
    for (int c = 0; c < checkpoints.length; c++) {
      _recalculateTttSplitLeaderboard(teamStates, c);
    }

    // Sortowanie drużyn wg oficjalnego czasu 4. kolarza
    final finishedTeams = teamStates.where((t) => t.hasFinished).toList()
      ..sort((a, b) => (a.officialFourthRiderFinishTimeSeconds ?? double.infinity)
          .compareTo(b.officialFourthRiderFinishTimeSeconds ?? double.infinity));

    final double bestTeamTime = finishedTeams.isNotEmpty
        ? (finishedTeams.first.officialFourthRiderFinishTimeSeconds ?? 0.0)
        : 0.0;

    final List<TttTeamResult> officialTeamResults = [];
    final List<IttRiderResult> officialIndividualRiderResults = [];

    for (int rank = 1; rank <= finishedTeams.length; rank++) {
      final t = finishedTeams[rank - 1];
      final double offTime = t.officialFourthRiderFinishTimeSeconds ?? 0.0;
      final double gap = offTime - bestTeamTime;
      final double avgSpeed = offTime > 0
          ? (stage.totalDistanceKm / (offTime / 3600.0))
          : 0.0;

      final Map<String, double> indTimes = {};
      for (final r in t.trainRiders) {
        indTimes[r.riderId] = r.riderState.finalFinishTimeSeconds ?? offTime;
      }

      officialTeamResults.add(
        TttTeamResult(
          teamId: t.team.id,
          teamName: t.team.name,
          rank: rank,
          officialTimeSeconds: offTime,
          gapToWinnerSeconds: math.max(0.0, gap),
          averageSpeedKmh: avgSpeed,
          activeFinishersCount: t.activeRiders.length,
          droppedCount: t.droppedRiders.length,
          individualFinishTimesSeconds: indTimes,
          droppedRiderNames: t.droppedRiders.map((r) => r.riderName).toList(),
          splits: List<TimeTrialSplitRecord>.from(t.teamSplits),
          turnDuration: t.turnDuration,
        ),
      );

      // Każdy kolarz z pociągu (pierwsza 4-ka) otrzymuje oficjalny czas 4. zawodnika do GC
      for (final r in t.trainRiders) {
        final double riderTime = r.isDropped
            ? (r.riderState.finalFinishTimeSeconds ?? offTime + 120.0)
            : offTime;

        officialIndividualRiderResults.add(
          IttRiderResult(
            riderId: r.riderId,
            riderName: r.riderName,
            teamId: t.team.id,
            teamName: t.team.name,
            rank: rank,
            finishTimeSeconds: riderTime,
            gapToWinnerSeconds: math.max(0.0, riderTime - bestTeamTime),
            averageWatts: r.riderState.averageWatts,
            averageSpeedKmh: avgSpeed,
            maxSpeedKmh: t.maxSpeedKmh,
            remainingWPrimePercentage:
                r.riderState.wPrimeState.wPrimePercentage,
            isBlownUp: r.isDropped,
            blowUpKm: r.droppedAtKm,
            splits: List<TimeTrialSplitRecord>.from(t.teamSplits),
            pacingStrategy: PacingStrategy.balanced,
          ),
        );
      }
    }

    if (officialTeamResults.isNotEmpty) {
      final winningTeam = officialTeamResults.first;
      commentary.add(
        '🏆 Drużynową jazdę na czas ${stage.name} wygrywa ${winningTeam.teamName} '
        'z czasem ${winningTeam.formattedTime} (śr. ${winningTeam.averageSpeedKmh.toStringAsFixed(1)} km/h)!',
      );
    }

    return TimeTrialStageResult(
      stageId: stage.id,
      stageName: stage.name,
      type: TimeTrialType.ttt,
      totalDistanceKm: stage.totalDistanceKm,
      checkpoints: checkpoints,
      riderResults: officialIndividualRiderResults,
      teamResults: officialTeamResults,
      commentaryLog: commentary,
    );
  }

  /// Symuluje przejazd drużyny w szyku czasowym na lemondkach z rotacją zmian (TTT).
  static void _simulateSingleTeamTtt({
    required TttTeamSimulationState teamState,
    required RaceStage stage,
    required List<TimeTrialCheckpoint> checkpoints,
    required List<String> commentary,
  }) {
    teamState.hasStarted = true;
    final double totalMeters = stage.totalDistanceKm * 1000.0;
    const double dt = 1.0; // 1-sekundowy krok dla dokładnego odmierzania zmian (15-30s)

    double currentTrainSpeedMs = 6.0;
    int nextCheckpointIdx = 0;

    while (teamState.distanceTraveledMeters < totalMeters) {
      final double currentKm = teamState.distanceTraveledKm;
      final StageSegment currentSegment = _findSegmentAtKm(stage, currentKm);
      final double slopeGradient = currentSegment.gradientPercent / 100.0;
      final double crr = calculateSegmentCrr(currentSegment);

      final double relativeWindAngle = AeroCalculator.calculateRelativeWindAngle(
        windDirectionDegrees: currentSegment.windDirectionDegrees,
        roadBearingDegrees: currentSegment.roadBearingDegrees,
      );
      final double airDensity = AeroCalculator.calculateAirDensity(
        altitudeMeters: currentSegment.startElevationM,
        temperatureCelsius: stage.baseTemperatureCelsius,
      );

      final activeRiders = teamState.activeRiders;
      if (activeRiders.length < 4) {
        // Zbyt wielu kolarzy odpadło – katastrofa pociągu drużynowego
        break;
      }

      // Średni FTP aktywnych kolarzy w pociągu drużyny (zespołowe zarządzanie tempem)
      double sumFtp = 0.0;
      for (final r in activeRiders) {
        sumFtp += (r.riderState.rider.physiology.ftpWatts > 0
            ? r.riderState.rider.physiology.ftpWatts.toDouble()
            : 380.0);
      }
      final double teamAverageFtp = sumFtp / activeRiders.length;

      // 1. Kolarz dający zmianę na czele (Puller)
      final puller = teamState.currentPuller!;
      puller.currentDraftingReduction = 0.0; // Brak draftingu na czele pociągu!

      // Kolarz na czele jedzie mocno, ale w ryzach optymalnego tempa drużyny
      // (zbyt mocna zmiana rozerwałaby pociąg i zgubiła kluczowego 4. kolarza!)
      final double pullerFtp = puller.riderState.rider.physiology.ftpWatts > 0
          ? puller.riderState.rider.physiology.ftpWatts.toDouble()
          : 400.0;

      double pullerTargetWatts = math.min(pullerFtp * 1.05, teamAverageFtp * 1.08);
      if (currentSegment.gradientPercent > 2.0) {
        pullerTargetWatts *= 1.05;
      }

      // Aktualizacja W' kolarza na czele
      final pullerWUpdate = WPrimeBalanceEngine.update(
        state: puller.riderState.wPrimeState,
        targetPowerWatts: pullerTargetWatts,
        physiology: puller.riderState.rider.physiology,
        timeStepSeconds: dt,
      );
      puller.riderState.wPrimeState = pullerWUpdate.newState;
      final double pullerActualWatts = pullerWUpdate.actualPowerWatts;

      puller.riderState.currentWatts = pullerActualWatts;
      puller.riderState.totalWorkJoules += pullerActualWatts * dt;
      puller.riderState.elapsedRideSeconds += dt;

      // Obliczenie prędkości pociągu narzucanej przez kolarza na czele
      final double pullerCdA = calculateRiderEffectiveCdA(
        puller.riderState.rider,
        draftingReduction: 0.0,
        yawAngleRadians: relativeWindAngle * (math.pi / 180.0),
      );

      final double pullerTotalMassKg =
          puller.riderState.rider.physiology.weightKg + ttBikeMassKg;

      final speedResult = SpeedSolver.solveNextSecond(
        inputWatts: pullerActualWatts,
        currentSpeedMs: currentTrainSpeedMs,
        totalMassKg: pullerTotalMassKg,
        gradientFraction: slopeGradient,
        effectiveCdA: pullerCdA,
        airDensityKgM3: airDensity,
        effectiveCrr: crr,
        windSpeedMs: stage.windSpeedKmh / 3.6,
        relativeWindAngleDegrees: relativeWindAngle,
        descendingSkill: puller.riderState.rider.skills.descending,
        technicalDifficulty: currentSegment.technicalDifficulty,
        timeStepSeconds: dt,
      );

      currentTrainSpeedMs = math.max(3.0, speedResult.newSpeedMs);
      teamState.maxSpeedKmh =
          math.max(teamState.maxSpeedKmh, currentTrainSpeedMs * 3.6);

      // 2. Kolarze jadący za kołem w pociągu (Drafting Followers)
      for (final follower in activeRiders) {
        if (identical(follower, puller)) continue;

        follower.currentDraftingReduction = tttDraftingReductionFollower;

        // Wyznaczenie mocy wymaganej do utrzymania prędkości pociągu w draftingu
        final double followerCdA = calculateRiderEffectiveCdA(
          follower.riderState.rider,
          draftingReduction: tttDraftingReductionFollower,
          yawAngleRadians: relativeWindAngle * (math.pi / 180.0),
        );
        final double followerMassKg =
            follower.riderState.rider.physiology.weightKg + ttBikeMassKg;

        final forces = SpeedSolver.calculateResistanceForces(
          speedMs: currentTrainSpeedMs,
          totalMassKg: followerMassKg,
          gradientFraction: slopeGradient,
          effectiveCdA: followerCdA,
          airDensityKgM3: airDensity,
          effectiveCrr: crr,
          windSpeedMs: stage.windSpeedKmh / 3.6,
          relativeWindAngleDegrees: relativeWindAngle,
        );

        // P_wheel = F_resist * v
        final double wheelPower =
            math.max(0.0, forces.totalResistanceForce * currentTrainSpeedMs);
        final double requiredWatts = math.max(
          80.0,
          wheelPower / (1.0 - PhysicsConstants.drivetrainLossStandard),
        );

        // W' dla kolarza za kołem – w tunelu aero następuje regeneracja!
        final folWUpdate = WPrimeBalanceEngine.update(
          state: follower.riderState.wPrimeState,
          targetPowerWatts: requiredWatts,
          physiology: follower.riderState.rider.physiology,
          timeStepSeconds: dt,
        );

        follower.riderState.wPrimeState = folWUpdate.newState;
        follower.riderState.currentWatts = folWUpdate.actualPowerWatts;
        follower.riderState.totalWorkJoules += folWUpdate.actualPowerWatts * dt;
        follower.riderState.elapsedRideSeconds += dt;

        // Czy kolarz nie wytrzymuje tempa i odpada z pociągu?
        // Następuje to tylko gdy kolarz spędził co najmniej kilkanaście sekund w stanie pełnego wyczerpania
        // oraz drużyna ma jeszcze bezpieczną rezerwę (co najmniej 4 kolarzy musi ukończyć etap!)
        if (folWUpdate.wasPowerCapped &&
            folWUpdate.newState.isExhausted &&
            folWUpdate.newState.timeInExhaustionSeconds >= 12.0 &&
            teamState.activeRiders.length > 4) {
          follower.isDropped = true;
          follower.droppedAtKm = currentKm;
          follower.riderState.isBlownUp = true;
          commentary.add(
            '💔 Odpadnięcie! ${follower.riderName} nie wytrzymał tempa pociągu ${teamState.team.name} '
            'i odpada na ${currentKm.toStringAsFixed(1)}. km! Drużyna kontynuuje w ${teamState.activeRiders.length} kolarzy.',
          );
        }
      }

      // 3. Odliczanie czasu zmiany (15-30 sek) i rotacja pociągu
      teamState.currentTurnElapsedSeconds += dt;
      if (teamState.currentTurnElapsedSeconds >=
          teamState.turnDuration.seconds) {
        teamState.currentTurnElapsedSeconds = 0.0;
        final currentActiveCount = teamState.activeRiders.length;
        if (currentActiveCount > 0) {
          teamState.currentPullerIndex =
              (teamState.currentPullerIndex + 1) % currentActiveCount;
        }
      }

      teamState.distanceTraveledMeters += currentTrainSpeedMs * dt;
      teamState.teamElapsedSeconds += dt;

      // Sprawdzenie punktów pomiaru czasu drużyny
      while (nextCheckpointIdx < checkpoints.length &&
          teamState.distanceTraveledKm >=
              checkpoints[nextCheckpointIdx].distanceKm) {
        final cp = checkpoints[nextCheckpointIdx];
        teamState.teamSplits.add(
          TimeTrialSplitRecord(
            checkpointIndex: cp.index,
            checkpointName: cp.name,
            distanceKm: cp.distanceKm,
            splitElapsedTimeSeconds: teamState.teamElapsedSeconds,
            splitRank: 0,
            gapToBestSplitSeconds: 0.0,
            averageWattsSoFar: puller.riderState.averageWatts,
            averageSpeedKmhSoFar: teamState.teamElapsedSeconds > 0
                ? (teamState.distanceTraveledKm /
                    (teamState.teamElapsedSeconds / 3600.0))
                : 0.0,
            remainingWPrimeJoules:
                puller.riderState.wPrimeState.currentWPrimeJoules,
            wPrimePercentage: puller.riderState.wPrimeState.wPrimePercentage,
            isExhausted: false,
          ),
        );
        nextCheckpointIdx++;
      }
    }

    teamState.hasFinished = true;
    final double finishTime = teamState.teamElapsedSeconds;

    // Zgodnie z regulaminem UCI:
    // Czas 4. kolarza jest oficjalnym czasem drużyny!
    // Kolarze od 1 do 4 w pociągu otrzymują ten oficjalny czas.
    // Kolarze 5+ oraz kolarze, którzy odpadli, otrzymują indywidualne, gorsze czasy.
    teamState.officialFourthRiderFinishTimeSeconds = finishTime;

    final activeAtFinish = teamState.activeRiders;
    teamState.finishersCount = activeAtFinish.length;

    for (int i = 0; i < teamState.trainRiders.length; i++) {
      final r = teamState.trainRiders[i];
      if (!r.isDropped) {
        // Kolarze finiszujący w zwartym pociągu (pierwsza 4-ka i kolejni)
        // Kolarze do 4. miejsca mają identyczny czas drużyny
        final int finishPos = activeAtFinish.indexOf(r) + 1;
        if (finishPos <= 4) {
          r.riderState.finalFinishTimeSeconds = finishTime;
        } else {
          // Kolarze 5., 6., 7. finiszujący za 4. zawodnikiem dostają niewielką stratę na kresce
          r.riderState.finalFinishTimeSeconds = finishTime + ((finishPos - 4) * 0.35);
        }
      } else {
        // Kolarz, który odpadł z pociągu, jechał sam i traci czas
        final double droppedDistanceRemainingKm =
            stage.totalDistanceKm - (r.droppedAtKm ?? (stage.totalDistanceKm * 0.5));
        final double extraSeconds = (droppedDistanceRemainingKm * 1000.0) / 10.5; // ~38 km/h solo
        r.riderState.finalFinishTimeSeconds = finishTime + extraSeconds;
      }
      r.riderState.hasFinished = true;
    }
  }

  // ===========================================================================
  // 5. INTERAKTYWNA SYMULACJA KROKOWA (STEP / TICK API)
  // ===========================================================================

  /// Tworzy interaktywną sesję symulacji ITT gotową do renderowania w 3D lub aktualizacji HUD.
  static IttSimulationSession createIttSession({
    required RaceStage stage,
    required List<Rider> riders,
    required Map<String, CyclingTeam> teamsMap,
    Map<String, PacingStrategy>? customPacing,
    Map<String, int>? customWatts,
    double startIntervalSeconds = 60.0,
  }) {
    final checkpoints = extractOrGenerateCheckpoints(stage);
    final sortedRiders = List<Rider>.from(riders)
      ..sort((a, b) => a.overallRating.compareTo(b.overallRating));

    final List<IttRiderSimulationState> states = [];
    double delay = 0.0;
    for (int i = 0; i < sortedRiders.length; i++) {
      final r = sortedRiders[i];
      final team = teamsMap[r.contract.teamId] ?? teamsMap.values.first;
      states.add(
        IttRiderSimulationState(
          rider: r,
          teamId: team.id,
          teamName: team.name,
          startDelaySeconds: delay,
          wPrimeState: WPrimeState.initial(r.physiology),
          glycogenGrams: r.physiology.glycogenCapacityGrams > 0
              ? r.physiology.glycogenCapacityGrams
              : 450.0,
          pacingStrategy: customPacing?[r.id] ?? PacingStrategy.balanced,
          customWatts: customWatts?[r.id],
        ),
      );
      delay += startIntervalSeconds;
    }

    return IttSimulationSession(
      stage: stage,
      checkpoints: checkpoints,
      riderStates: states,
      teamsMap: teamsMap,
    );
  }

  /// Wykonuje jeden krok czasowy symulacji ITT ([dtSeconds]), np. 1.0s.
  static void tickIttSession(IttSimulationSession session, double dtSeconds) {
    if (session.isCompleted) return;

    session.globalElapsedSeconds += dtSeconds;
    final double globalTime = session.globalElapsedSeconds;
    final double totalMeters = session.stage.totalDistanceKm * 1000.0;

    bool allFinished = true;

    for (final state in session.riderStates) {
      if (state.hasFinished) continue;

      // Czy kolarz zjechał już z rampy startowej?
      if (!state.hasStarted) {
        if (globalTime >= state.startDelaySeconds) {
          state.hasStarted = true;
          state.currentSpeedMs = 5.0; // Start ze stromej rampy
        } else {
          allFinished = false;
          continue;
        }
      }

      allFinished = false;

      final double currentKm = state.distanceTraveledKm;
      final double progress = (state.distanceTraveledMeters / totalMeters).clamp(0.0, 1.0);
      final currentSeg = _findSegmentAtKm(session.stage, currentKm);
      final double slope = currentSeg.gradientPercent / 100.0;
      final double crr = calculateSegmentCrr(currentSeg);

      final double relWindAngle = AeroCalculator.calculateRelativeWindAngle(
        windDirectionDegrees: currentSeg.windDirectionDegrees,
        roadBearingDegrees: currentSeg.roadBearingDegrees,
      );
      final double airDensity = AeroCalculator.calculateAirDensity(
        altitudeMeters: currentSeg.startElevationM,
        temperatureCelsius: session.stage.baseTemperatureCelsius,
      );

      final double cda = calculateRiderEffectiveCdA(
        state.rider,
        draftingReduction: 0.0,
        yawAngleRadians: relWindAngle * (math.pi / 180.0),
      );

      final double targetW = calculateTargetWatts(
        state.rider,
        state.pacingStrategy,
        customWatts: state.customWatts,
        progressFraction: progress,
        gradientPercent: currentSeg.gradientPercent,
      );

      final wUpdate = WPrimeBalanceEngine.update(
        state: state.wPrimeState,
        targetPowerWatts: targetW,
        physiology: state.rider.physiology,
        timeStepSeconds: dtSeconds,
      );

      state.wPrimeState = wUpdate.newState;
      double actualWatts = wUpdate.actualPowerWatts;

      if (wUpdate.wasPowerCapped || wUpdate.newState.isExhausted) {
        if (!state.isBlownUp) {
          state.isBlownUp = true;
          state.blowUpKm = currentKm;
        }
        actualWatts = math.min(actualWatts, state.rider.physiology.ftpWatts * 0.78);
      }

      state.currentWatts = actualWatts;
      state.totalWorkJoules += actualWatts * dtSeconds;
      state.elapsedRideSeconds += dtSeconds;

      final speedResult = SpeedSolver.solveNextSecond(
        inputWatts: actualWatts,
        currentSpeedMs: state.currentSpeedMs,
        totalMassKg: state.rider.physiology.weightKg + ttBikeMassKg,
        gradientFraction: slope,
        effectiveCdA: cda,
        airDensityKgM3: airDensity,
        effectiveCrr: crr,
        windSpeedMs: session.stage.windSpeedKmh / 3.6,
        relativeWindAngleDegrees: relWindAngle,
        descendingSkill: state.rider.skills.descending,
        technicalDifficulty: currentSeg.technicalDifficulty,
        timeStepSeconds: dtSeconds,
      );

      state.currentSpeedMs = math.max(2.5, speedResult.newSpeedMs);
      state.maxSpeedKmh = math.max(state.maxSpeedKmh, state.currentSpeedMs * 3.6);
      state.distanceTraveledMeters += state.currentSpeedMs * dtSeconds;

      // Sprawdź punkty pomiaru
      final recordedCount = state.splits.length;
      if (recordedCount < session.checkpoints.length) {
        final nextCp = session.checkpoints[recordedCount];
        if (state.distanceTraveledKm >= nextCp.distanceKm) {
          state.splits.add(
            TimeTrialSplitRecord(
              checkpointIndex: nextCp.index,
              checkpointName: nextCp.name,
              distanceKm: nextCp.distanceKm,
              splitElapsedTimeSeconds: state.elapsedRideSeconds,
              splitRank: 0,
              gapToBestSplitSeconds: 0.0,
              averageWattsSoFar: state.averageWatts,
              averageSpeedKmhSoFar: state.averageSpeedKmh,
              remainingWPrimeJoules: state.wPrimeState.currentWPrimeJoules,
              wPrimePercentage: state.wPrimeState.wPrimePercentage,
              isExhausted: state.wPrimeState.isExhausted || state.isBlownUp,
            ),
          );
        }
      }

      if (state.distanceTraveledMeters >= totalMeters) {
        state.hasFinished = true;
        state.finalFinishTimeSeconds = state.elapsedRideSeconds;
      }
    }

    if (allFinished) {
      session.isCompleted = true;
    }
  }

  /// Zmienia taktykę rozłożenia sił (Pacing Strategy) danego kolarza w czasie rzeczywistym.
  static void updateRiderPacing(
    IttRiderSimulationState state,
    PacingStrategy strategy, {
    int? customWatts,
  }) {
    state.pacingStrategy = strategy;
    state.customWatts = customWatts;
  }

  // ===========================================================================
  // 6. METODY POMOCNICZE
  // ===========================================================================

  static StageSegment _findSegmentAtKm(RaceStage stage, double targetKm) {
    if (stage.segments.isEmpty) {
      return const StageSegment(
        index: 0,
        startKm: 0.0,
        lengthKm: 100.0,
        startElevationM: 100.0,
        endElevationM: 100.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 20.0,
        windDirectionDegrees: 0.0,
        roadBearingDegrees: 0.0,
        sprintOrKomClassification: SegmentClassification.none,
      );
    }
    for (final seg in stage.segments) {
      if (targetKm >= seg.startKm && targetKm < seg.startKm + seg.lengthKm) {
        return seg;
      }
    }
    return stage.segments.last;
  }

  /// Przelicza ranking i różnice czasowe na danym punkcie pomiaru czasu (ITT).
  static void _recalculateSplitLeaderboard(
    List<IttRiderSimulationState> states,
    int checkpointIndex,
  ) {
    final List<({IttRiderSimulationState state, TimeTrialSplitRecord split})> atSplit = [];

    for (final s in states) {
      if (s.splits.length > checkpointIndex) {
        atSplit.add((state: s, split: s.splits[checkpointIndex]));
      }
    }

    if (atSplit.isEmpty) return;

    atSplit.sort(
      (a, b) => a.split.splitElapsedTimeSeconds.compareTo(b.split.splitElapsedTimeSeconds),
    );

    final double bestTime = atSplit.first.split.splitElapsedTimeSeconds;

    for (int rank = 1; rank <= atSplit.length; rank++) {
      final entry = atSplit[rank - 1];
      final double gap = entry.split.splitElapsedTimeSeconds - bestTime;

      // Zastąp rekord zaktualizowaną pozycją i stratą
      final updatedSplit = TimeTrialSplitRecord(
        checkpointIndex: entry.split.checkpointIndex,
        checkpointName: entry.split.checkpointName,
        distanceKm: entry.split.distanceKm,
        splitElapsedTimeSeconds: entry.split.splitElapsedTimeSeconds,
        splitRank: rank,
        gapToBestSplitSeconds: math.max(0.0, gap),
        averageWattsSoFar: entry.split.averageWattsSoFar,
        averageSpeedKmhSoFar: entry.split.averageSpeedKmhSoFar,
        remainingWPrimeJoules: entry.split.remainingWPrimeJoules,
        wPrimePercentage: entry.split.wPrimePercentage,
        isExhausted: entry.split.isExhausted,
      );

      entry.state.splits[checkpointIndex] = updatedSplit;
    }
  }

  /// Przelicza ranking i różnice czasowe na danym punkcie pomiaru czasu (TTT).
  static void _recalculateTttSplitLeaderboard(
    List<TttTeamSimulationState> teamStates,
    int checkpointIndex,
  ) {
    final List<({TttTeamSimulationState state, TimeTrialSplitRecord split})> atSplit = [];

    for (final t in teamStates) {
      if (t.teamSplits.length > checkpointIndex) {
        atSplit.add((state: t, split: t.teamSplits[checkpointIndex]));
      }
    }

    if (atSplit.isEmpty) return;

    atSplit.sort(
      (a, b) => a.split.splitElapsedTimeSeconds.compareTo(b.split.splitElapsedTimeSeconds),
    );

    final double bestTime = atSplit.first.split.splitElapsedTimeSeconds;

    for (int rank = 1; rank <= atSplit.length; rank++) {
      final entry = atSplit[rank - 1];
      final double gap = entry.split.splitElapsedTimeSeconds - bestTime;

      final updatedSplit = TimeTrialSplitRecord(
        checkpointIndex: entry.split.checkpointIndex,
        checkpointName: entry.split.checkpointName,
        distanceKm: entry.split.distanceKm,
        splitElapsedTimeSeconds: entry.split.splitElapsedTimeSeconds,
        splitRank: rank,
        gapToBestSplitSeconds: math.max(0.0, gap),
        averageWattsSoFar: entry.split.averageWattsSoFar,
        averageSpeedKmhSoFar: entry.split.averageSpeedKmhSoFar,
        remainingWPrimeJoules: entry.split.remainingWPrimeJoules,
        wPrimePercentage: entry.split.wPrimePercentage,
        isExhausted: entry.split.isExhausted,
      );

      entry.state.teamSplits[checkpointIndex] = updatedSplit;
    }
  }
}
