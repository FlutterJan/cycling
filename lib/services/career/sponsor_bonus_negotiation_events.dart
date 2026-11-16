// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/race/tour_race.dart';
import '../../models/team/cycling_team.dart';
import '../../models/team/sponsor_contract.dart';
import '../../state/career_state_notifier.dart';

/// Rodzaj spektakularnego sukcesu sportowego wyzwalającego telefon prezesa sponsora.
enum SpectacularSuccessTrigger {
  /// Triumf w jednym z 5 kolarskich Monumentów.
  monumentVictory,

  /// Co najmniej 3 zwycięstwa etapowe w jednym Wielkim Tourze.
  grandTourThreeStageWins,

  /// Zwycięstwo w klasyfikacji generalnej Wielkiego Touru.
  grandTourOverallVictory,

  /// Zdominowanie wyścigu etapowego WorldTour (GC + min. 2 etapy).
  worldTourStageRaceSweep;

  String toJson() => name;

  static SpectacularSuccessTrigger fromJson(String value) {
    return SpectacularSuccessTrigger.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SpectacularSuccessTrigger.monumentVictory,
    );
  }

  String get label {
    switch (this) {
      case SpectacularSuccessTrigger.monumentVictory:
        return 'Zwycięstwo w Monumencie';
      case SpectacularSuccessTrigger.grandTourThreeStageWins:
        return 'Hat-trick etapowy w Grand Tourze (3+ etapy)';
      case SpectacularSuccessTrigger.grandTourOverallVictory:
        return 'Triumf w klasyfikacji generalnej Grand Touru';
      case SpectacularSuccessTrigger.worldTourStageRaceSweep:
        return 'Dominacja w wyścigu WorldTour';
    }
  }
}

/// Przeznaczenie jednorazowego zastrzyku gotówki od prezesa sponsora.
enum BonusAllocationPurpose {
  /// Natychmiastowe zasilenie budżetu transferowego na zakup lub przedłużenie gwiazd.
  transferWarChest,

  /// Inwestycja w testy w tunelu aerodynamicznym, dopasowanie CdA i rozwój sprzętu.
  windTunnelAndAeroRnD,

  /// Równy podział środków (50% transfery / 50% tunel aerodynamiczny).
  splitTransferAndWindTunnel;

  String toJson() => name;

  static BonusAllocationPurpose fromJson(String value) {
    return BonusAllocationPurpose.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => BonusAllocationPurpose.transferWarChest,
    );
  }

  String get title {
    switch (this) {
      case BonusAllocationPurpose.transferWarChest:
        return 'Fundusz Transferowy';
      case BonusAllocationPurpose.windTunnelAndAeroRnD:
        return 'Tunel Aerodynamiczny i R&D';
      case BonusAllocationPurpose.splitTransferAndWindTunnel:
        return 'Podział Strategiczny 50 / 50';
    }
  }

  String get subtitle {
    switch (this) {
      case BonusAllocationPurpose.transferWarChest:
        return '100% premii zasila budżet na wykup kontraktów i nowe transfery.';
      case BonusAllocationPurpose.windTunnelAndAeroRnD:
        return '100% premii finansuje sesje w tunelu aero i optymalizację CdA.';
      case BonusAllocationPurpose.splitTransferAndWindTunnel:
        return 'Połowa kwoty trafia na transfery, a druga połowa do tunelu aero.';
    }
  }

  IconData get icon {
    switch (this) {
      case BonusAllocationPurpose.transferWarChest:
        return Icons.swap_horiz_rounded;
      case BonusAllocationPurpose.windTunnelAndAeroRnD:
        return Icons.air_rounded;
      case BonusAllocationPurpose.splitTransferAndWindTunnel:
        return Icons.pie_chart_rounded;
    }
  }
}

/// Aktualny status oferty nadzwyczajnej premii sponsorskiej.
enum SponsorBonusOfferStatus {
  pendingDecision,
  counterOffered,
  accepted,
  declined,
  expired;

  String toJson() => name;

  static SponsorBonusOfferStatus fromJson(String value) {
    return SponsorBonusOfferStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SponsorBonusOfferStatus.pendingDecision,
    );
  }

  bool get isActionable =>
      this == SponsorBonusOfferStatus.pendingDecision ||
      this == SponsorBonusOfferStatus.counterOffered;
}

/// Kontekst sportowy przekazywany do detektora nadzwyczajnych premii sponsorskich.
class SponsorBonusTriggerContext {
  final String raceId;
  final String raceName;
  final RaceCategory raceCategory;
  final DateTime eventDate;
  final bool isMonumentWin;
  final int grandTourStageWinsInRace;
  final bool wonGrandTourGc;
  final bool wonWorldTourGc;
  final String? heroRiderName;
  final double tvExposureMinutes;

  const SponsorBonusTriggerContext({
    required this.raceId,
    required this.raceName,
    required this.raceCategory,
    required this.eventDate,
    this.isMonumentWin = false,
    this.grandTourStageWinsInRace = 0,
    this.wonGrandTourGc = false,
    this.wonWorldTourGc = false,
    this.heroRiderName,
    this.tvExposureMinutes = 0.0,
  });

  String triggerKey(SpectacularSuccessTrigger trigger) =>
      '${raceId}_${trigger.name}';
}

/// Oferta jednorazowego zastrzyku gotówki (250 000–1 000 000 EUR) od prezesa sponsora.
class SponsorCeoBonusOffer {
  final String id;
  final String triggerKey;
  final String sponsorId;
  final String sponsorCompanyName;
  final String ceoName;
  final String ceoTitle;
  final SponsorIndustry industry;
  final SpectacularSuccessTrigger trigger;
  final String raceName;
  final String heroRiderName;
  final int offeredAmountEur;
  final int maxNegotiableAmountEur;
  final BonusAllocationPurpose recommendedPurpose;
  final BonusAllocationPurpose? selectedPurpose;
  final SponsorBonusOfferStatus status;
  final DateTime createdAt;
  final DateTime expiresOnDate;
  final String ceoCallTranscript;
  final int negotiationRoundsUsed;
  final int maxNegotiationRounds;
  final double sponsorPatience;
  final int? counterOfferRequestedEur;

  const SponsorCeoBonusOffer({
    required this.id,
    required this.triggerKey,
    required this.sponsorId,
    required this.sponsorCompanyName,
    required this.ceoName,
    required this.ceoTitle,
    required this.industry,
    required this.trigger,
    required this.raceName,
    required this.heroRiderName,
    required this.offeredAmountEur,
    required this.maxNegotiableAmountEur,
    required this.recommendedPurpose,
    this.selectedPurpose,
    this.status = SponsorBonusOfferStatus.pendingDecision,
    required this.createdAt,
    required this.expiresOnDate,
    required this.ceoCallTranscript,
    this.negotiationRoundsUsed = 0,
    this.maxNegotiationRounds = 2,
    this.sponsorPatience = 1.0,
    this.counterOfferRequestedEur,
  });

  bool get canNegotiateHigher =>
      status.isActionable &&
      negotiationRoundsUsed < maxNegotiationRounds &&
      sponsorPatience > 0.15 &&
      offeredAmountEur < SponsorBonusNegotiationEvents.maxBonusEur;

  bool isExpiredOn(DateTime date) => date.isAfter(expiresOnDate);

  SponsorCeoBonusOffer copyWith({
    String? id,
    String? triggerKey,
    String? sponsorId,
    String? sponsorCompanyName,
    String? ceoName,
    String? ceoTitle,
    SponsorIndustry? industry,
    SpectacularSuccessTrigger? trigger,
    String? raceName,
    String? heroRiderName,
    int? offeredAmountEur,
    int? maxNegotiableAmountEur,
    BonusAllocationPurpose? recommendedPurpose,
    BonusAllocationPurpose? selectedPurpose,
    SponsorBonusOfferStatus? status,
    DateTime? createdAt,
    DateTime? expiresOnDate,
    String? ceoCallTranscript,
    int? negotiationRoundsUsed,
    int? maxNegotiationRounds,
    double? sponsorPatience,
    int? counterOfferRequestedEur,
  }) {
    return SponsorCeoBonusOffer(
      id: id ?? this.id,
      triggerKey: triggerKey ?? this.triggerKey,
      sponsorId: sponsorId ?? this.sponsorId,
      sponsorCompanyName: sponsorCompanyName ?? this.sponsorCompanyName,
      ceoName: ceoName ?? this.ceoName,
      ceoTitle: ceoTitle ?? this.ceoTitle,
      industry: industry ?? this.industry,
      trigger: trigger ?? this.trigger,
      raceName: raceName ?? this.raceName,
      heroRiderName: heroRiderName ?? this.heroRiderName,
      offeredAmountEur: offeredAmountEur ?? this.offeredAmountEur,
      maxNegotiableAmountEur:
          maxNegotiableAmountEur ?? this.maxNegotiableAmountEur,
      recommendedPurpose: recommendedPurpose ?? this.recommendedPurpose,
      selectedPurpose: selectedPurpose ?? this.selectedPurpose,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      expiresOnDate: expiresOnDate ?? this.expiresOnDate,
      ceoCallTranscript: ceoCallTranscript ?? this.ceoCallTranscript,
      negotiationRoundsUsed:
          negotiationRoundsUsed ?? this.negotiationRoundsUsed,
      maxNegotiationRounds: maxNegotiationRounds ?? this.maxNegotiationRounds,
      sponsorPatience: sponsorPatience ?? this.sponsorPatience,
      counterOfferRequestedEur:
          counterOfferRequestedEur ?? this.counterOfferRequestedEur,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'triggerKey': triggerKey,
      'sponsorId': sponsorId,
      'sponsorCompanyName': sponsorCompanyName,
      'ceoName': ceoName,
      'ceoTitle': ceoTitle,
      'industry': industry.toJson(),
      'trigger': trigger.toJson(),
      'raceName': raceName,
      'heroRiderName': heroRiderName,
      'offeredAmountEur': offeredAmountEur,
      'maxNegotiableAmountEur': maxNegotiableAmountEur,
      'recommendedPurpose': recommendedPurpose.toJson(),
      'selectedPurpose': selectedPurpose?.toJson(),
      'status': status.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'expiresOnDate': expiresOnDate.toIso8601String(),
      'ceoCallTranscript': ceoCallTranscript,
      'negotiationRoundsUsed': negotiationRoundsUsed,
      'maxNegotiationRounds': maxNegotiationRounds,
      'sponsorPatience': sponsorPatience,
      'counterOfferRequestedEur': counterOfferRequestedEur,
    };
  }

  factory SponsorCeoBonusOffer.fromJson(Map<String, dynamic> json) {
    return SponsorCeoBonusOffer(
      id: json['id'] as String,
      triggerKey: json['triggerKey'] as String,
      sponsorId: json['sponsorId'] as String,
      sponsorCompanyName: json['sponsorCompanyName'] as String,
      ceoName: json['ceoName'] as String,
      ceoTitle: json['ceoTitle'] as String,
      industry: SponsorIndustry.fromJson(json['industry'] as String),
      trigger: SpectacularSuccessTrigger.fromJson(json['trigger'] as String),
      raceName: json['raceName'] as String,
      heroRiderName: json['heroRiderName'] as String,
      offeredAmountEur: (json['offeredAmountEur'] as num).toInt(),
      maxNegotiableAmountEur: (json['maxNegotiableAmountEur'] as num).toInt(),
      recommendedPurpose: BonusAllocationPurpose.fromJson(
        json['recommendedPurpose'] as String,
      ),
      selectedPurpose: json['selectedPurpose'] != null
          ? BonusAllocationPurpose.fromJson(json['selectedPurpose'] as String)
          : null,
      status: SponsorBonusOfferStatus.fromJson(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresOnDate: DateTime.parse(json['expiresOnDate'] as String),
      ceoCallTranscript: json['ceoCallTranscript'] as String,
      negotiationRoundsUsed:
          (json['negotiationRoundsUsed'] as num?)?.toInt() ?? 0,
      maxNegotiationRounds:
          (json['maxNegotiationRounds'] as num?)?.toInt() ?? 2,
      sponsorPatience:
          (json['sponsorPatience'] as num?)?.toDouble() ?? 1.0,
      counterOfferRequestedEur:
          (json['counterOfferRequestedEur'] as num?)?.toInt(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SponsorCeoBonusOffer && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Wynik sfinalizowania nadzwyczajnej premii sponsorskiej.
class SponsorBonusNegotiationOutcome {
  final SponsorCeoBonusOffer offer;
  final int cashInjectedEur;
  final int transferBudgetAddedEur;
  final int windTunnelBudgetAddedEur;
  final CyclingTeam updatedTeam;
  final CareerInboxMessage inboxMessage;
  final String headline;
  final String summary;

  const SponsorBonusNegotiationOutcome({
    required this.offer,
    required this.cashInjectedEur,
    required this.transferBudgetAddedEur,
    required this.windTunnelBudgetAddedEur,
    required this.updatedTeam,
    required this.inboxMessage,
    required this.headline,
    required this.summary,
  });
}

/// System nadzwyczajnych premii sponsorskich wyzwalanych po wielkich sukcesach sportowych.
///
/// Po wygraniu Monumentu, zdobyciu min. 3 etapów w Grand Tourze lub wygraniu
/// klasyfikacji generalnej Grand Touru prezes głównego sponsora dzwoni z ofertą
/// jednorazowego zastrzyku gotówki (250 000–1 000 000 EUR) na transfery lub tunel aero.
class SponsorBonusNegotiationEvents {
  const SponsorBonusNegotiationEvents._();

  static const int minBonusEur = 250000;
  static const int maxBonusEur = 1000000;
  static const int offerValidityDays = 7;

  static const Map<SponsorIndustry, List<String>> _ceoNamesByIndustry = {
    SponsorIndustry.finance: <String>['Henrik Lindqvist', 'Marcin Kowalczyk'],
    SponsorIndustry.tech: <String>['Claire Moreau', 'Kenji Takahashi'],
    SponsorIndustry.energy: <String>['Tomasz Zieliński', 'Jan Van Der Berg'],
    SponsorIndustry.automotive: <String>['Matteo Bellini', 'Lukas Weber'],
    SponsorIndustry.airlines: <String>['Sophie Laurent', 'David O’Connor'],
    SponsorIndustry.supermarkets: <String>['Pieter De Vries', 'Anna Nowak'],
    SponsorIndustry.crypto: <String>['Alex Mercer', 'Elena Kovacs'],
    SponsorIndustry.apparel: <String>['Marco Conti', 'Julien Lefèvre'],
  };

  /// Sprawdza, czy wynik sportowy kwalifikuje się do nadzwyczajnego telefonu prezesa.
  static SpectacularSuccessTrigger? detectTrigger(
    SponsorBonusTriggerContext context,
  ) {
    if (context.raceCategory == RaceCategory.monument &&
        context.isMonumentWin) {
      return SpectacularSuccessTrigger.monumentVictory;
    }
    if (context.raceCategory == RaceCategory.grandTour &&
        context.wonGrandTourGc) {
      return SpectacularSuccessTrigger.grandTourOverallVictory;
    }
    if (context.raceCategory == RaceCategory.grandTour &&
        context.grandTourStageWinsInRace >= 3) {
      return SpectacularSuccessTrigger.grandTourThreeStageWins;
    }
    if (context.raceCategory == RaceCategory.worldTourStageRace &&
        context.wonWorldTourGc &&
        context.grandTourStageWinsInRace >= 2) {
      return SpectacularSuccessTrigger.worldTourStageRaceSweep;
    }
    return null;
  }

  /// Tworzy ofertę telefoniczną od prezesa głównego sponsora, jeśli warunek sukcesu
  /// został spełniony i dane wydarzenie nie wygenerowało jeszcze wcześniej premii.
  static SponsorCeoBonusOffer? evaluateAndCreateOffer({
    required CyclingTeam team,
    required SponsorBonusTriggerContext context,
    Set<String> alreadyTriggeredKeys = const <String>{},
    math.Random? random,
  }) {
    final trigger = detectTrigger(context);
    if (trigger == null || team.sponsors.isEmpty) {
      return null;
    }

    final triggerKey = context.triggerKey(trigger);
    if (alreadyTriggeredKeys.contains(triggerKey)) {
      return null;
    }

    final rng = random ??
        math.Random(
          Object.hash(
            team.id,
            context.raceId,
            trigger.name,
            context.eventDate.millisecondsSinceEpoch,
          ),
        );

    final sponsor = _selectCallingSponsor(team.sponsors);
    final baseAmount = _computeBaseOfferEur(
      trigger: trigger,
      sponsor: sponsor,
      tvExposureMinutes: context.tvExposureMinutes,
      rng: rng,
    );

    final maxNegotiable = math
        .min(
          maxBonusEur,
          ((baseAmount * 1.25) / 10000).round() * 10000,
        )
        .clamp(baseAmount, maxBonusEur);

    final recommendedPurpose = _recommendPurpose(
      sponsor: sponsor,
      trigger: trigger,
    );

    final ceoList = _ceoNamesByIndustry[sponsor.industry] ??
        const <String>['Marek Kamiński'];
    final ceoName = ceoList[rng.nextInt(ceoList.length)];
    final heroName = (context.heroRiderName != null &&
            context.heroRiderName!.trim().isNotEmpty)
        ? context.heroRiderName!.trim()
        : 'Twój lider';

    final transcript = _buildCeoCallTranscript(
      ceoName: ceoName,
      companyName: sponsor.companyName,
      raceName: context.raceName,
      heroRiderName: heroName,
      trigger: trigger,
      amountEur: baseAmount,
      recommendedPurpose: recommendedPurpose,
    );

    return SponsorCeoBonusOffer(
      id: 'ceo_bonus_${context.raceId}_${trigger.name}_${context.eventDate.millisecondsSinceEpoch}',
      triggerKey: triggerKey,
      sponsorId: sponsor.id,
      sponsorCompanyName: sponsor.companyName,
      ceoName: ceoName,
      ceoTitle: 'Prezes Zarządu ${sponsor.companyName}',
      industry: sponsor.industry,
      trigger: trigger,
      raceName: context.raceName,
      heroRiderName: heroName,
      offeredAmountEur: baseAmount,
      maxNegotiableAmountEur: maxNegotiable,
      recommendedPurpose: recommendedPurpose,
      selectedPurpose: recommendedPurpose,
      status: SponsorBonusOfferStatus.pendingDecision,
      createdAt: context.eventDate,
      expiresOnDate: context.eventDate.add(
        const Duration(days: offerValidityDays),
      ),
      ceoCallTranscript: transcript,
      negotiationRoundsUsed: 0,
      maxNegotiationRounds: 2,
      sponsorPatience: 1.0,
    );
  }

  /// Przetwarza kontrofertę menedżera w trakcie rozmowy telefonicznej z prezesem.
  static SponsorCeoBonusOffer submitCounterOffer({
    required SponsorCeoBonusOffer offer,
    required int requestedAmountEur,
    BonusAllocationPurpose? preferredPurpose,
  }) {
    if (!offer.canNegotiateHigher) {
      return offer;
    }

    final clampedRequest =
        ((requestedAmountEur.clamp(minBonusEur, maxBonusEur)) / 10000).round() *
            10000;
    final nextRound = offer.negotiationRoundsUsed + 1;

    if (clampedRequest <= offer.offeredAmountEur) {
      return offer.copyWith(
        selectedPurpose: preferredPurpose ?? offer.selectedPurpose,
        counterOfferRequestedEur: clampedRequest,
      );
    }

    final overstretchRatio =
        (clampedRequest - offer.offeredAmountEur) /
            math.max(10000, offer.maxNegotiableAmountEur - offer.offeredAmountEur + 10000);

    // Jeśli żądanie mieści się w limicie prezesa i jest rozsądne:
    if (clampedRequest <= offer.maxNegotiableAmountEur) {
      final compromised = nextRound == 1 &&
              clampedRequest > offer.offeredAmountEur + 60000
          ? (((offer.offeredAmountEur + clampedRequest) / 2) / 10000).round() *
              10000
          : clampedRequest;
      final finalOffer = compromised.clamp(minBonusEur, maxBonusEur);
      final newPatience =
          (offer.sponsorPatience - 0.22 - overstretchRatio * 0.12)
              .clamp(0.0, 1.0);

      return offer.copyWith(
        offeredAmountEur: finalOffer,
        selectedPurpose: preferredPurpose ?? offer.selectedPurpose,
        status: SponsorBonusOfferStatus.counterOffered,
        negotiationRoundsUsed: nextRound,
        sponsorPatience: newPatience,
        counterOfferRequestedEur: clampedRequest,
        ceoCallTranscript:
            '„Doceniam Twoją ambicję po ${offer.raceName}. Zarząd zatwierdził podniesienie premii do '
            '${Formatters.formatCurrency(finalOffer)}. To nasz maksymalny kompromis — na co przeznaczamy środki?”',
      );
    }

    // Zbyt agresywne żądanie powyżej budżetu prezesa:
    final patienceDrop = 0.45 + (overstretchRatio * 0.25).clamp(0.0, 0.4);
    final remainingPatience =
        (offer.sponsorPatience - patienceDrop).clamp(0.0, 1.0);

    if (remainingPatience <= 0.15) {
      return offer.copyWith(
        status: SponsorBonusOfferStatus.declined,
        negotiationRoundsUsed: nextRound,
        sponsorPatience: 0.0,
        counterOfferRequestedEur: clampedRequest,
        ceoCallTranscript:
            '„${Formatters.formatCurrency(clampedRequest)} to kwota poza jakimkolwiek budżetem nadzwyczajnym. '
            'Niestety, zamykamy temat dodatkowej premii na ten moment.”',
      );
    }

    final bumpedCap = math.min(
      offer.maxNegotiableAmountEur,
      offer.offeredAmountEur + 40000,
    );

    return offer.copyWith(
      offeredAmountEur: bumpedCap.clamp(minBonusEur, maxBonusEur),
      selectedPurpose: preferredPurpose ?? offer.selectedPurpose,
      status: SponsorBonusOfferStatus.counterOffered,
      negotiationRoundsUsed: nextRound,
      sponsorPatience: remainingPatience,
      counterOfferRequestedEur: clampedRequest,
      ceoCallTranscript:
          '„Nie mogę zejść do ${Formatters.formatCurrency(clampedRequest)}, rada nadzorcza by tego nie przyjęła. '
          'Mogę dorzucić maksymalnie do ${Formatters.formatCurrency(bumpedCap)}. Bierzemy?”',
    );
  }

  /// Akceptuje ofertę prezesa, zasila konto drużyny i zwraca podział środków.
  static SponsorBonusNegotiationOutcome acceptOffer({
    required CyclingTeam team,
    required SponsorCeoBonusOffer offer,
    required BonusAllocationPurpose purpose,
    required DateTime decisionDate,
  }) {
    if (!offer.status.isActionable) {
      throw StateError(
        'Nie można zaakceptować oferty w statusie ${offer.status.name}.',
      );
    }

    final amount = offer.offeredAmountEur.clamp(minBonusEur, maxBonusEur);
    final int transferAdded;
    final int windTunnelAdded;

    switch (purpose) {
      case BonusAllocationPurpose.transferWarChest:
        transferAdded = amount;
        windTunnelAdded = 0;
        break;
      case BonusAllocationPurpose.windTunnelAndAeroRnD:
        transferAdded = 0;
        windTunnelAdded = amount;
        break;
      case BonusAllocationPurpose.splitTransferAndWindTunnel:
        transferAdded = amount ~/ 2;
        windTunnelAdded = amount - transferAdded;
        break;
    }

    final acceptedOffer = offer.copyWith(
      status: SponsorBonusOfferStatus.accepted,
      selectedPurpose: purpose,
    );

    final updatedTeam = team.copyWith(
      cashBalanceEur: team.cashBalanceEur + amount,
    );

    final headline =
        'Nadzwyczajna premia ${Formatters.formatCurrency(amount)} od ${offer.sponsorCompanyName}!';
    final summary =
        'Prezes ${offer.ceoName} przelał ${Formatters.formatCurrency(amount)} po sukcesie w ${offer.raceName}. '
        'Alokacja: ${purpose.title} (Transfery: +${Formatters.formatCurrency(transferAdded)}, '
        'Tunel Aero: +${Formatters.formatCurrency(windTunnelAdded)}).';

    final inboxMessage = CareerInboxMessage(
      id: 'inbox_${offer.id}_accepted',
      date: decisionDate,
      senderName: offer.ceoName,
      senderRole: offer.ceoTitle,
      subject: headline,
      body: '$summary\n\n„Świetna robota dla naszych barw. Wykorzystajcie ten zastrzyk mądrze!”',
      category: InboxCategory.sponsorNews,
      priority: InboxPriority.urgent,
      actionLabel: 'Otwórz finanse drużyny',
    );

    return SponsorBonusNegotiationOutcome(
      offer: acceptedOffer,
      cashInjectedEur: amount,
      transferBudgetAddedEur: transferAdded,
      windTunnelBudgetAddedEur: windTunnelAdded,
      updatedTeam: updatedTeam,
      inboxMessage: inboxMessage,
      headline: headline,
      summary: summary,
    );
  }

  /// Odrzuca ofertę premii nadzwyczajnej.
  static SponsorCeoBonusOffer declineOffer({
    required SponsorCeoBonusOffer offer,
    required DateTime decisionDate,
  }) {
    if (!offer.status.isActionable) {
      return offer;
    }
    return offer.copyWith(
      status: SponsorBonusOfferStatus.declined,
      ceoCallTranscript:
          '„Rozumiem, że drużyna nie potrzebuje teraz dodatkowego wsparcia. '
          'Wrócimy do rozmów przy kolejnym wielkim wyniku.”',
    );
  }

  /// Oznacza wygasłe oferty po przekroczeniu terminu ważności.
  static SponsorCeoBonusOffer expireIfNeeded({
    required SponsorCeoBonusOffer offer,
    required DateTime currentDate,
  }) {
    if (offer.status.isActionable && offer.isExpiredOn(currentDate)) {
      return offer.copyWith(status: SponsorBonusOfferStatus.expired);
    }
    return offer;
  }

  /// Generuje wiadomość w skrzynce menedżera informującą o przychodzącym telefonie od CEO.
  static CareerInboxMessage buildIncomingCallInboxMessage(
    SponsorCeoBonusOffer offer,
  ) {
    return CareerInboxMessage(
      id: 'inbox_${offer.id}_call',
      date: offer.createdAt,
      senderName: offer.ceoName,
      senderRole: offer.ceoTitle,
      subject:
          'PILNY TELEFON: ${offer.sponsorCompanyName} oferuje ${Formatters.formatCurrency(offer.offeredAmountEur)} premii!',
      body: '${offer.ceoCallTranscript}\n\n'
          'Wybierz przeznaczenie środków: Fundusz Transferowy lub Tunel Aerodynamiczny i R&D.',
      category: InboxCategory.sponsorNews,
      priority: InboxPriority.urgent,
      actionLabel: 'Odbierz telefon od CEO',
    );
  }

  static SponsorContract _selectCallingSponsor(List<SponsorContract> sponsors) {
    final sorted = List<SponsorContract>.from(sponsors)
      ..sort((a, b) {
        final tierCmp = a.sponsorTier.index.compareTo(b.sponsorTier.index);
        if (tierCmp != 0) return tierCmp;
        return b.annualBudgetEur.compareTo(a.annualBudgetEur);
      });
    return sorted.first;
  }

  static int _computeBaseOfferEur({
    required SpectacularSuccessTrigger trigger,
    required SponsorContract sponsor,
    required double tvExposureMinutes,
    required math.Random rng,
  }) {
    final double triggerBase;
    switch (trigger) {
      case SpectacularSuccessTrigger.monumentVictory:
        triggerBase = 360000;
        break;
      case SpectacularSuccessTrigger.grandTourThreeStageWins:
        triggerBase = 520000;
        break;
      case SpectacularSuccessTrigger.grandTourOverallVictory:
        triggerBase = 760000;
        break;
      case SpectacularSuccessTrigger.worldTourStageRaceSweep:
        triggerBase = 330000;
        break;
    }

    // Skala budżetu sponsora (od 1M do 25M EUR) wpływa na hojność zastrzyku:
    final budgetFactor =
        (sponsor.annualBudgetEur / 10000000.0).clamp(0.70, 1.35);
    final satisfactionFactor =
        0.85 + (sponsor.sponsorSatisfaction.clamp(0.0, 100.0) / 100.0) * 0.25;
    final tvFactor = 1.0 + (tvExposureMinutes.clamp(0.0, 180.0) / 180.0) * 0.12;
    final randomJitter = 0.92 + rng.nextDouble() * 0.16;

    final raw =
        triggerBase * budgetFactor * satisfactionFactor * tvFactor * randomJitter;
    final rounded = (raw / 10000).round() * 10000;
    return rounded.clamp(minBonusEur, maxBonusEur);
  }

  static BonusAllocationPurpose _recommendPurpose({
    required SponsorContract sponsor,
    required SpectacularSuccessTrigger trigger,
  }) {
    if (sponsor.industry == SponsorIndustry.tech ||
        sponsor.industry == SponsorIndustry.automotive) {
      return BonusAllocationPurpose.windTunnelAndAeroRnD;
    }
    if (trigger == SpectacularSuccessTrigger.grandTourOverallVictory) {
      return BonusAllocationPurpose.splitTransferAndWindTunnel;
    }
    return BonusAllocationPurpose.transferWarChest;
  }

  static String _buildCeoCallTranscript({
    required String ceoName,
    required String companyName,
    required String raceName,
    required String heroRiderName,
    required SpectacularSuccessTrigger trigger,
    required int amountEur,
    required BonusAllocationPurpose recommendedPurpose,
  }) {
    final formatted = Formatters.formatCurrency(amountEur);
    final successPhrase = switch (trigger) {
      SpectacularSuccessTrigger.monumentVictory =>
        'zwycięstwo $heroRiderName w Monumencie $raceName',
      SpectacularSuccessTrigger.grandTourThreeStageWins =>
        'niesamowite 3 zwycięstwa etapowe podczas $raceName',
      SpectacularSuccessTrigger.grandTourOverallVictory =>
        'triumf $heroRiderName w klasyfikacji generalnej $raceName',
      SpectacularSuccessTrigger.worldTourStageRaceSweep =>
        'totalna dominacja ekipy w $raceName',
    };

    return '„Tu $ceoName, prezes $companyName. Właśnie skończyłem oglądać transmisję — '
        '$successPhrase wywołało euforię w naszym zarządzie! '
        'Chcemy natychmiast przelać na konto drużyny jednorazową premię $formatted. '
        'Możesz przeznaczyć te środki na transfery albo na sesje w tunelu aerodynamicznym '
        '(osobiście sugeruję: ${recommendedPurpose.title}). Decyduj!”';
  }
}

/// Interaktywny modal telefonu od prezesa sponsora z negocjacją kwoty
/// i wyborem alokacji premii (Transfery vs Tunel Aerodynamiczny).
class SponsorBonusCallDialogWidget extends StatefulWidget {
  final SponsorCeoBonusOffer initialOffer;
  final ValueChanged<BonusAllocationPurpose>? onAccepted;
  final ValueChanged<SponsorCeoBonusOffer>? onOfferUpdated;
  final VoidCallback? onDeclined;

  const SponsorBonusCallDialogWidget({
    super.key,
    required this.initialOffer,
    this.onAccepted,
    this.onOfferUpdated,
    this.onDeclined,
  });

  @override
  State<SponsorBonusCallDialogWidget> createState() =>
      _SponsorBonusCallDialogWidgetState();
}

class _SponsorBonusCallDialogWidgetState
    extends State<SponsorBonusCallDialogWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  late SponsorCeoBonusOffer _offer;
  late BonusAllocationPurpose _selectedPurpose;
  late double _counterSliderEur;

  @override
  void initState() {
    super.initState();
    _offer = widget.initialOffer;
    _selectedPurpose =
        widget.initialOffer.selectedPurpose ?? widget.initialOffer.recommendedPurpose;
    _counterSliderEur = math
        .min(
          SponsorBonusNegotiationEvents.maxBonusEur,
          _offer.offeredAmountEur + 80000,
        )
        .toDouble();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutCubic,
      ),
    );
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  void _handleNegotiate() {
    if (!_offer.canNegotiateHigher) return;
    final updated = SponsorBonusNegotiationEvents.submitCounterOffer(
      offer: _offer,
      requestedAmountEur: _counterSliderEur.round(),
      preferredPurpose: _selectedPurpose,
    );
    setState(() {
      _offer = updated;
      if (_counterSliderEur < updated.offeredAmountEur) {
        _counterSliderEur = updated.offeredAmountEur.toDouble();
      }
    });
    widget.onOfferUpdated?.call(updated);
  }

  void _handleAccept() {
    if (!_offer.status.isActionable) return;
    widget.onAccepted?.call(_selectedPurpose);
  }

  void _handleDecline() {
    if (!_offer.status.isActionable) return;
    final declined = SponsorBonusNegotiationEvents.declineOffer(
      offer: _offer,
      decisionDate: DateTime.now(),
    );
    setState(() {
      _offer = declined;
    });
    widget.onOfferUpdated?.call(declined);
    widget.onDeclined?.call();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 620;
            final isDesktopWide = constraints.maxWidth >= 1000;
            final cardPadding = isCompact ? 16.0 : 24.0;

            return SingleChildScrollView(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isDesktopWide ? 960 : 760,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.goldAccent.withValues(alpha: 0.45),
                    width: 1.0,
                  ),
                ),
                padding: EdgeInsets.all(cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(isCompact: isCompact),
                    const SizedBox(height: 16),
                    _buildTranscriptBox(),
                    const SizedBox(height: 16),
                    if (isCompact) ...[
                      _buildOfferSummaryCard(),
                      const SizedBox(height: 12),
                      _buildNegotiationSection(),
                    ] else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: _buildOfferSummaryCard(),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 6,
                            child: _buildNegotiationSection(),
                          ),
                        ],
                      ),
                    const SizedBox(height: 18),
                    _buildPurposeSelector(isCompact: isCompact),
                    const SizedBox(height: 20),
                    _buildActionBar(isCompact: isCompact),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader({required bool isCompact}) {
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.goldAccent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.goldAccent.withValues(alpha: 0.55),
                  width: 1.0,
                ),
              ),
              child: const Icon(
                Icons.phone_in_talk_rounded,
                color: AppColors.goldAccent,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'TELEFON OD PREZESA SPONSORA',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: isCompact ? 11 : 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.goldAccent,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_offer.ceoName} • ${_offer.sponsorCompanyName}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: isCompact ? 16 : 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.cardBorder, width: 1.0),
          ),
          child: Text(
            _offer.trigger.label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTranscriptBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Text(
        _offer.ceoCallTranscript,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13.5,
          height: 1.45,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildOfferSummaryCard() {
    final patiencePct = (_offer.sponsorPatience * 100).round();
    final patienceColor = _offer.sponsorPatience >= 0.6
        ? AppColors.statusSuccess
        : (_offer.sponsorPatience >= 0.3
            ? AppColors.amberWarning
            : AppColors.crimsonAlert);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AKTUALNA OFERTA PREMIOWANA',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            Formatters.formatCurrency(_offer.offeredAmountEur),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              fontFeatures: [FontFeature.tabularFigures()],
              color: AppColors.goldAccent,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Cierpliwość prezesa',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '$patiencePct%',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: patienceColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _offer.sponsorPatience.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.background,
              valueColor: AlwaysStoppedAnimation<Color>(patienceColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Rundy negocjacji: ${_offer.negotiationRoundsUsed}/${_offer.maxNegotiationRounds}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              color: AppColors.textSecondary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNegotiationSection() {
    final canNegotiate = _offer.canNegotiateHigher &&
        _counterSliderEur.round() > _offer.offeredAmountEur;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  'NEGOCJACJA KWOTY',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Text(
                Formatters.formatCurrency(_counterSliderEur.round()),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.goldAccent,
              inactiveTrackColor: AppColors.background,
              thumbColor: AppColors.goldAccent,
              overlayColor: AppColors.goldAccent.withValues(alpha: 0.2),
            ),
            child: Slider(
              min: SponsorBonusNegotiationEvents.minBonusEur.toDouble(),
              max: SponsorBonusNegotiationEvents.maxBonusEur.toDouble(),
              divisions: 75,
              value: _counterSliderEur.clamp(
                SponsorBonusNegotiationEvents.minBonusEur.toDouble(),
                SponsorBonusNegotiationEvents.maxBonusEur.toDouble(),
              ),
              onChanged: _offer.canNegotiateHigher
                  ? (val) {
                      setState(() {
                        _counterSliderEur = ((val / 10000).round() * 10000)
                            .toDouble();
                      });
                    }
                  : null,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: _InteractiveActionButton(
              label: 'Poproś o wyższą premię',
              icon: Icons.trending_up_rounded,
              enabled: canNegotiate,
              variant: _ActionButtonVariant.secondary,
              onPressed: _handleNegotiate,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurposeSelector({required bool isCompact}) {
    const purposes = BonusAllocationPurpose.values;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'WYBIERZ CEL INWESTYCJI',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.7,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        if (isCompact)
          Column(
            children: [
              for (int i = 0; i < purposes.length; i++) ...[
                _PurposeOptionCard(
                  purpose: purposes[i],
                  selected: _selectedPurpose == purposes[i],
                  enabled: _offer.status.isActionable,
                  onTap: () => setState(() => _selectedPurpose = purposes[i]),
                ),
                if (i < purposes.length - 1) const SizedBox(height: 10),
              ],
            ],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < purposes.length; i++) ...[
                Expanded(
                  child: _PurposeOptionCard(
                    purpose: purposes[i],
                    selected: _selectedPurpose == purposes[i],
                    enabled: _offer.status.isActionable,
                    onTap: () => setState(() => _selectedPurpose = purposes[i]),
                  ),
                ),
                if (i < purposes.length - 1) const SizedBox(width: 12),
              ],
            ],
          ),
      ],
    );
  }

  Widget _buildActionBar({required bool isCompact}) {
    final actionable = _offer.status.isActionable;
    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InteractiveActionButton(
            label:
                'Akceptuj ${Formatters.formatCurrency(_offer.offeredAmountEur)}',
            icon: Icons.check_circle_rounded,
            enabled: actionable,
            variant: _ActionButtonVariant.primaryGold,
            onPressed: _handleAccept,
          ),
          const SizedBox(height: 10),
          _InteractiveActionButton(
            label: 'Odrzuć ofertę',
            icon: Icons.close_rounded,
            enabled: actionable,
            variant: _ActionButtonVariant.dangerOutline,
            onPressed: _handleDecline,
          ),
        ],
      );
    }

    return Row(
      children: [
        _InteractiveActionButton(
          label: 'Odrzuć ofertę',
          icon: Icons.close_rounded,
          enabled: actionable,
          variant: _ActionButtonVariant.dangerOutline,
          onPressed: _handleDecline,
        ),
        const Spacer(),
        _InteractiveActionButton(
          label:
              'Akceptuj ${Formatters.formatCurrency(_offer.offeredAmountEur)}',
          icon: Icons.check_circle_rounded,
          enabled: actionable,
          variant: _ActionButtonVariant.primaryGold,
          onPressed: _handleAccept,
        ),
      ],
    );
  }
}

class _PurposeOptionCard extends StatefulWidget {
  final BonusAllocationPurpose purpose;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _PurposeOptionCard({
    required this.purpose,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_PurposeOptionCard> createState() => _PurposeOptionCardState();
}

class _PurposeOptionCardState extends State<_PurposeOptionCard> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = !widget.enabled
        ? AppColors.cardBorder.withValues(alpha: 0.4)
        : widget.selected
            ? AppColors.goldAccent
            : (_focused || _hovered)
                ? AppColors.goldAccent.withValues(alpha: 0.65)
                : AppColors.cardBorder;

    final bgColor = !widget.enabled
        ? AppColors.background.withValues(alpha: 0.5)
        : widget.selected
            ? AppColors.goldAccent.withValues(alpha: 0.14)
            : _pressed
                ? AppColors.surfaceLight.withValues(alpha: 0.9)
                : _hovered
                    ? AppColors.surfaceLight
                    : AppColors.background;

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (val) => setState(() => _hovered = val),
      onShowFocusHighlight: (val) => setState(() => _focused = val),
      mouseCursor:
          widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled
            ? (_) {
                setState(() => _pressed = false);
                widget.onTap();
              }
            : null,
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    widget.purpose.icon,
                    size: 18,
                    color: widget.selected
                        ? AppColors.goldAccent
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.purpose.title,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: widget.enabled
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                widget.purpose.subtitle,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  height: 1.35,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _ActionButtonVariant {
  primaryGold,
  secondary,
  dangerOutline,
}

class _InteractiveActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final _ActionButtonVariant variant;
  final VoidCallback onPressed;

  const _InteractiveActionButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.variant,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final ButtonStyle style = ButtonStyle(
      animationDuration: const Duration(milliseconds: 200),
      padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
        EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      ),
      shape: WidgetStatePropertyAll<OutlinedBorder>(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) {
          return AppColors.surfaceLight.withValues(alpha: 0.45);
        }
        switch (variant) {
          case _ActionButtonVariant.primaryGold:
            if (states.contains(WidgetState.pressed)) {
              return AppColors.goldAccent.withValues(alpha: 0.8);
            }
            if (states.contains(WidgetState.hovered)) {
              return const Color(0xFFE0BE4C);
            }
            return AppColors.goldAccent;
          case _ActionButtonVariant.secondary:
            if (states.contains(WidgetState.pressed)) {
              return AppColors.primaryAccent;
            }
            if (states.contains(WidgetState.hovered)) {
              return AppColors.primaryAccent.withValues(alpha: 0.85);
            }
            return AppColors.primaryAccent.withValues(alpha: 0.72);
          case _ActionButtonVariant.dangerOutline:
            if (states.contains(WidgetState.hovered)) {
              return AppColors.crimsonAlert.withValues(alpha: 0.14);
            }
            return Colors.transparent;
        }
      }),
      foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) {
          return AppColors.textSecondary.withValues(alpha: 0.5);
        }
        switch (variant) {
          case _ActionButtonVariant.primaryGold:
            return AppColors.background;
          case _ActionButtonVariant.secondary:
            return AppColors.textPrimary;
          case _ActionButtonVariant.dangerOutline:
            return AppColors.crimsonAlert;
        }
      }),
      side: WidgetStateProperty.resolveWith<BorderSide>((states) {
        if (variant == _ActionButtonVariant.dangerOutline) {
          return BorderSide(
            color: states.contains(WidgetState.disabled)
                ? AppColors.cardBorder
                : AppColors.crimsonAlert.withValues(alpha: 0.6),
            width: 1.0,
          );
        }
        if (states.contains(WidgetState.focused)) {
          return const BorderSide(color: AppColors.goldAccent, width: 1.5);
        }
        return BorderSide.none;
      }),
    );

    return ElevatedButton.icon(
      onPressed: enabled ? onPressed : null,
      style: style,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.1,
        ),
      ),
    );
  }
}
