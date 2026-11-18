// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/team/cycling_team.dart';

/// Główny archetyp taktyczny dyrektora sportowego drużyny AI.
enum DsTacticalArchetype {
  skyTrainControl,
  totalAttackChaos,
  sprintLeadoutMachine,
  echelonCrosswindHunters,
  breakawayOpportunists,
  cobblesAndClassicsBrawler,
  mountainAmbushRelay,
  counterPunchSniper,
  komPolkaHunter,
  academyTalentShowrunner;

  String toJson() => name;

  static DsTacticalArchetype fromJson(String value) {
    return DsTacticalArchetype.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => DsTacticalArchetype.breakawayOpportunists,
    );
  }

  String get label {
    switch (this) {
      case DsTacticalArchetype.skyTrainControl:
        return 'Kontrolowany Pociąg Tempowy';
      case DsTacticalArchetype.totalAttackChaos:
        return 'Totalna Ofensywa z Daleka';
      case DsTacticalArchetype.sprintLeadoutMachine:
        return 'Maszyna Sprinterska';
      case DsTacticalArchetype.echelonCrosswindHunters:
        return 'Łowcy Wachlarzy';
      case DsTacticalArchetype.breakawayOpportunists:
        return 'Łowcy Ucieczek i Etapów';
      case DsTacticalArchetype.cobblesAndClassicsBrawler:
        return 'Wojownicy Bruku i Klasyków';
      case DsTacticalArchetype.mountainAmbushRelay:
        return 'Górskie Zasadzki Przekaźnikowe';
      case DsTacticalArchetype.counterPunchSniper:
        return 'Snajper Kontrataku';
      case DsTacticalArchetype.komPolkaHunter:
        return 'Łowcy Koszulki w Grochy';
      case DsTacticalArchetype.academyTalentShowrunner:
        return 'Akademia Rozwoju i Harców';
    }
  }

  String get shortLabel {
    switch (this) {
      case DsTacticalArchetype.skyTrainControl:
        return 'Pociąg GC';
      case DsTacticalArchetype.totalAttackChaos:
        return 'Total Attack';
      case DsTacticalArchetype.sprintLeadoutMachine:
        return 'Sprint Train';
      case DsTacticalArchetype.echelonCrosswindHunters:
        return 'Wachlarze';
      case DsTacticalArchetype.breakawayOpportunists:
        return 'Ucieczki';
      case DsTacticalArchetype.cobblesAndClassicsBrawler:
        return 'Bruk/Klasyki';
      case DsTacticalArchetype.mountainAmbushRelay:
        return 'Przekaźniki';
      case DsTacticalArchetype.counterPunchSniper:
        return 'Kontratak';
      case DsTacticalArchetype.komPolkaHunter:
        return 'Grochy KOM';
      case DsTacticalArchetype.academyTalentShowrunner:
        return 'Akademia U23';
    }
  }

  Color get accentColor {
    switch (this) {
      case DsTacticalArchetype.skyTrainControl:
        return AppColors.accentBlue;
      case DsTacticalArchetype.totalAttackChaos:
        return AppColors.crimsonAlert;
      case DsTacticalArchetype.sprintLeadoutMachine:
        return AppColors.cyanAccent;
      case DsTacticalArchetype.echelonCrosswindHunters:
        return AppColors.amberWarning;
      case DsTacticalArchetype.breakawayOpportunists:
        return AppColors.statusSuccess;
      case DsTacticalArchetype.cobblesAndClassicsBrawler:
        return AppColors.primaryAccent;
      case DsTacticalArchetype.mountainAmbushRelay:
        return AppColors.goldAccent;
      case DsTacticalArchetype.counterPunchSniper:
        return AppColors.powerZone7;
      case DsTacticalArchetype.komPolkaHunter:
        return AppColors.powerZone6;
      case DsTacticalArchetype.academyTalentShowrunner:
        return AppColors.powerZone3;
    }
  }

  IconData get icon {
    switch (this) {
      case DsTacticalArchetype.skyTrainControl:
        return Icons.linear_scale_rounded;
      case DsTacticalArchetype.totalAttackChaos:
        return Icons.flash_on_rounded;
      case DsTacticalArchetype.sprintLeadoutMachine:
        return Icons.speed_rounded;
      case DsTacticalArchetype.echelonCrosswindHunters:
        return Icons.air_rounded;
      case DsTacticalArchetype.breakawayOpportunists:
        return Icons.directions_bike_rounded;
      case DsTacticalArchetype.cobblesAndClassicsBrawler:
        return Icons.terrain_rounded;
      case DsTacticalArchetype.mountainAmbushRelay:
        return Icons.hub_rounded;
      case DsTacticalArchetype.counterPunchSniper:
        return Icons.gps_fixed_rounded;
      case DsTacticalArchetype.komPolkaHunter:
        return Icons.landscape_rounded;
      case DsTacticalArchetype.academyTalentShowrunner:
        return Icons.school_rounded;
    }
  }
}

/// Preferowany profil terenu etapu dla dyrektora sportowego.
enum DsStageTerrainFocus {
  flatSprint,
  cobblesClassic,
  hillyPuncheur,
  highMountain,
  timeTrial,
  allRounder;

  String toJson() => name;

  static DsStageTerrainFocus fromJson(String value) {
    return DsStageTerrainFocus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => DsStageTerrainFocus.allRounder,
    );
  }

  String get label {
    switch (this) {
      case DsStageTerrainFocus.flatSprint:
        return 'Płaskie / Sprint';
      case DsStageTerrainFocus.cobblesClassic:
        return 'Bruk / Klasyki';
      case DsStageTerrainFocus.hillyPuncheur:
        return 'Pagórki / Ardeny';
      case DsStageTerrainFocus.highMountain:
        return 'Wysokie Góry';
      case DsStageTerrainFocus.timeTrial:
        return 'Jazda na Czas';
      case DsStageTerrainFocus.allRounder:
        return 'Wszechstronny';
    }
  }
}

/// Tolerancja ryzyka taktycznego w trakcie wyścigu.
enum DsRiskToleranceLevel {
  conservative,
  calculated,
  aggressive,
  reckless;

  String toJson() => name;

  static DsRiskToleranceLevel fromJson(String value) {
    return DsRiskToleranceLevel.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => DsRiskToleranceLevel.calculated,
    );
  }

  String get label {
    switch (this) {
      case DsRiskToleranceLevel.conservative:
        return 'Konserwatywna';
      case DsRiskToleranceLevel.calculated:
        return 'Skalkulowana';
      case DsRiskToleranceLevel.aggressive:
        return 'Agresywna';
      case DsRiskToleranceLevel.reckless:
        return 'Bezkompromisowa';
    }
  }
}

/// Szybkość adaptacji dyrektora sportowego do wydarzeń na trasie.
enum DsAdaptationSpeed {
  rigid,
  methodical,
  reactive,
  improvisational;

  String toJson() => name;

  static DsAdaptationSpeed fromJson(String value) {
    return DsAdaptationSpeed.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => DsAdaptationSpeed.methodical,
    );
  }

  String get label {
    switch (this) {
      case DsAdaptationSpeed.rigid:
        return 'Sztywny plan';
      case DsAdaptationSpeed.methodical:
        return 'Metodyczna';
      case DsAdaptationSpeed.reactive:
        return 'Reaktywna';
      case DsAdaptationSpeed.improvisational:
        return 'Improwizacja';
    }
  }
}

/// Zestaw liczbowych tendencji taktycznych dyrektora sportowego (0.0 – 1.0).
class DsTacticalTendencyProfile {
  final double breakawayAppetite;
  final double pelotonChaseAggression;
  final double mountainPaceTrainIntensity;
  final double crosswindEchelonTrigger;
  final double sprintLeadoutCommitment;
  final double satelliteRelayFrequency;
  final double lateAttackDistanceKm;
  final double riskAppetite;
  final double bluffingAndPokerFaceBias;
  final double gcProtectionThresholdMin;

  const DsTacticalTendencyProfile({
    required this.breakawayAppetite,
    required this.pelotonChaseAggression,
    required this.mountainPaceTrainIntensity,
    required this.crosswindEchelonTrigger,
    required this.sprintLeadoutCommitment,
    required this.satelliteRelayFrequency,
    required this.lateAttackDistanceKm,
    required this.riskAppetite,
    required this.bluffingAndPokerFaceBias,
    required this.gcProtectionThresholdMin,
  });

  /// Złożony indeks agresji taktycznej (0–100).
  int get tacticalAggressionIndex {
    final raw = (breakawayAppetite * 0.22 +
            crosswindEchelonTrigger * 0.18 +
            riskAppetite * 0.25 +
            satelliteRelayFrequency * 0.15 +
            (lateAttackDistanceKm / 70.0).clamp(0.0, 1.0) * 0.20) *
        100.0;
    return raw.round().clamp(5, 99);
  }

  DsTacticalTendencyProfile copyWith({
    double? breakawayAppetite,
    double? pelotonChaseAggression,
    double? mountainPaceTrainIntensity,
    double? crosswindEchelonTrigger,
    double? sprintLeadoutCommitment,
    double? satelliteRelayFrequency,
    double? lateAttackDistanceKm,
    double? riskAppetite,
    double? bluffingAndPokerFaceBias,
    double? gcProtectionThresholdMin,
  }) {
    return DsTacticalTendencyProfile(
      breakawayAppetite:
          (breakawayAppetite ?? this.breakawayAppetite).clamp(0.0, 1.0),
      pelotonChaseAggression:
          (pelotonChaseAggression ?? this.pelotonChaseAggression).clamp(0.0, 1.0),
      mountainPaceTrainIntensity:
          (mountainPaceTrainIntensity ?? this.mountainPaceTrainIntensity)
              .clamp(0.0, 1.0),
      crosswindEchelonTrigger:
          (crosswindEchelonTrigger ?? this.crosswindEchelonTrigger)
              .clamp(0.0, 1.0),
      sprintLeadoutCommitment:
          (sprintLeadoutCommitment ?? this.sprintLeadoutCommitment)
              .clamp(0.0, 1.0),
      satelliteRelayFrequency:
          (satelliteRelayFrequency ?? this.satelliteRelayFrequency)
              .clamp(0.0, 1.0),
      lateAttackDistanceKm:
          (lateAttackDistanceKm ?? this.lateAttackDistanceKm).clamp(0.5, 85.0),
      riskAppetite: (riskAppetite ?? this.riskAppetite).clamp(0.0, 1.0),
      bluffingAndPokerFaceBias:
          (bluffingAndPokerFaceBias ?? this.bluffingAndPokerFaceBias)
              .clamp(0.0, 1.0),
      gcProtectionThresholdMin:
          (gcProtectionThresholdMin ?? this.gcProtectionThresholdMin)
              .clamp(1.0, 8.0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'breakawayAppetite': breakawayAppetite,
      'pelotonChaseAggression': pelotonChaseAggression,
      'mountainPaceTrainIntensity': mountainPaceTrainIntensity,
      'crosswindEchelonTrigger': crosswindEchelonTrigger,
      'sprintLeadoutCommitment': sprintLeadoutCommitment,
      'satelliteRelayFrequency': satelliteRelayFrequency,
      'lateAttackDistanceKm': lateAttackDistanceKm,
      'riskAppetite': riskAppetite,
      'bluffingAndPokerFaceBias': bluffingAndPokerFaceBias,
      'gcProtectionThresholdMin': gcProtectionThresholdMin,
    };
  }

  factory DsTacticalTendencyProfile.fromJson(Map<String, dynamic> json) {
    return DsTacticalTendencyProfile(
      breakawayAppetite:
          (json['breakawayAppetite'] as num?)?.toDouble() ?? 0.5,
      pelotonChaseAggression:
          (json['pelotonChaseAggression'] as num?)?.toDouble() ?? 0.5,
      mountainPaceTrainIntensity:
          (json['mountainPaceTrainIntensity'] as num?)?.toDouble() ?? 0.5,
      crosswindEchelonTrigger:
          (json['crosswindEchelonTrigger'] as num?)?.toDouble() ?? 0.5,
      sprintLeadoutCommitment:
          (json['sprintLeadoutCommitment'] as num?)?.toDouble() ?? 0.5,
      satelliteRelayFrequency:
          (json['satelliteRelayFrequency'] as num?)?.toDouble() ?? 0.4,
      lateAttackDistanceKm:
          (json['lateAttackDistanceKm'] as num?)?.toDouble() ?? 15.0,
      riskAppetite: (json['riskAppetite'] as num?)?.toDouble() ?? 0.5,
      bluffingAndPokerFaceBias:
          (json['bluffingAndPokerFaceBias'] as num?)?.toDouble() ?? 0.4,
      gcProtectionThresholdMin:
          (json['gcProtectionThresholdMin'] as num?)?.toDouble() ?? 3.5,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DsTacticalTendencyProfile &&
        other.breakawayAppetite == breakawayAppetite &&
        other.pelotonChaseAggression == pelotonChaseAggression &&
        other.mountainPaceTrainIntensity == mountainPaceTrainIntensity &&
        other.crosswindEchelonTrigger == crosswindEchelonTrigger &&
        other.sprintLeadoutCommitment == sprintLeadoutCommitment &&
        other.satelliteRelayFrequency == satelliteRelayFrequency &&
        other.lateAttackDistanceKm == lateAttackDistanceKm &&
        other.riskAppetite == riskAppetite &&
        other.bluffingAndPokerFaceBias == bluffingAndPokerFaceBias &&
        other.gcProtectionThresholdMin == gcProtectionThresholdMin;
  }

  @override
  int get hashCode => Object.hash(
        breakawayAppetite,
        pelotonChaseAggression,
        mountainPaceTrainIntensity,
        crosswindEchelonTrigger,
        sprintLeadoutCommitment,
        satelliteRelayFrequency,
        lateAttackDistanceKm,
        riskAppetite,
        bluffingAndPokerFaceBias,
        gcProtectionThresholdMin,
      );
}

/// Pełny unikalny profil taktyczny dyrektora sportowego drużyny AI.
class DirectorSportifTacticalProfile {
  final String teamId;
  final String teamName;
  final TeamDivision division;
  final String countryIso;
  final String directorName;
  final String directorNationalityIso;
  final String styleCodename;
  final DsTacticalArchetype archetype;
  final DsStageTerrainFocus primaryTerrainFocus;
  final DsRiskToleranceLevel riskTolerance;
  final DsAdaptationSpeed adaptationSpeed;
  final String signatureMove;
  final String weaknessExploitHint;
  final String radioQuote;
  final DsTacticalTendencyProfile tendencies;
  final double scoutingConfidence;

  const DirectorSportifTacticalProfile({
    required this.teamId,
    required this.teamName,
    required this.division,
    required this.countryIso,
    required this.directorName,
    required this.directorNationalityIso,
    required this.styleCodename,
    required this.archetype,
    required this.primaryTerrainFocus,
    required this.riskTolerance,
    required this.adaptationSpeed,
    required this.signatureMove,
    required this.weaknessExploitHint,
    required this.radioQuote,
    required this.tendencies,
    this.scoutingConfidence = 0.85,
  });

  DirectorSportifTacticalProfile copyWith({
    String? teamId,
    String? teamName,
    TeamDivision? division,
    String? countryIso,
    String? directorName,
    String? directorNationalityIso,
    String? styleCodename,
    DsTacticalArchetype? archetype,
    DsStageTerrainFocus? primaryTerrainFocus,
    DsRiskToleranceLevel? riskTolerance,
    DsAdaptationSpeed? adaptationSpeed,
    String? signatureMove,
    String? weaknessExploitHint,
    String? radioQuote,
    DsTacticalTendencyProfile? tendencies,
    double? scoutingConfidence,
  }) {
    return DirectorSportifTacticalProfile(
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      division: division ?? this.division,
      countryIso: countryIso ?? this.countryIso,
      directorName: directorName ?? this.directorName,
      directorNationalityIso:
          directorNationalityIso ?? this.directorNationalityIso,
      styleCodename: styleCodename ?? this.styleCodename,
      archetype: archetype ?? this.archetype,
      primaryTerrainFocus: primaryTerrainFocus ?? this.primaryTerrainFocus,
      riskTolerance: riskTolerance ?? this.riskTolerance,
      adaptationSpeed: adaptationSpeed ?? this.adaptationSpeed,
      signatureMove: signatureMove ?? this.signatureMove,
      weaknessExploitHint: weaknessExploitHint ?? this.weaknessExploitHint,
      radioQuote: radioQuote ?? this.radioQuote,
      tendencies: tendencies ?? this.tendencies,
      scoutingConfidence:
          (scoutingConfidence ?? this.scoutingConfidence).clamp(0.1, 1.0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'teamId': teamId,
      'teamName': teamName,
      'division': division.toJson(),
      'countryIso': countryIso,
      'directorName': directorName,
      'directorNationalityIso': directorNationalityIso,
      'styleCodename': styleCodename,
      'archetype': archetype.toJson(),
      'primaryTerrainFocus': primaryTerrainFocus.toJson(),
      'riskTolerance': riskTolerance.toJson(),
      'adaptationSpeed': adaptationSpeed.toJson(),
      'signatureMove': signatureMove,
      'weaknessExploitHint': weaknessExploitHint,
      'radioQuote': radioQuote,
      'tendencies': tendencies.toJson(),
      'scoutingConfidence': scoutingConfidence,
    };
  }

  factory DirectorSportifTacticalProfile.fromJson(Map<String, dynamic> json) {
    return DirectorSportifTacticalProfile(
      teamId: json['teamId'] as String? ?? 'unknown_team',
      teamName: json['teamName'] as String? ?? 'Unknown Team',
      division: TeamDivision.fromJson(json['division'] as String? ?? 'proTeam'),
      countryIso: json['countryIso'] as String? ?? 'INT',
      directorName: json['directorName'] as String? ?? 'Director Sportif',
      directorNationalityIso:
          json['directorNationalityIso'] as String? ?? 'INT',
      styleCodename: json['styleCodename'] as String? ?? 'Klasyczny Styl',
      archetype:
          DsTacticalArchetype.fromJson(json['archetype'] as String? ?? ''),
      primaryTerrainFocus: DsStageTerrainFocus.fromJson(
        json['primaryTerrainFocus'] as String? ?? '',
      ),
      riskTolerance: DsRiskToleranceLevel.fromJson(
        json['riskTolerance'] as String? ?? '',
      ),
      adaptationSpeed: DsAdaptationSpeed.fromJson(
        json['adaptationSpeed'] as String? ?? '',
      ),
      signatureMove: json['signatureMove'] as String? ?? '',
      weaknessExploitHint: json['weaknessExploitHint'] as String? ?? '',
      radioQuote: json['radioQuote'] as String? ?? '',
      tendencies: DsTacticalTendencyProfile.fromJson(
        (json['tendencies'] as Map<String, dynamic>?) ?? const {},
      ),
      scoutingConfidence:
          (json['scoutingConfidence'] as num?)?.toDouble() ?? 0.85,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DirectorSportifTacticalProfile &&
        other.teamId == teamId &&
        other.directorName == directorName &&
        other.styleCodename == styleCodename &&
        other.archetype == archetype &&
        other.tendencies == tendencies;
  }

  @override
  int get hashCode =>
      Object.hash(teamId, directorName, styleCodename, archetype, tendencies);
}

/// Kontekst etapu wykorzystywany do prognozowania decyzji DS AI.
class StageTacticalContextInput {
  final String stageName;
  final DsStageTerrainFocus terrain;
  final double distanceKm;
  final double remainingKm;
  final double crosswindKmh;
  final int elevationGainM;
  final bool isGrandTour;
  final bool hasCobbleSectors;
  final double leaderGcGapSeconds;
  final bool rivalInBreakawayThreat;

  const StageTacticalContextInput({
    required this.stageName,
    required this.terrain,
    required this.distanceKm,
    required this.remainingKm,
    required this.crosswindKmh,
    required this.elevationGainM,
    this.isGrandTour = false,
    this.hasCobbleSectors = false,
    this.leaderGcGapSeconds = 0.0,
    this.rivalInBreakawayThreat = false,
  });

  Map<String, dynamic> toJson() => {
        'stageName': stageName,
        'terrain': terrain.toJson(),
        'distanceKm': distanceKm,
        'remainingKm': remainingKm,
        'crosswindKmh': crosswindKmh,
        'elevationGainM': elevationGainM,
        'isGrandTour': isGrandTour,
        'hasCobbleSectors': hasCobbleSectors,
        'leaderGcGapSeconds': leaderGcGapSeconds,
        'rivalInBreakawayThreat': rivalInBreakawayThreat,
      };

  factory StageTacticalContextInput.fromJson(Map<String, dynamic> json) {
    return StageTacticalContextInput(
      stageName: json['stageName'] as String? ?? 'Etap',
      terrain: DsStageTerrainFocus.fromJson(json['terrain'] as String? ?? ''),
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 175.0,
      remainingKm: (json['remainingKm'] as num?)?.toDouble() ?? 175.0,
      crosswindKmh: (json['crosswindKmh'] as num?)?.toDouble() ?? 12.0,
      elevationGainM: (json['elevationGainM'] as num?)?.toInt() ?? 1400,
      isGrandTour: json['isGrandTour'] as bool? ?? false,
      hasCobbleSectors: json['hasCobbleSectors'] as bool? ?? false,
      leaderGcGapSeconds:
          (json['leaderGcGapSeconds'] as num?)?.toDouble() ?? 0.0,
      rivalInBreakawayThreat: json['rivalInBreakawayThreat'] as bool? ?? false,
    );
  }
}

/// Prognoza planu taktycznego drużyny AI na konkretny etap.
class DsStageTacticalPlan {
  final String teamId;
  final String teamName;
  final String directorName;
  final String styleCodename;
  final DsTacticalArchetype archetype;
  final double recommendedTempoPctFtp;
  final double sendBreakawayProbability;
  final double chaseBreakawayProbability;
  final double echelonAmbushProbability;
  final double sprintTrainActivationKm;
  final double plannedAttackKmToGo;
  final int domestiquesCommittedToPace;
  final String primaryObjectiveLabel;
  final String tacticalAlertSummary;
  final String counterStrategyTip;

  const DsStageTacticalPlan({
    required this.teamId,
    required this.teamName,
    required this.directorName,
    required this.styleCodename,
    required this.archetype,
    required this.recommendedTempoPctFtp,
    required this.sendBreakawayProbability,
    required this.chaseBreakawayProbability,
    required this.echelonAmbushProbability,
    required this.sprintTrainActivationKm,
    required this.plannedAttackKmToGo,
    required this.domestiquesCommittedToPace,
    required this.primaryObjectiveLabel,
    required this.tacticalAlertSummary,
    required this.counterStrategyTip,
  });

  double get threatScore {
    return (sendBreakawayProbability * 0.25 +
            chaseBreakawayProbability * 0.25 +
            echelonAmbushProbability * 0.25 +
            (recommendedTempoPctFtp / 100.0) * 0.25)
        .clamp(0.0, 1.0);
  }
}

/// Zbiorczy raport taktyczny całego peletonu (52 drużyny AI) przed etapem.
class PelotonTacticalMatchupReport {
  final String playerTeamId;
  final int rivalTeamCount;
  final Map<DsTacticalArchetype, int> archetypeDistribution;
  final List<DsStageTacticalPlan> topThreatPlans;
  final List<String> expectedBreakawayTeams;
  final List<String> expectedChaseTeams;
  final List<String> expectedEchelonInstigators;

  const PelotonTacticalMatchupReport({
    required this.playerTeamId,
    required this.rivalTeamCount,
    required this.archetypeDistribution,
    required this.topThreatPlans,
    required this.expectedBreakawayTeams,
    required this.expectedChaseTeams,
    required this.expectedEchelonInstigators,
  });
}

/// Silnik unikalnych stylów taktycznych dyrektorów sportowych wszystkich 52 drużyn AI.
class AiDirectorSportifTacticalStylesEngine {
  AiDirectorSportifTacticalStylesEngine._();

  static const int standardAiTeamCount = 52;
  static const int totalPresetTeamCount = 53;

  /// Pełny rejestr 53 unikalnych profili DS (18 WT + 15 ProTeam + 20 Continental).
  /// Po wykluczeniu drużyny gracza pozostaje dokładnie 52 drużyn AI.
  static final List<DirectorSportifTacticalProfile> _presetProfiles =
      List<DirectorSportifTacticalProfile>.unmodifiable([
    // =========================================================================
    // WORLDTOUR (18 drużyn)
    // =========================================================================
    const DirectorSportifTacticalProfile(
      teamId: 'team_aethel_ineos',
      teamName: 'Aethel Royal Grenadiers',
      division: TeamDivision.worldTour,
      countryIso: 'GBR',
      directorName: 'Sir Gareth Brailsford-Vance',
      directorNationalityIso: 'GBR',
      styleCodename: 'Żelazny Metronom W/kg',
      archetype: DsTacticalArchetype.skyTrainControl,
      primaryTerrainFocus: DsStageTerrainFocus.highMountain,
      riskTolerance: DsRiskToleranceLevel.conservative,
      adaptationSpeed: DsAdaptationSpeed.methodical,
      signatureMove:
          'Ustawienie 5 pomocników na czele u podnóża finałowego podjazdu na 92% FTP i bezlitosne kasowanie każdego skoku.',
      weaknessExploitHint:
          'Zaatakuj na zjeździe przed ostatnią górą lub wykorzystaj wiatr boczny przed podjazdem, zanim ustawią pociąg.',
      radioQuote: 'Trzymajcie 410 watów równo, nikt nie wychodzi przed szereg.',
      tendencies: DsTacticalTendencyProfile(
        breakawayAppetite: 0.18,
        pelotonChaseAggression: 0.88,
        mountainPaceTrainIntensity: 0.96,
        crosswindEchelonTrigger: 0.62,
        sprintLeadoutCommitment: 0.25,
        satelliteRelayFrequency: 0.35,
        lateAttackDistanceKm: 4.5,
        riskAppetite: 0.24,
        bluffingAndPokerFaceBias: 0.32,
        gcProtectionThresholdMin: 2.0,
      ),
    ),
    const DirectorSportifTacticalProfile(
      teamId: 'team_veloce_santander',
      teamName: 'Veloce-Santander Corsa',
      division: TeamDivision.worldTour,
      countryIso: 'ITA',
      directorName: 'Lorenzo Bellini',
      directorNationalityIso: 'ITA',
      styleCodename: 'Mediolańska Furia na Zjazdach',
      archetype: DsTacticalArchetype.counterPunchSniper,
      primaryTerrainFocus: DsStageTerrainFocus.hillyPuncheur,
      riskTolerance: DsRiskToleranceLevel.aggressive,
      adaptationSpeed: DsAdaptationSpeed.reactive,
      signatureMove:
          'Oszczędzanie lidera w środku peletonu przez 180 km i błyskawiczny cios na ostatnich 1800 m oraz technicznych serpentynach.',
      weaknessExploitHint:
          'Narzuć wysokie tempo już na przedostatniej premii górskiej, by pozbawić ich snajpera świeżości w końcówce.',
      radioQuote: 'Czekaj na ostatni zakręt w lewo — tam zrzucisz im łańcuch!',
      tendencies: DsTacticalTendencyProfile(
        breakawayAppetite: 0.42,
        pelotonChaseAggression: 0.58,
        mountainPaceTrainIntensity: 0.54,
        crosswindEchelonTrigger: 0.48,
        sprintLeadoutCommitment: 0.66,
        satelliteRelayFrequency: 0.40,
        lateAttackDistanceKm: 2.2,
        riskAppetite: 0.72,
        bluffingAndPokerFaceBias: 0.78,
        gcProtectionThresholdMin: 3.0,
      ),
    ),
    const DirectorSportifTacticalProfile(
      teamId: 'team_kronos_swiss',
      teamName: 'Kronos Precision Velo',
      division: TeamDivision.worldTour,
      countryIso: 'SUI',
      directorName: 'Fabian Meier-Keller',
      directorNationalityIso: 'SUI',
      styleCodename: 'Szwajcarski Chronometr',
      archetype: DsTacticalArchetype.skyTrainControl,
      primaryTerrainFocus: DsStageTerrainFocus.timeTrial,
      riskTolerance: DsRiskToleranceLevel.calculated,
      adaptationSpeed: DsAdaptationSpeed.rigid,
      signatureMove:
          'Jazda ściśle według krzywej mleczanowej i stratyfikacja podjazdów pod maksymalne zyski w ITT.',
      weaknessExploitHint:
          'Wprowadź chaos nieregularnymi zmianami tempa (rwane ataki co 90 sekund) na stromych ściankach.',
      radioQuote: 'Kadencja 94, tętno w strefie 4b. Ani wata więcej.',
      tendencies: DsTacticalTendencyProfile(
        breakawayAppetite: 0.22,
        pelotonChaseAggression: 0.74,
        mountainPaceTrainIntensity: 0.84,
        crosswindEchelonTrigger: 0.55,
        sprintLeadoutCommitment: 0.30,
        satelliteRelayFrequency: 0.28,
        lateAttackDistanceKm: 5.0,
        riskAppetite: 0.28,
        bluffingAndPokerFaceBias: 0.20,
        gcProtectionThresholdMin: 2.5,
      ),
    ),
    const DirectorSportifTacticalProfile(
      teamId: 'team_zenith_usa',
      teamName: 'Zenith-Apex Silicon Valley',
      division: TeamDivision.worldTour,
      countryIso: 'USA',
      directorName: 'Marcus Vance-Sterling',
      directorNationalityIso: 'USA',
      styleCodename: 'Algorytm Watt-Bomb',
      archetype: DsTacticalArchetype.totalAttackChaos,
      primaryTerrainFocus: DsStageTerrainFocus.allRounder,
      riskTolerance: DsRiskToleranceLevel.aggressive,
      adaptationSpeed: DsAdaptationSpeed.reactive,
      signatureMove:
          'Wykorzystanie analizy telemetrii rywali w czasie rzeczywistym do odpalenia bomby watowej 35 km przed metą.',
      weaknessExploitHint:
          'Nie goń pierwszego zrywu w pojedynkę — zawiąż koalicję z drużynami sprinterskimi lub GC.',
      radioQuote: 'Model pokazuje kryzys u rywala. Pełny gaz przez 4 minuty!',
      tendencies: DsTacticalTendencyProfile(
        breakawayAppetite: 0.64,
        pelotonChaseAggression: 0.70,
        mountainPaceTrainIntensity: 0.78,
        crosswindEchelonTrigger: 0.74,
        sprintLeadoutCommitment: 0.52,
        satelliteRelayFrequency: 0.76,
        lateAttackDistanceKm: 36.0,
        riskAppetite: 0.84,
        bluffingAndPokerFaceBias: 0.65,
        gcProtectionThresholdMin: 2.8,
      ),
    ),
    const DirectorSportifTacticalProfile(
      teamId: 'team_sovereign_ger',
      teamName: 'Sovereign-Lufthansa Team',
      division: TeamDivision.worldTour,
      countryIso: 'GER',
      directorName: 'Rolf Aldag-Weber',
      directorNationalityIso: 'GER',
      styleCodename: 'Autostrada Sprinterska',
      archetype: DsTacticalArchetype.sprintLeadoutMachine,
      primaryTerrainFocus: DsStageTerrainFocus.flatSprint,
      riskTolerance: DsRiskToleranceLevel.calculated,
      adaptationSpeed: DsAdaptationSpeed.methodical,
      signatureMove:
          'Dwukilometrowa formacja pociągu z trzema rozprowadzającymi powyżej 64 km/h i perfekcyjną procą na 220 m.',
      weaknessExploitHint:
          'Zniszcz ich pociąg, atakując na rondach 4 km przed metą lub zamykając wewnętrzną linię na wietrze.',
      radioQuote: 'Pociąg na lewej krawędzi! Nikt nie może wbić się między 2. a 3. koło!',
      tendencies: DsTacticalTendencyProfile(
        breakawayAppetite: 0.20,
        pelotonChaseAggression: 0.94,
        mountainPaceTrainIntensity: 0.34,
        crosswindEchelonTrigger: 0.68,
        sprintLeadoutCommitment: 0.97,
        satelliteRelayFrequency: 0.22,
        lateAttackDistanceKm: 1.5,
        riskAppetite: 0.45,
        bluffingAndPokerFaceBias: 0.28,
        gcProtectionThresholdMin: 4.5,
      ),
    ),
    const DirectorSportifTacticalProfile(
      teamId: 'team_nordic_nor',
      teamName: 'Nordic-Equinor Arctic Squad',
      division: TeamDivision.worldTour,
      countryIso: 'NOR',
      directorName: 'Thorstein Hushovd-Vik',
      directorNationalityIso: 'NOR',
      styleCodename: 'Fiordowy Szkwał Bocznych Wiatrów',
      archetype: DsTacticalArchetype.echelonCrosswindHunters,
      primaryTerrainFocus: DsStageTerrainFocus.cobblesClassic,
      riskTolerance: DsRiskToleranceLevel.aggressive,
      adaptationSpeed: DsAdaptationSpeed.reactive,
      signatureMove:
          'Natychmiastowe formowanie wachlarza przy wietrze >18 km/h i spychanie lekkich górali pod krawężnik.',
      weaknessExploitHint:
          'Ustaw swoich kolarzy w TOP 15 peletonu przed każdym odsłoniętym odcinkiem wybrzeża.',
      radioQuote: 'Wiatr z prawej! Zamykamy wachlarz, zostawić tylko ośmiu z przodu!',
      tendencies: DsTacticalTendencyProfile(
        breakawayAppetite: 0.56,
        pelotonChaseAggression: 0.78,
        mountainPaceTrainIntensity: 0.48,
        crosswindEchelonTrigger: 0.96,
        sprintLeadoutCommitment: 0.72,
        satelliteRelayFrequency: 0.44,
        lateAttackDistanceKm: 28.0,
        riskAppetite: 0.80,
        bluffingAndPokerFaceBias: 0.42,
        gcProtectionThresholdMin: 3.5,
      ),
    ),
    const DirectorSportifTacticalProfile(
      teamId: 'team_flanders_vektor',
      teamName: 'Flanders-AeroVektor Lotto',
      division: TeamDivision.worldTour,
      countryIso: 'BEL',
      directorName: 'Dirk Van Der Bruggen',
      directorNationalityIso: 'BEL',
      styleCodename: 'Wataha z Flandrii',
      archetype: DsTacticalArchetype.cobblesAndClassicsBrawler,
      primaryTerrainFocus: DsStageTerrainFocus.cobblesClassic,
      riskTolerance: DsRiskToleranceLevel.reckless,
      adaptationSpeed: DsAdaptationSpeed.improvisational,
      signatureMove:
          'Wielokrotne ataki parami na 45–60 km przed metą brukowanych klasyków, zmuszające rywali do gonitwy.',
      weaknessExploitHint:
          'Nie reaguj na pierwszego harcownika — pilnuj bezpośrednio ich głównego lidera na najcięższych sektorach.',
      radioQuote: 'Na Muurze idziecie obaj! Jeśli usiądą na kole, kontruje trzeci!',
      tendencies: DsTacticalTendencyProfile(
        breakawayAppetite: 0.74,
        pelotonChaseAggression: 0.72,
        mountainPaceTrainIntensity: 0.42,
        crosswindEchelonTrigger: 0.88,
        sprintLeadoutCommitment: 0.68,
        satelliteRelayFrequency: 0.60,
        lateAttackDistanceKm: 48.0,
        riskAppetite: 0.91,
        bluffingAndPokerFaceBias: 0.62,
        gcProtectionThresholdMin: 4.0,
      ),
    ),
    const DirectorSportifTacticalProfile(
      teamId: 'team_kuraudo_jpn',
      teamName: 'Kuraudo-Toyota Racing Team',
      division: TeamDivision.worldTour,
      countryIso: 'JPN',
      directorName: 'Kenji Takahashi',
      directorNationalityIso: 'JPN',
      styleCodename: 'Dyscyplina Kaizen',
      archetype: DsTacticalArchetype.breakawayOpportunists,
      primaryTerrainFocus: DsStageTerrainFocus.hillyPuncheur,
      riskTolerance: DsRiskToleranceLevel.calculated,
      adaptationSpeed: DsAdaptationSpeed.methodical,
      signatureMove:
          'Perfekcyjne rotacje w ucieczce dnia z matematycznie wyliczonym bilansem glikogenu i żeli.',
      weaknessExploitHint:
          'Wciągnij ich w szarpaną jazdę w ucieczce — nie lubią nieprzewidywalnych przyspieszeń przed premiami.',
      radioQuote: 'Zmiana co 25 sekund, równe 370 watów. Cel: utrzymać 3 minuty do podjazdu.',
      tendencies: DsTacticalTendencyProfile(
        breakawayAppetite: 0.86,
        pelotonChaseAggression: 0.45,
        mountainPaceTrainIntensity: 0.56,
        crosswindEchelonTrigger: 0.50,
        sprintLeadoutCommitment: 0.62,
        satelliteRelayFrequency: 0.58,
        lateAttackDistanceKm: 14.0,
        riskAppetite: 0.55,
        bluffingAndPokerFaceBias: 0.35,
        gcProtectionThresholdMin: 4.2,
      ),
    ),
    const DirectorSportifTacticalProfile(
      teamId: 'team_ventus_ned',
      teamName: 'Ventus-Jumbo Wind Power',
      division: TeamDivision.worldTour,
      countryIso: 'NED',
      directorName: 'Merijn Zeeman-Brouwer',
      directorNationalityIso: 'NED',
      styleCodename: 'Totalny Blok Wielotorowy',
      archetype: DsTacticalArchetype.mountainAmbushRelay,
      primaryTerrainFocus: DsStageTerrainFocus.highMountain,
      riskTolerance: DsRiskToleranceLevel.aggressive,
      adaptationSpeed: DsAdaptationSpeed.reactive,
      signatureMove:
          'Wysyłanie dwóch górali do porannej ucieczki jako stacji przekaźnikowych dla lidera na przedostatniej przełęczy.',
      weaknessExploitHint:
          'Blokuj ich pomocników już w pierwszych 15 km etapu, aby żaden nie wszedł do odjazdu.',
      radioQuote: 'Zostawcie ucieczkę na szczycie i czekajcie w dolinie na lidera!',
      tendencies: DsTacticalTendencyProfile(
        breakawayAppetite: 0.52,
        pelotonChaseAggression: 0.82,
        mountainPaceTrainIntensity: 0.90,
        crosswindEchelonTrigger: 0.85,
        sprintLeadoutCommitment: 0.64,
        satelliteRelayFrequency: 0.95,
        lateAttackDistanceKm: 24.0,
        riskAppetite: 0.78,
        bluffingAndPokerFaceBias: 0.54,
        gcProtectionThresholdMin: 1.8,
      ),
    ),
    const DirectorSportifTacticalProfile(
      teamId: 'team_corsa_armani',
      teamName: 'Corsa d\'Oro-Armani Squadra',
      division: TeamDivision.worldTour,
      countryIso: 'ITA',
      directorName: 'Gianni Savio-Conti',
      directorNationalityIso: 'ITA',
      styleCodename: 'Teatr Złotego Kontrataku',
      archetype: DsTacticalArchetype.komPolkaHunter,
      primaryTerrainFocus: DsStageTerrainFocus.highMountain,
      riskTolerance: DsRiskToleranceLevel.aggressive,
      adaptationSpeed: DsAdaptationSpeed.improvisational,
      signatureMove:
          'Polowanie na każdą premię górską z jednoczesnym blefowaniem kryzysu na stromych rampach.',
      weaknessExploitHint:
          'Nie daj się zwieść opuszczonej głowie ich lidera — często symuluje zmęczenie przed atakiem.',
      radioQuote: 'Pokaż zmęczenie do kamery, a za zakrętem odpal na 1100 watów!',
      tendencies: DsTacticalTendencyProfile(
        breakawayAppetite: 0.80,
        pelotonChaseAggression: 0.42,
        mountainPaceTrainIntensity: 0.60,
        crosswindEchelonTrigger: 0.38,
        sprintLeadoutCommitment: 0.45,
        satelliteRelayFrequency: 0.62,
        lateAttackDistanceKm: 11.0,
        riskAppetite: 0.82,
        bluffingAndPokerFaceBias: 0.92,
        gcProtectionThresholdMin: 3.8,
      ),
    ),
    const DirectorSportifTacticalProfile(
      teamId: 'team_gripmax_fra',
      teamName: 'GripMax-Michelin Velosport',
      division: TeamDivision.worldTour,
      countryIso: 'FRA',
      directorName: 'Marc Madiot-Delacroix',
      directorNationalityIso: 'FRA',
      styleCodename: 'Francuski Panache',
      archetype: DsTacticalArchetype.totalAttackChaos,
      primaryTerrainFocus: DsStageTerrainFocus.hillyPuncheur,
      riskTolerance: DsRiskToleranceLevel.reckless,
      adaptationSpeed: DsAdaptationSpeed.improvisational,
      signatureMove:
          'Szaleńcze ataki w dniu narodowym lub na średnich górach na 55 km przed metą ku uciesze kibiców.',
      weaknessExploitHint:
          'Utrzymaj chłodną głowę i równe tempo peletonu — ich zrywy często wypalają się przed ostatnim podjazdem.',
      radioQuote: 'Allez! Nie patrz na waty, jedź sercem! Francja patrzy!',
      tendencies: DsTacticalTendencyProfile(
        breakawayAppetite: 0.88,
        pelotonChaseAggression: 0.54,
        mountainPaceTrainIntensity: 0.58,
        crosswindEchelonTrigger: 0.64,
        sprintLeadoutCommitment: 0.55,
        satelliteRelayFrequency: 0.50,
        lateAttackDistanceKm: 52.0,
        riskAppetite: 0.94,
        bluffingAndPokerFaceBias: 0.45,
        gcProtectionThresholdMin: 3.5,
      ),
    ),
    const DirectorSportifTacticalProfile(
      teamId: 'team_silvan_esp',
      teamName: 'Silvan-Euskadi Iberia',
      division: TeamDivision.worldTour,
      countryIso: 'ESP',
      directorName: 'Patxi Vila-Arregi',
      directorNationalityIso: 'ESP',
      styleCodename: 'Pirenejska Karuzela',
      archetype: DsTacticalArchetype.mountainAmbushRelay,
      primaryTerrainFocus: DsStageTerrainFocus.highMountain,
      riskTolerance: DsRiskToleranceLevel.aggressive,
      adaptationSpeed: DsAdaptationSpeed.reactive,
      signatureMove:
          'Równoczesne skoki dwóch górali na 12% rampach, zmuszające lidera GC do wyboru, za kim gonić.',
      weaknessExploitHint:
          'Zostaw mniej groźnego w klasyfikacji generalnej kolarza i sklejaj koło wyłącznie głównego lidera.',
      radioQuote: 'Jeden z lewej, drugi z prawej! Niech sami się ugotują!',
      tendencies: DsTacticalTendencyProfile(
        breakawayAppetite: 0.72,
        pelotonChaseAggression: 0.60,
        mountainPaceTrainIntensity: 0.82,
        crosswindEchelonTrigger: 0.34,
        sprintLeadoutCommitment: 0.22,
        satelliteRelayFrequency: 0.86,
        lateAttackDistanceKm: 18.0,
        riskAppetite: 0.79,
        bluffingAndPokerFaceBias: 0.58,
        gcProtectionThresholdMin: 2.4,
      ),
    ),
    const DirectorSportifTacticalProfile(
      teamId: 'team_apex_aus',
      teamName: 'Apex-Qantas Pacific Velocity',
      division: TeamDivision.worldTour,
      countryIso: 'AUS',
      directorName: 'Matthew White-O\'Connor',
      directorNationalityIso: 'AUS',
      styleCodename: 'Antypodzki Pociąg Prędkości',
      archetype: DsTacticalArchetype.sprintLeadoutMachine,
      primaryTerrainFocus: DsStageTerrainFocus.flatSprint,
      riskTolerance: DsRiskToleranceLevel.calculated,
      adaptationSpeed: DsAdaptationSpeed.reactive,
      signatureMove:
          'Późne, niezwykle szybkie podprowadzenie sprintera z głębi grupy na ostatnich 1500 m.',
      weaknessExploitHint:
          'Zajmij środek szosy przed ostatnim kilometrem, aby odciąć ich pilota od otwartej przestrzeni.',
      radioQuote: 'Czekaj do tablicy 800 m, potem odpalajcie na pełnej linii!',
      tendencies: DsTacticalTendencyProfile(
        breakawayAppetite: 0.44,
        pelotonChaseAggression: 0.85,
        mountainPaceTrainIntensity: 0.50,
        crosswindEchelonTrigger: 0.78,
        sprintLeadoutCommitment: 0.91,
        satelliteRelayFrequency: 0.38,
        lateAttackDistanceKm: 1.8,
        riskAppetite: 0.62,
        bluffingAndPokerFaceBias: 0.40,
        gcProtectionThresholdMin: 3.6,
      ),
    ),
    const DirectorSportifTacticalProfile(
      teamId: 'team_boreas_den',
      teamName: 'Boreas-Maersk Nordic Line',
      division: TeamDivision.worldTour,
      countryIso: 'DEN',
      directorName: 'Bjarne Riis-Lindholm',
      directorNationalityIso: 'DEN',
      styleCodename: 'Duński Krawężnik Północy',
      archetype: DsTacticalArchetype.echelonCrosswindHunters,
      primaryTerrainFocus: DsStageTerrainFocus.allRounder,
      riskTolerance: DsRiskToleranceLevel.aggressive,
      adaptationSpeed: DsAdaptationSpeed.methodical,
      signatureMove:
          'Zaplanowane z wyprzedzeniem ataki na otwartych równinach i bezwzględna jazda w rynsztoku.',
      weaknessExploitHint:
          'Sprawdź prognozę wiatru na 30 km przed metą — jeśli wieje z boku, trzymaj cały skład w pierwszej dwudziestce.',
      radioQuote: 'Za 2 km zjazd w prawo na otwarte pola. Cała ósemka na czoło!',
      tendencies: DsTacticalTendencyProfile(
        breakawayAppetite: 0.58,
        pelotonChaseAggression: 0.80,
        mountainPaceTrainIntensity: 0.70,
        crosswindEchelonTrigger: 0.94,
        sprintLeadoutCommitment: 0.58,
        satelliteRelayFrequency: 0.65,
        lateAttackDistanceKm: 32.0,
        riskAppetite: 0.81,
        bluffingAndPokerFaceBias: 0.48,
        gcProtectionThresholdMin: 2.5,
      ),
    ),
    const DirectorSportifTacticalProfile(
      teamId: 'team_alpina_aut',
      teamName: 'Alpina-RedBull Energy Velo',
      division: TeamDivision.worldTour,
      countryIso: 'AUT',
      directorName: 'Bernhard Eisel-Gruber',
      directorNationalityIso: 'AUT',
      styleCodename: 'Alpejski Sprint Pod Górę',
      archetype: DsTacticalArchetype.counterPunchSniper,
      primaryTerrainFocus: DsStageTerrainFocus.highMountain,
      riskTolerance: DsRiskToleranceLevel.aggressive,
      adaptationSpeed: DsAdaptationSpeed.reactive,
      signatureMove:
          'Agresywna selekcja pomocnikami na przedostatniej górze i atomowy finisz na szczycie.',
      weaknessExploitHint:
          'Zmuś ich do pracy już 50 km przed metą — mają potężnych liderów, ale krótszą ławkę na płaskim.',
      radioQuote: 'Ostatnie 900 metrów to nasza strefa. Złamcie im morale przyspieszeniem!',
      tendencies: DsTacticalTendencyProfile(
        breakawayAppetite: 0.48,
        pelotonChaseAggression: 0.76,
        mountainPaceTrainIntensity: 0.86,
        crosswindEchelonTrigger: 0.58,
        sprintLeadoutCommitment: 0.60,
        satelliteRelayFrequency: 0.55,
        lateAttackDistanceKm: 3.0,
        riskAppetite: 0.75,
        bluffingAndPokerFaceBias: 0.52,
        gcProtectionThresholdMin: 2.2,
      ),
    ),
    const DirectorSportifTacticalProfile(
      teamId: 'team_oranje_ned',
      teamName: 'Oranje-Heineken Classic Velo',
      division: TeamDivision.worldTour,
      countryIso: 'NED',
      directorName: 'Danny Nelissen-Bakker',
      directorNationalityIso: 'NED',
      styleCodename: 'Pomarańczowa Ofensywa Amstel',
      archetype: DsTacticalArchetype.cobblesAndClassicsBrawler,
      primaryTerrainFocus: DsStageTerrainFocus.hillyPuncheur,
      riskTolerance: DsRiskToleranceLevel.aggressive,
      adaptationSpeed: DsAdaptationSpeed.improvisational,
      signatureMove:
          'Nieustanne skoki na wąskich holenderskich i ardeńskich drogach pełnych zakrętów 90°.',
      weaknessExploitHint:
          'Zabezpiecz czoło przed serią ciasnych zakrętów — wykorzystują efekt akordeonu do zrywania peletonu.',
      radioQuote: 'Po każdym zakręcie 800 watów przez 10 sekund — z tyłu pękną!',
      tendencies: DsTacticalTendencyProfile(
        breakawayAppetite: 0.70,
        pelotonChaseAggression: 0.68,
        mountainPaceTrainIntensity: 0.46,
        crosswindEchelonTrigger: 0.86,
        sprintLeadoutCommitment: 0.74,
        satelliteRelayFrequency: 0.52,
        lateAttackDistanceKm: 26.0,
        riskAppetite: 0.85,
        bluffingAndPokerFaceBias: 0.50,
        gcProtectionThresholdMin: 3.8,
      ),
    ),
    const DirectorSportifTacticalProfile(
      teamId: 'team_bavaria_ger',
      teamName: 'Canyon-Bavaria Motors',
      division: TeamDivision.worldTour,
      countryIso: 'GER',
      directorName: 'Christian Pömer-Kohl',
      directorNationalityIso: 'GER',
      styleCodename: 'Bawarska Turbina Aero',
      archetype: DsTacticalArchetype.skyTrainControl,
      primaryTerrainFocus: DsStageTerrainFocus.timeTrial,
      riskTolerance: DsRiskToleranceLevel.calculated,
      adaptationSpeed: DsAdaptationSpeed.methodical,
      signatureMove:
          'Aero-dyscyplina w peletonie, minimalizacja strat wiatru i chirurgiczna kontrola pościgu.',
      weaknessExploitHint:
          'Wciągnij ich w strome górskie etapy o niskiej prędkości, gdzie przewaga aero traci znaczenie.',
      radioQuote: 'Głowy nisko, zwarta linia 67 km/h. Pożeramy ucieczkę co do sekundy.',
      tendencies: DsTacticalTendencyProfile(
        breakawayAppetite: 0.30,
        pelotonChaseAggression: 0.89,
        mountainPaceTrainIntensity: 0.74,
        crosswindEchelonTrigger: 0.76,
        sprintLeadoutCommitment: 0.82,
        satelliteRelayFrequency: 0.34,
        lateAttackDistanceKm: 6.0,
        riskAppetite: 0.40,
        bluffingAndPokerFaceBias: 0.25,
        gcProtectionThresholdMin: 2.6,
      ),
    ),
    const DirectorSportifTacticalProfile(
      teamId: 'team_azur_fra',
      teamName: 'Azur-TotalEnergies France',
      division: TeamDivision.worldTour,
      countryIso: 'FRA',
      directorName: 'Jean-René Bernaudeau-Morel',
      directorNationalityIso: 'FRA',
      styleCodename: 'Lazurowy Korsarz Etapowy',
      archetype: DsTacticalArchetype.breakawayOpportunists,
      primaryTerrainFocus: DsStageTerrainFocus.hillyPuncheur,
      riskTolerance: DsRiskToleranceLevel.reckless,
      adaptationSpeed: DsAdaptationSpeed.improvisational,
      signatureMove:
          'Obowiązkowa obecność dwóch zawodników w każdej ucieczce dnia i ataki pod wiatr.',
      weaknessExploitHint:
          'Pozwól im prowadzić ucieczkę na płaskim — zmęczą się jeszcze przed finałowymi podjazdami.',
      radioQuote: 'Bez naszego stroju w odjeździe nie macie po co wracać do autobusu!',
      tendencies: DsTacticalTendencyProfile(
        breakawayAppetite: 0.94,
        pelotonChaseAggression: 0.32,
        mountainPaceTrainIntensity: 0.44,
        crosswindEchelonTrigger: 0.56,
        sprintLeadoutCommitment: 0.48,
        satelliteRelayFrequency: 0.64,
        lateAttackDistanceKm: 42.0,
        riskAppetite: 0.89,
        bluffingAndPokerFaceBias: 0.60,
        gcProtectionThresholdMin: 5.0,
      ),
    ),

    // =========================================================================
    // PROTEAM (15 drużyn)
    // =========================================================================
    const DirectorSportifTacticalProfile(
      teamId: 'team_polonia_orlen',
      teamName: 'Polonia-Orlen Racing Team',
      division: TeamDivision.proTeam,
      countryIso: 'POL',
      directorName: 'Piotr Wadecki-Kowalski',
      directorNationalityIso: 'POL',
      styleCodename: 'Husaria Kontrataku',
      archetype: DsTacticalArchetype.breakawayOpportunists,
      primaryTerrainFocus: DsStageTerrainFocus.hillyPuncheur,
      riskTolerance: DsRiskToleranceLevel.aggressive,
      adaptationSpeed: DsAdaptationSpeed.reactive,
      signatureMove:
          'Zgrany tandem dwóch Polaków w ucieczce, gdzie jeden poświęca się dla finałowego ciosu drugiego.',
      weaknessExploitHint:
          'Rozdziel ich na zjeździe lub zmuś do gonitwy przed decydującą ścianką.',
      radioQuote: 'Zostaw go na kole, teraz idziesz po etap na pełnym gazie!',
      tendencies: DsTacticalTendencyProfile(
        breakawayAppetite: 0.90,
        pelotonChaseAggression: 0.48,
        mountainPaceTrainIntensity: 0.52,
        crosswindEchelonTrigger: 0.66,
        sprintLeadoutCommitment: 0.56,
        satelliteRelayFrequency: 0.60,
        lateAttackDistanceKm: 16.0,
        riskAppetite: 0.82,
        bluffingAndPokerFaceBias: 0.55,
        gcProtectionThresholdMin: 4.5,
      ),
    ),
    const DirectorSportifTacticalProfile(
      teamId: 'team_bravia_swe',
      teamName: 'Bravia-PostNord Velo',
      division: TeamDivision.proTeam,
      countryIso: 'SWE',
      directorName: 'Magnus Bäckstedt-Lind',
      directorNationalityIso: 'SWE',
      styleCodename: 'Skandynawski Lodołamacz',
      archetype: DsTacticalArchetype.echelonCrosswindHunters,
      primaryTerrainFocus: DsStageTerrainFocus.cobblesClassic,
      riskTolerance: DsRiskToleranceLevel.aggressive,
      adaptationSpeed: DsAdaptationSpeed.methodical,
      signatureMove:
          'Siłowe tempo w deszczu i chłodzie oraz rozbijanie grup na wietrznych płaskowyżach.',
      weaknessExploitHint:
          'W upalne dni powyżej 30°C ich ciężsi specjaliści od klasyków szybciej tracą moc na długich górach.',
      radioQuote: 'Im gorsza pogoda, tym lepiej dla nas. Ciśniemy na krawędzi!',
      tendencies: DsTacticalTendencyProfile(
        breakawayAppetite: 0.72,
        pelotonChaseAggression: 0.64,
        mountainPaceTrainIntensity: 0.36,
        crosswindEchelonTrigger: 0.92,
        sprintLeadoutCommitment: 0.62,
        satelliteRelayFrequency: 0.34,
        lateAttackDistanceKm: 30.0,
        riskAppetite: 0.76,
        bluffingAndPokerFaceBias: 0.30,
        gcProtectionThresholdMin: 5.0,
      ),
    ),
    const DirectorSportifTacticalProfile(
      teamId: 'team_euskadi_esp',
      teamName: 'Euskadi-Kutxabank Passion',
      division: TeamDivision.proTeam,
      countryIso: 'ESP',
      directorName: 'Jorge Azanza-Etxebarria',
      directorNationalityIso: 'ESP',
      styleCodename: 'Baskijski Duch Gór',
      archetype: DsTacticalArchetype.komPolkaHunter,
      primaryTerrainFocus: DsStageTerrainFocus.highMountain,
      riskTolerance: DsRiskToleranceLevel.reckless,
      adaptationSpeed: DsAdaptationSpeed.improvisational,
      signatureMove:
          'Ataki od pierwszego kilometra każdego etapu górskiego w pogoni za koszulką w grochy.',
      weaknessExploitHint:
          'Pozwól im wygrywać wczesne premie 3. kategorii — zużyją zapasy W\' przed finałem.',
      radioQuote: 'Pomarańczowe koszulki muszą być na szczycie pierwsze! Atakujemy od startu!',
      tendencies: DsTacticalTendencyProfile(
        breakawayAppetite: 0.92,
        pelotonChaseAggression: 0.28,
        mountainPaceTrainIntensity: 0.68,
        crosswindEchelonTrigger: 0.25,
        sprintLeadoutCommitment: 0.18,
        satelliteRelayFrequency: 0.68,
        lateAttackDistanceKm: 22.0,
        riskAppetite: 0.90,
        bluffingAndPokerFaceBias: 0.44,
        gcProtectionThresholdMin: 4.8,
      ),
    ),
    const DirectorSportifTacticalProfile(
      teamId: 'team_swiss_alps',
      teamName: 'Swiss-Alps PostAuto',
      division: TeamDivision.proTeam,
      countryIso: 'SUI',
      directorName: 'Michael Schär-Bühler',
      directorNationalityIso: 'SUI',
      styleCodename: 'Alpejska Precyzja Zjazdowa',
      archetype: DsTacticalArchetype.mountainAmbushRelay,
      primaryTerrainFocus: DsStageTerrainFocus.highMountain,
      riskTolerance: DsRiskToleranceLevel.calculated,
      adaptationSpeed: DsAdaptationSpeed.methodical,
      signatureMove:
          'Wykorzystywanie pozycji Supertuck na alpejskich serpentynach do łączenia z pomocnikiem w dolinie.',
      weaknessExploitHint:
          'Utrzymuj kontakt na szczycie przełęczy — na płaskim po zjeździe ich przewaga szybko topnieje.',
      radioQuote: 'Perfekcyjna linia wiraży i przejęcie koła w dolinie za 4 km.',
      tendencies: DsTacticalTendencyProfile(
        breakawayAppetite: 0.66,
        pelotonChaseAggression: 0.50,
        mountainPaceTrainIntensity: 0.64,
        crosswindEchelonTrigger: 0.46,
        sprintLeadoutCommitment: 0.34,
        satelliteRelayFrequency: 0.78,
        lateAttackDistanceKm: 19.0,
        riskAppetite: 0.58,
        bluffingAndPokerFaceBias: 0.36,
        gcProtectionThresholdMin: 3.4,
      ),
    ),
    const DirectorSportifTacticalProfile(
      teamId: 'team_bretagne_fra',
      teamName: 'Bretagne-Armorique Velo',
      division: TeamDivision.proTeam,
      countryIso: 'FRA',
      directorName: 'Emmanuel Hubert-Le Goff',
      directorNationalityIso: 'FRA',
      styleCodename: 'Bretania Bez Hamulców',
      archetype: DsTacticalArchetype.totalAttackChaos,
      primaryTerrainFocus: DsStageTerrainFocus.hillyPuncheur,
      riskTolerance: DsRiskToleranceLevel.reckless,
      adaptationSpeed: DsAdaptationSpeed.improvisational,
      signatureMove:
          'Wściekłe ataki na pagórkach i walka o czerwoną tabliczkę Najaktywniejszego Kolarza Etapu.',
      weaknessExploitHint:
          'Ich ucieczki często nie współpracują harmonijnie pod koniec — zaatakuj w momencie ich kłótni o zmiany.',
      radioQuote: 'Jedziemy po czerwony numer! Zero kalkulacji!',
      tendencies: DsTacticalTendencyProfile(
        breakawayAppetite: 0.95,
        pelotonChaseAggression: 0.36,
        mountainPaceTrainIntensity: 0.40,
        crosswindEchelonTrigger: 0.70,
        sprintLeadoutCommitment: 0.50,
        satelliteRelayFrequency: 0.45,
        lateAttackDistanceKm: 58.0,
        riskAppetite: 0.93,
        bluffingAndPokerFaceBias: 0.40,
        gcProtectionThresholdMin: 5.5,
      ),
    ),
    const DirectorSportifTacticalProfile(
      teamId: 'team_bogota_col',
      teamName: 'Bogota-Cafe de Colombia',
      division: TeamDivision.proTeam,
      countryIso: 'COL',
      directorName: 'Oliverio Rincón-Torres',
      directorNationalityIso: 'COL',
      styleCodename: 'Andyjscy Eskarabajos',
      archetype: DsTacticalArchetype.komPolkaHunter,
      primaryTerrainFocus: DsStageTerrainFocus.highMountain,
      riskTolerance: DsRiskToleranceLevel.aggressive,
      adaptationSpeed: DsAdaptationSpeed.reactive,
      signatureMove:
          'Nieskończone serie przyspieszeń powyżej 2000 m n.p.m., gdzie lekcy Kolumbijczycy zyskują przewagę tlenową.',
      weaknessExploitHint:
          'Rozciągnij grupę na wietrze bocznym w płaskich dolinach jeszcze przed startem wspinaczki.',
      radioQuote: 'Powyżej 1800 metrów to nasz dom. Rwijcie tempo co 500 metrów!',
      tendencies: DsTacticalTendencyProfile(
        breakawayAppetite: 0.84,
        pelotonChaseAggression: 0.30,
        mountainPaceTrainIntensity: 0.79,
        crosswindEchelonTrigger: 0.22,
        sprintLeadoutCommitment: 0.16,
        satelliteRelayFrequency: 0.74,
        lateAttackDistanceKm: 13.0,
        riskAppetite: 0.86,
        bluffingAndPokerFaceBias: 0.52,
        gcProtectionThresholdMin: 3.2,
      ),
    ),
    const DirectorSportifTacticalProfile(
      teamId: 'team_adria_slo',
      teamName: 'Adria-Krka Triglav Velo',
      division: TeamDivision.proTeam,
      countryIso: 'SLO',
      directorName: 'Andrej Hauptman-Kralj',
      directorNationalityIso: 'SLO',
      styleCodename: 'Słoweński Cios z Cienia',
      archetype: DsTacticalArchetype.counterPunchSniper,
      primaryTerrainFocus: DsStageTerrainFocus.allRounder,
      riskTolerance: DsRiskToleranceLevel.aggressive,
      adaptationSpeed: DsAdaptationSpeed.reactive,
      signatureMove:
          'Cierpliwe ukrycie lidera aż do ostatnich 2 km podjazdu i eksplozja przy 11 W/kg.',
      weaknessExploitHint:
          'Nie zostawiaj ich lidera samego na kole w ostatniej trójce — narzuć równe, męczące tempo dużo wcześniej.',
      radioQuote: 'Zostań na trzecim kole i czekaj na nasz znak przy 1500 m.',
      tendencies: DsTacticalTendencyProfile(
        breakawayAppetite: 0.62,
        pelotonChaseAggression: 0.56,
        mountainPaceTrainIntensity: 0.72,
        crosswindEchelonTrigger: 0.54,
        sprintLeadoutCommitment: 0.44,
        satelliteRelayFrequency: 0.58,
        lateAttackDistanceKm: 2.5,
        riskAppetite: 0.77,
        bluffingAndPokerFaceBias: 0.74,
        gcProtectionThresholdMin: 2.8,
      ),
    ),
    const DirectorSportifTacticalProfile(
      teamId: 'team_wallonie_bel',
      teamName: 'Wallonie-Ardennes Bpost',
      division: TeamDivision.proTeam,
      countryIso: 'BEL',
      directorName: 'Christophe Brandt-Dumont',
      directorNationalityIso: 'BEL',
      styleCodename: 'Walońska Zasadzka Ardeńska',
      archetype: DsTacticalArchetype.cobblesAndClassicsBrawler,
      primaryTerrainFocus: DsStageTerrainFocus.hillyPuncheur,
      riskTolerance: DsRiskToleranceLevel.aggressive,
      adaptationSpeed: DsAdaptationSpeed.reactive,
      signatureMove:
          'Ataki na stromych walońskich ściankach 15–20% przed zjazdem na metę.',
      weaknessExploitHint:
          'Utrzymaj wysoką kadencję na dole krótkich podjazdów i nie daj się zamknąć z tyłu peletonu.',
      radioQuote: 'Na La Redoute otwieramy ogień bez oglądania się za siebie!',
      tendencies: DsTacticalTendencyProfile(
        breakawayAppetite: 0.78,
        pelotonChaseAggression: 0.55,
        mountainPaceTrainIntensity: 0.48,
        crosswindEchelonTrigger: 0.72,
        sprintLeadoutCommitment: 0.58,
        satelliteRelayFrequency: 0.46,
        lateAttackDistanceKm: 20.0,
        riskAppetite: 0.83,
        bluffingAndPokerFaceBias: 0.48,
        gcProtectionThresholdMin: 4.5,
      ),
    ),
    const DirectorSportifTacticalProfile(
      teamId: 'team_padova_ita',
      teamName: 'Padova-Prosecco Cycling',
      division: TeamDivision.proTeam,
      countryIso: 'ITA',
      directorName: 'Roberto Reverberi-Moro',
      directorNationalityIso: 'ITA',
      styleCodename: 'Wenecki Pociąg Harcowników',
      archetype: DsTacticalArchetype.sprintLeadoutMachine,
      primaryTerrainFocus: DsStageTerrainFocus.flatSprint,
      riskTolerance: DsRiskToleranceLevel.calculated,
      adaptationSpeed: DsAdaptationSpeed.methodical,
      signatureMove:
          'Wysyłanie pomocnika do ucieczki dla widoczności sponsora przy jednoczesnym budowaniu pociągu dla sprintera.',
      weaknessExploitHint:
          'Wymuś na nich pracę w pościgu wcześniej, żeby zabrakło im ostatniego rozprowadzającego.',
      radioQuote: 'Dwóch do odjazdu przed kamerami, pięciu pilnuje sprintera w środku!',
      tendencies: DsTacticalTendencyProfile(
        breakawayAppetite: 0.68,
        pelotonChaseAggression: 0.70,
        mountainPaceTrainIntensity: 0.32,
        crosswindEchelonTrigger: 0.52,
        sprintLeadoutCommitment: 0.84,
        satelliteRelayFrequency: 0.25,
        lateAttackDistanceKm: 1.6,
        riskAppetite: 0.54,
        bluffingAndPokerFaceBias: 0.66,
        gcProtectionThresholdMin: 5.2,
      ),
    ),
    const DirectorSportifTacticalProfile(
      teamId: 'team_tirol_aut',
      teamName: 'Tirol-KTM Berggeist',
      division: TeamDivision.proTeam,
      countryIso: 'AUT',
      directorName: 'Gregor Gazvoda-Hofer',
      directorNationalityIso: 'AUT',
      styleCodename: 'Tyrolski Duch Szczytów',
      archetype: DsTacticalArchetype.academyTalentShowrunner,
      primaryTerrainFocus: DsStageTerrainFocus.highMountain,
      riskTolerance: DsRiskToleranceLevel.aggressive,
      adaptationSpeed: DsAdaptationSpeed.reactive,
      signatureMove:
          'Wypuszczanie młodych górali U23 w śmiałe solowe rajdy na trudnych alpejskich etapach.',
      weaknessExploitHint:
          'Kontroluj ich młodych zawodników na długich podjazdach — brakuje im doświadczenia w rozkładaniu sił.',
      radioQuote: 'Młody, nie bój się nazwisk! Jedź swoje tempo do samego szczytu!',
      tendencies: DsTacticalTendencyProfile(
        breakawayAppetite: 0.87,
        pelotonChaseAggression: 0.34,
        mountainPaceTrainIntensity: 0.62,
        crosswindEchelonTrigger: 0.40,
        sprintLeadoutCommitment: 0.28,
        satelliteRelayFrequency: 0.50,
        lateAttackDistanceKm: 25.0,
        riskAppetite: 0.80,
        bluffingAndPokerFaceBias: 0.34,
        gcProtectionThresholdMin: 5.0,
      ),
    ),
    const DirectorSportifTacticalProfile(
      teamId: 'team_vlaanderen_bel',
      teamName: 'Vlaanderen-Gent Bicycles',
      division: TeamDivision.proTeam,
      countryIso: 'BEL',
      directorName: 'Hans De Clercq-Peeters',
      directorNationalityIso: 'BEL',
      styleCodename: 'Gandawska Szkoła Bruku',
      archetype: DsTacticalArchetype.cobblesAndClassicsBrawler,
      primaryTerrainFocus: DsStageTerrainFocus.cobblesClassic,
      riskTolerance: DsRiskToleranceLevel.aggressive,
      adaptationSpeed: DsAdaptationSpeed.methodical,
      signatureMove:
          'Perfekcyjne ustawianie się w wąskich wjazdach na sektory brukowe 5★ przed faworytami WorldTour.',
      weaknessExploitHint:
          'Zaatakuj na płaskich odcinkach asfaltu pomiędzy sektorami, kiedy ich ciężsi specjaliści odpoczywają.',
      radioQuote: 'Wjeżdżamy na kocie łby jako pierwsi albo wcale!',
      tendencies: DsTacticalTendencyProfile(
        breakawayAppetite: 0.82,
        pelotonChaseAggression: 0.52,
        mountainPaceTrainIntensity: 0.30,
        crosswindEchelonTrigger: 0.84,
        sprintLeadoutCommitment: 0.65,
        satelliteRelayFrequency: 0.36,
        lateAttackDistanceKm: 34.0,
        riskAppetite: 0.78,
        bluffingAndPokerFaceBias: 0.46,
        gcProtectionThresholdMin: 5.5,
      ),
    ),
    const DirectorSportifTacticalProfile(
      teamId: 'team_olympus_gre',
      teamName: 'Olympus-Hellenic Air',
      division: TeamDivision.proTeam,
      countryIso: 'GRE',
      directorName: 'Nikos Papadopoulos',
      directorNationalityIso: 'GRE',
      styleCodename: 'Ateński Ogień Prometeusza',
      archetype: DsTacticalArchetype.breakawayOpportunists,
      primaryTerrainFocus: DsStageTerrainFocus.hillyPuncheur,
      riskTolerance: DsRiskToleranceLevel.reckless,
      adaptationSpeed: DsAdaptationSpeed.improvisational,
      signatureMove:
          'Ekstremalnie wczesne ataki w upale >32°C, gdzie kolarze z południa lepiej znoszą temperaturę głęboką.',
      weaknessExploitHint:
          'Stosuj woreczki z lodem i utrzymuj chłodzenie w peletonie — w chłodniejszej końcówce ich przewaga znika.',
      radioQuote: 'W tym słońcu reszta padnie. Jedźcie mocno pod każdą górę!',
      tendencies: DsTacticalTendencyProfile(
        breakawayAppetite: 0.91,
        pelotonChaseAggression: 0.30,
        mountainPaceTrainIntensity: 0.45,
        crosswindEchelonTrigger: 0.44,
        sprintLeadoutCommitment: 0.38,
        satelliteRelayFrequency: 0.40,
        lateAttackDistanceKm: 40.0,
        riskAppetite: 0.88,
        bluffingAndPokerFaceBias: 0.50,
        gcProtectionThresholdMin: 5.8,
      ),
    ),
    const DirectorSportifTacticalProfile(
      teamId: 'team_algarve_por',
      teamName: 'Algarve-Sagres Ciclismo',
      division: TeamDivision.proTeam,
      countryIso: 'POR',
      directorName: 'Ruben Guerreiro-Silva',
      directorNationalityIso: 'POR',
      styleCodename: 'Atlantycki Pociąg Górski',
      archetype: DsTacticalArchetype.skyTrainControl,
      primaryTerrainFocus: DsStageTerrainFocus.highMountain,
      riskTolerance: DsRiskToleranceLevel.calculated,
      adaptationSpeed: DsAdaptationSpeed.methodical,
      signatureMove:
          'Zaskakująco zdyscyplinowany pociąg na średnich i długich podjazdach o stałym nachyleniu 6–8%.',
      weaknessExploitHint:
          'Atakuj na bardzo stromych odcinkach >14%, gdzie ich rytmiczny pociąg traci płynność.',
      radioQuote: 'Równe tempo na Alto da Foia! Nie pozwólcie im złapać rytmu!',
      tendencies: DsTacticalTendencyProfile(
        breakawayAppetite: 0.54,
        pelotonChaseAggression: 0.66,
        mountainPaceTrainIntensity: 0.78,
        crosswindEchelonTrigger: 0.48,
        sprintLeadoutCommitment: 0.32,
        satelliteRelayFrequency: 0.48,
        lateAttackDistanceKm: 7.5,
        riskAppetite: 0.48,
        bluffingAndPokerFaceBias: 0.42,
        gcProtectionThresholdMin: 3.2,
      ),
    ),
    const DirectorSportifTacticalProfile(
      teamId: 'team_caledonia_gbr',
      teamName: 'Caledonia-Highland Malt',
      division: TeamDivision.proTeam,
      countryIso: 'GBR',
      directorName: 'David Millar-MacLeod',
      directorNationalityIso: 'GBR',
      styleCodename: 'Szkocki Wiatr Wrzosowisk',
      archetype: DsTacticalArchetype.echelonCrosswindHunters,
      primaryTerrainFocus: DsStageTerrainFocus.timeTrial,
      riskTolerance: DsRiskToleranceLevel.calculated,
      adaptationSpeed: DsAdaptationSpeed.reactive,
      signatureMove:
          'Wspólne ataki czasowców w końcówce na 8–12 km przed metą na wzór drużynowej jazdy na czas.',
      weaknessExploitHint:
          'Jeśli odjadą na płaskim w trójkę, natychmiast wyślij dwóch pomocników na pościg — nie czekaj.',
      radioQuote: 'Formujemy mini-TTT na ostatnich 10 km. Zmiany po 15 sekund!',
      tendencies: DsTacticalTendencyProfile(
        breakawayAppetite: 0.74,
        pelotonChaseAggression: 0.60,
        mountainPaceTrainIntensity: 0.44,
        crosswindEchelonTrigger: 0.89,
        sprintLeadoutCommitment: 0.46,
        satelliteRelayFrequency: 0.42,
        lateAttackDistanceKm: 12.0,
        riskAppetite: 0.68,
        bluffingAndPokerFaceBias: 0.38,
        gcProtectionThresholdMin: 4.5,
      ),
    ),
    const DirectorSportifTacticalProfile(
      teamId: 'team_auckland_nzl',
      teamName: 'Auckland-Kiwi Express',
      division: TeamDivision.proTeam,
      countryIso: 'NZL',
      directorName: 'Greg Henderson-Reid',
      directorNationalityIso: 'NZL',
      styleCodename: 'Torowa Proca z Pacyfiku',
      archetype: DsTacticalArchetype.sprintLeadoutMachine,
      primaryTerrainFocus: DsStageTerrainFocus.flatSprint,
      riskTolerance: DsRiskToleranceLevel.aggressive,
      adaptationSpeed: DsAdaptationSpeed.reactive,
      signatureMove:
          'Torowa synchronizacja zmian na ostatnich 3 km i ekstremalnie późny finisz z drugiego koła.',
      weaknessExploitHint:
          'Rozbij ich torowy rytm, narzucając ostre przyspieszenie już na 5 km przed metą.',
      radioQuote: 'Jak na welodromie w Cambridge — płynne przejście i ogień na 180 m!',
      tendencies: DsTacticalTendencyProfile(
        breakawayAppetite: 0.58,
        pelotonChaseAggression: 0.76,
        mountainPaceTrainIntensity: 0.34,
        crosswindEchelonTrigger: 0.72,
        sprintLeadoutCommitment: 0.90,
        satelliteRelayFrequency: 0.30,
        lateAttackDistanceKm: 1.4,
        riskAppetite: 0.66,
        bluffingAndPokerFaceBias: 0.45,
        gcProtectionThresholdMin: 5.0,
      ),
    ),

    // =========================================================================
    // CONTINENTAL (20 drużyn)
    // =========================================================================
    const DirectorSportifTacticalProfile(
      teamId: 'team_mazovia_pol',
      teamName: 'Mazovia-Warszawa Continental',
      division: TeamDivision.continental,
      countryIso: 'POL',
      directorName: 'Dariusz Banaszek-Mazur',
      directorNationalityIso: 'POL',
      styleCodename: 'Mazowiecki Zryw od Kilometra Zero',
      archetype: DsTacticalArchetype.breakawayOpportunists,
      primaryTerrainFocus: DsStageTerrainFocus.flatSprint,
      riskTolerance: DsRiskToleranceLevel.reckless,
      adaptationSpeed: DsAdaptationSpeed.improvisational,
      signatureMove:
          'Ataki od samego startu ostrego na płaskich i wietrznych etapach dla czasu antenowego sponsora.',
      weaknessExploitHint:
          'Zignoruj ich harce na pierwszych 100 km — sprinterzy WT dogonią ich bez wysiłku.',
      radioQuote: 'Od zera do odjazdu! Pokazujemy biało-czerwone barwy w telewizji!',
      tendencies: DsTacticalTendencyProfile(
        breakawayAppetite: 0.96,
        pelotonChaseAggression: 0.22,
        mountainPaceTrainIntensity: 0.25,
        crosswindEchelonTrigger: 0.64,
        sprintLeadoutCommitment: 0.52,
        satelliteRelayFrequency: 0.28,
        lateAttackDistanceKm: 62.0,
        riskAppetite: 0.92,
        bluffingAndPokerFaceBias: 0.35,
        gcProtectionThresholdMin: 6.5,
      ),
    ),
    const DirectorSportifTacticalProfile(
      teamId: 'team_lombardia_ita',
      teamName: 'Lombardia-Como Talents',
      division: TeamDivision.continental,
      countryIso: 'ITA',
      directorName: 'Davide Bramati-Riva',
      directorNationalityIso: 'ITA',
      styleCodename: 'Kuźnia Talentów znad Como',
      archetype: DsTacticalArchetype.academyTalentShowrunner,
      primaryTerrainFocus: DsStageTerrainFocus.hillyPuncheur,
      riskTolerance: DsRiskToleranceLevel.aggressive,
      adaptationSpeed: DsAdaptationSpeed.reactive,
      signatureMove:
          'Promowanie 20-letnich puncherów przez śmiałe ataki na zjazdach i krótkich podjazdach.',
      weaknessExploitHint:
          'Zadbaj o pozycję na zjazdach z pagórków, gdzie ich młodzi zawodnicy podejmują największe ryzyko.',
      radioQuote: 'Skauci WorldTouru oglądają ten finał — pokaż, co potrafisz na zjeździe!',
      tendencies: DsTacticalTendencyProfile(
        breakawayAppetite: 0.85,
        pelotonChaseAggression: 0.30,
        mountainPaceTrainIntensity: 0.46,
        crosswindEchelonTrigger: 0.38,
        sprintLeadoutCommitment: 0.42,
        satelliteRelayFrequency: 0.44,
        lateAttackDistanceKm: 18.0,
        riskAppetite: 0.84,
        bluffingAndPokerFaceBias: 0.48,
        gcProtectionThresholdMin: 6.0,
      ),
    ),
    const DirectorSportifTacticalProfile(
      teamId: 'team_almaty_kaz',
      teamName: 'Almaty-Kazakh Steppe',
      division: TeamDivision.continental,
      countryIso: 'KAZ',
      directorName: 'Aleksandr Szefier-Nazar',
      directorNationalityIso: 'KAZ',
      styleCodename: 'Stepowa Partyzantka',
      archetype: DsTacticalArchetype.totalAttackChaos,
      primaryTerrainFocus: DsStageTerrainFocus.highMountain,
      riskTolerance: DsRiskToleranceLevel.reckless,
      adaptationSpeed: DsAdaptationSpeed.improvisational,
      signatureMove:
          'Nieskoordynowane, nieprzewidywalne zrywy co kilka kilometrów rozbijające spokój w grupie.',
      weaknessExploitHint:
          'Nie goń pojedynczych skoków — pozwól, aby sami wyczerpali swoje baterie W\'.',
      radioQuote: 'Atakuj, kiedy nikt się nie spodziewa! Chaos jest naszym sprzymierzeńcem!',
      tendencies: DsTacticalTendencyProfile(
        breakawayAppetite: 0.89,
        pelotonChaseAggression: 0.26,
        mountainPaceTrainIntensity: 0.55,
        crosswindEchelonTrigger: 0.72,
        sprintLeadoutCommitment: 0.20,
        satelliteRelayFrequency: 0.62,
        lateAttackDistanceKm: 44.0,
        riskAppetite: 0.95,
        bluffingAndPokerFaceBias: 0.70,
        gcProtectionThresholdMin: 6.0,
      ),
    ),
    const DirectorSportifTacticalProfile(
      teamId: 'team_medellin_col',
      teamName: 'Antioquia-Medellin Climbers',
      division: TeamDivision.continental,
      countryIso: 'COL',
      directorName: 'Gabriel Jaime Vélez',
      directorNationalityIso: 'COL',
      styleCodename: 'Kondory z Antioquia',
      archetype: DsTacticalArchetype.komPolkaHunter,
      primaryTerrainFocus: DsStageTerrainFocus.highMountain,
      riskTolerance: DsRiskToleranceLevel.aggressive,
      adaptationSpeed: DsAdaptationSpeed.reactive,
      signatureMove:
          'Masowa ucieczka trzech wspinaczy z jednego zespołu na najtrudniejszym etapie górskim.',
      weaknessExploitHint:
          'Wykorzystaj ich niską masę na płaskim wietrze — przed górami łatwo stracą kontakt.',
      radioQuote: 'Trzech naszych w górach to jak jeden pociąg! Lećcie po punkty KOM!',
      tendencies: DsTacticalTendencyProfile(
        breakawayAppetite: 0.91,
        pelotonChaseAggression: 0.20,
        mountainPaceTrainIntensity: 0.74,
        crosswindEchelonTrigger: 0.18,
        sprintLeadoutCommitment: 0.12,
        satelliteRelayFrequency: 0.70,
        lateAttackDistanceKm: 15.0,
        riskAppetite: 0.85,
        bluffingAndPokerFaceBias: 0.42,
        gcProtectionThresholdMin: 5.5,
      ),
    ),
    const DirectorSportifTacticalProfile(
      teamId: 'team_brabant_ned',
      teamName: 'Brabant-Eindhoven Tech',
      division: TeamDivision.continental,
      countryIso: 'NED',
      directorName: 'Servais Knaven-Vos',
      directorNationalityIso: 'NED',
      styleCodename: 'Laboratorium Wiatru z Eindhoven',
      archetype: DsTacticalArchetype.academyTalentShowrunner,
      primaryTerrainFocus: DsStageTerrainFocus.timeTrial,
      riskTolerance: DsRiskToleranceLevel.calculated,
      adaptationSpeed: DsAdaptationSpeed.methodical,
      signatureMove:
          'Zoptymalizowane pod kątem CdA późne ataki solowe młodych specjalistów od jazdy na czas.',
      weaknessExploitHint:
          'Wprowadź rywalizację na wąskich krętych drogach, gdzie pozycja aero jest trudna do utrzymania.',
      radioQuote: 'Zjedź na przedłużki wirtualne, 430 W do samej linii mety!',
      tendencies: DsTacticalTendencyProfile(
        breakawayAppetite: 0.76,
        pelotonChaseAggression: 0.44,
        mountainPaceTrainIntensity: 0.42,
        crosswindEchelonTrigger: 0.78,
        sprintLeadoutCommitment: 0.54,
        satelliteRelayFrequency: 0.36,
        lateAttackDistanceKm: 11.0,
        riskAppetite: 0.60,
        bluffingAndPokerFaceBias: 0.25,
        gcProtectionThresholdMin: 5.8,
      ),
    ),
    const DirectorSportifTacticalProfile(
      teamId: 'team_provence_fra',
      teamName: 'Provence-Lavande Cyclisme',
      division: TeamDivision.continental,
      countryIso: 'FRA',
      directorName: 'Laurent Jalabert-Fabre',
      directorNationalityIso: 'FRA',
      styleCodename: 'Mistral z Prowansji',
      archetype: DsTacticalArchetype.echelonCrosswindHunters,
      primaryTerrainFocus: DsStageTerrainFocus.hillyPuncheur,
      riskTolerance: DsRiskToleranceLevel.aggressive,
      adaptationSpeed: DsAdaptationSpeed.reactive,
      signatureMove:
          'Wykorzystywanie podmuchów mistralu na zjazdach z Ventoux i prowansalskich płaskowyżach.',
      weaknessExploitHint:
          'Pilnuj czoła w dolinach rzeki Rodan, gdzie wiatr zmienia kierunek za każdym zakrętem.',
      radioQuote: 'Mistral wieje! Zakładamy koła z przodu i tniemy grupę na pół!',
      tendencies: DsTacticalTendencyProfile(
        breakawayAppetite: 0.84,
        pelotonChaseAggression: 0.38,
        mountainPaceTrainIntensity: 0.52,
        crosswindEchelonTrigger: 0.87,
        sprintLeadoutCommitment: 0.40,
        satelliteRelayFrequency: 0.46,
        lateAttackDistanceKm: 29.0,
        riskAppetite: 0.79,
        bluffingAndPokerFaceBias: 0.46,
        gcProtectionThresholdMin: 6.0,
      ),
    ),
    const DirectorSportifTacticalProfile(
      teamId: 'team_andalucia_esp',
      teamName: 'Andalucia-Sevilla Sol',
      division: TeamDivision.continental,
      countryIso: 'ESP',
      directorName: 'Antonio Cabello-Ruiz',
      directorNationalityIso: 'ESP',
      styleCodename: 'Andaluzyjski Żar Słońca',
      archetype: DsTacticalArchetype.breakawayOpportunists,
      primaryTerrainFocus: DsStageTerrainFocus.hillyPuncheur,
      riskTolerance: DsRiskToleranceLevel.aggressive,
      adaptationSpeed: DsAdaptationSpeed.improvisational,
      signatureMove:
          'Długie ucieczki w skwarze, liczące na kryzys nawodnieniowy w głównym peletonie.',
      weaknessExploitHint:
          'Wysyłaj pomocników po bidony i lód przed strefami upału, a bez trudu ich dogonisz.',
      radioQuote: 'W południe słońce zabije pościg. Utrzymujcie przewagę!',
      tendencies: DsTacticalTendencyProfile(
        breakawayAppetite: 0.90,
        pelotonChaseAggression: 0.24,
        mountainPaceTrainIntensity: 0.50,
        crosswindEchelonTrigger: 0.36,
        sprintLeadoutCommitment: 0.38,
        satelliteRelayFrequency: 0.42,
        lateAttackDistanceKm: 33.0,
        riskAppetite: 0.81,
        bluffingAndPokerFaceBias: 0.55,
        gcProtectionThresholdMin: 6.2,
      ),
    ),
    const DirectorSportifTacticalProfile(
      teamId: 'team_yorkshire_gbr',
      teamName: 'Yorkshire-Dales Cycling',
      division: TeamDivision.continental,
      countryIso: 'GBR',
      directorName: 'Russell Downing-Shaw',
      directorNationalityIso: 'GBR',
      styleCodename: 'Klify i Wrzosy Yorkshire',
      archetype: DsTacticalArchetype.cobblesAndClassicsBrawler,
      primaryTerrainFocus: DsStageTerrainFocus.hillyPuncheur,
      riskTolerance: DsRiskToleranceLevel.aggressive,
      adaptationSpeed: DsAdaptationSpeed.reactive,
      signatureMove:
          'Brutalne ataki na krótkich, szorstkich podjazdach 18–25% typowych dla angielskich dolin.',
      weaknessExploitHint:
          'Zastosuj kasetę o szerszym zakresie (np. 11-34T) i równomierną kadencję, aby nie spalić nóg na stromiźnie.',
      radioQuote: 'Na tym 20-procentowym murze nikt nie ma litości — pełny ogień!',
      tendencies: DsTacticalTendencyProfile(
        breakawayAppetite: 0.82,
        pelotonChaseAggression: 0.42,
        mountainPaceTrainIntensity: 0.44,
        crosswindEchelonTrigger: 0.80,
        sprintLeadoutCommitment: 0.50,
        satelliteRelayFrequency: 0.38,
        lateAttackDistanceKm: 21.0,
        riskAppetite: 0.83,
        bluffingAndPokerFaceBias: 0.32,
        gcProtectionThresholdMin: 5.8,
      ),
    ),
    const DirectorSportifTacticalProfile(
      teamId: 'team_bavaria_jr_ger',
      teamName: 'Bavaria-Alpen Junior Velo',
      division: TeamDivision.continental,
      countryIso: 'GER',
      directorName: 'Danilo Hondo-Becker',
      directorNationalityIso: 'GER',
      styleCodename: 'Szkoła Młodych Sprinterów',
      archetype: DsTacticalArchetype.sprintLeadoutMachine,
      primaryTerrainFocus: DsStageTerrainFocus.flatSprint,
      riskTolerance: DsRiskToleranceLevel.calculated,
      adaptationSpeed: DsAdaptationSpeed.methodical,
      signatureMove:
          'Zdyscyplinowana nauka pociągu sprinterskiego dla kolarzy U23 na płaskich końcówkach.',
      weaknessExploitHint:
          'Ich młodzi piloci łatwo gubią koło w tłoku na ostatnich 1000 m — wyprzedź ich po zewnętrznej.',
      radioQuote: 'Trzymajcie szyk jak w podręczniku, nie patrzcie na gwiazdy WorldTour!',
      tendencies: DsTacticalTendencyProfile(
        breakawayAppetite: 0.56,
        pelotonChaseAggression: 0.62,
        mountainPaceTrainIntensity: 0.30,
        crosswindEchelonTrigger: 0.58,
        sprintLeadoutCommitment: 0.86,
        satelliteRelayFrequency: 0.24,
        lateAttackDistanceKm: 1.5,
        riskAppetite: 0.50,
        bluffingAndPokerFaceBias: 0.22,
        gcProtectionThresholdMin: 6.5,
      ),
    ),
    const DirectorSportifTacticalProfile(
      teamId: 'team_jutland_den',
      teamName: 'Jutland-Vejle Cycling',
      division: TeamDivision.continental,
      countryIso: 'DEN',
      directorName: 'Michael Mørkøv-Hansen',
      directorNationalityIso: 'DEN',
      styleCodename: 'Jutlandzki Wiatr Przeciwny',
      archetype: DsTacticalArchetype.echelonCrosswindHunters,
      primaryTerrainFocus: DsStageTerrainFocus.cobblesClassic,
      riskTolerance: DsRiskToleranceLevel.aggressive,
      adaptationSpeed: DsAdaptationSpeed.reactive,
      signatureMove:
          'Współpraca z większymi ekipami na wietrze bocznym w celu przetrwania i walki o TOP 10 etapu.',
      weaknessExploitHint:
          'Zajmij pierwszą linię wachlarza przed mostami i groblami nadmorskimi.',
      radioQuote: 'Dołączamy do pierwszego wachlarza, nie dajcie się odciąć!',
      tendencies: DsTacticalTendencyProfile(
        breakawayAppetite: 0.78,
        pelotonChaseAggression: 0.45,
        mountainPaceTrainIntensity: 0.32,
        crosswindEchelonTrigger: 0.90,
        sprintLeadoutCommitment: 0.64,
        satelliteRelayFrequency: 0.30,
        lateAttackDistanceKm: 27.0,
        riskAppetite: 0.77,
        bluffingAndPokerFaceBias: 0.36,
        gcProtectionThresholdMin: 6.0,
      ),
    ),
    const DirectorSportifTacticalProfile(
      teamId: 'team_bohemia_cze',
      teamName: 'Bohemia-Praha Velo',
      division: TeamDivision.continental,
      countryIso: 'CZE',
      directorName: 'Roman Kreuziger-Novák',
      directorNationalityIso: 'CZE',
      styleCodename: 'Praski Snajper Finiszowy',
      archetype: DsTacticalArchetype.counterPunchSniper,
      primaryTerrainFocus: DsStageTerrainFocus.hillyPuncheur,
      riskTolerance: DsRiskToleranceLevel.calculated,
      adaptationSpeed: DsAdaptationSpeed.reactive,
      signatureMove:
          'Ciche przeczekanie walki faworytów i zaskakujący atak na 1200 m przed metą po bruku lub pagórku.',
      weaknessExploitHint:
          'Kontroluj ataki z drugiego rzędu na ostatnim kilometrze — świetnie wykorzystują moment zawahania.',
      radioQuote: 'Kiedy faworyci patrzą na siebie, wtedy odpalasz sprint pod górę!',
      tendencies: DsTacticalTendencyProfile(
        breakawayAppetite: 0.70,
        pelotonChaseAggression: 0.40,
        mountainPaceTrainIntensity: 0.54,
        crosswindEchelonTrigger: 0.52,
        sprintLeadoutCommitment: 0.56,
        satelliteRelayFrequency: 0.42,
        lateAttackDistanceKm: 1.8,
        riskAppetite: 0.69,
        bluffingAndPokerFaceBias: 0.68,
        gcProtectionThresholdMin: 5.2,
      ),
    ),
    const DirectorSportifTacticalProfile(
      teamId: 'team_normandie_fra',
      teamName: 'Normandie-Rouen Velo Club',
      division: TeamDivision.continental,
      countryIso: 'FRA',
      directorName: 'Sandy Casar-Leblanc',
      directorNationalityIso: 'FRA',
      styleCodename: 'Normandzka Krawędź Wybrzeża',
      archetype: DsTacticalArchetype.academyTalentShowrunner,
      primaryTerrainFocus: DsStageTerrainFocus.cobblesClassic,
      riskTolerance: DsRiskToleranceLevel.aggressive,
      adaptationSpeed: DsAdaptationSpeed.improvisational,
      signatureMove:
          'Ataki młodych Francuzów na nadmorskich klifach i technicznych kryteriach miejskich.',
      weaknessExploitHint:
          'Nie trać energii na gonienie ich w środku etapu — na płaskim finiszu brakuje im siły.',
      radioQuote: 'Zostawcie serce na asfalcie Normandii! Atak na szczycie klifu!',
      tendencies: DsTacticalTendencyProfile(
        breakawayAppetite: 0.88,
        pelotonChaseAggression: 0.28,
        mountainPaceTrainIntensity: 0.36,
        crosswindEchelonTrigger: 0.76,
        sprintLeadoutCommitment: 0.52,
        satelliteRelayFrequency: 0.34,
        lateAttackDistanceKm: 35.0,
        riskAppetite: 0.85,
        bluffingAndPokerFaceBias: 0.42,
        gcProtectionThresholdMin: 6.4,
      ),
    ),
    const DirectorSportifTacticalProfile(
      teamId: 'team_krakow_pol',
      teamName: 'Kraków-Wawel Academy',
      division: TeamDivision.continental,
      countryIso: 'POL',
      directorName: 'Zbigniew Spruch-Kowalczyk',
      directorNationalityIso: 'POL',
      styleCodename: 'Krakowski Kontratak Akademii',
      archetype: DsTacticalArchetype.academyTalentShowrunner,
      primaryTerrainFocus: DsStageTerrainFocus.hillyPuncheur,
      riskTolerance: DsRiskToleranceLevel.aggressive,
      adaptationSpeed: DsAdaptationSpeed.reactive,
      signatureMove:
          'Wspólna praca młodych kolarzy U23 na podjazdach o nachyleniu 7–10% i odważne finisze z mniejszych grup.',
      weaknessExploitHint:
          'Zwiększ tempo przed podjazdem, aby odciąć ich młodych liderów od starszych pomocników.',
      radioQuote: 'Chłopaki z Krakowa, nie pękamy! Jedziemy po koszulkę młodzieżową!',
      tendencies: DsTacticalTendencyProfile(
        breakawayAppetite: 0.86,
        pelotonChaseAggression: 0.34,
        mountainPaceTrainIntensity: 0.50,
        crosswindEchelonTrigger: 0.54,
        sprintLeadoutCommitment: 0.48,
        satelliteRelayFrequency: 0.48,
        lateAttackDistanceKm: 17.0,
        riskAppetite: 0.78,
        bluffingAndPokerFaceBias: 0.40,
        gcProtectionThresholdMin: 5.5,
      ),
    ),
    const DirectorSportifTacticalProfile(
      teamId: 'team_limburg_ned',
      teamName: 'Limburg-Valkenburg Hills',
      division: TeamDivision.continental,
      countryIso: 'NED',
      directorName: 'Bart Brentjens-Maas',
      directorNationalityIso: 'NED',
      styleCodename: 'Cauberg Express',
      archetype: DsTacticalArchetype.counterPunchSniper,
      primaryTerrainFocus: DsStageTerrainFocus.hillyPuncheur,
      riskTolerance: DsRiskToleranceLevel.aggressive,
      adaptationSpeed: DsAdaptationSpeed.reactive,
      signatureMove:
          'Eksplozywne przyspieszenia na krótkich podjazdach typu Cauberg z perfekcyjnym wyczuciem momentu.',
      weaknessExploitHint:
          'Wyczerp ich nogi na długich, płaskich odcinkach przed serią pagórków.',
      radioQuote: 'Na najstromszej ściance w Valkenburgu odpalasz 1000 W bez oglądania się!',
      tendencies: DsTacticalTendencyProfile(
        breakawayAppetite: 0.75,
        pelotonChaseAggression: 0.42,
        mountainPaceTrainIntensity: 0.45,
        crosswindEchelonTrigger: 0.74,
        sprintLeadoutCommitment: 0.58,
        satelliteRelayFrequency: 0.38,
        lateAttackDistanceKm: 2.0,
        riskAppetite: 0.76,
        bluffingAndPokerFaceBias: 0.54,
        gcProtectionThresholdMin: 5.8,
      ),
    ),
    const DirectorSportifTacticalProfile(
      teamId: 'team_sicilia_ita',
      teamName: 'Sicilia-Etna Vulcano',
      division: TeamDivision.continental,
      countryIso: 'ITA',
      directorName: 'Paolo Tiralongo-Greco',
      directorNationalityIso: 'ITA',
      styleCodename: 'Lawina z Etny',
      archetype: DsTacticalArchetype.komPolkaHunter,
      primaryTerrainFocus: DsStageTerrainFocus.highMountain,
      riskTolerance: DsRiskToleranceLevel.reckless,
      adaptationSpeed: DsAdaptationSpeed.improvisational,
      signatureMove:
          'Bezkompromisowe ataki na wulkanicznych podjazdach o długim, nieregularnym nachyleniu.',
      weaknessExploitHint:
          'Utrzymuj stały rytm watażu — ich zrywy na stromych fragmentach szybko wywołują dług tlenowy.',
      radioQuote: 'Zostawcie wszystko na zboczach Etny! Grochy są nasze!',
      tendencies: DsTacticalTendencyProfile(
        breakawayAppetite: 0.92,
        pelotonChaseAggression: 0.22,
        mountainPaceTrainIntensity: 0.66,
        crosswindEchelonTrigger: 0.30,
        sprintLeadoutCommitment: 0.18,
        satelliteRelayFrequency: 0.56,
        lateAttackDistanceKm: 19.0,
        riskAppetite: 0.89,
        bluffingAndPokerFaceBias: 0.62,
        gcProtectionThresholdMin: 6.0,
      ),
    ),
    const DirectorSportifTacticalProfile(
      teamId: 'team_asmara_eri',
      teamName: 'Asmara-Horn of Africa',
      division: TeamDivision.continental,
      countryIso: 'ERI',
      directorName: 'Daniel Teklehaimanot-Tesfay',
      directorNationalityIso: 'ERI',
      styleCodename: 'Wyżyna Erytrejska',
      archetype: DsTacticalArchetype.komPolkaHunter,
      primaryTerrainFocus: DsStageTerrainFocus.highMountain,
      riskTolerance: DsRiskToleranceLevel.aggressive,
      adaptationSpeed: DsAdaptationSpeed.reactive,
      signatureMove:
          'Niezwykle wytrzymała jazda w ucieczkach na dużej wysokości >2000 m n.p.m. z wysoką kadencją.',
      weaknessExploitHint:
          'Zadbaj o pozycjonowanie na technicznych zjazdach w deszczu — to ich słabszy punkt.',
      radioQuote: 'Wysokość to nasz żywioł! Zbieramy wszystkie premie górskie!',
      tendencies: DsTacticalTendencyProfile(
        breakawayAppetite: 0.93,
        pelotonChaseAggression: 0.24,
        mountainPaceTrainIntensity: 0.64,
        crosswindEchelonTrigger: 0.28,
        sprintLeadoutCommitment: 0.32,
        satelliteRelayFrequency: 0.52,
        lateAttackDistanceKm: 23.0,
        riskAppetite: 0.84,
        bluffingAndPokerFaceBias: 0.38,
        gcProtectionThresholdMin: 6.2,
      ),
    ),
    const DirectorSportifTacticalProfile(
      teamId: 'team_galicia_esp',
      teamName: 'Galicia-Camino Ciclismo',
      division: TeamDivision.continental,
      countryIso: 'ESP',
      directorName: 'Ezequiel Mosquera-Paz',
      directorNationalityIso: 'ESP',
      styleCodename: 'Galicyjska Mgła i Rampa',
      archetype: DsTacticalArchetype.mountainAmbushRelay,
      primaryTerrainFocus: DsStageTerrainFocus.highMountain,
      riskTolerance: DsRiskToleranceLevel.aggressive,
      adaptationSpeed: DsAdaptationSpeed.reactive,
      signatureMove:
          'Ataki na krętych, mglistych podjazdach Galicji z wykorzystaniem pomocnika czekającego przed ostatnią rampą.',
      weaknessExploitHint:
          'Kontroluj ich ruchy już u podnóża ostatniej góry — w płaskich dolinach nie mają wsparcia.',
      radioQuote: 'We mgle nikt nie widzi różnic. Wyrwij do przodu na pierwszym zakręcie!',
      tendencies: DsTacticalTendencyProfile(
        breakawayAppetite: 0.85,
        pelotonChaseAggression: 0.28,
        mountainPaceTrainIntensity: 0.60,
        crosswindEchelonTrigger: 0.42,
        sprintLeadoutCommitment: 0.22,
        satelliteRelayFrequency: 0.72,
        lateAttackDistanceKm: 14.0,
        riskAppetite: 0.80,
        bluffingAndPokerFaceBias: 0.58,
        gcProtectionThresholdMin: 5.5,
      ),
    ),
    const DirectorSportifTacticalProfile(
      teamId: 'team_tatra_pol',
      teamName: 'Tatra-Zakopane Velo',
      division: TeamDivision.continental,
      countryIso: 'POL',
      directorName: 'Tomasz Marczyński-Góral',
      directorNationalityIso: 'POL',
      styleCodename: 'Podhalańska Ściana Gliczarowa',
      archetype: DsTacticalArchetype.komPolkaHunter,
      primaryTerrainFocus: DsStageTerrainFocus.highMountain,
      riskTolerance: DsRiskToleranceLevel.reckless,
      adaptationSpeed: DsAdaptationSpeed.improvisational,
      signatureMove:
          'Agresywne harce na krótkich, bardzo stromych ściankach >15% w poszukiwaniu skalpu nad drużynami WT.',
      weaknessExploitHint:
          'Nie daj się sprowokować na pierwszym podjeździe — zjedz żel i poczekaj na finałowe kilometry.',
      radioQuote: 'Na Gliczarowie jedziemy jak po swoje! Pełna moc w nogach!',
      tendencies: DsTacticalTendencyProfile(
        breakawayAppetite: 0.92,
        pelotonChaseAggression: 0.25,
        mountainPaceTrainIntensity: 0.65,
        crosswindEchelonTrigger: 0.35,
        sprintLeadoutCommitment: 0.20,
        satelliteRelayFrequency: 0.54,
        lateAttackDistanceKm: 16.0,
        riskAppetite: 0.88,
        bluffingAndPokerFaceBias: 0.48,
        gcProtectionThresholdMin: 6.0,
      ),
    ),
    const DirectorSportifTacticalProfile(
      teamId: 'team_sachsen_ger',
      teamName: 'Sachsen-Dresden Velo',
      division: TeamDivision.continental,
      countryIso: 'GER',
      directorName: 'Steffen Wesemann-Richter',
      directorNationalityIso: 'GER',
      styleCodename: 'Saksoński Maszynista Równin',
      archetype: DsTacticalArchetype.sprintLeadoutMachine,
      primaryTerrainFocus: DsStageTerrainFocus.flatSprint,
      riskTolerance: DsRiskToleranceLevel.calculated,
      adaptationSpeed: DsAdaptationSpeed.methodical,
      signatureMove:
          'Zdyscyplinowana pogoń wspólnie z większymi ekipami, by dowieźć szybkiego sprintera na finisz.',
      weaknessExploitHint:
          'Wprowadź podziały na krótkich podjazdach na 15 km przed metą — szybko gubią formację.',
      radioQuote: 'Pomagamy w pościgu dwoma kolarzami i walczymy o podium w sprincie!',
      tendencies: DsTacticalTendencyProfile(
        breakawayAppetite: 0.52,
        pelotonChaseAggression: 0.68,
        mountainPaceTrainIntensity: 0.28,
        crosswindEchelonTrigger: 0.64,
        sprintLeadoutCommitment: 0.85,
        satelliteRelayFrequency: 0.20,
        lateAttackDistanceKm: 1.7,
        riskAppetite: 0.46,
        bluffingAndPokerFaceBias: 0.26,
        gcProtectionThresholdMin: 6.5,
      ),
    ),
    const DirectorSportifTacticalProfile(
      teamId: 'team_bratislava_svk',
      teamName: 'Bratislava-Dunaj Cycling',
      division: TeamDivision.continental,
      countryIso: 'SVK',
      directorName: 'Ján Valach-Kováč',
      directorNationalityIso: 'SVK',
      styleCodename: 'Naddunajski Cyklon Saganowski',
      archetype: DsTacticalArchetype.cobblesAndClassicsBrawler,
      primaryTerrainFocus: DsStageTerrainFocus.hillyPuncheur,
      riskTolerance: DsRiskToleranceLevel.aggressive,
      adaptationSpeed: DsAdaptationSpeed.improvisational,
      signatureMove:
          'Nieszablonowe ataki z głębi peletonu na zakrętach i końcówkach z brukowanym finiszem pod górę.',
      weaknessExploitHint:
          'Zablokuj zewnętrzną stronę na ostatnich 400 m — szukają luki przy bandach.',
      radioQuote: 'Szukaj luki przy barierkach i wyjdź z drugiego koła na 250 metrach!',
      tendencies: DsTacticalTendencyProfile(
        breakawayAppetite: 0.83,
        pelotonChaseAggression: 0.36,
        mountainPaceTrainIntensity: 0.38,
        crosswindEchelonTrigger: 0.72,
        sprintLeadoutCommitment: 0.70,
        satelliteRelayFrequency: 0.36,
        lateAttackDistanceKm: 3.5,
        riskAppetite: 0.84,
        bluffingAndPokerFaceBias: 0.64,
        gcProtectionThresholdMin: 6.0,
      ),
    ),
  ]);

  /// Zwraca wszystkie 53 predefiniowane profile dyrektorów sportowych.
  static List<DirectorSportifTacticalProfile> get allPresetProfiles =>
      _presetProfiles;

  /// Zwraca dokładnie 52 profile drużyn AI (wykluczając drużynę gracza).
  /// Jeśli [excludePlayerTeamId] nie znajduje się na liście 53 presetów (np. drużyna własna),
  /// zwraca pierwsze 52 drużyny AI, aby zachować spójność ligi 52 rywali.
  static List<DirectorSportifTacticalProfile> getAiTeamsProfiles({
    String? excludePlayerTeamId,
    Map<String, DirectorSportifTacticalProfile> customOverrides = const {},
  }) {
    final merged = _presetProfiles
        .map((p) => customOverrides[p.teamId] ?? p)
        .toList();

    if (excludePlayerTeamId == null || excludePlayerTeamId.isEmpty) {
      return merged.take(standardAiTeamCount).toList();
    }

    final filtered =
        merged.where((p) => p.teamId != excludePlayerTeamId).toList();
    if (filtered.length > standardAiTeamCount) {
      return filtered.take(standardAiTeamCount).toList();
    }
    return filtered;
  }

  /// Wyszukuje profil DS dla konkretnej drużyny. Jeśli drużyna jest spoza presetów,
  /// deterministycznie generuje dla niej unikalny styl na podstawie [teamId].
  static DirectorSportifTacticalProfile getProfileForTeam(
    String teamId, {
    String? teamName,
    TeamDivision division = TeamDivision.proTeam,
    String countryIso = 'INT',
    Map<String, DirectorSportifTacticalProfile> customOverrides = const {},
  }) {
    final override = customOverrides[teamId];
    if (override != null) return override;

    for (final profile in _presetProfiles) {
      if (profile.teamId == teamId) return profile;
    }

    return generateProfileForCustomTeam(
      teamId: teamId,
      teamName: teamName ?? teamId,
      division: division,
      countryIso: countryIso,
    );
  }

  /// Deterministycznie generuje unikalny profil DS dla dowolnej własnej/nowej drużyny.
  static DirectorSportifTacticalProfile generateProfileForCustomTeam({
    required String teamId,
    required String teamName,
    required TeamDivision division,
    String countryIso = 'INT',
  }) {
    final seed = teamId.codeUnits.fold<int>(17, (acc, c) => acc * 31 + c);
    final rng = math.Random(seed);
    final archetype =
        DsTacticalArchetype.values[rng.nextInt(DsTacticalArchetype.values.length)];
    final terrain =
        DsStageTerrainFocus.values[rng.nextInt(DsStageTerrainFocus.values.length)];
    final risk = DsRiskToleranceLevel
        .values[rng.nextInt(DsRiskToleranceLevel.values.length)];
    final adaptation =
        DsAdaptationSpeed.values[rng.nextInt(DsAdaptationSpeed.values.length)];

    return DirectorSportifTacticalProfile(
      teamId: teamId,
      teamName: teamName,
      division: division,
      countryIso: countryIso,
      directorName: 'DS $teamName',
      directorNationalityIso: countryIso,
      styleCodename: '${archetype.shortLabel} ($teamName)',
      archetype: archetype,
      primaryTerrainFocus: terrain,
      riskTolerance: risk,
      adaptationSpeed: adaptation,
      signatureMove:
          'Dynamiczna taktyka ${archetype.label.toLowerCase()} dopasowana do składu $teamName.',
      weaknessExploitHint:
          'Wykorzystaj zmianę rytmu w końcówce etapu, aby przetestować reakcję sztabu $teamName.',
      radioQuote: 'Trzymamy nasz plan na $teamName — jedziemy z pełnym zaangażowaniem!',
      tendencies: DsTacticalTendencyProfile(
        breakawayAppetite: 0.35 + rng.nextDouble() * 0.55,
        pelotonChaseAggression: 0.25 + rng.nextDouble() * 0.65,
        mountainPaceTrainIntensity: 0.30 + rng.nextDouble() * 0.60,
        crosswindEchelonTrigger: 0.25 + rng.nextDouble() * 0.65,
        sprintLeadoutCommitment: 0.25 + rng.nextDouble() * 0.65,
        satelliteRelayFrequency: 0.25 + rng.nextDouble() * 0.55,
        lateAttackDistanceKm: 2.0 + rng.nextDouble() * 40.0,
        riskAppetite: 0.30 + rng.nextDouble() * 0.60,
        bluffingAndPokerFaceBias: 0.25 + rng.nextDouble() * 0.55,
        gcProtectionThresholdMin: 2.0 + rng.nextDouble() * 3.5,
      ),
    );
  }

  /// Wylicza konkretny plan taktyczny dyrektora sportowego AI na dany etap.
  static DsStageTacticalPlan evaluateStagePlan(
    DirectorSportifTacticalProfile profile,
    StageTacticalContextInput context,
  ) {
    final t = profile.tendencies;
    final terrainMatch = profile.primaryTerrainFocus == context.terrain ||
        profile.primaryTerrainFocus == DsStageTerrainFocus.allRounder;

    // Prawdopodobieństwo wysłania kolarzy do ucieczki dnia
    double breakawayProb = t.breakawayAppetite;
    if (profile.division == TeamDivision.continental) {
      breakawayProb += 0.10;
    }
    if (context.terrain == DsStageTerrainFocus.highMountain &&
        profile.archetype == DsTacticalArchetype.komPolkaHunter) {
      breakawayProb += 0.12;
    }
    if (context.rivalInBreakawayThreat &&
        profile.archetype == DsTacticalArchetype.skyTrainControl) {
      breakawayProb -= 0.15;
    }
    breakawayProb = breakawayProb.clamp(0.05, 0.99);

    // Prawdopodobieństwo pracy na czele pościgu peletonu
    double chaseProb = t.pelotonChaseAggression;
    if (context.terrain == DsStageTerrainFocus.flatSprint) {
      chaseProb = (chaseProb * 0.65 + t.sprintLeadoutCommitment * 0.35);
    }
    if (context.rivalInBreakawayThreat &&
        context.leaderGcGapSeconds.abs() <= t.gcProtectionThresholdMin * 60.0) {
      chaseProb += 0.22;
    }
    chaseProb = chaseProb.clamp(0.05, 0.99);

    // Prawdopodobieństwo próby rozerwania grupy wachlarzem
    double echelonProb = 0.08;
    if (context.crosswindKmh >= 18.0) {
      final windFactor = ((context.crosswindKmh - 12.0) / 18.0).clamp(0.35, 1.35);
      echelonProb = (t.crosswindEchelonTrigger * windFactor).clamp(0.10, 0.99);
    }

    // Docelowe tempo % FTP zespołu na kluczowym odcinku
    double baseTempo = 74.0 + t.mountainPaceTrainIntensity * 18.0;
    if (context.terrain == DsStageTerrainFocus.highMountain) {
      baseTempo += 4.0;
    } else if (context.terrain == DsStageTerrainFocus.flatSprint) {
      baseTempo -= 3.0;
    }
    if (context.isGrandTour && terrainMatch) {
      baseTempo += 1.5;
    }
    final recommendedTempo = baseTempo.clamp(68.0, 96.0);

    // Liczba pomocników angażowanych w kontrolę tempa
    final domestiques = ((chaseProb * 4.5) +
            (profile.archetype == DsTacticalArchetype.skyTrainControl ? 1.5 : 0.0))
        .round()
        .clamp(0, 6);

    // Aktywacja pociągu sprinterskiego i dystans planowanego ataku
    final sprintKm =
        (2.0 + t.sprintLeadoutCommitment * 9.5).clamp(1.5, 12.0);
    final attackKm = context.terrain == DsStageTerrainFocus.flatSprint
        ? sprintKm
        : t.lateAttackDistanceKm.clamp(1.0, context.distanceKm * 0.55);

    final objective = _resolvePrimaryObjective(
      profile: profile,
      context: context,
      breakawayProb: breakawayProb,
      chaseProb: chaseProb,
      echelonProb: echelonProb,
    );

    final alert =
        '${profile.directorName} (${profile.styleCodename}) planuje $objective '
        'przy tempie ${recommendedTempo.toStringAsFixed(0)}% FTP'
        '${echelonProb >= 0.60 ? ' z wysokim ryzykiem wachlarzy' : ''}.';

    return DsStageTacticalPlan(
      teamId: profile.teamId,
      teamName: profile.teamName,
      directorName: profile.directorName,
      styleCodename: profile.styleCodename,
      archetype: profile.archetype,
      recommendedTempoPctFtp: double.parse(recommendedTempo.toStringAsFixed(1)),
      sendBreakawayProbability: double.parse(breakawayProb.toStringAsFixed(2)),
      chaseBreakawayProbability: double.parse(chaseProb.toStringAsFixed(2)),
      echelonAmbushProbability: double.parse(echelonProb.toStringAsFixed(2)),
      sprintTrainActivationKm: double.parse(sprintKm.toStringAsFixed(1)),
      plannedAttackKmToGo: double.parse(attackKm.toStringAsFixed(1)),
      domestiquesCommittedToPace: domestiques,
      primaryObjectiveLabel: objective,
      tacticalAlertSummary: alert,
      counterStrategyTip: profile.weaknessExploitHint,
    );
  }

  static String _resolvePrimaryObjective({
    required DirectorSportifTacticalProfile profile,
    required StageTacticalContextInput context,
    required double breakawayProb,
    required double chaseProb,
    required double echelonProb,
  }) {
    if (echelonProb >= 0.72 && context.crosswindKmh >= 20.0) {
      return 'Rozbicie peletonu wachlarzem na wietrze';
    }
    if (context.terrain == DsStageTerrainFocus.flatSprint &&
        profile.tendencies.sprintLeadoutCommitment >= 0.75) {
      return 'Kontrola pościgu i pociąg sprinterski';
    }
    if (profile.archetype == DsTacticalArchetype.skyTrainControl &&
        context.terrain == DsStageTerrainFocus.highMountain) {
      return 'Pociąg GC i selekcja na finałowym podjeździe';
    }
    if (profile.archetype == DsTacticalArchetype.mountainAmbushRelay &&
        context.terrain == DsStageTerrainFocus.highMountain) {
      return 'Wysłanie stacji przekaźnikowej na przedostatnią przełęcz';
    }
    if (profile.archetype == DsTacticalArchetype.komPolkaHunter &&
        context.elevationGainM >= 2200) {
      return 'Walka o punkty KOM w ucieczce górskiej';
    }
    if (breakawayProb >= chaseProb) {
      return 'Aktywny udział w ucieczce dnia';
    }
    return 'Ochrona lidera i praca w głównym peletonie';
  }

  /// Tworzy kompletny raport wywiadowczy dla wszystkich 52 drużyn AI przed etapem.
  static PelotonTacticalMatchupReport buildPelotonMatchupReport({
    required String playerTeamId,
    required StageTacticalContextInput context,
    Map<String, DirectorSportifTacticalProfile> customOverrides = const {},
  }) {
    final aiProfiles = getAiTeamsProfiles(
      excludePlayerTeamId: playerTeamId,
      customOverrides: customOverrides,
    );

    final distribution = <DsTacticalArchetype, int>{};
    final plans = <DsStageTacticalPlan>[];

    for (final profile in aiProfiles) {
      distribution[profile.archetype] =
          (distribution[profile.archetype] ?? 0) + 1;
      plans.add(evaluateStagePlan(profile, context));
    }

    plans.sort((a, b) => b.threatScore.compareTo(a.threatScore));

    final expectedBreakaway = plans
        .where((p) => p.sendBreakawayProbability >= 0.75)
        .map((p) => p.teamName)
        .take(8)
        .toList();

    final expectedChase = plans
        .where((p) => p.chaseBreakawayProbability >= 0.72)
        .map((p) => p.teamName)
        .take(6)
        .toList();

    final expectedEchelon = plans
        .where((p) => p.echelonAmbushProbability >= 0.60)
        .map((p) => p.teamName)
        .take(6)
        .toList();

    return PelotonTacticalMatchupReport(
      playerTeamId: playerTeamId,
      rivalTeamCount: aiProfiles.length,
      archetypeDistribution: distribution,
      topThreatPlans: plans.take(10).toList(),
      expectedBreakawayTeams: expectedBreakaway,
      expectedChaseTeams: expectedChase,
      expectedEchelonInstigators: expectedEchelon,
    );
  }

  /// Międzysezonowa ewolucja stylu DS na podstawie wyników drużyny.
  static DirectorSportifTacticalProfile applySeasonEvolution(
    DirectorSportifTacticalProfile profile, {
    required int seasonWins,
    required int gcTop10Count,
    required bool promoted,
  }) {
    double chaseDelta = 0.0;
    double breakawayDelta = 0.0;
    double riskDelta = 0.0;

    if (promoted) {
      chaseDelta += 0.05;
      riskDelta += 0.03;
    }
    if (gcTop10Count >= 3) {
      chaseDelta += 0.06;
      breakawayDelta -= 0.04;
    } else if (seasonWins <= 2) {
      breakawayDelta += 0.05;
      riskDelta += 0.04;
    }

    final updatedTendencies = profile.tendencies.copyWith(
      pelotonChaseAggression:
          profile.tendencies.pelotonChaseAggression + chaseDelta,
      breakawayAppetite: profile.tendencies.breakawayAppetite + breakawayDelta,
      riskAppetite: profile.tendencies.riskAppetite + riskDelta,
    );

    return profile.copyWith(tendencies: updatedTendencies);
  }
}

/// Stan Riverpod przechowujący profile DS, filtry widoku oraz aktywny kontekst etapu.
class AiDirectorSportifTacticalStylesState {
  final String playerTeamId;
  final Map<String, DirectorSportifTacticalProfile> customOverrides;
  final String searchQuery;
  final TeamDivision? divisionFilter;
  final DsTacticalArchetype? archetypeFilter;
  final String? selectedTeamId;
  final StageTacticalContextInput stageContext;

  const AiDirectorSportifTacticalStylesState({
    required this.playerTeamId,
    required this.customOverrides,
    required this.searchQuery,
    required this.divisionFilter,
    required this.archetypeFilter,
    required this.selectedTeamId,
    required this.stageContext,
  });

  factory AiDirectorSportifTacticalStylesState.initial({
    String playerTeamId = 'team_polonia_orlen',
  }) {
    return AiDirectorSportifTacticalStylesState(
      playerTeamId: playerTeamId,
      customOverrides: const {},
      searchQuery: '',
      divisionFilter: null,
      archetypeFilter: null,
      selectedTeamId: 'team_aethel_ineos',
      stageContext: const StageTacticalContextInput(
        stageName: 'Etap Królewski / Klasyk',
        terrain: DsStageTerrainFocus.highMountain,
        distanceKm: 185.0,
        remainingKm: 185.0,
        crosswindKmh: 22.0,
        elevationGainM: 3650,
        isGrandTour: true,
        rivalInBreakawayThreat: true,
        leaderGcGapSeconds: 95.0,
      ),
    );
  }

  List<DirectorSportifTacticalProfile> get aiProfiles {
    return AiDirectorSportifTacticalStylesEngine.getAiTeamsProfiles(
      excludePlayerTeamId: playerTeamId,
      customOverrides: customOverrides,
    );
  }

  List<DirectorSportifTacticalProfile> get filteredProfiles {
    final q = searchQuery.trim().toLowerCase();
    return aiProfiles.where((p) {
      if (divisionFilter != null && p.division != divisionFilter) {
        return false;
      }
      if (archetypeFilter != null && p.archetype != archetypeFilter) {
        return false;
      }
      if (q.isNotEmpty) {
        final haystack =
            '${p.teamName} ${p.directorName} ${p.styleCodename} ${p.countryIso}'
                .toLowerCase();
        if (!haystack.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  DirectorSportifTacticalProfile? get selectedProfile {
    final list = filteredProfiles;
    if (list.isEmpty) return null;
    if (selectedTeamId != null) {
      for (final p in list) {
        if (p.teamId == selectedTeamId) return p;
      }
    }
    return list.first;
  }

  AiDirectorSportifTacticalStylesState copyWith({
    String? playerTeamId,
    Map<String, DirectorSportifTacticalProfile>? customOverrides,
    String? searchQuery,
    TeamDivision? divisionFilter,
    bool clearDivisionFilter = false,
    DsTacticalArchetype? archetypeFilter,
    bool clearArchetypeFilter = false,
    String? selectedTeamId,
    StageTacticalContextInput? stageContext,
  }) {
    return AiDirectorSportifTacticalStylesState(
      playerTeamId: playerTeamId ?? this.playerTeamId,
      customOverrides: customOverrides ?? this.customOverrides,
      searchQuery: searchQuery ?? this.searchQuery,
      divisionFilter:
          clearDivisionFilter ? null : (divisionFilter ?? this.divisionFilter),
      archetypeFilter: clearArchetypeFilter
          ? null
          : (archetypeFilter ?? this.archetypeFilter),
      selectedTeamId: selectedTeamId ?? this.selectedTeamId,
      stageContext: stageContext ?? this.stageContext,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playerTeamId': playerTeamId,
      'customOverrides':
          customOverrides.map((k, v) => MapEntry(k, v.toJson())),
      'searchQuery': searchQuery,
      'divisionFilter': divisionFilter?.toJson(),
      'archetypeFilter': archetypeFilter?.toJson(),
      'selectedTeamId': selectedTeamId,
      'stageContext': stageContext.toJson(),
    };
  }

  factory AiDirectorSportifTacticalStylesState.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawOverrides =
        (json['customOverrides'] as Map<String, dynamic>?) ?? const {};
    final overrides = <String, DirectorSportifTacticalProfile>{};
    for (final entry in rawOverrides.entries) {
      if (entry.value is Map<String, dynamic>) {
        overrides[entry.key] = DirectorSportifTacticalProfile.fromJson(
          entry.value as Map<String, dynamic>,
        );
      }
    }

    return AiDirectorSportifTacticalStylesState(
      playerTeamId: json['playerTeamId'] as String? ?? 'team_polonia_orlen',
      customOverrides: overrides,
      searchQuery: json['searchQuery'] as String? ?? '',
      divisionFilter: json['divisionFilter'] != null
          ? TeamDivision.fromJson(json['divisionFilter'] as String)
          : null,
      archetypeFilter: json['archetypeFilter'] != null
          ? DsTacticalArchetype.fromJson(json['archetypeFilter'] as String)
          : null,
      selectedTeamId: json['selectedTeamId'] as String?,
      stageContext: StageTacticalContextInput.fromJson(
        (json['stageContext'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }
}

/// Notifier zarządzający stanem stylów taktycznych 52 drużyn AI.
class AiDirectorSportifTacticalStylesNotifier
    extends StateNotifier<AiDirectorSportifTacticalStylesState> {
  AiDirectorSportifTacticalStylesNotifier()
      : super(AiDirectorSportifTacticalStylesState.initial());

  void setPlayerTeam(String teamId) {
    state = state.copyWith(playerTeamId: teamId);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setDivisionFilter(TeamDivision? division) {
    if (division == null) {
      state = state.copyWith(clearDivisionFilter: true);
    } else {
      state = state.copyWith(divisionFilter: division);
    }
  }

  void setArchetypeFilter(DsTacticalArchetype? archetype) {
    if (archetype == null) {
      state = state.copyWith(clearArchetypeFilter: true);
    } else {
      state = state.copyWith(archetypeFilter: archetype);
    }
  }

  void selectTeam(String teamId) {
    state = state.copyWith(selectedTeamId: teamId);
  }

  void setStageTerrain(DsStageTerrainFocus terrain) {
    state = state.copyWith(
      stageContext: StageTacticalContextInput(
        stageName: terrain.label,
        terrain: terrain,
        distanceKm: state.stageContext.distanceKm,
        remainingKm: state.stageContext.remainingKm,
        crosswindKmh: state.stageContext.crosswindKmh,
        elevationGainM: terrain == DsStageTerrainFocus.highMountain
            ? 3800
            : (terrain == DsStageTerrainFocus.flatSprint ? 650 : 1950),
        isGrandTour: state.stageContext.isGrandTour,
        hasCobbleSectors: terrain == DsStageTerrainFocus.cobblesClassic,
        leaderGcGapSeconds: state.stageContext.leaderGcGapSeconds,
        rivalInBreakawayThreat: state.stageContext.rivalInBreakawayThreat,
      ),
    );
  }

  void setCrosswindKmh(double windKmh) {
    state = state.copyWith(
      stageContext: StageTacticalContextInput(
        stageName: state.stageContext.stageName,
        terrain: state.stageContext.terrain,
        distanceKm: state.stageContext.distanceKm,
        remainingKm: state.stageContext.remainingKm,
        crosswindKmh: windKmh.clamp(0.0, 55.0),
        elevationGainM: state.stageContext.elevationGainM,
        isGrandTour: state.stageContext.isGrandTour,
        hasCobbleSectors: state.stageContext.hasCobbleSectors,
        leaderGcGapSeconds: state.stageContext.leaderGcGapSeconds,
        rivalInBreakawayThreat: state.stageContext.rivalInBreakawayThreat,
      ),
    );
  }

  void evolveTeamStyleAfterSeason({
    required String teamId,
    required int seasonWins,
    required int gcTop10Count,
    required bool promoted,
  }) {
    final current = AiDirectorSportifTacticalStylesEngine.getProfileForTeam(
      teamId,
      customOverrides: state.customOverrides,
    );
    final evolved = AiDirectorSportifTacticalStylesEngine.applySeasonEvolution(
      current,
      seasonWins: seasonWins,
      gcTop10Count: gcTop10Count,
      promoted: promoted,
    );
    final nextOverrides =
        Map<String, DirectorSportifTacticalProfile>.from(state.customOverrides);
    nextOverrides[teamId] = evolved;
    state = state.copyWith(customOverrides: nextOverrides);
  }

  void resetFilters() {
    state = state.copyWith(
      searchQuery: '',
      clearDivisionFilter: true,
      clearArchetypeFilter: true,
    );
  }

  void restoreFromJson(Map<String, dynamic> json) {
    state = AiDirectorSportifTacticalStylesState.fromJson(json);
  }
}

final aiDirectorSportifTacticalStylesProvider = StateNotifierProvider<
    AiDirectorSportifTacticalStylesNotifier,
    AiDirectorSportifTacticalStylesState>(
  (ref) => AiDirectorSportifTacticalStylesNotifier(),
);

/// Produkcyjny, responsywny panel wywiadu taktycznego 52 dyrektorów sportowych AI.
class AiDirectorSportifTacticalStylesPanel extends ConsumerStatefulWidget {
  final bool isReadOnly;

  const AiDirectorSportifTacticalStylesPanel({
    super.key,
    this.isReadOnly = false,
  });

  @override
  ConsumerState<AiDirectorSportifTacticalStylesPanel> createState() =>
      _AiDirectorSportifTacticalStylesPanelState();
}

class _AiDirectorSportifTacticalStylesPanelState
    extends ConsumerState<AiDirectorSportifTacticalStylesPanel> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiDirectorSportifTacticalStylesProvider);
    final notifier = ref.read(aiDirectorSportifTacticalStylesProvider.notifier);
    final filtered = state.filteredProfiles;
    final selected = state.selectedProfile;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 1100;
          final isTablet =
              constraints.maxWidth >= 680 && constraints.maxWidth < 1100;

          return Padding(
            padding: EdgeInsets.all(isDesktop ? 20.0 : 14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(state, filtered.length),
                const SizedBox(height: 14),
                _buildFilterToolbar(state, notifier, isDesktop || isTablet),
                const SizedBox(height: 14),
                if (isDesktop || isTablet)
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: isDesktop ? 5 : 4,
                          child: _buildTeamsList(
                            filtered,
                            selected?.teamId,
                            notifier,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: isDesktop ? 7 : 6,
                          child: _buildDetailPanel(selected, state.stageContext),
                        ),
                      ],
                    ),
                  )
                else
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: 260,
                            child: _buildTeamsList(
                              filtered,
                              selected?.teamId,
                              notifier,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildDetailPanel(
                            selected,
                            state.stageContext,
                            shrinkWrap: true,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(
    AiDirectorSportifTacticalStylesState state,
    int visibleCount,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryAccent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryAccent.withValues(alpha: 0.45),
              ),
            ),
            child: const Icon(
              Icons.psychology_alt_rounded,
              color: AppColors.goldAccent,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Wywiad Taktyczny Dyrektorów Sportowych AI',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
                  'Unikalne doktryny taktyczne wszystkich ${state.aiProfiles.length} drużyn AI',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Text(
              '$visibleCount / ${state.aiProfiles.length} drużyn',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.goldAccent,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterToolbar(
    AiDirectorSportifTacticalStylesState state,
    AiDirectorSportifTacticalStylesNotifier notifier,
    bool isWide,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: isWide ? 280 : double.infinity,
                child: TextField(
                  controller: _searchController,
                  enabled: !widget.isReadOnly,
                  onChanged: notifier.setSearchQuery,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Szukaj drużyny, DS lub stylu...',
                    hintStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.goldAccent),
                    ),
                  ),
                ),
              ),
              _InteractiveFilterChip(
                label: 'Wszystkie',
                selected: state.divisionFilter == null,
                disabled: widget.isReadOnly,
                onTap: () => notifier.setDivisionFilter(null),
              ),
              for (final div in TeamDivision.values)
                _InteractiveFilterChip(
                  label: div.label.replaceFirst('UCI ', ''),
                  selected: state.divisionFilter == div,
                  disabled: widget.isReadOnly,
                  onTap: () => notifier.setDivisionFilter(div),
                ),
              _InteractiveFilterChip(
                label: 'Reset',
                selected: false,
                disabled: widget.isReadOnly,
                icon: Icons.refresh_rounded,
                onTap: () {
                  _searchController.clear();
                  notifier.resetFilters();
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text(
                  'Symuluj teren:',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                for (final terrain in DsStageTerrainFocus.values) ...[
                  _InteractiveFilterChip(
                    label: terrain.label,
                    selected: state.stageContext.terrain == terrain,
                    disabled: widget.isReadOnly,
                    accentColor: AppColors.accentBlue,
                    onTap: () => notifier.setStageTerrain(terrain),
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamsList(
    List<DirectorSportifTacticalProfile> profiles,
    String? selectedTeamId,
    AiDirectorSportifTacticalStylesNotifier notifier,
  ) {
    if (profiles.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: const Center(
          child: Text(
            'Brak drużyn AI spełniających wybrane kryteria.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(10),
        itemCount: profiles.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final profile = profiles[index];
          final isSelected = profile.teamId == selectedTeamId;
          return _TeamStyleTile(
            profile: profile,
            isSelected: isSelected,
            disabled: widget.isReadOnly,
            onTap: () => notifier.selectTeam(profile.teamId),
          );
        },
      ),
    );
  }

  Widget _buildDetailPanel(
    DirectorSportifTacticalProfile? profile,
    StageTacticalContextInput stageContext, {
    bool shrinkWrap = false,
  }) {
    if (profile == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: const Center(
          child: Text(
            'Wybierz drużynę AI z listy, aby wyświetlić dossier taktyczne.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    final plan = AiDirectorSportifTacticalStylesEngine.evaluateStagePlan(
      profile,
      stageContext,
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: profile.archetype.accentColor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: profile.archetype.accentColor.withValues(alpha: 0.5),
                ),
              ),
              child: Icon(
                profile.archetype.icon,
                color: profile.archetype.accentColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.teamName,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'DS: ${profile.directorName} (${profile.directorNationalityIso}) • ${profile.division.label}',
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Text(
                'Agresja ${profile.tendencies.tacticalAggressionIndex}/100',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.goldAccent,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MetaPill(
              label: profile.styleCodename,
              color: profile.archetype.accentColor,
            ),
            _MetaPill(
              label: profile.archetype.label,
              color: AppColors.accentBlue,
            ),
            _MetaPill(
              label: 'Ryzyko: ${profile.riskTolerance.label}',
              color: AppColors.amberWarning,
            ),
            _MetaPill(
              label: 'Adaptacja: ${profile.adaptationSpeed.label}',
              color: AppColors.statusSuccess,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Text(
            '„${profile.radioQuote}”',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: AppColors.goldAccent,
            ),
          ),
        ),
        const SizedBox(height: 14),
        _buildInfoSection(
          title: 'Znak rozpoznawczy DS',
          body: profile.signatureMove,
          icon: Icons.bolt_rounded,
          accent: profile.archetype.accentColor,
        ),
        const SizedBox(height: 10),
        _buildInfoSection(
          title: 'Jak skontrować ten styl (Wywiad)',
          body: profile.weaknessExploitHint,
          icon: Icons.shield_outlined,
          accent: AppColors.statusSuccess,
        ),
        const SizedBox(height: 14),
        const Text(
          'Wskaźniki Tendencji Taktycznych',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        _TendencyBar(
          label: 'Apetyt na ucieczkę dnia',
          value: profile.tendencies.breakawayAppetite,
          color: AppColors.statusSuccess,
        ),
        _TendencyBar(
          label: 'Agresja pościgu peletonu',
          value: profile.tendencies.pelotonChaseAggression,
          color: AppColors.accentBlue,
        ),
        _TendencyBar(
          label: 'Pociąg górski (% tempa)',
          value: profile.tendencies.mountainPaceTrainIntensity,
          color: AppColors.goldAccent,
        ),
        _TendencyBar(
          label: 'Polowanie na wachlarze (wiatr)',
          value: profile.tendencies.crosswindEchelonTrigger,
          color: AppColors.amberWarning,
        ),
        _TendencyBar(
          label: 'Zaangażowanie w pociąg sprinterski',
          value: profile.tendencies.sprintLeadoutCommitment,
          color: AppColors.cyanAccent,
        ),
        _TendencyBar(
          label: 'Taktyka stacji przekaźnikowych',
          value: profile.tendencies.satelliteRelayFrequency,
          color: AppColors.primaryAccent,
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.accentBlue.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Prognoza na etap: ${stageContext.terrain.label}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentBlue,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                plan.tacticalAlertSummary,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  _StatBadge(
                    label: 'Tempo',
                    value: '${plan.recommendedTempoPctFtp.toStringAsFixed(0)}% FTP',
                  ),
                  _StatBadge(
                    label: 'Szansa ucieczki',
                    value:
                        '${(plan.sendBreakawayProbability * 100).round()}%',
                  ),
                  _StatBadge(
                    label: 'Pomocnicy na czole',
                    value: '${plan.domestiquesCommittedToPace}',
                  ),
                  _StatBadge(
                    label: 'Atak ok.',
                    value: '${plan.plannedAttackKmToGo.toStringAsFixed(1)} km',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: shrinkWrap ? content : SingleChildScrollView(child: content),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required String body,
    required IconData icon,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textPrimary,
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

class _TeamStyleTile extends StatefulWidget {
  final DirectorSportifTacticalProfile profile;
  final bool isSelected;
  final bool disabled;
  final VoidCallback onTap;

  const _TeamStyleTile({
    required this.profile,
    required this.isSelected,
    required this.disabled,
    required this.onTap,
  });

  @override
  State<_TeamStyleTile> createState() => _TeamStyleTileState();
}

class _TeamStyleTileState extends State<_TeamStyleTile> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.profile.archetype.accentColor;
    final borderColor = widget.isSelected
        ? AppColors.goldAccent
        : (_isFocused
            ? AppColors.accentBlue
            : (_isHovered ? accent.withValues(alpha: 0.7) : AppColors.cardBorder));

    return FocusableActionDetector(
      enabled: !widget.disabled,
      onShowFocusHighlight: (focused) => setState(() => _isFocused = focused),
      child: MouseRegion(
        cursor:
            widget.disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.disabled ? null : widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? AppColors.surfaceLight
                  : (_isHovered
                      ? AppColors.surfaceLight.withValues(alpha: 0.7)
                      : AppColors.background),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: widget.isSelected ? 1.5 : 1.0),
            ),
            child: Row(
              children: [
                Icon(
                  widget.profile.archetype.icon,
                  size: 20,
                  color: accent,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.profile.teamName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.profile.directorName} • ${widget.profile.styleCodename}',
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
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.profile.archetype.shortLabel,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: accent,
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

class _InteractiveFilterChip extends StatefulWidget {
  final String label;
  final bool selected;
  final bool disabled;
  final IconData? icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _InteractiveFilterChip({
    required this.label,
    required this.selected,
    required this.disabled,
    required this.onTap,
    this.icon,
    this.accentColor = AppColors.goldAccent,
  });

  @override
  State<_InteractiveFilterChip> createState() => _InteractiveFilterChipState();
}

class _InteractiveFilterChipState extends State<_InteractiveFilterChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.selected
        ? widget.accentColor.withValues(alpha: 0.22)
        : (_hovered ? AppColors.surfaceLight : AppColors.background);
    final borderColor = widget.selected
        ? widget.accentColor
        : (_focused ? AppColors.accentBlue : AppColors.cardBorder);

    return FocusableActionDetector(
      enabled: !widget.disabled,
      onShowFocusHighlight: (focused) => setState(() => _focused = focused),
      child: MouseRegion(
        cursor:
            widget.disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.disabled ? null : widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: widget.disabled
                  ? AppColors.surface.withValues(alpha: 0.5)
                  : bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    size: 14,
                    color: widget.disabled
                        ? AppColors.textSecondary.withValues(alpha: 0.4)
                        : AppColors.textPrimary,
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight:
                        widget.selected ? FontWeight.w700 : FontWeight.w500,
                    color: widget.disabled
                        ? AppColors.textSecondary.withValues(alpha: 0.4)
                        : (widget.selected
                            ? widget.accentColor
                            : AppColors.textPrimary),
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

class _MetaPill extends StatelessWidget {
  final String label;
  final Color color;

  const _MetaPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
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

class _TendencyBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _TendencyBar({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (value.clamp(0.0, 1.0) * 100).round();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
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
              Text(
                '$pct%',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: AppColors.background,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;

  const _StatBadge({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: RichText(
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
                fontWeight: FontWeight.w700,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
