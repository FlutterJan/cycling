import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/career/rider_relationship_chemistry_web_model.dart';

/// Typ zgrupowania lub wydarzenia integracyjnego dla drużyny kolarskiej.
enum TeamBondingRetreatType {
  /// Górska chata w Alpach bez wyścigowej presji: głęboka odbudowa zaufania.
  alpsCabinRetreat,

  /// Kolacja integracyjna i degustacja: szybkie obniżenie napięcia w szatni.
  gastronomyAndWineEvening,

  /// Warsztat taktyczny i analiza wideo: uzgodnienie ról na Grand Tour.
  tacticalWarRoomWorkshop,

  /// Wyzwanie terenowe i team-building: przełamanie barier między frakcjami.
  outdoorSurvivalChallenge,

  /// Obóz wyciszający z zakazem mediów po kryzysie prasowym.
  mediaFreeDetoxCamp;

  String toJson() => name;

  static TeamBondingRetreatType fromJson(String? value) {
    if (value == null || value.isEmpty) {
      return TeamBondingRetreatType.gastronomyAndWineEvening;
    }
    return TeamBondingRetreatType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TeamBondingRetreatType.gastronomyAndWineEvening,
    );
  }

  String get displayNamePl {
    switch (this) {
      case TeamBondingRetreatType.alpsCabinRetreat:
        return 'Górska Chata w Alpach';
      case TeamBondingRetreatType.gastronomyAndWineEvening:
        return 'Kolacja Integracyjna Zespołu';
      case TeamBondingRetreatType.tacticalWarRoomWorkshop:
        return 'Warsztat Taktyczny & Wideo';
      case TeamBondingRetreatType.outdoorSurvivalChallenge:
        return 'Wyzwanie Terenowe Team-Building';
      case TeamBondingRetreatType.mediaFreeDetoxCamp:
        return 'Obóz Wyciszenia (Media Detox)';
    }
  }

  String get displayNameEn {
    switch (this) {
      case TeamBondingRetreatType.alpsCabinRetreat:
        return 'Alpine Cabin Retreat';
      case TeamBondingRetreatType.gastronomyAndWineEvening:
        return 'Team Gastronomy Evening';
      case TeamBondingRetreatType.tacticalWarRoomWorkshop:
        return 'Tactical War-Room Workshop';
      case TeamBondingRetreatType.outdoorSurvivalChallenge:
        return 'Outdoor Survival Challenge';
      case TeamBondingRetreatType.mediaFreeDetoxCamp:
        return 'Media-Free Detox Camp';
    }
  }
}

/// Strategia mediacji konfliktu między liderami lub zwaśnionymi kolarzami.
enum ConflictMediationApproach {
  /// Karta Wspólnego Przywództwa: jasny podział wyścigów i celów sezonowych.
  sharedLeadershipCharter,

  /// Zamknięte spotkanie w cztery oczy z dyrektorem sportowym.
  privateClearingAirSummit,

  /// Arbitraż doświadczonego kapitana szosy (Mentor Veteran).
  veteranCaptainArbitration,

  /// Twarde ultimatum menedżera narzucające hierarchię.
  authorityUltimatum,

  /// Wspólny długi trening w górach wymagający wzajemnej pomocy.
  jointTrainingPairChallenge;

  String toJson() => name;

  static ConflictMediationApproach fromJson(String? value) {
    if (value == null || value.isEmpty) {
      return ConflictMediationApproach.privateClearingAirSummit;
    }
    return ConflictMediationApproach.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ConflictMediationApproach.privateClearingAirSummit,
    );
  }

  String get displayNamePl {
    switch (this) {
      case ConflictMediationApproach.sharedLeadershipCharter:
        return 'Karta Wspólnego Przywództwa';
      case ConflictMediationApproach.privateClearingAirSummit:
        return 'Zamknięta Rozmowa Sztabu';
      case ConflictMediationApproach.veteranCaptainArbitration:
        return 'Arbitraż Kapitana Szosy';
      case ConflictMediationApproach.authorityUltimatum:
        return 'Ultimatum Dyrektora Sportowego';
      case ConflictMediationApproach.jointTrainingPairChallenge:
        return 'Wspólny Trening Par w Górach';
    }
  }

  String get descriptionPl {
    switch (this) {
      case ConflictMediationApproach.sharedLeadershipCharter:
        return 'Rozdziela cele Grand Tour i klasyki między liderów, eliminując rywalizację o ten sam wyścig.';
      case ConflictMediationApproach.privateClearingAirSummit:
        return 'Szczera rozmowa za zamkniętymi drzwiami bez kamer i agentów. Stabilna, bezpieczna opcja.';
      case ConflictMediationApproach.veteranCaptainArbitration:
        return 'Wykorzystuje autorytet weterana szatni do pogodzenia zwaśnionych gwiazd.';
      case ConflictMediationApproach.authorityUltimatum:
        return 'Twarde wymuszenie dyscypliny. Wysoka nagroda przy sukcesie, ale ryzyko eskalacji buntu.';
      case ConflictMediationApproach.jointTrainingPairChallenge:
        return '5-godzinna sesja na przełęczy wymagająca jazdy na zmianę i wzajemnego podawania bidonów.';
    }
  }

  double get baseSuccessRate {
    switch (this) {
      case ConflictMediationApproach.sharedLeadershipCharter:
        return 0.72;
      case ConflictMediationApproach.privateClearingAirSummit:
        return 0.68;
      case ConflictMediationApproach.veteranCaptainArbitration:
        return 0.74;
      case ConflictMediationApproach.authorityUltimatum:
        return 0.48;
      case ConflictMediationApproach.jointTrainingPairChallenge:
        return 0.64;
    }
  }
}

/// Wynik jakościowy próby mediacji konfliktu.
enum MediationOutcomeTier {
  /// Przełomowe pojednanie: duży skok relacji i spadek napięcia.
  breakthroughReconciliation,

  /// Konstruktywny rozejm: wyraźna poprawa i możliwość współpracy.
  constructiveTruce,

  /// Kruchy pokój: niewielki postęp, napięcie nadal wysokie.
  fragileColdPeace,

  /// Fiasko mediacji: eskalacja konfliktu i dalszy spadek relacji.
  mediationBackfire;

  String toJson() => name;

  static MediationOutcomeTier fromJson(String? value) {
    if (value == null || value.isEmpty) {
      return MediationOutcomeTier.constructiveTruce;
    }
    return MediationOutcomeTier.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => MediationOutcomeTier.constructiveTruce,
    );
  }

  String get displayNamePl {
    switch (this) {
      case MediationOutcomeTier.breakthroughReconciliation:
        return 'Przełomowe Pojednanie';
      case MediationOutcomeTier.constructiveTruce:
        return 'Konstruktywny Rozejm';
      case MediationOutcomeTier.fragileColdPeace:
        return 'Kruchy Pokój';
      case MediationOutcomeTier.mediationBackfire:
        return 'Eskalacja Konfliktu';
    }
  }
}

/// Szablon planu integracji drużynowej z parametrami kosztów i efektów.
@immutable
class TeamBondingRetreatPlan {
  final TeamBondingRetreatType retreatType;
  final String titlePl;
  final String descriptionPl;
  final int costEur;
  final int durationDays;
  final int baseChemistryGain;
  final int tensionReliefBonus;
  final int moraleBoost;
  final int fatigueCost;
  final int minSquadSize;

  const TeamBondingRetreatPlan({
    required this.retreatType,
    required this.titlePl,
    required this.descriptionPl,
    required this.costEur,
    required this.durationDays,
    required this.baseChemistryGain,
    required this.tensionReliefBonus,
    required this.moraleBoost,
    required this.fatigueCost,
    this.minSquadSize = 2,
  });
}

/// Wykryty konflikt lub napięcie w szatni kwalifikujące się do mediacji.
@immutable
class ConflictCaseSummary {
  final String pairKey;
  final String riderAId;
  final String riderBId;
  final String riderAName;
  final String riderBName;
  final int currentScore;
  final int tension;
  final int trust;
  final int respect;
  final RelationshipTier tier;
  final bool isStrainedBloodBrothers;
  final int severityScore;
  final ConflictMediationApproach recommendedApproach;

  const ConflictCaseSummary({
    required this.pairKey,
    required this.riderAId,
    required this.riderBId,
    required this.riderAName,
    required this.riderBName,
    required this.currentScore,
    required this.tension,
    required this.trust,
    required this.respect,
    required this.tier,
    required this.isStrainedBloodBrothers,
    required this.severityScore,
    required this.recommendedApproach,
  });

  bool get isCritical => currentScore <= -50 || tension >= 75;
}

/// Wynik przeprowadzonego zgrupowania lub wydarzenia integracyjnego.
@immutable
class TeamBondingRetreatResult {
  final bool success;
  final TeamBondingRetreatType retreatType;
  final String dateIso;
  final int costEur;
  final List<String> participatingRiderIds;
  final int pairsAffectedCount;
  final double averageChemistryDelta;
  final int teamMoraleDelta;
  final RiderRelationshipChemistryWebModel updatedChemistryModel;
  final String summary;

  const TeamBondingRetreatResult({
    required this.success,
    required this.retreatType,
    required this.dateIso,
    required this.costEur,
    required this.participatingRiderIds,
    required this.pairsAffectedCount,
    required this.averageChemistryDelta,
    required this.teamMoraleDelta,
    required this.updatedChemistryModel,
    required this.summary,
  });
}

/// Wynik pojedynczej sesji mediacji między dwoma kolarzami/liderami.
@immutable
class ConflictMediationResult {
  final bool success;
  final String riderAId;
  final String riderBId;
  final ConflictMediationApproach approach;
  final MediationOutcomeTier outcomeTier;
  final int scoreBefore;
  final int scoreAfter;
  final int tensionBefore;
  final int tensionAfter;
  final double successProbabilityUsed;
  final bool pactRestored;
  final RiderRelationshipChemistryWebModel updatedChemistryModel;
  final String summary;
  final String dateIso;

  const ConflictMediationResult({
    required this.success,
    required this.riderAId,
    required this.riderBId,
    required this.approach,
    required this.outcomeTier,
    required this.scoreBefore,
    required this.scoreAfter,
    required this.tensionBefore,
    required this.tensionAfter,
    required this.successProbabilityUsed,
    required this.pactRestored,
    required this.updatedChemistryModel,
    required this.summary,
    required this.dateIso,
  });

  int get scoreDelta => scoreAfter - scoreBefore;
}

/// Wpis w dzienniku interwencji szatniowych.
@immutable
class TeamBondingHistoryEntry {
  final String id;
  final String title;
  final String detail;
  final String dateIso;
  final bool isPositive;
  final bool isMediation;

  const TeamBondingHistoryEntry({
    required this.id,
    required this.title,
    required this.detail,
    required this.dateIso,
    required this.isPositive,
    required this.isMediation,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'detail': detail,
        'dateIso': dateIso,
        'isPositive': isPositive,
        'isMediation': isMediation,
      };

  factory TeamBondingHistoryEntry.fromJson(Map<String, dynamic> json) {
    return TeamBondingHistoryEntry(
      id: (json['id'] as String?) ?? 'hist_0',
      title: (json['title'] as String?) ?? '',
      detail: (json['detail'] as String?) ?? '',
      dateIso: (json['dateIso'] as String?) ?? '',
      isPositive: (json['isPositive'] as bool?) ?? true,
      isMediation: (json['isMediation'] as bool?) ?? false,
    );
  }
}

/// Serwis obsługujący integracje drużynowe oraz mediacje konfliktów między liderami.
class TeamBondingRetreatAndConflictMediationService {
  const TeamBondingRetreatAndConflictMediationService();

  /// Katalog dostępnych form integracji drużynowej.
  static const List<TeamBondingRetreatPlan> availableRetreatPlans =
      <TeamBondingRetreatPlan>[
    TeamBondingRetreatPlan(
      retreatType: TeamBondingRetreatType.gastronomyAndWineEvening,
      titlePl: 'Kolacja Integracyjna Zespołu',
      descriptionPl:
          'Wspólny wieczór poza hotelem wyścigowym. Błyskawicznie obniża napięcie i poprawia atmosferę przed klasykami.',
      costEur: 4500,
      durationDays: 1,
      baseChemistryGain: 6,
      tensionReliefBonus: 4,
      moraleBoost: 5,
      fatigueCost: 0,
    ),
    TeamBondingRetreatPlan(
      retreatType: TeamBondingRetreatType.tacticalWarRoomWorkshop,
      titlePl: 'Warsztat Taktyczny & Wideo',
      descriptionPl:
          'Wspólna analiza tras i klarowny podział zadań dla pociągu sprinterskiego oraz liderów GC.',
      costEur: 7500,
      durationDays: 2,
      baseChemistryGain: 8,
      tensionReliefBonus: 3,
      moraleBoost: 4,
      fatigueCost: 2,
    ),
    TeamBondingRetreatPlan(
      retreatType: TeamBondingRetreatType.outdoorSurvivalChallenge,
      titlePl: 'Wyzwanie Terenowe Team-Building',
      descriptionPl:
          'Zadania wymagające zaufania w parach poza rowerem. Świetnie łączy młode talenty z weteranami.',
      costEur: 14000,
      durationDays: 3,
      baseChemistryGain: 12,
      tensionReliefBonus: 6,
      moraleBoost: 8,
      fatigueCost: 5,
      minSquadSize: 4,
    ),
    TeamBondingRetreatPlan(
      retreatType: TeamBondingRetreatType.mediaFreeDetoxCamp,
      titlePl: 'Obóz Wyciszenia (Media Detox)',
      descriptionPl:
          'Odcięcie drużyny od prasy i mediów społecznościowych po głośnym konflikcie. Maksymalna redukcja napięć.',
      costEur: 19500,
      durationDays: 4,
      baseChemistryGain: 11,
      tensionReliefBonus: 12,
      moraleBoost: 7,
      fatigueCost: 1,
      minSquadSize: 3,
    ),
    TeamBondingRetreatPlan(
      retreatType: TeamBondingRetreatType.alpsCabinRetreat,
      titlePl: 'Górska Chata w Alpach',
      descriptionPl:
          'Prestiżowe 5-dniowe zgrupowanie przed Wielkim Tourem budujące braterstwo i gotowość do poświęceń.',
      costEur: 32000,
      durationDays: 5,
      baseChemistryGain: 16,
      tensionReliefBonus: 8,
      moraleBoost: 12,
      fatigueCost: 4,
      minSquadSize: 4,
    ),
  ];

  /// Zwraca plan dla wskazanego typu integracji.
  static TeamBondingRetreatPlan planFor(TeamBondingRetreatType type) {
    return availableRetreatPlans.firstWhere(
      (p) => p.retreatType == type,
      orElse: () => availableRetreatPlans.first,
    );
  }

  /// Wykrywa wszystkie aktywne konflikty i nadwyrężone relacje w szatni.
  List<ConflictCaseSummary> detectActiveConflicts(
    RiderRelationshipChemistryWebModel model,
  ) {
    final strainedPairKeys = <String>{
      for (final pact in model.bloodBrothersPacts)
        if (pact.status == BloodBrothersPactStatus.strained) pact.pairKey,
    };

    final hasMentorCaptain = model.profiles.values.any(
      (p) => p.archetype == LockerRoomPersonalityArchetype.mentorVeteran,
    );

    final conflicts = <ConflictCaseSummary>[];
    for (final edge in model.edges.values) {
      final isStrained = strainedPairKeys.contains(edge.pairKey);
      final hasConflict =
          edge.clampedScore < 0 || edge.tension >= 45 || isStrained;
      if (!hasConflict) continue;

      final profileA = model.profiles[edge.riderAId];
      final profileB = model.profiles[edge.riderBId];
      final nameA = profileA?.riderName ?? edge.riderAId;
      final nameB = profileB?.riderName ?? edge.riderBId;

      final negativePart = edge.clampedScore < 0 ? -edge.clampedScore : 0;
      final severity = ((negativePart * 0.65) +
              (edge.tension * 0.45) +
              (isStrained ? 18 : 0))
          .round()
          .clamp(1, 100);

      final recommended = _recommendApproachForPair(
        profileA: profileA,
        profileB: profileB,
        edge: edge,
        hasMentorCaptain: hasMentorCaptain,
      );

      conflicts.add(
        ConflictCaseSummary(
          pairKey: edge.pairKey,
          riderAId: edge.riderAId,
          riderBId: edge.riderBId,
          riderAName: nameA,
          riderBName: nameB,
          currentScore: edge.clampedScore,
          tension: edge.tension,
          trust: edge.trust,
          respect: edge.respect,
          tier: RelationshipTier.fromScore(
            edge.clampedScore,
            hasActiveBloodBrothersPact: edge.hasBloodBrothersPact,
          ),
          isStrainedBloodBrothers: isStrained,
          severityScore: severity,
          recommendedApproach: recommended,
        ),
      );
    }

    conflicts.sort((a, b) => b.severityScore.compareTo(a.severityScore));
    return List<ConflictCaseSummary>.unmodifiable(conflicts);
  }

  ConflictMediationApproach _recommendApproachForPair({
    required RiderLockerRoomProfile? profileA,
    required RiderLockerRoomProfile? profileB,
    required RiderRelationshipEdge edge,
    required bool hasMentorCaptain,
  }) {
    final bothAlpha =
        profileA?.archetype == LockerRoomPersonalityArchetype.alphaLeader &&
            profileB?.archetype == LockerRoomPersonalityArchetype.alphaLeader;
    if (bothAlpha) {
      return ConflictMediationApproach.sharedLeadershipCharter;
    }
    if (hasMentorCaptain && edge.tension >= 60) {
      return ConflictMediationApproach.veteranCaptainArbitration;
    }
    if (edge.clampedScore <= -45 && edge.respect >= 40) {
      return ConflictMediationApproach.jointTrainingPairChallenge;
    }
    return ConflictMediationApproach.privateClearingAirSummit;
  }

  /// Szacuje prawdopodobieństwo powodzenia mediacji (`0.05..0.95`).
  double estimateMediationSuccessProbability({
    required RiderRelationshipChemistryWebModel model,
    required String riderAId,
    required String riderBId,
    required ConflictMediationApproach approach,
    int managerAuthorityRating = 70,
  }) {
    if (riderAId == riderBId) return 0.0;
    final profileA = model.profiles[riderAId];
    final profileB = model.profiles[riderBId];
    if (profileA == null || profileB == null) return 0.0;

    final edge = model.getEdge(riderAId, riderBId);
    final score = edge?.clampedScore ?? 0;
    final tension = edge?.tension ?? 20;
    final respect = edge?.respect ?? 50;

    var prob = approach.baseSuccessRate;

    // Wpływ aktualnego stanu relacji i napięcia.
    prob += (score / 100.0) * 0.14;
    prob -= ((tension - 30).clamp(0, 70) / 100.0) * 0.20;
    prob += ((respect - 50) / 100.0) * 0.12;

    // Wpływ autorytetu dyrektora sportowego (szczególnie przy ultimatum).
    final authorityFactor = (managerAuthorityRating - 50) / 100.0;
    if (approach == ConflictMediationApproach.authorityUltimatum) {
      prob += authorityFactor * 0.35;
    } else {
      prob += authorityFactor * 0.12;
    }

    // Archetypy osobowości.
    final bothAlpha =
        profileA.archetype == LockerRoomPersonalityArchetype.alphaLeader &&
            profileB.archetype == LockerRoomPersonalityArchetype.alphaLeader;
    if (bothAlpha) {
      if (approach == ConflictMediationApproach.sharedLeadershipCharter) {
        prob += 0.12;
      } else if (approach == ConflictMediationApproach.authorityUltimatum) {
        prob -= 0.14;
      } else {
        prob -= 0.06;
      }
    }

    final hasJoker =
        profileA.archetype == LockerRoomPersonalityArchetype.lockerRoomJoker ||
            profileB.archetype == LockerRoomPersonalityArchetype.lockerRoomJoker;
    if (hasJoker) {
      prob += 0.06;
    }

    final hasMentorInTeam = model.profiles.values.any(
      (p) =>
          p.archetype == LockerRoomPersonalityArchetype.mentorVeteran &&
          p.riderId != riderAId &&
          p.riderId != riderBId,
    );
    if (approach == ConflictMediationApproach.veteranCaptainArbitration) {
      prob += hasMentorInTeam ? 0.14 : -0.18;
    }

    return prob.clamp(0.05, 0.95);
  }

  /// Organizuje integrację drużynową, aktualizując sieć relacji wszystkich uczestników.
  TeamBondingRetreatResult executeTeamBondingRetreat({
    required RiderRelationshipChemistryWebModel model,
    required TeamBondingRetreatType retreatType,
    required int availableBudgetEur,
    required String dateIso,
    List<String>? participantRiderIds,
  }) {
    final plan = planFor(retreatType);
    if (availableBudgetEur < plan.costEur) {
      return TeamBondingRetreatResult(
        success: false,
        retreatType: retreatType,
        dateIso: dateIso,
        costEur: 0,
        participatingRiderIds: const <String>[],
        pairsAffectedCount: 0,
        averageChemistryDelta: 0.0,
        teamMoraleDelta: 0,
        updatedChemistryModel: model,
        summary:
            'Niewystarczający budżet ($availableBudgetEur €) na ${plan.titlePl} (wymagane ${plan.costEur} €).',
      );
    }

    final requestedIds = participantRiderIds ??
        model.profiles.keys.toList(growable: false);
    final participants = requestedIds
        .where(model.profiles.containsKey)
        .toSet()
        .toList(growable: false);

    if (participants.length < plan.minSquadSize) {
      return TeamBondingRetreatResult(
        success: false,
        retreatType: retreatType,
        dateIso: dateIso,
        costEur: 0,
        participatingRiderIds: participants,
        pairsAffectedCount: 0,
        averageChemistryDelta: 0.0,
        teamMoraleDelta: 0,
        updatedChemistryModel: model,
        summary:
            'Za mało uczestników (${participants.length}). ${plan.titlePl} wymaga min. ${plan.minSquadSize} kolarzy.',
      );
    }

    final hasJoker = participants.any(
      (id) =>
          model.profiles[id]?.archetype ==
          LockerRoomPersonalityArchetype.lockerRoomJoker,
    );

    var workingModel = model;
    var pairsAffected = 0;
    var totalDelta = 0;

    for (var i = 0; i < participants.length; i++) {
      for (var j = i + 1; j < participants.length; j++) {
        final idA = participants[i];
        final idB = participants[j];
        final edge = workingModel.getEdge(idA, idB);
        final currentScore = edge?.clampedScore ?? 0;
        final currentTension = edge?.tension ?? 15;

        var pairGain = plan.baseChemistryGain;
        if (hasJoker) {
          pairGain += 2;
        }
        // Pary w konflikcie zyskują dodatkowo na neutralnym gruncie (kolacja / detox).
        if (currentScore < 0 || currentTension >= 50) {
          pairGain += (plan.tensionReliefBonus * 0.5).round();
        }
        // Pary blisko sufitu (+85..+100) rosną wolniej.
        if (currentScore >= 85) {
          pairGain = math.max(1, pairGain ~/ 2);
        }

        final opResult = workingModel.applyInteractionEvent(
          riderAId: idA,
          riderBId: idB,
          eventType: RelationshipEventType.trainingCampBonding,
          scoreDelta: pairGain,
          summary: '${plan.titlePl}: wspólna integracja zespołu.',
          dateIso: dateIso,
          incrementCampDays: plan.durationDays,
        );
        if (opResult.success) {
          workingModel = opResult.updatedModel;
          pairsAffected++;
          totalDelta += pairGain;
        }
      }
    }

    final avgDelta = pairsAffected == 0 ? 0.0 : totalDelta / pairsAffected;

    return TeamBondingRetreatResult(
      success: true,
      retreatType: retreatType,
      dateIso: dateIso,
      costEur: plan.costEur,
      participatingRiderIds: List<String>.unmodifiable(participants),
      pairsAffectedCount: pairsAffected,
      averageChemistryDelta: avgDelta,
      teamMoraleDelta: plan.moraleBoost,
      updatedChemistryModel: workingModel,
      summary:
          'Zakończono „${plan.titlePl}” (${participants.length} kolarzy, $pairsAffected relacji, średni zysk +${avgDelta.toStringAsFixed(1)} pkt, morale +${plan.moraleBoost}).',
    );
  }

  /// Przeprowadza mediację między dwoma liderami lub skonfliktowanymi kolarzami.
  ConflictMediationResult mediateLeaderConflict({
    required RiderRelationshipChemistryWebModel model,
    required String riderAId,
    required String riderBId,
    required ConflictMediationApproach approach,
    required String dateIso,
    int managerAuthorityRating = 70,
    double? overrideRoll,
    int? seed,
  }) {
    if (riderAId == riderBId ||
        !model.profiles.containsKey(riderAId) ||
        !model.profiles.containsKey(riderBId)) {
      return ConflictMediationResult(
        success: false,
        riderAId: riderAId,
        riderBId: riderBId,
        approach: approach,
        outcomeTier: MediationOutcomeTier.mediationBackfire,
        scoreBefore: 0,
        scoreAfter: 0,
        tensionBefore: 0,
        tensionAfter: 0,
        successProbabilityUsed: 0.0,
        pactRestored: false,
        updatedChemistryModel: model,
        summary: 'Nieprawidłowa para kolarzy do mediacji.',
        dateIso: dateIso,
      );
    }

    final edgeBefore = model.getEdge(riderAId, riderBId);
    final scoreBefore = edgeBefore?.clampedScore ?? 0;
    final tensionBefore = edgeBefore?.tension ?? 20;

    final prob = estimateMediationSuccessProbability(
      model: model,
      riderAId: riderAId,
      riderBId: riderBId,
      approach: approach,
      managerAuthorityRating: managerAuthorityRating,
    );

    final roll = (overrideRoll ??
            math.Random(seed ?? Object.hash(riderAId, riderBId, dateIso, approach))
                .nextDouble())
        .clamp(0.0, 1.0);

    final MediationOutcomeTier outcomeTier;
    final int scoreDelta;
    final RelationshipEventType eventType;
    final String summaryText;

    if (roll <= prob * 0.35) {
      outcomeTier = MediationOutcomeTier.breakthroughReconciliation;
      scoreDelta = approach == ConflictMediationApproach.authorityUltimatum
          ? 24
          : 28;
      eventType = RelationshipEventType.conflictMediationSuccess;
      summaryText =
          'Przełomowe pojednanie po „${approach.displayNamePl}” (+$scoreDelta pkt).';
    } else if (roll <= prob) {
      outcomeTier = MediationOutcomeTier.constructiveTruce;
      scoreDelta = 16;
      eventType = RelationshipEventType.conflictMediationSuccess;
      summaryText =
          'Zawarto konstruktywny rozejm dzięki „${approach.displayNamePl}” (+$scoreDelta pkt).';
    } else if (roll <= math.min(0.97, prob + 0.18)) {
      outcomeTier = MediationOutcomeTier.fragileColdPeace;
      scoreDelta = 5;
      eventType = RelationshipEventType.conflictMediationSuccess;
      summaryText =
          'Kruchy pokój po „${approach.displayNamePl}” (+$scoreDelta pkt). Napięcie nadal wyczuwalne.';
    } else {
      outcomeTier = MediationOutcomeTier.mediationBackfire;
      scoreDelta =
          approach == ConflictMediationApproach.authorityUltimatum ? -16 : -9;
      eventType = RelationshipEventType.leadershipClash;
      summaryText =
          'Mediacja „${approach.displayNamePl}” zakończyła się eskalacją sporu ($scoreDelta pkt).';
    }

    final opResult = model.applyInteractionEvent(
      riderAId: riderAId,
      riderBId: riderBId,
      eventType: eventType,
      scoreDelta: scoreDelta,
      summary: summaryText,
      dateIso: dateIso,
    );

    var updatedModel = opResult.updatedModel;
    var pactRestored = false;

    // Jeśli pakt Blood Brothers był nadwyrężony i mediacja dała przełom (+70+), przywróć status active.
    final pairKey = RiderRelationshipEdge.canonicalPairKey(riderAId, riderBId);
    final edgeAfter = updatedModel.getEdge(riderAId, riderBId);
    final scoreAfter = edgeAfter?.clampedScore ?? scoreBefore;
    final tensionAfter = edgeAfter?.tension ?? tensionBefore;

    if (outcomeTier == MediationOutcomeTier.breakthroughReconciliation &&
        scoreAfter >= 70) {
      final pacts = List<BloodBrothersPact>.from(updatedModel.bloodBrothersPacts);
      final idx = pacts.indexWhere(
        (p) =>
            p.pairKey == pairKey && p.status == BloodBrothersPactStatus.strained,
      );
      if (idx != -1) {
        pacts[idx] = pacts[idx].copyWith(
          status: BloodBrothersPactStatus.active,
          loyaltyStrength: math.max(85, scoreAfter),
        );
        updatedModel = RiderRelationshipChemistryWebModel(
          teamId: updatedModel.teamId,
          seasonYear: updatedModel.seasonYear,
          profiles: updatedModel.profiles,
          edges: updatedModel.edges,
          bloodBrothersPacts: List<BloodBrothersPact>.unmodifiable(pacts),
          recentEvents: updatedModel.recentEvents,
        );
        pactRestored = true;
      }
    }

    final nameA = model.profiles[riderAId]?.riderName ?? riderAId;
    final nameB = model.profiles[riderBId]?.riderName ?? riderBId;

    return ConflictMediationResult(
      success: outcomeTier != MediationOutcomeTier.mediationBackfire,
      riderAId: riderAId,
      riderBId: riderBId,
      approach: approach,
      outcomeTier: outcomeTier,
      scoreBefore: scoreBefore,
      scoreAfter: scoreAfter,
      tensionBefore: tensionBefore,
      tensionAfter: tensionAfter,
      successProbabilityUsed: prob,
      pactRestored: pactRestored,
      updatedChemistryModel: updatedModel,
      summary: '$nameA ↔ $nameB: $summaryText',
      dateIso: dateIso,
    );
  }
}

/// Stan zarządzany przez Riverpod dla modułu integracji i mediacji w szatni.
@immutable
class TeamBondingAndMediationState {
  final RiderRelationshipChemistryWebModel chemistryModel;
  final int teamBudgetEur;
  final int teamMorale;
  final int managerAuthorityRating;
  final TeamBondingRetreatType selectedRetreatType;
  final ConflictMediationApproach selectedMediationApproach;
  final String? selectedConflictPairKey;
  final TeamBondingRetreatResult? lastRetreatResult;
  final ConflictMediationResult? lastMediationResult;
  final List<TeamBondingHistoryEntry> history;
  final String? statusBannerMessage;
  final bool statusBannerIsError;

  const TeamBondingAndMediationState({
    required this.chemistryModel,
    required this.teamBudgetEur,
    required this.teamMorale,
    this.managerAuthorityRating = 72,
    this.selectedRetreatType = TeamBondingRetreatType.gastronomyAndWineEvening,
    this.selectedMediationApproach =
        ConflictMediationApproach.sharedLeadershipCharter,
    this.selectedConflictPairKey,
    this.lastRetreatResult,
    this.lastMediationResult,
    this.history = const <TeamBondingHistoryEntry>[],
    this.statusBannerMessage,
    this.statusBannerIsError = false,
  });

  TeamBondingAndMediationState copyWith({
    RiderRelationshipChemistryWebModel? chemistryModel,
    int? teamBudgetEur,
    int? teamMorale,
    int? managerAuthorityRating,
    TeamBondingRetreatType? selectedRetreatType,
    ConflictMediationApproach? selectedMediationApproach,
    String? selectedConflictPairKey,
    bool clearSelectedConflictPairKey = false,
    TeamBondingRetreatResult? lastRetreatResult,
    ConflictMediationResult? lastMediationResult,
    List<TeamBondingHistoryEntry>? history,
    String? statusBannerMessage,
    bool clearStatusBanner = false,
    bool? statusBannerIsError,
  }) {
    return TeamBondingAndMediationState(
      chemistryModel: chemistryModel ?? this.chemistryModel,
      teamBudgetEur: teamBudgetEur ?? this.teamBudgetEur,
      teamMorale: teamMorale ?? this.teamMorale,
      managerAuthorityRating:
          managerAuthorityRating ?? this.managerAuthorityRating,
      selectedRetreatType: selectedRetreatType ?? this.selectedRetreatType,
      selectedMediationApproach:
          selectedMediationApproach ?? this.selectedMediationApproach,
      selectedConflictPairKey: clearSelectedConflictPairKey
          ? null
          : (selectedConflictPairKey ?? this.selectedConflictPairKey),
      lastRetreatResult: lastRetreatResult ?? this.lastRetreatResult,
      lastMediationResult: lastMediationResult ?? this.lastMediationResult,
      history: history ?? this.history,
      statusBannerMessage: clearStatusBanner
          ? null
          : (statusBannerMessage ?? this.statusBannerMessage),
      statusBannerIsError: statusBannerIsError ?? this.statusBannerIsError,
    );
  }
}

/// Kontroler Riverpod obsługujący integracje drużynowe i mediacje konfliktów.
class TeamBondingAndMediationNotifier
    extends StateNotifier<TeamBondingAndMediationState> {
  final TeamBondingRetreatAndConflictMediationService _service;

  TeamBondingAndMediationNotifier({
    required TeamBondingRetreatAndConflictMediationService service,
    required TeamBondingAndMediationState initialState,
  })  : _service = service,
        super(initialState);

  void selectRetreatType(TeamBondingRetreatType type) {
    state = state.copyWith(
      selectedRetreatType: type,
      clearStatusBanner: true,
    );
  }

  void selectMediationApproach(ConflictMediationApproach approach) {
    state = state.copyWith(
      selectedMediationApproach: approach,
      clearStatusBanner: true,
    );
  }

  void selectConflictPair(String? pairKey) {
    state = state.copyWith(
      selectedConflictPairKey: pairKey,
      clearSelectedConflictPairKey: pairKey == null,
      clearStatusBanner: true,
    );
  }

  TeamBondingRetreatResult runTeamRetreat({
    required String dateIso,
    List<String>? participantRiderIds,
  }) {
    final result = _service.executeTeamBondingRetreat(
      model: state.chemistryModel,
      retreatType: state.selectedRetreatType,
      availableBudgetEur: state.teamBudgetEur,
      dateIso: dateIso,
      participantRiderIds: participantRiderIds,
    );

    if (!result.success) {
      state = state.copyWith(
        lastRetreatResult: result,
        statusBannerMessage: result.summary,
        statusBannerIsError: true,
      );
      return result;
    }

    final entry = TeamBondingHistoryEntry(
      id: 'retreat_${dateIso}_${state.history.length + 1}',
      title: TeamBondingRetreatAndConflictMediationService.planFor(
        result.retreatType,
      ).titlePl,
      detail: result.summary,
      dateIso: dateIso,
      isPositive: true,
      isMediation: false,
    );

    state = state.copyWith(
      chemistryModel: result.updatedChemistryModel,
      teamBudgetEur: state.teamBudgetEur - result.costEur,
      teamMorale: (state.teamMorale + result.teamMoraleDelta).clamp(0, 100),
      lastRetreatResult: result,
      history: List<TeamBondingHistoryEntry>.unmodifiable(
        <TeamBondingHistoryEntry>[entry, ...state.history].take(30),
      ),
      statusBannerMessage: result.summary,
      statusBannerIsError: false,
    );

    return result;
  }

  ConflictMediationResult runConflictMediation({
    required String riderAId,
    required String riderBId,
    required String dateIso,
    double? overrideRoll,
    int? seed,
  }) {
    final result = _service.mediateLeaderConflict(
      model: state.chemistryModel,
      riderAId: riderAId,
      riderBId: riderBId,
      approach: state.selectedMediationApproach,
      dateIso: dateIso,
      managerAuthorityRating: state.managerAuthorityRating,
      overrideRoll: overrideRoll,
      seed: seed,
    );

    final entry = TeamBondingHistoryEntry(
      id: 'med_${dateIso}_${state.history.length + 1}',
      title: result.outcomeTier.displayNamePl,
      detail: result.summary,
      dateIso: dateIso,
      isPositive: result.success,
      isMediation: true,
    );

    final remainingConflicts =
        _service.detectActiveConflicts(result.updatedChemistryModel);
    final nextSelectedKey = remainingConflicts.any(
      (c) => c.pairKey == state.selectedConflictPairKey,
    )
        ? state.selectedConflictPairKey
        : (remainingConflicts.isNotEmpty
            ? remainingConflicts.first.pairKey
            : null);

    state = state.copyWith(
      chemistryModel: result.updatedChemistryModel,
      lastMediationResult: result,
      selectedConflictPairKey: nextSelectedKey,
      clearSelectedConflictPairKey: nextSelectedKey == null,
      history: List<TeamBondingHistoryEntry>.unmodifiable(
        <TeamBondingHistoryEntry>[entry, ...state.history].take(30),
      ),
      statusBannerMessage: result.summary,
      statusBannerIsError: !result.success,
    );

    return result;
  }

  void clearStatusBanner() {
    state = state.copyWith(clearStatusBanner: true);
  }
}

final teamBondingAndMediationServiceProvider =
    Provider<TeamBondingRetreatAndConflictMediationService>((ref) {
  return const TeamBondingRetreatAndConflictMediationService();
});

final teamBondingAndMediationProvider = StateNotifierProvider.autoDispose<
    TeamBondingAndMediationNotifier, TeamBondingAndMediationState>((ref) {
  final service = ref.watch(teamBondingAndMediationServiceProvider);
  final demoModel = _buildDefaultShowcaseModel();
  final conflicts = service.detectActiveConflicts(demoModel);
  return TeamBondingAndMediationNotifier(
    service: service,
    initialState: TeamBondingAndMediationState(
      chemistryModel: demoModel,
      teamBudgetEur: 125000,
      teamMorale: 68,
      selectedConflictPairKey:
          conflicts.isNotEmpty ? conflicts.first.pairKey : null,
    ),
  );
});

RiderRelationshipChemistryWebModel _buildDefaultShowcaseModel() {
  final base = RiderRelationshipChemistryWebModel.fromRoster(
    teamId: 'team_apex',
    seasonYear: 2026,
    roster: const <RiderLockerRoomProfile>[
      RiderLockerRoomProfile(
        riderId: 'r_leader_1',
        riderName: 'K. Majka',
        archetype: LockerRoomPersonalityArchetype.alphaLeader,
        leadershipWeight: 92,
        egoLevel: 85,
        adaptability: 60,
        currentMorale: 72,
        isTeamCaptain: true,
      ),
      RiderLockerRoomProfile(
        riderId: 'r_leader_2',
        riderName: 'M. Kwiatkowski',
        archetype: LockerRoomPersonalityArchetype.alphaLeader,
        leadershipWeight: 88,
        egoLevel: 80,
        adaptability: 65,
        currentMorale: 74,
      ),
      RiderLockerRoomProfile(
        riderId: 'r_vet',
        riderName: 'T. Marczyński',
        archetype: LockerRoomPersonalityArchetype.mentorVeteran,
        leadershipWeight: 74,
        egoLevel: 40,
        adaptability: 85,
        currentMorale: 80,
      ),
      RiderLockerRoomProfile(
        riderId: 'r_joker',
        riderName: 'S. Aniołkowski',
        archetype: LockerRoomPersonalityArchetype.lockerRoomJoker,
        leadershipWeight: 62,
        egoLevel: 45,
        adaptability: 90,
        currentMorale: 82,
      ),
      RiderLockerRoomProfile(
        riderId: 'r_dom',
        riderName: 'Ł. Owsian',
        archetype: LockerRoomPersonalityArchetype.humbleDomestique,
        leadershipWeight: 54,
        egoLevel: 30,
        adaptability: 88,
        currentMorale: 78,
      ),
    ],
  );

  return base
      .applyInteractionEvent(
        riderAId: 'r_leader_1',
        riderBId: 'r_leader_2',
        eventType: RelationshipEventType.leadershipClash,
        scoreDelta: -36,
        summary: 'Spór o rolę jedynego lidera na Tour de France.',
        dateIso: '2026-06-12',
      )
      .updatedModel;
}

/// Produkcyjny panel UI integracji drużynowych i mediacji między liderami.
class TeamBondingRetreatAndConflictMediationPanel extends ConsumerWidget {
  final String currentDateIso;

  const TeamBondingRetreatAndConflictMediationPanel({
    super.key,
    this.currentDateIso = '2026-06-18',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(teamBondingAndMediationProvider);
    final notifier = ref.read(teamBondingAndMediationProvider.notifier);
    final service = ref.watch(teamBondingAndMediationServiceProvider);

    final summary = state.chemistryModel.calculateOverallTeamChemistry();
    final conflicts = service.detectActiveConflicts(state.chemistryModel);

    final selectedConflict = conflicts.isEmpty
        ? null
        : conflicts.firstWhere(
            (c) => c.pairKey == state.selectedConflictPairKey,
            orElse: () => conflicts.first,
          );

    return Container(
      color: AppColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 960;
          final isCompact = constraints.maxWidth < 520;
          final padding = isCompact ? 12.0 : 20.0;

          return SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _HeaderOverviewCard(
                  summary: summary,
                  budgetEur: state.teamBudgetEur,
                  morale: state.teamMorale,
                  conflictsCount: conflicts.length,
                  isCompact: isCompact,
                ),
                if (state.statusBannerMessage != null) ...<Widget>[
                  const SizedBox(height: 12),
                  _StatusFeedbackBanner(
                    message: state.statusBannerMessage!,
                    isError: state.statusBannerIsError,
                    onDismiss: notifier.clearStatusBanner,
                  ),
                ],
                const SizedBox(height: 16),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: _RetreatSectionCard(
                          state: state,
                          onSelectRetreat: notifier.selectRetreatType,
                          onExecuteRetreat: () => notifier.runTeamRetreat(
                            dateIso: currentDateIso,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _MediationSectionCard(
                          state: state,
                          service: service,
                          conflicts: conflicts,
                          selectedConflict: selectedConflict,
                          onSelectConflict: notifier.selectConflictPair,
                          onSelectApproach: notifier.selectMediationApproach,
                          onExecuteMediation: selectedConflict == null
                              ? null
                              : () => notifier.runConflictMediation(
                                    riderAId: selectedConflict.riderAId,
                                    riderBId: selectedConflict.riderBId,
                                    dateIso: currentDateIso,
                                  ),
                        ),
                      ),
                    ],
                  )
                else ...<Widget>[
                  _RetreatSectionCard(
                    state: state,
                    onSelectRetreat: notifier.selectRetreatType,
                    onExecuteRetreat: () => notifier.runTeamRetreat(
                      dateIso: currentDateIso,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _MediationSectionCard(
                    state: state,
                    service: service,
                    conflicts: conflicts,
                    selectedConflict: selectedConflict,
                    onSelectConflict: notifier.selectConflictPair,
                    onSelectApproach: notifier.selectMediationApproach,
                    onExecuteMediation: selectedConflict == null
                        ? null
                        : () => notifier.runConflictMediation(
                              riderAId: selectedConflict.riderAId,
                              riderBId: selectedConflict.riderBId,
                              dateIso: currentDateIso,
                            ),
                  ),
                ],
                if (state.history.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 16),
                  _HistoryLogCard(history: state.history),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeaderOverviewCard extends StatelessWidget {
  final TeamChemistrySummary summary;
  final int budgetEur;
  final int morale;
  final int conflictsCount;
  final bool isCompact;

  const _HeaderOverviewCard({
    required this.summary,
    required this.budgetEur,
    required this.morale,
    required this.conflictsCount,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    final atmosphereColor = summary.overallScore >= 65
        ? AppColors.statusSuccess
        : (summary.overallScore >= 45
            ? AppColors.accentBlue
            : AppColors.crimsonAlert);

    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primaryAccent.withValues(alpha: 0.5),
                  ),
                ),
                child: const Icon(
                  Icons.diversity_3_rounded,
                  color: AppColors.goldAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Integracja Szatni & Mediacje Liderów',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Atmosfera: ${summary.atmosphere.displayNamePl}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: atmosphereColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _MetricChip(
                label: 'Chemia Zespołu',
                value: summary.overallScore.toStringAsFixed(1),
                color: atmosphereColor,
              ),
              _MetricChip(
                label: 'Morale',
                value: '$morale%',
                color: AppColors.accentBlue,
              ),
              _MetricChip(
                label: 'Budżet',
                value: '$budgetEur €',
                color: AppColors.goldAccent,
              ),
              _MetricChip(
                label: 'Konflikty',
                value: '$conflictsCount',
                color: conflictsCount > 0
                    ? AppColors.crimsonAlert
                    : AppColors.statusSuccess,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
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
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusFeedbackBanner extends StatelessWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  const _StatusFeedbackBanner({
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isError ? AppColors.crimsonAlert : AppColors.statusSuccess;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            isError ? Icons.warning_amber_rounded : Icons.check_circle_outline,
            color: accent,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: const Icon(Icons.close, size: 16),
            color: AppColors.textSecondary,
            tooltip: 'Zamknij komunikat',
          ),
        ],
      ),
    );
  }
}

class _RetreatSectionCard extends StatelessWidget {
  final TeamBondingAndMediationState state;
  final ValueChanged<TeamBondingRetreatType> onSelectRetreat;
  final VoidCallback onExecuteRetreat;

  const _RetreatSectionCard({
    required this.state,
    required this.onSelectRetreat,
    required this.onExecuteRetreat,
  });

  @override
  Widget build(BuildContext context) {
    final selectedPlan =
        TeamBondingRetreatAndConflictMediationService.planFor(
      state.selectedRetreatType,
    );
    final canAfford = state.teamBudgetEur >= selectedPlan.costEur &&
        state.chemistryModel.profiles.length >= selectedPlan.minSquadSize;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'Integracje Drużynowe',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Wybierz formę integracji, aby odbudować chemię i morale całego składu.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ...TeamBondingRetreatAndConflictMediationService
              .availableRetreatPlans
              .map(
            (plan) {
              final isSelected =
                  plan.retreatType == state.selectedRetreatType;
              final affordable = state.teamBudgetEur >= plan.costEur;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _InteractiveOptionCard(
                  isSelected: isSelected,
                  isDisabled: !affordable,
                  onTap: () => onSelectRetreat(plan.retreatType),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              plan.titlePl,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            '${plan.costEur} €',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: affordable
                                  ? AppColors.goldAccent
                                  : AppColors.crimsonAlert,
                              fontFeatures: const <FontFeature>[
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        plan.descriptionPl,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: <Widget>[
                          _MiniTag(
                            text: '+${plan.baseChemistryGain} Chemia',
                            color: AppColors.statusSuccess,
                          ),
                          _MiniTag(
                            text: '+${plan.moraleBoost}% Morale',
                            color: AppColors.accentBlue,
                          ),
                          _MiniTag(
                            text: '${plan.durationDays} dni',
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          _ActionButton(
            label: 'Zorganizuj Integrację (${selectedPlan.costEur} €)',
            icon: Icons.groups_rounded,
            enabled: canAfford,
            onPressed: canAfford ? onExecuteRetreat : null,
          ),
        ],
      ),
    );
  }
}

class _MediationSectionCard extends StatelessWidget {
  final TeamBondingAndMediationState state;
  final TeamBondingRetreatAndConflictMediationService service;
  final List<ConflictCaseSummary> conflicts;
  final ConflictCaseSummary? selectedConflict;
  final ValueChanged<String?> onSelectConflict;
  final ValueChanged<ConflictMediationApproach> onSelectApproach;
  final VoidCallback? onExecuteMediation;

  const _MediationSectionCard({
    required this.state,
    required this.service,
    required this.conflicts,
    required this.selectedConflict,
    required this.onSelectConflict,
    required this.onSelectApproach,
    required this.onExecuteMediation,
  });

  @override
  Widget build(BuildContext context) {
    final estimatedProb = selectedConflict == null
        ? 0.0
        : service.estimateMediationSuccessProbability(
            model: state.chemistryModel,
            riderAId: selectedConflict!.riderAId,
            riderBId: selectedConflict!.riderBId,
            approach: state.selectedMediationApproach,
            managerAuthorityRating: state.managerAuthorityRating,
          );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'Mediacja Konfliktów Liderów',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Rozwiązuj spory o przywództwo i obniżaj napięcie w szatni przed startem.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          if (conflicts.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.statusSuccess.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.statusSuccess.withValues(alpha: 0.35),
                ),
              ),
              child: const Row(
                children: <Widget>[
                  Icon(
                    Icons.verified_rounded,
                    color: AppColors.statusSuccess,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Brak aktywnych konfliktów w szatni. Liderzy współpracują zgodnie z planem.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...<Widget>[
            ...conflicts.map((conflict) {
              final isSelected =
                  selectedConflict?.pairKey == conflict.pairKey;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _InteractiveOptionCard(
                  isSelected: isSelected,
                  onTap: () => onSelectConflict(conflict.pairKey),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        conflict.isCritical
                            ? Icons.local_fire_department_rounded
                            : Icons.balance_rounded,
                        color: conflict.isCritical
                            ? AppColors.crimsonAlert
                            : AppColors.amberWarning,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              '${conflict.riderAName} ↔ ${conflict.riderBName}',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Relacja: ${conflict.currentScore} • Napięcie: ${conflict.tension}%',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11.5,
                                color: AppColors.textSecondary,
                                fontFeatures: <FontFeature>[
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      _MiniTag(
                        text: 'Ryzyko ${conflict.severityScore}',
                        color: conflict.isCritical
                            ? AppColors.crimsonAlert
                            : AppColors.amberWarning,
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 10),
            const Text(
              'Strategia Mediacji',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ...ConflictMediationApproach.values.map((approach) {
              final isSelected =
                  approach == state.selectedMediationApproach;
              final isRecommended =
                  selectedConflict?.recommendedApproach == approach;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _InteractiveOptionCard(
                  isSelected: isSelected,
                  onTap: () => onSelectApproach(approach),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              approach.displayNamePl,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (isRecommended)
                            const _MiniTag(
                              text: 'Zalecane',
                              color: AppColors.goldAccent,
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        approach.descriptionPl,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            _ActionButton(
              label:
                  'Przeprowadź Mediację (Szansa ${(estimatedProb * 100).round()}%)',
              icon: Icons.handshake_rounded,
              enabled: onExecuteMediation != null,
              onPressed: onExecuteMediation,
            ),
          ],
        ],
      ),
    );
  }
}

class _HistoryLogCard extends StatelessWidget {
  final List<TeamBondingHistoryEntry> history;

  const _HistoryLogCard({required this.history});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Dziennik Szatni',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ...history.take(5).map(
            (entry) {
              final accent = entry.isPositive
                  ? AppColors.statusSuccess
                  : AppColors.crimsonAlert;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      entry.isMediation
                          ? Icons.handshake_outlined
                          : Icons.groups_outlined,
                      size: 16,
                      color: accent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${entry.dateIso} • ${entry.detail}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InteractiveOptionCard extends StatefulWidget {
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;
  final Widget child;

  const _InteractiveOptionCard({
    required this.isSelected,
    this.isDisabled = false,
    required this.onTap,
    required this.child,
  });

  @override
  State<_InteractiveOptionCard> createState() => _InteractiveOptionCardState();
}

class _InteractiveOptionCardState extends State<_InteractiveOptionCard> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isSelected
        ? AppColors.goldAccent
        : (_isFocused
            ? AppColors.accentBlue
            : (_isHovered
                ? AppColors.primaryAccent
                : AppColors.cardBorder));

    final bgColor = widget.isSelected
        ? AppColors.primaryAccent.withValues(alpha: 0.16)
        : (_isPressed
            ? AppColors.surfaceLight.withValues(alpha: 0.9)
            : (_isHovered
                ? AppColors.surfaceLight
                : AppColors.surfaceLight.withValues(alpha: 0.6)));

    return FocusableActionDetector(
      enabled: !widget.isDisabled,
      onShowHoverHighlight: (hovered) => setState(() => _isHovered = hovered),
      onShowFocusHighlight: (focused) => setState(() => _isFocused = focused),
      child: GestureDetector(
        onTapDown: widget.isDisabled
            ? null
            : (_) => setState(() => _isPressed = true),
        onTapUp: widget.isDisabled
            ? null
            : (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.isDisabled ? null : widget.onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          opacity: widget.isDisabled ? 0.5 : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor,
                width: widget.isSelected ? 1.5 : 1.0,
              ),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = !widget.enabled
        ? AppColors.surfaceLight
        : (_isPressed
            ? AppColors.primaryAccent.withValues(alpha: 0.75)
            : (_isHovered
                ? AppColors.primaryAccent.withValues(alpha: 0.95)
                : AppColors.primaryAccent));

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (h) => setState(() => _isHovered = h),
      onShowFocusHighlight: (f) => setState(() => _isFocused = f),
      child: InkWell(
        onTap: widget.enabled ? widget.onPressed : null,
        onHighlightChanged: (p) => setState(() => _isPressed = p),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isFocused
                  ? AppColors.goldAccent
                  : (widget.enabled
                      ? AppColors.goldAccent.withValues(alpha: 0.5)
                      : AppColors.cardBorder),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                widget.icon,
                size: 18,
                color: widget.enabled
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: widget.enabled
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
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

class _MiniTag extends StatelessWidget {
  final String text;
  final Color color;

  const _MiniTag({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: color,
          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
