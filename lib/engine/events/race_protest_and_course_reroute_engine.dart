import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/race/race_stage.dart';
import '../../models/race/stage_segment.dart';

/// Typ ekstremalnego zagrożenia pogodowego lub drogowego w protokole UCI (Art. 2.2.029bis).
enum ExtremeWeatherHazardType {
  none,
  blizzardAndSnow,
  landslideAndRockfall,
  freezingRainAndHypothermia,
  extremeHeatwave,
  galeForceCrosswinds,
  hailstormAndFlashFlood;

  String toJson() => name;

  static ExtremeWeatherHazardType fromJson(String value) {
    return ExtremeWeatherHazardType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ExtremeWeatherHazardType.none,
    );
  }

  String get labelPl {
    switch (this) {
      case ExtremeWeatherHazardType.none:
        return 'Warunki stabilne';
      case ExtremeWeatherHazardType.blizzardAndSnow:
        return 'Śnieżyca i oblodzenie przełęczy';
      case ExtremeWeatherHazardType.landslideAndRockfall:
        return 'Osuwisko i blokada trasy';
      case ExtremeWeatherHazardType.freezingRainAndHypothermia:
        return 'Marznący deszcz i ryzyko hipotermii';
      case ExtremeWeatherHazardType.extremeHeatwave:
        return 'Ekstremalny upał (> 40°C)';
      case ExtremeWeatherHazardType.galeForceCrosswinds:
        return 'Huraganowy wiatr boczny';
      case ExtremeWeatherHazardType.hailstormAndFlashFlood:
        return 'Gradobicie i podtopienia';
    }
  }

  IconData get icon {
    switch (this) {
      case ExtremeWeatherHazardType.none:
        return Icons.wb_sunny_rounded;
      case ExtremeWeatherHazardType.blizzardAndSnow:
        return Icons.ac_unit_rounded;
      case ExtremeWeatherHazardType.landslideAndRockfall:
        return Icons.landslide_rounded;
      case ExtremeWeatherHazardType.freezingRainAndHypothermia:
        return Icons.severe_cold_rounded;
      case ExtremeWeatherHazardType.extremeHeatwave:
        return Icons.thermostat_rounded;
      case ExtremeWeatherHazardType.galeForceCrosswinds:
        return Icons.air_rounded;
      case ExtremeWeatherHazardType.hailstormAndFlashFlood:
        return Icons.thunderstorm_rounded;
    }
  }
}

/// Poziom alarmu Protokołu Ekstremalnej Pogody UCI.
enum UciProtocolTriggerLevel {
  green,
  amber,
  red,
  black;

  String toJson() => name;

  static UciProtocolTriggerLevel fromJson(String value) {
    return UciProtocolTriggerLevel.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => UciProtocolTriggerLevel.green,
    );
  }

  String get labelPl {
    switch (this) {
      case UciProtocolTriggerLevel.green:
        return 'ZIELONY — Brak zagrożenia';
      case UciProtocolTriggerLevel.amber:
        return 'BURSZTYNOWY — Narada komisarzy i CPA';
      case UciProtocolTriggerLevel.red:
        return 'CZERWONY — Wymagana zmiana trasy UCI';
      case UciProtocolTriggerLevel.black:
        return 'CZARNY — Zatrzymanie / Odwołanie etapu';
    }
  }

  Color get badgeColor {
    switch (this) {
      case UciProtocolTriggerLevel.green:
        return AppColors.statusSuccess;
      case UciProtocolTriggerLevel.amber:
        return AppColors.amberWarning;
      case UciProtocolTriggerLevel.red:
        return AppColors.crimsonAlert;
      case UciProtocolTriggerLevel.black:
        return AppColors.primaryAccent;
    }
  }
}

/// Decyzja organizatora i kolegium sędziów UCI w sprawie modyfikacji trasy etapu.
enum CourseRerouteAction {
  none,
  neutralizeDescent,
  bypassHighPass,
  relocateFinishLower,
  delayStartAndShorten,
  cancelStage;

  String toJson() => name;

  static CourseRerouteAction fromJson(String value) {
    return CourseRerouteAction.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CourseRerouteAction.none,
    );
  }

  String get labelPl {
    switch (this) {
      case CourseRerouteAction.none:
        return 'Utrzymaj pierwotną trasę';
      case CourseRerouteAction.neutralizeDescent:
        return 'Neutralizuj niebezpieczny zjazd';
      case CourseRerouteAction.bypassHighPass:
        return 'Objazd wysokiej przełęczy doliną';
      case CourseRerouteAction.relocateFinishLower:
        return 'Przenieś metę niżej (skróć etap)';
      case CourseRerouteAction.delayStartAndShorten:
        return 'Opóźnij start i skróć dystans';
      case CourseRerouteAction.cancelStage:
        return 'Odwołaj etap (Art. 2.2.029bis)';
    }
  }

  String get descriptionPl {
    switch (this) {
      case CourseRerouteAction.none:
        return 'Etap przebiega bez modyfikacji trasy ani neutralizacji.';
      case CourseRerouteAction.neutralizeDescent:
        return 'Przejazd w kolumnie za wozem dyrektora na stromych zjazdach; czasy GC zamrożone.';
      case CourseRerouteAction.bypassHighPass:
        return 'Ominięcie zasypanej lub zablokowanej przełęczy tunelem/doliną z anulowaniem premii KOM.';
      case CourseRerouteAction.relocateFinishLower:
        return 'Wyznaczenie nowej linii mety na bezpiecznej wysokości przed szczytem lub osuwiskiem.';
      case CourseRerouteAction.delayStartAndShorten:
        return 'Przesunięcie startu o 90 min i redukcja początkowych kilometrów etapu.';
      case CourseRerouteAction.cancelStage:
        return 'Natychmiastowe przerwanie rywalizacji ze względu na bezpośrednie zagrożenie życia.';
    }
  }
}

/// Stanowisko kolarzy / związku CPA w głosowaniu protestacyjnym.
enum RiderProtestStance {
  continueRacing,
  cautionRequested,
  protestShorten,
  refuseToStartOrContinue;

  String toJson() => name;

  static RiderProtestStance fromJson(String value) {
    return RiderProtestStance.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RiderProtestStance.continueRacing,
    );
  }

  String get labelPl {
    switch (this) {
      case RiderProtestStance.continueRacing:
        return 'Jedziemy dalej';
      case RiderProtestStance.cautionRequested:
        return 'Żądamy neutralizacji zjazdów';
      case RiderProtestStance.protestShorten:
        return 'Protest CPA — skrócić etap';
      case RiderProtestStance.refuseToStartOrContinue:
        return 'Odmowa jazdy (Art. 2.2.029bis)';
    }
  }
}

/// Dane telemetryczne pogody i trasy wejściowe dla silnika protokołu UCI.
class ExtremeWeatherTelemetryInput {
  final RaceStage stage;
  final double currentRaceKm;
  final double airTemperatureCelsius;
  final double summitTemperatureCelsius;
  final double windGustKmh;
  final double precipitationMmPerHour;
  final double visibilityMeters;
  final bool hasLandslideReport;
  final double? landslideKm;
  final bool iceOnRoadSurface;
  final double pelotonColdStressIndex;
  final double cpaRepresentativeSupport;

  const ExtremeWeatherTelemetryInput({
    required this.stage,
    required this.currentRaceKm,
    required this.airTemperatureCelsius,
    required this.summitTemperatureCelsius,
    required this.windGustKmh,
    required this.precipitationMmPerHour,
    required this.visibilityMeters,
    this.hasLandslideReport = false,
    this.landslideKm,
    this.iceOnRoadSurface = false,
    this.pelotonColdStressIndex = 0.0,
    this.cpaRepresentativeSupport = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'stage': stage.toJson(),
        'currentRaceKm': currentRaceKm,
        'airTemperatureCelsius': airTemperatureCelsius,
        'summitTemperatureCelsius': summitTemperatureCelsius,
        'windGustKmh': windGustKmh,
        'precipitationMmPerHour': precipitationMmPerHour,
        'visibilityMeters': visibilityMeters,
        'hasLandslideReport': hasLandslideReport,
        'landslideKm': landslideKm,
        'iceOnRoadSurface': iceOnRoadSurface,
        'pelotonColdStressIndex': pelotonColdStressIndex,
        'cpaRepresentativeSupport': cpaRepresentativeSupport,
      };

  factory ExtremeWeatherTelemetryInput.fromJson(Map<String, dynamic> json) {
    return ExtremeWeatherTelemetryInput(
      stage: RaceStage.fromJson(
        Map<String, dynamic>.from(json['stage'] as Map? ?? const {}),
      ),
      currentRaceKm: (json['currentRaceKm'] as num?)?.toDouble() ?? 0.0,
      airTemperatureCelsius:
          (json['airTemperatureCelsius'] as num?)?.toDouble() ?? 15.0,
      summitTemperatureCelsius:
          (json['summitTemperatureCelsius'] as num?)?.toDouble() ?? 10.0,
      windGustKmh: (json['windGustKmh'] as num?)?.toDouble() ?? 10.0,
      precipitationMmPerHour:
          (json['precipitationMmPerHour'] as num?)?.toDouble() ?? 0.0,
      visibilityMeters:
          (json['visibilityMeters'] as num?)?.toDouble() ?? 5000.0,
      hasLandslideReport: json['hasLandslideReport'] as bool? ?? false,
      landslideKm: (json['landslideKm'] as num?)?.toDouble(),
      iceOnRoadSurface: json['iceOnRoadSurface'] as bool? ?? false,
      pelotonColdStressIndex:
          (json['pelotonColdStressIndex'] as num?)?.toDouble() ?? 0.0,
      cpaRepresentativeSupport:
          (json['cpaRepresentativeSupport'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Wynik ewaluacji Protokołu Ekstremalnej Pogody UCI.
class UciProtocolEvaluationResult {
  final ExtremeWeatherHazardType hazardType;
  final UciProtocolTriggerLevel triggerLevel;
  final double severityScore;
  final List<String> triggeredRules;
  final CourseRerouteAction recommendedAction;
  final double protestPressure;
  final RiderProtestStance pelotonStance;
  final String communiqueHeadline;
  final String communiqueDetails;

  const UciProtocolEvaluationResult({
    required this.hazardType,
    required this.triggerLevel,
    required this.severityScore,
    required this.triggeredRules,
    required this.recommendedAction,
    required this.protestPressure,
    required this.pelotonStance,
    required this.communiqueHeadline,
    required this.communiqueDetails,
  });

  Map<String, dynamic> toJson() => {
        'hazardType': hazardType.toJson(),
        'triggerLevel': triggerLevel.toJson(),
        'severityScore': severityScore,
        'triggeredRules': triggeredRules,
        'recommendedAction': recommendedAction.toJson(),
        'protestPressure': protestPressure,
        'pelotonStance': pelotonStance.toJson(),
        'communiqueHeadline': communiqueHeadline,
        'communiqueDetails': communiqueDetails,
      };

  factory UciProtocolEvaluationResult.fromJson(Map<String, dynamic> json) {
    return UciProtocolEvaluationResult(
      hazardType: ExtremeWeatherHazardType.fromJson(
        json['hazardType'] as String? ?? 'none',
      ),
      triggerLevel: UciProtocolTriggerLevel.fromJson(
        json['triggerLevel'] as String? ?? 'green',
      ),
      severityScore: (json['severityScore'] as num?)?.toDouble() ?? 0.0,
      triggeredRules: (json['triggeredRules'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      recommendedAction: CourseRerouteAction.fromJson(
        json['recommendedAction'] as String? ?? 'none',
      ),
      protestPressure: (json['protestPressure'] as num?)?.toDouble() ?? 0.0,
      pelotonStance: RiderProtestStance.fromJson(
        json['pelotonStance'] as String? ?? 'continueRacing',
      ),
      communiqueHeadline: json['communiqueHeadline'] as String? ?? '',
      communiqueDetails: json['communiqueDetails'] as String? ?? '',
    );
  }
}

/// Wynik dynamicznej zmiany trasy etapu.
class ReroutedStageResult {
  final RaceStage originalStage;
  final RaceStage reroutedStage;
  final CourseRerouteAction appliedAction;
  final List<int> removedSegmentIndices;
  final int bypassSegmentsAdded;
  final double originalDistanceKm;
  final double newDistanceKm;
  final double distanceDeltaKm;
  final double originalMaxElevationM;
  final double newMaxElevationM;
  final List<String> cancelledKomPrimes;
  final List<int> neutralizedSegmentIndices;
  final bool isStageCancelled;
  final String gcTimePolicyNote;

  const ReroutedStageResult({
    required this.originalStage,
    required this.reroutedStage,
    required this.appliedAction,
    required this.removedSegmentIndices,
    required this.bypassSegmentsAdded,
    required this.originalDistanceKm,
    required this.newDistanceKm,
    required this.distanceDeltaKm,
    required this.originalMaxElevationM,
    required this.newMaxElevationM,
    required this.cancelledKomPrimes,
    required this.neutralizedSegmentIndices,
    required this.isStageCancelled,
    required this.gcTimePolicyNote,
  });
}

/// Pojedynczy głos drużyny lub reprezentanta CPA w sprawie protestu na etapie.
class RaceProtestVoteRecord {
  final String teamOrRiderId;
  final String displayName;
  final RiderProtestStance stance;
  final double weight;
  final String reason;

  const RaceProtestVoteRecord({
    required this.teamOrRiderId,
    required this.displayName,
    required this.stance,
    this.weight = 1.0,
    this.reason = '',
  });

  Map<String, dynamic> toJson() => {
        'teamOrRiderId': teamOrRiderId,
        'displayName': displayName,
        'stance': stance.toJson(),
        'weight': weight,
        'reason': reason,
      };

  factory RaceProtestVoteRecord.fromJson(Map<String, dynamic> json) {
    return RaceProtestVoteRecord(
      teamOrRiderId: json['teamOrRiderId'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      stance: RiderProtestStance.fromJson(
        json['stance'] as String? ?? 'continueRacing',
      ),
      weight: (json['weight'] as num?)?.toDouble() ?? 1.0,
      reason: json['reason'] as String? ?? '',
    );
  }
}

/// Zagregowany wynik głosowania protestacyjnego peletonu.
class PelotonProtestConsensus {
  final RiderProtestStance consensusStance;
  final double protestPressure;
  final double totalWeight;
  final Map<RiderProtestStance, double> stanceShare;

  const PelotonProtestConsensus({
    required this.consensusStance,
    required this.protestPressure,
    required this.totalWeight,
    required this.stanceShare,
  });
}

/// Silnik Protokołu Ekstremalnej Pogody UCI (Art. 2.2.029bis), protestów kolarzy
/// oraz dynamicznej zmiany trasy etapu.
class RaceProtestAndCourseRerouteEngine {
  const RaceProtestAndCourseRerouteEngine();

  /// Ocenia bieżące warunki pogodowe i zagrożenia na trasie etapu zgodnie z wytycznymi UCI.
  UciProtocolEvaluationResult evaluateExtremeWeather(
    ExtremeWeatherTelemetryInput input,
  ) {
    final rules = <String>[];
    var score = 0.0;
    var hazard = ExtremeWeatherHazardType.none;

    final maxStageAlt = input.stage.maxElevationM;
    final hasLandslideAhead = input.hasLandslideReport &&
        (input.landslideKm == null ||
            input.landslideKm! >= input.currentRaceKm);

    if (hasLandslideAhead) {
      hazard = ExtremeWeatherHazardType.landslideAndRockfall;
      score += 68.0;
      final kmText = input.landslideKm != null
          ? 'na km ${input.landslideKm!.toStringAsFixed(1)}'
          : 'na dalszej części trasy';
      rules.add('Osuwisko / blokada drogi $kmText');
    }

    if (input.summitTemperatureCelsius <= 0.5 &&
        (input.precipitationMmPerHour >= 2.0 || input.iceOnRoadSurface)) {
      if (hazard == ExtremeWeatherHazardType.none) {
        hazard = ExtremeWeatherHazardType.blizzardAndSnow;
      }
      score += 52.0;
      if (input.iceOnRoadSurface) score += 20.0;
      rules.add(
        'Temperatura na przełęczy (${input.summitTemperatureCelsius.toStringAsFixed(1)}°C) z opadami/oblodzeniem',
      );
    } else if (input.airTemperatureCelsius <= 4.0 &&
        input.precipitationMmPerHour >= 4.0) {
      if (hazard == ExtremeWeatherHazardType.none) {
        hazard = ExtremeWeatherHazardType.freezingRainAndHypothermia;
      }
      score += 44.0;
      rules.add(
        'Marznący deszcz (${input.airTemperatureCelsius.toStringAsFixed(1)}°C, ${input.precipitationMmPerHour.toStringAsFixed(1)} mm/h)',
      );
    }

    if (input.airTemperatureCelsius >= 39.5) {
      if (hazard == ExtremeWeatherHazardType.none) {
        hazard = ExtremeWeatherHazardType.extremeHeatwave;
      }
      final heatPenalty = (input.airTemperatureCelsius - 38.0) * 11.0;
      score += heatPenalty.clamp(15.0, 65.0);
      rules.add(
        'Ekstremalny upał ${input.airTemperatureCelsius.toStringAsFixed(1)}°C (ryzyko topnienia asfaltu i udaru)',
      );
    }

    if (input.windGustKmh >= 60.0) {
      if (hazard == ExtremeWeatherHazardType.none) {
        hazard = ExtremeWeatherHazardType.galeForceCrosswinds;
      }
      final windScore = ((input.windGustKmh - 55.0) * 1.4).clamp(12.0, 65.0);
      score += windScore;
      rules.add(
        'Porywy wiatru ${input.windGustKmh.toStringAsFixed(0)} km/h na odsłoniętych odcinkach',
      );
    }

    if (input.precipitationMmPerHour >= 15.0 &&
        input.airTemperatureCelsius > 4.0) {
      if (hazard == ExtremeWeatherHazardType.none) {
        hazard = ExtremeWeatherHazardType.hailstormAndFlashFlood;
      }
      score += 36.0;
      rules.add(
        'Nawałnica / gradobicie (${input.precipitationMmPerHour.toStringAsFixed(1)} mm/h)',
      );
    }

    if (input.visibilityMeters < 100.0) {
      score += 18.0;
      rules.add(
        'Widoczność ograniczona do ${input.visibilityMeters.toStringAsFixed(0)} m',
      );
    }

    final coldStressContribution =
        (input.pelotonColdStressIndex / 100.0).clamp(0.0, 1.0) * 16.0;
    final cpaContribution =
        input.cpaRepresentativeSupport.clamp(0.0, 1.0) * 14.0;
    score = (score + coldStressContribution + cpaContribution).clamp(0.0, 100.0);

    final UciProtocolTriggerLevel level;
    if (score >= 82.0) {
      level = UciProtocolTriggerLevel.black;
    } else if (score >= 52.0) {
      level = UciProtocolTriggerLevel.red;
    } else if (score >= 28.0) {
      level = UciProtocolTriggerLevel.amber;
    } else {
      level = UciProtocolTriggerLevel.green;
    }

    final CourseRerouteAction action = _recommendAction(
      input: input,
      hazard: hazard,
      level: level,
      maxStageAlt: maxStageAlt,
    );

    final protestPressure = (score / 100.0 * 0.75 +
            input.cpaRepresentativeSupport.clamp(0.0, 1.0) * 0.25)
        .clamp(0.0, 1.0);

    final RiderProtestStance stance;
    if (protestPressure >= 0.80) {
      stance = RiderProtestStance.refuseToStartOrContinue;
    } else if (protestPressure >= 0.55) {
      stance = RiderProtestStance.protestShorten;
    } else if (protestPressure >= 0.30) {
      stance = RiderProtestStance.cautionRequested;
    } else {
      stance = RiderProtestStance.continueRacing;
    }

    final headline = _buildHeadline(level, hazard, action);
    final details = _buildDetails(input, rules, action, level);

    return UciProtocolEvaluationResult(
      hazardType: hazard,
      triggerLevel: level,
      severityScore: score,
      triggeredRules: List<String>.unmodifiable(rules),
      recommendedAction: action,
      protestPressure: protestPressure,
      pelotonStance: stance,
      communiqueHeadline: headline,
      communiqueDetails: details,
    );
  }

  /// Agreguje ważone głosy drużyn i reprezentantów CPA w sprawie protestu na etapie.
  PelotonProtestConsensus aggregatePelotonProtestVotes(
    List<RaceProtestVoteRecord> votes,
  ) {
    if (votes.isEmpty) {
      return const PelotonProtestConsensus(
        consensusStance: RiderProtestStance.continueRacing,
        protestPressure: 0.0,
        totalWeight: 0.0,
        stanceShare: {
          RiderProtestStance.continueRacing: 1.0,
          RiderProtestStance.cautionRequested: 0.0,
          RiderProtestStance.protestShorten: 0.0,
          RiderProtestStance.refuseToStartOrContinue: 0.0,
        },
      );
    }

    final totals = <RiderProtestStance, double>{
      for (final s in RiderProtestStance.values) s: 0.0,
    };
    var totalWeight = 0.0;
    var weightedPressure = 0.0;

    for (final vote in votes) {
      final w = math.max(0.0, vote.weight);
      if (w <= 0.0) continue;
      totals[vote.stance] = (totals[vote.stance] ?? 0.0) + w;
      totalWeight += w;
      switch (vote.stance) {
        case RiderProtestStance.continueRacing:
          weightedPressure += 0.0 * w;
          break;
        case RiderProtestStance.cautionRequested:
          weightedPressure += 0.4 * w;
          break;
        case RiderProtestStance.protestShorten:
          weightedPressure += 0.78 * w;
          break;
        case RiderProtestStance.refuseToStartOrContinue:
          weightedPressure += 1.0 * w;
          break;
      }
    }

    if (totalWeight <= 0.0) {
      return const PelotonProtestConsensus(
        consensusStance: RiderProtestStance.continueRacing,
        protestPressure: 0.0,
        totalWeight: 0.0,
        stanceShare: {},
      );
    }

    final shares = <RiderProtestStance, double>{
      for (final entry in totals.entries) entry.key: entry.value / totalWeight,
    };

    var topStance = RiderProtestStance.continueRacing;
    var topScore = -1.0;
    for (final entry in totals.entries) {
      if (entry.value > topScore) {
        topScore = entry.value;
        topStance = entry.key;
      }
    }

    return PelotonProtestConsensus(
      consensusStance: topStance,
      protestPressure: (weightedPressure / totalWeight).clamp(0.0, 1.0),
      totalWeight: totalWeight,
      stanceShare: shares,
    );
  }

  /// Dynamicznie modyfikuje segmenty trasy etapu zgodnie z decyzją Protokołu UCI.
  ReroutedStageResult applyDynamicCourseReroute({
    required RaceStage stage,
    required double currentRaceKm,
    required CourseRerouteAction action,
    double? hazardKm,
  }) {
    final origDist = stage.totalDistanceKm;
    final origMaxAlt = stage.maxElevationM;

    if (stage.segments.isEmpty || action == CourseRerouteAction.none) {
      return ReroutedStageResult(
        originalStage: stage,
        reroutedStage: stage,
        appliedAction: CourseRerouteAction.none,
        removedSegmentIndices: const [],
        bypassSegmentsAdded: 0,
        originalDistanceKm: origDist,
        newDistanceKm: origDist,
        distanceDeltaKm: 0.0,
        originalMaxElevationM: origMaxAlt,
        newMaxElevationM: origMaxAlt,
        cancelledKomPrimes: const [],
        neutralizedSegmentIndices: const [],
        isStageCancelled: false,
        gcTimePolicyNote: 'Brak zmian regulaminowych — standardowy pomiar czasu.',
      );
    }

    if (action == CourseRerouteAction.cancelStage) {
      return ReroutedStageResult(
        originalStage: stage,
        reroutedStage: stage.copyWith(
          name: '${stage.name} [ODWOŁANY]',
          segments: const [],
        ),
        appliedAction: action,
        removedSegmentIndices: stage.segments.map((s) => s.index).toList(),
        bypassSegmentsAdded: 0,
        originalDistanceKm: origDist,
        newDistanceKm: 0.0,
        distanceDeltaKm: -origDist,
        originalMaxElevationM: origMaxAlt,
        newMaxElevationM: 0.0,
        cancelledKomPrimes: _extractKomNames(stage.segments),
        neutralizedSegmentIndices: const [],
        isStageCancelled: true,
        gcTimePolicyNote:
            'Etap odwołany na mocy Art. 2.2.029bis UCI — brak punktów i zmian w GC.',
      );
    }

    if (action == CourseRerouteAction.neutralizeDescent) {
      final neutralizedIndices = <int>[];
      final updatedSegments = stage.segments.map((seg) {
        if (seg.endKm > currentRaceKm && seg.gradientPercent < -3.0) {
          neutralizedIndices.add(seg.index);
          return seg.copyWith(
            technicalDifficulty: math.min(seg.technicalDifficulty, 15.0),
          );
        }
        return seg;
      }).toList();

      final newStage = stage.copyWith(
        name: '${stage.name} [Zjazd zneutralizowany]',
        segments: updatedSegments,
      );

      return ReroutedStageResult(
        originalStage: stage,
        reroutedStage: newStage,
        appliedAction: action,
        removedSegmentIndices: const [],
        bypassSegmentsAdded: 0,
        originalDistanceKm: origDist,
        newDistanceKm: newStage.totalDistanceKm,
        distanceDeltaKm: newStage.totalDistanceKm - origDist,
        originalMaxElevationM: origMaxAlt,
        newMaxElevationM: newStage.maxElevationM,
        cancelledKomPrimes: const [],
        neutralizedSegmentIndices: List<int>.unmodifiable(neutralizedIndices),
        isStageCancelled: false,
        gcTimePolicyNote:
            'Neutralizacja niebezpiecznych zjazdów — zakaz ataków za wozem dyrektora, czasy zamrożone.',
      );
    }

    if (action == CourseRerouteAction.bypassHighPass) {
      return _applyBypassHighPass(
        stage: stage,
        currentRaceKm: currentRaceKm,
        hazardKm: hazardKm,
        origDist: origDist,
        origMaxAlt: origMaxAlt,
      );
    }

    if (action == CourseRerouteAction.relocateFinishLower) {
      return _applyRelocateFinishLower(
        stage: stage,
        currentRaceKm: currentRaceKm,
        hazardKm: hazardKm,
        origDist: origDist,
        origMaxAlt: origMaxAlt,
      );
    }

    // CourseRerouteAction.delayStartAndShorten
    return _applyDelayStartAndShorten(
      stage: stage,
      currentRaceKm: currentRaceKm,
      origDist: origDist,
      origMaxAlt: origMaxAlt,
    );
  }

  ReroutedStageResult _applyBypassHighPass({
    required RaceStage stage,
    required double currentRaceKm,
    required double? hazardKm,
    required double origDist,
    required double origMaxAlt,
  }) {
    final segments = stage.segments;
    // Znajdź najbardziej eksponowany/wysoki blok segmentów przed nami
    int peakIdx = -1;
    double highestAlt = -double.infinity;
    for (int i = 0; i < segments.length; i++) {
      final seg = segments[i];
      if (seg.endKm <= currentRaceKm) continue;
      if (hazardKm != null &&
          hazardKm >= seg.startKm &&
          hazardKm <= seg.endKm) {
        peakIdx = i;
        break;
      }
      final segMax = math.max(seg.startElevationM, seg.endElevationM);
      if (segMax > highestAlt) {
        highestAlt = segMax;
        peakIdx = i;
      }
    }

    if (peakIdx == -1 || segments.length <= 2) {
      return _applyRelocateFinishLower(
        stage: stage,
        currentRaceKm: currentRaceKm,
        hazardKm: hazardKm,
        origDist: origDist,
        origMaxAlt: origMaxAlt,
      );
    }

    // Rozszerz blok objazdu na sąsiedni podjazd i zjazd z tej samej przełęczy
    int startCut = peakIdx;
    while (startCut > 0 &&
        segments[startCut - 1].endKm > currentRaceKm &&
        (segments[startCut - 1].isClimb ||
            segments[startCut - 1].endElevationM > 1400.0)) {
      startCut--;
    }
    int endCut = peakIdx;
    while (endCut < segments.length - 1 &&
        (segments[endCut + 1].isDescent ||
            segments[endCut + 1].startElevationM > 1400.0)) {
      endCut++;
    }

    // Jeśli objazd objąłby cały koniec trasy, przenieś metę niżej
    if (endCut >= segments.length - 1 && startCut > 0) {
      return _applyRelocateFinishLower(
        stage: stage,
        currentRaceKm: currentRaceKm,
        hazardKm: segments[startCut].startKm + 1.0,
        origDist: origDist,
        origMaxAlt: origMaxAlt,
      );
    }

    final removed = <int>[];
    final cancelledKoms = <String>[];
    for (int i = startCut; i <= endCut; i++) {
      removed.add(segments[i].index);
      final kom = segments[i].climbCategory;
      if (kom != null) {
        cancelledKoms.add('KOM Cat $kom (km ${segments[i].endKm.toStringAsFixed(1)})');
      }
    }

    final startElev = segments[startCut].startElevationM;
    final endElev = segments[endCut].endElevationM;
    final originalCutLength = segments
        .sublist(startCut, endCut + 1)
        .fold<double>(0.0, (sum, s) => sum + s.lengthKm);
    final bypassLength = math.max(4.0, originalCutLength * 0.65);

    final bypassSegment = StageSegment(
      index: startCut,
      startKm: segments[startCut].startKm,
      lengthKm: bypassLength,
      startElevationM: startElev,
      endElevationM: endElev,
      surfaceType: SegmentSurfaceType.smoothAsphalt,
      technicalDifficulty: 18.0,
      windDirectionDegrees: segments[startCut].windDirectionDegrees,
      roadBearingDegrees: segments[startCut].roadBearingDegrees,
      sprintOrKomClassification: SegmentClassification.none,
    );

    final rawList = <StageSegment>[
      ...segments.sublist(0, startCut),
      bypassSegment,
      ...segments.sublist(endCut + 1),
    ];

    final reindexed = _reindexSegments(rawList);
    final newStage = stage.copyWith(
      name: '${stage.name} [Objazd przełęczy]',
      segments: reindexed,
    );

    return ReroutedStageResult(
      originalStage: stage,
      reroutedStage: newStage,
      appliedAction: CourseRerouteAction.bypassHighPass,
      removedSegmentIndices: List<int>.unmodifiable(removed),
      bypassSegmentsAdded: 1,
      originalDistanceKm: origDist,
      newDistanceKm: newStage.totalDistanceKm,
      distanceDeltaKm: newStage.totalDistanceKm - origDist,
      originalMaxElevationM: origMaxAlt,
      newMaxElevationM: newStage.maxElevationM,
      cancelledKomPrimes: List<String>.unmodifiable(cancelledKoms),
      neutralizedSegmentIndices: const [],
      isStageCancelled: false,
      gcTimePolicyNote:
          'Objazd przełęczy doliną — premie górskie na wyłączonym odcinku anulowane.',
    );
  }

  ReroutedStageResult _applyRelocateFinishLower({
    required RaceStage stage,
    required double currentRaceKm,
    required double? hazardKm,
    required double origDist,
    required double origMaxAlt,
  }) {
    final segments = stage.segments;
    int keepUntilIdx = segments.length - 1;

    if (hazardKm != null) {
      for (int i = 0; i < segments.length; i++) {
        if (segments[i].endKm >= hazardKm && segments[i].endKm > currentRaceKm) {
          keepUntilIdx = math.max(0, i - 1);
          break;
        }
      }
    } else {
      // Skróć przed najwyższym finałowym podjazdem / ostatnimi ~25% etapu
      final targetCutoffKm = math.max(currentRaceKm + 5.0, origDist * 0.72);
      for (int i = 0; i < segments.length; i++) {
        if (segments[i].endKm >= targetCutoffKm) {
          keepUntilIdx = i;
          break;
        }
      }
    }

    if (keepUntilIdx >= segments.length - 1 && segments.length > 1) {
      keepUntilIdx = segments.length - 2;
    }

    final kept = segments.sublist(0, keepUntilIdx + 1).toList();
    final removed = <int>[];
    final cancelledKoms = <String>[];
    for (int i = keepUntilIdx + 1; i < segments.length; i++) {
      removed.add(segments[i].index);
      final kom = segments[i].climbCategory;
      if (kom != null) {
        cancelledKoms.add('KOM Cat $kom (km ${segments[i].endKm.toStringAsFixed(1)})');
      }
    }

    if (kept.isNotEmpty) {
      kept[kept.length - 1] = kept.last.copyWith(
        sprintOrKomClassification: SegmentClassification.finishLine,
      );
    }

    final reindexed = _reindexSegments(kept);
    final newStage = stage.copyWith(
      name: '${stage.name} [Meta przeniesiona]',
      segments: reindexed,
    );

    return ReroutedStageResult(
      originalStage: stage,
      reroutedStage: newStage,
      appliedAction: CourseRerouteAction.relocateFinishLower,
      removedSegmentIndices: List<int>.unmodifiable(removed),
      bypassSegmentsAdded: 0,
      originalDistanceKm: origDist,
      newDistanceKm: newStage.totalDistanceKm,
      distanceDeltaKm: newStage.totalDistanceKm - origDist,
      originalMaxElevationM: origMaxAlt,
      newMaxElevationM: newStage.maxElevationM,
      cancelledKomPrimes: List<String>.unmodifiable(cancelledKoms),
      neutralizedSegmentIndices: const [],
      isStageCancelled: false,
      gcTimePolicyNote:
          'Meta przeniesiona niżej — pełne czasy GC liczone na nowej linii mety.',
    );
  }

  ReroutedStageResult _applyDelayStartAndShorten({
    required RaceStage stage,
    required double currentRaceKm,
    required double origDist,
    required double origMaxAlt,
  }) {
    final segments = stage.segments;
    if (segments.length <= 2 || currentRaceKm > 15.0) {
      return _applyRelocateFinishLower(
        stage: stage,
        currentRaceKm: currentRaceKm,
        hazardKm: null,
        origDist: origDist,
        origMaxAlt: origMaxAlt,
      );
    }

    final skipCount = math.max(1, (segments.length * 0.25).floor());
    final removed = segments.sublist(0, skipCount).map((s) => s.index).toList();
    final cancelledKoms = _extractKomNames(segments.sublist(0, skipCount));
    final kept = _reindexSegments(segments.sublist(skipCount));

    final newStage = stage.copyWith(
      name: '${stage.name} [Start opóźniony / skrócony]',
      segments: kept,
    );

    return ReroutedStageResult(
      originalStage: stage,
      reroutedStage: newStage,
      appliedAction: CourseRerouteAction.delayStartAndShorten,
      removedSegmentIndices: List<int>.unmodifiable(removed),
      bypassSegmentsAdded: 0,
      originalDistanceKm: origDist,
      newDistanceKm: newStage.totalDistanceKm,
      distanceDeltaKm: newStage.totalDistanceKm - origDist,
      originalMaxElevationM: origMaxAlt,
      newMaxElevationM: newStage.maxElevationM,
      cancelledKomPrimes: List<String>.unmodifiable(cancelledKoms),
      neutralizedSegmentIndices: const [],
      isStageCancelled: false,
      gcTimePolicyNote:
          'Start opóźniony o 90 min, początkowy odcinek wyłączony z rywalizacji.',
    );
  }

  List<StageSegment> _reindexSegments(List<StageSegment> segments) {
    final result = <StageSegment>[];
    var cursorKm = 0.0;
    for (int i = 0; i < segments.length; i++) {
      final seg = segments[i];
      result.add(
        seg.copyWith(
          index: i,
          startKm: cursorKm,
        ),
      );
      cursorKm += seg.lengthKm;
    }
    return result;
  }

  List<String> _extractKomNames(List<StageSegment> segments) {
    final names = <String>[];
    for (final s in segments) {
      final cat = s.climbCategory;
      if (cat != null) {
        names.add('KOM Cat $cat (km ${s.endKm.toStringAsFixed(1)})');
      }
    }
    return names;
  }

  CourseRerouteAction _recommendAction({
    required ExtremeWeatherTelemetryInput input,
    required ExtremeWeatherHazardType hazard,
    required UciProtocolTriggerLevel level,
    required double maxStageAlt,
  }) {
    if (level == UciProtocolTriggerLevel.green) {
      return CourseRerouteAction.none;
    }
    if (level == UciProtocolTriggerLevel.black) {
      if (input.currentRaceKm > input.stage.totalDistanceKm * 0.55 &&
          !input.hasLandslideReport) {
        return CourseRerouteAction.relocateFinishLower;
      }
      return CourseRerouteAction.cancelStage;
    }
    if (hazard == ExtremeWeatherHazardType.landslideAndRockfall) {
      final landslideKm = input.landslideKm ?? input.stage.totalDistanceKm * 0.7;
      if (landslideKm > input.stage.totalDistanceKm * 0.75) {
        return CourseRerouteAction.relocateFinishLower;
      }
      return CourseRerouteAction.bypassHighPass;
    }
    if (hazard == ExtremeWeatherHazardType.blizzardAndSnow) {
      if (maxStageAlt >= 1600.0 && input.stage.isSummitFinish) {
        return CourseRerouteAction.relocateFinishLower;
      }
      if (maxStageAlt >= 1400.0) {
        return CourseRerouteAction.bypassHighPass;
      }
      return CourseRerouteAction.delayStartAndShorten;
    }
    if (hazard == ExtremeWeatherHazardType.freezingRainAndHypothermia ||
        hazard == ExtremeWeatherHazardType.hailstormAndFlashFlood) {
      return level == UciProtocolTriggerLevel.red
          ? CourseRerouteAction.neutralizeDescent
          : CourseRerouteAction.neutralizeDescent;
    }
    if (hazard == ExtremeWeatherHazardType.galeForceCrosswinds ||
        hazard == ExtremeWeatherHazardType.extremeHeatwave) {
      return input.currentRaceKm < 10.0
          ? CourseRerouteAction.delayStartAndShorten
          : CourseRerouteAction.neutralizeDescent;
    }
    return CourseRerouteAction.neutralizeDescent;
  }

  String _buildHeadline(
    UciProtocolTriggerLevel level,
    ExtremeWeatherHazardType hazard,
    CourseRerouteAction action,
  ) {
    switch (level) {
      case UciProtocolTriggerLevel.green:
        return 'Warunki na trasie zgodne z normami bezpieczeństwa UCI';
      case UciProtocolTriggerLevel.amber:
        return 'Alert meteo UCI: ${hazard.labelPl}';
      case UciProtocolTriggerLevel.red:
        return 'PROTOKÓŁ EKSTREMALNEJ POGODY UCI — ${action.labelPl}';
      case UciProtocolTriggerLevel.black:
        return 'ALARM KRYTYCZNY UCI (Art. 2.2.029bis) — ${action.labelPl}';
    }
  }

  String _buildDetails(
    ExtremeWeatherTelemetryInput input,
    List<String> rules,
    CourseRerouteAction action,
    UciProtocolTriggerLevel level,
  ) {
    if (rules.isEmpty || level == UciProtocolTriggerLevel.green) {
      return 'Temperatura na szczycie ${input.summitTemperatureCelsius.toStringAsFixed(1)}°C, '
          'porywy wiatru ${input.windGustKmh.toStringAsFixed(0)} km/h. Brak podstaw do uruchomienia Art. 2.2.029bis.';
    }
    return 'Czynniki aktywujące: ${rules.join('; ')}. '
        'Rekomendacja kolegium komisarzy i CPA: ${action.labelPl}.';
  }
}

/// Stan Riverpod dla modułu Protokołu Ekstremalnej Pogody UCI i zmiany trasy.
class RaceProtestAndRerouteState {
  final ExtremeWeatherTelemetryInput? lastTelemetry;
  final UciProtocolEvaluationResult? evaluation;
  final ReroutedStageResult? rerouteResult;
  final List<RaceProtestVoteRecord> protestVotes;
  final RiderProtestStance? managerVoteStance;
  final bool officialDecisionLocked;
  final List<String> auditLog;

  const RaceProtestAndRerouteState({
    this.lastTelemetry,
    this.evaluation,
    this.rerouteResult,
    this.protestVotes = const [],
    this.managerVoteStance,
    this.officialDecisionLocked = false,
    this.auditLog = const [],
  });

  RaceProtestAndRerouteState copyWith({
    ExtremeWeatherTelemetryInput? lastTelemetry,
    UciProtocolEvaluationResult? evaluation,
    ReroutedStageResult? rerouteResult,
    List<RaceProtestVoteRecord>? protestVotes,
    RiderProtestStance? managerVoteStance,
    bool? officialDecisionLocked,
    List<String>? auditLog,
  }) {
    return RaceProtestAndRerouteState(
      lastTelemetry: lastTelemetry ?? this.lastTelemetry,
      evaluation: evaluation ?? this.evaluation,
      rerouteResult: rerouteResult ?? this.rerouteResult,
      protestVotes: protestVotes ?? this.protestVotes,
      managerVoteStance: managerVoteStance ?? this.managerVoteStance,
      officialDecisionLocked:
          officialDecisionLocked ?? this.officialDecisionLocked,
      auditLog: auditLog ?? this.auditLog,
    );
  }
}

/// Notifier zarządzający oceną pogody, głosami CPA oraz dynamiczną zmianą trasy.
class RaceProtestAndRerouteNotifier
    extends StateNotifier<RaceProtestAndRerouteState> {
  final RaceProtestAndCourseRerouteEngine _engine;

  RaceProtestAndRerouteNotifier({
    RaceProtestAndCourseRerouteEngine? engine,
  })  : _engine = engine ?? const RaceProtestAndCourseRerouteEngine(),
        super(const RaceProtestAndRerouteState());

  void evaluateTelemetry(ExtremeWeatherTelemetryInput input) {
    final result = _engine.evaluateExtremeWeather(input);
    final updatedLog = <String>[
      'Ewaluacja UCI (${result.triggerLevel.name.toUpperCase()}): '
          '${result.hazardType.labelPl} (${result.severityScore.toStringAsFixed(0)} pkt)',
      ...state.auditLog,
    ].take(20).toList();

    state = state.copyWith(
      lastTelemetry: input,
      evaluation: result,
      auditLog: updatedLog,
    );
  }

  void setProtestVotes(List<RaceProtestVoteRecord> votes) {
    state = state.copyWith(protestVotes: List.unmodifiable(votes));
  }

  void submitManagerVote(
    RiderProtestStance stance, {
    String teamName = 'Twoja Drużyna',
    String reason = 'Stanowisko dyrektora sportowego',
  }) {
    final filtered = state.protestVotes
        .where((v) => v.teamOrRiderId != 'player_team')
        .toList();
    filtered.add(
      RaceProtestVoteRecord(
        teamOrRiderId: 'player_team',
        displayName: teamName,
        stance: stance,
        weight: 1.5,
        reason: reason,
      ),
    );
    final updatedLog = <String>[
      'Oddano głos w naradzie CPA: ${stance.labelPl}',
      ...state.auditLog,
    ].take(20).toList();

    state = state.copyWith(
      protestVotes: List.unmodifiable(filtered),
      managerVoteStance: stance,
      auditLog: updatedLog,
    );
  }

  void applyReroute(CourseRerouteAction action, {double? hazardKm}) {
    final telemetry = state.lastTelemetry;
    if (telemetry == null) return;
    final rerouted = _engine.applyDynamicCourseReroute(
      stage: telemetry.stage,
      currentRaceKm: telemetry.currentRaceKm,
      action: action,
      hazardKm: hazardKm ?? telemetry.landslideKm,
    );
    final updatedLog = <String>[
      'Zastosowano decyzję UCI: ${action.labelPl} '
          '(${rerouted.originalDistanceKm.toStringAsFixed(1)} -> '
          '${rerouted.newDistanceKm.toStringAsFixed(1)} km)',
      ...state.auditLog,
    ].take(20).toList();

    state = state.copyWith(
      rerouteResult: rerouted,
      officialDecisionLocked: action != CourseRerouteAction.none,
      auditLog: updatedLog,
    );
  }

  void reset() {
    state = const RaceProtestAndRerouteState();
  }
}

final raceProtestAndRerouteProvider = StateNotifierProvider<
    RaceProtestAndRerouteNotifier, RaceProtestAndRerouteState>(
  (ref) => RaceProtestAndRerouteNotifier(),
);

/// Produkcyjny panel Protokołu Ekstremalnej Pogody UCI i dynamicznej zmiany trasy.
class RaceProtestAndCourseReroutePanel extends ConsumerWidget {
  const RaceProtestAndCourseReroutePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(raceProtestAndRerouteProvider);
    final notifier = ref.read(raceProtestAndRerouteProvider.notifier);
    final evaluation = state.evaluation;
    final reroute = state.rerouteResult;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isCompact = width < 640;
        final isWide = width >= 1100;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isCompact ? 12 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeaderCard(context, evaluation, isCompact),
              const SizedBox(height: 14),
              if (evaluation == null)
                _buildEmptyStateCard(isCompact)
              else if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _buildEvaluationDetailsCard(
                        evaluation,
                        state.protestVotes,
                        isCompact,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 6,
                      child: _buildActionsAndRerouteCard(
                        state: state,
                        evaluation: evaluation,
                        reroute: reroute,
                        notifier: notifier,
                        isCompact: isCompact,
                      ),
                    ),
                  ],
                )
              else ...[
                _buildEvaluationDetailsCard(
                  evaluation,
                  state.protestVotes,
                  isCompact,
                ),
                const SizedBox(height: 14),
                _buildActionsAndRerouteCard(
                  state: state,
                  evaluation: evaluation,
                  reroute: reroute,
                  notifier: notifier,
                  isCompact: isCompact,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderCard(
    BuildContext context,
    UciProtocolEvaluationResult? evaluation,
    bool isCompact,
  ) {
    final level = evaluation?.triggerLevel ?? UciProtocolTriggerLevel.green;
    final hazard = evaluation?.hazardType ?? ExtremeWeatherHazardType.none;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.all(isCompact ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: evaluation != null
              ? level.badgeColor.withValues(alpha: 0.55)
              : AppColors.cardBorder,
          width: 1.0,
        ),
      ),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: level.badgeColor.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: level.badgeColor.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Icon(
                        hazard.icon,
                        color: level.badgeColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Protokół Ekstremalnej Pogody UCI',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            evaluation?.communiqueHeadline ??
                                'Art. 2.2.029bis — Monitoring pogody i trasy',
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
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: level.badgeColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: level.badgeColor.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Text(
                    level.labelPl,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: level.badgeColor,
                    ),
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: level.badgeColor.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: level.badgeColor.withValues(alpha: 0.45),
                          ),
                        ),
                        child: Icon(
                          hazard.icon,
                          color: level.badgeColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Protokół Ekstremalnej Pogody UCI',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              evaluation?.communiqueHeadline ??
                                  'Art. 2.2.029bis — Monitoring pogody i trasy',
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
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: level.badgeColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: level.badgeColor.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Text(
                    level.labelPl,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: level.badgeColor,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyStateCard(bool isCompact) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 16 : 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Brak aktywnej telemetrii zagrożenia',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Silnik oczekuje na odczyt meteorologiczny etapu lub raport sędziowski o blokadzie drogi.',
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

  Widget _buildEvaluationDetailsCard(
    UciProtocolEvaluationResult evaluation,
    List<RaceProtestVoteRecord> votes,
    bool isCompact,
  ) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Ocena Ryzyka i Presja CPA',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${evaluation.severityScore.toStringAsFixed(0)} / 100',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: evaluation.triggerLevel.badgeColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (evaluation.severityScore / 100.0).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                evaluation.triggerLevel.badgeColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            evaluation.communiqueDetails,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          if (evaluation.triggeredRules.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...evaluation.triggeredRules.map(
              (rule) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 15,
                      color: evaluation.triggerLevel.badgeColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        rule,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Nastrój peletonu: ${evaluation.pelotonStance.labelPl}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '${(evaluation.protestPressure * 100).toStringAsFixed(0)}% (${votes.length} głosów)',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.goldAccent,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsAndRerouteCard({
    required RaceProtestAndRerouteState state,
    required UciProtocolEvaluationResult evaluation,
    required ReroutedStageResult? reroute,
    required RaceProtestAndRerouteNotifier notifier,
    required bool isCompact,
  }) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Stanowisko Drużyny i Zmiana Trasy',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: RiderProtestStance.values.map((stance) {
              final selected = state.managerVoteStance == stance;
              return _InteractiveActionChip(
                label: stance.labelPl,
                selected: selected,
                accentColor: AppColors.goldAccent,
                enabled: !state.officialDecisionLocked,
                onTap: () => notifier.submitManagerVote(stance),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text(
            'Decyzja Komisarzy UCI (Dynamiczny Reroute)',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CourseRerouteAction.values.map((action) {
              final isRecommended = evaluation.recommendedAction == action;
              final isApplied = reroute?.appliedAction == action;
              return _InteractiveActionChip(
                label: isRecommended ? '${action.labelPl} (Zalecane)' : action.labelPl,
                selected: isApplied,
                accentColor: action == CourseRerouteAction.cancelStage
                    ? AppColors.crimsonAlert
                    : AppColors.accentBlue,
                enabled: !state.officialDecisionLocked || isApplied,
                onTap: () => notifier.applyReroute(action),
              );
            }).toList(),
          ),
          if (reroute != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: reroute.isStageCancelled
                      ? AppColors.crimsonAlert.withValues(alpha: 0.6)
                      : AppColors.accentBlue.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reroute.reroutedStage.name,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Dystans: ${reroute.originalDistanceKm.toStringAsFixed(1)} km → '
                    '${reroute.newDistanceKm.toStringAsFixed(1)} km '
                    '(${reroute.distanceDeltaKm >= 0 ? '+' : ''}${reroute.distanceDeltaKm.toStringAsFixed(1)} km)',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.accentBlue,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reroute.gcTimePolicyNote,
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
        ],
      ),
    );
  }
}

class _InteractiveActionChip extends StatefulWidget {
  final String label;
  final bool selected;
  final Color accentColor;
  final bool enabled;
  final VoidCallback onTap;

  const _InteractiveActionChip({
    required this.label,
    required this.selected,
    required this.accentColor,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_InteractiveActionChip> createState() => _InteractiveActionChipState();
}

class _InteractiveActionChipState extends State<_InteractiveActionChip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = !widget.enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.45)
        : widget.selected
            ? widget.accentColor.withValues(alpha: 0.22)
            : _pressed
                ? widget.accentColor.withValues(alpha: 0.16)
                : _hovered
                    ? AppColors.surfaceLight
                    : AppColors.background;

    final borderColor = !widget.enabled
        ? AppColors.cardBorder.withValues(alpha: 0.4)
        : (widget.selected || _focused || _hovered)
            ? widget.accentColor
            : AppColors.cardBorder;

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: widget.enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1.0),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
              color: !widget.enabled
                  ? AppColors.textSecondary.withValues(alpha: 0.5)
                  : widget.selected
                      ? widget.accentColor
                      : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
