import 'dart:math' as math;
import '../../models/career/career_save.dart';
import '../../models/rider/rider.dart';
import '../../models/rider/rider_contract.dart';
import '../../models/team/cycling_team.dart';

/// Główny profil specjalizacji i cel sezonowy Głównego Lidera (Franchise Rider).
enum FranchiseRoleFocus {
  /// Klasyfikacja Generalna Grand Touru (Tour de France / Giro d'Italia / Vuelta a España)
  grandTourGc,

  /// Brukowane Wiosenne Klasyki i Monumenty (Ronde van Vlaanderen, Paris-Roubaix)
  springCobbledClassics,

  /// Pagórkowate Klasyki Ardeńskie (Amstel Gold Race, Flèche Wallonne, Liège-Bastogne-Liège)
  ardennesClassics,

  /// Finały sprinterskie i walka o Zieloną Koszulkę (Pociąg sprinterski)
  pureSprintTrain,

  /// Uniwersalny uciekinier i etapowiec (All-Rounder / Stage Hunter)
  allRounder;

  String toJson() => name;

  static FranchiseRoleFocus fromJson(String value) {
    return FranchiseRoleFocus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => FranchiseRoleFocus.grandTourGc,
    );
  }

  String get label {
    switch (this) {
      case FranchiseRoleFocus.grandTourGc:
        return 'Lider GC na Grand Toury';
      case FranchiseRoleFocus.springCobbledClassics:
        return 'Lider na Brukowane Klasyki';
      case FranchiseRoleFocus.ardennesClassics:
        return 'Lider na Klasyki Ardeńskie';
      case FranchiseRoleFocus.pureSprintTrain:
        return 'Lider Sprintów z Peletonu';
      case FranchiseRoleFocus.timeTrialAndBreakaways:
        return 'Specjalista Czasówek i Ucieczek';
    }
  }

  static const FranchiseRoleFocus timeTrialAndBreakaways = FranchiseRoleFocus.allRounder;
}

/// Model Głównego Lidera (Franchise Rider), wokół którego budowany jest skład drużyny.
///
/// Gracz może wyznaczyć od 1 do maksymalnie 3 takich kolarzy w zespole.
class FranchiseRider {
  final String riderId;
  final String riderName;
  final FranchiseRoleFocus focus;

  /// Priorytet lidera w klubie (1 = Niekwestionowany Kapitan #1, 2 = Drugi Lider #2, 3 = Trzeci Lider #3)
  final int priorityRank;

  /// Identyfikator dedykowanego pociągu pomocników przypisanego pod tego lidera
  final String? designatedSquadId;

  const FranchiseRider({
    required this.riderId,
    required this.riderName,
    required this.focus,
    required this.priorityRank,
    this.designatedSquadId,
  });

  FranchiseRider copyWith({
    String? riderId,
    String? riderName,
    FranchiseRoleFocus? focus,
    int? priorityRank,
    String? designatedSquadId,
  }) {
    return FranchiseRider(
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      focus: focus ?? this.focus,
      priorityRank: priorityRank ?? this.priorityRank,
      designatedSquadId: designatedSquadId ?? this.designatedSquadId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'riderName': riderName,
      'focus': focus.toJson(),
      'priorityRank': priorityRank,
      'designatedSquadId': designatedSquadId,
    };
  }

  factory FranchiseRider.fromJson(Map<String, dynamic> json) {
    return FranchiseRider(
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      focus: FranchiseRoleFocus.fromJson(json['focus'] as String),
      priorityRank: (json['priorityRank'] as num).toInt(),
      designatedSquadId: json['designatedSquadId'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FranchiseRider && other.riderId == riderId;
  }

  @override
  int get hashCode => riderId.hashCode;

  @override
  String toString() =>
      'FranchiseRider(#$priorityRank $riderName, cel: ${focus.name}, squad: $designatedSquadId)';
}

/// Dedykowany skład / pociąg pomocników zbudowany wokół konkretnego celu lub lidera
/// (np. "Skład pod Tour de France" vs "Skład pod Wiosenne Klasyki" vs "Pociąg Sprinterski").
class DedicatedSquad {
  final String id;
  final String name;
  final String leaderRiderId;
  final List<String> domestiqueRiderIds;
  final String targetSeasonObjective;

  /// Liczba wspólnych wyścigów przejechanych przez ten skład
  final int sharedRacesCount;

  /// Liczba wspólnych etapów ukończonych w tej formacji
  final int sharedStagesCount;

  /// Liczba odbytych wspólnych zgrupowań i obozów wysokogórskich
  final int trainingCampsCount;

  /// Wskaźnik zgrania i chemii składu w skali 0.0 - 100.0 punktów
  final double cohesionScore;

  const DedicatedSquad({
    required this.id,
    required this.name,
    required this.leaderRiderId,
    required this.domestiqueRiderIds,
    required this.targetSeasonObjective,
    this.sharedRacesCount = 0,
    this.sharedStagesCount = 0,
    this.trainingCampsCount = 0,
    this.cohesionScore = 25.0,
  });

  /// Wszyscy kolarze tworzący skład (lider + pomocnicy)
  List<String> get allRiderIds => [leaderRiderId, ...domestiqueRiderIds];

  /// Rozmiar formacji (zazwyczaj 7 lub 8 kolarzy na Grand Tour, 6-7 na klasyki)
  int get memberCount => allRiderIds.length;

  DedicatedSquad copyWith({
    String? id,
    String? name,
    String? leaderRiderId,
    List<String>? domestiqueRiderIds,
    String? targetSeasonObjective,
    int? sharedRacesCount,
    int? sharedStagesCount,
    int? trainingCampsCount,
    double? cohesionScore,
  }) {
    return DedicatedSquad(
      id: id ?? this.id,
      name: name ?? this.name,
      leaderRiderId: leaderRiderId ?? this.leaderRiderId,
      domestiqueRiderIds: domestiqueRiderIds != null
          ? List<String>.unmodifiable(domestiqueRiderIds)
          : this.domestiqueRiderIds,
      targetSeasonObjective: targetSeasonObjective ?? this.targetSeasonObjective,
      sharedRacesCount: sharedRacesCount ?? this.sharedRacesCount,
      sharedStagesCount: sharedStagesCount ?? this.sharedStagesCount,
      trainingCampsCount: trainingCampsCount ?? this.trainingCampsCount,
      cohesionScore: cohesionScore ?? this.cohesionScore,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'leaderRiderId': leaderRiderId,
      'domestiqueRiderIds': domestiqueRiderIds,
      'targetSeasonObjective': targetSeasonObjective,
      'sharedRacesCount': sharedRacesCount,
      'sharedStagesCount': sharedStagesCount,
      'trainingCampsCount': trainingCampsCount,
      'cohesionScore': cohesionScore,
    };
  }

  factory DedicatedSquad.fromJson(Map<String, dynamic> json) {
    return DedicatedSquad(
      id: json['id'] as String,
      name: json['name'] as String,
      leaderRiderId: json['leaderRiderId'] as String,
      domestiqueRiderIds: (json['domestiqueRiderIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      targetSeasonObjective: json['targetSeasonObjective'] as String,
      sharedRacesCount: (json['sharedRacesCount'] as num?)?.toInt() ?? 0,
      sharedStagesCount: (json['sharedStagesCount'] as num?)?.toInt() ?? 0,
      trainingCampsCount: (json['trainingCampsCount'] as num?)?.toInt() ?? 0,
      cohesionScore: (json['cohesionScore'] as num?)?.toDouble() ?? 25.0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DedicatedSquad && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'DedicatedSquad($name, Lider: $leaderRiderId, Pomocnicy: ${domestiqueRiderIds.length}, Zgranie: ${cohesionScore.toStringAsFixed(1)}/100)';
}

/// Wyliczone bonusy synergii i chemii pociągu kolarskiego.
class SquadSynergyBonus {
  final String squadId;
  final String squadName;
  final double cohesionRating; // 0.0 - 100.0

  /// Bonus do efektywności osłony aerodynamicznej na kole (Drafting / Slipstream Efficiency)
  /// [np. +3.0% do +12.0% dodatkowej redukcji oporu powietrza dla kolarza osłanianego]
  final double draftingEfficiencyBonusPercent;

  /// Bonus do morale lidera i stabilności psychicznej pod presją [np. +5.0% do +15.0%]
  final double leaderMoraleBonusPercent;

  /// Dodatkowa moc pomocników w strefie beztlenowej przy nadawaniu tempa pod górę [Watów]
  final double domestiquePacingWattsBonus;

  /// Redukcja ryzyka kraksy i defektu dzięki zgraniu i zaufaniu w formacji [%]
  final double safetyCohesionBonusPercent;

  /// Zwięzłe podsumowanie taktyczne
  final String summaryDescription;

  const SquadSynergyBonus({
    required this.squadId,
    required this.squadName,
    required this.cohesionRating,
    required this.draftingEfficiencyBonusPercent,
    required this.leaderMoraleBonusPercent,
    required this.domestiquePacingWattsBonus,
    required this.safetyCohesionBonusPercent,
    required this.summaryDescription,
  });

  Map<String, dynamic> toJson() {
    return {
      'squadId': squadId,
      'squadName': squadName,
      'cohesionRating': cohesionRating,
      'draftingEfficiencyBonusPercent': draftingEfficiencyBonusPercent,
      'leaderMoraleBonusPercent': leaderMoraleBonusPercent,
      'domestiquePacingWattsBonus': domestiquePacingWattsBonus,
      'safetyCohesionBonusPercent': safetyCohesionBonusPercent,
      'summaryDescription': summaryDescription,
    };
  }

  factory SquadSynergyBonus.fromJson(Map<String, dynamic> json) {
    return SquadSynergyBonus(
      squadId: json['squadId'] as String,
      squadName: json['squadName'] as String,
      cohesionRating: (json['cohesionRating'] as num).toDouble(),
      draftingEfficiencyBonusPercent:
          (json['draftingEfficiencyBonusPercent'] as num).toDouble(),
      leaderMoraleBonusPercent:
          (json['leaderMoraleBonusPercent'] as num).toDouble(),
      domestiquePacingWattsBonus:
          (json['domestiquePacingWattsBonus'] as num).toDouble(),
      safetyCohesionBonusPercent:
          (json['safetyCohesionBonusPercent'] as num).toDouble(),
      summaryDescription: json['summaryDescription'] as String,
    );
  }

  @override
  String toString() =>
      'SquadSynergyBonus($squadName, Zgranie: ${cohesionRating.toStringAsFixed(1)}%, Aero: +${draftingEfficiencyBonusPercent.toStringAsFixed(1)}%, Morale: +${leaderMoraleBonusPercent.toStringAsFixed(1)}%)';
}

/// Rodzaj profesjonalnego zgrupowania / obozu treningowego dla wybranego pociągu kolarzy.
enum TrainingCampType {
  /// Obóz wysokogórski (Teneryfa / Teide lub Sierra Nevada) – hipoksja, zgranie pociągu górskiego
  teideAltitude,

  /// Rekonesans bruków Flandrii i Roubaix (Kortrijk) – technika jazdy, zgranie na wiatrach
  flemishCobbles,

  /// Wiosenny obóz bazy tlenowej i integracji (Calpe / Costa Blanca)
  calpeEndurance,

  /// Specjalistyczne warsztaty pociągu sprinterskiego i tunelu aerodynamicznego (Zolder)
  sprintTrainWorkshop;

  String toJson() => name;

  static TrainingCampType fromJson(String value) {
    return TrainingCampType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TrainingCampType.calpeEndurance,
    );
  }

  String get title {
    switch (this) {
      case TrainingCampType.teideAltitude:
        return 'Zgrupowanie wysokogórskie Teide (Teneryfa)';
      case TrainingCampType.flemishCobbles:
        return 'Rekonesans bruków Flandrii (Kortrijk)';
      case TrainingCampType.calpeEndurance:
        return 'Obóz integracyjny w Calpe (Hiszpania)';
      case TrainingCampType.sprintTrainWorkshop:
        return 'Warsztaty pociągu sprinterskiego i tunel aero';
    }
  }

  int get costEur {
    switch (this) {
      case TrainingCampType.teideAltitude:
        return 75000;
      case TrainingCampType.flemishCobbles:
        return 45000;
      case TrainingCampType.calpeEndurance:
        return 35000;
      case TrainingCampType.sprintTrainWorkshop:
        return 50000;
    }
  }

  int get durationDays {
    switch (this) {
      case TrainingCampType.teideAltitude:
        return 14;
      case TrainingCampType.flemishCobbles:
        return 7;
      case TrainingCampType.calpeEndurance:
        return 10;
      case TrainingCampType.sprintTrainWorkshop:
        return 5;
    }
  }
}

/// Rezultat odbytego zgrupowania treningowego dla składu.
class TrainingCampResult {
  final TrainingCampType campType;
  final String squadId;
  final String squadName;
  final int costEur;
  final double cohesionGained;
  final double newCohesionScore;
  final double moraleBoost;
  final String reportDescription;

  const TrainingCampResult({
    required this.campType,
    required this.squadId,
    required this.squadName,
    required this.costEur,
    required this.cohesionGained,
    required this.newCohesionScore,
    required this.moraleBoost,
    required this.reportDescription,
  });

  Map<String, dynamic> toJson() {
    return {
      'campType': campType.toJson(),
      'squadId': squadId,
      'squadName': squadName,
      'costEur': costEur,
      'cohesionGained': cohesionGained,
      'newCohesionScore': newCohesionScore,
      'moraleBoost': moraleBoost,
      'reportDescription': reportDescription,
    };
  }

  factory TrainingCampResult.fromJson(Map<String, dynamic> json) {
    return TrainingCampResult(
      campType: TrainingCampType.fromJson(json['campType'] as String),
      squadId: json['squadId'] as String,
      squadName: json['squadName'] as String,
      costEur: (json['costEur'] as num).toInt(),
      cohesionGained: (json['cohesionGained'] as num).toDouble(),
      newCohesionScore: (json['newCohesionScore'] as num).toDouble(),
      moraleBoost: (json['moraleBoost'] as num).toDouble(),
      reportDescription: json['reportDescription'] as String,
    );
  }

  @override
  String toString() =>
      'TrainingCampResult(${campType.title}, +${cohesionGained.toStringAsFixed(1)} pkt zgrania, koszt: €$costEur)';
}

/// Raport audytu hierarchii i ewentualnych konfliktów w zespole.
class TeamHierarchyAudit {
  final List<FranchiseRider> franchiseLeaders;
  final List<DedicatedSquad> squads;
  final double overallTeamHarmonyScore; // 0.0 - 100.0
  final bool hasConflicts;
  final List<String> warnings;
  final List<SquadSynergyBonus> squadSynergies;

  const TeamHierarchyAudit({
    required this.franchiseLeaders,
    required this.squads,
    required this.overallTeamHarmonyScore,
    required this.hasConflicts,
    required this.warnings,
    required this.squadSynergies,
  });
}

/// Serwis zarządzający hierarchią zespołu, wyznaczaniem 1-3 Głównych Liderów,
/// dedykowanymi pociągami pomocników oraz synergią i chemią szatni.
class TeamChemistryAndBuilderService {
  TeamChemistryAndBuilderService._();

  /// Maksymalna dozwolona liczba Głównych Liderów w drużynie (Franchise Riders)
  static const int maxFranchiseLeaders = 3;

  /// Wyznacza lub aktualizuje Głównych Liderów drużyny gracza (od 1 do maksymalnie 3 kolarzy).
  ///
  /// Kolarze wyznaczeni jako Główni Liderzy otrzymują priorytet w kalendarzu,
  /// dedykowaną ochronę pomocników oraz wyższą odporność na spadek morale.
  static ({CareerSave updatedSave, List<FranchiseRider> assignedLeaders}) setFranchiseLeaders({
    required CareerSave currentSave,
    required List<({String riderId, FranchiseRoleFocus focus, int priorityRank})> leaderAssignments,
  }) {
    if (leaderAssignments.isEmpty) {
      throw ArgumentError('Drużyna musi posiadać co najmniej 1 Głównego Lidera.');
    }
    if (leaderAssignments.length > maxFranchiseLeaders) {
      throw ArgumentError('Można wyznaczyć maksymalnie $maxFranchiseLeaders Głównych Liderów (Franchise Riders).');
    }

    final playerTeam = currentSave.playerTeam;
    final List<FranchiseRider> leaders = [];
    final Map<String, Rider> updatedRiders = {for (final r in currentSave.riders) r.id: r};

    // Weryfikacja unikalności i przynależności kolarzy
    final Set<String> checkedIds = {};
    for (final assignment in leaderAssignments) {
      if (checkedIds.contains(assignment.riderId)) {
        throw ArgumentError('Zdublowany kolarz na liście liderów: ${assignment.riderId}');
      }
      checkedIds.add(assignment.riderId);

      final rider = updatedRiders[assignment.riderId];
      if (rider == null || !playerTeam.rosterRiderIds.contains(rider.id)) {
        throw ArgumentError('Kolarz ${assignment.riderId} nie należy do drużyny gracza.');
      }

      // Aktualizujemy kontrakt kolarza na TeamLeader
      final updatedContract = rider.contract.copyWith(
        role: assignment.priorityRank == 1 ? RiderRole.teamLeader : RiderRole.coLeader,
        morale: math.min(1.0, rider.contract.morale + 0.08),
        leaderLoyalty: 1.0,
      );
      updatedRiders[rider.id] = rider.copyWith(contract: updatedContract);

      leaders.add(
        FranchiseRider(
          riderId: rider.id,
          riderName: rider.fullName,
          focus: assignment.focus,
          priorityRank: assignment.priorityRank,
        ),
      );
    }

    // Sortujemy po randze priorytetu (1, 2, 3)
    leaders.sort((a, b) => a.priorityRank.compareTo(b.priorityRank));

    final updatedSave = currentSave.copyWith(
      riders: updatedRiders.values.toList(),
      lastSavedAt: DateTime.now(),
    );

    return (updatedSave: updatedSave, assignedLeaders: leaders);
  }

  /// Tworzy dedykowany pociąg pomocników wokół wybranego lidera
  /// (np. "Skład pod Tour de France" lub "Skład pod Wiosenne Klasyki").
  static DedicatedSquad createDedicatedSquad({
    required String squadId,
    required String squadName,
    required String leaderRiderId,
    required List<String> domestiqueRiderIds,
    required String targetObjective,
    required List<Rider> allRiders,
  }) {
    if (domestiqueRiderIds.isEmpty) {
      throw ArgumentError('Pociąg pomocników musi zawierać co najmniej 1 pomocnika.');
    }
    if (domestiqueRiderIds.contains(leaderRiderId)) {
      throw ArgumentError('Lider nie może być jednocześnie wpisany jako pomocnik.');
    }

    // Wyliczamy bazowe zgranie startowe (np. wspólna narodowość daje +5 pkt)
    final leader = allRiders.firstWhere((r) => r.id == leaderRiderId);
    double initialCohesion = 25.0;

    int sameNationCount = 0;
    for (final dId in domestiqueRiderIds) {
      final dom = allRiders.firstWhere((r) => r.id == dId);
      if (dom.nationalityIso == leader.nationalityIso) {
        sameNationCount++;
      }
    }
    initialCohesion += (sameNationCount * 2.5);

    return DedicatedSquad(
      id: squadId,
      name: squadName,
      leaderRiderId: leaderRiderId,
      domestiqueRiderIds: List<String>.unmodifiable(domestiqueRiderIds),
      targetSeasonObjective: targetObjective,
      sharedRacesCount: 0,
      sharedStagesCount: 0,
      trainingCampsCount: 0,
      cohesionScore: initialCohesion.clamp(15.0, 50.0),
    );
  }

  /// Wylicza szczegółowe bonusy synergii dla dedykowanego pociągu kolarzy.
  ///
  /// Im dłużej ta sama grupa trenuje na obozach i startuje razem w wyścigach,
  /// tym wyższe oszczędności energii na kole (drafting) i wyższe morale lidera.
  static SquadSynergyBonus calculateSquadSynergy({
    required DedicatedSquad squad,
    required List<Rider> allRiders,
    CyclingTeam? team,
  }) {
    final double cohesion = squad.cohesionScore.clamp(0.0, 100.0);

    // 1. Bonus do efektywności draftingu (jazdy na kole w pociągu)
    // Zgrany skład oszczędza od +3.0% do +10.5% energii więcej na kole
    final double draftingBonus = 2.0 + (cohesion / 100.0) * 8.5;

    // 2. Bonus do morale lidera i psychicznej pewności siebie
    // Lider jadący ze swoimi stałymi 'gregari' zyskuje +4% do +15% morale
    final double moraleBonus = 3.0 + (cohesion / 100.0) * 12.0;

    // 3. Dodatkowa moc pomocników przy nadawaniu tempa (Pacing Watts Bonus)
    // Zaufanie do lidera wyzwala dodatkowe 8 - 25 Watów w kluczowych momentach
    final double pacingWattsBonus = 5.0 + (cohesion / 100.0) * 20.0;

    // 4. Bezpieczeństwo i unikanie kraks w peletonie
    final double safetyBonus = 5.0 + (cohesion / 100.0) * 20.0;

    String summary;
    if (cohesion >= 80.0) {
      summary = 'Perfekcyjnie zgrana maszyna. Pomocnicy czytają ruchy lidera w ułamku sekundy, oferując maksymalną osłonę aero (+${draftingBonus.toStringAsFixed(1)}%) i żelazne morale.';
    } else if (cohesion >= 55.0) {
      summary = 'Solidny, dobrze rozumiejący się skład. Dobre nawyki w peletonie (+${draftingBonus.toStringAsFixed(1)}% zysku na kole) i wysoka lojalność.';
    } else {
      summary = 'Nowo sformowany skład. Wymaga wspólnych obozów przygotowawczych i startów, aby osiągnąć pełną synergię na kole.';
    }

    return SquadSynergyBonus(
      squadId: squad.id,
      squadName: squad.name,
      cohesionRating: cohesion,
      draftingEfficiencyBonusPercent: double.parse(draftingBonus.toStringAsFixed(1)),
      leaderMoraleBonusPercent: double.parse(moraleBonus.toStringAsFixed(1)),
      domestiquePacingWattsBonus: double.parse(pacingWattsBonus.toStringAsFixed(1)),
      safetyCohesionBonusPercent: double.parse(safetyBonus.toStringAsFixed(1)),
      summaryDescription: summary,
    );
  }

  /// Aktualizuje zgranie składów po wspólnie przejechanym etapie wyścigu.
  ///
  /// Gdy kolarze z tego samego pociągu jadą w jednym etapie, ich chemia i zaufanie rosną.
  static List<DedicatedSquad> updateSquadsAfterStage({
    required List<DedicatedSquad> squads,
    required List<String> stageFinisherRiderIds,
  }) {
    return squads.map((squad) {
      final finishersSet = stageFinisherRiderIds.toSet();

      // Sprawdzamy, ilu członków pociągu (lider + pomocnicy) jechało w etapie
      final activeMembersCount = squad.allRiderIds.where((id) => finishersSet.contains(id)).length;

      // Jeśli w etapie brał udział lider oraz co najmniej 2 pomocników
      if (finishersSet.contains(squad.leaderRiderId) && activeMembersCount >= 3) {
        final double gain = 1.2 + (activeMembersCount * 0.35); // +2.0 do +4.0 pkt za etap
        final double newScore = math.min(100.0, squad.cohesionScore + gain);

        return squad.copyWith(
          sharedStagesCount: squad.sharedStagesCount + 1,
          cohesionScore: double.parse(newScore.toStringAsFixed(1)),
        );
      }

      return squad;
    }).toList();
  }

  /// Organizuje dedykowane zgrupowanie treningowe / obóz wysokogórski dla wybranego pociągu.
  ///
  /// Obóz potrąca koszt z budżetu drużyny, podnosi zgranie składu o +15.0 - +30.0 pkt
  /// oraz zwiększa bazę tlenową i morale kolarzy.
  static ({CareerSave updatedSave, TrainingCampResult result}) conductTrainingCamp({
    required CareerSave currentSave,
    required DedicatedSquad squad,
    required TrainingCampType campType,
  }) {
    final playerTeam = currentSave.playerTeam;
    final int costEur = campType.costEur;

    if (playerTeam.cashBalanceEur < costEur) {
      throw StateError('Niewystarczające środki w budżecie drużyny (€$costEur wymagane).');
    }

    // 1. Zgranie zyskiwane na obozie
    double cohesionGain;
    double moraleBoost;
    switch (campType) {
      case TrainingCampType.teideAltitude:
        cohesionGain = 28.0;
        moraleBoost = 0.12;
        break;
      case TrainingCampType.flemishCobbles:
        cohesionGain = 22.0;
        moraleBoost = 0.08;
        break;
      case TrainingCampType.calpeEndurance:
        cohesionGain = 20.0;
        moraleBoost = 0.10;
        break;
      case TrainingCampType.sprintTrainWorkshop:
        cohesionGain = 30.0;
        moraleBoost = 0.09;
        break;
    }

    final double newCohesion = math.min(100.0, squad.cohesionScore + cohesionGain);
    final updatedSquad = squad.copyWith(
      trainingCampsCount: squad.trainingCampsCount + 1,
      cohesionScore: double.parse(newCohesion.toStringAsFixed(1)),
    );

    // 2. Aktualizacja morale i bazy fizycznej kolarzy w kadrze
    final squadRiderIdsSet = squad.allRiderIds.toSet();
    final updatedRiders = currentSave.riders.map((r) {
      if (squadRiderIdsSet.contains(r.id)) {
        final updatedHealth = r.health.copyWith(
          morale: math.min(1.0, r.health.morale + moraleBoost),
          chronicTrainingLoadCtl: r.health.chronicTrainingLoadCtl + 6.0, // Wzrost formy tlenowej
        );
        return r.copyWith(health: updatedHealth);
      }
      return r;
    }).toList();

    // 3. Zapis transakcji finansowej
    final updatedTeams = currentSave.teams.map((t) {
      if (t.id == currentSave.playerTeamId) {
        return t.copyWith(cashBalanceEur: t.cashBalanceEur - costEur);
      }
      return t;
    }).toList();

    final ledgerEntry = CareerFinanceLedgerEntry(
      id: 'camp_${DateTime.now().millisecondsSinceEpoch}',
      date: currentSave.currentDate,
      category: FinanceCategory.facilityUpgrade,
      amountEur: -costEur,
      description: 'Zgrupowanie: ${campType.title} dla składu "${squad.name}"',
    );

    final updatedSave = currentSave.copyWith(
      teams: updatedTeams,
      riders: updatedRiders,
      financeLedger: [ledgerEntry, ...currentSave.financeLedger],
      lastSavedAt: DateTime.now(),
    );

    final result = TrainingCampResult(
      campType: campType,
      squadId: squad.id,
      squadName: squad.name,
      costEur: costEur,
      cohesionGained: cohesionGain,
      newCohesionScore: newCohesion,
      moraleBoost: moraleBoost,
      reportDescription: 'Pomyślnie ukończono ${campType.title}. Skład "${squad.name}" poprawił zgranie o +${cohesionGain.toStringAsFixed(1)} pkt (aktualnie: ${newCohesion.toStringAsFixed(1)}/100). Morale zespołu wzrosło.',
    );

    return (updatedSave: updatedSave, result: result);
  }

  /// Dokonuje całościowego audytu hierarchii i harmonii w szatni,
  /// ostrzegając przed ego-konfliktami i rywalizacją liderów.
  static TeamHierarchyAudit analyzeTeamHierarchy({
    required List<Rider> teamRoster,
    required List<FranchiseRider> franchiseLeaders,
    required List<DedicatedSquad> squads,
    CyclingTeam? team,
  }) {
    final List<String> warnings = [];
    double totalCohesion = 0.0;
    final List<SquadSynergyBonus> synergies = [];

    for (final squad in squads) {
      final syn = calculateSquadSynergy(squad: squad, allRiders: teamRoster, team: team);
      synergies.add(syn);
      totalCohesion += squad.cohesionScore;
    }

    final double avgCohesion = squads.isNotEmpty ? (totalCohesion / squads.length) : 50.0;

    // 1. Sprawdzenie, czy kolarz gwiazda nie został pominięty jako lider
    for (final r in teamRoster) {
      final bool isSuperstar = (r.physiology.criticalPowerWatts / r.physiology.weightKg) >= 6.0 ||
          r.potential >= 84;
      final bool isLeader = franchiseLeaders.any((fl) => fl.riderId == r.id);

      if (isSuperstar && !isLeader) {
        warnings.add('Gwiazda zespołu ${r.fullName} nie posiada statusu Głównego Lidera (Franchise Rider), co obniża jego lojalność.');
      }
    }

    // 2. Sprawdzenie konfliktów wewnątrz pociągów
    for (final squad in squads) {
      final domestiqueRiders = teamRoster.where((r) => squad.domestiqueRiderIds.contains(r.id)).toList();
      for (final dom in domestiqueRiders) {
        if (dom.contract.role == RiderRole.teamLeader) {
          warnings.add('W składzie "${squad.name}" kolarz ${dom.fullName} ma kontrakt lidera, lecz został przydzielony do roli pomocnika.');
        }
      }
    }

    final double harmonyScore = (avgCohesion - (warnings.length * 8.0)).clamp(10.0, 100.0);

    return TeamHierarchyAudit(
      franchiseLeaders: franchiseLeaders,
      squads: squads,
      overallTeamHarmonyScore: double.parse(harmonyScore.toStringAsFixed(1)),
      hasConflicts: warnings.isNotEmpty,
      warnings: warnings,
      squadSynergies: synergies,
    );
  }
}

