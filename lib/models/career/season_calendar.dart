import '../../models/race/race_stage.dart';
import '../../models/race/tour_race.dart';

/// Stan ukończenia pojedynczego wyścigu w kalendarzu sezonu.
enum RaceCompletionStatus {
  upcoming,
  inProgress,
  completed,
  cancelled;

  String toJson() => name;

  static RaceCompletionStatus fromJson(String value) {
    return RaceCompletionStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RaceCompletionStatus.upcoming,
    );
  }
}

/// Zwięzłe podsumowanie ukończonego wyścigu zapamiętywane w historii kariery.
class RaceHistoryEntry {
  final String raceId;
  final String raceName;
  final int seasonYear;
  final String winnerRiderId;
  final String winnerRiderName;
  final String winnerTeamId;
  final String winnerTeamName;
  final int winnerTotalTimeSeconds;
  final String? pointsWinnerRiderName;
  final String? mountainsWinnerRiderName;
  final String? youthWinnerRiderName;
  final String? teamWinnerName;
  final DateTime completedDate;

  const RaceHistoryEntry({
    required this.raceId,
    required this.raceName,
    required this.seasonYear,
    required this.winnerRiderId,
    required this.winnerRiderName,
    required this.winnerTeamId,
    required this.winnerTeamName,
    required this.winnerTotalTimeSeconds,
    this.pointsWinnerRiderName,
    this.mountainsWinnerRiderName,
    this.youthWinnerRiderName,
    this.teamWinnerName,
    required this.completedDate,
  });

  RaceHistoryEntry copyWith({
    String? raceId,
    String? raceName,
    int? seasonYear,
    String? winnerRiderId,
    String? winnerRiderName,
    String? winnerTeamId,
    String? winnerTeamName,
    int? winnerTotalTimeSeconds,
    String? pointsWinnerRiderName,
    String? mountainsWinnerRiderName,
    String? youthWinnerRiderName,
    String? teamWinnerName,
    DateTime? completedDate,
  }) {
    return RaceHistoryEntry(
      raceId: raceId ?? this.raceId,
      raceName: raceName ?? this.raceName,
      seasonYear: seasonYear ?? this.seasonYear,
      winnerRiderId: winnerRiderId ?? this.winnerRiderId,
      winnerRiderName: winnerRiderName ?? this.winnerRiderName,
      winnerTeamId: winnerTeamId ?? this.winnerTeamId,
      winnerTeamName: winnerTeamName ?? this.winnerTeamName,
      winnerTotalTimeSeconds:
          winnerTotalTimeSeconds ?? this.winnerTotalTimeSeconds,
      pointsWinnerRiderName:
          pointsWinnerRiderName ?? this.pointsWinnerRiderName,
      mountainsWinnerRiderName:
          mountainsWinnerRiderName ?? this.mountainsWinnerRiderName,
      youthWinnerRiderName:
          youthWinnerRiderName ?? this.youthWinnerRiderName,
      teamWinnerName: teamWinnerName ?? this.teamWinnerName,
      completedDate: completedDate ?? this.completedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'raceId': raceId,
      'raceName': raceName,
      'seasonYear': seasonYear,
      'winnerRiderId': winnerRiderId,
      'winnerRiderName': winnerRiderName,
      'winnerTeamId': winnerTeamId,
      'winnerTeamName': winnerTeamName,
      'winnerTotalTimeSeconds': winnerTotalTimeSeconds,
      'pointsWinnerRiderName': pointsWinnerRiderName,
      'mountainsWinnerRiderName': mountainsWinnerRiderName,
      'youthWinnerRiderName': youthWinnerRiderName,
      'teamWinnerName': teamWinnerName,
      'completedDate': completedDate.toIso8601String(),
    };
  }

  factory RaceHistoryEntry.fromJson(Map<String, dynamic> json) {
    return RaceHistoryEntry(
      raceId: json['raceId'] as String,
      raceName: json['raceName'] as String,
      seasonYear: (json['seasonYear'] as num).toInt(),
      winnerRiderId: json['winnerRiderId'] as String,
      winnerRiderName: json['winnerRiderName'] as String,
      winnerTeamId: json['winnerTeamId'] as String,
      winnerTeamName: json['winnerTeamName'] as String,
      winnerTotalTimeSeconds: (json['winnerTotalTimeSeconds'] as num).toInt(),
      pointsWinnerRiderName: json['pointsWinnerRiderName'] as String?,
      mountainsWinnerRiderName: json['mountainsWinnerRiderName'] as String?,
      youthWinnerRiderName: json['youthWinnerRiderName'] as String?,
      teamWinnerName: json['teamWinnerName'] as String?,
      completedDate: DateTime.parse(json['completedDate'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RaceHistoryEntry &&
        other.raceId == raceId &&
        other.seasonYear == seasonYear;
  }

  @override
  int get hashCode => Object.hash(raceId, seasonYear);

  @override
  String toString() =>
      'RaceHistoryEntry($raceName $seasonYear: 1. $winnerRiderName [$winnerTeamName])';
}

/// Model kalendarza wyścigowego dla danego sezonu w trybie kariery menedżera.
class SeasonCalendar {
  final int seasonYear;
  final List<TourRace> races;
  final int currentRaceIndex;
  final String? activeRaceId;
  final int activeStageIndex;
  final List<String> completedRaceIds;
  final Map<String, RaceHistoryEntry> raceHistory;

  const SeasonCalendar({
    required this.seasonYear,
    required this.races,
    this.currentRaceIndex = 0,
    this.activeRaceId,
    this.activeStageIndex = 0,
    this.completedRaceIds = const [],
    this.raceHistory = const {},
  });

  /// Aktualnie trwający wyścig (lub null, jeśli jesteśmy w okresie między wyścigami)
  TourRace? get activeRace {
    if (activeRaceId == null) return null;
    for (final race in races) {
      if (race.id == activeRaceId) return race;
    }
    return null;
  }

  /// Aktualnie rozgrywany etap wyścigu
  RaceStage? get activeStage {
    final currentRace = activeRace;
    if (currentRace == null) return null;
    if (activeStageIndex >= 0 && activeStageIndex < currentRace.stages.length) {
      return currentRace.stages[activeStageIndex];
    }
    return null;
  }

  /// Następny nadchodzący wyścig w kalendarzu
  TourRace? get nextUpcomingRace {
    for (int i = currentRaceIndex; i < races.length; i++) {
      final race = races[i];
      if (!completedRaceIds.contains(race.id)) {
        return race;
      }
    }
    return null;
  }

  /// Lista wszystkich wyścigów, które jeszcze się nie odbyły
  List<TourRace> get upcomingRaces =>
      races.where((r) => !completedRaceIds.contains(r.id)).toList();

  /// Lista wszystkich wyścigów już ukończonych w tym sezonie
  List<TourRace> get completedRaces =>
      races.where((r) => completedRaceIds.contains(r.id)).toList();

  /// Czy dany wyścig został już w pełni ukończony
  bool isRaceCompleted(String raceId) => completedRaceIds.contains(raceId);

  /// Czy dany wyścig jest aktualnie rozgrywany
  bool isRaceActive(String raceId) => activeRaceId == raceId;

  /// Pobiera wyścigi zaplanowane na dany miesiąc (1-12)
  List<TourRace> getRacesForMonth(int month) =>
      races.where((r) => r.startMonth == month).toList();

  /// Pobiera wyścig po identyfikatorze
  TourRace? getRaceById(String id) {
    for (final r in races) {
      if (r.id == id) return r;
    }
    return null;
  }

  /// Zwraca zaktualizowany kalendarz po rozpoczęciu wyścigu
  SeasonCalendar startRace(String raceId) {
    final raceIndex = races.indexWhere((r) => r.id == raceId);
    return copyWith(
      activeRaceId: raceId,
      activeStageIndex: 0,
      currentRaceIndex: raceIndex >= 0 ? raceIndex : currentRaceIndex,
    );
  }

  /// Zwraca zaktualizowany kalendarz po przejściu do kolejnego etapu
  SeasonCalendar advanceToNextStage() {
    final race = activeRace;
    if (race == null) return this;

    final nextStage = activeStageIndex + 1;
    if (nextStage < race.stages.length) {
      return copyWith(activeStageIndex: nextStage);
    }
    return this;
  }

  /// Zwraca zaktualizowany kalendarz po zakończeniu całego wyścigu
  SeasonCalendar completeActiveRace(RaceHistoryEntry historyEntry) {
    if (activeRaceId == null) return this;

    final updatedCompleted = List<String>.from(completedRaceIds);
    if (!updatedCompleted.contains(activeRaceId!)) {
      updatedCompleted.add(activeRaceId!);
    }

    final updatedHistory = Map<String, RaceHistoryEntry>.from(raceHistory);
    updatedHistory[activeRaceId!] = historyEntry;

    final nextIndex = currentRaceIndex + 1;

    return copyWith(
      activeRaceId: null,
      activeStageIndex: 0,
      currentRaceIndex: nextIndex,
      completedRaceIds: updatedCompleted,
      raceHistory: updatedHistory,
    );
  }

  SeasonCalendar copyWith({
    int? seasonYear,
    List<TourRace>? races,
    int? currentRaceIndex,
    String? activeRaceId,
    int? activeStageIndex,
    List<String>? completedRaceIds,
    Map<String, RaceHistoryEntry>? raceHistory,
  }) {
    return SeasonCalendar(
      seasonYear: seasonYear ?? this.seasonYear,
      races: races != null ? List<TourRace>.unmodifiable(races) : this.races,
      currentRaceIndex: currentRaceIndex ?? this.currentRaceIndex,
      activeRaceId: activeRaceId,
      activeStageIndex: activeStageIndex ?? this.activeStageIndex,
      completedRaceIds: completedRaceIds != null
          ? List<String>.unmodifiable(completedRaceIds)
          : this.completedRaceIds,
      raceHistory: raceHistory != null
          ? Map<String, RaceHistoryEntry>.unmodifiable(raceHistory)
          : this.raceHistory,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'seasonYear': seasonYear,
      'races': races.map((r) => r.toJson()).toList(),
      'currentRaceIndex': currentRaceIndex,
      'activeRaceId': activeRaceId,
      'activeStageIndex': activeStageIndex,
      'completedRaceIds': completedRaceIds,
      'raceHistory': raceHistory.map((k, v) => MapEntry(k, v.toJson())),
    };
  }

  factory SeasonCalendar.fromJson(Map<String, dynamic> json) {
    return SeasonCalendar(
      seasonYear: (json['seasonYear'] as num).toInt(),
      races: (json['races'] as List<dynamic>)
          .map((e) => TourRace.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentRaceIndex: (json['currentRaceIndex'] as num?)?.toInt() ?? 0,
      activeRaceId: json['activeRaceId'] as String?,
      activeStageIndex: (json['activeStageIndex'] as num?)?.toInt() ?? 0,
      completedRaceIds: (json['completedRaceIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      raceHistory: (json['raceHistory'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, RaceHistoryEntry.fromJson(v as Map<String, dynamic>)),
          ) ??
          const {},
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SeasonCalendar &&
        other.seasonYear == seasonYear &&
        other.currentRaceIndex == currentRaceIndex &&
        other.activeRaceId == activeRaceId &&
        other.activeStageIndex == activeStageIndex;
  }

  @override
  int get hashCode => Object.hash(
        seasonYear,
        currentRaceIndex,
        activeRaceId,
        activeStageIndex,
      );

  @override
  String toString() =>
      'SeasonCalendar($seasonYear, races: ${races.length}, completed: ${completedRaceIds.length}, active: $activeRaceId (stage $activeStageIndex))';
}

