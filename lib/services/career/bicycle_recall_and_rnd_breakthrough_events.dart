// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/team/bike_manufacturer_deal.dart';
import '../../models/team/cycling_team.dart';
import '../../state/career_state_notifier.dart';

/// Rodzaj losowego zdarzenia technologicznego R&D lub jakościowego sprzętu.
enum TechnicalEventKind {
  /// Przełom inżynieryjny w trakcie sezonu (prototyp widelca lub kierownicy aero).
  rndAeroBreakthrough,

  /// Wada fabryczna partii obręczy wymagająca pilnej akcji serwisowej.
  rimBatchRecall;

  String toJson() => name;

  static TechnicalEventKind fromJson(String value) {
    return TechnicalEventKind.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TechnicalEventKind.rndAeroBreakthrough,
    );
  }

  String get label {
    switch (this) {
      case TechnicalEventKind.rndAeroBreakthrough:
        return 'Przełom Inżynieryjny R&D';
      case TechnicalEventKind.rimBatchRecall:
        return 'Akcja Serwisowa Obręczy';
    }
  }
}

/// Rodzaj komponentu objętego przełomem aerodynamicznym R&D.
enum RndPrototypeComponent {
  /// Nowy prototyp widelca aero o profilu Kamm-tail.
  aeroForkPrototype,

  /// Zintegrowany kokpit kierownicy aero z ukrytym prowadzeniem przewodów.
  aeroHandlebarCockpit;

  String toJson() => name;

  static RndPrototypeComponent fromJson(String value) {
    return RndPrototypeComponent.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RndPrototypeComponent.aeroForkPrototype,
    );
  }

  String get label {
    switch (this) {
      case RndPrototypeComponent.aeroForkPrototype:
        return 'Prototyp widelca aero';
      case RndPrototypeComponent.aeroHandlebarCockpit:
        return 'Prototyp kierownicy aero';
    }
  }
}

/// Status cyklu życia zdarzenia technologicznego lub akcji serwisowej.
enum TechnicalEventStatus {
  pendingDecision,
  activeInService,
  resolved,
  declined;

  String toJson() => name;

  static TechnicalEventStatus fromJson(String value) {
    return TechnicalEventStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TechnicalEventStatus.pendingDecision,
    );
  }

  String get label {
    switch (this) {
      case TechnicalEventStatus.pendingDecision:
        return 'Wymaga decyzji';
      case TechnicalEventStatus.activeInService:
        return 'Aktywny w sezonie';
      case TechnicalEventStatus.resolved:
        return 'Zakończono';
      case TechnicalEventStatus.declined:
        return 'Odrzucono';
    }
  }

  bool get isActionable => this == TechnicalEventStatus.pendingDecision;
}

/// Decyzja menedżera w sprawie przełomu R&D przed Tour de France.
enum RndBreakthroughChoice {
  deployBeforeTourDeFrance,
  windTunnelValidationFirst,
  declinePrototype;

  String toJson() => name;

  static RndBreakthroughChoice fromJson(String value) {
    return RndBreakthroughChoice.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RndBreakthroughChoice.deployBeforeTourDeFrance,
    );
  }

  String get label {
    switch (this) {
      case RndBreakthroughChoice.deployBeforeTourDeFrance:
        return 'Wdróż przed Tour de France (-2.5% CdA)';
      case RndBreakthroughChoice.windTunnelValidationFirst:
        return 'Waliduj w tunelu aero (-2.5% CdA, bezpiecznie)';
      case RndBreakthroughChoice.declinePrototype:
        return 'Odrzuć prototyp';
    }
  }
}

/// Decyzja menedżera w sprawie pilnej akcji serwisowej wadliwej partii obręczy.
enum RecallActionChoice {
  emergencyFactorySwap,
  mechanicInspectionAndReinforce,
  deferWithRisk;

  String toJson() => name;

  static RecallActionChoice fromJson(String value) {
    return RecallActionChoice.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RecallActionChoice.emergencyFactorySwap,
    );
  }

  String get label {
    switch (this) {
      case RecallActionChoice.emergencyFactorySwap:
        return 'Pilna wymiana fabryczna obręczy';
      case RecallActionChoice.mechanicInspectionAndReinforce:
        return 'Przegląd warsztatowy i selekcja';
      case RecallActionChoice.deferWithRisk:
        return 'Jedź dalej (ryzyko defektu)';
    }
  }
}

/// Filtr listy zdarzeń w panelu UI.
enum TechnicalEventFilter {
  all,
  breakthroughs,
  recalls;

  String get label {
    switch (this) {
      case TechnicalEventFilter.all:
        return 'Wszystkie';
      case TechnicalEventFilter.breakthroughs:
        return 'Przełomy R&D';
      case TechnicalEventFilter.recalls:
        return 'Akcje Serwisowe';
    }
  }
}

/// Ilościowy wpływ zdarzenia technologicznego na fizykę jazdy, ryzyko i budżet.
class BicycleTechnicalEventImpact {
  /// Mnożnik współczynnika CdA (np. 0.975 oznacza redukcję oporu o 2.5%).
  final double cdaMultiplier;

  /// Procentowa zmiana CdA (np. -2.5 dla przełomu aero).
  final double cdaDeltaPercent;

  /// Zmiana prawdopodobieństwa defektu/awarii koła na etapie (0.0 - 0.35).
  final double mechanicalFailureRiskDelta;

  /// Zmiana masy zestawu w gramach (ujemna = lżejszy, dodatnia = cięższy).
  final int wheelsetWeightDeltaGrams;

  /// Koszt logistyczny lub serwisowy w EUR.
  final int costEur;

  /// Liczba dni pracy mechaników potrzebna do wdrożenia / wymiany.
  final int mechanicWorkloadDays;

  /// Zmiana morale drużyny.
  final int moraleDelta;

  /// Czy rozwiązanie posiada aktualną homologację UCI.
  final bool uciHomologated;

  const BicycleTechnicalEventImpact({
    required this.cdaMultiplier,
    required this.cdaDeltaPercent,
    required this.mechanicalFailureRiskDelta,
    required this.wheelsetWeightDeltaGrams,
    required this.costEur,
    required this.mechanicWorkloadDays,
    required this.moraleDelta,
    required this.uciHomologated,
  });

  BicycleTechnicalEventImpact copyWith({
    double? cdaMultiplier,
    double? cdaDeltaPercent,
    double? mechanicalFailureRiskDelta,
    int? wheelsetWeightDeltaGrams,
    int? costEur,
    int? mechanicWorkloadDays,
    int? moraleDelta,
    bool? uciHomologated,
  }) {
    return BicycleTechnicalEventImpact(
      cdaMultiplier: cdaMultiplier ?? this.cdaMultiplier,
      cdaDeltaPercent: cdaDeltaPercent ?? this.cdaDeltaPercent,
      mechanicalFailureRiskDelta:
          mechanicalFailureRiskDelta ?? this.mechanicalFailureRiskDelta,
      wheelsetWeightDeltaGrams:
          wheelsetWeightDeltaGrams ?? this.wheelsetWeightDeltaGrams,
      costEur: costEur ?? this.costEur,
      mechanicWorkloadDays: mechanicWorkloadDays ?? this.mechanicWorkloadDays,
      moraleDelta: moraleDelta ?? this.moraleDelta,
      uciHomologated: uciHomologated ?? this.uciHomologated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cdaMultiplier': cdaMultiplier,
      'cdaDeltaPercent': cdaDeltaPercent,
      'mechanicalFailureRiskDelta': mechanicalFailureRiskDelta,
      'wheelsetWeightDeltaGrams': wheelsetWeightDeltaGrams,
      'costEur': costEur,
      'mechanicWorkloadDays': mechanicWorkloadDays,
      'moraleDelta': moraleDelta,
      'uciHomologated': uciHomologated,
    };
  }

  factory BicycleTechnicalEventImpact.fromJson(Map<String, dynamic> json) {
    return BicycleTechnicalEventImpact(
      cdaMultiplier: (json['cdaMultiplier'] as num?)?.toDouble() ?? 1.0,
      cdaDeltaPercent: (json['cdaDeltaPercent'] as num?)?.toDouble() ?? 0.0,
      mechanicalFailureRiskDelta:
          (json['mechanicalFailureRiskDelta'] as num?)?.toDouble() ?? 0.0,
      wheelsetWeightDeltaGrams:
          (json['wheelsetWeightDeltaGrams'] as num?)?.toInt() ?? 0,
      costEur: (json['costEur'] as num?)?.toInt() ?? 0,
      mechanicWorkloadDays:
          (json['mechanicWorkloadDays'] as num?)?.toInt() ?? 0,
      moraleDelta: (json['moraleDelta'] as num?)?.toInt() ?? 0,
      uciHomologated: (json['uciHomologated'] as bool?) ?? true,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BicycleTechnicalEventImpact &&
        other.cdaMultiplier == cdaMultiplier &&
        other.cdaDeltaPercent == cdaDeltaPercent &&
        other.mechanicalFailureRiskDelta == mechanicalFailureRiskDelta &&
        other.wheelsetWeightDeltaGrams == wheelsetWeightDeltaGrams &&
        other.costEur == costEur &&
        other.mechanicWorkloadDays == mechanicWorkloadDays &&
        other.moraleDelta == moraleDelta &&
        other.uciHomologated == uciHomologated;
  }

  @override
  int get hashCode => Object.hash(
        cdaMultiplier,
        cdaDeltaPercent,
        mechanicalFailureRiskDelta,
        wheelsetWeightDeltaGrams,
        costEur,
        mechanicWorkloadDays,
        moraleDelta,
        uciHomologated,
      );
}

/// Pojedyncze zdarzenie technologiczne R&D lub akcji serwisowej sprzętu.
class BicycleTechnicalEventRecord {
  final String id;
  final TechnicalEventKind kind;
  final String title;
  final String subtitle;
  final String technicalBulletinCode;
  final String manufacturerName;
  final String affectedComponentName;
  final RndPrototypeComponent? prototypeComponent;
  final String? rimBatchCode;
  final int affectedWheelsetCount;
  final DateTime detectedAt;
  final DateTime deadlineDate;
  final TechnicalEventStatus status;
  final BicycleTechnicalEventImpact impact;
  final String? chosenActionLabel;
  final DateTime? resolvedAt;

  const BicycleTechnicalEventRecord({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.technicalBulletinCode,
    required this.manufacturerName,
    required this.affectedComponentName,
    this.prototypeComponent,
    this.rimBatchCode,
    this.affectedWheelsetCount = 0,
    required this.detectedAt,
    required this.deadlineDate,
    required this.status,
    required this.impact,
    this.chosenActionLabel,
    this.resolvedAt,
  });

  bool get isUrgentRecall =>
      kind == TechnicalEventKind.rimBatchRecall &&
      status == TechnicalEventStatus.pendingDecision;

  bool get isBreakthrough => kind == TechnicalEventKind.rndAeroBreakthrough;

  BicycleTechnicalEventRecord copyWith({
    String? id,
    TechnicalEventKind? kind,
    String? title,
    String? subtitle,
    String? technicalBulletinCode,
    String? manufacturerName,
    String? affectedComponentName,
    RndPrototypeComponent? prototypeComponent,
    String? rimBatchCode,
    int? affectedWheelsetCount,
    DateTime? detectedAt,
    DateTime? deadlineDate,
    TechnicalEventStatus? status,
    BicycleTechnicalEventImpact? impact,
    String? chosenActionLabel,
    DateTime? resolvedAt,
  }) {
    return BicycleTechnicalEventRecord(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      technicalBulletinCode:
          technicalBulletinCode ?? this.technicalBulletinCode,
      manufacturerName: manufacturerName ?? this.manufacturerName,
      affectedComponentName:
          affectedComponentName ?? this.affectedComponentName,
      prototypeComponent: prototypeComponent ?? this.prototypeComponent,
      rimBatchCode: rimBatchCode ?? this.rimBatchCode,
      affectedWheelsetCount:
          affectedWheelsetCount ?? this.affectedWheelsetCount,
      detectedAt: detectedAt ?? this.detectedAt,
      deadlineDate: deadlineDate ?? this.deadlineDate,
      status: status ?? this.status,
      impact: impact ?? this.impact,
      chosenActionLabel: chosenActionLabel ?? this.chosenActionLabel,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kind': kind.toJson(),
      'title': title,
      'subtitle': subtitle,
      'technicalBulletinCode': technicalBulletinCode,
      'manufacturerName': manufacturerName,
      'affectedComponentName': affectedComponentName,
      'prototypeComponent': prototypeComponent?.toJson(),
      'rimBatchCode': rimBatchCode,
      'affectedWheelsetCount': affectedWheelsetCount,
      'detectedAt': detectedAt.toIso8601String(),
      'deadlineDate': deadlineDate.toIso8601String(),
      'status': status.toJson(),
      'impact': impact.toJson(),
      'chosenActionLabel': chosenActionLabel,
      'resolvedAt': resolvedAt?.toIso8601String(),
    };
  }

  factory BicycleTechnicalEventRecord.fromJson(Map<String, dynamic> json) {
    return BicycleTechnicalEventRecord(
      id: json['id'] as String,
      kind: TechnicalEventKind.fromJson(json['kind'] as String? ?? ''),
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      technicalBulletinCode: json['technicalBulletinCode'] as String? ?? '',
      manufacturerName: json['manufacturerName'] as String? ?? '',
      affectedComponentName: json['affectedComponentName'] as String? ?? '',
      prototypeComponent: json['prototypeComponent'] != null
          ? RndPrototypeComponent.fromJson(
              json['prototypeComponent'] as String,
            )
          : null,
      rimBatchCode: json['rimBatchCode'] as String?,
      affectedWheelsetCount:
          (json['affectedWheelsetCount'] as num?)?.toInt() ?? 0,
      detectedAt: DateTime.parse(json['detectedAt'] as String),
      deadlineDate: DateTime.parse(json['deadlineDate'] as String),
      status: TechnicalEventStatus.fromJson(json['status'] as String? ?? ''),
      impact: BicycleTechnicalEventImpact.fromJson(
        (json['impact'] as Map<String, dynamic>?) ?? const {},
      ),
      chosenActionLabel: json['chosenActionLabel'] as String?,
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BicycleTechnicalEventRecord &&
        other.id == id &&
        other.kind == kind &&
        other.status == status &&
        other.impact == impact &&
        other.chosenActionLabel == chosenActionLabel;
  }

  @override
  int get hashCode =>
      Object.hash(id, kind, status, impact, chosenActionLabel);
}

/// Kontekst wejściowy do losowania zdarzeń R&D lub akcji serwisowej w trakcie sezonu.
class BicycleTechnicalEventContext {
  final DateTime currentDate;
  final DateTime? tourDeFranceStartDate;
  final BikeManufacturerDeal manufacturerDeal;
  final TeamStaff teamStaff;
  final TeamDivision teamDivision;
  final int currentTeamBudgetEur;
  final List<BicycleTechnicalEventRecord> existingEvents;
  final int? seed;

  const BicycleTechnicalEventContext({
    required this.currentDate,
    this.tourDeFranceStartDate,
    required this.manufacturerDeal,
    required this.teamStaff,
    required this.teamDivision,
    required this.currentTeamBudgetEur,
    this.existingEvents = const [],
    this.seed,
  });
}

/// Wynik rozstrzygnięcia zdarzenia technologicznego przez menedżera.
class TechnicalEventResolutionOutcome {
  final BicycleTechnicalEventRecord updatedEvent;
  final CareerInboxMessage inboxMessage;
  final int budgetDeltaEur;
  final double cdaMultiplierApplied;

  const TechnicalEventResolutionOutcome({
    required this.updatedEvent,
    required this.inboxMessage,
    required this.budgetDeltaEur,
    required this.cdaMultiplierApplied,
  });
}

/// Stan zarządzania zdarzeniami R&D i akcjami serwisowymi sprzętu.
class BicycleRecallAndRndState {
  final List<BicycleTechnicalEventRecord> events;
  final double activeCdaMultiplier;
  final double activeMechanicalRiskPenalty;
  final int totalSpentOnServiceEur;
  final TechnicalEventFilter activeFilter;
  final String? selectedEventId;

  const BicycleRecallAndRndState({
    this.events = const [],
    this.activeCdaMultiplier = 1.0,
    this.activeMechanicalRiskPenalty = 0.0,
    this.totalSpentOnServiceEur = 0,
    this.activeFilter = TechnicalEventFilter.all,
    this.selectedEventId,
  });

  int get pendingCount =>
      events.where((e) => e.status == TechnicalEventStatus.pendingDecision).length;

  int get pendingRecallCount => events
      .where(
        (e) =>
            e.kind == TechnicalEventKind.rimBatchRecall &&
            e.status == TechnicalEventStatus.pendingDecision,
      )
      .length;

  int get activeBreakthroughCount => events
      .where(
        (e) =>
            e.kind == TechnicalEventKind.rndAeroBreakthrough &&
            e.status == TechnicalEventStatus.activeInService,
      )
      .length;

  List<BicycleTechnicalEventRecord> get filteredEvents {
    switch (activeFilter) {
      case TechnicalEventFilter.all:
        return events;
      case TechnicalEventFilter.breakthroughs:
        return events
            .where((e) => e.kind == TechnicalEventKind.rndAeroBreakthrough)
            .toList(growable: false);
      case TechnicalEventFilter.recalls:
        return events
            .where((e) => e.kind == TechnicalEventKind.rimBatchRecall)
            .toList(growable: false);
    }
  }

  BicycleRecallAndRndState copyWith({
    List<BicycleTechnicalEventRecord>? events,
    double? activeCdaMultiplier,
    double? activeMechanicalRiskPenalty,
    int? totalSpentOnServiceEur,
    TechnicalEventFilter? activeFilter,
    String? selectedEventId,
  }) {
    return BicycleRecallAndRndState(
      events: events ?? this.events,
      activeCdaMultiplier: activeCdaMultiplier ?? this.activeCdaMultiplier,
      activeMechanicalRiskPenalty:
          activeMechanicalRiskPenalty ?? this.activeMechanicalRiskPenalty,
      totalSpentOnServiceEur:
          totalSpentOnServiceEur ?? this.totalSpentOnServiceEur,
      activeFilter: activeFilter ?? this.activeFilter,
      selectedEventId: selectedEventId ?? this.selectedEventId,
    );
  }
}

/// Serwis obsługujący losowe zdarzenia technologiczne R&D (prototyp widelca lub
/// kierownicy aero obniżający CdA o 2.5% przed Tour de France) oraz pilne akcje
/// serwisowe wadliwych partii obręczy.
class BicycleRecallAndRndBreakthroughEvents {
  const BicycleRecallAndRndBreakthroughEvents();

  /// Stała redukcja współczynnika CdA (2.5%) przy wdrożeniu przełomowego prototypu.
  static const double breakthroughCdaReductionRatio = 0.025;

  /// Mnożnik CdA wynikający z redukcji o 2.5% (`1.0 - 0.025 = 0.975`).
  static const double breakthroughCdaMultiplier = 0.975;

  /// Losuje dzienne zdarzenie technologiczne R&D lub akcję serwisową obręczy.
  /// Zwraca `null`, jeśli w danym dniu nie doszło do nowego zdarzenia.
  BicycleTechnicalEventRecord? rollDailyTechnicalEvent(
    BicycleTechnicalEventContext context,
  ) {
    final rng = context.seed != null
        ? math.Random(context.seed!)
        : math.Random(
            context.currentDate.millisecondsSinceEpoch ^
                context.manufacturerDeal.manufacturerId.hashCode,
          );

    final hasPendingBreakthrough = context.existingEvents.any(
      (e) =>
          e.kind == TechnicalEventKind.rndAeroBreakthrough &&
          e.status == TechnicalEventStatus.pendingDecision,
    );
    final hasActiveBreakthroughInSeason = context.existingEvents.any(
      (e) =>
          e.kind == TechnicalEventKind.rndAeroBreakthrough &&
          e.detectedAt.year == context.currentDate.year &&
          e.status != TechnicalEventStatus.declined,
    );
    final hasPendingRecall = context.existingEvents.any(
      (e) =>
          e.kind == TechnicalEventKind.rimBatchRecall &&
          e.status == TechnicalEventStatus.pendingDecision,
    );

    final isPreTourWindow = _isPreTourDeFranceWindow(
      context.currentDate,
      context.tourDeFranceStartDate,
    );

    // Prawdopodobieństwo przełomu R&D rośnie przed Tour de France i zależy od poziomu R&D producenta.
    if (!hasPendingBreakthrough && !hasActiveBreakthroughInSeason) {
      final rndLevelFactor =
          (context.manufacturerDeal.researchAndDevelopmentLevel / 100.0)
              .clamp(0.2, 1.0);
      final divisionBoost =
          context.teamDivision == TeamDivision.worldTour ? 1.35 : 0.85;
      final baseDailyRndChance = isPreTourWindow ? 0.038 : 0.0045;
      final rndChance = (baseDailyRndChance * rndLevelFactor * divisionBoost)
          .clamp(0.001, 0.08);

      if (rng.nextDouble() < rndChance) {
        final component = rng.nextBool()
            ? RndPrototypeComponent.aeroForkPrototype
            : RndPrototypeComponent.aeroHandlebarCockpit;
        return createRndAeroBreakthroughEvent(
          date: context.currentDate,
          manufacturerDeal: context.manufacturerDeal,
          component: component,
          tourDeFranceStartDate: context.tourDeFranceStartDate,
        );
      }
    }

    // Prawdopodobieństwo wykrycia wady partii obręczy (niższe przy lepszych mechanikach i prestiżu marki).
    if (!hasPendingRecall) {
      final prestigeMitigation =
          (6 - context.manufacturerDeal.prestigeLevel.clamp(1, 5)) * 0.22;
      final mechanicMitigation =
          (1.15 - (context.teamStaff.mechanicsLevel / 120.0)).clamp(0.45, 1.1);
      final dailyRecallChance =
          (0.0032 * (0.65 + prestigeMitigation) * mechanicMitigation)
              .clamp(0.001, 0.015);

      if (rng.nextDouble() < dailyRecallChance) {
        final batchNumber = 100 + rng.nextInt(899);
        final wheelsetCount = 18 + rng.nextInt(24);
        return createRimBatchRecallEvent(
          date: context.currentDate,
          manufacturerDeal: context.manufacturerDeal,
          rimBatchCode:
              'RIM-${context.currentDate.year % 100}-$batchNumber-QC',
          affectedWheelsetCount: wheelsetCount,
        );
      }
    }

    return null;
  }

  /// Tworzy zdarzenie przełomu inżynieryjnego R&D przed Tour de France (-2.5% CdA).
  BicycleTechnicalEventRecord createRndAeroBreakthroughEvent({
    required DateTime date,
    required BikeManufacturerDeal manufacturerDeal,
    required RndPrototypeComponent component,
    DateTime? tourDeFranceStartDate,
  }) {
    final tdfStart =
        tourDeFranceStartDate ?? DateTime(date.year, 7, 1);
    final deadline = tdfStart.isAfter(date)
        ? tdfStart.subtract(const Duration(days: 2))
        : date.add(const Duration(days: 5));

    final isFork = component == RndPrototypeComponent.aeroForkPrototype;
    final componentName = isFork
        ? 'Widelec Aero Kamm-Tail SL-X (${manufacturerDeal.manufacturerName})'
        : 'Kokpit Kierownicy Aero Monocoque (${manufacturerDeal.manufacturerName})';

    final code =
        'RND-${date.year}-${isFork ? 'FK' : 'HB'}-${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';

    return BicycleTechnicalEventRecord(
      id: 'rnd_${date.millisecondsSinceEpoch}_${component.name}',
      kind: TechnicalEventKind.rndAeroBreakthrough,
      title: isFork
          ? 'Przełom R&D: Nowy prototyp widelca aero (-2.5% CdA)'
          : 'Przełom R&D: Nowy prototyp kierownicy aero (-2.5% CdA)',
      subtitle:
          'Dział inżynierii ${manufacturerDeal.manufacturerName} ukończył w tunelu aerodynamicznym $componentName. Wdrożenie przed Tour de France obniża opór aerodynamiczny (CdA) o 2.5%.',
      technicalBulletinCode: code,
      manufacturerName: manufacturerDeal.manufacturerName,
      affectedComponentName: componentName,
      prototypeComponent: component,
      detectedAt: date,
      deadlineDate: deadline,
      status: TechnicalEventStatus.pendingDecision,
      impact: BicycleTechnicalEventImpact(
        cdaMultiplier: breakthroughCdaMultiplier,
        cdaDeltaPercent: -2.5,
        mechanicalFailureRiskDelta: 0.0,
        wheelsetWeightDeltaGrams: isFork ? -35 : -45,
        costEur: 0,
        mechanicWorkloadDays: 2,
        moraleDelta: 4,
        uciHomologated: true,
      ),
    );
  }

  /// Tworzy zdarzenie wady fabrycznej partii obręczy wymagającej pilnej akcji serwisowej.
  BicycleTechnicalEventRecord createRimBatchRecallEvent({
    required DateTime date,
    required BikeManufacturerDeal manufacturerDeal,
    required String rimBatchCode,
    int affectedWheelsetCount = 24,
  }) {
    final safeWheelsetCount = affectedWheelsetCount.clamp(6, 80);
    final emergencyLogisticsCost = 8500 + (safeWheelsetCount * 350);

    return BicycleTechnicalEventRecord(
      id: 'recall_${date.millisecondsSinceEpoch}_$rimBatchCode',
      kind: TechnicalEventKind.rimBatchRecall,
      title: 'PILNA AKCJA SERWISOWA: Wada fabryczna partii obręczy',
      subtitle:
          'Kontrola jakości ${manufacturerDeal.manufacturerName} wykryła mikropęknięcia żywicy karbonowej w partii obręczy $rimBatchCode ($safeWheelsetCount kompletów kół w naszym serwisie). Wymagana natychmiastowa interwencja.',
      technicalBulletinCode: 'SB-$rimBatchCode',
      manufacturerName: manufacturerDeal.manufacturerName,
      affectedComponentName: 'Obręcze karbonowe serii $rimBatchCode',
      rimBatchCode: rimBatchCode,
      affectedWheelsetCount: safeWheelsetCount,
      detectedAt: date,
      deadlineDate: date.add(const Duration(days: 3)),
      status: TechnicalEventStatus.pendingDecision,
      impact: BicycleTechnicalEventImpact(
        cdaMultiplier: 1.0,
        cdaDeltaPercent: 0.0,
        mechanicalFailureRiskDelta: 0.22,
        wheelsetWeightDeltaGrams: 0,
        costEur: emergencyLogisticsCost,
        mechanicWorkloadDays: 3,
        moraleDelta: -3,
        uciHomologated: true,
      ),
    );
  }

  /// Rozstrzyga zdarzenie przełomu R&D według wyboru menedżera.
  TechnicalEventResolutionOutcome resolveRndBreakthrough({
    required BicycleTechnicalEventRecord event,
    required RndBreakthroughChoice choice,
    required DateTime actionDate,
  }) {
    switch (choice) {
      case RndBreakthroughChoice.deployBeforeTourDeFrance:
        final updated = event.copyWith(
          status: TechnicalEventStatus.activeInService,
          chosenActionLabel: choice.label,
          resolvedAt: actionDate,
          impact: event.impact.copyWith(
            cdaMultiplier: breakthroughCdaMultiplier,
            cdaDeltaPercent: -2.5,
            costEur: 0,
            moraleDelta: 5,
            uciHomologated: true,
          ),
        );
        return TechnicalEventResolutionOutcome(
          updatedEvent: updated,
          inboxMessage: toInboxMessage(updated),
          budgetDeltaEur: 0,
          cdaMultiplierApplied: breakthroughCdaMultiplier,
        );

      case RndBreakthroughChoice.windTunnelValidationFirst:
        const validationCost = 12000;
        final updated = event.copyWith(
          status: TechnicalEventStatus.activeInService,
          chosenActionLabel: choice.label,
          resolvedAt: actionDate,
          impact: event.impact.copyWith(
            cdaMultiplier: breakthroughCdaMultiplier,
            cdaDeltaPercent: -2.5,
            mechanicalFailureRiskDelta: -0.02,
            costEur: validationCost,
            mechanicWorkloadDays: 3,
            moraleDelta: 6,
            uciHomologated: true,
          ),
        );
        return TechnicalEventResolutionOutcome(
          updatedEvent: updated,
          inboxMessage: toInboxMessage(updated),
          budgetDeltaEur: -validationCost,
          cdaMultiplierApplied: breakthroughCdaMultiplier,
        );

      case RndBreakthroughChoice.declinePrototype:
        final updated = event.copyWith(
          status: TechnicalEventStatus.declined,
          chosenActionLabel: choice.label,
          resolvedAt: actionDate,
          impact: event.impact.copyWith(
            cdaMultiplier: 1.0,
            cdaDeltaPercent: 0.0,
            costEur: 0,
            moraleDelta: 0,
          ),
        );
        return TechnicalEventResolutionOutcome(
          updatedEvent: updated,
          inboxMessage: toInboxMessage(updated),
          budgetDeltaEur: 0,
          cdaMultiplierApplied: 1.0,
        );
    }
  }

  /// Rozstrzyga pilną akcję serwisową wadliwej partii obręczy.
  TechnicalEventResolutionOutcome resolveRimRecall({
    required BicycleTechnicalEventRecord event,
    required RecallActionChoice choice,
    required DateTime actionDate,
    int mechanicsLevel = 70,
  }) {
    switch (choice) {
      case RecallActionChoice.emergencyFactorySwap:
        final logisticsCost = (event.impact.costEur * 0.45).round();
        final updated = event.copyWith(
          status: TechnicalEventStatus.resolved,
          chosenActionLabel: choice.label,
          resolvedAt: actionDate,
          impact: event.impact.copyWith(
            mechanicalFailureRiskDelta: 0.0,
            wheelsetWeightDeltaGrams: 15,
            costEur: logisticsCost,
            mechanicWorkloadDays: 2,
            moraleDelta: 1,
          ),
        );
        return TechnicalEventResolutionOutcome(
          updatedEvent: updated,
          inboxMessage: toInboxMessage(updated),
          budgetDeltaEur: -logisticsCost,
          cdaMultiplierApplied: 1.0,
        );

      case RecallActionChoice.mechanicInspectionAndReinforce:
        const inspectionCost = 3500;
        final residualRisk =
            mechanicsLevel >= 80 ? 0.02 : 0.05;
        final updated = event.copyWith(
          status: TechnicalEventStatus.resolved,
          chosenActionLabel: choice.label,
          resolvedAt: actionDate,
          impact: event.impact.copyWith(
            mechanicalFailureRiskDelta: residualRisk,
            costEur: inspectionCost,
            mechanicWorkloadDays: 4,
            moraleDelta: 0,
          ),
        );
        return TechnicalEventResolutionOutcome(
          updatedEvent: updated,
          inboxMessage: toInboxMessage(updated),
          budgetDeltaEur: -inspectionCost,
          cdaMultiplierApplied: 1.0,
        );

      case RecallActionChoice.deferWithRisk:
        final updated = event.copyWith(
          status: TechnicalEventStatus.activeInService,
          chosenActionLabel: choice.label,
          resolvedAt: actionDate,
          impact: event.impact.copyWith(
            mechanicalFailureRiskDelta: 0.22,
            costEur: 0,
            mechanicWorkloadDays: 0,
            moraleDelta: -4,
          ),
        );
        return TechnicalEventResolutionOutcome(
          updatedEvent: updated,
          inboxMessage: toInboxMessage(updated),
          budgetDeltaEur: 0,
          cdaMultiplierApplied: 1.0,
        );
    }
  }

  /// Wylicza łączny mnożnik CdA wynikający ze wszystkich aktywnych wdrożeń R&D.
  double computeEffectiveCdaMultiplier(
    List<BicycleTechnicalEventRecord> events,
  ) {
    var multiplier = 1.0;
    for (final event in events) {
      if (event.status == TechnicalEventStatus.activeInService ||
          (event.kind == TechnicalEventKind.rndAeroBreakthrough &&
              event.status == TechnicalEventStatus.resolved)) {
        multiplier *= event.impact.cdaMultiplier;
      }
    }
    return multiplier.clamp(0.88, 1.05);
  }

  /// Wylicza łączną karę ryzyka defektu mechanicznego z nierozwiązanych akcji serwisowych.
  double computeMechanicalFailureRiskPenalty(
    List<BicycleTechnicalEventRecord> events,
  ) {
    var penalty = 0.0;
    for (final event in events) {
      if (event.kind == TechnicalEventKind.rimBatchRecall &&
          (event.status == TechnicalEventStatus.pendingDecision ||
              event.status == TechnicalEventStatus.activeInService)) {
        penalty += event.impact.mechanicalFailureRiskDelta;
      }
    }
    return penalty.clamp(0.0, 0.5);
  }

  /// Szacuje oszczędność mocy w watach przy danej redukcji CdA i prędkości jazdy.
  double estimateWattsSavedAtSpeed(
    double cdaMultiplier, {
    double baseCda = 0.275,
    double speedKmh = 45.0,
    double airDensityKgM3 = 1.225,
  }) {
    if (cdaMultiplier >= 1.0) return 0.0;
    final deltaCda = baseCda * (1.0 - cdaMultiplier);
    final vMs = speedKmh / 3.6;
    return 0.5 * airDensityKgM3 * deltaCda * vMs * vMs * vMs;
  }

  /// Konwertuje zdarzenie technologiczne na wiadomość do skrzynki menedżera.
  CareerInboxMessage toInboxMessage(BicycleTechnicalEventRecord event) {
    final isRecall = event.kind == TechnicalEventKind.rimBatchRecall;
    final priority =
        isRecall && event.status == TechnicalEventStatus.pendingDecision
            ? InboxPriority.urgent
            : InboxPriority.normal;

    final statusSuffix = event.chosenActionLabel != null
        ? '\n\nPodjęta decyzja: ${event.chosenActionLabel}.'
        : '';

    return CareerInboxMessage(
      id: 'inbox_${event.id}_${event.status.name}',
      date: event.resolvedAt ?? event.detectedAt,
      senderName: '${event.manufacturerName} R&D / Serwis',
      senderRole: isRecall
          ? 'Kontrola Jakości Sprzętu'
          : 'Główny Inżynier Aerodynamiki',
      subject: '${event.technicalBulletinCode}: ${event.title}',
      body: '${event.subtitle}$statusSuffix',
      category: isRecall ? InboxCategory.general : InboxCategory.raceBriefing,
      priority: priority,
      actionLabel: event.status.isActionable
          ? (isRecall ? 'Rozpocznij akcję serwisową' : 'Zatwierdź prototyp R&D')
          : null,
    );
  }

  bool _isPreTourDeFranceWindow(
    DateTime currentDate,
    DateTime? tourDeFranceStartDate,
  ) {
    final tdfStart =
        tourDeFranceStartDate ?? DateTime(currentDate.year, 7, 1);
    final daysUntilTdf = tdfStart.difference(currentDate).inDays;
    return daysUntilTdf >= 3 && daysUntilTdf <= 45;
  }
}

/// Kontroler Riverpod zarządzający zdarzeniami R&D i akcjami serwisowymi sprzętu.
class BicycleRecallAndRndNotifier
    extends StateNotifier<BicycleRecallAndRndState> {
  final BicycleRecallAndRndBreakthroughEvents _service;

  BicycleRecallAndRndNotifier({
    BicycleRecallAndRndBreakthroughEvents? service,
    BicycleRecallAndRndState? initialState,
  })  : _service = service ?? const BicycleRecallAndRndBreakthroughEvents(),
        super(initialState ?? const BicycleRecallAndRndState());

  void setFilter(TechnicalEventFilter filter) {
    state = state.copyWith(activeFilter: filter);
  }

  void selectEvent(String? eventId) {
    state = state.copyWith(selectedEventId: eventId);
  }

  /// Dodaje nowe zdarzenie wygenerowane w trakcie sezonu.
  void registerEvent(BicycleTechnicalEventRecord event) {
    final updatedList = [event, ...state.events];
    _recomputeState(updatedList);
  }

  /// Symuluje losowe sprawdzenie dnia kariery i rejestruje zdarzenie, jeśli wystąpiło.
  BicycleTechnicalEventRecord? evaluateDay(
    BicycleTechnicalEventContext context,
  ) {
    final rolled = _service.rollDailyTechnicalEvent(
      BicycleTechnicalEventContext(
        currentDate: context.currentDate,
        tourDeFranceStartDate: context.tourDeFranceStartDate,
        manufacturerDeal: context.manufacturerDeal,
        teamStaff: context.teamStaff,
        teamDivision: context.teamDivision,
        currentTeamBudgetEur: context.currentTeamBudgetEur,
        existingEvents: state.events,
        seed: context.seed,
      ),
    );
    if (rolled != null) {
      registerEvent(rolled);
    }
    return rolled;
  }

  /// Rozstrzyga przełom R&D wybraną decyzją.
  TechnicalEventResolutionOutcome? decideRndBreakthrough({
    required String eventId,
    required RndBreakthroughChoice choice,
    required DateTime actionDate,
  }) {
    final index = state.events.indexWhere((e) => e.id == eventId);
    if (index < 0) return null;

    final outcome = _service.resolveRndBreakthrough(
      event: state.events[index],
      choice: choice,
      actionDate: actionDate,
    );

    final updatedList = [...state.events];
    updatedList[index] = outcome.updatedEvent;
    _recomputeState(
      updatedList,
      additionalSpendEur:
          outcome.budgetDeltaEur < 0 ? -outcome.budgetDeltaEur : 0,
    );
    return outcome;
  }

  /// Rozstrzyga pilną akcję serwisową obręczy.
  TechnicalEventResolutionOutcome? decideRimRecall({
    required String eventId,
    required RecallActionChoice choice,
    required DateTime actionDate,
    int mechanicsLevel = 70,
  }) {
    final index = state.events.indexWhere((e) => e.id == eventId);
    if (index < 0) return null;

    final outcome = _service.resolveRimRecall(
      event: state.events[index],
      choice: choice,
      actionDate: actionDate,
      mechanicsLevel: mechanicsLevel,
    );

    final updatedList = [...state.events];
    updatedList[index] = outcome.updatedEvent;
    _recomputeState(
      updatedList,
      additionalSpendEur:
          outcome.budgetDeltaEur < 0 ? -outcome.budgetDeltaEur : 0,
    );
    return outcome;
  }

  void _recomputeState(
    List<BicycleTechnicalEventRecord> updatedList, {
    int additionalSpendEur = 0,
  }) {
    state = state.copyWith(
      events: List<BicycleTechnicalEventRecord>.unmodifiable(updatedList),
      activeCdaMultiplier:
          _service.computeEffectiveCdaMultiplier(updatedList),
      activeMechanicalRiskPenalty:
          _service.computeMechanicalFailureRiskPenalty(updatedList),
      totalSpentOnServiceEur:
          state.totalSpentOnServiceEur + additionalSpendEur,
    );
  }
}

final bicycleRecallAndRndProvider = StateNotifierProvider<
    BicycleRecallAndRndNotifier, BicycleRecallAndRndState>((ref) {
  return BicycleRecallAndRndNotifier();
});

/// Responsywny panel UI prezentujący zdarzenia R&D (przełomy aero -2.5% CdA)
/// oraz pilne akcje serwisowe partii obręczy.
class BicycleRecallAndRndBreakthroughPanel extends StatelessWidget {
  final BicycleRecallAndRndState state;
  final TechnicalEventFilter activeFilter;
  final ValueChanged<TechnicalEventFilter> onFilterChanged;
  final void Function(String eventId, RndBreakthroughChoice choice)
      onRndDecision;
  final void Function(String eventId, RecallActionChoice choice)
      onRecallDecision;
  final int availableBudgetEur;
  final bool isInteractionLocked;

  const BicycleRecallAndRndBreakthroughPanel({
    super.key,
    required this.state,
    required this.activeFilter,
    required this.onFilterChanged,
    required this.onRndDecision,
    required this.onRecallDecision,
    this.availableBudgetEur = 1000000,
    this.isInteractionLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    const service = BicycleRecallAndRndBreakthroughEvents();
    final wattsSaved = service.estimateWattsSavedAtSpeed(
      state.activeCdaMultiplier,
    );
    final cdaPercentDelta = (state.activeCdaMultiplier - 1.0) * 100.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isCompact = width < 640;
        final isWideDesktop = width >= 1120;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 1),
          ),
          padding: EdgeInsets.all(isCompact ? 14 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(isCompact),
              const SizedBox(height: 16),
              _buildTelemetryStrip(
                isCompact: isCompact,
                cdaPercentDelta: cdaPercentDelta,
                wattsSaved: wattsSaved,
              ),
              const SizedBox(height: 16),
              _buildFilterRow(isCompact),
              const SizedBox(height: 16),
              if (state.filteredEvents.isEmpty)
                _buildEmptyState()
              else if (isWideDesktop)
                _buildWideGrid(state.filteredEvents)
              else
                _buildVerticalList(state.filteredEvents, isCompact),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isCompact) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primaryAccent.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primaryAccent.withValues(alpha: 0.45),
            ),
          ),
          child: const Icon(
            Icons.precision_manufacturing_rounded,
            color: AppColors.goldAccent,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Inżynieria R&D i Kontrola Jakości Sprzętu',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isCompact ? 16 : 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Przełomy aerodynamiczne przed Tour de France oraz pilne akcje serwisowe komponentów.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  letterSpacing: -0.1,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTelemetryStrip({
    required bool isCompact,
    required double cdaPercentDelta,
    required double wattsSaved,
  }) {
    final cards = [
      _TelemetryMetricTile(
        label: 'AKTYWNA DELTA CdA',
        value:
            '${cdaPercentDelta <= 0 ? '' : '+'}${cdaPercentDelta.toStringAsFixed(1)}%',
        accentColor: cdaPercentDelta < 0
            ? AppColors.statusSuccess
            : AppColors.textPrimary,
        icon: Icons.air_rounded,
      ),
      _TelemetryMetricTile(
        label: 'ZYSK @ 45 KM/H',
        value: '+${wattsSaved.toStringAsFixed(1)} W',
        accentColor:
            wattsSaved > 0 ? AppColors.accentBlue : AppColors.textSecondary,
        icon: Icons.bolt_rounded,
      ),
      _TelemetryMetricTile(
        label: 'PILNE AKCJE SERWISOWE',
        value: '${state.pendingRecallCount}',
        accentColor: state.pendingRecallCount > 0
            ? AppColors.crimsonAlert
            : AppColors.statusSuccess,
        icon: Icons.warning_amber_rounded,
      ),
      _TelemetryMetricTile(
        label: 'RYZYKO DEFEKTU',
        value:
            '+${(state.activeMechanicalRiskPenalty * 100).toStringAsFixed(0)}%',
        accentColor: state.activeMechanicalRiskPenalty > 0
            ? AppColors.amberWarning
            : AppColors.statusSuccess,
        icon: Icons.build_circle_outlined,
      ),
    ];

    if (isCompact) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 10),
              Expanded(child: cards[1]),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: cards[2]),
              const SizedBox(width: 10),
              Expanded(child: cards[3]),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i < cards.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }

  Widget _buildFilterRow(bool isCompact) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: TechnicalEventFilter.values.map((filter) {
        final selected = filter == activeFilter;
        return _InteractivePillButton(
          label: filter.label,
          isSelected: selected,
          isDisabled: isInteractionLocked,
          onPressed: () => onFilterChanged(filter),
        );
      }).toList(growable: false),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_outlined,
            color: AppColors.textSecondary,
            size: 32,
          ),
          SizedBox(height: 10),
          Text(
            'Brak aktywnych biuletynów technicznych R&D',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Wszystkie rowery i koła drużyny spełniają normy kontroli jakości.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideGrid(List<BicycleTechnicalEventRecord> items) {
    final rows = <Widget>[];
    for (int i = 0; i < items.length; i += 2) {
      final first = items[i];
      final second = i + 1 < items.length ? items[i + 1] : null;
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _TechnicalEventCard(
                event: first,
                isCompact: false,
                availableBudgetEur: availableBudgetEur,
                isInteractionLocked: isInteractionLocked,
                onRndDecision: (choice) => onRndDecision(first.id, choice),
                onRecallDecision: (choice) =>
                    onRecallDecision(first.id, choice),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: second != null
                  ? _TechnicalEventCard(
                      event: second,
                      isCompact: false,
                      availableBudgetEur: availableBudgetEur,
                      isInteractionLocked: isInteractionLocked,
                      onRndDecision: (choice) =>
                          onRndDecision(second.id, choice),
                      onRecallDecision: (choice) =>
                          onRecallDecision(second.id, choice),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );
      if (i + 2 < items.length) {
        rows.add(const SizedBox(height: 14));
      }
    }
    return Column(children: rows);
  }

  Widget _buildVerticalList(
    List<BicycleTechnicalEventRecord> items,
    bool isCompact,
  ) {
    return Column(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          _TechnicalEventCard(
            event: items[i],
            isCompact: isCompact,
            availableBudgetEur: availableBudgetEur,
            isInteractionLocked: isInteractionLocked,
            onRndDecision: (choice) => onRndDecision(items[i].id, choice),
            onRecallDecision: (choice) => onRecallDecision(items[i].id, choice),
          ),
          if (i < items.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _TelemetryMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color accentColor;
  final IconData icon;

  const _TelemetryMetricTile({
    required this.label,
    required this.value,
    required this.accentColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: accentColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TechnicalEventCard extends StatefulWidget {
  final BicycleTechnicalEventRecord event;
  final bool isCompact;
  final int availableBudgetEur;
  final bool isInteractionLocked;
  final ValueChanged<RndBreakthroughChoice> onRndDecision;
  final ValueChanged<RecallActionChoice> onRecallDecision;

  const _TechnicalEventCard({
    required this.event,
    required this.isCompact,
    required this.availableBudgetEur,
    required this.isInteractionLocked,
    required this.onRndDecision,
    required this.onRecallDecision,
  });

  @override
  State<_TechnicalEventCard> createState() => _TechnicalEventCardState();
}

class _TechnicalEventCardState extends State<_TechnicalEventCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final isRecall = event.kind == TechnicalEventKind.rimBatchRecall;
    final accent = isRecall ? AppColors.crimsonAlert : AppColors.goldAccent;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.all(widget.isCompact ? 14 : 16),
        decoration: BoxDecoration(
          color: _isHovered ? AppColors.surfaceLight : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered
                ? accent.withValues(alpha: 0.7)
                : AppColors.cardBorder,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _StatusBadge(
                  text: event.technicalBulletinCode,
                  color: accent,
                ),
                _StatusBadge(
                  text: event.status.label,
                  color: _statusColor(event.status),
                ),
                Text(
                  event.manufacturerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              event.title,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: widget.isCompact ? 14.5 : 15.5,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              event.subtitle,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (event.impact.cdaDeltaPercent != 0.0)
                  _SpecChip(
                    icon: Icons.speed_rounded,
                    label:
                        'CdA ${event.impact.cdaDeltaPercent.toStringAsFixed(1)}%',
                    color: AppColors.statusSuccess,
                  ),
                if (event.impact.wheelsetWeightDeltaGrams != 0)
                  _SpecChip(
                    icon: Icons.scale_rounded,
                    label:
                        '${event.impact.wheelsetWeightDeltaGrams > 0 ? '+' : ''}${event.impact.wheelsetWeightDeltaGrams} g',
                    color: AppColors.accentBlue,
                  ),
                if (event.affectedWheelsetCount > 0)
                  _SpecChip(
                    icon: Icons.tire_repair_rounded,
                    label: '${event.affectedWheelsetCount} kpl. kół',
                    color: AppColors.amberWarning,
                  ),
                if (event.impact.costEur > 0)
                  _SpecChip(
                    icon: Icons.euro_rounded,
                    label: Formatters.formatCurrency(event.impact.costEur),
                    color: AppColors.textPrimary,
                  ),
              ],
            ),
            if (event.status.isActionable) ...[
              const SizedBox(height: 14),
              _buildActionButtons(event, isRecall),
            ] else if (event.chosenActionLabel != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Text(
                  'Decyzja: ${event.chosenActionLabel}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    BicycleTechnicalEventRecord event,
    bool isRecall,
  ) {
    if (isRecall) {
      final swapCost = (event.impact.costEur * 0.45).round();
      final canAffordSwap = widget.availableBudgetEur >= swapCost;
      final canAffordInspect = widget.availableBudgetEur >= 3500;

      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _InteractiveActionButton(
            label:
                'Wymiana fabryczna (${Formatters.formatCurrency(swapCost)})',
            isPrimary: true,
            isDisabled: widget.isInteractionLocked || !canAffordSwap,
            onPressed: () =>
                widget.onRecallDecision(RecallActionChoice.emergencyFactorySwap),
          ),
          _InteractiveActionButton(
            label: 'Przegląd warsztatowy (3 500 €)',
            isPrimary: false,
            isDisabled: widget.isInteractionLocked || !canAffordInspect,
            onPressed: () => widget.onRecallDecision(
              RecallActionChoice.mechanicInspectionAndReinforce,
            ),
          ),
          _InteractiveActionButton(
            label: 'Odrocz (ryzyko)',
            isPrimary: false,
            isDisabled: widget.isInteractionLocked,
            onPressed: () =>
                widget.onRecallDecision(RecallActionChoice.deferWithRisk),
          ),
        ],
      );
    }

    final canAffordValidation = widget.availableBudgetEur >= 12000;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _InteractiveActionButton(
          label: 'Wdróż przed Tour de France (-2.5% CdA)',
          isPrimary: true,
          isDisabled: widget.isInteractionLocked,
          onPressed: () => widget
              .onRndDecision(RndBreakthroughChoice.deployBeforeTourDeFrance),
        ),
        _InteractiveActionButton(
          label: 'Walidacja w tunelu (12 000 €)',
          isPrimary: false,
          isDisabled: widget.isInteractionLocked || !canAffordValidation,
          onPressed: () => widget
              .onRndDecision(RndBreakthroughChoice.windTunnelValidationFirst),
        ),
        _InteractiveActionButton(
          label: 'Odrzuć',
          isPrimary: false,
          isDisabled: widget.isInteractionLocked,
          onPressed: () =>
              widget.onRndDecision(RndBreakthroughChoice.declinePrototype),
        ),
      ],
    );
  }

  Color _statusColor(TechnicalEventStatus status) {
    switch (status) {
      case TechnicalEventStatus.pendingDecision:
        return AppColors.amberWarning;
      case TechnicalEventStatus.activeInService:
        return AppColors.statusSuccess;
      case TechnicalEventStatus.resolved:
        return AppColors.accentBlue;
      case TechnicalEventStatus.declined:
        return AppColors.textSecondary;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
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

class _SpecChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SpecChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractivePillButton extends StatefulWidget {
  final String label;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onPressed;

  const _InteractivePillButton({
    required this.label,
    required this.isSelected,
    required this.isDisabled,
    required this.onPressed,
  });

  @override
  State<_InteractivePillButton> createState() => _InteractivePillButtonState();
}

class _InteractivePillButtonState extends State<_InteractivePillButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isSelected
        ? AppColors.primaryAccent
        : (_hovered ? AppColors.surfaceLight : AppColors.surface);
    final borderColor = _focused
        ? AppColors.goldAccent
        : (widget.isSelected ? AppColors.primaryAccent : AppColors.cardBorder);

    return FocusableActionDetector(
      enabled: !widget.isDisabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: widget.isDisabled
            ? null
            : (_) => setState(() => _pressed = true),
        onTapUp: widget.isDisabled
            ? null
            : (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.isDisabled ? null : widget.onPressed,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: widget.isDisabled
                  ? bgColor.withValues(alpha: 0.45)
                  : bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: _focused ? 1.5 : 1),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: widget.isDisabled
                    ? AppColors.textSecondary.withValues(alpha: 0.5)
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractiveActionButton extends StatefulWidget {
  final String label;
  final bool isPrimary;
  final bool isDisabled;
  final VoidCallback onPressed;

  const _InteractiveActionButton({
    required this.label,
    required this.isPrimary,
    required this.isDisabled,
    required this.onPressed,
  });

  @override
  State<_InteractiveActionButton> createState() =>
      _InteractiveActionButtonState();
}

class _InteractiveActionButtonState extends State<_InteractiveActionButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final baseColor =
        widget.isPrimary ? AppColors.primaryAccent : AppColors.surfaceLight;
    final hoverColor = widget.isPrimary
        ? AppColors.primaryAccent.withValues(alpha: 0.85)
        : AppColors.cardBorder;
    final borderColor = _focused
        ? AppColors.goldAccent
        : (widget.isPrimary ? AppColors.goldAccent.withValues(alpha: 0.55) : AppColors.cardBorder);

    return FocusableActionDetector(
      enabled: !widget.isDisabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: widget.isDisabled
            ? null
            : (_) => setState(() => _pressed = true),
        onTapUp: widget.isDisabled
            ? null
            : (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.isDisabled ? null : widget.onPressed,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: widget.isDisabled
                  ? AppColors.surface.withValues(alpha: 0.5)
                  : (_hovered ? hoverColor : baseColor),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: widget.isDisabled
                    ? AppColors.cardBorder.withValues(alpha: 0.5)
                    : borderColor,
                width: _focused ? 1.5 : 1,
              ),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: widget.isDisabled
                    ? AppColors.textSecondary.withValues(alpha: 0.55)
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
