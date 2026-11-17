// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import '../../core/constants/physics_constants.dart';
import '../../models/race/velodrome_track_and_hour_record_model.dart';

/// Sekcja geometryczna standardowego welodromu 250 m.
enum VelodromeTrackSection {
  /// Prosta startowa / przeciwległa (nachylenie ~12°–14°).
  straight('Prosta', 'Straight'),

  /// Strefa przejściowa (klotoida wejścia w wiraż).
  transitionEntry('Wejście w wiraż', 'Turn Entry'),

  /// Wierzchołek wirażu o maksymalnym pochyleniu (42°–45°).
  turnApex('Wiraż', 'Turn Apex'),

  /// Strefa wyjścia z wiraża na prostą.
  transitionExit('Wyjście z wiraża', 'Turn Exit');

  final String labelPl;
  final String labelEn;

  const VelodromeTrackSection(this.labelPl, this.labelEn);
}

/// Linia jazdy kolarza na drewnianym torze względem czarnej linii pomiarowej.
enum VelodromeTrackLine {
  /// Czarna linia pomiarowa (20 cm od wewnętrznej krawędzi) — dokładne 250.0 m.
  measurementBlackLine(
    'Czarna linia pomiarowa',
    'Black Measurement Line',
    0.0,
    250.0,
  ),

  /// Czerwona linia sprinterska (+0.9 m powyżej czarnej linii).
  sprinterRedLine(
    'Czerwona linia sprinterska',
    'Red Sprinter Line',
    0.90,
    253.2,
  ),

  /// Niebieska linia stayerska (+2.45 m — środek wiraża).
  stayerBlueLine(
    'Niebieska linia stayerska',
    'Blue Stayer Line',
    2.45,
    256.8,
  ),

  /// Wysoka linia pod górną bandą (+3.2 m i wyżej — 258.5 m).
  upperBankLine(
    'Górna część wiraża',
    'Upper Banking Line',
    3.20,
    258.5,
  );

  final String labelPl;
  final String labelEn;

  /// Wysokość poprzeczna powyżej czarnej linii pomiarowej [m].
  final double heightAboveBlackLineMeters;

  /// Efektywny dystans pełnego okrążenia na tej linii [m].
  final double effectiveLapLengthMeters;

  const VelodromeTrackLine(
    this.labelPl,
    this.labelEn,
    this.heightAboveBlackLineMeters,
    this.effectiveLapLengthMeters,
  );
}

/// Dane wejściowe do obliczenia chwilowej fizyki na welodromie.
class VelodromePhysicsInput {
  /// Specyfikacja welodromu (długość, kąt wirażu, promień, wysokość, drewno).
  final VelodromeFacilitySpec facility;

  /// Rower torowy ostrokołowy.
  final FixedGearTrackBike bike;

  /// Masa kolarza [kg] (bez roweru).
  final double riderMassKg;

  /// Prędkość liniowa kolarza [m/s].
  final double speedMs;

  /// Sekcja toru (prosta, wejście, wiraż, wyjście).
  final VelodromeTrackSection section;

  /// Odchylenie poprzeczne powyżej czarnej linii pomiarowej [m] (`0.0` = dokładnie na linii,
  /// `>= 3.2` = górna banda 258.5 m).
  final double metersAboveBlackLine;

  /// Współczynnik oporu toczenia opon torowych (jeśli `null`, pobierany z nawierzchni drewna).
  final double? customCrr;

  /// Całkowity współczynnik oporu aerodynamicznego CdA [m²] (jeśli `null`, pobierany z roweru).
  final double? customCda;

  const VelodromePhysicsInput({
    required this.facility,
    required this.bike,
    required this.riderMassKg,
    required this.speedMs,
    this.section = VelodromeTrackSection.turnApex,
    this.metersAboveBlackLine = 0.0,
    this.customCrr,
    this.customCda,
  });
}

/// Wynik rozwiązania fizyki jazdy na wirażu i prostej drewnianego welodromu.
class VelodromeBankingPhysicsResult {
  /// Aktualny kąt pochylenia toru w danej sekcji [stopnie].
  final double localBankingDegrees;

  /// Efektywny promień skrętu z uwzględnieniem linii jazdy [m].
  final double effectiveTurnRadiusMeters;

  /// Przyspieszenie odśrodkowe $a_c = v^2 / R$ [m/s²].
  final double centripetalAccelerationMs2;

  /// Siła odśrodkowa $F_c = m \cdot a_c$ [N].
  final double centripetalForceNewtons;

  /// Współczynnik przeciążenia dociskającego do toru (1.0G = masa spoczynkowa, maks. 1.8G).
  final double gForceLoadFactor;

  /// Surowy (nieograniczony) współczynnik przeciążenia G przed limitem torowym.
  final double rawGForceLoadFactor;

  /// Masa całkowita (kolarz + rower) [kg].
  final double totalMassKg;

  /// Efektywna masa dociskająca opony do drewna w wirażu $m_{eff} = m \cdot G$ [kg].
  final double effectiveMassKg;

  /// Równowagowy kąt pochylenia roweru względem pionu [stopnie].
  final double equilibriumLeanAngleDegrees;

  /// Różnica między kątem pochylenia roweru a kątem nachylenia toru [stopnie].
  final double relativeBankLeanDeltaDegrees;

  /// Efektywny dystans jednego okrążenia dla aktualnej linii jazdy [m] (250.0–258.5 m).
  final double effectiveLapLengthMeters;

  /// Kara dystansowa na 1 okrążenie za jazdę powyżej czarnej linii [m].
  final double blackLinePenaltyMetersPerLap;

  /// Kara czasowa na 1 okrążenie przy aktualnej prędkości [s].
  final double blackLineTimePenaltySecondsPerLap;

  /// Siła oporu toczenia z uwzględnieniem przeciążenia w wirażu [N].
  final double rollingResistanceForceNewtons;

  /// Siła oporu aerodynamicznego [N].
  final double aerodynamicDragForceNewtons;

  /// Całkowita siła oporu ruchu [N].
  final double totalResistanceForceNewtons;

  /// Moc na kole potrzebna do utrzymania prędkości [W].
  final double wheelPowerWatts;

  /// Moc na pedałach (po uwzględnieniu sprawności napędu ostrokołowego) [W].
  final double requiredRiderPowerWatts;

  /// Kadencja wymuszona przez ostre koło [RPM].
  final double cadenceRpm;

  /// Czy prędkość jest bezpieczna na wirażu (powyżej prędkości zsunięcia na dół).
  final bool isAboveMinimumTurnSpeed;

  /// Minimalna bezpieczna prędkość na wirażu o danym nachyleniu [m/s].
  final double minimumSafeTurnSpeedMs;

  const VelodromeBankingPhysicsResult({
    required this.localBankingDegrees,
    required this.effectiveTurnRadiusMeters,
    required this.centripetalAccelerationMs2,
    required this.centripetalForceNewtons,
    required this.gForceLoadFactor,
    required this.rawGForceLoadFactor,
    required this.totalMassKg,
    required this.effectiveMassKg,
    required this.equilibriumLeanAngleDegrees,
    required this.relativeBankLeanDeltaDegrees,
    required this.effectiveLapLengthMeters,
    required this.blackLinePenaltyMetersPerLap,
    required this.blackLineTimePenaltySecondsPerLap,
    required this.rollingResistanceForceNewtons,
    required this.aerodynamicDragForceNewtons,
    required this.totalResistanceForceNewtons,
    required this.wheelPowerWatts,
    required this.requiredRiderPowerWatts,
    required this.cadenceRpm,
    required this.isAboveMinimumTurnSpeed,
    required this.minimumSafeTurnSpeedMs,
  });

  /// Prędkość liniowa w km/h wyliczona z mocy/oporu.
  double get speedKmh =>
      totalResistanceForceNewtons > 0
          ? (wheelPowerWatts / totalResistanceForceNewtons) * 3.6
          : 0.0;

  /// Procentowy wzrost oporu toczenia w porównaniu do jazdy po płaskim (1.0G).
  double get rollingResistanceIncreasePercent =>
      math.max(0.0, (gForceLoadFactor - 1.0) * 100.0);
}

/// Telemetria pojedynczego okrążenia w symulacji Rekordu Godzinnego UCI.
class HourRecordLapTelemetry {
  final int lapNumber;
  final double elapsedTimeSeconds;
  final double lapTimeSeconds;
  final double targetLapTimeSeconds;
  final double lapDeviationSeconds;
  final double averageSpeedKmh;
  final double peakTurnGForce;
  final double effectiveMassKg;
  final double averagePowerWatts;
  final double cadenceRpm;
  final double metersAboveBlackLine;
  final double effectiveLapLengthMeters;
  final double cumulativeDistanceMeters;
  final double remainingWPrimeJoules;
  final bool isWithinPaceTolerance;

  const HourRecordLapTelemetry({
    required this.lapNumber,
    required this.elapsedTimeSeconds,
    required this.lapTimeSeconds,
    required this.targetLapTimeSeconds,
    required this.lapDeviationSeconds,
    required this.averageSpeedKmh,
    required this.peakTurnGForce,
    required this.effectiveMassKg,
    required this.averagePowerWatts,
    required this.cadenceRpm,
    required this.metersAboveBlackLine,
    required this.effectiveLapLengthMeters,
    required this.cumulativeDistanceMeters,
    required this.remainingWPrimeJoules,
    required this.isWithinPaceTolerance,
  });
}

/// Wynik pełnej 60-minutowej symulacji tempa na Rekord Godzinny UCI.
class HourRecordPacingSimulationResult {
  final VelodromeFacilitySpec facility;
  final FixedGearTrackBike bike;
  final double targetLapTimeSeconds;
  final double paceToleranceSeconds;
  final double totalDistanceMeters;
  final int completedFullLaps;
  final double fractionalLaps;
  final double averageLapTimeSeconds;
  final double steadyStateAverageLapTimeSeconds;
  final double averageSpeedKmh;
  final double averagePowerWatts;
  final double peakCentripetalGForce;
  final double totalBlackLinePenaltyMeters;
  final double totalBlackLineTimePenaltySeconds;
  final int maxConsecutiveOnPaceLaps;
  final int totalOnPaceLaps;
  final bool heldTargetPaceFor227Laps;
  final List<HourRecordLapTelemetry> laps;

  const HourRecordPacingSimulationResult({
    required this.facility,
    required this.bike,
    required this.targetLapTimeSeconds,
    required this.paceToleranceSeconds,
    required this.totalDistanceMeters,
    required this.completedFullLaps,
    required this.fractionalLaps,
    required this.averageLapTimeSeconds,
    required this.steadyStateAverageLapTimeSeconds,
    required this.averageSpeedKmh,
    required this.averagePowerWatts,
    required this.peakCentripetalGForce,
    required this.totalBlackLinePenaltyMeters,
    required this.totalBlackLineTimePenaltySeconds,
    required this.maxConsecutiveOnPaceLaps,
    required this.totalOnPaceLaps,
    required this.heldTargetPaceFor227Laps,
    required this.laps,
  });

  /// Dystans końcowy w kilometrach.
  double get totalDistanceKm => totalDistanceMeters / 1000.0;
}

/// Solver fizyki jazdy po drewnianym welodromie 250 m i tempa na Rekord Godzinny UCI.
///
/// Modeluje:
/// 1. Siłę odśrodkową na wirażu $a_c = v^2 / R$ dociskającą kolarza do drewnianego toru
///    (przeciążenie do $1.8G$, podnoszące efektywną masę $m_{eff}$ oraz opór toczenia).
/// 2. Karę za wyjechanie powyżej czarnej linii pomiarowej (wydłużenie okrążenia
///    z $250.0\text{ m}$ do $258.5\text{ m}$).
/// 3. Precyzyjne tempo na Rekord Godzinny (np. $15.80\text{ s}$ przez 227 okrążeń z rzędu).
class VelodromeBankingAndCentripetalSolver {
  VelodromeBankingAndCentripetalSolver._();

  /// Standardowa długość okrążenia na czarnej linii pomiarowej [m].
  static const double blackLineLapLengthMeters = 250.0;

  /// Maksymalna długość okrążenia przy wyjechaniu wysoko pod górną bandę [m].
  static const double maxUpperLineLapLengthMeters = 258.5;

  /// Maksymalne odchylenie poprzeczne powyżej czarnej linii odpowiadające 258.5 m [m].
  static const double maxLineDeviationMeters = 3.20;

  /// Maksymalne fizjologiczno-torowe przeciążenie na wirażu welodromu [G].
  static const double maxVelodromeGForce = 1.80;

  /// Docelowa liczba okrążeń wyścigowych dla tempa Rekordu Godzinnego (~15.80 s).
  static const int hourRecordBenchmarkConsecutiveLaps = 227;

  /// Udział wiraży w całkowitej długości okrążenia 250 m (ok. 56% łuki, 44% proste/przejścia).
  static const double turnFractionOfLap = 0.56;

  /// Wylicza efektywną długość okrążenia [m] dla zadanej wysokości jazdy powyżej czarnej linii [m].
  ///
  /// - `0.0 m` -> `250.0 m` (czarna linia pomiarowa)
  /// - `>= 3.20 m` -> `258.5 m` (górna część wiraża)
  static double computeEffectiveLapLengthMeters(double metersAboveBlackLine) {
    final double clampedOffset =
        metersAboveBlackLine.clamp(0.0, maxLineDeviationMeters);
    final double ratio = clampedOffset / maxLineDeviationMeters;
    // Długość toru rośnie proporcjonalnie do przesunięcia w górę wiraża: +8.5 m na pełnej szerokości.
    return blackLineLapLengthMeters +
        (maxUpperLineLapLengthMeters - blackLineLapLengthMeters) * ratio;
  }

  /// Wylicza efektywny promień wirażu $R$ [m] po uwzględnieniu wysokości jazdy nad czarną linią.
  static double computeEffectiveTurnRadiusMeters({
    required VelodromeFacilitySpec facility,
    required double metersAboveBlackLine,
  }) {
    final double baseRadius = math.max(15.0, facility.turnRadiusMeters);
    final double clampedOffset =
        metersAboveBlackLine.clamp(0.0, maxLineDeviationMeters);
    final double bankRad =
        facility.turnBankingDegrees.clamp(0.0, 60.0) * (math.pi / 180.0);
    // Rzut poziomy przesunięcia po nachylonej powierzchni wiraża powiększa promień toru jazdy.
    return baseRadius + clampedOffset * math.cos(bankRad);
  }

  /// Zwraca lokalny kąt pochylenia toru [stopnie] dla danej sekcji welodromu.
  static double localBankingAngleDegrees({
    required VelodromeFacilitySpec facility,
    required VelodromeTrackSection section,
  }) {
    switch (section) {
      case VelodromeTrackSection.straight:
        return facility.straightBankingDegrees;
      case VelodromeTrackSection.transitionEntry:
      case VelodromeTrackSection.transitionExit:
        return (facility.straightBankingDegrees + facility.turnBankingDegrees) *
            0.5;
      case VelodromeTrackSection.turnApex:
        return facility.turnBankingDegrees;
    }
  }

  /// Wylicza przyspieszenie odśrodkowe $a_c = \frac{v^2}{R}$ [m/s²].
  static double computeCentripetalAcceleration({
    required double speedMs,
    required double radiusMeters,
  }) {
    if (speedMs <= 0.0 || radiusMeters <= 0.0) return 0.0;
    return (speedMs * speedMs) / radiusMeters;
  }

  /// Oblicza pełny stan fizyki kolarza na welodromie w zadanej sekcji i przy zadanej prędkości.
  static VelodromeBankingPhysicsResult solveInstantaneousPhysics(
    VelodromePhysicsInput input,
  ) {
    final double safeSpeedMs = math.max(0.0, input.speedMs);
    final double totalMassKg =
        math.max(40.0, input.riderMassKg + input.bike.bikeWeightKg);
    final double localBankDeg = localBankingAngleDegrees(
      facility: input.facility,
      section: input.section,
    );
    final double localBankRad = localBankDeg * (math.pi / 180.0);

    final double effectiveLapLength =
        computeEffectiveLapLengthMeters(input.metersAboveBlackLine);
    final double penaltyMetersPerLap =
        math.max(0.0, effectiveLapLength - blackLineLapLengthMeters);
    final double penaltyTimePerLap =
        safeSpeedMs > 0.1 ? penaltyMetersPerLap / safeSpeedMs : 0.0;

    final double effectiveRadius = input.section == VelodromeTrackSection.straight
        ? 1e9 // Prosta nie generuje przyspieszenia odśrodkowego.
        : computeEffectiveTurnRadiusMeters(
            facility: input.facility,
            metersAboveBlackLine: input.metersAboveBlackLine,
          );

    final double ac = input.section == VelodromeTrackSection.straight
        ? 0.0
        : computeCentripetalAcceleration(
            speedMs: safeSpeedMs,
            radiusMeters: effectiveRadius,
          );

    final double fc = totalMassKg * ac;

    // Składowa normalna dociskająca opony prostopadle do drewnianej nawierzchni:
    // a_n = g * cos(theta) + a_c * sin(theta).
    const double g = PhysicsConstants.gravity;
    final double normalAccel =
        g * math.cos(localBankRad) + ac * math.sin(localBankRad);
    final double rawGLoad = normalAccel / g;
    final double clampedGLoad = rawGLoad.clamp(0.75, maxVelodromeGForce);
    final double effectiveMassKg = totalMassKg * clampedGLoad;

    // Równowagowy kąt pochylenia roweru względem pionu: tan(phi) = a_c / g.
    final double leanRad = math.atan2(ac, g);
    final double leanDeg = leanRad * (180.0 / math.pi);
    final double relativeBankDeltaDeg = (leanDeg - localBankDeg).abs();

    // Minimalna bezpieczna prędkość na wirażu (poniżej tej wartości grawitacja zsuwa koła w dół,
    // jeśli tarcie opony o suche drewno ~0.65 nie utrzyma bocznego poślizgu).
    const double woodStaticFriction = 0.65;
    final double effectiveSlideTan = math.max(
      0.0,
      (math.sin(localBankRad) - woodStaticFriction * math.cos(localBankRad)) /
          (math.cos(localBankRad) + woodStaticFriction * math.sin(localBankRad)),
    );
    final double minSafeSpeedMs =
        input.section == VelodromeTrackSection.straight
            ? 0.0
            : math.sqrt(g * effectiveRadius * effectiveSlideTan);
    final bool isAboveMinTurnSpeed = safeSpeedMs >= minSafeSpeedMs;

    // Opór toczenia rośnie proporcjonalnie do efektywnej masy dociskającej opony (aż do 1.8G).
    final double crr =
        input.customCrr ?? input.facility.woodSurface.baseRollingResistanceCrr;
    final double rollingResistanceN = crr * effectiveMassKg * g;

    // Opór aerodynamiczny w warunkach hali (wysokość, temperatura, wilgotność).
    final double airDensity = input.facility.airDensityKgPerM3;
    final double cda = input.customCda ?? input.bike.cdaMetersSquared;
    final double aeroDragN =
        0.5 * airDensity * cda * safeSpeedMs * safeSpeedMs;

    final double totalResistanceN = rollingResistanceN + aeroDragN;
    final double wheelPowerW = totalResistanceN * safeSpeedMs;
    final double efficiency =
        input.bike.drivetrainEfficiency.clamp(0.90, 0.999);
    final double riderPowerW = wheelPowerW / efficiency;

    final double cadenceRpm =
        input.bike.cadenceRpmFromSpeedKmh(safeSpeedMs * 3.6);

    return VelodromeBankingPhysicsResult(
      localBankingDegrees: localBankDeg,
      effectiveTurnRadiusMeters: effectiveRadius,
      centripetalAccelerationMs2: ac,
      centripetalForceNewtons: fc,
      gForceLoadFactor: clampedGLoad,
      rawGForceLoadFactor: rawGLoad,
      totalMassKg: totalMassKg,
      effectiveMassKg: effectiveMassKg,
      equilibriumLeanAngleDegrees: leanDeg,
      relativeBankLeanDeltaDegrees: relativeBankDeltaDeg,
      effectiveLapLengthMeters: effectiveLapLength,
      blackLinePenaltyMetersPerLap: penaltyMetersPerLap,
      blackLineTimePenaltySecondsPerLap: penaltyTimePerLap,
      rollingResistanceForceNewtons: rollingResistanceN,
      aerodynamicDragForceNewtons: aeroDragN,
      totalResistanceForceNewtons: totalResistanceN,
      wheelPowerWatts: wheelPowerW,
      requiredRiderPowerWatts: riderPowerW,
      cadenceRpm: cadenceRpm,
      isAboveMinimumTurnSpeed: isAboveMinTurnSpeed,
      minimumSafeTurnSpeedMs: minSafeSpeedMs,
    );
  }

  /// Wylicza uśrednioną fizykę pełnego okrążenia (ważoną udziałem prostych i wiraży).
  static VelodromeBankingPhysicsResult solveAverageLapPhysics({
    required VelodromeFacilitySpec facility,
    required FixedGearTrackBike bike,
    required double riderMassKg,
    required double speedMs,
    double metersAboveBlackLine = 0.0,
    double? customCrr,
    double? customCda,
  }) {
    final VelodromeBankingPhysicsResult straightResult =
        solveInstantaneousPhysics(
      VelodromePhysicsInput(
        facility: facility,
        bike: bike,
        riderMassKg: riderMassKg,
        speedMs: speedMs,
        section: VelodromeTrackSection.straight,
        metersAboveBlackLine: metersAboveBlackLine,
        customCrr: customCrr,
        customCda: customCda,
      ),
    );
    final VelodromeBankingPhysicsResult turnResult = solveInstantaneousPhysics(
      VelodromePhysicsInput(
        facility: facility,
        bike: bike,
        riderMassKg: riderMassKg,
        speedMs: speedMs,
        section: VelodromeTrackSection.turnApex,
        metersAboveBlackLine: metersAboveBlackLine,
        customCrr: customCrr,
        customCda: customCda,
      ),
    );

    const double wTurn = turnFractionOfLap;
    const double wStraight = 1.0 - turnFractionOfLap;

    final double avgG =
        turnResult.gForceLoadFactor * wTurn +
        straightResult.gForceLoadFactor * wStraight;
    final double avgEffectiveMass =
        turnResult.effectiveMassKg * wTurn +
        straightResult.effectiveMassKg * wStraight;
    final double avgRollingN =
        turnResult.rollingResistanceForceNewtons * wTurn +
        straightResult.rollingResistanceForceNewtons * wStraight;
    final double avgTotalN = avgRollingN + turnResult.aerodynamicDragForceNewtons;
    final double avgWheelW = avgTotalN * math.max(0.0, speedMs);
    final double efficiency = bike.drivetrainEfficiency.clamp(0.90, 0.999);

    return VelodromeBankingPhysicsResult(
      localBankingDegrees:
          turnResult.localBankingDegrees * wTurn +
          straightResult.localBankingDegrees * wStraight,
      effectiveTurnRadiusMeters: turnResult.effectiveTurnRadiusMeters,
      centripetalAccelerationMs2: turnResult.centripetalAccelerationMs2,
      centripetalForceNewtons: turnResult.centripetalForceNewtons,
      gForceLoadFactor: avgG,
      rawGForceLoadFactor: turnResult.rawGForceLoadFactor,
      totalMassKg: turnResult.totalMassKg,
      effectiveMassKg: avgEffectiveMass,
      equilibriumLeanAngleDegrees: turnResult.equilibriumLeanAngleDegrees,
      relativeBankLeanDeltaDegrees: turnResult.relativeBankLeanDeltaDegrees,
      effectiveLapLengthMeters: turnResult.effectiveLapLengthMeters,
      blackLinePenaltyMetersPerLap: turnResult.blackLinePenaltyMetersPerLap,
      blackLineTimePenaltySecondsPerLap:
          turnResult.blackLineTimePenaltySecondsPerLap,
      rollingResistanceForceNewtons: avgRollingN,
      aerodynamicDragForceNewtons: turnResult.aerodynamicDragForceNewtons,
      totalResistanceForceNewtons: avgTotalN,
      wheelPowerWatts: avgWheelW,
      requiredRiderPowerWatts: avgWheelW / efficiency,
      cadenceRpm: turnResult.cadenceRpm,
      isAboveMinimumTurnSpeed: turnResult.isAboveMinimumTurnSpeed,
      minimumSafeTurnSpeedMs: turnResult.minimumSafeTurnSpeedMs,
    );
  }

  /// Wyznacza prędkość równowagi [m/s] metodą bisekcji dla zadanej mocy na pedałach [W].
  static double solveSteadySpeedFromPower({
    required VelodromeFacilitySpec facility,
    required FixedGearTrackBike bike,
    required double riderMassKg,
    required double riderPowerWatts,
    double metersAboveBlackLine = 0.0,
    double? customCrr,
    double? customCda,
  }) {
    if (riderPowerWatts <= 0.0) return 0.0;
    double low = 1.0;
    double high = 30.0; // 108 km/h górna granica wyszukiwania

    for (int i = 0; i < 42; i++) {
      final double mid = 0.5 * (low + high);
      final VelodromeBankingPhysicsResult res = solveAverageLapPhysics(
        facility: facility,
        bike: bike,
        riderMassKg: riderMassKg,
        speedMs: mid,
        metersAboveBlackLine: metersAboveBlackLine,
        customCrr: customCrr,
        customCda: customCda,
      );
      if (res.requiredRiderPowerWatts > riderPowerWatts) {
        high = mid;
      } else {
        low = mid;
      }
    }
    return 0.5 * (low + high);
  }

  /// Symuluje precyzyjne 60-minutowe tempo na Rekord Godzinny UCI
  /// (np. utrzymanie czasu okrążenia `15.80 s` przez 227 okrążeń z rzędu).
  static HourRecordPacingSimulationResult simulateHourRecordPacing({
    required VelodromeFacilitySpec facility,
    required FixedGearTrackBike bike,
    required double riderMassKg,
    required double riderFtpWatts,
    required double riderWPrimeJoules,
    double targetLapTimeSeconds = 15.80,
    double paceToleranceSeconds = 0.10,
    double lineDisciplineSkill = 96.0,
    double pacingPrecisionSkill = 96.0,
    double? customCrr,
    double? customCda,
    bool includeStandingStartLap = true,
  }) {
    final double safeTargetLapTime = targetLapTimeSeconds.clamp(12.5, 25.0);
    final double safeTolerance = paceToleranceSeconds.clamp(0.02, 1.0);
    final double safeFtp = math.max(180.0, riderFtpWatts) *
        facility.hypoxiaPowerPenaltyFactor;
    double remainingWPrime = math.max(5000.0, riderWPrimeJoules);

    final List<HourRecordLapTelemetry> laps = <HourRecordLapTelemetry>[];
    double elapsedTime = 0.0;
    double totalDistance = 0.0;
    double totalPenaltyMeters = 0.0;
    double totalPenaltyTime = 0.0;
    double peakGForce = 1.0;
    double sumPower = 0.0;
    double sumSteadyLapTime = 0.0;
    int steadyLapCount = 0;
    int currentStreak = 0;
    int maxStreak = 0;
    int totalOnPace = 0;
    int lapNumber = 0;

    final double disciplineNorm = (lineDisciplineSkill / 100.0).clamp(0.5, 1.0);
    final double pacingNorm = (pacingPrecisionSkill / 100.0).clamp(0.5, 1.0);

    // Maksymalna liczba pętli bezpieczeństwa (ok. 300 okrążeń w 60 minut).
    while (elapsedTime < 3600.0 && lapNumber < 320) {
      lapNumber++;
      final double progressRatio = (elapsedTime / 3600.0).clamp(0.0, 1.0);

      // Odchylenie powyżej czarnej linii rośnie lekko wraz ze zmęczeniem pod koniec godziny.
      final double fatigueDrift = math.pow(progressRatio, 1.8).toDouble();
      final double lineNoise =
          (1.0 - disciplineNorm) * (0.35 + 1.25 * fatigueDrift);
      final double metersAboveBlackLine =
          lineNoise.clamp(0.0, maxLineDeviationMeters);

      final double effectiveLapLength =
          computeEffectiveLapLengthMeters(metersAboveBlackLine);
      final double lapPenaltyMeters =
          effectiveLapLength - blackLineLapLengthMeters;

      // Docelowa prędkość z czarnej linii i zakładanego czasu okrążenia (np. 250 / 15.80 = 15.823 m/s).
      double targetSpeedMs = blackLineLapLengthMeters / safeTargetLapTime;

      // Pierwsze okrążenie ze startu zatrzymanego trwa dłużej o ~5.6 s (rozpędzanie ostrego koła).
      final bool isStandingStart = includeStandingStartLap && lapNumber == 1;
      if (isStandingStart) {
        targetSpeedMs *= 0.735;
      }

      // Niewielka oscylacja tempa zależna od umiejętności równej jazdy i zmęczenia.
      final double paceJitterFactor =
          1.0 - (1.0 - pacingNorm) * 0.015 * fatigueDrift;
      final double plannedSpeedMs = targetSpeedMs * paceJitterFactor;

      final VelodromeBankingPhysicsResult physics = solveAverageLapPhysics(
        facility: facility,
        bike: bike,
        riderMassKg: riderMassKg,
        speedMs: plannedSpeedMs,
        metersAboveBlackLine: metersAboveBlackLine,
        customCrr: customCrr,
        customCda: customCda,
      );

      double actualSpeedMs = plannedSpeedMs;
      double actualPowerW = physics.requiredRiderPowerWatts;

      // Jeśli kolarz nie ma już zasobów W' i potrzebna moc przekracza FTP,
      // prędkość spada do tempa równowagi na FTP.
      if (actualPowerW > safeFtp) {
        final double excessPower = actualPowerW - safeFtp;
        final double estLapDuration = effectiveLapLength / actualSpeedMs;
        final double wPrimeCost = excessPower * estLapDuration;
        if (remainingWPrime >= wPrimeCost) {
          remainingWPrime -= wPrimeCost;
        } else {
          // Przejście na moc progową FTP (plus resztka W').
          final double sustainablePower =
              safeFtp + (remainingWPrime / math.max(1.0, estLapDuration));
          remainingWPrime = 0.0;
          actualSpeedMs = solveSteadySpeedFromPower(
            facility: facility,
            bike: bike,
            riderMassKg: riderMassKg,
            riderPowerWatts: sustainablePower,
            metersAboveBlackLine: metersAboveBlackLine,
            customCrr: customCrr,
            customCda: customCda,
          );
          actualPowerW = sustainablePower;
        }
      } else {
        // Regeneracja W' poniżej FTP wg modelu wykładniczego Skiby.
        final double dcp = safeFtp - actualPowerW;
        final double tauW = 546.0 * math.exp(-0.01 * dcp) + 316.0;
        final double estLapDuration = effectiveLapLength / actualSpeedMs;
        remainingWPrime = riderWPrimeJoules -
            (riderWPrimeJoules - remainingWPrime) *
                math.exp(-estLapDuration / tauW);
      }

      final VelodromeBankingPhysicsResult actualTurnPhysics =
          solveInstantaneousPhysics(
        VelodromePhysicsInput(
          facility: facility,
          bike: bike,
          riderMassKg: riderMassKg,
          speedMs: actualSpeedMs,
          section: VelodromeTrackSection.turnApex,
          metersAboveBlackLine: metersAboveBlackLine,
          customCrr: customCrr,
          customCda: customCda,
        ),
      );

      final double rawLapTime = effectiveLapLength / math.max(1.0, actualSpeedMs);

      // Jeśli to ostatnie, niepełne okrążenie przekraczające 3600.0 s, przytnij do pełnej godziny.
      if (elapsedTime + rawLapTime > 3600.0) {
        final double remainingTime = 3600.0 - elapsedTime;
        final double partialDistance = actualSpeedMs * remainingTime;
        totalDistance += partialDistance;
        elapsedTime = 3600.0;
        break;
      }

      elapsedTime += rawLapTime;
      totalDistance += effectiveLapLength;
      totalPenaltyMeters += lapPenaltyMeters;
      totalPenaltyTime += lapPenaltyMeters / math.max(1.0, actualSpeedMs);
      peakGForce = math.max(peakGForce, actualTurnPhysics.gForceLoadFactor);
      sumPower += actualPowerW;

      final double deviation = rawLapTime - safeTargetLapTime;
      final bool onPace = !isStandingStart && deviation.abs() <= safeTolerance;
      if (!isStandingStart) {
        sumSteadyLapTime += rawLapTime;
        steadyLapCount++;
      }

      if (onPace) {
        currentStreak++;
        totalOnPace++;
        maxStreak = math.max(maxStreak, currentStreak);
      } else {
        currentStreak = 0;
      }

      laps.add(
        HourRecordLapTelemetry(
          lapNumber: lapNumber,
          elapsedTimeSeconds: elapsedTime,
          lapTimeSeconds: rawLapTime,
          targetLapTimeSeconds: safeTargetLapTime,
          lapDeviationSeconds: deviation,
          averageSpeedKmh: actualSpeedMs * 3.6,
          peakTurnGForce: actualTurnPhysics.gForceLoadFactor,
          effectiveMassKg: actualTurnPhysics.effectiveMassKg,
          averagePowerWatts: actualPowerW,
          cadenceRpm: actualTurnPhysics.cadenceRpm,
          metersAboveBlackLine: metersAboveBlackLine,
          effectiveLapLengthMeters: effectiveLapLength,
          cumulativeDistanceMeters: totalDistance,
          remainingWPrimeJoules: remainingWPrime,
          isWithinPaceTolerance: onPace,
        ),
      );
    }

    final int completedFullLaps = laps.length;
    final double fractionalLaps = totalDistance / blackLineLapLengthMeters;
    final double avgLapTime =
        completedFullLaps > 0 ? elapsedTime / completedFullLaps : 0.0;
    final double steadyAvgLapTime =
        steadyLapCount > 0 ? sumSteadyLapTime / steadyLapCount : avgLapTime;
    final double avgSpeedKmh = (totalDistance / 3600.0) * 3.6;
    final double avgPower =
        completedFullLaps > 0 ? sumPower / completedFullLaps : 0.0;

    return HourRecordPacingSimulationResult(
      facility: facility,
      bike: bike,
      targetLapTimeSeconds: safeTargetLapTime,
      paceToleranceSeconds: safeTolerance,
      totalDistanceMeters: totalDistance,
      completedFullLaps: completedFullLaps,
      fractionalLaps: fractionalLaps,
      averageLapTimeSeconds: avgLapTime,
      steadyStateAverageLapTimeSeconds: steadyAvgLapTime,
      averageSpeedKmh: avgSpeedKmh,
      averagePowerWatts: avgPower,
      peakCentripetalGForce: peakGForce,
      totalBlackLinePenaltyMeters: totalPenaltyMeters,
      totalBlackLineTimePenaltySeconds: totalPenaltyTime,
      maxConsecutiveOnPaceLaps: maxStreak,
      totalOnPaceLaps: totalOnPace,
      heldTargetPaceFor227Laps:
          maxStreak >= hourRecordBenchmarkConsecutiveLaps,
      laps: laps,
    );
  }
}
