// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import '../../models/race/ultra_endurance_bikepacking_race_model.dart';

/// Faza rytmu dobowego (Process C w dwuprocesowym modelu Borbély'ego).
enum CircadianPhaseZone {
  peakAlertness('Peak Alertness', 'Szczyt czujności dobowej'),
  postLunchDip('Post-Lunch Dip', 'Spadek popołudniowy (14:00–15:30)'),
  eveningWindDown('Evening Wind-Down', 'Wieczorne wyciszenie'),
  melatoninOnset('Melatonin Onset', 'Wyrzut melatoniny'),
  circadianNadir('Circadian Nadir', 'Nadir dobowy (02:00–05:30)'),
  dawnRebound('Dawn Rebound', 'Poranny wzrost kortyzolu');

  final String labelEn;
  final String labelPl;

  const CircadianPhaseZone(this.labelEn, this.labelPl);

  String toJson() => name;

  static CircadianPhaseZone fromJson(String value) {
    return CircadianPhaseZone.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CircadianPhaseZone.peakAlertness,
    );
  }
}

/// Poziom klinicznego deficytu snu (`Sleep Debt` — Process S).
enum SleepDeprivationSeverity {
  fresh('Fresh', 'Świeży', false),
  mildFatigue('Mild Fatigue', 'Lekkie zmęczenie', false),
  moderateImpairment('Moderate Impairment', 'Umiarkowane upośledzenie', false),
  severeHallucinationRisk(
    'Severe Hallucination Risk',
    'Ryzyko halucynacji',
    true,
  ),
  criticalMicroSleepDanger(
    'Critical Micro-Sleep Danger',
    'Krytyczne ryzyko mikrosnu!',
    true,
  );

  final String labelEn;
  final String labelPl;
  final bool requiresMandatoryStop;

  const SleepDeprivationSeverity(
    this.labelEn,
    this.labelPl,
    this.requiresMandatoryStop,
  );

  String toJson() => name;

  static SleepDeprivationSeverity fromJson(String value) {
    return SleepDeprivationSeverity.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SleepDeprivationSeverity.fresh,
    );
  }
}

/// Warunki schronienia podczas postoju na sen w wyścigu Ultra-Endurance.
enum BivyShelterCondition {
  warmIndoorHotel('Warm Indoor Hotel', 'Ciepły hotel / pensjonat'),
  dryAlpineBivy('Dry Alpine Bivy', 'Suchy biwak w śpiworze i Bivy'),
  coldWindyBivy('Cold & Windy Bivy', 'Zimny, wietrzny biwak na przełęczy'),
  wetStormBivy('Wet Storm Bivy', 'Biwak w ulewie / wychłodzenie'),
  roadsideBenchMicroNap('Roadside Bench Nap', 'Drzemka na ławce / przystanku');

  final String labelEn;
  final String labelPl;

  const BivyShelterCondition(this.labelEn, this.labelPl);

  String toJson() => name;

  static BivyShelterCondition fromJson(String value) {
    return BivyShelterCondition.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => BivyShelterCondition.dryAlpineBivy,
    );
  }
}

/// Pełny stan fizjologii snu i rytmu dobowego kolarza Ultra-Endurance.
class UltraCircadianSleepState {
  final double elapsedRaceHours;
  final double localClockHour;
  final double hoursSinceLastSleep;
  final double sleepDebtHours;
  final double cumulativeSleepHours;
  final double cognitiveAlertnessPercent;
  final double sleepInertiaRemainingHours;
  final double activeCaffeineMg;
  final int microSleepEventsCount;
  final double hallucinationIntensity;
  final int bivyStopsCount;
  final int hotelStopsCount;
  final int microNapsCount;
  final double totalSleepStopHours;
  final double totalHotelSpendEur;

  const UltraCircadianSleepState({
    this.elapsedRaceHours = 0.0,
    this.localClockHour = 6.0,
    this.hoursSinceLastSleep = 0.0,
    this.sleepDebtHours = 0.0,
    this.cumulativeSleepHours = 0.0,
    this.cognitiveAlertnessPercent = 100.0,
    this.sleepInertiaRemainingHours = 0.0,
    this.activeCaffeineMg = 0.0,
    this.microSleepEventsCount = 0,
    this.hallucinationIntensity = 0.0,
    this.bivyStopsCount = 0,
    this.hotelStopsCount = 0,
    this.microNapsCount = 0,
    this.totalSleepStopHours = 0.0,
    this.totalHotelSpendEur = 0.0,
  });

  UltraCircadianSleepState copyWith({
    double? elapsedRaceHours,
    double? localClockHour,
    double? hoursSinceLastSleep,
    double? sleepDebtHours,
    double? cumulativeSleepHours,
    double? cognitiveAlertnessPercent,
    double? sleepInertiaRemainingHours,
    double? activeCaffeineMg,
    int? microSleepEventsCount,
    double? hallucinationIntensity,
    int? bivyStopsCount,
    int? hotelStopsCount,
    int? microNapsCount,
    double? totalSleepStopHours,
    double? totalHotelSpendEur,
  }) {
    return UltraCircadianSleepState(
      elapsedRaceHours: elapsedRaceHours ?? this.elapsedRaceHours,
      localClockHour: localClockHour ?? this.localClockHour,
      hoursSinceLastSleep: hoursSinceLastSleep ?? this.hoursSinceLastSleep,
      sleepDebtHours: sleepDebtHours ?? this.sleepDebtHours,
      cumulativeSleepHours: cumulativeSleepHours ?? this.cumulativeSleepHours,
      cognitiveAlertnessPercent:
          cognitiveAlertnessPercent ?? this.cognitiveAlertnessPercent,
      sleepInertiaRemainingHours:
          sleepInertiaRemainingHours ?? this.sleepInertiaRemainingHours,
      activeCaffeineMg: activeCaffeineMg ?? this.activeCaffeineMg,
      microSleepEventsCount:
          microSleepEventsCount ?? this.microSleepEventsCount,
      hallucinationIntensity:
          hallucinationIntensity ?? this.hallucinationIntensity,
      bivyStopsCount: bivyStopsCount ?? this.bivyStopsCount,
      hotelStopsCount: hotelStopsCount ?? this.hotelStopsCount,
      microNapsCount: microNapsCount ?? this.microNapsCount,
      totalSleepStopHours: totalSleepStopHours ?? this.totalSleepStopHours,
      totalHotelSpendEur: totalHotelSpendEur ?? this.totalHotelSpendEur,
    );
  }

  Map<String, dynamic> toJson() => {
    'elapsedRaceHours': elapsedRaceHours,
    'localClockHour': localClockHour,
    'hoursSinceLastSleep': hoursSinceLastSleep,
    'sleepDebtHours': sleepDebtHours,
    'cumulativeSleepHours': cumulativeSleepHours,
    'cognitiveAlertnessPercent': cognitiveAlertnessPercent,
    'sleepInertiaRemainingHours': sleepInertiaRemainingHours,
    'activeCaffeineMg': activeCaffeineMg,
    'microSleepEventsCount': microSleepEventsCount,
    'hallucinationIntensity': hallucinationIntensity,
    'bivyStopsCount': bivyStopsCount,
    'hotelStopsCount': hotelStopsCount,
    'microNapsCount': microNapsCount,
    'totalSleepStopHours': totalSleepStopHours,
    'totalHotelSpendEur': totalHotelSpendEur,
  };

  factory UltraCircadianSleepState.fromJson(Map<String, dynamic> json) {
    return UltraCircadianSleepState(
      elapsedRaceHours: (json['elapsedRaceHours'] as num?)?.toDouble() ?? 0.0,
      localClockHour: (json['localClockHour'] as num?)?.toDouble() ?? 6.0,
      hoursSinceLastSleep:
          (json['hoursSinceLastSleep'] as num?)?.toDouble() ?? 0.0,
      sleepDebtHours: (json['sleepDebtHours'] as num?)?.toDouble() ?? 0.0,
      cumulativeSleepHours:
          (json['cumulativeSleepHours'] as num?)?.toDouble() ?? 0.0,
      cognitiveAlertnessPercent:
          (json['cognitiveAlertnessPercent'] as num?)?.toDouble() ?? 100.0,
      sleepInertiaRemainingHours:
          (json['sleepInertiaRemainingHours'] as num?)?.toDouble() ?? 0.0,
      activeCaffeineMg: (json['activeCaffeineMg'] as num?)?.toDouble() ?? 0.0,
      microSleepEventsCount:
          (json['microSleepEventsCount'] as num?)?.toInt() ?? 0,
      hallucinationIntensity:
          (json['hallucinationIntensity'] as num?)?.toDouble() ?? 0.0,
      bivyStopsCount: (json['bivyStopsCount'] as num?)?.toInt() ?? 0,
      hotelStopsCount: (json['hotelStopsCount'] as num?)?.toInt() ?? 0,
      microNapsCount: (json['microNapsCount'] as num?)?.toInt() ?? 0,
      totalSleepStopHours:
          (json['totalSleepStopHours'] as num?)?.toDouble() ?? 0.0,
      totalHotelSpendEur:
          (json['totalHotelSpendEur'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Parametry kroku jazdy w symulacji fizjologii snu.
class UltraSleepPhysiologyStepInput {
  final double durationHours;
  final double ambientTempCelsius;
  final bool isRaining;
  final double windSpeedKmh;
  final double elevationMeters;
  final double caffeineIntakeMg;
  final double riderResilience;
  final bool isTechnicalDescent;
  final double? deterministicRoll;

  const UltraSleepPhysiologyStepInput({
    required this.durationHours,
    this.ambientTempCelsius = 14.0,
    this.isRaining = false,
    this.windSpeedKmh = 12.0,
    this.elevationMeters = 400.0,
    this.caffeineIntakeMg = 0.0,
    this.riderResilience = 75.0,
    this.isTechnicalDescent = false,
    this.deterministicRoll,
  });
}

/// Wynik kroku jazdy dla fizjologii braku snu i rytmu dobowego.
class UltraSleepPhysiologyStepResult {
  final UltraCircadianSleepState nextState;
  final CircadianPhaseZone circadianPhase;
  final SleepDeprivationSeverity severity;
  final double circadianAlertnessFactor;
  final double sleepDebtPowerMultiplier;
  final double effectivePowerMultiplier;
  final double reactionTimePenaltySeconds;
  final double microSleepProbabilityPerHour;
  final bool microSleepTriggered;
  final double hallucinationRisk;
  final double caffeineBoostPercent;
  final String recommendedActionPl;
  final String recommendedActionEn;

  const UltraSleepPhysiologyStepResult({
    required this.nextState,
    required this.circadianPhase,
    required this.severity,
    required this.circadianAlertnessFactor,
    required this.sleepDebtPowerMultiplier,
    required this.effectivePowerMultiplier,
    required this.reactionTimePenaltySeconds,
    required this.microSleepProbabilityPerHour,
    required this.microSleepTriggered,
    required this.hallucinationRisk,
    required this.caffeineBoostPercent,
    required this.recommendedActionPl,
    required this.recommendedActionEn,
  });
}

/// Dane wejściowe oceny postoju na sen (Bivy vs Hotel vs Drzemka).
class SleepStopEvaluationInput {
  final UltraCircadianSleepState currentState;
  final UltraSleepStrategy strategy;
  final BivyShelterCondition shelterCondition;
  final BikepackingLoadout loadout;
  final double ambientTempCelsius;
  final bool isRaining;
  final double hotelDetourHours;
  final double hotelCostEur;
  final double cruisingSpeedKmh;

  const SleepStopEvaluationInput({
    required this.currentState,
    required this.strategy,
    required this.shelterCondition,
    this.loadout = const BikepackingLoadout(bags: []),
    this.ambientTempCelsius = 8.0,
    this.isRaining = false,
    this.hotelDetourHours = 0.45,
    this.hotelCostEur = 85.0,
    this.cruisingSpeedKmh = 26.0,
  });
}

/// Szczegółowy wynik fizjologiczny i czasowy postoju na sen.
class SleepStopEvaluationResult {
  final UltraSleepStrategy strategy;
  final BivyShelterCondition shelterCondition;
  final UltraCircadianSleepState nextState;
  final double sleepDurationHours;
  final double setupAndDetourOverheadHours;
  final double totalStoppedHours;
  final double sleepQualityMultiplier;
  final double thermalComfortScore;
  final double hypothermiaRisk;
  final double debtRecoveredHours;
  final double alertnessGainedPercent;
  final double postWakeSleepInertiaHours;
  final bool electronicsRecharged;
  final double effectiveSpeedRecoveryKmh;
  final double netTimeDeltaOverNext12Hours;
  final String verdictPl;
  final String verdictEn;

  const SleepStopEvaluationResult({
    required this.strategy,
    required this.shelterCondition,
    required this.nextState,
    required this.sleepDurationHours,
    required this.setupAndDetourOverheadHours,
    required this.totalStoppedHours,
    required this.sleepQualityMultiplier,
    required this.thermalComfortScore,
    required this.hypothermiaRisk,
    required this.debtRecoveredHours,
    required this.alertnessGainedPercent,
    required this.postWakeSleepInertiaHours,
    required this.electronicsRecharged,
    required this.effectiveSpeedRecoveryKmh,
    required this.netTimeDeltaOverNext12Hours,
    required this.verdictPl,
    required this.verdictEn,
  });
}

/// Raport porównawczy strategii snu: Bivy Bag vs Hotel vs Mikrodrzemka 20 min.
class BivyVsHotelComparisonReport {
  final SleepStopEvaluationResult bivyEvaluation;
  final SleepStopEvaluationResult hotelEvaluation;
  final SleepStopEvaluationResult microNapEvaluation;
  final double pushThroughProjectedMultiplier;
  final UltraSleepStrategy recommendedStrategy;
  final double timeAdvantageHours;
  final String summaryPl;
  final String summaryEn;

  const BivyVsHotelComparisonReport({
    required this.bivyEvaluation,
    required this.hotelEvaluation,
    required this.microNapEvaluation,
    required this.pushThroughProjectedMultiplier,
    required this.recommendedStrategy,
    required this.timeAdvantageHours,
    required this.summaryPl,
    required this.summaryEn,
  });
}

/// Solver fizjologii braku snu (`Sleep Debt`), rytmu dobowego (Borbély Process S + C)
/// oraz taktycznych postojów w śpiworze Bivy vs hotele w wyścigach Ultra-Endurance.
class UltraSleepDeprivationAndCircadianSolver {
  const UltraSleepDeprivationAndCircadianSolver._();

  /// Okres półtrwania kofeiny w organizmie (h).
  static const double _caffeineHalfLifeHours = 5.0;

  /// Normalizuje godzinę zegarową do przedziału [0.0, 24.0).
  static double normalizeClockHour(double hour) {
    final mod = hour % 24.0;
    return mod < 0.0 ? mod + 24.0 : mod;
  }

  /// Klasyfikuje fazę rytmu dobowego na podstawie lokalnej godziny zegarowej.
  static CircadianPhaseZone classifyCircadianPhase(double localClockHour) {
    final h = normalizeClockHour(localClockHour);
    if (h >= 2.0 && h < 5.5) {
      return CircadianPhaseZone.circadianNadir;
    }
    if (h >= 5.5 && h < 8.5) {
      return CircadianPhaseZone.dawnRebound;
    }
    if (h >= 13.5 && h < 15.5) {
      return CircadianPhaseZone.postLunchDip;
    }
    if (h >= 21.0 && h < 23.5) {
      return CircadianPhaseZone.eveningWindDown;
    }
    if (h >= 23.5 || h < 2.0) {
      return CircadianPhaseZone.melatoninOnset;
    }
    return CircadianPhaseZone.peakAlertness;
  }

  /// Oblicza ciągłą krzywą czujności rytmu dobowego (Process C, 0.66–1.04).
  ///
  /// Uwzględnia główny nadir okołodobowy (~03:45) oraz wtórny spadek popołudniowy (~14:30).
  static double computeCircadianCurve(double localClockHour) {
    final h = normalizeClockHour(localClockHour);
    // Główna składowa 24h: minimum ok. 03:45 (3.75 h), maksimum ok. 15:45
    final primaryPhaseRad = ((h - 3.75) / 24.0) * 2.0 * math.pi;
    final primaryWave = -math.cos(primaryPhaseRad); // [-1.0, +1.0]

    // Druga harmoniczna (12h) modelująca popołudniowy spadek ok. 14:30
    final secondaryPhaseRad = ((h - 14.5) / 12.0) * 2.0 * math.pi;
    final secondaryDip = -math.cos(secondaryPhaseRad);

    // Normalizacja do fizjologicznego zakresu mnożnika [0.66, 1.04]
    final raw = 0.86 + 0.13 * primaryWave + 0.08 * secondaryDip;
    return raw.clamp(0.66, 1.04);
  }

  /// Klasyfikuje kliniczny stopień deficytu snu.
  static SleepDeprivationSeverity classifyDeprivationSeverity(
    UltraCircadianSleepState state,
  ) {
    if (state.sleepDebtHours >= 14.0 ||
        state.hoursSinceLastSleep >= 40.0 ||
        state.microSleepEventsCount >= 2) {
      return SleepDeprivationSeverity.criticalMicroSleepDanger;
    }
    if (state.sleepDebtHours >= 9.0 || state.hoursSinceLastSleep >= 30.0) {
      return SleepDeprivationSeverity.severeHallucinationRisk;
    }
    if (state.sleepDebtHours >= 5.0 || state.hoursSinceLastSleep >= 22.0) {
      return SleepDeprivationSeverity.moderateImpairment;
    }
    if (state.sleepDebtHours >= 2.0 || state.hoursSinceLastSleep >= 16.0) {
      return SleepDeprivationSeverity.mildFatigue;
    }
    return SleepDeprivationSeverity.fresh;
  }

  /// Oblicza krok fizjologiczny podczas jazdy (akumulacja Sleep Debt, rozpad kofeiny,
  /// wpływ rytmu dobowego, inercji snu oraz ryzyko mikrosnu i halucynacji).
  static UltraSleepPhysiologyStepResult stepRidingPhysiology(
    UltraCircadianSleepState state,
    UltraSleepPhysiologyStepInput input,
  ) {
    final dt = math.max(0.0, input.durationHours);
    final resilienceFactor =
        (0.85 + (input.riderResilience.clamp(0.0, 100.0) / 100.0) * 0.30);

    final nextClock = normalizeClockHour(state.localClockHour + dt);
    final nextElapsed = state.elapsedRaceHours + dt;
    final nextAwake = state.hoursSinceLastSleep + dt;

    // Proces S: przeciętny człowiek potrzebuje ~7.5 h snu na 24 h => ok. 0.3125 h długu na każdą godzinę czuwania
    // Odporność kolarza ultra zmniejsza tempo akumulacji długu.
    final debtRatePerHour = (0.31 / resilienceFactor) *
        (input.elevationMeters > 2000.0 ? 1.10 : 1.0) *
        (input.isRaining && input.ambientTempCelsius < 6.0 ? 1.08 : 1.0);
    final nextDebt = math.max(0.0, state.sleepDebtHours + dt * debtRatePerHour);

    // Rozpad kofeiny (okres półtrwania ~5 h) + przyjęcie nowej dawki
    final decayFactor = dt > 0.0
        ? math.pow(0.5, dt / _caffeineHalfLifeHours).toDouble()
        : 1.0;
    final nextCaffeine =
        (state.activeCaffeineMg * decayFactor + math.max(0.0, input.caffeineIntakeMg))
            .clamp(0.0, 600.0);

    // Efekt maskowania zmęczenia przez kofeinę (maleje przy wysokim długu snu)
    final caffeineSaturation = (nextCaffeine / 200.0).clamp(0.0, 1.0);
    final tolerancePenalty = (1.0 - (nextDebt / 24.0)).clamp(0.35, 1.0);
    final caffeineBoostPercent = caffeineSaturation * 12.0 * tolerancePenalty;

    // Inercja snu po przebudzeniu
    final nextInertia = math.max(0.0, state.sleepInertiaRemainingHours - dt);
    final inertiaPenalty = nextInertia > 0.0 ? (nextInertia * 0.16).clamp(0.0, 0.15) : 0.0;

    // Proces C: rytm dobowy w połowie kroku
    final midClock = normalizeClockHour(state.localClockHour + dt * 0.5);
    final circadianPhase = classifyCircadianPhase(midClock);
    final circadianFactor = computeCircadianCurve(midClock);

    // Spadek mocy wynikający z deficytu snu (0.64–1.0)
    final acuteDrop = math.max(0.0, (nextAwake - 16.0) * 0.0068);
    final chronicDrop = math.max(0.0, (nextDebt - 3.5) * 0.0095);
    final sleepDebtPowerMultiplier =
        (1.0 - acuteDrop - chronicDrop).clamp(0.64, 1.0);

    // Łączny mnożnik efektywnej mocy (z kofeiną i bezwładnością snu)
    final caffeinePowerBoost = 1.0 + (caffeineBoostPercent / 100.0) * 0.35;
    final effectivePowerMultiplier = (sleepDebtPowerMultiplier *
            (0.82 + 0.18 * circadianFactor) *
            (1.0 - inertiaPenalty) *
            caffeinePowerBoost)
        .clamp(0.58, 1.02);

    // Spadek czujności poznawczej
    final circadianDropBonus =
        circadianPhase == CircadianPhaseZone.circadianNadir ? 1.55 : 1.0;
    final rawAlertnessDrop =
        dt * (2.6 + math.max(0.0, nextAwake - 18.0) * 0.22) * circadianDropBonus /
            resilienceFactor;
    final baseAlertness =
        (state.cognitiveAlertnessPercent - rawAlertnessDrop).clamp(8.0, 100.0);
    final effectiveAlertness =
        (baseAlertness + caffeineBoostPercent * 0.75 - inertiaPenalty * 45.0)
            .clamp(5.0, 100.0);

    // Ryzyko halucynacji i mikrosnu
    final nightMultiplier =
        (circadianPhase == CircadianPhaseZone.circadianNadir ||
                circadianPhase == CircadianPhaseZone.melatoninOnset)
            ? 1.55
            : 0.72;
    final rawHallucination =
        (math.max(0.0, nextAwake - 22.0) / 28.0 +
                math.max(0.0, nextDebt - 7.0) / 18.0) *
            0.5 *
            nightMultiplier /
            resilienceFactor;
    final hallucinationRisk = rawHallucination.clamp(0.0, 1.0);

    final microSleepProbPerHour =
        ((math.max(0.0, nextAwake - 24.0) * 0.018 +
                    math.max(0.0, nextDebt - 8.0) * 0.024) *
                nightMultiplier *
                (1.0 - caffeineSaturation * 0.35))
            .clamp(0.0, 0.85);

    final stepMicroSleepProb =
        (1.0 - math.pow(1.0 - microSleepProbPerHour, dt)).toDouble();
    final microSleepTriggered = input.deterministicRoll != null &&
        dt > 0.0 &&
        input.deterministicRoll!.clamp(0.0, 1.0) < stepMicroSleepProb;

    final reactionTimePenaltySeconds = ((1.0 - effectiveAlertness / 100.0) * 1.15 +
            (input.isTechnicalDescent ? 0.25 : 0.0) * (1.0 - circadianFactor))
        .clamp(0.0, 1.45);

    final nextState = state.copyWith(
      elapsedRaceHours: nextElapsed,
      localClockHour: nextClock,
      hoursSinceLastSleep: nextAwake,
      sleepDebtHours: nextDebt,
      cognitiveAlertnessPercent: effectiveAlertness,
      sleepInertiaRemainingHours: nextInertia,
      activeCaffeineMg: nextCaffeine,
      microSleepEventsCount:
          state.microSleepEventsCount + (microSleepTriggered ? 1 : 0),
      hallucinationIntensity: hallucinationRisk,
    );

    final severity = classifyDeprivationSeverity(nextState);
    final (actionPl, actionEn) = _buildStepRecommendation(
      severity: severity,
      circadianPhase: circadianPhase,
      microSleepTriggered: microSleepTriggered,
      caffeineMg: nextCaffeine,
    );

    return UltraSleepPhysiologyStepResult(
      nextState: nextState,
      circadianPhase: circadianPhase,
      severity: severity,
      circadianAlertnessFactor: circadianFactor,
      sleepDebtPowerMultiplier: sleepDebtPowerMultiplier,
      effectivePowerMultiplier: effectivePowerMultiplier,
      reactionTimePenaltySeconds: reactionTimePenaltySeconds,
      microSleepProbabilityPerHour: microSleepProbPerHour,
      microSleepTriggered: microSleepTriggered,
      hallucinationRisk: hallucinationRisk,
      caffeineBoostPercent: caffeineBoostPercent,
      recommendedActionPl: actionPl,
      recommendedActionEn: actionEn,
    );
  }

  /// Ocenia pojedynczy postój na sen (mikrodrzemka 20 min, cykl 90 min, biwak 4 h, hotel 5 h).
  static SleepStopEvaluationResult evaluateSleepStop(
    SleepStopEvaluationInput input,
  ) {
    final strategy = input.strategy;
    final sleepHours = strategy.durationHours;
    final state = input.currentState;

    if (strategy == UltraSleepStrategy.pushThroughNight || sleepHours <= 0.0) {
      final projected = stepRidingPhysiology(
        state,
        UltraSleepPhysiologyStepInput(
          durationHours: 4.0,
          ambientTempCelsius: input.ambientTempCelsius,
          isRaining: input.isRaining,
        ),
      );
      return SleepStopEvaluationResult(
        strategy: strategy,
        shelterCondition: input.shelterCondition,
        nextState: projected.nextState,
        sleepDurationHours: 0.0,
        setupAndDetourOverheadHours: 0.0,
        totalStoppedHours: 0.0,
        sleepQualityMultiplier: 0.0,
        thermalComfortScore: input.isRaining ? 25.0 : 50.0,
        hypothermiaRisk: input.ambientTempCelsius < 5.0 && input.isRaining
            ? 0.45
            : 0.10,
        debtRecoveredHours: 0.0,
        alertnessGainedPercent: -12.0,
        postWakeSleepInertiaHours: 0.0,
        electronicsRecharged: false,
        effectiveSpeedRecoveryKmh: 0.0,
        netTimeDeltaOverNext12Hours: -0.8,
        verdictPl: 'Jazda non-stop bez snu — wysokie ryzyko mikrosnu nad ranem.',
        verdictEn: 'Push through night — high micro-sleep risk toward dawn.',
      );
    }

    // Czas narzutu (zjazd z trasy + zameldowanie w hotelu vs rozłożenie bivy na poboczu)
    final double overheadHours;
    switch (strategy) {
      case UltraSleepStrategy.microNap20Min:
        overheadHours = 0.05;
        break;
      case UltraSleepStrategy.powerSleep90Min:
        overheadHours = 0.12;
        break;
      case UltraSleepStrategy.bivy4Hours:
        overheadHours = 0.18;
        break;
      case UltraSleepStrategy.hotel5Hours:
        overheadHours = math.max(0.20, input.hotelDetourHours);
        break;
      case UltraSleepStrategy.pushThroughNight:
        overheadHours = 0.0;
        break;
    }

    // Ocena termiki i jakości snu zależna od sprzętu i warunków atmosferycznych
    final (qualityMult, thermalComfort, hypothermiaRisk) =
        _evaluateShelterQuality(
      shelter: input.shelterCondition,
      loadout: input.loadout,
      ambientTempCelsius: input.ambientTempCelsius,
      isRaining: input.isRaining,
    );

    // Kofeina w organizmie obniża efektywność głębokiego snu NREM/REM
    final caffeineDisruption =
        (1.0 - (state.activeCaffeineMg / 500.0) * 0.25).clamp(0.75, 1.0);

    // Bonus fazy: sen w nocy (melatonina / nadir) regeneruje głębiej niż w środku dnia
    final clockPhase = classifyCircadianPhase(state.localClockHour);
    final circadianSleepBonus =
        (clockPhase == CircadianPhaseZone.melatoninOnset ||
                clockPhase == CircadianPhaseZone.circadianNadir)
            ? 1.10
            : 0.92;

    final effectiveQuality =
        (qualityMult * caffeineDisruption * circadianSleepBonus).clamp(0.35, 1.25);

    // Fizjologia regeneracji długu snu:
    // Mikrodrzemka 20 min daje szybki zastrzyk czujności, ale niemal nie redukuje długu S.
    final debtRecovered = strategy == UltraSleepStrategy.microNap20Min
        ? math.min(state.sleepDebtHours, 0.25 * effectiveQuality)
        : math.min(state.sleepDebtHours, sleepHours * 1.15 * effectiveQuality);

    final alertnessGained = strategy == UltraSleepStrategy.microNap20Min
        ? (22.0 * effectiveQuality).clamp(8.0, 30.0)
        : (sleepHours * 19.5 * effectiveQuality).clamp(15.0, 75.0);

    // Inercja snu: drzemka <= 25 min budzi w lekkiej fazie N1/N2 (zero inercji);
    // 90 min trafia w koniec cyklu REM (minimalna inercja); 4-5 h w zimnie może dać inercję.
    final postWakeInertia = switch (strategy) {
      UltraSleepStrategy.microNap20Min => 0.0,
      UltraSleepStrategy.powerSleep90Min => 0.15,
      UltraSleepStrategy.bivy4Hours =>
        input.shelterCondition == BivyShelterCondition.coldWindyBivy ||
                input.shelterCondition == BivyShelterCondition.wetStormBivy
            ? 0.45
            : 0.25,
      UltraSleepStrategy.hotel5Hours => 0.20,
      UltraSleepStrategy.pushThroughNight => 0.0,
    };

    final totalStopped = sleepHours + overheadHours;
    final nextClock = normalizeClockHour(state.localClockHour + totalStopped);

    // Rozpad kofeiny podczas snu
    final sleepCaffeineDecay =
        math.pow(0.5, totalStopped / _caffeineHalfLifeHours).toDouble();

    final isHotel = strategy == UltraSleepStrategy.hotel5Hours ||
        input.shelterCondition == BivyShelterCondition.warmIndoorHotel;
    final isMicro = strategy == UltraSleepStrategy.microNap20Min;

    final nextState = state.copyWith(
      elapsedRaceHours: state.elapsedRaceHours + totalStopped,
      localClockHour: nextClock,
      hoursSinceLastSleep: 0.0,
      sleepDebtHours: math.max(0.0, state.sleepDebtHours - debtRecovered),
      cumulativeSleepHours: state.cumulativeSleepHours + sleepHours,
      cognitiveAlertnessPercent:
          (state.cognitiveAlertnessPercent + alertnessGained).clamp(15.0, 100.0),
      sleepInertiaRemainingHours: postWakeInertia,
      activeCaffeineMg: state.activeCaffeineMg * sleepCaffeineDecay,
      hallucinationIntensity: 0.0,
      bivyStopsCount:
          state.bivyStopsCount + (!isHotel && !isMicro ? 1 : 0),
      hotelStopsCount: state.hotelStopsCount + (isHotel ? 1 : 0),
      microNapsCount: state.microNapsCount + (isMicro ? 1 : 0),
      totalSleepStopHours: state.totalSleepStopHours + totalStopped,
      totalHotelSpendEur:
          state.totalHotelSpendEur + (isHotel ? input.hotelCostEur : 0.0),
    );

    // Projekcja zysku prędkości przez kolejne 12 h jazdy względem jazdy bez snu
    final beforeMult = _projectPowerMultiplier(state);
    final afterMult = _projectPowerMultiplier(nextState);
    final speedGainKmh =
        math.max(0.0, (afterMult - beforeMult) * input.cruisingSpeedKmh * 0.72);

    // Zysk dystansu w 12 h po śnie minus dystans stracony na postój
    final baseSpeedBefore = input.cruisingSpeedKmh * (0.72 + 0.28 * beforeMult);
    final speedAfter = input.cruisingSpeedKmh * (0.72 + 0.28 * afterMult);
    final ridingHoursInWindow = math.max(0.0, 12.0 - totalStopped);
    final distWithSleep = ridingHoursInWindow * speedAfter;
    final distWithoutSleep = 12.0 * (baseSpeedBefore * 0.92);
    final netTimeDelta =
        (distWithSleep - distWithoutSleep) / math.max(12.0, input.cruisingSpeedKmh);

    final (verdictPl, verdictEn) = _buildStopVerdict(
      strategy: strategy,
      shelter: input.shelterCondition,
      hypothermiaRisk: hypothermiaRisk,
      netDeltaHours: netTimeDelta,
    );

    return SleepStopEvaluationResult(
      strategy: strategy,
      shelterCondition: input.shelterCondition,
      nextState: nextState,
      sleepDurationHours: sleepHours,
      setupAndDetourOverheadHours: overheadHours,
      totalStoppedHours: totalStopped,
      sleepQualityMultiplier: effectiveQuality,
      thermalComfortScore: thermalComfort,
      hypothermiaRisk: hypothermiaRisk,
      debtRecoveredHours: debtRecovered,
      alertnessGainedPercent: alertnessGained,
      postWakeSleepInertiaHours: postWakeInertia,
      electronicsRecharged: isHotel,
      effectiveSpeedRecoveryKmh: speedGainKmh,
      netTimeDeltaOverNext12Hours: netTimeDelta,
      verdictPl: verdictPl,
      verdictEn: verdictEn,
    );
  }

  /// Porównuje opłacalność biwaku (Bivy), hotelu (5h) oraz mikrodrzemki (20 min).
  static BivyVsHotelComparisonReport compareBivyVsHotelStrategies({
    required UltraCircadianSleepState currentState,
    required BikepackingLoadout loadout,
    double ambientTempCelsius = 7.0,
    bool isRaining = false,
    double hotelDetourHours = 0.45,
    double hotelCostEur = 90.0,
    double cruisingSpeedKmh = 26.0,
  }) {
    final bivyShelter = isRaining
        ? BivyShelterCondition.wetStormBivy
        : (ambientTempCelsius < 5.0
            ? BivyShelterCondition.coldWindyBivy
            : BivyShelterCondition.dryAlpineBivy);

    final bivyEval = evaluateSleepStop(
      SleepStopEvaluationInput(
        currentState: currentState,
        strategy: UltraSleepStrategy.bivy4Hours,
        shelterCondition: bivyShelter,
        loadout: loadout,
        ambientTempCelsius: ambientTempCelsius,
        isRaining: isRaining,
        cruisingSpeedKmh: cruisingSpeedKmh,
      ),
    );

    final hotelEval = evaluateSleepStop(
      SleepStopEvaluationInput(
        currentState: currentState,
        strategy: UltraSleepStrategy.hotel5Hours,
        shelterCondition: BivyShelterCondition.warmIndoorHotel,
        loadout: loadout,
        ambientTempCelsius: ambientTempCelsius,
        isRaining: isRaining,
        hotelDetourHours: hotelDetourHours,
        hotelCostEur: hotelCostEur,
        cruisingSpeedKmh: cruisingSpeedKmh,
      ),
    );

    final microNapEval = evaluateSleepStop(
      SleepStopEvaluationInput(
        currentState: currentState,
        strategy: UltraSleepStrategy.microNap20Min,
        shelterCondition: BivyShelterCondition.roadsideBenchMicroNap,
        loadout: loadout,
        ambientTempCelsius: ambientTempCelsius,
        isRaining: isRaining,
        cruisingSpeedKmh: cruisingSpeedKmh,
      ),
    );

    final pushMultiplier = _projectPowerMultiplier(currentState);
    final severity = classifyDeprivationSeverity(currentState);

    final UltraSleepStrategy recommended;
    final double timeAdvantage;
    if (severity.requiresMandatoryStop &&
        (isRaining || ambientTempCelsius < 4.0 || !loadout.hasBivyBag)) {
      recommended = UltraSleepStrategy.hotel5Hours;
      timeAdvantage = hotelEval.netTimeDeltaOverNext12Hours -
          bivyEval.netTimeDeltaOverNext12Hours;
    } else if (currentState.sleepDebtHours >= 6.0) {
      if (bivyEval.netTimeDeltaOverNext12Hours >=
          hotelEval.netTimeDeltaOverNext12Hours) {
        recommended = UltraSleepStrategy.bivy4Hours;
        timeAdvantage = bivyEval.netTimeDeltaOverNext12Hours -
            hotelEval.netTimeDeltaOverNext12Hours;
      } else {
        recommended = UltraSleepStrategy.hotel5Hours;
        timeAdvantage = hotelEval.netTimeDeltaOverNext12Hours -
            bivyEval.netTimeDeltaOverNext12Hours;
      }
    } else if (currentState.hoursSinceLastSleep >= 18.0) {
      recommended = UltraSleepStrategy.microNap20Min;
      timeAdvantage = microNapEval.netTimeDeltaOverNext12Hours -
          bivyEval.netTimeDeltaOverNext12Hours;
    } else {
      recommended = UltraSleepStrategy.pushThroughNight;
      timeAdvantage = 0.0;
    }

    final summaryPl =
        'Rekomendacja: ${recommended.name} | Bivy jakość ${(bivyEval.sleepQualityMultiplier * 100).round()}% vs Hotel ${(hotelEval.sleepQualityMultiplier * 100).round()}%.';
    final summaryEn =
        'Recommended: ${recommended.name} | Bivy quality ${(bivyEval.sleepQualityMultiplier * 100).round()}% vs Hotel ${(hotelEval.sleepQualityMultiplier * 100).round()}%.';

    return BivyVsHotelComparisonReport(
      bivyEvaluation: bivyEval,
      hotelEvaluation: hotelEval,
      microNapEvaluation: microNapEval,
      pushThroughProjectedMultiplier: pushMultiplier,
      recommendedStrategy: recommended,
      timeAdvantageHours: timeAdvantage,
      summaryPl: summaryPl,
      summaryEn: summaryEn,
    );
  }

  /// Symuluje 24-godzinny profil rytmu dobowego i narastania długu snu (np. do wykresów UI).
  static List<UltraSleepPhysiologyStepResult> simulate24HourCircadianProfile(
    UltraCircadianSleepState initialState, {
    double ambientNightTempC = 8.0,
    double riderResilience = 75.0,
  }) {
    final samples = <UltraSleepPhysiologyStepResult>[];
    var current = initialState;

    for (var i = 0; i < 24; i++) {
      final isNight = current.localClockHour >= 21.0 || current.localClockHour < 6.0;
      final step = stepRidingPhysiology(
        current,
        UltraSleepPhysiologyStepInput(
          durationHours: 1.0,
          ambientTempCelsius: isNight ? ambientNightTempC : ambientNightTempC + 9.0,
          riderResilience: riderResilience,
        ),
      );
      samples.add(step);
      current = step.nextState;
    }
    return samples;
  }

  static double _projectPowerMultiplier(UltraCircadianSleepState state) {
    final acuteDrop = math.max(0.0, (state.hoursSinceLastSleep - 16.0) * 0.0068);
    final chronicDrop = math.max(0.0, (state.sleepDebtHours - 3.5) * 0.0095);
    return (1.0 - acuteDrop - chronicDrop).clamp(0.64, 1.0);
  }

  static (double quality, double thermalComfort, double hypothermiaRisk)
      _evaluateShelterQuality({
    required BivyShelterCondition shelter,
    required BikepackingLoadout loadout,
    required double ambientTempCelsius,
    required bool isRaining,
  }) {
    if (shelter == BivyShelterCondition.warmIndoorHotel) {
      return (1.18, 98.0, 0.0);
    }

    if (shelter == BivyShelterCondition.roadsideBenchMicroNap) {
      final coldPenalty = ambientTempCelsius < 8.0 ? 0.12 : 0.0;
      final rainPenalty = isRaining ? 0.18 : 0.0;
      return (
        (0.76 - coldPenalty - rainPenalty).clamp(0.40, 0.85),
        (64.0 - (12.0 - ambientTempCelsius).clamp(0.0, 30.0)).clamp(20.0, 75.0),
        isRaining && ambientTempCelsius < 6.0 ? 0.25 : 0.04,
      );
    }

    var quality = 0.90;
    var thermal = 78.0;
    var hypo = 0.04;

    if (!loadout.hasBivyBag) {
      quality -= 0.22;
      thermal -= 24.0;
      hypo += 0.22;
    }
    if (!loadout.hasSleepingBag) {
      quality -= 0.25;
      thermal -= 28.0;
      hypo += 0.26;
    }
    if (loadout.hasDownJacket) {
      thermal += 8.0;
    }
    if (ambientTempCelsius < 4.0) {
      final coldDelta = 4.0 - ambientTempCelsius;
      quality -= (coldDelta * 0.025).clamp(0.0, 0.25);
      thermal -= (coldDelta * 3.5).clamp(0.0, 35.0);
      hypo += (coldDelta * 0.035).clamp(0.0, 0.35);
    }
    if (isRaining || shelter == BivyShelterCondition.wetStormBivy) {
      final rainHit = loadout.hasRainShell && loadout.hasBivyBag ? 0.10 : 0.28;
      quality -= rainHit;
      thermal -= rainHit * 65.0;
      hypo += rainHit * 0.85;
    }
    if (shelter == BivyShelterCondition.coldWindyBivy) {
      quality -= 0.08;
      thermal -= 10.0;
      hypo += 0.08;
    }

    return (
      quality.clamp(0.35, 1.05),
      thermal.clamp(10.0, 95.0),
      hypo.clamp(0.0, 0.95),
    );
  }

  static (String pl, String en) _buildStepRecommendation({
    required SleepDeprivationSeverity severity,
    required CircadianPhaseZone circadianPhase,
    required bool microSleepTriggered,
    required double caffeineMg,
  }) {
    if (microSleepTriggered ||
        severity == SleepDeprivationSeverity.criticalMicroSleepDanger) {
      return (
        'ALARM: Natychmiastowy zjazd na drzemkę lub biwak! Wykryto epizod mikrosnu.',
        'ALERT: Stop immediately for a nap or bivy! Micro-sleep episode detected.',
      );
    }
    if (severity == SleepDeprivationSeverity.severeHallucinationRisk) {
      return (
        'Krytyczny deficyt snu — zatrzymaj się na 90 min cykl snu lub hotel.',
        'Severe sleep debt — stop for a 90-min sleep cycle or hotel recovery.',
      );
    }
    if (circadianPhase == CircadianPhaseZone.circadianNadir && caffeineMg < 60.0) {
      return (
        'Nadir dobowy (02:00–05:30): rozważ mikrodrzemkę 20 min lub espresso.',
        'Circadian nadir (02:00–05:30): consider a 20-min power nap or caffeine.',
      );
    }
    return (
      'Czujność w normie. Kontynuuj równym tempem wytrzymałościowym.',
      'Alertness stable. Maintain steady ultra-endurance pacing.',
    );
  }

  static (String pl, String en) _buildStopVerdict({
    required UltraSleepStrategy strategy,
    required BivyShelterCondition shelter,
    required double hypothermiaRisk,
    required double netDeltaHours,
  }) {
    if (hypothermiaRisk >= 0.45) {
      return (
        'Zagrożenie hipotermią na biwaku — zalecany ciepły hotel mimo objazdu.',
        'Hypothermia risk in bivy — warm hotel strongly advised despite detour.',
      );
    }
    if (strategy == UltraSleepStrategy.hotel5Hours) {
      return (
        'Pełna regeneracja w hotelu + naładowanie elektroniki do 100%.',
        'Full hotel recovery + all race electronics recharged to 100%.',
      );
    }
    if (netDeltaHours >= 0.0) {
      return (
        'Opłacalny postój (${shelter.labelPl}): odzyskana prędkość rekompensuje czas snu.',
        'Net-positive stop (${shelter.labelEn}): recovered speed offsets stop time.',
      );
    }
    return (
      'Bezpieczna regeneracja (${shelter.labelPl}), umiarkowany koszt czasowy.',
      'Safe recovery stop (${shelter.labelEn}) with moderate time investment.',
    );
  }
}
