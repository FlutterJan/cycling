// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

/// Status gospodarki wodno-elektrolitowej kolarza podczas etapu.
enum HydrationElectrolyteStatus {
  /// Pełne nawodnienie i równowaga sodowa (< 1.5% odwodnienia masy ciała).
  optimal,

  /// Umiarkowane odwodnienie (1.5% - 3.0% masy ciała) lub lekki deficyt sodu.
  mildDehydration,

  /// Krytyczne odwodnienie (> 3.0% masy ciała) lub głęboki niedobór sodu.
  criticalDepletion,

  /// Aktywne bolesne skurcze mięśni (Muscle Cramps) blokujące sprint na ostatnich kilometrach.
  muscleCramps,
}

/// Rodzaj przyjmowanego płynu lub suplementu elektrolitowego.
enum ElectrolyteSupplementType {
  /// Czysta woda (uzupełnia płyny, ale nie dostarcza sodu).
  plainWater,

  /// Napój izotoniczny w bidonie (umiarkowana dawka sodu).
  isotonicDrink,

  /// Tabletka elektrolitowa (wysoka dawka sodu przeciwdziałająca skurczom).
  electrolyteTablet,

  /// Kapsułka solna o skoncentrowanej zawartości sodu.
  saltCapsule,
}

/// Zdarzenie spożycia płynu i/lub elektrolitów w pojedynczym kroku symulacji.
class ElectrolyteIntakeEvent {
  /// Objętość przyjętego płynu [ml].
  final double fluidMl;

  /// Ilość dostarczonego sodu [mg].
  final double sodiumMg;

  /// Typ przyjętego suplementu / płynu.
  final ElectrolyteSupplementType supplementType;

  const ElectrolyteIntakeEvent({
    required this.fluidMl,
    required this.sodiumMg,
    required this.supplementType,
  });

  /// Standardowy bidon czystej wody (500 ml, 0 mg sodu).
  factory ElectrolyteIntakeEvent.plainWaterBidon({double volumeMl = 500.0}) {
    return ElectrolyteIntakeEvent(
      fluidMl: math.max(0.0, volumeMl),
      sodiumMg: 0.0,
      supplementType: ElectrolyteSupplementType.plainWater,
    );
  }

  /// Bidon napoju izotonicznego (domyślnie 500 ml przy stężeniu 400 mg Na/l).
  factory ElectrolyteIntakeEvent.isotonicBidon({
    double volumeMl = 500.0,
    double sodiumPerLiterMg = 400.0,
  }) {
    final double safeVolume = math.max(0.0, volumeMl);
    final double safeConc = math.max(0.0, sodiumPerLiterMg);
    return ElectrolyteIntakeEvent(
      fluidMl: safeVolume,
      sodiumMg: (safeVolume / 1000.0) * safeConc,
      supplementType: ElectrolyteSupplementType.isotonicDrink,
    );
  }

  /// Tabletka elektrolitowa rozpuszczona w bidonie lub popita wodą.
  factory ElectrolyteIntakeEvent.electrolyteTablet({
    double fluidMl = 500.0,
    double tabletSodiumMg =
        SweatSodiumElectrolyteDepletion.defaultElectrolyteTabletSodiumMg,
  }) {
    return ElectrolyteIntakeEvent(
      fluidMl: math.max(0.0, fluidMl),
      sodiumMg: math.max(0.0, tabletSodiumMg),
      supplementType: ElectrolyteSupplementType.electrolyteTablet,
    );
  }

  /// Skoncentrowana kapsułka solna popita małą ilością wody.
  factory ElectrolyteIntakeEvent.saltCapsule({
    double capsuleSodiumMg = 750.0,
    double fluidMl = 150.0,
  }) {
    return ElectrolyteIntakeEvent(
      fluidMl: math.max(0.0, fluidMl),
      sodiumMg: math.max(0.0, capsuleSodiumMg),
      supplementType: ElectrolyteSupplementType.saltCapsule,
    );
  }

  /// Czy zdarzenie dostarcza dedykowanej suplementacji tabletką lub kapsułką elektrolitową.
  bool get isElectrolyteTabletOrCapsule =>
      supplementType == ElectrolyteSupplementType.electrolyteTablet ||
      supplementType == ElectrolyteSupplementType.saltCapsule;
}

/// Indywidualny profil fizjologiczny pocenia się i utraty sodu przez kolarza.
class RiderSweatProfile {
  /// Indywidualne bazowe tempo pocenia się w warunkach wysiłkowych [0.8 - 2.5 l/h].
  final double baseSweatRateLitersPerHour;

  /// Indywidualne stężenie sodu w pocie [500.0 - 1500.0 mg/l].
  final double sweatSodiumConcentrationMgPerL;

  /// Masa ciała kolarza [kg].
  final double riderMassKg;

  /// Początkowa buforowa rezerwa sodu dostępna podczas wysiłku [mg].
  final double initialSodiumReserveMg;

  /// Poziom aklimatyzacji cieplnej [0.0 - 1.0] (zmniejsza stężenie sodu w pocie).
  final double heatAcclimatization;

  RiderSweatProfile({
    double baseSweatRateLitersPerHour = 1.4,
    double sweatSodiumConcentrationMgPerL = 950.0,
    double riderMassKg = 68.0,
    double? initialSodiumReserveMg,
    double heatAcclimatization = 0.0,
  })  : baseSweatRateLitersPerHour = baseSweatRateLitersPerHour.clamp(
          SweatSodiumElectrolyteDepletion.minSweatRateLitersPerHour,
          SweatSodiumElectrolyteDepletion.maxSweatRateLitersPerHour,
        ),
        sweatSodiumConcentrationMgPerL =
            sweatSodiumConcentrationMgPerL.clamp(
          SweatSodiumElectrolyteDepletion.minSweatSodiumMgPerL,
          SweatSodiumElectrolyteDepletion.maxSweatSodiumMgPerL,
        ),
        riderMassKg = math.max(40.0, riderMassKg),
        initialSodiumReserveMg = math.max(
          800.0,
          initialSodiumReserveMg ??
              (math.max(40.0, riderMassKg) *
                  SweatSodiumElectrolyteDepletion.initialSodiumReserveMgPerKg),
        ),
        heatAcclimatization = heatAcclimatization.clamp(0.0, 1.0);
}

/// Stan gospodarki wodno-elektrolitowej utrzymywany pomiędzy krokami symulacji.
class SweatElectrolyteState {
  /// Skumulowana objętość potu utraconego od startu etapu [ml].
  final double cumulativeSweatLossMl;

  /// Skumulowana objętość płynów przyjętych od startu etapu [ml].
  final double cumulativeFluidIntakeMl;

  /// Skumulowana masa sodu utraconego z potem [mg].
  final double cumulativeSodiumLossMg;

  /// Skumulowana masa sodu przyjętego z napojami i tabletkami [mg].
  final double cumulativeSodiumIntakeMg;

  /// Aktualna dostępna rezerwa sodu buforująca wysiłek [mg].
  final double availableSodiumReserveMg;

  /// Liczba przyjętych tabletek elektrolitowych lub kapsułek solnych.
  final int electrolyteTabletsTaken;

  /// Czy kolarz ma aktualnie aktywne skurcze mięśni (Muscle Cramps).
  final bool hasMuscleCramps;

  /// Nasilenie skurczów mięśni w skali [0.0 - 1.0].
  final double crampSeverity;

  /// Łączny czas spędzony ze skurczami mięśni [s].
  final double crampDurationSeconds;

  const SweatElectrolyteState({
    this.cumulativeSweatLossMl = 0.0,
    this.cumulativeFluidIntakeMl = 0.0,
    this.cumulativeSodiumLossMg = 0.0,
    this.cumulativeSodiumIntakeMg = 0.0,
    this.availableSodiumReserveMg = 2720.0,
    this.electrolyteTabletsTaken = 0,
    this.hasMuscleCramps = false,
    this.crampSeverity = 0.0,
    this.crampDurationSeconds = 0.0,
  });

  /// Stan początkowy dopasowany do indywidualnego profilu kolarza.
  factory SweatElectrolyteState.initial(RiderSweatProfile profile) {
    return SweatElectrolyteState(
      availableSodiumReserveMg: profile.initialSodiumReserveMg,
    );
  }

  /// Aktualny deficyt płynów netto [ml] (>= 0.0).
  double get netFluidDeficitMl =>
      math.max(0.0, cumulativeSweatLossMl - cumulativeFluidIntakeMl);

  /// Aktualny deficyt sodu netto [mg] (>= 0.0).
  double get netSodiumDeficitMg =>
      math.max(0.0, cumulativeSodiumLossMg - cumulativeSodiumIntakeMg);

  /// Procentowe odwodnienie masy ciała [%] dla zadanej masy kolarza.
  double dehydrationBodyMassPercent(double riderMassKg) {
    return SweatSodiumElectrolyteDepletion.calculateDehydrationPercent(
      netFluidDeficitMl: netFluidDeficitMl,
      riderMassKg: riderMassKg,
    );
  }

  SweatElectrolyteState copyWith({
    double? cumulativeSweatLossMl,
    double? cumulativeFluidIntakeMl,
    double? cumulativeSodiumLossMg,
    double? cumulativeSodiumIntakeMg,
    double? availableSodiumReserveMg,
    int? electrolyteTabletsTaken,
    bool? hasMuscleCramps,
    double? crampSeverity,
    double? crampDurationSeconds,
  }) {
    return SweatElectrolyteState(
      cumulativeSweatLossMl:
          cumulativeSweatLossMl ?? this.cumulativeSweatLossMl,
      cumulativeFluidIntakeMl:
          cumulativeFluidIntakeMl ?? this.cumulativeFluidIntakeMl,
      cumulativeSodiumLossMg:
          cumulativeSodiumLossMg ?? this.cumulativeSodiumLossMg,
      cumulativeSodiumIntakeMg:
          cumulativeSodiumIntakeMg ?? this.cumulativeSodiumIntakeMg,
      availableSodiumReserveMg:
          availableSodiumReserveMg ?? this.availableSodiumReserveMg,
      electrolyteTabletsTaken:
          electrolyteTabletsTaken ?? this.electrolyteTabletsTaken,
      hasMuscleCramps: hasMuscleCramps ?? this.hasMuscleCramps,
      crampSeverity: crampSeverity ?? this.crampSeverity,
      crampDurationSeconds:
          crampDurationSeconds ?? this.crampDurationSeconds,
    );
  }
}

/// Parametry wejściowe pojedynczego kroku modelu gospodarki wodno-elektrolitowej.
class SweatElectrolyteStepInput {
  /// Czas trwania kroku symulacji [s].
  final double deltaTimeSeconds;

  /// Aktualna moc generowana przez kolarza [W].
  final double powerWatts;

  /// Progowa moc funkcjonalna FTP kolarza [W].
  final double ftpWatts;

  /// Temperatura otoczenia [°C].
  final double ambientTemperatureCelsius;

  /// Względna wilgotność powietrza [0.0 - 1.0].
  final double relativeHumidity;

  /// Aktualna temperatura głęboka ciała [°C].
  final double coreBodyTemperatureCelsius;

  /// Dystans pozostały do linii mety [m].
  final double distanceToFinishMeters;

  /// Czy kolarz próbuje obecnie sprintować lub generuje szczytowy moment obrotowy.
  final bool isSprintingOrHighTorque;

  /// Lista przyjętych w tym kroku płynów i tabletek elektrolitowych.
  final List<ElectrolyteIntakeEvent> intakes;

  const SweatElectrolyteStepInput({
    required this.deltaTimeSeconds,
    required this.powerWatts,
    this.ftpWatts = 350.0,
    this.ambientTemperatureCelsius = 24.0,
    this.relativeHumidity = 0.50,
    this.coreBodyTemperatureCelsius = 37.8,
    this.distanceToFinishMeters = 50000.0,
    this.isSprintingOrHighTorque = false,
    this.intakes = const <ElectrolyteIntakeEvent>[],
  });
}

/// Wynik pojedynczego kroku obliczeń gospodarki wodno-elektrolitowej.
class SweatElectrolyteStepResult {
  /// Zaktualizowany stan wodno-elektrolitowy kolarza.
  final SweatElectrolyteState updatedState;

  /// Efektywne tempo pocenia się w tym kroku [l/h] (w granicach [0.8, 2.5] l/h).
  final double effectiveSweatRateLitersPerHour;

  /// Efektywne stężenie sodu w pocie [mg/l] (w granicach [500, 1500] mg/l).
  final double effectiveSweatSodiumMgPerL;

  /// Objętość potu utracona w tym kroku [ml].
  final double sweatLossStepMl;

  /// Masa sodu utracona w tym kroku [mg].
  final double sodiumLossStepMg;

  /// Procentowe odwodnienie masy ciała [%].
  final double dehydrationPercent;

  /// Aktualny deficyt sodu netto [mg].
  final double netSodiumDeficitMg;

  /// Czy odwodnienie przekroczyło próg krytyczny (> 3.0% masy ciała).
  final bool isDehydrationAboveCrampThreshold;

  /// Czy rezerwa sodu spadła poniżej progu krytycznego bez wsparcia tabletek elektrolitowych.
  final bool isSodiumCriticallyDepleted;

  /// Czy wystąpiły bolesne skurcze mięśni (`Muscle Cramps`).
  final bool hasMuscleCramps;

  /// Czy sprint na ostatnich kilometrach jest zablokowany przez `Muscle Cramps`.
  final bool isSprintBlocked;

  /// Mnożnik maksymalnej mocy sprintu ([0.45 - 1.0]).
  final double sprintPowerCapMultiplier;

  /// Mnożnik mocy ciągłej/progowej ([0.75 - 1.0]).
  final double sustainedPowerMultiplier;

  /// Dryf tętna wynikający z odwodnienia [BPM].
  final double heartRateDriftBpm;

  /// Zbiorczy status nawodnienia i równowagi elektrolitowej.
  final HydrationElectrolyteStatus status;

  const SweatElectrolyteStepResult({
    required this.updatedState,
    required this.effectiveSweatRateLitersPerHour,
    required this.effectiveSweatSodiumMgPerL,
    required this.sweatLossStepMl,
    required this.sodiumLossStepMg,
    required this.dehydrationPercent,
    required this.netSodiumDeficitMg,
    required this.isDehydrationAboveCrampThreshold,
    required this.isSodiumCriticallyDepleted,
    required this.hasMuscleCramps,
    required this.isSprintBlocked,
    required this.sprintPowerCapMultiplier,
    required this.sustainedPowerMultiplier,
    required this.heartRateDriftBpm,
    required this.status,
  });
}

/// Naukowy model gospodarki wodno-elektrolitowej (pot, sód i skurcze mięśni).
///
/// Modeluje:
/// - indywidualne tempo pocenia się (`0.8 - 2.5 l/h`) zależne od profilu,
///   temperatury, wilgotności i intensywności wysiłku,
/// - indywidualne stężenie sodu w pocie (`500 - 1500 mg/l`),
/// - wpływ nawadniania wodą, izotonikiem oraz tabletkami elektrolitowymi,
/// - bolesne skurcze mięśni (`Muscle Cramps`) wywoływane przez odwodnienie
///   powyżej `3.0%` masy ciała lub niedobór sodu bez tabletek elektrolitowych,
///   blokujące sprint na ostatnich kilometrach.
class SweatSodiumElectrolyteDepletion {
  SweatSodiumElectrolyteDepletion._();

  /// Minimalne fizjologiczne tempo pocenia się podczas wysiłku [l/h].
  static const double minSweatRateLitersPerHour = 0.8;

  /// Maksymalne fizjologiczne tempo pocenia się podczas wysiłku [l/h].
  static const double maxSweatRateLitersPerHour = 2.5;

  /// Minimalne indywidualne stężenie sodu w pocie [mg/l].
  static const double minSweatSodiumMgPerL = 500.0;

  /// Maksymalne indywidualne stężenie sodu w pocie [mg/l].
  static const double maxSweatSodiumMgPerL = 1500.0;

  /// Próg odwodnienia masy ciała wywołujący skurcze mięśni [%].
  static const double criticalDehydrationPercent = 3.0;

  /// Początkowa rezerwa sodu przypadająca na 1 kg masy ciała [mg/kg].
  static const double initialSodiumReserveMgPerKg = 40.0;

  /// Krytyczny próg rezerwy sodu [mg], poniżej którego bez tabletek występują skurcze.
  static const double criticalSodiumReserveThresholdMg = 600.0;

  /// Domyślna dawka sodu w jednej tabletce elektrolitowej [mg].
  static const double defaultElectrolyteTabletSodiumMg = 500.0;

  /// Strefa ostatnich kilometrów etapu, w której skurcze blokują sprint [m].
  static const double finalKilometersSprintZoneMeters = 5000.0;

  /// Oblicza efektywne tempo pocenia się [l/h] w zakresie [0.8, 2.5] l/h.
  static double calculateEffectiveSweatRateLitersPerHour({
    required RiderSweatProfile profile,
    required double powerWatts,
    double ftpWatts = 350.0,
    double ambientTemperatureCelsius = 24.0,
    double relativeHumidity = 0.50,
    double coreBodyTemperatureCelsius = 37.8,
  }) {
    final double safeFtp = math.max(120.0, ftpWatts);
    final double intensityRatio =
        (math.max(0.0, powerWatts) / safeFtp).clamp(0.25, 1.8);

    // Wzrost temperatury otoczenia powyżej 20 °C i wysoka temperatura głęboka nasilają pocenie.
    final double tempFactor =
        1.0 + ((ambientTemperatureCelsius - 20.0).clamp(-10.0, 22.0) * 0.022);
    final double coreTempFactor =
        1.0 + ((coreBodyTemperatureCelsius - 37.5).clamp(0.0, 3.0) * 0.14);
    final double humidityFactor =
        1.0 + ((relativeHumidity.clamp(0.0, 1.0) - 0.5) * 0.10);
    final double intensityFactor = (0.65 + (intensityRatio * 0.45)).clamp(
      0.70,
      1.35,
    );

    final double rawRate = profile.baseSweatRateLitersPerHour *
        tempFactor *
        coreTempFactor *
        humidityFactor *
        intensityFactor;

    return rawRate.clamp(
      minSweatRateLitersPerHour,
      maxSweatRateLitersPerHour,
    );
  }

  /// Oblicza efektywne stężenie sodu w pocie [mg/l] w zakresie [500, 1500] mg/l.
  ///
  /// Aklimatyzacja cieplna pozwala kolarzowi oszczędzać sód w pocie nawet do 18%.
  static double calculateEffectiveSweatSodiumMgPerL({
    required RiderSweatProfile profile,
  }) {
    final double acclimatizationDiscount =
        1.0 - (profile.heatAcclimatization.clamp(0.0, 1.0) * 0.18);
    final double effective =
        profile.sweatSodiumConcentrationMgPerL * acclimatizationDiscount;
    return effective.clamp(minSweatSodiumMgPerL, maxSweatSodiumMgPerL);
  }

  /// Oblicza procentowe odwodnienie masy ciała [%].
  static double calculateDehydrationPercent({
    required double netFluidDeficitMl,
    required double riderMassKg,
  }) {
    final double safeMassKg = math.max(40.0, riderMassKg);
    final double deficitKg = math.max(0.0, netFluidDeficitMl) / 1000.0;
    return (deficitKg / safeMassKg) * 100.0;
  }

  /// Wykonuje pojedynczy krok symulacji gospodarki wodno-elektrolitowej.
  static SweatElectrolyteStepResult step({
    required RiderSweatProfile profile,
    required SweatElectrolyteState currentState,
    required SweatElectrolyteStepInput input,
  }) {
    final double dt = math.max(0.0, input.deltaTimeSeconds);

    final double sweatRateLph = calculateEffectiveSweatRateLitersPerHour(
      profile: profile,
      powerWatts: input.powerWatts,
      ftpWatts: input.ftpWatts,
      ambientTemperatureCelsius: input.ambientTemperatureCelsius,
      relativeHumidity: input.relativeHumidity,
      coreBodyTemperatureCelsius: input.coreBodyTemperatureCelsius,
    );

    final double sweatSodiumMgPerL =
        calculateEffectiveSweatSodiumMgPerL(profile: profile);

    final double sweatLossStepMl = sweatRateLph * 1000.0 * (dt / 3600.0);
    final double sodiumLossStepMg =
        (sweatLossStepMl / 1000.0) * sweatSodiumMgPerL;

    double fluidIntakeStepMl = 0.0;
    double sodiumIntakeStepMg = 0.0;
    int tabletsTakenStep = 0;

    for (final ElectrolyteIntakeEvent intake in input.intakes) {
      fluidIntakeStepMl += math.max(0.0, intake.fluidMl);
      sodiumIntakeStepMg += math.max(0.0, intake.sodiumMg);
      if (intake.isElectrolyteTabletOrCapsule) {
        tabletsTakenStep += 1;
      }
    }

    final double updatedSweatLossMl =
        currentState.cumulativeSweatLossMl + sweatLossStepMl;
    final double updatedFluidIntakeMl =
        currentState.cumulativeFluidIntakeMl + fluidIntakeStepMl;
    final double updatedSodiumLossMg =
        currentState.cumulativeSodiumLossMg + sodiumLossStepMg;
    final double updatedSodiumIntakeMg =
        currentState.cumulativeSodiumIntakeMg + sodiumIntakeStepMg;
    final int updatedTabletsTaken =
        currentState.electrolyteTabletsTaken + tabletsTakenStep;

    final double updatedSodiumReserveMg = math.max(
      0.0,
      currentState.availableSodiumReserveMg -
          sodiumLossStepMg +
          sodiumIntakeStepMg,
    );

    final double netFluidDeficitMl =
        math.max(0.0, updatedSweatLossMl - updatedFluidIntakeMl);
    final double dehydrationPercent = calculateDehydrationPercent(
      netFluidDeficitMl: netFluidDeficitMl,
      riderMassKg: profile.riderMassKg,
    );

    final double netSodiumDeficitMg =
        math.max(0.0, updatedSodiumLossMg - updatedSodiumIntakeMg);

    final bool dehydrationTriggered =
        dehydrationPercent > criticalDehydrationPercent;

    // Niedobór sodu bez tabletek elektrolitowych wywołuje skurcze, gdy rezerwa
    // spadnie poniżej progu krytycznego i kolarz nie stosował suplementacji tabletkami
    // lub mimo późniejszego przyjęcia nie odbudował jeszcze bezpiecznej rezerwy.
    final bool sodiumCriticallyLow =
        updatedSodiumReserveMg <= criticalSodiumReserveThresholdMg;
    final bool sodiumDepletionWithoutTablets =
        sodiumCriticallyLow && updatedTabletsTaken == 0;

    // Dodatkowe ryzyko: nawet przy wcześniejszej tabletce skrajne wyczerpanie sodu
    // (< 250 mg rezerwy) również prowadzi do skurczów.
    final bool extremeSodiumCollapse = updatedSodiumReserveMg < 250.0;

    bool hasCramps = dehydrationTriggered ||
        sodiumDepletionWithoutTablets ||
        extremeSodiumCollapse;

    // Jeśli kolarz miał skurcze, a nawodnienie wróciło <= 2.7% i rezerwa sodu > 900 mg
    // (np. po podaniu tabletek elektrolitowych i bidonu), skurcze ustępują.
    if (currentState.hasMuscleCramps && !hasCramps) {
      final bool recoveredHydration = dehydrationPercent <= 2.7;
      final bool recoveredSodium = updatedSodiumReserveMg > 900.0;
      if (!(recoveredHydration && recoveredSodium)) {
        hasCramps = true;
      }
    }

    double crampSeverity = 0.0;
    if (hasCramps) {
      final double dehydrationExcess =
          math.max(0.0, dehydrationPercent - criticalDehydrationPercent) / 2.0;
      final double sodiumShortfall = math.max(
            0.0,
            criticalSodiumReserveThresholdMg - updatedSodiumReserveMg,
          ) /
          criticalSodiumReserveThresholdMg;
      final double sprintLoadBoost = input.isSprintingOrHighTorque ? 0.25 : 0.0;
      crampSeverity = (0.45 +
              dehydrationExcess * 0.35 +
              sodiumShortfall * 0.40 +
              sprintLoadBoost)
          .clamp(0.35, 1.0);
    }

    final bool inFinalKilometers =
        input.distanceToFinishMeters <= finalKilometersSprintZoneMeters;
    final bool isSprintBlocked = hasCramps && inFinalKilometers;

    final double sprintPowerCapMultiplier = hasCramps
        ? (isSprintBlocked
            ? (0.55 - crampSeverity * 0.15).clamp(0.40, 0.55)
            : (0.72 - crampSeverity * 0.15).clamp(0.55, 0.72))
        : (dehydrationPercent > 2.0
            ? (1.0 - (dehydrationPercent - 2.0) * 0.06).clamp(0.88, 1.0)
            : 1.0);

    final double sustainedPowerMultiplier = hasCramps
        ? (0.86 - crampSeverity * 0.11).clamp(0.75, 0.86)
        : (dehydrationPercent > 1.5
            ? (1.0 - (dehydrationPercent - 1.5) * 0.04).clamp(0.90, 1.0)
            : 1.0);

    // Dryf tętna rośnie liniowo powyżej 1.5% odwodnienia masy ciała.
    final double heartRateDriftBpm = dehydrationPercent > 1.5
        ? ((dehydrationPercent - 1.5) * 4.5).clamp(0.0, 14.0)
        : 0.0;

    final HydrationElectrolyteStatus status;
    if (hasCramps) {
      status = HydrationElectrolyteStatus.muscleCramps;
    } else if (dehydrationPercent >= 2.5 || sodiumCriticallyLow) {
      status = HydrationElectrolyteStatus.criticalDepletion;
    } else if (dehydrationPercent >= 1.5 ||
        updatedSodiumReserveMg < profile.initialSodiumReserveMg * 0.5) {
      status = HydrationElectrolyteStatus.mildDehydration;
    } else {
      status = HydrationElectrolyteStatus.optimal;
    }

    final SweatElectrolyteState updatedState = currentState.copyWith(
      cumulativeSweatLossMl: updatedSweatLossMl,
      cumulativeFluidIntakeMl: updatedFluidIntakeMl,
      cumulativeSodiumLossMg: updatedSodiumLossMg,
      cumulativeSodiumIntakeMg: updatedSodiumIntakeMg,
      availableSodiumReserveMg: updatedSodiumReserveMg,
      electrolyteTabletsTaken: updatedTabletsTaken,
      hasMuscleCramps: hasCramps,
      crampSeverity: crampSeverity,
      crampDurationSeconds:
          currentState.crampDurationSeconds + (hasCramps ? dt : 0.0),
    );

    return SweatElectrolyteStepResult(
      updatedState: updatedState,
      effectiveSweatRateLitersPerHour: sweatRateLph,
      effectiveSweatSodiumMgPerL: sweatSodiumMgPerL,
      sweatLossStepMl: sweatLossStepMl,
      sodiumLossStepMg: sodiumLossStepMg,
      dehydrationPercent: dehydrationPercent,
      netSodiumDeficitMg: netSodiumDeficitMg,
      isDehydrationAboveCrampThreshold: dehydrationTriggered,
      isSodiumCriticallyDepleted: sodiumCriticallyLow,
      hasMuscleCramps: hasCramps,
      isSprintBlocked: isSprintBlocked,
      sprintPowerCapMultiplier: sprintPowerCapMultiplier,
      sustainedPowerMultiplier: sustainedPowerMultiplier,
      heartRateDriftBpm: heartRateDriftBpm,
      status: status,
    );
  }
}
