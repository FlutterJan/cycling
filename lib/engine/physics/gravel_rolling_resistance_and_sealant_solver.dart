import 'dart:math' as math;

import '../../core/constants/physics_constants.dart';
import '../../models/equipment/gravel_bike_and_tire_inserts_model.dart';
import '../../models/race/gravel_race_and_surface_model.dart';

/// Stan nawierzchni szutrowej wpływający na straty impedancyjne i zapadanie opony.
enum GravelRollingCondition {
  dryHardpack,
  looseDryDust,
  washboardChatter,
  wetMuddyRut,
  flintRockField;

  String toJson() => name;

  static GravelRollingCondition fromJson(String value) {
    return GravelRollingCondition.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => GravelRollingCondition.dryHardpack,
    );
  }
}

/// Strategia rozwiązania przebicia opony w wyścigu szutrowym.
enum GravelSealantRepairStrategy {
  /// Mleczko Tubeless zalepiło otwór w trakcie jazdy bez zatrzymywania.
  selfSealedInMotion,

  /// Zatrzymanie na poboczu, użycie knota (bacon strip) oraz naboju CO2.
  tubelessPlugAndCo2,

  /// Jazda awaryjna na piance antyprzebiciowej (Run-Flat) bez zatrzymania.
  runFlatOnFoamInsert,

  /// Rozcięcie wymagające założenia zapasowej dętki.
  spareTubeInstall,

  /// Brak możliwości naprawy — wycofanie z wyścigu (DNF).
  dnfMechanical;

  String toJson() => name;

  static GravelSealantRepairStrategy fromJson(String value) {
    return GravelSealantRepairStrategy.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => GravelSealantRepairStrategy.dnfMechanical,
    );
  }
}

/// Dane wejściowe do obliczenia strat toczenia i impedancji na szutrze.
class GravelImpedanceInput {
  final GravelBikeAndTireInsertsModel bikeSetup;
  final GravelSurfaceCategory surfaceCategory;
  final double speedMetersPerSecond;
  final double riderMassKg;
  final double rainIntensity;
  final double slopeGradient;
  final double ambientTempC;
  final double? looseGravelDepthCm;
  final double? overrideFrontPressureBar;
  final double? overrideRearPressureBar;

  const GravelImpedanceInput({
    required this.bikeSetup,
    required this.surfaceCategory,
    required this.speedMetersPerSecond,
    this.riderMassKg = 72.0,
    this.rainIntensity = 0.0,
    this.slopeGradient = 0.0,
    this.ambientTempC = 22.0,
    this.looseGravelDepthCm,
    this.overrideFrontPressureBar,
    this.overrideRearPressureBar,
  });
}

/// Wynik analizy oporów toczenia, strat impedancyjnych i ryzyka dobicia obręczy.
class GravelImpedanceResult {
  final double effectiveCrr;
  final double baseHysteresisCrr;
  final double impedanceLossCrr;
  final double looseGravelSinkageCrr;
  final double totalRollingPowerWatts;
  final double impedancePenaltyWatts;
  final double sinkagePenaltyWatts;
  final double optimalFrontPressureBar;
  final double optimalRearPressureBar;
  final double vibrationFatigueIndex;
  final double pinchFlatRiskPerHour;
  final double gripMultiplier;
  final double totalSystemMassKg;

  const GravelImpedanceResult({
    required this.effectiveCrr,
    required this.baseHysteresisCrr,
    required this.impedanceLossCrr,
    required this.looseGravelSinkageCrr,
    required this.totalRollingPowerWatts,
    required this.impedancePenaltyWatts,
    required this.sinkagePenaltyWatts,
    required this.optimalFrontPressureBar,
    required this.optimalRearPressureBar,
    required this.vibrationFatigueIndex,
    required this.pinchFlatRiskPerHour,
    required this.gripMultiplier,
    required this.totalSystemMassKg,
  });

  Map<String, dynamic> toJson() => {
        'effectiveCrr': effectiveCrr,
        'baseHysteresisCrr': baseHysteresisCrr,
        'impedanceLossCrr': impedanceLossCrr,
        'looseGravelSinkageCrr': looseGravelSinkageCrr,
        'totalRollingPowerWatts': totalRollingPowerWatts,
        'impedancePenaltyWatts': impedancePenaltyWatts,
        'sinkagePenaltyWatts': sinkagePenaltyWatts,
        'optimalFrontPressureBar': optimalFrontPressureBar,
        'optimalRearPressureBar': optimalRearPressureBar,
        'vibrationFatigueIndex': vibrationFatigueIndex,
        'pinchFlatRiskPerHour': pinchFlatRiskPerHour,
        'gripMultiplier': gripMultiplier,
        'totalSystemMassKg': totalSystemMassKg,
      };
}

/// Dane wejściowe do symulacji przebicia opony i samonaprawy przez mleczko Tubeless.
class GravelPunctureEventInput {
  final GravelBikeAndTireInsertsModel bikeSetup;
  final GravelSurfaceCategory surfaceCategory;
  final double punctureSizeMm;
  final bool isFrontWheel;
  final bool isSidewallCut;
  final double currentTirePressureBar;
  final double speedMetersPerSecond;
  final double ambientTempC;
  final double deterministicRoll01;
  final int availableCo2Cartridges;
  final int availableTubelessPlugs;
  final bool hasSpareInnerTube;

  const GravelPunctureEventInput({
    required this.bikeSetup,
    required this.surfaceCategory,
    required this.punctureSizeMm,
    required this.isFrontWheel,
    this.isSidewallCut = false,
    required this.currentTirePressureBar,
    this.speedMetersPerSecond = 8.5,
    this.ambientTempC = 24.0,
    required this.deterministicRoll01,
    this.availableCo2Cartridges = 2,
    this.availableTubelessPlugs = 5,
    this.hasSpareInnerTube = true,
  });
}

/// Wynik rozstrzygnięcia przebicia na trasie szutrowej.
class GravelPunctureResolutionResult {
  final bool resolved;
  final bool selfSealedWithoutStopping;
  final GravelSealantRepairStrategy strategy;
  final double timeLostSeconds;
  final double pressureAfterEventBar;
  final double sealantConsumedMl;
  final int co2CartridgesUsed;
  final int plugsUsed;
  final bool spareTubeUsed;
  final bool runFlatActive;
  final double postEventRollingPenaltyWatts;
  final GravelBikeAndTireInsertsModel updatedBikeSetup;
  final String diagnosticCode;

  const GravelPunctureResolutionResult({
    required this.resolved,
    required this.selfSealedWithoutStopping,
    required this.strategy,
    required this.timeLostSeconds,
    required this.pressureAfterEventBar,
    required this.sealantConsumedMl,
    required this.co2CartridgesUsed,
    required this.plugsUsed,
    required this.spareTubeUsed,
    required this.runFlatActive,
    required this.postEventRollingPenaltyWatts,
    required this.updatedBikeSetup,
    required this.diagnosticCode,
  });
}

/// Podsumowanie fizyki toczenia i ryzyka przebić dla całego etapu szutrowego.
class GravelStagePhysicsSummary {
  final double totalDistanceKm;
  final double averageEffectiveCrr;
  final double averageRollingWatts;
  final double totalImpedancePenaltyKilojoules;
  final double expectedPuncturesCount;
  final double expectedTimeLostToMechanicalsSeconds;
  final double sealantRemainingFrontMl;
  final double sealantRemainingRearMl;
  final double recommendedFrontPressureBar;
  final double recommendedRearPressureBar;

  const GravelStagePhysicsSummary({
    required this.totalDistanceKm,
    required this.averageEffectiveCrr,
    required this.averageRollingWatts,
    required this.totalImpedancePenaltyKilojoules,
    required this.expectedPuncturesCount,
    required this.expectedTimeLostToMechanicalsSeconds,
    required this.sealantRemainingFrontMl,
    required this.sealantRemainingRearMl,
    required this.recommendedFrontPressureBar,
    required this.recommendedRearPressureBar,
  });
}

/// Silnik fizyki szutrowej obliczający straty impedancyjne na luźnym szutrze
/// (model punktu przegięcia ciśnienia / Silca Breakpoint, zapadanie w żwirze)
/// oraz samonaprawę przebić przez mleczko Tubeless i wkładki Foam Inserts.
class GravelRollingResistanceAndSealantSolver {
  const GravelRollingResistanceAndSealantSolver();

  /// Wylicza optymalne ciśnienie (przód/tył) w barach dla podanej masy kolarza,
  /// szerokości opony, kategorii nawierzchni i ewentualnych wkładek antyprzebiciowych.
  ({double frontBar, double rearBar}) calculateOptimalGravelPressure({
    required GravelBikeAndTireInsertsModel bikeSetup,
    required GravelSurfaceCategory surfaceCategory,
    double riderMassKg = 72.0,
    double rainIntensity = 0.0,
  }) {
    final totalMassKg =
        (riderMassKg + _totalBikeWeightKg(bikeSetup)).clamp(52.0, 130.0);
    final massScale = math.pow(totalMassKg / 81.5, 0.72).toDouble();

    final baseSurfaceBar = surfaceCategory.recommendedTirePressureBar;
    final frontWidthScale =
        math.pow(42.0 / bikeSetup.frontTire.widthMm.clamp(35.0, 52.0), 1.15);
    final rearWidthScale =
        math.pow(42.0 / bikeSetup.rearTire.widthMm.clamp(35.0, 52.0), 1.15);

    final insertAllowance = bikeSetup.tireInserts.isInstalled
        ? bikeSetup.tireInserts.pressureReductionAllowanceBar
        : 0.0;
    final wetReduction = rainIntensity.clamp(0.0, 1.0) * 0.14;

    // Rozkład masy na szutrze: ~44% przód, ~56% tył.
    final rawFront =
        (baseSurfaceBar * massScale * frontWidthScale * 0.94) -
            insertAllowance -
            wetReduction;
    final rawRear =
        (baseSurfaceBar * massScale * rearWidthScale * 1.02) -
            insertAllowance -
            wetReduction;

    return (
      frontBar: rawFront.clamp(1.25, 3.80),
      rearBar: rawRear.clamp(1.35, 4.00),
    );
  }

  /// Oblicza pełny bilans oporów toczenia, strat impedancyjnych, zapadania opony
  /// w luźnym szutrze oraz wskaźników zmęczenia wibracjami i ryzyka dobicia.
  GravelImpedanceResult solveRollingResistance(GravelImpedanceInput input) {
    final speedMs = input.speedMetersPerSecond.clamp(0.0, 28.0);
    final rain = input.rainIntensity.clamp(0.0, 1.0);
    final bike = input.bikeSetup;
    final totalMassKg =
        (input.riderMassKg + _totalBikeWeightKg(bike)).clamp(48.0, 140.0);

    final optimal = calculateOptimalGravelPressure(
      bikeSetup: bike,
      surfaceCategory: input.surfaceCategory,
      riderMassKg: input.riderMassKg,
      rainIntensity: rain,
    );

    final frontP =
        (input.overrideFrontPressureBar ?? bike.frontPressureBar).clamp(0.4, 5.0);
    final rearP =
        (input.overrideRearPressureBar ?? bike.rearPressureBar).clamp(0.4, 5.0);

    // 1. Bazowe opory histerezy opony i wkładki piankowej (44% przód / 56% tył).
    final frontBaseCrr = _tireHysteresisCrr(
      tire: bike.frontTire,
      actualBar: frontP,
      optimalBar: optimal.frontBar,
      insert: bike.tireInserts,
    );
    final rearBaseCrr = _tireHysteresisCrr(
      tire: bike.rearTire,
      actualBar: rearP,
      optimalBar: optimal.rearBar,
      insert: bike.tireInserts,
    );
    final baseHysteresisCrr = (frontBaseCrr * 0.44) + (rearBaseCrr * 0.56);

    // 2. Straty impedancyjne (Breakpoint Impedance Loss):
    // Przekroczenie punktu przegięcia ciśnienia na nierównym szutrze powoduje
    // odbijanie masy kolarza i drgania zamiast ugięcia opony.
    final frontImpedanceCrr = _wheelImpedanceCrr(
      actualBar: frontP,
      optimalBar: optimal.frontBar,
      surface: input.surfaceCategory,
      speedMs: speedMs,
    );
    final rearImpedanceCrr = _wheelImpedanceCrr(
      actualBar: rearP,
      optimalBar: optimal.rearBar,
      surface: input.surfaceCategory,
      speedMs: speedMs,
    );
    final impedanceLossCrr = (frontImpedanceCrr * 0.44) + (rearImpedanceCrr * 0.56);

    // 3. Straty zapadania / spychania luźnego kruszywa (Bulldozing / Sinkage).
    final looseDepthCm =
        input.looseGravelDepthCm ?? _defaultLooseDepthCm(input.surfaceCategory, rain);
    final avgWidthMm = (bike.frontTire.widthMm + bike.rearTire.widthMm) * 0.5;
    final avgPressureBar = (frontP * 0.44) + (rearP * 0.56);
    final sinkageBase = (looseDepthCm / 3.2) *
        math.pow(44.0 / avgWidthMm.clamp(35.0, 52.0), 1.45) *
        math.pow((avgPressureBar / 2.25).clamp(0.5, 2.0), 0.35) *
        0.0024;
    final mudPenaltyCrr = (bike.mudAccumulationKg.clamp(0.0, 6.0) * 0.00045) +
        (rain * (input.surfaceCategory.categoryNumber >= 4 ? 0.0014 : 0.0005));
    final looseGravelSinkageCrr = (sinkageBase + mudPenaltyCrr).clamp(0.0, 0.025);

    final effectiveCrr =
        (baseHysteresisCrr + impedanceLossCrr + looseGravelSinkageCrr)
            .clamp(0.0025, 0.045);

    // 4. Przeliczenie na moc oporów toczenia [W].
    final slopeAngleRad = math.atan(input.slopeGradient.clamp(-0.35, 0.35));
    final normalForceN =
        totalMassKg * PhysicsConstants.gravity * math.cos(slopeAngleRad);

    final totalRollingPowerWatts = effectiveCrr * normalForceN * speedMs;
    final impedancePenaltyWatts = impedanceLossCrr * normalForceN * speedMs;
    final sinkagePenaltyWatts = looseGravelSinkageCrr * normalForceN * speedMs;

    // 5. Indeks zmęczenia wibracjami oraz ryzyko dobicia obręczy (pinch-flat).
    final overPressureRatio = math.max(
      0.0,
      ((frontP - optimal.frontBar) / optimal.frontBar) * 0.5 +
          ((rearP - optimal.rearBar) / optimal.rearBar) * 0.5,
    );
    final frameDampingBonus =
        (bike.frame.vibrationDampingIndex.clamp(1.0, 5.0) - 3.0) * 0.05;
    final widthComfortBonus = ((avgWidthMm - 40.0) / 10.0) * 0.12;
    final vibrationFatigueIndex = (input.surfaceCategory.vibrationIntensity +
            (overPressureRatio * 0.35) -
            frameDampingBonus -
            widthComfortBonus)
        .clamp(0.05, 1.0);

    final underPressureRatio = math.max(
      0.0,
      ((optimal.rearBar - rearP) / optimal.rearBar),
    );
    final insertShield = bike.tireInserts.isInstalled
        ? bike.tireInserts.pinchFlatProtectionFactor.clamp(0.0, 0.95)
        : 0.0;
    final rawPinchRisk =
        (0.03 + (underPressureRatio * 0.65)) *
            input.surfaceCategory.punctureRiskFactor *
            (1.0 - insertShield);
    final pinchFlatRiskPerHour = rawPinchRisk.clamp(0.0, 0.95);

    // 6. Przyczepność łączna (bieżnik + poprawa z niższego ciśnienia).
    final frontGrip = bike.frontTire.treadPattern
        .gripFactorForSurface(input.surfaceCategory, rain);
    final rearGrip = bike.rearTire.treadPattern
        .gripFactorForSurface(input.surfaceCategory, rain);
    final pressureGripFactor =
        (1.0 + ((optimal.rearBar - rearP) * 0.08)).clamp(0.78, 1.18);
    final gripMultiplier =
        (((frontGrip * 0.45) + (rearGrip * 0.55)) * pressureGripFactor)
            .clamp(0.45, 1.40);

    return GravelImpedanceResult(
      effectiveCrr: effectiveCrr,
      baseHysteresisCrr: baseHysteresisCrr,
      impedanceLossCrr: impedanceLossCrr,
      looseGravelSinkageCrr: looseGravelSinkageCrr,
      totalRollingPowerWatts: totalRollingPowerWatts,
      impedancePenaltyWatts: impedancePenaltyWatts,
      sinkagePenaltyWatts: sinkagePenaltyWatts,
      optimalFrontPressureBar: optimal.frontBar,
      optimalRearPressureBar: optimal.rearBar,
      vibrationFatigueIndex: vibrationFatigueIndex,
      pinchFlatRiskPerHour: pinchFlatRiskPerHour,
      gripMultiplier: gripMultiplier,
      totalSystemMassKg: totalMassKg,
    );
  }

  /// Rozstrzyga zdarzenie przebicia opony na trasie szutrowej:
  /// próba samonaprawy przez mleczko Tubeless w ruchu, a w razie porażki
  /// eskalacja do knota + CO2, jazdy Run-Flat na wkładce Foam Insert lub dętki.
  GravelPunctureResolutionResult resolvePunctureAndSealant(
    GravelPunctureEventInput input,
  ) {
    final bike = input.bikeSetup;
    final tire = input.isFrontWheel ? bike.frontTire : bike.rearTire;
    final punctureMm = input.punctureSizeMm.clamp(0.5, 15.0);

    // Rozcięcie ścianki bocznej jest znacznie trudniejsze do zaklejenia przez mleczko.
    final sidewallEffectiveSizeMm = input.isSidewallCut
        ? (punctureMm * (1.45 / tire.casingType.sidewallCutProtectionMultiplier))
        : punctureMm;

    // Zbyt wysokie ciśnienie (>2.6 bar) utrudnia zakrzepnięcie lateksu/mikrowłókien.
    final highPressurePenalty =
        math.max(0.0, (input.currentTirePressureBar - 2.55) * 0.12);
    final effectiveRoll =
        (input.deterministicRoll01 + highPressurePenalty).clamp(0.0, 1.0);

    final SealantPunctureOutcome sealantOutcome =
        bike.tubelessSealant.consumeSealantForPuncture(
      punctureSizeMm: sidewallEffectiveSizeMm,
      isFrontWheel: input.isFrontWheel,
      deterministicRoll01: effectiveRoll,
    );

    final updatedWithSealant = _copyBikeWithSealantAndPressure(
      bike: bike,
      sealant: sealantOutcome.updatedSealantState,
      isFrontWheel: input.isFrontWheel,
      newPressureBar:
          (input.currentTirePressureBar - sealantOutcome.pressureLostBar)
              .clamp(0.30, 4.50),
    );

    if (sealantOutcome.sealedSuccessfully) {
      final postPressure =
          (input.currentTirePressureBar - sealantOutcome.pressureLostBar)
              .clamp(0.95, 4.50);
      final penaltyWatts = _pressureDropRollingPenaltyWatts(
        bike: updatedWithSealant,
        surface: input.surfaceCategory,
        isFrontWheel: input.isFrontWheel,
        pressureBar: postPressure,
        speedMs: input.speedMetersPerSecond,
      );
      return GravelPunctureResolutionResult(
        resolved: true,
        selfSealedWithoutStopping: true,
        strategy: GravelSealantRepairStrategy.selfSealedInMotion,
        timeLostSeconds: 0.0,
        pressureAfterEventBar: postPressure,
        sealantConsumedMl: sealantOutcome.sealantConsumedMl,
        co2CartridgesUsed: 0,
        plugsUsed: 0,
        spareTubeUsed: false,
        runFlatActive: false,
        postEventRollingPenaltyWatts: penaltyWatts,
        updatedBikeSetup: _copyBikeWithSealantAndPressure(
          bike: bike,
          sealant: sealantOutcome.updatedSealantState,
          isFrontWheel: input.isFrontWheel,
          newPressureBar: postPressure,
        ),
        diagnosticCode: sealantOutcome.reasonCode,
      );
    }

    // Próba naprawy knotem + CO2 (dla przebić bieżnika do 9.5 mm).
    if (!input.isSidewallCut &&
        punctureMm <= 9.5 &&
        input.availableTubelessPlugs > 0 &&
        input.availableCo2Cartridges > 0) {
      final optimal = calculateOptimalGravelPressure(
        bikeSetup: updatedWithSealant,
        surfaceCategory: input.surfaceCategory,
      );
      final restoredPressure =
          input.isFrontWheel ? optimal.frontBar : optimal.rearBar;
      return GravelPunctureResolutionResult(
        resolved: true,
        selfSealedWithoutStopping: false,
        strategy: GravelSealantRepairStrategy.tubelessPlugAndCo2,
        timeLostSeconds: 42.0,
        pressureAfterEventBar: restoredPressure,
        sealantConsumedMl: sealantOutcome.sealantConsumedMl,
        co2CartridgesUsed: 1,
        plugsUsed: 1,
        spareTubeUsed: false,
        runFlatActive: false,
        postEventRollingPenaltyWatts: 0.0,
        updatedBikeSetup: _copyBikeWithSealantAndPressure(
          bike: updatedWithSealant,
          sealant: sealantOutcome.updatedSealantState,
          isFrontWheel: input.isFrontWheel,
          newPressureBar: restoredPressure,
        ),
        diagnosticCode: 'PLUGGED_AND_CO2_INFLATED',
      );
    }

    // Jeśli zainstalowano wkładkę Foam Insert, kolarz może jechać w trybie Run-Flat.
    if (bike.tireInserts.isInstalled &&
        bike.tireInserts.runFlatMaxRangeKm > 0.0) {
      final runFlatRetention =
          bike.tireInserts.runFlatSpeedRetention.clamp(0.40, 0.85);
      final penaltyWatts = (1.0 - runFlatRetention) * 115.0;
      return GravelPunctureResolutionResult(
        resolved: true,
        selfSealedWithoutStopping: false,
        strategy: GravelSealantRepairStrategy.runFlatOnFoamInsert,
        timeLostSeconds: 0.0,
        pressureAfterEventBar: 0.25,
        sealantConsumedMl: sealantOutcome.sealantConsumedMl,
        co2CartridgesUsed: 0,
        plugsUsed: 0,
        spareTubeUsed: false,
        runFlatActive: true,
        postEventRollingPenaltyWatts: penaltyWatts,
        updatedBikeSetup: _copyBikeWithSealantAndPressure(
          bike: updatedWithSealant,
          sealant: sealantOutcome.updatedSealantState,
          isFrontWheel: input.isFrontWheel,
          newPressureBar: 0.25,
        ),
        diagnosticCode: 'RUN_FLAT_ON_FOAM_INSERT',
      );
    }

    // Ostateczność: montaż zapasowej dętki (np. przy dużym rozcięciu ścianki bocznej).
    if (input.hasSpareInnerTube) {
      final co2Used = input.availableCo2Cartridges > 0 ? 1 : 0;
      final tubePressure = input.isFrontWheel ? 2.35 : 2.50;
      return GravelPunctureResolutionResult(
        resolved: true,
        selfSealedWithoutStopping: false,
        strategy: GravelSealantRepairStrategy.spareTubeInstall,
        timeLostSeconds: co2Used > 0 ? 155.0 : 210.0,
        pressureAfterEventBar: tubePressure,
        sealantConsumedMl: sealantOutcome.sealantConsumedMl,
        co2CartridgesUsed: co2Used,
        plugsUsed: 0,
        spareTubeUsed: true,
        runFlatActive: false,
        postEventRollingPenaltyWatts: 3.5,
        updatedBikeSetup: _copyBikeWithSealantAndPressure(
          bike: updatedWithSealant,
          sealant: sealantOutcome.updatedSealantState,
          isFrontWheel: input.isFrontWheel,
          newPressureBar: tubePressure,
        ),
        diagnosticCode: 'SPARE_TUBE_INSTALLED',
      );
    }

    return GravelPunctureResolutionResult(
      resolved: false,
      selfSealedWithoutStopping: false,
      strategy: GravelSealantRepairStrategy.dnfMechanical,
      timeLostSeconds: 0.0,
      pressureAfterEventBar: 0.0,
      sealantConsumedMl: sealantOutcome.sealantConsumedMl,
      co2CartridgesUsed: 0,
      plugsUsed: 0,
      spareTubeUsed: false,
      runFlatActive: false,
      postEventRollingPenaltyWatts: 0.0,
      updatedBikeSetup: _copyBikeWithSealantAndPressure(
        bike: updatedWithSealant,
        sealant: sealantOutcome.updatedSealantState,
        isFrontWheel: input.isFrontWheel,
        newPressureBar: 0.0,
      ),
      diagnosticCode: 'DNF_UNREPAIRABLE_PUNCTURE',
    );
  }

  /// Symuluje uśrednioną fizykę toczenia, odparowanie mleczka w cieple
  /// i oczekiwane straty czasowe na sekwencji segmentów trasy szutrowej.
  GravelStagePhysicsSummary simulateStagePhysics({
    required GravelBikeAndTireInsertsModel bikeSetup,
    required List<GravelCourseSegment> segments,
    double riderMassKg = 72.0,
    double averageSpeedMetersPerSecond = 8.8,
    double rainIntensity = 0.0,
    double ambientTempC = 25.0,
  }) {
    if (segments.isEmpty) {
      final optimal = calculateOptimalGravelPressure(
        bikeSetup: bikeSetup,
        surfaceCategory: GravelSurfaceCategory.cat2CompactedForestRoad,
        riderMassKg: riderMassKg,
        rainIntensity: rainIntensity,
      );
      return GravelStagePhysicsSummary(
        totalDistanceKm: 0.0,
        averageEffectiveCrr: 0.0,
        averageRollingWatts: 0.0,
        totalImpedancePenaltyKilojoules: 0.0,
        expectedPuncturesCount: 0.0,
        expectedTimeLostToMechanicalsSeconds: 0.0,
        sealantRemainingFrontMl: bikeSetup.tubelessSealant.remainingVolumeMlFront,
        sealantRemainingRearMl: bikeSetup.tubelessSealant.remainingVolumeMlRear,
        recommendedFrontPressureBar: optimal.frontBar,
        recommendedRearPressureBar: optimal.rearBar,
      );
    }

    double totalDistKm = 0.0;
    double weightedCrrSum = 0.0;
    double weightedWattsSum = 0.0;
    double totalImpedanceKj = 0.0;
    double expectedPunctures = 0.0;
    double expectedTimeLostSec = 0.0;
    double totalDurationHours = 0.0;

    final speed = averageSpeedMetersPerSecond.clamp(2.5, 16.0);

    for (final seg in segments) {
      final segKm = seg.lengthKm.clamp(0.1, 300.0);
      final segMeters = segKm * 1000.0;
      final segDurationSec = segMeters / speed;
      final segDurationHours = segDurationSec / 3600.0;

      final res = solveRollingResistance(
        GravelImpedanceInput(
          bikeSetup: bikeSetup,
          surfaceCategory: seg.surfaceCategory,
          speedMetersPerSecond: speed,
          riderMassKg: riderMassKg,
          rainIntensity: rainIntensity,
          slopeGradient: seg.gradientPercent / 100.0,
          ambientTempC: ambientTempC,
        ),
      );

      totalDistKm += segKm;
      totalDurationHours += segDurationHours;
      weightedCrrSum += res.effectiveCrr * segKm;
      weightedWattsSum += res.totalRollingPowerWatts * segKm;
      totalImpedanceKj += (res.impedancePenaltyWatts * segDurationSec) / 1000.0;

      // Bazowe prawdopodobieństwo przebicia na 100 km zależne od nawierzchni i oplotu.
      final avgProtection =
          (bikeSetup.frontTire.punctureResistanceIndex +
                  bikeSetup.rearTire.punctureResistanceIndex) *
              0.5;
      final casingShield =
          bikeSetup.frontTire.casingType.sidewallCutProtectionMultiplier;
      final segPunctureRate = (segKm / 100.0) *
          0.32 *
          seg.surfaceCategory.punctureRiskFactor /
          ((avgProtection / 3.2) * casingShield);

      expectedPunctures += segPunctureRate;

      final sealProb = bikeSetup.tubelessSealant.estimateSealProbability(
        punctureSizeMm: 3.2,
        isFrontWheel: false,
      );
      expectedTimeLostSec += segPunctureRate * (1.0 - sealProb) * 42.0;
    }

    final evaporatedSealant = bikeSetup.tubelessSealant.applyHeatEvaporation(
      durationHours: totalDurationHours,
      ambientTempC: ambientTempC,
    );

    final dominantSurface = segments.reduce(
      (a, b) => a.lengthKm >= b.lengthKm ? a : b,
    ).surfaceCategory;
    final recommended = calculateOptimalGravelPressure(
      bikeSetup: bikeSetup,
      surfaceCategory: dominantSurface,
      riderMassKg: riderMassKg,
      rainIntensity: rainIntensity,
    );

    return GravelStagePhysicsSummary(
      totalDistanceKm: totalDistKm,
      averageEffectiveCrr: weightedCrrSum / totalDistKm,
      averageRollingWatts: weightedWattsSum / totalDistKm,
      totalImpedancePenaltyKilojoules: totalImpedanceKj,
      expectedPuncturesCount: expectedPunctures,
      expectedTimeLostToMechanicalsSeconds: expectedTimeLostSec,
      sealantRemainingFrontMl: evaporatedSealant.remainingVolumeMlFront,
      sealantRemainingRearMl: evaporatedSealant.remainingVolumeMlRear,
      recommendedFrontPressureBar: recommended.frontBar,
      recommendedRearPressureBar: recommended.rearBar,
    );
  }

  double _tireHysteresisCrr({
    required GravelTireSpec tire,
    required double actualBar,
    required double optimalBar,
    required FoamTireInsertSpec insert,
  }) {
    final base = tire.baseCrr *
        tire.treadPattern.treadCrrFactor *
        tire.casingType.casingCrrMultiplier;
    final underInflationRatio = (optimalBar / actualBar.clamp(0.4, 5.0));
    final hysteresisScale = underInflationRatio > 1.0
        ? math.pow(underInflationRatio, 0.24).toDouble()
        : math.pow(underInflationRatio, 0.10).toDouble();
    final insertPenalty =
        insert.isInstalled ? insert.hysteresisRollingPenaltyCrr : 0.0;
    return (base * hysteresisScale) + insertPenalty;
  }

  double _wheelImpedanceCrr({
    required double actualBar,
    required double optimalBar,
    required GravelSurfaceCategory surface,
    required double speedMs,
  }) {
    final baseVibrationCrr = surface.vibrationIntensity * 0.0014;
    if (actualBar <= optimalBar) {
      return baseVibrationCrr;
    }
    final overRatio = ((actualBar - optimalBar) / optimalBar).clamp(0.0, 1.5);
    final speedFactor = math.pow((speedMs / 8.0).clamp(0.25, 2.5), 0.45);
    final impedanceSpike = (surface.crrMultiplier - 1.0) *
        0.0068 *
        math.pow(overRatio, 1.65) *
        speedFactor;
    return baseVibrationCrr + impedanceSpike;
  }

  double _defaultLooseDepthCm(
    GravelSurfaceCategory surface,
    double rainIntensity,
  ) {
    switch (surface) {
      case GravelSurfaceCategory.cat1ChampagneGravel:
        return 0.4 + (rainIntensity * 0.3);
      case GravelSurfaceCategory.cat2CompactedForestRoad:
        return 0.9 + (rainIntensity * 0.5);
      case GravelSurfaceCategory.cat3LooseWashboardsAndRuts:
        return 2.6 + (rainIntensity * 0.6);
      case GravelSurfaceCategory.cat4SharpFlintAndChunkyRock:
        return 3.2 + (rainIntensity * 0.5);
      case GravelSurfaceCategory.cat5TechnicalSingletrackAndMud:
        return 4.1 + (rainIntensity * 1.8);
    }
  }

  double _pressureDropRollingPenaltyWatts({
    required GravelBikeAndTireInsertsModel bike,
    required GravelSurfaceCategory surface,
    required bool isFrontWheel,
    required double pressureBar,
    required double speedMs,
  }) {
    final baseline = solveRollingResistance(
      GravelImpedanceInput(
        bikeSetup: bike,
        surfaceCategory: surface,
        speedMetersPerSecond: speedMs,
      ),
    );
    final degraded = solveRollingResistance(
      GravelImpedanceInput(
        bikeSetup: bike,
        surfaceCategory: surface,
        speedMetersPerSecond: speedMs,
        overrideFrontPressureBar: isFrontWheel ? pressureBar : null,
        overrideRearPressureBar: isFrontWheel ? null : pressureBar,
      ),
    );
    return math.max(
      0.0,
      degraded.totalRollingPowerWatts - baseline.totalRollingPowerWatts,
    );
  }

  double _totalBikeWeightKg(GravelBikeAndTireInsertsModel bike) {
    final totalGrams = bike.frame.frameWeightGrams +
        bike.frontTire.weightGramsPerTire +
        bike.rearTire.weightGramsPerTire +
        bike.wheelsetWeightGrams +
        bike.groupsetWeightGrams +
        bike.cockpitAndSaddleWeightGrams;
    return (totalGrams / 1000.0) +
        bike.tireInserts.totalWeightKg +
        bike.tubelessSealant.totalWeightKg +
        (bike.currentFrameBottlesFluidMl / 1000.0) +
        (bike.hydrationPack.dryWeightGrams / 1000.0) +
        (bike.hydrationPack.currentFluidMl / 1000.0) +
        bike.mudAccumulationKg;
  }

  GravelBikeAndTireInsertsModel _copyBikeWithSealantAndPressure({
    required GravelBikeAndTireInsertsModel bike,
    required TubelessSealantSpec sealant,
    required bool isFrontWheel,
    required double newPressureBar,
  }) {
    return GravelBikeAndTireInsertsModel(
      id: bike.id,
      name: bike.name,
      frame: bike.frame,
      frontTire: bike.frontTire,
      rearTire: bike.rearTire,
      frontPressureBar: isFrontWheel ? newPressureBar : bike.frontPressureBar,
      rearPressureBar: isFrontWheel ? bike.rearPressureBar : newPressureBar,
      tireInserts: bike.tireInserts,
      tubelessSealant: sealant,
      hydrationPack: bike.hydrationPack,
      wheelsetWeightGrams: bike.wheelsetWeightGrams,
      groupsetWeightGrams: bike.groupsetWeightGrams,
      cockpitAndSaddleWeightGrams: bike.cockpitAndSaddleWeightGrams,
      frameBottlesCapacityMl: bike.frameBottlesCapacityMl,
      currentFrameBottlesFluidMl: bike.currentFrameBottlesFluidMl,
      mudAccumulationKg: bike.mudAccumulationKg,
    );
  }
}
