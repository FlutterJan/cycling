import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'rider_race_state.dart';

/// Rola kolarza w hierarchii taktycznej drużyny na etapie.
enum TeamHierarchyRole {
  /// Główny lider drużyny (nr 1 — domyślny priorytet i ochrona pomocników).
  primaryLeader,

  /// Wicelider drużyny (nr 2 — przejmuje ochronę w razie problemów nr 1).
  coLeader,

  /// Kluczowy pomocnik górski / klasykowy (rezerwowy kapitan szosowy).
  protectedDomestique,

  /// Pomocnik pracujący na rzecz aktywnego lidera.
  domestique;

  String toJson() => name;

  static TeamHierarchyRole fromJson(String value) {
    return TeamHierarchyRole.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TeamHierarchyRole.domestique,
    );
  }

  String get label {
    switch (this) {
      case TeamHierarchyRole.primaryLeader:
        return 'Lider #1';
      case TeamHierarchyRole.coLeader:
        return 'Wicelider #2';
      case TeamHierarchyRole.protectedDomestique:
        return 'Kluczowy pomocnik';
      case TeamHierarchyRole.domestique:
        return 'Pomocnik';
    }
  }
}

/// Przyczyna wyzwolenia dynamicznej zmiany lidera na szosie.
enum LeaderChangeTriggerReason {
  /// Brak powodu — główny lider jedzie bez problemów.
  none,

  /// Główny lider uległ kraksie na trasie.
  crash,

  /// Główny lider stracił kontakt z grupą główną / peletonem.
  droppedFromGroup,

  /// Główny lider zgłosił przez radio słabą dyspozycję dnia ("Bad Legs").
  badLegsRadioReport,

  /// Główny lider wycofał się z wyścigu (DNF).
  abandoned,

  /// Ręczna decyzja dyrektora sportowego z wozu technicznego.
  manualDsOverride;

  String toJson() => name;

  static LeaderChangeTriggerReason fromJson(String value) {
    return LeaderChangeTriggerReason.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => LeaderChangeTriggerReason.none,
    );
  }

  String get label {
    switch (this) {
      case LeaderChangeTriggerReason.none:
        return 'Brak incydentu';
      case LeaderChangeTriggerReason.crash:
        return 'Kraksa lidera #1';
      case LeaderChangeTriggerReason.droppedFromGroup:
        return 'Utrata kontaktu z grupą';
      case LeaderChangeTriggerReason.badLegsRadioReport:
        return 'Radio: "Bad Legs"';
      case LeaderChangeTriggerReason.abandoned:
        return 'Wycofanie z etapu (DNF)';
      case LeaderChangeTriggerReason.manualDsOverride:
        return 'Decyzja DS przez radio';
    }
  }
}

/// Aktualny status dowodzenia i ochrony w drużynie na szosie.
enum LeaderChangeStatus {
  /// Główny lider (nr 1) utrzymuje ochronę pomocników i status priorytetowy.
  primaryInCommand,

  /// Wicelider (nr 2) automatycznie przejął ochronę i status priorytetowy.
  coLeaderInCommand,

  /// Rezerwowy kapitan (kluczowy pomocnik) przejął rolę po niedostępności nr 1 i nr 2.
  fallbackCaptainInCommand,

  /// Przywrócono status priorytetowy głównemu liderowi po powrocie do grupy.
  restoredToPrimary,

  /// Brak zdolnego lidera w grupie — tryb wolnej ręki / polowania na etap.
  noViableLeader;

  String toJson() => name;

  static LeaderChangeStatus fromJson(String value) {
    return LeaderChangeStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => LeaderChangeStatus.primaryInCommand,
    );
  }

  String get label {
    switch (this) {
      case LeaderChangeStatus.primaryInCommand:
        return 'Lider #1 przy władzy';
      case LeaderChangeStatus.coLeaderInCommand:
        return 'Wicelider #2 przejął ochronę';
      case LeaderChangeStatus.fallbackCaptainInCommand:
        return 'Kapitan rezerwowy w grupie';
      case LeaderChangeStatus.restoredToPrimary:
        return 'Przywrócono Lidera #1';
      case LeaderChangeStatus.noViableLeader:
        return 'Wolna ręka (brak lidera)';
    }
  }
}

/// Profil kolarza drużyny na szosie oceniany przez logikę zmiany lidera.
class TeamRoadRiderProfile {
  final String riderId;
  final String riderName;
  final int bibNumber;
  final TeamHierarchyRole hierarchyRole;

  /// Indeks grupy na etapie (0 = czołówka, 1 = peleton główny, 2+ = grupy pościgowe).
  final int groupIndex;

  /// Strata czasowa do docelowej grupy faworytów w sekundach [s].
  final double timeGapToGroupSeconds;

  /// Czy kolarz uległ kraksie w trakcie etapu.
  final bool hasCrashed;

  /// Czy kolarz wycofał się z wyścigu (DNF).
  final bool isAbandoned;

  /// Czy kolarz zgłosił przez radio słabą dyspozycję dnia ("Bad Legs").
  final bool reportedBadLegs;

  /// Ukryta/odkryta dyspozycja dnia (-5..+5). Wartości <= -3 oznaczają słabą nogę.
  final int dayConditionScore;

  /// Poziom skumulowanego zmęczenia (0.0 = świeży, 1.0 = wyczerpany).
  final double fatigueRatio;

  /// Aktualna pozycja w klasyfikacji generalnej (GC).
  final int gcPosition;

  /// Aktualne polecenie taktyczne kolarza.
  final TacticalOrder currentOrder;

  /// Identyfikator kolarza, którego aktualnie osłania ten pomocnik (jeśli dotyczy).
  final String? protectingRiderId;

  const TeamRoadRiderProfile({
    required this.riderId,
    required this.riderName,
    this.bibNumber = 1,
    required this.hierarchyRole,
    this.groupIndex = 0,
    this.timeGapToGroupSeconds = 0.0,
    this.hasCrashed = false,
    this.isAbandoned = false,
    this.reportedBadLegs = false,
    this.dayConditionScore = 0,
    this.fatigueRatio = 0.2,
    this.gcPosition = 10,
    this.currentOrder = TacticalOrder.holdPosition,
    this.protectingRiderId,
  });

  bool get isDomestiqueRole =>
      hierarchyRole == TeamHierarchyRole.domestique ||
      hierarchyRole == TeamHierarchyRole.protectedDomestique;

  TeamRoadRiderProfile copyWith({
    String? riderId,
    String? riderName,
    int? bibNumber,
    TeamHierarchyRole? hierarchyRole,
    int? groupIndex,
    double? timeGapToGroupSeconds,
    bool? hasCrashed,
    bool? isAbandoned,
    bool? reportedBadLegs,
    int? dayConditionScore,
    double? fatigueRatio,
    int? gcPosition,
    TacticalOrder? currentOrder,
    String? protectingRiderId,
    bool clearProtectingRiderId = false,
  }) {
    return TeamRoadRiderProfile(
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      bibNumber: bibNumber ?? this.bibNumber,
      hierarchyRole: hierarchyRole ?? this.hierarchyRole,
      groupIndex: groupIndex ?? this.groupIndex,
      timeGapToGroupSeconds:
          timeGapToGroupSeconds ?? this.timeGapToGroupSeconds,
      hasCrashed: hasCrashed ?? this.hasCrashed,
      isAbandoned: isAbandoned ?? this.isAbandoned,
      reportedBadLegs: reportedBadLegs ?? this.reportedBadLegs,
      dayConditionScore: dayConditionScore ?? this.dayConditionScore,
      fatigueRatio: (fatigueRatio ?? this.fatigueRatio).clamp(0.0, 1.0),
      gcPosition: gcPosition ?? this.gcPosition,
      currentOrder: currentOrder ?? this.currentOrder,
      protectingRiderId: clearProtectingRiderId
          ? null
          : (protectingRiderId ?? this.protectingRiderId),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'riderName': riderName,
      'bibNumber': bibNumber,
      'hierarchyRole': hierarchyRole.toJson(),
      'groupIndex': groupIndex,
      'timeGapToGroupSeconds': timeGapToGroupSeconds,
      'hasCrashed': hasCrashed,
      'isAbandoned': isAbandoned,
      'reportedBadLegs': reportedBadLegs,
      'dayConditionScore': dayConditionScore,
      'fatigueRatio': fatigueRatio,
      'gcPosition': gcPosition,
      'currentOrder': currentOrder.toJson(),
      'protectingRiderId': protectingRiderId,
    };
  }

  factory TeamRoadRiderProfile.fromJson(Map<String, dynamic> json) {
    return TeamRoadRiderProfile(
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      bibNumber: (json['bibNumber'] as num?)?.toInt() ?? 1,
      hierarchyRole:
          TeamHierarchyRole.fromJson(json['hierarchyRole'] as String),
      groupIndex: (json['groupIndex'] as num?)?.toInt() ?? 0,
      timeGapToGroupSeconds:
          (json['timeGapToGroupSeconds'] as num?)?.toDouble() ?? 0.0,
      hasCrashed: json['hasCrashed'] as bool? ?? false,
      isAbandoned: json['isAbandoned'] as bool? ?? false,
      reportedBadLegs: json['reportedBadLegs'] as bool? ?? false,
      dayConditionScore: (json['dayConditionScore'] as num?)?.toInt() ?? 0,
      fatigueRatio: (json['fatigueRatio'] as num?)?.toDouble() ?? 0.2,
      gcPosition: (json['gcPosition'] as num?)?.toInt() ?? 10,
      currentOrder: TacticalOrder.fromJson(
        json['currentOrder'] as String? ?? 'holdPosition',
      ),
      protectingRiderId: json['protectingRiderId'] as String?,
    );
  }
}

/// Dane wejściowe do oceny dynamicznej zmiany lidera na szosie.
class TeamLeaderChangeInput {
  final String teamId;
  final String teamName;
  final double stageKilometer;
  final double totalStageKilometers;

  /// Docelowy indeks grupy, w której znajduje się walka o etap/GC.
  final int targetGroupIndex;

  /// Próg straty czasowej [s], po którym uznajemy utratę kontaktu z grupą.
  final double dropThresholdSeconds;

  /// Próg dyspozycji dnia (<= wartości oznacza kryzysowe "Bad Legs").
  final int badLegsDayConditionThreshold;

  /// Czy pozwolić na przywrócenie lidera nr 1, jeśli wróci do grupy w dobrej formie.
  final bool allowRestorePrimaryIfRecovered;

  /// Ręczne wymuszenie przekazania dowodzenia wiceliderowi przez dyrektora sportowego.
  final bool manualOverrideToCoLeader;

  /// Identyfikator aktywnego lidera z poprzedniego kroku symulacji.
  final String? previousActiveLeaderId;

  /// Status dowodzenia z poprzedniego kroku symulacji.
  final LeaderChangeStatus previousStatus;

  final List<TeamRoadRiderProfile> riders;

  const TeamLeaderChangeInput({
    required this.teamId,
    required this.teamName,
    required this.stageKilometer,
    required this.totalStageKilometers,
    this.targetGroupIndex = 0,
    this.dropThresholdSeconds = 20.0,
    this.badLegsDayConditionThreshold = -3,
    this.allowRestorePrimaryIfRecovered = false,
    this.manualOverrideToCoLeader = false,
    this.previousActiveLeaderId,
    this.previousStatus = LeaderChangeStatus.primaryInCommand,
    required this.riders,
  });

  double get remainingKm =>
      (totalStageKilometers - stageKilometer).clamp(0.0, totalStageKilometers);
}

/// Zapis przekierowania pojedynczego pomocnika do ochrony nowego lidera.
class DomestiqueReassignment {
  final String domestiqueId;
  final String domestiqueName;
  final String? previousProtectedRiderId;
  final String newProtectedRiderId;
  final TacticalOrder previousOrder;
  final TacticalOrder newOrder;

  /// Waga priorytetu ochrony w grupie (0.0..1.0).
  final double protectionPriorityWeight;

  const DomestiqueReassignment({
    required this.domestiqueId,
    required this.domestiqueName,
    required this.previousProtectedRiderId,
    required this.newProtectedRiderId,
    required this.previousOrder,
    required this.newOrder,
    required this.protectionPriorityWeight,
  });

  Map<String, dynamic> toJson() {
    return {
      'domestiqueId': domestiqueId,
      'domestiqueName': domestiqueName,
      'previousProtectedRiderId': previousProtectedRiderId,
      'newProtectedRiderId': newProtectedRiderId,
      'previousOrder': previousOrder.toJson(),
      'newOrder': newOrder.toJson(),
      'protectionPriorityWeight': protectionPriorityWeight,
    };
  }
}

/// Wynik ewaluacji dynamicznej zmiany lidera na szosie.
class TeamLeaderChangeDecision {
  final String teamId;
  final LeaderChangeStatus status;
  final LeaderChangeTriggerReason triggerReason;

  /// Czy w tej klatce nastąpiła faktyczna zmiana aktywnego lidera.
  final bool didChangeLeader;
  final String? previousLeaderId;
  final String? previousLeaderName;
  final String? activePriorityLeaderId;
  final String? activePriorityLeaderName;

  /// Waga priorytetowa aktywnego lidera w grupie (1.0 = pełny priorytet drużyny).
  final double activeLeaderPriorityWeight;
  final List<DomestiqueReassignment> reassignedDomestiques;
  final TacticalOrder formerLeaderNewOrder;
  final String radioCommunique;
  final List<TeamRoadRiderProfile> updatedRiders;
  final double evaluatedAtKm;

  const TeamLeaderChangeDecision({
    required this.teamId,
    required this.status,
    required this.triggerReason,
    required this.didChangeLeader,
    required this.previousLeaderId,
    required this.previousLeaderName,
    required this.activePriorityLeaderId,
    required this.activePriorityLeaderName,
    required this.activeLeaderPriorityWeight,
    required this.reassignedDomestiques,
    required this.formerLeaderNewOrder,
    required this.radioCommunique,
    required this.updatedRiders,
    required this.evaluatedAtKm,
  });

  bool get isCoLeaderActive => status == LeaderChangeStatus.coLeaderInCommand;
}

/// Silnik dynamicznej zmiany lidera na szosie w trakcie etapu.
///
/// Jeśli główny lider drużyny (nr 1) ulegnie kraksie, straci kontakt z grupą
/// lub zgłosi przez radio słabą dyspozycję dnia ("Bad Legs"), wicelider (nr 2)
/// automatycznie przejmuje ochronę pomocników i status priorytetowy w grupie.
class TeamLeaderChangeOnTheRoadLogic {
  TeamLeaderChangeOnTheRoadLogic._();

  /// Waga priorytetu pozycjonowania dla aktywnego lidera chronionego przez zespół.
  static const double priorityLeaderWeight = 1.0;

  /// Waga priorytetu dla rezerwowego kapitana, gdy obaj liderzy odpadli.
  static const double fallbackCaptainWeight = 0.72;

  /// Standardowa waga dla zwykłego kolarza bez statusu priorytetowego.
  static const double standardRiderWeight = 0.25;

  /// Ewaluuje sytuację drużyny na szosie i w razie potrzeby przekazuje
  /// ochronę pomocników oraz status priorytetowy wiceliderowi (nr 2).
  static TeamLeaderChangeDecision evaluate(TeamLeaderChangeInput input) {
    if (input.riders.isEmpty) {
      return TeamLeaderChangeDecision(
        teamId: input.teamId,
        status: LeaderChangeStatus.noViableLeader,
        triggerReason: LeaderChangeTriggerReason.none,
        didChangeLeader: false,
        previousLeaderId: input.previousActiveLeaderId,
        previousLeaderName: null,
        activePriorityLeaderId: null,
        activePriorityLeaderName: null,
        activeLeaderPriorityWeight: 0.0,
        reassignedDomestiques: const [],
        formerLeaderNewOrder: TacticalOrder.saveEnergy,
        radioCommunique: 'Brak kolarzy drużyny ${input.teamName} na trasie.',
        updatedRiders: const [],
        evaluatedAtKm: input.stageKilometer,
      );
    }

    final TeamRoadRiderProfile? primary = _findPrimaryLeader(input.riders);
    final TeamRoadRiderProfile? coLeader = _findCoLeader(
      input.riders,
      excludeId: primary?.riderId,
    );

    if (primary == null && coLeader == null) {
      return _handleFallbackOrNoLeader(
        input: input,
        primary: null,
        coLeader: null,
        trigger: LeaderChangeTriggerReason.none,
      );
    }

    // Sprawdzenie, czy główny lider (nr 1) jest zdolny do dalszego liderowania.
    final LeaderChangeTriggerReason primaryProblem = primary == null
        ? LeaderChangeTriggerReason.abandoned
        : _detectLeaderCompromiseReason(
            rider: primary,
            targetGroupIndex: input.targetGroupIndex,
            dropThresholdSeconds: input.dropThresholdSeconds,
            badLegsThreshold: input.badLegsDayConditionThreshold,
            manualOverride: input.manualOverrideToCoLeader,
          );

    final bool wasCoLeaderActive =
        input.previousStatus == LeaderChangeStatus.coLeaderInCommand ||
            (coLeader != null &&
                input.previousActiveLeaderId == coLeader.riderId);

    // Jeśli główny lider ma problem lub wicelider już przejął dowodzenie
    // (a nie zezwolono na przywrócenie nr 1).
    final bool shouldUseCoLeader = primaryProblem !=
            LeaderChangeTriggerReason.none ||
        (wasCoLeaderActive && !input.allowRestorePrimaryIfRecovered);

    if (!shouldUseCoLeader && primary != null) {
      final bool isRestoring = wasCoLeaderActive &&
          input.allowRestorePrimaryIfRecovered &&
          primaryProblem == LeaderChangeTriggerReason.none;

      return _assignPrimaryLeader(
        input: input,
        primary: primary,
        coLeader: coLeader,
        isRestoring: isRestoring,
      );
    }

    // Główny lider jest niedysponowany — sprawdzamy zdolność wicelidera (nr 2).
    if (coLeader != null &&
        _isRiderViableForLeadership(
          rider: coLeader,
          targetGroupIndex: input.targetGroupIndex,
          dropThresholdSeconds: input.dropThresholdSeconds,
          badLegsThreshold: input.badLegsDayConditionThreshold,
        )) {
      final LeaderChangeTriggerReason effectiveReason =
          primaryProblem != LeaderChangeTriggerReason.none
              ? primaryProblem
              : LeaderChangeTriggerReason.manualDsOverride;

      return _promoteCoLeader(
        input: input,
        primary: primary,
        coLeader: coLeader,
        reason: effectiveReason,
      );
    }

    // Wicelider również niedostępny — szukamy rezerwowego kapitana lub trybu wolnej ręki.
    return _handleFallbackOrNoLeader(
      input: input,
      primary: primary,
      coLeader: coLeader,
      trigger: primaryProblem,
    );
  }

  /// Aplikuje wynik decyzji bezpośrednio na listę dynamicznych stanów [RiderRaceState].
  static List<RiderRaceState> applyToRiderRaceStates({
    required List<RiderRaceState> raceStates,
    required TeamLeaderChangeDecision decision,
  }) {
    if (raceStates.isEmpty || decision.updatedRiders.isEmpty) {
      return raceStates;
    }

    final Map<String, TeamRoadRiderProfile> byId = {
      for (final rider in decision.updatedRiders) rider.riderId: rider,
    };

    return raceStates.map((state) {
      final TeamRoadRiderProfile? updated = byId[state.riderId];
      if (updated == null) return state;
      return state.copyWith(activeTacticalOrder: updated.currentOrder);
    }).toList(growable: false);
  }

  static TeamRoadRiderProfile? _findPrimaryLeader(
    List<TeamRoadRiderProfile> riders,
  ) {
    final primaries = riders
        .where((r) => r.hierarchyRole == TeamHierarchyRole.primaryLeader)
        .toList();
    if (primaries.isEmpty) return null;
    primaries.sort((a, b) => a.bibNumber.compareTo(b.bibNumber));
    return primaries.first;
  }

  static TeamRoadRiderProfile? _findCoLeader(
    List<TeamRoadRiderProfile> riders, {
    String? excludeId,
  }) {
    final coLeaders = riders
        .where(
          (r) =>
              r.riderId != excludeId &&
              r.hierarchyRole == TeamHierarchyRole.coLeader,
        )
        .toList();
    if (coLeaders.isEmpty) return null;
    coLeaders.sort((a, b) => a.bibNumber.compareTo(b.bibNumber));
    return coLeaders.first;
  }

  static LeaderChangeTriggerReason _detectLeaderCompromiseReason({
    required TeamRoadRiderProfile rider,
    required int targetGroupIndex,
    required double dropThresholdSeconds,
    required int badLegsThreshold,
    required bool manualOverride,
  }) {
    if (rider.isAbandoned) {
      return LeaderChangeTriggerReason.abandoned;
    }
    if (rider.hasCrashed) {
      return LeaderChangeTriggerReason.crash;
    }
    if (rider.groupIndex > targetGroupIndex ||
        rider.timeGapToGroupSeconds >= dropThresholdSeconds) {
      return LeaderChangeTriggerReason.droppedFromGroup;
    }
    if (rider.reportedBadLegs || rider.dayConditionScore <= badLegsThreshold) {
      return LeaderChangeTriggerReason.badLegsRadioReport;
    }
    if (manualOverride) {
      return LeaderChangeTriggerReason.manualDsOverride;
    }
    return LeaderChangeTriggerReason.none;
  }

  static bool _isRiderViableForLeadership({
    required TeamRoadRiderProfile rider,
    required int targetGroupIndex,
    required double dropThresholdSeconds,
    required int badLegsThreshold,
  }) {
    if (rider.isAbandoned || rider.hasCrashed) return false;
    if (rider.groupIndex > targetGroupIndex) return false;
    if (rider.timeGapToGroupSeconds >= dropThresholdSeconds) return false;
    if (rider.reportedBadLegs || rider.dayConditionScore <= badLegsThreshold) {
      return false;
    }
    return true;
  }

  static TeamLeaderChangeDecision _assignPrimaryLeader({
    required TeamLeaderChangeInput input,
    required TeamRoadRiderProfile primary,
    required TeamRoadRiderProfile? coLeader,
    required bool isRestoring,
  }) {
    final bool didChange = isRestoring ||
        (input.previousActiveLeaderId != null &&
            input.previousActiveLeaderId != primary.riderId);

    final List<DomestiqueReassignment> reassignments = [];
    final List<TeamRoadRiderProfile> updated = [];

    for (final rider in input.riders) {
      if (rider.riderId == primary.riderId) {
        final TacticalOrder leaderOrder =
            rider.currentOrder == TacticalOrder.saveEnergy
                ? TacticalOrder.holdPosition
                : rider.currentOrder;
        updated.add(
          rider.copyWith(
            currentOrder: leaderOrder,
            clearProtectingRiderId: true,
          ),
        );
      } else if (coLeader != null && rider.riderId == coLeader.riderId) {
        // Wicelider w grupie utrzymuje pozycję bez marnowania sił.
        updated.add(
          rider.copyWith(
            currentOrder: rider.currentOrder == TacticalOrder.protectLeader
                ? TacticalOrder.holdPosition
                : rider.currentOrder,
            clearProtectingRiderId: true,
          ),
        );
      } else if (_shouldDomestiqueProtectActiveLeader(
        domestique: rider,
        targetGroupIndex: input.targetGroupIndex,
        previousProtectedId: rider.protectingRiderId,
        oldLeaderId: coLeader?.riderId,
      )) {
        if (rider.protectingRiderId != primary.riderId ||
            rider.currentOrder != TacticalOrder.protectLeader) {
          reassignments.add(
            DomestiqueReassignment(
              domestiqueId: rider.riderId,
              domestiqueName: rider.riderName,
              previousProtectedRiderId: rider.protectingRiderId,
              newProtectedRiderId: primary.riderId,
              previousOrder: rider.currentOrder,
              newOrder: TacticalOrder.protectLeader,
              protectionPriorityWeight: priorityLeaderWeight,
            ),
          );
        }
        updated.add(
          rider.copyWith(
            currentOrder: TacticalOrder.protectLeader,
            protectingRiderId: primary.riderId,
          ),
        );
      } else {
        updated.add(rider);
      }
    }

    final String radio = isRestoring
        ? 'Radio DS (${input.teamName}): ${primary.riderName} wrócił do grupy! '
            'Przywracamy ochronę pomocników dla lidera #1.'
        : 'Radio DS (${input.teamName}): ${primary.riderName} utrzymuje status lidera #1.';

    return TeamLeaderChangeDecision(
      teamId: input.teamId,
      status: isRestoring
          ? LeaderChangeStatus.restoredToPrimary
          : LeaderChangeStatus.primaryInCommand,
      triggerReason: LeaderChangeTriggerReason.none,
      didChangeLeader: didChange,
      previousLeaderId: input.previousActiveLeaderId ?? primary.riderId,
      previousLeaderName:
          isRestoring ? coLeader?.riderName : primary.riderName,
      activePriorityLeaderId: primary.riderId,
      activePriorityLeaderName: primary.riderName,
      activeLeaderPriorityWeight: priorityLeaderWeight,
      reassignedDomestiques: reassignments,
      formerLeaderNewOrder: primary.currentOrder,
      radioCommunique: radio,
      updatedRiders: updated,
      evaluatedAtKm: input.stageKilometer,
    );
  }

  static TeamLeaderChangeDecision _promoteCoLeader({
    required TeamLeaderChangeInput input,
    required TeamRoadRiderProfile? primary,
    required TeamRoadRiderProfile coLeader,
    required LeaderChangeTriggerReason reason,
  }) {
    final bool didChange = input.previousActiveLeaderId != coLeader.riderId ||
        input.previousStatus != LeaderChangeStatus.coLeaderInCommand;

    const TacticalOrder formerLeaderOrder = TacticalOrder.saveEnergy;
    final List<DomestiqueReassignment> reassignments = [];
    final List<TeamRoadRiderProfile> updated = [];

    for (final rider in input.riders) {
      if (primary != null && rider.riderId == primary.riderId) {
        // Zdegradowany lider nr 1 przechodzi w tryb oszczędzania energii.
        updated.add(
          rider.copyWith(
            currentOrder: formerLeaderOrder,
            clearProtectingRiderId: true,
          ),
        );
      } else if (rider.riderId == coLeader.riderId) {
        // Wicelider nr 2 przejmuje status priorytetowy w grupie.
        final TacticalOrder coLeaderOrder =
            rider.currentOrder == TacticalOrder.attack
                ? TacticalOrder.attack
                : TacticalOrder.followWheels;
        updated.add(
          rider.copyWith(
            currentOrder: coLeaderOrder,
            clearProtectingRiderId: true,
          ),
        );
      } else if (_shouldDomestiqueProtectActiveLeader(
        domestique: rider,
        targetGroupIndex: input.targetGroupIndex,
        previousProtectedId: rider.protectingRiderId,
        oldLeaderId: primary?.riderId,
      )) {
        if (rider.protectingRiderId != coLeader.riderId ||
            rider.currentOrder != TacticalOrder.protectLeader) {
          reassignments.add(
            DomestiqueReassignment(
              domestiqueId: rider.riderId,
              domestiqueName: rider.riderName,
              previousProtectedRiderId: rider.protectingRiderId,
              newProtectedRiderId: coLeader.riderId,
              previousOrder: rider.currentOrder,
              newOrder: TacticalOrder.protectLeader,
              protectionPriorityWeight: priorityLeaderWeight,
            ),
          );
        }
        updated.add(
          rider.copyWith(
            currentOrder: TacticalOrder.protectLeader,
            protectingRiderId: coLeader.riderId,
          ),
        );
      } else {
        updated.add(rider);
      }
    }

    final String primaryLabel = primary?.riderName ?? 'Lider #1';
    final String reasonPhrase = _reasonToRadioPhrase(reason);
    final String radio =
        'RADIO DS (${input.teamName}, ${input.stageKilometer.toStringAsFixed(1)} km): '
        '$primaryLabel $reasonPhrase! Plan B: ${coLeader.riderName} (#${coLeader.bibNumber}) '
        'przejmuje ochronę ${reassignments.length} pomocników i status priorytetowy w grupie.';

    return TeamLeaderChangeDecision(
      teamId: input.teamId,
      status: LeaderChangeStatus.coLeaderInCommand,
      triggerReason: reason,
      didChangeLeader: didChange,
      previousLeaderId: primary?.riderId ?? input.previousActiveLeaderId,
      previousLeaderName: primary?.riderName,
      activePriorityLeaderId: coLeader.riderId,
      activePriorityLeaderName: coLeader.riderName,
      activeLeaderPriorityWeight: priorityLeaderWeight,
      reassignedDomestiques: reassignments,
      formerLeaderNewOrder: formerLeaderOrder,
      radioCommunique: radio,
      updatedRiders: updated,
      evaluatedAtKm: input.stageKilometer,
    );
  }

  static TeamLeaderChangeDecision _handleFallbackOrNoLeader({
    required TeamLeaderChangeInput input,
    required TeamRoadRiderProfile? primary,
    required TeamRoadRiderProfile? coLeader,
    required LeaderChangeTriggerReason trigger,
  }) {
    final fallbackCandidates = input.riders
        .where(
          (r) =>
              r.hierarchyRole == TeamHierarchyRole.protectedDomestique &&
              _isRiderViableForLeadership(
                rider: r,
                targetGroupIndex: input.targetGroupIndex,
                dropThresholdSeconds: input.dropThresholdSeconds,
                badLegsThreshold: input.badLegsDayConditionThreshold,
              ),
        )
        .toList()
      ..sort((a, b) => a.gcPosition.compareTo(b.gcPosition));

    if (fallbackCandidates.isNotEmpty) {
      final TeamRoadRiderProfile captain = fallbackCandidates.first;
      final bool didChange = input.previousActiveLeaderId != captain.riderId;
      final List<DomestiqueReassignment> reassignments = [];
      final List<TeamRoadRiderProfile> updated = [];

      for (final rider in input.riders) {
        if (rider.riderId == captain.riderId) {
          updated.add(
            rider.copyWith(
              currentOrder: TacticalOrder.followWheels,
              clearProtectingRiderId: true,
            ),
          );
        } else if (primary != null && rider.riderId == primary.riderId ||
            coLeader != null && rider.riderId == coLeader.riderId) {
          updated.add(
            rider.copyWith(
              currentOrder: TacticalOrder.saveEnergy,
              clearProtectingRiderId: true,
            ),
          );
        } else if (_shouldDomestiqueProtectActiveLeader(
          domestique: rider,
          targetGroupIndex: input.targetGroupIndex,
          previousProtectedId: rider.protectingRiderId,
          oldLeaderId: primary?.riderId ?? coLeader?.riderId,
        )) {
          reassignments.add(
            DomestiqueReassignment(
              domestiqueId: rider.riderId,
              domestiqueName: rider.riderName,
              previousProtectedRiderId: rider.protectingRiderId,
              newProtectedRiderId: captain.riderId,
              previousOrder: rider.currentOrder,
              newOrder: TacticalOrder.protectLeader,
              protectionPriorityWeight: fallbackCaptainWeight,
            ),
          );
          updated.add(
            rider.copyWith(
              currentOrder: TacticalOrder.protectLeader,
              protectingRiderId: captain.riderId,
            ),
          );
        } else {
          updated.add(rider);
        }
      }

      return TeamLeaderChangeDecision(
        teamId: input.teamId,
        status: LeaderChangeStatus.fallbackCaptainInCommand,
        triggerReason: trigger,
        didChangeLeader: didChange,
        previousLeaderId: primary?.riderId ?? coLeader?.riderId,
        previousLeaderName: primary?.riderName ?? coLeader?.riderName,
        activePriorityLeaderId: captain.riderId,
        activePriorityLeaderName: captain.riderName,
        activeLeaderPriorityWeight: fallbackCaptainWeight,
        reassignedDomestiques: reassignments,
        formerLeaderNewOrder: TacticalOrder.saveEnergy,
        radioCommunique:
            'RADIO DS (${input.teamName}): Obaj liderzy poza grą! '
            '${captain.riderName} przejmuje rolę kapitana w grupie.',
        updatedRiders: updated,
        evaluatedAtKm: input.stageKilometer,
      );
    }

    // Brak zdolnego lidera w grupie: zwalniamy pomocników do wolnej ręki.
    final updated = input.riders.map((rider) {
      if (rider.isAbandoned) return rider;
      if (rider.currentOrder == TacticalOrder.protectLeader) {
        return rider.copyWith(
          currentOrder: TacticalOrder.holdPosition,
          clearProtectingRiderId: true,
        );
      }
      return rider.copyWith(clearProtectingRiderId: true);
    }).toList(growable: false);

    return TeamLeaderChangeDecision(
      teamId: input.teamId,
      status: LeaderChangeStatus.noViableLeader,
      triggerReason: trigger,
      didChangeLeader:
          input.previousStatus != LeaderChangeStatus.noViableLeader,
      previousLeaderId: primary?.riderId ?? coLeader?.riderId,
      previousLeaderName: primary?.riderName ?? coLeader?.riderName,
      activePriorityLeaderId: null,
      activePriorityLeaderName: null,
      activeLeaderPriorityWeight: 0.0,
      reassignedDomestiques: const [],
      formerLeaderNewOrder: TacticalOrder.saveEnergy,
      radioCommunique:
          'RADIO DS (${input.teamName}): Brak lidera w czołowej grupie — '
          'wolna ręka dla wszystkich kolarzy na etapie!',
      updatedRiders: updated,
      evaluatedAtKm: input.stageKilometer,
    );
  }

  static bool _shouldDomestiqueProtectActiveLeader({
    required TeamRoadRiderProfile domestique,
    required int targetGroupIndex,
    required String? previousProtectedId,
    required String? oldLeaderId,
  }) {
    if (!domestique.isDomestiqueRole) return false;
    if (domestique.isAbandoned || domestique.hasCrashed) return false;
    if (domestique.groupIndex > targetGroupIndex) return false;
    if (domestique.currentOrder == TacticalOrder.fetchBidonsFromCar ||
        domestique.currentOrder == TacticalOrder.attack) {
      return false;
    }

    // Pomocnik był przypisany do starego lidera lub ma aktywny rozkaz ochrony/utrzymania pozycji.
    if (oldLeaderId != null && previousProtectedId == oldLeaderId) {
      return true;
    }
    return domestique.currentOrder == TacticalOrder.protectLeader ||
        domestique.currentOrder == TacticalOrder.holdPosition;
  }

  static String _reasonToRadioPhrase(LeaderChangeTriggerReason reason) {
    switch (reason) {
      case LeaderChangeTriggerReason.none:
        return 'przekazuje prowadzenie';
      case LeaderChangeTriggerReason.crash:
        return 'uległ kraksie na trasie';
      case LeaderChangeTriggerReason.droppedFromGroup:
        return 'stracił kontakt z grupą';
      case LeaderChangeTriggerReason.badLegsRadioReport:
        return 'zgłosił przez radio "Bad Legs"';
      case LeaderChangeTriggerReason.abandoned:
        return 'wycofał się z wyścigu';
      case LeaderChangeTriggerReason.manualDsOverride:
        return 'został zastąpiony decyzją dyrektora sportowego';
    }
  }
}

/// Panel taktyczny prezentujący dynamiczną zmianę lidera na szosie w HUD wyścigu.
///
/// Obsługuje responsywnie rozdzielczości `390x844`, `1024x768` i `1600x900`,
/// paletę [AppColors], typografię `Inter` oraz pełne stany interakcji.
class TeamLeaderChangeStatusPanel extends StatelessWidget {
  final TeamLeaderChangeDecision decision;
  final VoidCallback? onTriggerBadLegsOverride;
  final VoidCallback? onRestorePrimaryLeader;
  final bool isInteractiveEnabled;

  const TeamLeaderChangeStatusPanel({
    super.key,
    required this.decision,
    this.onTriggerBadLegsOverride,
    this.onRestorePrimaryLeader,
    this.isInteractiveEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 520;
        final bool isWide = constraints.maxWidth >= 960;

        final Color accentColor = _statusAccentColor(decision.status);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.all(isCompact ? 14 : 18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: decision.isCoLeaderActive
                  ? AppColors.goldAccent.withValues(alpha: 0.75)
                  : const Color(0xFF2A2F3D),
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(isCompact: isCompact, accentColor: accentColor),
              const SizedBox(height: 12),
              _buildRadioBanner(accentColor: accentColor),
              const SizedBox(height: 12),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildLeaderCards(isCompact)),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 2,
                      child: _buildDomestiquesSection(isCompact),
                    ),
                  ],
                )
              else ...[
                _buildLeaderCards(isCompact),
                const SizedBox(height: 12),
                _buildDomestiquesSection(isCompact),
              ],
              if (onTriggerBadLegsOverride != null ||
                  onRestorePrimaryLeader != null) ...[
                const SizedBox(height: 14),
                _buildActionBar(isCompact: isCompact),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader({
    required bool isCompact,
    required Color accentColor,
  }) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'HIERARCHIA NA SZOSIE',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: isCompact ? 12 : 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accentColor.withValues(alpha: 0.45)),
          ),
          child: Text(
            decision.status.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: accentColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRadioBanner({required Color accentColor}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.headset_mic_rounded,
            size: 16,
            color: accentColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              decision.radioCommunique,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                height: 1.4,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderCards(bool isCompact) {
    final String activeName =
        decision.activePriorityLeaderName ?? 'Brak aktywnego lidera';
    final String reasonLabel = decision.triggerReason.label;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.workspace_premium_rounded,
                size: 16,
                color: AppColors.goldAccent,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Aktywny priorytet: $activeName',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _metricChip(
                label: 'Powód',
                value: reasonLabel,
              ),
              _metricChip(
                label: 'Priorytet w grupie',
                value:
                    '${(decision.activeLeaderPriorityWeight * 100).round()}%',
              ),
              _metricChip(
                label: 'Kilometr',
                value: '${decision.evaluatedAtKm.toStringAsFixed(1)} km',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDomestiquesSection(bool isCompact) {
    final int count = decision.reassignedDomestiques.length;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ochrona pomocników ($count)',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          if (count == 0)
            const Text(
              'Brak przekierowanych pomocników w tej klatce.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: decision.reassignedDomestiques
                  .map(
                    (d) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF2A2F3D)),
                      ),
                      child: Text(
                        '${d.domestiqueName} → ${d.newOrder.label}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }

  Widget _buildActionBar({required bool isCompact}) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        if (onTriggerBadLegsOverride != null)
          _TacticalActionButton(
            label: 'Przekaż ochronę Wiceliderowi #2',
            icon: Icons.swap_horiz_rounded,
            accentColor: AppColors.goldAccent,
            enabled: isInteractiveEnabled && !decision.isCoLeaderActive,
            onPressed: onTriggerBadLegsOverride,
          ),
        if (onRestorePrimaryLeader != null)
          _TacticalActionButton(
            label: 'Przywróć Lidera #1',
            icon: Icons.replay_rounded,
            accentColor: AppColors.accentBlue,
            enabled: isInteractiveEnabled && decision.isCoLeaderActive,
            onPressed: onRestorePrimaryLeader,
          ),
      ],
    );
  }

  Widget _metricChip({required String label, required String value}) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontFamily: 'Inter', fontSize: 11),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Color _statusAccentColor(LeaderChangeStatus status) {
    switch (status) {
      case LeaderChangeStatus.primaryInCommand:
        return AppColors.statusSuccess;
      case LeaderChangeStatus.coLeaderInCommand:
        return AppColors.goldAccent;
      case LeaderChangeStatus.fallbackCaptainInCommand:
        return AppColors.amberWarning;
      case LeaderChangeStatus.restoredToPrimary:
        return AppColors.accentBlue;
      case LeaderChangeStatus.noViableLeader:
        return AppColors.crimsonAlert;
    }
  }
}

class _TacticalActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final bool enabled;
  final VoidCallback? onPressed;

  const _TacticalActionButton({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_TacticalActionButton> createState() => _TacticalActionButtonState();
}

class _TacticalActionButtonState extends State<_TacticalActionButton> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final bool canInteract = widget.enabled && widget.onPressed != null;

    final Color backgroundColor;
    if (!canInteract) {
      backgroundColor = AppColors.surfaceLight.withValues(alpha: 0.45);
    } else if (_isPressed) {
      backgroundColor = widget.accentColor.withValues(alpha: 0.28);
    } else if (_isHovered) {
      backgroundColor = widget.accentColor.withValues(alpha: 0.18);
    } else {
      backgroundColor = AppColors.surfaceLight;
    }

    final Color borderColor;
    if (!canInteract) {
      borderColor = const Color(0xFF2A2F3D).withValues(alpha: 0.5);
    } else if (_isFocused) {
      borderColor = widget.accentColor;
    } else if (_isHovered || _isPressed) {
      borderColor = widget.accentColor.withValues(alpha: 0.75);
    } else {
      borderColor = const Color(0xFF2A2F3D);
    }

    final Color foregroundColor = canInteract
        ? AppColors.textPrimary
        : AppColors.textSecondary.withValues(alpha: 0.5);

    return FocusableActionDetector(
      enabled: canInteract,
      onShowHoverHighlight: (hovered) {
        if (_isHovered != hovered) {
          setState(() => _isHovered = hovered);
        }
      },
      onShowFocusHighlight: (focused) {
        if (_isFocused != focused) {
          setState(() => _isFocused = focused);
        }
      },
      child: GestureDetector(
        onTapDown: canInteract ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: canInteract ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel:
            canInteract ? () => setState(() => _isPressed = false) : null,
        onTap: canInteract ? widget.onPressed : null,
        child: MouseRegion(
          cursor:
              canInteract ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: _isFocused ? 1.5 : 1.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 15,
                  color: canInteract ? widget.accentColor : foregroundColor,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: foregroundColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
