import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import 'historical_records_and_palmares_service.dart';

/// 5-poziomowa klasyfikacja legend w Piramidzie Wszech Czasów (All-Time GOAT Pyramid).
enum GoatTier {
  risingLegend(
    level: 1,
    displayName: 'Wschodząca Legenda',
    englishName: 'Rising Legend',
    minScore: 0,
    subtitle: 'Pierwsze triumfy WorldTour i ślad w historii peletonu',
    accentColor: AppColors.statusSuccess,
  ),
  eraContender(
    level: 2,
    displayName: 'Pretendent Epoki',
    englishName: 'Era Contender',
    minScore: 1500,
    subtitle: 'Uznany zwycięzca etapów Grand Tour i klasyków',
    accentColor: AppColors.accentBlue,
  ),
  monumentalIcon(
    level: 3,
    displayName: 'Ikona Monumentów',
    englishName: 'Monumental Icon',
    minScore: 4000,
    subtitle: 'Wielokrotny triumfator Monumentów lub lider Wielkich Tourów',
    accentColor: AppColors.primaryAccent,
  ),
  pantheonTitan(
    level: 4,
    displayName: 'Tytan Panteonu',
    englishName: 'Pantheon Titan',
    minScore: 8000,
    subtitle: 'Mistrz wielu Wielkich Tourów, tęczowej koszulki i klasyków',
    accentColor: AppColors.cyanAccent,
  ),
  immortalApex(
    level: 5,
    displayName: 'Nieśmiertelny Szczyt',
    englishName: 'Immortal Apex',
    minScore: 14000,
    subtitle: 'Absolutny panteon G.O.A.T. — niedościgniony wzorzec wszech czasów',
    accentColor: AppColors.goldAccent,
  );

  final int level;
  final String displayName;
  final String englishName;
  final int minScore;
  final String subtitle;
  final Color accentColor;

  const GoatTier({
    required this.level,
    required this.displayName,
    required this.englishName,
    required this.minScore,
    required this.subtitle,
    required this.accentColor,
  });

  /// Wyznacza poziom w piramidzie na podstawie punktacji GOAT.
  static GoatTier fromScore(int score) {
    if (score >= immortalApex.minScore) return immortalApex;
    if (score >= pantheonTitan.minScore) return pantheonTitan;
    if (score >= monumentalIcon.minScore) return monumentalIcon;
    if (score >= eraContender.minScore) return eraContender;
    return risingLegend;
  }

  /// Następny poziom w piramidzie (lub null dla najwyższego piętra).
  GoatTier? get nextTier {
    switch (this) {
      case GoatTier.risingLegend:
        return GoatTier.eraContender;
      case GoatTier.eraContender:
        return GoatTier.monumentalIcon;
      case GoatTier.monumentalIcon:
        return GoatTier.pantheonTitan;
      case GoatTier.pantheonTitan:
        return GoatTier.immortalApex;
      case GoatTier.immortalApex:
        return null;
    }
  }
}

/// Epoka historyczna kolarstwa używana do normalizacji gęstości kalendarza i konkurencji.
enum CyclingEra {
  goldenEra1960_1979(
    displayName: 'Złota Era (1960–1979)',
    shortLabel: '1960–79',
    eraAdjustmentMultiplier: 0.96,
    description: 'Epoka kanibali, wyścigów od wiosny do jesieni bez specjalizacji.',
  ),
  classicEra1980_1999(
    displayName: 'Era Klasyczna (1980–1999)',
    shortLabel: '1980–99',
    eraAdjustmentMultiplier: 1.00,
    description: 'Początek globalizacji peletonu i dominacji specjalistów GT.',
  ),
  modernEra2000_2019(
    displayName: 'Era Nowoczesna (2000–2019)',
    shortLabel: '2000–19',
    eraAdjustmentMultiplier: 1.04,
    description: 'Wysoka specjalizacja, pomiary mocy i pociągi WorldTour.',
  ),
  contemporaryEra2020Plus(
    displayName: 'Era Współczesna (2020+)',
    shortLabel: '2020+',
    eraAdjustmentMultiplier: 1.08,
    description: 'Najwyższa głębia stawki, całoroczny kalendarz i wyścigi na waty/kg.',
  );

  final String displayName;
  final String shortLabel;
  final double eraAdjustmentMultiplier;
  final String description;

  const CyclingEra({
    required this.displayName,
    required this.shortLabel,
    required this.eraAdjustmentMultiplier,
    required this.description,
  });

  /// Określa epokę na podstawie roku szczytu kariery.
  static CyclingEra fromPeakYear(int year) {
    if (year < 1980) return CyclingEra.goldenEra1960_1979;
    if (year < 2000) return CyclingEra.classicEra1980_1999;
    if (year < 2020) return CyclingEra.modernEra2000_2019;
    return CyclingEra.contemporaryEra2020Plus;
  }
}

/// Szczegółowy rozkład punktacji wieloletniej `All-Time Goat Score`.
class GoatScoreBreakdown {
  final String riderId;
  final String riderName;
  final String nationalityIso;
  final CyclingEra era;
  final int activeSeasons;
  final int grandTourGcScore;
  final int monumentAndClassicScore;
  final int championshipAndOlympicScore;
  final int stageAndJerseyScore;
  final int longevityAndDominanceScore;
  final int milestoneBonusScore;
  final int rawTotalScore;
  final int eraAdjustedTotalScore;
  final double normalizedIndex100;
  final GoatTier tier;
  final bool hasTripleCrownSameYear;
  final bool hasGrandTourGcGrandSlam;
  final bool hasMonumentsGrandSlam;
  final bool hasGrandTourStageTrifecta;

  const GoatScoreBreakdown({
    required this.riderId,
    required this.riderName,
    required this.nationalityIso,
    required this.era,
    required this.activeSeasons,
    required this.grandTourGcScore,
    required this.monumentAndClassicScore,
    required this.championshipAndOlympicScore,
    required this.stageAndJerseyScore,
    required this.longevityAndDominanceScore,
    required this.milestoneBonusScore,
    required this.rawTotalScore,
    required this.eraAdjustedTotalScore,
    required this.normalizedIndex100,
    required this.tier,
    required this.hasTripleCrownSameYear,
    required this.hasGrandTourGcGrandSlam,
    required this.hasMonumentsGrandSlam,
    required this.hasGrandTourStageTrifecta,
  });

  /// Zwraca wynik aktywny zależnie od tego, czy włączono normalizację epoki.
  int effectiveScore({required bool useEraAdjustment}) =>
      useEraAdjustment ? eraAdjustedTotalScore : rawTotalScore;

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'riderName': riderName,
        'nationalityIso': nationalityIso,
        'era': era.name,
        'activeSeasons': activeSeasons,
        'grandTourGcScore': grandTourGcScore,
        'monumentAndClassicScore': monumentAndClassicScore,
        'championshipAndOlympicScore': championshipAndOlympicScore,
        'stageAndJerseyScore': stageAndJerseyScore,
        'longevityAndDominanceScore': longevityAndDominanceScore,
        'milestoneBonusScore': milestoneBonusScore,
        'rawTotalScore': rawTotalScore,
        'eraAdjustedTotalScore': eraAdjustedTotalScore,
        'normalizedIndex100': normalizedIndex100,
        'tier': tier.name,
        'hasTripleCrownSameYear': hasTripleCrownSameYear,
        'hasGrandTourGcGrandSlam': hasGrandTourGcGrandSlam,
        'hasMonumentsGrandSlam': hasMonumentsGrandSlam,
        'hasGrandTourStageTrifecta': hasGrandTourStageTrifecta,
      };
}

/// Profil historycznej legendy peletonu do porównań Hall of Fame.
class HistoricLegendProfile {
  final String id;
  final String name;
  final String nickname;
  final String nationalityIso;
  final CyclingEra era;
  final int careerStartYear;
  final int careerEndYear;
  final int peakYear;
  final bool isRetired;
  final String specialty;
  final String signatureAchievement;
  final int olympicGoldWins;
  final int hourRecordCount;
  final bool hasTripleCrownSameYear;
  final RiderPalmares palmares;

  const HistoricLegendProfile({
    required this.id,
    required this.name,
    required this.nickname,
    required this.nationalityIso,
    required this.era,
    required this.careerStartYear,
    required this.careerEndYear,
    required this.peakYear,
    required this.isRetired,
    required this.specialty,
    required this.signatureAchievement,
    this.olympicGoldWins = 0,
    this.hourRecordCount = 0,
    this.hasTripleCrownSameYear = false,
    required this.palmares,
  });

  int get activeSeasons => math.max(1, careerEndYear - careerStartYear + 1);
  String get careerSpanLabel =>
      isRetired ? '$careerStartYear–$careerEndYear' : '$careerStartYear–obecnie';
}

/// Porównanie pojedynczej kategorii pomiędzy dwoma kolarzami.
class GoatCategoryComparison {
  final String categoryId;
  final String label;
  final int primaryScore;
  final int secondaryScore;

  const GoatCategoryComparison({
    required this.categoryId,
    required this.label,
    required this.primaryScore,
    required this.secondaryScore,
  });

  int get delta => primaryScore - secondaryScore;

  /// Zwraca udział pierwszego kolarza w sumie obu wyników (0.0..1.0).
  double get primaryShare {
    final total = primaryScore + secondaryScore;
    if (total <= 0) return 0.5;
    return (primaryScore / total).clamp(0.0, 1.0);
  }

  /// Zwraca -1 dla wygranej drugiego, 0 dla remisu, 1 dla wygranej pierwszego.
  int get winnerSign {
    if (primaryScore > secondaryScore) return 1;
    if (secondaryScore > primaryScore) return -1;
    return 0;
  }
}

/// Pełny raport porównawczy H2H między dwoma zawodnikami lub legendami.
class LegendComparisonReport {
  final GoatScoreBreakdown primary;
  final GoatScoreBreakdown secondary;
  final bool eraAdjusted;
  final List<GoatCategoryComparison> categories;
  final int scoreDelta;
  final double percentageAdvantage;
  final String verdictHeadline;
  final String verdictDetail;

  const LegendComparisonReport({
    required this.primary,
    required this.secondary,
    required this.eraAdjusted,
    required this.categories,
    required this.scoreDelta,
    required this.percentageAdvantage,
    required this.verdictHeadline,
    required this.verdictDetail,
  });
}

/// Pozycja w zintegrowanym Rankingu Wszech Czasów (aktywni + legendy).
class AllTimeHallOfFameLeaderboardEntry {
  final int rank;
  final String riderId;
  final String riderName;
  final String nickname;
  final String nationalityIso;
  final CyclingEra era;
  final bool isRetired;
  final bool isCareerRider;
  final String specialty;
  final String signatureAchievement;
  final GoatScoreBreakdown breakdown;
  final int effectiveScore;
  final int gapToLeader;
  final int gapToNextRank;

  const AllTimeHallOfFameLeaderboardEntry({
    required this.rank,
    required this.riderId,
    required this.riderName,
    required this.nickname,
    required this.nationalityIso,
    required this.era,
    required this.isRetired,
    required this.isCareerRider,
    required this.specialty,
    required this.signatureAchievement,
    required this.breakdown,
    required this.effectiveScore,
    required this.gapToLeader,
    required this.gapToNextRank,
  });
}

/// Projekcja zysku punktowego GOAT po zdobyciu kolejnego trofeum.
class GoatMilestoneProjection {
  final String milestoneTitle;
  final int pointsGain;
  final int projectedScore;
  final GoatTier projectedTier;
  final bool promotesTier;

  const GoatMilestoneProjection({
    required this.milestoneTitle,
    required this.pointsGain,
    required this.projectedScore,
    required this.projectedTier,
    required this.promotesTier,
  });
}

/// Katalog wbudowanych legend historycznych kolarstwa.
class HistoricLegendsCatalog {
  HistoricLegendsCatalog._();

  static const List<HistoricLegendProfile> legends = [
    HistoricLegendProfile(
      id: 'legend_eddy_merckx',
      name: 'Eddy Merckx',
      nickname: 'Kanibal',
      nationalityIso: 'BEL',
      era: CyclingEra.goldenEra1960_1979,
      careerStartYear: 1965,
      careerEndYear: 1978,
      peakYear: 1972,
      isRetired: true,
      specialty: 'Wszechstronny Dominator',
      signatureAchievement: '11 Grand Tourów, 19 Monumentów, 3x MŚ, Potrójna Korona 1974',
      hourRecordCount: 1,
      hasTripleCrownSameYear: true,
      palmares: RiderPalmares(
        riderId: 'legend_eddy_merckx',
        riderName: 'Eddy Merckx',
        nationalityIso: 'BEL',
        grandTourOverallWins: 11,
        tourDeFranceGcWins: 5,
        giroDItaliaGcWins: 5,
        vueltaAEspanaGcWins: 1,
        grandTourStageWins: 64,
        tourDeFranceStageWins: 34,
        giroStageWins: 24,
        vueltaStageWins: 6,
        monumentWins: 19,
        milanoSanRemoWins: 7,
        rondeVanVlaanderenWins: 2,
        parisRoubaixWins: 3,
        liegeBastogneLiegeWins: 5,
        ilLombardiaWins: 2,
        worldChampionshipRoadWins: 3,
        daysInYellowJersey: 96,
        daysInPinkJersey: 78,
        daysInRedJersey: 6,
        pointsClassificationsWon: 5,
        komClassificationsWon: 3,
        otherWorldTourWins: 35,
        totalCareerVictories: 279,
      ),
    ),
    HistoricLegendProfile(
      id: 'legend_bernard_hinault',
      name: 'Bernard Hinault',
      nickname: 'Borsuk',
      nationalityIso: 'FRA',
      era: CyclingEra.classicEra1980_1999,
      careerStartYear: 1975,
      careerEndYear: 1986,
      peakYear: 1982,
      isRetired: true,
      specialty: 'Wielkie Toury & Klasyki',
      signatureAchievement: '10 Grand Tourów (min. 2x każdy) i 5 Monumentów',
      palmares: RiderPalmares(
        riderId: 'legend_bernard_hinault',
        riderName: 'Bernard Hinault',
        nationalityIso: 'FRA',
        grandTourOverallWins: 10,
        tourDeFranceGcWins: 5,
        giroDItaliaGcWins: 3,
        vueltaAEspanaGcWins: 2,
        grandTourStageWins: 41,
        tourDeFranceStageWins: 28,
        giroStageWins: 6,
        vueltaStageWins: 7,
        monumentWins: 5,
        rondeVanVlaanderenWins: 0,
        milanoSanRemoWins: 0,
        parisRoubaixWins: 1,
        liegeBastogneLiegeWins: 2,
        ilLombardiaWins: 2,
        worldChampionshipRoadWins: 1,
        daysInYellowJersey: 75,
        daysInPinkJersey: 31,
        daysInRedJersey: 16,
        pointsClassificationsWon: 1,
        komClassificationsWon: 2,
        otherWorldTourWins: 22,
        totalCareerVictories: 144,
      ),
    ),
    HistoricLegendProfile(
      id: 'legend_tadej_pogacar',
      name: 'Tadej Pogačar',
      nickname: 'Słoweński Fenomen',
      nationalityIso: 'SLO',
      era: CyclingEra.contemporaryEra2020Plus,
      careerStartYear: 2019,
      careerEndYear: 2026,
      peakYear: 2024,
      isRetired: false,
      specialty: 'Grand Tour & Monumenty',
      signatureAchievement: 'Potrójna Korona 2024 (Giro + TdF + MŚ) i 7 Monumentów',
      hasTripleCrownSameYear: true,
      palmares: RiderPalmares(
        riderId: 'legend_tadej_pogacar',
        riderName: 'Tadej Pogačar',
        nationalityIso: 'SLO',
        grandTourOverallWins: 5,
        tourDeFranceGcWins: 4,
        giroDItaliaGcWins: 1,
        vueltaAEspanaGcWins: 0,
        grandTourStageWins: 26,
        tourDeFranceStageWins: 17,
        giroStageWins: 6,
        vueltaStageWins: 3,
        monumentWins: 7,
        milanoSanRemoWins: 0,
        rondeVanVlaanderenWins: 1,
        parisRoubaixWins: 0,
        liegeBastogneLiegeWins: 2,
        ilLombardiaWins: 4,
        worldChampionshipRoadWins: 1,
        daysInYellowJersey: 40,
        daysInPinkJersey: 20,
        pointsClassificationsWon: 0,
        komClassificationsWon: 3,
        youthClassificationsWon: 4,
        otherWorldTourWins: 24,
        totalCareerVictories: 88,
      ),
    ),
    HistoricLegendProfile(
      id: 'legend_jacques_anquetil',
      name: 'Jacques Anquetil',
      nickname: 'Monsieur Chrono',
      nationalityIso: 'FRA',
      era: CyclingEra.goldenEra1960_1979,
      careerStartYear: 1953,
      careerEndYear: 1969,
      peakYear: 1963,
      isRetired: true,
      specialty: 'Jazda na czas & Grand Toury',
      signatureAchievement: 'Pierwszy 5-krotny zwycięzca Tour de France i Triple Crown GT',
      hourRecordCount: 1,
      palmares: RiderPalmares(
        riderId: 'legend_jacques_anquetil',
        riderName: 'Jacques Anquetil',
        nationalityIso: 'FRA',
        grandTourOverallWins: 8,
        tourDeFranceGcWins: 5,
        giroDItaliaGcWins: 2,
        vueltaAEspanaGcWins: 1,
        grandTourStageWins: 23,
        tourDeFranceStageWins: 16,
        giroStageWins: 6,
        vueltaStageWins: 1,
        monumentWins: 1,
        liegeBastogneLiegeWins: 1,
        daysInYellowJersey: 50,
        daysInPinkJersey: 42,
        daysInRedJersey: 16,
        otherWorldTourWins: 18,
        totalCareerVictories: 132,
      ),
    ),
    HistoricLegendProfile(
      id: 'legend_fausto_coppi',
      name: 'Fausto Coppi',
      nickname: 'Il Campionissimo',
      nationalityIso: 'ITA',
      era: CyclingEra.goldenEra1960_1979,
      careerStartYear: 1939,
      careerEndYear: 1959,
      peakYear: 1952,
      isRetired: true,
      specialty: 'Góral & Klasyki',
      signatureAchievement: '5x Giro d\'Italia, 2x TdF, 9 Monumentów i Rekord Godzinny',
      hourRecordCount: 1,
      palmares: RiderPalmares(
        riderId: 'legend_fausto_coppi',
        riderName: 'Fausto Coppi',
        nationalityIso: 'ITA',
        grandTourOverallWins: 7,
        tourDeFranceGcWins: 2,
        giroDItaliaGcWins: 5,
        vueltaAEspanaGcWins: 0,
        grandTourStageWins: 31,
        tourDeFranceStageWins: 9,
        giroStageWins: 22,
        monumentWins: 9,
        milanoSanRemoWins: 3,
        parisRoubaixWins: 1,
        ilLombardiaWins: 5,
        worldChampionshipRoadWins: 1,
        daysInYellowJersey: 19,
        daysInPinkJersey: 31,
        komClassificationsWon: 5,
        otherWorldTourWins: 16,
        totalCareerVictories: 118,
      ),
    ),
    HistoricLegendProfile(
      id: 'legend_miguel_indurain',
      name: 'Miguel Induráin',
      nickname: 'Big Mig',
      nationalityIso: 'ESP',
      era: CyclingEra.classicEra1980_1999,
      careerStartYear: 1984,
      careerEndYear: 1996,
      peakYear: 1994,
      isRetired: true,
      specialty: 'Grand Tour & Czasówka',
      signatureAchievement: '5 Tourów z rzędu, 2x Giro, Złoto Olimpijskie i Rekord Godzinny',
      olympicGoldWins: 1,
      hourRecordCount: 1,
      palmares: RiderPalmares(
        riderId: 'legend_miguel_indurain',
        riderName: 'Miguel Induráin',
        nationalityIso: 'ESP',
        grandTourOverallWins: 7,
        tourDeFranceGcWins: 5,
        giroDItaliaGcWins: 2,
        grandTourStageWins: 16,
        tourDeFranceStageWins: 12,
        giroStageWins: 4,
        worldChampionshipTimeTrialWins: 1,
        daysInYellowJersey: 60,
        daysInPinkJersey: 29,
        otherWorldTourWins: 15,
        totalCareerVictories: 78,
      ),
    ),
    HistoricLegendProfile(
      id: 'legend_sean_kelly',
      name: 'Sean Kelly',
      nickname: 'King Kelly',
      nationalityIso: 'IRL',
      era: CyclingEra.classicEra1980_1999,
      careerStartYear: 1977,
      careerEndYear: 1994,
      peakYear: 1986,
      isRetired: true,
      specialty: 'Klasyki & Tygodniówki',
      signatureAchievement: '9 Monumentów, Vuelta a España, 7x Paris-Nice z rzędu',
      palmares: RiderPalmares(
        riderId: 'legend_sean_kelly',
        riderName: 'Sean Kelly',
        nationalityIso: 'IRL',
        grandTourOverallWins: 1,
        vueltaAEspanaGcWins: 1,
        grandTourStageWins: 21,
        tourDeFranceStageWins: 5,
        vueltaStageWins: 16,
        monumentWins: 9,
        milanoSanRemoWins: 2,
        parisRoubaixWins: 2,
        liegeBastogneLiegeWins: 2,
        ilLombardiaWins: 3,
        daysInYellowJersey: 1,
        daysInRedJersey: 12,
        pointsClassificationsWon: 8,
        otherWorldTourWins: 34,
        totalCareerVictories: 193,
      ),
    ),
    HistoricLegendProfile(
      id: 'legend_roger_de_vlaeminck',
      name: 'Roger De Vlaeminck',
      nickname: 'Monsieur Paris-Roubaix',
      nationalityIso: 'BEL',
      era: CyclingEra.goldenEra1960_1979,
      careerStartYear: 1969,
      careerEndYear: 1984,
      peakYear: 1975,
      isRetired: true,
      specialty: 'Bruk & Monumenty',
      signatureAchievement: 'Wszystkie 5 Monumentów (11 łącznie), w tym 4x Paris-Roubaix',
      palmares: RiderPalmares(
        riderId: 'legend_roger_de_vlaeminck',
        riderName: 'Roger De Vlaeminck',
        nationalityIso: 'BEL',
        grandTourStageWins: 24,
        tourDeFranceStageWins: 1,
        giroStageWins: 22,
        vueltaStageWins: 1,
        monumentWins: 11,
        milanoSanRemoWins: 3,
        rondeVanVlaanderenWins: 1,
        parisRoubaixWins: 4,
        liegeBastogneLiegeWins: 1,
        ilLombardiaWins: 2,
        pointsClassificationsWon: 3,
        otherWorldTourWins: 22,
        totalCareerVictories: 168,
      ),
    ),
    HistoricLegendProfile(
      id: 'legend_fabian_cancellara',
      name: 'Fabian Cancellara',
      nickname: 'Spartakus',
      nationalityIso: 'SUI',
      era: CyclingEra.modernEra2000_2019,
      careerStartYear: 2001,
      careerEndYear: 2016,
      peakYear: 2010,
      isRetired: true,
      specialty: 'Bruk & Czasówka',
      signatureAchievement: '7 Monumentów brukowych, 4x MŚ ITT i 2x Złoto Olimpijskie ITT',
      olympicGoldWins: 2,
      palmares: RiderPalmares(
        riderId: 'legend_fabian_cancellara',
        riderName: 'Fabian Cancellara',
        nationalityIso: 'SUI',
        grandTourStageWins: 11,
        tourDeFranceStageWins: 8,
        vueltaStageWins: 3,
        monumentWins: 7,
        rondeVanVlaanderenWins: 3,
        parisRoubaixWins: 3,
        milanoSanRemoWins: 1,
        worldChampionshipTimeTrialWins: 4,
        daysInYellowJersey: 29,
        daysInRedJersey: 5,
        otherWorldTourWins: 18,
        totalCareerVictories: 86,
      ),
    ),
    HistoricLegendProfile(
      id: 'legend_remco_evenepoel',
      name: 'Remco Evenepoel',
      nickname: 'Aerobullet',
      nationalityIso: 'BEL',
      era: CyclingEra.contemporaryEra2020Plus,
      careerStartYear: 2019,
      careerEndYear: 2026,
      peakYear: 2024,
      isRetired: false,
      specialty: 'Czasówka, Klasyki & GT',
      signatureAchievement: 'Podwójny Mistrz Olimpijski 2024 (RR + ITT), MŚ RR & ITT, Vuelta GC',
      olympicGoldWins: 2,
      palmares: RiderPalmares(
        riderId: 'legend_remco_evenepoel',
        riderName: 'Remco Evenepoel',
        nationalityIso: 'BEL',
        grandTourOverallWins: 1,
        vueltaAEspanaGcWins: 1,
        grandTourStageWins: 8,
        tourDeFranceStageWins: 1,
        giroStageWins: 2,
        vueltaStageWins: 5,
        monumentWins: 2,
        liegeBastogneLiegeWins: 2,
        worldChampionshipRoadWins: 1,
        worldChampionshipTimeTrialWins: 2,
        daysInPinkJersey: 3,
        daysInRedJersey: 14,
        youthClassificationsWon: 1,
        otherWorldTourWins: 14,
        totalCareerVictories: 61,
      ),
    ),
  ];
}

/// Serwis obliczania punktacji wieloletniej `All-Time Goat Score` i porównań Hall of Fame.
class HistoricLegendHallOfFameCompareService {
  /// Punkt odniesienia dla indeksu 100.0 (najwyższy historyczny pułap).
  static const double _goatBenchmarkScore = 30000.0;

  const HistoricLegendHallOfFameCompareService();

  /// Oblicza pełny rozkład `All-Time Goat Score` dla podanego `RiderPalmares`.
  GoatScoreBreakdown evaluatePalmares(
    RiderPalmares palmares, {
    CyclingEra era = CyclingEra.contemporaryEra2020Plus,
    int activeSeasons = 6,
    int olympicGoldWins = 0,
    int hourRecordCount = 0,
    bool hasTripleCrownSameYear = false,
  }) {
    final safeSeasons = math.max(1, activeSeasons);

    // 1. Wielkie Toury GC
    final grandTourGcScore = (palmares.tourDeFranceGcWins * 1000) +
        (palmares.giroDItaliaGcWins * 750) +
        (palmares.vueltaAEspanaGcWins * 750);

    // 2. Monumenty i klasyki jednodniowe
    final diversityBonus = palmares.distinctMonumentsWonCount >= 3
        ? (palmares.distinctMonumentsWonCount - 2) * 250
        : 0;
    final monumentAndClassicScore = (palmares.monumentWins * 450) +
        (palmares.otherWorldTourWins * 120) +
        diversityBonus;

    // 3. Mistrzostwa Świata, Igrzyska Olimpijskie i Rekord Godzinny
    final championshipAndOlympicScore =
        (palmares.worldChampionshipRoadWins * 500) +
            (palmares.worldChampionshipTimeTrialWins * 350) +
            (olympicGoldWins * 450) +
            (hourRecordCount * 300);

    // 4. Etapy Grand Tourów i koszulki klasyfikacji
    final stageAndJerseyScore = (palmares.grandTourStageWins * 100) +
        (palmares.daysInYellowJersey * 30) +
        ((palmares.daysInPinkJersey + palmares.daysInRedJersey) * 20) +
        ((palmares.pointsClassificationsWon + palmares.komClassificationsWon) *
            150) +
        (palmares.youthClassificationsWon * 80);

    // 5. Długowieczność i wieloletnia dominacja
    final rawLongevityBase = safeSeasons * 55;
    final consistencyRatio =
        (palmares.totalCareerVictories / safeSeasons).clamp(0.0, 22.0);
    final dominanceConsistencyBonus = (consistencyRatio * 42).round();
    final longevityAndDominanceScore =
        rawLongevityBase + dominanceConsistencyBonus;

    // 6. Historyczne kamienie milowe (Slamy i Potrójne Korony)
    int milestoneBonusScore = 0;
    if (palmares.hasGrandTourGcCareerGrandSlam) milestoneBonusScore += 1500;
    if (palmares.hasGrandTourStageTrifecta) milestoneBonusScore += 300;
    if (palmares.hasMonumentsGrandSlam) milestoneBonusScore += 2000;
    if (hasTripleCrownSameYear) milestoneBonusScore += 1400;

    final rawTotalScore = grandTourGcScore +
        monumentAndClassicScore +
        championshipAndOlympicScore +
        stageAndJerseyScore +
        longevityAndDominanceScore +
        milestoneBonusScore;

    final eraAdjustedTotalScore =
        (rawTotalScore * era.eraAdjustmentMultiplier).round();

    final normalizedIndex100 =
        ((eraAdjustedTotalScore / _goatBenchmarkScore) * 100.0)
            .clamp(0.0, 100.0);

    return GoatScoreBreakdown(
      riderId: palmares.riderId,
      riderName: palmares.riderName,
      nationalityIso: palmares.nationalityIso,
      era: era,
      activeSeasons: safeSeasons,
      grandTourGcScore: grandTourGcScore,
      monumentAndClassicScore: monumentAndClassicScore,
      championshipAndOlympicScore: championshipAndOlympicScore,
      stageAndJerseyScore: stageAndJerseyScore,
      longevityAndDominanceScore: longevityAndDominanceScore,
      milestoneBonusScore: milestoneBonusScore,
      rawTotalScore: rawTotalScore,
      eraAdjustedTotalScore: eraAdjustedTotalScore,
      normalizedIndex100: double.parse(normalizedIndex100.toStringAsFixed(1)),
      tier: GoatTier.fromScore(eraAdjustedTotalScore),
      hasTripleCrownSameYear: hasTripleCrownSameYear,
      hasGrandTourGcGrandSlam: palmares.hasGrandTourGcCareerGrandSlam,
      hasMonumentsGrandSlam: palmares.hasMonumentsGrandSlam,
      hasGrandTourStageTrifecta: palmares.hasGrandTourStageTrifecta,
    );
  }

  /// Oblicza punktację GOAT bezpośrednio z profilu legendy historycznej.
  GoatScoreBreakdown evaluateLegend(HistoricLegendProfile legend) {
    return evaluatePalmares(
      legend.palmares,
      era: legend.era,
      activeSeasons: legend.activeSeasons,
      olympicGoldWins: legend.olympicGoldWins,
      hourRecordCount: legend.hourRecordCount,
      hasTripleCrownSameYear: legend.hasTripleCrownSameYear,
    );
  }

  /// Porównuje dwóch kolarzy we wszystkich wymiarach Hall of Fame.
  LegendComparisonReport compareRiders(
    GoatScoreBreakdown primary,
    GoatScoreBreakdown secondary, {
    bool useEraAdjustment = true,
  }) {
    final pScore = primary.effectiveScore(useEraAdjustment: useEraAdjustment);
    final sScore = secondary.effectiveScore(useEraAdjustment: useEraAdjustment);
    final delta = pScore - sScore;

    final baseDenominator = math.max(1, math.min(pScore, sScore));
    final pctAdv = ((delta.abs() / baseDenominator) * 100.0).clamp(0.0, 999.0);

    final categories = [
      GoatCategoryComparison(
        categoryId: 'gt_gc',
        label: 'Wielkie Toury (GC)',
        primaryScore: primary.grandTourGcScore,
        secondaryScore: secondary.grandTourGcScore,
      ),
      GoatCategoryComparison(
        categoryId: 'monuments',
        label: 'Monumenty & Klasyki',
        primaryScore: primary.monumentAndClassicScore,
        secondaryScore: secondary.monumentAndClassicScore,
      ),
      GoatCategoryComparison(
        categoryId: 'champs',
        label: 'MŚ, IO & Rekordy',
        primaryScore: primary.championshipAndOlympicScore,
        secondaryScore: secondary.championshipAndOlympicScore,
      ),
      GoatCategoryComparison(
        categoryId: 'stages',
        label: 'Etapy & Koszulki',
        primaryScore: primary.stageAndJerseyScore,
        secondaryScore: secondary.stageAndJerseyScore,
      ),
      GoatCategoryComparison(
        categoryId: 'longevity',
        label: 'Wieloletnia Dominacja',
        primaryScore: primary.longevityAndDominanceScore,
        secondaryScore: secondary.longevityAndDominanceScore,
      ),
      GoatCategoryComparison(
        categoryId: 'milestones',
        label: 'Kamienie Milowe (Slam)',
        primaryScore: primary.milestoneBonusScore,
        secondaryScore: secondary.milestoneBonusScore,
      ),
    ];

    final String headline;
    final String detail;
    if (delta == 0) {
      headline = 'Remis Historyczny ($pScore pkt)';
      detail =
          '${primary.riderName} i ${secondary.riderName} zajmują identyczną pozycję w punktacji GOAT.';
    } else if (delta > 0) {
      headline = '${primary.riderName} prowadzi o +$delta pkt';
      detail =
          'Przewaga ${pctAdv.toStringAsFixed(1)}% nad ${secondary.riderName} '
          '(${primary.tier.displayName} vs ${secondary.tier.displayName}).';
    } else {
      headline = '${secondary.riderName} prowadzi o +${delta.abs()} pkt';
      detail =
          '${primary.riderName} traci ${delta.abs()} pkt (${pctAdv.toStringAsFixed(1)}%) '
          'do ${secondary.riderName}.';
    }

    return LegendComparisonReport(
      primary: primary,
      secondary: secondary,
      eraAdjusted: useEraAdjustment,
      categories: categories,
      scoreDelta: delta,
      percentageAdvantage: double.parse(pctAdv.toStringAsFixed(1)),
      verdictHeadline: headline,
      verdictDetail: detail,
    );
  }

  /// Tworzy zintegrowany Ranking Wszech Czasów łączący legendy historyczne i kolarzy z kariery.
  List<AllTimeHallOfFameLeaderboardEntry> buildMergedHallOfFame({
    List<RiderPalmares> careerRiders = const [],
    bool includeHistoricLegends = true,
    bool useEraAdjustment = true,
    GoatTier? filterTier,
    CyclingEra? filterEra,
    String searchQuery = '',
    int careerCurrentYear = 2026,
  }) {
    final rawItems = <({
      String id,
      String name,
      String nickname,
      String iso,
      CyclingEra era,
      bool isRetired,
      bool isCareerRider,
      String specialty,
      String signature,
      GoatScoreBreakdown breakdown,
    })>[];

    final seenIds = <String>{};

    for (final palmares in careerRiders) {
      if (palmares.riderId.isEmpty) continue;
      seenIds.add(palmares.riderId);
      final seasonsCount = palmares.entries.isEmpty
          ? 1
          : palmares.entries.map((e) => e.seasonYear).toSet().length;
      final breakdown = evaluatePalmares(
        palmares,
        era: CyclingEra.fromPeakYear(careerCurrentYear),
        activeSeasons: seasonsCount,
      );
      if (breakdown.rawTotalScore <= 0) continue;
      rawItems.add((
        id: palmares.riderId,
        name: palmares.riderName,
        nickname: 'Kariera Aktywna',
        iso: palmares.nationalityIso,
        era: breakdown.era,
        isRetired: false,
        isCareerRider: true,
        specialty: palmares.grandTourOverallWins > 0
            ? 'Lider Grand Tour'
            : (palmares.monumentWins > 0 ? 'Łowca Klasyków' : 'Zawodowiec WT'),
        signature:
            '${palmares.grandTourOverallWins}x GT • ${palmares.monumentWins}x Mon. • ${palmares.totalCareerVictories} zw.',
        breakdown: breakdown,
      ));
    }

    if (includeHistoricLegends) {
      for (final legend in HistoricLegendsCatalog.legends) {
        if (seenIds.contains(legend.id)) continue;
        final breakdown = evaluateLegend(legend);
        rawItems.add((
          id: legend.id,
          name: legend.name,
          nickname: legend.nickname,
          iso: legend.nationalityIso,
          era: legend.era,
          isRetired: legend.isRetired,
          isCareerRider: false,
          specialty: legend.specialty,
          signature: legend.signatureAchievement,
          breakdown: breakdown,
        ));
      }
    }

    final normalizedQuery = searchQuery.trim().toLowerCase();

    final filtered = rawItems.where((item) {
      if (filterTier != null && item.breakdown.tier != filterTier) {
        return false;
      }
      if (filterEra != null && item.era != filterEra) {
        return false;
      }
      if (normalizedQuery.isNotEmpty) {
        final matchName = item.name.toLowerCase().contains(normalizedQuery);
        final matchNick = item.nickname.toLowerCase().contains(normalizedQuery);
        final matchIso = item.iso.toLowerCase().contains(normalizedQuery);
        if (!matchName && !matchNick && !matchIso) return false;
      }
      return true;
    }).toList();

    filtered.sort((a, b) {
      final scoreA =
          a.breakdown.effectiveScore(useEraAdjustment: useEraAdjustment);
      final scoreB =
          b.breakdown.effectiveScore(useEraAdjustment: useEraAdjustment);
      final cmp = scoreB.compareTo(scoreA);
      if (cmp != 0) return cmp;
      return a.name.compareTo(b.name);
    });

    if (filtered.isEmpty) return const [];

    final leaderScore = filtered.first.breakdown
        .effectiveScore(useEraAdjustment: useEraAdjustment);

    return List<AllTimeHallOfFameLeaderboardEntry>.generate(
      filtered.length,
      (index) {
        final item = filtered[index];
        final score =
            item.breakdown.effectiveScore(useEraAdjustment: useEraAdjustment);
        final prevScore = index == 0
            ? score
            : filtered[index - 1]
                .breakdown
                .effectiveScore(useEraAdjustment: useEraAdjustment);
        return AllTimeHallOfFameLeaderboardEntry(
          rank: index + 1,
          riderId: item.id,
          riderName: item.name,
          nickname: item.nickname,
          nationalityIso: item.iso,
          era: item.era,
          isRetired: item.isRetired,
          isCareerRider: item.isCareerRider,
          specialty: item.specialty,
          signatureAchievement: item.signature,
          breakdown: item.breakdown,
          effectiveScore: score,
          gapToLeader: leaderScore - score,
          gapToNextRank: index == 0 ? 0 : prevScore - score,
        );
      },
    );
  }

  /// Wylicza ile punktów GOAT doda kolejne prestiżowe trofeum.
  List<GoatMilestoneProjection> nextMilestoneRecommendations(
    GoatScoreBreakdown current, {
    bool useEraAdjustment = true,
  }) {
    final baseScore =
        current.effectiveScore(useEraAdjustment: useEraAdjustment);
    final mult = useEraAdjustment ? current.era.eraAdjustmentMultiplier : 1.0;

    final candidates = <({String title, int rawGain})>[
      (title: 'Zwycięstwo w Tour de France (GC)', rawGain: 1000),
      (title: 'Mistrzostwo Świata ze startu wspólnego', rawGain: 500),
      (title: 'Zwycięstwo w Monumencie', rawGain: 450),
      (title: 'Złoty Medal Olimpijski', rawGain: 450),
      (title: 'Etap Grand Touru', rawGain: 100),
    ];

    return candidates.map((c) {
      final adjustedGain = (c.rawGain * mult).round();
      final projected = baseScore + adjustedGain;
      final projectedTier = GoatTier.fromScore(projected);
      return GoatMilestoneProjection(
        milestoneTitle: c.title,
        pointsGain: adjustedGain,
        projectedScore: projected,
        projectedTier: projectedTier,
        promotesTier: projectedTier.level > current.tier.level,
      );
    }).toList();
  }
}

/// Stan modułu porównywania legend i rankingu All-Time GOAT.
class HistoricLegendCompareState {
  final bool useEraAdjustment;
  final GoatTier? filterTier;
  final CyclingEra? filterEra;
  final String searchQuery;
  final String primaryRiderId;
  final String secondaryRiderId;
  final List<RiderPalmares> careerPalmares;

  const HistoricLegendCompareState({
    this.useEraAdjustment = true,
    this.filterTier,
    this.filterEra,
    this.searchQuery = '',
    this.primaryRiderId = 'legend_tadej_pogacar',
    this.secondaryRiderId = 'legend_eddy_merckx',
    this.careerPalmares = const [],
  });

  HistoricLegendCompareState copyWith({
    bool? useEraAdjustment,
    GoatTier? filterTier,
    bool clearTierFilter = false,
    CyclingEra? filterEra,
    bool clearEraFilter = false,
    String? searchQuery,
    String? primaryRiderId,
    String? secondaryRiderId,
    List<RiderPalmares>? careerPalmares,
  }) {
    return HistoricLegendCompareState(
      useEraAdjustment: useEraAdjustment ?? this.useEraAdjustment,
      filterTier: clearTierFilter ? null : (filterTier ?? this.filterTier),
      filterEra: clearEraFilter ? null : (filterEra ?? this.filterEra),
      searchQuery: searchQuery ?? this.searchQuery,
      primaryRiderId: primaryRiderId ?? this.primaryRiderId,
      secondaryRiderId: secondaryRiderId ?? this.secondaryRiderId,
      careerPalmares: careerPalmares ?? this.careerPalmares,
    );
  }
}

/// Notifier zarządzający stanem rankingu All-Time GOAT i porównania H2H.
class HistoricLegendCompareNotifier
    extends StateNotifier<HistoricLegendCompareState> {
  final HistoricLegendHallOfFameCompareService _service;

  HistoricLegendCompareNotifier({
    HistoricLegendHallOfFameCompareService? service,
  })  : _service = service ?? const HistoricLegendHallOfFameCompareService(),
        super(const HistoricLegendCompareState());

  void toggleEraAdjustment(bool value) {
    state = state.copyWith(useEraAdjustment: value);
  }

  void setTierFilter(GoatTier? tier) {
    if (tier == null || state.filterTier == tier) {
      state = state.copyWith(clearTierFilter: true);
    } else {
      state = state.copyWith(filterTier: tier);
    }
  }

  void setEraFilter(CyclingEra? era) {
    if (era == null || state.filterEra == era) {
      state = state.copyWith(clearEraFilter: true);
    } else {
      state = state.copyWith(filterEra: era);
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void selectPrimaryRider(String riderId) {
    state = state.copyWith(primaryRiderId: riderId);
  }

  void selectSecondaryRider(String riderId) {
    state = state.copyWith(secondaryRiderId: riderId);
  }

  void swapComparedRiders() {
    state = state.copyWith(
      primaryRiderId: state.secondaryRiderId,
      secondaryRiderId: state.primaryRiderId,
    );
  }

  void setCareerPalmares(List<RiderPalmares> palmares) {
    state = state.copyWith(careerPalmares: palmares);
  }

  List<AllTimeHallOfFameLeaderboardEntry> get leaderboard =>
      _service.buildMergedHallOfFame(
        careerRiders: state.careerPalmares,
        useEraAdjustment: state.useEraAdjustment,
        filterTier: state.filterTier,
        filterEra: state.filterEra,
        searchQuery: state.searchQuery,
      );

  LegendComparisonReport? buildActiveComparison() {
    final all = _service.buildMergedHallOfFame(
      careerRiders: state.careerPalmares,
      useEraAdjustment: state.useEraAdjustment,
    );
    if (all.length < 2) return null;

    final primary = all.firstWhere(
      (e) => e.riderId == state.primaryRiderId,
      orElse: () => all.first,
    );
    final secondary = all.firstWhere(
      (e) => e.riderId == state.secondaryRiderId,
      orElse: () => all.length > 1 ? all[1] : all.first,
    );

    return _service.compareRiders(
      primary.breakdown,
      secondary.breakdown,
      useEraAdjustment: state.useEraAdjustment,
    );
  }
}

final historicLegendCompareServiceProvider =
    Provider<HistoricLegendHallOfFameCompareService>(
  (ref) => const HistoricLegendHallOfFameCompareService(),
);

final historicLegendCompareProvider = StateNotifierProvider<
    HistoricLegendCompareNotifier, HistoricLegendCompareState>(
  (ref) => HistoricLegendCompareNotifier(
    service: ref.watch(historicLegendCompareServiceProvider),
  ),
);

/// Interaktywny panel porównania Legend Wszech Czasów i punktacji `All-Time Goat Score`.
class HistoricLegendHallOfFameComparePanel extends ConsumerStatefulWidget {
  final List<RiderPalmares> careerPalmares;

  const HistoricLegendHallOfFameComparePanel({
    super.key,
    this.careerPalmares = const [],
  });

  @override
  ConsumerState<HistoricLegendHallOfFameComparePanel> createState() =>
      _HistoricLegendHallOfFameComparePanelState();
}

class _HistoricLegendHallOfFameComparePanelState
    extends ConsumerState<HistoricLegendHallOfFameComparePanel> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.careerPalmares.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(historicLegendCompareProvider.notifier)
            .setCareerPalmares(widget.careerPalmares);
      });
    }
  }

  @override
  void didUpdateWidget(
      covariant HistoricLegendHallOfFameComparePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.careerPalmares != oldWidget.careerPalmares) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(historicLegendCompareProvider.notifier)
            .setCareerPalmares(widget.careerPalmares);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(historicLegendCompareProvider);
    final notifier = ref.read(historicLegendCompareProvider.notifier);
    final leaderboard = notifier.leaderboard;
    final comparison = notifier.buildActiveComparison();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D), width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 1080;
          final isCompact = constraints.maxWidth < 600;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(state, notifier, isCompact),
                const SizedBox(height: 16),
                _buildFiltersBar(state, notifier, isCompact),
                const SizedBox(height: 16),
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: _buildComparisonCard(
                          comparison,
                          state,
                          notifier,
                          isCompact,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 5,
                        child: _buildLeaderboardCard(
                          leaderboard,
                          state,
                          notifier,
                        ),
                      ),
                    ],
                  )
                else ...[
                  _buildComparisonCard(
                    comparison,
                    state,
                    notifier,
                    isCompact,
                  ),
                  const SizedBox(height: 16),
                  _buildLeaderboardCard(
                    leaderboard,
                    state,
                    notifier,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(
    HistoricLegendCompareState state,
    HistoricLegendCompareNotifier notifier,
    bool isCompact,
  ) {
    const titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ALL-TIME GOAT SCORE & HALL OF FAME',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.goldAccent,
            letterSpacing: -0.2,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Wieloletnia punktacja wszech czasów z normalizacją epok i porównaniem H2H',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );

    final eraToggle = _InteractiveToggleChip(
      label: 'Normalizacja Epok',
      selected: state.useEraAdjustment,
      accentColor: AppColors.cyanAccent,
      onTap: () => notifier.toggleEraAdjustment(!state.useEraAdjustment),
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleBlock,
          const SizedBox(height: 12),
          eraToggle,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Expanded(child: titleBlock),
        const SizedBox(width: 16),
        eraToggle,
      ],
    );
  }

  Widget _buildFiltersBar(
    HistoricLegendCompareState state,
    HistoricLegendCompareNotifier notifier,
    bool isCompact,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            onChanged: notifier.setSearchQuery,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Szukaj legendy, pseudonimu lub kraju (np. Merckx, BEL)...',
              hintStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
              suffixIcon: state.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16),
                      color: AppColors.textSecondary,
                      onPressed: () {
                        _searchController.clear();
                        notifier.setSearchQuery('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.surfaceLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2A2F3D)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2A2F3D)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.goldAccent),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InteractiveToggleChip(
                label: 'Wszystkie Piętra',
                selected: state.filterTier == null,
                accentColor: AppColors.goldAccent,
                onTap: () => notifier.setTierFilter(null),
              ),
              for (final tier in GoatTier.values.reversed)
                _InteractiveToggleChip(
                  label: 'T${tier.level} ${tier.displayName}',
                  selected: state.filterTier == tier,
                  accentColor: tier.accentColor,
                  onTap: () => notifier.setTierFilter(tier),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InteractiveToggleChip(
                label: 'Wszystkie Epoki',
                selected: state.filterEra == null,
                accentColor: AppColors.accentBlue,
                onTap: () => notifier.setEraFilter(null),
              ),
              for (final era in CyclingEra.values)
                _InteractiveToggleChip(
                  label: era.shortLabel,
                  selected: state.filterEra == era,
                  accentColor: AppColors.accentBlue,
                  onTap: () => notifier.setEraFilter(era),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonCard(
    LegendComparisonReport? comparison,
    HistoricLegendCompareState state,
    HistoricLegendCompareNotifier notifier,
    bool isCompact,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      padding: const EdgeInsets.all(16),
      child: comparison == null
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Brak wystarczającej liczby kolarzy do porównania H2H.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isCompact)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildCompareSlotHeader(
                        label: 'KOLARZ A',
                        breakdown: comparison.primary,
                        useEraAdjustment: state.useEraAdjustment,
                        accentColor: AppColors.goldAccent,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: _InteractiveIconAction(
                            icon: Icons.swap_vert_rounded,
                            tooltip: 'Zamień strony',
                            onPressed: notifier.swapComparedRiders,
                          ),
                        ),
                      ),
                      _buildCompareSlotHeader(
                        label: 'KOLARZ B',
                        breakdown: comparison.secondary,
                        useEraAdjustment: state.useEraAdjustment,
                        accentColor: AppColors.cyanAccent,
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: _buildCompareSlotHeader(
                          label: 'KOLARZ A',
                          breakdown: comparison.primary,
                          useEraAdjustment: state.useEraAdjustment,
                          accentColor: AppColors.goldAccent,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: _InteractiveIconAction(
                          icon: Icons.swap_horiz_rounded,
                          tooltip: 'Zamień strony',
                          onPressed: notifier.swapComparedRiders,
                        ),
                      ),
                      Expanded(
                        child: _buildCompareSlotHeader(
                          label: 'KOLARZ B',
                          breakdown: comparison.secondary,
                          useEraAdjustment: state.useEraAdjustment,
                          accentColor: AppColors.cyanAccent,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.goldAccent.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comparison.verdictHeadline,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        comparison.verdictDetail,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                for (final category in comparison.categories) ...[
                  _buildCategoryBar(category, isCompact),
                  const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }

  Widget _buildCompareSlotHeader({
    required String label,
    required GoatScoreBreakdown breakdown,
    required bool useEraAdjustment,
    required Color accentColor,
  }) {
    final score = breakdown.effectiveScore(useEraAdjustment: useEraAdjustment);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label • ${breakdown.nationalityIso}',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            breakdown.riderName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$score pkt',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'T${breakdown.tier.level} ${breakdown.tier.displayName} (${breakdown.normalizedIndex100}%)',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: breakdown.tier.accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBar(GoatCategoryComparison category, bool isCompact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${category.primaryScore}',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: category.winnerSign == 1
                    ? FontWeight.w800
                    : FontWeight.w500,
                color: category.winnerSign == 1
                    ? AppColors.goldAccent
                    : AppColors.textSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            Expanded(
              child: Text(
                category.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isCompact ? 11 : 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Text(
              '${category.secondaryScore}',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: category.winnerSign == -1
                    ? FontWeight.w800
                    : FontWeight.w500,
                color: category.winnerSign == -1
                    ? AppColors.cyanAccent
                    : AppColors.textSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 8,
            child: Row(
              children: [
                Expanded(
                  flex: math.max(1, (category.primaryShare * 1000).round()),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    color: AppColors.goldAccent,
                  ),
                ),
                Expanded(
                  flex: math.max(
                    1,
                    ((1.0 - category.primaryShare) * 1000).round(),
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    color: AppColors.cyanAccent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardCard(
    List<AllTimeHallOfFameLeaderboardEntry> entries,
    HistoricLegendCompareState state,
    HistoricLegendCompareNotifier notifier,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Ranking Wszech Czasów',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${entries.length} legend',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Brak legend spełniających kryteria filtra.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            for (final entry in entries) ...[
              _LeaderboardLegendRow(
                entry: entry,
                isPrimary: state.primaryRiderId == entry.riderId,
                isSecondary: state.secondaryRiderId == entry.riderId,
                onSelectPrimary: () =>
                    notifier.selectPrimaryRider(entry.riderId),
                onSelectSecondary: () =>
                    notifier.selectSecondaryRider(entry.riderId),
              ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

class _InteractiveToggleChip extends StatefulWidget {
  final String label;
  final bool selected;
  final Color accentColor;
  final VoidCallback? onTap;

  const _InteractiveToggleChip({
    required this.label,
    required this.selected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_InteractiveToggleChip> createState() => _InteractiveToggleChipState();
}

class _InteractiveToggleChipState extends State<_InteractiveToggleChip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final bgColor = !enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : widget.selected
            ? widget.accentColor.withValues(alpha: _pressed ? 0.28 : 0.20)
            : (_hovered
                ? AppColors.surfaceLight
                : AppColors.background);

    final borderColor = !enabled
        ? const Color(0xFF2A2F3D).withValues(alpha: 0.4)
        : (_focused || widget.selected)
            ? widget.accentColor
            : (_hovered
                ? widget.accentColor.withValues(alpha: 0.5)
                : const Color(0xFF2A2F3D));

    return FocusableActionDetector(
      enabled: enabled,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
              color: !enabled
                  ? AppColors.textSecondary.withValues(alpha: 0.5)
                  : widget.selected
                      ? widget.accentColor
                      : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractiveIconAction extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _InteractiveIconAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  State<_InteractiveIconAction> createState() => _InteractiveIconActionState();
}

class _InteractiveIconActionState extends State<_InteractiveIconAction> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return Tooltip(
      message: widget.tooltip,
      child: FocusableActionDetector(
        enabled: enabled,
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _pressed
                  ? AppColors.goldAccent.withValues(alpha: 0.25)
                  : (_hovered ? AppColors.surfaceLight : AppColors.background),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _focused || _hovered
                    ? AppColors.goldAccent
                    : const Color(0xFF2A2F3D),
              ),
            ),
            child: Icon(
              widget.icon,
              size: 18,
              color: enabled
                  ? AppColors.goldAccent
                  : AppColors.textSecondary.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }
}

class _LeaderboardLegendRow extends StatefulWidget {
  final AllTimeHallOfFameLeaderboardEntry entry;
  final bool isPrimary;
  final bool isSecondary;
  final VoidCallback onSelectPrimary;
  final VoidCallback onSelectSecondary;

  const _LeaderboardLegendRow({
    required this.entry,
    required this.isPrimary,
    required this.isSecondary,
    required this.onSelectPrimary,
    required this.onSelectSecondary,
  });

  @override
  State<_LeaderboardLegendRow> createState() => _LeaderboardLegendRowState();
}

class _LeaderboardLegendRowState extends State<_LeaderboardLegendRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isPrimary
        ? AppColors.goldAccent
        : widget.isSecondary
            ? AppColors.cyanAccent
            : (_hovered
                ? AppColors.textSecondary.withValues(alpha: 0.5)
                : const Color(0xFF2A2F3D));

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _hovered ? AppColors.surfaceLight : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(
                '#${widget.entry.rank}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: widget.entry.rank <= 3
                      ? AppColors.goldAccent
                      : AppColors.textSecondary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.entry.riderName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.entry.nationalityIso,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'T${widget.entry.breakdown.tier.level} • ${widget.entry.effectiveScore} pkt',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: widget.entry.breakdown.tier.accentColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _SlotBadgeButton(
              label: 'A',
              selected: widget.isPrimary,
              color: AppColors.goldAccent,
              onTap: widget.onSelectPrimary,
            ),
            const SizedBox(width: 6),
            _SlotBadgeButton(
              label: 'B',
              selected: widget.isSecondary,
              color: AppColors.cyanAccent,
              onTap: widget.onSelectSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _SlotBadgeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _SlotBadgeButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.22) : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? color : const Color(0xFF2A2F3D),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: selected ? color : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
