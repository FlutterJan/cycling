// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../models/rider/rider.dart';

/// Dyscyplina kolarstwa szosowego na Igrzyskach Olimpijskich.
enum OlympicDiscipline {
  roadRace(
    polishLabel: 'Wyścig ze startu wspólnego',
    englishLabel: 'Olympic Road Race',
    maxNationalQuota: 4,
    raceRadioAllowed: false,
  ),
  individualTimeTrial(
    polishLabel: 'Jazda indywidualna na czas (ITT)',
    englishLabel: 'Olympic Individual Time Trial',
    maxNationalQuota: 2,
    raceRadioAllowed: false,
  );

  final String polishLabel;
  final String englishLabel;
  final int maxNationalQuota;
  final bool raceRadioAllowed;

  const OlympicDiscipline({
    required this.polishLabel,
    required this.englishLabel,
    required this.maxNationalQuota,
    required this.raceRadioAllowed,
  });

  String toJson() => name;

  static OlympicDiscipline fromJson(String value) {
    return OlympicDiscipline.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => OlympicDiscipline.roadRace,
    );
  }
}

/// Medal olimpijski przyznawany za miejsca 1–3.
enum OlympicMedalTier {
  gold(
    polishLabel: 'Złoty Medal',
    englishLabel: 'Gold Medal',
    rank: 1,
    uciBonusPoints: 600,
    prestigeScore: 100,
  ),
  silver(
    polishLabel: 'Srebrny Medal',
    englishLabel: 'Silver Medal',
    rank: 2,
    uciBonusPoints: 400,
    prestigeScore: 70,
  ),
  bronze(
    polishLabel: 'Brązowy Medal',
    englishLabel: 'Bronze Medal',
    rank: 3,
    uciBonusPoints: 300,
    prestigeScore: 50,
  );

  final String polishLabel;
  final String englishLabel;
  final int rank;
  final int uciBonusPoints;
  final int prestigeScore;

  const OlympicMedalTier({
    required this.polishLabel,
    required this.englishLabel,
    required this.rank,
    required this.uciBonusPoints,
    required this.prestigeScore,
  });

  String toJson() => name;

  static OlympicMedalTier fromJson(String value) {
    return OlympicMedalTier.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => OlympicMedalTier.bronze,
    );
  }
}

/// Faza 4-letniego cyklu olimpijskiego.
enum OlympicCyclePhase {
  offCycle('Okres międzyolimpijski'),
  qualificationWindow('Okno kwalifikacji narodowych'),
  olympicGamesWindow('Igrzyska Olimpijskie (Sierpień)'),
  reigningChampionCycle('Panowanie Mistrza Olimpijskiego');

  final String polishLabel;
  const OlympicCyclePhase(this.polishLabel);

  String toJson() => name;

  static OlympicCyclePhase fromJson(String value) {
    return OlympicCyclePhase.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => OlympicCyclePhase.offCycle,
    );
  }
}

/// Profil trasy olimpijskiej (płaska, klasyczna/pagórkowata, górska).
enum OlympicCourseTerrainProfile {
  flatSprint('Płaska / Sprinterska', 0.25, 0.75),
  classicsPunchy('Klasyczna / Pagórkowata (Montmartre)', 0.65, 0.45),
  mountainous('Górska / Wysokie Przełęcze', 0.90, 0.20);

  final String polishLabel;
  final double climbWeight;
  final double flatSprintWeight;

  const OlympicCourseTerrainProfile(
    this.polishLabel,
    this.climbWeight,
    this.flatSprintWeight,
  );

  String toJson() => name;

  static OlympicCourseTerrainProfile fromJson(String value) {
    return OlympicCourseTerrainProfile.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => OlympicCourseTerrainProfile.classicsPunchy,
    );
  }
}

/// Typ autonomicznej decyzji kolarza podczas wyścigu bez radia wyścigowego.
enum NoRaceRadioActionType {
  holdSteadyTempo('Utrzymuj stałe tempo grupy'),
  autonomousAttack('Autonomiczny atak z wyczucia'),
  bridgeToBreakaway('Przeskok do odjazdu'),
  waitForTeammate('Czekaj na kontakt wzrokowy z kolegą'),
  blindChaseEffort('Pogoń bez pełnych danych o stracie');

  final String polishLabel;
  const NoRaceRadioActionType(this.polishLabel);

  String toJson() => name;

  static NoRaceRadioActionType fromJson(String value) {
    return NoRaceRadioActionType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => NoRaceRadioActionType.holdSteadyTempo,
    );
  }
}

/// Specyfikacja edycji Igrzysk Olimpijskich w cyklu 4-letnim.
class OlympicHostEdition {
  final int year;
  final String hostCity;
  final String hostCountryIso;
  final String roadRaceCircuitName;
  final double roadRaceDistanceKm;
  final int roadRaceElevationGainM;
  final OlympicCourseTerrainProfile roadRaceTerrain;
  final double ittDistanceKm;
  final int ittElevationGainM;
  final DateTime roadRaceDate;
  final DateTime ittDate;

  const OlympicHostEdition({
    required this.year,
    required this.hostCity,
    required this.hostCountryIso,
    required this.roadRaceCircuitName,
    required this.roadRaceDistanceKm,
    required this.roadRaceElevationGainM,
    required this.roadRaceTerrain,
    required this.ittDistanceKm,
    required this.ittElevationGainM,
    required this.roadRaceDate,
    required this.ittDate,
  });

  Map<String, dynamic> toJson() => {
        'year': year,
        'hostCity': hostCity,
        'hostCountryIso': hostCountryIso,
        'roadRaceCircuitName': roadRaceCircuitName,
        'roadRaceDistanceKm': roadRaceDistanceKm,
        'roadRaceElevationGainM': roadRaceElevationGainM,
        'roadRaceTerrain': roadRaceTerrain.toJson(),
        'ittDistanceKm': ittDistanceKm,
        'ittElevationGainM': ittElevationGainM,
        'roadRaceDate': roadRaceDate.toIso8601String(),
        'ittDate': ittDate.toIso8601String(),
      };

  factory OlympicHostEdition.fromJson(Map<String, dynamic> json) {
    return OlympicHostEdition(
      year: (json['year'] as num).toInt(),
      hostCity: json['hostCity'] as String,
      hostCountryIso: json['hostCountryIso'] as String,
      roadRaceCircuitName: json['roadRaceCircuitName'] as String,
      roadRaceDistanceKm: (json['roadRaceDistanceKm'] as num).toDouble(),
      roadRaceElevationGainM: (json['roadRaceElevationGainM'] as num).toInt(),
      roadRaceTerrain: OlympicCourseTerrainProfile.fromJson(
        json['roadRaceTerrain'] as String? ?? 'classicsPunchy',
      ),
      ittDistanceKm: (json['ittDistanceKm'] as num).toDouble(),
      ittElevationGainM: (json['ittElevationGainM'] as num).toInt(),
      roadRaceDate: DateTime.parse(json['roadRaceDate'] as String),
      ittDate: DateTime.parse(json['ittDate'] as String),
    );
  }
}

/// Zasady wyścigu bez radia wyścigowego (No Race Radio) na Igrzyskach Olimpijskich.
class OlympicNoRaceRadioRules {
  final bool raceRadioEnabled;
  final bool canReceiveLiveTimeGaps;
  final bool canIssueInstantTacticalOrders;
  final int motoChalkboardDelaySeconds;
  final double visualContactRadiusMeters;
  final double breakawayChaosMultiplier;

  const OlympicNoRaceRadioRules({
    this.raceRadioEnabled = false,
    this.canReceiveLiveTimeGaps = false,
    this.canIssueInstantTacticalOrders = false,
    this.motoChalkboardDelaySeconds = 65,
    this.visualContactRadiusMeters = 35.0,
    this.breakawayChaosMultiplier = 1.35,
  });

  Map<String, dynamic> toJson() => {
        'raceRadioEnabled': raceRadioEnabled,
        'canReceiveLiveTimeGaps': canReceiveLiveTimeGaps,
        'canIssueInstantTacticalOrders': canIssueInstantTacticalOrders,
        'motoChalkboardDelaySeconds': motoChalkboardDelaySeconds,
        'visualContactRadiusMeters': visualContactRadiusMeters,
        'breakawayChaosMultiplier': breakawayChaosMultiplier,
      };

  factory OlympicNoRaceRadioRules.fromJson(Map<String, dynamic> json) {
    return OlympicNoRaceRadioRules(
      raceRadioEnabled: json['raceRadioEnabled'] as bool? ?? false,
      canReceiveLiveTimeGaps: json['canReceiveLiveTimeGaps'] as bool? ?? false,
      canIssueInstantTacticalOrders:
          json['canIssueInstantTacticalOrders'] as bool? ?? false,
      motoChalkboardDelaySeconds:
          (json['motoChalkboardDelaySeconds'] as num?)?.toInt() ?? 65,
      visualContactRadiusMeters:
          (json['visualContactRadiusMeters'] as num?)?.toDouble() ?? 35.0,
      breakawayChaosMultiplier:
          (json['breakawayChaosMultiplier'] as num?)?.toDouble() ?? 1.35,
    );
  }
}

/// Wynik autonomicznej decyzji kolarza podjętej bez radia wyścigowego.
class NoRaceRadioDecisionResult {
  final String riderId;
  final NoRaceRadioActionType action;
  final double tacticalAccuracy;
  final int perceivedGapSeconds;
  final int actualGapSeconds;
  final bool teammateInVisualContact;
  final String rationale;

  const NoRaceRadioDecisionResult({
    required this.riderId,
    required this.action,
    required this.tacticalAccuracy,
    required this.perceivedGapSeconds,
    required this.actualGapSeconds,
    required this.teammateInVisualContact,
    required this.rationale,
  });
}

/// Przydział kwot narodowych dla małych reprezentacji olimpijskich (max 4 RR / max 2 ITT).
class NationalOlympicQuotaRule {
  final String nationalityIso;
  final int nationUciRank;
  final int roadRaceQuota;
  final int ittQuota;

  const NationalOlympicQuotaRule({
    required this.nationalityIso,
    required this.nationUciRank,
    required this.roadRaceQuota,
    required this.ittQuota,
  });

  Map<String, dynamic> toJson() => {
        'nationalityIso': nationalityIso,
        'nationUciRank': nationUciRank,
        'roadRaceQuota': roadRaceQuota,
        'ittQuota': ittQuota,
      };

  factory NationalOlympicQuotaRule.fromJson(Map<String, dynamic> json) {
    return NationalOlympicQuotaRule(
      nationalityIso: json['nationalityIso'] as String,
      nationUciRank: (json['nationUciRank'] as num).toInt(),
      roadRaceQuota: (json['roadRaceQuota'] as num).toInt().clamp(1, 4),
      ittQuota: (json['ittQuota'] as num).toInt().clamp(1, 2),
    );
  }
}

/// Powołana mała reprezentacja narodowa na Igrzyska Olimpijskie.
class OlympicNationalTeamRoster {
  final int olympicYear;
  final String nationalityIso;
  final OlympicDiscipline discipline;
  final int maxAllowedQuota;
  final List<String> selectedRiderIds;
  final List<String> selectedRiderNames;
  final String? roadCaptainRiderId;

  const OlympicNationalTeamRoster({
    required this.olympicYear,
    required this.nationalityIso,
    required this.discipline,
    required this.maxAllowedQuota,
    required this.selectedRiderIds,
    required this.selectedRiderNames,
    required this.roadCaptainRiderId,
  });

  int get squadSize => selectedRiderIds.length;
  bool get isWithinOlympicLimit => squadSize <= maxAllowedQuota;

  Map<String, dynamic> toJson() => {
        'olympicYear': olympicYear,
        'nationalityIso': nationalityIso,
        'discipline': discipline.toJson(),
        'maxAllowedQuota': maxAllowedQuota,
        'selectedRiderIds': selectedRiderIds,
        'selectedRiderNames': selectedRiderNames,
        'roadCaptainRiderId': roadCaptainRiderId,
      };

  factory OlympicNationalTeamRoster.fromJson(Map<String, dynamic> json) {
    return OlympicNationalTeamRoster(
      olympicYear: (json['olympicYear'] as num).toInt(),
      nationalityIso: json['nationalityIso'] as String,
      discipline: OlympicDiscipline.fromJson(json['discipline'] as String),
      maxAllowedQuota: (json['maxAllowedQuota'] as num).toInt(),
      selectedRiderIds: (json['selectedRiderIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      selectedRiderNames: (json['selectedRiderNames'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      roadCaptainRiderId: json['roadCaptainRiderId'] as String?,
    );
  }
}

/// Złoty kask i złota rama mistrza olimpijskiego noszone przez cały 4-letni cykl.
class OlympicChampionGoldGear {
  final String riderId;
  final String riderName;
  final String nationalityIso;
  final OlympicDiscipline discipline;
  final int olympicYearWon;
  final int validUntilYear;
  final bool hasGoldHelmet;
  final bool hasGoldFrame;
  final bool hasGoldSleeveBands;
  final String helmetColorHex;
  final String frameColorHex;
  final int moraleBonus;
  final double sponsorMediaValueMultiplier;

  const OlympicChampionGoldGear({
    required this.riderId,
    required this.riderName,
    required this.nationalityIso,
    required this.discipline,
    required this.olympicYearWon,
    required this.validUntilYear,
    this.hasGoldHelmet = true,
    this.hasGoldFrame = true,
    this.hasGoldSleeveBands = true,
    this.helmetColorHex = '#D4AF37',
    this.frameColorHex = '#D4AF37',
    this.moraleBonus = 8,
    this.sponsorMediaValueMultiplier = 1.35,
  });

  bool isActiveInYear(int year) =>
      year >= olympicYearWon && year < validUntilYear;

  bool appliesToDiscipline(OlympicDiscipline raceDiscipline) =>
      discipline == raceDiscipline;

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'riderName': riderName,
        'nationalityIso': nationalityIso,
        'discipline': discipline.toJson(),
        'olympicYearWon': olympicYearWon,
        'validUntilYear': validUntilYear,
        'hasGoldHelmet': hasGoldHelmet,
        'hasGoldFrame': hasGoldFrame,
        'hasGoldSleeveBands': hasGoldSleeveBands,
        'helmetColorHex': helmetColorHex,
        'frameColorHex': frameColorHex,
        'moraleBonus': moraleBonus,
        'sponsorMediaValueMultiplier': sponsorMediaValueMultiplier,
      };

  factory OlympicChampionGoldGear.fromJson(Map<String, dynamic> json) {
    return OlympicChampionGoldGear(
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      nationalityIso: json['nationalityIso'] as String,
      discipline: OlympicDiscipline.fromJson(json['discipline'] as String),
      olympicYearWon: (json['olympicYearWon'] as num).toInt(),
      validUntilYear: (json['validUntilYear'] as num).toInt(),
      hasGoldHelmet: json['hasGoldHelmet'] as bool? ?? true,
      hasGoldFrame: json['hasGoldFrame'] as bool? ?? true,
      hasGoldSleeveBands: json['hasGoldSleeveBands'] as bool? ?? true,
      helmetColorHex: json['helmetColorHex'] as String? ?? '#D4AF37',
      frameColorHex: json['frameColorHex'] as String? ?? '#D4AF37',
      moraleBonus: (json['moraleBonus'] as num?)?.toInt() ?? 8,
      sponsorMediaValueMultiplier:
          (json['sponsorMediaValueMultiplier'] as num?)?.toDouble() ?? 1.35,
    );
  }
}

/// Zbiorczy wygląd sprzętu kolarza w wyścigu (uwzględnia Złoty Kask i Złotą Ramę).
class OlympicEquipmentAppearance {
  final bool usesGoldHelmet;
  final bool usesGoldFrame;
  final bool usesGoldSleeveBands;
  final String helmetHex;
  final String frameHex;
  final String badgeLabel;

  const OlympicEquipmentAppearance({
    required this.usesGoldHelmet,
    required this.usesGoldFrame,
    required this.usesGoldSleeveBands,
    required this.helmetHex,
    required this.frameHex,
    required this.badgeLabel,
  });

  static const OlympicEquipmentAppearance standard = OlympicEquipmentAppearance(
    usesGoldHelmet: false,
    usesGoldFrame: false,
    usesGoldSleeveBands: false,
    helmetHex: '#181B22',
    frameHex: '#222630',
    badgeLabel: '',
  );
}

/// Pojedynczy wynik kolarza na mecie wyścigu olimpijskiego.
class OlympicRaceResultEntry {
  final int rank;
  final String riderId;
  final String riderName;
  final String nationalityIso;
  final Duration finishTime;
  final Duration gapToWinner;
  final OlympicMedalTier? medal;
  final int uciPointsAwarded;
  final double averageSpeedKmh;

  const OlympicRaceResultEntry({
    required this.rank,
    required this.riderId,
    required this.riderName,
    required this.nationalityIso,
    required this.finishTime,
    required this.gapToWinner,
    required this.medal,
    required this.uciPointsAwarded,
    required this.averageSpeedKmh,
  });

  Map<String, dynamic> toJson() => {
        'rank': rank,
        'riderId': riderId,
        'riderName': riderName,
        'nationalityIso': nationalityIso,
        'finishTimeSeconds': finishTime.inSeconds,
        'gapToWinnerSeconds': gapToWinner.inSeconds,
        'medal': medal?.toJson(),
        'uciPointsAwarded': uciPointsAwarded,
        'averageSpeedKmh': averageSpeedKmh,
      };

  factory OlympicRaceResultEntry.fromJson(Map<String, dynamic> json) {
    final medalStr = json['medal'] as String?;
    return OlympicRaceResultEntry(
      rank: (json['rank'] as num).toInt(),
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      nationalityIso: json['nationalityIso'] as String,
      finishTime: Duration(seconds: (json['finishTimeSeconds'] as num).toInt()),
      gapToWinner:
          Duration(seconds: (json['gapToWinnerSeconds'] as num).toInt()),
      medal: medalStr == null ? null : OlympicMedalTier.fromJson(medalStr),
      uciPointsAwarded: (json['uciPointsAwarded'] as num).toInt(),
      averageSpeedKmh: (json['averageSpeedKmh'] as num).toDouble(),
    );
  }
}

/// Pełny raport z rozegranego wyścigu olimpijskiego.
class OlympicRaceSimulationReport {
  final OlympicHostEdition edition;
  final OlympicDiscipline discipline;
  final OlympicNoRaceRadioRules noRadioRules;
  final List<OlympicNationalTeamRoster> nationalRosters;
  final List<OlympicRaceResultEntry> standings;
  final OlympicChampionGoldGear? awardedGoldGear;
  final DateTime simulatedAt;

  const OlympicRaceSimulationReport({
    required this.edition,
    required this.discipline,
    required this.noRadioRules,
    required this.nationalRosters,
    required this.standings,
    required this.awardedGoldGear,
    required this.simulatedAt,
  });

  OlympicRaceResultEntry? get goldMedalist =>
      standings.isNotEmpty ? standings.first : null;

  OlympicRaceResultEntry? get silverMedalist =>
      standings.length >= 2 ? standings[1] : null;

  OlympicRaceResultEntry? get bronzeMedalist =>
      standings.length >= 3 ? standings[2] : null;

  Map<String, dynamic> toJson() => {
        'edition': edition.toJson(),
        'discipline': discipline.toJson(),
        'noRadioRules': noRadioRules.toJson(),
        'nationalRosters': nationalRosters.map((e) => e.toJson()).toList(),
        'standings': standings.map((e) => e.toJson()).toList(),
        'awardedGoldGear': awardedGoldGear?.toJson(),
        'simulatedAt': simulatedAt.toIso8601String(),
      };

  factory OlympicRaceSimulationReport.fromJson(Map<String, dynamic> json) {
    final goldGearJson = json['awardedGoldGear'] as Map<String, dynamic>?;
    return OlympicRaceSimulationReport(
      edition:
          OlympicHostEdition.fromJson(json['edition'] as Map<String, dynamic>),
      discipline: OlympicDiscipline.fromJson(json['discipline'] as String),
      noRadioRules: OlympicNoRaceRadioRules.fromJson(
          json['noRadioRules'] as Map<String, dynamic>),
      nationalRosters: (json['nationalRosters'] as List<dynamic>)
          .map((e) =>
              OlympicNationalTeamRoster.fromJson(e as Map<String, dynamic>))
          .toList(),
      standings: (json['standings'] as List<dynamic>)
          .map(
              (e) => OlympicRaceResultEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      awardedGoldGear: goldGearJson == null
          ? null
          : OlympicChampionGoldGear.fromJson(goldGearJson),
      simulatedAt: DateTime.parse(json['simulatedAt'] as String),
    );
  }
}

/// Serwis zarządzający 4-letnim Cyklem Igrzysk Olimpijskich w kolarstwie szosowym:
/// - kalendarz czteroletni (2024, 2028, 2032, ...),
/// - zasady braku radia wyścigowego (No Race Radio),
/// - małe reprezentacje narodowe (max 4 RR / max 2 ITT),
/// - przyznawanie i noszenie Złotego Kasku i Złotej Ramy Mistrza Olimpijskiego.
class OlympicGamesQuadrennialCycleService {
  static const int cycleLengthYears = 4;
  static const int baseOlympicYear = 2024;

  final List<OlympicChampionGoldGear> _goldGearRegistry = [];
  final List<OlympicRaceSimulationReport> _history = [];

  OlympicGamesQuadrennialCycleService({
    List<OlympicChampionGoldGear>? initialGoldGear,
    List<OlympicRaceSimulationReport>? initialHistory,
  }) {
    if (initialGoldGear != null) {
      _goldGearRegistry.addAll(initialGoldGear);
    }
    if (initialHistory != null) {
      _history.addAll(initialHistory);
    }
  }

  List<OlympicChampionGoldGear> get goldGearRegistry =>
      List.unmodifiable(_goldGearRegistry);

  List<OlympicRaceSimulationReport> get simulationHistory =>
      List.unmodifiable(_history);

  /// Sprawdza czy dany rok jest rokiem Igrzysk Olimpijskich (cykl 4-letni).
  bool isOlympicYear(int year) => year >= 1896 && year % cycleLengthYears == 0;

  /// Zwraca najbliższy rok olimpijski (bieżący jeśli olimpijski lub kolejny).
  int nextOlympicYear(int fromYear) {
    if (isOlympicYear(fromYear)) return fromYear;
    final remainder = fromYear % cycleLengthYears;
    return fromYear + (cycleLengthYears - remainder);
  }

  /// Liczba lat pozostałych do najbliższych Igrzysk Olimpijskich.
  int yearsUntilNextOlympics(int fromYear) =>
      nextOlympicYear(fromYear) - fromYear;

  /// Określa fazę 4-letniego cyklu olimpijskiego dla podanej daty.
  OlympicCyclePhase evaluateCyclePhase(DateTime currentDate) {
    if (isOlympicYear(currentDate.year)) {
      if (currentDate.month == 8) {
        return OlympicCyclePhase.olympicGamesWindow;
      }
      if (currentDate.month < 8) {
        return OlympicCyclePhase.qualificationWindow;
      }
      return OlympicCyclePhase.reigningChampionCycle;
    }
    if (yearsUntilNextOlympics(currentDate.year) == 1 &&
        currentDate.month >= 9) {
      return OlympicCyclePhase.qualificationWindow;
    }
    return _goldGearRegistry.any((g) => g.isActiveInYear(currentDate.year))
        ? OlympicCyclePhase.reigningChampionCycle
        : OlympicCyclePhase.offCycle;
  }

  /// Zwraca pełną specyfikację gospodarza Igrzysk dla wybranego roku olimpijskiego.
  OlympicHostEdition getEditionForYear(int year) {
    final olympicYear = isOlympicYear(year) ? year : nextOlympicYear(year);
    switch (olympicYear) {
      case 2024:
        return OlympicHostEdition(
          year: 2024,
          hostCity: 'Paryż',
          hostCountryIso: 'FRA',
          roadRaceCircuitName: 'Trocadéro – Butte Montmartre',
          roadRaceDistanceKm: 273.0,
          roadRaceElevationGainM: 2800,
          roadRaceTerrain: OlympicCourseTerrainProfile.classicsPunchy,
          ittDistanceKm: 32.4,
          ittElevationGainM: 150,
          roadRaceDate: DateTime(2024, 8, 3),
          ittDate: DateTime(2024, 7, 27),
        );
      case 2028:
        return OlympicHostEdition(
          year: 2028,
          hostCity: 'Los Angeles',
          hostCountryIso: 'USA',
          roadRaceCircuitName: 'Santa Monica – Mulholland Drive',
          roadRaceDistanceKm: 262.0,
          roadRaceElevationGainM: 3450,
          roadRaceTerrain: OlympicCourseTerrainProfile.mountainous,
          ittDistanceKm: 38.0,
          ittElevationGainM: 280,
          roadRaceDate: DateTime(2028, 8, 5),
          ittDate: DateTime(2028, 7, 29),
        );
      case 2032:
        return OlympicHostEdition(
          year: 2032,
          hostCity: 'Brisbane',
          hostCountryIso: 'AUS',
          roadRaceCircuitName: 'Mount Coot-tha Olympic Loop',
          roadRaceDistanceKm: 254.0,
          roadRaceElevationGainM: 2400,
          roadRaceTerrain: OlympicCourseTerrainProfile.classicsPunchy,
          ittDistanceKm: 35.5,
          ittElevationGainM: 210,
          roadRaceDate: DateTime(2032, 8, 7),
          ittDate: DateTime(2032, 7, 31),
        );
      default:
        final rotation = _proceduralHostRotation(olympicYear);
        return rotation;
    }
  }

  OlympicHostEdition _proceduralHostRotation(int olympicYear) {
    const presets = [
      (
        'Mediolan',
        'ITA',
        'Ghisallo – Como Circuit',
        266.0,
        3600,
        OlympicCourseTerrainProfile.mountainous,
      ),
      (
        'Tokio',
        'JPN',
        'Fuji International Speedway',
        244.0,
        4200,
        OlympicCourseTerrainProfile.mountainous,
      ),
      (
        'Madryt',
        'ESP',
        'Sierra de Guadarrama Loop',
        258.0,
        2900,
        OlympicCourseTerrainProfile.classicsPunchy,
      ),
      (
        'Kopenhaga',
        'DEN',
        'Zealand Coastal Wind Circuit',
        248.0,
        1150,
        OlympicCourseTerrainProfile.flatSprint,
      ),
    ];
    final idx =
        ((olympicYear - baseOlympicYear) ~/ cycleLengthYears).abs() %
            presets.length;
    final p = presets[idx];
    return OlympicHostEdition(
      year: olympicYear,
      hostCity: p.$1,
      hostCountryIso: p.$2,
      roadRaceCircuitName: p.$3,
      roadRaceDistanceKm: p.$4,
      roadRaceElevationGainM: p.$5,
      roadRaceTerrain: p.$6,
      ittDistanceKm: 36.0,
      ittElevationGainM: 220,
      roadRaceDate: DateTime(olympicYear, 8, 4),
      ittDate: DateTime(olympicYear, 7, 28),
    );
  }

  /// Zasady komunikacji bez radia wyścigowego dla danej dyscypliny olimpijskiej.
  OlympicNoRaceRadioRules getNoRaceRadioRules(OlympicDiscipline discipline) {
    return OlympicNoRaceRadioRules(
      raceRadioEnabled: false,
      canReceiveLiveTimeGaps: false,
      canIssueInstantTacticalOrders: false,
      motoChalkboardDelaySeconds:
          discipline == OlympicDiscipline.roadRace ? 65 : 45,
      visualContactRadiusMeters:
          discipline == OlympicDiscipline.roadRace ? 35.0 : 0.0,
      breakawayChaosMultiplier:
          discipline == OlympicDiscipline.roadRace ? 1.35 : 1.0,
    );
  }

  /// Wylicza kwotę startową kraju zgodnie z zasadami małych reprezentacji olimpijskich.
  NationalOlympicQuotaRule computeNationalQuota({
    required String nationalityIso,
    required int nationUciRank,
  }) {
    final safeRank = nationUciRank < 1 ? 1 : nationUciRank;
    final int roadQuota;
    if (safeRank <= 5) {
      roadQuota = 4;
    } else if (safeRank <= 15) {
      roadQuota = 3;
    } else if (safeRank <= 30) {
      roadQuota = 2;
    } else {
      roadQuota = 1;
    }
    final int ittQuota = safeRank <= 12 ? 2 : 1;

    return NationalOlympicQuotaRule(
      nationalityIso: nationalityIso.toUpperCase(),
      nationUciRank: safeRank,
      roadRaceQuota: roadQuota,
      ittQuota: ittQuota,
    );
  }

  /// Buduje małą reprezentację narodową z puli kolarzy danego kraju,
  /// ściśle respektując limit miejsc (max 4 RR / max 2 ITT).
  OlympicNationalTeamRoster buildNationalTeamRoster({
    required int olympicYear,
    required String nationalityIso,
    required OlympicDiscipline discipline,
    required List<Rider> worldRiders,
    required int nationUciRank,
    OlympicCourseTerrainProfile? terrainProfile,
  }) {
    final iso = nationalityIso.toUpperCase();
    final quotaRule = computeNationalQuota(
      nationalityIso: iso,
      nationUciRank: nationUciRank,
    );
    final maxSlots = discipline == OlympicDiscipline.roadRace
        ? quotaRule.roadRaceQuota
        : quotaRule.ittQuota;

    final edition = getEditionForYear(olympicYear);
    final effectiveTerrain = terrainProfile ?? edition.roadRaceTerrain;

    final eligible = worldRiders
        .where(
          (r) =>
              r.nationalityIso.toUpperCase() == iso && r.health.isFitToRace,
        )
        .toList();

    eligible.sort((a, b) {
      final scoreB = _scoreRiderForOlympicSelection(
        b,
        discipline,
        effectiveTerrain,
      );
      final scoreA = _scoreRiderForOlympicSelection(
        a,
        discipline,
        effectiveTerrain,
      );
      return scoreB.compareTo(scoreA);
    });

    final selected = eligible.take(maxSlots).toList();
    String? captainId;
    if (selected.isNotEmpty) {
      final byIq = [...selected]
        ..sort((a, b) => b.skills.raceIq.compareTo(a.skills.raceIq));
      captainId = byIq.first.id;
    }

    return OlympicNationalTeamRoster(
      olympicYear: olympicYear,
      nationalityIso: iso,
      discipline: discipline,
      maxAllowedQuota: maxSlots,
      selectedRiderIds: selected.map((r) => r.id).toList(),
      selectedRiderNames: selected.map((r) => r.fullName).toList(),
      roadCaptainRiderId: captainId,
    );
  }

  double _scoreRiderForOlympicSelection(
    Rider rider,
    OlympicDiscipline discipline,
    OlympicCourseTerrainProfile terrain,
  ) {
    final wPerKg = rider.physiology.wattsPerKg;
    final tsbBonus =
        (rider.health.trainingStressBalance * 0.25).clamp(-15.0, 15.0);
    final pointsBonus = math.min(25.0, rider.careerPointsUci / 120.0);

    if (discipline == OlympicDiscipline.individualTimeTrial) {
      return rider.skills.timeTrialPositioning * 0.85 +
          rider.skills.aeroPositioning * 0.65 +
          rider.physiology.ftpWatts * 0.14 +
          rider.powerProfile.watts20m * 0.08 +
          tsbBonus +
          pointsBonus;
    }

    final climbComponent =
        (wPerKg * 14.0 + rider.powerProfile.watts5m / rider.physiology.weightKg * 4.5) *
            terrain.climbWeight;
    final flatComponent =
        (rider.powerProfile.watts5s * 0.03 +
                rider.skills.draftingEfficiency * 0.5 +
                rider.skills.punch * 0.35) *
            terrain.flatSprintWeight;

    return climbComponent +
        flatComponent +
        rider.skills.raceIq * 0.35 +
        rider.skills.bikeHandling * 0.15 +
        tsbBonus +
        pointsBonus;
  }

  /// Ocenia autonomiczną decyzję kolarza w sytuacji wyścigowej bez radia (No Race Radio).
  NoRaceRadioDecisionResult evaluateNoRadioRiderDecision({
    required Rider rider,
    required int actualGapToBreakawaySeconds,
    required double distanceRemainingKm,
    required double nearestTeammateDistanceMeters,
    required int seed,
  }) {
    final rules = getNoRaceRadioRules(OlympicDiscipline.roadRace);
    final rng = math.Random(seed ^ rider.id.hashCode);

    // Kolarz o wysokim raceIq dokładniej szacuje stratę z tablicy motocykla.
    final iqFactor = (rider.skills.raceIq / 100.0).clamp(0.3, 1.0);
    final maxEstimationNoise = ((1.0 - iqFactor) * 45.0).round() + 5;
    final noise =
        rng.nextInt(maxEstimationNoise * 2 + 1) - maxEstimationNoise;
    final perceivedGap = math.max(0, actualGapToBreakawaySeconds + noise);

    final teammateVisible =
        nearestTeammateDistanceMeters <= rules.visualContactRadiusMeters;

    final NoRaceRadioActionType action;
    final String rationale;

    if (distanceRemainingKm <= 18.0 &&
        perceivedGap > 20 &&
        perceivedGap <= 75 &&
        iqFactor >= 0.72) {
      action = NoRaceRadioActionType.bridgeToBreakaway;
      rationale =
          'Kolarz ocenił tablicę moto (${perceivedGap}s) i samodzielnie przeskakuje do ucieczki.';
    } else if (distanceRemainingKm <= 12.0 &&
        perceivedGap <= 15 &&
        rider.skills.punch >= 78) {
      action = NoRaceRadioActionType.autonomousAttack;
      rationale =
          'Brak radia wymusza instynktowny atak w końcówce bez czekania na zgodę DS.';
    } else if (!teammateVisible &&
        distanceRemainingKm > 35.0 &&
        iqFactor < 0.65) {
      action = NoRaceRadioActionType.waitForTeammate;
      rationale =
          'Brak łączności i kontaktu wzrokowego z kadrą — kolarz zwalnia w oczekiwaniu na kolegę.';
    } else if (perceivedGap > 180 && distanceRemainingKm <= 45.0) {
      action = NoRaceRadioActionType.blindChaseEffort;
      rationale =
          'Opóźniona tablica sędziowska (${rules.motoChalkboardDelaySeconds}s) wymusza mocną pogoń w ciemno.';
    } else {
      action = NoRaceRadioActionType.holdSteadyTempo;
      rationale =
          'Stabilne tempo zgodne z odprawą przedstartową i kontrolą wzrokową grupy.';
    }

    final accuracy = (1.0 -
            (perceivedGap - actualGapToBreakawaySeconds).abs() /
                math.max(60.0, actualGapToBreakawaySeconds.toDouble()))
        .clamp(0.35, 1.0);

    return NoRaceRadioDecisionResult(
      riderId: rider.id,
      action: action,
      tacticalAccuracy: double.parse(accuracy.toStringAsFixed(2)),
      perceivedGapSeconds: perceivedGap,
      actualGapSeconds: actualGapToBreakawaySeconds,
      teammateInVisualContact: teammateVisible,
      rationale: rationale,
    );
  }

  /// Symuluje wyścig olimpijski (RR lub ITT), wyłania medalistów i przyznaje
  /// Złoty Kask oraz Złotą Ramę na pełne 4 lata.
  OlympicRaceSimulationReport simulateOlympicRace({
    required int olympicYear,
    required OlympicDiscipline discipline,
    required List<Rider> worldRiders,
    Map<String, int>? nationUciRanks,
    int? seed,
  }) {
    final edition = getEditionForYear(olympicYear);
    final noRadioRules = getNoRaceRadioRules(discipline);

    if (worldRiders.isEmpty) {
      final emptyReport = OlympicRaceSimulationReport(
        edition: edition,
        discipline: discipline,
        noRadioRules: noRadioRules,
        nationalRosters: const [],
        standings: const [],
        awardedGoldGear: null,
        simulatedAt: DateTime.now(),
      );
      _history.add(emptyReport);
      return emptyReport;
    }

    // Grupowanie kolarzy po narodowości i powoływanie małych reprezentacji narodowych.
    final nations = worldRiders
        .map((r) => r.nationalityIso.toUpperCase())
        .toSet()
        .toList()
      ..sort();

    final rosters = <OlympicNationalTeamRoster>[];
    final participantIds = <String>{};
    final rosterByRiderId = <String, OlympicNationalTeamRoster>{};

    for (var i = 0; i < nations.length; i++) {
      final iso = nations[i];
      final rank = nationUciRanks?[iso] ?? (i + 1);
      final roster = buildNationalTeamRoster(
        olympicYear: edition.year,
        nationalityIso: iso,
        discipline: discipline,
        worldRiders: worldRiders,
        nationUciRank: rank,
        terrainProfile: edition.roadRaceTerrain,
      );
      if (roster.selectedRiderIds.isNotEmpty) {
        rosters.add(roster);
        for (final id in roster.selectedRiderIds) {
          participantIds.add(id);
          rosterByRiderId[id] = roster;
        }
      }
    }

    final participants =
        worldRiders.where((r) => participantIds.contains(r.id)).toList();

    final rng = math.Random(seed ?? (edition.year * 997 + discipline.index));
    final distanceKm = discipline == OlympicDiscipline.roadRace
        ? edition.roadRaceDistanceKm
        : edition.ittDistanceKm;

    final scored = <(Rider rider, double performanceScore)>[];
    for (final rider in participants) {
      final roster = rosterByRiderId[rider.id];
      final baseScore = _scoreRiderForOlympicSelection(
        rider,
        discipline,
        edition.roadRaceTerrain,
      );

      // Małe reprezentacje (1-4 kolarzy) dają ograniczoną premię wsparcia drużyny w RR.
      final supportBonus = discipline == OlympicDiscipline.roadRace
          ? ((roster?.squadSize ?? 1) - 1) * 2.2
          : 0.0;

      // Brak radia w RR zwiększa wariancję taktyczną, premiując wysokie raceIq.
      final iqStabilizer = (rider.skills.raceIq / 100.0) * 6.0;
      final chaosRange =
          discipline == OlympicDiscipline.roadRace ? 14.0 : 5.5;
      final chaosNoise =
          (rng.nextDouble() * 2.0 - 1.0) *
          chaosRange *
          noRadioRules.breakawayChaosMultiplier;

      scored.add((rider, baseScore + supportBonus + iqStabilizer + chaosNoise));
    }

    scored.sort((a, b) => b.$2.compareTo(a.$2));

    final bestScore = scored.isNotEmpty ? scored.first.$2 : 100.0;
    final baseSpeedKmh = discipline == OlympicDiscipline.roadRace ? 42.8 : 51.2;
    final winnerSeconds = ((distanceKm / baseSpeedKmh) * 3600.0).round();

    final standings = <OlympicRaceResultEntry>[];
    for (var i = 0; i < scored.length; i++) {
      final rider = scored[i].$1;
      final scoreDiff = math.max(0.0, bestScore - scored[i].$2);
      final gapSec = i == 0 ? 0 : (scoreDiff * 6.5).round() + i * 2;
      final totalSec = winnerSeconds + gapSec;
      final avgSpeed =
          totalSec > 0 ? distanceKm / (totalSec / 3600.0) : baseSpeedKmh;

      OlympicMedalTier? medal;
      int uciPoints = 0;
      if (i == 0) {
        medal = OlympicMedalTier.gold;
        uciPoints = OlympicMedalTier.gold.uciBonusPoints;
      } else if (i == 1) {
        medal = OlympicMedalTier.silver;
        uciPoints = OlympicMedalTier.silver.uciBonusPoints;
      } else if (i == 2) {
        medal = OlympicMedalTier.bronze;
        uciPoints = OlympicMedalTier.bronze.uciBonusPoints;
      } else if (i < 16) {
        uciPoints = math.max(10, 220 - i * 14);
      }

      standings.add(
        OlympicRaceResultEntry(
          rank: i + 1,
          riderId: rider.id,
          riderName: rider.fullName,
          nationalityIso: rider.nationalityIso.toUpperCase(),
          finishTime: Duration(seconds: totalSec),
          gapToWinner: Duration(seconds: gapSec),
          medal: medal,
          uciPointsAwarded: uciPoints,
          averageSpeedKmh: double.parse(avgSpeed.toStringAsFixed(2)),
        ),
      );
    }

    OlympicChampionGoldGear? awardedGear;
    if (standings.isNotEmpty) {
      final champion = standings.first;
      awardedGear = OlympicChampionGoldGear(
        riderId: champion.riderId,
        riderName: champion.riderName,
        nationalityIso: champion.nationalityIso,
        discipline: discipline,
        olympicYearWon: edition.year,
        validUntilYear: edition.year + cycleLengthYears,
      );
      _registerGoldGear(awardedGear);
    }

    final report = OlympicRaceSimulationReport(
      edition: edition,
      discipline: discipline,
      noRadioRules: noRadioRules,
      nationalRosters: rosters,
      standings: standings,
      awardedGoldGear: awardedGear,
      simulatedAt: DateTime.now(),
    );
    _history.add(report);
    return report;
  }

  void _registerGoldGear(OlympicChampionGoldGear gear) {
    _goldGearRegistry.removeWhere(
      (g) =>
          g.discipline == gear.discipline &&
          g.olympicYearWon == gear.olympicYearWon,
    );
    _goldGearRegistry.add(gear);
  }

  /// Zwraca aktywny pakiet Złotego Kasku i Ramy dla kolarza w danym roku (jeśli jest mistrzem).
  OlympicChampionGoldGear? getActiveGoldGearForRider(
    String riderId,
    int currentYear, {
    OlympicDiscipline? discipline,
  }) {
    for (final gear in _goldGearRegistry.reversed) {
      if (gear.riderId == riderId &&
          gear.isActiveInYear(currentYear) &&
          (discipline == null || gear.appliesToDiscipline(discipline))) {
        return gear;
      }
    }
    return null;
  }

  /// Rozwiązuje wygląd sprzętu kolarza (Złoty Kask + Złota Rama) w wyścigu 3D i profilu.
  OlympicEquipmentAppearance resolveEquipmentAppearanceForRace({
    required String riderId,
    required int currentYear,
    required OlympicDiscipline raceDiscipline,
  }) {
    final activeGear = getActiveGoldGearForRider(
      riderId,
      currentYear,
      discipline: raceDiscipline,
    );
    if (activeGear == null) {
      return OlympicEquipmentAppearance.standard;
    }
    return OlympicEquipmentAppearance(
      usesGoldHelmet: activeGear.hasGoldHelmet,
      usesGoldFrame: activeGear.hasGoldFrame,
      usesGoldSleeveBands: activeGear.hasGoldSleeveBands,
      helmetHex: activeGear.helmetColorHex,
      frameHex: activeGear.frameColorHex,
      badgeLabel:
          'Mistrz Olimpijski ${activeGear.olympicYearWon} (${activeGear.discipline.englishLabel})',
    );
  }

  Map<String, dynamic> toJson() => {
        'goldGearRegistry': _goldGearRegistry.map((e) => e.toJson()).toList(),
        'history': _history.map((e) => e.toJson()).toList(),
      };

  factory OlympicGamesQuadrennialCycleService.fromJson(
    Map<String, dynamic> json,
  ) {
    return OlympicGamesQuadrennialCycleService(
      initialGoldGear: (json['goldGearRegistry'] as List<dynamic>? ?? [])
          .map((e) =>
              OlympicChampionGoldGear.fromJson(e as Map<String, dynamic>))
          .toList(),
      initialHistory: (json['history'] as List<dynamic>? ?? [])
          .map((e) =>
              OlympicRaceSimulationReport.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Niezmienny stan cyklu olimpijskiego dla warstwy Riverpod i UI.
class OlympicGamesQuadrennialCycleState {
  final int currentYear;
  final OlympicDiscipline selectedDiscipline;
  final OlympicHostEdition activeEdition;
  final OlympicNoRaceRadioRules noRadioRules;
  final List<OlympicChampionGoldGear> activeChampions;
  final OlympicRaceSimulationReport? latestReport;
  final bool isSimulating;

  const OlympicGamesQuadrennialCycleState({
    required this.currentYear,
    required this.selectedDiscipline,
    required this.activeEdition,
    required this.noRadioRules,
    required this.activeChampions,
    required this.latestReport,
    this.isSimulating = false,
  });

  bool get isCurrentYearOlympic => currentYear % 4 == 0;

  OlympicGamesQuadrennialCycleState copyWith({
    int? currentYear,
    OlympicDiscipline? selectedDiscipline,
    OlympicHostEdition? activeEdition,
    OlympicNoRaceRadioRules? noRadioRules,
    List<OlympicChampionGoldGear>? activeChampions,
    OlympicRaceSimulationReport? latestReport,
    bool? isSimulating,
  }) {
    return OlympicGamesQuadrennialCycleState(
      currentYear: currentYear ?? this.currentYear,
      selectedDiscipline: selectedDiscipline ?? this.selectedDiscipline,
      activeEdition: activeEdition ?? this.activeEdition,
      noRadioRules: noRadioRules ?? this.noRadioRules,
      activeChampions: activeChampions ?? this.activeChampions,
      latestReport: latestReport ?? this.latestReport,
      isSimulating: isSimulating ?? this.isSimulating,
    );
  }
}

/// Kontroler Riverpod zarządzający 4-letnim cyklem olimpijskim.
class OlympicGamesQuadrennialCycleNotifier
    extends StateNotifier<OlympicGamesQuadrennialCycleState> {
  final OlympicGamesQuadrennialCycleService _service;

  OlympicGamesQuadrennialCycleNotifier({
    OlympicGamesQuadrennialCycleService? service,
    int initialYear = 2028,
  })  : _service = service ?? OlympicGamesQuadrennialCycleService(),
        super(
          OlympicGamesQuadrennialCycleState(
            currentYear: initialYear,
            selectedDiscipline: OlympicDiscipline.roadRace,
            activeEdition: (service ?? OlympicGamesQuadrennialCycleService())
                .getEditionForYear(initialYear),
            noRadioRules: (service ?? OlympicGamesQuadrennialCycleService())
                .getNoRaceRadioRules(OlympicDiscipline.roadRace),
            activeChampions: (service ?? OlympicGamesQuadrennialCycleService())
                .goldGearRegistry
                .where((g) => g.isActiveInYear(initialYear))
                .toList(),
            latestReport: null,
          ),
        );

  OlympicGamesQuadrennialCycleService get service => _service;

  void selectDiscipline(OlympicDiscipline discipline) {
    state = state.copyWith(
      selectedDiscipline: discipline,
      noRadioRules: _service.getNoRaceRadioRules(discipline),
    );
  }

  void setYear(int year) {
    state = state.copyWith(
      currentYear: year,
      activeEdition: _service.getEditionForYear(year),
      activeChampions: _service.goldGearRegistry
          .where((g) => g.isActiveInYear(year))
          .toList(),
    );
  }

  OlympicRaceSimulationReport? runOlympicSimulation(
    List<Rider> worldRiders, {
    Map<String, int>? nationUciRanks,
    int? seed,
  }) {
    if (!_service.isOlympicYear(state.currentYear) || worldRiders.isEmpty) {
      return null;
    }
    state = state.copyWith(isSimulating: true);
    final report = _service.simulateOlympicRace(
      olympicYear: state.currentYear,
      discipline: state.selectedDiscipline,
      worldRiders: worldRiders,
      nationUciRanks: nationUciRanks,
      seed: seed,
    );
    state = state.copyWith(
      isSimulating: false,
      latestReport: report,
      activeChampions: _service.goldGearRegistry
          .where((g) => g.isActiveInYear(state.currentYear))
          .toList(),
    );
    return report;
  }
}

final olympicGamesQuadrennialCycleProvider = StateNotifierProvider<
    OlympicGamesQuadrennialCycleNotifier,
    OlympicGamesQuadrennialCycleState>((ref) {
  return OlympicGamesQuadrennialCycleNotifier();
});

/// Produkcyjny panel UI 4-letniego Cyklu Igrzysk Olimpijskich.
/// W pełni responsywny (`390x844`, `1024x768`, `1600x900`) z obsługą stanów
/// `hover`, `active`, `disabled`, `focus` i paletą `AppColors` + czcionką `Inter`.
class OlympicGamesQuadrennialCyclePanel extends StatefulWidget {
  final OlympicGamesQuadrennialCycleState state;
  final ValueChanged<OlympicDiscipline>? onSelectDiscipline;
  final VoidCallback? onSimulateRace;
  final bool isDisabled;

  const OlympicGamesQuadrennialCyclePanel({
    super.key,
    required this.state,
    this.onSelectDiscipline,
    this.onSimulateRace,
    this.isDisabled = false,
  });

  @override
  State<OlympicGamesQuadrennialCyclePanel> createState() =>
      _OlympicGamesQuadrennialCyclePanelState();
}

class _OlympicGamesQuadrennialCyclePanelState
    extends State<OlympicGamesQuadrennialCyclePanel> {
  bool _isSimulateHovered = false;
  bool _isSimulateFocused = false;
  bool _isSimulatePressed = false;
  String? _selectedNationFilter;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 680;
        final isWide = constraints.maxWidth >= 1100;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 1),
          ),
          padding: EdgeInsets.all(isCompact ? 14 : 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(isCompact),
                const SizedBox(height: 16),
                _buildDisciplineSelector(isCompact),
                const SizedBox(height: 16),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: _buildNoRadioRulesCard()),
                      const SizedBox(width: 16),
                      Expanded(flex: 7, child: _buildGoldGearChampionsCard()),
                    ],
                  )
                else ...[
                  _buildNoRadioRulesCard(),
                  const SizedBox(height: 16),
                  _buildGoldGearChampionsCard(),
                ],
                const SizedBox(height: 16),
                _buildRosterAndResultsSection(isCompact),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isCompact) {
    final edition = widget.state.activeEdition;
    final canSimulate = !widget.isDisabled &&
        !widget.state.isSimulating &&
        widget.state.isCurrentYearOlympic &&
        widget.onSimulateRace != null;

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.goldAccent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.goldAccent.withValues(alpha: 0.45)),
      ),
      child: Text(
        widget.state.isCurrentYearOlympic
            ? 'ROK OLIMPIJSKI ${edition.year}'
            : 'NASTĘPNE IGRZYSKA: ${edition.year}',
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.goldAccent,
          letterSpacing: 0.4,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );

    final actionButton = _buildSimulateButton(canSimulate);

    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                badge,
                const SizedBox(height: 10),
                Text(
                  'Igrzyska Olimpijskie • ${edition.hostCity} ${edition.year}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${edition.roadRaceCircuitName} • ${edition.roadRaceDistanceKm.toStringAsFixed(0)} km / ${edition.roadRaceElevationGainM} m przewyższenia',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(width: double.infinity, child: actionButton),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      badge,
                      const SizedBox(height: 8),
                      Text(
                        'Igrzyska Olimpijskie • ${edition.hostCity} ${edition.year}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${edition.roadRaceCircuitName} • ${edition.roadRaceDistanceKm.toStringAsFixed(0)} km • ${edition.roadRaceElevationGainM} m',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                actionButton,
              ],
            ),
    );
  }

  Widget _buildSimulateButton(bool enabled) {
    final bgColor = !enabled
        ? AppColors.surfaceLight
        : _isSimulatePressed
            ? AppColors.goldAccent.withValues(alpha: 0.85)
            : _isSimulateHovered
                ? AppColors.goldAccent
                : AppColors.primaryAccent;

    final borderColor = !enabled
        ? AppColors.cardBorder
        : _isSimulateFocused
            ? AppColors.goldAccent
            : _isSimulateHovered
                ? AppColors.goldAccent
                : AppColors.primaryAccent;

    return FocusableActionDetector(
      enabled: enabled,
      onShowFocusHighlight: (focused) {
        if (mounted) setState(() => _isSimulateFocused = focused);
      },
      onShowHoverHighlight: (hovered) {
        if (mounted) setState(() => _isSimulateHovered = hovered);
      },
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _isSimulatePressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _isSimulatePressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _isSimulatePressed = false) : null,
        onTap: enabled ? widget.onSimulateRace : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: _isSimulateFocused ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.emoji_events_rounded,
                size: 18,
                color: !enabled
                    ? AppColors.textSecondary
                    : _isSimulateHovered
                        ? AppColors.background
                        : AppColors.textPrimary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.state.isSimulating
                      ? 'Symulacja...'
                      : 'Rozegraj Wyścig Olimpijski',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: !enabled
                        ? AppColors.textSecondary
                        : _isSimulateHovered
                            ? AppColors.background
                            : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDisciplineSelector(bool isCompact) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: OlympicDiscipline.values.map((discipline) {
        final selected = widget.state.selectedDiscipline == discipline;
        final enabled = !widget.isDisabled && widget.onSelectDiscipline != null;
        return _DisciplineChipButton(
          label: discipline.polishLabel,
          quotaText: 'Max ${discipline.maxNationalQuota} / kraj',
          selected: selected,
          enabled: enabled,
          onTap: enabled ? () => widget.onSelectDiscipline!(discipline) : null,
        );
      }).toList(),
    );
  }

  Widget _buildNoRadioRulesCard() {
    final rules = widget.state.noRadioRules;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.crimsonAlert.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.headset_off_rounded,
                  size: 18,
                  color: AppColors.crimsonAlert,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Wyścig bez radia wyścigowego',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildRuleRow(
            'Łączność słuchawkowa DS',
            rules.raceRadioEnabled ? 'Włączona' : 'ZABRONIONA',
            AppColors.crimsonAlert,
          ),
          const SizedBox(height: 8),
          _buildRuleRow(
            'Opóźnienie tablicy sędziowskiej',
            '${rules.motoChalkboardDelaySeconds} s',
            AppColors.amberWarning,
          ),
          const SizedBox(height: 8),
          _buildRuleRow(
            'Kontakt wzrokowy kadry',
            '${rules.visualContactRadiusMeters.toStringAsFixed(0)} m',
            AppColors.accentBlue,
          ),
          const SizedBox(height: 8),
          _buildRuleRow(
            'Mnożnik chaosu ucieczek',
            '${rules.breakawayChaosMultiplier.toStringAsFixed(2)}x',
            AppColors.goldAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildRuleRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: valueColor,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _buildGoldGearChampionsCard() {
    final champions = widget.state.activeChampions;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.goldAccent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  size: 18,
                  color: AppColors.goldAccent,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Złoty Kask i Rama Mistrza Olimpijskiego (4 lata)',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (champions.isEmpty)
            const Text(
              'Brak aktywnego mistrza olimpijskiego w bieżącym cyklu. Rozegraj wyścig, aby przyznać złoty kask i złotą ramę na 4 sezony.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            )
          else
            ...champions.map(
              (gear) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.goldAccent.withValues(alpha: 0.45),
                  ),
                ),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.military_tech_rounded,
                          color: AppColors.goldAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${gear.riderName} (${gear.nationalityIso})',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${gear.discipline.polishLabel} • ${gear.olympicYearWon}–${gear.validUntilYear}',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.goldAccent.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '+${gear.moraleBonus} Morale • ${gear.sponsorMediaValueMultiplier}x Media',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.goldAccent,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRosterAndResultsSection(bool isCompact) {
    final report = widget.state.latestReport;
    if (report == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder, width: 1),
        ),
        child: const Text(
          'Małe reprezentacje narodowe (max 4 kolarzy w starcie wspólnym, max 2 w ITT) oraz wyniki medalowe pojawią się po rozegraniu wyścigu olimpijskiego.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    final filteredStandings = _selectedNationFilter == null
        ? report.standings.take(8).toList()
        : report.standings
            .where((s) => s.nationalityIso == _selectedNationFilter)
            .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Małe Reprezentacje Narodowe i Wyniki Olimpijskie',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _NationFilterPill(
                label: 'Wszystkie (${report.standings.length})',
                selected: _selectedNationFilter == null,
                onTap: () => setState(() => _selectedNationFilter = null),
              ),
              ...report.nationalRosters.take(8).map(
                    (r) => _NationFilterPill(
                      label: '${r.nationalityIso} (${r.squadSize}/${r.maxAllowedQuota})',
                      selected: _selectedNationFilter == r.nationalityIso,
                      onTap: () => setState(
                        () => _selectedNationFilter = r.nationalityIso,
                      ),
                    ),
                  ),
            ],
          ),
          const SizedBox(height: 12),
          ...filteredStandings.map((entry) {
            final isGold = entry.medal == OlympicMedalTier.gold;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 10 : 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isGold
                    ? AppColors.goldAccent.withValues(alpha: 0.10)
                    : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isGold
                      ? AppColors.goldAccent.withValues(alpha: 0.5)
                      : AppColors.cardBorder,
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      '#${entry.rank}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isGold
                            ? AppColors.goldAccent
                            : AppColors.textSecondary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${entry.riderName} (${entry.nationalityIso})',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    entry.gapToWinner.inSeconds == 0
                        ? _formatDuration(entry.finishTime)
                        : '+${_formatDuration(entry.gapToWinner)}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final mins = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$mins:$secs';
    }
    return '$mins:$secs';
  }
}

class _DisciplineChipButton extends StatefulWidget {
  final String label;
  final String quotaText;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  const _DisciplineChipButton({
    required this.label,
    required this.quotaText,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_DisciplineChipButton> createState() => _DisciplineChipButtonState();
}

class _DisciplineChipButtonState extends State<_DisciplineChipButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bg = !widget.enabled
        ? AppColors.surface
        : widget.selected
            ? AppColors.primaryAccent.withValues(alpha: 0.22)
            : _hovered
                ? AppColors.surfaceLight
                : AppColors.surface;

    final border = !widget.enabled
        ? AppColors.cardBorder
        : _focused
            ? AppColors.goldAccent
            : widget.selected
                ? AppColors.goldAccent
                : _hovered
                    ? AppColors.textSecondary
                    : AppColors.cardBorder;

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowFocusHighlight: (f) => setState(() => _focused = f),
      onShowHoverHighlight: (h) => setState(() => _hovered = h),
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: _focused ? 2 : 1),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: !widget.enabled
                      ? AppColors.textSecondary
                      : widget.selected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.quotaText,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.goldAccent,
                    fontFeatures: [FontFeature.tabularFigures()],
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

class _NationFilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NationFilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.goldAccent.withValues(alpha: 0.16)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.goldAccent : AppColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.goldAccent : AppColors.textSecondary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}
