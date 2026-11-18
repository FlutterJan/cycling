import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';

/// Poziom agresywności taktycznej w walce o koło rozprowadzającego na ostatnich 3 km.
enum WheelFightTacticAggression {
  /// Czysta obrona toru jazdy — minimalne ryzyko kary UCI, niższy opór boczny.
  cleanDefensive(
    labelPl: 'Czysta Obrona',
    shortTag: 'CZYSTO',
    tacticalAggression: 0.35,
    forceMultiplier: 0.88,
    uciRiskMultiplier: 0.28,
    wPrimeCostMultiplier: 0.75,
  ),

  /// Standardowy opór barkiem w bark przy 62 km/h — optymalny balans siły i przepisów.
  balancedShoulderHold(
    labelPl: 'Opór Barkiem',
    shortTag: 'BARK W BARK',
    tacticalAggression: 0.65,
    forceMultiplier: 1.00,
    uciRiskMultiplier: 0.68,
    wPrimeCostMultiplier: 1.00,
  ),

  /// Walka na granicy przepisów UCI — wysokie wykorzystanie masy ciała i core.
  razorEdgeAggressive(
    labelPl: 'Na Granicy UCI',
    shortTag: 'GRANICA UCI',
    tacticalAggression: 0.90,
    forceMultiplier: 1.15,
    uciRiskMultiplier: 1.38,
    wPrimeCostMultiplier: 1.25,
  ),

  /// Niebezpieczne wypychanie łokciem / zmianą toru — wysokie ryzyko żółtej kartki i relegacji.
  recklessBarge(
    labelPl: 'Ostry Łokieć (Ryzyko)',
    shortTag: 'RYZYKO UCI',
    tacticalAggression: 1.00,
    forceMultiplier: 1.24,
    uciRiskMultiplier: 2.30,
    wPrimeCostMultiplier: 1.45,
  );

  final String labelPl;
  final String shortTag;
  final double tacticalAggression;
  final double forceMultiplier;
  final double uciRiskMultiplier;
  final double wPrimeCostMultiplier;

  const WheelFightTacticAggression({
    required this.labelPl,
    required this.shortTag,
    required this.tacticalAggression,
    required this.forceMultiplier,
    required this.uciRiskMultiplier,
    required this.wPrimeCostMultiplier,
  });

  String toJson() => name;

  static WheelFightTacticAggression fromJson(String value) {
    return WheelFightTacticAggression.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => WheelFightTacticAggression.balancedShoulderHold,
    );
  }
}

/// Faza walki o koło rozprowadzającego w pociągu sprinterskim.
enum WheelFightPhase {
  /// Poza strefą ostatnich 3 km — brak wzmożonej walki o koło.
  outsideFinal3Km,

  /// Utrzymanie pewnej pozycji na kole rozprowadzającego bez silnego nacisku rywala.
  holdingLeadoutWheel,

  /// Aktywny opór barkiem w bark przy ~62 km/h przeciwko wcinającemu się rywalowi.
  shoulderToShoulderDuel,

  /// Skuteczne odepchnięcie rywala dzięki masie ciała, sile core i Race IQ.
  fendingOffIntruder,

  /// Utrata koła rozprowadzającego na rzecz silniejszego lub bardziej agresywnego rywala.
  wheelLostToRival,

  /// Ostrzeżenie / żółta kartka UCI za niebezpieczne odchylenie toru jazdy.
  uciWarningIssued,

  /// Relegacja na koniec grupy za złamanie przepisów sprinterskich UCI.
  uciRelegationTriggered;

  String get labelPl {
    switch (this) {
      case WheelFightPhase.outsideFinal3Km:
        return 'Poza Strefą 3 km';
      case WheelFightPhase.holdingLeadoutWheel:
        return 'Pewne Koło Rozprowadzającego';
      case WheelFightPhase.shoulderToShoulderDuel:
        return 'Walka Bark w Bark (62 km/h)';
      case WheelFightPhase.fendingOffIntruder:
        return 'Rywal Odepchnięty';
      case WheelFightPhase.wheelLostToRival:
        return 'Utrata Koła na Rzecz Rywala';
      case WheelFightPhase.uciWarningIssued:
        return 'Żółta Kartka UCI';
      case WheelFightPhase.uciRelegationTriggered:
        return 'Relegacja UCI!';
    }
  }

  String toJson() => name;

  static WheelFightPhase fromJson(String value) {
    return WheelFightPhase.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => WheelFightPhase.holdingLeadoutWheel,
    );
  }
}

/// Werdykt sędziowski UCI (Art. 2.3.036) oceniający legalność walki o koło.
enum UciElbowRuleVerdict {
  /// Regulaminowy kontakt barkiem w bark bez zmiany toru jazdy.
  cleanContact,

  /// Agresywny opór na granicy przepisów — obserwowany przez kamerę VAR.
  borderlineLean,

  /// Ostrzeżenie i żółta kartka UCI za niebezpieczne zajeżdżanie drogi.
  yellowCardWarning,

  /// Relegacja na koniec peletonu i grzywna 200 CHF.
  relegationAndFine;

  String get labelPl {
    switch (this) {
      case UciElbowRuleVerdict.cleanContact:
        return 'Kontakt Regulaminowy';
      case UciElbowRuleVerdict.borderlineLean:
        return 'Na Granicy Przepisów (VAR)';
      case UciElbowRuleVerdict.yellowCardWarning:
        return 'Żółta Kartka UCI (Art. 2.3.036)';
      case UciElbowRuleVerdict.relegationAndFine:
        return 'Relegacja + 200 CHF';
    }
  }

  String toJson() => name;

  static UciElbowRuleVerdict fromJson(String value) {
    return UciElbowRuleVerdict.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => UciElbowRuleVerdict.cleanContact,
    );
  }
}

/// Profil fizyczny i taktyczny kolarza biorącego udział w walce o koło.
class WheelFightRiderProfile {
  final String riderId;
  final String riderName;
  final String teamName;
  final double weightKg;
  final int coreStrength;
  final int sprint;
  final int raceIq;
  final int bikeHandling;
  final double remainingWPrimePct;

  const WheelFightRiderProfile({
    required this.riderId,
    required this.riderName,
    required this.teamName,
    required this.weightKg,
    required this.coreStrength,
    required this.sprint,
    required this.raceIq,
    required this.bikeHandling,
    this.remainingWPrimePct = 85.0,
  });

  /// Indeks stabilności bocznej (0–100) łączący masę ciała, siłę core oraz panowanie nad rowerem.
  double get lateralStabilityIndex {
    final weightScore = ((weightKg - 55.0) / 35.0 * 100.0).clamp(0.0, 100.0);
    return (weightScore * 0.38 +
            coreStrength.clamp(1, 100) * 0.42 +
            bikeHandling.clamp(1, 100) * 0.20)
        .clamp(0.0, 100.0);
  }

  /// Czy zawodnik posiada elitarną świadomość pociągu sprinterskiego (wysoki Race IQ i Sprint).
  bool get hasEliteLeadoutAwareness => raceIq >= 78 && sprint >= 78;

  WheelFightRiderProfile copyWith({
    String? riderId,
    String? riderName,
    String? teamName,
    double? weightKg,
    int? coreStrength,
    int? sprint,
    int? raceIq,
    int? bikeHandling,
    double? remainingWPrimePct,
  }) {
    return WheelFightRiderProfile(
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      teamName: teamName ?? this.teamName,
      weightKg: weightKg ?? this.weightKg,
      coreStrength: coreStrength ?? this.coreStrength,
      sprint: sprint ?? this.sprint,
      raceIq: raceIq ?? this.raceIq,
      bikeHandling: bikeHandling ?? this.bikeHandling,
      remainingWPrimePct: remainingWPrimePct ?? this.remainingWPrimePct,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'riderName': riderName,
      'teamName': teamName,
      'weightKg': weightKg,
      'coreStrength': coreStrength,
      'sprint': sprint,
      'raceIq': raceIq,
      'bikeHandling': bikeHandling,
      'remainingWPrimePct': remainingWPrimePct,
    };
  }

  factory WheelFightRiderProfile.fromJson(Map<String, dynamic> json) {
    return WheelFightRiderProfile(
      riderId: json['riderId'] as String? ?? 'rider_0',
      riderName: json['riderName'] as String? ?? 'Sprinter',
      teamName: json['teamName'] as String? ?? 'Team',
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 74.0,
      coreStrength: (json['coreStrength'] as num?)?.toInt() ?? 80,
      sprint: (json['sprint'] as num?)?.toInt() ?? 85,
      raceIq: (json['raceIq'] as num?)?.toInt() ?? 80,
      bikeHandling: (json['bikeHandling'] as num?)?.toInt() ?? 80,
      remainingWPrimePct:
          (json['remainingWPrimePct'] as num?)?.toDouble() ?? 85.0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WheelFightRiderProfile &&
        other.riderId == riderId &&
        other.riderName == riderName &&
        other.teamName == teamName &&
        other.weightKg == weightKg &&
        other.coreStrength == coreStrength &&
        other.sprint == sprint &&
        other.raceIq == raceIq &&
        other.bikeHandling == bikeHandling &&
        other.remainingWPrimePct == remainingWPrimePct;
  }

  @override
  int get hashCode => Object.hash(
        riderId,
        riderName,
        teamName,
        weightKg,
        coreStrength,
        sprint,
        raceIq,
        bikeHandling,
        remainingWPrimePct,
      );
}

/// Dane wejściowe pojedynczego kroku symulacji walki o koło na ostatnich 3 km.
class WheelFightStepInput {
  final WheelFightRiderProfile defender;
  final WheelFightRiderProfile challenger;
  final double distanceToFinishKm;
  final double pelotonSpeedKmh;
  final double leadoutWheelGapMeters;
  final double roadWidthMeters;
  final double crosswindSpeedKmh;
  final WheelFightTacticAggression defenderAggression;
  final WheelFightTacticAggression challengerAggression;
  final double deltaSeconds;

  const WheelFightStepInput({
    required this.defender,
    required this.challenger,
    this.distanceToFinishKm = 1.8,
    this.pelotonSpeedKmh = 62.0,
    this.leadoutWheelGapMeters = 0.35,
    this.roadWidthMeters = 6.5,
    this.crosswindSpeedKmh = 10.0,
    this.defenderAggression = WheelFightTacticAggression.balancedShoulderHold,
    this.challengerAggression = WheelFightTacticAggression.balancedShoulderHold,
    this.deltaSeconds = 1.0,
  });

  WheelFightStepInput copyWith({
    WheelFightRiderProfile? defender,
    WheelFightRiderProfile? challenger,
    double? distanceToFinishKm,
    double? pelotonSpeedKmh,
    double? leadoutWheelGapMeters,
    double? roadWidthMeters,
    double? crosswindSpeedKmh,
    WheelFightTacticAggression? defenderAggression,
    WheelFightTacticAggression? challengerAggression,
    double? deltaSeconds,
  }) {
    return WheelFightStepInput(
      defender: defender ?? this.defender,
      challenger: challenger ?? this.challenger,
      distanceToFinishKm: distanceToFinishKm ?? this.distanceToFinishKm,
      pelotonSpeedKmh: pelotonSpeedKmh ?? this.pelotonSpeedKmh,
      leadoutWheelGapMeters:
          leadoutWheelGapMeters ?? this.leadoutWheelGapMeters,
      roadWidthMeters: roadWidthMeters ?? this.roadWidthMeters,
      crosswindSpeedKmh: crosswindSpeedKmh ?? this.crosswindSpeedKmh,
      defenderAggression: defenderAggression ?? this.defenderAggression,
      challengerAggression: challengerAggression ?? this.challengerAggression,
      deltaSeconds: deltaSeconds ?? this.deltaSeconds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'defender': defender.toJson(),
      'challenger': challenger.toJson(),
      'distanceToFinishKm': distanceToFinishKm,
      'pelotonSpeedKmh': pelotonSpeedKmh,
      'leadoutWheelGapMeters': leadoutWheelGapMeters,
      'roadWidthMeters': roadWidthMeters,
      'crosswindSpeedKmh': crosswindSpeedKmh,
      'defenderAggression': defenderAggression.toJson(),
      'challengerAggression': challengerAggression.toJson(),
      'deltaSeconds': deltaSeconds,
    };
  }

  factory WheelFightStepInput.fromJson(Map<String, dynamic> json) {
    return WheelFightStepInput(
      defender: WheelFightRiderProfile.fromJson(
        Map<String, dynamic>.from(json['defender'] as Map? ?? const {}),
      ),
      challenger: WheelFightRiderProfile.fromJson(
        Map<String, dynamic>.from(json['challenger'] as Map? ?? const {}),
      ),
      distanceToFinishKm:
          (json['distanceToFinishKm'] as num?)?.toDouble() ?? 1.8,
      pelotonSpeedKmh: (json['pelotonSpeedKmh'] as num?)?.toDouble() ?? 62.0,
      leadoutWheelGapMeters:
          (json['leadoutWheelGapMeters'] as num?)?.toDouble() ?? 0.35,
      roadWidthMeters: (json['roadWidthMeters'] as num?)?.toDouble() ?? 6.5,
      crosswindSpeedKmh:
          (json['crosswindSpeedKmh'] as num?)?.toDouble() ?? 10.0,
      defenderAggression: WheelFightTacticAggression.fromJson(
        json['defenderAggression'] as String? ?? 'balancedShoulderHold',
      ),
      challengerAggression: WheelFightTacticAggression.fromJson(
        json['challengerAggression'] as String? ?? 'balancedShoulderHold',
      ),
      deltaSeconds: (json['deltaSeconds'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

/// Wynik pojedynczego kroku fizyki walki barkiem w bark o koło rozprowadzającego.
class WheelFightStepResult {
  final WheelFightPhase phase;
  final UciElbowRuleVerdict uciVerdict;
  final bool isInFinal3KmZone;
  final double defenderHoldProbability;
  final double defenderTotalForceNewtons;
  final double challengerIntrusionForceNewtons;
  final double netLateralMarginNewtons;
  final double wheelPositionRetentionPct;
  final double aeroDraftSavedWatts;
  final double isometricCoreWPrimeCostJoules;
  final double uciInfractionRiskPct;
  final double headElbowDeflectionDegrees;
  final double speedNormalizationFactor;
  final String tacticalCommentaryPl;

  const WheelFightStepResult({
    required this.phase,
    required this.uciVerdict,
    required this.isInFinal3KmZone,
    required this.defenderHoldProbability,
    required this.defenderTotalForceNewtons,
    required this.challengerIntrusionForceNewtons,
    required this.netLateralMarginNewtons,
    required this.wheelPositionRetentionPct,
    required this.aeroDraftSavedWatts,
    required this.isometricCoreWPrimeCostJoules,
    required this.uciInfractionRiskPct,
    required this.headElbowDeflectionDegrees,
    required this.speedNormalizationFactor,
    required this.tacticalCommentaryPl,
  });

  Map<String, dynamic> toJson() {
    return {
      'phase': phase.toJson(),
      'uciVerdict': uciVerdict.toJson(),
      'isInFinal3KmZone': isInFinal3KmZone,
      'defenderHoldProbability': defenderHoldProbability,
      'defenderTotalForceNewtons': defenderTotalForceNewtons,
      'challengerIntrusionForceNewtons': challengerIntrusionForceNewtons,
      'netLateralMarginNewtons': netLateralMarginNewtons,
      'wheelPositionRetentionPct': wheelPositionRetentionPct,
      'aeroDraftSavedWatts': aeroDraftSavedWatts,
      'isometricCoreWPrimeCostJoules': isometricCoreWPrimeCostJoules,
      'uciInfractionRiskPct': uciInfractionRiskPct,
      'headElbowDeflectionDegrees': headElbowDeflectionDegrees,
      'speedNormalizationFactor': speedNormalizationFactor,
      'tacticalCommentaryPl': tacticalCommentaryPl,
    };
  }

  factory WheelFightStepResult.fromJson(Map<String, dynamic> json) {
    return WheelFightStepResult(
      phase: WheelFightPhase.fromJson(
        json['phase'] as String? ?? 'holdingLeadoutWheel',
      ),
      uciVerdict: UciElbowRuleVerdict.fromJson(
        json['uciVerdict'] as String? ?? 'cleanContact',
      ),
      isInFinal3KmZone: json['isInFinal3KmZone'] as bool? ?? true,
      defenderHoldProbability:
          (json['defenderHoldProbability'] as num?)?.toDouble() ?? 0.5,
      defenderTotalForceNewtons:
          (json['defenderTotalForceNewtons'] as num?)?.toDouble() ?? 0.0,
      challengerIntrusionForceNewtons:
          (json['challengerIntrusionForceNewtons'] as num?)?.toDouble() ?? 0.0,
      netLateralMarginNewtons:
          (json['netLateralMarginNewtons'] as num?)?.toDouble() ?? 0.0,
      wheelPositionRetentionPct:
          (json['wheelPositionRetentionPct'] as num?)?.toDouble() ?? 100.0,
      aeroDraftSavedWatts:
          (json['aeroDraftSavedWatts'] as num?)?.toDouble() ?? 0.0,
      isometricCoreWPrimeCostJoules:
          (json['isometricCoreWPrimeCostJoules'] as num?)?.toDouble() ?? 0.0,
      uciInfractionRiskPct:
          (json['uciInfractionRiskPct'] as num?)?.toDouble() ?? 0.0,
      headElbowDeflectionDegrees:
          (json['headElbowDeflectionDegrees'] as num?)?.toDouble() ?? 0.0,
      speedNormalizationFactor:
          (json['speedNormalizationFactor'] as num?)?.toDouble() ?? 1.0,
      tacticalCommentaryPl: json['tacticalCommentaryPl'] as String? ?? '',
    );
  }
}

/// Próbka historii pojedynku do wykresu telemetrii.
class WheelFightHistorySample {
  final int stepIndex;
  final double distanceToFinishKm;
  final double speedKmh;
  final double wheelRetentionPct;
  final double uciRiskPct;
  final WheelFightPhase phase;

  const WheelFightHistorySample({
    required this.stepIndex,
    required this.distanceToFinishKm,
    required this.speedKmh,
    required this.wheelRetentionPct,
    required this.uciRiskPct,
    required this.phase,
  });

  Map<String, dynamic> toJson() {
    return {
      'stepIndex': stepIndex,
      'distanceToFinishKm': distanceToFinishKm,
      'speedKmh': speedKmh,
      'wheelRetentionPct': wheelRetentionPct,
      'uciRiskPct': uciRiskPct,
      'phase': phase.toJson(),
    };
  }

  factory WheelFightHistorySample.fromJson(Map<String, dynamic> json) {
    return WheelFightHistorySample(
      stepIndex: (json['stepIndex'] as num?)?.toInt() ?? 0,
      distanceToFinishKm:
          (json['distanceToFinishKm'] as num?)?.toDouble() ?? 0.0,
      speedKmh: (json['speedKmh'] as num?)?.toDouble() ?? 62.0,
      wheelRetentionPct:
          (json['wheelRetentionPct'] as num?)?.toDouble() ?? 100.0,
      uciRiskPct: (json['uciRiskPct'] as num?)?.toDouble() ?? 0.0,
      phase: WheelFightPhase.fromJson(
        json['phase'] as String? ?? 'holdingLeadoutWheel',
      ),
    );
  }
}

/// Silnik fizyki walki o koło w pociągu sprinterskim na ostatnich 3 km (`#675`).
///
/// Modeluje:
/// 1. Aktywną obronę koła rozprowadzającego przez sprinterów z wysokim `raceIq` i `sprint`.
/// 2. Fizykę oporu bocznego barkiem w bark przy ~62 km/h (bezwładność masy ciała + siła core + handling).
/// 3. Wpływ agresywności taktycznej oraz weryfikację zgodności z przepisami sędziowskimi UCI (Art. 2.3.036).
/// 4. Zysk aerodynamiczny utrzymania koła (W) vs izometryczny koszt W' mięśni głębokich.
class SprinterElbowRubbingAndWheelFighting {
  SprinterElbowRubbingAndWheelFighting._();

  static const double finalZoneThresholdKm = 3.0;
  static const double referenceSprintSpeedKmh = 62.0;

  /// Oblicza pojedynczy krok fizyki walki barkiem w bark o miejsce na kole rozprowadzającego.
  static WheelFightStepResult evaluateWheelFightStep({
    required WheelFightStepInput input,
    double previousRetentionPct = 88.0,
    double previousUciRiskPct = 8.0,
  }) {
    final distKm = input.distanceToFinishKm.clamp(0.0, 250.0);
    final speedKmh = input.pelotonSpeedKmh.clamp(25.0, 82.0);
    final dt = input.deltaSeconds.clamp(0.1, 10.0);
    final speedFactor =
        (speedKmh / referenceSprintSpeedKmh).clamp(0.60, 1.35);

    // Poza strefą ostatnich 3 km pociągi dopiero się formują — brak bezpośredniej walki bark w bark.
    if (distKm > finalZoneThresholdKm || distKm <= 0.0) {
      return WheelFightStepResult(
        phase: WheelFightPhase.outsideFinal3Km,
        uciVerdict: UciElbowRuleVerdict.cleanContact,
        isInFinal3KmZone: false,
        defenderHoldProbability: 0.95,
        defenderTotalForceNewtons: 0.0,
        challengerIntrusionForceNewtons: 0.0,
        netLateralMarginNewtons: 0.0,
        wheelPositionRetentionPct: previousRetentionPct.clamp(0.0, 100.0),
        aeroDraftSavedWatts: _computeAeroDraftSavedWatts(
          speedKmh: speedKmh,
          gapMeters: input.leadoutWheelGapMeters,
          retentionPct: previousRetentionPct,
        ),
        isometricCoreWPrimeCostJoules: 0.0,
        uciInfractionRiskPct: (previousUciRiskPct * 0.85).clamp(0.0, 100.0),
        headElbowDeflectionDegrees: 0.0,
        speedNormalizationFactor: speedFactor,
        tacticalCommentaryPl: distKm <= 0.0
            ? 'Linia mety przekroczona — pojedynek o koło zakończony.'
            : 'Poza strefą 3 km (${distKm.toStringAsFixed(1)} km) — formowanie pociągu sprinterskiego.',
      );
    }

    // 1. Siła oporu bocznego obrońcy [N] przy 62 km/h:
    // Zależy od masy ciała (bezwładność), siły core (przeniesienie momentu),
    // antycypacji (raceIq + sprint) oraz agresywności taktycznej.
    final defenderForceN = computeShoulderResistanceForceNewtons(
      rider: input.defender,
      aggression: input.defenderAggression,
      speedKmh: speedKmh,
      leadoutWheelGapMeters: input.leadoutWheelGapMeters,
      isDefender: true,
    );

    // 2. Siła natarcia wcinającego się rywala [N]:
    // Zależna od masy rywala, siły core, agresywności oraz dostępnej luki za rozprowadzającym.
    final rawChallengerForceN = computeShoulderResistanceForceNewtons(
      rider: input.challenger,
      aggression: input.challengerAggression,
      speedKmh: speedKmh,
      leadoutWheelGapMeters: input.leadoutWheelGapMeters,
      isDefender: false,
    );

    // Jeśli obrońca ma wysokie Race IQ i Sprint, zamyka lukę zanim rywal włoży przednie koło.
    final anticipationMitigation = _computeAnticipationMitigation(
      defender: input.defender,
      gapMeters: input.leadoutWheelGapMeters,
    );
    final challengerForceN =
        (rawChallengerForceN * anticipationMitigation).clamp(15.0, 500.0);

    final netMarginN = defenderForceN - challengerForceN;

    // 3. Prawdopodobieństwo utrzymania koła (krzywa logistyczna względem różnicy sił w N).
    final holdProbability =
        (1.0 / (1.0 + math.exp(-netMarginN / 28.0))).clamp(0.02, 0.99);

    // 4. Aktualizacja stopnia utrzymania pozycji na kole [0..100%].
    final retentionDeltaPerSec = (netMarginN / 8.5).clamp(-14.0, 12.0);
    final nextRetention =
        (previousRetentionPct + retentionDeltaPerSec * dt).clamp(0.0, 100.0);

    // 5. Ocena odchylenia toru jazdy i ryzyka złamania przepisów UCI (Art. 2.3.036).
    final deflectionDeg = _computeLateralDeflectionDegrees(
      defender: input.defender,
      aggression: input.defenderAggression,
      netMarginN: netMarginN,
      speedFactor: speedFactor,
      roadWidthMeters: input.roadWidthMeters,
      crosswindSpeedKmh: input.crosswindSpeedKmh,
    );

    final riskIncrementPerSec = _computeUciRiskIncrementPerSec(
      defender: input.defender,
      aggression: input.defenderAggression,
      deflectionDeg: deflectionDeg,
      speedFactor: speedFactor,
      roadWidthMeters: input.roadWidthMeters,
    );

    final nextUciRisk = (previousUciRiskPct + riskIncrementPerSec * dt)
        .clamp(0.0, 100.0);

    final uciVerdict = _resolveUciVerdict(
      uciRiskPct: nextUciRisk,
      deflectionDeg: deflectionDeg,
      aggression: input.defenderAggression,
    );

    // 6. Izometryczny koszt W' mięśni głębokich oraz zysk aerodynamiczny w tunelu przy 62 km/h.
    final coreWPrimeCostJ = _computeIsometricCoreWPrimeCost(
      aggression: input.defenderAggression,
      challengerForceN: challengerForceN,
      speedFactor: speedFactor,
      dt: dt,
    );

    final aeroSavedW = _computeAeroDraftSavedWatts(
      speedKmh: speedKmh,
      gapMeters: input.leadoutWheelGapMeters,
      retentionPct: nextRetention,
    );

    // 7. Określenie fazy pojedynku i komunikatu taktycznego.
    final phase = _resolvePhase(
      uciVerdict: uciVerdict,
      nextRetentionPct: nextRetention,
      netMarginN: netMarginN,
    );

    final commentary = _buildCommentaryPl(
      phase: phase,
      uciVerdict: uciVerdict,
      defender: input.defender,
      challenger: input.challenger,
      speedKmh: speedKmh,
      netMarginN: netMarginN,
      aeroSavedW: aeroSavedW,
    );

    return WheelFightStepResult(
      phase: phase,
      uciVerdict: uciVerdict,
      isInFinal3KmZone: true,
      defenderHoldProbability: holdProbability,
      defenderTotalForceNewtons: defenderForceN,
      challengerIntrusionForceNewtons: challengerForceN,
      netLateralMarginNewtons: netMarginN,
      wheelPositionRetentionPct: nextRetention,
      aeroDraftSavedWatts: aeroSavedW,
      isometricCoreWPrimeCostJoules: coreWPrimeCostJ,
      uciInfractionRiskPct: nextUciRisk,
      headElbowDeflectionDegrees: deflectionDeg,
      speedNormalizationFactor: speedFactor,
      tacticalCommentaryPl: commentary,
    );
  }

  /// Oblicza siłę oporu barkiem w bark [N] przy prędkości pociągu sprinterskiego (~62 km/h).
  static double computeShoulderResistanceForceNewtons({
    required WheelFightRiderProfile rider,
    required WheelFightTacticAggression aggression,
    required double speedKmh,
    required double leadoutWheelGapMeters,
    required bool isDefender,
  }) {
    final speedFactor = (speedKmh / referenceSprintSpeedKmh).clamp(0.60, 1.35);

    // Masa ciała generuje bezwładność boczną w kontakcie bark-bark (~1.55 N na kg masy przy 62 km/h).
    final massInertiaN = rider.weightKg.clamp(48.0, 105.0) * 1.55;

    // Siła mięśni core pozwala przenieść ciężar ciała bez utraty równowagi na rowerze.
    final coreTorqueN = rider.coreStrength.clamp(1, 100) * 1.15;

    // Race IQ i Sprint dają przewagę timingu kontaktu i stabilności na pedałach.
    final tacticalTimingBonus =
        (rider.raceIq.clamp(1, 100) * 0.45 + rider.sprint.clamp(1, 100) * 0.35);

    // Spadek stabilności przy wyczerpaniu zapasu beztlenowego W' (<25%).
    final wPrimeFatigueFactor = rider.remainingWPrimePct < 25.0
        ? (0.74 + (rider.remainingWPrimePct.clamp(0.0, 25.0) / 25.0) * 0.26)
        : 1.0;

    // Obrońca jadący ciasno za rozprowadzającym (<0.4 m) ma dodatkową stabilność linii.
    final tightWheelLineBonus =
        isDefender ? (1.0 + (0.6 - leadoutWheelGapMeters.clamp(0.1, 0.6)) * 0.22) : 1.0;

    final baseForce = (massInertiaN + coreTorqueN + tacticalTimingBonus) *
        aggression.forceMultiplier *
        speedFactor *
        wPrimeFatigueFactor *
        tightWheelLineBonus;

    return baseForce.clamp(35.0, 480.0);
  }

  static double _computeAnticipationMitigation({
    required WheelFightRiderProfile defender,
    required double gapMeters,
  }) {
    final awareness =
        (defender.raceIq.clamp(1, 100) * 0.6 + defender.sprint.clamp(1, 100) * 0.4);
    final gapPenalty = (gapMeters.clamp(0.15, 1.5) - 0.25) * 0.14;
    final mitigation = 1.08 - (awareness / 100.0) * 0.22 + gapPenalty;
    return mitigation.clamp(0.76, 1.18);
  }

  static double _computeLateralDeflectionDegrees({
    required WheelFightRiderProfile defender,
    required WheelFightTacticAggression aggression,
    required double netMarginN,
    required double speedFactor,
    required double roadWidthMeters,
    required double crosswindSpeedKmh,
  }) {
    final handlingControl = (110.0 - defender.bikeHandling.clamp(1, 100)) / 100.0;
    final narrowRoadFactor = roadWidthMeters < 5.5 ? 1.22 : 1.0;
    final windPerturbation = (crosswindSpeedKmh.clamp(0.0, 60.0) / 60.0) * 2.4;
    final contactAngle = (2.8 +
            aggression.tacticalAggression * 6.8 +
            handlingControl * 4.2 +
            (netMarginN.abs() / 140.0) * 1.8) *
        speedFactor *
        narrowRoadFactor +
        windPerturbation;
    return contactAngle.clamp(1.0, 26.0);
  }

  static double _computeUciRiskIncrementPerSec({
    required WheelFightRiderProfile defender,
    required WheelFightTacticAggression aggression,
    required double deflectionDeg,
    required double speedFactor,
    required double roadWidthMeters,
  }) {
    // Wyższe Race IQ pozwala bronić pozycji przepisowo bez niepotrzebnych ruchów łokciem.
    final iqControlFactor =
        (1.25 - (defender.raceIq.clamp(1, 100) / 100.0) * 0.55).clamp(0.65, 1.25);
    final narrowPenalty = roadWidthMeters < 5.0 ? 1.35 : 1.0;

    if (aggression == WheelFightTacticAggression.cleanDefensive &&
        deflectionDeg < 9.5) {
      return -2.5; // Spadek ryzyka przy czystej jeździe
    }

    final rawIncrement = ((deflectionDeg - 7.5) * 1.15) *
        aggression.uciRiskMultiplier *
        iqControlFactor *
        speedFactor *
        narrowPenalty;
    return rawIncrement.clamp(-3.0, 28.0);
  }

  static UciElbowRuleVerdict _resolveUciVerdict({
    required double uciRiskPct,
    required double deflectionDeg,
    required WheelFightTacticAggression aggression,
  }) {
    if (uciRiskPct >= 88.0 ||
        (aggression == WheelFightTacticAggression.recklessBarge &&
            deflectionDeg >= 18.5)) {
      return UciElbowRuleVerdict.relegationAndFine;
    }
    if (uciRiskPct >= 62.0 || deflectionDeg >= 15.0) {
      return UciElbowRuleVerdict.yellowCardWarning;
    }
    if (uciRiskPct >= 36.0 || deflectionDeg >= 11.2) {
      return UciElbowRuleVerdict.borderlineLean;
    }
    return UciElbowRuleVerdict.cleanContact;
  }

  static double _computeIsometricCoreWPrimeCost({
    required WheelFightTacticAggression aggression,
    required double challengerForceN,
    required double speedFactor,
    required double dt,
  }) {
    final baseWatts = (32.0 + challengerForceN * 0.14) *
        aggression.wPrimeCostMultiplier *
        speedFactor;
    return (baseWatts * dt).clamp(10.0, 260.0);
  }

  static double _computeAeroDraftSavedWatts({
    required double speedKmh,
    required double gapMeters,
    required double retentionPct,
  }) {
    final speedMs = speedKmh / 3.6;
    // Przy 62 km/h (17.22 m/s) opór aero ~ P = 0.5 * rho * CdA * v^3 ~ 720-780 W solo.
    final soloAeroWatts = 0.5 * 1.225 * 0.24 * math.pow(speedMs, 3);
    final gapEfficiency = (1.0 - (gapMeters.clamp(0.15, 2.0) - 0.15) * 0.24)
        .clamp(0.35, 1.0);
    final retentionFactor = (retentionPct.clamp(0.0, 100.0) / 100.0);
    // W pełni utrzymane koło rozprowadzającego oszczędza ~37% mocy aero (~270 W przy 62 km/h).
    return (soloAeroWatts * 0.37 * gapEfficiency * retentionFactor)
        .clamp(0.0, 380.0);
  }

  static WheelFightPhase _resolvePhase({
    required UciElbowRuleVerdict uciVerdict,
    required double nextRetentionPct,
    required double netMarginN,
  }) {
    if (uciVerdict == UciElbowRuleVerdict.relegationAndFine) {
      return WheelFightPhase.uciRelegationTriggered;
    }
    if (uciVerdict == UciElbowRuleVerdict.yellowCardWarning) {
      return WheelFightPhase.uciWarningIssued;
    }
    if (nextRetentionPct < 38.0) {
      return WheelFightPhase.wheelLostToRival;
    }
    if (netMarginN >= 22.0 && nextRetentionPct >= 78.0) {
      return WheelFightPhase.fendingOffIntruder;
    }
    if (netMarginN.abs() < 22.0 || nextRetentionPct < 88.0) {
      return WheelFightPhase.shoulderToShoulderDuel;
    }
    return WheelFightPhase.holdingLeadoutWheel;
  }

  static String _buildCommentaryPl({
    required WheelFightPhase phase,
    required UciElbowRuleVerdict uciVerdict,
    required WheelFightRiderProfile defender,
    required WheelFightRiderProfile challenger,
    required double speedKmh,
    required double netMarginN,
    required double aeroSavedW,
  }) {
    final speedStr = speedKmh.toStringAsFixed(1);
    switch (phase) {
      case WheelFightPhase.outsideFinal3Km:
        return 'Pociąg poza strefą 3 km — spokojna jazda w szyku.';
      case WheelFightPhase.holdingLeadoutWheel:
        return '${defender.riderName} pewnie pilnuje koła rozprowadzającego przy $speedStr km/h (zysk ${aeroSavedW.round()} W).';
      case WheelFightPhase.shoulderToShoulderDuel:
        return 'Twardy opór barkiem w bark przy $speedStr km/h! ${defender.riderName} vs ${challenger.riderName} (bilans ${netMarginN >= 0 ? '+' : ''}${netMarginN.round()} N).';
      case WheelFightPhase.fendingOffIntruder:
        return '${defender.riderName} (${defender.weightKg.toStringAsFixed(0)} kg, Core ${defender.coreStrength}) wypycha ${challenger.riderName} czystym oporem barku!';
      case WheelFightPhase.wheelLostToRival:
        return '${challenger.riderName} wcisnął się przednie koło — ${defender.riderName} traci tunel za rozprowadzającym!';
      case WheelFightPhase.uciWarningIssued:
        return 'Uwaga sędziów UCI (${uciVerdict.labelPl}): zbyt głębokie odchylenie toru przy $speedStr km/h!';
      case WheelFightPhase.uciRelegationTriggered:
        return 'DECYZJA SĘDZIÓW UCI: Relegacja ${defender.riderName} za niebezpieczne użycie łokcia w sprincie!';
    }
  }
}

/// Stan Riverpod modułu walki barkiem w bark o koło rozprowadzającego.
class SprinterWheelFightState {
  final WheelFightStepInput currentInput;
  final WheelFightStepResult lastResult;
  final List<WheelFightHistorySample> history;
  final int stepCount;
  final bool isAutoSimulating;

  const SprinterWheelFightState({
    required this.currentInput,
    required this.lastResult,
    required this.history,
    required this.stepCount,
    this.isAutoSimulating = false,
  });

  factory SprinterWheelFightState.initial() {
    const defaultDefender = WheelFightRiderProfile(
      riderId: 'sprinter_lead',
      riderName: 'K. De Bruyn',
      teamName: 'Alpecin Apex',
      weightKg: 78.5,
      coreStrength: 91,
      sprint: 92,
      raceIq: 88,
      bikeHandling: 86,
      remainingWPrimePct: 86.0,
    );
    const defaultChallenger = WheelFightRiderProfile(
      riderId: 'rival_intruder',
      riderName: 'M. Venturi',
      teamName: 'Bora Velocity',
      weightKg: 73.0,
      coreStrength: 82,
      sprint: 89,
      raceIq: 81,
      bikeHandling: 83,
      remainingWPrimePct: 84.0,
    );
    const initialInput = WheelFightStepInput(
      defender: defaultDefender,
      challenger: defaultChallenger,
      distanceToFinishKm: 2.2,
      pelotonSpeedKmh: 62.0,
      leadoutWheelGapMeters: 0.35,
      roadWidthMeters: 6.5,
      crosswindSpeedKmh: 12.0,
      defenderAggression: WheelFightTacticAggression.balancedShoulderHold,
      challengerAggression: WheelFightTacticAggression.balancedShoulderHold,
      deltaSeconds: 1.0,
    );
    final initialResult =
        SprinterElbowRubbingAndWheelFighting.evaluateWheelFightStep(
      input: initialInput,
      previousRetentionPct: 86.0,
      previousUciRiskPct: 10.0,
    );
    return SprinterWheelFightState(
      currentInput: initialInput,
      lastResult: initialResult,
      history: [
        WheelFightHistorySample(
          stepIndex: 0,
          distanceToFinishKm: initialInput.distanceToFinishKm,
          speedKmh: initialInput.pelotonSpeedKmh,
          wheelRetentionPct: initialResult.wheelPositionRetentionPct,
          uciRiskPct: initialResult.uciInfractionRiskPct,
          phase: initialResult.phase,
        ),
      ],
      stepCount: 0,
      isAutoSimulating: false,
    );
  }

  SprinterWheelFightState copyWith({
    WheelFightStepInput? currentInput,
    WheelFightStepResult? lastResult,
    List<WheelFightHistorySample>? history,
    int? stepCount,
    bool? isAutoSimulating,
  }) {
    return SprinterWheelFightState(
      currentInput: currentInput ?? this.currentInput,
      lastResult: lastResult ?? this.lastResult,
      history: history ?? this.history,
      stepCount: stepCount ?? this.stepCount,
      isAutoSimulating: isAutoSimulating ?? this.isAutoSimulating,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentInput': currentInput.toJson(),
      'lastResult': lastResult.toJson(),
      'history': history.map((e) => e.toJson()).toList(),
      'stepCount': stepCount,
      'isAutoSimulating': isAutoSimulating,
    };
  }

  factory SprinterWheelFightState.fromJson(Map<String, dynamic> json) {
    final rawHistory = json['history'] as List? ?? const [];
    return SprinterWheelFightState(
      currentInput: WheelFightStepInput.fromJson(
        Map<String, dynamic>.from(json['currentInput'] as Map? ?? const {}),
      ),
      lastResult: WheelFightStepResult.fromJson(
        Map<String, dynamic>.from(json['lastResult'] as Map? ?? const {}),
      ),
      history: rawHistory
          .whereType<Map>()
          .map(
            (e) =>
                WheelFightHistorySample.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList(),
      stepCount: (json['stepCount'] as num?)?.toInt() ?? 0,
      isAutoSimulating: json['isAutoSimulating'] as bool? ?? false,
    );
  }
}

/// Kontroler Riverpod zarządzający symulacją walki o koło na ostatnich 3 km.
class SprinterWheelFightNotifier
    extends StateNotifier<SprinterWheelFightState> {
  SprinterWheelFightNotifier() : super(SprinterWheelFightState.initial());

  void setDefenderAggression(WheelFightTacticAggression aggression) {
    final updatedInput =
        state.currentInput.copyWith(defenderAggression: aggression);
    final res = SprinterElbowRubbingAndWheelFighting.evaluateWheelFightStep(
      input: updatedInput,
      previousRetentionPct: state.lastResult.wheelPositionRetentionPct,
      previousUciRiskPct: state.lastResult.uciInfractionRiskPct,
    );
    state = state.copyWith(currentInput: updatedInput, lastResult: res);
  }

  void setPelotonSpeed(double speedKmh) {
    final updatedInput = state.currentInput.copyWith(
      pelotonSpeedKmh: speedKmh.clamp(45.0, 76.0),
    );
    final res = SprinterElbowRubbingAndWheelFighting.evaluateWheelFightStep(
      input: updatedInput,
      previousRetentionPct: state.lastResult.wheelPositionRetentionPct,
      previousUciRiskPct: state.lastResult.uciInfractionRiskPct,
    );
    state = state.copyWith(currentInput: updatedInput, lastResult: res);
  }

  void applyScenarioPreset({
    required WheelFightRiderProfile defender,
    required WheelFightRiderProfile challenger,
    required WheelFightTacticAggression defenderAggression,
    required WheelFightTacticAggression challengerAggression,
    double speedKmh = 62.0,
    double distanceToFinishKm = 1.8,
  }) {
    final input = state.currentInput.copyWith(
      defender: defender,
      challenger: challenger,
      defenderAggression: defenderAggression,
      challengerAggression: challengerAggression,
      pelotonSpeedKmh: speedKmh,
      distanceToFinishKm: distanceToFinishKm,
    );
    final res = SprinterElbowRubbingAndWheelFighting.evaluateWheelFightStep(
      input: input,
      previousRetentionPct: 82.0,
      previousUciRiskPct: 12.0,
    );
    state = SprinterWheelFightState(
      currentInput: input,
      lastResult: res,
      history: [
        WheelFightHistorySample(
          stepIndex: 0,
          distanceToFinishKm: input.distanceToFinishKm,
          speedKmh: input.pelotonSpeedKmh,
          wheelRetentionPct: res.wheelPositionRetentionPct,
          uciRiskPct: res.uciInfractionRiskPct,
          phase: res.phase,
        ),
      ],
      stepCount: 0,
    );
  }

  void stepSimulation() {
    if (state.currentInput.distanceToFinishKm <= 0.0 ||
        state.lastResult.phase == WheelFightPhase.uciRelegationTriggered) {
      return;
    }

    // Przy 62 km/h (17.22 m/s) w 1 s kolarz pokonuje ~0.0172 km.
    final kmDelta =
        (state.currentInput.pelotonSpeedKmh / 3600.0) * state.currentInput.deltaSeconds * 6.0;
    final nextDist =
        (state.currentInput.distanceToFinishKm - kmDelta).clamp(0.0, 10.0);

    final wPrimeLossPct =
        (state.lastResult.isometricCoreWPrimeCostJoules / 240.0).clamp(0.0, 5.0);
    final nextDefender = state.currentInput.defender.copyWith(
      remainingWPrimePct:
          (state.currentInput.defender.remainingWPrimePct - wPrimeLossPct)
              .clamp(0.0, 100.0),
    );

    final nextInput = state.currentInput.copyWith(
      defender: nextDefender,
      distanceToFinishKm: nextDist,
    );

    final res = SprinterElbowRubbingAndWheelFighting.evaluateWheelFightStep(
      input: nextInput,
      previousRetentionPct: state.lastResult.wheelPositionRetentionPct,
      previousUciRiskPct: state.lastResult.uciInfractionRiskPct,
    );

    final nextStep = state.stepCount + 1;
    final nextHistory = [
      ...state.history,
      WheelFightHistorySample(
        stepIndex: nextStep,
        distanceToFinishKm: nextDist,
        speedKmh: nextInput.pelotonSpeedKmh,
        wheelRetentionPct: res.wheelPositionRetentionPct,
        uciRiskPct: res.uciInfractionRiskPct,
        phase: res.phase,
      ),
    ];

    state = state.copyWith(
      currentInput: nextInput,
      lastResult: res,
      history: nextHistory.length > 30
          ? nextHistory.sublist(nextHistory.length - 30)
          : nextHistory,
      stepCount: nextStep,
    );
  }

  void reset() {
    state = SprinterWheelFightState.initial();
  }
}

final sprinterWheelFightProvider = StateNotifierProvider<
    SprinterWheelFightNotifier, SprinterWheelFightState>(
  (ref) => SprinterWheelFightNotifier(),
);

/// Wizualizacja toru jazdy w pociągu sprinterskim (rozprowadzający, obrońca i wcinający się rywal).
class WheelFightLateralForcePainter extends CustomPainter {
  final WheelFightStepInput input;
  final WheelFightStepResult result;

  const WheelFightLateralForcePainter({
    required this.input,
    required this.result,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = AppColors.background;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)),
      bgPaint,
    );

    // Pasy drogi i krawężnik.
    final lanePaint = Paint()
      ..color = AppColors.cardBorder.withValues(alpha: 0.7)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(0, size.height * 0.16),
      Offset(size.width, size.height * 0.16),
      lanePaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.84),
      Offset(size.width, size.height * 0.84),
      lanePaint,
    );

    // Linia środkowa asfaltu przerywana.
    final centerDashPaint = Paint()
      ..color = AppColors.textSecondary.withValues(alpha: 0.25)
      ..strokeWidth = 1.5;
    for (double x = 12; x < size.width - 12; x += 22) {
      canvas.drawLine(
        Offset(x, size.height * 0.5),
        Offset(x + 11, size.height * 0.5),
        centerDashPaint,
      );
    }

    // Pozycja rozprowadzającego (Leadout) z przodu po prawej.
    final leadoutCenter = Offset(size.width * 0.74, size.height * 0.48);
    _drawRiderCapsule(
      canvas: canvas,
      center: leadoutCenter,
      color: AppColors.accentBlue,
      label: 'ROZPR.',
    );

    // Obrońca na kole rozprowadzającego.
    final retentionNorm = (result.wheelPositionRetentionPct / 100.0).clamp(0.0, 1.0);
    final defenderX = size.width * (0.34 + retentionNorm * 0.18);
    final defenderY = size.height * 0.48;
    final defenderCenter = Offset(defenderX, defenderY);

    // Tunel aero między rozprowadzającym a obrońcą.
    final draftPaint = Paint()
      ..color = AppColors.statusSuccess.withValues(alpha: 0.18 * retentionNorm)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTRB(
        defenderCenter.dx + 16,
        leadoutCenter.dy - 14,
        leadoutCenter.dx - 16,
        leadoutCenter.dy + 14,
      ),
      draftPaint,
    );

    // Wcinający się rywal z boku (bark w bark).
    final challengerProximity = (1.0 - retentionNorm * 0.65).clamp(0.25, 1.0);
    final challengerCenter = Offset(
      defenderX + (challengerProximity - 0.5) * 28,
      defenderY + 34,
    );

    // Wektor nacisku barkiem w bark.
    final contactColor = result.uciVerdict == UciElbowRuleVerdict.relegationAndFine
        ? AppColors.crimsonAlert
        : result.uciVerdict == UciElbowRuleVerdict.yellowCardWarning
            ? AppColors.amberWarning
            : AppColors.goldAccent;
    final forceArrowPaint = Paint()
      ..color = contactColor
      ..strokeWidth = 2.5;
    canvas.drawLine(defenderCenter, challengerCenter, forceArrowPaint);

    _drawRiderCapsule(
      canvas: canvas,
      center: defenderCenter,
      color: AppColors.goldAccent,
      label: 'OBROŃCA',
    );
    _drawRiderCapsule(
      canvas: canvas,
      center: challengerCenter,
      color: AppColors.crimsonAlert,
      label: 'RYWAL',
    );
  }

  void _drawRiderCapsule({
    required Canvas canvas,
    required Offset center,
    required Color color,
    required String label,
  }) {
    final fill = Paint()..color = color.withValues(alpha: 0.22);
    final border = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: 54, height: 24),
      const Radius.circular(12),
    );
    canvas.drawRRect(rect, fill);
    canvas.drawRRect(rect, border);

    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant WheelFightLateralForcePainter oldDelegate) {
    return oldDelegate.input != input || oldDelegate.result != result;
  }
}

/// Produkcyjny panel taktyczno-fizyczny walki o koło w pociągu sprinterskim (#675).
///
/// Obsługuje pełne stany `hover`, `active`, `disabled` i `focus`, animacje `220ms`
/// (`Curves.easeOutCubic`), paletę `AppColors`, czcionkę `Inter` (`tabularFigures`)
/// oraz responsywny układ `LayoutBuilder` dla `390x844`, `1024x768` i `1600x900`.
class SprinterElbowRubbingAndWheelFightingPanel extends ConsumerWidget {
  final bool isReadOnly;

  const SprinterElbowRubbingAndWheelFightingPanel({
    super.key,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sprinterWheelFightProvider);
    final notifier = ref.read(sprinterWheelFightProvider.notifier);
    final input = state.currentInput;
    final res = state.lastResult;

    final isDuelEnded = input.distanceToFinishKm <= 0.0 ||
        res.phase == WheelFightPhase.uciRelegationTriggered;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 680;
          final isWide = constraints.maxWidth >= 1100;

          final header = _buildHeader(input: input, res: res);
          final diagramCard = _buildDiagramAndTelemetryCard(
            input: input,
            res: res,
            isCompact: isCompact,
          );
          final controlsCard = _buildControlsCard(
            input: input,
            res: res,
            notifier: notifier,
            isReadOnly: isReadOnly,
            isDuelEnded: isDuelEnded,
          );

          if (isWide) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 6, child: diagramCard),
                      const SizedBox(width: 16),
                      Expanded(flex: 5, child: controlsCard),
                    ],
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                const SizedBox(height: 14),
                diagramCard,
                const SizedBox(height: 14),
                controlsCard,
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader({
    required WheelFightStepInput input,
    required WheelFightStepResult res,
  }) {
    final phaseColor = _phaseAccentColor(res.phase);
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Walka o Koło w Pociągu Sprinterskim (Ostatnie 3 km)',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Opór barkiem w bark przy ${input.pelotonSpeedKmh.toStringAsFixed(1)} km/h • Pozostało ${input.distanceToFinishKm.toStringAsFixed(2)} km',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: phaseColor.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: phaseColor, width: 1),
          ),
          child: Text(
            res.phase.labelPl,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: phaseColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDiagramAndTelemetryCard({
    required WheelFightStepInput input,
    required WheelFightStepResult res,
    required bool isCompact,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: isCompact ? 132 : 156,
            child: CustomPaint(
              painter: WheelFightLateralForcePainter(input: input, result: res),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetricTile(
                label: 'Opór Obrońcy',
                value: '${res.defenderTotalForceNewtons.round()} N',
                accent: AppColors.goldAccent,
              ),
              _MetricTile(
                label: 'Nacisk Rywala',
                value: '${res.challengerIntrusionForceNewtons.round()} N',
                accent: AppColors.crimsonAlert,
              ),
              _MetricTile(
                label: 'Utrzymanie Koła',
                value: '${res.wheelPositionRetentionPct.toStringAsFixed(0)}%',
                accent: AppColors.statusSuccess,
              ),
              _MetricTile(
                label: 'Zysk Aero',
                value: '+${res.aeroDraftSavedWatts.round()} W',
                accent: AppColors.accentBlue,
              ),
              _MetricTile(
                label: 'Ryzyko UCI',
                value: '${res.uciInfractionRiskPct.toStringAsFixed(0)}%',
                accent: res.uciInfractionRiskPct >= 62.0
                    ? AppColors.amberWarning
                    : AppColors.textSecondary,
              ),
              _MetricTile(
                label: 'Kąt Odchylenia',
                value: '${res.headElbowDeflectionDegrees.toStringAsFixed(1)}°',
                accent: AppColors.cyanAccent,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder, width: 1),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.gavel_rounded,
                  size: 16,
                  color: _verdictColor(res.uciVerdict),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${res.uciVerdict.labelPl} — ${res.tacticalCommentaryPl}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsCard({
    required WheelFightStepInput input,
    required WheelFightStepResult res,
    required SprinterWheelFightNotifier notifier,
    required bool isReadOnly,
    required bool isDuelEnded,
  }) {
    final controlsDisabled = isReadOnly || isDuelEnded;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Taktyka Obrony Koła (Agresywność)',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: WheelFightTacticAggression.values.map((mode) {
              return _InteractiveTacticChip(
                label: mode.labelPl,
                isSelected: input.defenderAggression == mode,
                isDisabled: controlsDisabled,
                accentColor: mode == WheelFightTacticAggression.recklessBarge
                    ? AppColors.crimsonAlert
                    : AppColors.goldAccent,
                onPressed: () => notifier.setDefenderAggression(mode),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Prędkość Pociągu',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '${input.pelotonSpeedKmh.toStringAsFixed(1)} km/h',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          Slider(
            value: input.pelotonSpeedKmh.clamp(45.0, 76.0),
            min: 45.0,
            max: 76.0,
            divisions: 31,
            activeColor: AppColors.primaryAccent,
            inactiveColor: AppColors.cardBorder,
            onChanged: controlsDisabled
                ? null
                : (val) => notifier.setPelotonSpeed(val),
          ),
          const SizedBox(height: 8),
          const Text(
            'Profile Pojedynku',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InteractiveActionButton(
                label: 'Elitarny Sprinter (79 kg)',
                isDisabled: isReadOnly,
                onPressed: () => notifier.applyScenarioPreset(
                  defender: input.defender.copyWith(
                    weightKg: 79.0,
                    coreStrength: 92,
                    raceIq: 90,
                    sprint: 93,
                    remainingWPrimePct: 90.0,
                  ),
                  challenger: input.challenger.copyWith(
                    weightKg: 70.0,
                    coreStrength: 78,
                    raceIq: 78,
                    sprint: 85,
                  ),
                  defenderAggression:
                      WheelFightTacticAggression.balancedShoulderHold,
                  challengerAggression:
                      WheelFightTacticAggression.balancedShoulderHold,
                ),
              ),
              _InteractiveActionButton(
                label: 'Lekki Rywal vs Ciężki Atak',
                isDisabled: isReadOnly,
                onPressed: () => notifier.applyScenarioPreset(
                  defender: input.defender.copyWith(
                    weightKg: 66.0,
                    coreStrength: 70,
                    raceIq: 74,
                    sprint: 82,
                    remainingWPrimePct: 75.0,
                  ),
                  challenger: input.challenger.copyWith(
                    weightKg: 82.0,
                    coreStrength: 90,
                    raceIq: 86,
                    sprint: 91,
                  ),
                  defenderAggression:
                      WheelFightTacticAggression.cleanDefensive,
                  challengerAggression:
                      WheelFightTacticAggression.razorEdgeAggressive,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _InteractiveActionButton(
                label: isDuelEnded ? 'Pojedynek Zakończony' : 'Symuluj Krok (1 s)',
                isPrimary: true,
                isDisabled: controlsDisabled,
                onPressed: notifier.stepSimulation,
              ),
              _InteractiveActionButton(
                label: 'Resetuj',
                isDisabled: isReadOnly,
                onPressed: notifier.reset,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _phaseAccentColor(WheelFightPhase phase) {
    switch (phase) {
      case WheelFightPhase.outsideFinal3Km:
        return AppColors.textSecondary;
      case WheelFightPhase.holdingLeadoutWheel:
      case WheelFightPhase.fendingOffIntruder:
        return AppColors.statusSuccess;
      case WheelFightPhase.shoulderToShoulderDuel:
        return AppColors.goldAccent;
      case WheelFightPhase.wheelLostToRival:
      case WheelFightPhase.uciWarningIssued:
        return AppColors.amberWarning;
      case WheelFightPhase.uciRelegationTriggered:
        return AppColors.crimsonAlert;
    }
  }

  Color _verdictColor(UciElbowRuleVerdict verdict) {
    switch (verdict) {
      case UciElbowRuleVerdict.cleanContact:
        return AppColors.statusSuccess;
      case UciElbowRuleVerdict.borderlineLean:
        return AppColors.goldAccent;
      case UciElbowRuleVerdict.yellowCardWarning:
        return AppColors.amberWarning;
      case UciElbowRuleVerdict.relegationAndFine:
        return AppColors.crimsonAlert;
    }
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
      constraints: const BoxConstraints(minWidth: 108),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: accent,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractiveTacticChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final bool isDisabled;
  final Color accentColor;
  final VoidCallback onPressed;

  const _InteractiveTacticChip({
    required this.label,
    required this.isSelected,
    required this.isDisabled,
    required this.accentColor,
    required this.onPressed,
  });

  @override
  State<_InteractiveTacticChip> createState() => _InteractiveTacticChipState();
}

class _InteractiveTacticChipState extends State<_InteractiveTacticChip> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isDisabled
        ? AppColors.cardBorder.withValues(alpha: 0.45)
        : _isFocused
            ? AppColors.cyanAccent
            : widget.isSelected
                ? widget.accentColor
                : _isHovered
                    ? AppColors.textSecondary
                    : AppColors.cardBorder;

    final bgColor = widget.isDisabled
        ? AppColors.background.withValues(alpha: 0.5)
        : widget.isSelected
            ? widget.accentColor.withValues(alpha: _isPressed ? 0.28 : 0.18)
            : _isHovered
                ? AppColors.surfaceLight
                : AppColors.background;

    return FocusableActionDetector(
      enabled: !widget.isDisabled,
      onShowFocusHighlight: (focused) => setState(() => _isFocused = focused),
      onShowHoverHighlight: (hovered) => setState(() => _isHovered = hovered),
      child: GestureDetector(
        onTapDown: widget.isDisabled
            ? null
            : (_) => setState(() => _isPressed = true),
        onTapUp: widget.isDisabled
            ? null
            : (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.isDisabled ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: _isFocused || widget.isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight:
                  widget.isSelected ? FontWeight.w700 : FontWeight.w500,
              color: widget.isDisabled
                  ? AppColors.textSecondary.withValues(alpha: 0.45)
                  : widget.isSelected
                      ? widget.accentColor
                      : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractiveActionButton extends StatefulWidget {
  final String label;
  final bool isPrimary;
  final bool isDisabled;
  final VoidCallback onPressed;

  const _InteractiveActionButton({
    required this.label,
    this.isPrimary = false,
    required this.isDisabled,
    required this.onPressed,
  });

  @override
  State<_InteractiveActionButton> createState() =>
      _InteractiveActionButtonState();
}

class _InteractiveActionButtonState extends State<_InteractiveActionButton> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final baseColor =
        widget.isPrimary ? AppColors.primaryAccent : AppColors.background;
    final bgColor = widget.isDisabled
        ? AppColors.background.withValues(alpha: 0.4)
        : _isPressed
            ? baseColor.withValues(alpha: 0.85)
            : _isHovered
                ? (widget.isPrimary
                    ? AppColors.primaryAccent.withValues(alpha: 0.9)
                    : AppColors.surface)
                : baseColor;

    final borderColor = widget.isDisabled
        ? AppColors.cardBorder.withValues(alpha: 0.4)
        : _isFocused
            ? AppColors.cyanAccent
            : widget.isPrimary
                ? AppColors.goldAccent.withValues(alpha: 0.65)
                : AppColors.cardBorder;

    return FocusableActionDetector(
      enabled: !widget.isDisabled,
      onShowFocusHighlight: (focused) => setState(() => _isFocused = focused),
      onShowHoverHighlight: (hovered) => setState(() => _isHovered = hovered),
      child: GestureDetector(
        onTapDown: widget.isDisabled
            ? null
            : (_) => setState(() => _isPressed = true),
        onTapUp: widget.isDisabled
            ? null
            : (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.isDisabled ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: _isFocused ? 1.5 : 1.0,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: widget.isDisabled
                  ? AppColors.textSecondary.withValues(alpha: 0.45)
                  : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
