// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import '../../models/equipment/drivetrain_gearing_configuration.dart';

/// Strefa kadencji kolarza określająca obciążenie nerwowo-mięśniowe i metaboliczne.
enum CadenceEfficiencyZone {
  /// Jazda bez pedałowania (zjazd / swobodne toczenie).
  coasting('Coasting', 'Swobodne toczenie'),

  /// "Mielenie na twardo" (< 60 RPM) — gwałtowny wzrost momentu na korbie,
  /// +18% kosztu glikogenu oraz przyspieszone zmęczenie włókien szybkokurczliwych (Typ II).
  grinding('Grinding (<60 RPM)', 'Mielenie na twardo'),

  /// Niska kadencja siłowa (60–74 RPM) — lekko podwyższone obciążenie mięśniowe.
  lowTorque('Low Cadence (60–74 RPM)', 'Niska kadencja siłowa'),

  /// Optymalne okno kadencji (75–98 RPM) — najwyższa sprawność metaboliczna.
  optimal('Optimal (75–98 RPM)', 'Optymalna kadencja'),

  /// Wysoka kadencja (99–115 RPM) — większe obciążenie układu krążenia.
  highSpin('High Spin (99–115 RPM)', 'Wysoka kadencja'),

  /// "Kręcenie w próżni" (> 115 RPM) — utrata efektywnego przekazywania mocy.
  spinningOut('Spinning Out (>115 RPM)', 'Przekręcone przełożenie');

  final String labelEn;
  final String labelPl;

  const CadenceEfficiencyZone(this.labelEn, this.labelPl);
}

/// Dane wejściowe pojedynczego kroku symulacji dla [CadenceAndGearingEfficiencySolver].
class CadenceAndGearingInput {
  /// Konfiguracja napędu (tarcze korby, kaseta 12s, obwód koła, długość korby).
  final DrivetrainGearingConfiguration drivetrain;

  /// Aktualna prędkość liniowa kolarza [m/s].
  final double speedMs;

  /// Aktualna moc generowana na pedałach [W].
  final double powerWatts;

  /// Nachylenie trasy w procentach (np. `18.0` oznacza ściankę 18%).
  final double gradePercent;

  /// Preferowana docelowa kadencja kolarza [RPM] (domyślnie 88 RPM, na podjazdach niższa).
  final double preferredCadenceRpm;

  /// Czas trwania kroku symulacji [s] do obliczenia przyrostu zmęczenia włókien.
  final double deltaTimeSeconds;

  /// Opcjonalna ręcznie wymuszona przednia tarcza (liczba zębów).
  final int? forcedFrontTeeth;

  /// Opcjonalna ręcznie wymuszona tylna koronka kasety (liczba zębów).
  final int? forcedRearTeeth;

  const CadenceAndGearingInput({
    required this.drivetrain,
    required this.speedMs,
    required this.powerWatts,
    this.gradePercent = 0.0,
    this.preferredCadenceRpm = 88.0,
    this.deltaTimeSeconds = 1.0,
    this.forcedFrontTeeth,
    this.forcedRearTeeth,
  });
}

/// Wynik obliczeń przełożenia, kadencji oraz kosztów fizjologiczno-mechanicznych.
class CadenceAndGearingResult {
  /// Wybrana przednia tarcza korby $Z_{front}$ [liczba zębów].
  final int frontTeeth;

  /// Wybrana tylna koronka kasety $Z_{rear}$ [liczba zębów].
  final int rearTeeth;

  /// Dokładne przełożenie $i = \frac{Z_{front}}{Z_{rear}}$.
  final double gearRatio;

  /// Wyliczona kadencja $\text{RPM} = \frac{v \cdot 60}{C_{wheel} \cdot i}$.
  final double cadenceRpm;

  /// Strefa kadencji kolarza.
  final CadenceEfficiencyZone zone;

  /// Czy kolarz "mieli na twardo" (kadencja poniżej 60 RPM podczas pedałowania).
  final bool isGrinding;

  /// Czy kolarz przekręca najtwardszy bieg (> 115 RPM).
  final bool isSpinningOut;

  /// Czy łańcuch pracuje w silnym przekosie (cross-chain).
  final bool isCrossChained;

  /// Sprawność mechaniczna napędu (uwzględniająca wosk, OSPW i ewentualny przekos).
  final double mechanicalEfficiency;

  /// Mnożnik kosztu glikogenu (`1.00` w normie, `1.18` przy mieleniu `< 60 RPM`).
  final double glycogenCostMultiplier;

  /// Mnożnik tempa zmęczenia włókien szybkokurczliwych (Typ II) (`1.00` w normie).
  final double fastTwitchFatigueMultiplier;

  /// Przyrost skumulowanego zmęczenia włókien szybkokurczliwych w tym kroku [pkt].
  final double fastTwitchFatigueDelta;

  /// Mnożnik efektywnej mocy wynikający z biomechaniki skrajnej kadencji (`0.0..1.0`).
  final double biomechanicalPowerFactor;

  /// Średni moment obrotowy na osi suportu [Nm].
  final double crankTorqueNm;

  /// Średnia siła nacisku na pedał [N].
  final double averagePedalForceNewtons;

  /// Prędkość liniowa w km/h dla celów telemetrycznych.
  double get speedKmh => speedMs * 3.6;

  /// Prędkość liniowa podana na wejściu [m/s].
  final double speedMs;

  const CadenceAndGearingResult({
    required this.frontTeeth,
    required this.rearTeeth,
    required this.gearRatio,
    required this.cadenceRpm,
    required this.zone,
    required this.isGrinding,
    required this.isSpinningOut,
    required this.isCrossChained,
    required this.mechanicalEfficiency,
    required this.glycogenCostMultiplier,
    required this.fastTwitchFatigueMultiplier,
    required this.fastTwitchFatigueDelta,
    required this.biomechanicalPowerFactor,
    required this.crankTorqueNm,
    required this.averagePedalForceNewtons,
    required this.speedMs,
  });

  /// Etykieta aktualnego przełożenia, np. `36x28`.
  String get gearLabel => '${frontTeeth}x$rearTeeth';

  /// Procentowy narzut kosztu glikogenu względem strefy optymalnej (np. `18.0` dla `+18%`).
  double get glycogenPenaltyPercent => (glycogenCostMultiplier - 1.0) * 100.0;

  Map<String, dynamic> toJson() {
    return {
      'frontTeeth': frontTeeth,
      'rearTeeth': rearTeeth,
      'gearRatio': gearRatio,
      'cadenceRpm': cadenceRpm,
      'zone': zone.name,
      'isGrinding': isGrinding,
      'isSpinningOut': isSpinningOut,
      'isCrossChained': isCrossChained,
      'mechanicalEfficiency': mechanicalEfficiency,
      'glycogenCostMultiplier': glycogenCostMultiplier,
      'fastTwitchFatigueMultiplier': fastTwitchFatigueMultiplier,
      'fastTwitchFatigueDelta': fastTwitchFatigueDelta,
      'biomechanicalPowerFactor': biomechanicalPowerFactor,
      'crankTorqueNm': crankTorqueNm,
      'averagePedalForceNewtons': averagePedalForceNewtons,
      'speedMs': speedMs,
    };
  }
}

/// Solver fizyki kadencji, przełożeń i biomechanicznego kosztu pracy mięśni.
///
/// Realizuje dokładne równania kinematyki napędu:
/// - Przełożenie: $i = \frac{Z_{front}}{Z_{rear}}$
/// - Kadencja: $\text{RPM} = \frac{v \cdot 60}{C_{wheel} \cdot i}$
///
/// Modeluje zjawisko "mielenia na twardo" (< 60 RPM), które na stromych ściankach
/// (np. 18% przy kasecie `11-28T`) powoduje wzrost kosztu glikogenu o 18% oraz
/// przyspieszone zmęczenie włókien szybkokurczliwych (Typ II) na skutek wysokiego
/// momentu obrotowego na korbie.
class CadenceAndGearingEfficiencySolver {
  /// Próg kadencji poniżej którego następuje "mielenie na twardo" [RPM].
  static const double grindingCadenceThresholdRpm = 60.0;

  /// Dolna granica optymalnego okna kadencji [RPM].
  static const double optimalCadenceMinRpm = 75.0;

  /// Górna granica optymalnego okna kadencji [RPM].
  static const double optimalCadenceMaxRpm = 98.0;

  /// Próg przekręcania najtwardszego biegu ("spinning out") [RPM].
  static const double spinningOutThresholdRpm = 115.0;

  /// Stały narzut kosztu glikogenu podczas mielenia na twardo (< 60 RPM): +18%.
  static const double grindingGlycogenPenaltyFraction = 0.18;

  /// Bazowa stawka narastania zmęczenia włókien szybkokurczliwych [pkt/s].
  static const double baseFastTwitchFatigueRatePerSecond = 0.05;

  const CadenceAndGearingEfficiencySolver();

  /// Oblicza dokładne przełożenie napędu $i = \frac{Z_{front}}{Z_{rear}}$.
  static double calculateGearRatio({
    required int frontTeeth,
    required int rearTeeth,
  }) {
    if (frontTeeth <= 0 || rearTeeth <= 0) {
      throw ArgumentError(
        'Liczba zębów przedniej ($frontTeeth) i tylnej ($rearTeeth) tarczy musi być dodatnia.',
      );
    }
    return frontTeeth / rearTeeth;
  }

  /// Oblicza kadencję [RPM] ze wzoru $\text{RPM} = \frac{v \cdot 60}{C_{wheel} \cdot i}$.
  ///
  /// - [speedMs]: prędkość liniowa [m/s]
  /// - [wheelCircumferenceMeters]: obwód toczny koła [m] (np. `2.136` dla 700x28c)
  /// - [gearRatio]: przełożenie $i = Z_{front} / Z_{rear}$
  static double calculateCadenceRpm({
    required double speedMs,
    required double wheelCircumferenceMeters,
    required double gearRatio,
  }) {
    if (speedMs <= 0.0 ||
        wheelCircumferenceMeters <= 0.0 ||
        gearRatio <= 0.0) {
      return 0.0;
    }
    return (speedMs * 60.0) / (wheelCircumferenceMeters * gearRatio);
  }

  /// Oblicza prędkość liniową [m/s] dla zadanej kadencji i przełożenia.
  static double calculateSpeedMs({
    required double cadenceRpm,
    required double wheelCircumferenceMeters,
    required double gearRatio,
  }) {
    if (cadenceRpm <= 0.0 ||
        wheelCircumferenceMeters <= 0.0 ||
        gearRatio <= 0.0) {
      return 0.0;
    }
    return (cadenceRpm * wheelCircumferenceMeters * gearRatio) / 60.0;
  }

  /// Rozwiązuje pełny stan kadencji, przełożenia oraz kosztów metabolicznych i mięśniowych.
  CadenceAndGearingResult solve(CadenceAndGearingInput input) {
    final safeSpeedMs = math.max(0.0, input.speedMs);
    final safePowerWatts = math.max(0.0, input.powerWatts);
    final safeDeltaTime = math.max(0.0, input.deltaTimeSeconds);
    final wheelCircumferenceM =
        math.max(1.0, input.drivetrain.wheelCircumferenceMm) / 1000.0;
    final crankArmLengthM =
        math.max(0.140, input.drivetrain.crankArmLengthMm / 1000.0);

    // 1. Dobór przełożenia (ręczne wymuszenie lub automatyczna zmiana biegów).
    final selectedGear = _resolveGearSelection(
      input: input,
      speedMs: safeSpeedMs,
      wheelCircumferenceM: wheelCircumferenceM,
    );

    final gearRatio = calculateGearRatio(
      frontTeeth: selectedGear.frontTeeth,
      rearTeeth: selectedGear.rearTeeth,
    );

    // 2. Wyliczenie dokładnej kadencji [RPM].
    final cadenceRpm = calculateCadenceRpm(
      speedMs: safeSpeedMs,
      wheelCircumferenceMeters: wheelCircumferenceM,
      gearRatio: gearRatio,
    );

    // 3. Sprawdzenie przekosu łańcucha oraz sprawności mechanicznej.
    final isCrossChained = _isCrossChained(
      drivetrain: input.drivetrain,
      frontTeeth: selectedGear.frontTeeth,
      rearTeeth: selectedGear.rearTeeth,
    );
    final crossChainPenalty = isCrossChained ? 0.006 : 0.0;
    final mechanicalEfficiency =
        (input.drivetrain.drivetrainEfficiency - crossChainPenalty)
            .clamp(0.92, 0.992);

    // 4. Gdy kolarz nie pedałuje (zjazd / coasting) lub stoi w miejscu.
    if (safePowerWatts <= 5.0 || safeSpeedMs <= 0.05) {
      return CadenceAndGearingResult(
        frontTeeth: selectedGear.frontTeeth,
        rearTeeth: selectedGear.rearTeeth,
        gearRatio: gearRatio,
        cadenceRpm: 0.0,
        zone: CadenceEfficiencyZone.coasting,
        isGrinding: false,
        isSpinningOut: false,
        isCrossChained: isCrossChained,
        mechanicalEfficiency: mechanicalEfficiency,
        glycogenCostMultiplier: 1.0,
        fastTwitchFatigueMultiplier: 1.0,
        fastTwitchFatigueDelta: 0.0,
        biomechanicalPowerFactor: 1.0,
        crankTorqueNm: 0.0,
        averagePedalForceNewtons: 0.0,
        speedMs: safeSpeedMs,
      );
    }

    // 5. Klasyfikacja strefy kadencji.
    final zone = _classifyCadenceZone(cadenceRpm);
    final isGrinding = cadenceRpm < grindingCadenceThresholdRpm;
    final isSpinningOut = cadenceRpm > spinningOutThresholdRpm;

    // 6. Moment obrotowy na korbie i siła nacisku na pedał.
    final angularVelocityRadPerSec = math.max(
      0.5,
      (cadenceRpm * 2.0 * math.pi) / 60.0,
    );
    final crankTorqueNm = safePowerWatts / angularVelocityRadPerSec;
    final averagePedalForceNewtons = crankTorqueNm / crankArmLengthM;

    // 7. Koszt glikogenu oraz przyspieszone zmęczenie włókien szybkokurczliwych.
    final glycogenCostMultiplier = _computeGlycogenCostMultiplier(
      cadenceRpm: cadenceRpm,
      gradePercent: input.gradePercent,
      cassette: input.drivetrain.cassette,
    );

    final fastTwitchFatigueMultiplier = _computeFastTwitchFatigueMultiplier(
      cadenceRpm: cadenceRpm,
      gradePercent: input.gradePercent,
      crankTorqueNm: crankTorqueNm,
      cassette: input.drivetrain.cassette,
    );

    final fastTwitchFatigueDelta = isGrinding
        ? baseFastTwitchFatigueRatePerSecond *
            fastTwitchFatigueMultiplier *
            safeDeltaTime
        : (cadenceRpm < optimalCadenceMinRpm
            ? baseFastTwitchFatigueRatePerSecond *
                (fastTwitchFatigueMultiplier - 1.0) *
                safeDeltaTime
            : 0.0);

    // 8. Współczynnik efektywnego przeniesienia mocy przy skrajnych kadencjach.
    final biomechanicalPowerFactor = _computeBiomechanicalPowerFactor(
      cadenceRpm: cadenceRpm,
    );

    return CadenceAndGearingResult(
      frontTeeth: selectedGear.frontTeeth,
      rearTeeth: selectedGear.rearTeeth,
      gearRatio: gearRatio,
      cadenceRpm: cadenceRpm,
      zone: zone,
      isGrinding: isGrinding,
      isSpinningOut: isSpinningOut,
      isCrossChained: isCrossChained,
      mechanicalEfficiency: mechanicalEfficiency,
      glycogenCostMultiplier: glycogenCostMultiplier,
      fastTwitchFatigueMultiplier: fastTwitchFatigueMultiplier,
      fastTwitchFatigueDelta: fastTwitchFatigueDelta,
      biomechanicalPowerFactor: biomechanicalPowerFactor,
      crankTorqueNm: crankTorqueNm,
      averagePedalForceNewtons: averagePedalForceNewtons,
      speedMs: safeSpeedMs,
    );
  }

  _SelectedGear _resolveGearSelection({
    required CadenceAndGearingInput input,
    required double speedMs,
    required double wheelCircumferenceM,
  }) {
    final drivetrain = input.drivetrain;

    if (input.forcedFrontTeeth != null && input.forcedRearTeeth != null) {
      return _SelectedGear(
        frontTeeth: input.forcedFrontTeeth!,
        rearTeeth: input.forcedRearTeeth!,
      );
    }

    // Na stromych podjazdach (>= 10%) kolarz obniża docelową kadencję lekko w dół
    // i automatycznie wybiera najlżejsze dostępne przełożenie, jeśli prędkość jest niska.
    final effectiveTargetCadence = input.gradePercent >= 10.0
        ? math.min(input.preferredCadenceRpm, 82.0)
        : input.preferredCadenceRpm;

    final speedKmh = speedMs * 3.6;
    final bestCombination = drivetrain.findOptimalGear(
      targetSpeedKmh: math.max(1.0, speedKmh),
      preferredCadenceRpm: effectiveTargetCadence.clamp(60.0, 110.0),
    );

    // Jeśli nawet najlżejsze przełożenie daje kadencję poniżej docelowej,
    // wybieramy bezwzględnie najlżejszy bieg (mała tarcza + największa koronka).
    final easiestRatio = drivetrain.easiestGearRatio;
    final easiestCadence = calculateCadenceRpm(
      speedMs: speedMs,
      wheelCircumferenceMeters: wheelCircumferenceM,
      gearRatio: easiestRatio,
    );
    if (easiestCadence <= effectiveTargetCadence) {
      return _SelectedGear(
        frontTeeth: drivetrain.chainring.smallestTeeth,
        rearTeeth: drivetrain.cassette.largestCog,
      );
    }

    return _SelectedGear(
      frontTeeth: bestCombination.frontTeeth,
      rearTeeth: bestCombination.rearTeeth,
    );
  }

  bool _isCrossChained({
    required DrivetrainGearingConfiguration drivetrain,
    required int frontTeeth,
    required int rearTeeth,
  }) {
    if (drivetrain.chainring.isSingleRing1x) {
      return false;
    }
    final cogs = drivetrain.cassetteCogs;
    final cogIndex = cogs.indexOf(rearTeeth);
    if (cogIndex < 0) return false;

    final isOuterRing = frontTeeth == drivetrain.chainring.outerTeeth;
    final isInnerRing = frontTeeth == drivetrain.chainring.smallestTeeth;
    if (isOuterRing && cogIndex >= cogs.length - 2) {
      return true;
    }
    if (isInnerRing && cogIndex <= 1) {
      return true;
    }
    return false;
  }

  CadenceEfficiencyZone _classifyCadenceZone(double cadenceRpm) {
    if (cadenceRpm < grindingCadenceThresholdRpm) {
      return CadenceEfficiencyZone.grinding;
    }
    if (cadenceRpm < optimalCadenceMinRpm) {
      return CadenceEfficiencyZone.lowTorque;
    }
    if (cadenceRpm <= optimalCadenceMaxRpm) {
      return CadenceEfficiencyZone.optimal;
    }
    if (cadenceRpm <= spinningOutThresholdRpm) {
      return CadenceEfficiencyZone.highSpin;
    }
    return CadenceEfficiencyZone.spinningOut;
  }

  double _computeGlycogenCostMultiplier({
    required double cadenceRpm,
    required double gradePercent,
    required Cassette12SpeedOption cassette,
  }) {
    if (cadenceRpm < grindingCadenceThresholdRpm) {
      // Mielenie na twardo (< 60 RPM): wzrost kosztu glikogenu o 18% (1.18).
      // Na bardzo stromych ścianach (>= 18%) przy twardej kasecie 11-28T
      // zachowujemy pełny narzut +18% od progu < 60 RPM.
      return 1.0 + grindingGlycogenPenaltyFraction;
    }
    if (cadenceRpm < optimalCadenceMinRpm) {
      // Płynne przejście między optymalną kadencją (75 RPM -> 1.00) a progiem 60 RPM (1.06).
      final t = (optimalCadenceMinRpm - cadenceRpm) /
          (optimalCadenceMinRpm - grindingCadenceThresholdRpm);
      return 1.0 + (t * 0.06);
    }
    if (cadenceRpm <= optimalCadenceMaxRpm) {
      return 1.0;
    }
    // Wysoka kadencja (> 98 RPM) zwiększa wydatek tlenowy/węglowodanowy o max ~6%.
    final spinExcess = ((cadenceRpm - optimalCadenceMaxRpm) / 25.0).clamp(0.0, 1.0);
    return 1.0 + (spinExcess * 0.06);
  }

  double _computeFastTwitchFatigueMultiplier({
    required double cadenceRpm,
    required double gradePercent,
    required double crankTorqueNm,
    required Cassette12SpeedOption cassette,
  }) {
    if (cadenceRpm >= optimalCadenceMinRpm) {
      return 1.0;
    }
    if (cadenceRpm >= grindingCadenceThresholdRpm) {
      // Lekka rekrutacja włókien szybkokurczliwych w strefie siłowej (60–74 RPM).
      final t = (optimalCadenceMinRpm - cadenceRpm) /
          (optimalCadenceMinRpm - grindingCadenceThresholdRpm);
      return 1.0 + (t * 0.25);
    }

    // Poniżej 60 RPM następuje silne przeciążenie włókien szybkokurczliwych (Typ II):
    // bazowy mnożnik 1.45x rosnący wraz z deficytem kadencji, momentem i stromizną.
    final cadenceDeficitRatio =
        ((grindingCadenceThresholdRpm - cadenceRpm) / 25.0).clamp(0.0, 1.0);
    final torqueFactor = ((crankTorqueNm - 55.0) / 50.0).clamp(0.0, 0.5);
    final steep18Bonus =
        (gradePercent >= 18.0 && cassette == Cassette12SpeedOption.sprint11_28)
            ? 0.20
            : 0.0;

    return 1.45 + (cadenceDeficitRatio * 0.65) + torqueFactor + steep18Bonus;
  }

  double _computeBiomechanicalPowerFactor({required double cadenceRpm}) {
    if (cadenceRpm < 45.0) {
      // Skrajne zablokowanie kadencji na ścianie obniża efektywną moc.
      final deficit = ((45.0 - cadenceRpm) / 20.0).clamp(0.0, 1.0);
      return 0.94 - (deficit * 0.12);
    }
    if (cadenceRpm > spinningOutThresholdRpm) {
      // Przekręcenie biegu (> 115 RPM) ogranicza zdolność generowania momentu.
      final excess = ((cadenceRpm - spinningOutThresholdRpm) / 25.0).clamp(0.0, 1.0);
      return 1.0 - (excess * 0.22);
    }
    return 1.0;
  }
}

class _SelectedGear {
  final int frontTeeth;
  final int rearTeeth;

  const _SelectedGear({
    required this.frontTeeth,
    required this.rearTeeth,
  });
}
