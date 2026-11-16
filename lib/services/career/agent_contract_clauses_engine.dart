import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/career/staff_member.dart';
import '../../models/equipment/complete_bike.dart';
import '../../models/rider/rider.dart';
import '../../models/rider/rider_contract.dart';
import '../../models/team/cycling_team.dart';

/// Typy specjalnych klauzul kontraktowych negocjowanych przez agentów kolarzy.
enum AgentContractClauseType {
  guaranteedGrandTourLeadership,
  equipmentVeto,
  personalSoigneurOrCoach,
  relegationFreeRelease;

  String toJson() => name;

  static AgentContractClauseType fromJson(String value) {
    return AgentContractClauseType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => AgentContractClauseType.guaranteedGrandTourLeadership,
    );
  }

  String get title {
    switch (this) {
      case AgentContractClauseType.guaranteedGrandTourLeadership:
        return 'Guaranteed Grand Tour Leadership';
      case AgentContractClauseType.equipmentVeto:
        return 'Equipment Veto';
      case AgentContractClauseType.personalSoigneurOrCoach:
        return 'Personal Soigneur/Coach';
      case AgentContractClauseType.relegationFreeRelease:
        return 'Relegation Free Release';
    }
  }

  String get subtitlePl {
    switch (this) {
      case AgentContractClauseType.guaranteedGrandTourLeadership:
        return 'Gwarancja pozycji lidera na wybrany Wielki Tour';
      case AgentContractClauseType.equipmentVeto:
        return 'Wymóg topowych kół i ramy klasy WorldTour Pro';
      case AgentContractClauseType.personalSoigneurOrCoach:
        return 'Wymóg zatrudnienia ulubionego trenera lub soigneura';
      case AgentContractClauseType.relegationFreeRelease:
        return 'Darmowe odejście w razie spadku drużyny z WorldTouru';
    }
  }

  String get shortBadge {
    switch (this) {
      case AgentContractClauseType.guaranteedGrandTourLeadership:
        return 'GT LIDER';
      case AgentContractClauseType.equipmentVeto:
        return 'SPRZĘT VETO';
      case AgentContractClauseType.personalSoigneurOrCoach:
        return 'TRENER VIP';
      case AgentContractClauseType.relegationFreeRelease:
        return 'SPADEK 0€';
    }
  }

  IconData get icon {
    switch (this) {
      case AgentContractClauseType.guaranteedGrandTourLeadership:
        return Icons.emoji_events_rounded;
      case AgentContractClauseType.equipmentVeto:
        return Icons.pedal_bike_rounded;
      case AgentContractClauseType.personalSoigneurOrCoach:
        return Icons.sports_rounded;
      case AgentContractClauseType.relegationFreeRelease:
        return Icons.lock_open_rounded;
    }
  }

  /// Bazowa redukcja żądań płacowych (np. 0.08 = -8% pensji w zamian za klauzulę).
  double get defaultSalaryDiscountFactor {
    switch (this) {
      case AgentContractClauseType.guaranteedGrandTourLeadership:
        return 0.09;
      case AgentContractClauseType.equipmentVeto:
        return 0.05;
      case AgentContractClauseType.personalSoigneurOrCoach:
        return 0.06;
      case AgentContractClauseType.relegationFreeRelease:
        return 0.08;
    }
  }
}

/// Wybrany Wielki Tour objęty gwarancją przywództwa w kontrakcie.
enum GrandTourTarget {
  tourDeFrance,
  giroDItalia,
  vueltaAEspana;

  String toJson() => name;

  static GrandTourTarget fromJson(String value) {
    return GrandTourTarget.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => GrandTourTarget.tourDeFrance,
    );
  }

  String get displayName {
    switch (this) {
      case GrandTourTarget.tourDeFrance:
        return 'Tour de France';
      case GrandTourTarget.giroDItalia:
        return "Giro d'Italia";
      case GrandTourTarget.vueltaAEspana:
        return 'Vuelta a España';
    }
  }

  String get shortCode {
    switch (this) {
      case GrandTourTarget.tourDeFrance:
        return 'TDF';
      case GrandTourTarget.giroDItalia:
        return 'GIRO';
      case GrandTourTarget.vueltaAEspana:
        return 'VUELTA';
    }
  }
}

/// Wynikowy status zgodności pojedynczej klauzuli specjalnej.
enum ClauseComplianceStatus {
  compliant,
  warning,
  breached,
  triggered,
  notApplicable;

  String get labelPl {
    switch (this) {
      case ClauseComplianceStatus.compliant:
        return 'SPEŁNIONA';
      case ClauseComplianceStatus.warning:
        return 'UWAGA';
      case ClauseComplianceStatus.breached:
        return 'NARUSZONA';
      case ClauseComplianceStatus.triggered:
        return 'AKTYWOWANA';
      case ClauseComplianceStatus.notApplicable:
        return 'NIEAKTYWNA';
    }
  }

  Color get statusColor {
    switch (this) {
      case ClauseComplianceStatus.compliant:
        return AppColors.statusSuccess;
      case ClauseComplianceStatus.warning:
        return AppColors.amberWarning;
      case ClauseComplianceStatus.breached:
        return AppColors.crimsonAlert;
      case ClauseComplianceStatus.triggered:
        return AppColors.goldAccent;
      case ClauseComplianceStatus.notApplicable:
        return AppColors.textSecondary;
    }
  }
}

/// Pojedyncza klauzula specjalna w kontrakcie kolarza.
class AgentContractClause {
  final String id;
  final AgentContractClauseType type;
  final bool isActive;
  final GrandTourTarget? targetGrandTour;
  final double? minimumFrameStiffnessIndex;
  final int? maximumFrameWeightGrams;
  final int? maximumWheelsetWeightGrams;
  final int? minimumEquipmentTierPriceEur;
  final String? preferredCoachId;
  final String? preferredCoachName;
  final int? minimumCoachExperienceLevel;
  final int? personalCoachStipendEur;
  final double salaryDiscountFactor;
  final double moralePenaltyOnBreach;
  final double loyaltyPenaltyOnBreach;
  final String notes;

  const AgentContractClause({
    required this.id,
    required this.type,
    this.isActive = true,
    this.targetGrandTour,
    this.minimumFrameStiffnessIndex,
    this.maximumFrameWeightGrams,
    this.maximumWheelsetWeightGrams,
    this.minimumEquipmentTierPriceEur,
    this.preferredCoachId,
    this.preferredCoachName,
    this.minimumCoachExperienceLevel,
    this.personalCoachStipendEur,
    double? salaryDiscountFactor,
    this.moralePenaltyOnBreach = -18.0,
    this.loyaltyPenaltyOnBreach = -22.0,
    this.notes = '',
  }) : salaryDiscountFactor = salaryDiscountFactor ?? 0.06;

  factory AgentContractClause.guaranteedGrandTourLeadership({
    String id = 'clause_gt_leadership',
    GrandTourTarget targetGrandTour = GrandTourTarget.tourDeFrance,
    bool isActive = true,
    double salaryDiscountFactor = 0.09,
  }) {
    return AgentContractClause(
      id: id,
      type: AgentContractClauseType.guaranteedGrandTourLeadership,
      isActive: isActive,
      targetGrandTour: targetGrandTour,
      salaryDiscountFactor: salaryDiscountFactor,
      moralePenaltyOnBreach: -22.0,
      loyaltyPenaltyOnBreach: -25.0,
      notes: 'Gwarancja roli lidera GC lub głównego lidera na ${targetGrandTour.displayName}.',
    );
  }

  factory AgentContractClause.equipmentVeto({
    String id = 'clause_equipment_veto',
    bool isActive = true,
    double minimumFrameStiffnessIndex = 1.75,
    int maximumFrameWeightGrams = 850,
    int maximumWheelsetWeightGrams = 1400,
    int minimumEquipmentTierPriceEur = 10000,
    double salaryDiscountFactor = 0.05,
  }) {
    return AgentContractClause(
      id: id,
      type: AgentContractClauseType.equipmentVeto,
      isActive: isActive,
      minimumFrameStiffnessIndex: minimumFrameStiffnessIndex,
      maximumFrameWeightGrams: maximumFrameWeightGrams,
      maximumWheelsetWeightGrams: maximumWheelsetWeightGrams,
      minimumEquipmentTierPriceEur: minimumEquipmentTierPriceEur,
      salaryDiscountFactor: salaryDiscountFactor,
      moralePenaltyOnBreach: -14.0,
      loyaltyPenaltyOnBreach: -12.0,
      notes:
          'Rama <= ${maximumFrameWeightGrams}g (sztywność >= ${minimumFrameStiffnessIndex.toStringAsFixed(2)}), '
          'koła <= ${maximumWheelsetWeightGrams}g, łączna klasa >= $minimumEquipmentTierPriceEur EUR.',
    );
  }

  factory AgentContractClause.personalSoigneurOrCoach({
    String id = 'clause_personal_coach',
    bool isActive = true,
    String? preferredCoachId,
    String preferredCoachName = 'Zaufany Trener Osobisty',
    int minimumCoachExperienceLevel = 80,
    int personalCoachStipendEur = 3500,
    double salaryDiscountFactor = 0.06,
  }) {
    return AgentContractClause(
      id: id,
      type: AgentContractClauseType.personalSoigneurOrCoach,
      isActive: isActive,
      preferredCoachId: preferredCoachId,
      preferredCoachName: preferredCoachName,
      minimumCoachExperienceLevel: minimumCoachExperienceLevel,
      personalCoachStipendEur: personalCoachStipendEur,
      salaryDiscountFactor: salaryDiscountFactor,
      moralePenaltyOnBreach: -16.0,
      loyaltyPenaltyOnBreach: -18.0,
      notes: 'Wymóg zatrudnienia trenera "$preferredCoachName" lub eksperta o poziomie >= $minimumCoachExperienceLevel.',
    );
  }

  factory AgentContractClause.relegationFreeRelease({
    String id = 'clause_relegation_release',
    bool isActive = true,
    double salaryDiscountFactor = 0.08,
  }) {
    return AgentContractClause(
      id: id,
      type: AgentContractClauseType.relegationFreeRelease,
      isActive: isActive,
      salaryDiscountFactor: salaryDiscountFactor,
      moralePenaltyOnBreach: -10.0,
      loyaltyPenaltyOnBreach: -15.0,
      notes: 'W przypadku spadku drużyny z UCI WorldTour klauzula wykupu spada do 0 EUR.',
    );
  }

  AgentContractClause copyWith({
    String? id,
    AgentContractClauseType? type,
    bool? isActive,
    GrandTourTarget? targetGrandTour,
    double? minimumFrameStiffnessIndex,
    int? maximumFrameWeightGrams,
    int? maximumWheelsetWeightGrams,
    int? minimumEquipmentTierPriceEur,
    String? preferredCoachId,
    String? preferredCoachName,
    int? minimumCoachExperienceLevel,
    int? personalCoachStipendEur,
    double? salaryDiscountFactor,
    double? moralePenaltyOnBreach,
    double? loyaltyPenaltyOnBreach,
    String? notes,
  }) {
    return AgentContractClause(
      id: id ?? this.id,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
      targetGrandTour: targetGrandTour ?? this.targetGrandTour,
      minimumFrameStiffnessIndex: minimumFrameStiffnessIndex ?? this.minimumFrameStiffnessIndex,
      maximumFrameWeightGrams: maximumFrameWeightGrams ?? this.maximumFrameWeightGrams,
      maximumWheelsetWeightGrams: maximumWheelsetWeightGrams ?? this.maximumWheelsetWeightGrams,
      minimumEquipmentTierPriceEur: minimumEquipmentTierPriceEur ?? this.minimumEquipmentTierPriceEur,
      preferredCoachId: preferredCoachId ?? this.preferredCoachId,
      preferredCoachName: preferredCoachName ?? this.preferredCoachName,
      minimumCoachExperienceLevel: minimumCoachExperienceLevel ?? this.minimumCoachExperienceLevel,
      personalCoachStipendEur: personalCoachStipendEur ?? this.personalCoachStipendEur,
      salaryDiscountFactor: salaryDiscountFactor ?? this.salaryDiscountFactor,
      moralePenaltyOnBreach: moralePenaltyOnBreach ?? this.moralePenaltyOnBreach,
      loyaltyPenaltyOnBreach: loyaltyPenaltyOnBreach ?? this.loyaltyPenaltyOnBreach,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toJson(),
      'isActive': isActive,
      'targetGrandTour': targetGrandTour?.toJson(),
      'minimumFrameStiffnessIndex': minimumFrameStiffnessIndex,
      'maximumFrameWeightGrams': maximumFrameWeightGrams,
      'maximumWheelsetWeightGrams': maximumWheelsetWeightGrams,
      'minimumEquipmentTierPriceEur': minimumEquipmentTierPriceEur,
      'preferredCoachId': preferredCoachId,
      'preferredCoachName': preferredCoachName,
      'minimumCoachExperienceLevel': minimumCoachExperienceLevel,
      'personalCoachStipendEur': personalCoachStipendEur,
      'salaryDiscountFactor': salaryDiscountFactor,
      'moralePenaltyOnBreach': moralePenaltyOnBreach,
      'loyaltyPenaltyOnBreach': loyaltyPenaltyOnBreach,
      'notes': notes,
    };
  }

  factory AgentContractClause.fromJson(Map<String, dynamic> json) {
    return AgentContractClause(
      id: json['id'] as String? ?? 'clause_unknown',
      type: AgentContractClauseType.fromJson(json['type'] as String? ?? ''),
      isActive: json['isActive'] as bool? ?? true,
      targetGrandTour: json['targetGrandTour'] != null
          ? GrandTourTarget.fromJson(json['targetGrandTour'] as String)
          : null,
      minimumFrameStiffnessIndex: (json['minimumFrameStiffnessIndex'] as num?)?.toDouble(),
      maximumFrameWeightGrams: (json['maximumFrameWeightGrams'] as num?)?.toInt(),
      maximumWheelsetWeightGrams: (json['maximumWheelsetWeightGrams'] as num?)?.toInt(),
      minimumEquipmentTierPriceEur: (json['minimumEquipmentTierPriceEur'] as num?)?.toInt(),
      preferredCoachId: json['preferredCoachId'] as String?,
      preferredCoachName: json['preferredCoachName'] as String?,
      minimumCoachExperienceLevel: (json['minimumCoachExperienceLevel'] as num?)?.toInt(),
      personalCoachStipendEur: (json['personalCoachStipendEur'] as num?)?.toInt(),
      salaryDiscountFactor: (json['salaryDiscountFactor'] as num?)?.toDouble() ?? 0.06,
      moralePenaltyOnBreach: (json['moralePenaltyOnBreach'] as num?)?.toDouble() ?? -18.0,
      loyaltyPenaltyOnBreach: (json['loyaltyPenaltyOnBreach'] as num?)?.toDouble() ?? -22.0,
      notes: json['notes'] as String? ?? '',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AgentContractClause &&
        other.id == id &&
        other.type == type &&
        other.isActive == isActive &&
        other.targetGrandTour == targetGrandTour &&
        other.minimumFrameStiffnessIndex == minimumFrameStiffnessIndex &&
        other.maximumFrameWeightGrams == maximumFrameWeightGrams &&
        other.maximumWheelsetWeightGrams == maximumWheelsetWeightGrams &&
        other.minimumEquipmentTierPriceEur == minimumEquipmentTierPriceEur &&
        other.preferredCoachId == preferredCoachId &&
        other.preferredCoachName == preferredCoachName &&
        other.minimumCoachExperienceLevel == minimumCoachExperienceLevel &&
        other.personalCoachStipendEur == personalCoachStipendEur &&
        other.salaryDiscountFactor == salaryDiscountFactor &&
        other.moralePenaltyOnBreach == moralePenaltyOnBreach &&
        other.loyaltyPenaltyOnBreach == loyaltyPenaltyOnBreach &&
        other.notes == notes;
  }

  @override
  int get hashCode => Object.hash(
        id,
        type,
        isActive,
        targetGrandTour,
        minimumFrameStiffnessIndex,
        maximumFrameWeightGrams,
        maximumWheelsetWeightGrams,
        minimumEquipmentTierPriceEur,
        preferredCoachId,
        preferredCoachName,
        minimumCoachExperienceLevel,
        personalCoachStipendEur,
        salaryDiscountFactor,
        moralePenaltyOnBreach,
        loyaltyPenaltyOnBreach,
        notes,
      );
}

/// Pakiet klauzul specjalnych przypisany do kontraktu danego kolarza.
class RiderContractClausesBundle {
  final String riderId;
  final List<AgentContractClause> clauses;
  final double negotiationPatienceBonus;

  const RiderContractClausesBundle({
    required this.riderId,
    required this.clauses,
    this.negotiationPatienceBonus = 0.0,
  });

  List<AgentContractClause> get activeClauses =>
      clauses.where((c) => c.isActive).toList(growable: false);

  /// Łączna redukcja oczekiwań płacowych (ograniczona do maks. 28%).
  double get totalSalaryDiscountFactor {
    double sum = 0.0;
    for (final clause in activeClauses) {
      sum += clause.salaryDiscountFactor;
    }
    return sum.clamp(0.0, 0.28);
  }

  bool hasClause(AgentContractClauseType type) =>
      activeClauses.any((c) => c.type == type);

  AgentContractClause? findClause(AgentContractClauseType type) {
    for (final c in clauses) {
      if (c.type == type) return c;
    }
    return null;
  }

  RiderContractClausesBundle copyWith({
    String? riderId,
    List<AgentContractClause>? clauses,
    double? negotiationPatienceBonus,
  }) {
    return RiderContractClausesBundle(
      riderId: riderId ?? this.riderId,
      clauses: clauses != null ? List<AgentContractClause>.unmodifiable(clauses) : this.clauses,
      negotiationPatienceBonus: negotiationPatienceBonus ?? this.negotiationPatienceBonus,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'clauses': clauses.map((c) => c.toJson()).toList(),
      'negotiationPatienceBonus': negotiationPatienceBonus,
    };
  }

  factory RiderContractClausesBundle.fromJson(Map<String, dynamic> json) {
    return RiderContractClausesBundle(
      riderId: json['riderId'] as String? ?? '',
      clauses: (json['clauses'] as List<dynamic>? ?? const [])
          .map((e) => AgentContractClause.fromJson(e as Map<String, dynamic>))
          .toList(),
      negotiationPatienceBonus: (json['negotiationPatienceBonus'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Kontekst środowiska drużyny do audytu klauzul kontraktowych.
class ClauseEvaluationContext {
  final Rider rider;
  final CyclingTeam team;
  final Map<GrandTourTarget, List<String>> assignedGrandTourLeaderIds;
  final CompleteBike? assignedBike;
  final List<StaffMember> teamStaffMembers;
  final bool wasRelegatedFromWorldTour;
  final TeamDivision? previousDivision;

  const ClauseEvaluationContext({
    required this.rider,
    required this.team,
    this.assignedGrandTourLeaderIds = const {},
    this.assignedBike,
    this.teamStaffMembers = const [],
    this.wasRelegatedFromWorldTour = false,
    this.previousDivision,
  });
}

/// Wynik ewaluacji pojedynczej klauzuli.
class ClauseEvaluationResult {
  final AgentContractClause clause;
  final ClauseComplianceStatus status;
  final String headline;
  final String explanation;
  final String recommendedAction;
  final double moraleDelta;
  final double loyaltyDelta;
  final bool triggersFreeRelease;
  final bool allowsEquipmentVetoSwap;

  const ClauseEvaluationResult({
    required this.clause,
    required this.status,
    required this.headline,
    required this.explanation,
    required this.recommendedAction,
    this.moraleDelta = 0.0,
    this.loyaltyDelta = 0.0,
    this.triggersFreeRelease = false,
    this.allowsEquipmentVetoSwap = false,
  });
}

/// Pełny raport z audytu wszystkich klauzul kolarza.
class ContractClausesAuditReport {
  final String riderId;
  final String riderName;
  final List<ClauseEvaluationResult> results;
  final RiderContract updatedContract;
  final bool isFreeAgentReleaseTriggered;
  final bool hasAnyBreach;
  final bool hasEquipmentVetoBlock;
  final double totalMoraleDelta;
  final double totalLoyaltyDelta;
  final String summaryMessage;

  const ContractClausesAuditReport({
    required this.riderId,
    required this.riderName,
    required this.results,
    required this.updatedContract,
    required this.isFreeAgentReleaseTriggered,
    required this.hasAnyBreach,
    required this.hasEquipmentVetoBlock,
    required this.totalMoraleDelta,
    required this.totalLoyaltyDelta,
    required this.summaryMessage,
  });
}

/// Silnik klauzul specjalnych w kontraktach kolarzy i negocjacjach z agentami.
class AgentContractClausesEngine {
  const AgentContractClausesEngine();

  /// Generuje rekomendowany zestaw klauzul specjalnych dopasowany do profilu kolarza i dywizji.
  RiderContractClausesBundle generateRecommendedClausesForRider(
    Rider rider, {
    TeamDivision currentDivision = TeamDivision.worldTour,
    List<StaffMember> availableStaff = const [],
    int seed = 0,
  }) {
    final ovr = rider.overallRating;
    final isLeaderProfile = rider.contract.role == RiderRole.teamLeader ||
        rider.contract.role == RiderRole.coLeader ||
        ovr >= 80;

    final List<AgentContractClause> clauses = [];

    // 1. Guaranteed Grand Tour Leadership
    final prefersGrandTour = rider.specialization == RiderSpecialization.gcClimber ||
        rider.specialization == RiderSpecialization.pureClimber ||
        rider.specialization == RiderSpecialization.timeTrialist ||
        (isLeaderProfile && ovr >= 79);

    if (prefersGrandTour) {
      final gtTarget = _pickPreferredGrandTour(rider, seed);
      clauses.add(
        AgentContractClause.guaranteedGrandTourLeadership(
          id: 'gt_lead_${rider.id}',
          targetGrandTour: gtTarget,
          isActive: ovr >= 80 || rider.contract.role == RiderRole.teamLeader,
        ),
      );
    }

    // 2. Equipment Veto
    if (ovr >= 78 ||
        rider.specialization == RiderSpecialization.timeTrialist ||
        rider.specialization == RiderSpecialization.pureSprinter) {
      final isElite = ovr >= 85;
      clauses.add(
        AgentContractClause.equipmentVeto(
          id: 'equip_veto_${rider.id}',
          isActive: ovr >= 81,
          minimumFrameStiffnessIndex: isElite ? 1.90 : 1.75,
          maximumFrameWeightGrams: isElite ? 780 : 850,
          maximumWheelsetWeightGrams: isElite ? 1320 : 1400,
          minimumEquipmentTierPriceEur: isElite ? 12500 : 10000,
        ),
      );
    }

    // 3. Personal Soigneur / Coach
    PerformanceCoach? favoriteCoach;
    for (final staff in availableStaff) {
      if (staff is PerformanceCoach) {
        if (favoriteCoach == null || staff.experienceLevel > favoriteCoach.experienceLevel) {
          favoriteCoach = staff;
        }
      }
    }
    if (ovr >= 79 || rider.potential >= 85) {
      clauses.add(
        AgentContractClause.personalSoigneurOrCoach(
          id: 'personal_coach_${rider.id}',
          isActive: ovr >= 82,
          preferredCoachId: favoriteCoach?.id,
          preferredCoachName: favoriteCoach?.fullName ?? 'Osobisty Trener / Soigneur',
          minimumCoachExperienceLevel: ovr >= 85 ? 85 : 78,
          personalCoachStipendEur: ovr >= 85 ? 4800 : 3200,
        ),
      );
    }

    // 4. Relegation Free Release
    if (currentDivision == TeamDivision.worldTour && ovr >= 77) {
      clauses.add(
        AgentContractClause.relegationFreeRelease(
          id: 'relegation_free_${rider.id}',
          isActive: true,
        ),
      );
    }

    return RiderContractClausesBundle(
      riderId: rider.id,
      clauses: List<AgentContractClause>.unmodifiable(clauses),
      negotiationPatienceBonus: clauses.where((c) => c.isActive).length * 4.5,
    );
  }

  /// Oblicza nową stawkę miesięcznej pensji po uwzględnieniu aktywnych klauzul specjalnych.
  int calculateNegotiatedSalaryWithClauses({
    required int baseSalaryDemandEur,
    required List<AgentContractClause> activeClauses,
  }) {
    if (baseSalaryDemandEur <= 0) return 0;
    double discount = 0.0;
    for (final clause in activeClauses) {
      if (clause.isActive) {
        discount += clause.salaryDiscountFactor;
      }
    }
    final cappedDiscount = discount.clamp(0.0, 0.28);
    final adjusted = (baseSalaryDemandEur * (1.0 - cappedDiscount)).round();
    return math.max(2500, adjusted);
  }

  /// Przeprowadza pełny audyt wszystkich aktywnych klauzul kolarza w obecnym stanie drużyny.
  ContractClausesAuditReport evaluateClauses(
    RiderContractClausesBundle bundle,
    ClauseEvaluationContext context,
  ) {
    final activeClauses = bundle.activeClauses;
    if (activeClauses.isEmpty) {
      return ContractClausesAuditReport(
        riderId: context.rider.id,
        riderName: context.rider.fullName,
        results: const [],
        updatedContract: context.rider.contract,
        isFreeAgentReleaseTriggered: false,
        hasAnyBreach: false,
        hasEquipmentVetoBlock: false,
        totalMoraleDelta: 0.0,
        totalLoyaltyDelta: 0.0,
        summaryMessage: 'Kontrakt nie zawiera aktywnych klauzul specjalnych.',
      );
    }

    final List<ClauseEvaluationResult> results = [];
    double totalMoraleDelta = 0.0;
    double totalLoyaltyDelta = 0.0;
    bool freeReleaseTriggered = false;
    bool hasBreach = false;
    bool hasEquipBlock = false;

    for (final clause in activeClauses) {
      final result = _evaluateSingleClause(clause, context);
      results.add(result);
      totalMoraleDelta += result.moraleDelta;
      totalLoyaltyDelta += result.loyaltyDelta;
      if (result.triggersFreeRelease) {
        freeReleaseTriggered = true;
      }
      if (result.status == ClauseComplianceStatus.breached) {
        hasBreach = true;
      }
      if (result.allowsEquipmentVetoSwap) {
        hasEquipBlock = true;
      }
    }

    final updatedContract = applyAuditDeltasToContract(
      contract: context.rider.contract,
      moraleDelta: totalMoraleDelta,
      loyaltyDelta: totalLoyaltyDelta,
      triggersFreeRelease: freeReleaseTriggered,
    );

    final String summary;
    if (freeReleaseTriggered) {
      summary =
          'Spadek z UCI WorldTour aktywował klauzulę Relegation Free Release — ${context.rider.fullName} może odejść za darmo (0 EUR).';
    } else if (hasBreach) {
      final breachedCount = results.where((r) => r.status == ClauseComplianceStatus.breached).length;
      summary =
          'Naruszenie $breachedCount klauzul(i) w kontrakcie ${context.rider.fullName}: morale ${totalMoraleDelta.toStringAsFixed(0)}, lojalność ${totalLoyaltyDelta.toStringAsFixed(0)}.';
    } else if (results.any((r) => r.status == ClauseComplianceStatus.warning)) {
      summary = 'Klauzule specjalne ${context.rider.fullName} wymagają uwagi menedżera przed kluczowymi startami.';
    } else {
      summary = 'Wszystkie klauzule specjalne w kontrakcie ${context.rider.fullName} są w pełni respektowane.';
    }

    return ContractClausesAuditReport(
      riderId: context.rider.id,
      riderName: context.rider.fullName,
      results: List<ClauseEvaluationResult>.unmodifiable(results),
      updatedContract: updatedContract,
      isFreeAgentReleaseTriggered: freeReleaseTriggered,
      hasAnyBreach: hasBreach,
      hasEquipmentVetoBlock: hasEquipBlock,
      totalMoraleDelta: totalMoraleDelta,
      totalLoyaltyDelta: totalLoyaltyDelta,
      summaryMessage: summary,
    );
  }

  /// Aplikuje wyliczone zmiany morale, lojalności oraz zeruje kwotę odstępnego przy aktywacji spadkowej.
  RiderContract applyAuditDeltasToContract({
    required RiderContract contract,
    required double moraleDelta,
    required double loyaltyDelta,
    required bool triggersFreeRelease,
  }) {
    final nextMorale = (contract.morale + moraleDelta).clamp(0.0, 100.0);
    final nextLoyalty = (contract.leaderLoyalty + loyaltyDelta).clamp(0.0, 100.0);
    return contract.copyWith(
      morale: nextMorale,
      leaderLoyalty: nextLoyalty,
      releaseClauseEur: triggersFreeRelease ? 0 : contract.releaseClauseEur,
    );
  }

  ClauseEvaluationResult _evaluateSingleClause(
    AgentContractClause clause,
    ClauseEvaluationContext context,
  ) {
    switch (clause.type) {
      case AgentContractClauseType.guaranteedGrandTourLeadership:
        return _evaluateGrandTourLeadership(clause, context);
      case AgentContractClauseType.equipmentVeto:
        return _evaluateEquipmentVeto(clause, context);
      case AgentContractClauseType.personalSoigneurOrCoach:
        return _evaluatePersonalCoach(clause, context);
      case AgentContractClauseType.relegationFreeRelease:
        return _evaluateRelegationFreeRelease(clause, context);
    }
  }

  ClauseEvaluationResult _evaluateGrandTourLeadership(
    AgentContractClause clause,
    ClauseEvaluationContext context,
  ) {
    final target = clause.targetGrandTour ?? GrandTourTarget.tourDeFrance;
    final leaders = context.assignedGrandTourLeaderIds[target];

    if (leaders == null || leaders.isEmpty) {
      return ClauseEvaluationResult(
        clause: clause,
        status: ClauseComplianceStatus.warning,
        headline: 'Oczekuje na potwierdzenie lidera (${target.shortCode})',
        explanation:
            'Skład liderów na ${target.displayName} nie został jeszcze ogłoszony. Agent oczekuje oficjalnej nominacji.',
        recommendedAction: 'Wpisz ${context.rider.fullName} jako lidera na ${target.displayName} w Kalendarzu.',
      );
    }

    if (leaders.contains(context.rider.id)) {
      if (leaders.length > 2) {
        return ClauseEvaluationResult(
          clause: clause,
          status: ClauseComplianceStatus.warning,
          headline: 'Rozmyte przywództwo na ${target.shortCode}',
          explanation:
              'Zawodnik jest wśród ${leaders.length} liderów na ${target.displayName}, co agent uznaje za niejasną hierarchię.',
          recommendedAction: 'Ogranicz liczbę liderów na ${target.displayName} do maksymalnie dwóch.',
          moraleDelta: -4.0,
        );
      }
      return ClauseEvaluationResult(
        clause: clause,
        status: ClauseComplianceStatus.compliant,
        headline: 'Lider na ${target.displayName} potwierdzony',
        explanation: '${context.rider.fullName} widnieje jako główny lider drużyny na ${target.displayName}.',
        recommendedAction: 'Utrzymaj obecną hierarchię w komunikacji z zespołem.',
      );
    }

    return ClauseEvaluationResult(
      clause: clause,
      status: ClauseComplianceStatus.breached,
      headline: 'Złamana gwarancja lidera na ${target.shortCode}',
      explanation:
          'W składzie na ${target.displayName} wyznaczono innych liderów bez udziału ${context.rider.fullName}.',
      recommendedAction: 'Przywróć zawodnika na pozycję lidera ${target.displayName}, aby zatrzymać spadek morale.',
      moraleDelta: clause.moralePenaltyOnBreach,
      loyaltyDelta: clause.loyaltyPenaltyOnBreach,
    );
  }

  ClauseEvaluationResult _evaluateEquipmentVeto(
    AgentContractClause clause,
    ClauseEvaluationContext context,
  ) {
    final bike = context.assignedBike ?? _pickBestBikeFromTeam(context.team.inventoryBikes);
    if (bike == null) {
      return ClauseEvaluationResult(
        clause: clause,
        status: ClauseComplianceStatus.breached,
        headline: 'Brak zatwierdzonego roweru wyścigowego',
        explanation: 'Drużyna nie posiada w garażu kompletnego roweru spełniającego wymogi weta sprzętowego.',
        recommendedAction: 'Zakup lub skonfiguruj topową ramę i koła w Garażu R&D.',
        moraleDelta: clause.moralePenaltyOnBreach,
        loyaltyDelta: clause.loyaltyPenaltyOnBreach,
        allowsEquipmentVetoSwap: true,
      );
    }

    final maxFrameWeight = clause.maximumFrameWeightGrams ?? 850;
    final minStiffness = clause.minimumFrameStiffnessIndex ?? 1.75;
    final maxWheelWeight = clause.maximumWheelsetWeightGrams ?? 1400;
    final minCombinedPrice = clause.minimumEquipmentTierPriceEur ?? 10000;

    final int combinedPrice = bike.frame.priceEur + bike.wheelset.priceEur;
    final List<String> failedChecks = [];
    final List<String> minorWarnings = [];

    if (bike.frame.weightGrams > maxFrameWeight) {
      if (bike.frame.weightGrams <= maxFrameWeight + 45) {
        minorWarnings.add('masa ramy ${bike.frame.weightGrams}g > ${maxFrameWeight}g');
      } else {
        failedChecks.add('zbyt ciężka rama (${bike.frame.weightGrams}g vs limit ${maxFrameWeight}g)');
      }
    }

    if (bike.frame.stiffnessToWeightIndex < minStiffness) {
      if (bike.frame.stiffnessToWeightIndex >= minStiffness - 0.1) {
        minorWarnings.add('sztywność ramy ${bike.frame.stiffnessToWeightIndex.toStringAsFixed(2)} poniżej celu');
      } else {
        failedChecks.add('zbyt niska sztywność ramy (${bike.frame.stiffnessToWeightIndex.toStringAsFixed(2)})');
      }
    }

    if (bike.wheelset.weightGrams > maxWheelWeight) {
      if (bike.wheelset.weightGrams <= maxWheelWeight + 50) {
        minorWarnings.add('masa kół ${bike.wheelset.weightGrams}g > ${maxWheelWeight}g');
      } else {
        failedChecks.add('zbyt ciężkie koła (${bike.wheelset.weightGrams}g vs limit ${maxWheelWeight}g)');
      }
    }

    if (combinedPrice < minCombinedPrice) {
      if (combinedPrice >= (minCombinedPrice * 0.90).round()) {
        minorWarnings.add('klasa zestawu $combinedPrice EUR blisko progu $minCombinedPrice EUR');
      } else {
        failedChecks.add('klasa ramy i kół ($combinedPrice EUR) poniżej wymogu $minCombinedPrice EUR');
      }
    }

    if (failedChecks.isEmpty && minorWarnings.isEmpty) {
      return ClauseEvaluationResult(
        clause: clause,
        status: ClauseComplianceStatus.compliant,
        headline: 'Sprzęt zaakceptowany: ${bike.frame.name}',
        explanation:
            'Rama ${bike.frame.name} (${bike.frame.weightGrams}g) i koła ${bike.wheelset.name} (${bike.wheelset.weightGrams}g) spełniają wymogi.',
        recommendedAction: 'Brak wymaganych zmian w garażu.',
      );
    }

    if (failedChecks.isEmpty) {
      return ClauseEvaluationResult(
        clause: clause,
        status: ClauseComplianceStatus.warning,
        headline: 'Sprzęt na granicy weta (${bike.name})',
        explanation: 'Agent zgłasza zastrzeżenia: ${minorWarnings.join(', ')}.',
        recommendedAction: 'Rozważ upgrade kół lub ramy w Garażu R&D przed Wielkim Tourem.',
        moraleDelta: -3.0,
      );
    }

    return ClauseEvaluationResult(
      clause: clause,
      status: ClauseComplianceStatus.breached,
      headline: 'Weto Sprzętowe Aktywne (${bike.name})',
      explanation: 'Kolarz odmawia akceptacji obecnego zestawu: ${failedChecks.join('; ')}.',
      recommendedAction: 'Zmień kontrakt sprzętowy lub przydziel lżejszą ramę i karbonowe koła pro.',
      moraleDelta: clause.moralePenaltyOnBreach,
      loyaltyDelta: clause.loyaltyPenaltyOnBreach,
      allowsEquipmentVetoSwap: true,
    );
  }

  ClauseEvaluationResult _evaluatePersonalCoach(
    AgentContractClause clause,
    ClauseEvaluationContext context,
  ) {
    final minLevel = clause.minimumCoachExperienceLevel ?? 80;
    final preferredId = clause.preferredCoachId;
    final preferredName = clause.preferredCoachName ?? 'ulubiony trener';

    final coaches = context.teamStaffMembers.whereType<PerformanceCoach>().toList();
    if (preferredId != null && coaches.any((c) => c.id == preferredId)) {
      return ClauseEvaluationResult(
        clause: clause,
        status: ClauseComplianceStatus.compliant,
        headline: 'Ulubiony trener w sztabie: $preferredName',
        explanation: 'Wymagany trener przygotowania fizycznego pracuje z kolarzem w strukturach drużyny.',
        recommendedAction: 'Utrzymaj kontrakt trenera podczas przejścia między sezonami.',
      );
    }

    final qualifiedCoach = coaches.where((c) => c.experienceLevel >= minLevel).toList();
    if (qualifiedCoach.isNotEmpty) {
      return ClauseEvaluationResult(
        clause: clause,
        status: preferredId == null ? ClauseComplianceStatus.compliant : ClauseComplianceStatus.warning,
        headline: preferredId == null
            ? 'Trener klasy Pro spełnia wymóg (${qualifiedCoach.first.fullName})'
            : 'Brak $preferredName — zastępstwo warunkowe',
        explanation: preferredId == null
            ? 'Trener ${qualifiedCoach.first.fullName} (poziom ${qualifiedCoach.first.experienceLevel}) spełnia standard klauzuli.'
            : 'W sztabie nie ma $preferredName, ale ${qualifiedCoach.first.fullName} tymczasowo stabilizuje plan treningowy.',
        recommendedAction: preferredId == null
            ? 'Brak wymaganych działań.'
            : 'Zatrudnij $preferredName, aby wyeliminować drobny spadek zaufania.',
        moraleDelta: preferredId == null ? 0.0 : -4.0,
      );
    }

    if (context.team.staff.trainersLevel >= minLevel && coaches.isEmpty) {
      return ClauseEvaluationResult(
        clause: clause,
        status: ClauseComplianceStatus.warning,
        headline: 'Ogólny poziom trenerów wystarczający, brak dedykowanego coacha',
        explanation:
            'Poziom sztabu (${context.team.staff.trainersLevel}) spełnia minimum, lecz brak imiennego trenera dla ${context.rider.fullName}.',
        recommendedAction: 'Przypisz dedykowanego trenera w ekranie Sztabu.',
        moraleDelta: -3.0,
      );
    }

    return ClauseEvaluationResult(
      clause: clause,
      status: ClauseComplianceStatus.breached,
      headline: 'Brak wymaganego trenera ($preferredName)',
      explanation:
          'Drużyna nie zatrudnia $preferredName ani trenera o poziomie >= $minLevel (obecnie ${context.team.staff.trainersLevel}).',
      recommendedAction: 'Zatrudnij w Sztabie trenera o poziomie >= $minLevel lub wypłać dodatek na osobistego coacha.',
      moraleDelta: clause.moralePenaltyOnBreach,
      loyaltyDelta: clause.loyaltyPenaltyOnBreach,
    );
  }

  ClauseEvaluationResult _evaluateRelegationFreeRelease(
    AgentContractClause clause,
    ClauseEvaluationContext context,
  ) {
    final bool relegated = context.wasRelegatedFromWorldTour ||
        (context.previousDivision == TeamDivision.worldTour &&
            context.team.division != TeamDivision.worldTour);

    if (relegated) {
      return ClauseEvaluationResult(
        clause: clause,
        status: ClauseComplianceStatus.triggered,
        headline: 'Aktywowano Darmowe Odejście (Spadek z WT)',
        explanation:
            'Drużyna utraciła licencję UCI WorldTour. Kwota odstępnego została wyzerowana (0 EUR) — kolarz może odejść jako wolny agent.',
        recommendedAction: 'Spróbuj renegocjować nowy kontrakt z podwyżką lub przygotuj następcę na rynku transferowym.',
        moraleDelta: clause.moralePenaltyOnBreach,
        loyaltyDelta: clause.loyaltyPenaltyOnBreach,
        triggersFreeRelease: true,
      );
    }

    if (context.team.division == TeamDivision.worldTour) {
      return ClauseEvaluationResult(
        clause: clause,
        status: ClauseComplianceStatus.compliant,
        headline: 'Licencja WorldTour bezpieczna',
        explanation: 'Drużyna startuje w UCI WorldTour — klauzula darmowego odejścia pozostaje w uśpieniu.',
        recommendedAction: 'Utrzymaj miejsce w Top 18 rankingu 3-letniego UCI.',
      );
    }

    return ClauseEvaluationResult(
      clause: clause,
      status: ClauseComplianceStatus.notApplicable,
      headline: 'Drużyna poza WorldTourem (${context.team.division.label})',
      explanation: 'Klauzula dotyczy wyłącznie spadku z najwyższej dywizji WorldTour.',
      recommendedAction: 'Awans do WorldTour ponownie aktywuje ochronę kontraktową.',
    );
  }

  GrandTourTarget _pickPreferredGrandTour(Rider rider, int seed) {
    switch (rider.nationalityIso.toUpperCase()) {
      case 'ITA':
        return GrandTourTarget.giroDItalia;
      case 'ESP':
      case 'COL':
        return GrandTourTarget.vueltaAEspana;
      case 'FRA':
      case 'SLO':
      case 'DEN':
      case 'BEL':
      case 'GBR':
        return GrandTourTarget.tourDeFrance;
      default:
        const values = GrandTourTarget.values;
        return values[(rider.id.hashCode.abs() + seed) % values.length];
    }
  }

  CompleteBike? _pickBestBikeFromTeam(List<CompleteBike> bikes) {
    if (bikes.isEmpty) return null;
    CompleteBike best = bikes.first;
    int bestScore = best.frame.priceEur + best.wheelset.priceEur;
    for (final bike in bikes.skip(1)) {
      final score = bike.frame.priceEur + bike.wheelset.priceEur;
      if (score > bestScore) {
        best = bike;
        bestScore = score;
      }
    }
    return best;
  }
}

/// Responsywny panel UI prezentujący i pozwalający zarządzać klauzulami specjalnymi agenta.
/// Obsługuje rozdzielczości 390x844, 1024x768 i 1600x900 oraz pełne stany hover/active/disabled/focus.
class AgentContractClausesPanel extends StatefulWidget {
  final RiderContractClausesBundle bundle;
  final ContractClausesAuditReport? auditReport;
  final int baseMonthlySalaryEur;
  final bool isNegotiationEditable;
  final ValueChanged<RiderContractClausesBundle>? onBundleChanged;

  const AgentContractClausesPanel({
    super.key,
    required this.bundle,
    this.auditReport,
    required this.baseMonthlySalaryEur,
    this.isNegotiationEditable = false,
    this.onBundleChanged,
  });

  @override
  State<AgentContractClausesPanel> createState() => _AgentContractClausesPanelState();
}

class _AgentContractClausesPanelState extends State<AgentContractClausesPanel> {
  final AgentContractClausesEngine _engine = const AgentContractClausesEngine();
  String? _selectedClauseId;

  @override
  void initState() {
    super.initState();
    if (widget.bundle.clauses.isNotEmpty) {
      _selectedClauseId = widget.bundle.clauses.first.id;
    }
  }

  void _toggleClause(AgentContractClause clause) {
    if (!widget.isNegotiationEditable || widget.onBundleChanged == null) return;
    final updatedClauses = widget.bundle.clauses
        .map((c) => c.id == clause.id ? c.copyWith(isActive: !c.isActive) : c)
        .toList();
    widget.onBundleChanged!(widget.bundle.copyWith(clauses: updatedClauses));
  }

  void _updateGrandTourTarget(AgentContractClause clause, GrandTourTarget target) {
    if (!widget.isNegotiationEditable || widget.onBundleChanged == null) return;
    final updatedClauses = widget.bundle.clauses
        .map(
          (c) => c.id == clause.id
              ? c.copyWith(
                  targetGrandTour: target,
                  notes: 'Gwarancja roli lidera GC lub głównego lidera na ${target.displayName}.',
                )
              : c,
        )
        .toList();
    widget.onBundleChanged!(widget.bundle.copyWith(clauses: updatedClauses));
  }

  ClauseEvaluationResult? _findAuditForClause(String clauseId) {
    final report = widget.auditReport;
    if (report == null) return null;
    for (final item in report.results) {
      if (item.clause.id == clauseId) return item;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final negotiatedSalary = _engine.calculateNegotiatedSalaryWithClauses(
      baseSalaryDemandEur: widget.baseMonthlySalaryEur,
      activeClauses: widget.bundle.activeClauses,
    );
    final savingsEur = math.max(0, widget.baseMonthlySalaryEur - negotiatedSalary);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D), width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 520;
          final isWide = constraints.maxWidth >= 920;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(isCompact, negotiatedSalary, savingsEur),
              if (widget.auditReport != null) ...[
                const SizedBox(height: 12),
                _buildAuditSummaryBanner(widget.auditReport!),
              ],
              const SizedBox(height: 14),
              if (widget.bundle.clauses.isEmpty)
                _buildEmptyState()
              else if (isWide)
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: widget.bundle.clauses.map((clause) {
                    final cardWidth = (constraints.maxWidth - 32 - 12) / 2;
                    return SizedBox(
                      width: math.max(280, cardWidth),
                      child: _ClauseInteractiveCard(
                        clause: clause,
                        auditResult: _findAuditForClause(clause.id),
                        isSelected: _selectedClauseId == clause.id,
                        isEditable: widget.isNegotiationEditable,
                        onSelect: () => setState(() => _selectedClauseId = clause.id),
                        onToggle: () => _toggleClause(clause),
                        onGrandTourChanged: (gt) => _updateGrandTourTarget(clause, gt),
                      ),
                    );
                  }).toList(),
                )
              else
                Column(
                  children: widget.bundle.clauses.map((clause) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ClauseInteractiveCard(
                        clause: clause,
                        auditResult: _findAuditForClause(clause.id),
                        isSelected: _selectedClauseId == clause.id,
                        isEditable: widget.isNegotiationEditable,
                        onSelect: () => setState(() => _selectedClauseId = clause.id),
                        onToggle: () => _toggleClause(clause),
                        onGrandTourChanged: (gt) => _updateGrandTourTarget(clause, gt),
                      ),
                    );
                  }).toList(),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isCompact, int negotiatedSalary, int savingsEur) {
    final discountPercent = (widget.bundle.totalSalaryDiscountFactor * 100).round();

    final titleBlock = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primaryAccent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.6)),
          ),
          child: const Icon(Icons.gavel_rounded, color: AppColors.goldAccent, size: 18),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Klauzule Specjalne Agenta',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Aktywne: ${widget.bundle.activeClauses.length}/${widget.bundle.clauses.length} • Redukcja pensji: -$discountPercent%',
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
    );

    final salaryChip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        crossAxisAlignment: isCompact ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Text(
            '${Formatters.formatCurrency(negotiatedSalary)} / mies.',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.goldAccent,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          if (savingsEur > 0)
            Text(
              'Oszczędność: -${Formatters.formatCurrency(savingsEur)}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: AppColors.statusSuccess,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
        ],
      ),
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleBlock,
          const SizedBox(height: 10),
          salaryChip,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: titleBlock),
        const SizedBox(width: 12),
        salaryChip,
      ],
    );
  }

  Widget _buildAuditSummaryBanner(ContractClausesAuditReport report) {
    final Color accent;
    final IconData icon;
    if (report.isFreeAgentReleaseTriggered) {
      accent = AppColors.goldAccent;
      icon = Icons.lock_open_rounded;
    } else if (report.hasAnyBreach) {
      accent = AppColors.crimsonAlert;
      icon = Icons.warning_amber_rounded;
    } else {
      accent = AppColors.statusSuccess;
      icon = Icons.verified_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              report.summaryMessage,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: const Text(
        'Brak klauzul specjalnych w tym kontrakcie.',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _ClauseInteractiveCard extends StatefulWidget {
  final AgentContractClause clause;
  final ClauseEvaluationResult? auditResult;
  final bool isSelected;
  final bool isEditable;
  final VoidCallback onSelect;
  final VoidCallback onToggle;
  final ValueChanged<GrandTourTarget> onGrandTourChanged;

  const _ClauseInteractiveCard({
    required this.clause,
    required this.auditResult,
    required this.isSelected,
    required this.isEditable,
    required this.onSelect,
    required this.onToggle,
    required this.onGrandTourChanged,
  });

  @override
  State<_ClauseInteractiveCard> createState() => _ClauseInteractiveCardState();
}

class _ClauseInteractiveCardState extends State<_ClauseInteractiveCard> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.clause.isActive;
    final statusColor = widget.auditResult?.status.statusColor ??
        (isActive ? AppColors.goldAccent : AppColors.textSecondary);

    final borderColor = _isFocused
        ? AppColors.accentBlue
        : widget.isSelected
            ? AppColors.goldAccent
            : _isHovered
                ? AppColors.primaryAccent
                : const Color(0xFF2A2F3D);

    final bgColor = !isActive
        ? AppColors.background.withValues(alpha: 0.7)
        : _isHovered
            ? AppColors.surfaceLight
            : AppColors.surfaceLight.withValues(alpha: 0.78);

    return FocusableActionDetector(
      onShowFocusHighlight: (focused) => setState(() => _isFocused = focused),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onSelect,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: borderColor,
                width: _isFocused || widget.isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      widget.clause.type.icon,
                      size: 18,
                      color: isActive ? statusColor : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.clause.type.title,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.clause.type.subtitlePl,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusOrSwitch(isActive, statusColor),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  widget.auditResult?.explanation ?? widget.clause.notes,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (widget.clause.type == AgentContractClauseType.guaranteedGrandTourLeadership &&
                    widget.isEditable &&
                    isActive) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: GrandTourTarget.values.map((gt) {
                      final selected = widget.clause.targetGrandTour == gt;
                      return ChoiceChip(
                        label: Text(
                          gt.shortCode,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: selected ? AppColors.background : AppColors.textPrimary,
                          ),
                        ),
                        selected: selected,
                        selectedColor: AppColors.goldAccent,
                        backgroundColor: AppColors.surface,
                        side: BorderSide(
                          color: selected ? AppColors.goldAccent : const Color(0xFF2A2F3D),
                        ),
                        onSelected: (_) => widget.onGrandTourChanged(gt),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Redukcja pensji: -${(widget.clause.salaryDiscountFactor * 100).round()}%',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.statusSuccess,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (widget.auditResult != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: statusColor.withValues(alpha: 0.45)),
                        ),
                        child: Text(
                          widget.auditResult!.status.labelPl,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
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

  Widget _buildStatusOrSwitch(bool isActive, Color statusColor) {
    if (widget.isEditable) {
      return Switch(
        value: isActive,
        activeThumbColor: AppColors.goldAccent,
        activeTrackColor: AppColors.primaryAccent,
        inactiveThumbColor: AppColors.textSecondary,
        inactiveTrackColor: AppColors.background,
        onChanged: (_) => widget.onToggle(),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? statusColor.withValues(alpha: 0.15) : AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isActive ? statusColor.withValues(alpha: 0.4) : const Color(0xFF2A2F3D)),
      ),
      child: Text(
        isActive ? widget.clause.type.shortBadge : 'WYŁ.',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isActive ? statusColor : AppColors.textSecondary,
        ),
      ),
    );
  }
}
