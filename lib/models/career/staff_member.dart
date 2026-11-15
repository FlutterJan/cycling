// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import '../rider/rider.dart';
import '../team/cycling_team.dart';

/// Rola i specjalizacja członka sztabu szkoleniowo-technicznego.
enum StaffRole {
  sportsDirector,
  performanceCoach,
  teamDoctor,
  headMechanic,
  scout;

  String get displayName {
    switch (this) {
      case StaffRole.sportsDirector:
        return 'Dyrektor Sportowy';
      case StaffRole.performanceCoach:
        return 'Trener Przygotowania Fizycznego';
      case StaffRole.teamDoctor:
        return 'Lekarz Klubowy';
      case StaffRole.headMechanic:
        return 'Główny Mechanik';
      case StaffRole.scout:
        return 'Skaut Talentów';
    }
  }

  String toJson() => name;

  static StaffRole fromJson(String value) {
    return StaffRole.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => StaffRole.sportsDirector,
    );
  }
}

/// Filozofia taktyczna Dyrektora Sportowego w wozie technicznym.
enum DirectorTacticalPhilosophy {
  aggressiveAttacking,
  cautiousDefensive,
  breakawayGambler,
  sprinterTrainSpecialist,
  gcCalculator;

  String get displayName {
    switch (this) {
      case DirectorTacticalPhilosophy.aggressiveAttacking:
        return 'Agresywny Atak (Ranty i Odjazdy)';
      case DirectorTacticalPhilosophy.cautiousDefensive:
        return 'Ostrożna Defensywa (Kontrola GC)';
      case DirectorTacticalPhilosophy.breakawayGambler:
        return 'Łowca Ucieczek (Etapowe Rajdy)';
      case DirectorTacticalPhilosophy.sprinterTrainSpecialist:
        return 'Mistrz Pociągu Sprinterskiego';
      case DirectorTacticalPhilosophy.gcCalculator:
        return 'Kalkulator Klasyfikacji Generalnej';
    }
  }

  String toJson() => name;

  static DirectorTacticalPhilosophy fromJson(String value) {
    return DirectorTacticalPhilosophy.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => DirectorTacticalPhilosophy.gcCalculator,
    );
  }
}

/// Specjalizacja Trenera Przygotowania Fizycznego i Motorycznego.
enum CoachSpecialization {
  enduranceAndClimbing,
  sprintAndExplosiveness,
  timeTrialAero,
  allRoundDevelopment;

  String get displayName {
    switch (this) {
      case CoachSpecialization.enduranceAndClimbing:
        return 'Wytrzymałość & Góry (FTP i W/kg)';
      case CoachSpecialization.sprintAndExplosiveness:
        return 'Moc Eksplozywna & Sprint (W15s)';
      case CoachSpecialization.timeTrialAero:
        return 'Jazda Indywidualna na Czas (TT)';
      case CoachSpecialization.allRoundDevelopment:
        return 'Wszechstronny Rozwój Kolarza';
    }
  }

  String toJson() => name;

  static CoachSpecialization fromJson(String value) {
    return CoachSpecialization.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CoachSpecialization.allRoundDevelopment,
    );
  }
}

/// Specjalizacja kliniczna Lekarza Klubowego.
enum DoctorSpecialization {
  orthopedicsAndTrauma,
  sportsCardiologyAndHematology,
  infectiousDiseaseAndNutrition;

  String get displayName {
    switch (this) {
      case DoctorSpecialization.orthopedicsAndTrauma:
        return 'Ortopedia & Traumatologia (Złamania i Szlify)';
      case DoctorSpecialization.sportsCardiologyAndHematology:
        return 'Kardiologia & Hematologia (Badania Krwi)';
      case DoctorSpecialization.infectiousDiseaseAndNutrition:
        return 'Prewencja Infekcji & Żywienie Kliniczne';
    }
  }

  String toJson() => name;

  static DoctorSpecialization fromJson(String value) {
    return DoctorSpecialization.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => DoctorSpecialization.sportsCardiologyAndHematology,
    );
  }
}

/// Region geograficzny penetrowany przez Skauta Talentów.
enum ScoutingRegion {
  westernEurope,
  easternEurope,
  colombiaAndSouthAmerica,
  northAmerica,
  africa,
  oceania,
  scandinavia;

  String get displayName {
    switch (this) {
      case ScoutingRegion.westernEurope:
        return 'Europa Zachodnia (FRA, BEL, NED, ESP, ITA)';
      case ScoutingRegion.easternEurope:
        return 'Europa Wschodnia & Bałkany (POL, CZE, SLO, SVK)';
      case ScoutingRegion.colombiaAndSouthAmerica:
        return 'Ameryka Południowa & Andy (COL, ECU)';
      case ScoutingRegion.northAmerica:
        return 'Ameryka Północna (USA, CAN)';
      case ScoutingRegion.africa:
        return 'Afryka Wschodnia (ERI, ETH, RWA, RSA)';
      case ScoutingRegion.oceania:
        return 'Oceania (AUS, NZL)';
      case ScoutingRegion.scandinavia:
        return 'Skandynawia (DEN, NOR, SWE)';
    }
  }

  String toJson() => name;

  static ScoutingRegion fromJson(String value) {
    return ScoutingRegion.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ScoutingRegion.westernEurope,
    );
  }
}

/// Główny profil poszukiwanych talentów przez Skauta.
enum ScoutTalentFocus {
  grandTourContenders,
  sprinters,
  cobblesClassicsSpecialists,
  timeTrialists,
  anyHighPotential;

  String get displayName {
    switch (this) {
      case ScoutTalentFocus.grandTourContenders:
        return 'Kandydaci na Liderów GC (Górale)';
      case ScoutTalentFocus.sprinters:
        return 'Czyste Talenty Sprinterskie';
      case ScoutTalentFocus.cobblesClassicsSpecialists:
        return 'Mistrzowie Bruków i Wiatrów';
      case ScoutTalentFocus.timeTrialists:
        return 'Czasowcy i Maszyny Aero';
      case ScoutTalentFocus.anyHighPotential:
        return 'Wszelkie Wybitne Talenty U23';
    }
  }

  String toJson() => name;

  static ScoutTalentFocus fromJson(String value) {
    return ScoutTalentFocus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ScoutTalentFocus.anyHighPotential,
    );
  }
}

/// Bazowa klasa reprezentująca członka sztabu zespołu kolarskiego (`StaffMember`).
abstract class StaffMember {
  final String id;
  final String firstName;
  final String lastName;
  final String nationalityIso;
  final StaffRole role;
  final int age;

  /// Doświadczenie i ogólny poziom wiedzy specjalistycznej (1-100)
  final int experienceLevel;

  /// Miesięczne wynagrodzenie brutto w Euro (€)
  final int monthlySalaryEur;

  /// Rok wygaśnięcia kontraktu ze stajnią
  final int contractEndYear;

  /// Morale sztabowca (0.0 - 100.0)
  final double morale;

  /// Renoma w peletonie WorldTour (1-100)
  final int reputation;

  /// Unikalne cechy osobowościowe lub trenerskie (Special Traits)
  final List<String> specialTraits;

  const StaffMember({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.nationalityIso,
    required this.role,
    required this.age,
    required this.experienceLevel,
    required this.monthlySalaryEur,
    required this.contractEndYear,
    this.morale = 85.0,
    required this.reputation,
    this.specialTraits = const [],
  });

  String get fullName => '$firstName $lastName';

  /// Równoważna wartość poziomu kompetencji w skali 1-100 do synchronizacji z `TeamStaff`
  int get equivalentStaffLevel => experienceLevel;

  /// Jednorazowa premia za podpisanie kontraktu na wolnym rynku (€)
  int get signingBonusEur => (monthlySalaryEur * 2.5).round();

  Map<String, dynamic> toJson();

  /// Polimorficzna deserializacja członka sztabu z JSON
  factory StaffMember.fromJson(Map<String, dynamic> json) {
    final role = StaffRole.fromJson(json['role'] as String);
    switch (role) {
      case StaffRole.sportsDirector:
        return SportsDirector.fromJson(json);
      case StaffRole.performanceCoach:
        return PerformanceCoach.fromJson(json);
      case StaffRole.teamDoctor:
        return TeamDoctor.fromJson(json);
      case StaffRole.headMechanic:
        return HeadMechanic.fromJson(json);
      case StaffRole.scout:
        return Scout.fromJson(json);
    }
  }
}

// =============================================================================
// 1. SPORTS DIRECTOR (Dyrektor Sportowy w wozie technicznym)
// =============================================================================

/// Dyrektor Sportowy kierujący taktyką wyścigu z wozu technicznego nr 1 / nr 2.
///
/// Wpływa bezpośrednio na:
/// - Szybkość dojazdu wozu serwisowego w kolumnie i czas wymiany roweru po defekcie,
/// - Precyzję i trafność decyzji taktycznych AI (timing rantów, formowanie pociągu),
/// - Bonus do morale i motywacji kolarzy po porannej odprawie przedstartowej w autobusie.
class SportsDirector extends StaffMember {
  /// Umiejętność manewrowania wozem w kolumnie technicznej UCI (1-100).
  /// Im wyższa, tym wóz szybciej przeciska się między samochodami i sędziami do uciekającego kolarza.
  final int convoyCarDrivingSkill;

  /// Zdolności taktyczne i zmysł wyścigowy AI (1-100).
  /// Poprawia timing ataków na podjazdach oraz zjazdów kolarzy po bidony do wozu.
  final int tacticalAiInsight;

  /// Charyzma i umiejętności oratorskie podczas porannej odprawy w autobusie (1-100).
  /// Zapewnia zastrzyk morale i koncentracji przed kluczowymi etapami.
  final int preRaceBriefingCharisma;

  /// Przejrzystość i autorytet w komunikacji radiowej (Radio Tour) (1-100).
  final int radioCommunicationClarity;

  /// Filozofia taktyczna kierowania drużyną
  final DirectorTacticalPhilosophy tacticalPhilosophy;

  const SportsDirector({
    required super.id,
    required super.firstName,
    required super.lastName,
    required super.nationalityIso,
    required super.age,
    required super.experienceLevel,
    required super.monthlySalaryEur,
    required super.contractEndYear,
    super.morale = 85.0,
    required super.reputation,
    super.specialTraits = const [],
    required this.convoyCarDrivingSkill,
    required this.tacticalAiInsight,
    required this.preRaceBriefingCharisma,
    required this.radioCommunicationClarity,
    this.tacticalPhilosophy = DirectorTacticalPhilosophy.gcCalculator,
  }) : super(role: StaffRole.sportsDirector);

  /// Oblicza łączny czas wymiany roweru lub koła po defekcie [sekundy].
  ///
  /// Elitarny dyrektor sportowy i zgrany kierowca wozu wymieniają rower w 8.5–10 sekund.
  /// Mniej doświadczony sztab w gęstej kolumnie może tracić 18–25 sekund.
  double calculateBikeSwapTimeSeconds({
    bool isRiderInMainPeloton = true,
    bool isWetRainConditions = false,
  }) {
    // Bazowy czas pit-stopu
    double baseSeconds = 14.0;

    // Doświadczenie i umiejętności jazdy w kolumnie obniżają czas do -5.5s
    final drivingBonus = (convoyCarDrivingSkill / 100.0) * 5.5;
    baseSeconds -= drivingBonus;

    // Jeśli kolarz jest w małej ucieczce z wozem za plecami, wymiana jest błyskawiczna
    if (!isRiderInMainPeloton) {
      baseSeconds -= 1.8;
    }

    // Warunki deszczowe utrudniają manewrowanie
    if (isWetRainConditions) {
      baseSeconds += 2.2;
    }

    return double.parse(baseSeconds.clamp(8.0, 24.0).toStringAsFixed(1));
  }

  /// Wylicza zastrzyk morale dla kolarzy po porannej odprawie przedstartowej (Pre-race briefing).
  ///
  /// Zwraca wartość punktową morale (od +1.0 do +6.5 pkt).
  double calculateBriefingMoraleBonus({bool isQueenStage = false}) {
    final baseBonus = (preRaceBriefingCharisma / 100.0) * 4.5;
    final multiplier = isQueenStage ? 1.4 : 1.0;
    return double.parse((baseBonus * multiplier).clamp(1.0, 6.5).toStringAsFixed(1));
  }

  /// Wylicza wskaźnik efektywności taktycznej AI w wyścigu (0.0 - 1.0)
  double get tacticalEfficiencyScore {
    return ((tacticalAiInsight * 0.6 + radioCommunicationClarity * 0.4) / 100.0)
        .clamp(0.40, 0.99);
  }

  SportsDirector copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? nationalityIso,
    int? age,
    int? experienceLevel,
    int? monthlySalaryEur,
    int? contractEndYear,
    double? morale,
    int? reputation,
    List<String>? specialTraits,
    int? convoyCarDrivingSkill,
    int? tacticalAiInsight,
    int? preRaceBriefingCharisma,
    int? radioCommunicationClarity,
    DirectorTacticalPhilosophy? tacticalPhilosophy,
  }) {
    return SportsDirector(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      nationalityIso: nationalityIso ?? this.nationalityIso,
      age: age ?? this.age,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      monthlySalaryEur: monthlySalaryEur ?? this.monthlySalaryEur,
      contractEndYear: contractEndYear ?? this.contractEndYear,
      morale: morale ?? this.morale,
      reputation: reputation ?? this.reputation,
      specialTraits: specialTraits ?? this.specialTraits,
      convoyCarDrivingSkill: convoyCarDrivingSkill ?? this.convoyCarDrivingSkill,
      tacticalAiInsight: tacticalAiInsight ?? this.tacticalAiInsight,
      preRaceBriefingCharisma:
          preRaceBriefingCharisma ?? this.preRaceBriefingCharisma,
      radioCommunicationClarity:
          radioCommunicationClarity ?? this.radioCommunicationClarity,
      tacticalPhilosophy: tacticalPhilosophy ?? this.tacticalPhilosophy,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'nationalityIso': nationalityIso,
        'role': role.toJson(),
        'age': age,
        'experienceLevel': experienceLevel,
        'monthlySalaryEur': monthlySalaryEur,
        'contractEndYear': contractEndYear,
        'morale': morale,
        'reputation': reputation,
        'specialTraits': specialTraits,
        'convoyCarDrivingSkill': convoyCarDrivingSkill,
        'tacticalAiInsight': tacticalAiInsight,
        'preRaceBriefingCharisma': preRaceBriefingCharisma,
        'radioCommunicationClarity': radioCommunicationClarity,
        'tacticalPhilosophy': tacticalPhilosophy.toJson(),
      };

  factory SportsDirector.fromJson(Map<String, dynamic> json) {
    return SportsDirector(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      nationalityIso: json['nationalityIso'] as String,
      age: (json['age'] as num).toInt(),
      experienceLevel: (json['experienceLevel'] as num).toInt(),
      monthlySalaryEur: (json['monthlySalaryEur'] as num).toInt(),
      contractEndYear: (json['contractEndYear'] as num).toInt(),
      morale: (json['morale'] as num?)?.toDouble() ?? 85.0,
      reputation: (json['reputation'] as num).toInt(),
      specialTraits: (json['specialTraits'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      convoyCarDrivingSkill: (json['convoyCarDrivingSkill'] as num).toInt(),
      tacticalAiInsight: (json['tacticalAiInsight'] as num).toInt(),
      preRaceBriefingCharisma:
          (json['preRaceBriefingCharisma'] as num).toInt(),
      radioCommunicationClarity:
          (json['radioCommunicationClarity'] as num).toInt(),
      tacticalPhilosophy: json['tacticalPhilosophy'] != null
          ? DirectorTacticalPhilosophy.fromJson(json['tacticalPhilosophy'] as String)
          : DirectorTacticalPhilosophy.gcCalculator,
    );
  }
}

// =============================================================================
// 2. PERFORMANCE COACH (Trener Przygotowania Fizycznego i Siłowego)
// =============================================================================

/// Trener przygotowania motorycznego, siłowego i periodyzacji obciążeń.
///
/// Odpowiada za:
/// - Efektywność przyrostu mocy progowej FTP i W/kg podczas obozów wysokogórskich,
/// - Progres mocy sprinterskiej (W15s i moc eksplozywna),
/// - Periodyzację ćwiczeń siłowych na siłowni w okresie zimowym (siła maksymalna, core).
class PerformanceCoach extends StaffMember {
  /// Skuteczność stymulacji wzrostu progu tlenowego FTP kolarzy (1-100)
  final int ftpDevelopmentEfficiency;

  /// Specjalizacja w treningu mocy nerwowo-mięśniowej i sprintu (W5s - W30s) (1-100)
  final int sprintAndNeuromuscularFocus;

  /// Periodyzacja treningu siłowego w okresie zimowym (Gym & Core Stability) (1-100)
  final int winterGymPeriodizationSkill;

  /// Umiejętność zapobiegania przetrenowaniu (kontrola ATL i przemęczenia OUN) (1-100)
  final int overtrainingPrevention;

  /// Główny profil trenerski
  final CoachSpecialization specialization;

  const PerformanceCoach({
    required super.id,
    required super.firstName,
    required super.lastName,
    required super.nationalityIso,
    required super.age,
    required super.experienceLevel,
    required super.monthlySalaryEur,
    required super.contractEndYear,
    super.morale = 85.0,
    required super.reputation,
    super.specialTraits = const [],
    required this.ftpDevelopmentEfficiency,
    required this.sprintAndNeuromuscularFocus,
    required this.winterGymPeriodizationSkill,
    required this.overtrainingPrevention,
    this.specialization = CoachSpecialization.allRoundDevelopment,
  }) : super(role: StaffRole.performanceCoach);

  /// Mnożnik przyrostu FTP podczas obozu treningowego lub bloku bazy (np. 1.00 - 1.35x)
  double get ftpProgressionMultiplier {
    return 1.0 + (ftpDevelopmentEfficiency / 100.0) * 0.35;
  }

  /// Bonus do maksymalnej mocy sprinterskiej 15s w watach [W] po treningu motorycznym
  int calculateSprintBonusWatts(int currentWatts15s) {
    final factor = (sprintAndNeuromuscularFocus / 100.0) * 0.04;
    return (currentWatts15s * factor).round().clamp(10, 55);
  }

  /// Skuteczność zachowania siły mięśniowej po zimowym bloku na siłowni (0.0 - 1.0)
  double get winterStrengthRetentionFactor {
    return 0.70 + (winterGymPeriodizationSkill / 100.0) * 0.28;
  }

  PerformanceCoach copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? nationalityIso,
    int? age,
    int? experienceLevel,
    int? monthlySalaryEur,
    int? contractEndYear,
    double? morale,
    int? reputation,
    List<String>? specialTraits,
    int? ftpDevelopmentEfficiency,
    int? sprintAndNeuromuscularFocus,
    int? winterGymPeriodizationSkill,
    int? overtrainingPrevention,
    CoachSpecialization? specialization,
  }) {
    return PerformanceCoach(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      nationalityIso: nationalityIso ?? this.nationalityIso,
      age: age ?? this.age,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      monthlySalaryEur: monthlySalaryEur ?? this.monthlySalaryEur,
      contractEndYear: contractEndYear ?? this.contractEndYear,
      morale: morale ?? this.morale,
      reputation: reputation ?? this.reputation,
      specialTraits: specialTraits ?? this.specialTraits,
      ftpDevelopmentEfficiency:
          ftpDevelopmentEfficiency ?? this.ftpDevelopmentEfficiency,
      sprintAndNeuromuscularFocus:
          sprintAndNeuromuscularFocus ?? this.sprintAndNeuromuscularFocus,
      winterGymPeriodizationSkill:
          winterGymPeriodizationSkill ?? this.winterGymPeriodizationSkill,
      overtrainingPrevention:
          overtrainingPrevention ?? this.overtrainingPrevention,
      specialization: specialization ?? this.specialization,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'nationalityIso': nationalityIso,
        'role': role.toJson(),
        'age': age,
        'experienceLevel': experienceLevel,
        'monthlySalaryEur': monthlySalaryEur,
        'contractEndYear': contractEndYear,
        'morale': morale,
        'reputation': reputation,
        'specialTraits': specialTraits,
        'ftpDevelopmentEfficiency': ftpDevelopmentEfficiency,
        'sprintAndNeuromuscularFocus': sprintAndNeuromuscularFocus,
        'winterGymPeriodizationSkill': winterGymPeriodizationSkill,
        'overtrainingPrevention': overtrainingPrevention,
        'specialization': specialization.toJson(),
      };

  factory PerformanceCoach.fromJson(Map<String, dynamic> json) {
    return PerformanceCoach(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      nationalityIso: json['nationalityIso'] as String,
      age: (json['age'] as num).toInt(),
      experienceLevel: (json['experienceLevel'] as num).toInt(),
      monthlySalaryEur: (json['monthlySalaryEur'] as num).toInt(),
      contractEndYear: (json['contractEndYear'] as num).toInt(),
      morale: (json['morale'] as num?)?.toDouble() ?? 85.0,
      reputation: (json['reputation'] as num).toInt(),
      specialTraits: (json['specialTraits'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      ftpDevelopmentEfficiency:
          (json['ftpDevelopmentEfficiency'] as num).toInt(),
      sprintAndNeuromuscularFocus:
          (json['sprintAndNeuromuscularFocus'] as num).toInt(),
      winterGymPeriodizationSkill:
          (json['winterGymPeriodizationSkill'] as num).toInt(),
      overtrainingPrevention:
          (json['overtrainingPrevention'] as num).toInt(),
      specialization: json['specialization'] != null
          ? CoachSpecialization.fromJson(json['specialization'] as String)
          : CoachSpecialization.allRoundDevelopment,
    );
  }
}

// =============================================================================
// 3. TEAM DOCTOR (Lekarz Klubowy & Medycyna Sportowa)
// =============================================================================

/// Lekarz klubowy odpowiedzialny za zdrowie, badania krwi i rehabilitację kolarzy.
///
/// Odpowiada za:
/// - Precyzyjną diagnostykę hematologiczną (Hct, ferrytyna, kinaza kreatynowa),
/// - Reżim sanitarny chroniący przed infekcjami dróg oddechowych i żołądkowymi,
/// - Błyskawiczny zrost kości i przyspieszony powrót po złamaniach obojczyka/żeber.
class TeamDoctor extends StaffMember {
  /// Umiejętność interpretacji biomarkerów krwi i wczesnego wykrywania anemii (1-100)
  final int bloodDiagnosticsSkill;

  /// Prewencja infekcji wirusowych i bakteryjnych w hotelach podczas Grand Tourów (1-100)
  final int infectionPreventionAndHygiene;

  /// Efektywność rehabilitacji ortopedycznej po złamaniach (zrost obojczyka, nadgarstka) (1-100)
  final int fractureAndOrthopedicRehabSpeed;

  /// Doświadczenie w wilgotnym leczeniu szlifów asfaltowych (Road Rash Care) (1-100)
  final int woundHealingCare;

  /// Specjalizacja medyczna lekarza
  final DoctorSpecialization medicalSpecialization;

  const TeamDoctor({
    required super.id,
    required super.firstName,
    required super.lastName,
    required super.nationalityIso,
    required super.age,
    required super.experienceLevel,
    required super.monthlySalaryEur,
    required super.contractEndYear,
    super.morale = 85.0,
    required super.reputation,
    super.specialTraits = const [],
    required this.bloodDiagnosticsSkill,
    required this.infectionPreventionAndHygiene,
    required this.fractureAndOrthopedicRehabSpeed,
    required this.woundHealingCare,
    this.medicalSpecialization = DoctorSpecialization.sportsCardiologyAndHematology,
  }) : super(role: StaffRole.teamDoctor);

  /// Skraca liczbę dni pauzy po ciężkim złamaniu kości (np. złamanie obojczyka, żeber)
  int calculateFractureDaysReduction(int standardInjuryDays) {
    final factor = (fractureAndOrthopedicRehabSpeed / 100.0) * 0.35; // do 35% szybciej
    final daysOff = (standardInjuryDays * factor).round();
    return daysOff.clamp(1, 14);
  }

  /// Procentowa redukcja ryzyka zachorowania na infekcję bakteryjną lub wirusa (0.0% - 65.0%)
  double get infectionRiskReductionPercent {
    return (infectionPreventionAndHygiene / 100.0) * 65.0;
  }

  /// Zdolność wykrycia krytycznego niedoboru ferrytyny zanim kolarz wpadnie w anemię wysiłkową
  bool get canDetectEarlyIronDeficiency => bloodDiagnosticsSkill >= 65;

  TeamDoctor copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? nationalityIso,
    int? age,
    int? experienceLevel,
    int? monthlySalaryEur,
    int? contractEndYear,
    double? morale,
    int? reputation,
    List<String>? specialTraits,
    int? bloodDiagnosticsSkill,
    int? infectionPreventionAndHygiene,
    int? fractureAndOrthopedicRehabSpeed,
    int? woundHealingCare,
    DoctorSpecialization? medicalSpecialization,
  }) {
    return TeamDoctor(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      nationalityIso: nationalityIso ?? this.nationalityIso,
      age: age ?? this.age,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      monthlySalaryEur: monthlySalaryEur ?? this.monthlySalaryEur,
      contractEndYear: contractEndYear ?? this.contractEndYear,
      morale: morale ?? this.morale,
      reputation: reputation ?? this.reputation,
      specialTraits: specialTraits ?? this.specialTraits,
      bloodDiagnosticsSkill:
          bloodDiagnosticsSkill ?? this.bloodDiagnosticsSkill,
      infectionPreventionAndHygiene:
          infectionPreventionAndHygiene ?? this.infectionPreventionAndHygiene,
      fractureAndOrthopedicRehabSpeed:
          fractureAndOrthopedicRehabSpeed ?? this.fractureAndOrthopedicRehabSpeed,
      woundHealingCare: woundHealingCare ?? this.woundHealingCare,
      medicalSpecialization:
          medicalSpecialization ?? this.medicalSpecialization,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'nationalityIso': nationalityIso,
        'role': role.toJson(),
        'age': age,
        'experienceLevel': experienceLevel,
        'monthlySalaryEur': monthlySalaryEur,
        'contractEndYear': contractEndYear,
        'morale': morale,
        'reputation': reputation,
        'specialTraits': specialTraits,
        'bloodDiagnosticsSkill': bloodDiagnosticsSkill,
        'infectionPreventionAndHygiene': infectionPreventionAndHygiene,
        'fractureAndOrthopedicRehabSpeed': fractureAndOrthopedicRehabSpeed,
        'woundHealingCare': woundHealingCare,
        'medicalSpecialization': medicalSpecialization.toJson(),
      };

  factory TeamDoctor.fromJson(Map<String, dynamic> json) {
    return TeamDoctor(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      nationalityIso: json['nationalityIso'] as String,
      age: (json['age'] as num).toInt(),
      experienceLevel: (json['experienceLevel'] as num).toInt(),
      monthlySalaryEur: (json['monthlySalaryEur'] as num).toInt(),
      contractEndYear: (json['contractEndYear'] as num).toInt(),
      morale: (json['morale'] as num?)?.toDouble() ?? 85.0,
      reputation: (json['reputation'] as num).toInt(),
      specialTraits: (json['specialTraits'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      bloodDiagnosticsSkill:
          (json['bloodDiagnosticsSkill'] as num).toInt(),
      infectionPreventionAndHygiene:
          (json['infectionPreventionAndHygiene'] as num).toInt(),
      fractureAndOrthopedicRehabSpeed:
          (json['fractureAndOrthopedicRehabSpeed'] as num).toInt(),
      woundHealingCare: (json['woundHealingCare'] as num).toInt(),
      medicalSpecialization: json['medicalSpecialization'] != null
          ? DoctorSpecialization.fromJson(json['medicalSpecialization'] as String)
          : DoctorSpecialization.sportsCardiologyAndHematology,
    );
  }
}

// =============================================================================
// 4. HEAD MECHANIC (Główny Mechanik Drużyny)
// =============================================================================

/// Główny mechanik odpowiadający za park maszynowy i bezawaryjność rowerów.
///
/// Odpowiada za:
/// - Zminimalizowanie ryzyka usterek napędu (spadający łańcuch, chain suck, rozregulowanie di2),
/// - Perfekcyjny dobór ciśnienia i montaż opon tubeless pod trudny bruk (Paris-Roubaix),
/// - Szybki nocny serwis rowerów i wygotowywanie łańcuchów w gorącym wosku (Hot Melt Wax).
class HeadMechanic extends StaffMember {
  /// Precyzja regulacji napędu obniżająca ryzyko defektu mechanicznego (1-100)
  final int drivetrainReliabilitySkill;

  /// Doświadczenie w systemach bezdętkowych tubeless i doborze ciśnień pod bruk (1-100)
  final int tubelessAndTireMastery;

  /// Czas kompletnego nocnego serwisu jednego roweru w minutach (np. 35 - 75 min)
  final int serviceTimeMinutesPerBike;

  /// Mistrzostwo w technologii woskowania łańcuchów (Hot Melt Wax) (1-100)
  final int chainWaxingExpertise;

  /// Doświadczenie w centrowaniu kół i serwisie łożysk ceramicznych (1-100)
  final int wheelTruingPrecision;

  const HeadMechanic({
    required super.id,
    required super.firstName,
    required super.lastName,
    required super.nationalityIso,
    required super.age,
    required super.experienceLevel,
    required super.monthlySalaryEur,
    required super.contractEndYear,
    super.morale = 85.0,
    required super.reputation,
    super.specialTraits = const [],
    required this.drivetrainReliabilitySkill,
    required this.tubelessAndTireMastery,
    this.serviceTimeMinutesPerBike = 45,
    required this.chainWaxingExpertise,
    required this.wheelTruingPrecision,
  }) : super(role: StaffRole.headMechanic);

  /// Mnożnik prawdopodobieństwa defektu napędu (np. 0.35x u mistrza mechaniki do 1.20x)
  double get mechanicalFailureRateMultiplier {
    return 1.25 - (drivetrainReliabilitySkill / 100.0) * 0.90;
  }

  /// Oszczędność watów [W] dzięki profesjonalnej kąpieli woskowicy na gorąco (Hot Melt Wax)
  double get chainWaxWattageSavings {
    return 3.0 + (chainWaxingExpertise / 100.0) * 2.5; // 3.0 - 5.5 W oszczędności
  }

  /// Redukcja ryzyka przebicia opony na bruku dzięki uszczelnieniu tubeless (0% - 60%)
  double get punctureRiskReductionPercent {
    return (tubelessAndTireMastery / 100.0) * 60.0;
  }

  HeadMechanic copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? nationalityIso,
    int? age,
    int? experienceLevel,
    int? monthlySalaryEur,
    int? contractEndYear,
    double? morale,
    int? reputation,
    List<String>? specialTraits,
    int? drivetrainReliabilitySkill,
    int? tubelessAndTireMastery,
    int? serviceTimeMinutesPerBike,
    int? chainWaxingExpertise,
    int? wheelTruingPrecision,
  }) {
    return HeadMechanic(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      nationalityIso: nationalityIso ?? this.nationalityIso,
      age: age ?? this.age,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      monthlySalaryEur: monthlySalaryEur ?? this.monthlySalaryEur,
      contractEndYear: contractEndYear ?? this.contractEndYear,
      morale: morale ?? this.morale,
      reputation: reputation ?? this.reputation,
      specialTraits: specialTraits ?? this.specialTraits,
      drivetrainReliabilitySkill:
          drivetrainReliabilitySkill ?? this.drivetrainReliabilitySkill,
      tubelessAndTireMastery:
          tubelessAndTireMastery ?? this.tubelessAndTireMastery,
      serviceTimeMinutesPerBike:
          serviceTimeMinutesPerBike ?? this.serviceTimeMinutesPerBike,
      chainWaxingExpertise: chainWaxingExpertise ?? this.chainWaxingExpertise,
      wheelTruingPrecision: wheelTruingPrecision ?? this.wheelTruingPrecision,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'nationalityIso': nationalityIso,
        'role': role.toJson(),
        'age': age,
        'experienceLevel': experienceLevel,
        'monthlySalaryEur': monthlySalaryEur,
        'contractEndYear': contractEndYear,
        'morale': morale,
        'reputation': reputation,
        'specialTraits': specialTraits,
        'drivetrainReliabilitySkill': drivetrainReliabilitySkill,
        'tubelessAndTireMastery': tubelessAndTireMastery,
        'serviceTimeMinutesPerBike': serviceTimeMinutesPerBike,
        'chainWaxingExpertise': chainWaxingExpertise,
        'wheelTruingPrecision': wheelTruingPrecision,
      };

  factory HeadMechanic.fromJson(Map<String, dynamic> json) {
    return HeadMechanic(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      nationalityIso: json['nationalityIso'] as String,
      age: (json['age'] as num).toInt(),
      experienceLevel: (json['experienceLevel'] as num).toInt(),
      monthlySalaryEur: (json['monthlySalaryEur'] as num).toInt(),
      contractEndYear: (json['contractEndYear'] as num).toInt(),
      morale: (json['morale'] as num?)?.toDouble() ?? 85.0,
      reputation: (json['reputation'] as num).toInt(),
      specialTraits: (json['specialTraits'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      drivetrainReliabilitySkill:
          (json['drivetrainReliabilitySkill'] as num).toInt(),
      tubelessAndTireMastery:
          (json['tubelessAndTireMastery'] as num).toInt(),
      serviceTimeMinutesPerBike:
          (json['serviceTimeMinutesPerBike'] as num?)?.toInt() ?? 45,
      chainWaxingExpertise:
          (json['chainWaxingExpertise'] as num).toInt(),
      wheelTruingPrecision:
          (json['wheelTruingPrecision'] as num).toInt(),
    );
  }
}

// =============================================================================
// 5. SCOUT (Skaut Talentów U23)
// =============================================================================

/// Skaut odpowiedzialny za wyszukiwanie i wstępną ocenę talentów młodzieżowych (U19/U23).
///
/// Odpowiada za:
/// - Odkrywanie perełek kolarskich w przydzielonym regionie świata (np. Kolumbia, Bałkany),
/// - Dokładność oceny potencjału (Potencjał 1-99) oraz profilu mocy młodzika,
/// - Tworzenie rzetelnych raportów skautingowych eliminujących ryzyko transferowych wpadek.
class Scout extends StaffMember {
  /// Skuteczność odkrywania kolarzy o wysokim potencjale (>85) (1-100)
  final int talentDiscoveryRating;

  /// Precyzja estymacji prawdziwego potencjału i FTP (1-100).
  /// Im wyższa, tym węższy margines błędu w raporcie skautingowym.
  final int evaluationPrecision;

  /// Przydzielony region operacyjny skauta
  final ScoutingRegion assignedRegion;

  /// Rozpiętość siatki kontaktów z klubami młodzieżowymi w regionie (1-100)
  final int networkReach;

  /// Preferowany profil poszukiwanego adepta
  final ScoutTalentFocus specialtyFocus;

  const Scout({
    required super.id,
    required super.firstName,
    required super.lastName,
    required super.nationalityIso,
    required super.age,
    required super.experienceLevel,
    required super.monthlySalaryEur,
    required super.contractEndYear,
    super.morale = 85.0,
    required super.reputation,
    super.specialTraits = const [],
    required this.talentDiscoveryRating,
    required this.evaluationPrecision,
    required this.assignedRegion,
    required this.networkReach,
    this.specialtyFocus = ScoutTalentFocus.anyHighPotential,
  }) : super(role: StaffRole.scout);

  /// Margines błędu estymacji potencjału (np. +/- 2 punkty u elitarnego skauta, +/- 7 u nowicjusza)
  int get potentialEstimationMargin {
    return (7 - (evaluationPrecision / 100.0 * 5.0)).round().clamp(1, 8);
  }

  /// Czy dany kraj kolarza znajduje się w strefie operacyjnej tego skauta
  bool isCountryInRegion(String countryIso) {
    final iso = countryIso.toUpperCase();
    switch (assignedRegion) {
      case ScoutingRegion.westernEurope:
        return ['FRA', 'BEL', 'NED', 'ESP', 'ITA', 'GER', 'SUI', 'GBR'].contains(iso);
      case ScoutingRegion.easternEurope:
        return ['POL', 'CZE', 'SLO', 'SVK', 'HUN', 'UKR', 'ROU'].contains(iso);
      case ScoutingRegion.colombiaAndSouthAmerica:
        return ['COL', 'ECU', 'ARG', 'CHI', 'BRA', 'VEN'].contains(iso);
      case ScoutingRegion.northAmerica:
        return ['USA', 'CAN', 'MEX'].contains(iso);
      case ScoutingRegion.africa:
        return ['ERI', 'ETH', 'RWA', 'RSA', 'MAR', 'ALG'].contains(iso);
      case ScoutingRegion.oceania:
        return ['AUS', 'NZL'].contains(iso);
      case ScoutingRegion.scandinavia:
        return ['DEN', 'NOR', 'SWE', 'FIN'].contains(iso);
    }
  }

  Scout copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? nationalityIso,
    int? age,
    int? experienceLevel,
    int? monthlySalaryEur,
    int? contractEndYear,
    double? morale,
    int? reputation,
    List<String>? specialTraits,
    int? talentDiscoveryRating,
    int? evaluationPrecision,
    ScoutingRegion? assignedRegion,
    int? networkReach,
    ScoutTalentFocus? specialtyFocus,
  }) {
    return Scout(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      nationalityIso: nationalityIso ?? this.nationalityIso,
      age: age ?? this.age,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      monthlySalaryEur: monthlySalaryEur ?? this.monthlySalaryEur,
      contractEndYear: contractEndYear ?? this.contractEndYear,
      morale: morale ?? this.morale,
      reputation: reputation ?? this.reputation,
      specialTraits: specialTraits ?? this.specialTraits,
      talentDiscoveryRating:
          talentDiscoveryRating ?? this.talentDiscoveryRating,
      evaluationPrecision: evaluationPrecision ?? this.evaluationPrecision,
      assignedRegion: assignedRegion ?? this.assignedRegion,
      networkReach: networkReach ?? this.networkReach,
      specialtyFocus: specialtyFocus ?? this.specialtyFocus,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'nationalityIso': nationalityIso,
        'role': role.toJson(),
        'age': age,
        'experienceLevel': experienceLevel,
        'monthlySalaryEur': monthlySalaryEur,
        'contractEndYear': contractEndYear,
        'morale': morale,
        'reputation': reputation,
        'specialTraits': specialTraits,
        'talentDiscoveryRating': talentDiscoveryRating,
        'evaluationPrecision': evaluationPrecision,
        'assignedRegion': assignedRegion.toJson(),
        'networkReach': networkReach,
        'specialtyFocus': specialtyFocus.toJson(),
      };

  factory Scout.fromJson(Map<String, dynamic> json) {
    return Scout(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      nationalityIso: json['nationalityIso'] as String,
      age: (json['age'] as num).toInt(),
      experienceLevel: (json['experienceLevel'] as num).toInt(),
      monthlySalaryEur: (json['monthlySalaryEur'] as num).toInt(),
      contractEndYear: (json['contractEndYear'] as num).toInt(),
      morale: (json['morale'] as num?)?.toDouble() ?? 85.0,
      reputation: (json['reputation'] as num).toInt(),
      specialTraits: (json['specialTraits'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      talentDiscoveryRating:
          (json['talentDiscoveryRating'] as num).toInt(),
      evaluationPrecision:
          (json['evaluationPrecision'] as num).toInt(),
      assignedRegion: json['assignedRegion'] != null
          ? ScoutingRegion.fromJson(json['assignedRegion'] as String)
          : ScoutingRegion.westernEurope,
      networkReach: (json['networkReach'] as num).toInt(),
      specialtyFocus: json['specialtyFocus'] != null
          ? ScoutTalentFocus.fromJson(json['specialtyFocus'] as String)
          : ScoutTalentFocus.anyHighPotential,
    );
  }
}

// =============================================================================
// 6. FULL TEAM STAFF ROSTER & GENERATOR
// =============================================================================

/// Pełna kadra sztabu szkoleniowo-technicznego drużyny kolarskiej.
///
/// Zarządza wszystkimi pracownikami stajni i wylicza syntetyczny obiekt `TeamStaff`
/// dla zachowania pełnej kompatybilności wstecznej z modelami `CyclingTeam`.
class FullTeamStaffRoster {
  final List<SportsDirector> sportsDirectors;
  final List<PerformanceCoach> coaches;
  final List<TeamDoctor> doctors;
  final List<HeadMechanic> mechanics;
  final List<Scout> scouts;

  const FullTeamStaffRoster({
    this.sportsDirectors = const [],
    this.coaches = const [],
    this.doctors = const [],
    this.mechanics = const [],
    this.scouts = const [],
  });

  /// Lista wszystkich członków sztabu
  List<StaffMember> get allMembers => [
        ...sportsDirectors,
        ...coaches,
        ...doctors,
        ...mechanics,
        ...scouts,
      ];

  /// Łączna suma miesięcznych wynagrodzeń całego sztabu w Euro (€)
  int get totalMonthlySalariesEur {
    int total = 0;
    for (final member in allMembers) {
      total += member.monthlySalaryEur;
    }
    return total;
  }

  /// Główny Dyrektor Sportowy zespołu (DS 1)
  SportsDirector? get leadDirector =>
      sportsDirectors.isNotEmpty ? sportsDirectors.first : null;

  /// Główny Lekarz Zespołu
  TeamDoctor? get leadDoctor => doctors.isNotEmpty ? doctors.first : null;

  /// Główny Mechanik Zespołu
  HeadMechanic? get leadMechanic => mechanics.isNotEmpty ? mechanics.first : null;

  /// Konwertuje rozbudowany skład sztabu na zagregowany model `TeamStaff`
  TeamStaff toTeamStaff() {
    int avgDs = _calculateAverageLevel(sportsDirectors.map((m) => m.experienceLevel));
    int avgCoaches = _calculateAverageLevel(coaches.map((m) => m.experienceLevel));
    int avgDocs = _calculateAverageLevel(doctors.map((m) => m.experienceLevel));
    int avgMech = _calculateAverageLevel(mechanics.map((m) => m.experienceLevel));
    int avgScouts = _calculateAverageLevel(scouts.map((m) => m.experienceLevel));

    return TeamStaff(
      trainersLevel: avgCoaches,
      sportsDirectorsLevel: avgDs,
      doctorsLevel: avgDocs,
      mechanicsLevel: avgMech,
      scoutsLevel: avgScouts,
    );
  }

  static int _calculateAverageLevel(Iterable<int> levels) {
    if (levels.isEmpty) return 65;
    final sum = levels.reduce((a, b) => a + b);
    return (sum / levels.length).round().clamp(1, 100);
  }

  FullTeamStaffRoster copyWith({
    List<SportsDirector>? sportsDirectors,
    List<PerformanceCoach>? coaches,
    List<TeamDoctor>? doctors,
    List<HeadMechanic>? mechanics,
    List<Scout>? scouts,
  }) {
    return FullTeamStaffRoster(
      sportsDirectors: sportsDirectors ?? this.sportsDirectors,
      coaches: coaches ?? this.coaches,
      doctors: doctors ?? this.doctors,
      mechanics: mechanics ?? this.mechanics,
      scouts: scouts ?? this.scouts,
    );
  }

  Map<String, dynamic> toJson() => {
        'sportsDirectors': sportsDirectors.map((e) => e.toJson()).toList(),
        'coaches': coaches.map((e) => e.toJson()).toList(),
        'doctors': doctors.map((e) => e.toJson()).toList(),
        'mechanics': mechanics.map((e) => e.toJson()).toList(),
        'scouts': scouts.map((e) => e.toJson()).toList(),
      };

  factory FullTeamStaffRoster.fromJson(Map<String, dynamic> json) {
    return FullTeamStaffRoster(
      sportsDirectors: (json['sportsDirectors'] as List<dynamic>?)
              ?.map((e) => SportsDirector.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      coaches: (json['coaches'] as List<dynamic>?)
              ?.map((e) => PerformanceCoach.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      doctors: (json['doctors'] as List<dynamic>?)
              ?.map((e) => TeamDoctor.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      mechanics: (json['mechanics'] as List<dynamic>?)
              ?.map((e) => HeadMechanic.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      scouts: (json['scouts'] as List<dynamic>?)
              ?.map((e) => Scout.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

/// Generator realistycznych członków sztabu dla różnych dywizji UCI.
class StaffProceduralGenerator {
  StaffProceduralGenerator._();

  /// Generuje kompletny, realistyczny sztab dla drużyny danej dywizji
  static FullTeamStaffRoster generateDefaultTeamStaffRoster({
    required TeamDivision division,
    required String teamCountryIso,
    int seed = 42,
  }) {
    final rng = math.Random(seed);
    final baseLevel = _getBaseStaffLevelForDivision(division);

    final dsList = [
      _generateSportsDirector(
        id: 'ds_${division.name}_1',
        targetLevel: (baseLevel + rng.nextInt(10)).clamp(40, 98),
        nationalityIso: teamCountryIso,
        rng: rng,
      ),
      _generateSportsDirector(
        id: 'ds_${division.name}_2',
        targetLevel: (baseLevel - 4 + rng.nextInt(8)).clamp(35, 95),
        nationalityIso: 'BEL',
        rng: rng,
      ),
    ];

    final coachList = [
      _generatePerformanceCoach(
        id: 'coach_${division.name}_1',
        targetLevel: (baseLevel + rng.nextInt(8)).clamp(40, 98),
        nationalityIso: teamCountryIso,
        rng: rng,
      ),
      _generatePerformanceCoach(
        id: 'coach_${division.name}_2',
        targetLevel: (baseLevel - 2 + rng.nextInt(8)).clamp(40, 95),
        nationalityIso: 'GBR',
        rng: rng,
      ),
    ];

    final doctorList = [
      _generateTeamDoctor(
        id: 'doc_${division.name}_1',
        targetLevel: (baseLevel + rng.nextInt(10)).clamp(40, 99),
        nationalityIso: teamCountryIso,
        rng: rng,
      ),
    ];

    final mechanicList = [
      _generateHeadMechanic(
        id: 'mech_${division.name}_1',
        targetLevel: (baseLevel + rng.nextInt(10)).clamp(40, 99),
        nationalityIso: 'ITA',
        rng: rng,
      ),
      _generateHeadMechanic(
        id: 'mech_${division.name}_2',
        targetLevel: (baseLevel - 3 + rng.nextInt(8)).clamp(35, 94),
        nationalityIso: teamCountryIso,
        rng: rng,
      ),
    ];

    final scoutList = [
      _generateScout(
        id: 'scout_${division.name}_1',
        targetLevel: (baseLevel + rng.nextInt(8)).clamp(40, 98),
        region: ScoutingRegion.westernEurope,
        nationalityIso: 'FRA',
        rng: rng,
      ),
      _generateScout(
        id: 'scout_${division.name}_2',
        targetLevel: (baseLevel - 2 + rng.nextInt(8)).clamp(40, 95),
        region: ScoutingRegion.colombiaAndSouthAmerica,
        nationalityIso: 'COL',
        rng: rng,
      ),
    ];

    return FullTeamStaffRoster(
      sportsDirectors: dsList,
      coaches: coachList,
      doctors: doctorList,
      mechanics: mechanicList,
      scouts: scoutList,
    );
  }

  static int _getBaseStaffLevelForDivision(TeamDivision division) {
    switch (division) {
      case TeamDivision.worldTour:
        return 82;
      case TeamDivision.proTeam:
        return 72;
      case TeamDivision.continental:
        return 58;
    }
  }

  static SportsDirector _generateSportsDirector({
    required String id,
    required int targetLevel,
    required String nationalityIso,
    required math.Random rng,
  }) {
    final names = _getStaffName(nationalityIso, rng);
    return SportsDirector(
      id: id,
      firstName: names.$1,
      lastName: names.$2,
      nationalityIso: nationalityIso,
      age: 44 + rng.nextInt(22),
      experienceLevel: targetLevel,
      monthlySalaryEur: (targetLevel * 140 + 2500),
      contractEndYear: 2027 + rng.nextInt(2),
      reputation: targetLevel,
      convoyCarDrivingSkill: (targetLevel + rng.nextInt(7) - 3).clamp(40, 99),
      tacticalAiInsight: (targetLevel + rng.nextInt(7) - 3).clamp(40, 99),
      preRaceBriefingCharisma: (targetLevel + rng.nextInt(7) - 3).clamp(40, 99),
      radioCommunicationClarity: (targetLevel + rng.nextInt(7) - 3).clamp(40, 99),
      tacticalPhilosophy: DirectorTacticalPhilosophy
          .values[rng.nextInt(DirectorTacticalPhilosophy.values.length)],
      specialTraits: const ['Opanowanie w kryzysie', 'Strategia rantowa'],
    );
  }

  static PerformanceCoach _generatePerformanceCoach({
    required String id,
    required int targetLevel,
    required String nationalityIso,
    required math.Random rng,
  }) {
    final names = _getStaffName(nationalityIso, rng);
    return PerformanceCoach(
      id: id,
      firstName: names.$1,
      lastName: names.$2,
      nationalityIso: nationalityIso,
      age: 36 + rng.nextInt(20),
      experienceLevel: targetLevel,
      monthlySalaryEur: (targetLevel * 120 + 2200),
      contractEndYear: 2027 + rng.nextInt(2),
      reputation: targetLevel,
      ftpDevelopmentEfficiency: (targetLevel + rng.nextInt(7) - 3).clamp(40, 99),
      sprintAndNeuromuscularFocus: (targetLevel + rng.nextInt(7) - 3).clamp(40, 99),
      winterGymPeriodizationSkill: (targetLevel + rng.nextInt(7) - 3).clamp(40, 99),
      overtrainingPrevention: (targetLevel + rng.nextInt(7) - 3).clamp(40, 99),
      specialization: CoachSpecialization
          .values[rng.nextInt(CoachSpecialization.values.length)],
      specialTraits: const ['Optymalizacja VO2max', 'Periodyzacja falowa'],
    );
  }

  static TeamDoctor _generateTeamDoctor({
    required String id,
    required int targetLevel,
    required String nationalityIso,
    required math.Random rng,
  }) {
    final names = _getStaffName(nationalityIso, rng);
    return TeamDoctor(
      id: id,
      firstName: names.$1,
      lastName: names.$2,
      nationalityIso: nationalityIso,
      age: 42 + rng.nextInt(24),
      experienceLevel: targetLevel,
      monthlySalaryEur: (targetLevel * 160 + 3500),
      contractEndYear: 2028 + rng.nextInt(2),
      reputation: targetLevel,
      bloodDiagnosticsSkill: (targetLevel + rng.nextInt(7) - 3).clamp(40, 99),
      infectionPreventionAndHygiene: (targetLevel + rng.nextInt(7) - 3).clamp(40, 99),
      fractureAndOrthopedicRehabSpeed: (targetLevel + rng.nextInt(7) - 3).clamp(40, 99),
      woundHealingCare: (targetLevel + rng.nextInt(7) - 3).clamp(40, 99),
      medicalSpecialization: DoctorSpecialization
          .values[rng.nextInt(DoctorSpecialization.values.length)],
      specialTraits: const ['Traumatologia obojczyka', 'Prewencja infekcji'],
    );
  }

  static HeadMechanic _generateHeadMechanic({
    required String id,
    required int targetLevel,
    required String nationalityIso,
    required math.Random rng,
  }) {
    final names = _getStaffName(nationalityIso, rng);
    return HeadMechanic(
      id: id,
      firstName: names.$1,
      lastName: names.$2,
      nationalityIso: nationalityIso,
      age: 38 + rng.nextInt(25),
      experienceLevel: targetLevel,
      monthlySalaryEur: (targetLevel * 85 + 1800),
      contractEndYear: 2027 + rng.nextInt(2),
      reputation: targetLevel,
      drivetrainReliabilitySkill: (targetLevel + rng.nextInt(7) - 3).clamp(40, 99),
      tubelessAndTireMastery: (targetLevel + rng.nextInt(7) - 3).clamp(40, 99),
      chainWaxingExpertise: (targetLevel + rng.nextInt(7) - 3).clamp(40, 99),
      wheelTruingPrecision: (targetLevel + rng.nextInt(7) - 3).clamp(40, 99),
      serviceTimeMinutesPerBike: (58 - (targetLevel / 100.0 * 20)).round(),
      specialTraits: const ['Mistrz woskowania łańcucha', 'Precyzja Di2'],
    );
  }

  static Scout _generateScout({
    required String id,
    required int targetLevel,
    required ScoutingRegion region,
    required String nationalityIso,
    required math.Random rng,
  }) {
    final names = _getStaffName(nationalityIso, rng);
    return Scout(
      id: id,
      firstName: names.$1,
      lastName: names.$2,
      nationalityIso: nationalityIso,
      age: 40 + rng.nextInt(26),
      experienceLevel: targetLevel,
      monthlySalaryEur: (targetLevel * 75 + 1600),
      contractEndYear: 2027 + rng.nextInt(2),
      reputation: targetLevel,
      talentDiscoveryRating: (targetLevel + rng.nextInt(7) - 3).clamp(40, 99),
      evaluationPrecision: (targetLevel + rng.nextInt(7) - 3).clamp(40, 99),
      assignedRegion: region,
      networkReach: (targetLevel + rng.nextInt(7) - 3).clamp(40, 99),
      specialtyFocus:
          ScoutTalentFocus.values[rng.nextInt(ScoutTalentFocus.values.length)],
      specialTraits: const ['Oko do górali', 'Siatka kontaktów U19'],
    );
  }

  static (String, String) _getStaffName(String countryIso, math.Random rng) {
    switch (countryIso.toUpperCase()) {
      case 'POL':
        final first = ['Piotr', 'Krzysztof', 'Tomasz', 'Dariusz', 'Marek', 'Andrzej'];
        final last = ['Wadecki', 'Brożyna', 'Piasecki', 'Szymaniak', 'Kozłowski', 'Baran'];
        return (first[rng.nextInt(first.length)], last[rng.nextInt(last.length)]);
      case 'FRA':
        final first = ['Marc', 'Vincent', 'Yvon', 'Julien', 'Philippe', 'Thierry'];
        final last = ['Madiot', 'Lavenu', 'Ledanois', 'Guimard', 'Bourgain', 'Pineau'];
        return (first[rng.nextInt(first.length)], last[rng.nextInt(last.length)]);
      case 'BEL':
        final first = ['Patrick', 'Johan', 'Dirk', 'Wilfried', 'Sven', 'Tom'];
        final last = ['Lefevere', 'Bruyneel', 'Demol', 'Peeters', 'Vanthourenhout', 'Steels'];
        return (first[rng.nextInt(first.length)], last[rng.nextInt(last.length)]);
      case 'ITA':
        final first = ['Gianluigi', 'Paolo', 'Rodolfo', 'Mario', 'Stefano', 'Luca'];
        final last = ['Stanga', 'Bettini', 'Massignani', 'Scirea', 'Zanatta', 'Guercilena'];
        return (first[rng.nextInt(first.length)], last[rng.nextInt(last.length)]);
      case 'COL':
        final first = ['Libardo', 'Oliverio', 'Hernan', 'Jairo', 'Raul', 'Mauricio'];
        final last = ['Nino', 'Rincon', 'Buenahora', 'Chaves', 'Mesa', 'Ardila'];
        return (first[rng.nextInt(first.length)], last[rng.nextInt(last.length)]);
      default:
        final first = ['Alex', 'David', 'Michael', 'Lars', 'Kurt', 'Erik'];
        final last = ['Brailsford', 'Millar', 'Bjarne', 'Bak', 'Arvesen', 'Zabel'];
        return (first[rng.nextInt(first.length)], last[rng.nextInt(last.length)]);
    }
  }

  /// Generuje pulę wolnych agentów na rynku pracy dla wszystkich ról
  static List<StaffMember> generateFreeAgentMarketPool({
    int countPerRole = 3,
    int seed = 777,
  }) {
    final rng = math.Random(seed);
    final list = <StaffMember>[];
    final countries = ['FRA', 'BEL', 'ITA', 'ESP', 'POL', 'GBR', 'COL', 'NED', 'GER', 'DEN'];

    for (int i = 0; i < countPerRole; i++) {
      // DS
      list.add(_generateSportsDirector(
        id: 'fa_ds_$i',
        targetLevel: 55 + rng.nextInt(38),
        nationalityIso: countries[rng.nextInt(countries.length)],
        rng: rng,
      ));
      // Coach
      list.add(_generatePerformanceCoach(
        id: 'fa_coach_$i',
        targetLevel: 55 + rng.nextInt(38),
        nationalityIso: countries[rng.nextInt(countries.length)],
        rng: rng,
      ));
      // Doctor
      list.add(_generateTeamDoctor(
        id: 'fa_doc_$i',
        targetLevel: 55 + rng.nextInt(38),
        nationalityIso: countries[rng.nextInt(countries.length)],
        rng: rng,
      ));
      // Mechanic
      list.add(_generateHeadMechanic(
        id: 'fa_mech_$i',
        targetLevel: 55 + rng.nextInt(38),
        nationalityIso: countries[rng.nextInt(countries.length)],
        rng: rng,
      ));
      // Scout
      list.add(_generateScout(
        id: 'fa_scout_$i',
        targetLevel: 55 + rng.nextInt(38),
        region: ScoutingRegion.values[rng.nextInt(ScoutingRegion.values.length)],
        nationalityIso: countries[rng.nextInt(countries.length)],
        rng: rng,
      ));
    }
    return list;
  }

  /// Generuje domyślne grupy treningowe dla drużyny
  static List<TrainingGroup> generateDefaultTrainingGroups({
    List<PerformanceCoach>? availableCoaches,
    List<Rider>? availableRiders,
  }) {
    final coach1Id = (availableCoaches != null && availableCoaches.isNotEmpty)
        ? availableCoaches.first.id
        : null;
    final coach2Id = (availableCoaches != null && availableCoaches.length > 1)
        ? availableCoaches[1].id
        : null;

    final riderIds = (availableRiders ?? []).map((r) => r.id).toList();

    return [
      TrainingGroup(
        id: 'group_gc_climbers',
        name: 'Grupa Górska / Liderzy GC',
        description: 'Optymalizacja VO2max, progu FTP i wydolności w strefie wysokogórskiej',
        focusSpecialization: CoachSpecialization.enduranceAndClimbing,
        assignedCoachId: coach1Id,
        assignedRiderIds: riderIds.take(4).toList(),
      ),
      TrainingGroup(
        id: 'group_sprint_train',
        name: 'Pociąg Sprinterski & Finiszerzy',
        description: 'Moc maksymalna W15s, praca beztlenowa i koordynacja rozprowadzania',
        focusSpecialization: CoachSpecialization.sprintAndExplosiveness,
        assignedCoachId: coach2Id,
        assignedRiderIds: riderIds.skip(4).take(4).toList(),
      ),
      TrainingGroup(
        id: 'group_time_trial_aero',
        name: 'Maszyny Aero & Jazda na Czas',
        description: 'Utrzymanie pozycji aero, pacing mocy progowej oraz stabilność tułowia',
        focusSpecialization: CoachSpecialization.timeTrialAero,
        assignedCoachId: null,
        assignedRiderIds: riderIds.skip(8).take(4).toList(),
      ),
      TrainingGroup(
        id: 'group_u23_development',
        name: 'Młodzieżowcy & Wszechstronni',
        description: 'Podstawowa baza tlenowa Z2, nawyki regeneracyjne i zapobieganie kontuzjom',
        focusSpecialization: CoachSpecialization.allRoundDevelopment,
        assignedCoachId: null,
        assignedRiderIds: riderIds.skip(12).take(4).toList(),
      ),
    ];
  }
}

// =============================================================================
// 7. TRAINING GROUP (Grupy Treningowe Kolarzy)
// =============================================================================

/// Grupa treningowa zrzeszająca 4-5 kolarzy pod okiem dedykowanego trenera przygotowania fizycznego.
class TrainingGroup {
  final String id;
  final String name;
  final String description;
  final CoachSpecialization focusSpecialization;
  final String? assignedCoachId;
  final List<String> assignedRiderIds;

  const TrainingGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.focusSpecialization,
    this.assignedCoachId,
    this.assignedRiderIds = const [],
  });

  /// Czy specjalizacja trenera jest synergiczna ze specjalizacją kolarza
  static bool isSynergistic(CoachSpecialization coachSpec, RiderSpecialization riderSpec) {
    switch (coachSpec) {
      case CoachSpecialization.enduranceAndClimbing:
        return riderSpec == RiderSpecialization.gcClimber ||
            riderSpec == RiderSpecialization.pureClimber ||
            riderSpec == RiderSpecialization.puncher;
      case CoachSpecialization.sprintAndExplosiveness:
        return riderSpec == RiderSpecialization.pureSprinter ||
            riderSpec == RiderSpecialization.versatileSprinter;
      case CoachSpecialization.timeTrialAero:
        return riderSpec == RiderSpecialization.timeTrialist ||
            riderSpec == RiderSpecialization.classicCobbles;
      case CoachSpecialization.allRoundDevelopment:
        return true;
    }
  }

  /// Wylicza wskaźnik synergii grupy (0.0 do 1.0)
  double calculateSynergyRatio(PerformanceCoach? coach, List<Rider> riders) {
    if (coach == null || riders.isEmpty) return 0.5;
    int matchingCount = 0;
    for (final r in riders) {
      if (isSynergistic(coach.specialization, r.specialization)) {
        matchingCount++;
      }
    }
    final coachLevelFactor = coach.experienceLevel / 100.0;
    final matchRatio = matchingCount / riders.length;
    // Wypadkowa synergia: 50% dopasowanie profilu, 50% poziom wiedzy trenera
    return (0.5 * matchRatio + 0.5 * coachLevelFactor).clamp(0.2, 1.0);
  }

  /// Procentowy bonus do progresji FTP i watów sprintu (np. +10% do +20%)
  int calculateSynergyBonusPercent(PerformanceCoach? coach, List<Rider> riders) {
    if (coach == null) return 0;
    final ratio = calculateSynergyRatio(coach, riders);
    return (ratio * 20.0).round();
  }

  TrainingGroup copyWith({
    String? id,
    String? name,
    String? description,
    CoachSpecialization? focusSpecialization,
    String? assignedCoachId,
    bool clearCoach = false,
    List<String>? assignedRiderIds,
  }) {
    return TrainingGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      focusSpecialization: focusSpecialization ?? this.focusSpecialization,
      assignedCoachId:
          clearCoach ? null : (assignedCoachId ?? this.assignedCoachId),
      assignedRiderIds: assignedRiderIds ?? this.assignedRiderIds,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'focusSpecialization': focusSpecialization.toJson(),
        'assignedCoachId': assignedCoachId,
        'assignedRiderIds': assignedRiderIds,
      };

  factory TrainingGroup.fromJson(Map<String, dynamic> json) {
    return TrainingGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      focusSpecialization: json['focusSpecialization'] != null
          ? CoachSpecialization.fromJson(json['focusSpecialization'] as String)
          : CoachSpecialization.allRoundDevelopment,
      assignedCoachId: json['assignedCoachId'] as String?,
      assignedRiderIds: (json['assignedRiderIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}

// =============================================================================
// 8. RACE DIRECTOR ASSIGNMENT (Wybór Dyrektorów na Wyścig)
// =============================================================================

/// Przypisanie Dyrektorów Sportowych do wozów technicznych na konkretny wyścig.
class RaceDirectorAssignment {
  final String raceId;
  final String raceName;
  final String leadDirectorId; // Wóz techniczny #1 (Główny DS)
  final String? supportDirectorId; // Wóz techniczny #2 (Wsparcie)
  final DateTime assignedAt;

  const RaceDirectorAssignment({
    required this.raceId,
    required this.raceName,
    required this.leadDirectorId,
    this.supportDirectorId,
    required this.assignedAt,
  });

  RaceDirectorAssignment copyWith({
    String? raceId,
    String? raceName,
    String? leadDirectorId,
    String? supportDirectorId,
    bool clearSupport = false,
    DateTime? assignedAt,
  }) {
    return RaceDirectorAssignment(
      raceId: raceId ?? this.raceId,
      raceName: raceName ?? this.raceName,
      leadDirectorId: leadDirectorId ?? this.leadDirectorId,
      supportDirectorId:
          clearSupport ? null : (supportDirectorId ?? this.supportDirectorId),
      assignedAt: assignedAt ?? this.assignedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'raceId': raceId,
        'raceName': raceName,
        'leadDirectorId': leadDirectorId,
        'supportDirectorId': supportDirectorId,
        'assignedAt': assignedAt.toIso8601String(),
      };

  factory RaceDirectorAssignment.fromJson(Map<String, dynamic> json) {
    return RaceDirectorAssignment(
      raceId: json['raceId'] as String,
      raceName: json['raceName'] as String,
      leadDirectorId: json['leadDirectorId'] as String,
      supportDirectorId: json['supportDirectorId'] as String?,
      assignedAt: DateTime.parse(json['assignedAt'] as String),
    );
  }
}
