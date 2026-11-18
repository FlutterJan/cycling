// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/rider/rider.dart';
import '../../models/rider/rider_contract.dart';
import '../generators/rider_procedural_generator.dart';

/// Region świata, z którego wywodzi się 17-letni talent zaproszony na Combine.
enum CombineRegion {
  westernEurope,
  centralEasternEurope,
  nordicsAndBaltics,
  latinAmerica,
  northAmerica,
  africaAndMiddleEast,
  asiaPacific;

  String toJson() => name;

  static CombineRegion fromJson(String value) {
    return CombineRegion.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CombineRegion.westernEurope,
    );
  }

  String get label {
    switch (this) {
      case CombineRegion.westernEurope:
        return 'Europa Zachodnia';
      case CombineRegion.centralEasternEurope:
        return 'Europa Śr.-Wsch.';
      case CombineRegion.nordicsAndBaltics:
        return 'Skandynawia';
      case CombineRegion.latinAmerica:
        return 'Ameryka Łacińska';
      case CombineRegion.northAmerica:
        return 'Ameryka Płn.';
      case CombineRegion.africaAndMiddleEast:
        return 'Afryka & Bliski Wschód';
      case CombineRegion.asiaPacific:
        return 'Azja & Pacyfik';
    }
  }

  List<String> get countryIsos {
    switch (this) {
      case CombineRegion.westernEurope:
        return const ['FRA', 'BEL', 'NED', 'ITA', 'ESP', 'GBR', 'GER', 'SUI', 'POR', 'IRL'];
      case CombineRegion.centralEasternEurope:
        return const ['POL', 'SLO', 'CZE', 'SVK', 'AUT'];
      case CombineRegion.nordicsAndBaltics:
        return const ['DEN', 'NOR'];
      case CombineRegion.latinAmerica:
        return const ['COL', 'ECU'];
      case CombineRegion.northAmerica:
        return const ['USA'];
      case CombineRegion.africaAndMiddleEast:
        return const ['ERI', 'RSA'];
      case CombineRegion.asiaPacific:
        return const ['AUS', 'NZL', 'KAZ'];
    }
  }

  static CombineRegion fromNationalityIso(String iso) {
    final upper = iso.toUpperCase();
    for (final region in CombineRegion.values) {
      if (region.countryIsos.contains(upper)) {
        return region;
      }
    }
    return CombineRegion.westernEurope;
  }
}

/// Lokalizacja corocznego obozu selekcyjnego Global Young Talent Combine.
enum CombineCampLocation {
  aigleUciWcc,
  gironaCatalonia,
  calpeAlicante,
  sierraNevadaAltitude,
  boulderColorado;

  String toJson() => name;

  static CombineCampLocation fromJson(String value) {
    return CombineCampLocation.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CombineCampLocation.aigleUciWcc,
    );
  }

  String get label {
    switch (this) {
      case CombineCampLocation.aigleUciWcc:
        return 'Aigle — UCI World Cycling Centre';
      case CombineCampLocation.gironaCatalonia:
        return 'Girona — Katalonia Pro Hub';
      case CombineCampLocation.calpeAlicante:
        return 'Calpe — Costa Blanca Lab';
      case CombineCampLocation.sierraNevadaAltitude:
        return 'Sierra Nevada — Centrum Wysokogórskie';
      case CombineCampLocation.boulderColorado:
        return 'Boulder — Rocky Mountains Lab';
    }
  }

  String get countryIso {
    switch (this) {
      case CombineCampLocation.aigleUciWcc:
        return 'SUI';
      case CombineCampLocation.gironaCatalonia:
      case CombineCampLocation.calpeAlicante:
      case CombineCampLocation.sierraNevadaAltitude:
        return 'ESP';
      case CombineCampLocation.boulderColorado:
        return 'USA';
    }
  }

  int get altitudeMeters {
    switch (this) {
      case CombineCampLocation.aigleUciWcc:
        return 415;
      case CombineCampLocation.gironaCatalonia:
        return 75;
      case CombineCampLocation.calpeAlicante:
        return 60;
      case CombineCampLocation.sierraNevadaAltitude:
        return 2320;
      case CombineCampLocation.boulderColorado:
        return 1655;
    }
  }

  int get organizationCostEur {
    switch (this) {
      case CombineCampLocation.aigleUciWcc:
        return 28000;
      case CombineCampLocation.gironaCatalonia:
        return 22000;
      case CombineCampLocation.calpeAlicante:
        return 18000;
      case CombineCampLocation.sierraNevadaAltitude:
        return 34000;
      case CombineCampLocation.boulderColorado:
        return 30000;
    }
  }

  String get description {
    switch (this) {
      case CombineCampLocation.aigleUciWcc:
        return 'Oficjalny ośrodek UCI z welodromem i pełnym laboratorium biomechanicznym.';
      case CombineCampLocation.gironaCatalonia:
        return 'Mekka zawodowego peletonu z technicznymi podjazdami Rocacorba i Els Àngels.';
      case CombineCampLocation.calpeAlicante:
        return 'Szybkie szosy wybrzeża i podjazd Coll de Rates do precyzyjnych testów W/kg.';
      case CombineCampLocation.sierraNevadaAltitude:
        return 'Testy hipoksji i reakcji hematologicznej na wysokości 2320 m n.p.m.';
      case CombineCampLocation.boulderColorado:
        return 'Amerykański kampus wytrzymałościowy łączący badania VO2max i długie podjazdy.';
    }
  }
}

/// Stacja testów laboratoryjnych i terenowych podczas Combine.
enum CombineTestStation {
  vo2MaxLabRamp,
  wattPerKgClimbTrial,
  peakSprintNeuromuscular,
  aeroCdAAndHandling;

  String toJson() => name;

  static CombineTestStation fromJson(String value) {
    return CombineTestStation.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CombineTestStation.vo2MaxLabRamp,
    );
  }

  String get label {
    switch (this) {
      case CombineTestStation.vo2MaxLabRamp:
        return 'Lab VO2max & Mleczan';
      case CombineTestStation.wattPerKgClimbTrial:
        return 'Próba Podjazdu W/kg';
      case CombineTestStation.peakSprintNeuromuscular:
        return 'Sprint & Moc Szczytowa';
      case CombineTestStation.aeroCdAAndHandling:
        return 'Aero CdA & Technika';
    }
  }

  String get shortLabel {
    switch (this) {
      case CombineTestStation.vo2MaxLabRamp:
        return 'VO2max';
      case CombineTestStation.wattPerKgClimbTrial:
        return 'W/kg 20m';
      case CombineTestStation.peakSprintNeuromuscular:
        return 'Sprint 5s';
      case CombineTestStation.aeroCdAAndHandling:
        return 'Aero/Tech';
    }
  }

  int get testFeeEur {
    switch (this) {
      case CombineTestStation.vo2MaxLabRamp:
        return 2500;
      case CombineTestStation.wattPerKgClimbTrial:
        return 1800;
      case CombineTestStation.peakSprintNeuromuscular:
        return 1500;
      case CombineTestStation.aeroCdAAndHandling:
        return 2200;
    }
  }
}

/// Klasa skautingowa 17-letniego adepta.
enum CombineProspectTier {
  generationalPhenom,
  blueChipProspect,
  solidAcademyFit,
  rawProject;

  String toJson() => name;

  static CombineProspectTier fromJson(String value) {
    return CombineProspectTier.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CombineProspectTier.solidAcademyFit,
    );
  }

  String get label {
    switch (this) {
      case CombineProspectTier.generationalPhenom:
        return 'Fenomen Pokolenia (5★)';
      case CombineProspectTier.blueChipProspect:
        return 'Elitarny Prospekt (4★)';
      case CombineProspectTier.solidAcademyFit:
        return 'Talent Akademii (3★)';
      case CombineProspectTier.rawProject:
        return 'Surowy Projekt (2★)';
    }
  }

  String get badgeShort {
    switch (this) {
      case CombineProspectTier.generationalPhenom:
        return '5★ PHENOM';
      case CombineProspectTier.blueChipProspect:
        return '4★ ELITE';
      case CombineProspectTier.solidAcademyFit:
        return '3★ ACADEMY';
      case CombineProspectTier.rawProject:
        return '2★ PROJECT';
    }
  }

  Color get accentColor {
    switch (this) {
      case CombineProspectTier.generationalPhenom:
        return AppColors.goldAccent;
      case CombineProspectTier.blueChipProspect:
        return AppColors.accentBlue;
      case CombineProspectTier.solidAcademyFit:
        return AppColors.statusSuccess;
      case CombineProspectTier.rawProject:
        return AppColors.textSecondary;
    }
  }
}

/// Status kandydata w trakcie obozu selekcyjnego.
enum CombineCandidateStatus {
  invited,
  tested,
  raced,
  shortlisted,
  signedToAcademy,
  signedToPro,
  passedOver;

  String toJson() => name;

  static CombineCandidateStatus fromJson(String value) {
    return CombineCandidateStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CombineCandidateStatus.invited,
    );
  }

  String get label {
    switch (this) {
      case CombineCandidateStatus.invited:
        return 'Zaproszony';
      case CombineCandidateStatus.tested:
        return 'Po testach lab';
      case CombineCandidateStatus.raced:
        return 'Po wyścigu';
      case CombineCandidateStatus.shortlisted:
        return 'Lista życzeń';
      case CombineCandidateStatus.signedToAcademy:
        return 'Podpisany (U19/U23)';
      case CombineCandidateStatus.signedToPro:
        return 'Podpisany (Pro)';
      case CombineCandidateStatus.passedOver:
        return 'Pominięty';
    }
  }

  bool get isSigned =>
      this == CombineCandidateStatus.signedToAcademy ||
      this == CombineCandidateStatus.signedToPro;
}

/// Faza aktualnej edycji obozu Global Young Talent Combine.
enum CombineCampPhase {
  notStarted,
  labTestingInProgress,
  selectionRaceCompleted,
  draftingWindowOpen,
  concluded;

  String toJson() => name;

  static CombineCampPhase fromJson(String value) {
    return CombineCampPhase.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CombineCampPhase.notStarted,
    );
  }

  String get label {
    switch (this) {
      case CombineCampPhase.notStarted:
        return 'Oczekuje na otwarcie';
      case CombineCampPhase.labTestingInProgress:
        return 'Testy Laboratoryjne';
      case CombineCampPhase.selectionRaceCompleted:
        return 'Po Wyścigu Selekcyjnym';
      case CombineCampPhase.draftingWindowOpen:
        return 'Okno Podpisywania Kontraktów';
      case CombineCampPhase.concluded:
        return 'Obóz Zakończony';
    }
  }
}

/// Kryterium sortowania listy 17-letnich talentów.
enum CombineSortField {
  combineScore,
  estimatedPotential,
  wattsPerKg,
  selectionRaceRank;

  String get label {
    switch (this) {
      case CombineSortField.combineScore:
        return 'Ocena Combine';
      case CombineSortField.estimatedPotential:
        return 'Potencjał';
      case CombineSortField.wattsPerKg:
        return 'W/kg (20 min)';
      case CombineSortField.selectionRaceRank:
        return 'Wynik Wyścigu';
    }
  }
}

/// Wynik pojedynczej stacji testowej w ramach Global Young Talent Combine.
class CombineLabTestResult {
  final CombineTestStation station;
  final double rawScore;
  final double measuredVo2Max;
  final double measuredFtpWatts;
  final double measuredWPerKg20m;
  final double measuredPeakSprintWatts;
  final double measuredLactateThresholdMmol;
  final double measuredVamMetersPerHour;
  final String scoutNote;
  final DateTime completedAt;

  const CombineLabTestResult({
    required this.station,
    required this.rawScore,
    required this.measuredVo2Max,
    required this.measuredFtpWatts,
    required this.measuredWPerKg20m,
    required this.measuredPeakSprintWatts,
    required this.measuredLactateThresholdMmol,
    required this.measuredVamMetersPerHour,
    required this.scoutNote,
    required this.completedAt,
  });

  Map<String, dynamic> toJson() => {
        'station': station.toJson(),
        'rawScore': rawScore,
        'measuredVo2Max': measuredVo2Max,
        'measuredFtpWatts': measuredFtpWatts,
        'measuredWPerKg20m': measuredWPerKg20m,
        'measuredPeakSprintWatts': measuredPeakSprintWatts,
        'measuredLactateThresholdMmol': measuredLactateThresholdMmol,
        'measuredVamMetersPerHour': measuredVamMetersPerHour,
        'scoutNote': scoutNote,
        'completedAt': completedAt.toIso8601String(),
      };

  factory CombineLabTestResult.fromJson(Map<String, dynamic> json) {
    return CombineLabTestResult(
      station: CombineTestStation.fromJson(json['station']?.toString() ?? ''),
      rawScore: (json['rawScore'] as num?)?.toDouble() ?? 0.0,
      measuredVo2Max: (json['measuredVo2Max'] as num?)?.toDouble() ?? 0.0,
      measuredFtpWatts: (json['measuredFtpWatts'] as num?)?.toDouble() ?? 0.0,
      measuredWPerKg20m: (json['measuredWPerKg20m'] as num?)?.toDouble() ?? 0.0,
      measuredPeakSprintWatts: (json['measuredPeakSprintWatts'] as num?)?.toDouble() ?? 0.0,
      measuredLactateThresholdMmol:
          (json['measuredLactateThresholdMmol'] as num?)?.toDouble() ?? 4.0,
      measuredVamMetersPerHour: (json['measuredVamMetersPerHour'] as num?)?.toDouble() ?? 0.0,
      scoutNote: json['scoutNote']?.toString() ?? '',
      completedAt: DateTime.tryParse(json['completedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

/// Wynik 85-kilometrowego wyścigu selekcyjnego juniorów podczas Combine.
class CombineSelectionRaceResult {
  final int rank;
  final int timeGapSeconds;
  final double avgPowerWatts;
  final double normalizedPowerWPerKg;
  final double breakawayKm;
  final int attackCount;
  final double raceIqScore;
  final List<String> highlights;

  const CombineSelectionRaceResult({
    required this.rank,
    required this.timeGapSeconds,
    required this.avgPowerWatts,
    required this.normalizedPowerWPerKg,
    required this.breakawayKm,
    required this.attackCount,
    required this.raceIqScore,
    required this.highlights,
  });

  String get formattedGap {
    if (rank == 1 || timeGapSeconds <= 0) return 'Zwycięzca';
    final mins = timeGapSeconds ~/ 60;
    final secs = timeGapSeconds % 60;
    if (mins == 0) return '+${secs}s';
    return '+${mins}m ${secs.toString().padLeft(2, '0')}s';
  }

  Map<String, dynamic> toJson() => {
        'rank': rank,
        'timeGapSeconds': timeGapSeconds,
        'avgPowerWatts': avgPowerWatts,
        'normalizedPowerWPerKg': normalizedPowerWPerKg,
        'breakawayKm': breakawayKm,
        'attackCount': attackCount,
        'raceIqScore': raceIqScore,
        'highlights': highlights,
      };

  factory CombineSelectionRaceResult.fromJson(Map<String, dynamic> json) {
    return CombineSelectionRaceResult(
      rank: (json['rank'] as num?)?.toInt() ?? 99,
      timeGapSeconds: (json['timeGapSeconds'] as num?)?.toInt() ?? 0,
      avgPowerWatts: (json['avgPowerWatts'] as num?)?.toDouble() ?? 0.0,
      normalizedPowerWPerKg: (json['normalizedPowerWPerKg'] as num?)?.toDouble() ?? 0.0,
      breakawayKm: (json['breakawayKm'] as num?)?.toDouble() ?? 0.0,
      attackCount: (json['attackCount'] as num?)?.toInt() ?? 0,
      raceIqScore: (json['raceIqScore'] as num?)?.toDouble() ?? 50.0,
      highlights: (json['highlights'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}

/// Profil 17-letniego kandydata na obozie Global Young Talent Combine.
class CombineTalentCandidate {
  final String id;
  final Rider rider;
  final CombineRegion region;
  final CombineProspectTier prospectTier;
  final CombineCandidateStatus status;
  final int hiddenTruePotential;
  final int estimatedPotentialMin;
  final int estimatedPotentialMax;
  final double combineCompositeScore;
  final Map<CombineTestStation, CombineLabTestResult> testedStations;
  final CombineSelectionRaceResult? raceResult;
  final int competingTeamsInterest;
  final int signingFeeEur;
  final String recommendedRoleNote;

  const CombineTalentCandidate({
    required this.id,
    required this.rider,
    required this.region,
    required this.prospectTier,
    required this.status,
    required this.hiddenTruePotential,
    required this.estimatedPotentialMin,
    required this.estimatedPotentialMax,
    required this.combineCompositeScore,
    required this.testedStations,
    this.raceResult,
    required this.competingTeamsInterest,
    required this.signingFeeEur,
    required this.recommendedRoleNote,
  });

  bool get isFullyLabTested =>
      testedStations.length >= CombineTestStation.values.length;

  bool get hasRaced => raceResult != null;

  int get potentialSpread => (estimatedPotentialMax - estimatedPotentialMin).abs();

  String get displayPotentialRange =>
      estimatedPotentialMin == estimatedPotentialMax
          ? '$estimatedPotentialMin'
          : '$estimatedPotentialMin–$estimatedPotentialMax';

  double get wPerKg20m {
    final w = rider.physiology.weightKg > 0 ? rider.physiology.weightKg : 66.0;
    return rider.powerProfile.watts20m / w;
  }

  CombineTalentCandidate copyWith({
    Rider? rider,
    CombineCandidateStatus? status,
    int? estimatedPotentialMin,
    int? estimatedPotentialMax,
    double? combineCompositeScore,
    Map<CombineTestStation, CombineLabTestResult>? testedStations,
    CombineSelectionRaceResult? raceResult,
    int? competingTeamsInterest,
    String? recommendedRoleNote,
  }) {
    return CombineTalentCandidate(
      id: id,
      rider: rider ?? this.rider,
      region: region,
      prospectTier: prospectTier,
      status: status ?? this.status,
      hiddenTruePotential: hiddenTruePotential,
      estimatedPotentialMin: estimatedPotentialMin ?? this.estimatedPotentialMin,
      estimatedPotentialMax: estimatedPotentialMax ?? this.estimatedPotentialMax,
      combineCompositeScore: combineCompositeScore ?? this.combineCompositeScore,
      testedStations: testedStations ?? this.testedStations,
      raceResult: raceResult ?? this.raceResult,
      competingTeamsInterest: competingTeamsInterest ?? this.competingTeamsInterest,
      signingFeeEur: signingFeeEur,
      recommendedRoleNote: recommendedRoleNote ?? this.recommendedRoleNote,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'rider': rider.toJson(),
        'region': region.toJson(),
        'prospectTier': prospectTier.toJson(),
        'status': status.toJson(),
        'hiddenTruePotential': hiddenTruePotential,
        'estimatedPotentialMin': estimatedPotentialMin,
        'estimatedPotentialMax': estimatedPotentialMax,
        'combineCompositeScore': combineCompositeScore,
        'testedStations': testedStations.map(
          (k, v) => MapEntry(k.toJson(), v.toJson()),
        ),
        'raceResult': raceResult?.toJson(),
        'competingTeamsInterest': competingTeamsInterest,
        'signingFeeEur': signingFeeEur,
        'recommendedRoleNote': recommendedRoleNote,
      };

  factory CombineTalentCandidate.fromJson(Map<String, dynamic> json) {
    final rawStations = json['testedStations'] as Map<String, dynamic>? ?? const {};
    final parsedStations = <CombineTestStation, CombineLabTestResult>{};
    for (final entry in rawStations.entries) {
      if (entry.value is Map<String, dynamic>) {
        parsedStations[CombineTestStation.fromJson(entry.key)] =
            CombineLabTestResult.fromJson(entry.value as Map<String, dynamic>);
      }
    }
    return CombineTalentCandidate(
      id: json['id']?.toString() ?? '',
      rider: Rider.fromJson(json['rider'] as Map<String, dynamic>),
      region: CombineRegion.fromJson(json['region']?.toString() ?? ''),
      prospectTier: CombineProspectTier.fromJson(json['prospectTier']?.toString() ?? ''),
      status: CombineCandidateStatus.fromJson(json['status']?.toString() ?? ''),
      hiddenTruePotential: (json['hiddenTruePotential'] as num?)?.toInt() ?? 80,
      estimatedPotentialMin: (json['estimatedPotentialMin'] as num?)?.toInt() ?? 70,
      estimatedPotentialMax: (json['estimatedPotentialMax'] as num?)?.toInt() ?? 90,
      combineCompositeScore: (json['combineCompositeScore'] as num?)?.toDouble() ?? 0.0,
      testedStations: parsedStations,
      raceResult: json['raceResult'] is Map<String, dynamic>
          ? CombineSelectionRaceResult.fromJson(
              json['raceResult'] as Map<String, dynamic>,
            )
          : null,
      competingTeamsInterest: (json['competingTeamsInterest'] as num?)?.toInt() ?? 1,
      signingFeeEur: (json['signingFeeEur'] as num?)?.toInt() ?? 15000,
      recommendedRoleNote: json['recommendedRoleNote']?.toString() ?? '',
    );
  }
}

/// Pełny stan corocznej edycji obozu Global Young Talent Combine.
class CombineCampEdition {
  final int seasonYear;
  final int month;
  final CombineCampLocation location;
  final CombineCampPhase phase;
  final int budgetSpentEur;
  final int maxSlotsToSign;
  final List<String> signedCandidateIds;
  final List<CombineTalentCandidate> candidates;
  final String campSummaryNote;

  const CombineCampEdition({
    required this.seasonYear,
    required this.month,
    required this.location,
    required this.phase,
    required this.budgetSpentEur,
    required this.maxSlotsToSign,
    required this.signedCandidateIds,
    required this.candidates,
    required this.campSummaryNote,
  });

  int get remainingSignSlots =>
      (maxSlotsToSign - signedCandidateIds.length).clamp(0, maxSlotsToSign);

  int get testedCandidatesCount =>
      candidates.where((c) => c.testedStations.isNotEmpty).length;

  int get fullyTestedCount =>
      candidates.where((c) => c.isFullyLabTested).length;

  bool get isSelectionRaceCompleted =>
      candidates.isNotEmpty && candidates.every((c) => c.hasRaced);

  CombineTalentCandidate? findCandidate(String id) {
    for (final c in candidates) {
      if (c.id == id) return c;
    }
    return null;
  }

  CombineCampEdition copyWith({
    CombineCampPhase? phase,
    int? budgetSpentEur,
    List<String>? signedCandidateIds,
    List<CombineTalentCandidate>? candidates,
    String? campSummaryNote,
  }) {
    return CombineCampEdition(
      seasonYear: seasonYear,
      month: month,
      location: location,
      phase: phase ?? this.phase,
      budgetSpentEur: budgetSpentEur ?? this.budgetSpentEur,
      maxSlotsToSign: maxSlotsToSign,
      signedCandidateIds: signedCandidateIds ?? this.signedCandidateIds,
      candidates: candidates ?? this.candidates,
      campSummaryNote: campSummaryNote ?? this.campSummaryNote,
    );
  }

  Map<String, dynamic> toJson() => {
        'seasonYear': seasonYear,
        'month': month,
        'location': location.toJson(),
        'phase': phase.toJson(),
        'budgetSpentEur': budgetSpentEur,
        'maxSlotsToSign': maxSlotsToSign,
        'signedCandidateIds': signedCandidateIds,
        'candidates': candidates.map((c) => c.toJson()).toList(),
        'campSummaryNote': campSummaryNote,
      };

  factory CombineCampEdition.fromJson(Map<String, dynamic> json) {
    return CombineCampEdition(
      seasonYear: (json['seasonYear'] as num?)?.toInt() ?? 2026,
      month: (json['month'] as num?)?.toInt() ?? 7,
      location: CombineCampLocation.fromJson(json['location']?.toString() ?? ''),
      phase: CombineCampPhase.fromJson(json['phase']?.toString() ?? ''),
      budgetSpentEur: (json['budgetSpentEur'] as num?)?.toInt() ?? 0,
      maxSlotsToSign: (json['maxSlotsToSign'] as num?)?.toInt() ?? 3,
      signedCandidateIds: (json['signedCandidateIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      candidates: (json['candidates'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(CombineTalentCandidate.fromJson)
              .toList() ??
          const [],
      campSummaryNote: json['campSummaryNote']?.toString() ?? '',
    );
  }
}

/// Wynik operacji wykonanej podczas obozu Combine.
class CombineActionOutcome {
  final bool success;
  final String message;
  final CombineCampEdition updatedEdition;
  final Rider? signedRider;
  final int costEur;

  const CombineActionOutcome({
    required this.success,
    required this.message,
    required this.updatedEdition,
    this.signedRider,
    this.costEur = 0,
  });
}

/// Archiwalny wpis zakończonej edycji Global Young Talent Combine.
class CombineCampHistoryEntry {
  final int seasonYear;
  final CombineCampLocation location;
  final int totalCandidates;
  final int signedCount;
  final String topProspectName;
  final double topCombineScore;

  const CombineCampHistoryEntry({
    required this.seasonYear,
    required this.location,
    required this.totalCandidates,
    required this.signedCount,
    required this.topProspectName,
    required this.topCombineScore,
  });

  Map<String, dynamic> toJson() => {
        'seasonYear': seasonYear,
        'location': location.toJson(),
        'totalCandidates': totalCandidates,
        'signedCount': signedCount,
        'topProspectName': topProspectName,
        'topCombineScore': topCombineScore,
      };

  factory CombineCampHistoryEntry.fromJson(Map<String, dynamic> json) {
    return CombineCampHistoryEntry(
      seasonYear: (json['seasonYear'] as num?)?.toInt() ?? 2026,
      location: CombineCampLocation.fromJson(json['location']?.toString() ?? ''),
      totalCandidates: (json['totalCandidates'] as num?)?.toInt() ?? 0,
      signedCount: (json['signedCount'] as num?)?.toInt() ?? 0,
      topProspectName: json['topProspectName']?.toString() ?? '',
      topCombineScore: (json['topCombineScore'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Serwis zarządzający corocznym obozem selekcyjnym 17-letnich talentów
/// (`Global Young Talent Combine`): generacją globalnej kohorty, testami
/// laboratoryjnymi, wyścigiem selekcyjnym oraz podpisywaniem kontraktów.
class YouthTalentSummerCombineCampService {
  const YouthTalentSummerCombineCampService();

  /// Rozpoczyna nową coroczną edycję obozu dla 17-letnich juniorów z całego świata.
  CombineCampEdition launchAnnualCombine({
    required int seasonYear,
    CombineCampLocation location = CombineCampLocation.aigleUciWcc,
    int candidateCount = 16,
    int maxSlotsToSign = 3,
    int month = 7,
    math.Random? random,
  }) {
    final rng = random ?? math.Random();
    final clampedCount = candidateCount.clamp(6, 32);
    final clampedSlots = maxSlotsToSign.clamp(1, 6);
    const regions = CombineRegion.values;
    final candidates = <CombineTalentCandidate>[];

    for (var i = 0; i < clampedCount; i++) {
      final region = regions[i % regions.length];
      final countries = region.countryIsos;
      final countryIso = countries[rng.nextInt(countries.length)];

      // Rozkład klas talentu: 1-2 fenomeny, 4-5 elitarni, reszta akademia/projekt
      final CombineProspectTier tier;
      final int targetOvr;
      final int truePotential;
      if (i == 0 || (i == 7 && clampedCount >= 12)) {
        tier = CombineProspectTier.generationalPhenom;
        targetOvr = 72 + rng.nextInt(5); // 72-76 już w wieku 17 lat
        truePotential = 93 + rng.nextInt(7); // 93-99
      } else if (i < 5) {
        tier = CombineProspectTier.blueChipProspect;
        targetOvr = 67 + rng.nextInt(5); // 67-71
        truePotential = 86 + rng.nextInt(7); // 86-92
      } else if (i < (clampedCount * 0.75).round()) {
        tier = CombineProspectTier.solidAcademyFit;
        targetOvr = 62 + rng.nextInt(5); // 62-66
        truePotential = 77 + rng.nextInt(9); // 77-85
      } else {
        tier = CombineProspectTier.rawProject;
        targetOvr = 58 + rng.nextInt(5); // 58-62
        truePotential = 69 + rng.nextInt(10); // 69-78
      }

      final baseRider = RiderProceduralGenerator.generateRider(
        id: 'combine_${seasonYear}_${i + 1}_${countryIso.toLowerCase()}',
        nationalityIso: countryIso,
        age: 17,
        targetOverallRating: targetOvr,
        teamId: 'combine_pool_$seasonYear',
        role: RiderRole.neoPro,
        random: rng,
      );

      final alignedBirthDate = DateTime(
        seasonYear - 17,
        1 + rng.nextInt(12),
        1 + rng.nextInt(28),
      );

      final juniorRider = Rider(
        id: baseRider.id,
        firstName: baseRider.firstName,
        lastName: baseRider.lastName,
        nationalityIso: baseRider.nationalityIso,
        birthDate: alignedBirthDate,
        potential: truePotential,
        specialization: baseRider.specialization,
        physiology: baseRider.physiology,
        powerProfile: baseRider.powerProfile,
        skills: baseRider.skills,
        appearance: baseRider.appearance,
        contract: baseRider.contract,
        health: baseRider.health,
        careerPointsUci: 0,
      );

      // Początkowa Mgła Wojny: szerokie widełki potencjału
      final fogMin = (truePotential - (7 + rng.nextInt(6))).clamp(50, 95);
      final fogMax = (truePotential + (6 + rng.nextInt(6))).clamp(fogMin + 2, 99);

      final interest = tier == CombineProspectTier.generationalPhenom
          ? 4 + rng.nextInt(2)
          : tier == CombineProspectTier.blueChipProspect
              ? 2 + rng.nextInt(3)
              : rng.nextInt(3);

      final signingFee = switch (tier) {
        CombineProspectTier.generationalPhenom => 45000 + rng.nextInt(20000),
        CombineProspectTier.blueChipProspect => 24000 + rng.nextInt(12000),
        CombineProspectTier.solidAcademyFit => 12000 + rng.nextInt(8000),
        CombineProspectTier.rawProject => 6000 + rng.nextInt(4000),
      };

      candidates.add(
        CombineTalentCandidate(
          id: juniorRider.id,
          rider: juniorRider,
          region: region,
          prospectTier: tier,
          status: CombineCandidateStatus.invited,
          hiddenTruePotential: truePotential,
          estimatedPotentialMin: fogMin,
          estimatedPotentialMax: fogMax,
          combineCompositeScore: 0.0,
          testedStations: const {},
          raceResult: null,
          competingTeamsInterest: interest,
          signingFeeEur: signingFee,
          recommendedRoleNote: _buildInitialRoleNote(juniorRider),
        ),
      );
    }

    // Lekkie przetasowanie kolejności początkowej, aby 5★ nie zawsze był na pozycji 0
    candidates.shuffle(rng);

    return CombineCampEdition(
      seasonYear: seasonYear,
      month: month.clamp(6, 9),
      location: location,
      phase: CombineCampPhase.labTestingInProgress,
      budgetSpentEur: location.organizationCostEur,
      maxSlotsToSign: clampedSlots,
      signedCandidateIds: const [],
      candidates: candidates,
      campSummaryNote:
          'Obóz Global Young Talent Combine $seasonYear otwarty w ${location.label}. '
          'Zaproszono $clampedCount 17-latków z całego świata.',
    );
  }

  /// Przeprowadza pojedynczą stację testową dla wskazanego juniora.
  CombineActionOutcome runLabTestStation({
    required CombineCampEdition edition,
    required String candidateId,
    required CombineTestStation station,
    int scoutSkill = 78,
    int availableBudgetEur = 1000000,
    math.Random? random,
  }) {
    if (edition.phase == CombineCampPhase.concluded) {
      return CombineActionOutcome(
        success: false,
        message: 'Edycja Combine ${edition.seasonYear} została już zakończona.',
        updatedEdition: edition,
      );
    }

    final candidate = edition.findCandidate(candidateId);
    if (candidate == null) {
      return CombineActionOutcome(
        success: false,
        message: 'Nie znaleziono kandydata o ID $candidateId.',
        updatedEdition: edition,
      );
    }

    if (candidate.testedStations.containsKey(station)) {
      return CombineActionOutcome(
        success: false,
        message:
            '${candidate.rider.fullName} ukończył już stację ${station.label}.',
        updatedEdition: edition,
      );
    }

    final fee = station.testFeeEur;
    if (availableBudgetEur < fee) {
      return CombineActionOutcome(
        success: false,
        message: 'Niewystarczający budżet na test ${station.label} ($fee EUR).',
        updatedEdition: edition,
      );
    }

    final rng = random ?? math.Random();
    final testResult = _measureLabStation(
      candidate: candidate,
      station: station,
      location: edition.location,
      rng: rng,
    );

    final updatedStations =
        Map<CombineTestStation, CombineLabTestResult>.from(candidate.testedStations)
          ..[station] = testResult;

    // Zawężenie widełek potencjału (im wyższy scoutSkill, tym mniejszy błąd)
    final shrinkFactor = (0.32 + (scoutSkill.clamp(40, 100) / 100.0) * 0.28);
    final newSpread = math.max(
      1,
      (candidate.potentialSpread * (1.0 - shrinkFactor)).round(),
    );
    final truePot = candidate.hiddenTruePotential;
    final halfLeft = newSpread ~/ 2;
    final newMin = (truePot - halfLeft).clamp(50, 99);
    final newMax = (newMin + newSpread).clamp(newMin, 99);

    final updatedCandidate = candidate.copyWith(
      testedStations: updatedStations,
      estimatedPotentialMin: newMin,
      estimatedPotentialMax: newMax,
      status: candidate.status == CombineCandidateStatus.invited
          ? CombineCandidateStatus.tested
          : candidate.status,
      combineCompositeScore: _computeCompositeScore(
        testedStations: updatedStations,
        raceResult: candidate.raceResult,
      ),
      recommendedRoleNote: _buildDetailedRoleNote(
        candidate.rider,
        updatedStations,
        candidate.raceResult,
      ),
    );

    final updatedList = edition.candidates
        .map((c) => c.id == candidateId ? updatedCandidate : c)
        .toList();

    final updatedEdition = edition.copyWith(
      budgetSpentEur: edition.budgetSpentEur + fee,
      candidates: updatedList,
      campSummaryNote:
          '${candidate.rider.fullName}: ukończono ${station.label} '
          '(${testResult.rawScore.toStringAsFixed(1)} pkt).',
    );

    return CombineActionOutcome(
      success: true,
      message:
          'Zakończono ${station.label} dla ${candidate.rider.fullName}.',
      updatedEdition: updatedEdition,
      costEur: fee,
    );
  }

  /// Wykonuje komplet wszystkich 4 stacji laboratoryjnych dla jednego kandydata.
  CombineActionOutcome runAllLabTestsForCandidate({
    required CombineCampEdition edition,
    required String candidateId,
    int scoutSkill = 78,
    int availableBudgetEur = 1000000,
    math.Random? random,
  }) {
    var currentEdition = edition;
    var remainingBudget = availableBudgetEur;
    var totalCost = 0;
    var testsRun = 0;

    for (final station in CombineTestStation.values) {
      final candidate = currentEdition.findCandidate(candidateId);
      if (candidate == null) {
        return CombineActionOutcome(
          success: false,
          message: 'Nie znaleziono kandydata o ID $candidateId.',
          updatedEdition: currentEdition,
        );
      }
      if (candidate.testedStations.containsKey(station)) continue;

      final step = runLabTestStation(
        edition: currentEdition,
        candidateId: candidateId,
        station: station,
        scoutSkill: scoutSkill,
        availableBudgetEur: remainingBudget,
        random: random,
      );
      if (!step.success) {
        return CombineActionOutcome(
          success: testsRun > 0,
          message: step.message,
          updatedEdition: currentEdition,
          costEur: totalCost,
        );
      }
      currentEdition = step.updatedEdition;
      remainingBudget -= step.costEur;
      totalCost += step.costEur;
      testsRun++;
    }

    if (testsRun == 0) {
      return CombineActionOutcome(
        success: false,
        message: 'Kandydat przeszedł już komplet 4 testów laboratoryjnych.',
        updatedEdition: currentEdition,
      );
    }

    final name = currentEdition.findCandidate(candidateId)?.rider.fullName ?? '';
    return CombineActionOutcome(
      success: true,
      message: 'Wykonano pełny pakiet 4 testów lab dla $name.',
      updatedEdition: currentEdition,
      costEur: totalCost,
    );
  }

  /// Masowo uruchamia brakujące testy lab dla całej grupy (np. wszystkich zaproszonych).
  CombineActionOutcome runBatchLabTestsForAll({
    required CombineCampEdition edition,
    int scoutSkill = 78,
    int availableBudgetEur = 1000000,
    math.Random? random,
  }) {
    var currentEdition = edition;
    var remainingBudget = availableBudgetEur;
    var totalCost = 0;
    var count = 0;

    for (final candidate in edition.candidates) {
      if (candidate.isFullyLabTested || candidate.status.isSigned) continue;
      final res = runAllLabTestsForCandidate(
        edition: currentEdition,
        candidateId: candidate.id,
        scoutSkill: scoutSkill,
        availableBudgetEur: remainingBudget,
        random: random,
      );
      if (res.costEur > 0) {
        currentEdition = res.updatedEdition;
        remainingBudget -= res.costEur;
        totalCost += res.costEur;
        count++;
      }
      if (!res.success && res.costEur == 0) {
        break;
      }
    }

    return CombineActionOutcome(
      success: count > 0,
      message: count > 0
          ? 'Przetestowano laboratoryjnie $count juniorów (koszt: $totalCost EUR).'
          : 'Brak kandydatów wymagających testów lub brak środków.',
      updatedEdition: currentEdition,
      costEur: totalCost,
    );
  }

  /// Symuluje finałowy 85-kilometrowy wyścig selekcyjny Global Young Talent Combine.
  CombineActionOutcome simulateSelectionRoadRace({
    required CombineCampEdition edition,
    double courseMountainWeight = 0.50,
    double courseSprintWeight = 0.30,
    math.Random? random,
  }) {
    if (edition.phase == CombineCampPhase.concluded) {
      return CombineActionOutcome(
        success: false,
        message: 'Obóz jest już zakończony.',
        updatedEdition: edition,
      );
    }
    if (edition.isSelectionRaceCompleted) {
      return CombineActionOutcome(
        success: false,
        message: 'Wyścig selekcyjny tej edycji został już rozegrany.',
        updatedEdition: edition,
      );
    }

    final rng = random ?? math.Random();
    final scored = <_RacePerfEntry>[];

    final mWeight = courseMountainWeight.clamp(0.1, 0.8);
    final sWeight = courseSprintWeight.clamp(0.1, 0.8);
    final tacticalWeight = (1.0 - (mWeight + sWeight)).clamp(0.1, 0.5);

    for (final candidate in edition.candidates) {
      final r = candidate.rider;
      final wKg = candidate.wPerKg20m;
      final sprintNorm = (r.powerProfile.watts5s / 1350.0).clamp(0.5, 1.25);
      final climbNorm = (wKg / 6.0).clamp(0.55, 1.25);
      final iqNorm = ((r.skills.raceIq + r.skills.aeroPositioning) / 200.0).clamp(0.4, 1.0);
      final formNoise = (rng.nextDouble() - 0.5) * 0.09;

      final perfIndex =
          (climbNorm * mWeight) + (sprintNorm * sWeight) + (iqNorm * tacticalWeight) + formNoise;

      scored.add(_RacePerfEntry(candidate: candidate, perfIndex: perfIndex));
    }

    scored.sort((a, b) => b.perfIndex.compareTo(a.perfIndex));
    final leaderPerf = scored.isNotEmpty ? scored.first.perfIndex : 1.0;

    final updatedById = <String, CombineTalentCandidate>{};
    for (var idx = 0; idx < scored.length; idx++) {
      final entry = scored[idx];
      final rank = idx + 1;
      final gapRatio = (leaderPerf - entry.perfIndex).clamp(0.0, 0.6);
      final gapSeconds = rank == 1 ? 0 : (gapRatio * 420 + idx * 3).round();

      final c = entry.candidate;
      final r = c.rider;
      final weight = r.physiology.weightKg > 0 ? r.physiology.weightKg : 66.0;
      final avgPower = (r.physiology.ftpWatts * (0.86 + rng.nextDouble() * 0.11)).roundToDouble();
      final npWkg = ((avgPower * 1.07) / weight);
      final attacks = (rank <= 6 ? 1 + rng.nextInt(3) : rng.nextInt(2));
      final breakawayKm = rank <= 5 && rng.nextDouble() > 0.35
          ? 14.0 + rng.nextDouble() * 32.0
          : rng.nextDouble() * 8.0;
      final raceIq = (58.0 + (r.skills.raceIq * 0.35) + (rank <= 5 ? 10.0 : 0.0))
          .clamp(40.0, 99.0);

      final highlights = <String>[
        if (rank == 1) 'Zwycięzca wyścigu selekcyjnego Global Combine',
        if (rank <= 3 && rank > 1) 'Podium wyścigu selekcyjnego (#$rank)',
        if (breakawayKm >= 18.0)
          'Aktywny w ucieczce przez ${breakawayKm.toStringAsFixed(0)} km',
        if (attacks >= 2) '$attacks zdecydowane ataki na selektywnym podjeździe',
        if (highlightsEmptyFallback(rank, breakawayKm, attacks))
          'Stabilna jazda w grupie pościgowej',
      ];

      final raceResult = CombineSelectionRaceResult(
        rank: rank,
        timeGapSeconds: gapSeconds,
        avgPowerWatts: avgPower,
        normalizedPowerWPerKg: double.parse(npWkg.toStringAsFixed(2)),
        breakawayKm: double.parse(breakawayKm.toStringAsFixed(1)),
        attackCount: attacks,
        raceIqScore: double.parse(raceIq.toStringAsFixed(1)),
        highlights: highlights,
      );

      // Wyścig dalej zawęża widełki potencjału
      final newSpread = math.max(1, (c.potentialSpread * 0.55).round());
      final truePot = c.hiddenTruePotential;
      final newMin = (truePot - (newSpread ~/ 2)).clamp(50, 99);
      final newMax = (newMin + newSpread).clamp(newMin, 99);

      final nextStatus = c.status.isSigned || c.status == CombineCandidateStatus.shortlisted
          ? c.status
          : CombineCandidateStatus.raced;

      updatedById[c.id] = c.copyWith(
        raceResult: raceResult,
        status: nextStatus,
        estimatedPotentialMin: newMin,
        estimatedPotentialMax: newMax,
        combineCompositeScore: _computeCompositeScore(
          testedStations: c.testedStations,
          raceResult: raceResult,
        ),
        recommendedRoleNote: _buildDetailedRoleNote(
          r,
          c.testedStations,
          raceResult,
        ),
      );
    }

    final updatedList =
        edition.candidates.map((c) => updatedById[c.id] ?? c).toList();
    final winnerName = scored.isNotEmpty ? scored.first.candidate.rider.fullName : '—';

    final updatedEdition = edition.copyWith(
      phase: CombineCampPhase.draftingWindowOpen,
      candidates: updatedList,
      campSummaryNote:
          'Zakończono wyścig selekcyjny 85 km! Zwyciężył $winnerName. '
          'Otwarto okno podpisywania kontraktów (${edition.remainingSignSlots} wolne miejsca).',
    );

    return CombineActionOutcome(
      success: true,
      message: 'Wyścig selekcyjny rozegrany — triumfuje $winnerName.',
      updatedEdition: updatedEdition,
    );
  }

  bool highlightsEmptyFallback(int rank, double breakawayKm, int attacks) {
    return rank > 3 && breakawayKm < 18.0 && attacks < 2;
  }

  /// Dodaje lub usuwa kandydata z listy życzeń dyrektora sportowego.
  CombineCampEdition toggleShortlist({
    required CombineCampEdition edition,
    required String candidateId,
  }) {
    final updated = edition.candidates.map((c) {
      if (c.id != candidateId || c.status.isSigned) return c;
      if (c.status == CombineCandidateStatus.shortlisted) {
        final fallbackStatus = c.hasRaced
            ? CombineCandidateStatus.raced
            : (c.testedStations.isNotEmpty
                ? CombineCandidateStatus.tested
                : CombineCandidateStatus.invited);
        return c.copyWith(status: fallbackStatus);
      }
      return c.copyWith(status: CombineCandidateStatus.shortlisted);
    }).toList();

    return edition.copyWith(candidates: updated);
  }

  /// Podpisuje kontrakt z 17-letnim talentem z obozu do akademii U19/U23 lub kadry Pro.
  CombineActionOutcome signTalentFromCombine({
    required CombineCampEdition edition,
    required String candidateId,
    required String targetTeamId,
    required int availableBudgetEur,
    bool toSeniorProSquad = false,
  }) {
    if (edition.phase == CombineCampPhase.concluded) {
      return CombineActionOutcome(
        success: false,
        message: 'Okno transferowe obozu zostało już zamknięte.',
        updatedEdition: edition,
      );
    }

    if (edition.remainingSignSlots <= 0) {
      return CombineActionOutcome(
        success: false,
        message:
            'Wykorzystano limit ${edition.maxSlotsToSign} podpisów w tej edycji Combine.',
        updatedEdition: edition,
      );
    }

    final candidate = edition.findCandidate(candidateId);
    if (candidate == null) {
      return CombineActionOutcome(
        success: false,
        message: 'Nie znaleziono kandydata o ID $candidateId.',
        updatedEdition: edition,
      );
    }

    if (candidate.status.isSigned) {
      return CombineActionOutcome(
        success: false,
        message: '${candidate.rider.fullName} ma już podpisany kontrakt.',
        updatedEdition: edition,
      );
    }

    final fee = candidate.signingFeeEur + (toSeniorProSquad ? 12000 : 0);
    if (availableBudgetEur < fee) {
      return CombineActionOutcome(
        success: false,
        message:
            'Brak środków na podpisanie ${candidate.rider.fullName} (wymagane $fee EUR).',
        updatedEdition: edition,
      );
    }

    final monthlySalary = toSeniorProSquad ? 3600 : 1850;
    final updatedContract = candidate.rider.contract.copyWith(
      teamId: targetTeamId,
      role: RiderRole.neoPro,
      monthlySalaryEur: monthlySalary,
      signingBonusEur: fee,
      contractEndYear: edition.seasonYear + (toSeniorProSquad ? 3 : 2),
      morale: 92.0,
      leaderLoyalty: 85.0,
    );

    final signedRider = Rider(
      id: candidate.rider.id,
      firstName: candidate.rider.firstName,
      lastName: candidate.rider.lastName,
      nationalityIso: candidate.rider.nationalityIso,
      birthDate: candidate.rider.birthDate,
      potential: candidate.hiddenTruePotential,
      specialization: candidate.rider.specialization,
      physiology: candidate.rider.physiology,
      powerProfile: candidate.rider.powerProfile,
      skills: candidate.rider.skills,
      appearance: candidate.rider.appearance,
      contract: updatedContract,
      health: candidate.rider.health,
      careerPointsUci: candidate.rider.careerPointsUci,
    );

    final nextStatus = toSeniorProSquad
        ? CombineCandidateStatus.signedToPro
        : CombineCandidateStatus.signedToAcademy;

    final updatedCandidate = candidate.copyWith(
      rider: signedRider,
      status: nextStatus,
      estimatedPotentialMin: candidate.hiddenTruePotential,
      estimatedPotentialMax: candidate.hiddenTruePotential,
    );

    final updatedCandidates = edition.candidates
        .map((c) => c.id == candidateId ? updatedCandidate : c)
        .toList();
    final updatedSignedIds = [...edition.signedCandidateIds, candidateId];

    final updatedEdition = edition.copyWith(
      budgetSpentEur: edition.budgetSpentEur + fee,
      signedCandidateIds: updatedSignedIds,
      candidates: updatedCandidates,
      campSummaryNote:
          'Podpisano ${signedRider.fullName} (${signedRider.nationalityIso}, 17 lat) '
          'do ${toSeniorProSquad ? "kadry Pro" : "Akademii U19/U23"}!',
    );

    return CombineActionOutcome(
      success: true,
      message:
          '${signedRider.fullName} dołącza do ${toSeniorProSquad ? "pierwszego zespołu" : "akademii"}!',
      updatedEdition: updatedEdition,
      signedRider: signedRider,
      costEur: fee,
    );
  }

  /// Zamyka bieżącą edycję obozu i tworzy wpis archiwalny.
  ({CombineCampEdition edition, CombineCampHistoryEntry historyEntry})
      concludeCombineCamp({
    required CombineCampEdition edition,
  }) {
    final finalizedCandidates = edition.candidates.map((c) {
      if (c.status.isSigned) return c;
      return c.copyWith(status: CombineCandidateStatus.passedOver);
    }).toList();

    CombineTalentCandidate? topCandidate;
    for (final c in finalizedCandidates) {
      if (topCandidate == null ||
          c.combineCompositeScore > topCandidate.combineCompositeScore) {
        topCandidate = c;
      }
    }

    final concluded = edition.copyWith(
      phase: CombineCampPhase.concluded,
      candidates: finalizedCandidates,
      campSummaryNote:
          'Edycja ${edition.seasonYear} zakończona. Podpisano ${edition.signedCandidateIds.length} '
          'z ${edition.candidates.length} juniorów.',
    );

    final historyEntry = CombineCampHistoryEntry(
      seasonYear: edition.seasonYear,
      location: edition.location,
      totalCandidates: finalizedCandidates.length,
      signedCount: edition.signedCandidateIds.length,
      topProspectName: topCandidate?.rider.fullName ?? 'Brak danych',
      topCombineScore: topCandidate?.combineCompositeScore ?? 0.0,
    );

    return (edition: concluded, historyEntry: historyEntry);
  }

  /// Filtruje i sortuje kandydatów według wybranych kryteriów.
  List<CombineTalentCandidate> filterAndSortCandidates({
    required List<CombineTalentCandidate> candidates,
    CombineRegion? regionFilter,
    CombineSortField sortBy = CombineSortField.combineScore,
  }) {
    final filtered = regionFilter == null
        ? List<CombineTalentCandidate>.from(candidates)
        : candidates.where((c) => c.region == regionFilter).toList();

    filtered.sort((a, b) {
      switch (sortBy) {
        case CombineSortField.combineScore:
          return b.combineCompositeScore.compareTo(a.combineCompositeScore);
        case CombineSortField.estimatedPotential:
          return b.estimatedPotentialMax.compareTo(a.estimatedPotentialMax);
        case CombineSortField.wattsPerKg:
          return b.wPerKg20m.compareTo(a.wPerKg20m);
        case CombineSortField.selectionRaceRank:
          final ra = a.raceResult?.rank ?? 999;
          final rb = b.raceResult?.rank ?? 999;
          return ra.compareTo(rb);
      }
    });

    return filtered;
  }

  CombineLabTestResult _measureLabStation({
    required CombineTalentCandidate candidate,
    required CombineTestStation station,
    required CombineCampLocation location,
    required math.Random rng,
  }) {
    final r = candidate.rider;
    final lab = r.labProfile;
    final weight = r.physiology.weightKg > 0 ? r.physiology.weightKg : 66.0;
    final wPerKg20 = r.powerProfile.watts20m / weight;
    final altitudePenalty = location.altitudeMeters > 1500 ? 0.96 : 1.0;

    final double rawScore;
    final String note;

    switch (station) {
      case CombineTestStation.vo2MaxLabRamp:
        rawScore = ((lab.vo2MaxMlKgMin - 62.0) / 26.0 * 55.0 + 42.0).clamp(35.0, 99.0);
        note = lab.vo2MaxMlKgMin >= 80
            ? 'Wybitny pułap tlenowy (${lab.vo2MaxMlKgMin.toStringAsFixed(1)} ml/kg/min) jak na 17-latka.'
            : 'Stabilna krzywa mleczanowa (LT2: ${lab.lt2LactateMmolL.toStringAsFixed(1)} mmol/l).';
        break;
      case CombineTestStation.wattPerKgClimbTrial:
        final adjWkg = wPerKg20 * altitudePenalty;
        rawScore = ((adjWkg - 4.0) / 2.2 * 58.0 + 40.0).clamp(35.0, 99.0);
        note = adjWkg >= 5.5
            ? 'Znakomity stosunek mocy do masy (${adjWkg.toStringAsFixed(2)} W/kg) na podjeździe.'
            : 'Równe tempo wspinaczki (${adjWkg.toStringAsFixed(2)} W/kg).';
        break;
      case CombineTestStation.peakSprintNeuromuscular:
        rawScore =
            ((r.powerProfile.watts5s - 820.0) / 680.0 * 55.0 + 40.0).clamp(35.0, 99.0);
        note = r.powerProfile.watts5s >= 1220
            ? 'Eksplozywne przyspieszenie (${r.powerProfile.watts5s.toStringAsFixed(0)} W).'
            : 'Kontrolowana dynamika nerwowo-mięśniowa.';
        break;
      case CombineTestStation.aeroCdAAndHandling:
        final techAvg =
            (r.skills.bikeHandling + r.skills.descending + r.skills.timeTrialPositioning) / 3.0;
        rawScore = (techAvg + (rng.nextDouble() * 6.0 - 3.0)).clamp(35.0, 99.0);
        note = techAvg >= 72
            ? 'Czysta pozycja aero i pewne prowadzenie roweru w zakrętach.'
            : 'Wymaga korekty bike-fittingu i pracy nad zjazdami.';
        break;
    }

    final vam = (wPerKg20 * 285.0 * altitudePenalty).clamp(950.0, 1950.0);

    return CombineLabTestResult(
      station: station,
      rawScore: double.parse(rawScore.toStringAsFixed(1)),
      measuredVo2Max: double.parse(lab.vo2MaxMlKgMin.toStringAsFixed(1)),
      measuredFtpWatts: double.parse((r.physiology.ftpWatts * altitudePenalty).toStringAsFixed(0)),
      measuredWPerKg20m: double.parse((wPerKg20 * altitudePenalty).toStringAsFixed(2)),
      measuredPeakSprintWatts: double.parse(r.powerProfile.watts5s.toStringAsFixed(0)),
      measuredLactateThresholdMmol: double.parse(lab.lt2LactateMmolL.toStringAsFixed(2)),
      measuredVamMetersPerHour: double.parse(vam.toStringAsFixed(0)),
      scoutNote: note,
      completedAt: DateTime.now(),
    );
  }

  double _computeCompositeScore({
    required Map<CombineTestStation, CombineLabTestResult> testedStations,
    required CombineSelectionRaceResult? raceResult,
  }) {
    if (testedStations.isEmpty && raceResult == null) return 0.0;

    final labAvg = testedStations.isEmpty
        ? 0.0
        : testedStations.values.map((e) => e.rawScore).reduce((a, b) => a + b) /
            testedStations.length;

    if (raceResult == null) {
      return double.parse(labAvg.toStringAsFixed(1));
    }

    final raceScore = (100.0 - ((raceResult.rank - 1) * 4.5)).clamp(30.0, 100.0);
    if (testedStations.isEmpty) {
      return double.parse((raceScore * 0.85).toStringAsFixed(1));
    }

    final combined = (labAvg * 0.62) + (raceScore * 0.38);
    return double.parse(combined.toStringAsFixed(1));
  }

  String _buildInitialRoleNote(Rider rider) {
    return 'Profil wstępny: ${rider.specialization.displayName} (17 lat, ${rider.nationalityIso}). '
        'Wymaga testów laboratoryjnych.';
  }

  String _buildDetailedRoleNote(
    Rider rider,
    Map<CombineTestStation, CombineLabTestResult> stations,
    CombineSelectionRaceResult? race,
  ) {
    final parts = <String>[rider.specialization.displayName];
    if (stations.containsKey(CombineTestStation.vo2MaxLabRamp)) {
      parts.add(
        'VO2max ${stations[CombineTestStation.vo2MaxLabRamp]!.measuredVo2Max.toStringAsFixed(1)}',
      );
    }
    if (stations.containsKey(CombineTestStation.wattPerKgClimbTrial)) {
      parts.add(
        '${stations[CombineTestStation.wattPerKgClimbTrial]!.measuredWPerKg20m.toStringAsFixed(2)} W/kg',
      );
    }
    if (race != null) {
      parts.add('Wyścig #${race.rank}');
    }
    return parts.join(' • ');
  }
}

class _RacePerfEntry {
  final CombineTalentCandidate candidate;
  final double perfIndex;

  const _RacePerfEntry({
    required this.candidate,
    required this.perfIndex,
  });
}

/// Stan UI i Riverpod dla modułu Global Young Talent Combine.
class YouthTalentSummerCombineState {
  final CombineCampEdition? activeEdition;
  final List<CombineCampHistoryEntry> history;
  final String? selectedCandidateId;
  final CombineRegion? regionFilter;
  final CombineSortField sortBy;
  final int availableBudgetEur;
  final String teamId;
  final String? feedbackMessage;
  final bool isErrorFeedback;

  const YouthTalentSummerCombineState({
    this.activeEdition,
    this.history = const [],
    this.selectedCandidateId,
    this.regionFilter,
    this.sortBy = CombineSortField.combineScore,
    this.availableBudgetEur = 450000,
    this.teamId = 'player_team',
    this.feedbackMessage,
    this.isErrorFeedback = false,
  });

  CombineTalentCandidate? get selectedCandidate {
    final edition = activeEdition;
    if (edition == null || selectedCandidateId == null) return null;
    return edition.findCandidate(selectedCandidateId!);
  }

  YouthTalentSummerCombineState copyWith({
    CombineCampEdition? activeEdition,
    bool clearEdition = false,
    List<CombineCampHistoryEntry>? history,
    String? selectedCandidateId,
    bool clearSelectedCandidate = false,
    CombineRegion? regionFilter,
    bool clearRegionFilter = false,
    CombineSortField? sortBy,
    int? availableBudgetEur,
    String? feedbackMessage,
    bool clearFeedback = false,
    bool? isErrorFeedback,
  }) {
    return YouthTalentSummerCombineState(
      activeEdition: clearEdition ? null : (activeEdition ?? this.activeEdition),
      history: history ?? this.history,
      selectedCandidateId: clearSelectedCandidate
          ? null
          : (selectedCandidateId ?? this.selectedCandidateId),
      regionFilter:
          clearRegionFilter ? null : (regionFilter ?? this.regionFilter),
      sortBy: sortBy ?? this.sortBy,
      availableBudgetEur: availableBudgetEur ?? this.availableBudgetEur,
      teamId: teamId,
      feedbackMessage:
          clearFeedback ? null : (feedbackMessage ?? this.feedbackMessage),
      isErrorFeedback: isErrorFeedback ?? this.isErrorFeedback,
    );
  }
}

/// Kontroler stanu Riverpod obsługujący obóz Global Young Talent Combine.
class YouthTalentSummerCombineNotifier
    extends StateNotifier<YouthTalentSummerCombineState> {
  final YouthTalentSummerCombineCampService _service;

  YouthTalentSummerCombineNotifier({
    YouthTalentSummerCombineCampService? service,
    YouthTalentSummerCombineState? initialState,
  })  : _service = service ?? const YouthTalentSummerCombineCampService(),
        super(initialState ?? const YouthTalentSummerCombineState());

  void launchNewEdition({
    int seasonYear = 2026,
    CombineCampLocation location = CombineCampLocation.aigleUciWcc,
    int candidateCount = 16,
    int maxSlotsToSign = 3,
    math.Random? random,
  }) {
    if (state.availableBudgetEur < location.organizationCostEur) {
      state = state.copyWith(
        feedbackMessage:
            'Brak środków na organizację obozu (${location.organizationCostEur} EUR).',
        isErrorFeedback: true,
      );
      return;
    }

    final edition = _service.launchAnnualCombine(
      seasonYear: seasonYear,
      location: location,
      candidateCount: candidateCount,
      maxSlotsToSign: maxSlotsToSign,
      random: random,
    );

    state = state.copyWith(
      activeEdition: edition,
      selectedCandidateId:
          edition.candidates.isNotEmpty ? edition.candidates.first.id : null,
      availableBudgetEur: state.availableBudgetEur - location.organizationCostEur,
      feedbackMessage: edition.campSummaryNote,
      isErrorFeedback: false,
    );
  }

  void selectCandidate(String candidateId) {
    state = state.copyWith(
      selectedCandidateId: candidateId,
      clearFeedback: true,
    );
  }

  void setRegionFilter(CombineRegion? region) {
    state = state.copyWith(
      regionFilter: region,
      clearRegionFilter: region == null,
    );
  }

  void setSortField(CombineSortField sortField) {
    state = state.copyWith(sortBy: sortField);
  }

  void runLabStation({
    required String candidateId,
    required CombineTestStation station,
    int scoutSkill = 80,
    math.Random? random,
  }) {
    final edition = state.activeEdition;
    if (edition == null) return;

    final outcome = _service.runLabTestStation(
      edition: edition,
      candidateId: candidateId,
      station: station,
      scoutSkill: scoutSkill,
      availableBudgetEur: state.availableBudgetEur,
      random: random,
    );

    state = state.copyWith(
      activeEdition: outcome.updatedEdition,
      availableBudgetEur: state.availableBudgetEur - outcome.costEur,
      feedbackMessage: outcome.message,
      isErrorFeedback: !outcome.success,
    );
  }

  void runAllLabForCandidate({
    required String candidateId,
    int scoutSkill = 80,
    math.Random? random,
  }) {
    final edition = state.activeEdition;
    if (edition == null) return;

    final outcome = _service.runAllLabTestsForCandidate(
      edition: edition,
      candidateId: candidateId,
      scoutSkill: scoutSkill,
      availableBudgetEur: state.availableBudgetEur,
      random: random,
    );

    state = state.copyWith(
      activeEdition: outcome.updatedEdition,
      availableBudgetEur: state.availableBudgetEur - outcome.costEur,
      feedbackMessage: outcome.message,
      isErrorFeedback: !outcome.success,
    );
  }

  void runBatchLabForAll({int scoutSkill = 80, math.Random? random}) {
    final edition = state.activeEdition;
    if (edition == null) return;

    final outcome = _service.runBatchLabTestsForAll(
      edition: edition,
      scoutSkill: scoutSkill,
      availableBudgetEur: state.availableBudgetEur,
      random: random,
    );

    state = state.copyWith(
      activeEdition: outcome.updatedEdition,
      availableBudgetEur: state.availableBudgetEur - outcome.costEur,
      feedbackMessage: outcome.message,
      isErrorFeedback: !outcome.success,
    );
  }

  void simulateSelectionRace({
    double courseMountainWeight = 0.50,
    double courseSprintWeight = 0.30,
    math.Random? random,
  }) {
    final edition = state.activeEdition;
    if (edition == null) return;

    final outcome = _service.simulateSelectionRoadRace(
      edition: edition,
      courseMountainWeight: courseMountainWeight,
      courseSprintWeight: courseSprintWeight,
      random: random,
    );

    state = state.copyWith(
      activeEdition: outcome.updatedEdition,
      feedbackMessage: outcome.message,
      isErrorFeedback: !outcome.success,
    );
  }

  void toggleShortlist(String candidateId) {
    final edition = state.activeEdition;
    if (edition == null) return;
    final updated = _service.toggleShortlist(
      edition: edition,
      candidateId: candidateId,
    );
    state = state.copyWith(activeEdition: updated);
  }

  void signCandidate({
    required String candidateId,
    bool toSeniorProSquad = false,
  }) {
    final edition = state.activeEdition;
    if (edition == null) return;

    final outcome = _service.signTalentFromCombine(
      edition: edition,
      candidateId: candidateId,
      targetTeamId: state.teamId,
      availableBudgetEur: state.availableBudgetEur,
      toSeniorProSquad: toSeniorProSquad,
    );

    state = state.copyWith(
      activeEdition: outcome.updatedEdition,
      availableBudgetEur: state.availableBudgetEur - outcome.costEur,
      feedbackMessage: outcome.message,
      isErrorFeedback: !outcome.success,
    );
  }

  void concludeActiveCamp() {
    final edition = state.activeEdition;
    if (edition == null) return;

    final res = _service.concludeCombineCamp(edition: edition);
    state = state.copyWith(
      activeEdition: res.edition,
      history: [res.historyEntry, ...state.history],
      feedbackMessage: res.edition.campSummaryNote,
      isErrorFeedback: false,
    );
  }
}

final youthTalentSummerCombineServiceProvider =
    Provider<YouthTalentSummerCombineCampService>(
  (ref) => const YouthTalentSummerCombineCampService(),
);

final youthTalentSummerCombineProvider = StateNotifierProvider<
    YouthTalentSummerCombineNotifier, YouthTalentSummerCombineState>((ref) {
  final service = ref.watch(youthTalentSummerCombineServiceProvider);
  return YouthTalentSummerCombineNotifier(service: service);
});

/// Produkcyjny panel UI obozu selekcyjnego 17-latków `Global Young Talent Combine`.
class YouthTalentSummerCombineCampPanel extends ConsumerStatefulWidget {
  const YouthTalentSummerCombineCampPanel({super.key});

  @override
  ConsumerState<YouthTalentSummerCombineCampPanel> createState() =>
      _YouthTalentSummerCombineCampPanelState();
}

class _YouthTalentSummerCombineCampPanelState
    extends ConsumerState<YouthTalentSummerCombineCampPanel> {
  CombineCampLocation _selectedLocation = CombineCampLocation.aigleUciWcc;
  final YouthTalentSummerCombineCampService _service =
      const YouthTalentSummerCombineCampService();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(youthTalentSummerCombineProvider);
    final notifier = ref.read(youthTalentSummerCombineProvider.notifier);

    return Container(
      color: AppColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 720;
          final isDesktop = constraints.maxWidth >= 1180;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 12 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderCard(state, notifier, isMobile),
                if (state.feedbackMessage != null) ...[
                  const SizedBox(height: 12),
                  _buildFeedbackBanner(
                    state.feedbackMessage!,
                    state.isErrorFeedback,
                  ),
                ],
                const SizedBox(height: 16),
                if (state.activeEdition == null)
                  _buildLaunchSetupCard(state, notifier, isMobile)
                else
                  _buildActiveCombineContent(
                    state,
                    state.activeEdition!,
                    notifier,
                    isMobile,
                    isDesktop,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(
    YouthTalentSummerCombineState state,
    YouthTalentSummerCombineNotifier notifier,
    bool isMobile,
  ) {
    final edition = state.activeEdition;
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.goldAccent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.goldAccent.withValues(alpha: 0.45),
                  ),
                ),
                child: const Icon(
                  Icons.public_rounded,
                  color: AppColors.goldAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'GLOBAL YOUNG TALENT COMBINE',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      edition == null
                          ? 'Coroczny obóz selekcyjny 17-letnich talentów z całego świata'
                          : '${edition.location.label} • ${edition.phase.label}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _StatBadge(
                label: 'Budżet Skautingu',
                value: '${_formatEur(state.availableBudgetEur)} EUR',
                accent: AppColors.statusSuccess,
              ),
              if (edition != null)
                _StatBadge(
                  label: 'Wolne Kontrakty',
                  value:
                      '${edition.remainingSignSlots}/${edition.maxSlotsToSign}',
                  accent: AppColors.goldAccent,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackBanner(String message, bool isError) {
    final color = isError ? AppColors.crimsonAlert : AppColors.statusSuccess;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: color,
            size: 18,
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

  Widget _buildLaunchSetupCard(
    YouthTalentSummerCombineState state,
    YouthTalentSummerCombineNotifier notifier,
    bool isMobile,
  ) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Wybierz Bazę Letniego Obozu Selekcyjnego',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Zaproś 16 wyselekcjonowanych 17-latków z 7 regionów świata na testy wydolnościowe oraz wyścig kontrolny 85 km.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: CombineCampLocation.values.map((loc) {
              final selected = _selectedLocation == loc;
              return _InteractiveSurfaceButton(
                onTap: () => setState(() => _selectedLocation = loc),
                isSelected: selected,
                width: isMobile ? double.infinity : 260,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          loc.countryIso,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? AppColors.goldAccent
                                : AppColors.accentBlue,
                          ),
                        ),
                        Text(
                          '${loc.altitudeMeters} m n.p.m.',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      loc.label,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loc.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Koszt: ${_formatEur(loc.organizationCostEur)} EUR',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.goldAccent,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          _ActionPillButton(
            label: 'Otwórz Global Young Talent Combine',
            icon: Icons.rocket_launch_rounded,
            accent: AppColors.primaryAccent,
            enabled:
                state.availableBudgetEur >= _selectedLocation.organizationCostEur,
            onPressed: () =>
                notifier.launchNewEdition(location: _selectedLocation),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveCombineContent(
    YouthTalentSummerCombineState state,
    CombineCampEdition edition,
    YouthTalentSummerCombineNotifier notifier,
    bool isMobile,
    bool isDesktop,
  ) {
    final candidates = _service.filterAndSortCandidates(
      candidates: edition.candidates,
      regionFilter: state.regionFilter,
      sortBy: state.sortBy,
    );
    final selected = state.selectedCandidate ??
        (candidates.isNotEmpty ? candidates.first : null);

    final toolbar = _buildActionToolbar(state, edition, notifier);
    final listCard = _buildCandidatesListCard(
      candidates,
      selected?.id,
      state,
      notifier,
    );
    final detailCard = selected == null
        ? const SizedBox.shrink()
        : _buildCandidateDetailCard(selected, edition, state, notifier, isMobile);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        toolbar,
        const SizedBox(height: 16),
        if (isMobile) ...[
          listCard,
          const SizedBox(height: 16),
          detailCard,
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: isDesktop ? 5 : 4, child: listCard),
              const SizedBox(width: 16),
              Expanded(flex: isDesktop ? 6 : 5, child: detailCard),
            ],
          ),
      ],
    );
  }

  Widget _buildActionToolbar(
    YouthTalentSummerCombineState state,
    CombineCampEdition edition,
    YouthTalentSummerCombineNotifier notifier,
  ) {
    final isConcluded = edition.phase == CombineCampPhase.concluded;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _ActionPillButton(
            label: 'Testy Lab (Wszyscy)',
            icon: Icons.biotech_rounded,
            accent: AppColors.accentBlue,
            enabled: !isConcluded,
            onPressed: () => notifier.runBatchLabForAll(),
          ),
          _ActionPillButton(
            label: edition.isSelectionRaceCompleted
                ? 'Wyścig Rozegrany'
                : 'Symuluj Wyścig 85 km',
            icon: Icons.directions_bike_rounded,
            accent: AppColors.goldAccent,
            enabled: !isConcluded && !edition.isSelectionRaceCompleted,
            onPressed: () => notifier.simulateSelectionRace(),
          ),
          _ActionPillButton(
            label: isConcluded ? 'Nowa Edycja' : 'Zakończ Obóz',
            icon: isConcluded ? Icons.refresh_rounded : Icons.flag_rounded,
            accent: isConcluded ? AppColors.primaryAccent : AppColors.statusSuccess,
            enabled: true,
            onPressed: () {
              if (isConcluded) {
                notifier.launchNewEdition(
                  seasonYear: edition.seasonYear + 1,
                  location: _selectedLocation,
                );
              } else {
                notifier.concludeActiveCamp();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCandidatesListCard(
    List<CombineTalentCandidate> candidates,
    String? selectedId,
    YouthTalentSummerCombineState state,
    YouthTalentSummerCombineNotifier notifier,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Text(
                'Kandydaci U18 (${candidates.length})',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              DropdownButton<CombineSortField>(
                value: state.sortBy,
                dropdownColor: AppColors.surfaceLight,
                underline: const SizedBox.shrink(),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.accentBlue,
                ),
                items: CombineSortField.values
                    .map(
                      (f) => DropdownMenuItem(
                        value: f,
                        child: Text(f.label),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) notifier.setSortField(v);
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChipItem(
                  label: 'Wszystkie',
                  selected: state.regionFilter == null,
                  onTap: () => notifier.setRegionFilter(null),
                ),
                ...CombineRegion.values.map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: _FilterChipItem(
                      label: r.label,
                      selected: state.regionFilter == r,
                      onTap: () => notifier.setRegionFilter(r),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 480),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: candidates.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final c = candidates[index];
                final isSelected = c.id == selectedId;
                return _InteractiveSurfaceButton(
                  onTap: () => notifier.selectCandidate(c.id),
                  isSelected: isSelected,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    c.rider.fullName,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  c.rider.nationalityIso,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accentBlue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${c.rider.specialization.displayName} • Pot. ${c.displayPotentialRange}',
                              overflow: TextOverflow.ellipsis,
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
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            c.combineCompositeScore > 0
                                ? c.combineCompositeScore.toStringAsFixed(1)
                                : '—',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: c.prospectTier.accentColor,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                          Text(
                            c.status.label,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCandidateDetailCard(
    CombineTalentCandidate candidate,
    CombineCampEdition edition,
    YouthTalentSummerCombineState state,
    YouthTalentSummerCombineNotifier notifier,
    bool isMobile,
  ) {
    final r = candidate.rider;
    final isConcluded = edition.phase == CombineCampPhase.concluded;
    final canSign = !isConcluded &&
        !candidate.status.isSigned &&
        edition.remainingSignSlots > 0;

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${r.fullName} (${r.nationalityIso}, 17 lat)',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${r.specialization.displayName} • ${candidate.region.label}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: candidate.prospectTier.accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: candidate.prospectTier.accentColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  candidate.prospectTier.badgeShort,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: candidate.prospectTier.accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _StatBadge(
                label: 'Potencjał',
                value: candidate.displayPotentialRange,
                accent: AppColors.goldAccent,
              ),
              _StatBadge(
                label: 'Combine Score',
                value: candidate.combineCompositeScore > 0
                    ? candidate.combineCompositeScore.toStringAsFixed(1)
                    : 'Brak',
                accent: AppColors.accentBlue,
              ),
              _StatBadge(
                label: 'Zainteresowanie WT',
                value: '${candidate.competingTeamsInterest} ekip',
                accent: AppColors.amberWarning,
              ),
              _StatBadge(
                label: 'Opłata Szkoleniowa',
                value: '${_formatEur(candidate.signingFeeEur)} EUR',
                accent: AppColors.statusSuccess,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Stacje Laboratoryjne Combine',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CombineTestStation.values.map((station) {
              final result = candidate.testedStations[station];
              return _InteractiveSurfaceButton(
                onTap: (!isConcluded && result == null)
                    ? () => notifier.runLabStation(
                          candidateId: candidate.id,
                          station: station,
                        )
                    : null,
                isSelected: result != null,
                width: isMobile ? double.infinity : 236,
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            station.shortLabel,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          result != null
                              ? '${result.rawScore.toStringAsFixed(1)} pkt'
                              : '${station.testFeeEur} EUR',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: result != null
                                ? AppColors.statusSuccess
                                : AppColors.goldAccent,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result != null ? result.scoutNote : 'Kliknij, aby wykonać test',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          if (candidate.raceResult != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Wyścig Selekcyjny 85 km: Miejsce #${candidate.raceResult!.rank} (${candidate.raceResult!.formattedGap})',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.goldAccent,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'NP: ${candidate.raceResult!.normalizedPowerWPerKg} W/kg • '
                    'Ataki: ${candidate.raceResult!.attackCount} • '
                    'Race IQ: ${candidate.raceResult!.raceIqScore}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textPrimary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ActionPillButton(
                label: candidate.status == CombineCandidateStatus.shortlisted
                    ? 'Usuń z Listy Życzeń'
                    : 'Na Listę Życzeń',
                icon: Icons.star_outline_rounded,
                accent: AppColors.accentBlue,
                enabled: !isConcluded && !candidate.status.isSigned,
                onPressed: () => notifier.toggleShortlist(candidate.id),
              ),
              _ActionPillButton(
                label: 'Podpisz do Akademii U23',
                icon: Icons.school_rounded,
                accent: AppColors.statusSuccess,
                enabled: canSign &&
                    state.availableBudgetEur >= candidate.signingFeeEur,
                onPressed: () => notifier.signCandidate(
                  candidateId: candidate.id,
                  toSeniorProSquad: false,
                ),
              ),
              _ActionPillButton(
                label: 'Podpisz Bezpośrednio do Pro',
                icon: Icons.workspace_premium_rounded,
                accent: AppColors.primaryAccent,
                enabled: canSign &&
                    state.availableBudgetEur >= (candidate.signingFeeEur + 12000),
                onPressed: () => notifier.signCandidate(
                  candidateId: candidate.id,
                  toSeniorProSquad: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatEur(int value) {
    final s = value.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _StatBadge({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: accent,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipItem extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChipItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_FilterChipItem> createState() => _FilterChipItemState();
}

class _FilterChipItemState extends State<_FilterChipItem> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.selected
        ? AppColors.goldAccent
        : (_focused || _hovered
            ? AppColors.accentBlue
            : AppColors.cardBorder);

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: widget.selected
                ? AppColors.goldAccent.withValues(alpha: 0.16)
                : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
              color: widget.selected
                  ? AppColors.goldAccent
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractiveSurfaceButton extends StatefulWidget {
  final VoidCallback? onTap;
  final bool isSelected;
  final Widget child;
  final double? width;
  final EdgeInsetsGeometry padding;

  const _InteractiveSurfaceButton({
    required this.onTap,
    required this.isSelected,
    required this.child,
    this.width,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  State<_InteractiveSurfaceButton> createState() =>
      _InteractiveSurfaceButtonState();
}

class _InteractiveSurfaceButtonState extends State<_InteractiveSurfaceButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final borderColor = widget.isSelected
        ? AppColors.goldAccent
        : (_focused
            ? AppColors.accentBlue
            : (_hovered && enabled
                ? AppColors.textSecondary
                : AppColors.cardBorder));

    return FocusableActionDetector(
      enabled: enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: InkWell(
        onTap: widget.onTap,
        onHighlightChanged: (v) => setState(() => _pressed = v),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: widget.width,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: _pressed && enabled
                ? AppColors.surfaceLight.withValues(alpha: 0.9)
                : (widget.isSelected
                    ? AppColors.primaryAccent.withValues(alpha: 0.16)
                    : AppColors.surfaceLight),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class _ActionPillButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accent;
  final bool enabled;
  final VoidCallback onPressed;

  const _ActionPillButton({
    required this.label,
    required this.icon,
    required this.accent,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_ActionPillButton> createState() => _ActionPillButtonState();
}

class _ActionPillButtonState extends State<_ActionPillButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = !widget.enabled
        ? AppColors.surfaceLight
        : (_pressed
            ? widget.accent.withValues(alpha: 0.85)
            : (_hovered
                ? widget.accent.withValues(alpha: 0.95)
                : widget.accent));

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: InkWell(
        onTap: widget.enabled ? widget.onPressed : null,
        onHighlightChanged: (v) => setState(() => _pressed = v),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _focused
                  ? AppColors.goldAccent
                  : (widget.enabled
                      ? widget.accent
                      : AppColors.cardBorder),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 16,
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
                    fontSize: 12,
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
