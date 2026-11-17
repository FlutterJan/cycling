import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/rider/rider_physiology.dart';
import 'nutrition_and_glycogen_engine.dart';

/// Strategie żywieniowe i suplementacyjne WorldTouru wybierane przez zespół przed wyścigiem.
enum TeamNutritionStrategyType {
  /// Klasyczna strategia izotoniczno-żelowa (60 g węglowodanów na godzinę).
  standard60gCho,

  /// Nowoczesny hydrożel wysokowęglowodanowy (110 g/h, transport SGLT1 + GLUT5).
  /// Wymaga wysokiego wytrenowania jelit (`gutTrainingLevel >= 0.70`), inaczej grozi GI Distress.
  highCarbHydrogel110g,

  /// Przedstartowe ładowanie wodorowęglanem sodu (0.3 g/kg w minikapsułkach hydrożelowych).
  /// Zwiększa buforowanie kwasu mlekowego i pojemność W' o +6% kosztem ryzyka problemów żołądkowych.
  bicarbonatePreLoad,

  /// Egzogenne estry ketonowe podawane bezpośrednio po przekroczeniu linii mety.
  /// Przyspieszają nocną regenerację glikogenu i spadek zmęczenia o +12%.
  postFinishExogenousKetones;

  String get displayName {
    switch (this) {
      case TeamNutritionStrategyType.standard60gCho:
        return 'Standard 60g/h CHO';
      case TeamNutritionStrategyType.highCarbHydrogel110g:
        return 'High-Carb Hydrogel 110g/h';
      case TeamNutritionStrategyType.bicarbonatePreLoad:
        return 'Bicarbonate Pre-Load';
      case TeamNutritionStrategyType.postFinishExogenousKetones:
        return 'Post-Finish Exogenous Ketones';
    }
  }

  String get shortLabel {
    switch (this) {
      case TeamNutritionStrategyType.standard60gCho:
        return '60g/h CHO';
      case TeamNutritionStrategyType.highCarbHydrogel110g:
        return 'Hydrogel 110g/h';
      case TeamNutritionStrategyType.bicarbonatePreLoad:
        return 'Bicarb +6% W\'';
      case TeamNutritionStrategyType.postFinishExogenousKetones:
        return 'Ketones +12% Rec';
    }
  }

  String get scientificSummary {
    switch (this) {
      case TeamNutritionStrategyType.standard60gCho:
        return 'Bezpieczna podaż 60 g/h glukozy/maltodekstryny. Minimalne obciążenie jelit i brak wymogu adaptacji.';
      case TeamNutritionStrategyType.highCarbHydrogel110g:
        return 'Matryca alginianowo-pektynowa 110 g/h (1:0.8). Wymaga wytrenowania jelit (>=70%), aby uniknąć GI Distress.';
      case TeamNutritionStrategyType.bicarbonatePreLoad:
        return 'Buforowanie H+ i mleczanu zwiększające W\' o +6%. Podwyższone ryzyko dolegliwości żołądkowo-jelitowych.';
      case TeamNutritionStrategyType.postFinishExogenousKetones:
        return 'Estry ketonowe po mecie: aktywacja mTOR i resynteza glikogenu przyspieszająca nocną regenerację o +12%.';
    }
  }

  double get targetCarbsGramsPerHour {
    switch (this) {
      case TeamNutritionStrategyType.standard60gCho:
        return 60.0;
      case TeamNutritionStrategyType.highCarbHydrogel110g:
        return 110.0;
      case TeamNutritionStrategyType.bicarbonatePreLoad:
        return 60.0;
      case TeamNutritionStrategyType.postFinishExogenousKetones:
        return 60.0;
    }
  }

  double get requiredGutTrainingLevel {
    switch (this) {
      case TeamNutritionStrategyType.standard60gCho:
        return 0.0;
      case TeamNutritionStrategyType.highCarbHydrogel110g:
        return 0.70;
      case TeamNutritionStrategyType.bicarbonatePreLoad:
        return 0.40;
      case TeamNutritionStrategyType.postFinishExogenousKetones:
        return 0.0;
    }
  }

  double get wPrimeBonusFraction {
    switch (this) {
      case TeamNutritionStrategyType.bicarbonatePreLoad:
        return 0.06;
      case TeamNutritionStrategyType.standard60gCho:
      case TeamNutritionStrategyType.highCarbHydrogel110g:
      case TeamNutritionStrategyType.postFinishExogenousKetones:
        return 0.0;
    }
  }

  double get overnightRecoveryBonusFraction {
    switch (this) {
      case TeamNutritionStrategyType.postFinishExogenousKetones:
        return 0.12;
      case TeamNutritionStrategyType.standard60gCho:
      case TeamNutritionStrategyType.highCarbHydrogel110g:
      case TeamNutritionStrategyType.bicarbonatePreLoad:
        return 0.0;
    }
  }

  int get costPerRiderEur {
    switch (this) {
      case TeamNutritionStrategyType.standard60gCho:
        return 15;
      case TeamNutritionStrategyType.highCarbHydrogel110g:
        return 45;
      case TeamNutritionStrategyType.bicarbonatePreLoad:
        return 35;
      case TeamNutritionStrategyType.postFinishExogenousKetones:
        return 85;
    }
  }

  Color get accentColor {
    switch (this) {
      case TeamNutritionStrategyType.standard60gCho:
        return AppColors.accentBlue;
      case TeamNutritionStrategyType.highCarbHydrogel110g:
        return AppColors.cyanAccent;
      case TeamNutritionStrategyType.bicarbonatePreLoad:
        return AppColors.amberWarning;
      case TeamNutritionStrategyType.postFinishExogenousKetones:
        return AppColors.goldAccent;
    }
  }
}

/// Nasilenie problemów żołądkowo-jelitowych (GI Distress) podczas etapu.
enum GiDistressSeverity {
  none,
  mild,
  moderate,
  severe;

  String get displayName {
    switch (this) {
      case GiDistressSeverity.none:
        return 'Brak (Optymalnie)';
      case GiDistressSeverity.mild:
        return 'Łagodny GI Distress';
      case GiDistressSeverity.moderate:
        return 'Umiarkowany GI Distress';
      case GiDistressSeverity.severe:
        return 'Ciężki GI Distress';
    }
  }

  double get ftpPenaltyFraction {
    switch (this) {
      case GiDistressSeverity.none:
        return 0.0;
      case GiDistressSeverity.mild:
        return 0.02;
      case GiDistressSeverity.moderate:
        return 0.06;
      case GiDistressSeverity.severe:
        return 0.12;
    }
  }

  double get absorptionMultiplier {
    switch (this) {
      case GiDistressSeverity.none:
        return 1.0;
      case GiDistressSeverity.mild:
        return 0.88;
      case GiDistressSeverity.moderate:
        return 0.72;
      case GiDistressSeverity.severe:
        return 0.50;
    }
  }

  Color get statusColor {
    switch (this) {
      case GiDistressSeverity.none:
        return AppColors.statusSuccess;
      case GiDistressSeverity.mild:
        return AppColors.amberWarning;
      case GiDistressSeverity.moderate:
        return AppColors.powerZone5;
      case GiDistressSeverity.severe:
        return AppColors.crimsonAlert;
    }
  }
}

/// Profil tolerancji jelitowej i suplementacji pojedynczego kolarza.
class RiderSupplementationProfile {
  final String riderId;
  final String riderName;

  /// Poziom wytrenowania jelit [0.0 - 1.0] (np. 0.75 = 75% adaptacji do 110g/h CHO).
  final double gutTrainingLevel;

  /// Indywidualna tolerancja przewodu pokarmowego na wodorowęglan sodu [0.0 - 1.0].
  final double bicarbonateTolerance;

  /// Czy kolarz jest dopuszczony medycznie do pełnej suplementacji wyścigowej.
  final bool isClearedForSupplementation;

  const RiderSupplementationProfile({
    required this.riderId,
    required this.riderName,
    required this.gutTrainingLevel,
    this.bicarbonateTolerance = 0.65,
    this.isClearedForSupplementation = true,
  });

  double get clampedGutTraining => gutTrainingLevel.clamp(0.0, 1.0);
  double get clampedBicarbTolerance => bicarbonateTolerance.clamp(0.0, 1.0);

  RiderSupplementationProfile copyWith({
    String? riderId,
    String? riderName,
    double? gutTrainingLevel,
    double? bicarbonateTolerance,
    bool? isClearedForSupplementation,
  }) {
    return RiderSupplementationProfile(
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      gutTrainingLevel: gutTrainingLevel ?? this.gutTrainingLevel,
      bicarbonateTolerance: bicarbonateTolerance ?? this.bicarbonateTolerance,
      isClearedForSupplementation: isClearedForSupplementation ?? this.isClearedForSupplementation,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'riderName': riderName,
      'gutTrainingLevel': gutTrainingLevel,
      'bicarbonateTolerance': bicarbonateTolerance,
      'isClearedForSupplementation': isClearedForSupplementation,
    };
  }

  factory RiderSupplementationProfile.fromJson(Map<String, dynamic> json) {
    return RiderSupplementationProfile(
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      gutTrainingLevel: (json['gutTrainingLevel'] as num).toDouble(),
      bicarbonateTolerance: (json['bicarbonateTolerance'] as num?)?.toDouble() ?? 0.65,
      isClearedForSupplementation: json['isClearedForSupplementation'] as bool? ?? true,
    );
  }
}

/// Wynik oceny przedstartowej wybranej strategii żywieniowej dla danego kolarza.
class PreRaceNutritionStrategyEvaluation {
  final TeamNutritionStrategyType strategy;
  final double effectiveCarbAbsorptionGramsPerHour;
  final double wPrimeMultiplier;
  final double lactateBufferingMultiplier;
  final double overnightRecoveryMultiplier;
  final double giDistressRiskFraction;
  final bool meetsGutTrainingRequirement;
  final int costEur;

  const PreRaceNutritionStrategyEvaluation({
    required this.strategy,
    required this.effectiveCarbAbsorptionGramsPerHour,
    required this.wPrimeMultiplier,
    required this.lactateBufferingMultiplier,
    required this.overnightRecoveryMultiplier,
    required this.giDistressRiskFraction,
    required this.meetsGutTrainingRequirement,
    required this.costEur,
  });

  double get giDistressRiskPercent => (giDistressRiskFraction * 100.0).clamp(0.0, 100.0);
  double get wPrimeBonusPercent => (wPrimeMultiplier - 1.0) * 100.0;
  double get overnightRecoveryBonusPercent => (overnightRecoveryMultiplier - 1.0) * 100.0;
}

/// Wynik losowania/oceny problemów żołądkowo-jelitowych podczas etapu.
class GiDistressOutcome {
  final GiDistressSeverity severity;
  final double calculatedRiskFraction;
  final double ftpPenaltyFraction;
  final double absorptionMultiplier;

  const GiDistressOutcome({
    required this.severity,
    required this.calculatedRiskFraction,
    required this.ftpPenaltyFraction,
    required this.absorptionMultiplier,
  });

  bool get hasDistress => severity != GiDistressSeverity.none;
}

/// Wynik pojedynczego kroku symulacji wyścigowej z uwzględnieniem nowoczesnej suplementacji.
class SupplementationRaceStepResult {
  final NutritionState nutritionState;
  final PreRaceNutritionStrategyEvaluation evaluation;
  final GiDistressOutcome giOutcome;
  final double effectiveFtpWatts;
  final double effectiveWPrimeJoules;
  final double carbsBurnedGrams;
  final double carbsAbsorbedGrams;
  final double fluidLostMl;
  final double fluidAbsorbedMl;
  final bool isBonking;

  const SupplementationRaceStepResult({
    required this.nutritionState,
    required this.evaluation,
    required this.giOutcome,
    required this.effectiveFtpWatts,
    required this.effectiveWPrimeJoules,
    required this.carbsBurnedGrams,
    required this.carbsAbsorbedGrams,
    required this.fluidLostMl,
    required this.fluidAbsorbedMl,
    required this.isBonking,
  });
}

/// Wynik nocnej regeneracji po etapie z uwzględnieniem egzogennych ketonów.
class OvernightKetoneRecoveryResult {
  final TeamNutritionStrategyType strategy;
  final double baseFatigueDropAtl;
  final double boostedFatigueDropAtl;
  final double baseGlycogenResynthesisGrams;
  final double boostedGlycogenResynthesisGrams;
  final double recoveryMultiplier;

  const OvernightKetoneRecoveryResult({
    required this.strategy,
    required this.baseFatigueDropAtl,
    required this.boostedFatigueDropAtl,
    required this.baseGlycogenResynthesisGrams,
    required this.boostedGlycogenResynthesisGrams,
    required this.recoveryMultiplier,
  });

  double get extraFatigueDropAtl => boostedFatigueDropAtl - baseFatigueDropAtl;
  double get recoveryBoostPercent => (recoveryMultiplier - 1.0) * 100.0;
}

/// Zbiorcze podsumowanie planu suplementacyjnego dla całego składu drużyny przed wyścigiem.
class TeamNutritionPlanSummary {
  final int riderCount;
  final int totalCostEur;
  final double averageGiRiskFraction;
  final int gutTrainingWarningCount;
  final double averageEffectiveCarbsGramsPerHour;
  final List<PreRaceNutritionStrategyEvaluation> riderEvaluations;

  const TeamNutritionPlanSummary({
    required this.riderCount,
    required this.totalCostEur,
    required this.averageGiRiskFraction,
    required this.gutTrainingWarningCount,
    required this.averageEffectiveCarbsGramsPerHour,
    required this.riderEvaluations,
  });
}

/// Silnik nowoczesnej suplementacji WorldTouru:
/// - `Standard 60g/h CHO`
/// - `High-Carb Hydrogel 110g/h` (zależny od `gutTrainingLevel`)
/// - `Bicarbonate Pre-Load` (+6% pojemności W' i buforowania mleczanu kosztem ryzyka `GI Distress`)
/// - `Post-Finish Exogenous Ketones` (+12% regeneracji nocnej)
class CarbohydrateHydrogelAndKetonesEngine {
  CarbohydrateHydrogelAndKetonesEngine._();

  static const double standardCarbsGramsPerHour = 60.0;
  static const double hydrogelMaxCarbsGramsPerHour = 110.0;
  static const double hydrogelUntrainedCarbsGramsPerHour = 75.0;
  static const double hydrogelRequiredGutTraining = 0.70;
  static const double bicarbonateWPrimeBonus = 0.06;
  static const double ketonesOvernightRecoveryBonus = 0.12;

  /// Oblicza przedstartową ocenę wybranej strategii żywieniowej dla konkretnego kolarza.
  static PreRaceNutritionStrategyEvaluation evaluatePreRaceStrategy({
    required TeamNutritionStrategyType strategy,
    required RiderSupplementationProfile profile,
    double raceTemperatureCelsius = 22.0,
  }) {
    final double gut = profile.clampedGutTraining;
    final double bicarbTol = profile.clampedBicarbTolerance;
    final double heatFactor = raceTemperatureCelsius > 28.0
        ? (1.0 + (raceTemperatureCelsius - 28.0) * 0.025).clamp(1.0, 1.35)
        : 1.0;

    late final double effectiveCarbsPerHour;
    late final double baseRisk;
    late final bool meetsGut;

    switch (strategy) {
      case TeamNutritionStrategyType.standard60gCho:
        effectiveCarbsPerHour = standardCarbsGramsPerHour;
        baseRisk = 0.02;
        meetsGut = true;
        break;

      case TeamNutritionStrategyType.highCarbHydrogel110g:
        meetsGut = gut >= hydrogelRequiredGutTraining;
        if (meetsGut) {
          effectiveCarbsPerHour = hydrogelMaxCarbsGramsPerHour;
          final double extraAdaptation = (gut - hydrogelRequiredGutTraining) / (1.0 - hydrogelRequiredGutTraining);
          baseRisk = 0.08 - (extraAdaptation * 0.03);
        } else {
          final double progress = (gut / hydrogelRequiredGutTraining).clamp(0.0, 1.0);
          effectiveCarbsPerHour = hydrogelUntrainedCarbsGramsPerHour +
              (hydrogelMaxCarbsGramsPerHour - hydrogelUntrainedCarbsGramsPerHour) * progress;
          final double deficit = hydrogelRequiredGutTraining - gut;
          baseRisk = 0.08 + deficit * 0.65;
        }
        break;

      case TeamNutritionStrategyType.bicarbonatePreLoad:
        effectiveCarbsPerHour = standardCarbsGramsPerHour;
        meetsGut = gut >= strategy.requiredGutTrainingLevel;
        baseRisk = (0.18 * (1.0 - 0.45 * bicarbTol - 0.30 * gut)).clamp(0.04, 0.35);
        break;

      case TeamNutritionStrategyType.postFinishExogenousKetones:
        effectiveCarbsPerHour = standardCarbsGramsPerHour;
        meetsGut = true;
        baseRisk = 0.03;
        break;
    }

    final double totalRisk = (baseRisk * heatFactor).clamp(0.01, 0.75);
    final double wPrimeMult = 1.0 + strategy.wPrimeBonusFraction;
    final double recoveryMult = 1.0 + strategy.overnightRecoveryBonusFraction;

    return PreRaceNutritionStrategyEvaluation(
      strategy: strategy,
      effectiveCarbAbsorptionGramsPerHour: effectiveCarbsPerHour,
      wPrimeMultiplier: wPrimeMult,
      lactateBufferingMultiplier: wPrimeMult,
      overnightRecoveryMultiplier: recoveryMult,
      giDistressRiskFraction: totalRisk,
      meetsGutTrainingRequirement: meetsGut,
      costEur: strategy.costPerRiderEur,
    );
  }

  /// Deterministycznie ocenia wystąpienie i nasilenie `GI Distress` na podstawie rzutu [0.0, 1.0].
  static GiDistressOutcome evaluateGiDistress({
    required PreRaceNutritionStrategyEvaluation evaluation,
    required double deterministicRoll01,
  }) {
    final double roll = deterministicRoll01.clamp(0.0, 1.0);
    final double risk = evaluation.giDistressRiskFraction.clamp(0.0, 1.0);

    if (roll >= risk) {
      return GiDistressOutcome(
        severity: GiDistressSeverity.none,
        calculatedRiskFraction: risk,
        ftpPenaltyFraction: GiDistressSeverity.none.ftpPenaltyFraction,
        absorptionMultiplier: GiDistressSeverity.none.absorptionMultiplier,
      );
    }

    final GiDistressSeverity severity;
    if (roll < risk * 0.25) {
      severity = GiDistressSeverity.severe;
    } else if (roll < risk * 0.60) {
      severity = GiDistressSeverity.moderate;
    } else {
      severity = GiDistressSeverity.mild;
    }

    return GiDistressOutcome(
      severity: severity,
      calculatedRiskFraction: risk,
      ftpPenaltyFraction: severity.ftpPenaltyFraction,
      absorptionMultiplier: severity.absorptionMultiplier,
    );
  }

  /// Wylicza efektywną pojemność beztlenową W' kolarza [J] po uwzględnieniu strategii (np. +6% Bicarbonate Pre-Load).
  static double computeEffectiveWPrimeJoules({
    required RiderPhysiology physiology,
    required TeamNutritionStrategyType strategy,
  }) {
    final double baseWPrime = math.max(1000.0, physiology.wPrimeJoules.toDouble());
    return baseWPrime * (1.0 + strategy.wPrimeBonusFraction);
  }

  /// Wylicza przyspieszoną nocną regenerację po etapie (z +12% dla `Post-Finish Exogenous Ketones`).
  static OvernightKetoneRecoveryResult computeOvernightRecovery({
    required TeamNutritionStrategyType strategy,
    required double baseFatigueDropAtl,
    required double baseGlycogenResynthesisGrams,
    double riderRecoveryRate = 1.0,
  }) {
    final double safeAtl = math.max(0.0, baseFatigueDropAtl);
    final double safeGlycogen = math.max(0.0, baseGlycogenResynthesisGrams);
    final double safeRate = riderRecoveryRate.clamp(0.5, 2.0);
    final double multiplier = 1.0 + strategy.overnightRecoveryBonusFraction;

    return OvernightKetoneRecoveryResult(
      strategy: strategy,
      baseFatigueDropAtl: safeAtl * safeRate,
      boostedFatigueDropAtl: safeAtl * safeRate * multiplier,
      baseGlycogenResynthesisGrams: safeGlycogen,
      boostedGlycogenResynthesisGrams: safeGlycogen * multiplier,
      recoveryMultiplier: multiplier,
    );
  }

  /// Wykonuje krok symulacji wyścigowej łącząc model `NutritionAndGlycogenEngine`
  /// z wybraną strategią WorldTouru, absorpcją hydrożelową, buforowaniem W' oraz ewentualnym GI Distress.
  static SupplementationRaceStepResult simulateRaceStep({
    required NutritionState state,
    required RiderPhysiology physiology,
    required RiderSupplementationProfile profile,
    required TeamNutritionStrategyType strategy,
    required double currentPowerWatts,
    double temperatureCelsius = 22.0,
    double timeStepSeconds = 1.0,
    double deterministicGiRoll01 = 0.99,
  }) {
    final PreRaceNutritionStrategyEvaluation evaluation = evaluatePreRaceStrategy(
      strategy: strategy,
      profile: profile,
      raceTemperatureCelsius: temperatureCelsius,
    );
    final GiDistressOutcome giOutcome = evaluateGiDistress(
      evaluation: evaluation,
      deterministicRoll01: deterministicGiRoll01,
    );
    final double effectiveWPrime = computeEffectiveWPrimeJoules(
      physiology: physiology,
      strategy: strategy,
    );

    if (timeStepSeconds <= 0.0) {
      final double baseFtp = physiology.ftpWatts.toDouble() *
          state.effectiveFtpMultiplier *
          (1.0 - giOutcome.ftpPenaltyFraction);
      return SupplementationRaceStepResult(
        nutritionState: state,
        evaluation: evaluation,
        giOutcome: giOutcome,
        effectiveFtpWatts: baseFtp,
        effectiveWPrimeJoules: effectiveWPrime,
        carbsBurnedGrams: 0.0,
        carbsAbsorbedGrams: 0.0,
        fluidLostMl: 0.0,
        fluidAbsorbedMl: 0.0,
        isBonking: state.isBonking,
      );
    }

    final double baseFtp = physiology.ftpWatts.toDouble();
    final double carbBurnRate = NutritionAndGlycogenEngine.calculateCarbBurnRateGramsPerSecond(
      currentPowerWatts: currentPowerWatts,
      ftpWatts: baseFtp,
      labProfile: physiology.labProfile,
    );
    final double carbsBurned = carbBurnRate * timeStepSeconds;

    final double maxAbsorptionPerSecond =
        (evaluation.effectiveCarbAbsorptionGramsPerHour * giOutcome.absorptionMultiplier) / 3600.0;
    final double carbsAbsorbed = math.min(state.stomachCarbsGrams, maxAbsorptionPerSecond * timeStepSeconds);
    final double newStomachCarbs = math.max(0.0, state.stomachCarbsGrams - carbsAbsorbed);

    final double rawGlycogen = state.currentGlycogenGrams - carbsBurned + carbsAbsorbed;
    final double newGlycogen = rawGlycogen.clamp(0.0, state.maxGlycogenGrams);

    bool isBonking = state.isBonking;
    int bonkCount = state.bonkCount;
    double timeInBonk = state.timeInBonkSeconds;

    if (!isBonking && newGlycogen < NutritionAndGlycogenEngine.bonkThresholdGrams) {
      isBonking = true;
      bonkCount++;
    } else if (isBonking) {
      timeInBonk += timeStepSeconds;
      if (newGlycogen >= NutritionAndGlycogenEngine.bonkExitThresholdGrams) {
        isBonking = false;
      }
    }

    final double sweatRate = NutritionAndGlycogenEngine.calculateSweatRateMlPerSecond(
      currentPowerWatts: currentPowerWatts,
      temperatureCelsius: temperatureCelsius,
      riderWeightKg: physiology.weightKg,
      grossEfficiencyPercent: physiology.labProfile?.grossEfficiencyPercent ?? 22.0,
    );
    final double fluidLost = sweatRate * timeStepSeconds;

    const double maxFluidAbsorptionPerSecond =
        NutritionAndGlycogenEngine.maxStomachFluidAbsorptionMlPerHour / 3600.0;
    final double fluidAbsorbed = math.min(
      state.stomachFluidMl,
      maxFluidAbsorptionPerSecond * timeStepSeconds,
    );
    final double newStomachFluid = math.max(0.0, state.stomachFluidMl - fluidAbsorbed);

    final double bodyWaterEquivMl = math.max(300.0, physiology.weightKg * 10.0);
    final double hydrationDeltaPercent = (fluidAbsorbed - fluidLost) / bodyWaterEquivMl;
    final double newHydration = (state.hydrationPercent + hydrationDeltaPercent).clamp(50.0, 100.0);

    final double bonkMultiplier = isBonking ? (1.0 - NutritionAndGlycogenEngine.bonkFtpPenalty) : 1.0;
    final double effectiveFtp = baseFtp * bonkMultiplier * (1.0 - giOutcome.ftpPenaltyFraction);

    final NutritionState updatedState = state.copyWith(
      currentGlycogenGrams: newGlycogen,
      hydrationPercent: newHydration,
      stomachCarbsGrams: newStomachCarbs,
      stomachFluidMl: newStomachFluid,
      isBonking: isBonking,
      bonkCount: bonkCount,
      timeInBonkSeconds: timeInBonk,
      totalCarbsBurnedGrams: state.totalCarbsBurnedGrams + carbsBurned,
      totalFluidSweatedMl: state.totalFluidSweatedMl + fluidLost,
    );

    return SupplementationRaceStepResult(
      nutritionState: updatedState,
      evaluation: evaluation,
      giOutcome: giOutcome,
      effectiveFtpWatts: effectiveFtp,
      effectiveWPrimeJoules: effectiveWPrime,
      carbsBurnedGrams: carbsBurned,
      carbsAbsorbedGrams: carbsAbsorbed,
      fluidLostMl: fluidLost,
      fluidAbsorbedMl: fluidAbsorbed,
      isBonking: isBonking,
    );
  }

  /// Ocenia zbiorczy plan suplementacji dla całego składu zespołu przed startem etapu.
  static TeamNutritionPlanSummary evaluateTeamRosterPlan({
    required Map<RiderSupplementationProfile, TeamNutritionStrategyType> assignments,
    double raceTemperatureCelsius = 22.0,
  }) {
    if (assignments.isEmpty) {
      return const TeamNutritionPlanSummary(
        riderCount: 0,
        totalCostEur: 0,
        averageGiRiskFraction: 0.0,
        gutTrainingWarningCount: 0,
        averageEffectiveCarbsGramsPerHour: 0.0,
        riderEvaluations: [],
      );
    }

    final List<PreRaceNutritionStrategyEvaluation> evaluations = [];
    int totalCost = 0;
    double sumGiRisk = 0.0;
    int warnings = 0;
    double sumCarbs = 0.0;

    assignments.forEach((profile, strategy) {
      final PreRaceNutritionStrategyEvaluation eval = evaluatePreRaceStrategy(
        strategy: strategy,
        profile: profile,
        raceTemperatureCelsius: raceTemperatureCelsius,
      );
      evaluations.add(eval);
      totalCost += eval.costEur;
      sumGiRisk += eval.giDistressRiskFraction;
      if (!eval.meetsGutTrainingRequirement) {
        warnings++;
      }
      sumCarbs += eval.effectiveCarbAbsorptionGramsPerHour;
    });

    final int count = evaluations.length;
    return TeamNutritionPlanSummary(
      riderCount: count,
      totalCostEur: totalCost,
      averageGiRiskFraction: sumGiRisk / count,
      gutTrainingWarningCount: warnings,
      averageEffectiveCarbsGramsPerHour: sumCarbs / count,
      riderEvaluations: evaluations,
    );
  }
}

/// Produkcyjny panel wyboru strategii żywieniowej i suplementacji WorldTouru przed wyścigiem.
/// W pełni responsywny dla rozdzielczości `390x844`, `1024x768` i `1600x900` z pełnymi stanami
/// `hover`, `active`, `disabled` i `focus`.
class CarbohydrateHydrogelAndKetonesPanel extends StatefulWidget {
  final RiderSupplementationProfile initialProfile;
  final TeamNutritionStrategyType initialStrategy;
  final double baseWPrimeJoules;
  final double raceTemperatureCelsius;
  final ValueChanged<TeamNutritionStrategyType>? onStrategyApplied;

  const CarbohydrateHydrogelAndKetonesPanel({
    super.key,
    this.initialProfile = const RiderSupplementationProfile(
      riderId: 'leader_01',
      riderName: 'Lider GC',
      gutTrainingLevel: 0.78,
      bicarbonateTolerance: 0.70,
    ),
    this.initialStrategy = TeamNutritionStrategyType.highCarbHydrogel110g,
    this.baseWPrimeJoules = 22000.0,
    this.raceTemperatureCelsius = 24.0,
    this.onStrategyApplied,
  });

  @override
  State<CarbohydrateHydrogelAndKetonesPanel> createState() =>
      _CarbohydrateHydrogelAndKetonesPanelState();
}

class _CarbohydrateHydrogelAndKetonesPanelState
    extends State<CarbohydrateHydrogelAndKetonesPanel> {
  late TeamNutritionStrategyType _selectedStrategy;
  late double _gutTrainingLevel;
  late double _bicarbonateTolerance;
  bool _isConfirmHovered = false;
  bool _isConfirmPressed = false;
  bool _isConfirmFocused = false;
  String? _lastAppliedNotice;

  @override
  void initState() {
    super.initState();
    _selectedStrategy = widget.initialStrategy;
    _gutTrainingLevel = widget.initialProfile.clampedGutTraining;
    _bicarbonateTolerance = widget.initialProfile.clampedBicarbTolerance;
  }

  RiderSupplementationProfile get _currentProfile => widget.initialProfile.copyWith(
        gutTrainingLevel: _gutTrainingLevel,
        bicarbonateTolerance: _bicarbonateTolerance,
      );

  @override
  Widget build(BuildContext context) {
    final PreRaceNutritionStrategyEvaluation evaluation =
        CarbohydrateHydrogelAndKetonesEngine.evaluatePreRaceStrategy(
      strategy: _selectedStrategy,
      profile: _currentProfile,
      raceTemperatureCelsius: widget.raceTemperatureCelsius,
    );

    final double effectiveWPrime = widget.baseWPrimeJoules * evaluation.wPrimeMultiplier;
    final bool isDisabled = !widget.initialProfile.isClearedForSupplementation;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isCompact = constraints.maxWidth < 560;
          final bool isWide = constraints.maxWidth >= 1000;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(isCompact),
                const SizedBox(height: 16),
                _buildStrategyGrid(isCompact: isCompact, isWide: isWide, isDisabled: isDisabled),
                const SizedBox(height: 16),
                _buildGutTrainingControl(isDisabled: isDisabled),
                const SizedBox(height: 16),
                _buildTelemetrySummary(
                  evaluation: evaluation,
                  effectiveWPrime: effectiveWPrime,
                  isCompact: isCompact,
                ),
                const SizedBox(height: 16),
                _buildApplyFooter(evaluation: evaluation, isDisabled: isDisabled, isCompact: isCompact),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isCompact) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.goldAccent.withValues(alpha: 0.45)),
          ),
          child: const Icon(Icons.biotech_outlined, color: AppColors.goldAccent, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Strategia Żywieniowa & Suplementacja WorldTour',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isCompact ? 15 : 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${widget.initialProfile.riderName} • Temp. etapu: ${widget.raceTemperatureCelsius.toStringAsFixed(0)}°C',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  letterSpacing: -0.2,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStrategyGrid({
    required bool isCompact,
    required bool isWide,
    required bool isDisabled,
  }) {
    const strategies = TeamNutritionStrategyType.values;
    if (isCompact) {
      return Column(
        children: [
          for (int i = 0; i < strategies.length; i++) ...[
            _StrategyOptionCard(
              strategy: strategies[i],
              isSelected: _selectedStrategy == strategies[i],
              isDisabled: isDisabled,
              gutTrainingLevel: _gutTrainingLevel,
              onSelect: () => setState(() {
                _selectedStrategy = strategies[i];
                _lastAppliedNotice = null;
              }),
            ),
            if (i < strategies.length - 1) const SizedBox(height: 10),
          ],
        ],
      );
    }

    final int columns = isWide ? 4 : 2;
    final List<Widget> rows = [];
    for (int i = 0; i < strategies.length; i += columns) {
      final slice = strategies.sublist(i, math.min(i + columns, strategies.length));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int j = 0; j < slice.length; j++) ...[
                Expanded(
                  child: _StrategyOptionCard(
                    strategy: slice[j],
                    isSelected: _selectedStrategy == slice[j],
                    isDisabled: isDisabled,
                    gutTrainingLevel: _gutTrainingLevel,
                    onSelect: () => setState(() {
                      _selectedStrategy = slice[j];
                      _lastAppliedNotice = null;
                    }),
                  ),
                ),
                if (j < slice.length - 1) const SizedBox(width: 12),
              ],
            ],
          ),
        ),
      );
      if (i + columns < strategies.length) {
        rows.add(const SizedBox(height: 12));
      }
    }
    return Column(children: rows);
  }

  Widget _buildGutTrainingControl({required bool isDisabled}) {
    final int gutPercent = (_gutTrainingLevel * 100).round();
    final bool meetsHydrogel = _gutTrainingLevel >= CarbohydrateHydrogelAndKetonesEngine.hydrogelRequiredGutTraining;
    final Color barColor = meetsHydrogel ? AppColors.statusSuccess : AppColors.amberWarning;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Wytrenowanie jelit (Gut Training Level)',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: barColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: barColor.withValues(alpha: 0.45)),
                ),
                child: Text(
                  '$gutPercent% ${meetsHydrogel ? '(Gotowy na 110g/h)' : '(Próg: 70%)'}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: barColor,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: barColor,
              inactiveTrackColor: AppColors.background,
              thumbColor: AppColors.textPrimary,
              overlayColor: barColor.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: _gutTrainingLevel,
              min: 0.0,
              max: 1.0,
              divisions: 20,
              onChanged: isDisabled
                  ? null
                  : (value) {
                      setState(() {
                        _gutTrainingLevel = value;
                        _lastAppliedNotice = null;
                      });
                    },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetrySummary({
    required PreRaceNutritionStrategyEvaluation evaluation,
    required double effectiveWPrime,
    required bool isCompact,
  }) {
    final List<Widget> metrics = [
      _TelemetryChip(
        label: 'Wchłanianie CHO',
        value: '${evaluation.effectiveCarbAbsorptionGramsPerHour.toStringAsFixed(0)} g/h',
        accent: AppColors.cyanAccent,
      ),
      _TelemetryChip(
        label: 'Pojemność W\'',
        value: '${(effectiveWPrime / 1000.0).toStringAsFixed(2)} kJ (+${evaluation.wPrimeBonusPercent.toStringAsFixed(0)}%)',
        accent: evaluation.wPrimeBonusPercent > 0 ? AppColors.amberWarning : AppColors.textSecondary,
      ),
      _TelemetryChip(
        label: 'Ryzyko GI Distress',
        value: '${evaluation.giDistressRiskPercent.toStringAsFixed(1)}%',
        accent: evaluation.giDistressRiskPercent > 12.0 ? AppColors.crimsonAlert : AppColors.statusSuccess,
      ),
      _TelemetryChip(
        label: 'Regeneracja nocna',
        value: '+${evaluation.overnightRecoveryBonusPercent.toStringAsFixed(0)}%',
        accent: evaluation.overnightRecoveryBonusPercent > 0 ? AppColors.goldAccent : AppColors.textSecondary,
      ),
    ];

    if (isCompact) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: metrics
            .map((m) => SizedBox(width: double.infinity, child: m))
            .toList(),
      );
    }

    return Row(
      children: [
        for (int i = 0; i < metrics.length; i++) ...[
          Expanded(child: metrics[i]),
          if (i < metrics.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }

  Widget _buildApplyFooter({
    required PreRaceNutritionStrategyEvaluation evaluation,
    required bool isDisabled,
    required bool isCompact,
  }) {
    final Color buttonBg = isDisabled
        ? AppColors.surfaceLight
        : _isConfirmPressed
            ? AppColors.primaryAccent.withValues(alpha: 0.85)
            : _isConfirmHovered
                ? AppColors.primaryAccent.withValues(alpha: 0.95)
                : AppColors.primaryAccent;

    final Widget confirmButton = FocusableActionDetector(
      enabled: !isDisabled,
      onShowHoverHighlight: (hovered) => setState(() => _isConfirmHovered = hovered),
      onShowFocusHighlight: (focused) => setState(() => _isConfirmFocused = focused),
      child: GestureDetector(
        onTapDown: isDisabled ? null : (_) => setState(() => _isConfirmPressed = true),
        onTapUp: isDisabled ? null : (_) => setState(() => _isConfirmPressed = false),
        onTapCancel: isDisabled ? null : () => setState(() => _isConfirmPressed = false),
        onTap: isDisabled
            ? null
            : () {
                setState(() {
                  _lastAppliedNotice =
                      'Zastosowano: ${_selectedStrategy.displayName} (${evaluation.costEur} EUR)';
                });
                widget.onStrategyApplied?.call(_selectedStrategy);
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: buttonBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isConfirmFocused
                  ? AppColors.goldAccent
                  : isDisabled
                      ? AppColors.cardBorder
                      : AppColors.primaryAccent,
              width: _isConfirmFocused ? 1.5 : 1.0,
            ),
          ),
          child: Text(
            isDisabled ? 'Suplementacja zablokowana medycznie' : 'Zatwierdź Strategię (${evaluation.costEur} EUR)',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
              color: isDisabled ? AppColors.textSecondary : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isCompact)
          confirmButton
        else
          Row(
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Text(
                    _lastAppliedNotice ?? _selectedStrategy.scientificSummary,
                    key: ValueKey(_lastAppliedNotice ?? _selectedStrategy.name),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      letterSpacing: -0.2,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              confirmButton,
            ],
          ),
        if (isCompact && _lastAppliedNotice != null) ...[
          const SizedBox(height: 8),
          Text(
            _lastAppliedNotice!,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.statusSuccess,
            ),
          ),
        ],
      ],
    );
  }
}

class _StrategyOptionCard extends StatefulWidget {
  final TeamNutritionStrategyType strategy;
  final bool isSelected;
  final bool isDisabled;
  final double gutTrainingLevel;
  final VoidCallback onSelect;

  const _StrategyOptionCard({
    required this.strategy,
    required this.isSelected,
    required this.isDisabled,
    required this.gutTrainingLevel,
    required this.onSelect,
  });

  @override
  State<_StrategyOptionCard> createState() => _StrategyOptionCardState();
}

class _StrategyOptionCardState extends State<_StrategyOptionCard> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final bool needsWarning = widget.strategy == TeamNutritionStrategyType.highCarbHydrogel110g &&
        widget.gutTrainingLevel < CarbohydrateHydrogelAndKetonesEngine.hydrogelRequiredGutTraining;

    final Color borderColor = widget.isDisabled
        ? AppColors.cardBorder
        : widget.isSelected
            ? widget.strategy.accentColor
            : _isFocused
                ? AppColors.goldAccent
                : _isHovered
                    ? widget.strategy.accentColor.withValues(alpha: 0.6)
                    : AppColors.cardBorder;

    final Color bgColor = widget.isDisabled
        ? AppColors.background
        : _isPressed
            ? AppColors.surfaceLight.withValues(alpha: 0.8)
            : widget.isSelected
                ? AppColors.surfaceLight
                : _isHovered
                    ? AppColors.surfaceLight.withValues(alpha: 0.6)
                    : AppColors.background;

    return FocusableActionDetector(
      enabled: !widget.isDisabled,
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      child: GestureDetector(
        onTapDown: widget.isDisabled ? null : (_) => setState(() => _isPressed = true),
        onTapUp: widget.isDisabled ? null : (_) => setState(() => _isPressed = false),
        onTapCancel: widget.isDisabled ? null : () => setState(() => _isPressed = false),
        onTap: widget.isDisabled ? null : widget.onSelect,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: widget.isSelected || _isFocused ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.strategy.displayName,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: widget.isDisabled ? AppColors.textSecondary : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (widget.isSelected)
                    Icon(Icons.check_circle, size: 16, color: widget.strategy.accentColor),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                widget.strategy.scientificSummary,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  letterSpacing: -0.2,
                  color: AppColors.textSecondary,
                ),
              ),
              if (needsWarning) ...[
                const SizedBox(height: 6),
                const Text(
                  'Wymaga Gut Training >= 70%',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.amberWarning,
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

class _TelemetryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _TelemetryChip({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
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
              letterSpacing: -0.2,
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
              fontFeatures: const [FontFeature.tabularFigures()],
              letterSpacing: -0.2,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}
