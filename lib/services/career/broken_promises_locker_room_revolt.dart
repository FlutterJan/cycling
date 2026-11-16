import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/race/tour_race.dart';
import '../../models/rider/rider.dart';
import '../../models/rider/rider_contract.dart';
import 'rider_ego_and_conflicts_service.dart';

/// Rola obiecana kolarzowi przed startem Wielkiego Touru lub sezonu.
enum PromisedRaceRole {
  soleLeader,
  coLeader,
  protectedSprinter,
  stageHunter;

  String toJson() => name;

  static PromisedRaceRole fromJson(String value) {
    return PromisedRaceRole.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => PromisedRaceRole.soleLeader,
    );
  }

  String get displayName {
    switch (this) {
      case PromisedRaceRole.soleLeader:
        return 'Jedyny Lider GC';
      case PromisedRaceRole.coLeader:
        return 'Współlider';
      case PromisedRaceRole.protectedSprinter:
        return 'Chroniony Sprinter';
      case PromisedRaceRole.stageHunter:
        return 'Wolna Ręka (Stage Hunter)';
    }
  }
}

/// Rola faktycznie przydzielona kolarzowi przez menedżera na dany wyścig.
enum AssignedRaceRole {
  leader,
  coLeader,
  domestique,
  omittedFromRoster;

  String toJson() => name;

  static AssignedRaceRole fromJson(String value) {
    return AssignedRaceRole.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => AssignedRaceRole.domestique,
    );
  }

  String get displayName {
    switch (this) {
      case AssignedRaceRole.leader:
        return 'Lider Zespołu';
      case AssignedRaceRole.coLeader:
        return 'Współlider';
      case AssignedRaceRole.domestique:
        return 'Pomocnik (Domestique)';
      case AssignedRaceRole.omittedFromRoster:
        return 'Pominięty w składzie';
    }
  }
}

/// Przyczyna złamania obietnicy przedstartowej.
enum PromiseBreachReason {
  demotedToDomestique,
  omittedFromSquad,
  sharedLeadershipViolation;

  String toJson() => name;

  static PromiseBreachReason fromJson(String value) {
    return PromiseBreachReason.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => PromiseBreachReason.demotedToDomestique,
    );
  }

  String get label {
    switch (this) {
      case PromiseBreachReason.demotedToDomestique:
        return 'Zdegradowany do roli pomocnika';
      case PromiseBreachReason.omittedFromSquad:
        return 'Pominięty w składzie wyścigowym';
      case PromiseBreachReason.sharedLeadershipViolation:
        return 'Złamana gwarancja jedynego lidera';
    }
  }
}

/// Skala buntu w szatni drużyny.
enum LockerRoomRevoltSeverity {
  moderate,
  severe,
  explosiveMutiny;

  String toJson() => name;

  static LockerRoomRevoltSeverity fromJson(String value) {
    return LockerRoomRevoltSeverity.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => LockerRoomRevoltSeverity.explosiveMutiny,
    );
  }

  String get displayName {
    switch (this) {
      case LockerRoomRevoltSeverity.moderate:
        return 'Napięcie w szatni';
      case LockerRoomRevoltSeverity.severe:
        return 'Poważny kryzys zaufania';
      case LockerRoomRevoltSeverity.explosiveMutiny:
        return 'Otwarty Bunt w Szatni';
    }
  }
}

/// Formalne żądanie transferu złożone przez rozgoryczonego kolarza.
class TransferDemandOrder {
  final String riderId;
  final String riderName;
  final String reason;
  final int urgencyDays;
  final bool refusesContractRenewal;
  final int demandedBuyoutDiscountPercent;
  final DateTime issuedAt;

  const TransferDemandOrder({
    required this.riderId,
    required this.riderName,
    required this.reason,
    this.urgencyDays = 14,
    this.refusesContractRenewal = true,
    this.demandedBuyoutDiscountPercent = 25,
    required this.issuedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'riderName': riderName,
      'reason': reason,
      'urgencyDays': urgencyDays,
      'refusesContractRenewal': refusesContractRenewal,
      'demandedBuyoutDiscountPercent': demandedBuyoutDiscountPercent,
      'issuedAt': issuedAt.toIso8601String(),
    };
  }

  factory TransferDemandOrder.fromJson(Map<String, dynamic> json) {
    return TransferDemandOrder(
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      reason: json['reason'] as String,
      urgencyDays: (json['urgencyDays'] as num?)?.toInt() ?? 14,
      refusesContractRenewal: json['refusesContractRenewal'] as bool? ?? true,
      demandedBuyoutDiscountPercent:
          (json['demandedBuyoutDiscountPercent'] as num?)?.toInt() ?? 25,
      issuedAt: DateTime.parse(json['issuedAt'] as String),
    );
  }
}

/// Ostry wywiad w prasie kolarskiej udzielony po złamaniu obietnicy.
class ExplosivePressInterview {
  final String id;
  final String riderId;
  final String riderName;
  final String outletName;
  final String headline;
  final String quote;
  final int reputationDamagePoints;
  final int sponsorConcernLevel;
  final DateTime publishedAt;

  const ExplosivePressInterview({
    required this.id,
    required this.riderId,
    required this.riderName,
    required this.outletName,
    required this.headline,
    required this.quote,
    required this.reputationDamagePoints,
    required this.sponsorConcernLevel,
    required this.publishedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'riderId': riderId,
      'riderName': riderName,
      'outletName': outletName,
      'headline': headline,
      'quote': quote,
      'reputationDamagePoints': reputationDamagePoints,
      'sponsorConcernLevel': sponsorConcernLevel,
      'publishedAt': publishedAt.toIso8601String(),
    };
  }

  factory ExplosivePressInterview.fromJson(Map<String, dynamic> json) {
    return ExplosivePressInterview(
      id: json['id'] as String,
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      outletName: json['outletName'] as String,
      headline: json['headline'] as String,
      quote: json['quote'] as String,
      reputationDamagePoints: (json['reputationDamagePoints'] as num).toInt(),
      sponsorConcernLevel: (json['sponsorConcernLevel'] as num).toInt(),
      publishedAt: DateTime.parse(json['publishedAt'] as String),
    );
  }
}

/// Pełny zapis konsekwencji pojedynczej złamanej obietnicy.
class BrokenPromiseConsequenceRecord {
  final String promiseId;
  final String riderId;
  final String riderName;
  final String raceId;
  final String raceName;
  final PromisedRaceRole promisedRole;
  final AssignedRaceRole assignedRole;
  final PromiseBreachReason breachReason;
  final LockerRoomRevoltSeverity severity;
  final double teamChemistryPenalty;
  final double riderMoralePenalty;
  final double riderLoyaltyPenalty;
  final double lockerRoomTensionSpike;
  final TransferDemandOrder transferDemand;
  final ExplosivePressInterview pressInterview;
  final DateTime revoltDate;

  const BrokenPromiseConsequenceRecord({
    required this.promiseId,
    required this.riderId,
    required this.riderName,
    required this.raceId,
    required this.raceName,
    required this.promisedRole,
    required this.assignedRole,
    required this.breachReason,
    required this.severity,
    required this.teamChemistryPenalty,
    required this.riderMoralePenalty,
    required this.riderLoyaltyPenalty,
    required this.lockerRoomTensionSpike,
    required this.transferDemand,
    required this.pressInterview,
    required this.revoltDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'promiseId': promiseId,
      'riderId': riderId,
      'riderName': riderName,
      'raceId': raceId,
      'raceName': raceName,
      'promisedRole': promisedRole.toJson(),
      'assignedRole': assignedRole.toJson(),
      'breachReason': breachReason.toJson(),
      'severity': severity.toJson(),
      'teamChemistryPenalty': teamChemistryPenalty,
      'riderMoralePenalty': riderMoralePenalty,
      'riderLoyaltyPenalty': riderLoyaltyPenalty,
      'lockerRoomTensionSpike': lockerRoomTensionSpike,
      'transferDemand': transferDemand.toJson(),
      'pressInterview': pressInterview.toJson(),
      'revoltDate': revoltDate.toIso8601String(),
    };
  }

  factory BrokenPromiseConsequenceRecord.fromJson(Map<String, dynamic> json) {
    return BrokenPromiseConsequenceRecord(
      promiseId: json['promiseId'] as String,
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      raceId: json['raceId'] as String,
      raceName: json['raceName'] as String,
      promisedRole: PromisedRaceRole.fromJson(json['promisedRole'] as String),
      assignedRole: AssignedRaceRole.fromJson(json['assignedRole'] as String),
      breachReason:
          PromiseBreachReason.fromJson(json['breachReason'] as String),
      severity: LockerRoomRevoltSeverity.fromJson(json['severity'] as String),
      teamChemistryPenalty: (json['teamChemistryPenalty'] as num).toDouble(),
      riderMoralePenalty: (json['riderMoralePenalty'] as num).toDouble(),
      riderLoyaltyPenalty: (json['riderLoyaltyPenalty'] as num).toDouble(),
      lockerRoomTensionSpike:
          (json['lockerRoomTensionSpike'] as num).toDouble(),
      transferDemand: TransferDemandOrder.fromJson(
        json['transferDemand'] as Map<String, dynamic>,
      ),
      pressInterview: ExplosivePressInterview.fromJson(
        json['pressInterview'] as Map<String, dynamic>,
      ),
      revoltDate: DateTime.parse(json['revoltDate'] as String),
    );
  }
}

/// Zbiorczy wynik ewaluacji powołania składu pod kątem złamanych obietnic.
class LockerRoomRevoltEvaluationResult {
  final bool hasRevolt;
  final List<BrokenPromiseConsequenceRecord> brokenPromises;
  final List<RiderContractPromise> updatedPromises;
  final List<Rider> updatedRiders;
  final double initialTeamChemistry;
  final double resultingTeamChemistry;
  final double totalChemistryDelta;
  final List<TransferDemandOrder> transferRequests;
  final List<ExplosivePressInterview> pressInterviews;
  final List<String> affectedTeammateIds;
  final String lockerRoomMoraleImpactSummary;

  const LockerRoomRevoltEvaluationResult({
    required this.hasRevolt,
    required this.brokenPromises,
    required this.updatedPromises,
    required this.updatedRiders,
    required this.initialTeamChemistry,
    required this.resultingTeamChemistry,
    required this.totalChemistryDelta,
    required this.transferRequests,
    required this.pressInterviews,
    required this.affectedTeammateIds,
    required this.lockerRoomMoraleImpactSummary,
  });
}

/// System konsekwencji złamanych obietnic kontraktowych i taktycznych
/// (`BrokenPromisesLockerRoomRevolt`).
///
/// Jeśli menedżer obiecał gwiazdorowi rolę lidera na Tour de France, a następnie
/// wystawił go jako pomocnika lub pominął w składzie, kolarz natychmiast składa
/// żądanie transferu, udziela ostrego wywiadu w prasie i obniża chemię zespołu
/// o 30 punktów.
class BrokenPromisesLockerRoomRevolt {
  BrokenPromisesLockerRoomRevolt._();

  /// Kara do chemii zespołu za złamanie obietnicy roli lidera gwiazdorowi na TdF.
  static const double tourDeFranceLeaderBreachChemistryPenalty = 30.0;

  /// Kara do chemii zespołu za złamanie obietnicy w innym wyścigu rangi GT/WT.
  static const double standardPromiseBreachChemistryPenalty = 18.0;

  static const List<String> _pressOutlets = [
    "L'Équipe",
    'Het Laatste Nieuws',
    'Cyclingnews',
    'La Gazzetta dello Sport',
    'WielerFlits',
  ];

  /// Sprawdza, czy wyścig jest Tour de France.
  static bool isTourDeFranceRace(TourRace race) {
    final lowerId = race.id.toLowerCase();
    final lowerName = race.name.toLowerCase();
    return lowerId.contains('tdf') ||
        lowerId.contains('tour_de_france') ||
        lowerName.contains('tour de france');
  }

  /// Określa, czy kolarz ma status gwiazdora / lidera drużyny.
  static bool isStarRider(Rider rider) {
    return rider.overallRating >= 80 ||
        rider.contract.role == RiderRole.teamLeader ||
        rider.contract.role == RiderRole.coLeader ||
        rider.contract.role == RiderRole.sprinter;
  }

  /// Ewaluuje zgłoszony skład oraz przydzielone role taktyczne względem aktywnych obietnic.
  static LockerRoomRevoltEvaluationResult evaluateSquadSelectionConsequences({
    required TourRace race,
    required List<Rider> teamRoster,
    required List<String> selectedSquadRiderIds,
    required Map<String, AssignedRaceRole> assignedRolesByRiderId,
    required List<RiderContractPromise> activePromises,
    required double currentTeamChemistry,
    DateTime? evaluationDate,
    String teamName = 'Zespół',
  }) {
    final now = evaluationDate ?? DateTime.now();
    final clampedInitialChemistry = currentTeamChemistry.clamp(0.0, 100.0);

    if (teamRoster.isEmpty || activePromises.isEmpty) {
      return LockerRoomRevoltEvaluationResult(
        hasRevolt: false,
        brokenPromises: const [],
        updatedPromises: List<RiderContractPromise>.unmodifiable(activePromises),
        updatedRiders: List<Rider>.unmodifiable(teamRoster),
        initialTeamChemistry: clampedInitialChemistry,
        resultingTeamChemistry: clampedInitialChemistry,
        totalChemistryDelta: 0.0,
        transferRequests: const [],
        pressInterviews: const [],
        affectedTeammateIds: const [],
        lockerRoomMoraleImpactSummary:
            'Brak złamanych obietnic — atmosfera w szatni przed ${race.name} jest stabilna.',
      );
    }

    final selectedSet = selectedSquadRiderIds.toSet();
    final rosterById = <String, Rider>{
      for (final rider in teamRoster) rider.id: rider,
    };

    final leaderAssignedCount = selectedSet.where((riderId) {
      final explicitRole = assignedRolesByRiderId[riderId];
      if (explicitRole != null) {
        return explicitRole == AssignedRaceRole.leader;
      }
      final rider = rosterById[riderId];
      return rider?.contract.role == RiderRole.teamLeader;
    }).length;

    final updatedPromises = <RiderContractPromise>[];
    final brokenRecords = <BrokenPromiseConsequenceRecord>[];
    final transferRequests = <TransferDemandOrder>[];
    final pressInterviews = <ExplosivePressInterview>[];
    final revoltingRiderIds = <String>{};
    final updatedRiderMap = <String, Rider>{
      for (final rider in teamRoster) rider.id: rider,
    };

    double accumulatedChemistryPenalty = 0.0;

    for (final promise in activePromises) {
      if (!_appliesToRace(promise, race) ||
          promise.status != ContractPromiseStatus.pending ||
          promise.brokenPenaltyApplied) {
        updatedPromises.add(promise);
        continue;
      }

      final rider = updatedRiderMap[promise.riderId];
      if (rider == null) {
        updatedPromises.add(promise);
        continue;
      }

      final isSelected = selectedSet.contains(rider.id);
      final assignedRole = isSelected
          ? (assignedRolesByRiderId[rider.id] ??
              _inferAssignedRoleFromContract(rider.contract.role))
          : AssignedRaceRole.omittedFromRoster;

      final breachReason = _detectBreachReason(
        promise: promise,
        assignedRole: assignedRole,
        leaderAssignedCount: leaderAssignedCount,
      );

      if (breachReason == null) {
        updatedPromises.add(promise);
        continue;
      }

      final isTdf = isTourDeFranceRace(race);
      final star = isStarRider(rider);
      final isLeaderPromise =
          promise.type == ContractPromiseType.soleLeaderGrandTour ||
              promise.type == ContractPromiseType.coLeaderProtected;

      final double chemistryPenalty = (isTdf && isLeaderPromise && star) ||
              (isTdf &&
                  (breachReason == PromiseBreachReason.demotedToDomestique ||
                      breachReason == PromiseBreachReason.omittedFromSquad))
          ? tourDeFranceLeaderBreachChemistryPenalty
          : standardPromiseBreachChemistryPenalty;

      final severity = chemistryPenalty >= tourDeFranceLeaderBreachChemistryPenalty
          ? LockerRoomRevoltSeverity.explosiveMutiny
          : LockerRoomRevoltSeverity.severe;

      const double moralePenalty = 45.0;
      const double loyaltyPenalty = 55.0;
      const double tensionSpike = 35.0;

      final transferDemand = _buildTransferDemand(
        rider: rider,
        race: race,
        breachReason: breachReason,
        issuedAt: now,
      );

      final interview = _buildExplosivePressInterview(
        rider: rider,
        race: race,
        teamName: teamName,
        breachReason: breachReason,
        publishedAt: now,
      );

      final record = BrokenPromiseConsequenceRecord(
        promiseId: promise.id,
        riderId: rider.id,
        riderName: rider.fullName,
        raceId: race.id,
        raceName: race.name,
        promisedRole: _mapPromiseToRole(promise.type),
        assignedRole: assignedRole,
        breachReason: breachReason,
        severity: severity,
        teamChemistryPenalty: chemistryPenalty,
        riderMoralePenalty: moralePenalty,
        riderLoyaltyPenalty: loyaltyPenalty,
        lockerRoomTensionSpike: tensionSpike,
        transferDemand: transferDemand,
        pressInterview: interview,
        revoltDate: now,
      );

      brokenRecords.add(record);
      transferRequests.add(transferDemand);
      pressInterviews.add(interview);
      revoltingRiderIds.add(rider.id);
      accumulatedChemistryPenalty += chemistryPenalty;

      updatedRiderMap[rider.id] = rider.copyWith(
        contract: rider.contract.copyWith(
          morale: (rider.contract.morale - moralePenalty).clamp(0.0, 100.0),
          leaderLoyalty:
              (rider.contract.leaderLoyalty - loyaltyPenalty).clamp(0.0, 100.0),
        ),
      );

      updatedPromises.add(
        promise.copyWith(
          status: ContractPromiseStatus.broken,
          resolvedDate: now,
          brokenPenaltyApplied: true,
        ),
      );
    }

    final affectedTeammateIds = <String>[];
    if (brokenRecords.isNotEmpty) {
      for (final rider in teamRoster) {
        if (revoltingRiderIds.contains(rider.id)) continue;
        final current = updatedRiderMap[rider.id]!;
        const teammateRipplePenalty = 6.0;
        updatedRiderMap[rider.id] = current.copyWith(
          contract: current.contract.copyWith(
            morale:
                (current.contract.morale - teammateRipplePenalty).clamp(0.0, 100.0),
          ),
        );
        affectedTeammateIds.add(rider.id);
      }
    }

    final resultingChemistry =
        (clampedInitialChemistry - accumulatedChemistryPenalty).clamp(0.0, 100.0);
    final totalDelta = resultingChemistry - clampedInitialChemistry;

    final summary = brokenRecords.isEmpty
        ? 'Brak złamanych obietnic — atmosfera w szatni przed ${race.name} jest stabilna.'
        : 'BUNT W SZATNI (${brokenRecords.length}): '
            '${brokenRecords.map((b) => b.riderName).join(", ")} '
            'żąda transferu i atakuje zarząd w mediach. '
            'Chemia zespołu spadła o ${accumulatedChemistryPenalty.toStringAsFixed(0)} pkt '
            '(${clampedInitialChemistry.toStringAsFixed(0)} -> ${resultingChemistry.toStringAsFixed(0)}).';

    return LockerRoomRevoltEvaluationResult(
      hasRevolt: brokenRecords.isNotEmpty,
      brokenPromises: List<BrokenPromiseConsequenceRecord>.unmodifiable(brokenRecords),
      updatedPromises: List<RiderContractPromise>.unmodifiable(updatedPromises),
      updatedRiders: List<Rider>.unmodifiable(
        teamRoster.map((r) => updatedRiderMap[r.id]!),
      ),
      initialTeamChemistry: clampedInitialChemistry,
      resultingTeamChemistry: resultingChemistry,
      totalChemistryDelta: totalDelta,
      transferRequests: List<TransferDemandOrder>.unmodifiable(transferRequests),
      pressInterviews: List<ExplosivePressInterview>.unmodifiable(pressInterviews),
      affectedTeammateIds: List<String>.unmodifiable(affectedTeammateIds),
      lockerRoomMoraleImpactSummary: summary,
    );
  }

  static bool _appliesToRace(RiderContractPromise promise, TourRace race) {
    if (promise.targetRaceId == null) {
      return race.isGrandTour || isTourDeFranceRace(race);
    }
    if (promise.targetRaceId == race.id) return true;
    final promiseRaceLower = (promise.targetRaceName ?? '').toLowerCase();
    if (isTourDeFranceRace(race) && promiseRaceLower.contains('tour de france')) {
      return true;
    }
    return false;
  }

  static AssignedRaceRole _inferAssignedRoleFromContract(RiderRole role) {
    switch (role) {
      case RiderRole.teamLeader:
        return AssignedRaceRole.leader;
      case RiderRole.coLeader:
        return AssignedRaceRole.coLeader;
      case RiderRole.sprinter:
      case RiderRole.breakawaySpecialist:
      case RiderRole.superDomestique:
      case RiderRole.domestique:
      case RiderRole.neoPro:
        return AssignedRaceRole.domestique;
    }
  }

  static PromisedRaceRole _mapPromiseToRole(ContractPromiseType type) {
    switch (type) {
      case ContractPromiseType.soleLeaderGrandTour:
        return PromisedRaceRole.soleLeader;
      case ContractPromiseType.coLeaderProtected:
        return PromisedRaceRole.coLeader;
      case ContractPromiseType.dedicatedSprintTrain:
        return PromisedRaceRole.protectedSprinter;
      case ContractPromiseType.guaranteedGrandTourRoster:
      case ContractPromiseType.freeRoleStageHunting:
        return PromisedRaceRole.stageHunter;
    }
  }

  static PromiseBreachReason? _detectBreachReason({
    required RiderContractPromise promise,
    required AssignedRaceRole assignedRole,
    required int leaderAssignedCount,
  }) {
    if (assignedRole == AssignedRaceRole.omittedFromRoster) {
      return PromiseBreachReason.omittedFromSquad;
    }

    switch (promise.type) {
      case ContractPromiseType.soleLeaderGrandTour:
        if (assignedRole == AssignedRaceRole.domestique) {
          return PromiseBreachReason.demotedToDomestique;
        }
        if (assignedRole == AssignedRaceRole.coLeader ||
            leaderAssignedCount >= 2) {
          return PromiseBreachReason.sharedLeadershipViolation;
        }
        return null;

      case ContractPromiseType.coLeaderProtected:
        if (assignedRole == AssignedRaceRole.domestique) {
          return PromiseBreachReason.demotedToDomestique;
        }
        return null;

      case ContractPromiseType.dedicatedSprintTrain:
      case ContractPromiseType.guaranteedGrandTourRoster:
      case ContractPromiseType.freeRoleStageHunting:
        if (assignedRole == AssignedRaceRole.domestique &&
            promise.type != ContractPromiseType.guaranteedGrandTourRoster) {
          return PromiseBreachReason.demotedToDomestique;
        }
        return null;
    }
  }

  static TransferDemandOrder _buildTransferDemand({
    required Rider rider,
    required TourRace race,
    required PromiseBreachReason breachReason,
    required DateTime issuedAt,
  }) {
    final reasonText = breachReason == PromiseBreachReason.omittedFromSquad
        ? 'Pominięcie w składzie na ${race.name} mimo pisemnej gwarancji roli lidera.'
        : 'Degradacja do roli pomocnika na ${race.name} mimo obietnicy przywództwa.';

    return TransferDemandOrder(
      riderId: rider.id,
      riderName: rider.fullName,
      reason: reasonText,
      urgencyDays: 14,
      refusesContractRenewal: true,
      demandedBuyoutDiscountPercent: 25,
      issuedAt: issuedAt,
    );
  }

  static ExplosivePressInterview _buildExplosivePressInterview({
    required Rider rider,
    required TourRace race,
    required String teamName,
    required PromiseBreachReason breachReason,
    required DateTime publishedAt,
  }) {
    final outletIndex =
        rider.id.hashCode.abs() % _pressOutlets.length;
    final outlet = _pressOutlets[outletIndex];

    final String headline;
    final String quote;

    if (breachReason == PromiseBreachReason.omittedFromSquad) {
      headline =
          'SZOK PRZED ${race.name.toUpperCase()}: ${rider.fullName} pominięty! „Zostałem zdradzony przez $teamName”';
      quote =
          '„Całą zimę budowałem formę pod ${race.name}, bo dyrektor sportowy obiecał mi opaskę lidera. '
          'Zostawienie mnie poza składem to policzek i brak szacunku. Nie wyobrażam sobie dalszej jazdy w tej koszulce — mój agent już szuka nowego zespołu.”';
    } else if (breachReason == PromiseBreachReason.demotedToDomestique) {
      headline =
          'AWANTURA W AUTOBUSIE $teamName: ${rider.fullName} wybucha po degradacji do roli pomocnika';
      quote =
          '„Nie po to harowałem na zgrupowaniach wysokogórskich jako lider na ${race.name}, żeby teraz wozić bidony innym. '
          'Obietnice w tym klubie nie są warte papieru, na którym je spisano. Żądam natychmiastowego transferu.”';
    } else {
      headline =
          'WOJNA O LIDEROWANIE W $teamName: ${rider.fullName} ostro o złamanej obietnicy na ${race.name}';
      quote =
          '„Miałem być jedynym liderem na ${race.name}, a w autobusie dowiaduję się o podwójnej hierarchii. '
          'Jeśli zarząd nie dotrzymuje słowa, czas spakować walizki i odejść.”';
    }

    return ExplosivePressInterview(
      id: 'interview_${rider.id}_${race.id}',
      riderId: rider.id,
      riderName: rider.fullName,
      outletName: outlet,
      headline: headline,
      quote: quote,
      reputationDamagePoints: isTourDeFranceRace(race) ? 28 : 16,
      sponsorConcernLevel: isTourDeFranceRace(race) ? 85 : 55,
      publishedAt: publishedAt,
    );
  }
}

/// Panel UI prezentujący kryzys w szatni po złamaniu obietnic liderowi.
///
/// Obsługuje responsywność `LayoutBuilder` (390x844, 1024x768, 1600x900),
/// paletę `AppColors`, czcionkę `Inter` oraz pełne stany `hover`, `active`,
/// `disabled` i `focus`.
class BrokenPromisesLockerRoomRevoltPanel extends StatefulWidget {
  final LockerRoomRevoltEvaluationResult evaluation;
  final void Function(TransferDemandOrder demand)? onAcceptTransferRequest;
  final VoidCallback? onCallEmergencyMeeting;
  final VoidCallback? onDismiss;

  const BrokenPromisesLockerRoomRevoltPanel({
    super.key,
    required this.evaluation,
    this.onAcceptTransferRequest,
    this.onCallEmergencyMeeting,
    this.onDismiss,
  });

  @override
  State<BrokenPromisesLockerRoomRevoltPanel> createState() =>
      _BrokenPromisesLockerRoomRevoltPanelState();
}

class _BrokenPromisesLockerRoomRevoltPanelState
    extends State<BrokenPromisesLockerRoomRevoltPanel> {
  final Set<String> _acceptedTransferRiderIds = <String>{};
  bool _meetingScheduled = false;

  @override
  Widget build(BuildContext context) {
    final result = widget.evaluation;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: result.hasRevolt
              ? AppColors.crimsonAlert.withValues(alpha: 0.65)
              : const Color(0xFF2A2F3D),
          width: 1.0,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          final isDesktop = constraints.maxWidth >= 1050;
          final padding = isMobile ? 14.0 : 20.0;

          return SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(result, isMobile),
                const SizedBox(height: 16),
                if (!result.hasRevolt)
                  _buildCalmStateCard()
                else if (isDesktop || !isMobile)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: _buildChemistryAndDemandsColumn(result),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 6,
                        child: _buildInterviewsAndActionsColumn(result),
                      ),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildChemistryAndDemandsColumn(result),
                      const SizedBox(height: 16),
                      _buildInterviewsAndActionsColumn(result),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(LockerRoomRevoltEvaluationResult result, bool isMobile) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
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
                color: (result.hasRevolt
                        ? AppColors.crimsonAlert
                        : AppColors.statusSuccess)
                    .withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: result.hasRevolt
                      ? AppColors.crimsonAlert
                      : AppColors.statusSuccess,
                ),
              ),
              child: Icon(
                result.hasRevolt
                    ? Icons.warning_amber_rounded
                    : Icons.verified_user_rounded,
                color: result.hasRevolt
                    ? AppColors.crimsonAlert
                    : AppColors.statusSuccess,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.hasRevolt
                        ? 'BUNT W SZATNI — ZŁAMANE OBIETNICE'
                        : 'STATUS SZATNI I OBIETNIC',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    result.lockerRoomMoraleImpactSummary,
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
        if (widget.onDismiss != null)
          _RevoltActionButton(
            label: 'Zamknij',
            icon: Icons.close_rounded,
            isPrimary: false,
            onPressed: widget.onDismiss,
          ),
      ],
    );
  }

  Widget _buildCalmStateCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_outline_rounded,
              color: AppColors.statusSuccess, size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Wszystkie obietnice kontraktowe i role liderów zostały uszanowane. Chemia zespołu pozostaje nienaruszona.',
              style: TextStyle(
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

  Widget _buildChemistryAndDemandsColumn(
    LockerRoomRevoltEvaluationResult result,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildChemistryGaugeCard(result),
        const SizedBox(height: 12),
        for (final record in result.brokenPromises) ...[
          _buildTransferDemandCard(record),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildChemistryGaugeCard(LockerRoomRevoltEvaluationResult result) {
    final before = result.initialTeamChemistry;
    final after = result.resultingTeamChemistry;
    final delta = result.totalChemistryDelta;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'CHEMIA ZESPOŁU',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: AppColors.textSecondary,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.crimsonAlert.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.crimsonAlert.withValues(alpha: 0.5)),
                ),
                child: Text(
                  '${delta.toStringAsFixed(0)} pkt',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                    color: AppColors.crimsonAlert,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: before, end: after),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            builder: (context, animatedValue, _) {
              final progress = (animatedValue / 100.0).clamp(0.0, 1.0);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        animatedValue.toStringAsFixed(0),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          fontFeatures: [FontFeature.tabularFigures()],
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '/ 100  (było ${before.toStringAsFixed(0)})',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontFeatures: [FontFeature.tabularFigures()],
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: AppColors.background,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress < 0.45
                            ? AppColors.crimsonAlert
                            : AppColors.amberWarning,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTransferDemandCard(BrokenPromiseConsequenceRecord record) {
    final accepted = _acceptedTransferRiderIds.contains(record.riderId);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.crimsonAlert.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.exit_to_app_rounded,
                  color: AppColors.crimsonAlert, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${record.riderName} — ŻĄDANIE TRANSFERU',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildTag(record.breachReason.label, AppColors.crimsonAlert),
              _buildTag(
                'Morale -${record.riderMoralePenalty.toStringAsFixed(0)}',
                AppColors.amberWarning,
              ),
              _buildTag(
                'Lojalność -${record.riderLoyaltyPenalty.toStringAsFixed(0)}',
                AppColors.primaryAccent,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            record.transferDemand.reason,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          _RevoltActionButton(
            label: accepted
                ? 'Wystawiono na listę transferową'
                : 'Akceptuj żądanie transferu',
            icon: accepted
                ? Icons.check_rounded
                : Icons.swap_horiz_rounded,
            isPrimary: true,
            enabled: !accepted && widget.onAcceptTransferRequest != null,
            onPressed: () {
              setState(() {
                _acceptedTransferRiderIds.add(record.riderId);
              });
              widget.onAcceptTransferRequest?.call(record.transferDemand);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInterviewsAndActionsColumn(
    LockerRoomRevoltEvaluationResult result,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final interview in result.pressInterviews) ...[
          _buildPressInterviewCard(interview),
          const SizedBox(height: 12),
        ],
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2A2F3D)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ZARZĄDZANIE KRYZYSOWE',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: AppColors.goldAccent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _meetingScheduled
                          ? 'Zwołano nadzwyczajną odprawę w autobusie drużyny.'
                          : 'Zwołaj zamknięte spotkanie szatni, aby ograniczyć dalszy spadek morale.',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _RevoltActionButton(
                label: _meetingScheduled ? 'Zwołano' : 'Odprawa Kryzysowa',
                icon: Icons.forum_rounded,
                isPrimary: false,
                enabled:
                    !_meetingScheduled && widget.onCallEmergencyMeeting != null,
                onPressed: () {
                  setState(() => _meetingScheduled = true);
                  widget.onCallEmergencyMeeting?.call();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPressInterviewCard(ExplosivePressInterview interview) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.newspaper_rounded,
                  color: AppColors.goldAccent, size: 18),
              const SizedBox(width: 8),
              Text(
                interview.outletName.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.goldAccent,
                ),
              ),
              const Spacer(),
              Text(
                'Reputacja -${interview.reputationDamagePoints}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: AppColors.crimsonAlert,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            interview.headline,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: const Border(
                left: BorderSide(color: AppColors.primaryAccent, width: 3),
              ),
            ),
            child: Text(
              interview.quote,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                fontStyle: FontStyle.italic,
                height: 1.45,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _RevoltActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final bool enabled;
  final VoidCallback? onPressed;

  const _RevoltActionButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    this.enabled = true,
    this.onPressed,
  });

  @override
  State<_RevoltActionButton> createState() => _RevoltActionButtonState();
}

class _RevoltActionButtonState extends State<_RevoltActionButton> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.enabled && widget.onPressed != null;
    final baseColor =
        widget.isPrimary ? AppColors.primaryAccent : AppColors.surface;
    final bgColor = !active
        ? AppColors.surface.withValues(alpha: 0.45)
        : _isPressed
            ? baseColor.withValues(alpha: 0.78)
            : _isHovered
                ? baseColor.withValues(alpha: 0.92)
                : baseColor;

    final borderColor = !active
        ? const Color(0xFF2A2F3D).withValues(alpha: 0.5)
        : _isFocused
            ? AppColors.goldAccent
            : _isHovered
                ? AppColors.textSecondary
                : const Color(0xFF2A2F3D);

    return FocusableActionDetector(
      enabled: active,
      onShowFocusHighlight: (focused) => setState(() => _isFocused = focused),
      onShowHoverHighlight: (hovered) => setState(() => _isHovered = hovered),
      mouseCursor:
          active ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTapDown: active ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: active ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel:
            active ? () => setState(() => _isPressed = false) : null,
        onTap: active ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: math.max(1.0, _isFocused ? 1.5 : 1.0),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: active ? AppColors.textPrimary : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        active ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
