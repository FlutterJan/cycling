// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/rider/rider.dart';

/// Typ wydarzenia z życia osobistego i rodzinnego kolarza.
enum PersonalLifeEventType {
  childBirth,
  paternityLeave,
  homeRace,
  familyMilestone,
  homesicknessWave;

  String toJson() => name;

  static PersonalLifeEventType fromJson(String value) {
    return PersonalLifeEventType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => PersonalLifeEventType.familyMilestone,
    );
  }

  String get label {
    switch (this) {
      case PersonalLifeEventType.childBirth:
        return 'Narodziny Dziecka';
      case PersonalLifeEventType.paternityLeave:
        return 'Urlop Ojcowski';
      case PersonalLifeEventType.homeRace:
        return 'Domowy Wyścig';
      case PersonalLifeEventType.familyMilestone:
        return 'Wydarzenie Rodzinne';
      case PersonalLifeEventType.homesicknessWave:
        return 'Tęsknota za Domem';
    }
  }

  IconData get icon {
    switch (this) {
      case PersonalLifeEventType.childBirth:
        return Icons.child_friendly_rounded;
      case PersonalLifeEventType.paternityLeave:
        return Icons.family_restroom_rounded;
      case PersonalLifeEventType.homeRace:
        return Icons.flag_rounded;
      case PersonalLifeEventType.familyMilestone:
        return Icons.celebration_rounded;
      case PersonalLifeEventType.homesicknessWave:
        return Icons.home_outlined;
    }
  }

  Color get accentColor {
    switch (this) {
      case PersonalLifeEventType.childBirth:
        return AppColors.goldAccent;
      case PersonalLifeEventType.paternityLeave:
        return AppColors.accentBlue;
      case PersonalLifeEventType.homeRace:
        return AppColors.statusSuccess;
      case PersonalLifeEventType.familyMilestone:
        return AppColors.cyanAccent;
      case PersonalLifeEventType.homesicknessWave:
        return AppColors.amberWarning;
    }
  }
}

/// Decyzja menedżera w sprawie urlopu ojcowskiego po narodzinach dziecka.
enum PaternityLeaveOption {
  fullLeave14Days,
  shortLeave5Days,
  stayOnRaceRoster;

  String toJson() => name;

  static PaternityLeaveOption fromJson(String value) {
    return PaternityLeaveOption.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => PaternityLeaveOption.shortLeave5Days,
    );
  }

  String get label {
    switch (this) {
      case PaternityLeaveOption.fullLeave14Days:
        return 'Pełny Urlop (14 dni)';
      case PaternityLeaveOption.shortLeave5Days:
        return 'Krótki Urlop (5 dni)';
      case PaternityLeaveOption.stayOnRaceRoster:
        return 'Pozostanie w Składzie';
    }
  }

  String get description {
    switch (this) {
      case PaternityLeaveOption.fullLeave14Days:
        return 'Kolarz wraca do rodziny na 2 tygodnie. +20 morale, +12 lojalności, brak dostępności wyścigowej.';
      case PaternityLeaveOption.shortLeave5Days:
        return 'Krótka przerwa na narodziny i powrót do treningu. +10 morale, +5 lojalności, 5 dni pauzy.';
      case PaternityLeaveOption.stayOnRaceRoster:
        return 'Kolarz zostaje na wyścigu. Pełna dostępność, ale -16 morale i -10 lojalności wobec zespołu.';
    }
  }

  int get leaveDurationDays {
    switch (this) {
      case PaternityLeaveOption.fullLeave14Days:
        return 14;
      case PaternityLeaveOption.shortLeave5Days:
        return 5;
      case PaternityLeaveOption.stayOnRaceRoster:
        return 0;
    }
  }

  int get moraleDelta {
    switch (this) {
      case PaternityLeaveOption.fullLeave14Days:
        return 20;
      case PaternityLeaveOption.shortLeave5Days:
        return 10;
      case PaternityLeaveOption.stayOnRaceRoster:
        return -16;
    }
  }

  int get loyaltyDelta {
    switch (this) {
      case PaternityLeaveOption.fullLeave14Days:
        return 12;
      case PaternityLeaveOption.shortLeave5Days:
        return 5;
      case PaternityLeaveOption.stayOnRaceRoster:
        return -10;
    }
  }

  double get ctlDelta {
    switch (this) {
      case PaternityLeaveOption.fullLeave14Days:
        return -4.5;
      case PaternityLeaveOption.shortLeave5Days:
        return -1.5;
      case PaternityLeaveOption.stayOnRaceRoster:
        return 0.0;
    }
  }
}

/// Poziom bliskości geograficznej wyścigu względem domu kolarza.
enum HomeRaceBonusTier {
  hometownVillage,
  homeRegion,
  homeCountry;

  String toJson() => name;

  static HomeRaceBonusTier fromJson(String value) {
    return HomeRaceBonusTier.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => HomeRaceBonusTier.homeCountry,
    );
  }

  String get label {
    switch (this) {
      case HomeRaceBonusTier.hometownVillage:
        return 'Rodzinna Miejscowość';
      case HomeRaceBonusTier.homeRegion:
        return 'Region Domowy';
      case HomeRaceBonusTier.homeCountry:
        return 'Wyścig Krajowy';
    }
  }

  int get moraleBoost {
    switch (this) {
      case HomeRaceBonusTier.hometownVillage:
        return 18;
      case HomeRaceBonusTier.homeRegion:
        return 12;
      case HomeRaceBonusTier.homeCountry:
        return 7;
    }
  }

  double get adrenalineMultiplier {
    switch (this) {
      case HomeRaceBonusTier.hometownVillage:
        return 1.045;
      case HomeRaceBonusTier.homeRegion:
        return 1.025;
      case HomeRaceBonusTier.homeCountry:
        return 1.015;
    }
  }

  double get mediaExposureMultiplier {
    switch (this) {
      case HomeRaceBonusTier.hometownVillage:
        return 1.30;
      case HomeRaceBonusTier.homeRegion:
        return 1.18;
      case HomeRaceBonusTier.homeCountry:
        return 1.10;
    }
  }
}

/// Status rozstrzygnięcia wydarzenia osobistego.
enum PersonalEventResolutionStatus {
  pendingDecision,
  activeLeave,
  resolvedBoosted,
  resolvedStrained,
  expired;

  String toJson() => name;

  static PersonalEventResolutionStatus fromJson(String value) {
    return PersonalEventResolutionStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => PersonalEventResolutionStatus.pendingDecision,
    );
  }

  String get label {
    switch (this) {
      case PersonalEventResolutionStatus.pendingDecision:
        return 'Wymaga Decyzji';
      case PersonalEventResolutionStatus.activeLeave:
        return 'Aktywny Urlop';
      case PersonalEventResolutionStatus.resolvedBoosted:
        return 'Pozytywny Wpływ';
      case PersonalEventResolutionStatus.resolvedStrained:
        return 'Napięcie w Zespole';
      case PersonalEventResolutionStatus.expired:
        return 'Zakończone';
    }
  }

  Color get color {
    switch (this) {
      case PersonalEventResolutionStatus.pendingDecision:
        return AppColors.goldAccent;
      case PersonalEventResolutionStatus.activeLeave:
        return AppColors.accentBlue;
      case PersonalEventResolutionStatus.resolvedBoosted:
        return AppColors.statusSuccess;
      case PersonalEventResolutionStatus.resolvedStrained:
        return AppColors.crimsonAlert;
      case PersonalEventResolutionStatus.expired:
        return AppColors.textSecondary;
    }
  }
}

/// Profil życia osobistego i rodzinnego kolarza.
class RiderFamilyProfile {
  final String riderId;
  final String riderName;
  final String nationalityIso;
  final String hometownName;
  final String homeRegionName;
  final String maritalStatusLabel;
  final int childrenCount;
  final DateTime? expectingChildDueDate;
  final int daysAwayFromHomeSeason;
  final int familyHappiness; // 0..100
  final int teamLoyaltyDelta; // -30..30
  final DateTime? paternityLeaveEndsAt;

  const RiderFamilyProfile({
    required this.riderId,
    required this.riderName,
    required this.nationalityIso,
    required this.hometownName,
    required this.homeRegionName,
    required this.maritalStatusLabel,
    required this.childrenCount,
    this.expectingChildDueDate,
    required this.daysAwayFromHomeSeason,
    required this.familyHappiness,
    required this.teamLoyaltyDelta,
    this.paternityLeaveEndsAt,
  });

  bool isOnPaternityLeaveAt(DateTime date) {
    final ends = paternityLeaveEndsAt;
    if (ends == null) return false;
    return !date.isAfter(ends);
  }

  RiderFamilyProfile copyWith({
    String? riderId,
    String? riderName,
    String? nationalityIso,
    String? hometownName,
    String? homeRegionName,
    String? maritalStatusLabel,
    int? childrenCount,
    DateTime? expectingChildDueDate,
    bool clearExpectingChildDueDate = false,
    int? daysAwayFromHomeSeason,
    int? familyHappiness,
    int? teamLoyaltyDelta,
    DateTime? paternityLeaveEndsAt,
    bool clearPaternityLeaveEndsAt = false,
  }) {
    return RiderFamilyProfile(
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      nationalityIso: nationalityIso ?? this.nationalityIso,
      hometownName: hometownName ?? this.hometownName,
      homeRegionName: homeRegionName ?? this.homeRegionName,
      maritalStatusLabel: maritalStatusLabel ?? this.maritalStatusLabel,
      childrenCount: childrenCount ?? this.childrenCount,
      expectingChildDueDate: clearExpectingChildDueDate
          ? null
          : (expectingChildDueDate ?? this.expectingChildDueDate),
      daysAwayFromHomeSeason:
          daysAwayFromHomeSeason ?? this.daysAwayFromHomeSeason,
      familyHappiness: (familyHappiness ?? this.familyHappiness).clamp(0, 100),
      teamLoyaltyDelta: (teamLoyaltyDelta ?? this.teamLoyaltyDelta).clamp(-30, 30),
      paternityLeaveEndsAt: clearPaternityLeaveEndsAt
          ? null
          : (paternityLeaveEndsAt ?? this.paternityLeaveEndsAt),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'riderName': riderName,
      'nationalityIso': nationalityIso,
      'hometownName': hometownName,
      'homeRegionName': homeRegionName,
      'maritalStatusLabel': maritalStatusLabel,
      'childrenCount': childrenCount,
      'expectingChildDueDate': expectingChildDueDate?.toIso8601String(),
      'daysAwayFromHomeSeason': daysAwayFromHomeSeason,
      'familyHappiness': familyHappiness,
      'teamLoyaltyDelta': teamLoyaltyDelta,
      'paternityLeaveEndsAt': paternityLeaveEndsAt?.toIso8601String(),
    };
  }

  factory RiderFamilyProfile.fromJson(Map<String, dynamic> json) {
    return RiderFamilyProfile(
      riderId: json['riderId'] as String? ?? '',
      riderName: json['riderName'] as String? ?? '',
      nationalityIso: json['nationalityIso'] as String? ?? 'POL',
      hometownName: json['hometownName'] as String? ?? 'Kraków',
      homeRegionName: json['homeRegionName'] as String? ?? 'Małopolska',
      maritalStatusLabel: json['maritalStatusLabel'] as String? ?? 'W związku',
      childrenCount: (json['childrenCount'] as num?)?.toInt() ?? 0,
      expectingChildDueDate: json['expectingChildDueDate'] != null
          ? DateTime.tryParse(json['expectingChildDueDate'] as String)
          : null,
      daysAwayFromHomeSeason:
          (json['daysAwayFromHomeSeason'] as num?)?.toInt() ?? 0,
      familyHappiness:
          ((json['familyHappiness'] as num?)?.toInt() ?? 75).clamp(0, 100),
      teamLoyaltyDelta:
          ((json['teamLoyaltyDelta'] as num?)?.toInt() ?? 0).clamp(-30, 30),
      paternityLeaveEndsAt: json['paternityLeaveEndsAt'] != null
          ? DateTime.tryParse(json['paternityLeaveEndsAt'] as String)
          : null,
    );
  }
}

/// Pojedyncze wydarzenie osobiste lub rodzinne kolarza.
class PersonalLifeEventRecord {
  final String eventId;
  final String riderId;
  final String riderName;
  final String nationalityIso;
  final PersonalLifeEventType type;
  final String title;
  final String description;
  final DateTime triggeredAt;
  final DateTime expiresAt;
  final PersonalEventResolutionStatus status;
  final PaternityLeaveOption? selectedLeaveOption;
  final String? homeRaceName;
  final String? homeRaceCountryIso;
  final HomeRaceBonusTier? homeRaceTier;
  final int moraleDelta;
  final int loyaltyDelta;
  final double fatigueDelta;
  final double ctlDelta;
  final double formAdrenalineMultiplier;
  final bool requiresManagerDecision;

  const PersonalLifeEventRecord({
    required this.eventId,
    required this.riderId,
    required this.riderName,
    required this.nationalityIso,
    required this.type,
    required this.title,
    required this.description,
    required this.triggeredAt,
    required this.expiresAt,
    required this.status,
    this.selectedLeaveOption,
    this.homeRaceName,
    this.homeRaceCountryIso,
    this.homeRaceTier,
    required this.moraleDelta,
    required this.loyaltyDelta,
    required this.fatigueDelta,
    required this.ctlDelta,
    required this.formAdrenalineMultiplier,
    required this.requiresManagerDecision,
  });

  PersonalLifeEventRecord copyWith({
    String? eventId,
    String? riderId,
    String? riderName,
    String? nationalityIso,
    PersonalLifeEventType? type,
    String? title,
    String? description,
    DateTime? triggeredAt,
    DateTime? expiresAt,
    PersonalEventResolutionStatus? status,
    PaternityLeaveOption? selectedLeaveOption,
    String? homeRaceName,
    String? homeRaceCountryIso,
    HomeRaceBonusTier? homeRaceTier,
    int? moraleDelta,
    int? loyaltyDelta,
    double? fatigueDelta,
    double? ctlDelta,
    double? formAdrenalineMultiplier,
    bool? requiresManagerDecision,
  }) {
    return PersonalLifeEventRecord(
      eventId: eventId ?? this.eventId,
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      nationalityIso: nationalityIso ?? this.nationalityIso,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      triggeredAt: triggeredAt ?? this.triggeredAt,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
      selectedLeaveOption: selectedLeaveOption ?? this.selectedLeaveOption,
      homeRaceName: homeRaceName ?? this.homeRaceName,
      homeRaceCountryIso: homeRaceCountryIso ?? this.homeRaceCountryIso,
      homeRaceTier: homeRaceTier ?? this.homeRaceTier,
      moraleDelta: moraleDelta ?? this.moraleDelta,
      loyaltyDelta: loyaltyDelta ?? this.loyaltyDelta,
      fatigueDelta: fatigueDelta ?? this.fatigueDelta,
      ctlDelta: ctlDelta ?? this.ctlDelta,
      formAdrenalineMultiplier:
          formAdrenalineMultiplier ?? this.formAdrenalineMultiplier,
      requiresManagerDecision:
          requiresManagerDecision ?? this.requiresManagerDecision,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'riderId': riderId,
      'riderName': riderName,
      'nationalityIso': nationalityIso,
      'type': type.toJson(),
      'title': title,
      'description': description,
      'triggeredAt': triggeredAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'status': status.toJson(),
      'selectedLeaveOption': selectedLeaveOption?.toJson(),
      'homeRaceName': homeRaceName,
      'homeRaceCountryIso': homeRaceCountryIso,
      'homeRaceTier': homeRaceTier?.toJson(),
      'moraleDelta': moraleDelta,
      'loyaltyDelta': loyaltyDelta,
      'fatigueDelta': fatigueDelta,
      'ctlDelta': ctlDelta,
      'formAdrenalineMultiplier': formAdrenalineMultiplier,
      'requiresManagerDecision': requiresManagerDecision,
    };
  }

  factory PersonalLifeEventRecord.fromJson(Map<String, dynamic> json) {
    return PersonalLifeEventRecord(
      eventId: json['eventId'] as String? ?? '',
      riderId: json['riderId'] as String? ?? '',
      riderName: json['riderName'] as String? ?? '',
      nationalityIso: json['nationalityIso'] as String? ?? 'POL',
      type: PersonalLifeEventType.fromJson(
        json['type'] as String? ?? 'familyMilestone',
      ),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      triggeredAt: DateTime.tryParse(json['triggeredAt'] as String? ?? '') ??
          DateTime(2026, 3, 1),
      expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? '') ??
          DateTime(2026, 3, 15),
      status: PersonalEventResolutionStatus.fromJson(
        json['status'] as String? ?? 'pendingDecision',
      ),
      selectedLeaveOption: json['selectedLeaveOption'] != null
          ? PaternityLeaveOption.fromJson(json['selectedLeaveOption'] as String)
          : null,
      homeRaceName: json['homeRaceName'] as String?,
      homeRaceCountryIso: json['homeRaceCountryIso'] as String?,
      homeRaceTier: json['homeRaceTier'] != null
          ? HomeRaceBonusTier.fromJson(json['homeRaceTier'] as String)
          : null,
      moraleDelta: (json['moraleDelta'] as num?)?.toInt() ?? 0,
      loyaltyDelta: (json['loyaltyDelta'] as num?)?.toInt() ?? 0,
      fatigueDelta: (json['fatigueDelta'] as num?)?.toDouble() ?? 0.0,
      ctlDelta: (json['ctlDelta'] as num?)?.toDouble() ?? 0.0,
      formAdrenalineMultiplier:
          (json['formAdrenalineMultiplier'] as num?)?.toDouble() ?? 1.0,
      requiresManagerDecision:
          json['requiresManagerDecision'] as bool? ?? false,
    );
  }
}

/// Modyfikatory startowe wynikające z życia osobistego i domowych wyścigów.
class PersonalLifeRaceModifiers {
  final String riderId;
  final bool isAvailableForSelection;
  final String? unavailabilityReason;
  final int moraleBonus;
  final int loyaltyBonus;
  final double adrenalinePowerMultiplier;
  final double focusStabilityFactor;
  final String activeEventSummary;

  const PersonalLifeRaceModifiers({
    required this.riderId,
    required this.isAvailableForSelection,
    this.unavailabilityReason,
    required this.moraleBonus,
    required this.loyaltyBonus,
    required this.adrenalinePowerMultiplier,
    required this.focusStabilityFactor,
    required this.activeEventSummary,
  });
}

/// Wynik dziennego przeliczenia wydarzeń z życia osobistego kadry.
class DailyPersonalLifeTickResult {
  final Map<String, RiderFamilyProfile> updatedProfiles;
  final List<PersonalLifeEventRecord> allEvents;
  final List<PersonalLifeEventRecord> newlyTriggeredEvents;
  final List<String> expiredLeaveRiderIds;

  const DailyPersonalLifeTickResult({
    required this.updatedProfiles,
    required this.allEvents,
    required this.newlyTriggeredEvents,
    required this.expiredLeaveRiderIds,
  });
}

/// Serwis zarządzający wydarzeniami z życia osobistego kolarzy:
/// narodzinami dziecka, urlopem ojcowskim, tęsknotą za domem oraz domowymi wyścigami.
class RiderPersonalLifeAndFamilyEventsService {
  const RiderPersonalLifeAndFamilyEventsService();

  static const Map<String, List<List<String>>> _countryHometowns = {
    'POL': [
      ['Kraków', 'Małopolska'],
      ['Sobótka', 'Dolny Śląsk'],
      ['Gdańsk', 'Pomorze'],
      ['Zakopane', 'Podhale'],
    ],
    'BEL': [
      ['Oudenaarde', 'Flandria Wschodnia'],
      ['Roeselare', 'Flandria Zachodnia'],
      ['Liège', 'Walonia'],
    ],
    'FRA': [
      ['Chambéry', 'Sabaudia'],
      ['Quimper', 'Bretania'],
      ['Pau', 'Pireneje'],
    ],
    'ESP': [
      ['Bilbao', 'Kraj Basków'],
      ['Girona', 'Katalonia'],
      ['Granada', 'Andaluzja'],
    ],
    'ITA': [
      ['Bergamo', 'Lombardia'],
      ['Siena', 'Toskania'],
      ['Bassano del Grappa', 'Wenecja Euganejska'],
    ],
    'NED': [
      ['Valkenburg', 'Limburgia'],
      ['Utrecht', 'Utrecht'],
    ],
    'SLO': [
      ['Kranj', 'Gorenjska'],
      ['Novo Mesto', 'Dolenjska'],
    ],
    'GBR': [
      ['Harrogate', 'Yorkshire'],
      ['Manchester', 'Lancashire'],
    ],
  };

  /// Tworzy początkowy profil rodzinny dla kolarza na podstawie jego danych.
  RiderFamilyProfile createInitialProfile(
    Rider rider, {
    String? hometown,
    String? homeRegion,
    int? childrenCount,
    DateTime? expectingChildDueDate,
    int familyHappiness = 78,
  }) {
    final hash = rider.id.codeUnits.fold<int>(0, (acc, c) => acc + c);
    final options = _countryHometowns[rider.nationalityIso.toUpperCase()] ??
        const [
          ['Girona', 'Katalonia'],
          ['Lugano', 'Ticino'],
        ];
    final picked = options[hash % options.length];
    final age = rider.age;

    final defaultMarital = age >= 27
        ? (hash % 3 == 0 ? 'Żonaty / Partnerstwo' : 'Małżeństwo')
        : (hash % 2 == 0 ? 'W związku' : 'Singiel');

    final defaultChildren = childrenCount ?? (age >= 30 ? (hash % 3) : 0);

    return RiderFamilyProfile(
      riderId: rider.id,
      riderName: rider.fullName,
      nationalityIso: rider.nationalityIso.toUpperCase(),
      hometownName: hometown ?? picked[0],
      homeRegionName: homeRegion ?? picked[1],
      maritalStatusLabel: defaultMarital,
      childrenCount: defaultChildren,
      expectingChildDueDate: expectingChildDueDate,
      daysAwayFromHomeSeason: 0,
      familyHappiness: familyHappiness.clamp(0, 100),
      teamLoyaltyDelta: 0,
      paternityLeaveEndsAt: null,
    );
  }

  /// Tworzy wydarzenie narodzin dziecka wymagające decyzji menedżera o urlopie ojcowskim.
  PersonalLifeEventRecord triggerChildBirthEvent({
    required Rider rider,
    required RiderFamilyProfile profile,
    required DateTime birthDate,
  }) {
    final eventId =
        'childbirth_${rider.id}_${birthDate.toIso8601String().substring(0, 10)}';
    return PersonalLifeEventRecord(
      eventId: eventId,
      riderId: rider.id,
      riderName: rider.fullName,
      nationalityIso: rider.nationalityIso.toUpperCase(),
      type: PersonalLifeEventType.childBirth,
      title: 'Narodziny dziecka: ${rider.fullName}',
      description:
          'W miejscowości ${profile.hometownName} przyszło na świat dziecko ${rider.fullName}. '
          'Zadecyduj o długości urlopu ojcowskiego i wsparciu ze strony zespołu.',
      triggeredAt: birthDate,
      expiresAt: birthDate.add(const Duration(days: 3)),
      status: PersonalEventResolutionStatus.pendingDecision,
      selectedLeaveOption: null,
      moraleDelta: 0,
      loyaltyDelta: 0,
      fatigueDelta: 0.0,
      ctlDelta: 0.0,
      formAdrenalineMultiplier: 1.0,
      requiresManagerDecision: true,
    );
  }

  /// Rozstrzyga decyzję o urlopie ojcowskim i zwraca zaktualizowane wydarzenie oraz profil kolarza.
  ({PersonalLifeEventRecord event, RiderFamilyProfile profile})
      resolvePaternityLeaveDecision({
    required PersonalLifeEventRecord event,
    required RiderFamilyProfile profile,
    required PaternityLeaveOption option,
    required DateTime decisionDate,
  }) {
    final leaveDays = option.leaveDurationDays;
    final hasLeave = leaveDays > 0;
    final leaveEnd = hasLeave
        ? decisionDate.add(Duration(days: leaveDays))
        : null;

    final updatedStatus = hasLeave
        ? PersonalEventResolutionStatus.activeLeave
        : PersonalEventResolutionStatus.resolvedStrained;

    final updatedProfile = profile.copyWith(
      childrenCount: event.type == PersonalLifeEventType.childBirth
          ? profile.childrenCount + 1
          : profile.childrenCount,
      clearExpectingChildDueDate: true,
      daysAwayFromHomeSeason:
          hasLeave ? math.max(0, profile.daysAwayFromHomeSeason - leaveDays) : profile.daysAwayFromHomeSeason,
      familyHappiness: profile.familyHappiness + option.moraleDelta,
      teamLoyaltyDelta: profile.teamLoyaltyDelta + option.loyaltyDelta,
      paternityLeaveEndsAt: leaveEnd,
      clearPaternityLeaveEndsAt: !hasLeave,
    );

    final updatedEvent = event.copyWith(
      type: hasLeave
          ? PersonalLifeEventType.paternityLeave
          : PersonalLifeEventType.childBirth,
      status: updatedStatus,
      selectedLeaveOption: option,
      expiresAt: leaveEnd ?? decisionDate.add(const Duration(days: 10)),
      moraleDelta: option.moraleDelta,
      loyaltyDelta: option.loyaltyDelta,
      fatigueDelta: hasLeave ? -18.0 : 4.0,
      ctlDelta: option.ctlDelta,
      formAdrenalineMultiplier: hasLeave ? 1.01 : 0.96,
      requiresManagerDecision: false,
      description: hasLeave
          ? '${profile.riderName} przebywa na urlopie ojcowskim (${option.label}) w ${profile.hometownName} do ${_formatDate(leaveEnd!)}.'
          : '${profile.riderName} pozostał w składzie mimo narodzin dziecka. Odczuwa silne rozproszenie i spadek morale.',
    );

    return (event: updatedEvent, profile: updatedProfile);
  }

  /// Ocenia poziom motywacji domowego wyścigu dla kolarza.
  HomeRaceBonusTier? determineHomeRaceTier({
    required RiderFamilyProfile profile,
    required String raceCountryIso,
    String? raceRegionName,
    String? racePassThroughCity,
  }) {
    final cityLower = racePassThroughCity?.trim().toLowerCase() ?? '';
    final hometownLower = profile.hometownName.trim().toLowerCase();
    if (cityLower.isNotEmpty && cityLower == hometownLower) {
      return HomeRaceBonusTier.hometownVillage;
    }

    final regionLower = raceRegionName?.trim().toLowerCase() ?? '';
    final homeRegionLower = profile.homeRegionName.trim().toLowerCase();
    if (regionLower.isNotEmpty && regionLower == homeRegionLower) {
      return HomeRaceBonusTier.homeRegion;
    }

    if (raceCountryIso.trim().toUpperCase() ==
        profile.nationalityIso.trim().toUpperCase()) {
      return HomeRaceBonusTier.homeCountry;
    }

    return null;
  }

  /// Tworzy wydarzenie domowego wyścigu z premią adrenaliny, morale i ekspozycji medialnej.
  PersonalLifeEventRecord? evaluateHomeRaceMotivation({
    required Rider rider,
    required RiderFamilyProfile profile,
    required String raceName,
    required String raceCountryIso,
    String? raceRegionName,
    String? racePassThroughCity,
    required DateTime raceDate,
  }) {
    final tier = determineHomeRaceTier(
      profile: profile,
      raceCountryIso: raceCountryIso,
      raceRegionName: raceRegionName,
      racePassThroughCity: racePassThroughCity,
    );
    if (tier == null) return null;

    return PersonalLifeEventRecord(
      eventId:
          'homerace_${rider.id}_${raceDate.toIso8601String().substring(0, 10)}',
      riderId: rider.id,
      riderName: rider.fullName,
      nationalityIso: profile.nationalityIso,
      type: PersonalLifeEventType.homeRace,
      title: 'Domowy wyścig: $raceName (${tier.label})',
      description: tier == HomeRaceBonusTier.hometownVillage
          ? 'Trasa $raceName przebiega przez rodzinne miasto ${profile.hometownName}! Rodzina i lokalny fanklub stoją przy barierach.'
          : 'Start w ${tier.label.toLowerCase()} ($raceName) wyzwala u ${rider.fullName} dodatkową mobilizację przed własną publicznością.',
      triggeredAt: raceDate,
      expiresAt: raceDate.add(const Duration(days: 2)),
      status: PersonalEventResolutionStatus.resolvedBoosted,
      homeRaceName: raceName,
      homeRaceCountryIso: raceCountryIso.toUpperCase(),
      homeRaceTier: tier,
      moraleDelta: tier.moraleBoost,
      loyaltyDelta: 4,
      fatigueDelta: -3.0,
      ctlDelta: 0.0,
      formAdrenalineMultiplier: tier.adrenalineMultiplier,
      requiresManagerDecision: false,
    );
  }

  /// Przelicza dzienną symulację życia osobistego kadry (terminy porodów, tęsknota za domem, wygasanie urlopów).
  DailyPersonalLifeTickResult evaluateDailyLifeEvents({
    required List<Rider> roster,
    required Map<String, RiderFamilyProfile> profiles,
    required List<PersonalLifeEventRecord> existingEvents,
    required DateTime currentDate,
    bool isTeamAwayOnRaceOrCamp = true,
    String? upcomingRaceName,
    String? upcomingRaceCountryIso,
    String? upcomingRaceRegion,
    String? upcomingRaceCity,
    int seed = 42,
  }) {
    final updatedProfiles = Map<String, RiderFamilyProfile>.from(profiles);
    final updatedEvents = List<PersonalLifeEventRecord>.from(existingEvents);
    final newlyTriggered = <PersonalLifeEventRecord>[];
    final expiredLeaveRiders = <String>[];
    final rng = math.Random(
      seed ^ currentDate.year ^ (currentDate.month * 31) ^ currentDate.day,
    );

    // 1. Wygaszanie przeterminowanych wydarzeń i zakończonych urlopów.
    for (int i = 0; i < updatedEvents.length; i++) {
      final ev = updatedEvents[i];
      if (ev.status == PersonalEventResolutionStatus.activeLeave &&
          currentDate.isAfter(ev.expiresAt)) {
        updatedEvents[i] = ev.copyWith(
          status: PersonalEventResolutionStatus.resolvedBoosted,
        );
        expiredLeaveRiders.add(ev.riderId);
        final p = updatedProfiles[ev.riderId];
        if (p != null) {
          updatedProfiles[ev.riderId] = p.copyWith(
            clearPaternityLeaveEndsAt: true,
          );
        }
      } else if (ev.status == PersonalEventResolutionStatus.pendingDecision &&
          currentDate.isAfter(ev.expiresAt)) {
        // Brak decyzji menedżera w terminie oznacza automatyczne pozostanie w składzie z karą morale.
        final p = updatedProfiles[ev.riderId];
        if (p != null) {
          final res = resolvePaternityLeaveDecision(
            event: ev,
            profile: p,
            option: PaternityLeaveOption.stayOnRaceRoster,
            decisionDate: currentDate,
          );
          updatedEvents[i] = res.event;
          updatedProfiles[ev.riderId] = res.profile;
        } else {
          updatedEvents[i] = ev.copyWith(
            status: PersonalEventResolutionStatus.expired,
            requiresManagerDecision: false,
          );
        }
      }
    }

    // 2. Przetwarzanie każdego kolarza w kadrze.
    for (final rider in roster) {
      final profile = updatedProfiles.putIfAbsent(
        rider.id,
        () => createInitialProfile(rider),
      );

      if (profile.isOnPaternityLeaveAt(currentDate)) {
        continue;
      }

      var workingProfile = profile;
      if (isTeamAwayOnRaceOrCamp) {
        final nextDaysAway = workingProfile.daysAwayFromHomeSeason + 1;
        final happinessDrain = nextDaysAway > 45 && nextDaysAway % 7 == 0 ? -3 : 0;
        workingProfile = workingProfile.copyWith(
          daysAwayFromHomeSeason: nextDaysAway,
          familyHappiness: workingProfile.familyHappiness + happinessDrain,
        );
      }

      // Narodziny dziecka w terminie porodu.
      final dueDate = workingProfile.expectingChildDueDate;
      if (dueDate != null && !currentDate.isBefore(dueDate)) {
        final alreadyHasBirth = updatedEvents.any(
          (e) =>
              e.riderId == rider.id &&
              e.type == PersonalLifeEventType.childBirth &&
              e.triggeredAt.year == currentDate.year &&
              e.triggeredAt.month == currentDate.month &&
              e.triggeredAt.day == currentDate.day,
        );
        if (!alreadyHasBirth) {
          final birthEvent = triggerChildBirthEvent(
            rider: rider,
            profile: workingProfile,
            birthDate: currentDate,
          );
          updatedEvents.insert(0, birthEvent);
          newlyTriggered.add(birthEvent);
          workingProfile = workingProfile.copyWith(
            clearExpectingChildDueDate: true,
          );
        }
      }

      // Tęsknota za domem po długiej rozłące (>55 dni poza domem).
      if (workingProfile.daysAwayFromHomeSeason >= 55 &&
          workingProfile.familyHappiness <= 58 &&
          rng.nextDouble() < 0.18) {
        final hasActiveHomesickness = updatedEvents.any(
          (e) =>
              e.riderId == rider.id &&
              e.type == PersonalLifeEventType.homesicknessWave &&
              !currentDate.isAfter(e.expiresAt),
        );
        if (!hasActiveHomesickness) {
          final homesickEvent = PersonalLifeEventRecord(
            eventId:
                'homesick_${rider.id}_${currentDate.toIso8601String().substring(0, 10)}',
            riderId: rider.id,
            riderName: rider.fullName,
            nationalityIso: workingProfile.nationalityIso,
            type: PersonalLifeEventType.homesicknessWave,
            title: 'Tęsknota za domem: ${rider.fullName}',
            description:
                '${rider.fullName} spędził już ${workingProfile.daysAwayFromHomeSeason} dni poza domem (${workingProfile.hometownName}). '
                'Weekend odpoczynku z rodziną przywróci równowagę psychiczną.',
            triggeredAt: currentDate,
            expiresAt: currentDate.add(const Duration(days: 7)),
            status: PersonalEventResolutionStatus.resolvedStrained,
            moraleDelta: -9,
            loyaltyDelta: -3,
            fatigueDelta: 5.0,
            ctlDelta: 0.0,
            formAdrenalineMultiplier: 0.97,
            requiresManagerDecision: false,
          );
          updatedEvents.insert(0, homesickEvent);
          newlyTriggered.add(homesickEvent);
        }
      }

      // Domowy wyścig przed startem.
      if (upcomingRaceName != null &&
          upcomingRaceCountryIso != null &&
          upcomingRaceName.isNotEmpty) {
        final alreadyHomeRace = updatedEvents.any(
          (e) =>
              e.riderId == rider.id &&
              e.type == PersonalLifeEventType.homeRace &&
              e.homeRaceName == upcomingRaceName &&
              !currentDate.isAfter(e.expiresAt),
        );
        if (!alreadyHomeRace) {
          final homeEvent = evaluateHomeRaceMotivation(
            rider: rider,
            profile: workingProfile,
            raceName: upcomingRaceName,
            raceCountryIso: upcomingRaceCountryIso,
            raceRegionName: upcomingRaceRegion,
            racePassThroughCity: upcomingRaceCity,
            raceDate: currentDate,
          );
          if (homeEvent != null) {
            updatedEvents.insert(0, homeEvent);
            newlyTriggered.add(homeEvent);
            workingProfile = workingProfile.copyWith(
              familyHappiness: workingProfile.familyHappiness + 4,
            );
          }
        }
      }

      updatedProfiles[rider.id] = workingProfile;
    }

    return DailyPersonalLifeTickResult(
      updatedProfiles: updatedProfiles,
      allEvents: updatedEvents,
      newlyTriggeredEvents: newlyTriggered,
      expiredLeaveRiderIds: expiredLeaveRiders,
    );
  }

  /// Przyznaje kolarzowi weekend wolnego w domu, redukując tęsknotę i podnosząc morale rodziny.
  ({RiderFamilyProfile profile, PersonalLifeEventRecord event})
      grantFamilyRestWeekend({
    required Rider rider,
    required RiderFamilyProfile profile,
    required DateTime currentDate,
  }) {
    final updatedProfile = profile.copyWith(
      daysAwayFromHomeSeason: math.max(0, profile.daysAwayFromHomeSeason - 10),
      familyHappiness: profile.familyHappiness + 14,
      teamLoyaltyDelta: profile.teamLoyaltyDelta + 4,
    );

    final event = PersonalLifeEventRecord(
      eventId:
          'family_rest_${rider.id}_${currentDate.toIso8601String().substring(0, 10)}',
      riderId: rider.id,
      riderName: rider.fullName,
      nationalityIso: profile.nationalityIso,
      type: PersonalLifeEventType.familyMilestone,
      title: 'Weekend z rodziną: ${rider.fullName}',
      description:
          'Menedżer przyznał ${rider.fullName} wolny weekend w ${profile.hometownName}. '
          'Szczęście rodzinne i skupienie wyraźnie wzrosły.',
      triggeredAt: currentDate,
      expiresAt: currentDate.add(const Duration(days: 7)),
      status: PersonalEventResolutionStatus.resolvedBoosted,
      moraleDelta: 12,
      loyaltyDelta: 4,
      fatigueDelta: -10.0,
      ctlDelta: -0.5,
      formAdrenalineMultiplier: 1.015,
      requiresManagerDecision: false,
    );

    return (profile: updatedProfile, event: event);
  }

  /// Oblicza finalne modyfikatory gotowości wyścigowej kolarza na dany dzień.
  PersonalLifeRaceModifiers computeRaceModifiers({
    required Rider rider,
    required RiderFamilyProfile profile,
    required List<PersonalLifeEventRecord> activeEvents,
    required DateTime raceDate,
    String? raceCountryIso,
    String? raceRegionName,
    String? racePassThroughCity,
  }) {
    if (profile.isOnPaternityLeaveAt(raceDate)) {
      return PersonalLifeRaceModifiers(
        riderId: rider.id,
        isAvailableForSelection: false,
        unavailabilityReason:
            'Urlop ojcowski do ${_formatDate(profile.paternityLeaveEndsAt!)}',
        moraleBonus: 12,
        loyaltyBonus: profile.teamLoyaltyDelta,
        adrenalinePowerMultiplier: 1.0,
        focusStabilityFactor: 1.0,
        activeEventSummary: 'Przebywanie na urlopie ojcowskim',
      );
    }

    int moraleSum = 0;
    double adrenaline = 1.0;
    double focus = 1.0;
    final summaries = <String>[];

    for (final ev in activeEvents) {
      if (ev.riderId != rider.id) continue;
      if (raceDate.isBefore(ev.triggeredAt) || raceDate.isAfter(ev.expiresAt)) {
        continue;
      }
      moraleSum += ev.moraleDelta;
      if (ev.formAdrenalineMultiplier > adrenaline) {
        adrenaline = ev.formAdrenalineMultiplier;
      } else if (ev.formAdrenalineMultiplier < 1.0) {
        focus = math.min(focus, ev.formAdrenalineMultiplier);
      }
      summaries.add(ev.title);
    }

    if (raceCountryIso != null && raceCountryIso.isNotEmpty) {
      final homeTier = determineHomeRaceTier(
        profile: profile,
        raceCountryIso: raceCountryIso,
        raceRegionName: raceRegionName,
        racePassThroughCity: racePassThroughCity,
      );
      if (homeTier != null) {
        adrenaline = math.max(adrenaline, homeTier.adrenalineMultiplier);
        if (summaries.isEmpty) {
          moraleSum += homeTier.moraleBoost;
          summaries.add('Domowy wyścig (${homeTier.label})');
        }
      }
    }

    if (profile.familyHappiness < 45) {
      focus = math.min(focus, 0.96);
    } else if (profile.familyHappiness >= 85) {
      focus = math.max(focus, 1.02);
    }

    return PersonalLifeRaceModifiers(
      riderId: rider.id,
      isAvailableForSelection: true,
      moraleBonus: moraleSum.clamp(-25, 30),
      loyaltyBonus: profile.teamLoyaltyDelta,
      adrenalinePowerMultiplier: adrenaline.clamp(0.95, 1.06),
      focusStabilityFactor: focus.clamp(0.93, 1.04),
      activeEventSummary:
          summaries.isEmpty ? 'Stabilna sytuacja rodzinna' : summaries.join(' • '),
    );
  }

  static String _formatDate(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }
}

/// Filtr listy wydarzeń w panelu życia osobistego.
enum PersonalLifeEventFilter {
  all,
  pendingDecision,
  activeLeave,
  homeRace;

  String get label {
    switch (this) {
      case PersonalLifeEventFilter.all:
        return 'Wszystkie';
      case PersonalLifeEventFilter.pendingDecision:
        return 'Decyzje';
      case PersonalLifeEventFilter.activeLeave:
        return 'Urlopy';
      case PersonalLifeEventFilter.homeRace:
        return 'Domowe';
    }
  }
}

/// Stan Riverpod dla modułu życia osobistego i wydarzeń rodzinnych kolarzy.
class RiderPersonalLifeState {
  final DateTime currentDate;
  final Map<String, RiderFamilyProfile> profiles;
  final List<PersonalLifeEventRecord> events;
  final String? selectedRiderId;
  final PersonalLifeEventFilter activeFilter;
  final String? statusBanner;

  const RiderPersonalLifeState({
    required this.currentDate,
    required this.profiles,
    required this.events,
    this.selectedRiderId,
    this.activeFilter = PersonalLifeEventFilter.all,
    this.statusBanner,
  });

  List<PersonalLifeEventRecord> get filteredEvents {
    return events.where((ev) {
      if (selectedRiderId != null && ev.riderId != selectedRiderId) {
        return false;
      }
      switch (activeFilter) {
        case PersonalLifeEventFilter.all:
          return true;
        case PersonalLifeEventFilter.pendingDecision:
          return ev.requiresManagerDecision &&
              ev.status == PersonalEventResolutionStatus.pendingDecision;
        case PersonalLifeEventFilter.activeLeave:
          return ev.status == PersonalEventResolutionStatus.activeLeave;
        case PersonalLifeEventFilter.homeRace:
          return ev.type == PersonalLifeEventType.homeRace;
      }
    }).toList(growable: false);
  }

  int get pendingDecisionsCount => events
      .where(
        (e) =>
            e.requiresManagerDecision &&
            e.status == PersonalEventResolutionStatus.pendingDecision,
      )
      .length;

  int get ridersOnLeaveCount => profiles.values
      .where((p) => p.isOnPaternityLeaveAt(currentDate))
      .length;

  RiderPersonalLifeState copyWith({
    DateTime? currentDate,
    Map<String, RiderFamilyProfile>? profiles,
    List<PersonalLifeEventRecord>? events,
    String? selectedRiderId,
    bool clearSelectedRiderId = false,
    PersonalLifeEventFilter? activeFilter,
    String? statusBanner,
  }) {
    return RiderPersonalLifeState(
      currentDate: currentDate ?? this.currentDate,
      profiles: profiles ?? this.profiles,
      events: events ?? this.events,
      selectedRiderId: clearSelectedRiderId
          ? null
          : (selectedRiderId ?? this.selectedRiderId),
      activeFilter: activeFilter ?? this.activeFilter,
      statusBanner: statusBanner ?? this.statusBanner,
    );
  }
}

/// Kontroler Riverpod zarządzający życiem osobistym i wydarzeniami rodzinnymi.
class RiderPersonalLifeNotifier extends StateNotifier<RiderPersonalLifeState> {
  final RiderPersonalLifeAndFamilyEventsService _service;

  RiderPersonalLifeNotifier({
    RiderPersonalLifeAndFamilyEventsService service =
        const RiderPersonalLifeAndFamilyEventsService(),
    DateTime? initialDate,
    List<Rider> initialRoster = const [],
  })  : _service = service,
        super(
          RiderPersonalLifeState(
            currentDate: initialDate ?? DateTime(2026, 5, 14),
            profiles: {
              for (final r in initialRoster)
                r.id: service.createInitialProfile(r),
            },
            events: const [],
            selectedRiderId:
                initialRoster.isNotEmpty ? initialRoster.first.id : null,
          ),
        );

  void initializeRoster(List<Rider> roster, {DateTime? currentDate}) {
    final nextProfiles = <String, RiderFamilyProfile>{};
    for (final rider in roster) {
      nextProfiles[rider.id] =
          state.profiles[rider.id] ?? _service.createInitialProfile(rider);
    }
    state = state.copyWith(
      currentDate: currentDate ?? state.currentDate,
      profiles: nextProfiles,
      selectedRiderId:
          state.selectedRiderId ?? (roster.isNotEmpty ? roster.first.id : null),
    );
  }

  void selectRider(String? riderId) {
    if (riderId == null) {
      state = state.copyWith(clearSelectedRiderId: true);
    } else {
      state = state.copyWith(selectedRiderId: riderId);
    }
  }

  void setFilter(PersonalLifeEventFilter filter) {
    state = state.copyWith(activeFilter: filter);
  }

  void triggerChildBirthForRider(Rider rider) {
    final profile =
        state.profiles[rider.id] ?? _service.createInitialProfile(rider);
    final event = _service.triggerChildBirthEvent(
      rider: rider,
      profile: profile,
      birthDate: state.currentDate,
    );
    state = state.copyWith(
      profiles: {...state.profiles, rider.id: profile},
      events: [event, ...state.events],
      statusBanner: 'Nowe narodziny w zespole: ${rider.fullName} czeka na decyzję o urlopie.',
    );
  }

  void resolvePaternityDecision({
    required String eventId,
    required PaternityLeaveOption option,
  }) {
    final idx = state.events.indexWhere((e) => e.eventId == eventId);
    if (idx < 0) return;
    final event = state.events[idx];
    final profile = state.profiles[event.riderId];
    if (profile == null) return;

    final resolved = _service.resolvePaternityLeaveDecision(
      event: event,
      profile: profile,
      option: option,
      decisionDate: state.currentDate,
    );

    final nextEvents = List<PersonalLifeEventRecord>.from(state.events);
    nextEvents[idx] = resolved.event;

    state = state.copyWith(
      profiles: {...state.profiles, profile.riderId: resolved.profile},
      events: nextEvents,
      statusBanner:
          'Decyzja podjęta (${option.label}) dla ${profile.riderName}.',
    );
  }

  void triggerHomeRaceCheck({
    required List<Rider> roster,
    required String raceName,
    required String raceCountryIso,
    String? raceRegionName,
    String? racePassThroughCity,
  }) {
    final nextProfiles = Map<String, RiderFamilyProfile>.from(state.profiles);
    final newEvents = <PersonalLifeEventRecord>[];

    for (final rider in roster) {
      final profile =
          nextProfiles[rider.id] ?? _service.createInitialProfile(rider);
      nextProfiles[rider.id] = profile;
      final ev = _service.evaluateHomeRaceMotivation(
        rider: rider,
        profile: profile,
        raceName: raceName,
        raceCountryIso: raceCountryIso,
        raceRegionName: raceRegionName,
        racePassThroughCity: racePassThroughCity,
        raceDate: state.currentDate,
      );
      if (ev != null) {
        newEvents.add(ev);
      }
    }

    if (newEvents.isEmpty) {
      state = state.copyWith(
        profiles: nextProfiles,
        statusBanner: 'Brak kolarzy z domową motywacją na wyścig $raceName.',
      );
      return;
    }

    state = state.copyWith(
      profiles: nextProfiles,
      events: [...newEvents, ...state.events],
      statusBanner:
          'Wykryto ${newEvents.length} domowe motywacje na wyścig $raceName.',
    );
  }

  void grantFamilyRestWeekend(Rider rider) {
    final profile =
        state.profiles[rider.id] ?? _service.createInitialProfile(rider);
    if (profile.isOnPaternityLeaveAt(state.currentDate)) return;

    final res = _service.grantFamilyRestWeekend(
      rider: rider,
      profile: profile,
      currentDate: state.currentDate,
    );
    state = state.copyWith(
      profiles: {...state.profiles, rider.id: res.profile},
      events: [res.event, ...state.events],
      statusBanner: 'Przyznano weekend rodzinny dla ${rider.fullName}.',
    );
  }

  void advanceOneDay(List<Rider> roster) {
    final nextDate = state.currentDate.add(const Duration(days: 1));
    final tick = _service.evaluateDailyLifeEvents(
      roster: roster,
      profiles: state.profiles,
      existingEvents: state.events,
      currentDate: nextDate,
    );
    state = state.copyWith(
      currentDate: nextDate,
      profiles: tick.updatedProfiles,
      events: tick.allEvents,
      statusBanner: tick.newlyTriggeredEvents.isNotEmpty
          ? 'Nowe wydarzenia rodzinne: ${tick.newlyTriggeredEvents.length}.'
          : 'Zaktualizowano kalendarz rodzinny na ${_formatIso(nextDate)}.',
    );
  }

  static String _formatIso(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

final riderPersonalLifeServiceProvider =
    Provider<RiderPersonalLifeAndFamilyEventsService>(
  (ref) => const RiderPersonalLifeAndFamilyEventsService(),
);

final riderPersonalLifeProvider = StateNotifierProvider<
    RiderPersonalLifeNotifier, RiderPersonalLifeState>((ref) {
  return RiderPersonalLifeNotifier(
    service: ref.watch(riderPersonalLifeServiceProvider),
  );
});

/// Produkcyjny panel UI zarządzania życiem osobistym i wydarzeniami rodzinnymi kolarzy.
/// Obsługuje responsywność `390x844`, `1024x768` i `1600x900`, paletę `AppColors` oraz czcionkę `Inter`.
class RiderPersonalLifeAndFamilyEventsPanel extends ConsumerStatefulWidget {
  final List<Rider> roster;
  final String upcomingRaceName;
  final String upcomingRaceCountryIso;
  final String? upcomingRaceRegion;
  final String? upcomingRaceCity;

  const RiderPersonalLifeAndFamilyEventsPanel({
    super.key,
    required this.roster,
    this.upcomingRaceName = 'Tour de Pologne',
    this.upcomingRaceCountryIso = 'POL',
    this.upcomingRaceRegion = 'Małopolska',
    this.upcomingRaceCity = 'Kraków',
  });

  @override
  ConsumerState<RiderPersonalLifeAndFamilyEventsPanel> createState() =>
      _RiderPersonalLifeAndFamilyEventsPanelState();
}

class _RiderPersonalLifeAndFamilyEventsPanelState
    extends ConsumerState<RiderPersonalLifeAndFamilyEventsPanel> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(riderPersonalLifeProvider.notifier).initializeRoster(widget.roster);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lifeState = ref.watch(riderPersonalLifeProvider);
    final notifier = ref.read(riderPersonalLifeProvider.notifier);
    final service = ref.watch(riderPersonalLifeServiceProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 1100;
          final isTablet =
              constraints.maxWidth >= 700 && constraints.maxWidth < 1100;

          return Padding(
            padding: EdgeInsets.all(isDesktop ? 24 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(lifeState, notifier, isDesktop),
                const SizedBox(height: 16),
                _buildKpiStrip(lifeState, isDesktop || isTablet),
                if (lifeState.statusBanner != null) ...[
                  const SizedBox(height: 12),
                  _buildStatusBanner(lifeState.statusBanner!),
                ],
                const SizedBox(height: 16),
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: _buildRosterFamilyColumn(
                          lifeState,
                          notifier,
                          service,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 7,
                        child: _buildEventsAndActionsColumn(
                          lifeState,
                          notifier,
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildRosterFamilyColumn(lifeState, notifier, service),
                      const SizedBox(height: 16),
                      _buildEventsAndActionsColumn(lifeState, notifier),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(
    RiderPersonalLifeState lifeState,
    RiderPersonalLifeNotifier notifier,
    bool isWide,
  ) {
    final actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _InteractiveActionButton(
          label: 'Sprawdź Domowy Wyścig',
          icon: Icons.flag_rounded,
          accentColor: AppColors.statusSuccess,
          enabled: widget.roster.isNotEmpty,
          onPressed: () => notifier.triggerHomeRaceCheck(
            roster: widget.roster,
            raceName: widget.upcomingRaceName,
            raceCountryIso: widget.upcomingRaceCountryIso,
            raceRegionName: widget.upcomingRaceRegion,
            racePassThroughCity: widget.upcomingRaceCity,
          ),
        ),
        _InteractiveActionButton(
          label: '+1 Dzień',
          icon: Icons.calendar_today_rounded,
          accentColor: AppColors.accentBlue,
          enabled: widget.roster.isNotEmpty,
          onPressed: () => notifier.advanceOneDay(widget.roster),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: isWide
          ? Row(
              children: [
                const Icon(
                  Icons.family_restroom_rounded,
                  color: AppColors.goldAccent,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Życie Osobiste i Wydarzenia Rodzinne',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Narodziny dzieci, urlopy ojcowskie, równowaga rodzinna i motywacja na domowych trasach (${widget.upcomingRaceName}).',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                actions,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.family_restroom_rounded,
                      color: AppColors.goldAccent,
                      size: 24,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Życie Osobiste i Rodzina',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Urlopy ojcowskie, tęsknota za domem i premia na wyścigu ${widget.upcomingRaceName}.',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                actions,
              ],
            ),
    );
  }

  Widget _buildKpiStrip(RiderPersonalLifeState lifeState, bool isMultiCol) {
    final avgHappiness = lifeState.profiles.isEmpty
        ? 0
        : (lifeState.profiles.values
                    .map((p) => p.familyHappiness)
                    .reduce((a, b) => a + b) /
                lifeState.profiles.length)
            .round();

    final cards = [
      _KpiTile(
        label: 'Decyzje Ojcowskie',
        value: '${lifeState.pendingDecisionsCount}',
        accent: AppColors.goldAccent,
        icon: Icons.child_friendly_rounded,
      ),
      _KpiTile(
        label: 'Aktywne Urlopy',
        value: '${lifeState.ridersOnLeaveCount}',
        accent: AppColors.accentBlue,
        icon: Icons.beach_access_rounded,
      ),
      _KpiTile(
        label: 'Szczęście Rodzinne',
        value: '$avgHappiness%',
        accent: AppColors.statusSuccess,
        icon: Icons.favorite_rounded,
      ),
      _KpiTile(
        label: 'Aktywne Zdarzenia',
        value: '${lifeState.events.length}',
        accent: AppColors.cyanAccent,
        icon: Icons.notifications_active_rounded,
      ),
    ];

    if (isMultiCol) {
      return Row(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            Expanded(child: cards[i]),
            if (i < cards.length - 1) const SizedBox(width: 12),
          ],
        ],
      );
    }

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

  Widget _buildStatusBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.accentBlue.withValues(alpha: 0.45),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppColors.accentBlue,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
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

  Widget _buildRosterFamilyColumn(
    RiderPersonalLifeState lifeState,
    RiderPersonalLifeNotifier notifier,
    RiderPersonalLifeAndFamilyEventsService service,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Profile Rodzinne Kadry',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (lifeState.selectedRiderId != null)
                _InteractiveActionButton(
                  label: 'Pokaż wszystkich',
                  icon: Icons.clear_all_rounded,
                  accentColor: AppColors.textSecondary,
                  compact: true,
                  onPressed: () => notifier.selectRider(null),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.roster.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Brak zakontraktowanych kolarzy w kadrze.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            for (final rider in widget.roster) ...[
              _buildRiderProfileTile(
                rider: rider,
                profile: lifeState.profiles[rider.id] ??
                    service.createInitialProfile(rider),
                lifeState: lifeState,
                notifier: notifier,
                service: service,
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }

  Widget _buildRiderProfileTile({
    required Rider rider,
    required RiderFamilyProfile profile,
    required RiderPersonalLifeState lifeState,
    required RiderPersonalLifeNotifier notifier,
    required RiderPersonalLifeAndFamilyEventsService service,
  }) {
    final isSelected = lifeState.selectedRiderId == rider.id;
    final onLeave = profile.isOnPaternityLeaveAt(lifeState.currentDate);
    final modifiers = service.computeRaceModifiers(
      rider: rider,
      profile: profile,
      activeEvents: lifeState.events,
      raceDate: lifeState.currentDate,
      raceCountryIso: widget.upcomingRaceCountryIso,
      raceRegionName: widget.upcomingRaceRegion,
      racePassThroughCity: widget.upcomingRaceCity,
    );

    return _InteractiveCardContainer(
      isSelected: isSelected,
      accentColor: onLeave ? AppColors.accentBlue : AppColors.primaryAccent,
      onTap: () => notifier.selectRider(isSelected ? null : rider.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${rider.fullName} (${profile.nationalityIso})',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _StatusBadge(
                label: onLeave ? 'Urlop Ojcowski' : 'Dostępny',
                color: onLeave ? AppColors.accentBlue : AppColors.statusSuccess,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Dom: ${profile.hometownName}, ${profile.homeRegionName} • Dzieci: ${profile.childrenCount} • Poza domem: ${profile.daysAwayFromHomeSeason} dni',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: profile.familyHappiness / 100.0,
                    minHeight: 6,
                    backgroundColor: AppColors.background,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      profile.familyHappiness >= 70
                          ? AppColors.statusSuccess
                          : (profile.familyHappiness >= 45
                              ? AppColors.amberWarning
                              : AppColors.crimsonAlert),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${profile.familyHappiness}% • Adrenalina x${modifiers.adrenalinePowerMultiplier.toStringAsFixed(3)}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InteractiveActionButton(
                label: 'Narodziny',
                icon: Icons.child_friendly_rounded,
                accentColor: AppColors.goldAccent,
                compact: true,
                onPressed: () => notifier.triggerChildBirthForRider(rider),
              ),
              _InteractiveActionButton(
                label: 'Weekend w domu',
                icon: Icons.home_rounded,
                accentColor: AppColors.cyanAccent,
                compact: true,
                enabled: !onLeave,
                onPressed: () => notifier.grantFamilyRestWeekend(rider),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventsAndActionsColumn(
    RiderPersonalLifeState lifeState,
    RiderPersonalLifeNotifier notifier,
  ) {
    final filtered = lifeState.filteredEvents;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Wydarzenia i Decyzje Menedżera',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final filter in PersonalLifeEventFilter.values)
                    _InteractiveActionButton(
                      label: filter.label,
                      accentColor: lifeState.activeFilter == filter
                          ? AppColors.goldAccent
                          : AppColors.textSecondary,
                      compact: true,
                      isActive: lifeState.activeFilter == filter,
                      onPressed: () => notifier.setFilter(filter),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder, width: 1),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.event_available_rounded,
                    color: AppColors.textSecondary,
                    size: 32,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Brak aktywnych wydarzeń w wybranym filtrze.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else
            for (final ev in filtered) ...[
              _buildEventCard(ev, notifier),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }

  Widget _buildEventCard(
    PersonalLifeEventRecord ev,
    RiderPersonalLifeNotifier notifier,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ev.requiresManagerDecision
              ? AppColors.goldAccent.withValues(alpha: 0.7)
              : AppColors.cardBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(ev.type.icon, color: ev.type.accentColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ev.title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _StatusBadge(label: ev.status.label, color: ev.status.color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            ev.description,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _MetricChip(
                label: 'Morale',
                value:
                    '${ev.moraleDelta >= 0 ? '+' : ''}${ev.moraleDelta}',
                color: ev.moraleDelta >= 0
                    ? AppColors.statusSuccess
                    : AppColors.crimsonAlert,
              ),
              _MetricChip(
                label: 'Lojalność',
                value:
                    '${ev.loyaltyDelta >= 0 ? '+' : ''}${ev.loyaltyDelta}',
                color: ev.loyaltyDelta >= 0
                    ? AppColors.accentBlue
                    : AppColors.crimsonAlert,
              ),
              _MetricChip(
                label: 'Moc',
                value:
                    'x${ev.formAdrenalineMultiplier.toStringAsFixed(3)}',
                color: AppColors.goldAccent,
              ),
            ],
          ),
          if (ev.requiresManagerDecision &&
              ev.status == PersonalEventResolutionStatus.pendingDecision) ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.cardBorder, height: 1),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in PaternityLeaveOption.values)
                  _InteractiveActionButton(
                    label: option.label,
                    accentColor: option == PaternityLeaveOption.stayOnRaceRoster
                        ? AppColors.crimsonAlert
                        : AppColors.goldAccent,
                    compact: true,
                    onPressed: () => notifier.resolvePaternityDecision(
                      eventId: ev.eventId,
                      option: option,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  final IconData icon;

  const _KpiTile({
    required this.label,
    required this.value,
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textSecondary,
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

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1),
      ),
      child: Text(
        label,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

/// Kontener karty z pełnymi stanami hover / active / focus.
class _InteractiveCardContainer extends StatefulWidget {
  final Widget child;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _InteractiveCardContainer({
    required this.child,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_InteractiveCardContainer> createState() =>
      _InteractiveCardContainerState();
}

class _InteractiveCardContainerState extends State<_InteractiveCardContainer> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isSelected || _isFocused
        ? widget.accentColor
        : (_isHovered
            ? widget.accentColor.withValues(alpha: 0.65)
            : AppColors.cardBorder);

    return FocusableActionDetector(
      onShowFocusHighlight: (focused) => setState(() => _isFocused = focused),
      onShowHoverHighlight: (hovered) => setState(() => _isHovered = hovered),
      mouseCursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _isPressed
                ? AppColors.background
                : (_isHovered
                    ? AppColors.surfaceLight.withValues(alpha: 0.9)
                    : AppColors.surfaceLight),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: widget.isSelected || _isFocused ? 1.5 : 1.0,
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Przycisk akcji z pełną obsługą stanów hover / active / disabled / focus.
class _InteractiveActionButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final Color accentColor;
  final VoidCallback onPressed;
  final bool enabled;
  final bool compact;
  final bool isActive;

  const _InteractiveActionButton({
    required this.label,
    this.icon,
    required this.accentColor,
    required this.onPressed,
    this.enabled = true,
    this.compact = false,
    this.isActive = false,
  });

  @override
  State<_InteractiveActionButton> createState() =>
      _InteractiveActionButtonState();
}

class _InteractiveActionButtonState extends State<_InteractiveActionButton> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = !widget.enabled;
    final effectiveColor =
        isDisabled ? AppColors.textSecondary : widget.accentColor;

    final bgColor = isDisabled
        ? AppColors.surface
        : (widget.isActive || _isPressed
            ? effectiveColor.withValues(alpha: 0.24)
            : (_isHovered
                ? effectiveColor.withValues(alpha: 0.16)
                : AppColors.surfaceLight));

    final borderColor = isDisabled
        ? AppColors.cardBorder.withValues(alpha: 0.5)
        : (_isFocused || widget.isActive
            ? effectiveColor
            : (_isHovered
                ? effectiveColor.withValues(alpha: 0.75)
                : AppColors.cardBorder));

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowFocusHighlight: (focused) => setState(() => _isFocused = focused),
      onShowHoverHighlight: (hovered) => setState(() => _isHovered = hovered),
      mouseCursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTapDown: widget.enabled
            ? (_) => setState(() => _isPressed = true)
            : null,
        onTapUp: widget.enabled
            ? (_) => setState(() => _isPressed = false)
            : null,
        onTapCancel: widget.enabled
            ? () => setState(() => _isPressed = false)
            : null,
        onTap: widget.enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 10 : 14,
            vertical: widget.compact ? 7 : 10,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: _isFocused ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: widget.compact ? 14 : 16,
                  color: isDisabled
                      ? AppColors.textSecondary.withValues(alpha: 0.5)
                      : effectiveColor,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: widget.compact ? 11.5 : 12.5,
                  fontWeight: FontWeight.w600,
                  color: isDisabled
                      ? AppColors.textSecondary.withValues(alpha: 0.5)
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
