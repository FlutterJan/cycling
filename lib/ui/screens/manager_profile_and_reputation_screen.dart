import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/career/career_save.dart';
import '../../models/team/cycling_team.dart';
import '../../services/career/achievement_and_milestones_service.dart';
import '../../state/career_controller.dart';

/// Zakładki ekranu Profilu Menedżera, statystyk życiowych i reputacji.
enum ManagerProfileTab {
  overview('Przegląd i Reputacja', Icons.verified_user_rounded),
  lifetimeStats('Statystyki Życiowe', Icons.analytics_rounded),
  tacticsAndTraits('Taktyka i Cechy', Icons.psychology_rounded),
  milestonesAndHistory('Historia i Kamienie', Icons.timeline_rounded);

  final String label;
  final IconData icon;

  const ManagerProfileTab(this.label, this.icon);
}

/// Ranga reputacji dyrektora sportowego w świecie UCI.
enum ManagerReputationTier {
  rookieDirector('Debiutant Szosowy', 0, 24, AppColors.textSecondary),
  proTactician('Taktyk ProSeries', 25, 49, AppColors.accentBlue),
  worldTourDirector('Dyrektor WorldTour', 50, 74, AppColors.statusSuccess),
  dynastyArchitect('Architekt Dynastii', 75, 89, AppColors.primaryAccent),
  cyclingLegend('Ikona Kolarstwa', 90, 100, AppColors.goldAccent);

  final String label;
  final int minScore;
  final int maxScore;
  final Color color;

  const ManagerReputationTier(
    this.label,
    this.minScore,
    this.maxScore,
    this.color,
  );

  static ManagerReputationTier fromScore(int score) {
    final clamped = score.clamp(0, 100);
    for (final tier in ManagerReputationTier.values.reversed) {
      if (clamped >= tier.minScore) return tier;
    }
    return ManagerReputationTier.rookieDirector;
  }
}

/// Preferowany styl komunikacji medialnej i zarządzania szatnią.
enum ManagerMediaStance {
  diplomatic(
    'Dyplomatyczny',
    'Stabilizuje zaufanie sponsorów i łagodzi konflikty w prasie.',
    Icons.handshake_rounded,
  ),
  aggressive(
    'Bezkompromisowy',
    'Podnosi determinację liderów przed klasykami, ale zwiększa presję mediów.',
    Icons.flash_on_rounded,
  ),
  analytical(
    'Analityczny',
    'Wzmacnia autorytet w tunelu aero i przy planowaniu szczytów formy.',
    Icons.insights_rounded,
  ),
  mediaDarling(
    'Ulubieniec Mediów',
    'Zwiększa wartość ekwiwalentu reklamowego TV i atrakcyjność dla sponsorów.',
    Icons.mic_external_on_rounded,
  );

  final String label;
  final String effectSummary;
  final IconData icon;

  const ManagerMediaStance(this.label, this.effectSummary, this.icon);

  static ManagerMediaStance fromJson(String value) {
    return ManagerMediaStance.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ManagerMediaStance.analytical,
    );
  }
}

/// Filtr zakresu statystyk życiowych.
enum ManagerStatsScopeFilter {
  allTime('Cała kariera'),
  currentSeason('Bieżący sezon'),
  grandTours('Wielkie Toury'),
  monuments('Monumenty');

  final String label;
  const ManagerStatsScopeFilter(this.label);
}

/// Filar składający się na końcowy indeks reputacji menedżera.
class ManagerReputationPillar {
  final String id;
  final String title;
  final String subtitle;
  final int score;
  final int seasonDelta;
  final String impactDescription;
  final IconData icon;
  final Color accentColor;

  const ManagerReputationPillar({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.score,
    required this.seasonDelta,
    required this.impactDescription,
    required this.icon,
    required this.accentColor,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'score': score,
      'seasonDelta': seasonDelta,
      'impactDescription': impactDescription,
    };
  }
}

/// Punkt historyczny reputacji menedżera w ujęciu sezonowym.
class ManagerSeasonReputationPoint {
  final int seasonYear;
  final int reputation;
  final int uciTeamRank;
  final int winsCount;
  final String teamName;

  const ManagerSeasonReputationPoint({
    required this.seasonYear,
    required this.reputation,
    required this.uciTeamRank,
    required this.winsCount,
    required this.teamName,
  });

  Map<String, dynamic> toJson() {
    return {
      'seasonYear': seasonYear,
      'reputation': reputation,
      'uciTeamRank': uciTeamRank,
      'winsCount': winsCount,
      'teamName': teamName,
    };
  }

  factory ManagerSeasonReputationPoint.fromJson(Map<String, dynamic> json) {
    return ManagerSeasonReputationPoint(
      seasonYear: (json['seasonYear'] as num).toInt(),
      reputation: (json['reputation'] as num).toInt(),
      uciTeamRank: (json['uciTeamRank'] as num).toInt(),
      winsCount: (json['winsCount'] as num).toInt(),
      teamName: json['teamName'] as String,
    );
  }
}

/// Zbiorcze statystyki życiowe dyrektora sportowego.
class ManagerLifetimeStats {
  final int seasonsManaged;
  final int totalRaceDays;
  final int stageWins;
  final int oneDayWins;
  final int monumentWins;
  final int grandTourTitles;
  final int leaderJerseyDays;
  final int podiumFinishes;
  final int totalPrizeMoneyEur;
  final double tacticalEfficiencyPct;
  final int negotiationWinRatePct;
  final int flatWins;
  final int hillsWins;
  final int mountainWins;
  final int cobbleWins;
  final int timeTrialWins;

  const ManagerLifetimeStats({
    required this.seasonsManaged,
    required this.totalRaceDays,
    required this.stageWins,
    required this.oneDayWins,
    required this.monumentWins,
    required this.grandTourTitles,
    required this.leaderJerseyDays,
    required this.podiumFinishes,
    required this.totalPrizeMoneyEur,
    required this.tacticalEfficiencyPct,
    required this.negotiationWinRatePct,
    required this.flatWins,
    required this.hillsWins,
    required this.mountainWins,
    required this.cobbleWins,
    required this.timeTrialWins,
  });

  int get totalVictories => stageWins + oneDayWins;

  Map<String, dynamic> toJson() {
    return {
      'seasonsManaged': seasonsManaged,
      'totalRaceDays': totalRaceDays,
      'stageWins': stageWins,
      'oneDayWins': oneDayWins,
      'monumentWins': monumentWins,
      'grandTourTitles': grandTourTitles,
      'leaderJerseyDays': leaderJerseyDays,
      'podiumFinishes': podiumFinishes,
      'totalPrizeMoneyEur': totalPrizeMoneyEur,
      'tacticalEfficiencyPct': tacticalEfficiencyPct,
      'negotiationWinRatePct': negotiationWinRatePct,
      'flatWins': flatWins,
      'hillsWins': hillsWins,
      'mountainWins': mountainWins,
      'cobbleWins': cobbleWins,
      'timeTrialWins': timeTrialWins,
    };
  }

  factory ManagerLifetimeStats.fromJson(Map<String, dynamic> json) {
    return ManagerLifetimeStats(
      seasonsManaged: (json['seasonsManaged'] as num).toInt(),
      totalRaceDays: (json['totalRaceDays'] as num).toInt(),
      stageWins: (json['stageWins'] as num).toInt(),
      oneDayWins: (json['oneDayWins'] as num).toInt(),
      monumentWins: (json['monumentWins'] as num).toInt(),
      grandTourTitles: (json['grandTourTitles'] as num).toInt(),
      leaderJerseyDays: (json['leaderJerseyDays'] as num).toInt(),
      podiumFinishes: (json['podiumFinishes'] as num).toInt(),
      totalPrizeMoneyEur: (json['totalPrizeMoneyEur'] as num).toInt(),
      tacticalEfficiencyPct: (json['tacticalEfficiencyPct'] as num).toDouble(),
      negotiationWinRatePct: (json['negotiationWinRatePct'] as num).toInt(),
      flatWins: (json['flatWins'] as num).toInt(),
      hillsWins: (json['hillsWins'] as num).toInt(),
      mountainWins: (json['mountainWins'] as num).toInt(),
      cobbleWins: (json['cobbleWins'] as num).toInt(),
      timeTrialWins: (json['timeTrialWins'] as num).toInt(),
    );
  }
}

/// Cecha / odznaka reputacyjna menedżera wpływająca na negocjacje i morale.
class ManagerTraitBadge {
  final String id;
  final String title;
  final String description;
  final String bonusLabel;
  final IconData icon;
  final Color accentColor;
  final bool isUnlocked;
  final double progressRatio;

  const ManagerTraitBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.bonusLabel,
    required this.icon,
    required this.accentColor,
    required this.isUnlocked,
    required this.progressRatio,
  });
}

/// Kamień milowy w historii kariery menedżera.
class ManagerCareerMilestone {
  final String id;
  final int seasonYear;
  final String dateLabel;
  final String title;
  final String description;
  final String categoryLabel;
  final bool isMajorHighlight;

  const ManagerCareerMilestone({
    required this.id,
    required this.seasonYear,
    required this.dateLabel,
    required this.title,
    required this.description,
    required this.categoryLabel,
    this.isMajorHighlight = false,
  });
}

/// Pełny migawkowy model profilu menedżera, statystyk życiowych i reputacji.
class ManagerProfileSnapshot {
  final String managerName;
  final String licenseCode;
  final String teamName;
  final String teamCountryIso;
  final TeamDivision teamDivision;
  final CareerDifficulty difficulty;
  final int currentSeasonYear;
  final DateTime currentDate;
  final int reputationScore;
  final int boardConfidencePct;
  final int mediaAppealPct;
  final int serviceCourseLevel;
  final int windTunnelLevel;
  final int medicalCenterLevel;
  final ManagerMediaStance mediaStance;
  final ManagerLifetimeStats lifetimeStats;
  final List<ManagerReputationPillar> pillars;
  final List<ManagerSeasonReputationPoint> reputationHistory;
  final List<ManagerTraitBadge> traits;
  final List<ManagerCareerMilestone> milestones;

  const ManagerProfileSnapshot({
    required this.managerName,
    required this.licenseCode,
    required this.teamName,
    required this.teamCountryIso,
    required this.teamDivision,
    required this.difficulty,
    required this.currentSeasonYear,
    required this.currentDate,
    required this.reputationScore,
    required this.boardConfidencePct,
    required this.mediaAppealPct,
    required this.serviceCourseLevel,
    required this.windTunnelLevel,
    required this.medicalCenterLevel,
    required this.mediaStance,
    required this.lifetimeStats,
    required this.pillars,
    required this.reputationHistory,
    required this.traits,
    required this.milestones,
  });

  ManagerReputationTier get reputationTier =>
      ManagerReputationTier.fromScore(reputationScore);

  int get pointsToNextTier {
    final tier = reputationTier;
    if (tier == ManagerReputationTier.cyclingLegend) return 0;
    return (tier.maxScore + 1 - reputationScore).clamp(0, 100);
  }

  /// Buduje deterministyczny profil na podstawie aktywnego zapisu kariery.
  factory ManagerProfileSnapshot.fromCareerSave(
    CareerSave save, {
    CareerAchievementMetrics? metrics,
    ManagerMediaStance mediaStance = ManagerMediaStance.analytical,
  }) {
    final team = save.playerTeam;
    final rep = save.managerReputation.clamp(1, 100);
    final seasonsManaged = math.max(1, save.currentSeasonYear - 2025);

    final stageWins = metrics?.totalStageAndRaceWins ??
        math.max(0, save.trophiesWon.length * 3 + (team.uciPointsSeason ~/ 180));
    final oneDayWins =
        metrics?.monumentsWonCount ?? math.max(0, save.trophiesWon.length);
    final monumentWins = metrics?.monumentsWonCount ??
        save.trophiesWon
            .where((t) =>
                t.toLowerCase().contains('roubaix') ||
                t.toLowerCase().contains('flanders') ||
                t.toLowerCase().contains('sanremo') ||
                t.toLowerCase().contains('liege') ||
                t.toLowerCase().contains('lombardia'))
            .length;
    final grandTourTitles = metrics?.grandTourGcWins ??
        save.trophiesWon
            .where((t) =>
                t.toLowerCase().contains('tour de france') ||
                t.toLowerCase().contains('giro') ||
                t.toLowerCase().contains('vuelta'))
            .length;

    final flatWins = metrics?.sprintStageWins ?? (stageWins * 0.30).round();
    final hillsWins = metrics?.breakawayWins ?? (stageWins * 0.25).round();
    final mountainWins =
        metrics?.mountainStageWins ?? (stageWins * 0.25).round();
    final cobbleWins = (stageWins * 0.10).round();
    final timeTrialWins =
        metrics?.timeTrialWins ??
        math.max(0, stageWins - flatWins - hillsWins - mountainWins - cobbleWins);

    final totalPrizeMoneyEur = save.financeLedger
        .where((e) =>
            e.category == FinanceCategory.prizeMoney ||
            e.category == FinanceCategory.racePrizeMoney)
        .fold<int>(0, (sum, e) => sum + e.amountEur);

    final acceptedOffers = save.contractOffers
        .where((o) => o.status == ContractOfferStatus.accepted)
        .length;
    final totalOffers = save.contractOffers.length;
    final negotiationRate = totalOffers == 0
        ? (55 + (rep * 0.35)).round().clamp(40, 96)
        : ((acceptedOffers / totalOffers) * 100).round().clamp(25, 99);

    final boardConfidence =
        (42 + (rep * 0.45) + (team.uciPointsSeason / 150)).round().clamp(15, 99);
    final mediaAppeal =
        (35 + (rep * 0.5) + (save.trophiesWon.length * 4)).round().clamp(20, 99);

    final infraAvg =
        ((save.serviceCourseLevel + save.windTunnelLevel + save.medicalCenterLevel) /
                15.0 *
                100)
            .round()
            .clamp(20, 100);
    final scoutingScore =
        (40 + save.youthAcademy.enrolledProspectIds.length * 6 + (team.staff.scoutsLevel * 0.35))
            .round()
            .clamp(25, 100);
    final sportingScore =
        (rep * 0.72 + math.min(28, save.trophiesWon.length * 5))
            .round()
            .clamp(15, 100);
    final ethicsScore =
        (68 + (save.difficulty == CareerDifficulty.realistic ? 14 : 6))
            .clamp(40, 99);

    final pillars = <ManagerReputationPillar>[
      ManagerReputationPillar(
        id: 'sporting',
        title: 'Sukcesy Sportowe',
        subtitle: 'Zwycięstwa etapowe, klasyki i punkty UCI',
        score: sportingScore,
        seasonDelta: math.max(1, team.uciPointsSeason ~/ 350),
        impactDescription:
            'Zwiększa szansę na dzikie karty ASO/RCS oraz przyciąga liderów GC.',
        icon: Icons.emoji_events_rounded,
        accentColor: AppColors.goldAccent,
      ),
      ManagerReputationPillar(
        id: 'board_trust',
        title: 'Zaufanie Zarządu i Sponsorów',
        subtitle: 'Realizacja celów oraz dyscyplina budżetowa',
        score: boardConfidence,
        seasonDelta: team.netMonthlyCashflowEur >= 0 ? 4 : -3,
        impactDescription:
            'Chroni stanowisko w okresach słabszej formy i podnosi oferty tytularne.',
        icon: Icons.account_balance_rounded,
        accentColor: AppColors.statusSuccess,
      ),
      ManagerReputationPillar(
        id: 'talent_dev',
        title: 'Rozwój Talentów U23',
        subtitle: 'Skauting młodzieży i progresja neoprofesjonalistów',
        score: scoutingScore,
        seasonDelta: 3,
        impactDescription:
            'Obniża żądania płacowe młodych kolarzy o 8–15% przy podpisywaniu umów.',
        icon: Icons.school_rounded,
        accentColor: AppColors.accentBlue,
      ),
      ManagerReputationPillar(
        id: 'innovation',
        title: 'Innowacje i Baza R&D',
        subtitle: 'Tunel aero, Service Course i centrum medyczne',
        score: infraAvg,
        seasonDelta: 2,
        impactDescription:
            'Odblokowuje priorytetowy dostęp do prototypów ram i kół u producentów.',
        icon: Icons.precision_manufacturing_rounded,
        accentColor: AppColors.cyanAccent,
      ),
      ManagerReputationPillar(
        id: 'ethics',
        title: 'Etyka i Fair Play UCI',
        subtitle: 'Czystość paszportu biologicznego i etykieta peletonu',
        score: ethicsScore,
        seasonDelta: 1,
        impactDescription:
            'Wzmacnia autorytet w kolegium sędziów i buduje zaufanie w sojuszach.',
        icon: Icons.shield_rounded,
        accentColor: AppColors.primaryAccent,
      ),
    ];

    final history = List<ManagerSeasonReputationPoint>.generate(
      math.max(2, seasonsManaged),
      (index) {
        final year = save.currentSeasonYear - (math.max(2, seasonsManaged) - 1 - index);
        final isCurrent = year == save.currentSeasonYear;
        final historicalRep = isCurrent
            ? rep
            : math.max(18, rep - (math.max(2, seasonsManaged) - 1 - index) * 7);
        return ManagerSeasonReputationPoint(
          seasonYear: year,
          reputation: historicalRep,
          uciTeamRank: math.max(1, 24 - (historicalRep ~/ 5)),
          winsCount: isCurrent
              ? stageWins + oneDayWins
              : math.max(2, (historicalRep / 5).round()),
          teamName: team.name,
        );
      },
    );

    final traits = <ManagerTraitBadge>[
      ManagerTraitBadge(
        id: 'tactical_mastermind',
        title: 'Mistrz Echelonów',
        description: 'Minimum 5 zwycięstw na płaskich lub brukowanych etapach.',
        bonusLabel: '+8% skuteczności formacji na wietrze bocznym',
        icon: Icons.air_rounded,
        accentColor: AppColors.accentBlue,
        isUnlocked: (flatWins + cobbleWins) >= 5,
        progressRatio: ((flatWins + cobbleWins) / 5.0).clamp(0.0, 1.0),
      ),
      ManagerTraitBadge(
        id: 'alpine_architect',
        title: 'Architekt Górski',
        description: 'Minimum 5 triumfów na etapach wysokogórskich HC.',
        bonusLabel: '+5% zaufania liderów GC na podjazdach >10%',
        icon: Icons.terrain_rounded,
        accentColor: AppColors.goldAccent,
        isUnlocked: mountainWins >= 5,
        progressRatio: (mountainWins / 5.0).clamp(0.0, 1.0),
      ),
      ManagerTraitBadge(
        id: 'aero_perfectionist',
        title: 'Inżynier Tunelu Aero',
        description: 'Rozbuduj Tunel Aerodynamiczny co najmniej do Poziomu 3.',
        bonusLabel: '-10% kosztu testów sprzętu i bike fittingu',
        icon: Icons.speed_rounded,
        accentColor: AppColors.cyanAccent,
        isUnlocked: save.windTunnelLevel >= 3,
        progressRatio: (save.windTunnelLevel / 3.0).clamp(0.0, 1.0),
      ),
      ManagerTraitBadge(
        id: 'silver_tongue',
        title: 'Negocjator WorldTour',
        description: 'Osiągnij minimum 65 pkt reputacji menedżerskiej.',
        bonusLabel: '+15% cierpliwości agentów podczas rozmów kontraktowych',
        icon: Icons.record_voice_over_rounded,
        accentColor: AppColors.statusSuccess,
        isUnlocked: rep >= 65,
        progressRatio: (rep / 65.0).clamp(0.0, 1.0),
      ),
    ];

    final milestones = <ManagerCareerMilestone>[
      ManagerCareerMilestone(
        id: 'm_start',
        seasonYear: 2026,
        dateLabel: '01.01.2026',
        title: 'Objęcie sterów w ${team.name}',
        description:
            'Uzyskanie licencji Dyrektora Sportowego UCI i podpisanie kontraktu zarządczego.',
        categoryLabel: 'Kariera',
        isMajorHighlight: false,
      ),
      if (save.trophiesWon.isNotEmpty)
        ...save.trophiesWon.take(6).toList().asMap().entries.map((entry) {
          return ManagerCareerMilestone(
            id: 'm_trophy_${entry.key}',
            seasonYear: save.currentSeasonYear,
            dateLabel: DateFormat('dd.MM.yyyy').format(save.currentDate),
            title: 'Triumf: ${entry.value}',
            description:
                'Historyczne zwycięstwo zapisane w kronice klubu ${team.name}.',
            categoryLabel: 'Trofeum',
            isMajorHighlight: true,
          );
        }),
      ManagerCareerMilestone(
        id: 'm_infra',
        seasonYear: save.currentSeasonYear,
        dateLabel: DateFormat('dd.MM.yyyy').format(save.currentDate),
        title: 'Modernizacja Bazy Service Course (Poz. ${save.serviceCourseLevel})',
        description:
            'Rozwój zaplecza logistycznego, tunelu aero (Poz. ${save.windTunnelLevel}) i centrum medycznego (Poz. ${save.medicalCenterLevel}).',
        categoryLabel: 'Infrastruktura',
        isMajorHighlight: false,
      ),
    ];

    final licenseSuffix =
        team.countryIso.toUpperCase().padRight(2, 'X').substring(0, 2);

    return ManagerProfileSnapshot(
      managerName: save.playerManagerName,
      licenseCode: 'UCI-DS-$licenseSuffix-${save.currentSeasonYear}-${(rep * 17 + 104) % 999}',
      teamName: team.name,
      teamCountryIso: team.countryIso,
      teamDivision: team.division,
      difficulty: save.difficulty,
      currentSeasonYear: save.currentSeasonYear,
      currentDate: save.currentDate,
      reputationScore: rep,
      boardConfidencePct: boardConfidence,
      mediaAppealPct: mediaAppeal,
      serviceCourseLevel: save.serviceCourseLevel,
      windTunnelLevel: save.windTunnelLevel,
      medicalCenterLevel: save.medicalCenterLevel,
      mediaStance: mediaStance,
      lifetimeStats: ManagerLifetimeStats(
        seasonsManaged: seasonsManaged,
        totalRaceDays: math.max(12, seasonsManaged * 64),
        stageWins: stageWins,
        oneDayWins: oneDayWins,
        monumentWins: monumentWins,
        grandTourTitles: grandTourTitles,
        leaderJerseyDays: math.max(0, stageWins * 2 + grandTourTitles * 12),
        podiumFinishes: math.max(stageWins + oneDayWins, (stageWins + oneDayWins) * 2 + 4),
        totalPrizeMoneyEur:
            totalPrizeMoneyEur > 0 ? totalPrizeMoneyEur : (stageWins * 18500 + oneDayWins * 24000),
        tacticalEfficiencyPct: (62.0 + rep * 0.31).clamp(45.0, 96.5),
        negotiationWinRatePct: negotiationRate,
        flatWins: flatWins,
        hillsWins: hillsWins,
        mountainWins: mountainWins,
        cobbleWins: cobbleWins,
        timeTrialWins: timeTrialWins,
      ),
      pillars: pillars,
      reputationHistory: history,
      traits: traits,
      milestones: milestones,
    );
  }

  /// Tworzy realistyczny profil demonstracyjny dla trybu podglądu bez aktywnego zapisu.
  factory ManagerProfileSnapshot.demoPreview() {
    return ManagerProfileSnapshot(
      managerName: 'Jan Kowalski',
      licenseCode: 'UCI-DS-PL-2028-742',
      teamName: 'Veloce Orlen Pro Cycling',
      teamCountryIso: 'PL',
      teamDivision: TeamDivision.worldTour,
      difficulty: CareerDifficulty.normal,
      currentSeasonYear: 2028,
      currentDate: DateTime(2028, 7, 24),
      reputationScore: 78,
      boardConfidencePct: 86,
      mediaAppealPct: 81,
      serviceCourseLevel: 4,
      windTunnelLevel: 3,
      medicalCenterLevel: 4,
      mediaStance: ManagerMediaStance.analytical,
      lifetimeStats: const ManagerLifetimeStats(
        seasonsManaged: 3,
        totalRaceDays: 194,
        stageWins: 34,
        oneDayWins: 11,
        monumentWins: 2,
        grandTourTitles: 1,
        leaderJerseyDays: 29,
        podiumFinishes: 88,
        totalPrizeMoneyEur: 1485000,
        tacticalEfficiencyPct: 84.6,
        negotiationWinRatePct: 79,
        flatWins: 11,
        hillsWins: 8,
        mountainWins: 9,
        cobbleWins: 3,
        timeTrialWins: 3,
      ),
      pillars: const [
        ManagerReputationPillar(
          id: 'sporting',
          title: 'Sukcesy Sportowe',
          subtitle: 'Zwycięstwa etapowe, klasyki i punkty UCI',
          score: 82,
          seasonDelta: 6,
          impactDescription:
              'Zwiększa szansę na dzikie karty ASO/RCS oraz przyciąga liderów GC.',
          icon: Icons.emoji_events_rounded,
          accentColor: AppColors.goldAccent,
        ),
        ManagerReputationPillar(
          id: 'board_trust',
          title: 'Zaufanie Zarządu i Sponsorów',
          subtitle: 'Realizacja celów oraz dyscyplina budżetowa',
          score: 86,
          seasonDelta: 4,
          impactDescription:
              'Chroni stanowisko w okresach słabszej formy i podnosi oferty tytularne.',
          icon: Icons.account_balance_rounded,
          accentColor: AppColors.statusSuccess,
        ),
        ManagerReputationPillar(
          id: 'talent_dev',
          title: 'Rozwój Talentów U23',
          subtitle: 'Skauting młodzieży i progresja neoprofesjonalistów',
          score: 74,
          seasonDelta: 5,
          impactDescription:
              'Obniża żądania płacowe młodych kolarzy o 8–15% przy podpisywaniu umów.',
          icon: Icons.school_rounded,
          accentColor: AppColors.accentBlue,
        ),
        ManagerReputationPillar(
          id: 'innovation',
          title: 'Innowacje i Baza R&D',
          subtitle: 'Tunel aero, Service Course i centrum medyczne',
          score: 73,
          seasonDelta: 3,
          impactDescription:
              'Odblokowuje priorytetowy dostęp do prototypów ram i kół u producentów.',
          icon: Icons.precision_manufacturing_rounded,
          accentColor: AppColors.cyanAccent,
        ),
        ManagerReputationPillar(
          id: 'ethics',
          title: 'Etyka i Fair Play UCI',
          subtitle: 'Czystość paszportu biologicznego i etykieta peletonu',
          score: 79,
          seasonDelta: 1,
          impactDescription:
              'Wzmacnia autorytet w kolegium sędziów i buduje zaufanie w sojuszach.',
          icon: Icons.shield_rounded,
          accentColor: AppColors.primaryAccent,
        ),
      ],
      reputationHistory: const [
        ManagerSeasonReputationPoint(
          seasonYear: 2026,
          reputation: 54,
          uciTeamRank: 16,
          winsCount: 9,
          teamName: 'Veloce Orlen Pro Cycling',
        ),
        ManagerSeasonReputationPoint(
          seasonYear: 2027,
          reputation: 67,
          uciTeamRank: 9,
          winsCount: 16,
          teamName: 'Veloce Orlen Pro Cycling',
        ),
        ManagerSeasonReputationPoint(
          seasonYear: 2028,
          reputation: 78,
          uciTeamRank: 4,
          winsCount: 20,
          teamName: 'Veloce Orlen Pro Cycling',
        ),
      ],
      traits: const [
        ManagerTraitBadge(
          id: 'tactical_mastermind',
          title: 'Mistrz Echelonów',
          description: 'Minimum 5 zwycięstw na płaskich lub brukowanych etapach.',
          bonusLabel: '+8% skuteczności formacji na wietrze bocznym',
          icon: Icons.air_rounded,
          accentColor: AppColors.accentBlue,
          isUnlocked: true,
          progressRatio: 1.0,
        ),
        ManagerTraitBadge(
          id: 'alpine_architect',
          title: 'Architekt Górski',
          description: 'Minimum 5 triumfów na etapach wysokogórskich HC.',
          bonusLabel: '+5% zaufania liderów GC na podjazdach >10%',
          icon: Icons.terrain_rounded,
          accentColor: AppColors.goldAccent,
          isUnlocked: true,
          progressRatio: 1.0,
        ),
        ManagerTraitBadge(
          id: 'aero_perfectionist',
          title: 'Inżynier Tunelu Aero',
          description: 'Rozbuduj Tunel Aerodynamiczny co najmniej do Poziomu 3.',
          bonusLabel: '-10% kosztu testów sprzętu i bike fittingu',
          icon: Icons.speed_rounded,
          accentColor: AppColors.cyanAccent,
          isUnlocked: true,
          progressRatio: 1.0,
        ),
        ManagerTraitBadge(
          id: 'silver_tongue',
          title: 'Negocjator WorldTour',
          description: 'Osiągnij minimum 85 pkt reputacji menedżerskiej.',
          bonusLabel: '+15% cierpliwości agentów podczas rozmów kontraktowych',
          icon: Icons.record_voice_over_rounded,
          accentColor: AppColors.statusSuccess,
          isUnlocked: false,
          progressRatio: 78 / 85,
        ),
      ],
      milestones: const [
        ManagerCareerMilestone(
          id: 'demo_1',
          seasonYear: 2026,
          dateLabel: '14.01.2026',
          title: 'Debiut na poziomie UCI WorldTour',
          description: 'Przejęcie zarządzania drużyną i pierwsze zwycięstwo etapowe w styczniu.',
          categoryLabel: 'Kariera',
        ),
        ManagerCareerMilestone(
          id: 'demo_2',
          seasonYear: 2027,
          dateLabel: '09.04.2027',
          title: 'Triumf na welodromie Paris–Roubaix',
          description: 'Taktyczny atak na Carrefour de l’Arbre zapewnił pierwszy Monument.',
          categoryLabel: 'Monument',
          isMajorHighlight: true,
        ),
        ManagerCareerMilestone(
          id: 'demo_3',
          seasonYear: 2028,
          dateLabel: '23.07.2028',
          title: 'Zwycięstwo w klasyfikacji generalnej Grand Touru',
          description: 'Żółta koszulka utrzymana na Polach Elizejskich po 21 dniach walki.',
          categoryLabel: 'Wielki Tour',
          isMajorHighlight: true,
        ),
      ],
    );
  }
}

/// Ekran Profilu Menedżera, statystyk życiowych i reputacji.
///
/// Prezentuje licencję dyrektora sportowego UCI, 5 filarów reputacji,
/// wykresy życiowych statystyk zwycięstw i trajektorii prestiżu (`fl_chart`),
/// cechy taktyczne, wybór stylu medialnego oraz oś kamieni milowych kariery.
class ManagerProfileAndReputationScreen extends ConsumerStatefulWidget {
  final CareerSave? careerSave;
  final ManagerProfileSnapshot? initialSnapshot;
  final bool isReadOnly;
  final ValueChanged<ManagerMediaStance>? onMediaStanceChanged;
  final VoidCallback? onBackPressed;

  const ManagerProfileAndReputationScreen({
    super.key,
    this.careerSave,
    this.initialSnapshot,
    this.isReadOnly = false,
    this.onMediaStanceChanged,
    this.onBackPressed,
  });

  @override
  ConsumerState<ManagerProfileAndReputationScreen> createState() =>
      _ManagerProfileAndReputationScreenState();
}

class _ManagerProfileAndReputationScreenState
    extends ConsumerState<ManagerProfileAndReputationScreen> {
  ManagerProfileTab _selectedTab = ManagerProfileTab.overview;
  ManagerStatsScopeFilter _statsScope = ManagerStatsScopeFilter.allTime;
  String? _selectedPillarId;
  bool _onlyMajorMilestones = false;
  bool _useDemoPreview = false;
  late ManagerMediaStance _mediaStance;

  @override
  void initState() {
    super.initState();
    _mediaStance =
        widget.initialSnapshot?.mediaStance ?? ManagerMediaStance.analytical;
  }

  ManagerProfileSnapshot? _resolveSnapshot() {
    if (widget.initialSnapshot != null) {
      return widget.initialSnapshot;
    }
    if (widget.careerSave != null) {
      return ManagerProfileSnapshot.fromCareerSave(
        widget.careerSave!,
        mediaStance: _mediaStance,
      );
    }
    final activeSave = ref.watch(careerProvider).save;
    if (activeSave != null) {
      final metrics = ref.watch(achievementServiceProvider).metrics;
      return ManagerProfileSnapshot.fromCareerSave(
        activeSave,
        metrics: metrics,
        mediaStance: _mediaStance,
      );
    }
    if (_useDemoPreview) {
      return ManagerProfileSnapshot.demoPreview();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _resolveSnapshot();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isMobile = width < 680;
            final isTablet = width >= 680 && width < 1150;
            final horizontalPadding = isMobile ? 14.0 : 24.0;

            if (snapshot == null) {
              return _buildEmptyCareerState(
                horizontalPadding: horizontalPadding,
                isMobile: isMobile,
              );
            }

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: isMobile ? 14 : 22,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTopBar(snapshot, isMobile: isMobile),
                  const SizedBox(height: 16),
                  _buildHeroLicenseAndReputation(
                    snapshot,
                    isMobile: isMobile,
                    isTablet: isTablet,
                  ),
                  const SizedBox(height: 18),
                  _buildTabSelector(isMobile: isMobile),
                  const SizedBox(height: 18),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeOutCubic,
                    child: KeyedSubtree(
                      key: ValueKey(_selectedTab),
                      child: _buildActiveTabContent(
                        snapshot,
                        isMobile: isMobile,
                        isTablet: isTablet,
                        contentWidth: width - (horizontalPadding * 2),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyCareerState({
    required double horizontalPadding,
    required bool isMobile,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(horizontalPadding),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            padding: EdgeInsets.all(isMobile ? 20 : 28),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderColor, width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.goldAccent.withValues(alpha: 0.45)),
                  ),
                  child: const Icon(
                    Icons.badge_outlined,
                    color: AppColors.goldAccent,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Brak aktywnego profilu menedżera',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Rozpocznij lub wczytaj karierę, aby śledzić reputację UCI, zaufanie zarządu oraz statystyki życiowe dyrektora sportowego.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    if (widget.onBackPressed != null)
                      _InteractiveActionButton(
                        label: 'Wróć',
                        icon: Icons.arrow_back_rounded,
                        isPrimary: false,
                        isDisabled: false,
                        onPressed: widget.onBackPressed,
                      ),
                    _InteractiveActionButton(
                      label: 'Wczytaj podgląd profilu',
                      icon: Icons.visibility_rounded,
                      isPrimary: true,
                      isDisabled: widget.isReadOnly,
                      onPressed: widget.isReadOnly
                          ? null
                          : () => setState(() => _useDemoPreview = true),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(
    ManagerProfileSnapshot snapshot, {
    required bool isMobile,
  }) {
    return Row(
      children: [
        if (widget.onBackPressed != null) ...[
          _InteractiveIconChip(
            icon: Icons.arrow_back_rounded,
            tooltip: 'Powrót',
            isDisabled: false,
            onTap: widget.onBackPressed,
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Profil Menedżera i Reputacja',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${snapshot.teamName} • Sezon ${snapshot.currentSeasonYear}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (widget.isReadOnly)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.textSecondary),
                SizedBox(width: 6),
                Text(
                  'Tylko odczyt',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildHeroLicenseAndReputation(
    ManagerProfileSnapshot snapshot, {
    required bool isMobile,
    required bool isTablet,
  }) {
    final licenseCard = _buildLicenseCard(snapshot, isMobile: isMobile);
    final reputationCard = _buildReputationGaugeCard(snapshot, isMobile: isMobile);

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          licenseCard,
          const SizedBox(height: 14),
          reputationCard,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: isTablet ? 6 : 7, child: licenseCard),
        const SizedBox(width: 16),
        Expanded(flex: 5, child: reputationCard),
      ],
    );
  }

  Widget _buildLicenseCard(
    ManagerProfileSnapshot snapshot, {
    required bool isMobile,
  }) {
    final tier = snapshot.reputationTier;
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface,
            AppColors.surfaceLight.withValues(alpha: 0.72),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.goldAccent.withValues(alpha: 0.55),
                  ),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppColors.goldAccent,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      snapshot.managerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Licencja ${snapshot.licenseCode}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: tier.color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: tier.color.withValues(alpha: 0.55)),
                ),
                child: Text(
                  tier.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: tier.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _StatPill(
                icon: Icons.directions_bike_rounded,
                label: 'Dywizja',
                value: snapshot.teamDivision.label,
                color: AppColors.goldAccent,
              ),
              _StatPill(
                icon: Icons.verified_rounded,
                label: 'Zarząd',
                value: '${snapshot.boardConfidencePct}%',
                color: AppColors.statusSuccess,
              ),
              _StatPill(
                icon: Icons.tv_rounded,
                label: 'Media',
                value: '${snapshot.mediaAppealPct}%',
                color: AppColors.accentBlue,
              ),
              _StatPill(
                icon: Icons.build_rounded,
                label: 'Baza HQ',
                value: 'Poz. ${snapshot.serviceCourseLevel}',
                color: AppColors.cyanAccent,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(
              children: [
                Icon(_mediaStance.icon, color: AppColors.goldAccent, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Styl medialny: ${_mediaStance.label} — ${_mediaStance.effectSummary}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.35,
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

  Widget _buildReputationGaugeCard(
    ManagerProfileSnapshot snapshot, {
    required bool isMobile,
  }) {
    final tier = snapshot.reputationTier;
    final progress = (snapshot.reputationScore / 100.0).clamp(0.0, 1.0);

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: Row(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progress),
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            builder: (context, animatedValue, _) {
              return SizedBox(
                width: 96,
                height: 96,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 96,
                      height: 96,
                      child: CircularProgressIndicator(
                        value: animatedValue,
                        strokeWidth: 8,
                        backgroundColor: AppColors.surfaceLight,
                        valueColor: AlwaysStoppedAnimation<Color>(tier.color),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${snapshot.reputationScore}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        const Text(
                          '/ 100',
                          style: TextStyle(
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
              );
            },
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Indeks Reputacji UCI',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  snapshot.pointsToNextTier == 0
                      ? 'Osiągnięto najwyższy status legendy światowego peletonu.'
                      : 'Brakuje ${snapshot.pointsToNextTier} pkt do kolejnej rangi prestiżu.',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _MiniKpi(
                      label: 'Zwycięstwa',
                      value: '${snapshot.lifetimeStats.totalVictories}',
                      color: AppColors.goldAccent,
                    ),
                    _MiniKpi(
                      label: 'Skuteczność',
                      value:
                          '${snapshot.lifetimeStats.tacticalEfficiencyPct.toStringAsFixed(1)}%',
                      color: AppColors.statusSuccess,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector({required bool isMobile}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ManagerProfileTab.values.map((tab) {
        final isSelected = _selectedTab == tab;
        return _InteractiveTabChip(
          label: tab.label,
          icon: tab.icon,
          isSelected: isSelected,
          isDisabled: false,
          compact: isMobile,
          onTap: () => setState(() => _selectedTab = tab),
        );
      }).toList(),
    );
  }

  Widget _buildActiveTabContent(
    ManagerProfileSnapshot snapshot, {
    required bool isMobile,
    required bool isTablet,
    required double contentWidth,
  }) {
    switch (_selectedTab) {
      case ManagerProfileTab.overview:
        return _buildOverviewTab(
          snapshot,
          isMobile: isMobile,
          isTablet: isTablet,
        );
      case ManagerProfileTab.lifetimeStats:
        return _buildLifetimeStatsTab(
          snapshot,
          isMobile: isMobile,
          isTablet: isTablet,
          contentWidth: contentWidth,
        );
      case ManagerProfileTab.tacticsAndTraits:
        return _buildTacticsAndTraitsTab(
          snapshot,
          isMobile: isMobile,
          isTablet: isTablet,
        );
      case ManagerProfileTab.milestonesAndHistory:
        return _buildMilestonesTab(snapshot, isMobile: isMobile);
    }
  }

  Widget _buildOverviewTab(
    ManagerProfileSnapshot snapshot, {
    required bool isMobile,
    required bool isTablet,
  }) {
    final pillarsSection = _SectionCard(
      title: '5 Filarów Reputacji Menedżera',
      subtitle: 'Kliknij lub najedź na filar, aby zobaczyć wpływ na świat gry',
      child: Column(
        children: snapshot.pillars.map((pillar) {
          final isSelected = _selectedPillarId == pillar.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ReputationPillarTile(
              pillar: pillar,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  _selectedPillarId = isSelected ? null : pillar.id;
                });
              },
            ),
          );
        }).toList(),
      ),
    );

    final historyChartSection = _SectionCard(
      title: 'Trajektoria Reputacji Sezon po Sezonie',
      subtitle: 'Ewolucja indeksu prestiżu UCI oraz rankingu drużyny',
      child: SizedBox(
        height: 230,
        child: _ReputationLineChart(history: snapshot.reputationHistory),
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          pillarsSection,
          const SizedBox(height: 16),
          historyChartSection,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: isTablet ? 6 : 7, child: pillarsSection),
        const SizedBox(width: 16),
        Expanded(flex: 5, child: historyChartSection),
      ],
    );
  }

  Widget _buildLifetimeStatsTab(
    ManagerProfileSnapshot snapshot, {
    required bool isMobile,
    required bool isTablet,
    required double contentWidth,
  }) {
    final stats = _scopedStats(snapshot.lifetimeStats);
    final kpis = [
      _KpiItem(
        title: 'Zwycięstwa łącznie',
        value: '${stats.totalVictories}',
        subtitle: '${stats.stageWins} etapowych • ${stats.oneDayWins} klasyków',
        icon: Icons.emoji_events_rounded,
        color: AppColors.goldAccent,
      ),
      _KpiItem(
        title: 'Wielkie Toury & Monumenty',
        value: '${stats.grandTourTitles} GT / ${stats.monumentWins} Mon.',
        subtitle: '${stats.leaderJerseyDays} dni w koszulkach lidera',
        icon: Icons.military_tech_rounded,
        color: AppColors.primaryAccent,
      ),
      _KpiItem(
        title: 'Miejsca na Podium',
        value: '${stats.podiumFinishes}',
        subtitle: '${stats.totalRaceDays} dni wyścigowych',
        icon: Icons.leaderboard_rounded,
        color: AppColors.accentBlue,
      ),
      _KpiItem(
        title: 'Zdobyte Nagrody (Prize Money)',
        value: Formatters.formatCurrency(stats.totalPrizeMoneyEur),
        subtitle: '${stats.negotiationWinRatePct}% skuteczności negocjacji',
        icon: Icons.euro_rounded,
        color: AppColors.statusSuccess,
      ),
    ];

    final columns = isMobile ? 2 : (isTablet ? 2 : 4);
    const spacing = 12.0;
    final tileWidth =
        ((contentWidth - spacing * (columns - 1)) / columns).clamp(140.0, 420.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ManagerStatsScopeFilter.values.map((scope) {
            return _InteractiveTabChip(
              label: scope.label,
              icon: Icons.filter_list_rounded,
              isSelected: _statsScope == scope,
              isDisabled: false,
              compact: true,
              onTap: () => setState(() => _statsScope = scope),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: kpis.map((item) {
            return SizedBox(
              width: tileWidth,
              child: _KpiStatCard(item: item),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Rozkład Zwycięstw według Terenu',
          subtitle: 'Profil specjalizacji taktycznej zespołu pod Twoim kierownictwem',
          child: SizedBox(
            height: 240,
            child: _TerrainVictoriesBarChart(stats: stats),
          ),
        ),
      ],
    );
  }

  ManagerLifetimeStats _scopedStats(ManagerLifetimeStats base) {
    switch (_statsScope) {
      case ManagerStatsScopeFilter.allTime:
        return base;
      case ManagerStatsScopeFilter.currentSeason:
        final div = math.max(1, base.seasonsManaged);
        return ManagerLifetimeStats(
          seasonsManaged: 1,
          totalRaceDays: (base.totalRaceDays / div).round(),
          stageWins: math.max(1, (base.stageWins / div).round()),
          oneDayWins: (base.oneDayWins / div).round(),
          monumentWins: base.monumentWins > 0 ? 1 : 0,
          grandTourTitles: base.grandTourTitles > 0 ? 1 : 0,
          leaderJerseyDays: (base.leaderJerseyDays / div).round(),
          podiumFinishes: (base.podiumFinishes / div).round(),
          totalPrizeMoneyEur: (base.totalPrizeMoneyEur / div).round(),
          tacticalEfficiencyPct: base.tacticalEfficiencyPct,
          negotiationWinRatePct: base.negotiationWinRatePct,
          flatWins: math.max(0, (base.flatWins / div).round()),
          hillsWins: math.max(0, (base.hillsWins / div).round()),
          mountainWins: math.max(0, (base.mountainWins / div).round()),
          cobbleWins: math.max(0, (base.cobbleWins / div).round()),
          timeTrialWins: math.max(0, (base.timeTrialWins / div).round()),
        );
      case ManagerStatsScopeFilter.grandTours:
        return ManagerLifetimeStats(
          seasonsManaged: base.seasonsManaged,
          totalRaceDays: base.seasonsManaged * 21,
          stageWins: (base.stageWins * 0.55).round(),
          oneDayWins: 0,
          monumentWins: 0,
          grandTourTitles: base.grandTourTitles,
          leaderJerseyDays: base.leaderJerseyDays,
          podiumFinishes: (base.podiumFinishes * 0.45).round(),
          totalPrizeMoneyEur: (base.totalPrizeMoneyEur * 0.65).round(),
          tacticalEfficiencyPct: base.tacticalEfficiencyPct,
          negotiationWinRatePct: base.negotiationWinRatePct,
          flatWins: (base.flatWins * 0.6).round(),
          hillsWins: (base.hillsWins * 0.4).round(),
          mountainWins: (base.mountainWins * 0.7).round(),
          cobbleWins: (base.cobbleWins * 0.2).round(),
          timeTrialWins: (base.timeTrialWins * 0.6).round(),
        );
      case ManagerStatsScopeFilter.monuments:
        return ManagerLifetimeStats(
          seasonsManaged: base.seasonsManaged,
          totalRaceDays: base.seasonsManaged * 5,
          stageWins: 0,
          oneDayWins: base.monumentWins,
          monumentWins: base.monumentWins,
          grandTourTitles: 0,
          leaderJerseyDays: 0,
          podiumFinishes: math.max(base.monumentWins, base.monumentWins * 2),
          totalPrizeMoneyEur: base.monumentWins * 35000,
          tacticalEfficiencyPct: base.tacticalEfficiencyPct,
          negotiationWinRatePct: base.negotiationWinRatePct,
          flatWins: 0,
          hillsWins: (base.monumentWins * 0.5).ceil(),
          mountainWins: 0,
          cobbleWins: base.monumentWins ~/ 2,
          timeTrialWins: 0,
        );
    }
  }

  Widget _buildTacticsAndTraitsTab(
    ManagerProfileSnapshot snapshot, {
    required bool isMobile,
    required bool isTablet,
  }) {
    final stanceSection = _SectionCard(
      title: 'Styl Medialny i Zarządzanie Szatnią',
      subtitle: widget.isReadOnly
          ? 'Tryb tylko do odczytu — zmiana stylu zablokowana'
          : 'Wybierz dominującą postawę na konferencjach prasowych',
      child: Column(
        children: ManagerMediaStance.values.map((stance) {
          final isSelected = _mediaStance == stance;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _MediaStanceOptionTile(
              stance: stance,
              isSelected: isSelected,
              isDisabled: widget.isReadOnly,
              onTap: widget.isReadOnly
                  ? null
                  : () {
                      setState(() => _mediaStance = stance);
                      widget.onMediaStanceChanged?.call(stance);
                    },
            ),
          );
        }).toList(),
      ),
    );

    final traitsSection = _SectionCard(
      title: 'Cechy i Specjalizacje Menedżerskie',
      subtitle: 'Pasywne premie odblokowywane poprzez wyniki na trasie',
      child: Column(
        children: snapshot.traits.map((trait) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _TraitBadgeTile(trait: trait),
          );
        }).toList(),
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          stanceSection,
          const SizedBox(height: 16),
          traitsSection,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: isTablet ? 5 : 5, child: stanceSection),
        const SizedBox(width: 16),
        Expanded(flex: 6, child: traitsSection),
      ],
    );
  }

  Widget _buildMilestonesTab(
    ManagerProfileSnapshot snapshot, {
    required bool isMobile,
  }) {
    final visibleMilestones = _onlyMajorMilestones
        ? snapshot.milestones.where((m) => m.isMajorHighlight).toList()
        : snapshot.milestones;

    return _SectionCard(
      title: 'Kamienie Milowe i Kronika Kariery',
      subtitle: 'Najważniejsze momenty budujące dziedzictwo dyrektora sportowego',
      trailing: _InteractiveTabChip(
        label: 'Tylko kluczowe',
        icon: Icons.star_rounded,
        isSelected: _onlyMajorMilestones,
        isDisabled: false,
        compact: true,
        onTap: () =>
            setState(() => _onlyMajorMilestones = !_onlyMajorMilestones),
      ),
      child: visibleMilestones.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Brak wyróżnionych kamieni milowych dla wybranego filtra.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          : Column(
              children: visibleMilestones.map((milestone) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _MilestoneTimelineTile(milestone: milestone),
                );
              }).toList(),
            ),
    );
  }
}

// ============================================================================
// KOMPONENTY POMOCNICZE UI (Stany hover / active / disabled / focus)
// ============================================================================

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
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

class _MiniKpi extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniKpi({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _InteractiveTabChip extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isDisabled;
  final bool compact;
  final VoidCallback? onTap;

  const _InteractiveTabChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.isDisabled,
    required this.compact,
    required this.onTap,
  });

  @override
  State<_InteractiveTabChip> createState() => _InteractiveTabChipState();
}

class _InteractiveTabChipState extends State<_InteractiveTabChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDisabled
        ? AppColors.surface.withValues(alpha: 0.4)
        : widget.isSelected
            ? AppColors.primaryAccent.withValues(alpha: 0.25)
            : _hovered
                ? AppColors.surfaceLight
                : AppColors.surface;
    final borderColor = _focused
        ? AppColors.goldAccent
        : widget.isSelected
            ? AppColors.goldAccent
            : _hovered
                ? AppColors.textSecondary.withValues(alpha: 0.45)
                : AppTheme.borderColor;
    final contentColor = widget.isDisabled
        ? AppColors.textSecondary.withValues(alpha: 0.45)
        : widget.isSelected
            ? AppColors.goldAccent
            : AppColors.textPrimary;

    return FocusableActionDetector(
      enabled: !widget.isDisabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: InkWell(
        onTap: widget.isDisabled ? null : widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 12 : 14,
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
              Icon(widget.icon, size: 15, color: contentColor),
              const SizedBox(width: 7),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: widget.compact ? 12 : 13,
                  fontWeight:
                      widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: contentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InteractiveIconChip extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool isDisabled;
  final VoidCallback? onTap;

  const _InteractiveIconChip({
    required this.icon,
    required this.tooltip,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  State<_InteractiveIconChip> createState() => _InteractiveIconChipState();
}

class _InteractiveIconChipState extends State<_InteractiveIconChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: FocusableActionDetector(
        enabled: !widget.isDisabled,
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        child: InkWell(
          onTap: widget.isDisabled ? null : widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _hovered ? AppColors.surfaceLight : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _focused ? AppColors.goldAccent : AppTheme.borderColor,
              ),
            ),
            child: Icon(
              widget.icon,
              size: 18,
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

class _InteractiveActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final bool isDisabled;
  final VoidCallback? onPressed;

  const _InteractiveActionButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.isDisabled,
    required this.onPressed,
  });

  @override
  State<_InteractiveActionButton> createState() =>
      _InteractiveActionButtonState();
}

class _InteractiveActionButtonState extends State<_InteractiveActionButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final baseBg = widget.isPrimary ? AppColors.primaryAccent : AppColors.surfaceLight;
    final bg = widget.isDisabled
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : _hovered
            ? baseBg.withValues(alpha: 0.85)
            : baseBg;

    return FocusableActionDetector(
      enabled: !widget.isDisabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: InkWell(
        onTap: widget.isDisabled ? null : widget.onPressed,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focused
                  ? AppColors.goldAccent
                  : widget.isPrimary
                      ? AppColors.goldAccent.withValues(alpha: 0.6)
                      : AppTheme.borderColor,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: widget.isDisabled
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: widget.isDisabled
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReputationPillarTile extends StatefulWidget {
  final ManagerReputationPillar pillar;
  final bool isSelected;
  final VoidCallback onTap;

  const _ReputationPillarTile({
    required this.pillar,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ReputationPillarTile> createState() => _ReputationPillarTileState();
}

class _ReputationPillarTileState extends State<_ReputationPillarTile> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.pillar;
    final deltaPrefix = p.seasonDelta >= 0 ? '+' : '';
    final deltaColor =
        p.seasonDelta >= 0 ? AppColors.statusSuccess : AppColors.crimsonAlert;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.isSelected || _hovered
                ? AppColors.surfaceLight
                : AppColors.background.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focused || widget.isSelected
                  ? AppColors.goldAccent
                  : AppTheme.borderColor,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(p.icon, size: 17, color: p.accentColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      p.title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '$deltaPrefix${p.seasonDelta} sez.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: deltaColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${p.score}/100',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (p.score / 100.0).clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: AppColors.surface,
                  valueColor: AlwaysStoppedAnimation<Color>(p.accentColor),
                ),
              ),
              if (widget.isSelected) ...[
                const SizedBox(height: 8),
                Text(
                  '${p.subtitle}. ${p.impactDescription}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReputationLineChart extends StatelessWidget {
  final List<ManagerSeasonReputationPoint> history;

  const _ReputationLineChart({required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const Center(
        child: Text(
          'Brak danych historycznych reputacji.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    final spots = history
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.reputation.toDouble()))
        .toList();

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 100,
        gridData: FlGridData(
          show: true,
          horizontalInterval: 25,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => const FlLine(
            color: AppTheme.borderColor,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 25,
              reservedSize: 34,
              getTitlesWidget: (value, _) => Text(
                '${value.toInt()}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 28,
              getTitlesWidget: (value, _) {
                final idx = value.toInt();
                if (idx < 0 || idx >= history.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${history[idx].seasonYear}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.goldAccent,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                radius: 4.5,
                color: AppColors.goldAccent,
                strokeWidth: 2,
                strokeColor: AppColors.background,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.goldAccent.withValues(alpha: 0.14),
            ),
          ),
        ],
      ),
    );
  }
}

class _TerrainVictoriesBarChart extends StatelessWidget {
  final ManagerLifetimeStats stats;

  const _TerrainVictoriesBarChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = <(String, int, Color)>[
      ('Płaskie', stats.flatWins, AppColors.accentBlue),
      ('Pagórki', stats.hillsWins, AppColors.statusSuccess),
      ('Góry HC', stats.mountainWins, AppColors.goldAccent),
      ('Bruk', stats.cobbleWins, AppColors.amberWarning),
      ('Czasówki', stats.timeTrialWins, AppColors.primaryAccent),
    ];

    final maxVal = items.fold<int>(
      4,
      (prev, el) => math.max(prev, el.$2),
    );

    return BarChart(
      BarChartData(
        maxY: (maxVal * 1.25).ceilToDouble(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => const FlLine(
            color: AppTheme.borderColor,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, _) => Text(
                '${value.toInt()}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, _) {
                final idx = value.toInt();
                if (idx < 0 || idx >= items.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    items[idx].$1,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: items.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.$2.toDouble(),
                width: 22,
                color: entry.value.$3,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _KpiItem {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _KpiItem({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class _KpiStatCard extends StatelessWidget {
  final _KpiItem item;

  const _KpiStatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(item.icon, size: 16, color: item.color),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaStanceOptionTile extends StatefulWidget {
  final ManagerMediaStance stance;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback? onTap;

  const _MediaStanceOptionTile({
    required this.stance,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  State<_MediaStanceOptionTile> createState() => _MediaStanceOptionTileState();
}

class _MediaStanceOptionTileState extends State<_MediaStanceOptionTile> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.stance;
    final borderColor = _focused
        ? AppColors.goldAccent
        : widget.isSelected
            ? AppColors.goldAccent
            : _hovered && !widget.isDisabled
                ? AppColors.textSecondary.withValues(alpha: 0.45)
                : AppTheme.borderColor;

    return FocusableActionDetector(
      enabled: !widget.isDisabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: InkWell(
        onTap: widget.isDisabled ? null : widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.primaryAccent.withValues(alpha: 0.2)
                : _hovered && !widget.isDisabled
                    ? AppColors.surfaceLight
                    : AppColors.background.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Icon(
                s.icon,
                size: 18,
                color: widget.isDisabled
                    ? AppColors.textSecondary.withValues(alpha: 0.45)
                    : widget.isSelected
                        ? AppColors.goldAccent
                        : AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.label,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: widget.isDisabled
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.effectSummary,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.isSelected)
                const Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: AppColors.goldAccent,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TraitBadgeTile extends StatelessWidget {
  final ManagerTraitBadge trait;

  const _TraitBadgeTile({required this.trait});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: trait.isUnlocked
              ? trait.accentColor.withValues(alpha: 0.5)
              : AppTheme.borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                trait.icon,
                size: 18,
                color: trait.isUnlocked
                    ? trait.accentColor
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  trait.title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: trait.isUnlocked
                      ? AppColors.statusSuccess.withValues(alpha: 0.16)
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  trait.isUnlocked ? 'Aktywna' : 'W toku',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: trait.isUnlocked
                        ? AppColors.statusSuccess
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            trait.description,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            trait.bonusLabel,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: trait.isUnlocked
                  ? trait.accentColor
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: trait.progressRatio.clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                trait.isUnlocked ? trait.accentColor : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MilestoneTimelineTile extends StatelessWidget {
  final ManagerCareerMilestone milestone;

  const _MilestoneTimelineTile({required this.milestone});

  @override
  Widget build(BuildContext context) {
    final accent =
        milestone.isMajorHighlight ? AppColors.goldAccent : AppColors.accentBlue;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: milestone.isMajorHighlight
              ? AppColors.goldAccent.withValues(alpha: 0.45)
              : AppTheme.borderColor,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              milestone.isMajorHighlight
                  ? Icons.emoji_events_rounded
                  : Icons.flag_rounded,
              size: 18,
              color: accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        milestone.title,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      milestone.dateLabel,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  milestone.description,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
