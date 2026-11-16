import 'dart:math' as math;

import '../../models/race/race_stage.dart';
import '../../models/race/stage_segment.dart';
import '../../models/rider/rider.dart';
import 'rider_race_state.dart';

/// Faza taktyczna AI łowcy koszulki w grochy (KOM / Polka Dot Jersey).
enum KomHunterTacticalPhase {
  /// Próba zabrania się w odjazd dnia na początku etapu lub pod pierwszy podjazd
  targetingBreakaway,

  /// Oszczędzanie sił na zjazdach (aero tuck) i w dolinach (głęboki draft, strefa Z1/Z2)
  conservingInValleyOrDescent,

  /// Kontrolowane tempo wspinaczki przed strefą ataku, z zachowaniem zapasu W' na finisz
  controlledClimbTempo,

  /// Dynamiczny finisz na ostatnich 600 m przed szczytem premii Cat 2, Cat 1 lub HC
  summitSprint600m,

  /// Krótka regeneracja tuż za szczytem przed rozpoczęciem zjazdu
  lightRecoveryAfterSummit,

  /// Brak opłacalnych premii górskich lub wycofanie z walki o punkty KOM
  abandonedKomHunt;

  String toJson() => name;

  static KomHunterTacticalPhase fromJson(String value) {
    return KomHunterTacticalPhase.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => KomHunterTacticalPhase.conservingInValleyOrDescent,
    );
  }
}

/// Szczegółowy opis pojedynczej premii górskiej (KOM) na trasie etapu.
class KomClimbPrimeInfo {
  final int segmentIndex;
  final SegmentClassification category;
  final double climbStartDistanceMeters;
  final double summitDistanceMeters;
  final double lengthMeters;
  final double averageGradientPercent;
  final double elevationGainM;
  final bool isSummitFinish;
  final List<int> pointsScale;

  const KomClimbPrimeInfo({
    required this.segmentIndex,
    required this.category,
    required this.climbStartDistanceMeters,
    required this.summitDistanceMeters,
    required this.lengthMeters,
    required this.averageGradientPercent,
    required this.elevationGainM,
    required this.isSummitFinish,
    required this.pointsScale,
  });

  /// Maksymalna liczba punktów KOM możliwa do zdobycia za 1. miejsce na szczycie.
  int get maxPointsAvailable => pointsScale.isNotEmpty ? pointsScale.first : 0;

  /// Czy premia należy do kategorii wysokopunktowanych (Cat 2, Cat 1 lub HC).
  bool get isHighValuePrime =>
      category == SegmentClassification.cat2 ||
      category == SegmentClassification.cat1 ||
      category == SegmentClassification.horsCategorie;

  /// Waga taktyczna premii [1.0 - 5.0] używana przy priorytetyzacji wysiłku.
  double get tacticalPriorityWeight {
    double base;
    switch (category) {
      case SegmentClassification.horsCategorie:
        base = 4.5;
        break;
      case SegmentClassification.cat1:
        base = 3.5;
        break;
      case SegmentClassification.cat2:
        base = 2.5;
        break;
      case SegmentClassification.cat3:
        base = 1.4;
        break;
      case SegmentClassification.cat4:
        base = 1.0;
        break;
      case SegmentClassification.none:
      case SegmentClassification.intermediateSprint:
      case SegmentClassification.finishLine:
        base = 0.0;
        break;
    }
    return isSummitFinish ? base * 1.25 : base;
  }

  Map<String, dynamic> toJson() {
    return {
      'segmentIndex': segmentIndex,
      'category': category.toJson(),
      'climbStartDistanceMeters': climbStartDistanceMeters,
      'summitDistanceMeters': summitDistanceMeters,
      'lengthMeters': lengthMeters,
      'averageGradientPercent': averageGradientPercent,
      'elevationGainM': elevationGainM,
      'isSummitFinish': isSummitFinish,
      'pointsScale': pointsScale,
    };
  }

  factory KomClimbPrimeInfo.fromJson(Map<String, dynamic> json) {
    return KomClimbPrimeInfo(
      segmentIndex: (json['segmentIndex'] as num).toInt(),
      category: SegmentClassification.fromJson(json['category'] as String),
      climbStartDistanceMeters: (json['climbStartDistanceMeters'] as num).toDouble(),
      summitDistanceMeters: (json['summitDistanceMeters'] as num).toDouble(),
      lengthMeters: (json['lengthMeters'] as num).toDouble(),
      averageGradientPercent: (json['averageGradientPercent'] as num).toDouble(),
      elevationGainM: (json['elevationGainM'] as num).toDouble(),
      isSummitFinish: json['isSummitFinish'] as bool? ?? false,
      pointsScale: (json['pointsScale'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
    );
  }
}

/// Wynik kalkulacji punktów górskich (KOM) dostępnych na całym etapie.
class StageKomPointsEvaluation {
  final String stageId;
  final List<KomClimbPrimeInfo> primes;
  final int totalAvailableKomPoints;
  final int highValuePointsTotal;
  final int hcCount;
  final int cat1Count;
  final int cat2Count;
  final int cat3And4Count;
  final bool isStageWorthHunting;
  final List<int> targetPrimeSegmentIndices;
  final String reasoning;

  const StageKomPointsEvaluation({
    required this.stageId,
    required this.primes,
    required this.totalAvailableKomPoints,
    required this.highValuePointsTotal,
    required this.hcCount,
    required this.cat1Count,
    required this.cat2Count,
    required this.cat3And4Count,
    required this.isStageWorthHunting,
    required this.targetPrimeSegmentIndices,
    required this.reasoning,
  });

  /// Łączna liczba wszystkich premii górskich na etapie.
  int get totalPrimesCount => primes.length;

  /// Łączna liczba premii Cat 2, Cat 1 oraz HC.
  int get highValuePrimesCount => hcCount + cat1Count + cat2Count;

  Map<String, dynamic> toJson() {
    return {
      'stageId': stageId,
      'primes': primes.map((p) => p.toJson()).toList(),
      'totalAvailableKomPoints': totalAvailableKomPoints,
      'highValuePointsTotal': highValuePointsTotal,
      'hcCount': hcCount,
      'cat1Count': cat1Count,
      'cat2Count': cat2Count,
      'cat3And4Count': cat3And4Count,
      'isStageWorthHunting': isStageWorthHunting,
      'targetPrimeSegmentIndices': targetPrimeSegmentIndices,
      'reasoning': reasoning,
    };
  }

  factory StageKomPointsEvaluation.fromJson(Map<String, dynamic> json) {
    return StageKomPointsEvaluation(
      stageId: json['stageId'] as String,
      primes: (json['primes'] as List<dynamic>)
          .map((e) => KomClimbPrimeInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalAvailableKomPoints: (json['totalAvailableKomPoints'] as num).toInt(),
      highValuePointsTotal: (json['highValuePointsTotal'] as num).toInt(),
      hcCount: (json['hcCount'] as num).toInt(),
      cat1Count: (json['cat1Count'] as num).toInt(),
      cat2Count: (json['cat2Count'] as num).toInt(),
      cat3And4Count: (json['cat3And4Count'] as num).toInt(),
      isStageWorthHunting: json['isStageWorthHunting'] as bool,
      targetPrimeSegmentIndices: (json['targetPrimeSegmentIndices'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      reasoning: json['reasoning'] as String,
    );
  }
}

/// Kontekst aktualnej klasyfikacji górskiej (Polka Dot Jersey) w wyścigu.
class KomJerseyStandingContext {
  final int riderCurrentKomPoints;
  final int jerseyLeaderKomPoints;
  final int closestRivalKomPoints;
  final double riderGcTimeGapSeconds;
  final bool isCurrentPolkaDotHolder;
  final int stagesRemainingInTour;

  const KomJerseyStandingContext({
    required this.riderCurrentKomPoints,
    required this.jerseyLeaderKomPoints,
    required this.closestRivalKomPoints,
    this.riderGcTimeGapSeconds = 0.0,
    this.isCurrentPolkaDotHolder = false,
    this.stagesRemainingInTour = 1,
  });

  /// Strata punktowa do lidera klasyfikacji górskiej (0 jeśli kolarz prowadzi).
  int get pointsDeficitToLeader =>
      math.max(0, jerseyLeaderKomPoints - riderCurrentKomPoints);

  /// Przewaga punktowa nad najgroźniejszym rywalem.
  int get leadOverClosestRival =>
      riderCurrentKomPoints - closestRivalKomPoints;

  /// Czy kolarz ma wystarczającą stratę w GC (>= 3 min), by peleton odpuścił go w ucieczce.
  bool get isSafeForBreakawayByGcGap => riderGcTimeGapSeconds >= 180.0;
}

/// Decyzja taktyczna wygenerowana przez [KomPolkaDotHunterAiController] dla pojedynczej sekundy symulacji.
class KomHunterDecision {
  final String riderId;
  final KomHunterTacticalPhase phase;
  final TacticalOrder tacticalOrder;
  final int targetWatts;
  final double targetWattsPerKg;
  final double targetEffortRatio;
  final bool shouldSprintForSummit;
  final bool shouldConserveEnergy;
  final bool shouldJoinBreakaway;
  final KomClimbPrimeInfo? activeTargetPrime;
  final double? distanceToNextSummitMeters;
  final int expectedPointsIfWon;
  final double wPrimeBudgetToSpendJoules;
  final String reasoning;

  const KomHunterDecision({
    required this.riderId,
    required this.phase,
    required this.tacticalOrder,
    required this.targetWatts,
    required this.targetWattsPerKg,
    required this.targetEffortRatio,
    required this.shouldSprintForSummit,
    required this.shouldConserveEnergy,
    required this.shouldJoinBreakaway,
    required this.activeTargetPrime,
    required this.distanceToNextSummitMeters,
    required this.expectedPointsIfWon,
    required this.wPrimeBudgetToSpendJoules,
    required this.reasoning,
  });

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'phase': phase.toJson(),
      'tacticalOrder': tacticalOrder.toJson(),
      'targetWatts': targetWatts,
      'targetWattsPerKg': targetWattsPerKg,
      'targetEffortRatio': targetEffortRatio,
      'shouldSprintForSummit': shouldSprintForSummit,
      'shouldConserveEnergy': shouldConserveEnergy,
      'shouldJoinBreakaway': shouldJoinBreakaway,
      'activeTargetPrime': activeTargetPrime?.toJson(),
      'distanceToNextSummitMeters': distanceToNextSummitMeters,
      'expectedPointsIfWon': expectedPointsIfWon,
      'wPrimeBudgetToSpendJoules': wPrimeBudgetToSpendJoules,
      'reasoning': reasoning,
    };
  }

  @override
  String toString() {
    return 'KomHunterDecision($riderId, phase: ${phase.name}, '
        '${targetWatts}W (${targetWattsPerKg.toStringAsFixed(2)} W/kg), '
        'sprint600m: $shouldSprintForSummit, conserve: $shouldConserveEnergy)';
  }
}

/// Wyspecjalizowane AI łowców koszulki w grochy (KOM / Polka Dot Jersey).
///
/// Odpowiada za:
/// 1. Kalkulację punktów górskich na etapach (analiza wszystkich premii Cat 4–HC
///    wraz z punktacją podwójną na finałowych szczytach i oceną opłacalności etapu).
/// 2. Oszczędzanie sił na zjazdach i w dolinach (minimalizacja wydatku energetycznego,
///    jazda w głębokim drafcie w dolinach i w pozycji aero na zjazdach, regeneracja W').
/// 3. Dynamiczny finisz na ostatnich 600 m przed szczytem każdej premii Cat 2, Cat 1 i HC
///    (eksplozywne wykorzystanie rezerwy beztlenowej W' w strefie szczytowej).
class KomPolkaDotHunterAiController {
  KomPolkaDotHunterAiController._();

  /// Dystans przed szczytem premii Cat 2, Cat 1 i HC uruchamiający dynamiczny finisz [m].
  static const double summitSprintTriggerDistanceMeters = 600.0;

  /// Minimalna liczba punktów KOM na etapie, by walka o odjazd była opłacalna.
  static const int minimumStagePointsForBreakawayHunt = 10;

  /// Próg rezerwy W' [0.0 - 1.0], jaki łowca stara się zachować przed strefą 600 m.
  static const double reservedWPrimeRatioForSummitSprint = 0.35;

  /// Zwraca skalę punktów KOM dla danej kategorii podjazdu.
  ///
  /// Jeśli [isSummitFinish] jest true, premie HC/Cat 1/Cat 2 przyznają pełną
  /// punktację szczytową (zgodną z `StageResultsCalculator`), a dla premii
  /// pośrednich stosowana jest standardowa skala etapowa.
  static List<int> getPointsScaleForCategory(
    SegmentClassification classification, {
    bool isSummitFinish = false,
  }) {
    switch (classification) {
      case SegmentClassification.horsCategorie:
        return isSummitFinish
            ? const [40, 30, 24, 20, 16, 12, 8, 4]
            : const [20, 15, 12, 10, 8, 6, 4, 2];
      case SegmentClassification.cat1:
        return isSummitFinish
            ? const [20, 16, 12, 8, 4, 2]
            : const [10, 8, 6, 4, 2, 1];
      case SegmentClassification.cat2:
        return isSummitFinish
            ? const [10, 6, 4, 2]
            : const [5, 3, 2, 1];
      case SegmentClassification.cat3:
        return isSummitFinish ? const [4, 2] : const [2, 1];
      case SegmentClassification.cat4:
        return isSummitFinish ? const [2] : const [1];
      case SegmentClassification.none:
      case SegmentClassification.intermediateSprint:
      case SegmentClassification.finishLine:
        return const [];
    }
  }

  /// Oblicza pełny bilans punktów górskich na etapie oraz identyfikuje kluczowe premie.
  static StageKomPointsEvaluation evaluateStageKomPoints(RaceStage stage) {
    final segments = stage.segments;
    if (segments.isEmpty) {
      return StageKomPointsEvaluation(
        stageId: stage.id,
        primes: const [],
        totalAvailableKomPoints: 0,
        highValuePointsTotal: 0,
        hcCount: 0,
        cat1Count: 0,
        cat2Count: 0,
        cat3And4Count: 0,
        isStageWorthHunting: false,
        targetPrimeSegmentIndices: const [],
        reasoning: 'Etap nie zawiera żadnych segmentów trasy.',
      );
    }

    final primes = <KomClimbPrimeInfo>[];
    int totalPoints = 0;
    int highValuePoints = 0;
    int hcCount = 0;
    int cat1Count = 0;
    int cat2Count = 0;
    int cat3And4Count = 0;

    for (int i = 0; i < segments.length; i++) {
      final seg = segments[i];
      if (!seg.isKom) continue;

      final isLastSegment = i == segments.length - 1;
      final isSummitFinish = isLastSegment && stage.isSummitFinish;
      final scale = getPointsScaleForCategory(
        seg.sprintOrKomClassification,
        isSummitFinish: isSummitFinish,
      );
      if (scale.isEmpty) continue;

      // Cofnij się po sąsiednich segmentach wznoszących, aby wyznaczyć początek podjazdu.
      int climbStartIdx = i;
      while (climbStartIdx > 0 && segments[climbStartIdx - 1].gradientPercent > 2.0) {
        climbStartIdx--;
      }

      final climbStartM = segments[climbStartIdx].startKm * 1000.0;
      final summitM = seg.endKm * 1000.0;
      final climbLengthM = math.max(100.0, summitM - climbStartM);

      double totalGainM = 0.0;
      for (int k = climbStartIdx; k <= i; k++) {
        totalGainM += segments[k].elevationGainM;
      }
      final avgGradient = (totalGainM / climbLengthM) * 100.0;

      final prime = KomClimbPrimeInfo(
        segmentIndex: seg.index,
        category: seg.sprintOrKomClassification,
        climbStartDistanceMeters: climbStartM,
        summitDistanceMeters: summitM,
        lengthMeters: climbLengthM,
        averageGradientPercent: avgGradient,
        elevationGainM: totalGainM,
        isSummitFinish: isSummitFinish,
        pointsScale: scale,
      );

      primes.add(prime);
      totalPoints += prime.maxPointsAvailable;

      switch (seg.sprintOrKomClassification) {
        case SegmentClassification.horsCategorie:
          hcCount++;
          highValuePoints += prime.maxPointsAvailable;
          break;
        case SegmentClassification.cat1:
          cat1Count++;
          highValuePoints += prime.maxPointsAvailable;
          break;
        case SegmentClassification.cat2:
          cat2Count++;
          highValuePoints += prime.maxPointsAvailable;
          break;
        case SegmentClassification.cat3:
        case SegmentClassification.cat4:
          cat3And4Count++;
          break;
        case SegmentClassification.none:
        case SegmentClassification.intermediateSprint:
        case SegmentClassification.finishLine:
          break;
      }
    }

    final targetIndices = primes
        .where((p) => p.isHighValuePrime || totalPoints < minimumStagePointsForBreakawayHunt)
        .map((p) => p.segmentIndex)
        .toList();

    final worthHunting = highValuePoints >= minimumStagePointsForBreakawayHunt ||
        (totalPoints >= 6 && primes.length >= 2);

    final reasoning = primes.isEmpty
        ? 'Etap płaski bez premii górskich KOM.'
        : 'Wykryto ${primes.length} premii KOM (HC: $hcCount, Cat 1: $cat1Count, '
            'Cat 2: $cat2Count, Cat 3/4: $cat3And4Count). '
            'Łączna pula za 1. miejsca: $totalPoints pkt (Cat 2/1/HC: $highValuePoints pkt). '
            '${worthHunting ? "Etap priorytetowy dla łowcy grochów." : "Niska wartość punktowa etapu."}';

    return StageKomPointsEvaluation(
      stageId: stage.id,
      primes: List<KomClimbPrimeInfo>.unmodifiable(primes),
      totalAvailableKomPoints: totalPoints,
      highValuePointsTotal: highValuePoints,
      hcCount: hcCount,
      cat1Count: cat1Count,
      cat2Count: cat2Count,
      cat3And4Count: cat3And4Count,
      isStageWorthHunting: worthHunting,
      targetPrimeSegmentIndices: List<int>.unmodifiable(targetIndices),
      reasoning: reasoning,
    );
  }

  /// Oblicza przydatność kolarza [0.0 - 100.0] do roli łowcy koszulki w grochy.
  static double calculateKomHunterSuitability(
    Rider rider, {
    KomJerseyStandingContext? jerseyContext,
  }) {
    final weight = rider.physiology.weightKg > 0.0 ? rider.physiology.weightKg : 68.0;
    final wPerKgFtp = rider.physiology.wattsPerKg;
    final wPerKg1m = rider.powerProfile.watts1m / weight;

    double specBonus = 0.0;
    switch (rider.specialization) {
      case RiderSpecialization.pureClimber:
        specBonus = 24.0;
        break;
      case RiderSpecialization.breakawaySpecialist:
        specBonus = 20.0;
        break;
      case RiderSpecialization.puncher:
        specBonus = 15.0;
        break;
      case RiderSpecialization.gcClimber:
        specBonus = 12.0;
        break;
      case RiderSpecialization.domestiqueEngine:
        specBonus = 6.0;
        break;
      case RiderSpecialization.timeTrialist:
      case RiderSpecialization.classicCobbles:
      case RiderSpecialization.versatileSprinter:
      case RiderSpecialization.pureSprinter:
        specBonus = 0.0;
        break;
    }

    // W/kg na długich podjazdach (4.0 -> 6.5) + dynamika 1m na 600 m finisz (7.0 -> 11.5)
    final climbScore = ((wPerKgFtp - 4.0) / 2.5 * 35.0).clamp(0.0, 35.0);
    final summitKickScore = ((wPerKg1m - 7.0) / 4.5 * 20.0).clamp(0.0, 20.0);

    // Umiejętności zjazdowe i oszczędzania sił w dolinach
    final conservationSkill =
        ((rider.skills.descending * 0.5 + rider.skills.draftingEfficiency * 0.5) / 100.0) * 12.0;
    final tacticalIq = (rider.skills.raceIq / 100.0) * 9.0;

    double contextBonus = 0.0;
    if (jerseyContext != null) {
      if (jerseyContext.isCurrentPolkaDotHolder) {
        contextBonus += 12.0;
      } else if (jerseyContext.pointsDeficitToLeader <= 25 &&
          jerseyContext.riderCurrentKomPoints > 0) {
        contextBonus += 8.0;
      }
      if (!jerseyContext.isSafeForBreakawayByGcGap &&
          rider.specialization == RiderSpecialization.gcClimber) {
        // Lider GC na podium rzadko odpuszczany jest w porannej ucieczce po punkty KOM
        contextBonus -= 10.0;
      }
    }

    return (specBonus + climbScore + summitKickScore + conservationSkill + tacticalIq + contextBonus)
        .clamp(0.0, 100.0);
  }

  /// Wyznacza główną decyzję taktyczną AI łowcy koszulki w grochy w bieżącej sekundzie etapu.
  static KomHunterDecision evaluateStep({
    required Rider rider,
    required RiderRaceState raceState,
    required RaceStage stage,
    StageKomPointsEvaluation? stageEvaluation,
    KomJerseyStandingContext? jerseyContext,
    List<RiderRaceState> nearbyRivals = const [],
    double? currentGradientOverridePercent,
  }) {
    final evaluation = stageEvaluation ?? evaluateStageKomPoints(stage);
    final weight = rider.physiology.weightKg > 0.0 ? rider.physiology.weightKg : 68.0;
    final ftp = math.max(150, rider.physiology.ftpWatts);
    final maxWPrime = math.max(1000.0, rider.physiology.wPrimeJoules.toDouble());
    final wPrimeRatio = (raceState.currentWPrime / maxWPrime).clamp(0.0, 1.0);
    final maxGlycogen = math.max(100.0, rider.physiology.glycogenCapacityGrams);
    final glycogenRatio = (raceState.currentGlycogen / maxGlycogen).clamp(0.0, 1.0);

    final currentDistanceM = raceState.distanceCoveredMeters;
    final currentSeg = _findSegmentAtDistance(stage.segments, currentDistanceM);
    final gradient = currentGradientOverridePercent ?? currentSeg?.gradientPercent ?? 0.0;

    // Znajdź następną premię górską przed kolarzem
    KomClimbPrimeInfo? nextPrime;
    for (final prime in evaluation.primes) {
      if (prime.summitDistanceMeters >= currentDistanceM) {
        nextPrime = prime;
        break;
      }
    }

    // Jeśli nie ma już premii KOM przed kolarzem lub glikogen jest krytycznie niski -> tryb pasywny
    if (nextPrime == null || evaluation.primes.isEmpty) {
      final conserveWatts = _computeConservationWatts(
        ftp: ftp,
        gradientPercent: gradient,
        inPelotonDraft: raceState.groupIndex > 0,
      );
      return KomHunterDecision(
        riderId: rider.id,
        phase: KomHunterTacticalPhase.abandonedKomHunt,
        tacticalOrder: TacticalOrder.saveEnergy,
        targetWatts: conserveWatts,
        targetWattsPerKg: conserveWatts / weight,
        targetEffortRatio: conserveWatts / ftp,
        shouldSprintForSummit: false,
        shouldConserveEnergy: true,
        shouldJoinBreakaway: false,
        activeTargetPrime: null,
        distanceToNextSummitMeters: null,
        expectedPointsIfWon: 0,
        wPrimeBudgetToSpendJoules: 0.0,
        reasoning: 'Brak kolejnych premii KOM na etapie — przejście w tryb oszczędzania sił do mety.',
      );
    }

    final distanceToSummitM = math.max(0.0, nextPrime.summitDistanceMeters - currentDistanceM);
    final distanceToNextClimbStartM = nextPrime.climbStartDistanceMeters - currentDistanceM;

    // 1. DYNAMICZNY FINISZ NA OSTATNICH 600 m PRZED SZCZYTEM PREMII CAT 2, CAT 1 LUB HC
    if (nextPrime.isHighValuePrime &&
        distanceToSummitM <= summitSprintTriggerDistanceMeters) {
      return _buildSummitSprintDecision(
        rider: rider,
        raceState: raceState,
        prime: nextPrime,
        distanceToSummitM: distanceToSummitM,
        gradientPercent: gradient,
        weightKg: weight,
        ftp: ftp,
        wPrimeRatio: wPrimeRatio,
        glycogenRatio: glycogenRatio,
        nearbyRivals: nearbyRivals,
      );
    }

    // 2. KRÓTKA REGENERACJA PO PRZEKROCZENIU SZCZYTU (pierwsze 400 m za poprzednią premią)
    final recentlyPassedPrime = _findRecentlyPassedPrime(
      evaluation.primes,
      currentDistanceM,
      windowMeters: 400.0,
    );
    if (recentlyPassedPrime != null && gradient <= 1.0) {
      final recoveryWatts = (ftp * 0.42).round();
      return KomHunterDecision(
        riderId: rider.id,
        phase: KomHunterTacticalPhase.lightRecoveryAfterSummit,
        tacticalOrder: TacticalOrder.saveEnergy,
        targetWatts: recoveryWatts,
        targetWattsPerKg: recoveryWatts / weight,
        targetEffortRatio: recoveryWatts / ftp,
        shouldSprintForSummit: false,
        shouldConserveEnergy: true,
        shouldJoinBreakaway: false,
        activeTargetPrime: nextPrime,
        distanceToNextSummitMeters: distanceToSummitM,
        expectedPointsIfWon: nextPrime.maxPointsAvailable,
        wPrimeBudgetToSpendJoules: 0.0,
        reasoning: 'Regeneracja tętna i W\' tuż za szczytem ${recentlyPassedPrime.category.name.toUpperCase()} '
            'przed zjazdem.',
      );
    }

    // 3. OSZCZĘDZANIE SIŁ NA ZJAZDACH I W DOLINACH
    final isInDescent = gradient < -2.0;
    final isInValley = gradient <= 2.0 && distanceToNextClimbStartM > 800.0;
    if (isInDescent || isInValley) {
      // Wyjątek: początek etapu (km 0–25) i kolarz wciąż w peletonie próbuje zabrać się w odjazd
      final totalStageM = stage.totalDistanceKm * 1000.0;
      final isEarlyBreakawayWindow =
          currentDistanceM <= math.min(28000.0, totalStageM * 0.22) &&
          raceState.groupIndex > 0 &&
          evaluation.isStageWorthHunting &&
          (jerseyContext == null || jerseyContext.isSafeForBreakawayByGcGap) &&
          wPrimeRatio > 0.45 &&
          glycogenRatio > 0.35;

      if (isEarlyBreakawayWindow && !isInDescent) {
        final attackWatts = math.min(
          rider.powerProfile.watts5m.toDouble(),
          ftp * 1.24,
        ).round();
        return KomHunterDecision(
          riderId: rider.id,
          phase: KomHunterTacticalPhase.targetingBreakaway,
          tacticalOrder: TacticalOrder.attack,
          targetWatts: attackWatts,
          targetWattsPerKg: attackWatts / weight,
          targetEffortRatio: attackWatts / ftp,
          shouldSprintForSummit: false,
          shouldConserveEnergy: false,
          shouldJoinBreakaway: true,
          activeTargetPrime: nextPrime,
          distanceToNextSummitMeters: distanceToSummitM,
          expectedPointsIfWon: nextPrime.maxPointsAvailable,
          wPrimeBudgetToSpendJoules: raceState.currentWPrime * 0.25,
          reasoning: 'Atak z peletonu na początku etapu (${evaluation.highValuePointsTotal} pkt KOM w puli) '
              'w celu zabrania się w odjazd dnia.',
        );
      }

      final conserveWatts = _computeConservationWatts(
        ftp: ftp,
        gradientPercent: gradient,
        inPelotonDraft: raceState.groupIndex > 0 || nearbyRivals.isNotEmpty,
      );

      final terrainLabel = isInDescent
          ? 'zjeździe (${gradient.toStringAsFixed(1)}%)'
          : 'dolinie (${gradient.toStringAsFixed(1)}%)';

      return KomHunterDecision(
        riderId: rider.id,
        phase: KomHunterTacticalPhase.conservingInValleyOrDescent,
        tacticalOrder: TacticalOrder.saveEnergy,
        targetWatts: conserveWatts,
        targetWattsPerKg: conserveWatts / weight,
        targetEffortRatio: conserveWatts / ftp,
        shouldSprintForSummit: false,
        shouldConserveEnergy: true,
        shouldJoinBreakaway: false,
        activeTargetPrime: nextPrime,
        distanceToNextSummitMeters: distanceToSummitM,
        expectedPointsIfWon: nextPrime.maxPointsAvailable,
        wPrimeBudgetToSpendJoules: 0.0,
        reasoning: 'Oszczędzanie sił i regeneracja W\' na $terrainLabel przed kolejną premią '
            '${nextPrime.category.name.toUpperCase()} (${(distanceToSummitM / 1000.0).toStringAsFixed(1)} km do szczytu).',
      );
    }

    // 4. KONTROLOWANE TEMPO WSPINACZKI PRZED STREFĄ 600 m
    return _buildControlledClimbDecision(
      rider: rider,
      raceState: raceState,
      prime: nextPrime,
      distanceToSummitM: distanceToSummitM,
      gradientPercent: gradient,
      weightKg: weight,
      ftp: ftp,
      wPrimeRatio: wPrimeRatio,
      glycogenRatio: glycogenRatio,
      nearbyRivals: nearbyRivals,
    );
  }

  /// Szacuje realistyczny potencjał punktowy KOM do zdobycia na pozostałej części etapu.
  static int estimateRemainingKomPointsPotential({
    required Rider rider,
    required RiderRaceState raceState,
    required StageKomPointsEvaluation stageEvaluation,
  }) {
    final suitability = calculateKomHunterSuitability(rider);
    final maxGlycogen = math.max(100.0, rider.physiology.glycogenCapacityGrams);
    final glycogenFactor = (raceState.currentGlycogen / maxGlycogen).clamp(0.2, 1.0);
    final positionFactor = raceState.groupIndex == 0 ? 1.0 : 0.45;

    double expected = 0.0;
    for (final prime in stageEvaluation.primes) {
      if (prime.summitDistanceMeters < raceState.distanceCoveredMeters) continue;
      final winProb = (suitability / 100.0) * glycogenFactor * positionFactor;
      if (winProb >= 0.65 && prime.pointsScale.isNotEmpty) {
        expected += prime.pointsScale[0];
      } else if (winProb >= 0.40 && prime.pointsScale.length > 1) {
        expected += prime.pointsScale[1];
      } else if (winProb >= 0.25 && prime.pointsScale.length > 2) {
        expected += prime.pointsScale[2];
      }
    }
    return expected.round();
  }

  static KomHunterDecision _buildSummitSprintDecision({
    required Rider rider,
    required RiderRaceState raceState,
    required KomClimbPrimeInfo prime,
    required double distanceToSummitM,
    required double gradientPercent,
    required double weightKg,
    required int ftp,
    required double wPrimeRatio,
    required double glycogenRatio,
    required List<RiderRaceState> nearbyRivals,
  }) {
    // Sprawdź obecność rywali w promieniu 150 m (walka o koło i punkty na kresce)
    final hasCloseRivals = nearbyRivals.any(
      (r) =>
          r.riderId != rider.id &&
          (r.distanceCoveredMeters - raceState.distanceCoveredMeters).abs() <= 150.0,
    );

    final urgency = 1.0 - (distanceToSummitM / summitSprintTriggerDistanceMeters).clamp(0.0, 1.0);
    final rivalFactor = hasCloseRivals ? 1.08 : 0.96;
    final categoryFactor = prime.category == SegmentClassification.horsCategorie
        ? 1.10
        : (prime.category == SegmentClassification.cat1 ? 1.04 : 0.98);
    final energyFactor = glycogenRatio < 0.15 ? 0.72 : 1.0;

    // Bazowy mnożnik mocy: ~128% - 168% FTP (dynamiczny finisz pod górę),
    // ograniczony przez krzywą mocy 1m/5s kolarza oraz dostępny zapas W'.
    double targetRatio = (1.28 + urgency * 0.32) * rivalFactor * categoryFactor * energyFactor;
    if (wPrimeRatio < 0.08) {
      // Rezerwa beztlenowa niemal wyczerpana — finisz na maksymalnej mocy tlenowej
      targetRatio = math.min(targetRatio, 1.05);
    }

    final maxAllowedWatts = distanceToSummitM <= 200.0
        ? rider.powerProfile.watts5s.toDouble() * 0.88
        : rider.powerProfile.watts1m.toDouble();

    final rawTargetWatts = (ftp * targetRatio).clamp(ftp * 0.95, maxAllowedWatts);
    final targetWatts = rawTargetWatts.round();
    final wPrimeSpend = wPrimeRatio > 0.05
        ? raceState.currentWPrime * (0.45 + urgency * 0.45)
        : 0.0;

    return KomHunterDecision(
      riderId: rider.id,
      phase: KomHunterTacticalPhase.summitSprint600m,
      tacticalOrder: TacticalOrder.attack,
      targetWatts: targetWatts,
      targetWattsPerKg: targetWatts / weightKg,
      targetEffortRatio: targetWatts / ftp,
      shouldSprintForSummit: true,
      shouldConserveEnergy: false,
      shouldJoinBreakaway: false,
      activeTargetPrime: prime,
      distanceToNextSummitMeters: distanceToSummitM,
      expectedPointsIfWon: prime.maxPointsAvailable,
      wPrimeBudgetToSpendJoules: wPrimeSpend,
      reasoning: 'Dynamiczny finisz KOM (${distanceToSummitM.round()} m do szczytu '
          '${prime.category.name.toUpperCase()}, ${gradientPercent.toStringAsFixed(1)}%): '
          '${hasCloseRivals ? "walka bezpośrednia z rywalami o " : "atak solo po "}'
          '${prime.maxPointsAvailable} pkt.',
    );
  }

  static KomHunterDecision _buildControlledClimbDecision({
    required Rider rider,
    required RiderRaceState raceState,
    required KomClimbPrimeInfo prime,
    required double distanceToSummitM,
    required double gradientPercent,
    required double weightKg,
    required int ftp,
    required double wPrimeRatio,
    required double glycogenRatio,
    required List<RiderRaceState> nearbyRivals,
  }) {
    // Na podjeździe kolarz utrzymuje tempo progowe (86%–98% FTP), ale pilnuje,
    // by zostawić >= 35% W' na finałowe 600 m premii Cat 2 / Cat 1 / HC.
    double baseRatio = prime.isHighValuePrime ? 0.94 : 0.88;
    if (wPrimeRatio < reservedWPrimeRatioForSummitSprint && prime.isHighValuePrime) {
      // Lekkie odpuszczenie poniżej progu LT2, by odbudować W' przed bramką 600 m
      baseRatio = 0.84;
    }
    if (glycogenRatio < 0.25) {
      baseRatio = math.min(baseRatio, 0.82);
    }

    // Jeśli bezpośredni rywal jest na czele i odjeżdża lekko przed premią, pilnuj koła
    final rivalAhead = nearbyRivals.any(
      (r) =>
          r.riderId != rider.id &&
          r.distanceCoveredMeters > raceState.distanceCoveredMeters &&
          (r.distanceCoveredMeters - raceState.distanceCoveredMeters) <= 40.0,
    );

    final order = rivalAhead ? TacticalOrder.followWheels : TacticalOrder.holdPosition;
    final targetWatts = (ftp * baseRatio).round();

    return KomHunterDecision(
      riderId: rider.id,
      phase: KomHunterTacticalPhase.controlledClimbTempo,
      tacticalOrder: order,
      targetWatts: targetWatts,
      targetWattsPerKg: targetWatts / weightKg,
      targetEffortRatio: targetWatts / ftp,
      shouldSprintForSummit: false,
      shouldConserveEnergy: false,
      shouldJoinBreakaway: false,
      activeTargetPrime: prime,
      distanceToNextSummitMeters: distanceToSummitM,
      expectedPointsIfWon: prime.maxPointsAvailable,
      wPrimeBudgetToSpendJoules: 0.0,
      reasoning: 'Kontrolowane tempo wspinaczki (${gradientPercent.toStringAsFixed(1)}%, '
          '${(distanceToSummitM / 1000.0).toStringAsFixed(2)} km do szczytu ${prime.category.name.toUpperCase()}) '
          'z oszczędzaniem W\' (${(wPrimeRatio * 100).round()}%) na ostatnie 600 m.',
    );
  }

  static int _computeConservationWatts({
    required int ftp,
    required double gradientPercent,
    required bool inPelotonDraft,
  }) {
    if (gradientPercent <= -5.0) {
      // Stromy zjazd — pozycja aero tuck, niemal zerowe pedałowanie (regeneracja W')
      return (ftp * 0.22).round();
    }
    if (gradientPercent < -2.0) {
      // Łagodny zjazd
      return (ftp * 0.35).round();
    }
    // Płaska dolina: w grupie duży zysk aero (~50% FTP), solo nieco mocniej (~62% FTP)
    return (ftp * (inPelotonDraft ? 0.50 : 0.62)).round();
  }

  static StageSegment? _findSegmentAtDistance(
    List<StageSegment> segments,
    double distanceMeters,
  ) {
    if (segments.isEmpty) return null;
    final km = distanceMeters / 1000.0;
    for (final seg in segments) {
      if (km >= seg.startKm && km <= seg.endKm) {
        return seg;
      }
    }
    return segments.last;
  }

  static KomClimbPrimeInfo? _findRecentlyPassedPrime(
    List<KomClimbPrimeInfo> primes,
    double currentDistanceMeters, {
    double windowMeters = 400.0,
  }) {
    for (final prime in primes) {
      final delta = currentDistanceMeters - prime.summitDistanceMeters;
      if (delta > 0.0 && delta <= windowMeters) {
        return prime;
      }
    }
    return null;
  }
}
