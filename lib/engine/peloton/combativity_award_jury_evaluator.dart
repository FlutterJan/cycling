import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../ui/widgets/jury_communique_report_modal.dart';

/// Profil terenu etapu wpływający na wagi oceny Kolegium Sędziów dla Najaktywniejszego Kolarza.
enum CombativityStageTerrain {
  flat,
  hilly,
  mountain,
  cobbles,
  timeTrial;

  String toJson() => name;

  static CombativityStageTerrain fromJson(String value) {
    return CombativityStageTerrain.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CombativityStageTerrain.hilly,
    );
  }

  String get labelPl {
    switch (this) {
      case CombativityStageTerrain.flat:
        return 'Etap płaski';
      case CombativityStageTerrain.hilly:
        return 'Etap pagórkowaty';
      case CombativityStageTerrain.mountain:
        return 'Etap górski';
      case CombativityStageTerrain.cobbles:
        return 'Etap brukowany';
      case CombativityStageTerrain.timeTrial:
        return 'Jazda na czas';
    }
  }
}

/// Główny wyróżnik taktyczny kolarza oceniany przez jury nagrody Combativity Award.
enum CombativityHighlightTag {
  breakawayEngine,
  soloRaid,
  mountainAttacker,
  crosswindEchelonInstigator,
  komPrimeHunter,
  sprintPrimeHunter,
  lateCounterAttacker;

  String toJson() => name;

  static CombativityHighlightTag fromJson(String value) {
    return CombativityHighlightTag.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CombativityHighlightTag.breakawayEngine,
    );
  }

  String get labelPl {
    switch (this) {
      case CombativityHighlightTag.breakawayEngine:
        return 'Motor ucieczki';
      case CombativityHighlightTag.soloRaid:
        return 'Samotny rajd';
      case CombativityHighlightTag.mountainAttacker:
        return 'Ataki w górach';
      case CombativityHighlightTag.crosswindEchelonInstigator:
        return 'Ranty na wietrze';
      case CombativityHighlightTag.komPrimeHunter:
        return 'Łowca premii górskich';
      case CombativityHighlightTag.sprintPrimeHunter:
        return 'Premie lotne';
      case CombativityHighlightTag.lateCounterAttacker:
        return 'Późny kontratak';
    }
  }

  Color get accentColor {
    switch (this) {
      case CombativityHighlightTag.breakawayEngine:
        return AppColors.crimsonAlert;
      case CombativityHighlightTag.soloRaid:
        return AppColors.goldAccent;
      case CombativityHighlightTag.mountainAttacker:
        return AppColors.primaryAccent;
      case CombativityHighlightTag.crosswindEchelonInstigator:
        return AppColors.accentBlue;
      case CombativityHighlightTag.komPrimeHunter:
        return AppColors.crimsonAlert;
      case CombativityHighlightTag.sprintPrimeHunter:
        return AppColors.statusSuccess;
      case CombativityHighlightTag.lateCounterAttacker:
        return AppColors.amberWarning;
    }
  }
}

/// Dane telemetryczne kolarza z przebiegu etapu na potrzeby wyboru Najaktywniejszego Kolarza.
class CombativityRiderStageTelemetry {
  final String riderId;
  final String riderName;
  final String teamId;
  final String teamName;
  final String teamShortCode;
  final int bibNumber;
  final bool isPlayerTeam;
  final double stageDistanceKm;
  final double breakawayKilometers;
  final double frontLeadPullKilometers;
  final double longestSoloLeadKm;
  final int mountainAttacksInitiated;
  final double mountainAttackKilometers;
  final double crosswindEchelonPullKm;
  final int crosswindAttacksInitiated;
  final int komPointsEarned;
  final int sprintPointsEarned;
  final int lateKmAttacks;
  final int? stageRank;
  final bool isDisqualifiedOrDnf;

  const CombativityRiderStageTelemetry({
    required this.riderId,
    required this.riderName,
    required this.teamId,
    required this.teamName,
    required this.teamShortCode,
    required this.bibNumber,
    this.isPlayerTeam = false,
    required this.stageDistanceKm,
    this.breakawayKilometers = 0.0,
    this.frontLeadPullKilometers = 0.0,
    this.longestSoloLeadKm = 0.0,
    this.mountainAttacksInitiated = 0,
    this.mountainAttackKilometers = 0.0,
    this.crosswindEchelonPullKm = 0.0,
    this.crosswindAttacksInitiated = 0,
    this.komPointsEarned = 0,
    this.sprintPointsEarned = 0,
    this.lateKmAttacks = 0,
    this.stageRank,
    this.isDisqualifiedOrDnf = false,
  });

  double get breakawayCoverageRatio {
    if (stageDistanceKm <= 0.0) return 0.0;
    return (breakawayKilometers / stageDistanceKm).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'riderName': riderName,
      'teamId': teamId,
      'teamName': teamName,
      'teamShortCode': teamShortCode,
      'bibNumber': bibNumber,
      'isPlayerTeam': isPlayerTeam,
      'stageDistanceKm': stageDistanceKm,
      'breakawayKilometers': breakawayKilometers,
      'frontLeadPullKilometers': frontLeadPullKilometers,
      'longestSoloLeadKm': longestSoloLeadKm,
      'mountainAttacksInitiated': mountainAttacksInitiated,
      'mountainAttackKilometers': mountainAttackKilometers,
      'crosswindEchelonPullKm': crosswindEchelonPullKm,
      'crosswindAttacksInitiated': crosswindAttacksInitiated,
      'komPointsEarned': komPointsEarned,
      'sprintPointsEarned': sprintPointsEarned,
      'lateKmAttacks': lateKmAttacks,
      'stageRank': stageRank,
      'isDisqualifiedOrDnf': isDisqualifiedOrDnf,
    };
  }

  factory CombativityRiderStageTelemetry.fromJson(Map<String, dynamic> json) {
    return CombativityRiderStageTelemetry(
      riderId: json['riderId'] as String? ?? '',
      riderName: json['riderName'] as String? ?? '',
      teamId: json['teamId'] as String? ?? '',
      teamName: json['teamName'] as String? ?? '',
      teamShortCode: json['teamShortCode'] as String? ?? 'TEAM',
      bibNumber: (json['bibNumber'] as num?)?.toInt() ?? 1,
      isPlayerTeam: json['isPlayerTeam'] as bool? ?? false,
      stageDistanceKm: (json['stageDistanceKm'] as num?)?.toDouble() ?? 160.0,
      breakawayKilometers:
          (json['breakawayKilometers'] as num?)?.toDouble() ?? 0.0,
      frontLeadPullKilometers:
          (json['frontLeadPullKilometers'] as num?)?.toDouble() ?? 0.0,
      longestSoloLeadKm: (json['longestSoloLeadKm'] as num?)?.toDouble() ?? 0.0,
      mountainAttacksInitiated:
          (json['mountainAttacksInitiated'] as num?)?.toInt() ?? 0,
      mountainAttackKilometers:
          (json['mountainAttackKilometers'] as num?)?.toDouble() ?? 0.0,
      crosswindEchelonPullKm:
          (json['crosswindEchelonPullKm'] as num?)?.toDouble() ?? 0.0,
      crosswindAttacksInitiated:
          (json['crosswindAttacksInitiated'] as num?)?.toInt() ?? 0,
      komPointsEarned: (json['komPointsEarned'] as num?)?.toInt() ?? 0,
      sprintPointsEarned: (json['sprintPointsEarned'] as num?)?.toInt() ?? 0,
      lateKmAttacks: (json['lateKmAttacks'] as num?)?.toInt() ?? 0,
      stageRank: (json['stageRank'] as num?)?.toInt(),
      isDisqualifiedOrDnf: json['isDisqualifiedOrDnf'] as bool? ?? false,
    );
  }
}

/// Szczegółowe rozbicie punktacji jury dla kandydata do nagrody Najaktywniejszego Kolarza.
class CombativityScoreBreakdown {
  final double breakawayDistanceScore;
  final double frontLeadWorkScore;
  final double soloRaidBonusScore;
  final double mountainAttackScore;
  final double crosswindEchelonScore;
  final double primesAndLateAttackScore;
  final double totalScore;
  final CombativityHighlightTag dominantHighlight;

  const CombativityScoreBreakdown({
    required this.breakawayDistanceScore,
    required this.frontLeadWorkScore,
    required this.soloRaidBonusScore,
    required this.mountainAttackScore,
    required this.crosswindEchelonScore,
    required this.primesAndLateAttackScore,
    required this.totalScore,
    required this.dominantHighlight,
  });

  Map<String, dynamic> toJson() {
    return {
      'breakawayDistanceScore': breakawayDistanceScore,
      'frontLeadWorkScore': frontLeadWorkScore,
      'soloRaidBonusScore': soloRaidBonusScore,
      'mountainAttackScore': mountainAttackScore,
      'crosswindEchelonScore': crosswindEchelonScore,
      'primesAndLateAttackScore': primesAndLateAttackScore,
      'totalScore': totalScore,
      'dominantHighlight': dominantHighlight.toJson(),
    };
  }

  factory CombativityScoreBreakdown.fromJson(Map<String, dynamic> json) {
    return CombativityScoreBreakdown(
      breakawayDistanceScore:
          (json['breakawayDistanceScore'] as num?)?.toDouble() ?? 0.0,
      frontLeadWorkScore:
          (json['frontLeadWorkScore'] as num?)?.toDouble() ?? 0.0,
      soloRaidBonusScore:
          (json['soloRaidBonusScore'] as num?)?.toDouble() ?? 0.0,
      mountainAttackScore:
          (json['mountainAttackScore'] as num?)?.toDouble() ?? 0.0,
      crosswindEchelonScore:
          (json['crosswindEchelonScore'] as num?)?.toDouble() ?? 0.0,
      primesAndLateAttackScore:
          (json['primesAndLateAttackScore'] as num?)?.toDouble() ?? 0.0,
      totalScore: (json['totalScore'] as num?)?.toDouble() ?? 0.0,
      dominantHighlight: CombativityHighlightTag.fromJson(
        json['dominantHighlight'] as String? ?? 'breakawayEngine',
      ),
    );
  }
}

/// Wynik oceny pojedynczego kandydata przez Kolegium Sędziów.
class CombativityCandidateEvaluation {
  final CombativityRiderStageTelemetry telemetry;
  final CombativityScoreBreakdown breakdown;
  final double juryVoteShare;
  final int rankInJuryVote;
  final bool awardedRedDossardNextStage;
  final int prizeMoneyEur;
  final String citationPl;
  final String citationEn;

  const CombativityCandidateEvaluation({
    required this.telemetry,
    required this.breakdown,
    required this.juryVoteShare,
    required this.rankInJuryVote,
    required this.awardedRedDossardNextStage,
    required this.prizeMoneyEur,
    required this.citationPl,
    required this.citationEn,
  });

  /// Konwertuje ocenę zwycięzcy na model komunikatu Kolegium Sędziów UCI.
  CombativityAwardWinner toCombativityAwardWinner() {
    return CombativityAwardWinner(
      riderId: telemetry.riderId,
      riderName: telemetry.riderName,
      teamName: telemetry.teamName,
      teamShortCode: telemetry.teamShortCode,
      bibNumber: telemetry.bibNumber,
      breakawayKilometers: telemetry.breakawayKilometers,
      longestSoloLeadKm: telemetry.longestSoloLeadKm,
      komPointsEarned: telemetry.komPointsEarned,
      sprintPointsEarned: telemetry.sprintPointsEarned,
      juryVotesShare: juryVoteShare,
      citationPl: citationPl,
      citationEn: citationEn,
      isPlayerTeam: telemetry.isPlayerTeam,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'telemetry': telemetry.toJson(),
      'breakdown': breakdown.toJson(),
      'juryVoteShare': juryVoteShare,
      'rankInJuryVote': rankInJuryVote,
      'awardedRedDossardNextStage': awardedRedDossardNextStage,
      'prizeMoneyEur': prizeMoneyEur,
      'citationPl': citationPl,
      'citationEn': citationEn,
    };
  }

  factory CombativityCandidateEvaluation.fromJson(Map<String, dynamic> json) {
    return CombativityCandidateEvaluation(
      telemetry: CombativityRiderStageTelemetry.fromJson(
        Map<String, dynamic>.from(json['telemetry'] as Map? ?? const {}),
      ),
      breakdown: CombativityScoreBreakdown.fromJson(
        Map<String, dynamic>.from(json['breakdown'] as Map? ?? const {}),
      ),
      juryVoteShare: (json['juryVoteShare'] as num?)?.toDouble() ?? 0.0,
      rankInJuryVote: (json['rankInJuryVote'] as num?)?.toInt() ?? 1,
      awardedRedDossardNextStage:
          json['awardedRedDossardNextStage'] as bool? ?? false,
      prizeMoneyEur: (json['prizeMoneyEur'] as num?)?.toInt() ?? 0,
      citationPl: json['citationPl'] as String? ?? '',
      citationEn: json['citationEn'] as String? ?? '',
    );
  }
}

/// Oficjalny werdykt Jury dla nagrody Najaktywniejszego Kolarza Etapu (Combativity Award).
class CombativityStageAwardDecision {
  final int stageNumber;
  final String stageName;
  final CombativityStageTerrain terrain;
  final bool isAwarded;
  final CombativityCandidateEvaluation? winner;
  final List<CombativityCandidateEvaluation> rankedNominees;
  final String? redDossardNextStageRiderId;
  final int? redDossardNextStageBibNumber;
  final int prizeMoneyEur;
  final String jurySummaryPl;
  final String jurySummaryEn;

  const CombativityStageAwardDecision({
    required this.stageNumber,
    required this.stageName,
    required this.terrain,
    required this.isAwarded,
    required this.winner,
    required this.rankedNominees,
    required this.redDossardNextStageRiderId,
    required this.redDossardNextStageBibNumber,
    required this.prizeMoneyEur,
    required this.jurySummaryPl,
    required this.jurySummaryEn,
  });

  CombativityAwardWinner? toCombativityAwardWinner() {
    return winner?.toCombativityAwardWinner();
  }

  Map<String, dynamic> toJson() {
    return {
      'stageNumber': stageNumber,
      'stageName': stageName,
      'terrain': terrain.toJson(),
      'isAwarded': isAwarded,
      'winner': winner?.toJson(),
      'rankedNominees': rankedNominees.map((e) => e.toJson()).toList(),
      'redDossardNextStageRiderId': redDossardNextStageRiderId,
      'redDossardNextStageBibNumber': redDossardNextStageBibNumber,
      'prizeMoneyEur': prizeMoneyEur,
      'jurySummaryPl': jurySummaryPl,
      'jurySummaryEn': jurySummaryEn,
    };
  }

  factory CombativityStageAwardDecision.fromJson(Map<String, dynamic> json) {
    final winnerMap = json['winner'] as Map?;
    return CombativityStageAwardDecision(
      stageNumber: (json['stageNumber'] as num?)?.toInt() ?? 1,
      stageName: json['stageName'] as String? ?? '',
      terrain: CombativityStageTerrain.fromJson(
        json['terrain'] as String? ?? 'hilly',
      ),
      isAwarded: json['isAwarded'] as bool? ?? false,
      winner: winnerMap == null
          ? null
          : CombativityCandidateEvaluation.fromJson(
              Map<String, dynamic>.from(winnerMap),
            ),
      rankedNominees: (json['rankedNominees'] as List? ?? const [])
          .map(
            (e) => CombativityCandidateEvaluation.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      redDossardNextStageRiderId: json['redDossardNextStageRiderId'] as String?,
      redDossardNextStageBibNumber:
          (json['redDossardNextStageBibNumber'] as num?)?.toInt(),
      prizeMoneyEur: (json['prizeMoneyEur'] as num?)?.toInt() ?? 0,
      jurySummaryPl: json['jurySummaryPl'] as String? ?? '',
      jurySummaryEn: json['jurySummaryEn'] as String? ?? '',
    );
  }
}

/// Algorytm wyboru Najaktywniejszego Kolarza Etapu (Prix de la Combativité).
///
/// Punktuje:
/// 1. Kilometraż przejechany na czele ucieczki oraz realną pracę na zmianach.
/// 2. Inicjowanie ataków w górach i zdobyte punkty górskie KOM.
/// 3. Jazdę na wietrze bocznym (inicjowanie i ciągnięcie rantów / echelonów).
/// 4. Samotne rajdy, premie lotne i późne kontrataki w końcówce etapu.
///
/// Zwycięzca otrzymuje czerwony numer startowy na kolejny etap oraz premię 2000 EUR.
class CombativityAwardJuryEvaluator {
  const CombativityAwardJuryEvaluator();

  /// Regulaminowa premia finansowa dla Najaktywniejszego Kolarza Etapu [EUR].
  static const int combatantPrizeMoneyEur = 2000;

  /// Identyfikator oznaczenia czerwonego numeru startowego na kolejny etap.
  static const String redDossardBadgeId = 'RED_DOSSARD';

  /// Ocenia kandydatów i wyłania zwycięzcę nagrody Najaktywniejszego Kolarza Etapu.
  CombativityStageAwardDecision evaluateStage({
    required int stageNumber,
    required String stageName,
    required CombativityStageTerrain terrain,
    required List<CombativityRiderStageTelemetry> candidates,
    int maxNominees = 6,
  }) {
    if (terrain == CombativityStageTerrain.timeTrial) {
      return CombativityStageAwardDecision(
        stageNumber: stageNumber,
        stageName: stageName,
        terrain: terrain,
        isAwarded: false,
        winner: null,
        rankedNominees: const [],
        redDossardNextStageRiderId: null,
        redDossardNextStageBibNumber: null,
        prizeMoneyEur: 0,
        jurySummaryPl:
            'Na etapach jazdy na czas (ITT/TTT) nie przyznaje się nagrody Najaktywniejszego Kolarza.',
        jurySummaryEn:
            'No Combativity Award is presented on individual or team time trial stages.',
      );
    }

    final eligible = candidates
        .where((c) => !c.isDisqualifiedOrDnf)
        .toList(growable: false);

    if (eligible.isEmpty) {
      return CombativityStageAwardDecision(
        stageNumber: stageNumber,
        stageName: stageName,
        terrain: terrain,
        isAwarded: false,
        winner: null,
        rankedNominees: const [],
        redDossardNextStageRiderId: null,
        redDossardNextStageBibNumber: null,
        prizeMoneyEur: 0,
        jurySummaryPl:
            'Brak uprawnionych kolarzy, którzy ukończyli etap do klasyfikacji Combativity Award.',
        jurySummaryEn:
            'No eligible stage finishers available for the Combativity Award jury vote.',
      );
    }

    final scoredEntries = eligible.map((telemetry) {
      final breakdown = scoreRider(telemetry: telemetry, terrain: terrain);
      return _ScoredCandidate(telemetry: telemetry, breakdown: breakdown);
    }).toList();

    scoredEntries.sort(_compareCandidates);

    final activeEntries = scoredEntries
        .where((entry) => entry.breakdown.totalScore > 0.0)
        .toList(growable: false);

    if (activeEntries.isEmpty) {
      return CombativityStageAwardDecision(
        stageNumber: stageNumber,
        stageName: stageName,
        terrain: terrain,
        isAwarded: false,
        winner: null,
        rankedNominees: const [],
        redDossardNextStageRiderId: null,
        redDossardNextStageBibNumber: null,
        prizeMoneyEur: 0,
        jurySummaryPl:
            'Kolegium Sędziów nie odnotowało istotnych akcji ofensywnych kwalifikujących do nagrody.',
        jurySummaryEn:
            'The Commissaires Panel recorded no qualifying offensive actions for the award.',
      );
    }

    final limitedEntries = activeEntries.take(math.max(1, maxNominees)).toList();
    final voteShares = _computeJuryVoteShares(limitedEntries);

    final evaluations = <CombativityCandidateEvaluation>[];
    for (int i = 0; i < limitedEntries.length; i++) {
      final item = limitedEntries[i];
      final isWinner = i == 0;
      evaluations.add(
        CombativityCandidateEvaluation(
          telemetry: item.telemetry,
          breakdown: item.breakdown,
          juryVoteShare: voteShares[i],
          rankInJuryVote: i + 1,
          awardedRedDossardNextStage: isWinner,
          prizeMoneyEur: isWinner ? combatantPrizeMoneyEur : 0,
          citationPl: _buildCitationPl(item.telemetry, item.breakdown, isWinner),
          citationEn: _buildCitationEn(item.telemetry, item.breakdown, isWinner),
        ),
      );
    }

    final winner = evaluations.first;
    return CombativityStageAwardDecision(
      stageNumber: stageNumber,
      stageName: stageName,
      terrain: terrain,
      isAwarded: true,
      winner: winner,
      rankedNominees: evaluations,
      redDossardNextStageRiderId: winner.telemetry.riderId,
      redDossardNextStageBibNumber: winner.telemetry.bibNumber,
      prizeMoneyEur: combatantPrizeMoneyEur,
      jurySummaryPl:
          'Najaktywniejszym Kolarzem Etapu $stageNumber został ${winner.telemetry.riderName} '
          '(${winner.telemetry.teamShortCode}, nr ${winner.telemetry.bibNumber}) — '
          'czerwony numer startowy na kolejny etap oraz premia $combatantPrizeMoneyEur EUR.',
      jurySummaryEn:
          'Stage $stageNumber Combativity Award goes to ${winner.telemetry.riderName} '
          '(${winner.telemetry.teamShortCode}, #${winner.telemetry.bibNumber}) — '
          'red dossard for the next stage and $combatantPrizeMoneyEur EUR prize.',
    );
  }

  /// Oblicza punktację jury dla pojedynczego kolarza z uwzględnieniem profilu terenu.
  CombativityScoreBreakdown scoreRider({
    required CombativityRiderStageTelemetry telemetry,
    required CombativityStageTerrain terrain,
  }) {
    final safeStageKm = math.max(1.0, telemetry.stageDistanceKm);
    final breakawayKm = math.max(0.0, telemetry.breakawayKilometers);
    final leadPullKm = math.max(0.0, telemetry.frontLeadPullKilometers);
    final soloKm = math.max(0.0, telemetry.longestSoloLeadKm);
    final mountainAttacks = math.max(0, telemetry.mountainAttacksInitiated);
    final mountainAttackKm = math.max(0.0, telemetry.mountainAttackKilometers);
    final crosswindKm = math.max(0.0, telemetry.crosswindEchelonPullKm);
    final crosswindAttacks = math.max(0, telemetry.crosswindAttacksInitiated);
    final komPts = math.max(0, telemetry.komPointsEarned);
    final sprintPts = math.max(0, telemetry.sprintPointsEarned);
    final lateAttacks = math.max(0, telemetry.lateKmAttacks);

    final mountainMultiplier = switch (terrain) {
      CombativityStageTerrain.mountain => 1.25,
      CombativityStageTerrain.hilly => 1.10,
      _ => 1.0,
    };

    final windMultiplier = switch (terrain) {
      CombativityStageTerrain.flat => 1.25,
      CombativityStageTerrain.cobbles => 1.20,
      _ => 1.0,
    };

    final breakawayDistanceScore =
        ((breakawayKm / safeStageKm).clamp(0.0, 1.0) * 42.0) +
        (math.min(breakawayKm, 220.0) * 0.14);

    final frontLeadWorkScore = math.min(leadPullKm, 200.0) * 0.35;

    final soloRaidBonusScore = math.min(soloKm, 120.0) * 0.55;

    final mountainAttackScore =
        ((mountainAttacks * 8.5) +
            (mountainAttackKm * 0.80) +
            (komPts * 0.65)) *
        mountainMultiplier;

    final crosswindEchelonScore =
        ((crosswindKm * 0.95) + (crosswindAttacks * 9.0)) * windMultiplier;

    final primesAndLateAttackScore =
        (sprintPts * 0.35) + (lateAttacks * 6.5);

    final totalScore =
        breakawayDistanceScore +
        frontLeadWorkScore +
        soloRaidBonusScore +
        mountainAttackScore +
        crosswindEchelonScore +
        primesAndLateAttackScore;

    final dominantHighlight = _determineDominantHighlight(
      telemetry: telemetry,
      breakawayScore: breakawayDistanceScore + frontLeadWorkScore,
      soloScore: soloRaidBonusScore,
      mountainScore: mountainAttackScore,
      crosswindScore: crosswindEchelonScore,
      primesLateScore: primesAndLateAttackScore,
    );

    return CombativityScoreBreakdown(
      breakawayDistanceScore: _round2(breakawayDistanceScore),
      frontLeadWorkScore: _round2(frontLeadWorkScore),
      soloRaidBonusScore: _round2(soloRaidBonusScore),
      mountainAttackScore: _round2(mountainAttackScore),
      crosswindEchelonScore: _round2(crosswindEchelonScore),
      primesAndLateAttackScore: _round2(primesAndLateAttackScore),
      totalScore: _round2(totalScore),
      dominantHighlight: dominantHighlight,
    );
  }

  CombativityHighlightTag _determineDominantHighlight({
    required CombativityRiderStageTelemetry telemetry,
    required double breakawayScore,
    required double soloScore,
    required double mountainScore,
    required double crosswindScore,
    required double primesLateScore,
  }) {
    final candidates = <MapEntry<CombativityHighlightTag, double>>[
      MapEntry(CombativityHighlightTag.breakawayEngine, breakawayScore),
      MapEntry(
        CombativityHighlightTag.soloRaid,
        telemetry.longestSoloLeadKm >= 15.0 ? soloScore * 1.4 : soloScore,
      ),
      MapEntry(
        telemetry.mountainAttacksInitiated > 0
            ? CombativityHighlightTag.mountainAttacker
            : CombativityHighlightTag.komPrimeHunter,
        mountainScore,
      ),
      MapEntry(
        CombativityHighlightTag.crosswindEchelonInstigator,
        crosswindScore,
      ),
      MapEntry(
        telemetry.lateKmAttacks > 0
            ? CombativityHighlightTag.lateCounterAttacker
            : CombativityHighlightTag.sprintPrimeHunter,
        primesLateScore,
      ),
    ];

    candidates.sort((a, b) => b.value.compareTo(a.value));
    return candidates.first.key;
  }

  int _compareCandidates(_ScoredCandidate a, _ScoredCandidate b) {
    final scoreCmp = b.breakdown.totalScore.compareTo(a.breakdown.totalScore);
    if (scoreCmp != 0) return scoreCmp;

    final kmCmp = b.telemetry.breakawayKilometers.compareTo(
      a.telemetry.breakawayKilometers,
    );
    if (kmCmp != 0) return kmCmp;

    final attacksA =
        a.telemetry.mountainAttacksInitiated +
        a.telemetry.crosswindAttacksInitiated;
    final attacksB =
        b.telemetry.mountainAttacksInitiated +
        b.telemetry.crosswindAttacksInitiated;
    final attackCmp = attacksB.compareTo(attacksA);
    if (attackCmp != 0) return attackCmp;

    final soloCmp = b.telemetry.longestSoloLeadKm.compareTo(
      a.telemetry.longestSoloLeadKm,
    );
    if (soloCmp != 0) return soloCmp;

    final rankA = a.telemetry.stageRank ?? 9999;
    final rankB = b.telemetry.stageRank ?? 9999;
    final rankCmp = rankA.compareTo(rankB);
    if (rankCmp != 0) return rankCmp;

    return a.telemetry.bibNumber.compareTo(b.telemetry.bibNumber);
  }

  List<double> _computeJuryVoteShares(List<_ScoredCandidate> entries) {
    if (entries.isEmpty) return const [];
    if (entries.length == 1) return const [1.0];

    final maxScore = entries.first.breakdown.totalScore;
    final weights = entries
        .map((e) => math.exp((e.breakdown.totalScore - maxScore) / 14.0))
        .toList(growable: false);
    final sumWeights = weights.fold<double>(0.0, (sum, w) => sum + w);
    if (sumWeights <= 0.0) {
      final equalShare = 1.0 / entries.length;
      return List<double>.filled(entries.length, equalShare);
    }
    return weights
        .map((w) => _round4(w / sumWeights))
        .toList(growable: false);
  }

  String _buildCitationPl(
    CombativityRiderStageTelemetry telemetry,
    CombativityScoreBreakdown breakdown,
    bool isWinner,
  ) {
    final parts = <String>[];
    if (telemetry.breakawayKilometers > 0.0) {
      parts.add(
        '${telemetry.breakawayKilometers.toStringAsFixed(1)} km na czele ucieczki',
      );
    }
    if (telemetry.frontLeadPullKilometers > 0.0) {
      parts.add(
        '${telemetry.frontLeadPullKilometers.toStringAsFixed(1)} km pracy na zmianach',
      );
    }
    if (telemetry.mountainAttacksInitiated > 0) {
      parts.add(
        '${telemetry.mountainAttacksInitiated} ataków w górach',
      );
    }
    if (telemetry.crosswindEchelonPullKm > 0.0 ||
        telemetry.crosswindAttacksInitiated > 0) {
      parts.add(
        '${telemetry.crosswindEchelonPullKm.toStringAsFixed(1)} km jazdy na wietrze w rantach',
      );
    }
    if (telemetry.longestSoloLeadKm >= 5.0) {
      parts.add(
        'samotny rajd ${telemetry.longestSoloLeadKm.toStringAsFixed(1)} km',
      );
    }

    final actionText = parts.isEmpty
        ? 'aktywna jazda ofensywna w trakcie etapu'
        : parts.join(', ');

    if (isWinner) {
      return 'Laureat czerwonego numeru startowego (+$combatantPrizeMoneyEur EUR): $actionText.';
    }
    return 'Nominacja jury (${breakdown.totalScore.toStringAsFixed(1)} pkt): $actionText.';
  }

  String _buildCitationEn(
    CombativityRiderStageTelemetry telemetry,
    CombativityScoreBreakdown breakdown,
    bool isWinner,
  ) {
    final parts = <String>[];
    if (telemetry.breakawayKilometers > 0.0) {
      parts.add(
        '${telemetry.breakawayKilometers.toStringAsFixed(1)} km in the breakaway',
      );
    }
    if (telemetry.mountainAttacksInitiated > 0) {
      parts.add(
        '${telemetry.mountainAttacksInitiated} mountain attacks initiated',
      );
    }
    if (telemetry.crosswindEchelonPullKm > 0.0 ||
        telemetry.crosswindAttacksInitiated > 0) {
      parts.add(
        '${telemetry.crosswindEchelonPullKm.toStringAsFixed(1)} km driving crosswind echelons',
      );
    }
    if (telemetry.longestSoloLeadKm >= 5.0) {
      parts.add(
        '${telemetry.longestSoloLeadKm.toStringAsFixed(1)} km solo lead',
      );
    }

    final actionText = parts.isEmpty
        ? 'relentless offensive riding throughout the stage'
        : parts.join(', ');

    if (isWinner) {
      return 'Awarded the red dossard (+$combatantPrizeMoneyEur EUR): $actionText.';
    }
    return 'Jury nominee (${breakdown.totalScore.toStringAsFixed(1)} pts): $actionText.';
  }

  static double _round2(double v) => (v * 100.0).roundToDouble() / 100.0;
  static double _round4(double v) => (v * 10000.0).roundToDouble() / 10000.0;
}

class _ScoredCandidate {
  final CombativityRiderStageTelemetry telemetry;
  final CombativityScoreBreakdown breakdown;

  const _ScoredCandidate({
    required this.telemetry,
    required this.breakdown,
  });
}

/// Filtry listy nominowanych w panelu Najaktywniejszego Kolarza Etapu.
enum CombativityPanelFilter {
  all,
  breakaway,
  mountainsAndWind;

  String get labelPl {
    switch (this) {
      case CombativityPanelFilter.all:
        return 'Wszyscy';
      case CombativityPanelFilter.breakaway:
        return 'Ucieczka';
      case CombativityPanelFilter.mountainsAndWind:
        return 'Góry i wiatr';
    }
  }
}

/// Interaktywny panel Kolegium Sędziów prezentujący wybór Najaktywniejszego Kolarza Etapu.
class CombativityAwardJuryPanel extends StatefulWidget {
  final CombativityStageAwardDecision decision;
  final ValueChanged<CombativityCandidateEvaluation>? onSelectNominee;

  const CombativityAwardJuryPanel({
    super.key,
    required this.decision,
    this.onSelectNominee,
  });

  @override
  State<CombativityAwardJuryPanel> createState() =>
      _CombativityAwardJuryPanelState();
}

class _CombativityAwardJuryPanelState extends State<CombativityAwardJuryPanel> {
  CombativityPanelFilter _filter = CombativityPanelFilter.all;
  String? _selectedRiderId;
  bool _copiedCitation = false;

  @override
  void initState() {
    super.initState();
    _selectedRiderId = widget.decision.winner?.telemetry.riderId;
  }

  @override
  void didUpdateWidget(covariant CombativityAwardJuryPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.decision.stageNumber != widget.decision.stageNumber ||
        oldWidget.decision.winner?.telemetry.riderId !=
            widget.decision.winner?.telemetry.riderId) {
      _selectedRiderId = widget.decision.winner?.telemetry.riderId;
      _copiedCitation = false;
    }
  }

  List<CombativityCandidateEvaluation> get _filteredNominees {
    final all = widget.decision.rankedNominees;
    switch (_filter) {
      case CombativityPanelFilter.all:
        return all;
      case CombativityPanelFilter.breakaway:
        return all
            .where((e) => e.telemetry.breakawayKilometers > 0.0)
            .toList(growable: false);
      case CombativityPanelFilter.mountainsAndWind:
        return all
            .where(
              (e) =>
                  e.telemetry.mountainAttacksInitiated > 0 ||
                  e.telemetry.crosswindEchelonPullKm > 0.0 ||
                  e.telemetry.crosswindAttacksInitiated > 0,
            )
            .toList(growable: false);
    }
  }

  CombativityCandidateEvaluation? get _activeNominee {
    final nominees = widget.decision.rankedNominees;
    if (nominees.isEmpty) return null;
    for (final item in nominees) {
      if (item.telemetry.riderId == _selectedRiderId) return item;
    }
    return nominees.first;
  }

  Future<void> _copyWinnerCitation() async {
    final target = _activeNominee ?? widget.decision.winner;
    if (target == null) return;
    await Clipboard.setData(ClipboardData(text: target.citationPl));
    if (!mounted) return;
    setState(() => _copiedCitation = true);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 560;
        final isWide = constraints.maxWidth >= 960;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor, width: 1),
          ),
          padding: EdgeInsets.all(isCompact ? 14 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(isCompact),
              const SizedBox(height: 16),
              if (!widget.decision.isAwarded || widget.decision.winner == null)
                _buildEmptyState()
              else ...[
                _buildWinnerBanner(widget.decision.winner!, isCompact),
                const SizedBox(height: 16),
                _buildFilterBar(isCompact),
                const SizedBox(height: 12),
                if (isWide && _activeNominee != null)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _buildNomineeList(isCompact)),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: _buildBreakdownCard(_activeNominee!),
                      ),
                    ],
                  )
                else ...[
                  _buildNomineeList(isCompact),
                  if (_activeNominee != null) ...[
                    const SizedBox(height: 12),
                    _buildBreakdownCard(_activeNominee!),
                  ],
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isCompact) {
    final canCopy = widget.decision.isAwarded && widget.decision.winner != null;
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.crimsonAlert.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.crimsonAlert.withValues(alpha: 0.45),
                ),
              ),
              child: const Icon(
                Icons.local_fire_department_rounded,
                color: AppColors.crimsonAlert,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Najaktywniejszy Kolarz Etapu ${widget.decision.stageNumber}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: isCompact ? 15 : 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    '${widget.decision.stageName} • ${widget.decision.terrain.labelPl}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        _CombativityActionButton(
          label: _copiedCitation ? 'Skopiowano werdykt' : 'Kopiuj werdykt',
          icon: _copiedCitation ? Icons.check_rounded : Icons.copy_rounded,
          enabled: canCopy,
          onPressed: canCopy ? _copyWinnerCitation : null,
        ),
      ],
    );
  }

  Widget _buildWinnerBanner(
    CombativityCandidateEvaluation winner,
    bool isCompact,
  ) {
    final t = winner.telemetry;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.all(isCompact ? 14 : 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.crimsonAlert.withValues(alpha: 0.55),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.crimsonAlert,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'CZERWONY NUMER #${t.bibNumber}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.4,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.goldAccent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.goldAccent.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  '+${winner.prizeMoneyEur} EUR',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.goldAccent,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Text(
                  'Głosy jury: ${(winner.juryVoteShare * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${t.riderName} (${t.teamName})',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: isCompact ? 16 : 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            winner.citationPl,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _MetricChip(
                label: 'Ucieczka',
                value: '${t.breakawayKilometers.toStringAsFixed(1)} km',
              ),
              _MetricChip(
                label: 'Ataki w górach',
                value: '${t.mountainAttacksInitiated}',
              ),
              _MetricChip(
                label: 'Jazda na wietrze',
                value: '${t.crosswindEchelonPullKm.toStringAsFixed(1)} km',
              ),
              _MetricChip(
                label: 'Samotny rajd',
                value: '${t.longestSoloLeadKm.toStringAsFixed(1)} km',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(bool isCompact) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: CombativityPanelFilter.values.map((filter) {
        final selected = _filter == filter;
        return _FilterChipButton(
          label: filter.labelPl,
          selected: selected,
          onTap: () => setState(() => _filter = filter),
        );
      }).toList(),
    );
  }

  Widget _buildNomineeList(bool isCompact) {
    final nominees = _filteredNominees;
    if (nominees.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: const Text(
          'Brak nominowanych kolarzy spełniających wybrane kryterium filtra.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: nominees.map((candidate) {
        final isSelected = candidate.telemetry.riderId == _selectedRiderId;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _NomineeTile(
            candidate: candidate,
            isSelected: isSelected,
            isCompact: isCompact,
            onTap: () {
              setState(() {
                _selectedRiderId = candidate.telemetry.riderId;
                _copiedCitation = false;
              });
              widget.onSelectNominee?.call(candidate);
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBreakdownCard(CombativityCandidateEvaluation candidate) {
    final b = candidate.breakdown;
    final t = candidate.telemetry;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Punktacja Jury • ${t.riderName}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _ScoreBarRow(
            label: 'Kilometraż ucieczki',
            score: b.breakawayDistanceScore,
            maxScore: 75,
            color: AppColors.crimsonAlert,
          ),
          _ScoreBarRow(
            label: 'Praca na zmianach',
            score: b.frontLeadWorkScore,
            maxScore: 60,
            color: AppColors.amberWarning,
          ),
          _ScoreBarRow(
            label: 'Ataki w górach i KOM',
            score: b.mountainAttackScore,
            maxScore: 60,
            color: AppColors.primaryAccent,
          ),
          _ScoreBarRow(
            label: 'Jazda na wietrze (ranty)',
            score: b.crosswindEchelonScore,
            maxScore: 60,
            color: AppColors.accentBlue,
          ),
          _ScoreBarRow(
            label: 'Samotny rajd / kontry',
            score: b.soloRaidBonusScore + b.primesAndLateAttackScore,
            maxScore: 60,
            color: AppColors.goldAccent,
          ),
          const Divider(color: AppTheme.borderColor, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  'Suma punktów Jury',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${b.totalScore.toStringAsFixed(1)} pkt',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.goldAccent,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Brak laureata Combativity Award',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.decision.jurySummaryPl,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _NomineeTile extends StatefulWidget {
  final CombativityCandidateEvaluation candidate;
  final bool isSelected;
  final bool isCompact;
  final VoidCallback onTap;

  const _NomineeTile({
    required this.candidate,
    required this.isSelected,
    required this.isCompact,
    required this.onTap,
  });

  @override
  State<_NomineeTile> createState() => _NomineeTileState();
}

class _NomineeTileState extends State<_NomineeTile> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.candidate.telemetry;
    final b = widget.candidate.breakdown;
    final borderColor = _focused
        ? AppColors.goldAccent
        : widget.isSelected
            ? AppColors.crimsonAlert
            : _hovered
                ? AppColors.textSecondary.withValues(alpha: 0.45)
                : AppTheme.borderColor;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: widget.isCompact ? 12 : 14,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            color: _pressed
                ? AppColors.surfaceLight.withValues(alpha: 0.9)
                : widget.isSelected
                    ? AppColors.surfaceLight
                    : _hovered
                        ? AppColors.surfaceLight.withValues(alpha: 0.6)
                        : AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: widget.candidate.awardedRedDossardNextStage
                      ? AppColors.crimsonAlert
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Text(
                  '${widget.candidate.rankInJuryVote}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${t.riderName} • ${t.teamShortCode}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      b.dominantHighlight.labelPl,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: b.dominantHighlight.accentColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${b.totalScore.toStringAsFixed(1)} pkt',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    '${(widget.candidate.juryVoteShare * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreBarRow extends StatelessWidget {
  final String label;
  final double score;
  final double maxScore;
  final Color color;

  const _ScoreBarRow({
    required this.label,
    required this.score,
    required this.maxScore,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = (score / math.max(1.0, maxScore)).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Text(
                score.toStringAsFixed(1),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(color),
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

  const _MetricChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
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
          Text(
            value,
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
    );
  }
}

class _FilterChipButton extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_FilterChipButton> createState() => _FilterChipButtonState();
}

class _FilterChipButtonState extends State<_FilterChipButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: widget.selected
                ? AppColors.crimsonAlert.withValues(alpha: 0.2)
                : _hovered
                    ? AppColors.surfaceLight
                    : AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _focused
                  ? AppColors.goldAccent
                  : widget.selected
                      ? AppColors.crimsonAlert
                      : AppTheme.borderColor,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
              color: widget.selected
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _CombativityActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback? onPressed;

  const _CombativityActionButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_CombativityActionButton> createState() =>
      _CombativityActionButtonState();
}

class _CombativityActionButtonState extends State<_CombativityActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled && widget.onPressed != null;
    return FocusableActionDetector(
      enabled: enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: !enabled
                ? AppColors.background
                : _pressed
                    ? AppColors.primaryAccent
                    : _hovered
                        ? AppColors.surfaceLight
                        : AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _focused ? AppColors.goldAccent : AppTheme.borderColor,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 15,
                color: enabled
                    ? AppColors.textPrimary
                    : AppColors.textSecondary.withValues(alpha: 0.45),
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: enabled
                      ? AppColors.textPrimary
                      : AppColors.textSecondary.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
