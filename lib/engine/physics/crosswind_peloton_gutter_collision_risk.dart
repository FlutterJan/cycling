// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/physics_constants.dart';
import '../../core/theme/app_colors.dart';

/// Rodzaj pobocza lub krawędzi drogi po stronie zawietrznej (rynsztok).
enum GutterShoulderType {
  /// Utwardzony asfaltowy rynsztok z drobnym piaskiem i kratkami ściekowymi.
  pavedDrainageGutter(
    'Paved Gutter',
    'Asfaltowy rynsztok',
    0.0068,
    0.76,
    0.22,
  ),

  /// Sypkie pobocze szutrowe za krawędzią asfaltu.
  gravelShoulder(
    'Gravel Shoulder',
    'Szutrowe pobocze',
    0.0185,
    0.48,
    0.58,
  ),

  /// Mokre lub miękkie pobocze trawiaste.
  wetGrassVerge(
    'Wet Grass Verge',
    'Mokre trawiaste pobocze',
    0.0260,
    0.30,
    0.78,
  ),

  /// Wysoki krawężnik lub barierka ochronna bezpośrednio przy asfalcie.
  raisedCurbOrGuardrail(
    'Curb / Guardrail',
    'Krawężnik / barierka',
    0.0140,
    0.62,
    0.88,
  ),

  /// Głębokie błotniste pobocze lub rów melioracyjny.
  deepMuddyDitch(
    'Muddy Ditch',
    'Błotnisty rów',
    0.0380,
    0.22,
    0.96,
  );

  final String labelEn;
  final String labelPl;

  /// Współczynnik oporu toczenia po zjechaniu na dane pobocze.
  final double offRoadCrr;

  /// Współczynnik przyczepności bocznej (mu) na danym poboczu.
  final double lateralGripMu;

  /// Bazowy współczynnik dotkliwości zjazdu / uderzenia (0.0–1.0).
  final double baseHazardSeverity;

  const GutterShoulderType(
    this.labelEn,
    this.labelPl,
    this.offRoadCrr,
    this.lateralGripMu,
    this.baseHazardSeverity,
  );
}

/// Poziom ryzyka zjechania na pobocze lub kolizji podczas wyprzedzania w rynsztoku.
enum GutterRiskLevel {
  /// Bezpieczny zapas szerokości korytarza.
  safeClearance('Safe Clearance', 'Bezpieczny przejazd', AppColors.statusSuccess),

  /// Ciasny przejazd wymagający wysokiej precyzji prowadzenia.
  tightSqueeze('Tight Squeeze', 'Ciasny korytarz', AppColors.accentBlue),

  /// Wysokie ryzyko zahaczenia o krawędź asfaltu lub rywala.
  highEdgeHazard('High Edge Hazard', 'Ryzyko krawędzi', AppColors.amberWarning),

  /// Bezpośrednie zagrożenie zjechania na pobocze.
  imminentRunOff('Imminent Run-Off', 'Zjazd na pobocze', AppColors.powerZone5),

  /// Krytyczne ryzyko kraksy lub domina w wachlarzu.
  criticalCrashRisk('Critical Crash Risk', 'Krytyczne ryzyko kraksy', AppColors.crimsonAlert);

  final String labelEn;
  final String labelPl;
  final Color color;

  const GutterRiskLevel(this.labelEn, this.labelPl, this.color);
}

/// Wynik symulowanego manewru wyprzedzania w rynsztoku na wietrze bocznym.
enum GutterOvertakeOutcome {
  /// Czyste wyprzedzenie bez opuszczenia asfaltu.
  cleanPass('Clean Pass', 'Czyste wyprzedzenie', AppColors.statusSuccess),

  /// Bezpieczne wycofanie się za koło po zamknięciu luki.
  abortedDropBack('Aborted / Drop Back', 'Wycofanie za koło', AppColors.accentBlue),

  /// Chwilowy zjazd na pobocze z udanym powrotem na asfalt.
  shoulderExcursionRecovered(
    'Shoulder Recovery',
    'Powrót z pobocza',
    AppColors.amberWarning,
  ),

  /// Zahaczenie o krawężnik lub gwałtowne odbicie do wnętrza peletonu.
  curbClipSwerve('Curb Clip Swerve', 'Odbicie od krawężnika', AppColors.powerZone5),

  /// Uślizg na poboczu skutkujący upadkiem wyprzedzającego kolarza.
  vergeWashoutCrash('Verge Washout Crash', 'Upadek na poboczu', AppColors.crimsonAlert),

  /// Kolizja z sąsiadem z wachlarza wywołująca kraksę w grupie.
  pelotonDominoCrash('Peloton Domino Crash', 'Kraksa w wachlarzu', AppColors.crimsonAlert);

  final String labelEn;
  final String labelPl;
  final Color color;

  const GutterOvertakeOutcome(this.labelEn, this.labelPl, this.color);
}

/// Dane wejściowe dla modelu fizyki ryzyka zjechania na pobocze w rynsztoku.
@immutable
class GutterCollisionRiskInput {
  /// Szerokość dostępnego korytarza między skrajem wachlarza a krawędzią asfaltu [m].
  final double availableGutterWidthMeters;

  /// Szerokość obrysu kolarza wraz z kierownicą [m] (typowo 0.56–0.64 m).
  final double riderEnvelopeWidthMeters;

  /// Prędkość jazdy peletonu [m/s].
  final double pelotonSpeedMs;

  /// Nadwyżka prędkości wyprzedzającego kolarza względem wachlarza [m/s].
  final double overtakeSpeedDeltaMs;

  /// Prędkość wiatru [m/s].
  final double windSpeedMs;

  /// Kąt natarcia wiatru względem osi drogi [stopnie, 0 = czołowy, 90 = czysty boczny].
  final double windAngleDeg;

  /// Mnożnik porywów wiatru (1.0 = wiatr stały, 1.4+ = silne podmuchy).
  final double gustFactor;

  /// Wysokość stożka przedniego koła [mm] (wpływa na siłę boczną i moment skręcający).
  final int frontRimDepthMm;

  /// Tempo zamykania luki przez sąsiedniego kolarza z wachlarza [m/s].
  final double pelotonSqueezeRateMs;

  /// Wysokość uskoku na krawędzi asfaltu [cm].
  final double asphaltEdgeStepCm;

  /// Rodzaj pobocza po stronie zawietrznej.
  final GutterShoulderType shoulderType;

  /// Czy nawierzchnia asfaltowa jest mokra.
  final bool isWetAsphalt;

  /// Umiejętność prowadzenia roweru (0–100).
  final double bikeHandlingSkill;

  /// Równowaga / stabilność tułowia kolarza (0–100).
  final double coreStabilitySkill;

  /// Aktualny poziom zmęczenia (0.0 = wypoczęty, 1.0 = skrajne wyczerpanie).
  final double fatigueRatio;

  /// Masa całkowita kolarza i roweru [kg].
  final double totalMassKg;

  /// Wysokość n.p.m. [m] dla obliczenia gęstości powietrza.
  final double altitudeMeters;

  /// Długość manewru wyprzedzania (liczba pozycji w wachlarzu * długość roweru) [m].
  final double overtakeDistanceMeters;

  const GutterCollisionRiskInput({
    required this.availableGutterWidthMeters,
    this.riderEnvelopeWidthMeters = 0.60,
    required this.pelotonSpeedMs,
    required this.overtakeSpeedDeltaMs,
    required this.windSpeedMs,
    required this.windAngleDeg,
    this.gustFactor = 1.20,
    this.frontRimDepthMm = 50,
    this.pelotonSqueezeRateMs = 0.08,
    this.asphaltEdgeStepCm = 1.8,
    this.shoulderType = GutterShoulderType.gravelShoulder,
    this.isWetAsphalt = false,
    this.bikeHandlingSkill = 76.0,
    this.coreStabilitySkill = 74.0,
    this.fatigueRatio = 0.25,
    this.totalMassKg = 76.0,
    this.altitudeMeters = 50.0,
    this.overtakeDistanceMeters = 12.0,
  });

  GutterCollisionRiskInput copyWith({
    double? availableGutterWidthMeters,
    double? riderEnvelopeWidthMeters,
    double? pelotonSpeedMs,
    double? overtakeSpeedDeltaMs,
    double? windSpeedMs,
    double? windAngleDeg,
    double? gustFactor,
    int? frontRimDepthMm,
    double? pelotonSqueezeRateMs,
    double? asphaltEdgeStepCm,
    GutterShoulderType? shoulderType,
    bool? isWetAsphalt,
    double? bikeHandlingSkill,
    double? coreStabilitySkill,
    double? fatigueRatio,
    double? totalMassKg,
    double? altitudeMeters,
    double? overtakeDistanceMeters,
  }) {
    return GutterCollisionRiskInput(
      availableGutterWidthMeters:
          availableGutterWidthMeters ?? this.availableGutterWidthMeters,
      riderEnvelopeWidthMeters:
          riderEnvelopeWidthMeters ?? this.riderEnvelopeWidthMeters,
      pelotonSpeedMs: pelotonSpeedMs ?? this.pelotonSpeedMs,
      overtakeSpeedDeltaMs: overtakeSpeedDeltaMs ?? this.overtakeSpeedDeltaMs,
      windSpeedMs: windSpeedMs ?? this.windSpeedMs,
      windAngleDeg: windAngleDeg ?? this.windAngleDeg,
      gustFactor: gustFactor ?? this.gustFactor,
      frontRimDepthMm: frontRimDepthMm ?? this.frontRimDepthMm,
      pelotonSqueezeRateMs: pelotonSqueezeRateMs ?? this.pelotonSqueezeRateMs,
      asphaltEdgeStepCm: asphaltEdgeStepCm ?? this.asphaltEdgeStepCm,
      shoulderType: shoulderType ?? this.shoulderType,
      isWetAsphalt: isWetAsphalt ?? this.isWetAsphalt,
      bikeHandlingSkill: bikeHandlingSkill ?? this.bikeHandlingSkill,
      coreStabilitySkill: coreStabilitySkill ?? this.coreStabilitySkill,
      fatigueRatio: fatigueRatio ?? this.fatigueRatio,
      totalMassKg: totalMassKg ?? this.totalMassKg,
      altitudeMeters: altitudeMeters ?? this.altitudeMeters,
      overtakeDistanceMeters:
          overtakeDistanceMeters ?? this.overtakeDistanceMeters,
    );
  }
}

/// Wynik statycznej oceny ryzyka wyprzedzania w rynsztoku na wietrze bocznym.
@immutable
class GutterCollisionRiskResult {
  /// Składowa boczna wiatru z uwzględnieniem porywów [m/s].
  final double effectiveCrosswindMs;

  /// Siła boczna parcia wiatru i turbulencji na kolarza [N].
  final double lateralAerodynamicForceN;

  /// Przewidywana amplituda znoszenia / chwiania bocznego w luce między kołami [m].
  final double lateralSwayAmplitudeMeters;

  /// Zapas szerokości netto w rynsztoku po odjęciu obrysu i chwiania [m].
  final double netClearanceMeters;

  /// Szacowany czas trwania manewru wyprzedzania [s].
  final double maneuverDurationSeconds;

  /// Margines czasu na korektę toru jazdy zanim dojdzie do zjazdu [s].
  final double reactionMarginSeconds;

  /// Prawdopodobieństwo zjechania kołem poza krawędź asfaltu (0.0–1.0).
  final double runOffProbability;

  /// Prawdopodobieństwo kontaktu z kolarzem z wachlarza przy próbie uniknięcia pobocza (0.0–1.0).
  final double echelonCollisionProbability;

  /// Ryzyko zakleszczenia koła na uskoku krawędzi asfaltu przy powrocie (0.0–1.0).
  final double edgeCatchProbability;

  /// Złożony indeks ryzyka w skali 0–100.
  final double overallRiskScore;

  /// Dodatkowa moc potrzebna na pokonanie turbulencji w rynsztoku [W].
  final double gutterTurbulencePowerPenaltyWatts;

  /// Szacowana strata prędkości po ewentualnym zjeździe na pobocze [m/s].
  final double offRoadSpeedDropMs;

  /// Kategoria ryzyka.
  final GutterRiskLevel riskLevel;

  /// Czy zalecane jest przerwanie manewru i powrót za koło.
  final bool shouldAbortOvertake;

  /// Czytelne podsumowanie taktyczne dla dyrektora sportowego.
  final String tacticalAdvisory;

  const GutterCollisionRiskResult({
    required this.effectiveCrosswindMs,
    required this.lateralAerodynamicForceN,
    required this.lateralSwayAmplitudeMeters,
    required this.netClearanceMeters,
    required this.maneuverDurationSeconds,
    required this.reactionMarginSeconds,
    required this.runOffProbability,
    required this.echelonCollisionProbability,
    required this.edgeCatchProbability,
    required this.overallRiskScore,
    required this.gutterTurbulencePowerPenaltyWatts,
    required this.offRoadSpeedDropMs,
    required this.riskLevel,
    required this.shouldAbortOvertake,
    required this.tacticalAdvisory,
  });
}

/// Pojedyncza próbka trajektorii bocznej podczas symulacji manewru wyprzedzania.
@immutable
class GutterManeuverStepSample {
  /// Czas od rozpoczęcia wyprzedzania [s].
  final double timeSeconds;

  /// Dystans pokonany względem początku luki [m].
  final double longitudinalProgressMeters;

  /// Odległość środka koła od krawędzi asfaltu [m] (wartość < 0 oznacza zjazd na pobocze).
  final double distanceToRoadEdgeMeters;

  /// Odległość boczna do sąsiedniego kolarza z wachlarza [m].
  final double distanceToEchelonRiderMeters;

  /// Chwilowa siła boczna [N].
  final double lateralForceN;

  /// Czy koło znajduje się poza asfaltem.
  final bool isOffRoad;

  const GutterManeuverStepSample({
    required this.timeSeconds,
    required this.longitudinalProgressMeters,
    required this.distanceToRoadEdgeMeters,
    required this.distanceToEchelonRiderMeters,
    required this.lateralForceN,
    required this.isOffRoad,
  });
}

/// Pełny wynik deterministycznej symulacji manewru wyprzedzania w rynsztoku.
@immutable
class GutterOvertakeSimulationResult {
  final GutterOvertakeOutcome outcome;
  final GutterCollisionRiskResult initialRisk;
  final List<GutterManeuverStepSample> trajectory;
  final double minEdgeClearanceMeters;
  final double timeSpentOffRoadSeconds;
  final double netSpeedLossMs;
  final double estimatedTimeLostSeconds;

  const GutterOvertakeSimulationResult({
    required this.outcome,
    required this.initialRisk,
    required this.trajectory,
    required this.minEdgeClearanceMeters,
    required this.timeSpentOffRoadSeconds,
    required this.netSpeedLossMs,
    required this.estimatedTimeLostSeconds,
  });
}

/// Solver fizyki ryzyka zjechania na pobocze i kolizji podczas wyprzedzania
/// w rynsztoku (po stronie zawietrznej wachlarza) przy wietrze bocznym.
class CrosswindPelotonGutterCollisionRisk {
  CrosswindPelotonGutterCollisionRisk._();

  static const double _minSafeMarginMeters = 0.14;
  static const double _maxSwayAmplitudeMeters = 0.55;

  /// Ocenia ryzyko zjechania na pobocze i kolizji z wachlarzem dla danych warunków.
  static GutterCollisionRiskResult evaluateRisk(GutterCollisionRiskInput input) {
    final double corridor = math.max(0.05, input.availableGutterWidthMeters);
    final double envelope = input.riderEnvelopeWidthMeters.clamp(0.45, 0.85);
    final double pelotonSpeed = math.max(2.0, input.pelotonSpeedMs);
    final double deltaV = input.overtakeSpeedDeltaMs.clamp(0.1, 8.0);
    final double riderSpeed = pelotonSpeed + deltaV;

    final double rho = PhysicsConstants.getAirDensityAtAltitude(input.altitudeMeters);
    final double angleRad = (input.windAngleDeg.clamp(0.0, 180.0)) * math.pi / 180.0;
    final double lateralWindComponent = input.windSpeedMs.abs() * math.sin(angleRad);
    final double gustFactor = input.gustFactor.clamp(1.0, 2.2);
    final double effectiveCrosswind = lateralWindComponent * gustFactor;

    // Powierzchnia boczna kolarza + ramy + wkład wysokiego stożka koła
    final double rimDepthNormalized = ((input.frontRimDepthMm - 25) / 55.0).clamp(0.0, 1.3);
    final double lateralAreaM2 = 0.44 + (rimDepthNormalized * 0.085);

    // Wzrost prędkości względnej zwiększa siłę parcia bocznego (efekt Venturiego w rynsztoku)
    final double relativeAirFlowMs =
        math.sqrt(effectiveCrosswind * effectiveCrosswind + (riderSpeed * 0.18) * (riderSpeed * 0.18));
    final double lateralForceN =
        0.5 * rho * lateralAreaM2 * 1.15 * effectiveCrosswind * relativeAirFlowMs;

    // Zdolność stabilizacji toru jazdy przez kolarza
    final double handlingNorm = (input.bikeHandlingSkill / 100.0).clamp(0.1, 1.0);
    final double coreNorm = (input.coreStabilitySkill / 100.0).clamp(0.1, 1.0);
    final double fatiguePenalty = 1.0 + (input.fatigueRatio.clamp(0.0, 1.0) * 0.55);
    final double wetPenalty = input.isWetAsphalt ? 1.24 : 1.0;

    final double skillDamping =
        (0.55 + 0.45 * (0.6 * handlingNorm + 0.4 * coreNorm)).clamp(0.35, 1.0);

    // Amplituda chwiania bocznego od podmuchu w przerwach między kołami wachlarza
    final double rawSway = (lateralForceN / (math.max(45.0, input.totalMassKg) * 9.81)) *
        0.62 *
        fatiguePenalty *
        wetPenalty /
        skillDamping;
    final double swayAmplitude = rawSway.clamp(0.03, _maxSwayAmplitudeMeters);

    // Zamykanie luki przez kolarza obok skraca dostępny korytarz w trakcie wyprzedzania
    final double maneuverDuration =
        (input.overtakeDistanceMeters.clamp(2.0, 40.0) / deltaV).clamp(0.8, 18.0);
    final double squeezeLoss =
        (input.pelotonSqueezeRateMs.clamp(0.0, 0.8) * maneuverDuration * 0.45)
            .clamp(0.0, corridor * 0.65);

    final double netClearance =
        corridor - envelope - swayAmplitude - squeezeLoss;

    // Margines reakcji na korektę toru jazdy
    final double reactionTimeBase = 0.24 + (input.fatigueRatio.clamp(0.0, 1.0) * 0.18);
    final double lateralDriftSpeed =
        math.max(0.08, (swayAmplitude / 0.8) + input.pelotonSqueezeRateMs.clamp(0.0, 0.8));
    final double timeToEdge =
        math.max(0.0, (corridor - envelope * 0.5) / lateralDriftSpeed);
    final double reactionMargin = timeToEdge - reactionTimeBase;

    // Prawdopodobieństwo zjechania na pobocze (krzywa sigmoidalna względem zapasu netto)
    final double clearanceDeficit = (_minSafeMarginMeters - netClearance) / 0.28;
    final double baseRunOff = 1.0 / (1.0 + math.exp(-clearanceDeficit * 2.4));
    final double speedRiskBoost = ((riderSpeed - 12.0) / 14.0).clamp(0.0, 0.25);
    final double runOffProbability = (baseRunOff + speedRiskBoost * (1.0 - skillDamping * 0.5))
        .clamp(0.01, 0.99);

    // Ryzyko kolizji z wachlarzem rośnie, gdy korytarz jest wąski i kolarz odbija od krawędzi
    final double collisionRaw =
        (runOffProbability * 0.65) +
            ((input.pelotonSqueezeRateMs / 0.35).clamp(0.0, 1.0) * 0.30) -
            (handlingNorm * 0.22);
    final double echelonCollisionProbability = collisionRaw.clamp(0.01, 0.96);

    // Ryzyko zakleszczenia przedniego koła na uskoku przy próbie powrotu na asfalt
    final double stepNorm = (input.asphaltEdgeStepCm.clamp(0.0, 10.0) / 4.5).clamp(0.0, 1.6);
    final double wetEdgeBoost = input.isWetAsphalt ? 1.32 : 1.0;
    final double edgeCatchProbability =
        (runOffProbability * stepNorm * 0.48 * wetEdgeBoost * (1.15 - handlingNorm * 0.45))
            .clamp(0.0, 0.98);

    // Złożony indeks ryzyka 0–100
    final double severityMultiplier = 0.60 + input.shoulderType.baseHazardSeverity * 0.55;
    final double rawScore = ((runOffProbability * 48.0) +
            (echelonCollisionProbability * 28.0) +
            (edgeCatchProbability * 24.0)) *
        severityMultiplier;
    final double overallScore = rawScore.clamp(0.0, 100.0);

    // Koszt aerodynamiczny turbulencji na krawędzi peletonu
    final double turbulencePowerWatts =
        (0.5 * rho * 0.34 * math.pow(riderSpeed, 2) * (effectiveCrosswind * 0.12 + 0.35) * 0.65)
            .clamp(0.0, 145.0);

    // Szacowany spadek prędkości przy wjechaniu na pobocze
    final double offRoadResistanceDelta =
        (input.shoulderType.offRoadCrr - PhysicsConstants.crrStandardAsphalt) *
            input.totalMassKg *
            PhysicsConstants.gravity;
    final double offRoadSpeedDrop =
        (offRoadResistanceDelta / math.max(12.0, riderSpeed * 1.4)).clamp(0.3, 6.5);

    final GutterRiskLevel level = _classifyRiskLevel(overallScore);
    final bool shouldAbort =
        level == GutterRiskLevel.imminentRunOff ||
            level == GutterRiskLevel.criticalCrashRisk ||
            netClearance < -0.08;

    final String advisory = _buildTacticalAdvisory(
      level: level,
      netClearance: netClearance,
      shoulderType: input.shoulderType,
      shouldAbort: shouldAbort,
    );

    return GutterCollisionRiskResult(
      effectiveCrosswindMs: effectiveCrosswind,
      lateralAerodynamicForceN: lateralForceN,
      lateralSwayAmplitudeMeters: swayAmplitude,
      netClearanceMeters: netClearance,
      maneuverDurationSeconds: maneuverDuration,
      reactionMarginSeconds: reactionMargin,
      runOffProbability: runOffProbability,
      echelonCollisionProbability: echelonCollisionProbability,
      edgeCatchProbability: edgeCatchProbability,
      overallRiskScore: overallScore,
      gutterTurbulencePowerPenaltyWatts: turbulencePowerWatts,
      offRoadSpeedDropMs: offRoadSpeedDrop,
      riskLevel: level,
      shouldAbortOvertake: shouldAbort,
      tacticalAdvisory: advisory,
    );
  }

  /// Przeprowadza deterministyczną symulację czasową manewru wyprzedzania w rynsztoku.
  static GutterOvertakeSimulationResult simulateOvertakeManeuver(
    GutterCollisionRiskInput input, {
    int deterministicSeed = 42,
    double timeStepSeconds = 0.1,
  }) {
    final GutterCollisionRiskResult initialRisk = evaluateRisk(input);
    final double dt = timeStepSeconds.clamp(0.02, 0.25);
    final double deltaV = input.overtakeSpeedDeltaMs.clamp(0.1, 8.0);
    final double totalDist = input.overtakeDistanceMeters.clamp(2.0, 40.0);
    final double halfEnvelope = input.riderEnvelopeWidthMeters.clamp(0.45, 0.85) * 0.5;

    double corridor = math.max(0.05, input.availableGutterWidthMeters);
    // Pozycja boczna od krawędzi asfaltu (0.0 = krawędź asfaltu)
    double lateralPosFromEdge = corridor * 0.52;
    double progress = 0.0;
    double elapsed = 0.0;
    double minEdgeClearance = lateralPosFromEdge;
    double timeOffRoad = 0.0;
    double speedLoss = 0.0;

    final List<GutterManeuverStepSample> trajectory = <GutterManeuverStepSample>[];
    final math.Random rng = math.Random(deterministicSeed);

    bool clippedCurb = false;
    bool dominoCrash = false;
    bool washoutCrash = false;

    final double handlingNorm = (input.bikeHandlingSkill / 100.0).clamp(0.1, 1.0);
    final int maxSteps = ((totalDist / deltaV) / dt).ceil().clamp(5, 300);

    for (int step = 0; step <= maxSteps && progress < totalDist; step++) {
      // Kolarz w wachlarzu delikatnie zacieśnia lukę
      corridor = math.max(
        0.15,
        corridor - input.pelotonSqueezeRateMs.clamp(0.0, 0.6) * dt * 0.45,
      );

      // Poryw wiatru w luce między kołami (deterministyczna fala + szum)
      final double gustWave =
          math.sin(elapsed * 2.7 + (deterministicSeed % 7)) * 0.55 +
              (rng.nextDouble() - 0.35) * 0.65;
      final double instLateralForce =
          initialRisk.lateralAerodynamicForceN * (1.0 + gustWave * 0.32);

      // Równowaga między znoszeniem ku krawędzi a kontrowaniem kierownicą
      final double pushTowardEdge =
          (instLateralForce / math.max(50.0, input.totalMassKg)) * 0.045;
      final double riderCounterSteer =
          (lateralPosFromEdge < corridor * 0.40 ? 0.24 : 0.06) * handlingNorm;

      // Jeśli kolarz jest zbyt blisko sąsiada z wachlarza, odsuwa się w stronę rynsztoka
      final double distToEchelon = (corridor - lateralPosFromEdge) - halfEnvelope;
      final double echelonRepulsion = distToEchelon < 0.12 ? 0.35 : 0.0;

      final double lateralVelocity =
          (-pushTowardEdge + riderCounterSteer - echelonRepulsion) * dt;
      lateralPosFromEdge += lateralVelocity;

      final double wheelClearanceToEdge = lateralPosFromEdge - (halfEnvelope * 0.25);
      if (wheelClearanceToEdge < minEdgeClearance) {
        minEdgeClearance = wheelClearanceToEdge;
      }

      final bool isOffRoad = wheelClearanceToEdge < 0.0;
      if (isOffRoad) {
        timeOffRoad += dt;
        speedLoss = math.max(speedLoss, initialRisk.offRoadSpeedDropMs * 0.75);

        if (input.shoulderType == GutterShoulderType.raisedCurbOrGuardrail) {
          clippedCurb = true;
          // Odbicie od krawężnika z powrotem w peleton
          lateralPosFromEdge += 0.22;
          if (handlingNorm < 0.72 || initialRisk.echelonCollisionProbability > 0.68) {
            dominoCrash = true;
          }
        } else if (wheelClearanceToEdge < -0.18 &&
            (input.shoulderType == GutterShoulderType.wetGrassVerge ||
                input.shoulderType == GutterShoulderType.deepMuddyDitch ||
                (1.0 - input.shoulderType.lateralGripMu) *
                        (1.0 - handlingNorm * 0.6) >
                    0.42)) {
          washoutCrash = true;
        }
      }

      if (distToEchelon < -0.05 && initialRisk.echelonCollisionProbability > 0.72) {
        dominoCrash = true;
      }

      final double stepSpeedDelta =
          isOffRoad ? math.max(0.1, deltaV - speedLoss * 0.45) : deltaV;
      progress += stepSpeedDelta * dt;
      elapsed += dt;

      trajectory.add(
        GutterManeuverStepSample(
          timeSeconds: elapsed,
          longitudinalProgressMeters: progress.clamp(0.0, totalDist),
          distanceToRoadEdgeMeters: wheelClearanceToEdge,
          distanceToEchelonRiderMeters: distToEchelon,
          lateralForceN: instLateralForce,
          isOffRoad: isOffRoad,
        ),
      );

      if (dominoCrash || washoutCrash) {
        break;
      }
    }

    final GutterOvertakeOutcome outcome;
    if (dominoCrash) {
      outcome = GutterOvertakeOutcome.pelotonDominoCrash;
    } else if (washoutCrash) {
      outcome = GutterOvertakeOutcome.vergeWashoutCrash;
    } else if (clippedCurb) {
      outcome = GutterOvertakeOutcome.curbClipSwerve;
    } else if (timeOffRoad > 0.0) {
      outcome = GutterOvertakeOutcome.shoulderExcursionRecovered;
    } else if (initialRisk.shouldAbortOvertake && handlingNorm >= 0.78) {
      outcome = GutterOvertakeOutcome.abortedDropBack;
    } else {
      outcome = GutterOvertakeOutcome.cleanPass;
    }

    final double timeLost = switch (outcome) {
      GutterOvertakeOutcome.cleanPass => 0.0,
      GutterOvertakeOutcome.abortedDropBack => 2.4,
      GutterOvertakeOutcome.shoulderExcursionRecovered => 1.8 + timeOffRoad * 2.5,
      GutterOvertakeOutcome.curbClipSwerve => 6.5,
      GutterOvertakeOutcome.vergeWashoutCrash => 45.0,
      GutterOvertakeOutcome.pelotonDominoCrash => 60.0,
    };

    return GutterOvertakeSimulationResult(
      outcome: outcome,
      initialRisk: initialRisk,
      trajectory: trajectory,
      minEdgeClearanceMeters: minEdgeClearance,
      timeSpentOffRoadSeconds: timeOffRoad,
      netSpeedLossMs: speedLoss,
      estimatedTimeLostSeconds: timeLost,
    );
  }

  /// Oblicza minimalną bezpieczną szerokość korytarza w rynsztoku dla zadanych warunków.
  static double computeMinimumSafeCorridorMeters(GutterCollisionRiskInput input) {
    final GutterCollisionRiskResult eval = evaluateRisk(input);
    return (input.riderEnvelopeWidthMeters +
            eval.lateralSwayAmplitudeMeters +
            _minSafeMarginMeters)
        .clamp(0.65, 1.85);
  }

  static GutterRiskLevel _classifyRiskLevel(double score) {
    if (score < 22.0) {
      return GutterRiskLevel.safeClearance;
    }
    if (score < 42.0) {
      return GutterRiskLevel.tightSqueeze;
    }
    if (score < 62.0) {
      return GutterRiskLevel.highEdgeHazard;
    }
    if (score < 80.0) {
      return GutterRiskLevel.imminentRunOff;
    }
    return GutterRiskLevel.criticalCrashRisk;
  }

  static String _buildTacticalAdvisory({
    required GutterRiskLevel level,
    required double netClearance,
    required GutterShoulderType shoulderType,
    required bool shouldAbort,
  }) {
    if (shouldAbort) {
      return 'Przerwij wyprzedzanie w rynsztoku! Brak bezpiecznego zapasu '
          '(${(netClearance * 100).toStringAsFixed(0)} cm) przy ${shoulderType.labelPl.toLowerCase()}.';
    }
    return switch (level) {
      GutterRiskLevel.safeClearance =>
        'Bezpieczny korytarz (${(netClearance * 100).toStringAsFixed(0)} cm zapasu). '
            'Możesz płynnie przesunąć się na czoło wachlarza.',
      GutterRiskLevel.tightSqueeze =>
        'Ciasny przejazd w rynsztoku — utrzymaj stabilną linię i unikaj gwałtownych ruchów kierownicą.',
      GutterRiskLevel.highEdgeHazard =>
        'Uwaga na krawędź asfaltu (${shoulderType.labelPl})! Zwiększ docisk przedniego koła i pilnuj podmuchów.',
      GutterRiskLevel.imminentRunOff =>
        'Groźba zjechania na ${shoulderType.labelPl.toLowerCase()} — wycofaj się za koło.',
      GutterRiskLevel.criticalCrashRisk =>
        'Krytyczne ryzyko kraksy w wachlarzu! Natychmiast odpuść pedałowanie i zostań w szeregu.',
    };
  }
}

/// Interaktywny panel telemetryczno-symulacyjny ryzyka wyprzedzania w rynsztoku
/// na wietrze bocznym, dopasowany do rozdzielczości 390x844, 1024x768 i 1600x900.
class CrosswindPelotonGutterCollisionRiskPanel extends StatefulWidget {
  final GutterCollisionRiskInput initialInput;
  final ValueChanged<GutterOvertakeSimulationResult>? onSimulationCompleted;

  const CrosswindPelotonGutterCollisionRiskPanel({
    super.key,
    this.initialInput = const GutterCollisionRiskInput(
      availableGutterWidthMeters: 0.88,
      pelotonSpeedMs: 13.8,
      overtakeSpeedDeltaMs: 1.8,
      windSpeedMs: 11.5,
      windAngleDeg: 78.0,
      frontRimDepthMm: 60,
    ),
    this.onSimulationCompleted,
  });

  @override
  State<CrosswindPelotonGutterCollisionRiskPanel> createState() =>
      _CrosswindPelotonGutterCollisionRiskPanelState();
}

class _CrosswindPelotonGutterCollisionRiskPanelState
    extends State<CrosswindPelotonGutterCollisionRiskPanel> {
  late GutterCollisionRiskInput _input;
  late GutterOvertakeSimulationResult _simResult;
  bool _isSimulating = false;
  int _seedCounter = 42;

  @override
  void initState() {
    super.initState();
    _input = widget.initialInput;
    _simResult = CrosswindPelotonGutterCollisionRisk.simulateOvertakeManeuver(
      _input,
      deterministicSeed: _seedCounter,
    );
  }

  void _updateInput(GutterCollisionRiskInput updated) {
    setState(() {
      _input = updated;
      _simResult = CrosswindPelotonGutterCollisionRisk.simulateOvertakeManeuver(
        _input,
        deterministicSeed: _seedCounter,
      );
    });
  }

  Future<void> _runNewSimulation() async {
    if (_isSimulating) {
      return;
    }
    setState(() => _isSimulating = true);
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted) {
      return;
    }
    setState(() {
      _seedCounter += 1;
      _simResult = CrosswindPelotonGutterCollisionRisk.simulateOvertakeManeuver(
        _input,
        deterministicSeed: _seedCounter,
      );
      _isSimulating = false;
    });
    widget.onSimulationCompleted?.call(_simResult);
  }

  @override
  Widget build(BuildContext context) {
    final GutterCollisionRiskResult risk = _simResult.initialRisk;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isCompact = constraints.maxWidth < 640;
        final bool isWide = constraints.maxWidth >= 1100;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 1),
          ),
          padding: EdgeInsets.all(isCompact ? 14 : 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _buildHeader(risk, isCompact),
                const SizedBox(height: 16),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(flex: 5, child: _buildVisualizerAndMetrics(risk)),
                      const SizedBox(width: 20),
                      Expanded(flex: 4, child: _buildControlsPanel(risk)),
                    ],
                  )
                else ...<Widget>[
                  _buildVisualizerAndMetrics(risk),
                  const SizedBox(height: 16),
                  _buildControlsPanel(risk),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(GutterCollisionRiskResult risk, bool isCompact) {
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: risk.riskLevel.color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: risk.riskLevel.color.withValues(alpha: 0.5),
                ),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: risk.riskLevel.color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'RYZYKO WYPRZEDZANIA W RYNSZTOKU',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: isCompact ? 13 : 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Fizyka wiatru bocznego i zjazdu na pobocze',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: risk.riskLevel.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: risk.riskLevel.color.withValues(alpha: 0.6)),
          ),
          child: Text(
            '${risk.riskLevel.labelPl} • ${risk.overallRiskScore.toStringAsFixed(0)}/100',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              color: risk.riskLevel.color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVisualizerAndMetrics(GutterCollisionRiskResult risk) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          height: 170,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          clipBehavior: Clip.antiAlias,
          child: CustomPaint(
            painter: _GutterTrajectoryPainter(
              input: _input,
              simulation: _simResult,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            _MetricTile(
              label: 'Zapas netto',
              value: '${(risk.netClearanceMeters * 100).toStringAsFixed(0)} cm',
              accent: risk.netClearanceMeters >= 0.12
                  ? AppColors.statusSuccess
                  : AppColors.crimsonAlert,
            ),
            _MetricTile(
              label: 'Znoszenie boczne',
              value: '±${(risk.lateralSwayAmplitudeMeters * 100).toStringAsFixed(0)} cm',
              accent: AppColors.accentBlue,
            ),
            _MetricTile(
              label: 'Ryzyko pobocza',
              value: '${(risk.runOffProbability * 100).toStringAsFixed(0)}%',
              accent: risk.riskLevel.color,
            ),
            _MetricTile(
              label: 'Wynik manewru',
              value: _simResult.outcome.labelPl,
              accent: _simResult.outcome.color,
            ),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: risk.shouldAbortOvertake
                  ? AppColors.crimsonAlert.withValues(alpha: 0.5)
                  : AppColors.cardBorder,
            ),
          ),
          child: Text(
            risk.tacticalAdvisory,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              height: 1.4,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlsPanel(GutterCollisionRiskResult risk) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _SliderRow(
            label: 'Szerokość rynsztoka',
            valueLabel: '${(_input.availableGutterWidthMeters * 100).toStringAsFixed(0)} cm',
            value: _input.availableGutterWidthMeters,
            min: 0.45,
            max: 1.50,
            onChanged: (double v) =>
                _updateInput(_input.copyWith(availableGutterWidthMeters: v)),
          ),
          _SliderRow(
            label: 'Wiatr boczny',
            valueLabel: '${(_input.windSpeedMs * 3.6).toStringAsFixed(0)} km/h',
            value: _input.windSpeedMs,
            min: 0.0,
            max: 22.0,
            onChanged: (double v) => _updateInput(_input.copyWith(windSpeedMs: v)),
          ),
          _SliderRow(
            label: 'Prędkość wyprzedzania (Δv)',
            valueLabel: '+${(_input.overtakeSpeedDeltaMs * 3.6).toStringAsFixed(1)} km/h',
            value: _input.overtakeSpeedDeltaMs,
            min: 0.4,
            max: 5.0,
            onChanged: (double v) =>
                _updateInput(_input.copyWith(overtakeSpeedDeltaMs: v)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Typ pobocza',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: GutterShoulderType.values.map((GutterShoulderType type) {
              final bool selected = _input.shoulderType == type;
              return _InteractiveChip(
                label: type.labelPl,
                selected: selected,
                onTap: () => _updateInput(_input.copyWith(shoulderType: type)),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _InteractiveChip(
                  label: _input.isWetAsphalt ? 'Asfalt: Mokry' : 'Asfalt: Suchy',
                  selected: _input.isWetAsphalt,
                  onTap: () =>
                      _updateInput(_input.copyWith(isWetAsphalt: !_input.isWetAsphalt)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  label: _isSimulating ? 'Symulacja...' : 'Testuj manewr',
                  disabled: _isSimulating,
                  onPressed: _runNewSimulation,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 128),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              valueLabel,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.goldAccent,
            inactiveTrackColor: AppColors.cardBorder,
            thumbColor: AppColors.goldAccent,
            overlayColor: AppColors.goldAccent.withValues(alpha: 0.2),
            trackHeight: 3,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _InteractiveChip extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _InteractiveChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_InteractiveChip> createState() => _InteractiveChipState();
}

class _InteractiveChipState extends State<_InteractiveChip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color bg = widget.selected
        ? AppColors.primaryAccent.withValues(alpha: 0.35)
        : _pressed
            ? AppColors.cardBorder
            : _hovered
                ? AppColors.surface
                : AppColors.background;
    final Color border = widget.selected
        ? AppColors.goldAccent
        : _focused
            ? AppColors.accentBlue
            : AppColors.cardBorder;

    return FocusableActionDetector(
      onShowHoverHighlight: (bool v) => setState(() => _hovered = v),
      onShowFocusHighlight: (bool v) => setState(() => _focused = v),
      mouseCursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border),
          ),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
              color: widget.selected
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final String label;
  final bool disabled;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.disabled,
    required this.onPressed,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color bg = widget.disabled
        ? AppColors.cardBorder.withValues(alpha: 0.45)
        : _pressed
            ? AppColors.primaryAccent
            : _hovered
                ? AppColors.goldAccent
                : AppColors.primaryAccent;
    final Color border = _focused
        ? AppColors.accentBlue
        : widget.disabled
            ? AppColors.cardBorder
            : AppColors.goldAccent.withValues(alpha: 0.65);

    return FocusableActionDetector(
      enabled: !widget.disabled,
      onShowHoverHighlight: (bool v) => setState(() => _hovered = v),
      onShowFocusHighlight: (bool v) => setState(() => _focused = v),
      mouseCursor:
          widget.disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: widget.disabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: widget.disabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.disabled ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border),
          ),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: widget.disabled
                  ? AppColors.textSecondary
                  : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _GutterTrajectoryPainter extends CustomPainter {
  final GutterCollisionRiskInput input;
  final GutterOvertakeSimulationResult simulation;

  _GutterTrajectoryPainter({
    required this.input,
    required this.simulation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double vergeHeight = size.height * 0.24;
    final double asphaltBottom = size.height - vergeHeight;

    // Strefa pobocza
    final Paint vergePaint = Paint()
      ..color = input.shoulderType.baseHazardSeverity > 0.7
          ? AppColors.crimsonAlert.withValues(alpha: 0.16)
          : AppColors.amberWarning.withValues(alpha: 0.12);
    canvas.drawRect(
      Rect.fromLTWH(0, asphaltBottom, size.width, vergeHeight),
      vergePaint,
    );

    // Krawędź asfaltu (linia przerywana/ciągła)
    final Paint edgeLinePaint = Paint()
      ..color = AppColors.textPrimary.withValues(alpha: 0.65)
      ..strokeWidth = 2.0;
    canvas.drawLine(
      Offset(0, asphaltBottom),
      Offset(size.width, asphaltBottom),
      edgeLinePaint,
    );

    // Linia wachlarza u góry korytarza
    final double echelonY = size.height * 0.25;
    final Paint echelonPaint = Paint()
      ..color = AppColors.accentBlue.withValues(alpha: 0.45)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(0, echelonY), Offset(size.width, echelonY), echelonPaint);

    // Kolarze w wachlarzu
    final Paint riderDotPaint = Paint()..color = AppColors.accentBlue;
    for (int i = 0; i < 6; i++) {
      final double rx = size.width * (0.12 + i * 0.15);
      canvas.drawCircle(Offset(rx, echelonY - 8), 5.5, riderDotPaint);
    }

    // Trajektoria wyprzedzania w rynsztoku
    if (simulation.trajectory.isEmpty) {
      return;
    }

    final Path path = Path();
    final double totalDist = input.overtakeDistanceMeters.clamp(2.0, 40.0);
    final double corridorMeters = math.max(0.25, input.availableGutterWidthMeters);
    final double corridorPixels = asphaltBottom - echelonY;

    for (int i = 0; i < simulation.trajectory.length; i++) {
      final GutterManeuverStepSample sample = simulation.trajectory[i];
      final double x =
          (sample.longitudinalProgressMeters / totalDist).clamp(0.0, 1.0) *
              (size.width - 24) +
          12;
      final double normFromEdge =
          (sample.distanceToRoadEdgeMeters / corridorMeters).clamp(-0.35, 1.0);
      final double y = asphaltBottom - (normFromEdge * corridorPixels);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final Paint trajectoryPaint = Paint()
      ..color = simulation.outcome.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, trajectoryPaint);
  }

  @override
  bool shouldRepaint(covariant _GutterTrajectoryPainter oldDelegate) {
    return oldDelegate.input != input || oldDelegate.simulation != simulation;
  }
}
