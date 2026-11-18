import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';

/// Tryb taktyczny mowy ciała i blefowania kolarza na podjeździe.
enum PokerFaceTacticMode {
  /// Naturalna jazda bez maskowania fizjologii.
  authentic,

  /// Blef: Ukrycie kryzysu (kamienna twarz, nieruchomy tułów mimo wysokiego mleczanu).
  pokerFaceHideCrisis,

  /// Blef: Udawanie kryzysu (zjazd na ogon grupki, prowokacja przedwczesnego ataku rywali).
  sandbaggingPlayDead,

  /// Blef: Pokaz siły (zapięta koszulka, taniec w korbach mimo średniego zapasu W').
  bluffShowOfStrength;

  String toJson() => name;

  static PokerFaceTacticMode fromJson(String value) {
    return PokerFaceTacticMode.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => PokerFaceTacticMode.authentic,
    );
  }

  String get label {
    switch (this) {
      case PokerFaceTacticMode.authentic:
        return 'Naturalna jazda';
      case PokerFaceTacticMode.pokerFaceHideCrisis:
        return 'Poker Face (Ukryj kryzys)';
      case PokerFaceTacticMode.sandbaggingPlayDead:
        return 'Sandbagging (Udawaj słabość)';
      case PokerFaceTacticMode.bluffShowOfStrength:
        return 'Pokaz siły (Zastraszenie)';
    }
  }

  String get shortTag {
    switch (this) {
      case PokerFaceTacticMode.authentic:
        return 'NATURAL';
      case PokerFaceTacticMode.pokerFaceHideCrisis:
        return 'MASKA';
      case PokerFaceTacticMode.sandbaggingPlayDead:
        return 'PUŁAPKA';
      case PokerFaceTacticMode.bluffShowOfStrength:
        return 'BLEF SIŁY';
    }
  }

  String get description {
    switch (this) {
      case PokerFaceTacticMode.authentic:
        return 'Brak dodatkowego kosztu tlenowego. Rywale odczytują Twoje realne zmęczenie.';
      case PokerFaceTacticMode.pokerFaceHideCrisis:
        return 'Maskuje deficyt W\' i mleczan (+2.5% kosztu W), opóźniając atak faworytów.';
      case PokerFaceTacticMode.sandbaggingPlayDead:
        return 'Spadek na koniec grupki wciąga rywali w pułapkę i ładuje bonus kontrataku.';
      case PokerFaceTacticMode.bluffShowOfStrength:
        return 'Agresywna sylwetka zniechęca rywali do przyspieszenia kosztem szybszej utraty W\'.';
    }
  }
}

/// Obserwowalny sygnał mowy ciała kolarza na podjeździe.
enum BodyLanguageCue {
  /// Równy rytm w siodle, spokojny oddech i nieruchome barki.
  steadySeatedSpin,

  /// Kamienna twarz ("Poker Face") — kontrolowany grymas mimo dużego wysiłku.
  pokerFaceMask,

  /// Wyraźne kołysanie ramionami i szarpanie kierownicy.
  shoulderRocking,

  /// Opadająca głowa, oddychanie szeroko otwartymi ustami — widoczny kryzys.
  headBobbingOpenMouth,

  /// Spadek na ostatnie koło grupy liderów.
  dropToBackOfGroup,

  /// Zapięta koszulka, wysoka kadencja i lekki taniec na stojąco.
  zippedUpAndOutOfSaddle;

  String toJson() => name;

  static BodyLanguageCue fromJson(String value) {
    return BodyLanguageCue.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => BodyLanguageCue.steadySeatedSpin,
    );
  }

  String get label {
    switch (this) {
      case BodyLanguageCue.steadySeatedSpin:
        return 'Równy rytm w siodle';
      case BodyLanguageCue.pokerFaceMask:
        return 'Kamienna twarz (Poker Face)';
      case BodyLanguageCue.shoulderRocking:
        return 'Kołysanie ramionami';
      case BodyLanguageCue.headBobbingOpenMouth:
        return 'Opadająca głowa / ciężki oddech';
      case BodyLanguageCue.dropToBackOfGroup:
        return 'Spadek na ogon grupy';
      case BodyLanguageCue.zippedUpAndOutOfSaddle:
        return 'Zapięta koszulka — pokaz siły';
    }
  }
}

/// Wynik oceny blefu przez rywali w grupie faworytów.
enum BluffDetectionOutcome {
  /// Rywale dali się całkowicie zwieść mowie ciała.
  fooledCompletely,

  /// Rywale nabrali podejrzeń, ale wciąż się wahają.
  partiallySuspicious,

  /// Blef został przejrzany — rywale znają rzeczywistą dyspozycję.
  bluffSeenThrough,

  /// Rywal połknął haczyk Sandbaggingu i zaatakował przedwcześnie.
  counterAttackBaited;

  String toJson() => name;

  static BluffDetectionOutcome fromJson(String value) {
    return BluffDetectionOutcome.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => BluffDetectionOutcome.fooledCompletely,
    );
  }

  String get label {
    switch (this) {
      case BluffDetectionOutcome.fooledCompletely:
        return 'Rywale zwiedzeni';
      case BluffDetectionOutcome.partiallySuspicious:
        return 'Rosnąca podejrzliwość';
      case BluffDetectionOutcome.bluffSeenThrough:
        return 'Blef przejrzany!';
      case BluffDetectionOutcome.counterAttackBaited:
        return 'Przynęta połknięta — okno kontry!';
    }
  }
}

/// Strefa wysokościowo-taktyczna podjazdu wpływająca na presję psychologiczną.
enum ClimbContextZone {
  baseOfClimb,
  steepPitch,
  highAltitudeFinal,
  summitApproach;

  String toJson() => name;

  static ClimbContextZone fromJson(String value) {
    return ClimbContextZone.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ClimbContextZone.steepPitch,
    );
  }

  String get label {
    switch (this) {
      case ClimbContextZone.baseOfClimb:
        return 'Podnóże podjazdu';
      case ClimbContextZone.steepPitch:
        return 'Stroma ścianka (>9%)';
      case ClimbContextZone.highAltitudeFinal:
        return 'Wysokie góry (>1800 m)';
      case ClimbContextZone.summitApproach:
        return 'Finałowy kilometr pod szczyt';
    }
  }
}

/// Profil umiejętności psychologicznych i maskowania kolarza.
class PokerFaceRiderProfile {
  final String riderId;
  final String riderName;
  final double pokerFaceSkill;
  final double mentalToughness;
  final double ftpWatts;
  final double wPrimeMaxJ;
  final bool hasDarkMirroredSunglasses;
  final double helmetMaskBonus;

  const PokerFaceRiderProfile({
    required this.riderId,
    required this.riderName,
    required this.pokerFaceSkill,
    required this.mentalToughness,
    required this.ftpWatts,
    required this.wPrimeMaxJ,
    this.hasDarkMirroredSunglasses = true,
    this.helmetMaskBonus = 0.04,
  });

  double get visualMaskBonus {
    final double glassesBonus = hasDarkMirroredSunglasses ? 0.12 : 0.0;
    return (glassesBonus + helmetMaskBonus).clamp(0.0, 0.25);
  }

  PokerFaceRiderProfile copyWith({
    String? riderId,
    String? riderName,
    double? pokerFaceSkill,
    double? mentalToughness,
    double? ftpWatts,
    double? wPrimeMaxJ,
    bool? hasDarkMirroredSunglasses,
    double? helmetMaskBonus,
  }) {
    return PokerFaceRiderProfile(
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      pokerFaceSkill: pokerFaceSkill ?? this.pokerFaceSkill,
      mentalToughness: mentalToughness ?? this.mentalToughness,
      ftpWatts: ftpWatts ?? this.ftpWatts,
      wPrimeMaxJ: wPrimeMaxJ ?? this.wPrimeMaxJ,
      hasDarkMirroredSunglasses:
          hasDarkMirroredSunglasses ?? this.hasDarkMirroredSunglasses,
      helmetMaskBonus: helmetMaskBonus ?? this.helmetMaskBonus,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'riderName': riderName,
      'pokerFaceSkill': pokerFaceSkill,
      'mentalToughness': mentalToughness,
      'ftpWatts': ftpWatts,
      'wPrimeMaxJ': wPrimeMaxJ,
      'hasDarkMirroredSunglasses': hasDarkMirroredSunglasses,
      'helmetMaskBonus': helmetMaskBonus,
    };
  }

  factory PokerFaceRiderProfile.fromJson(Map<String, dynamic> json) {
    return PokerFaceRiderProfile(
      riderId: json['riderId'] as String? ?? 'rider-1',
      riderName: json['riderName'] as String? ?? 'Lider Zespołu',
      pokerFaceSkill: (json['pokerFaceSkill'] as num?)?.toDouble() ?? 78.0,
      mentalToughness: (json['mentalToughness'] as num?)?.toDouble() ?? 82.0,
      ftpWatts: (json['ftpWatts'] as num?)?.toDouble() ?? 420.0,
      wPrimeMaxJ: (json['wPrimeMaxJ'] as num?)?.toDouble() ?? 24000.0,
      hasDarkMirroredSunglasses:
          json['hasDarkMirroredSunglasses'] as bool? ?? true,
      helmetMaskBonus: (json['helmetMaskBonus'] as num?)?.toDouble() ?? 0.04,
    );
  }
}

/// Obserwator AI z grupy faworytów interpretujący mowę ciała gracza.
class RivalBodyLanguageObserver {
  final String rivalId;
  final String rivalName;
  final String teamName;
  final double observationSkill;
  final double aggression;
  final double suspicionLevel;
  final double perceivedCrisisScore;
  final bool isBaitedIntoAttack;
  final BluffDetectionOutcome lastOutcome;

  const RivalBodyLanguageObserver({
    required this.rivalId,
    required this.rivalName,
    required this.teamName,
    required this.observationSkill,
    required this.aggression,
    this.suspicionLevel = 0.15,
    this.perceivedCrisisScore = 25.0,
    this.isBaitedIntoAttack = false,
    this.lastOutcome = BluffDetectionOutcome.fooledCompletely,
  });

  RivalBodyLanguageObserver copyWith({
    String? rivalId,
    String? rivalName,
    String? teamName,
    double? observationSkill,
    double? aggression,
    double? suspicionLevel,
    double? perceivedCrisisScore,
    bool? isBaitedIntoAttack,
    BluffDetectionOutcome? lastOutcome,
  }) {
    return RivalBodyLanguageObserver(
      rivalId: rivalId ?? this.rivalId,
      rivalName: rivalName ?? this.rivalName,
      teamName: teamName ?? this.teamName,
      observationSkill: observationSkill ?? this.observationSkill,
      aggression: aggression ?? this.aggression,
      suspicionLevel: suspicionLevel ?? this.suspicionLevel,
      perceivedCrisisScore: perceivedCrisisScore ?? this.perceivedCrisisScore,
      isBaitedIntoAttack: isBaitedIntoAttack ?? this.isBaitedIntoAttack,
      lastOutcome: lastOutcome ?? this.lastOutcome,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rivalId': rivalId,
      'rivalName': rivalName,
      'teamName': teamName,
      'observationSkill': observationSkill,
      'aggression': aggression,
      'suspicionLevel': suspicionLevel,
      'perceivedCrisisScore': perceivedCrisisScore,
      'isBaitedIntoAttack': isBaitedIntoAttack,
      'lastOutcome': lastOutcome.toJson(),
    };
  }

  factory RivalBodyLanguageObserver.fromJson(Map<String, dynamic> json) {
    return RivalBodyLanguageObserver(
      rivalId: json['rivalId'] as String? ?? 'rival-1',
      rivalName: json['rivalName'] as String? ?? 'Rywal GC',
      teamName: json['teamName'] as String? ?? 'Team Rival',
      observationSkill: (json['observationSkill'] as num?)?.toDouble() ?? 75.0,
      aggression: (json['aggression'] as num?)?.toDouble() ?? 70.0,
      suspicionLevel: (json['suspicionLevel'] as num?)?.toDouble() ?? 0.15,
      perceivedCrisisScore:
          (json['perceivedCrisisScore'] as num?)?.toDouble() ?? 25.0,
      isBaitedIntoAttack: json['isBaitedIntoAttack'] as bool? ?? false,
      lastOutcome: BluffDetectionOutcome.fromJson(
        json['lastOutcome'] as String? ?? 'fooledCompletely',
      ),
    );
  }
}

/// Wejściowe dane telemetryczne kroku symulacji na podjeździe.
class BluffingStepInput {
  final double wPrimeRemainingPct;
  final double powerOutputWatts;
  final double heartRateBpm;
  final double maxHeartRateBpm;
  final double lactateMmol;
  final double cadenceRpm;
  final double climbGradientPct;
  final double altitudeMeters;
  final double distanceToSummitKm;
  final ClimbContextZone climbZone;
  final double deltaSeconds;

  const BluffingStepInput({
    required this.wPrimeRemainingPct,
    required this.powerOutputWatts,
    required this.heartRateBpm,
    required this.maxHeartRateBpm,
    required this.lactateMmol,
    required this.cadenceRpm,
    required this.climbGradientPct,
    required this.altitudeMeters,
    required this.distanceToSummitKm,
    this.climbZone = ClimbContextZone.steepPitch,
    this.deltaSeconds = 10.0,
  });

  BluffingStepInput copyWith({
    double? wPrimeRemainingPct,
    double? powerOutputWatts,
    double? heartRateBpm,
    double? maxHeartRateBpm,
    double? lactateMmol,
    double? cadenceRpm,
    double? climbGradientPct,
    double? altitudeMeters,
    double? distanceToSummitKm,
    ClimbContextZone? climbZone,
    double? deltaSeconds,
  }) {
    return BluffingStepInput(
      wPrimeRemainingPct: wPrimeRemainingPct ?? this.wPrimeRemainingPct,
      powerOutputWatts: powerOutputWatts ?? this.powerOutputWatts,
      heartRateBpm: heartRateBpm ?? this.heartRateBpm,
      maxHeartRateBpm: maxHeartRateBpm ?? this.maxHeartRateBpm,
      lactateMmol: lactateMmol ?? this.lactateMmol,
      cadenceRpm: cadenceRpm ?? this.cadenceRpm,
      climbGradientPct: climbGradientPct ?? this.climbGradientPct,
      altitudeMeters: altitudeMeters ?? this.altitudeMeters,
      distanceToSummitKm: distanceToSummitKm ?? this.distanceToSummitKm,
      climbZone: climbZone ?? this.climbZone,
      deltaSeconds: deltaSeconds ?? this.deltaSeconds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'wPrimeRemainingPct': wPrimeRemainingPct,
      'powerOutputWatts': powerOutputWatts,
      'heartRateBpm': heartRateBpm,
      'maxHeartRateBpm': maxHeartRateBpm,
      'lactateMmol': lactateMmol,
      'cadenceRpm': cadenceRpm,
      'climbGradientPct': climbGradientPct,
      'altitudeMeters': altitudeMeters,
      'distanceToSummitKm': distanceToSummitKm,
      'climbZone': climbZone.toJson(),
      'deltaSeconds': deltaSeconds,
    };
  }

  factory BluffingStepInput.fromJson(Map<String, dynamic> json) {
    return BluffingStepInput(
      wPrimeRemainingPct:
          (json['wPrimeRemainingPct'] as num?)?.toDouble() ?? 62.0,
      powerOutputWatts: (json['powerOutputWatts'] as num?)?.toDouble() ?? 435.0,
      heartRateBpm: (json['heartRateBpm'] as num?)?.toDouble() ?? 176.0,
      maxHeartRateBpm: (json['maxHeartRateBpm'] as num?)?.toDouble() ?? 192.0,
      lactateMmol: (json['lactateMmol'] as num?)?.toDouble() ?? 6.8,
      cadenceRpm: (json['cadenceRpm'] as num?)?.toDouble() ?? 86.0,
      climbGradientPct: (json['climbGradientPct'] as num?)?.toDouble() ?? 9.4,
      altitudeMeters: (json['altitudeMeters'] as num?)?.toDouble() ?? 1720.0,
      distanceToSummitKm:
          (json['distanceToSummitKm'] as num?)?.toDouble() ?? 4.2,
      climbZone: ClimbContextZone.fromJson(
        json['climbZone'] as String? ?? 'steepPitch',
      ),
      deltaSeconds: (json['deltaSeconds'] as num?)?.toDouble() ?? 10.0,
    );
  }
}

/// Wynik pojedynczego kroku oceny mowy ciała i blefu.
class BluffingStepResult {
  final double trueCrisisScore;
  final double displayedCrisisScore;
  final double deceptionGap;
  final BodyLanguageCue activeCue;
  final double deceptionSuccessProbability;
  final double metabolicMaskingCostWatts;
  final double mentalFocusDrain;
  final double counterAttackSurpriseBonusPct;
  final BluffDetectionOutcome overallOutcome;
  final String radioTacticalNote;

  const BluffingStepResult({
    required this.trueCrisisScore,
    required this.displayedCrisisScore,
    required this.deceptionGap,
    required this.activeCue,
    required this.deceptionSuccessProbability,
    required this.metabolicMaskingCostWatts,
    required this.mentalFocusDrain,
    required this.counterAttackSurpriseBonusPct,
    required this.overallOutcome,
    required this.radioTacticalNote,
  });

  Map<String, dynamic> toJson() {
    return {
      'trueCrisisScore': trueCrisisScore,
      'displayedCrisisScore': displayedCrisisScore,
      'deceptionGap': deceptionGap,
      'activeCue': activeCue.toJson(),
      'deceptionSuccessProbability': deceptionSuccessProbability,
      'metabolicMaskingCostWatts': metabolicMaskingCostWatts,
      'mentalFocusDrain': mentalFocusDrain,
      'counterAttackSurpriseBonusPct': counterAttackSurpriseBonusPct,
      'overallOutcome': overallOutcome.toJson(),
      'radioTacticalNote': radioTacticalNote,
    };
  }

  factory BluffingStepResult.fromJson(Map<String, dynamic> json) {
    return BluffingStepResult(
      trueCrisisScore: (json['trueCrisisScore'] as num?)?.toDouble() ?? 30.0,
      displayedCrisisScore:
          (json['displayedCrisisScore'] as num?)?.toDouble() ?? 30.0,
      deceptionGap: (json['deceptionGap'] as num?)?.toDouble() ?? 0.0,
      activeCue: BodyLanguageCue.fromJson(
        json['activeCue'] as String? ?? 'steadySeatedSpin',
      ),
      deceptionSuccessProbability:
          (json['deceptionSuccessProbability'] as num?)?.toDouble() ?? 0.85,
      metabolicMaskingCostWatts:
          (json['metabolicMaskingCostWatts'] as num?)?.toDouble() ?? 0.0,
      mentalFocusDrain: (json['mentalFocusDrain'] as num?)?.toDouble() ?? 0.0,
      counterAttackSurpriseBonusPct:
          (json['counterAttackSurpriseBonusPct'] as num?)?.toDouble() ?? 0.0,
      overallOutcome: BluffDetectionOutcome.fromJson(
        json['overallOutcome'] as String? ?? 'fooledCompletely',
      ),
      radioTacticalNote:
          json['radioTacticalNote'] as String? ?? 'Stabilny rytm na podjeździe.',
    );
  }
}

/// Wpis w dzienniku psychologii podjazdu.
class BluffingHistoryEntry {
  final int stepIndex;
  final PokerFaceTacticMode tactic;
  final double trueCrisisScore;
  final double displayedCrisisScore;
  final BluffDetectionOutcome outcome;
  final String note;

  const BluffingHistoryEntry({
    required this.stepIndex,
    required this.tactic,
    required this.trueCrisisScore,
    required this.displayedCrisisScore,
    required this.outcome,
    required this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'stepIndex': stepIndex,
      'tactic': tactic.toJson(),
      'trueCrisisScore': trueCrisisScore,
      'displayedCrisisScore': displayedCrisisScore,
      'outcome': outcome.toJson(),
      'note': note,
    };
  }

  factory BluffingHistoryEntry.fromJson(Map<String, dynamic> json) {
    return BluffingHistoryEntry(
      stepIndex: (json['stepIndex'] as num?)?.toInt() ?? 0,
      tactic: PokerFaceTacticMode.fromJson(
        json['tactic'] as String? ?? 'authentic',
      ),
      trueCrisisScore: (json['trueCrisisScore'] as num?)?.toDouble() ?? 30.0,
      displayedCrisisScore:
          (json['displayedCrisisScore'] as num?)?.toDouble() ?? 30.0,
      outcome: BluffDetectionOutcome.fromJson(
        json['outcome'] as String? ?? 'fooledCompletely',
      ),
      note: json['note'] as String? ?? '',
    );
  }
}

/// Pełny stan mechaniki Poker Face i mowy ciała na podjeździe.
class BluffingAndPokerFaceState {
  final PokerFaceRiderProfile riderProfile;
  final PokerFaceTacticMode activeTactic;
  final BluffingStepInput lastInput;
  final BluffingStepResult lastResult;
  final double mentalFocusRemaining;
  final double sandbagChargeSeconds;
  final bool counterAttackWindowActive;
  final double counterAttackBonusPct;
  final List<RivalBodyLanguageObserver> rivals;
  final String selectedRivalId;
  final List<BluffingHistoryEntry> history;
  final bool isClimbActive;
  final int totalBluffSuccesses;
  final int totalBluffExposed;
  final int stepCounter;

  const BluffingAndPokerFaceState({
    required this.riderProfile,
    required this.activeTactic,
    required this.lastInput,
    required this.lastResult,
    required this.mentalFocusRemaining,
    required this.sandbagChargeSeconds,
    required this.counterAttackWindowActive,
    required this.counterAttackBonusPct,
    required this.rivals,
    required this.selectedRivalId,
    required this.history,
    this.isClimbActive = true,
    this.totalBluffSuccesses = 0,
    this.totalBluffExposed = 0,
    this.stepCounter = 0,
  });

  factory BluffingAndPokerFaceState.initial() {
    const profile = PokerFaceRiderProfile(
      riderId: 'leader-gc-1',
      riderName: 'M. Kwiatkowski (GC)',
      pokerFaceSkill: 84.0,
      mentalToughness: 88.0,
      ftpWatts: 425.0,
      wPrimeMaxJ: 24500.0,
      hasDarkMirroredSunglasses: true,
    );
    const input = BluffingStepInput(
      wPrimeRemainingPct: 54.0,
      powerOutputWatts: 448.0,
      heartRateBpm: 181.0,
      maxHeartRateBpm: 193.0,
      lactateMmol: 7.4,
      cadenceRpm: 84.0,
      climbGradientPct: 9.8,
      altitudeMeters: 1890.0,
      distanceToSummitKm: 4.6,
      climbZone: ClimbContextZone.highAltitudeFinal,
      deltaSeconds: 15.0,
    );
    const rivals = [
      RivalBodyLanguageObserver(
        rivalId: 'rival-1',
        rivalName: 'T. Pogačar',
        teamName: 'UAE Emirates',
        observationSkill: 88.0,
        aggression: 92.0,
        suspicionLevel: 0.22,
        perceivedCrisisScore: 34.0,
      ),
      RivalBodyLanguageObserver(
        rivalId: 'rival-2',
        rivalName: 'J. Vingegaard',
        teamName: 'Visma | Lease',
        observationSkill: 91.0,
        aggression: 79.0,
        suspicionLevel: 0.26,
        perceivedCrisisScore: 36.0,
      ),
      RivalBodyLanguageObserver(
        rivalId: 'rival-3',
        rivalName: 'R. Evenepoel',
        teamName: 'Soudal Quick-Step',
        observationSkill: 74.0,
        aggression: 89.0,
        suspicionLevel: 0.14,
        perceivedCrisisScore: 28.0,
      ),
    ];

    const initialBase = BluffingAndPokerFaceState(
      riderProfile: profile,
      activeTactic: PokerFaceTacticMode.pokerFaceHideCrisis,
      lastInput: input,
      lastResult: BluffingStepResult(
        trueCrisisScore: 48.0,
        displayedCrisisScore: 26.0,
        deceptionGap: 22.0,
        activeCue: BodyLanguageCue.pokerFaceMask,
        deceptionSuccessProbability: 0.84,
        metabolicMaskingCostWatts: 10.5,
        mentalFocusDrain: 1.8,
        counterAttackSurpriseBonusPct: 0.0,
        overallOutcome: BluffDetectionOutcome.fooledCompletely,
        radioTacticalNote:
            'Kamienna twarz działa — rywale nie widzą narastającego mleczanu.',
      ),
      mentalFocusRemaining: 92.0,
      sandbagChargeSeconds: 0.0,
      counterAttackWindowActive: false,
      counterAttackBonusPct: 0.0,
      rivals: rivals,
      selectedRivalId: 'rival-1',
      history: [],
      isClimbActive: true,
      totalBluffSuccesses: 1,
      totalBluffExposed: 0,
      stepCounter: 1,
    );

    final evaluated = BluffingAndPokerFaceEngine.evaluateStep(
      initialBase,
      input,
    );
    return evaluated.$1;
  }

  RivalBodyLanguageObserver? get selectedRival {
    if (rivals.isEmpty) return null;
    for (final rival in rivals) {
      if (rival.rivalId == selectedRivalId) return rival;
    }
    return rivals.first;
  }

  BluffingAndPokerFaceState copyWith({
    PokerFaceRiderProfile? riderProfile,
    PokerFaceTacticMode? activeTactic,
    BluffingStepInput? lastInput,
    BluffingStepResult? lastResult,
    double? mentalFocusRemaining,
    double? sandbagChargeSeconds,
    bool? counterAttackWindowActive,
    double? counterAttackBonusPct,
    List<RivalBodyLanguageObserver>? rivals,
    String? selectedRivalId,
    List<BluffingHistoryEntry>? history,
    bool? isClimbActive,
    int? totalBluffSuccesses,
    int? totalBluffExposed,
    int? stepCounter,
  }) {
    return BluffingAndPokerFaceState(
      riderProfile: riderProfile ?? this.riderProfile,
      activeTactic: activeTactic ?? this.activeTactic,
      lastInput: lastInput ?? this.lastInput,
      lastResult: lastResult ?? this.lastResult,
      mentalFocusRemaining: mentalFocusRemaining ?? this.mentalFocusRemaining,
      sandbagChargeSeconds: sandbagChargeSeconds ?? this.sandbagChargeSeconds,
      counterAttackWindowActive:
          counterAttackWindowActive ?? this.counterAttackWindowActive,
      counterAttackBonusPct:
          counterAttackBonusPct ?? this.counterAttackBonusPct,
      rivals: rivals ?? this.rivals,
      selectedRivalId: selectedRivalId ?? this.selectedRivalId,
      history: history ?? this.history,
      isClimbActive: isClimbActive ?? this.isClimbActive,
      totalBluffSuccesses: totalBluffSuccesses ?? this.totalBluffSuccesses,
      totalBluffExposed: totalBluffExposed ?? this.totalBluffExposed,
      stepCounter: stepCounter ?? this.stepCounter,
    );
  }
}

/// Deterministyczny silnik fizjologii mowy ciała, blefowania i reakcji AI na podjeździe.
class BluffingAndPokerFaceEngine {
  const BluffingAndPokerFaceEngine._();

  /// Wylicza rzeczywisty poziom kryzysu fizjologicznego (0–100).
  static double computeTrueCrisisScore(
    BluffingStepInput input,
    PokerFaceRiderProfile profile,
  ) {
    final double wPrimeDeficit =
        (100.0 - input.wPrimeRemainingPct.clamp(0.0, 100.0)) * 0.42;
    final double ftpRatio =
        (input.powerOutputWatts / math.max(150.0, profile.ftpWatts))
            .clamp(0.5, 1.8);
    final double intensityStress = ((ftpRatio - 0.85) * 45.0).clamp(0.0, 28.0);
    final double hrRatio =
        (input.heartRateBpm / math.max(120.0, input.maxHeartRateBpm))
            .clamp(0.5, 1.05);
    final double hrStress = ((hrRatio - 0.82) * 85.0).clamp(0.0, 18.0);
    final double lactateStress =
        ((input.lactateMmol - 3.5) * 3.2).clamp(0.0, 20.0);
    final double gradientStress =
        ((input.climbGradientPct - 6.0) * 1.4).clamp(0.0, 10.0);
    final double altitudePenalty =
        input.altitudeMeters > 1600.0
            ? ((input.altitudeMeters - 1600.0) / 1000.0) * 6.5
            : 0.0;
    final double cadenceDropPenalty =
        input.cadenceRpm < 76.0 ? (76.0 - input.cadenceRpm) * 0.6 : 0.0;

    final double rawScore =
        wPrimeDeficit +
        intensityStress +
        hrStress +
        lactateStress +
        gradientStress +
        altitudePenalty +
        cadenceDropPenalty;

    return rawScore.clamp(0.0, 100.0);
  }

  /// Wylicza prezentowany na zewnątrz poziom kryzysu po zastosowaniu taktyki mowy ciała.
  static double computeDisplayedCrisisScore({
    required double trueCrisisScore,
    required PokerFaceTacticMode tactic,
    required PokerFaceRiderProfile profile,
    required double mentalFocusRemaining,
  }) {
    final double skillFactor = (profile.pokerFaceSkill / 100.0).clamp(0.2, 1.0);
    final double focusFactor = (mentalFocusRemaining / 100.0).clamp(0.25, 1.0);
    final double maskPower =
        (skillFactor * 0.75 + focusFactor * 0.25 + profile.visualMaskBonus)
            .clamp(0.2, 1.15);

    switch (tactic) {
      case PokerFaceTacticMode.authentic:
        return trueCrisisScore;
      case PokerFaceTacticMode.pokerFaceHideCrisis:
        final double reduction = 34.0 * maskPower;
        return (trueCrisisScore - reduction).clamp(8.0, 92.0);
      case PokerFaceTacticMode.sandbaggingPlayDead:
        final double theatricalBoost = 32.0 * maskPower;
        return math.max(trueCrisisScore + theatricalBoost, 64.0).clamp(0.0, 96.0);
      case PokerFaceTacticMode.bluffShowOfStrength:
        final double suppression = 42.0 * maskPower;
        return (trueCrisisScore - suppression).clamp(5.0, 65.0);
    }
  }

  /// Dobiera wizualny sygnał mowy ciała na podstawie taktyki i stanu zmęczenia.
  static BodyLanguageCue resolveBodyLanguageCue({
    required PokerFaceTacticMode tactic,
    required double trueCrisisScore,
    required double mentalFocusRemaining,
  }) {
    if (mentalFocusRemaining < 12.0 && trueCrisisScore > 75.0) {
      return BodyLanguageCue.headBobbingOpenMouth;
    }

    switch (tactic) {
      case PokerFaceTacticMode.authentic:
        if (trueCrisisScore >= 78.0) return BodyLanguageCue.headBobbingOpenMouth;
        if (trueCrisisScore >= 52.0) return BodyLanguageCue.shoulderRocking;
        return BodyLanguageCue.steadySeatedSpin;
      case PokerFaceTacticMode.pokerFaceHideCrisis:
        if (trueCrisisScore >= 88.0 && mentalFocusRemaining < 28.0) {
          return BodyLanguageCue.shoulderRocking;
        }
        return BodyLanguageCue.pokerFaceMask;
      case PokerFaceTacticMode.sandbaggingPlayDead:
        return BodyLanguageCue.dropToBackOfGroup;
      case PokerFaceTacticMode.bluffShowOfStrength:
        return BodyLanguageCue.zippedUpAndOutOfSaddle;
    }
  }

  /// Ocenia reakcję pojedynczego rywala AI na prezentowaną mowę ciała.
  static RivalBodyLanguageObserver evaluateRivalPerception({
    required RivalBodyLanguageObserver rival,
    required PokerFaceTacticMode tactic,
    required double trueCrisisScore,
    required double displayedCrisisScore,
    required PokerFaceRiderProfile profile,
    required double mentalFocusRemaining,
    required double deltaSeconds,
  }) {
    if (tactic == PokerFaceTacticMode.authentic) {
      final double smoothedSuspicion =
          (rival.suspicionLevel - 0.08 * (deltaSeconds / 10.0)).clamp(0.05, 1.0);
      return rival.copyWith(
        suspicionLevel: smoothedSuspicion,
        perceivedCrisisScore: trueCrisisScore,
        isBaitedIntoAttack: false,
        lastOutcome: BluffDetectionOutcome.fooledCompletely,
      );
    }

    final double deceptionGap = (trueCrisisScore - displayedCrisisScore).abs();
    final double observerFactor = (rival.observationSkill / 100.0).clamp(0.3, 1.0);
    final double maskFactor =
        ((profile.pokerFaceSkill / 100.0) * 0.7 +
                (mentalFocusRemaining / 100.0) * 0.3 +
                profile.visualMaskBonus)
            .clamp(0.2, 1.15);

    // Im większa rozbieżność i wyższa obserwacja rywala, tym szybciej rośnie podejrzliwość.
    final double suspicionDelta =
        ((deceptionGap / 100.0) * observerFactor * 0.24 -
                maskFactor * 0.09) *
            (deltaSeconds / 10.0);

    final double nextSuspicion =
        (rival.suspicionLevel + suspicionDelta).clamp(0.05, 1.0);

    final double perceived =
        displayedCrisisScore +
        (trueCrisisScore - displayedCrisisScore) * (nextSuspicion * 0.72);

    bool baited = false;
    BluffDetectionOutcome outcome;

    if (nextSuspicion >= 0.72) {
      outcome = BluffDetectionOutcome.bluffSeenThrough;
    } else if (tactic == PokerFaceTacticMode.sandbaggingPlayDead &&
        nextSuspicion < 0.52 &&
        rival.aggression >= 75.0 &&
        perceived >= 60.0) {
      baited = true;
      outcome = BluffDetectionOutcome.counterAttackBaited;
    } else if (nextSuspicion >= 0.45) {
      outcome = BluffDetectionOutcome.partiallySuspicious;
    } else {
      outcome = BluffDetectionOutcome.fooledCompletely;
    }

    return rival.copyWith(
      suspicionLevel: nextSuspicion,
      perceivedCrisisScore: perceived.clamp(0.0, 100.0),
      isBaitedIntoAttack: baited,
      lastOutcome: outcome,
    );
  }

  /// Wykonuje pełny krok symulacji Poker Face dla bieżącego stanu i telemetrii.
  static (BluffingAndPokerFaceState, BluffingStepResult) evaluateStep(
    BluffingAndPokerFaceState state,
    BluffingStepInput input,
  ) {
    final double trueCrisis = computeTrueCrisisScore(input, state.riderProfile);

    // Jeśli brakuje koncentracji na kosztowny blef, automatyczny powrót do naturalnej jazdy.
    final PokerFaceTacticMode effectiveTactic =
        (state.mentalFocusRemaining < 6.0 &&
                state.activeTactic != PokerFaceTacticMode.authentic)
            ? PokerFaceTacticMode.authentic
            : state.activeTactic;

    final double displayedCrisis = computeDisplayedCrisisScore(
      trueCrisisScore: trueCrisis,
      tactic: effectiveTactic,
      profile: state.riderProfile,
      mentalFocusRemaining: state.mentalFocusRemaining,
    );

    final BodyLanguageCue cue = resolveBodyLanguageCue(
      tactic: effectiveTactic,
      trueCrisisScore: trueCrisis,
      mentalFocusRemaining: state.mentalFocusRemaining,
    );

    // Koszt metaboliczny utrzymania kamiennej twarzy / pokazu siły.
    double maskingCostWatts = 0.0;
    double focusDrain = -1.2; // Naturalna regeneracja przy autentycznej jeździe.
    switch (effectiveTactic) {
      case PokerFaceTacticMode.authentic:
        maskingCostWatts = 0.0;
        focusDrain = -1.8 * (input.deltaSeconds / 10.0);
        break;
      case PokerFaceTacticMode.pokerFaceHideCrisis:
        maskingCostWatts = input.powerOutputWatts * 0.025;
        focusDrain =
            (2.2 + (trueCrisis / 45.0)) * (input.deltaSeconds / 10.0);
        break;
      case PokerFaceTacticMode.sandbaggingPlayDead:
        maskingCostWatts = 0.0;
        focusDrain = 1.6 * (input.deltaSeconds / 10.0);
        break;
      case PokerFaceTacticMode.bluffShowOfStrength:
        maskingCostWatts = input.powerOutputWatts * 0.042;
        focusDrain = 3.1 * (input.deltaSeconds / 10.0);
        break;
    }

    final double nextFocus =
        (state.mentalFocusRemaining - focusDrain).clamp(0.0, 100.0);

    final List<RivalBodyLanguageObserver> updatedRivals = state.rivals
        .map(
          (r) => evaluateRivalPerception(
            rival: r,
            tactic: effectiveTactic,
            trueCrisisScore: trueCrisis,
            displayedCrisisScore: displayedCrisis,
            profile: state.riderProfile,
            mentalFocusRemaining: nextFocus,
            deltaSeconds: input.deltaSeconds,
          ),
        )
        .toList(growable: false);

    final int baitedCount =
        updatedRivals.where((r) => r.isBaitedIntoAttack).length;
    final int exposedCount = updatedRivals
        .where((r) => r.lastOutcome == BluffDetectionOutcome.bluffSeenThrough)
        .length;
    final int suspiciousCount = updatedRivals
        .where((r) => r.lastOutcome == BluffDetectionOutcome.partiallySuspicious)
        .length;

    final BluffDetectionOutcome overallOutcome;
    if (baitedCount > 0 && effectiveTactic == PokerFaceTacticMode.sandbaggingPlayDead) {
      overallOutcome = BluffDetectionOutcome.counterAttackBaited;
    } else if (exposedCount > updatedRivals.length / 2) {
      overallOutcome = BluffDetectionOutcome.bluffSeenThrough;
    } else if (suspiciousCount > 0 || exposedCount > 0) {
      overallOutcome = BluffDetectionOutcome.partiallySuspicious;
    } else {
      overallOutcome = BluffDetectionOutcome.fooledCompletely;
    }

    final double avgSuspicion = updatedRivals.isEmpty
        ? 0.0
        : updatedRivals.fold<double>(0.0, (s, r) => s + r.suspicionLevel) /
            updatedRivals.length;
    final double successProb = (1.0 - avgSuspicion).clamp(0.05, 0.98);

    // Ładowanie okna kontrataku w trybie Sandbagging, jeśli kolarz ma realny zapas W'.
    double nextSandbagCharge = state.sandbagChargeSeconds;
    if (effectiveTactic == PokerFaceTacticMode.sandbaggingPlayDead &&
        input.wPrimeRemainingPct >= 40.0) {
      nextSandbagCharge =
          (nextSandbagCharge + input.deltaSeconds).clamp(0.0, 60.0);
    } else {
      nextSandbagCharge =
          (nextSandbagCharge - input.deltaSeconds * 0.5).clamp(0.0, 60.0);
    }

    final bool counterWindowReady =
        nextSandbagCharge >= 20.0 &&
        input.wPrimeRemainingPct >= 38.0 &&
        overallOutcome != BluffDetectionOutcome.bluffSeenThrough;

    final double surpriseBonus = counterWindowReady
        ? (6.0 + (nextSandbagCharge / 60.0) * 8.0).clamp(6.0, 14.0)
        : 0.0;

    final String radioNote = _buildRadioNote(
      tactic: effectiveTactic,
      outcome: overallOutcome,
      trueCrisis: trueCrisis,
      displayedCrisis: displayedCrisis,
      counterReady: counterWindowReady,
    );

    final result = BluffingStepResult(
      trueCrisisScore: trueCrisis,
      displayedCrisisScore: displayedCrisis,
      deceptionGap: (trueCrisis - displayedCrisis).abs(),
      activeCue: cue,
      deceptionSuccessProbability: successProb,
      metabolicMaskingCostWatts: maskingCostWatts,
      mentalFocusDrain: focusDrain,
      counterAttackSurpriseBonusPct: surpriseBonus,
      overallOutcome: overallOutcome,
      radioTacticalNote: radioNote,
    );

    final int nextStep = state.stepCounter + 1;
    final entry = BluffingHistoryEntry(
      stepIndex: nextStep,
      tactic: effectiveTactic,
      trueCrisisScore: trueCrisis,
      displayedCrisisScore: displayedCrisis,
      outcome: overallOutcome,
      note: radioNote,
    );

    final List<BluffingHistoryEntry> nextHistory = [
      entry,
      ...state.history.take(11),
    ];

    final int nextSuccesses = state.totalBluffSuccesses +
        (effectiveTactic != PokerFaceTacticMode.authentic &&
                (overallOutcome == BluffDetectionOutcome.fooledCompletely ||
                    overallOutcome == BluffDetectionOutcome.counterAttackBaited)
            ? 1
            : 0);
    final int nextExposed = state.totalBluffExposed +
        (overallOutcome == BluffDetectionOutcome.bluffSeenThrough ? 1 : 0);

    final nextState = state.copyWith(
      activeTactic: effectiveTactic,
      lastInput: input,
      lastResult: result,
      mentalFocusRemaining: nextFocus,
      sandbagChargeSeconds: nextSandbagCharge,
      counterAttackWindowActive: counterWindowReady,
      counterAttackBonusPct: surpriseBonus,
      rivals: updatedRivals,
      history: nextHistory,
      totalBluffSuccesses: nextSuccesses,
      totalBluffExposed: nextExposed,
      stepCounter: nextStep,
    );

    return (nextState, result);
  }

  /// Aktywuje kontratak z zaskoczenia po skutecznym Sandbaggingu.
  static ({
    BluffingAndPokerFaceState state,
    bool activated,
    double surpriseBonusPct,
    String message,
  }) triggerCounterAttack(BluffingAndPokerFaceState state) {
    if (!state.counterAttackWindowActive || state.lastInput.wPrimeRemainingPct < 35.0) {
      return (
        state: state,
        activated: false,
        surpriseBonusPct: 0.0,
        message: 'Brak aktywnego okna kontry — ładuj Sandbagging przy W\' >= 40%.',
      );
    }

    final double bonus = state.counterAttackBonusPct.clamp(6.0, 14.0);
    final nextInput = state.lastInput.copyWith(
      powerOutputWatts: state.riderProfile.ftpWatts * 1.42,
      wPrimeRemainingPct: (state.lastInput.wPrimeRemainingPct - 14.0).clamp(0.0, 100.0),
      cadenceRpm: 98.0,
    );

    final entry = BluffingHistoryEntry(
      stepIndex: state.stepCounter + 1,
      tactic: PokerFaceTacticMode.bluffShowOfStrength,
      trueCrisisScore: state.lastResult.trueCrisisScore,
      displayedCrisisScore: 12.0,
      outcome: BluffDetectionOutcome.counterAttackBaited,
      note:
          'KONTRATAK Z ZASKOCZENIA! +${bonus.toStringAsFixed(1)}% przewagi reakcji rywali.',
    );

    final nextState = state.copyWith(
      activeTactic: PokerFaceTacticMode.bluffShowOfStrength,
      lastInput: nextInput,
      sandbagChargeSeconds: 0.0,
      counterAttackWindowActive: false,
      counterAttackBonusPct: 0.0,
      totalBluffSuccesses: state.totalBluffSuccesses + 1,
      stepCounter: state.stepCounter + 1,
      history: [entry, ...state.history.take(11)],
    );

    return (
      state: nextState,
      activated: true,
      surpriseBonusPct: bonus,
      message:
          'Atak wyprowadzony z ogona grupy! Rywale spóźnieni o +${bonus.toStringAsFixed(1)}% czasu reakcji.',
    );
  }

  static String _buildRadioNote({
    required PokerFaceTacticMode tactic,
    required BluffDetectionOutcome outcome,
    required double trueCrisis,
    required double displayedCrisis,
    required bool counterReady,
  }) {
    switch (tactic) {
      case PokerFaceTacticMode.authentic:
        return trueCrisis > 68.0
            ? 'Jedziesz na limicie — rywale widzą ciężki oddech na stromiźnie.'
            : 'Stabilna jazda w siodle. Pełna kontrola tętna i kadencji.';
      case PokerFaceTacticMode.pokerFaceHideCrisis:
        if (outcome == BluffDetectionOutcome.bluffSeenThrough) {
          return 'Uwaga! Rywale zauważyli kołysanie ramion mimo okularów.';
        }
        return 'Poker Face utrzymany: ukryto ${(trueCrisis - displayedCrisis).abs().toStringAsFixed(0)} pkt kryzysu.';
      case PokerFaceTacticMode.sandbaggingPlayDead:
        if (counterReady) {
          return 'Rywale łyknęli przynętę! Okno kontrataku z zaskoczenia otwarte.';
        }
        return 'Zjazd na koniec grupki — rywale zaczynają wierzyć w Twój kryzys.';
      case PokerFaceTacticMode.bluffShowOfStrength:
        if (outcome == BluffDetectionOutcome.bluffSeenThrough) {
          return 'Blef siły przejrzany — rywale wiedzą, że W\' spada.';
        }
        return 'Zapięta koszulka i taniec w korbach! Rywale wahają się przed atakiem.';
    }
  }
}

/// Kontroler Riverpod zarządzający stanem mowy ciała i blefowania na podjeździe.
class BluffingAndPokerFaceNotifier
    extends StateNotifier<BluffingAndPokerFaceState> {
  BluffingAndPokerFaceNotifier() : super(BluffingAndPokerFaceState.initial());

  void selectTactic(PokerFaceTacticMode tactic) {
    if (!state.isClimbActive) return;
    if (tactic != PokerFaceTacticMode.authentic &&
        state.mentalFocusRemaining < 6.0) {
      return;
    }
    final nextBase = state.copyWith(activeTactic: tactic);
    final evaluated = BluffingAndPokerFaceEngine.evaluateStep(
      nextBase,
      state.lastInput,
    );
    state = evaluated.$1;
  }

  void toggleSunglasses() {
    final nextProfile = state.riderProfile.copyWith(
      hasDarkMirroredSunglasses: !state.riderProfile.hasDarkMirroredSunglasses,
    );
    final nextBase = state.copyWith(riderProfile: nextProfile);
    final evaluated = BluffingAndPokerFaceEngine.evaluateStep(
      nextBase,
      state.lastInput,
    );
    state = evaluated.$1;
  }

  void selectRival(String rivalId) {
    state = state.copyWith(selectedRivalId: rivalId);
  }

  void simulateNextClimbStep() {
    if (!state.isClimbActive) return;
    final current = state.lastInput;
    final double nextWPrime =
        (current.wPrimeRemainingPct - 4.5).clamp(18.0, 95.0);
    final double nextDist =
        (current.distanceToSummitKm - 0.6).clamp(0.4, 20.0);
    final ClimbContextZone nextZone = nextDist <= 1.2
        ? ClimbContextZone.summitApproach
        : current.climbZone;

    final nextInput = current.copyWith(
      wPrimeRemainingPct: nextWPrime,
      lactateMmol: (current.lactateMmol + 0.35).clamp(2.5, 11.5),
      heartRateBpm: (current.heartRateBpm + 1.5).clamp(150.0, current.maxHeartRateBpm),
      distanceToSummitKm: nextDist,
      climbZone: nextZone,
      deltaSeconds: 15.0,
    );

    final evaluated = BluffingAndPokerFaceEngine.evaluateStep(state, nextInput);
    state = evaluated.$1;
  }

  String triggerCounterAttack() {
    final outcome = BluffingAndPokerFaceEngine.triggerCounterAttack(state);
    state = outcome.state;
    return outcome.message;
  }

  void resetClimbSession() {
    state = BluffingAndPokerFaceState.initial();
  }
}

final bluffingAndPokerFaceProvider = StateNotifierProvider<
    BluffingAndPokerFaceNotifier, BluffingAndPokerFaceState>(
  (ref) => BluffingAndPokerFaceNotifier(),
);

/// Wskaźnik łukowy porównujący rzeczywisty kryzys z prezentowaną maską Poker Face.
class PokerFaceBodyLanguageGaugePainter extends CustomPainter {
  final double trueCrisisScore;
  final double displayedCrisisScore;
  final double avgSuspicion;

  const PokerFaceBodyLanguageGaugePainter({
    required this.trueCrisisScore,
    required this.displayedCrisisScore,
    required this.avgSuspicion,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height * 0.56);
    final double radius = math.min(size.width, size.height) * 0.38;
    const double startAngle = math.pi * 0.8;
    const double sweepTotal = math.pi * 1.4;

    final Paint trackPaint = Paint()
      ..color = AppColors.surfaceLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final Rect outerRect = Rect.fromCircle(center: center, radius: radius);
    final Rect innerRect =
        Rect.fromCircle(center: center, radius: radius - 16);

    canvas.drawArc(outerRect, startAngle, sweepTotal, false, trackPaint);
    canvas.drawArc(
      innerRect,
      startAngle,
      sweepTotal,
      false,
      trackPaint..strokeWidth = 7,
    );

    // Zewnętrzny łuk: Rzeczywisty kryzys (Crimson / Amber).
    final Paint truePaint = Paint()
      ..color = trueCrisisScore >= 70
          ? AppColors.crimsonAlert
          : AppColors.amberWarning
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      outerRect,
      startAngle,
      sweepTotal * (trueCrisisScore.clamp(0, 100) / 100),
      false,
      truePaint,
    );

    // Wewnętrzny łuk: Prezentowana mowa ciała (Cyan / Gold).
    final Paint displayedPaint = Paint()
      ..color = AppColors.cyanAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      innerRect,
      startAngle,
      sweepTotal * (displayedCrisisScore.clamp(0, 100) / 100),
      false,
      displayedPaint,
    );

    // Wskaźnik podejrzliwości rywali.
    final double needleAngle =
        startAngle + sweepTotal * avgSuspicion.clamp(0.0, 1.0);
    final Offset needleEnd = Offset(
      center.dx + (radius + 6) * math.cos(needleAngle),
      center.dy + (radius + 6) * math.sin(needleAngle),
    );
    final Paint needlePaint = Paint()
      ..color = AppColors.goldAccent
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, needleEnd, needlePaint);
    canvas.drawCircle(center, 4.5, Paint()..color = AppColors.goldAccent);
  }

  @override
  bool shouldRepaint(covariant PokerFaceBodyLanguageGaugePainter oldDelegate) {
    return oldDelegate.trueCrisisScore != trueCrisisScore ||
        oldDelegate.displayedCrisisScore != displayedCrisisScore ||
        oldDelegate.avgSuspicion != avgSuspicion;
  }
}

/// Produkcyjny panel taktyczny mowy ciała i blefowania kryzysu na podjeździe (Poker Face).
class BluffingAndPokerFacePanel extends ConsumerStatefulWidget {
  const BluffingAndPokerFacePanel({super.key});

  @override
  ConsumerState<BluffingAndPokerFacePanel> createState() =>
      _BluffingAndPokerFacePanelState();
}

class _BluffingAndPokerFacePanelState
    extends ConsumerState<BluffingAndPokerFacePanel> {
  String? _actionBannerMessage;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bluffingAndPokerFaceProvider);
    final notifier = ref.read(bluffingAndPokerFaceProvider.notifier);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final bool isCompact = width < 640;
        final bool isDesktop = width >= 1120;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 1),
          ),
          padding: EdgeInsets.all(isCompact ? 12 : 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(state, notifier, isCompact),
                const SizedBox(height: 16),
                if (_actionBannerMessage != null) ...[
                  _buildActionBanner(_actionBannerMessage!),
                  const SizedBox(height: 12),
                ],
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: _buildTelemetryAndGaugeCard(state, isCompact),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 7,
                        child: _buildTacticsAndRivalsColumn(
                          state,
                          notifier,
                          isCompact,
                        ),
                      ),
                    ],
                  )
                else ...[
                  _buildTelemetryAndGaugeCard(state, isCompact),
                  const SizedBox(height: 16),
                  _buildTacticsAndRivalsColumn(state, notifier, isCompact),
                ],
                const SizedBox(height: 16),
                _buildHistoryLogCard(state, isCompact),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BluffingAndPokerFaceState state,
    BluffingAndPokerFaceNotifier notifier,
    bool isCompact,
  ) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryAccent.withValues(alpha: 0.5),
                  ),
                ),
                child: const Icon(
                  Icons.psychology_alt_rounded,
                  color: AppColors.goldAccent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Poker Face & Mowa Ciała na Podjeździe',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: isCompact ? 15 : 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${state.riderProfile.riderName} • ${state.lastInput.climbZone.label} (${state.lastInput.distanceToSummitKm.toStringAsFixed(1)} km do szczytu)',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InteractiveActionButton(
                label: state.riderProfile.hasDarkMirroredSunglasses
                    ? 'Okulary Lustrzane (+12%)'
                    : 'Bez Okularów (0%)',
                icon: Icons.visibility_off_rounded,
                isActive: state.riderProfile.hasDarkMirroredSunglasses,
                accentColor: AppColors.accentBlue,
                onPressed: notifier.toggleSunglasses,
              ),
              _InteractiveActionButton(
                label: 'Kolejny odcinek (+0.6 km)',
                icon: Icons.trending_up_rounded,
                isActive: false,
                accentColor: AppColors.goldAccent,
                onPressed: notifier.simulateNextClimbStep,
              ),
              _InteractiveActionButton(
                label: 'Reset',
                icon: Icons.refresh_rounded,
                isActive: false,
                accentColor: AppColors.textSecondary,
                onPressed: () {
                  notifier.resetClimbSession();
                  setState(() => _actionBannerMessage = null);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionBanner(String message) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.statusSuccess.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.statusSuccess.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.bolt_rounded,
            color: AppColors.statusSuccess,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryAndGaugeCard(
    BluffingAndPokerFaceState state,
    bool isCompact,
  ) {
    final avgSuspicion = state.rivals.isEmpty
        ? 0.0
        : state.rivals.fold<double>(0.0, (s, r) => s + r.suspicionLevel) /
            state.rivals.length;

    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              const Text(
                'TELEMETRIA MASKOWANIA',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.textSecondary,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Text(
                  state.lastResult.activeCue.label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cyanAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 170,
            child: CustomPaint(
              painter: PokerFaceBodyLanguageGaugePainter(
                trueCrisisScore: state.lastResult.trueCrisisScore,
                displayedCrisisScore: state.lastResult.displayedCrisisScore,
                avgSuspicion: avgSuspicion,
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 26),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(state.lastResult.deceptionSuccessProbability * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const Text(
                        'Skuteczność blefu',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetricTile(
                label: 'Prawdziwy kryzys',
                value:
                    '${state.lastResult.trueCrisisScore.toStringAsFixed(0)} / 100',
                accent: AppColors.crimsonAlert,
              ),
              _MetricTile(
                label: 'Prezentowana maska',
                value:
                    '${state.lastResult.displayedCrisisScore.toStringAsFixed(0)} / 100',
                accent: AppColors.cyanAccent,
              ),
              _MetricTile(
                label: 'Koncentracja',
                value: '${state.mentalFocusRemaining.toStringAsFixed(0)}%',
                accent: AppColors.goldAccent,
              ),
              _MetricTile(
                label: 'Zapas W\' / Moc',
                value:
                    '${state.lastInput.wPrimeRemainingPct.toStringAsFixed(0)}% • ${state.lastInput.powerOutputWatts.toStringAsFixed(0)} W',
                accent: AppColors.statusSuccess,
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            child: Container(
              key: ValueKey(state.lastResult.radioTacticalNote),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.headset_mic_rounded,
                    size: 16,
                    color: AppColors.goldAccent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.lastResult.radioTacticalNote,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textPrimary,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTacticsAndRivalsColumn(
    BluffingAndPokerFaceState state,
    BluffingAndPokerFaceNotifier notifier,
    bool isCompact,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.all(isCompact ? 14 : 18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  const Text(
                    'TAKTYKA MOWY CIAŁA',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    'Koszt maski: +${state.lastResult.metabolicMaskingCostWatts.toStringAsFixed(1)} W',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.amberWarning,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: isCompact ? 1 : 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: isCompact ? 3.1 : 2.35,
                children: PokerFaceTacticMode.values.map((tactic) {
                  final bool selected = state.activeTactic == tactic;
                  final bool disabled =
                      tactic != PokerFaceTacticMode.authentic &&
                          state.mentalFocusRemaining < 6.0;
                  return _TacticOptionCard(
                    tactic: tactic,
                    isSelected: selected,
                    isDisabled: disabled,
                    onTap: () => notifier.selectTactic(tactic),
                  );
                }).toList(growable: false),
              ),
              const SizedBox(height: 12),
              _InteractiveActionButton(
                label: state.counterAttackWindowActive
                    ? 'KONTRATAK Z ZASKOCZENIA (+${state.counterAttackBonusPct.toStringAsFixed(1)}%)'
                    : 'Kontratak (Ładuj Sandbagging: ${state.sandbagChargeSeconds.toStringAsFixed(0)}/20 s)',
                icon: Icons.flash_on_rounded,
                isActive: state.counterAttackWindowActive,
                isDisabled: !state.counterAttackWindowActive,
                accentColor: AppColors.goldAccent,
                fullWidth: true,
                onPressed: () {
                  final msg = notifier.triggerCounterAttack();
                  setState(() => _actionBannerMessage = msg);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(isCompact ? 14 : 18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'ODCZYT RYWALI W GRUPCE FAWORYTÓW',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              ...state.rivals.map(
                (rival) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _RivalObserverRow(
                    rival: rival,
                    isSelected: rival.rivalId == state.selectedRivalId,
                    onTap: () => notifier.selectRival(rival.rivalId),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryLogCard(
    BluffingAndPokerFaceState state,
    bool isCompact,
  ) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              const Text(
                'DZIENNIK PSYCHOLOGII PODJAZDU',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                'Udane: ${state.totalBluffSuccesses} • Przejrzane: ${state.totalBluffExposed}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (state.history.isEmpty)
            const Text(
              'Brak zarejestrowanych kroków.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            )
          else
            ...state.history.take(4).map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '#${entry.stepIndex} ${entry.tactic.shortTag}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.goldAccent,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.note,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                ),
        ],
      ),
    );
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
      constraints: const BoxConstraints(minWidth: 138),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
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

class _TacticOptionCard extends StatefulWidget {
  final PokerFaceTacticMode tactic;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  const _TacticOptionCard({
    required this.tactic,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  State<_TacticOptionCard> createState() => _TacticOptionCardState();
}

class _TacticOptionCardState extends State<_TacticOptionCard> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = widget.isSelected
        ? AppColors.goldAccent
        : _isFocused
            ? AppColors.accentBlue
            : _isHovered && !widget.isDisabled
                ? AppColors.primaryAccent
                : AppColors.cardBorder;

    final Color bgColor = widget.isDisabled
        ? AppColors.background.withValues(alpha: 0.6)
        : widget.isSelected
            ? AppColors.primaryAccent.withValues(alpha: 0.22)
            : _isPressed
                ? AppColors.surfaceLight.withValues(alpha: 0.95)
                : _isHovered
                    ? AppColors.surfaceLight
                    : AppColors.background;

    return FocusableActionDetector(
      enabled: !widget.isDisabled,
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      child: GestureDetector(
        onTapDown: widget.isDisabled
            ? null
            : (_) => setState(() => _isPressed = true),
        onTapUp: widget.isDisabled
            ? null
            : (_) {
                setState(() => _isPressed = false);
                widget.onTap();
              },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderColor,
              width: widget.isSelected || _isFocused ? 1.5 : 1.0,
            ),
          ),
          child: Opacity(
            opacity: widget.isDisabled ? 0.45 : 1.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.tactic.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: widget.isSelected
                              ? AppColors.goldAccent
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (widget.isSelected)
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 15,
                        color: AppColors.goldAccent,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.tactic.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RivalObserverRow extends StatefulWidget {
  final RivalBodyLanguageObserver rival;
  final bool isSelected;
  final VoidCallback onTap;

  const _RivalObserverRow({
    required this.rival,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_RivalObserverRow> createState() => _RivalObserverRowState();
}

class _RivalObserverRowState extends State<_RivalObserverRow> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final Color statusColor;
    switch (widget.rival.lastOutcome) {
      case BluffDetectionOutcome.fooledCompletely:
        statusColor = AppColors.statusSuccess;
        break;
      case BluffDetectionOutcome.partiallySuspicious:
        statusColor = AppColors.amberWarning;
        break;
      case BluffDetectionOutcome.bluffSeenThrough:
        statusColor = AppColors.crimsonAlert;
        break;
      case BluffDetectionOutcome.counterAttackBaited:
        statusColor = AppColors.cyanAccent;
        break;
    }

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isSelected || _hovered
                ? AppColors.surfaceLight
                : AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focused
                  ? AppColors.accentBlue
                  : widget.isSelected
                      ? AppColors.goldAccent
                      : AppColors.cardBorder,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.rival.rivalName} (${widget.rival.teamName})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Postrzegany kryzys: ${widget.rival.perceivedCrisisScore.toStringAsFixed(0)}% • Podejrzenie: ${(widget.rival.suspicionLevel * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.45),
                  ),
                ),
                child: Text(
                  widget.rival.lastOutcome.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InteractiveActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final bool isDisabled;
  final bool fullWidth;
  final Color accentColor;
  final VoidCallback onPressed;

  const _InteractiveActionButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.accentColor,
    required this.onPressed,
    this.isDisabled = false,
    this.fullWidth = false,
  });

  @override
  State<_InteractiveActionButton> createState() =>
      _InteractiveActionButtonState();
}

class _InteractiveActionButtonState extends State<_InteractiveActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color bg = widget.isDisabled
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : widget.isActive
            ? widget.accentColor.withValues(alpha: 0.22)
            : _pressed
                ? AppColors.surfaceLight
                : _hovered
                    ? AppColors.surfaceLight.withValues(alpha: 0.85)
                    : AppColors.background;

    final Color border = _focused
        ? AppColors.accentBlue
        : widget.isActive || _hovered
            ? widget.accentColor
            : AppColors.cardBorder;

    return FocusableActionDetector(
      enabled: !widget.isDisabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown:
            widget.isDisabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: widget.isDisabled
            ? null
            : (_) {
                setState(() => _pressed = false);
                widget.onPressed();
              },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: widget.fullWidth ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: _focused ? 1.5 : 1.0),
          ),
          child: Opacity(
            opacity: widget.isDisabled ? 0.5 : 1.0,
            child: Row(
              mainAxisSize:
                  widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, size: 16, color: widget.accentColor),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
