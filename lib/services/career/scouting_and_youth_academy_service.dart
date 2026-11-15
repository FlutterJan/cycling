import 'dart:math' as math;
import '../../models/career/career_save.dart';
import '../../models/rider/rider.dart';
import '../../models/rider/rider_contract.dart';
import '../generators/rider_procedural_generator.dart';

/// Źródło pochodzenia młodego talentu
enum ScoutingSource {
  juniorU19,
  espoirsU23,
  zwiftAcademyVirtual,
  localAmateurCriterium,
  mtbGravelCrossover;

  String toJson() => name;

  static ScoutingSource fromJson(String value) {
    return ScoutingSource.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ScoutingSource.juniorU19,
    );
  }

  String get label {
    switch (this) {
      case ScoutingSource.juniorU19:
        return 'Puchar Narodów & Wyścigi Juniorskie U19';
      case ScoutingSource.espoirsU23:
        return 'Kategoria Młodzieżowa U23 (Avenir / Baby Giro)';
      case ScoutingSource.zwiftAcademyVirtual:
        return 'Platforma e-cycling (Zwift Academy / Trenażery)';
      case ScoutingSource.localAmateurCriterium:
        return 'Wyścigi regionalne & Kryteria amatorskie';
      case ScoutingSource.mtbGravelCrossover:
        return 'Kolarstwo górskie (XCO) & Gravel Crossover';
    }
  }

  String get badgeLabel {
    switch (this) {
      case ScoutingSource.juniorU19:
        return 'JUNIOR U19';
      case ScoutingSource.espoirsU23:
        return 'U23 ESPOIR';
      case ScoutingSource.zwiftAcademyVirtual:
        return 'ZWIFT / E-CYCLING';
      case ScoutingSource.localAmateurCriterium:
        return 'AMATOR / KRYTERIUM';
      case ScoutingSource.mtbGravelCrossover:
        return 'MTB / GRAVEL';
    }
  }

  String get badgeColorHex {
    switch (this) {
      case ScoutingSource.juniorU19:
        return '#4CAF50';
      case ScoutingSource.espoirsU23:
        return '#2196F3';
      case ScoutingSource.zwiftAcademyVirtual:
        return '#FF9800'; // Pomarańczowy Zwift
      case ScoutingSource.localAmateurCriterium:
        return '#9C27B0';
      case ScoutingSource.mtbGravelCrossover:
        return '#795548';
    }
  }
}

/// Stopień odkrycia statystyk młodego kolarza (Mgła Wojny / Fog of War)
enum ScoutingDiscoveryStage {
  /// Poziom 0: Pobieżne doniesienia, szerokie widełki (błąd ±35W FTP, ±7 VO2max, ±12 potencjał)
  rawTalent,

  /// Poziom 1: Obserwacja skauta na wyścigach, zawężone widełki (błąd ±10W FTP, ±2 VO2max, ±4 potencjał)
  scoutedByObserver,

  /// Poziom 2: Testy laboratoryjne w Service Course (100% odkryte VO2max, progi mocy i potencjał)
  laboratoryTested;

  String toJson() => name;

  static ScoutingDiscoveryStage fromJson(String value) {
    return ScoutingDiscoveryStage.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ScoutingDiscoveryStage.rawTalent,
    );
  }

  String get label {
    switch (this) {
      case ScoutingDiscoveryStage.rawTalent:
        return 'Wstępny raport (Ukryte statystyki)';
      case ScoutingDiscoveryStage.scoutedByObserver:
        return 'Zweryfikowany przez skauta (Zawężone widełki)';
      case ScoutingDiscoveryStage.laboratoryTested:
        return 'Pełny audyt laboratoryjny (100% odkryte)';
    }
  }
}

/// Młody zawodnik w puli skautingowej klubu z ukrytymi statystykami
class ScoutedProspect {
  final String id;
  final String firstName;
  final String lastName;
  final String nationalityIso;
  final int age;
  final ScoutingSource source;
  final ScoutingDiscoveryStage discoveryStage;

  // Szacowane widełki (widoczne dla gracza w zależności od discoveryStage)
  final int estimatedMinFtpWatts;
  final int estimatedMaxFtpWatts;
  final double estimatedMinVo2Max;
  final double estimatedMaxVo2Max;
  final int estimatedMinPotential;
  final int estimatedMaxPotential;
  final RiderSpecialization? probableSpecialization;
  final String scoutReport;

  // Rzeczywisty, podkładowy model kolarza (ujawniany w miarę postępów)
  final Rider trueRider;

  final bool isEnrolledInAcademy;
  final bool isPromotedToProTeam;

  const ScoutedProspect({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.nationalityIso,
    required this.age,
    required this.source,
    required this.discoveryStage,
    required this.estimatedMinFtpWatts,
    required this.estimatedMaxFtpWatts,
    required this.estimatedMinVo2Max,
    required this.estimatedMaxVo2Max,
    required this.estimatedMinPotential,
    required this.estimatedMaxPotential,
    this.probableSpecialization,
    required this.scoutReport,
    required this.trueRider,
    this.isEnrolledInAcademy = false,
    this.isPromotedToProTeam = false,
  });

  String get fullName => '$firstName $lastName';

  /// Czy zawodnik jest w pełni przebadany w laboratorium
  bool get isFullyRevealed =>
      discoveryStage == ScoutingDiscoveryStage.laboratoryTested;

  /// Czy zawodnik był obserwowany przez skauta
  bool get isScouted =>
      discoveryStage == ScoutingDiscoveryStage.scoutedByObserver ||
      discoveryStage == ScoutingDiscoveryStage.laboratoryTested;

  /// Reprezentacja widełek FTP (np. "320 - 360 W" lub "345 W")
  String get ftpDisplay {
    if (isFullyRevealed) {
      return '${(trueRider.powerProfile.watts20m * 0.95).round()} W';
    }
    return '$estimatedMinFtpWatts – $estimatedMaxFtpWatts W';
  }

  /// Reprezentacja widełek VO2max (np. "74 - 82 ml/kg" lub "79.2 ml/kg")
  String get vo2MaxDisplay {
    if (isFullyRevealed) {
      final weight = trueRider.physiology.weightKg > 0 ? trueRider.physiology.weightKg : 70.0;
      final realVo2 = (trueRider.powerProfile.watts5m / weight) * 11.2;
      return '${realVo2.toStringAsFixed(1)} ml/kg/min';
    }
    return '${estimatedMinVo2Max.toStringAsFixed(0)} – ${estimatedMaxVo2Max.toStringAsFixed(0)} ml/kg/min';
  }

  /// Reprezentacja szacowanego potencjału w gwiazdkach lub punktach
  String get potentialDisplay {
    if (isFullyRevealed) {
      final pot = trueRider.potential;
      if (pot >= 94) return '$pot pkt (Diament Generacji 5★)';
      if (pot >= 86) return '$pot pkt (Perspektywa WT 4★)';
      if (pot >= 78) return '$pot pkt (Solidny Pro 3★)';
      return '$pot pkt (Poziom Kontynentalny 2★)';
    }
    return '$estimatedMinPotential – $estimatedMaxPotential pkt';
  }

  ScoutedProspect copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? nationalityIso,
    int? age,
    ScoutingSource? source,
    ScoutingDiscoveryStage? discoveryStage,
    int? estimatedMinFtpWatts,
    int? estimatedMaxFtpWatts,
    double? estimatedMinVo2Max,
    double? estimatedMaxVo2Max,
    int? estimatedMinPotential,
    int? estimatedMaxPotential,
    RiderSpecialization? probableSpecialization,
    String? scoutReport,
    Rider? trueRider,
    bool? isEnrolledInAcademy,
    bool? isPromotedToProTeam,
  }) {
    return ScoutedProspect(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      nationalityIso: nationalityIso ?? this.nationalityIso,
      age: age ?? this.age,
      source: source ?? this.source,
      discoveryStage: discoveryStage ?? this.discoveryStage,
      estimatedMinFtpWatts: estimatedMinFtpWatts ?? this.estimatedMinFtpWatts,
      estimatedMaxFtpWatts: estimatedMaxFtpWatts ?? this.estimatedMaxFtpWatts,
      estimatedMinVo2Max: estimatedMinVo2Max ?? this.estimatedMinVo2Max,
      estimatedMaxVo2Max: estimatedMaxVo2Max ?? this.estimatedMaxVo2Max,
      estimatedMinPotential:
          estimatedMinPotential ?? this.estimatedMinPotential,
      estimatedMaxPotential:
          estimatedMaxPotential ?? this.estimatedMaxPotential,
      probableSpecialization:
          probableSpecialization ?? this.probableSpecialization,
      scoutReport: scoutReport ?? this.scoutReport,
      trueRider: trueRider ?? this.trueRider,
      isEnrolledInAcademy: isEnrolledInAcademy ?? this.isEnrolledInAcademy,
      isPromotedToProTeam: isPromotedToProTeam ?? this.isPromotedToProTeam,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'nationalityIso': nationalityIso,
      'age': age,
      'source': source.toJson(),
      'discoveryStage': discoveryStage.toJson(),
      'estimatedMinFtpWatts': estimatedMinFtpWatts,
      'estimatedMaxFtpWatts': estimatedMaxFtpWatts,
      'estimatedMinVo2Max': estimatedMinVo2Max,
      'estimatedMaxVo2Max': estimatedMaxVo2Max,
      'estimatedMinPotential': estimatedMinPotential,
      'estimatedMaxPotential': estimatedMaxPotential,
      'probableSpecialization': probableSpecialization?.toJson(),
      'scoutReport': scoutReport,
      'trueRider': trueRider.toJson(),
      'isEnrolledInAcademy': isEnrolledInAcademy,
      'isPromotedToProTeam': isPromotedToProTeam,
    };
  }

  factory ScoutedProspect.fromJson(Map<String, dynamic> json) {
    return ScoutedProspect(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      nationalityIso: json['nationalityIso'] as String,
      age: (json['age'] as num).toInt(),
      source: ScoutingSource.fromJson(json['source'] as String),
      discoveryStage:
          ScoutingDiscoveryStage.fromJson(json['discoveryStage'] as String),
      estimatedMinFtpWatts: (json['estimatedMinFtpWatts'] as num).toInt(),
      estimatedMaxFtpWatts: (json['estimatedMaxFtpWatts'] as num).toInt(),
      estimatedMinVo2Max: (json['estimatedMinVo2Max'] as num).toDouble(),
      estimatedMaxVo2Max: (json['estimatedMaxVo2Max'] as num).toDouble(),
      estimatedMinPotential: (json['estimatedMinPotential'] as num).toInt(),
      estimatedMaxPotential: (json['estimatedMaxPotential'] as num).toInt(),
      probableSpecialization: json['probableSpecialization'] != null
          ? RiderSpecialization.fromJson(json['probableSpecialization'] as String)
          : null,
      scoutReport: json['scoutReport'] as String,
      trueRider: Rider.fromJson(json['trueRider'] as Map<String, dynamic>),
      isEnrolledInAcademy: json['isEnrolledInAcademy'] as bool? ?? false,
      isPromotedToProTeam: json['isPromotedToProTeam'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScoutedProspect && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Akademia Młodzieżowa / Zespół Rozwojowy drużyny (Youth Development Squad)
class YouthAcademy {
  final int level; // 1 - 5
  final List<String> enrolledProspectIds;

  const YouthAcademy({
    this.level = 1,
    this.enrolledProspectIds = const [],
  });

  /// Maksymalna liczba adeptów w akademii
  int get maxCapacity => level * 4; // 4, 8, 12, 16, 20

  /// Miesięczny koszt utrzymania akademii w Euro
  int get monthlyMaintenanceCostEur => level * 3500;

  /// Roczny mnożnik przyrostu umiejętności pod okiem trenerów akademii
  double get developmentMultiplier => 1.0 + (level * 0.15);

  String get levelName {
    switch (level) {
      case 1:
        return 'Szkółka Regionalna U19';
      case 2:
        return 'Klub Młodzieżowy U23';
      case 3:
        return 'Akademia Kolarska z Bazą Sprzętową';
      case 4:
        return 'Oficjalny Zespół Rozwojowy (Continental Devo Team)';
      case 5:
        return 'Elitarna Akademia ProTour WorldTeam';
      default:
        return 'Akademia Poziom $level';
    }
  }

  YouthAcademy copyWith({
    int? level,
    List<String>? enrolledProspectIds,
  }) {
    return YouthAcademy(
      level: level ?? this.level,
      enrolledProspectIds: enrolledProspectIds != null
          ? List.unmodifiable(enrolledProspectIds)
          : this.enrolledProspectIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'enrolledProspectIds': enrolledProspectIds,
    };
  }

  factory YouthAcademy.fromJson(Map<String, dynamic> json) {
    return YouthAcademy(
      level: (json['level'] as num?)?.toInt() ?? 1,
      enrolledProspectIds: (json['enrolledProspectIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }
}

/// Wynik misji skautingowej
class ScoutingMissionOutcome {
  final CareerSave updatedSave;
  final ScoutingSource source;
  final int scoutsSentCount;
  final int totalCostEur;
  final List<ScoutedProspect> discoveredOrUpdatedProspects;
  final String summary;

  const ScoutingMissionOutcome({
    required this.updatedSave,
    required this.source,
    required this.scoutsSentCount,
    required this.totalCostEur,
    required this.discoveredOrUpdatedProspects,
    required this.summary,
  });
}

/// Wynik testów laboratoryjnych młodego talentu
class ProspectLabTestingOutcome {
  final CareerSave updatedSave;
  final ScoutedProspect prospect;
  final double measuredFtpWatts;
  final double measuredVo2Max;
  final int measuredPotential;
  final int costEur;
  final String labCertificate;

  const ProspectLabTestingOutcome({
    required this.updatedSave,
    required this.prospect,
    required this.measuredFtpWatts,
    required this.measuredVo2Max,
    required this.measuredPotential,
    required this.costEur,
    required this.labCertificate,
  });
}

/// Serwis skautingu młodych kolarzy oraz akademii młodzieżowej (Youth Development Team).
///
/// Funkcjonalności:
/// 1. Generowanie puli adeptów U19/U23/Zwift z ukrytymi statystykami (widełki FTP, VO2max, potencjału).
/// 2. Wysyłanie skautów w teren w celu zawężenia widełek parametrów i weryfikacji specjalizacji.
/// 3. Zapraszanie zawodników na badania laboratoryjne w Service Course (100% odkrycie cech fizjologicznych).
/// 4. Zarządzanie Akademią Młodzieżową (zapisywanie adeptów, comiesięczny rozwój, awans do pierwszego zespołu).
class ScoutingAndYouthAcademyService {
  ScoutingAndYouthAcademyService._();

  // ===========================================================================
  // GENEROWANIE POCZĄTKOWEJ PULI TALENTÓW
  // ===========================================================================

  /// Tworzy realistyczną pulę adeptów z ukrytymi statystykami (widełkami)
  static List<ScoutedProspect> generateInitialScoutingPool({
    required int seasonYear,
    int count = 28,
    math.Random? random,
  }) {
    final rng = random ?? math.Random();
    final List<ScoutedProspect> prospects = [];

    const sources = ScoutingSource.values;

    for (int i = 0; i < count; i++) {
      final source = sources[i % sources.length];

      // Dobieramy tier kolarza
      ScoutingTier tier;
      final roll = rng.nextDouble();
      if (roll < 0.05) {
        tier = ScoutingTier.generationalTalent; // 5% diament
      } else if (roll < 0.25) {
        tier = ScoutingTier.worldTourProspect; // 20% prospekt WT
      } else if (roll < 0.65) {
        tier = ScoutingTier.solidPro; // 40% solid pro
      } else {
        tier = ScoutingTier.continentalHopeful; // 35% continental
      }

      final trueRider = RiderProceduralGenerator.generateNeoProTalent(
        currentSeasonYear: seasonYear,
        tier: tier,
        random: rng,
      );

      // Obliczamy prawdziwe wartości, aby na ich podstawie stworzyć widełki początkowe
      final trueFtp = trueRider.powerProfile.watts20m * 0.95;
      final weight = trueRider.physiology.weightKg > 0 ? trueRider.physiology.weightKg : 70.0;
      final trueVo2 = (trueRider.powerProfile.watts5m / weight) * 11.2;
      final truePot = trueRider.potential;

      // Szum losowy dla szerokich widełek (Poziom 0)
      final ftpNoise = (rng.nextDouble() * 20.0 - 10.0);
      final int minFtp = (trueFtp - 35 + ftpNoise).round().clamp(240, 480);
      final int maxFtp = (trueFtp + 35 + ftpNoise).round().clamp(270, 520);

      final vo2Noise = (rng.nextDouble() * 4.0 - 2.0);
      final double minVo2 = (trueVo2 - 7.0 + vo2Noise).clamp(50.0, 92.0);
      final double maxVo2 = (trueVo2 + 7.0 + vo2Noise).clamp(55.0, 98.0);

      final potNoise = (rng.nextInt(7) - 3);
      final int minPot = (truePot - 12 + potNoise).clamp(55, 99);
      final int maxPot = (truePot + 12 + potNoise).clamp(65, 99);

      // Prawdopodobna specjalizacja z 65% dokładnością na start
      RiderSpecialization probableSpec = trueRider.specialization;
      if (rng.nextDouble() > 0.65) {
        const allSpecs = RiderSpecialization.values;
        probableSpec = allSpecs[rng.nextInt(allSpecs.length)];
      }

      String initialReport;
      switch (source) {
        case ScoutingSource.juniorU19:
          initialReport =
              'Wyróżniający się junior z wyścigów Pucharu Narodów. Nienaganna sylwetka, ale wymaga weryfikacji progu mleczanowego.';
          break;
        case ScoutingSource.espoirsU23:
          initialReport =
              'Doświadczony młodzieżowiec po startach w Tour de l\'Avenir. Dobrze znosi obciążenia wieloetapowe.';
          break;
        case ScoutingSource.zwiftAcademyVirtual:
          initialReport =
              'Potężny silnik tlenowy z trenażera bezpośredniego. Generuje wysokie waty bezwzględne, lecz wymaga nauki jazdy w peletonie.';
          break;
        case ScoutingSource.localAmateurCriterium:
          initialReport =
              'Niezrzeszony amator z kryteriów ulicznych. Agresywny styl walki na finiszach, duża dynamika przyspieszenia.';
          break;
        case ScoutingSource.mtbGravelCrossover:
          initialReport =
              'Przechodzi z kolarstwa górskiego XCO. Wybitna technika prowadzenia roweru i wysoki pułap beztlenowy.';
          break;
      }

      prospects.add(
        ScoutedProspect(
          id: 'prospect_${seasonYear}_${i + 1}_${trueRider.nationalityIso.toLowerCase()}',
          firstName: trueRider.firstName,
          lastName: trueRider.lastName,
          nationalityIso: trueRider.nationalityIso,
          age: trueRider.age,
          source: source,
          discoveryStage: ScoutingDiscoveryStage.rawTalent,
          estimatedMinFtpWatts: minFtp,
          estimatedMaxFtpWatts: maxFtp,
          estimatedMinVo2Max: minVo2,
          estimatedMaxVo2Max: maxVo2,
          estimatedMinPotential: minPot,
          estimatedMaxPotential: maxPot,
          probableSpecialization: probableSpec,
          scoutReport: initialReport,
          trueRider: trueRider,
          isEnrolledInAcademy: false,
          isPromotedToProTeam: false,
        ),
      );
    }

    return List<ScoutedProspect>.unmodifiable(prospects);
  }

  // ===========================================================================
  // WYSYŁANIE SKAUTA W TEREN (ZAWĘŻANIE WIDEŁEK)
  // ===========================================================================

  /// Wysyła skauta na zawody w celu weryfikacji adeptów i zawężenia widełek parametrów
  static ScoutingMissionOutcome sendScoutOnMission({
    required CareerSave save,
    required ScoutingSource source,
    String? targetRegion,
  }) {
    final team = save.playerTeam;
    final scoutLevel = team.staff.scoutsLevel;

    // Koszt misji w zależności od źródła
    int missionCost;
    switch (source) {
      case ScoutingSource.juniorU19:
        missionCost = 2800;
        break;
      case ScoutingSource.espoirsU23:
        missionCost = 3500;
        break;
      case ScoutingSource.zwiftAcademyVirtual:
        missionCost = 1800; // Analiza telemetrii serwerowej
        break;
      case ScoutingSource.localAmateurCriterium:
        missionCost = 1400;
        break;
      case ScoutingSource.mtbGravelCrossover:
        missionCost = 2200;
        break;
    }

    if (team.cashBalanceEur < missionCost) {
      throw StateError(
        'Niewystarczające środki na misję skautingową! Koszt: €$missionCost, dostępne: €${team.cashBalanceEur}.',
      );
    }

    final rng = math.Random();
    final List<ScoutedProspect> currentPool = save.scoutingProspects.isNotEmpty
        ? List.from(save.scoutingProspects)
        : generateInitialScoutingPool(seasonYear: save.currentSeasonYear);

    // Wybieramy do 4 adeptów z danego źródła, którzy nie byli jeszcze w pełni zbadani
    final candidates = currentPool
        .where((p) =>
            p.source == source &&
            p.discoveryStage == ScoutingDiscoveryStage.rawTalent)
        .take(4)
        .toList();

    final List<ScoutedProspect> updatedInMission = [];

    for (final p in candidates) {
      final trueFtp = (p.trueRider.powerProfile.watts20m * 0.95).round();
      final weight = p.trueRider.physiology.weightKg > 0 ? p.trueRider.physiology.weightKg : 70.0;
      final trueVo2 = (p.trueRider.powerProfile.watts5m / weight) * 11.2;
      final truePot = p.trueRider.potential;

      // Wyższy poziom skauta daje węższy margines błędu
      final precisionMarginFtp = (14 - (scoutLevel / 100.0 * 6)).round(); // 8 - 14 W
      final precisionMarginVo2 = (2.5 - (scoutLevel / 100.0 * 1.0)); // 1.5 - 2.5 ml/kg
      final precisionMarginPot = (5 - (scoutLevel / 100.0 * 2)).round(); // 3 - 5 pkt

      final updated = p.copyWith(
        discoveryStage: ScoutingDiscoveryStage.scoutedByObserver,
        estimatedMinFtpWatts: trueFtp - precisionMarginFtp,
        estimatedMaxFtpWatts: trueFtp + precisionMarginFtp,
        estimatedMinVo2Max: (trueVo2 - precisionMarginVo2).clamp(52.0, 95.0),
        estimatedMaxVo2Max: (trueVo2 + precisionMarginVo2).clamp(55.0, 98.0),
        estimatedMinPotential: (truePot - precisionMarginPot).clamp(60, 99),
        estimatedMaxPotential: (truePot + precisionMarginPot).clamp(65, 99),
        probableSpecialization: p.trueRider.specialization, // Skaut bezbłędnie rozpoznaje specjalizację
        scoutReport:
            'Raport skauta (Dział Skautingu: $scoutLevel/100): Kolarz obserwowany na 3 wyścigach. Potwierdzona specjalizacja: ${p.trueRider.specialization.name}. Wysoka etyka pracy i świetna kadencja. Rekomendowane testy laboratoryjne.',
      );

      updatedInMission.add(updated);

      final idx = currentPool.indexWhere((item) => item.id == p.id);
      if (idx >= 0) {
        currentPool[idx] = updated;
      }
    }

    // Aktualizujemy saldo klubu
    final updatedTeams = save.teams.map((t) {
      if (t.id == team.id) {
        return t.copyWith(cashBalanceEur: t.cashBalanceEur - missionCost);
      }
      return t;
    }).toList();

    final ledgerEntry = CareerFinanceLedgerEntry(
      id: 'scout_${DateTime.now().millisecondsSinceEpoch}',
      date: save.currentDate,
      category: FinanceCategory.scoutingCosts,
      amountEur: -missionCost,
      description: 'Misja skautingowa: ${source.label} (${updatedInMission.length} zweryfikowanych talentów)',
    );

    final updatedSave = save.copyWith(
      teams: updatedTeams,
      scoutingProspects: currentPool,
      financeLedger: [ledgerEntry, ...save.financeLedger],
      lastSavedAt: DateTime.now(),
    );

    return ScoutingMissionOutcome(
      updatedSave: updatedSave,
      source: source,
      scoutsSentCount: 1,
      totalCostEur: missionCost,
      discoveredOrUpdatedProspects: updatedInMission,
      summary:
          'Skaut powrócił z misji (${source.label}). Szczegółowo zbadano ${updatedInMission.length} młodych kolarzy, zawężając widełki parametrów mocy i potencjału.',
    );
  }

  // ===========================================================================
  // TESTY LABORATORYJNE ADEPTA (100% ODKRYCIE CECH)
  // ===========================================================================

  /// Zaprasza młodego adepta na oficjalne badania laboratoryjne do bazy zespołu (100% odkrycia)
  static ProspectLabTestingOutcome inviteProspectToLabTesting({
    required CareerSave save,
    required String prospectId,
  }) {
    final team = save.playerTeam;
    const testCost = 1200; // Koszt ergospirometrii i kalibracji mocy

    if (team.cashBalanceEur < testCost) {
      throw StateError(
        'Brak wystarczających środków na badania laboratoryjne! Koszt: €$testCost, dostępne: €${team.cashBalanceEur}.',
      );
    }

    final pool = List<ScoutedProspect>.from(save.scoutingProspects);
    final idx = pool.indexWhere((p) => p.id == prospectId);
    if (idx < 0) {
      throw ArgumentError('Nie znaleziono adepta o ID: $prospectId');
    }

    final prospect = pool[idx];
    final trueRider = prospect.trueRider;

    final realFtp = (trueRider.powerProfile.watts20m * 0.95).round();
    final weight = trueRider.physiology.weightKg > 0 ? trueRider.physiology.weightKg : 70.0;
    final realVo2 = (trueRider.powerProfile.watts5m / weight) * 11.2;
    final realPot = trueRider.potential;

    final certificate = StringBuffer();
    certificate.writeln('OFICJALNY CERTYFIKAT MEDYCYNY SPORTOWEJ');
    certificate.writeln('Kolarz: ${prospect.fullName} (${prospect.age} lat, ${prospect.nationalityIso})');
    certificate.writeln('Pochodzenie: ${prospect.source.label}');
    certificate.writeln('Data badania: ${save.currentDate.toIso8601String().substring(0, 10)}\n');
    certificate.writeln('POMIARY ERGOSPIROMETRYCZNE & PROGI MOCY:');
    certificate.writeln(' • Zmierzony pułap tlenowy VO2max: ${realVo2.toStringAsFixed(1)} ml/kg/min');
    certificate.writeln(' • Próg anaerobowy FTP (60 min): $realFtp W (${(realFtp / weight).toStringAsFixed(2)} W/kg)');
    certificate.writeln(' • Moc 5-minutowa VO2peak: ${trueRider.powerProfile.watts5m.round()} W');
    certificate.writeln(' • Moc 1-minutowa Anaerobic: ${trueRider.powerProfile.watts1m.round()} W');
    certificate.writeln(' • Sprint 5s Neuromuscular: ${trueRider.powerProfile.watts5s.round()} W');
    certificate.writeln(' • Wskaźnik potencjału rozwojowego: $realPot / 100 pkt');

    if (realPot >= 94) {
      certificate.writeln('\nOCENA GŁÓWNEGO FIZJOLOGA:');
      certificate.writeln('★★★ DIAMENT GENERACJI ★★★');
      certificate.writeln('Unikalna kinetyka poboru tlenu i niezwykła pojemność beztlenowa. Kolarz formatu Evenepoela lub Pogačara.');
    } else if (realPot >= 86) {
      certificate.writeln('\nOCENA GŁÓWNEGO FIZJOLOGA:');
      certificate.writeln('Perspektywa WorldTour (4★). Znakomity silnik tlenowy, predyspozycje do wygrywania etapów w Grand Tourach.');
    } else {
      certificate.writeln('\nOCENA GŁÓWNEGO FIZJOLOGA:');
      certificate.writeln('Solidny rzemieślnik peletonu zawodowego. Wspaniały kandydat na lojalnego pomocnika.');
    }

    final revealedProspect = prospect.copyWith(
      discoveryStage: ScoutingDiscoveryStage.laboratoryTested,
      estimatedMinFtpWatts: realFtp,
      estimatedMaxFtpWatts: realFtp,
      estimatedMinVo2Max: realVo2,
      estimatedMaxVo2Max: realVo2,
      estimatedMinPotential: realPot,
      estimatedMaxPotential: realPot,
      probableSpecialization: trueRider.specialization,
      scoutReport: certificate.toString(),
    );

    pool[idx] = revealedProspect;

    // Aktualizujemy saldo klubu
    final updatedTeams = save.teams.map((t) {
      if (t.id == team.id) {
        return t.copyWith(cashBalanceEur: t.cashBalanceEur - testCost);
      }
      return t;
    }).toList();

    final ledgerEntry = CareerFinanceLedgerEntry(
      id: 'lab_${DateTime.now().millisecondsSinceEpoch}',
      date: save.currentDate,
      category: FinanceCategory.scoutingCosts,
      amountEur: -testCost,
      description: 'Badania laboratoryjne młodego adepta: ${prospect.fullName}',
    );

    final updatedSave = save.copyWith(
      teams: updatedTeams,
      scoutingProspects: pool,
      scoutedRiderIds: [...save.scoutedRiderIds, prospect.id],
      financeLedger: [ledgerEntry, ...save.financeLedger],
      lastSavedAt: DateTime.now(),
    );

    return ProspectLabTestingOutcome(
      updatedSave: updatedSave,
      prospect: revealedProspect,
      measuredFtpWatts: realFtp.toDouble(),
      measuredVo2Max: realVo2,
      measuredPotential: realPot,
      costEur: testCost,
      labCertificate: certificate.toString(),
    );
  }

  // ===========================================================================
  // ZARZĄDZANIE AKADEMIĄ MŁODZIEŻOWĄ (DEVELOPMENT SQUAD)
  // ===========================================================================

  /// Podpisuje zbadanego adepta do Akademii Młodzieżowej klubu
  static CareerSave enrollProspectInAcademy({
    required CareerSave save,
    required String prospectId,
  }) {
    final academy = save.youthAcademy;
    if (academy.enrolledProspectIds.length >= academy.maxCapacity) {
      throw StateError(
        'Akademia młodzieżowa osiągnęła maksymalną pojemność (${academy.enrolledProspectIds.length}/${academy.maxCapacity} adeptów)! Rozbuduj akademię na wyższy poziom.',
      );
    }

    final pool = List<ScoutedProspect>.from(save.scoutingProspects);
    final idx = pool.indexWhere((p) => p.id == prospectId);
    if (idx < 0) {
      throw ArgumentError('Nie znaleziono adepta o ID: $prospectId');
    }

    final prospect = pool[idx];
    if (prospect.isEnrolledInAcademy || prospect.isPromotedToProTeam) {
      return save; // Już zapisany
    }

    final updatedProspect = prospect.copyWith(isEnrolledInAcademy: true);
    pool[idx] = updatedProspect;

    final updatedAcademy = academy.copyWith(
      enrolledProspectIds: [...academy.enrolledProspectIds, prospectId],
    );

    return save.copyWith(
      scoutingProspects: pool,
      youthAcademy: updatedAcademy,
      lastSavedAt: DateTime.now(),
    );
  }

  /// Promuje wychowanka z Akademii lub Puli Skautingowej bezpośrednio do pierwszego zespołu
  static CareerSave promoteProspectToProTeam({
    required CareerSave save,
    required String prospectId,
    RiderRole role = RiderRole.neoPro,
    int? monthlySalaryEur,
  }) {
    final pool = List<ScoutedProspect>.from(save.scoutingProspects);
    final idx = pool.indexWhere((p) => p.id == prospectId);
    if (idx < 0) {
      throw ArgumentError('Nie znaleziono adepta o ID: $prospectId');
    }

    final prospect = pool[idx];
    final trueRider = prospect.trueRider;

    // Tworzymy profesjonalny kontrakt zawodowy w zespole gracza
    final salary = monthlySalaryEur ?? (2500 + (trueRider.overallRating - 60) * 200);

    final proContract = trueRider.contract.copyWith(
      teamId: save.playerTeamId,
      role: role,
      monthlySalaryEur: salary,
      contractEndYear: save.currentSeasonYear + 2, // 2-letni kontrakt dla młodego kolarza
      morale: 0.98, // Ogromna motywacja z podpisania profesjonalnego kontraktu
      leaderLoyalty: 0.90,
    );

    final promotedRider = trueRider.copyWith(
      contract: proContract,
    );

    // Oznaczamy w puli jako awansowanego
    pool[idx] = prospect.copyWith(
      isPromotedToProTeam: true,
      isEnrolledInAcademy: false,
    );

    // Usuwamy z akademii jeśli tam był
    final updatedAcademy = save.youthAcademy.copyWith(
      enrolledProspectIds: List<String>.from(save.youthAcademy.enrolledProspectIds)
        ..remove(prospectId),
    );

    // Dodajemy kolarza do bazy zawodników i składu drużyny
    final updatedRosterIds = List<String>.from(save.playerTeam.rosterRiderIds)
      ..add(promotedRider.id);

    final updatedTeams = save.teams.map((t) {
      if (t.id == save.playerTeamId) {
        return t.copyWith(rosterRiderIds: updatedRosterIds);
      }
      return t;
    }).toList();

    final updatedRiders = [promotedRider, ...save.riders];

    return save.copyWith(
      teams: updatedTeams,
      riders: updatedRiders,
      scoutingProspects: pool,
      youthAcademy: updatedAcademy,
      lastSavedAt: DateTime.now(),
    );
  }

  /// Rozbudowuje Akademię Młodzieżową na wyższy poziom (1 -> 5)
  static CareerSave upgradeYouthAcademy({required CareerSave save}) {
    final currentLevel = save.youthAcademy.level;
    if (currentLevel >= 5) {
      throw StateError('Akademia Młodzieżowa osiągnęła już maksymalny 5. poziom (Elita ProTour)!');
    }

    final upgradeCost = (currentLevel + 1) * 180000;
    if (save.playerTeam.cashBalanceEur < upgradeCost) {
      throw StateError(
        'Brak wystarczających środków na rozbudowę akademii! Koszt: €$upgradeCost, dostępne: €${save.playerTeam.cashBalanceEur}.',
      );
    }

    final updatedAcademy = save.youthAcademy.copyWith(level: currentLevel + 1);

    final updatedTeams = save.teams.map((t) {
      if (t.id == save.playerTeamId) {
        return t.copyWith(cashBalanceEur: t.cashBalanceEur - upgradeCost);
      }
      return t;
    }).toList();

    final ledgerEntry = CareerFinanceLedgerEntry(
      id: 'acad_up_${DateTime.now().millisecondsSinceEpoch}',
      date: save.currentDate,
      category: FinanceCategory.facilityUpgrade,
      amountEur: -upgradeCost,
      description: 'Rozbudowa Akademii Młodzieżowej na poziom ${currentLevel + 1} (${updatedAcademy.levelName})',
    );

    return save.copyWith(
      youthAcademy: updatedAcademy,
      teams: updatedTeams,
      financeLedger: [ledgerEntry, ...save.financeLedger],
      lastSavedAt: DateTime.now(),
    );
  }

  /// Przeprowadza comiesięczną progresję rozwoju kolarzy w Akademii Młodzieżowej
  static CareerSave processMonthlyAcademyDevelopment({required CareerSave save}) {
    if (save.youthAcademy.enrolledProspectIds.isEmpty) return save;

    final pool = List<ScoutedProspect>.from(save.scoutingProspects);
    final multiplier = save.youthAcademy.developmentMultiplier;
    final rng = math.Random();

    for (int i = 0; i < pool.length; i++) {
      final prospect = pool[i];
      if (prospect.isEnrolledInAcademy) {
        final rider = prospect.trueRider;
        // Trening w akademii podnosi parametry proporcjonalnie do poziomu akademii
        final powerBoost = (1.5 * multiplier + rng.nextDouble()).round();

        final updatedPower = rider.powerProfile.copyWith(
          watts20m: rider.powerProfile.watts20m + powerBoost,
          watts5m: rider.powerProfile.watts5m + (powerBoost * 1.2).round(),
        );

        final updatedRider = rider.copyWith(powerProfile: updatedPower);
        pool[i] = prospect.copyWith(trueRider: updatedRider);
      }
    }

    return save.copyWith(
      scoutingProspects: pool,
      lastSavedAt: DateTime.now(),
    );
  }
}

