import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Faza realizacji taktyki surfowania sprintera po kołach pociągów rywali.
enum CounterSurfPhase {
  /// Poza strefą ostatnich 3 km lub oczekiwanie na uformowanie pociągów.
  standby,

  /// Skanowanie pociągów rywali pod kątem prędkości, pozycji i luki na kole.
  scanningTrains,

  /// Dojazd i walka o pozycję na wybranym kole rywala.
  approachingWheel,

  /// Jazda w tunelu aerodynamicznym bezpośrednio na kole pociągu rywala.
  draftingRivalWheel,

  /// Dynamiczny przeskok (Wheel Hop) z jednego pociągu rywala na lepszy pociąg obok.
  wheelHopping,

  /// Uwięzienie przy barierkach (Boxed In) — szukanie wolnego korytarza.
  boxedInRecovery,

  /// Wyskoczenie z koła rywala na ostatnich ~220 m do pełnego sprintu (Slingshot).
  slingshotLaunch,

  /// Przekroczono linię mety.
  completed;

  String get labelPl {
    switch (this) {
      case CounterSurfPhase.standby:
        return 'Gotowość (>3 km)';
      case CounterSurfPhase.scanningTrains:
        return 'Skanowanie Pociągów';
      case CounterSurfPhase.approachingWheel:
        return 'Walka o Koło';
      case CounterSurfPhase.draftingRivalWheel:
        return 'Surfing w Tunelu';
      case CounterSurfPhase.wheelHopping:
        return 'Przeskok (Wheel Hop)';
      case CounterSurfPhase.boxedInRecovery:
        return 'Zamknięcie (Boxed In)';
      case CounterSurfPhase.slingshotLaunch:
        return 'Proca na Metę!';
      case CounterSurfPhase.completed:
        return 'Meta Osiągnięta';
    }
  }

  String toJson() => name;

  static CounterSurfPhase fromJson(String value) {
    return CounterSurfPhase.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CounterSurfPhase.standby,
    );
  }
}

/// Poziom agresywności sprintera podczas surfowania po pociągach rywali.
enum CounterSurfAggression {
  /// Cierpliwe czekanie na otwartą lukę, minimalne straty W'.
  patientShadow(
    labelPl: 'Cierpliwy Cień',
    riskTolerance: 0.35,
    battleBonus: -4.0,
    hopThresholdDelta: 12.0,
  ),

  /// Zbalansowane surfowanie między pociągami i walka o optymalne koło.
  balancedSurfer(
    labelPl: 'Zbalansowany Surfer',
    riskTolerance: 0.55,
    battleBonus: 2.0,
    hopThresholdDelta: 8.0,
  ),

  /// Agresywne wpychanie się na koła liderów i szybkie przeskoki.
  aggressiveWheelThief(
    labelPl: 'Agresywny Złodziej Koła',
    riskTolerance: 0.80,
    battleBonus: 9.0,
    hopThresholdDelta: 5.0,
  );

  final String labelPl;
  final double riskTolerance;
  final double battleBonus;
  final double hopThresholdDelta;

  const CounterSurfAggression({
    required this.labelPl,
    required this.riskTolerance,
    required this.battleBonus,
    required this.hopThresholdDelta,
  });

  String toJson() => name;

  static CounterSurfAggression fromJson(String value) {
    return CounterSurfAggression.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CounterSurfAggression.balancedSurfer,
    );
  }
}

/// Przyczyna zmiany docelowego pociągu rywala (Wheel Hop).
enum WheelHopReason {
  /// Brak zmiany — utrzymanie bieżącego koła.
  none,

  /// Rozprowadzający rywala traci moc i pociąg zwalnia.
  leadoutFading,

  /// Sąsiedni pociąg rywala wyprzedza z wyraźnie wyższą prędkością.
  fasterTrainOvertaking,

  /// Ryzyko zamknięcia przy barierkach na aktualnym torze jazdy.
  barrierBoxRisk,

  /// Sąsiedni pociąg zapewnia lepszą osłonę przed wiatrem bocznym.
  crosswindShelterBetter,

  /// Ręczne wskazanie koła przez dyrektora sportowego.
  manualDirectorOrder;

  String get labelPl {
    switch (this) {
      case WheelHopReason.none:
        return 'Stabilne koło';
      case WheelHopReason.leadoutFading:
        return 'Słabnący rozprowadzający';
      case WheelHopReason.fasterTrainOvertaking:
        return 'Szybszy pociąg obok';
      case WheelHopReason.barrierBoxRisk:
        return 'Unik przed barierką';
      case WheelHopReason.crosswindShelterBetter:
        return 'Lepszy wachlarz wiatrowy';
      case WheelHopReason.manualDirectorOrder:
        return 'Rozkaz Dyrektora';
    }
  }

  String toJson() => name;

  static WheelHopReason fromJson(String value) {
    return WheelHopReason.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => WheelHopReason.none,
    );
  }
}

/// Ocena jakości koła pociągu rywala.
enum SurfTargetQuality {
  prime,
  solid,
  risky,
  fading;

  String get labelPl {
    switch (this) {
      case SurfTargetQuality.prime:
        return 'Złote Koło';
      case SurfTargetQuality.solid:
        return 'Pewne Koło';
      case SurfTargetQuality.risky:
        return 'Ryzykowne';
      case SurfTargetQuality.fading:
        return 'Gasnące';
    }
  }

  String toJson() => name;

  static SurfTargetQuality fromJson(String value) {
    return SurfTargetQuality.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SurfTargetQuality.solid,
    );
  }
}

/// Migawka stanu konkurencyjnego pociągu sprinterskiego na ostatnich 3 km.
class RivalTrainSnapshot {
  final String teamId;
  final String teamName;
  final String targetSprinterId;
  final String targetSprinterName;
  final String activeLeadoutRiderId;
  final int remainingHelpers;
  final double trainSpeedKmh;
  final double lateralRoadPosition;
  final int leadoutPowerWatts;
  final double leadoutFatigueFraction;
  final bool wheelGapOpen;
  final int rivalWheelDefenseSkill;

  const RivalTrainSnapshot({
    required this.teamId,
    required this.teamName,
    required this.targetSprinterId,
    required this.targetSprinterName,
    required this.activeLeadoutRiderId,
    required this.remainingHelpers,
    required this.trainSpeedKmh,
    required this.lateralRoadPosition,
    required this.leadoutPowerWatts,
    required this.leadoutFatigueFraction,
    required this.wheelGapOpen,
    required this.rivalWheelDefenseSkill,
  });

  RivalTrainSnapshot copyWith({
    String? teamId,
    String? teamName,
    String? targetSprinterId,
    String? targetSprinterName,
    String? activeLeadoutRiderId,
    int? remainingHelpers,
    double? trainSpeedKmh,
    double? lateralRoadPosition,
    int? leadoutPowerWatts,
    double? leadoutFatigueFraction,
    bool? wheelGapOpen,
    int? rivalWheelDefenseSkill,
  }) {
    return RivalTrainSnapshot(
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      targetSprinterId: targetSprinterId ?? this.targetSprinterId,
      targetSprinterName: targetSprinterName ?? this.targetSprinterName,
      activeLeadoutRiderId: activeLeadoutRiderId ?? this.activeLeadoutRiderId,
      remainingHelpers: remainingHelpers ?? this.remainingHelpers,
      trainSpeedKmh: trainSpeedKmh ?? this.trainSpeedKmh,
      lateralRoadPosition: lateralRoadPosition ?? this.lateralRoadPosition,
      leadoutPowerWatts: leadoutPowerWatts ?? this.leadoutPowerWatts,
      leadoutFatigueFraction:
          leadoutFatigueFraction ?? this.leadoutFatigueFraction,
      wheelGapOpen: wheelGapOpen ?? this.wheelGapOpen,
      rivalWheelDefenseSkill:
          rivalWheelDefenseSkill ?? this.rivalWheelDefenseSkill,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'teamId': teamId,
      'teamName': teamName,
      'targetSprinterId': targetSprinterId,
      'targetSprinterName': targetSprinterName,
      'activeLeadoutRiderId': activeLeadoutRiderId,
      'remainingHelpers': remainingHelpers,
      'trainSpeedKmh': trainSpeedKmh,
      'lateralRoadPosition': lateralRoadPosition,
      'leadoutPowerWatts': leadoutPowerWatts,
      'leadoutFatigueFraction': leadoutFatigueFraction,
      'wheelGapOpen': wheelGapOpen,
      'rivalWheelDefenseSkill': rivalWheelDefenseSkill,
    };
  }

  factory RivalTrainSnapshot.fromJson(Map<String, dynamic> json) {
    return RivalTrainSnapshot(
      teamId: json['teamId'] as String,
      teamName: json['teamName'] as String,
      targetSprinterId: json['targetSprinterId'] as String,
      targetSprinterName: json['targetSprinterName'] as String,
      activeLeadoutRiderId: json['activeLeadoutRiderId'] as String,
      remainingHelpers: (json['remainingHelpers'] as num).toInt(),
      trainSpeedKmh: (json['trainSpeedKmh'] as num).toDouble(),
      lateralRoadPosition: (json['lateralRoadPosition'] as num).toDouble(),
      leadoutPowerWatts: (json['leadoutPowerWatts'] as num).toInt(),
      leadoutFatigueFraction:
          (json['leadoutFatigueFraction'] as num).toDouble(),
      wheelGapOpen: json['wheelGapOpen'] as bool? ?? true,
      rivalWheelDefenseSkill: (json['rivalWheelDefenseSkill'] as num).toInt(),
    );
  }
}

/// Profil sprintera realizującego taktykę surfowania po kołach rywali.
class SprinterSurfProfile {
  final String riderId;
  final String riderName;
  final int ftpWatts;
  final int power5sWatts;
  final int sprintSkill;
  final int bikeHandling;
  final int raceIq;
  final int aggression;
  final double wPrimeTotalJoules;
  final double wPrimeRemainingJoules;
  final double currentLateralPosition;
  final double currentSpeedKmh;

  const SprinterSurfProfile({
    required this.riderId,
    required this.riderName,
    required this.ftpWatts,
    required this.power5sWatts,
    required this.sprintSkill,
    required this.bikeHandling,
    required this.raceIq,
    required this.aggression,
    required this.wPrimeTotalJoules,
    required this.wPrimeRemainingJoules,
    required this.currentLateralPosition,
    required this.currentSpeedKmh,
  });

  double get wPrimeRemainingFraction {
    if (wPrimeTotalJoules <= 0.0) {
      return 0.0;
    }
    return (wPrimeRemainingJoules / wPrimeTotalJoules).clamp(0.0, 1.0);
  }

  SprinterSurfProfile copyWith({
    String? riderId,
    String? riderName,
    int? ftpWatts,
    int? power5sWatts,
    int? sprintSkill,
    int? bikeHandling,
    int? raceIq,
    int? aggression,
    double? wPrimeTotalJoules,
    double? wPrimeRemainingJoules,
    double? currentLateralPosition,
    double? currentSpeedKmh,
  }) {
    return SprinterSurfProfile(
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      ftpWatts: ftpWatts ?? this.ftpWatts,
      power5sWatts: power5sWatts ?? this.power5sWatts,
      sprintSkill: sprintSkill ?? this.sprintSkill,
      bikeHandling: bikeHandling ?? this.bikeHandling,
      raceIq: raceIq ?? this.raceIq,
      aggression: aggression ?? this.aggression,
      wPrimeTotalJoules: wPrimeTotalJoules ?? this.wPrimeTotalJoules,
      wPrimeRemainingJoules:
          wPrimeRemainingJoules ?? this.wPrimeRemainingJoules,
      currentLateralPosition:
          currentLateralPosition ?? this.currentLateralPosition,
      currentSpeedKmh: currentSpeedKmh ?? this.currentSpeedKmh,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'riderName': riderName,
      'ftpWatts': ftpWatts,
      'power5sWatts': power5sWatts,
      'sprintSkill': sprintSkill,
      'bikeHandling': bikeHandling,
      'raceIq': raceIq,
      'aggression': aggression,
      'wPrimeTotalJoules': wPrimeTotalJoules,
      'wPrimeRemainingJoules': wPrimeRemainingJoules,
      'currentLateralPosition': currentLateralPosition,
      'currentSpeedKmh': currentSpeedKmh,
    };
  }

  factory SprinterSurfProfile.fromJson(Map<String, dynamic> json) {
    return SprinterSurfProfile(
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      ftpWatts: (json['ftpWatts'] as num).toInt(),
      power5sWatts: (json['power5sWatts'] as num).toInt(),
      sprintSkill: (json['sprintSkill'] as num).toInt(),
      bikeHandling: (json['bikeHandling'] as num).toInt(),
      raceIq: (json['raceIq'] as num).toInt(),
      aggression: (json['aggression'] as num).toInt(),
      wPrimeTotalJoules: (json['wPrimeTotalJoules'] as num).toDouble(),
      wPrimeRemainingJoules: (json['wPrimeRemainingJoules'] as num).toDouble(),
      currentLateralPosition:
          (json['currentLateralPosition'] as num).toDouble(),
      currentSpeedKmh: (json['currentSpeedKmh'] as num).toDouble(),
    );
  }
}

/// Wynik punktowy i ocena taktyczna konkretnego pociągu rywala.
class RivalTrainEvaluation {
  final RivalTrainSnapshot train;
  final double score;
  final SurfTargetQuality quality;
  final double estimatedDraftSavingsPercent;
  final double wheelWinProbability;
  final double boxingRisk;
  final double lateralDistance;
  final String reasoning;

  const RivalTrainEvaluation({
    required this.train,
    required this.score,
    required this.quality,
    required this.estimatedDraftSavingsPercent,
    required this.wheelWinProbability,
    required this.boxingRisk,
    required this.lateralDistance,
    required this.reasoning,
  });
}

/// Dane wejściowe dla pojedynczego kroku decyzyjnego AI surfowania po kołach.
class CounterSurfStepInput {
  final SprinterSurfProfile sprinter;
  final List<RivalTrainSnapshot> rivalTrains;
  final double distanceToFinishMeters;

  /// Składowa wiatru bocznego (-1.0 z lewej na prawą, 0.0 brak, 1.0 z prawej na lewą).
  final double crosswindDirection;
  final CounterSurfAggression aggressionMode;
  final String? currentTargetTeamId;
  final CounterSurfPhase currentPhase;
  final double timeStepSeconds;
  final String? manualLockedTeamId;

  const CounterSurfStepInput({
    required this.sprinter,
    required this.rivalTrains,
    required this.distanceToFinishMeters,
    this.crosswindDirection = 0.0,
    this.aggressionMode = CounterSurfAggression.balancedSurfer,
    this.currentTargetTeamId,
    this.currentPhase = CounterSurfPhase.scanningTrains,
    this.timeStepSeconds = 1.0,
    this.manualLockedTeamId,
  });
}

/// Decyzja AI surfowania po kołach pociągów rywali w danym kroku symulacji.
class CounterSurfDecision {
  final CounterSurfPhase phase;
  final String? selectedTrainTeamId;
  final String? selectedTargetRiderId;
  final String? selectedTeamName;
  final WheelHopReason hopReason;
  final bool didWheelHop;
  final bool isBoxedIn;
  final bool isSlingshotReady;
  final double targetLateralPosition;
  final int targetWatts;
  final double estimatedDraftSavingsPercent;
  final double wPrimeDeltaJoules;
  final double newWPrimeRemainingJoules;
  final double wheelBattleScore;
  final List<RivalTrainEvaluation> evaluations;
  final String tacticalLog;

  const CounterSurfDecision({
    required this.phase,
    required this.selectedTrainTeamId,
    required this.selectedTargetRiderId,
    required this.selectedTeamName,
    required this.hopReason,
    required this.didWheelHop,
    required this.isBoxedIn,
    required this.isSlingshotReady,
    required this.targetLateralPosition,
    required this.targetWatts,
    required this.estimatedDraftSavingsPercent,
    required this.wPrimeDeltaJoules,
    required this.newWPrimeRemainingJoules,
    required this.wheelBattleScore,
    required this.evaluations,
    required this.tacticalLog,
  });
}

/// Silnik AI realizujący taktykę surfowania sprintera po kołach pociągów rywali (`Surf Rival Lead-out`).
///
/// Przeznaczony dla samotnego sprintera lub sprintera bez pełnego pociągu na ostatnich 3000 m:
/// skanuje konkurencyjne pociągi, wygrywa koło za pomocą `bikeHandling` i `raceIq`,
/// wykonuje dynamiczne przeskoki (`Wheel Hop`), unika zamknięcia przy barierkach (`Boxed In`)
/// oraz odpala końcowy sprint (`Slingshot Launch`) na ostatnich 220 m z pełnym zapasem W'.
class SprinterTrainCounterSurfingAi {
  SprinterTrainCounterSurfingAi._();

  static const double activationDistanceMeters = 3000.0;
  static const double slingshotLaunchDistanceMeters = 220.0;
  static const double barrierLeftEdge = -0.84;
  static const double barrierRightEdge = 0.84;
  static const double wheelBattleWinThreshold = 68.0;

  /// Ocenia wszystkie widoczne pociągi rywali i sortuje je malejąco według atrakcyjności koła.
  static List<RivalTrainEvaluation> evaluateRivalTrains({
    required SprinterSurfProfile sprinter,
    required List<RivalTrainSnapshot> rivalTrains,
    required double distanceToFinishMeters,
    required double crosswindDirection,
    required CounterSurfAggression aggressionMode,
  }) {
    if (rivalTrains.isEmpty) {
      return const [];
    }

    final double maxSpeed = rivalTrains
        .map((t) => t.trainSpeedKmh)
        .reduce((a, b) => math.max(a, b));

    final List<RivalTrainEvaluation> results = <RivalTrainEvaluation>[];
    for (final train in rivalTrains) {
      final double lateralDist =
          (train.lateralRoadPosition - sprinter.currentLateralPosition).abs();
      final double boxingRisk = _computeBoxingRisk(
        train: train,
        allTrains: rivalTrains,
      );

      // Prędkość pociągu względem najszybszego pociągu na szosie
      final double speedDelta = (maxSpeed - train.trainSpeedKmh).clamp(0.0, 12.0);
      final double speedScore = (40.0 - speedDelta * 3.5).clamp(8.0, 40.0);

      // Głębokość i świeżość pociągu
      final double depthScore = (train.remainingHelpers.clamp(0, 4) * 5.0) +
          ((1.0 - train.leadoutFatigueFraction.clamp(0.0, 1.0)) * 15.0);

      // Szansa na wygranie koła
      final double winProb = _computeWheelWinProbability(
        sprinter: sprinter,
        train: train,
        lateralDistance: lateralDist,
        aggressionMode: aggressionMode,
      );

      // Osłona przed wiatrem bocznym (im dalej na zawietrzną, tym lepiej)
      double crosswindBonus = 0.0;
      if (crosswindDirection.abs() > 0.15) {
        final bool onShelteredSide =
            (crosswindDirection > 0 && train.lateralRoadPosition > 0.1) ||
                (crosswindDirection < 0 && train.lateralRoadPosition < -0.1);
        crosswindBonus = onShelteredSide ? 7.5 : -3.5;
      }

      final double gapBonus = train.wheelGapOpen ? 10.0 : -6.0;
      final double lateralPenalty = lateralDist * 8.5;
      final double boxingPenalty =
          boxingRisk * (26.0 * (1.15 - aggressionMode.riskTolerance));

      final double rawScore = speedScore +
          depthScore +
          gapBonus +
          crosswindBonus +
          (winProb * 14.0) -
          lateralPenalty -
          boxingPenalty;
      final double clampedScore = rawScore.clamp(0.0, 100.0);

      final double draftSavings = _estimateDraftSavingsPercent(
        train: train,
        winProbability: winProb,
        crosswindDirection: crosswindDirection,
      );

      final SurfTargetQuality quality;
      if (train.leadoutFatigueFraction >= 0.78 || train.remainingHelpers == 0) {
        quality = SurfTargetQuality.fading;
      } else if (boxingRisk >= 0.62 || !train.wheelGapOpen && winProb < 0.55) {
        quality = SurfTargetQuality.risky;
      } else if (clampedScore >= 72.0) {
        quality = SurfTargetQuality.prime;
      } else {
        quality = SurfTargetQuality.solid;
      }

      final String reasoning = _buildEvaluationReasoning(
        train: train,
        quality: quality,
        boxingRisk: boxingRisk,
        draftSavings: draftSavings,
        distanceToFinishMeters: distanceToFinishMeters,
      );

      results.add(
        RivalTrainEvaluation(
          train: train,
          score: clampedScore,
          quality: quality,
          estimatedDraftSavingsPercent: draftSavings,
          wheelWinProbability: winProb,
          boxingRisk: boxingRisk,
          lateralDistance: lateralDist,
          reasoning: reasoning,
        ),
      );
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }

  /// Wyznacza decyzję taktyczną na pojedynczy krok symulacji wyścigu.
  static CounterSurfDecision evaluateStep(CounterSurfStepInput input) {
    final SprinterSurfProfile sprinter = input.sprinter;
    final double dt = math.max(0.1, input.timeStepSeconds);

    if (input.distanceToFinishMeters <= 0.0) {
      return CounterSurfDecision(
        phase: CounterSurfPhase.completed,
        selectedTrainTeamId: input.currentTargetTeamId,
        selectedTargetRiderId: null,
        selectedTeamName: null,
        hopReason: WheelHopReason.none,
        didWheelHop: false,
        isBoxedIn: false,
        isSlingshotReady: false,
        targetLateralPosition: sprinter.currentLateralPosition,
        targetWatts: (sprinter.ftpWatts * 0.55).round(),
        estimatedDraftSavingsPercent: 0.0,
        wPrimeDeltaJoules: 0.0,
        newWPrimeRemainingJoules: sprinter.wPrimeRemainingJoules,
        wheelBattleScore: 0.0,
        evaluations: const [],
        tacticalLog: 'Etap ukończony — sprinter minął linię mety.',
      );
    }

    if (input.distanceToFinishMeters > activationDistanceMeters) {
      final int cruiseWatts = (sprinter.ftpWatts * 0.68).round();
      return CounterSurfDecision(
        phase: CounterSurfPhase.standby,
        selectedTrainTeamId: null,
        selectedTargetRiderId: null,
        selectedTeamName: null,
        hopReason: WheelHopReason.none,
        didWheelHop: false,
        isBoxedIn: false,
        isSlingshotReady: false,
        targetLateralPosition: sprinter.currentLateralPosition,
        targetWatts: cruiseWatts,
        estimatedDraftSavingsPercent: 28.0,
        wPrimeDeltaJoules: 0.0,
        newWPrimeRemainingJoules: sprinter.wPrimeRemainingJoules,
        wheelBattleScore: 0.0,
        evaluations: const [],
        tacticalLog:
            'Oczekiwanie na strefę 3 km (${input.distanceToFinishMeters.toStringAsFixed(0)} m do mety).',
      );
    }

    final List<RivalTrainEvaluation> evaluations = evaluateRivalTrains(
      sprinter: sprinter,
      rivalTrains: input.rivalTrains,
      distanceToFinishMeters: input.distanceToFinishMeters,
      crosswindDirection: input.crosswindDirection,
      aggressionMode: input.aggressionMode,
    );

    if (evaluations.isEmpty) {
      final bool launch =
          input.distanceToFinishMeters <= slingshotLaunchDistanceMeters;
      final int soloWatts = launch
          ? sprinter.power5sWatts
          : (sprinter.ftpWatts * 0.94).round();
      final double wDelta = _computeWPrimeDelta(
        targetWatts: soloWatts,
        ftpWatts: sprinter.ftpWatts,
        dt: dt,
        currentWPrime: sprinter.wPrimeRemainingJoules,
        maxWPrime: sprinter.wPrimeTotalJoules,
      );
      return CounterSurfDecision(
        phase: launch
            ? CounterSurfPhase.slingshotLaunch
            : CounterSurfPhase.scanningTrains,
        selectedTrainTeamId: null,
        selectedTargetRiderId: null,
        selectedTeamName: null,
        hopReason: WheelHopReason.none,
        didWheelHop: false,
        isBoxedIn: false,
        isSlingshotReady: launch,
        targetLateralPosition: sprinter.currentLateralPosition,
        targetWatts: soloWatts,
        estimatedDraftSavingsPercent: 0.0,
        wPrimeDeltaJoules: wDelta,
        newWPrimeRemainingJoules: (sprinter.wPrimeRemainingJoules + wDelta)
            .clamp(0.0, sprinter.wPrimeTotalJoules),
        wheelBattleScore: 0.0,
        evaluations: const [],
        tacticalLog: launch
            ? 'Brak pociągów rywali — samotny finisz na pełnej mocy ($soloWatts W)!'
            : 'Brak aktywnych pociągów w zasięgu — jazda czujna z przodu peletonu.',
      );
    }

    // Wybór pociągu docelowego (z uwzględnieniem histerezy lub ręcznej blokady DS)
    final RivalTrainEvaluation? manualEval = input.manualLockedTeamId == null
        ? null
        : evaluations.cast<RivalTrainEvaluation?>().firstWhere(
              (e) => e!.train.teamId == input.manualLockedTeamId,
              orElse: () => null,
            );

    final RivalTrainEvaluation? currentEval = input.currentTargetTeamId == null
        ? null
        : evaluations.cast<RivalTrainEvaluation?>().firstWhere(
              (e) => e!.train.teamId == input.currentTargetTeamId,
              orElse: () => null,
            );

    final RivalTrainEvaluation bestEval = evaluations.first;
    RivalTrainEvaluation chosenEval = bestEval;
    WheelHopReason hopReason = WheelHopReason.none;
    bool didWheelHop = false;

    if (manualEval != null) {
      chosenEval = manualEval;
      if (input.currentTargetTeamId != null &&
          input.currentTargetTeamId != manualEval.train.teamId) {
        didWheelHop = true;
        hopReason = WheelHopReason.manualDirectorOrder;
      }
    } else if (currentEval != null &&
        currentEval.train.teamId != bestEval.train.teamId) {
      final double scoreGap = bestEval.score - currentEval.score;
      final bool mustEscapeBox =
          currentEval.boxingRisk >= 0.65 && bestEval.boxingRisk < 0.45;
      final bool currentFading =
          currentEval.quality == SurfTargetQuality.fading &&
              bestEval.quality != SurfTargetQuality.fading;

      if (mustEscapeBox) {
        chosenEval = bestEval;
        didWheelHop = true;
        hopReason = WheelHopReason.barrierBoxRisk;
      } else if (currentFading) {
        chosenEval = bestEval;
        didWheelHop = true;
        hopReason = WheelHopReason.leadoutFading;
      } else if (scoreGap >= input.aggressionMode.hopThresholdDelta) {
        chosenEval = bestEval;
        didWheelHop = true;
        hopReason = _inferHopReason(
          fromEval: currentEval,
          toEval: bestEval,
          crosswindDirection: input.crosswindDirection,
        );
      } else {
        chosenEval = currentEval;
      }
    }

    // Sprawdzenie zamknięcia przy barierkach
    final bool isBoxed = _isBoxedAtBarrier(
      sprinterLateralPos: sprinter.currentLateralPosition,
      targetTrain: chosenEval.train,
      allTrains: input.rivalTrains,
      sprinter: sprinter,
    );

    final double wheelBattleScore = _computeBattleScore(
      sprinter: sprinter,
      train: chosenEval.train,
      aggressionMode: input.aggressionMode,
    );

    final bool inSlingshotWindow =
        input.distanceToFinishMeters <= slingshotLaunchDistanceMeters;

    if (isBoxed) {
      final double escapeLateral = sprinter.currentLateralPosition < 0
          ? (sprinter.currentLateralPosition + 0.28).clamp(-1.0, 1.0)
          : (sprinter.currentLateralPosition - 0.28).clamp(-1.0, 1.0);
      final int recoveryWatts = (sprinter.ftpWatts * 0.82).round();
      final double wDelta = _computeWPrimeDelta(
        targetWatts: recoveryWatts,
        ftpWatts: sprinter.ftpWatts,
        dt: dt,
        currentWPrime: sprinter.wPrimeRemainingJoules,
        maxWPrime: sprinter.wPrimeTotalJoules,
      );
      return CounterSurfDecision(
        phase: CounterSurfPhase.boxedInRecovery,
        selectedTrainTeamId: chosenEval.train.teamId,
        selectedTargetRiderId: chosenEval.train.targetSprinterId,
        selectedTeamName: chosenEval.train.teamName,
        hopReason: hopReason,
        didWheelHop: didWheelHop,
        isBoxedIn: true,
        isSlingshotReady: false,
        targetLateralPosition: escapeLateral,
        targetWatts: recoveryWatts,
        estimatedDraftSavingsPercent: 24.0,
        wPrimeDeltaJoules: wDelta,
        newWPrimeRemainingJoules: (sprinter.wPrimeRemainingJoules + wDelta)
            .clamp(0.0, sprinter.wPrimeTotalJoules),
        wheelBattleScore: wheelBattleScore,
        evaluations: evaluations,
        tacticalLog:
            'Zamknięty przy barierce obok ${chosenEval.train.teamName}! Szukanie wyjścia na środek.',
      );
    }

    if (inSlingshotWindow) {
      final bool hasDraftBonus = chosenEval.lateralDistance <= 0.25 &&
          wheelBattleScore >= wheelBattleWinThreshold;
      final double launchMultiplier = hasDraftBonus ? 1.03 : 0.96;
      final double wPrimeScale =
          (0.65 + 0.35 * sprinter.wPrimeRemainingFraction).clamp(0.65, 1.0);
      final int sprintWatts =
          (sprinter.power5sWatts * launchMultiplier * wPrimeScale)
              .round()
              .clamp(850, 1850);
      final double wDelta = _computeWPrimeDelta(
        targetWatts: sprintWatts,
        ftpWatts: sprinter.ftpWatts,
        dt: dt,
        currentWPrime: sprinter.wPrimeRemainingJoules,
        maxWPrime: sprinter.wPrimeTotalJoules,
      );

      // Wyskakujemy na bok o 0.16 w stronę środka drogi, by ominąć pilota/rywala
      final double slingshotLateral = chosenEval.train.lateralRoadPosition > 0
          ? (chosenEval.train.lateralRoadPosition - 0.16).clamp(-1.0, 1.0)
          : (chosenEval.train.lateralRoadPosition + 0.16).clamp(-1.0, 1.0);

      return CounterSurfDecision(
        phase: CounterSurfPhase.slingshotLaunch,
        selectedTrainTeamId: chosenEval.train.teamId,
        selectedTargetRiderId: chosenEval.train.targetSprinterId,
        selectedTeamName: chosenEval.train.teamName,
        hopReason: hopReason,
        didWheelHop: didWheelHop,
        isBoxedIn: false,
        isSlingshotReady: true,
        targetLateralPosition: slingshotLateral,
        targetWatts: sprintWatts,
        estimatedDraftSavingsPercent: hasDraftBonus ? 18.0 : 0.0,
        wPrimeDeltaJoules: wDelta,
        newWPrimeRemainingJoules: (sprinter.wPrimeRemainingJoules + wDelta)
            .clamp(0.0, sprinter.wPrimeTotalJoules),
        wheelBattleScore: wheelBattleScore,
        evaluations: evaluations,
        tacticalLog: hasDraftBonus
            ? 'PROCA Z KOŁA ${chosenEval.train.targetSprinterName}! Wyskakuje zza ${chosenEval.train.teamName} ($sprintWatts W).'
            : 'Otwarcie finiszu z dalszej pozycji ($sprintWatts W).',
      );
    }

    // Faza podejścia, przeskoku lub jazdy w tunelu
    final bool alignedToWheel = chosenEval.lateralDistance <= 0.14;
    final CounterSurfPhase nextPhase;
    if (didWheelHop) {
      nextPhase = CounterSurfPhase.wheelHopping;
    } else if (alignedToWheel && wheelBattleScore >= wheelBattleWinThreshold) {
      nextPhase = CounterSurfPhase.draftingRivalWheel;
    } else {
      nextPhase = CounterSurfPhase.approachingWheel;
    }

    // Zapotrzebowanie mocy w tunelu vs podczas przeskoku/walki o koło
    final double baseCruisingRatio = nextPhase == CounterSurfPhase.draftingRivalWheel
        ? (1.0 - chosenEval.estimatedDraftSavingsPercent / 100.0) * 1.15
        : 1.04;
    final int targetWatts =
        (sprinter.ftpWatts * baseCruisingRatio.clamp(0.62, 1.22)).round();

    final double wDelta = _computeWPrimeDelta(
      targetWatts: targetWatts,
      ftpWatts: sprinter.ftpWatts,
      dt: dt,
      currentWPrime: sprinter.wPrimeRemainingJoules,
      maxWPrime: sprinter.wPrimeTotalJoules,
    );

    final double stepLateral = _moveTowards(
      current: sprinter.currentLateralPosition,
      target: chosenEval.train.lateralRoadPosition,
      maxDelta: 0.22 * dt,
    );

    final String log;
    if (didWheelHop) {
      log =
          'Przeskok na koło ${chosenEval.train.targetSprinterName} (${chosenEval.train.teamName}) — ${hopReason.labelPl}.';
    } else if (nextPhase == CounterSurfPhase.draftingRivalWheel) {
      log =
          'Surfuje w tunelu ${chosenEval.train.teamName} (oszczędność ${chosenEval.estimatedDraftSavingsPercent.toStringAsFixed(0)}% mocy).';
    } else {
      log =
          'Walka o koło ${chosenEval.train.targetSprinterName} (${chosenEval.train.teamName}, wynik ${wheelBattleScore.toStringAsFixed(0)}/100).';
    }

    return CounterSurfDecision(
      phase: nextPhase,
      selectedTrainTeamId: chosenEval.train.teamId,
      selectedTargetRiderId: chosenEval.train.targetSprinterId,
      selectedTeamName: chosenEval.train.teamName,
      hopReason: hopReason,
      didWheelHop: didWheelHop,
      isBoxedIn: false,
      isSlingshotReady: false,
      targetLateralPosition: stepLateral,
      targetWatts: targetWatts,
      estimatedDraftSavingsPercent: chosenEval.estimatedDraftSavingsPercent,
      wPrimeDeltaJoules: wDelta,
      newWPrimeRemainingJoules: (sprinter.wPrimeRemainingJoules + wDelta)
          .clamp(0.0, sprinter.wPrimeTotalJoules),
      wheelBattleScore: wheelBattleScore,
      evaluations: evaluations,
      tacticalLog: log,
    );
  }

  /// Symuluje pełny dojazd od [startDistanceMeters] do mety co [timeStepSeconds].
  static List<CounterSurfDecision> simulateFinalApproach({
    required SprinterSurfProfile initialSprinter,
    required List<RivalTrainSnapshot> rivalTrains,
    double startDistanceMeters = 2400.0,
    double crosswindDirection = 0.0,
    CounterSurfAggression aggressionMode = CounterSurfAggression.balancedSurfer,
    double timeStepSeconds = 2.0,
  }) {
    final List<CounterSurfDecision> history = <CounterSurfDecision>[];
    SprinterSurfProfile currentSprinter = initialSprinter;
    double distance = startDistanceMeters;
    String? currentTargetTeamId;
    CounterSurfPhase currentPhase = CounterSurfPhase.scanningTrains;

    int guard = 0;
    while (distance > 0.0 && guard < 300) {
      guard++;
      final CounterSurfDecision decision = evaluateStep(
        CounterSurfStepInput(
          sprinter: currentSprinter,
          rivalTrains: rivalTrains,
          distanceToFinishMeters: distance,
          crosswindDirection: crosswindDirection,
          aggressionMode: aggressionMode,
          currentTargetTeamId: currentTargetTeamId,
          currentPhase: currentPhase,
          timeStepSeconds: timeStepSeconds,
        ),
      );
      history.add(decision);

      currentTargetTeamId = decision.selectedTrainTeamId;
      currentPhase = decision.phase;
      final double speedKmh = decision.phase == CounterSurfPhase.slingshotLaunch
          ? 71.0
          : 61.5;
      final double metersCovered = (speedKmh / 3.6) * timeStepSeconds;
      distance = math.max(0.0, distance - metersCovered);
      currentSprinter = currentSprinter.copyWith(
        wPrimeRemainingJoules: decision.newWPrimeRemainingJoules,
        currentLateralPosition: decision.targetLateralPosition,
        currentSpeedKmh: speedKmh,
      );
    }

    return history;
  }

  static double _computeBoxingRisk({
    required RivalTrainSnapshot train,
    required List<RivalTrainSnapshot> allTrains,
  }) {
    final double pos = train.lateralRoadPosition;
    final bool nearLeft = pos <= barrierLeftEdge;
    final bool nearRight = pos >= barrierRightEdge;
    double risk = 0.08;
    if (nearLeft || nearRight) {
      risk = 0.45;
      for (final other in allTrains) {
        if (other.teamId == train.teamId) continue;
        if ((other.lateralRoadPosition - pos).abs() < 0.28) {
          risk = math.max(risk, 0.85);
        }
      }
    }
    return risk.clamp(0.0, 1.0);
  }

  static double _computeWheelWinProbability({
    required SprinterSurfProfile sprinter,
    required RivalTrainSnapshot train,
    required double lateralDistance,
    required CounterSurfAggression aggressionMode,
  }) {
    final double battle = _computeBattleScore(
      sprinter: sprinter,
      train: train,
      aggressionMode: aggressionMode,
    );
    final double gapAdjust = train.wheelGapOpen ? 0.14 : -0.16;
    final double distPenalty = lateralDistance * 0.15;
    return (((battle - 45.0) / 50.0) + gapAdjust - distPenalty).clamp(0.05, 0.98);
  }

  static double _computeBattleScore({
    required SprinterSurfProfile sprinter,
    required RivalTrainSnapshot train,
    required CounterSurfAggression aggressionMode,
  }) {
    final double skillBase = (sprinter.bikeHandling * 0.50) +
        (sprinter.raceIq * 0.35) +
        (sprinter.aggression * 0.15);
    final double defensePenalty = (train.rivalWheelDefenseSkill - 70) * 0.28;
    return (skillBase + aggressionMode.battleBonus - defensePenalty)
        .clamp(10.0, 100.0);
  }

  static double _estimateDraftSavingsPercent({
    required RivalTrainSnapshot train,
    required double winProbability,
    required double crosswindDirection,
  }) {
    final double baseDraft = 31.0 + (train.remainingHelpers.clamp(0, 4) * 1.4);
    final double windAdjust = crosswindDirection.abs() > 0.2 ? -3.0 : 1.5;
    final double reliabilityScale = 0.72 + (0.28 * winProbability);
    return ((baseDraft + windAdjust) * reliabilityScale).clamp(16.0, 40.0);
  }

  static bool _isBoxedAtBarrier({
    required double sprinterLateralPos,
    required RivalTrainSnapshot targetTrain,
    required List<RivalTrainSnapshot> allTrains,
    required SprinterSurfProfile sprinter,
  }) {
    final bool nearLeft = sprinterLateralPos <= barrierLeftEdge;
    final bool nearRight = sprinterLateralPos >= barrierRightEdge;
    if (!nearLeft && !nearRight) {
      return false;
    }
    for (final other in allTrains) {
      if (other.teamId == targetTrain.teamId) continue;
      if ((other.lateralRoadPosition - sprinterLateralPos).abs() < 0.26) {
        final bool escaped =
            sprinter.bikeHandling >= 90 && sprinter.raceIq >= 85;
        if (!escaped) {
          return true;
        }
      }
    }
    return false;
  }

  static WheelHopReason _inferHopReason({
    required RivalTrainEvaluation fromEval,
    required RivalTrainEvaluation toEval,
    required double crosswindDirection,
  }) {
    if (toEval.train.trainSpeedKmh - fromEval.train.trainSpeedKmh >= 1.8) {
      return WheelHopReason.fasterTrainOvertaking;
    }
    if (fromEval.boxingRisk >= 0.50 && toEval.boxingRisk < 0.35) {
      return WheelHopReason.barrierBoxRisk;
    }
    if (crosswindDirection.abs() > 0.2) {
      return WheelHopReason.crosswindShelterBetter;
    }
    return WheelHopReason.leadoutFading;
  }

  static double _computeWPrimeDelta({
    required int targetWatts,
    required int ftpWatts,
    required double dt,
    required double currentWPrime,
    required double maxWPrime,
  }) {
    if (targetWatts > ftpWatts) {
      return -(targetWatts - ftpWatts) * dt;
    }
    // Regeneracja W' poniżej FTP (uproszczona kinetyka Skiby)
    final double deficit = (ftpWatts - targetWatts).toDouble();
    final double tau = math.max(180.0, 546.0 * math.exp(-0.01 * deficit) + 316.0);
    final double missing = math.max(0.0, maxWPrime - currentWPrime);
    return missing * (1.0 - math.exp(-dt / tau));
  }

  static double _moveTowards({
    required double current,
    required double target,
    required double maxDelta,
  }) {
    final double diff = target - current;
    if (diff.abs() <= maxDelta) {
      return target.clamp(-1.0, 1.0);
    }
    return (current + diff.sign * maxDelta).clamp(-1.0, 1.0);
  }

  static String _buildEvaluationReasoning({
    required RivalTrainSnapshot train,
    required SurfTargetQuality quality,
    required double boxingRisk,
    required double draftSavings,
    required double distanceToFinishMeters,
  }) {
    if (quality == SurfTargetQuality.fading) {
      return 'Rozprowadzający wyczerpany (${(train.leadoutFatigueFraction * 100).round()}% zmęczenia).';
    }
    if (boxingRisk >= 0.6) {
      return 'Ryzyko zamknięcia przy barierce (${(boxingRisk * 100).round()}%).';
    }
    if (distanceToFinishMeters <= 500 && train.wheelGapOpen) {
      return 'Otwarte koło ${train.targetSprinterName} przed procą (-${draftSavings.round()}% oporu).';
    }
    return '${train.remainingHelpers} pomocników, ${train.trainSpeedKmh.toStringAsFixed(1)} km/h, -${draftSavings.round()}% W.';
  }
}

/// Interaktywny panel taktyki `Surf Rival Lead-out` (Zadanie #534).
///
/// Obsługuje responsywne układy dla `390x844`, `1024x768` oraz `1600x900`,
/// pełne stany `hover` / `active` / `disabled` / `focus` oraz płynne animacje.
class SprinterTrainCounterSurfingPanel extends StatefulWidget {
  final SprinterSurfProfile? initialSprinter;
  final List<RivalTrainSnapshot>? initialRivalTrains;
  final double initialDistanceMeters;

  const SprinterTrainCounterSurfingPanel({
    super.key,
    this.initialSprinter,
    this.initialRivalTrains,
    this.initialDistanceMeters = 2200.0,
  });

  @override
  State<SprinterTrainCounterSurfingPanel> createState() =>
      _SprinterTrainCounterSurfingPanelState();
}

class _SprinterTrainCounterSurfingPanelState
    extends State<SprinterTrainCounterSurfingPanel> {
  static const TextStyle _baseInterStyle = TextStyle(
    fontFamily: 'Inter',
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  late SprinterSurfProfile _sprinter;
  late List<RivalTrainSnapshot> _rivalTrains;
  late double _distanceMeters;
  CounterSurfAggression _aggression = CounterSurfAggression.balancedSurfer;
  double _crosswind = -0.35;
  String? _manualLockedTeamId;
  CounterSurfDecision? _lastDecision;
  Timer? _simTimer;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _initDefaults();
    _stepSimulation(advanceDistance: false);
  }

  @override
  void dispose() {
    _simTimer?.cancel();
    super.dispose();
  }

  void _initDefaults() {
    _sprinter = widget.initialSprinter ??
        const SprinterSurfProfile(
          riderId: 'sprinter_solo_1',
          riderName: 'M. Kittel-Type',
          ftpWatts: 410,
          power5sWatts: 1580,
          sprintSkill: 94,
          bikeHandling: 90,
          raceIq: 88,
          aggression: 84,
          wPrimeTotalJoules: 24000.0,
          wPrimeRemainingJoules: 22400.0,
          currentLateralPosition: 0.05,
          currentSpeedKmh: 61.0,
        );

    _rivalTrains = widget.initialRivalTrains ??
        const <RivalTrainSnapshot>[
          RivalTrainSnapshot(
            teamId: 'team_alpecin',
            teamName: 'Alpecin-Deceuninck',
            targetSprinterId: 'philipsen',
            targetSprinterName: 'J. Philipsen',
            activeLeadoutRiderId: 'mvdp',
            remainingHelpers: 2,
            trainSpeedKmh: 63.4,
            lateralRoadPosition: -0.32,
            leadoutPowerWatts: 620,
            leadoutFatigueFraction: 0.25,
            wheelGapOpen: true,
            rivalWheelDefenseSkill: 80,
          ),
          RivalTrainSnapshot(
            teamId: 'team_lidl',
            teamName: 'Lidl-Trek',
            targetSprinterId: 'milan',
            targetSprinterName: 'J. Milan',
            activeLeadoutRiderId: 'cons',
            remainingHelpers: 3,
            trainSpeedKmh: 62.6,
            lateralRoadPosition: 0.38,
            leadoutPowerWatts: 605,
            leadoutFatigueFraction: 0.20,
            wheelGapOpen: true,
            rivalWheelDefenseSkill: 76,
          ),
          RivalTrainSnapshot(
            teamId: 'team_soudal',
            teamName: 'Soudal Quick-Step',
            targetSprinterId: 'merlier',
            targetSprinterName: 'T. Merlier',
            activeLeadoutRiderId: 'lam',
            remainingHelpers: 1,
            trainSpeedKmh: 61.1,
            lateralRoadPosition: -0.86,
            leadoutPowerWatts: 560,
            leadoutFatigueFraction: 0.62,
            wheelGapOpen: false,
            rivalWheelDefenseSkill: 84,
          ),
        ];

    _distanceMeters = widget.initialDistanceMeters;
  }

  void _toggleSimulation() {
    if (_distanceMeters <= 0.0) {
      _resetSimulation();
      return;
    }
    setState(() {
      _isRunning = !_isRunning;
    });
    _simTimer?.cancel();
    if (_isRunning) {
      _simTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        if (!mounted) return;
        _stepSimulation(advanceDistance: true);
      });
    }
  }

  void _resetSimulation() {
    _simTimer?.cancel();
    setState(() {
      _isRunning = false;
      _manualLockedTeamId = null;
      _initDefaults();
    });
    _stepSimulation(advanceDistance: false);
  }

  void _stepSimulation({required bool advanceDistance}) {
    final double dt = advanceDistance ? 2.5 : 0.0;
    final CounterSurfDecision decision =
        SprinterTrainCounterSurfingAi.evaluateStep(
      CounterSurfStepInput(
        sprinter: _sprinter,
        rivalTrains: _rivalTrains,
        distanceToFinishMeters: _distanceMeters,
        crosswindDirection: _crosswind,
        aggressionMode: _aggression,
        currentTargetTeamId: _lastDecision?.selectedTrainTeamId,
        currentPhase:
            _lastDecision?.phase ?? CounterSurfPhase.scanningTrains,
        timeStepSeconds: dt > 0 ? dt : 1.0,
        manualLockedTeamId: _manualLockedTeamId,
      ),
    );

    setState(() {
      _lastDecision = decision;
      if (advanceDistance) {
        final double speedKmh =
            decision.phase == CounterSurfPhase.slingshotLaunch ? 72.0 : 62.5;
        final double covered = (speedKmh / 3.6) * dt;
        _distanceMeters = math.max(0.0, _distanceMeters - covered);
        _sprinter = _sprinter.copyWith(
          wPrimeRemainingJoules: decision.newWPrimeRemainingJoules,
          currentLateralPosition: decision.targetLateralPosition,
          currentSpeedKmh: speedKmh,
        );
        // Symuluj delikatne zmęczenie pociągu lidera przy zbliżaniu do mety
        _rivalTrains = _rivalTrains.map((t) {
          final double nextFatigue =
              (t.leadoutFatigueFraction + 0.025).clamp(0.0, 0.95);
          return t.copyWith(leadoutFatigueFraction: nextFatigue);
        }).toList();
        if (_distanceMeters <= 0.0) {
          _isRunning = false;
          _simTimer?.cancel();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final CounterSurfDecision? decision = _lastDecision;
    final bool isCompleted = _distanceMeters <= 0.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          final bool isDesktop = width >= 1120;
          final bool isTablet = width >= 680 && width < 1120;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(decision, isCompleted, isCompact: width < 600),
                const SizedBox(height: 16),
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: Column(
                          children: [
                            _buildRoadLaneVisualizer(decision),
                            const SizedBox(height: 16),
                            _buildTelemetryCard(decision),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 6,
                        child: Column(
                          children: [
                            _buildControlsCard(isCompleted),
                            const SizedBox(height: 16),
                            _buildRivalTrainsList(decision),
                          ],
                        ),
                      ),
                    ],
                  )
                else if (isTablet)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            _buildRoadLaneVisualizer(decision),
                            const SizedBox(height: 16),
                            _buildTelemetryCard(decision),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                            _buildControlsCard(isCompleted),
                            const SizedBox(height: 16),
                            _buildRivalTrainsList(decision),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      _buildRoadLaneVisualizer(decision),
                      const SizedBox(height: 12),
                      _buildTelemetryCard(decision),
                      const SizedBox(height: 12),
                      _buildControlsCard(isCompleted),
                      const SizedBox(height: 12),
                      _buildRivalTrainsList(decision),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(
    CounterSurfDecision? decision,
    bool isCompleted, {
    required bool isCompact,
  }) {
    final CounterSurfPhase phase = decision?.phase ?? CounterSurfPhase.standby;
    final Color phaseColor = _phaseAccentColor(phase);

    final Widget titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.waves_rounded,
              color: AppColors.goldAccent,
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Surf Rival Lead-out',
                overflow: TextOverflow.ellipsis,
                style: _baseInterStyle.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Taktyka surfowania ${_sprinter.riderName} po kołach pociągów rywali',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: _baseInterStyle.copyWith(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );

    final Widget actionsBlock = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Text(
            '${_distanceMeters.toStringAsFixed(0)} m',
            style: _baseInterStyle.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: phaseColor.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: phaseColor.withValues(alpha: 0.55)),
          ),
          child: Text(
            phase.labelPl,
            style: _baseInterStyle.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: phaseColor,
            ),
          ),
        ),
        _TacticalActionButton(
          label: isCompleted
              ? 'Restart'
              : (_isRunning ? 'Pauza' : 'Start AI'),
          icon: isCompleted
              ? Icons.replay_rounded
              : (_isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded),
          isPrimary: true,
          onTap: _toggleSimulation,
        ),
        _TacticalActionButton(
          label: 'Krok',
          icon: Icons.skip_next_rounded,
          isDisabled: _isRunning || isCompleted,
          onTap: () => _stepSimulation(advanceDistance: true),
        ),
        _TacticalActionButton(
          label: 'Reset',
          icon: Icons.refresh_rounded,
          onTap: _resetSimulation,
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleBlock,
                const SizedBox(height: 12),
                actionsBlock,
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: titleBlock),
                const SizedBox(width: 12),
                actionsBlock,
              ],
            ),
    );
  }

  Widget _buildRoadLaneVisualizer(CounterSurfDecision? decision) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Korytarz Szosy & Pozycja Pociągów',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _baseInterStyle.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _crosswind.abs() < 0.1
                      ? 'Brak wiatru bocznego'
                      : (_crosswind < 0
                          ? 'Wiatr z lewej →'
                          : '← Wiatr z prawej'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: _baseInterStyle.copyWith(
                    fontSize: 11,
                    color: AppColors.accentBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, laneConstraints) {
              final double laneWidth = laneConstraints.maxWidth;
              const double laneHeight = 148.0;

              return Container(
                width: laneWidth,
                height: laneHeight,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Stack(
                  children: [
                    // Lewa i prawa barierka ostrzegawcza
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: laneWidth * 0.08,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.crimsonAlert.withValues(alpha: 0.12),
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(11),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      width: laneWidth * 0.08,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.crimsonAlert.withValues(alpha: 0.12),
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(11),
                          ),
                        ),
                      ),
                    ),
                    // Pociągi rywali
                    for (final train in _rivalTrains)
                      _buildTrainMarker(
                        train: train,
                        laneWidth: laneWidth,
                        isSelected:
                            decision?.selectedTrainTeamId == train.teamId,
                      ),
                    // Nasz sprinter surfujący
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      left: ((_sprinter.currentLateralPosition + 1.0) / 2.0) *
                              (laneWidth - 44) +
                          4,
                      bottom: 14,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.goldAccent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.textPrimary,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppColors.goldAccent.withValues(alpha: 0.35),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.directions_bike_rounded,
                          size: 18,
                          color: AppColors.background,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTrainMarker({
    required RivalTrainSnapshot train,
    required double laneWidth,
    required bool isSelected,
  }) {
    final double x =
        ((train.lateralRoadPosition + 1.0) / 2.0) * (laneWidth - 88) + 8;
    return Positioned(
      left: x.clamp(4.0, math.max(4.0, laneWidth - 92)),
      top: 14,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: 84,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentBlue.withValues(alpha: 0.22)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.accentBlue : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              train.targetSprinterName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _baseInterStyle.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color:
                    isSelected ? AppColors.accentBlue : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${train.trainSpeedKmh.toStringAsFixed(1)} km/h',
              style: _baseInterStyle.copyWith(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTelemetryCard(CounterSurfDecision? decision) {
    final double wFraction = _sprinter.wPrimeRemainingFraction;
    final Color wColor = wFraction > 0.55
        ? AppColors.statusSuccess
        : (wFraction > 0.28 ? AppColors.amberWarning : AppColors.crimsonAlert);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Telemetria Surfowania & Radio DS',
            style: _baseInterStyle.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _TelemetryMetricChip(
                label: 'Moc Docelowa',
                value: '${decision?.targetWatts ?? 0} W',
                accent: AppColors.goldAccent,
              ),
              _TelemetryMetricChip(
                label: 'Oszczędność Draft',
                value:
                    '-${(decision?.estimatedDraftSavingsPercent ?? 0).toStringAsFixed(0)}%',
                accent: AppColors.statusSuccess,
              ),
              _TelemetryMetricChip(
                label: 'Walka o Koło',
                value:
                    '${(decision?.wheelBattleScore ?? 0).toStringAsFixed(0)}/100',
                accent: AppColors.accentBlue,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Zapas Beztlenowy W\'',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _baseInterStyle.copyWith(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(_sprinter.wPrimeRemainingJoules / 1000).toStringAsFixed(1)} / ${(_sprinter.wPrimeTotalJoules / 1000).toStringAsFixed(1)} kJ',
                style: _baseInterStyle.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: wFraction,
              minHeight: 8,
              backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(wColor),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Text(
              decision?.tacticalLog ?? 'Gotowy do analizy pociągów rywali.',
              style: _baseInterStyle.copyWith(
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsCard(bool isCompleted) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Agresywność Surfowania',
            style: _baseInterStyle.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CounterSurfAggression.values.map((mode) {
              final bool selected = _aggression == mode;
              return _SelectableOptionChip(
                label: mode.labelPl,
                isSelected: selected,
                isDisabled: isCompleted,
                onTap: () {
                  setState(() {
                    _aggression = mode;
                  });
                  _stepSimulation(advanceDistance: false);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Wiatr Boczny',
                style: _baseInterStyle.copyWith(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                _crosswind.toStringAsFixed(2),
                style: _baseInterStyle.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.accentBlue,
              inactiveTrackColor: AppColors.surfaceLight,
              thumbColor: AppColors.goldAccent,
            ),
            child: Slider(
              value: _crosswind,
              min: -1.0,
              max: 1.0,
              divisions: 8,
              onChanged: isCompleted
                  ? null
                  : (val) {
                      setState(() {
                        _crosswind = val;
                      });
                      _stepSimulation(advanceDistance: false);
                    },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRivalTrainsList(CounterSurfDecision? decision) {
    final List<RivalTrainEvaluation> evals = decision?.evaluations ?? const [];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Pociągi Rywali (Kliknij, by zablokować koło)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _baseInterStyle.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (_manualLockedTeamId != null) ...[
                const SizedBox(width: 8),
                _SelectableOptionChip(
                  label: 'Tryb Auto AI',
                  isSelected: false,
                  onTap: () {
                    setState(() {
                      _manualLockedTeamId = null;
                    });
                    _stepSimulation(advanceDistance: false);
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          if (evals.isEmpty)
            Text(
              'Brak pociągów do oceny.',
              style: _baseInterStyle.copyWith(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            )
          else
            Column(
              children: evals.map((evalItem) {
                final bool isTarget =
                    decision?.selectedTrainTeamId == evalItem.train.teamId;
                final bool isLocked =
                    _manualLockedTeamId == evalItem.train.teamId;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _RivalTrainEvaluationTile(
                    evaluation: evalItem,
                    isTarget: isTarget,
                    isManualLock: isLocked,
                    onTap: () {
                      setState(() {
                        _manualLockedTeamId = isLocked
                            ? null
                            : evalItem.train.teamId;
                      });
                      _stepSimulation(advanceDistance: false);
                    },
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Color _phaseAccentColor(CounterSurfPhase phase) {
    switch (phase) {
      case CounterSurfPhase.standby:
      case CounterSurfPhase.scanningTrains:
        return AppColors.textSecondary;
      case CounterSurfPhase.approachingWheel:
        return AppColors.amberWarning;
      case CounterSurfPhase.draftingRivalWheel:
        return AppColors.statusSuccess;
      case CounterSurfPhase.wheelHopping:
        return AppColors.accentBlue;
      case CounterSurfPhase.boxedInRecovery:
        return AppColors.crimsonAlert;
      case CounterSurfPhase.slingshotLaunch:
        return AppColors.goldAccent;
      case CounterSurfPhase.completed:
        return AppColors.cyanAccent;
    }
  }
}

class _TacticalActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;
  final bool isDisabled;

  const _TacticalActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
    this.isDisabled = false,
  });

  @override
  State<_TacticalActionButton> createState() => _TacticalActionButtonState();
}

class _TacticalActionButtonState extends State<_TacticalActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color baseBg = widget.isPrimary
        ? AppColors.primaryAccent
        : AppColors.surfaceLight;
    final Color effectiveBg = widget.isDisabled
        ? AppColors.surfaceLight.withValues(alpha: 0.45)
        : (_pressed
            ? baseBg.withValues(alpha: 0.85)
            : (_hovered ? baseBg.withValues(alpha: 0.92) : baseBg));
    final Color borderColor = _focused
        ? AppColors.goldAccent
        : (widget.isPrimary ? AppColors.primaryAccent : AppColors.cardBorder);

    return FocusableActionDetector(
      enabled: !widget.isDisabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: widget.isDisabled
            ? null
            : (_) => setState(() => _pressed = true),
        onTapUp: widget.isDisabled
            ? null
            : (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.isDisabled ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: effectiveBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: _focused ? 1.5 : 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: widget.isDisabled
                    ? AppColors.textSecondary.withValues(alpha: 0.5)
                    : AppColors.textPrimary,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: widget.isDisabled
                      ? AppColors.textSecondary.withValues(alpha: 0.5)
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectableOptionChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  const _SelectableOptionChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isDisabled = false,
  });

  @override
  State<_SelectableOptionChip> createState() => _SelectableOptionChipState();
}

class _SelectableOptionChipState extends State<_SelectableOptionChip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color bg = widget.isDisabled
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : widget.isSelected
            ? AppColors.goldAccent.withValues(alpha: _pressed ? 0.28 : 0.20)
            : (_hovered
                ? AppColors.surfaceLight.withValues(alpha: 0.9)
                : AppColors.surfaceLight);
    final Color border = _focused
        ? AppColors.accentBlue
        : (widget.isSelected ? AppColors.goldAccent : AppColors.cardBorder);

    return FocusableActionDetector(
      enabled: !widget.isDisabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: widget.isDisabled
            ? null
            : (_) => setState(() => _pressed = true),
        onTapUp: widget.isDisabled
            ? null
            : (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.isDisabled ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border, width: _focused ? 1.5 : 1),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
              color: widget.isDisabled
                  ? AppColors.textSecondary.withValues(alpha: 0.5)
                  : (widget.isSelected
                      ? AppColors.goldAccent
                      : AppColors.textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}

class _TelemetryMetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _TelemetryMetricChip({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: accent,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _RivalTrainEvaluationTile extends StatefulWidget {
  final RivalTrainEvaluation evaluation;
  final bool isTarget;
  final bool isManualLock;
  final VoidCallback onTap;

  const _RivalTrainEvaluationTile({
    required this.evaluation,
    required this.isTarget,
    required this.isManualLock,
    required this.onTap,
  });

  @override
  State<_RivalTrainEvaluationTile> createState() =>
      _RivalTrainEvaluationTileState();
}

class _RivalTrainEvaluationTileState extends State<_RivalTrainEvaluationTile> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final RivalTrainSnapshot train = widget.evaluation.train;
    final Color qualityColor = _qualityColor(widget.evaluation.quality);
    final Color borderColor = _focused
        ? AppColors.goldAccent
        : (widget.isTarget ? AppColors.accentBlue : AppColors.cardBorder);

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.isTarget
                ? AppColors.accentBlue.withValues(alpha: _pressed ? 0.18 : 0.12)
                : (_hovered
                    ? AppColors.surfaceLight.withValues(alpha: 0.95)
                    : AppColors.surfaceLight),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: widget.isTarget || _focused ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${train.targetSprinterName} (${train.teamName})',
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
                  if (widget.isManualLock) ...[
                    const Icon(
                      Icons.lock_rounded,
                      size: 14,
                      color: AppColors.goldAccent,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: qualityColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${widget.evaluation.quality.labelPl} (${widget.evaluation.score.round()})',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: qualityColor,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                widget.evaluation.reasoning,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _qualityColor(SurfTargetQuality quality) {
    switch (quality) {
      case SurfTargetQuality.prime:
        return AppColors.statusSuccess;
      case SurfTargetQuality.solid:
        return AppColors.accentBlue;
      case SurfTargetQuality.risky:
        return AppColors.amberWarning;
      case SurfTargetQuality.fading:
        return AppColors.crimsonAlert;
    }
  }
}
