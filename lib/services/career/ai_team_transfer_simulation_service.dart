// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import '../../core/utils/formatters.dart';
import '../../models/rider/rider.dart';
import '../../models/rider/rider_contract.dart';
import '../../models/team/cycling_team.dart';
import '../../state/career_state_notifier.dart';
import 'uci_promotion_relegation_cycle_service.dart';

/// Kluczowe role kadrowe analizowane przez AI przy budowie składu na kolejny sezon.
enum RosterNeedPosition {
  gcLeader('Lider GC', 'GCLeader'),
  pureSprinter('Czysty Sprinter', 'PureSprinter'),
  classicCobbles('Specjalista Bruków', 'ClassicCobbles'),
  superDomestique('Super-Domestique', 'SuperDomestique');

  final String polishLabel;
  final String code;

  const RosterNeedPosition(this.polishLabel, this.code);

  String toJson() => name;

  static RosterNeedPosition fromJson(String value) {
    return RosterNeedPosition.values.firstWhere(
      (e) =>
          e.name.toLowerCase() == value.toLowerCase() ||
          e.code.toLowerCase() == value.toLowerCase(),
      orElse: () => RosterNeedPosition.superDomestique,
    );
  }
}

/// Rodzaj zdarzenia wygenerowanego przez symulację rynku transferowego AI.
enum TransferNewsType {
  freeAgentSigning('Wolny Transfer'),
  contractExtension('Przedłużenie Kontraktu'),
  biddingWarWon('Wygrana Licytacja'),
  releaseClauseBuyout('Wykup Klauzuli'),
  playerRiderBuyoutOffer('Oferta Wykupu Klauzuli');

  final String polishLabel;

  const TransferNewsType(this.polishLabel);

  String toJson() => name;

  static TransferNewsType fromJson(String value) {
    return TransferNewsType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TransferNewsType.freeAgentSigning,
    );
  }
}

/// Raport potrzeb kadrowych i sytuacji sportowo-finansowej pojedynczej drużyny AI.
class TeamRosterNeedsReport {
  final String teamId;
  final String teamName;
  final TeamDivision division;
  final int rosterSize;
  final int targetRosterSize;
  final double averageAge;
  final int expiringContractsCount;
  final RelegationStatus relegationStatus;
  final bool isRelegationThreatened;
  final bool needsYouthInjection;
  final Map<RosterNeedPosition, int> positionCounts;
  final Map<RosterNeedPosition, int> positionDeficits;
  final List<RosterNeedPosition> priorityNeeds;
  final int availableTransferBudgetEur;
  final double urgencyScore;

  const TeamRosterNeedsReport({
    required this.teamId,
    required this.teamName,
    required this.division,
    required this.rosterSize,
    required this.targetRosterSize,
    required this.averageAge,
    required this.expiringContractsCount,
    required this.relegationStatus,
    required this.isRelegationThreatened,
    required this.needsYouthInjection,
    required this.positionCounts,
    required this.positionDeficits,
    required this.priorityNeeds,
    required this.availableTransferBudgetEur,
    required this.urgencyScore,
  });

  int get totalMissingRiders => math.max(0, targetRosterSize - rosterSize);

  bool get hasAnyDeficit =>
      totalMissingRiders > 0 || priorityNeeds.isNotEmpty;
}

/// Szczegółowa wycena rynkowa kolarza w EUR oraz jej składowe.
class RiderValuationBreakdown {
  final String riderId;
  final String riderName;
  final int age;
  final double wattsPerKg;
  final int uciPoints;
  final int potential;
  final int marketValueEur;
  final int suggestedAnnualSalaryEur;
  final int suggestedReleaseClauseEur;
  final double ageCurveMultiplier;
  final double powerScoreEur;
  final double uciPointsBonusEur;
  final double potentialPremiumEur;

  const RiderValuationBreakdown({
    required this.riderId,
    required this.riderName,
    required this.age,
    required this.wattsPerKg,
    required this.uciPoints,
    required this.potential,
    required this.marketValueEur,
    required this.suggestedAnnualSalaryEur,
    required this.suggestedReleaseClauseEur,
    required this.ageCurveMultiplier,
    required this.powerScoreEur,
    required this.uciPointsBonusEur,
    required this.potentialPremiumEur,
  });
}

/// Pojedyncza oferta złożona przez drużynę AI w ramach licytacji (Bidding War).
class BiddingWarOffer {
  final String teamId;
  final String teamName;
  final TeamDivision division;
  final int offeredAnnualSalaryEur;
  final int offeredSigningBonusEur;
  final int offeredBuyoutFeeEur;
  final RiderRole offeredRole;
  final int contractYears;
  final double bidScore;

  const BiddingWarOffer({
    required this.teamId,
    required this.teamName,
    required this.division,
    required this.offeredAnnualSalaryEur,
    required this.offeredSigningBonusEur,
    required this.offeredBuyoutFeeEur,
    required this.offeredRole,
    required this.contractYears,
    required this.bidScore,
  });

  int get totalPackageEur =>
      (offeredAnnualSalaryEur * contractYears) +
      offeredSigningBonusEur +
      offeredBuyoutFeeEur;
}

/// Wynik licytacji o topowego wolnego agenta, talent U23 lub wykup klauzuli.
class BiddingWarResult {
  final String riderId;
  final String riderName;
  final String winningTeamId;
  final String winningTeamName;
  final BiddingWarOffer winningOffer;
  final List<BiddingWarOffer> competingOffers;
  final bool isReleaseClauseBuyout;
  final bool targetsPlayerTeam;
  final int totalPackageEur;

  const BiddingWarResult({
    required this.riderId,
    required this.riderName,
    required this.winningTeamId,
    required this.winningTeamName,
    required this.winningOffer,
    required this.competingOffers,
    required this.isReleaseClauseBuyout,
    required this.targetsPlayerTeam,
    required this.totalPackageEur,
  });
}

/// Wpis informacyjny przekazywany do paska "Transfer Ticker" w Dashboardzie oraz do Inboxa.
class TransferNewsItem {
  final String id;
  final DateTime date;
  final String riderId;
  final String riderName;
  final String riderNationalityIso;
  final String? fromTeamId;
  final String fromTeamName;
  final String toTeamId;
  final String toTeamName;
  final int contractAmountEur;
  final int buyoutFeeEur;
  final int contractYears;
  final RiderRole role;
  final TransferNewsType newsType;
  final String expertComment;
  final bool isBreakingNews;

  const TransferNewsItem({
    required this.id,
    required this.date,
    required this.riderId,
    required this.riderName,
    required this.riderNationalityIso,
    required this.fromTeamId,
    required this.fromTeamName,
    required this.toTeamId,
    required this.toTeamName,
    required this.contractAmountEur,
    this.buyoutFeeEur = 0,
    required this.contractYears,
    required this.role,
    required this.newsType,
    required this.expertComment,
    this.isBreakingNews = false,
  });

  /// Krótki nagłówek do przewijanego paska "Transfer Ticker" na Dashboardzie HQ.
  String get tickerHeadline {
    final amountStr = Formatters.formatCompactCurrency(contractAmountEur);
    switch (newsType) {
      case TransferNewsType.contractExtension:
        return '[PRZEDŁUŻENIE] $riderName zostaje w $toTeamName na $contractYears lata ($amountStr/rok • ${role.label})';
      case TransferNewsType.playerRiderBuyoutOffer:
        final buyoutStr = Formatters.formatCompactCurrency(buyoutFeeEur);
        return '[PILNE - KLAUZULA] $toTeamName aktywuje klauzulę $buyoutStr za $riderName ($fromTeamName)!';
      case TransferNewsType.releaseClauseBuyout:
        final buyoutStr = Formatters.formatCompactCurrency(buyoutFeeEur);
        return '[WYKUP KLAUZULI] $riderName przechodzi z $fromTeamName do $toTeamName (klauzula $buyoutStr, kontrakt $amountStr/rok)';
      case TransferNewsType.biddingWarWon:
        return '[HIT TRANSFEROWY] $toTeamName wygrywa licytację o $riderName ($fromTeamName) — $amountStr/rok';
      case TransferNewsType.freeAgentSigning:
        return '[TRANSFER] $riderName: $fromTeamName → $toTeamName ($amountStr/rok • ${role.label})';
    }
  }

  /// Konwertuje wiadomość transferową na wpis w skrzynce menedżera (Inbox).
  CareerInboxMessage toInboxMessage() {
    final amountStr = Formatters.formatCurrency(contractAmountEur);
    final buyoutStr =
        buyoutFeeEur > 0 ? Formatters.formatCurrency(buyoutFeeEur) : null;

    final String subject;
    final InboxPriority priority;
    final String? actionLabel;

    if (newsType == TransferNewsType.playerRiderBuyoutOffer) {
      subject = 'OFERTA WYKUPU KLAUZULI: $riderName ($toTeamName)';
      priority = InboxPriority.urgent;
      actionLabel = 'Przejdź do Rynku Transferowego';
    } else if (isBreakingNews) {
      subject = 'Transferowy Hit: $riderName zasila $toTeamName';
      priority = InboxPriority.normal;
      actionLabel = 'Zobacz Rynek';
    } else {
      subject = 'Ruch na rynku: $riderName → $toTeamName';
      priority = InboxPriority.low;
      actionLabel = null;
    }

    final buffer = StringBuffer()
      ..writeln('${newsType.polishLabel.toUpperCase()}: $riderName ($riderNationalityIso)')
      ..writeln('Poprzedni zespół: $fromTeamName')
      ..writeln('Nowy zespół: $toTeamName')
      ..writeln('Rola w drużynie: ${role.label}')
      ..writeln('Kontrakt: $amountStr / rok ($contractYears lata)');

    if (buyoutStr != null) {
      buffer.writeln('Kwota wykupu klauzuli: $buyoutStr');
    }

    buffer
      ..writeln()
      ..writeln('Komentarz ekspercki:')
      ..write(expertComment);

    return CareerInboxMessage(
      id: 'inbox_tr_$id',
      date: date,
      senderName: newsType == TransferNewsType.playerRiderBuyoutOffer
          ? 'Zarząd $toTeamName'
          : 'Peleton Mercato Insider',
      senderRole: newsType == TransferNewsType.playerRiderBuyoutOffer
          ? 'Oferta Oficjalna'
          : 'Korespondent Transferowy',
      subject: subject,
      body: buffer.toString(),
      category: InboxCategory.transferMarket,
      priority: priority,
      actionLabel: actionLabel,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'riderId': riderId,
        'riderName': riderName,
        'riderNationalityIso': riderNationalityIso,
        'fromTeamId': fromTeamId,
        'fromTeamName': fromTeamName,
        'toTeamId': toTeamId,
        'toTeamName': toTeamName,
        'contractAmountEur': contractAmountEur,
        'buyoutFeeEur': buyoutFeeEur,
        'contractYears': contractYears,
        'role': role.toJson(),
        'newsType': newsType.toJson(),
        'expertComment': expertComment,
        'isBreakingNews': isBreakingNews,
      };

  factory TransferNewsItem.fromJson(Map<String, dynamic> json) {
    return TransferNewsItem(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      riderNationalityIso: json['riderNationalityIso'] as String? ?? 'INT',
      fromTeamId: json['fromTeamId'] as String?,
      fromTeamName: json['fromTeamName'] as String,
      toTeamId: json['toTeamId'] as String,
      toTeamName: json['toTeamName'] as String,
      contractAmountEur: (json['contractAmountEur'] as num).toInt(),
      buyoutFeeEur: (json['buyoutFeeEur'] as num?)?.toInt() ?? 0,
      contractYears: (json['contractYears'] as num).toInt(),
      role: RiderRole.fromJson(json['role'] as String),
      newsType: TransferNewsType.fromJson(json['newsType'] as String),
      expertComment: json['expertComment'] as String,
      isBreakingNews: json['isBreakingNews'] as bool? ?? false,
    );
  }
}

/// Pełny wynik kroku symulacji rynku transferowego AI.
class AiTransferSimulationResult {
  final List<Rider> updatedRiders;
  final List<CyclingTeam> updatedTeams;
  final List<TransferNewsItem> newsItems;
  final List<CareerInboxMessage> inboxMessages;
  final List<BiddingWarResult> biddingWars;
  final List<BiddingWarResult> playerBuyoutOffers;
  final Map<String, TeamRosterNeedsReport> teamNeedsReports;

  const AiTransferSimulationResult({
    required this.updatedRiders,
    required this.updatedTeams,
    required this.newsItems,
    required this.inboxMessages,
    required this.biddingWars,
    required this.playerBuyoutOffers,
    required this.teamNeedsReports,
  });
}

/// Analizator potrzeb kadrowych drużyn AI.
///
/// Sprawdza braki na 4 kluczowych pozycjach (`GCLeader`, `PureSprinter`, `ClassicCobbles`, `SuperDomestique`),
/// średni wiek składu oraz zagrożenie spadkiem w 3-letnim rankingu UCI.
class TeamRosterNeedsAnalyzer {
  TeamRosterNeedsAnalyzer._();

  /// Docelowa liczebność składu w zależności od dywizji UCI.
  static int targetRosterSizeForDivision(TeamDivision division) {
    switch (division) {
      case TeamDivision.worldTour:
        return 28;
      case TeamDivision.proTeam:
        return 22;
      case TeamDivision.continental:
        return 14;
    }
  }

  /// Minimalne docelowe pokrycie kluczowych pozycji w zależności od dywizji.
  static Map<RosterNeedPosition, int> targetPositionCountsForDivision(
    TeamDivision division,
  ) {
    switch (division) {
      case TeamDivision.worldTour:
        return const {
          RosterNeedPosition.gcLeader: 2,
          RosterNeedPosition.pureSprinter: 2,
          RosterNeedPosition.classicCobbles: 2,
          RosterNeedPosition.superDomestique: 4,
        };
      case TeamDivision.proTeam:
        return const {
          RosterNeedPosition.gcLeader: 1,
          RosterNeedPosition.pureSprinter: 1,
          RosterNeedPosition.classicCobbles: 1,
          RosterNeedPosition.superDomestique: 2,
        };
      case TeamDivision.continental:
        return const {
          RosterNeedPosition.gcLeader: 1,
          RosterNeedPosition.pureSprinter: 1,
          RosterNeedPosition.classicCobbles: 1,
          RosterNeedPosition.superDomestique: 1,
        };
    }
  }

  /// Określa, czy kolarz spełnia kryteria danej pozycji kadrowej.
  static bool riderFitsPosition(Rider rider, RosterNeedPosition position) {
    final wKg = rider.physiology.wattsPerKg;
    final ovr = rider.overallRating;

    switch (position) {
      case RosterNeedPosition.gcLeader:
        return (rider.specialization == RiderSpecialization.gcClimber ||
                rider.specialization == RiderSpecialization.pureClimber) &&
            (ovr >= 74 || wKg >= 5.55);
      case RosterNeedPosition.pureSprinter:
        return (rider.specialization == RiderSpecialization.pureSprinter ||
                rider.specialization == RiderSpecialization.versatileSprinter) &&
            (rider.sprintRating >= 73 || rider.powerProfile.watts5s >= 1420);
      case RosterNeedPosition.classicCobbles:
        return (rider.specialization == RiderSpecialization.classicCobbles ||
                rider.specialization == RiderSpecialization.puncher) &&
            (rider.skills.cobbles >= 72 || ovr >= 74);
      case RosterNeedPosition.superDomestique:
        return rider.contract.role == RiderRole.superDomestique ||
            ((rider.specialization == RiderSpecialization.domestiqueEngine ||
                    rider.specialization == RiderSpecialization.timeTrialist ||
                    rider.specialization == RiderSpecialization.pureClimber) &&
                ovr >= 70);
    }
  }

  /// Przeprowadza pełną analizę potrzeb kadrowych drużyny AI.
  static TeamRosterNeedsReport analyzeTeam({
    required CyclingTeam team,
    required List<Rider> teamRiders,
    required int currentSeasonYear,
    required DateTime referenceDate,
    RelegationStatus? relegationStatus,
  }) {
    final activeRiders = teamRiders
        .where((r) => !r.contract.isExpiring(currentSeasonYear))
        .toList();
    final expiringCount = teamRiders.length - activeRiders.length;

    // Średni wiek składu obliczany na pełnym obecnym składzie (lub aktywnych po wygaśnięciu)
    final ageSample = activeRiders.isNotEmpty ? activeRiders : teamRiders;
    double avgAge = 26.0;
    if (ageSample.isNotEmpty) {
      final sumAges = ageSample.fold<int>(
        0,
        (sum, r) => sum + _ageAtDate(r.birthDate, referenceDate),
      );
      avgAge = sumAges / ageSample.length;
    }

    final counts = <RosterNeedPosition, int>{
      for (final pos in RosterNeedPosition.values) pos: 0,
    };

    for (final rider in activeRiders) {
      for (final pos in RosterNeedPosition.values) {
        if (riderFitsPosition(rider, pos)) {
          counts[pos] = (counts[pos] ?? 0) + 1;
        }
      }
    }

    final targets = targetPositionCountsForDivision(team.division);
    final deficits = <RosterNeedPosition, int>{};
    for (final pos in RosterNeedPosition.values) {
      final target = targets[pos] ?? 1;
      final current = counts[pos] ?? 0;
      deficits[pos] = math.max(0, target - current);
    }

    final effectiveRelegationStatus =
        relegationStatus ?? _inferRelegationStatus(team);
    final isThreatened =
        effectiveRelegationStatus == RelegationStatus.relegationThreatened ||
        effectiveRelegationStatus == RelegationStatus.relegationZone ||
        effectiveRelegationStatus == RelegationStatus.proTeamPromotionZone;

    final needsYouth = avgAge >= 29.0;

    final priorityNeeds = deficits.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final targetRosterSize = targetRosterSizeForDivision(team.division);
    final missingTotal = math.max(0, targetRosterSize - activeRiders.length);

    final deficitSum =
        deficits.values.fold<int>(0, (sum, val) => sum + val);
    double urgency = (deficitSum * 11.0) + (missingTotal * 3.5);
    if (isThreatened) urgency += 22.0;
    if (needsYouth) urgency += 10.0;
    urgency = urgency.clamp(0.0, 100.0);

    // Dostępny budżet transferowy na kontrakty i ewentualne wykupy klauzul
    final rawAvailable =
        math.max(0, team.cashBalanceEur) + (team.annualSponsorIncomeEur * 0.35).round();
    final minReserve = switch (team.division) {
      TeamDivision.worldTour => 350000,
      TeamDivision.proTeam => 120000,
      TeamDivision.continental => 35000,
    };
    final transferBudget = math.max(minReserve, (rawAvailable * 0.45).round());

    return TeamRosterNeedsReport(
      teamId: team.id,
      teamName: team.name,
      division: team.division,
      rosterSize: activeRiders.length,
      targetRosterSize: targetRosterSize,
      averageAge: avgAge,
      expiringContractsCount: expiringCount,
      relegationStatus: effectiveRelegationStatus,
      isRelegationThreatened: isThreatened,
      needsYouthInjection: needsYouth,
      positionCounts: counts,
      positionDeficits: deficits,
      priorityNeeds: priorityNeeds.map((e) => e.key).toList(),
      availableTransferBudgetEur: transferBudget,
      urgencyScore: urgency,
    );
  }

  static RelegationStatus _inferRelegationStatus(CyclingTeam team) {
    switch (team.division) {
      case TeamDivision.worldTour:
        if (team.uciPointsSeason < 2400) {
          return RelegationStatus.relegationZone;
        }
        if (team.uciPointsSeason < 4200) {
          return RelegationStatus.relegationThreatened;
        }
        return RelegationStatus.safeWorldTour;
      case TeamDivision.proTeam:
        if (team.uciPointsSeason >= 2800) {
          return RelegationStatus.proTeamPromotionZone;
        }
        if (team.uciPointsSeason >= 1600) {
          return RelegationStatus.proTeamWildcardZone;
        }
        return RelegationStatus.proTeamMidfield;
      case TeamDivision.continental:
        return RelegationStatus.proTeamMidfield;
    }
  }

  static int _ageAtDate(DateTime birthDate, DateTime referenceDate) {
    int age = referenceDate.year - birthDate.year;
    if (referenceDate.month < birthDate.month ||
        (referenceDate.month == birthDate.month &&
            referenceDate.day < birthDate.day)) {
      age--;
    }
    return math.max(18, age);
  }
}

/// Zaawansowany serwis symulujący żywy rynek transferowy między wszystkimi 52 drużynami AI.
///
/// Obsługuje:
/// - Oficjalne okno transferowe od 1 sierpnia do 15 listopada.
/// - Przedłużenia kontraktów w trakcie sezonu (poza oknem transferowym).
/// - Wycenę rynkową kolarzy w EUR (krzywa wieku ze szczytem 24–28 lat, punkty UCI, W/kg, potencjał).
/// - Licytacje (Bidding Wars) bogatych ekip WorldTour o wolnych agentów, talenty i klauzule wykupu (w tym za kolarzy gracza).
/// - Generator `TransferNewsItem` dla Dashboard Transfer Ticker oraz Inboxa.
class AiTeamTransferSimulationService {
  AiTeamTransferSimulationService._();

  static const int windowOpenMonth = 8;
  static const int windowOpenDay = 1;
  static const int windowCloseMonth = 11;
  static const int windowCloseDay = 15;

  /// Sprawdza, czy w danej dacie trwa główne okno transferowe AI (1 sierpnia – 15 listopada).
  static bool isTransferWindowOpen(DateTime date) {
    if (date.month < windowOpenMonth || date.month > windowCloseMonth) {
      return false;
    }
    if (date.month == windowOpenMonth && date.day < windowOpenDay) {
      return false;
    }
    if (date.month == windowCloseMonth && date.day > windowCloseDay) {
      return false;
    }
    return true;
  }

  /// Oblicza mnożnik krzywej wieku z wyraźnym szczytem wartości w przedziale 24–28 lat.
  static double ageValuationCurveMultiplier(int age) {
    if (age <= 20) return 0.78;
    if (age == 21) return 0.88;
    if (age == 22) return 0.96;
    if (age == 23) return 1.05;
    if (age == 24) return 1.16;
    if (age == 25) return 1.22;
    if (age == 26) return 1.25; // Szczyt krzywej wartości
    if (age == 27) return 1.22;
    if (age == 28) return 1.16;
    if (age == 29) return 1.04;
    if (age == 30) return 0.94;
    if (age == 31) return 0.84;
    if (age == 32) return 0.74;
    if (age == 33) return 0.64;
    if (age == 34) return 0.54;
    return math.max(0.35, 0.54 - (age - 34) * 0.07);
  }

  /// Algorytm wyceny rynkowej kolarza w EUR bazujący na:
  /// - wieku (krzywa szczytu w wieku 24–28 lat),
  /// - punktach UCI (`careerPointsUci`),
  /// - stosunku mocy progowej W/kg (`wattsPerKg`),
  /// - potencjale rozwojowym (`potential`).
  static RiderValuationBreakdown evaluateRiderValuation(
    Rider rider, {
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    int age = now.year - rider.birthDate.year;
    if (now.month < rider.birthDate.month ||
        (now.month == rider.birthDate.month && now.day < rider.birthDate.day)) {
      age--;
    }
    age = math.max(18, age);

    final double weightKg =
        rider.physiology.weightKg > 0 ? rider.physiology.weightKg : 70.0;
    final double wKg = rider.physiology.ftpWatts / weightKg;
    final double ageMult = ageValuationCurveMultiplier(age);

    // 1. Bazowa wartość z W/kg oraz specjalizacji (sprint / klasyki / góry)
    final double wKgNormalized = ((wKg - 4.2) / (6.6 - 4.2)).clamp(0.0, 1.35);
    double powerScoreEur = 55000.0 + (math.pow(wKgNormalized, 2.15) * 2100000.0);

    if (rider.specialization == RiderSpecialization.pureSprinter ||
        rider.specialization == RiderSpecialization.versatileSprinter) {
      final sprintNorm =
          ((rider.powerProfile.watts5s - 1100.0) / (1750.0 - 1100.0))
              .clamp(0.0, 1.25);
      powerScoreEur = math.max(
        powerScoreEur,
        75000.0 + math.pow(sprintNorm, 2.0) * 1850000.0,
      );
    } else if (rider.specialization == RiderSpecialization.classicCobbles) {
      final cobblesNorm = ((rider.skills.cobbles - 55.0) / 40.0).clamp(0.0, 1.2);
      powerScoreEur += math.pow(cobblesNorm, 1.8) * 650000.0;
    }

    // 2. Premia za punkty UCI (udowodniona skuteczność w wyścigach)
    final int uciPoints = math.max(0, rider.careerPointsUci);
    final double uciPointsBonusEur = (uciPoints * 380.0) +
        (uciPoints > 1500 ? (uciPoints - 1500) * 420.0 : 0.0);

    // 3. Premia za potencjał rozwojowy (szczególnie wysoka u kolarzy <= 25 lat)
    final int potentialGap = math.max(0, rider.potential - rider.overallRating);
    final double youthFactor = age <= 23
        ? 1.45
        : age <= 26
            ? 1.0
            : 0.35;
    final double potentialPremiumEur =
        (math.max(0, rider.potential - 68) * 14000.0 + potentialGap * 22000.0) *
            youthFactor;

    final double rawMarketValue =
        (powerScoreEur + uciPointsBonusEur) * ageMult + potentialPremiumEur;

    final int marketValueEur =
        math.max(45000, ((rawMarketValue / 5000.0).round() * 5000));

    // Sugerowana roczna pensja to ok. 72% wartości rynkowej (z zachowaniem minimum UCI)
    final int suggestedSalary = math.max(
      45000,
      (((marketValueEur * 0.72) / 1000.0).round() * 1000),
    );

    // Sugerowana klauzula wykupu dla gwiazd i talentów
    final int suggestedReleaseClause =
        ((marketValueEur * (age <= 25 ? 2.6 : 1.9) / 10000.0).round() * 10000);

    return RiderValuationBreakdown(
      riderId: rider.id,
      riderName: rider.fullName,
      age: age,
      wattsPerKg: wKg,
      uciPoints: uciPoints,
      potential: rider.potential,
      marketValueEur: marketValueEur,
      suggestedAnnualSalaryEur: suggestedSalary,
      suggestedReleaseClauseEur: suggestedReleaseClause,
      ageCurveMultiplier: ageMult,
      powerScoreEur: powerScoreEur,
      uciPointsBonusEur: uciPointsBonusEur,
      potentialPremiumEur: potentialPremiumEur,
    );
  }

  /// Prosta funkcja pomocnicza zwracająca wycenę rynkową kolarza w EUR.
  static int calculateRiderMarketValueEur(
    Rider rider, {
    DateTime? referenceDate,
  }) {
    return evaluateRiderValuation(rider, referenceDate: referenceDate)
        .marketValueEur;
  }

  /// Uruchamia krok symulacji rynku transferowego AI dla podanej daty.
  ///
  /// - W oknie transferowym (1 VIII – 15 XI): analizuje potrzeby wszystkich drużyn AI,
  ///   organizuje licytacje (Bidding Wars) o najlepszych wolnych agentów, talenty i klauzule wykupu
  ///   (w tym za kolarzy z drużyny gracza), a następnie uzupełnia braki kadrowe.
  /// - Poza oknem (w trakcie sezonu): symuluje przedłużenia kontraktów przez ekipy AI.
  static AiTransferSimulationResult simulateMarketDay({
    required DateTime currentDate,
    required int currentSeasonYear,
    required String playerTeamId,
    required List<CyclingTeam> teams,
    required List<Rider> riders,
    Map<String, RelegationStatus> relegationStatuses = const {},
    int maxEventsPerStep = 6,
    bool autoExecutePlayerBuyouts = false,
    int? randomSeed,
  }) {
    final rng = math.Random(
      randomSeed ??
          (currentDate.year * 10000 +
              currentDate.month * 100 +
              currentDate.day),
    );

    final workingRiders = List<Rider>.from(riders);
    final workingTeams = List<CyclingTeam>.from(teams);
    final riderIndexById = <String, int>{
      for (int i = 0; i < workingRiders.length; i++) workingRiders[i].id: i,
    };
    final teamIndexById = <String, int>{
      for (int i = 0; i < workingTeams.length; i++) workingTeams[i].id: i,
    };

    final newsItems = <TransferNewsItem>[];
    final biddingWars = <BiddingWarResult>[];
    final playerBuyoutOffers = <BiddingWarResult>[];
    final reports = <String, TeamRosterNeedsReport>{};

    // Analiza potrzeb wszystkich drużyn AI (pomijając drużynę gracza)
    for (final team in workingTeams) {
      if (team.id == playerTeamId) continue;
      final teamRiders = workingRiders
          .where((r) => team.rosterRiderIds.contains(r.id) || r.teamId == team.id)
          .toList();
      reports[team.id] = TeamRosterNeedsAnalyzer.analyzeTeam(
        team: team,
        teamRiders: teamRiders,
        currentSeasonYear: currentSeasonYear,
        referenceDate: currentDate,
        relegationStatus: relegationStatuses[team.id],
      );
    }

    if (!isTransferWindowOpen(currentDate)) {
      // Poza oknem: przedłużenia kontraktów kluczowych kolarzy w trakcie sezonu
      _simulateInSeasonContractExtensions(
        currentDate: currentDate,
        currentSeasonYear: currentSeasonYear,
        playerTeamId: playerTeamId,
        workingRiders: workingRiders,
        workingTeams: workingTeams,
        riderIndexById: riderIndexById,
        reports: reports,
        newsItems: newsItems,
        maxEvents: math.max(1, maxEventsPerStep ~/ 2),
        rng: rng,
      );
    } else {
      // W oknie transferowym (1 VIII – 15 XI): Licytacje (Bidding Wars) + uzupełnianie składów
      _simulateBiddingWars(
        currentDate: currentDate,
        currentSeasonYear: currentSeasonYear,
        playerTeamId: playerTeamId,
        workingRiders: workingRiders,
        workingTeams: workingTeams,
        riderIndexById: riderIndexById,
        teamIndexById: teamIndexById,
        reports: reports,
        biddingWars: biddingWars,
        playerBuyoutOffers: playerBuyoutOffers,
        newsItems: newsItems,
        maxWars: math.max(1, maxEventsPerStep ~/ 2),
        autoExecutePlayerBuyouts: autoExecutePlayerBuyouts,
        rng: rng,
      );

      if (newsItems.length < maxEventsPerStep) {
        _simulateStandardRosterSignings(
          currentDate: currentDate,
          currentSeasonYear: currentSeasonYear,
          playerTeamId: playerTeamId,
          workingRiders: workingRiders,
          workingTeams: workingTeams,
          riderIndexById: riderIndexById,
          teamIndexById: teamIndexById,
          reports: reports,
          newsItems: newsItems,
          remainingSlots: maxEventsPerStep - newsItems.length,
          rng: rng,
        );
      }
    }

    final inboxMessages = newsItems
        .where(
          (item) =>
              item.newsType == TransferNewsType.playerRiderBuyoutOffer ||
              item.isBreakingNews ||
              item.newsType == TransferNewsType.biddingWarWon,
        )
        .map((item) => item.toInboxMessage())
        .toList();

    return AiTransferSimulationResult(
      updatedRiders: workingRiders,
      updatedTeams: workingTeams,
      newsItems: newsItems,
      inboxMessages: inboxMessages,
      biddingWars: biddingWars,
      playerBuyoutOffers: playerBuyoutOffers,
      teamNeedsReports: reports,
    );
  }

  /// Symuluje przedłużenia kontraktów w trakcie sezonu (poza oknem transferowym).
  static void _simulateInSeasonContractExtensions({
    required DateTime currentDate,
    required int currentSeasonYear,
    required String playerTeamId,
    required List<Rider> workingRiders,
    required List<CyclingTeam> workingTeams,
    required Map<String, int> riderIndexById,
    required Map<String, TeamRosterNeedsReport> reports,
    required List<TransferNewsItem> newsItems,
    required int maxEvents,
    required math.Random rng,
  }) {
    final aiTeamsById = <String, CyclingTeam>{
      for (final t in workingTeams)
        if (t.id != playerTeamId) t.id: t,
    };

    final expiringAiRiders = workingRiders.where((r) {
      if (r.teamId == playerTeamId) return false;
      if (!aiTeamsById.containsKey(r.teamId)) return false;
      return r.contract.isExpiring(currentSeasonYear) &&
          (r.overallRating >= 73 || r.potential >= 80);
    }).toList();

    if (expiringAiRiders.isEmpty) return;

    expiringAiRiders.sort((a, b) => b.overallRating.compareTo(a.overallRating));
    final pool = expiringAiRiders.take(math.min(12, expiringAiRiders.length)).toList()
      ..shuffle(rng);

    for (final rider in pool) {
      if (newsItems.length >= maxEvents) break;

      final team = aiTeamsById[rider.teamId];
      final report = reports[rider.teamId];
      if (team == null || report == null) continue;

      final valuation = evaluateRiderValuation(rider, referenceDate: currentDate);
      if (report.availableTransferBudgetEur < valuation.suggestedAnnualSalaryEur * 0.7) {
        continue;
      }

      final extensionYears = rider.age <= 26 ? 3 : 2;
      final newAnnualSalary = (valuation.suggestedAnnualSalaryEur *
              (0.95 + rng.nextDouble() * 0.12))
          .round();
      final newMonthlySalary = (newAnnualSalary / 12).round();
      final newRole = _determineBestRoleForRider(rider, team.division);

      final updatedContract = rider.contract.copyWith(
        role: newRole,
        monthlySalaryEur: newMonthlySalary,
        contractEndYear: currentSeasonYear + extensionYears,
        releaseClauseEur: valuation.suggestedReleaseClauseEur,
        morale: math.min(1.0, rider.contract.morale + 0.08),
      );

      final idx = riderIndexById[rider.id];
      if (idx != null) {
        workingRiders[idx] = rider.copyWith(contract: updatedContract);
      }

      final isStar = rider.overallRating >= 80 || valuation.marketValueEur >= 1200000;
      newsItems.add(
        TransferNewsItem(
          id: 'ext_${currentDate.millisecondsSinceEpoch}_${rider.id}',
          date: currentDate,
          riderId: rider.id,
          riderName: rider.fullName,
          riderNationalityIso: rider.nationalityIso,
          fromTeamId: team.id,
          fromTeamName: team.name,
          toTeamId: team.id,
          toTeamName: team.name,
          contractAmountEur: newAnnualSalary,
          contractYears: extensionYears,
          role: newRole,
          newsType: TransferNewsType.contractExtension,
          isBreakingNews: isStar,
          expertComment: _buildExpertComment(
            rider: rider,
            fromTeamName: team.name,
            toTeamName: team.name,
            newsType: TransferNewsType.contractExtension,
            annualSalaryEur: newAnnualSalary,
            buyoutFeeEur: 0,
            report: report,
          ),
        ),
      );
    }
  }

  /// Symuluje wojny licytacyjne (Bidding Wars) bogatych ekip WorldTour o najlepszych wolnych agentów,
  /// młode talenty oraz wykup klauzul odstępnego (również za kolarzy gracza!).
  static void _simulateBiddingWars({
    required DateTime currentDate,
    required int currentSeasonYear,
    required String playerTeamId,
    required List<Rider> workingRiders,
    required List<CyclingTeam> workingTeams,
    required Map<String, int> riderIndexById,
    required Map<String, int> teamIndexById,
    required Map<String, TeamRosterNeedsReport> reports,
    required List<BiddingWarResult> biddingWars,
    required List<BiddingWarResult> playerBuyoutOffers,
    required List<TransferNewsItem> newsItems,
    required int maxWars,
    required bool autoExecutePlayerBuyouts,
    required math.Random rng,
  }) {
    // Bogate ekipy WorldTour biorące udział w licytacjach
    final richWorldTourTeams = workingTeams.where((t) {
      if (t.id == playerTeamId) return false;
      if (t.division != TeamDivision.worldTour) return false;
      final report = reports[t.id];
      return report != null && report.availableTransferBudgetEur >= 900000;
    }).toList();

    if (richWorldTourTeams.length < 2) return;

    // Kandydaci do licytacji:
    // 1. Najlepsi wolni agenci (wygasające kontrakty, OVR >= 76 lub potencjał >= 83)
    // 2. Młode talenty / gwiazdy z klauzulą wykupu (w tym z drużyny gracza!)
    final candidates = workingRiders.where((r) {
      final isFreeAgent = r.contract.isExpiring(currentSeasonYear);
      final isYoungGem = r.age <= 24 && r.potential >= 83;
      final isElite = r.overallRating >= 78 || r.careerPointsUci >= 900;
      if (isFreeAgent && (isElite || isYoungGem)) return true;

      // Zakontraktowany gwiazdor/talent z realistyczną klauzulą wykupu
      final hasBuyoutClause = r.contract.releaseClauseEur > 0;
      return !isFreeAgent && hasBuyoutClause && (isElite || isYoungGem);
    }).toList();

    if (candidates.isEmpty) return;

    candidates.sort((a, b) {
      final scoreA = a.overallRating * 1.2 + a.potential * 0.6 + (a.teamId == playerTeamId ? 4.0 : 0.0);
      final scoreB = b.overallRating * 1.2 + b.potential * 0.6 + (b.teamId == playerTeamId ? 4.0 : 0.0);
      return scoreB.compareTo(scoreA);
    });

    final selectedPool = candidates.take(math.min(10, candidates.length)).toList()
      ..shuffle(rng);

    int warsRun = 0;
    for (final rider in selectedPool) {
      if (warsRun >= maxWars) break;

      final isFreeAgent = rider.contract.isExpiring(currentSeasonYear);
      final buyoutFee = isFreeAgent ? 0 : rider.contract.releaseClauseEur;
      final valuation = evaluateRiderValuation(rider, referenceDate: currentDate);

      final interestedBidders = <BiddingWarOffer>[];

      for (final team in richWorldTourTeams) {
        if (team.id == rider.teamId) continue;
        final report = reports[team.id];
        if (report == null) continue;

        final totalRequiredFirstYear = valuation.suggestedAnnualSalaryEur + buyoutFee;
        if (report.availableTransferBudgetEur < totalRequiredFirstYear) {
          continue;
        }

        // Dopasowanie kolarza do braków kadrowych drużyny
        double needMultiplier = 1.0;
        for (final need in report.priorityNeeds) {
          if (TeamRosterNeedsAnalyzer.riderFitsPosition(rider, need)) {
            needMultiplier += 0.22;
          }
        }
        if (report.needsYouthInjection && rider.age <= 24) {
          needMultiplier += 0.15;
        }
        if (report.isRelegationThreatened && rider.careerPointsUci >= 500) {
          needMultiplier += 0.18;
        }

        // Licytacja ma sens, gdy kolarz realnie wzmacnia lub wypełnia lukę
        if (needMultiplier < 1.10 && rng.nextDouble() > 0.35) continue;

        final bidMultiplier = (0.95 + rng.nextDouble() * 0.32) * needMultiplier;
        final offeredSalary =
            ((valuation.suggestedAnnualSalaryEur * bidMultiplier) / 1000.0)
                    .round() *
                1000;
        final signingBonus =
            ((offeredSalary * (0.08 + rng.nextDouble() * 0.12)) / 1000.0)
                    .round() *
                1000;
        final years = rider.age <= 25 ? 3 : 2;
        final offeredRole = _determineBestRoleForRider(rider, team.division);
        final prestigeBonus = team.uciPointsSeason / 500.0;
        final bidScore = (offeredSalary / 10000.0) +
            (signingBonus / 25000.0) +
            prestigeBonus +
            (offeredRole == RiderRole.teamLeader ? 15.0 : 5.0);

        interestedBidders.add(
          BiddingWarOffer(
            teamId: team.id,
            teamName: team.name,
            division: team.division,
            offeredAnnualSalaryEur: offeredSalary,
            offeredSigningBonusEur: signingBonus,
            offeredBuyoutFeeEur: buyoutFee,
            offeredRole: offeredRole,
            contractYears: years,
            bidScore: bidScore,
          ),
        );
      }

      if (interestedBidders.length < 2) continue;

      interestedBidders.sort((a, b) => b.bidScore.compareTo(a.bidScore));
      final winningOffer = interestedBidders.first;
      final targetsPlayer = rider.teamId == playerTeamId;
      final isBuyout = !isFreeAgent && buyoutFee > 0;

      final warResult = BiddingWarResult(
        riderId: rider.id,
        riderName: rider.fullName,
        winningTeamId: winningOffer.teamId,
        winningTeamName: winningOffer.teamName,
        winningOffer: winningOffer,
        competingOffers: interestedBidders,
        isReleaseClauseBuyout: isBuyout,
        targetsPlayerTeam: targetsPlayer,
        totalPackageEur: winningOffer.totalPackageEur,
      );

      biddingWars.add(warResult);
      if (targetsPlayer) {
        playerBuyoutOffers.add(warResult);
      }

      final oldTeamIdx = teamIndexById[rider.teamId];
      final oldTeamName =
          oldTeamIdx != null ? workingTeams[oldTeamIdx].name : 'Wolny Agent';

      // Jeśli to oferta wykupu za kolarza gracza i autoExecutePlayerBuyouts == false,
      // generujemy pilną wiadomość bez cichego zabierania kolarza ze składu.
      if (!targetsPlayer || autoExecutePlayerBuyouts) {
        _applyTransferExecution(
          rider: rider,
          newTeamId: winningOffer.teamId,
          newRole: winningOffer.offeredRole,
          annualSalaryEur: winningOffer.offeredAnnualSalaryEur,
          signingBonusEur: winningOffer.offeredSigningBonusEur,
          buyoutFeeEur: winningOffer.offeredBuyoutFeeEur,
          newContractEndYear: currentSeasonYear + winningOffer.contractYears,
          newReleaseClauseEur: valuation.suggestedReleaseClauseEur,
          workingRiders: workingRiders,
          workingTeams: workingTeams,
          riderIndexById: riderIndexById,
          teamIndexById: teamIndexById,
        );
      }

      final newsType = targetsPlayer
          ? TransferNewsType.playerRiderBuyoutOffer
          : (isBuyout
              ? TransferNewsType.releaseClauseBuyout
              : TransferNewsType.biddingWarWon);

      newsItems.add(
        TransferNewsItem(
          id: 'war_${currentDate.millisecondsSinceEpoch}_${rider.id}',
          date: currentDate,
          riderId: rider.id,
          riderName: rider.fullName,
          riderNationalityIso: rider.nationalityIso,
          fromTeamId: rider.teamId,
          fromTeamName: oldTeamName,
          toTeamId: winningOffer.teamId,
          toTeamName: winningOffer.teamName,
          contractAmountEur: winningOffer.offeredAnnualSalaryEur,
          buyoutFeeEur: winningOffer.offeredBuyoutFeeEur,
          contractYears: winningOffer.contractYears,
          role: winningOffer.offeredRole,
          newsType: newsType,
          isBreakingNews: true,
          expertComment: _buildExpertComment(
            rider: rider,
            fromTeamName: oldTeamName,
            toTeamName: winningOffer.teamName,
            newsType: newsType,
            annualSalaryEur: winningOffer.offeredAnnualSalaryEur,
            buyoutFeeEur: winningOffer.offeredBuyoutFeeEur,
            report: reports[winningOffer.teamId],
            competingTeamsCount: interestedBidders.length,
          ),
        ),
      );

      warsRun++;
    }
  }

  /// Uzupełnia pozostałe braki kadrowe drużyn AI na podstawie analizy `TeamRosterNeedsAnalyzer`.
  static void _simulateStandardRosterSignings({
    required DateTime currentDate,
    required int currentSeasonYear,
    required String playerTeamId,
    required List<Rider> workingRiders,
    required List<CyclingTeam> workingTeams,
    required Map<String, int> riderIndexById,
    required Map<String, int> teamIndexById,
    required Map<String, TeamRosterNeedsReport> reports,
    required List<TransferNewsItem> newsItems,
    required int remainingSlots,
    required math.Random rng,
  }) {
    if (remainingSlots <= 0) return;

    final freeAgents = workingRiders
        .where((r) =>
            r.teamId != playerTeamId &&
            r.contract.isExpiring(currentSeasonYear))
        .toList();

    if (freeAgents.isEmpty) return;

    final needyTeams = workingTeams
        .where((t) =>
            t.id != playerTeamId &&
            (reports[t.id]?.hasAnyDeficit ?? false))
        .toList()
      ..sort((a, b) {
        final urgA = reports[a.id]?.urgencyScore ?? 0.0;
        final urgB = reports[b.id]?.urgencyScore ?? 0.0;
        return urgB.compareTo(urgA);
      });

    int signings = 0;
    for (final team in needyTeams) {
      if (signings >= remainingSlots || freeAgents.isEmpty) break;
      final report = reports[team.id];
      if (report == null) continue;

      Rider? bestFit;
      double bestFitScore = -1.0;

      for (final candidate in freeAgents) {
        if (candidate.teamId == team.id) continue;
        final valuation =
            evaluateRiderValuation(candidate, referenceDate: currentDate);
        if (valuation.suggestedAnnualSalaryEur >
            report.availableTransferBudgetEur) {
          continue;
        }

        double score = candidate.overallRating.toDouble();
        for (final need in report.priorityNeeds) {
          if (TeamRosterNeedsAnalyzer.riderFitsPosition(candidate, need)) {
            score += 18.0;
          }
        }
        if (report.needsYouthInjection && candidate.age <= 24) {
          score += 10.0;
        }
        if (team.division == TeamDivision.continental &&
            candidate.overallRating > 75) {
          continue; // Ekipy Continental nie podpisują gwiazd WT
        }

        if (score > bestFitScore) {
          bestFitScore = score;
          bestFit = candidate;
        }
      }

      if (bestFit == null) continue;

      freeAgents.removeWhere((r) => r.id == bestFit!.id);
      final valuation =
          evaluateRiderValuation(bestFit, referenceDate: currentDate);
      final salary = ((valuation.suggestedAnnualSalaryEur *
                  (0.92 + rng.nextDouble() * 0.14)) /
              1000.0)
          .round() *
          1000;
      final years = bestFit.age <= 25 ? 2 : 1;
      final role = _determineBestRoleForRider(bestFit, team.division);

      final oldTeamIdx = teamIndexById[bestFit.teamId];
      final oldTeamName =
          oldTeamIdx != null ? workingTeams[oldTeamIdx].name : 'Wolny Agent';

      _applyTransferExecution(
        rider: bestFit,
        newTeamId: team.id,
        newRole: role,
        annualSalaryEur: salary,
        signingBonusEur: (salary * 0.05).round(),
        buyoutFeeEur: 0,
        newContractEndYear: currentSeasonYear + years,
        newReleaseClauseEur: valuation.suggestedReleaseClauseEur,
        workingRiders: workingRiders,
        workingTeams: workingTeams,
        riderIndexById: riderIndexById,
        teamIndexById: teamIndexById,
      );

      newsItems.add(
        TransferNewsItem(
          id: 'tr_${currentDate.millisecondsSinceEpoch}_${bestFit.id}',
          date: currentDate,
          riderId: bestFit.id,
          riderName: bestFit.fullName,
          riderNationalityIso: bestFit.nationalityIso,
          fromTeamId: bestFit.teamId,
          fromTeamName: oldTeamName,
          toTeamId: team.id,
          toTeamName: team.name,
          contractAmountEur: salary,
          contractYears: years,
          role: role,
          newsType: TransferNewsType.freeAgentSigning,
          isBreakingNews: bestFit.overallRating >= 80,
          expertComment: _buildExpertComment(
            rider: bestFit,
            fromTeamName: oldTeamName,
            toTeamName: team.name,
            newsType: TransferNewsType.freeAgentSigning,
            annualSalaryEur: salary,
            buyoutFeeEur: 0,
            report: report,
          ),
        ),
      );

      signings++;
    }
  }

  static void _applyTransferExecution({
    required Rider rider,
    required String newTeamId,
    required RiderRole newRole,
    required int annualSalaryEur,
    required int signingBonusEur,
    required int buyoutFeeEur,
    required int newContractEndYear,
    required int newReleaseClauseEur,
    required List<Rider> workingRiders,
    required List<CyclingTeam> workingTeams,
    required Map<String, int> riderIndexById,
    required Map<String, int> teamIndexById,
  }) {
    final oldTeamId = rider.teamId;
    final monthlySalary = (annualSalaryEur / 12).round();

    final updatedContract = rider.contract.copyWith(
      teamId: newTeamId,
      role: newRole,
      monthlySalaryEur: monthlySalary,
      signingBonusEur: signingBonusEur,
      releaseClauseEur: newReleaseClauseEur,
      contractEndYear: newContractEndYear,
      morale: 0.85,
    );

    final rIdx = riderIndexById[rider.id];
    if (rIdx != null) {
      workingRiders[rIdx] = rider.copyWith(contract: updatedContract);
    }

    final oldTIdx = teamIndexById[oldTeamId];
    if (oldTIdx != null && oldTeamId != newTeamId) {
      final oldTeam = workingTeams[oldTIdx];
      final updatedRoster =
          oldTeam.rosterRiderIds.where((id) => id != rider.id).toList();
      workingTeams[oldTIdx] = oldTeam.copyWith(
        rosterRiderIds: updatedRoster,
        cashBalanceEur: oldTeam.cashBalanceEur + buyoutFeeEur,
      );
    }

    final newTIdx = teamIndexById[newTeamId];
    if (newTIdx != null) {
      final newTeam = workingTeams[newTIdx];
      final updatedRoster = List<String>.from(newTeam.rosterRiderIds);
      if (!updatedRoster.contains(rider.id)) {
        updatedRoster.add(rider.id);
      }
      workingTeams[newTIdx] = newTeam.copyWith(
        rosterRiderIds: updatedRoster,
        cashBalanceEur:
            math.max(0, newTeam.cashBalanceEur - buyoutFeeEur - signingBonusEur),
      );
    }
  }

  static RiderRole _determineBestRoleForRider(
    Rider rider,
    TeamDivision division,
  ) {
    final ovr = rider.overallRating;
    if (rider.age <= 21 && ovr < 72) {
      return RiderRole.neoPro;
    }
    if (rider.specialization == RiderSpecialization.pureSprinter ||
        rider.specialization == RiderSpecialization.versatileSprinter) {
      return ovr >= 76 ? RiderRole.sprinter : RiderRole.domestique;
    }
    if (ovr >= 80 || (division != TeamDivision.worldTour && ovr >= 75)) {
      return RiderRole.teamLeader;
    }
    if (ovr >= 75) {
      return RiderRole.coLeader;
    }
    if (ovr >= 71) {
      return RiderRole.superDomestique;
    }
    if (rider.specialization == RiderSpecialization.breakawaySpecialist) {
      return RiderRole.breakawaySpecialist;
    }
    return RiderRole.domestique;
  }

  static String _buildExpertComment({
    required Rider rider,
    required String fromTeamName,
    required String toTeamName,
    required TransferNewsType newsType,
    required int annualSalaryEur,
    required int buyoutFeeEur,
    TeamRosterNeedsReport? report,
    int competingTeamsCount = 1,
  }) {
    final wKgStr = rider.physiology.wattsPerKg.toStringAsFixed(2);
    final salaryStr = Formatters.formatCompactCurrency(annualSalaryEur);

    switch (newsType) {
      case TransferNewsType.playerRiderBuyoutOffer:
        final buyoutStr = Formatters.formatCompactCurrency(buyoutFeeEur);
        return 'Gorące wieści z peletonu! $toTeamName złożyło oficjalną ofertę aktywacji klauzuli ($buyoutStr) za ${rider.fullName} ($wKgStr W/kg). '
            'W wyścigu o podpis kolarza brało udział aż $competingTeamsCount ekip WorldTour.';
      case TransferNewsType.releaseClauseBuyout:
        final buyoutStr = Formatters.formatCompactCurrency(buyoutFeeEur);
        return 'Bezkompromisowy ruch $toTeamName: wyłożenie $buyoutStr za wykup ${rider.fullName} z $fromTeamName pokazuje ogromne ambicje przed nowym sezonem.';
      case TransferNewsType.biddingWarWon:
        return '$toTeamName wygrywa zaciętą licytację z udziałem $competingTeamsCount drużyn WorldTour! '
            'Kontrakt na poziomie $salaryStr/rok dla ${rider.fullName} (OVR ${rider.overallRating}, $wKgStr W/kg) to jeden z najgłośniejszych ruchów okienka.';
      case TransferNewsType.contractExtension:
        return 'Stabilizacja w $toTeamName: ${rider.fullName} przedłuża umowę za $salaryStr/rok. '
            'Dyrektorzy sportowi nie chcieli ryzykować utraty kluczowego ogniwa przed otwarciem rynku.';
      case TransferNewsType.freeAgentSigning:
        if (report != null && report.isRelegationThreatened) {
          return '$toTeamName walczy o punkty w 3-letnim rankingu UCI — pozyskanie ${rider.fullName} (${rider.careerPointsUci} pkt UCI) ma natychmiast poprawić bilans drużyny.';
        }
        if (report != null && report.needsYouthInjection && rider.age <= 24) {
          return 'Odmłodzenie kadry w $toTeamName: ${rider.fullName} (lat ${rider.age}, potencjał ${rider.potential}) wpisuje się w długofalowy plan przebudowy składu.';
        }
        return 'Praktyczne wzmocnienie $toTeamName. ${rider.fullName} ($wKgStr W/kg) wnosi doświadczenie z $fromTeamName i zabezpiecza ważną pozycję w rotacji na nowy sezon.';
    }
  }
}
