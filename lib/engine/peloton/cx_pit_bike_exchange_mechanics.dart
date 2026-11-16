// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/race/cyclocross_course_and_mud_model.dart';

/// Identyfikator aktualnie używanego roweru przełajowego w parze boksowej (A/B).
enum CxBikeSlot {
  bikeA('Rower A', 'Bike A'),
  bikeB('Rower B', 'Bike B');

  final String labelPl;
  final String labelEn;

  const CxBikeSlot(this.labelPl, this.labelEn);

  /// Zwraca drugi rower w parze boksowej.
  CxBikeSlot get other => this == bikeA ? bikeB : bikeA;
}

/// Aktualny status operacji wymiany roweru w boksie technicznym (Pit Lane).
enum CxPitExchangeStatus {
  /// Kolarz jedzie po trasie na aktywnym rowerze.
  onCourse('Na trasie', 'On Course'),

  /// Zaplanowano zjazd do najbliższego boksu technicznego (Pit Lane).
  pitQueued('Zjazd zaplanowany', 'Pit Queued'),

  /// Trwa 4.5-sekundowa wymiana roweru w boksie technicznym.
  inPitLane('Wymiana w boksie (4.5 s)', 'In Pit Lane (4.5 s)'),

  /// Boks jest chwilowo niedostępny (np. poza strefą Pit Lane lub drugi rower w myciu).
  unavailable('Boks niedostępny', 'Pit Unavailable');

  final String labelPl;
  final String labelEn;

  const CxPitExchangeStatus(this.labelPl, this.labelEn);
}

/// Rekomendacja taktyczna dotycząca opłacalności zjazdu do boksu na wymianę roweru.
enum CxPitRecommendation {
  /// Natychmiastowy zjazd do boksu — zysk z czystego roweru przewyższa 4.5 s postoju.
  pitNow('Zjedź do boksu teraz', 'Pit Now'),

  /// Błoto narasta — zaplanuj wymianę na kolejnym wjeździe do boksu.
  pitNextBox('Zaplanuj boks na następnej strefie', 'Pit Next Box'),

  /// Pozostań na trasie — opory błota nie uzasadniają jeszcze straty 4.5 s.
  stayOut('Jedź dalej', 'Stay Out');

  final String labelPl;
  final String labelEn;

  const CxPitRecommendation(this.labelPl, this.labelEn);
}

/// Niezmienny stan zabrudzenia roweru, oporów napędu i wymiany w boksie CX.
class CxPitBikeExchangeState {
  /// Identyfikator kolarza.
  final String riderId;

  /// Waga bazowa czystego roweru CX [kg] (np. 7.9 kg).
  final double baseBikeWeightKg;

  /// Ilość błota oblepiającego aktualny rower [kg].
  final double accumulatedMudKg;

  /// Dodatkowe opory napędu wywołane błotem [W].
  final double drivetrainDragWatts;

  /// Łączny dystans przejechany na bieżącym rowerze od ostatniej wymiany [km].
  final double distanceOnCurrentBikeKm;

  /// Łączny dystans przejechany w ciężkim błocie na bieżącym rowerze [km].
  final double heavyMudDistanceOnCurrentBikeKm;

  /// Aktualnie używany rower z pary boksowej (A lub B).
  final CxBikeSlot activeBikeSlot;

  /// Status wymiany w boksie technicznym.
  final CxPitExchangeStatus status;

  /// Pozostały czas trwania aktualnego zjazdu do boksu [s] (startuje od 4.5 s).
  final double pitRemainingSeconds;

  /// Pozostały czas mycia drugiego roweru myjką ciśnieniową w boksie [s].
  final double spareBikeWashRemainingSeconds;

  /// Całkowity czas mycia zapasowego roweru myjką ciśnieniową [s].
  final double spareBikeWashTotalSeconds;

  /// Ilość błota na zapasowym rowerze przed zakończeniem mycia [kg].
  final double spareBikeResidualMudKg;

  /// Liczba ukończonych wymian roweru w boksie technicznym.
  final int exchangeCount;

  /// Łączny czas spędzony w boksie technicznym [s].
  final double totalPitTimeSeconds;

  const CxPitBikeExchangeState({
    required this.riderId,
    this.baseBikeWeightKg = CxPitBikeExchangeMechanics.defaultBaseBikeWeightKg,
    this.accumulatedMudKg = 0.0,
    this.drivetrainDragWatts = 0.0,
    this.distanceOnCurrentBikeKm = 0.0,
    this.heavyMudDistanceOnCurrentBikeKm = 0.0,
    this.activeBikeSlot = CxBikeSlot.bikeA,
    this.status = CxPitExchangeStatus.onCourse,
    this.pitRemainingSeconds = 0.0,
    this.spareBikeWashRemainingSeconds = 0.0,
    this.spareBikeWashTotalSeconds =
        CxPitBikeExchangeMechanics.defaultPressureWashDurationSeconds,
    this.spareBikeResidualMudKg = 0.0,
    this.exchangeCount = 0,
    this.totalPitTimeSeconds = 0.0,
  });

  /// Aktualna całkowita waga roweru z błotem [kg].
  double get currentBikeWeightKg => baseBikeWeightKg + accumulatedMudKg;

  /// Czy zapasowy rower został już w pełni umyty myjką ciśnieniową.
  bool get isSpareBikeClean => spareBikeWashRemainingSeconds <= 0.0001;

  /// Postęp mycia zapasowego roweru (0.0 – 1.0, gdzie 1.0 oznacza czysty rower).
  double get spareBikeWashProgress {
    if (isSpareBikeClean || spareBikeWashTotalSeconds <= 0.0) return 1.0;
    return (1.0 - (spareBikeWashRemainingSeconds / spareBikeWashTotalSeconds))
        .clamp(0.0, 1.0);
  }

  /// Czy kolarz przebywa obecnie w boksie technicznym.
  bool get isInPitLane => status == CxPitExchangeStatus.inPitLane;

  CxPitBikeExchangeState copyWith({
    String? riderId,
    double? baseBikeWeightKg,
    double? accumulatedMudKg,
    double? drivetrainDragWatts,
    double? distanceOnCurrentBikeKm,
    double? heavyMudDistanceOnCurrentBikeKm,
    CxBikeSlot? activeBikeSlot,
    CxPitExchangeStatus? status,
    double? pitRemainingSeconds,
    double? spareBikeWashRemainingSeconds,
    double? spareBikeWashTotalSeconds,
    double? spareBikeResidualMudKg,
    int? exchangeCount,
    double? totalPitTimeSeconds,
  }) {
    return CxPitBikeExchangeState(
      riderId: riderId ?? this.riderId,
      baseBikeWeightKg: baseBikeWeightKg ?? this.baseBikeWeightKg,
      accumulatedMudKg: accumulatedMudKg ?? this.accumulatedMudKg,
      drivetrainDragWatts: drivetrainDragWatts ?? this.drivetrainDragWatts,
      distanceOnCurrentBikeKm:
          distanceOnCurrentBikeKm ?? this.distanceOnCurrentBikeKm,
      heavyMudDistanceOnCurrentBikeKm: heavyMudDistanceOnCurrentBikeKm ??
          this.heavyMudDistanceOnCurrentBikeKm,
      activeBikeSlot: activeBikeSlot ?? this.activeBikeSlot,
      status: status ?? this.status,
      pitRemainingSeconds: pitRemainingSeconds ?? this.pitRemainingSeconds,
      spareBikeWashRemainingSeconds:
          spareBikeWashRemainingSeconds ?? this.spareBikeWashRemainingSeconds,
      spareBikeWashTotalSeconds:
          spareBikeWashTotalSeconds ?? this.spareBikeWashTotalSeconds,
      spareBikeResidualMudKg:
          spareBikeResidualMudKg ?? this.spareBikeResidualMudKg,
      exchangeCount: exchangeCount ?? this.exchangeCount,
      totalPitTimeSeconds: totalPitTimeSeconds ?? this.totalPitTimeSeconds,
    );
  }
}

/// Wynik pojedynczego kroku symulacji oblepiania błotem i obsługi boksu CX.
class CxPitBikeStepResult {
  /// Zaktualizowany stan mechaniki roweru i boksu.
  final CxPitBikeExchangeState state;

  /// Przyrost masy błota w tym kroku [kg].
  final double mudAddedKg;

  /// Przyrost oporów napędu w tym kroku [W].
  final double drivetrainDragAddedWatts;

  /// Czy w tym kroku rozpoczęto zjazd do boksu technicznego.
  final bool enteredPitLane;

  /// Czy w tym kroku zakończono wymianę i wydano czysty rower o wadze bazowej.
  final bool completedBikeExchange;

  /// Prędkość efektywna w kroku [m/s] (0 przy wymianie lub podana wartość).
  final double effectiveBikeMassKg;

  /// Zwięzły komunikat zdarzenia po polsku.
  final String eventMessagePl;

  const CxPitBikeStepResult({
    required this.state,
    required this.mudAddedKg,
    required this.drivetrainDragAddedWatts,
    required this.enteredPitLane,
    required this.completedBikeExchange,
    required this.effectiveBikeMassKg,
    required this.eventMessagePl,
  });
}

/// Wynik analizy taktycznej opłacalności wymiany roweru w boksie CX.
class CxPitTacticalEvaluation {
  final CxPitRecommendation recommendation;
  final double estimatedTimeSavedSeconds;
  final double pitStopCostSeconds;
  final double mudMassKg;
  final double drivetrainDragWatts;
  final String reasonPl;

  const CxPitTacticalEvaluation({
    required this.recommendation,
    required this.estimatedTimeSavedSeconds,
    required this.pitStopCostSeconds,
    required this.mudMassKg,
    required this.drivetrainDragWatts,
    required this.reasonPl,
  });
}

/// Mechanika oblepiania roweru błotem i wymiany w boksie technicznym (`Pit Lane`)
/// dla zimowego kolarstwa przełajowego (CX):
/// - każdy kilometr w ciężkim błocie dokłada od `0.4 kg` do `1.8 kg` błota,
/// - zwiększa opory napędu o `12 W` na każdy kilometr w ciężkim błocie,
/// - zjazd do boksu technicznego (`Pit Lane`) trwa `4.5 s`,
/// - mechanicy oddają kolarzowi czysty, umyty myjką ciśnieniową drugi rower o wadze bazowej.
class CxPitBikeExchangeMechanics {
  /// Minimalny przyrost masy błota na 1 km jazdy w ciężkim błocie [kg/km].
  static const double minMudKgPerKmInHeavyMud = 0.4;

  /// Maksymalny przyrost masy błota na 1 km jazdy w ciężkim błocie [kg/km].
  static const double maxMudKgPerKmInHeavyMud = 1.8;

  /// Przyrost oporów napędu na 1 km jazdy w ciężkim błocie [W/km].
  static const double drivetrainDragWattsPerKmInHeavyMud = 12.0;

  /// Standardowy czas zjazdu i wymiany roweru w boksie technicznym (`Pit Lane`) [s].
  static const double pitLaneExchangeDurationSeconds = 4.5;

  /// Domyślna waga bazowa czystego roweru przełajowego [kg].
  static const double defaultBaseBikeWeightKg = 7.9;

  /// Domyślny czas mycia zabrudzonego roweru myjką ciśnieniową w boksie [s].
  static const double defaultPressureWashDurationSeconds = 35.0;

  /// Maksymalny fizyczny limit błota, jakie może utrzymać rama, widelec i koła [kg].
  static const double maxPhysicalMudCapKg = 6.5;

  const CxPitBikeExchangeMechanics();

  /// Tworzy początkowy stan czystego roweru na starcie wyścigu CX.
  CxPitBikeExchangeState createInitialState({
    required String riderId,
    double baseBikeWeightKg = defaultBaseBikeWeightKg,
  }) {
    final safeBaseWeight =
        baseBikeWeightKg.isFinite && baseBikeWeightKg > 0.0
            ? baseBikeWeightKg
            : defaultBaseBikeWeightKg;
    return CxPitBikeExchangeState(
      riderId: riderId,
      baseBikeWeightKg: safeBaseWeight,
    );
  }

  /// Wylicza tempo odkładania się błota [kg/km] dla zadanych warunków trasy.
  ///
  /// W ciężkim błocie (`heavyMud`) zwraca wartość z przedziału `[0.4, 1.8] kg/km`
  /// zależnie od głębokości błota (`mudDepthCm`) oraz lepkości (`mudViscosityIndex`).
  double computeMudAccumulationRateKgPerKm({
    required CyclocrossMudCondition mudCondition,
    CyclocrossTerrainType terrainType = CyclocrossTerrainType.deepMud,
    double mudDepthCm = 12.0,
    double mudViscosityIndex = 0.65,
  }) {
    if (terrainType == CyclocrossTerrainType.pavedStartFinish ||
        terrainType == CyclocrossTerrainType.doublePitLane) {
      return 0.0;
    }

    final normalizedDepth = (mudDepthCm.clamp(0.0, 25.0)) / 25.0;
    final normalizedViscosity = mudViscosityIndex.clamp(0.0, 1.0);
    final severity = (0.55 * normalizedViscosity + 0.45 * normalizedDepth)
        .clamp(0.0, 1.0);

    // Bazowy przedział dla ciężkiego błota: dokładnie 0.4 kg/km – 1.8 kg/km.
    final heavyMudRate = minMudKgPerKmInHeavyMud +
        (maxMudKgPerKmInHeavyMud - minMudKgPerKmInHeavyMud) * severity;

    switch (mudCondition) {
      case CyclocrossMudCondition.heavyMud:
        if (terrainType == CyclocrossTerrainType.deepMud ||
            terrainType == CyclocrossTerrainType.offCamberSlope) {
          return heavyMudRate.clamp(
            minMudKgPerKmInHeavyMud,
            maxMudKgPerKmInHeavyMud,
          );
        }
        if (terrainType == CyclocrossTerrainType.meadowGrass ||
            terrainType == CyclocrossTerrainType.woodlandSingletrack) {
          return (heavyMudRate * 0.55).clamp(0.2, 1.1);
        }
        return (heavyMudRate * 0.25).clamp(0.0, 0.5);
      case CyclocrossMudCondition.boggySwamp:
        if (terrainType == CyclocrossTerrainType.deepMud) {
          return maxMudKgPerKmInHeavyMud;
        }
        return (heavyMudRate * 1.15).clamp(
          minMudKgPerKmInHeavyMud,
          maxMudKgPerKmInHeavyMud,
        );
      case CyclocrossMudCondition.tackyLoam:
        return (heavyMudRate * 0.65).clamp(0.15, 1.25);
      case CyclocrossMudCondition.frozenHard:
        return (heavyMudRate * 0.12).clamp(0.0, 0.25);
    }
  }

  /// Wylicza przyrost oporów napędu [W/km] dla zadanej nawierzchni i stanu błota.
  ///
  /// W ciężkim błocie na odcinku błotnym wynosi dokładnie `12.0 W/km`.
  double computeDrivetrainDragRateWattsPerKm({
    required CyclocrossMudCondition mudCondition,
    CyclocrossTerrainType terrainType = CyclocrossTerrainType.deepMud,
  }) {
    if (terrainType == CyclocrossTerrainType.pavedStartFinish ||
        terrainType == CyclocrossTerrainType.doublePitLane) {
      return 0.0;
    }

    switch (mudCondition) {
      case CyclocrossMudCondition.heavyMud:
        if (terrainType == CyclocrossTerrainType.deepMud ||
            terrainType == CyclocrossTerrainType.offCamberSlope) {
          return drivetrainDragWattsPerKmInHeavyMud;
        }
        return drivetrainDragWattsPerKmInHeavyMud * 0.5;
      case CyclocrossMudCondition.boggySwamp:
        if (terrainType == CyclocrossTerrainType.deepMud) {
          return drivetrainDragWattsPerKmInHeavyMud * 1.2;
        }
        return drivetrainDragWattsPerKmInHeavyMud * 0.7;
      case CyclocrossMudCondition.tackyLoam:
        return drivetrainDragWattsPerKmInHeavyMud * 0.55;
      case CyclocrossMudCondition.frozenHard:
        return drivetrainDragWattsPerKmInHeavyMud * 0.1;
    }
  }

  /// Rozpoczyna zjazd kolarza do boksu technicznego (`Pit Lane`).
  ///
  /// Czas postoju i wymiany wynosi `4.5 s` (lub podaną konfigurację, domyślnie `4.5 s`).
  /// Jeśli zapasowy rower jest jeszcze myty, doliczany jest minimalny narzut oczekiwania.
  CxPitBikeExchangeState enterPitLane({
    required CxPitBikeExchangeState state,
    double pitDurationSeconds = pitLaneExchangeDurationSeconds,
  }) {
    if (state.status == CxPitExchangeStatus.inPitLane) {
      return state;
    }
    final safePitDuration = pitDurationSeconds > 0.0
        ? pitDurationSeconds
        : pitLaneExchangeDurationSeconds;
    final washWait = state.spareBikeWashRemainingSeconds > 0.0
        ? state.spareBikeWashRemainingSeconds
        : 0.0;
    return state.copyWith(
      status: CxPitExchangeStatus.inPitLane,
      pitRemainingSeconds: safePitDuration + washWait,
    );
  }

  /// Kolejkuje zjazd do boksu przy najbliższym wjeździe `DoublePitLaneConfig`.
  CxPitBikeExchangeState queuePitExchange(CxPitBikeExchangeState state) {
    if (state.status == CxPitExchangeStatus.inPitLane) {
      return state;
    }
    return state.copyWith(status: CxPitExchangeStatus.pitQueued);
  }

  /// Anuluje zaplanowany zjazd do boksu (o ile kolarz jeszcze nie wjechał do Pit Lane).
  CxPitBikeExchangeState cancelQueuedPitExchange(CxPitBikeExchangeState state) {
    if (state.status == CxPitExchangeStatus.pitQueued) {
      return state.copyWith(status: CxPitExchangeStatus.onCourse);
    }
    return state;
  }

  /// Wykonuje pojedynczy krok symulacji (`dtSeconds` oraz `distanceMeters`):
  /// - obsługuje trwającą 4.5-sekundową wymianę w `Pit Lane` i oddanie czystego roweru o wadze bazowej,
  /// - myje w tle myjką ciśnieniową poprzedni zabłocony rower,
  /// - podczas jazdy po trasie dokłada błoto (`0.4–1.8 kg/km` w ciężkim błocie) i opory napędu (`12 W/km`).
  CxPitBikeStepResult step({
    required CxPitBikeExchangeState state,
    required double dtSeconds,
    double distanceMeters = 0.0,
    CyclocrossMudCondition mudCondition = CyclocrossMudCondition.heavyMud,
    CyclocrossCourseSegment? segment,
    DoublePitLaneConfig? pitLaneConfig,
    double lapDistanceMeters = 0.0,
  }) {
    final safeDt = dtSeconds.isFinite && dtSeconds > 0.0 ? dtSeconds : 0.0;
    final safeDistanceKm =
        distanceMeters.isFinite && distanceMeters > 0.0
            ? distanceMeters / 1000.0
            : 0.0;

    // 1. Postęp mycia zapasowego roweru myjką ciśnieniową w boksie.
    final washEfficiency = pitLaneConfig?.pressureWashEfficiency ?? 0.85;
    final washRate = washEfficiency.clamp(0.4, 1.5);
    double nextWashRemaining = state.spareBikeWashRemainingSeconds;
    double nextResidualMud = state.spareBikeResidualMudKg;
    if (nextWashRemaining > 0.0 && safeDt > 0.0) {
      nextWashRemaining = math.max(0.0, nextWashRemaining - safeDt * washRate);
      if (nextWashRemaining <= 0.0001) {
        nextWashRemaining = 0.0;
        nextResidualMud = 0.0;
      } else if (state.spareBikeWashTotalSeconds > 0.0) {
        final ratio =
            (nextWashRemaining / state.spareBikeWashTotalSeconds).clamp(0.0, 1.0);
        nextResidualMud = state.spareBikeResidualMudKg * ratio;
      }
    }

    var workingState = state.copyWith(
      spareBikeWashRemainingSeconds: nextWashRemaining,
      spareBikeResidualMudKg: nextResidualMud,
    );

    // 2. Jeśli kolarz ma zakolejkowany zjazd i właśnie wjechał w strefę Pit Lane:
    bool enteredPitLane = false;
    if (workingState.status == CxPitExchangeStatus.pitQueued &&
        pitLaneConfig != null &&
        pitLaneConfig.isWithinPitZone(lapDistanceMeters)) {
      workingState = enterPitLane(state: workingState);
      enteredPitLane = true;
    }

    // 3. Obsługa trwającego postoju i wymiany roweru w boksie (4.5 s):
    if (workingState.status == CxPitExchangeStatus.inPitLane) {
      final remainingAfterStep =
          math.max(0.0, workingState.pitRemainingSeconds - safeDt);
      final elapsedInPit = math.min(workingState.pitRemainingSeconds, safeDt);

      if (remainingAfterStep <= 0.0001) {
        // Wymiana zakończona! Mechanicy oddają czysty, umyty myjką ciśnieniową
        // drugi rower o dokładnej wadze bazowej (0.0 kg błota, 0.0 W oporów).
        final dirtyMudForWash = workingState.accumulatedMudKg;
        final washTime = dirtyMudForWash > 0.0
            ? defaultPressureWashDurationSeconds
            : 0.0;
        final completedState = workingState.copyWith(
          accumulatedMudKg: 0.0,
          drivetrainDragWatts: 0.0,
          distanceOnCurrentBikeKm: 0.0,
          heavyMudDistanceOnCurrentBikeKm: 0.0,
          activeBikeSlot: workingState.activeBikeSlot.other,
          status: CxPitExchangeStatus.onCourse,
          pitRemainingSeconds: 0.0,
          spareBikeWashRemainingSeconds: washTime,
          spareBikeWashTotalSeconds:
              washTime > 0.0 ? washTime : defaultPressureWashDurationSeconds,
          spareBikeResidualMudKg: dirtyMudForWash,
          exchangeCount: workingState.exchangeCount + 1,
          totalPitTimeSeconds: workingState.totalPitTimeSeconds + elapsedInPit,
        );

        return CxPitBikeStepResult(
          state: completedState,
          mudAddedKg: 0.0,
          drivetrainDragAddedWatts: 0.0,
          enteredPitLane: enteredPitLane,
          completedBikeExchange: true,
          effectiveBikeMassKg: completedState.currentBikeWeightKg,
          eventMessagePl:
              'Wymiana zakończona! Wydano czysty ${completedState.activeBikeSlot.labelPl} (${completedState.baseBikeWeightKg.toStringAsFixed(1)} kg).',
        );
      }

      final waitingState = workingState.copyWith(
        pitRemainingSeconds: remainingAfterStep,
        totalPitTimeSeconds: workingState.totalPitTimeSeconds + elapsedInPit,
      );

      return CxPitBikeStepResult(
        state: waitingState,
        mudAddedKg: 0.0,
        drivetrainDragAddedWatts: 0.0,
        enteredPitLane: enteredPitLane,
        completedBikeExchange: false,
        effectiveBikeMassKg: waitingState.currentBikeWeightKg,
        eventMessagePl:
            'W boksie technicznym: wymiana za ${remainingAfterStep.toStringAsFixed(1)} s.',
      );
    }

    // 4. Jazda po trasie — oblepianie roweru błotem i wzrost oporów napędu.
    final terrain = segment?.terrainType ?? CyclocrossTerrainType.deepMud;
    final mudDepthCm = segment?.mudDepthCm ?? 12.0;
    final mudViscosity = segment?.mudViscosityIndex ?? 0.65;

    final mudRateKgPerKm = computeMudAccumulationRateKgPerKm(
      mudCondition: mudCondition,
      terrainType: terrain,
      mudDepthCm: mudDepthCm,
      mudViscosityIndex: mudViscosity,
    );
    final dragRateWattsPerKm = computeDrivetrainDragRateWattsPerKm(
      mudCondition: mudCondition,
      terrainType: terrain,
    );

    final rawMudAdded = mudRateKgPerKm * safeDistanceKm;
    final clampedMudTotal = (workingState.accumulatedMudKg + rawMudAdded)
        .clamp(0.0, maxPhysicalMudCapKg);
    final actualMudAdded =
        math.max(0.0, clampedMudTotal - workingState.accumulatedMudKg);

    final dragAdded = dragRateWattsPerKm * safeDistanceKm;
    final nextDragWatts = workingState.drivetrainDragWatts + dragAdded;

    final isHeavyMudSegment =
        (mudCondition == CyclocrossMudCondition.heavyMud ||
                mudCondition == CyclocrossMudCondition.boggySwamp) &&
            (terrain == CyclocrossTerrainType.deepMud ||
                terrain == CyclocrossTerrainType.offCamberSlope);

    final nextState = workingState.copyWith(
      accumulatedMudKg: clampedMudTotal,
      drivetrainDragWatts: nextDragWatts,
      distanceOnCurrentBikeKm:
          workingState.distanceOnCurrentBikeKm + safeDistanceKm,
      heavyMudDistanceOnCurrentBikeKm:
          workingState.heavyMudDistanceOnCurrentBikeKm +
              (isHeavyMudSegment ? safeDistanceKm : 0.0),
    );

    return CxPitBikeStepResult(
      state: nextState,
      mudAddedKg: actualMudAdded,
      drivetrainDragAddedWatts: dragAdded,
      enteredPitLane: enteredPitLane,
      completedBikeExchange: false,
      effectiveBikeMassKg: nextState.currentBikeWeightKg,
      eventMessagePl: actualMudAdded > 0.0
          ? 'Błoto na rowerze: ${nextState.accumulatedMudKg.toStringAsFixed(2)} kg (+${nextState.drivetrainDragWatts.toStringAsFixed(1)} W oporu napędu).'
          : 'Przejazd na czysto — waga roweru ${nextState.currentBikeWeightKg.toStringAsFixed(2)} kg.',
    );
  }

  /// Ocenia opłacalność taktyczną zjazdu do boksu na podstawie pozostałego dystansu,
  /// masy błota na rowerze oraz straty mocy w napędzie względem kosztu 4.5 s.
  CxPitTacticalEvaluation evaluatePitExchangeRecommendation({
    required CxPitBikeExchangeState state,
    required double remainingRaceDistanceKm,
    double riderPowerWatts = 350.0,
  }) {
    final safeRemainingKm =
        remainingRaceDistanceKm > 0.0 ? remainingRaceDistanceKm : 0.0;
    final safePower = riderPowerWatts > 80.0 ? riderPowerWatts : 350.0;

    // Przybliżona prędkość CX ~20 km/h => ~180 s/km.
    // Koszt czasowy oporów napędu + dodatkowej masy błota na pozostałym dystansie:
    final powerLossRatio =
        (state.drivetrainDragWatts / safePower).clamp(0.0, 0.45);
    final weightPenaltyRatio = (state.accumulatedMudKg * 0.008).clamp(0.0, 0.08);
    final timePenaltyPerKmSeconds =
        180.0 * (powerLossRatio * 0.65 + weightPenaltyRatio);
    final projectedMudCostSeconds = timePenaltyPerKmSeconds * safeRemainingKm;

    final netTimeSaved = projectedMudCostSeconds - pitLaneExchangeDurationSeconds;

    if (!state.isSpareBikeClean && state.spareBikeWashRemainingSeconds > 2.0) {
      return CxPitTacticalEvaluation(
        recommendation: CxPitRecommendation.stayOut,
        estimatedTimeSavedSeconds: netTimeSaved,
        pitStopCostSeconds:
            pitLaneExchangeDurationSeconds + state.spareBikeWashRemainingSeconds,
        mudMassKg: state.accumulatedMudKg,
        drivetrainDragWatts: state.drivetrainDragWatts,
        reasonPl:
            'Zapasowy rower jest w trakcie mycia myjką ciśnieniową (${state.spareBikeWashRemainingSeconds.toStringAsFixed(0)} s).',
      );
    }

    if (netTimeSaved >= 2.5 &&
        (state.accumulatedMudKg >= 0.8 || state.drivetrainDragWatts >= 12.0)) {
      return CxPitTacticalEvaluation(
        recommendation: CxPitRecommendation.pitNow,
        estimatedTimeSavedSeconds: netTimeSaved,
        pitStopCostSeconds: pitLaneExchangeDurationSeconds,
        mudMassKg: state.accumulatedMudKg,
        drivetrainDragWatts: state.drivetrainDragWatts,
        reasonPl:
            'Zjazd 4.5 s zwróci się z nawiązką (+${netTimeSaved.toStringAsFixed(1)} s zysku na pozostałych ${safeRemainingKm.toStringAsFixed(1)} km).',
      );
    }

    if (state.accumulatedMudKg >= 0.4 && netTimeSaved > -1.5) {
      return CxPitTacticalEvaluation(
        recommendation: CxPitRecommendation.pitNextBox,
        estimatedTimeSavedSeconds: netTimeSaved,
        pitStopCostSeconds: pitLaneExchangeDurationSeconds,
        mudMassKg: state.accumulatedMudKg,
        drivetrainDragWatts: state.drivetrainDragWatts,
        reasonPl:
            'Błoto rośnie (${state.accumulatedMudKg.toStringAsFixed(2)} kg, +${state.drivetrainDragWatts.toStringAsFixed(0)} W) — przygotuj mechaników w boksie.',
      );
    }

    return CxPitTacticalEvaluation(
      recommendation: CxPitRecommendation.stayOut,
      estimatedTimeSavedSeconds: netTimeSaved,
      pitStopCostSeconds: pitLaneExchangeDurationSeconds,
      mudMassKg: state.accumulatedMudKg,
      drivetrainDragWatts: state.drivetrainDragWatts,
      reasonPl:
          'Rower wystarczająco lekki (${state.currentBikeWeightKg.toStringAsFixed(2)} kg) — postój 4.5 s jeszcze nieopłacalny.',
    );
  }
}

/// Responsywny panel HUD / Boxu Technicznego CX prezentujący stan zabłocenia roweru,
/// opory napędu w watach, postęp myjki ciśnieniowej oraz przycisk zjazdu do `Pit Lane` (4.5 s).
class CxPitBikeExchangePanel extends StatefulWidget {
  final CxPitBikeExchangeState state;
  final CxPitTacticalEvaluation? evaluation;
  final VoidCallback? onPitExchangePressed;
  final VoidCallback? onCancelPitQueuePressed;

  const CxPitBikeExchangePanel({
    super.key,
    required this.state,
    this.evaluation,
    this.onPitExchangePressed,
    this.onCancelPitQueuePressed,
  });

  @override
  State<CxPitBikeExchangePanel> createState() => _CxPitBikeExchangePanelState();
}

class _CxPitBikeExchangePanelState extends State<CxPitBikeExchangePanel> {
  bool _isPitButtonHovered = false;
  bool _isPitButtonPressed = false;
  bool _isPitButtonFocused = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 460;
        final state = widget.state;
        final mudRatio = (state.accumulatedMudKg /
                CxPitBikeExchangeMechanics.maxPhysicalMudCapKg)
            .clamp(0.0, 1.0);

        final mudColor = mudRatio >= 0.45
            ? AppColors.crimsonAlert
            : mudRatio >= 0.2
                ? AppColors.amberWarning
                : AppColors.statusSuccess;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: state.isInPitLane
                  ? AppColors.goldAccent
                  : AppColors.cardBorder,
              width: 1.0,
            ),
          ),
          padding: EdgeInsets.all(isCompact ? 14 : 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(state, isCompact),
              const SizedBox(height: 14),
              if (isCompact) ...[
                _buildMetricTile(
                  label: 'Waga roweru',
                  value: '${state.currentBikeWeightKg.toStringAsFixed(2)} kg',
                  subtitle:
                      'Baza ${state.baseBikeWeightKg.toStringAsFixed(1)} kg + ${state.accumulatedMudKg.toStringAsFixed(2)} kg błota',
                  accentColor: mudColor,
                ),
                const SizedBox(height: 10),
                _buildMetricTile(
                  label: 'Opory napędu',
                  value: '+${state.drivetrainDragWatts.toStringAsFixed(1)} W',
                  subtitle:
                      '${state.heavyMudDistanceOnCurrentBikeKm.toStringAsFixed(2)} km w ciężkim błocie',
                  accentColor: state.drivetrainDragWatts >= 12.0
                      ? AppColors.amberWarning
                      : AppColors.accentBlue,
                ),
              ] else
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        label: 'Waga roweru',
                        value:
                            '${state.currentBikeWeightKg.toStringAsFixed(2)} kg',
                        subtitle:
                            'Baza ${state.baseBikeWeightKg.toStringAsFixed(1)} kg + ${state.accumulatedMudKg.toStringAsFixed(2)} kg błota',
                        accentColor: mudColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricTile(
                        label: 'Opory napędu',
                        value:
                            '+${state.drivetrainDragWatts.toStringAsFixed(1)} W',
                        subtitle:
                            '${state.heavyMudDistanceOnCurrentBikeKm.toStringAsFixed(2)} km w ciężkim błocie',
                        accentColor: state.drivetrainDragWatts >= 12.0
                            ? AppColors.amberWarning
                            : AppColors.accentBlue,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              _buildSpareBikeWashStatus(state),
              if (widget.evaluation != null) ...[
                const SizedBox(height: 12),
                _buildTacticalBanner(widget.evaluation!),
              ],
              const SizedBox(height: 14),
              _buildPitActionButton(state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(CxPitBikeExchangeState state, bool isCompact) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.cardBorder, width: 1.0),
          ),
          child: const Icon(
            Icons.build_circle_outlined,
            color: AppColors.goldAccent,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BOKS TECHNICZNY CX • ${state.activeBikeSlot.labelPl.toUpperCase()}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isCompact ? 12 : 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Wymiany: ${state.exchangeCount} • Postój w boksie: ${state.totalPitTimeSeconds.toStringAsFixed(1)} s',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required String subtitle,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: accentColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpareBikeWashStatus(CxPitBikeExchangeState state) {
    final progress = state.spareBikeWashProgress;
    final clean = state.isSpareBikeClean;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                clean ? Icons.verified_outlined : Icons.water_drop_outlined,
                size: 15,
                color: clean ? AppColors.statusSuccess : AppColors.accentBlue,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  clean
                      ? 'Drugi rower (${state.activeBikeSlot.other.labelPl}): Czysty (${state.baseBikeWeightKg.toStringAsFixed(1)} kg)'
                      : 'Myjka ciśnieniowa (${state.activeBikeSlot.other.labelPl}): ${(progress * 100).toStringAsFixed(0)}%',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                clean ? AppColors.statusSuccess : AppColors.accentBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTacticalBanner(CxPitTacticalEvaluation evaluation) {
    final color = switch (evaluation.recommendation) {
      CxPitRecommendation.pitNow => AppColors.goldAccent,
      CxPitRecommendation.pitNextBox => AppColors.amberWarning,
      CxPitRecommendation.stayOut => AppColors.textSecondary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1.0),
      ),
      child: Text(
        '${evaluation.recommendation.labelPl}: ${evaluation.reasonPl}',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color == AppColors.textSecondary
              ? AppColors.textPrimary
              : color,
        ),
      ),
    );
  }

  Widget _buildPitActionButton(CxPitBikeExchangeState state) {
    final isQueued = state.status == CxPitExchangeStatus.pitQueued;
    final isInPit = state.isInPitLane;
    final callback = isQueued
        ? widget.onCancelPitQueuePressed
        : (isInPit ? null : widget.onPitExchangePressed);
    final isEnabled = callback != null;

    final Color bgColor;
    if (!isEnabled) {
      bgColor = AppColors.surfaceLight.withValues(alpha: 0.55);
    } else if (_isPitButtonPressed) {
      bgColor = AppColors.primaryAccent.withValues(alpha: 0.78);
    } else if (_isPitButtonHovered) {
      bgColor = isQueued ? AppColors.amberWarning : AppColors.goldAccent;
    } else {
      bgColor = isQueued ? AppColors.amberWarning : AppColors.primaryAccent;
    }

    final label = isInPit
        ? 'Wymiana w Pit Lane (${state.pitRemainingSeconds.toStringAsFixed(1)} s)...'
        : isQueued
            ? 'Anuluj zjazd do Pit Lane'
            : 'Zjazd do boksu — wymiana roweru (4.5 s)';

    return FocusableActionDetector(
      enabled: isEnabled,
      onShowHoverHighlight: (hovered) {
        if (mounted) setState(() => _isPitButtonHovered = hovered);
      },
      onShowFocusHighlight: (focused) {
        if (mounted) setState(() => _isPitButtonFocused = focused);
      },
      child: GestureDetector(
        onTapDown: isEnabled
            ? (_) => setState(() => _isPitButtonPressed = true)
            : null,
        onTapUp: isEnabled
            ? (_) => setState(() => _isPitButtonPressed = false)
            : null,
        onTapCancel: isEnabled
            ? () => setState(() => _isPitButtonPressed = false)
            : null,
        onTap: callback,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isPitButtonFocused
                  ? AppColors.cyanAccent
                  : AppColors.cardBorder,
              width: _isPitButtonFocused ? 1.5 : 1.0,
            ),
          ),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: isEnabled
                    ? (_isPitButtonHovered && !isQueued
                        ? AppColors.background
                        : AppColors.textPrimary)
                    : AppColors.textSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
