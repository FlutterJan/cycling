import 'dart:math' as math;

import '../../models/rider/rider.dart';
import '../simulation/tactical_ai_personality_profiles.dart';
import 'rider_race_state.dart';

/// Tryb taktyczny pasywnej jazdy na kole i blefowania kolarza AI w ucieczce.
enum WheelsuckingTacticMode {
  /// Kolarz normalnie współpracuje w rotacji i daje równe zmiany na czele.
  cooperative,

  /// Odmowa dawania zmian ("Skip Pulls / Sit On") — kolarz wiezie się na kole,
  /// chroniąc interes sprintera lub lidera jadącego z tyłu w peletonie.
  skipPullsSitOn,

  /// Blefowanie zmęczenia ("Poker Face") — udawanie jazdy na limicie na kole,
  /// mimo dużego zapasu W' i niskiego zmęczenia, aby sprowokować rywali do pracy.
  bluffingPainFace,

  /// Taktyczna gra nerwów na ostatnim kilometrze ("Cat & Mouse / Look-Back"),
  /// zmuszająca rywali do oglądania się za siebie i otwarcia sprintu jako pierwsi.
  finalKmStandoff,

  /// Wykorzystanie zmęczenia rywali po szarpaniu tempa i nagły kontratak zza pleców.
  counterAttackAmbush;

  String toJson() => name;

  static WheelsuckingTacticMode fromJson(String value) {
    return WheelsuckingTacticMode.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => WheelsuckingTacticMode.cooperative,
    );
  }

  String get displayName {
    switch (this) {
      case WheelsuckingTacticMode.cooperative:
        return 'Współpraca w rotacji';
      case WheelsuckingTacticMode.skipPullsSitOn:
        return 'Odmowa zmian (Sit On)';
      case WheelsuckingTacticMode.bluffingPainFace:
        return 'Blef zmęczenia (Poker Face)';
      case WheelsuckingTacticMode.finalKmStandoff:
        return 'Gra nerwów (Ostatni km)';
      case WheelsuckingTacticMode.counterAttackAmbush:
        return 'Kontratak zza koła';
    }
  }
}

/// Taktyczne uzasadnienie odmowy dawania zmian lub blefowania.
enum SitOnJustification {
  /// Brak powodu do pasywności — kolarz powinien pracować w ucieczce.
  none,

  /// Sprinter drużyny jedzie w peletonie z tyłu i ma realną szansę na finisz z grupy.
  sprinterInPelotonBehind,

  /// Lider GC / główny faworyt drużyny jedzie z tyłu w peletonie lub pościgu.
  gcLeaderInPelotonBehind,

  /// Oportunistyczna taktyka własna kolarza (oszczędzanie W' na finisz).
  opportunistConservation,

  /// Rywal ma przewagę liczebną kolegów w ucieczce i musi sam gonić/pracować.
  rivalTeammateOverload,

  /// Ostatni kilometr — taktyczne wyczekiwanie na ruch rywali przed finiszem.
  finalKmTrackStandoff;

  String toJson() => name;

  static SitOnJustification fromJson(String value) {
    return SitOnJustification.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SitOnJustification.none,
    );
  }
}

/// Przewidywana lub wywołana reakcja rywali w ucieczce na pasywną jazdę na kole.
enum RivalReactionType {
  /// Rywale akceptują sytuację i kontynuują równą jazdę.
  steadyPull,

  /// Rywale są poirytowani i szarpią tempo, marnując W' na przyspieszeniach.
  frustratedPaceSurge,

  /// Na ostatnim kilometrze rywale oglądają się za siebie i zwalniają tempo.
  lookBackSlowdown,

  /// Współpraca w ucieczce całkowicie siada, a peleton szybko odrabia stratę.
  breakawayCollapse,

  /// Rywal próbuje urwać pasywnego kolarza mocnym atakiem beztlenowym.
  furiousAttack;

  String toJson() => name;

  static RivalReactionType fromJson(String value) {
    return RivalReactionType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RivalReactionType.steadyPull,
    );
  }
}

/// Dane wejściowe do oceny decyzji o pasywnej jeździe na kole i blefowaniu.
class WheelsuckingAiInput {
  final String riderId;
  final String teamId;
  final RiderSpecialization specialization;
  final TacticalAiArchetype? archetype;
  final RiderRaceState riderState;

  /// Czy drużyna tego kolarza ma w peletonie z tyłu swojego sprintera.
  final bool hasTeamSprinterInPelotonBehind;

  /// Czy drużyna tego kolarza ma w peletonie z tyłu lidera GC / lidera etapu.
  final bool hasTeamLeaderInPelotonBehind;

  /// Aktualna przewaga czasowa ucieczki nad peletonem [s].
  final double pelotonGapSeconds;

  /// Dystans pozostały do mety [km].
  final double distanceToFinishKm;

  /// Dostępny zapas W' kolarza w ujęciu znormalizowanym [0.0 - 1.0].
  final double riderWPrimeRatio;

  /// Poziom zmęczenia kolarza [0.0 = świeży, 1.0 = skrajne wyczerpanie].
  final double riderFatigueRatio;

  /// Ocena umiejętności sprinterskich kolarza [1 - 100].
  final int riderSprintRating;

  /// Łączna liczba kolarzy w grupie ucieczkowej.
  final int breakawaySize;

  /// Liczba kolegów z drużyny w tej samej grupie (łącznie z tym kolarzem).
  final int teammatesInBreakawayCount;

  /// Liczba rywali w grupie.
  final int rivalsInBreakawayCount;

  /// Największa liczba kolarzy jednej drużyny rywali w tej ucieczce.
  final int maxRivalTeamSizeInBreakaway;

  /// Skumulowana frustracja rywali w ucieczce [0.0 - 1.0].
  final double rivalFrustrationIndex;

  /// Aktualna prędkość grupy [m/s].
  final double currentGroupSpeedMs;

  /// Bazowa moc potrzebna do utrzymania tempa na czele grupy [W].
  final double basePullPowerWatts;

  /// Czy meta znajduje się na podjeździe.
  final bool isUphillFinish;

  /// Aktualne nachylenie terenu [%].
  final double currentGradientPercent;

  /// Czas od ostatniej zmiany na czele [s].
  final double secondsSinceLastPull;

  /// Ziarno deterministyczne dla drobnych wahań taktycznych.
  final int randomSeed;

  const WheelsuckingAiInput({
    required this.riderId,
    required this.teamId,
    required this.specialization,
    this.archetype,
    required this.riderState,
    this.hasTeamSprinterInPelotonBehind = false,
    this.hasTeamLeaderInPelotonBehind = false,
    required this.pelotonGapSeconds,
    required this.distanceToFinishKm,
    required this.riderWPrimeRatio,
    required this.riderFatigueRatio,
    required this.riderSprintRating,
    required this.breakawaySize,
    this.teammatesInBreakawayCount = 1,
    this.rivalsInBreakawayCount = 1,
    this.maxRivalTeamSizeInBreakaway = 1,
    this.rivalFrustrationIndex = 0.0,
    required this.currentGroupSpeedMs,
    required this.basePullPowerWatts,
    this.isUphillFinish = false,
    this.currentGradientPercent = 0.0,
    this.secondsSinceLastPull = 0.0,
    this.randomSeed = 42,
  });

  bool get hasProtectedAssetInPelotonBehind =>
      hasTeamSprinterInPelotonBehind || hasTeamLeaderInPelotonBehind;
}

/// Wynik decyzji AI dotyczącej pasywnej jazdy na kole, blefu i gry nerwów.
class WheelsuckingAiDecision {
  final String riderId;
  final WheelsuckingTacticMode mode;
  final SitOnJustification justification;
  final TacticalOrder recommendedOrder;

  /// Udział w dawaniu zmian [0.0 = całkowita odmowa, 1.0 = pełna rotacja].
  final double pullContributionRatio;

  /// Docelowa moc na korbie [W].
  final int targetPowerWatts;

  /// Mnożnik prędkości względem tempa grupy (np. < 1.0 przy grze nerwów, > 1.0 przy ataku).
  final double targetSpeedFactor;

  /// Intensywność blefowania zmęczenia [0.0 - 1.0].
  final double bluffIntensity;

  /// Częstotliwość oglądania się za siebie na ostatnim kilometrze [Hz].
  final double lookBackFrequencyHz;

  /// Przewidywana reakcja rywali na zachowanie tego kolarza.
  final RivalReactionType expectedRivalReaction;

  /// Przyrost frustracji rywali w tym kroku [0.0 - 0.35].
  final double rivalFrustrationDelta;

  /// Szacowana oszczędność mocy dzięki pozostaniu na kole [W].
  final double wPrimeSavedWatts;

  /// Kara do wskaźnika współpracy grupy [0.0 - 0.45].
  final double cooperationPenalty;

  /// Opcjonalny komunikat do radia wyścigowego / komentarza TV.
  final String? radioAlertMessage;

  /// Zwięzłe uzasadnienie taktyczne dla UI i logów symulacji.
  final String tacticalMotive;

  const WheelsuckingAiDecision({
    required this.riderId,
    required this.mode,
    required this.justification,
    required this.recommendedOrder,
    required this.pullContributionRatio,
    required this.targetPowerWatts,
    required this.targetSpeedFactor,
    required this.bluffIntensity,
    required this.lookBackFrequencyHz,
    required this.expectedRivalReaction,
    required this.rivalFrustrationDelta,
    required this.wPrimeSavedWatts,
    required this.cooperationPenalty,
    this.radioAlertMessage,
    required this.tacticalMotive,
  });

  bool get isRefusingPulls =>
      mode == WheelsuckingTacticMode.skipPullsSitOn ||
      mode == WheelsuckingTacticMode.bluffingPainFace ||
      mode == WheelsuckingTacticMode.finalKmStandoff;

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'mode': mode.toJson(),
      'justification': justification.toJson(),
      'recommendedOrder': recommendedOrder.toJson(),
      'pullContributionRatio': pullContributionRatio,
      'targetPowerWatts': targetPowerWatts,
      'targetSpeedFactor': targetSpeedFactor,
      'bluffIntensity': bluffIntensity,
      'lookBackFrequencyHz': lookBackFrequencyHz,
      'expectedRivalReaction': expectedRivalReaction.toJson(),
      'rivalFrustrationDelta': rivalFrustrationDelta,
      'wPrimeSavedWatts': wPrimeSavedWatts,
      'cooperationPenalty': cooperationPenalty,
      'radioAlertMessage': radioAlertMessage,
      'tacticalMotive': tacticalMotive,
    };
  }

  factory WheelsuckingAiDecision.fromJson(Map<String, dynamic> json) {
    return WheelsuckingAiDecision(
      riderId: json['riderId'] as String,
      mode: WheelsuckingTacticMode.fromJson(json['mode'] as String),
      justification:
          SitOnJustification.fromJson(json['justification'] as String),
      recommendedOrder:
          TacticalOrder.fromJson(json['recommendedOrder'] as String),
      pullContributionRatio: (json['pullContributionRatio'] as num).toDouble(),
      targetPowerWatts: (json['targetPowerWatts'] as num).toInt(),
      targetSpeedFactor: (json['targetSpeedFactor'] as num).toDouble(),
      bluffIntensity: (json['bluffIntensity'] as num).toDouble(),
      lookBackFrequencyHz: (json['lookBackFrequencyHz'] as num).toDouble(),
      expectedRivalReaction:
          RivalReactionType.fromJson(json['expectedRivalReaction'] as String),
      rivalFrustrationDelta: (json['rivalFrustrationDelta'] as num).toDouble(),
      wPrimeSavedWatts: (json['wPrimeSavedWatts'] as num).toDouble(),
      cooperationPenalty: (json['cooperationPenalty'] as num).toDouble(),
      radioAlertMessage: json['radioAlertMessage'] as String?,
      tacticalMotive: json['tacticalMotive'] as String,
    );
  }
}

/// Stan gry nerwów na ostatnim kilometrze ("Cat & Mouse" / oglądanie się za siebie).
class FinalKmStandoffResult {
  /// Czy grupa weszła w tryb taktycznego wyczekiwania i oglądania się za siebie.
  final bool isStandoffActive;

  /// Mnożnik prędkości grupy wynikający ze zwolnienia i gry nerwów [0.76 - 1.0].
  final double groupSlowdownFactor;

  /// Częstotliwość oglądania się liderów grupy za siebie [Hz].
  final double lookBackFrequencyHz;

  /// Prawdopodobieństwo, że rywal pęknie i zaatakuje przedwcześnie [0.0 - 1.0].
  final double rivalCrackProbability;

  /// Dystans od mety [m], na którym kolarz AI planuje wyjść z koła do kontrataku.
  final double ambushLaunchMeters;

  /// Czy w tej chwili należy odpalić finiszowy atak zza pleców rywali.
  final bool shouldLaunchAmbushNow;

  const FinalKmStandoffResult({
    required this.isStandoffActive,
    required this.groupSlowdownFactor,
    required this.lookBackFrequencyHz,
    required this.rivalCrackProbability,
    required this.ambushLaunchMeters,
    required this.shouldLaunchAmbushNow,
  });
}

/// Zbiorcza ocena całej grupy ucieczkowej pod kątem pasywnej jazdy i reakcji rywali.
class WheelsuckingGroupEvaluation {
  final Map<String, WheelsuckingAiDecision> decisionsByRiderId;
  final int wheelsuckerCount;
  final double averagePullContribution;
  final double paceSurgeIntensity;
  final double groupCooperationMultiplier;
  final bool paceSurgesTriggered;
  final FinalKmStandoffResult finalKmStandoff;

  const WheelsuckingGroupEvaluation({
    required this.decisionsByRiderId,
    required this.wheelsuckerCount,
    required this.averagePullContribution,
    required this.paceSurgeIntensity,
    required this.groupCooperationMultiplier,
    required this.paceSurgesTriggered,
    required this.finalKmStandoff,
  });
}

/// Silnik AI taktyki pasywnej jazdy na kole (`Skip Pulls / Sit On`),
/// blefowania zmęczenia (`Poker Face`) oraz gry nerwów na ostatnim kilometrze.
class WheelsuckingAndBluffingAiLogic {
  WheelsuckingAndBluffingAiLogic._();

  /// Próg odległości do mety uruchamiający grę nerwów ostatniego kilometra [km].
  static const double finalKmStandoffThresholdKm = 1.25;

  /// Próg oszczędności aerodynamicznej przy jeździe na drugim/trzecim kole.
  static const double baseSitOnDraftSavingsRatio = 0.28;

  /// Ocenia decyzję pojedynczego kolarza AI w ucieczce.
  static WheelsuckingAiDecision evaluateRiderDecision(
    WheelsuckingAiInput input,
  ) {
    final double wPrimeRatio = input.riderWPrimeRatio.clamp(0.0, 1.0);
    final double fatigueRatio = input.riderFatigueRatio.clamp(0.0, 1.0);
    final double frustration = input.rivalFrustrationIndex.clamp(0.0, 1.0);
    final double safeBaseWatts = math.max(90.0, input.basePullPowerWatts);
    final int groupSize = math.max(1, input.breakawaySize);

    // Jeśli kolarz jedzie sam w ucieczce (solo), nie ma komu siedzieć na kole.
    if (groupSize <= 1 || input.rivalsInBreakawayCount <= 0) {
      return WheelsuckingAiDecision(
        riderId: input.riderId,
        mode: WheelsuckingTacticMode.cooperative,
        justification: SitOnJustification.none,
        recommendedOrder: TacticalOrder.pullGroup,
        pullContributionRatio: 1.0,
        targetPowerWatts: safeBaseWatts.round(),
        targetSpeedFactor: 1.0,
        bluffIntensity: 0.0,
        lookBackFrequencyHz: 0.0,
        expectedRivalReaction: RivalReactionType.steadyPull,
        rivalFrustrationDelta: 0.0,
        wPrimeSavedWatts: 0.0,
        cooperationPenalty: 0.0,
        tacticalMotive: 'Samotna jazda na czele — brak rywali do gry na kole.',
      );
    }

    // 1. Sprawdzenie gry nerwów na ostatnim kilometrze (<= 1.25 km do mety)
    final double distanceMeters = math.max(0.0, input.distanceToFinishKm * 1000.0);
    if (distanceMeters <= finalKmStandoffThresholdKm * 1000.0) {
      final FinalKmStandoffResult standoff = evaluateFinalKmStandoff(
        distanceToFinishMeters: distanceMeters,
        wPrimeRatio: wPrimeRatio,
        fatigueRatio: fatigueRatio,
        rivalFrustrationIndex: frustration,
        sprintRating: input.riderSprintRating,
        isUphillFinish: input.isUphillFinish,
        hasProtectedAssetBehind: input.hasProtectedAssetInPelotonBehind,
        randomSeed: input.randomSeed,
      );

      if (standoff.shouldLaunchAmbushNow) {
        final int attackWatts = (safeBaseWatts * 1.65).round();
        return WheelsuckingAiDecision(
          riderId: input.riderId,
          mode: WheelsuckingTacticMode.counterAttackAmbush,
          justification: SitOnJustification.finalKmTrackStandoff,
          recommendedOrder: TacticalOrder.attack,
          pullContributionRatio: 0.0,
          targetPowerWatts: attackWatts,
          targetSpeedFactor: 1.18,
          bluffIntensity: 0.0,
          lookBackFrequencyHz: 0.2,
          expectedRivalReaction: RivalReactionType.furiousAttack,
          rivalFrustrationDelta: 0.15,
          wPrimeSavedWatts: 0.0,
          cooperationPenalty: 0.30,
          radioAlertMessage:
              'Kontratak zza koła na ${distanceMeters.round()} m przed metą!',
          tacticalMotive:
              'Wykorzystanie zawahania rywali na ostatnim kilometrze i nagły wyskok.',
        );
      }

      final int standoffWatts =
          (safeBaseWatts * (1.0 - baseSitOnDraftSavingsRatio) * 0.90).round();
      return WheelsuckingAiDecision(
        riderId: input.riderId,
        mode: WheelsuckingTacticMode.finalKmStandoff,
        justification: SitOnJustification.finalKmTrackStandoff,
        recommendedOrder: TacticalOrder.followWheels,
        pullContributionRatio: 0.0,
        targetPowerWatts: standoffWatts,
        targetSpeedFactor: standoff.groupSlowdownFactor,
        bluffIntensity: 0.45,
        lookBackFrequencyHz: standoff.lookBackFrequencyHz,
        expectedRivalReaction: RivalReactionType.lookBackSlowdown,
        rivalFrustrationDelta: 0.18,
        wPrimeSavedWatts: safeBaseWatts * baseSitOnDraftSavingsRatio,
        cooperationPenalty: 0.40,
        radioAlertMessage:
            'Gra nerwów pod Flamme Rouge — kolarze oglądają się za siebie.',
        tacticalMotive:
            'Ostatni kilometr: odmowa wyjścia na wiatr, zmuszanie rywali do otwarcia sprintu.',
      );
    }

    // 2. Ocena uzasadnienia odmowy dawania zmian (Skip Pulls / Sit On)
    final SitOnJustification justification = _resolveSitOnJustification(input);
    if (justification == SitOnJustification.none) {
      return WheelsuckingAiDecision(
        riderId: input.riderId,
        mode: WheelsuckingTacticMode.cooperative,
        justification: SitOnJustification.none,
        recommendedOrder: TacticalOrder.pullGroup,
        pullContributionRatio: 1.0,
        targetPowerWatts: safeBaseWatts.round(),
        targetSpeedFactor: 1.0,
        bluffIntensity: 0.0,
        lookBackFrequencyHz: 0.0,
        expectedRivalReaction: RivalReactionType.steadyPull,
        rivalFrustrationDelta: 0.0,
        wPrimeSavedWatts: 0.0,
        cooperationPenalty: 0.0,
        tacticalMotive: 'Brak interesu z tyłu — równa współpraca w odjeździe.',
      );
    }

    // 3. Wybór między jawnym "Skip Pulls / Sit On" a blefowaniem zmęczenia ("Poker Face")
    final bool canBluffPokerFace = wPrimeRatio >= 0.48 &&
        fatigueRatio <= 0.62 &&
        (input.archetype == TacticalAiArchetype.wheelsuckerOpportunist ||
            input.riderSprintRating >= 72 ||
            input.secondsSinceLastPull >= 45.0);

    final WheelsuckingTacticMode selectedMode = canBluffPokerFace
        ? WheelsuckingTacticMode.bluffingPainFace
        : WheelsuckingTacticMode.skipPullsSitOn;

    final double draftSavings = _computeDraftSavingsFactor(
      gradientPercent: input.currentGradientPercent,
    );
    final int sitOnWatts =
        math.max(65, (safeBaseWatts * (1.0 - draftSavings)).round());
    final double savedWatts = safeBaseWatts * draftSavings;

    final double bluffIntensity = selectedMode ==
            WheelsuckingTacticMode.bluffingPainFace
        ? (0.55 + (wPrimeRatio * 0.35)).clamp(0.0, 1.0)
        : 0.15;

    final RivalReactionType reaction = _predictRivalReaction(
      input: input,
      frustration: frustration,
    );

    final double frustrationDelta = _computeFrustrationDelta(
      justification: justification,
      reaction: reaction,
      teammatesCount: input.teammatesInBreakawayCount,
    );

    final double cooperationPenalty = justification ==
                SitOnJustification.sprinterInPelotonBehind ||
            justification == SitOnJustification.gcLeaderInPelotonBehind
        ? 0.35
        : 0.25;

    final String motive = _buildMotiveDescription(
      justification: justification,
      mode: selectedMode,
    );

    final String? radioAlert = _buildRadioAlert(
      justification: justification,
      reaction: reaction,
    );

    return WheelsuckingAiDecision(
      riderId: input.riderId,
      mode: selectedMode,
      justification: justification,
      recommendedOrder: TacticalOrder.saveEnergy,
      pullContributionRatio: 0.0,
      targetPowerWatts: sitOnWatts,
      targetSpeedFactor:
          reaction == RivalReactionType.frustratedPaceSurge ? 1.04 : 0.98,
      bluffIntensity: bluffIntensity,
      lookBackFrequencyHz:
          input.distanceToFinishKm <= 3.0 ? 0.35 : 0.10,
      expectedRivalReaction: reaction,
      rivalFrustrationDelta: frustrationDelta,
      wPrimeSavedWatts: savedWatts,
      cooperationPenalty: cooperationPenalty,
      radioAlertMessage: radioAlert,
      tacticalMotive: motive,
    );
  }

  /// Ocenia grę nerwów na ostatnim kilometrze (oglądanie się za siebie i zwalnianie).
  static FinalKmStandoffResult evaluateFinalKmStandoff({
    required double distanceToFinishMeters,
    required double wPrimeRatio,
    required double fatigueRatio,
    required double rivalFrustrationIndex,
    required int sprintRating,
    required bool isUphillFinish,
    required bool hasProtectedAssetBehind,
    int randomSeed = 42,
  }) {
    final double clampedDist = distanceToFinishMeters.clamp(0.0, 1500.0);
    if (clampedDist > finalKmStandoffThresholdKm * 1000.0) {
      return const FinalKmStandoffResult(
        isStandoffActive: false,
        groupSlowdownFactor: 1.0,
        lookBackFrequencyHz: 0.0,
        rivalCrackProbability: 0.0,
        ambushLaunchMeters: 260.0,
        shouldLaunchAmbushNow: false,
      );
    }

    final math.Random rng = math.Random(randomSeed ^ clampedDist.round());
    final double sprintBias = (sprintRating / 100.0).clamp(0.2, 1.0);
    final double ambushLaunchMeters = isUphillFinish
        ? (170.0 + sprintBias * 60.0)
        : (230.0 + sprintBias * 90.0);

    final bool hasEnergyForAmbush =
        wPrimeRatio.clamp(0.0, 1.0) >= 0.28 && fatigueRatio <= 0.85;
    final bool shouldLaunchNow =
        clampedDist <= ambushLaunchMeters && hasEnergyForAmbush;

    // Im bliżej 300-800 m przed metą, tym częstsze oglądanie się za siebie i większe zwolnienie.
    final double proximityFactor =
        (1.0 - ((clampedDist - 250.0).clamp(0.0, 1000.0) / 1000.0))
            .clamp(0.0, 1.0);
    final double frustrationFactor = rivalFrustrationIndex.clamp(0.0, 1.0);

    final double slowdown = hasProtectedAssetBehind
        ? (0.86 - proximityFactor * 0.08).clamp(0.76, 0.94)
        : (0.92 - proximityFactor * 0.08 - frustrationFactor * 0.04)
            .clamp(0.78, 0.96);

    final double lookBackHz =
        (0.35 + proximityFactor * 0.85 + frustrationFactor * 0.25)
            .clamp(0.2, 1.5);

    final double jitter = (rng.nextDouble() - 0.5) * 0.08;
    final double crackProb =
        (0.25 + frustrationFactor * 0.45 + proximityFactor * 0.25 + jitter)
            .clamp(0.05, 0.95);

    return FinalKmStandoffResult(
      isStandoffActive: !shouldLaunchNow,
      groupSlowdownFactor: shouldLaunchNow ? 1.15 : slowdown,
      lookBackFrequencyHz: lookBackHz,
      rivalCrackProbability: crackProb,
      ambushLaunchMeters: ambushLaunchMeters,
      shouldLaunchAmbushNow: shouldLaunchNow,
    );
  }

  /// Ocenia całą grupę ucieczkową jednocześnie, wyliczając reakcję rywali
  /// i szarpnięcia tempa wywołane przez kolarzy odmawiających zmian.
  static WheelsuckingGroupEvaluation evaluateGroup(
    List<WheelsuckingAiInput> groupInputs,
  ) {
    if (groupInputs.isEmpty) {
      return const WheelsuckingGroupEvaluation(
        decisionsByRiderId: {},
        wheelsuckerCount: 0,
        averagePullContribution: 1.0,
        paceSurgeIntensity: 0.0,
        groupCooperationMultiplier: 1.0,
        paceSurgesTriggered: false,
        finalKmStandoff: FinalKmStandoffResult(
          isStandoffActive: false,
          groupSlowdownFactor: 1.0,
          lookBackFrequencyHz: 0.0,
          rivalCrackProbability: 0.0,
          ambushLaunchMeters: 260.0,
          shouldLaunchAmbushNow: false,
        ),
      );
    }

    final Map<String, WheelsuckingAiDecision> decisions = {};
    int wheelsuckers = 0;
    double pullSum = 0.0;
    double penaltySum = 0.0;
    bool surgeTriggered = false;

    for (final input in groupInputs) {
      final decision = evaluateRiderDecision(input);
      decisions[input.riderId] = decision;
      pullSum += decision.pullContributionRatio;
      penaltySum += decision.cooperationPenalty;
      if (decision.isRefusingPulls) {
        wheelsuckers++;
      }
      if (decision.expectedRivalReaction ==
              RivalReactionType.frustratedPaceSurge ||
          decision.expectedRivalReaction == RivalReactionType.furiousAttack) {
        surgeTriggered = true;
      }
    }

    final int count = groupInputs.length;
    final double avgPull = (pullSum / count).clamp(0.0, 1.0);
    final double cooperationMultiplier =
        (1.0 - (penaltySum / count)).clamp(0.45, 1.0);
    final double surgeIntensity = surgeTriggered
        ? (0.12 + (wheelsuckers / count) * 0.25).clamp(0.0, 0.35)
        : 0.0;

    final WheelsuckingAiInput leaderSample = groupInputs.first;
    final FinalKmStandoffResult standoff = evaluateFinalKmStandoff(
      distanceToFinishMeters: leaderSample.distanceToFinishKm * 1000.0,
      wPrimeRatio: leaderSample.riderWPrimeRatio,
      fatigueRatio: leaderSample.riderFatigueRatio,
      rivalFrustrationIndex: leaderSample.rivalFrustrationIndex,
      sprintRating: leaderSample.riderSprintRating,
      isUphillFinish: leaderSample.isUphillFinish,
      hasProtectedAssetBehind: leaderSample.hasProtectedAssetInPelotonBehind,
      randomSeed: leaderSample.randomSeed,
    );

    return WheelsuckingGroupEvaluation(
      decisionsByRiderId: decisions,
      wheelsuckerCount: wheelsuckers,
      averagePullContribution: avgPull,
      paceSurgeIntensity: surgeIntensity,
      groupCooperationMultiplier: cooperationMultiplier,
      paceSurgesTriggered: surgeTriggered,
      finalKmStandoff: standoff,
    );
  }

  static SitOnJustification _resolveSitOnJustification(
    WheelsuckingAiInput input,
  ) {
    // Priorytet 1: W peletonie z tyłu jedzie sprinter drużyny (na płaskim/pagórkach)
    if (input.hasTeamSprinterInPelotonBehind &&
        input.pelotonGapSeconds <= 360.0 &&
        !input.isUphillFinish) {
      return SitOnJustification.sprinterInPelotonBehind;
    }

    // Priorytet 2: W peletonie z tyłu jedzie lider GC drużyny
    if (input.hasTeamLeaderInPelotonBehind && input.pelotonGapSeconds <= 420.0) {
      return SitOnJustification.gcLeaderInPelotonBehind;
    }

    // Priorytet 3: Przewaga liczebna jednej drużyny rywali w tej samej ucieczce
    if (input.maxRivalTeamSizeInBreakaway >=
        input.teammatesInBreakawayCount + 1) {
      return SitOnJustification.rivalTeammateOverload;
    }

    // Priorytet 4: Osobowość Pasożyta-Oportunisty lub szybki sprinter w końcówce
    final bool isOpportunist =
        input.archetype == TacticalAiArchetype.wheelsuckerOpportunist;
    final bool isLateSprintThreat = input.distanceToFinishKm <= 12.0 &&
        (input.specialization == RiderSpecialization.pureSprinter ||
            input.specialization == RiderSpecialization.versatileSprinter ||
            input.riderSprintRating >= 78);

    if (isOpportunist || isLateSprintThreat) {
      return SitOnJustification.opportunistConservation;
    }

    return SitOnJustification.none;
  }

  static double _computeDraftSavingsFactor({
    required double gradientPercent,
  }) {
    // Na stromym podjeździe tunel aerodynamiczny daje mniejszy zysk niż na płaskim.
    if (gradientPercent >= 7.0) {
      return 0.12;
    }
    if (gradientPercent >= 3.5) {
      return 0.20;
    }
    return baseSitOnDraftSavingsRatio;
  }

  static RivalReactionType _predictRivalReaction({
    required WheelsuckingAiInput input,
    required double frustration,
  }) {
    if (input.distanceToFinishKm <= finalKmStandoffThresholdKm) {
      return RivalReactionType.lookBackSlowdown;
    }
    if (frustration >= 0.78) {
      return input.rivalsInBreakawayCount >= 2
          ? RivalReactionType.furiousAttack
          : RivalReactionType.breakawayCollapse;
    }
    if (frustration >= 0.40 || input.secondsSinceLastPull >= 60.0) {
      return RivalReactionType.frustratedPaceSurge;
    }
    return RivalReactionType.steadyPull;
  }

  static double _computeFrustrationDelta({
    required SitOnJustification justification,
    required RivalReactionType reaction,
    required int teammatesCount,
  }) {
    double base = 0.08;
    if (justification == SitOnJustification.sprinterInPelotonBehind ||
        justification == SitOnJustification.gcLeaderInPelotonBehind) {
      base = 0.14;
    }
    if (teammatesCount > 1) {
      base += 0.04;
    }
    if (reaction == RivalReactionType.furiousAttack) {
      base += 0.06;
    }
    return base.clamp(0.0, 0.35);
  }

  static String _buildMotiveDescription({
    required SitOnJustification justification,
    required WheelsuckingTacticMode mode,
  }) {
    final String prefix = mode == WheelsuckingTacticMode.bluffingPainFace
        ? 'Blef zmęczenia (Poker Face): '
        : 'Skip Pulls / Sit On: ';

    switch (justification) {
      case SitOnJustification.sprinterInPelotonBehind:
        return '${prefix}odmowa zmian — sprinter drużyny jedzie w peletonie z tyłu.';
      case SitOnJustification.gcLeaderInPelotonBehind:
        return '${prefix}odmowa zmian — lider drużyny goni z peletonu.';
      case SitOnJustification.rivalTeammateOverload:
        return '${prefix}rywale mają przewagę liczebną i muszą sami pracować.';
      case SitOnJustification.opportunistConservation:
        return '${prefix}oszczędzanie W\' na kole przed finałowym rozstrzygnięciem.';
      case SitOnJustification.finalKmTrackStandoff:
        return 'Ostatni kilometr: gra nerwów i oglądanie się za siebie.';
      case SitOnJustification.none:
        return 'Równa współpraca w ucieczce.';
    }
  }

  static String? _buildRadioAlert({
    required SitOnJustification justification,
    required RivalReactionType reaction,
  }) {
    if (justification == SitOnJustification.sprinterInPelotonBehind) {
      return 'Taktyka "Sit On": kolarz odmawia zmian, bo z tyłu czeka jego sprinter!';
    }
    if (justification == SitOnJustification.gcLeaderInPelotonBehind) {
      return 'Taktyka "Skip Pulls": lider w peletonie, pomocnik w ucieczce nie daje zmian.';
    }
    if (reaction == RivalReactionType.frustratedPaceSurge) {
      return 'Rywale tracą cierpliwość i szarpią tempo przez jazdę na kole!';
    }
    if (reaction == RivalReactionType.furiousAttack) {
      return 'Złość w ucieczce! Rywal atakuje, próbując zgubić pasażera na gapę.';
    }
    return null;
  }
}
