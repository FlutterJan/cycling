import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/physics_constants.dart';
import '../../core/theme/app_colors.dart';

/// Faza realizacji manewru taktycznego `Kamikaze Pull & Drop` w Drużynowej Jeździe na Czas (TTT).
enum KamikazePullDropPhase {
  /// Taktyka w gotowości — pociąg jedzie standardową rotacją zmian.
  standby,

  /// Wybrany kolarz zbliża się do strefy odpalenia (ostatnia zmiana przed atakiem).
  approachingTrigger,

  /// Aktywny, supramaksymalny zaciąg Kamikaze na czele pociągu (118–140% FTP).
  kamikazePullActive,

  /// Wykorzystano W' — kolarz zjeżdża na bok i celowo odpada z pociągu.
  swingOffAndDrop,

  /// Pociąg zamknął lukę i kontynuuje jazdę w zredukowanym, szybszym składzie.
  pacelineRegrouped,

  /// Manewr przerwany przez strażnika bezpieczeństwa (ochrona limitu 4./5. kolarza UCI).
  abortedSafetyGuard,

  /// Etap TTT zakończony.
  completed;

  String get labelPl {
    switch (this) {
      case KamikazePullDropPhase.standby:
        return 'Gotowość';
      case KamikazePullDropPhase.approachingTrigger:
        return 'Przygotowanie';
      case KamikazePullDropPhase.kamikazePullActive:
        return 'Kamikaze Pull';
      case KamikazePullDropPhase.swingOffAndDrop:
        return 'Zjazd i Odpadnięcie';
      case KamikazePullDropPhase.pacelineRegrouped:
        return 'Pociąg Przegrupowany';
      case KamikazePullDropPhase.abortedSafetyGuard:
        return 'Blokada Limitu UCI';
      case KamikazePullDropPhase.completed:
        return 'Ukończono';
    }
  }

  String toJson() => name;

  static KamikazePullDropPhase fromJson(String value) {
    return KamikazePullDropPhase.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => KamikazePullDropPhase.standby,
    );
  }
}

/// Poziom agresywności zaciągu Kamikaze przed celowym odpadnięciem.
enum KamikazePullIntensity {
  /// Kontrolowany zaciąg (118% FTP) — dłuższa zmiana, umiarkowany zysk prędkości.
  controlledSurge(ftpRatio: 1.18, labelPl: 'Kontrolowany (118% FTP)'),

  /// Klasyczny Kamikaze Pull (128% FTP) — optymalny balans czasu i przyspieszenia.
  classicKamikaze(ftpRatio: 1.28, labelPl: 'Klasyczny Kamikaze (128% FTP)'),

  /// Pełna bomba (138% FTP) — maksymalny skok prędkości na ostatnie kilometry.
  allOutNuclear(ftpRatio: 1.38, labelPl: 'Pełna Bomba (138% FTP)');

  final double ftpRatio;
  final String labelPl;

  const KamikazePullIntensity({
    required this.ftpRatio,
    required this.labelPl,
  });

  String toJson() => name;

  static KamikazePullIntensity fromJson(String value) {
    return KamikazePullIntensity.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => KamikazePullIntensity.classicKamikaze,
    );
  }
}

/// Tryb reguły bezpieczeństwa liczby kolarzy na mecie TTT.
enum TttCountingSafetyMode {
  /// Twardy limit UCI: zostaw minimum 4 kolarzy (brak bufora na defekt/kraksę).
  uciMinimumFour(minRemainingRiders: 4, labelPl: 'Limit UCI (4 kolarzy)'),

  /// Bezpieczny bufor: zostaw minimum 5 kolarzy (ochrona przed kraksą lub odcięciem).
  fiveRiderBuffer(minRemainingRiders: 5, labelPl: 'Bufor Bezpieczeństwa (5 kolarzy)');

  final int minRemainingRiders;
  final String labelPl;

  const TttCountingSafetyMode({
    required this.minRemainingRiders,
    required this.labelPl,
  });

  String toJson() => name;

  static TttCountingSafetyMode fromJson(String value) {
    return TttCountingSafetyMode.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TttCountingSafetyMode.fiveRiderBuffer,
    );
  }
}

/// Powód decyzji o zakwalifikowaniu lub odrzuceniu kolarza do manewru Kamikaze.
enum KamikazeCandidateVerdict {
  optimalSacrifice,
  viableSacrifice,
  protectedGcLeader,
  protectedCoreTtEngine,
  insufficientWPrime,
  alreadyDropped,
  teamBelowSafetyFloor,
}

/// Profil kolarza w pociągu TTT dla oceny taktyki `Kamikaze Pull & Drop`.
class TttDropStrategyRiderProfile {
  final String riderId;
  final String riderName;
  final double ftpWatts;
  final double wPrimeTotalJoules;
  final double wPrimeRemainingJoules;
  final double riderMassKg;
  final double bikeMassKg;
  final double cdaM2;
  final int timeTrialSkill;
  final int staminaSkill;
  final bool isGcLeader;
  final bool isDesignatedPacelineCaptain;
  final bool isDropped;
  final double fatigueFraction;

  const TttDropStrategyRiderProfile({
    required this.riderId,
    required this.riderName,
    required this.ftpWatts,
    required this.wPrimeTotalJoules,
    required this.wPrimeRemainingJoules,
    this.riderMassKg = 70.0,
    this.bikeMassKg = 7.6,
    this.cdaM2 = 0.225,
    this.timeTrialSkill = 75,
    this.staminaSkill = 75,
    this.isGcLeader = false,
    this.isDesignatedPacelineCaptain = false,
    this.isDropped = false,
    this.fatigueFraction = 0.0,
  });

  double get wPrimeRatio => wPrimeTotalJoules > 0
      ? (wPrimeRemainingJoules / wPrimeTotalJoules).clamp(0.0, 1.0)
      : 0.0;

  double get totalMassKg => math.max(45.0, riderMassKg + bikeMassKg);

  TttDropStrategyRiderProfile copyWith({
    String? riderId,
    String? riderName,
    double? ftpWatts,
    double? wPrimeTotalJoules,
    double? wPrimeRemainingJoules,
    double? riderMassKg,
    double? bikeMassKg,
    double? cdaM2,
    int? timeTrialSkill,
    int? staminaSkill,
    bool? isGcLeader,
    bool? isDesignatedPacelineCaptain,
    bool? isDropped,
    double? fatigueFraction,
  }) {
    return TttDropStrategyRiderProfile(
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      ftpWatts: ftpWatts ?? this.ftpWatts,
      wPrimeTotalJoules: wPrimeTotalJoules ?? this.wPrimeTotalJoules,
      wPrimeRemainingJoules:
          wPrimeRemainingJoules ?? this.wPrimeRemainingJoules,
      riderMassKg: riderMassKg ?? this.riderMassKg,
      bikeMassKg: bikeMassKg ?? this.bikeMassKg,
      cdaM2: cdaM2 ?? this.cdaM2,
      timeTrialSkill: timeTrialSkill ?? this.timeTrialSkill,
      staminaSkill: staminaSkill ?? this.staminaSkill,
      isGcLeader: isGcLeader ?? this.isGcLeader,
      isDesignatedPacelineCaptain:
          isDesignatedPacelineCaptain ?? this.isDesignatedPacelineCaptain,
      isDropped: isDropped ?? this.isDropped,
      fatigueFraction: fatigueFraction ?? this.fatigueFraction,
    );
  }

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'riderName': riderName,
        'ftpWatts': ftpWatts,
        'wPrimeTotalJoules': wPrimeTotalJoules,
        'wPrimeRemainingJoules': wPrimeRemainingJoules,
        'riderMassKg': riderMassKg,
        'bikeMassKg': bikeMassKg,
        'cdaM2': cdaM2,
        'timeTrialSkill': timeTrialSkill,
        'staminaSkill': staminaSkill,
        'isGcLeader': isGcLeader,
        'isDesignatedPacelineCaptain': isDesignatedPacelineCaptain,
        'isDropped': isDropped,
        'fatigueFraction': fatigueFraction,
      };

  factory TttDropStrategyRiderProfile.fromJson(Map<String, dynamic> json) {
    return TttDropStrategyRiderProfile(
      riderId: json['riderId'] as String? ?? '',
      riderName: json['riderName'] as String? ?? 'Kolarz',
      ftpWatts: (json['ftpWatts'] as num?)?.toDouble() ?? 350.0,
      wPrimeTotalJoules:
          (json['wPrimeTotalJoules'] as num?)?.toDouble() ?? 20000.0,
      wPrimeRemainingJoules:
          (json['wPrimeRemainingJoules'] as num?)?.toDouble() ?? 16000.0,
      riderMassKg: (json['riderMassKg'] as num?)?.toDouble() ?? 70.0,
      bikeMassKg: (json['bikeMassKg'] as num?)?.toDouble() ?? 7.6,
      cdaM2: (json['cdaM2'] as num?)?.toDouble() ?? 0.225,
      timeTrialSkill: (json['timeTrialSkill'] as num?)?.toInt() ?? 75,
      staminaSkill: (json['staminaSkill'] as num?)?.toInt() ?? 75,
      isGcLeader: json['isGcLeader'] as bool? ?? false,
      isDesignatedPacelineCaptain:
          json['isDesignatedPacelineCaptain'] as bool? ?? false,
      isDropped: json['isDropped'] as bool? ?? false,
      fatigueFraction: (json['fatigueFraction'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Dane wejściowe dla ewaluacji i kroku symulacji taktyki `Kamikaze Pull & Drop`.
class KamikazePullDropInput {
  final List<TttDropStrategyRiderProfile> riders;
  final double distanceRemainingKm;
  final double totalStageDistanceKm;
  final double currentTrainSpeedKmh;
  final double roadGradientPercent;
  final double headwindMs;
  final double airDensityKgM3;
  final double crr;
  final KamikazePullIntensity intensity;
  final TttCountingSafetyMode safetyMode;
  final String? forcedCandidateRiderId;

  const KamikazePullDropInput({
    required this.riders,
    required this.distanceRemainingKm,
    required this.totalStageDistanceKm,
    required this.currentTrainSpeedKmh,
    this.roadGradientPercent = 0.0,
    this.headwindMs = 0.0,
    this.airDensityKgM3 = PhysicsConstants.seaLevelAirDensity,
    this.crr = 0.0028,
    this.intensity = KamikazePullIntensity.classicKamikaze,
    this.safetyMode = TttCountingSafetyMode.fiveRiderBuffer,
    this.forcedCandidateRiderId,
  });
}

/// Ocena pojedynczego kolarza jako kandydata do zaciągu Kamikaze.
class KamikazeCandidateEvaluation {
  final String riderId;
  final String riderName;
  final double suitabilityScore;
  final KamikazeCandidateVerdict verdict;
  final double plannedPullWatts;
  final double estimatedPullDurationSeconds;
  final double estimatedSpeedGainKmh;
  final double estimatedTeamTimeGainSeconds;
  final String rationalePl;

  const KamikazeCandidateEvaluation({
    required this.riderId,
    required this.riderName,
    required this.suitabilityScore,
    required this.verdict,
    required this.plannedPullWatts,
    required this.estimatedPullDurationSeconds,
    required this.estimatedSpeedGainKmh,
    required this.estimatedTeamTimeGainSeconds,
    required this.rationalePl,
  });

  bool get isEligible =>
      verdict == KamikazeCandidateVerdict.optimalSacrifice ||
      verdict == KamikazeCandidateVerdict.viableSacrifice;
}

/// Plan i rekomendacja taktyczna dla całej drużyny w bieżącej sytuacji TTT.
class KamikazePullDropPlan {
  final bool canExecuteSafely;
  final int activeRidersCount;
  final int minRequiredFinishers;
  final KamikazeCandidateEvaluation? recommendedCandidate;
  final List<KamikazeCandidateEvaluation> allEvaluations;
  final double projectedPacelineSpeedKmh;
  final double projectedTeamTimeGainSeconds;
  final double followerDraftPowerSavingsWatts;
  final double triggerWindowScore;
  final String tacticalSummaryPl;

  const KamikazePullDropPlan({
    required this.canExecuteSafely,
    required this.activeRidersCount,
    required this.minRequiredFinishers,
    required this.recommendedCandidate,
    required this.allEvaluations,
    required this.projectedPacelineSpeedKmh,
    required this.projectedTeamTimeGainSeconds,
    required this.followerDraftPowerSavingsWatts,
    required this.triggerWindowScore,
    required this.tacticalSummaryPl,
  });
}

/// Stan bieżącego wykonania manewru `Kamikaze Pull & Drop` w czasie rzeczywistym.
class KamikazePullDropExecutionState {
  final KamikazePullDropPhase phase;
  final String? activeKamikazeRiderId;
  final String? activeKamikazeRiderName;
  final double pullElapsedSeconds;
  final double pullTargetWatts;
  final double pullRiderWPrimeRemainingJoules;
  final double pullRiderWPrimeTotalJoules;
  final double currentTrainSpeedKmh;
  final double cumulativeTimeGainedSeconds;
  final int activeRidersRemaining;
  final int droppedByKamikazeCount;
  final List<String> droppedRiderIds;
  final String? statusMessagePl;

  const KamikazePullDropExecutionState({
    this.phase = KamikazePullDropPhase.standby,
    this.activeKamikazeRiderId,
    this.activeKamikazeRiderName,
    this.pullElapsedSeconds = 0.0,
    this.pullTargetWatts = 0.0,
    this.pullRiderWPrimeRemainingJoules = 0.0,
    this.pullRiderWPrimeTotalJoules = 0.0,
    this.currentTrainSpeedKmh = 52.0,
    this.cumulativeTimeGainedSeconds = 0.0,
    this.activeRidersRemaining = 6,
    this.droppedByKamikazeCount = 0,
    this.droppedRiderIds = const [],
    this.statusMessagePl,
  });

  double get wPrimeRemainingRatio => pullRiderWPrimeTotalJoules > 0
      ? (pullRiderWPrimeRemainingJoules / pullRiderWPrimeTotalJoules)
          .clamp(0.0, 1.0)
      : 0.0;

  KamikazePullDropExecutionState copyWith({
    KamikazePullDropPhase? phase,
    String? activeKamikazeRiderId,
    String? activeKamikazeRiderName,
    double? pullElapsedSeconds,
    double? pullTargetWatts,
    double? pullRiderWPrimeRemainingJoules,
    double? pullRiderWPrimeTotalJoules,
    double? currentTrainSpeedKmh,
    double? cumulativeTimeGainedSeconds,
    int? activeRidersRemaining,
    int? droppedByKamikazeCount,
    List<String>? droppedRiderIds,
    String? statusMessagePl,
  }) {
    return KamikazePullDropExecutionState(
      phase: phase ?? this.phase,
      activeKamikazeRiderId:
          activeKamikazeRiderId ?? this.activeKamikazeRiderId,
      activeKamikazeRiderName:
          activeKamikazeRiderName ?? this.activeKamikazeRiderName,
      pullElapsedSeconds: pullElapsedSeconds ?? this.pullElapsedSeconds,
      pullTargetWatts: pullTargetWatts ?? this.pullTargetWatts,
      pullRiderWPrimeRemainingJoules: pullRiderWPrimeRemainingJoules ??
          this.pullRiderWPrimeRemainingJoules,
      pullRiderWPrimeTotalJoules:
          pullRiderWPrimeTotalJoules ?? this.pullRiderWPrimeTotalJoules,
      currentTrainSpeedKmh: currentTrainSpeedKmh ?? this.currentTrainSpeedKmh,
      cumulativeTimeGainedSeconds:
          cumulativeTimeGainedSeconds ?? this.cumulativeTimeGainedSeconds,
      activeRidersRemaining:
          activeRidersRemaining ?? this.activeRidersRemaining,
      droppedByKamikazeCount:
          droppedByKamikazeCount ?? this.droppedByKamikazeCount,
      droppedRiderIds: droppedRiderIds ?? this.droppedRiderIds,
      statusMessagePl: statusMessagePl ?? this.statusMessagePl,
    );
  }
}

/// Silnik taktyki `Kamikaze Pull & Drop` dla Drużynowej Jazdy na Czas (TTT).
///
/// Odpowiada za:
/// - dobór optymalnego kolarza do poświęcenia (ochrona lidera GC i silników TT),
/// - weryfikację limitu UCI (minimum 4 kolarzy na mecie, opcjonalny bufor 5. kolarza),
/// - obliczenia fizyczne skoku prędkości, drenażu W' oraz zysku czasowego drużyny,
/// - deterministyczną maszynę stanów manewru (`standby -> kamikazePullActive -> swingOffAndDrop -> pacelineRegrouped`).
class TeamTimeTrialRiderDropStrategy {
  const TeamTimeTrialRiderDropStrategy._();

  /// Próg pozostałego W' [J], poniżej którego kolarz Kamikaze schodzi ze zmiany i odpada.
  static const double dropWPrimeThresholdJoules = 650.0;

  /// Minimalny czas trwania pojedynczego zaciągu Kamikaze [s].
  static const double minPullDurationSeconds = 12.0;

  /// Maksymalny czas trwania pojedynczego zaciągu Kamikaze [s].
  static const double maxPullDurationSeconds = 55.0;

  /// Redukcja oporu aero dla chronionych kolarzy jadących na kole podczas zaciągu Kamikaze.
  static const double protectedFollowerDraftReduction = 0.41;

  /// Ocenia cały skład pociągu i generuje plan manewru `Kamikaze Pull & Drop`.
  static KamikazePullDropPlan evaluatePlan(KamikazePullDropInput input) {
    final List<TttDropStrategyRiderProfile> activeRiders =
        input.riders.where((r) => !r.isDropped).toList();
    final int activeCount = activeRiders.length;
    final int minFinishers = input.safetyMode.minRemainingRiders;
    final bool canExecuteSafely = activeCount > minFinishers;

    final double triggerScore = _computeTriggerWindowScore(
      distanceRemainingKm: input.distanceRemainingKm,
      totalStageDistanceKm: input.totalStageDistanceKm,
      roadGradientPercent: input.roadGradientPercent,
      headwindMs: input.headwindMs,
    );

    if (activeRiders.isEmpty) {
      return KamikazePullDropPlan(
        canExecuteSafely: false,
        activeRidersCount: 0,
        minRequiredFinishers: minFinishers,
        recommendedCandidate: null,
        allEvaluations: const [],
        projectedPacelineSpeedKmh: math.max(0.0, input.currentTrainSpeedKmh),
        projectedTeamTimeGainSeconds: 0.0,
        followerDraftPowerSavingsWatts: 0.0,
        triggerWindowScore: triggerScore,
        tacticalSummaryPl: 'Brak aktywnych kolarzy w pociągu TTT.',
      );
    }

    // Wyznacz średnie FTP drużyny jako punkt odniesienia dla "silników TT".
    final double avgFtp = activeRiders
            .map((r) => r.ftpWatts)
            .fold<double>(0.0, (sum, v) => sum + v) /
        activeRiders.length;

    final List<KamikazeCandidateEvaluation> evaluations = input.riders
        .map(
          (rider) => _evaluateCandidate(
            rider: rider,
            teamAvgFtp: avgFtp,
            canExecuteSafely: canExecuteSafely,
            input: input,
          ),
        )
        .toList()
      ..sort((a, b) => b.suitabilityScore.compareTo(a.suitabilityScore));

    KamikazeCandidateEvaluation? recommended;
    if (input.forcedCandidateRiderId != null) {
      for (final eval in evaluations) {
        if (eval.riderId == input.forcedCandidateRiderId &&
            eval.verdict != KamikazeCandidateVerdict.alreadyDropped &&
            eval.verdict != KamikazeCandidateVerdict.teamBelowSafetyFloor) {
          recommended = eval;
          break;
        }
      }
    }
    recommended ??= evaluations.cast<KamikazeCandidateEvaluation?>().firstWhere(
          (e) => e != null && e.isEligible,
          orElse: () => null,
        );

    final double baseSpeedKmh = math.max(20.0, input.currentTrainSpeedKmh);
    final double speedGain = recommended?.estimatedSpeedGainKmh ?? 0.0;
    final double projectedSpeedKmh = baseSpeedKmh + speedGain;
    final double timeGain = recommended?.estimatedTeamTimeGainSeconds ?? 0.0;

    // Oszczędność mocy chronionych kolarzy jadących w głębokim drafcie za zaciągiem Kamikaze.
    final double draftSavingsWatts = recommended != null
        ? recommended.plannedPullWatts * protectedFollowerDraftReduction * 0.85
        : 0.0;

    final String summary;
    if (!canExecuteSafely) {
      summary =
          'Blokada bezpieczeństwa: pozostało $activeCount kolarzy (limit: $minFinishers). '
          'Kolejne odpadnięcie grozi utratą czasu drużyny!';
    } else if (recommended == null) {
      summary =
          'Brak odpowiedniego kandydata do zaciągu Kamikaze — wszyscy kolarze są chronieni lub wyczerpani.';
    } else {
      summary =
          'Rekomendacja: ${recommended.riderName} na zaciąg ${recommended.plannedPullWatts.round()} W '
          'przez ~${recommended.estimatedPullDurationSeconds.round()} s '
          '(+${speedGain.toStringAsFixed(1)} km/h, zysk ~${timeGain.toStringAsFixed(2)} s).';
    }

    return KamikazePullDropPlan(
      canExecuteSafely: canExecuteSafely,
      activeRidersCount: activeCount,
      minRequiredFinishers: minFinishers,
      recommendedCandidate: recommended,
      allEvaluations: evaluations,
      projectedPacelineSpeedKmh: projectedSpeedKmh,
      projectedTeamTimeGainSeconds: timeGain,
      followerDraftPowerSavingsWatts: draftSavingsWatts,
      triggerWindowScore: triggerScore,
      tacticalSummaryPl: summary,
    );
  }

  /// Rozpoczyna manewr `Kamikaze Pull` dla wybranego kolarza.
  static KamikazePullDropExecutionState initiateKamikazePull({
    required KamikazePullDropExecutionState currentState,
    required KamikazePullDropInput input,
    required String candidateRiderId,
  }) {
    final List<TttDropStrategyRiderProfile> activeRiders =
        input.riders.where((r) => !r.isDropped).toList();
    final int minFinishers = input.safetyMode.minRemainingRiders;

    if (activeRiders.length <= minFinishers) {
      return currentState.copyWith(
        phase: KamikazePullDropPhase.abortedSafetyGuard,
        activeRidersRemaining: activeRiders.length,
        statusMessagePl:
            'Przerwano: drużyna ma tylko ${activeRiders.length} aktywnych kolarzy '
            '(wymagane minimum: $minFinishers).',
      );
    }

    final TttDropStrategyRiderProfile? rider = activeRiders
        .cast<TttDropStrategyRiderProfile?>()
        .firstWhere((r) => r?.riderId == candidateRiderId, orElse: () => null);

    if (rider == null) {
      return currentState.copyWith(
        phase: KamikazePullDropPhase.standby,
        statusMessagePl:
            'Nie znaleziono aktywnego kolarza o ID $candidateRiderId.',
      );
    }

    final double targetWatts =
        math.max(180.0, rider.ftpWatts * input.intensity.ftpRatio);

    return currentState.copyWith(
      phase: KamikazePullDropPhase.kamikazePullActive,
      activeKamikazeRiderId: rider.riderId,
      activeKamikazeRiderName: rider.riderName,
      pullElapsedSeconds: 0.0,
      pullTargetWatts: targetWatts,
      pullRiderWPrimeRemainingJoules: rider.wPrimeRemainingJoules,
      pullRiderWPrimeTotalJoules: rider.wPrimeTotalJoules,
      currentTrainSpeedKmh: input.currentTrainSpeedKmh,
      activeRidersRemaining: activeRiders.length,
      statusMessagePl:
          '${rider.riderName} wyszedł na czoło! Zaciąg Kamikaze ${targetWatts.round()} W.',
    );
  }

  /// Wykonuje jeden krok czasowy [dtSeconds] aktywnego manewru `Kamikaze Pull & Drop`.
  static KamikazePullDropExecutionState stepExecution({
    required KamikazePullDropExecutionState state,
    required KamikazePullDropInput input,
    required double dtSeconds,
  }) {
    if (dtSeconds <= 0.0) return state;

    if (input.distanceRemainingKm <= 0.0) {
      return state.copyWith(
        phase: KamikazePullDropPhase.completed,
        statusMessagePl: 'Drużyna przekroczyła linię mety TTT.',
      );
    }

    if (state.phase != KamikazePullDropPhase.kamikazePullActive) {
      return state;
    }

    final TttDropStrategyRiderProfile? rider = input.riders
        .cast<TttDropStrategyRiderProfile?>()
        .firstWhere(
          (r) => r?.riderId == state.activeKamikazeRiderId && !(r?.isDropped ?? true),
          orElse: () => null,
        );

    if (rider == null) {
      return state.copyWith(
        phase: KamikazePullDropPhase.pacelineRegrouped,
        statusMessagePl: 'Pociąg przegrupowany po zejściu kolarza.',
      );
    }

    final double targetWatts = state.pullTargetWatts > 0
        ? state.pullTargetWatts
        : rider.ftpWatts * input.intensity.ftpRatio;

    // Zużycie W' powyżej progu FTP [J/s = W].
    final double excessWatts = math.max(25.0, targetWatts - rider.ftpWatts);
    final double nextWPrime = math.max(
      0.0,
      state.pullRiderWPrimeRemainingJoules - (excessWatts * dtSeconds),
    );
    final double nextElapsed = state.pullElapsedSeconds + dtSeconds;

    // Obliczenie aktualnego skoku prędkości pociągu.
    final double baseSpeedMs = math.max(5.5, input.currentTrainSpeedKmh / 3.6);
    final double boostedSpeedMs = _solveSpeedMsFromPower(
      powerWatts: targetWatts,
      massKg: rider.totalMassKg,
      cdaM2: rider.cdaM2,
      crr: input.crr,
      airDensityKgM3: input.airDensityKgM3,
      gradientPercent: input.roadGradientPercent,
      headwindMs: input.headwindMs,
    );
    // Pociąg porusza się z prędkością zadaną przez czoło (ograniczoną płynnością przyspieszenia).
    final double effectiveSpeedMs = math.max(
      baseSpeedMs,
      baseSpeedMs + ((boostedSpeedMs - baseSpeedMs) * 0.88),
    );
    final double deltaDistanceMeters =
        math.max(0.0, effectiveSpeedMs - baseSpeedMs) * dtSeconds;
    final double stepTimeGainSeconds = deltaDistanceMeters / baseSpeedMs;

    final bool reachedWPrimeLimit =
        nextWPrime <= dropWPrimeThresholdJoules &&
            nextElapsed >= minPullDurationSeconds;
    final bool reachedMaxDuration = nextElapsed >= maxPullDurationSeconds;

    if (reachedWPrimeLimit || reachedMaxDuration) {
      final List<String> updatedDropped = List<String>.from(state.droppedRiderIds)
        ..add(rider.riderId);
      final int remaining = math.max(0, state.activeRidersRemaining - 1);

      return state.copyWith(
        phase: KamikazePullDropPhase.swingOffAndDrop,
        pullElapsedSeconds: nextElapsed,
        pullRiderWPrimeRemainingJoules: nextWPrime,
        currentTrainSpeedKmh: effectiveSpeedMs * 3.6,
        cumulativeTimeGainedSeconds:
            state.cumulativeTimeGainedSeconds + stepTimeGainSeconds,
        activeRidersRemaining: remaining,
        droppedByKamikazeCount: state.droppedByKamikazeCount + 1,
        droppedRiderIds: updatedDropped,
        statusMessagePl:
            '${rider.riderName} wykonał zaciąg (${nextElapsed.toStringAsFixed(0)} s) i zjeżdża z pociągu! '
            'Pozostało $remaining kolarzy.',
      );
    }

    return state.copyWith(
      pullElapsedSeconds: nextElapsed,
      pullRiderWPrimeRemainingJoules: nextWPrime,
      currentTrainSpeedKmh: effectiveSpeedMs * 3.6,
      cumulativeTimeGainedSeconds:
          state.cumulativeTimeGainedSeconds + stepTimeGainSeconds,
      statusMessagePl:
          '${rider.riderName} ciągnie ${targetWatts.round()} W '
          '(${(effectiveSpeedMs * 3.6).toStringAsFixed(1)} km/h, W\' ${(nextWPrime / 1000.0).toStringAsFixed(1)} kJ).',
    );
  }

  /// Natychmiastowo wykonuje zjazd i odpadnięcie kolarza na żądanie dyrektora sportowego.
  static KamikazePullDropExecutionState forceSwingOffAndDrop({
    required KamikazePullDropExecutionState state,
  }) {
    if (state.phase != KamikazePullDropPhase.kamikazePullActive ||
        state.activeKamikazeRiderId == null) {
      return state;
    }

    final List<String> updatedDropped = List<String>.from(state.droppedRiderIds);
    if (!updatedDropped.contains(state.activeKamikazeRiderId)) {
      updatedDropped.add(state.activeKamikazeRiderId!);
    }
    final int remaining = math.max(0, state.activeRidersRemaining - 1);

    return state.copyWith(
      phase: KamikazePullDropPhase.swingOffAndDrop,
      activeRidersRemaining: remaining,
      droppedByKamikazeCount: updatedDropped.length,
      droppedRiderIds: updatedDropped,
      statusMessagePl:
          '${state.activeKamikazeRiderName ?? "Kolarz"} zjechał na rozkaz wozu! '
          'Pozostało $remaining kolarzy w pociągu.',
    );
  }

  /// Domyka manewr po zjeździe kolarza i przywraca standardową rotację reszty pociągu.
  static KamikazePullDropExecutionState regroupPaceline({
    required KamikazePullDropExecutionState state,
  }) {
    if (state.phase != KamikazePullDropPhase.swingOffAndDrop &&
        state.phase != KamikazePullDropPhase.abortedSafetyGuard) {
      return state;
    }
    return state.copyWith(
      phase: KamikazePullDropPhase.pacelineRegrouped,
      statusMessagePl:
          'Pociąg przegrupowany (${state.activeRidersRemaining} aktywnych kolarzy). '
          'Zysk netto: +${state.cumulativeTimeGainedSeconds.toStringAsFixed(2)} s.',
    );
  }

  static KamikazeCandidateEvaluation _evaluateCandidate({
    required TttDropStrategyRiderProfile rider,
    required double teamAvgFtp,
    required bool canExecuteSafely,
    required KamikazePullDropInput input,
  }) {
    if (rider.isDropped) {
      return KamikazeCandidateEvaluation(
        riderId: rider.riderId,
        riderName: rider.riderName,
        suitabilityScore: -100.0,
        verdict: KamikazeCandidateVerdict.alreadyDropped,
        plannedPullWatts: 0.0,
        estimatedPullDurationSeconds: 0.0,
        estimatedSpeedGainKmh: 0.0,
        estimatedTeamTimeGainSeconds: 0.0,
        rationalePl: 'Kolarz już odpadł z pociągu.',
      );
    }

    if (!canExecuteSafely) {
      return KamikazeCandidateEvaluation(
        riderId: rider.riderId,
        riderName: rider.riderName,
        suitabilityScore: -50.0,
        verdict: KamikazeCandidateVerdict.teamBelowSafetyFloor,
        plannedPullWatts: 0.0,
        estimatedPullDurationSeconds: 0.0,
        estimatedSpeedGainKmh: 0.0,
        estimatedTeamTimeGainSeconds: 0.0,
        rationalePl:
            'Drużyna osiągnęła dolny limit kolarzy (${input.safetyMode.minRemainingRiders}).',
      );
    }

    if (rider.isGcLeader) {
      return KamikazeCandidateEvaluation(
        riderId: rider.riderId,
        riderName: rider.riderName,
        suitabilityScore: -20.0,
        verdict: KamikazeCandidateVerdict.protectedGcLeader,
        plannedPullWatts: 0.0,
        estimatedPullDurationSeconds: 0.0,
        estimatedSpeedGainKmh: 0.0,
        estimatedTeamTimeGainSeconds: 0.0,
        rationalePl: 'Lider klasyfikacji generalnej (GC) — chroniony do mety.',
      );
    }

    final double plannedWatts =
        math.max(180.0, rider.ftpWatts * input.intensity.ftpRatio);
    final double usableWPrime = math.max(
      0.0,
      rider.wPrimeRemainingJoules - dropWPrimeThresholdJoules,
    );

    if (usableWPrime < 2500.0) {
      return KamikazeCandidateEvaluation(
        riderId: rider.riderId,
        riderName: rider.riderName,
        suitabilityScore: 5.0,
        verdict: KamikazeCandidateVerdict.insufficientWPrime,
        plannedPullWatts: plannedWatts,
        estimatedPullDurationSeconds: 0.0,
        estimatedSpeedGainKmh: 0.0,
        estimatedTeamTimeGainSeconds: 0.0,
        rationalePl:
            'Zbyt niski zapas W\' (${(rider.wPrimeRemainingJoules / 1000.0).toStringAsFixed(1)} kJ) na efektywny zaciąg.',
      );
    }

    final double excessWatts = math.max(25.0, plannedWatts - rider.ftpWatts);
    final double pullDuration = (usableWPrime / excessWatts)
        .clamp(minPullDurationSeconds, maxPullDurationSeconds);

    final double baseSpeedMs = math.max(5.5, input.currentTrainSpeedKmh / 3.6);
    final double boostedSpeedMs = _solveSpeedMsFromPower(
      powerWatts: plannedWatts,
      massKg: rider.totalMassKg,
      cdaM2: rider.cdaM2,
      crr: input.crr,
      airDensityKgM3: input.airDensityKgM3,
      gradientPercent: input.roadGradientPercent,
      headwindMs: input.headwindMs,
    );
    final double speedGainMs = math.max(0.0, (boostedSpeedMs - baseSpeedMs) * 0.88);
    final double speedGainKmh = speedGainMs * 3.6;
    final double distanceBonusMeters = speedGainMs * pullDuration;
    final double timeGainSeconds = distanceBonusMeters / baseSpeedMs;

    // Kolarze o najwyższym FTP i skillu TT są cenniejsi w rdzeniu do samej mety,
    // natomiast słabszy silnik TT z dużym W' jest idealnym kandydatem Kamikaze.
    final bool isCoreEngine =
        rider.isDesignatedPacelineCaptain ||
        (rider.ftpWatts >= teamAvgFtp && rider.timeTrialSkill >= 82);

    if (isCoreEngine) {
      return KamikazeCandidateEvaluation(
        riderId: rider.riderId,
        riderName: rider.riderName,
        suitabilityScore: 32.0 + timeGainSeconds,
        verdict: KamikazeCandidateVerdict.protectedCoreTtEngine,
        plannedPullWatts: plannedWatts,
        estimatedPullDurationSeconds: pullDuration,
        estimatedSpeedGainKmh: speedGainKmh,
        estimatedTeamTimeGainSeconds: timeGainSeconds,
        rationalePl:
            'Kluczowy silnik TT — lepiej zachować go na końcowe kilometry.',
      );
    }

    // Punktacja przydatności: wyższy zysk czasu + wysoki W' + niższe relatywne FTP (mniejsza strata dla rdzenia).
    final double ftpSacrificeAdvantage =
        ((teamAvgFtp - rider.ftpWatts) / math.max(1.0, teamAvgFtp)) * 45.0;
    final double fatigueBonus = rider.fatigueFraction * 20.0;
    final double score = 55.0 +
        (timeGainSeconds * 12.0) +
        (rider.wPrimeRatio * 20.0) +
        ftpSacrificeAdvantage +
        fatigueBonus;

    final KamikazeCandidateVerdict verdict = score >= 72.0
        ? KamikazeCandidateVerdict.optimalSacrifice
        : KamikazeCandidateVerdict.viableSacrifice;

    return KamikazeCandidateEvaluation(
      riderId: rider.riderId,
      riderName: rider.riderName,
      suitabilityScore: score,
      verdict: verdict,
      plannedPullWatts: plannedWatts,
      estimatedPullDurationSeconds: pullDuration,
      estimatedSpeedGainKmh: speedGainKmh,
      estimatedTeamTimeGainSeconds: timeGainSeconds,
      rationalePl:
          '${verdict == KamikazeCandidateVerdict.optimalSacrifice ? "Optymalny" : "Dobry"} kandydat: '
          '${pullDuration.round()} s przy ${plannedWatts.round()} W, '
          'zysk +${timeGainSeconds.toStringAsFixed(2)} s.',
    );
  }

  /// Wyznacza atrakcyjność bieżącego okna trasy (0–100) do odpalenia `Kamikaze Pull & Drop`.
  static double _computeTriggerWindowScore({
    required double distanceRemainingKm,
    required double totalStageDistanceKm,
    required double roadGradientPercent,
    required double headwindMs,
  }) {
    final double safeTotal = math.max(1.0, totalStageDistanceKm);
    final double remainingFraction =
        (distanceRemainingKm / safeTotal).clamp(0.0, 1.0);

    // Najlepsze okno to końcowe 25% trasy (lub ostatnie 2–8 km).
    double proximityScore = 30.0;
    if (distanceRemainingKm <= 8.0 && distanceRemainingKm >= 1.2) {
      proximityScore = 95.0;
    } else if (remainingFraction <= 0.30) {
      proximityScore = 75.0;
    }

    // Płasko lub lekko pod wiatr zwiększa wartość aerodynamiczną zaciągu.
    final double gradientPenalty = (roadGradientPercent.abs() * 6.0).clamp(0.0, 35.0);
    final double headwindBonus = (headwindMs * 3.5).clamp(-10.0, 18.0);

    return (proximityScore - gradientPenalty + headwindBonus).clamp(0.0, 100.0);
  }

  /// Rozwiązuje prędkość [m/s] z zadanej mocy metodą bisekcji.
  static double _solveSpeedMsFromPower({
    required double powerWatts,
    required double massKg,
    required double cdaM2,
    required double crr,
    required double airDensityKgM3,
    required double gradientPercent,
    required double headwindMs,
  }) {
    final double effectivePower =
        math.max(50.0, powerWatts * (1.0 - PhysicsConstants.drivetrainLossStandard));
    final double grade = gradientPercent / 100.0;
    final double gravityForce = massKg * PhysicsConstants.gravity * grade;
    final double rollingForce =
        massKg * PhysicsConstants.gravity * crr * math.cos(math.atan(grade));

    double low = 2.0;
    double high = 26.0;
    for (int i = 0; i < 24; i++) {
      final double mid = 0.5 * (low + high);
      final double vRel = mid + headwindMs;
      final double aeroForce =
          0.5 * airDensityKgM3 * cdaM2 * vRel * vRel.abs();
      final double requiredPower = (gravityForce + rollingForce + aeroForce) * mid;
      if (requiredPower < effectivePower) {
        low = mid;
      } else {
        high = mid;
      }
    }
    return 0.5 * (low + high);
  }
}

/// Interaktywny panel taktyki `Kamikaze Pull & Drop` zgodny z paletą `AppColors` i `Inter`.
class KamikazePullDropStrategyPanel extends StatefulWidget {
  final KamikazePullDropInput initialInput;
  final ValueChanged<KamikazePullDropExecutionState>? onStateChanged;

  const KamikazePullDropStrategyPanel({
    super.key,
    required this.initialInput,
    this.onStateChanged,
  });

  @override
  State<KamikazePullDropStrategyPanel> createState() =>
      _KamikazePullDropStrategyPanelState();
}

class _KamikazePullDropStrategyPanelState
    extends State<KamikazePullDropStrategyPanel> {
  late KamikazePullIntensity _intensity;
  late TttCountingSafetyMode _safetyMode;
  String? _selectedCandidateId;
  late KamikazePullDropExecutionState _executionState;

  @override
  void initState() {
    super.initState();
    _intensity = widget.initialInput.intensity;
    _safetyMode = widget.initialInput.safetyMode;
    _selectedCandidateId = widget.initialInput.forcedCandidateRiderId;
    final int activeCount =
        widget.initialInput.riders.where((r) => !r.isDropped).length;
    _executionState = KamikazePullDropExecutionState(
      activeRidersRemaining: activeCount,
      currentTrainSpeedKmh: widget.initialInput.currentTrainSpeedKmh,
      statusMessagePl: 'Gotowy do zaciągu Kamikaze.',
    );
  }

  KamikazePullDropInput get _currentInput {
    final droppedSet = _executionState.droppedRiderIds.toSet();
    final updatedRiders = widget.initialInput.riders
        .map(
          (r) => droppedSet.contains(r.riderId)
              ? r.copyWith(isDropped: true)
              : r,
        )
        .toList();
    return KamikazePullDropInput(
      riders: updatedRiders,
      distanceRemainingKm: widget.initialInput.distanceRemainingKm,
      totalStageDistanceKm: widget.initialInput.totalStageDistanceKm,
      currentTrainSpeedKmh: _executionState.currentTrainSpeedKmh,
      roadGradientPercent: widget.initialInput.roadGradientPercent,
      headwindMs: widget.initialInput.headwindMs,
      airDensityKgM3: widget.initialInput.airDensityKgM3,
      crr: widget.initialInput.crr,
      intensity: _intensity,
      safetyMode: _safetyMode,
      forcedCandidateRiderId: _selectedCandidateId,
    );
  }

  void _updateExecution(KamikazePullDropExecutionState next) {
    setState(() {
      _executionState = next;
    });
    widget.onStateChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final plan = TeamTimeTrialRiderDropStrategy.evaluatePlan(_currentInput);
    final String? effectiveCandidateId =
        _selectedCandidateId ?? plan.recommendedCandidate?.riderId;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D), width: 1.0),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isCompact = constraints.maxWidth < 600;
          final bool isWide = constraints.maxWidth >= 1000;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isCompact ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(plan, isCompact),
                const SizedBox(height: 12),
                _buildControlsRow(isCompact),
                const SizedBox(height: 12),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _buildRosterList(plan, effectiveCandidateId)),
                      const SizedBox(width: 12),
                      Expanded(flex: 2, child: _buildActionAndTelemetry(plan, effectiveCandidateId)),
                    ],
                  )
                else ...[
                  _buildActionAndTelemetry(plan, effectiveCandidateId),
                  const SizedBox(height: 12),
                  _buildRosterList(plan, effectiveCandidateId),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(KamikazePullDropPlan plan, bool isCompact) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryAccent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primaryAccent),
          ),
          child: const Icon(
            Icons.bolt_rounded,
            color: AppColors.goldAccent,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TTT: Kamikaze Pull & Drop',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isCompact ? 14 : 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                plan.tacticalSummaryPl,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _StatusBadge(phase: _executionState.phase),
      ],
    );
  }

  Widget _buildControlsRow(bool isCompact) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final intensity in KamikazePullIntensity.values)
          _TacticalChipButton(
            label: intensity.labelPl,
            isSelected: _intensity == intensity,
            isDisabled:
                _executionState.phase == KamikazePullDropPhase.kamikazePullActive,
            onPressed: () {
              setState(() => _intensity = intensity);
            },
          ),
        for (final mode in TttCountingSafetyMode.values)
          _TacticalChipButton(
            label: mode.labelPl,
            isSelected: _safetyMode == mode,
            accentColor: AppColors.goldAccent,
            isDisabled:
                _executionState.phase == KamikazePullDropPhase.kamikazePullActive,
            onPressed: () {
              setState(() => _safetyMode = mode);
            },
          ),
      ],
    );
  }

  Widget _buildActionAndTelemetry(
    KamikazePullDropPlan plan,
    String? effectiveCandidateId,
  ) {
    final bool isActivePull =
        _executionState.phase == KamikazePullDropPhase.kamikazePullActive;
    final bool canLaunch = plan.canExecuteSafely &&
        effectiveCandidateId != null &&
        !isActivePull &&
        _executionState.phase != KamikazePullDropPhase.swingOffAndDrop;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _MetricTile(
                label: 'Prędkość',
                value:
                    '${_executionState.currentTrainSpeedKmh.toStringAsFixed(1)} km/h',
                valueColor: AppColors.accentBlue,
              ),
              const SizedBox(width: 8),
              _MetricTile(
                label: 'Zysk TTT',
                value:
                    '+${_executionState.cumulativeTimeGainedSeconds.toStringAsFixed(2)} s',
                valueColor: AppColors.statusSuccess,
              ),
              const SizedBox(width: 8),
              _MetricTile(
                label: 'Aktywni',
                value:
                    '${plan.activeRidersCount}/${plan.minRequiredFinishers}',
                valueColor: plan.canExecuteSafely
                    ? AppColors.goldAccent
                    : AppColors.crimsonAlert,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TacticalActionButton(
                label: 'Odpal Kamikaze Pull',
                icon: Icons.flash_on_rounded,
                backgroundColor: AppColors.primaryAccent,
                isDisabled: !canLaunch,
                onPressed: () {
                  if (effectiveCandidateId == null) return;
                  _updateExecution(
                    TeamTimeTrialRiderDropStrategy.initiateKamikazePull(
                      currentState: _executionState,
                      input: _currentInput,
                      candidateRiderId: effectiveCandidateId,
                    ),
                  );
                },
              ),
              _TacticalActionButton(
                label: 'Symuluj +5s',
                icon: Icons.fast_forward_rounded,
                backgroundColor: AppColors.accentBlue.withValues(alpha: 0.25),
                isDisabled: !isActivePull,
                onPressed: () {
                  _updateExecution(
                    TeamTimeTrialRiderDropStrategy.stepExecution(
                      state: _executionState,
                      input: _currentInput,
                      dtSeconds: 5.0,
                    ),
                  );
                },
              ),
              _TacticalActionButton(
                label: 'Zjazd & Drop',
                icon: Icons.call_split_rounded,
                backgroundColor: AppColors.amberWarning.withValues(alpha: 0.25),
                isDisabled: !isActivePull,
                onPressed: () {
                  _updateExecution(
                    TeamTimeTrialRiderDropStrategy.forceSwingOffAndDrop(
                      state: _executionState,
                    ),
                  );
                },
              ),
              if (_executionState.phase ==
                  KamikazePullDropPhase.swingOffAndDrop)
                _TacticalActionButton(
                  label: 'Przegrupuj Pociąg',
                  icon: Icons.groups_rounded,
                  backgroundColor:
                      AppColors.statusSuccess.withValues(alpha: 0.25),
                  isDisabled: false,
                  onPressed: () {
                    _updateExecution(
                      TeamTimeTrialRiderDropStrategy.regroupPaceline(
                        state: _executionState,
                      ),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRosterList(
    KamikazePullDropPlan plan,
    String? effectiveCandidateId,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final eval in plan.allEvaluations)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _CandidateRow(
              evaluation: eval,
              isSelected: eval.riderId == effectiveCandidateId,
              isDisabled:
                  eval.verdict == KamikazeCandidateVerdict.alreadyDropped ||
                  eval.verdict == KamikazeCandidateVerdict.protectedGcLeader ||
                  eval.verdict == KamikazeCandidateVerdict.teamBelowSafetyFloor,
              onTap: () {
                setState(() => _selectedCandidateId = eval.riderId);
              },
            ),
          ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final KamikazePullDropPhase phase;

  const _StatusBadge({required this.phase});

  @override
  Widget build(BuildContext context) {
    final Color color;
    switch (phase) {
      case KamikazePullDropPhase.kamikazePullActive:
        color = AppColors.crimsonAlert;
      case KamikazePullDropPhase.swingOffAndDrop:
        color = AppColors.amberWarning;
      case KamikazePullDropPhase.pacelineRegrouped:
      case KamikazePullDropPhase.completed:
        color = AppColors.statusSuccess;
      case KamikazePullDropPhase.abortedSafetyGuard:
        color = AppColors.crimsonAlert;
      case KamikazePullDropPhase.standby:
      case KamikazePullDropPhase.approachingTrigger:
        color = AppColors.accentBlue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        phase.labelPl,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF2A2F3D)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                color: valueColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TacticalChipButton extends StatefulWidget {
  final String label;
  final bool isSelected;
  final bool isDisabled;
  final Color accentColor;
  final VoidCallback onPressed;

  const _TacticalChipButton({
    required this.label,
    required this.isSelected,
    required this.isDisabled,
    this.accentColor = AppColors.primaryAccent,
    required this.onPressed,
  });

  @override
  State<_TacticalChipButton> createState() => _TacticalChipButtonState();
}

class _TacticalChipButtonState extends State<_TacticalChipButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = widget.isDisabled
        ? const Color(0xFF2A2F3D)
        : widget.isSelected || _focused
            ? widget.accentColor
            : _hovered
                ? AppColors.textSecondary
                : const Color(0xFF2A2F3D);

    final Color bgColor = widget.isDisabled
        ? AppColors.surface
        : widget.isSelected
            ? widget.accentColor.withValues(alpha: _pressed ? 0.35 : 0.22)
            : _hovered
                ? AppColors.surfaceLight
                : AppColors.surface;

    return FocusableActionDetector(
      enabled: !widget.isDisabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (!widget.isDisabled) widget.onPressed();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown: widget.isDisabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: widget.isDisabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.isDisabled ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
              color: widget.isDisabled
                  ? AppColors.textSecondary.withValues(alpha: 0.45)
                  : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _TacticalActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final bool isDisabled;
  final VoidCallback onPressed;

  const _TacticalActionButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.isDisabled,
    required this.onPressed,
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
    return FocusableActionDetector(
      enabled: !widget.isDisabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (!widget.isDisabled) widget.onPressed();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown: widget.isDisabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: widget.isDisabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.isDisabled ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isDisabled
                ? AppColors.surface.withValues(alpha: 0.6)
                : _pressed
                    ? widget.backgroundColor.withValues(alpha: 0.9)
                    : _hovered
                        ? widget.backgroundColor.withValues(alpha: 0.75)
                        : widget.backgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _focused && !widget.isDisabled
                  ? AppColors.goldAccent
                  : const Color(0xFF2A2F3D),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 15,
                color: widget.isDisabled
                    ? AppColors.textSecondary.withValues(alpha: 0.4)
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
                      ? AppColors.textSecondary.withValues(alpha: 0.4)
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

class _CandidateRow extends StatefulWidget {
  final KamikazeCandidateEvaluation evaluation;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  const _CandidateRow({
    required this.evaluation,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  State<_CandidateRow> createState() => _CandidateRowState();
}

class _CandidateRowState extends State<_CandidateRow> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final Color statusColor;
    switch (widget.evaluation.verdict) {
      case KamikazeCandidateVerdict.optimalSacrifice:
        statusColor = AppColors.statusSuccess;
      case KamikazeCandidateVerdict.viableSacrifice:
        statusColor = AppColors.accentBlue;
      case KamikazeCandidateVerdict.protectedGcLeader:
      case KamikazeCandidateVerdict.protectedCoreTtEngine:
        statusColor = AppColors.goldAccent;
      case KamikazeCandidateVerdict.insufficientWPrime:
      case KamikazeCandidateVerdict.alreadyDropped:
      case KamikazeCandidateVerdict.teamBelowSafetyFloor:
        statusColor = AppColors.crimsonAlert;
    }

    return FocusableActionDetector(
      enabled: !widget.isDisabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTap: widget.isDisabled ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.primaryAccent.withValues(alpha: 0.16)
                : _hovered && !widget.isDisabled
                    ? AppColors.surfaceLight
                    : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected || _focused
                  ? AppColors.goldAccent
                  : const Color(0xFF2A2F3D),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.evaluation.riderName,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: widget.isDisabled
                            ? AppColors.textSecondary.withValues(alpha: 0.6)
                            : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      widget.evaluation.rationalePl,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.evaluation.estimatedTeamTimeGainSeconds > 0) ...[
                const SizedBox(width: 8),
                Text(
                  '+${widget.evaluation.estimatedTeamTimeGainSeconds.toStringAsFixed(2)}s',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
