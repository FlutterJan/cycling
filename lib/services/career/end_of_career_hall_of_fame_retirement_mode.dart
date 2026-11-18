import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Powód zakończenia kariery menedżerskiej i przejścia na emeryturę.
enum RetirementReason {
  voluntaryLegacyPeak(
    'Dobrowolna emerytura na szczycie',
    'Menedżer odchodzi w chwale po zbudowaniu kolarskiej potęgi.',
  ),
  mandatoryAgeCap(
    'Wiek emerytalny (70+ lat)',
    'Zasłużony odpoczynek po dekadach na fotelu dyrektora sportowego.',
  ),
  healthAndBurnout(
    'Wypalenie i zdrowie',
    'Intensywność kalendarza WorldTour wymaga przekazania sterów.',
  ),
  completedDynastyGoal(
    'Realizacja celu Dynastii',
    'Wszystkie historyczne cele pokoleniowe zostały osiągnięte.',
  ),
  boardDismissalFinal(
    'Zakończenie misji zarządu',
    'Kontrakt wygasł po zakończeniu długiego cyklu sportowego.',
  );

  const RetirementReason(this.label, this.description);
  final String label;
  final String description;
}

/// Ranga w Księdze Legend (Hall of Fame) obliczana na podstawie punktów dziedzictwa.
enum HallOfFameTier {
  localLegend('Lokalna Legenda', 0, Color(0xFFCD7F32)),
  nationalIcon('Ikona Narodowa', 1500, Color(0xFFC0C0C0)),
  worldTourImmortal('Nieśmiertelny WorldTour', 3500, AppColors.goldAccent),
  grandTourEmperor('Cesarz Wielkich Tourów', 7000, AppColors.accentBlue),
  eternalCyclingPantheon('Wieczny Panteon Kolarstwa', 12000, AppColors.cyanAccent);

  const HallOfFameTier(this.label, this.minScore, this.accentColor);
  final String label;
  final int minScore;
  final Color accentColor;

  /// Wyznacza najwyższą rangę osiągniętą dla danej liczby punktów.
  static HallOfFameTier fromScore(int score) {
    HallOfFameTier current = HallOfFameTier.localLegend;
    for (final tier in HallOfFameTier.values) {
      if (score >= tier.minScore) {
        current = tier;
      }
    }
    return current;
  }
}

/// Relacja następcy w trybie New Game+ / Dynastia względem emerytowanej legendy.
enum DynastyRelation {
  sonOrDaughter(
    'Syn / Córka',
    'Bezpośredni spadkobierca nazwiska i rodzinnej szkoły taktycznej.',
    1.15,
  ),
  protegeAssistantDs(
    'Wychowanek (Asystent DS)',
    'Wieloletni prawy ręka z wozu technicznego przejmujący stery.',
    1.10,
  ),
  formerTeamCaptain(
    'Były Kapitan Drużyny',
    'Emerytowany lider peletonu, który zna szatnię od podszewki.',
    1.08,
  ),
  grandchildHeir(
    'Wnuk / Wnuczka',
    'Nowe pokolenie wnoszące nowoczesną naukę sportową do tradycji.',
    1.20,
  );

  const DynastyRelation(this.label, this.description, this.prestigeMultiplier);
  final String label;
  final String description;
  final double prestigeMultiplier;
}

/// Archetyp taktyczny nowego menedżera w Dynastii NG+.
enum DynastyArchetype {
  grandTourStrategist(
    'Strateg Wielkich Tourów',
    'Premia do zarządzania regeneracją w 3. tygodniu i taktyki górskiej.',
  ),
  classicsTactician(
    'Taktyk Klasyków i Bruku',
    'Premia do czytania wiatru bocznego, wachlarzy i wyścigów jednodniowych.',
  ),
  sprintMastermind(
    'Architekt Pociągów Sprinterskich',
    'Premia do zgrania rozprowadzania i negocjacji ze sponsorami komercyjnymi.',
  ),
  developmentArchitect(
    'Budowniczy Akademii Młodzieży',
    'Premia do odkrywania talentów U23 i tempa rozwoju młodych kolarzy.',
  );

  const DynastyArchetype(this.label, this.description);
  final String label;
  final String description;
}

/// Modyfikatory wyzwania dla trybu New Game+ / Dynastia.
enum DynastyChallengeModifier {
  rivalAiEscalation(
    'Eskalacja AI Rywali',
    'Rywale WorldTour agresywniej licytują transfery i kontratakują na etapach.',
    1.15,
  ),
  strictFinancialFairPlay(
    'Rygor Financial Fair Play',
    'Zaostrzone limity budżetowe UCI i mniejsza tolerancja zarządu na deficyt.',
    1.12,
  ),
  legendaryExpectations(
    'Presja Nazwiska',
    'Sponsorzy wymagają podium w wyścigach rangi WT już od 1. sezonu.',
    1.18,
  ),
  ironmanInjuries(
    'Realistyczna Medycyna',
    'Dłuższa rekonwalescencja po kraksach wymagająca głębszej rotacji składem.',
    1.10,
  );

  const DynastyChallengeModifier(
    this.label,
    this.description,
    this.scoreMultiplier,
  );
  final String label;
  final String description;
  final double scoreMultiplier;
}

/// Pamiątkowa tablica / odznaczenie zdobyte w trakcie kariery.
@immutable
class HallOfFamePlaque {
  const HallOfFamePlaque({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.bonusPoints,
    required this.iconCodePoint,
  });

  final String id;
  final String title;
  final String subtitle;
  final int bonusPoints;
  final int iconCodePoint;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'bonusPoints': bonusPoints,
        'iconCodePoint': iconCodePoint,
      };

  factory HallOfFamePlaque.fromJson(Map<String, dynamic> json) {
    return HallOfFamePlaque(
      id: json['id'] as String? ?? 'plaque',
      title: json['title'] as String? ?? 'Odznaczenie',
      subtitle: json['subtitle'] as String? ?? '',
      bonusPoints: (json['bonusPoints'] as num?)?.toInt() ?? 0,
      iconCodePoint:
          (json['iconCodePoint'] as num?)?.toInt() ?? Icons.emoji_events.codePoint,
    );
  }
}

/// Szczegółowy rozkład punktów dziedzictwa (Legacy Score).
@immutable
class LegacyScoreBreakdown {
  const LegacyScoreBreakdown({
    required this.grandTourPoints,
    required this.monumentPoints,
    required this.championshipPoints,
    required this.stageWinPoints,
    required this.longevityAndRankingPoints,
    required this.academyAndFinancialPoints,
    required this.plaqueBonusPoints,
    required this.dynastyMultiplier,
  });

  final int grandTourPoints;
  final int monumentPoints;
  final int championshipPoints;
  final int stageWinPoints;
  final int longevityAndRankingPoints;
  final int academyAndFinancialPoints;
  final int plaqueBonusPoints;
  final double dynastyMultiplier;

  int get rawTotal =>
      grandTourPoints +
      monumentPoints +
      championshipPoints +
      stageWinPoints +
      longevityAndRankingPoints +
      academyAndFinancialPoints +
      plaqueBonusPoints;

  int get finalScore => (rawTotal * dynastyMultiplier).round();

  Map<String, dynamic> toJson() => {
        'grandTourPoints': grandTourPoints,
        'monumentPoints': monumentPoints,
        'championshipPoints': championshipPoints,
        'stageWinPoints': stageWinPoints,
        'longevityAndRankingPoints': longevityAndRankingPoints,
        'academyAndFinancialPoints': academyAndFinancialPoints,
        'plaqueBonusPoints': plaqueBonusPoints,
        'dynastyMultiplier': dynastyMultiplier,
      };

  factory LegacyScoreBreakdown.fromJson(Map<String, dynamic> json) {
    return LegacyScoreBreakdown(
      grandTourPoints: (json['grandTourPoints'] as num?)?.toInt() ?? 0,
      monumentPoints: (json['monumentPoints'] as num?)?.toInt() ?? 0,
      championshipPoints: (json['championshipPoints'] as num?)?.toInt() ?? 0,
      stageWinPoints: (json['stageWinPoints'] as num?)?.toInt() ?? 0,
      longevityAndRankingPoints:
          (json['longevityAndRankingPoints'] as num?)?.toInt() ?? 0,
      academyAndFinancialPoints:
          (json['academyAndFinancialPoints'] as num?)?.toInt() ?? 0,
      plaqueBonusPoints: (json['plaqueBonusPoints'] as num?)?.toInt() ?? 0,
      dynastyMultiplier:
          (json['dynastyMultiplier'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

/// Pełne podsumowanie dokonań menedżera w momencie przejścia na emeryturę.
@immutable
class ManagerCareerPalmaresSummary {
  const ManagerCareerPalmaresSummary({
    required this.managerId,
    required this.managerName,
    required this.nationalityCode,
    required this.dynastyName,
    required this.generationNumber,
    required this.startSeasonYear,
    required this.endSeasonYear,
    required this.managerAgeAtRetirement,
    required this.primaryTeamName,
    required this.teamsManaged,
    required this.grandTourWins,
    required this.monumentWins,
    required this.worldAndOlympicTitles,
    required this.totalStageWins,
    required this.uciTeamNumberOneYears,
    required this.academyGraduatesPromoted,
    required this.peakTeamBudgetEur,
    required this.legacyReputation,
    required this.activeChallengeScoreMultiplier,
  });

  final String managerId;
  final String managerName;
  final String nationalityCode;
  final String dynastyName;
  final int generationNumber;
  final int startSeasonYear;
  final int endSeasonYear;
  final int managerAgeAtRetirement;
  final String primaryTeamName;
  final List<String> teamsManaged;
  final int grandTourWins;
  final int monumentWins;
  final int worldAndOlympicTitles;
  final int totalStageWins;
  final int uciTeamNumberOneYears;
  final int academyGraduatesPromoted;
  final double peakTeamBudgetEur;
  final double legacyReputation;
  final double activeChallengeScoreMultiplier;

  int get seasonsManaged => math.max(1, endSeasonYear - startSeasonYear + 1);

  Map<String, dynamic> toJson() => {
        'managerId': managerId,
        'managerName': managerName,
        'nationalityCode': nationalityCode,
        'dynastyName': dynastyName,
        'generationNumber': generationNumber,
        'startSeasonYear': startSeasonYear,
        'endSeasonYear': endSeasonYear,
        'managerAgeAtRetirement': managerAgeAtRetirement,
        'primaryTeamName': primaryTeamName,
        'teamsManaged': teamsManaged,
        'grandTourWins': grandTourWins,
        'monumentWins': monumentWins,
        'worldAndOlympicTitles': worldAndOlympicTitles,
        'totalStageWins': totalStageWins,
        'uciTeamNumberOneYears': uciTeamNumberOneYears,
        'academyGraduatesPromoted': academyGraduatesPromoted,
        'peakTeamBudgetEur': peakTeamBudgetEur,
        'legacyReputation': legacyReputation,
        'activeChallengeScoreMultiplier': activeChallengeScoreMultiplier,
      };

  factory ManagerCareerPalmaresSummary.fromJson(Map<String, dynamic> json) {
    return ManagerCareerPalmaresSummary(
      managerId: json['managerId'] as String? ?? 'mgr_1',
      managerName: json['managerName'] as String? ?? 'Nieznany Menedżer',
      nationalityCode: json['nationalityCode'] as String? ?? 'POL',
      dynastyName: json['dynastyName'] as String? ?? 'Dynastia Kolarska',
      generationNumber: (json['generationNumber'] as num?)?.toInt() ?? 1,
      startSeasonYear: (json['startSeasonYear'] as num?)?.toInt() ?? 2025,
      endSeasonYear: (json['endSeasonYear'] as num?)?.toInt() ?? 2032,
      managerAgeAtRetirement:
          (json['managerAgeAtRetirement'] as num?)?.toInt() ?? 62,
      primaryTeamName:
          json['primaryTeamName'] as String? ?? 'Pro Peloton Team',
      teamsManaged: (json['teamsManaged'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['Pro Peloton Team'],
      grandTourWins: (json['grandTourWins'] as num?)?.toInt() ?? 0,
      monumentWins: (json['monumentWins'] as num?)?.toInt() ?? 0,
      worldAndOlympicTitles:
          (json['worldAndOlympicTitles'] as num?)?.toInt() ?? 0,
      totalStageWins: (json['totalStageWins'] as num?)?.toInt() ?? 0,
      uciTeamNumberOneYears:
          (json['uciTeamNumberOneYears'] as num?)?.toInt() ?? 0,
      academyGraduatesPromoted:
          (json['academyGraduatesPromoted'] as num?)?.toInt() ?? 0,
      peakTeamBudgetEur:
          (json['peakTeamBudgetEur'] as num?)?.toDouble() ?? 15000000,
      legacyReputation:
          (json['legacyReputation'] as num?)?.toDouble() ?? 50.0,
      activeChallengeScoreMultiplier:
          (json['activeChallengeScoreMultiplier'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

/// Wpis w Księdze Legend (Hall of Fame) po zakończeniu kariery.
@immutable
class HallOfFameInductionEntry {
  const HallOfFameInductionEntry({
    required this.inductionId,
    required this.inductedAtIso,
    required this.reason,
    required this.tier,
    required this.palmares,
    required this.scoreBreakdown,
    required this.plaques,
    required this.epitaphQuote,
  });

  final String inductionId;
  final String inductedAtIso;
  final RetirementReason reason;
  final HallOfFameTier tier;
  final ManagerCareerPalmaresSummary palmares;
  final LegacyScoreBreakdown scoreBreakdown;
  final List<HallOfFamePlaque> plaques;
  final String epitaphQuote;

  int get finalScore => scoreBreakdown.finalScore;

  Map<String, dynamic> toJson() => {
        'inductionId': inductionId,
        'inductedAtIso': inductedAtIso,
        'reason': reason.name,
        'tier': tier.name,
        'palmares': palmares.toJson(),
        'scoreBreakdown': scoreBreakdown.toJson(),
        'plaques': plaques.map((p) => p.toJson()).toList(),
        'epitaphQuote': epitaphQuote,
      };

  factory HallOfFameInductionEntry.fromJson(Map<String, dynamic> json) {
    final reasonName = json['reason'] as String?;
    final tierName = json['tier'] as String?;
    return HallOfFameInductionEntry(
      inductionId: json['inductionId'] as String? ?? 'hof_0',
      inductedAtIso:
          json['inductedAtIso'] as String? ?? DateTime(2035).toIso8601String(),
      reason: RetirementReason.values.firstWhere(
        (r) => r.name == reasonName,
        orElse: () => RetirementReason.voluntaryLegacyPeak,
      ),
      tier: HallOfFameTier.values.firstWhere(
        (t) => t.name == tierName,
        orElse: () => HallOfFameTier.localLegend,
      ),
      palmares: ManagerCareerPalmaresSummary.fromJson(
        (json['palmares'] as Map<String, dynamic>?) ?? const {},
      ),
      scoreBreakdown: LegacyScoreBreakdown.fromJson(
        (json['scoreBreakdown'] as Map<String, dynamic>?) ?? const {},
      ),
      plaques: (json['plaques'] as List<dynamic>?)
              ?.map((e) => HallOfFamePlaque.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      epitaphQuote: json['epitaphQuote'] as String? ?? '',
    );
  }
}

/// Archiwum Księgi Legend przechowujące pokolenia menedżerów.
@immutable
class HallOfFameArchive {
  const HallOfFameArchive({
    this.entries = const [],
  });

  final List<HallOfFameInductionEntry> entries;

  List<HallOfFameInductionEntry> get sortedByScore {
    final copy = List<HallOfFameInductionEntry>.from(entries);
    copy.sort((a, b) => b.finalScore.compareTo(a.finalScore));
    return copy;
  }

  int get highestScore =>
      entries.isEmpty ? 0 : sortedByScore.first.finalScore;

  int get totalDynastyGenerations => entries.fold<int>(
        0,
        (maxGen, e) => math.max(maxGen, e.palmares.generationNumber),
      );

  HallOfFameArchive addEntry(HallOfFameInductionEntry entry) {
    final updated = List<HallOfFameInductionEntry>.from(entries)
      ..removeWhere((e) => e.inductionId == entry.inductionId)
      ..add(entry);
    return HallOfFameArchive(entries: updated);
  }

  String exportToJsonString() =>
      jsonEncode({'entries': entries.map((e) => e.toJson()).toList()});

  factory HallOfFameArchive.fromJsonString(String raw) {
    if (raw.trim().isEmpty) return const HallOfFameArchive();
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final list = (decoded['entries'] as List<dynamic>?)
            ?.map(
              (e) => HallOfFameInductionEntry.fromJson(
                e as Map<String, dynamic>,
              ),
            )
            .toList() ??
        const [];
    return HallOfFameArchive(entries: list);
  }
}

/// Profil następcy w trybie New Game+ / Dynastia.
@immutable
class DynastySuccessorProfile {
  const DynastySuccessorProfile({
    required this.successorName,
    required this.dynastyName,
    required this.nationalityCode,
    required this.generationNumber,
    required this.startingAge,
    required this.relation,
    required this.archetype,
    required this.predecessorInductionId,
  });

  final String successorName;
  final String dynastyName;
  final String nationalityCode;
  final int generationNumber;
  final int startingAge;
  final DynastyRelation relation;
  final DynastyArchetype archetype;
  final String predecessorInductionId;

  Map<String, dynamic> toJson() => {
        'successorName': successorName,
        'dynastyName': dynastyName,
        'nationalityCode': nationalityCode,
        'generationNumber': generationNumber,
        'startingAge': startingAge,
        'relation': relation.name,
        'archetype': archetype.name,
        'predecessorInductionId': predecessorInductionId,
      };
}

/// Dziedziczone premie i relikty przenoszone do nowej kariery New Game+ / Dynastia.
@immutable
class DynastyInheritanceBundle {
  const DynastyInheritanceBundle({
    required this.successor,
    required this.startSeasonYear,
    required this.seedEndowmentEur,
    required this.startingReputationBonus,
    required this.scoutingNetworkTierBonus,
    required this.academyTalentAuraBonus,
    required this.xpGainMultiplier,
    required this.hardcorePrestigeOnly,
    required this.activeModifiers,
    required this.mentorPassiveTitle,
    required this.inheritedRelics,
  });

  final DynastySuccessorProfile successor;
  final int startSeasonYear;
  final double seedEndowmentEur;
  final double startingReputationBonus;
  final int scoutingNetworkTierBonus;
  final double academyTalentAuraBonus;
  final double xpGainMultiplier;
  final bool hardcorePrestigeOnly;
  final Set<DynastyChallengeModifier> activeModifiers;
  final String mentorPassiveTitle;
  final List<String> inheritedRelics;

  double get combinedChallengeScoreMultiplier {
    double mult = successor.relation.prestigeMultiplier;
    for (final m in activeModifiers) {
      mult *= m.scoreMultiplier;
    }
    if (hardcorePrestigeOnly) {
      mult *= 1.15;
    }
    return double.parse(mult.toStringAsFixed(3));
  }

  Map<String, dynamic> toJson() => {
        'successor': successor.toJson(),
        'startSeasonYear': startSeasonYear,
        'seedEndowmentEur': seedEndowmentEur,
        'startingReputationBonus': startingReputationBonus,
        'scoutingNetworkTierBonus': scoutingNetworkTierBonus,
        'academyTalentAuraBonus': academyTalentAuraBonus,
        'xpGainMultiplier': xpGainMultiplier,
        'hardcorePrestigeOnly': hardcorePrestigeOnly,
        'activeModifiers': activeModifiers.map((m) => m.name).toList(),
        'mentorPassiveTitle': mentorPassiveTitle,
        'inheritedRelics': inheritedRelics,
      };
}

/// Wynik sprawdzenia gotowości menedżera do przejścia na emeryturę.
@immutable
class RetirementEligibilityReport {
  const RetirementEligibilityReport({
    required this.canRetire,
    required this.isMandatoryAgeReached,
    required this.suggestedReason,
    required this.blockingReason,
  });

  final bool canRetire;
  final bool isMandatoryAgeReached;
  final RetirementReason suggestedReason;
  final String? blockingReason;
}

/// Kompletny rezultat przejścia na emeryturę i ewentualnego startu New Game+.
@immutable
class DynastyTransitionResult {
  const DynastyTransitionResult({
    required this.inductionEntry,
    required this.updatedArchive,
    required this.dynastyBundle,
  });

  final HallOfFameInductionEntry inductionEntry;
  final HallOfFameArchive updatedArchive;
  final DynastyInheritanceBundle? dynastyBundle;
}

/// Serwis obsługujący emeryturę menedżerską, Księgę Legend (Hall of Fame)
/// oraz tryb New Game+ / Dynastia.
class EndOfCareerHallOfFameRetirementService {
  const EndOfCareerHallOfFameRetirementService();

  /// Sprawdza czy menedżer spełnia warunki przejścia na emeryturę.
  RetirementEligibilityReport evaluateEligibility(
    ManagerCareerPalmaresSummary palmares,
  ) {
    if (palmares.seasonsManaged < 1) {
      return const RetirementEligibilityReport(
        canRetire: false,
        isMandatoryAgeReached: false,
        suggestedReason: RetirementReason.voluntaryLegacyPeak,
        blockingReason:
            'Wymagany minimum 1 pełny sezon menedżerski przed przejściem na emeryturę.',
      );
    }

    if (palmares.managerAgeAtRetirement >= 70) {
      return const RetirementEligibilityReport(
        canRetire: true,
        isMandatoryAgeReached: true,
        suggestedReason: RetirementReason.mandatoryAgeCap,
        blockingReason: null,
      );
    }

    if (palmares.grandTourWins >= 3 && palmares.monumentWins >= 3) {
      return const RetirementEligibilityReport(
        canRetire: true,
        isMandatoryAgeReached: false,
        suggestedReason: RetirementReason.voluntaryLegacyPeak,
        blockingReason: null,
      );
    }

    return const RetirementEligibilityReport(
      canRetire: true,
      isMandatoryAgeReached: false,
      suggestedReason: RetirementReason.voluntaryLegacyPeak,
      blockingReason: null,
    );
  }

  /// Wylicza odznaczenia (tablice) zdobyte na przestrzeni kariery.
  List<HallOfFamePlaque> evaluatePlaques(ManagerCareerPalmaresSummary palmares) {
    final plaques = <HallOfFamePlaque>[];

    if (palmares.grandTourWins >= 3) {
      plaques.add(
        HallOfFamePlaque(
          id: 'triple_crown_architect',
          title: 'Architekt Wielkich Tourów',
          subtitle: '${palmares.grandTourWins} triumfy w klasyfikacji generalnej GT',
          bonusPoints: 750,
          iconCodePoint: Icons.workspace_premium.codePoint,
        ),
      );
    }
    if (palmares.monumentWins >= 5) {
      plaques.add(
        HallOfFamePlaque(
          id: 'monument_conqueror',
          title: 'Władca Monumentów',
          subtitle: '${palmares.monumentWins} zwycięstw w 5 kolarskich Monumentach',
          bonusPoints: 600,
          iconCodePoint: Icons.military_tech.codePoint,
        ),
      );
    }
    if (palmares.academyGraduatesPromoted >= 6) {
      plaques.add(
        HallOfFamePlaque(
          id: 'academy_patriarch',
          title: 'Patriarcha Akademii',
          subtitle:
              '${palmares.academyGraduatesPromoted} wychowanków wprowadzonych do WorldTour',
          bonusPoints: 450,
          iconCodePoint: Icons.school.codePoint,
        ),
      );
    }
    if (palmares.uciTeamNumberOneYears >= 2) {
      plaques.add(
        HallOfFamePlaque(
          id: 'uci_dynasty_dominator',
          title: 'Dominator Rankingu UCI',
          subtitle:
              '${palmares.uciTeamNumberOneYears} sezony jako najlepsza ekipa świata',
          bonusPoints: 500,
          iconCodePoint: Icons.leaderboard.codePoint,
        ),
      );
    }
    if (palmares.peakTeamBudgetEur >= 40000000) {
      plaques.add(
        HallOfFamePlaque(
          id: 'financial_empire',
          title: 'Imperium Finansowe',
          subtitle: 'Budżet zespołu przekroczył 40 mln €',
          bonusPoints: 350,
          iconCodePoint: Icons.account_balance.codePoint,
        ),
      );
    }
    if (palmares.seasonsManaged >= 10) {
      plaques.add(
        HallOfFamePlaque(
          id: 'iron_ds_decade',
          title: 'Dekada w Wozie Technicznym',
          subtitle: '${palmares.seasonsManaged} sezonów nieprzerwanej służby',
          bonusPoints: 400,
          iconCodePoint: Icons.directions_car.codePoint,
        ),
      );
    }

    return plaques;
  }

  /// Oblicza szczegółową punktację Legacy Score oraz przypisuje rangę.
  LegacyScoreBreakdown calculateScoreBreakdown(
    ManagerCareerPalmaresSummary palmares,
    List<HallOfFamePlaque> plaques,
  ) {
    final plaquePoints =
        plaques.fold<int>(0, (sum, p) => sum + p.bonusPoints);

    return LegacyScoreBreakdown(
      grandTourPoints: palmares.grandTourWins * 1100,
      monumentPoints: palmares.monumentWins * 550,
      championshipPoints: palmares.worldAndOlympicTitles * 700,
      stageWinPoints: palmares.totalStageWins * 45,
      longevityAndRankingPoints:
          palmares.seasonsManaged * 120 + palmares.uciTeamNumberOneYears * 450,
      academyAndFinancialPoints: palmares.academyGraduatesPromoted * 110 +
          (palmares.peakTeamBudgetEur / 1000000).floor() * 25,
      plaqueBonusPoints: plaquePoints,
      dynastyMultiplier: math.max(1.0, palmares.activeChallengeScoreMultiplier),
    );
  }

  /// Tworzy wpis do Księgi Legend (Hall of Fame) i aktualizuje archiwum.
  HallOfFameInductionEntry inductManager({
    required ManagerCareerPalmaresSummary palmares,
    required RetirementReason reason,
    DateTime? timestamp,
  }) {
    final now = timestamp ?? DateTime.now();
    final plaques = evaluatePlaques(palmares);
    final breakdown = calculateScoreBreakdown(palmares, plaques);
    final tier = HallOfFameTier.fromScore(breakdown.finalScore);

    final epitaph = _buildEpitaphQuote(palmares, tier, reason);

    return HallOfFameInductionEntry(
      inductionId:
          'hof_${palmares.managerId}_gen${palmares.generationNumber}_${now.millisecondsSinceEpoch}',
      inductedAtIso: now.toIso8601String(),
      reason: reason,
      tier: tier,
      palmares: palmares,
      scoreBreakdown: breakdown,
      plaques: plaques,
      epitaphQuote: epitaph,
    );
  }

  /// Generuje pakiet dziedzictwa dla nowej kariery New Game+ / Dynastia.
  DynastyInheritanceBundle buildDynastyInheritanceBundle({
    required HallOfFameInductionEntry predecessor,
    required String successorName,
    required DynastyRelation relation,
    required DynastyArchetype archetype,
    required Set<DynastyChallengeModifier> modifiers,
    bool hardcorePrestigeOnly = false,
    int? customStartAge,
  }) {
    final cleanName = successorName.trim().isEmpty
        ? '${predecessor.palmares.managerName.split(' ').last} Jr.'
        : successorName.trim();

    final tierIndex = HallOfFameTier.values.indexOf(predecessor.tier);
    final startingAge = customStartAge ??
        switch (relation) {
          DynastyRelation.sonOrDaughter => 31,
          DynastyRelation.grandchildHeir => 27,
          DynastyRelation.protegeAssistantDs => 36,
          DynastyRelation.formerTeamCaptain => 38,
        };

    final double seedEndowmentEur = hardcorePrestigeOnly
        ? 0.0
        : math
            .min(
              predecessor.palmares.peakTeamBudgetEur * 0.20,
              1500000.0 + predecessor.finalScore * 650.0,
            )
            .roundToDouble();

    final double reputationBonus = hardcorePrestigeOnly
        ? 5.0
        : double.parse(
            (8.0 + tierIndex * 5.5 + predecessor.palmares.generationNumber * 2.0)
                .clamp(5.0, 35.0)
                .toStringAsFixed(1),
          );

    final int scoutingBonus =
        hardcorePrestigeOnly ? 0 : (1 + (tierIndex ~/ 2)).clamp(1, 3);

    final double academyAura = hardcorePrestigeOnly
        ? 0.02
        : double.parse((0.04 + tierIndex * 0.025).toStringAsFixed(3));

    final double xpMult = double.parse(
      (1.08 + tierIndex * 0.05).toStringAsFixed(2),
    );

    final relics = <String>[
      'Złoty Notatnik Taktyczny (${predecessor.palmares.primaryTeamName})',
      if (predecessor.palmares.grandTourWins > 0)
        'Żółty Bidon Zwycięzcy GT (${predecessor.palmares.endSeasonYear})',
      if (predecessor.palmares.monumentWins > 0)
        'Kamień Brukowy z Arenbergu',
      if (predecessor.plaques.isNotEmpty)
        'Honorowa Tablica: ${predecessor.plaques.first.title}',
    ];

    final successor = DynastySuccessorProfile(
      successorName: cleanName,
      dynastyName: predecessor.palmares.dynastyName,
      nationalityCode: predecessor.palmares.nationalityCode,
      generationNumber: predecessor.palmares.generationNumber + 1,
      startingAge: startingAge,
      relation: relation,
      archetype: archetype,
      predecessorInductionId: predecessor.inductionId,
    );

    return DynastyInheritanceBundle(
      successor: successor,
      startSeasonYear: predecessor.palmares.endSeasonYear + 1,
      seedEndowmentEur: seedEndowmentEur,
      startingReputationBonus: reputationBonus,
      scoutingNetworkTierBonus: scoutingBonus,
      academyTalentAuraBonus: academyAura,
      xpGainMultiplier: xpMult,
      hardcorePrestigeOnly: hardcorePrestigeOnly,
      activeModifiers: Set<DynastyChallengeModifier>.from(modifiers),
      mentorPassiveTitle:
          'Duch Mentora: ${predecessor.palmares.managerName} (${predecessor.tier.label})',
      inheritedRelics: relics,
    );
  }

  /// Wykonuje pełną transakcję emerytury i opcjonalnie przygotowuje NG+ Dynastię.
  DynastyTransitionResult executeRetirementAndOptionalDynasty({
    required ManagerCareerPalmaresSummary palmares,
    required RetirementReason reason,
    required HallOfFameArchive currentArchive,
    bool startNewGamePlus = false,
    String successorName = '',
    DynastyRelation relation = DynastyRelation.sonOrDaughter,
    DynastyArchetype archetype = DynastyArchetype.grandTourStrategist,
    Set<DynastyChallengeModifier> modifiers = const {},
    bool hardcorePrestigeOnly = false,
  }) {
    final eligibility = evaluateEligibility(palmares);
    if (!eligibility.canRetire) {
      throw StateError(
        eligibility.blockingReason ?? 'Menedżer nie spełnia warunków emerytury.',
      );
    }

    final entry = inductManager(palmares: palmares, reason: reason);
    final updatedArchive = currentArchive.addEntry(entry);

    final DynastyInheritanceBundle? bundle = startNewGamePlus
        ? buildDynastyInheritanceBundle(
            predecessor: entry,
            successorName: successorName,
            relation: relation,
            archetype: archetype,
            modifiers: modifiers,
            hardcorePrestigeOnly: hardcorePrestigeOnly,
          )
        : null;

    return DynastyTransitionResult(
      inductionEntry: entry,
      updatedArchive: updatedArchive,
      dynastyBundle: bundle,
    );
  }

  String _buildEpitaphQuote(
    ManagerCareerPalmaresSummary palmares,
    HallOfFameTier tier,
    RetirementReason reason,
  ) {
    if (palmares.grandTourWins >= 5) {
      return '„Przez ${palmares.seasonsManaged} sezonów wyznaczał standardy taktyczne peletonu, zdobywając ${palmares.grandTourWins} Wielkich Tourów.”';
    }
    if (palmares.monumentWins >= 3) {
      return '„Jego drużyny kochały bruk, wiatr i najdłuższe klasyki — ${palmares.monumentWins} Monumentów zapisanych złotymi zgłoskami.”';
    }
    if (reason == RetirementReason.mandatoryAgeCap) {
      return '„Po ${palmares.seasonsManaged} latach w wozie technicznym ${palmares.primaryTeamName} przekazuje radio wyścigowe kolejnemu pokoleniu.”';
    }
    return '„${tier.label} — wniósł ${palmares.totalStageWins} zwycięstw etapowych do historii ${palmares.dynastyName}.”';
  }
}

/// Stan Riverpod dla modułu Emerytury Menedżerskiej, Księgi Legend i New Game+ Dynastii.
@immutable
class EndOfCareerRetirementState {
  const EndOfCareerRetirementState({
    required this.currentPalmares,
    required this.archive,
    this.selectedReason = RetirementReason.voluntaryLegacyPeak,
    this.selectedRelation = DynastyRelation.sonOrDaughter,
    this.selectedArchetype = DynastyArchetype.grandTourStrategist,
    this.selectedModifiers = const {},
    this.hardcorePrestigeOnly = false,
    this.successorNameInput = '',
    this.lastTransitionResult,
    this.errorMessage,
  });

  final ManagerCareerPalmaresSummary currentPalmares;
  final HallOfFameArchive archive;
  final RetirementReason selectedReason;
  final DynastyRelation selectedRelation;
  final DynastyArchetype selectedArchetype;
  final Set<DynastyChallengeModifier> selectedModifiers;
  final bool hardcorePrestigeOnly;
  final String successorNameInput;
  final DynastyTransitionResult? lastTransitionResult;
  final String? errorMessage;

  EndOfCareerRetirementState copyWith({
    ManagerCareerPalmaresSummary? currentPalmares,
    HallOfFameArchive? archive,
    RetirementReason? selectedReason,
    DynastyRelation? selectedRelation,
    DynastyArchetype? selectedArchetype,
    Set<DynastyChallengeModifier>? selectedModifiers,
    bool? hardcorePrestigeOnly,
    String? successorNameInput,
    DynastyTransitionResult? lastTransitionResult,
    String? errorMessage,
    bool clearError = false,
  }) {
    return EndOfCareerRetirementState(
      currentPalmares: currentPalmares ?? this.currentPalmares,
      archive: archive ?? this.archive,
      selectedReason: selectedReason ?? this.selectedReason,
      selectedRelation: selectedRelation ?? this.selectedRelation,
      selectedArchetype: selectedArchetype ?? this.selectedArchetype,
      selectedModifiers: selectedModifiers ?? this.selectedModifiers,
      hardcorePrestigeOnly: hardcorePrestigeOnly ?? this.hardcorePrestigeOnly,
      successorNameInput: successorNameInput ?? this.successorNameInput,
      lastTransitionResult: lastTransitionResult ?? this.lastTransitionResult,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Notifier zarządzający procesem emerytury menedżerskiej i tworzeniem Dynastii NG+.
class EndOfCareerRetirementNotifier
    extends StateNotifier<EndOfCareerRetirementState> {
  EndOfCareerRetirementNotifier({
    EndOfCareerHallOfFameRetirementService? service,
    ManagerCareerPalmaresSummary? initialPalmares,
    HallOfFameArchive? initialArchive,
  })  : _service = service ?? const EndOfCareerHallOfFameRetirementService(),
        super(
          EndOfCareerRetirementState(
            currentPalmares: initialPalmares ?? _defaultSamplePalmares(),
            archive: initialArchive ?? const HallOfFameArchive(),
          ),
        );

  final EndOfCareerHallOfFameRetirementService _service;

  static ManagerCareerPalmaresSummary _defaultSamplePalmares() {
    return const ManagerCareerPalmaresSummary(
      managerId: 'mgr_kowalski_gen1',
      managerName: 'Marek Kowalski',
      nationalityCode: 'POL',
      dynastyName: 'Dynastia Kowalski',
      generationNumber: 1,
      startSeasonYear: 2025,
      endSeasonYear: 2034,
      managerAgeAtRetirement: 61,
      primaryTeamName: 'Vistula Pro Cycling',
      teamsManaged: ['Vistula Pro Cycling', 'Baltic Continental'],
      grandTourWins: 4,
      monumentWins: 6,
      worldAndOlympicTitles: 2,
      totalStageWins: 48,
      uciTeamNumberOneYears: 3,
      academyGraduatesPromoted: 8,
      peakTeamBudgetEur: 46500000,
      legacyReputation: 92.5,
      activeChallengeScoreMultiplier: 1.0,
    );
  }

  void updatePalmares(ManagerCareerPalmaresSummary palmares) {
    state = state.copyWith(currentPalmares: palmares, clearError: true);
  }

  void selectRetirementReason(RetirementReason reason) {
    state = state.copyWith(selectedReason: reason, clearError: true);
  }

  void selectDynastyRelation(DynastyRelation relation) {
    state = state.copyWith(selectedRelation: relation, clearError: true);
  }

  void selectDynastyArchetype(DynastyArchetype archetype) {
    state = state.copyWith(selectedArchetype: archetype, clearError: true);
  }

  void toggleChallengeModifier(DynastyChallengeModifier modifier) {
    final next = Set<DynastyChallengeModifier>.from(state.selectedModifiers);
    if (next.contains(modifier)) {
      next.remove(modifier);
    } else {
      next.add(modifier);
    }
    state = state.copyWith(selectedModifiers: next, clearError: true);
  }

  void setHardcorePrestigeOnly(bool value) {
    state = state.copyWith(hardcorePrestigeOnly: value, clearError: true);
  }

  void setSuccessorName(String name) {
    state = state.copyWith(successorNameInput: name, clearError: true);
  }

  /// Wylicza podgląd punktacji i tablic bez zapisywania emerytury.
  HallOfFameInductionEntry previewInduction() {
    return _service.inductManager(
      palmares: state.currentPalmares,
      reason: state.selectedReason,
    );
  }

  /// Finalizuje emeryturę i wpisuje menedżera do Księgi Legend.
  DynastyTransitionResult? retireToHallOfFame({bool launchNewGamePlus = false}) {
    try {
      final result = _service.executeRetirementAndOptionalDynasty(
        palmares: state.currentPalmares,
        reason: state.selectedReason,
        currentArchive: state.archive,
        startNewGamePlus: launchNewGamePlus,
        successorName: state.successorNameInput,
        relation: state.selectedRelation,
        archetype: state.selectedArchetype,
        modifiers: state.selectedModifiers,
        hardcorePrestigeOnly: state.hardcorePrestigeOnly,
      );
      state = state.copyWith(
        archive: result.updatedArchive,
        lastTransitionResult: result,
        clearError: true,
      );
      return result;
    } on StateError catch (e) {
      state = state.copyWith(errorMessage: e.message);
      return null;
    }
  }
}

final endOfCareerRetirementServiceProvider =
    Provider<EndOfCareerHallOfFameRetirementService>(
  (ref) => const EndOfCareerHallOfFameRetirementService(),
);

final endOfCareerRetirementProvider = StateNotifierProvider<
    EndOfCareerRetirementNotifier, EndOfCareerRetirementState>(
  (ref) => EndOfCareerRetirementNotifier(
    service: ref.watch(endOfCareerRetirementServiceProvider),
  ),
);

/// Produkcyjny, responsywny panel UI Emerytury Menedżerskiej, Księgi Legend
/// oraz kreatora trybu New Game+ / Dynastia.
class EndOfCareerHallOfFameRetirementPanel extends ConsumerStatefulWidget {
  const EndOfCareerHallOfFameRetirementPanel({
    super.key,
    this.onStartNewGamePlus,
  });

  final ValueChanged<DynastyInheritanceBundle>? onStartNewGamePlus;

  @override
  ConsumerState<EndOfCareerHallOfFameRetirementPanel> createState() =>
      _EndOfCareerHallOfFameRetirementPanelState();
}

class _EndOfCareerHallOfFameRetirementPanelState
    extends ConsumerState<EndOfCareerHallOfFameRetirementPanel> {
  int _activeTabIndex = 0;
  late final TextEditingController _successorController;

  @override
  void initState() {
    super.initState();
    _successorController = TextEditingController();
  }

  @override
  void dispose() {
    _successorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(endOfCareerRetirementProvider);
    final notifier = ref.read(endOfCareerRetirementProvider.notifier);
    final service = ref.watch(endOfCareerRetirementServiceProvider);
    final eligibility = service.evaluateEligibility(state.currentPalmares);
    final preview = notifier.previewInduction();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isCompact = width < 640;
        final isTablet = width >= 640 && width < 1100;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor, width: 1),
          ),
          padding: EdgeInsets.all(isCompact ? 12 : 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(state, preview, isCompact),
                const SizedBox(height: 16),
                _buildTabBar(isCompact),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  _buildErrorBanner(state.errorMessage!),
                ],
                if (state.lastTransitionResult != null) ...[
                  const SizedBox(height: 12),
                  _buildSuccessBanner(state.lastTransitionResult!),
                ],
                const SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeOutCubic,
                  child: _activeTabIndex == 0
                      ? _buildRetirementOverviewTab(
                          key: const ValueKey('tab_retirement'),
                          state: state,
                          notifier: notifier,
                          preview: preview,
                          eligibility: eligibility,
                          isCompact: isCompact,
                          isTablet: isTablet,
                        )
                      : _activeTabIndex == 1
                          ? _buildDynastyNgPlusTab(
                              key: const ValueKey('tab_dynasty'),
                              state: state,
                              notifier: notifier,
                              service: service,
                              preview: preview,
                              eligibility: eligibility,
                              isCompact: isCompact,
                            )
                          : _buildHallOfFameArchiveTab(
                              key: const ValueKey('tab_archive'),
                              archive: state.archive,
                              isCompact: isCompact,
                            ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    EndOfCareerRetirementState state,
    HallOfFameInductionEntry preview,
    bool isCompact,
  ) {
    final palmares = state.currentPalmares;
    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.goldAccent.withValues(alpha: 0.45),
          width: 1,
        ),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.goldAccent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.goldAccent.withValues(alpha: 0.5),
                  ),
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  color: AppColors.goldAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emerytura Menedżerska & Dynastia NG+',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: isCompact ? 16 : 19,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${palmares.managerName} • ${palmares.dynastyName} (Pokolenie ${palmares.generationNumber})',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: preview.tier.accentColor.withValues(alpha: 0.6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  preview.tier.label.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: preview.tier.accentColor,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${preview.finalScore} PKT DZIEDZICTWA',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isCompact) {
    final tabs = <(int, String, IconData)>[
      (0, 'Emerytura & Palmares', Icons.emoji_events_outlined),
      (1, 'New Game+ / Dynastia', Icons.auto_awesome),
      (2, 'Księga Legend', Icons.menu_book_outlined),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tabs.map((tab) {
        final selected = _activeTabIndex == tab.$1;
        return _InteractivePillButton(
          label: tab.$2,
          icon: tab.$3,
          selected: selected,
          compact: isCompact,
          onTap: () => setState(() => _activeTabIndex = tab.$1),
        );
      }).toList(),
    );
  }

  Widget _buildRetirementOverviewTab({
    required Key key,
    required EndOfCareerRetirementState state,
    required EndOfCareerRetirementNotifier notifier,
    required HallOfFameInductionEntry preview,
    required RetirementEligibilityReport eligibility,
    required bool isCompact,
    required bool isTablet,
  }) {
    final p = state.currentPalmares;
    final columns = isCompact ? 2 : (isTablet ? 3 : 4);

    final stats = <(String, String, Color)>[
      ('Sezony', '${p.seasonsManaged} (${p.startSeasonYear}–${p.endSeasonYear})', AppColors.textPrimary),
      ('Wielkie Toury', '${p.grandTourWins}', AppColors.goldAccent),
      ('Monumenty', '${p.monumentWins}', AppColors.accentBlue),
      ('MŚ / Igrzyska', '${p.worldAndOlympicTitles}', AppColors.cyanAccent),
      ('Zwycięstwa etapowe', '${p.totalStageWins}', AppColors.statusSuccess),
      ('Lata #1 UCI', '${p.uciTeamNumberOneYears}', AppColors.goldAccent),
      ('Wychowankowie WT', '${p.academyGraduatesPromoted}', AppColors.accentBlue),
      ('Reputacja', '${p.legacyReputation.toStringAsFixed(1)} / 100', AppColors.textPrimary),
    ];

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionCard(
          title: 'Bilans Kariery Menedżerskiej',
          subtitle: preview.epitaphQuote,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: stats.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: isCompact ? 2.1 : 2.5,
            ),
            itemBuilder: (context, index) {
              final item = stats[index];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.$1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.$2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: item.$3,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Zdobyte Tablice Honorowe (${preview.plaques.length})',
          subtitle: 'Specjalne osiągnięcia utrwalone w Księdze Legend.',
          child: preview.plaques.isEmpty
              ? const Text(
                  'Brak odblokowanych tablic honorowych — rozegraj więcej sezonów lub zdobądź kluczowe trofea.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                )
              : Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: preview.plaques.map((plaque) {
                    return Container(
                      width: isCompact ? double.infinity : 260,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.goldAccent.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _resolvePlaqueIcon(plaque.id),
                            color: AppColors.goldAccent,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  plaque.title,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${plaque.subtitle} (+${plaque.bonusPoints} pkt)',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Decyzja o Emeryturze',
          subtitle: 'Wybierz oficjalny powód zakończenia obecnej kadencji.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: RetirementReason.values.map((reason) {
                  return _InteractivePillButton(
                    label: reason.label,
                    icon: Icons.flag_outlined,
                    selected: state.selectedReason == reason,
                    compact: true,
                    onTap: () => notifier.selectRetirementReason(reason),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                alignment: WrapAlignment.end,
                children: [
                  _ActionButton(
                    label: 'Przejdź na Emeryturę (Księga Legend)',
                    icon: Icons.military_tech,
                    enabled: eligibility.canRetire,
                    isPrimary: false,
                    onPressed: () =>
                        notifier.retireToHallOfFame(launchNewGamePlus: false),
                  ),
                  _ActionButton(
                    label: 'Konfiguruj New Game+ / Dynastię',
                    icon: Icons.arrow_forward,
                    enabled: eligibility.canRetire,
                    isPrimary: true,
                    onPressed: () => setState(() => _activeTabIndex = 1),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDynastyNgPlusTab({
    required Key key,
    required EndOfCareerRetirementState state,
    required EndOfCareerRetirementNotifier notifier,
    required EndOfCareerHallOfFameRetirementService service,
    required HallOfFameInductionEntry preview,
    required RetirementEligibilityReport eligibility,
    required bool isCompact,
  }) {
    final bundlePreview = service.buildDynastyInheritanceBundle(
      predecessor: preview,
      successorName: state.successorNameInput,
      relation: state.selectedRelation,
      archetype: state.selectedArchetype,
      modifiers: state.selectedModifiers,
      hardcorePrestigeOnly: state.hardcorePrestigeOnly,
    );

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionCard(
          title:
              'Kreator Następcy — Pokolenie ${bundlePreview.successor.generationNumber}',
          subtitle:
              'Przenieś dziedzictwo ${state.currentPalmares.dynastyName} do nowej kariery New Game+.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _successorController,
                onChanged: notifier.setSuccessorName,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  labelText: 'Imię i nazwisko następcy',
                  hintText: bundlePreview.successor.successorName,
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.goldAccent),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Relacja z Legendą',
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
                children: DynastyRelation.values.map((rel) {
                  return _InteractivePillButton(
                    label:
                        '${rel.label} (x${rel.prestigeMultiplier.toStringAsFixed(2)})',
                    icon: Icons.family_restroom,
                    selected: state.selectedRelation == rel,
                    compact: true,
                    onTap: () => notifier.selectDynastyRelation(rel),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              const Text(
                'Archetyp Taktyczny Następcy',
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
                children: DynastyArchetype.values.map((arch) {
                  return _InteractivePillButton(
                    label: arch.label,
                    icon: Icons.psychology_outlined,
                    selected: state.selectedArchetype == arch,
                    compact: true,
                    onTap: () => notifier.selectDynastyArchetype(arch),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Modyfikatory Wyzwania New Game+ & Dziedzictwo',
          subtitle:
              'Łączny mnożnik prestiżu NG+: x${bundlePreview.combinedChallengeScoreMultiplier.toStringAsFixed(2)}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Material(
                type: MaterialType.transparency,
                child: SwitchListTile.adaptive(
                  value: state.hardcorePrestigeOnly,
                  onChanged: notifier.setHardcorePrestigeOnly,
                  activeTrackColor: AppColors.goldAccent,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Tryb Czystego Prestiżu (bez dotacji finansowej)',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: const Text(
                    'Wyłącza startowy fundusz dziedzictwa i sieć skautów w zamian za +15% punktów Legacy.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: DynastyChallengeModifier.values.map((mod) {
                  return _InteractivePillButton(
                    label:
                        '${mod.label} (+${((mod.scoreMultiplier - 1) * 100).round()}%)',
                    icon: Icons.bolt,
                    selected: state.selectedModifiers.contains(mod),
                    compact: true,
                    onTap: () => notifier.toggleChallengeModifier(mod),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.goldAccent.withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bundlePreview.mentorPassiveTitle,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.goldAccent,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '• Fundusz startowy Dynastii: ${(bundlePreview.seedEndowmentEur / 1000000).toStringAsFixed(2)} mln €\n'
                      '• Premia reputacji na starcie: +${bundlePreview.startingReputationBonus} pkt\n'
                      '• Poziom sieci skautingu: +${bundlePreview.scoutingNetworkTierBonus} • Aura Akademii: +${(bundlePreview.academyTalentAuraBonus * 100).toStringAsFixed(1)}%\n'
                      '• Relikty: ${bundlePreview.inheritedRelics.join(', ')}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        height: 1.5,
                        color: AppColors.textSecondary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment:
                    isCompact ? Alignment.center : Alignment.centerRight,
                child: _ActionButton(
                  label: 'Rozpocznij New Game+ / Dynastię',
                  icon: Icons.play_arrow_rounded,
                  enabled: eligibility.canRetire,
                  isPrimary: true,
                  onPressed: () {
                    final res =
                        notifier.retireToHallOfFame(launchNewGamePlus: true);
                    if (res?.dynastyBundle != null) {
                      widget.onStartNewGamePlus?.call(res!.dynastyBundle!);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHallOfFameArchiveTab({
    required Key key,
    required HallOfFameArchive archive,
    required bool isCompact,
  }) {
    final sorted = archive.sortedByScore;
    return _SectionCard(
      key: key,
      title: 'Księga Legend (${sorted.length})',
      subtitle:
          'Najwyższy wynik dziedzictwa: ${archive.highestScore} pkt • Pokoleń: ${archive.totalDynastyGenerations}',
      child: sorted.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Księga Legend jest jeszcze pusta. Zakończ pierwszą karierę menedżerską, aby wpisać swoje nazwisko do historii.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          : Column(
              children: sorted.map((entry) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: entry.tier.accentColor.withValues(alpha: 0.45),
                    ),
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
                          Text(
                            '${entry.palmares.managerName} (Gen ${entry.palmares.generationNumber})',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${entry.palmares.primaryTeamName} • ${entry.palmares.startSeasonYear}–${entry.palmares.endSeasonYear} • ${entry.tier.label}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${entry.finalScore} PKT',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: entry.tier.accentColor,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  IconData _resolvePlaqueIcon(String plaqueId) {
    return switch (plaqueId) {
      'triple_crown_architect' => Icons.workspace_premium,
      'monument_conqueror' => Icons.military_tech,
      'academy_patriarch' => Icons.school,
      'uci_dynasty_dominator' => Icons.leaderboard,
      'financial_empire' => Icons.account_balance,
      'iron_ds_decade' => Icons.directions_car,
      _ => Icons.emoji_events,
    };
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.crimsonAlert.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.crimsonAlert),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.crimsonAlert, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessBanner(DynastyTransitionResult result) {
    final bundle = result.dynastyBundle;
    final text = bundle == null
        ? 'Wpisano ${result.inductionEntry.palmares.managerName} do Księgi Legend (${result.inductionEntry.finalScore} pkt).'
        : 'Uruchomiono Dynastię Pokolenie ${bundle.successor.generationNumber}: ${bundle.successor.successorName} (${bundle.startSeasonYear}).';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.statusSuccess.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.statusSuccess),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline,
              color: AppColors.statusSuccess, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
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
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InteractivePillButton extends StatefulWidget {
  const _InteractivePillButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  State<_InteractivePillButton> createState() => _InteractivePillButtonState();
}

class _InteractivePillButtonState extends State<_InteractivePillButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.selected
        ? AppColors.goldAccent
        : (_focused
            ? AppColors.accentBlue
            : (_hovered ? AppColors.textSecondary : AppColors.cardBorder));
    final bgColor = widget.selected
        ? AppColors.primaryAccent.withValues(alpha: 0.28)
        : (_pressed
            ? AppColors.surfaceLight.withValues(alpha: 0.9)
            : (_hovered ? AppColors.surfaceLight : AppColors.surface));

    return FocusableActionDetector(
      onShowFocusHighlight: (val) => setState(() => _focused = val),
      onShowHoverHighlight: (val) => setState(() => _hovered = val),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 10 : 14,
              vertical: widget.compact ? 8 : 10,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 16,
                  color: widget.selected
                      ? AppColors.goldAccent
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: widget.compact ? 12 : 13,
                      fontWeight:
                          widget.selected ? FontWeight.w600 : FontWeight.w500,
                      color: widget.selected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
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

class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.isPrimary,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool enabled;
  final bool isPrimary;
  final VoidCallback onPressed;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color baseBg = !widget.enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : (widget.isPrimary ? AppColors.primaryAccent : AppColors.surfaceLight);
    final Color bg = _pressed && widget.enabled
        ? baseBg.withValues(alpha: 0.78)
        : (_hovered && widget.enabled ? baseBg.withValues(alpha: 0.92) : baseBg);
    final Color borderColor = !widget.enabled
        ? AppColors.cardBorder.withValues(alpha: 0.5)
        : (_focused
            ? AppColors.goldAccent
            : (widget.isPrimary
                ? AppColors.goldAccent.withValues(alpha: 0.65)
                : AppColors.cardBorder));

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowFocusHighlight: (val) => setState(() => _focused = val),
      onShowHoverHighlight: (val) => setState(() => _hovered = val),
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.enabled ? widget.onPressed : null,
        child: MouseRegion(
          cursor: widget.enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.forbidden,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  size: 18,
                  color: widget.enabled
                      ? (widget.isPrimary
                          ? AppColors.goldAccent
                          : AppColors.textPrimary)
                      : AppColors.textSecondary.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: widget.enabled
                          ? AppColors.textPrimary
                          : AppColors.textSecondary.withValues(alpha: 0.5),
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
