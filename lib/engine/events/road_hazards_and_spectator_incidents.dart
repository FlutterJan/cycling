import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../models/race/race_stage.dart';
import '../../models/race/stage_segment.dart';
import '../../models/rider/rider_health.dart';

/// Typ incydentu drogowego lub kibicowskiego na trasie wyścigu.
enum RoadHazardType {
  /// Zwężenie przez wysepkę drogową z żółtymi pachołkami na ostatnich 5 km.
  trafficIslandBottleneck,

  /// Przejazd kolejowy z ryzykiem zamknięcia szlabanu przed peletonem.
  railwayLevelCrossing,

  /// Nieostrożny kibic robiący zdjęcia na podjeździe (wtargnięcie w tor jazdy).
  carelessSpectatorPhoto,

  /// Mokre pasy dla pieszych na zakrętach (śliska farba w deszczu).
  wetPedestrianCrosswalk,

  /// Plama oleju lub paliwa na szybkim zjeździe.
  descentOilSlick;

  String toJson() => name;

  static RoadHazardType fromJson(String value) {
    return RoadHazardType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RoadHazardType.trafficIslandBottleneck,
    );
  }

  String get labelPl {
    switch (this) {
      case RoadHazardType.trafficIslandBottleneck:
        return 'Wysepka drogowa (ostatnie 5 km)';
      case RoadHazardType.railwayLevelCrossing:
        return 'Przejazd kolejowy';
      case RoadHazardType.carelessSpectatorPhoto:
        return 'Kibice z aparatami na podjeździe';
      case RoadHazardType.wetPedestrianCrosswalk:
        return 'Mokre pasy na zakręcie';
      case RoadHazardType.descentOilSlick:
        return 'Plama oleju na zjeździe';
    }
  }

  String get shortCode {
    switch (this) {
      case RoadHazardType.trafficIslandBottleneck:
        return 'ISLAND';
      case RoadHazardType.railwayLevelCrossing:
        return 'RAIL';
      case RoadHazardType.carelessSpectatorPhoto:
        return 'CROWD';
      case RoadHazardType.wetPedestrianCrosswalk:
        return 'ZEBRA';
      case RoadHazardType.descentOilSlick:
        return 'OIL';
    }
  }
}

/// Poziom zagrożenia dla peletonu.
enum HazardSeverityLevel {
  low,
  moderate,
  high,
  critical;

  String toJson() => name;

  static HazardSeverityLevel fromJson(String value) {
    return HazardSeverityLevel.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => HazardSeverityLevel.moderate,
    );
  }

  String get labelPl {
    switch (this) {
      case HazardSeverityLevel.low:
        return 'Niskie';
      case HazardSeverityLevel.moderate:
        return 'Umiarkowane';
      case HazardSeverityLevel.high:
        return 'Wysokie';
      case HazardSeverityLevel.critical:
        return 'Krytyczne';
    }
  }
}

/// Stan rogatek na przejeździe kolejowym w momencie zbliżania się grupy.
enum RailwayBarrierState {
  open,
  warningLightsFlashing,
  closing,
  closed;

  String toJson() => name;

  static RailwayBarrierState fromJson(String value) {
    return RailwayBarrierState.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RailwayBarrierState.open,
    );
  }

  String get labelPl {
    switch (this) {
      case RailwayBarrierState.open:
        return 'Szlaban otwarty';
      case RailwayBarrierState.warningLightsFlashing:
        return 'Pulsujące czerwone światła';
      case RailwayBarrierState.closing:
        return 'Opuszczanie rogatek';
      case RailwayBarrierState.closed:
        return 'Szlaban zamknięty';
    }
  }
}

/// Skutek spotkania kolarza z zagrożeniem drogowym.
enum RoadHazardActionOutcome {
  cleanPassage,
  emergencyBrakingTimeLoss,
  pelotonSplitOrAccordion,
  riderCrashOrKnockdown,
  neutralizedWait,
  commissaireBarrierViolation;

  String toJson() => name;

  static RoadHazardActionOutcome fromJson(String value) {
    return RoadHazardActionOutcome.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RoadHazardActionOutcome.cleanPassage,
    );
  }

  String get labelPl {
    switch (this) {
      case RoadHazardActionOutcome.cleanPassage:
        return 'Czysty przejazd';
      case RoadHazardActionOutcome.emergencyBrakingTimeLoss:
        return 'Awaryjne hamowanie';
      case RoadHazardActionOutcome.pelotonSplitOrAccordion:
        return 'Efekt akordeonu / podział';
      case RoadHazardActionOutcome.riderCrashOrKnockdown:
        return 'Upadek / potrącenie';
      case RoadHazardActionOutcome.neutralizedWait:
        return 'Neutralizacja przed szlabanem';
      case RoadHazardActionOutcome.commissaireBarrierViolation:
        return 'Przejazd pod szlabanem (DSQ)';
    }
  }
}

/// Strefa zagrożenia drogowego na trasie etapu.
class RoadHazardZone {
  final String id;
  final RoadHazardType type;
  final double kilometerMark;
  final double distanceToFinishKm;
  final double roadWidthMeters;
  final double surfaceFrictionMu;
  final double gradientPercent;
  final bool isWetSurface;
  final bool hasYellowCones;
  final double spectatorDensityFactor;
  final RailwayBarrierState railwayBarrierState;
  final double barrierClosureDurationSeconds;
  final HazardSeverityLevel severity;
  final String descriptionPl;
  final String radioWarningPl;

  const RoadHazardZone({
    required this.id,
    required this.type,
    required this.kilometerMark,
    required this.distanceToFinishKm,
    this.roadWidthMeters = 6.5,
    this.surfaceFrictionMu = 0.85,
    this.gradientPercent = 0.0,
    this.isWetSurface = false,
    this.hasYellowCones = false,
    this.spectatorDensityFactor = 0.3,
    this.railwayBarrierState = RailwayBarrierState.open,
    this.barrierClosureDurationSeconds = 0.0,
    required this.severity,
    required this.descriptionPl,
    required this.radioWarningPl,
  });

  bool get isInFinal5Km => distanceToFinishKm <= 5.0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toJson(),
      'kilometerMark': kilometerMark,
      'distanceToFinishKm': distanceToFinishKm,
      'roadWidthMeters': roadWidthMeters,
      'surfaceFrictionMu': surfaceFrictionMu,
      'gradientPercent': gradientPercent,
      'isWetSurface': isWetSurface,
      'hasYellowCones': hasYellowCones,
      'spectatorDensityFactor': spectatorDensityFactor,
      'railwayBarrierState': railwayBarrierState.toJson(),
      'barrierClosureDurationSeconds': barrierClosureDurationSeconds,
      'severity': severity.toJson(),
      'descriptionPl': descriptionPl,
      'radioWarningPl': radioWarningPl,
    };
  }

  factory RoadHazardZone.fromJson(Map<String, dynamic> json) {
    return RoadHazardZone(
      id: json['id'] as String,
      type: RoadHazardType.fromJson(json['type'] as String),
      kilometerMark: (json['kilometerMark'] as num).toDouble(),
      distanceToFinishKm: (json['distanceToFinishKm'] as num).toDouble(),
      roadWidthMeters: (json['roadWidthMeters'] as num?)?.toDouble() ?? 6.5,
      surfaceFrictionMu: (json['surfaceFrictionMu'] as num?)?.toDouble() ?? 0.85,
      gradientPercent: (json['gradientPercent'] as num?)?.toDouble() ?? 0.0,
      isWetSurface: (json['isWetSurface'] as bool?) ?? false,
      hasYellowCones: (json['hasYellowCones'] as bool?) ?? false,
      spectatorDensityFactor:
          (json['spectatorDensityFactor'] as num?)?.toDouble() ?? 0.3,
      railwayBarrierState: json['railwayBarrierState'] != null
          ? RailwayBarrierState.fromJson(json['railwayBarrierState'] as String)
          : RailwayBarrierState.open,
      barrierClosureDurationSeconds:
          (json['barrierClosureDurationSeconds'] as num?)?.toDouble() ?? 0.0,
      severity: HazardSeverityLevel.fromJson(json['severity'] as String),
      descriptionPl: json['descriptionPl'] as String,
      radioWarningPl: json['radioWarningPl'] as String,
    );
  }
}

/// Dane kolarza zbliżającego się do strefy zagrożenia.
class RiderHazardExposureInput {
  final String riderId;
  final String riderName;
  final String teamId;
  final int bibNumber;
  final bool isInBreakaway;
  final int pelotonPositionIndex;
  final int groupSize;
  final double currentSpeedKmh;
  final double bikeHandlingSkill;
  final double descendingSkill;
  final double positioningSkill;
  final double fatigueRatio;
  final bool isLeader;
  final bool dsWarningDelivered;

  const RiderHazardExposureInput({
    required this.riderId,
    required this.riderName,
    required this.teamId,
    this.bibNumber = 1,
    this.isInBreakaway = false,
    this.pelotonPositionIndex = 0,
    this.groupSize = 120,
    required this.currentSpeedKmh,
    this.bikeHandlingSkill = 75.0,
    this.descendingSkill = 75.0,
    this.positioningSkill = 75.0,
    this.fatigueRatio = 0.2,
    this.isLeader = false,
    this.dsWarningDelivered = false,
  });
}

/// Kontekst ewaluacji przejazdu grupy przez strefę zagrożenia.
class RoadHazardEvaluationInput {
  final WeatherCondition weatherCondition;
  final double pelotonSpeedKmh;
  final double breakawayGapSeconds;
  final List<RiderHazardExposureInput> riders;
  final int seed;

  const RoadHazardEvaluationInput({
    required this.weatherCondition,
    required this.pelotonSpeedKmh,
    this.breakawayGapSeconds = 0.0,
    required this.riders,
    this.seed = 42,
  });
}

/// Wpływ incydentu drogowego na pojedynczego kolarza.
class RiderHazardImpact {
  final String riderId;
  final String riderName;
  final String teamId;
  final RoadHazardActionOutcome outcome;
  final double timeLostSeconds;
  final double speedDropKmh;
  final double wPrimePenaltyJoules;
  final bool crashed;
  final Injury? injury;
  final bool commissaireDsqRisk;
  final String notePl;

  const RiderHazardImpact({
    required this.riderId,
    required this.riderName,
    required this.teamId,
    required this.outcome,
    required this.timeLostSeconds,
    required this.speedDropKmh,
    required this.wPrimePenaltyJoules,
    required this.crashed,
    this.injury,
    this.commissaireDsqRisk = false,
    required this.notePl,
  });

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'riderName': riderName,
      'teamId': teamId,
      'outcome': outcome.toJson(),
      'timeLostSeconds': timeLostSeconds,
      'speedDropKmh': speedDropKmh,
      'wPrimePenaltyJoules': wPrimePenaltyJoules,
      'crashed': crashed,
      'injury': injury?.toJson(),
      'commissaireDsqRisk': commissaireDsqRisk,
      'notePl': notePl,
    };
  }

  factory RiderHazardImpact.fromJson(Map<String, dynamic> json) {
    return RiderHazardImpact(
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      teamId: json['teamId'] as String,
      outcome: RoadHazardActionOutcome.fromJson(json['outcome'] as String),
      timeLostSeconds: (json['timeLostSeconds'] as num).toDouble(),
      speedDropKmh: (json['speedDropKmh'] as num).toDouble(),
      wPrimePenaltyJoules: (json['wPrimePenaltyJoules'] as num).toDouble(),
      crashed: json['crashed'] as bool,
      injury: json['injury'] != null
          ? Injury.fromJson(json['injury'] as Map<String, dynamic>)
          : null,
      commissaireDsqRisk: (json['commissaireDsqRisk'] as bool?) ?? false,
      notePl: json['notePl'] as String,
    );
  }
}

/// Pełny raport ze zdarzenia drogowego lub kibicowskiego na trasie.
class RoadHazardIncidentReport {
  final String id;
  final RoadHazardZone hazard;
  final double kilometerMark;
  final double distanceToFinishKm;
  final bool triggered;
  final HazardSeverityLevel severity;
  final double barrierClosedForSeconds;
  final double breakawayAdvantageDeltaSeconds;
  final double accordionDelayBackOfPelotonSeconds;
  final List<RiderHazardImpact> affectedRiders;
  final String radioTourAlertPl;
  final String dsRadioWarningPl;

  const RoadHazardIncidentReport({
    required this.id,
    required this.hazard,
    required this.kilometerMark,
    required this.distanceToFinishKm,
    required this.triggered,
    required this.severity,
    this.barrierClosedForSeconds = 0.0,
    this.breakawayAdvantageDeltaSeconds = 0.0,
    this.accordionDelayBackOfPelotonSeconds = 0.0,
    required this.affectedRiders,
    required this.radioTourAlertPl,
    required this.dsRadioWarningPl,
  });

  int get crashCount => affectedRiders.where((r) => r.crashed).length;
  bool get hasCrashes => crashCount > 0;
  bool get hasCommissaireRisk =>
      affectedRiders.any((r) => r.commissaireDsqRisk);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hazard': hazard.toJson(),
      'kilometerMark': kilometerMark,
      'distanceToFinishKm': distanceToFinishKm,
      'triggered': triggered,
      'severity': severity.toJson(),
      'barrierClosedForSeconds': barrierClosedForSeconds,
      'breakawayAdvantageDeltaSeconds': breakawayAdvantageDeltaSeconds,
      'accordionDelayBackOfPelotonSeconds': accordionDelayBackOfPelotonSeconds,
      'affectedRiders': affectedRiders.map((r) => r.toJson()).toList(),
      'radioTourAlertPl': radioTourAlertPl,
      'dsRadioWarningPl': dsRadioWarningPl,
    };
  }

  factory RoadHazardIncidentReport.fromJson(Map<String, dynamic> json) {
    return RoadHazardIncidentReport(
      id: json['id'] as String,
      hazard: RoadHazardZone.fromJson(json['hazard'] as Map<String, dynamic>),
      kilometerMark: (json['kilometerMark'] as num).toDouble(),
      distanceToFinishKm: (json['distanceToFinishKm'] as num).toDouble(),
      triggered: json['triggered'] as bool,
      severity: HazardSeverityLevel.fromJson(json['severity'] as String),
      barrierClosedForSeconds:
          (json['barrierClosedForSeconds'] as num?)?.toDouble() ?? 0.0,
      breakawayAdvantageDeltaSeconds:
          (json['breakawayAdvantageDeltaSeconds'] as num?)?.toDouble() ?? 0.0,
      accordionDelayBackOfPelotonSeconds:
          (json['accordionDelayBackOfPelotonSeconds'] as num?)?.toDouble() ??
              0.0,
      affectedRiders: (json['affectedRiders'] as List<dynamic>)
          .map((e) => RiderHazardImpact.fromJson(e as Map<String, dynamic>))
          .toList(),
      radioTourAlertPl: json['radioTourAlertPl'] as String,
      dsRadioWarningPl: json['dsRadioWarningPl'] as String,
    );
  }
}

/// Alias PascalCase dla spójności konwencji nazewnictwa w projekcie.
typedef RoadHazardsAndSpectatorIncidents = RoadHazardsAndSpectatorincidents;

/// Silnik realistycznych incydentów drogowych i kibicowskich na trasie etapu.
///
/// Obsługuje 5 typowych dla kolarstwa szosowego zagrożeń:
/// 1. Zwężenia przez wysepki drogowe (`Traffic Islands`) z żółtymi pachołkami na ostatnich 5 km,
/// 2. Przejazdy kolejowe z ryzykiem zamknięcia szlabanu przed peletonem,
/// 3. Nieostrożnych kibiców robiących zdjęcia na podjazdach,
/// 4. Mokre pasy dla pieszych na zakrętach,
/// 5. Plamy oleju na zjazdach.
class RoadHazardsAndSpectatorincidents {
  const RoadHazardsAndSpectatorincidents();

  /// Deterministycznie generuje listę stref zagrożeń dla całego etapu.
  List<RoadHazardZone> generateStageHazardZones({
    required RaceStage stage,
    required int seed,
    double spectatorDensity = 0.65,
  }) {
    final totalKm = stage.totalDistanceKm;
    if (totalKm <= 0.0 || stage.segments.isEmpty) {
      return const [];
    }

    final rng = math.Random(seed ^ stage.id.hashCode);
    final isWet = stage.weatherCondition == WeatherCondition.lightRain ||
        stage.weatherCondition == WeatherCondition.heavyStorm;
    final clampedSpectators = spectatorDensity.clamp(0.0, 1.0);
    final zones = <RoadHazardZone>[];
    int seq = 0;

    // 1. Wysepki drogowe (Traffic Islands) z żółtymi pachołkami na ostatnich 5 km
    if (stage.stageType != StageType.individualTimeTrial && totalKm >= 6.0) {
      final islandCount = stage.stageType == StageType.flat ? 2 : 1;
      for (int i = 0; i < islandCount; i++) {
        final distToFinish =
            (1.2 + (i * 2.1) + rng.nextDouble() * 1.1).clamp(0.7, 4.9);
        final kmMark = (totalKm - distToFinish).clamp(0.5, totalKm - 0.5);
        final segment = _segmentAtKm(stage.segments, kmMark);
        final width = 3.2 + rng.nextDouble() * 1.1;
        zones.add(
          RoadHazardZone(
            id: '${stage.id}_hazard_${seq++}',
            type: RoadHazardType.trafficIslandBottleneck,
            kilometerMark: _round1(kmMark),
            distanceToFinishKm: _round1(distToFinish),
            roadWidthMeters: _round2(width),
            surfaceFrictionMu: isWet ? 0.58 : 0.85,
            gradientPercent: segment.gradientPercent,
            isWetSurface: isWet,
            hasYellowCones: true,
            severity: distToFinish <= 2.5
                ? HazardSeverityLevel.high
                : HazardSeverityLevel.moderate,
            descriptionPl:
                'Zwężenie przez wysepkę drogową (szer. ${width.toStringAsFixed(1)} m) '
                'oznakowaną żółtymi pachołkami i gwizdkiem sędziego.',
            radioWarningPl:
                'Uwaga! Wysepka z żółtymi pachołkami na ${_round1(distToFinish)} km do mety — '
                'ustawić pociąg na czele przed zwężeniem!',
          ),
        );
      }
    }

    // 2. Przejazdy kolejowe na odcinkach płaskich/pagórkowatych poza finałowymi 4 km
    final railwayCandidates = stage.segments.where((seg) {
      final distToFinish = totalKm - (seg.startKm + seg.lengthKm * 0.5);
      return distToFinish > 4.5 &&
          seg.startKm > 8.0 &&
          seg.gradientPercent.abs() < 3.5;
    }).toList();

    if (railwayCandidates.isNotEmpty &&
        stage.stageType != StageType.individualTimeTrial &&
        stage.stageType != StageType.teamTimeTrial) {
      final chosen =
          railwayCandidates[rng.nextInt(railwayCandidates.length)];
      final kmMark = chosen.startKm + chosen.lengthKm * (0.3 + rng.nextDouble() * 0.4);
      final distToFinish = math.max(4.5, totalKm - kmMark);
      final barrierRoll = rng.nextDouble();
      final RailwayBarrierState barrierState;
      final double closureDuration;
      final HazardSeverityLevel severity;

      if (barrierRoll < 0.22) {
        barrierState = RailwayBarrierState.closed;
        closureDuration = 18.0 + rng.nextDouble() * 34.0;
        severity = HazardSeverityLevel.critical;
      } else if (barrierRoll < 0.42) {
        barrierState = RailwayBarrierState.closing;
        closureDuration = 12.0 + rng.nextDouble() * 18.0;
        severity = HazardSeverityLevel.high;
      } else if (barrierRoll < 0.65) {
        barrierState = RailwayBarrierState.warningLightsFlashing;
        closureDuration = 0.0;
        severity = HazardSeverityLevel.moderate;
      } else {
        barrierState = RailwayBarrierState.open;
        closureDuration = 0.0;
        severity = HazardSeverityLevel.low;
      }

      zones.add(
        RoadHazardZone(
          id: '${stage.id}_hazard_${seq++}',
          type: RoadHazardType.railwayLevelCrossing,
          kilometerMark: _round1(kmMark),
          distanceToFinishKm: _round1(distToFinish),
          roadWidthMeters: 5.8,
          surfaceFrictionMu: isWet ? 0.52 : 0.78,
          gradientPercent: chosen.gradientPercent,
          isWetSurface: isWet,
          railwayBarrierState: barrierState,
          barrierClosureDurationSeconds: _round1(closureDuration),
          severity: severity,
          descriptionPl:
              'Przejazd kolejowy na ${_round1(kmMark)} km (${barrierState.labelPl}).',
          radioWarningPl:
              'Przejazd kolejowy na ${_round1(kmMark)} km! Zakaz przejazdu pod opuszczającym się szlabanem (grozi DSQ).',
        ),
      );
    }

    // 3. Nieostrożni kibice robiący zdjęcia na podjazdach
    final climbCandidates = stage.segments
        .where((seg) => seg.gradientPercent >= 5.0 && seg.lengthKm >= 1.0)
        .toList();
    if (climbCandidates.isNotEmpty && clampedSpectators >= 0.35) {
      final seg = climbCandidates[rng.nextInt(climbCandidates.length)];
      final kmMark = seg.startKm + seg.lengthKm * (0.4 + rng.nextDouble() * 0.4);
      final distToFinish = math.max(0.5, totalKm - kmMark);
      final isHcOrCat1 =
          seg.sprintOrKomClassification == SegmentClassification.horsCategorie ||
              seg.sprintOrKomClassification == SegmentClassification.cat1;
      zones.add(
        RoadHazardZone(
          id: '${stage.id}_hazard_${seq++}',
          type: RoadHazardType.carelessSpectatorPhoto,
          kilometerMark: _round1(kmMark),
          distanceToFinishKm: _round1(distToFinish),
          roadWidthMeters: isHcOrCat1 ? 3.1 : 4.0,
          surfaceFrictionMu: isWet ? 0.60 : 0.85,
          gradientPercent: seg.gradientPercent,
          isWetSurface: isWet,
          spectatorDensityFactor:
              (clampedSpectators * (isHcOrCat1 ? 1.2 : 1.0)).clamp(0.3, 1.0),
          severity: isHcOrCat1
              ? HazardSeverityLevel.high
              : HazardSeverityLevel.moderate,
          descriptionPl:
              'Gęsty szpaler kibiców na podjeździe (${seg.gradientPercent.toStringAsFixed(1)}%) — '
              'fani wychylają się z telefonami i aparatami w tor jazdy.',
          radioWarningPl:
              'Tłum kibiców z aparatami na ${_round1(kmMark)} km! Trzymać środek szosy i uważać na łokcie.',
        ),
      );
    }

    // 4. Mokre pasy dla pieszych na zakrętach (szczególnie przy deszczu / trudnych zakrętach)
    final cornerCandidates = stage.segments
        .where((seg) => seg.technicalDifficulty >= 52.0)
        .toList();
    if (cornerCandidates.isNotEmpty && (isWet || rng.nextDouble() < 0.35)) {
      final seg = cornerCandidates[rng.nextInt(cornerCandidates.length)];
      final kmMark = seg.startKm + seg.lengthKm * 0.5;
      final distToFinish = math.max(0.4, totalKm - kmMark);
      final mu = isWet ? 0.34 : 0.68;
      zones.add(
        RoadHazardZone(
          id: '${stage.id}_hazard_${seq++}',
          type: RoadHazardType.wetPedestrianCrosswalk,
          kilometerMark: _round1(kmMark),
          distanceToFinishKm: _round1(distToFinish),
          roadWidthMeters: 5.4,
          surfaceFrictionMu: mu,
          gradientPercent: seg.gradientPercent,
          isWetSurface: isWet,
          severity: isWet
              ? HazardSeverityLevel.high
              : HazardSeverityLevel.low,
          descriptionPl: isWet
              ? 'Śliska biała farba pasów dla pieszych na ostrym zakręcie w deszczu (μ=${mu.toStringAsFixed(2)}).'
              : 'Przejście dla pieszych na technicznym zakręcie.',
          radioWarningPl:
              'Uwaga na śliskie pasy dla pieszych w zakręcie na ${_round1(kmMark)} km — nie składać roweru na białej farbie!',
        ),
      );
    }

    // 5. Plamy oleju na zjazdach
    final descentCandidates = stage.segments
        .where((seg) => seg.gradientPercent <= -4.0 && seg.lengthKm >= 1.2)
        .toList();
    if (descentCandidates.isNotEmpty && rng.nextDouble() < 0.65) {
      final seg = descentCandidates[rng.nextInt(descentCandidates.length)];
      final kmMark = seg.startKm + seg.lengthKm * (0.35 + rng.nextDouble() * 0.35);
      final distToFinish = math.max(1.0, totalKm - kmMark);
      final mu = isWet ? 0.22 : 0.28;
      zones.add(
        RoadHazardZone(
          id: '${stage.id}_hazard_${seq++}',
          type: RoadHazardType.descentOilSlick,
          kilometerMark: _round1(kmMark),
          distanceToFinishKm: _round1(distToFinish),
          roadWidthMeters: 5.0,
          surfaceFrictionMu: mu,
          gradientPercent: seg.gradientPercent,
          isWetSurface: isWet,
          severity: HazardSeverityLevel.critical,
          descriptionPl:
              'Tęczowa plama oleju na szybkim zjeździe (${seg.gradientPercent.toStringAsFixed(1)}%, μ=${mu.toStringAsFixed(2)}).',
          radioWarningPl:
              'ALARM! Plama oleju na zjeździe na ${_round1(kmMark)} km! Natychmiast zredukować prędkość przed wirażem!',
        ),
      );
    }

    zones.sort((a, b) => a.kilometerMark.compareTo(b.kilometerMark));
    return zones;
  }

  /// Oblicza znormalizowany wskaźnik ryzyka [0.0, 1.0] dla strefy zagrożenia.
  double calculateHazardRiskScore({
    required RoadHazardZone hazard,
    required WeatherCondition weatherCondition,
    required double approachSpeedKmh,
    double avgBikeHandling = 75.0,
  }) {
    double score;
    switch (hazard.type) {
      case RoadHazardType.trafficIslandBottleneck:
        final widthPenalty = ((5.0 - hazard.roadWidthMeters).clamp(0.0, 2.5)) * 0.16;
        final speedFactor = (approachSpeedKmh / 65.0).clamp(0.4, 1.3);
        final final5KmMultiplier = hazard.isInFinal5Km ? 1.25 : 0.85;
        score = (0.32 + widthPenalty) * speedFactor * final5KmMultiplier;
        break;
      case RoadHazardType.railwayLevelCrossing:
        switch (hazard.railwayBarrierState) {
          case RailwayBarrierState.open:
            score = 0.05;
            break;
          case RailwayBarrierState.warningLightsFlashing:
            score = 0.42;
            break;
          case RailwayBarrierState.closing:
            score = 0.78;
            break;
          case RailwayBarrierState.closed:
            score = 0.96;
            break;
        }
        break;
      case RoadHazardType.carelessSpectatorPhoto:
        final crowdFactor = hazard.spectatorDensityFactor.clamp(0.2, 1.0);
        final narrowBonus = hazard.roadWidthMeters < 3.6 ? 0.18 : 0.0;
        score = 0.25 + crowdFactor * 0.48 + narrowBonus;
        break;
      case RoadHazardType.wetPedestrianCrosswalk:
        final isWet = hazard.isWetSurface ||
            weatherCondition == WeatherCondition.lightRain ||
            weatherCondition == WeatherCondition.heavyStorm;
        final gripPenalty = (0.85 - hazard.surfaceFrictionMu).clamp(0.0, 0.7);
        score = (isWet ? 0.35 : 0.10) +
            gripPenalty * 0.65 * (approachSpeedKmh / 50.0).clamp(0.5, 1.4);
        break;
      case RoadHazardType.descentOilSlick:
        final speedRisk = ((approachSpeedKmh - 42.0) / 40.0).clamp(0.1, 1.2);
        score = 0.42 + speedRisk * 0.48;
        break;
    }

    final skillMitigation = ((avgBikeHandling - 70.0) / 100.0).clamp(-0.15, 0.20);
    return (score - skillMitigation).clamp(0.0, 1.0);
  }

  /// Symuluje przejazd grupy kolarzy przez konkretną strefę zagrożenia.
  RoadHazardIncidentReport evaluateHazardEncounter({
    required RoadHazardZone hazard,
    required RoadHazardEvaluationInput input,
  }) {
    final rng = math.Random(input.seed ^ hazard.id.hashCode);
    final impacts = <RiderHazardImpact>[];

    switch (hazard.type) {
      case RoadHazardType.trafficIslandBottleneck:
        return _evaluateTrafficIsland(hazard, input, rng, impacts);
      case RoadHazardType.railwayLevelCrossing:
        return _evaluateRailwayCrossing(hazard, input, rng, impacts);
      case RoadHazardType.carelessSpectatorPhoto:
        return _evaluateCarelessSpectator(hazard, input, rng, impacts);
      case RoadHazardType.wetPedestrianCrosswalk:
        return _evaluateWetCrosswalk(hazard, input, rng, impacts);
      case RoadHazardType.descentOilSlick:
        return _evaluateDescentOilSlick(hazard, input, rng, impacts);
    }
  }

  RoadHazardIncidentReport _evaluateTrafficIsland(
    RoadHazardZone hazard,
    RoadHazardEvaluationInput input,
    math.Random rng,
    List<RiderHazardImpact> impacts,
  ) {
    final isWet = hazard.isWetSurface ||
        input.weatherCondition == WeatherCondition.lightRain ||
        input.weatherCondition == WeatherCondition.heavyStorm;
    final bottleneckSeverity =
        ((4.8 - hazard.roadWidthMeters).clamp(0.2, 2.2)) *
            (hazard.isInFinal5Km ? 1.35 : 1.0);
    double maxAccordionDelay = 0.0;
    bool anyCrash = false;

    for (final rider in input.riders) {
      final groupSize = math.max(1, rider.groupSize);
      final relativePos = (rider.pelotonPositionIndex / groupSize).clamp(0.0, 1.0);
      final isBackHalf = !rider.isInBreakaway && relativePos > 0.35;

      final warningBonus = rider.dsWarningDelivered ? 0.35 : 0.0;
      final skillScore = (rider.bikeHandlingSkill * 0.6 +
              rider.positioningSkill * 0.4) /
          100.0;

      // Ogon peletonu musi ostro hamować przed zwężeniem (efekt akordeonu)
      double timeLoss = 0.0;
      double speedDrop = 0.0;
      double wPrimePenalty = 0.0;
      var outcome = RoadHazardActionOutcome.cleanPassage;
      var crashed = false;
      Injury? injury;
      var note = 'Sprawnie ominął wysepkę z żółtymi pachołkami.';

      if (isBackHalf) {
        final accordionFactor = (relativePos - 0.30) * 1.4;
        timeLoss = _round1(
          (1.2 + bottleneckSeverity * 2.8 * accordionFactor) *
              (1.0 - warningBonus * 0.5),
        );
        speedDrop = _round1(8.0 + bottleneckSeverity * 6.0 * accordionFactor);
        wPrimePenalty = _round1(650.0 + timeLoss * 140.0);
        outcome = RoadHazardActionOutcome.pelotonSplitOrAccordion;
        note =
            'Hamowanie przed wysepką (efekt akordeonu): strata ${timeLoss.toStringAsFixed(1)} s.';
        if (timeLoss > maxAccordionDelay) {
          maxAccordionDelay = timeLoss;
        }
      }

      // Ryzyko zahaczenia pachołka lub upadku przy dużej prędkości
      final crashProb = ((0.035 * bottleneckSeverity) *
              (isWet ? 1.5 : 1.0) *
              (1.25 - skillScore) *
              (1.0 - warningBonus))
          .clamp(0.002, 0.22);

      if (rng.nextDouble() < crashProb) {
        crashed = true;
        anyCrash = true;
        outcome = RoadHazardActionOutcome.riderCrashOrKnockdown;
        timeLoss = _round1(18.0 + rng.nextDouble() * 28.0);
        speedDrop = rider.currentSpeedKmh;
        wPrimePenalty = 1800.0;
        injury = _rollMinorOrModerateInjury(rng, severeAllowed: false);
        note = 'Zahaczył o żółty pachołek na wysepce i upadł na asfalt!';
      }

      impacts.add(
        RiderHazardImpact(
          riderId: rider.riderId,
          riderName: rider.riderName,
          teamId: rider.teamId,
          outcome: outcome,
          timeLostSeconds: timeLoss,
          speedDropKmh: speedDrop,
          wPrimePenaltyJoules: wPrimePenalty,
          crashed: crashed,
          injury: injury,
          notePl: note,
        ),
      );
    }

    return RoadHazardIncidentReport(
      id: '${hazard.id}_report',
      hazard: hazard,
      kilometerMark: hazard.kilometerMark,
      distanceToFinishKm: hazard.distanceToFinishKm,
      triggered: anyCrash || maxAccordionDelay > 1.5,
      severity: anyCrash ? HazardSeverityLevel.high : hazard.severity,
      accordionDelayBackOfPelotonSeconds: _round1(maxAccordionDelay),
      affectedRiders: impacts,
      radioTourAlertPl: anyCrash
          ? 'Kraksa na wysepce drogowej ${hazard.distanceToFinishKm.toStringAsFixed(1)} km przed metą!'
          : 'Peleton rozciągnął się na zwężeniu z żółtymi pachołkami (${hazard.distanceToFinishKm.toStringAsFixed(1)} km do mety).',
      dsRadioWarningPl: hazard.radioWarningPl,
    );
  }

  RoadHazardIncidentReport _evaluateRailwayCrossing(
    RoadHazardZone hazard,
    RoadHazardEvaluationInput input,
    math.Random rng,
    List<RiderHazardImpact> impacts,
  ) {
    final state = hazard.railwayBarrierState;
    if (state == RailwayBarrierState.open) {
      for (final rider in input.riders) {
        impacts.add(
          RiderHazardImpact(
            riderId: rider.riderId,
            riderName: rider.riderName,
            teamId: rider.teamId,
            outcome: RoadHazardActionOutcome.cleanPassage,
            timeLostSeconds: 0.0,
            speedDropKmh: 0.0,
            wPrimePenaltyJoules: 0.0,
            crashed: false,
            notePl: 'Przejazd kolejowy otwarty — peleton przejechał bez przeszkód.',
          ),
        );
      }
      return RoadHazardIncidentReport(
        id: '${hazard.id}_report',
        hazard: hazard,
        kilometerMark: hazard.kilometerMark,
        distanceToFinishKm: hazard.distanceToFinishKm,
        triggered: false,
        severity: HazardSeverityLevel.low,
        affectedRiders: impacts,
        radioTourAlertPl:
            'Peleton bezpiecznie minął przejazd kolejowy na ${hazard.kilometerMark} km.',
        dsRadioWarningPl: hazard.radioWarningPl,
      );
    }

    final closureSec = hazard.barrierClosureDurationSeconds > 0.0
        ? hazard.barrierClosureDurationSeconds
        : (state == RailwayBarrierState.closed ? 32.0 : 16.0);

    // Czy ucieczka zdążyła przejechać przed zamknięciem rogatek?
    final breakawayPassedBeforeGate =
        input.breakawayGapSeconds >= 20.0 && state != RailwayBarrierState.open;

    double breakawayDelta = 0.0;
    bool anyDsqRisk = false;

    for (final rider in input.riders) {
      if (rider.isInBreakaway && breakawayPassedBeforeGate) {
        impacts.add(
          RiderHazardImpact(
            riderId: rider.riderId,
            riderName: rider.riderName,
            teamId: rider.teamId,
            outcome: RoadHazardActionOutcome.cleanPassage,
            timeLostSeconds: 0.0,
            speedDropKmh: 0.0,
            wPrimePenaltyJoules: 0.0,
            crashed: false,
            notePl:
                'Ucieczka zdążyła przejechać przez tory tuż przed opuszczeniem szlabanu!',
          ),
        );
        continue;
      }

      if (state == RailwayBarrierState.warningLightsFlashing) {
        final speedDrop = _round1(4.0 + rng.nextDouble() * 4.0);
        impacts.add(
          RiderHazardImpact(
            riderId: rider.riderId,
            riderName: rider.riderName,
            teamId: rider.teamId,
            outcome: RoadHazardActionOutcome.emergencyBrakingTimeLoss,
            timeLostSeconds: 1.5,
            speedDropKmh: speedDrop,
            wPrimePenaltyJoules: 300.0,
            crashed: false,
            notePl:
                'Zwolnienie przed migającymi czerwonymi światłami na przejeździe.',
          ),
        );
        continue;
      }

      // Szlaban opuszczający się lub zamknięty: część nerwowych kolarzy może złamać zakaz UCI
      final recklessRisk = state == RailwayBarrierState.closing &&
          !rider.dsWarningDelivered &&
          rider.fatigueRatio > 0.45 &&
          rng.nextDouble() < 0.06;

      if (recklessRisk) {
        anyDsqRisk = true;
        impacts.add(
          RiderHazardImpact(
            riderId: rider.riderId,
            riderName: rider.riderName,
            teamId: rider.teamId,
            outcome: RoadHazardActionOutcome.commissaireBarrierViolation,
            timeLostSeconds: 0.0,
            speedDropKmh: 0.0,
            wPrimePenaltyJoules: 200.0,
            crashed: false,
            commissaireDsqRisk: true,
            notePl:
                'Przejechał pod opuszczającym się szlabanem — groźba dyskwalifikacji przez Jury UCI!',
          ),
        );
      } else {
        // Zatrzymanie przed szlabanem (neutralizacja lub strata)
        final waitLoss =
            breakawayPassedBeforeGate ? closureSec : 0.0;
        if (waitLoss > breakawayDelta) {
          breakawayDelta = waitLoss;
        }
        impacts.add(
          RiderHazardImpact(
            riderId: rider.riderId,
            riderName: rider.riderName,
            teamId: rider.teamId,
            outcome: RoadHazardActionOutcome.neutralizedWait,
            timeLostSeconds: _round1(waitLoss),
            speedDropKmh: rider.currentSpeedKmh,
            wPrimePenaltyJoules: 0.0,
            crashed: false,
            notePl: breakawayPassedBeforeGate
                ? 'Zatrzymany przed zamkniętym szlabanem na ${closureSec.toStringAsFixed(0)} s (ucieczka zyskuje przewagę).'
                : 'Zatrzymanie wyścigu przed zamkniętym szlabanem — sędziowie neutralizują stratę.',
          ),
        );
      }
    }

    return RoadHazardIncidentReport(
      id: '${hazard.id}_report',
      hazard: hazard,
      kilometerMark: hazard.kilometerMark,
      distanceToFinishKm: hazard.distanceToFinishKm,
      triggered: state == RailwayBarrierState.closed ||
          state == RailwayBarrierState.closing ||
          anyDsqRisk,
      severity: state == RailwayBarrierState.closed
          ? HazardSeverityLevel.critical
          : HazardSeverityLevel.high,
      barrierClosedForSeconds:
          (state == RailwayBarrierState.closed ||
                  state == RailwayBarrierState.closing)
              ? closureSec
              : 0.0,
      breakawayAdvantageDeltaSeconds: _round1(breakawayDelta),
      affectedRiders: impacts,
      radioTourAlertPl: state == RailwayBarrierState.closed
          ? 'STOP! Zamknięty szlaban kolejowy na ${hazard.kilometerMark} km! Peleton zatrzymany na ${closureSec.toStringAsFixed(0)} s.'
          : 'Uwaga na rogatki kolejowe na ${hazard.kilometerMark} km — sędziowie blokują wjazd na tory.',
      dsRadioWarningPl: hazard.radioWarningPl,
    );
  }

  RoadHazardIncidentReport _evaluateCarelessSpectator(
    RoadHazardZone hazard,
    RoadHazardEvaluationInput input,
    math.Random rng,
    List<RiderHazardImpact> impacts,
  ) {
    bool anyIncident = false;
    bool anyCrash = false;

    for (final rider in input.riders) {
      final exposure = hazard.spectatorDensityFactor *
          (rider.pelotonPositionIndex < 15 ? 1.25 : 0.75);
      final handling = (rider.bikeHandlingSkill / 100.0).clamp(0.4, 1.0);
      final warningCut = rider.dsWarningDelivered ? 0.45 : 0.0;

      final incidentProb =
          (0.08 * exposure * (1.2 - handling) * (1.0 - warningCut))
              .clamp(0.005, 0.25);

      if (rng.nextDouble() < incidentProb) {
        anyIncident = true;
        final crashRoll = rng.nextDouble() < 0.30;
        if (crashRoll) {
          anyCrash = true;
          impacts.add(
            RiderHazardImpact(
              riderId: rider.riderId,
              riderName: rider.riderName,
              teamId: rider.teamId,
              outcome: RoadHazardActionOutcome.riderCrashOrKnockdown,
              timeLostSeconds: _round1(14.0 + rng.nextDouble() * 20.0),
              speedDropKmh: rider.currentSpeedKmh,
              wPrimePenaltyJoules: 1600.0,
              crashed: true,
              injury: _rollMinorOrModerateInjury(rng, severeAllowed: false),
              notePl:
                  'Zahaczył kierownicą o kibica robiącego selfie na podjeździe i upadł!',
            ),
          );
        } else {
          final loss = _round1(2.0 + rng.nextDouble() * 4.5);
          impacts.add(
            RiderHazardImpact(
              riderId: rider.riderId,
              riderName: rider.riderName,
              teamId: rider.teamId,
              outcome: RoadHazardActionOutcome.emergencyBrakingTimeLoss,
              timeLostSeconds: loss,
              speedDropKmh: _round1(4.5 + rng.nextDouble() * 4.0),
              wPrimePenaltyJoules: 850.0,
              crashed: false,
              notePl:
                  'Wybity z rytmu przez kibica z aparatem — strata ${loss.toStringAsFixed(1)} s i skok tętna.',
            ),
          );
        }
      } else {
        impacts.add(
          RiderHazardImpact(
            riderId: rider.riderId,
            riderName: rider.riderName,
            teamId: rider.teamId,
            outcome: RoadHazardActionOutcome.cleanPassage,
            timeLostSeconds: 0.0,
            speedDropKmh: 0.0,
            wPrimePenaltyJoules: 0.0,
            crashed: false,
            notePl: 'Bezpiecznie ominął kibiców na podjeździe.',
          ),
        );
      }
    }

    return RoadHazardIncidentReport(
      id: '${hazard.id}_report',
      hazard: hazard,
      kilometerMark: hazard.kilometerMark,
      distanceToFinishKm: hazard.distanceToFinishKm,
      triggered: anyIncident,
      severity: anyCrash
          ? HazardSeverityLevel.high
          : (anyIncident ? HazardSeverityLevel.moderate : hazard.severity),
      affectedRiders: impacts,
      radioTourAlertPl: anyCrash
          ? 'Incydent z udziałem kibica robiącego zdjęcia na podjeździe (${hazard.kilometerMark} km)!'
          : 'Gęsty tłum kibiców na podjeździe na ${hazard.kilometerMark} km utrudnia przejazd.',
      dsRadioWarningPl: hazard.radioWarningPl,
    );
  }

  RoadHazardIncidentReport _evaluateWetCrosswalk(
    RoadHazardZone hazard,
    RoadHazardEvaluationInput input,
    math.Random rng,
    List<RiderHazardImpact> impacts,
  ) {
    final isWet = hazard.isWetSurface ||
        input.weatherCondition == WeatherCondition.lightRain ||
        input.weatherCondition == WeatherCondition.heavyStorm;
    bool anySlip = false;
    bool anyCrash = false;

    for (final rider in input.riders) {
      if (!isWet) {
        impacts.add(
          RiderHazardImpact(
            riderId: rider.riderId,
            riderName: rider.riderName,
            teamId: rider.teamId,
            outcome: RoadHazardActionOutcome.cleanPassage,
            timeLostSeconds: 0.0,
            speedDropKmh: 0.0,
            wPrimePenaltyJoules: 0.0,
            crashed: false,
            notePl: 'Sucha farba na pasach — pewna przyczepność w zakręcie.',
          ),
        );
        continue;
      }

      final gripDeficit = (0.65 - hazard.surfaceFrictionMu).clamp(0.05, 0.45);
      final speedFactor = (rider.currentSpeedKmh / 45.0).clamp(0.6, 1.5);
      final skill = (rider.bikeHandlingSkill / 100.0).clamp(0.4, 1.0);
      final warningCut = rider.dsWarningDelivered ? 0.40 : 0.0;

      final slipProb =
          (gripDeficit * 0.42 * speedFactor * (1.25 - skill) * (1.0 - warningCut))
              .clamp(0.01, 0.30);

      if (rng.nextDouble() < slipProb) {
        anySlip = true;
        final crash = rng.nextDouble() < 0.48;
        if (crash) {
          anyCrash = true;
          impacts.add(
            RiderHazardImpact(
              riderId: rider.riderId,
              riderName: rider.riderName,
              teamId: rider.teamId,
              outcome: RoadHazardActionOutcome.riderCrashOrKnockdown,
              timeLostSeconds: _round1(20.0 + rng.nextDouble() * 25.0),
              speedDropKmh: rider.currentSpeedKmh,
              wPrimePenaltyJoules: 1500.0,
              crashed: true,
              injury: _rollMinorOrModerateInjury(rng, severeAllowed: true),
              notePl:
                  'Uślizg przedniego koła na mokrych pasach dla pieszych w zakręcie!',
            ),
          );
        } else {
          final loss = _round1(2.5 + rng.nextDouble() * 3.5);
          impacts.add(
            RiderHazardImpact(
              riderId: rider.riderId,
              riderName: rider.riderName,
              teamId: rider.teamId,
              outcome: RoadHazardActionOutcome.emergencyBrakingTimeLoss,
              timeLostSeconds: loss,
              speedDropKmh: _round1(9.0 + rng.nextDouble() * 6.0),
              wPrimePenaltyJoules: 600.0,
              crashed: false,
              notePl:
                  'Wyprostował zakręt na śliskiej farbie pasów — utrata rytmu (${loss.toStringAsFixed(1)} s).',
            ),
          );
        }
      } else {
        impacts.add(
          RiderHazardImpact(
            riderId: rider.riderId,
            riderName: rider.riderName,
            teamId: rider.teamId,
            outcome: RoadHazardActionOutcome.cleanPassage,
            timeLostSeconds: 0.0,
            speedDropKmh: 0.0,
            wPrimePenaltyJoules: 0.0,
            crashed: false,
            notePl: 'Ominął białą farbę pasów i utrzymał linię w zakręcie.',
          ),
        );
      }
    }

    return RoadHazardIncidentReport(
      id: '${hazard.id}_report',
      hazard: hazard,
      kilometerMark: hazard.kilometerMark,
      distanceToFinishKm: hazard.distanceToFinishKm,
      triggered: anySlip,
      severity: anyCrash ? HazardSeverityLevel.high : hazard.severity,
      affectedRiders: impacts,
      radioTourAlertPl: anyCrash
          ? 'Poślizg i upadek na mokrych pasach dla pieszych na ${hazard.kilometerMark} km!'
          : 'Peleton ostrożnie pokonał śliskie pasy na zakręcie (${hazard.kilometerMark} km).',
      dsRadioWarningPl: hazard.radioWarningPl,
    );
  }

  RoadHazardIncidentReport _evaluateDescentOilSlick(
    RoadHazardZone hazard,
    RoadHazardEvaluationInput input,
    math.Random rng,
    List<RiderHazardImpact> impacts,
  ) {
    bool anyIncident = false;
    bool anyCrash = false;

    for (final rider in input.riders) {
      final speedExcess =
          ((rider.currentSpeedKmh - 48.0) / 35.0).clamp(0.15, 1.35);
      final skill = ((rider.descendingSkill * 0.55 +
                  rider.bikeHandlingSkill * 0.45) /
              100.0)
          .clamp(0.4, 1.0);
      final warningCut = rider.dsWarningDelivered ? 0.50 : 0.0;

      final hazardProb =
          (0.22 * speedExcess * (1.28 - skill) * (1.0 - warningCut))
              .clamp(0.02, 0.42);

      if (rng.nextDouble() < hazardProb) {
        anyIncident = true;
        final crash = rng.nextDouble() < (0.45 * speedExcess);
        if (crash) {
          anyCrash = true;
          impacts.add(
            RiderHazardImpact(
              riderId: rider.riderId,
              riderName: rider.riderName,
              teamId: rider.teamId,
              outcome: RoadHazardActionOutcome.riderCrashOrKnockdown,
              timeLostSeconds: _round1(28.0 + rng.nextDouble() * 38.0),
              speedDropKmh: rider.currentSpeedKmh,
              wPrimePenaltyJoules: 2000.0,
              crashed: true,
              injury: _rollMinorOrModerateInjury(rng, severeAllowed: true),
              notePl:
                  'Wpadł w plamę oleju na zjeździe przy ${rider.currentSpeedKmh.toStringAsFixed(0)} km/h — groźny upadek!',
            ),
          );
        } else {
          final loss = _round1(4.0 + rng.nextDouble() * 5.0);
          impacts.add(
            RiderHazardImpact(
              riderId: rider.riderId,
              riderName: rider.riderName,
              teamId: rider.teamId,
              outcome: RoadHazardActionOutcome.emergencyBrakingTimeLoss,
              timeLostSeconds: loss,
              speedDropKmh: _round1(16.0 + rng.nextDouble() * 10.0),
              wPrimePenaltyJoules: 750.0,
              crashed: false,
              notePl:
                  'Awaryjne hamowanie przed plamą oleju na zjeździe — wyratował rower, strata ${loss.toStringAsFixed(1)} s.',
            ),
          );
        }
      } else {
        impacts.add(
          RiderHazardImpact(
            riderId: rider.riderId,
            riderName: rider.riderName,
            teamId: rider.teamId,
            outcome: RoadHazardActionOutcome.cleanPassage,
            timeLostSeconds: 0.0,
            speedDropKmh: 0.0,
            wPrimePenaltyJoules: 0.0,
            crashed: false,
            notePl: 'Dostrzegł plamę oleju i bezpiecznie ją ominął.',
          ),
        );
      }
    }

    return RoadHazardIncidentReport(
      id: '${hazard.id}_report',
      hazard: hazard,
      kilometerMark: hazard.kilometerMark,
      distanceToFinishKm: hazard.distanceToFinishKm,
      triggered: anyIncident,
      severity: anyCrash ? HazardSeverityLevel.critical : HazardSeverityLevel.high,
      affectedRiders: impacts,
      radioTourAlertPl: anyCrash
          ? 'GROŹNA KRAKSA na plamie oleju podczas zjazdu (${hazard.kilometerMark} km)!'
          : 'Peleton zwalnia na zjeździe z powodu plamy oleju (${hazard.kilometerMark} km).',
      dsRadioWarningPl: hazard.radioWarningPl,
    );
  }

  Injury _rollMinorOrModerateInjury(
    math.Random rng, {
    required bool severeAllowed,
  }) {
    final roll = rng.nextDouble();
    if (severeAllowed && roll < 0.22) {
      return const Injury(
        name: 'Złamanie obojczyka',
        type: InjuryType.clavicleFracture,
        daysRemaining: 42,
        trainingAllowed: false,
      );
    }
    if (roll < 0.65) {
      return const Injury(
        name: 'Głębokie otarcia naskórka (Road Rash)',
        type: InjuryType.roadRash,
        daysRemaining: 7,
        trainingAllowed: true,
      );
    }
    return const Injury(
      name: 'Złamanie kości nadgarstka',
      type: InjuryType.wristFracture,
      daysRemaining: 21,
      trainingAllowed: false,
    );
  }

  StageSegment _segmentAtKm(List<StageSegment> segments, double km) {
    for (final seg in segments) {
      if (km >= seg.startKm && km <= seg.endKm) {
        return seg;
      }
    }
    return segments.last;
  }

  double _round1(double v) => (v * 10.0).roundToDouble() / 10.0;
  double _round2(double v) => (v * 100.0).roundToDouble() / 100.0;
}

/// Produkcyjny panel taktyczny ostrzeżeń drogowych i incydentów na trasie.
class RoadHazardsAndSpectatorIncidentsPanel extends StatefulWidget {
  final List<RoadHazardZone> hazards;
  final RoadHazardIncidentReport? latestReport;
  final ValueChanged<RoadHazardZone>? onSendDsWarning;
  final VoidCallback? onSimulateSelectedHazard;
  final bool isActionEnabled;

  const RoadHazardsAndSpectatorIncidentsPanel({
    super.key,
    required this.hazards,
    this.latestReport,
    this.onSendDsWarning,
    this.onSimulateSelectedHazard,
    this.isActionEnabled = true,
  });

  @override
  State<RoadHazardsAndSpectatorIncidentsPanel> createState() =>
      _RoadHazardsAndSpectatorIncidentsPanelState();
}

class _RoadHazardsAndSpectatorIncidentsPanelState
    extends State<RoadHazardsAndSpectatorIncidentsPanel> {
  RoadHazardType? _selectedFilter;
  String? _selectedHazardId;
  final Set<String> _warnedHazardIds = <String>{};

  @override
  void initState() {
    super.initState();
    if (widget.hazards.isNotEmpty) {
      _selectedHazardId = widget.hazards.first.id;
    }
  }

  @override
  void didUpdateWidget(
      covariant RoadHazardsAndSpectatorIncidentsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hazards.isNotEmpty &&
        !widget.hazards.any((h) => h.id == _selectedHazardId)) {
      _selectedHazardId = widget.hazards.first.id;
    }
  }

  List<RoadHazardZone> get _filteredHazards {
    if (_selectedFilter == null) return widget.hazards;
    return widget.hazards.where((h) => h.type == _selectedFilter).toList();
  }

  RoadHazardZone? get _selectedHazard {
    final list = _filteredHazards;
    if (list.isEmpty) return null;
    for (final h in list) {
      if (h.id == _selectedHazardId) return h;
    }
    return list.first;
  }

  Color _severityColor(HazardSeverityLevel level) {
    switch (level) {
      case HazardSeverityLevel.low:
        return AppColors.statusSuccess;
      case HazardSeverityLevel.moderate:
        return AppColors.accentBlue;
      case HazardSeverityLevel.high:
        return AppColors.amberWarning;
      case HazardSeverityLevel.critical:
        return AppColors.crimsonAlert;
    }
  }

  IconData _hazardIcon(RoadHazardType type) {
    switch (type) {
      case RoadHazardType.trafficIslandBottleneck:
        return Icons.alt_route_rounded;
      case RoadHazardType.railwayLevelCrossing:
        return Icons.train_rounded;
      case RoadHazardType.carelessSpectatorPhoto:
        return Icons.photo_camera_rounded;
      case RoadHazardType.wetPedestrianCrosswalk:
        return Icons.directions_walk_rounded;
      case RoadHazardType.descentOilSlick:
        return Icons.water_drop_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 600;
          final isDesktop = constraints.maxWidth >= 1000;
          final filtered = _filteredHazards;
          final selected = _selectedHazard;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(isCompact),
              const SizedBox(height: 12),
              _buildFilterChips(),
              const SizedBox(height: 14),
              if (filtered.isEmpty)
                _buildEmptyState()
              else if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: _buildHazardList(filtered)),
                    const SizedBox(width: 16),
                    Expanded(flex: 6, child: _buildDetailCard(selected)),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHazardList(filtered),
                    const SizedBox(height: 12),
                    _buildDetailCard(selected),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isCompact) {
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text(
        '${widget.hazards.length} stref',
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.goldAccent,
        ),
      ),
    );

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primaryAccent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primaryAccent),
          ),
          child: const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.goldAccent,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Zagrożenia Drogowe & Kibice',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isCompact ? 15 : 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: AppColors.textPrimary,
                ),
              ),
              const Text(
                'Wysepki <5 km, szlabany PKP, kibice, pasy i plamy oleju',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        badge,
      ],
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _HazardFilterButton(
            label: 'Wszystkie',
            selected: _selectedFilter == null,
            onTap: () => setState(() => _selectedFilter = null),
          ),
          for (final type in RoadHazardType.values) ...[
            const SizedBox(width: 8),
            _HazardFilterButton(
              label: type.shortCode,
              selected: _selectedFilter == type,
              onTap: () => setState(() => _selectedFilter = type),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHazardList(List<RoadHazardZone> list) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final hazard in list) ...[
          _HazardListTile(
            hazard: hazard,
            icon: _hazardIcon(hazard.type),
            severityColor: _severityColor(hazard.severity),
            selected: hazard.id == _selectedHazard?.id,
            warned: _warnedHazardIds.contains(hazard.id),
            onTap: () => setState(() => _selectedHazardId = hazard.id),
          ),
          if (hazard != list.last) const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildDetailCard(RoadHazardZone? hazard) {
    if (hazard == null) return const SizedBox.shrink();
    final severityColor = _severityColor(hazard.severity);
    final alreadyWarned = _warnedHazardIds.contains(hazard.id);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(_hazardIcon(hazard.type), color: severityColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hazard.type.labelPl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: severityColor),
                ),
                child: Text(
                  hazard.severity.labelPl,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: severityColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            hazard.descriptionPl,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              height: 1.4,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _MetricChip(
                label: 'Kilometr',
                value: '${hazard.kilometerMark.toStringAsFixed(1)} km',
              ),
              _MetricChip(
                label: 'Do mety',
                value: '${hazard.distanceToFinishKm.toStringAsFixed(1)} km',
              ),
              _MetricChip(
                label: 'Szerokość',
                value: '${hazard.roadWidthMeters.toStringAsFixed(1)} m',
              ),
              _MetricChip(
                label: 'Przyczepność μ',
                value: hazard.surfaceFrictionMu.toStringAsFixed(2),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Text(
              'Radio DS: ${hazard.radioWarningPl}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _HazardActionButton(
                label: alreadyWarned
                    ? 'Ostrzeżenie wysłane'
                    : 'Ostrzeż kolarzy przez Radio',
                icon: alreadyWarned
                    ? Icons.check_circle_outline_rounded
                    : Icons.headset_mic_rounded,
                enabled: widget.isActionEnabled && !alreadyWarned,
                primary: true,
                onPressed: () {
                  setState(() => _warnedHazardIds.add(hazard.id));
                  widget.onSendDsWarning?.call(hazard);
                },
              ),
              if (widget.onSimulateSelectedHazard != null)
                _HazardActionButton(
                  label: 'Symuluj przejazd',
                  icon: Icons.play_arrow_rounded,
                  enabled: widget.isActionEnabled,
                  primary: false,
                  onPressed: widget.onSimulateSelectedHazard!,
                ),
            ],
          ),
          if (widget.latestReport != null &&
              widget.latestReport!.hazard.id == hazard.id) ...[
            const SizedBox(height: 12),
            Text(
              'Raport: ${widget.latestReport!.radioTourAlertPl}',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: widget.latestReport!.hasCrashes
                    ? AppColors.crimsonAlert
                    : AppColors.goldAccent,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const Text(
        'Brak zagrożeń drogowych dla wybranego filtra.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _HazardFilterButton extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _HazardFilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_HazardFilterButton> createState() => _HazardFilterButtonState();
}

class _HazardFilterButtonState extends State<_HazardFilterButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.selected
        ? AppColors.primaryAccent
        : (_hovered ? AppColors.surfaceLight : AppColors.background);
    final border = _focused
        ? AppColors.goldAccent
        : (widget.selected ? AppColors.goldAccent : AppColors.cardBorder);

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: widget.selected
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _HazardListTile extends StatefulWidget {
  final RoadHazardZone hazard;
  final IconData icon;
  final Color severityColor;
  final bool selected;
  final bool warned;
  final VoidCallback onTap;

  const _HazardListTile({
    required this.hazard,
    required this.icon,
    required this.severityColor,
    required this.selected,
    required this.warned,
    required this.onTap,
  });

  @override
  State<_HazardListTile> createState() => _HazardListTileState();
}

class _HazardListTileState extends State<_HazardListTile> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.selected
        ? AppColors.surfaceLight
        : (_hovered
            ? AppColors.surfaceLight.withValues(alpha: 0.65)
            : AppColors.background);
    final border = _focused || widget.selected
        ? AppColors.goldAccent
        : AppColors.cardBorder;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Icon(widget.icon, color: widget.severityColor, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.hazard.type.labelPl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${widget.hazard.kilometerMark.toStringAsFixed(1)} km '
                      '(do mety ${widget.hazard.distanceToFinishKm.toStringAsFixed(1)} km)',
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
              if (widget.warned)
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: AppColors.statusSuccess,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HazardActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final bool primary;
  final VoidCallback onPressed;

  const _HazardActionButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.primary,
    required this.onPressed,
  });

  @override
  State<_HazardActionButton> createState() => _HazardActionButtonState();
}

class _HazardActionButtonState extends State<_HazardActionButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    if (!widget.enabled) {
      bg = AppColors.surface.withValues(alpha: 0.5);
    } else if (_pressed) {
      bg = widget.primary
          ? AppColors.primaryAccent.withValues(alpha: 0.85)
          : AppColors.surface;
    } else if (_hovered) {
      bg = widget.primary
          ? AppColors.primaryAccent.withValues(alpha: 0.95)
          : AppColors.surface;
    } else {
      bg = widget.primary ? AppColors.primaryAccent : AppColors.background;
    }

    final borderColor = !widget.enabled
        ? AppColors.cardBorder.withValues(alpha: 0.4)
        : (_focused
            ? AppColors.goldAccent
            : (widget.primary ? AppColors.goldAccent : AppColors.cardBorder));

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (widget.enabled) widget.onPressed();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
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
                  maxLines: 1,
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

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;

  const _MetricChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
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
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
