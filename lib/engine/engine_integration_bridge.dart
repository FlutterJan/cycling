// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import '../models/equipment/bike_fit_configuration.dart';
import '../models/equipment/complete_bike.dart';
import '../models/equipment/equipment_wear_and_maintenance.dart';
import '../models/race/race_stage.dart';
import '../models/race/stage_segment.dart';
import '../models/rider/lactate_and_lab_profile.dart';
import '../models/rider/rider.dart';
import '../models/rider/rider_physiology.dart';
import '../models/team/cycling_team.dart';
import 'peloton/boids_steering_collision_avoidance.dart';
import 'peloton/rider_race_state.dart';
import 'physics/aero_calculator.dart';
import 'physics/altitude_acclimatization_and_heat_engine.dart';
import 'physics/day_condition_and_biorhythm_engine.dart';
import 'physics/gravity_and_rolling_calculator.dart';
import 'physics/speed_solver.dart';
import 'physics/tire_pressure_calculator.dart';
import 'simulation/tactical_ai_personality_profiles.dart';

/// Konfiguracja ciśnienia w oponach wybranego kolarza przed startem etapu.
class RiderTirePressureSetup {
  final double frontPressureBar;
  final double rearPressureBar;
  final RimType rimType;
  final TireSystemType? overrideSystem;

  const RiderTirePressureSetup({
    required this.frontPressureBar,
    required this.rearPressureBar,
    this.rimType = RimType.hooked,
    this.overrideSystem,
  });
}

/// Zintegrowany stan fizjologiczno-sprzętowo-taktyczny pojedynczego kolarza
/// utrzymywany w trakcie symulacji etapu przez [EngineIntegrationBridge].
class EngineIntegrationRiderContext {
  final String riderId;
  final BikeFitConfiguration bikeFit;
  final RiderTirePressureSetup tirePressureSetup;
  final ChainAndWaxCondition chainCondition;
  final RiderThermalState thermalState;
  final RiderDayConditionState dayConditionState;
  final TacticalAiArchetype aiArchetype;
  final double altitudeAcclimatizationScore;
  final double lastDraftingReduction;
  final bool isDrafting;

  const EngineIntegrationRiderContext({
    required this.riderId,
    required this.bikeFit,
    required this.tirePressureSetup,
    required this.chainCondition,
    required this.thermalState,
    required this.dayConditionState,
    required this.aiArchetype,
    required this.altitudeAcclimatizationScore,
    this.lastDraftingReduction = 0.0,
    this.isDrafting = false,
  });

  EngineIntegrationRiderContext copyWith({
    BikeFitConfiguration? bikeFit,
    RiderTirePressureSetup? tirePressureSetup,
    ChainAndWaxCondition? chainCondition,
    RiderThermalState? thermalState,
    RiderDayConditionState? dayConditionState,
    TacticalAiArchetype? aiArchetype,
    double? altitudeAcclimatizationScore,
    double? lastDraftingReduction,
    bool? isDrafting,
  }) {
    return EngineIntegrationRiderContext(
      riderId: riderId,
      bikeFit: bikeFit ?? this.bikeFit,
      tirePressureSetup: tirePressureSetup ?? this.tirePressureSetup,
      chainCondition: chainCondition ?? this.chainCondition,
      thermalState: thermalState ?? this.thermalState,
      dayConditionState: dayConditionState ?? this.dayConditionState,
      aiArchetype: aiArchetype ?? this.aiArchetype,
      altitudeAcclimatizationScore:
          altitudeAcclimatizationScore ?? this.altitudeAcclimatizationScore,
      lastDraftingReduction:
          lastDraftingReduction ?? this.lastDraftingReduction,
      isDrafting: isDrafting ?? this.isDrafting,
    );
  }
}

/// Wynik ewaluacji wszystkich kalkulatorów fizyki, fizjologii i AI przed rozwiązaniem
/// równania ruchu ([SpeedSolver]) dla pojedynczego kolarza w danym kroku symulacji.
class EngineIntegrationStepOutput {
  /// Fizjologia kolarza skorygowana o dyspozycję dnia (#189), wysokość i upał (#199)
  /// oraz profil mleczanowy LT1/LT2/VLaMax (#126).
  final RiderPhysiology effectivePhysiology;

  /// Efektywny współczynnik oporu aerodynamicznego CdA [m²] uwzględniający [BikeFitConfiguration] (#130),
  /// pozycję kolarza, kąt wiatru oraz cień aerodynamiczny Boids (#184).
  final double effectiveCdA;

  /// Efektywny współczynnik oporów toczenia Crr z uwzględnieniem ciśnienia w oponach (#132).
  final double effectiveCrr;

  /// Całkowita strata mechaniczna napędu [0.01 - 0.15] wynikająca ze stanu wosku/smaru na łańcuchu (#133).
  final double effectiveDrivetrainLoss;

  /// Gęstość powietrza na aktualnej wysokości n.p.m. i temperaturze [kg/m³].
  final double airDensityKgM3;

  /// Kąt natarcia wiatru względem osi drogi [°].
  final double relativeWindAngleDegrees;

  /// Prędkość wiatru na segmencie [m/s].
  final double windSpeedMs;

  /// Całkowita masa układu kolarz + rower + bidony [kg].
  final double totalMassKg;

  /// Efektywna umiejętność zjazdowa skorygowana o ryzyko osobowości AI (#193).
  final int effectiveDescendingSkill;

  /// Dodatkowy dryf tętna spowodowany stresem cieplnym [bpm].
  final double heartRateThermalDriftBpm;

  /// Mnożnik spalania glikogenu wynikający z profilu mleczanowego LT1/LT2/VLaMax (#126).
  final double lactateGlycogenBurnMultiplier;

  /// Opcjonalna decyzja taktyczna AI dla kolarzy niesterowanych ręcznie przez gracza (#193).
  final TacticalAiDecision? aiDecision;

  /// Zaktualizowany stan zintegrowany kolarza po tym kroku.
  final EngineIntegrationRiderContext updatedContext;

  const EngineIntegrationStepOutput({
    required this.effectivePhysiology,
    required this.effectiveCdA,
    required this.effectiveCrr,
    required this.effectiveDrivetrainLoss,
    required this.airDensityKgM3,
    required this.relativeWindAngleDegrees,
    required this.windSpeedMs,
    required this.totalMassKg,
    required this.effectiveDescendingSkill,
    required this.heartRateThermalDriftBpm,
    required this.lactateGlycogenBurnMultiplier,
    required this.aiDecision,
    required this.updatedContext,
  });
}

/// Wynik kroku ruchu ciągłego Boids (#184) zastosowanego do całego peletonu.
class EngineIntegrationBoidsUpdate {
  final Map<String, RiderRaceState> updatedRiderStates;
  final int collisionCountResolved;
  final int activeOvertakesCount;

  const EngineIntegrationBoidsUpdate({
    required this.updatedRiderStates,
    required this.collisionCountResolved,
    required this.activeOvertakesCount,
  });
}

/// Centralny most integracyjny łączący wszystkie kalkulatory fizyki, fizjologii,
/// sprzętu, AI oraz ruchu ciągłego Boids z główną pętlą [StageSimulationLoop]
/// i wątkiem roboczym [IsolateSimulationWorker].
///
/// Spina bezpośrednio w jednym spójnym przepływie obliczeniowym:
/// 1. Opór aero z uwzględnieniem [BikeFitConfiguration] (#130) i [AeroCalculator].
/// 2. Ciśnienie w oponach [TirePressureCalculator] (#132) i stan wosku [ChainAndWaxCondition] (#133).
/// 3. Aklimatyzację wysokościową i stres cieplny [AltitudeAcclimatizationAndHeatEngine] (#199).
/// 4. Dyspozycję dnia "Noga Dnia" [DayConditionAndBiorhythmEngine] (#189).
/// 5. Profil mleczanowy LT1 / LT2 / VLaMax [LactateAndLabProfile] (#126).
/// 6. Osobowości taktyczne AI [TacticalAiPersonalityProfiles] (#193).
/// 7. Omijanie kolizji i drafting Boids [BoidsSteeringCollisionAvoidance] (#184).
class EngineIntegrationBridge {
  final Map<String, EngineIntegrationRiderContext> _riderContexts;
  final Map<String, BoidRiderState> _boidStates;
  final BoidsSteeringCollisionAvoidance _boidsEngine;
  final int _raceSeed;

  EngineIntegrationBridge._({
    required Map<String, EngineIntegrationRiderContext> riderContexts,
    required Map<String, BoidRiderState> boidStates,
    required BoidsSteeringCollisionAvoidance boidsEngine,
    required int raceSeed,
  })  : _riderContexts = riderContexts,
        _boidStates = boidStates,
        _boidsEngine = boidsEngine,
        _raceSeed = raceSeed;

  /// Dostęp do bieżącego kontekstu zintegrowanego kolarza (tylko do odczytu).
  EngineIntegrationRiderContext? contextForRider(String riderId) =>
      _riderContexts[riderId];

  /// Zwraca procent oszczędności aerodynamicznej z draftingu Boids dla kolarza [0.0 - 48.0].
  double draftingSavingsPercentForRider(String riderId) {
    final ctx = _riderContexts[riderId];
    if (ctx == null) return 0.0;
    return (ctx.lastDraftingReduction * 100.0).clamp(0.0, 48.0);
  }

  /// Czy kolarz aktualnie korzysta z cienia aerodynamicznego w peletonie.
  bool isRiderDrafting(String riderId) =>
      _riderContexts[riderId]?.isDrafting ?? false;

  /// Tworzy i inicjalizuje most integracyjny dla wszystkich kolarzy na starcie etapu.
  factory EngineIntegrationBridge.initializeStage({
    required RaceStage stage,
    required String playerTeamId,
    required Map<String, Rider> allRidersMap,
    required Map<String, CompleteBike> allBikesMap,
    required Map<String, CyclingTeam> allTeamsMap,
    Map<String, BikeFitConfiguration>? customBikeFits,
    Map<String, RiderTirePressureSetup>? customTirePressures,
    Map<String, double>? altitudeAcclimatizationScores,
    Set<String> trainerWarmupRiderIds = const {},
    math.Random? random,
    int raceSeed = 42,
  }) {
    final rng = random ?? math.Random(raceSeed);
    final dayConditionEngine = DayConditionAndBiorhythmEngine(random: rng);
    const boidsEngine = BoidsSteeringCollisionAvoidance();

    final ridersList = allRidersMap.values.toList();
    final aiPersonalities = TacticalAiPersonalityProfiles.assignPelotonPersonalities(
      ridersList,
      raceSeed: raceSeed,
    );

    final initialSegment = stage.segments.isNotEmpty
        ? stage.segments.first
        : const StageSegment(
            index: 0,
            startKm: 0.0,
            lengthKm: 100.0,
            startElevationM: 100.0,
            endElevationM: 100.0,
            surfaceType: SegmentSurfaceType.smoothAsphalt,
            technicalDifficulty: 20.0,
            windDirectionDegrees: 0.0,
            roadBearingDegrees: 90.0,
            sprintOrKomClassification: SegmentClassification.none,
          );

    final bool isWetStage = stage.weatherCondition == WeatherCondition.lightRain ||
        stage.weatherCondition == WeatherCondition.heavyStorm;

    final contexts = <String, EngineIntegrationRiderContext>{};
    final boidStates = <String, BoidRiderState>{};

    for (var i = 0; i < ridersList.length; i++) {
      final rider = ridersList[i];
      final bike = allBikesMap[rider.id];
      final bool isPlayer = rider.contract.teamId == playerTeamId;

      // 1. BikeFitConfiguration (#130)
      final bikeFit = customBikeFits?[rider.id] ??
          bike?.bikeFit ??
          const BikeFitConfiguration(
            saddleHeightMm: 745.0,
            saddleSetbackMm: 58.0,
            saddleTiltDegrees: -1.5,
            cockpitWidthMm: 400,
            stemLengthMm: 115,
            spacersStackMm: 15,
            hoodInwardTiltDegrees: 6.0,
            crankArmLengthMm: 172.5,
            cleatOffsetMm: -3.0,
          );

      // 2. Ciśnienie w oponach (#132)
      final RiderTirePressureSetup pressureSetup;
      if (customTirePressures?[rider.id] != null) {
        pressureSetup = customTirePressures![rider.id]!;
      } else if (bike != null) {
        final recommended = TirePressureCalculator.calculateFromBikeAndRider(
          bike: bike,
          physiology: rider.physiology,
          surfaceType: initialSegment.surfaceType,
          isWet: isWetStage,
        );
        pressureSetup = RiderTirePressureSetup(
          frontPressureBar: recommended.frontPressureBar,
          rearPressureBar: recommended.rearPressureBar,
          overrideSystem: recommended.tireSystem,
        );
      } else {
        pressureSetup = const RiderTirePressureSetup(
          frontPressureBar: 4.5,
          rearPressureBar: 4.7,
        );
      }

      // 3. Stan wosku i łańcucha (#133)
      final chainCondition = bike?.wear.chain ??
          ChainAndWaxCondition.brandNewHotMeltWax(
            allWeatherFormula: isWetStage,
          );

      // 4. Dyspozycja dnia "Noga Dnia" (#189)
      final drawInputs = DayConditionDrawInputs.fromRider(
        rider: rider,
        weatherCondition: stage.weatherCondition,
        temperatureCelsius: stage.baseTemperatureCelsius,
        isPlayerRider: isPlayer,
        didTrainerWarmup: trainerWarmupRiderIds.contains(rider.id),
      );
      final drawnScore = dayConditionEngine.drawConditionScore(drawInputs);
      final dayCondition = RiderDayConditionState(
        riderId: rider.id,
        actualCondition: drawnScore,
        isRevealed: !isPlayer || drawInputs.didTrainerWarmup,
        isPlayerRider: isPlayer,
        didTrainerWarmup: drawInputs.didTrainerWarmup,
      );

      // 5. Aklimatyzacja wysokościowa i stan termiczny (#199)
      final double baseAcclimatization =
          altitudeAcclimatizationScores?[rider.id] ??
              (AltitudeAcclimatizationAndHeatEngine.isHighAltitudeNativeCountry(
                      rider.nationalityIso)
                  ? 95.0
                  : 45.0);
      final thermalState = RiderThermalState(
        heatAcclimatizationScore: rider.skills.heatTolerance.toDouble(),
      );

      // 6. Osobowość taktyczna AI (#193)
      final aiArchetype =
          aiPersonalities[rider.id] ?? TacticalAiArchetype.loyalRoadCaptain;

      contexts[rider.id] = EngineIntegrationRiderContext(
        riderId: rider.id,
        bikeFit: bikeFit,
        tirePressureSetup: pressureSetup,
        chainCondition: chainCondition,
        thermalState: thermalState,
        dayConditionState: dayCondition,
        aiArchetype: aiArchetype,
        altitudeAcclimatizationScore: baseAcclimatization,
      );

      // 7. Stan startowy Boids w siatce peletonu (#184)
      final int row = i ~/ 8;
      final int col = i % 8;
      final double startLateral = ((col - 3.5) * 0.75).clamp(-3.0, 3.0);
      final double startDistance = math.max(0.0, 30.0 - (row * 2.1));

      boidStates[rider.id] = BoidRiderState(
        riderId: rider.id,
        distanceMeters: startDistance,
        lateralOffsetMeters: startLateral,
        longitudinalSpeedMs: 11.0,
        targetSpeedMs: 11.0,
      );
    }

    return EngineIntegrationBridge._(
      riderContexts: contexts,
      boidStates: boidStates,
      boidsEngine: boidsEngine,
      raceSeed: raceSeed,
    );
  }

  /// Oblicza zintegrowane parametry fizjologii, aerodynamiki, oporów toczenia,
  /// napędu oraz decyzji AI dla pojedynczego kolarza w bieżącym kroku symulacji.
  EngineIntegrationStepOutput evaluateRiderPreStep({
    required Rider rider,
    required CompleteBike bike,
    required RiderRaceState riderState,
    required RaceStage stage,
    required StageSegment segment,
    required double currentDraftingModifier,
    required double timeStepSeconds,
    required bool isPlayerRider,
    required double distanceRemainingKm,
    List<StageSegment> upcomingSegments = const [],
  }) {
    final ctx = _riderContexts[rider.id] ??
        EngineIntegrationRiderContext(
          riderId: rider.id,
          bikeFit: bike.bikeFit,
          tirePressureSetup: const RiderTirePressureSetup(
            frontPressureBar: 4.5,
            rearPressureBar: 4.7,
          ),
          chainCondition: bike.wear.chain,
          thermalState: RiderThermalState(
            heatAcclimatizationScore: rider.skills.heatTolerance.toDouble(),
          ),
          dayConditionState: RiderDayConditionState(
            riderId: rider.id,
            actualCondition: 0,
            isRevealed: true,
            isPlayerRider: isPlayerRider,
            didTrainerWarmup: false,
          ),
          aiArchetype: TacticalAiArchetype.loyalRoadCaptain,
          altitudeAcclimatizationScore: 50.0,
        );

    final double currentSpeedMs = math.max(0.5, riderState.currentSpeedMs);
    final double currentSpeedKmh = currentSpeedMs * 3.6;
    final double currentWatts = riderState.currentWatts.toDouble();
    final double altitudeMeters =
        (segment.startElevationM + segment.endElevationM) * 0.5;
    final bool isWetStage = stage.weatherCondition == WeatherCondition.lightRain ||
        stage.weatherCondition == WeatherCondition.heavyStorm;

    // -------------------------------------------------------------------------
    // 1. Profil mleczanowy LT1 / LT2 / VLaMax (#126)
    // -------------------------------------------------------------------------
    final LactateAndLabProfile lab = rider.labProfile;
    final double baseLt2 = lab.lt2Watts > 0
        ? lab.lt2Watts.toDouble()
        : rider.physiology.ftpWatts.toDouble();
    // Wyższe VLaMax szybciej drenuje glikogen powyżej LT1; niższe VLaMax (diesel) oszczędza.
    final double vlaNorm = (lab.vlaMaxMmolLPerSec - 0.42).clamp(-0.25, 0.50);
    final double lactateGlycogenBurnMultiplier =
        currentWatts > lab.lt1Watts
            ? (1.0 + (vlaNorm * 0.35)).clamp(0.82, 1.25)
            : (1.0 - (vlaNorm * 0.10)).clamp(0.90, 1.08);

    // -------------------------------------------------------------------------
    // 2. Dyspozycja dnia "Noga Dnia" (#189)
    // -------------------------------------------------------------------------
    var updatedDayCondition = ctx.dayConditionState;
    if (!updatedDayCondition.isRevealed &&
        segment.gradientPercent >= kFirstClimbMinGradientPercent &&
        currentWatts >= lab.lt1Watts) {
      updatedDayCondition = updatedDayCondition.copyWith(isRevealed: true);
    }
    final DayConditionModifiers dayMods = updatedDayCondition.modifiers;

    // -------------------------------------------------------------------------
    // 3. Aklimatyzacja wysokościowa i stres cieplny (#199)
    // -------------------------------------------------------------------------
    final altHeatResult = AltitudeAcclimatizationAndHeatEngine.evaluateCombinedStep(
      altitudeMeters: altitudeMeters,
      baseFtpWatts: baseLt2 * dayMods.ftpMultiplier,
      altitudeAcclimatizationScore: ctx.altitudeAcclimatizationScore,
      nationalityIso: rider.nationalityIso,
      thermalState: ctx.thermalState,
      deltaTimeSeconds: math.max(0.0, timeStepSeconds),
      ambientTemperatureCelsius: stage.baseTemperatureCelsius,
      airSpeedMetersPerSecond: currentSpeedMs,
      currentPowerWatts: currentWatts,
      heatTolerance: rider.skills.heatTolerance,
      relativeHumidity01: isWetStage ? 0.85 : 0.45,
      gradientPercent: segment.gradientPercent,
    );

    var updatedThermalState = altHeatResult.heatResult.updatedState;
    if (altHeatResult.heatResult.shouldRecommendIceSocks &&
        updatedThermalState.iceSocksAvailableInTeamCar > 0 &&
        !updatedThermalState.isIceSockActive) {
      updatedThermalState =
          AltitudeAcclimatizationAndHeatEngine.deployIceSocks(updatedThermalState);
    }

    // Składamy efektywną fizjologię do WPrimeBalanceEngine i NutritionAndGlycogenEngine
    final int effectiveFtpWatts = math.max(
      80,
      (baseLt2 * dayMods.ftpMultiplier * altHeatResult.combinedFtpMultiplier)
          .round(),
    );
    final int effectiveWPrimeJoules =
        dayMods.applyToWPrime(rider.physiology.wPrimeJoules);
    final double effectiveRecoveryRate =
        (rider.physiology.recoveryRate * dayMods.recoverySpeedMultiplier)
            .clamp(0.5, 2.5);
    final double effectiveVo2Max =
        (rider.physiology.vo2Max * dayMods.vo2MaxMultiplier).clamp(45.0, 99.0);

    final RiderPhysiology effectivePhysiology = rider.physiology.copyWith(
      ftpWatts: effectiveFtpWatts,
      wPrimeJoules: effectiveWPrimeJoules,
      recoveryRate: effectiveRecoveryRate,
      vo2Max: effectiveVo2Max,
      labProfile: lab,
    );

    // -------------------------------------------------------------------------
    // 4. Opór aerodynamiczny z uwzględnieniem BikeFitConfiguration (#130)
    //    oraz oszczędności cienia aerodynamicznego Boids (#184)
    // -------------------------------------------------------------------------
    final RiderPosition position = _resolveRiderPosition(
      segment: segment,
      order: riderState.activeTacticalOrder,
      currentSpeedKmh: currentSpeedKmh,
      bikeFit: ctx.bikeFit,
    );

    final double relWindAngle = AeroCalculator.calculateRelativeWindAngle(
      windDirectionDegrees: segment.windDirectionDegrees,
      roadBearingDegrees: segment.roadBearingDegrees,
    );
    final double airDensity = AeroCalculator.calculateAirDensity(
      altitudeMeters: altitudeMeters,
      temperatureCelsius: stage.baseTemperatureCelsius,
    );

    final double combinedDrafting =
        (ctx.lastDraftingReduction + currentDraftingModifier).clamp(0.0, 0.48);

    // Łączymy CdA ramy i kół z pełnym modelem BikeFitConfiguration (#130)
    final double customBikeFitCdaModifier = bike.frame.aeroCdaModifier +
        bike.wheelset.aeroCdaModifier +
        ctx.bikeFit.totalCdaModifier;

    final double baseCdA = AeroCalculator.calculateEffectiveCdA(
      riderFrontalAreaM2: rider.physiology.frontalAreaM2,
      position: position,
      bikeCdaModifier: customBikeFitCdaModifier,
      draftingReduction: combinedDrafting * rider.skills.draftingBonusMultiplier,
      yawAngleRadians: (relWindAngle * math.pi) / 180.0,
    );
    final double effectiveCdA =
        math.max(AeroCalculator.minAllowedCdA, baseCdA * rider.skills.cdaModifier);

    // -------------------------------------------------------------------------
    // 5. Ciśnienie w oponach (#132) i stan wosku na łańcuchu (#133)
    // -------------------------------------------------------------------------
    final double totalMassKg = GravityAndRollingCalculator.calculateTotalMassKg(
      riderWeightKg: rider.physiology.weightKg,
      bikeWeightKg: bike.totalWeightKg,
    );

    final tireRec = TirePressureCalculator.calculateFromBikeAndRider(
      bike: bike,
      physiology: rider.physiology,
      surfaceType: segment.surfaceType,
      isWet: isWetStage,
      rimType: ctx.tirePressureSetup.rimType,
      overrideSystem: ctx.tirePressureSetup.overrideSystem,
    );
    final tireEval = TirePressureCalculator.evaluatePressure(
      frontPressureBar: ctx.tirePressureSetup.frontPressureBar,
      rearPressureBar: ctx.tirePressureSetup.rearPressureBar,
      recommendation: tireRec,
      speedKmh: math.max(15.0, currentSpeedKmh),
    );

    final double baseCrr = GravityAndRollingCalculator.calculateEffectiveCrr(
      tire: bike.tire,
      surfaceType: segment.surfaceType,
    );
    // Straty impedancji i histerezy opon w Watach przeliczone na przyrost Crr
    final double normalForceN =
        totalMassKg * 9.80665 * math.cos(math.atan(segment.gradientPercent / 100.0));
    final double tirePenaltyCrr = (normalForceN > 1.0 && currentSpeedMs > 1.0)
        ? (tireEval.totalRollingPenaltyWatts / (normalForceN * currentSpeedMs))
        : 0.0;
    final double effectiveCrr = (baseCrr + tirePenaltyCrr).clamp(0.0018, 0.025);

    // Zużycie wosku łańcucha w bieżącym kroku
    final double stepDistanceKm = (currentSpeedMs * math.max(0.0, timeStepSeconds)) / 1000.0;
    final ChainAndWaxCondition updatedChain = _advanceChainCondition(
      current: ctx.chainCondition,
      stepDistanceKm: stepDistanceKm,
      isWet: isWetStage,
    );

    final double groupsetLoss = (1.0 - bike.groupset.mechanicalEfficiency).clamp(0.005, 0.08);
    // Bazowe tarcie nowego wosku to ~3.5W przy 250W (1.4%). Różnica ponad bazę dodaje strat napędu.
    final double waxLossFraction =
        (updatedChain.effectiveFrictionLossWatts / 250.0).clamp(0.010, 0.090);
    final double effectiveDrivetrainLoss =
        math.max(groupsetLoss, waxLossFraction).clamp(0.010, 0.140);

    // -------------------------------------------------------------------------
    // 6. Osobowości taktyczne AI (#193)
    // -------------------------------------------------------------------------
    TacticalAiDecision? aiDecision;
    int effectiveDescendingSkill = rider.skills.descending;

    if (!isPlayerRider) {
      final aiContext = TacticalAiRaceContext(
        rider: rider,
        riderState: riderState,
        currentSegment: segment,
        upcomingSegments: upcomingSegments,
        distanceRemainingKm: distanceRemainingKm,
        isInBreakaway: riderState.groupIndex > 0,
        randomSeed: _raceSeed,
      );
      aiDecision = TacticalAiPersonalityProfiles.evaluateRiderDecision(
        aiContext,
        overrideArchetype: ctx.aiArchetype,
      );
      final double adjustedDescent =
          rider.skills.descending * aiDecision.descentRiskMultiplier;
      effectiveDescendingSkill = adjustedDescent.round().clamp(1, 99);
    }

    final updatedContext = ctx.copyWith(
      thermalState: updatedThermalState,
      dayConditionState: updatedDayCondition,
      chainCondition: updatedChain,
    );
    _riderContexts[rider.id] = updatedContext;

    return EngineIntegrationStepOutput(
      effectivePhysiology: effectivePhysiology,
      effectiveCdA: effectiveCdA,
      effectiveCrr: effectiveCrr,
      effectiveDrivetrainLoss: effectiveDrivetrainLoss,
      airDensityKgM3: airDensity,
      relativeWindAngleDegrees: relWindAngle,
      windSpeedMs: stage.windSpeedKmh / 3.6,
      totalMassKg: totalMassKg,
      effectiveDescendingSkill: effectiveDescendingSkill,
      heartRateThermalDriftBpm:
          altHeatResult.heatResult.heartRateThermalDriftBpm,
      lactateGlycogenBurnMultiplier: lactateGlycogenBurnMultiplier,
      aiDecision: aiDecision,
      updatedContext: updatedContext,
    );
  }

  /// Wykonuje krok fizyki ruchu ciągłego peletonu [BoidsSteeringCollisionAvoidance] (#184)
  /// dla wszystkich kolarzy po obliczeniu prędkości w [SpeedSolver].
  ///
  /// Aktualizuje bezkolizyjne pozycje poprzeczne (`lateralPositionRoad`), wygładzoną prędkość
  /// wzdłużną w efekcie akordeonu oraz realne oszczędności draftingu na kolejny krok.
  EngineIntegrationBoidsUpdate applyBoidsPelotonStep({
    required Map<String, RiderRaceState> riderStates,
    required StageSegment segment,
    required double windSpeedKmh,
    required double dtSeconds,
  }) {
    if (riderStates.isEmpty || dtSeconds <= 0.0) {
      return EngineIntegrationBoidsUpdate(
        updatedRiderStates: riderStates,
        collisionCountResolved: 0,
        activeOvertakesCount: 0,
      );
    }

    final List<BoidRiderState> frameInputs = [];
    for (final entry in riderStates.entries) {
      final rId = entry.key;
      final rState = entry.value;
      final prevBoid = _boidStates[rId];
      final double roadWidth = _boidsEngine.resolveRoadWidthMeters(segment: segment);
      final double currentLateralMeters =
          prevBoid?.lateralOffsetMeters ?? (rState.lateralPositionRoad * roadWidth * 0.45);

      frameInputs.add(
        BoidRiderState(
          riderId: rId,
          distanceMeters: rState.distanceCoveredMeters,
          lateralOffsetMeters: currentLateralMeters,
          lateralVelocityMs: prevBoid?.lateralVelocityMs ?? 0.0,
          longitudinalSpeedMs: rState.currentSpeedMs,
          targetSpeedMs: rState.currentSpeedMs,
          leanAngleRad: prevBoid?.leanAngleRad ?? 0.0,
          overtakeLane: prevBoid?.overtakeLane ?? OvertakeLaneDirection.none,
          overtakeCooldownSec: prevBoid?.overtakeCooldownSec ?? 0.0,
          draftingTargetRiderId: prevBoid?.draftingTargetRiderId,
          tacticalOrder: rState.activeTacticalOrder,
          isCrashed: false,
          isDnf: false,
        ),
      );
    }

    // Sub-stepping dla stabilności 60 FPS przy dt = 1.0s
    final int subSteps = dtSeconds >= 0.5 ? 6 : 1;
    final double subDt = dtSeconds / subSteps;

    BoidsFrameResult result = _boidsEngine.stepFrame(
      riders: frameInputs,
      dtSeconds: subDt,
      segment: segment,
      windSpeedKmh: windSpeedKmh,
    );
    for (int s = 1; s < subSteps; s++) {
      result = _boidsEngine.stepFrame(
        riders: result.riders,
        dtSeconds: subDt,
        segment: segment,
        windSpeedKmh: windSpeedKmh,
      );
    }

    final updatedStates = Map<String, RiderRaceState>.from(riderStates);
    for (final boid in result.riders) {
      _boidStates[boid.riderId] = boid;

      final existing = updatedStates[boid.riderId];
      if (existing == null) continue;

      final double normalizedLat =
          boid.normalizedLateralPosition(result.effectiveRoadWidthMeters);
      final bool hasDraftTarget = boid.draftingTargetRiderId != null &&
          boid.tacticalOrder != TacticalOrder.pullGroup &&
          boid.tacticalOrder != TacticalOrder.attack;

      // Rzeczywista redukcja oporu z pozycji w peletonie Boids
      final double computedDrafting = hasDraftTarget
          ? (segment.gradientPercent > 6.5 ? 0.16 : 0.36)
          : 0.0;

      final ctx = _riderContexts[boid.riderId];
      if (ctx != null) {
        _riderContexts[boid.riderId] = ctx.copyWith(
          lastDraftingReduction: computedDrafting,
          isDrafting: hasDraftTarget,
        );
      }

      // Wygładzamy prędkość wzdłużną o korektę kolizyjną i zwężeniową z Boids
      final double blendedSpeed =
          ((existing.currentSpeedMs * 0.65) + (boid.longitudinalSpeedMs * 0.35))
              .clamp(0.5, 32.0);

      updatedStates[boid.riderId] = existing.copyWith(
        lateralPositionRoad: normalizedLat,
        currentSpeedMs: blendedSpeed,
      );
    }

    return EngineIntegrationBoidsUpdate(
      updatedRiderStates: updatedStates,
      collisionCountResolved: result.collisionCountResolved,
      activeOvertakesCount: result.activeOvertakesCount,
    );
  }

  /// Rozwiązuje prędkość kolarza w [SpeedSolver] bezpośrednio na podstawie wyniku [evaluateRiderPreStep].
  SpeedSolverResult solveSpeedForIntegratedStep({
    required EngineIntegrationStepOutput stepOutput,
    required CompleteBike bike,
    required StageSegment segment,
    required double currentSpeedMs,
    required double actualExecutedWatts,
    required double timeStepSeconds,
  }) {
    return SpeedSolver.solveNextSecond(
      inputWatts: actualExecutedWatts,
      currentSpeedMs: currentSpeedMs,
      totalMassKg: stepOutput.totalMassKg,
      gradientPercent: segment.gradientPercent,
      effectiveCdA: stepOutput.effectiveCdA,
      airDensityKgM3: stepOutput.airDensityKgM3,
      effectiveCrr: stepOutput.effectiveCrr,
      windSpeedMs: stepOutput.windSpeedMs,
      relativeWindAngleDegrees: stepOutput.relativeWindAngleDegrees,
      descendingSkill: stepOutput.effectiveDescendingSkill,
      technicalDifficulty: segment.technicalDifficulty,
      drivetrainLoss: stepOutput.effectiveDrivetrainLoss,
      timeStepSeconds: timeStepSeconds,
      wheelInertiaKgM2: bike.wheelset.momentOfInertia,
    );
  }

  RiderPosition _resolveRiderPosition({
    required StageSegment segment,
    required TacticalOrder order,
    required double currentSpeedKmh,
    required BikeFitConfiguration bikeFit,
  }) {
    if (segment.gradientPercent >= 6.5 && order == TacticalOrder.attack) {
      return RiderPosition.standing;
    }
    if (bikeFit.hasExtremeAeroHoods &&
        (order == TacticalOrder.attack || order == TacticalOrder.pullGroup) &&
        currentSpeedKmh >= 40.0) {
      return RiderPosition.puppyPaws;
    }
    if (order == TacticalOrder.attack ||
        order == TacticalOrder.pullGroup ||
        segment.gradientPercent < -3.0) {
      return RiderPosition.drops;
    }
    return RiderPosition.hoods;
  }

  ChainAndWaxCondition _advanceChainCondition({
    required ChainAndWaxCondition current,
    required double stepDistanceKm,
    required bool isWet,
  }) {
    if (stepDistanceKm <= 0.0) return current;

    final double washoutThreshold =
        math.max(25.0, current.lubricantType.wetWashoutThresholdKm);
    final double filmLossPerKm = isWet ? (100.0 / washoutThreshold) : (100.0 / 600.0);
    final double newFilm =
        (current.waxFilmRemainingPercent - (stepDistanceKm * filmLossPerKm))
            .clamp(0.0, 100.0);

    return ChainAndWaxCondition(
      lubricantType: current.lubricantType,
      waxFilmRemainingPercent: newFilm,
      chainElongationPercent:
          (current.chainElongationPercent + (stepDistanceKm * 0.00015))
              .clamp(0.0, 1.5),
      totalChainMileageKm: current.totalChainMileageKm + stepDistanceKm,
      mileageSinceLastWaxKm: current.mileageSinceLastWaxKm + stepDistanceKm,
      isWashedOut: current.isWashedOut || newFilm <= 0.0,
    );
  }
}
