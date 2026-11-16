import 'dart:math' as math;

import '../../core/constants/physics_constants.dart';

/// Pozycja aerodynamiczna kolarza podczas zjazdu technicznego.
enum DescenderAeroPosture {
  /// Standardowy chwyt na klamkomanetkach (wysoki opór czołowy, pełna kontrola hamulców).
  hoods('Hoods', 'Górny chwyt (klamki)', PhysicsConstants.cdaHoods),

  /// Dolny chwyt kierownicy (optymalny przed wejściem w zakręt i podczas hamowania).
  drops('Drops', 'Dolny chwyt', PhysicsConstants.cdaDrops),

  /// Pozycja z przedramionami na kierownicy na łagodniejszych odcinkach zjazdu.
  puppyPaws('Puppy Paws', 'Przedramiona na kierownicy', PhysicsConstants.cdaPuppyPaws),

  /// Agresywna pozycja aerodynamiczna na ramie ("Supertuck" — klatka przy mostku, niski środek ciężkości).
  supertuckTopTube('Supertuck (Top Tube)', 'Pozycja aero na ramie', 0.238);

  final String labelEn;
  final String labelPl;
  final double baseCdA;

  const DescenderAeroPosture(this.labelEn, this.labelPl, this.baseCdA);

  String toJson() => name;

  static DescenderAeroPosture fromJson(String value) {
    return DescenderAeroPosture.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => DescenderAeroPosture.drops,
    );
  }
}

/// Poziom agresywności ataku na zjeździe.
enum DescenderAttackAggression {
  /// Kontrolowany zjazd z dużym zapasem przyczepności.
  controlled('Controlled', 'Kontrolowany', 0.90, 0.55),

  /// Standardowy atak elitarnego zjazdowca — późne hamowanie i pełny supertuck.
  aggressive('Aggressive', 'Agresywny atak', 1.00, 1.00),

  /// Jazda na absolutnej granicy przyczepności (maksymalne opóźnienie hamowania, podwyższone ryzyko uślizgu).
  kamikaze('Kamikaze', 'Na granicy ryzyka', 1.08, 1.45);

  final String labelEn;
  final String labelPl;
  final double brakingAggressionMultiplier;
  final double slipRiskMultiplier;

  const DescenderAttackAggression(
    this.labelEn,
    this.labelPl,
    this.brakingAggressionMultiplier,
    this.slipRiskMultiplier,
  );

  String toJson() => name;

  static DescenderAttackAggression fromJson(String value) {
    return DescenderAttackAggression.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => DescenderAttackAggression.aggressive,
    );
  }
}

/// Faza ataku na zjeździe od szczytu przełęczy po dolinę.
enum DescenderAttackPhase {
  /// Brak aktywnego ataku zjazdowego.
  inactive,

  /// Przyspieszenie na szczycie przełęczy (otwarcie luki przed pierwszymi serpentynami).
  summitLaunch,

  /// Szybka prosta między zakrętami w pozycji aerodynamicznej na ramie (Supertuck).
  supertuckChute,

  /// Późne dohamowanie przed serpentyną w dolnym chwycie.
  lateBrakingEntry,

  /// Pokonywanie wierzchołka zakrętu (apex) i dynamiczne wyjście z serpentyny.
  hairpinApexExit,

  /// Zjazd zakończony.
  completed;

  String toJson() => name;

  static DescenderAttackPhase fromJson(String value) {
    return DescenderAttackPhase.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => DescenderAttackPhase.inactive,
    );
  }
}

/// Wynik weryfikacji, czy kolarz spełnia wymogi ataku na technicznym zjeździe.
class SummitDescenderEligibility {
  final bool canAttack;
  final bool meetsDescendingThreshold;
  final bool meetsBikeHandlingThreshold;
  final bool isTechnicalDescentAhead;
  final bool hasSufficientAnaerobicReserve;
  final double skillAdvantageFactor;
  final String reasonCode;

  const SummitDescenderEligibility({
    required this.canAttack,
    required this.meetsDescendingThreshold,
    required this.meetsBikeHandlingThreshold,
    required this.isTechnicalDescentAhead,
    required this.hasSufficientAnaerobicReserve,
    required this.skillAdvantageFactor,
    required this.reasonCode,
  });

  Map<String, dynamic> toJson() => {
        'canAttack': canAttack,
        'meetsDescendingThreshold': meetsDescendingThreshold,
        'meetsBikeHandlingThreshold': meetsBikeHandlingThreshold,
        'isTechnicalDescentAhead': isTechnicalDescentAhead,
        'hasSufficientAnaerobicReserve': hasSufficientAnaerobicReserve,
        'skillAdvantageFactor': skillAdvantageFactor,
        'reasonCode': reasonCode,
      };

  factory SummitDescenderEligibility.fromJson(Map<String, dynamic> json) {
    return SummitDescenderEligibility(
      canAttack: json['canAttack'] as bool? ?? false,
      meetsDescendingThreshold: json['meetsDescendingThreshold'] as bool? ?? false,
      meetsBikeHandlingThreshold: json['meetsBikeHandlingThreshold'] as bool? ?? false,
      isTechnicalDescentAhead: json['isTechnicalDescentAhead'] as bool? ?? false,
      hasSufficientAnaerobicReserve:
          json['hasSufficientAnaerobicReserve'] as bool? ?? false,
      skillAdvantageFactor: (json['skillAdvantageFactor'] as num?)?.toDouble() ?? 0.0,
      reasonCode: json['reasonCode'] as String? ?? 'unknown',
    );
  }
}

/// Parametry kolarza i trasy dla mechaniki ataku na zjeździe i pozycji Supertuck.
class DescenderAttackInput {
  /// Identyfikator kolarza.
  final String riderId;

  /// Umiejętność zjazdów (1–100; wymagane >= 85 do ataku na technicznym zjeździe).
  final int descendingSkill;

  /// Umiejętność prowadzenia roweru i pokonywania zakrętów (1–100; wymagane >= 85).
  final int bikeHandlingSkill;

  /// Umiejętność utrzymania pozycji aerodynamicznej (1–100).
  final int aeroPositioningSkill;

  /// Masa ciała kolarza [kg].
  final double riderMassKg;

  /// Masa roweru [kg].
  final double bikeMassKg;

  /// Całkowita długość zjazdu [km] (domyślnie 15.0 km).
  final double descentLengthKm;

  /// Średnie nachylenie zjazdu [%] (ujemne, np. -7.5%).
  final double averageGradientPercent;

  /// Liczba serpentyn / ostrych nawrotów na długości zjazdu.
  final int hairpinCount;

  /// Średni promień krzywizny serpentyny [m].
  final double hairpinRadiusMeters;

  /// Współczynnik przyczepności nawierzchni (1.0 = suchy asfalt, ~0.68 = mokry).
  final double surfaceGripMultiplier;

  /// Gęstość powietrza [kg/m^3].
  final double airDensityKgM3;

  /// Współczynnik oporów toczenia opon (Crr).
  final double crr;

  /// Składowa wiatru czołowego [m/s] (>0 w twarz, <0 w plecy).
  final double headwindMs;

  /// Pozostały ułamek energii beztlenowej W' na szczycie przełęczy (0.0–1.0).
  final double wPrimeRemainingFraction;

  /// Moc generowana przy wyjściu z zakrętów i na szczycie [W].
  final double cornerExitPowerWatts;

  /// Wybrany poziom agresywności ataku.
  final DescenderAttackAggression aggression;

  const DescenderAttackInput({
    required this.riderId,
    required this.descendingSkill,
    required this.bikeHandlingSkill,
    this.aeroPositioningSkill = 82,
    this.riderMassKg = 68.0,
    this.bikeMassKg = 6.9,
    this.descentLengthKm = DescenderAttackAndSupertuckPhysics.referenceDescentKm,
    this.averageGradientPercent = -7.5,
    this.hairpinCount = 18,
    this.hairpinRadiusMeters = 19.0,
    this.surfaceGripMultiplier = 1.0,
    this.airDensityKgM3 = 1.08,
    this.crr = PhysicsConstants.crrSmoothAsphalt,
    this.headwindMs = 0.0,
    this.wPrimeRemainingFraction = 0.75,
    this.cornerExitPowerWatts = 520.0,
    this.aggression = DescenderAttackAggression.aggressive,
  });

  double get totalMassKg => math.max(45.0, riderMassKg + bikeMassKg);

  DescenderAttackInput copyWith({
    String? riderId,
    int? descendingSkill,
    int? bikeHandlingSkill,
    int? aeroPositioningSkill,
    double? riderMassKg,
    double? bikeMassKg,
    double? descentLengthKm,
    double? averageGradientPercent,
    int? hairpinCount,
    double? hairpinRadiusMeters,
    double? surfaceGripMultiplier,
    double? airDensityKgM3,
    double? crr,
    double? headwindMs,
    double? wPrimeRemainingFraction,
    double? cornerExitPowerWatts,
    DescenderAttackAggression? aggression,
  }) {
    return DescenderAttackInput(
      riderId: riderId ?? this.riderId,
      descendingSkill: descendingSkill ?? this.descendingSkill,
      bikeHandlingSkill: bikeHandlingSkill ?? this.bikeHandlingSkill,
      aeroPositioningSkill: aeroPositioningSkill ?? this.aeroPositioningSkill,
      riderMassKg: riderMassKg ?? this.riderMassKg,
      bikeMassKg: bikeMassKg ?? this.bikeMassKg,
      descentLengthKm: descentLengthKm ?? this.descentLengthKm,
      averageGradientPercent: averageGradientPercent ?? this.averageGradientPercent,
      hairpinCount: hairpinCount ?? this.hairpinCount,
      hairpinRadiusMeters: hairpinRadiusMeters ?? this.hairpinRadiusMeters,
      surfaceGripMultiplier: surfaceGripMultiplier ?? this.surfaceGripMultiplier,
      airDensityKgM3: airDensityKgM3 ?? this.airDensityKgM3,
      crr: crr ?? this.crr,
      headwindMs: headwindMs ?? this.headwindMs,
      wPrimeRemainingFraction:
          wPrimeRemainingFraction ?? this.wPrimeRemainingFraction,
      cornerExitPowerWatts: cornerExitPowerWatts ?? this.cornerExitPowerWatts,
      aggression: aggression ?? this.aggression,
    );
  }
}

/// Stan pojedynczego kroku symulacji ataku zjazdowego.
class DescenderStepState {
  final double elapsedTimeSeconds;
  final double distanceCoveredMeters;
  final double currentSpeedMs;
  final double effectiveCdA;
  final DescenderAeroPosture activePosture;
  final DescenderAttackPhase activePhase;
  final double brakingDecelerationMs2;
  final double brakingDelayAdvantageMeters;
  final double cumulativeTimeGainSeconds;
  final double instantaneousSlipRisk;

  const DescenderStepState({
    required this.elapsedTimeSeconds,
    required this.distanceCoveredMeters,
    required this.currentSpeedMs,
    required this.effectiveCdA,
    required this.activePosture,
    required this.activePhase,
    required this.brakingDecelerationMs2,
    required this.brakingDelayAdvantageMeters,
    required this.cumulativeTimeGainSeconds,
    required this.instantaneousSlipRisk,
  });

  double get currentSpeedKmh => currentSpeedMs * 3.6;

  Map<String, dynamic> toJson() => {
        'elapsedTimeSeconds': elapsedTimeSeconds,
        'distanceCoveredMeters': distanceCoveredMeters,
        'currentSpeedMs': currentSpeedMs,
        'effectiveCdA': effectiveCdA,
        'activePosture': activePosture.toJson(),
        'activePhase': activePhase.toJson(),
        'brakingDecelerationMs2': brakingDecelerationMs2,
        'brakingDelayAdvantageMeters': brakingDelayAdvantageMeters,
        'cumulativeTimeGainSeconds': cumulativeTimeGainSeconds,
        'instantaneousSlipRisk': instantaneousSlipRisk,
      };
}

/// Pełne podsumowanie symulacji zjazdu technicznego dla atakującego vs bazowy peleton.
class DescentSimulationSummary {
  final String riderId;
  final bool attackExecuted;
  final double descentLengthKm;
  final double totalTimeSeconds;
  final double baselinePelotonTimeSeconds;
  final double timeGainSeconds;
  final double timeSavedFromSummitAttackSeconds;
  final double timeSavedFromLateBrakingSeconds;
  final double timeSavedFromSupertuckAeroSeconds;
  final double peakSpeedKmh;
  final double averageSpeedKmh;
  final double baselineAverageSpeedKmh;
  final double supertuckActivePercentage;
  final double averageBrakingDelayMeters;
  final double averageSupertuckCdA;
  final double peakSlipRisk;

  const DescentSimulationSummary({
    required this.riderId,
    required this.attackExecuted,
    required this.descentLengthKm,
    required this.totalTimeSeconds,
    required this.baselinePelotonTimeSeconds,
    required this.timeGainSeconds,
    required this.timeSavedFromSummitAttackSeconds,
    required this.timeSavedFromLateBrakingSeconds,
    required this.timeSavedFromSupertuckAeroSeconds,
    required this.peakSpeedKmh,
    required this.averageSpeedKmh,
    required this.baselineAverageSpeedKmh,
    required this.supertuckActivePercentage,
    required this.averageBrakingDelayMeters,
    required this.averageSupertuckCdA,
    required this.peakSlipRisk,
  });

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'attackExecuted': attackExecuted,
        'descentLengthKm': descentLengthKm,
        'totalTimeSeconds': totalTimeSeconds,
        'baselinePelotonTimeSeconds': baselinePelotonTimeSeconds,
        'timeGainSeconds': timeGainSeconds,
        'timeSavedFromSummitAttackSeconds': timeSavedFromSummitAttackSeconds,
        'timeSavedFromLateBrakingSeconds': timeSavedFromLateBrakingSeconds,
        'timeSavedFromSupertuckAeroSeconds': timeSavedFromSupertuckAeroSeconds,
        'peakSpeedKmh': peakSpeedKmh,
        'averageSpeedKmh': averageSpeedKmh,
        'baselineAverageSpeedKmh': baselineAverageSpeedKmh,
        'supertuckActivePercentage': supertuckActivePercentage,
        'averageBrakingDelayMeters': averageBrakingDelayMeters,
        'averageSupertuckCdA': averageSupertuckCdA,
        'peakSlipRisk': peakSlipRisk,
      };
}

/// Silnik fizyki ataków na technicznych zjazdach i agresywnej pozycji na ramie (Supertuck).
///
/// Kolarze o umiejętności `descending >= 85` i `bikeHandling >= 85` mogą zaatakować
/// na szczycie przełęczy i zyskać 25–45 s na 15 km zjazdu dzięki późniejszemu
/// hamowaniu przed serpentynami oraz agresywnej pozycji aerodynamicznej na ramie.
class DescenderAttackAndSupertuckPhysics {
  DescenderAttackAndSupertuckPhysics._();

  /// Minimalny próg umiejętności zjazdów wymagany do ataku na technicznym zjeździe.
  static const int minDescendingSkill = 85;

  /// Minimalny próg umiejętności prowadzenia roweru wymagany do późnego hamowania i Supertucka.
  static const int minBikeHandlingSkill = 85;

  /// Referencyjna długość technicznego zjazdu z przełęczy [km].
  static const double referenceDescentKm = 15.0;

  /// Minimalna wymagana rezerwa W' (ułamek) do odpalenia przyspieszenia na szczycie przełęczy.
  static const double minSummitWPrimeFraction = 0.12;

  /// Czas trwania początkowego zrywu na szczycie przełęczy [s].
  static const double summitLaunchDurationSeconds = 12.0;

  /// Minimalna prędkość bezpiecznego wejścia w pozycję Supertuck na ramie [m/s] (~48 km/h).
  static const double minSupertuckActivationSpeedMs = 13.33;

  /// Bazowy poziom umiejętności peletonu służący jako punkt odniesienia dla zysku czasowego.
  static const int baselinePelotonDescending = 76;
  static const int baselinePelotonBikeHandling = 76;
  static const int baselinePelotonAero = 75;

  /// Sprawdza, czy kolarz może zaatakować na szczycie przełęczy przed technicznym zjazdem.
  static SummitDescenderEligibility evaluateSummitAttackEligibility({
    required int descendingSkill,
    required int bikeHandlingSkill,
    required double upcomingGradientPercent,
    required double descentLengthKm,
    required int hairpinCount,
    double wPrimeRemainingFraction = 0.75,
  }) {
    final bool meetsDesc = descendingSkill >= minDescendingSkill;
    final bool meetsHand = bikeHandlingSkill >= minBikeHandlingSkill;
    final bool isTechnical =
        upcomingGradientPercent <= -3.0 && descentLengthKm >= 2.0 && hairpinCount >= 2;
    final bool hasWPrime = wPrimeRemainingFraction >= minSummitWPrimeFraction;

    final double avgSkill = (descendingSkill * 0.55) + (bikeHandlingSkill * 0.45);
    final double advantage = ((avgSkill - 85.0) / 15.0).clamp(0.0, 1.0);

    String reasonCode = 'eligible_for_summit_attack';
    if (!meetsDesc) {
      reasonCode = 'descending_below_85';
    } else if (!meetsHand) {
      reasonCode = 'bike_handling_below_85';
    } else if (!isTechnical) {
      reasonCode = 'descent_not_technical_enough';
    } else if (!hasWPrime) {
      reasonCode = 'insufficient_w_prime_reserve';
    }

    return SummitDescenderEligibility(
      canAttack: meetsDesc && meetsHand && isTechnical && hasWPrime,
      meetsDescendingThreshold: meetsDesc,
      meetsBikeHandlingThreshold: meetsHand,
      isTechnicalDescentAhead: isTechnical,
      hasSufficientAnaerobicReserve: hasWPrime,
      skillAdvantageFactor: advantage,
      reasonCode: reasonCode,
    );
  }

  /// Wylicza efektywne CdA w zależności od pozycji na zjeździe i umiejętności aero kolarza.
  static double computeEffectiveCdA({
    required DescenderAeroPosture posture,
    required int aeroPositioningSkill,
    required int descendingSkill,
  }) {
    final double aeroMod =
        1.0 - ((aeroPositioningSkill.clamp(1, 100) - 70) / 100.0) * 0.14;
    final double tuckStabilityMod = posture == DescenderAeroPosture.supertuckTopTube
        ? 1.0 - ((descendingSkill.clamp(1, 100) - 85).clamp(0, 15) / 15.0) * 0.055
        : 1.0;

    return (posture.baseCdA * aeroMod * tuckStabilityMod).clamp(0.185, 0.380);
  }

  /// Wylicza maksymalną bezpieczną prędkość pokonania wierzchołka serpentyny [m/s]
  /// na podstawie fizyki przyczepności `v_max = sqrt(mu * g * R)` oraz umiejętności.
  static double computeHairpinApexSpeedMs({
    required int descendingSkill,
    required int bikeHandlingSkill,
    required double hairpinRadiusMeters,
    required double surfaceGripMultiplier,
    DescenderAttackAggression aggression = DescenderAttackAggression.aggressive,
  }) {
    final double clampedRadius = hairpinRadiusMeters.clamp(8.0, 80.0);
    final double clampedGrip = surfaceGripMultiplier.clamp(0.35, 1.15);

    // Bazowy współczynnik tarcia bocznego dla asfaltu (0.82 na sucho)
    final double skillFactor =
        ((bikeHandlingSkill.clamp(1, 100) * 0.65 + descendingSkill.clamp(1, 100) * 0.35) -
                74.0) /
            26.0;
    final double effectiveMu = (0.79 + skillFactor * 0.11) *
        clampedGrip *
        (0.97 + (aggression.brakingAggressionMultiplier - 0.90) * 0.20);

    return math.sqrt(effectiveMu * PhysicsConstants.gravity * clampedRadius)
        .clamp(6.5, 22.0);
  }

  /// Wylicza maksymalne opóźnienie hamowania przed serpentyną [m/s^2]
  /// oraz przewagę późnego hamowania w metrach względem bazowego peletonu.
  static ({double decelerationMs2, double lateBrakingMeters}) computeLateBrakingProfile({
    required int descendingSkill,
    required int bikeHandlingSkill,
    required double entrySpeedMs,
    required double apexSpeedMs,
    required double surfaceGripMultiplier,
    DescenderAttackAggression aggression = DescenderAttackAggression.aggressive,
  }) {
    final double clampedGrip = surfaceGripMultiplier.clamp(0.35, 1.15);
    final double combinedSkill =
        (descendingSkill.clamp(1, 100) * 0.55) + (bikeHandlingSkill.clamp(1, 100) * 0.45);

    // Bazowy peleton hamuje zachowawczo (~0.50 g na sucho), elita (~0.68-0.78 g)
    final double riderG = (0.48 + ((combinedSkill - 65.0).clamp(0.0, 35.0) / 35.0) * 0.26) *
        clampedGrip *
        aggression.brakingAggressionMultiplier;
    final double riderDecel = (riderG * PhysicsConstants.gravity).clamp(3.2, 8.6);

    final double baselineG = 0.50 * clampedGrip;
    final double baselineDecel = (baselineG * PhysicsConstants.gravity).clamp(3.0, 6.2);

    final double vIn = math.max(entrySpeedMs, apexSpeedMs + 0.5);
    final double riderBrakingDist =
        (vIn * vIn - apexSpeedMs * apexSpeedMs) / (2.0 * riderDecel);
    final double baselineBrakingDist =
        (vIn * vIn - apexSpeedMs * apexSpeedMs) / (2.0 * baselineDecel);

    return (
      decelerationMs2: riderDecel,
      lateBrakingMeters: math.max(0.0, baselineBrakingDist - riderBrakingDist),
    );
  }

  /// Oblicza przyspieszenie wzdłużne [m/s^2] na zjeździe przy zadanej mocy i pozycji aero.
  static double computeDownhillAccelerationMs2({
    required double speedMs,
    required double totalMassKg,
    required double gradientPercent,
    required double effectiveCdA,
    required double crr,
    required double airDensityKgM3,
    required double headwindMs,
    required double pedalingPowerWatts,
  }) {
    final double clampedSpeed = math.max(1.0, speedMs);
    final double slopeAngle = math.atan(gradientPercent / 100.0);

    // Siła grawitacji wspomagająca zjazd (gradientPercent < 0 => -sin(slopeAngle) > 0)
    final double gravityAssistForce =
        totalMassKg * PhysicsConstants.gravity * (-math.sin(slopeAngle));

    final double rollingResistanceForce =
        totalMassKg * PhysicsConstants.gravity * crr * math.cos(slopeAngle);

    final double relativeAirSpeed = clampedSpeed + headwindMs;
    final double aeroDragForce = 0.5 *
        airDensityKgM3 *
        effectiveCdA *
        relativeAirSpeed *
        relativeAirSpeed.abs();

    final double driveForce = pedalingPowerWatts > 0.0
        ? (pedalingPowerWatts * PhysicsConstants.getMechanicalEfficiency(isWaxed: true)) /
            clampedSpeed
        : 0.0;

    final double netForce =
        gravityAssistForce + driveForce - rollingResistanceForce - aeroDragForce;
    return netForce / totalMassKg;
  }

  /// Oblicza pojedynczy krok fizyki zjazdu (`dtSeconds`) dla integracji w pętli symulacji.
  static DescenderStepState stepDescentPhysics({
    required DescenderAttackInput input,
    required double currentSpeedMs,
    required double distanceCoveredMeters,
    required double elapsedTimeSeconds,
    required double distanceToNextHairpinMeters,
    required double baselineSpeedMs,
    required double cumulativeTimeGainSeconds,
    double dtSeconds = 0.5,
  }) {
    final bool isEligible = input.descendingSkill >= minDescendingSkill &&
        input.bikeHandlingSkill >= minBikeHandlingSkill;

    final double apexSpeedMs = computeHairpinApexSpeedMs(
      descendingSkill: input.descendingSkill,
      bikeHandlingSkill: input.bikeHandlingSkill,
      hairpinRadiusMeters: input.hairpinRadiusMeters,
      surfaceGripMultiplier: input.surfaceGripMultiplier,
      aggression: input.aggression,
    );

    final brakingProfile = computeLateBrakingProfile(
      descendingSkill: input.descendingSkill,
      bikeHandlingSkill: input.bikeHandlingSkill,
      entrySpeedMs: currentSpeedMs,
      apexSpeedMs: apexSpeedMs,
      surfaceGripMultiplier: input.surfaceGripMultiplier,
      aggression: input.aggression,
    );

    // Wymagany dystans do wyhamowania przed serpentyną
    final double speedExcessSq =
        math.max(0.0, currentSpeedMs * currentSpeedMs - apexSpeedMs * apexSpeedMs);
    final double requiredBrakingDist =
        speedExcessSq / (2.0 * brakingProfile.decelerationMs2);

    DescenderAttackPhase phase;
    DescenderAeroPosture posture;
    double powerWatts = 0.0;
    double accelMs2 = 0.0;

    if (elapsedTimeSeconds < summitLaunchDurationSeconds && isEligible) {
      phase = DescenderAttackPhase.summitLaunch;
      posture = DescenderAeroPosture.drops;
      powerWatts = input.cornerExitPowerWatts * 1.15;
    } else if (distanceToNextHairpinMeters <= 18.0) {
      phase = DescenderAttackPhase.hairpinApexExit;
      posture = DescenderAeroPosture.drops;
      powerWatts = input.cornerExitPowerWatts * (isEligible ? 1.0 : 0.72);
    } else if (distanceToNextHairpinMeters <= requiredBrakingDist + 8.0 &&
        currentSpeedMs > apexSpeedMs + 0.4) {
      phase = DescenderAttackPhase.lateBrakingEntry;
      posture = DescenderAeroPosture.drops;
      accelMs2 = -brakingProfile.decelerationMs2;
    } else if (isEligible && currentSpeedMs >= minSupertuckActivationSpeedMs) {
      phase = DescenderAttackPhase.supertuckChute;
      posture = DescenderAeroPosture.supertuckTopTube;
      powerWatts = 0.0; // W pozycji na ramie kolarz nie pedałuje — maksymalizuje aero
    } else {
      phase = DescenderAttackPhase.supertuckChute;
      posture = DescenderAeroPosture.drops;
      powerWatts = 140.0;
    }

    final double effectiveCdA = computeEffectiveCdA(
      posture: posture,
      aeroPositioningSkill: input.aeroPositioningSkill,
      descendingSkill: input.descendingSkill,
    );

    if (phase != DescenderAttackPhase.lateBrakingEntry) {
      accelMs2 = computeDownhillAccelerationMs2(
        speedMs: currentSpeedMs,
        totalMassKg: input.totalMassKg,
        gradientPercent: input.averageGradientPercent,
        effectiveCdA: effectiveCdA,
        crr: input.crr,
        airDensityKgM3: input.airDensityKgM3,
        headwindMs: input.headwindMs,
        pedalingPowerWatts: powerWatts,
      );
    }

    double nextSpeedMs = (currentSpeedMs + accelMs2 * dtSeconds).clamp(4.0, 31.0);
    if (phase == DescenderAttackPhase.hairpinApexExit) {
      nextSpeedMs = math.max(nextSpeedMs, apexSpeedMs);
    }

    final double avgStepSpeed = (currentSpeedMs + nextSpeedMs) * 0.5;
    final double stepDistance = avgStepSpeed * dtSeconds;

    // Różnica czasu względem bazowego tempa peletonu na tym samym dystansie
    final double clampedBaselineSpeed = math.max(4.0, baselineSpeedMs);
    final double baselineStepTime = stepDistance / clampedBaselineSpeed;
    final double stepTimeGain = baselineStepTime - dtSeconds;

    final double wetPenalty = (1.0 - input.surfaceGripMultiplier).clamp(0.0, 0.5);
    final double slipRisk = ((phase == DescenderAttackPhase.lateBrakingEntry ||
                phase == DescenderAttackPhase.hairpinApexExit)
            ? (0.04 + wetPenalty * 0.25) * input.aggression.slipRiskMultiplier
            : 0.015 * input.aggression.slipRiskMultiplier)
        .clamp(0.0, 0.95);

    return DescenderStepState(
      elapsedTimeSeconds: elapsedTimeSeconds + dtSeconds,
      distanceCoveredMeters: distanceCoveredMeters + stepDistance,
      currentSpeedMs: nextSpeedMs,
      effectiveCdA: effectiveCdA,
      activePosture: posture,
      activePhase: phase,
      brakingDecelerationMs2:
          phase == DescenderAttackPhase.lateBrakingEntry ? brakingProfile.decelerationMs2 : 0.0,
      brakingDelayAdvantageMeters: brakingProfile.lateBrakingMeters,
      cumulativeTimeGainSeconds: cumulativeTimeGainSeconds + stepTimeGain,
      instantaneousSlipRisk: slipRisk,
    );
  }

  /// Symuluje cały techniczny zjazd (domyślnie 15 km) dla kolarza i porównuje z bazowym
  /// przejazdem peletonu, wyliczając dokładny zysk czasowy (25–45 s dla elity).
  static DescentSimulationSummary simulateFullDescent(
    DescenderAttackInput input, {
    double dtSeconds = 0.5,
  }) {
    final eligibility = evaluateSummitAttackEligibility(
      descendingSkill: input.descendingSkill,
      bikeHandlingSkill: input.bikeHandlingSkill,
      upcomingGradientPercent: input.averageGradientPercent,
      descentLengthKm: input.descentLengthKm,
      hairpinCount: input.hairpinCount,
      wPrimeRemainingFraction: input.wPrimeRemainingFraction,
    );

    final double totalMeters = math.max(500.0, input.descentLengthKm * 1000.0);
    final int hairpins = math.max(1, input.hairpinCount);
    final double segmentLengthMeters = totalMeters / hairpins;

    // Symulacja referencyjna peletonu (brak Supertucka, konserwatywne hamowanie)
    final baselineRun = _runSinglePass(
      input: input.copyWith(
        descendingSkill: baselinePelotonDescending,
        bikeHandlingSkill: baselinePelotonBikeHandling,
        aeroPositioningSkill: baselinePelotonAero,
        aggression: DescenderAttackAggression.controlled,
      ),
      allowSupertuckAndSummitAttack: false,
      totalMeters: totalMeters,
      segmentLengthMeters: segmentLengthMeters,
      dtSeconds: dtSeconds,
    );

    if (!eligibility.canAttack) {
      final nonAttackRun = _runSinglePass(
        input: input,
        allowSupertuckAndSummitAttack: false,
        totalMeters: totalMeters,
        segmentLengthMeters: segmentLengthMeters,
        dtSeconds: dtSeconds,
      );

      return DescentSimulationSummary(
        riderId: input.riderId,
        attackExecuted: false,
        descentLengthKm: input.descentLengthKm,
        totalTimeSeconds: nonAttackRun.totalTimeSeconds,
        baselinePelotonTimeSeconds: baselineRun.totalTimeSeconds,
        timeGainSeconds: baselineRun.totalTimeSeconds - nonAttackRun.totalTimeSeconds,
        timeSavedFromSummitAttackSeconds: 0.0,
        timeSavedFromLateBrakingSeconds:
            math.max(0.0, baselineRun.totalTimeSeconds - nonAttackRun.totalTimeSeconds),
        timeSavedFromSupertuckAeroSeconds: 0.0,
        peakSpeedKmh: nonAttackRun.peakSpeedMs * 3.6,
        averageSpeedKmh: (totalMeters / nonAttackRun.totalTimeSeconds) * 3.6,
        baselineAverageSpeedKmh: (totalMeters / baselineRun.totalTimeSeconds) * 3.6,
        supertuckActivePercentage: 0.0,
        averageBrakingDelayMeters: nonAttackRun.avgBrakingDelayMeters,
        averageSupertuckCdA: DescenderAeroPosture.drops.baseCdA,
        peakSlipRisk: nonAttackRun.peakSlipRisk,
      );
    }

    // Symulacja pośrednia: samo późne hamowanie + atak na szczycie (bez Supertucka)
    final lateBrakingOnlyRun = _runSinglePass(
      input: input,
      allowSupertuckAndSummitAttack: false,
      allowSummitAttackBurst: true,
      totalMeters: totalMeters,
      segmentLengthMeters: segmentLengthMeters,
      dtSeconds: dtSeconds,
    );

    // Pełna symulacja elitarnego ataku: szczyt + późne hamowanie + Supertuck na ramie
    final fullAttackRun = _runSinglePass(
      input: input,
      allowSupertuckAndSummitAttack: true,
      allowSummitAttackBurst: true,
      totalMeters: totalMeters,
      segmentLengthMeters: segmentLengthMeters,
      dtSeconds: dtSeconds,
    );

    final double totalGain =
        baselineRun.totalTimeSeconds - fullAttackRun.totalTimeSeconds;
    final double supertuckGain = math.max(
      0.0,
      lateBrakingOnlyRun.totalTimeSeconds - fullAttackRun.totalTimeSeconds,
    );
    final double summitGain = (2.2 + eligibility.skillAdvantageFactor * 1.8)
        .clamp(0.0, math.max(0.0, totalGain - supertuckGain));
    final double lateBrakingGain =
        math.max(0.0, totalGain - supertuckGain - summitGain);

    return DescentSimulationSummary(
      riderId: input.riderId,
      attackExecuted: true,
      descentLengthKm: input.descentLengthKm,
      totalTimeSeconds: fullAttackRun.totalTimeSeconds,
      baselinePelotonTimeSeconds: baselineRun.totalTimeSeconds,
      timeGainSeconds: totalGain,
      timeSavedFromSummitAttackSeconds: summitGain,
      timeSavedFromLateBrakingSeconds: lateBrakingGain,
      timeSavedFromSupertuckAeroSeconds: supertuckGain,
      peakSpeedKmh: fullAttackRun.peakSpeedMs * 3.6,
      averageSpeedKmh: (totalMeters / fullAttackRun.totalTimeSeconds) * 3.6,
      baselineAverageSpeedKmh: (totalMeters / baselineRun.totalTimeSeconds) * 3.6,
      supertuckActivePercentage: fullAttackRun.supertuckPercentage,
      averageBrakingDelayMeters: fullAttackRun.avgBrakingDelayMeters,
      averageSupertuckCdA: fullAttackRun.avgSupertuckCdA,
      peakSlipRisk: fullAttackRun.peakSlipRisk,
    );
  }

  static _SinglePassResult _runSinglePass({
    required DescenderAttackInput input,
    required bool allowSupertuckAndSummitAttack,
    bool allowSummitAttackBurst = false,
    required double totalMeters,
    required double segmentLengthMeters,
    required double dtSeconds,
  }) {
    double distance = 0.0;
    double elapsed = 0.0;
    double speedMs = allowSummitAttackBurst ? 11.2 : 10.0; // prędkość na szczycie przełęczy
    double peakSpeedMs = speedMs;
    double peakSlipRisk = 0.0;

    int totalSteps = 0;
    int supertuckSteps = 0;
    double supertuckCdaSum = 0.0;
    double brakingDelaySum = 0.0;
    int brakingSteps = 0;

    final double apexSpeedMs = computeHairpinApexSpeedMs(
      descendingSkill: input.descendingSkill,
      bikeHandlingSkill: input.bikeHandlingSkill,
      hairpinRadiusMeters: input.hairpinRadiusMeters,
      surfaceGripMultiplier: input.surfaceGripMultiplier,
      aggression: input.aggression,
    );

    while (distance < totalMeters && elapsed < 3600.0) {
      totalSteps++;
      final double distanceInSegment = distance % segmentLengthMeters;
      final double distanceToHairpin = segmentLengthMeters - distanceInSegment;

      final brakingProfile = computeLateBrakingProfile(
        descendingSkill: input.descendingSkill,
        bikeHandlingSkill: input.bikeHandlingSkill,
        entrySpeedMs: speedMs,
        apexSpeedMs: apexSpeedMs,
        surfaceGripMultiplier: input.surfaceGripMultiplier,
        aggression: input.aggression,
      );

      final double speedExcessSq =
          math.max(0.0, speedMs * speedMs - apexSpeedMs * apexSpeedMs);
      final double requiredBrakingDist =
          speedExcessSq / (2.0 * brakingProfile.decelerationMs2);

      DescenderAeroPosture posture = DescenderAeroPosture.drops;
      double powerWatts = 0.0;
      double accelMs2 = 0.0;
      bool isBraking = false;
      bool isApex = false;

      if (allowSummitAttackBurst && elapsed < summitLaunchDurationSeconds) {
        posture = DescenderAeroPosture.drops;
        powerWatts = input.cornerExitPowerWatts * 1.15;
      } else if (distanceToHairpin <= 18.0) {
        isApex = true;
        posture = DescenderAeroPosture.drops;
        powerWatts = input.cornerExitPowerWatts *
            (allowSummitAttackBurst ? 1.0 : 0.65);
      } else if (distanceToHairpin <= requiredBrakingDist + 8.0 &&
          speedMs > apexSpeedMs + 0.4) {
        isBraking = true;
        posture = DescenderAeroPosture.drops;
        accelMs2 = -brakingProfile.decelerationMs2;
        brakingDelaySum += brakingProfile.lateBrakingMeters;
        brakingSteps++;
      } else if (allowSupertuckAndSummitAttack &&
          speedMs >= minSupertuckActivationSpeedMs) {
        posture = DescenderAeroPosture.supertuckTopTube;
        powerWatts = 0.0;
        supertuckSteps++;
      } else {
        posture = DescenderAeroPosture.drops;
        powerWatts = allowSummitAttackBurst ? 210.0 : 220.0;
      }

      final double effectiveCdA = computeEffectiveCdA(
        posture: posture,
        aeroPositioningSkill: input.aeroPositioningSkill,
        descendingSkill: input.descendingSkill,
      );

      if (posture == DescenderAeroPosture.supertuckTopTube) {
        supertuckCdaSum += effectiveCdA;
      }

      if (!isBraking) {
        accelMs2 = computeDownhillAccelerationMs2(
          speedMs: speedMs,
          totalMassKg: input.totalMassKg,
          gradientPercent: input.averageGradientPercent,
          effectiveCdA: effectiveCdA,
          crr: input.crr,
          airDensityKgM3: input.airDensityKgM3,
          headwindMs: input.headwindMs,
          pedalingPowerWatts: powerWatts,
        );
      }

      double nextSpeedMs = (speedMs + accelMs2 * dtSeconds).clamp(4.0, 31.0);
      if (isApex) {
        nextSpeedMs = math.max(nextSpeedMs, apexSpeedMs);
      }

      final double stepDist = ((speedMs + nextSpeedMs) * 0.5) * dtSeconds;
      if (distance + stepDist >= totalMeters) {
        final double remaining = totalMeters - distance;
        final double frac = (remaining / math.max(0.001, stepDist)).clamp(0.0, 1.0);
        elapsed += dtSeconds * frac;
        distance = totalMeters;
      } else {
        elapsed += dtSeconds;
        distance += stepDist;
      }

      speedMs = nextSpeedMs;
      if (speedMs > peakSpeedMs) {
        peakSpeedMs = speedMs;
      }

      final double wetPenalty = (1.0 - input.surfaceGripMultiplier).clamp(0.0, 0.5);
      final double stepSlip = ((isBraking || isApex)
              ? (0.04 + wetPenalty * 0.25) * input.aggression.slipRiskMultiplier
              : 0.015 * input.aggression.slipRiskMultiplier)
          .clamp(0.0, 0.95);
      if (stepSlip > peakSlipRisk) {
        peakSlipRisk = stepSlip;
      }
    }

    return _SinglePassResult(
      totalTimeSeconds: elapsed,
      peakSpeedMs: peakSpeedMs,
      supertuckPercentage:
          totalSteps > 0 ? (supertuckSteps / totalSteps) * 100.0 : 0.0,
      avgBrakingDelayMeters:
          brakingSteps > 0 ? brakingDelaySum / brakingSteps : 0.0,
      avgSupertuckCdA: supertuckSteps > 0
          ? supertuckCdaSum / supertuckSteps
          : DescenderAeroPosture.drops.baseCdA,
      peakSlipRisk: peakSlipRisk,
    );
  }
}

class _SinglePassResult {
  final double totalTimeSeconds;
  final double peakSpeedMs;
  final double supertuckPercentage;
  final double avgBrakingDelayMeters;
  final double avgSupertuckCdA;
  final double peakSlipRisk;

  const _SinglePassResult({
    required this.totalTimeSeconds,
    required this.peakSpeedMs,
    required this.supertuckPercentage,
    required this.avgBrakingDelayMeters,
    required this.avgSupertuckCdA,
    required this.peakSlipRisk,
  });
}
