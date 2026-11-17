import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/race/race_stage.dart';
import '../../models/rider/rider.dart';
import '../../models/team/cycling_team.dart';

/// Przydział kolarza do jednego z dwóch równoległych frontów wyścigowych lub rezerwy.
enum ParallelFrontSlot {
  frontA,
  frontB,
  reserve;

  String toJson() => name;

  String get labelPl {
    switch (this) {
      case ParallelFrontSlot.frontA:
        return 'Front A';
      case ParallelFrontSlot.frontB:
        return 'Front B';
      case ParallelFrontSlot.reserve:
        return 'Rezerwa / Odpoczynek';
    }
  }

  static ParallelFrontSlot fromJson(String value) {
    return ParallelFrontSlot.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ParallelFrontSlot.reserve,
    );
  }
}

/// Profil terenu wyścigu na danym froncie.
enum ParallelRaceTerrain {
  flat,
  hilly,
  highMountain,
  cobbleClassic,
  timeTrial;

  String toJson() => name;

  String get labelPl {
    switch (this) {
      case ParallelRaceTerrain.flat:
        return 'Płaski / Sprint';
      case ParallelRaceTerrain.hilly:
        return 'Pagórkowaty / Ardeny';
      case ParallelRaceTerrain.highMountain:
        return 'Wysokie Góry';
      case ParallelRaceTerrain.cobbleClassic:
        return 'Bruk / Klasyk';
      case ParallelRaceTerrain.timeTrial:
        return 'Jazda na Czas (ITT)';
    }
  }

  IconData get icon {
    switch (this) {
      case ParallelRaceTerrain.flat:
        return Icons.bolt_rounded;
      case ParallelRaceTerrain.hilly:
        return Icons.terrain_rounded;
      case ParallelRaceTerrain.highMountain:
        return Icons.landscape_rounded;
      case ParallelRaceTerrain.cobbleClassic:
        return Icons.grid_view_rounded;
      case ParallelRaceTerrain.timeTrial:
        return Icons.timer_rounded;
    }
  }

  static ParallelRaceTerrain fromJson(String value) {
    return ParallelRaceTerrain.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ParallelRaceTerrain.flat,
    );
  }
}

/// Ranga wyścigu determinująca pulę punktów UCI, nagród i wymaganą liczbę kolarzy.
enum ParallelRaceTier {
  grandTour,
  monument,
  worldTourStage,
  worldTourOneDay,
  proSeries,
  class1;

  String toJson() => name;

  String get labelPl {
    switch (this) {
      case ParallelRaceTier.grandTour:
        return 'Grand Tour (WT)';
      case ParallelRaceTier.monument:
        return 'Monument (WT)';
      case ParallelRaceTier.worldTourStage:
        return 'WorldTour Etapówka';
      case ParallelRaceTier.worldTourOneDay:
        return 'WorldTour Klasyk';
      case ParallelRaceTier.proSeries:
        return 'UCI ProSeries';
      case ParallelRaceTier.class1:
        return 'UCI 1.1 / 2.1';
    }
  }

  int get uciWinnerPoints {
    switch (this) {
      case ParallelRaceTier.grandTour:
        return 210;
      case ParallelRaceTier.monument:
        return 800;
      case ParallelRaceTier.worldTourStage:
        return 100;
      case ParallelRaceTier.worldTourOneDay:
        return 500;
      case ParallelRaceTier.proSeries:
        return 200;
      case ParallelRaceTier.class1:
        return 125;
    }
  }

  int get defaultMinRiders {
    switch (this) {
      case ParallelRaceTier.grandTour:
        return 8;
      case ParallelRaceTier.monument:
      case ParallelRaceTier.worldTourStage:
      case ParallelRaceTier.worldTourOneDay:
        return 7;
      case ParallelRaceTier.proSeries:
      case ParallelRaceTier.class1:
        return 6;
    }
  }

  int get defaultMaxRiders {
    switch (this) {
      case ParallelRaceTier.grandTour:
        return 8;
      case ParallelRaceTier.monument:
      case ParallelRaceTier.worldTourStage:
      case ParallelRaceTier.worldTourOneDay:
      case ParallelRaceTier.proSeries:
      case ParallelRaceTier.class1:
        return 7;
    }
  }

  int get basePrizePoolEur {
    switch (this) {
      case ParallelRaceTier.grandTour:
        return 28000;
      case ParallelRaceTier.monument:
        return 50000;
      case ParallelRaceTier.worldTourStage:
        return 14000;
      case ParallelRaceTier.worldTourOneDay:
        return 35000;
      case ParallelRaceTier.proSeries:
        return 18000;
      case ParallelRaceTier.class1:
        return 9000;
    }
  }

  static ParallelRaceTier fromJson(String value) {
    return ParallelRaceTier.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ParallelRaceTier.worldTourStage,
    );
  }
}

/// Strategia automatycznego podziału 28-osobowej kadry na dwa fronty.
enum ParallelSplitStrategy {
  prioritizeFrontA,
  balanced,
  prioritizeFrontB,
  freshnessFirst;

  String toJson() => name;

  String get labelPl {
    switch (this) {
      case ParallelSplitStrategy.prioritizeFrontA:
        return 'Priorytet Front A';
      case ParallelSplitStrategy.balanced:
        return 'Równomierny Podział';
      case ParallelSplitStrategy.prioritizeFrontB:
        return 'Priorytet Front B';
      case ParallelSplitStrategy.freshnessFirst:
        return 'Ochrona Świeżości (TSB)';
    }
  }

  static ParallelSplitStrategy fromJson(String value) {
    return ParallelSplitStrategy.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ParallelSplitStrategy.prioritizeFrontA,
    );
  }
}

/// Poziom ważności problemu walidacyjnego przy podziale składu.
enum ParallelValidationSeverity {
  ok,
  warning,
  error;

  String toJson() => name;

  static ParallelValidationSeverity fromJson(String value) {
    return ParallelValidationSeverity.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ParallelValidationSeverity.ok,
    );
  }
}

/// Specyfikacja pojedynczego wyścigu (etapu lub klasyku) odbywającego się w tym samym dniu.
class ParallelRaceEventSpec {
  final String raceId;
  final String raceName;
  final int stageNumber;
  final String stageName;
  final ParallelRaceTerrain terrain;
  final ParallelRaceTier tier;
  final double distanceKm;
  final int elevationGainM;
  final int requiredMinRiders;
  final int requiredMaxRiders;
  final WeatherCondition weatherCondition;
  final double windSpeedKmh;
  final double priorityWeight;

  const ParallelRaceEventSpec({
    required this.raceId,
    required this.raceName,
    this.stageNumber = 1,
    required this.stageName,
    required this.terrain,
    required this.tier,
    required this.distanceKm,
    required this.elevationGainM,
    required this.requiredMinRiders,
    required this.requiredMaxRiders,
    this.weatherCondition = WeatherCondition.sunny,
    this.windSpeedKmh = 12.0,
    this.priorityWeight = 0.5,
  });

  ParallelRaceEventSpec copyWith({
    String? raceId,
    String? raceName,
    int? stageNumber,
    String? stageName,
    ParallelRaceTerrain? terrain,
    ParallelRaceTier? tier,
    double? distanceKm,
    int? elevationGainM,
    int? requiredMinRiders,
    int? requiredMaxRiders,
    WeatherCondition? weatherCondition,
    double? windSpeedKmh,
    double? priorityWeight,
  }) {
    return ParallelRaceEventSpec(
      raceId: raceId ?? this.raceId,
      raceName: raceName ?? this.raceName,
      stageNumber: stageNumber ?? this.stageNumber,
      stageName: stageName ?? this.stageName,
      terrain: terrain ?? this.terrain,
      tier: tier ?? this.tier,
      distanceKm: distanceKm ?? this.distanceKm,
      elevationGainM: elevationGainM ?? this.elevationGainM,
      requiredMinRiders: requiredMinRiders ?? this.requiredMinRiders,
      requiredMaxRiders: requiredMaxRiders ?? this.requiredMaxRiders,
      weatherCondition: weatherCondition ?? this.weatherCondition,
      windSpeedKmh: windSpeedKmh ?? this.windSpeedKmh,
      priorityWeight: priorityWeight ?? this.priorityWeight,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'raceId': raceId,
      'raceName': raceName,
      'stageNumber': stageNumber,
      'stageName': stageName,
      'terrain': terrain.toJson(),
      'tier': tier.toJson(),
      'distanceKm': distanceKm,
      'elevationGainM': elevationGainM,
      'requiredMinRiders': requiredMinRiders,
      'requiredMaxRiders': requiredMaxRiders,
      'weatherCondition': weatherCondition.toJson(),
      'windSpeedKmh': windSpeedKmh,
      'priorityWeight': priorityWeight,
    };
  }

  factory ParallelRaceEventSpec.fromJson(Map<String, dynamic> json) {
    return ParallelRaceEventSpec(
      raceId: json['raceId'] as String,
      raceName: json['raceName'] as String,
      stageNumber: (json['stageNumber'] as num?)?.toInt() ?? 1,
      stageName: json['stageName'] as String,
      terrain: ParallelRaceTerrain.fromJson(json['terrain'] as String),
      tier: ParallelRaceTier.fromJson(json['tier'] as String),
      distanceKm: (json['distanceKm'] as num).toDouble(),
      elevationGainM: (json['elevationGainM'] as num).toInt(),
      requiredMinRiders: (json['requiredMinRiders'] as num).toInt(),
      requiredMaxRiders: (json['requiredMaxRiders'] as num).toInt(),
      weatherCondition: WeatherCondition.fromJson(
        (json['weatherCondition'] as String?) ?? 'sunny',
      ),
      windSpeedKmh: (json['windSpeedKmh'] as num?)?.toDouble() ?? 12.0,
      priorityWeight: (json['priorityWeight'] as num?)?.toDouble() ?? 0.5,
    );
  }
}

/// Znormalizowany profil kolarza z 28-osobowej kadry do podziału na dwa fronty.
class ParallelRosterRiderSnapshot {
  final String riderId;
  final String fullName;
  final String nationalityIso;
  final RiderSpecialization specialization;
  final int overallRating;
  final int climbingScore;
  final int sprintScore;
  final int cobblesScore;
  final int timeTrialScore;
  final int domestiqueEngineScore;
  final double tsb;
  final double fatigueAtl;
  final double fitnessCtl;
  final bool isFitToRace;
  final String? injuryLabel;

  const ParallelRosterRiderSnapshot({
    required this.riderId,
    required this.fullName,
    required this.nationalityIso,
    required this.specialization,
    required this.overallRating,
    required this.climbingScore,
    required this.sprintScore,
    required this.cobblesScore,
    required this.timeTrialScore,
    required this.domestiqueEngineScore,
    required this.tsb,
    required this.fatigueAtl,
    required this.fitnessCtl,
    required this.isFitToRace,
    this.injuryLabel,
  });

  /// Tworzy migawkę kolarza bezpośrednio z domenowego modelu [Rider].
  factory ParallelRosterRiderSnapshot.fromRider(Rider rider) {
    final double weight =
        rider.physiology.weightKg > 0 ? rider.physiology.weightKg : 70.0;
    final double wPerKg20 = rider.powerProfile.watts20m / weight;
    final int climb =
        (((wPerKg20 - 3.5) / 3.1) * 55 + 44).clamp(40, 99).round();
    final int sprint =
        (((rider.powerProfile.watts5s - 900.0) / 850.0) * 55 + 44)
            .clamp(40, 99)
            .round();
    final int cobbles = rider.skills.cobbles.clamp(40, 99);
    final int tt =
        ((rider.skills.timeTrialPositioning * 0.5) + (climb * 0.5))
            .clamp(40, 99)
            .round();
    final int engine =
        ((rider.skills.draftingEfficiency * 0.5) + (rider.skills.raceIq * 0.5))
            .clamp(40, 99)
            .round();

    return ParallelRosterRiderSnapshot(
      riderId: rider.id,
      fullName: rider.fullName,
      nationalityIso: rider.nationalityIso,
      specialization: rider.specialization,
      overallRating: rider.overallRating,
      climbingScore: climb,
      sprintScore: sprint,
      cobblesScore: cobbles,
      timeTrialScore: tt,
      domestiqueEngineScore: engine,
      tsb: rider.health.trainingStressBalance,
      fatigueAtl: rider.health.acuteTrainingLoad,
      fitnessCtl: rider.health.chronicTrainingLoad,
      isFitToRace: rider.health.isFitToRace,
      injuryLabel: rider.health.currentInjury?.name ?? rider.health.currentIllness,
    );
  }

  /// Wylicza dopasowanie kolarza (0..100) do konkretnego profilu trasy z uwzględnieniem świeżości TSB.
  double terrainAffinityScore(ParallelRaceTerrain terrain) {
    final double base;
    switch (terrain) {
      case ParallelRaceTerrain.flat:
        base = (sprintScore * 0.58) +
            (domestiqueEngineScore * 0.27) +
            (overallRating * 0.15);
      case ParallelRaceTerrain.hilly:
        base = (climbingScore * 0.38) +
            (sprintScore * 0.24) +
            (overallRating * 0.38);
      case ParallelRaceTerrain.highMountain:
        base = (climbingScore * 0.68) +
            (overallRating * 0.22) +
            (domestiqueEngineScore * 0.10);
      case ParallelRaceTerrain.cobbleClassic:
        base = (cobblesScore * 0.62) +
            (domestiqueEngineScore * 0.22) +
            (sprintScore * 0.16);
      case ParallelRaceTerrain.timeTrial:
        base = (timeTrialScore * 0.72) +
            (overallRating * 0.18) +
            (domestiqueEngineScore * 0.10);
    }

    // Modyfikator formy / zmęczenia TSB (-35..+25)
    final double tsbModifier = (tsb / 4.5).clamp(-9.0, 6.0);
    return (base + tsbModifier).clamp(20.0, 105.0);
  }

  ParallelRosterRiderSnapshot copyWith({
    String? riderId,
    String? fullName,
    String? nationalityIso,
    RiderSpecialization? specialization,
    int? overallRating,
    int? climbingScore,
    int? sprintScore,
    int? cobblesScore,
    int? timeTrialScore,
    int? domestiqueEngineScore,
    double? tsb,
    double? fatigueAtl,
    double? fitnessCtl,
    bool? isFitToRace,
    String? injuryLabel,
    bool clearInjuryLabel = false,
  }) {
    return ParallelRosterRiderSnapshot(
      riderId: riderId ?? this.riderId,
      fullName: fullName ?? this.fullName,
      nationalityIso: nationalityIso ?? this.nationalityIso,
      specialization: specialization ?? this.specialization,
      overallRating: overallRating ?? this.overallRating,
      climbingScore: climbingScore ?? this.climbingScore,
      sprintScore: sprintScore ?? this.sprintScore,
      cobblesScore: cobblesScore ?? this.cobblesScore,
      timeTrialScore: timeTrialScore ?? this.timeTrialScore,
      domestiqueEngineScore:
          domestiqueEngineScore ?? this.domestiqueEngineScore,
      tsb: tsb ?? this.tsb,
      fatigueAtl: fatigueAtl ?? this.fatigueAtl,
      fitnessCtl: fitnessCtl ?? this.fitnessCtl,
      isFitToRace: isFitToRace ?? this.isFitToRace,
      injuryLabel: clearInjuryLabel ? null : (injuryLabel ?? this.injuryLabel),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'fullName': fullName,
      'nationalityIso': nationalityIso,
      'specialization': specialization.toJson(),
      'overallRating': overallRating,
      'climbingScore': climbingScore,
      'sprintScore': sprintScore,
      'cobblesScore': cobblesScore,
      'timeTrialScore': timeTrialScore,
      'domestiqueEngineScore': domestiqueEngineScore,
      'tsb': tsb,
      'fatigueAtl': fatigueAtl,
      'fitnessCtl': fitnessCtl,
      'isFitToRace': isFitToRace,
      'injuryLabel': injuryLabel,
    };
  }

  factory ParallelRosterRiderSnapshot.fromJson(Map<String, dynamic> json) {
    return ParallelRosterRiderSnapshot(
      riderId: json['riderId'] as String,
      fullName: json['fullName'] as String,
      nationalityIso: json['nationalityIso'] as String,
      specialization:
          RiderSpecialization.fromJson(json['specialization'] as String),
      overallRating: (json['overallRating'] as num).toInt(),
      climbingScore: (json['climbingScore'] as num).toInt(),
      sprintScore: (json['sprintScore'] as num).toInt(),
      cobblesScore: (json['cobblesScore'] as num).toInt(),
      timeTrialScore: (json['timeTrialScore'] as num).toInt(),
      domestiqueEngineScore: (json['domestiqueEngineScore'] as num).toInt(),
      tsb: (json['tsb'] as num).toDouble(),
      fatigueAtl: (json['fatigueAtl'] as num).toDouble(),
      fitnessCtl: (json['fitnessCtl'] as num).toDouble(),
      isFitToRace: json['isFitToRace'] as bool,
      injuryLabel: json['injuryLabel'] as String?,
    );
  }
}

/// Podział sztabu technicznego i logistyki pomiędzy dwa równoległe fronty.
class ParallelStaffSplitConfig {
  final int frontADirectorLevel;
  final int frontBDirectorLevel;
  final int frontAMechanicsLevel;
  final int frontBMechanicsLevel;
  final bool frontATeamBusAvailable;
  final bool frontBTeamBusAvailable;

  const ParallelStaffSplitConfig({
    this.frontADirectorLevel = 82,
    this.frontBDirectorLevel = 68,
    this.frontAMechanicsLevel = 85,
    this.frontBMechanicsLevel = 72,
    this.frontATeamBusAvailable = true,
    this.frontBTeamBusAvailable = false,
  });

  factory ParallelStaffSplitConfig.fromTeamStaff(
    TeamStaff staff, {
    bool primaryBusOnFrontA = true,
    bool hasSecondBus = false,
  }) {
    final int mainDs = staff.sportsDirectorsLevel.clamp(40, 100);
    final int assistantDs = (mainDs - 14).clamp(35, 95);
    final int mainMech = staff.mechanicsLevel.clamp(40, 100);
    final int assistantMech = (mainMech - 12).clamp(35, 95);

    return ParallelStaffSplitConfig(
      frontADirectorLevel: primaryBusOnFrontA ? mainDs : assistantDs,
      frontBDirectorLevel: primaryBusOnFrontA ? assistantDs : mainDs,
      frontAMechanicsLevel: primaryBusOnFrontA ? mainMech : assistantMech,
      frontBMechanicsLevel: primaryBusOnFrontA ? assistantMech : mainMech,
      frontATeamBusAvailable: primaryBusOnFrontA || hasSecondBus,
      frontBTeamBusAvailable: !primaryBusOnFrontA || hasSecondBus,
    );
  }

  ParallelStaffSplitConfig copyWith({
    int? frontADirectorLevel,
    int? frontBDirectorLevel,
    int? frontAMechanicsLevel,
    int? frontBMechanicsLevel,
    bool? frontATeamBusAvailable,
    bool? frontBTeamBusAvailable,
  }) {
    return ParallelStaffSplitConfig(
      frontADirectorLevel: frontADirectorLevel ?? this.frontADirectorLevel,
      frontBDirectorLevel: frontBDirectorLevel ?? this.frontBDirectorLevel,
      frontAMechanicsLevel: frontAMechanicsLevel ?? this.frontAMechanicsLevel,
      frontBMechanicsLevel: frontBMechanicsLevel ?? this.frontBMechanicsLevel,
      frontATeamBusAvailable:
          frontATeamBusAvailable ?? this.frontATeamBusAvailable,
      frontBTeamBusAvailable:
          frontBTeamBusAvailable ?? this.frontBTeamBusAvailable,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'frontADirectorLevel': frontADirectorLevel,
      'frontBDirectorLevel': frontBDirectorLevel,
      'frontAMechanicsLevel': frontAMechanicsLevel,
      'frontBMechanicsLevel': frontBMechanicsLevel,
      'frontATeamBusAvailable': frontATeamBusAvailable,
      'frontBTeamBusAvailable': frontBTeamBusAvailable,
    };
  }

  factory ParallelStaffSplitConfig.fromJson(Map<String, dynamic> json) {
    return ParallelStaffSplitConfig(
      frontADirectorLevel: (json['frontADirectorLevel'] as num).toInt(),
      frontBDirectorLevel: (json['frontBDirectorLevel'] as num).toInt(),
      frontAMechanicsLevel: (json['frontAMechanicsLevel'] as num).toInt(),
      frontBMechanicsLevel: (json['frontBMechanicsLevel'] as num).toInt(),
      frontATeamBusAvailable: json['frontATeamBusAvailable'] as bool,
      frontBTeamBusAvailable: json['frontBTeamBusAvailable'] as bool,
    );
  }
}

/// Pojedynczy komunikat walidacji podziału 28-osobowej kadry.
class ParallelDayValidationIssue {
  final ParallelValidationSeverity severity;
  final ParallelFrontSlot? front;
  final String code;
  final String message;

  const ParallelDayValidationIssue({
    required this.severity,
    this.front,
    required this.code,
    required this.message,
  });

  Map<String, dynamic> toJson() {
    return {
      'severity': severity.toJson(),
      'front': front?.toJson(),
      'code': code,
      'message': message,
    };
  }

  factory ParallelDayValidationIssue.fromJson(Map<String, dynamic> json) {
    return ParallelDayValidationIssue(
      severity: ParallelValidationSeverity.fromJson(json['severity'] as String),
      front: json['front'] != null
          ? ParallelFrontSlot.fromJson(json['front'] as String)
          : null,
      code: json['code'] as String,
      message: json['message'] as String,
    );
  }
}

/// Pełny raport poprawności podziału kadry na dwa fronty.
class ParallelDayRosterValidation {
  final bool isValid;
  final List<ParallelDayValidationIssue> issues;
  final int frontACount;
  final int frontBCount;
  final int reserveCount;
  final List<String> duplicateRiderIds;

  const ParallelDayRosterValidation({
    required this.isValid,
    required this.issues,
    required this.frontACount,
    required this.frontBCount,
    required this.reserveCount,
    this.duplicateRiderIds = const [],
  });

  bool get hasWarnings =>
      issues.any((i) => i.severity == ParallelValidationSeverity.warning);

  List<ParallelDayValidationIssue> get errors =>
      issues.where((i) => i.severity == ParallelValidationSeverity.error).toList();

  Map<String, dynamic> toJson() {
    return {
      'isValid': isValid,
      'issues': issues.map((e) => e.toJson()).toList(),
      'frontACount': frontACount,
      'frontBCount': frontBCount,
      'reserveCount': reserveCount,
      'duplicateRiderIds': duplicateRiderIds,
    };
  }

  factory ParallelDayRosterValidation.fromJson(Map<String, dynamic> json) {
    return ParallelDayRosterValidation(
      isValid: json['isValid'] as bool,
      issues: (json['issues'] as List<dynamic>)
          .map((e) =>
              ParallelDayValidationIssue.fromJson(e as Map<String, dynamic>))
          .toList(),
      frontACount: (json['frontACount'] as num).toInt(),
      frontBCount: (json['frontBCount'] as num).toInt(),
      reserveCount: (json['reserveCount'] as num).toInt(),
      duplicateRiderIds: (json['duplicateRiderIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );
  }
}

/// Wynik pojedynczego kolarza na jednym z równoległych frontów.
class ParallelRiderRaceOutcome {
  final String riderId;
  final String riderName;
  final ParallelFrontSlot assignedFront;
  final int rank;
  final int timeGapSeconds;
  final int uciPoints;
  final int prizeMoneyEur;
  final double tsbDelta;
  final bool hadMechanicalOrCrash;
  final String? incidentNote;
  final bool isTeamBest;

  const ParallelRiderRaceOutcome({
    required this.riderId,
    required this.riderName,
    required this.assignedFront,
    required this.rank,
    required this.timeGapSeconds,
    required this.uciPoints,
    required this.prizeMoneyEur,
    required this.tsbDelta,
    this.hadMechanicalOrCrash = false,
    this.incidentNote,
    this.isTeamBest = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'riderName': riderName,
      'assignedFront': assignedFront.toJson(),
      'rank': rank,
      'timeGapSeconds': timeGapSeconds,
      'uciPoints': uciPoints,
      'prizeMoneyEur': prizeMoneyEur,
      'tsbDelta': tsbDelta,
      'hadMechanicalOrCrash': hadMechanicalOrCrash,
      'incidentNote': incidentNote,
      'isTeamBest': isTeamBest,
    };
  }

  factory ParallelRiderRaceOutcome.fromJson(Map<String, dynamic> json) {
    return ParallelRiderRaceOutcome(
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      assignedFront: ParallelFrontSlot.fromJson(json['assignedFront'] as String),
      rank: (json['rank'] as num).toInt(),
      timeGapSeconds: (json['timeGapSeconds'] as num).toInt(),
      uciPoints: (json['uciPoints'] as num).toInt(),
      prizeMoneyEur: (json['prizeMoneyEur'] as num).toInt(),
      tsbDelta: (json['tsbDelta'] as num).toDouble(),
      hadMechanicalOrCrash: json['hadMechanicalOrCrash'] as bool? ?? false,
      incidentNote: json['incidentNote'] as String?,
      isTeamBest: json['isTeamBest'] as bool? ?? false,
    );
  }
}

/// Wynik symulacji jednego z dwóch równoległych wyścigów tego samego dnia.
class ParallelFrontSimulationResult {
  final ParallelRaceEventSpec raceSpec;
  final String teamLeaderId;
  final String teamLeaderName;
  final String winnerName;
  final String winnerTeamName;
  final List<String> podiumTop3Names;
  final List<ParallelRiderRaceOutcome> riderOutcomes;
  final int bestTeamRank;
  final int totalUciPoints;
  final int totalPrizeMoneyEur;
  final int mediaValueEur;
  final String tacticalSummary;
  final double teamStrengthRating;

  const ParallelFrontSimulationResult({
    required this.raceSpec,
    required this.teamLeaderId,
    required this.teamLeaderName,
    required this.winnerName,
    required this.winnerTeamName,
    required this.podiumTop3Names,
    required this.riderOutcomes,
    required this.bestTeamRank,
    required this.totalUciPoints,
    required this.totalPrizeMoneyEur,
    required this.mediaValueEur,
    required this.tacticalSummary,
    required this.teamStrengthRating,
  });

  Map<String, dynamic> toJson() {
    return {
      'raceSpec': raceSpec.toJson(),
      'teamLeaderId': teamLeaderId,
      'teamLeaderName': teamLeaderName,
      'winnerName': winnerName,
      'winnerTeamName': winnerTeamName,
      'podiumTop3Names': podiumTop3Names,
      'riderOutcomes': riderOutcomes.map((e) => e.toJson()).toList(),
      'bestTeamRank': bestTeamRank,
      'totalUciPoints': totalUciPoints,
      'totalPrizeMoneyEur': totalPrizeMoneyEur,
      'mediaValueEur': mediaValueEur,
      'tacticalSummary': tacticalSummary,
      'teamStrengthRating': teamStrengthRating,
    };
  }

  factory ParallelFrontSimulationResult.fromJson(Map<String, dynamic> json) {
    return ParallelFrontSimulationResult(
      raceSpec:
          ParallelRaceEventSpec.fromJson(json['raceSpec'] as Map<String, dynamic>),
      teamLeaderId: json['teamLeaderId'] as String,
      teamLeaderName: json['teamLeaderName'] as String,
      winnerName: json['winnerName'] as String,
      winnerTeamName: json['winnerTeamName'] as String,
      podiumTop3Names: (json['podiumTop3Names'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      riderOutcomes: (json['riderOutcomes'] as List<dynamic>)
          .map((e) =>
              ParallelRiderRaceOutcome.fromJson(e as Map<String, dynamic>))
          .toList(),
      bestTeamRank: (json['bestTeamRank'] as num).toInt(),
      totalUciPoints: (json['totalUciPoints'] as num).toInt(),
      totalPrizeMoneyEur: (json['totalPrizeMoneyEur'] as num).toInt(),
      mediaValueEur: (json['mediaValueEur'] as num).toInt(),
      tacticalSummary: json['tacticalSummary'] as String,
      teamStrengthRating: (json['teamStrengthRating'] as num).toDouble(),
    );
  }
}

/// Zbiorczy raport z dnia kalendarzowego z dwoma równoległymi wyścigami.
class ParallelRaceDayReport {
  final DateTime calendarDate;
  final ParallelFrontSimulationResult frontAResult;
  final ParallelFrontSimulationResult frontBResult;
  final List<String> reserveRiderIds;
  final int combinedUciPoints;
  final int combinedPrizeMoneyEur;
  final int combinedMediaValueEur;
  final double reserveTsbRecoveryDelta;
  final ParallelDayRosterValidation validationSnapshot;

  const ParallelRaceDayReport({
    required this.calendarDate,
    required this.frontAResult,
    required this.frontBResult,
    required this.reserveRiderIds,
    required this.combinedUciPoints,
    required this.combinedPrizeMoneyEur,
    required this.combinedMediaValueEur,
    required this.reserveTsbRecoveryDelta,
    required this.validationSnapshot,
  });

  Map<String, dynamic> toJson() {
    return {
      'calendarDate': calendarDate.toIso8601String(),
      'frontAResult': frontAResult.toJson(),
      'frontBResult': frontBResult.toJson(),
      'reserveRiderIds': reserveRiderIds,
      'combinedUciPoints': combinedUciPoints,
      'combinedPrizeMoneyEur': combinedPrizeMoneyEur,
      'combinedMediaValueEur': combinedMediaValueEur,
      'reserveTsbRecoveryDelta': reserveTsbRecoveryDelta,
      'validationSnapshot': validationSnapshot.toJson(),
    };
  }

  factory ParallelRaceDayReport.fromJson(Map<String, dynamic> json) {
    return ParallelRaceDayReport(
      calendarDate: DateTime.parse(json['calendarDate'] as String),
      frontAResult: ParallelFrontSimulationResult.fromJson(
        json['frontAResult'] as Map<String, dynamic>,
      ),
      frontBResult: ParallelFrontSimulationResult.fromJson(
        json['frontBResult'] as Map<String, dynamic>,
      ),
      reserveRiderIds: (json['reserveRiderIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      combinedUciPoints: (json['combinedUciPoints'] as num).toInt(),
      combinedPrizeMoneyEur: (json['combinedPrizeMoneyEur'] as num).toInt(),
      combinedMediaValueEur: (json['combinedMediaValueEur'] as num).toInt(),
      reserveTsbRecoveryDelta:
          (json['reserveTsbRecoveryDelta'] as num).toDouble(),
      validationSnapshot: ParallelDayRosterValidation.fromJson(
        json['validationSnapshot'] as Map<String, dynamic>,
      ),
    );
  }
}

/// Główny silnik symulacji równoległych wyścigów w tym samym dniu kalendarzowym.
class MultiRaceParallelDaySimulator {
  const MultiRaceParallelDaySimulator._();

  static const List<String> _rivalWinnerNames = [
    'T. Pogačar',
    'J. Vingegaard',
    'M. van der Poel',
    'R. Evenepoel',
    'W. van Aert',
    'J. Philipsen',
    'P. Roglič',
    'M. Pedersen',
    'J. Almeida',
    'B. Girmay',
  ];

  static const List<String> _rivalTeamNames = [
    'UAE Team Emirates',
    'Team Visma | Lease a Bike',
    'Alpecin-Deceuninck',
    'Soudal Quick-Step',
    'Lidl-Trek',
    'Red Bull - BORA - hansgrohe',
    'INEOS Grenadiers',
  ];

  /// Waliduje podział 28-osobowej kadry na Front A, Front B oraz Rezerwę.
  static ParallelDayRosterValidation validateSplit({
    required List<ParallelRosterRiderSnapshot> squad,
    required Map<String, ParallelFrontSlot> assignments,
    required ParallelRaceEventSpec frontA,
    required ParallelRaceEventSpec frontB,
  }) {
    final List<ParallelDayValidationIssue> issues = [];
    final Set<String> seenA = {};
    final Set<String> seenB = {};
    final Set<String> duplicates = {};

    int frontACount = 0;
    int frontBCount = 0;
    int reserveCount = 0;

    final Map<String, ParallelRosterRiderSnapshot> byId = {
      for (final rider in squad) rider.riderId: rider,
    };

    for (final rider in squad) {
      final slot = assignments[rider.riderId] ?? ParallelFrontSlot.reserve;
      switch (slot) {
        case ParallelFrontSlot.frontA:
          if (!seenA.add(rider.riderId)) {
            duplicates.add(rider.riderId);
          }
          frontACount++;
        case ParallelFrontSlot.frontB:
          if (!seenB.add(rider.riderId)) {
            duplicates.add(rider.riderId);
          }
          frontBCount++;
        case ParallelFrontSlot.reserve:
          reserveCount++;
      }

      if (slot != ParallelFrontSlot.reserve) {
        if (!rider.isFitToRace) {
          issues.add(
            ParallelDayValidationIssue(
              severity: ParallelValidationSeverity.error,
              front: slot,
              code: 'RIDER_UNFIT',
              message:
                  '${rider.fullName} ma aktywną kontuzję/chorobę (${rider.injuryLabel ?? 'niedopuszczony'}) i nie może wystartować na ${slot.labelPl}.',
            ),
          );
        } else if (rider.tsb < -25.0) {
          issues.add(
            ParallelDayValidationIssue(
              severity: ParallelValidationSeverity.warning,
              front: slot,
              code: 'RIDER_FATIGUED',
              message:
                  '${rider.fullName} ma niską świeżość (TSB ${rider.tsb.toStringAsFixed(1)}) — wysokie ryzyko przetrenowania.',
            ),
          );
        }
      }
    }

    for (final id in assignments.keys) {
      if (!byId.containsKey(id)) {
        issues.add(
          ParallelDayValidationIssue(
            severity: ParallelValidationSeverity.error,
            code: 'UNKNOWN_RIDER',
            message: 'Nieznany identyfikator kolarza w przydziale: $id.',
          ),
        );
      }
    }

    if (frontACount < frontA.requiredMinRiders ||
        frontACount > frontA.requiredMaxRiders) {
      issues.add(
        ParallelDayValidationIssue(
          severity: ParallelValidationSeverity.error,
          front: ParallelFrontSlot.frontA,
          code: 'FRONT_A_SIZE',
          message:
              'Front A (${frontA.raceName}) wymaga ${frontA.requiredMinRiders}–${frontA.requiredMaxRiders} kolarzy (obecnie: $frontACount).',
        ),
      );
    }

    if (frontBCount < frontB.requiredMinRiders ||
        frontBCount > frontB.requiredMaxRiders) {
      issues.add(
        ParallelDayValidationIssue(
          severity: ParallelValidationSeverity.error,
          front: ParallelFrontSlot.frontB,
          code: 'FRONT_B_SIZE',
          message:
              'Front B (${frontB.raceName}) wymaga ${frontB.requiredMinRiders}–${frontB.requiredMaxRiders} kolarzy (obecnie: $frontBCount).',
        ),
      );
    }

    final int fitCount = squad.where((r) => r.isFitToRace).length;
    final int minCombined = frontA.requiredMinRiders + frontB.requiredMinRiders;
    if (fitCount < minCombined) {
      issues.add(
        ParallelDayValidationIssue(
          severity: ParallelValidationSeverity.warning,
          code: 'SHORT_HANDED_SQUAD',
          message:
              'Liczba zdrowych kolarzy ($fitCount) jest mniejsza niż minimum na oba fronty ($minCombined).',
        ),
      );
    }

    final bool hasErrors =
        issues.any((i) => i.severity == ParallelValidationSeverity.error);

    return ParallelDayRosterValidation(
      isValid: !hasErrors,
      issues: issues,
      frontACount: frontACount,
      frontBCount: frontBCount,
      reserveCount: reserveCount,
      duplicateRiderIds: duplicates.toList(),
    );
  }

  /// Inteligentnie dzieli 28-osobową kadrę na Front A, Front B oraz Rezerwę bez nakładania się zawodników.
  static Map<String, ParallelFrontSlot> autoSplitSquadForTwoFronts({
    required List<ParallelRosterRiderSnapshot> squad,
    required ParallelRaceEventSpec frontA,
    required ParallelRaceEventSpec frontB,
    ParallelSplitStrategy strategy = ParallelSplitStrategy.prioritizeFrontA,
  }) {
    final Map<String, ParallelFrontSlot> result = {
      for (final r in squad) r.riderId: ParallelFrontSlot.reserve,
    };

    final List<ParallelRosterRiderSnapshot> fitRiders =
        squad.where((r) => r.isFitToRace).toList();
    if (fitRiders.isEmpty) {
      return result;
    }

    final Set<String> usedIds = {};
    final int targetA = frontA.requiredMaxRiders.clamp(0, fitRiders.length);
    final int targetB = frontB.requiredMaxRiders.clamp(0, fitRiders.length);

    double scoreFor(
      ParallelRosterRiderSnapshot rider,
      ParallelRaceEventSpec spec,
    ) {
      final double base = rider.terrainAffinityScore(spec.terrain);
      if (strategy == ParallelSplitStrategy.freshnessFirst) {
        return base * 0.65 + ((rider.tsb + 35.0) * 1.1);
      }
      return base;
    }

    int countA = 0;
    int countB = 0;

    void pickBestFor(ParallelFrontSlot slot, ParallelRaceEventSpec spec) {
      final candidates =
          fitRiders.where((r) => !usedIds.contains(r.riderId)).toList();
      if (candidates.isEmpty) return;

      candidates.sort((a, b) {
        final double diffA = scoreFor(a, spec);
        final double diffB = scoreFor(b, spec);
        return diffB.compareTo(diffA);
      });

      final chosen = candidates.first;
      usedIds.add(chosen.riderId);
      result[chosen.riderId] = slot;
      if (slot == ParallelFrontSlot.frontA) {
        countA++;
      } else {
        countB++;
      }
    }

    if (strategy == ParallelSplitStrategy.prioritizeFrontA) {
      while (countA < targetA && usedIds.length < fitRiders.length) {
        pickBestFor(ParallelFrontSlot.frontA, frontA);
      }
      while (countB < targetB && usedIds.length < fitRiders.length) {
        pickBestFor(ParallelFrontSlot.frontB, frontB);
      }
    } else if (strategy == ParallelSplitStrategy.prioritizeFrontB) {
      while (countB < targetB && usedIds.length < fitRiders.length) {
        pickBestFor(ParallelFrontSlot.frontB, frontB);
      }
      while (countA < targetA && usedIds.length < fitRiders.length) {
        pickBestFor(ParallelFrontSlot.frontA, frontA);
      }
    } else {
      // balanced lub freshnessFirst: naprzemienne dobieranie liderów i pomocników
      bool pickA = frontA.priorityWeight >= frontB.priorityWeight;
      while ((countA < targetA || countB < targetB) &&
          usedIds.length < fitRiders.length) {
        if (pickA && countA < targetA) {
          pickBestFor(ParallelFrontSlot.frontA, frontA);
        } else if (!pickA && countB < targetB) {
          pickBestFor(ParallelFrontSlot.frontB, frontB);
        } else if (countA < targetA) {
          pickBestFor(ParallelFrontSlot.frontA, frontA);
        } else if (countB < targetB) {
          pickBestFor(ParallelFrontSlot.frontB, frontB);
        }
        pickA = !pickA;
      }
    }

    return result;
  }

  /// Symuluje oba równoległe wyścigi w tym samym dniu kalendarzowym i zwraca zbiorczy raport.
  static ParallelRaceDayReport simulateParallelRaceDay({
    required DateTime calendarDate,
    required List<ParallelRosterRiderSnapshot> squad,
    required Map<String, ParallelFrontSlot> assignments,
    required ParallelRaceEventSpec frontA,
    required ParallelRaceEventSpec frontB,
    required ParallelStaffSplitConfig staffSplit,
    int seed = 2026,
  }) {
    final validation = validateSplit(
      squad: squad,
      assignments: assignments,
      frontA: frontA,
      frontB: frontB,
    );

    if (!validation.isValid) {
      throw StateError(
        'Niepoprawny podział kadry na dwa fronty: ${validation.errors.map((e) => e.message).join(' ')}',
      );
    }

    final List<ParallelRosterRiderSnapshot> frontARiders = squad
        .where(
          (r) =>
              (assignments[r.riderId] ?? ParallelFrontSlot.reserve) ==
              ParallelFrontSlot.frontA,
        )
        .toList();
    final List<ParallelRosterRiderSnapshot> frontBRiders = squad
        .where(
          (r) =>
              (assignments[r.riderId] ?? ParallelFrontSlot.reserve) ==
              ParallelFrontSlot.frontB,
        )
        .toList();
    final List<String> reserveIds = squad
        .where(
          (r) =>
              (assignments[r.riderId] ?? ParallelFrontSlot.reserve) ==
              ParallelFrontSlot.reserve,
        )
        .map((r) => r.riderId)
        .toList();

    final frontAResult = _simulateSingleFront(
      slot: ParallelFrontSlot.frontA,
      spec: frontA,
      riders: frontARiders,
      directorLevel: staffSplit.frontADirectorLevel,
      mechanicsLevel: staffSplit.frontAMechanicsLevel,
      hasTeamBus: staffSplit.frontATeamBusAvailable,
      rng: math.Random(seed ^ frontA.raceId.hashCode ^ calendarDate.day),
    );

    final frontBResult = _simulateSingleFront(
      slot: ParallelFrontSlot.frontB,
      spec: frontB,
      riders: frontBRiders,
      directorLevel: staffSplit.frontBDirectorLevel,
      mechanicsLevel: staffSplit.frontBMechanicsLevel,
      hasTeamBus: staffSplit.frontBTeamBusAvailable,
      rng: math.Random((seed + 997) ^ frontB.raceId.hashCode ^ calendarDate.day),
    );

    return ParallelRaceDayReport(
      calendarDate: calendarDate,
      frontAResult: frontAResult,
      frontBResult: frontBResult,
      reserveRiderIds: reserveIds,
      combinedUciPoints:
          frontAResult.totalUciPoints + frontBResult.totalUciPoints,
      combinedPrizeMoneyEur:
          frontAResult.totalPrizeMoneyEur + frontBResult.totalPrizeMoneyEur,
      combinedMediaValueEur:
          frontAResult.mediaValueEur + frontBResult.mediaValueEur,
      reserveTsbRecoveryDelta: 4.5,
      validationSnapshot: validation,
    );
  }

  static ParallelFrontSimulationResult _simulateSingleFront({
    required ParallelFrontSlot slot,
    required ParallelRaceEventSpec spec,
    required List<ParallelRosterRiderSnapshot> riders,
    required int directorLevel,
    required int mechanicsLevel,
    required bool hasTeamBus,
    required math.Random rng,
  }) {
    final sorted = [...riders]..sort(
        (a, b) => b
            .terrainAffinityScore(spec.terrain)
            .compareTo(a.terrainAffinityScore(spec.terrain)),
      );

    final leader = sorted.first;
    final double leaderAffinity = leader.terrainAffinityScore(spec.terrain);
    final double supportAvg = sorted.length > 1
        ? sorted
                .skip(1)
                .map((r) => r.domestiqueEngineScore.toDouble())
                .reduce((a, b) => a + b) /
            (sorted.length - 1)
        : 60.0;

    final double dsBonus = ((directorLevel - 65) * 0.08).clamp(-2.0, 3.0);
    final double busBonus = hasTeamBus ? 1.2 : -0.6;
    final double teamStrength =
        (leaderAffinity * 0.72 + supportAvg * 0.28 + dsBonus + busBonus)
            .clamp(40.0, 102.0);

    final double defectBaseProb =
        ((100 - mechanicsLevel) * 0.0022).clamp(0.01, 0.14) +
            (spec.terrain == ParallelRaceTerrain.cobbleClassic ? 0.05 : 0.0) +
            (spec.weatherCondition == WeatherCondition.heavyStorm ? 0.04 : 0.0);

    final List<ParallelRiderRaceOutcome> outcomes = [];
    final Set<int> usedRanks = {};

    for (int i = 0; i < sorted.length; i++) {
      final rider = sorted[i];
      final double affinity = rider.terrainAffinityScore(spec.terrain);
      final bool isLeader = i == 0;
      final bool incident = rng.nextDouble() < defectBaseProb;
      final int incidentPenaltyRanks = incident ? 12 + rng.nextInt(28) : 0;

      // Im wyższe dopasowanie i bonus drużynowy, tym lepsza lokata w peletonie 150-osobowym
      final double performanceIndex = affinity +
          (isLeader ? dsBonus + busBonus + 2.5 : (supportAvg - 70) * 0.08) +
          (rng.nextDouble() * 9.0 - 4.5);

      int rawRank = (100.0 - performanceIndex).round() * 2 +
          (isLeader ? 1 : 12 + i * 7) +
          incidentPenaltyRanks;
      rawRank = rawRank.clamp(1, 154);

      while (usedRanks.contains(rawRank)) {
        rawRank++;
      }
      usedRanks.add(rawRank);

      final int timeGapSeconds = rawRank == 1
          ? 0
          : (rawRank <= 12
              ? (rawRank - 1) * (2 + rng.nextInt(4))
              : 35 + (rawRank - 12) * (6 + rng.nextInt(5)));

      final int uciPts = _uciPointsForRank(rawRank, spec.tier);
      final int prizeEur = _prizeMoneyForRank(rawRank, spec.tier);
      final double tsbDelta = -(6.0 +
              (spec.distanceKm / 45.0) +
              (spec.elevationGainM / 950.0) +
              (isLeader ? 2.0 : 1.0))
          .clamp(6.5, 19.5);

      outcomes.add(
        ParallelRiderRaceOutcome(
          riderId: rider.riderId,
          riderName: rider.fullName,
          assignedFront: slot,
          rank: rawRank,
          timeGapSeconds: timeGapSeconds,
          uciPoints: uciPts,
          prizeMoneyEur: prizeEur,
          tsbDelta: double.parse(tsbDelta.toStringAsFixed(1)),
          hadMechanicalOrCrash: incident,
          incidentNote: incident
              ? (spec.terrain == ParallelRaceTerrain.cobbleClassic
                  ? 'Przebita opona na sektorze bruku'
                  : 'Defekt mechaniczny — szybka pomoc wozu')
              : null,
          isTeamBest: false,
        ),
      );
    }

    outcomes.sort((a, b) => a.rank.compareTo(b.rank));
    final int bestRank = outcomes.first.rank;
    final List<ParallelRiderRaceOutcome> finalOutcomes = [
      outcomes.first.rank == bestRank
          ? ParallelRiderRaceOutcome(
              riderId: outcomes.first.riderId,
              riderName: outcomes.first.riderName,
              assignedFront: outcomes.first.assignedFront,
              rank: outcomes.first.rank,
              timeGapSeconds: outcomes.first.timeGapSeconds,
              uciPoints: outcomes.first.uciPoints,
              prizeMoneyEur: outcomes.first.prizeMoneyEur,
              tsbDelta: outcomes.first.tsbDelta,
              hadMechanicalOrCrash: outcomes.first.hadMechanicalOrCrash,
              incidentNote: outcomes.first.incidentNote,
              isTeamBest: true,
            )
          : outcomes.first,
      ...outcomes.skip(1),
    ];

    final int totalUci =
        finalOutcomes.fold(0, (sum, o) => sum + o.uciPoints);
    final int totalPrize =
        finalOutcomes.fold(0, (sum, o) => sum + o.prizeMoneyEur);

    final String rivalWinner =
        _rivalWinnerNames[rng.nextInt(_rivalWinnerNames.length)];
    final String rivalTeam =
        _rivalTeamNames[rng.nextInt(_rivalTeamNames.length)];

    final String winnerName =
        bestRank == 1 ? finalOutcomes.first.riderName : rivalWinner;
    final String winnerTeam =
        bestRank == 1 ? 'Twoja Drużyna' : rivalTeam;

    final List<String> podium = [
      winnerName,
      if (bestRank == 2) finalOutcomes.first.riderName else _rivalWinnerNames[(rng.nextInt(_rivalWinnerNames.length - 1) + 1) % _rivalWinnerNames.length],
      if (bestRank == 3) finalOutcomes.first.riderName else _rivalWinnerNames[(rng.nextInt(_rivalWinnerNames.length - 2) + 2) % _rivalWinnerNames.length],
    ];

    final int mediaValueEur = ((totalUci * 420) +
            (bestRank <= 3 ? 45000 : bestRank <= 10 ? 18000 : 6000) +
            (hasTeamBus ? 4000 : 0))
        .round();

    final String tacticalSummary = bestRank == 1
        ? 'Zwycięstwo na ${spec.raceName}! Lider ${leader.fullName} wykorzystał pracę ${sorted.length - 1} pomocników i taktykę DS ($directorLevel).'
        : bestRank <= 5
            ? 'Świetny finisz na podium/Top 5 (${finalOutcomes.first.riderName} #$bestRank). Zespół kontrolował tempo peletonu.'
            : bestRank <= 15
                ? 'Solidny wynik w Top 15 (${finalOutcomes.first.riderName} #$bestRank) i cenne punkty UCI.'
                : 'Trudny dzień na trasie ${spec.raceName} — najlepszy kolarz ukończył na #$bestRank miejscu.';

    return ParallelFrontSimulationResult(
      raceSpec: spec,
      teamLeaderId: leader.riderId,
      teamLeaderName: leader.fullName,
      winnerName: winnerName,
      winnerTeamName: winnerTeam,
      podiumTop3Names: podium,
      riderOutcomes: finalOutcomes,
      bestTeamRank: bestRank,
      totalUciPoints: totalUci,
      totalPrizeMoneyEur: totalPrize,
      mediaValueEur: mediaValueEur,
      tacticalSummary: tacticalSummary,
      teamStrengthRating: double.parse(teamStrength.toStringAsFixed(1)),
    );
  }

  static int _uciPointsForRank(int rank, ParallelRaceTier tier) {
    final int maxPts = tier.uciWinnerPoints;
    if (rank == 1) return maxPts;
    if (rank == 2) return (maxPts * 0.72).round();
    if (rank == 3) return (maxPts * 0.56).round();
    if (rank <= 5) return (maxPts * 0.40).round();
    if (rank <= 10) return (maxPts * 0.22).round();
    if (rank <= 20) return (maxPts * 0.08).round();
    if (rank <= 30) return (maxPts * 0.03).round();
    return 0;
  }

  static int _prizeMoneyForRank(int rank, ParallelRaceTier tier) {
    final int pool = tier.basePrizePoolEur;
    if (rank == 1) return (pool * 0.40).round();
    if (rank == 2) return (pool * 0.20).round();
    if (rank == 3) return (pool * 0.12).round();
    if (rank <= 5) return (pool * 0.06).round();
    if (rank <= 10) return (pool * 0.03).round();
    if (rank <= 20) return (pool * 0.012).round();
    return 0;
  }

  /// Generuje kompletną, realistyczną 28-osobową kadrę drużyny WorldTour do testów i demonstracji.
  static List<ParallelRosterRiderSnapshot> generateSample28RiderSquad({
    int seed = 42,
  }) {
    final rng = math.Random(seed);
    const List<String> names = [
      'K. Kowalski',
      'M. Kwiatkowski',
      'R. Majka',
      'L. Van Wilder',
      'T. Pidcock',
      'S. Bennett',
      'A. De Lie',
      'F. Ganna',
      'J. Tratnik',
      'D. Gaudu',
      'P. Bilbao',
      'G. Ciccone',
      'N. Politt',
      'Y. Lampaert',
      'C. Laporte',
      'B. Turner',
      'M. Sheffield',
      'T. Arensman',
      'S. Kung',
      'K. Asgreen',
      'M. Valgren',
      'J. Stewart',
      'E. Hayter',
      'L. Plapp',
      'R. Dennis',
      'A. Zingle',
      'W. Barguil',
      'J. Hindley',
    ];
    const List<String> nats = [
      'PL',
      'PL',
      'PL',
      'BE',
      'GB',
      'IE',
      'BE',
      'IT',
      'SI',
      'FR',
      'ES',
      'IT',
      'DE',
      'BE',
      'FR',
      'GB',
      'US',
      'NL',
      'CH',
      'DK',
      'DK',
      'GB',
      'GB',
      'AU',
      'AU',
      'FR',
      'FR',
      'AU',
    ];
    const List<RiderSpecialization> specs = [
      RiderSpecialization.gcClimber,
      RiderSpecialization.puncher,
      RiderSpecialization.pureClimber,
      RiderSpecialization.gcClimber,
      RiderSpecialization.puncher,
      RiderSpecialization.pureSprinter,
      RiderSpecialization.versatileSprinter,
      RiderSpecialization.timeTrialist,
      RiderSpecialization.domestiqueEngine,
      RiderSpecialization.gcClimber,
      RiderSpecialization.pureClimber,
      RiderSpecialization.pureClimber,
      RiderSpecialization.classicCobbles,
      RiderSpecialization.classicCobbles,
      RiderSpecialization.classicCobbles,
      RiderSpecialization.domestiqueEngine,
      RiderSpecialization.timeTrialist,
      RiderSpecialization.gcClimber,
      RiderSpecialization.timeTrialist,
      RiderSpecialization.classicCobbles,
      RiderSpecialization.breakawaySpecialist,
      RiderSpecialization.versatileSprinter,
      RiderSpecialization.puncher,
      RiderSpecialization.timeTrialist,
      RiderSpecialization.domestiqueEngine,
      RiderSpecialization.versatileSprinter,
      RiderSpecialization.breakawaySpecialist,
      RiderSpecialization.gcClimber,
    ];

    return List<ParallelRosterRiderSnapshot>.generate(28, (i) {
      final spec = specs[i];
      final int tierBoost = i < 8 ? 84 : (i < 18 ? 76 : 69);
      final int climb = (spec == RiderSpecialization.gcClimber ||
              spec == RiderSpecialization.pureClimber)
          ? tierBoost + rng.nextInt(10)
          : 55 + rng.nextInt(22);
      final int sprint = (spec == RiderSpecialization.pureSprinter ||
              spec == RiderSpecialization.versatileSprinter)
          ? tierBoost + rng.nextInt(10)
          : 52 + rng.nextInt(20);
      final int cobbles = spec == RiderSpecialization.classicCobbles
          ? tierBoost + rng.nextInt(11)
          : 48 + rng.nextInt(24);
      final int tt = spec == RiderSpecialization.timeTrialist
          ? tierBoost + rng.nextInt(11)
          : 54 + rng.nextInt(22);
      final int engine = (66 + rng.nextInt(24)).clamp(50, 95);
      final int ovr = ((climb + sprint + cobbles + tt + engine) / 5.0)
          .round()
          .clamp(62, 95);

      final bool isInjured = i == 27; // 1 kontuzjowany kolarz w kadrze 28-osobowej
      final double tsb = isInjured
          ? -18.0
          : double.parse((-12.0 + rng.nextDouble() * 30.0).toStringAsFixed(1));

      return ParallelRosterRiderSnapshot(
        riderId: 'rider_${i + 1}',
        fullName: names[i],
        nationalityIso: nats[i],
        specialization: spec,
        overallRating: ovr,
        climbingScore: climb.clamp(45, 97),
        sprintScore: sprint.clamp(45, 97),
        cobblesScore: cobbles.clamp(45, 97),
        timeTrialScore: tt.clamp(45, 97),
        domestiqueEngineScore: engine,
        tsb: tsb,
        fatigueAtl: 65.0 + rng.nextInt(25),
        fitnessCtl: 75.0 + rng.nextInt(20),
        isFitToRace: !isInjured,
        injuryLabel: isInjured ? 'Stłuczenie kolana (4d)' : null,
      );
    });
  }
}

/// Stan symulatora równoległych wyścigów w jednym dniu kalendarzowym.
class ParallelDaySimulatorState {
  final DateTime calendarDate;
  final List<ParallelRosterRiderSnapshot> squad;
  final ParallelRaceEventSpec frontAEvent;
  final ParallelRaceEventSpec frontBEvent;
  final Map<String, ParallelFrontSlot> assignments;
  final ParallelStaffSplitConfig staffSplit;
  final ParallelSplitStrategy strategy;
  final ParallelDayRosterValidation validation;
  final ParallelRaceDayReport? lastReport;
  final bool isSimulating;
  final bool isReadOnly;

  const ParallelDaySimulatorState({
    required this.calendarDate,
    required this.squad,
    required this.frontAEvent,
    required this.frontBEvent,
    required this.assignments,
    required this.staffSplit,
    required this.strategy,
    required this.validation,
    this.lastReport,
    this.isSimulating = false,
    this.isReadOnly = false,
  });

  factory ParallelDaySimulatorState.initialDefault() {
    final squad = MultiRaceParallelDaySimulator.generateSample28RiderSquad();
    const frontA = ParallelRaceEventSpec(
      raceId: 'paris_nice_s4',
      raceName: 'Paris-Nice',
      stageNumber: 4,
      stageName: 'Etap 4: Chalon-sur-Saône → Mont Brouilly',
      terrain: ParallelRaceTerrain.highMountain,
      tier: ParallelRaceTier.worldTourStage,
      distanceKm: 183.0,
      elevationGainM: 3340,
      requiredMinRiders: 7,
      requiredMaxRiders: 7,
      weatherCondition: WeatherCondition.overcast,
      windSpeedKmh: 18.0,
      priorityWeight: 0.65,
    );
    const frontB = ParallelRaceEventSpec(
      raceId: 'tirreno_adriatico_s3',
      raceName: 'Tirreno-Adriatico',
      stageNumber: 3,
      stageName: 'Etap 3: Volterra → Gualdo Tadino',
      terrain: ParallelRaceTerrain.flat,
      tier: ParallelRaceTier.worldTourStage,
      distanceKm: 225.0,
      elevationGainM: 1450,
      requiredMinRiders: 7,
      requiredMaxRiders: 7,
      weatherCondition: WeatherCondition.sunny,
      windSpeedKmh: 11.0,
      priorityWeight: 0.50,
    );
    final assignments = MultiRaceParallelDaySimulator.autoSplitSquadForTwoFronts(
      squad: squad,
      frontA: frontA,
      frontB: frontB,
      strategy: ParallelSplitStrategy.prioritizeFrontA,
    );
    final validation = MultiRaceParallelDaySimulator.validateSplit(
      squad: squad,
      assignments: assignments,
      frontA: frontA,
      frontB: frontB,
    );

    return ParallelDaySimulatorState(
      calendarDate: DateTime(2026, 3, 12),
      squad: squad,
      frontAEvent: frontA,
      frontBEvent: frontB,
      assignments: assignments,
      staffSplit: const ParallelStaffSplitConfig(),
      strategy: ParallelSplitStrategy.prioritizeFrontA,
      validation: validation,
    );
  }

  ParallelDaySimulatorState copyWith({
    DateTime? calendarDate,
    List<ParallelRosterRiderSnapshot>? squad,
    ParallelRaceEventSpec? frontAEvent,
    ParallelRaceEventSpec? frontBEvent,
    Map<String, ParallelFrontSlot>? assignments,
    ParallelStaffSplitConfig? staffSplit,
    ParallelSplitStrategy? strategy,
    ParallelDayRosterValidation? validation,
    ParallelRaceDayReport? lastReport,
    bool clearLastReport = false,
    bool? isSimulating,
    bool? isReadOnly,
  }) {
    return ParallelDaySimulatorState(
      calendarDate: calendarDate ?? this.calendarDate,
      squad: squad ?? this.squad,
      frontAEvent: frontAEvent ?? this.frontAEvent,
      frontBEvent: frontBEvent ?? this.frontBEvent,
      assignments: assignments ?? this.assignments,
      staffSplit: staffSplit ?? this.staffSplit,
      strategy: strategy ?? this.strategy,
      validation: validation ?? this.validation,
      lastReport: clearLastReport ? null : (lastReport ?? this.lastReport),
      isSimulating: isSimulating ?? this.isSimulating,
      isReadOnly: isReadOnly ?? this.isReadOnly,
    );
  }
}

/// Kontroler Riverpod zarządzający podziałem 28-osobowej kadry i symulacją dnia podwójnego.
class MultiRaceParallelDaySimulatorNotifier
    extends StateNotifier<ParallelDaySimulatorState> {
  MultiRaceParallelDaySimulatorNotifier([ParallelDaySimulatorState? initial])
      : super(initial ?? ParallelDaySimulatorState.initialDefault());

  void assignRider(String riderId, ParallelFrontSlot slot) {
    if (state.isReadOnly) return;
    final updated = Map<String, ParallelFrontSlot>.from(state.assignments);
    updated[riderId] = slot;
    final validation = MultiRaceParallelDaySimulator.validateSplit(
      squad: state.squad,
      assignments: updated,
      frontA: state.frontAEvent,
      frontB: state.frontBEvent,
    );
    state = state.copyWith(
      assignments: updated,
      validation: validation,
      clearLastReport: true,
    );
  }

  void autoSplit(ParallelSplitStrategy strategy) {
    if (state.isReadOnly) return;
    final updated = MultiRaceParallelDaySimulator.autoSplitSquadForTwoFronts(
      squad: state.squad,
      frontA: state.frontAEvent,
      frontB: state.frontBEvent,
      strategy: strategy,
    );
    final validation = MultiRaceParallelDaySimulator.validateSplit(
      squad: state.squad,
      assignments: updated,
      frontA: state.frontAEvent,
      frontB: state.frontBEvent,
    );
    state = state.copyWith(
      assignments: updated,
      strategy: strategy,
      validation: validation,
      clearLastReport: true,
    );
  }

  void updateStaffSplit(ParallelStaffSplitConfig config) {
    if (state.isReadOnly) return;
    state = state.copyWith(staffSplit: config, clearLastReport: true);
  }

  void updateEvents({
    ParallelRaceEventSpec? frontA,
    ParallelRaceEventSpec? frontB,
  }) {
    if (state.isReadOnly) return;
    final nextA = frontA ?? state.frontAEvent;
    final nextB = frontB ?? state.frontBEvent;
    final validation = MultiRaceParallelDaySimulator.validateSplit(
      squad: state.squad,
      assignments: state.assignments,
      frontA: nextA,
      frontB: nextB,
    );
    state = state.copyWith(
      frontAEvent: nextA,
      frontBEvent: nextB,
      validation: validation,
      clearLastReport: true,
    );
  }

  void setReadOnly(bool readOnly) {
    state = state.copyWith(isReadOnly: readOnly);
  }

  void clearReport() {
    state = state.copyWith(clearLastReport: true);
  }

  ParallelRaceDayReport? runParallelSimulation({int seed = 2026}) {
    if (state.isReadOnly || !state.validation.isValid) {
      return null;
    }
    state = state.copyWith(isSimulating: true);
    final report = MultiRaceParallelDaySimulator.simulateParallelRaceDay(
      calendarDate: state.calendarDate,
      squad: state.squad,
      assignments: state.assignments,
      frontA: state.frontAEvent,
      frontB: state.frontBEvent,
      staffSplit: state.staffSplit,
      seed: seed,
    );
    state = state.copyWith(lastReport: report, isSimulating: false);
    return report;
  }
}

final multiRaceParallelDaySimulatorProvider = StateNotifierProvider<
    MultiRaceParallelDaySimulatorNotifier, ParallelDaySimulatorState>((ref) {
  return MultiRaceParallelDaySimulatorNotifier();
});

/// Responsywny panel zarządzania i symulacji równoległych wyścigów w tym samym dniu.
class MultiRaceParallelDaySimulatorPanel extends ConsumerStatefulWidget {
  const MultiRaceParallelDaySimulatorPanel({super.key});

  @override
  ConsumerState<MultiRaceParallelDaySimulatorPanel> createState() =>
      _MultiRaceParallelDaySimulatorPanelState();
}

class _MultiRaceParallelDaySimulatorPanelState
    extends ConsumerState<MultiRaceParallelDaySimulatorPanel> {
  ParallelFrontSlot _mobileTab = ParallelFrontSlot.frontA;
  String? _hoveredRiderId;

  @override
  Widget build(BuildContext context) {
    final simState = ref.watch(multiRaceParallelDaySimulatorProvider);
    final notifier =
        ref.read(multiRaceParallelDaySimulatorProvider.notifier);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final bool isMobile = width < 720;
        final bool isDesktop = width >= 1200;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 1.0),
          ),
          padding: EdgeInsets.all(isMobile ? 12 : 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context, simState, notifier, isMobile),
                const SizedBox(height: 16),
                _buildStrategyAndValidationBar(
                  simState,
                  notifier,
                  isMobile,
                ),
                const SizedBox(height: 16),
                if (isDesktop)
                  _buildDesktopThreeColumns(simState, notifier)
                else if (!isMobile)
                  _buildTabletTwoColumns(simState, notifier)
                else
                  _buildMobileTabbedLayout(simState, notifier),
                if (simState.lastReport != null) ...[
                  const SizedBox(height: 16),
                  _buildParallelReportCard(simState.lastReport!, isMobile),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ParallelDaySimulatorState simState,
    MultiRaceParallelDaySimulatorNotifier notifier,
    bool isMobile,
  ) {
    final String dateStr =
        '${simState.calendarDate.year}-${simState.calendarDate.month.toString().padLeft(2, '0')}-${simState.calendarDate.day.toString().padLeft(2, '0')}';
    final bool canSimulate =
        !simState.isReadOnly && simState.validation.isValid && !simState.isSimulating;

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.call_split_rounded,
                    color: AppColors.goldAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Podwójny Dzień Wyścigowy ($dateStr)',
                      style: const TextStyle(
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
              const SizedBox(height: 4),
              Text(
                'Kadra ${simState.squad.length} kolarzy • Front A: ${simState.validation.frontACount}/${simState.frontAEvent.requiredMaxRiders} • Front B: ${simState.validation.frontBCount}/${simState.frontBEvent.requiredMaxRiders} • Rezerwa: ${simState.validation.reserveCount}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          _ActionPillButton(
            label: simState.isSimulating
                ? 'Symulacja...'
                : 'Symuluj Oba Fronty',
            icon: Icons.play_arrow_rounded,
            accentColor: AppColors.goldAccent,
            enabled: canSimulate,
            onPressed: () => notifier.runParallelSimulation(),
          ),
        ],
      ),
    );
  }

  Widget _buildStrategyAndValidationBar(
    ParallelDaySimulatorState simState,
    MultiRaceParallelDaySimulatorNotifier notifier,
    bool isMobile,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Auto-podział kadry:',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              ...ParallelSplitStrategy.values.map((strategy) {
                final bool selected = simState.strategy == strategy;
                return _ActionPillButton(
                  label: strategy.labelPl,
                  icon: selected ? Icons.check_circle_rounded : Icons.tune_rounded,
                  accentColor:
                      selected ? AppColors.primaryAccent : AppColors.accentBlue,
                  isSelected: selected,
                  enabled: !simState.isReadOnly,
                  onPressed: () => notifier.autoSplit(strategy),
                );
              }),
            ],
          ),
          if (simState.validation.issues.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...simState.validation.issues.take(3).map((issue) {
              final Color color =
                  issue.severity == ParallelValidationSeverity.error
                      ? AppColors.crimsonAlert
                      : AppColors.amberWarning;
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(
                      issue.severity == ParallelValidationSeverity.error
                          ? Icons.error_outline_rounded
                          : Icons.warning_amber_rounded,
                      size: 16,
                      color: color,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        issue.message,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildDesktopThreeColumns(
    ParallelDaySimulatorState simState,
    MultiRaceParallelDaySimulatorNotifier notifier,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildFrontColumn(
            slot: ParallelFrontSlot.frontA,
            spec: simState.frontAEvent,
            simState: simState,
            notifier: notifier,
            accent: AppColors.goldAccent,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildReserveColumn(simState, notifier),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildFrontColumn(
            slot: ParallelFrontSlot.frontB,
            spec: simState.frontBEvent,
            simState: simState,
            notifier: notifier,
            accent: AppColors.accentBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildTabletTwoColumns(
    ParallelDaySimulatorState simState,
    MultiRaceParallelDaySimulatorNotifier notifier,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              _buildFrontColumn(
                slot: ParallelFrontSlot.frontA,
                spec: simState.frontAEvent,
                simState: simState,
                notifier: notifier,
                accent: AppColors.goldAccent,
              ),
              const SizedBox(height: 16),
              _buildFrontColumn(
                slot: ParallelFrontSlot.frontB,
                spec: simState.frontBEvent,
                simState: simState,
                notifier: notifier,
                accent: AppColors.accentBlue,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildReserveColumn(simState, notifier),
        ),
      ],
    );
  }

  Widget _buildMobileTabbedLayout(
    ParallelDaySimulatorState simState,
    MultiRaceParallelDaySimulatorNotifier notifier,
  ) {
    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ParallelFrontSlot.values.map((slot) {
            final bool selected = _mobileTab == slot;
            final Color accent = slot == ParallelFrontSlot.frontA
                ? AppColors.goldAccent
                : slot == ParallelFrontSlot.frontB
                    ? AppColors.accentBlue
                    : AppColors.textSecondary;
            return _ActionPillButton(
              label: slot.labelPl,
              accentColor: accent,
              isSelected: selected,
              enabled: true,
              onPressed: () => setState(() => _mobileTab = slot),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          switchInCurve: Curves.easeOutCubic,
          child: _mobileTab == ParallelFrontSlot.frontA
              ? KeyedSubtree(
                  key: const ValueKey('tab_frontA'),
                  child: _buildFrontColumn(
                    slot: ParallelFrontSlot.frontA,
                    spec: simState.frontAEvent,
                    simState: simState,
                    notifier: notifier,
                    accent: AppColors.goldAccent,
                  ),
                )
              : _mobileTab == ParallelFrontSlot.frontB
                  ? KeyedSubtree(
                      key: const ValueKey('tab_frontB'),
                      child: _buildFrontColumn(
                        slot: ParallelFrontSlot.frontB,
                        spec: simState.frontBEvent,
                        simState: simState,
                        notifier: notifier,
                        accent: AppColors.accentBlue,
                      ),
                    )
                  : KeyedSubtree(
                      key: const ValueKey('tab_reserve'),
                      child: _buildReserveColumn(simState, notifier),
                    ),
        ),
      ],
    );
  }

  Widget _buildFrontColumn({
    required ParallelFrontSlot slot,
    required ParallelRaceEventSpec spec,
    required ParallelDaySimulatorState simState,
    required MultiRaceParallelDaySimulatorNotifier notifier,
    required Color accent,
  }) {
    final assigned = simState.squad
        .where(
          (r) =>
              (simState.assignments[r.riderId] ?? ParallelFrontSlot.reserve) ==
              slot,
        )
        .toList();

    final int dsLevel = slot == ParallelFrontSlot.frontA
        ? simState.staffSplit.frontADirectorLevel
        : simState.staffSplit.frontBDirectorLevel;
    final bool hasBus = slot == ParallelFrontSlot.frontA
        ? simState.staffSplit.frontATeamBusAvailable
        : simState.staffSplit.frontBTeamBusAvailable;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.45), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(spec.terrain.icon, color: accent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${slot.labelPl}: ${spec.raceName}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
              Text(
                '${assigned.length}/${spec.requiredMaxRiders}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${spec.stageName} • ${spec.distanceKm.toStringAsFixed(0)} km • ${spec.elevationGainM} m',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'DS: $dsLevel • ${hasBus ? 'Autobus Drużyny' : 'Wóz Zastępczy'}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 10),
          if (assigned.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Brak przypisanych kolarzy na ten front.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            ...assigned.map(
              (rider) => _buildRiderRow(
                rider: rider,
                currentSlot: slot,
                terrain: spec.terrain,
                simState: simState,
                notifier: notifier,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReserveColumn(
    ParallelDaySimulatorState simState,
    MultiRaceParallelDaySimulatorNotifier notifier,
  ) {
    final reserve = simState.squad
        .where(
          (r) =>
              (simState.assignments[r.riderId] ?? ParallelFrontSlot.reserve) ==
              ParallelFrontSlot.reserve,
        )
        .toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.hotel_rounded,
                color: AppColors.statusSuccess,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Rezerwa / Regeneracja (+4.5 TSB)',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${reserve.length}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.statusSuccess,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (reserve.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Wszyscy kolarze zostali wysłani na fronty.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            ...reserve.map(
              (rider) => _buildRiderRow(
                rider: rider,
                currentSlot: ParallelFrontSlot.reserve,
                terrain: simState.frontAEvent.terrain,
                simState: simState,
                notifier: notifier,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRiderRow({
    required ParallelRosterRiderSnapshot rider,
    required ParallelFrontSlot currentSlot,
    required ParallelRaceTerrain terrain,
    required ParallelDaySimulatorState simState,
    required MultiRaceParallelDaySimulatorNotifier notifier,
  }) {
    final bool hovered = _hoveredRiderId == rider.riderId;
    final double affinity = rider.terrainAffinityScore(terrain);

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredRiderId = rider.riderId),
      onExit: (_) => setState(() {
        if (_hoveredRiderId == rider.riderId) _hoveredRiderId = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: hovered ? AppColors.surfaceLight : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: !rider.isFitToRace
                ? AppColors.crimsonAlert.withValues(alpha: 0.5)
                : hovered
                    ? AppColors.goldAccent.withValues(alpha: 0.5)
                    : AppColors.cardBorder,
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${rider.fullName} (${rider.nationalityIso})',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: rider.isFitToRace
                          ? AppColors.textPrimary
                          : AppColors.crimsonAlert,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    rider.isFitToRace
                        ? 'OVR ${rider.overallRating} • Dop. ${affinity.round()} • TSB ${rider.tsb >= 0 ? '+' : ''}${rider.tsb.toStringAsFixed(0)}'
                        : (rider.injuryLabel ?? 'Kontuzja'),
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
            const SizedBox(width: 6),
            _MiniSlotButton(
              label: 'A',
              selected: currentSlot == ParallelFrontSlot.frontA,
              enabled: !simState.isReadOnly && rider.isFitToRace,
              accent: AppColors.goldAccent,
              onTap: () =>
                  notifier.assignRider(rider.riderId, ParallelFrontSlot.frontA),
            ),
            const SizedBox(width: 4),
            _MiniSlotButton(
              label: 'B',
              selected: currentSlot == ParallelFrontSlot.frontB,
              enabled: !simState.isReadOnly && rider.isFitToRace,
              accent: AppColors.accentBlue,
              onTap: () =>
                  notifier.assignRider(rider.riderId, ParallelFrontSlot.frontB),
            ),
            const SizedBox(width: 4),
            _MiniSlotButton(
              label: 'R',
              selected: currentSlot == ParallelFrontSlot.reserve,
              enabled: !simState.isReadOnly,
              accent: AppColors.statusSuccess,
              onTap: () => notifier.assignRider(
                rider.riderId,
                ParallelFrontSlot.reserve,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParallelReportCard(
    ParallelRaceDayReport report,
    bool isMobile,
  ) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.goldAccent.withValues(alpha: 0.6),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            children: [
              const Text(
                'Raport Dnia Podwójnego',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.goldAccent,
                ),
              ),
              Text(
                'Łącznie: ${report.combinedUciPoints} pkt UCI • €${report.combinedPrizeMoneyEur} nagród • €${report.combinedMediaValueEur} ekspozycji TV',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.statusSuccess,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSingleFrontSummaryTile(
            'Front A',
            report.frontAResult,
            AppColors.goldAccent,
          ),
          const SizedBox(height: 8),
          _buildSingleFrontSummaryTile(
            'Front B',
            report.frontBResult,
            AppColors.accentBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildSingleFrontSummaryTile(
    String tag,
    ParallelFrontSimulationResult res,
    Color accent,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$tag • ${res.raceSpec.raceName} (Najlepszy: #${res.bestTeamRank})',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
              Text(
                '+${res.totalUciPoints} UCI • €${res.totalPrizeMoneyEur}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            res.tacticalSummary,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionPillButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final Color accentColor;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onPressed;

  const _ActionPillButton({
    required this.label,
    this.icon,
    required this.accentColor,
    this.isSelected = false,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_ActionPillButton> createState() => _ActionPillButtonState();
}

class _ActionPillButtonState extends State<_ActionPillButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final Color bg = !widget.enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : widget.isSelected
            ? widget.accentColor.withValues(alpha: 0.24)
            : _hovered
                ? AppColors.surfaceLight
                : AppColors.background;

    final Color border = !widget.enabled
        ? AppColors.cardBorder.withValues(alpha: 0.4)
        : (_focused || widget.isSelected)
            ? widget.accentColor
            : _hovered
                ? widget.accentColor.withValues(alpha: 0.7)
                : AppColors.cardBorder;

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: InkWell(
        onTap: widget.enabled ? widget.onPressed : null,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: _focused ? 1.5 : 1.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 16,
                  color: widget.enabled
                      ? widget.accentColor
                      : AppColors.textSecondary.withValues(alpha: 0.4),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: widget.enabled
                      ? AppColors.textPrimary
                      : AppColors.textSecondary.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniSlotButton extends StatefulWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final Color accent;
  final VoidCallback onTap;

  const _MiniSlotButton({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.accent,
    required this.onTap,
  });

  @override
  State<_MiniSlotButton> createState() => _MiniSlotButtonState();
}

class _MiniSlotButtonState extends State<_MiniSlotButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: InkWell(
        onTap: widget.enabled ? widget.onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: !widget.enabled
                ? AppColors.surface.withValues(alpha: 0.3)
                : widget.selected
                    ? widget.accent.withValues(alpha: 0.28)
                    : _hovered
                        ? AppColors.surfaceLight
                        : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: !widget.enabled
                  ? AppColors.cardBorder.withValues(alpha: 0.3)
                  : (widget.selected || _focused)
                      ? widget.accent
                      : AppColors.cardBorder,
              width: 1.0,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: !widget.enabled
                  ? AppColors.textSecondary.withValues(alpha: 0.35)
                  : widget.selected
                      ? widget.accent
                      : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
