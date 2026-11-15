// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import '../../models/race/tour_race.dart';
import '../../models/team/cycling_team.dart';
import '../../models/team/sponsor_contract.dart';
import '../../state/career_state_notifier.dart';

/// Rozpoznany typ celu sponsorskiego na podstawie opisu lub identyfikatora [SponsorObjective].
enum EvaluatedObjectiveType {
  /// Wygranie klasyfikacji generalnej Grand Touru (TdF, Giro, Vuelta)
  winGrandTourGc,

  /// Podium w klasyfikacji generalnej Grand Touru (Top 3)
  podiumGrandTourGc,

  /// Triumf w jednym z 5 Monumentów kolarstwa
  winMonument,

  /// Podium w jednym z 5 Monumentów (Top 3) - np. €250,000 bonusu
  podiumMonument,

  /// Top 5 w klasyku lub Monumencie (w tym brukowanym)
  top5ClassicOrMonument,

  /// Zwycięstwo etapowe w Grand Tourze lub wyścigu WorldTour
  stageWinWorldTour,

  /// Spędzenie określonej liczby kilometrów w ucieczkach (ekspozycja TV)
  breakawayKmExposure,

  /// Tytuł Najbardziej Walecznego Kolarza (Czerwony Numer / Super Combativity)
  mostCombativeAward,

  /// Zielona koszulka klasyfikacji punktowej
  pointsJersey,

  /// Koszulka w grochy najlepszego górala (KOM)
  mountainsJersey,

  /// Zakończenie lub utrzymanie pozycji w Top 5 Drużynowego Rankingu UCI
  top5UciTeamRanking,

  /// Ogólne zwycięstwo w dowolnym wyścigu zawodowym
  anyRaceWin,
}

/// Kontekst wyników sportowych drużyny po zakończonym wyścigu lub etapie,
/// przekazywany do automatycznej ewaluacji celów sponsorskich.
class PostRaceSponsorContext {
  final String raceId;
  final String raceName;
  final RaceCategory raceCategory;
  final DateTime raceDate;

  /// Czy wyścig/etap stanowi zakończenie całej imprezy (np. wyścig jednodniowy lub ostatni etap wyścigu etapowego)
  final bool isFinalStage;
  final int stageNumber;

  /// Najlepsze miejsce kolarza drużyny na etapie lub w wyścigu jednodniowym (null jeśli DNF / brak wyniku)
  final int? bestPlayerStageRank;

  /// Najlepsze miejsce kolarza drużyny w klasyfikacji generalnej (GC) na koniec wyścigu wieloetapowego
  final int? bestPlayerGcRank;

  /// Liczba zwycięstw etapowych zdobytych w tym wyścigu/dniu (zwykle 0 lub 1)
  final int wonStagesCount;

  /// Czy drużyna zdobyła klasyfikację punktową (Zielona Koszulka)
  final bool wonPointsJersey;

  /// Czy drużyna zdobyła klasyfikację górską (Koszulka w Grochy)
  final bool wonMountainsJersey;

  /// Czy kolarz drużyny otrzymał nagrodę Najbardziej Walecznego Kolarza
  final bool wonMostCombativeAward;

  /// Łączna liczba kilometrów przejechanych przez kolarzy drużyny w ucieczce podczas tego etapu/wyścigu
  final double teamBreakawayKm;

  /// Aktualna pozycja drużyny w Drużynowym Rankingu UCI (opcjonalnie do weryfikacji celu Top 5)
  final int? currentUciTeamRank;

  /// Nazwisko najlepszego kolarza drużyny w tym wyścigu (do personalizacji wiadomości od sponsora)
  final String? topFinishingRiderName;

  const PostRaceSponsorContext({
    required this.raceId,
    required this.raceName,
    required this.raceCategory,
    required this.raceDate,
    this.isFinalStage = true,
    this.stageNumber = 1,
    this.bestPlayerStageRank,
    this.bestPlayerGcRank,
    this.wonStagesCount = 0,
    this.wonPointsJersey = false,
    this.wonMountainsJersey = false,
    this.wonMostCombativeAward = false,
    this.teamBreakawayKm = 0.0,
    this.currentUciTeamRank,
    this.topFinishingRiderName,
  });

  bool get isGrandTour => raceCategory == RaceCategory.grandTour;
  bool get isMonument => raceCategory == RaceCategory.monument;
  bool get isWorldTourEvent =>
      raceCategory == RaceCategory.grandTour ||
      raceCategory == RaceCategory.monument ||
      raceCategory == RaceCategory.worldTourStageRace ||
      raceCategory == RaceCategory.worldTourOneDay;
}

/// Informacja o pojedynczym zrealizowanym celu sponsorskim i wypłaconym bonusie.
class CompletedObjectiveBonus {
  final String sponsorId;
  final String sponsorName;
  final SponsorTier sponsorTier;
  final String objectiveId;
  final String objectiveDescription;
  final int bonusPaidEur;
  final double satisfactionGain;

  const CompletedObjectiveBonus({
    required this.sponsorId,
    required this.sponsorName,
    required this.sponsorTier,
    required this.objectiveId,
    required this.objectiveDescription,
    required this.bonusPaidEur,
    required this.satisfactionGain,
  });
}

/// Pełny wynik ewaluacji celów sponsorskich po wyścigu.
class SponsorEvaluationResult {
  /// Zaktualizowana lista kontraktów sponsorskich (nowy postęp celów i poziom zadowolenia)
  final List<SponsorContract> updatedSponsors;

  /// Zaktualizowany stan konta drużyny (uwzględniający wypłacone premie)
  final int updatedCashBalanceEur;

  /// Łączna kwota bonusów finansowych wypłaconych po tym wyścigu
  final int totalBonusesPaidEur;

  /// Lista nowo zrealizowanych celów w tym wyścigu
  final List<CompletedObjectiveBonus> newlyCompletedObjectives;

  /// Ważony wskaźnik zadowolenia zarządu i sponsorów (0.0 - 100.0)
  final double overallBoardSatisfaction;

  /// Zmiana ogólnego zadowolenia zarządu po tym wyścigu
  final double boardSatisfactionDelta;

  /// Wygenerowane maile od sponsora tytularnego (gratulacje lub ostrzeżenia)
  final List<CareerInboxMessage> generatedEmails;

  const SponsorEvaluationResult({
    required this.updatedSponsors,
    required this.updatedCashBalanceEur,
    required this.totalBonusesPaidEur,
    required this.newlyCompletedObjectives,
    required this.overallBoardSatisfaction,
    required this.boardSatisfactionDelta,
    required this.generatedEmails,
  });

  bool get hasPaidBonuses => totalBonusesPaidEur > 0;
  bool get hasGeneratedEmails => generatedEmails.isNotEmpty;
}

/// Serwis odpowiedzialny za automatyczną weryfikację postępu celów sponsorskich ([SponsorObjective]),
/// aktualizację paska zadowolenia zarządu, wypłatę bonusów finansowych oraz wysyłkę
/// korespondencji od sponsora tytularnego po każdym zakończonym wyścigu.
class SponsorObjectivesEvaluator {
  const SponsorObjectivesEvaluator();

  /// Próg zadowolenia sponsora tytularnego, poniżej którego wysyłane jest oficjalne ostrzeżenie.
  static const double warningSatisfactionThreshold = 45.0;

  /// Próg krytyczny zadowolenia zarządu grożący zerwaniem rozmów o przedłużeniu umowy.
  static const double criticalSatisfactionThreshold = 25.0;

  /// Przeprowadza pełną ewaluację wszystkich sponsorów drużyny po zakończeniu wyścigu/etapu.
  SponsorEvaluationResult evaluatePostRace({
    required CyclingTeam team,
    required PostRaceSponsorContext context,
  }) {
    if (team.sponsors.isEmpty) {
      return SponsorEvaluationResult(
        updatedSponsors: const [],
        updatedCashBalanceEur: team.cashBalanceEur,
        totalBonusesPaidEur: 0,
        newlyCompletedObjectives: const [],
        overallBoardSatisfaction: 50.0,
        boardSatisfactionDelta: 0.0,
        generatedEmails: const [],
      );
    }

    final double previousBoardSatisfaction = calculateBoardSatisfaction(team.sponsors);
    final List<SponsorContract> updatedSponsors = [];
    final List<CompletedObjectiveBonus> completedBonuses = [];
    int totalBonusesPaid = 0;

    bool titleSponsorCompletedAny = false;
    double titleSponsorDelta = 0.0;
    bool titleSponsorDisappointed = false;

    for (final sponsor in team.sponsors) {
      double sponsorSatisfactionDelta = 0.0;
      final List<SponsorObjective> updatedObjectives = [];

      for (final objective in sponsor.objectives) {
        if (objective.isCompleted) {
          updatedObjectives.add(objective);
          continue;
        }

        final evaluated = _evaluateSingleObjective(
          objective: objective,
          context: context,
        );

        final updatedObj = evaluated.updatedObjective;
        updatedObjectives.add(updatedObj);

        if (updatedObj.isCompleted && !objective.isCompleted) {
          final double gain = _satisfactionGainForImportance(objective.importance);
          sponsorSatisfactionDelta += gain;
          totalBonusesPaid += objective.bonusPaymentEur;

          completedBonuses.add(
            CompletedObjectiveBonus(
              sponsorId: sponsor.id,
              sponsorName: sponsor.companyName,
              sponsorTier: sponsor.sponsorTier,
              objectiveId: objective.id,
              objectiveDescription: objective.description,
              bonusPaidEur: objective.bonusPaymentEur,
              satisfactionGain: gain,
            ),
          );

          if (sponsor.sponsorTier == SponsorTier.titlePrimary) {
            titleSponsorCompletedAny = true;
          }
        } else if (evaluated.progressDelta > 0) {
          // Częściowy postęp (np. kilometry w ucieczce w TV) delikatnie podnosi zadowolenie
          sponsorSatisfactionDelta += _partialProgressSatisfaction(objective.importance);
        } else if (evaluated.causedDisappointment) {
          // Rozczarowanie w kluczowym dla celu wyścigu (np. słaby wynik w Monumencie)
          final double penalty = _disappointmentPenalty(
            importance: objective.importance,
            category: context.raceCategory,
          );
          sponsorSatisfactionDelta -= penalty;

          if (sponsor.sponsorTier == SponsorTier.titlePrimary) {
            titleSponsorDisappointed = true;
          }
        }
      }

      // Dodatkowa premia lub kara wynikowa za prestiżowy rezultat w wyścigu (nawet bez konkretnego celu)
      sponsorSatisfactionDelta += _generalRaceImpressionDelta(
        sponsor: sponsor,
        context: context,
        alreadyRewardedObjective: sponsorSatisfactionDelta > 0,
      );

      final double newSatisfaction =
          (sponsor.sponsorSatisfaction + sponsorSatisfactionDelta).clamp(0.0, 100.0);

      if (sponsor.sponsorTier == SponsorTier.titlePrimary) {
        titleSponsorDelta = newSatisfaction - sponsor.sponsorSatisfaction;
      }

      updatedSponsors.add(
        sponsor.copyWith(
          sponsorSatisfaction: newSatisfaction,
          objectives: updatedObjectives,
        ),
      );
    }

    final double newBoardSatisfaction = calculateBoardSatisfaction(updatedSponsors);
    final double boardDelta = newBoardSatisfaction - previousBoardSatisfaction;

    // Generowanie maili od sponsora tytularnego (lub głównego partnera, jeśli brak tytularnego)
    final List<CareerInboxMessage> emails = _generateTitleSponsorEmails(
      teamName: team.name,
      updatedSponsors: updatedSponsors,
      context: context,
      completedBonuses: completedBonuses,
      titleSponsorCompletedAny: titleSponsorCompletedAny,
      titleSponsorDisappointed: titleSponsorDisappointed,
      titleSponsorDelta: titleSponsorDelta,
      overallBoardSatisfaction: newBoardSatisfaction,
    );

    return SponsorEvaluationResult(
      updatedSponsors: updatedSponsors,
      updatedCashBalanceEur: team.cashBalanceEur + totalBonusesPaid,
      totalBonusesPaidEur: totalBonusesPaid,
      newlyCompletedObjectives: completedBonuses,
      overallBoardSatisfaction: newBoardSatisfaction,
      boardSatisfactionDelta: boardDelta,
      generatedEmails: emails,
    );
  }

  /// Wygodna metoda pomocnicza aplikująca wynik ewaluacji bezpośrednio na model [CyclingTeam].
  CyclingTeam applyEvaluationToTeam({
    required CyclingTeam team,
    required SponsorEvaluationResult result,
  }) {
    return team.copyWith(
      sponsors: result.updatedSponsors,
      cashBalanceEur: result.updatedCashBalanceEur,
    );
  }

  /// Wylicza ważony pasek zadowolenia zarządu i sponsorów (0.0 - 100.0).
  /// Sponsor tytularny (`titlePrimary`) ma największy wpływ na ocenę zarządu.
  double calculateBoardSatisfaction(List<SponsorContract> sponsors) {
    if (sponsors.isEmpty) return 50.0;

    double weightedSum = 0.0;
    double totalWeight = 0.0;

    for (final s in sponsors) {
      final double weight = _weightForTier(s.sponsorTier);
      weightedSum += s.sponsorSatisfaction * weight;
      totalWeight += weight;
    }

    if (totalWeight <= 0.0) return 50.0;
    return (weightedSum / totalWeight).clamp(0.0, 100.0);
  }

  /// Rozpoznaje typ celu sponsorskiego na podstawie słów kluczowych w jego opisie lub ID.
  EvaluatedObjectiveType classifyObjective(SponsorObjective objective) {
    final desc = objective.description.toLowerCase();
    final id = objective.id.toLowerCase();
    final combined = '$id $desc';

    if (combined.contains('uci') && (combined.contains('top 5') || combined.contains('top5') || combined.contains('ranking'))) {
      return EvaluatedObjectiveType.top5UciTeamRanking;
    }
    if (combined.contains('uciecz') || combined.contains('ekspozycj') || combined.contains('breakaway') || combined.contains('airtime')) {
      return EvaluatedObjectiveType.breakawayKmExposure;
    }
    if (combined.contains('waleczn') || combined.contains('czerwony numer') || combined.contains('combativ')) {
      return EvaluatedObjectiveType.mostCombativeAward;
    }
    if (combined.contains('zielon') || combined.contains('punktow') || combined.contains('green')) {
      return EvaluatedObjectiveType.pointsJersey;
    }
    if (combined.contains('groch') || combined.contains('góral') || combined.contains('mountain') || combined.contains('kom')) {
      return EvaluatedObjectiveType.mountainsJersey;
    }
    if (combined.contains('monumen')) {
      if (combined.contains('podium') || combined.contains('top 3') || combined.contains('top3')) {
        return EvaluatedObjectiveType.podiumMonument;
      }
      if (combined.contains('top 5') || combined.contains('top5')) {
        return EvaluatedObjectiveType.top5ClassicOrMonument;
      }
      return EvaluatedObjectiveType.winMonument;
    }
    if (combined.contains('klasyk') || combined.contains('brukow') || combined.contains('top 5') || combined.contains('top5')) {
      return EvaluatedObjectiveType.top5ClassicOrMonument;
    }
    if (combined.contains('grand tour') || combined.contains('wielk') || combined.contains('gc') || combined.contains('generaln')) {
      if (combined.contains('etap') || combined.contains('stage')) {
        return EvaluatedObjectiveType.stageWinWorldTour;
      }
      if (combined.contains('podium') || combined.contains('top 3') || combined.contains('top3')) {
        return EvaluatedObjectiveType.podiumGrandTourGc;
      }
      return EvaluatedObjectiveType.winGrandTourGc;
    }
    if (combined.contains('etap') || combined.contains('stage')) {
      return EvaluatedObjectiveType.stageWinWorldTour;
    }

    return EvaluatedObjectiveType.anyRaceWin;
  }

  // ===========================================================================
  // PRYWATNA LOGIKA EWALUACJI POJEDYNCZEGO CELU
  // ===========================================================================

  _SingleObjectiveEvaluation _evaluateSingleObjective({
    required SponsorObjective objective,
    required PostRaceSponsorContext context,
  }) {
    final kind = classifyObjective(objective);
    double newProgress = objective.currentProgress;
    bool completed = false;
    bool disappointment = false;

    switch (kind) {
      case EvaluatedObjectiveType.winGrandTourGc:
        if (context.isGrandTour && context.isFinalStage) {
          if (context.bestPlayerGcRank == 1) {
            newProgress = objective.targetProgress;
            completed = true;
          } else if (context.bestPlayerGcRank == null || context.bestPlayerGcRank! > 10) {
            disappointment = true;
          }
        }
        break;

      case EvaluatedObjectiveType.podiumGrandTourGc:
        if (context.isGrandTour && context.isFinalStage) {
          if (context.bestPlayerGcRank != null && context.bestPlayerGcRank! <= 3) {
            newProgress = objective.targetProgress;
            completed = true;
          } else if (context.bestPlayerGcRank == null || context.bestPlayerGcRank! > 12) {
            disappointment = true;
          }
        }
        break;

      case EvaluatedObjectiveType.winMonument:
        if (context.isMonument) {
          if (context.bestPlayerStageRank == 1) {
            newProgress = objective.targetProgress;
            completed = true;
          } else if (context.bestPlayerStageRank == null || context.bestPlayerStageRank! > 15) {
            disappointment = true;
          }
        }
        break;

      case EvaluatedObjectiveType.podiumMonument:
        if (context.isMonument) {
          if (context.bestPlayerStageRank != null && context.bestPlayerStageRank! <= 3) {
            newProgress = objective.targetProgress;
            completed = true;
          } else if (context.bestPlayerStageRank == null || context.bestPlayerStageRank! > 20) {
            disappointment = true;
          }
        }
        break;

      case EvaluatedObjectiveType.top5ClassicOrMonument:
        if (context.isMonument || context.raceCategory == RaceCategory.worldTourOneDay) {
          if (context.bestPlayerStageRank != null && context.bestPlayerStageRank! <= 5) {
            newProgress = objective.targetProgress;
            completed = true;
          } else if (context.isMonument &&
              (context.bestPlayerStageRank == null || context.bestPlayerStageRank! > 25)) {
            disappointment = true;
          }
        }
        break;

      case EvaluatedObjectiveType.stageWinWorldTour:
        if (context.isWorldTourEvent) {
          final int winsThisEvent = context.wonStagesCount > 0
              ? context.wonStagesCount
              : (context.bestPlayerStageRank == 1 ? 1 : 0);
          if (winsThisEvent > 0) {
            newProgress = objective.currentProgress + winsThisEvent;
            if (newProgress >= objective.targetProgress) {
              completed = true;
            }
          }
        }
        break;

      case EvaluatedObjectiveType.breakawayKmExposure:
        if (context.teamBreakawayKm > 0) {
          newProgress = objective.currentProgress + context.teamBreakawayKm;
          if (newProgress >= objective.targetProgress) {
            completed = true;
          }
        }
        break;

      case EvaluatedObjectiveType.mostCombativeAward:
        if (context.wonMostCombativeAward) {
          newProgress = objective.targetProgress;
          completed = true;
        }
        break;

      case EvaluatedObjectiveType.pointsJersey:
        if (context.isFinalStage && context.wonPointsJersey) {
          newProgress = objective.targetProgress;
          completed = true;
        }
        break;

      case EvaluatedObjectiveType.mountainsJersey:
        if (context.isFinalStage && context.wonMountainsJersey) {
          newProgress = objective.targetProgress;
          completed = true;
        }
        break;

      case EvaluatedObjectiveType.top5UciTeamRanking:
        if (context.currentUciTeamRank != null && context.currentUciTeamRank! <= 5) {
          newProgress = objective.targetProgress;
          completed = true;
        }
        break;

      case EvaluatedObjectiveType.anyRaceWin:
        if (context.bestPlayerStageRank == 1 || context.wonStagesCount > 0) {
          newProgress = objective.currentProgress + math.max(1, context.wonStagesCount);
          if (newProgress >= objective.targetProgress) {
            completed = true;
          }
        }
        break;
    }

    final clampedProgress = objective.targetProgress > 0
        ? newProgress.clamp(0.0, objective.targetProgress)
        : (completed ? 1.0 : newProgress);

    final updated = objective.copyWith(
      currentProgress: clampedProgress,
      isCompleted: completed || (objective.targetProgress > 0 && clampedProgress >= objective.targetProgress),
    );

    return _SingleObjectiveEvaluation(
      updatedObjective: updated,
      progressDelta: math.max(0.0, updated.currentProgress - objective.currentProgress),
      causedDisappointment: disappointment,
    );
  }

  // ===========================================================================
  // KALKULACJA PASKA ZADOWOLENIA ZARZĄDU I SPONSORÓW
  // ===========================================================================

  double _weightForTier(SponsorTier tier) {
    switch (tier) {
      case SponsorTier.titlePrimary:
        return 0.60;
      case SponsorTier.titleSecondary:
        return 0.20;
      case SponsorTier.majorPartner:
        return 0.12;
      case SponsorTier.technicalSupplier:
        return 0.08;
    }
  }

  double _satisfactionGainForImportance(ObjectiveImportance importance) {
    switch (importance) {
      case ObjectiveImportance.low:
        return 4.0;
      case ObjectiveImportance.medium:
        return 7.0;
      case ObjectiveImportance.high:
        return 12.0;
      case ObjectiveImportance.critical:
        return 18.0;
    }
  }

  double _partialProgressSatisfaction(ObjectiveImportance importance) {
    switch (importance) {
      case ObjectiveImportance.low:
        return 0.8;
      case ObjectiveImportance.medium:
        return 1.2;
      case ObjectiveImportance.high:
        return 1.8;
      case ObjectiveImportance.critical:
        return 2.5;
    }
  }

  double _disappointmentPenalty({
    required ObjectiveImportance importance,
    required RaceCategory category,
  }) {
    final double basePenalty;
    switch (importance) {
      case ObjectiveImportance.low:
        basePenalty = 2.0;
      case ObjectiveImportance.medium:
        basePenalty = 4.0;
      case ObjectiveImportance.high:
        basePenalty = 7.0;
      case ObjectiveImportance.critical:
        basePenalty = 11.0;
    }
    final double multiplier = (category == RaceCategory.monument || category == RaceCategory.grandTour)
        ? 1.25
        : 0.8;
    return basePenalty * multiplier;
  }

  double _generalRaceImpressionDelta({
    required SponsorContract sponsor,
    required PostRaceSponsorContext context,
    required bool alreadyRewardedObjective,
  }) {
    if (alreadyRewardedObjective) return 0.0;

    // Zwycięstwo poza konkretnym celem nadal poprawia nastroje w zarządzie
    if (context.bestPlayerStageRank == 1) {
      return context.isWorldTourEvent ? 3.5 : 1.8;
    }
    // Podium w ważnym wyścigu
    if (context.bestPlayerStageRank != null &&
        context.bestPlayerStageRank! <= 3 &&
        context.isWorldTourEvent) {
      return 2.0;
    }
    // Duża aktywność telewizyjna w ucieczce
    if (context.teamBreakawayKm >= 100.0) {
      return 1.0;
    }
    return 0.0;
  }

  // ===========================================================================
  // GENERATOR MAILI OD SPONSORA TYTULARNEGO (GRATULACJE / OSTRZEŻENIA)
  // ===========================================================================

  List<CareerInboxMessage> _generateTitleSponsorEmails({
    required String teamName,
    required List<SponsorContract> updatedSponsors,
    required PostRaceSponsorContext context,
    required List<CompletedObjectiveBonus> completedBonuses,
    required bool titleSponsorCompletedAny,
    required bool titleSponsorDisappointed,
    required double titleSponsorDelta,
    required double overallBoardSatisfaction,
  }) {
    final SponsorContract titleSponsor = updatedSponsors.firstWhere(
      (s) => s.sponsorTier == SponsorTier.titlePrimary,
      orElse: () => updatedSponsors.first,
    );

    final List<CareerInboxMessage> messages = [];
    final int timestamp = context.raceDate.millisecondsSinceEpoch;

    // 1. Mail z gratulacjami za zrealizowanie celu lub wielki sukces (np. podium w Monumencie)
    if (completedBonuses.isNotEmpty) {
      final int totalBonus = completedBonuses.fold(0, (sum, b) => sum + b.bonusPaidEur);
      final String formattedBonus = _formatEur(totalBonus);
      final String objectivesList =
          completedBonuses.map((b) => '• ${b.objectiveDescription} (+${_formatEur(b.bonusPaidEur)})').join('\n');

      final String riderMention = context.topFinishingRiderName != null
          ? 'Szczególne wyrazy uznania dla ${context.topFinishingRiderName} za świetną postawę na trasie ${context.raceName}. '
          : '';

      messages.add(
        CareerInboxMessage(
          id: 'sponsor_congrats_${context.raceId}_$timestamp',
          date: context.raceDate,
          senderName: 'Zarząd ${titleSponsor.companyName}',
          senderRole: titleSponsor.sponsorTier == SponsorTier.titlePrimary
              ? 'Sponsor Tytularny'
              : 'Główny Partner Drużyny',
          subject: 'Gratulacje! Cel sponsorski osiągnięty – przelew $formattedBonus',
          body: 'Szanowny Dyrektorze Sportowy $teamName,\n\n'
              'W imieniu zarządu ${titleSponsor.companyName} składamy serdeczne gratulacje po wyścigu ${context.raceName}! '
              '${riderMention}Nasze barwy były doskonale widoczne w transmisji telewizyjnej.\n\n'
              'Zrealizowane cele kontraktowe:\n'
              '$objectivesList\n\n'
              'Zgodnie z umową na konto drużyny został natychmiast przelany bonus w wysokości $formattedBonus. '
              'Aktualne zadowolenie naszego zarządu wynosi ${titleSponsor.sponsorSatisfaction.toStringAsFixed(0)}% '
              '(ogólne poparcie zarządu: ${overallBoardSatisfaction.toStringAsFixed(0)}%). Tak trzymać!',
          category: InboxCategory.sponsorNews,
          priority: totalBonus >= 250000 || titleSponsorCompletedAny
              ? InboxPriority.urgent
              : InboxPriority.normal,
          actionLabel: 'Zobacz finanse i cele',
        ),
      );
    }

    // 2. Mail ostrzegawczy od sponsora tytularnego przy niskim zadowoleniu lub słabym występie
    final bool lowSatisfaction = titleSponsor.sponsorSatisfaction < warningSatisfactionThreshold;
    final bool criticalWarning = titleSponsor.sponsorSatisfaction < criticalSatisfactionThreshold;

    if ((titleSponsorDisappointed && titleSponsorDelta < -2.0) || lowSatisfaction) {
      final String severityNote = criticalWarning
          ? 'KRYTYCZNY ALARM KONTRAKTOWY: Zaufanie zarządu spadło do ${titleSponsor.sponsorSatisfaction.toStringAsFixed(0)}%. '
              'Jeśli wyniki nie ulegną natychmiastowej poprawie, wstrzymamy rozmowy o przedłużeniu finansowania na kolejny sezon!'
          : 'Zadowolenie naszego zarządu spadło do ${titleSponsor.sponsorSatisfaction.toStringAsFixed(0)}%. '
              'Oczekujemy znacznie bardziej agresywnej jazdy oraz walki o punkty i miejsca na podium w nadchodzących startach.';

      messages.add(
        CareerInboxMessage(
          id: 'sponsor_warning_${context.raceId}_$timestamp',
          date: context.raceDate,
          senderName: 'Dyrektor Marketingu ${titleSponsor.companyName}',
          senderRole: 'Sponsor Tytularny',
          subject: criticalWarning
              ? 'PILNE OSTRZEŻENIE: Kryzys zaufania po ${context.raceName}'
              : 'Ostrzeżenie od sponsora: Oczekujemy lepszych wyników po ${context.raceName}',
          body: 'Panie Menedżerze,\n\n'
              'Występ ekipy $teamName w wyścigu ${context.raceName} był poniżej oczekiwań naszego zarządu oraz celów zapisanych w kontrakcie.\n\n'
              '$severityNote\n\n'
              'Prosimy o przedstawienie planu naprawczego i pełne zaangażowanie liderów w najbliższych wyścigach.',
          category: InboxCategory.sponsorNews,
          priority: InboxPriority.urgent,
          actionLabel: 'Przejrzyj cele sponsorskie',
        ),
      );
    }

    return messages;
  }

  static String _formatEur(int amount) {
    final str = amount.toString();
    final buffer = StringBuffer('€');
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
}

class _SingleObjectiveEvaluation {
  final SponsorObjective updatedObjective;
  final double progressDelta;
  final bool causedDisappointment;

  const _SingleObjectiveEvaluation({
    required this.updatedObjective,
    required this.progressDelta,
    required this.causedDisappointment,
  });
}
