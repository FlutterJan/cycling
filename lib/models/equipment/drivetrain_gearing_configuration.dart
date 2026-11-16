// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

/// Dostępne konfiguracje tarcz mechanizmu korbowego (1x oraz 2x).
enum CranksetChainringOption {
  compact50_34(
    id: '50_34_compact',
    label: '50/34T Compact',
    outerTeeth: 50,
    innerTeeth: 34,
    isSingleRing1x: false,
    weightDeltaGrams: -25,
    aeroCdaModifier: 0.0002,
    recommendedTerrain: 'Wysokie góry i strome ściany (>12%)',
    description:
        'Klasyczna korba kompaktowa zapewniająca lekkie przełożenia na najcięższe alpejskie przełęcze kosztem niższej prędkości maksymalnej na zjazdach.',
  ),
  semiCompact52_36(
    id: '52_36_semi_compact',
    label: '52/36T Semi-Compact',
    outerTeeth: 52,
    innerTeeth: 36,
    isSingleRing1x: false,
    weightDeltaGrams: 0,
    aeroCdaModifier: 0.0,
    recommendedTerrain: 'Teren pagórkowaty, klasyki i etapy mieszane',
    description:
        'Uniwersalny kompromis peletonu łączący płynną kadencję na płaskim z wystarczającym zapasem na długie podjazdy.',
  ),
  proStandard54_40(
    id: '54_40_pro_standard',
    label: '54/40T Pro Standard',
    outerTeeth: 54,
    innerTeeth: 40,
    isSingleRing1x: false,
    weightDeltaGrams: 18,
    aeroCdaModifier: -0.0003,
    recommendedTerrain: 'Wyścigi WorldTour, szybkie etapy i finisze',
    description:
        'Współczesny standard zawodowego peletonu WorldTour gwarantujący wysoką linię łańcucha i brak dokręcania przy >65 km/h.',
  ),
  fastFlat56_44(
    id: '56_44_fast_flat',
    label: '56/44T Fast Flat',
    outerTeeth: 56,
    innerTeeth: 44,
    isSingleRing1x: false,
    weightDeltaGrams: 35,
    aeroCdaModifier: -0.0006,
    recommendedTerrain: 'Płaskie etapy sprinterskie, wiatry boczne i TTT',
    description:
        'Ekstremalnie twarda korba dla pociągów sprinterskich i szybkich czasówek drużynowych przy prędkościach 55–75 km/h.',
  ),
  aeroSingle58_1x(
    id: '58_1x_aero_single',
    label: '58T 1x Aero Single',
    outerTeeth: 58,
    innerTeeth: null,
    isSingleRing1x: true,
    weightDeltaGrams: -110,
    aeroCdaModifier: -0.0018,
    recommendedTerrain: 'Indywidualna jazda na czas (ITT), płaskie klasyki aero',
    description:
        'Pełna tarcza aerodynamiczna 1x bez przedniej przerzutki. Minimalizuje opór czołowy i ryzyko spadnięcia łańcucha, lecz wymaga ogromnej siły na podjazdach.',
  );

  final String id;
  final String label;
  final int outerTeeth;
  final int? innerTeeth;
  final bool isSingleRing1x;
  final int weightDeltaGrams;
  final double aeroCdaModifier;
  final String recommendedTerrain;
  final String description;

  const CranksetChainringOption({
    required this.id,
    required this.label,
    required this.outerTeeth,
    required this.innerTeeth,
    required this.isSingleRing1x,
    required this.weightDeltaGrams,
    required this.aeroCdaModifier,
    required this.recommendedTerrain,
    required this.description,
  });

  /// Najmniejsza dostępna tarcza korby (dla 1x równa tarczy zewnętrznej).
  int get smallestTeeth => innerTeeth ?? outerTeeth;

  /// Różnica zębów między dużą a małą tarczą (0 dla 1x).
  int get chainringGapTeeth =>
      isSingleRing1x ? 0 : (outerTeeth - smallestTeeth);

  static CranksetChainringOption fromId(String? id) {
    for (final option in CranksetChainringOption.values) {
      if (option.id == id || option.name == id) {
        return option;
      }
    }
    return CranksetChainringOption.semiCompact52_36;
  }
}

/// Dostępne 12-rzędowe kasety napędowe.
enum Cassette12SpeedOption {
  sprint11_28(
    id: '11_28t',
    label: '11-28T',
    cogs: [11, 12, 13, 14, 15, 16, 17, 19, 21, 23, 25, 28],
    weightGrams: 198,
    requiresXdrFreehub: false,
    recommendedTerrain: 'Płaskie etapy, kryteria i szybkie czasówki',
    description:
        'Ciasno zestopniowana kaseta wyścigowa z 6 przeskokami co 1 ząb (11–17T) dla idealnego utrzymania kadencji w peletonie.',
  ),
  allRound11_30(
    id: '11_30t',
    label: '11-30T',
    cogs: [11, 12, 13, 14, 15, 16, 17, 19, 21, 24, 27, 30],
    weightGrams: 215,
    requiresXdrFreehub: false,
    recommendedTerrain: 'Klasyki, pagórki i etapy górskie o umiarkowanym nachyleniu',
    description:
        'Najbardziej uniwersalna 12-rzędowa kaseta peletonu łącząca gęsty dół 11–17T z miękką koronką ratunkową 30T.',
  ),
  climbing11_34(
    id: '11_34t',
    label: '11-34T',
    cogs: [11, 12, 13, 14, 15, 17, 19, 21, 24, 27, 30, 34],
    weightGrams: 248,
    requiresXdrFreehub: false,
    recommendedTerrain: 'Królewskie etapy górskie i długie przełęcze HC',
    description:
        'Szeroki zakres przełożeń pozwalający utrzymać wysoką kadencję (>80 RPM) na stromych alpejskich podjazdach nawet pod koniec Grand Touru.',
  ),
  gravelSteep10_36(
    id: '10_36t_gravel_steep',
    label: '10-36T Gravel/Steep',
    cogs: [10, 11, 12, 13, 15, 17, 19, 21, 24, 28, 32, 36],
    weightGrams: 276,
    requiresXdrFreehub: true,
    recommendedTerrain: 'Strade Bianche, szutry, bruki oraz rampy >18%',
    description:
        'Kaseta o potężnym zakresie 360% z koronką 10T (wymaga bębenka XDR) i miękkim biegiem 36T na ekstremalne sektory szutrowe i ściany.',
  );

  final String id;
  final String label;
  final List<int> cogs;
  final int weightGrams;
  final bool requiresXdrFreehub;
  final String recommendedTerrain;
  final String description;

  const Cassette12SpeedOption({
    required this.id,
    required this.label,
    required this.cogs,
    required this.weightGrams,
    required this.requiresXdrFreehub,
    required this.recommendedTerrain,
    required this.description,
  });

  /// Najmniejsza (najtwardsza) koronka kasety.
  int get smallestCog => cogs.first;

  /// Największa (najlżejsza) koronka kasety.
  int get largestCog => cogs.last;

  /// Liczba biegów kasety (zawsze 12).
  int get speedCount => cogs.length;

  /// Liczba pojedynczych przeskoków o 1 ząb (miara płynności kadencji).
  int get oneToothJumpsCount {
    var count = 0;
    for (var i = 1; i < cogs.length; i++) {
      if (cogs[i] - cogs[i - 1] == 1) {
        count++;
      }
    }
    return count;
  }

  /// Całkowity zakres przełożeń samej kasety w procentach (np. 309% dla 11-34T).
  double get rangePercent => (largestCog / smallestCog) * 100.0;

  static Cassette12SpeedOption fromId(String? id) {
    for (final option in Cassette12SpeedOption.values) {
      if (option.id == id || option.name == id) {
        return option;
      }
    }
    return Cassette12SpeedOption.allRound11_30;
  }
}

/// Wynik doboru optymalnego przełożenia dla zadanej prędkości i preferowanej kadencji.
class GearCombination {
  final int frontTeeth;
  final int rearTeeth;
  final double ratio;
  final double cadenceAtTargetSpeedRpm;
  final bool isCrossChained;

  const GearCombination({
    required this.frontTeeth,
    required this.rearTeeth,
    required this.ratio,
    required this.cadenceAtTargetSpeedRpm,
    required this.isCrossChained,
  });

  String get label => '${frontTeeth}x$rearTeeth';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GearCombination &&
        other.frontTeeth == frontTeeth &&
        other.rearTeeth == rearTeeth &&
        other.isCrossChained == isCrossChained;
  }

  @override
  int get hashCode => Object.hash(frontTeeth, rearTeeth, isCrossChained);

  @override
  String toString() =>
      'GearCombination($label, ratio: ${ratio.toStringAsFixed(2)}, '
      'cadence: ${cadenceAtTargetSpeedRpm.toStringAsFixed(1)} RPM)';
}

/// Szczegółowy model konfiguracji przełożeń napędu szosowego/czasowego.
///
/// Łączy wybór tarcz korby ([CranksetChainringOption]) oraz 12-rzędowej kasety
/// ([Cassette12SpeedOption]) z parametrami koła, korby i optymalizacji oporów
/// mechanicznych (łańcuch woskowany, powiększony wózek przerzutki OSPW).
class DrivetrainGearingConfiguration {
  /// Domyślny obwód toczny opony 700x28c [mm].
  static const double defaultWheelCircumferenceMm = 2136.0;

  /// Domyślna długość ramienia korby [mm].
  static const double defaultCrankArmLengthMm = 172.5;

  /// Standardowa pojemność szosowej tylnej przerzutki (liczba zębów).
  static const int standardRoadDerailleurMaxCapacityTeeth = 39;

  final CranksetChainringOption chainring;
  final Cassette12SpeedOption cassette;
  final double wheelCircumferenceMm;
  final double crankArmLengthMm;
  final bool waxedChain;
  final bool oversizedPulleyCage;

  const DrivetrainGearingConfiguration({
    required this.chainring,
    required this.cassette,
    this.wheelCircumferenceMm = defaultWheelCircumferenceMm,
    this.crankArmLengthMm = defaultCrankArmLengthMm,
    this.waxedChain = true,
    this.oversizedPulleyCage = false,
  });

  // ===========================================================================
  // PRESETY WYŚCIGOWE
  // ===========================================================================

  /// Uniwersalna konfiguracja na klasyki i etapy mieszane (`52/36T` + `11-30T`).
  factory DrivetrainGearingConfiguration.allRounder() {
    return const DrivetrainGearingConfiguration(
      chainring: CranksetChainringOption.semiCompact52_36,
      cassette: Cassette12SpeedOption.allRound11_30,
    );
  }

  /// Konfiguracja na wysokie góry i długie przełęcze (`50/34T` + `11-34T`).
  factory DrivetrainGearingConfiguration.alpineClimber() {
    return const DrivetrainGearingConfiguration(
      chainring: CranksetChainringOption.compact50_34,
      cassette: Cassette12SpeedOption.climbing11_34,
    );
  }

  /// Konfiguracja profesjonalnego peletonu WorldTour (`54/40T` + `11-30T`).
  factory DrivetrainGearingConfiguration.proPelotonStandard() {
    return const DrivetrainGearingConfiguration(
      chainring: CranksetChainringOption.proStandard54_40,
      cassette: Cassette12SpeedOption.allRound11_30,
      waxedChain: true,
    );
  }

  /// Konfiguracja aerodynamiczna na płaskie ITT (`58T 1x` + `11-28T`).
  factory DrivetrainGearingConfiguration.timeTrialAero() {
    return const DrivetrainGearingConfiguration(
      chainring: CranksetChainringOption.aeroSingle58_1x,
      cassette: Cassette12SpeedOption.sprint11_28,
      waxedChain: true,
      oversizedPulleyCage: true,
    );
  }

  /// Konfiguracja sprinterska na płaskie etapy i wiatry (`56/44T` + `11-28T`).
  factory DrivetrainGearingConfiguration.fastFlatSprinter() {
    return const DrivetrainGearingConfiguration(
      chainring: CranksetChainringOption.fastFlat56_44,
      cassette: Cassette12SpeedOption.sprint11_28,
      waxedChain: true,
    );
  }

  /// Konfiguracja na szutry Strade Bianche i ekstremalne ściany (`50/34T` + `10-36T`).
  factory DrivetrainGearingConfiguration.gravelSteep() {
    return const DrivetrainGearingConfiguration(
      chainring: CranksetChainringOption.compact50_34,
      cassette: Cassette12SpeedOption.gravelSteep10_36,
      wheelCircumferenceMm: 2155.0,
    );
  }

  // ===========================================================================
  // PARAMETRY MECHANICZNE I PRZEŁOŻENIA
  // ===========================================================================

  /// Lista dostępnych tarcz z przodu (1 element dla 1x, 2 elementy dla 2x).
  List<int> get frontChainrings => chainring.isSingleRing1x
      ? [chainring.outerTeeth]
      : [chainring.outerTeeth, chainring.smallestTeeth];

  /// Lista 12 koronek kasety od najmniejszej do największej.
  List<int> get cassetteCogs => cassette.cogs;

  /// Najtwardsze (najszybsze) przełożenie napędu (np. 54/11 = 4.91).
  double get hardestGearRatio => chainring.outerTeeth / cassette.smallestCog;

  /// Najlżejsze (wspinaczkowe) przełożenie napędu (np. 34/34 = 1.00).
  double get easiestGearRatio =>
      chainring.smallestTeeth / cassette.largestCog;

  /// Całkowity zakres przełożeń napędu w procentach.
  double get gearRangePercent => (hardestGearRatio / easiestGearRatio) * 100.0;

  /// Wymagana pojemność tylnej przerzutki (chain wrap) w zębach.
  int get totalChainWrapTeeth =>
      chainring.chainringGapTeeth +
      (cassette.largestCog - cassette.smallestCog);

  /// Czy napęd przekracza pojemność standardowej szosowej przerzutki (>39T).
  bool get exceedsStandardRoadDerailleurCapacity =>
      totalChainWrapTeeth > standardRoadDerailleurMaxCapacityTeeth;

  /// Różnica masy względem konfiguracji bazowej (`52/36T` + `11-30T`) w gramach.
  int get weightDeltaGrams {
    const baselineCassetteWeightGrams = 215;
    final cassetteDelta = cassette.weightGrams - baselineCassetteWeightGrams;
    final ospwDelta = oversizedPulleyCage ? 12 : 0;
    return chainring.weightDeltaGrams + cassetteDelta + ospwDelta;
  }

  /// Modyfikator oporu aerodynamicznego CdA [m^2].
  double get aeroCdaModifier {
    final ospwAeroPenalty = oversizedPulleyCage ? 0.00015 : 0.0;
    return chainring.aeroCdaModifier + ospwAeroPenalty;
  }

  /// Sprawność mechaniczna napędu (0.95 – 0.992) uwzględniająca woskowanie i OSPW.
  double get drivetrainEfficiency {
    var efficiency = 0.978;
    if (waxedChain) {
      efficiency += 0.004;
    }
    if (oversizedPulleyCage) {
      efficiency += 0.002;
    }
    if (chainring.isSingleRing1x) {
      // Brak prowadnicy przedniej przerzutki, ale minimalnie większe przekosy skrajnych koronek.
      efficiency -= 0.0005;
    }
    return efficiency.clamp(0.95, 0.992);
  }

  /// Ocena płynności kadencji (0–100 pkt) na podstawie pojedynczych przeskoków na kasecie.
  double get cadenceSmoothnessScore {
    final cassetteScore = (cassette.oneToothJumpsCount / 6.0) * 75.0;
    final chainringPenalty = chainring.isSingleRing1x
        ? 0.0
        : math.max(0.0, (chainring.chainringGapTeeth - 12) * 2.0);
    return (25.0 + cassetteScore - chainringPenalty).clamp(0.0, 100.0);
  }

  // ===========================================================================
  // KINEMATYKA PRĘDKOŚCI I KADENCJI
  // ===========================================================================

  /// Prędkość liniowa [km/h] dla zadanego przełożenia i kadencji [RPM].
  double speedKmhAtCadence({
    required double ratio,
    required double cadenceRpm,
  }) {
    if (ratio <= 0 || cadenceRpm <= 0 || wheelCircumferenceMm <= 0) {
      return 0.0;
    }
    final metersPerMinute = ratio * (wheelCircumferenceMm / 1000.0) * cadenceRpm;
    return (metersPerMinute * 60.0) / 1000.0;
  }

  /// Wymagana kadencja [RPM] do utrzymania zadanej prędkości [km/h] na danym przełożeniu.
  double requiredCadenceRpm({
    required double ratio,
    required double speedKmh,
  }) {
    if (ratio <= 0 || speedKmh <= 0 || wheelCircumferenceMm <= 0) {
      return 0.0;
    }
    final metersPerMinute = (speedKmh * 1000.0) / 60.0;
    return metersPerMinute / (ratio * (wheelCircumferenceMm / 1000.0));
  }

  /// Prędkość na najtwardszym biegu przy kadencji 110 RPM (zjazdy / szybki peleton).
  double get maxSpeedKmhAt110Rpm => speedKmhAtCadence(
        ratio: hardestGearRatio,
        cadenceRpm: 110.0,
      );

  /// Prędkość maksymalna na najtwardszym biegu przy 120 RPM (finisz sprinterski).
  double get maxSpeedKmhAt120Rpm => speedKmhAtCadence(
        ratio: hardestGearRatio,
        cadenceRpm: 120.0,
      );

  /// Prędkość minimalna na najlżejszym biegu przy kadencji 70 RPM (strome podjazdy).
  double get minClimbSpeedKmhAt70Rpm => speedKmhAtCadence(
        ratio: easiestGearRatio,
        cadenceRpm: 70.0,
      );

  /// Prędkość minimalna na najlżejszym biegu przy kadencji 80 RPM (komfortowa wspinaczka).
  double get minClimbSpeedKmhAt80Rpm => speedKmhAtCadence(
        ratio: easiestGearRatio,
        cadenceRpm: 80.0,
      );

  /// Czy zestaw nadaje się na strome góry (najlżejsze przełożenie <= 1.22).
  bool get isSuitableForSteepMountains => easiestGearRatio <= 1.22;

  /// Czy występuje ryzyko "kręcenia w pustkę" (spin-out) na szybkich zjazdach/sprintach.
  bool get isSpinOutRiskOnDescent => hardestGearRatio < 4.70;

  /// Dobiera optymalną kombinację tarczy i koronki dla zadanej prędkości i kadencji.
  GearCombination findOptimalGear({
    required double targetSpeedKmh,
    double preferredCadenceRpm = 90.0,
  }) {
    final safeSpeed = math.max(1.0, targetSpeedKmh);
    final safeCadence = preferredCadenceRpm.clamp(40.0, 140.0);

    GearCombination? best;
    var bestScore = double.infinity;

    for (final front in frontChainrings) {
      for (var cogIndex = 0; cogIndex < cassette.cogs.length; cogIndex++) {
        final rear = cassette.cogs[cogIndex];
        final ratio = front / rear;
        final cadence = requiredCadenceRpm(ratio: ratio, speedKmh: safeSpeed);

        final isCrossChained = !chainring.isSingleRing1x &&
            ((front == chainring.outerTeeth &&
                    cogIndex >= cassette.cogs.length - 2) ||
                (front == chainring.innerTeeth && cogIndex <= 1));

        // Kara za przekos łańcucha, aby preferować czystą linię przy zbliżonej kadencji.
        final crossChainPenalty = isCrossChained ? 12.0 : 0.0;
        final score = (cadence - safeCadence).abs() + crossChainPenalty;

        if (score < bestScore) {
          bestScore = score;
          best = GearCombination(
            frontTeeth: front,
            rearTeeth: rear,
            ratio: ratio,
            cadenceAtTargetSpeedRpm: cadence,
            isCrossChained: isCrossChained,
          );
        }
      }
    }

    return best!;
  }

  /// Lista ostrzeżeń mechanicznych i taktycznych dla dyrektora sportowego i mechaników.
  List<String> get mechanicalWarnings {
    final warnings = <String>[];

    if (chainring.isSingleRing1x && easiestGearRatio > 1.50) {
      warnings.add(
        'Napęd ${chainring.label} z kasetą ${cassette.label} ma bardzo twarde najlżejsze przełożenie (${easiestGearRatio.toStringAsFixed(2)}) — ryzyko przepalenia nóg na podjazdach >7%.',
      );
    }

    if (isSpinOutRiskOnDescent) {
      warnings.add(
        'Korba ${chainring.label} (max ${maxSpeedKmhAt110Rpm.toStringAsFixed(1)} km/h @ 110 RPM) grozi brakiem przełożenia na szybkich zjazdach i sprintach.',
      );
    }

    if (cassette.requiresXdrFreehub) {
      warnings.add(
        'Kaseta ${cassette.label} z koronką 10T wymaga kół z bębenkiem SRAM XDR.',
      );
    }

    if (exceedsStandardRoadDerailleurCapacity) {
      warnings.add(
        'Pojemność napędu (${totalChainWrapTeeth}T) przekracza limit standardowej przerzutki szosowej ($standardRoadDerailleurMaxCapacityTeeth T) — wymagany wózek Gravel/XPLR.',
      );
    }

    return warnings;
  }

  // ===========================================================================
  // KOPIOWANIE I SERIALIZACJA JSON
  // ===========================================================================

  DrivetrainGearingConfiguration copyWith({
    CranksetChainringOption? chainring,
    Cassette12SpeedOption? cassette,
    double? wheelCircumferenceMm,
    double? crankArmLengthMm,
    bool? waxedChain,
    bool? oversizedPulleyCage,
  }) {
    return DrivetrainGearingConfiguration(
      chainring: chainring ?? this.chainring,
      cassette: cassette ?? this.cassette,
      wheelCircumferenceMm: wheelCircumferenceMm ?? this.wheelCircumferenceMm,
      crankArmLengthMm: crankArmLengthMm ?? this.crankArmLengthMm,
      waxedChain: waxedChain ?? this.waxedChain,
      oversizedPulleyCage: oversizedPulleyCage ?? this.oversizedPulleyCage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chainring': chainring.id,
      'cassette': cassette.id,
      'wheelCircumferenceMm': wheelCircumferenceMm,
      'crankArmLengthMm': crankArmLengthMm,
      'waxedChain': waxedChain,
      'oversizedPulleyCage': oversizedPulleyCage,
    };
  }

  factory DrivetrainGearingConfiguration.fromJson(Map<String, dynamic> json) {
    return DrivetrainGearingConfiguration(
      chainring: CranksetChainringOption.fromId(json['chainring'] as String?),
      cassette: Cassette12SpeedOption.fromId(json['cassette'] as String?),
      wheelCircumferenceMm:
          (json['wheelCircumferenceMm'] as num?)?.toDouble() ??
              defaultWheelCircumferenceMm,
      crankArmLengthMm:
          (json['crankArmLengthMm'] as num?)?.toDouble() ??
              defaultCrankArmLengthMm,
      waxedChain: json['waxedChain'] as bool? ?? true,
      oversizedPulleyCage: json['oversizedPulleyCage'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DrivetrainGearingConfiguration &&
        other.chainring == chainring &&
        other.cassette == cassette &&
        other.wheelCircumferenceMm == wheelCircumferenceMm &&
        other.crankArmLengthMm == crankArmLengthMm &&
        other.waxedChain == waxedChain &&
        other.oversizedPulleyCage == oversizedPulleyCage;
  }

  @override
  int get hashCode => Object.hash(
        chainring,
        cassette,
        wheelCircumferenceMm,
        crankArmLengthMm,
        waxedChain,
        oversizedPulleyCage,
      );

  @override
  String toString() =>
      'DrivetrainGearingConfiguration(${chainring.label}, ${cassette.label}, '
      'range: ${gearRangePercent.toStringAsFixed(0)}%)';
}
