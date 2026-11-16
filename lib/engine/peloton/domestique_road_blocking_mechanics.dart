import 'dart:math' as math;

import 'peloton_chase_ai_controller.dart';

/// Stan taktycznej blokady drogi przez drużynę lidera ucieczki.
enum RoadBlockingStatus {
  /// Blokada nieaktywna (droga >= 4.5 m, brak kolegi w ucieczce lub za mało kolarzy).
  inactive,

  /// Częściowe utrudnianie pogoni (wąska droga, ale niepełne pokrycie szerokości jezdni).
  partialScreen,

  /// Pełna blokada szosy (wąska droga < 4.5 m, szeroki szyk przy ~65% FTP).
  fullRoadblock,

  /// Rywale przełamali blokadę, przepychając się poboczem z dużym kosztem W'.
  breachedByRivals;

  String toJson() => name;

  static RoadBlockingStatus fromJson(String value) {
    return RoadBlockingStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RoadBlockingStatus.inactive,
    );
  }

  String get label {
    switch (this) {
      case RoadBlockingStatus.inactive:
        return 'Brak blokady';
      case RoadBlockingStatus.partialScreen:
        return 'Częściowe spowalnianie';
      case RoadBlockingStatus.fullRoadblock:
        return 'Pełna blokada szosy';
      case RoadBlockingStatus.breachedByRivals:
        return 'Blokada przełamana';
    }
  }
}

/// Pozycja boczna pojedynczego pomocnika tworzącego ścianę blokującą na czele grupy.
class BlockingRiderLateralSlot {
  final int slotIndex;

  /// Znormalizowana pozycja na szerokości szosy: -1.0 (lewa) .. 1.0 (prawa).
  final double normalizedLateralPosition;

  /// Przesunięcie boczne względem osi jezdni w metrach [m].
  final double lateralOffsetMeters;

  /// Docelowe tempo kolarza jako ułamek FTP (domyślnie ~0.65).
  final double targetFtpRatio;

  const BlockingRiderLateralSlot({
    required this.slotIndex,
    required this.normalizedLateralPosition,
    required this.lateralOffsetMeters,
    required this.targetFtpRatio,
  });

  Map<String, dynamic> toJson() {
    return {
      'slotIndex': slotIndex,
      'normalizedLateralPosition': normalizedLateralPosition,
      'lateralOffsetMeters': lateralOffsetMeters,
      'targetFtpRatio': targetFtpRatio,
    };
  }

  factory BlockingRiderLateralSlot.fromJson(Map<String, dynamic> json) {
    return BlockingRiderLateralSlot(
      slotIndex: (json['slotIndex'] as num).toInt(),
      normalizedLateralPosition:
          (json['normalizedLateralPosition'] as num).toDouble(),
      lateralOffsetMeters: (json['lateralOffsetMeters'] as num).toDouble(),
      targetFtpRatio: (json['targetFtpRatio'] as num).toDouble(),
    );
  }
}

/// Dane wejściowe do oceny mechaniki blokowania pogoni przez drużynę lidera.
class RoadBlockingInput {
  /// Szerokość jezdni w metrach [m]. Blokada jest skuteczna przy < 4.5 m.
  final double roadWidthMeters;

  /// Nachylenie drogi w procentach [%].
  final double gradientPercent;

  /// Identyfikator drużyny stosującej blokadę.
  final String blockingTeamId;

  /// Nazwa drużyny stosującej blokadę.
  final String blockingTeamName;

  /// Czy drużyna ma kolegę z ekipy w ucieczce przed grupą pościgową.
  final bool hasTeammateInBreakaway;

  /// Aktualna przewaga ucieczki nad grupą w sekundach [s].
  final double breakawayGapSeconds;

  /// Liczba pomocników ustawionych szeroko na czele grupy.
  final int domestiquesAtFrontCount;

  /// Ustawione tempo drużyny blokującej względem FTP (np. 0.65 = 65% FTP).
  final double blockingPaceFtpRatio;

  /// Stopień rozstawienia pomocników na szerokość jezdni (0.0 - 1.0).
  final double formationSpreadNormalized;

  /// Liczba kolarzy rywali próbujących zorganizować pościg za plecami blokady.
  final int rivalChaseCommitmentCount;

  /// Docelowe tempo pogoni, jakie chcieliby narzucić rywale (np. 0.90 = 90% FTP).
  final double rivalDesiredChaseFtpRatio;

  /// Planowane tempo odrabiania strat przez rywali bez blokady [s/10km].
  final double rivalPlannedClawbackSecondsPer10Km;

  const RoadBlockingInput({
    required this.roadWidthMeters,
    this.gradientPercent = 0.0,
    required this.blockingTeamId,
    required this.blockingTeamName,
    required this.hasTeammateInBreakaway,
    required this.breakawayGapSeconds,
    required this.domestiquesAtFrontCount,
    this.blockingPaceFtpRatio =
        DomestiqueRoadBlockingMechanics.optimalBlockingPaceFtpRatio,
    this.formationSpreadNormalized = 1.0,
    this.rivalChaseCommitmentCount = 3,
    this.rivalDesiredChaseFtpRatio = 0.90,
    this.rivalPlannedClawbackSecondsPer10Km = 45.0,
  });

  RoadBlockingInput copyWith({
    double? roadWidthMeters,
    double? gradientPercent,
    String? blockingTeamId,
    String? blockingTeamName,
    bool? hasTeammateInBreakaway,
    double? breakawayGapSeconds,
    int? domestiquesAtFrontCount,
    double? blockingPaceFtpRatio,
    double? formationSpreadNormalized,
    int? rivalChaseCommitmentCount,
    double? rivalDesiredChaseFtpRatio,
    double? rivalPlannedClawbackSecondsPer10Km,
  }) {
    return RoadBlockingInput(
      roadWidthMeters: roadWidthMeters ?? this.roadWidthMeters,
      gradientPercent: gradientPercent ?? this.gradientPercent,
      blockingTeamId: blockingTeamId ?? this.blockingTeamId,
      blockingTeamName: blockingTeamName ?? this.blockingTeamName,
      hasTeammateInBreakaway:
          hasTeammateInBreakaway ?? this.hasTeammateInBreakaway,
      breakawayGapSeconds: breakawayGapSeconds ?? this.breakawayGapSeconds,
      domestiquesAtFrontCount:
          domestiquesAtFrontCount ?? this.domestiquesAtFrontCount,
      blockingPaceFtpRatio: blockingPaceFtpRatio ?? this.blockingPaceFtpRatio,
      formationSpreadNormalized:
          formationSpreadNormalized ?? this.formationSpreadNormalized,
      rivalChaseCommitmentCount:
          rivalChaseCommitmentCount ?? this.rivalChaseCommitmentCount,
      rivalDesiredChaseFtpRatio:
          rivalDesiredChaseFtpRatio ?? this.rivalDesiredChaseFtpRatio,
      rivalPlannedClawbackSecondsPer10Km: rivalPlannedClawbackSecondsPer10Km ??
          this.rivalPlannedClawbackSecondsPer10Km,
    );
  }
}

/// Wynik ewaluacji blokowania drogi przez pomocników drużyny lidera.
class RoadBlockingEvaluationResult {
  final RoadBlockingStatus status;
  final bool isRoadNarrowEnough;
  final bool isBlockingActive;
  final double roadWidthMeters;

  /// Stopień zajęcia szerokości drogi przez ścianę pomocników (0.0 - 1.0).
  final double blockadeCoverageRatio;

  /// Pozostały wolny korytarz boczny dla rywali [m].
  final double overtakeGapWidthMeters;

  /// Czy rywale mogą bezpiecznie przecisnąć się obok blokady.
  final bool canRivalSqueezePast;

  /// Współczynnik dezorganizacji pogoni rywali (0.0 = brak, 0.80 = silna blokada).
  final double chaseDisruptionFactor;

  /// Efektywność pościgu rywali po uwzględnieniu blokady (0.20 - 1.0).
  final double chaseEfficiencyMultiplier;

  /// Efektywne tempo czoła grupy względem FTP.
  final double effectivePelotonPaceFtpRatio;

  /// Skorygowane tempo odrabiania strat przez pościg [s/10km].
  final double effectiveClawbackSecondsPer10Km;

  /// Dodatkowy koszt mocy [W] potrzebny rywalowi na wyprzedzenie poboczem.
  final int gutterSurgeExtraWattsRequired;

  /// Rozmieszczenie boczne pomocników na szosie dla silnika Boids / 3D.
  final List<BlockingRiderLateralSlot> blockingSlots;

  /// Komunikat radia wyścigowego opisujący sytuację na szosie.
  final String radioCommentary;

  const RoadBlockingEvaluationResult({
    required this.status,
    required this.isRoadNarrowEnough,
    required this.isBlockingActive,
    required this.roadWidthMeters,
    required this.blockadeCoverageRatio,
    required this.overtakeGapWidthMeters,
    required this.canRivalSqueezePast,
    required this.chaseDisruptionFactor,
    required this.chaseEfficiencyMultiplier,
    required this.effectivePelotonPaceFtpRatio,
    required this.effectiveClawbackSecondsPer10Km,
    required this.gutterSurgeExtraWattsRequired,
    required this.blockingSlots,
    required this.radioCommentary,
  });

  Map<String, dynamic> toJson() {
    return {
      'status': status.toJson(),
      'isRoadNarrowEnough': isRoadNarrowEnough,
      'isBlockingActive': isBlockingActive,
      'roadWidthMeters': roadWidthMeters,
      'blockadeCoverageRatio': blockadeCoverageRatio,
      'overtakeGapWidthMeters': overtakeGapWidthMeters,
      'canRivalSqueezePast': canRivalSqueezePast,
      'chaseDisruptionFactor': chaseDisruptionFactor,
      'chaseEfficiencyMultiplier': chaseEfficiencyMultiplier,
      'effectivePelotonPaceFtpRatio': effectivePelotonPaceFtpRatio,
      'effectiveClawbackSecondsPer10Km': effectiveClawbackSecondsPer10Km,
      'gutterSurgeExtraWattsRequired': gutterSurgeExtraWattsRequired,
      'blockingSlots': blockingSlots.map((s) => s.toJson()).toList(),
      'radioCommentary': radioCommentary,
    };
  }
}

/// Mechanika blokowania pogoni przez drużynę lidera na wąskich drogach (< 4.5 m).
///
/// Gdy drużyna ma kolarza w ucieczce i jedzie szeroko na czele peletonu
/// z nisko ustawionym tempem (~65% FTP), rywale nie mogą łatwo ustawić
/// własnego pociągu pościgowego na wąskiej szosie.
class DomestiqueRoadBlockingMechanics {
  /// Próg wąskiej drogi pozwalającej na skuteczne blokowanie szosy [m].
  static const double narrowRoadThresholdMeters = 4.5;

  /// Optymalne niskie tempo blokowania na czele grupy (65% FTP).
  static const double optimalBlockingPaceFtpRatio = 0.65;

  /// Maksymalne tempo, przy którym blokada wciąż wyraźnie spowalnia pogoń.
  static const double maxEffectiveBlockingPaceFtpRatio = 0.78;

  /// Efektywna szerokość zajmowana przez jednego kolarza z buforem bocznym [m].
  static const double riderEffectiveWidthMeters = 0.85;

  /// Minimalny korytarz potrzebny rywalom do płynnego wyprzedzania bokiem [m].
  static const double minSafeOvertakeCorridorMeters = 0.90;

  const DomestiqueRoadBlockingMechanics();

  /// Oblicza pełny wpływ taktycznej blokady na organizację i tempo pogoni.
  RoadBlockingEvaluationResult evaluateBlocking(RoadBlockingInput input) {
    final safeRoadWidth = input.roadWidthMeters.clamp(2.0, 12.0);
    final isNarrowRoad = safeRoadWidth < narrowRoadThresholdMeters;
    final clampedSpread = input.formationSpreadNormalized.clamp(0.0, 1.0);
    final clampedPace = input.blockingPaceFtpRatio.clamp(0.45, 1.15);
    final riderCount = math.max(0, input.domestiquesAtFrontCount);

    if (!input.hasTeammateInBreakaway ||
        input.breakawayGapSeconds <= 0.0 ||
        riderCount <= 0) {
      return RoadBlockingEvaluationResult(
        status: RoadBlockingStatus.inactive,
        isRoadNarrowEnough: isNarrowRoad,
        isBlockingActive: false,
        roadWidthMeters: safeRoadWidth,
        blockadeCoverageRatio: 0.0,
        overtakeGapWidthMeters: safeRoadWidth,
        canRivalSqueezePast: true,
        chaseDisruptionFactor: 0.0,
        chaseEfficiencyMultiplier: 1.0,
        effectivePelotonPaceFtpRatio: input.rivalDesiredChaseFtpRatio,
        effectiveClawbackSecondsPer10Km:
            input.rivalPlannedClawbackSecondsPer10Km,
        gutterSurgeExtraWattsRequired: 0,
        blockingSlots: const [],
        radioCommentary:
            'Brak podstaw do blokowania pogoni — rywale organizują swobodną zmianę.',
      );
    }

    if (!isNarrowRoad) {
      return RoadBlockingEvaluationResult(
        status: RoadBlockingStatus.inactive,
        isRoadNarrowEnough: false,
        isBlockingActive: false,
        roadWidthMeters: safeRoadWidth,
        blockadeCoverageRatio: math.min(
          1.0,
          (riderCount * riderEffectiveWidthMeters * clampedSpread) /
              safeRoadWidth,
        ),
        overtakeGapWidthMeters: math.max(
          0.0,
          safeRoadWidth - (riderCount * riderEffectiveWidthMeters * 0.6),
        ),
        canRivalSqueezePast: true,
        chaseDisruptionFactor: 0.0,
        chaseEfficiencyMultiplier: 1.0,
        effectivePelotonPaceFtpRatio: input.rivalDesiredChaseFtpRatio,
        effectiveClawbackSecondsPer10Km:
            input.rivalPlannedClawbackSecondsPer10Km,
        gutterSurgeExtraWattsRequired: 0,
        blockingSlots: computeBlockingSlots(
          domestiquesCount: riderCount,
          roadWidthMeters: safeRoadWidth,
          spreadNormalized: clampedSpread,
          targetFtpRatio: clampedPace,
        ),
        radioCommentary:
            'Szosa ma ${safeRoadWidth.toStringAsFixed(1)} m szerokości — za szeroko na blokadę, rywale bez problemu wychodzą bokiem.',
      );
    }

    final coveredWidth =
        riderCount * riderEffectiveWidthMeters * (0.45 + 0.55 * clampedSpread);
    final coverageRatio = (coveredWidth / safeRoadWidth).clamp(0.0, 1.0);
    final freeGapWidth = math.max(0.0, safeRoadWidth - coveredWidth);

    final paceSuppression = _computePaceSuppressionFactor(clampedPace);
    final climbPenaltyFactor = _computeClimbPenaltyFactor(input.gradientPercent);
    final rivalPressure = _computeRivalPressureFactor(
      rivalCount: input.rivalChaseCommitmentCount,
      freeGapWidth: freeGapWidth,
    );

    final rawDisruption =
        coverageRatio * paceSuppression * climbPenaltyFactor * rivalPressure;
    final disruptionFactor = rawDisruption.clamp(0.0, 0.80);
    final efficiencyMultiplier = (1.0 - disruptionFactor).clamp(0.20, 1.0);

    final canSqueezePast = freeGapWidth >= minSafeOvertakeCorridorMeters ||
        (input.rivalChaseCommitmentCount >= 5 && freeGapWidth >= 0.65);

    final RoadBlockingStatus status;
    if (disruptionFactor < 0.12) {
      status = RoadBlockingStatus.breachedByRivals;
    } else if (coverageRatio >= 0.72 &&
        clampedPace <= 0.72 &&
        !canSqueezePast) {
      status = RoadBlockingStatus.fullRoadblock;
    } else {
      status = RoadBlockingStatus.partialScreen;
    }

    final effectivePace = _blendPelotonPace(
      blockingPaceFtpRatio: clampedPace,
      rivalDesiredFtpRatio: input.rivalDesiredChaseFtpRatio,
      disruptionFactor: disruptionFactor,
    );

    final effectiveClawback =
        _computeEffectiveClawback(
          plannedClawbackSecondsPer10Km:
              input.rivalPlannedClawbackSecondsPer10Km,
          efficiencyMultiplier: efficiencyMultiplier,
          blockingPaceFtpRatio: clampedPace,
        );

    final extraWatts = _computeGutterSurgeWatts(
      freeGapWidth: freeGapWidth,
      disruptionFactor: disruptionFactor,
    );

    final slots = computeBlockingSlots(
      domestiquesCount: riderCount,
      roadWidthMeters: safeRoadWidth,
      spreadNormalized: clampedSpread,
      targetFtpRatio: clampedPace,
    );

    final commentary = _buildRadioCommentary(
      teamName: input.blockingTeamName,
      status: status,
      roadWidthMeters: safeRoadWidth,
      pacePercent: (clampedPace * 100).round(),
      disruptionPercent: (disruptionFactor * 100).round(),
    );

    return RoadBlockingEvaluationResult(
      status: status,
      isRoadNarrowEnough: true,
      isBlockingActive: status == RoadBlockingStatus.fullRoadblock ||
          status == RoadBlockingStatus.partialScreen,
      roadWidthMeters: safeRoadWidth,
      blockadeCoverageRatio: coverageRatio,
      overtakeGapWidthMeters: freeGapWidth,
      canRivalSqueezePast: canSqueezePast,
      chaseDisruptionFactor: disruptionFactor,
      chaseEfficiencyMultiplier: efficiencyMultiplier,
      effectivePelotonPaceFtpRatio: effectivePace,
      effectiveClawbackSecondsPer10Km: effectiveClawback,
      gutterSurgeExtraWattsRequired: extraWatts,
      blockingSlots: slots,
      radioCommentary: commentary,
    );
  }

  /// Wyznacza boczne sloty na jezdni dla pomocników jadących szeroko na czele.
  List<BlockingRiderLateralSlot> computeBlockingSlots({
    required int domestiquesCount,
    required double roadWidthMeters,
    required double spreadNormalized,
    double targetFtpRatio = optimalBlockingPaceFtpRatio,
  }) {
    if (domestiquesCount <= 0) return const [];
    final safeWidth = roadWidthMeters.clamp(2.0, 12.0);
    final spread = spreadNormalized.clamp(0.15, 1.0);
    final maxHalfSpanNormalized = 0.88 * spread;

    if (domestiquesCount == 1) {
      return [
        BlockingRiderLateralSlot(
          slotIndex: 0,
          normalizedLateralPosition: 0.0,
          lateralOffsetMeters: 0.0,
          targetFtpRatio: targetFtpRatio,
        ),
      ];
    }

    return List<BlockingRiderLateralSlot>.generate(domestiquesCount, (index) {
      final t = index / (domestiquesCount - 1);
      final normalized =
          (-maxHalfSpanNormalized) + (2.0 * maxHalfSpanNormalized * t);
      return BlockingRiderLateralSlot(
        slotIndex: index,
        normalizedLateralPosition: normalized,
        lateralOffsetMeters: normalized * (safeWidth * 0.5),
        targetFtpRatio: targetFtpRatio,
      );
    });
  }

  /// Aplikuje wynik blokady drogowej do istniejącego planu pościgu [PelotonChasePlan].
  PelotonChasePlan applyToChasePlan({
    required PelotonChasePlan basePlan,
    required RoadBlockingEvaluationResult blockingResult,
  }) {
    if (!blockingResult.isBlockingActive) {
      return basePlan;
    }

    final adjustedClawback =
        basePlan.actualClawbackSecondsPer10Km *
        blockingResult.chaseEfficiencyMultiplier;
    final survivalBoost = blockingResult.chaseDisruptionFactor * 0.35;
    final adjustedSurvival =
        (basePlan.breakawaySurvivalProbability + survivalBoost).clamp(0.0, 1.0);

    return PelotonChasePlan(
      urgency: basePlan.urgency,
      targetCatchKmRemaining: basePlan.targetCatchKmRemaining,
      projectedCatchKm: basePlan.projectedCatchKm,
      requiredClawbackSecondsPer10Km: basePlan.requiredClawbackSecondsPer10Km,
      actualClawbackSecondsPer10Km: adjustedClawback,
      aiMiscalculationFactor: basePlan.aiMiscalculationFactor,
      breakawaySurvivalProbability: adjustedSurvival,
      committedTeams: basePlan.committedTeams,
      radioReport: '${basePlan.radioReport} ${blockingResult.radioCommentary}',
    );
  }

  double _computePaceSuppressionFactor(double paceFtpRatio) {
    if (paceFtpRatio <= optimalBlockingPaceFtpRatio) {
      return 1.0;
    }
    if (paceFtpRatio >= maxEffectiveBlockingPaceFtpRatio) {
      return 0.15;
    }
    final t = (paceFtpRatio - optimalBlockingPaceFtpRatio) /
        (maxEffectiveBlockingPaceFtpRatio - optimalBlockingPaceFtpRatio);
    return (1.0 - 0.85 * t).clamp(0.15, 1.0);
  }

  double _computeClimbPenaltyFactor(double gradientPercent) {
    if (gradientPercent <= 3.0) return 1.0;
    if (gradientPercent >= 12.0) return 0.55;
    final t = (gradientPercent - 3.0) / 9.0;
    return (1.0 - 0.45 * t).clamp(0.55, 1.0);
  }

  double _computeRivalPressureFactor({
    required int rivalCount,
    required double freeGapWidth,
  }) {
    if (freeGapWidth < 0.50) {
      return 1.0;
    }
    if (rivalCount >= 5 && freeGapWidth >= minSafeOvertakeCorridorMeters) {
      return 0.55;
    }
    if (rivalCount >= 3 && freeGapWidth >= minSafeOvertakeCorridorMeters) {
      return 0.72;
    }
    return 0.90;
  }

  double _blendPelotonPace({
    required double blockingPaceFtpRatio,
    required double rivalDesiredFtpRatio,
    required double disruptionFactor,
  }) {
    final targetRival = math.max(blockingPaceFtpRatio, rivalDesiredFtpRatio);
    return targetRival -
        ((targetRival - blockingPaceFtpRatio) * disruptionFactor);
  }

  double _computeEffectiveClawback({
    required double plannedClawbackSecondsPer10Km,
    required double efficiencyMultiplier,
    required double blockingPaceFtpRatio,
  }) {
    final baseScaled = plannedClawbackSecondsPer10Km * efficiencyMultiplier;
    if (blockingPaceFtpRatio <= 0.68 && efficiencyMultiplier <= 0.45) {
      return math.min(baseScaled, plannedClawbackSecondsPer10Km * 0.35);
    }
    return baseScaled;
  }

  int _computeGutterSurgeWatts({
    required double freeGapWidth,
    required double disruptionFactor,
  }) {
    if (disruptionFactor <= 0.10) return 0;
    final gapTightness = (1.0 - (freeGapWidth / 1.5)).clamp(0.0, 1.0);
    return (35 + (145 * gapTightness * disruptionFactor)).round();
  }

  String _buildRadioCommentary({
    required String teamName,
    required RoadBlockingStatus status,
    required double roadWidthMeters,
    required int pacePercent,
    required int disruptionPercent,
  }) {
    final widthText = roadWidthMeters.toStringAsFixed(1);
    switch (status) {
      case RoadBlockingStatus.fullRoadblock:
        return 'Ekipa $teamName zamknęła wąską drogę ($widthText m) na całej szerokości przy $pacePercent% FTP — pogoń rywali sparaliżowana (-$disruptionPercent% tempa)!';
      case RoadBlockingStatus.partialScreen:
        return 'Pomocnicy $teamName jadą szeroko na drodze $widthText m ($pacePercent% FTP), skutecznie wybijając rywali z rytmu (-$disruptionPercent%).';
      case RoadBlockingStatus.breachedByRivals:
        return 'Rywale znaleźli lukę przy krawężniku na drodze $widthText m i przełamują zasłonę $teamName.';
      case RoadBlockingStatus.inactive:
        return 'Brak aktywnej blokady na szosie.';
    }
  }
}
