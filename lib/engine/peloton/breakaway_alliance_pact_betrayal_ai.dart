import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';

/// Faza cyklu życia dynamicznego mikro-paktu w ucieczce dnia.
enum BreakawayPactPhase {
  /// Powyżej 15 km przed metą — okno negocjacji jeszcze się nie otworzyło.
  prePactWindow,

  /// Około 15 km przed metą — dwaj najsilniejsi uciekinierzy analizują reputację.
  negotiating,

  /// Aktywny pakt: „Współpracujemy do 1 km przed metą, żeby peleton nas nie złapał”.
  activePact,

  /// Pakt dotrzymany do 1 km przed metą — otwarta walka na finiszu.
  pactHonoredEndgame,

  /// Jeden z partnerów złamał pakt przed linią 1 km.
  betrayed,

  /// Pakt odrzucony z powodu braku zaufania lub braku zagrożenia ze strony peletonu.
  rejected;

  String toJson() => name;

  static BreakawayPactPhase fromJson(String value) {
    return BreakawayPactPhase.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => BreakawayPactPhase.prePactWindow,
    );
  }

  String get label {
    switch (this) {
      case BreakawayPactPhase.prePactWindow:
        return 'Przed oknem paktu (>15 km)';
      case BreakawayPactPhase.negotiating:
        return 'Negocjacje na 15 km przed metą';
      case BreakawayPactPhase.activePact:
        return 'Aktywny pakt (do 1 km)';
      case BreakawayPactPhase.pactHonoredEndgame:
        return 'Pakt dotrzymany (finałowy 1 km)';
      case BreakawayPactPhase.betrayed:
        return 'Zdrada paktu!';
      case BreakawayPactPhase.rejected:
        return 'Pakt odrzucony';
    }
  }
}

/// Klasa reputacji kolarza w peletonie pod kątem dotrzymywania umów.
enum PartnerReputationTier {
  gentleman,
  reliable,
  opportunist,
  notoriousBetrayer;

  String toJson() => name;

  static PartnerReputationTier fromJson(String value) {
    return PartnerReputationTier.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => PartnerReputationTier.reliable,
    );
  }

  String get label {
    switch (this) {
      case PartnerReputationTier.gentleman:
        return 'Dżentelmen szosy';
      case PartnerReputationTier.reliable:
        return 'Solidny partner';
      case PartnerReputationTier.opportunist:
        return 'Oportunista';
      case PartnerReputationTier.notoriousBetrayer:
        return 'Notoryczny zdrajca';
    }
  }

  Color get badgeColor {
    switch (this) {
      case PartnerReputationTier.gentleman:
        return AppColors.statusSuccess;
      case PartnerReputationTier.reliable:
        return AppColors.accentBlue;
      case PartnerReputationTier.opportunist:
        return AppColors.amberWarning;
      case PartnerReputationTier.notoriousBetrayer:
        return AppColors.crimsonAlert;
    }
  }
}

/// Powód zerwania lub zdrady paktu przed 1 km do mety.
enum BetrayalTriggerReason {
  none,
  pelotonSafeMargin,
  opportunisticAmbush,
  exhaustionCollapse,
  steepKickerAttack;

  String toJson() => name;

  static BetrayalTriggerReason fromJson(String value) {
    return BetrayalTriggerReason.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => BetrayalTriggerReason.none,
    );
  }

  String get label {
    switch (this) {
      case BetrayalTriggerReason.none:
        return 'Brak zdrady';
      case BetrayalTriggerReason.pelotonSafeMargin:
        return 'Bezpieczna przewaga — partner atakuje wcześniej';
      case BetrayalTriggerReason.opportunisticAmbush:
        return 'Zasadzka oportunisty przed 1 km';
      case BetrayalTriggerReason.exhaustionCollapse:
        return 'Wyczerpanie partnera — brak sił na zmiany';
      case BetrayalTriggerReason.steepKickerAttack:
        return 'Skok na stromej ściance przed finałem';
    }
  }
}

/// Decyzja dotycząca propozycji zawarcia mikro-paktu.
enum PactProposalDecision {
  accepted,
  acceptedWithCaution,
  rejectedLowTrust,
  rejectedNoThreat;

  String toJson() => name;

  static PactProposalDecision fromJson(String value) {
    return PactProposalDecision.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => PactProposalDecision.accepted,
    );
  }

  String get label {
    switch (this) {
      case PactProposalDecision.accepted:
        return 'Pakt zawarty bez zastrzeżeń';
      case PactProposalDecision.acceptedWithCaution:
        return 'Pakt zawarty z rezerwą';
      case PactProposalDecision.rejectedLowTrust:
        return 'Odrzucono — zbyt niska wiarygodność';
      case PactProposalDecision.rejectedNoThreat:
        return 'Odrzucono — peleton nie zagraża';
    }
  }
}

/// Kandydat do mikro-paktu spośród kolarzy jadących w ucieczce dnia.
class BreakawayPactCandidate {
  final String riderId;
  final String riderName;
  final String teamName;

  /// Złożony indeks aktualnej siły w ucieczce (0.0 - 100.0).
  final double powerScore;

  /// Pozostała rezerwa beztlenowa W' (0.0 - 1.0).
  final double remainingWPrimeRatio;

  /// Umiejętność sprintu na finiszu (0 - 100).
  final int sprintRating;

  /// Dotychczasowa reputacja w peletonie (0.0 = zdrajca, 1.0 = pełne zaufanie).
  final double reputationScore;

  /// Liczba dotrzymanych paktów w historii kariery/sezonu.
  final int pastPactsHonored;

  /// Liczba złamanych paktów w historii kariery/sezonu.
  final int pastPactsBetrayed;

  /// Dotychczasowy udział w dawaniu zmian w bieżącej ucieczce (0.0 - 1.0).
  final double pullContributionRatio;

  const BreakawayPactCandidate({
    required this.riderId,
    required this.riderName,
    required this.teamName,
    required this.powerScore,
    required this.remainingWPrimeRatio,
    required this.sprintRating,
    required this.reputationScore,
    this.pastPactsHonored = 0,
    this.pastPactsBetrayed = 0,
    this.pullContributionRatio = 0.5,
  });

  PartnerReputationTier get reputationTier {
    if (reputationScore >= 0.80) return PartnerReputationTier.gentleman;
    if (reputationScore >= 0.60) return PartnerReputationTier.reliable;
    if (reputationScore >= 0.35) return PartnerReputationTier.opportunist;
    return PartnerReputationTier.notoriousBetrayer;
  }

  BreakawayPactCandidate copyWith({
    String? riderId,
    String? riderName,
    String? teamName,
    double? powerScore,
    double? remainingWPrimeRatio,
    int? sprintRating,
    double? reputationScore,
    int? pastPactsHonored,
    int? pastPactsBetrayed,
    double? pullContributionRatio,
  }) {
    return BreakawayPactCandidate(
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      teamName: teamName ?? this.teamName,
      powerScore: powerScore ?? this.powerScore,
      remainingWPrimeRatio: remainingWPrimeRatio ?? this.remainingWPrimeRatio,
      sprintRating: sprintRating ?? this.sprintRating,
      reputationScore: reputationScore ?? this.reputationScore,
      pastPactsHonored: pastPactsHonored ?? this.pastPactsHonored,
      pastPactsBetrayed: pastPactsBetrayed ?? this.pastPactsBetrayed,
      pullContributionRatio:
          pullContributionRatio ?? this.pullContributionRatio,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'riderName': riderName,
      'teamName': teamName,
      'powerScore': powerScore,
      'remainingWPrimeRatio': remainingWPrimeRatio,
      'sprintRating': sprintRating,
      'reputationScore': reputationScore,
      'pastPactsHonored': pastPactsHonored,
      'pastPactsBetrayed': pastPactsBetrayed,
      'pullContributionRatio': pullContributionRatio,
    };
  }

  factory BreakawayPactCandidate.fromJson(Map<String, dynamic> json) {
    return BreakawayPactCandidate(
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      teamName: json['teamName'] as String? ?? 'Pro Team',
      powerScore: (json['powerScore'] as num).toDouble(),
      remainingWPrimeRatio:
          (json['remainingWPrimeRatio'] as num?)?.toDouble() ?? 0.5,
      sprintRating: (json['sprintRating'] as num?)?.toInt() ?? 65,
      reputationScore: (json['reputationScore'] as num?)?.toDouble() ?? 0.65,
      pastPactsHonored: (json['pastPactsHonored'] as num?)?.toInt() ?? 0,
      pastPactsBetrayed: (json['pastPactsBetrayed'] as num?)?.toInt() ?? 0,
      pullContributionRatio:
          (json['pullContributionRatio'] as num?)?.toDouble() ?? 0.5,
    );
  }
}

/// Wynik analizy wiarygodności potencjalnego partnera do mikro-paktu.
class PartnerTrustAnalysis {
  final String partnerId;
  final String partnerName;
  final double trustScore;
  final PartnerReputationTier reputationTier;
  final double betrayalProbability;
  final double expectedCooperationBonusKmh;
  final PactProposalDecision decision;
  final String rationale;

  const PartnerTrustAnalysis({
    required this.partnerId,
    required this.partnerName,
    required this.trustScore,
    required this.reputationTier,
    required this.betrayalProbability,
    required this.expectedCooperationBonusKmh,
    required this.decision,
    required this.rationale,
  });

  bool get isAccepted =>
      decision == PactProposalDecision.accepted ||
      decision == PactProposalDecision.acceptedWithCaution;

  Map<String, dynamic> toJson() {
    return {
      'partnerId': partnerId,
      'partnerName': partnerName,
      'trustScore': trustScore,
      'reputationTier': reputationTier.toJson(),
      'betrayalProbability': betrayalProbability,
      'expectedCooperationBonusKmh': expectedCooperationBonusKmh,
      'decision': decision.toJson(),
      'rationale': rationale,
    };
  }

  factory PartnerTrustAnalysis.fromJson(Map<String, dynamic> json) {
    return PartnerTrustAnalysis(
      partnerId: json['partnerId'] as String,
      partnerName: json['partnerName'] as String,
      trustScore: (json['trustScore'] as num).toDouble(),
      reputationTier: PartnerReputationTier.fromJson(
        json['reputationTier'] as String,
      ),
      betrayalProbability: (json['betrayalProbability'] as num).toDouble(),
      expectedCooperationBonusKmh:
          (json['expectedCooperationBonusKmh'] as num).toDouble(),
      decision: PactProposalDecision.fromJson(json['decision'] as String),
      rationale: json['rationale'] as String? ?? '',
    );
  }
}

/// Aktywny lub zakończony mikro-pakt zawarty między dwoma najsilniejszymi uciekinierami.
class BreakawayMicroPact {
  final String pactId;
  final String initiatorId;
  final String initiatorName;
  final String partnerId;
  final String partnerName;
  final String agreementText;
  final double formedAtDistanceToFinishKm;
  final double dissolveAtDistanceToFinishKm;
  final BreakawayPactPhase phase;
  final PartnerTrustAnalysis trustAnalysis;
  final double cooperationSpeedBonusKmh;
  final String? betrayerId;
  final BetrayalTriggerReason betrayalReason;
  final double? betrayalDistanceKm;
  final String radioCommunique;

  const BreakawayMicroPact({
    required this.pactId,
    required this.initiatorId,
    required this.initiatorName,
    required this.partnerId,
    required this.partnerName,
    required this.agreementText,
    required this.formedAtDistanceToFinishKm,
    this.dissolveAtDistanceToFinishKm = 1.0,
    required this.phase,
    required this.trustAnalysis,
    required this.cooperationSpeedBonusKmh,
    this.betrayerId,
    this.betrayalReason = BetrayalTriggerReason.none,
    this.betrayalDistanceKm,
    required this.radioCommunique,
  });

  BreakawayMicroPact copyWith({
    String? pactId,
    String? initiatorId,
    String? initiatorName,
    String? partnerId,
    String? partnerName,
    String? agreementText,
    double? formedAtDistanceToFinishKm,
    double? dissolveAtDistanceToFinishKm,
    BreakawayPactPhase? phase,
    PartnerTrustAnalysis? trustAnalysis,
    double? cooperationSpeedBonusKmh,
    String? betrayerId,
    BetrayalTriggerReason? betrayalReason,
    double? betrayalDistanceKm,
    String? radioCommunique,
  }) {
    return BreakawayMicroPact(
      pactId: pactId ?? this.pactId,
      initiatorId: initiatorId ?? this.initiatorId,
      initiatorName: initiatorName ?? this.initiatorName,
      partnerId: partnerId ?? this.partnerId,
      partnerName: partnerName ?? this.partnerName,
      agreementText: agreementText ?? this.agreementText,
      formedAtDistanceToFinishKm:
          formedAtDistanceToFinishKm ?? this.formedAtDistanceToFinishKm,
      dissolveAtDistanceToFinishKm:
          dissolveAtDistanceToFinishKm ?? this.dissolveAtDistanceToFinishKm,
      phase: phase ?? this.phase,
      trustAnalysis: trustAnalysis ?? this.trustAnalysis,
      cooperationSpeedBonusKmh:
          cooperationSpeedBonusKmh ?? this.cooperationSpeedBonusKmh,
      betrayerId: betrayerId ?? this.betrayerId,
      betrayalReason: betrayalReason ?? this.betrayalReason,
      betrayalDistanceKm: betrayalDistanceKm ?? this.betrayalDistanceKm,
      radioCommunique: radioCommunique ?? this.radioCommunique,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pactId': pactId,
      'initiatorId': initiatorId,
      'initiatorName': initiatorName,
      'partnerId': partnerId,
      'partnerName': partnerName,
      'agreementText': agreementText,
      'formedAtDistanceToFinishKm': formedAtDistanceToFinishKm,
      'dissolveAtDistanceToFinishKm': dissolveAtDistanceToFinishKm,
      'phase': phase.toJson(),
      'trustAnalysis': trustAnalysis.toJson(),
      'cooperationSpeedBonusKmh': cooperationSpeedBonusKmh,
      'betrayerId': betrayerId,
      'betrayalReason': betrayalReason.toJson(),
      'betrayalDistanceKm': betrayalDistanceKm,
      'radioCommunique': radioCommunique,
    };
  }

  factory BreakawayMicroPact.fromJson(Map<String, dynamic> json) {
    return BreakawayMicroPact(
      pactId: json['pactId'] as String,
      initiatorId: json['initiatorId'] as String,
      initiatorName: json['initiatorName'] as String,
      partnerId: json['partnerId'] as String,
      partnerName: json['partnerName'] as String,
      agreementText: json['agreementText'] as String,
      formedAtDistanceToFinishKm:
          (json['formedAtDistanceToFinishKm'] as num).toDouble(),
      dissolveAtDistanceToFinishKm:
          (json['dissolveAtDistanceToFinishKm'] as num?)?.toDouble() ?? 1.0,
      phase: BreakawayPactPhase.fromJson(json['phase'] as String),
      trustAnalysis: PartnerTrustAnalysis.fromJson(
        json['trustAnalysis'] as Map<String, dynamic>,
      ),
      cooperationSpeedBonusKmh:
          (json['cooperationSpeedBonusKmh'] as num).toDouble(),
      betrayerId: json['betrayerId'] as String?,
      betrayalReason: BetrayalTriggerReason.fromJson(
        json['betrayalReason'] as String? ?? 'none',
      ),
      betrayalDistanceKm: (json['betrayalDistanceKm'] as num?)?.toDouble(),
      radioCommunique: json['radioCommunique'] as String? ?? '',
    );
  }
}

/// Dane wejściowe pojedynczego kroku ewaluacji mikro-paktu w ucieczce.
class BreakawayPactStepInput {
  final double distanceToFinishKm;
  final double pelotonGapSeconds;
  final double pelotonClosingSpeedKmh;
  final double currentGradientPercent;
  final List<BreakawayPactCandidate> candidates;
  final int seed;

  const BreakawayPactStepInput({
    required this.distanceToFinishKm,
    required this.pelotonGapSeconds,
    this.pelotonClosingSpeedKmh = 1.5,
    this.currentGradientPercent = 0.5,
    required this.candidates,
    this.seed = 689,
  });
}

/// Wynik kroku AI mikro-paktów i zdrady w ucieczce dnia.
class BreakawayPactEvaluationResult {
  final BreakawayMicroPact? pact;
  final List<String> activePairIds;
  final double speedBonusKmh;
  final double pelotonCatchRisk;
  final Map<String, double> reputationDeltas;
  final List<String> eventLog;

  const BreakawayPactEvaluationResult({
    required this.pact,
    required this.activePairIds,
    required this.speedBonusKmh,
    required this.pelotonCatchRisk,
    required this.reputationDeltas,
    required this.eventLog,
  });
}

/// Silnik AI dynamicznych mikro-paktów i zdrad w ucieczce dnia.
///
/// Na 15 km przed metą wybiera dwóch najsilniejszych uciekinierów, ocenia
/// wiarygodność partnera na podstawie jego dotychczasowej reputacji w peletonie
/// i zarządza paktem: „Współpracujemy do 1 km przed metą, żeby peleton nas nie złapał”.
class BreakawayAlliancePactBetrayalAi {
  const BreakawayAlliancePactBetrayalAi();

  static const double pactWindowStartKm = 15.0;
  static const double pactWindowEndKm = 1.0;
  static const double minTrustToAccept = 0.38;
  static const double safeGapNoThreatSeconds = 110.0;
  static const String defaultPactPhrase =
      'Współpracujemy do 1 km przed metą, żeby peleton nas nie złapał';

  /// Wybiera dwóch najsilniejszych kolarzy w ucieczce według siły i zapasu W'.
  List<BreakawayPactCandidate> selectTwoStrongestRiders(
    List<BreakawayPactCandidate> candidates,
  ) {
    if (candidates.length < 2) return List<BreakawayPactCandidate>.from(candidates);
    final sorted = List<BreakawayPactCandidate>.from(candidates)
      ..sort((a, b) {
        final powerCmp = b.powerScore.compareTo(a.powerScore);
        if (powerCmp != 0) return powerCmp;
        final wPrimeCmp =
            b.remainingWPrimeRatio.compareTo(a.remainingWPrimeRatio);
        if (wPrimeCmp != 0) return wPrimeCmp;
        return a.riderId.compareTo(b.riderId);
      });
    return sorted.take(2).toList(growable: false);
  }

  /// Analizuje wiarygodność potencjalnego partnera na podstawie reputacji w peletonie.
  PartnerTrustAnalysis analyzePartnerTrust({
    required BreakawayPactCandidate evaluator,
    required BreakawayPactCandidate partner,
    required double pelotonGapSeconds,
    required double distanceToFinishKm,
  }) {
    final totalHistory = partner.pastPactsHonored + partner.pastPactsBetrayed;
    final historyTrust = totalHistory == 0
        ? partner.reputationScore
        : (partner.pastPactsHonored + 1.0) / (totalHistory + 2.0);

    final urgencyBoost = pelotonGapSeconds <= 45.0
        ? 0.10
        : (pelotonGapSeconds <= 75.0 ? 0.04 : -0.05);

    final rawTrust = (partner.reputationScore * 0.55) +
        (historyTrust * 0.25) +
        (partner.pullContributionRatio * 0.20) +
        urgencyBoost;
    final trustScore = rawTrust.clamp(0.0, 1.0);

    final sprintAdvantage =
        ((partner.sprintRating - evaluator.sprintRating) / 100.0)
            .clamp(-0.20, 0.20);
    final rawBetrayalProb = ((1.0 - partner.reputationScore) * 0.65) +
        ((1.0 - partner.pullContributionRatio) * 0.20) +
        (sprintAdvantage < -0.05 ? 0.12 : 0.0) -
        (pelotonGapSeconds < 30.0 ? 0.15 : 0.0);
    final betrayalProbability = rawBetrayalProb.clamp(0.03, 0.95);

    final PactProposalDecision decision;
    final String rationale;
    if (pelotonGapSeconds >= safeGapNoThreatSeconds &&
        distanceToFinishKm <= 15.0) {
      decision = PactProposalDecision.rejectedNoThreat;
      rationale =
          'Przewaga ${pelotonGapSeconds.toStringAsFixed(0)} s daje bezpieczny bufor — '
          '${partner.riderName} woli jechać na własne konto.';
    } else if (trustScore < minTrustToAccept) {
      decision = PactProposalDecision.rejectedLowTrust;
      rationale =
          'Reputacja ${partner.riderName} (${(partner.reputationScore * 100).toStringAsFixed(0)}%, '
          'zdrad: ${partner.pastPactsBetrayed}) jest zbyt niska, by ryzykować pakt.';
    } else if (trustScore < 0.62) {
      decision = PactProposalDecision.acceptedWithCaution;
      rationale =
          '${partner.riderName} ma mieszaną opinię (${partner.reputationTier.label}), '
          'ale presja peletonu wymusza sojusz do 1 km.';
    } else {
      decision = PactProposalDecision.accepted;
      rationale =
          'Wysoka wiarygodność (${(trustScore * 100).toStringAsFixed(0)}%) i solidne zmiany '
          'gwarantują lojalną współpracę do 1 km przed metą.';
    }

    final expectedBonus = decision == PactProposalDecision.accepted
        ? 2.2 + (trustScore * 0.8)
        : (decision == PactProposalDecision.acceptedWithCaution ? 1.6 : 0.0);

    return PartnerTrustAnalysis(
      partnerId: partner.riderId,
      partnerName: partner.riderName,
      trustScore: trustScore,
      reputationTier: partner.reputationTier,
      betrayalProbability: betrayalProbability,
      expectedCooperationBonusKmh: expectedBonus,
      decision: decision,
      rationale: rationale,
    );
  }

  /// Wykonuje krok symulacji mikro-paktu między dwoma najsilniejszymi uciekinierami.
  BreakawayPactEvaluationResult evaluatePactStep(
    BreakawayPactStepInput input, {
    BreakawayMicroPact? existingPact,
  }) {
    final catchRisk = _computeCatchRisk(
      pelotonGapSeconds: input.pelotonGapSeconds,
      distanceToFinishKm: input.distanceToFinishKm,
      closingSpeedKmh: input.pelotonClosingSpeedKmh,
    );

    if (input.candidates.length < 2) {
      return BreakawayPactEvaluationResult(
        pact: existingPact,
        activePairIds: const <String>[],
        speedBonusKmh: 0.0,
        pelotonCatchRisk: catchRisk,
        reputationDeltas: const <String, double>{},
        eventLog: const <String>[
          'Za mało uciekinierów do zawiązania mikro-paktu.',
        ],
      );
    }

    final topTwo = selectTwoStrongestRiders(input.candidates);
    final initiator = topTwo[0];
    final partner = topTwo[1];

    // Przed 15 km do mety nie otwieramy jeszcze okna paktu.
    if (input.distanceToFinishKm > pactWindowStartKm && existingPact == null) {
      return BreakawayPactEvaluationResult(
        pact: null,
        activePairIds: [initiator.riderId, partner.riderId],
        speedBonusKmh: 0.0,
        pelotonCatchRisk: catchRisk,
        reputationDeltas: const <String, double>{},
        eventLog: [
          'Do okna mikro-paktu (15 km) pozostało ${(input.distanceToFinishKm - pactWindowStartKm).toStringAsFixed(1)} km.',
        ],
      );
    }

    // Jeśli pakt już był zdradzony lub odrzucony, utrzymujemy stan końcowy.
    if (existingPact != null &&
        (existingPact.phase == BreakawayPactPhase.betrayed ||
            existingPact.phase == BreakawayPactPhase.rejected ||
            existingPact.phase == BreakawayPactPhase.pactHonoredEndgame)) {
      return BreakawayPactEvaluationResult(
        pact: existingPact,
        activePairIds: [existingPact.initiatorId, existingPact.partnerId],
        speedBonusKmh: 0.0,
        pelotonCatchRisk: catchRisk,
        reputationDeltas: const <String, double>{},
        eventLog: [existingPact.radioCommunique],
      );
    }

    // Inicjalizacja paktu w oknie <= 15 km przed metą.
    if (existingPact == null) {
      final analysis = analyzePartnerTrust(
        evaluator: initiator,
        partner: partner,
        pelotonGapSeconds: input.pelotonGapSeconds,
        distanceToFinishKm: input.distanceToFinishKm,
      );

      if (!analysis.isAccepted) {
        final rejectedPact = BreakawayMicroPact(
          pactId: 'pact_${initiator.riderId}_${partner.riderId}',
          initiatorId: initiator.riderId,
          initiatorName: initiator.riderName,
          partnerId: partner.riderId,
          partnerName: partner.riderName,
          agreementText: defaultPactPhrase,
          formedAtDistanceToFinishKm: input.distanceToFinishKm,
          phase: BreakawayPactPhase.rejected,
          trustAnalysis: analysis,
          cooperationSpeedBonusKmh: 0.0,
          radioCommunique: analysis.rationale,
        );
        return BreakawayPactEvaluationResult(
          pact: rejectedPact,
          activePairIds: [initiator.riderId, partner.riderId],
          speedBonusKmh: 0.0,
          pelotonCatchRisk: catchRisk,
          reputationDeltas: const <String, double>{},
          eventLog: [
            'Na ${input.distanceToFinishKm.toStringAsFixed(1)} km przed metą brak porozumienia: ${analysis.rationale}',
          ],
        );
      }

      final activePact = BreakawayMicroPact(
        pactId: 'pact_${initiator.riderId}_${partner.riderId}',
        initiatorId: initiator.riderId,
        initiatorName: initiator.riderName,
        partnerId: partner.riderId,
        partnerName: partner.riderName,
        agreementText: defaultPactPhrase,
        formedAtDistanceToFinishKm: input.distanceToFinishKm,
        phase: BreakawayPactPhase.activePact,
        trustAnalysis: analysis,
        cooperationSpeedBonusKmh: analysis.expectedCooperationBonusKmh,
        radioCommunique:
            '${initiator.riderName} i ${partner.riderName}: „$defaultPactPhrase”.',
      );

      return BreakawayPactEvaluationResult(
        pact: activePact,
        activePairIds: [initiator.riderId, partner.riderId],
        speedBonusKmh: activePact.cooperationSpeedBonusKmh,
        pelotonCatchRisk: catchRisk,
        reputationDeltas: const <String, double>{},
        eventLog: [
          'Zawarto mikro-pakt (${input.distanceToFinishKm.toStringAsFixed(1)} km do mety): ${activePact.radioCommunique}',
        ],
      );
    }

    // Aktualizacja istniejącego aktywnego paktu.
    if (input.distanceToFinishKm <= pactWindowEndKm) {
      final honoredPact = existingPact.copyWith(
        phase: BreakawayPactPhase.pactHonoredEndgame,
        cooperationSpeedBonusKmh: 0.0,
        radioCommunique:
            'Flamme Rouge (1 km)! ${existingPact.initiatorName} i ${existingPact.partnerName} dotrzymali paktu — otwarta walka o etap!',
      );
      return BreakawayPactEvaluationResult(
        pact: honoredPact,
        activePairIds: [existingPact.initiatorId, existingPact.partnerId],
        speedBonusKmh: 0.0,
        pelotonCatchRisk: catchRisk,
        reputationDeltas: {
          existingPact.initiatorId: 0.06,
          existingPact.partnerId: 0.06,
        },
        eventLog: [honoredPact.radioCommunique],
      );
    }

    // Sprawdzenie warunków zdrady w oknie 15.0 -> 1.0 km.
    final partnerState = input.candidates.firstWhere(
      (c) => c.riderId == existingPact.partnerId,
      orElse: () => partner,
    );
    final initiatorState = input.candidates.firstWhere(
      (c) => c.riderId == existingPact.initiatorId,
      orElse: () => initiator,
    );

    final betrayalCheck = _evaluateBetrayalTrigger(
      input: input,
      pact: existingPact,
      initiator: initiatorState,
      partner: partnerState,
    );

    if (betrayalCheck != null) {
      final betrayedPact = existingPact.copyWith(
        phase: BreakawayPactPhase.betrayed,
        cooperationSpeedBonusKmh: -1.4,
        betrayerId: betrayalCheck.betrayerId,
        betrayalReason: betrayalCheck.reason,
        betrayalDistanceKm: input.distanceToFinishKm,
        radioCommunique:
            'ZDRADA na ${input.distanceToFinishKm.toStringAsFixed(1)} km! ${betrayalCheck.betrayerName} łamie pakt (${betrayalCheck.reason.label}).',
      );
      final loyalId = betrayalCheck.betrayerId == existingPact.partnerId
          ? existingPact.initiatorId
          : existingPact.partnerId;

      return BreakawayPactEvaluationResult(
        pact: betrayedPact,
        activePairIds: [existingPact.initiatorId, existingPact.partnerId],
        speedBonusKmh: -1.4,
        pelotonCatchRisk: (catchRisk + 0.15).clamp(0.0, 1.0),
        reputationDeltas: {
          betrayalCheck.betrayerId: -0.18,
          loyalId: 0.03,
        },
        eventLog: [betrayedPact.radioCommunique],
      );
    }

    // Pakt nadal trwa — równe zmiany i bonus aerodynamiczny.
    return BreakawayPactEvaluationResult(
      pact: existingPact,
      activePairIds: [existingPact.initiatorId, existingPact.partnerId],
      speedBonusKmh: existingPact.cooperationSpeedBonusKmh,
      pelotonCatchRisk: catchRisk,
      reputationDeltas: const <String, double>{},
      eventLog: [
        'Aktywna współpraca (${input.distanceToFinishKm.toStringAsFixed(1)} km do mety): +${existingPact.cooperationSpeedBonusKmh.toStringAsFixed(1)} km/h.',
      ],
    );
  }

  _BetrayalOutcome? _evaluateBetrayalTrigger({
    required BreakawayPactStepInput input,
    required BreakawayMicroPact pact,
    required BreakawayPactCandidate initiator,
    required BreakawayPactCandidate partner,
  }) {
    if (partner.remainingWPrimeRatio < 0.10) {
      return _BetrayalOutcome(
        betrayerId: partner.riderId,
        betrayerName: partner.riderName,
        reason: BetrayalTriggerReason.exhaustionCollapse,
      );
    }

    final prob = pact.trustAnalysis.betrayalProbability;
    if (input.pelotonGapSeconds >= 65.0 &&
        input.distanceToFinishKm <= 6.0 &&
        prob >= 0.42) {
      return _BetrayalOutcome(
        betrayerId: partner.riderId,
        betrayerName: partner.riderName,
        reason: BetrayalTriggerReason.pelotonSafeMargin,
      );
    }

    if (input.currentGradientPercent >= 6.5 &&
        input.distanceToFinishKm <= 5.0 &&
        prob >= 0.35) {
      return _BetrayalOutcome(
        betrayerId: partner.riderId,
        betrayerName: partner.riderName,
        reason: BetrayalTriggerReason.steepKickerAttack,
      );
    }

    if (input.distanceToFinishKm <= 4.0 &&
        input.distanceToFinishKm > pactWindowEndKm) {
      final rng = math.Random(
        input.seed ^ (input.distanceToFinishKm * 100).round(),
      );
      if (rng.nextDouble() < prob * 0.45) {
        final partnerIsLessTrustworthy =
            partner.reputationScore <= initiator.reputationScore;
        final betrayer = partnerIsLessTrustworthy ? partner : initiator;
        return _BetrayalOutcome(
          betrayerId: betrayer.riderId,
          betrayerName: betrayer.riderName,
          reason: BetrayalTriggerReason.opportunisticAmbush,
        );
      }
    }

    return null;
  }

  double _computeCatchRisk({
    required double pelotonGapSeconds,
    required double distanceToFinishKm,
    required double closingSpeedKmh,
  }) {
    if (distanceToFinishKm <= 0.0) return 0.0;
    final requiredGapSeconds = distanceToFinishKm * 4.2;
    final pressure = (requiredGapSeconds - pelotonGapSeconds) / 45.0;
    final speedFactor = (closingSpeedKmh - 1.0) * 0.06;
    return (0.35 + pressure * 0.45 + speedFactor).clamp(0.02, 0.99);
  }
}

class _BetrayalOutcome {
  final String betrayerId;
  final String betrayerName;
  final BetrayalTriggerReason reason;

  const _BetrayalOutcome({
    required this.betrayerId,
    required this.betrayerName,
    required this.reason,
  });
}

/// Stan Riverpod dla modułu mikro-paktów i zdrady w ucieczce dnia.
class BreakawayAlliancePactState {
  final double distanceToFinishKm;
  final double pelotonGapSeconds;
  final double currentGradientPercent;
  final List<BreakawayPactCandidate> candidates;
  final BreakawayMicroPact? activePact;
  final double speedBonusKmh;
  final double pelotonCatchRisk;
  final List<String> eventLog;
  final String? selectedPartnerId;

  const BreakawayAlliancePactState({
    required this.distanceToFinishKm,
    required this.pelotonGapSeconds,
    required this.currentGradientPercent,
    required this.candidates,
    this.activePact,
    this.speedBonusKmh = 0.0,
    this.pelotonCatchRisk = 0.35,
    this.eventLog = const <String>[],
    this.selectedPartnerId,
  });

  BreakawayAlliancePactState copyWith({
    double? distanceToFinishKm,
    double? pelotonGapSeconds,
    double? currentGradientPercent,
    List<BreakawayPactCandidate>? candidates,
    BreakawayMicroPact? activePact,
    bool clearPact = false,
    double? speedBonusKmh,
    double? pelotonCatchRisk,
    List<String>? eventLog,
    String? selectedPartnerId,
  }) {
    return BreakawayAlliancePactState(
      distanceToFinishKm: distanceToFinishKm ?? this.distanceToFinishKm,
      pelotonGapSeconds: pelotonGapSeconds ?? this.pelotonGapSeconds,
      currentGradientPercent:
          currentGradientPercent ?? this.currentGradientPercent,
      candidates: candidates ?? this.candidates,
      activePact: clearPact ? null : (activePact ?? this.activePact),
      speedBonusKmh: speedBonusKmh ?? this.speedBonusKmh,
      pelotonCatchRisk: pelotonCatchRisk ?? this.pelotonCatchRisk,
      eventLog: eventLog ?? this.eventLog,
      selectedPartnerId: selectedPartnerId ?? this.selectedPartnerId,
    );
  }
}

/// Kontroler Riverpod zarządzający symulacją mikro-paktów w ucieczce.
class BreakawayAlliancePactNotifier
    extends StateNotifier<BreakawayAlliancePactState> {
  final BreakawayAlliancePactBetrayalAi _ai;

  BreakawayAlliancePactNotifier({BreakawayAlliancePactBetrayalAi? ai})
      : _ai = ai ?? const BreakawayAlliancePactBetrayalAi(),
        super(_initialState());

  static BreakawayAlliancePactState _initialState() {
    const initialCandidates = <BreakawayPactCandidate>[
      BreakawayPactCandidate(
        riderId: 'r_kowalski',
        riderName: 'Marek Kowalski',
        teamName: 'Vistula Pro Cycling',
        powerScore: 91.5,
        remainingWPrimeRatio: 0.72,
        sprintRating: 74,
        reputationScore: 0.86,
        pastPactsHonored: 9,
        pastPactsBetrayed: 1,
        pullContributionRatio: 0.85,
      ),
      BreakawayPactCandidate(
        riderId: 'r_vermeulen',
        riderName: 'Bram Vermeulen',
        teamName: 'Flanders Alpecin',
        powerScore: 89.0,
        remainingWPrimeRatio: 0.68,
        sprintRating: 82,
        reputationScore: 0.68,
        pastPactsHonored: 5,
        pastPactsBetrayed: 2,
        pullContributionRatio: 0.74,
      ),
      BreakawayPactCandidate(
        riderId: 'r_moreau',
        riderName: 'Luc Moreau',
        teamName: 'Alpes Élite',
        powerScore: 81.2,
        remainingWPrimeRatio: 0.54,
        sprintRating: 69,
        reputationScore: 0.29,
        pastPactsHonored: 1,
        pastPactsBetrayed: 6,
        pullContributionRatio: 0.30,
      ),
    ];

    return const BreakawayAlliancePactState(
      distanceToFinishKm: 15.0,
      pelotonGapSeconds: 42.0,
      currentGradientPercent: 1.5,
      candidates: initialCandidates,
      selectedPartnerId: 'r_vermeulen',
      eventLog: [
        'Ucieczka zbliża się do tablicy 15 km przed metą — otwiera się okno mikro-paktu.',
      ],
    );
  }

  void evaluateCurrentStep({int seed = 689}) {
    final result = _ai.evaluatePactStep(
      BreakawayPactStepInput(
        distanceToFinishKm: state.distanceToFinishKm,
        pelotonGapSeconds: state.pelotonGapSeconds,
        currentGradientPercent: state.currentGradientPercent,
        candidates: state.candidates,
        seed: seed,
      ),
      existingPact: state.activePact,
    );

    final updatedCandidates = state.candidates.map((c) {
      final delta = result.reputationDeltas[c.riderId];
      if (delta == null) return c;
      final isBetrayal = delta < 0;
      return c.copyWith(
        reputationScore: (c.reputationScore + delta).clamp(0.0, 1.0),
        pastPactsHonored:
            isBetrayal ? c.pastPactsHonored : c.pastPactsHonored + 1,
        pastPactsBetrayed:
            isBetrayal ? c.pastPactsBetrayed + 1 : c.pastPactsBetrayed,
      );
    }).toList(growable: false);

    state = state.copyWith(
      candidates: updatedCandidates,
      activePact: result.pact,
      speedBonusKmh: result.speedBonusKmh,
      pelotonCatchRisk: result.pelotonCatchRisk,
      eventLog: [...result.eventLog, ...state.eventLog].take(8).toList(),
    );
  }

  void advanceDistance(double deltaKm) {
    final nextDistance = (state.distanceToFinishKm - deltaKm).clamp(0.5, 25.0);
    state = state.copyWith(distanceToFinishKm: nextDistance);
    evaluateCurrentStep();
  }

  void setPelotonGap(double gapSeconds) {
    state = state.copyWith(pelotonGapSeconds: gapSeconds.clamp(5.0, 150.0));
  }

  void setGradient(double gradientPercent) {
    state =
        state.copyWith(currentGradientPercent: gradientPercent.clamp(-4.0, 14.0));
  }

  void selectPartner(String partnerId) {
    state = state.copyWith(selectedPartnerId: partnerId);
  }

  void resetScenario() {
    state = _initialState();
  }
}

final breakawayAlliancePactProvider = StateNotifierProvider<
    BreakawayAlliancePactNotifier, BreakawayAlliancePactState>(
  (ref) => BreakawayAlliancePactNotifier(),
);

/// Responsywny panel taktyczny mikro-paktów i reputacji partnerów w ucieczce.
class BreakawayAlliancePactBetrayalPanel extends ConsumerWidget {
  const BreakawayAlliancePactBetrayalPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(breakawayAlliancePactProvider);
    final notifier = ref.read(breakawayAlliancePactProvider.notifier);
    const ai = BreakawayAlliancePactBetrayalAi();
    final topTwo = ai.selectTwoStrongestRiders(state.candidates);
    final selectedPartner = state.candidates.firstWhere(
      (c) => c.riderId == state.selectedPartnerId,
      orElse: () => topTwo.length > 1 ? topTwo[1] : state.candidates.first,
    );
    final trustPreview = topTwo.isNotEmpty
        ? ai.analyzePartnerTrust(
            evaluator: topTwo.first,
            partner: selectedPartner,
            pelotonGapSeconds: state.pelotonGapSeconds,
            distanceToFinishKm: state.distanceToFinishKm,
          )
        : null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          final padding = constraints.maxWidth < 460 ? 12.0 : 18.0;

          final leftColumn = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeaderBanner(state: state),
              const SizedBox(height: 12),
              _PactStatusCard(state: state, topTwo: topTwo),
              const SizedBox(height: 12),
              _ControlsCard(state: state, notifier: notifier),
            ],
          );

          final rightColumn = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CandidatesReputationCard(
                candidates: state.candidates,
                selectedPartnerId: selectedPartner.riderId,
                onSelectPartner: notifier.selectPartner,
              ),
              if (trustPreview != null) ...[
                const SizedBox(height: 12),
                _TrustAnalysisCard(analysis: trustPreview),
              ],
              const SizedBox(height: 12),
              _EventLogCard(logs: state.eventLog),
            ],
          );

          return SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: leftColumn),
                      const SizedBox(width: 14),
                      Expanded(flex: 6, child: rightColumn),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      leftColumn,
                      const SizedBox(height: 12),
                      rightColumn,
                    ],
                  ),
          );
        },
      ),
    );
  }
}

class _HeaderBanner extends StatelessWidget {
  final BreakawayAlliancePactState state;

  const _HeaderBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    final phase = state.activePact?.phase ??
        (state.distanceToFinishKm <= 15.0
            ? BreakawayPactPhase.negotiating
            : BreakawayPactPhase.prePactWindow);
    final phaseColor = switch (phase) {
      BreakawayPactPhase.activePact => AppColors.statusSuccess,
      BreakawayPactPhase.pactHonoredEndgame => AppColors.goldAccent,
      BreakawayPactPhase.betrayed => AppColors.crimsonAlert,
      BreakawayPactPhase.rejected => AppColors.amberWarning,
      BreakawayPactPhase.negotiating => AppColors.accentBlue,
      BreakawayPactPhase.prePactWindow => AppColors.textSecondary,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mikro-Pakty Ucieczki Dnia (AI)',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Dystans do mety: ${state.distanceToFinishKm.toStringAsFixed(1)} km  •  Przewaga: ${state.pelotonGapSeconds.toStringAsFixed(0)} s',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: phaseColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: phaseColor.withValues(alpha: 0.45)),
            ),
            child: Text(
              phase.label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: phaseColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PactStatusCard extends StatelessWidget {
  final BreakawayAlliancePactState state;
  final List<BreakawayPactCandidate> topTwo;

  const _PactStatusCard({
    required this.state,
    required this.topTwo,
  });

  @override
  Widget build(BuildContext context) {
    final pact = state.activePact;
    final pairLabel = topTwo.length >= 2
        ? '${topTwo[0].riderName} ↔ ${topTwo[1].riderName}'
        : 'Brak pary do paktu';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.handshake_outlined,
                  size: 18, color: AppColors.goldAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  pairLabel,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Text(
              pact != null
                  ? '„${pact.agreementText}”\n${pact.radioCommunique}'
                  : '„${BreakawayAlliancePactBetrayalAi.defaultPactPhrase}” — kliknij Ewaluuj pakt, aby rozpocząć negocjacje.',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                height: 1.45,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _MetricChip(
                label: 'Bonus prędkości',
                value:
                    '${state.speedBonusKmh >= 0 ? '+' : ''}${state.speedBonusKmh.toStringAsFixed(1)} km/h',
                valueColor: state.speedBonusKmh >= 0
                    ? AppColors.statusSuccess
                    : AppColors.crimsonAlert,
              ),
              _MetricChip(
                label: 'Ryzyko dogonienia',
                value: '${(state.pelotonCatchRisk * 100).toStringAsFixed(0)}%',
                valueColor: state.pelotonCatchRisk > 0.60
                    ? AppColors.crimsonAlert
                    : AppColors.accentBlue,
              ),
              _MetricChip(
                label: 'Nachylenie',
                value: '${state.currentGradientPercent.toStringAsFixed(1)}%',
                valueColor: AppColors.textPrimary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ControlsCard extends StatelessWidget {
  final BreakawayAlliancePactState state;
  final BreakawayAlliancePactNotifier notifier;

  const _ControlsCard({
    required this.state,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    final canAdvance = state.distanceToFinishKm > 0.5;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sterowanie symulacją końcówki',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InteractiveActionButton(
                label: 'Ewaluuj pakt (15 km)',
                icon: Icons.gavel_rounded,
                isPrimary: true,
                onTap: () => notifier.evaluateCurrentStep(),
              ),
              _InteractiveActionButton(
                label: 'Przesuń -3 km',
                icon: Icons.fast_forward_rounded,
                enabled: canAdvance,
                onTap: () => notifier.advanceDistance(3.0),
              ),
              _InteractiveActionButton(
                label: 'Finał 1 km',
                icon: Icons.flag_rounded,
                enabled: state.distanceToFinishKm > 1.0,
                onTap: () =>
                    notifier.advanceDistance(state.distanceToFinishKm - 1.0),
              ),
              _InteractiveActionButton(
                label: 'Reset',
                icon: Icons.refresh_rounded,
                onTap: notifier.resetScenario,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CandidatesReputationCard extends StatelessWidget {
  final List<BreakawayPactCandidate> candidates;
  final String selectedPartnerId;
  final ValueChanged<String> onSelectPartner;

  const _CandidatesReputationCard({
    required this.candidates,
    required this.selectedPartnerId,
    required this.onSelectPartner,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reputacja uciekinierów w peletonie',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          for (final rider in candidates) ...[
            _CandidateRow(
              rider: rider,
              selected: rider.riderId == selectedPartnerId,
              onTap: () => onSelectPartner(rider.riderId),
            ),
            if (rider != candidates.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _CandidateRow extends StatefulWidget {
  final BreakawayPactCandidate rider;
  final bool selected;
  final VoidCallback onTap;

  const _CandidateRow({
    required this.rider,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_CandidateRow> createState() => _CandidateRowState();
}

class _CandidateRowState extends State<_CandidateRow> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final tier = widget.rider.reputationTier;
    final borderColor = widget.selected || _focused
        ? AppColors.goldAccent
        : (_hovered ? AppColors.accentBlue : AppColors.cardBorder);

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(12),
          transform: Matrix4.identity()..scaleByDouble(_pressed ? 0.99 : 1.0, _pressed ? 0.99 : 1.0, 1.0, 1.0),
          decoration: BoxDecoration(
            color: widget.selected
                ? AppColors.surfaceLight
                : (_hovered
                    ? AppColors.surfaceLight.withValues(alpha: 0.7)
                    : AppColors.background),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.rider.riderName,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.rider.teamName} • Siła ${widget.rider.powerScore.toStringAsFixed(1)} • Dotrzymane: ${widget.rider.pastPactsHonored}/${widget.rider.pastPactsHonored + widget.rider.pastPactsBetrayed}',
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: tier.badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(widget.rider.reputationScore * 100).toStringAsFixed(0)}% • ${tier.label}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: tier.badgeColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
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

class _TrustAnalysisCard extends StatelessWidget {
  final PartnerTrustAnalysis analysis;

  const _TrustAnalysisCard({required this.analysis});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analiza wiarygodności: ${analysis.partnerName}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _MetricChip(
                label: 'Zaufanie',
                value: '${(analysis.trustScore * 100).toStringAsFixed(0)}%',
                valueColor: analysis.isAccepted
                    ? AppColors.statusSuccess
                    : AppColors.crimsonAlert,
              ),
              _MetricChip(
                label: 'Ryzyko zdrady',
                value:
                    '${(analysis.betrayalProbability * 100).toStringAsFixed(0)}%',
                valueColor: analysis.betrayalProbability > 0.45
                    ? AppColors.crimsonAlert
                    : AppColors.amberWarning,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            analysis.rationale,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EventLogCard extends StatelessWidget {
  final List<String> logs;

  const _EventLogCard({required this.logs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dziennik radia wyścigowego',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          for (final entry in logs)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• $entry',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _MetricChip({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractiveActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  final bool isPrimary;

  const _InteractiveActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.enabled = true,
    this.isPrimary = false,
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
    final baseColor = widget.isPrimary
        ? AppColors.primaryAccent
        : AppColors.surfaceLight;
    final bgColor = !widget.enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : (_pressed
            ? baseColor.withValues(alpha: 0.8)
            : (_hovered ? baseColor.withValues(alpha: 0.92) : baseColor));
    final borderColor = !widget.enabled
        ? AppColors.cardBorder.withValues(alpha: 0.5)
        : (_focused
            ? AppColors.goldAccent
            : (_hovered ? AppColors.accentBlue : AppColors.cardBorder));

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown:
            widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp:
            widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel:
            widget.enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 15,
                color: widget.enabled
                    ? AppColors.textPrimary
                    : AppColors.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: widget.enabled
                      ? AppColors.textPrimary
                      : AppColors.textSecondary.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
