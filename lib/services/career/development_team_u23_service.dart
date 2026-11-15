// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import '../../models/rider/lactate_and_lab_profile.dart';
import '../../models/rider/rider.dart';
import '../../models/rider/rider_contract.dart';
import '../../models/team/cycling_team.dart';
import '../generators/rider_procedural_generator.dart';

/// Poziom infrastruktury i zaplecza szkoleniowego zespołu młodzieżowego U23.
enum DevoInfrastructureTier {
  /// Poziom 1: Baza Regionalna (Regional Devo Base)
  /// Podstawowa opieka trenerska, starty w krajowych kryteriach i wyścigach U23.
  regional,

  /// Poziom 2: Narodowy Zespół Kontynentalny (National Continental Devo)
  /// Licencja UCI Continental, dedykowany wóz techniczny, dietetyk i zgrupowania w Hiszpanii.
  nationalContinental,

  /// Poziom 3: Elitarny Kampus World-Class (World-Class Devo Campus)
  /// Pełny transfer technologii WorldTeamu, lab wydolnościowy, stały aero-fitting i wysokie góry.
  worldClassCampus;

  String toJson() => name;

  static DevoInfrastructureTier fromJson(String value) {
    return DevoInfrastructureTier.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => DevoInfrastructureTier.regional,
    );
  }

  String get displayName {
    switch (this) {
      case DevoInfrastructureTier.regional:
        return 'Baza Regionalna U23 (Tier 1)';
      case DevoInfrastructureTier.nationalContinental:
        return 'Klub Kontynentalny UCI Devo (Tier 2)';
      case DevoInfrastructureTier.worldClassCampus:
        return 'Elitarny Kampus Rozwojowy World-Class (Tier 3)';
    }
  }

  /// Maksymalna pojemność kadry młodzieżowej
  int get maxRosterCapacity {
    switch (this) {
      case DevoInfrastructureTier.regional:
        return 8;
      case DevoInfrastructureTier.nationalContinental:
        return 12;
      case DevoInfrastructureTier.worldClassCampus:
        return 16;
    }
  }

  /// Koszt założenia lub rozbudowy do tego poziomu w Euro
  int get upgradeCostEur {
    switch (this) {
      case DevoInfrastructureTier.regional:
        return 120000;
      case DevoInfrastructureTier.nationalContinental:
        return 85000;
      case DevoInfrastructureTier.worldClassCampus:
        return 180000;
    }
  }

  /// Stały miesięczny koszt utrzymania infrastruktury i sztabu Devo w Euro
  int get monthlyMaintenanceCostEur {
    switch (this) {
      case DevoInfrastructureTier.regional:
        return 9500;
      case DevoInfrastructureTier.nationalContinental:
        return 21000;
      case DevoInfrastructureTier.worldClassCampus:
        return 42000;
    }
  }

  /// Mnożnik przyrostu parametrów fizjologicznych młodych adeptów
  double get growthMultiplier {
    switch (this) {
      case DevoInfrastructureTier.regional:
        return 1.0;
      case DevoInfrastructureTier.nationalContinental:
        return 1.25;
      case DevoInfrastructureTier.worldClassCampus:
        return 1.55;
    }
  }
}

/// Kategoria i ranga wyścigu młodzieżowego U23.
enum YouthRaceCategory {
  /// Młodzieżowy Grand Tour (Giro Next Gen / Baby Giro)
  u23GrandTour,

  /// Wyścig Pucharu Narodów UCI (Tour de l'Avenir)
  u23NationsCup,

  /// Klasyk Młodzieżowy (Paris-Roubaix Espoirs, Liège-Bastogne-Liège U23)
  u23MonumentClassic,

  /// Trudna etapówka górska (Ronde de l'Isard, Course de la Paix U23)
  continentalStageRace,

  /// Włoski prestiżowy klasyk pagórkowaty (Giro del Belvedere, Trofeo Piva)
  u23RegionalClassic;

  String toJson() => name;

  static YouthRaceCategory fromJson(String value) {
    return YouthRaceCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => YouthRaceCategory.u23RegionalClassic,
    );
  }

  String get label {
    switch (this) {
      case YouthRaceCategory.u23GrandTour:
        return 'Grand Tour U23 (Giro Next Gen)';
      case YouthRaceCategory.u23NationsCup:
        return 'Puchar Narodów U23 (Tour de l\'Avenir)';
      case YouthRaceCategory.u23MonumentClassic:
        return 'Monument U23 (Bruzdy & Wzgórza)';
      case YouthRaceCategory.continentalStageRace:
        return 'Etapówka Kontynentalna U23';
      case YouthRaceCategory.u23RegionalClassic:
        return 'Prestiżowy Klasyk U23';
    }
  }
}

/// Status kolarza w programie młodzieżowym Devo Squadu.
enum DevoRiderStatus {
  /// Aktywny kolarz szkolący się i ścigający w zespole U23
  activeU23,

  /// Stażysta (Stagiaire) – dopuszczony do startów w WorldTeamie od 1 sierpnia
  stagiaire,

  /// Awansowany na stałe do pierwszego składu zawodowego
  promotedToWorldTeam,

  /// Przekroczył limit wiekowy kategorii U23 (ukończone 23 lata)
  graduatedAgeLimit,

  /// Zesłany tymczasowo z pierwszego zespołu w celu odbudowy morale i punktowania
  demotedFromWorldTeam;

  String toJson() => name;

  static DevoRiderStatus fromJson(String value) {
    return DevoRiderStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => DevoRiderStatus.activeU23,
    );
  }

  String get label {
    switch (this) {
      case DevoRiderStatus.activeU23:
        return 'Aktywny U23 (Devo)';
      case DevoRiderStatus.stagiaire:
        return 'Stażysta (Stagiaire)';
      case DevoRiderStatus.promotedToWorldTeam:
        return 'Awansowany do Pierwszego Składu';
      case DevoRiderStatus.graduatedAgeLimit:
        return 'Absolwent U23 (Wiek > 22)';
      case DevoRiderStatus.demotedFromWorldTeam:
        return 'Zesłany na odbudowę (Z WorldTeamu)';
    }
  }
}

/// Wycinek parametrów fizjologicznych i motorycznych kolarza z comiesięcznego audytu.
class PhysiologicalAuditSnapshot {
  final DateTime testDate;
  final int ftpWatts;
  final double wattsPerKg;
  final double vo2Max;
  final double vlaMax;
  final int maxSprintPower5s;
  final int overallRating;
  final String notes;

  const PhysiologicalAuditSnapshot({
    required this.testDate,
    required this.ftpWatts,
    required this.wattsPerKg,
    required this.vo2Max,
    required this.vlaMax,
    required this.maxSprintPower5s,
    required this.overallRating,
    required this.notes,
  });

  Map<String, dynamic> toJson() => {
        'testDate': testDate.toIso8601String(),
        'ftpWatts': ftpWatts,
        'wattsPerKg': wattsPerKg,
        'vo2Max': vo2Max,
        'vlaMax': vlaMax,
        'maxSprintPower5s': maxSprintPower5s,
        'overallRating': overallRating,
        'notes': notes,
      };

  factory PhysiologicalAuditSnapshot.fromJson(Map<String, dynamic> json) {
    return PhysiologicalAuditSnapshot(
      testDate: DateTime.parse(json['testDate'] as String),
      ftpWatts: (json['ftpWatts'] as num).toInt(),
      wattsPerKg: (json['wattsPerKg'] as num).toDouble(),
      vo2Max: (json['vo2Max'] as num).toDouble(),
      vlaMax: (json['vlaMax'] as num).toDouble(),
      maxSprintPower5s: (json['maxSprintPower5s'] as num).toInt(),
      overallRating: (json['overallRating'] as num).toInt(),
      notes: json['notes'] as String,
    );
  }
}

/// Profil młodego zawodnika rozwijającego się w zespole młodzieżowym U23.
class DevoRiderProfile {
  final Rider rider;
  final DateTime signedDate;
  final int monthlySalaryEur;
  final int contractEndYear;
  final DevoRiderStatus status;
  final int raceDaysThisSeason;

  /// Wskaźnik zmęczenia skumulowanego / ryzyka przetrenowania (0.0 - 100.0)
  /// Kolarze 18-letni przy > 60.0 pkt zaczynają cierpieć na syndrom wypalenia.
  final double burnoutFatigueIndex;

  /// Identyfikator starszego kolarza z pierwszego składu przydzielonego jako mentor
  final String? seniorMentorId;
  final String? seniorMentorName;

  /// Zgromadzone punkty w wyścigach młodzieżowych w tym sezonie
  final int uciYouthPointsSeason;

  /// Historia cyklicznych audytów wydolnościowych
  final List<PhysiologicalAuditSnapshot> auditHistory;

  const DevoRiderProfile({
    required this.rider,
    required this.signedDate,
    required this.monthlySalaryEur,
    required this.contractEndYear,
    this.status = DevoRiderStatus.activeU23,
    this.raceDaysThisSeason = 0,
    this.burnoutFatigueIndex = 15.0,
    this.seniorMentorId,
    this.seniorMentorName,
    this.uciYouthPointsSeason = 0,
    this.auditHistory = const [],
  });

  /// Wiek kolarza na podstawie daty urodzenia
  int get currentAge {
    final now = DateTime.now();
    int age = now.year - rider.birthDate.year;
    if (now.month < rider.birthDate.month ||
        (now.month == rider.birthDate.month && now.day < rider.birthDate.day)) {
      age--;
    }
    return age;
  }

  /// Czy kolarz mieści się w limitach wiekowych kategorii U23 (18 - 22 lata)
  bool get isEligibleForU23 => currentAge <= 22;

  /// Czy kolarz cierpi na syndrom przetrenowania / wypalenia (Burnout)
  bool get isOvertrained => burnoutFatigueIndex >= 70.0;

  DevoRiderProfile copyWith({
    Rider? rider,
    DateTime? signedDate,
    int? monthlySalaryEur,
    int? contractEndYear,
    DevoRiderStatus? status,
    int? raceDaysThisSeason,
    double? burnoutFatigueIndex,
    String? seniorMentorId,
    String? seniorMentorName,
    int? uciYouthPointsSeason,
    List<PhysiologicalAuditSnapshot>? auditHistory,
  }) {
    return DevoRiderProfile(
      rider: rider ?? this.rider,
      signedDate: signedDate ?? this.signedDate,
      monthlySalaryEur: monthlySalaryEur ?? this.monthlySalaryEur,
      contractEndYear: contractEndYear ?? this.contractEndYear,
      status: status ?? this.status,
      raceDaysThisSeason: raceDaysThisSeason ?? this.raceDaysThisSeason,
      burnoutFatigueIndex: burnoutFatigueIndex ?? this.burnoutFatigueIndex,
      seniorMentorId: seniorMentorId ?? this.seniorMentorId,
      seniorMentorName: seniorMentorName ?? this.seniorMentorName,
      uciYouthPointsSeason: uciYouthPointsSeason ?? this.uciYouthPointsSeason,
      auditHistory: auditHistory != null
          ? List.unmodifiable(auditHistory)
          : this.auditHistory,
    );
  }

  Map<String, dynamic> toJson() => {
        'rider': rider.toJson(),
        'signedDate': signedDate.toIso8601String(),
        'monthlySalaryEur': monthlySalaryEur,
        'contractEndYear': contractEndYear,
        'status': status.toJson(),
        'raceDaysThisSeason': raceDaysThisSeason,
        'burnoutFatigueIndex': burnoutFatigueIndex,
        'seniorMentorId': seniorMentorId,
        'seniorMentorName': seniorMentorName,
        'uciYouthPointsSeason': uciYouthPointsSeason,
        'auditHistory': auditHistory.map((s) => s.toJson()).toList(),
      };

  factory DevoRiderProfile.fromJson(Map<String, dynamic> json) {
    return DevoRiderProfile(
      rider: Rider.fromJson(json['rider'] as Map<String, dynamic>),
      signedDate: DateTime.parse(json['signedDate'] as String),
      monthlySalaryEur: (json['monthlySalaryEur'] as num).toInt(),
      contractEndYear: (json['contractEndYear'] as num).toInt(),
      status: DevoRiderStatus.fromJson(json['status'] as String),
      raceDaysThisSeason: (json['raceDaysThisSeason'] as num?)?.toInt() ?? 0,
      burnoutFatigueIndex:
          (json['burnoutFatigueIndex'] as num?)?.toDouble() ?? 15.0,
      seniorMentorId: json['seniorMentorId'] as String?,
      seniorMentorName: json['seniorMentorName'] as String?,
      uciYouthPointsSeason:
          (json['uciYouthPointsSeason'] as num?)?.toInt() ?? 0,
      auditHistory: (json['auditHistory'] as List<dynamic>?)
              ?.map((e) => PhysiologicalAuditSnapshot.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

/// Oficjalny wyścig z młodzieżowego kalendarza U23.
class YouthRaceEvent {
  final String id;
  final String name;
  final String countryIso;
  final YouthRaceCategory category;
  final int month;
  final int durationDays;
  final int uciPointsForWin;
  final double mountainDifficulty; // 1.0 - 5.0
  final double cobblesDifficulty; // 1.0 - 5.0
  final int requiredMinSquadSize;
  final int maxSquadSize;
  final int prizePoolEur;
  final String description;

  const YouthRaceEvent({
    required this.id,
    required this.name,
    required this.countryIso,
    required this.category,
    required this.month,
    required this.durationDays,
    required this.uciPointsForWin,
    this.mountainDifficulty = 1.0,
    this.cobblesDifficulty = 1.0,
    this.requiredMinSquadSize = 4,
    this.maxSquadSize = 6,
    required this.prizePoolEur,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'countryIso': countryIso,
        'category': category.toJson(),
        'month': month,
        'durationDays': durationDays,
        'uciPointsForWin': uciPointsForWin,
        'mountainDifficulty': mountainDifficulty,
        'cobblesDifficulty': cobblesDifficulty,
        'requiredMinSquadSize': requiredMinSquadSize,
        'maxSquadSize': maxSquadSize,
        'prizePoolEur': prizePoolEur,
        'description': description,
      };

  factory YouthRaceEvent.fromJson(Map<String, dynamic> json) {
    return YouthRaceEvent(
      id: json['id'] as String,
      name: json['name'] as String,
      countryIso: json['countryIso'] as String,
      category: YouthRaceCategory.fromJson(json['category'] as String),
      month: (json['month'] as num).toInt(),
      durationDays: (json['durationDays'] as num).toInt(),
      uciPointsForWin: (json['uciPointsForWin'] as num).toInt(),
      mountainDifficulty:
          (json['mountainDifficulty'] as num?)?.toDouble() ?? 1.0,
      cobblesDifficulty: (json['cobblesDifficulty'] as num?)?.toDouble() ?? 1.0,
      requiredMinSquadSize:
          (json['requiredMinSquadSize'] as num?)?.toInt() ?? 4,
      maxSquadSize: (json['maxSquadSize'] as num?)?.toInt() ?? 6,
      prizePoolEur: (json['prizePoolEur'] as num).toInt(),
      description: json['description'] as String,
    );
  }
}

/// Rezultat występu pojedynczego zawodnika w wyścigu U23.
class YouthRaceRiderPlacement {
  final String riderId;
  final String riderName;
  final int position;
  final int uciPoints;
  final int expGained;
  final double fatigueDelta;
  final bool hadCrash;

  const YouthRaceRiderPlacement({
    required this.riderId,
    required this.riderName,
    required this.position,
    required this.uciPoints,
    required this.expGained,
    required this.fatigueDelta,
    this.hadCrash = false,
  });

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'riderName': riderName,
        'position': position,
        'uciPoints': uciPoints,
        'expGained': expGained,
        'fatigueDelta': fatigueDelta,
        'hadCrash': hadCrash,
      };

  factory YouthRaceRiderPlacement.fromJson(Map<String, dynamic> json) {
    return YouthRaceRiderPlacement(
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      position: (json['position'] as num).toInt(),
      uciPoints: (json['uciPoints'] as num).toInt(),
      expGained: (json['expGained'] as num).toInt(),
      fatigueDelta: (json['fatigueDelta'] as num).toDouble(),
      hadCrash: json['hadCrash'] as bool? ?? false,
    );
  }
}

/// Kompletny raport i podsumowanie rozegranego wyścigu młodzieżowego.
class YouthRaceResult {
  final String raceId;
  final String raceName;
  final DateTime raceDate;
  final List<YouthRaceRiderPlacement> placements;
  final int teamPointsEarned;
  final int prizeMoneyWonEur;
  final String raceReport;

  const YouthRaceResult({
    required this.raceId,
    required this.raceName,
    required this.raceDate,
    required this.placements,
    required this.teamPointsEarned,
    required this.prizeMoneyWonEur,
    required this.raceReport,
  });

  Map<String, dynamic> toJson() => {
        'raceId': raceId,
        'raceName': raceName,
        'raceDate': raceDate.toIso8601String(),
        'placements': placements.map((p) => p.toJson()).toList(),
        'teamPointsEarned': teamPointsEarned,
        'prizeMoneyWonEur': prizeMoneyWonEur,
        'raceReport': raceReport,
      };

  factory YouthRaceResult.fromJson(Map<String, dynamic> json) {
    return YouthRaceResult(
      raceId: json['raceId'] as String,
      raceName: json['raceName'] as String,
      raceDate: DateTime.parse(json['raceDate'] as String),
      placements: (json['placements'] as List<dynamic>)
          .map((e) =>
              YouthRaceRiderPlacement.fromJson(e as Map<String, dynamic>))
          .toList(),
      teamPointsEarned: (json['teamPointsEarned'] as num).toInt(),
      prizeMoneyWonEur: (json['prizeMoneyWonEur'] as num).toInt(),
      raceReport: json['raceReport'] as String,
    );
  }
}

/// Pełny model zespołu młodzieżowego U23 (Development Team).
class DevelopmentTeamU23 {
  final String primaryTeamId;
  final String devoTeamName;
  final bool isFormed;
  final DateTime? formationDate;
  final DevoInfrastructureTier infrastructureTier;
  final List<DevoRiderProfile> riders;
  final List<YouthRaceResult> raceResultsHistory;
  final int totalYouthUciPoints;
  final int totalAlumniPromoted;
  final int cashBudgetEur;
  final int totalPrizeMoneyWonEur;

  const DevelopmentTeamU23({
    required this.primaryTeamId,
    required this.devoTeamName,
    this.isFormed = false,
    this.formationDate,
    this.infrastructureTier = DevoInfrastructureTier.regional,
    this.riders = const [],
    this.raceResultsHistory = const [],
    this.totalYouthUciPoints = 0,
    this.totalAlumniPromoted = 0,
    this.cashBudgetEur = 0,
    this.totalPrizeMoneyWonEur = 0,
  });

  /// Liczba aktywnych adeptów w zespole U23
  int get activeRidersCount =>
      riders.where((r) => r.status == DevoRiderStatus.activeU23 ||
                          r.status == DevoRiderStatus.stagiaire ||
                          r.status == DevoRiderStatus.demotedFromWorldTeam).length;

  /// Czy kadra młodzieżowa osiągnęła maksymalną pojemność
  bool get isRosterFull => activeRidersCount >= infrastructureTier.maxRosterCapacity;

  /// Miesięczny sumaryczny koszt utrzymania Devo (sztab + pensje kolarzy)
  int get totalMonthlyBurnRateEur {
    if (!isFormed) return 0;
    int salaries = 0;
    for (final r in riders) {
      if (r.status == DevoRiderStatus.activeU23 ||
          r.status == DevoRiderStatus.stagiaire ||
          r.status == DevoRiderStatus.demotedFromWorldTeam) {
        salaries += r.monthlySalaryEur;
      }
    }
    return infrastructureTier.monthlyMaintenanceCostEur + salaries;
  }

  DevelopmentTeamU23 copyWith({
    String? primaryTeamId,
    String? devoTeamName,
    bool? isFormed,
    DateTime? formationDate,
    DevoInfrastructureTier? infrastructureTier,
    List<DevoRiderProfile>? riders,
    List<YouthRaceResult>? raceResultsHistory,
    int? totalYouthUciPoints,
    int? totalAlumniPromoted,
    int? cashBudgetEur,
    int? totalPrizeMoneyWonEur,
  }) {
    return DevelopmentTeamU23(
      primaryTeamId: primaryTeamId ?? this.primaryTeamId,
      devoTeamName: devoTeamName ?? this.devoTeamName,
      isFormed: isFormed ?? this.isFormed,
      formationDate: formationDate ?? this.formationDate,
      infrastructureTier: infrastructureTier ?? this.infrastructureTier,
      riders: riders != null ? List.unmodifiable(riders) : this.riders,
      raceResultsHistory: raceResultsHistory != null
          ? List.unmodifiable(raceResultsHistory)
          : this.raceResultsHistory,
      totalYouthUciPoints: totalYouthUciPoints ?? this.totalYouthUciPoints,
      totalAlumniPromoted: totalAlumniPromoted ?? this.totalAlumniPromoted,
      cashBudgetEur: cashBudgetEur ?? this.cashBudgetEur,
      totalPrizeMoneyWonEur:
          totalPrizeMoneyWonEur ?? this.totalPrizeMoneyWonEur,
    );
  }

  Map<String, dynamic> toJson() => {
        'primaryTeamId': primaryTeamId,
        'devoTeamName': devoTeamName,
        'isFormed': isFormed,
        'formationDate': formationDate?.toIso8601String(),
        'infrastructureTier': infrastructureTier.toJson(),
        'riders': riders.map((r) => r.toJson()).toList(),
        'raceResultsHistory':
            raceResultsHistory.map((res) => res.toJson()).toList(),
        'totalYouthUciPoints': totalYouthUciPoints,
        'totalAlumniPromoted': totalAlumniPromoted,
        'cashBudgetEur': cashBudgetEur,
        'totalPrizeMoneyWonEur': totalPrizeMoneyWonEur,
      };

  factory DevelopmentTeamU23.fromJson(Map<String, dynamic> json) {
    return DevelopmentTeamU23(
      primaryTeamId: json['primaryTeamId'] as String,
      devoTeamName: json['devoTeamName'] as String,
      isFormed: json['isFormed'] as bool? ?? false,
      formationDate: json['formationDate'] != null
          ? DateTime.parse(json['formationDate'] as String)
          : null,
      infrastructureTier: DevoInfrastructureTier.fromJson(
          json['infrastructureTier'] as String? ?? 'regional'),
      riders: (json['riders'] as List<dynamic>?)
              ?.map((e) =>
                  DevoRiderProfile.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      raceResultsHistory: (json['raceResultsHistory'] as List<dynamic>?)
              ?.map((e) =>
                  YouthRaceResult.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      totalYouthUciPoints:
          (json['totalYouthUciPoints'] as num?)?.toInt() ?? 0,
      totalAlumniPromoted:
          (json['totalAlumniPromoted'] as num?)?.toInt() ?? 0,
      cashBudgetEur: (json['cashBudgetEur'] as num?)?.toInt() ?? 0,
      totalPrizeMoneyWonEur:
          (json['totalPrizeMoneyWonEur'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Serwis zarządzania programem młodzieżowym U23 (Development Team Service).
class DevelopmentTeamU23Service {
  DevelopmentTeamU23Service._();

  static final math.Random _defaultRandom = math.Random();

  // ===========================================================================
  // 1. ZAKŁADANIE I ROZBUDOWA DEVO SQUADU
  // ===========================================================================

  /// Zakłada nowy zespół młodzieżowy U23 przy drużynie głównej gracza.
  /// Pobiera opłatę rejestracyjną UCI oraz koszt bazy regionalnej.
  static ({CyclingTeam updatedTeam, DevelopmentTeamU23 devoTeam})
      formDevelopmentTeam({
    required CyclingTeam primaryTeam,
    String? customDevoName,
    DateTime? currentDate,
  }) {
    final date = currentDate ?? DateTime.now();
    final formationCost = DevoInfrastructureTier.regional.upgradeCostEur;

    if (primaryTeam.cashBalanceEur < formationCost) {
      throw StateError(
          'Brak wystarczających środków w budżecie klubu na założenie Devo Teamu. '
          'Wymagane: $formationCost €, dostępne: ${primaryTeam.cashBalanceEur} €.');
    }

    final devoName = customDevoName ?? '${primaryTeam.name} Devo Team';

    final updatedTeam = primaryTeam.copyWith(
      cashBalanceEur: primaryTeam.cashBalanceEur - formationCost,
    );

    final devoTeam = DevelopmentTeamU23(
      primaryTeamId: primaryTeam.id,
      devoTeamName: devoName,
      isFormed: true,
      formationDate: date,
      infrastructureTier: DevoInfrastructureTier.regional,
      cashBudgetEur: 40000,
      riders: const [],
      raceResultsHistory: const [],
    );

    return (updatedTeam: updatedTeam, devoTeam: devoTeam);
  }

  /// Rozbudowuje bazę szkoleniową i podnosi poziom licencji Devo Teamu.
  static ({CyclingTeam updatedTeam, DevelopmentTeamU23 updatedDevo})
      upgradeInfrastructure({
    required CyclingTeam primaryTeam,
    required DevelopmentTeamU23 devoTeam,
    required DevoInfrastructureTier targetTier,
  }) {
    if (!devoTeam.isFormed) {
      throw StateError('Najpierw należy założyć zespół młodzieżowy Devo.');
    }

    if (targetTier.index <= devoTeam.infrastructureTier.index) {
      throw ArgumentError(
          'Docelowy poziom infrastruktury musi być wyższy niż obecny.');
    }

    final cost = targetTier.upgradeCostEur;
    if (primaryTeam.cashBalanceEur < cost) {
      throw StateError(
          'Brak funduszy na upgrade bazy Devo. Wymagane: $cost €, dostępne: ${primaryTeam.cashBalanceEur} €.');
    }

    final updatedTeam = primaryTeam.copyWith(
      cashBalanceEur: primaryTeam.cashBalanceEur - cost,
    );

    final updatedDevo = devoTeam.copyWith(
      infrastructureTier: targetTier,
    );

    return (updatedTeam: updatedTeam, updatedDevo: updatedDevo);
  }

  // ===========================================================================
  // 2. SKAUTING I KONTRAKTOWANIE UTALENTOWANYCH 18-LATKÓW
  // ===========================================================================

  /// Generuje roczną lub kwartalną pulę utalentowanych 18-latków
  /// (absolwentów kategorii Junior U19 gotowych na przejście do U23).
  static List<Rider> generateAvailableYoungTalents({
    required int currentSeasonYear,
    int count = 8,
    math.Random? random,
  }) {
    final rng = random ?? _defaultRandom;
    final talents = <Rider>[];

    for (int i = 0; i < count; i++) {
      ScoutingTier tier;
      final roll = rng.nextDouble();
      if (roll < 0.08) {
        tier = ScoutingTier.generationalTalent; // 8% szans na diament
      } else if (roll < 0.35) {
        tier = ScoutingTier.worldTourProspect; // 27% szans na prospekta
      } else if (roll < 0.75) {
        tier = ScoutingTier.solidPro;
      } else {
        tier = ScoutingTier.continentalHopeful;
      }

      final talent = RiderProceduralGenerator.generateNeoProTalent(
        currentSeasonYear: currentSeasonYear,
        tier: tier,
        random: rng,
      );

      // Gwarantujemy wiek 18 lat (lub 19 przy wczesnym urodzeniu)
      final birthDate18 = DateTime(currentSeasonYear - 18, 1 + rng.nextInt(12), 1 + rng.nextInt(28));
      talents.add(talent.copyWith(birthDate: birthDate18));
    }

    return List.unmodifiable(talents);
  }

  /// Podpisuje kontrakt młodzieżowy z utalentowanym 18-latkiem do Devo Squadu.
  static ({CyclingTeam updatedTeam, DevelopmentTeamU23 updatedDevo})
      signYoungProspectToDevo({
    required CyclingTeam primaryTeam,
    required DevelopmentTeamU23 devoTeam,
    required Rider prospectRider,
    required int monthlySalaryEur,
    required int contractDurationYears,
    int signingBonusEur = 5000,
    DateTime? currentDate,
  }) {
    if (!devoTeam.isFormed) {
      throw StateError('Zespół młodzieżowy nie został jeszcze powołany.');
    }

    if (devoTeam.isRosterFull) {
      throw StateError(
          'Brak miejsc w zespole młodzieżowym. Osiągnięto limit ${devoTeam.infrastructureTier.maxRosterCapacity} kolarzy. '
          'Rozbuduj bazę Devo lub zwolnij zawodnika.');
    }

    // Weryfikacja wieku U23
    final now = currentDate ?? DateTime.now();
    int age = now.year - prospectRider.birthDate.year;
    if (age > 22) {
      throw ArgumentError(
          'Kolarz ma $age lat i przekracza limit kategorii U23 (maksymalnie 22 lata).');
    }

    if (primaryTeam.cashBalanceEur < signingBonusEur) {
      throw StateError(
          'Brak środków na premię za podpisanie kontraktu młodzieżowego ($signingBonusEur €).');
    }

    // Aktualizacja kolarza
    final updatedContract = prospectRider.contract.copyWith(
      teamId: devoTeam.devoTeamName,
      role: RiderRole.neoPro,
      monthlySalaryEur: monthlySalaryEur,
      contractEndYear: now.year + contractDurationYears,
      morale: 88.0,
      leaderLoyalty: 82.0,
    );

    final boundRider = prospectRider.copyWith(contract: updatedContract);

    // Pierwszy audyt fizjologiczny adepta
    final initialAudit = PhysiologicalAuditSnapshot(
      testDate: now,
      ftpWatts: boundRider.physiology.ftpWatts,
      wattsPerKg: boundRider.physiology.wattsPerKg,
      vo2Max: boundRider.physiology.vo2Max,
      vlaMax: boundRider.physiology.labProfile?.vlaMaxMmolLPerSec ?? 0.50,
      maxSprintPower5s: boundRider.powerProfile.watts5s,
      overallRating: boundRider.potential,
      notes: 'Początkowy audyt po podpisaniu kontraktu z zespołem młodzieżowym U23.',
    );

    final profile = DevoRiderProfile(
      rider: boundRider,
      signedDate: now,
      monthlySalaryEur: monthlySalaryEur,
      contractEndYear: now.year + contractDurationYears,
      status: DevoRiderStatus.activeU23,
      raceDaysThisSeason: 0,
      burnoutFatigueIndex: 12.0,
      uciYouthPointsSeason: 0,
      auditHistory: [initialAudit],
    );

    final updatedTeam = primaryTeam.copyWith(
      cashBalanceEur: primaryTeam.cashBalanceEur - signingBonusEur,
    );

    final updatedDevo = devoTeam.copyWith(
      riders: [...devoTeam.riders, profile],
    );

    return (updatedTeam: updatedTeam, updatedDevo: updatedDevo);
  }

  // ===========================================================================
  // 3. OFICJALNY KALENDARZ I ROZGRYWANIE WYŚCIGÓW MŁODZIEŻOWYCH U23
  // ===========================================================================

  /// Zwraca listę oficjalnych, prestiżowych wyścigów w kalendarzu U23.
  static List<YouthRaceEvent> getOfficialYouthRaceCalendar() {
    return const [
      YouthRaceEvent(
        id: 'u23_belvedere',
        name: 'Giro del Belvedere U23',
        countryIso: 'ITA',
        category: YouthRaceCategory.u23RegionalClassic,
        month: 4,
        durationDays: 1,
        uciPointsForWin: 45,
        mountainDifficulty: 3.2,
        cobblesDifficulty: 1.0,
        prizePoolEur: 12000,
        description: 'Włoski klasyk pagórkowaty w Villa di Villa. Strome ścianki weryfikujące dynamikę puncherów.',
      ),
      YouthRaceEvent(
        id: 'u23_trofeo_piva',
        name: 'Trofeo Piva U23',
        countryIso: 'ITA',
        category: YouthRaceCategory.u23RegionalClassic,
        month: 4,
        durationDays: 1,
        uciPointsForWin: 45,
        mountainDifficulty: 3.5,
        cobblesDifficulty: 1.0,
        prizePoolEur: 12000,
        description: 'Baskijskie nachylenia w winnicach Col San Martino. Prawdziwy chrzest bojowy wspinaczy U23.',
      ),
      YouthRaceEvent(
        id: 'u23_liege_espoirs',
        name: 'Liège-Bastogne-Liège Espoirs',
        countryIso: 'BEL',
        category: YouthRaceCategory.u23MonumentClassic,
        month: 4,
        durationDays: 1,
        uciPointsForWin: 80,
        mountainDifficulty: 3.8,
        cobblesDifficulty: 1.2,
        prizePoolEur: 18000,
        description: 'Młodzieżowa Dziekanka w Ardenach. La Redoute i Côte des Forges weryfikują przyszłych mistrzów klasyków.',
      ),
      YouthRaceEvent(
        id: 'u23_roubaix_espoirs',
        name: 'Paris-Roubaix Espoirs',
        countryIso: 'FRA',
        category: YouthRaceCategory.u23MonumentClassic,
        month: 5,
        durationDays: 1,
        uciPointsForWin: 85,
        mountainDifficulty: 1.0,
        cobblesDifficulty: 4.8,
        prizePoolEur: 20000,
        description: 'Piekło Północy U23. Sektory bruku Camphin-en-Pévèle i Carrefour de l\'Arbre testujące odporność i bikeHandling.',
      ),
      YouthRaceEvent(
        id: 'u23_ronde_isard',
        name: 'Ronde de l\'Isard',
        countryIso: 'FRA',
        category: YouthRaceCategory.continentalStageRace,
        month: 5,
        durationDays: 5,
        uciPointsForWin: 95,
        mountainDifficulty: 4.6,
        cobblesDifficulty: 1.0,
        prizePoolEur: 25000,
        description: 'Pirenejski wyścig etapowy z wspinaczkami na Plateau de Beille i Guzet-Neige. Próba ognia dla czystych górali.',
      ),
      YouthRaceEvent(
        id: 'u23_baby_giro',
        name: 'Giro Next Gen (Baby Giro)',
        countryIso: 'ITA',
        category: YouthRaceCategory.u23GrandTour,
        month: 6,
        durationDays: 8,
        uciPointsForWin: 160,
        mountainDifficulty: 4.9,
        cobblesDifficulty: 1.5,
        prizePoolEur: 65000,
        description: 'Oficjalny młodzieżowy Grand Tour we Włoszech. Przełęcz Stelvio i legendarne wspinaczki tworzące legendy WorldTouru.',
      ),
      YouthRaceEvent(
        id: 'u23_tour_de_l_avenir',
        name: 'Tour de l\'Avenir (Wyścig Przyszłości)',
        countryIso: 'FRA',
        category: YouthRaceCategory.u23NationsCup,
        month: 8,
        durationDays: 10,
        uciPointsForWin: 220,
        mountainDifficulty: 5.0,
        cobblesDifficulty: 1.2,
        prizePoolEur: 80000,
        description: 'Najbardziej prestiżowy wyścig młodzieżowy globu. Zwycięzcy Aveniru (jak Pogačar, Bernal czy Gaudu) natychmiast stają się gwiazdami WorldTouru.',
      ),
    ];
  }

  /// Wystawia kadrę Devo w wyścigu młodzieżowym i symuluje rywalizację.
  static ({
    DevelopmentTeamU23 updatedDevo,
    YouthRaceResult raceResult,
  }) simulateYouthRace({
    required DevelopmentTeamU23 devoTeam,
    required YouthRaceEvent raceEvent,
    required List<String> participantRiderIds,
    math.Random? random,
  }) {
    final rng = random ?? _defaultRandom;

    if (participantRiderIds.length < raceEvent.requiredMinSquadSize ||
        participantRiderIds.length > raceEvent.maxSquadSize) {
      throw ArgumentError(
          'Nieprawidłowa liczba kolarzy na wyścig ${raceEvent.name}. Wymagane od ${raceEvent.requiredMinSquadSize} do ${raceEvent.maxSquadSize}.');
    }

    // Wyciągamy kolarzy z Devo
    final squadProfiles = devoTeam.riders
        .where((r) => participantRiderIds.contains(r.rider.id))
        .toList();

    if (squadProfiles.length != participantRiderIds.length) {
      throw ArgumentError(
          'Część wybranych kolarzy nie należy do zespołu młodzieżowego Devo.');
    }

    final placements = <YouthRaceRiderPlacement>[];
    int totalTeamPoints = 0;
    int totalPrizeMoney = 0;

    // Obliczamy potencjał każdego kolarza pod kątem profilu wyścigu
    final scoredRiders = <({DevoRiderProfile profile, double raceScore})>[];

    for (final profile in squadProfiles) {
      final r = profile.rider;
      double score = r.physiology.ftpWatts / (r.physiology.weightKg) * 15.0;

      // Bonus za specjalizację
      if (raceEvent.mountainDifficulty >= 4.0) {
        if (r.specialization == RiderSpecialization.gcClimber ||
            r.specialization == RiderSpecialization.pureClimber) {
          score += 25.0;
        }
      }

      if (raceEvent.cobblesDifficulty >= 3.5) {
        score += r.skills.cobbles * 0.4 + r.skills.bikeHandling * 0.3;
      }

      // Kary za zmęczenie / burnout
      if (profile.isOvertrained) {
        score *= 0.65; // Drastyczny spadek mocy przy wypaleniu
      } else {
        score -= (profile.burnoutFatigueIndex * 0.2);
      }

      // Losowość rywalizacji sportowej
      score += (rng.nextDouble() * 20.0) - 10.0;
      scoredRiders.add((profile: profile, raceScore: score));
    }

    scoredRiders.sort((a, b) => b.raceScore.compareTo(a.raceScore));

    // Symulacja miejsc w peletonie U23 (100-140 rywali)
    int bestPos = 1;
    for (int i = 0; i < scoredRiders.length; i++) {
      final item = scoredRiders[i];
      final profile = item.profile;

      // Szansa na podium zależna od jakości
      int pos;
      if (i == 0) {
        // Lider Devo na ten wyścig
        pos = (item.raceScore > 105.0)
            ? (1 + rng.nextInt(3)) // Podium!
            : (item.raceScore > 90.0
                ? (4 + rng.nextInt(12)) // Top 15
                : (16 + rng.nextInt(30)));
        bestPos = pos;
      } else {
        pos = (bestPos + 4 + (i * 6) + rng.nextInt(15)).clamp(1, 110);
      }

      final bool hadCrash = rng.nextDouble() < 0.05; // 5% ryzyka kraksy
      int uciPoints = 0;
      if (pos == 1) {
        uciPoints = raceEvent.uciPointsForWin;
      } else if (pos <= 3) {
        uciPoints = (raceEvent.uciPointsForWin * 0.65).round();
      } else if (pos <= 10) {
        uciPoints = (raceEvent.uciPointsForWin * 0.35).round();
      } else if (pos <= 20) {
        uciPoints = (raceEvent.uciPointsForWin * 0.15).round();
      }

      final int expGained = 15 + (raceEvent.durationDays * 8) + (pos <= 10 ? 25 : 0);
      final double fatigueDelta = raceEvent.durationDays * 3.5;

      placements.add(
        YouthRaceRiderPlacement(
          riderId: profile.rider.id,
          riderName: profile.rider.fullName,
          position: pos,
          uciPoints: uciPoints,
          expGained: expGained,
          fatigueDelta: fatigueDelta,
          hadCrash: hadCrash,
        ),
      );

      totalTeamPoints += uciPoints;
    }

    if (bestPos == 1) {
      totalPrizeMoney = (raceEvent.prizePoolEur * 0.40).round();
    } else if (bestPos <= 3) {
      totalPrizeMoney = (raceEvent.prizePoolEur * 0.20).round();
    } else if (bestPos <= 10) {
      totalPrizeMoney = (raceEvent.prizePoolEur * 0.08).round();
    }

    final report = bestPos <= 3
        ? 'Fantastyczny występ Devo Squadu na trasie ${raceEvent.name}! '
            '${placements.first.riderName} wywalczył miejsce na podium (miejsce $bestPos), '
            'inkasując $totalTeamPoints punktów UCI U23 oraz $totalPrizeMoney € premii finansowej.'
        : 'Zakończono zmagania w ${raceEvent.name}. Najlepszy z naszych adeptów zajął $bestPos. miejsce. '
            'Cenne kilometry doświadczenia w peletonie młodzieżowym.';

    final raceResult = YouthRaceResult(
      raceId: raceEvent.id,
      raceName: raceEvent.name,
      raceDate: DateTime.now(),
      placements: placements,
      teamPointsEarned: totalTeamPoints,
      prizeMoneyWonEur: totalPrizeMoney,
      raceReport: report,
    );

    // Aktualizujemy kolarzy w Devo
    final updatedRiderProfiles = devoTeam.riders.map((profile) {
      final placement = placements.firstWhere(
        (p) => p.riderId == profile.rider.id,
        orElse: () => const YouthRaceRiderPlacement(
          riderId: '',
          riderName: '',
          position: 0,
          uciPoints: 0,
          expGained: 0,
          fatigueDelta: 0,
        ),
      );

      if (placement.riderId.isEmpty) return profile;

      // Wzrost parametrów po wyścigu
      final updatedRider = profile.rider.copyWith(
        careerPointsUci: profile.rider.careerPointsUci + placement.uciPoints,
        skills: profile.rider.skills.copyWith(
          raceIq: (profile.rider.skills.raceIq + (placement.expGained / 25).round()).clamp(1, 99),
          bikeHandling: (profile.rider.skills.bikeHandling + (raceEvent.cobblesDifficulty > 2.0 ? 1 : 0)).clamp(1, 99),
        ),
      );

      return profile.copyWith(
        rider: updatedRider,
        raceDaysThisSeason: profile.raceDaysThisSeason + raceEvent.durationDays,
        burnoutFatigueIndex: (profile.burnoutFatigueIndex + placement.fatigueDelta).clamp(0.0, 100.0),
        uciYouthPointsSeason: profile.uciYouthPointsSeason + placement.uciPoints,
      );
    }).toList();

    final updatedDevo = devoTeam.copyWith(
      riders: updatedRiderProfiles,
      totalYouthUciPoints: devoTeam.totalYouthUciPoints + totalTeamPoints,
      totalPrizeMoneyWonEur: devoTeam.totalPrizeMoneyWonEur + totalPrizeMoney,
      cashBudgetEur: devoTeam.cashBudgetEur + totalPrizeMoney,
      raceResultsHistory: [...devoTeam.raceResultsHistory, raceResult],
    );

    return (updatedDevo: updatedDevo, raceResult: raceResult);
  }

  // ===========================================================================
  // 4. ROZWÓJ FIZJOLOGICZNY I CYKLICZNE AUDYTY WYDOLNOŚCIOWE
  // ===========================================================================

  /// Przeprowadza comiesięczny audyt i symulację rozwoju fizjologicznego młodych kolarzy.
  /// Uwzględnia okno plastyczności (18-21 lat), poziom bazy Devo, obecność mentora oraz ryzyko wypalenia.
  static DevelopmentTeamU23 runMonthlyDevoPhysiologicalEvolution({
    required DevelopmentTeamU23 devoTeam,
    DateTime? currentDate,
    math.Random? random,
  }) {
    if (!devoTeam.isFormed) return devoTeam;

    final date = currentDate ?? DateTime.now();
    final rng = random ?? _defaultRandom;
    final infraMultiplier = devoTeam.infrastructureTier.growthMultiplier;

    final evolvedProfiles = devoTeam.riders.map((profile) {
      if (profile.status != DevoRiderStatus.activeU23 &&
          profile.status != DevoRiderStatus.stagiaire) {
        return profile;
      }

      final r = profile.rider;
      final int age = profile.currentAge;
      final int potentialGap = (r.potential - (r.physiology.ftpWatts / 4.2).round()).clamp(1, 35);

      // Kolarze z syndromem przetrenowania / wypalenia (burnout > 70) nie rozwijają się,
      // a ich morale i forma spadają!
      if (profile.isOvertrained) {
        final regressedRider = r.copyWith(
          contract: r.contract.copyWith(
            morale: (r.contract.morale - 8.0).clamp(20.0, 100.0),
          ),
        );
        return profile.copyWith(
          rider: regressedRider,
          // Spadek zmęczenia przy odpoczynku
          burnoutFatigueIndex: (profile.burnoutFatigueIndex - 12.0).clamp(0.0, 100.0),
        );
      }

      // Przyrost FTP w oknie plastyczności (18-21 lat)
      // Młodzi adepci mogą zyskać od +2W do +7W na miesiąc pod okiem trenerów Devo
      double baseWattsGain = (1.5 + rng.nextDouble() * 3.5) * (potentialGap / 20.0);
      baseWattsGain *= infraMultiplier;

      // Bonus od przypisanego starszego mentora (+25% do rozwoju)
      if (profile.seniorMentorId != null) {
        baseWattsGain *= 1.25;
      }

      final int newFtp = (r.physiology.ftpWatts + baseWattsGain.round()).clamp(200, 480);
      final double newVo2Max = (r.physiology.vo2Max + (baseWattsGain * 0.04)).clamp(50.0, 92.0);

      // Adaptacja VLaMax w zależności od specjalizacji
      double newVlaMax = r.physiology.labProfile?.vlaMaxMmolLPerSec ?? 0.50;
      if (r.specialization == RiderSpecialization.gcClimber ||
          r.specialization == RiderSpecialization.pureClimber ||
          r.specialization == RiderSpecialization.timeTrialist) {
        // Obniżanie VLaMax dla lepszej wydajności tlenowej i ekonomii progowej
        newVlaMax = (newVlaMax - 0.015).clamp(0.24, 0.70);
      } else if (r.specialization == RiderSpecialization.pureSprinter) {
        // Zachowanie wysokiego VLaMax pod wybuchowy finisz
        newVlaMax = (newVlaMax + 0.01).clamp(0.55, 0.85);
      }

      // Wzrost parametrów mocy
      final newPowerProfile = r.powerProfile.copyWith(
        watts60m: newFtp,
        watts20m: (newFtp * 1.05).round(),
        watts5m: (newFtp * 1.22).round(),
        functionalThresholdPowerWatts: newFtp,
      );

      final newLabProfile = r.physiology.labProfile != null
          ? LactateAndLabProfile(
              lt1Watts: (newFtp * 0.72).round(),
              lt1LactateMmolL: r.physiology.labProfile!.lt1LactateMmolL,
              lt1HeartRateBpm: r.physiology.labProfile!.lt1HeartRateBpm,
              fatMaxWatts: (newFtp * 0.68).round(),
              fatMaxOxidationRateGramsPerHour:
                  r.physiology.labProfile!.fatMaxOxidationRateGramsPerHour,
              lt2Watts: newFtp,
              lt2LactateMmolL: r.physiology.labProfile!.lt2LactateMmolL,
              lt2HeartRateBpm: r.physiology.lactateThresholdHr,
              vlaMaxMmolLPerSec: newVlaMax,
              vo2MaxMlKgMin: newVo2Max,
              powerAtVo2MaxWatts: (newFtp * 1.25).round(),
              grossEfficiencyPercent:
                  r.physiology.labProfile!.grossEfficiencyPercent,
              deltaEfficiencyPercent:
                  r.physiology.labProfile!.deltaEfficiencyPercent,
              referenceWeightKg: r.physiology.weightKg,
            )
          : null;

      final newPhysiology = r.physiology.copyWith(
        ftpWatts: newFtp,
        vo2Max: newVo2Max,
        labProfile: newLabProfile,
      );

      // Wzrost techniki i IQ
      final int iqBonus = profile.seniorMentorId != null ? 2 : 1;
      final newSkills = r.skills.copyWith(
        raceIq: (r.skills.raceIq + iqBonus).clamp(1, 99),
        descending:
            (r.skills.descending + (rng.nextDouble() < 0.4 ? 1 : 0)).clamp(1, 99),
        bikeHandling:
            (r.skills.bikeHandling + (rng.nextDouble() < 0.5 ? 1 : 0)).clamp(1, 99),
      );

      final evolvedRider = r.copyWith(
        powerProfile: newPowerProfile,
        physiology: newPhysiology,
        skills: newSkills,
      );

      // Nowy snapshot z audytu
      final snapshot = PhysiologicalAuditSnapshot(
        testDate: date,
        ftpWatts: newFtp,
        wattsPerKg: evolvedRider.physiology.wattsPerKg,
        vo2Max: newVo2Max,
        vlaMax: newVlaMax,
        maxSprintPower5s: evolvedRider.powerProfile.watts5s,
        overallRating: (newFtp / 4.1).round(),
        notes: 'Wiek $age l. Miesięczny progres: +${baseWattsGain.round()}W FTP. '
            '${profile.seniorMentorName != null ? "Wsparcie mentora: ${profile.seniorMentorName}." : "Praca z trenerem Devo."}',
      );

      return profile.copyWith(
        rider: evolvedRider,
        burnoutFatigueIndex: (profile.burnoutFatigueIndex - 8.0).clamp(0.0, 100.0),
        auditHistory: [...profile.auditHistory, snapshot],
      );
    }).toList();

    return devoTeam.copyWith(riders: evolvedProfiles);
  }

  /// Przypisuje weterana z pierwszego zespołu jako mentora młodego adepta U23.
  static DevelopmentTeamU23 assignSeniorMentor({
    required DevelopmentTeamU23 devoTeam,
    required CyclingTeam primaryTeam,
    required String devoRiderId,
    required Rider seniorMentor,
  }) {
    if (seniorMentor.skills.raceIq < 70) {
      throw ArgumentError(
          'Mentor musi posiadać wysokie doświadczenie i zmysł taktyczny (Race IQ min. 70).');
    }

    final updatedProfiles = devoTeam.riders.map((p) {
      if (p.rider.id == devoRiderId) {
        return p.copyWith(
          seniorMentorId: seniorMentor.id,
          seniorMentorName: seniorMentor.fullName,
        );
      }
      return p;
    }).toList();

    return devoTeam.copyWith(riders: updatedProfiles);
  }

  // ===========================================================================
  // 5. AWANS ŚRÓDSEZONOWY DO PIERWSZEGO SKŁADU & STAŻE (STAGIAIRE)
  // ===========================================================================

  /// Awansuje młodego kolarza z zespołu Devo do pierwszego składu (WorldTeam / ProTeam).
  /// Może nastąpić w dowolnym momencie sezonu, gdy w kadrze głównej jest wolne miejsce.
  static ({CyclingTeam updatedTeam, DevelopmentTeamU23 updatedDevo})
      promoteRiderToFirstTeam({
    required CyclingTeam primaryTeam,
    required DevelopmentTeamU23 devoTeam,
    required String devoRiderId,
    int? proAnnualSalaryEur,
  }) {
    if (primaryTeam.rosterRiderIds.length >= 30) {
      throw StateError(
          'Kadra pierwszego zespołu osiągnęła maksymalny limit 30 kolarzy UCI WorldTour. '
          'Nie można awansować zawodnika bez zwolnienia miejsca w składzie.');
    }

    final devoProfile = devoTeam.riders.firstWhere(
      (r) => r.rider.id == devoRiderId,
      orElse: () => throw ArgumentError('Nie znaleziono kolarza w zespole Devo.'),
    );

    // Minimalna pensja WorldTouru (ok. 45 000 € rocznie lub 3 750 € / miesiąc)
    final salary = proAnnualSalaryEur != null
        ? (proAnnualSalaryEur / 12).round()
        : math.max(devoProfile.monthlySalaryEur * 2, 3850);

    final promotedContract = devoProfile.rider.contract.copyWith(
      teamId: primaryTeam.id,
      role: RiderRole.neoPro,
      monthlySalaryEur: salary,
      morale: 95.0, // Euforia po awansie do elity
      leaderLoyalty: 90.0,
    );

    final updatedRider = devoProfile.rider.copyWith(contract: promotedContract);

    // Zaktualizowany zespół główny
    final updatedTeam = primaryTeam.copyWith(
      rosterRiderIds: [...primaryTeam.rosterRiderIds, updatedRider.id],
    );

    // Aktualizacja statusu w profilu Devo (jako uhonorowany absolwent)
    final updatedProfiles = devoTeam.riders.map((p) {
      if (p.rider.id == devoRiderId) {
        return p.copyWith(
          rider: updatedRider,
          status: DevoRiderStatus.promotedToWorldTeam,
        );
      }
      return p;
    }).toList();

    final updatedDevo = devoTeam.copyWith(
      riders: updatedProfiles,
      totalAlumniPromoted: devoTeam.totalAlumniPromoted + 1,
    );

    return (updatedTeam: updatedTeam, updatedDevo: updatedDevo);
  }

  /// Mianuje adepta Devo na oficjalnego Stażystę (Stagiaire) od 1 sierpnia.
  /// Umożliwia młodemu kolarzowi starty w wybranych wyścigach elity ProSeries/1.1.
  static DevelopmentTeamU23 appointStagiaire({
    required DevelopmentTeamU23 devoTeam,
    required String devoRiderId,
    DateTime? currentDate,
  }) {
    final now = currentDate ?? DateTime.now();
    if (now.month < 8) {
      throw StateError(
          'Zgodnie z przepisami UCI kontrakty stażystów (Stagiaire) mogą być zawierane '
          'dopiero od 1 sierpnia.');
    }

    final updatedProfiles = devoTeam.riders.map((p) {
      if (p.rider.id == devoRiderId) {
        return p.copyWith(
          status: DevoRiderStatus.stagiaire,
        );
      }
      return p;
    }).toList();

    return devoTeam.copyWith(riders: updatedProfiles);
  }

  /// Zsyła młodego kolarza (< 23 lata) z pierwszego zespołu z powrotem do Devo
  /// w celu odbudowy morale, pewności siebie i zbierania punktów w U23.
  static ({CyclingTeam updatedTeam, DevelopmentTeamU23 updatedDevo})
      demoteRiderToDevo({
    required CyclingTeam primaryTeam,
    required DevelopmentTeamU23 devoTeam,
    required Rider riderToDemote,
  }) {
    if (riderToDemote.birthDate.year > DateTime.now().year - 23) {
      // Spełnia wymóg U23
    } else {
      throw ArgumentError(
          'Kolarz ukończył 23 lata i nie kwalifikuje się do rywalizacji w kategorii U23.');
    }

    if (devoTeam.isRosterFull) {
      throw StateError('Brak miejsc w składzie zespołu młodzieżowego Devo.');
    }

    // Usunięcie z pierwszego składu
    final updatedRoster =
        primaryTeam.rosterRiderIds.where((id) => id != riderToDemote.id).toList();
    final updatedTeam = primaryTeam.copyWith(rosterRiderIds: updatedRoster);

    final demotedContract = riderToDemote.contract.copyWith(
      teamId: devoTeam.devoTeamName,
      role: RiderRole.domestique,
      morale: 60.0, // Tymczasowy spadek morale po zesłaniu
    );

    final updatedRider = riderToDemote.copyWith(contract: demotedContract);

    final devoProfile = DevoRiderProfile(
      rider: updatedRider,
      signedDate: DateTime.now(),
      monthlySalaryEur: updatedRider.contract.monthlySalaryEur,
      contractEndYear: updatedRider.contract.contractEndYear,
      status: DevoRiderStatus.demotedFromWorldTeam,
      raceDaysThisSeason: 0,
      burnoutFatigueIndex: 25.0,
      uciYouthPointsSeason: 0,
    );

    final updatedDevo = devoTeam.copyWith(
      riders: [...devoTeam.riders, devoProfile],
    );

    return (updatedTeam: updatedTeam, updatedDevo: updatedDevo);
  }

  // ===========================================================================
  // 6. ROZLICZENIE FINANSOWE DEVO SQUADU
  // ===========================================================================

  /// Rozlicza miesięczny budżet zespołu młodzieżowego i obciąża konto drużyny głównej.
  static ({CyclingTeam updatedTeam, DevelopmentTeamU23 updatedDevo})
      processMonthlyDevoFinances({
    required CyclingTeam primaryTeam,
    required DevelopmentTeamU23 devoTeam,
  }) {
    if (!devoTeam.isFormed) {
      return (updatedTeam: primaryTeam, updatedDevo: devoTeam);
    }

    final totalBurn = devoTeam.totalMonthlyBurnRateEur;
    final updatedCash = primaryTeam.cashBalanceEur - totalBurn;

    final updatedTeam = primaryTeam.copyWith(
      cashBalanceEur: updatedCash,
    );

    return (updatedTeam: updatedTeam, updatedDevo: devoTeam);
  }
}
