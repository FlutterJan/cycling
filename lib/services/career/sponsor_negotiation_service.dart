import 'dart:math' as math;
import '../../models/career/career_save.dart';
import '../../models/rider/rider.dart';
import '../../models/team/cycling_team.dart';
import '../../models/team/sponsor_contract.dart';

/// Profil preferencji i wartości marketingowych korporacji poszukującej drużyny kolarskiej.
enum SponsorMarketingFocus {
  /// Nastawiony na żółtą koszulkę Tour de France i wygrywanie klasyfikacji generalnej
  grandTourGlory,

  /// Nastawiony na maksymalny czas antenowy TV dzięki odważnym, długim ucieczkom
  breakawayExposure,

  /// Nastawiony na tradycję Wiosennych Monumentów i heroiczne bruki Flandrii/Roubaix
  classicsTradition,

  /// Nastawiony na sprinty masowe, prędkość i walkę o zieloną koszulkę
  pureSpeedAndSprints,

  /// Nastawiony na promocję nowoczesnych technologii, aerodynamiki i danych
  techAndInnovation,

  /// Nastawiony na tożsamość narodową i lokalnych bohaterów
  nationalHeritage;

  String toJson() => name;

  static SponsorMarketingFocus fromJson(String value) {
    return SponsorMarketingFocus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SponsorMarketingFocus.breakawayExposure,
    );
  }

  String get label {
    switch (this) {
      case SponsorMarketingFocus.grandTourGlory:
        return 'Triumf w Grand Tourach (Żółta Koszulka TdF)';
      case SponsorMarketingFocus.breakawayExposure:
        return 'Czas antenowy TV (Odważne Ucieczki i Waleczność)';
      case SponsorMarketingFocus.classicsTradition:
        return 'Wiosenne Monumenty i Tradycja Bruków';
      case SponsorMarketingFocus.pureSpeedAndSprints:
        return 'Finałowe Sprinty i Zielona Koszulka';
      case SponsorMarketingFocus.techAndInnovation:
        return 'Innowacje, Aerodynamika i Nowoczesne Technologie';
      case SponsorMarketingFocus.nationalHeritage:
        return 'Tożsamość Narodowa i Lokalni Bohaterowie';
    }
  }
}

/// Potencjalny sponsor korporacyjny dostępny na rynku poszukiwania partnerów.
class PotentialSponsorCompany {
  final String id;
  final String name;
  final SponsorIndustry industry;
  final SponsorTier defaultTier;
  final String countryIso;
  final int baseAnnualBudgetEur;
  final SponsorMarketingFocus marketingFocus;
  final double minimumTeamPrestigeRequirement; // 1.0 - 100.0
  final String description;

  const PotentialSponsorCompany({
    required this.id,
    required this.name,
    required this.industry,
    required this.defaultTier,
    required this.countryIso,
    required this.baseAnnualBudgetEur,
    required this.marketingFocus,
    required this.minimumTeamPrestigeRequirement,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'industry': industry.toJson(),
      'defaultTier': defaultTier.toJson(),
      'countryIso': countryIso,
      'baseAnnualBudgetEur': baseAnnualBudgetEur,
      'marketingFocus': marketingFocus.toJson(),
      'minimumTeamPrestigeRequirement': minimumTeamPrestigeRequirement,
      'description': description,
    };
  }

  factory PotentialSponsorCompany.fromJson(Map<String, dynamic> json) {
    return PotentialSponsorCompany(
      id: json['id'] as String,
      name: json['name'] as String,
      industry: SponsorIndustry.fromJson(json['industry'] as String),
      defaultTier: SponsorTier.fromJson(json['defaultTier'] as String),
      countryIso: json['countryIso'] as String,
      baseAnnualBudgetEur: (json['baseAnnualBudgetEur'] as num).toInt(),
      marketingFocus: SponsorMarketingFocus.fromJson(json['marketingFocus'] as String),
      minimumTeamPrestigeRequirement:
          (json['minimumTeamPrestigeRequirement'] as num).toDouble(),
      description: json['description'] as String,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PotentialSponsorCompany && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'PotentialSponsorCompany($name, ${defaultTier.name}, €${(baseAnnualBudgetEur / 1000000).toStringAsFixed(1)}M/rok, cel: ${marketingFocus.name})';
}

/// Rodzaj obietnicy sportowej składanej sponsorowi w Pitch Decku na kolejny sezon.
enum PromisedObjectiveType {
  /// Wygranie klasyfikacji generalnej Tour de France / Giro / Vuelta
  winGrandTourGc,

  /// Podium w klasyfikacji generalnej Grand Touru (Top 3)
  podiumGrandTourGc,

  /// Triumf w jednym z 5 Monumentów kolarstwa
  winCyclingMonument,

  /// Zdobycie minimum określonej liczby zwycięstw etapowych WorldTour
  targetStageWinsCount,

  /// Spędzenie minimum 1200+ km w ucieczkach (czas antenowy TV)
  breakawayTvAirtimeKm,

  /// Wygranie klasyfikacji najbardziej walecznego kolarza (Super Combativity)
  winMostCombativeAward,

  /// Zdobycie Zielonej Koszulki Klasyfikacji Punktowej
  winPointsGreenJersey,

  /// Zdobycie Koszulki w Grochy Najlepszego Górala (KOM)
  winMountainsJersey,

  /// Zakończenie sezonu w Top 5 Drużynowego Rankingu UCI
  finishTop5UciTeamRanking;

  String toJson() => name;

  static PromisedObjectiveType fromJson(String value) {
    return PromisedObjectiveType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => PromisedObjectiveType.targetStageWinsCount,
    );
  }

  String get label {
    switch (this) {
      case PromisedObjectiveType.winGrandTourGc:
        return 'Zwycięstwo w Klasyfikacji Generalnej Grand Touru';
      case PromisedObjectiveType.podiumGrandTourGc:
        return 'Podium Klasyfikacji Generalnej Grand Touru (Top 3)';
      case PromisedObjectiveType.winCyclingMonument:
        return 'Zwycięstwo w Monumencie Kolarskim';
      case PromisedObjectiveType.targetStageWinsCount:
        return 'Pakiet Zwycięstw Etapowych w WorldTourze';
      case PromisedObjectiveType.breakawayTvAirtimeKm:
        return 'Minimum 1200 km w Ucieczkach (Ekspozycja TV)';
      case PromisedObjectiveType.winMostCombativeAward:
        return 'Tytuł Najbardziej Walecznego Kolarza (Czerwony Numer)';
      case PromisedObjectiveType.winPointsGreenJersey:
        return 'Zdobycie Zielonej Koszulki Punktowej';
      case PromisedObjectiveType.winMountainsJersey:
        return 'Zdobycie Koszulki w Grochy Najlepszego Górala';
      case PromisedObjectiveType.finishTop5UciTeamRanking:
        return 'Miejsce w Top 5 Drużynowego Rankingu UCI';
    }
  }

  /// Wartość premiowa dodawana do satysfakcji sponsora za zrealizowanie
  int get defaultBonusEur {
    switch (this) {
      case PromisedObjectiveType.winGrandTourGc:
        return 1200000;
      case PromisedObjectiveType.podiumGrandTourGc:
        return 600000;
      case PromisedObjectiveType.winCyclingMonument:
        return 500000;
      case PromisedObjectiveType.targetStageWinsCount:
        return 350000;
      case PromisedObjectiveType.breakawayTvAirtimeKm:
        return 250000;
      case PromisedObjectiveType.winMostCombativeAward:
        return 200000;
      case PromisedObjectiveType.winPointsGreenJersey:
        return 400000;
      case PromisedObjectiveType.winMountainsJersey:
        return 350000;
      case PromisedObjectiveType.finishTop5UciTeamRanking:
        return 500000;
    }
  }
}

/// Pakiet prezentacji sponsorskiej (Pitch Deck) przygotowywany przez menedżera drużyny.
class SponsorPitchDeck {
  final String sponsorCompanyId;
  final SponsorTier proposedTier;
  final int requestedAnnualBudgetEur;
  final int contractDurationYears;
  final String? featuredStarRiderId;
  final List<PromisedObjectiveType> promisedObjectives;

  const SponsorPitchDeck({
    required this.sponsorCompanyId,
    required this.proposedTier,
    required this.requestedAnnualBudgetEur,
    required this.contractDurationYears,
    this.featuredStarRiderId,
    required this.promisedObjectives,
  });

  Map<String, dynamic> toJson() {
    return {
      'sponsorCompanyId': sponsorCompanyId,
      'proposedTier': proposedTier.toJson(),
      'requestedAnnualBudgetEur': requestedAnnualBudgetEur,
      'contractDurationYears': contractDurationYears,
      'featuredStarRiderId': featuredStarRiderId,
      'promisedObjectives': promisedObjectives.map((o) => o.toJson()).toList(),
    };
  }

  factory SponsorPitchDeck.fromJson(Map<String, dynamic> json) {
    return SponsorPitchDeck(
      sponsorCompanyId: json['sponsorCompanyId'] as String,
      proposedTier: SponsorTier.fromJson(json['proposedTier'] as String),
      requestedAnnualBudgetEur: (json['requestedAnnualBudgetEur'] as num).toInt(),
      contractDurationYears: (json['contractDurationYears'] as num).toInt(),
      featuredStarRiderId: json['featuredStarRiderId'] as String?,
      promisedObjectives: (json['promisedObjectives'] as List<dynamic>)
          .map((e) => PromisedObjectiveType.fromJson(e as String))
          .toList(),
    );
  }
}

/// Status decyzji zarządu sponsora po analizie Pitch Decku.
enum SponsorNegotiationDecision {
  accepted,
  counterOffer,
  rejected;

  String toJson() => name;

  static SponsorNegotiationDecision fromJson(String value) {
    return SponsorNegotiationDecision.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SponsorNegotiationDecision.rejected,
    );
  }
}

/// Rezultat negocjacji sponsorskich z zarządem korporacji.
class SponsorPitchResult {
  final SponsorNegotiationDecision decision;
  final double overallScore; // 0.0 - 100.0 pkt
  final int offeredAnnualBudgetEur;
  final int contractDurationYears;
  final String corporateDirectorQuote;
  final String? rejectionReason;

  // Cząstkowa ocena filarów prezentacji
  final double starPowerScore; // Waga 30%
  final double breakawayExposureScore; // Waga 25%
  final double promisesAmbitionScore; // Waga 20%
  final double budgetFairnessScore; // Waga 15%
  final double divisionPrestigeScore; // Waga 10%

  /// Wygenerowany kontrakt sponsorski (jeśli zaakceptowano lub kontroferta)
  final SponsorContract? resultingContract;

  const SponsorPitchResult({
    required this.decision,
    required this.overallScore,
    required this.offeredAnnualBudgetEur,
    required this.contractDurationYears,
    required this.corporateDirectorQuote,
    this.rejectionReason,
    required this.starPowerScore,
    required this.breakawayExposureScore,
    required this.promisesAmbitionScore,
    required this.budgetFairnessScore,
    required this.divisionPrestigeScore,
    this.resultingContract,
  });

  bool get isAccepted => decision == SponsorNegotiationDecision.accepted;
  bool get isCounterOffer => decision == SponsorNegotiationDecision.counterOffer;
  bool get isRejected => decision == SponsorNegotiationDecision.rejected;

  Map<String, dynamic> toJson() {
    return {
      'decision': decision.toJson(),
      'overallScore': overallScore,
      'offeredAnnualBudgetEur': offeredAnnualBudgetEur,
      'contractDurationYears': contractDurationYears,
      'corporateDirectorQuote': corporateDirectorQuote,
      'rejectionReason': rejectionReason,
      'starPowerScore': starPowerScore,
      'breakawayExposureScore': breakawayExposureScore,
      'promisesAmbitionScore': promisesAmbitionScore,
      'budgetFairnessScore': budgetFairnessScore,
      'divisionPrestigeScore': divisionPrestigeScore,
      'resultingContract': resultingContract?.toJson(),
    };
  }

  factory SponsorPitchResult.fromJson(Map<String, dynamic> json) {
    return SponsorPitchResult(
      decision: SponsorNegotiationDecision.fromJson(json['decision'] as String),
      overallScore: (json['overallScore'] as num).toDouble(),
      offeredAnnualBudgetEur: (json['offeredAnnualBudgetEur'] as num).toInt(),
      contractDurationYears: (json['contractDurationYears'] as num).toInt(),
      corporateDirectorQuote: json['corporateDirectorQuote'] as String,
      rejectionReason: json['rejectionReason'] as String?,
      starPowerScore: (json['starPowerScore'] as num).toDouble(),
      breakawayExposureScore: (json['breakawayExposureScore'] as num).toDouble(),
      promisesAmbitionScore: (json['promisesAmbitionScore'] as num).toDouble(),
      budgetFairnessScore: (json['budgetFairnessScore'] as num).toDouble(),
      divisionPrestigeScore: (json['divisionPrestigeScore'] as num).toDouble(),
      resultingContract: json['resultingContract'] != null
          ? SponsorContract.fromJson(json['resultingContract'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  String toString() =>
      'SponsorPitchResult(${decision.name}, score: ${overallScore.toStringAsFixed(1)}/100, budżet: €${(offeredAnnualBudgetEur / 1000000).toStringAsFixed(1)}M, "$corporateDirectorQuote")';
}

/// Zaawansowany serwis pozyskiwania sponsorów, negocjacji budżetu i analizy prezentacji (Pitch Deck).
class SponsorNegotiationService {
  SponsorNegotiationService._();

  // ===========================================================================
  // BAZA KANDYDATÓW NA SPONSORÓW (SPONSORS CATALOG)
  // ===========================================================================

  static const List<PotentialSponsorCompany> availableSponsorCompanies = [
    // Tytułowi sponsorzy WorldTour (Pule €18M - €34M)
    PotentialSponsorCompany(
      id: 'sp_aerovektor_telecom',
      name: 'AeroVektor Telecom',
      industry: SponsorIndustry.tech,
      defaultTier: SponsorTier.titlePrimary,
      countryIso: 'FRA',
      baseAnnualBudgetEur: 26000000,
      marketingFocus: SponsorMarketingFocus.grandTourGlory,
      minimumTeamPrestigeRequirement: 70.0,
      description: 'Francuski gigant telekomunikacyjny żądający widoczności w lipcu podczas Tour de France i walki o Maillot Jaune.',
    ),
    PotentialSponsorCompany(
      id: 'sp_desert_emirates',
      name: 'Desert Skyway Airlines',
      industry: SponsorIndustry.airlines,
      defaultTier: SponsorTier.titlePrimary,
      countryIso: 'UAE',
      baseAnnualBudgetEur: 32000000,
      marketingFocus: SponsorMarketingFocus.grandTourGlory,
      minimumTeamPrestigeRequirement: 80.0,
      description: 'Luksusowe linie lotnicze dysponujące nieograniczonym budżetem, oczekujące bezdyskusyjnej dominacji w peletonie WorldTour.',
    ),
    PotentialSponsorCompany(
      id: 'sp_sovereign_wealth',
      name: 'Sovereign Capital Partners',
      industry: SponsorIndustry.finance,
      defaultTier: SponsorTier.titlePrimary,
      countryIso: 'GBR',
      baseAnnualBudgetEur: 28000000,
      marketingFocus: SponsorMarketingFocus.techAndInnovation,
      minimumTeamPrestigeRequirement: 75.0,
      description: 'Brytyjski fundusz inwestycyjny ceniący podejście marginal gains, aerodynamikę i zwycięstwa w próbkach czasowych.',
    ),
    PotentialSponsorCompany(
      id: 'sp_helios_green',
      name: 'Helios Green Energy',
      industry: SponsorIndustry.energy,
      defaultTier: SponsorTier.titlePrimary,
      countryIso: 'ESP',
      baseAnnualBudgetEur: 21000000,
      marketingFocus: SponsorMarketingFocus.breakawayExposure,
      minimumTeamPrestigeRequirement: 60.0,
      description: 'Hiszpański koncern energii odnawialnej poszukujący agresywnej jazdy w ucieczkach górskich i koszulki górala w Vuelcie.',
    ),
    PotentialSponsorCompany(
      id: 'sp_alpen_supermarkt',
      name: 'Alpen Supermarkt',
      industry: SponsorIndustry.supermarkets,
      defaultTier: SponsorTier.titlePrimary,
      countryIso: 'GER',
      baseAnnualBudgetEur: 19500000,
      marketingFocus: SponsorMarketingFocus.breakawayExposure,
      minimumTeamPrestigeRequirement: 50.0,
      description: 'Środkowoeuropejska sieć marketów, dla której kluczowy jest codzienny czas antenowy TV i obecność kolarzy w ucieczkach dnia.',
    ),

    // Drugi sponsor tytularny (Title Secondary - Pule €7M - €12M)
    PotentialSponsorCompany(
      id: 'sp_nordic_credit',
      name: 'Nordic Credit Bank',
      industry: SponsorIndustry.finance,
      defaultTier: SponsorTier.titleSecondary,
      countryIso: 'DEN',
      baseAnnualBudgetEur: 8500000,
      marketingFocus: SponsorMarketingFocus.classicsTradition,
      minimumTeamPrestigeRequirement: 55.0,
      description: 'Skandynawska instytucja finansowa nastawiona na brukowane Monumenty i bohaterstwo w wiosennym deszczu i błocie.',
    ),
    PotentialSponsorCompany(
      id: 'sp_corsa_espresso',
      name: "Corsa d'Oro Espresso",
      industry: SponsorIndustry.supermarkets,
      defaultTier: SponsorTier.titleSecondary,
      countryIso: 'ITA',
      baseAnnualBudgetEur: 7800000,
      marketingFocus: SponsorMarketingFocus.breakawayExposure,
      minimumTeamPrestigeRequirement: 45.0,
      description: 'Włoska palarnia kawy kochająca romantyczne, samotne ataki, Giro d\'Italia i widowiskową, bezkompromisową walkę.',
    ),
    PotentialSponsorCompany(
      id: 'sp_voltix_ev',
      name: 'Voltix Electric Mobility',
      industry: SponsorIndustry.automotive,
      defaultTier: SponsorTier.titleSecondary,
      countryIso: 'GER',
      baseAnnualBudgetEur: 9200000,
      marketingFocus: SponsorMarketingFocus.pureSpeedAndSprints,
      minimumTeamPrestigeRequirement: 50.0,
      description: 'Producent miejskich pojazdów elektrycznych promujący prędkość, pociągi sprinterskie i zieloną koszulkę punktową.',
    ),
    PotentialSponsorCompany(
      id: 'sp_boreas_offshore',
      name: 'Boreas Offshore Wind',
      industry: SponsorIndustry.energy,
      defaultTier: SponsorTier.titleSecondary,
      countryIso: 'NED',
      baseAnnualBudgetEur: 8200000,
      marketingFocus: SponsorMarketingFocus.classicsTradition,
      minimumTeamPrestigeRequirement: 48.0,
      description: 'Holenderski pionier morskich farm wiatrowych ceniący rantowanie na bocznych wiatrach i bruki Flandrii.',
    ),

    // Główny partner (Major Partner - Pule €3M - €6M)
    PotentialSponsorCompany(
      id: 'sp_kronos_watches',
      name: 'Kronos Swiss Horology',
      industry: SponsorIndustry.apparel,
      defaultTier: SponsorTier.majorPartner,
      countryIso: 'SUI',
      baseAnnualBudgetEur: 4500000,
      marketingFocus: SponsorMarketingFocus.techAndInnovation,
      minimumTeamPrestigeRequirement: 40.0,
      description: 'Szwajcarska manufaktura zegarków stawiająca na precyzję, jazdę indywidualną na czas i aerodynamikę co do setnej sekundy.',
    ),
    PotentialSponsorCompany(
      id: 'sp_velodata_cloud',
      name: 'VeloData Cloud Analytics',
      industry: SponsorIndustry.tech,
      defaultTier: SponsorTier.majorPartner,
      countryIso: 'USA',
      baseAnnualBudgetEur: 5200000,
      marketingFocus: SponsorMarketingFocus.techAndInnovation,
      minimumTeamPrestigeRequirement: 45.0,
      description: 'Dostawca rozwiązań chmurowych analizujący waty, W\' i telemetrię wyścigową w czasie rzeczywistym.',
    ),
    PotentialSponsorCompany(
      id: 'sp_baltic_fintech',
      name: 'Baltic Payments & Pay',
      industry: SponsorIndustry.finance,
      defaultTier: SponsorTier.majorPartner,
      countryIso: 'POL',
      baseAnnualBudgetEur: 3800000,
      marketingFocus: SponsorMarketingFocus.nationalHeritage,
      minimumTeamPrestigeRequirement: 35.0,
      description: 'Środkowoeuropejska spółka fintech promująca Tour de Pologne, młode talenty i kolarzy z regionu bałtyckiego.',
    ),
    PotentialSponsorCompany(
      id: 'sp_zenith_pharma',
      name: 'Zenith Pro Nutrition',
      industry: SponsorIndustry.apparel,
      defaultTier: SponsorTier.majorPartner,
      countryIso: 'BEL',
      baseAnnualBudgetEur: 4200000,
      marketingFocus: SponsorMarketingFocus.classicsTradition,
      minimumTeamPrestigeRequirement: 40.0,
      description: 'Belgijski producent odżywek dla sportowców wytrzymałościowych, sponsorujący Ardeny i finisze pod górę.',
    ),
  ];

  /// Zwraca listę firm zainteresowanych współpracą sponsorską
  static List<PotentialSponsorCompany> getProspectingList({
    SponsorTier? tierFilter,
    SponsorIndustry? industryFilter,
  }) {
    return availableSponsorCompanies.where((c) {
      if (tierFilter != null && c.defaultTier != tierFilter) return false;
      if (industryFilter != null && c.industry != industryFilter) return false;
      return true;
    }).toList();
  }

  /// Wylicza siłę oddziaływania medialnego gwiazdy zespołu (Star Power Index, 0.0 - 100.0 pkt).
  ///
  /// Kolarze o potencjale powyżej 82, wysokim W/kg (>5.8 W/kg) i tysiącach punktów UCI
  /// przyciągają sponsorów jak magnes, znacząco podnosząc kwoty kontraktów.
  static double calculateRiderMediaStarRating(Rider rider) {
    double score = 20.0;

    final double wKg = rider.physiology.criticalPowerWatts / rider.physiology.weightKg;
    final int sprintWatts = rider.powerProfile.p5sWatts;
    final int uciPoints = rider.careerPointsUci;
    final int potential = rider.potential;

    // 1. Klasa sportowa (Górale i Sprinterzy)
    if (wKg >= 6.2 || sprintWatts >= 1650) {
      score += 40.0; // Klasa światowej supergwiazdy
    } else if (wKg >= 5.8 || sprintWatts >= 1500) {
      score += 25.0; // Czołowy zawodnik peletonu
    } else if (wKg >= 5.4 || sprintWatts >= 1350) {
      score += 15.0;
    }

    // 2. Punkty UCI w karierze (rozpoznawalność i sukcesy)
    score += (uciPoints / 120.0).clamp(0.0, 25.0);

    // 3. Potencjał i status prospekta
    if (potential >= 88) {
      score += 15.0;
    } else if (potential >= 80) {
      score += 8.0;
    }

    return score.clamp(10.0, 100.0);
  }

  /// Wylicza wskaźnik waleczności i ekspozycji telewizyjnej zespołu (Breakaway TV Exposure Rating).
  ///
  /// Drużyny aktywnie uciekające i walczące o etapy z odważnych odjazdów
  /// generują ogromną wartość ekwiwalentu reklamowego (AVE) dla marek konsumenckich.
  static double calculateTeamBreakawayExposure({
    required CareerSave save,
    int? breakawayKmSeason,
    int? mostCombativeAwardsSeason,
    int? breakawayStageWinsSeason,
  }) {
    double score = 40.0;

    // Pobieramy dane z historii lub przyjmujemy szacunki z wyników
    final km = breakawayKmSeason ?? 850;
    final awards = mostCombativeAwardsSeason ?? 3;
    final wins = breakawayStageWinsSeason ?? 1;

    // Kilometry w ucieczkach (czas antenowy TV z widocznym logo sponsora na koszulce)
    score += (km / 40.0).clamp(0.0, 30.0);

    // Zdobyte czerwone numery najbardziej walecznego kolarza
    score += (awards * 4.0).clamp(0.0, 15.0);

    // Etapy wygrane po samotnej ucieczce
    score += (wins * 8.0).clamp(0.0, 20.0);

    return score.clamp(10.0, 100.0);
  }

  /// Przeprowadza pełną analizę prezentacji (Pitch Deck) złożonej przez menedżera
  /// i generuje oficjalną odpowiedź zarządu sponsora ([SponsorPitchResult]).
  static SponsorPitchResult evaluatePitchDeck({
    required CareerSave currentSave,
    required SponsorPitchDeck pitchDeck,
    int? breakawayKmSeason,
    int? mostCombativeAwardsSeason,
    int? breakawayStageWinsSeason,
  }) {
    final company = availableSponsorCompanies.firstWhere(
      (c) => c.id == pitchDeck.sponsorCompanyId,
      orElse: () => availableSponsorCompanies.first,
    );

    final playerTeam = currentSave.playerTeam;

    // =========================================================================
    // FILAR 1: SIŁA MEDIALNA GWIAZDY ZESPOŁU (Waga 30%)
    // =========================================================================
    double starRating = 30.0;
    Rider? featuredStar;

    if (pitchDeck.featuredStarRiderId != null) {
      featuredStar = currentSave.getRiderById(pitchDeck.featuredStarRiderId!);
    }
    // Jeśli nie wybrano ręcznie, szukamy najlepszego kolarza z kadry gracza
    if (featuredStar == null && currentSave.playerRoster.isNotEmpty) {
      final sortedRoster = [...currentSave.playerRoster]
        ..sort((a, b) => b.careerPointsUci.compareTo(a.careerPointsUci));
      featuredStar = sortedRoster.first;
    }

    if (featuredStar != null) {
      starRating = calculateRiderMediaStarRating(featuredStar);
    }
    final double starPowerScore = (starRating / 100.0) * 30.0;

    // =========================================================================
    // FILAR 2: WALECZNOŚĆ I EKSPOZYCJA TELEWIZYJNA W UCIECZKACH (Waga 25%)
    // =========================================================================
    final double breakawayRating = calculateTeamBreakawayExposure(
      save: currentSave,
      breakawayKmSeason: breakawayKmSeason,
      mostCombativeAwardsSeason: mostCombativeAwardsSeason,
      breakawayStageWinsSeason: breakawayStageWinsSeason,
    );

    double breakawayWeightMultiplier = 1.0;
    if (company.marketingFocus == SponsorMarketingFocus.breakawayExposure) {
      breakawayWeightMultiplier = 1.35; // Sponsor szczególnie pożąda ucieczek!
    } else if (company.marketingFocus == SponsorMarketingFocus.grandTourGlory) {
      breakawayWeightMultiplier = 0.85; // Wolą klasyfikację generalną
    }

    final double breakawayExposureScore = ((breakawayRating / 100.0) * 25.0 * breakawayWeightMultiplier)
        .clamp(0.0, 25.0);

    // =========================================================================
    // FILAR 3: AMBICJA I WIARYGODNOŚĆ OBIETNIC SPORTOWYCH (Waga 20%)
    // =========================================================================
    double promisesScore = 10.0;

    for (final obj in pitchDeck.promisedObjectives) {
      switch (obj) {
        case PromisedObjectiveType.winGrandTourGc:
        case PromisedObjectiveType.podiumGrandTourGc:
          // Wiarygodne tylko, gdy zespół ma kolarza z W/kg > 5.8
          final hasGcLeader = currentSave.playerRoster.any(
            (r) => (r.physiology.criticalPowerWatts / r.physiology.weightKg) >= 5.8,
          );
          if (hasGcLeader) {
            promisesScore += 8.0;
          } else {
            promisesScore -= 6.0; // Puste obietnice obniżają zaufanie
          }
          break;
        case PromisedObjectiveType.winCyclingMonument:
          final hasClassicsLeader = currentSave.playerRoster.any((r) => r.skills.cobbles >= 80 || r.skills.punch >= 82);
          promisesScore += hasClassicsLeader ? 6.0 : -3.0;
          break;
        case PromisedObjectiveType.targetStageWinsCount:
          promisesScore += 4.0;
          break;
        case PromisedObjectiveType.breakawayTvAirtimeKm:
        case PromisedObjectiveType.winMostCombativeAward:
          // Ucieczki są zawsze wiarygodne i pożądane
          promisesScore += 5.0;
          break;
        case PromisedObjectiveType.winPointsGreenJersey:
        case PromisedObjectiveType.winMountainsJersey:
        case PromisedObjectiveType.finishTop5UciTeamRanking:
          promisesScore += 4.0;
          break;
      }
    }
    final double promisesAmbitionScore = promisesScore.clamp(0.0, 20.0);

    // =========================================================================
    // FILAR 4: UCZCIWOŚĆ I REALIZM ŻĄDANEGO BUDŻETU (Waga 15%)
    // =========================================================================
    double budgetScore;
    final int baseBudget = company.baseAnnualBudgetEur;
    final double budgetRatio = pitchDeck.requestedAnnualBudgetEur / baseBudget.toDouble();

    if (budgetRatio <= 0.85) {
      budgetScore = 15.0; // Bardzo korzystna oferta dla sponsora
    } else if (budgetRatio <= 1.05) {
      budgetScore = 13.0 + (1.05 - budgetRatio) * 10.0;
    } else if (budgetRatio <= 1.25) {
      budgetScore = 8.0; // Wyższy budżet do zaakceptowania przy dobrej gwieździe
    } else {
      budgetScore = math.max(0.0, 8.0 - (budgetRatio - 1.25) * 20.0); // Zbyt wysokie żądania
    }
    final double budgetFairnessScore = budgetScore.clamp(0.0, 15.0);

    // =========================================================================
    // FILAR 5: PRESTIŻ DYWIZJI ZESPOŁU (Waga 10%)
    // =========================================================================
    double divisionPrestigeScore;
    switch (playerTeam.division) {
      case TeamDivision.worldTour:
        divisionPrestigeScore = 10.0;
        break;
      case TeamDivision.proTeam:
        divisionPrestigeScore = company.defaultTier == SponsorTier.titlePrimary ? 4.0 : 8.0;
        break;
      case TeamDivision.continental:
        divisionPrestigeScore = company.defaultTier == SponsorTier.titlePrimary ? 1.0 : 4.0;
        break;
    }

    // =========================================================================
    // ŁĄCZNY WYNIK PUNKTOWY I DECYZJA ZARZĄDU
    // =========================================================================
    final double totalScore = (starPowerScore +
            breakawayExposureScore +
            promisesAmbitionScore +
            budgetFairnessScore +
            divisionPrestigeScore)
        .clamp(0.0, 100.0);

    // Weryfikacja minimalnego prestiżu
    if (totalScore < company.minimumTeamPrestigeRequirement) {
      return SponsorPitchResult(
        decision: SponsorNegotiationDecision.rejected,
        overallScore: totalScore,
        offeredAnnualBudgetEur: 0,
        contractDurationYears: 0,
        corporateDirectorQuote: 'Profil waszego zespołu oraz obecne zasięgi medialne nie spełniają naszych standardów korporacyjnych. Dziękujemy za spotkanie.',
        rejectionReason: 'Zbyt niski prestiż medialny i brak wyników na poziomie WorldTour.',
        starPowerScore: starPowerScore,
        breakawayExposureScore: breakawayExposureScore,
        promisesAmbitionScore: promisesAmbitionScore,
        budgetFairnessScore: budgetFairnessScore,
        divisionPrestigeScore: divisionPrestigeScore,
      );
    }

    if (totalScore >= 70.0) {
      // 1. ZAAKCEPTOWANA – Sponsor zgadza się na warunki z Pitch Decku!
      final resultingContract = _buildSponsorContractFromDeck(
        company: company,
        deck: pitchDeck,
        finalAnnualBudgetEur: pitchDeck.requestedAnnualBudgetEur,
      );

      final starName = featuredStar?.fullName ?? 'waszych liderów';
      return SponsorPitchResult(
        decision: SponsorNegotiationDecision.accepted,
        overallScore: totalScore,
        offeredAnnualBudgetEur: pitchDeck.requestedAnnualBudgetEur,
        contractDurationYears: pitchDeck.contractDurationYears,
        corporateDirectorQuote: 'Jesteśmy pod ogromnym wrażeniem waszej strategii i zaangażowania $starName. Wierzymy, że ta współpraca przyniesie naszej marce globalny rozgłos. Podpisujemy umowę!',
        starPowerScore: starPowerScore,
        breakawayExposureScore: breakawayExposureScore,
        promisesAmbitionScore: promisesAmbitionScore,
        budgetFairnessScore: budgetFairnessScore,
        divisionPrestigeScore: divisionPrestigeScore,
        resultingContract: resultingContract,
      );
    } else if (totalScore >= 46.0) {
      // 2. KONTROFERTA – Sponsor proponuje skorygowany budżet
      final int counterBudget = (baseBudget * (0.80 + (totalScore / 100.0) * 0.25) / 50000.0).round() * 50000;
      final resultingContract = _buildSponsorContractFromDeck(
        company: company,
        deck: pitchDeck,
        finalAnnualBudgetEur: counterBudget,
      );

      return SponsorPitchResult(
        decision: SponsorNegotiationDecision.counterOffer,
        overallScore: totalScore,
        offeredAnnualBudgetEur: counterBudget,
        contractDurationYears: pitchDeck.contractDurationYears,
        corporateDirectorQuote: 'Projekt jest obiecujący, jednak żądany budżet przewyższa naszą analizę ROI. Możemy zaoferować €${(counterBudget / 1000000).toStringAsFixed(2)}M rocznie pod warunkiem intensywnej obecności w ucieczkach.',
        starPowerScore: starPowerScore,
        breakawayExposureScore: breakawayExposureScore,
        promisesAmbitionScore: promisesAmbitionScore,
        budgetFairnessScore: budgetFairnessScore,
        divisionPrestigeScore: divisionPrestigeScore,
        resultingContract: resultingContract,
      );
    } else {
      // 3. ODRZUCENIE
      String quote = 'Niestety, zarząd nie wyraził zgody na alokację środków na ten projekt.';
      String reason = 'Niewystarczająca rozpoznawalność medialna lub nierealistyczne obietnice.';

      if (budgetRatio > 1.30) {
        quote = 'Przedstawiony kosztorys drastycznie przekracza nasze ramy budżetowe.';
        reason = 'Zażądano budżetu o ponad 30% wyższego od rynkowej bazy sponsora.';
      } else if (starRating < 45.0) {
        quote = 'W waszej kadrze brakuje kolarza formatu gwiazdy, który przyciągnąłby uwagę kamer na kluczowych etapach.';
        reason = 'Brak lidera o wysokiej popularności medialnej.';
      }

      return SponsorPitchResult(
        decision: SponsorNegotiationDecision.rejected,
        overallScore: totalScore,
        offeredAnnualBudgetEur: 0,
        contractDurationYears: 0,
        corporateDirectorQuote: quote,
        rejectionReason: reason,
        starPowerScore: starPowerScore,
        breakawayExposureScore: breakawayExposureScore,
        promisesAmbitionScore: promisesAmbitionScore,
        budgetFairnessScore: budgetFairnessScore,
        divisionPrestigeScore: divisionPrestigeScore,
      );
    }
  }

  /// Podpisuje oficjalny kontrakt sponsorski i aktualizuje finanse zespołu w bazie zapisu.
  static CareerSave signSponsorContract({
    required CareerSave currentSave,
    required SponsorContract contract,
  }) {
    final playerTeam = currentSave.playerTeam;

    // Aktualizujemy listę sponsorów drużyny
    final updatedSponsors = [...playerTeam.sponsors, contract];

    // Pierwsza transza sponsorska (1/12 budżetu rocznego) trafia od razu na konto klubu!
    final int upfrontTrancheEur = (contract.annualBudgetEur / 12.0).round();

    final updatedTeams = currentSave.teams.map((t) {
      if (t.id == currentSave.playerTeamId) {
        return t.copyWith(
          sponsors: updatedSponsors,
          cashBalanceEur: t.cashBalanceEur + upfrontTrancheEur,
        );
      }
      return t;
    }).toList();

    // Wpis do księgi finansowej
    final ledgerEntry = CareerFinanceLedgerEntry(
      id: 'spons_${DateTime.now().millisecondsSinceEpoch}',
      date: currentSave.currentDate,
      category: FinanceCategory.sponsorPayout,
      amountEur: upfrontTrancheEur,
      description: 'Pierwsza transza kontraktu sponsorskiego: ${contract.companyName} (${contract.sponsorTier.name})',
    );

    return currentSave.copyWith(
      teams: updatedTeams,
      financeLedger: [ledgerEntry, ...currentSave.financeLedger],
      lastSavedAt: DateTime.now(),
    );
  }

  /// Tworzy instancję [SponsorContract] na podstawie zaakceptowanego Pitch Decku.
  static SponsorContract _buildSponsorContractFromDeck({
    required PotentialSponsorCompany company,
    required SponsorPitchDeck deck,
    required int finalAnnualBudgetEur,
  }) {
    final List<SponsorObjective> objectives = [];

    for (int i = 0; i < deck.promisedObjectives.length; i++) {
      final objType = deck.promisedObjectives[i];
      objectives.add(
        SponsorObjective(
          id: 'obj_${DateTime.now().millisecondsSinceEpoch}_$i',
          description: objType.label,
          bonusPaymentEur: objType.defaultBonusEur,
          importance: ObjectiveImportance.high,
          isCompleted: false,
          currentProgress: 0.0,
          targetProgress: (objType == PromisedObjectiveType.breakawayTvAirtimeKm) ? 1200.0 : 1.0,
        ),
      );
    }

    return SponsorContract(
      id: 'spc_${DateTime.now().millisecondsSinceEpoch}_${company.id}',
      companyName: company.name,
      industry: company.industry,
      sponsorTier: deck.proposedTier,
      annualBudgetEur: finalAnnualBudgetEur,
      contractDurationYears: deck.contractDurationYears,
      sponsorSatisfaction: 80.0, // Początkowy wysoki poziom zaufania
      objectives: objectives,
    );
  }
}

