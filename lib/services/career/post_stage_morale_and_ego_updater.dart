// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import '../../engine/simulation/stage_results_calculator.dart';
import '../../models/race/race_stage.dart';
import '../../models/rider/rider.dart';
import '../../models/rider/rider_contract.dart';
import 'rider_ego_and_conflicts_service.dart';

/// Kategoria zdarzenia nastrojowego po zakończeniu etapu.
enum PostStageMoraleEventType {
  stageVictoryTeamSurge,
  leaderJerseyTakenSurge,
  leaderJerseyRetainedBoost,
  podiumFinishBoost,
  leaderUnprotectedInCrosswind,
  sprinterNoLeadoutTrainFrustration,
  stageDnfOrOtlSetback;

  String toJson() => name;

  static PostStageMoraleEventType fromJson(String value) {
    return PostStageMoraleEventType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => PostStageMoraleEventType.podiumFinishBoost,
    );
  }

  String get labelPl {
    switch (this) {
      case PostStageMoraleEventType.stageVictoryTeamSurge:
        return 'Zwycięstwo etapowe (+Morale całej ekipy)';
      case PostStageMoraleEventType.leaderJerseyTakenSurge:
        return 'Przejęcie koszulki lidera (+Euforia w zespole)';
      case PostStageMoraleEventType.leaderJerseyRetainedBoost:
        return 'Obrona koszulki lidera (+Stabilizacja morale)';
      case PostStageMoraleEventType.podiumFinishBoost:
        return 'Podium etapowe (+Morale)';
      case PostStageMoraleEventType.leaderUnprotectedInCrosswind:
        return 'Brak ochrony lidera na wietrze (-Morale i lojalność)';
      case PostStageMoraleEventType.sprinterNoLeadoutTrainFrustration:
        return 'Brak pociągu sprinterskiego na płaskim finiszu (Frustracja)';
      case PostStageMoraleEventType.stageDnfOrOtlSetback:
        return 'Wycofanie / Limit czasu na etapie (-Morale)';
    }
  }
}

/// Pojedyncza przyczyna zmiany morale, lojalności lub presji ego u kolarza.
class MoraleChangeReason {
  final PostStageMoraleEventType eventType;
  final double moraleDelta;
  final double loyaltyDelta;
  final double egoPressureDelta;
  final String descriptionPl;

  const MoraleChangeReason({
    required this.eventType,
    required this.moraleDelta,
    required this.loyaltyDelta,
    required this.egoPressureDelta,
    required this.descriptionPl,
  });

  Map<String, dynamic> toJson() => {
        'eventType': eventType.toJson(),
        'moraleDelta': moraleDelta,
        'loyaltyDelta': loyaltyDelta,
        'egoPressureDelta': egoPressureDelta,
        'descriptionPl': descriptionPl,
      };

  factory MoraleChangeReason.fromJson(Map<String, dynamic> json) {
    return MoraleChangeReason(
      eventType: PostStageMoraleEventType.fromJson(json['eventType'] as String),
      moraleDelta: (json['moraleDelta'] as num).toDouble(),
      loyaltyDelta: (json['loyaltyDelta'] as num).toDouble(),
      egoPressureDelta: (json['egoPressureDelta'] as num).toDouble(),
      descriptionPl: json['descriptionPl'] as String,
    );
  }
}

/// Szczegółowy bilans zmian nastroju i ego pojedynczego kolarza po etapie.
class RiderMoraleAndEgoDelta {
  final String riderId;
  final String riderName;
  final double moraleBefore;
  final double moraleAfter;
  final double moraleDelta;
  final double loyaltyBefore;
  final double loyaltyAfter;
  final double loyaltyDelta;
  final double egoPressureDelta;
  final List<MoraleChangeReason> reasons;

  const RiderMoraleAndEgoDelta({
    required this.riderId,
    required this.riderName,
    required this.moraleBefore,
    required this.moraleAfter,
    required this.moraleDelta,
    required this.loyaltyBefore,
    required this.loyaltyAfter,
    required this.loyaltyDelta,
    required this.egoPressureDelta,
    required this.reasons,
  });

  bool get hasNetChange =>
      moraleDelta.abs() > 0.001 ||
      loyaltyDelta.abs() > 0.001 ||
      egoPressureDelta.abs() > 0.001;

  String get narrativeSummaryPl {
    if (reasons.isEmpty) return 'Brak istotnych zmian nastroju po etapie.';
    return reasons.map((r) => r.descriptionPl).join(' • ');
  }
}

/// Kontekst taktyczno-wynikowy zakończonego etapu przekazywany do procesora nastrojów.
class PostStageMoraleContext {
  final String raceId;
  final String raceName;
  final RaceStage stage;
  final String teamId;
  final List<OfficialRiderStageResult> teamResults;

  /// Identyfikator kolarza drużyny wyznaczonego jako główny lider (np. GC) na ten etap.
  final String? designatedLeaderId;

  /// Identyfikator kolarza drużyny wyznaczonego jako główny sprinter na ten etap.
  final String? designatedSprinterId;

  /// Czy kolarz naszej drużyny przejął koszulkę lidera klasyfikacji generalnej (GC) po tym etapie.
  final bool tookGcLeaderJersey;

  /// Czy kolarz naszej drużyny obronił posiadaną już koszulkę lidera GC.
  final bool retainedGcLeaderJersey;

  /// Czy kolarz naszej drużyny przejął koszulkę punktową lub górską.
  final bool tookSecondaryJersey;

  /// Identyfikator kolarza, który zdobył lub obronił koszulkę lidera.
  final String? jerseyHolderRiderId;

  /// Odsetek czasu/dystansu stref wiatru bocznego, w których lider miał osłonę kolegów (0.0 - 1.0).
  final double leaderWindProtectionRatio;

  /// Liczba pomocników przypisanych do osłony lidera na wietrze.
  final int leaderProtectedDomestiquesCount;

  /// Strata czasowa poniesiona przez lidera bezpośrednio na rantach / wietrze bocznym [s].
  final double leaderCrosswindTimeLossSeconds;

  /// Czy na płaskim/sprinterskim etapie zorganizowano pociąg rozprowadzający dla sprintera.
  final bool sprintTrainOrganized;

  /// Liczba kolarzy wyznaczonych do pociągu sprinterskiego w finale.
  final int sprintLeadoutRidersCount;

  /// Jakość wsparcia pociągu w ostatnich 3 km (0.0 - 1.0).
  final double sprintLeadoutSupportRatio;

  /// Czy etap zakończył się masowym finiszem peletonu (np. nawet na etapie pagórkowatym).
  final bool isBunchSprintFinish;

  /// Opcjonalne profile psychologiczne kolarzy (jeśli brak, generowane deterministycznie).
  final Map<String, RiderPersonalityProfile> personalityProfilesByRiderId;

  /// Data zakończenia etapu (używana w ewentualnych raportach incydentów).
  final DateTime? stageDate;

  const PostStageMoraleContext({
    required this.raceId,
    required this.raceName,
    required this.stage,
    required this.teamId,
    required this.teamResults,
    this.designatedLeaderId,
    this.designatedSprinterId,
    this.tookGcLeaderJersey = false,
    this.retainedGcLeaderJersey = false,
    this.tookSecondaryJersey = false,
    this.jerseyHolderRiderId,
    this.leaderWindProtectionRatio = 1.0,
    this.leaderProtectedDomestiquesCount = 1,
    this.leaderCrosswindTimeLossSeconds = 0.0,
    this.sprintTrainOrganized = true,
    this.sprintLeadoutRidersCount = 2,
    this.sprintLeadoutSupportRatio = 1.0,
    this.isBunchSprintFinish = false,
    this.personalityProfilesByRiderId = const {},
    this.stageDate,
  });
}

/// Wynik zbiorczy aktualizacji morale, lojalności i ego po etapie.
class PostStageMoraleUpdateReport {
  final List<Rider> updatedSquad;
  final Map<String, RiderMoraleAndEgoDelta> riderDeltas;
  final List<PostStageMoraleEventType> triggeredEvents;
  final List<TeamConflictIncident> generatedIncidents;
  final double teamAverageMoraleBefore;
  final double teamAverageMoraleAfter;
  final String headlinePl;

  const PostStageMoraleUpdateReport({
    required this.updatedSquad,
    required this.riderDeltas,
    required this.triggeredEvents,
    required this.generatedIncidents,
    required this.teamAverageMoraleBefore,
    required this.teamAverageMoraleAfter,
    required this.headlinePl,
  });

  double get teamAverageMoraleDelta =>
      teamAverageMoraleAfter - teamAverageMoraleBefore;

  RiderMoraleAndEgoDelta? deltaForRider(String riderId) =>
      riderDeltas[riderId];
}

/// Procesor nastrojów po etapie (`PostStageMoraleAndEgoUpdater`):
/// - podnosi morale całej ekipy po zwycięstwie etapowym lub przejęciu koszulki lidera,
/// - obniża morale i lojalność lidera w przypadku braku ochrony na wietrze bocznym,
/// - generuje frustrację sprintera (oraz ryzyko konfliktu), gdy na płaskim finiszu
///   nie zorganizowano mu pociągu rozprowadzającego.
class PostStageMoraleAndEgoUpdater {
  const PostStageMoraleAndEgoUpdater._();

  static const double _minMorale100 = 5.0;
  static const double _maxMorale100 = 100.0;
  static const double _minLoyalty100 = 5.0;
  static const double _maxLoyalty100 = 100.0;

  /// Przetwarza nastroje całego składu po zakończonym etapie i zwraca zaktualizowanych
  /// kolarzy oraz pełny raport przyczyn i ewentualnych incydentów ego.
  static PostStageMoraleUpdateReport processPostStageMoraleAndEgo({
    required List<Rider> squadRiders,
    required PostStageMoraleContext context,
  }) {
    if (squadRiders.isEmpty) {
      return const PostStageMoraleUpdateReport(
        updatedSquad: [],
        riderDeltas: {},
        triggeredEvents: [],
        generatedIncidents: [],
        teamAverageMoraleBefore: 0.0,
        teamAverageMoraleAfter: 0.0,
        headlinePl: 'Brak kolarzy w składzie do aktualizacji nastrojów.',
      );
    }

    final Map<String, OfficialRiderStageResult> resultsByRiderId = {
      for (final res in context.teamResults) res.riderId: res,
    };

    final OfficialRiderStageResult? stageWinnerResult = context.teamResults
        .where((r) => r.rank == 1 && !r.isDnf && !r.isEliminatedOtl)
        .cast<OfficialRiderStageResult?>()
        .firstOrNull;

    final OfficialRiderStageResult? bestPodiumResult = context.teamResults
        .where(
            (r) => r.rank >= 2 && r.rank <= 3 && !r.isDnf && !r.isEliminatedOtl)
        .cast<OfficialRiderStageResult?>()
        .firstOrNull;

    final bool hasTeamStageWin = stageWinnerResult != null;
    final bool hasTeamPodium = !hasTeamStageWin && bestPodiumResult != null;
    final bool hasLeaderJerseyTakeover = context.tookGcLeaderJersey;
    final bool hasLeaderJerseyRetained =
        !hasLeaderJerseyTakeover && context.retainedGcLeaderJersey;

    final Rider? designatedLeader = _resolveDesignatedLeader(
      squadRiders: squadRiders,
      designatedLeaderId: context.designatedLeaderId,
    );
    final Rider? designatedSprinter = _resolveDesignatedSprinter(
      squadRiders: squadRiders,
      designatedSprinterId: context.designatedSprinterId,
    );

    final bool hasWindExposure = _hasSignificantCrosswind(context.stage);
    final bool leaderUnprotectedOnWind = designatedLeader != null &&
        hasWindExposure &&
        (context.leaderWindProtectionRatio < 0.45 ||
            context.leaderProtectedDomestiquesCount <= 0 ||
            context.leaderCrosswindTimeLossSeconds >= 15.0);

    final bool isFlatSprintStage =
        context.stage.stageType == StageType.flat || context.isBunchSprintFinish;
    final OfficialRiderStageResult? sprinterResult = designatedSprinter != null
        ? resultsByRiderId[designatedSprinter.id]
        : null;
    final bool sprinterWonStage =
        sprinterResult != null && sprinterResult.rank == 1;
    final bool sprinterWithoutTrain = designatedSprinter != null &&
        isFlatSprintStage &&
        !sprinterWonStage &&
        (sprinterResult == null || (!sprinterResult.isDnf && !sprinterResult.isEliminatedOtl)) &&
        (!context.sprintTrainOrganized ||
            context.sprintLeadoutRidersCount <= 0 ||
            context.sprintLeadoutSupportRatio < 0.35);

    final Set<PostStageMoraleEventType> triggeredEvents = {};
    final List<TeamConflictIncident> incidents = [];
    final Map<String, RiderMoraleAndEgoDelta> deltas = {};
    final List<Rider> updatedSquad = [];

    if (hasTeamStageWin) {
      triggeredEvents.add(PostStageMoraleEventType.stageVictoryTeamSurge);
    } else if (hasTeamPodium) {
      triggeredEvents.add(PostStageMoraleEventType.podiumFinishBoost);
    }
    if (hasLeaderJerseyTakeover) {
      triggeredEvents.add(PostStageMoraleEventType.leaderJerseyTakenSurge);
    } else if (hasLeaderJerseyRetained) {
      triggeredEvents.add(PostStageMoraleEventType.leaderJerseyRetainedBoost);
    }
    if (leaderUnprotectedOnWind) {
      triggeredEvents
          .add(PostStageMoraleEventType.leaderUnprotectedInCrosswind);
    }
    if (sprinterWithoutTrain) {
      triggeredEvents
          .add(PostStageMoraleEventType.sprinterNoLeadoutTrainFrustration);
    }

    double sumMoraleBefore = 0.0;
    double sumMoraleAfter = 0.0;

    for (final rider in squadRiders) {
      final profile = context.personalityProfilesByRiderId[rider.id] ??
          RiderEgoAndConflictsService.generatePersonalityProfile(rider);
      final result = resultsByRiderId[rider.id];

      final List<MoraleChangeReason> reasons = [];
      double moraleDelta = 0.0;
      double loyaltyDelta = 0.0;
      double egoPressureDelta = 0.0;

      // 1. Zwycięstwo etapowe (wzrost morale całej ekipy)
      if (hasTeamStageWin) {
        final bool isWinner = stageWinnerResult.riderId == rider.id;
        final double winMorale = isWinner ? 14.0 : 7.5;
        final double winLoyalty = isWinner ? 6.0 : 4.0;
        final double winEgo = isWinner ? -6.0 : -2.0;

        moraleDelta += winMorale;
        loyaltyDelta += winLoyalty;
        egoPressureDelta += winEgo;
        reasons.add(
          MoraleChangeReason(
            eventType: PostStageMoraleEventType.stageVictoryTeamSurge,
            moraleDelta: winMorale,
            loyaltyDelta: winLoyalty,
            egoPressureDelta: winEgo,
            descriptionPl: isWinner
                ? 'Zwycięstwo etapowe (${stageWinnerResult.riderName}) — ogromny zastrzyk pewności siebie.'
                : 'Zwycięstwo kolegi z ekipy (${stageWinnerResult.riderName}) — euforia w autobusie drużyny.',
          ),
        );
      } else if (hasTeamPodium) {
        final bool isPodiumRider = bestPodiumResult.riderId == rider.id;
        final double podMorale = isPodiumRider ? 6.0 : 2.5;
        final double podLoyalty = isPodiumRider ? 2.5 : 1.5;

        moraleDelta += podMorale;
        loyaltyDelta += podLoyalty;
        reasons.add(
          MoraleChangeReason(
            eventType: PostStageMoraleEventType.podiumFinishBoost,
            moraleDelta: podMorale,
            loyaltyDelta: podLoyalty,
            egoPressureDelta: 0.0,
            descriptionPl: isPodiumRider
                ? 'Podium etapu (#${bestPodiumResult.rank}) podbudowuje nastroje.'
                : 'Podium zespołu (#${bestPodiumResult.rank}) poprawia atmosferę w ekipie.',
          ),
        );
      }

      // 2. Przejęcie lub obrona koszulki lidera (wzrost morale całej ekipy)
      if (hasLeaderJerseyTakeover) {
        final bool isHolder = context.jerseyHolderRiderId == rider.id ||
            (context.jerseyHolderRiderId == null &&
                designatedLeader?.id == rider.id);
        final double jerseyMorale = isHolder ? 12.0 : 8.0;
        final double jerseyLoyalty = isHolder ? 8.0 : 5.0;
        final double jerseyEgo = isHolder ? -5.0 : -3.0;

        moraleDelta += jerseyMorale;
        loyaltyDelta += jerseyLoyalty;
        egoPressureDelta += jerseyEgo;
        reasons.add(
          MoraleChangeReason(
            eventType: PostStageMoraleEventType.leaderJerseyTakenSurge,
            moraleDelta: jerseyMorale,
            loyaltyDelta: jerseyLoyalty,
            egoPressureDelta: jerseyEgo,
            descriptionPl: isHolder
                ? 'Przejęcie koszulki lidera GC! Pełna mobilizacja i duma.'
                : 'Ekipa przejęła koszulkę lidera GC — rośnie duch zespołu.',
          ),
        );
      } else if (hasLeaderJerseyRetained) {
        final bool isHolder = context.jerseyHolderRiderId == rider.id ||
            (context.jerseyHolderRiderId == null &&
                designatedLeader?.id == rider.id);
        final double retainMorale = isHolder ? 4.0 : 2.5;
        final double retainLoyalty = isHolder ? 2.5 : 1.5;

        moraleDelta += retainMorale;
        loyaltyDelta += retainLoyalty;
        reasons.add(
          MoraleChangeReason(
            eventType: PostStageMoraleEventType.leaderJerseyRetainedBoost,
            moraleDelta: retainMorale,
            loyaltyDelta: retainLoyalty,
            egoPressureDelta: 0.0,
            descriptionPl: 'Obrona koszulki lidera GC stabilizuje morale ekipy.',
          ),
        );
      } else if (context.tookSecondaryJersey) {
        final bool isHolder = context.jerseyHolderRiderId == rider.id;
        final double secMorale = isHolder ? 6.5 : 3.5;
        final double secLoyalty = isHolder ? 3.0 : 2.0;

        moraleDelta += secMorale;
        loyaltyDelta += secLoyalty;
        reasons.add(
          MoraleChangeReason(
            eventType: PostStageMoraleEventType.leaderJerseyTakenSurge,
            moraleDelta: secMorale,
            loyaltyDelta: secLoyalty,
            egoPressureDelta: -1.5,
            descriptionPl:
                'Zdobycie koszulki klasyfikacji pobocznej wzmacnia morale zespołu.',
          ),
        );
      }

      // 3. Spadek morale lidera przy braku ochrony na wietrze
      if (leaderUnprotectedOnWind && rider.id == designatedLeader.id) {
        final double protectionGap =
            (1.0 - context.leaderWindProtectionRatio.clamp(0.0, 1.0));
        final double timeLossFactor =
            (context.leaderCrosswindTimeLossSeconds / 30.0).clamp(0.0, 2.0);
        final double egoMultiplier =
            profile.archetype == PersonalityArchetype.alphaLeader ||
                    profile.archetype ==
                        PersonalityArchetype.youngAmbitiousChallenger
                ? 1.25
                : 1.0;

        final double windMoralePenalty = -((8.0 +
                    protectionGap * 8.0 +
                    timeLossFactor * 5.0) *
                egoMultiplier)
            .clamp(6.0, 26.0);
        final double windLoyaltyPenalty = -((6.0 +
                    protectionGap * 6.0 +
                    timeLossFactor * 4.0) *
                egoMultiplier)
            .clamp(5.0, 22.0);
        final double windEgoSpike =
            (10.0 + protectionGap * 12.0).clamp(8.0, 24.0);

        moraleDelta += windMoralePenalty;
        loyaltyDelta += windLoyaltyPenalty;
        egoPressureDelta += windEgoSpike;
        reasons.add(
          MoraleChangeReason(
            eventType: PostStageMoraleEventType.leaderUnprotectedInCrosswind,
            moraleDelta: windMoralePenalty,
            loyaltyDelta: windLoyaltyPenalty,
            egoPressureDelta: windEgoSpike,
            descriptionPl: context.leaderCrosswindTimeLossSeconds >= 15.0
                ? 'Brak osłony na wietrze bocznym i strata ${context.leaderCrosswindTimeLossSeconds.round()}s na rantach wywołały wściekłość lidera.'
                : 'Lider był osamotniony na bocznym wietrze bez wsparcia pomocników.',
          ),
        );

        if (profile.egoLevel >= 70 ||
            context.leaderCrosswindTimeLossSeconds >= 45.0) {
          incidents.add(
            _buildCrosswindConflictIncident(
              leader: rider,
              context: context,
              moraleDamage: windMoralePenalty.abs(),
            ),
          );
        }
      }

      // 4. Frustracja sprintera bez zorganizowanego pociągu na płaskim finiszu
      if (sprinterWithoutTrain && rider.id == designatedSprinter.id) {
        final double trainGap =
            (1.0 - context.sprintLeadoutSupportRatio.clamp(0.0, 1.0));
        final bool isPrimaDonna =
            profile.archetype == PersonalityArchetype.primaDonnaSprinter;
        final double sprinterMultiplier = isPrimaDonna ? 1.35 : 1.0;
        final bool missedTopTen =
            sprinterResult != null && sprinterResult.rank > 10;

        final double trainMoralePenalty = -((9.0 +
                    trainGap * 7.0 +
                    (missedTopTen ? 4.0 : 0.0)) *
                sprinterMultiplier)
            .clamp(8.0, 28.0);
        final double trainLoyaltyPenalty = -((7.0 +
                    trainGap * 6.0 +
                    (missedTopTen ? 3.0 : 0.0)) *
                sprinterMultiplier)
            .clamp(6.0, 24.0);
        final double trainEgoSpike =
            ((12.0 + trainGap * 10.0) * sprinterMultiplier).clamp(10.0, 30.0);

        moraleDelta += trainMoralePenalty;
        loyaltyDelta += trainLoyaltyPenalty;
        egoPressureDelta += trainEgoSpike;
        reasons.add(
          MoraleChangeReason(
            eventType:
                PostStageMoraleEventType.sprinterNoLeadoutTrainFrustration,
            moraleDelta: trainMoralePenalty,
            loyaltyDelta: trainLoyaltyPenalty,
            egoPressureDelta: trainEgoSpike,
            descriptionPl:
                'Brak zorganizowanego pociągu na płaskim finiszu sfrustrował sprintera (${rider.fullName}).',
          ),
        );

        if (isPrimaDonna ||
            profile.mediaDramaProneness >= 65 ||
            context.sprintLeadoutRidersCount <= 0) {
          incidents.add(
            _buildSprinterNoTrainIncident(
              sprinter: rider,
              context: context,
              moraleDamage: trainMoralePenalty.abs(),
            ),
          );
        }
      }

      // 5. DNF / OTL na etapie
      if (result != null && (result.isDnf || result.isEliminatedOtl)) {
        triggeredEvents.add(PostStageMoraleEventType.stageDnfOrOtlSetback);
        const double dnfMorale = -10.0;
        moraleDelta += dnfMorale;
        reasons.add(
          MoraleChangeReason(
            eventType: PostStageMoraleEventType.stageDnfOrOtlSetback,
            moraleDelta: dnfMorale,
            loyaltyDelta: 0.0,
            egoPressureDelta: 0.0,
            descriptionPl: result.isDnf
                ? 'Wycofanie z etapu (DNF) obniża morale kolarza.'
                : 'Przekroczenie limitu czasu (OTL) obniża morale kolarza.',
          ),
        );
      }

      final double rawMoraleBefore = rider.contract.morale;
      final double rawLoyaltyBefore = rider.contract.leaderLoyalty;
      final bool usesNormalizedMoraleScale = rawMoraleBefore <= 1.0;
      final bool usesNormalizedLoyaltyScale = rawLoyaltyBefore <= 1.0;

      final double appliedMoraleDelta =
          usesNormalizedMoraleScale ? moraleDelta / 100.0 : moraleDelta;
      final double appliedLoyaltyDelta =
          usesNormalizedLoyaltyScale ? loyaltyDelta / 100.0 : loyaltyDelta;

      final double rawMoraleAfter = usesNormalizedMoraleScale
          ? (rawMoraleBefore + appliedMoraleDelta).clamp(0.05, 1.0)
          : (rawMoraleBefore + appliedMoraleDelta)
              .clamp(_minMorale100, _maxMorale100);

      final double rawLoyaltyAfter = usesNormalizedLoyaltyScale
          ? (rawLoyaltyBefore + appliedLoyaltyDelta).clamp(0.05, 1.0)
          : (rawLoyaltyBefore + appliedLoyaltyDelta)
              .clamp(_minLoyalty100, _maxLoyalty100);

      final double normalizedBefore =
          usesNormalizedMoraleScale ? rawMoraleBefore * 100.0 : rawMoraleBefore;
      final double normalizedAfter =
          usesNormalizedMoraleScale ? rawMoraleAfter * 100.0 : rawMoraleAfter;

      sumMoraleBefore += normalizedBefore;
      sumMoraleAfter += normalizedAfter;

      final updatedRider = rider.copyWith(
        contract: rider.contract.copyWith(
          morale: rawMoraleAfter,
          leaderLoyalty: rawLoyaltyAfter,
        ),
      );
      updatedSquad.add(updatedRider);

      deltas[rider.id] = RiderMoraleAndEgoDelta(
        riderId: rider.id,
        riderName: rider.fullName,
        moraleBefore: rawMoraleBefore,
        moraleAfter: rawMoraleAfter,
        moraleDelta: rawMoraleAfter - rawMoraleBefore,
        loyaltyBefore: rawLoyaltyBefore,
        loyaltyAfter: rawLoyaltyAfter,
        loyaltyDelta: rawLoyaltyAfter - rawLoyaltyBefore,
        egoPressureDelta: egoPressureDelta,
        reasons: List<MoraleChangeReason>.unmodifiable(reasons),
      );
    }

    final double avgBefore = sumMoraleBefore / squadRiders.length;
    final double avgAfter = sumMoraleAfter / squadRiders.length;

    return PostStageMoraleUpdateReport(
      updatedSquad: List<Rider>.unmodifiable(updatedSquad),
      riderDeltas: Map<String, RiderMoraleAndEgoDelta>.unmodifiable(deltas),
      triggeredEvents:
          List<PostStageMoraleEventType>.unmodifiable(triggeredEvents),
      generatedIncidents: List<TeamConflictIncident>.unmodifiable(incidents),
      teamAverageMoraleBefore: avgBefore,
      teamAverageMoraleAfter: avgAfter,
      headlinePl: _buildHeadlinePl(
        triggeredEvents: triggeredEvents,
        avgDelta: avgAfter - avgBefore,
        winnerName: stageWinnerResult?.riderName,
        leaderName: designatedLeader?.fullName,
        sprinterName: designatedSprinter?.fullName,
      ),
    );
  }

  static bool _hasSignificantCrosswind(RaceStage stage) {
    if (stage.weatherCondition == WeatherCondition.crosswindGale) return true;
    if (stage.windSpeedKmh >= 25.0) return true;
    if (stage.windSpeedKmh >= 18.0) {
      for (final seg in stage.segments) {
        final double angleRad =
            (seg.windDirectionDegrees - seg.roadBearingDegrees) *
                math.pi /
                180.0;
        if (math.sin(angleRad).abs() >= 0.5) return true;
      }
    }
    return false;
  }

  static Rider? _resolveDesignatedLeader({
    required List<Rider> squadRiders,
    required String? designatedLeaderId,
  }) {
    if (designatedLeaderId != null) {
      for (final rider in squadRiders) {
        if (rider.id == designatedLeaderId) return rider;
      }
    }
    for (final rider in squadRiders) {
      if (rider.contract.role == RiderRole.teamLeader) return rider;
    }
    for (final rider in squadRiders) {
      if (rider.contract.role == RiderRole.coLeader) return rider;
    }
    return null;
  }

  static Rider? _resolveDesignatedSprinter({
    required List<Rider> squadRiders,
    required String? designatedSprinterId,
  }) {
    if (designatedSprinterId != null) {
      for (final rider in squadRiders) {
        if (rider.id == designatedSprinterId) return rider;
      }
    }
    for (final rider in squadRiders) {
      if (rider.contract.role == RiderRole.sprinter) return rider;
    }
    for (final rider in squadRiders) {
      if (rider.specialization == RiderSpecialization.pureSprinter ||
          rider.specialization == RiderSpecialization.versatileSprinter) {
        return rider;
      }
    }
    return null;
  }

  static TeamConflictIncident _buildCrosswindConflictIncident({
    required Rider leader,
    required PostStageMoraleContext context,
    required double moraleDamage,
  }) {
    final int severity = math.min(
      95,
      (50 +
              (context.leaderCrosswindTimeLossSeconds * 0.6).round() +
              ((1.0 - context.leaderWindProtectionRatio.clamp(0.0, 1.0)) * 25)
                  .round())
          .toInt(),
    );
    return TeamConflictIncident(
      id: 'morale_wind_${context.raceId}_s${context.stage.stageNumber}_${leader.id}',
      raceId: context.raceId,
      stageNumber: context.stage.stageNumber,
      stageName: context.stage.name,
      aggressorRiderId: leader.id,
      aggressorRiderName: leader.fullName,
      victimRiderId: context.teamId,
      victimRiderName: 'Kierownictwo & Pomocnicy',
      incidentType: IntraTeamIncidentType.postStageMediaRant,
      severity: severity,
      radioTranscript:
          '${leader.fullName}: "Gdzie byliście na tym wietrze?! Jechałem sam na rantach, a wy siedzieliście z tyłu!"',
      mediaHeadline:
          'Napięcie w ekipie po etapie ${context.stage.stageNumber}: ${leader.fullName} krytykuje brak osłony na wietrze.',
      moraleDamage: moraleDamage,
      incidentDate: context.stageDate ?? DateTime.now(),
    );
  }

  static TeamConflictIncident _buildSprinterNoTrainIncident({
    required Rider sprinter,
    required PostStageMoraleContext context,
    required double moraleDamage,
  }) {
    final int severity = math.min(
      95,
      (55 +
              ((1.0 - context.sprintLeadoutSupportRatio.clamp(0.0, 1.0)) * 30)
                  .round())
          .toInt(),
    );
    return TeamConflictIncident(
      id: 'morale_sprint_${context.raceId}_s${context.stage.stageNumber}_${sprinter.id}',
      raceId: context.raceId,
      stageNumber: context.stage.stageNumber,
      stageName: context.stage.name,
      aggressorRiderId: sprinter.id,
      aggressorRiderName: sprinter.fullName,
      victimRiderId: context.teamId,
      victimRiderName: 'Pociąg Sprinterski',
      incidentType: IntraTeamIncidentType.sprintLeadoutSabotage,
      severity: severity,
      radioTranscript:
          '${sprinter.fullName}: "Nie miałem ani jednego koła na ostatnich 2 km! Po co przyjechaliśmy na płaski etap bez pociągu?!"',
      mediaHeadline:
          '${sprinter.fullName} wściekły po płaskim finiszu: "Zostałem sam bez rozprowadzenia".',
      moraleDamage: moraleDamage,
      incidentDate: context.stageDate ?? DateTime.now(),
    );
  }

  static String _buildHeadlinePl({
    required Set<PostStageMoraleEventType> triggeredEvents,
    required double avgDelta,
    String? winnerName,
    String? leaderName,
    String? sprinterName,
  }) {
    if (triggeredEvents
            .contains(PostStageMoraleEventType.stageVictoryTeamSurge) &&
        triggeredEvents
            .contains(PostStageMoraleEventType.leaderJerseyTakenSurge)) {
      return 'Podwójna euforia! Zwycięstwo (${winnerName ?? "ekipa"}) i przejęcie koszulki lidera podniosły morale (+${avgDelta.toStringAsFixed(1)}).';
    }
    if (triggeredEvents
        .contains(PostStageMoraleEventType.stageVictoryTeamSurge)) {
      return 'Zwycięstwo etapowe (${winnerName ?? "ekipa"}) napędza całą drużynę (+${avgDelta.toStringAsFixed(1)} morale).';
    }
    if (triggeredEvents
        .contains(PostStageMoraleEventType.leaderJerseyTakenSurge)) {
      return 'Koszulka lidera dla zespołu! Morale w autobusie wyraźnie rośnie (+${avgDelta.toStringAsFixed(1)}).';
    }
    if (triggeredEvents
        .contains(PostStageMoraleEventType.leaderUnprotectedInCrosswind)) {
      return 'Kryzys zaufania na wietrze: ${leaderName ?? "lider"} stracił morale przez brak osłony.';
    }
    if (triggeredEvents.contains(
        PostStageMoraleEventType.sprinterNoLeadoutTrainFrustration)) {
      return 'Frustracja po finiszu: ${sprinterName ?? "sprinter"} rozgoryczony brakiem pociągu rozprowadzającego.';
    }
    if (triggeredEvents.contains(PostStageMoraleEventType.podiumFinishBoost)) {
      return 'Podium etapowe pozytywnie wpływa na nastroje w zespole (+${avgDelta.toStringAsFixed(1)}).';
    }
    return 'Stabilne nastroje w zespole po zakończeniu etapu.';
  }
}
