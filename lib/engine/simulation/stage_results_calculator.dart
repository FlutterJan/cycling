import 'dart:math' as math;
import '../../models/race/race_stage.dart';
import '../../models/race/stage_segment.dart';
import '../../models/rider/rider.dart';
import '../events/race_incident_engine.dart';
import 'stage_simulation_loop.dart';

/// Oficjalny wynik pojedynczego kolarza po zastosowaniu wszystkich reguł UCI.
class OfficialRiderStageResult {
  final String riderId;
  final String riderName;
  final String teamId;

  /// Oficjalne miejsce na etapie (1, 2, 3...)
  final int rank;

  /// Surowy czas fizycznego przecięcia linii mety [s]
  final double rawFinishTimeSeconds;

  /// Oficjalny czas skorygowany regułami UCI (reguła 3 sekund, reguła 3 kilometrów) [s]
  final double officialFinishTimeSeconds;

  /// Zdobyta bonifikata czasowa na mecie [s] (10s za 1. miejsce, 6s za 2., 4s za 3.)
  final int timeBonusSeconds;

  /// Oficjalna strata czasowa do zwycięzcy etapu [s]
  final double gapToWinnerSeconds;

  /// Zdobyte punkty do klasyfikacji punktowej (zielona koszulka)
  final int pointsGreenJersey;

  /// Zdobyte punkty do klasyfikacji górskiej (grochy / KOM)
  final int pointsKom;

  /// Zdobyta nagroda finansowa na etapie w Euro [EUR]
  final int prizeMoneyEur;

  /// Czy wobec kolarza zastosowano regułę 3 kilometrów (kraksa/defekt w strefie ochronnej)
  final bool isThreeKmRuleApplied;

  /// Czy kolarz otrzymał czas grupy w ramach reguły 3 sekund (brak różnicy czasowej w peletonie)
  final bool isThreeSecondRuleApplied;

  /// Czy kolarz przekroczył dopuszczalny limit czasu (Hors Délais / Out of Time Limit - OTL)
  final bool isEliminatedOtl;

  /// Czy kolarz wycofał się z wyścigu i nie ukończył etapu (Did Not Finish - DNF)
  final bool isDnf;

  const OfficialRiderStageResult({
    required this.riderId,
    required this.riderName,
    required this.teamId,
    required this.rank,
    required this.rawFinishTimeSeconds,
    required this.officialFinishTimeSeconds,
    this.timeBonusSeconds = 0,
    required this.gapToWinnerSeconds,
    this.pointsGreenJersey = 0,
    this.pointsKom = 0,
    this.prizeMoneyEur = 0,
    this.isThreeKmRuleApplied = false,
    this.isThreeSecondRuleApplied = false,
    this.isEliminatedOtl = false,
    this.isDnf = false,
  });

  /// Sformatowany oficjalny czas lub strata (np. "04:12:35" lub "+0:15")
  String get formattedGap {
    if (isDnf) return 'DNF';
    if (isEliminatedOtl) return 'OTL';
    if (rank == 1) {
      final int totalSec = officialFinishTimeSeconds.round();
      final int hours = totalSec ~/ 3600;
      final int minutes = (totalSec % 3600) ~/ 60;
      final int seconds = totalSec % 60;
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    if (gapToWinnerSeconds <= 0.0) return 'ten sam czas';

    final int totalSec = gapToWinnerSeconds.round();
    final int minutes = totalSec ~/ 60;
    final int seconds = totalSec % 60;
    if (minutes == 0) return '+$seconds s';
    return '+${minutes}m ${seconds.toString().padLeft(2, '0')}s';
  }

  OfficialRiderStageResult copyWith({
    String? riderId,
    String? riderName,
    String? teamId,
    int? rank,
    double? rawFinishTimeSeconds,
    double? officialFinishTimeSeconds,
    int? timeBonusSeconds,
    double? gapToWinnerSeconds,
    int? pointsGreenJersey,
    int? pointsKom,
    int? prizeMoneyEur,
    bool? isThreeKmRuleApplied,
    bool? isThreeSecondRuleApplied,
    bool? isEliminatedOtl,
    bool? isDnf,
  }) {
    return OfficialRiderStageResult(
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      teamId: teamId ?? this.teamId,
      rank: rank ?? this.rank,
      rawFinishTimeSeconds: rawFinishTimeSeconds ?? this.rawFinishTimeSeconds,
      officialFinishTimeSeconds: officialFinishTimeSeconds ?? this.officialFinishTimeSeconds,
      timeBonusSeconds: timeBonusSeconds ?? this.timeBonusSeconds,
      gapToWinnerSeconds: gapToWinnerSeconds ?? this.gapToWinnerSeconds,
      pointsGreenJersey: pointsGreenJersey ?? this.pointsGreenJersey,
      pointsKom: pointsKom ?? this.pointsKom,
      prizeMoneyEur: prizeMoneyEur ?? this.prizeMoneyEur,
      isThreeKmRuleApplied: isThreeKmRuleApplied ?? this.isThreeKmRuleApplied,
      isThreeSecondRuleApplied: isThreeSecondRuleApplied ?? this.isThreeSecondRuleApplied,
      isEliminatedOtl: isEliminatedOtl ?? this.isEliminatedOtl,
      isDnf: isDnf ?? this.isDnf,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'riderName': riderName,
      'teamId': teamId,
      'rank': rank,
      'rawFinishTimeSeconds': rawFinishTimeSeconds,
      'officialFinishTimeSeconds': officialFinishTimeSeconds,
      'timeBonusSeconds': timeBonusSeconds,
      'gapToWinnerSeconds': gapToWinnerSeconds,
      'pointsGreenJersey': pointsGreenJersey,
      'pointsKom': pointsKom,
      'prizeMoneyEur': prizeMoneyEur,
      'isThreeKmRuleApplied': isThreeKmRuleApplied,
      'isThreeSecondRuleApplied': isThreeSecondRuleApplied,
      'isEliminatedOtl': isEliminatedOtl,
      'isDnf': isDnf,
    };
  }

  factory OfficialRiderStageResult.fromJson(Map<String, dynamic> json) {
    return OfficialRiderStageResult(
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      teamId: json['teamId'] as String,
      rank: (json['rank'] as num).toInt(),
      rawFinishTimeSeconds: (json['rawFinishTimeSeconds'] as num).toDouble(),
      officialFinishTimeSeconds: (json['officialFinishTimeSeconds'] as num).toDouble(),
      timeBonusSeconds: (json['timeBonusSeconds'] as num?)?.toInt() ?? 0,
      gapToWinnerSeconds: (json['gapToWinnerSeconds'] as num).toDouble(),
      pointsGreenJersey: (json['pointsGreenJersey'] as num?)?.toInt() ?? 0,
      pointsKom: (json['pointsKom'] as num?)?.toInt() ?? 0,
      prizeMoneyEur: (json['prizeMoneyEur'] as num?)?.toInt() ?? 0,
      isThreeKmRuleApplied: json['isThreeKmRuleApplied'] as bool? ?? false,
      isThreeSecondRuleApplied: json['isThreeSecondRuleApplied'] as bool? ?? false,
      isEliminatedOtl: json['isEliminatedOtl'] as bool? ?? false,
      isDnf: json['isDnf'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    return '#$rank $riderName ($teamId) - $formattedGap (bonus: -${timeBonusSeconds}s, pts: $pointsGreenJersey, KOM: $pointsKom, €$prizeMoneyEur)';
  }
}

/// Pełny raport z wynikami, klasyfikacjami i nagrodami po zakończeniu etapu.
class StageSummaryReport {
  final String stageId;
  final int stageNumber;
  final String stageName;
  final StageType stageType;
  final String winnerRiderName;
  final String winnerTeamId;
  final double winnerTimeSeconds;

  /// Obliczony limit czasu (Time Cut / OTL) w sekundach
  final double timeCutLimitSeconds;

  /// Procent limitu czasu (% doliczony do czasu zwycięzcy)
  final double timeCutPercent;

  /// Liczba kolarzy wyeliminowanych przez przekroczenie limitu czasu (OTL)
  final int otlEliminatedCount;

  /// Liczba kolarzy, którzy nie ukończyli etapu (DNF)
  final int dnfCount;

  /// Lista oficjalnych wyników wszystkich kolarzy
  final List<OfficialRiderStageResult> results;

  /// Łączne nagrody finansowe zdobyte przez każdą z drużyn [EUR]
  final Map<String, int> teamPrizeMoneyTotals;

  /// Najaktywniejszy kolarz etapu (nagroda za waleczność / combativity)
  final String? mostCombativeRiderId;

  const StageSummaryReport({
    required this.stageId,
    required this.stageNumber,
    required this.stageName,
    required this.stageType,
    required this.winnerRiderName,
    required this.winnerTeamId,
    required this.winnerTimeSeconds,
    required this.timeCutLimitSeconds,
    required this.timeCutPercent,
    required this.otlEliminatedCount,
    required this.dnfCount,
    required this.results,
    required this.teamPrizeMoneyTotals,
    this.mostCombativeRiderId,
  });

  Map<String, dynamic> toJson() {
    return {
      'stageId': stageId,
      'stageNumber': stageNumber,
      'stageName': stageName,
      'stageType': stageType.toJson(),
      'winnerRiderName': winnerRiderName,
      'winnerTeamId': winnerTeamId,
      'winnerTimeSeconds': winnerTimeSeconds,
      'timeCutLimitSeconds': timeCutLimitSeconds,
      'timeCutPercent': timeCutPercent,
      'otlEliminatedCount': otlEliminatedCount,
      'dnfCount': dnfCount,
      'results': results.map((r) => r.toJson()).toList(),
      'teamPrizeMoneyTotals': teamPrizeMoneyTotals,
      'mostCombativeRiderId': mostCombativeRiderId,
    };
  }

  factory StageSummaryReport.fromJson(Map<String, dynamic> json) {
    return StageSummaryReport(
      stageId: json['stageId'] as String,
      stageNumber: (json['stageNumber'] as num).toInt(),
      stageName: json['stageName'] as String,
      stageType: StageType.fromJson(json['stageType'] as String),
      winnerRiderName: json['winnerRiderName'] as String,
      winnerTeamId: json['winnerTeamId'] as String,
      winnerTimeSeconds: (json['winnerTimeSeconds'] as num).toDouble(),
      timeCutLimitSeconds: (json['timeCutLimitSeconds'] as num).toDouble(),
      timeCutPercent: (json['timeCutPercent'] as num).toDouble(),
      otlEliminatedCount: (json['otlEliminatedCount'] as num).toInt(),
      dnfCount: (json['dnfCount'] as num).toInt(),
      results: (json['results'] as List<dynamic>)
          .map((e) => OfficialRiderStageResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      teamPrizeMoneyTotals: (json['teamPrizeMoneyTotals'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, (v as num).toInt())),
      mostCombativeRiderId: json['mostCombativeRiderId'] as String?,
    );
  }
}

/// Zaawansowany kalkulator oficjalnych wyników etapu wyścigu kolarskiego.
///
/// Po przekroczeniu linii mety przez kolarzy podlicza:
/// 1. Regułę 3 sekund (UCI Art. 2.6.027): na płaskich etapach różnica między kolarzami <= 3.0 s nie tworzy luki czasowej.
/// 2. Regułę 3 kilometrów: w razie kraksy/defektu na płaskim finiszu (< 3 km) kolarz otrzymuje czas grupy, w której jechał.
/// 3. Bonifikaty czasowe na mecie (10s, 6s, 4s).
/// 4. Punkty do zielonej koszulki (zależne od profilu etapu: płaski 50 pkt, pagórkowaty 30 pkt, górski 20 pkt).
/// 5. Punkty górskie KOM (kategorie HC, 1, 2, 3, 4).
/// 6. Pule nagród finansowych dla drużyn wg stawek Grand Tour (np. 11 000 € za 1. miejsce).
/// 7. Limit czasu (Time Cut / OTL / Hors Délais) na etapach górskich.
class StageResultsCalculator {
  StageResultsCalculator._();

  /// Alias dla calculateStageResults kompatybilny z różnymi kontrolerami
  static StageSummaryReport calculateOfficialStageResults({
    required RaceStage stage,
    required List<StageFinishResult> finishResults,
    required List<RaceIncidentEvent> incidents,
    required Map<String, Rider> allRidersMap,
    String? playerTeamId,
    String? mostCombativeRiderId,
  }) {
    return calculateStageResults(
      stage: stage,
      rawFinishResults: finishResults,
      stageIncidents: incidents,
      allRidersMap: allRidersMap,
      mostCombativeRiderId: mostCombativeRiderId,
    );
  }

  /// Główna metoda podliczająca i zatwierdzająca oficjalne wyniki etapu.
  static StageSummaryReport calculateStageResults({
    required RaceStage stage,
    required List<StageFinishResult> rawFinishResults,
    required List<RaceIncidentEvent> stageIncidents,
    required Map<String, Rider> allRidersMap,
    String? mostCombativeRiderId,
  }) {
    if (rawFinishResults.isEmpty) {
      return StageSummaryReport(
        stageId: stage.id,
        stageNumber: stage.stageNumber,
        stageName: stage.name,
        stageType: stage.stageType,
        winnerRiderName: 'Brak',
        winnerTeamId: '',
        winnerTimeSeconds: 0.0,
        timeCutLimitSeconds: 0.0,
        timeCutPercent: 0.0,
        otlEliminatedCount: 0,
        dnfCount: 0,
        results: const [],
        teamPrizeMoneyTotals: const {},
      );
    }

    // 1. Sortowanie surowych wyników wg kolejności na kresce
    final List<StageFinishResult> sortedRaw = List.from(rawFinishResults)
      ..sort((a, b) => a.finishTimeSeconds.compareTo(b.finishTimeSeconds));

    final double winnerTime = sortedRaw.first.finishTimeSeconds;
    final double stageLengthKm = stage.totalDistanceKm;

    // 2. Obliczenie limitu czasu (Time Cut / OTL)
    final double timeCutPercent = _calculateTimeCutPercent(
      stage: stage,
      winnerTimeSeconds: winnerTime,
    );
    final double timeCutLimitSeconds = winnerTime * (1.0 + (timeCutPercent / 100.0));

    // 3. Aplikacja Reguły 3 kilometrów (kraksy i defekty na ostatnich 3 km)
    final Map<String, double> threeKmAdjustedTimes = _applyThreeKilometerRule(
      stage: stage,
      sortedRaw: sortedRaw,
      incidents: stageIncidents,
    );

    // 4. Aplikacja Reguły 3 sekund (łączenie w grupy czasowe)
    final List<({StageFinishResult raw, double officialTime, bool is3sApplied})> timeGroups =
        _applyThreeSecondRule(
      stage: stage,
      sortedRaw: sortedRaw,
      adjustedTimes: threeKmAdjustedTimes,
    );

    // 5. Przydział bonifikat czasowych (10s, 6s, 4s na mecie etapów ze startu wspólnego)
    final bool hasTimeBonuses = !stage.isTimeTrial;

    // 6. Przydział punktów do klasyfikacji punktowej (zielona koszulka)
    final List<int> pointScale = _getPointsScaleForStage(stage.stageType);

    // 7. Przydział nagród finansowych
    final List<int> prizeMoneyScale = _getPrizeMoneyScale();

    final List<OfficialRiderStageResult> officialResults = [];
    final Map<String, int> teamMoneyTotals = {};
    int otlCount = 0;
    int dnfCount = 0;

    for (int i = 0; i < timeGroups.length; i++) {
      final entry = timeGroups[i];
      final raw = entry.raw;
      final int rank = i + 1;
      final double officialTime = entry.officialTime;
      final double gapToWinner = math.max(0.0, officialTime - winnerTime);

      // Bonifikata czasowa dla top 3
      int bonusSeconds = 0;
      if (hasTimeBonuses) {
        if (rank == 1) bonusSeconds = 10;
        if (rank == 2) bonusSeconds = 6;
        if (rank == 3) bonusSeconds = 4;
      }

      // Punkty do zielonej koszulki
      final int greenPoints = i < pointScale.length ? pointScale[i] : 0;

      // Punkty górskie KOM na mecie szczytowej (jeśli etap kończy się podjazdem)
      int komPoints = 0;
      if (stage.isSummitFinish && stage.segments.isNotEmpty) {
        final lastSeg = stage.segments.last;
        komPoints = _getSummitKomPoints(lastSeg.sprintOrKomClassification, rank);
      }

      // Nagroda finansowa
      int prizeMoney = i < prizeMoneyScale.length ? prizeMoneyScale[i] : 0;
      if (raw.riderId == mostCombativeRiderId) {
        prizeMoney += 2000; // Premia za waleczność (Combativity)
      }

      // Weryfikacja przekroczenia limitu czasu (OTL)
      final bool isOtl = !stage.isTimeTrial && officialTime > timeCutLimitSeconds;
      if (isOtl) otlCount++;

      final official = OfficialRiderStageResult(
        riderId: raw.riderId,
        riderName: raw.riderName,
        teamId: raw.teamId,
        rank: rank,
        rawFinishTimeSeconds: raw.finishTimeSeconds,
        officialFinishTimeSeconds: officialTime,
        timeBonusSeconds: bonusSeconds,
        gapToWinnerSeconds: gapToWinner,
        pointsGreenJersey: greenPoints,
        pointsKom: komPoints,
        prizeMoneyEur: prizeMoney,
        isThreeKmRuleApplied: threeKmAdjustedTimes.containsKey(raw.riderId),
        isThreeSecondRuleApplied: entry.is3sApplied,
        isEliminatedOtl: isOtl,
        isDnf: false,
      );

      officialResults.add(official);

      // Akumulacja nagród finansowych dla zespołu
      if (prizeMoney > 0) {
        teamMoneyTotals[raw.teamId] = (teamMoneyTotals[raw.teamId] ?? 0) + prizeMoney;
      }
    }

    // Dodanie kolarzy DNF (którzy wycofali się w wyniku kraks)
    for (final inc in stageIncidents) {
      for (final victim in inc.primaryVictims) {
        if (victim.isDnf) {
          final alreadyPresent = officialResults.any((r) => r.riderId == victim.riderId);
          if (!alreadyPresent) {
            dnfCount++;
            officialResults.add(
              OfficialRiderStageResult(
                riderId: victim.riderId,
                riderName: victim.riderName,
                teamId: victim.teamId,
                rank: officialResults.length + 1,
                rawFinishTimeSeconds: 99999.0,
                officialFinishTimeSeconds: 99999.0,
                timeBonusSeconds: 0,
                gapToWinnerSeconds: 99999.0,
                pointsGreenJersey: 0,
                pointsKom: 0,
                prizeMoneyEur: 0,
                isDnf: true,
              ),
            );
          }
        }
      }
    }

    return StageSummaryReport(
      stageId: stage.id,
      stageNumber: stage.stageNumber,
      stageName: stage.name,
      stageType: stage.stageType,
      winnerRiderName: sortedRaw.first.riderName,
      winnerTeamId: sortedRaw.first.teamId,
      winnerTimeSeconds: winnerTime,
      timeCutLimitSeconds: timeCutLimitSeconds,
      timeCutPercent: timeCutPercent,
      otlEliminatedCount: otlCount,
      dnfCount: dnfCount,
      results: officialResults,
      teamPrizeMoneyTotals: teamMoneyTotals,
      mostCombativeRiderId: mostCombativeRiderId,
    );
  }

  /// 1. Reguła 3 sekund (UCI Art. 2.6.027):
  /// Na płaskich etapach, jeśli różnica między kolejnymi kolarzami wynosi <= 3.0 sekundy,
  /// otrzymują oni ten sam czas co czoło danej grupy. Na finiszach górskich próg wynosi 1.0s.
  static List<({StageFinishResult raw, double officialTime, bool is3sApplied})> _applyThreeSecondRule({
    required RaceStage stage,
    required List<StageFinishResult> sortedRaw,
    required Map<String, double> adjustedTimes,
  }) {
    final List<({StageFinishResult raw, double officialTime, bool is3sApplied})> results = [];
    if (sortedRaw.isEmpty) return results;

    // Próg łączenia czasowego: 3.0s na płaskim/bruku, 1.0s na wspinaczkach i pagórkach
    final double splitThresholdSeconds = (stage.stageType == StageType.flat || stage.stageType == StageType.cobbleClassic)
        ? 3.0
        : 1.0;

    double currentGroupOfficialTime = adjustedTimes[sortedRaw.first.riderId] ?? sortedRaw.first.finishTimeSeconds;
    double lastRiderRawTime = sortedRaw.first.finishTimeSeconds;

    for (int i = 0; i < sortedRaw.length; i++) {
      final raw = sortedRaw[i];
      final double effectiveRawTime = adjustedTimes[raw.riderId] ?? raw.finishTimeSeconds;

      if (i == 0) {
        results.add((raw: raw, officialTime: currentGroupOfficialTime, is3sApplied: false));
        lastRiderRawTime = effectiveRawTime;
        continue;
      }

      final double gapToPrecedingRider = effectiveRawTime - lastRiderRawTime;

      if (gapToPrecedingRider <= splitThresholdSeconds) {
        // Kolarz jedzie w tej samej grupie – otrzymuje czas czoła grupy!
        results.add((raw: raw, officialTime: currentGroupOfficialTime, is3sApplied: true));
      } else {
        // Powstała oficjalna luka czasowa – nowa grupa czasowa!
        currentGroupOfficialTime = effectiveRawTime;
        results.add((raw: raw, officialTime: currentGroupOfficialTime, is3sApplied: false));
      }

      lastRiderRawTime = effectiveRawTime;
    }

    return results;
  }

  /// 2. Reguła 3 kilometrów:
  /// Jeśli kolarz ulegnie kraksie lub awarii w strefie ostatnich 3 km etapu ze startu wspólnego
  /// (z wyłączeniem finiszów na szczycie góry i ITT/TTT), otrzymuje czas grupy, w której jechał w chwili zdarzenia.
  static Map<String, double> _applyThreeKilometerRule({
    required RaceStage stage,
    required List<StageFinishResult> sortedRaw,
    required List<RaceIncidentEvent> incidents,
  }) {
    final Map<String, double> adjustments = {};

    // Reguła 3 km nie obowiązuje na czasówkach ani finiszach na szczycie góry (Summit Finish)
    if (stage.isTimeTrial || stage.isSummitFinish || stage.stageType == StageType.summitFinish) {
      return adjustments;
    }

    final double threeKmZoneStartKm = math.max(0.0, stage.totalDistanceKm - 3.0);

    for (final incident in incidents) {
      if (incident.kilometerMark >= threeKmZoneStartKm) {
        // Incydent nastąpił na ostatnich 3 kilometrach!
        for (final victim in incident.primaryVictims) {
          if (!victim.isDnf) {
            // Szukamy zwycięzcy lub czoła peletonu jako punktu odniesienia
            final double pelotonFinishTime = sortedRaw.first.finishTimeSeconds;
            adjustments[victim.riderId] = pelotonFinishTime;
          }
        }
      }
    }

    return adjustments;
  }

  /// Wylicza dopuszczalny limit czasu (Time Cut % / OTL) w oparciu o profil etapu i prędkość zwycięzcy.
  static double _calculateTimeCutPercent({
    required RaceStage stage,
    required double winnerTimeSeconds,
  }) {
    if (winnerTimeSeconds <= 0.0) return 12.0;

    final double winnerSpeedKmh = stage.totalDistanceKm / (winnerTimeSeconds / 3600.0);

    switch (stage.stageType) {
      case StageType.flat:
        // Na płaskim limit wynosi od 4% do 11% w zależności od tempa
        if (winnerSpeedKmh > 48.0) return 11.0;
        if (winnerSpeedKmh > 44.0) return 9.0;
        return 6.0;

      case StageType.cobbleClassic:
      case StageType.hilly:
        // Na pagórkach limit wynosi 10% - 14%
        if (winnerSpeedKmh > 42.0) return 14.0;
        if (winnerSpeedKmh > 38.0) return 12.0;
        return 10.0;

      case StageType.highMountain:
      case StageType.summitFinish:
        // Na etapach górskich limit wynosi 12% - 18% (nawet 40-50 minut zapasu!)
        if (winnerSpeedKmh > 38.0) return 18.0;
        if (winnerSpeedKmh > 34.0) return 16.0;
        return 13.0;

      case StageType.individualTimeTrial:
      case StageType.teamTimeTrial:
        return 25.0; // Na czasówkach 25% czasu zwycięzcy
    }
  }

  /// Skala punktów do zielonej koszulki w zależności od kategorii etapu.
  static List<int> _getPointsScaleForStage(StageType stageType) {
    switch (stageType) {
      case StageType.flat:
        // Etap płaski sprinterski: wysokie punkty (50 pkt za wygraną)
        return const [50, 30, 20, 18, 16, 14, 12, 10, 8, 7, 6, 5, 4, 3, 2];
      case StageType.hilly:
      case StageType.cobbleClassic:
        // Etap pagórkowaty: średnie punkty (30 pkt)
        return const [30, 25, 22, 19, 17, 15, 13, 11, 9, 7, 6, 5, 4, 3, 2];
      case StageType.highMountain:
      case StageType.summitFinish:
      case StageType.individualTimeTrial:
      case StageType.teamTimeTrial:
        // Etap górski / czasówka: niższe punkty (20 pkt)
        return const [20, 17, 15, 13, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1];
    }
  }

  /// Punkty do klasyfikacji górskiej KOM przyznawane na mecie szczytowej.
  static int _getSummitKomPoints(SegmentClassification classification, int rank) {
    switch (classification) {
      case SegmentClassification.horsCategorie:
        // Finisz na szczycie poza kategorią (np. Alpe d'Huez) – podwójne punkty!
        const scale = [40, 30, 24, 20, 16, 12, 8, 4];
        return rank <= scale.length ? scale[rank - 1] : 0;
      case SegmentClassification.cat1:
        const scale = [20, 16, 12, 8, 4, 2];
        return rank <= scale.length ? scale[rank - 1] : 0;
      case SegmentClassification.cat2:
        const scale = [10, 6, 4, 2];
        return rank <= scale.length ? scale[rank - 1] : 0;
      case SegmentClassification.cat3:
        const scale = [4, 2];
        return rank <= scale.length ? scale[rank - 1] : 0;
      case SegmentClassification.cat4:
        return rank == 1 ? 2 : 0;
      case SegmentClassification.none:
      case SegmentClassification.intermediateSprint:
      case SegmentClassification.finishLine:
        return 0;
    }
  }

  /// Pula nagród finansowych na etapie wg standardów UCI WorldTour / Tour de France [EUR].
  static List<int> _getPrizeMoneyScale() {
    return const [
      11000, // 1. miejsce
      5500, // 2. miejsce
      2800, // 3. miejsce
      1500, // 4. miejsce
      830, // 5. miejsce
      650, // 6. miejsce
      500, // 7. miejsce
      450, // 8. miejsce
      380, // 9. miejsce
      380, // 10. miejsce
      300, 300, 300, 300, 300, // 11 - 15
      300, 300, 300, 300, 300, // 16 - 20
    ];
  }
}

