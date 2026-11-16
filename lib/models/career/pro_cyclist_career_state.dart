import '../rider/rider.dart';
import '../team/cycling_team.dart';

/// Etap rozwoju kariery pojedynczego kolarza w trybie "Zostań Legendą" (Be a Pro).
enum ProCyclistCareerTier {
  u23Continental,
  continentalPro,
  proTeam,
  worldTourDomestique,
  worldTourCoLeader,
  worldTourLeader,
  worldTourLegend;

  String toJson() => name;

  String get label {
    switch (this) {
      case ProCyclistCareerTier.u23Continental:
        return 'U23 Continental';
      case ProCyclistCareerTier.continentalPro:
        return 'Continental Elite';
      case ProCyclistCareerTier.proTeam:
        return 'UCI ProTeam';
      case ProCyclistCareerTier.worldTourDomestique:
        return 'WorldTour Domestique';
      case ProCyclistCareerTier.worldTourCoLeader:
        return 'WorldTour Co-Lider';
      case ProCyclistCareerTier.worldTourLeader:
        return 'Lider WorldTour';
      case ProCyclistCareerTier.worldTourLegend:
        return 'Legenda Kolarstwa';
    }
  }

  int get rankIndex => index;

  static ProCyclistCareerTier fromJson(String value) {
    return ProCyclistCareerTier.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ProCyclistCareerTier.u23Continental,
    );
  }
}

/// Poziom zaufania Dyrektora Sportowego wyliczany na podstawie `dsTrustScore` (0–100).
enum DsTrustTier {
  skeptical,
  probation,
  reliable,
  trusted,
  captain,
  untouchable;

  String get label {
    switch (this) {
      case DsTrustTier.skeptical:
        return 'Sceptyczny (Ławka rezerwowych)';
      case DsTrustTier.probation:
        return 'Okres próbny (Tylko bidony)';
      case DsTrustTier.reliable:
        return 'Solidny pomocnik';
      case DsTrustTier.trusted:
        return 'Zaufany kolarz (Prawo do ucieczki)';
      case DsTrustTier.captain:
        return 'Kapitan drogi / Co-Lider';
      case DsTrustTier.untouchable:
        return 'Pełne zaufanie (Wolna ręka)';
    }
  }

  static DsTrustTier fromScore(double score) {
    final clamped = score.clamp(0.0, 100.0);
    if (clamped < 20.0) return DsTrustTier.skeptical;
    if (clamped < 40.0) return DsTrustTier.probation;
    if (clamped < 60.0) return DsTrustTier.reliable;
    if (clamped < 78.0) return DsTrustTier.trusted;
    if (clamped < 92.0) return DsTrustTier.captain;
    return DsTrustTier.untouchable;
  }
}

/// Kategoria prywatnej nieruchomości kolarza.
enum ProCyclistPropertyCategory {
  apartment,
  mountainChalet,
  coastalVilla,
  taxHavenPenthouse,
  trainingBase;

  String toJson() => name;

  String get label {
    switch (this) {
      case ProCyclistPropertyCategory.apartment:
        return 'Apartament miejski';
      case ProCyclistPropertyCategory.mountainChalet:
        return 'Chalet wysokogórski';
      case ProCyclistPropertyCategory.coastalVilla:
        return 'Willa nadmorska';
      case ProCyclistPropertyCategory.taxHavenPenthouse:
        return 'Penthouse (Rezydencja podatkowa)';
      case ProCyclistPropertyCategory.trainingBase:
        return 'Prywatna baza treningowa';
    }
  }

  static ProCyclistPropertyCategory fromJson(String value) {
    return ProCyclistPropertyCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ProCyclistPropertyCategory.apartment,
    );
  }
}

/// Prywatna nieruchomość posiadana przez kolarza (np. Girona, Andora, Monako, Sierra Nevada).
class ProCyclistRealEstate {
  final String id;
  final String name;
  final String location;
  final int altitudeMeters;
  final ProCyclistPropertyCategory category;
  final int purchasePriceEur;
  final int monthlyUpkeepEur;
  final double recoveryBonusPercent;
  final double altitudeAcclimatizationBonus;
  final double taxShieldPercent;
  final DateTime purchasedDate;
  final bool isPrimaryResidence;

  const ProCyclistRealEstate({
    required this.id,
    required this.name,
    required this.location,
    required this.altitudeMeters,
    required this.category,
    required this.purchasePriceEur,
    required this.monthlyUpkeepEur,
    this.recoveryBonusPercent = 0.0,
    this.altitudeAcclimatizationBonus = 0.0,
    this.taxShieldPercent = 0.0,
    required this.purchasedDate,
    this.isPrimaryResidence = false,
  });

  ProCyclistRealEstate copyWith({
    String? id,
    String? name,
    String? location,
    int? altitudeMeters,
    ProCyclistPropertyCategory? category,
    int? purchasePriceEur,
    int? monthlyUpkeepEur,
    double? recoveryBonusPercent,
    double? altitudeAcclimatizationBonus,
    double? taxShieldPercent,
    DateTime? purchasedDate,
    bool? isPrimaryResidence,
  }) {
    return ProCyclistRealEstate(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      altitudeMeters: altitudeMeters ?? this.altitudeMeters,
      category: category ?? this.category,
      purchasePriceEur: purchasePriceEur ?? this.purchasePriceEur,
      monthlyUpkeepEur: monthlyUpkeepEur ?? this.monthlyUpkeepEur,
      recoveryBonusPercent: recoveryBonusPercent ?? this.recoveryBonusPercent,
      altitudeAcclimatizationBonus:
          altitudeAcclimatizationBonus ?? this.altitudeAcclimatizationBonus,
      taxShieldPercent: taxShieldPercent ?? this.taxShieldPercent,
      purchasedDate: purchasedDate ?? this.purchasedDate,
      isPrimaryResidence: isPrimaryResidence ?? this.isPrimaryResidence,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'altitudeMeters': altitudeMeters,
      'category': category.toJson(),
      'purchasePriceEur': purchasePriceEur,
      'monthlyUpkeepEur': monthlyUpkeepEur,
      'recoveryBonusPercent': recoveryBonusPercent,
      'altitudeAcclimatizationBonus': altitudeAcclimatizationBonus,
      'taxShieldPercent': taxShieldPercent,
      'purchasedDate': purchasedDate.toIso8601String(),
      'isPrimaryResidence': isPrimaryResidence,
    };
  }

  factory ProCyclistRealEstate.fromJson(Map<String, dynamic> json) {
    return ProCyclistRealEstate(
      id: json['id'] as String,
      name: json['name'] as String,
      location: json['location'] as String,
      altitudeMeters: (json['altitudeMeters'] as num).toInt(),
      category: ProCyclistPropertyCategory.fromJson(json['category'] as String),
      purchasePriceEur: (json['purchasePriceEur'] as num).toInt(),
      monthlyUpkeepEur: (json['monthlyUpkeepEur'] as num).toInt(),
      recoveryBonusPercent:
          (json['recoveryBonusPercent'] as num?)?.toDouble() ?? 0.0,
      altitudeAcclimatizationBonus:
          (json['altitudeAcclimatizationBonus'] as num?)?.toDouble() ?? 0.0,
      taxShieldPercent:
          (json['taxShieldPercent'] as num?)?.toDouble() ?? 0.0,
      purchasedDate: DateTime.parse(json['purchasedDate'] as String),
      isPrimaryResidence: json['isPrimaryResidence'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProCyclistRealEstate &&
        other.id == id &&
        other.isPrimaryResidence == isPrimaryResidence;
  }

  @override
  int get hashCode => Object.hash(id, isPrimaryResidence);
}

/// Kategoria prywatnego sprzętu treningowego lub wyścigowego kolarza.
enum ProCyclistEquipmentCategory {
  personalBike,
  aeroWheelset,
  powerMeter,
  recoveryTech,
  indoorTrainer,
  labDiagnostics;

  String toJson() => name;

  String get label {
    switch (this) {
      case ProCyclistEquipmentCategory.personalBike:
        return 'Rower prywatny';
      case ProCyclistEquipmentCategory.aeroWheelset:
        return 'Koła karbonowe';
      case ProCyclistEquipmentCategory.powerMeter:
        return 'Pomiar mocy';
      case ProCyclistEquipmentCategory.recoveryTech:
        return 'Sprzęt regeneracyjny';
      case ProCyclistEquipmentCategory.indoorTrainer:
        return 'Trenażer Smart';
      case ProCyclistEquipmentCategory.labDiagnostics:
        return 'Analizator mleczanu / VO2';
    }
  }

  static ProCyclistEquipmentCategory fromJson(String value) {
    return ProCyclistEquipmentCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ProCyclistEquipmentCategory.personalBike,
    );
  }
}

/// Prywatny sprzęt kupiony za własne środki przez kolarza.
class ProCyclistPrivateEquipment {
  final String id;
  final String name;
  final String brand;
  final ProCyclistEquipmentCategory category;
  final int purchasePriceEur;
  final double durabilityPercent;
  final double trainingXpBonusPercent;
  final double recoveryBonusPercent;
  final double wattSavings;
  final DateTime purchasedDate;
  final bool isEquipped;

  const ProCyclistPrivateEquipment({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.purchasePriceEur,
    this.durabilityPercent = 100.0,
    this.trainingXpBonusPercent = 0.0,
    this.recoveryBonusPercent = 0.0,
    this.wattSavings = 0.0,
    required this.purchasedDate,
    this.isEquipped = true,
  });

  ProCyclistPrivateEquipment copyWith({
    String? id,
    String? name,
    String? brand,
    ProCyclistEquipmentCategory? category,
    int? purchasePriceEur,
    double? durabilityPercent,
    double? trainingXpBonusPercent,
    double? recoveryBonusPercent,
    double? wattSavings,
    DateTime? purchasedDate,
    bool? isEquipped,
  }) {
    return ProCyclistPrivateEquipment(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      purchasePriceEur: purchasePriceEur ?? this.purchasePriceEur,
      durabilityPercent:
          (durabilityPercent ?? this.durabilityPercent).clamp(0.0, 100.0),
      trainingXpBonusPercent:
          trainingXpBonusPercent ?? this.trainingXpBonusPercent,
      recoveryBonusPercent: recoveryBonusPercent ?? this.recoveryBonusPercent,
      wattSavings: wattSavings ?? this.wattSavings,
      purchasedDate: purchasedDate ?? this.purchasedDate,
      isEquipped: isEquipped ?? this.isEquipped,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'category': category.toJson(),
      'purchasePriceEur': purchasePriceEur,
      'durabilityPercent': durabilityPercent,
      'trainingXpBonusPercent': trainingXpBonusPercent,
      'recoveryBonusPercent': recoveryBonusPercent,
      'wattSavings': wattSavings,
      'purchasedDate': purchasedDate.toIso8601String(),
      'isEquipped': isEquipped,
    };
  }

  factory ProCyclistPrivateEquipment.fromJson(Map<String, dynamic> json) {
    return ProCyclistPrivateEquipment(
      id: json['id'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String,
      category: ProCyclistEquipmentCategory.fromJson(json['category'] as String),
      purchasePriceEur: (json['purchasePriceEur'] as num).toInt(),
      durabilityPercent:
          ((json['durabilityPercent'] as num?)?.toDouble() ?? 100.0)
              .clamp(0.0, 100.0),
      trainingXpBonusPercent:
          (json['trainingXpBonusPercent'] as num?)?.toDouble() ?? 0.0,
      recoveryBonusPercent:
          (json['recoveryBonusPercent'] as num?)?.toDouble() ?? 0.0,
      wattSavings: (json['wattSavings'] as num?)?.toDouble() ?? 0.0,
      purchasedDate: DateTime.parse(json['purchasedDate'] as String),
      isEquipped: json['isEquipped'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProCyclistPrivateEquipment &&
        other.id == id &&
        other.isEquipped == isEquipped &&
        other.durabilityPercent == durabilityPercent;
  }

  @override
  int get hashCode => Object.hash(id, isEquipped, durabilityPercent);
}

/// Typ zadania zespołowego przydzielonego przez Dyrektora Sportowego na wyścig.
enum ProCyclistAssignmentType {
  fetchBottles,
  protectLeader,
  pacePeloton,
  joinBreakaway,
  leadoutSprint,
  huntKomPoints,
  winStage,
  defendJersey,
  freeRole,
  timeTrialEffort;

  String toJson() => name;

  String get label {
    switch (this) {
      case ProCyclistAssignmentType.fetchBottles:
        return 'Dowieź bidony z wozu';
      case ProCyclistAssignmentType.protectLeader:
        return 'Ochraniaj lidera drużyny';
      case ProCyclistAssignmentType.pacePeloton:
        return 'Nadawaj tempo na czele peletonu';
      case ProCyclistAssignmentType.joinBreakaway:
        return 'Zabierz się w odjazd dnia';
      case ProCyclistAssignmentType.leadoutSprint:
        return 'Rozprowadź sprintera na finisz';
      case ProCyclistAssignmentType.huntKomPoints:
        return 'Walcz o punkty górskie (KOM)';
      case ProCyclistAssignmentType.winStage:
        return 'Wygraj etap / wyścig';
      case ProCyclistAssignmentType.defendJersey:
        return 'Broń koszulki klasyfikacji';
      case ProCyclistAssignmentType.freeRole:
        return 'Wolna ręka taktyczna';
      case ProCyclistAssignmentType.timeTrialEffort:
        return 'Pojedź na maksimum w czasówce';
    }
  }

  static ProCyclistAssignmentType fromJson(String value) {
    return ProCyclistAssignmentType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ProCyclistAssignmentType.protectLeader,
    );
  }
}

/// Status realizacji bieżącego zadania wyścigowego.
enum ProCyclistAssignmentStatus {
  assigned,
  inProgress,
  completed,
  failed,
  expired;

  String toJson() => name;

  static ProCyclistAssignmentStatus fromJson(String value) {
    return ProCyclistAssignmentStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ProCyclistAssignmentStatus.assigned,
    );
  }
}

/// Aktualne zadanie zespołowe wyznaczone przez Dyrektora Sportowego na wyścig/etap.
class ProCyclistRaceAssignment {
  final String assignmentId;
  final String raceId;
  final String raceName;
  final int stageNumber;
  final ProCyclistAssignmentType type;
  final String title;
  final String description;
  final String targetMetricLabel;
  final double targetValue;
  final double currentProgress;
  final double rewardTrustDelta;
  final double penaltyTrustDelta;
  final int rewardSkillPoints;
  final int rewardXp;
  final int rewardBonusEur;
  final ProCyclistAssignmentStatus status;
  final DateTime assignedDate;
  final DateTime? completedDate;

  const ProCyclistRaceAssignment({
    required this.assignmentId,
    required this.raceId,
    required this.raceName,
    this.stageNumber = 1,
    required this.type,
    required this.title,
    required this.description,
    required this.targetMetricLabel,
    required this.targetValue,
    this.currentProgress = 0.0,
    required this.rewardTrustDelta,
    this.penaltyTrustDelta = -5.0,
    this.rewardSkillPoints = 1,
    this.rewardXp = 100,
    this.rewardBonusEur = 0,
    this.status = ProCyclistAssignmentStatus.assigned,
    required this.assignedDate,
    this.completedDate,
  });

  double get completionRatio {
    if (targetValue <= 0.0) {
      return status == ProCyclistAssignmentStatus.completed ? 1.0 : 0.0;
    }
    return (currentProgress / targetValue).clamp(0.0, 1.0);
  }

  bool get isFinished =>
      status == ProCyclistAssignmentStatus.completed ||
      status == ProCyclistAssignmentStatus.failed ||
      status == ProCyclistAssignmentStatus.expired;

  ProCyclistRaceAssignment copyWith({
    String? assignmentId,
    String? raceId,
    String? raceName,
    int? stageNumber,
    ProCyclistAssignmentType? type,
    String? title,
    String? description,
    String? targetMetricLabel,
    double? targetValue,
    double? currentProgress,
    double? rewardTrustDelta,
    double? penaltyTrustDelta,
    int? rewardSkillPoints,
    int? rewardXp,
    int? rewardBonusEur,
    ProCyclistAssignmentStatus? status,
    DateTime? assignedDate,
    DateTime? completedDate,
  }) {
    return ProCyclistRaceAssignment(
      assignmentId: assignmentId ?? this.assignmentId,
      raceId: raceId ?? this.raceId,
      raceName: raceName ?? this.raceName,
      stageNumber: stageNumber ?? this.stageNumber,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      targetMetricLabel: targetMetricLabel ?? this.targetMetricLabel,
      targetValue: targetValue ?? this.targetValue,
      currentProgress: currentProgress ?? this.currentProgress,
      rewardTrustDelta: rewardTrustDelta ?? this.rewardTrustDelta,
      penaltyTrustDelta: penaltyTrustDelta ?? this.penaltyTrustDelta,
      rewardSkillPoints: rewardSkillPoints ?? this.rewardSkillPoints,
      rewardXp: rewardXp ?? this.rewardXp,
      rewardBonusEur: rewardBonusEur ?? this.rewardBonusEur,
      status: status ?? this.status,
      assignedDate: assignedDate ?? this.assignedDate,
      completedDate: completedDate ?? this.completedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'assignmentId': assignmentId,
      'raceId': raceId,
      'raceName': raceName,
      'stageNumber': stageNumber,
      'type': type.toJson(),
      'title': title,
      'description': description,
      'targetMetricLabel': targetMetricLabel,
      'targetValue': targetValue,
      'currentProgress': currentProgress,
      'rewardTrustDelta': rewardTrustDelta,
      'penaltyTrustDelta': penaltyTrustDelta,
      'rewardSkillPoints': rewardSkillPoints,
      'rewardXp': rewardXp,
      'rewardBonusEur': rewardBonusEur,
      'status': status.toJson(),
      'assignedDate': assignedDate.toIso8601String(),
      'completedDate': completedDate?.toIso8601String(),
    };
  }

  factory ProCyclistRaceAssignment.fromJson(Map<String, dynamic> json) {
    return ProCyclistRaceAssignment(
      assignmentId: json['assignmentId'] as String,
      raceId: json['raceId'] as String,
      raceName: json['raceName'] as String,
      stageNumber: (json['stageNumber'] as num?)?.toInt() ?? 1,
      type: ProCyclistAssignmentType.fromJson(json['type'] as String),
      title: json['title'] as String,
      description: json['description'] as String,
      targetMetricLabel: json['targetMetricLabel'] as String,
      targetValue: (json['targetValue'] as num).toDouble(),
      currentProgress: (json['currentProgress'] as num?)?.toDouble() ?? 0.0,
      rewardTrustDelta: (json['rewardTrustDelta'] as num).toDouble(),
      penaltyTrustDelta:
          (json['penaltyTrustDelta'] as num?)?.toDouble() ?? -5.0,
      rewardSkillPoints: (json['rewardSkillPoints'] as num?)?.toInt() ?? 1,
      rewardXp: (json['rewardXp'] as num?)?.toInt() ?? 100,
      rewardBonusEur: (json['rewardBonusEur'] as num?)?.toInt() ?? 0,
      status: ProCyclistAssignmentStatus.fromJson(json['status'] as String),
      assignedDate: DateTime.parse(json['assignedDate'] as String),
      completedDate: json['completedDate'] != null
          ? DateTime.parse(json['completedDate'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProCyclistRaceAssignment &&
        other.assignmentId == assignmentId &&
        other.status == status &&
        other.currentProgress == currentProgress;
  }

  @override
  int get hashCode => Object.hash(assignmentId, status, currentProgress);
}

/// Kategoria wpisu w dzienniku osiągnięć i historii kariery kolarza.
enum ProCyclistJournalCategory {
  debut,
  victory,
  podium,
  jersey,
  contract,
  trustMilestone,
  lifestyle,
  injury,
  trainingBreakthrough,
  nationalTeam;

  String toJson() => name;

  String get label {
    switch (this) {
      case ProCyclistJournalCategory.debut:
        return 'Debiut';
      case ProCyclistJournalCategory.victory:
        return 'Zwycięstwo';
      case ProCyclistJournalCategory.podium:
        return 'Podium';
      case ProCyclistJournalCategory.jersey:
        return 'Koszulka';
      case ProCyclistJournalCategory.contract:
        return 'Kontrakt';
      case ProCyclistJournalCategory.trustMilestone:
        return 'Zaufanie DS';
      case ProCyclistJournalCategory.lifestyle:
        return 'Styl życia';
      case ProCyclistJournalCategory.injury:
        return 'Kontuzja';
      case ProCyclistJournalCategory.trainingBreakthrough:
        return 'Przełom formy';
      case ProCyclistJournalCategory.nationalTeam:
        return 'Reprezentacja';
    }
  }

  static ProCyclistJournalCategory fromJson(String value) {
    return ProCyclistJournalCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ProCyclistJournalCategory.debut,
    );
  }
}

/// Pojedynczy wpis w dzienniku osiągnięć kolarza.
class ProCyclistJournalEntry {
  final String entryId;
  final DateTime date;
  final int seasonYear;
  final ProCyclistJournalCategory category;
  final String title;
  final String description;
  final String? raceName;
  final double trustDelta;
  final int xpDelta;
  final int eurDelta;
  final bool isKeyMilestone;

  const ProCyclistJournalEntry({
    required this.entryId,
    required this.date,
    required this.seasonYear,
    required this.category,
    required this.title,
    required this.description,
    this.raceName,
    this.trustDelta = 0.0,
    this.xpDelta = 0,
    this.eurDelta = 0,
    this.isKeyMilestone = false,
  });

  ProCyclistJournalEntry copyWith({
    String? entryId,
    DateTime? date,
    int? seasonYear,
    ProCyclistJournalCategory? category,
    String? title,
    String? description,
    String? raceName,
    double? trustDelta,
    int? xpDelta,
    int? eurDelta,
    bool? isKeyMilestone,
  }) {
    return ProCyclistJournalEntry(
      entryId: entryId ?? this.entryId,
      date: date ?? this.date,
      seasonYear: seasonYear ?? this.seasonYear,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      raceName: raceName ?? this.raceName,
      trustDelta: trustDelta ?? this.trustDelta,
      xpDelta: xpDelta ?? this.xpDelta,
      eurDelta: eurDelta ?? this.eurDelta,
      isKeyMilestone: isKeyMilestone ?? this.isKeyMilestone,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'entryId': entryId,
      'date': date.toIso8601String(),
      'seasonYear': seasonYear,
      'category': category.toJson(),
      'title': title,
      'description': description,
      'raceName': raceName,
      'trustDelta': trustDelta,
      'xpDelta': xpDelta,
      'eurDelta': eurDelta,
      'isKeyMilestone': isKeyMilestone,
    };
  }

  factory ProCyclistJournalEntry.fromJson(Map<String, dynamic> json) {
    return ProCyclistJournalEntry(
      entryId: json['entryId'] as String,
      date: DateTime.parse(json['date'] as String),
      seasonYear: (json['seasonYear'] as num).toInt(),
      category: ProCyclistJournalCategory.fromJson(json['category'] as String),
      title: json['title'] as String,
      description: json['description'] as String,
      raceName: json['raceName'] as String?,
      trustDelta: (json['trustDelta'] as num?)?.toDouble() ?? 0.0,
      xpDelta: (json['xpDelta'] as num?)?.toInt() ?? 0,
      eurDelta: (json['eurDelta'] as num?)?.toInt() ?? 0,
      isKeyMilestone: json['isKeyMilestone'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProCyclistJournalEntry && other.entryId == entryId;
  }

  @override
  int get hashCode => entryId.hashCode;
}

/// Zbiorcze statystyki palmares kolarza w trybie kariery indywidualnej.
class ProCyclistPalmares {
  final int raceDays;
  final int careerWins;
  final int careerPodiums;
  final int stageWins;
  final int u23Wins;
  final int monumentStarts;
  final int monumentWins;
  final int grandTourStarts;
  final int grandTourStageWins;
  final int grandTourPodiums;
  final int leaderJerseyDays;
  final int komJerseyWins;
  final int pointsJerseyWins;
  final int youthJerseyWins;
  final int worldChampMedals;

  const ProCyclistPalmares({
    this.raceDays = 0,
    this.careerWins = 0,
    this.careerPodiums = 0,
    this.stageWins = 0,
    this.u23Wins = 0,
    this.monumentStarts = 0,
    this.monumentWins = 0,
    this.grandTourStarts = 0,
    this.grandTourStageWins = 0,
    this.grandTourPodiums = 0,
    this.leaderJerseyDays = 0,
    this.komJerseyWins = 0,
    this.pointsJerseyWins = 0,
    this.youthJerseyWins = 0,
    this.worldChampMedals = 0,
  });

  ProCyclistPalmares copyWith({
    int? raceDays,
    int? careerWins,
    int? careerPodiums,
    int? stageWins,
    int? u23Wins,
    int? monumentStarts,
    int? monumentWins,
    int? grandTourStarts,
    int? grandTourStageWins,
    int? grandTourPodiums,
    int? leaderJerseyDays,
    int? komJerseyWins,
    int? pointsJerseyWins,
    int? youthJerseyWins,
    int? worldChampMedals,
  }) {
    return ProCyclistPalmares(
      raceDays: raceDays ?? this.raceDays,
      careerWins: careerWins ?? this.careerWins,
      careerPodiums: careerPodiums ?? this.careerPodiums,
      stageWins: stageWins ?? this.stageWins,
      u23Wins: u23Wins ?? this.u23Wins,
      monumentStarts: monumentStarts ?? this.monumentStarts,
      monumentWins: monumentWins ?? this.monumentWins,
      grandTourStarts: grandTourStarts ?? this.grandTourStarts,
      grandTourStageWins: grandTourStageWins ?? this.grandTourStageWins,
      grandTourPodiums: grandTourPodiums ?? this.grandTourPodiums,
      leaderJerseyDays: leaderJerseyDays ?? this.leaderJerseyDays,
      komJerseyWins: komJerseyWins ?? this.komJerseyWins,
      pointsJerseyWins: pointsJerseyWins ?? this.pointsJerseyWins,
      youthJerseyWins: youthJerseyWins ?? this.youthJerseyWins,
      worldChampMedals: worldChampMedals ?? this.worldChampMedals,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'raceDays': raceDays,
      'careerWins': careerWins,
      'careerPodiums': careerPodiums,
      'stageWins': stageWins,
      'u23Wins': u23Wins,
      'monumentStarts': monumentStarts,
      'monumentWins': monumentWins,
      'grandTourStarts': grandTourStarts,
      'grandTourStageWins': grandTourStageWins,
      'grandTourPodiums': grandTourPodiums,
      'leaderJerseyDays': leaderJerseyDays,
      'komJerseyWins': komJerseyWins,
      'pointsJerseyWins': pointsJerseyWins,
      'youthJerseyWins': youthJerseyWins,
      'worldChampMedals': worldChampMedals,
    };
  }

  factory ProCyclistPalmares.fromJson(Map<String, dynamic> json) {
    return ProCyclistPalmares(
      raceDays: (json['raceDays'] as num?)?.toInt() ?? 0,
      careerWins: (json['careerWins'] as num?)?.toInt() ?? 0,
      careerPodiums: (json['careerPodiums'] as num?)?.toInt() ?? 0,
      stageWins: (json['stageWins'] as num?)?.toInt() ?? 0,
      u23Wins: (json['u23Wins'] as num?)?.toInt() ?? 0,
      monumentStarts: (json['monumentStarts'] as num?)?.toInt() ?? 0,
      monumentWins: (json['monumentWins'] as num?)?.toInt() ?? 0,
      grandTourStarts: (json['grandTourStarts'] as num?)?.toInt() ?? 0,
      grandTourStageWins: (json['grandTourStageWins'] as num?)?.toInt() ?? 0,
      grandTourPodiums: (json['grandTourPodiums'] as num?)?.toInt() ?? 0,
      leaderJerseyDays: (json['leaderJerseyDays'] as num?)?.toInt() ?? 0,
      komJerseyWins: (json['komJerseyWins'] as num?)?.toInt() ?? 0,
      pointsJerseyWins: (json['pointsJerseyWins'] as num?)?.toInt() ?? 0,
      youthJerseyWins: (json['youthJerseyWins'] as num?)?.toInt() ?? 0,
      worldChampMedals: (json['worldChampMedals'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProCyclistPalmares &&
        other.raceDays == raceDays &&
        other.careerWins == careerWins &&
        other.careerPodiums == careerPodiums &&
        other.stageWins == stageWins &&
        other.u23Wins == u23Wins &&
        other.monumentWins == monumentWins &&
        other.grandTourStageWins == grandTourStageWins;
  }

  @override
  int get hashCode => Object.hash(
        raceDays,
        careerWins,
        careerPodiums,
        stageWins,
        u23Wins,
        monumentWins,
        grandTourStageWins,
      );
}

/// Osobisty kontrakt reklamowy kolarza (okulary, zegarek, odżywki, kask).
class ProCyclistPersonalSponsor {
  final String sponsorId;
  final String brandName;
  final String categoryLabel;
  final int monthlyRetainerEur;
  final int winBonusEur;
  final double minFameRequired;
  final int contractEndYear;

  const ProCyclistPersonalSponsor({
    required this.sponsorId,
    required this.brandName,
    required this.categoryLabel,
    required this.monthlyRetainerEur,
    required this.winBonusEur,
    this.minFameRequired = 10.0,
    required this.contractEndYear,
  });

  ProCyclistPersonalSponsor copyWith({
    String? sponsorId,
    String? brandName,
    String? categoryLabel,
    int? monthlyRetainerEur,
    int? winBonusEur,
    double? minFameRequired,
    int? contractEndYear,
  }) {
    return ProCyclistPersonalSponsor(
      sponsorId: sponsorId ?? this.sponsorId,
      brandName: brandName ?? this.brandName,
      categoryLabel: categoryLabel ?? this.categoryLabel,
      monthlyRetainerEur: monthlyRetainerEur ?? this.monthlyRetainerEur,
      winBonusEur: winBonusEur ?? this.winBonusEur,
      minFameRequired: minFameRequired ?? this.minFameRequired,
      contractEndYear: contractEndYear ?? this.contractEndYear,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sponsorId': sponsorId,
      'brandName': brandName,
      'categoryLabel': categoryLabel,
      'monthlyRetainerEur': monthlyRetainerEur,
      'winBonusEur': winBonusEur,
      'minFameRequired': minFameRequired,
      'contractEndYear': contractEndYear,
    };
  }

  factory ProCyclistPersonalSponsor.fromJson(Map<String, dynamic> json) {
    return ProCyclistPersonalSponsor(
      sponsorId: json['sponsorId'] as String,
      brandName: json['brandName'] as String,
      categoryLabel: json['categoryLabel'] as String,
      monthlyRetainerEur: (json['monthlyRetainerEur'] as num).toInt(),
      winBonusEur: (json['winBonusEur'] as num).toInt(),
      minFameRequired: (json['minFameRequired'] as num?)?.toDouble() ?? 10.0,
      contractEndYear: (json['contractEndYear'] as num).toInt(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProCyclistPersonalSponsor &&
        other.sponsorId == sponsorId &&
        other.contractEndYear == contractEndYear;
  }

  @override
  int get hashCode => Object.hash(sponsorId, contractEndYear);
}

/// Kompletny model stanu kariery pojedynczego kolarza w trybie "Zostań Legendą" (Be a Pro).
class ProCyclistCareerState {
  final String careerId;
  final String careerName;
  final Rider playerRider;
  final DateTime currentDate;
  final DateTime careerStartDate;
  final int seasonYear;
  final String currentTeamId;
  final String currentTeamName;
  final TeamDivision currentDivision;
  final ProCyclistCareerTier careerTier;

  /// Poziom zaufania Dyrektora Sportowego w skali 0.0 – 100.0.
  final double dsTrustScore;

  /// Dostępne punkty rozwoju atrybutów i umiejętności kolarza.
  final int skillPoints;
  final int experienceXp;
  final int careerLevel;
  final int totalSkillPointsEarned;
  final int totalSkillPointsSpent;

  /// Stan konta prywatnego kolarza w EUR oraz statystyki finansowe.
  final int privateBalanceEur;
  final int careerEarningsEur;
  final int monthlyLivingExpensesEur;

  /// Rozpoznawalność medialna (0–100) i liczba obserwujących kibiców.
  final double fameScore;
  final int fanFollowersCount;

  /// Posiadane nieruchomości oraz prywatny sprzęt treningowy/wyścigowy.
  final List<ProCyclistRealEstate> ownedProperties;
  final List<ProCyclistPrivateEquipment> ownedPrivateEquipment;
  final List<ProCyclistPersonalSponsor> activePersonalSponsors;

  /// Aktualne zadanie zespołowe wyznaczone na wyścig / etap.
  final ProCyclistRaceAssignment? currentRaceAssignment;
  final int completedAssignmentsCount;
  final int failedAssignmentsCount;

  /// Dziennik osiągnięć i kamieni milowych kariery.
  final List<ProCyclistJournalEntry> achievementJournal;
  final ProCyclistPalmares palmares;

  final bool isRetired;
  final String? retirementReason;

  const ProCyclistCareerState({
    required this.careerId,
    required this.careerName,
    required this.playerRider,
    required this.currentDate,
    required this.careerStartDate,
    required this.seasonYear,
    required this.currentTeamId,
    required this.currentTeamName,
    required this.currentDivision,
    required this.careerTier,
    required this.dsTrustScore,
    required this.skillPoints,
    this.experienceXp = 0,
    this.careerLevel = 1,
    this.totalSkillPointsEarned = 0,
    this.totalSkillPointsSpent = 0,
    required this.privateBalanceEur,
    this.careerEarningsEur = 0,
    this.monthlyLivingExpensesEur = 1200,
    this.fameScore = 5.0,
    this.fanFollowersCount = 250,
    this.ownedProperties = const [],
    this.ownedPrivateEquipment = const [],
    this.activePersonalSponsors = const [],
    this.currentRaceAssignment,
    this.completedAssignmentsCount = 0,
    this.failedAssignmentsCount = 0,
    this.achievementJournal = const [],
    this.palmares = const ProCyclistPalmares(),
    this.isRetired = false,
    this.retirementReason,
  });

  /// Tworzy początkowy stan kariery 18-letniego kolarza w dywizji U23 Continental.
  factory ProCyclistCareerState.createNew({
    required String careerId,
    required String careerName,
    required Rider playerRider,
    required DateTime startDate,
    String currentTeamId = 'u23_dev_team',
    String currentTeamName = 'Continental U23 Development',
    TeamDivision currentDivision = TeamDivision.continental,
    double initialDsTrustScore = 35.0,
    int initialSkillPoints = 5,
    int initialPrivateBalanceEur = 2500,
  }) {
    final normalizedTrust = initialDsTrustScore.clamp(0.0, 100.0);
    final normalizedSp = initialSkillPoints < 0 ? 0 : initialSkillPoints;

    return ProCyclistCareerState(
      careerId: careerId,
      careerName: careerName,
      playerRider: playerRider,
      currentDate: startDate,
      careerStartDate: startDate,
      seasonYear: startDate.year,
      currentTeamId: currentTeamId,
      currentTeamName: currentTeamName,
      currentDivision: currentDivision,
      careerTier: ProCyclistCareerTier.u23Continental,
      dsTrustScore: normalizedTrust,
      skillPoints: normalizedSp,
      experienceXp: 0,
      careerLevel: 1,
      totalSkillPointsEarned: normalizedSp,
      totalSkillPointsSpent: 0,
      privateBalanceEur: initialPrivateBalanceEur,
      careerEarningsEur: initialPrivateBalanceEur,
      monthlyLivingExpensesEur: 950,
      fameScore: 4.0,
      fanFollowersCount: 180,
      achievementJournal: [
        ProCyclistJournalEntry(
          entryId: 'debut_${careerId}_${startDate.year}',
          date: startDate,
          seasonYear: startDate.year,
          category: ProCyclistJournalCategory.debut,
          title: 'Podpisanie pierwszego kontraktu U23',
          description:
              '${playerRider.fullName} rozpoczyna zawodową drogę w barwach $currentTeamName.',
          trustDelta: 0.0,
          xpDelta: 0,
          eurDelta: initialPrivateBalanceEur,
          isKeyMilestone: true,
        ),
      ],
    );
  }

  /// Aktualna kategoria zaufania Dyrektora Sportowego.
  DsTrustTier get dsTrustTier => DsTrustTier.fromScore(dsTrustScore);

  /// Zaokrąglony poziom zaufania DS (0–100).
  int get dsTrustScoreRounded => dsTrustScore.round().clamp(0, 100);

  /// Czy kolarz ma wystarczające zaufanie DS, aby prosić o wolną rękę lub ucieczkę.
  bool get canRequestBreakawayOrFreeRole => dsTrustScore >= 60.0;

  /// Czy kolarz ma status chronionego lidera drużyny.
  bool get hasProtectedLeaderStatus => dsTrustScore >= 78.0;

  /// Wiek kolarza liczony względem aktualnej daty kariery.
  int get careerAgeYears {
    int age = currentDate.year - playerRider.birthDate.year;
    if (currentDate.month < playerRider.birthDate.month ||
        (currentDate.month == playerRider.birthDate.month &&
            currentDate.day < playerRider.birthDate.day)) {
      age--;
    }
    return age < 0 ? 0 : age;
  }

  /// Całkowity miesięczny koszt utrzymania posiadanych nieruchomości w EUR.
  int get totalMonthlyPropertyUpkeepEur => ownedProperties.fold<int>(
        0,
        (sum, item) => sum + item.monthlyUpkeepEur,
      );

  /// Całkowity miesięczny przychód ze sponsorów osobistych w EUR.
  int get totalMonthlyPersonalSponsorIncomeEur =>
      activePersonalSponsors.fold<int>(
        0,
        (sum, sponsor) => sum + sponsor.monthlyRetainerEur,
      );

  /// Miesięczny bilans prywatny (pensja + sponsorzy osob. - koszty życia i nieruchomości).
  int get projectedMonthlyNetCashflowEur =>
      playerRider.contract.monthlySalaryEur +
      totalMonthlyPersonalSponsorIncomeEur -
      monthlyLivingExpensesEur -
      totalMonthlyPropertyUpkeepEur;

  /// Suma wartości rynkowej nieruchomości, sprzętu i gotówki na koncie.
  int get totalNetWorthEur {
    final propertyValue = ownedProperties.fold<int>(
      0,
      (sum, item) => sum + item.purchasePriceEur,
    );
    final equipmentValue = ownedPrivateEquipment.fold<int>(
      0,
      (sum, item) => sum + item.purchasePriceEur,
    );
    return privateBalanceEur + propertyValue + equipmentValue;
  }

  /// Łączny bonus do nocnej regeneracji (%) z nieruchomości i aktywnego sprzętu.
  double get totalRecoveryBonusPercent {
    final propertyBonus = ownedProperties.fold<double>(
      0.0,
      (sum, item) => sum + item.recoveryBonusPercent,
    );
    final equipmentBonus = ownedPrivateEquipment
        .where((e) => e.isEquipped)
        .fold<double>(0.0, (sum, item) => sum + item.recoveryBonusPercent);
    return (propertyBonus + equipmentBonus).clamp(0.0, 45.0);
  }

  /// Łączny bonus do zdobywanego doświadczenia treningowego (%) z prywatnego sprzętu.
  double get totalTrainingXpBonusPercent {
    final equipmentBonus = ownedPrivateEquipment
        .where((e) => e.isEquipped)
        .fold<double>(0.0, (sum, item) => sum + item.trainingXpBonusPercent);
    return equipmentBonus.clamp(0.0, 50.0);
  }

  /// Łączna oszczędność aerodynamiczna/mechaniczna (W) z prywatnego sprzętu.
  double get totalPrivateEquipmentWattSavings {
    return ownedPrivateEquipment
        .where((e) => e.isEquipped)
        .fold<double>(0.0, (sum, item) => sum + item.wattSavings)
        .clamp(0.0, 25.0);
  }

  /// Liczba XP wymagana do awansu na kolejny poziom kariery.
  int get xpRequiredForNextLevel => careerLevel * 500;

  /// Postęp do kolejnego poziomu kariery (0.0 – 1.0).
  double get levelProgressRatio {
    final threshold = xpRequiredForNextLevel;
    if (threshold <= 0) return 0.0;
    return (experienceXp / threshold).clamp(0.0, 1.0);
  }

  /// Skuteczność realizacji zadań zespołowych (0.0 – 1.0).
  double get assignmentSuccessRate {
    final total = completedAssignmentsCount + failedAssignmentsCount;
    if (total == 0) return 1.0;
    return (completedAssignmentsCount / total).clamp(0.0, 1.0);
  }

  /// Zwraca kopię stanu ze zmodyfikowanym zaufaniem DS w granicach 0–100.
  ProCyclistCareerState applyDsTrustDelta(double delta) {
    final nextTrust = (dsTrustScore + delta).clamp(0.0, 100.0);
    return copyWith(dsTrustScore: nextTrust);
  }

  /// Dodaje punkty XP, automatycznie obsługując awanse poziomów i przyznawanie `skillPoints`.
  ProCyclistCareerState grantExperienceXp(int xpGain) {
    if (xpGain <= 0) return this;
    int nextXp = experienceXp + xpGain;
    int nextLevel = careerLevel;
    int bonusSkillPoints = 0;

    while (nextXp >= nextLevel * 500) {
      nextXp -= nextLevel * 500;
      nextLevel++;
      bonusSkillPoints += 2;
    }

    return copyWith(
      experienceXp: nextXp,
      careerLevel: nextLevel,
      skillPoints: skillPoints + bonusSkillPoints,
      totalSkillPointsEarned: totalSkillPointsEarned + bonusSkillPoints,
    );
  }

  /// Wydaje określoną liczbę `skillPoints` jeśli jest wystarczająca.
  ProCyclistCareerState spendSkillPoints(int points) {
    if (points <= 0 || points > skillPoints) {
      return this;
    }
    return copyWith(
      skillPoints: skillPoints - points,
      totalSkillPointsSpent: totalSkillPointsSpent + points,
    );
  }

  /// Rejestruje nowy wpis na początku dziennika osiągnięć.
  ProCyclistCareerState appendJournalEntry(ProCyclistJournalEntry entry) {
    return copyWith(
      achievementJournal: [entry, ...achievementJournal],
    );
  }

  ProCyclistCareerState copyWith({
    String? careerId,
    String? careerName,
    Rider? playerRider,
    DateTime? currentDate,
    DateTime? careerStartDate,
    int? seasonYear,
    String? currentTeamId,
    String? currentTeamName,
    TeamDivision? currentDivision,
    ProCyclistCareerTier? careerTier,
    double? dsTrustScore,
    int? skillPoints,
    int? experienceXp,
    int? careerLevel,
    int? totalSkillPointsEarned,
    int? totalSkillPointsSpent,
    int? privateBalanceEur,
    int? careerEarningsEur,
    int? monthlyLivingExpensesEur,
    double? fameScore,
    int? fanFollowersCount,
    List<ProCyclistRealEstate>? ownedProperties,
    List<ProCyclistPrivateEquipment>? ownedPrivateEquipment,
    List<ProCyclistPersonalSponsor>? activePersonalSponsors,
    ProCyclistRaceAssignment? currentRaceAssignment,
    bool clearCurrentRaceAssignment = false,
    int? completedAssignmentsCount,
    int? failedAssignmentsCount,
    List<ProCyclistJournalEntry>? achievementJournal,
    ProCyclistPalmares? palmares,
    bool? isRetired,
    String? retirementReason,
  }) {
    return ProCyclistCareerState(
      careerId: careerId ?? this.careerId,
      careerName: careerName ?? this.careerName,
      playerRider: playerRider ?? this.playerRider,
      currentDate: currentDate ?? this.currentDate,
      careerStartDate: careerStartDate ?? this.careerStartDate,
      seasonYear: seasonYear ?? this.seasonYear,
      currentTeamId: currentTeamId ?? this.currentTeamId,
      currentTeamName: currentTeamName ?? this.currentTeamName,
      currentDivision: currentDivision ?? this.currentDivision,
      careerTier: careerTier ?? this.careerTier,
      dsTrustScore: (dsTrustScore ?? this.dsTrustScore).clamp(0.0, 100.0),
      skillPoints: (skillPoints ?? this.skillPoints) < 0
          ? 0
          : (skillPoints ?? this.skillPoints),
      experienceXp: (experienceXp ?? this.experienceXp) < 0
          ? 0
          : (experienceXp ?? this.experienceXp),
      careerLevel: (careerLevel ?? this.careerLevel) < 1
          ? 1
          : (careerLevel ?? this.careerLevel),
      totalSkillPointsEarned:
          totalSkillPointsEarned ?? this.totalSkillPointsEarned,
      totalSkillPointsSpent:
          totalSkillPointsSpent ?? this.totalSkillPointsSpent,
      privateBalanceEur: privateBalanceEur ?? this.privateBalanceEur,
      careerEarningsEur: careerEarningsEur ?? this.careerEarningsEur,
      monthlyLivingExpensesEur:
          monthlyLivingExpensesEur ?? this.monthlyLivingExpensesEur,
      fameScore: (fameScore ?? this.fameScore).clamp(0.0, 100.0),
      fanFollowersCount: (fanFollowersCount ?? this.fanFollowersCount) < 0
          ? 0
          : (fanFollowersCount ?? this.fanFollowersCount),
      ownedProperties: ownedProperties ?? this.ownedProperties,
      ownedPrivateEquipment:
          ownedPrivateEquipment ?? this.ownedPrivateEquipment,
      activePersonalSponsors:
          activePersonalSponsors ?? this.activePersonalSponsors,
      currentRaceAssignment: clearCurrentRaceAssignment
          ? null
          : (currentRaceAssignment ?? this.currentRaceAssignment),
      completedAssignmentsCount:
          completedAssignmentsCount ?? this.completedAssignmentsCount,
      failedAssignmentsCount:
          failedAssignmentsCount ?? this.failedAssignmentsCount,
      achievementJournal: achievementJournal ?? this.achievementJournal,
      palmares: palmares ?? this.palmares,
      isRetired: isRetired ?? this.isRetired,
      retirementReason: retirementReason ?? this.retirementReason,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'careerId': careerId,
      'careerName': careerName,
      'playerRider': playerRider.toJson(),
      'currentDate': currentDate.toIso8601String(),
      'careerStartDate': careerStartDate.toIso8601String(),
      'seasonYear': seasonYear,
      'currentTeamId': currentTeamId,
      'currentTeamName': currentTeamName,
      'currentDivision': currentDivision.toJson(),
      'careerTier': careerTier.toJson(),
      'dsTrustScore': dsTrustScore,
      'skillPoints': skillPoints,
      'experienceXp': experienceXp,
      'careerLevel': careerLevel,
      'totalSkillPointsEarned': totalSkillPointsEarned,
      'totalSkillPointsSpent': totalSkillPointsSpent,
      'privateBalanceEur': privateBalanceEur,
      'careerEarningsEur': careerEarningsEur,
      'monthlyLivingExpensesEur': monthlyLivingExpensesEur,
      'fameScore': fameScore,
      'fanFollowersCount': fanFollowersCount,
      'ownedProperties': ownedProperties.map((e) => e.toJson()).toList(),
      'ownedPrivateEquipment':
          ownedPrivateEquipment.map((e) => e.toJson()).toList(),
      'activePersonalSponsors':
          activePersonalSponsors.map((e) => e.toJson()).toList(),
      'currentRaceAssignment': currentRaceAssignment?.toJson(),
      'completedAssignmentsCount': completedAssignmentsCount,
      'failedAssignmentsCount': failedAssignmentsCount,
      'achievementJournal': achievementJournal.map((e) => e.toJson()).toList(),
      'palmares': palmares.toJson(),
      'isRetired': isRetired,
      'retirementReason': retirementReason,
    };
  }

  factory ProCyclistCareerState.fromJson(Map<String, dynamic> json) {
    return ProCyclistCareerState(
      careerId: json['careerId'] as String,
      careerName: json['careerName'] as String,
      playerRider:
          Rider.fromJson(json['playerRider'] as Map<String, dynamic>),
      currentDate: DateTime.parse(json['currentDate'] as String),
      careerStartDate: DateTime.parse(json['careerStartDate'] as String),
      seasonYear: (json['seasonYear'] as num).toInt(),
      currentTeamId: json['currentTeamId'] as String,
      currentTeamName: json['currentTeamName'] as String,
      currentDivision:
          TeamDivision.fromJson(json['currentDivision'] as String),
      careerTier: ProCyclistCareerTier.fromJson(json['careerTier'] as String),
      dsTrustScore:
          ((json['dsTrustScore'] as num).toDouble()).clamp(0.0, 100.0),
      skillPoints: (json['skillPoints'] as num).toInt(),
      experienceXp: (json['experienceXp'] as num?)?.toInt() ?? 0,
      careerLevel: (json['careerLevel'] as num?)?.toInt() ?? 1,
      totalSkillPointsEarned:
          (json['totalSkillPointsEarned'] as num?)?.toInt() ?? 0,
      totalSkillPointsSpent:
          (json['totalSkillPointsSpent'] as num?)?.toInt() ?? 0,
      privateBalanceEur: (json['privateBalanceEur'] as num).toInt(),
      careerEarningsEur: (json['careerEarningsEur'] as num?)?.toInt() ?? 0,
      monthlyLivingExpensesEur:
          (json['monthlyLivingExpensesEur'] as num?)?.toInt() ?? 1200,
      fameScore: ((json['fameScore'] as num?)?.toDouble() ?? 5.0)
          .clamp(0.0, 100.0),
      fanFollowersCount: (json['fanFollowersCount'] as num?)?.toInt() ?? 250,
      ownedProperties: (json['ownedProperties'] as List<dynamic>?)
              ?.map((e) =>
                  ProCyclistRealEstate.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      ownedPrivateEquipment: (json['ownedPrivateEquipment'] as List<dynamic>?)
              ?.map((e) => ProCyclistPrivateEquipment.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          const [],
      activePersonalSponsors:
          (json['activePersonalSponsors'] as List<dynamic>?)
                  ?.map((e) => ProCyclistPersonalSponsor.fromJson(
                      e as Map<String, dynamic>))
                  .toList() ??
              const [],
      currentRaceAssignment: json['currentRaceAssignment'] != null
          ? ProCyclistRaceAssignment.fromJson(
              json['currentRaceAssignment'] as Map<String, dynamic>,
            )
          : null,
      completedAssignmentsCount:
          (json['completedAssignmentsCount'] as num?)?.toInt() ?? 0,
      failedAssignmentsCount:
          (json['failedAssignmentsCount'] as num?)?.toInt() ?? 0,
      achievementJournal: (json['achievementJournal'] as List<dynamic>?)
              ?.map((e) =>
                  ProCyclistJournalEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      palmares: json['palmares'] != null
          ? ProCyclistPalmares.fromJson(
              json['palmares'] as Map<String, dynamic>,
            )
          : const ProCyclistPalmares(),
      isRetired: json['isRetired'] as bool? ?? false,
      retirementReason: json['retirementReason'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProCyclistCareerState &&
        other.careerId == careerId &&
        other.playerRider == playerRider &&
        other.currentDate == currentDate &&
        other.dsTrustScore == dsTrustScore &&
        other.skillPoints == skillPoints &&
        other.privateBalanceEur == privateBalanceEur &&
        other.careerTier == careerTier &&
        other.currentRaceAssignment == currentRaceAssignment;
  }

  @override
  int get hashCode => Object.hash(
        careerId,
        playerRider,
        currentDate,
        dsTrustScore,
        skillPoints,
        privateBalanceEur,
        careerTier,
        currentRaceAssignment,
      );

  @override
  String toString() {
    return 'ProCyclistCareerState(${playerRider.fullName}, ${careerTier.label}, '
        'DS Trust: ${dsTrustScore.toStringAsFixed(1)}, SP: $skillPoints, '
        'EUR: $privateBalanceEur)';
  }
}
