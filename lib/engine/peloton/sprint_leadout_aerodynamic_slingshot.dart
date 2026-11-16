import 'dart:math' as math;

import '../../core/constants/physics_constants.dart';

/// Faza manewru "procy aerodynamicznej" na ostatnich 250 m etapu.
enum SlingshotPhase {
  /// Poza strefą ostatnich 250 m lub bez aktywnego rozprowadzenia.
  inactive,

  /// Sprinter jedzie bezpośrednio na kole rozprowadzającego (przygotowanie do skoku).
  draftingLeadout,

  /// Pierwsze 1.5 s po wyskoczeniu z koła — opóźnione narastanie oporu czołowego.
  delayedDragRamp,

  /// Po upływie 1.5 s — pełny opór czołowy przy szczytowej prędkości sprinterskiej.
  fullExposureSprint,

  /// Przekroczono linię mety.
  completed;

  String toJson() => name;

  static SlingshotPhase fromJson(String value) {
    return SlingshotPhase.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SlingshotPhase.inactive,
    );
  }
}

/// Dane wejściowe dla symulacji efektu "procy aerodynamicznej" w końcówce etapu.
class SprintSlingshotInput {
  /// Identyfikator sprintera wykonującego finisz.
  final String sprinterId;

  /// Identyfikator rozprowadzającego (Lead-out Man), z którego koła wyskakuje sprinter.
  final String? leadoutRiderId;

  /// Pozostały dystans do linii mety w momencie rozpoczęcia manewru [m].
  final double distanceToFinishMeters;

  /// Prędkość początkowa w momencie wyskoku z koła rozprowadzającego [km/h].
  final double launchSpeedKmh;

  /// Całkowita pojemność beztlenowa W' sprintera [J].
  final double wPrimeTotalJoules;

  /// Pozostała energia beztlenowa W' w momencie wyskoku [J].
  final double wPrimeRemainingJoules;

  /// Moc krytyczna (CP / FTP) sprintera [W].
  final double criticalPowerWatts;

  /// Opcjonalna jawna moc szczytowa sprintera [W]. Gdy null, wyliczana ze skilla i masy.
  final double? peakSprintWatts;

  /// Umiejętność sprintu kolarza (1–100).
  final int sprintSkill;

  /// Masa ciała sprintera [kg].
  final double riderMassKg;

  /// Masa roweru [kg].
  final double bikeMassKg;

  /// Współczynnik oporu aerodynamicznego sprintera w dolnym chwycie [m^2].
  final double sprinterCdA;

  /// Współczynnik oporów toczenia opon (Crr).
  final double crr;

  /// Gęstość powietrza [kg/m^3].
  final double airDensityKgM3;

  /// Nachylenie drogi na ostatnich 250 m [%].
  final double roadGradientPercent;

  /// Składowa wiatru czołowego wzdłuż osi drogi [m/s] (>0 w twarz, <0 w plecy).
  final double headwindMs;

  /// Straty mechaniczne napędu (ułamek, np. 0.025 = 2.5%).
  final double drivetrainLoss;

  /// Czy sprinter wyskakuje z koła rozprowadzającego (`Lead-out Man`).
  final bool hasLeadoutWheel;

  /// Początkowy mnożnik oporu czołowego tuż za kołem rozprowadzającego (domyślnie 0.42).
  final double leadoutInitialDragMultiplier;

  const SprintSlingshotInput({
    required this.sprinterId,
    this.leadoutRiderId,
    this.distanceToFinishMeters =
        SprintLeadoutAerodynamicSlingshot.activationDistanceMeters,
    this.launchSpeedKmh =
        SprintLeadoutAerodynamicSlingshot.defaultLaunchSpeedKmh,
    this.wPrimeTotalJoules = 24000.0,
    this.wPrimeRemainingJoules = 24000.0,
    this.criticalPowerWatts = 410.0,
    this.peakSprintWatts,
    this.sprintSkill = 90,
    this.riderMassKg = 74.0,
    this.bikeMassKg = 7.2,
    this.sprinterCdA = 0.275,
    this.crr = 0.0035,
    this.airDensityKgM3 = PhysicsConstants.seaLevelAirDensity,
    this.roadGradientPercent = 0.0,
    this.headwindMs = 0.0,
    this.drivetrainLoss = 0.025,
    this.hasLeadoutWheel = true,
    this.leadoutInitialDragMultiplier =
        SprintLeadoutAerodynamicSlingshot.defaultInitialDragMultiplier,
  });

  /// Ułamek pozostałego W' (0.0 – 1.0).
  double get wPrimeRemainingFraction {
    if (wPrimeTotalJoules <= 0.0) {
      return 0.0;
    }
    return (wPrimeRemainingJoules / wPrimeTotalJoules).clamp(0.0, 1.0);
  }

  /// Łączna masa układu kolarz + rower [kg].
  double get totalMassKg => math.max(45.0, riderMassKg + bikeMassKg);

  SprintSlingshotInput copyWith({
    String? sprinterId,
    String? leadoutRiderId,
    double? distanceToFinishMeters,
    double? launchSpeedKmh,
    double? wPrimeTotalJoules,
    double? wPrimeRemainingJoules,
    double? criticalPowerWatts,
    double? peakSprintWatts,
    int? sprintSkill,
    double? riderMassKg,
    double? bikeMassKg,
    double? sprinterCdA,
    double? crr,
    double? airDensityKgM3,
    double? roadGradientPercent,
    double? headwindMs,
    double? drivetrainLoss,
    bool? hasLeadoutWheel,
    double? leadoutInitialDragMultiplier,
  }) {
    return SprintSlingshotInput(
      sprinterId: sprinterId ?? this.sprinterId,
      leadoutRiderId: leadoutRiderId ?? this.leadoutRiderId,
      distanceToFinishMeters:
          distanceToFinishMeters ?? this.distanceToFinishMeters,
      launchSpeedKmh: launchSpeedKmh ?? this.launchSpeedKmh,
      wPrimeTotalJoules: wPrimeTotalJoules ?? this.wPrimeTotalJoules,
      wPrimeRemainingJoules:
          wPrimeRemainingJoules ?? this.wPrimeRemainingJoules,
      criticalPowerWatts: criticalPowerWatts ?? this.criticalPowerWatts,
      peakSprintWatts: peakSprintWatts ?? this.peakSprintWatts,
      sprintSkill: sprintSkill ?? this.sprintSkill,
      riderMassKg: riderMassKg ?? this.riderMassKg,
      bikeMassKg: bikeMassKg ?? this.bikeMassKg,
      sprinterCdA: sprinterCdA ?? this.sprinterCdA,
      crr: crr ?? this.crr,
      airDensityKgM3: airDensityKgM3 ?? this.airDensityKgM3,
      roadGradientPercent: roadGradientPercent ?? this.roadGradientPercent,
      headwindMs: headwindMs ?? this.headwindMs,
      drivetrainLoss: drivetrainLoss ?? this.drivetrainLoss,
      hasLeadoutWheel: hasLeadoutWheel ?? this.hasLeadoutWheel,
      leadoutInitialDragMultiplier:
          leadoutInitialDragMultiplier ?? this.leadoutInitialDragMultiplier,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sprinterId': sprinterId,
      'leadoutRiderId': leadoutRiderId,
      'distanceToFinishMeters': distanceToFinishMeters,
      'launchSpeedKmh': launchSpeedKmh,
      'wPrimeTotalJoules': wPrimeTotalJoules,
      'wPrimeRemainingJoules': wPrimeRemainingJoules,
      'criticalPowerWatts': criticalPowerWatts,
      'peakSprintWatts': peakSprintWatts,
      'sprintSkill': sprintSkill,
      'riderMassKg': riderMassKg,
      'bikeMassKg': bikeMassKg,
      'sprinterCdA': sprinterCdA,
      'crr': crr,
      'airDensityKgM3': airDensityKgM3,
      'roadGradientPercent': roadGradientPercent,
      'headwindMs': headwindMs,
      'drivetrainLoss': drivetrainLoss,
      'hasLeadoutWheel': hasLeadoutWheel,
      'leadoutInitialDragMultiplier': leadoutInitialDragMultiplier,
    };
  }

  factory SprintSlingshotInput.fromJson(Map<String, dynamic> json) {
    return SprintSlingshotInput(
      sprinterId: json['sprinterId'] as String,
      leadoutRiderId: json['leadoutRiderId'] as String?,
      distanceToFinishMeters:
          (json['distanceToFinishMeters'] as num?)?.toDouble() ??
              SprintLeadoutAerodynamicSlingshot.activationDistanceMeters,
      launchSpeedKmh: (json['launchSpeedKmh'] as num?)?.toDouble() ??
          SprintLeadoutAerodynamicSlingshot.defaultLaunchSpeedKmh,
      wPrimeTotalJoules:
          (json['wPrimeTotalJoules'] as num?)?.toDouble() ?? 24000.0,
      wPrimeRemainingJoules:
          (json['wPrimeRemainingJoules'] as num?)?.toDouble() ?? 24000.0,
      criticalPowerWatts:
          (json['criticalPowerWatts'] as num?)?.toDouble() ?? 410.0,
      peakSprintWatts: (json['peakSprintWatts'] as num?)?.toDouble(),
      sprintSkill: (json['sprintSkill'] as num?)?.toInt() ?? 90,
      riderMassKg: (json['riderMassKg'] as num?)?.toDouble() ?? 74.0,
      bikeMassKg: (json['bikeMassKg'] as num?)?.toDouble() ?? 7.2,
      sprinterCdA: (json['sprinterCdA'] as num?)?.toDouble() ?? 0.275,
      crr: (json['crr'] as num?)?.toDouble() ?? 0.0035,
      airDensityKgM3: (json['airDensityKgM3'] as num?)?.toDouble() ??
          PhysicsConstants.seaLevelAirDensity,
      roadGradientPercent:
          (json['roadGradientPercent'] as num?)?.toDouble() ?? 0.0,
      headwindMs: (json['headwindMs'] as num?)?.toDouble() ?? 0.0,
      drivetrainLoss: (json['drivetrainLoss'] as num?)?.toDouble() ?? 0.025,
      hasLeadoutWheel: json['hasLeadoutWheel'] as bool? ?? true,
      leadoutInitialDragMultiplier:
          (json['leadoutInitialDragMultiplier'] as num?)?.toDouble() ??
              SprintLeadoutAerodynamicSlingshot.defaultInitialDragMultiplier,
    );
  }
}

/// Pojedyncza próbka telemetrii kroku symulacji efektu "procy aerodynamicznej".
class SprintSlingshotStepResult {
  /// Czas od momentu wyskoku z koła rozprowadzającego [s].
  final double elapsedSeconds;

  /// Pozostały dystans do linii mety [m].
  final double distanceToFinishMeters;

  /// Dystans pokonany od momentu wyskoku [m].
  final double distanceCoveredMeters;

  /// Prędkość sprintera [m/s].
  final double speedMs;

  /// Prędkość sprintera [km/h].
  double get speedKmh => speedMs * 3.6;

  /// Przyspieszenie liniowe [m/s^2].
  final double accelerationMs2;

  /// Mnożnik oporu czołowego (0.42–1.00 w trakcie narastania przez 1.5 s, potem 1.00).
  final double frontalDragMultiplier;

  /// Efektywny współczynnik oporu CdA w danym kroku [m^2].
  final double effectiveCdA;

  /// Chwilowa moc generowana przez sprintera [W].
  final double powerOutputWatts;

  /// Chwilowa siła oporu aerodynamicznego [N].
  final double aeroDragForceNewtons;

  /// Pozostała pojemność W' [J].
  final double wPrimeRemainingJoules;

  /// Pozostały ułamek W' (0.0 – 1.0).
  final double wPrimeRemainingFraction;

  /// Aktualna faza manewru.
  final SlingshotPhase phase;

  /// Czy w tym kroku działa opóźnienie narastania oporu czołowego.
  bool get isSlingshotBoostActive => phase == SlingshotPhase.delayedDragRamp;

  const SprintSlingshotStepResult({
    required this.elapsedSeconds,
    required this.distanceToFinishMeters,
    required this.distanceCoveredMeters,
    required this.speedMs,
    required this.accelerationMs2,
    required this.frontalDragMultiplier,
    required this.effectiveCdA,
    required this.powerOutputWatts,
    required this.aeroDragForceNewtons,
    required this.wPrimeRemainingJoules,
    required this.wPrimeRemainingFraction,
    required this.phase,
  });
}

/// Podsumowanie pełnej symulacji finiszu na ostatnich 250 m z efektem procy.
class SprintSlingshotSimulationSummary {
  /// Osiągnięta prędkość szczytowa [km/h].
  final double peakSpeedKmh;

  /// Osiągnięta prędkość szczytowa [m/s].
  double get peakSpeedMs => peakSpeedKmh / 3.6;

  /// Czas do osiągnięcia prędkości szczytowej od wyskoku z koła [s].
  final double timeToPeakSpeedSeconds;

  /// Całkowity czas pokonania pozostałego dystansu do mety [s].
  final double finishTimeSeconds;

  /// Prędkość dokładnie po 1.5 s narastania oporu czołowego [km/h].
  final double speedAt1500msKmh;

  /// Prędkość szczytowa w wariancie kontrolnym bez procy (natychmiastowy pełny opór) [km/h].
  final double peakSpeedWithoutSlingshotKmh;

  /// Zysk prędkości szczytowej dzięki efektowi procy aerodynamicznej [km/h].
  double get slingshotSpeedGainKmh =>
      peakSpeedKmh - peakSpeedWithoutSlingshotKmh;

  /// Pozostała energia W' na linii mety [J].
  final double finalWPrimeRemainingJoules;

  /// Czy efekt procy został uruchomiony.
  final bool slingshotTriggered;

  /// Pełna oś czasu kroków symulacji.
  final List<SprintSlingshotStepResult> timeline;

  const SprintSlingshotSimulationSummary({
    required this.peakSpeedKmh,
    required this.timeToPeakSpeedSeconds,
    required this.finishTimeSeconds,
    required this.speedAt1500msKmh,
    required this.peakSpeedWithoutSlingshotKmh,
    required this.finalWPrimeRemainingJoules,
    required this.slingshotTriggered,
    required this.timeline,
  });
}

/// Silnik fizyki efektu "procy aerodynamicznej" (`Aerodynamic Slingshot`)
/// na ostatnich 250 m sprinterskiego finiszu.
///
/// Gdy sprinter wyskakuje z koła swojego rozprowadzającego (`Lead-out Man`)
/// przy ok. 65 km/h z pełnym zasobem W', opór czołowy narasta z opóźnieniem
/// przez pierwsze 1.5 s (przeniesienie pędu strugi i opóźniona separacja warstwy
/// przyściennej), pozwalając osiągnąć szczytowe 72–76 km/h.
class SprintLeadoutAerodynamicSlingshot {
  SprintLeadoutAerodynamicSlingshot._();

  /// Maksymalny dystans do mety, na którym aktywuje się proca aerodynamiczna [m].
  static const double activationDistanceMeters = 250.0;

  /// Czas opóźnionego narastania oporu czołowego po wyskoczeniu z koła [s].
  static const double dragRampDurationSeconds = 1.5;

  /// Wzorcowa prędkość wyprowadzenia przez Lead-out Mana [km/h].
  static const double defaultLaunchSpeedKmh = 65.0;

  /// Początkowy mnożnik oporu czołowego w momencie wyskoku z tunelu aero.
  static const double defaultInitialDragMultiplier = 0.42;

  /// Dolna granica docelowej prędkości szczytowej przy pełnym W' [km/h].
  static const double targetPeakSpeedMinKmh = 72.0;

  /// Górna granica docelowej prędkości szczytowej przy pełnym W' [km/h].
  static const double targetPeakSpeedMaxKmh = 76.0;

  /// Sprawdza, czy sprinter znajduje się w strefie i warunkach pozwalających
  /// na aktywację efektu procy aerodynamicznej.
  static bool canActivateSlingshot({
    required double distanceToFinishMeters,
    required bool hasLeadoutWheel,
    double wPrimeRemainingFraction = 1.0,
  }) {
    return distanceToFinishMeters > 0.0 &&
        distanceToFinishMeters <= activationDistanceMeters &&
        hasLeadoutWheel &&
        wPrimeRemainingFraction > 0.05;
  }

  /// Wylicza mnożnik oporu czołowego (0.42–1.00) w funkcji czasu od wyskoczenia
  /// z koła rozprowadzającego.
  ///
  /// Przez pierwsze `1.5 s` mnożnik płynnie narasta (krzywa Hermite'a `smoothstep`)
  /// od [initialDragMultiplier] do `1.0`. Bez koła rozprowadzającego natychmiast
  /// zwraca `1.0`.
  static double computeFrontalDragMultiplier({
    required double elapsedSinceLaunchSeconds,
    required bool hasLeadoutWheel,
    double initialDragMultiplier = defaultInitialDragMultiplier,
    double rampDurationSeconds = dragRampDurationSeconds,
  }) {
    if (!hasLeadoutWheel || rampDurationSeconds <= 0.0) {
      return 1.0;
    }

    final double clampedInitial = initialDragMultiplier.clamp(0.30, 1.0);
    if (elapsedSinceLaunchSeconds <= 0.0) {
      return clampedInitial;
    }
    if (elapsedSinceLaunchSeconds >= rampDurationSeconds) {
      return 1.0;
    }

    final double u =
        (elapsedSinceLaunchSeconds / rampDurationSeconds).clamp(0.0, 1.0);
    // Krzywa S-kształtna smoothstep: 3u^2 - 2u^3 (łagodny start w strudze i płynne wyjście)
    final double smooth = u * u * (3.0 - 2.0 * u);
    return clampedInitial + (1.0 - clampedInitial) * smooth;
  }

  /// Wyznacza moc szczytową sprintera [W] na podstawie jego umiejętności sprintu,
  /// masy ciała oraz aktualnego poziomu pozostałego W'.
  static double calculateEffectiveSprintWatts({
    required int sprintSkill,
    required double riderMassKg,
    required double criticalPowerWatts,
    required double wPrimeRemainingFraction,
    double? explicitPeakWatts,
  }) {
    final double clampedFraction = wPrimeRemainingFraction.clamp(0.0, 1.0);
    final double basePeakWatts;
    if (explicitPeakWatts != null && explicitPeakWatts > 0.0) {
      basePeakWatts = explicitPeakWatts;
    } else {
      final double clampedSkill = sprintSkill.clamp(1, 100).toDouble();
      // Kalibracja: dla skilla 80–99 i masy 74 kg daje ~1445–1695 W,
      // co z efektem procy przy 65 km/h generuje szczytowe 72–76 km/h.
      final double wattsPerKg = 15.2 + (clampedSkill * 0.078);
      basePeakWatts = riderMassKg * wattsPerKg;
    }

    if (clampedFraction <= 0.0) {
      return criticalPowerWatts;
    }

    // Pełna moc eksplozywna powyżej 25% W', płynny spadek do CP przy wyczerpaniu W'.
    final double powerRetention = clampedFraction >= 0.25
        ? 0.94 + 0.06 * ((clampedFraction - 0.25) / 0.75)
        : 0.94 * math.sqrt(clampedFraction / 0.25);

    return math.max(
      criticalPowerWatts,
      criticalPowerWatts +
          (basePeakWatts - criticalPowerWatts) * powerRetention,
    );
  }

  /// Wykonuje pojedynczy krok symulacji ruchu sprintera w trakcie finiszu.
  static SprintSlingshotStepResult step({
    required SprintSlingshotInput input,
    required double elapsedSeconds,
    required double currentSpeedMs,
    required double distanceToFinishMeters,
    required double distanceCoveredMeters,
    required double wPrimeRemainingJoules,
    required double timeStepSeconds,
  }) {
    final double dt = timeStepSeconds.clamp(0.005, 0.5);
    final bool slingshotActive = input.hasLeadoutWheel &&
        distanceToFinishMeters <= activationDistanceMeters &&
        distanceToFinishMeters > 0.0;

    final double dragMultiplier = computeFrontalDragMultiplier(
      elapsedSinceLaunchSeconds: elapsedSeconds,
      hasLeadoutWheel: slingshotActive,
      initialDragMultiplier: input.leadoutInitialDragMultiplier,
    );

    final double effectiveCdA = input.sprinterCdA * dragMultiplier;
    final double wFraction = input.wPrimeTotalJoules > 0.0
        ? (wPrimeRemainingJoules / input.wPrimeTotalJoules).clamp(0.0, 1.0)
        : 0.0;

    final double powerWatts = calculateEffectiveSprintWatts(
      sprintSkill: input.sprintSkill,
      riderMassKg: input.riderMassKg,
      criticalPowerWatts: input.criticalPowerWatts,
      wPrimeRemainingFraction: wFraction,
      explicitPeakWatts: input.peakSprintWatts,
    );

    final double effectiveSpeed = math.max(0.35, currentSpeedMs);
    final double efficiency = 1.0 - input.drivetrainLoss.clamp(0.0, 0.20);
    final double propulsionForce = (powerWatts * efficiency) / effectiveSpeed;

    final double apparentAirSpeedMs =
        math.max(0.0, currentSpeedMs + input.headwindMs);
    final double aeroForce = 0.5 *
        input.airDensityKgM3 *
        effectiveCdA *
        apparentAirSpeedMs *
        apparentAirSpeedMs;

    final double slopeAngleRad = math.atan(input.roadGradientPercent / 100.0);
    final double totalMass = input.totalMassKg;
    final double gravityForce =
        totalMass * PhysicsConstants.gravity * math.sin(slopeAngleRad);
    final double rollingForce = totalMass *
        PhysicsConstants.gravity *
        math.cos(slopeAngleRad) *
        input.crr;

    final double netForce =
        propulsionForce - (aeroForce + gravityForce + rollingForce);
    final double acceleration = netForce / totalMass;

    final double nextSpeedMs = math.max(0.0, currentSpeedMs + acceleration * dt);
    final double avgSpeedMs = 0.5 * (currentSpeedMs + nextSpeedMs);
    final double deltaDistance = avgSpeedMs * dt;
    final double nextDistanceToFinish =
        math.max(0.0, distanceToFinishMeters - deltaDistance);
    final double nextDistanceCovered = distanceCoveredMeters + deltaDistance;

    final double anaerobicDrainJoules =
        math.max(0.0, powerWatts - input.criticalPowerWatts) * dt;
    final double nextWPrimeJoules =
        math.max(0.0, wPrimeRemainingJoules - anaerobicDrainJoules);
    final double nextWFraction = input.wPrimeTotalJoules > 0.0
        ? (nextWPrimeJoules / input.wPrimeTotalJoules).clamp(0.0, 1.0)
        : 0.0;

    final double nextElapsed = elapsedSeconds + dt;
    final SlingshotPhase phase;
    if (nextDistanceToFinish <= 0.0) {
      phase = SlingshotPhase.completed;
    } else if (!slingshotActive) {
      phase = SlingshotPhase.inactive;
    } else if (nextElapsed <= dragRampDurationSeconds) {
      phase = SlingshotPhase.delayedDragRamp;
    } else {
      phase = SlingshotPhase.fullExposureSprint;
    }

    return SprintSlingshotStepResult(
      elapsedSeconds: nextElapsed,
      distanceToFinishMeters: nextDistanceToFinish,
      distanceCoveredMeters: nextDistanceCovered,
      speedMs: nextSpeedMs,
      accelerationMs2: acceleration,
      frontalDragMultiplier: dragMultiplier,
      effectiveCdA: effectiveCdA,
      powerOutputWatts: powerWatts,
      aeroDragForceNewtons: aeroForce,
      wPrimeRemainingJoules: nextWPrimeJoules,
      wPrimeRemainingFraction: nextWFraction,
      phase: phase,
    );
  }

  /// Symuluje pełny finisz na ostatnich <= 250 m i zwraca telemetrię szczytową
  /// wraz z porównaniem do wariantu bez efektu procy aerodynamicznej.
  static SprintSlingshotSimulationSummary simulateFinal250m(
    SprintSlingshotInput input, {
    double timeStepSeconds = 0.05,
  }) {
    final double dt = timeStepSeconds.clamp(0.01, 0.25);
    final _SimulationRun primaryRun = _runSimulation(input, dt: dt);

    final double baselinePeakKmh;
    if (input.hasLeadoutWheel) {
      final _SimulationRun baselineRun = _runSimulation(
        input.copyWith(hasLeadoutWheel: false),
        dt: dt,
      );
      baselinePeakKmh = baselineRun.peakSpeedKmh;
    } else {
      baselinePeakKmh = primaryRun.peakSpeedKmh;
    }

    return SprintSlingshotSimulationSummary(
      peakSpeedKmh: primaryRun.peakSpeedKmh,
      timeToPeakSpeedSeconds: primaryRun.timeToPeakSpeedSeconds,
      finishTimeSeconds: primaryRun.finishTimeSeconds,
      speedAt1500msKmh: primaryRun.speedAt1500msKmh,
      peakSpeedWithoutSlingshotKmh: baselinePeakKmh,
      finalWPrimeRemainingJoules: primaryRun.finalWPrimeRemainingJoules,
      slingshotTriggered: canActivateSlingshot(
        distanceToFinishMeters: input.distanceToFinishMeters,
        hasLeadoutWheel: input.hasLeadoutWheel,
        wPrimeRemainingFraction: input.wPrimeRemainingFraction,
      ),
      timeline: primaryRun.timeline,
    );
  }

  static _SimulationRun _runSimulation(
    SprintSlingshotInput input, {
    required double dt,
  }) {
    double elapsed = 0.0;
    double speedMs = math.max(0.0, input.launchSpeedKmh / 3.6);
    double distanceRemaining = math.max(0.0, input.distanceToFinishMeters);
    double distanceCovered = 0.0;
    double wPrime = math.max(0.0, input.wPrimeRemainingJoules);

    double peakSpeedMs = speedMs;
    double timeToPeak = 0.0;
    double speedAt1500msKmh = input.launchSpeedKmh;
    bool captured1500ms = false;

    final List<SprintSlingshotStepResult> timeline =
        <SprintSlingshotStepResult>[];

    // Bezpieczny górny limit iteracji (max 60 s dla finiszu 250 m).
    const int maxSteps = 6000;
    for (int i = 0; i < maxSteps && distanceRemaining > 0.0; i++) {
      final SprintSlingshotStepResult stepResult = step(
        input: input,
        elapsedSeconds: elapsed,
        currentSpeedMs: speedMs,
        distanceToFinishMeters: distanceRemaining,
        distanceCoveredMeters: distanceCovered,
        wPrimeRemainingJoules: wPrime,
        timeStepSeconds: dt,
      );

      timeline.add(stepResult);
      elapsed = stepResult.elapsedSeconds;
      speedMs = stepResult.speedMs;
      distanceRemaining = stepResult.distanceToFinishMeters;
      distanceCovered = stepResult.distanceCoveredMeters;
      wPrime = stepResult.wPrimeRemainingJoules;

      if (speedMs > peakSpeedMs) {
        peakSpeedMs = speedMs;
        timeToPeak = elapsed;
      }

      if (!captured1500ms && elapsed >= dragRampDurationSeconds) {
        speedAt1500msKmh = stepResult.speedKmh;
        captured1500ms = true;
      }
    }

    if (!captured1500ms && timeline.isNotEmpty) {
      speedAt1500msKmh = timeline.last.speedKmh;
    }

    return _SimulationRun(
      peakSpeedKmh: peakSpeedMs * 3.6,
      timeToPeakSpeedSeconds: timeToPeak,
      finishTimeSeconds: elapsed,
      speedAt1500msKmh: speedAt1500msKmh,
      finalWPrimeRemainingJoules: wPrime,
      timeline: timeline,
    );
  }
}

class _SimulationRun {
  final double peakSpeedKmh;
  final double timeToPeakSpeedSeconds;
  final double finishTimeSeconds;
  final double speedAt1500msKmh;
  final double finalWPrimeRemainingJoules;
  final List<SprintSlingshotStepResult> timeline;

  const _SimulationRun({
    required this.peakSpeedKmh,
    required this.timeToPeakSpeedSeconds,
    required this.finishTimeSeconds,
    required this.speedAt1500msKmh,
    required this.finalWPrimeRemainingJoules,
    required this.timeline,
  });
}
