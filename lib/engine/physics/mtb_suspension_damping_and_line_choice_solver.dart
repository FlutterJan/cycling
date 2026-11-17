// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import '../../core/constants/physics_constants.dart';
import '../../models/race/mtb_xco_course_and_suspension_model.dart';

/// Taktyka wyboru linii przejazdu na technicznych przeszkodach MTB XCO.
enum MtbLineTacticalPolicy {
  /// Agresywne wybieranie szybkiej linii A-Line, o ile ryzyko nie przekracza progu krytycznego.
  aggressiveALine('Aggressive A-Line', 'Agresywna linia A'),

  /// Optymalizacja wartości oczekiwanej czasu (Expected Value) z uwzględnieniem ryzyka kraksy.
  balancedExpectedValue('Balanced EV', 'Zbalansowana (EV)'),

  /// Bezpieczna jazda linią B-Line w celu ochrony przewagi lub uniknięcia defektu.
  conservativeBLine('Conservative B-Line', 'Bezpieczna linia B'),

  /// Wymuszona linia A-Line (np. atak lidera lub pościg na ostatnim okrążeniu).
  forcedALine('Forced A-Line', 'Wymuszona linia A'),

  /// Wymuszona linia B-Line (np. uszkodzone zawieszenie lub niskie ciśnienie w oponie).
  forcedBLine('Forced B-Line', 'Wymuszona linia B');

  final String labelEn;
  final String labelPl;

  const MtbLineTacticalPolicy(this.labelEn, this.labelPl);

  String toJson() => name;

  static MtbLineTacticalPolicy fromJson(String value) {
    return MtbLineTacticalPolicy.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => MtbLineTacticalPolicy.balancedExpectedValue,
    );
  }
}

/// Wynik pokonania pojedynczego segmentu MTB XCO.
enum MtbSegmentOutcome {
  cleanFastALine('Clean A-Line', 'Czysty, szybki przejazd linią A'),
  cleanSafeBLine('Clean B-Line', 'Bezpieczny przejazd linią B'),
  cleanSingleLine('Clean Single Line', 'Płynny przejazd sekcji'),
  footDabStumble('Foot-Dab Stumble', 'Podparcie nogą / utrata rytmu'),
  dropBottomOut('Suspension Bottom-Out', 'Dobite zawieszenie na lądowaniu'),
  pinchFlatPuncture('Pinch-Flat Snakebite', 'Dobite koło / przebicie opony 2.4"'),
  lineCrash('Technical Line Crash', 'Upadek na technicznej sekcji');

  final String labelEn;
  final String labelPl;

  const MtbSegmentOutcome(this.labelEn, this.labelPl);

  bool get isIncident =>
      this == footDabStumble ||
      this == dropBottomOut ||
      this == pinchFlatPuncture ||
      this == lineCrash;
}

/// Dane wejściowe do solvera fizyki zawieszenia, wyboru linii i przyczepności opon 2.4" MTB XCO.
class MtbSuspensionAndLineInput {
  final MtbXcoCourseSegment segment;
  final MtbXcoBikeConfiguration bikeConfig;
  final MtbTrailSoilCondition soilCondition;
  final double riderMassKg;
  final double powerWatts;
  final double approachSpeedMps;
  final double bikeHandling;
  final double descendingSkill;
  final double wPrimeRemainingRatio;
  final double altitudeMeters;
  final SuspensionLockoutMode? overrideLockoutMode;
  final DropperPostState? overrideDropperState;
  final MtbLineTacticalPolicy linePolicy;
  final bool isOutOfSaddle;
  final double? deterministicRoll;

  const MtbSuspensionAndLineInput({
    required this.segment,
    required this.bikeConfig,
    this.soilCondition = MtbTrailSoilCondition.tackyLoam,
    this.riderMassKg = 68.0,
    this.powerWatts = 350.0,
    this.approachSpeedMps = 6.2,
    this.bikeHandling = 82.0,
    this.descendingSkill = 80.0,
    this.wPrimeRemainingRatio = 0.85,
    this.altitudeMeters = 620.0,
    this.overrideLockoutMode,
    this.overrideDropperState,
    this.linePolicy = MtbLineTacticalPolicy.balancedExpectedValue,
    this.isOutOfSaddle = false,
    this.deterministicRoll,
  });
}

/// Ocena pojedynczego wariantu linii (A-Line lub B-Line) na segmencie XCO.
class MtbLineOptionEvaluation {
  final MtbTrailLineChoice lineChoice;
  final double effectiveLengthMeters;
  final double expectedSpeedMps;
  final double cleanTimeSeconds;
  final double adjustedCrashRisk;
  final double footDabRisk;
  final double bottomOutRisk;
  final double pinchFlatRisk;
  final double expectedTimeWithRiskSeconds;
  final bool meetsTravelRequirement;
  final bool meetsDropperRequirement;

  const MtbLineOptionEvaluation({
    required this.lineChoice,
    required this.effectiveLengthMeters,
    required this.expectedSpeedMps,
    required this.cleanTimeSeconds,
    required this.adjustedCrashRisk,
    required this.footDabRisk,
    required this.bottomOutRisk,
    required this.pinchFlatRisk,
    required this.expectedTimeWithRiskSeconds,
    required this.meetsTravelRequirement,
    required this.meetsDropperRequirement,
  });

  double get totalIncidentRisk =>
      (adjustedCrashRisk + footDabRisk + pinchFlatRisk).clamp(0.0, 0.95);
}

/// Szczegółowe wyniki fizyki zawieszenia i opon 2.4" dla segmentu XCO.
class MtbSuspensionDampingMetrics {
  final SuspensionLockoutMode activeLockoutMode;
  final DropperPostState activeDropperState;
  final double dampingAbsorptionRatio;
  final double reboundTuningScore;
  final double sagMatchScore;
  final double pedalBobLossWatts;
  final double unabsorbedChatterWatts;
  final double effectiveRollingCrr;
  final double rollingResistanceWatts;
  final double tire24GripMu;
  final double climbTractionLimitRatio;
  final double wheelspinPowerLossWatts;
  final double maxCorneringSpeedMps;
  final double vibrationFatigueIndex;

  const MtbSuspensionDampingMetrics({
    required this.activeLockoutMode,
    required this.activeDropperState,
    required this.dampingAbsorptionRatio,
    required this.reboundTuningScore,
    required this.sagMatchScore,
    required this.pedalBobLossWatts,
    required this.unabsorbedChatterWatts,
    required this.effectiveRollingCrr,
    required this.rollingResistanceWatts,
    required this.tire24GripMu,
    required this.climbTractionLimitRatio,
    required this.wheelspinPowerLossWatts,
    required this.maxCorneringSpeedMps,
    required this.vibrationFatigueIndex,
  });
}

/// Kompletny wynik analizy i symulacji segmentu MTB XCO.
class MtbSuspensionAndLineResult {
  final int segmentIndex;
  final String segmentName;
  final MtbTrailLineChoice chosenLine;
  final MtbSegmentOutcome outcome;
  final MtbSuspensionDampingMetrics dampingMetrics;
  final MtbLineOptionEvaluation? aLineEvaluation;
  final MtbLineOptionEvaluation? bLineEvaluation;
  final double exitSpeedMps;
  final double segmentTimeSeconds;
  final double timeAdvantageOverBLineSeconds;
  final double netEffectivePowerWatts;
  final double incidentTimePenaltySeconds;
  final String decisionReasonPl;

  const MtbSuspensionAndLineResult({
    required this.segmentIndex,
    required this.segmentName,
    required this.chosenLine,
    required this.outcome,
    required this.dampingMetrics,
    this.aLineEvaluation,
    this.bLineEvaluation,
    required this.exitSpeedMps,
    required this.segmentTimeSeconds,
    required this.timeAdvantageOverBLineSeconds,
    required this.netEffectivePowerWatts,
    required this.incidentTimePenaltySeconds,
    required this.decisionReasonPl,
  });
}

/// Zbiorcze podsumowanie fizyki pełnej rundy MTB XCO (np. 4.2 km).
class MtbXcoLapPhysicsSummary {
  final String courseId;
  final double totalLapTimeSeconds;
  final double totalDistanceMeters;
  final int aLinesTaken;
  final int bLinesTaken;
  final double totalPedalBobEnergyKj;
  final double totalChatterEnergyKj;
  final double totalWheelspinEnergyKj;
  final double averageTireGripMu;
  final double averageDampingAbsorption;
  final double cumulativeIncidentProbability;
  final double timeSavedByALinesSeconds;
  final List<MtbSuspensionAndLineResult> segmentResults;

  const MtbXcoLapPhysicsSummary({
    required this.courseId,
    required this.totalLapTimeSeconds,
    required this.totalDistanceMeters,
    required this.aLinesTaken,
    required this.bLinesTaken,
    required this.totalPedalBobEnergyKj,
    required this.totalChatterEnergyKj,
    required this.totalWheelspinEnergyKj,
    required this.averageTireGripMu,
    required this.averageDampingAbsorption,
    required this.cumulativeIncidentProbability,
    required this.timeSavedByALinesSeconds,
    required this.segmentResults,
  });
}

/// Rekomendacja optymalnego ciśnienia zawieszenia, tłumienia powrotu i opon 2.4".
class MtbOptimalSetupRecommendation {
  final double recommendedForkPsi;
  final double recommendedRearShockPsi;
  final int recommendedForkReboundClicks;
  final int recommendedRearReboundClicks;
  final double recommendedFrontTireBar;
  final double recommendedRearTireBar;
  final MtbTireTreadPattern recommendedTreadPattern;
  final int recommendedTravelMm;

  const MtbOptimalSetupRecommendation({
    required this.recommendedForkPsi,
    required this.recommendedRearShockPsi,
    required this.recommendedForkReboundClicks,
    required this.recommendedRearReboundClicks,
    required this.recommendedFrontTireBar,
    required this.recommendedRearTireBar,
    required this.recommendedTreadPattern,
    required this.recommendedTravelMm,
  });
}

/// Solver fizyki MTB XCO obliczający tłumienie nierówności przez zawieszenie,
/// wybór linii przejazdu (`A-Line` vs `B-Line`) oraz przyczepność opon 2.4".
class MtbSuspensionDampingAndLineChoiceSolver {
  MtbSuspensionDampingAndLineChoiceSolver._();

  static const double _mtbCdaBase = 0.44;
  static const double _crashPenaltySeconds = 11.5;
  static const double _pinchFlatPenaltySeconds = 22.0;
  static const double _bottomOutPenaltySeconds = 2.4;
  static const double _footDabPenaltySeconds = 3.2;

  /// Oblicza zoptymalizowane ustawienia zawieszenia i opon 2.4" pod trasę, warunki i wagę kolarza.
  static MtbOptimalSetupRecommendation recommendOptimalSetup({
    required MtbXcoCourseAndSuspensionModel course,
    required double riderMassKg,
  }) {
    final safeMass = riderMassKg.clamp(45.0, 110.0);
    final forkPsi = MtbForkAndShockSetup.computeRecommendedForkPsi(safeMass);
    final rearPsi = MtbForkAndShockSetup.computeRecommendedRearPsi(safeMass);

    // Szybkość odbicia (rebound clicks: 1 = najwolniejsze, 16 = najszybsze).
    // Wyższe ciśnienie (cięższy kolarz) i większe korzenie/kamienie wymagają szybszego powrotu.
    final roughness = course.averageRoughnessIndex;
    final baseRebound = 7 + ((safeMass - 65.0) * 0.08).round();
    final terrainReboundDelta = roughness >= 0.6 ? 2 : (roughness <= 0.25 ? -1 : 0);
    final forkRebound = (baseRebound + terrainReboundDelta).clamp(4, 14);
    final rearRebound = (baseRebound + terrainReboundDelta - 1).clamp(4, 14);

    // Optymalne ciśnienie opon 2.4" zależne od wagi i podłoża [bar]
    final baseTireBar = 1.02 + (safeMass / 210.0);
    final soilPressureOffset = switch (course.soilCondition) {
      MtbTrailSoilCondition.dryHardpack => 0.08,
      MtbTrailSoilCondition.looseDust => -0.05,
      MtbTrailSoilCondition.tackyLoam => 0.0,
      MtbTrailSoilCondition.wetRootsAndRock => -0.08,
      MtbTrailSoilCondition.muddyRut => -0.10,
    };
    final frontBar = double.parse(
      (baseTireBar + soilPressureOffset - 0.04).clamp(1.05, 1.85).toStringAsFixed(2),
    );
    final rearBar = double.parse(
      (baseTireBar + soilPressureOffset + 0.06).clamp(1.12, 1.95).toStringAsFixed(2),
    );

    final tread = switch (course.soilCondition) {
      MtbTrailSoilCondition.dryHardpack => MtbTireTreadPattern.fastSemiSlick,
      MtbTrailSoilCondition.looseDust ||
      MtbTrailSoilCondition.tackyLoam =>
        MtbTireTreadPattern.allRoundXcKnob,
      MtbTrailSoilCondition.wetRootsAndRock ||
      MtbTrailSoilCondition.muddyRut =>
        MtbTireTreadPattern.aggressiveMudSpike,
    };

    return MtbOptimalSetupRecommendation(
      recommendedForkPsi: forkPsi,
      recommendedRearShockPsi: rearPsi,
      recommendedForkReboundClicks: forkRebound,
      recommendedRearReboundClicks: rearRebound,
      recommendedFrontTireBar: frontBar,
      recommendedRearTireBar: rearBar,
      recommendedTreadPattern: tread,
      recommendedTravelMm: course.recommendedTravelMm,
    );
  }

  /// Oblicza fizykę zawieszenia, przyczepność opon 2.4" oraz decyzję A-Line vs B-Line dla jednego segmentu.
  static MtbSuspensionAndLineResult solveSegment(
    MtbSuspensionAndLineInput input,
  ) {
    final segment = input.segment;
    final bike = input.bikeConfig;
    final suspension = bike.suspension;
    final tire = bike.tireSetup;
    final dropper = bike.dropperPost;

    final safeMassKg = input.riderMassKg.clamp(45.0, 120.0);
    final totalMassKg = safeMassKg + bike.totalWeightKg.clamp(7.5, 14.0);
    final safeSpeedMps = input.approachSpeedMps.clamp(1.2, 22.0);
    final safePower = input.powerWatts.clamp(40.0, 1600.0);

    // 1. Aktywny tryb blokady i sztycy (Flight Attendant automatycznie dobiera tryb do segmentu)
    final activeLockout = input.overrideLockoutMode ??
        (suspension.hasElectronicFlightAttendant
            ? segment.recommendedLockout
            : suspension.remoteLockoutMode);

    final activeDropper = input.overrideDropperState ??
        (dropper.isWirelessElectronic
            ? segment.recommendedDropper
            : dropper.currentState);

    // 2. Ocena tłumienia zawieszenia: SAG, Rebound, Skok, Lockout
    final sagMatchScore = _computeSagMatchScore(suspension, safeMassKg);
    final reboundTuningScore = _computeReboundTuningScore(
      suspension,
      segment.roughnessIndex,
      safeSpeedMps,
    );
    final effectiveSetupSuspension = suspension.copyWith(
      remoteLockoutMode: activeLockout,
    );
    final baseDamping =
        effectiveSetupSuspension.dampingQualityScore(segment.roughnessIndex);
    final dampingAbsorptionRatio = (baseDamping *
            (0.84 + 0.16 * reboundTuningScore) *
            (0.86 + 0.14 * sagMatchScore))
        .clamp(0.10, 1.0);

    // 3. Straty na bujanie (Pedal Bob) podczas pedałowania
    final pedalBobMultiplier = _computePedalBobMultiplier(
      segment: segment,
      isOutOfSaddle: input.isOutOfSaddle,
      architecture: suspension.architecture,
      hasFlightAttendant: suspension.hasElectronicFlightAttendant,
    );
    final pedalBobLossWatts = safePower *
        activeLockout.pedalBobLossFactor *
        pedalBobMultiplier;

    // 4. Straty energii kinetycznej przez nietłumione drgania (Chatter / Impedancja zawieszenia)
    final unabsorbedRoughness =
        (segment.roughnessIndex * (1.0 - dampingAbsorptionRatio)).clamp(0.0, 1.0);
    final rockFactor = 1.0 + (segment.rockSizeCm.clamp(0.0, 60.0) / 50.0);
    final rootFactor = 1.0 + (segment.rootDensityPerMeter.clamp(0.0, 5.0) * 0.14);
    final unabsorbedChatterWatts = (0.38 *
            totalMassKg *
            math.pow(safeSpeedMps, 1.55) *
            unabsorbedRoughness *
            rockFactor *
            rootFactor *
            0.16)
        .clamp(0.0, 260.0);

    // 5. Fizyka opon 2.4": przyczepność mu_eff, opory toczenia CRR, poślizg na stromych podjazdach, zakręty
    final tire24GripMu = _computeEffectiveTireGripMu(
      tire: tire,
      soil: input.soilCondition,
      riderMassKg: safeMassKg,
      dampingAbsorptionRatio: dampingAbsorptionRatio,
    );
    final effectiveRollingCrr = tire.rollingResistanceCrr(input.soilCondition);
    final slopeRad = math.atan(segment.gradientPercent / 100.0);
    final normalForce = totalMassKg * PhysicsConstants.gravity * math.cos(slopeRad);
    final rollingResistanceWatts = effectiveRollingCrr * normalForce * safeSpeedMps;

    // Trakcja tylnego koła na stromym podjeździe (poślizg koła przy niskiej przyczepności)
    final climbTractionResult = _computeClimbTractionAndWheelspin(
      segment: segment,
      powerWatts: safePower - pedalBobLossWatts,
      speedMps: safeSpeedMps,
      normalForceN: normalForce,
      tireGripMu: tire24GripMu,
      rearPressureBar: tire.rearPressureBar,
      isOutOfSaddle: input.isOutOfSaddle,
    );

    // Maksymalna prędkość w zakręcie / bandzie (v_max = sqrt(mu * g * R))
    final cornerRadiusMeters = switch (segment.featureType) {
      MtbXcoFeatureType.bermSwitchback => 6.8,
      MtbXcoFeatureType.rootSection || MtbXcoFeatureType.rockGarden => 11.5,
      MtbXcoFeatureType.woodBridge => 14.0,
      _ => 22.0,
    };
    final bermBankingBonus =
        segment.featureType == MtbXcoFeatureType.bermSwitchback ? 1.24 : 1.0;
    final maxCorneringSpeedMps = math.sqrt(
      (tire24GripMu * bermBankingBonus).clamp(0.25, 1.65) *
          PhysicsConstants.gravity *
          cornerRadiusMeters,
    );

    final vibrationFatigueIndex = (unabsorbedRoughness *
            (1.0 + segment.rootDensityPerMeter * 0.12) *
            (safeSpeedMps / 7.0))
        .clamp(0.0, 1.0);

    final dampingMetrics = MtbSuspensionDampingMetrics(
      activeLockoutMode: activeLockout,
      activeDropperState: activeDropper,
      dampingAbsorptionRatio: dampingAbsorptionRatio,
      reboundTuningScore: reboundTuningScore,
      sagMatchScore: sagMatchScore,
      pedalBobLossWatts: pedalBobLossWatts,
      unabsorbedChatterWatts: unabsorbedChatterWatts,
      effectiveRollingCrr: effectiveRollingCrr,
      rollingResistanceWatts: rollingResistanceWatts,
      tire24GripMu: tire24GripMu,
      climbTractionLimitRatio: climbTractionResult.tractionRatio,
      wheelspinPowerLossWatts: climbTractionResult.wheelspinLossWatts,
      maxCorneringSpeedMps: maxCorneringSpeedMps,
      vibrationFatigueIndex: vibrationFatigueIndex,
    );

    // 6. Obliczenie prędkości bazowej na segmencie z bilansu mocy
    final netEffectivePower = math.max(
      10.0,
      safePower -
          pedalBobLossWatts -
          unabsorbedChatterWatts -
          climbTractionResult.wheelspinLossWatts,
    );

    final baseSegmentSpeedMps = _solveSteadySpeedMps(
      netPowerWatts: netEffectivePower,
      totalMassKg: totalMassKg,
      gradientPercent: segment.gradientPercent,
      effectiveCrr: effectiveRollingCrr,
      altitudeMeters: input.altitudeMeters,
      approachSpeedMps: safeSpeedMps,
      maxCorneringSpeedMps: maxCorneringSpeedMps,
      segment: segment,
    );

    // 7. Analiza wyboru linii przejazdu: A-Line vs B-Line
    if (segment.hasLineSplit) {
      final aEval = _evaluateLineOption(
        option: segment.aLine!,
        segment: segment,
        input: input,
        baseSpeedMps: baseSegmentSpeedMps,
        dampingMetrics: dampingMetrics,
        activeDropper: activeDropper,
      );
      final bEval = _evaluateLineOption(
        option: segment.bLine!,
        segment: segment,
        input: input,
        baseSpeedMps: baseSegmentSpeedMps,
        dampingMetrics: dampingMetrics,
        activeDropper: activeDropper,
      );

      final chosen = _selectLine(
        policy: input.linePolicy,
        aEval: aEval,
        bEval: bEval,
      );
      final selectedEval = chosen == MtbTrailLineChoice.aLine ? aEval : bEval;

      final outcomeResolution = _resolveSegmentOutcome(
        chosenLine: chosen,
        evaluation: selectedEval,
        hasSplit: true,
        climbWheelspinRatio: climbTractionResult.tractionRatio,
        deterministicRoll: input.deterministicRoll,
      );

      final totalTimeSeconds =
          selectedEval.cleanTimeSeconds + outcomeResolution.penaltySeconds;
      final effectiveExitSpeed = outcomeResolution.penaltySeconds > 0.0
          ? (selectedEval.expectedSpeedMps * 0.68).clamp(1.8, 22.0)
          : selectedEval.expectedSpeedMps;

      final advantageOverB = bEval.cleanTimeSeconds - totalTimeSeconds;

      return MtbSuspensionAndLineResult(
        segmentIndex: segment.index,
        segmentName: segment.name,
        chosenLine: chosen,
        outcome: outcomeResolution.outcome,
        dampingMetrics: dampingMetrics,
        aLineEvaluation: aEval,
        bLineEvaluation: bEval,
        exitSpeedMps: effectiveExitSpeed,
        segmentTimeSeconds: totalTimeSeconds,
        timeAdvantageOverBLineSeconds: advantageOverB,
        netEffectivePowerWatts: netEffectivePower,
        incidentTimePenaltySeconds: outcomeResolution.penaltySeconds,
        decisionReasonPl: _buildDecisionReasonPl(
          chosen: chosen,
          aEval: aEval,
          bEval: bEval,
          policy: input.linePolicy,
          outcome: outcomeResolution.outcome,
        ),
      );
    }

    // Segment bez rozwidlenia (Single Line)
    final safeLength = math.max(1.0, segment.lengthMeters);
    final singleLineEval = _evaluateLineOption(
      option: MtbXcoLineOption(
        lineChoice: MtbTrailLineChoice.bLine,
        lengthMeters: safeLength,
        dropHeightMeters: segment.dropHeightMeters,
        technicalDifficulty: (segment.roughnessIndex * 8.0).clamp(1.0, 9.0),
        timeAdvantageSeconds: 0.0,
        crashRiskBase: (segment.roughnessIndex * 0.035).clamp(0.002, 0.06),
        minSuspensionTravelMm: 100,
        requiresDropperPost: segment.isTechnicalDescent,
      ),
      segment: segment,
      input: input,
      baseSpeedMps: baseSegmentSpeedMps,
      dampingMetrics: dampingMetrics,
      activeDropper: activeDropper,
    );

    final outcomeResolution = _resolveSegmentOutcome(
      chosenLine: MtbTrailLineChoice.bLine,
      evaluation: singleLineEval,
      hasSplit: false,
      climbWheelspinRatio: climbTractionResult.tractionRatio,
      deterministicRoll: input.deterministicRoll,
    );

    final totalTimeSeconds =
        singleLineEval.cleanTimeSeconds + outcomeResolution.penaltySeconds;
    final exitSpeed = outcomeResolution.penaltySeconds > 0.0
        ? (singleLineEval.expectedSpeedMps * 0.72).clamp(1.8, 22.0)
        : singleLineEval.expectedSpeedMps;

    return MtbSuspensionAndLineResult(
      segmentIndex: segment.index,
      segmentName: segment.name,
      chosenLine: MtbTrailLineChoice.bLine,
      outcome: outcomeResolution.outcome,
      dampingMetrics: dampingMetrics,
      aLineEvaluation: null,
      bLineEvaluation: singleLineEval,
      exitSpeedMps: exitSpeed,
      segmentTimeSeconds: totalTimeSeconds,
      timeAdvantageOverBLineSeconds: 0.0,
      netEffectivePowerWatts: netEffectivePower,
      incidentTimePenaltySeconds: outcomeResolution.penaltySeconds,
      decisionReasonPl: outcomeResolution.outcome.isIncident
          ? '${outcomeResolution.outcome.labelPl} na sekcji ${segment.name}.'
          : 'Płynny przejazd sekcji ${segment.name}.',
    );
  }

  /// Symuluje pełną rundę MTB XCO segment po segmencie i zwraca zagregowaną telemetrię.
  static MtbXcoLapPhysicsSummary simulateLap({
    required MtbXcoCourseAndSuspensionModel course,
    required MtbXcoBikeConfiguration bikeConfig,
    double riderMassKg = 68.0,
    double basePowerWatts = 345.0,
    double bikeHandling = 82.0,
    double descendingSkill = 80.0,
    double wPrimeRemainingRatio = 0.85,
    MtbLineTacticalPolicy linePolicy =
        MtbLineTacticalPolicy.balancedExpectedValue,
    double? deterministicRoll,
  }) {
    if (course.segments.isEmpty) {
      return MtbXcoLapPhysicsSummary(
        courseId: course.courseId,
        totalLapTimeSeconds: course.lapDistanceKm * 185.0,
        totalDistanceMeters: course.lapDistanceKm * 1000.0,
        aLinesTaken: 0,
        bLinesTaken: 0,
        totalPedalBobEnergyKj: 0.0,
        totalChatterEnergyKj: 0.0,
        totalWheelspinEnergyKj: 0.0,
        averageTireGripMu: bikeConfig.tireSetup.gripScore(course.soilCondition),
        averageDampingAbsorption: 0.85,
        cumulativeIncidentProbability: 0.02,
        timeSavedByALinesSeconds: 0.0,
        segmentResults: const [],
      );
    }

    final results = <MtbSuspensionAndLineResult>[];
    double currentSpeedMps = 6.5;
    double totalTimeSeconds = 0.0;
    double totalDistanceMeters = 0.0;
    int aLinesTaken = 0;
    int bLinesTaken = 0;
    double pedalBobKj = 0.0;
    double chatterKj = 0.0;
    double wheelspinKj = 0.0;
    double gripWeighted = 0.0;
    double dampingWeighted = 0.0;
    double noIncidentProb = 1.0;
    double timeSavedByA = 0.0;

    for (final seg in course.segments) {
      // Kolarz generuje wyższą moc na stromych podjazdach interwałowych (115% bazowej)
      final segmentPower = seg.gradientPercent > 6.0
          ? basePowerWatts * 1.15
          : (seg.gradientPercent < -4.0
              ? basePowerWatts * 0.45
              : basePowerWatts);

      final result = solveSegment(
        MtbSuspensionAndLineInput(
          segment: seg,
          bikeConfig: bikeConfig,
          soilCondition: course.soilCondition,
          riderMassKg: riderMassKg,
          powerWatts: segmentPower,
          approachSpeedMps: currentSpeedMps,
          bikeHandling: bikeHandling,
          descendingSkill: descendingSkill,
          wPrimeRemainingRatio: wPrimeRemainingRatio,
          altitudeMeters: course.altitudeMeters,
          linePolicy: linePolicy,
          isOutOfSaddle: seg.gradientPercent >= 10.0,
          deterministicRoll: deterministicRoll,
        ),
      );

      results.add(result);
      currentSpeedMps = result.exitSpeedMps;
      totalTimeSeconds += result.segmentTimeSeconds;
      totalDistanceMeters += seg.lengthMeters;

      if (seg.hasLineSplit) {
        if (result.chosenLine == MtbTrailLineChoice.aLine) {
          aLinesTaken++;
          timeSavedByA += math.max(0.0, result.timeAdvantageOverBLineSeconds);
        } else {
          bLinesTaken++;
        }
      }

      pedalBobKj +=
          (result.dampingMetrics.pedalBobLossWatts * result.segmentTimeSeconds) /
              1000.0;
      chatterKj += (result.dampingMetrics.unabsorbedChatterWatts *
              result.segmentTimeSeconds) /
          1000.0;
      wheelspinKj += (result.dampingMetrics.wheelspinPowerLossWatts *
              result.segmentTimeSeconds) /
          1000.0;

      gripWeighted += result.dampingMetrics.tire24GripMu * seg.lengthMeters;
      dampingWeighted +=
          result.dampingMetrics.dampingAbsorptionRatio * seg.lengthMeters;

      final chosenEval = result.chosenLine == MtbTrailLineChoice.aLine
          ? result.aLineEvaluation
          : result.bLineEvaluation;
      if (chosenEval != null) {
        noIncidentProb *= (1.0 - chosenEval.totalIncidentRisk).clamp(0.05, 1.0);
      }
    }

    final safeDist = math.max(1.0, totalDistanceMeters);
    return MtbXcoLapPhysicsSummary(
      courseId: course.courseId,
      totalLapTimeSeconds: totalTimeSeconds,
      totalDistanceMeters: totalDistanceMeters,
      aLinesTaken: aLinesTaken,
      bLinesTaken: bLinesTaken,
      totalPedalBobEnergyKj: pedalBobKj,
      totalChatterEnergyKj: chatterKj,
      totalWheelspinEnergyKj: wheelspinKj,
      averageTireGripMu: gripWeighted / safeDist,
      averageDampingAbsorption: dampingWeighted / safeDist,
      cumulativeIncidentProbability: (1.0 - noIncidentProb).clamp(0.0, 0.99),
      timeSavedByALinesSeconds: timeSavedByA,
      segmentResults: results,
    );
  }

  static double _computeSagMatchScore(
    MtbForkAndShockSetup setup,
    double riderMassKg,
  ) {
    final recForkPsi = MtbForkAndShockSetup.computeRecommendedForkPsi(riderMassKg);
    final forkPsiError =
        ((setup.forkAirPressurePsi - recForkPsi).abs() / recForkPsi)
            .clamp(0.0, 0.6);
    final forkSagError = ((setup.forkSagPercent - 18.0).abs() / 15.0).clamp(0.0, 1.0);

    double rearScore = 1.0;
    if (setup.rearShockTravelMm > 0) {
      final recRearPsi =
          MtbForkAndShockSetup.computeRecommendedRearPsi(riderMassKg);
      final rearPsiError =
          ((setup.rearShockAirPressurePsi - recRearPsi).abs() / recRearPsi)
              .clamp(0.0, 0.6);
      final rearSagError =
          ((setup.rearShockSagPercent - 24.0).abs() / 15.0).clamp(0.0, 1.0);
      rearScore = (1.0 - (rearPsiError * 0.5 + rearSagError * 0.5)).clamp(0.3, 1.0);
    }

    final forkScore =
        (1.0 - (forkPsiError * 0.5 + forkSagError * 0.5)).clamp(0.3, 1.0);
    return ((forkScore + rearScore) * 0.5).clamp(0.30, 1.0);
  }

  static double _computeReboundTuningScore(
    MtbForkAndShockSetup setup,
    double roughnessIndex,
    double speedMps,
  ) {
    // Zbyt wolny powrót (niskie kliknięcia) powoduje "packing up" na szybkich seriach korzeni/kamieni
    final idealForkClicks = (7.5 + roughnessIndex * 3.0 + (speedMps > 8.0 ? 1.0 : 0.0))
        .clamp(4.0, 14.0);
    final forkDiff = (setup.forkReboundClicks - idealForkClicks).abs();
    final forkScore = (1.0 - forkDiff * 0.075).clamp(0.45, 1.0);

    if (setup.rearShockTravelMm <= 0) {
      return forkScore;
    }
    final idealRearClicks = (idealForkClicks - 1.0).clamp(4.0, 13.0);
    final rearDiff = (setup.rearReboundClicks - idealRearClicks).abs();
    final rearScore = (1.0 - rearDiff * 0.075).clamp(0.45, 1.0);
    return ((forkScore + rearScore) * 0.5).clamp(0.45, 1.0);
  }

  static double _computePedalBobMultiplier({
    required MtbXcoCourseSegment segment,
    required bool isOutOfSaddle,
    required MtbSuspensionArchitecture architecture,
    required bool hasFlightAttendant,
  }) {
    if (segment.gradientPercent <= -3.0) {
      return 0.25; // Zjazd — mało pedałowania, brak strat bujania
    }
    double mult = 1.0;
    if (segment.gradientPercent >= 8.0) {
      mult *= 1.35;
    }
    if (isOutOfSaddle) {
      mult *= 1.55;
    }
    if (architecture == MtbSuspensionArchitecture.hardtail) {
      mult *= 0.22; // Sztywny tył nie pompuje
    }
    if (hasFlightAttendant) {
      mult *= 0.45; // Elektroniczna kompresja minimalizuje bujanie między uderzeniami
    }
    return mult;
  }

  static double _computeEffectiveTireGripMu({
    required MtbTire24Setup tire,
    required MtbTrailSoilCondition soil,
    required double riderMassKg,
    required double dampingAbsorptionRatio,
  }) {
    final baseGrip = tire.gripScore(soil);
    // Zbyt wysokie ciśnienie (>1.75 bar) zmniejsza powierzchnię styku klocków 2.4"
    final avgBar = (tire.frontPressureBar + tire.rearPressureBar) * 0.5;
    final optimalBar = 1.05 + (riderMassKg / 210.0);
    final overPressurePenalty =
        ((avgBar - (optimalBar + 0.15)).clamp(0.0, 0.8)) * 0.22;
    // Lepszy oplot (120 TPI vs 60 TPI) lepiej układa się na korzeniach
    final casingBonus = ((tire.casingTpi - 60) / 600.0).clamp(0.0, 0.08);
    // Dobre tłumienie zawieszenia utrzymuje koło w kontakcie z podłożem
    final contactPatchFactor = 0.82 + 0.18 * dampingAbsorptionRatio;

    return ((baseGrip - overPressurePenalty + casingBonus) * contactPatchFactor)
        .clamp(0.28, 1.30);
  }

  static ({double tractionRatio, double wheelspinLossWatts})
      _computeClimbTractionAndWheelspin({
    required MtbXcoCourseSegment segment,
    required double powerWatts,
    required double speedMps,
    required double normalForceN,
    required double tireGripMu,
    required double rearPressureBar,
    required bool isOutOfSaddle,
  }) {
    if (segment.gradientPercent <= 3.0) {
      return (tractionRatio: 0.2, wheelspinLossWatts: 0.0);
    }
    final safeSpeed = math.max(1.5, speedMps);
    final tangentialDriveForceN = powerWatts / safeSpeed;
    // Na siedząco ~65% masy spoczywa na tylnym kole; na stojąco spada do ~46%
    final rearWeightShare = isOutOfSaddle ? 0.46 : 0.65;
    final pressureTractionMod =
        rearPressureBar > 1.65 ? 0.90 : (rearPressureBar <= 1.40 ? 1.05 : 1.0);
    final maxRearTractionN =
        normalForceN * rearWeightShare * tireGripMu * pressureTractionMod;

    final ratio =
        (tangentialDriveForceN / math.max(10.0, maxRearTractionN)).clamp(0.0, 2.0);
    if (ratio <= 0.92) {
      return (tractionRatio: ratio, wheelspinLossWatts: 0.0);
    }
    final slipExcess = (ratio - 0.92).clamp(0.0, 0.8);
    final wheelspinWatts = (powerWatts * slipExcess * 0.35).clamp(0.0, powerWatts * 0.4);
    return (tractionRatio: ratio, wheelspinLossWatts: wheelspinWatts);
  }

  static double _solveSteadySpeedMps({
    required double netPowerWatts,
    required double totalMassKg,
    required double gradientPercent,
    required double effectiveCrr,
    required double altitudeMeters,
    required double approachSpeedMps,
    required double maxCorneringSpeedMps,
    required MtbXcoCourseSegment segment,
  }) {
    final slopeRad = math.atan(gradientPercent / 100.0);
    final gravityForce = totalMassKg * PhysicsConstants.gravity * math.sin(slopeRad);
    final rollingForce =
        effectiveCrr * totalMassKg * PhysicsConstants.gravity * math.cos(slopeRad);
    final rho = PhysicsConstants.getAirDensityAtAltitude(altitudeMeters);
    final aeroDragCoeff = 0.5 * rho * _mtbCdaBase;

    // Bisekcja dla P = (F_grav + F_roll + k_aero * v^2) * v na podjazdach i płaskim
    double low = 1.4;
    double high = 20.0;
    for (int i = 0; i < 18; i++) {
      final mid = (low + high) * 0.5;
      final requiredPower =
          (gravityForce + rollingForce + aeroDragCoeff * mid * mid) * mid;
      if (requiredPower > netPowerWatts) {
        high = mid;
      } else {
        low = mid;
      }
    }
    final steadySpeed = (low + high) * 0.5;
    // Wygładzenie z prędkością wejściową oraz ograniczeniem prędkości w zakrętach
    final blendedSpeed = (approachSpeedMps * 0.30 + steadySpeed * 0.70);
    final cappedByCorner =
        segment.featureType == MtbXcoFeatureType.bermSwitchback ||
                segment.featureType == MtbXcoFeatureType.rootSection
            ? math.min(blendedSpeed, maxCorneringSpeedMps)
            : blendedSpeed;
    return cappedByCorner.clamp(1.6, 18.5);
  }

  static MtbLineOptionEvaluation _evaluateLineOption({
    required MtbXcoLineOption option,
    required MtbXcoCourseSegment segment,
    required MtbSuspensionAndLineInput input,
    required double baseSpeedMps,
    required MtbSuspensionDampingMetrics dampingMetrics,
    required DropperPostState activeDropper,
  }) {
    final bike = input.bikeConfig;
    final safeLength = math.max(1.0, option.lengthMeters);
    final travelOk = bike.suspension.forkTravelMm >= option.minSuspensionTravelMm;
    final dropperOk =
        !option.requiresDropperPost || activeDropper != DropperPostState.extended;

    // Przewaga prędkości na A-Line vs B-Line z uwzględnieniem jakości zawieszenia i techniki
    final skillAvg = ((input.bikeHandling + input.descendingSkill) * 0.5)
        .clamp(30.0, 100.0);
    final skillFactor = 0.86 + ((skillAvg - 50.0) / 50.0) * 0.22;
    final travelSpeedMod = travelOk ? 1.0 : 0.90;
    final dropperSpeedMod = dropperOk ? 1.0 : 0.92;
    final gripSpeedMod =
        (0.85 + dampingMetrics.tire24GripMu * 0.16).clamp(0.84, 1.08);

    final expectedSpeedMps = (baseSpeedMps *
            skillFactor *
            travelSpeedMod *
            dropperSpeedMod *
            gripSpeedMod)
        .clamp(1.8, 19.5);

    final rawTime = safeLength / expectedSpeedMps;
    final cleanTimeSeconds = math.max(
      1.0,
      rawTime - (option.lineChoice == MtbTrailLineChoice.aLine
          ? option.timeAdvantageSeconds * 0.35
          : 0.0),
    );

    // Ryzyko kraksy i błędów
    final skillMitigation = (1.35 - (skillAvg / 100.0) * 0.75).clamp(0.45, 1.35);
    final fatiguePenalty =
        input.wPrimeRemainingRatio < 0.25 ? 1.38 : (1.0 + (1.0 - input.wPrimeRemainingRatio) * 0.15);
    final soilRiskFactor = (1.15 / dampingMetrics.tire24GripMu).clamp(0.75, 2.2);
    final travelPenalty = travelOk ? 1.0 : 1.55;
    final dropperPenalty = dropperOk ? 1.0 : 1.45;
    final dampingFactor = (1.30 - dampingMetrics.dampingAbsorptionRatio * 0.45)
        .clamp(0.75, 1.40);

    final adjustedCrashRisk = (option.crashRiskBase *
            skillMitigation *
            fatiguePenalty *
            soilRiskFactor *
            travelPenalty *
            dropperPenalty *
            dampingFactor)
        .clamp(0.002, 0.72);

    final footDabRisk = (adjustedCrashRisk * 1.45).clamp(0.005, 0.65);
    final bottomOutRisk = bike.suspension.bottomOutRisk(
      math.max(option.dropHeightMeters, segment.dropHeightMeters),
      input.riderMassKg,
    );
    final pinchFlatRisk = bike.tireSetup.pinchFlatRisk(
      segment.roughnessIndex *
          (option.lineChoice == MtbTrailLineChoice.aLine ? 1.15 : 0.85),
      input.riderMassKg,
    );

    final expectedIncidentPenalty = adjustedCrashRisk * _crashPenaltySeconds +
        footDabRisk * _footDabPenaltySeconds +
        bottomOutRisk * _bottomOutPenaltySeconds +
        pinchFlatRisk * _pinchFlatPenaltySeconds;

    return MtbLineOptionEvaluation(
      lineChoice: option.lineChoice,
      effectiveLengthMeters: safeLength,
      expectedSpeedMps: expectedSpeedMps,
      cleanTimeSeconds: cleanTimeSeconds,
      adjustedCrashRisk: adjustedCrashRisk,
      footDabRisk: footDabRisk,
      bottomOutRisk: bottomOutRisk,
      pinchFlatRisk: pinchFlatRisk,
      expectedTimeWithRiskSeconds: cleanTimeSeconds + expectedIncidentPenalty,
      meetsTravelRequirement: travelOk,
      meetsDropperRequirement: dropperOk,
    );
  }

  static MtbTrailLineChoice _selectLine({
    required MtbLineTacticalPolicy policy,
    required MtbLineOptionEvaluation aEval,
    required MtbLineOptionEvaluation bEval,
  }) {
    switch (policy) {
      case MtbLineTacticalPolicy.forcedALine:
        return MtbTrailLineChoice.aLine;
      case MtbLineTacticalPolicy.forcedBLine:
        return MtbTrailLineChoice.bLine;
      case MtbLineTacticalPolicy.conservativeBLine:
        return bEval.totalIncidentRisk <= aEval.totalIncidentRisk
            ? MtbTrailLineChoice.bLine
            : MtbTrailLineChoice.aLine;
      case MtbLineTacticalPolicy.aggressiveALine:
        // Wybiera A-Line, dopóki łączne ryzyko kraksy nie przekracza 22%
        return aEval.adjustedCrashRisk <= 0.22
            ? MtbTrailLineChoice.aLine
            : MtbTrailLineChoice.bLine;
      case MtbLineTacticalPolicy.balancedExpectedValue:
        return aEval.expectedTimeWithRiskSeconds <=
                bEval.expectedTimeWithRiskSeconds
            ? MtbTrailLineChoice.aLine
            : MtbTrailLineChoice.bLine;
    }
  }

  static ({MtbSegmentOutcome outcome, double penaltySeconds})
      _resolveSegmentOutcome({
    required MtbTrailLineChoice chosenLine,
    required MtbLineOptionEvaluation evaluation,
    required bool hasSplit,
    required double climbWheelspinRatio,
    double? deterministicRoll,
  }) {
    if (deterministicRoll != null) {
      final roll = deterministicRoll.clamp(0.0, 0.9999);
      if (roll < evaluation.adjustedCrashRisk) {
        return (
          outcome: MtbSegmentOutcome.lineCrash,
          penaltySeconds: _crashPenaltySeconds,
        );
      }
      if (roll < evaluation.adjustedCrashRisk + evaluation.pinchFlatRisk) {
        return (
          outcome: MtbSegmentOutcome.pinchFlatPuncture,
          penaltySeconds: _pinchFlatPenaltySeconds,
        );
      }
      if (roll <
          evaluation.adjustedCrashRisk +
              evaluation.pinchFlatRisk +
              evaluation.bottomOutRisk * 0.5) {
        return (
          outcome: MtbSegmentOutcome.dropBottomOut,
          penaltySeconds: _bottomOutPenaltySeconds,
        );
      }
      if (roll <
              evaluation.adjustedCrashRisk +
                  evaluation.pinchFlatRisk +
                  evaluation.bottomOutRisk * 0.5 +
                  evaluation.footDabRisk * 0.5 ||
          climbWheelspinRatio > 1.35) {
        return (
          outcome: MtbSegmentOutcome.footDabStumble,
          penaltySeconds: _footDabPenaltySeconds,
        );
      }
    }

    if (!hasSplit) {
      return (
        outcome: MtbSegmentOutcome.cleanSingleLine,
        penaltySeconds: 0.0,
      );
    }

    return (
      outcome: chosenLine == MtbTrailLineChoice.aLine
          ? MtbSegmentOutcome.cleanFastALine
          : MtbSegmentOutcome.cleanSafeBLine,
      penaltySeconds: 0.0,
    );
  }

  static String _buildDecisionReasonPl({
    required MtbTrailLineChoice chosen,
    required MtbLineOptionEvaluation aEval,
    required MtbLineOptionEvaluation bEval,
    required MtbLineTacticalPolicy policy,
    required MtbSegmentOutcome outcome,
  }) {
    if (outcome.isIncident) {
      return '${outcome.labelPl} podczas jazdy ${chosen == MtbTrailLineChoice.aLine ? 'linią A' : 'linią B'}.';
    }
    if (chosen == MtbTrailLineChoice.aLine) {
      final saved = (bEval.cleanTimeSeconds - aEval.cleanTimeSeconds)
          .toStringAsFixed(2);
      return 'Wybrano linię A (${policy.labelPl}): zysk ~$saved s, ryzyko kraksy ${(aEval.adjustedCrashRisk * 100).toStringAsFixed(1)}%.';
    }
    return 'Wybrano bezpieczną linię B (${policy.labelPl}): ryzyko na A-Line wynosiło ${(aEval.adjustedCrashRisk * 100).toStringAsFixed(1)}%.';
  }
}
