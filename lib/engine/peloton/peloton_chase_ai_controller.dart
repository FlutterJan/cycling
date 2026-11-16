import 'dart:math' as math;
import '../../models/race/race_stage.dart';
import '../../models/rider/rider.dart';
import '../../models/team/cycling_team.dart';
import 'breakaway_vs_peloton_equilibrium_solver.dart';

/// Poziom pilności i intensywności pościgu peletonu za ucieczką.
enum ChaseUrgency {
  /// Spokojne tempo, ucieczka jedzie pod kontrolą na bezpieczny dystans
  idle,

  /// Kontrolowane tempo (utrzymywanie ucieczki na 3-4 minutach)
  controlledPacing,

  /// Stopniowe niwelowanie straty (odrabianie ok. 45-60s na każde 10 km)
  gradualClosing,

  /// Ostra pogoń z pełnym zaangażowaniem pociągu pościgowego (95-105% FTP)
  highSpeedPursuit,

  /// Panika w peletonie! (< 20 km do mety, przewaga ucieczki wciąż niebezpieczna)
  panicCatch,

  /// Kapitulacja peletonu (ucieczka wygrała etap, peleton zwalnia i walczy o 4. miejsce)
  resignedSurrender;

  String toJson() => name;

  static ChaseUrgency fromJson(String value) {
    return ChaseUrgency.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ChaseUrgency.controlledPacing,
    );
  }

  String get label {
    switch (this) {
      case ChaseUrgency.idle:
        return 'Jazda spacerowa';
      case ChaseUrgency.controlledPacing:
        return 'Kontrola przewagi';
      case ChaseUrgency.gradualClosing:
        return 'Systematyczna pogoń';
      case ChaseUrgency.highSpeedPursuit:
        return 'Maksymalny pościg';
      case ChaseUrgency.panicCatch:
        return 'Alarm w peletonie!';
      case ChaseUrgency.resignedSurrender:
        return 'Kapitulacja pościgu';
    }
  }
}

/// Zaangażowanie pojedynczego zespołu w pociąg pościgowy na czele peletonu.
class ChaseCommitment {
  final String teamId;
  final String teamName;
  final List<String> committedDomestiqueIds;
  final int targetWattsPerRider;
  final String motive;

  const ChaseCommitment({
    required this.teamId,
    required this.teamName,
    required this.committedDomestiqueIds,
    required this.targetWattsPerRider,
    required this.motive,
  });

  int get domestiqueCount => committedDomestiqueIds.length;

  ChaseCommitment copyWith({
    String? teamId,
    String? teamName,
    List<String>? committedDomestiqueIds,
    int? targetWattsPerRider,
    String? motive,
  }) {
    return ChaseCommitment(
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      committedDomestiqueIds: committedDomestiqueIds ?? this.committedDomestiqueIds,
      targetWattsPerRider: targetWattsPerRider ?? this.targetWattsPerRider,
      motive: motive ?? this.motive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'teamId': teamId,
      'teamName': teamName,
      'committedDomestiqueIds': committedDomestiqueIds,
      'targetWattsPerRider': targetWattsPerRider,
      'motive': motive,
    };
  }

  factory ChaseCommitment.fromJson(Map<String, dynamic> json) {
    return ChaseCommitment(
      teamId: json['teamId'] as String,
      teamName: json['teamName'] as String,
      committedDomestiqueIds: (json['committedDomestiqueIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      targetWattsPerRider: (json['targetWattsPerRider'] as num).toInt(),
      motive: json['motive'] as String,
    );
  }

  @override
  String toString() {
    return 'ChaseCommitment($teamName, riders: $domestiqueCount, P: ${targetWattsPerRider}W, motive: "$motive")';
  }
}

/// Szczegółowy plan taktyczny pościgu peletonu za ucieczką.
class PelotonChasePlan {
  /// Poziom pilności i determinacji peletonu
  final ChaseUrgency urgency;

  /// Docelowy punkt skasowania ucieczki przed metą w km (np. 5 - 10 km)
  final double targetCatchKmRemaining;

  /// Prognozowany kilometr etapu, na którym nastąpi skasowanie ucieczki [km]
  final double projectedCatchKm;

  /// Wymagane tempo odrabiania strat w sekundach na 10 km [s/10km]
  final double requiredClawbackSecondsPer10Km;

  /// Rzeczywiste tempo odrabiania strat generowane przez lokomotywę pościgu [s/10km]
  final double actualClawbackSecondsPer10Km;

  /// Współczynnik błędu kalkulacji AI (0.80 - 1.25)
  /// Wartość > 1.0 oznacza, że peleton przeszacował swoje siły i sprytna ucieczka ma szansę dojechać!
  final double aiMiscalculationFactor;

  /// Prawdopodobieństwo dojechania ucieczki do mety [0.0 - 1.0]
  final double breakawaySurvivalProbability;

  /// Lista drużyn wystawiających pomocników do pracy na czele
  final List<ChaseCommitment> committedTeams;

  /// Łączna liczba pomocników pracujących aktualnie w pociągu pościgowym
  int get totalDomestiquesWorking =>
      committedTeams.fold<int>(0, (sum, c) => sum + c.domestiqueCount);

  /// Raport radiowy dyrektora sportowego
  final String radioReport;

  const PelotonChasePlan({
    required this.urgency,
    required this.targetCatchKmRemaining,
    required this.projectedCatchKm,
    required this.requiredClawbackSecondsPer10Km,
    required this.actualClawbackSecondsPer10Km,
    required this.aiMiscalculationFactor,
    required this.breakawaySurvivalProbability,
    required this.committedTeams,
    required this.radioReport,
  });

  /// Czy ucieczka ma realne szanse wygrać etap (> 35% prawdopodobieństwa)
  bool get hasBreakawayStrongChance => breakawaySurvivalProbability >= 0.35;

  PelotonChasePlan copyWith({
    ChaseUrgency? urgency,
    double? targetCatchKmRemaining,
    double? projectedCatchKm,
    double? requiredClawbackSecondsPer10Km,
    double? actualClawbackSecondsPer10Km,
    double? aiMiscalculationFactor,
    double? breakawaySurvivalProbability,
    List<ChaseCommitment>? committedTeams,
    String? radioReport,
  }) {
    return PelotonChasePlan(
      urgency: urgency ?? this.urgency,
      targetCatchKmRemaining: targetCatchKmRemaining ?? this.targetCatchKmRemaining,
      projectedCatchKm: projectedCatchKm ?? this.projectedCatchKm,
      requiredClawbackSecondsPer10Km:
          requiredClawbackSecondsPer10Km ?? this.requiredClawbackSecondsPer10Km,
      actualClawbackSecondsPer10Km:
          actualClawbackSecondsPer10Km ?? this.actualClawbackSecondsPer10Km,
      aiMiscalculationFactor:
          aiMiscalculationFactor ?? this.aiMiscalculationFactor,
      breakawaySurvivalProbability:
          breakawaySurvivalProbability ?? this.breakawaySurvivalProbability,
      committedTeams: committedTeams ?? this.committedTeams,
      radioReport: radioReport ?? this.radioReport,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'urgency': urgency.toJson(),
      'targetCatchKmRemaining': targetCatchKmRemaining,
      'projectedCatchKm': projectedCatchKm,
      'requiredClawbackSecondsPer10Km': requiredClawbackSecondsPer10Km,
      'actualClawbackSecondsPer10Km': actualClawbackSecondsPer10Km,
      'aiMiscalculationFactor': aiMiscalculationFactor,
      'breakawaySurvivalProbability': breakawaySurvivalProbability,
      'committedTeams': committedTeams.map((c) => c.toJson()).toList(),
      'radioReport': radioReport,
    };
  }

  factory PelotonChasePlan.fromJson(Map<String, dynamic> json) {
    return PelotonChasePlan(
      urgency: ChaseUrgency.fromJson(json['urgency'] as String),
      targetCatchKmRemaining: (json['targetCatchKmRemaining'] as num).toDouble(),
      projectedCatchKm: (json['projectedCatchKm'] as num).toDouble(),
      requiredClawbackSecondsPer10Km:
          (json['requiredClawbackSecondsPer10Km'] as num).toDouble(),
      actualClawbackSecondsPer10Km:
          (json['actualClawbackSecondsPer10Km'] as num).toDouble(),
      aiMiscalculationFactor: (json['aiMiscalculationFactor'] as num).toDouble(),
      breakawaySurvivalProbability:
          (json['breakawaySurvivalProbability'] as num).toDouble(),
      committedTeams: (json['committedTeams'] as List<dynamic>)
          .map((e) => ChaseCommitment.fromJson(e as Map<String, dynamic>))
          .toList(),
      radioReport: json['radioReport'] as String,
    );
  }

  @override
  String toString() {
    return 'PelotonChasePlan(${urgency.label}, targetCatch: -${targetCatchKmRemaining.toStringAsFixed(1)}km, '
        'projected: ${projectedCatchKm.toStringAsFixed(1)}km, '
        'prob: ${(breakawaySurvivalProbability * 100).toStringAsFixed(0)}%, '
        'locomotive: $totalDomestiquesWorking riders)';
  }
}

/// Kontroler sztucznej inteligencji zarządzający pościgiem peletonu.
///
/// Logika kolarska:
/// 1. Drużyna lidera wyścigu (żółta koszulka) kontroluje ucieczkę, by nie zagroziła GC.
/// 2. Na etapach płaskich drużyny sprinterskie wystawiają pomocników (domestiques), by
///    doprowadzić do finiszu z grupy.
/// 3. Standardowa zasada peletonu: odrabianie ok. 1 minuty na 10 km na płaskiej trasie.
/// 4. Cel: skasowanie ucieczki na 5-10 km przed metą (nie za wcześnie, by uniknąć kontrataków!).
/// 5. Błędy kalkulacji AI (poker taktyczny, wiatr w plecy, kręta trasa, zgrana ucieczka)
///    stwarzają realną szansę (15-25%), że sprytna ucieczka dojedzie do mety.
class PelotonChaseAiController {
  PelotonChaseAiController._();

  /// Oblicza optymalny i realistyczny plan pościgu peletonu.
  ///
  /// Parametry:
  /// - [stage]: aktualny etap wyścigu ([RaceStage])
  /// - [currentKm]: aktualny kilometraż czoła peletonu [km]
  /// - [breakawayGapSeconds]: aktualna strata peletonu do ucieczki [s]
  /// - [breakawayCooperationScore]: wskaźnik współpracy ucieczki (1.0 = zgrana karuzela)
  /// - [breakawayRiderCount]: liczba kolarzy w ucieczce
  /// - [gcLeaderTeam]: drużyna lidera wyścigu ([CyclingTeam])
  /// - [sprintTeams]: drużyny posiadające faworytów sprinterskich
  /// - [allTeamsMap]: mapa id -> [CyclingTeam]
  /// - [allRidersMap]: mapa id -> [Rider]
  /// - [isBreakawayDangerousInGc]: czy któryś uciekinier zagraża żółtej koszulce
  static PelotonChasePlan calculateChasePlan({
    required RaceStage stage,
    required double currentKm,
    required double breakawayGapSeconds,
    required double breakawayCooperationScore,
    required int breakawayRiderCount,
    required CyclingTeam gcLeaderTeam,
    required List<CyclingTeam> sprintTeams,
    required Map<String, CyclingTeam> allTeamsMap,
    required Map<String, Rider> allRidersMap,
    bool isBreakawayDangerousInGc = false,
  }) {
    final double stageLengthKm = stage.totalDistanceKm;
    final double distanceRemainingKm = math.max(1.0, stageLengthKm - currentKm);

    // Na czasówkach pościg nie występuje
    if (stage.isTimeTrial) {
      return PelotonChasePlan(
        urgency: ChaseUrgency.idle,
        targetCatchKmRemaining: 0.0,
        projectedCatchKm: stageLengthKm,
        requiredClawbackSecondsPer10Km: 0.0,
        actualClawbackSecondsPer10Km: 0.0,
        aiMiscalculationFactor: 1.0,
        breakawaySurvivalProbability: 0.0,
        committedTeams: const [],
        radioReport: 'Jazda indywidualna na czas.',
      );
    }

    // Jeśli brak ucieczki lub ucieczka już została skasowana (< 5 sekund przewagi)
    if (breakawayGapSeconds <= 5.0 || breakawayRiderCount == 0) {
      return PelotonChasePlan(
        urgency: ChaseUrgency.idle,
        targetCatchKmRemaining: 0.0,
        projectedCatchKm: currentKm,
        requiredClawbackSecondsPer10Km: 0.0,
        actualClawbackSecondsPer10Km: 0.0,
        aiMiscalculationFactor: 1.0,
        breakawaySurvivalProbability: 0.0,
        committedTeams: const [],
        radioReport: 'Peleton jedzie całością – brak ucieczki na trasie.',
      );
    }

    // 1. Wyznaczenie pożądanego punktu skasowania ucieczki:
    // Peleton dąży do dogonienia ucieczki na 5.0 do 9.5 km przed metą.
    // Skasowanie ucieczki za wcześnie (np. 30 km do mety) grozi chaosem i serią kontrataków!
    final double targetCatchKmRemaining = (stage.stageType == StageType.flat) ? 7.5 : 5.0;

    // Dystans dostępny na odrobienie strat [km]
    final double availableClosingKm = math.max(1.0, distanceRemainingKm - targetCatchKmRemaining);

    // Wymagane tempo odrabiania straty w sekundach na 10 km:
    final double requiredClawbackPer10Km = (breakawayGapSeconds / availableClosingKm) * 10.0;

    // 2. Czynniki błędów i wariancji taktycznej AI (dające szansę ucieczce):
    // a) Poker taktyczny drużyn sprinterskich (bystander effect): "Niech inni gonią"
    double pokerHesitationPenalty = 0.0;
    if (sprintTeams.length >= 3 && distanceRemainingKm > 40.0 && !isBreakawayDangerousInGc) {
      pokerHesitationPenalty = 0.18; // 18% opóźnienia w reakcji
    }

    // b) Jakość współpracy ucieczki: idealna karuzela jedzie szybciej niż kalkuluje peleton
    final double breakawayEfficiencyBonus = (breakawayCooperationScore >= 0.90) ? 0.14 : 0.0;

    // c) Wiatr w plecy (tailwind faworyzuje małą grupę) lub trudna technicznie kręta trasa
    final double windFactor = stage.windSpeedKmh > 25.0 ? 0.08 : 0.0;

    // Łączny współczynnik błędu kalkulacji AI (wartości > 1.0 pomagają ucieczce)
    final double aiMiscalculationFactor = (1.0 + pokerHesitationPenalty + breakawayEfficiencyBonus + windFactor)
        .clamp(0.75, 1.45);

    // 3. Poziom pilności pościgu (ChaseUrgency)
    ChaseUrgency urgency;
    if (distanceRemainingKm < 15.0 && breakawayGapSeconds > 90.0) {
      // Za mało kilometrów, ucieczka jest zbyt daleko – kapitulacja peletonu
      urgency = ChaseUrgency.resignedSurrender;
    } else if (distanceRemainingKm < 22.0 && breakawayGapSeconds > 45.0) {
      urgency = ChaseUrgency.panicCatch;
    } else if (requiredClawbackPer10Km > 75.0 || distanceRemainingKm < 45.0 || isBreakawayDangerousInGc) {
      urgency = ChaseUrgency.highSpeedPursuit;
    } else if (requiredClawbackPer10Km > 35.0 || distanceRemainingKm < 80.0) {
      urgency = ChaseUrgency.gradualClosing;
    } else {
      urgency = ChaseUrgency.controlledPacing;
    }

    // 4. Dobór drużyn i pomocników (domestiques) do pracy na czele:
    final List<ChaseCommitment> commitments = [];

    // A) Drużyna lidera wyścigu (żółta koszulka)
    if (isBreakawayDangerousInGc || urgency == ChaseUrgency.panicCatch) {
      final domestiques = _pickDomestiquesForTeam(gcLeaderTeam, allRidersMap, count: 2);
      if (domestiques.isNotEmpty) {
        commitments.add(
          ChaseCommitment(
            teamId: gcLeaderTeam.id,
            teamName: gcLeaderTeam.name,
            committedDomestiqueIds: domestiques,
            targetWattsPerRider: (urgency == ChaseUrgency.panicCatch) ? 385 : 340,
            motive: 'Obrona żółtej koszulki lidera wyścigu',
          ),
        );
      }
    } else if (urgency != ChaseUrgency.idle && urgency != ChaseUrgency.resignedSurrender) {
      // 1 pomocnik lidera kontroluje tempo
      final domestiques = _pickDomestiquesForTeam(gcLeaderTeam, allRidersMap, count: 1);
      if (domestiques.isNotEmpty) {
        commitments.add(
          ChaseCommitment(
            teamId: gcLeaderTeam.id,
            teamName: gcLeaderTeam.name,
            committedDomestiqueIds: domestiques,
            targetWattsPerRider: 310,
            motive: 'Kontrola bezpiecznej przewagi ucieczki',
          ),
        );
      }
    }

    // B) Drużyny sprinterskie (na etapach płaskich / pagórkowatych)
    if (stage.stageType == StageType.flat || stage.stageType == StageType.cobbleClassic) {
      final int maxSprintTeamsToWork = (urgency == ChaseUrgency.highSpeedPursuit || urgency == ChaseUrgency.panicCatch)
          ? math.min(4, sprintTeams.length)
          : math.min(2, sprintTeams.length);

      for (int i = 0; i < maxSprintTeamsToWork; i++) {
        final sTeam = sprintTeams[i];
        if (sTeam.id == gcLeaderTeam.id) continue;

        final int ridersCount = (urgency == ChaseUrgency.panicCatch) ? 2 : 1;
        final domestiques = _pickDomestiquesForTeam(sTeam, allRidersMap, count: ridersCount);

        if (domestiques.isNotEmpty) {
          commitments.add(
            ChaseCommitment(
              teamId: sTeam.id,
              teamName: sTeam.name,
              committedDomestiqueIds: domestiques,
              targetWattsPerRider: (urgency == ChaseUrgency.panicCatch) ? 400 : 355,
              motive: 'Praca na czele pod finisz z peletonu',
            ),
          );
        }
      }
    }

    // 5. Rzeczywista siła lokomotywy pościgu:
    // Każdy zaangażowany pomocnik na czele dokłada ok. 15-20 s/10km zdolności odrabiania
    final int totalDomestiques = commitments.fold<int>(0, (sum, c) => sum + c.domestiqueCount);
    double baseClawbackPer10Km;

    switch (urgency) {
      case ChaseUrgency.idle:
        baseClawbackPer10Km = 0.0;
        break;
      case ChaseUrgency.controlledPacing:
        baseClawbackPer10Km = 25.0 + (totalDomestiques * 6.0); // ~35-45s / 10km
        break;
      case ChaseUrgency.gradualClosing:
        baseClawbackPer10Km = 35.0 + (totalDomestiques * 8.0); // ~55-70s / 10km
        break;
      case ChaseUrgency.highSpeedPursuit:
        baseClawbackPer10Km = 50.0 + (totalDomestiques * 11.0); // ~85-110s / 10km
        break;
      case ChaseUrgency.panicCatch:
        baseClawbackPer10Km = 65.0 + (totalDomestiques * 14.0); // > 120s / 10km
        break;
      case ChaseUrgency.resignedSurrender:
        baseClawbackPer10Km = 5.0; // Minimalne tempo, brak szans
        break;
    }

    // Rzeczywiste tempo odrabiania uwzględniające błędy AI i spryt ucieczki
    final double actualClawbackPer10Km = math.max(0.0, baseClawbackPer10Km / aiMiscalculationFactor);

    // Prognozowany kilometr skasowania ucieczki:
    final double kmNeededToCatch = actualClawbackPer10Km > 0.0
        ? (breakawayGapSeconds / (actualClawbackPer10Km / 10.0))
        : 9999.0;

    final double projectedCatchKm = currentKm + kmNeededToCatch;

    // 6. Szacowanie prawdopodobieństwa dojechania ucieczki do mety przez zbalansowany solver równowagi:
    final BreakawayEquilibriumResult equilibrium =
        BreakawayVsPelotonEquilibriumSolver.solveForStage(
      stage: stage,
      currentKm: currentKm,
      currentGapSeconds: breakawayGapSeconds,
      breakawayRiderCount: breakawayRiderCount,
      breakawayCooperationScore: breakawayCooperationScore,
      sprintTeamsInterestedCount: sprintTeams.length,
      committedChaseDomestiques: totalDomestiques,
      isBreakawayDangerousInGc: isBreakawayDangerousInGc,
    );
    final double survivalProbability = equilibrium.survivalProbability;

    // Komunikat radiowy
    String radioReport;
    if (urgency == ChaseUrgency.resignedSurrender) {
      radioReport = 'Ucieczka wygrała etap! Peleton odpuścił pościg i szykuje się do sprintu o dalsze miejsca.';
    } else if (urgency == ChaseUrgency.panicCatch) {
      radioReport = 'Alarm na czele peletonu! Pociąg pościgowy idzie na 110% mocy – walka o każdą sekundę!';
    } else if (survivalProbability > 0.40) {
      radioReport = 'Ucieczka świetnie współpracuje! Przy obecnym tempie uciekinierzy powalczą o etap!';
    } else {
      radioReport = 'Peleton kontroluje sytuację. Prognozowane skasowanie ucieczki na ${projectedCatchKm.toStringAsFixed(1)} km.';
    }

    return PelotonChasePlan(
      urgency: urgency,
      targetCatchKmRemaining: targetCatchKmRemaining,
      projectedCatchKm: projectedCatchKm,
      requiredClawbackSecondsPer10Km: requiredClawbackPer10Km,
      actualClawbackSecondsPer10Km: actualClawbackPer10Km,
      aiMiscalculationFactor: aiMiscalculationFactor,
      breakawaySurvivalProbability: survivalProbability.clamp(0.01, 0.99),
      committedTeams: commitments,
      radioReport: radioReport,
    );
  }

  /// Pomocnicza funkcja dobierająca najlepszych pomocników ([domestiqueEngine] lub rouleurów) z danego zespołu.
  static List<String> _pickDomestiquesForTeam(
    CyclingTeam team,
    Map<String, Rider> allRidersMap, {
    required int count,
  }) {
    final List<({String riderId, double engineScore})> candidates = [];

    for (final riderId in team.rosterRiderIds) {
      final rider = allRidersMap[riderId];
      if (rider == null) continue;

      double score = rider.physiology.ftpWatts.toDouble();
      if (rider.specialization == RiderSpecialization.domestiqueEngine) {
        score += 80.0;
      } else if (rider.specialization == RiderSpecialization.timeTrialist) {
        score += 60.0;
      } else if (rider.specialization == RiderSpecialization.classicCobbles) {
        score += 40.0;
      } else if (rider.specialization == RiderSpecialization.pureSprinter ||
          rider.specialization == RiderSpecialization.gcClimber) {
        score -= 200.0; // Nie palimy sprinterów ani liderów na wietrze!
      }

      candidates.add((riderId: riderId, engineScore: score));
    }

    candidates.sort((a, b) => b.engineScore.compareTo(a.engineScore));
    return candidates.take(count).map((c) => c.riderId).toList();
  }
}

