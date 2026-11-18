// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import '../../core/constants/physics_constants.dart';
import '../../models/esports/uci_cycling_esports_world_model.dart';

/// Tryb pracy trenażera interaktywnego Smart w wyścigu lub teście e-Sports.
enum EsportsTrainerControlMode {
  /// Tryb symulacji trasy (SIM): opór rośnie i maleje wraz z profilem wirtualnym.
  simMode('SIM Mode', 'Tryb Symulacji Trasy'),

  /// Tryb ERG: trenażer wymusza stałą moc zadaną niezależnie od kadencji i nachylenia.
  ergMode('ERG Mode', 'Tryb Stałej Mocy (ERG)'),

  /// Tryb wirtualnej zmiany przełożeń (Virtual Shifting 24-speed).
  virtualShifting('Virtual Shifting', 'Wirtualne Przełożenia');

  final String labelEn;
  final String labelPl;

  const EsportsTrainerControlMode(this.labelEn, this.labelPl);
}

/// Zalecana akcja taktyczna dla posiadanego Power-Upa w wyścigu e-Sports.
enum EsportsPowerUpAction {
  /// Brak gotowego Power-Upa w slocie.
  none('None', 'Brak Power-Upa'),

  /// Natychmiastowa aktywacja w optymalnym oknie.
  activateNow('Activate Now', 'Aktywuj Teraz'),

  /// Przetrzymanie (np. Featherweight) na nadchodzący podjazd.
  holdForClimb('Hold for Climb', 'Zachowaj na Podjazd'),

  /// Przetrzymanie (np. Aero Helmet / Burrito) na finisz lub premię.
  holdForSprint('Hold for Sprint', 'Zachowaj na Finisz'),

  /// Zachowanie Power-Upa na strefę zagrożenia eliminacją co 60 s.
  saveForElimination('Save for Elimination', 'Zachowaj na Eliminację');

  final String labelEn;
  final String labelPl;

  const EsportsPowerUpAction(this.labelEn, this.labelPl);
}

/// Status weryfikacji Dual-Recording (podwójny pomiar mocy w UCI Esports).
enum DualRecordingComplianceStatus {
  verified('Verified', 'Zweryfikowany'),
  warningDrift('Drift Warning', 'Ostrzeżenie Dryftu'),
  disqualified('DSQ Mismatch', 'Dyskwalifikacja (Rozbieżność)');

  final String labelEn;
  final String labelPl;

  const DualRecordingComplianceStatus(this.labelEn, this.labelPl);
}

/// Dane wejściowe pojedynczego kroku fizyki kolarza e-Sports.
class EsportsRiderPhysicsInput {
  final EsportsRiderLiveState rider;
  final EsportsVirtualWorldSpec world;
  final double targetPowerWatts;
  final EsportsTrainerControlMode controlMode;
  final double deltaTimeSeconds;

  /// Czy przed kolarzem w odległości < 10 m jedzie rywal dający cień aero.
  final bool hasDraftTargetAhead;

  /// Siła cienia aerodynamicznego przed aktywacją Power-Upów (0.0 = brak, 1.0 = pełny peleton).
  final double baseDraftShelterIntensity;

  /// Czy rywal w promieniu 10 m przed kolarzem ma aktywny Power-Up Burrito.
  final bool rivalAheadHasActiveBurrito;

  /// Bazowy współczynnik CdA awatara przed modyfikatorami Power-Upów [m^2].
  final double baseAvatarCda;

  /// Masa wirtualnego roweru [kg].
  final double bikeWeightKg;

  /// Aktualny stan harmonogramu eliminacji (opcjonalny, do logiki taktycznej).
  final Elimination60sScheduleState? eliminationSchedule;

  const EsportsRiderPhysicsInput({
    required this.rider,
    required this.world,
    required this.targetPowerWatts,
    this.controlMode = EsportsTrainerControlMode.simMode,
    this.deltaTimeSeconds = 1.0,
    this.hasDraftTargetAhead = true,
    this.baseDraftShelterIntensity = 0.55,
    this.rivalAheadHasActiveBurrito = false,
    this.baseAvatarCda = PhysicsConstants.cdaDrops,
    this.bikeWeightKg = 6.8,
    this.eliminationSchedule,
  });
}

/// Wynik obliczeń pojedynczego kroku fizyki trenażera Smart, prędkości i W'.
class EsportsRiderPhysicsResult {
  final EsportsRiderLiveState updatedRider;
  final EsportsVirtualCourseSegment currentSegment;
  final double effectivePowerWatts;
  final double ergTargetPowerWatts;
  final double simulatedTrainerGradientPercent;
  final double effectiveCda;
  final double effectiveMassKg;
  final double effectiveCrr;
  final double effectiveDraftFactor;
  final bool isDraftBlockedByBurrito;
  final double speedMs;
  final double speedKmh;
  final double powerSavingsFromPowerUpWatts;
  final double aeroDragWatts;
  final double rollingResistanceWatts;
  final double gravityWatts;
  final DualRecordingComplianceStatus dualRecordingStatus;
  final bool crossedBannerGate;

  const EsportsRiderPhysicsResult({
    required this.updatedRider,
    required this.currentSegment,
    required this.effectivePowerWatts,
    required this.ergTargetPowerWatts,
    required this.simulatedTrainerGradientPercent,
    required this.effectiveCda,
    required this.effectiveMassKg,
    required this.effectiveCrr,
    required this.effectiveDraftFactor,
    required this.isDraftBlockedByBurrito,
    required this.speedMs,
    required this.speedKmh,
    required this.powerSavingsFromPowerUpWatts,
    required this.aeroDragWatts,
    required this.rollingResistanceWatts,
    required this.gravityWatts,
    required this.dualRecordingStatus,
    required this.crossedBannerGate,
  });
}

/// Ocena strategiczna momentu aktywacji Power-Upa w wyścigu e-Sports.
class EsportsPowerUpStrategyDecision {
  final EsportsPowerUpType? powerUpType;
  final EsportsPowerUpAction recommendedAction;
  final bool shouldActivateNow;
  final double urgencyScore;
  final double estimatedPowerSavingsWatts;
  final double estimatedTimeGainSeconds;
  final String reasonPl;

  const EsportsPowerUpStrategyDecision({
    required this.powerUpType,
    required this.recommendedAction,
    required this.shouldActivateNow,
    required this.urgencyScore,
    required this.estimatedPowerSavingsWatts,
    required this.estimatedTimeGainSeconds,
    required this.reasonPl,
  });
}

/// Wynik rozwiązania rundy eliminacyjnej co 60 sekund.
class EsportsEliminationStepResult {
  final Elimination60sScheduleState updatedSchedule;
  final List<EsportsRiderLiveState> updatedRiders;
  final EliminationRoundRecord? eliminationRecord;
  final bool eliminationTriggered;

  const EsportsEliminationStepResult({
    required this.updatedSchedule,
    required this.updatedRiders,
    this.eliminationRecord,
    required this.eliminationTriggered,
  });
}

/// Solver fizyki wyścigów UCI Cycling Esports, trenażerów Smart/ERG oraz strategii Power-Upów.
class EsportsSmartTrainerErgAndPowerupsSolver {
  static const double _virtualDrivetrainEfficiency = 0.98;
  static const double _maxDraftReductionFraction = 0.36;
  static const double _dualRecordingWarningThresholdPercent = 1.5;
  static const double _dualRecordingDsqThresholdPercent = 2.5;
  static const double _minSpeedMs = 1.5;
  static const double _maxSpeedMs = 30.5; // ~110 km/h na stromym zjeździe

  const EsportsSmartTrainerErgAndPowerupsSolver();

  /// Rozwiązuje pojedynczy krok fizyki kolarza e-Sports (ERG/SIM, opory, Power-Upy, W', dystans).
  EsportsRiderPhysicsResult solveRiderPhysicsStep(
    EsportsRiderPhysicsInput input,
  ) {
    final dt = math.max(0.05, input.deltaTimeSeconds);
    final rider = input.rider;

    if (!rider.isActiveInRace) {
      final segment = input.world.segmentAtDistance(rider.distanceMeters);
      return EsportsRiderPhysicsResult(
        updatedRider: rider,
        currentSegment: segment,
        effectivePowerWatts: 0.0,
        ergTargetPowerWatts: 0.0,
        simulatedTrainerGradientPercent: 0.0,
        effectiveCda: input.baseAvatarCda,
        effectiveMassKg: rider.weightKg + input.bikeWeightKg,
        effectiveCrr: segment.surfaceCrr,
        effectiveDraftFactor: 1.0,
        isDraftBlockedByBurrito: false,
        speedMs: 0.0,
        speedKmh: 0.0,
        powerSavingsFromPowerUpWatts: 0.0,
        aeroDragWatts: 0.0,
        rollingResistanceWatts: 0.0,
        gravityWatts: 0.0,
        dualRecordingStatus: _evaluateDualRecordingStatus(rider),
        crossedBannerGate: false,
      );
    }

    final segment = input.world.segmentAtDistance(rider.distanceMeters);
    final dualStatus = _evaluateDualRecordingStatus(rider);

    // Weryfikacja dyskwalifikacji za rozbieżność Dual-Recording na MŚ UCI.
    if (dualStatus == DualRecordingComplianceStatus.disqualified &&
        !rider.trainerSpec.isUciCompliant) {
      final dsqRider = rider.copyWith(
        currentPowerWatts: 0.0,
        speedKmh: 0.0,
        verdict: EsportsAvatarVerdict.disqualifiedDualRecording,
      );
      return EsportsRiderPhysicsResult(
        updatedRider: dsqRider,
        currentSegment: segment,
        effectivePowerWatts: 0.0,
        ergTargetPowerWatts: 0.0,
        simulatedTrainerGradientPercent: 0.0,
        effectiveCda: input.baseAvatarCda,
        effectiveMassKg: rider.weightKg + input.bikeWeightKg,
        effectiveCrr: segment.surfaceCrr,
        effectiveDraftFactor: 1.0,
        isDraftBlockedByBurrito: false,
        speedMs: 0.0,
        speedKmh: 0.0,
        powerSavingsFromPowerUpWatts: 0.0,
        aeroDragWatts: 0.0,
        rollingResistanceWatts: 0.0,
        gravityWatts: 0.0,
        dualRecordingStatus: dualStatus,
        crossedBannerGate: false,
      );
    }

    // 1. Przetworzenie trenażera Smart (ERG vs SIM + dryft kalibracyjny).
    final ergTarget = _resolveErgOrSimPower(
      requestedWatts: input.targetPowerWatts,
      currentWatts: rider.currentPowerWatts,
      trainer: rider.trainerSpec,
      controlMode: input.controlMode,
      dt: dt,
    );
    final effectivePowerWatts =
        (ergTarget + rider.trainerSpec.calibrationDriftWatts).clamp(
          0.0,
          rider.trainerSpec.maxPowerWatts.toDouble(),
        );

    final simulatedTrainerGradient = input.controlMode ==
            EsportsTrainerControlMode.ergMode
        ? 0.0
        : rider.trainerSpec.clampSimulatedGradient(segment.gradientPercent);

    // 2. Modyfikatory aktywnego Power-Upa oraz ewentualne blokowanie draftu przez Burrito rywala.
    final activeType = rider.activePowerUpType;
    final activeSpec =
        activeType != null ? EsportsPowerUpSpec.forType(activeType) : null;

    final effectiveCda =
        input.baseAvatarCda * (activeSpec?.cdaMultiplier ?? 1.0);
    final effectiveMassKg =
        (rider.weightKg * (activeSpec?.massMultiplier ?? 1.0)) +
        input.bikeWeightKg;
    final effectiveCrr =
        segment.surfaceCrr * (activeSpec?.crrMultiplier ?? 1.0);

    final isDraftBlockedByBurrito =
        input.rivalAheadHasActiveBurrito && segment.draftingEnabled;
    final effectiveDraftFactor = _computeEffectiveDraftFactor(
      segment: segment,
      hasDraftTargetAhead: input.hasDraftTargetAhead,
      baseDraftShelterIntensity: input.baseDraftShelterIntensity,
      isDraftBlockedByBurrito: isDraftBlockedByBurrito,
      powerUpDraftMultiplier: activeSpec?.draftMultiplier ?? 1.0,
    );

    // 3. Rozwiązanie równania bilansu mocy dla prędkości w świecie wirtualnym.
    final wheelPowerWatts = effectivePowerWatts * _virtualDrivetrainEfficiency;
    final targetSpeedMs = _solveSteadyStateSpeedMs(
      wheelPowerWatts: wheelPowerWatts,
      totalMassKg: effectiveMassKg,
      gradientPercent: segment.gradientPercent,
      crr: effectiveCrr,
      cda: effectiveCda,
      draftFactor: effectiveDraftFactor,
      airDensity: input.world.airDensityKgM3,
    );

    // Bezwładność koła zamachowego trenażera i masy wirtualnej łagodzi skoki prędkości.
    final currentSpeedMs = math.max(_minSpeedMs, rider.speedKmh / 3.6);
    final inertiaTau = _computeInertiaTimeConstantSeconds(
      flywheelInertiaKg: rider.trainerSpec.flywheelInertiaKg,
      totalMassKg: effectiveMassKg,
    );
    final alpha = 1.0 - math.exp(-dt / inertiaTau);
    final nextSpeedMs = (currentSpeedMs + (targetSpeedMs - currentSpeedMs) * alpha)
        .clamp(_minSpeedMs, _maxSpeedMs);
    final nextSpeedKmh = nextSpeedMs * 3.6;

    // 4. Rozkład oporów przy bieżącej prędkości oraz zysk z aktywnego Power-Upa.
    final breakdown = _computeResistancePowerBreakdown(
      speedMs: nextSpeedMs,
      totalMassKg: effectiveMassKg,
      gradientPercent: segment.gradientPercent,
      crr: effectiveCrr,
      cda: effectiveCda,
      draftFactor: effectiveDraftFactor,
      airDensity: input.world.airDensityKgM3,
    );

    final baselinePowerSavings = activeSpec == null
        ? 0.0
        : _estimatePowerSavingsWatts(
            speedMs: nextSpeedMs,
            riderWeightKg: rider.weightKg,
            bikeWeightKg: input.bikeWeightKg,
            segment: segment,
            baseCda: input.baseAvatarCda,
            baseDraftFactor: _computeEffectiveDraftFactor(
              segment: segment,
              hasDraftTargetAhead: input.hasDraftTargetAhead,
              baseDraftShelterIntensity: input.baseDraftShelterIntensity,
              isDraftBlockedByBurrito: isDraftBlockedByBurrito,
              powerUpDraftMultiplier: 1.0,
            ),
            airDensity: input.world.airDensityKgM3,
            activeSpec: activeSpec,
          );

    // 5. Aktualizacja baterii beztlenowej W' (model Skiby).
    final nextWPrime = _updateWPrimeBalance(
      currentWPrimeJoules: rider.wPrimeRemainingJoules,
      maxWPrimeJoules: rider.wPrimeMaxJoules,
      ftpWatts: rider.ftpWatts,
      powerWatts: effectivePowerWatts,
      dtSeconds: dt,
    );

    // 6. Aktualizacja dystansu, okrążenia i sprawdzenie bramy Power-Up Banner.
    final previousDistance = rider.distanceMeters;
    final nextDistance = previousDistance + nextSpeedMs * dt;
    final safeLapLength = math.max(1.0, input.world.lapLengthMeters);
    final nextLap = (nextDistance / safeLapLength).floor() + 1;

    final nextSegment = input.world.segmentAtDistance(nextDistance);
    final crossedBannerGate =
        nextSegment.index != segment.index && nextSegment.isPowerUpBannerGate;

    // 7. Tyknięcie timera Power-Upa oraz ewentualne przyznanie nowego po przejeździe pod bramką.
    var nextSlot = rider.powerUpSlot.tick(dt);
    if (crossedBannerGate && nextSlot.state == EsportsPowerUpSlotState.empty) {
      final grantedType = _rollPowerUpForSegment(
        nextSegment: nextSegment,
        riderIndexSeed: rider.riderId.hashCode ^ nextLap,
      );
      nextSlot = nextSlot.copyWith(
        powerUp: grantedType,
        state: EsportsPowerUpSlotState.ready,
        remainingActiveSeconds: 0.0,
        cooldownSeconds: 0.0,
      );
    }

    // 8. Aktualizacja kadencji (zależna od trybu ERG lub nachylenia).
    final nextCadenceRpm = _estimateCadenceRpm(
      controlMode: input.controlMode,
      gradientPercent: segment.gradientPercent,
      speedKmh: nextSpeedKmh,
      powerWatts: effectivePowerWatts,
      ftpWatts: rider.ftpWatts,
    );

    final updatedRider = rider.copyWith(
      currentPowerWatts: effectivePowerWatts,
      cadenceRpm: nextCadenceRpm,
      speedKmh: nextSpeedKmh,
      distanceMeters: nextDistance,
      lap: nextLap,
      wPrimeRemainingJoules: nextWPrime,
      powerUpSlot: nextSlot,
    );

    return EsportsRiderPhysicsResult(
      updatedRider: updatedRider,
      currentSegment: nextSegment,
      effectivePowerWatts: effectivePowerWatts,
      ergTargetPowerWatts: ergTarget,
      simulatedTrainerGradientPercent: simulatedTrainerGradient,
      effectiveCda: effectiveCda,
      effectiveMassKg: effectiveMassKg,
      effectiveCrr: effectiveCrr,
      effectiveDraftFactor: effectiveDraftFactor,
      isDraftBlockedByBurrito: isDraftBlockedByBurrito,
      speedMs: nextSpeedMs,
      speedKmh: nextSpeedKmh,
      powerSavingsFromPowerUpWatts: baselinePowerSavings,
      aeroDragWatts: breakdown.aeroWatts,
      rollingResistanceWatts: breakdown.rollingWatts,
      gravityWatts: breakdown.gravityWatts,
      dualRecordingStatus: dualStatus,
      crossedBannerGate: crossedBannerGate,
    );
  }

  /// Ocenia optymalny moment użycia Power-Upa dla danego kolarza i odcinka trasy.
  EsportsPowerUpStrategyDecision evaluatePowerUpStrategy({
    required EsportsRiderLiveState rider,
    required EsportsVirtualWorldSpec world,
    Elimination60sScheduleState? eliminationSchedule,
    bool rivalsDraftingBehind = false,
    int activeRidersCount = 20,
    double baseAvatarCda = PhysicsConstants.cdaDrops,
  }) {
    final slot = rider.powerUpSlot;
    if (slot.powerUp == null || slot.state != EsportsPowerUpSlotState.ready) {
      return const EsportsPowerUpStrategyDecision(
        powerUpType: null,
        recommendedAction: EsportsPowerUpAction.none,
        shouldActivateNow: false,
        urgencyScore: 0.0,
        estimatedPowerSavingsWatts: 0.0,
        estimatedTimeGainSeconds: 0.0,
        reasonPl: 'Brak gotowego Power-Upa w slocie.',
      );
    }

    final type = slot.powerUp!;
    final spec = EsportsPowerUpSpec.forType(type);
    final currentSeg = world.segmentAtDistance(rider.distanceMeters);
    final lookaheadDist = rider.distanceMeters + 250.0;
    final nextSeg = world.segmentAtDistance(lookaheadDist);
    final remainingRaceDist =
        math.max(0.0, world.totalRaceDistanceMeters - rider.distanceMeters);

    final isInEliminationDanger = eliminationSchedule != null &&
        eliminationSchedule.isInFinalTenSecondsWarning &&
        rider.rank >= math.max(1, activeRidersCount - 3);

    final speedMs = math.max(5.0, rider.speedKmh / 3.6);
    final estimatedSavings = _estimatePowerSavingsWatts(
      speedMs: speedMs,
      riderWeightKg: rider.weightKg,
      bikeWeightKg: 6.8,
      segment: currentSeg,
      baseCda: baseAvatarCda,
      baseDraftFactor: 0.78,
      airDensity: world.airDensityKgM3,
      activeSpec: spec,
    );
    final estimatedTimeGain =
        (estimatedSavings / math.max(180.0, rider.ftpWatts)) *
        spec.durationSeconds *
        0.55;

    // 1. Alarm eliminacyjny (ostatnie 10 s rundy 60-sekundowej dla zagrożonych).
    if (isInEliminationDanger) {
      return EsportsPowerUpStrategyDecision(
        powerUpType: type,
        recommendedAction: EsportsPowerUpAction.activateNow,
        shouldActivateNow: true,
        urgencyScore: 0.96,
        estimatedPowerSavingsWatts: estimatedSavings,
        estimatedTimeGainSeconds: estimatedTimeGain,
        reasonPl:
            'Alarm eliminacji (<10 s): natychmiast odpal ${spec.displayName}, aby uniknąć odpadnięcia!',
      );
    }

    // 2. Finisz wyścigu (< 500 m do mety) lub premia sprinterska/górska.
    if (remainingRaceDist <= 500.0) {
      return EsportsPowerUpStrategyDecision(
        powerUpType: type,
        recommendedAction: EsportsPowerUpAction.activateNow,
        shouldActivateNow: true,
        urgencyScore: 0.95,
        estimatedPowerSavingsWatts: estimatedSavings,
        estimatedTimeGainSeconds: estimatedTimeGain,
        reasonPl:
            'Ostatnie 500 m wyścigu — pełna aktywacja ${spec.displayName} na finisz.',
      );
    }

    // 3. Logika specyficzna dla typu Power-Upa.
    switch (type) {
      case EsportsPowerUpType.featherweight:
        if (spec.isOptimalForGradient(currentSeg.gradientPercent)) {
          return EsportsPowerUpStrategyDecision(
            powerUpType: type,
            recommendedAction: EsportsPowerUpAction.activateNow,
            shouldActivateNow: true,
            urgencyScore: 0.88,
            estimatedPowerSavingsWatts: estimatedSavings,
            estimatedTimeGainSeconds: estimatedTimeGain,
            reasonPl:
                'Stromy podjazd (${currentSeg.gradientPercent.toStringAsFixed(1)}%): optymalne okno dla Featherweight (-10% masy).',
          );
        }
        if (nextSeg.index != currentSeg.index &&
            spec.isOptimalForGradient(nextSeg.gradientPercent)) {
          return EsportsPowerUpStrategyDecision(
            powerUpType: type,
            recommendedAction: EsportsPowerUpAction.holdForClimb,
            shouldActivateNow: false,
            urgencyScore: 0.25,
            estimatedPowerSavingsWatts: estimatedSavings,
            estimatedTimeGainSeconds: estimatedTimeGain,
            reasonPl:
                'Zachowaj Featherweight na zbliżającą się wspinaczkę (${nextSeg.gradientPercent.toStringAsFixed(1)}%).',
          );
        }
        return EsportsPowerUpStrategyDecision(
          powerUpType: type,
          recommendedAction: EsportsPowerUpAction.holdForClimb,
          shouldActivateNow: false,
          urgencyScore: 0.20,
          estimatedPowerSavingsWatts: estimatedSavings,
          estimatedTimeGainSeconds: estimatedTimeGain,
          reasonPl:
              'Płaski lub zjazdowy odcinek — zachowaj Featherweight na podjazd (>4.5%).',
        );

      case EsportsPowerUpType.aeroHelmet:
        if (spec.isOptimalForGradient(currentSeg.gradientPercent) &&
            (currentSeg.isSprintOrKomPrime || rider.speedKmh >= 44.0)) {
          return EsportsPowerUpStrategyDecision(
            powerUpType: type,
            recommendedAction: EsportsPowerUpAction.activateNow,
            shouldActivateNow: true,
            urgencyScore: 0.86,
            estimatedPowerSavingsWatts: estimatedSavings,
            estimatedTimeGainSeconds: estimatedTimeGain,
            reasonPl:
                'Wysoka prędkość (${rider.speedKmh.toStringAsFixed(1)} km/h) / strefa premii — Aero Helmet daje -25% CdA.',
          );
        }
        return EsportsPowerUpStrategyDecision(
          powerUpType: type,
          recommendedAction: EsportsPowerUpAction.holdForSprint,
          shouldActivateNow: false,
          urgencyScore: 0.30,
          estimatedPowerSavingsWatts: estimatedSavings,
          estimatedTimeGainSeconds: estimatedTimeGain,
          reasonPl:
              'Zachowaj Aero Helmet na szybki zjazd, płaski atak lub sprint finiszowy.',
        );

      case EsportsPowerUpType.burrito:
        if (rivalsDraftingBehind &&
            currentSeg.draftingEnabled &&
            (currentSeg.isSprintOrKomPrime ||
                (eliminationSchedule != null &&
                    eliminationSchedule.secondsUntilNextElimination <= 18))) {
          return EsportsPowerUpStrategyDecision(
            powerUpType: type,
            recommendedAction: EsportsPowerUpAction.activateNow,
            shouldActivateNow: true,
            urgencyScore: 0.84,
            estimatedPowerSavingsWatts: estimatedSavings,
            estimatedTimeGainSeconds: estimatedTimeGain,
            reasonPl:
                'Rywale na kole przed końcówką — odpal Burrito, aby odciąć im draft w promieniu 10 m!',
          );
        }
        return EsportsPowerUpStrategyDecision(
          powerUpType: type,
          recommendedAction: EsportsPowerUpAction.saveForElimination,
          shouldActivateNow: false,
          urgencyScore: 0.28,
          estimatedPowerSavingsWatts: estimatedSavings,
          estimatedTimeGainSeconds: estimatedTimeGain,
          reasonPl:
              'Zachowaj Burrito na moment ataku lub ostatnie sekundy przed eliminacją.',
        );

      case EsportsPowerUpType.draftBoost:
        if (currentSeg.draftingEnabled &&
            spec.isOptimalForGradient(currentSeg.gradientPercent) &&
            rider.rank > 1) {
          return EsportsPowerUpStrategyDecision(
            powerUpType: type,
            recommendedAction: EsportsPowerUpAction.activateNow,
            shouldActivateNow: true,
            urgencyScore: 0.78,
            estimatedPowerSavingsWatts: estimatedSavings,
            estimatedTimeGainSeconds: estimatedTimeGain,
            reasonPl:
                'Jazda w grupie po płaskim — Draft Boost zwiększa oszczędność mocy o 35%.',
          );
        }
        return EsportsPowerUpStrategyDecision(
          powerUpType: type,
          recommendedAction: EsportsPowerUpAction.holdForSprint,
          shouldActivateNow: false,
          urgencyScore: 0.22,
          estimatedPowerSavingsWatts: estimatedSavings,
          estimatedTimeGainSeconds: estimatedTimeGain,
          reasonPl:
              'Zachowaj Draft Boost na szybką jazdę na kole w grupie.',
        );

      case EsportsPowerUpType.steamroller:
        if (currentSeg.surfaceCrr >= 0.0040) {
          return EsportsPowerUpStrategyDecision(
            powerUpType: type,
            recommendedAction: EsportsPowerUpAction.activateNow,
            shouldActivateNow: true,
            urgencyScore: 0.85,
            estimatedPowerSavingsWatts: estimatedSavings,
            estimatedTimeGainSeconds: estimatedTimeGain,
            reasonPl:
                'Sektor o podwyższonym oporze toczenia (CRR) — Steamroller redukuje CRR o 50%.',
          );
        }
        return EsportsPowerUpStrategyDecision(
          powerUpType: type,
          recommendedAction: EsportsPowerUpAction.holdForSprint,
          shouldActivateNow: false,
          urgencyScore: 0.25,
          estimatedPowerSavingsWatts: estimatedSavings,
          estimatedTimeGainSeconds: estimatedTimeGain,
          reasonPl:
              'Gładki asfalt wirtualny — zachowaj Steamroller na odcinek o wyższym CRR.',
        );
    }
  }

  /// Aktualizuje zegar wyścigu eliminacyjnego i przeprowadza eliminację co 60 s.
  EsportsEliminationStepResult evaluateEliminationRound({
    required Elimination60sScheduleState schedule,
    required List<EsportsRiderLiveState> riders,
    required int elapsedIncrementSeconds,
  }) {
    final int nextElapsed =
        schedule.elapsedSeconds + math.max<int>(0, elapsedIncrementSeconds);
    var updatedSchedule = schedule.copyWith(elapsedSeconds: nextElapsed);

    final activeRiders = riders.where((r) => r.isActiveInRace).toList()
      ..sort((a, b) => b.distanceMeters.compareTo(a.distanceMeters));

    // Aktualizacja pozycji rankingu oraz straty czasowej do lidera.
    final leaderDist =
        activeRiders.isNotEmpty ? activeRiders.first.distanceMeters : 0.0;
    final rerankedById = <String, EsportsRiderLiveState>{};
    for (var i = 0; i < activeRiders.length; i++) {
      final r = activeRiders[i];
      final speedMs = math.max(4.0, r.speedKmh / 3.6);
      final gapSeconds = math.max(0.0, (leaderDist - r.distanceMeters) / speedMs);
      rerankedById[r.riderId] = r.copyWith(
        rank: i + 1,
        gapToLeaderSeconds: gapSeconds,
      );
    }

    final shouldTrigger =
        activeRiders.length > 1 && nextElapsed >= updatedSchedule.nextTriggerSecond;

    if (!shouldTrigger) {
      final merged = riders
          .map((r) => rerankedById[r.riderId] ?? r)
          .toList(growable: false);
      return EsportsEliminationStepResult(
        updatedSchedule: updatedSchedule,
        updatedRiders: merged,
        eliminationTriggered: false,
      );
    }

    // Ostatni aktywny kolarz odpada w tej rundzie.
    final lastRider = rerankedById[activeRiders.last.riderId]!;
    final secondLastRider = rerankedById[activeRiders[activeRiders.length - 2].riderId]!;
    final gapMeters = math.max(
      0.0,
      secondLastRider.distanceMeters - lastRider.distanceMeters,
    );
    final photoFinishGapSeconds =
        gapMeters / math.max(4.0, lastRider.speedKmh / 3.6);

    final eliminatedRider = lastRider.copyWith(
      verdict: EsportsAvatarVerdict.eliminated,
      eliminatedAtSecond: nextElapsed,
      eliminatedRound: updatedSchedule.currentRound,
      currentPowerWatts: 0.0,
      speedKmh: 0.0,
    );
    rerankedById[eliminatedRider.riderId] = eliminatedRider;

    final remainingCount = activeRiders.length - 1;
    updatedSchedule = updatedSchedule.recordElimination(
      eliminatedRider: eliminatedRider,
      remainingCount: remainingCount,
      photoFinishGapSeconds: photoFinishGapSeconds,
    );

    final merged = riders
        .map((r) => rerankedById[r.riderId] ?? r)
        .toList(growable: false);

    return EsportsEliminationStepResult(
      updatedSchedule: updatedSchedule,
      updatedRiders: merged,
      eliminationRecord: updatedSchedule.eliminationHistory.last,
      eliminationTriggered: true,
    );
  }

  DualRecordingComplianceStatus _evaluateDualRecordingStatus(
    EsportsRiderLiveState rider,
  ) {
    final absDelta = rider.dualRecordingDeltaPercent.abs();
    if (!rider.trainerSpec.dualPowerMeterVerified ||
        absDelta > _dualRecordingDsqThresholdPercent) {
      return DualRecordingComplianceStatus.disqualified;
    }
    if (absDelta > _dualRecordingWarningThresholdPercent ||
        rider.trainerSpec.calibrationStatus !=
            SmartTrainerCalibrationStatus.calibrated) {
      return DualRecordingComplianceStatus.warningDrift;
    }
    return DualRecordingComplianceStatus.verified;
  }

  double _resolveErgOrSimPower({
    required double requestedWatts,
    required double currentWatts,
    required SmartTrainerHardwareSpec trainer,
    required EsportsTrainerControlMode controlMode,
    required double dt,
  }) {
    final clampedRequested = requestedWatts.clamp(
      0.0,
      trainer.maxPowerWatts.toDouble(),
    );

    // W trybie ERG trenażer dąży płynnie do stałej mocy zadanej (stała czasowa ~0.8 s).
    final responseTau = controlMode == EsportsTrainerControlMode.ergMode
        ? (trainer.supportsErgMode ? 0.8 : 1.4)
        : 0.45;
    final alpha = 1.0 - math.exp(-dt / responseTau);
    return currentWatts + (clampedRequested - currentWatts) * alpha;
  }

  double _computeEffectiveDraftFactor({
    required EsportsVirtualCourseSegment segment,
    required bool hasDraftTargetAhead,
    required double baseDraftShelterIntensity,
    required bool isDraftBlockedByBurrito,
    required double powerUpDraftMultiplier,
  }) {
    if (!segment.draftingEnabled ||
        !hasDraftTargetAhead ||
        isDraftBlockedByBurrito) {
      return 1.0;
    }
    final clampedIntensity = baseDraftShelterIntensity.clamp(0.0, 1.0);
    final rawReduction =
        _maxDraftReductionFraction * clampedIntensity * powerUpDraftMultiplier;
    return (1.0 - rawReduction).clamp(0.45, 1.0);
  }

  double _solveSteadyStateSpeedMs({
    required double wheelPowerWatts,
    required double totalMassKg,
    required double gradientPercent,
    required double crr,
    required double cda,
    required double draftFactor,
    required double airDensity,
  }) {
    if (wheelPowerWatts <= 1.0 && gradientPercent >= 0.0) {
      return _minSpeedMs;
    }

    final slopeAngleRad = math.atan(gradientPercent / 100.0);
    final fGravity = totalMassKg * PhysicsConstants.gravity * math.sin(slopeAngleRad);
    final fRolling =
        totalMassKg * PhysicsConstants.gravity * math.cos(slopeAngleRad) * crr;
    final aeroCoeff = 0.5 * airDensity * cda * draftFactor;
    final constantForce = fGravity + fRolling;

    // Rozwiązujemy f(v) = aeroCoeff * v^3 + constantForce * v - wheelPowerWatts = 0
    var v = 10.0;
    for (var i = 0; i < 16; i++) {
      final f = aeroCoeff * v * v * v + constantForce * v - wheelPowerWatts;
      final df = 3.0 * aeroCoeff * v * v + constantForce;
      if (df.abs() < 1e-6) break;
      final nextV = v - f / df;
      v = nextV.clamp(_minSpeedMs, _maxSpeedMs);
      if ((f).abs() < 0.05) break;
    }
    return v;
  }

  double _computeInertiaTimeConstantSeconds({
    required double flywheelInertiaKg,
    required double totalMassKg,
  }) {
    final normalizedFlywheel = (flywheelInertiaKg / 10.0).clamp(0.3, 2.5);
    return (1.1 + 0.45 * normalizedFlywheel + (totalMassKg / 140.0))
        .clamp(1.2, 3.2);
  }

  _ResistanceBreakdown _computeResistancePowerBreakdown({
    required double speedMs,
    required double totalMassKg,
    required double gradientPercent,
    required double crr,
    required double cda,
    required double draftFactor,
    required double airDensity,
  }) {
    final slopeAngleRad = math.atan(gradientPercent / 100.0);
    final aeroWatts =
        0.5 * airDensity * cda * draftFactor * speedMs * speedMs * speedMs;
    final rollingWatts =
        totalMassKg * PhysicsConstants.gravity * math.cos(slopeAngleRad) * crr * speedMs;
    final gravityWatts =
        totalMassKg * PhysicsConstants.gravity * math.sin(slopeAngleRad) * speedMs;
    return _ResistanceBreakdown(
      aeroWatts: aeroWatts,
      rollingWatts: rollingWatts,
      gravityWatts: gravityWatts,
    );
  }

  double _estimatePowerSavingsWatts({
    required double speedMs,
    required double riderWeightKg,
    required double bikeWeightKg,
    required EsportsVirtualCourseSegment segment,
    required double baseCda,
    required double baseDraftFactor,
    required double airDensity,
    required EsportsPowerUpSpec activeSpec,
  }) {
    final baseMass = riderWeightKg + bikeWeightKg;
    final baseBreakdown = _computeResistancePowerBreakdown(
      speedMs: speedMs,
      totalMassKg: baseMass,
      gradientPercent: segment.gradientPercent,
      crr: segment.surfaceCrr,
      cda: baseCda,
      draftFactor: baseDraftFactor,
      airDensity: airDensity,
    );

    final modDraft = activeSpec.draftMultiplier > 1.0
        ? (1.0 - (1.0 - baseDraftFactor) * activeSpec.draftMultiplier)
            .clamp(0.45, 1.0)
        : baseDraftFactor;

    final modBreakdown = _computeResistancePowerBreakdown(
      speedMs: speedMs,
      totalMassKg: (riderWeightKg * activeSpec.massMultiplier) + bikeWeightKg,
      gradientPercent: segment.gradientPercent,
      crr: segment.surfaceCrr * activeSpec.crrMultiplier,
      cda: baseCda * activeSpec.cdaMultiplier,
      draftFactor: modDraft,
      airDensity: airDensity,
    );

    return math.max(0.0, baseBreakdown.totalWatts - modBreakdown.totalWatts);
  }

  double _updateWPrimeBalance({
    required double currentWPrimeJoules,
    required double maxWPrimeJoules,
    required double ftpWatts,
    required double powerWatts,
    required double dtSeconds,
  }) {
    if (maxWPrimeJoules <= 0.0) return 0.0;
    final deltaFromFtp = powerWatts - ftpWatts;
    if (deltaFromFtp > 0.0) {
      return (currentWPrimeJoules - deltaFromFtp * dtSeconds)
          .clamp(0.0, maxWPrimeJoules);
    }
    // Regeneracja wykładnicza W' wg modelu Skiby (stała czasowa ~280–450 s).
    final recoveryHeadroom = math.max(10.0, -deltaFromFtp);
    final tauRecovery = 546.0 * math.exp(-0.01 * recoveryHeadroom) + 316.0;
    final recovered = maxWPrimeJoules -
        (maxWPrimeJoules - currentWPrimeJoules) * math.exp(-dtSeconds / tauRecovery);
    return recovered.clamp(0.0, maxWPrimeJoules);
  }

  EsportsPowerUpType _rollPowerUpForSegment({
    required EsportsVirtualCourseSegment nextSegment,
    required int riderIndexSeed,
  }) {
    final pool = <EsportsPowerUpType>[
      EsportsPowerUpType.aeroHelmet,
      EsportsPowerUpType.featherweight,
      EsportsPowerUpType.burrito,
      EsportsPowerUpType.draftBoost,
      if (nextSegment.surfaceCrr >= 0.0035) EsportsPowerUpType.steamroller,
    ];
    final idx = riderIndexSeed.abs() % pool.length;
    return pool[idx];
  }

  int _estimateCadenceRpm({
    required EsportsTrainerControlMode controlMode,
    required double gradientPercent,
    required double speedKmh,
    required double powerWatts,
    required double ftpWatts,
  }) {
    if (powerWatts < 30.0) return 0;
    if (controlMode == EsportsTrainerControlMode.ergMode) {
      return (90 + ((powerWatts - ftpWatts) * 0.03).round()).clamp(78, 108);
    }
    final gradientPenalty = gradientPercent > 3.0 ? (gradientPercent - 3.0) * 1.4 : 0.0;
    final speedBonus = speedKmh > 45.0 ? (speedKmh - 45.0) * 0.45 : 0.0;
    return (92.0 - gradientPenalty + speedBonus).round().clamp(68, 114);
  }
}

class _ResistanceBreakdown {
  final double aeroWatts;
  final double rollingWatts;
  final double gravityWatts;

  const _ResistanceBreakdown({
    required this.aeroWatts,
    required this.rollingWatts,
    required this.gravityWatts,
  });

  double get totalWatts => aeroWatts + rollingWatts + gravityWatts;
}
